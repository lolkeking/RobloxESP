--[[
    UI Module
    Handles the configuration interface for the ESP cheat
]]

local UI = {}

-- Services
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Variables
local GuiObject = nil
local DraggingUI = false
local DragOffset = Vector2.new(0, 0)
local Config = nil
local Minimized = false

-- UI Colors
local Colors = {
    Background = Color3.fromRGB(25, 25, 25),
    Header = Color3.fromRGB(35, 35, 35),
    Text = Color3.fromRGB(255, 255, 255),
    Accent = Color3.fromRGB(255, 0, 0),
    Button = Color3.fromRGB(45, 45, 45),
    ButtonHover = Color3.fromRGB(55, 55, 55),
    Slider = Color3.fromRGB(65, 65, 65),
    SliderFill = Color3.fromRGB(255, 0, 0),
    Toggle = Color3.fromRGB(45, 45, 45),
    ToggleEnabled = Color3.fromRGB(0, 255, 0)
}

-- Initialize UI
function UI.Init(config)
    Config = config
    
    -- Create UI
    UI.CreateGui()
    
    -- Set up input handlers
    UI.SetupInputHandlers()
    
    return UI
end

-- Create the GUI
function UI.CreateGui()
    -- Check if GUI already exists and remove it
    if GuiObject then
        GuiObject:Destroy()
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESPCheatGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Try to parent to CoreGui, fall back to PlayerGui if not allowed
    local success, err = pcall(function()
        screenGui.Parent = CoreGui
    end)
    
    if not success then
        screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Create main frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    mainFrame.BackgroundColor3 = Colors.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Parent = screenGui
    
    -- Apply corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = mainFrame
    
    -- Create header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundColor3 = Colors.Header
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    -- Apply corner radius to header
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 5)
    headerCorner.Parent = header
    
    -- Create title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -60, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Roblox ESP Cheat"
    title.TextColor3 = Colors.Text
    title.TextSize = 16
    title.Font = Enum.Font.SourceSansBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Create minimize button
    local minimizeButton = Instance.new("TextButton")
    minimizeButton.Name = "MinimizeButton"
    minimizeButton.Size = UDim2.new(0, 25, 0, 25)
    minimizeButton.Position = UDim2.new(1, -60, 0, 2)
    minimizeButton.BackgroundColor3 = Colors.Button
    minimizeButton.Text = "-"
    minimizeButton.TextColor3 = Colors.Text
    minimizeButton.TextSize = 18
    minimizeButton.Font = Enum.Font.SourceSansBold
    minimizeButton.BorderSizePixel = 0
    minimizeButton.Parent = header
    
    -- Apply corner radius to minimize button
    local minimizeCorner = Instance.new("UICorner")
    minimizeCorner.CornerRadius = UDim.new(0, 3)
    minimizeCorner.Parent = minimizeButton
    
    -- Create close button
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 25, 0, 25)
    closeButton.Position = UDim2.new(1, -30, 0, 2)
    closeButton.BackgroundColor3 = Colors.Accent
    closeButton.Text = "X"
    closeButton.TextColor3 = Colors.Text
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.SourceSansBold
    closeButton.BorderSizePixel = 0
    closeButton.Parent = header
    
    -- Apply corner radius to close button
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 3)
    closeCorner.Parent = closeButton
    
    -- Create content frame
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Name = "Content"
    contentFrame.Size = UDim2.new(1, -20, 1, -40)
    contentFrame.Position = UDim2.new(0, 10, 0, 35)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ScrollBarThickness = 5
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 600) -- Will be updated based on content
    contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    contentFrame.Parent = mainFrame
    
    -- Create UI elements for configuration
    UI.CreateConfigElements(contentFrame)
    
    -- Minimize button functionality
    minimizeButton.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        
        if Minimized then
            -- Minimize animation
            local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 300, 0, 30)})
            tween:Play()
            minimizeButton.Text = "+"
            contentFrame.Visible = false
        else
            -- Restore animation
            local tween = TweenService:Create(mainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 300, 0, 400)})
            tween:Play()
            minimizeButton.Text = "-"
            contentFrame.Visible = true
        end
    end)
    
    -- Close button functionality
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
        GuiObject = nil
    end)
    
    -- Store GUI object for later reference
    GuiObject = screenGui
