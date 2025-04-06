--[[
    ESP Module
    Handles all ESP drawing and logic
]]

local ESP = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Variables
local Camera = nil
local LocalPlayer = nil
local Utilities = loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/RobloxESP/main/modules/Utilities.lua"))()

-- Drawing objects for each player
local PlayerDrawings = {}

-- Initialize ESP
function ESP.Init(config, camera, localPlayer)
    Camera = camera
    LocalPlayer = localPlayer
    
    -- Clear any existing drawings when reinitializing
    ESP.ClearDrawings()
end

-- Update ESP for all players
function ESP.Update(players, config)
    -- Remove drawings for players who left
    for player, drawings in pairs(PlayerDrawings) do
        if not table.find(players, player) then
            ESP.RemoveDrawingsForPlayer(player)
        end
    end
    
    -- Update drawings for current players
    for _, player in pairs(players) do
        if player ~= LocalPlayer then
            ESP.UpdatePlayerESP(player, config)
        end
    end
end

-- Update ESP for a specific player
function ESP.UpdatePlayerESP(player, config)
    -- Get character and root part
    local character = player.Character
    if not character then
        ESP.RemoveDrawingsForPlayer(player)
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then
        ESP.RemoveDrawingsForPlayer(player)
        return
    end
    
    -- Check if player is too far
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    if distance > config.MaxDistance then
        ESP.RemoveDrawingsForPlayer(player)
        return
    end
    
    -- Team check
    if config.TeamCheck and player.Team == LocalPlayer.Team then
        ESP.RemoveDrawingsForPlayer(player)
        return
    end
    
    -- Create drawings if they don't exist
    if not PlayerDrawings[player] then
        PlayerDrawings[player] = ESP.CreateDrawingsForPlayer()
    end
    
    -- Get player's weapon, vehicle, and other info
    local weaponInfo = Utilities.GetPlayerWeapon(character)
    local vehicleInfo = Utilities.GetPlayerVehicle(character)
    local teamInfo = Utilities.GetPlayerTeam(player)
    
    -- Get player color
    local playerColor = config.BoxColor
    if config.TeamColor and player.Team then
        playerColor = player.Team.TeamColor.Color
    end
    
    -- Update box ESP (2D or 3D)
    if config.BoxEnabled or config.Box3DEnabled then
        ESP.UpdateBoxESP(player, character, playerColor, config)
    else
        PlayerDrawings[player].Box.Visible = false
        -- Hide 3D box lines if they exist
        if PlayerDrawings[player].Box3D then
            for _, line in pairs(PlayerDrawings[player].Box3D) do
                line.Visible = false
            end
        end
    end
    
    -- Update name ESP
    if config.NameEnabled then
        ESP.UpdateNameESP(player, character, playerColor, config)
    else
        PlayerDrawings[player].Name.Visible = false
    end
    
    -- Update information ESP (weapon, team, vehicle, distance)
    if config.WeaponEnabled or config.TeamEnabled or config.VehicleEnabled or config.DistanceEnabled then
        ESP.UpdateInfoESP(player, character, weaponInfo, teamInfo, vehicleInfo, distance, playerColor, config)
    else
        PlayerDrawings[player].Info.Visible = false
    end
    
    -- Update chams
    if config.ChamsEnabled then
        ESP.UpdateChams(player, character, playerColor, config)
    else
        ESP.RemoveChams(player)
    end
end

-- Create drawing objects for a player
function ESP.CreateDrawingsForPlayer()
    local drawings = {}
    
    -- Box ESP (2D)
    drawings.Box = Drawing.new("Square")
    drawings.Box.Thickness = 1
    drawings.Box.Filled = false
    drawings.Box.Visible = false
    
    -- Name ESP
    drawings.Name = Drawing.new("Text")
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Visible = false
    
    -- Info ESP
    drawings.Info = Drawing.new("Text")
    drawings.Info.Center = true
    drawings.Info.Outline = true
    drawings.Info.Visible = false
    
    -- Chams
    drawings.Chams = {}
    
    -- 3D Box (created when needed)
    drawings.Box3D = {}
    
    return drawings
