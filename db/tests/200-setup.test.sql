
/* ###################################################################################################### */
\ir './test-begin.sql'
\timing off
-- \set ECHO queries

-- select array_agg( x[ 1 ] ) from lateral regexp_matches( '⿱亠父, ⿱六乂, ⿱六乂', '([^\s,]+)', 'g' ) as q1 ( x );
-- -- select array_agg( x[ 1 ] ) from lateral regexp_match( '⿱亠父, ⿱六乂, ⿱六乂', '([^\s,]+)' ) as q1 ( x );
-- xxx;



-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists X cascade;
\ir '../200-setup.sql'
\set filename 200-setup.test.sql
\pset pager on

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
do $$ begin
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_atom( '°heatinglight',   'component',  'light to indicate oven is heating'       );
  perform FM.add_atom( '°powerlight',     'component',  'light to indicate oven is switched on'   );
  perform FM.add_atom( '°mainswitch',     'component',  'button to switch microwave on and off'   );
  perform FM.add_atom( '°plug',           'component',  'mains plug'                              );
  perform FM.add_atom( ':pressed',        'aspect',     'when a button is in ''on'' position'     );
  perform FM.add_atom( ':released',       'aspect',     'when a button is in ''off'' position'    );
  perform FM.add_atom( ':on',             'aspect',     'something is active'                     );
  perform FM.add_atom( ':off',            'aspect',     'something is inactive'                   );
  perform FM.add_atom( ':inserted',       'aspect',     'plug is in socket'                       );
  perform FM.add_atom( ':disconnected',   'aspect',     'plug is not in socket'                   );
  perform FM.add_atom( '^actuate',        'verb',       'press or release a button'               );
  perform FM.add_atom( '^insert',         'verb',       'insert plug into socket'                 );
  perform FM.add_atom( '^pull',           'verb',       'pull plug from socket'                   );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_pair( '°mainswitch',   ':pressed',       'state',  false,  'the power button is in ''on'' position'    );
  perform FM.add_pair( '°mainswitch',   ':released',      'state',  true,   'the power button is in ''off'' position'   );
  perform FM.add_pair( '°powerlight',   ':on',            'state',  false,  'the power light is bright'                 );
  perform FM.add_pair( '°powerlight',   ':off',           'state',  true,   'the power light is dark'                   );
  perform FM.add_pair( '°plug',         ':inserted',      'state',  false,  'the mains plug is inserted'                );
  perform FM.add_pair( '°plug',         ':disconnected',  'state',  true,   'the mains plug is not inserted'            );
  perform FM.add_pair( '°mainswitch',   '^actuate',       'event',  false,  'press or release the power button'         );
  perform FM.add_pair( '°plug',         '^insert',        'event',  false,  'insert plug into socket'                   );
  perform FM.add_pair( '°plug',         '^pull',          'event',  false,  'pull plug from socket'                     );
  -- -------------------------------------------------------------------------------------------------------
  -- -- improved interface:
  -- perform FM.add_default_state(  '°mainswitch:released', 'the power button is in ''off'' position' );
  -- perform FM.add_state(          '°mainswitch:pressed',  'the power button is in ''on'' position'  );
  -- perform FM.add_event(          '°mainswitch^actuate',  'press or release the power button'       );
  -- -------------------------------------------------------------------------------------------------------
  -- perform FM.add_transition( '  °mainswitch:released, °mainswitch^actuate => °mainswitch:pressed  ' );
  -- perform FM.add_transition( '°mainswitch:released, °mainswitch^actuate => °mainswitch:pressed' );
  perform FM.add_transition( '°mainswitch:released,°mainswitch^actuate => °mainswitch:pressed' );
  perform FM.add_transition( '°plug:inserted,°plug^pull => °plug:disconnected,°powerlight:off' );
  end; $$;