end

-- Create configuration elements
function UI.CreateConfigElements(parent)
    local elementY = 10
    local spacing = 35
    
    -- Main toggle
    UI.CreateCategoryLabel(parent, "Main Settings", elementY)
    elementY = elementY + 25
    
    local mainToggle = UI.CreateToggle(parent, "ESP Enabled", Config.Enabled, elementY)
    mainToggle.Callback = function(value)
        Config.Enabled = value
    end
    elementY = elementY + spacing
    
    -- Box ESP settings
    UI.CreateCategoryLabel(parent, "Box ESP Settings", elementY)
    elementY = elementY + 25
    
    local boxToggle = UI.CreateToggle(parent, "2D Box ESP", Config.BoxEnabled, elementY)
    boxToggle.Callback = function(value)
        Config.BoxEnabled = value
        if value then
            Config.Box3DEnabled = false
            box3DToggle.SetValue(false)
        end
    end
    elementY = elementY + spacing
    
    local box3DToggle = UI.CreateToggle(parent, "3D Box ESP", Config.Box3DEnabled, elementY)
    box3DToggle.Callback = function(value)
        Config.Box3DEnabled = value
        if value then
            Config.BoxEnabled = false
            boxToggle.SetValue(false)
        end
    end
    elementY = elementY + spacing
    
    UI.CreateColorPicker(parent, "Box Color", Config.BoxColor, elementY, function(color)
        Config.BoxColor = color
    end)
    elementY = elementY + spacing
    
    UI.CreateSlider(parent, "Box Transparency", Config.BoxTransparency, 0, 1, 0.1, elementY, function(value)
        Config.BoxTransparency = value
    end)
    elementY = elementY + spacing
    
    -- Name ESP settings
    UI.CreateCategoryLabel(parent, "Name ESP Settings", elementY)
    elementY = elementY + 25
    
    local nameToggle = UI.CreateToggle(parent, "Name ESP", Config.NameEnabled, elementY)
    nameToggle.Callback = function(value)
        Config.NameEnabled = value
    end
    elementY = elementY + spacing
    
    UI.CreateColorPicker(parent, "Name Color", Config.NameColor, elementY, function(color)
        Config.NameColor = color
    end)
    elementY = elementY + spacing
    
    local nameOutlineToggle = UI.CreateToggle(parent, "Name Outline", Config.NameOutline, elementY)
    nameOutlineToggle.Callback = function(value)
        Config.NameOutline = value
    end
    elementY = elementY + spacing
    
    -- Chams settings
    UI.CreateCategoryLabel(parent, "Chams Settings", elementY)
    elementY = elementY + 25
    
    local chamsToggle = UI.CreateToggle(parent, "Chams", Config.ChamsEnabled, elementY)
    chamsToggle.Callback = function(value)
        Config.ChamsEnabled = value
    end
    elementY = elementY + spacing
    
    UI.CreateColorPicker(parent, "Chams Color", Config.ChamsColor, elementY, function(color)
        Config.ChamsColor = color
    end)
    elementY = elementY + spacing
    
    UI.CreateSlider(parent, "Chams Transparency", Config.ChamsTransparency, 0, 1, 0.1, elementY, function(value)
        Config.ChamsTransparency = value
    end)
    elementY = elementY + spacing
    
    -- Information settings
    UI.CreateCategoryLabel(parent, "Information Settings", elementY)
    elementY = elementY + 25
    
    local weaponToggle = UI.CreateToggle(parent, "Show Weapon", Config.WeaponEnabled, elementY)
    weaponToggle.Callback = function(value)
        Config.WeaponEnabled = value
    end
    elementY = elementY + spacing
    
    local teamToggle = UI.CreateToggle(parent, "Show Team", Config.TeamEnabled, elementY)
    teamToggle.Callback = function(value)
        Config.TeamEnabled = value
    end
    elementY = elementY + spacing
    
    local vehicleToggle = UI.CreateToggle(parent, "Show Vehicle", Config.VehicleEnabled, elementY)
    vehicleToggle.Callback = function(value)
        Config.VehicleEnabled = value
    end
    elementY = elementY + spacing
    
    local distanceToggle = UI.CreateToggle(parent, "Show Distance", Config.DistanceEnabled, elementY)
    distanceToggle.Callback = function(value)
        Config.DistanceEnabled = value
    end
    elementY = elementY + spacing
    
    -- Team check settings
    UI.CreateCategoryLabel(parent, "Team Settings", elementY)
    elementY = elementY + 25
    
    local teamCheckToggle = UI.CreateToggle(parent, "Team Check", Config.TeamCheck, elementY)
    teamCheckToggle.Callback = function(value)
        Config.TeamCheck = value
    end
    elementY = elementY + spacing
    
    local teamColorToggle = UI.CreateToggle(parent, "Use Team Colors", Config.TeamColor, elementY)
    teamColorToggle.Callback = function(value)
        Config.TeamColor = value
    end
    elementY = elementY + spacing
    
    -- Misc settings
    UI.CreateCategoryLabel(parent, "Misc Settings", elementY)
    elementY = elementY + 25
    
    UI.CreateSlider(parent, "Maximum Distance", Config.MaxDistance, 100, 2000, 100, elementY, function(value)
        Config.MaxDistance = value
    end)
    elementY = elementY + spacing
    
    UI.CreateSlider(parent, "Text Size", Config.TextSize, 10, 24, 1, elementY, function(value)
        Config.TextSize = value
    end)
    elementY = elementY + spacing
    
    -- Update canvas size based on content
    parent.CanvasSize = UDim2.new(0, 0, 0, elementY + 20)
