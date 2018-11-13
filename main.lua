-- This ligne allows to show tracks into the console during execution of the program
io.stdout:setvbuf("no")

-- Prevent Love2D to filter pictures outlines which they are resize
-- Useful for pixel art
love.graphics.setDefaultFilter("nearest")

-- Maps parameters
map = love.graphics.newImage("images/background/firstWorld.png")
mapX = map:getWidth()
mapY = map:getHeight()
mapOriginY = -(mapY/3)
mapOriginX = -(mapX/3)
MAPDOWN = (mapY/3) + 70

-- Screen paramaters
screenWidth = love.graphics.getWidth()
screenHeight = love.graphics.getHeight()

-- Camera parameters
camera = {}
camera.x = -90
camera.y = 0
camera.speed = 120

-- Lists
listSprites = {}
listFighters = {}
listEnemies = {}
listHurtBoxes = {}
listHitBoxes  = {}

-- Factory function for creating sprites
function CreateSprite(pName, pX, pY, pVX, pVY, pState, pFrame, pImage)
	local mySprite = {}

	mySprite.name = pName
	mySprite.x = pX
	mySprite.y = pY
	mySprite.vx = pVX
	mySprite.vy = pVY
	mySprite.state = pState
	mySprite.isJumping = false
	mySprite.isFalling = false
	mySprite.isStanding = false
	mySprite.jumpSpeed = 200
	mySprite.isDead = false

	mySprite.currentAnimation = ""
	mySprite.frame = 0
	mySprite.animationSpeed = 1/28
	mySprite.animationTimer = 0
	mySprite.animations = {}
	mySprite.images = {}
	mySprite.hurtBox = {}
	mySprite.hitBox = {}

	-- Function used for add images as a tilesheet for a sprite
	mySprite.AddImages = function(pDirectory, pSpriteName, pListImages)
		for k,v in pairs(pListImages) do
			local filename = pDirectory.."/"..pSpriteName.."/"..v..".png"
			mySprite.images[v] = love.graphics.newImage(filename)
		end
	end

	mySprite.AddAnimation = function(pDirectory, pSpriteName, pName, pListImages)
		mySprite.AddImages(pDirectory, pSpriteName, pListImages)
		mySprite.animations[pName] = pListImages
	end

	mySprite.PlayAnimation = function(pName)
		if mySprite.currentAnimation ~= pName then
			mySprite.currentAnimation = pName
			mySprite.frame = 1
		end
	end

	table.insert(listSprites, mySprite)
	return mySprite
end

-- Factory function for creating fighters
function CreateFighter(pName, pX, pY, pVX, pVY, pState, pFrame, pImage, pOriginX, pOriginY)
	local myFighter = CreateSprite(pName, pX, pY, pVX, pVY, pState, pFrame, pImage)
	myFighter.isPunching = false
	myFighter.bHitBoxActive = false
	myFighter.canJump = true
	myFighter.flip = false
	myFighter.originX = pOriginX
	myFighter.originY = pOriginY
	table.insert(listFighters, myFighter)
	return myFighter
end

function CreateEnemy(pName, pX, pY, pVX, pVY, pState, pFrame, pImage, pOriginX, pOriginY)
	local myEnemy = CreateSprite(pName, pX, pY, pVX, pVY, pState, pFrame, pImage)
	myEnemy.flip = false
	myEnemy.isDead = false
	myEnemy.originX = pOriginX
	myEnemy.originY = pOriginY
	myEnemy.timerAttack = 60
	table.insert(listEnemies, myEnemy)
	return myEnemy
end

-- Changing sprites animations
function ChangeAnimation(pSprite, pState)
	if pSprite.state ~= pState then
		pSprite.state = pState
		pSprite.frame = 1
		return true 
	end
	return false
end

-- Changing animations speed
function ChangeAnimationSpeed(pSprite, pAnimationSpeed)
	if pSprite.animationSpeed ~= pAnimationSpeed then
		oldAnimationSpeed = pSprite.animationSpeed
		pSprite.animationSpeed = pAnimationSpeed
	end
end

function SpriteDead(pSprite)
	if pSprite.isDead == false then
		pSprite.isDead = true
	end
end

