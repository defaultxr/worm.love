-- worm

function love.load()
   -- settings
   screen_width = 1600
   screen_height = 900

   -- setup
   love.graphics.setMode(screen_width, screen_height)
   
   -- resources
   fixedWidth = love.graphics.newFont("FreeMono.ttf", 14);
   image = love.graphics.newImage("arrow.png")
   quad = love.graphics.newQuad(0, 0, image:getWidth(), image:getHeight(), image:getWidth(), image:getHeight())
   tail = love.graphics.newImage("tail.png")
   tquad = love.graphics.newQuad(0, 0, tail:getWidth(), tail:getHeight(), tail:getWidth(), tail:getHeight())
   tiles = love.graphics.newImage("tiles.png")
   enemy1 = love.graphics.newQuad(32, 160, 32, 32, tiles:getWidth(), tiles:getHeight())
   teleport = love.graphics.newQuad(64, 160, 32, 32, tiles:getWidth(), tiles:getHeight())

   -- sounds
   require 'slam'
   doof = love.audio.newSource("doof.ogg", 'source')

   -- lists
   walls = { }
   enemies = { }
   messages = { }
   
   -- tilemaps
   ATL = require("AdvTiledLoader")
   map = ATL.Loader.load("begin.tmx")
   
   -- collision detection
   HC = require 'hardoncollider'
   Collider = HC(100, on_collide, on_nullide)

   -- For each row
   for r, layer in pairs(map.layers) do
      if layer.properties.noEffect ~= 1 then
         if layer.class == "TileLayer" then
            for x, y, tile in map(layer.name):iterate() do
               local shape = nil
               if tile.properties.isSolid == 1 or tile.properties.isSpring == 1 or tile.properties.slows then
                  local edgeL = 0
                  local edgeT = 0
                  local wid = tile.width
                  local hei = tile.height
                  if tile.properties.edgeL ~= nil then
                     edgeL = tile.properties.edgeL
                  end
                  if tile.properties.edgeT ~= nil then
                     edgeT = tile.properties.edgeT
                  end
                  if tile.properties.width ~= nil then
                     wid = tile.properties.width
                  end
                  if tile.properties.height ~= nil then
                     hei = tile.properties.height
                  end
                  shape = Collider:addRectangle(x*map.tileWidth+edgeL,
                                                y*map.tileHeight+edgeT,
                                                wid,
                                                hei)
               elseif tile.properties.isCorner ~= nil then
                  if tile.properties.isCorner == 1 then
                     shape = Collider:addPolygon(x*map.tileWidth, y*map.tileHeight, (x*map.tileWidth)+tile.width, y*map.tileHeight, x*map.tileWidth, (y*map.tileHeight)+tile.height)
                  end
               end
               if shape ~= nil then
                  shape.properties = tile.properties
                  Collider:setPassive(shape)
                  table.insert(walls, shape)
               end
            end
         else -- if the layer is npcs
            layer.visible = false
            for x, tile in pairs(map(layer.name).objects) do
               local shape = Collider:addCircle(tile.x+16, tile.y-16, 16)
               shape.properties = tile.properties
               shape.name = tile.name
               table.insert(enemies, shape)
            end
         end
      end
   end

   map_width = map.width * map.tileWidth
   map_height = map.height * map.tileHeight
   
   -- constants
   accel = 468
   decel = 2000 -- braking speed
   maxspeed = 1000
   boosttime = 0.2 -- double-tapping a key is only counted as a double-tap if the first and second press are within this time of each other.
   cam_speed = 2

   -- state
   speedmul = 1 -- speed multiplier, based on the ground you're standing on.
   wormShape = Collider:addCircle(272, 272, 14)
   wormShape.velocity = { x = 0, y = 0 }
   wormShape.l = { x = 272, y = 272 }
   wormShape.lastdir = 0
   wormShape.springing = 0
   wormShape.teleporting = 0
   last = { 0, 0, 0, 0 } -- left right up down
   worm_onscreen = true
   tailpos = { }
   for i=1, 200 do
      tailpos[i] = 272
   end
   tx,ty = 0,0

   message("HI")
