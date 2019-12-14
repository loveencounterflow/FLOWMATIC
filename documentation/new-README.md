

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

# XXX

* Possible to define any number of state machines
* each machine must have unique ID (path)
* machines can reference each other
* ID is a path like `power/switch`, `oven/power/switch`
* can reference relatively as in `./indicator/^on()`, `../motor/^off()`

* context, set in advance (?)
* components, concrete and abstract: 'places' to 'hold state'
* components may be nested: `oven/power/switch`; state may be associated with intermediate components as in
  when `oven/power/switch/:pressed` and `oven/power/plug/:loose` implies `oven/power/:off`; when
  `oven/power/switch/:pressed` then `oven/power/plug/insert()` triggers `oven/plug/:inserted` and
  `oven/power/:on`.

* blueprints
	* blueprints are construction plans for parts
	* Ex. binary `switch/` with two aspects (`:on`, `:off`) and single action (`toggle()`), rules are `:on
	  toggle() => :off` and `:off toggle() => :on`.
 	* each part is either a *movable part* (a component), a *declarative* part (an aspect ≡ an atomic state)
 	  or an *moving* part (an action that appears as a trigger or a move in a transition rule).
 	* each part must have a name that is unique across its local domain, so all aspects must have a
 	  designation that is distinct from that of all other aspects of that component (but aspects of child
 	  components may reuse names, so `power/:off` does not clash with, say, `power/switch/:off`; also,
 	  `power/:off` (a state) does not clash with `power/off()` (an action). It is customary to define actions
 	  to trigger their namesake states, as in `power/off() => power/:off`, `power/on() => power/:on` and so
 	  forth, but not obligatory).
 	* a blueprint may be copied into a target position (either another blueprint position or a usable
 	  machine); each part may be renamed when doing so; for example, one could derive a `light/` from a
 	  `switch/` blueprint by renaming `switch/ → light/`, `:off → :dark` and `:on → :lit`. Renaming does
 	  not alter the logic, only the appearance of a part (which may or may not be advantageous: renaming may
 	  clarify intended semantics but it also obscures the logical equivalence of two parts).

* assemblies are complex parts built from more elementary ones; e.g. above we have a `power` assembly with a
  `switch` and a `plug`, and one could add an indicator `light` to give `power/ { switch/ {
  :pressed, :released, toggle() }, plug/ { :loose, :inserted, insert(), pull() }, light/ { :on, :off, } }`,
  or, more readably,

  ```
  power/
  	:on
  	:off
  	switch/
  		:released
  		:pressed
  		toggle()
  	plug/
  		:loose
  		:inserted
  		pull()
  		insert()
  	light/
  		:on
  		:off
  ```

* aspect
* state
* action


# DB Objects

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
* `FM._current_transition_effects`
* `FM._current_transition_moves`

# Interaction via RPC

* uses [`intershop-rpc`](https://github.com/loveencounterflow/intershop-rpc) to receive notifications about
	changes in machine
* uses RPC and/or NodeJS DB adapter (such as [`pg`](https://github.com/brianc/node-postgres)) to send
	events to state machines
* RPC is bidirectional, so preferred
* must either give full paths to all components or else set context which is then tied to ID of component
	that uses RPC server


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