-- Collision detection function
-- Returns true if two boxes overlap, false if they don't
-- x1,y1 are the top-left coords of the first box, while w1,h1 are its width and height
-- x2,y2,w2 & h2 are the same, but for the second box.
function CheckCollision(x1,y1,w1,h1,x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end

function CreateBox(pList, pBox, pWho, pSprite)
	local myBox = {}
	myBox.x = pSprite.x + pBox.x --+ camera.x
	myBox.y = pSprite.y + pBox.y --+ camera.y
	myBox.w = pBox.w * 2
	myBox.h = pBox.h * 2
	myBox.who = pWho
	table.insert(pList, myBox)
	--print("Ma box créée | X:"..tostring(myBox.x).."; Y :"..tostring(myBox.y).."; W :"..tostring(myBox.w).."; W :"..tostring(myBox.w))
	return myBox
end

function SetBoxes(pSprite)
	if pSprite.hurtBox[pSprite.state] ~= nil then
		local myBox = pSprite.hurtBox[pSprite.state][pSprite.frame]
		if myBox ~= nil then
			CreateBox(listHurtBoxes, myBox, pSprite.name, pSprite)
			--print("Mon Sprite | X:"..tostring(pSprite.x).."; Y :"..tostring(pSprite.y)..";")
			--print("Ma box | X:"..tostring(myBox.x).."; Y :"..tostring(myBox.y).."; W :"..tostring(myBox.w).."; W :"..tostring(myBox.w))
		end
	end
	if pSprite.hitBox[pSprite.state] ~= nil then
		local myBox = pSprite.hitBox[pSprite.state][pSprite.frame]
		if myBox ~= nil then
			CreateBox(listHitBoxes, myBox, pSprite.name, pSprite)
		end
	end
end

function TestCollisions()
	for hit=1, #listHitBoxes do
		local hitb = listHitBoxes[hit]
		for hurt=1, #listHurtBoxes do
			local hurtb = listHurtBoxes[hurt]
			--print("Collision ? "..tostring(CheckCollision(hitb.x, hitb.y, hitb.w, hitb.h,
			--				  hurtb.x, hurtb.y, hurtb.w, hurtb.h)))
			if CheckCollision(hitb.x, hitb.y, hitb.w, hitb.h,
							  hurtb.x, hurtb.y, hurtb.w, hurtb.h) == true then
				if hitb.who ~= hurtb.who then
					print(hitb.who.." vient de frapper "..hurtb.who)
					lastActionBy = hitb.who
					bTestCollision = false
				end			  	
		  	end
		end
	end
end

function love.load()
	love.window.setTitle("Gamecodeur Beat'Em Up")

	-- Creating my first fighter and import those animations
	myFighter = CreateFighter("Rayman", 160, MAPDOWN, 90, 0, "idle", 1, "rayman", 32, 64)
	--Animations
	myFighter.AddAnimation("images/", "rayman", "idle", {"idle1", "idle2", "idle3", "idle4", "idle5",
														 "idle6", "idle7", "idle8", "idle9", "idle10",
														 "idle11", "idle12"})
	myFighter.AddAnimation("images/", "rayman", "run", {"run1", "run2", "run3", "run4", "run5", "run6"})
	myFighter.AddAnimation("images/", "rayman", "jump", {"jump1", "jump2", "jump3", "jump4", "jump6", "jump7"})
	myFighter.AddAnimation("images/", "rayman", "fall", {"fall1"})
	myFighter.AddAnimation("images/", "rayman", "punch", {"punch1", "punch2", "punch3", "punch4", "punch5", "punch6"})
	myFighter.PlayAnimation("idle")
	--HurtBoxes
	-- Idle
	myFighter.hurtBox["idle"] = {}
	myFighter.hurtBox["idle"][1]  = {x=10, y=0, w=25, h=51}
	myFighter.hurtBox["idle"][2]  = {x=10, y=0, w=25, h=51}
	myFighter.hurtBox["idle"][3]  = {x=10, y=0, w=25, h=51}
	myFighter.hurtBox["idle"][4]  = {x=10, y=0, w=25, h=51}
	myFighter.hurtBox["idle"][5]  = {x=10, y=0, w=25, h=52}
	myFighter.hurtBox["idle"][6]  = {x=10, y=0, w=25, h=51}
	myFighter.hurtBox["idle"][7]  = {x=10, y=0, w=25, h=52}
	myFighter.hurtBox["idle"][8]  = {x=10, y=0, w=25, h=52}
	myFighter.hurtBox["idle"][9]  = {x=10, y=0, w=25, h=51}
	myFighter.hurtBox["idle"][10] = {x=10, y=0, w=25, h=51}
	myFighter.hurtBox["idle"][11] = {x=10, y=0, w=25, h=50}
	myFighter.hurtBox["idle"][12] = {x=10, y=0, w=25, h=50}
	-- Run
	myFighter.hurtBox["run"] = {}
	myFighter.hurtBox["run"][1]  = {x=22, y=12, w=29, h=50}
	myFighter.hurtBox["run"][2]  = {x=27, y=13, w=24, h=48}
	myFighter.hurtBox["run"][3]  = {x=28, y=19, w=23, h=42}
	myFighter.hurtBox["run"][4]  = {x=24, y=16, w=28, h=45}
	myFighter.hurtBox["run"][5]  = {x=27, y=10, w=24, h=52}
	myFighter.hurtBox["run"][6]  = {x=27, y=11, w=24, h=50}
	-- Jump
	myFighter.hurtBox["jump"] = {}
	myFighter.hurtBox["jump"][1]  = {x=27, y=22, w=23, h=40}
	myFighter.hurtBox["jump"][2]  = {x=28, y=16, w=22, h=45}
	myFighter.hurtBox["jump"][3]  = {x=29, y=10, w=21, h=51}
	myFighter.hurtBox["jump"][4]  = {x=32, y=1, w=19, h=60}
	myFighter.hurtBox["jump"][5]  = {x=34, y=1, w=15, h=61}
	myFighter.hurtBox["jump"][6]  = {x=34, y=1, w=18, h=61}
	-- Fall
	myFighter.hurtBox["fall"] = {}
	myFighter.hurtBox["fall"][1]  = {x=32, y=1, w=19, h=59}
	-- Punch
	myFighter.hurtBox["punch"] = {}
	myFighter.hurtBox["punch"][1]  = {x=24, y=12, w=26, h=49}
	myFighter.hurtBox["punch"][2]  = {x=22, y=11, w=16, h=51}
	myFighter.hurtBox["punch"][3]  = {x=19, y=12, w=15, h=50}
	myFighter.hurtBox["punch"][4]  = {x=17, y=14, w=13, h=47}
	myFighter.hurtBox["punch"][5]  = {x=29, y=11, w=12, h=50}
	myFighter.hurtBox["punch"][6]  = {x=29, y=12, w=17, h=48}

	--HitBoxes
	-- Punch
	myFighter.hitBox["punch"] = {}
	myFighter.hitBox["punch"][1]  = {x=47, y=35, w=15, h=15}


	-- Creating my first enemy and those animations
	myEnemy = CreateEnemy("Rabbids", screenWidth/2, MAPDOWN, 90, 0, "idle", "rabbids", 32, 64)
	myEnemy.AddAnimation("images/", "rabbids", "idle", {"idle1", "idle2"})
	ChangeAnimationSpeed(myEnemy, 1/4)
	myEnemy.PlayAnimation("idle")
	-- Hurtbox
	myEnemy.hurtBox = {}
	-- Idle
	myEnemy.hurtBox["idle"] 	= {}
	myEnemy.hurtBox["idle"][1] = {x=0, y=0, w=30, h=50}
	myEnemy.hurtBox["idle"][2] = {x=0, y=0, w=31, h=50}
end

-- Update camera moves wich follow fighter selected by player
function MoveCamera(pCamera, pSprite)
	local dist = pCamera.x + pSprite.x
	if dist < 70 then
		pCamera.x = pCamera.x + 1
	end
	if dist > (screenWidth/2)+70 then
		pCamera.x = pCamera.x - 1
	end
end 

function UpdateSprite(pSprite, dt)
	-- Animation
	local tick = false
	local jumpHeight = screenHeight/3	--Limit jump on Y axis

	-- Verify if the sprite selected have animations
	if pSprite.currentAnimation ~= "" then
		pSprite.animationTimer = pSprite.animationTimer + dt
		-- Reset animation timer and change 'tick' to true
		if pSprite.animationTimer >= pSprite.animationSpeed then
			tick = true
			pSprite.animationTimer = 0
		end
		-- Check if it's the last frame for punching
		if pSprite.isPunching == true then
			if pSprite.frame == 6 then
				bHitBoxActive = true
			end
		end
		-- Changing animation frame
		if tick == true then
			pSprite.frame = pSprite.frame + 1
			-- Verify the last animation frame and restart to the first frame
			if pSprite.frame > #pSprite.animations[pSprite.currentAnimation] then
				pSprite.frame = 1
				-- Specifig values for jumping and punching animations
				if pSprite.isPunching == true then
					pSprite.isPunching = false
					ChangeAnimation(pSprite, "idle")
					bHitBoxActive = false
				end
				if pSprite.isJumping == true then
					pSprite.isFalling = true
					pSprite.isJumping = false
				end
			end 
		end
	end

	if pSprite.isJumping == true then
		pSprite.isStanding = false
		pSprite.canJump = false
		pSprite.isFalling = false
		pSprite.jumpSpeed = -200 --pSprite.jumpSpeed * (-1)
		pSprite.vy = pSprite.jumpSpeed
	end

	if pSprite.isStanding == true then
		pSprite.vy = 0
		pSprite.y = MAPDOWN
		pSprite.isFalling = false
		pSprite.isJumping = false
		pSprite.canJump = true
	end

	if pSprite.isFalling == true then
		pSprite.isJumping = false
		pSprite.isStanding = false
		pSprite.canJump = false
		pSprite.jumpSpeed = 200 --pSprite.jumpSpeed * (-1)
		pSprite.vy = pSprite.jumpSpeed
	end

	if pSprite.y < jumpHeight then
		pSprite.isJumping = false 
		pSprite.isFalling = true
	end

	if pSprite.y >= MAPDOWN then
		pSprite.isStanding = true
	end

	--Sprite gravity
	pSprite.y = pSprite.y + (pSprite.vy * dt)

	SetBoxes(pSprite)
	if bTestCollision then
		TestCollisions()
	end

	--print("bTestCollision = "..tostring(bTestCollision))
end

function UpdateFighter(pFighter, pCamera, dt)
	--Fighter moves
	local newAnimation = "idle"

	MoveCamera(camera, pFighter)

	if love.keyboard.isDown("right") then
		local newAnimationSpeed = 1/16
		ChangeAnimationSpeed(pFighter, newAnimationSpeed)

		pFighter.flip = false

		-- Keep fighter on the screen
		if pFighter.x > (screenWidth - 64) then
			pFighter.x = screenWidth - 64
		else
			pFighter.x = pFighter.x + (pFighter.vx * dt)
		end

		newAnimation = "run"
	elseif love.keyboard.isDown("left") then
		local newAnimationSpeed = 1/16
		ChangeAnimationSpeed(pFighter, newAnimationSpeed)

		pFighter.flip = true

		-- Keep fighter on the screen
		if pFighter.x < 0 then
			pFighter.x = 0
		else 
			pFighter.x = pFighter.x - (pFighter.vx * dt)
		end

		newAnimation = "run"
	end

	--Fighter jumpMove
	if pFighter.isJumping == true then
		local newAnimationSpeed = 1/28
		ChangeAnimationSpeed(pFighter, newAnimationSpeed)
		newAnimation = "jump"
	end

	--Fighter falling animation
	if pFighter.isFalling == true then
		newAnimation = "fall"
	end

	--Fighter punchMove
	if pFighter.isPunching == true then
		-- Changing animation to punching
		local newAnimationSpeed = 1/28
		ChangeAnimationSpeed(pFighter, newAnimationSpeed)
		newAnimation = "punch"
	end

	if newAnimation == "idle" then
		local newAnimationSpeed = 1/28
		ChangeAnimationSpeed(pFighter, newAnimationSpeed)
	end

	pFighter.PlayAnimation(newAnimation)
end

function love.update(dt)
	UpdateSprite(myFighter, dt)
	UpdateSprite(myEnemy, dt)
	UpdateFighter(myFighter, camera, dt)
end

-- Drawing sprites and those animations
function DrawSprite(pSprite)
	local imgName = pSprite.animations[pSprite.currentAnimation][pSprite.frame]
	local img = pSprite.images[imgName]
	local halfw = img:getWidth()  / 2
  	local halfh = img:getHeight() / 2
  	local flipCoef = 1
  	if pSprite.flip then flipCoef = -1 end
  	love.graphics.draw(	img, -- Image
					    pSprite.x + halfw, -- horizontal position
					    pSprite.y + halfh, -- vertical position
					    0, -- rotation (none = 0)
					    2 * flipCoef, -- horizontal scale
					    2, -- vertical scale (normal size = 1)
					    halfw, halfh -- horizontal and vertical offset
    )

end

function DrawBoxes()
	love.graphics.setColor(0,0,1)
	for hurt=1, #listHurtBoxes do
		local hurtb = listHurtBoxes[hurt]
		love.graphics.rectangle("line", hurtb.x, hurtb.y, hurtb.w, hurtb.h)
	end
	if bHitBoxActive == true then
		love.graphics.setColor(1,0,0)
		for hit=1, #listHitBoxes do
			local hitb = listHitBoxes[hit]
			love.graphics.rectangle("line", hitb.x, hitb.y, hitb.w, hitb.h)
		end
	end
	love.graphics.setColor(1,1,1)
end

function love.draw()
	--Map
	love.graphics.draw(map, mapOriginX + camera.x, mapOriginY)
	DrawSprite(myFighter)
	DrawSprite(myEnemy)
	DrawBoxes()
end

function KeyPressedFighter(key, pFighter)
	if key == "up" then
		if pFighter.canJump == true then
			-- Variables to save old values of Fighter before jumping
			pFighter.isJumping = true
		end
	elseif key == "space" then
		pFighter.isPunching = true
		bTestCollision = ChangeAnimation(pFighter, "punch")
	end
end

function love.keypressed(key)
	KeyPressedFighter(key, myFighter)
end
