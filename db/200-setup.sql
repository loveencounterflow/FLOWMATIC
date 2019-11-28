

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
create domain FM_TYPES.pair             as text     check ( value ~ '^°[^°^:]+[:^][^°^:]+$'             );
create domain FM_TYPES.topic            as text     check ( value ~ '^°.+'              ); -- i.e., component
create domain FM_TYPES.focus            as text     check ( value ~ '^[:^].+'           ); -- i.e., verb or aspect
create domain FM_TYPES.atom             as text     check ( value ~ '^[°^:].+'          ); -- i.e., component, verb, or aspect
create domain FM_TYPES.sigil            as text     check ( value ~ '^[°^:]$'           );
create domain FM_TYPES.sigilcombo       as text     check ( value ~ '^([°^:])|(°[^:])$' );
-- create domain FM.predicate        as jsonb    check ( true                        );


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


-- =========================================================================================================
-- LOG(S)
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
create table FM.queue (
    queueid     bigint generated by default as identity primary key,
    t           timestamp with time zone    not null default statement_timestamp(),
    event       FM_TYPES.action             not null references FM.pairs ( pair ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
create table FM.journal (
    jid         bigint generated by default as identity primary key,
    t           timestamp with time zone    not null  default statement_timestamp(),
    kind        text                        not null,
    topic       FM_TYPES.topic              not null,
    focus       FM_TYPES.focus              not null,
    pair        FM_TYPES.pair               not null,
    status      text,
  foreign key ( kind  ) references FM.kinds ( kind ),
  foreign key ( pair  ) references FM.pairs ( pair ),
  constraint "pair must be concatenation of topic and focus" check ( pair = topic || focus ) );

-- ---------------------------------------------------------------------------------------------------------
-- ### TAINT not clear whether ID or timestamp should be used to find current state
create view FM.current_state as ( select
    jid           as jid,
    t             as t,
    topic         as topic,
    focus         as focus,
    pair          as pair,
    status        as status
  from FM.journal
  where true
    and ( kind = 'state' )
    and ( jid in ( select distinct max( jid ) over ( partition by topic ) as jid ) ) );

-- ---------------------------------------------------------------------------------------------------------
-- current event is oldest event in queue
create view FM.current_event as ( select *
  from FM.queue where queueid = ( select min( queueid ) as queueid from FM.queue ) );

-- ---------------------------------------------------------------------------------------------------------
create view FM.current_transition_consequents as ( select distinct
    phrasid,
    csqts,
    moves
  from FM.transition_phrases
  where true
    and cond in ( select pair  from FM.current_state )
    and trgg in ( select event from FM.current_event )
    order by phrasid );

-- ---------------------------------------------------------------------------------------------------------
create materialized view FM._current_transition_effects as ( select
      phrase.phrasid    as phrasid,
      csqt.state_nr     as state_nr,
      tf[ 1 ]           as topic,
      tf[ 2 ]           as focus,
      csqt.state        as state
    from FM.current_transition_consequents as phrase,
    lateral unnest( phrase.csqts ) with ordinality      as csqt ( state, state_nr ),
    lateral regexp_match( csqt.state, '^(.+)(:.+)$' )   as tf
    order by phrase.phrasid, csqt.state_nr
  ) with no data;

comment on materialized view FM._current_transition_effects is 'Materialized view to temporarily hold
effects valid for current transition.';

-- ---------------------------------------------------------------------------------------------------------
create materialized view FM._current_transition_moves as ( select
      phrase.phrasid  as phrasid,
      x.nr as nr,
      x.move as move
    from FM.current_transition_consequents as phrase,
    lateral unnest( moves ) with ordinality x ( move, nr )
    where ( moves != '{}' ) and ( moves is not null )
    order by phrase.phrasid, x.nr
  ) with no data;

comment on materialized view FM._current_transition_effects is 'Materialized view to temporarily hold moves
valid for current transition.';

-- ---------------------------------------------------------------------------------------------------------
-- ### TAINT bringing together two independant IDs from 2 tables
create view FM.current_state_and_event as (
  ( select null as id, null as t, null as kind, null as topic, null as focus, null as state, null as status where false ) union all
  ( select jid,     t, 'state', topic,  focus,  pair,   status from FM.current_state ) union all
  ( select queueid, t, 'event', null,   null,   event,  null   from FM.current_event )
  order by topic, focus );


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.helo() returns void volatile language sql as $$
  select log( e'\x1b[38;05;226m\x1b[7m ✱ helo ✱ \x1b[0m' ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.reset() returns void volatile language plpgsql as $$
  -- Reset all values to their defaults
  begin
    insert into FM.journal ( kind,    topic, focus, pair,           status )
      select                 'state', topic, focus, topic || focus, 'reset'
      from FM.pairs
      where dflt;
    -- ### TAINT consider to actually use entries in `_transition_phrases`:
    insert into FM.journal  ( kind,     topic,  focus,      pair,           status  ) values
                            ( 'state',  '°FSM', ':ACTIVE',  '°FSM:ACTIVE',  'reset' );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.write_event_to_journal( ¶row FM.queue, ¶status text )
  returns bigint volatile language plpgsql as $$
  declare
    ¶tf text[];
    R   bigint;
  begin
    ¶tf :=  regexp_match( ¶row.event, '^(.+)(\^.+)$' );
    insert into FM.journal  ( kind,     topic,    focus,    pair,       status ) values
                            ( 'event',  ¶tf[ 1 ], ¶tf[ 2 ], ¶row.event, ¶status )
      returning jid into R;
    return R;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.update_journal_entry_status( ¶jid bigint, ¶status text )
  returns void volatile language sql as $$
  update FM.journal set status = ¶status where jid = ¶jid; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.apply_current_effects( ¶row FM.queue )
  returns text volatile language plpgsql as $$
  declare
    ¶effect       record;
    ¶status       text    :=  'ok';
    ¶has_effect   boolean :=  false;
  begin
    -- ### TAINT consider to use temporary table as that will not get persisted
    for ¶effect in select * from FM._current_transition_effects loop
      ¶has_effect := true;
      insert into FM.journal  ( kind,     topic,          focus,          pair,           status  ) values
                              ( 'state',  ¶effect.topic,  ¶effect.focus,  ¶effect.state,  ¶status );
      end loop;
    if ¶has_effect then return ¶status; end if;
    return 'futile';
    end; $$;

comment on function FM_FSM.apply_current_effects( FM.queue ) is 'NB. always perform `refresh materialized
view FM._current_transition_effects;` before calling this method.';

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.queue_moves( ¶row FM.queue )
  returns void volatile language plpgsql as $$
  declare
    ¶row record;
  begin
    for ¶row in select move from FM._current_transition_moves order by nr loop
      -- perform log( '^388799^', ¶row.move::text );
      perform FM.emit( ¶row.move::text );
      end loop;
    end; $$;

comment on function FM_FSM.queue_moves( FM.queue ) is 'NB. always perform `refresh materialized view
FM._current_transition_moves;` before calling this method.';

-- ---------------------------------------------------------------------------------------------------------
create function FM.process_current_event() returns void language plpgsql as $$
  declare
    ¶row      FM.queue;
    ¶status   text  :=  'ok';
    ¶t        text;
    ¶jid      bigint;
  begin
    select * from FM.current_event limit 1 into ¶row;
    ¶jid = FM_FSM.write_event_to_journal( ¶row, 'active' );
    ¶t  :=  to_char( ¶row.t, 'YYYY-MON-DD HH24:MI:SS.MS' );
    perform log(
          e'\x1b[38;05;240m^775^ \x1b[38;05;94m'
      ||  ¶t
      ||  e'\x1b[0m \x1b[38;05;100m\x1b[7m '
      ||  ¶row.event
      ||  e' \x1b[0m' );
    refresh materialized view FM._current_transition_effects;
    refresh materialized view FM._current_transition_moves;
    -- .....................................................................................................
    if ¶row.event ~ '^°FSM\^' then
      case ¶row.event
        when '°FSM^RESET' then perform FM_FSM.reset();
        when '°FSM^HELO'  then perform FM_FSM.helo();
        else ¶status := 'unknown';
        end case;
      else
        ¶status :=  FM_FSM.apply_current_effects( ¶row );
      end if;
    perform FM_FSM.queue_moves( ¶row );
    delete from FM.queue where queueid = ¶row.queueid;
    perform FM_FSM.update_journal_entry_status( ¶jid, ¶status );
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
-- ### TAINT consider to enter event both into `queue` *and* `journal` at once so it can always be
-- referred to by its stable ID in `journal`
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
  perform FM.add_atom( '^HELO',      'verb',       'put the automaton in its initial state'    );
  -- perform FM.add_atom( '^START',     'verb',       'start the automaton'                       );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_pair(  '°FSM', ':IDLE',    'state',  true,   'the automaton is not in use'               );
  perform FM.add_pair(  '°FSM', ':ACTIVE',  'state',  false,  'the automaton is in use'                   );
  perform FM.add_pair(  '°FSM', '^RESET',   'event',  false,  'reset the automaton to its initial state'  );
  perform FM.add_pair(  '°FSM', '^HELO',    'event',  false,  'extend greetings'  );
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

