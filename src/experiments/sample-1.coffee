
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



