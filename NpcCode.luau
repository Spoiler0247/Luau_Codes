--Discord -> Spoiler(spoiler0247_20639) // Roblox -> Fortrex(@GameMaker494)

--!strict 
-- Enable strict type checking

--Setup

local npcModel = script.Parent -- Gets the rig
local humanoid = npcModel:WaitForChild("Humanoid") :: Humanoid -- Gets the humanoid inside the rig
local rootPart = npcModel:WaitForChild("HumanoidRootPart") :: BasePart -- Gets the root part of the rig
local Players = game:GetService("Players")-- Enables the use of the Players service
local RunService = game:GetService("RunService")-- Enables the use of the RunService 
local PathfindingService = game:GetService("PathfindingService") -- Enables the use of the PathfindingService
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Enables the use of the ReplicatedStorage service
local DataStoreService = game:GetService("DataStoreService") -- Enables the use of the DataStoreService

local npcData = DataStoreService:GetDataStore("NpcData") -- Gets the DataStore for npc data

local prompt = npcModel:WaitForChild("ProximityPrompt") :: ProximityPrompt  -- Gets the ProximityPrompt inside rig
local npcSettilngsPrompt = npcModel:WaitForChild("SettingsPrompt") :: ProximityPrompt  -- Gets the ProximityPrompt inside rig

local NpcSettingsRemote = ReplicatedStorage:WaitForChild("NpcSettingsRemote") -- Gets the SettingsRemote inside ReplicatedStorage
local NpcSettingsRespondRemote = ReplicatedStorage:WaitForChild("NpcSettingsRespondRemote") -- Gets the SettingsRespondRemote inside ReplicatedStorage
local ResetDataRemote = ReplicatedStorage:WaitForChild("ResetDataRemote") -- Gets the ResetDataRemote inside ReplicatedStorage

local BindableBoxEvent = ReplicatedStorage:WaitForChild("BindableBoxEvent") -- Gets the BindableBoxEvent inside ReplicatedStorage

local debounce = false  -- Creates a variable for debounce

export type Npc = { -- Defining Npc`s properties and their types
	rig: Model,
	Name: string,
	Humanoid: Humanoid,
	RootPart: BasePart,
	Friend: Player?,-- Optional, can be nil
	Inventory: {[string] : number}, -- Optional, can be nil
	ActionTypes: {string},
	Action: string
}

local NameData = "rig" -- Default name for the npc

local success, err = pcall(function() -- checks npc`s name data
	NameData = npcData:GetAsync("Name") 
	npcModel.Name = NameData
end)

if success then
	print(success)
else -- If there is an error, it will print the error and change the name to default
	warn(err) 
	npcModel.Name = "rig"
	NameData = "rig"
end

local npcServise = {} -- Creates a new table for the npcServise

local ActionTypes = {"Follow","PickUp"} -- Table of possible actions

local InventoryData = {} -- Table of the npc`s inventory

local success1, err1 = pcall(function() -- Gets npc`s inventory data
	InventoryData = npcData:GetAsync("Inventory")
end)

if success1 then
	print(success1)
else
	warn(err1)
	InventoryData = {} -- Sets the inventory to an empty table if the data is not found
end

local self = setmetatable({ -- Sets the properties of the new Npc object
	rig = npcModel,
	Name = NameData,
	Humanoid = humanoid,
	RootPart = rootPart,
	Friend = nil,
	Inventory = InventoryData,
	ActionTypes = ActionTypes,
	Action = "Follow"
}, npcServise) :: Npc

--Functions and events


--Follow function
function npcServise.Follow() -- Custom function for npc to follow the player
	assert(self.Friend and self.Friend.Character, "Character not found") -- Check if player has a character
	print("Following")
	
	while task.wait(0.1) do -- Makes the rig follow the player constantly
		if self.Action ~= "Follow" then -- If the npc is not in Follow mode
			return -- Stops the function
		end
		
		local npcPos = self.RootPart.Position -- Gets the position of the npc in the loop
		
		if not npcPos  then -- If npc has no position
			print("Stopped")
			break
		end
		
		local friendChar = self.Friend.Character -- Gets the character of the player
		
		if not friendChar then -- If player has no character
			print("Stopped")
			break
		end
		
		local friendPos = friendChar:GetPivot().Position -- Gets the position of the player
		
		local path = PathfindingService:CreatePath() -- Creates a new path
		
		path:ComputeAsync(npcPos, friendPos) -- Computes the path
		
		local waypoints = path:GetWaypoints() -- Gets the waypoints of the path
		
		if path.Status == Enum.PathStatus.NoPath then -- If path cannot be computed
			print("No path")
			continue -- skips the rest of the loop
		end
		
		
		for _, waypoint in waypoints do -- Loops through the waypoints
			
			if waypoint.Action == Enum.PathWaypointAction.Jump then -- If the waypoint is a jump
				self.Humanoid.Jump = true -- Makes the npc jump
			end
			self.Humanoid:MoveTo(waypoint.Position) -- Moves the npc to the waypoint
			
			if self.Action ~= "Follow" then -- If the npc is not in Follow mode
				return -- Stops the function
			end
			
			if (friendPos - friendChar:GetPivot().Position).Magnitude > 10 then -- If player went to far from its previous positon 
				break	-- Stops the loop so new path can be computed
			end	
		end
	end
end


