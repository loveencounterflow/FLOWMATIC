

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
create domain FM_TYPES.state            as text     check ( value ~ '^°[^°^:]+:[^°^:]+$'              );
create domain FM_TYPES.action           as text     check ( value ~ '^°[^°^:]+\^[^°^:]+$'             );
create domain FM_TYPES.topic            as text     check ( value ~ '^°.+'              ); -- i.e., component
create domain FM_TYPES.focus            as text     check ( value ~ '^[:^].+'           ); -- i.e., verb or aspect
create domain FM_TYPES.atom             as text     check ( value ~ '^[°^:].+'          ); -- i.e., component, verb, or aspect
create domain FM_TYPES.sigil            as text     check ( value ~ '^[°^:]$'           );
create domain FM_TYPES.sigilcombo       as text     check ( value ~ '^([°^:])|(°[^:])$' );
-- create domain FM.predicate        as jsonb    check ( true                        );

  -- do $$ begin
  --   perform log( '^3399^', '°component:aspect'::FM_TYPES.state );
  --   perform log( '^3399^', '°component^verb'::FM_TYPES.action );
  --   end; $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- create type FM_TYPES.pair as (
--   topic   FM_TYPES.topic,
--   focus   FM_TYPES.focus );

-- -- ---------------------------------------------------------------------------------------------------------
-- create type FM_TYPES.state as (
--   topic   FM_TYPES.component,
--   focus   FM_TYPES.aspect );

-- -- ---------------------------------------------------------------------------------------------------------
-- create type FM_TYPES.action as (
--   topic   FM_TYPES.component,
--   focus   FM_TYPES.verb );

-- -- ---------------------------------------------------------------------------------------------------------
-- create type FM_TYPES.premise as (
--   conds     FM_TYPES.state[],
--   trigger   FM_TYPES.action );

