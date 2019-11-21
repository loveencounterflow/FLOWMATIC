
/* ###################################################################################################### */
\ir './test-begin.sql'
\timing on
-- \set ECHO queries

-- select array_agg( x[ 1 ] ) from lateral regexp_matches( '⿱亠父, ⿱六乂, ⿱六乂', '([^\s,]+)', 'g' ) as q1 ( x );
-- -- select array_agg( x[ 1 ] ) from lateral regexp_match( '⿱亠父, ⿱六乂, ⿱六乂', '([^\s,]+)' ) as q1 ( x );
-- xxx;



-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ 1 }———:reset
drop schema if exists X cascade;
\ir '../200-setup.sql'
\pset pager on
drop schema if exists _X_ cascade;
create schema _X_;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ 2 }———:reset
insert into X.components ( component, comment ) values
  ( '°heatinglight',  'light to indicate oven is heating' ),
  ( '°powerlight',    'light to indicate oven is switched on' ),
  ( '°mainswitch',    'button to switch microwave on and off' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ 3 }———:reset
insert into X.aspects ( aspect, comment ) values
  ( ':pressed',     'when a button is in ''on'' position'     ),
  ( ':released',    'when a button is in ''off'' position'    ),
  ( ':on',          'something is active'                     ),
  ( ':off',         'something is inactive'                   );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ 4 }———:reset
insert into X.verbs ( verb, comment ) values
  ( '^press',   'press a button'              ),
  ( '^release', 'release a button'            );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ 5 }———:reset
insert into X.states ( component, aspect, comment ) values
  ( '°mainswitch', ':pressed',    'the power button is in ''on'' position'  ),
  ( '°mainswitch', ':released',   'the power button is in ''off'' position' ),
  ( '°powerlight', ':on',         'the power light is bright'  ),
  ( '°powerlight', ':off',        'the power light is dark' );
  ;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ 6 }———:reset
insert into X.events ( component, verb, comment ) values
  ( '°mainswitch', '^press',   'press the power button'   ),
  ( '°mainswitch', '^release', 'release the power button' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ 6 }———:reset
insert into X.transitions ( src_component, src_aspect, evt_component, evt_verb, trg_component, trg_aspect ) values
  -- ( '°mainswitch', ':pressed', '°mainswitch', '^press', '°mainswitch', ':pressed' ),
  ( '°mainswitch',  ':released',  '°mainswitch',    '^press',     '°mainswitch',    ':pressed'    ),
  ( '°mainswitch',  ':pressed',   '°mainswitch',    '^release',   '°mainswitch',    ':released'   ),
  ( '°powerlight',  ':off',       '°mainswitch',    '^press',     '°powerlight',    ':on'    ),
  ( '°powerlight',  ':on',        '°mainswitch',    '^release',   '°powerlight',    ':off'   );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ 7 }———:reset
insert into X.eventlog ( component, verb ) values
  ( '°mainswitch', '^press'   ),
  ( '°mainswitch', '^release' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ 8 }———:reset
-- .........................................................................................................
\echo :reverse:steel X.components   :reset
select * from X.components          order by component;
-- .........................................................................................................
\echo :reverse:steel X.aspects      :reset
select * from X.aspects             order by aspect;
-- .........................................................................................................
\echo :reverse:steel X.verbs        :reset
select * from X.verbs               order by verb;
-- .........................................................................................................
\echo :reverse:steel X.states       :reset
select * from X.states              order by component, aspect;
-- .........................................................................................................
\echo :reverse:steel X.atoms        :reset
select * from X.atoms               order by type, atom;
-- .........................................................................................................
\echo :reverse:steel X.events       :reset
select * from X.events              order by component, verb;
-- .........................................................................................................
\echo :reverse:steel X.transitions  :reset
select * from X.transitions         order by src_component, src_aspect, evt_component, evt_verb, trg_component, trg_aspect;
-- .........................................................................................................
\echo :reverse:steel X.eventlog     :reset
select * from X.eventlog            order by t;
-- .........................................................................................................
\echo :reverse:steel X.statelog     :reset
select * from X.statelog            order by t;


/* ###################################################################################################### */
\echo :red ———{ 9 }———:reset
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
