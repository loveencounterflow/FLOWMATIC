
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

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 2 }———:reset
-- insert into FM.atoms ( atom, kind, comment ) values
--   ( '°heatinglight',  'component',  'light to indicate oven is heating'       ),
--   ( '°powerlight',    'component',  'light to indicate oven is switched on'   ),
--   ( '°mainswitch',    'component',  'button to switch microwave on and off'   ),
--   ( ':pressed',       'aspect',     'when a button is in ''on'' position'     ),
--   ( ':released',      'aspect',     'when a button is in ''off'' position'    ),
--   ( ':on',            'aspect',     'something is active'                     ),
--   ( ':off',           'aspect',     'something is inactive'                   ),
--   ( '^press',         'verb',       'press a button'                          ),
--   ( '^release',       'verb',       'release a button'                        );

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 5 }———:reset
-- insert into FM.pairs ( topic, focus, kind, dflt, comment ) values
--   ( '°mainswitch',  ':pressed',   'state',  false,  'the power button is in ''on'' position'    ),
--   ( '°mainswitch',  ':released',  'state',  true,   'the power button is in ''off'' position'   ),
--   ( '°powerlight',  ':on',        'state',  false,  'the power light is bright'                 ),
--   ( '°powerlight',  ':off',       'state',  true,   'the power light is dark'                   ),
--   ( '°mainswitch',  '^press',     'event',  false,  'press the power button'                    ),
--   ( '°mainswitch',  '^release',   'event',  false,  'release the power button'                  );

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 7 }———:reset
-- insert into FM.transitions ( termid, topic, focus, action ) values
--   -- ( '°mainswitch', ':pressed', '°mainswitch', '^press', '°mainswitch', ':pressed' ),
--   ( 3,  '°mainswitch',    ':released',  4     ),
--   ( 3,  '°mainswitch',    '^press',     4     ),
--   ( 4,  '°mainswitch',    ':pressed',   null  ),
--   ( 5,  '°mainswitch',    ':pressed',   6     ),
--   ( 5,  '°mainswitch',    '^release',   6     ),
--   ( 6,  '°mainswitch',    ':released',  null  ),
--   ( 7,  '°powerlight',    ':off',       8     ),
--   ( 7,  '°mainswitch',    '^press',     8     ),
--   ( 8,  '°powerlight',    ':on',        null  ),
--   ( 9,  '°powerlight',    ':on',        10    ),
--   ( 9,  '°mainswitch',    '^release',   10    ),
--   ( 10, '°powerlight',    ':off',       null  );

-- -- ---------------------------------------------------------------------------------------------------------
-- \echo :signal ———{ :filename 8 }———:reset
-- insert into FM.eventlog ( component, verb ) values
--   ( '°FSM',         '^RESET'    ),
--   -- ( '°FSM',         '^START'    ),
--   ( '°mainswitch',  '^press'    ),
--   ( '°mainswitch',  '^release'  );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
-- .........................................................................................................
\echo :reverse:steel FM.kinds            :reset
select * from FM.kinds;
-- .........................................................................................................
\echo :reverse:steel FM.atoms            :reset
select * from FM.atoms;
-- .........................................................................................................
\echo :reverse:steel FM.pairs            :reset
select * from FM.pairs;
-- .........................................................................................................
\echo :reverse:plum FM.transition_terms      :reset
select * from FM.transition_terms;
-- .........................................................................................................
\echo :reverse:plum FM.transition_clauses      :reset
select * from FM.transition_clauses;
-- .........................................................................................................
\echo :reverse:plum FM.transition_clauses_and_phrases      :reset
select * from FM.transition_clauses_and_phrases;
-- -- .........................................................................................................
-- \echo :reverse:plum FM.transition_termids_and_clausids      :reset
-- select * from FM.transition_termids_and_clausids;
-- -- .........................................................................................................
-- \echo :reverse:plum FM.transition_clausids      :reset
-- select * from FM.transition_clausids;
-- .........................................................................................................
\echo :reverse:plum FM.transition_phrasids      :reset
select * from FM.transition_phrasids;
-- .........................................................................................................
\echo :reverse:plum FM.transition_phrases      :reset
select * from FM.transition_phrases;
-- -- .........................................................................................................
-- \echo :reverse:plum FM.transition_premises      :reset
-- select * from FM.transition_premises;
-- -- .........................................................................................................
-- \echo :reverse:plum FM.transition_actions      :reset
-- select * from FM.transition_actions;
-- -- .........................................................................................................
-- \echo :reverse:yellow FM.eventlog        :reset
-- select * from FM.eventlog;
-- -- .........................................................................................................
-- \echo :reverse:yellow FM.statelog        :reset
-- select * from FM.statelog;



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
