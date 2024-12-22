#  -----------------------------------
#  finite state machine
#  ------------------------------------

# --------- the transition class
class Transition
    var fromState
    var nextState
    var trigger

    def init(fromState,nextState,trigger)
        self.fromState = fromState
        self.nextState = nextState
        self.trigger = trigger
    end

    def tostring()
        return f"fromState={self.fromState} ==> nextState={self.nextState} - trigger={self.trigger}"
    end
end

# --------- the state class
class State

    var name
    var transitions
    var onEnterAction
    var onLeaveAction
    var onTimerAction

    def init(name)
        self.name=name
        self.transitions = []
        self.onEnterAction = nil
        self.onLeaveAction = nil
        self.onTimerAction = nil
    end

    # define the next possible state with associated trigger
    def next(nextState,trigger)
        var cproc="next WARN"

        if nextState==nil
            print(cproc.."next-state must be defined")
            return self
        end

        if trigger==nil
            print(cproc.."trigger must be defined")
            return self
        end

        # create a new transition
        var trans=Transition(self.name,nextState,trigger)
        self.transitions.push(trans)    
        return self   
    end

    # define the on-enter action
    def onEnter(action)
        var cproc="onEnter"
        if action != nil && type(action) !="function"
            print(cproc.."expected function")
            return self
        end

        self.onEnterAction = action
        return self
    end

     # define the on-leave action
    def onLeave(action)
        var cproc="onLeave"
        if action != nil && type(action) !="function"
            print(cproc.."expected function")
            return self
        end

        self.onLeaveAction = action
        return self
    end
    
     # define the on-timer action
     # it is cyclically called if the state is the active one 
    def onTimer(action)
        var cproc="onTimer"
        if action != nil && type(action) !="function"
            print(cproc.."expected function")
            return self
        end

        self.onTimerAction = action
        return self
    end

    def tostring()
        return f"name:{self.name} transitions:{self.transitions.size()}"
    end    
end


#-------------- 

 state manager - implements the infinite state-machine

each state
  - can have multiple transisiton to other states or itself
  - implements
       onEnterAction : executed if state is entered
       onLeaveAction : executed if state is leaved
       onTimerAction : executed cyclically as long the state is active
   - after Start() command, the initial state (first defined) is entered

 --------------# 

class StateMan
    var name
    var lastLogInfo
    var lastWarnInfo
    var lastLogProc
    var infoEnable

    var states
    var current     # current state
    var prev        # previous state
    var startupState

    var timerInterval
    var timerCounter
    var timeStateChangedMillis

    var onTimer             # action on timer without state dependency
    var onStateChanged      # action when state has changed globally
    
    static trStartup = "trStartup"
    static stStartup = "stStartup"

    # log with level INFO
    def info(proc,info)
        self.lastLogProc = proc
        self.lastLogInfo = info
        if self.infoEnable print("INFO "+self.name+"."+proc+" - "+info) end
    end

    # log with level WARN
    def warn(proc,info)
        self.lastLogProc = proc
        self.lastWarnInfo = info
        print("WARN "+self.name+"."+proc+" - "+info)
    end

    def tostring()
        return f"{self.name} - {self.current=}"
    end

    def init(name)
        var cproc="init"
        self.name=name
        self.states = {}
        self.current=nil

        self.infoEnable = true
        self.info(cproc,f"{self.name} created" )
        self.infoEnable = false	
        self.timerInterval = 5
        self.timerCounter = 1
        self.timeStateChangedMillis = tasmota.millis()

        # beginning state is named startup in each case
        self.startupState= self.addState(self.stStartup);
    end

    # perform action onEnter
    def doOnEnter()
        var cproc="doOnEnter"
        # perform on-Enter for inital state
        if self.current!=nil && self.current.onEnterAction != nil
            try	
                self.info(cproc,"perform onEnter for "..self.current.name)
                self.current.onEnterAction()
            except .. as exname, exmsg
                self.warn(cproc, exname + " - " + exmsg)
            end 
        end
    end

    # start the state machine with initial state
    def start()
        self.trigger(self.trStartup)
        tasmota.add_driver(self)
    end

    # called by tasmota, performs onTimer action
    def every_second()
        var cproc="every_second"

        self.timerCounter-=1
        if self.timerCounter <=0
            self.timerCounter = self.timerInterval

            # independen action on timer
            if self.onTimer != nil
                try	
                    self.info(cproc,"perform onTimer global")
                    self.onTimer()
                except .. as exname, exmsg
                    self.warn(cproc, exname + " - " + exmsg)
                end 
            end

            # perform onTimerAction
            if self.current!=nil && self.current.onTimerAction != nil
                try	
                    self.info(cproc,"perform onTimer for "..self.current.name)
                    self.current.onTimerAction()
                except .. as exname, exmsg
                    self.warn(cproc, exname + " - " + exmsg)
                end 
            end
        end
    end

    # destructor
    def deinit()
        var cproc="deinit"
        tasmota.remove_driver(self)
        self.info(cproc,"done")
    end 

    # add a new state to state machine, first one is inital state
    def addState(name)
        var cproc="addState"

        if self.states.contains(name)
            self.warn(cproc,"already exists:"..name)
            return nil
        end
        
        var state = State(name)
        self.states[name]=state

        if size(self.states) == 2
            self.info(cproc,"initial state "..name)
            self.current=self.startupState
            self.startupState.next(name,self.trStartup)
        end

        return state
    end

    # perform a trigger that can initiate a transition
    def trigger(trigger)
        var cproc="trigger"

        var found = nil
        for trans : self.current.transitions
            if trans.trigger==trigger
                found = trans
                break
            end
        end

        if found==nil
            self.info(cproc,f"current={self.current} missing trigger={trigger}")
            return false
        end

        self.info(cproc,f"[{trigger}] {self.current.name} ==> {found.nextState}")

        # perform on-Leave
        if self.current.onLeaveAction != nil
            try	
                self.info(cproc,"perform onLeave for "..self.current.name)
                self.current.onLeaveAction()
            except .. as exname, exmsg
                self.warn(cproc, exname + " - " + exmsg)
            end 
        end

        # change state
        self.prev = self.current
        self.current = self.states[found.nextState]

        # perform on-Enter
        self.doOnEnter()
        self.timeStateChangedMillis = tasmota.millis()
        
        if self.onStateChanged != nil
            try	
                self.onStateChanged()
            except .. as exname, exmsg
                self.warn(cproc, exname + " - " + exmsg)
            end 
        end

        return true
    end

    # create a mermaid script showing the current scenario
    def mermaid()
        var ss = "stateDiagram-v2\n"
        ss+="classDef current fill:blue,font-weight:bold,color:white\n"
        ss+="classDef prev   fill:lightblue,color:black\n"

        var first=true

        for name:self.states.keys()
            if name == self.stStartup
                continue
            end

            var state=self.states[name]

            if first
                ss+="[*] -->"..state.name.."\n"
            end

            first=false

            for trans:state.transitions
                # Still --> Moving
                ss+= str(trans.fromState).." --> "..str(trans.nextState)..":"..str(trans.trigger).."\n"
                #print(trans)
            end

            if self.current!=nil
              ss+=f"class {self.current.name} current\n"
            end

            if self.prev!=nil
               ss+=f"class {self.prev.name} prev\n"
            end

        end

        return ss
    end

    # create an uri to get a rendered mermaid image
    def mermaidUri()
        import string
        import crypto
        var script = self.mermaid()
        var bb = bytes().fromstring(script) 
        var b64 = bb.tob64()
        return 'https://mermaid.ink/img/'..b64
    end

end
