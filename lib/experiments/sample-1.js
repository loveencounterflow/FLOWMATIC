(function() {
  'use strict';
  var $, $async, $drain, $show, $watch, CND, PATH, SP, add_item, alert, badge, cast, debug, declare, echo, help, info, isa, jr, log, new_xxx, rpr, type_of, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'FLOMATIC/SAMPLE-1';

  log = CND.get_logger('plain', badge);

  info = CND.get_logger('info', badge);

  whisper = CND.get_logger('whisper', badge);

  alert = CND.get_logger('alert', badge);

  debug = CND.get_logger('debug', badge);

  warn = CND.get_logger('warn', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  ({isa, validate, cast, declare, type_of} = require('../types'));

  //...........................................................................................................
  SP = require('steampipes');

  ({$, $async, $watch, $show, $drain} = SP.export());

  //...........................................................................................................
  ({jr} = CND);

  PATH = require('path');

  // glob                      = require 'glob'
  // FS                        = require 'fs'
  /*
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
  */
  "/blueprints/\n/blueprints/toggler/\n/blueprints/toggler/toggle()\n/blueprints/toggler/:on\n/blueprints/toggler/:off\n/blueprints/xxx/\n/blueprints/xxx/on()\n/blueprints/xxx/off()\n/blueprints/xxx/:off/on() => @:on\n/blueprints/xxx/:on/off() => @:off\n/blueprints/valve/<-component\n/blueprints/valve/:opened\n/blueprints/valve/:closed\n/blueprints/valve/open()    => @:opened\n/blueprints/valve/close()   => @:closed\n/blueprints/valve/toggle()  =>";

  // '/blueprints/@/xxx/:off', '../machine/:active', '@/on()', '@/:on'

  //-----------------------------------------------------------------------------------------------------------
  declare('relative_path', {
    tests: {
      "x is a nonempty_text": function(x) {
        return this.isa.nonempty_text(x);
      },
      "x does not start with a slash": function(x) {
        return !x.startsWith('/');
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  declare('absolute_path', {
    tests: {
      "x is a nonempty_text": function(x) {
        return this.isa.nonempty_text(x);
      },
      "x starts with a slash": function(x) {
        return x.startsWith('/');
      }
    }
  });

  //-----------------------------------------------------------------------------------------------------------
  new_xxx = function() {
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  add_item = function(me, d) {
    return validate.absolute_path(d);
  };

  // perform FM.add_atom( ':open',           'aspect',     'door is open'                            );
  // perform FM.add_pair( '°plug',         ':disconnected',  'state',  true,   'the mains plug is not inserted'            );
  // perform FM.add_pair( '°ones',           ':even', 'state',  true,    'even # of 1s'  );
  // await DB.query [ "select FM.emit( $1 );", $key, ]
  return add_item;

  //###########################################################################################################
  if (module === require.main) {
    (async() => {
      var xxx;
      xxx = this.new_xxx();
      await add_item(xxx, '/microwave');
      await add_item(xxx, '/microwave/power');
      await add_item(xxx, '/microwave/power/switch');
      await add_item(xxx, '/microwave/power/switch/:on');
      return (await add_item(xxx, '/microwave/power/switch/:off'));
    })();
  }

}).call(this);
