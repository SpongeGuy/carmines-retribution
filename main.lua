-- carmine's retribution
-- sponge guy

-- variables that will literally never change here
local font_consolas = love.graphics.setNewFont("crafters-delight.ttf", 8)
local anim8 = require 'anim8'
local push = require 'push'

-- global variables
love.graphics.setDefaultFilter("nearest", "nearest")

local window_width, window_height = love.window.getDesktopDimensions()
local game_width, game_height = 960, 540
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

local fire_colors = {color_brightred, color_orange, color_yellow, color_orange}
local grey_colors = {color_white, color_white, color_white, color_lightgrey, color_grey, color_lightgrey}


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
	self.data = nil
	self.timer = timer_global
	self.seed = math.random() * 0.2
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
	self.looping = flags.looping or false
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

	-- handle screen looping if applicable
	if self.looping then
		if self.dx < 0 and self.x < -50 then
			self.x = game_width + 50
		elseif self.dx > 0 and self.x > game_width + 50 then
			self.x = -50
		end
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

function MoveableObject:draw_hitbox()
	love.graphics.rectangle('line', self.hitx, self.hity, self.hitw, self.hith)
end

function MoveableObject:control(speed, left, right, up, down)
	self.dx = 0
	self.dy = 0
	if love.keyboard.isDown(left) and self.x > 0 then
		self.dx = -speed
	end
	if love.keyboard.isDown(right) and self.x < game_width - 35 then
		self.dx = speed
	end
	if love.keyboard.isDown(up) and self.y > 0 then
		self.dy = -speed
	end
	if love.keyboard.isDown(down) and self.y < game_height - 23 then
		self.dy = speed
	end
	if not (self.dx == 0 and self.dy == 0) then
		self.dx = self.dx * 0.707
		self.dy = self.dy * 0.707
	end
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
	self.sheet = load_image("sprites/heart/heart_sheet.png")
	self.animation = initialize_animation(self.sheet, 16, 16, '1-2', 1)
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
	self.points = 100
	return self
end

local Enemy_Gross = {}
Enemy_Gross.__index = Enemy_Gross

setmetatable(Enemy_Gross, {__index = MoveableObject})

function Enemy_Gross.new(x, y, dx, dy, flags)
	local flags = flags or {}
	local self = MoveableObject.new(x, y, dx, dy, hitx, hity, hitw, hith, flags)
	setmetatable(self, Enemy_Gross)
	self.hitx = x
	self.hity = y
	self.hitw = 23
	self.hith = 35
	self.sheet = load_image("sprites/gross_guy_sheet.png")
	self.animation = initialize_animation(self.sheet, 23, 35, '1-5', 0.1)
	self.friendly = false
	self.id = "gross_guy"
	self.health = 5
	self.points = 50
	self.copies = flags.copies or 5
	self.copying = flags.copying or true
	self.switched = false
	self.death_effects = {death_effect_points, death_effect_burst}
	return self
end

function Enemy_Gross:update(dt)
	MoveableObject.update(self, dt)
	if self.copying and self.copies > 1 and (self.x < 925 and self.x > 800) then
		copy = Enemy_Gross.new(game_width + 20, self.y, self.dx, self.dy, {copies = self.copies - 1})
		self.copying = false
		table.insert(enemies, copy)
	end
	if self.x < 100 and not self.switched then
		self.switched = true
		self.dx = -self.dx * 0.707
		self.dy = self.dx
	end
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

