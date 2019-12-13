

![](https://raw.githubusercontent.com/loveencounterflow/flowmatic/master/artwork/flowmatic-logo-3-1-small.png)

# FlowMatic

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Parts](#parts)
  - [Public](#public)
    - [Atoms](#atoms)
    - [Rules / Transition Phrases](#rules--transition-phrases)
    - [Transitions](#transitions)
    - [Journal](#journal)
    - [Current (User) State](#current-user-state)
    - [Current Event](#current-event)
    - [Current Transition Consequents](#current-transition-consequents)
    - [Queue](#queue)
  - [Internal](#internal)
    - [Effects and Moves of Current Transition, Captured](#effects-and-moves-of-current-transition-captured)
- [To Do](#to-do)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Parts

## Public
### Atoms
### Rules / Transition Phrases
### Transitions
`FM.transitions`
### Journal
### Current (User) State
### Current Event
### Current Transition Consequents
`current_transition_consequents`
### Queue
## Internal
### Effects and Moves of Current Transition, Captured
`FM._current_transition_effects`
`FM._current_transition_moves`


# To Do

* [X] declaring pairs should be enough to implicitly declare atoms
* [ ] allow default / unnamed component, actions without component
* [ ] implement moves on state enter, exit
* [ ] build transitions view that links states with events
* [ ] implement path syntax, abolish sigils
* [ ] implement payloads for events
* [ ] implement valued states
* [ ] use unified, indexed values for journal status, display differently in custom journal view according
  to journalling mode
* [ ] 1. introduce machine ID or similar measure so any number of state machines can be implemented within
  the same tables
* [ ] 2. parse transition phrases using a state machine
* [ ] 3. profit
* [ ] record phrasid in journal to indicate which transition phrase was activated