-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.reset() returns void volatile language plpgsql as $$
  -- Reset all values to their defaults
  begin
    perform log( '^FM_FSM.reset^' );
    insert into FM.journal  ( topic, focus, kind, remark )
      select                  topic, focus, kind, 'RESET'
      from FM.pairs
      where dflt; -- `kind = 'state'` is implicit for `dflt = true`
    -- ### TAINT consider to actually use entries in `transition_phrases`:
    insert into FM.journal  ( topic,  focus,      kind,     remark  ) values
                            ( '°FSM', ':ACTIVE',  'state',  'RESET' );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.record_unmatched_event( ¶row FM.queue ) returns void volatile language plpgsql as $$
  begin
    insert into FM.journal ( topic, focus, remark ) values ( ¶row.topic, ¶row.focus, 'UNPROCESSED' );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.move_queued_event_to_journal( ¶row FM.queue, ¶remark text )
  returns void volatile language plpgsql as $$
  begin
    delete from FM.queue where id = ¶row.id;
    insert into FM.journal ( topic, focus, kind, remark ) values ( ¶row.topic, ¶row.focus, 'event', ¶remark );
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FM_FSM.match_event( ¶row FM.queue )
  returns text volatile language plpgsql as $$
  declare
    ¶remark       text  :=  'RESOLVED';
    ¶transitions  record;
  begin
    perform log( '^388799^', ¶row::text );
    ¶remark :=  'UNPROCESSED';
    -- for ¶transitions in
    --   select csqt_topics, csqt_focuses
    --     from FM.transition_phrases
    --       where true
    --         and topic = ¶row.topic
    --         and focus = ¶row.focus
    --   loop
    --     perform log( '^3877^', transitions::text );
    --     end loop;
    return ¶remark;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
/* ### TAINT  when used as an actual queue, should not trigger on insert but run independently, possibly
              using external clok. */
create function FM.on_after_insert_into_fm_eventqueue() returns trigger language plpgsql as $$
  declare
    ¶event    text  :=  null;
    ¶remark   text  :=  'RESOLVED';
  begin
    ¶event  := new.topic || new.focus;
    perform log( '^6643^', new::text );
    perform log( '^6643^', new.topic::text );
    perform log( '^6643^', new.focus::text );
    perform log( '^6643^', pg_typeof( new )::text );
    -- .....................................................................................................
    case ¶event
      when '°FSM^RESET' then  perform FM_FSM.reset();
      else                    ¶remark :=  FM_FSM.match_event( new );
      -- else                    ¶remark :=  'UNPROCESSED';
      end case;
    -- .....................................................................................................
    perform FM_FSM.move_queued_event_to_journal( new, ¶remark );
    return null;
    end; $$;

-- ---------------------------------------------------------------------------------------------------------
create trigger on_after_insert_into_fm_eventqueue after insert on FM.queue
  for each row execute procedure FM.on_after_insert_into_fm_eventqueue();

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
-- -- .........................................................................................................
-- \echo :reverse:steel FM.kinds            :reset
-- select * from FM.kinds;
-- -- .........................................................................................................
-- \echo :reverse:steel FM.atoms            :reset
-- select * from FM.atoms;
-- .........................................................................................................
\echo :reverse:steel FM.pairs            :reset
select * from FM.pairs;
-- .........................................................................................................
\echo :reverse:steel FM.transition_phrases            :reset
select * from FM.transition_phrases;
-- .........................................................................................................
\echo :reverse:steel FM.transition_phrases_spread            :reset
select * from FM.transition_phrases_spread;
--- -- .........................................................................................................
-- \echo :reverse:steel FM.queue            :reset
-- select * from FM.queue;
insert into FM.queue ( topic, focus ) values ( '°FSM', '^RESET' );
-- insert into FM.queue ( topic, focus ) values ( '°FSM', '^START' );
insert into FM.queue ( topic, focus ) values ( '°mainswitch', '^actuate' );

-- .........................................................................................................
\echo :reverse:steel FM.journal            :reset
select * from FM.journal;
-- .........................................................................................................
\echo :reverse:steel FM.current_states            :reset
select * from FM.current_states;
-- .........................................................................................................
\echo :reverse:steel FM.current_events            :reset
select * from FM.current_events;
-- .........................................................................................................
\echo :reverse:steel FM.current_journal            :reset
select * from FM.current_journal;

-- select
--     *
--   from FM.transition_phrases_spread as transition
--   -- join FM.current_journal           as current on ( transition.cond_topic = current.topic )
--   where transition.id in ( select id
--     from FM.transition_phrases_spread as transition
--     where true
--       and ( transition.cond_topic = '°mainswitch' )
--       and ( transition.cond_focus = ':released' ) )
--     ;