--  ____  ____  ____  ____  ___  ____  ___ 
-- ( ___)( ___)( ___)( ___)/ __)(_  _)/ __)
--  )__)  )__)  )__)  )__)( (__   )(  \__ \
-- (____)(__)  (__)  (____)\___) (__) (___/

function death_effect_points(enemy)
	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2
	local points = enemy.points
	
	effect_points(pointX, pointY, enemy.dx / 2.5, math.random(-25, 25), points)
end

function death_effect_explode(enemy)
	local sound = love.audio.newSource("sounds/block_hit.wav", 'static')
	sound:play()

	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2

	for p  = 1, 50 do
		effect_explode(pointX, pointY, math.random(-200, 200) + enemy.dx, math.random(-200, 200) + enemy.dy)
	end
end

function death_effect_shockwave(enemy)
	local sound = love.audio.newSource("sounds/block_hit.wav", 'static')
	sound:play()

	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2

	effect_shockwave(pointX, pointY, enemy.dx / 2, enemy.dy / 2)
end

function death_effect_burst(enemy)
	local sound = love.audio.newSource("sounds/block_hit.wav", 'static')
	sound:play()

	local pointX = enemy.x + enemy.hitw/2
	local pointY = enemy.y + enemy.hith/2

	effect_burst(pointX, pointY, enemy.dx * 0.75, enemy.dy * 0.75, 50)
end

function effect_points(x, y, dx, dy, value)
	local pp = ParticleObject.new(x, y, dx, dy, "points")
	pp.data = value
	pp.timer = pp.timer + 0.5
	score = score + value
	table.insert(particles, pp)
end

function effect_shockwave(x, y, dx, dy)
	local myp = ParticleObject.new(x, y, dx, dy, "effect_shockwave")
	myp.r = 1
	myp.alpha = 0.2
	myp.dr = 400--* math.random() * 1.5
	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		self.r = (self.r + self.dr * dt)
		local decrease_rate = 3.5
		local decrease_per_frame = decrease_rate / love.timer.getFPS()
		self.dr = self.dr * (1 - decrease_per_frame)
		self.alpha = self.alpha - 0.25 * dt
	end
	myp.timer = myp.timer + myp.seed - 0.5
	table.insert(particles, myp)
end

function effect_burst(x, y, dx, dy, r, dr)
	local myp = ParticleObject.new(x, y, dx, dy)
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
	local myp = ParticleObject.new(x, y, dx, dy, "explosion")
	function myp:update(dt)
		self.x = (self.x + self.dx * dt)
		self.y = (self.y + self.dy * dt)
		local decrease_rate = 2.5
		local decrease_per_frame = decrease_rate / love.timer.getFPS()
		self.r = self.r - 1 * dt
		self.dx = self.dx * (1 - decrease_per_frame)
		self.dy = self.dy * (1 - decrease_per_frame)
	end
	myp.r = math.floor(math.random(4, 8))
	myp.timer = myp.timer + myp.seed
	table.insert(particles, myp)
end










--   ___    __    __  __  ____    __    _____    __    ____  
--  / __)  /__\  (  \/  )( ___)  (  )  (  _  )  /__\  (  _ \ 
-- ( (_-. /(__)\  )    (  )__)    )(__  )(_)(  /(__)\  )(_) )
--  \___/(__)(__)(_/\/\_)(____)  (____)(_____)(__)(__)(____/ 

-- load functions

function love.load()
	love.window.setTitle("CARMINE'S RETRIBUTION")
	love.window.setIcon(love.image.newImageData("sprites/carmine/carmine_icon.png"))
	mode = 'start'

	-- timers
	-- - make sure to set timer to nill after using
	timer_blink = 1
	timer_global = 1
	timer_levelselect_delay = nil
	timer_invulnerable = nil
	timer_shot = nil
	timer_secondshot = nil

	shader_flash = love.graphics.newShader[[
		vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
		{
			vec4 pixel = Texel(texture, texture_coords); // get current pixel color
			return vec4(1.0, 1.0, 1.0, pixel.a); // return modified pixel color
		}
	]]
end

function load_player()
	-- carmine
	carmine = MoveableObject.new(100, 200, 0, 0, 114, 208, 14, 7)
	carmine.id = "carmine"
	carmine.health = 3
	carmine.attack_speed = 0.25
	function carmine:shoot(dt)
		-- shot effect_burst data
		shot_circ_x = carmine.x + 30
		shot_circ_y = carmine.y + 10
		if shot_circ_r > 0 then
			shot_circ_r = shot_circ_r - 180 * dt
		end
		if shot_circ_r < 0 then shot_circ_r = 0 end

		-- water drop
		if love.keyboard.isDown('space') and not timer_shot then
			local water = Projectile_Water.new(math.floor(carmine.x + 10), math.floor(carmine.y), 550, 0, true)
			timer_shot = timer_global
			--timer_secondshot = timer_global
			local sound = love.audio.newSource("sounds/ball_shot.wav", 'static')
			sound:play()
			key_space_pressed = true
			
			table.insert(bullets, water)
			shot_circ_r = 25
		end

		if timer_secondshot and timer_global - timer_secondshot > 0.1 then
			local water = Projectile_Water.new(math.floor(carmine.x + 10), math.floor(carmine.y), 550, 0, true)
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
end

function reset_game()
	-- init variables
	bullets = {}
	background = {}
	enemies = {}
	explosions = {}
	particles = {}
	hearts = {}
	score = 0

	-- these are the controllers for every moving object
	-- everything which moves along the screen should reference these variables
	game_dx = -150
	game_dy = 0

	
	sound_slash = love.audio.newSource("sounds/slash.wav", 'static')
	shot_circ_r = 0
	shot_circ_x = 0
	shot_circ_y = 0

	-- hearts
	table.insert(hearts, Graphic_Heart.new(0, 0, 0, 0))
	table.insert(hearts, Graphic_Heart.new(20, 0, 0, 0))
	table.insert(hearts, Graphic_Heart.new(40, 0, 0, 0))
	
	load_player()

	-- stars
	for i = 1, 300 do
		star = MoveableObject.new(math.random(1, game_width), math.random(1, game_height), -math.random(1, 200), 0)
		star.sheet = load_image("sprites/stars/star1_sheet.png")
		star.animation = initialize_animation(star.sheet, 4, 7, '1-4', 0.1)
		star.looping = true
		table.insert(background, star)
	end

	guy1 = Enemy_Gross.new(game_width + 50, 200, game_dx, game_dy, {copies = 7})
	table.insert(enemies, guy1)
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
		end
		if enemy_left_game_area or enemy_dead then
			table.remove(enemies, i)
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
	for i = 1, 3 do
		if i <= carmine.health then
			hearts[i].full = true
		end
		hearts[i]:update(dt)
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
		if explosion.r <= 0 then
			table.remove(explosions, i)
		end
	end
end

function update_particles(dt)
	for i = #particles, 1, -1 do
		local particle = particles[i]
		particle:update(dt)
		if timer_global - particle.timer > 0.7 + particle.seed then
			table.remove(particles, i)
		end
	end
end

function update_player(dt)
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

	

	if love.keyboard.isDown('c') then
		for p = 1, #bullets do
			bullets[p].health = bullets[p].health -1
		end
	end
end


function update_game(dt)
	logstring = ""

	if carmine.health <= 0 then
		mode = 'gameover'
		reset_game()
	end

	if love.keyboard.isDown('r') then
		reset_game()
	end
	if timer_global > 32000 then
		timer_global = 1
	end

	-- invulnerability timer
	if timer_invulnerable and timer_global - timer_invulnerable > 2 then
		timer_invulnerable = nil
	end
	-- shot timer
	if timer_shot and timer_global - timer_shot > carmine.attack_speed then
		timer_shot = nil
	end

	
	
	
	-- collection updates
	carmine:shoot(dt)
	update_bullets(dt)
	update_background(dt)
	update_enemies(dt)
	update_player(dt)
	
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

				enemies[i].flash = 0.05

				-- local bullet_effect_burst = ExplosionObject.new(bullets[p].x + bullets[p].hitw/2, bullets[p].y + bullets[p].hith/2, 30, 200, bullets[p].dx * 0.05, bullets[p].dy * 0.05)
				effect_burst(bullets[p].x + bullets[p].hitw/2, bullets[p].y + bullets[p].hith/2, bullets[p].dx * 0.05, bullets[p].dy * 0.05)
			end
		end
	end
	for i = 1, #enemies do -- enemy collide with player
		if not enemies[i].friendly and get_collision(carmine, enemies[i]) then
			if not timer_invulnerable then
				sound_slash:play()
				enemies[i].health = enemies[i].health - 1
				carmine.health = carmine.health - 1

				local sound = love.audio.newSource("sounds/deep_hit.wav", "static")
				sound:play()

				enemies[i].flash = 0.05
				timer_invulnerable = timer_global
				return
			else
				
				
			end
		end
	end
	for i = 1, #bullets do -- enemy bullet collide with carmine
		if not bullets[i].friendly and get_collision(carmine, bullets[i]) then
			if not timer_invulnerable then
				sound_slash:play()
				carmine.health = carmine.health - 1
				timer_invulnerable = timer_global
				return
			else
				
				
			end
		end
	end
	

	-- if #enemies < 7 then
	-- 	local rock = Enemy_Rock.new(game_width + 50, math.random(50, game_height - 50), -150, 0)
	-- 	table.insert(enemies, rock)
	-- end

	log1:log(logstring)
end

function update_levelscreen(dt)
	reset_game()
	if not timer_levelselect_delay then
		timer_levelselect_delay = timer_global
	end
	if timer_global - timer_levelselect_delay > 2 then
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
	timer_global = timer_global + (1 * dt)
	timer_blink = timer_blink + (1 * dt) * 10
	if mode == 'game' then
		update_game(dt)
	elseif mode == 'start' then
		update_start(dt)
	elseif mode == 'gameover' then
		timer_blink = timer_blink + (1 * dt) * 15
		update_gameover(dt)
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

function draw_explosions()
	for i = 1, #explosions do
		local explosion = explosions[i]
		if math.sin(timer_global * 50) < 0.33 then
			set_draw_color(22)
		elseif math.sin(timer_global * 50) > -0.1 then
			set_draw_color(6)
		else
			set_draw_color(28)
		end
		love.graphics.circle("fill", math.floor(explosion.x), math.floor(explosion.y), math.floor(explosion.r))
		set_draw_color(22)
	end
end

function draw_particles()
	for i = 1, #particles do
		local particle = particles[i]
		if particle.id == "points" then
			set_draw_color(blink({21, 22, 23, 24}))
			love.graphics.print(particle.data, math.floor(particle.x), math.floor(particle.y))
			set_draw_color(22)
		elseif particle.id == "explosion" then
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
		elseif particle.id == "effect_shockwave" then
			love.graphics.setColor(1, 1, 1, particle.alpha)
			love.graphics.circle('line', math.floor(particle.x), math.floor(particle.y), particle.r)
		end
	end
	set_draw_color(22)
end

function draw_player()
	if not timer_invulnerable then
		carmine_wings_left_animation:draw(carmine_wings_right_sheet, math.floor(carmine.x - 45), math.floor(carmine.y - 35))
		carmine_body_animation:draw(carmine_body_sheet, math.floor(carmine.x), math.floor(carmine.y))
		carmine_wings_right_animation:draw(carmine_wings_left_sheet, math.floor(carmine.x - 45), math.floor(carmine.y - 35))
	else
		if math.sin(timer_global * 50) < 0.75 then
			carmine_wings_left_animation:draw(carmine_wings_right_sheet, math.floor(carmine.x - 45), math.floor(carmine.y - 35))
			carmine_body_animation:draw(carmine_body_sheet, math.floor(carmine.x), math.floor(carmine.y))
			carmine_wings_right_animation:draw(carmine_wings_left_sheet, math.floor(carmine.x - 45), math.floor(carmine.y - 35))
		end
	end
	set_draw_color(22)
	love.graphics.circle('fill', math.floor(shot_circ_x), math.floor(shot_circ_y), shot_circ_r)
end

function draw_game()

	draw_background()
	
	draw_particles()
	draw_enemies()

	draw_bullets()
	draw_explosions()
	
	draw_player()
	draw_hearts()
	love.graphics.print(score, 80, 0)

end

function draw_levelscreen()
	set_draw_color(blink({21, 22, 23, 24}))
	local text1 = "LEVEL 1"
	local text2 = "OUTER SPACER"
	love.graphics.print(text1, center_text(text1), (game_height / 2) - 60)
	love.graphics.print(text2, center_text(text2), (game_height / 2) - 40)
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

function draw_gameover()
	set_draw_color(blink({9, 6, 28}))
	local text1 = "YOU SUCK"
	local text2 = "NOT WORTHY OF CARMINE"
	love.graphics.print(text1, (game_width / 2) - math.floor(font_consolas:getWidth(text1) / 2.2), (game_height / 2) - 60)
	love.graphics.print(text2, (game_width / 2) - math.floor(font_consolas:getWidth(text2) / 2.2), (game_height / 2) - 40)
end

function love.draw()
	push:start()
		if mode == 'game' then
			draw_game()
		elseif mode == 'start' then
			draw_start()
		elseif mode == 'gameover' then
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