--PickUp function
function npcServise.PickUp(box: BasePart, player: Player) -- Custom function for npc to pick up objects
	print("PickUp")
	if debounce then return end -- If npc is already going for another object, the call will be ignored
	debounce = true
		
	if self.Action ~= "PickUp" then -- If the npc is not in PickUp mode
		debounce = false
		return -- Stops the current call
	end
	if player == self.Friend then -- Checks if the player is the friend of the npc
		local path = PathfindingService:CreatePath() -- Creates a new path to the object
		path:ComputeAsync(self.rig:GetPivot().Position,box.Position + Vector3.new(1,0,1)) -- Computes the path
		if path.Status == Enum.PathStatus.NoPath then -- If path cannot be computed
			print("No path")
			debounce = false
			return -- Stops the function
		end
	        
		local waypoints = path:GetWaypoints() -- Gets the waypoints of the path
			
		for _, waypoint in waypoints do -- Loops through the waypoints
			if waypoint.Action == Enum.PathWaypointAction.Jump then -- If the waypoint is a jump
				self.Humanoid.Jump = true -- Makes the npc jump
			end
				
			self.Humanoid:MoveTo(waypoint.Position) -- Moves the npc to the waypoint
				
			repeat -- Loops until the npc is close enough to the waypoint, so npc gets to the target faster
				task.wait(0.1)
				local wayDistance = (self.rig:GetPivot().Position - waypoint.Position).Magnitude -- Gets the distance between the npc and the waypoint
					
			if wayDistance < 3 then -- waits for npc to come close enough to the waypoint to move faster
				break -- skips to the next waypoint
			end
					
			until self.Humanoid.MoveToFinished:Wait()
			if (self.rig:GetPivot().Position - box.Position).Magnitude < 10 then -- If the npc is close enough to the object
				box:Destroy() --Picks up the box
				print("Picked up box")
				debounce = false
					
				local success, err = pcall(function() -- Gets npc`s inventory
					self.Inventory = npcData:GetAsync("Inventory") or {}
				end)
					
				if success then
					print("Got Npc Inventory")
				else
					warn(err)
				end
					
				if self.Inventory[box.Name] then 
					self.Inventory[box.Name] += 1 -- Adding to the inventory
				else
					self.Inventory[box.Name] = 1 -- Sets the inventory
				end
					
				local success1, err1 = pcall(function() -- Updating npc`s inventory database
					npcData:SetAsync("Inventory",self.Inventory)
				end)
					
				if success1 then
					print("Updated npc inventory")
				else
					warn(err1)
				end
					
				print(self.Inventory)
				break -- endsthe loop after picking up the object
			end
		end
	end
end


--Rename function
function npcServise.Rename(self: Npc, newName:string) -- Custom function for renaming npc
	self.Name = newName -- Sets the name property of "self"
	self.rig.Name = newName -- Sets the name of the npc
	
	local  success1 , err1 = pcall(function() -- Updating npc`s name database 
		npcData:UpdateAsync("Name",function()
			return newName
		end)
	end)
	
	if success1 then
		print("Updated npc name")
	else
		warn(err1)
	end
	return
end


--Change action function
function npcServise.ChangeAction(newAction: string) -- Custom function for changing npc`s action
	
	assert(table.find(self.ActionTypes,newAction),string.format("%s is not a valid action",newAction)) -- Checking if the action is valid
	
	self.Action = newAction -- Sets the action property of "self"
	if newAction == "Follow" then
		npcServise.Follow(self::Npc) -- Starts the follow function
	end
	print("Action changed".. self.Action)
end


--BindableObjectEvent
BindableBoxEvent.Event:Connect(function(player: Player, box: Part) -- Connects to the event that fires when a player tries to pick up an object
	if self.Action == "PickUp" then -- Checks if the npc is in pick up mode
		npcServise.PickUp(box,player) -- Starts the pick up function
	end
end)


--Activating prompt
prompt.Triggered:Connect(function(player: Player) -- When npc`s activation prompt is triggered
	
	prompt.Enabled = false -- Prevents secondary usage while activated
	npcSettilngsPrompt.Enabled = true -- Enables the npc settings prompt
	
    assert(player.Character, "Character not found") -- Check if player has a character
	
	self.Friend = player
	
	npcServise.Follow(self::Npc) -- Starts the follow function after npc`s activation as default action
end)


--Npc settings prompt
npcSettilngsPrompt.Triggered:Connect(function(player: Player) -- When the npc settings prompt is triggered

	npcSettilngsPrompt.Enabled = false -- Prevents reapeted usage while triggered
	NpcSettingsRemote:FireClient(player :: Player,self.Name,self.Action,self.ActionTypes) -- Sends the settinfs browsing remote to the client
	
end)


-- Respond event
NpcSettingsRespondRemote.OnServerEvent:Connect(function(player :Player,newName: string?,newAction : string) -- Catches the changes made in settings
	npcSettilngsPrompt.Enabled = true -- Re enables the prompt
	if newName and newName ~= self.Name then -- Checks if the name has changed
		npcServise.Rename(self :: Npc, newName :: string) -- Calls the Rename function
	end
	if newAction and newAction ~= self.Action then -- Checks if the action has changed
		npcServise.ChangeAction(newAction :: string) -- Calls the ChangeAction function
	end
end)


--Reset data event
ResetDataRemote.OnServerEvent:Connect(function(player:Player) -- When the reset data remote is fired
	local success1, err1 = pcall(function()
		npcData:UpdateAsync("Inventory",function() -- Resets the inventory data
			self.Inventory = {}
			return {}
		end)
	end)
	
	if success1 then
		print(self.Inventory)
	else
		warn(err1)
	end
	
end)
