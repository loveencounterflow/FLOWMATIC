
'use strict'

############################################################################################################
CND                       = require 'cnd'
rpr                       = CND.rpr
badge                     = 'FLOMATIC/SAMPLE-1'
log                       = CND.get_logger 'plain',     badge
info                      = CND.get_logger 'info',      badge
whisper                   = CND.get_logger 'whisper',   badge
alert                     = CND.get_logger 'alert',     badge
debug                     = CND.get_logger 'debug',     badge
warn                      = CND.get_logger 'warn',      badge
help                      = CND.get_logger 'help',      badge
urge                      = CND.get_logger 'urge',      badge
echo                      = CND.echo.bind CND
#...........................................................................................................
{ isa
  validate
  cast
  declare
  type_of }               = require '../types'
#...........................................................................................................
SP                        = require 'steampipes'
{ $
  $async
  $watch
  $show
  $drain }                = SP.export()
#...........................................................................................................
{ jr, }                   = CND
PATH                      = require 'path'
# glob                      = require 'glob'
# FS                        = require 'fs'



###
blueprints/

  toggler/
    toggle()
    :on
    :off

  xxx/
    on()
    off()
    @:off on()  => @:on
    @:on  off() => @:off

  valve/
    :opened
    :closed
    open()    => :opened
    close()   => :closed
    toggle()  =>

microwave/
  power/
    switch/ <- /blueprints/toggler
    light/  <- /blueprints/toggler
      :on   <-  :lit
      :off  <-  :dark
  magnetron/ <- /blueprints/xxx
  disk/
    :rotating
    :resting
  door/ <- /blueprints/valve
    sensor
      :pressed
      :released
  timer
###

"""
/blueprints/
/blueprints/toggler/
/blueprints/toggler/toggle()
/blueprints/toggler/:on
/blueprints/toggler/:off
/blueprints/xxx/
/blueprints/xxx/on()
/blueprints/xxx/off()
/blueprints/xxx/:off/on() => @:on
/blueprints/xxx/:on/off() => @:off
/blueprints/valve/<-component
/blueprints/valve/:opened
/blueprints/valve/:closed
/blueprints/valve/open()    => @:opened
/blueprints/valve/close()   => @:closed
/blueprints/valve/toggle()  =>
"""

# '/blueprints/@/xxx/:off', '../machine/:active', '@/on()', '@/:on'

#-----------------------------------------------------------------------------------------------------------
declare 'relative_path', tests:
 "x is a nonempty_text":          ( x ) -> @isa.nonempty_text x
 "x does not start with a slash": ( x ) -> not x.startsWith '/'

#-----------------------------------------------------------------------------------------------------------
declare 'absolute_path', tests:
 "x is a nonempty_text":          ( x ) -> @isa.nonempty_text x
 "x starts with a slash":         ( x ) -> x.startsWith '/'

#-----------------------------------------------------------------------------------------------------------
new_xxx = () ->
  return null

#-----------------------------------------------------------------------------------------------------------
add_item = ( me, d ) ->
  validate.absolute_path d
  # perform FM.add_atom( ':open',           'aspect',     'door is open'                            );
  # perform FM.add_pair( '°plug',         ':disconnected',  'state',  true,   'the mains plug is not inserted'            );
  # perform FM.add_pair( '°ones',           ':even', 'state',  true,    'even # of 1s'  );
  # await DB.query [ "select FM.emit( $1 );", $key, ]
return add_item


############################################################################################################
if module is require.main then do =>
  xxx = @new_xxx()
  await add_item xxx, '/microwave'
  await add_item xxx, '/microwave/power'
  await add_item xxx, '/microwave/power/switch'
  await add_item xxx, '/microwave/power/switch/:on'
  await add_item xxx, '/microwave/power/switch/:off'