-- -- ---------------------------------------------------------------------------------------------------------
-- create type FM_TYPES.effect as (
--   csqts     FM_TYPES.state[],
--   moves     FM_TYPES.action[] );


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
create table FM.pairs (
    topic       FM_TYPES.topic          not null  references FM.atoms ( atom ),
    focus       FM_TYPES.focus          not null  references FM.atoms ( atom ),
    pair        text                    not null  unique  primary key,
    kind        text                    not null  references FM.kinds ( kind ),
    dflt        boolean                 not null  default false,
    comment     FM_TYPES.nonempty_text,
  -- primary key ( topic, focus )
  constraint "pair must be concatenation of topic and focus" check ( pair = topic || focus )
  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
create table FM._transition_phrases (
  -- ### TAINT check that arrays contain unique values
  -- ### TAINT check that each array elements satisfies foreign key reference to FM.pairs
  -- ### TAINT add non-null, uniqueness constraints
    phrasid           bigint generated by default as identity primary key,
    conds             FM_TYPES.state[],
    trgg              FM_TYPES.action,
    csqts             FM_TYPES.state[],
    moves             FM_TYPES.action[]
    );

-- ---------------------------------------------------------------------------------------------------------
-- The standard-relational version of FM._transition_phrases`:
create view FM.transition_phrases as ( select
    TP.phrasid                  as phrasid,
    cond.nr                     as cond_nr,
    cond.state                  as cond,
    -- TP.cond_focuses[ cond.nr ]  as cond_focus,
    TP.trgg                     as trgg,
    TP.csqts                    as csqts,
    TP.moves                    as moves
  from FM._transition_phrases as TP,
  lateral unnest( conds ) with ordinality cond ( state, nr ) );

-- insert into FM._transition_phrases
--   ( conds,                trgg,         csqts,                  moves ) values
--     ( array[ '°FSM:IDLE' ], '°FSM^START', array[ '°FSM:ACTIVE' ], null ),
--     ( array[ '°FSM:IDLE', '°FSM:BLAH' ], '°FSM^RESET', array[ '°FSM:WAITING' ], null );


-- =========================================================================================================
-- LOG(S)
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
create table FM.queue (
    id          bigint generated by default as identity primary key,
    t           timestamp with time zone    not null default statement_timestamp(),
    event       FM_TYPES.action             not null references FM.pairs ( pair ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
create table FM.eventjournal (
    id          bigint generated by default as identity primary key,
    t           timestamp with time zone    not null  default statement_timestamp(),
    event       FM_TYPES.action             not null,
    remark      text,
  foreign key ( event ) references FM.pairs ( pair ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
create table FM.statejournal (
    id          bigint generated by default as identity primary key,
    t           timestamp with time zone    not null  default statement_timestamp(),
    topic       FM_TYPES.topic              not null,
    focus       FM_TYPES.focus              not null,
    state       FM_TYPES.state              not null,
    remark      text,
  foreign key ( state ) references FM.pairs ( pair ),
  constraint "state must be concatenation of topic and focus" check ( state = topic || focus ) );

-- ---------------------------------------------------------------------------------------------------------
-- ### TAINT not clear whether ID or timestamp should be used to find current state
create view FM.current_state as ( select
    id            as id,
    t             as t,
    topic         as topic,
    focus         as focus,
    state         as state,
    remark        as remark
  from FM.statejournal where id in ( select distinct
      max( id ) over ( partition by topic ) as id
    from FM.statejournal ) );

-- ---------------------------------------------------------------------------------------------------------
-- current event is oldest event in queue
create view FM.current_event as ( select *
  from FM.queue where id = ( select min( id ) as id from FM.queue ) );

-- ---------------------------------------------------------------------------------------------------------
create view FM.current_transition_effects as ( select distinct
    phrasid,
    csqts,
    moves
  from FM.transition_phrases
  where true
    and cond in ( select state from FM.current_state )
    and trgg in ( select event from FM.current_event )
    order by phrasid );

-- ---------------------------------------------------------------------------------------------------------
create materialized view FM._current_transition_state_effects as ( select
      phrase.phrasid    as phrasid,
      csqt.state_nr     as state_nr,
      tf[ 1 ]           as topic,
      tf[ 2 ]           as focus,
      csqt.state        as state
    from FM.current_transition_effects as phrase,
    lateral unnest( phrase.csqts ) with ordinality      as csqt ( state, state_nr ),
    lateral regexp_match( csqt.state, '^(.+)(:.+)$' )   as tf
    order by phrase.phrasid, csqt.state_nr
  ) with no data;

comment on materialized view FM._current_transition_state_effects is 'Table to temporarily hold effects
valid for current transition.';

-- ---------------------------------------------------------------------------------------------------------
-- ### TAINT bringing together two independant IDs from 2 tables
create view FM.journal as (
  ( select id, t, topic, focus, state, 'state', remark from FM.current_state ) union all
  ( select id, t, null,   null, event, 'event', null   from FM.current_event )
  order by topic, focus );


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.reset() returns void volatile language plpgsql as $$
  -- Reset all values to their defaults
  begin
    perform log( '^FM_FSM.reset^' );
    insert into FM.statejournal ( topic, focus, state,          remark )
      select                      topic, focus, topic || focus, 'RESET'
      from FM.pairs
      where dflt;
    -- ### TAINT consider to actually use entries in `_transition_phrases`:
    insert into FM.statejournal ( topic,  focus,      state,          remark  ) values
                                ( '°FSM', ':ACTIVE',  '°FSM:ACTIVE',  'RESET' );
    end; $$;

-- -- ---------------------------------------------------------------------------------------------------------
-- create function FM_FSM.record_unmatched_event( ¶row FM.queue ) returns void volatile language plpgsql as $$
--   begin
--     insert into FM.journal ( topic, focus, remark ) values ( ¶row.topic, ¶row.focus, 'UNPROCESSED' );
--     end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.move_event_from_queue_to_eventjournal( ¶row FM.queue, ¶remark text )
  returns void volatile language plpgsql as $$
  begin
    delete from FM.queue where id = ¶row.id;
    insert into FM.eventjournal ( event, remark ) values ( ¶row.event, ¶remark );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.apply_current_effects( ¶row FM.queue )
  returns text volatile language plpgsql as $$
  declare
    ¶remark       text  :=  'RESOLVED';
    ¶effect       record;
  begin
    -- perform log( '^388799^', ¶row::text );
    -- ### TAINT consider to use temporary table as that will not get persisted
    refresh materialized view FM._current_transition_state_effects;
    for ¶effect in select * from FM._current_transition_state_effects loop
      -- perform log( '^388800^', ¶effect::text );
      insert into FM.statejournal ( topic, focus, state, remark )
        values ( ¶effect.topic, ¶effect.focus, ¶effect.state, ¶remark );
      end loop;
    -- ¶remark       :=  'UNPROCESSED';
    return ¶remark;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM.process_current_event() returns void language plpgsql as $$
  declare
    ¶row      FM.queue;
    ¶remark   text  :=  'RESOLVED';
  begin
    select * from FM.current_event limit 1 into ¶row;
    perform log( '^6643^', ¶row::text );
    -- .....................................................................................................
    if ¶row.event ~ '^°FSM\^' then
      case ¶row.event
        when '°FSM^RESET' then perform FM_FSM.reset();
        when '°FSM^HELO'  then perform FM_FSM.helo();
        else ¶remark := 'UNKNOWN';
        end case;
      else
        ¶remark :=  FM_FSM.apply_current_effects( ¶row );
      end if;
    perform FM_FSM.move_event_from_queue_to_eventjournal( ¶row, ¶remark );
    -- .....................................................................................................
    end; $$;


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
    insert into FM.pairs ( topic, focus, pair, kind, dflt, comment ) values
      ( ¶topic, ¶focus, ¶topic || ¶focus, ¶kind, ¶dflt, ¶comment );
    return found;
  end; $$;

comment on function FM.add_pair( FM_TYPES.topic, FM_TYPES.focus, text, boolean, text ) is 'Given a topic, a
focus, a kind, a default flag (indicating whether the new state is a default state), and an optional
comment, register the pair with table `FM.pairs`. In case the pair has already been registered, an error
will be thrown.';


-- ---------------------------------------------------------------------------------------------------------
-- ### TAINT validate
create function FM.add_transition( ¶conds text[], ¶trgg FM_TYPES.action, ¶csqts text[], ¶moves text[] )
  returns void volatile language plpgsql as $$
  begin
    insert into FM._transition_phrases ( conds, trgg, csqts, moves ) values
      ( ¶conds, ¶trgg, ¶csqts, ¶moves );
  end; $$;

-- ---------------------------------------------------------------------------------------------------------
-- ### TAINT validate
create function FM.add_transition( ¶conds text, ¶trgg FM_TYPES.action, ¶csqts text, ¶moves text )
  returns void volatile language plpgsql as $$
  declare
    ¶conds_lst    FM_TYPES.nonempty_text[];
    ¶csqts_lst    FM_TYPES.nonempty_text[];
    ¶moves_lst    FM_TYPES.nonempty_text[];
  begin
    ¶conds_lst    :=  regexp_split_to_array( ¶conds, '\s*,\s*' );
    ¶csqts_lst    :=  regexp_split_to_array( ¶csqts, '\s*,\s*' );
    ¶moves_lst    :=  regexp_split_to_array( ¶moves, '\s*,\s*' );
    perform FM.add_transition( ¶conds_lst, ¶trgg, ¶csqts_lst, ¶moves_lst );
  end; $$;

-- ---------------------------------------------------------------------------------------------------------
-- ### TAINT validate
create function FM.add_transition( ¶conds text, ¶trgg FM_TYPES.action, ¶csqts text )
  returns void volatile language sql as $$
    select FM.add_transition( ¶conds, ¶trgg, ¶csqts, null ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM.emit( ¶event FM_TYPES.action )
  returns void volatile language plpgsql as $$
  begin
    insert into FM.queue ( event ) values ( ¶event );
  end; $$;

comment on function FM.emit( FM_TYPES.action ) is 'Add event to the queue.';


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

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
do $$ begin
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_transition( '°FSM:IDLE', '°FSM^RESET', '°FSM:ACTIVE', '°FSM^HELO' );
  -- -------------------------------------------------------------------------------------------------------
  end; $$;



/* ###################################################################################################### */
\echo :red ———{ :filename 13 }———:reset
\quit

