


'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'INTERSHOP-RPC/DEMO'
debug                     = CND.get_logger 'debug',     badge
alert                     = CND.get_logger 'alert',     badge
whisper                   = CND.get_logger 'whisper',   badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
info                      = CND.get_logger 'info',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
# FS                        = require 'fs'
# PATH                      = require 'path'
NET                       = require 'net'
#...........................................................................................................
SP                        = require 'steampipes'
{ $
  $async
  $watch
  $drain }                = SP.export()
#...........................................................................................................
DATOM                     = require 'datom'
{ new_datom
  select }                = DATOM.export()
#...........................................................................................................
types                     = require '../types'
{ isa
  validate
  cast
  type_of }               = types
#...........................................................................................................
{ jr }                    = CND
Rpc                       = require 'intershop-rpc'
DB                        = require '../../intershop/intershop_modules/db'


############################################################################################################
if module is require.main then do =>
  # debug '^7776^', ( k for k of Rpc )
  # debug '^7776^', ( k for k of new Rpc 23001 )
  rpc = new Rpc 23001
  rpc.contract '^flowmatic-event', ( d ) -> help '^5554^ contract', d; return 42
  await rpc.start()
  rpc.listen_to_all ( P... ) -> urge '^66676^ listen_to_all', P
  rpc.listen_to_unheard ( P... ) -> urge '^66676^ listen_to_unheard', P
  debug await rpc.emit '^foobar'
  debug '^7712^', await rpc.delegate '^flowmatic-event', { x: 123, }
  debug '^7712^', await rpc.delegate '^flowmatic-event', 123
  debug '^7712^', await rpc.delegate new_datom '^flowmatic-event', 123
  $key = '°s/^one'
  debug '^8887^', await DB.query [ "select FM.emit( $1 );", $key, ]
  process.exit 1

