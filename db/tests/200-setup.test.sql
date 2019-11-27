
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

select * from FM.atoms;
select * from FM.pairs;
select * from FM.transition_phrases;
select * from FM.transition_phrases_spread;
xxx


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
do $$ begin
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_atom( '°indicator',      'component',  'light to indicate oven is switched on'   );
  perform FM.add_atom( '°switch',         'component',  'button to switch microwave on and off'   );
  perform FM.add_atom( '°plug',           'component',  'mains plug'                              );
  perform FM.add_atom( '°door',           'component',  'oven hatch'                              );
  perform FM.add_atom( '°power',          'component',  'whether appliance is powered'            );
  perform FM.add_atom( ':on',             'aspect',     'something is active'                     );
  perform FM.add_atom( ':off',            'aspect',     'something is inactive'                   );
  perform FM.add_atom( ':open',           'aspect',     'door is open'                            );
  perform FM.add_atom( ':closed',         'aspect',     'door is closed'                          );
  perform FM.add_atom( ':inserted',       'aspect',     'plug is in socket'                       );
  perform FM.add_atom( ':disconnected',   'aspect',     'plug is not in socket'                   );
  perform FM.add_atom( '^toggle',         'verb',       'press or release a button'               );
  perform FM.add_atom( '^insert',         'verb',       'insert plug into socket'                 );
  perform FM.add_atom( '^pull',           'verb',       'pull plug from socket'                   );
  perform FM.add_atom( '^open',           'verb',       'open a door'                   );
  perform FM.add_atom( '^close',          'verb',       'close a door'                   );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_pair( '°switch',       ':on',            'state',  false,  'the power button is in ''on'' position'    );
  perform FM.add_pair( '°switch',       ':off',           'state',  true,   'the power button is in ''off'' position'   );
  perform FM.add_pair( '°indicator',    ':on',            'state',  false,  'the power light is bright'                 );
  perform FM.add_pair( '°indicator',    ':off',           'state',  true,   'the power light is dark'                   );
  perform FM.add_pair( '°plug',         ':inserted',      'state',  false,  'the mains plug is inserted'                );
  perform FM.add_pair( '°plug',         ':disconnected',  'state',  true,   'the mains plug is not inserted'            );
  perform FM.add_pair( '°power',        ':on',            'state',  false,  'the appliance has no power'                );
  perform FM.add_pair( '°power',        ':off',           'state',  true,   'the appliance has power'                   );
  -- -------------------------------------------------------------------------------------------------------
  perform FM.add_pair( '°switch',       '^toggle',        'event',  false,  'press or release the power button'         );
  perform FM.add_pair( '°plug',         '^insert',        'event',  false,  'insert plug into socket'                   );
  perform FM.add_pair( '°plug',         '^pull',          'event',  false,  'pull plug from socket'                     );
  perform FM.add_pair( '°door',         '^open',          'event',  false,  'open the oven hatch'                       );
  perform FM.add_pair( '°door',         '^close',         'event',  false,  'close the oven hatch'                      );
  -- -------------------------------------------------------------------------------------------------------
  -- -- improved interface:
  -- perform FM.add_default_state(  '°switch:off', 'the power button is in ''off'' position' );
  -- perform FM.add_state(          '°switch:on',  'the power button is in ''on'' position'  );
  -- perform FM.add_event(          '°switch^toggle',  'press or release the power button'       );
  -- -------------------------------------------------------------------------------------------------------
  -- perform FM.add_transition( '  °switch:off, °switch^toggle => °switch:on  ' );
  -- perform FM.add_transition( '°switch:off, °switch^toggle => °switch:on' );
  perform FM.add_transition( '°switch:off,°switch^toggle        => °switch:on'                        );
  perform FM.add_transition( '°switch:on,°switch^toggle         => °switch:off'                       );
  -- perform FM.add_transition( '°switch:on,°power:on              => °indicator:on'                     );
  -- perform FM.add_transition( '°switch:off                       => °indicator:off'                    );
  -- perform FM.add_transition( '°power:off                        => °indicator:off'                    );
  -- perform FM.add_transition( '°plug:inserted,°plug^pull         => °plug:disconnected'                );
  -- perform FM.add_transition( '°plug:disconnected,°plug^insert   => °plug:inserted'                    );
  -- perform FM.add_transition( '°plug:inserted,°switch:on         => °power:on'                         );
  perform FM.add_transition( '°plug:disconnected                => °power:off'                        );
  perform FM.add_transition( '°switch:off                       => °power:off'                        );
  -- perform FM.add_transition( '°c1:a1,°c2,a2                  => °c3:foo'                           );
  -- perform FM.add_transition( '°c1:a1,°c2,a2,^FSM:^TICK       => °c3:foo'                           );
  end; $$;


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
--- -- .........................................................................................................
-- \echo :reverse:steel FM.queue            :reset
-- select * from FM.queue;
insert into FM.queue ( topic, focus ) values ( '°FSM', '^RESET' );
-- insert into FM.queue ( topic, focus ) values ( '°FSM', '^START' );
insert into FM.queue ( topic, focus ) values ( '°switch', '^toggle' );

-- .........................................................................................................
\echo :reverse:steel FM.journal            :reset
select * from FM.journal;
-- .........................................................................................................
\echo :reverse:steel FM.transition_phrases_spread            :reset
select * from FM.transition_phrases_spread;
-- .........................................................................................................
\echo :reverse:steel FM.current_states            :reset
select * from FM.current_states;
-- .........................................................................................................
\echo :reverse:steel FM.current_event            :reset
select * from FM.current_event;
-- .........................................................................................................
\echo :reverse:steel FM.current_journal            :reset
select * from FM.current_journal;

-- ### NOTE also possible to formulate as `where id in ( select id from current_event )`
-- view on all condition clauses that contain current event:
\echo :reverse:yellow candidate transition phrases (based on current event) :reset
select
    transition.*
  from FM.transition_phrases_spread as transition
  join FM.current_event             as event on ( true
    and transition.cond_topic = event.topic
    and transition.cond_focus = event.focus );

\echo :reverse:yellow relevant transition phrases :reset
select
    *
  from FM.transition_phrases_spread as transition
  -- join FM.current_journal           as current on ( transition.cond_topic = current.topic )
  where transition.phrasid in ( select phrasid
    from FM.transition_phrases_spread as transition
    where true
      and ( transition.cond_topic = '°switch' )
      and ( transition.cond_focus = ':off' )
      -- and ( transition.cond_focus = '^toggle' )
      )
    ;

create view FM.intersection_of_current_states_and_transitions as ( select
    clause.*
  from FM.transition_phrases_spread as clause
  join FM.current_states            as state on ( true
    and clause.cond_topic = state.topic
    and clause.cond_focus = state.focus )
  );
\echo :reverse:yellow intersection of transition clauses and current states :reset
select * from FM.intersection_of_current_states_and_transitions;

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
