https://github.com/davidmoten/state-machine

model complex state as sets of facets, eg.:

```
  °door:          { open,      close, }
  °cooking:       { true,      false, }
  °mains:         { connected, disconnected, }
  °powerbutton:   { pressed,   released, }
```

from keys with various possible values follows a number of namespaced states:

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

°door:closed^open_door=>°door:open
°door:open^open_door=>°door:open
°door:open^insert_plug=>°door:open

°door:closed °plug:inserted °cooking:stopped °button^press    => °button:pressed  °cooking:ongoing
°door:closed °plug:inserted °cooking:ongoing °button^release  => °button:released °cooking:stopped

```
°components
:values
?guards
^events
+actions
```

```sql
-- ??? component '*' to signify any component, e.g. `°*^tick` (might use `°clock^tick` as well)
create table components (
  component   text unique not null primary key,
  comment     text );

create table verbs ( -- things like 'press', 'tick', 'toggle', 'next'
  verb        text unique not null primary key,
  comment     text );

create table events (
  t           timestamp with timezone not null default now(),
  component   text                    not null references components ( component ),
  verb        text                    not null references verbs ( verb ),
  comment     text,
  primary key ( component, verb ) );

-- for ongoing, async things like heating ( => temp continually rising )
-- create table activities ( ... );



```