end

-- Update 2D/3D box ESP
function ESP.UpdateBoxESP(player, character, color, config)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    
    if not rootPart or not humanoid then return end
    
    -- Get player size
    local size = Utilities.GetPlayerSize(character)
    
    if config.Box3DEnabled then
        -- Update 3D box
        ESP.Update3DBox(player, rootPart, size, color, config)
        -- Hide 2D box
        PlayerDrawings[player].Box.Visible = false
    else
        -- Update 2D box
        ESP.Update2DBox(player, rootPart, size, color, config)
        -- Hide 3D box if it exists
        if PlayerDrawings[player].Box3D then
            for _, line in pairs(PlayerDrawings[player].Box3D) do
                line.Visible = false
            end
        end
    end
end

-- Update 2D box
function ESP.Update2DBox(player, rootPart, size, color, config)
    local boxDrawing = PlayerDrawings[player].Box
    
    -- Calculate corners of the character's bounding box
    local cornerPositions = Utilities.GetBoundingBox(rootPart.CFrame, size)
    
    -- Get screen positions of corners
    local screenCorners = {}
    for _, position in pairs(cornerPositions) do
        local screenPos, onScreen = Utilities.WorldToScreen(position)
        if screenPos then
            table.insert(screenCorners, screenPos)
        end
    end
    
    -- Calculate 2D bounding box from screen corners
    if #screenCorners > 0 then
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        
        for _, point in pairs(screenCorners) do
            minX = math.min(minX, point.X)
            minY = math.min(minY, point.Y)
            maxX = math.max(maxX, point.X)
            maxY = math.max(maxY, point.Y)
        end
        
        -- Update box properties
        boxDrawing.Position = Vector2.new(minX, minY)
        boxDrawing.Size = Vector2.new(maxX - minX, maxY - minY)
        boxDrawing.Color = color
        boxDrawing.Transparency = 1 - config.BoxTransparency
        boxDrawing.Visible = true
    else
        boxDrawing.Visible = false
    end
end

-- Update 3D box
function ESP.Update3DBox(player, rootPart, size, color, config)
    -- Create 3D box lines if they don't exist
    if not PlayerDrawings[player].Box3D or #PlayerDrawings[player].Box3D == 0 then
        for i = 1, 12 do -- 12 edges in a 3D box
            PlayerDrawings[player].Box3D[i] = Drawing.new("Line")
            PlayerDrawings[player].Box3D[i].Thickness = 1
            PlayerDrawings[player].Box3D[i].Visible = false
        end
    end
    
    -- Calculate corners of the character's bounding box
    local cornerPositions = Utilities.GetBoundingBox(rootPart.CFrame, size)
    
    -- Define the edges of the 3D box (pairs of corner indices)
    local edges = {
        {1, 2}, {2, 3}, {3, 4}, {4, 1}, -- Bottom face
        {5, 6}, {6, 7}, {7, 8}, {8, 5}, -- Top face
        {1, 5}, {2, 6}, {3, 7}, {4, 8}  -- Connecting edges
    }
    
    -- Draw each edge
    for i, edge in ipairs(edges) do
        local point1, onScreen1 = Utilities.WorldToScreen(cornerPositions[edge[1]])
        local point2, onScreen2 = Utilities.WorldToScreen(cornerPositions[edge[2]])
        
        if point1 and point2 and (onScreen1 or onScreen2) then
            PlayerDrawings[player].Box3D[i].From = point1
            PlayerDrawings[player].Box3D[i].To = point2
            PlayerDrawings[player].Box3D[i].Color = color
            PlayerDrawings[player].Box3D[i].Transparency = 1 - config.BoxTransparency
            PlayerDrawings[player].Box3D[i].Visible = true
        else
            PlayerDrawings[player].Box3D[i].Visible = false
        end
    end
end