end

-- utility functions

function sign(num)
   if num == 0 then
      return 0
   elseif num > 0 then
      return 1
   elseif num < 0 then
      return -1
   end
end

function clip(num, min, max)
   return math.min(math.max(num, min), max)
end

function printtable(t)
   for k,v in pairs(t) do print(k,v) end
end

function dir(dir1, dir2, default)
   if default == nil then default = 0 end
   local d = -1*math.atan2(dir1, dir2)
   if dir1 == 0 and dir2 == 0 then
      return default
   else
      return d
   end
end

function dist(x1, y1, x2, y2)
   local xd = x2-x1
   local yd = y2-y1
   return math.sqrt(xd*xd + yd*yd)
end

function osd(text)
   local _, lines = string.gsub(text, "\n", "")
   love.graphics.print(text, math.floor(0-tx), math.floor(screen_height-((lines+1)*14)-ty))
end

function message(text, time)
   if time == nil then time = 5 end
   table.insert(messages, { text=text, time=time, start=love.timer.getTime() })
end

polle = 0

function poll(text, every)
   local line = debug.getinfo(1).currentline
   if polle == 0 then
      print(text)
   end
   polle = (polle + 1)%every
end

function love.keyreleased(key)
end

function love.keypressed(key, unicode)
   if key == "escape" then
      love.event.push("quit")
   end
   -- timers
   local ctime = love.timer.getTime()
   if key == "left" then
      if (ctime - last[1]) < boosttime then
         wormShape.velocity.x = wormShape.velocity.x - 500
      end
      last[1] = ctime
   end
   if key == "right" then
      if (ctime - last[2]) < boosttime then
         wormShape.velocity.x = wormShape.velocity.x + 500
      end
      last[2] = ctime
   end
   if key == "up" then
      if (ctime - last[3]) < boosttime then
         wormShape.velocity.y = wormShape.velocity.y - 500
      end
      last[3] = ctime
   end
   if key == "down" then
      if (ctime - last[4]) < boosttime then
         wormShape.velocity.y = wormShape.velocity.y + 500
      end
      last[4] = ctime
   end
end

function on_collide(dt, shape_a, shape_b, dx, dy)
   local worm = nil
   local other = nil
   local rdx, rdy = 0, 0
   if shape_a == wormShape then
      worm = shape_a
      other = shape_b
      rdx = dx
      rdy = dy
   elseif shape_b == wormShape then
      worm = shape_b
      other = shape_a
      rdx = -dx
      rdy = -dy
   else
      return
   end
   if worm ~= nil then
      local ox, oy = other:center()
      local wx, wy = worm:center()
      if other.properties.isSolid == 1 then
         print("delta: "..rdx..", "..rdy)
         -- worm.velocity.x = worm.velocity.x + dx
         -- worm.velocity.y = worm.velocity.y + dy
         -- if math.abs(dx) < 32 and math.abs(dy) < 32 then
         if math.abs(rdx) > 16 or math.abs(rdy) > 16 then
            -- message("ignored")
            worm:moveTo(worm.l.x, worm.l.y)
         else
            -- message("moved")
            worm:move(rdx, rdy)
         end
         -- end
         -- worm:moveTo(worm.l.x, worm.l.y)
         if ((ox > wx and worm.velocity.x > 0) or (ox < wx and worm.velocity.x < 0)) then -- and (math.abs(oy-wy) < 16) then
            worm.velocity.x = 0
         end
         if ((oy > wy and worm.velocity.y > 0) or (oy < wy and worm.velocity.y < 0)) then -- and (math.abs(ox-wx) < 16) then
            worm.velocity.y = 0
         end
      elseif other.properties.isSpring == 1 and worm.springing == 0 then
         if dist(wx, wy, ox, oy) < 10 then
            doof:play()
            worm:moveTo(ox, oy)
            worm.springing = 1
            if other.properties.springX ~= nil then
               worm.velocity.x = other.properties.springX * 500
            end
            if other.properties.springY ~= nil then
               worm.velocity.y = other.properties.springY * 500
            end
            if other.properties.mulX ~= nil then
               worm.velocity.x = worm.velocity.x * other.properties.mulX
            end
            if other.properties.mulY ~= nil then
               worm.velocity.y = worm.velocity.y * other.properties.mulY
            end
            -- worm:move(dt * worm.velocity.x, dt * worm.velocity.y)
         end
      elseif other.properties.teleportTo ~= nil then
         if worm.teleporting == 0 then
            worm.teleporting = 0.75
            for n, teleport in pairs(enemies) do
               if teleport.name == other.properties.teleportTo then
                  local toX, toY = teleport:center()
                  worm:moveTo(toX, toY)
                  -- FIX: break here
               end
            end
         end
      end
      if other.properties.slows ~= nil then
         speedmul = other.properties.slows
      else
         speedmul = 1
      end
   end
