(function() {
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


}).call(this);
