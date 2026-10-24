local contextactionservice = game:GetService('ContextActionService')
local replicatedstorage = game:GetService('ReplicatedStorage')
local Soundserv = game:GetService('SoundService')
local twnserv = game:GetService('TweenService')  --// THIS ARE THE SERVICES I WILL BE USING
local Runserv = game:GetService('RunService')
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--[[

I WILL BE WRITING IN 3RD PERSON LIKE IF I WAS MAKING A YOUTUBE TUTORIAL 

]]


local localplr = Players.LocalPlayer

local module = {}  ------------// START OF THE MODULE SCRIPT 

local playerDoubleJumpState = {} --// THIS TABLE STORES SOME DOUBLE JUMPING VALUES FOR EACH PLAYER, THEY WILL BE DEFINED LATER IN THE CODE

function module.TwoDCamera()   -----------------------//  THIS MODULE SETS THE CAMERA TO A SPECIFIC POSITION WHEN PLAYER ADDED, IT GIVES IT THE 2D VIBE
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable  --// THIS LINE MAKES THE CAMERA SCRIPTABLE SO IT CAN BE MODIFIED BY THE DEV TO HIS LIKINGS
	
	local campos = Vector3.new(0, 20, 0)
	local lookpos = Vector3.new(0,20,100)    ---// THIS BLOCK OF CODE SETS THE CAMERA TO A SPECIFIC POSITION AND LOOKS AT A SPECIFIC POSITION
	local cf = CFrame.new(campos, lookpos)
	camera.CFrame = cf
end

--[[

THE FUNCTION BELOW IS THE CLIMB MECHANIC, IT TAKES IN 3 PARAMETERS:
climb_area: ITS THE ZONE THAT IF THE PLAYER TOUCHES IT TRIGGERS THE CLIMB MECHANIC
char: THE PLAYER'S CHARACTER
input: IT GETS THE DIRECTION OF THE PLAYER TO DETERMINE WHAT SIDE TO TRIGGER, ITS EITHER RIGHT OR LEFT/ A OR D

]]

