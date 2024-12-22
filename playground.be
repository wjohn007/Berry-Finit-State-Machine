# enter this commands step by step in Berry console and watch output

# show the current state
print(fsm.current)

## this triggers the transition stIdle => stProcessing
fsm.trigger(trStartProcessing)


# show transistion of the current state
print(fsm.current.transitions)


## this triggers the transition stProcessing => stFinished
fsm.trigger(trProcessFinished)

## this triggers the transition stFinished => stIdle
fsm.trigger(trWaitForNextJob)


# this command creates an URL that shows the graphically  the current state of finit-state-machine
fsm.mermaidUri()




