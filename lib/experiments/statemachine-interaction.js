(function() {
  'use strict';
  var $, $async, $drain, $show, $watch, CND, DATOM, DB, PATH, SP, alert, badge, cast, debug, demo, echo, emit, freeze, help, info, isa, jr, log, new_datom, read_configuration, rpr, select, show, sleep, start_rpc_server, start_rpc_server_with_default_handler, type_of, types, urge, validate, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'FLOWMATIC/INTERACTION';

  log = CND.get_logger('plain', badge);

  debug = CND.get_logger('debug', badge);

  info = CND.get_logger('info', badge);

  warn = CND.get_logger('warn', badge);

  alert = CND.get_logger('alert', badge);

  help = CND.get_logger('help', badge);

  urge = CND.get_logger('urge', badge);

  whisper = CND.get_logger('whisper', badge);

  echo = CND.echo.bind(CND);

  //...........................................................................................................
  // FS                        = require 'fs'
  // FSP                       = ( require 'fs' ).promises
  PATH = require('path');

  //...........................................................................................................
  SP = require('steampipes');

  ({$, $async, $watch, $show, $drain} = SP.export());

  DATOM = require('datom');

  ({new_datom, freeze, select} = DATOM.export());

  sleep = function(dts) {
    return new Promise((done) => {
      return setTimeout(done, dts * 1000);
    });
  };

  ({jr} = CND);

  DB = require('../../intershop/intershop_modules/db');

  //...........................................................................................................
  types = require('../types');

  ({isa, validate, cast, type_of} = types);

  //...........................................................................................................
  require('cnd/lib/exception-handler');

  // #-----------------------------------------------------------------------------------------------------------
  // demo_2 = -> new Promise ( resolve ) =>
  //   fifo      = FIFO.new_fifo()
  //   pipeline  = []
  //   pipeline.push FIFO.new_message_source fifo
  //   pipeline.push $watch ( d ) => info '^333^', d
  //   pipeline.push $drain =>
  //     resolve()
  //   SP.pull pipeline...
  //   return null

  //-----------------------------------------------------------------------------------------------------------
  emit = async function($key, $value) {
    validate.undefined($value);
    await DB.query(["select FM.emit( $1 );", $key]);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  show = async function() {
    /* TAINT assemble value in DB */
    var R, i, len, ref, row;
    R = {};
    ref = (await DB.query("select * from FM.current_user_state order by topic;"));
    for (i = 0, len = ref.length; i < len; i++) {
      row = ref[i];
      R[row.topic] = row.focus;
    }
    return urge(jr(R));
  };

  //-----------------------------------------------------------------------------------------------------------
  start_rpc_server = function() {
    return new Promise((resolve, reject) => {
      var rpc_server;
      rpc_server = require('../../intershop/intershop_modules/intershop-rpc-server-secondary');
      return rpc_server.listen((error, P) => {
        if (error != null) {
          return reject(error);
        } else {
          return resolve(rpc_server);
        }
      });
    });
  };

  //-----------------------------------------------------------------------------------------------------------
  demo = async function() {
    var rpc_server;
    rpc_server = (await start_rpc_server());
    process.on('uncaughtException', function() {
      return rpc_server.stop();
    });
    process.on('unhandledRejection', function() {
      return rpc_server.stop();
    });
    //.........................................................................................................
    rpc_server.contract('on_flowmatic_event', function(S, Q) {
      var event;
      validate.object(Q);
      ({event} = Q);
      debug('^33373^', rpr(event));
      if (event === '°s^one') {
        return ['°s^zero'];
      }
      return null;
    });
    //.........................................................................................................
    // info jr row for row in await DB.query """select * from FM.journal;"""
    await show();
    await emit('°s^zero');
    await show();
    await emit('°s^zero');
    await show();
    await emit('°s^one');
    await show();
    return process.exit(0);
  };

  //-----------------------------------------------------------------------------------------------------------
  read_configuration = function() {
    var PTVR, guest_intershop_ptv_path, host_intershop_ptv_path;
    PTVR = require('../../intershop/intershop_modules/ptv-reader');
    guest_intershop_ptv_path = PATH.resolve(PATH.join(__dirname, '../../intershop/intershop.ptv'));
    host_intershop_ptv_path = PATH.resolve(PATH.join(__dirname, '../../intershop.ptv'));
    return freeze(PTVR.hash_from_paths(guest_intershop_ptv_path, host_intershop_ptv_path));
  };

  //-----------------------------------------------------------------------------------------------------------
  start_rpc_server_with_default_handler = async function() {
    var rpc_server;
    // help PgBoss.getConstructionPlans()
    rpc_server = (await start_rpc_server());
    process.on('uncaughtException', function() {
      return rpc_server.stop();
    });
    process.on('unhandledRejection', function() {
      return rpc_server.stop();
    });
    //.........................................................................................................
    rpc_server.contract('on_flowmatic_event', function(S, Q) {
      var event;
      validate.object(Q);
      ({event} = Q);
      return 'gotcha';
    });
    return rpc_server;
  };

  //###########################################################################################################
  if (require.main === module) {
    (async() => {
      var rpc_server;
      rpc_server = (await start_rpc_server_with_default_handler());
      return process.exit(1);
    })();
  }

}).call(this);
