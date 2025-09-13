-- ===================================================================
-- Network Library (Rewritten from Firelib ( https://github.com/InfernusScripts/Null-Fire/blob/main/Core/Libraries/Network/Main.lua ) )
-- ===================================================================
if getgenv()._NETWORK then return getgenv()._NETWORK end

-- --- Services and State ---
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local isNetworkActive = false
local cooldowns = {} -- Used by fallback functions to prevent spam

local function manipulateSimulationRadius()
	if not isNetworkActive then return end
	
	for _, player in ipairs(Players:GetPlayers()) do
		if player and player ~= LocalPlayer then
			player.MaximumSimulationRadius = 0
		end
	end

	LocalPlayer.MaximumSimulationRadius = math.huge
	LocalPlayer.ReplicationFocus = workspace
end

local function fireProximityPrompt_Fallback(prompt)
	if cooldowns[prompt] then return end
	cooldowns[prompt] = true

    -- 1. Save all the original properties of the prompt.
	local originalParent = prompt.Parent
	local originalMaxDistance = prompt.MaxActivationDistance
	local originalEnabled = prompt.Enabled
	local originalHoldDuration = prompt.HoldDuration
	local originalLineOfSight = prompt.RequiresLineOfSight

    -- 2. Create a temporary, invisible part right in front of the camera.
	local tempPart = Instance.new("Part", workspace)
	tempPart.Transparency = 1
	tempPart.CanCollide = false
	tempPart.Anchored = true
	tempPart.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -3)

    -- 3. Modify the prompt to be easily triggered.
	prompt.Parent = tempPart
	prompt.MaxActivationDistance = math.huge
	prompt.Enabled = true
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false

	RunService.Heartbeat:Wait() -- Wait a frame for changes to apply

    -- 4. Simulate the player pressing and releasing the interact key.
	prompt:InputHoldBegin()
	RunService.Heartbeat:Wait()
	prompt:InputHoldEnd()

	RunService.Heartbeat:Wait() -- Wait a frame for the action to register

    -- 5. Restore all the original properties and clean up.
	if prompt.Parent == tempPart then
		prompt.Parent = originalParent
		prompt.MaxActivationDistance = originalMaxDistance
		prompt.Enabled = originalEnabled
		prompt.HoldDuration = originalHoldDuration
		prompt.RequiresLineOfSight = originalLineOfSight
	end
	tempPart:Destroy()
	
    cooldowns[prompt] = false
end

-- --- Public API ---
local Network = {}

function Network:SetActive(state)
	isNetworkActive = state
	if not state then
		LocalPlayer.ReplicationFocus = nil
		for _, v in ipairs(Players:GetPlayers()) do
			if v then v.MaximumSimulationRadius = 1000 end
		end
	end
end

function Network:FireProximityPrompt(prompt, checkDistance)
    -- Default to checking distance unless specified otherwise
    checkDistance = (checkDistance == nil) and true or false

    if typeof(prompt) ~= "Instance" or not prompt:IsA("ProximityPrompt") then return false end
    
    -- If we are too far away and distance check is on, do nothing.
    if checkDistance and (prompt.Parent:GetPivot().Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude > prompt.MaxActivationDistance then
        return false
    end
    
    -- Try to use the fast, built-in executor function if it exists.
    if fireproximityprompt then
        task.spawn(fireproximityprompt, prompt)
        return true
    end
    
    task.spawn(fireProximityPrompt_Fallback, prompt)
    return true
end

-- --- Initialization ---
RunService.RenderStepped:Connect(manipulateSimulationRadius)

-- Store the library in the global table and return it.
getgenv()._NETWORK = Network
return Network