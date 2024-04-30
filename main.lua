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
	for _, obj in ipairs(entity) do
		if obj.master then
			return obj
		end
	end
end












 
--  _____  ____   ____  ____  ___  ____  ___ 
-- (  _  )(  _ \ (_  _)( ___)/ __)(_  _)/ __)
--  )(_)(  ) _ <.-_)(   )__)( (__   )(  \__ \
-- (_____)(____/\____) (____)\___) (__) (___/

local Background = {}
Background.__index = Background

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



local Entity = {}
Entity.__index = Entity

function Entity.new(data)
	local self = setmetatable({}, Entity)
	-- this data variable will contain a table of tables containing metadata
	-- in its update function, each table will be updated
	-- make sure the data is in this format {{...}, {...}, {...}}
	self.data = data

	-- self.death_effects
	-- self.death_condition
	-- self.points
	-- self.friendly
	-- self.max_health
	-- self.health
	return self
end



local Particle = {}
Particle.__index = Particle

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



local Pickup = {}
Pickup.__index = Pickup

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



local Terrain = {}
Terrain.__index = Terrain

function Terrain.new(x, y, dx, dy, hitw, hith, w, h, sheet, animation)
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





---------------------------

local ParticleObject = {}
ParticleObject.__index = ParticleObject

function ParticleObject.new(x, y, dx, dy, id)
	local self = setmetatable({}, ParticleObject)
	self.x = x or 0
	self.y = y or 0
	self.dx = dx or 0
	self.dy = dy or 0
	self.id = id or nil
	self.timer = timer_global
	self.seed = math.random() * 0.25
	return self
end

function ParticleObject:update(dt)
	self.x = (self.x + self.dx * dt)
	self.y = (self.y + self.dy * dt)
end

local ExplosionObject = {}
ExplosionObject.__index = ExplosionObject

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
	self.friendly = flags.friendly or nil
	self.health = flags.health or nil
	self.points = flags.points or 0
	self.death_effects = nil

	-- timers
	self.flash = 0
	return self
end

function MoveableObject:trigger_death_effects()
	if self.death_effects then
		for _, effect in ipairs(self.death_effects) do
			effect(self)
		end
	end
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

	-- flash tickdown
	if self.flash and self.flash > 0 then
		self.flash = self.flash - (1 * dt)
	end

	-- animation zone
	if self.animation then
		self.animation:update(dt)
	end
end

function draw_hitbox(obj)
	love.graphics.rectangle('line', math.floor(obj.hitx) - 0.25, math.floor(obj.hity) - 0.25, math.floor(obj.hitw) + 0.5, math.floor(obj.hith) + 0.5)
end

function control(obj, speed, left, right, up, down)
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

--  ____  _  _  _   _  ____  ____  ____  ____  ____  ____  
-- (_  _)( \( )( )_( )( ___)(  _ \(_  _)(_  _)( ___)(  _ \ 
--  _)(_  )  (  ) _ (  )__)  )   / _)(_   )(   )__)  )(_) )
-- (____)(_)\_)(_) (_)(____)(_)\_)(____) (__) (____)(____/ 

local Graphic_Heart = {}
Graphic_Heart.__index = Graphic_Heart

setmetatable(Graphic_Heart, {__index = ParticleObject})

function Graphic_Heart.new(x, y, dx, dy)
	local self = ParticleObject.new(x, y, dx, dy, id)
	setmetatable(self, Graphic_Heart)
	self.id = "heart_graphic"
	self.sheet = particle_heart_sheet
	self.animation = create_animation(self.sheet, 11, 11, '1-2', 100)
	self.full = true
	return self
end

function Graphic_Heart:update(dt)
	self.animation:update(dt)
	if self.full then
		self.animation:gotoFrame(1)
	else
		self.animation:gotoFrame(2)
	end
end

function trigger_death_effects(entity, only_on_master)
	if entity.death_effects then
		for _, effect in ipairs(entity.death_effects) do
			effect(entity, only_on_master)
		end
	end
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
	player.health = 1
	player.attack_speed = 1
	player.attack_type = "none"
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

		if self.health <= 0 then
			trigger_death_effects(self, true)
			self.dead = true
		end
	end

	function player:shoot(dt)
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
				double_water_shot(math.floor(data[2].x + 10), math.floor(data[2].y), 550, 0, true)
			end
			if self.secondshot then
				self.timer_secondshot = timer_global
			end
		end

		if self.timer_secondshot and timer_global - self.timer_secondshot > self.attack_speed/2 then
			local water = Projectile_Water.new(math.floor(data[2].x + 10), math.floor(data[2].y), 550, 0, true)
			table.insert(bullets, water)
			self.timer_secondshot = nil 
			local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
			sound:play()
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
		draw_hitbox(self.data[2])
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
	rock.timer = timer_global
	rock.flash = 0
	rock.friendly = false
	rock.death_effects = {
		death_effect_points, 
		death_effect_burst, 
		death_effect_explode, 
		death_effect_shockwave,
		death_effect_sound_blockhit,
		death_effect_break,
		--death_effect_spawn_lilgabbro,
		--death_effect_spawn_heart,
	}
	rock.dead = false

	-- update function
	function rock:update(dt)
		for _, t in ipairs(self.data) do
			t.x = t.x + t.dx * dt
			t.y = t.y + t.dy * dt
			t.hitx = t.hitx + t.dx * dt
			t.hity = t.hity + t.dy * dt
			t.animation:update(dt)
		end
		if player and timer_global - self.timer > 1 then
			self.timer = timer_global
			local chance = math.random(1, 100)
			if chance < 15 then
				local pdx, pdy = get_vector(self.data[1], player.data[2], 200, true)
				red_orb_shot(self.data[1].x + self.data[1].hitw / 2, self.data[1].y + self.data[1].hith / 2, pdx, pdy, false)
			end
		end
		-- controls white shader effect on hit
		if self.flash and self.flash > 0 then
			self.flash = self.flash - (1 * dt)
		end

		-- enemy death scenarios
		if self.health <= 0 then
			self.trigger_death_effects()
			self.increment_counter()
			self.dead = true
		end

		local x1, x2, y1, y2 = get_game_boundaries()
		if self.data[1].x < x1 - 100 or self.data[1].x > x2 + 100 or self.data[1].y < y1 - 100 or self.data[1].y > y2 + 100 then
			self.dead = true
		end
	end

	function rock:trigger_death_effects()
		if self.death_effects then
			for _, effect in ipairs(self.death_effects) do
				effect(self, false)
			end
		end
	end

	-- increment statistics
	function rock:increment_counter()
		enemy_killed_count = enemy_killed_count + 1
		enemy_gross_killed_count = enemy_gross_killed_count + 1
	end

	return rock
end



local Enemy_Gross = {}
Enemy_Gross.__index = Enemy_Gross

setmetatable(Enemy_Gross, {__index = MoveableObject})

function Enemy_Gross.new(x, y, dx, dy, flags)
	local flags = flags or {}
	local self = MoveableObject.new(x, y, dx, dy, hitx, hity, hitw, hith, flags)
	setmetatable(self, Enemy_Gross)
	self.dx = dx or game_dx
	self.dy = dy or game_dy
	self.hitx = x
	self.hity = y
	self.hitw = 23
	self.hith = 35
	self.sheet = entity_gross_guy_sheet
	self.animation = create_animation(self.sheet, 23, 35, '1-5', 0.1)
	self.friendly = false
	self.health = 2
	self.points = 50
	self.id = "gross_guy"

	-- unique
	self.copies = flags.copies or 5
	self.copying = flags.copying or true
	self.switched = false

	self.death_effects = {
		death_effect_points, 
		death_effect_burst, 
		death_effect_explode, 
		death_effect_shockwave,
		death_effect_sound_blockhit,
		death_effect_break,
	}

	return self
end

function Enemy_Gross:update(dt)
	MoveableObject.update(self, dt)
	if self.copying and self.copies > 1 and (self.x < 925 and self.x > 800) then
		copy = Enemy_Gross.new(game_width + 20, self.y, self.dx, self.dy, {copies = self.copies - 1})
		self.copying = false
		table.insert(enemies, copy)
	end
	if self.x < 100 and not self.switched and self.y < game_height / 2 then
		self.switched = true
		self.dx = -self.dx * 0.707
		self.dy = self.dx
	elseif self.x < 100 and not self.switched and self.y >= game_height / 2 then
		self.switched = true
		self.dx = -self.dx * 0.707
		self.dy = -self.dx
	end
end

function Enemy_Gross:increment_counter()
	enemy_killed_count = enemy_killed_count + 1
	enemy_gross_killed_count = enemy_gross_killed_count + 1
end

local Enemy_Drang = {}
Enemy_Drang.__index = Enemy_Drang

setmetatable(Enemy_Drang, {__index = MoveableObject})

function Enemy_Drang.new(x, y, dx, dy, flags)
	local flags = flags or {}
	local self = MoveableObject.new(x, y, dx, dy)
	setmetatable(self, Enemy_Drang)
	self.hitx = x
	self.hity = y
	self.dx = dx or game_dx
	self.dy = dy or game_dy
	self.hitw = 36
	self.hith = 40
	self.sheet = entity_drang1_sheet
	self.animation = create_animation(self.sheet, 36, 40, '1-5', 0.1)
	self.friendly = false
	self.health = 3
	self.points = 150
	self.id = "forked_drang"
	self.chance_100_heart = true

	self.death_effects = {
		death_effect_points, 
		death_effect_burst, 
		death_effect_explode, 
		death_effect_shockwave,
		death_effect_sound_blockhit,
		death_effect_break,
		death_effect_spawn_heart,
	}

	return self
end

function Enemy_Drang:update(dt)
	if math.sin(timer_global * 10) < 0 then
		self.dy = -50 + game_dy
	else
		self.dy = 50 + game_dy
	end
	MoveableObject.update(self, dt)
end

function Enemy_Drang:increment_counter()
	enemy_killed_count = enemy_killed_count + 1
	enemy_drang_killed_count = enemy_drang_killed_count + 1
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
	self.dx = 500
	self.sheet = entity_water_drop_sheet
	self.animation = create_animation(self.sheet, 20, 21, '1-4', 0.1)
	self.friendly = friendly
	self.id = "water_drop"
	self.health = 1
	return self
end

function create_projectile_red_orb(posx, posy, deltax, deltay, friendly)
	local data = {
		{
			x = posx,
			y = posy,
			dx = deltax,
			dy = deltay,
			hitx = posx,
			hity = posy,
			hitw = 43,
			hith = 30,
			sheet = entity_damage_orb_sheet,
			animation = create_animation(entity_damage_orb_sheet, 14, 14, '1-5', 0.05)
		},
	}

	local orb = Entity.new(data)
	orb.id = "damage_orb"
	orb.health = 1
	orb.friendly = false

	function orb:update(dt)
		for _, data in ipairs(self.data) do
			data.x = data.x + data.dx * dt
			data.y = data.y + data.dy * dt
			data.hitx = data.hitx + data.dx * dt
			data.hity = data.hity + data.dy * dt
			data.animation:update(dt)
		end
	end

	return orb
end

local Powerup_Lil_Gabbro = {}
Powerup_Lil_Gabbro.__index = Powerup_Lil_Gabbro

setmetatable(Powerup_Lil_Gabbro, {__index = MoveableObject})

function Powerup_Lil_Gabbro.new(x, y, dx, dy)
	local self = MoveableObject.new(x, y, dx, dy)
	setmetatable(self, Powerup_Lil_Gabbro)
	self.hitx = x
	self.hity = y
	self.hitw = 17
	self.hith = 15
	self.dx = dx
	self.dy = dy
	self.sheet = pickup_lilgabbron_sheet
	self.animation = create_animation(self.sheet, 17, 15, '1-2', 0.1)
	self.id = "powerup_lil_gabbro"
	self.points = 1000
	self.sound = love.audio.newSource("sounds/powerup_super.wav", "static")
	self.timer = timer_global
	self.seed = math.random(-3.14, 3.14)
	return self
end

function Powerup_Lil_Gabbro:update(dt)
	if player and timer_global - self.timer < 1 then
		self.dx, self.dy = get_vector(self, player, 1, false)
	else
		self.dx = math.sin(timer_global / 2 + self.seed) * 200 + (game_dx / 2)
		self.dy = math.sin(timer_global + self.seed) * 100
	end
	
	
	self.x = (self.x + self.dx * dt)
	self.y = (self.y + self.dy * dt)

	self.hitx = self.hitx + self.dx * dt
	self.hity = self.hity + self.dy * dt
	self.animation:update(dt)
end

function Powerup_Lil_Gabbro:effect(dt)
	effect_shockwave(self.x + (self.hith / 2), self.y + self.hitw / 2, self.dx / 2, self.dy / 2)
	effect_points(self.x + self.hith / 2, self.y + self.hitw / 2, self.dx / 2, self.dy / 2, self.points)
	effect_message(self.x + self.hith / 2, self.y + self.hitw / 2, self.dx / 2 + math.random(-50, 50), self.dy / 2 + math.random(-50, 50), "Nice!")
	self.sound:play()
end

local Powerup_Heart = {}
Powerup_Heart.__index = Powerup_Heart

setmetatable(Powerup_Heart, {__index = MoveableObject})

function Powerup_Heart.new(x, y, dx, dy)
	local self = MoveableObject.new(x, y, dx, dy)
	setmetatable(self, Powerup_Heart)
	self.hitx = x
	self.hity = y
	self.hitw = 26
	self.hith = 26
	self.dx = dx or game_dx / 2
	self.dy = dy
	self.sheet = pickup_cheese_sheet
	self.animation = create_animation(self.sheet, 26, 26, '1-1', 100)
	self.id = "powerup_heart"
	self.points = 250
	self.sound = love.audio.newSource("sounds/ploop.wav", "static")
	self.seed = math.random(-3.14, 3.14)
	return self
end

function Powerup_Heart:update(dt)
	self.dy = math.sin(timer_global + self.seed) * 100
	self.x = (self.x + self.dx * dt)
	self.y = (self.y + self.dy * dt)

	self.hitx = self.hitx + self.dx * dt
	self.hity = self.hity + self.dy * dt
	self.animation:update(dt)
end

function Powerup_Heart:effect(dt)
	if player.health < player.max_health then
		player.health = player.health + 1
		effect_shockwave(ui_hearts_x + (7 * (player.health - 1)), ui_hearts_y + 7, 0, 0, 20, 400)
	end
	effect_message(self.x + self.hith / 2, self.y + self.hitw / 2, self.dx / 2 + math.random(-50, 50), self.dy / 2 + math.random(-50, 50), "Health up!")
	effect_shockwave(self.x + (self.hith / 2), self.y + self.hitw / 2, self.dx / 2, self.dy / 2)
	effect_points(self.x + self.hith / 2, self.y + self.hitw / 2, self.dx / 2, self.dy / 2, self.points)
	
	self.sound:play()
end


--  ___  ____  ____  ___  ____    __    __   
-- / __)(  _ \( ___)/ __)(_  _)  /__\  (  )  
-- \__ \ )___/ )__)( (__  _)(_  /(__)\  )(__ 
-- (___/(__)  (____)\___)(____)(__)(__)(____)

-- USED TO ALTERNATE COLORS FOR TEXT OR OTHER SHIT
-- WARNING: THIS DOESN'T START THE BLINK TIMER
function blink(colors)
	if not colors then
		return {255, 255, 255}
	end
	if timer_blink > #colors + 1 then
		timer_blink = 1
	end
	local i = math.floor(timer_blink)
	return colors[i]
end

function set_draw_color(num)
	local r, g, b = love.math.colorFromBytes(colors_DB32[num][1], colors_DB32[num][2], colors_DB32[num][3])
	love.graphics.setColor(r, g, b)
end

function spawn_enemy(enemy, x, y, dx, dy, flags)

	local e = enemy.new(x, y, gdx, gdy, flags)
	local fucked = false
	for i = #enemies, 1, -1 do
		if get_collision(e, enemies[i]) then
			fucked = true
			return
		end
	end

	if fucked then logstring = logstring .. "fucked" end
	table.insert(enemies, e)
end

function spawn_powerup(powerup, x, y, dx, dy, flags)
	flags = flags or {}
	local e = powerup.new(x, y, dx, dy, flags.points)
	table.insert(powerups, e)
end

--  ____  ____  ____  ____  ___  ____  ___ 
-- ( ___)( ___)( ___)( ___)/ __)(_  _)/ __)
--  )__)  )__)  )__)  )__)( (__   )(  \__ \
-- (____)(__)  (__)  (____)\___) (__) (___/

function effect_points(x, y, dx, dy, points, apply)
	local a = true
	if apply == false then
		a = false
	end
	local pp = Particle.new(x, y, dx, dy, 3, points)
	pp.timer = pp.timer - pp.lifetime
	pp.id = "effect_message"
	if a then
		score = score + points 
	end
	function pp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
	end
	table.insert(particles, pp)
end

-- function create_text(x, y, dx, dy, text, delay)
-- 	local msg = ParticleObject.new(x, y, dx, dy, "display_text")
-- 	msg.color = 22
-- 	msg.obj = love.graphics.newText(font_gamer_med, text)
-- 	if delay then
-- 		msg.timer = msg.timer + delay
-- 	end

-- 	return msg
-- end

function effect_message(x, y, dx, dy, text, lifetime)
	local msg = Particle.new(x, y, dx, dy, lifetime, text)
	msg.timer = msg.timer - lifetime
	msg.id = "effect_message"
	function msg:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
	end
	table.insert(particles, msg)
end

function effect_shockwave(x, y, dx, dy, r, dr, da)
	local myp = Particle.new(x, y, dx, dy, 1, nil)
	myp.data = math.random() * 0.25
	myp.id = "effect_shockwave"
	myp.r = r or 1
	myp.alpha = 1
	myp.dr = dr or 250--* math.random() * 1.5
	local da = da or 1
	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		self.r = (self.r + self.dr * dt)
		local decrease_rate = 3.5
		local decrease_per_frame = decrease_rate / love.timer.getFPS()
		self.dr = self.dr * (1 - decrease_per_frame)
		self.alpha = self.alpha - da * dt
	end
	myp.timer = myp.timer - myp.lifetime
	for i = 1, 3 do
		table.insert(explosions, myp)
	end
end

function effect_break(x, y, dx, dy)
	local myp = Particle.new(x, y, dx, dy, 1, nil)
	myp.data = math.random() * 0.25
	myp.id = "effect_break"
	myp.dx = dx or math.random(-300, 300)
	myp.dy = dy or math.random(-300, 300)
	myp.r = 1
	myp.timer = myp.timer + myp.data - 1.5
	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		local decrease_rate = 2.5
		local decrease_per_frame = decrease_rate / love.timer.getFPS()
		self.dx = self.dx * (1 - decrease_per_frame)
		self.dy = self.dy * (1 - decrease_per_frame)

	end
	table.insert(explosions, myp)
end

function effect_burst(x, y, dx, dy, r, dr)
	local myp = Particle.new(x, y, dx, dy, 0, nil)
	myp.id = "effect_burst"
	myp.r = r or 30
	myp.dr = dr or 200
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
	end
	table.insert(explosions, myp)
end

-- MAKES AN EXPLOSION AT A COORDINATE
function effect_explode(x, y, dx, dy)
	local myp = Particle.new(x, y, dx, dy, 2, nil)
	myp.data = math.random() * 0.25
	myp.id = "effect_explosion"
	myp.r = math.floor(math.random(4, 8))
	myp.timer = myp.timer - myp.lifetime + myp.data

	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		local decrease_rate = 2.5
		local decrease_per_frame = decrease_rate / love.timer.getFPS()
		self.r = self.r - 4 * dt
		if self.r < 0 then
			self.r = 0
		end
		self.dx = self.dx * (1 - decrease_per_frame)
		self.dy = self.dy * (1 - decrease_per_frame)

	end
	table.insert(particles, myp)
end

function effect_starfield(x, y, w, h)
	for i = 1, (w / 6) + (h / 6) do
		star = Particle.new(math.random(x, w), math.random(y, h), math.random(0, game_dx), math.random(0, game_dy), nil, nil)
		star.id = "starfield_star"
		star.sheet = particle_star_sheet
		star.animation = create_animation(particle_star_sheet, 4, 7, '1-4', 0.1)
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

		for p  = 1, 50 do
			effect_explode(pointX, pointY, math.random(-150, 150) + obj.dx, math.random(-150, 150) + obj.dy)
		end
	else
		print(entity)
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			for p  = 1, 50 do
				effect_explode(pointX, pointY, math.random(-150, 150) + obj.dx, math.random(-150, 150) + obj.dy)
			end
		end
	end
	
end

function death_effect_shockwave(entity, only_on_master)
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		effect_shockwave(pointX, pointY, obj.dx / 2, obj.dy / 2)
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			effect_shockwave(pointX, pointY, obj.dx / 2, obj.dy / 2)
		end
	end
	
end

function death_effect_burst(entity, only_on_master)
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		effect_burst(pointX, pointY, obj.dx * 0.75, obj.dy * 0.75, 50)
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			effect_burst(pointX, pointY, obj.dx * 0.75, obj.dy * 0.75, 50)
		end
	end
	
end

function death_effect_break(entity, only_on_master)
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		for i = 1, 50 do
			effect_break(pointX, pointY, obj.dx + math.random(-300, 300), obj.dy + math.random(-300, 300))
		end
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			for i = 1, 50 do
				effect_break(pointX, pointY, obj.dx + math.random(-300, 300), obj.dy + math.random(-300, 300))
			end
		end
	end
	
end

function death_effect_sound_blockhit(entity, only_on_master)
	local sound = love.audio.newSource("sounds/block_hit.wav", 'static')
	sound:play()
end

function death_effect_spawn_lilgabbro(entity, only_on_master)
	local sound = love.audio.newSource("sounds/poink.wav", "static")
	if only_on_master then
		local obj = get_master_obj(entity)
		local pointX = obj.x + obj.hitw/2
		local pointY = obj.y + obj.hith/2

		local value = math.random(1, 100)
		if value < 25 then
			spawn_powerup(Powerup_Lil_Gabbro, pointX, pointY)
			sound:play()
		end
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			local value = math.random(1, 100)
			if value < 25 then
				spawn_powerup(Powerup_Lil_Gabbro, pointX, pointY)
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
		if obj.chance_100_heart then
			value = 1
		end
		if value < 5 then
			spawn_powerup(Powerup_Heart, pointX, pointY)
			sound:play()
		end
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2

			local value = math.random(1, 100)
			if obj.chance_100_heart then
				value = 1
			end
			if value < 5 then
				spawn_powerup(Powerup_Heart, pointX, pointY)
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
		local points = obj.points
		effect_points(pointX, pointY, enemy.dx / 2.5 + math.random(-50, 50), math.random(-50, 50), points, apply)
	else
		for _, obj in ipairs(entity.data) do
			local pointX = obj.x + obj.hitw/2
			local pointY = obj.y + obj.hith/2
			local points = obj.points
			effect_points(pointX, pointY, enemy.dx / 2.5 + math.random(-50, 50), math.random(-50, 50), points, apply)
		end
	end
	
	
	
end





--  ___  _   _  _____  ____  ___ 
-- / __)( )_( )(  _  )(_  _)/ __)
-- \__ \ ) _ (  )(_)(   )(  \__ \
-- (___/(_) (_)(_____) (__) (___/

function single_water_shot(x, y, dx, dy, friendly)
	local water = Projectile_Water.new(x, y, dx, dy, friendly)
	
	--timer_secondshot = timer_global
	local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
	sound:play()
	
	table.insert(bullets, water)
	
end

function double_water_shot(x, y, dx, dy, friendly)
	--21
	local water1 = Projectile_Water.new(x, y + 21/2, dx, dy, friendly)
	local water2 = Projectile_Water.new(x, y - 21/2, dx, dy, friendly)
	local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
	sound:play()
	
	table.insert(bullets, water1)
	table.insert(bullets, water2)
	

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
	mode = 'start'

	-- timers
	-- - make sure to set timer to nill after using
	timer_blink = 1
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

	for i = 1, #player_letters do
		if player_letters[i] == 1 then
			create_letter(player_letters[i], startX, math.random(minY, maxY), height - 30)
		else
			create_letter(player_letters[i], startX, math.random(minY, maxY), height)
		end
		startX = startX + 3 + letters_title[player_letters[i]][2]
	end

	startX = 50
	minY = 150
	maxY = 200

	for i = 1, #retribution_letters do
		if retribution_letters[i] == 1 then
			create_letter(retribution_letters[i], startX, math.random(minY, maxY), height - 30 + 100)
		else
			create_letter(retribution_letters[i], startX, math.random(minY, maxY), height + 100)
		end
		startX = startX + 3 + letters_title[retribution_letters[i]][2]
	end
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
		table.insert(hearts, Graphic_Heart.new(ui_hearts_x + (12 * (i - 1)), ui_hearts_y, 0, 0))
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

function load_stars()
	-- stars
	for i = 1, 300 do
		star = MoveableObject.new(math.random(1, game_width), math.random(1, game_height), math.random() * game_dx, math.random() * game_dy)
		star.sheet = particle_star_sheet
		star.animation = create_animation(star.sheet, 4, 7, '1-4', 0.1)
		star.looping = true
		table.insert(background, star)
	end
end

function reset_game()
	-- init variables
	bullets = {}
	background = {}
	enemies = {}
	explosions = {}
	particles = {}
	powerups = {}
	ui = {}

	-- ui
	score = 0
	load_player()
	load_ui()
	level = 1

	-- these are the controllers for every moving object
	-- everything which moves along the screen should reference these variables
	game_dx = -150
	game_dy = 0

	game_difficulty_factor = 1

	sound_slash = love.audio.newSource("sounds/slash.wav", 'static')
	shot_circ_r = 0
	shot_circ_x = 0
	shot_circ_y = 0

	timer_blink = 1
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
		local enemy = enemies[i]
		enemy:update(dt)
		if enemy.dead then
			table.remove(enemies, i)
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

function update_bullets(dt)
	for i = #bullets, 1, -1 do
		local bullet = bullets[i]
		bullet:update(dt)
		local bullet_left_game_area = false
		local bullet_dead = false
		for _, data in ipairs(bullets[i].data) do
			local bullet_left_game_area = (data.x > (window_width / window_scale) + 200 or data.x < -200) or (data.y > (window_height / window_scale) + 200 or data.y < -200)
			local bullet_dead = bullet.health and bullet.health <= 0
			if bullet_left_game_area or bullet_dead then
				table.remove(bullets, i)
			end
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

function update_explosions(dt)
	for i = #explosions, 1, -1 do
		local explosion = explosions[i]
		explosion:update(dt)
		if explosion.r <= 0 or timer_global - explosion.timer > 0 then
			table.remove(explosions, i)
		end
	end
end

function update_powerups(dt)
	for i = #powerups, 1, -1 do
		local powerup = powerups[i]
		local powerup_left_game_area = (powerup.x > (game_width) + 200 or powerup.x < -200) or (powerup.y > (game_height) + 200 or powerup.y < -200)
		powerup:update(dt)
		if powerup_left_game_area then
			table.remove(powerups, i)
		end
	end
end

function update_particles(dt)
	for i = #particles, 1, -1 do
		print(particles[i].id)
		local particle = particles[i]
		particle:update(dt)
		local particle_left_game_area = (particle.x > (game_width) + 200 or particle.x < -200) or (particle.y > (game_height) + 200 or particle.y < -200)
		if (timer_global - particle.timer > 2 + particle.data) or particle_left_game_area then
			table.remove(particles, i)
		end
	end
end

function update_player(dt)
	if not player then
		return
	end
	print(player)
	for _, obj in ipairs(player.data) do
		control(obj, 250, "a", "d", "w", "s")
	end
	player:update(dt)
	player:shoot(dt)
	
end


function game_rules(dt)
	-- get coordinates of possible enemy spawn
	-- do for loop through enemies
	-- if coordinates collide with another enemy, don't spawn
	-- - instead, add to queue and continually spawn those from the queue when able
	x = game_width + 2
	y = math.random(2, game_height - 50)

	

	-- enemy spawning difficulty measuring
	if timer_global - timer_enemy_spawner > game_difficulty_factor then
		if game_difficulty_factor > 0.25 then
			game_difficulty_factor = game_difficulty_factor - 0.0025
		end
		local chance = math.random(0, 100)
		if chance > 25 then
			--spawn_enemy(Enemy_Rock, x, y)
			local rock = create_enemy_rock(x, y, game_dx, game_dy)
			table.insert(enemies, rock)
		else
			--spawn_enemy(Enemy_Gross, x, y)
		end
		if chance < 5 * game_difficulty_factor then
			--spawn_enemy(Enemy_Drang, x, y)
		end
		timer_enemy_spawner = timer_global
	end
	if timer_global > 300 and game_difficulty_factor > 0.1 and timer_global - timer_game_speed > 1 then
		game_difficulty_factor = game_difficulty_factor - 0.001
	end
	if timer_global - timer_game_speed > 1 then
		game_dx = game_dx - 0.25
		timer_game_speed = timer_global
	end
end



function update_game(dt)
	logstring = ""
	load_ui() -- probably shouldn't have this here, but right now it's fine
	if timer_levelselect_delay and timer_global - timer_levelselect_delay > 3 then
		timer_levelselect_delay = nil
	end

	if player and player.health <= 0 then
		mode = 'gameover'
	end

	if love.keyboard.isDown('r') then
		mode = 'start'
	end
	if timer_global > 32000 then
		timer_global = 1
	end

	-- local temp_counter = 0
	-- for _, dude in ipairs(enemies) do
	-- 	temp_counter = temp_counter + 1
	-- end
	-- logstring = logstring .. temp_counter


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
	for i = #enemies, 1, -1 do -- friendly bullet collide with enemy
		for _, data in ipairs(enemies[i].data) do
			for p = #bullets, 1, -1 do
				if bullets[p].friendly and not enemies[i].friendly and get_collision(data, bullets[p]) then
					enemies[i].health = enemies[i].health - 1
					bullets[p].health = bullets[p].health - 1

					local sound = love.audio.newSource("sounds/deep_hit.wav", 'static')
					sound:play()
					effect_shockwave(bullets[p].x + bullets[p].hitw/2, bullets[p].y + bullets[p].hith/2, bullets[p].dx * 0.05, bullets[p].dy * 0.05, 1, 50)
					for fewji = 1, 3 do
						effect_break(data.x + data.hitw / 2, data.y + data.hith / 2)
					end
					enemies[i].flash = 0.05
				end
			end
		end
	end

	

	if not player then
		--logstring = logstring .. "hi"
		return
	end

	

	for i = 1, #enemies do -- enemy collide with player
		for _, obj in ipairs(enemies[i].data) do
			if not enemies[i].friendly and get_collision(player.data[2], obj) then
				if not player.timer_invulnerable then
					sound_slash:play()
					enemies[i].health = enemies[i].health - 1
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
	for i = 1, #bullets do -- enemy bullet collide with player
		print(bullets[i].id)
		for _, obj in ipairs(bullets[i].data) do
			if not bullets[i].friendly and get_collision(player.data[2], obj) then
				if not timer_invulnerable then
					sound_slash:play()
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
		local powerup = powerups[i]
		if get_collision(player, powerup) then
			powerup:effect(dt)

			table.remove(powerups, i)
		end
	end
	
	
	if not timer_levelselect_delay then
		game_rules(dt)
	end
	log1:log(logstring)
end

function update_start(dt)
	-- update function for start screen
	update_letters(dt)
	if love.keyboard.isDown('space') and not key_space_pressed then
		mode = 'game'
		key_space_pressed = true
		reset_game()
		if not timer_levelselect_delay then
			timer_levelselect_delay = timer_global
		end
	end
end

function update_gameover(dt)
	-- update function for gameover screen
	if love.keyboard.isDown('space') and not key_space_pressed then
		mode = 'start'
		key_space_pressed = true
	end
end

function update_credits(dt)
	if love.keyboard.isDown('space') and not key_space_pressed then
		mode = 'start'
		key_space_pressed = true
	end
end

function love.update(dt)
	timer_global = timer_global + (1 * dt)
	timer_blink = timer_blink + (1 * dt) * 10
	if mode == 'game' then
		update_game(dt)
	elseif mode == 'start' then
		update_start(dt)
	elseif mode == 'gameover' then
		timer_blink = timer_blink + (1 * dt) * 15
		update_game(dt)
		update_gameover(dt)
	elseif mode == 'results' then

	elseif mode == 'credits' then
		update_credits(dt)
		
	elseif mode == 'levelscreen' then
		update_levelscreen(dt)
	end
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
		for _, data in ipairs(enemies[i].data) do
			draw_hitbox(data)
		end
		local enemy = enemies[i]
		-- draw white shader effect when hit
		if enemy.flash and enemy.flash > 0 then
			love.graphics.setShader(shader_flash)
		end
		for _, data in ipairs(enemies[i].data) do
			data.animation:draw(data.sheet, math.floor(data.x), math.floor(data.y))
		end
		
		love.graphics.setShader()
	end
end

function draw_hearts()
	for i = 1, #hearts do
		local heart = hearts[i]
		heart.animation:draw(heart.sheet, math.floor(heart.x), math.floor(heart.y))
	end
end

function draw_bullets()
	for i = 1, #bullets do
		for _, data in ipairs(bullets[i].data) do
			data.animation:draw(data.sheet, math.floor(data.x), math.floor(data.y))
		end
	end
end

function draw_powerups()
	for i = 1, #powerups do
		local powerup = powerups[i]
		powerup.animation:draw(powerup.sheet, math.floor(powerup.x), math.floor(powerup.y))
	end
end

function draw_explosions()
	for i = 1, #explosions do
		local explosion = explosions[i]
		if explosion.id == "effect_burst" then
			if math.sin(timer_global * 50) < 0.33 then
				set_draw_color(22)
			elseif math.sin(timer_global * 50) > -0.1 then
				set_draw_color(6)
			else
				set_draw_color(28)
			end
			love.graphics.circle("fill", math.floor(explosion.x), math.floor(explosion.y), math.floor(explosion.r))
		elseif explosion.id == "effect_shockwave" then
			love.graphics.setColor(1, 1, 1, explosion.alpha)
			love.graphics.circle('line', math.floor(explosion.x), math.floor(explosion.y), explosion.r)
			
		elseif explosion.id == "effect_break" then
			set_draw_color(22)
			love.graphics.circle('fill', math.floor(explosion.x), math.floor(explosion.y), explosion.r)
		end
	end
	set_draw_color(22)
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
		local particle = particles[i]
		if particle.id == "effect_points" then
			set_draw_color(blink({21, 22, 23, 20, 10, 11, 22}))
			love.graphics.print(particle.points, math.floor(particle.x), math.floor(particle.y))
			set_draw_color(22)
		elseif particle.id == "effect_explosion" then
			local time_elapsed = timer_global - particle.timer
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
			love.graphics.circle('fill', math.floor(particle.x), math.floor(particle.y), particle.r)
		end
	end
	set_draw_color(22)
end

function draw_player()
	if not player then
		return
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
	-- love.graphics.print(game_difficulty_factor, 250, 4)

	
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

function draw_levelscreen()
	set_draw_color(blink({21, 22, 23, 24}))
	love.graphics.draw(ui_label_level_num, ui_label_level_num_x, ui_label_level_num_y)
	love.graphics.draw(ui_label_level_name, ui_label_level_name_x, ui_label_level_name_y)
	set_draw_color(22)
end

function draw_gameover()
	set_draw_color(blink({9, 6, 28}))
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
	set_draw_color(blink({21, 22, 22, 22, 23, 24}))
	local text1 = "CARMINE'S RETRIBUTION"
	local text2 = "PRESS ANY KEY TO START"
	love.graphics.print(text1, center_text(text1), (game_height / 2) - 60)
	love.graphics.print(text2, center_text(text2), (game_height / 2 ) - 40)
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
		log1:draw(0, 0)
	push:finish()
end






function love.keyreleased(key)
	if key == 'space' then
		key_space_pressed = false
	end
end