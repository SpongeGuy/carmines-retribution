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
	{"sprites/letters/'.png", 10, 17}, 		-- 1
	{"sprites/letters/a.png", 33, 38}, 		-- 2
	{"sprites/letters/b.png", 32, 40}, 		-- 3
	{"sprites/letters/e.png", 36, 42},		-- 4
	{"sprites/letters/i.png", 9, 39},		-- 5
	{"sprites/letters/m.png", 44, 34},		-- 6
	{"sprites/letters/n.png", 32, 41},		-- 7
	{"sprites/letters/o.png", 33, 41},		-- 8
	{"sprites/letters/r.png", 25, 40},		-- 9 
	{"sprites/letters/s.png", 39, 40},		-- 10
	{"sprites/letters/t.png", 26, 41},		-- 11
	{"sprites/letters/u.png", 29, 38},		-- 12
	{"sprites/letters/big_c.png", 48, 48},	-- 13
	{"sprites/letters/big_r.png", 61, 68},	-- 14

}


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

function initialize_animation(sheet, frame_width, frame_height, frames, duration)
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

	local dx = obj2.x - obj1.x
	local dy = obj2.y - obj1.y

	if norm then
		local magnitude = math.sqrt(dx * dx + dy * dy)

		dx = dx / magnitude
		dy = dy / magnitude
	end

	return dx * multiplier, dy * multiplier
end

function load_image(path)
	local info = love.filesystem.getInfo(path)
	if info then
		return love.graphics.newImage(path)
	end
	print("Couldn't grab image from " .. path)
