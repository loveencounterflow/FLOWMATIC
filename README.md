

![](https://raw.githubusercontent.com/loveencounterflow/flowmatic/master/artwork/flowmatic-logo-3-1-small.png)

# FlowMatic

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

  - [Representation of State](#representation-of-state)
  - [Complex State](#complex-state)
  - [Conjunctions and Disjunctions](#conjunctions-and-disjunctions)
  - [Continuous Values](#continuous-values)
  - [Comparisons](#comparisons)
  - [If / Then / Else Conditions](#if--then--else-conditions)
  - [Loops](#loops)
  - [Composability](#composability)
  - [Turing Completeness](#turing-completeness)
  - [XXX](#xxx)
  - [Sigils](#sigils)
- [The FlowMatic Finite Automaton](#the-flowmatic-finite-automaton)
  - [Symbolic and Built-In States](#symbolic-and-built-in-states)
  - [Symbolic and Built-In Acts](#symbolic-and-built-in-acts)
  - [Constraints on Transitions Table](#constraints-on-transitions-table)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


<!-- https://github.com/davidmoten/state-machine -->

## Representation of State

* pair component, aspect (and possibly parameter)
* recorded in table `statelog`
* append-only, only the most recent entry counts
* can also use `update` instead of `insert`, but then no history visible
* each component must have exactly one valid entry in `statelog`; these are called the 'Current Component
  State Vector' (CCSV)
* current state of the FSM is then the union of the most recent event and the Current Component State
  Vector
* all **pairs**—states and events—always have a component in the first position—also called the
  **topic**—and a either an aspect (for states) or else an action (for events) in the second position, the
  **focus**.

## Complex State

model complex state as sets of facets, eg.:

```
  °door:          { open,      close, }
  °cooking:       { true,      false, }
  °mains:         { connected, disconnected, }
  °powerbutton:   { pressed,   released, }
```

from keys with various possible aspects follows a number of namespaced states:

```
  °powerbutton: { pressed, released, } ⇒
    { °powerbutton:pressed, °powerbutton:released, }
```

States are `°component:aspect` pairs. The `°component` identifies a material or abstract part of a real or
imaginary machine; the `:aspect`—in its simplest form a binary tag—encodes the position that part is in or
the activity that the component is performing. Static aspects and dynamic aspects ('activities') are not
formally separated.

The set of all state vectors whose elements enumerate each `°component:aspect` pair:

```
{
  [ °a:a1, °b:b1, °c:c1, ... ],
  [ °a:a2, °b:b1, °c:c1, ... ],
  [ °a:a3, °b:b1, °c:c1, ... ],
  [ °a:a1, °b:b2, °c:c1, ... ],
  [ °a:a2, °b:b2, °c:c1, ... ],
  [ °a:a3, °b:b2, °c:c1, ... ],
  ...
  }
```

will be fairly large even for smallish models; for example, a system with three components which assume one
of 3, 2, and 4 aspects, respectively, is `3 * 2 * 4 = 24`; add two more binary components and you're already
looking at `24 * 2 * 2 = 92` possible states. This phenomenon—that complex machinery, most of all computers
with their gazillions of binary switches, may be in any one of an unfathomable huge number of distinct
states—is known as the [combinatorial state
explosion](https://en.wikipedia.org/wiki/Combinatorial_explosion) and can be seen as one of the motivating
factors to research finite state automata at all.

As far as an automaton is intended to model a real-world machine, e.g. a microwave oven, a fair number of
the multitude of expressible states may be deemed physically impossible (like `°mains:disconnected ∧
°magnetron:on`), so could be logically excluded from the states.

Other state vectors, such as `°door:open ∧ °magnetron:on` may be undesirable but imaginable when something
goes wrong. Of course, a microwave oven that is running with an open door is clearly broken, so there may be
a point in introducing a rule like `°door:open ∧ °magnetron:on ⇒ °oven:broken`. After all, in real
microwaves there will be both a switch in the door to sense whether the door is shut (instead of making the
`°door:open` state solely reliant on prior actions without regard to actual physical state of the part),
and, presumably, there will also be a sensor to measure current in critical parts of the circuitry, so it
makes sense to introduce a safety net that cuts the mains should `°door:open` and `°magnetron:on` ever
coincide. In other words, it will always be possible to either rule out unwanted or physically unlikely and
impossible states, or else to connect them to emergency handlers, both to test the functionality of the
automaton itself and as a guide which safety measures could be implemented in the physical machine.

## Conjunctions and Disjunctions

State vectors can be linked via boolean logic:

```
°door:closed    ∧   °door^open              ⇒  °door:open
°door:open      ∧   °door^open              ⇒  °door:open
°door:open      ∧   °plug^insert            ⇒  °door:open
°magnetron:on   ∧   °door^open              ⇒  °magnetron:off
°plug:loose     ∨   °powerbutton:released   ⇒  °powerlight:off
°door^open                                  ⇒  °magnetron:off
```

The disjunction (`∨` or `or` operator or 'union') we can safely discard with as it is easily representable
by inserting multiple transitions:

```
°plug:loose ∨ °powerbutton:released   ⇒ °powerlight:off
                        ⬌
°plug:loose                           ⇒ °powerlight:off
°powerbutton:released                 ⇒ °powerlight:off
```

However, conjunctions (`∧` or `and` operator or 'intersection') must still be explicitly expressed:

```
°plug:inserted ∧ °powerbutton:pressed  ⇒  °powerlight:on
```

There are two ways to capture this in (Postgre)SQL: either with arrays of values, or by grouping clauses by
means of a term ID; this solution has the advantage that it leaves a natural opening for expressing
assertion/negation, here called `pred` (for 'predicate'):

```
                    'condition'               'consequence'
                    'premise'
                    'if'                      'then'
term        pred    source_item           ⇒  target_item
——————————— ——————— ————————————————————— ——— ———————————————————
term:20     T       °plug:inserted        ⇒  °powerlight:on
term:20     T       °powerbutton:pressed  ⇒  °powerlight:on
term:50     T       °plug:loose           ⇒  °powerlight:off
term:51     T       °powerbutton:released ⇒  °powerlight:off
```

It can be readily seen that in the above table

* assuming there are only two states for the `°plug` (either `:inserted` or `:loose`), we can also write
  `not °plug:inserted` for `°plug:loose` and vice versa;
* the term IDs for disjunct items must all be different (hence, 'dis'junction); and
* the value for `target_item` must be the same for all rows referring to the same term.

This leads us to a generalization: what if we didn't use a target *item* but a target *term*? That would
allow us to notate *both* consequents *and* conditions as vectors in a unified fashion. Moreover, let's
introduce the concept of a 'phrase', which we define as the **sequence of terms that lead from (conjunctions
of) conditions (and optional intermediaries) to consequents**. In the below table, we have added a nonsense
`term:99` to show that **phrases may overlap in their consequents**; this is the effect of disjunctions:

```
( a ∨ b ) ⇒ d
```

holds when

```
( a ⇒ d ) ∨ ( b ⇒ d )
```

holds.

We will also introduce two actions, `°powerlight^on` and `°powerlight^off`, to replace the states that we
used in the earlier tables; this to express more clearly that, from the condition, a *dynamic* consequence
followed, one that, despite appearances, has multiple consequences (namely, both turn on the power indicator
*and* ring a bell).

```
                    'condition'               'consequence'
                    'if'                      'then'
term        pred    source_item           ⇒  target_item
——————————— ——————— ————————————————————— ——— ———————————————————
term:99     T       °foo^bar              ⇒  term:21
——————————— ——————— ————————————————————— ——— ———————————————————
term:20     T       °plug:inserted        ⇒  term:21
term:20     T       °powerbutton:pressed  ⇒  term:21
term:21     T       °powerlight^on        ⇒  term:22
term:22     T       °bell^chime               ∎
term:22     T       °powerlight:on            ∎
——————————— ——————— ————————————————————— ——— ———————————————————
term:50     T       °plug:loose           ⇒  term:52
term:51     T       °powerbutton:released ⇒  term:52
term:52     T       °powerlight^off       ⇒  term:53
term:53     T       °powerlight:off           ∎
```


One may note at this junction that the states of the `°powerbutton` component have not been modelled
satisfactorily; after all, there should normally some kind of user interaction that is responsible for
toggling its state. Regardless of whether we have a switch that requires flipping or pressing it, what the
user does is reverse the state of switch by some kind of gesture; let's model this as a verb `^actuate`.
This, then, leads to the next refinement.

Observe that `°powerbutton^actuate` is like a **public member** of the microwave's 'API', as it were,
whereas `°powerlight^on` and `^off` are like **private members** in that they cannot be directly caused from
outside of the automaton:

```
term        pred    source_item           ⇒  target_item
——————————— ——————— ————————————————————— ——— ———————————————————
term:10     T       °powerbutton^actuate  ⇒  term:11
term:10     T       °powerbutton:released ⇒  term:11
term:11     T       °powerbutton:pressed      ∎
term:12     T       °powerbutton^actuate  ⇒  term:14
term:12     T       °powerbutton:pressed  ⇒  term:14
term:14     T       °powerbutton:released     ∎
——————————— ——————— ————————————————————— ——— ———————————————————
term:20     T       °plug:inserted        ⇒  term:21
term:20     T       °powerbutton:pressed  ⇒  term:21
term:21     T       °powerlight^on        ⇒  term:22
term:22     T       °bell^chime               ∎
term:22     T       °powerlight:on            ∎
```

There's yet another problem apparent: in the chain `°plug:inserted ∧ °powerbutton:pressed ⇒
°powerlight^on ∧ °bell^chime`, no mention of time or rising vs. falling flanks is made; therefore, if we
interpreted the phrase as being *timeless*, then the `°bell` should be `^chime`ing all the time. This is
probably not what the customer wants, an oven that rings all the time when being in use.

In order to have the bell just say 'pling', we insert a new internal verb, `°powerbutton^press`, that is
then used to both toggle the switch and chime the bell; we note that this will only work if we can make it
so that, on the one hand,

* **states (`°x:y`) are potentially eternally valid but get overriden by later states with the same
  component,**

and on the other,

* **events (`°x^y`) are exhausted as soon as all direct consequences have been retrieved.**

Since we want the automaton to only process a single event in each cycle, that also implies further that

* **there are no truly simultaneous events: each event comes before or after any other, if any**

meaning that in order to model conjunctions of events: `°a^b ∧ °u^v ⇒ ...`, we have to do so by having
the events first cause a state change: `°a^b ⇒ °c:d; °u^v ⇒ °w:x;`, and only when those partial states do
combine can a consequence happen: `°c:d ∧ °w:x ⇒ ...`. So `°switch^activate ∧ °plug^insert` can *never*
be fulfilled; this will, therefore, be ruled out by a higher-order regulation to ensure that

* **a phrase may only contain at most one event.**

Instead, a more circumlocutionary suite like

```
°switch^activate                        ⇒  °switch:activated;
°plug^insert                            ⇒  °plug:inserted;
°switch:activated ∧ °plug:inserted      ⇒  °device^start`
```

must be used.

```
term        pred    source_item           ⇒  target_item
——————————— ——————— ————————————————————— ——— ———————————————————
term:10     T       °powerbutton^actuate  ⇒  term:11
term:10     T       °powerbutton:released ⇒  term:11
term:11     T       °powerbutton^press        ∎
term:11     T       °powerbutton:pressed      ∎
term:12     T       °powerbutton^actuate  ⇒  term:14
term:13     T       °powerbutton:pressed  ⇒  term:14
term:14     T       °powerbutton:released     ∎
term:14     T       °powerbutton^release      ∎
——————————— ——————— ————————————————————— ——— ———————————————————
term:20     T       °plug:inserted        ⇒  term:21
term:20     T       °powerbutton^press    ⇒  term:21
term:21     T       °powerlight^on        ⇒  term:22
term:22     T       °bell^chime               ∎
term:22     T       °powerlight:on            ∎
```

## Atoms, Pairs, Terms, Clauses and Phrases

### Atoms: the Elementary Parts

In FlowMatic, atoms represent the samlles parts that transition phrases are made of. They come in three
flavors, namely **`°components`**, **`^verbs`**, and **`:aspects`**, here written with their respective
discerning sigils.

### Pairs: States and Actions

Pairs are tuples of a **`°component`** and either a **`^verb`** (when it is known as an **action**) or else
an **`:aspect`** (when it is known as an (elementary) **state**). Pairs are introduced into the system to
make sure that only licensed combinations may appear in transition rules and events sent in from the
outside. Pairs are customarily written with both parts running together as in `°bell^ring` or
`°door:closed`.


### Phrases

Phrases are **sequence of terms that lead from (conjunctions
of) conditions to consequents**

```
( °FSM:IDLE ∧ °FSM:ACTIVE ∧ ... ) ⇒ ( °FSM^RESET ∧ °FSM^START ∧ ... )
```

```
    °FSM:IDLE
  + °FSM:ACTIVE
  + ...
  ——————————————————————
  = °FSM^RESET
  + °FSM^START
  + ...
```


<!--
\Rightarrow ⇒
\vee        ∨
\wedge      ∧
 -->


## Continuous Values

States may be (quasi-) continuous, such as `°temparature:51C` or `°thermostatdial:60C`; in such cases, a
comparator `°temparature < °thermostatdial` or `°temparature > °thermostatdial` can be used to decide
whether to heat, to switch off heating, to cool, or to switch off cooling, as the case may be.


## Comparisons

* `°thermometer:temp` `<` `-18C`
* `°bicycle:speed`    `>` `25kmh`
* `°light:on`         `=` `true`


## If / Then / Else Conditions

## Loops

## Composability

## Turing Completeness

## XXX

```
    °door         :closed
  + °plug         :inserted
  + °cooking      :stopped
  + °startbutton  :released
  + °startbutton  ^press
  ——————————————————————————
  = °button       :pressed
  + °cooking      :ongoing

  + °cooking      :ongoing
  + °heater       :on
  + °temparature  :toohigh
  ——————————————————————————
  = °heater       :off

  + °cooking      :ongoing
  + °heater       :off
  + °temparature  :toolow
  ——————————————————————————
  = °heater       :on
```

```
°door:closed °plug:inserted °cooking:ongoing °button^release  ⇒ °button:released °cooking:stopped
```

```
  notation format:

    '°mainswitch:released, °mainswitch^actuate => °mainswitch:pressed'

  extended with predicates:

    '°thermometer:temp%" x > 50°C "         => °heater^switchoff'
    '°thermometer:temp%" x < 45°C "         => °heater^switchon'
    '°thermometer:temp%" 50°C < x "         => °indicator:color%red
    '°thermometer:temp%" 45°C < x < 50°C "  => °indicator:color%green
    '°thermometer:temp%" 45°C > x "         => °indicator:color%blue

  basic form of negation:
    '°box%not:open'
    '°box:open%not'

```



## Sigils

```
°components
:aspects
?guards
^verbs
+actions
event:  °component^verb
state:  °component:aspect
```

## Microwave Oven model

Components:

```
°switch       main switch, °switch^toggle => :on or :off
°start        start switch to initiate cooking procedure when °start^press occurs
°indicator    indicator light, :on when operating, :off otherwise
°lighting     cooking space illumination, :on when powered and door closed, :off otherwise
°magnetron    heating element, :on when operating, :off otherwise
°timer        starts :running with fixed delta time, terminates cooking when delta time is over
°power        :on or :off, indicates whether appliance connected to mains
°door         when :open, inhibits cooking; when :closed, allows cooking
```

## Tripartite Phrase Model (Upcoming)

* machine state described by `°component:aspect` pairs
* these form a state vector
* each component has `n > 1` possible aspects
* plus one abstract aspect `:*` (not formally necessary, but practical):
* `:*` means 'match any aspect' in the condition
* `:*` means 'no change' in the consequent
* a transition phrase consists of condition, event, consequent
* event is always one single `°component^verb`
* or an abstract default event, call it `°_^next` (where `°_` symbolizes the engine component itself)
* both condition (`cond`) and consequent (`csqt`) are formally always complete machine state vectors (with
  wildcard elements indicated by `:*` aspects), in practice only relevant matches and state changes need be
  written
* machine transitions from `cond` state to `csqt` state when all `cond` terms match and event occurs
* after state transition has been performed, any number of *moves* ('future events') may be queued
* possible to declare transitions without conditions but with event
* possible to declare transitions without consequents but with one or more moves
* *conflict resolution*: more than a single phrase may match given at any step.
  * All matching phrases are activated in the order defined;
  * when resolving,
    * all consequents of all phrases will be set, in the order of their declaration
    * all moves of all phrases will be queued, in the order of their declaration.
  * There *may* be later a way to avoid queueing duplicate, non-initial or non-final moves should the need
    arise. Until then, *each matching premise instates and evokes all the terms and moves of the RHS*.

* consider to abolish (all?) sigils, use path notation, write e.g. `switch/on` for state, `switch/on()`
  (with arguments within parens: `console/print(text:"x")`) for events, square brackets (?) for
  multifacetted and continuous values e.g. `cpu1/temp[47°C]`; possibly use paths to denote nested machines

```
┌──────────────────────────────────────────────┐
│                     phrase                   │
├───────────────────────┬──────────────────────┤
│    LHS: conditions    │   RHS: consequents   │
├────────────┬──────────┼───────────┬──────────┤
│  premises  │ trigger  │   effect  │   moves  │
└────────────┴──────────┴───────────┴──────────┘
```


> An event is what causes a state machine to transition from its current state to its next state. All state
> transitions in a state machine are due to these events; state cannot change unless some stimulus (the
> event) causes it to change.—https://xstate.js.org/docs/guides/events.html#sending-events

Mnemonic:

```
transition phrase := IF °con:ditions WHEN °e^vent THEN °con:sequents QUEUE °mo^ves
transition phrase :=
  match °con:dition1, °con:dition2
    waitfor °e^vent
    apply   °con:sequent1, °con:sequent2
    emit    °mo^ve1, °mo^ve2
```

> A transition phrase declares, on the left hand side, a number of state conditions to be met and exactly
> one an event (the trigger) to occur; and, on the right hand side, a number of state consequents to be
> followed, plus any number of moves (future events) to be queued.


```
°light:off  &  °_^next   =>  °light:on   ||  °_^next
°light:on   &  °_^next   =>  °light:off  ||  °_^next

°light:off  &  °light^on   =>  °light:on   ||  °timer^sleep%0.5s, °light^off, °timer^sleep%0.5s, °light^on
°light:on   &  °light^off  =>  °light:off

°plug:disconnected  & °_^* => °power:off
°power:off          & °_^* => °light:off

°con:dition & °e^vent => °con:sequent || °mo^ve1, °mo^ve2, ...


```

`°_^*`—occurs implicitly
`°_^+`—any explicit event

```
╔═════════╤════════╤════════╤════════════╤═══════════════╤════════════╤════════════╗
║ phrasid │ condid │ csqtid │ cond_topic │  cond_focus   │ csqt_topic │ csqt_focus ║
╠═════════╪════════╪════════╪════════════╪═══════════════╪════════════╪════════════╣
║       1 │      1 │      1 │ °FSM       │ :IDLE         │ °FSM       │ :ACTIVE    ║
║       1 │      2 │      1 │ °FSM       │ ^START        │ °FSM       │ :ACTIVE    ║
║       2 │      1 │      1 │ °switch    │ :off          │ °switch    │ :on        ║
║       2 │      2 │      1 │ °switch    │ ^toggle       │ °switch    │ :on        ║
║       3 │      1 │      1 │ °switch    │ :on           │ °switch    │ :off       ║
║       3 │      2 │      1 │ °switch    │ ^toggle       │ °switch    │ :off       ║
║       4 │      1 │      1 │ °plug      │ :disconnected │ °power     │ :off       ║
║       4 │      2 │      1 │ °FSM       │ ^TICK         │ °power     │ :off       ║
║       5 │      1 │      1 │ °switch    │ :off          │ °power     │ :off       ║
║       5 │      2 │      1 │ °FSM       │ ^TICK         │ °power     │ :off       ║
╚═════════╧════════╧════════╧════════════╧═══════════════╧════════════╧════════════╝
```

```
╔═════════╤════════╤════════╤════════════╤═══════════════╤════════════╤════════════╗
║ phrasid │ condid │ csqtid │ cond_topic │  cond_focus   │ csqt_topic │ csqt_focus ║
╠═════════╪════════╪════════╪════════════╪═══════════════╪════════════╪════════════╣
║       1 │      1 │      1 │ °FSM       │ :IDLE         │ °FSM       │ :ACTIVE    ║
║       1 │      2 │      1 │ °FSM       │ ^START        │ °FSM       │ :ACTIVE    ║
║       2 │      1 │      1 │ °switch    │ :off          │ °switch    │ :on        ║
║       2 │      2 │      1 │ °switch    │ ^toggle       │ °switch    │ :on        ║
║       3 │      1 │      1 │ °switch    │ :on           │ °switch    │ :off       ║
║       3 │      2 │      1 │ °switch    │ ^toggle       │ °switch    │ :off       ║
║       4 │      1 │      1 │ °plug      │ :disconnected │ °power     │ :off       ║
║       4 │      2 │      1 │ °FSM       │ ^TICK         │ °power     │ :off       ║
║       5 │      1 │      1 │ °switch    │ :off          │ °power     │ :off       ║
║       5 │      2 │      1 │ °FSM       │ ^TICK         │ °power     │ :off       ║
╚═════════╧════════╧════════╧════════════╧═══════════════╧════════════╧════════════╝

conditions                      | trigger        |  consequents
°FSM    °switch   °plug         |                |  °FSM    °switch   °plug
————————————————————————————————————————————————————————————————————————————————————
:IDLE   ---       ---           | °FSM^START     |  :ACTIVE ---       ---
---     :off      ---           | °switch^toggle |  ---     :on       ---
---     :on       ---           | °switch^toggle |  ---     :off      ---
---     ---       :disconnected | °plug^insert   |  ---     ---       :inserted
---     ---       :inserted     | °plug^pull     |  ---     ---       :disconnected

```



------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------


## Configuration

in `intershop.ptv`:

```
flowmatic/debugging                   ::boolean=          true
flowmatic/journal/eventbraces         ::boolean=          true
flowmatic/moves/autoplay              ::boolean=          true
flowmatic/emit/autoplay               ::boolean=          true
```

* **`flowmatic/journal/eventbraces`**—whether to use two events, one with status `<` and one with status `>`
  that come before and after any state changes caused by that event. Events that were successfully processed
  but did not result in any changes will have status `=`.

* **`flowmatic/moves/autoplay`**—whether to automatically process any events that resulted from any
  consequent (i.e. all moves) until event queue is empty.

* **`flowmatic/emit/autoplay`**—whether to automatically process any events that have been `emit()`ted by
  the user.

# The FlowMatic Finite Automaton

## Symbolic and Built-In States


* `FIRST`—the point of a `RESET` act; must be the 'point of origin' in the transition table.

* `LAST`—

* `*`—a.k.a. 'star' or 'catchall tail'; a transition with a catchall tail will
  match any point, even a non-existing one when the journal is empty after after
  initialization and can thus be used to bootstrap the FA.

* `...`—a.k.a. 'ellipsis', 'anonymous', 'continuation' or 'continue'; may occur
  as point (where it signifies 'continue with next transition' in order of
  inseetion to transitions table) or as tail (where it means 'continued from
  previous transition').

## Symbolic and Built-In Acts


* `RESET`—to be called as the first act after setup; initializes journal (but
  not the board).

* `START`—to be called as the first act of a new case.

* `STOP`-to be called as the last act of a case.

* `->`—a.k.a. 'walkthrough', 'then' or 'auto-act'; indicates that the
  assciatiated command is to be executed without waiting for the next act. This
  allows to write sequences of commands.

## Constraints on Transitions Table

* All tuples `( tail, act )` must be unique; there can only be at most one
  transition to follow when the current state is paired with the upcoming act.
  The exception is the tuple `( '...', '->' )`, which may occur any number of
  times.

* A '\*' (star) in the tail of a transition makes the associated act unique; IOW,
  a starred act can have only this single entry in the transitions table.
  **Note** It is possible that we re-define the star to mean 'default'
  transition for a given act in the future and lift this restriction.

* A transition that *ends* in `...` (continuation) must be followed by a
  transiton that *starts* with a `...` (continuation); the inverse also holds.
  IOW, continuation points and tails must always occur in immediately adjacent
  lines of the transitions table.

* For the time being, a transition with a continuation tail must have a
  walkthrough act. That is, a series of commands that are connected by `...`
  (continuations) can not wait for a specific action anywhere; such series must
  always run to completion until a properly named point is reached.

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

Alternative implementation of transition phrases with 'column vectors', that is to say, both the first and
second parts (topics and focuses) of the terms of both the condition pairs and the consequent pairs get
stored separatedly; they can be repaired by iterating over indices since `|cond_topics| =
|cond_focuses|` and `|csqt_topics| = |csqt_focuses|`, respectively; as a result, the representation of a
transition phrase like `°FSM:IDLE,°FSM^START => °FSM:ACTIVE` is rather less nested (no arrays of
composite types), and while there are, naturally, more columns, they are more narrowly typed. This is a
good thing since now there's an obvious place where to put predicates in the future (namely, into two
dedicated columns `cond_predicates`, `csqt_predicates`):

```
 FM.transition_phrases
╔════╤══════════════════════════════════╤════════════════════╗
║ id │              conds               │       csqts        ║
╠════╪══════════════════════════════════╪════════════════════╣
║  1 │ {"(°FSM,:IDLE)","(°FSM,^START)"} │ {"(°FSM,:ACTIVE)"} ║
╚════╧══════════════════════════════════╧════════════════════╝

 FM.transition_phrases_2
╔════╤═════════════╤════════════════╤═════════════╤══════════════╗
║ id │ cond_topics │  cond_focuses  │ csqt_topics │ csqt_focuses ║
╠════╪═════════════╪════════════════╪═════════════╪══════════════╣
║  1 │ {°FSM,°FSM} │ {:IDLE,^START} │ {°FSM}      │ {:ACTIVE}    ║
╚════╧═════════════╧════════════════╧═════════════╧══════════════╝
```
I say 'column vectors b/c that's how one should read them:
```
╔════╤═════════════╤════════════════╤═════════════╤══════════════╗
║ id │ cond_topics │  cond_focuses  │ csqt_topics │ csqt_focuses ║
╠════╪═════════════╪════════════════╪═════════════╪══════════════╣
║  1 │ {°FSM,      │ {:IDLE,        │ {°FSM}      │ {:ACTIVE}    ║
║    │  °FSM}      │  ^START}       │             │              ║
╚════╧═════════════╧════════════════╧═════════════╧══════════════╝
```

This form may be easily rewritten into a more standard relational form without arrays:

```
╔════╤═════════════╤════════════════╤═════════════╤══════════════╗
║ id │ cond_topics │  cond_focuses  │ csqt_topics │ csqt_focuses ║
╠════╪═════════════╪════════════════╪═════════════╪══════════════╣
║  1 │  °FSM       │  :IDLE         │  °FSM       │  :ACTIVE     ║
║  2 │  °FSM       │  ^START        │  °FSM       │  :ACTIVE     ║
╚════╧═════════════╧════════════════╧═════════════╧══════════════╝
```

And of course, `(cond_topics,cond_focuses)` and `(csqt_topics,csqt_focuses)` should be modelled as
references to the `pairs` table because that is what they are, quotes of elements of the set of licensed
pairs (states and actions). That, however, can only be done with intermediate `m:n` relations, which
have been conveniently omitted here. *But* when we introduce predicates (a.k.a. 'payloads'), then things
get more involved, so let's keep the conceptually simpler model for the time being.



# To Do

* [X] declaring pairs should be enough to implicitly declare atoms
* [ ] allow default / unnamed component, actions without component
* [ ] implement moves on state enter, exit
* [ ] build transitions view that links states with events

