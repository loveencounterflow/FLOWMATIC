

/* ###################################################################################################### */
\ir '../intershop/db/010-trm.sql'
\ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
\set filename 200-setup.sql
-- -- \set ECHO queries

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists FM        cascade; create schema FM;
drop schema if exists FM_TYPES  cascade; create schema FM_TYPES;
drop schema if exists FM_FSM    cascade; create schema FM_FSM;


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
-- ### TAINT use intershop.ptv variables to make configurable?
create domain FM_TYPES.positive_integer as integer  check ( value > 0                   );
create domain FM_TYPES.nonempty_text    as text     check ( value ~ '.+'                );
create domain FM_TYPES.component        as text     check ( value ~ '^°.+'              );
create domain FM_TYPES.verb             as text     check ( value ~ '^\^.+'             );
create domain FM_TYPES.aspect           as text     check ( value ~ '^:.+'              );
create domain FM_TYPES.topic            as text     check ( value ~ '^°.+'              ); -- i.e., component
create domain FM_TYPES.focus            as text     check ( value ~ '^[:^].+'           ); -- i.e., verb or aspect
create domain FM_TYPES.atom             as text     check ( value ~ '^[°^:].+'          ); -- i.e., component, verb, or aspect
create domain FM_TYPES.sigil            as text     check ( value ~ '^[°^:]$'           );
create domain FM_TYPES.sigilcombo       as text     check ( value ~ '^([°^:])|(°[^:])$' );
-- create domain FM.predicate        as jsonb    check ( true                        );

-- ---------------------------------------------------------------------------------------------------------
create type FM_TYPES.pair as (
  topic   FM_TYPES.topic,
  focus   FM_TYPES.focus );

-- ---------------------------------------------------------------------------------------------------------
create type FM_TYPES.state as (
  topic   FM_TYPES.component,
  focus   FM_TYPES.aspect );

-- ---------------------------------------------------------------------------------------------------------
create type FM_TYPES.action as (
  topic   FM_TYPES.component,
  focus   FM_TYPES.verb );

-- ---------------------------------------------------------------------------------------------------------
create type FM_TYPES.premise as (
  conds     FM_TYPES.state[],
  trigger   FM_TYPES.action );