end

function on_nullide(dt, shape_a, shape_b)
   local worm = nil
   local other = nil
   if shape_a == wormShape then
      worm = shape_a
      other = shape_b
   elseif shape_b == wormShape then
      worm = shape_b
      other = shape_a
   else
      return
   end
   if other.properties.isSpring == 1 then
      worm.springing = 0
   end
   if other.properties.slows ~= nil then
      speedmul = 1
   end
end

function love.update(dt)
   -- love.timer.sleep(0.05)
   if dt > 0.02 then
      -- print("abnormally high delta time of " .. dt .. ". Set the dt to its maximum.")
      dt = 0.02
   end
   -- actually alter the position of the character
   local wormX, wormY = wormShape:center()
   if wormX > math.abs(tx) and wormY > math.abs(ty) and (wormX < math.abs(tx)+screen_width) and (wormY < math.abs(ty)+screen_height) then
      wormShape:move((dt * wormShape.velocity.x), (dt * wormShape.velocity.y))
      if wormShape.teleporting > 0 then
         wormShape.teleporting = wormShape.teleporting - dt
      elseif wormShape.teleporting < 0 then
         wormShape.teleporting = 0
      end
      Collider:update(dt)
      -- for i=1, 70 do
      -- print((dt * wormShape.velocity.y)/70)
      -- if math.abs(wormShape.velocity.x * dt)/70 > 0 then
      -- local x,y = wormShape:center()
      -- print("here", x, y)
      -- end
      -- end
      local wormX, wormY = wormShape:center()
      wormShape.l.x = wormX
      wormShape.l.y = wormY
      -- movement / acceleration
      local left = love.keyboard.isDown("left")
      local right = love.keyboard.isDown("right")
      local up = love.keyboard.isDown("up")
      local down = love.keyboard.isDown("down")
      if left and not right then
         if wormShape.velocity.x > 0 then
            wormShape.velocity.x = wormShape.velocity.x + (-1 * dt * decel)
         else
            wormShape.velocity.x = wormShape.velocity.x + (-1 * dt * accel)
         end
      elseif right and not left then
         if wormShape.velocity.x < 0 then
            wormShape.velocity.x = wormShape.velocity.x + (dt * decel)
         else
            wormShape.velocity.x = wormShape.velocity.x + (dt * accel)
         end
      else
         if math.abs(wormShape.velocity.x) < 10 then
            wormShape.velocity.x = 0
         else
            wormShape.velocity.x = wormShape.velocity.x - ((dt * accel) * sign(wormShape.velocity.x))
         end
      end
      if up and not down then
         if wormShape.velocity.y > 0 then
            wormShape.velocity.y = wormShape.velocity.y + (-1 * dt * decel)
         else
            wormShape.velocity.y = wormShape.velocity.y + (-1 * dt * accel)
         end
      elseif down and not up then
         if wormShape.velocity.y < 0 then
            wormShape.velocity.y = wormShape.velocity.y + (dt * decel)
         else
            wormShape.velocity.y = wormShape.velocity.y + (dt * accel)
         end
      else
         if math.abs(wormShape.velocity.y) < 10 then
            wormShape.velocity.y = 0
         else
            wormShape.velocity.y = wormShape.velocity.y - ((dt * accel) * sign(wormShape.velocity.y))
         end
      end
      -- make sure the speed doesn't exceed maxspeed
      if math.abs(wormShape.velocity.x) > (maxspeed * speedmul) then
         wormShape.velocity.x = sign(wormShape.velocity.x) * maxspeed * speedmul
      end
      if math.abs(wormShape.velocity.y) > (maxspeed * speedmul) then
         wormShape.velocity.y = sign(wormShape.velocity.y) * maxspeed * speedmul
      end
      -- update the tailpos array!
      table.insert(tailpos, wormX)
      table.insert(tailpos, wormY)
      table.remove(tailpos, 1)
      table.remove(tailpos, 1)
   end
   -- move the camera
   -- poll(wormY, 5)
   local wormX, wormY = wormShape:center()
   local mx = (-1*tx)+(screen_width/2)-wormX
   tx = tx + ((mx*cam_speed)*dt)
   local my = (-1*ty)+(screen_height/2)-wormY
   ty = ty + ((my*cam_speed)*dt)
   tx = clip(tx, -map_width+screen_width, 0)
   ty = clip(ty, -map_height+screen_height, 0)
   -- update the enemies...
   for i, enemy in pairs(enemies) do
      local cx, cy = enemy:center()
      if dist(cx, cy, wormX, wormY) < 200 then
         -- message("IN RANGE OF " .. enemy.name)
      end
   end
   -- update the messages table
   for index=#messages,1,-1 do
      local val = messages[index]
      if (love.timer.getTime() - val.start) > val.time then
         table.remove(messages, index)
      end
   end