function module.ClimbMechanic(climb_area, char, input)
	local hum = char:FindFirstChildOfClass('Humanoid')
	local hrp = char:FindFirstChild('HumanoidRootPart')
	
	local Animator = hum:WaitForChild('Animator')
	local Climbanimation = Instance.new('Animation')
	Climbanimation.AnimationId = 'rbxassetid://140427978163641'  --// THIS BLOCK OF CODE DEFINES THE CLIMBING ANIMATION
	
	local customOffset  --// THIS VARIABLE IS USED TO DETERMINE WHICH DIRECTION THE PLAYER SHOULD CLIMB TO
	local angle  ----------// THIS VARIABLE ROTATES THE PLAYER EITHER RIGHT OR LEFT DEPENDING ON THE CLIMBING DIRECTION
	
	local function Climb(climb_area, char, input)  --// START OF THE CLIMBING MECHANIC
		if input == 'D' then
			customOffset = Vector3.new(-2,5,0)
			angle = 90
		elseif input == 'A' then  ----------------------// THIS BLOCK OF CODE DETERMINES THE DIRECTION OF THE CLIMB, A IS LEFT AND D IS RIGHT
			customOffset = Vector3.new(2,5,0)
			angle = -90
		end

		if hrp then  -----------// CHECKS IF THE HUMANOIDROOTPART EXISTS FROM NOW ON I WILL CALL IT HRP
			hrp.Anchored = true  ---------// ANCHOR THE HRP TO MAKE THE CLIMBING MOVEMENT SMOOTHER
			local climbCancelled = false --// THIS VARIABLE IS USED TO UNANCHOR THE HRP AND PRINT A WARINING IF PLAYER IS TOO LOW OR FALLING TOO FAST

			local lowYaxis = hrp.Position.Y < climb_area.Position.Y - 2  --// THIS VARIABLE CALCULATES IF THE PLAYER IS TO LOW TO CLIMB
			local downwardvelocity = hrp.AssemblyLinearVelocity.Y  --// THIS VARIABLE CALCULATES THE PLAYER'S FALLING SPEED

			if lowYaxis or downwardvelocity < -25 then ---// THIS LINE CHECKS IF THE PLAYER IS EITHER TO LOW OR FALLING TOO FAST
				hrp.Anchored = false   --// IF ITS TRUE THEN UNANCHOR THE HRP AND EXIT THE FUNCTION WITH THE return STATEMENT BELOW
				return
			end

			local AnimationPos = CFrame.new(climb_area.Position + customOffset) * CFrame.Angles(0, math.rad(angle) ,0) --// THIS MOVES THE PLAYER ONTOP OF THE CLIMBED OBJECT
			local twninfo = TweenInfo.new(.2)
			local climb_endposition = twnserv:Create(hrp, twninfo, {CFrame = AnimationPos}) --// THIS CREATES A TWEEN SO IT MOVES ON TOP OF THE OBJECT SMOOTHLY
			
			--// THIS RUNSERVICE (HEARBEAT) RUNS WHILE THE CLIMBING MECHANIC IS HAPPENING
			
			local connection              ----------------------// THIS ENABLES THE FEATURE TO DISCONNECT FROM ANY RUNSERVICE
			connection = Runserv.Heartbeat:Connect(function()
				if lowYaxis or downwardvelocity < -15 then  --// CHECKS IF THE PLAYER IS TOO LOW OR FALLING TOO FAST, IF TRUE THEN
					climb_endposition:Cancel()  ---// STOPS THE TWEEN
					climbCancelled = true  ---------------------------// SETS THE climbCancelled VARIABLE TO TRUE
					Animator:LoadAnimation(Climbanimation):Stop() --// STOPS THE CLIMB ANIMATION
					hrp.Anchored = false  --// UNANCHORS THE HRP SO THE PLAYER IS ABLE TO MOVE
					connection:Disconnect()  --// ENDS THE RUNSERVICE
				end
			end)
			
			Soundserv.ClimbGrunt_sfx:Play()  --// PLAYS A GRUNT SOUND WHEN THE CLIMB MECHANIC IS TRIGGERED
			climb_endposition:Play()  -------// STARTS THE TWEEN TO MOVE THE PLAYER ON TOP OF THE CLIMBED OBJECT
			Animator:LoadAnimation(Climbanimation):Play()  --// TRIGGERS THE CLIMB ANIMATION

			climb_endposition.Completed:Connect(function()  --// THIS RUNS ONCE THE TWEEN IS COMPLETED OR CANCELLED
				connection:Disconnect()     ------------------// ENDS THE RUNSERVICE
				if climbCancelled then warn('ClimbMechanic stopped due to <Y axis or falling fast') return end  --// CHECK IF THE THE CLIMB MECHANIC WAS UNSUCCESSFUL IF SO THEN PRINT OUT A WARNING AND EXIT THE FUNCTION
				hrp.Anchored = false  --// UNANCHORS THE HRP SO THE PLAYER CAN MOVE
			end)
		end
	end
	Climb(climb_area, char, input)  --// CALLS THE CLIMB FUNCTION
end

--// THE FUNCTION BELLOW IS THE DASH MECHANIC, IT TAKES IN 2 PARAMETERS, THE PLAYER'S HRP AND THE DIRECTION THE PLAYER IS FACING

