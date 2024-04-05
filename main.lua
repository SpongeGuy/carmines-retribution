


-- mother fucker
font_consolas = love.graphics.setNewFont("crafters-delight.ttf", 8)
local anim8 = require 'anim8'
local push = require 'push'

-- global variables
love.graphics.setDefaultFilter("nearest", "nearest")
local game_width, game_height = 960, 540
local window_width, window_height = love.window.getDesktopDimensions()
local window_scale = window_width/game_width
push:setupScreen(game_width, game_height, window_width, window_height, {windowed = true})

-- helpful functions
local MoveableObject = {}
MoveableObject.__index = MoveableObject

function MoveableObject.new(x, y, dx, dy, hitx, hity, hitw, hith, flags) --here
	flags = flags or {}

	local self = setmetatable({}, MoveableObject)
	self.x = x or 0
	self.y = y or 0
	self.hitx = hitx or nil
	self.hity = hity or nil
	self.hitw = hitw or nil
	self.hith = hith or nil
	self.dx = dx or 0
	self.dy = dy or 0
	self.sheet = flags.sheet or nil
	self.animation = flags.animation or nil
	self.id = flags.id or ""
	self.looping = flags.looping or false
	self.friendly = flags.friendly or nil
	return self
end

function MoveableObject:update(dt)
	-- update movement
	self.x = self.x + self.dx * dt
	self.y = self.y + self.dy * dt
	if self.hitx and self.hity then
		self.hitx = self.hitx + self.dx * dt
		self.hity = self.hity + self.dy * dt
	end

	-- ensure object does not micromove
	if self.dx < 0.001 and self.dx > -0.001 then
		self.dx = 0
	end

	-- handle screen looping if applicable
	if self.looping then
		if self.dx < 0 and self.x < -50 then
			self.x = game_width + 50
		elseif self.dx > 0 and self.x > game_width + 50 then
			self.x = -50
		end
	end

	-- animation zone
	if self.animation then
		self.animation:update(dt)
	end
end

function MoveableObject:draw_hitbox()
	love.graphics.rectangle('line', self.hitx, self.hity, self.hitw, self.hith)
end

function MoveableObject:control(speed, left, right, up, down)
	self.dx = 0
	self.dy = 0
	if love.keyboard.isDown(left) then
		self.dx = -speed
	end
	if love.keyboard.isDown(right) then
		self.dx = speed
	end
	if love.keyboard.isDown(up) then
		self.dy = -speed
	end
	if love.keyboard.isDown(down) then
		self.dy = speed
	end
	if not (self.dx == 0 and self.dy == 0) then
		self.dx = self.dx * 0.707
		self.dy = self.dy * 0.707
	end
end

-- local BulletObject = {}
-- BulletObject.__index = BulletObject

-- setmetatable(BulletObject, {__index = MoveableObject})

-- function BulletObject.new(x, y, dx, dy, w, h, sheet, animation)
-- 	local self = MoveableObject.new(x, y, dx, dy, w, h, sheet, animation)
-- 	setmetatable(self, BulletObject)
-- 	self.friendly = false
-- 	return self
-- end

-- function BulletObject:update(dt)
-- 	MoveableObject.update(self, dt)

-- end

-- local EnemyObject = {}
-- EnemyObject.__index = EnemyObject
-- setmetatable(EnemyObject, {__index = MoveableObject})

-- function EnemyObject.new(x, y, dx, dy, w, h, sheet, animation)
-- 	local self = MoveableObject.new(x, y, dx, dy, w, h, sheet, animation)
-- 	setmetatable(self, EnemyObject)
-- 	self.friendly = false
-- 	return self
-- end

function initialize_animation(sheet, frame_width, frame_height, frames, duration)
	local a = anim8.newGrid(frame_width, frame_height, sheet:getWidth(), sheet:getHeight())
	return anim8.newAnimation(a(frames, 1), duration)
end

