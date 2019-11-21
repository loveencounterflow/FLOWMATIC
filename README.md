

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
                    'premise'                 'action'
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
allow us to notate *both* consequences *and* conditions as vectors in a unified fashion. Moreover, let's
introduce the concept of a 'phrase', which we define as the **sequence of terms that lead from (conjunctions
of) conditions (and optional intermediaries) to consequences**. In the below table, we have added a nonsense
`term:99` to show that **phrases may overlap in their consequences**; this is the effect of disjunctions:

```
( a ) ∨ ( b ∧ c ) ⇒ d ⇒ ( e ∧ f )
```

holds when

```
( (   a   ) ⇒ d ⇒ ( e ∧ f ) )
∨
( ( b ∧ c ) ⇒ d ⇒ ( e ∧ f ) )
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




------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------


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
