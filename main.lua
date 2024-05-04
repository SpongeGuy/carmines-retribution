-- player's retribution
-- sponge guy

-- variables that will literally never change here
local font_consolas = love.graphics.setNewFont("PressStart2P.ttf", 8)
local font_gamer_med = love.graphics.newFont("PressStart2P.ttf", 8)
local anim8 = require 'anim8'
local push = require 'push'

-- global variables
love.graphics.setDefaultFilter("nearest", "nearest")

local window_width, window_height = love.window.getDesktopDimensions()
local game_width, game_height = 960, 540
local window_scale = window_width/game_width
push:setupScreen(game_width, game_height, window_width, window_height, {windowed = true})

local colors_DB32 = {
	{0, 0, 0},
	{34, 32, 52},
	{69, 40, 60},
	{102, 57, 49},
	{143, 86, 59},
	{223, 113, 38},
	{217, 160, 102},
	{238, 195, 154},
	{251, 242, 54},
	{153, 229, 80},
	{106, 190, 48},
	{55, 148, 110},
	{75, 105, 47},
	{82, 75, 36},
	{50, 60, 57},
	{63, 63, 116},
	{48, 96, 130},
	{91, 110, 225},
	{99, 155, 255},
	{95, 205, 228},
	{203, 219, 252},
	{255, 255, 255},
	{155, 173, 183},
	{132, 126, 135},
	{105, 106, 106},
	{89, 86, 82},
	{118, 66, 138},
	{172, 50, 50},
	{217, 87, 99},
	{215, 123, 186},
	{143, 151, 74},
	{138, 111, 48}
}


local letters_title = {
	{"sprites/particle/letters/'.png", 10, 17}, 		-- 1
	{"sprites/particle/letters/a.png", 33, 38}, 		-- 2
	{"sprites/particle/letters/b.png", 32, 40}, 		-- 3
	{"sprites/particle/letters/e.png", 36, 42},		-- 4
	{"sprites/particle/letters/i.png", 9, 39},		-- 5
	{"sprites/particle/letters/m.png", 44, 34},		-- 6
	{"sprites/particle/letters/n.png", 32, 41},		-- 7
	{"sprites/particle/letters/o.png", 33, 41},		-- 8
	{"sprites/particle/letters/r.png", 25, 40},		-- 9 
	{"sprites/particle/letters/s.png", 39, 40},		-- 10
	{"sprites/particle/letters/t.png", 26, 41},		-- 11
	{"sprites/particle/letters/u.png", 29, 38},		-- 12
	{"sprites/particle/letters/big_c.png", 48, 48},	-- 13
	{"sprites/particle/letters/big_r.png", 61, 68},	-- 14
}

function load_image(path)
	local info = love.filesystem.getInfo(path)
	if info then
		return love.graphics.newImage(path)
	end
	print("Couldn't grab image from " .. path)
end

-- might add sheet data to this later
local player_carmine_body_sheet = load_image("sprites/player/carmine/carmine_body-sheet.png")
local player_carmine_left_wings_sheet = load_image("sprites/player/carmine/carmine_wings_left-sheet.png")
local player_carmine_right_wings_sheet = load_image("sprites/player/carmine/carmine_wings_right-sheet.png")

local entity_rock1_sheet = load_image("sprites/entity/rocks/rock1-sheet.png")
local entity_damage_orb_sheet = load_image("sprites/entity/damage_orb/damage_orb-sheet.png")
local entity_drang1_sheet = load_image("sprites/entity/drang/drang1-sheet.png")
local entity_gross_guy_sheet = load_image("sprites/entity/gross_guy/gross_guy-sheet.png")
local entity_water_drop_sheet = load_image("sprites/entity/water_drop/water_drop-sheet.png")

local particle_star_sheet = load_image("sprites/particle/stars/star1-sheet.png")
local particle_heart_sheet = load_image("sprites/particle/heart/heart_alt-sheet.png")

local pickup_lilgabbron_sheet = load_image("sprites/pickup/lil_gabbron-sheet.png")
local pickup_cheese_sheet = load_image("sprites/pickup/smol_cheese.png")


-- shader effects