function module.TriggerDash(hrp, direction)
	local hum = hrp.Parent:FindFirstChildOfClass('Humanoid') --// LOOKS FOR THE PLAYER'S HUMANOID
	local Animator = hum:FindFirstChildOfClass('Animator')
	local DashAnimation = Instance.new('Animation')
	DashAnimation.AnimationId = 'rbxassetid://136417349553097'  --// THIS IS THE DASH ANIMATION SETUP
	
	local FacingDirection = hrp.Orientation.Y --// THIS VARIABLE GETS THE CURRENT Y AXIS THE PLAYER IS FACING
	local direction     -------------// THIS VARIABLE IS USED TO DETERMINE THE DASH DIRECTION
	if math.abs(FacingDirection - 90) < math.abs(FacingDirection - (-90)) then  --// THIS ROUNDS THE Y AXIS TO EITHER 90 OR -90 EX: IF THE PLAYER IS FACING AT A 30 DEGREE ANGLE IT WILL ROUND IT TO 90 SO THE PLAYERS DASHES TO THE RIGHT
		direction = -1 --// THIS IS LEFT
	else
		direction = 1 --// THIS IS RIGHT
	end
	
	Soundserv.Dash_sfx:Play()  ---// PLAYS THE DASH SOUND EFFECT
	Animator:LoadAnimation(DashAnimation):Play() --// PLAYS THE DASH ANIMATION
	
	local bodyvelocity = Instance.new('BodyVelocity') --// THIS GIVES THE PLAYER A BOOST TO SIMULATE THE DASG
	bodyvelocity.MaxForce = Vector3.new(1e5,1e3,1e5) -----------// THIS IS THE FORCE APPLIED, 1e5 IS JUST A FANCY WAY OF WRITING 100,000 XeX IS USED TO WRITE BIG NUMBERS SO THE CODE DOESN'T BRANCH OUT
	bodyvelocity.Velocity = Vector3.new(direction * 60,0,0) --// THIS CACULATES THE DIRECTION OF THE PLAYER AND THE SPEED THE PLAYER IS DASHING AT
	bodyvelocity.Parent = hrp  --// THIS ATTACHES THE BODYVELOCITY TO THE HRP
	
	task.delay(.1, function()  --// THIS IS THE DURATION OF THE DASH, AFTER 100 MILISECONDS IT ENDS THE DASH
		bodyvelocity:Destroy()
	end)
end

function module.SetupDoubleJump(player)   ------// THIS FUNCTION SETS UP THE DOUBLE JUMP MECHANIC, THE PARAMETER IS THE PLAYER
	if not playerDoubleJumpState[player] then --// IF THE PLAYER IS NOT INSIDE THE TABLE THEN ADD IT AND SET THE VALUES
		playerDoubleJumpState[player] = {
			candoublejump = false,  --// IF TRUE THEN THIS ENABLES THE PLAYER TO DOUBLE JUMP
			HasDoubleJumped = false  --// IF TRUE MEANS THAT THE PLAYER HAS DOUBLE JUMPED
		}
	end
end

local hitplayer = true  --// THIS VARIABLE IS USED TO DETERMINE IF THE PLAYER CAN HIT ANOTHER PLAYER

