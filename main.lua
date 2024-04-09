-- carmine's retribution
-- sponge guy

-- variables that will literally never change here
local font_consolas = love.graphics.setNewFont("crafters-delight.ttf", 8)
local anim8 = require 'anim8'
local push = require 'push'

-- global variables
love.graphics.setDefaultFilter("nearest", "nearest")
local game_width, game_height = 960, 540
local window_width, window_height = love.window.getDesktopDimensions()
local window_scale = window_width/game_width
push:setupScreen(game_width, game_height, window_width, window_height, {windowed = true})

local color_darkred = {172, 50, 50}
local color_brightred = {219, 24, 24}
local color_orange = {223, 113, 38}
local color_white = {255, 255, 255}
local color_green = {153, 229, 80}
local color_grey = {105, 106, 106}
local color_lightgrey = {155, 173, 183}
local color_black = {0, 0, 0}
local color_brown = {102, 57, 49}
local color_yellow = {251, 242, 54}

local fire_colors = {color_brightred, color_orange, color_yellow, color_orange}
local grey_colors = {color_white, color_white, color_white, color_lightgrey, color_grey, color_lightgrey}


-- shader effects


-- helpful functions

local log1, log2, log3 = {}, {}, {}
function log1:log(...)
	local text = ''
	for i = 1, select('#', ...) do
	  text = text .. ' ' .. tostring(select(i, ...))
	end
  table.insert(self, 1, text)
	if #self > 30 then
		table.remove(self)
	end
end

function log1:draw(...)
	love.graphics.print(table.concat(self, '\r\n'), ...)
end

log2.log  = log1.log
log2.draw = log1.draw
log3.log = log1.log
log3.draw = log1.draw

local counter = 0

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
	self.health = flags.health or nil
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

-- define enemy types

local Enemy_Rock = {}
Enemy_Rock.__index = Enemy_Rock

setmetatable(Enemy_Rock, {__index = MoveableObject})

function Enemy_Rock.new(x, y, dx, dy)
	local self = MoveableObject.new(x, y, dx, dy, hitx, hity, hitw, hith, flags)
	self.hitx = x
	self.hity = y
	self.hitw = 55
	self.hith = 36
	self.sheet = load_image("sprites/rocks/rock1_sheet.png")
	self.animation = initialize_animation(self.sheet, 55, 36, '1-2', 0.1)
	self.friendly = false
	self.id = "evil_rock"
	self.health = 3
	return self
end

local Projectile_Water = {}
Projectile_Water.__index = Projectile_Water

setmetatable(Projectile_Water, {__index = MoveableObject})

function Projectile_Water.new(x, y, dx, dy, friendly)
	local self = MoveableObject.new(x, y, dx, dy, hitx, hity, hitw, hith, flags)
	self.hitx = x
	self.hity = y
	self.hitw = 20
	self.hith = 21
	self.sheet = load_image("sprites/water_drop/water_drop_sheet.png")
	self.animation = initialize_animation(self.sheet, 20, 21, '1-4', 0.1)
	self.friendly = friendly
	self.id = "water_drop"
	self.health = 1
	return self
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
-- if you need to destroy an object, just set it to nil within its collection, garbage collection will take care of it
function update_collection(collection, dt)
	local str = "{"
	-- mark objects for removal
 	for i = 1, #collection do
		local obj = collection[i]
		if obj then
			local obj_left_game_area = (obj.x > (window_width * window_scale) + 200 or obj.x < -200) or (obj.y > (window_height * window_scale) + 200 or obj.y < -200)
			if obj_left_game_area then
				collection[i] = nil
			elseif obj.health then
				if obj.health <= 0 then
					collection[i] = nil
				end
			end
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
	collectgarbage()
end

function draw_collection(collection)
	for _, obj in pairs(collection) do
		-- if enemy colliding with friendly bullet, set shader

		obj.animation:draw(obj.sheet, obj.x, obj.y)
	end
end

function draw_enemies()
	for i = 1, #enemies do
		local enemy = enemies[i]
		enemy.animation:draw(enemy.sheet, enemy.x, enemy.y)
		enemy:draw_hitbox()
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