end










 
--  _____  ____   ____  ____  ___  ____  ___ 
-- (  _  )(  _ \ (_  _)( ___)/ __)(_  _)/ __)
--  )(_)(  ) _ <.-_)(   )__)( (__   )(  \__ \
-- (_____)(____/\____) (____)\___) (__) (___/

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
	love.graphics.rectangle('line', obj.hitx, obj.hity, obj.hitw, obj.hith)
end

function control(obj, speed, left, right, up, down)
	if obj.health <= 0 then
		obj.dx = 0
		obj.dy = 0
		return
	end
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
	if not (obj.dx == 0 and obj.dy == 0) then
		obj.dx = obj.dx * 0.707
		obj.dy = obj.dy * 0.707
	end
	obj.dx = obj.dx * 1.2
	obj.dy = obj.dy * 1.2
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
	self.sheet = load_image("sprites/heart/heart_alt_sheet.png")
	self.animation = initialize_animation(self.sheet, 11, 11, '1-2', 100)
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

local Player = {}
Player.__index = Player

setmetatable(Player, {__index = MoveableObject})

function Player.new(x, y, dx, dy, hitx, hity, hitw, hith, flags)
	local self = MoveableObject.new(x, y, dx, dy, hitx, hity, hitw, hith, flags)
	setmetatable(self, Player)
	self.texture_height = hith or 0
	self.texture_width = hitw or 0
	self.friendly = true
	self.id = "player"
	self.health = 3
	return self
end

function Player:shoot()
	
end

local Enemy_Rock = {}
Enemy_Rock.__index = Enemy_Rock

setmetatable(Enemy_Rock, {__index = MoveableObject})

function Enemy_Rock.new(x, y, dx, dy, flags)
	local flags = flags or {}
	local self = MoveableObject.new(x, y, dx, dy, hitx, hity, hitw, hith, flags)
	setmetatable(self, Enemy_Rock)
	self.hitx = x
	self.hity = y
	self.dx = dx or game_dx * 0.75
	self.dy = dy or game_dy * 0.75
	self.hitw = 43
	self.hith = 30
	self.sheet = load_image("sprites/rocks/rock1-sheet.png")
	self.animation = initialize_animation(self.sheet, 43, 30, '1-5', 0.1)
	self.friendly = false
	self.health = 5
	self.points = 100
	self.id = "evil_rock"
	self.timer = timer_global

	self.death_effects = {
		death_effect_points, 
		death_effect_burst, 
		death_effect_explode, 
		death_effect_shockwave,
		death_effect_sound_blockhit,
		death_effect_break,
		death_effect_spawn_lilgabbro,
		death_effect_spawn_heart,
	}
	
	return self
end

function Enemy_Rock:update(dt)
	MoveableObject.update(self, dt)
	if player and timer_global - self.timer > 1 then
		self.timer = timer_global
		local chance = math.random(1, 100)
		if chance < 15 then
			local pdx, pdy = get_vector(self, player, 200, true)
			red_orb_shot(self.x + self.hitw / 2, self.y + self.hith / 2, pdx, pdy, false)
		end
	end
end

function Enemy_Rock:increment_counter()
	enemy_killed_count = enemy_killed_count + 1
	enemy_rock_killed_count = enemy_rock_killed_count + 1
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
	self.sheet = load_image("sprites/gross_guy_sheet.png")
	self.animation = initialize_animation(self.sheet, 23, 35, '1-5', 0.1)
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
	self.sheet = load_image("sprites/drang/drang1-sheet.png")
	self.animation = initialize_animation(self.sheet, 36, 40, '1-5', 0.1)
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
	self.sheet = load_image("sprites/water_drop/water_drop_sheet.png")
	self.animation = initialize_animation(self.sheet, 20, 21, '1-4', 0.1)
	self.friendly = friendly
	self.id = "water_drop"
	self.health = 1
	return self
end

local Projectile_Red_Orb = {}
Projectile_Red_Orb.__index = Projectile_Red_Orb

setmetatable(Projectile_Red_Orb, {__index = MoveableObject})

function Projectile_Red_Orb.new(x, y, dx, dy, friendly)
	local self = MoveableObject.new(x, y, dx, dy)
	self.hitx = x
	self.hity = y
	self.hitw = 14
	self.hith = 14
	self.sheet = load_image("sprites/damage_orb/damage_orb-sheet.png")
	self.animation = initialize_animation(self.sheet, 14, 14, '1-5', 0.05)
	self.friendly = friendly
	self.id = "damage_orb"
	self.health = 1
	return self
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
	self.sheet = load_image("sprites/pickups/lil_gabbron-sheet.png")
	self.animation = initialize_animation(self.sheet, 17, 15, '1-2', 0.1)
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
	self.sheet = load_image("sprites/pickups/smol_cheese.png")
	self.animation = initialize_animation(self.sheet, 26, 26, '1-1', 100)
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
	local pp = ParticleObject.new(x, y, dx, dy, "effect_points")
	pp.points = points
	pp.timer = pp.timer + 0.5
	if a then 
		score = score + points 
	end
	table.insert(particles, pp)
end

function create_text(x, y, dx, dy, text, delay)
	local msg = ParticleObject.new(x, y, dx, dy, "display_text")
	msg.color = 22
	msg.obj = love.graphics.newText(font_gamer_med, text)
	if delay then
		msg.timer = msg.timer + delay
	end

	return msg
end

function effect_message(x, y, dx, dy, text, delay)

	local msg = ParticleObject.new(x, y, dx, dy, "effect_points")
	msg.points = text
	msg.timer = msg.timer + 0.5
	if delay then
		msg.timer = msg.timer + delay
	end
	
	table.insert(particles, msg)
end

function effect_shockwave(x, y, dx, dy, r, dr, da)
	local myp = ParticleObject.new(x, y, dx, dy, "effect_shockwave")
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
	myp.timer = myp.timer + myp.seed - 0.5
	for i = 1, 3 do
		table.insert(explosions, myp)
	end
end

function effect_break(x, y, dx, dy)
	local myp = ParticleObject.new(x, y, dx, dy, "effect_break")
	myp.dx = dx or math.random(-300, 300)
	myp.dy = dy or math.random(-300, 300)
	myp.r = 1
	myp.timer = myp.timer + myp.seed - 1.5
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
	local myp = ParticleObject.new(x, y, dx, dy, "effect_burst")
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
	local myp = ParticleObject.new(x, y, dx, dy, "effect_explosion")
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
	myp.r = math.floor(math.random(4, 8))
	myp.timer = myp.timer + myp.seed
	table.insert(particles, myp)
end

function effect_starfield(x, y, w, h)
	for i = 1, (w / 6) + (h / 6) do
		star = ParticleObject.new(math.random(x, w), math.random(y, h), math.random(0, game_dx), math.random(0, game_dy), "starfield_star")
		star.sheet = load_image("sprites/stars/star1_sheet.png")
		star.animation = initialize_animation(star.sheet, 4, 7, '1-4', 0.1)
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



function death_effect_explode(enemy)
	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2

	for p  = 1, 50 do
		effect_explode(pointX, pointY, math.random(-150, 150) + enemy.dx, math.random(-150, 150) + enemy.dy)
	end
end

function death_effect_shockwave(enemy)
	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2

	effect_shockwave(pointX, pointY, enemy.dx / 2, enemy.dy / 2)
end

function death_effect_burst(enemy)
	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2

	effect_burst(pointX, pointY, enemy.dx * 0.75, enemy.dy * 0.75, 50)
end

function death_effect_break(enemy)
	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2

	for i = 1, 50 do
		effect_break(pointX, pointY, enemy.dx + math.random(-300, 300), enemy.dy + math.random(-300, 300))
	end
end

function death_effect_sound_blockhit(enemy)
	local sound = love.audio.newSource("sounds/block_hit.wav", 'static')
	sound:play()
end

function death_effect_spawn_lilgabbro(enemy)
	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2

	local value = math.random(1, 100)
	if value < 25 then
		spawn_powerup(Powerup_Lil_Gabbro, pointX, pointY)
		local sound = love.audio.newSource("sounds/poink.wav", "static")
		sound:play()
	end
end

function death_effect_spawn_heart(enemy)
	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2

	local value = math.random(1, 100)
	if enemy.chance_100_heart then
		value = 1
	end
	if value < 5 then
		spawn_powerup(Powerup_Heart, pointX, pointY)
		local sound = love.audio.newSource("sounds/poink.wav", "static")
		sound:play()
	end
end

function death_effect_points(enemy, apply)
	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2
	local points = enemy.points
	
	effect_points(pointX, pointY, enemy.dx / 2.5 + math.random(-50, 50), math.random(-50, 50), points, apply)
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
	local orb = Projectile_Red_Orb.new(x, y, dx, dy, friendly)
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
	love.window.setIcon(love.image.newImageData("sprites/carmine/carmine_icon.png"))
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
	player_max_health = 4
	player_attack_speed = 0.25


	-- player
	player = MoveableObject.new(100, 200, 0, 0, 114, 208, 14, 7)
	player.id = "player"
	player.points = 1000
	player.max_health = player_max_health
	player.health = 4
	player.attack_speed = player_attack_speed
	player.attack_type = "double_water_shot"
	player.secondshot = true
	function player:update(dt)
		MoveableObject.update(self, dt)
		-- important attributes here
		self.max_health = player_max_health
		self.attack_speed = player_attack_speed
		if player.dy < 0 then
			carmine_body_animation:gotoFrame(3)
		elseif player.dy > 0 then
			carmine_body_animation:gotoFrame(1)
		else
			carmine_body_animation:gotoFrame(2)
		end
	end
	function player:shoot(dt)
		if self.health <= 0 then
			return
		end
		-- shot effect_burst data
		shot_circ_x = player.x + 30
		shot_circ_y = player.y + 10
		if shot_circ_r > 0 then
			shot_circ_r = shot_circ_r - 180 * dt
		end
		if shot_circ_r < 0 then shot_circ_r = 0 end

		-- water drop
		if love.keyboard.isDown('space') and not timer_shot then
			shot_circ_r = 25
			timer_shot = timer_global
			key_space_pressed = true

			-- shot types / abilities ???
			if player.attack_type == "single_water_shot" then
				single_water_shot(math.floor(player.x + 10), math.floor(player.y), 550, 0, true)
			elseif player.attack_type == "double_water_shot" then
				double_water_shot(math.floor(player.x + 10), math.floor(player.y), 550, 0, true)
			end
			if player.secondshot then
				timer_secondshot = timer_global
			end


		end

		if timer_secondshot and timer_global - timer_secondshot > player.attack_speed/2 then
			local water = Projectile_Water.new(math.floor(player.x + 10), math.floor(player.y), 550, 0, true)
			table.insert(bullets, water)
			timer_secondshot = nilv 
			local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
			sound:play()
			shot_circ_r = 20
		end
	end

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
	
	function player:draw()
		if not timer_invulnerable then
			carmine_wings_left_animation:draw(carmine_wings_right_sheet, math.floor(player.x - 45), math.floor(player.y - 35))
			carmine_body_animation:draw(carmine_body_sheet, math.floor(player.x), math.floor(player.y))
			carmine_wings_right_animation:draw(carmine_wings_left_sheet, math.floor(player.x - 45), math.floor(player.y - 35))
		else
			if math.sin(timer_global * 50) < 0.5 then
				carmine_wings_left_animation:draw(carmine_wings_right_sheet, math.floor(player.x - 45), math.floor(player.y - 35))
				carmine_body_animation:draw(carmine_body_sheet, math.floor(player.x), math.floor(player.y))
				carmine_wings_right_animation:draw(carmine_wings_left_sheet, math.floor(player.x - 45), math.floor(player.y - 35))
			end
		end
	end

	
end

function load_startscreen()
	letters = {}
	function create_letter(id, x, y, bottom_y)
		local l = ParticleObject.new(x, y)
		l.id = id
		l.sheet = load_image(letters_title[id][1])
		l.animation = initialize_animation(l.sheet, letters_title[id][2], letters_title[id][3], '1-1', 1000)
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

	ui_label_angry_text = "NOT WORTHY OF CARMINE"
	ui_label_angry = love.graphics.newText(font_gamer_med, ui_label_angry_text)
	ui_label_angry_x = center_text(ui_label_angry_text)
	ui_label_angry_y = (game_height / 2) - 40
end

function load_ui()
	load_levelscreen()
	load_gameover()
	-- name
	ui_label_name = love.graphics.newText(font_gamer_med, "player")
	ui_label_name_x = 4
	ui_label_name_y = 4

	

	-- life
	ui_label_life = love.graphics.newText(font_gamer_med, "-LIFE-")
	ui_label_life_x = ui_label_name:getWidth() + 12
	ui_label_life_y = 4
	hearts = {}
	ui_hearts_x = ui_label_life_x
	ui_hearts_y = ui_label_life_y + ui_label_life:getHeight()
	ui_hearts_length = 13 * player_max_health
	for i = 1, player_max_health do
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
		star.sheet = load_image("sprites/stars/star1_sheet.png")
		star.animation = initialize_animation(star.sheet, 4, 7, '1-4', 0.1)
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
		local enemy_left_game_area = (enemy.x > (window_width / window_scale) + 200 or enemy.x < -200) or (enemy.y > (window_height / window_scale) + 200 or enemy.y < -200)
		local enemy_dead = enemy.health and enemy.health <= 0
		if enemy_dead then
			enemy:trigger_death_effects()
			enemy:increment_counter()
		end
		if enemy_left_game_area or enemy_dead then
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
		local bullet_left_game_area = (bullet.x > (window_width / window_scale) + 200 or bullet.x < -200) or (bullet.y > (window_height / window_scale) + 200 or bullet.y < -200)
		local bullet_dead = bullet.health and bullet.health <= 0
		if bullet_left_game_area or bullet_dead then
			table.remove(bullets, i)
		end
	end
end

function update_hearts(dt)
	-- my balls are in agony :((
	for i = #hearts, 1, -1 do
		hearts[i].full = false
	end
	for i = 1, player_max_health do
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
		if explosion.r <= 0 or timer_global - explosion.timer > 2 then
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
		local particle = particles[i]
		particle:update(dt)
		local particle_left_game_area = (particle.x > (game_width) + 200 or particle.x < -200) or (particle.y > (game_height) + 200 or particle.y < -200)
		if (timer_global - particle.timer > 2 + particle.seed) or particle_left_game_area then
			table.remove(particles, i)
		end
	end
end

function update_player(dt)
	if not player then
		return
	end
	if player.health <= 0 then
		death_effect_explode(player)
		death_effect_break(player)
		death_effect_shockwave(player)
		death_effect_burst(player)
		death_effect_points(player, false)
		player = nil
		return
	end
	carmine_wings_left_animation:update(dt)
	carmine_wings_right_animation:update(dt)
	control(player, 250, "a", "d", "w", "s")
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
			spawn_enemy(Enemy_Rock, x, y)
		else
			spawn_enemy(Enemy_Gross, x, y)
		end
		if chance < 5 * game_difficulty_factor then
			spawn_enemy(Enemy_Drang, x, y)
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

	-- invulnerability timer
	if timer_invulnerable and timer_global - timer_invulnerable > 2 then
		timer_invulnerable = nil
	end
	-- shot timer
	if timer_shot and timer_global - timer_shot > player_attack_speed then
		timer_shot = nil
	end

	
	
	
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
		for p = #bullets, 1, -1 do
			if bullets[p].friendly and not enemies[i].friendly and get_collision(enemies[i], bullets[p]) then
				enemies[i].health = enemies[i].health - 1
				bullets[p].health = bullets[p].health - 1

				local sound = love.audio.newSource("sounds/deep_hit.wav", 'static')
				sound:play()
				effect_shockwave(bullets[p].x + bullets[p].hitw/2, bullets[p].y + bullets[p].hith/2, bullets[p].dx * 0.05, bullets[p].dy * 0.05, 1, 50)
				for fewji = 1, 3 do
					effect_break(enemies[i].x + enemies[i].hitw / 2, enemies[i].y + enemies[i].hith / 2)
				end
				enemies[i].flash = 0.05

			end
		end
	end

	

	if not player then
		--logstring = logstring .. "hi"
		return
	end

	

	for i = 1, #enemies do -- enemy collide with player
		if not enemies[i].friendly and get_collision(player, enemies[i]) then
			if not timer_invulnerable then
				sound_slash:play()
				enemies[i].health = enemies[i].health - 1
				player.health = player.health - 1

				local sound = love.audio.newSource("sounds/deep_hit.wav", "static")
				sound:play()

				enemies[i].flash = 0.05
				timer_invulnerable = timer_global
				return
			else
				
				
			end
		end
	end
	for i = 1, #bullets do -- enemy bullet collide with player
		if not bullets[i].friendly and get_collision(player, bullets[i]) then
			if not timer_invulnerable then
				sound_slash:play()
				player.health = player.health - 1
				timer_invulnerable = timer_global
				return
			else
				
				
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
		mode = 'credits'
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
		local enemy = enemies[i]
		if enemy.flash > 0 then
			love.graphics.setShader(shader_flash)
		end
		enemy.animation:draw(enemy.sheet, math.floor(enemy.x), math.floor(enemy.y))
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
		local bullet = bullets[i]
		bullet.animation:draw(bullet.sheet, math.floor(bullet.x), math.floor(bullet.y))
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
		love.graphics.print(mode, 600, 4)
		if mode == 'game' then
			draw_game()
		elseif mode == 'start' then
			draw_letters()
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