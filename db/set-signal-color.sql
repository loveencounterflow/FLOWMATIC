

\ir '../intershop/db/update-os-env.sql'

select ¶( 'flowmatic/debugging' ) as is_debugging
\gset
\if :is_debugging
  do $$ begin perform log( '44451', 'debugging' ); end; $$;
  \set signal :red:reverse'  ':reset :red
\else
  do $$ begin perform log( '44451', 'production' ); end; $$;
  \set signal :green:reverse'  ':reset :green
\endif