function blink(colors)
	if not colors then
		return love.math.colorFromBytes(color_white[1], color_white[2], color_white[3])
	end
	if timer_blink > #colors + 1 then
		timer_blink = 1
	end
	local i = math.floor(timer_blink)
	return love.math.colorFromBytes(colors[i][1], colors[i][2], colors[i][3])
end








-- load functions

function love.load()
	love.window.setTitle("CARMINE'S RETRIBUTION")
	love.window.setIcon(love.image.newImageData("sprites/carmine/carmine_body.png"))
	mode = 'start'

	-- timers
	-- - make sure to set timer to nill after using
	timer_blink = 1
	timer_game = 1
	timer_levelselect_delay = nil
	timer_invulnerable = nil
	timer_shot = nil
	timer_secondshot = nil

	shader_flash = love.graphics.newShader[[
		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
		{
			vec4 pixel = Texel(texture, texture_coords); // get current pixel color
			return vec4(1.0, pixel.g, pixel.b, pixel.a); // return modified pixel color
		}
	]]
end

function reset_game()
	-- init variables
	bullets = {}
	background = {}
	enemies = {}

	
	sound_slash = love.audio.newSource("sounds/slash.wav", 'static')
	circ_r = 0
	circ_x = 0
	circ_y = 0

	
	-- carmine
	carmine = MoveableObject.new(100, 200, 0, 0, 114, 208, 14, 7)
	carmine.id = "carmine"
	carmine.lives = 3

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
	for i = 1, 300 do
		star = MoveableObject.new(math.random(1, game_width), math.random(1, game_height), -math.random(1, 200), 0)
		star.sheet = load_image("sprites/stars/star1_sheet.png")
		star.animation = initialize_animation(star.sheet, 4, 7, '1-4', 0.1)
		star.looping = true
		table.insert(background, star)
	end

	rock1 = Enemy_Rock.new(game_width + 50, 200, -200, 0)
	rock2 = Enemy_Rock.new(game_width + 200, 150, -250, 0)
	table.insert(enemies, rock1)
	table.insert(enemies, rock2)
end




-- game functions

function update_game(dt)
	if carmine.lives <= 0 then
		mode = 'gameover'
		reset_game()
	end

	if love.keyboard.isDown('r') then
		reset_game()
	end
	if timer_game > 32000 then
		timer_game = 1
	end

	

	-- invulnerability timer
	if timer_invulnerable and timer_game - timer_invulnerable > 2 then
		timer_invulnerable = nil
	end
	-- shot timer
	if timer_shot and timer_game - timer_shot > 0.3 then
		timer_shot = nil
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
	if love.keyboard.isDown('space') and not timer_shot then
		timer_shot = timer_game
		timer_secondshot = timer_game
		local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
		sound:play()
		key_space_pressed = true
		local water = Projectile_Water.new(math.floor(carmine.x + 10), math.floor(carmine.y), 550, 0, true)
		table.insert(bullets, water)
		circ_r = 25
	end

	if timer_secondshot and timer_game - timer_secondshot > 0.075 then
		local water = Projectile_Water.new(math.floor(carmine.x + 10), math.floor(carmine.y), 550, 0, true)
		table.insert(bullets, water)
		timer_secondshot = nil
		local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
		sound:play()
		circ_r = 20
	end

	

	-- collection updates
	update_collection(bullets, dt)
	update_collection(background, dt)
	update_collection(enemies, dt)

	-- collision effects
	for i = 1, #enemies do
		if get_collision(carmine, enemies[i]) then
			if not timer_invulnerable then
				sound_slash:play()
				enemies[i].health = enemies[i].health - 1
				carmine.lives = carmine.lives - 1
				timer_invulnerable = timer_game
				return
			else
				
				
			end
		end
	end
	for i = 1, #bullets do
		if not bullets[i].friendly and get_collision(carmine, bullets[i]) then
			if not timer_invulnerable then
				sound_slash:play()
				carmine.health = carmine.health - 1
				timer_invulnerable = timer_game
				return
			else
				
				
			end
		end
	end
	for i = 1, #enemies do
		for p = 1, #bullets do
			if get_collision(enemies[i], bullets[p]) and bullets[p].friendly then
				local slash = love.audio.newSource("sounds/slash.wav", 'static')
				slash:play()
				enemies[i].health = enemies[i].health - 1
				bullets[p].health = bullets[p].health - 1
				return
			end
		end
	end

	

	if #enemies < 3 then
		local rock = Enemy_Rock.new(game_width + 50, math.random(50, game_height - 50), -100, 0)
		table.insert(enemies, rock)
	end