end

function love.draw()
   love.graphics.setBackgroundColor(0x80,0x80,0x80)
   love.graphics.translate(math.floor(tx), math.floor(ty))
   map:autoDrawRange(math.floor(tx), math.floor(ty), 1, pad)
   map:draw()
   -- for i, wall in pairs(walls) do
      -- wall:draw()
   -- end
   --
   for i=1, #tailpos/2 do
      if i%5 == 0 then
         love.graphics.drawq(tail, tquad, tailpos[i*2-1], tailpos[i*2], 0, 1, 1, tail:getWidth()/2, tail:getHeight()/2)
      end
   end
   local wormX, wormY = wormShape:center()
   wormShape.lastdir = dir(wormShape.velocity.x, wormShape.velocity.y, wormShape.lastdir)
   love.graphics.drawq(image, quad, wormX, wormY, wormShape.lastdir, 1, 1, image:getWidth()/2, image:getHeight()/2)
   -- wormShape:draw()
   for i, enemy in pairs(enemies) do
      local centerx, centery = enemy:center()
      if enemy.properties.enemyType == 1 then
         love.graphics.drawq(tiles, enemy1, centerx, centery, dir(wormX-centerx, wormY-centery), 1, 1, 16, 16)
      elseif enemy.properties.teleportTo ~= nil then
         love.graphics.drawq(tiles, teleport, centerx, centery, love.timer.getTime(), 1, 1, 16, 16)
      end
   end
   love.graphics.setFont(fixedWidth);
   local cosd = ""
   for i, msg in ipairs(messages) do
      if i ~= 1 then cosd = cosd .. "\n" end
      cosd = cosd .. msg.text
   end
   -- osd(cosd)
   osd(string.format("worm.teleporting: %5d\ntx: %5d ty: %5d\nwx: %5d wy: %5d", wormShape.teleporting, tx, ty, wormX, wormY))
   love.graphics.print("Current FPS: "..tostring(love.timer.getFPS()), math.floor(10-tx), math.floor(10-ty))
end