end

-- Create a category label
function UI.CreateCategoryLabel(parent, text, yPosition)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, yPosition)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Colors.Accent
    label.TextSize = 16
    label.Font = Enum.Font.SourceSansBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    
    return label
end

-- Create a toggle
function UI.CreateToggle(parent, text, initialValue, yPosition)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "Toggle_" .. text
    toggleFrame.Size = UDim2.new(1, 0, 0, 25)
    toggleFrame.Position = UDim2.new(0, 0, 0, yPosition)
    toggleFrame.BackgroundTransparency = 1
    toggleFrame.Parent = parent
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    toggleLabel.Position = UDim2.new(0, 0, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = text
    toggleLabel.TextColor3 = Colors.Text
    toggleLabel.TextSize = 14
    toggleLabel.Font = Enum.Font.SourceSans
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame
    
    local toggleButton = Instance.new("Frame")
    toggleButton.Size = UDim2.new(0, 40, 0, 20)
    toggleButton.Position = UDim2.new(0.8, 0, 0, 2)
    toggleButton.BackgroundColor3 = Colors.Toggle
    toggleButton.BorderSizePixel = 0
    toggleButton.Parent = toggleFrame
    
    -- Apply corner radius
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggleButton
    
    local toggleSwitch = Instance.new("Frame")
    toggleSwitch.Size = UDim2.new(0, 18, 0, 18)
    toggleSwitch.Position = UDim2.new(0, 1, 0, 1)
    toggleSwitch.BackgroundColor3 = Colors.Text
    toggleSwitch.BorderSizePixel = 0
    toggleSwitch.Parent = toggleButton
    
    -- Apply corner radius to switch
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(0, 9)
    switchCorner.Parent = toggleSwitch
    
    -- Set initial value
    local value = initialValue
    
    local function updateToggle()
        if value then
            toggleButton.BackgroundColor3 = Colors.ToggleEnabled
            local tween = TweenService:Create(toggleSwitch, TweenInfo.new(0.2), {Position = UDim2.new(0, 21, 0, 1)})
            tween:Play()
        else
            toggleButton.BackgroundColor3 = Colors.Toggle
            local tween = TweenService:Create(toggleSwitch, TweenInfo.new(0.2), {Position = UDim2.new(0, 1, 0, 1)})
            tween:Play()
        end
    end
    
    updateToggle()
    
    -- Make toggle clickable
    toggleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            value = not value
            updateToggle()
            if toggleFrame.Callback then
                toggleFrame.Callback(value)
            end
        end
    end)
    
    -- Make label clickable too
    toggleLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            value = not value
            updateToggle()
            if toggleFrame.Callback then
                toggleFrame.Callback(value)
            end
        end
    end)
    
    -- Add function to set value programmatically
    toggleFrame.SetValue = function(newValue)
        value = newValue
        updateToggle()
    end
    
    return toggleFrame