end

function update_levelscreen(dt)
	reset_game()
	if not timer_levelselect_delay then
		timer_levelselect_delay = timer_game
	end
	if timer_game - timer_levelselect_delay > 2 then
		mode = 'game'
		timer_levelselect_delay = nil
	end
end

function update_start(dt)
	-- update function for start screen
	if love.keyboard.isDown('space') and not key_space_pressed then
		mode = 'levelscreen'
		key_space_pressed = true
	end
end

function update_gameover(dt)
	-- update function for gameover screen
	if love.keyboard.isDown('space') and not key_space_pressed then
		mode = 'start'
		key_space_pressed = true
	end
end

function love.update(dt)
	timer_game = timer_game + (1 * dt)
	if mode == 'game' then
		update_game(dt)
	elseif mode == 'start' then
		timer_blink = timer_blink + (1 * dt) * 10
		update_start(dt)
	elseif mode == 'gameover' then
		timer_blink = timer_blink + (1 * dt) * 15
		update_gameover(dt)
	elseif mode == 'levelscreen' then
		timer_blink = timer_blink + (1 * dt) * 10
		update_levelscreen(dt)
	end
end




-- draw functions

function draw_game()
	-- background
	draw_collection(background)

	-- bullets
	draw_collection(bullets)
	draw_enemies()

	-- carmine
	carmine_wings_left_animation:draw(carmine_wings_right_sheet, carmine.x - 45, carmine.y - 35)
	carmine_body_animation:draw(carmine_body_sheet, carmine.x, carmine.y)
	carmine_wings_right_animation:draw(carmine_wings_left_sheet, carmine.x - 45, carmine.y - 35)
	love.graphics.setColor(1, 1, 1)
	love.graphics.circle('fill', circ_x, circ_y, circ_r)

	love.graphics.print(carmine.lives, 0, 0)

	
	
end

function draw_levelscreen()
	love.graphics.setColor(blink(grey_colors))
	love.graphics.print("LEVEL 1", (game_width / 2) - 35, (game_height / 2) - 60)
	love.graphics.print("FUCKING SPACE", (game_width / 2) - 55, (game_height / 2) - 40)
end

function draw_start()
	love.graphics.setColor(blink(grey_colors))
	love.graphics.print("CARMINE'S RETRIBUTION", (game_width / 2) - 70, (game_height / 2) - 60)
	love.graphics.print("PRESS ANY KEY TO START", (game_width / 2) - 72, (game_height / 2 ) - 40)
end

function draw_gameover()
	love.graphics.setColor(blink(fire_colors))
	love.graphics.print("YOU SUCK", (game_width / 2) - 35, (game_height / 2) - 60)
	love.graphics.print("NOT WORTHY OF CARMINE", (game_width / 2) - 70, (game_height / 2) - 40)
end

function love.draw()
	push:start()
		if timer_invulnerable then
			love.graphics.print(timer_game - timer_invulnerable, 50, 0)
		end
		
		love.graphics.print(timer_game, 50, 10)
		if timer_shot then
			love.graphics.print(timer_game - timer_shot, 50, 20)
		end
		if mode == 'game' then
			draw_game()
		elseif mode == 'start' then
			draw_start()
		elseif mode == 'gameover' then
			draw_gameover()
		elseif mode == 'levelscreen' then
			draw_levelscreen()
		end
	push:finish()
end

function love.keyreleased(key)
	if key == 'space' then
		key_space_pressed = false
	end
end