-- ---------------------------------------------------------------------------------------------------------
create type FM_TYPES.effect as (
  csqts     FM_TYPES.state[],
  moves     FM_TYPES.action[] );


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
create table FM.kinds (
    kind      FM_TYPES.nonempty_text   not null  unique,
    sigil     FM_TYPES.sigilcombo      not null  unique,
    comment   FM_TYPES.nonempty_text,
  primary key ( kind ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
-- ### TAINT add check that sigil matches kind
create table FM.atoms (
    atom      FM_TYPES.atom           not null  unique,
    kind      text                    not null  references FM.kinds ( kind ),
    comment   FM_TYPES.nonempty_text,
  primary key ( atom ) );


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
-- ### TAINT add constraint to check that sigils, kinds match
-- ### TAINT add constraint to check that exactly one state has dflt = true
-- ### TAINT add constraint to check that all events have dflt = false (or null)
create table FM._pairs (
    topic       FM_TYPES.topic          not null  references FM.atoms ( atom ),
    focus       FM_TYPES.focus          not null  references FM.atoms ( atom ),
    kind        text                    not null  references FM.kinds ( kind ),
    dflt        boolean                 not null  default false,
    comment     FM_TYPES.nonempty_text,
  primary key ( topic, focus )
  -- constraint on ( topic ) check
  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
create view FM.pairs as ( select
    topic || focus    as pair,
    kind              as kind,
    dflt              as dflt,
    comment           as comment
  from FM._pairs );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
create table FM.transition_phrases (
  -- ### TAINT add non-null, uniqueness constraints
    phrasid           bigint generated by default as identity primary key,
    cond_topics       FM_TYPES.component[],
    cond_focuses      FM_TYPES.aspect[],
    -- cond_predicates   FM_TYPES.predicates[],
    trgg_topic        FM_TYPES.component,
    trgg_focus        FM_TYPES.verb,
    -- csqt_predicates   FM_TYPES.predicates[],
    csqt_topics       FM_TYPES.component[],
    csqt_focuses      FM_TYPES.aspect[],
    moves             FM_TYPES.action[]
    );

-- ---------------------------------------------------------------------------------------------------------
-- The standard-relational version of FM.transition_phrases`:
create view FM.transition_phrases_spread as ( select
    TP.phrasid                  as phrasid,
    cond.nr                     as cond_nr,
    csqt.nr                     as csqt_nr,
    cond.topic                  as cond_topic,
    TP.cond_focuses[ cond.nr ]  as cond_focus,
    TP.trgg_topic               as trgg_topic,
    TP.trgg_focus               as trgg_focus,
    csqt.topic                  as csqt_topic,
    TP.csqt_focuses[ csqt.nr ]  as csqt_focus,
    TP.moves                    as moves
    -- TP.move_topics              as move_topics,
    -- TP.move_focuses             as move_focuses
  from FM.transition_phrases as TP,
  -- ### NOTE could also use unnest( a1, a2, ... ) in from clause
  lateral unnest( cond_topics ) with ordinality cond ( topic, nr ),
  lateral unnest( csqt_topics ) with ordinality csqt ( topic, nr ) );
  -- lateral unnest( move_topics ) with ordinality move ( _, nr ) );

insert into FM.transition_phrases
  ( cond_topics, cond_focuses, trgg_topic, trgg_focus, csqt_topics, csqt_focuses, moves ) values (
            '{°FSM}'::FM_TYPES.component[],
           '{:IDLE}'::FM_TYPES.aspect[],
              '°FSM'::FM_TYPES.component,
            '^START'::FM_TYPES.verb,
            '{°FSM}'::FM_TYPES.component[],
         '{:ACTIVE}'::FM_TYPES.aspect[],
                    null );


-- =========================================================================================================
-- API
-- ---------------------------------------------------------------------------------------------------------
create function FM.add_atom( ¶atom FM_TYPES.atom, ¶kind text, ¶comment text )
  -- ### TAINT should check that kind and sigil match
  returns boolean volatile language plpgsql as $$
  begin
    insert into FM.atoms ( atom, kind, comment ) values
      ( ¶atom, ¶kind, ¶comment );
    return found;
  end; $$;

comment on function FM.add_atom( FM_TYPES.atom, text, text ) is 'Given a name, and an optional comment,
register the atom with table `FM.atoms`. In case the atom has already been registered, an error will
be thrown.';

-- ---------------------------------------------------------------------------------------------------------
create function FM.add_pair(
  ¶topic FM_TYPES.topic, ¶focus FM_TYPES.focus, ¶kind text, ¶dflt boolean, ¶comment text )
  -- ### TAINT consider to split into two functions to add states, actions
  -- ### TAINT should check that kind and sigil match
  returns boolean volatile language plpgsql as $$
  begin
    insert into FM._pairs ( topic, focus, kind, dflt, comment ) values
      ( ¶topic, ¶focus, ¶kind, ¶dflt, ¶comment );
    return found;
  end; $$;

comment on function FM.add_pair( FM_TYPES.topic, FM_TYPES.focus, text, boolean, text ) is 'Given a topic, a
focus, a kind, a default flag (indicating whether the new state is a default state), and an optional
comment, register the pair with table `FM.pairs`. In case the pair has already been registered, an error
will be thrown.';



-- =========================================================================================================
-- INITIAL DATA
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
insert into FM.kinds ( kind, sigil, comment ) values
  ( 'component',  '°',  'models interacting parts of the system'            ),
  ( 'verb',       '^',  'models what parts of the system can do'            ),
  ( 'aspect',     ':',  'models malleable phases of components'             ),
  ( 'event',      '°^', 'models ex- and internal actuations of the system'  ),
  ( 'state',      '°:', 'models static and dynamic postures of the system'  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
do $$ begin
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_atom( '°FSM',       'component',  'pseudo-component for the automaton itself' );
  perform FM.add_atom( ':IDLE',      'aspect',     'when the automaton is not in use'          );
  perform FM.add_atom( ':ACTIVE',    'aspect',     'when the automaton is in use'              );
  perform FM.add_atom( '^RESET',     'verb',       'put the automaton in its initial state'    );
  -- perform FM.add_atom( '^START',     'verb',       'start the automaton'                       );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_pair(  '°FSM', ':IDLE',    'state',  true,   'the automaton is not in use'               );
  perform FM.add_pair(  '°FSM', ':ACTIVE',  'state',  false,  'the automaton is in use'                   );
  perform FM.add_pair(  '°FSM', '^RESET',   'event',  false,  'reset the automaton to its initial state'  );
  -- perform FM.add_pair(  '°FSM', '^START',   'event',  false,  'start the automaton'                       );
  -- -------------------------------------------------------------------------------------------------------
  end; $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 10 }———:reset
-- do $$ begin
--   -- -------------------------------------------------------------------------------------------------------
--   -- The 'raw' form to define a transition:
--   -- perform FM.add_transition(
--   --      '{°FSM,°FSM}'::FM_TYPES.topic[],
--   --   '{:IDLE,^START}'::FM_TYPES.focus[],
--   --           '{°FSM}'::FM_TYPES.topic[],
--   --        '{:ACTIVE}'::FM_TYPES.focus[] );
--   -- -------------------------------------------------------------------------------------------------------
--   perform FM.add_transition( '°FSM:IDLE,°FSM^START => °FSM:ACTIVE' );
--   -- -------------------------------------------------------------------------------------------------------
--   end; $$;



/* ###################################################################################################### */
\echo :red ———{ :filename 13 }———:reset
\quit

