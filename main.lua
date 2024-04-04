-- todo
-- - add background with parallax
-- - add enemy with movement
-- - make enemy shoot bullet


-- mother fucker
font_consolas = love.graphics.newFont("crafters-delight.ttf")
local anim8 = require 'anim8'
local push = require 'push'

-- global variables
love.graphics.setDefaultFilter("nearest", "nearest")
local game_width, game_height = 960, 540
local window_width, window_height = love.window.getDesktopDimensions()
local window_scale = window_width/game_width
push:setupScreen(game_width, game_height, window_width, window_height, {fullscreen = true})

local carmine_body_sheet, carmine_body_animation
local carmine_wings_left_sheet, carmine_wings_left_animation, carmine_wings_right_sheet, carmine_wings_right_animation
local water_drop_sheet, water_drop_animation
local bullets = {}
local background = {}


-- helpful functions
local MoveableObject = {}
MoveableObject.__index = MoveableObject

function MoveableObject.new(x, y, dx, dy, w, h, sheet, animation) --here
	local self = setmetatable({}, MoveableObject)
	self.x = x or 0
	self.y = y or 0
	self.w = w or 0
	self.h = h or 0
	self.dx = dx or 0
	self.dy = dy or 0
	self.sheet = sheet or nil
	self.animation = animation or nil
	self.id = ""
	self.looping = false
	return self
end

function MoveableObject:update(dt)
	-- update movement
	self.x = self.x + self.dx * dt
	self.y = self.y + self.dy * dt

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

function MoveableObject:initialize_animation(width, height, frames, duration)
	local a = anim8.newGrid(width, height, self.sheet:getWidth(), self.sheet:getHeight())
	self.animation = anim8.newAnimation(a(frames, 1), duration)
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
end

-- removes all nil values from a table, moving subsequent values up
function update_collection(collection, dt)
	local str = "{"
	-- mark objects for removal
 	for i = 1, #collection do
		local obj = collection[i]
		deletion_condition = (obj.x > (window_width * window_scale) + 200 or obj.x < -200) or (obj.y > (window_height * window_scale) + 200 or obj.y < -200)
		if deletion_condition then
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

-- get if colliding with the window edge
-- accounts for window scaling
function get_window_collision(x1, y1, w, h)
	local vertical = y < 0 or y + h > window_height / window_scale
	local horizontal = x < 0 or x + w > window_width / window_scale
	return vertical, horizontal
end

-- get if there is a collision between two objects
function get_collision(x1, y1, w, h, x2, y2)
	local col_x = false
	local col_y = false
	if x2 < x1 + w and x2 > x1 then
		col_x = true
	end
	if y2 < y1 + h and y2 > y1 then
		col_y = true
	end
	if col_x and col_y then
		return true
	end
	return false
end

function load_image(path)
	local info = love.filesystem.getInfo(path)
	if info then
		return love.graphics.newImage(path)
	end
	print("Couldn't grab image from " .. path)
end

function debug()
	tester = "x:" .. friend.x .. "\t" .. "y:" .. friend.y .. "\t" .. "dx:" .. friend.dx .. "\t" .. "dy:" .. friend.dy
	text = love.graphics.newText(font_consolas, tester)
end


-- engage loving

function love.load()
	--love.window.setMode(window_width, window_height, {fullscreen = true})
	
	scared_man_png = load_image('sprites/scared_man.png')

	local g

	-- carmine
	carmine_body_sheet = load_image('sprites/carmine/carmine_body_sheet.png')
	g = anim8.newGrid(35, 23, carmine_body_sheet:getWidth(), carmine_body_sheet:getHeight())
	carmine_body_animation = anim8.newAnimation(g('1-3', 1), 0.1)

	carmine_wings_left_sheet = load_image('sprites/carmine/carmine_wings_left_sheet.png')
	g = anim8.newGrid(100, 100, carmine_wings_left_sheet:getWidth(), carmine_wings_left_sheet:getHeight())
	carmine_wings_left_animation = anim8.newAnimation(g('1-4', 1), 0.1)

	carmine_wings_right_sheet = load_image('sprites/carmine/carmine_wings_right_sheet.png')
	g = anim8.newGrid(100, 100, carmine_wings_right_sheet:getWidth(), carmine_wings_right_sheet:getHeight())
	carmine_wings_right_animation = anim8.newAnimation(g('1-4', 1), 0.1)

	carmine_obj = MoveableObject.new(100, 200, 0, 0)
	carmine_obj.id = "carmine"

	-- stars
	for i = 1, 150 do
		star = MoveableObject.new(math.random(1, game_width), math.random(1, game_height), -math.random(50, 350), 0)
		star.sheet = load_image("sprites/stars/star1_sheet.png")
		star:initialize_animation(4, 7, '1-4', 0.1)
		star.looping = true
		table.insert(background, star)
	end
end

local circ_r = 0
local circ_x = 0
local circ_y = 0

function love.update(dt)
	-- bullets
	update_collection(bullets, dt)
	update_collection(background, dt)
	-- carmine
	carmine_wings_left_animation:update(dt)
	carmine_wings_right_animation:update(dt)
	carmine_obj:control(250, "a", "d", "w", "s")
	carmine_obj:update(dt)
	if carmine_obj.dy < 0 then
		carmine_body_animation:gotoFrame(3)
	elseif carmine_obj.dy > 0 then
		carmine_body_animation:gotoFrame(1)
	else
		carmine_body_animation:gotoFrame(2)
	end

	circ_x = carmine_obj.x + 80
	circ_y = carmine_obj.y + 45

	-- water drop
	if love.keyboard.isDown('space') and not key_space_pressed then
		local source = love.audio.newSource("sounds/ball_shot.wav", 'static')
		source:play()
		key_space_pressed = true
		local water = MoveableObject.new(math.floor(carmine_obj.x + 49), math.floor(carmine_obj.y + 37), 550, 0, 20, 21)
		water.sheet = load_image('sprites/water_drop/water_drop_sheet.png')
		water:initialize_animation(20, 21, '1-4', 0.05)
		water.id = "water_drop"
		table.insert(bullets, water)
		circ_r = 30
		
	end
	if circ_r > 0 then
		circ_r = circ_r - 3
	end
	
end

function love.draw()
	push:start()
		-- background
		draw_collection(background)

		-- carmine
		carmine_wings_left_animation:draw(carmine_wings_right_sheet, carmine_obj.x, carmine_obj.y)
		carmine_body_animation:draw(carmine_body_sheet, (carmine_obj.x + 44), (carmine_obj.y + 32))
		carmine_wings_right_animation:draw(carmine_wings_left_sheet, carmine_obj.x, carmine_obj.y)

		-- bullets
		draw_collection(bullets)
		
		love.graphics.setColor(1, 1, 1)
		love.graphics.circle('fill', circ_x, circ_y, circ_r)
	push:finish()
end

function love.keyreleased(key)
	if key == 'space' then
		key_space_pressed = false
	end
end