end

-- Create a slider
function UI.CreateSlider(parent, text, initialValue, minValue, maxValue, step, yPosition, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Name = "Slider_" .. text
    sliderFrame.Size = UDim2.new(1, 0, 0, 25)
    sliderFrame.Position = UDim2.new(0, 0, 0, yPosition)
    sliderFrame.BackgroundTransparency = 1
    sliderFrame.Parent = parent
    
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(0.5, 0, 1, 0)
    sliderLabel.Position = UDim2.new(0, 0, 0, 0)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = text
    sliderLabel.TextColor3 = Colors.Text
    sliderLabel.TextSize = 14
    sliderLabel.Font = Enum.Font.SourceSans
    sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    sliderLabel.Parent = sliderFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0.15, 0, 1, 0)
    valueLabel.Position = UDim2.new(0.85, 0, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(initialValue)
    valueLabel.TextColor3 = Colors.Text
    valueLabel.TextSize = 14
    valueLabel.Font = Enum.Font.SourceSans
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = sliderFrame
    
    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0.35, 0, 0, 6)
    sliderBg.Position = UDim2.new(0.5, 0, 0.5, 0)
    sliderBg.BackgroundColor3 = Colors.Slider
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = sliderFrame
    
    -- Apply corner radius
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 3)
    bgCorner.Parent = sliderBg
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((initialValue - minValue) / (maxValue - minValue), 0, 1, 0)
    sliderFill.BackgroundColor3 = Colors.SliderFill
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg
    
    -- Apply corner radius to fill
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = sliderFill
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 12, 0, 12)
    sliderButton.Position = UDim2.new((initialValue - minValue) / (maxValue - minValue), -6, 0.5, -6)
    sliderButton.BackgroundColor3 = Colors.Accent
    sliderButton.Text = ""
    sliderButton.BorderSizePixel = 0
    sliderButton.Parent = sliderBg
    
    -- Apply corner radius to button
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = sliderButton
    
    -- Slider functionality
    local dragging = false
    local value = initialValue
    
    local function updateSlider(input)
        local parent = sliderBg.AbsolutePosition
        local size = sliderBg.AbsoluteSize
        local position = math.clamp((input.Position.X - parent.X) / size.X, 0, 1)
        local newValue = minValue + ((maxValue - minValue) * position)
        
        -- Apply step if provided
        if step then
            newValue = math.floor(newValue / step + 0.5) * step
            position = (newValue - minValue) / (maxValue - minValue)
        end
        
        -- Clamp value to min/max
        newValue = math.clamp(newValue, minValue, maxValue)
        
        -- Update slider position and fill
        sliderButton.Position = UDim2.new(position, -6, 0.5, -6)
        sliderFill.Size = UDim2.new(position, 0, 1, 0)
        
        -- Update value label (round to 2 decimal places for display)
        valueLabel.Text = tostring(math.floor(newValue * 100) / 100)
        
        -- Update value and call callback
        value = newValue
        if callback then
            callback(value)
        end
    end
    
    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    sliderButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateSlider(input)
            dragging = true
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateSlider(input)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return sliderFrame
end

