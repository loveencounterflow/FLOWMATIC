
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
drop schema if exists _X_ cascade;
create schema _X_;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
insert into X.components ( component, comment ) values
  ( '°FSM',           'pseudo-component for the automaton itself' ),
  ( '°heatinglight',  'light to indicate oven is heating' ),
  ( '°powerlight',    'light to indicate oven is switched on' ),
  ( '°mainswitch',    'button to switch microwave on and off' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
insert into X.aspects ( aspect, comment ) values
  ( ':IDLE',        'when the automaton is not in use'        ),
  ( ':ACTIVE',      'when the automaton is in use'            ),
  ( ':pressed',     'when a button is in ''on'' position'     ),
  ( ':released',    'when a button is in ''off'' position'    ),
  ( ':on',          'something is active'                     ),
  ( ':off',         'something is inactive'                   );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
insert into X.verbs ( verb, comment ) values
  ( '^RESET',   'put the automaton in its initial state'  ),
  ( '^press',   'press a button'                          ),
  ( '^release', 'release a button'                        );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
insert into X.states ( component, aspect, comment ) values
  ( '°FSM',         ':IDLE',      'the automaton is not in use'             ),
  ( '°FSM',         ':ACTIVE',    'the automaton is in use'                 ),
  ( '°mainswitch',  ':pressed',   'the power button is in ''on'' position'  ),
  ( '°mainswitch',  ':released',  'the power button is in ''off'' position' ),
  ( '°powerlight',  ':on',        'the power light is bright'               ),
  ( '°powerlight',  ':off',       'the power light is dark'                 );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
insert into X.defaultstates ( component, aspect ) values
-- ### TAINT introduce state '°mainswitch:unknown' as we cannot know whether button is released when unplugged ###
  ( '°FSM',         ':IDLE'       ),
  ( '°mainswitch',  ':released'   ),
  ( '°powerlight',  ':off'        );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
insert into X.events ( component, verb, comment ) values
  ( '°FSM',         '^RESET',     'reset the automaton to its initial state'  ),
  ( '°mainswitch',  '^press',     'press the power button'                    ),
  ( '°mainswitch',  '^release',   'release the power button'                  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 7 }———:reset
insert into X.transitions ( src_component, src_aspect, evt_component, evt_verb, trg_component, trg_aspect ) values
  -- ( '°mainswitch', ':pressed', '°mainswitch', '^press', '°mainswitch', ':pressed' ),
  ( '°FSM',         ':IDLE',      '°FSM',           '^RESET',     '°FSM',           ':ACTIVE'     ),
  ( '°mainswitch',  ':released',  '°mainswitch',    '^press',     '°mainswitch',    ':pressed'    ),
  ( '°mainswitch',  ':pressed',   '°mainswitch',    '^release',   '°mainswitch',    ':released'   ),
  ( '°powerlight',  ':off',       '°mainswitch',    '^press',     '°powerlight',    ':on'         ),
  ( '°powerlight',  ':on',        '°mainswitch',    '^release',   '°powerlight',    ':off'        );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 8 }———:reset
insert into X.eventlog ( component, verb ) values
  ( '°FSM',         '^RESET'    ),
  -- ( '°FSM',         '^START'    ),
  ( '°mainswitch',  '^press'    ),
  ( '°mainswitch',  '^release'  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
-- .........................................................................................................
\echo :reverse:steel X.components     :reset
select * from X.components            order by component;
-- .........................................................................................................
\echo :reverse:steel X.aspects        :reset
select * from X.aspects               order by aspect;
-- .........................................................................................................
\echo :reverse:steel X.verbs          :reset
select * from X.verbs                 order by verb;
-- .........................................................................................................
\echo :reverse:steel X.states         :reset
select * from X.states                order by component, aspect;
-- .........................................................................................................
\echo :reverse:steel X.defaultstates  :reset
select * from X.defaultstates         order by component, aspect;
-- .........................................................................................................
\echo :reverse:steel X.events         :reset
select * from X.events                order by component, verb;
-- .........................................................................................................
\echo :reverse:yellow X.atoms         :reset
select * from X.atoms                 ;
-- .........................................................................................................
\echo :reverse:yellow X.pairs         :reset
select * from X.pairs                 ;
-- .........................................................................................................
\echo :reverse:steel X.transitions    :reset
select * from X.transitions           order by src_component, src_aspect, evt_component, evt_verb, trg_component, trg_aspect;
-- .........................................................................................................
\echo :reverse:lime X.eventlog        :reset
select * from X.eventlog              order by t;
-- .........................................................................................................
\echo :reverse:lime X.statelog        :reset
select * from X.statelog              order by t;


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