function module.Punch(player)  ----// THIS FUNCTION IS THE PUNCHING MECHANIC, THE PARAMETER IS THE PLAYER
	local char = player.Character
	local hrp = char:WaitForChild('HumanoidRootPart')
	local hum = char:WaitForChild('Humanoid')
	local animator = hum:WaitForChild('Animator')
	local PunchAnimation = Instance.new('Animation')
	PunchAnimation.AnimationId = 'rbxassetid://125055857730196' --// SETS UP THE PUNCHING ANIMATIONS
	local PunchAnimation2 = Instance.new('Animation')
	PunchAnimation2.AnimationId = 'rbxassetid://123619535051485'
	if hrp then
		local lightPunch = true  --------------------// THIS VARIABLE DEFINES THE FUNCTION AS A LIGHT PUNCH
		
		local punchHitBox = Instance.new('Part')
		punchHitBox.CFrame = hrp.CFrame * CFrame.new(0,0,-3)
		punchHitBox.Size = Vector3.new(5.5, 3, 2) + Vector3.new(0,0,4)  --// THIS BLOCK OF CODE CREATES THE PUNCH HITBOX
		punchHitBox.CanCollide = false
		punchHitBox.Anchored = false
		punchHitBox.Transparency = .5  -----------------// MAKES THE HITBOX VISIBLE FOR TESTING PURPOSES
		punchHitBox.Color = Color3.fromRGB(255, 0, 0)
		punchHitBox:AddTag('DamagePlayer')  -------------// THIS TAG IS ADDED TO EVERY PLAYER AS SOON AS THEY JOIN SO THEY CAN GET HURT, THE DUMMIES ALSO HAVE THE TAG
		
		punchHitBox.Parent = workspace
		
		local weld = Instance.new('WeldConstraint')  --// THIS WELDS THE HITBOX TO THE HRP SO THERE AREN'T ANY ISSUES
		weld.Part0 = hrp
		weld.Part1 = punchHitBox
		weld.Parent = punchHitBox
		
		local num = math.random(1,2)  --// THIS IS A RANDOM NUMBER SELECTOR, IT CHOOSES BETWEEN 1 OR 2, 1 AND 2 HAVE PUNCHING ANIMATIONS, THE PLAYER WILL PUNCH WITH EITHER THE LEFT OR THE RIGHT ARM
		if num == 1 then
			animator:LoadAnimation(PunchAnimation):Play()
		else
			animator:LoadAnimation(PunchAnimation2):Play()
		end
		Soundserv.MissedPunch_SFX:Play()  --// THIS PLAYS WHEN THE PLAYER THROWS A PUNCH
		
		punchHitBox.Touched:Connect(function(hit) -------------------------// THIS WILL TRIGGER WHEN SOMETHING HITS THE HITBOX
			if hit.Parent:HasTag('DamagePlayer') and hitplayer == true then ----// THIS CHECKS IF THE HIT THING IS A PLAYER IF IT IS THEN:
				module.PlayerHitting(hit,lightPunch)   --// THIS MODULE WILL APPEAR LATER BUT IN SHORT, IT DETECTS IF ITS A LIGHT OR HEAVY PUNCH
				Soundserv.Punch_SFX:Play()  --// THIS SOUND EFFECT WILL ONLY PLAY WHEN THE PLAYER HIT ANOTHER PLAYER
			end
		end)
		
		task.delay(.2, function()  ------// THIS WILL GET RID OF THE HITBOX AFTER 200 MILISECONDS
			punchHitBox:Destroy()
		end)
	end
end

--// THIS FUNCTION IS THE BIG PUNCH MECHANIC, IT TAKES IN 2 PARAMETERS, PLAYER AND SERVERSIDE
--// SERVERSIDE: ITS A BOOLEAN THAT TURNS TRUE IF IT WAS CALLED FROM THE SERVER (HELPS WITH TELLING THE SERVER THAT A HITBOX WAS CREATED)

