local anim8 = require 'anim8'
local push = require 'push'
love.graphics.setDefaultFilter("nearest", "nearest")
local window_width, window_height = love.window.getDesktopDimensions()
local game_width, game_height = 960, 540
local window_scale = window_width/game_width
push:setupScreen(game_width, game_height, window_width, window_height, {windowed = true})

local font_game = love.graphics.setNewFont("PressStart2P.ttf", 8)


function load_image(path)
	local info = love.filesystem.getInfo(path)
	if info then
		return love.graphics.newImage(path)
	end
	print("Couldn't grab image from " .. path)
end

function create_animation(sheet, frame_width, frame_height, frames, duration)
	local a = anim8.newGrid(frame_width, frame_height, sheet:getWidth(), sheet:getHeight())
	return anim8.newAnimation(a(frames, 1), duration)
end

local sheet_red_orb = load_image("sprites/entity/damage_orb/damage_orb-sheet.png")

-- backgrounds
local sheet_sp_back = load_image("sprites/background/seaside_peaks/back.png")
local sheet_sp_ocean = load_image("sprites/background/seaside_peaks/ocean.png")
local sheet_sp_near = load_image("sprites/background/seaside_peaks/near.png")
local sheet_sp_horizon = load_image("sprites/background/seaside_peaks/horizon.png")
local sheet_sp_vfar = load_image("sprites/background/seaside_peaks/very_far.png")
local sheet_sp_farish = load_image("sprites/background/seaside_peaks/farish.png")
local sheet_sp_far = load_image("sprites/background/seaside_peaks/far.png")

function create_background(sheet, posx, posy, deltax, deltay, id, repeating)
	local bg = {
		x = posx,
		y = posy,
		dx = deltax,
		dy = deltay,
		sheet = sheet,
		animation = create_animation(sheet, 1920, 540, '1-1', 10000),
		id = id or "generic",
		repeating = repeating or true,
	}
	return bg
end

function love.load()
	scroll_mod = 1
	backgrounds = {
		-- 1
		create_background(sheet_sp_back, 1920, 0, 0, 0, "immobile"),
		create_background(sheet_sp_back, 0, 0, 0, 0, "immobile"),
		create_background(sheet_sp_vfar, 1920, 0, -8, 0),
		create_background(sheet_sp_vfar, 0, 0, -8, 0),
		create_background(sheet_sp_far, 1920, 0, -16, 0),
		create_background(sheet_sp_far, 0, 0, -16, 0),
		create_background(sheet_sp_farish, 1920, 0, -22, 0),
		create_background(sheet_sp_farish, 0, 0, -22, 0),
		create_background(sheet_sp_horizon, 1920, 0, -30, 0),
		create_background(sheet_sp_horizon, 0, 0, -30, 0),
		create_background(sheet_sp_ocean, 1920, 0, -40, 0),
		create_background(sheet_sp_ocean, 0, 0, -40, 0),
		create_background(sheet_sp_near, 1920, 0, -60, 0),
		create_background(sheet_sp_near, 0, 0, -60, 0),
		
		

		-- 2
		
		
		
		
		
	}

end


function love.update(dt)
	if love.keyboard.isDown('right') then
		print("hi")
		scroll_mod = scroll_mod + 0.1
	end
	if love.keyboard.isDown('left') then
		scroll_mod = scroll_mod - 0.1
	end
	fps = love.timer.getFPS()
	for _, bg in ipairs(backgrounds) do
		local deltax = bg.dx
		if bg.id ~= "immobile" then
			deltax = deltax * scroll_mod
		end
		bg.x = bg.x + deltax * dt
		bg.y = bg.y + bg.dy * dt
		if bg.x < -1920 then
			bg.x = bg.x + 3840
		elseif bg.x > 1920 then
			bg.x = bg.x - 3840
		end
		bg.animation:update(dt)
	end

	
end


function love.draw()
	push:start()
		
		for _, bg in ipairs(backgrounds) do
			bg.animation:draw(bg.sheet, math.floor(bg.x), math.floor(bg.y))
		end
		love.graphics.print(fps, 0, 0)
	push:finish()
end