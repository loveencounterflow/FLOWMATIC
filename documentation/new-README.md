

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


# Parts and Rules

* Three kinds of parts:
  * components (to be renamed?) (always defined as an absolute path, so all components are always
    subcomponents, except for the ones at the root)
  * (elementary) states (like actions always bound to a component)
  * actions (always bound to a component, possibly root, so `/foo()` is a possible rule)
    * an action is either *pending* (imminent, queued for later), or *settled* (*fulfilled* or *rejected*)
    * while being pending, an action may be *current* (in the process of being fulfilled)
    * in analogy to ([JavaScript ES6
      Promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise))
    * except for 'current' not being in that spec; to simplify, we speak of *queued*, *current*,
      *fulfilled*, *rejected*; 'pending', then, is 'queued' or 'current', and 'settled' is 'fulfilled' or
      'rejected'.

* so far excluded to declare sub-actions or sub-states of actions or states, so `foo()/:bar`, `foo()/bar()`
  &c. not possible, only `cmp1/cmp2/.../cmpn/action1()` is a legal path, hence **the leaves (tips) of a
  FlowMatic tree are always and only actions and states, its branches are always and only components.**

* Rules are how trees can 'move' (change state):
  * rules are `( condition, consequent )` pairs, where `conditions` in turn are `( premise, trigger, )`
    pairs, with premises being conjunctions of states and the trigger an action; consequents are `( effect,
    move )` pairs with effects being sets of state changes to be applied and moves sequences of actions to
    be queued.
  * a premise, that is, a conjunction (`∧` or `and` operator or 'intersection') of a set of state (or state
    matchers);
  * a trigger, that is an action that occurs (becomes 'current' as defined above) at a point in time when
    all the terms of the premise are met with (match).—Since no two actions may occur at the same time,
    **each rule must have exactly one action** (although it is conceivable to define a conjunction of a set
    of states and a (disjunction (`∨` or `or` operator or 'union')) of a set of actions), i.e. `( :s1 ∧ :s2
    ∧ ... :sn ) ∧ ( a1() ∨ a2() ∨ ... )` such that the rule is relevant whenever all of the states and one
    of the actions becomes current; such cases, however, can be broken down to as many alternative rules as
    there are disjunct actions in the compound trigger)
  * enter/exit rules can be triggered by entering (reaching) or exiting (leaving) a given (complex or
    elementary) state; these may be declared by using the abstract root actions `/~enter()`, `/~exit()`.
    Each time a rule is processed that changes at least one elementary state, an sequence `/~exit()`,
    `/~enter()` pair of events will be emitted with the old and the new states, respectively, as payloads;
    no such events will be emitted in case a rule did not effect any change in state.
  * rules that do not have any explicit premises will become active whenever a given event is emitted (i.e.
    the default premise is the empty premise which matches all states).
  * rules that do not have an explicit trigger will become active whenever a state that matches the premises
    is entered (i.e. the default trigger is `/~enter()`).

# Outline of a Simple Machine

An appliance named `blink` with a `plug`, a `light` that can be `toggle()`d, and a stateless `timer` that
can `tick()`:

```
E                     A                     V
place                 role                  quality     comment
———————————————————————————————————————————————————————————————————————————————
/apps/blink/timer     action                tick()
...............................................................................
/apps/blink/light     state                 :off        # default state
/apps/blink/light     state                 :on
/apps/blink/light     action                toggle()
...............................................................................
/apps/blink/plug      state                 :unplugged      # default state
/apps/blink/plug      state                 :inserted
———————————————————————————————————————————————————————————————————————————————
```

When the light is on and is toggled, it is turned off:

```
———————————————————————————————————————————————————————————————————————————————
/rules[1]             premise               /apps/blink/light/:on
/rules[1]             trigger               /apps/blink/light/toggle()
/rules[1]             effect                /apps/blink/light/:off
———————————————————————————————————————————————————————————————————————————————
```

When the light is off and is toggled, the light is turned on, but *only* when the plug is inserted, too:

```
———————————————————————————————————————————————————————————————————————————————
/rules[2]             premise               /apps/blink/plug/:inserted
/rules[2]             premise               /apps/blink/light/:off
/rules[2]             trigger               /apps/blink/light/toggle()
/rules[2]             effect                /apps/blink/light/:on
———————————————————————————————————————————————————————————————————————————————
```

When the timer ticks, an intent to toggle the app's light is queued:

```
———————————————————————————————————————————————————————————————————————————————
/rules[3]             trigger               /apps/blink/timer/tick()
/rules[3]             move                  /apps/blink/light/toggle()
———————————————————————————————————————————————————————————————————————————————
```

We can capture the fact that the light can never be on when the plug is not inserted:

```
———————————————————————————————————————————————————————————————————————————————
/rules[4]             premise               /apps/blink/plug/:unplugged
/rules[4]             effect                /apps/blink/light/:off
———————————————————————————————————————————————————————————————————————————————
```

One could safeguard against internal errors by introducing an error action (assuming `~error()` being a
system-level feature that can be attached to any component; also observe since we don't declare a trigger,
the implicit trigger `/~enter()` is used):

```
———————————————————————————————————————————————————————————————————————————————
/rules[5]             premise               /apps/blink/plug/:unplugged
/rules[5]             premise               /apps/blink/light/:off
/rules[5]             move                  /apps/blink/light/~error("impossible state")
———————————————————————————————————————————————————————————————————————————————
```



* not possible now, but conceivably later we can [allow trees to modify themselves (grow or
  shrink)](https://de.wikipedia.org/wiki/Anatoli_Dneprow#Leben) based on (their own or another machine's)
  rules; such rules could add, modify or delete components, states, actions, and, potentially, rules

# Common Ecosystem

* there is no hard-cut division between components or machines, they always share a common space; one
  machine may potentially always 'reach over' and issue an event that changes another machine's state (i.e.
  components always share a common ecosystem)

# XXX

* Possible to define any number of state machines
* each machine must have unique ID (path)
* machines can reference each other
* ID is a path like `power/switch`, `oven/power/switch`
* can reference relatively as in `./indicator/^on()`, `../motor/^off()`

* context, set in advance (?)
* components, concrete and abstract: 'places' to 'hold state'
* components may be nested: `oven/power/switch`; state may be associated with intermediate components as in
  when `oven/power/switch/:pressed` and `oven/power/plug/:unplugged` implies `oven/power/:off`; when
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
  :pressed, :released, toggle() }, plug/ { :unplugged, :inserted, insert(), pull() }, light/ { :on, :off, } }`,
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
      :unplugged
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

