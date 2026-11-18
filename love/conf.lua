function love.conf(t)
  t.identity = "deadzone"
  t.version = "11.5"
  t.window.title = "DEAD ZONE"
  t.window.width = 1280
  t.window.height = 720
  t.window.resizable = true
  t.window.fullscreen = (love._os == "Android" or love._os == "iOS")
  t.window.vsync = 1
  t.modules.joystick = false
  t.modules.physics = false
  t.modules.video = false
end
