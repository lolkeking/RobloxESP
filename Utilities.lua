--[[
    Utilities Module
    Helper functions for the ESP cheat
]]

local Utilities = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Variables
local Camera = workspace.CurrentCamera

-- Convert world position to screen position
function Utilities.WorldToScreen(worldPosition)
    local screenPosition, onScreen = Camera:WorldToScreenPoint(worldPosition)
    return Vector2.new(screenPosition.X, screenPosition.Y), onScreen and screenPosition.Z > 0
end

-- Get bounding box corners from CFrame and Size
function Utilities.GetBoundingBox(cframe, size)
    local corners = {
        -- Bottom corners
        cframe * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2),
        cframe * CFrame.new(size.X/2, -size.Y/2, -size.Z/2),
        cframe * CFrame.new(size.X/2, -size.Y/2, size.Z/2),
        cframe * CFrame.new(-size.X/2, -size.Y/2, size.Z/2),
        
        -- Top corners
        cframe * CFrame.new(-size.X/2, size.Y/2, -size.Z/2),
        cframe * CFrame.new(size.X/2, size.Y/2, -size.Z/2),
        cframe * CFrame.new(size.X/2, size.Y/2, size.Z/2),
        cframe * CFrame.new(-size.X/2, size.Y/2, size.Z/2)
    }
    
    -- Convert CFrame positions to Vector3 positions
    for i, corner in ipairs(corners) do
        corners[i] = corner.Position
    end
    
    return corners
end

-- Get player size from character
function Utilities.GetPlayerSize(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return Vector3.new(4, 6, 2) -- Default size
    end
    
    -- Calculate size based on character parts
    local minX, minY, minZ = math.huge, math.huge, math.huge
    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
    
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") then
            local size = part.Size
            local position = part.Position
            
            minX = math.min(minX, position.X - size.X/2)
            minY = math.min(minY, position.Y - size.Y/2)
            minZ = math.min(minZ, position.Z - size.Z/2)
            
            maxX = math.max(maxX, position.X + size.X/2)
            maxY = math.max(maxY, position.Y + size.Y/2)
            maxZ = math.max(maxZ, position.Z + size.Z/2)
        end
    end
    
    -- Calculate size
    local sizeX = maxX - minX
    local sizeY = maxY - minY
    local sizeZ = maxZ - minZ
    
    -- If we couldn't determine a proper size, use defaults based on character type
    if sizeX <= 0 or sizeY <= 0 or sizeZ <= 0 then
        if humanoid.RigType == Enum.HumanoidRigType.R15 then
            return Vector3.new(4, 6, 2)
        else
            return Vector3.new(3, 5, 2)
        end
    end
    
    return Vector3.new(sizeX, sizeY, sizeZ)
end

-- Get the weapon a player is holding
function Utilities.GetPlayerWeapon(character)
    -- Try to find weapon in character
    for _, item in pairs(character:GetChildren()) do
        -- Common weapon tool names
        if item:IsA("Tool") then
            return item.Name
        end
    end
    
    -- Check if the character has a property or attribute that indicates weapons
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        -- Some games store equipped item in a humanoid attribute
        if humanoid:GetAttribute("EquippedWeapon") then
            return humanoid:GetAttribute("EquippedWeapon")
        end
        
        -- Check for equipped tool
        if humanoid:FindFirstChild("EquippedTool") then
            return humanoid.EquippedTool.Value
        end
    end
    
    -- Check for popular backpack implementations
    local player = Players:GetPlayerFromCharacter(character)
    if player then
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, item in pairs(backpack:GetChildren()) do
                if item:IsA("Tool") and item.Parent == character then
                    return item.Name
                end
            end
        end
    end
    
    return "None"
end

-- Get the vehicle a player is using
function Utilities.GetPlayerVehicle(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return nil
    end
    
    -- Check if player is sitting
    if humanoid.SeatPart and humanoid.SeatPart.Parent then
        local vehicle = humanoid.SeatPart.Parent
        
        -- Try to determine if it's a vehicle or just a seat
        local isVehicle = false
        
        -- Check if it has "Vehicle" in the name
        if vehicle.Name:lower():find("vehicle") or 
           vehicle.Name:lower():find("car") or 
           vehicle.Name:lower():find("bike") or
           vehicle.Name:lower():find("helicopter") or
           vehicle.Name:lower():find("aircraft") or
           vehicle.Name:lower():find("boat") then
            isVehicle = true
        end
        
        -- Check if it has vehicle-related children or properties
        if vehicle:FindFirstChild("Engine") or
           vehicle:FindFirstChild("Wheels") or
           vehicle:FindFirstChild("Body") then
            isVehicle = true
        end
        
        if isVehicle then
            return vehicle.Name
        else
            return "Seat: " .. humanoid.SeatPart.Name
        end
    end
    
    return nil
end

-- Get the team of a player
function Utilities.GetPlayerTeam(player)
    if player.Team then
        return player.Team.Name
    end
    
    -- Some games store team info differently
    if player:GetAttribute("Team") then
        return player:GetAttribute("Team")
    end
    
    -- Check character for team indicators
    local character = player.Character
    if character then
        if character:GetAttribute("Team") then
            return character:GetAttribute("Team")
        end
        
        -- Some games use colored parts to indicate teams
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if torso and torso.Color ~= nil then
            -- Try to determine team based on color
            local color = torso.Color
            if color.R > 0.8 and color.G < 0.2 and color.B < 0.2 then
                return "Red Team"
            elseif color.R < 0.2 and color.G > 0.5 and color.B < 0.2 then
                return "Green Team"
            elseif color.R < 0.2 and color.G < 0.2 and color.B > 0.8 then
                return "Blue Team"
            elseif color.R > 0.8 and color.G > 0.8 and color.B < 0.2 then
                return "Yellow Team"
            end
        end
    end
    
    return "No Team"
end

return Utilities