-- insert into FM.predicates ( predicate ) values
--   ( array[ '42', 'false', 'null', '[2,3,5,7]' ]::jsonb[] ),
--   ( array[ '42', 'true' ]::jsonb[] );
-- select * from FM.predicates;


/* ###################################################################################################### */
\echo :red ———{ :filename 10 }———:reset
\quit

-- select * from FACTORS._010_factors;
-- select * from FACTORS.factors;
-- create materialized view _FC_.glyphs_with_fingerprints as ( select
--     *,
--     SIEVE.fingerprint( iclabel ) as fingerprint
--   from
--     SFORMULAS.sformulas
--   limit 10
--   )
--   ;

-- select * from FACTORS.factors
--   order by sortcode;
-- -- select * from FACTORS._010_tautomorphs;
-- \echo :red ———{ 81883 quit }———:reset
-- \quit

select FACTORS.get_wbfx_code( 5, '1234', '一', '十', '木', '林', 'x2h--' ); -- 12 一 十 12.340 木 x2h  林
select FACTORS.get_wbfx_code( 5, '1234', '一', '十', null, '木', null ); -- 12 一 十 12.340 木 x2h  林
select FACTORS.get_wbfx_code( 5, '1234', '一', '十', null, '木', '----' ); -- 12 一 十 12.340 木 x2h  林
select FACTORS.get_wbfx_code( 5, '1234', '一', '十', '木', '木', '----' ); -- 12 一 十 12.340 木 x2h  林

-- ---------------------------------------------------------------------------------------------------------
insert into T.probes_and_matchers
  ( function_name,      p1_txt,             p1_cast,           expect,      match_txt,          match_type       ) values
  ( 'FACTORS.get_sortcode', '北', 'text', 'eq', 'f:0420:北:----:F:北', 'text' ),
  ( 'FACTORS.get_sortcode', '𣥠', 'text', 'eq', 'f:0439:止:x2hB:F:𣥠', 'text' ),
  ( 'FACTORS.get_sortcode', '丿', 'text', 'eq', 'f:0688:丿:----:F:丿', 'text' ),
  ( 'FACTORS.get_sortcode', '𣥕', 'text', 'eq', 'f:0439:止:x2vA:F:𣥕', 'text' ),
  -- .......................................................................................................
  -- ( 'FACTORS.get_wbfx_code'( 5, '1234', '一', '十', '木', '林', 'x2h--' ); -- 12 一 十 12.340 木 x2h  林)
  -- ( 'FACTORS.get_wbfx_code'( 5, '1234', '一', '十', null, '木', null ); -- 12 一 十 12.340 木 x2h  林)
  -- ( 'FACTORS.get_wbfx_code'( 5, '1234', '一', '十', null, '木', '----' ); -- 12 一 十 12.340 木 x2h  林)
  -- ( 'FACTORS.get_wbfx_code'( 5, '1234', '一', '十', '木', '木', '----' ); -- 12 一 十 12.340 木 x2h  林)
  -- .......................................................................................................
  ( 'FACTORS.get_silhouette_symbol', 'x', 'text', 'eq', 'C', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '◰', 'text', 'eq', 'b', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '≈', 'text', 'eq', 'u', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '<', 'text', 'eq', 'u', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '>', 'text', 'eq', 'u', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '?', 'text', 'eq', 'u', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '↻', 'text', 'eq', 'u', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '(', 'text', 'eq', '(', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '隻', 'text', 'eq', 'C', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '坌', 'text', 'eq', 'C', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '分', 'text', 'eq', 'C', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '力', 'text', 'eq', 'F', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '一', 'text', 'eq', 'F', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '𡿭', 'text', 'eq', 'F', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '𣥖', 'text', 'eq', 'F', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '𣥠', 'text', 'eq', 'F', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '𣥕', 'text', 'eq', 'F', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '𣥗', 'text', 'eq', 'F', 'text' ),
  ( 'FACTORS.get_silhouette_symbol', '勿', 'text', 'eq', 'F', 'text' );


/* ====================================================================================================== */
\ir './test-perform.sql'

\pset pager on
-- select distinct xcode from FACTORS.factors order by xcode;
-- select glyph, wbf5        from FACTORS.factors            where glyph in ( '際', '祙', '祭', '⽰', '未' );
-- select * from FACTORS._010_factors;

/* ====================================================================================================== */
\ir './test-end.sql'
\quit
