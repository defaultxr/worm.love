-- worm

function love.load()
   -- resources
   fixedWidth = love.graphics.newFont("FreeMono.ttf", 12);
   image = love.graphics.newImage("arrow.png")
   quad = love.graphics.newQuad(0, 0, image:getWidth(), image:getHeight(), image:getWidth(), image:getHeight())
   tail = love.graphics.newImage("tail.png")
   tquad = love.graphics.newQuad(0, 0, tail:getWidth(), tail:getHeight(), tail:getWidth(), tail:getHeight())
   
   -- tilemaps
   ATL = require("AdvTiledLoader")
   map = ATL.Loader.load("begin.tmx")
   
   -- collision detection
   HC = require 'hardoncollider'
   Collider = HC(100, on_collide)

   -- For each row
   for r, layer in pairs(map.layers) do
      for x, y, tile in map(layer.name):iterate() do
         -- print( string.format("Tile at (%d,%d) has an id of %d", x, y, tile.id) )
         local shape = nil
         if tile.properties.isSolid == 1 then
            shape = Collider:addRectangle(x*map.tileWidth, y*map.tileHeight, tile.width, tile.height)
         elseif tile.properties.isCorner ~= nil then
            if tile.properties.isCorner == 1 then
               shape = Collider:addPolygon(x*map.tileWidth, y*map.tileHeight, (x*map.tileWidth)+tile.width, y*map.tileHeight, x*map.tileWidth, (y*map.tileHeight)+tile.height)
            end
         end
         if shape ~= nil then
            shape.properties = tile.properties
            Collider:setPassive(shape)
         end
      end
   end

   map_width = map.width * map.tileWidth
   map_height = map.height * map.tileHeight
   
   -- constants
   accel = 468
   decel = 1000 -- braking speed (obviously should be higher than acceleration speed)
   maxspeed = 1000
   boosttime = 0.2 -- double-tapping a key is only counted as a double-tap if the first and second press are within this time of each other.
   screen_width = love.graphics.getWidth()
   screen_height = love.graphics.getHeight()
   cam_speed = 5

   -- state
   direction = { 0, 0 }
   lastdir = 0
   wormShape = Collider:addCircle(300, 300, 16)
   wormShape.velocity = { x = 0, y = 0 }
   last = { 0, 0, 0, 0 } -- left right up down
   tailpos = { }
   for i=1, 200 do
      tailpos[i] = 300
   end
   tx,ty = 0,0
end

--[[
   idea: possibly make the directional keys just set a "goal" velocity
   and then just ramp up to that velocity elsewhere?
]]--

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

function dir(dir1, dir2)
   local d = -1*math.atan2(dir1, dir2)
   if dir1 == 0 and dir2 == 0 then
      return lastdir
   else
      lastdir = d
      return lastdir
   end
end

function osd(text)
   local _, lines = string.gsub(text, "\n", "")
   love.graphics.print(text, math.floor(0-tx), math.floor(597-((lines+2)*10)-ty))
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

function on_collide(dt, shape_a, shape_b)
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
   if worm ~= nil and other.properties.isSolid == 1 then
      local ox, oy = other:center()
      local wx, wy = worm:center()
      if ((ox > wx and worm.velocity.x > 0) or (ox < wx and worm.velocity.x < 0)) and (math.abs(oy-wy) < 16) then
         worm.velocity.x = 0
      end
      if ((oy > wy and worm.velocity.y > 0) or (oy < wy and worm.velocity.y < 0)) and (math.abs(ox-wx) < 16) then
         worm.velocity.y = 0
      end
   end
end

function love.update(dt)
   Collider:update(dt)
   -- actually alter the position of the character
   local wormX, wormY = wormShape:center()
   local wormX = wormX + (dt * wormShape.velocity.x)
   local wormY = wormY + (dt * wormShape.velocity.y)
   wormShape:moveTo(wormX, wormY)
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
   if math.abs(wormShape.velocity.x) > maxspeed then
      wormShape.velocity.x = sign(wormShape.velocity.x) * maxspeed
   end
   if math.abs(wormShape.velocity.y) > maxspeed then
      wormShape.velocity.y = sign(wormShape.velocity.y) * maxspeed
   end
   -- update the tailpos array!
   table.insert(tailpos, wormX)
   table.insert(tailpos, wormY)
   table.remove(tailpos, 1)
   table.remove(tailpos, 1)
   -- move the camera
   local mx = (-1*tx)+(screen_width/2)-wormX
   tx = tx + ((mx*cam_speed)*dt)
   local my = (-1*ty)+(screen_height/2)-wormY
   ty = ty + ((my*cam_speed)*dt)
   tx = clip(tx, -map_width+screen_width, 0)
   ty = clip(ty, -map_height+screen_height, 0)
end

function love.draw()
   love.graphics.setBackgroundColor(0x80,0x80,0x80)
   love.graphics.translate(math.floor(tx), math.floor(ty))
   map:autoDrawRange(math.floor(tx), math.floor(ty), 1, pad)
   map:draw()
   --
   local div = wormShape.velocity.y/wormShape.velocity.x
   for i=1, 100 do
      if i%5 == 0 then
         love.graphics.drawq(tail, tquad, tailpos[i*2-1], tailpos[i*2], 0, 1, 1, tail:getWidth()/2, tail:getHeight()/2)
      end
   end
   local wormX, wormY = wormShape:center()
   love.graphics.drawq(image, quad, wormX, wormY, dir(wormShape.velocity.x, wormShape.velocity.y), 1, 1, image:getWidth()/2, image:getHeight()/2)
   -- love.graphics.circle("fill", wormX, wormY, 16)
   love.graphics.setFont(fixedWidth);
   osd(string.format("pos: x:%5d y:%5d\ncam: x:%5d y:%5d", wormX, wormY, tx, ty))
end