-- Create a color picker
function UI.CreateColorPicker(parent, text, initialColor, yPosition, callback)
    local colorFrame = Instance.new("Frame")
    colorFrame.Name = "ColorPicker_" .. text
    colorFrame.Size = UDim2.new(1, 0, 0, 25)
    colorFrame.Position = UDim2.new(0, 0, 0, yPosition)
    colorFrame.BackgroundTransparency = 1
    colorFrame.Parent = parent
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(0.7, 0, 1, 0)
    colorLabel.Position = UDim2.new(0, 0, 0, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = text
    colorLabel.TextColor3 = Colors.Text
    colorLabel.TextSize = 14
    colorLabel.Font = Enum.Font.SourceSans
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.Parent = colorFrame
    
    local colorPreview = Instance.new("Frame")
    colorPreview.Size = UDim2.new(0, 25, 0, 20)
    colorPreview.Position = UDim2.new(0.8, 0, 0, 2)
    colorPreview.BackgroundColor3 = initialColor
    colorPreview.BorderSizePixel = 1
    colorPreview.BorderColor3 = Colors.Text
    colorPreview.Parent = colorFrame
    
    -- Apply corner radius
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 3)
    previewCorner.Parent = colorPreview
    
    -- Create the color picker panel (initially hidden)
    local pickerPanel = Instance.new("Frame")
    pickerPanel.Name = "PickerPanel"
    pickerPanel.Size = UDim2.new(0, 200, 0, 220)
    pickerPanel.Position = UDim2.new(0.5, -100, 0, 30)
    pickerPanel.BackgroundColor3 = Colors.Background
    pickerPanel.BorderSizePixel = 1
    pickerPanel.BorderColor3 = Colors.Accent
    pickerPanel.Visible = false
    pickerPanel.ZIndex = 10
    pickerPanel.Parent = colorFrame
    
    -- Apply corner radius to panel
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 5)
    panelCorner.Parent = pickerPanel
    
    -- Create the basic RGB sliders
    local rgbSliders = {"R", "G", "B"}
    local sliderColors = {
        R = Color3.fromRGB(255, 0, 0),
        G = Color3.fromRGB(0, 255, 0),
        B = Color3.fromRGB(0, 0, 255)
    }
    
    local rgbValues = {
        R = initialColor.R * 255,
        G = initialColor.G * 255,
        B = initialColor.B * 255
    }
    
    local sliderHeight = 25
    
    for i, channel in ipairs(rgbSliders) do
        local slider = Instance.new("Frame")
        slider.Name = channel .. "Slider"
        slider.Size = UDim2.new(0.9, 0, 0, sliderHeight)
        slider.Position = UDim2.new(0.05, 0, 0, 10 + (i-1) * (sliderHeight + 10))
        slider.BackgroundTransparency = 1
        slider.ZIndex = 11
        slider.Parent = pickerPanel
        
        local channelLabel = Instance.new("TextLabel")
        channelLabel.Size = UDim2.new(0.15, 0, 1, 0)
        channelLabel.Position = UDim2.new(0, 0, 0, 0)
        channelLabel.BackgroundTransparency = 1
        channelLabel.Text = channel
        channelLabel.TextColor3 = Colors.Text
        channelLabel.TextSize = 14
        channelLabel.Font = Enum.Font.SourceSans
        channelLabel.ZIndex = 11
        channelLabel.Parent = slider
        
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "Value"
        valueLabel.Size = UDim2.new(0.15, 0, 1, 0)
        valueLabel.Position = UDim2.new(0.85, 0, 0, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(math.floor(rgbValues[channel]))
        valueLabel.TextColor3 = Colors.Text
        valueLabel.TextSize = 14
        valueLabel.Font = Enum.Font.SourceSans
        valueLabel.ZIndex = 11
        valueLabel.Parent = slider
        
        local sliderBg = Instance.new("Frame")
        sliderBg.Size = UDim2.new(0.65, 0, 0, 6)
        sliderBg.Position = UDim2.new(0.2, 0, 0.5, 0)
        sliderBg.BackgroundColor3 = Colors.Slider
        sliderBg.BorderSizePixel = 0
        sliderBg.ZIndex = 11
        sliderBg.Parent = slider
        
        -- Apply corner radius
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 3)
        bgCorner.Parent = sliderBg
        
        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "Fill"
        sliderFill.Size = UDim2.new(rgbValues[channel] / 255, 0, 1, 0)
        sliderFill.BackgroundColor3 = sliderColors[channel]
        sliderFill.BorderSizePixel = 0
        sliderFill.ZIndex = 11
        sliderFill.Parent = sliderBg
        
        -- Apply corner radius
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = sliderFill
        
        local sliderButton = Instance.new("TextButton")
        sliderButton.Size = UDim2.new(0, 12, 0, 12)
        sliderButton.Position = UDim2.new(rgbValues[channel] / 255, -6, 0.5, -6)
        sliderButton.BackgroundColor3 = Colors.Text
        sliderButton.Text = ""
        sliderButton.BorderSizePixel = 0
        sliderButton.ZIndex = 12
        sliderButton.Parent = sliderBg
        
        -- Apply corner radius
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = sliderButton
        
        -- Slider functionality
        local dragging = false
        
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                
                local parent = sliderBg.AbsolutePosition
                local size = sliderBg.AbsoluteSize
                local position = math.clamp((input.Position.X - parent.X) / size.X, 0, 1)
                local channelValue = math.floor(position * 255)
                
                rgbValues[channel] = channelValue
                valueLabel.Text = tostring(channelValue)
                
                sliderButton.Position = UDim2.new(position, -6, 0.5, -6)
                sliderFill.Size = UDim2.new(position, 0, 1, 0)
                
                -- Update color preview
                local newColor = Color3.fromRGB(rgbValues.R, rgbValues.G, rgbValues.B)
                colorPreview.BackgroundColor3 = newColor
                
                if callback then
                    callback(newColor)
                end
            end
        end)
        
        sliderBg.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local parent = sliderBg.AbsolutePosition
                local size = sliderBg.AbsoluteSize
                local position = math.clamp((input.Position.X - parent.X) / size.X, 0, 1)
                local channelValue = math.floor(position * 255)
                
                rgbValues[channel] = channelValue
                valueLabel.Text = tostring(channelValue)
                
                sliderButton.Position = UDim2.new(position, -6, 0.5, -6)
                sliderFill.Size = UDim2.new(position, 0, 1, 0)
                
                -- Update color preview
                local newColor = Color3.fromRGB(rgbValues.R, rgbValues.G, rgbValues.B)
                colorPreview.BackgroundColor3 = newColor
                
                if callback then
                    callback(newColor)
                end
            end
        end)
    end
    
    -- Create preset color buttons
    local presetColors = {
        Color3.fromRGB(255, 0, 0),    -- Red
        Color3.fromRGB(0, 255, 0),    -- Green
        Color3.fromRGB(0, 0, 255),    -- Blue
        Color3.fromRGB(255, 255, 0),  -- Yellow
        Color3.fromRGB(255, 0, 255),  -- Magenta
        Color3.fromRGB(0, 255, 255),  -- Cyan
        Color3.fromRGB(255, 255, 255),-- White
        Color3.fromRGB(0, 0, 0)       -- Black
    }
    
    local presetSize = 20
    local presetGap = 5
    local presetsPerRow = 4
    
    for i, color in ipairs(presetColors) do
        local row = math.floor((i-1) / presetsPerRow)
        local col = (i-1) % presetsPerRow
        
        local presetButton = Instance.new("TextButton")
        presetButton.Size = UDim2.new(0, presetSize, 0, presetSize)
        presetButton.Position = UDim2.new(0.1 + col * (presetSize + presetGap) / 200, 0, 0, 120 + row * (presetSize + presetGap))
        presetButton.BackgroundColor3 = color
        presetButton.Text = ""
        presetButton.BorderSizePixel = 1
        presetButton.BorderColor3 = Colors.Text
        presetButton.ZIndex = 11
        presetButton.Parent = pickerPanel
        
        -- Apply corner radius
        local presetCorner = Instance.new("UICorner")
        presetCorner.CornerRadius = UDim.new(0, 3)
        presetCorner.Parent = presetButton
        
        -- Click functionality
        presetButton.MouseButton1Click:Connect(function()
            colorPreview.BackgroundColor3 = color
            
            -- Update RGB values
            rgbValues.R = color.R * 255
            rgbValues.G = color.G * 255
            rgbValues.B = color.B * 255
            
            -- Update RGB sliders
            for _, channel in ipairs(rgbSliders) do
                local slider = pickerPanel:FindFirstChild(channel .. "Slider")
                if slider then
                    local valueLabel = slider:FindFirstChild("Value")
                    local sliderBg = slider:FindFirstChild("Frame")
                    if valueLabel and sliderBg then
                        valueLabel.Text = tostring(math.floor(rgbValues[channel]))
                        
                        local sliderFill = sliderBg:FindFirstChild("Fill")
                        local sliderButton = sliderBg:FindFirstChild("TextButton")
                        if sliderFill and sliderButton then
                            local position = rgbValues[channel] / 255
                            sliderButton.Position = UDim2.new(position, -6, 0.5, -6)
                            sliderFill.Size = UDim2.new(position, 0, 1, 0)
                        end
                    end
                end
            end
            
            if callback then
                callback(color)
            end
        end)
    end
    
    -- Add apply button
    local applyButton = Instance.new("TextButton")
    applyButton.Size = UDim2.new(0.8, 0, 0, 30)
    applyButton.Position = UDim2.new(0.1, 0, 0, 180)
    applyButton.BackgroundColor3 = Colors.Button
    applyButton.Text = "Apply"
    applyButton.TextColor3 = Colors.Text
    applyButton.TextSize = 14
    applyButton.Font = Enum.Font.SourceSansBold
    applyButton.ZIndex = 11
    applyButton.Parent = pickerPanel
    
    -- Apply corner radius
    local applyCorner = Instance.new("UICorner")
    applyCorner.CornerRadius = UDim.new(0, 5)
    applyCorner.Parent = applyButton
    
    -- Apply button functionality
    applyButton.MouseButton1Click:Connect(function()
        pickerPanel.Visible = false
    end)
    
    -- Toggle color picker visibility when preview is clicked
    colorPreview.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            pickerPanel.Visible = not pickerPanel.Visible
        end
    end)
    
    return colorFrame
end

-- Set up input handlers for UI dragging
function UI.SetupInputHandlers()
    if not GuiObject then return end
    
    local mainFrame = GuiObject:FindFirstChild("MainFrame")
    local header = mainFrame and mainFrame:FindFirstChild("Header")
    
    if not mainFrame or not header then return end
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            DraggingUI = true
            DragOffset = mainFrame.Position - UDim2.new(0, input.Position.X, 0, input.Position.Y)
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            DraggingUI = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if DraggingUI and input.UserInputType == Enum.UserInputType.MouseMovement then
            mainFrame.Position = DragOffset + UDim2.new(0, input.Position.X, 0, input.Position.Y)
        end
    end)
end

-- Update the status text based on enabled state
function UI.UpdateStatus(enabled)
    if not GuiObject then return end
    
    local title = GuiObject.MainFrame.Header.Title
    
    if enabled then
        title.Text = "Roblox ESP Cheat [ON]"
        title.TextColor3 = Color3.fromRGB(0, 255, 0)
    else
        title.Text = "Roblox ESP Cheat [OFF]"
        title.TextColor3 = Color3.fromRGB(255, 0, 0)
    end
end

return UI