function module.BigPunch(player,ServerSide)
	local char = player.Character
	local hrp = char:WaitForChild('HumanoidRootPart')
	local hum = char:WaitForChild('Humanoid')
	local Animator = hum:WaitForChild('Animator')
	local BigPunchAnimation = Instance.new('Animation')
	BigPunchAnimation.AnimationId = 'rbxassetid://78855943263077'  --// SETS UP THE ANIMATION
	if hrp then
		local heavyPunch = true  -----------------------------// DEFINES THE FUNCTION AS A HEAVY PUNCH
		local bodyvelocity = Instance.new('BodyVelocity')
		bodyvelocity.MaxForce = Vector3.new(1e6,1e6,1e6)  --// THIS LOCKS THE PLAYER SO THEY DON'T FALL
		bodyvelocity.Velocity = Vector3.new(0,0,0)  --// THIS MAKES THE PLAYER UNABLE TO MOVE WHEN THE MECHANIC IS TRIGGERED
		bodyvelocity.Parent = hrp
		
		local punchHitBox = Instance.new('Part') --// THIS BLOCK OF CODE CREATES THE HITBOX
		punchHitBox.Size = Vector3.new(5.5, 5, 20)
		punchHitBox.CanCollide = false
		punchHitBox.Anchored = false
		punchHitBox.Transparency = .5
		punchHitBox.Color = Color3.fromRGB(255, 0, 0)
		punchHitBox.CFrame = hrp.CFrame * CFrame.new(0,0,-punchHitBox.Size.Z/2)  --// THIS GETS THE PLAYERS POSITION AND PLACES THE HITBOX INFRONT OF THE PLAYER
		punchHitBox:AddTag('DamagePlayer') --// MAKES THE HITBOX ABLE TO DAMAGE PLAYERS
		
		punchHitBox.Parent = workspace
		
		local weld = Instance.new('WeldConstraint')  --// THIS WELDS THE HTIBOX TO THE PLAYER SO THERE ARE NO ISSUES
		weld.Part0 = hrp
		weld.Part1 = punchHitBox
		weld.Parent = punchHitBox
		
		punchHitBox.Touched:Connect(function(hit)  ---------// DETECTS IF SOMETHING TOUCHED THE HITBOX
			if hit.Parent:HasTag('DamagePlayer') and hitplayer == true then  --// SAME LOGIC AS THE PUNCH MECHANIC
				module.PlayerHitting(hit,nil,heavyPunch) --// PASSES ON THE HEAVYPUNCH PARAMETER SO THE PLAYERHITTING MODULE KNOWS ITS A HEAVYPUNCH
			end
		end)
		if ServerSide then          --------------// CHECKS IF ITS THE SERVER... THIS IS JUST SO WHEN DEBUGGING YOU DON'T SEE TWO HITBOXES
			punchHitBox.Transparency = 1
			Soundserv.BigPunch_SFX:Play() --// PLAYS THE BIB PUNCH SOUND EFFECT
		end
		Animator:LoadAnimation(BigPunchAnimation):Play() --// PLAYS THE BIGPUNCH ANIMATION
		
		task.delay(1,function()  ------// THIS GETS RID OF THE HITBOX AND THE LOCKED PLAYER SO THEY CAN MOVE AGAIN AFTER 1 SECOND
			punchHitBox:Destroy()  --// HITBOX
			bodyvelocity:Destroy()  --// LOCKED PLAYER
		end)
	end
end

function module.Invisibility(player,Hide,Show)  --// THIS FUNCTION MAKES THE PLAYER INVISIBLE FOR 3 SECONDS, THERE ARE 3 PARAMETERS, player: the player that will be invisible, Hide (BOOLEAN): makes the player invisible, Show(BOOLEAN): makes the player visible
	local char = player.Character
	if Hide then
		Soundserv.Invisibility_sfx:Play()
		for _, Child in ipairs(char:GetDescendants()) do  -----// THIS ITERATES THROUGH THE PLAYERS DESCENDANTS
			if Child:IsA('Part') or Child:IsA('Decal') then --// THIS MAKES EVERY PART AND DECAL INVISIBLE
				Child.Transparency = 1
			elseif Child:IsA('Accessory') then  --// THIS HIDES THE PLAYER'S ACCESSORIES
				Child.Handle.Transparency = 1
			end
		end
	elseif Show then
		for _, Child in ipairs(char:GetDescendants()) do  ---// THIS IS THE EXACT SAME LOGIC AS THE PREVIOUS BLOCK OF CODE BUT ITS THE OPPOSITE
			if Child:IsA('Part') or Child:IsA('Decal') then
				if Child.Name == 'HumanoidRootPart' then  --// CHECKS IF THE PART OR DECAL IS THE HUMANOID ROOT PART IF IT IS THEN HIDE IT
					Child.Transparency = 1
				else
					Child.Transparency = 0
				end
			elseif Child:IsA('Accessory') then
				Child.Handle.Transparency = 0
			end
		end
	end
end