-- Update name ESP
function ESP.UpdateNameESP(player, character, color, config)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local nameDrawing = PlayerDrawings[player].Name
    
    -- Get head position for name placement
    local head = character:FindFirstChild("Head")
    local position = head and head.Position or (rootPart.Position + Vector3.new(0, 2, 0))
    
    -- Convert world position to screen position
    local screenPos, onScreen = Utilities.WorldToScreen(position)
    
    if screenPos and onScreen then
        nameDrawing.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
        nameDrawing.Text = player.Name
        nameDrawing.Color = config.NameColor
        nameDrawing.Size = config.TextSize
        nameDrawing.Outline = config.NameOutline
        nameDrawing.Visible = true
    else
        nameDrawing.Visible = false
    end
end

-- Update information ESP (weapon, team, vehicle, distance)
function ESP.UpdateInfoESP(player, character, weaponInfo, teamInfo, vehicleInfo, distance, color, config)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local infoDrawing = PlayerDrawings[player].Info
    
    -- Get position for info text placement (below name)
    local head = character:FindFirstChild("Head")
    local position = head and head.Position or (rootPart.Position + Vector3.new(0, 2, 0))
    
    -- Convert world position to screen position
    local screenPos, onScreen = Utilities.WorldToScreen(position)
    
    if screenPos and onScreen then
        -- Build info text
        local infoText = ""
        
        if config.WeaponEnabled and weaponInfo then
            infoText = infoText .. "Weapon: " .. weaponInfo .. "\n"
        end
        
        if config.TeamEnabled and teamInfo then
            infoText = infoText .. "Team: " .. teamInfo .. "\n"
        end
        
        if config.VehicleEnabled then
            infoText = infoText .. "Vehicle: " .. (vehicleInfo or "None") .. "\n"
        end
        
        if config.DistanceEnabled then
            infoText = infoText .. "Distance: " .. math.floor(distance) .. "m"
        end
        
        infoDrawing.Position = Vector2.new(screenPos.X, screenPos.Y - 20)
        infoDrawing.Text = infoText
        infoDrawing.Color = color
        infoDrawing.Size = config.TextSize
        infoDrawing.Visible = true
    else
        infoDrawing.Visible = false
    end
end

-- Update chams (highlighting players through walls)
function ESP.UpdateChams(player, character, color, config)
    -- Remove existing chams
    ESP.RemoveChams(player)
    
    -- Create new chams
    PlayerDrawings[player].Chams = {}
    
    -- Apply chams to character parts
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            -- Create highlight
            local highlight = Instance.new("Highlight")
            highlight.FillColor = color
            highlight.FillTransparency = config.ChamsTransparency
            highlight.OutlineColor = color
            highlight.OutlineTransparency = 0.5
            highlight.Adornee = part
            highlight.Parent = part
            
            -- Add to chams table for this player
            table.insert(PlayerDrawings[player].Chams, highlight)
        end
    end
end

-- Remove chams for a player
function ESP.RemoveChams(player)
    if PlayerDrawings[player] and PlayerDrawings[player].Chams then
        for _, highlight in pairs(PlayerDrawings[player].Chams) do
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
        end
        PlayerDrawings[player].Chams = {}
    end
end

-- Remove all drawings for a player
function ESP.RemoveDrawingsForPlayer(player)
    if not PlayerDrawings[player] then return end
    
    -- Remove 2D box
    if PlayerDrawings[player].Box then
        PlayerDrawings[player].Box:Remove()
    end
    
    -- Remove name
    if PlayerDrawings[player].Name then
        PlayerDrawings[player].Name:Remove()
    end
    
    -- Remove info
    if PlayerDrawings[player].Info then
        PlayerDrawings[player].Info:Remove()
    end
    
    -- Remove 3D box
    if PlayerDrawings[player].Box3D then
        for _, line in pairs(PlayerDrawings[player].Box3D) do
            line:Remove()
        end
    end
    
    -- Remove chams
    ESP.RemoveChams(player)
    
    -- Remove player from drawings table
    PlayerDrawings[player] = nil
end

-- Clear all drawings
function ESP.ClearDrawings()
    for player, _ in pairs(PlayerDrawings) do
        ESP.RemoveDrawingsForPlayer(player)
    end
    PlayerDrawings = {}
end

return ESP
