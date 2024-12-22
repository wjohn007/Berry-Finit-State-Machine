# define the states
stIdle = "stIdle"
stProcessing = "stProcessing"
stFinished = "stFinished"

# define the transistions
trStartProcessing = "StartProcessing"
trProcessFinished= "ProcessFinished"
trWaitForNextJob = "WaitForNextJob"


# create the state manager
fsm = StateMan("fsm-demo")

# define state stIdle
fsm
    .addState(stIdle) 

    # define the transistion to following state (multiple definitions are allowed)
    .next(stProcessing,trStartProcessing) 

    # define a callback method, when the state is entered
    .onEnter(def () print(f"entering {stIdle}") end)

    # define a callback method when the state is leaved
    .onLeave(def () print(f"leaving {stIdle}") end)
    
    # define a callback method the will be cyclically called, when the state is active
    .onTimer(def () print(f"just in state {stIdle}") end)

# define state stProcessing
fsm
    .addState(stProcessing)
    .next(stFinished,trProcessFinished)
    .onEnter(def () print(f"entering {stProcessing}") end)
    .onLeave(def () print(f"leaving {stProcessing}") end)
    .onTimer(def () print(f"just in state {stProcessing}") end)

# define state stFinished    
fsm
    .addState(stFinished)
    .next(stIdle,trWaitForNextJob)
    .onEnter(def () print(f"entering {stFinished}") end)
    .onLeave(def () print(f"leaving {stFinished}") end)
    .onTimer(def () print(f"just in state {stFinished}") end)



# print out infos
fsm.infoEnable=true

# start the state-machine
fsm.start()