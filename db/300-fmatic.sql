

/* ###################################################################################################### */
\ir '../intershop/db/010-trm.sql'
\ir './set-signal-color.sql'
-- \ir './test-begin.sql'
-- \pset pager on
\timing off
\set filename 300-FMAT.sql
-- -- \set ECHO queries

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
drop schema if exists FMAT cascade; create schema FMAT;


-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 1 }———:reset
create function FMAT.test_absolute_path( ¶x text ) returns boolean immutable parallel safe language sql as $$
  select ( ¶x = '/' ) or ( ¶x ~ '^/.*[^/]$' and ¶x !~ '//' ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function FMAT.test_path_segment( ¶x text ) returns boolean immutable parallel safe language sql as $$
  -- ### TAINT more specifically, should exclude any brackets except at end etc
  select ¶x ~ '^[^/\s]+$'; $$;

-- ---------------------------------------------------------------------------------------------------------
create function FMAT.test_aspect( ¶x text ) returns boolean immutable parallel safe language sql as $$
  select FMAT.test_path_segment( ¶x ) and ( ¶x ~ '^:[^()]$' ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function FMAT.test_action( ¶x text ) returns boolean immutable parallel safe language sql as $$
  select FMAT.test_path_segment( ¶x ) and ( ¶x ~ '^[^:()]\(\)$' ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function FMAT.test_topic( ¶x text ) returns boolean immutable parallel safe language sql as $$
  select FMAT.test_absolute_path( ¶x ); $$;

-- ---------------------------------------------------------------------------------------------------------
create function FMAT.test_focus( ¶x text ) returns boolean immutable parallel safe language sql as $$
  select FMAT.test_aspect( ¶x ) or FMAT.test_action( ¶x ); $$;


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 2 }———:reset
-- ### TAINT use intershop.ptv variables to make configurable?
create domain FMAT.positive_integer as integer  check ( value > 0                   );
create domain FMAT.nonempty_text    as text     check ( value ~ '.+'                );
create domain FMAT.absolute_path    as text     check ( FMAT.test_absolute_path( value ) );
create domain FMAT.topic            as text     check ( FMAT.test_topic( value ) );
create domain FMAT.focus            as text     check ( FMAT.test_focus( value ) );

comment on domain FMAT.absolute_path is 'Data type for FlowMatic paths (qualified names); must be either a
slash (for the root element) or else start with a slash, followed by at least one character other than a
slash, not contain any slash directly followed by another slash, and not end in a slash.';


-- =========================================================================================================
--
-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 3 }———:reset
-- ### TAINT find better term than 'rolegroup'
create table FMAT.rolegroups (
    rolegroup   FMAT.nonempty_text  not null  unique,
    comment     FMAT.nonempty_text,
  primary key ( rolegroup ) );

comment on table FMAT.rolegroups is 'XXXXXXXXXXXXXXXXXXXXXX';

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 4 }———:reset
insert into FMAT.rolegroups ( rolegroup, comment ) values
  ( 'rule',         'XXX' ),
  -- ### TAINT find better term than 'declaration' ('rules' are likewise 'declared')
  ( 'declaration',  'XXX' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 5 }———:reset
create table FMAT.roles (
    rolegroup   FMAT.nonempty_text    not null references FMAT.rolegroups ( rolegroup ),
    priority    FMAT.positive_integer not null,
    role        FMAT.nonempty_text    not null  unique,
    comment     FMAT.nonempty_text,
  primary key ( role ) );
create unique index on FMAT.roles ( role, priority );
comment on table FMAT.roles is 'Provides roles of FlowMatic components.';

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 6 }———:reset
insert into FMAT.roles ( rolegroup, priority, role, comment ) values
  ( 'declaration',  1,  'action',     'xxxx' ),
  ( 'declaration',  2,  'state',      'xxxx' ),
  ( 'declaration',  3,  'component',  'xxxx' ),
  ( 'rule',         4,  'premise',    'xxxx' ),
  ( 'rule',         5,  'trigger',    'xxxx' ),
  ( 'rule',         6,  'effect',     'xxxx' ),
  ( 'rule',         7,  'move',       'xxxx' );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 7 }———:reset
-- ### TAINT add check that sigil matches role
create table FMAT.rules (
  rulid   bigint generated by default as identity primary key,
  comment text );

comment on table FMAT.rules is 'XXXXXXXXXXXXXXXXXXXXXX';

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 8 }———:reset
create function FMAT._is_rulid( ¶rulid bigint ) returns boolean stable language sql as $$
  select exists ( select 1 from FMAT.rules where rulid = ¶rulid limit 1 ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 9 }———:reset
-- ### TAINT add check that sigil matches role
create table FMAT.parts (
    partid    bigint                  generated by default as identity primary key,
    role      text                    not null  references FMAT.roles ( role ),
    path      FMAT.absolute_path      not null,
    rulid     FMAT.positive_integer,
    comment   FMAT.nonempty_text,
    constraint "xxx" check (
      -- ### TAINT use rolegroup instead of listing terms
      ( role in ( 'premise', 'trigger', 'effect', 'move' ) and FMAT._is_rulid( rulid ) )
        or
      ( role in ( 'component', 'state', 'action' ) and ( rulid is null ) ) )
    );

-- thx to https://stackoverflow.com/a/8289253/7568091 (as usual)
-- thx to https://dba.stackexchange.com/a/9760/126933 (as usual)
-- ### TAINT think about best ordering of fields
create unique index "unique (role,path) where rulid is null" on
  FMAT.parts ( role, path ) where rulid is null;
create unique index "unique (role,path,rulid) where rulid is not null" on
  FMAT.parts ( role, path, rulid ) where rulid is not null;

comment on table FMAT.parts is 'XXXXXXXXXXXXXXXXXXXXXX';

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 10 }———:reset
create function FMAT._is_action( ¶path FMAT.absolute_path ) returns boolean stable language sql as $$
  select exists ( select 1 from FMAT.parts
    where ( path = ¶path ) and ( role = 'action' ) limit 1 ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 11 }———:reset
-- ### TAINT add check that sigil matches role
create table FMAT.queue (
    qid         bigint generated always as identity primary key,
    t           timestamptz         not null default statement_timestamp(),
    path        FMAT.absolute_path  not null,
    constraint "path must be registered action" check ( FMAT._is_action( path ) ) );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 12 }———:reset
create function FMAT.push_to_queue( ¶path FMAT.absolute_path )
  returns void volatile language sql as $$
  insert into FMAT.queue ( path ) values ( ¶path ); $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 13 }———:reset
create function FMAT.pop_from_queue() returns FMAT.queue volatile language sql as $$
  delete from FMAT.queue where qid = ( select qid from FMAT.queue order by qid
    for update skip locked limit 1 ) returning *; $$;

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 14 }———:reset
-- ### TAINT add check that sigil matches role
create table FMAT.journal (
    jid       bigint                  generated by default as identity primary key,
    t         timestamptz             not null default statement_timestamp(),
    role      text                    not null  references FMAT.roles ( role ),
    path      FMAT.absolute_path      not null
    );

-- ---------------------------------------------------------------------------------------------------------
\echo :signal ———{ :filename 13 }———:reset
create function FMAT.advance_next() returns FMAT.journal volatile language sql as $$
  with x as ( select * from FMAT.pop_from_queue() )
  insert into FMAT.journal ( role, path ) select 'trigger', x.path from x
  returning *; $$;


-- =========================================================================================================
--

/* ###################################################################################################### */
\echo :red ———{ :filename 15 }———:reset
\quit

