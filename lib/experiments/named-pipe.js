(function() {
  'use strict';
  var $, $async, $drain, $show, $watch, CND, DATOM, FS, FSP, PATH, SP, Tail, alert, badge, debug, demo_1, demo_2, echo, help, info, is_executable, jr, log, mkfifoSync, new_datom, new_fifo, new_message_source, receive, rpr, select, send, sleep, urge, warn, whisper;

  //###########################################################################################################
  CND = require('cnd');

  rpr = CND.rpr;

  badge = 'FLOWMATIC/NAMED-PIPE';

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
  FS = require('fs');

  FSP = (require('fs')).promises;

  PATH = require('path');

  is_executable = require('executable');

  ({mkfifoSync} = require('named-pipe'));

  Tail = (require('tail')).Tail;

  //...........................................................................................................
  SP = require('steampipes');

  ({$, $async, $watch, $show, $drain} = SP.export());

  DATOM = require('datom');

  ({new_datom, select} = DATOM.export());

  sleep = function(dts) {
    return new Promise((done) => {
      return setTimeout(done, dts * 1000);
    });
  };

  ({jr} = CND);

  //...........................................................................................................
  require('cnd/lib/exception-handler');

  //-----------------------------------------------------------------------------------------------------------
  new_fifo = function() {
    var fifo_path, fifo_relpath;
    fifo_path = PATH.resolve(PATH.join(__dirname, '../../myfifo'));
    fifo_relpath = PATH.relative(process.cwd(), fifo_path);
    /* TAINT test whether file exists, do not overwrite (?) */
    FS.writeFileSync(fifo_path, '');
    // try mkfifoSync fifo_path catch error
    //   throw error unless ( error.message is 'unable to create the pipe. do you have permissions?' ) \
    //     and ( FS.statSync fifo_path ).isFIFO()
    // if error? then  info "^fifo@5541^ using existing FIFO pipe at #{fifo_relpath}"
    // else            info "^fifo@5542^ created FIFO pipe at #{fifo_relpath}"
    return fifo_path;
  };

  //-----------------------------------------------------------------------------------------------------------
  send = async function(fifo_path, d) {
    // FS.appendFileSync fifo_path, 'helo'
    await FSP.appendFile(fifo_path, (JSON.stringify(d)) + '\n');
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  receive = function(fifo_path, handler) {
    var tail;
    // validate.function handler
    tail = new Tail(fifo_path, {
      fromBeginning: true
    });
    tail.on('line', (line) => {
      var error;
      try {
        return handler(null, JSON.parse(line));
      } catch (error1) {
        error = error1;
        throw new Error(`when trying to parse ${rpr(line)}, an error was thrown with ${rpr(error.message)}`);
      }
    });
    tail.on('error', (error) => {
      return handler(error);
    });
    return tail;
  };

  //-----------------------------------------------------------------------------------------------------------
  new_message_source = function(fifo_path) {
    var R, end, receiver;
    receiver = receive(fifo_path, (error, d) => {
      if (error != null) {
        throw error;
      }
      if (select(d, '~stop')) {
        return R.end();
      }
      return send(d);
    });
    R = SP.new_push_source();
    end = R.end.bind(R);
    send = R.send.bind(R);
    R.send = (d) => {
      if (select(d, '~stop')) {
        return R.end();
      }
      return send(d);
    };
    R.end = () => {
      receiver.unwatch();
      return end();
    };
    R.receiver = receiver;
    return R;
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_1 = function() {
    var fifo_path, tail;
    fifo_path = new_fifo();
    send(fifo_path, 'helo-1');
    send(fifo_path, 'helo-2');
    send(fifo_path, 'helo-3');
    send(fifo_path, 'helo-4');
    tail = receive(fifo_path);
    send(fifo_path, 'helo-5');
    send(fifo_path, 'helo-6');
    // await sleep 1
    setTimeout((() => {
      tail.unwatch();
      return info('ok');
    }), 1000);
    return null;
  };

  //-----------------------------------------------------------------------------------------------------------
  demo_2 = function() {
    return new Promise(async(resolve) => {
      var d, fifo_path, i, nr, pipeline, source;
      fifo_path = new_fifo();
      source = new_message_source(fifo_path);
      pipeline = [];
      pipeline.push(source);
      pipeline.push($watch((d) => {
        return info('^333^', d);
      }));
      pipeline.push($drain(() => {
        return resolve();
      }));
      SP.pull(...pipeline);
//.........................................................................................................
      for (nr = i = 1; i <= 10; nr = ++i) {
        d = new_datom('^foo', {
          time: Date.now(),
          value: `msg#${nr}`
        });
        whisper('^22231^', jr(d));
        source.send(d);
        await sleep(0.1);
      }
      source.send(new_datom('~stop'));
      // source.end()
      //.........................................................................................................
      info('ok');
      return null;
    });
  };

  //###########################################################################################################
  if (require.main === module) {
    (async() => {
      // await demo_1()
      await demo_2();
      return help('ok');
    })();
  }

}).call(this);