function module.SpawnCheese(player)  -----------------------// THIS FUNCTION MAKES THE PLAYER ABLE TO SPAWN CHEESE
	local char = player.Character
	local hrp = char:FindFirstChild('HumanoidRootPart')
	if hrp then
		local Cheese = replicatedstorage.Cheese:Clone()  -------// THIS CLONES THE CHEESE MODEL 
		Cheese.Position = hrp.Position + Vector3.new(0,5,0)  ------// MAKES THE CHEESE SPAWN ON TOP OF THE PLAYER
		Cheese:AddTag('DamagePlayer') ------------------------// MAKES IT ABLE TO DAMAGE OTHER PLAYERS
		Cheese.Parent = workspace      ---// THIS LINE SENDS THE CLONED CHEESE MODEL TO THE WORKSPACE SO PLAYER CAN SEE IT
		Soundserv.Cheese_sfx:Play()
		
		Cheese.Touched:Connect(function(hit)     -------------------------------// DETECTS IF THE CHEESE HAS BEEN TOUCHED
			if hit.Parent:HasTag('DamagePlayer') and hitplayer == true then
				local heavyPunch = true
				module.PlayerHitting(hit,nil,heavyPunch)  ---// CALL THE PLAYERHITTING MODULE
			end
		end)
		Debris:AddItem(Cheese,5)  --// GETS RID OF THE CHEESE 5 SECONDS AFTER SPAWNING THE CHEESE
	end
end

function module.PlayerHitting(hit, lightPunch, heavyPunch)  --// THIS FUNCTION IS THE PLAYER DAMAGING FUNCTION, IT TAKES 3 PARAMETERS: hit (ENEMY/PLAYER), lightpunch (BOOLEAN) and heavypunch (BOOLEAN)
	local target = hit.Parent --// ENEMY'S CHARACTER
	if hitplayer then
		if target.Humanoid and lightPunch then  --// CHECKS IF THE PUNCH IS A LIGHTPUNCH AND ALSO CHECK IF THE ENEMY HAS A HUMANOID JUST FOR GOOD MEASURE
			target.Humanoid:TakeDamage(10)  -----------// DAMAGE THE ENEMY
		elseif target.Humanoid and heavyPunch then  --// CHECKS IF ITS A HEAVYPUNCH
			target.Humanoid:TakeDamage(100)  -------// INSTAKILLS THE ENEMY
		end
		task.spawn(function()   ---// THIS HELPS WITH PLAYERS NOT DYING INSTANTLY BY ADDING A COOLDOWN TO THE HITBOXES WHEN TOUCHED
			hitplayer = false
			task.wait(.5)
			hitplayer = true
		end)
	end
end

function module.LockPlayerControls(Lock, Unlock)  --// THIS FUNCTIONS LOCKS THE PLAYER, IT MAKES THE PLAYER UNABLE TO MOVE OR DO ANYTHING AT ALL, IT TAKE IN 2 PARAMETERS: lock (BOOLEAN) and unlock (BOOLEAN), THIS MODULE IS CALLED FROM A LOCAL SCRIPT
	if Lock then     -----------------------// CHECK IF THE ORDER GIVEN IS LOCK
		contextactionservice:BindAction( --// THIS ENABLES THE DEV TO OVERWRITE CERTAIN PLAYER MOVEMENTS
			'PausePlayer',  ----------------------------------------// THIS IS THE BIND NAME
			function() return Enum.ContextActionResult.Sink end,  --// ENUM.CONTEXTACTIONRESULT.SINK BASICALLY BLOCKS WHATEVER YOU WANT TO BLOCK, IN THIS CASE IT WILL BE MOVEMENT
			false,  -----------------------------------// THIS ASKS YOU IF YOU WANT TO CREATE A TOUCHBUTTON
			unpack(Enum.PlayerActions:GetEnumItems())  ---------// THIS WILL BLOCK ANY MOVEMENT FROM THE PLAYER, BASICALLY THE PLAYER WILL BE FROZEN
		)
	elseif Unlock then  -----------------// CHECK IF THE ORDER GIVEN IS UNLOCK
		contextactionservice:UnbindAction('PausePlayer')  --// THIS MAKES THE PLAYER ABLE TO MOVE AGAIN, IT BASICALLY TURNS OFF THE BINDACTION
	end
end

return module  --// END OF MODULE
