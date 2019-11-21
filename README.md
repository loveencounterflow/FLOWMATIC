

![](https://raw.githubusercontent.com/loveencounterflow/flowmatic/master/artwork/flowmatic-logo-3-1-small.png)

# FlowMatic

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

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
  °powerbutton: { pressed, released, } =>
    { °powerbutton:pressed, °powerbutton:released, }
```

The powerset of all namespaced states lists all states that the model could
in theory be in; of these, some, like

```
  °mains:disconnected and °cooking:true
```

will be physically impossible, so should be
logically excluded from the states; others, such as

```
  °door:open and °cooking:true
```

are undesirable but, crucially, physically possible, and must likewise
be logically excluded.

States are views as key/value pairs, where the key identifies a *component*
of the physical machine, and the value encodes the position that component
is in or the action that the component is performing.

Observe states may be (quasi-) continuous, such as `°temparature:51C` or
`°thermostatdial:60C`; in such cases, a comparator `°temparature < °thermostatdial`
or `°temparature > °thermostatdial` can be used to decided whether to heat, to switch off
heating, to cool, or to switch off cooling, as the case may be.

Keys may also represent ongoing actions such as `°cooking:{ongoing,stopped,interrupted}`.

## Conjunctions and Disjunctions

State vectors can be linked via boolean logic:

```
°door:closed    ∧   °door^open              =>  °door:open
°door:open      ∧   °door^open              =>  °door:open
°door:open      ∧   °plug^insert            =>  °door:open
°magnetron:on   ∧   °door^open              =>  °magnetron:off
°plug:loose     ∨   °powerbutton:released   =>  °powerlight:off
°door^open                                  =>  °magnetron:off
```

The disjunction (`∨` or `or` operator or 'union') we can safely discard with as it is easily representable
by inserting multiple transitions:

```
°plug:loose ∨ °powerbutton:released   => °powerlight:off
==>
°plug:loose                           => °powerlight:off
°powerbutton:released                 => °powerlight:off
```

However, conjunctions (`∧` or `and` operator or 'intersection') must still be explicitly expressed:

```
°plug:inserted ∧ °powerbutton:pressed  =>  °powerlight:on
```

There are two ways to capture this in (Postgre)SQL: either with arrays of values, or by grouping clauses by
means of a term ID; this solution has the advantage that it leaves a natural opening for expressing
assertion/negation, here called `pred` (for 'predicate'):

```
                  'condition'               'consequence'
                  'if'                      'then'
term        pred    source_item           =>  target_item
——————————— ——————— ————————————————————— ——— ———————————————————
term:20     T       °plug:inserted        =>  °powerlight:on
term:20     T       °powerbutton:pressed  =>  °powerlight:on
term:50     T       °plug:loose           =>  °powerlight:off
term:51     T       °powerbutton:released =>  °powerlight:off
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
( a ) ∨ ( b ∧ c ) => d => ( e ∧ f )
```

holds when

```
( (   a   ) => d => ( e ∧ f ) )
∨
( ( b ∧ c ) => d => ( e ∧ f ) )
```

holds.

We will also introduce two actions, `°powerlight^on` and `°powerlight^off`, to replace the states that we
used in the earlier tables; this to express more clearly that, from the condition, a *dynamic* consequence
followed, one that, despite appearances, has multiple consequences (namely, both turn on the power indicator
*and* ring a bell).

```
                    'condition'               'consequence'
                    'if'                      'then'
term        pred    source_item           =>  target_item
——————————— ——————— ————————————————————— ——— ———————————————————
term:99     T       °foo^bar              =>  term:21
——————————— ——————— ————————————————————— ——— ———————————————————
term:20     T       °plug:inserted        =>  term:21
term:20     T       °powerbutton:pressed  =>  term:21
term:21     T       °powerlight^on        =>  term:22
term:22     T       °bell^chime               ∎
term:22     T       °powerlight:on            ∎
——————————— ——————— ————————————————————— ——— ———————————————————
term:50     T       °plug:loose           =>  term:52
term:51     T       °powerbutton:released =>  term:52
term:52     T       °powerlight^off       =>  term:53
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
term        pred    source_item           =>  target_item
——————————— ——————— ————————————————————— ——— ———————————————————
term:10     T       °powerbutton^actuate  =>  term:11
term:10     T       °powerbutton:released =>  term:11
term:11     T       °powerbutton:pressed      ∎
term:12     T       °powerbutton^actuate  =>  term:14
term:12     T       °powerbutton:pressed  =>  term:14
term:14     T       °powerbutton:released     ∎
——————————— ——————— ————————————————————— ——— ———————————————————
term:20     T       °plug:inserted        =>  term:21
term:20     T       °powerbutton:pressed  =>  term:21
term:21     T       °powerlight^on        =>  term:22
term:22     T       °bell^chime               ∎
term:22     T       °powerlight:on            ∎
```

There's yet another problem apparent: in the chain `°plug:inserted ∧ °powerbutton:pressed =>
°powerlight^on ∧ °bell^chime`, no mention of time or rising vs. falling flanks is made; therefore, if we
interpreted the phrase as being *timeless*, then the `°bell` should be `^chime`ing all the time. This is
probably not what the customer wants, an oven that rings all the time when being in use.

In order to have the bell just say 'pling', we insert a new internal verb, `°powerbutton^press`, that is
then used to both toggle the switch and chime the bell; we note that this will only work if we can make it
so that, on the one hand,

* **states (`°x:y`) are eternally valid but get overriden by later states with the same component**,

and on the other,

* **events (`°x^y`) are exhausted as soon as all direct consequences have been retrieved**.

Since we want the automaton to only process a single event in each cycle, that also implies further that

* **there are no truly simultaneous events: each event comes before or after any other, if any**

meaning that in order to model conjunctions of events: `°a^b ∧ °u^v => ...`, we have to do so by having
the events first cause a state change: `°a^b => °c:d; °u^v => °w:x;`, and only when those partial states do
combine can a consequence happen: `°c:d ∧ °w:x => ...`. So `°switch^activate ∧ °plug^insert` can *never*
be fulfilled; this will, therefore, be ruled out by a higher-order regulation to ensure that

* **a phrase may only contain at most one event**.

Instead, a more circumlocutionary suite like

```
°switch^activate                        =>  °switch:activated;
°plug^insert                            =>  °plug:inserted;
°switch:activated ∧ °plug:inserted      =>  °device^start`
```

must be used.

```
term        pred    source_item           =>  target_item
——————————— ——————— ————————————————————— ——— ———————————————————
term:10     T       °powerbutton^actuate  =>  term:11
term:10     T       °powerbutton:released =>  term:11
term:11     T       °powerbutton^press        ∎
term:11     T       °powerbutton:pressed      ∎
term:12     T       °powerbutton^actuate  =>  term:14
term:13     T       °powerbutton:pressed  =>  term:14
term:14     T       °powerbutton:released     ∎
term:14     T       °powerbutton^release      ∎
——————————— ——————— ————————————————————— ——— ———————————————————
term:20     T       °plug:inserted        =>  term:21
term:20     T       °powerbutton^press    =>  term:21
term:21     T       °powerlight^on        =>  term:22
term:22     T       °bell^chime               ∎
term:22     T       °powerlight:on            ∎
```

## Continuous Values

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
°door:closed °plug:inserted °cooking:ongoing °button^release  => °button:released °cooking:stopped
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