-- THIS FONT IS CALLED 'BULBHEAD' ON https://patorjk.com/software/taag
--  __  __  ____  ____  __    ____  ____  ____  ____  ___ 
-- (  )(  )(_  _)(_  _)(  )  (_  _)(_  _)(_  _)( ___)/ __)
--  )(__)(   )(   _)(_  )(__  _)(_   )(   _)(_  )__) \__ \
-- (______) (__) (____)(____)(____) (__) (____)(____)(___/

local log1, log2, log3 = {}, {}, {}
function log1:log(...)
	local text = ''
	for i = 1, select('#', ...) do
	  text = text .. ' ' .. tostring(select(i, ...))
	end
  table.insert(self, 1, text)
	if #self > 60 then
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

function create_animation(sheet, frame_width, frame_height, frames, duration)
	local a = anim8.newGrid(frame_width, frame_height, sheet:getWidth(), sheet:getHeight())
	return anim8.newAnimation(a(frames, 1), duration)
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
	if not (obj1.hitx and obj1.hity and obj2.hitx and obj2.hity) then
		return false
	end
	if obj1.hitw == 0 or obj1.hith == 0 or obj2.hitw == 0 or obj2.hith == 0 then
		return false
	end
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

function get_vector(obj1, obj2, multiplier, normalized)
	local norm = true
	if normalized == false then norm = false end

	local dx = (obj2.hitx + obj2.hitw / 2) - (obj1.hitx + obj1.hitw / 2)
	local dy = (obj2.hity + obj2.hith / 2) - (obj1.hity + obj2.hith / 2)

	if norm then
		local magnitude = math.sqrt(dx * dx + dy * dy)

		dx = dx / magnitude
		dy = dy / magnitude
	end

	return dx * multiplier, dy * multiplier
end

function get_game_boundaries()
	local minX = 0
	local maxX = game_width
	local minY = 0
	local maxY = game_height
	return minX, maxX, minY, maxY
end

function get_master_obj(entity)
	for _, obj in ipairs(entity.data) do
		if obj.master then
			return obj
		end
	end
end

function clear_all()
	bullets = {}
	background = {}
	enemies = {}
	explosions = {}
	particles = {}
	powerups = {}
	ui = {}
	player = nil
end

-- USED TO ALTERNATE COLORS FOR TEXT OR OTHER SHIT
-- WARNING: THIS DOESN'T START THE BLINK TIMER
function blink(colors, timer)
	if type(timer) ~= "table" then return 22 end
	if not (colors and timer) then
		return {255, 255, 255}
	end
	if timer.value > #colors + 1 then
		timer.value = 1
	end
	local i = math.floor(timer.value)
	return colors[i]
end

function set_draw_color(num)
	local r, g, b = love.math.colorFromBytes(colors_DB32[num][1], colors_DB32[num][2], colors_DB32[num][3])
	love.graphics.setColor(r, g, b)
end











 
--  _____  ____   ____  ____  ___  ____  ___ 
-- (  _  )(  _ \ (_  _)( ___)/ __)(_  _)/ __)
--  )(_)(  ) _ <.-_)(   )__)( (__   )(  \__ \
-- (_____)(____/\____) (____)\___) (__) (___/

local Background = {}
Background.__index = Background
local Entity = {}
Entity.__index = Entity
local Particle = {}
Particle.__index = Particle
local Pickup = {}
Pickup.__index = Pickup
local Terrain = {}
Terrain.__index = Terrain
local BlinkTimer = {}
BlinkTimer.__index = BlinkTimer
local Timer = {}
Timer.__index = Timer

function Background.new(x, y, dx, dy, w, h, sheet, animation)
	self.x = x
	self.y = y
	self.dx = dx
	self.dy = dy
	self.w = w
	self.h = h
	self.sheet = sheet
	self.animation = animation 
end

function Entity.new(data)
	local self = setmetatable({}, Entity)
	-- this data variable will contain a table of tables containing metadata
	-- in its update function, each table will be updated
	-- make sure the data is in this format {{...}, {...}, {...}}
	self.data = data
	self.flash = 0
	return self
end

function Particle.new(x, y, dx, dy, lifetime, data)
	local self = setmetatable({}, Particle)
	self.x = x
	self.y = y
	self.dx = dx
	self.dy = dy
	self.lifetime = lifetime
	self.timer = timer_global
	self.data = data
	return self
end

function Pickup.new(x, y, dx, dy, hitw, hith, w, h, sheet, animation)
	local self = setmetatable({}, Pickup)
	-- physical data
	self.x = x
	self.y = y
	self.dx = dx
	self.dy = dy
	self.hitx = x
	self.hity = y
	self.hitw = hitw
	self.hith = hith
	self.pickup_effect = nil

	-- visual information
	self.w = w
	self.h = h
	self.sheet = sheet
	self.animation = animation
	
	return self
end

function Terrain.new(x, y, dx, dy, hitw, hith, w, h, sheet, animation)
	-- man linked lists would come in real handy right about now
	local self = setmetatable({}, Terrain)
	self.x = x
	self.y = y
	self.dx = dx
	self.dy = dy
	self.hitw = hitw
	self.hith = hith
	
	-- visual information
	self.w = w
	self.h = h
	self.sheet = sheet
	self.animation = animation

	return self
end

function BlinkTimer.new(runtime, multiplier, id)
	local self = setmetatable({}, Timer)
	self.value = 1
	self.multiplier = multiplier or 1
	self.runtime = runtime
	self.id = id or "generic_timer_blink"

	function self:update(dt)
		self.value = self.value + ((1 * self.multiplier) * dt)
		if self.value > self.runtime then
			self = nil
		end
	end
	return self
end

function Timer.new(runtime, looping, id)
	local self = setmetatable({}, Timer)
	self.value = timer_global
	self.runtime = runtime
	self.elapsed = 0
	self.looping = looping
	self.id = id or "generic_timer"

	function self:update(dt)
		self.elapsed = timer_global - self.value
		if self.looping and timer_global - self.value > self.runtime then
			self.value = timer_global
		elseif timer_global - self.value > self.runtime then
			self = nil
		end
	end

	return self
end





---------------------------
function object_update_coordinates(dt, obj)
	local deltax = obj.dx
	local deltay = obj.dy
	obj.x = obj.x + deltax * dt
	obj.y = obj.y + deltay * dt
	obj.hitx = obj.hitx + deltax * dt
	obj.hity = obj.hity + deltay * dt
	obj.animation:update(dt)
end

function object_draw_hitbox(obj)
	love.graphics.rectangle('line', math.floor(obj.hitx) - 0.25, math.floor(obj.hity) - 0.25, math.floor(obj.hitw) + 0.5, math.floor(obj.hith) + 0.5)
end

function object_control(obj, speed, left, right, up, down)
	-- 250 is good value for speed
	obj.dx = 0
	obj.dy = 0
	if love.keyboard.isDown(left) and obj.x > 0 then
		obj.dx = -speed
	end
	if love.keyboard.isDown(right) and obj.x < game_width - 35 then
		obj.dx = speed
	end
	if love.keyboard.isDown(up) and obj.y > 0 then
		obj.dy = -speed
	end
	if love.keyboard.isDown(down) and obj.y < game_height - 23 then
		obj.dy = speed
	end
	if obj.dx ~= 0 and obj.dy ~= 0 then
		
		obj.dx = obj.dx * 0.707
		obj.dy = obj.dy * 0.707
	end
	obj.dx = obj.dx
	obj.dy = obj.dy
end

function entity_default_update_calls(dt, entity)
	-- controls white shader effect on hit
	if entity.flash and entity.flash > 0 then
		entity.flash = entity.flash - (1 * dt)
	end

	-- kill enemy if health is below zero
	if entity.health and entity.health <= 0 then
		trigger_death_effects(entity, true)
		if entity.increment_counter then
			entity:increment_counter()
		end
		entity.dead = true
	end

	-- destroy enemy if out of bounds
	local x1, x2, y1, y2 = get_game_boundaries()
	local obj = get_master_obj(entity)
	if obj.x < x1 - 100 or obj.x > x2 + 100 or obj.y < y1 - 100 or obj.y > y2 + 100 then
		entity.dead = true
	end
end


------------------------------------

function trigger_death_effects(entity, only_on_master)
	if entity.death_effects then
		for _, effect in ipairs(entity.death_effects) do
			effect(entity, only_on_master)
		end
	end
end

function create_ui_heart(x, y)
	local ui = Particle.new(x, y, 0, 0)
	ui.id = "heart_graphic"
	ui.sheet = particle_heart_sheet
	ui.animation = create_animation(particle_heart_sheet, 11, 11, '1-2', 1000)
	ui.full = true
	ui.dead = false

	function ui:update(dt)
		self.animation:update(dt)
		if self.full then
			self.animation:gotoFrame(1)
		else
			self.animation:gotoFrame(2)
		end
	end

	function ui:draw(dt)
		self.animation:draw(self.sheet, math.floor(self.x), math.floor(self.y))
	end
	table.insert(hearts, ui)
end

function create_player_carmine(posx, posy)
	-- init data
	local data = {
		
		{ -- right wing
			x = posx - 45,
			y = posy - 32,
			dx = 0,
			dy = 0,
			hitw = 0,
			hith = 0,
			sheet = player_carmine_right_wings_sheet,
			animation = create_animation(player_carmine_right_wings_sheet, 100, 100, '1-4', 0.1),
		},
		{ -- body
			master = true,
			x = posx,
			y = posy,
			dx = 0,
			dy = 0,
			hitx = posx + 14,
			hity = posy + 7,
			hitw = 14,
			hith = 7,
			sheet = player_carmine_body_sheet,
			animation = create_animation(player_carmine_body_sheet, 35, 23, '1-3', 1000),
		},
		{ -- left wing
			x = posx - 45,
			y = posy - 32,
			dx = 0,
			dy = 0,
			hitw = 0,
			hith = 0,
			sheet = player_carmine_left_wings_sheet,
			animation = create_animation(player_carmine_left_wings_sheet, 100, 100, '1-4', 0.1),
		},
		
	}

	local player = Entity.new(data)
	player.id = "player_carmine"
	player.points = 1000
	player.max_health = 4
	player.health = 4
	player.attack_speed = 1
	player.attack_type = "double_water_shot"
	player.secondshot = false
	player.invulnerable_delay = 2

	player.timer_shot = nil
	player.timer_secondshot = nil
	player.timer_invulnerable = nil

	player.death_effects = {
		death_effect_points, 
		death_effect_burst, 
		death_effect_explode, 
		death_effect_shockwave,
		death_effect_break,
	}

	player.dead = false

	function player:update(dt)
		for _, obj in ipairs(self.data) do
			obj.x = obj.x + self.data[2].dx * dt
			obj.y = obj.y + self.data[2].dy * dt
			if obj.hitx and obj.hity then
				obj.hitx = obj.hitx + self.data[2].dx * dt
				obj.hity = obj.hity + self.data[2].dy * dt
			end
			obj.animation:update(dt)
		end
		self.max_health = PLAYER_MAX_HEALTH
		self.attack_speed = PLAYER_ATTACK_SPEED
		if data[2].dy < 0 then
			data[2].animation:gotoFrame(3)
		elseif data[2].dy > 0 then
			data[2].animation:gotoFrame(1)
		else
			data[2].animation:gotoFrame(2)
		end

		if self.timer_shot and timer_global - self.timer_shot > self.attack_speed then
			self.timer_shot = nil
		end
		if self.timer_invulnerable and timer_global - self.timer_invulnerable > self.invulnerable_delay then
			self.timer_invulnerable = nil
		end

		if self.flash > 0 then
			self.flash = self.flash - 1 * dt
		end

		if self.health <= 0 then
			trigger_death_effects(self, true)
			self.dead = true
		end
	end

	function player:shoot(dt)
		-- eventually incorporate recursion into this
		if self.health <= 0 then
			return
		end

		shot_circ_x = data[2].x + 30
		shot_circ_y = data[2].y + 10
		if shot_circ_r > 0 then
			shot_circ_r = shot_circ_r - 180 * dt
		end

		if shot_circ_r < 0 then shot_circ_r = 0 end

		-- water drop
		if love.keyboard.isDown('space') and not self.timer_shot then
			shot_circ_r = 25
			self.timer_shot = timer_global
			key_space_pressed = true

			-- shot types / abilities ???
			if self.attack_type == "single_water_shot" then
				single_water_shot(math.floor(data[2].x + 10), math.floor(data[2].y), 550, 0, true)
			elseif self.attack_type == "double_water_shot" then
				quintuple_water_shot(math.floor(data[2].x + 10), math.floor(data[2].y), 550, 0, true)
			end
			if self.secondshot then
				self.timer_secondshot = timer_global
			end
		end

		if self.timer_secondshot and timer_global - self.timer_secondshot > self.attack_speed/2 then
			local water = single_water_shot(math.floor(data[2].x + 10), math.floor(data[2].y), 550, 0, true)
			self.timer_secondshot = nil 
			shot_circ_r = 20
		end
	end

	function player:draw()
		if not self.timer_invulnerable then
			for i = 1, 3 do
				data[i].animation:draw(data[i].sheet, math.floor(data[i].x), math.floor(data[i].y))
			end
		elseif math.sin(timer_global * 50) < 0.5 then
			for i = 1, 3 do
				data[i].animation:draw(data[i].sheet, math.floor(data[i].x), math.floor(data[i].y))
			end
		end
	end
	return player
end

function create_enemy_rock(posx, posy, deltax, deltay)
	-- init data
	local data = {
		{
			master = true,
			x = posx,
			y = posy,
			dx = deltax,
			dy = deltay,
			hitx = posx,
			hity = posy,
			hitw = 43,
			hith = 30,
			sheet = entity_rock1_sheet,
			animation = create_animation(entity_rock1_sheet, 43, 30, '1-5', 0.1), -- trying to call sheet here
		},
	}

	-- object creation
	local rock = Entity.new(data)
	rock.id = "evil_rock"
	rock.health = 5
	rock.points = 100
	rock.timer = timer_global + 2
	rock.friendly = false
	rock.death_effects = {
		death_effect_points, 
		death_effect_burst, 
		death_effect_explode, 
		death_effect_shockwave,
		death_effect_sound_blockhit,
		death_effect_break,
		death_effect_spawn_heart,
		death_effect_spawn_lilgab,
	}
	rock.dead = false

	-- update function
	function rock:update(dt)
		for _, obj in ipairs(self.data) do
			object_update_coordinates(dt, obj)
		end
		if player and timer_global - self.timer > 0 then
			self.timer = timer_global + 2
			if math.random(1, 100) < 15 then
				local pdx, pdy = get_vector(self.data[1], get_master_obj(player), 200, true)
				red_orb_shot(self.data[1].x + self.data[1].hitw / 2, self.data[1].y + self.data[1].hith / 2, pdx, pdy, false)
			end
		end
		

		entity_default_update_calls(dt, self)
	end

	-- increment statistics
	function rock:increment_counter()
		enemy_killed_count = enemy_killed_count + 1
		enemy_gross_killed_count = enemy_gross_killed_count + 1
	end

	function rock:draw()
		for _, obj in ipairs(self.data) do
			obj.animation:draw(obj.sheet, math.floor(obj.x), math.floor(obj.y))
		end
	end

	return rock
end



function create_enemy_gross(posx, posy, deltax, deltay)
	local data = {
		{
			master = true,
			x = posx,
			y = posy,
			dx = deltax,
			dy = deltay,
			hitx = posx,
			hity = posy,
			hitw = 23,
			hith = 35,
			sheet = entity_gross_guy_sheet,
			animation = create_animation(entity_gross_guy_sheet, 23, 35, '1-5', 0.1), -- trying to call sheet here
		},
	}

	local gross = Entity.new(data)
	gross.friendly = false
	gross.id = "enemy_gross_guy"
	gross.points = 50
	gross.health = 2

	gross.copies = 5
	gross.copying = true
	gross.switched = false

	gross.death_effects = {
		death_effect_points, 
		death_effect_burst, 
		death_effect_explode, 
		death_effect_shockwave,
		death_effect_sound_blockhit,
		death_effect_break,
	}
	gross.dead = false

	function gross:update(dt)
		for _, obj in ipairs(self.data) do
			object_update_coordinates(dt, obj)
		
			if self.copying and self.copies > 1 and (obj.x < 925 and obj.x > 800) then
				local copy = create_enemy_gross(game_width + 20, obj.y, obj.dx, obj.dy)
				copy.copies = self.copies - 1
				self.copying = false
				table.insert(enemies, copy)
			end

			if obj.x < 100 and not self.switched and obj.y < game_height / 2 then
				self.switched = true
				obj.dx = -obj.dx * 0.707
				obj.dy = obj.dx
			elseif obj.x < 100 and not self.switched and obj.y >= game_height / 2 then
				self.switched = true
				obj.dx = -obj.dx * 0.707
				obj.dy = -obj.dx
			end

			
		end

		entity_default_update_calls(dt, self)
	end

	function gross:increment_counter()
		enemy_killed_count = enemy_killed_count + 1
		enemy_gross_killed_count = enemy_gross_killed_count + 1
	end

	function gross:draw()
		for _, obj in ipairs(self.data) do
			obj.animation:draw(obj.sheet, math.floor(obj.x), math.floor(obj.y))
		end
	end

	return gross
end

function create_enemy_drang(posx, posy, deltax, deltay)
	local data = {
		{
			master = true,
			x = posx,
			y = posy,
			dx = deltax,
			dy = deltay,
			hitx = posx,
			hity = posy,
			hitw = 36,
			hith = 40,
			sheet = entity_drang1_sheet,
			animation = create_animation(entity_drang1_sheet, 36, 40, '1-5', 0.1),
		},
	}

	local drang = Entity.new(data)
	drang.id = "enemy_drang"
	drang.friendly = false
	drang.health = 3
	drang.points = 150
	drang.chance_100_heart = true
	drang.death_effects = {
		death_effect_points, 
		death_effect_burst, 
		death_effect_explode, 
		death_effect_shockwave,
		death_effect_sound_blockhit,
		death_effect_break,
		death_effect_spawn_heart,
	}
	drang.dead = false

	function drang:update(dt)
		for _, obj in ipairs(self.data) do
			if math.sin(timer_global * 10) < 0 then
				obj.dy = -50
			else
				obj.dy = 50
			end

			object_update_coordinates(dt, obj)
			
		end

		entity_default_update_calls(dt, self)
	end

	function drang:increment_counter()
		enemy_killed_count = enemy_killed_count + 1
		enemy_drang_killed_count = enemy_drang_killed_count + 1
	end

	function drang:draw()
		for _, obj in ipairs(self.data) do
			obj.animation:draw(obj.sheet, math.floor(obj.x), math.floor(obj.y))
		end
	end

	return drang
end

function create_projectile_red_orb(posx, posy, deltax, deltay, friendly)
	local data = {
		{
			master = true,
			x = posx,
			y = posy,
			dx = deltax,
			dy = deltay,
			hitx = posx + 2,
			hity = posy + 2,
			hitw = 10,
			hith = 10,
			sheet = entity_damage_orb_sheet,
			animation = create_animation(entity_damage_orb_sheet, 14, 14, '1-5', 0.05)
		},
	}

	local orb = Entity.new(data)
	orb.id = "damage_orb"
	orb.health = 1
	orb.friendly = false
	orb.dead = false

	function orb:update(dt)
		for _, obj in ipairs(self.data) do
			object_update_coordinates(dt, obj)
		end

		entity_default_update_calls(dt, self)
	end

	function orb:draw(dt)
		for _, obj in ipairs(self.data) do
			obj.animation:draw(obj.sheet, math.floor(obj.x), math.floor(obj.y))
		end
	end

	return orb
end

function create_projectile_water_drop(posx, posy, deltax, deltay, friendly)
	local data = {
		{
			master = true,
			x = posx,
			y = posy,
			dx = deltax,
			dy = deltay,
			hitx = posx,
			hity = posy,
			hitw = 20,
			hith = 21,
			sheet = entity_water_drop_sheet,
			animation = create_animation(entity_water_drop_sheet, 20, 21, '1-4', 0.05)
		},
	}

	local orb = Entity.new(data)
	orb.id = "water_drop"
	orb.health = 1
	orb.friendly = true

	function orb:update(dt)
		for _, obj in ipairs(self.data) do
			object_update_coordinates(dt, obj)
		end
		entity_default_update_calls(dt, self)
	end

	function orb:draw()
		for _, obj in ipairs(self.data) do
			obj.animation:draw(obj.sheet, math.floor(obj.x), math.floor(obj.y))
		end
	end

	return orb
end

function create_powerup_lilgab(posx, posy, deltax, deltay)
	local data = {
		{
			master = true,
			x = posx,
			y = posy,
			dx = deltax,
			dy = deltay,
			hitx = posx,
			hity = posy,
			hitw = 17,
			hith = 15,
			sheet = pickup_lilgabbron_sheet,
			animation = create_animation(pickup_lilgabbron_sheet, 17, 15, '1-2', 0.1),
		},
	}
	local gab = Entity.new(data)
	gab.id = "powerup_lil_gab"
	gab.points = 1000
	gab.seed = math.random() * 6.28 - 3.14
	gab.dead = false
	gab.timer = timer_global + 1
	gab.sound = love.audio.newSource("sounds/powerup_super.wav", 'static')

	function gab:effect()
		local obj = get_master_obj(self)
		local p1 = create_particle_shockwave(obj.x + (obj.hith / 2), obj.y + obj.hitw / 2, obj.dx / 2, obj.dy / 2)
		local p2 = create_particle_points(obj.x + obj.hith / 2, obj.y + obj.hitw / 2, obj.dx / 2, obj.dy / 2, self.points)
		local p3 = create_particle_message(obj.x + obj.hith / 2, obj.y + obj.hitw / 2, obj.dx / 2 + math.random(-50, 50), obj.dy / 2 + math.random(-50, 50), "Nice!", 3)
		table.insert(explosions, p1)
		table.insert(particles, p2)
		table.insert(particles, p3)
		self.sound:play()
	end

	function gab:update(dt)
		for _, obj in ipairs(self.data) do
			if player and timer_global - self.timer < 0 then
				local p_obj = get_master_obj(player)
				obj.dx, obj.dy = get_vector(obj, p_obj, 1, false)
			else
				obj.dx = math.sin(timer_global / 2 + self.seed) * 200
				obj.dy = math.sin(timer_global + self.seed) * 100
			end

			object_update_coordinates(dt, obj)
			entity_default_update_calls(dt, self)
		end
	end

	function gab:draw()
		for _, obj in ipairs(self.data) do
			obj.animation:draw(obj.sheet, math.floor(obj.x), math.floor(obj.y))
		end
	end
	return gab
end


function create_powerup_cheese(posx, posy, deltax, deltay)
	local data = {
		{
			master = true,
			x = posx,
			y = posy,
			dx = deltax,
			dy = deltay,
			hitx = posx,
			hity = posy,
			hitw = 26,
			hith = 26,
			sheet = pickup_cheese_sheet,
			animation = create_animation(pickup_cheese_sheet, 26, 26, '1-1', 1000),
		},
	}

	local cheese = Entity.new(data)
	cheese.id = "powerup_cheese"
	cheese.points = 250
	cheese.seed = math.random() * 6.28 - 3.14
	cheese.dead = false
	cheese.sound = love.audio.newSource("sounds/ploop.wav", 'static')

	function cheese:update(dt)
		for _, obj in ipairs(self.data) do
			obj.dy = math.sin(timer_global + self.seed) * 100
			
			object_update_coordinates(dt, obj)

			if (obj.x > (game_width) + 200 or obj.x < -200) or (obj.y > (game_height) + 200 or obj.y < -200) then
				cheese.dead = true
			end

			entity_default_update_calls(dt, self)
		end
		
	end

	function cheese:effect(dt)
		if player.health < player.max_health then
			player.health = player.health + 1
			create_particle_shockwave(ui_hearts_x + (7 * (player.health - 1)), ui_hearts_y + 7, 0, 0, 20, 400)
		end
		local p1 = create_particle_message(self.data[1].x + self.data[1].hith / 2, self.data[1].y + self.data[1].hitw / 2, self.data[1].dx / 2 + math.random(-50, 50), self.data[1].dy / 2 + math.random(-50, 50), "Health up!", 3)
		local p2 = create_particle_shockwave(self.data[1].x + (self.data[1].hith / 2), self.data[1].y + self.data[1].hitw / 2, self.data[1].dx / 2, self.data[1].dy / 2)
		local p3 = create_particle_points(self.data[1].x + self.data[1].hith / 2, self.data[1].y + self.data[1].hitw / 2, self.data[1].dx / 2, self.data[1].dy / 2, self.points)
		table.insert(explosions, p2)
		table.insert(particles, p1)
		table.insert(particles, p3)
		self.sound:play()
	end

	function cheese:draw()
		for _, obj in ipairs(self.data) do
			obj.animation:draw(obj.sheet, math.floor(obj.x), math.floor(obj.y))
		end
	end

	return cheese
end


--  ___  ____  ____  ___  ____    __    __   
-- / __)(  _ \( ___)/ __)(_  _)  /__\  (  )  
-- \__ \ )___/ )__)( (__  _)(_  /(__)\  )(__ 
-- (___/(__)  (____)\___)(____)(__)(__)(____)



-- function spawn_enemy(enemy, x, y, dx, dy, flags)

-- 	local e = enemy.new(x, y, gdx, gdy, flags)
-- 	local fucked = false
-- 	for i = #enemies, 1, -1 do
-- 		if get_collision(e, enemies[i]) then
-- 			fucked = true
-- 			return
-- 		end
-- 	end

-- 	if fucked then logstring = logstring .. "fucked" end
-- 	table.insert(enemies, e)
-- end

--  ____  ____  ____  ____  ___  ____  ___ 
-- ( ___)( ___)( ___)( ___)/ __)(_  _)/ __)
--  )__)  )__)  )__)  )__)( (__   )(  \__ \
-- (____)(__)  (__)  (____)\___) (__) (___/

function create_particle_points(x, y, dx, dy, points, apply, color)
	local myp = Particle.new(x, y, dx, dy)
	myp.lifetime = 3
	myp.points = points
	myp.timer = timer_global
	myp.blink_timer = BlinkTimer.new(myp.lifetime, 10)
	myp.id = "effect_message"
	myp.dead = false
	myp.color = color or 22
	myp.seed = math.random() * 0.5
	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		self.blink_timer:update(dt)
		if timer_global - self.timer > self.lifetime + self.seed then
			self.dead = true
			self.blink_timer = nil
		end
		
	end
	function myp:draw(dt)
		if type(self.color) == "table" then
			set_draw_color(blink(self.color, self.blink_timer))
		else
			set_draw_color(self.color)
		end
		love.graphics.print(self.points, math.floor(self.x), math.floor(self.y))
	end
	if apply == false then
		myp.points = 0
	end
	score = score + myp.points
	return myp
	
	
end

function create_particle_message(x, y, dx, dy, text, lifetime, color)
	local myp = Particle.new(x, y, dx, dy)
	myp.lifetime = lifetime
	myp.text = text
	myp.timer = timer_global
	myp.blink_timer = BlinkTimer.new(myp.lifetime, 10)
	myp.id = "effect_message"
	myp.seed = math.random() * 0.5
	myp.dead = false
	myp.color = color or 22

	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		self.blink_timer:update(dt)
		if self.lifetime ~= false and timer_global - self.timer > self.lifetime + self.seed then
			self.dead = true
			self.blink_timer = nil
		end
		if self.x > game_width + 20 or self.x < -20 or self.y > game_height or self.y < -20 then
			self.dead = true
			self.blink_timer = nil
		end
		
	end
	function myp:draw()
		if type(self.color) == "table" then
			set_draw_color(blink(self.color), self.blink_timer)
		else
			set_draw_color(self.color)
		end
		love.graphics.print(self.text, math.floor(self.x), math.floor(self.y))
	end
	return myp
end

function create_particle_shockwave(x, y, dx, dy, r, dr, da)
	local myp = Particle.new(x, y, dx, dy)
	myp.seed = math.random() * 0.25
	myp.lifetime = 1
	myp.id = "effect_shockwave"
	myp.r = r or 1
	myp.alpha = 1
	myp.dr = dr or 300--* math.random() * 1.5
	myp.timer = timer_global + myp.lifetime
	myp.dead = false
	local da = da or 2
	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		self.r = (self.r + self.dr * dt)
		local decrease_rate = 3.5
		local decrease_per_frame = decrease_rate / love.timer.getFPS()
		self.dr = self.dr * (1 - decrease_per_frame)
		self.alpha = self.alpha - da * dt

		if timer_global - self.timer > 0 then
			self.dead = true
		end
	end

	function myp:draw()
		love.graphics.setColor(1, 1, 1, self.alpha)
		love.graphics.circle('line', math.floor(self.x), math.floor(self.y), self.r)
		set_draw_color(22)
	end
	
	return myp
end

function create_particle_break(x, y, dx, dy)
	local myp = Particle.new(x, y, dx, dy)
	myp.seed = math.random() * 0.25
	myp.lifetime = 1
	myp.id = "effect_break"
	myp.dx = dx or math.random(-300, 300)
	myp.dy = dy or math.random(-300, 300)
	myp.r = 1
	myp.timer = timer_global + myp.lifetime + myp.seed 
	myp.dead = false
	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		local decrease_rate = 2.5
		local decrease_per_frame = decrease_rate / love.timer.getFPS()
		self.dx = self.dx * (1 - decrease_per_frame)
		self.dy = self.dy * (1 - decrease_per_frame)
		if timer_global - self.timer > 0 then
			self.dead = true
		end
	end
	function myp:draw()
		set_draw_color(22)
		love.graphics.circle('fill', math.floor(self.x), math.floor(self.y), self.r)
	end
	return myp
end

function create_particle_burst(x, y, dx, dy, r, dr)
	local myp = Particle.new(x, y, dx, dy)
	myp.lifetime = 1
	myp.id = "effect_burst"
	myp.r = r or 30
	myp.dr = dr or 200
	myp.timer = timer_global + myp.lifetime
	myp.dead = false
	function myp:update(dt)
		self.x = (self.x + (self.dx) * dt)
		self.y = (self.y + (self.dy) * dt)
		if self.r > 0 then
			self.r = self.r - self.dr * dt
			self.dr = self.dr - 1
		end
		if self.r < 0 then
			self.r = 0
		end
		if timer_global - self.timer > 0 then
			self.dead = true
		end
	end
	function myp:draw()
		if math.sin(timer_global * 50) < 0.33 then
			set_draw_color(22)
		elseif math.sin(timer_global * 50) > -0.1 then
			set_draw_color(6)
		else
			set_draw_color(28)
		end
		love.graphics.circle("fill", math.floor(self.x), math.floor(self.y), math.floor(self.r))
	end
	return myp
end

-- MAKES AN EXPLOSION AT A COORDINATE
function create_particle_explosion(x, y, dx, dy)
	local myp = Particle.new(x, y, dx, dy)
	myp.lifetime = 2
	myp.seed = math.random() * 0.1
	myp.id = "effect_explosion"
	myp.r = math.floor(math.random(5, 10))
	myp.timer = timer_global + myp.lifetime + myp.seed
	myp.dead = false
	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		local decrease_rate = 2.5
		local decrease_per_frame = decrease_rate / love.timer.getFPS()
		self.r = self.r - 5 * dt
		if self.r < 0 then
			self.r = 0
		end
		self.dx = self.dx * (1 - decrease_per_frame)
		self.dy = self.dy * (1 - decrease_per_frame)

		if timer_global - self.timer > 0 then
			self.dead = true
		end
	end

	function myp:draw()
		local time_elapsed = timer_global - (self.timer - self.lifetime + self.seed)
		if time_elapsed < 0.1 then
			set_draw_color(22)
		elseif time_elapsed > 0.5 then
			set_draw_color(25)
		elseif time_elapsed > 0.4 then
			set_draw_color(4)
		elseif time_elapsed > 0.3 then
			set_draw_color(28)
		elseif time_elapsed > 0.2 then
			set_draw_color(6)
		elseif time_elapsed > 0.1 then
			set_draw_color(9)
		end
		love.graphics.circle('fill', math.floor(self.x), math.floor(self.y), self.r)
	end

	return myp
end

function effect_starfield(x, y, w, h)
	for i = 1, (w / 6) + (h / 6) do
		star = Particle.new(math.random(x, w), math.random(y, h), math.random(0, -150), math.random(0, 0), nil, nil)
		star.id = "starfield_star"
		star.sheet = particle_star_sheet
		star.animation = create_animation(particle_star_sheet, 4, 7, '1-4', 0.1)
		star.dead = false
		function star:update(dt)
			self.x = self.x + self.dx * dt
			self.y = self.y + self.dy * dt
			if self.dx < x and self.x < x - 50 then
				self.x = w + 50
			elseif self.dx > x and self.x > w + 50 then
				self.x = x - 50
			end
			self.animation:update(dt)
		end
		table.insert(background, star)
	end
end



function death_effect_explode(entity, only_on_master)
	if only_on_master == true then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		for p = 1, 50 do
			local particle = create_particle_explosion(pointX, pointY, math.random(-125, 125) + obj.dx, math.random(-125, 125) + obj.dy)
			table.insert(particles, particle)
		end
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			for p  = 1, 50 do
				local particle = create_particle_explosion(pointX, pointY, math.random(-125, 125) + obj.dx, math.random(-125, 125) + obj.dy)
				table.insert(particles, particle)
			end
		end
	end
	
end

function death_effect_shockwave(entity, only_on_master)
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		for i = 1, 3 do
			local explosion = create_particle_shockwave(pointX, pointY, obj.dx / 4, obj.dy / 4)
			table.insert(explosions, explosion)
		end
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			for i = 1, 3 do
				local explosion = create_particle_shockwave(pointX, pointY, obj.dx / 4, obj.dy / 4)
				table.insert(explosions, explosion)
			end
		end
	end
	
end

function death_effect_burst(entity, only_on_master)
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		local explosion = create_particle_burst(pointX, pointY, obj.dx * 0.75, obj.dy * 0.75, 50)
		table.insert(explosions, explosion)
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			local explosion = create_particle_burst(pointX, pointY, obj.dx * 0.75, obj.dy * 0.75, 50)
			table.insert(explosions, explosion)
		end
	end
	
end

function death_effect_break(entity, only_on_master)
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		for i = 1, 50 do
			local particle = create_particle_break(pointX, pointY, obj.dx + math.random(-300, 300), obj.dy + math.random(-300, 300))
			table.insert(particles, particle)
		end
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			for i = 1, 50 do
				local particle = create_particle_break(pointX, pointY, obj.dx + math.random(-300, 300), obj.dy + math.random(-300, 300))
				table.insert(particles, particle)
			end
		end
	end
	
end

function death_effect_sound_blockhit(entity, only_on_master)
	local sound = love.audio.newSource("sounds/block_hit.wav", 'static')
	sound:play()
end

function death_effect_spawn_lilgab(entity, only_on_master)
	local sound = love.audio.newSource("sounds/poink.wav", "static")
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		local value = math.random(1, 100)
		if value < 25 then
			local gab = create_powerup_lilgab(pointX, pointY, -150, 0)
			table.insert(powerups, gab)
			sound:play()
		end
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			local value = math.random(1, 100)
			if value < 100 then
				local gab = create_powerup_lilgab(pointX, pointY, -150, 0)
				table.insert(powerups, gab)
				sound:play()
			end
		end
	end
end

function death_effect_spawn_heart(entity, only_on_master)
	local sound = love.audio.newSource("sounds/poink.wav", "static")
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		local value = math.random(1, 100)
		if entity.chance_100_heart then
			value = 1
		end
		if value < 5 then
			local cheese = create_powerup_cheese(pointX, pointY, -75, 0)
			table.insert(powerups, cheese)
			sound:play()
		end
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			local value = math.random(1, 100)
			if entity.chance_100_heart then
				value = 1
			end
			if value < 5 then
				local cheese = create_powerup_cheese(pointX, pointY, -75, 0)
				table.insert(powerups, cheese)
				sound:play()
			end
		end
	end
	
end

function death_effect_points(entity, only_on_master, apply)
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2
		local points = entity.points
		local particle = create_particle_points(pointX, pointY, obj.dx / 2.5 + math.random(-50, 50), obj.dy / 5 + math.random(-50, 50), points, apply, {21, 22, 23, 20, 10, 11, 22})
		table.insert(particles, particle)
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2
			local points = entity.points
			local particle = create_particle_points(pointX, pointY, obj.dx / 2.5 + math.random(-50, 50), obj.dy / 5 + math.random(-50, 50), points, apply, {21, 22, 23, 20, 10, 11, 22})
			table.insert(particles, particle)
		end
	end
end





--  ___  _   _  _____  ____  ___ 
-- / __)( )_( )(  _  )(_  _)/ __)
-- \__ \ ) _ (  )(_)(   )(  \__ \
-- (___/(_) (_)(_____) (__) (___/

function single_water_shot(x, y, dx, dy, friendly)
	local water = create_projectile_water_drop(x, y, dx, dy, friendly)
	
	--timer_secondshot = timer_global
	local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
	sound:play()
	
	table.insert(bullets, water)
	
end

function double_water_shot(x, y, dx, dy, friendly)
	--21
	local water1 = create_projectile_water_drop(x, y + 21/2, dx, dy, friendly)
	local water2 = create_projectile_water_drop(x, y - 21/2, dx, dy, friendly)
	local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
	sound:play()
	
	table.insert(bullets, water1)
	table.insert(bullets, water2)
end

function triple_water_shot(x, y, dx, dy, friendly)
	local water1 = create_projectile_water_drop(x, y + 21/2, dx * 0.9, -dx * 0.3, friendly)
	local water2 = create_projectile_water_drop(x, y, dx, dy, friendly)
	local water3 = create_projectile_water_drop(x, y - 21/2, dx * 0.9, dx * 0.3, friendly)
	local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
	sound:play()
	
	table.insert(bullets, water1)
	table.insert(bullets, water2)
	table.insert(bullets, water3)
end

function quintuple_water_shot(x, y, dx, dy, friendly)
	local mod = 0.25
	local w1 = create_projectile_water_drop(x - 8, y - 40, dx, dy, friendly)
	local w2 = create_projectile_water_drop(x - 2, y - 20, dx , dy, friendly)
	local w3 = create_projectile_water_drop(x, y, dx, dy, friendly)
	local w4 = create_projectile_water_drop(x - 2, y + 20, dx, dy, friendly)
	local w5 = create_projectile_water_drop(x - 8, y + 40, dx, dy, friendly)
	local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
	sound:play()
	
	table.insert(bullets, w1)
	table.insert(bullets, w2)
	
	table.insert(bullets, w4)
	table.insert(bullets, w5)
	table.insert(bullets, w3)
end

function red_orb_shot(x, y, dx, dy, friendly)
	local orb = create_projectile_red_orb(x, y, dx, dy, friendly)
	local sound = love.audio.newSource("sounds/weak_shot.wav", 'static')
	sound:play()

	table.insert(bullets, orb)
end





--   ___    __    __  __  ____    __    _____    __    ____  
--  / __)  /__\  (  \/  )( ___)  (  )  (  _  )  /__\  (  _ \ 
-- ( (_-. /(__)\  )    (  )__)    )(__  )(_)(  /(__)\  )(_) )
--  \___/(__)(__)(_/\/\_)(____)  (____)(_____)(__)(__)(____/ 

-- load functions

function love.load()
	love.window.setTitle("CARMINE'S RETRIBUTION")
	love.window.setIcon(love.image.newImageData("sprites/player/carmine/carmine_icon.png"))
	load_startscreen()
	switch_mode('start')

	-- timers
	-- - make sure to set timer to nill after using
	timer_global = 1
	timer_levelselect_delay = nil

	timer_menu_delay = nil

	timer_invulnerable = nil
	timer_shot = nil
	timer_secondshot = nil

	timer_enemy_spawner = 1
	timer_game_speed = 1

	enemy_killed_count = 0
	enemy_rock_killed_count = 0
	enemy_gross_killed_count = 0
	enemy_drang_killed_count = 0

	game_difficulty_factor = 1

	shader_flash = love.graphics.newShader[[
		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
		{
			vec4 pixel = Texel(texture, texture_coords); // get current pixel color
			return vec4(1.0, 1.0, 1.0, pixel.a); // return modified pixel color
		}
	]]

	
end



function load_player()
	-- important attributes
	PLAYER_MAX_HEALTH = 4
	PLAYER_ATTACK_SPEED = 0.25

	player = create_player_carmine(100, 200)
	
end

function load_startscreen()
	letters = {}
	function create_letter(id, x, y, bottom_y)
		local l = ParticleObject.new(x, y)
		l.id = id
		l.sheet = load_image(letters_title[id][1])
		l.animation = create_animation(l.sheet, letters_title[id][2], letters_title[id][3], '1-1', 1000)
		l.colliding = false
		l.dy = 10
		l.firstbounce = true
		function l:update(dt)
			self.x = (self.x + self.dx * dt)
			self.y = (self.y + self.dy * dt)
			if self.dy < 300 then
				self.dy = self.dy + 300 * dt
			end
			if self.y < bottom_y then
				self.colliding = false
			end
			if self.y > bottom_y and not self.colliding and self.firstbounce then
				self.colliding = true
				self.dy = -self.dy / 2
				self.firstbounce = false
			end

			if self.y > bottom_y and not self.colliding and not self.firstbounce then
				self.colliding = true
				self.dy = -self.dy + 1
			end
			if self.y > bottom_y and self.colliding then
				self.y = bottom_y
			end
			self.animation:update(dt)
		end
		table.insert(letters, l)
	end

	local startX = 100
	local minY = 75
	local maxY = 100
	local height = 120
	local player_letters = {13, 2, 9, 6, 5, 7, 4, 1, 10}
	local retribution_letters = {14, 4, 11, 9, 5, 3, 12, 11, 5, 8, 7}

	-- for i = 1, #player_letters do
	-- 	if player_letters[i] == 1 then
	-- 		create_letter(player_letters[i], startX, math.random(minY, maxY), height - 30)
	-- 	else
	-- 		create_letter(player_letters[i], startX, math.random(minY, maxY), height)
	-- 	end
	-- 	startX = startX + 3 + letters_title[player_letters[i]][2]
	-- end

	-- startX = 50
	-- minY = 150
	-- maxY = 200

	-- for i = 1, #retribution_letters do
	-- 	if retribution_letters[i] == 1 then
	-- 		create_letter(retribution_letters[i], startX, math.random(minY, maxY), height - 30 + 100)
	-- 	else
	-- 		create_letter(retribution_letters[i], startX, math.random(minY, maxY), height + 100)
	-- 	end
	-- 	startX = startX + 3 + letters_title[retribution_letters[i]][2]
	-- end
end

function load_levelscreen()
	-- level info
	ui_label_level_num_text = "WAVE 1"
	ui_label_level_num = love.graphics.newText(font_gamer_med, ui_label_level_num_text)
	ui_label_level_num_x = center_text(ui_label_level_num_text)
	ui_label_level_num_y = (game_height / 2) - 60

	ui_label_level_name_text = "OUTER SPACE"
	ui_label_level_name = love.graphics.newText(font_gamer_med, ui_label_level_name_text)
	ui_label_level_name_x = center_text(ui_label_level_name_text)
	ui_label_level_name_y = (game_height / 2) - 40
end

function load_gameover()
	ui_label_deathmessage_text = "YOU SUCK"
	ui_label_deathmessage = love.graphics.newText(font_gamer_med, ui_label_deathmessage_text)
	ui_label_deathmessage_x = center_text(ui_label_deathmessage_text)
	ui_label_deathmessage_y = (game_height / 2) - 60

	ui_label_angry_text = "NOT WORTHY OF RETRIBUTION"
	ui_label_angry = love.graphics.newText(font_gamer_med, ui_label_angry_text)
	ui_label_angry_x = center_text(ui_label_angry_text)
	ui_label_angry_y = (game_height / 2) - 40
end

function load_ui()
	load_levelscreen()
	load_gameover()
	-- name
	ui_label_name = love.graphics.newText(font_gamer_med, "CARMINE")
	ui_label_name_x = 4
	ui_label_name_y = 4

	-- life
	ui_label_life = love.graphics.newText(font_gamer_med, "-LIFE-")
	ui_label_life_x = ui_label_name:getWidth() + 12
	ui_label_life_y = 4
	hearts = {}
	ui_hearts_x = ui_label_life_x
	ui_hearts_y = ui_label_life_y + ui_label_life:getHeight()
	ui_hearts_length = 13 * PLAYER_MAX_HEALTH
	for i = 1, PLAYER_MAX_HEALTH do
		create_ui_heart(ui_hearts_x + (12 * (i - 1)), ui_hearts_y)
	end
	
	-- score
	ui_label_score = love.graphics.newText(font_gamer_med, "-SCORE-")
	if ui_label_life:getWidth() > ui_hearts_length then
		ui_label_score_x = ui_label_life_x + ui_label_life:getWidth() + 6
	else
		ui_label_score_x = ui_label_life_x + ui_hearts_length + 6
	end
	
	ui_label_score_y = 4
	ui_score = love.graphics.newText(font_gamer_med, score)
	ui_score_x = ui_label_score_x + 8
	ui_score_y = ui_label_score_y + ui_label_score:getHeight() + 2

	-- time
	ui_label_time = love.graphics.newText(font_gamer_med, "-TIME-")
	ui_label_time_x = game_width - 4 - ui_label_time:getWidth()
	ui_label_time_y = 4
	ui_time = love.graphics.newText(font_gamer_med, math.floor(timer_global))
	ui_time_x = ui_label_time_x + 8
	ui_time_y = ui_label_time_y + ui_label_time:getHeight()


	-- kills
	ui_label_kills = love.graphics.newText(font_gamer_med, "-KILLS-")
	ui_label_kills_x = ui_label_time_x - 12 - ui_label_kills:getWidth()
	ui_label_kills_y = 4
	ui_kills = love.graphics.newText(font_gamer_med, enemy_killed_count)
	ui_kills_x = ui_label_kills_x + 8
	ui_kills_y = ui_label_kills_y + ui_label_life:getHeight()
end

function reset_game()
	-- init variables
	clear_all()

	-- ui
	score = 0
	load_player()
	load_ui()
	level = 1

	-- these are the controllers for every moving object
	-- everything which moves along the screen should reference these variables

	game_speed_factor = 1
	game_difficulty_factor = 1

	sound_slash = love.audio.newSource("sounds/slash.wav", 'static')
	shot_circ_r = 0
	shot_circ_x = 0
	shot_circ_y = 0

	timer_global = 1
	timer_enemy_spawner = 1
	timer_game_speed = 1
	game_difficulty_factor = 1
	timer_levelselect_delay = nil

	timer_menu_delay = nil

	timer_invulnerable = nil
	timer_shot = nil
	timer_secondshot = nil

	enemy_killed_count = 0
	enemy_rock_killed_count = 0
	enemy_gross_killed_count = 0
	enemy_drang_killed_count = 0

	

	if level == 1 then
		effect_starfield(0, 0, game_width, game_height)
	end
end






--   ___    __    __  __  ____    __  __  ____  ____    __   ____  ____ 
--  / __)  /__\  (  \/  )( ___)  (  )(  )(  _ \(  _ \  /__\ (_  _)( ___)
-- ( (_-. /(__)\  )    (  )__)    )(__)(  )___/ )(_) )/(__)\  )(   )__) 
--  \___/(__)(__)(_/\/\_)(____)  (______)(__)  (____/(__)(__)(__) (____)

-- sets a deletion condition
-- removes all nil values from a table, moving subsequent values up
-- if you need to destroy an object, just set it to nil within its collection, garbage collection will take care of it
function update_enemies(dt)
	for i = #enemies, 1, -1 do
		enemies[i]:update(dt)
		if enemies[i].dead then
			table.remove(enemies, i)
		end
	end
end

function update_bullets(dt)
	for i = #bullets, 1, -1 do
		bullets[i]:update(dt)
		if bullets[i].dead then
			table.remove(bullets, i)
		end
	end
end

function update_explosions(dt)
	for i = #explosions, 1, -1 do
		explosions[i]:update(dt)
		if explosions[i].dead then
			table.remove(explosions, i)
		end
	end
end

function update_powerups(dt)
	for i = #powerups, 1, -1 do
		powerups[i]:update(dt)
		if powerups[i].dead then
			table.remove(powerups, i)
		end
	end
end

function update_particles(dt)
	for i = #particles, 1, -1 do
		particles[i]:update(dt)
		if particles[i].dead then
			table.remove(particles, i)
		end
	end
end

function update_letters(dt)
	for i = #letters, 1, -1 do
		letters[i]:update(dt)
		if mode ~= 'start' then
			table.remove(letters, i)
		end
	end
end

function update_hearts(dt)
	-- my balls are in agony :((
	for i = #hearts, 1, -1 do
		hearts[i].full = false
	end
	for i = 1, PLAYER_MAX_HEALTH do
		if player and i <= player.health then
			hearts[i].full = true
		else
			hearts[i].full = false
		end
		hearts[i]:update(dt)
	end
end

function update_ui(dt)
	for i = #ui, 1, -1 do
		if ui[i].id == "display_text" then
			ui[i]:update(dt)
			if ui[i].delay ~= false and timer_global - ui[i].timer > 1 then
				--table.remove(ui, i)
			end
		end
	end
end

function update_background(dt)
	for i = #background, 1, -1 do
		local decor = background[i]
		decor:update(dt)
		local decor_left_game_area = (decor.x > (window_width / window_scale) + 200 or decor.x < -200) or (decor.y > (window_height / window_scale) + 200 or decor.y < -200)
		if decor_left_game_area then
			table.remove(decors, i)
		end
	end
end

function update_player(dt)
	if not player then
		return
	end
	for _, obj in ipairs(player.data) do
		object_control(obj, 250, "a", "d", "w", "s")
	end
	player:update(dt)
	player:shoot(dt)
	if player.dead then
		player = nil
	end
	
end


function game_rules(dt)
	-- get coordinates of possible enemy spawn
	-- do for loop through enemies
	-- if coordinates collide with another enemy, don't spawn
	-- - instead, add to queue and continually spawn those from the queue when able
	x = game_width + 2
	y = math.random(2, game_height - 50)

	local spawn_occured = false

	-- enemy spawning difficulty measuring
	if timer_global - timer_enemy_spawner > game_difficulty_factor then
		if game_difficulty_factor > 0.25 then
			game_difficulty_factor = game_difficulty_factor - 0.0025
		end
		if math.random(0, 100) < 50 then
			--spawn_enemy(Enemy_Rock, x, y)
			local rock = create_enemy_rock(x, y, -100 * game_speed_factor, 0)
			table.insert(enemies, rock)
			spawn_occured = true
		end
		if math.random(0, 100) < 25 then
			local gross = create_enemy_gross(x, y, -150 * game_speed_factor, 0)
			table.insert(enemies, gross)
			spawn_occured = true
		end
		if math.random(0, 100) < 10 * game_difficulty_factor then
			local drang = create_enemy_drang(x, y, -125 * game_speed_factor, 0)
			table.insert(enemies, drang)
			spawn_occured = true
		end
		if not spawn_occured then
			local obj = get_master_obj(player)
			create_particle_message(obj.x, obj.y, math.random(-100, 100), math.random(-100, 100), "Cursed...", 3)
		end
		timer_enemy_spawner = timer_global
	end
	if timer_global > 300 and game_difficulty_factor > 0.1 and timer_global - timer_game_speed > 1 then
		game_difficulty_factor = game_difficulty_factor - 0.001
	end
	if timer_global - timer_game_speed > 1 then
		game_speed_factor = game_speed_factor + 0.001
		timer_game_speed = timer_global
	end
end



function update_game(dt)
	logstring = ""
	load_ui() -- probably shouldn't have this here, but right now it's fine
	if timer_levelselect_delay and timer_global - timer_levelselect_delay > 3 then
		timer_levelselect_delay = nil
	end

	if not player or (player and player.health <= 0) then
		switch_mode('gameover')
	end

	if love.keyboard.isDown('r') then
		clear_all()
	end
	if timer_global > 32000 then
		timer_global = 1
	end

	
	--logstring = logstring .. (math.random(-3.14, 3.14))

	-- collection updates
	update_bullets(dt)
	update_background(dt)
	update_enemies(dt)
	update_player(dt)
	update_powerups(dt)
	update_explosions(dt)
	update_particles(dt)
	update_hearts(dt)

	
	
	-- collision effects
	for i = 1, #enemies do -- friendly bullet collide with enemy
		local enemy = enemies[i]
		for _, e_obj in ipairs(enemy.data) do
			for j = 1, #bullets do
				local bullet = bullets[j]
				for _, b_obj in ipairs(bullet.data) do
					if bullet.friendly and not enemy.friendly and get_collision(e_obj, b_obj) then
						enemy.health = enemy.health - 1
						bullet.health = bullet.health - 1

						local sound = love.audio.newSource("sounds/deep_hit.wav", 'static')
						sound:play()
						local p1 = create_particle_shockwave(b_obj.x + b_obj.hitw/2, b_obj.y + b_obj.hith/2, b_obj.dx * 0.05, b_obj.dy * 0.05, 1, 50, 1)
						table.insert(explosions, p1)
						for index = 1, 3 do
							local p2 = create_particle_break(e_obj.x + e_obj.hitw / 2, e_obj.y + e_obj.hith / 2)
							table.insert(particles, p2)
						end
						enemy.flash = 0.05
					end
				end
			end
		end
	end

	

	if not player then
		return
	end

	

	for i = 1, #enemies do -- enemy collide with player
		for _, obj in ipairs(enemies[i].data) do
			if not enemies[i].friendly and get_collision(get_master_obj(player), obj) then
				if not player.timer_invulnerable then
					sound_slash:play()
					enemies[i].health = enemies[i].health - 1
					player.flash = 0.1
					player.health = player.health - 1

					local sound = love.audio.newSource("sounds/deep_hit.wav", "static")
					sound:play()

					enemies[i].flash = 0.05
					player.timer_invulnerable = timer_global
					return
				else
					
					
				end
			end
		end
	end

	for i = #bullets, 1, -1 do -- enemy bullet collide with player
		for _, obj in ipairs(bullets[i].data) do
			if not bullets[i].friendly and get_collision(get_master_obj(player), obj) then
				if not player.timer_invulnerable then
					local p1 = create_particle_burst(obj.x, obj.y, obj.dx, obj.dy)
					table.insert(explosions, p1)
					sound_slash:play()
					player.flash = 0.1
					player.health = player.health - 1
					player.timer_invulnerable = timer_global
					return
				else
					
					
				end
				table.remove(bullets, i)
			end
		end
	end

	for i = #powerups, 1, -1 do -- player collision with powerup
		for _, obj in ipairs(powerups[i].data) do
			local player_master = get_master_obj(player)
			if get_collision(player_master, obj) then
				powerups[i]:effect(dt)

				table.remove(powerups, i)
			end
		end
		
	end
	
	
	if not timer_levelselect_delay then
		game_rules(dt)
	end
end

function update_start(dt)
	-- update function for start screen
	update_letters(dt)
	if love.keyboard.isDown('space') and not key_space_pressed then
		switch_mode('game')
		key_space_pressed = true
		if not timer_levelselect_delay then
			timer_levelselect_delay = timer_global
		end
	end
end

function update_gameover(dt)
	-- update function for gameover screen
	if love.keyboard.isDown('space') and not key_space_pressed then
		switch_mode('start')
		key_space_pressed = true
	end
end

function update_credits(dt)
	if love.keyboard.isDown('space') and not key_space_pressed then
		switch_mode('start')
		key_space_pressed = true
	end
end

-- startscreen
function load_start()

end







--   ___    __    __  __  ____    ____  ____    __    _    _ 
--  / __)  /__\  (  \/  )( ___)  (  _ \(  _ \  /__\  ( \/\/ )
-- ( (_-. /(__)\  )    (  )__)    )(_) ))   / /(__)\  )    ( 
--  \___/(__)(__)(_/\/\_)(____)  (____/(_)\_)(__)(__)(__/\__)

function draw_background()
	for i = 1, #background do
		local decor = background[i]
		decor.animation:draw(decor.sheet, math.floor(decor.x), math.floor(decor.y))
	end
end

function draw_enemies()
	for i = 1, #enemies do
		-- draw white shader effect when hit
		if enemies[i].flash and enemies[i].flash > 0 then
			love.graphics.setShader(shader_flash)
		end
		enemies[i]:draw()
		love.graphics.setShader()
	end
end

function draw_hearts()
	for i = 1, #hearts do
		hearts[i]:draw()
	end
end

function draw_bullets()
	for i = 1, #bullets do
		bullets[i]:draw()
	end
end

function draw_powerups()
	for i = 1, #powerups do
		powerups[i]:draw()
	end
end

function draw_explosions()
	for i = 1, #explosions do
		explosions[i]:draw()
	end
end

function draw_letters()
	for i = 1, #letters do
		local letter = letters[i]
		set_draw_color(22)
		letter.animation:draw(letter.sheet, math.floor(letter.x), math.floor(letter.y) - letters_title[letter.id][3])
	end
end

function draw_particles()
	for i = 1, #particles do
		particles[i]:draw()
	end
	set_draw_color(22)
end

function draw_player()
	if not player then
		return
	end
	if player.flash and player.flash > 0 then
		love.graphics.setShader(shader_flash)
	end
	player:draw()
	set_draw_color(22)
	love.graphics.circle('fill', math.floor(shot_circ_x), math.floor(shot_circ_y), shot_circ_r)
end

function draw_ui()
	set_draw_color(7)
	love.graphics.draw(ui_label_name, ui_label_name_x, ui_label_name_y)
	for i = 1, #ui do
		if ui[i].id == "display_text" then
			set_draw_color(ui[i].color)
			love.graphics.draw(ui[i].obj, ui[i].x, ui[i].y)
		end
	end
	set_draw_color(22)
	love.graphics.draw(ui_label_life, ui_label_life_x, ui_label_life_y)
	draw_hearts()
	love.graphics.draw(ui_label_score, ui_label_score_x, ui_label_score_y)
	love.graphics.draw(ui_score, ui_score_x, ui_score_y)

	love.graphics.draw(ui_label_time, ui_label_time_x, ui_label_time_y)
	love.graphics.draw(ui_time, ui_time_x, ui_time_y)
	love.graphics.draw(ui_label_kills, ui_label_kills_x, ui_label_kills_y)
	love.graphics.draw(ui_kills, ui_kills_x, ui_kills_y)
end

function draw_game()
	draw_background()
	draw_ui()
	draw_particles()
	draw_enemies()
	draw_bullets()
	draw_explosions()
	draw_powerups()
	draw_player()

	-- this is for level info at beginning of thing
	if timer_levelselect_delay then
		draw_levelscreen()
	end

end

function clear_message_effects()
	for i = 1, #particles do
		if particles[i].id == "effect_message" then
			table.remove(particles, i)
		end
	end
end

function draw_levelscreen()
	set_draw_color(blink({21, 22, 23, 24}, timer_blink))
	love.graphics.draw(ui_label_level_num, ui_label_level_num_x, ui_label_level_num_y)
	love.graphics.draw(ui_label_level_name, ui_label_level_name_x, ui_label_level_name_y)
	set_draw_color(22)
end

function draw_gameover()
	set_draw_color(blink({9, 6, 28}, timer_blink))
	love.graphics.draw(ui_label_deathmessage, ui_label_deathmessage_x, ui_label_deathmessage_y)
	love.graphics.draw(ui_label_angry, ui_label_angry_x, ui_label_angry_y)
	set_draw_color(22)
end

-- returns x value
function center_text(text)
	local x = (game_width / 2) - math.floor((love.graphics.getFont():getWidth(text)) / 2)
	return x
end

function draw_start()
	set_draw_color(blink({21, 22, 22, 22, 23, 24}, timer_blink))
	local text1 = "CARMINE'S RETRIBUTION"
	local text2 = "PRESS ANY KEY TO START"
	love.graphics.print(text1, center_text(text1), (game_height / 2) - 60)
	love.graphics.print(text2, center_text(text2), (game_height / 2 ) - 40)
end



function switch_mode(m)
	if m == 'game' then
		clear_all()
		reset_game()
	elseif m == 'start' then
		clear_all()
	elseif m == 'gameover' then

	elseif m == 'results' then

	elseif m == 'credits' then

	elseif m == 'levelscreen' then

	end
	mode = m
end

function love.update(dt)
	timer_global = timer_global + (1 * dt)
	if mode == 'game' then
		update_game(dt)
	elseif mode == 'start' then
		update_start(dt)
	elseif mode == 'gameover' then
		update_game(dt)
		update_gameover(dt)
	elseif mode == 'results' then

	elseif mode == 'credits' then
		update_credits(dt)
		
	elseif mode == 'levelscreen' then
		update_levelscreen(dt)
	end
end

function love.draw()
	push:start()
		--love.graphics.print(mode, 600, 4)
		if mode == 'game' then
			draw_game()
		elseif mode == 'start' then
			--draw_letters()
			draw_start()
		elseif mode == 'gameover' then
			draw_game()
			draw_gameover()
		elseif mode == 'levelscreen' then
			draw_levelscreen()
		end
		if logstring then
			log1:log(logstring)
		end
		
		log1:draw(0, 0)
	push:finish()
end

function love.keyreleased(key)
	if key == 'space' then
		key_space_pressed = false
	end
end