-- sets a deletion condition
-- removes all nil values from a table, moving subsequent values up
function update_collection(collection, dt)
	local str = "{"
	-- mark objects for removal
 	for i = 1, #collection do
		local obj = collection[i]
		local obj_left_game_area = (obj.x > (window_width * window_scale) + 200 or obj.x < -200) or (obj.y > (window_height * window_scale) + 200 or obj.y < -200)
		if obj_left_game_area then
			collection[i] = nil
		end
	end

	-- compact the array
	local j = 0
	for i = 1, #collection do
		if collection[i] ~= nil then
			j = j + 1
			collection[j] = collection[i]
		end
	end

	-- make the rest of array nil
	for i = j + 1, #collection do
		collection[i] = nil
	end

	-- update objects
	for _, obj in pairs(collection) do
		if obj then
			str = str..obj.id..", "
			obj:update(dt)
		end
	end

	str = str.."}"
	str = #collection
end

function draw_collection(collection)
	for _, obj in pairs(collection) do
		obj.animation:draw(obj.sheet, obj.x, obj.y)
	end
end


-- returns a number. if input is lower than low or higher than high, it returns corresponding value. 
-- else, it returns the value
function clamp(value, low, high)
	if value < low then
		value = low
	end
	if value > high then
		value = high
	end
	return value
end

-- get if there is a collision between two objects
function get_collision(obj1, obj2)
	if obj1.hitx + obj1.hitw < obj2.hitx then
		return false
	elseif obj1.hity > obj2.hity + obj2.hith then
		return false
	elseif obj1.hitx > obj2.hitx + obj2.hitw then
		return false
	elseif obj1.hity + obj1.hith < obj2.hity then
		return false
	end
	return true
end

function load_image(path)
	local info = love.filesystem.getInfo(path)
	if info then
		return love.graphics.newImage(path)
	end
	print("Couldn't grab image from " .. path)
end

function blink()

end






-- load functions

function love.load()
	mode = 'start'
end

function reset_game()
	-- init variables
	bullets = {}
	background = {}
	enemies = {}

	sound_shot = love.audio.newSource("sounds/ball_shot.wav", 'static')
	sound_slash = love.audio.newSource("sounds/slash.wav", 'static')
	circ_r = 0
	circ_x = 0
	circ_y = 0

	
	-- carmine
	carmine = MoveableObject.new(100, 200, 0, 0, 114, 208, 14, 7)
	carmine.id = "carmine"
	carmine.lives = 1

	local g
	carmine_body_sheet = load_image('sprites/carmine/carmine_body_sheet.png')
	g = anim8.newGrid(35, 23, carmine_body_sheet:getWidth(), carmine_body_sheet:getHeight())
	carmine_body_animation = anim8.newAnimation(g('1-3', 1), 0.1)

	carmine_wings_left_sheet = load_image('sprites/wings/carmine_wings_left_sheet.png')
	g = anim8.newGrid(100, 100, carmine_wings_left_sheet:getWidth(), carmine_wings_left_sheet:getHeight())
	carmine_wings_left_animation = anim8.newAnimation(g('1-4', 1), 0.1)

	carmine_wings_right_sheet = load_image('sprites/wings/carmine_wings_right_sheet.png')
	g = anim8.newGrid(100, 100, carmine_wings_right_sheet:getWidth(), carmine_wings_right_sheet:getHeight())
	carmine_wings_right_animation = anim8.newAnimation(g('1-4', 1), 0.1)

	-- stars
	for i = 1, 150 do
		star = MoveableObject.new(math.random(1, game_width), math.random(1, game_height), -math.random(50, 350), 0)
		star.sheet = load_image("sprites/stars/star1_sheet.png")
		star.animation = initialize_animation(star.sheet, 4, 7, '1-4', 0.1)
		star.looping = true
		table.insert(background, star)
	end

	rock = MoveableObject.new(game_width + 25, 100, -200, 0, game_width + 25, 100, 55, 36, {sheet = load_image("sprites/rocks/rock1_sheet.png")})
	rock.animation = initialize_animation(rock.sheet, 55, 36, '1-2', 0.1)
	rock.id = "evil_rock"
	table.insert(enemies, rock)
