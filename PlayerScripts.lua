local replicatedstorage = game:GetService('ReplicatedStorage')
local Soundserv = game:GetService('SoundService')
local uis = game:GetService('UserInputService')
local Players = game:GetService("Players")

task.wait(3)

local localplr = Players.LocalPlayer

--// DOUBLE JUMP VARIABLES\\-------

local previousJump = tick()
local isdoublejumping = false
--------------------------------------

repeat task.wait() until workspace.CurrentCamera

local module = require(replicatedstorage:WaitForChild('ModuleScript_1'))
module.TwoDCamera()

replicatedstorage.GetPlayerInputDirection.OnClientInvoke = function()  ----// GET DIRECTION
	if uis:IsKeyDown(Enum.KeyCode.D) then
		return 'D'                           --// RIGHT
	end
	if uis:IsKeyDown(Enum.KeyCode.A) then
		return 'A'                           --// LEFT
	end
end

replicatedstorage.StopPlayerPhysics.OnClientEvent:Connect(function(player,disablePhysics)
	local movement = require(player.PlayerScripts.PlayerModule):GetControls()
	if disablePhysics then
		movement:Disable()
	else
		movement:Enable()
	end
end)

local humanoid = localplr.Character:WaitForChild('Humanoid')  ---// SETUP DOUBLEJUMP
humanoid.StateChanged:Connect(function(oldstate, newstate)
	if newstate == Enum.HumanoidStateType.Landed then
		isdoublejumping = false
	elseif newstate == Enum.HumanoidStateType.Jumping then
		previousJump = tick()
		
	end
end)

local DisableInputs = false

----------// COOLDOWNS \\-------------------

local PunchCooldown = true
local DashCooldown = true


uis.InputBegan:Connect(function(input, gpe)   ----// INPUTS
	if gpe then return end
	local char = localplr.Character
	local hum = char:WaitForChild('Humanoid')
	local hrp = char:WaitForChild('HumanoidRootPart')
	if not DisableInputs and input.KeyCode == Enum.KeyCode.Space then       -------------// DOUBLE JUMP / SPACE
		if tick() - previousJump >= .2 then
			if hum:GetState() == Enum.HumanoidStateType.Freefall and not isdoublejumping then
				isdoublejumping = true
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
				replicatedstorage.DoubleJUmp:FireServer(localplr)
				local Animator = hum:WaitForChild('Animator')
				local DoubleJumpAnimation = Instance.new('Animation')
				DoubleJumpAnimation.AnimationId = 'rbxassetid://139422960728928'
				Animator:LoadAnimation(DoubleJumpAnimation):Play()
				Soundserv.Jump_sfx:Play()
			end
		end
	elseif not DisableInputs and input.UserInputType == Enum.UserInputType.MouseButton1 then   -------// PUNCH / MOUSEBUTTON1
		if not PunchCooldown then return end
		replicatedstorage.PunchHitBox:FireServer(localplr)
		
		task.spawn(function()
			PunchCooldown = false
			task.wait(1)
			PunchCooldown = true
		end)
	elseif not DisableInputs and input.KeyCode == Enum.KeyCode.F then   ---   ---------------// HEAVY PUNCH / F
		if not PunchCooldown then return end
		local Lock = true
		local Unlock = true
		module.BigPunch(localplr)
		module.LockPlayerControls(Lock,nil)
		replicatedstorage.BigPunchHitbox:FireServer(localplr)
		task.spawn(function()
			PunchCooldown = false
			task.wait(1)
			PunchCooldown = true
		end)
		task.delay(1,function()
			module.LockPlayerControls(nil,Unlock)
		end)
	elseif not DisableInputs and input.KeyCode == Enum.KeyCode.E then         ----------// DASH / E
		if not DashCooldown then return end
		module.TriggerDash(hrp,1)
		replicatedstorage.PlayerDashed:FireServer(1)
		
		task.spawn(function()
			DashCooldown = false
			task.wait(1)
			DashCooldown = true
		end)
	elseif not DisableInputs and input.KeyCode == Enum.KeyCode.R then          -----------// INVISIBILITY / R
		module.Invisibility(localplr,true,nil)
		replicatedstorage.Invisibility:FireServer(true,nil)
		
		task.spawn(function()
			DisableInputs = true
			task.wait(3)
			DisableInputs = false
			module.Invisibility(localplr,nil,true)
			replicatedstorage.Invisibility:FireServer(nil,true)
		end)
	elseif not DisableInputs and input.UserInputType == Enum.UserInputType.MouseButton2 then
		module.SpawnCheese(localplr)
	end
end)