end




-- game functions

function update_game(dt)
	if love.keyboard.isDown('r') then
		reset_game()
	end


	-- collections
	update_collection(bullets, dt)
	update_collection(background, dt)

	-- special behavior on collision with carmine
	for i = 1, #enemies do
		if get_collision(carmine, enemies[i]) then
			sound_slash:play()
			enemies[i] = nil
			carmine.lives = carmine.lives - 1
		end
	end
	update_collection(enemies, dt)
	
	-- carmine
	if carmine.lives == 0 then
		mode = 'gameover'
	end
	carmine_wings_left_animation:update(dt)
	carmine_wings_right_animation:update(dt)
	carmine:control(250, "a", "d", "w", "s")
	carmine:update(dt)
	if carmine.dy < 0 then
		carmine_body_animation:gotoFrame(3)
	elseif carmine.dy > 0 then
		carmine_body_animation:gotoFrame(1)
	else
		carmine_body_animation:gotoFrame(2)
	end

	-- shot burst data
	circ_x = carmine.x + 30
	circ_y = carmine.y + 10
	if circ_r > 0 then
		circ_r = circ_r - 180 * dt
	end
	if circ_r < 0 then circ_r = 0 end

	-- water drop
	if love.keyboard.isDown('space') and not key_space_pressed then
		sound_shot:play()
		key_space_pressed = true
		local water = MoveableObject.new(math.floor(carmine.x + 10), math.floor(carmine.y), 550, 0, 20, 21)
		water.sheet = load_image('sprites/water_drop/water_drop_sheet.png')
		water.animation = initialize_animation(water.sheet, 20, 21, '1-4', 0.05)
		water.id = "water_drop"
		table.insert(bullets, water)
		circ_r = 25
	end
end

function update_start(dt)
	if love.keyboard.isDown('space') and not key_space_pressed then
		mode = 'game'
		key_space_pressed = true
		reset_game()
	end
end

function update_gameover(dt)
	if love.keyboard.isDown('space') and not key_space_pressed then
		mode = 'start'
		key_space_pressed = true
	end
end

function love.update(dt)
	if mode == 'game' then
		update_game(dt)
	elseif mode == 'start' then
		update_start(dt)
	elseif mode == 'gameover' then
		update_gameover(dt)
	end
end




-- draw functions

function draw_game()
	-- background
	draw_collection(background)

	-- bullets
	draw_collection(bullets)
	draw_collection(enemies)

	-- carmine
	carmine_wings_left_animation:draw(carmine_wings_right_sheet, carmine.x - 45, carmine.y - 35)
	carmine_body_animation:draw(carmine_body_sheet, carmine.x, carmine.y)
	carmine_wings_right_animation:draw(carmine_wings_left_sheet, carmine.x - 45, carmine.y - 35)
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle('fill', circ_x, circ_y, circ_r)

	love.graphics.print(carmine.lives, 0, 0)
	-- carmine:draw_hitbox()
	-- for _, enemy in pairs(enemies) do
	-- 	enemy:draw_hitbox()
	-- end
end

function draw_start()
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("CARMINE'S RETRIBUTION", (game_width / 2) - 70, (game_height / 2) - 60)
	love.graphics.print("PRESS ANY KEY TO START", (game_width / 2) - 72, (game_height / 2 ) - 40)
end

function draw_gameover()
	love.graphics.setColor(1, 0.2, 0.5)
	love.graphics.print("YOU SUCK", (game_width / 2) - 35, (game_height / 2) - 60)
	love.graphics.print("NOT WORTHY OF CARMINE", (game_width / 2) - 70, (game_height / 2) - 40)
end

function love.draw()
	push:start()
		if mode == 'game' then
			draw_game()
		elseif mode == 'start' then
			draw_start()
		elseif mode == 'gameover' then
			draw_gameover()
		end
	push:finish()
end

function love.keyreleased(key)
	if key == 'space' then
		key_space_pressed = false
	end
end