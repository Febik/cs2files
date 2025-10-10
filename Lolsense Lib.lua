-- GUI Library for Roblox Executor
-- By: AI Assistant

local GUI = {}
GUI.__index = GUI

-- Configuration
GUI.WindowSize = Vector2.new(850, 650)
GUI.TabButtonSize = Vector2.new(120, 30)
GUI.SectionSize = Vector2.new(200, 400)
GUI.ColorPickerSize = 150
GUI.ConfigWindowSize = Vector2.new(400, 500)

-- Colors
GUI.Colors = {
    Background = Color3.fromRGB(30, 30, 40),
    Header = Color3.fromRGB(45, 45, 55),
    TabActive = Color3.fromRGB(65, 105, 225),
    TabInactive = Color3.fromRGB(50, 50, 60),
    Button = Color3.fromRGB(65, 105, 225),
    ButtonHover = Color3.fromRGB(75, 115, 235),
    Slider = Color3.fromRGB(65, 105, 225),
    Checkbox = Color3.fromRGB(65, 105, 225),
    Text = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(200, 200, 200),
    Line = Color3.fromRGB(60, 60, 70)
}

-- Storage
GUI.Instances = {}
GUI.Tabs = {}
GUI.CurrentTab = nil
GUI.Configs = {}
GUI.Visible = false
GUI.ToggleBind = Enum.KeyCode.Insert

-- Utility functions
local function Create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

local function Tween(object, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = game:GetService("TweenService"):Create(object, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Main GUI Creation
function GUI:CreateWindow(title)
    -- ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Name = "ExecutorGUI",
        DisplayOrder = 10
    })
    
    -- Main Frame
    local MainFrame = Create("Frame", {
        Parent = ScreenGui,
        Size = UDim2.new(0, self.WindowSize.X, 0, self.WindowSize.Y),
        Position = UDim2.new(0.5, -self.WindowSize.X/2, 0.5, -self.WindowSize.Y/2),
        BackgroundColor3 = self.Colors.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    
    -- Header
    local Header = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0
    })
    
    local Title = Create("TextLabel", {
        Parent = Header,
        Size = UDim2.new(0, 200, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "Executor GUI",
        TextColor3 = self.Colors.Text,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    -- Close Button
    local CloseButton = Create("TextButton", {
        Parent = Header,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0.5, -15),
        BackgroundColor3 = Color3.fromRGB(220, 60, 60),
        BorderSizePixel = 0,
        Text = "X",
        TextColor3 = self.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold
    })
    
    CloseButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)
    
    -- Tabs Container
    local TabsContainer = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundTransparency = 1
    })
    
    local UIListLayout = Create("UIListLayout", {
        Parent = TabsContainer,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 5)
    })
    
    -- Content Area
    local ContentArea = Create("Frame", {
        Parent = MainFrame,
        Size = UDim2.new(1, -20, 1, -100),
        Position = UDim2.new(0, 10, 0, 90),
        BackgroundTransparency = 1
    })
    
    -- Store instances
    self.Instances.ScreenGui = ScreenGui
    self.Instances.MainFrame = MainFrame
    self.Instances.TabsContainer = TabsContainer
    self.Instances.ContentArea = ContentArea
    
    -- Bind toggle key
    self:SetupToggleBind()
    
    return self
end

-- Toggle Bind Setup
function GUI:SetupToggleBind()
    local UserInputService = game:GetService("UserInputService")
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == self.ToggleBind then
            self:Toggle()
        end
    end)
end

function GUI:SetToggleBind(keyCode)
    self.ToggleBind = keyCode
end

-- Toggle GUI Visibility
function GUI:Toggle()
    self.Visible = not self.Visible
    self.Instances.ScreenGui.Enabled = self.Visible
end

-- Tab System
function GUI:CreateTab(name)
    local tab = {}
    tab.Name = name
    tab.Buttons = {}
    
    -- Tab Button
    local TabButton = Create("TextButton", {
        Parent = self.Instances.TabsContainer,
        Size = UDim2.new(0, self.TabButtonSize.X, 0, self.TabButtonSize.Y),
        BackgroundColor3 = #self.Tabs == 0 and self.Colors.TabActive or self.Colors.TabInactive,
        BorderSizePixel = 0,
        Text = name,
        TextColor3 = self.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham
    })
    
    -- Tab Content
    local TabContent = Create("ScrollingFrame", {
        Parent = self.Instances.ContentArea,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Colors.Line,
        Visible = #self.Tabs == 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    
    local ContentLayout = Create("UIListLayout", {
        Parent = TabContent,
        Padding = UDim.new(0, 10)
    })
    
    tab.Button = TabButton
    tab.Content = TabContent
    
    TabButton.MouseButton1Click:Connect(function()
        self:SwitchTab(tab)
    end)
    
    table.insert(self.Tabs, tab)
    
    if #self.Tabs == 1 then
        self.CurrentTab = tab
    end
    
    return tab
end

function GUI:SwitchTab(tab)
    if self.CurrentTab == tab then return end
    
    -- Update current tab appearance
    if self.CurrentTab then
        Tween(self.CurrentTab.Button, {BackgroundColor3 = self.Colors.TabInactive})
        self.CurrentTab.Content.Visible = false
    end
    
    -- Set new tab
    self.CurrentTab = tab
    Tween(tab.Button, {BackgroundColor3 = self.Colors.TabActive})
    tab.Content.Visible = true
end

-- UI Elements
function GUI:CreateSection(tab, name)
    local section = {}
    
    local SectionFrame = Create("Frame", {
        Parent = tab.Content,
        Size = UDim2.new(1, -20, 0, 0),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    local SectionTitle = Create("TextLabel", {
        Parent = SectionFrame,
        Size = UDim2.new(1, -20, 0, 30),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = self.Colors.Text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local SectionContent = Create("Frame", {
        Parent = SectionFrame,
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 10, 0, 35),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y
    })
    
    local ContentLayout = Create("UIListLayout", {
        Parent = SectionContent,
        Padding = UDim.new(0, 8)
    })
    
    section.Frame = SectionFrame
    section.Content = SectionContent
    
    return section
end

function GUI:CreateLine(tab)
    local Line = Create("Frame", {
        Parent = tab.Content,
        Size = UDim2.new(1, -20, 0, 1),
        BackgroundColor3 = self.Colors.Line,
        BorderSizePixel = 0
    })
    
    return Line
end

-- Slider
function GUI:CreateSlider(section, text, min, max, default, callback)
    local slider = {}
    slider.Value = default or min
    
    local SliderFrame = Create("Frame", {
        Parent = section.Content,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1
    })
    
    local TextLabel = Create("TextLabel", {
        Parent = SliderFrame,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local ValueLabel = Create("TextButton", {
        Parent = SliderFrame,
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0,
        Text = tostring(default or min),
        TextColor3 = self.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham
    })
    
    local SliderTrack = Create("Frame", {
        Parent = SliderFrame,
        Size = UDim2.new(1, -70, 0, 4),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = self.Colors.Line,
        BorderSizePixel = 0
    })
    
    local SliderFill = Create("Frame", {
        Parent = SliderTrack,
        Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = self.Colors.Slider,
        BorderSizePixel = 0
    })
    
    local SliderButton = Create("TextButton", {
        Parent = SliderTrack,
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8),
        BackgroundColor3 = self.Colors.Text,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 2
    })
    
    -- Value editing
    local ValueTextBox = Create("TextBox", {
        Parent = SliderFrame,
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundColor3 = self.Colors.Button,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = self.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        Visible = false,
        PlaceholderText = "Enter value"
    })
    
    ValueLabel.MouseButton1Click:Connect(function()
        ValueLabel.Visible = false
        ValueTextBox.Visible = true
        ValueTextBox:CaptureFocus()
    end)
    
    ValueTextBox.FocusLost:Connect(function(enterPressed)
        local value = tonumber(ValueTextBox.Text)
        if value then
            value = math.clamp(value, min, max)
            slider.Value = value
            ValueLabel.Text = tostring(value)
            ValueTextBox.Text = ""
            if callback then callback(value) end
            
            -- Update slider position
            local ratio = (value - min) / (max - min)
            SliderFill.Size = UDim2.new(ratio, 0, 1, 0)
            SliderButton.Position = UDim2.new(ratio, -8, 0.5, -8)
        end
        
        ValueTextBox.Visible = false
        ValueLabel.Visible = true
    end)
    
    -- Slider dragging
    local function UpdateSlider(xPosition)
        local trackAbsolutePosition = SliderTrack.AbsolutePosition.X
        local trackAbsoluteSize = SliderTrack.AbsoluteSize.X
        local relativeX = math.clamp(xPosition - trackAbsolutePosition, 0, trackAbsoluteSize)
        local ratio = relativeX / trackAbsoluteSize
        local value = math.floor(min + (max - min) * ratio)
        
        slider.Value = value
        ValueLabel.Text = tostring(value)
        SliderFill.Size = UDim2.new(ratio, 0, 1, 0)
        SliderButton.Position = UDim2.new(ratio, -8, 0.5, -8)
        
        if callback then callback(value) end
    end
    
    SliderButton.MouseButton1Down:Connect(function()
        local connection
        connection = game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                UpdateSlider(input.Position.X)
            end
        end)
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
            end
        end)
    end)
    
    SliderTrack.MouseButton1Down:Connect(function(x, y)
        UpdateSlider(x)
    end)
    
    return slider
end

-- Checkbox
function GUI:CreateCheckbox(section, text, default, callback)
    local checkbox = {}
    checkbox.Value = default or false
    
    local CheckboxFrame = Create("Frame", {
        Parent = section.Content,
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1
    })
    
    local CheckboxButton = Create("TextButton", {
        Parent = CheckboxFrame,
        Size = UDim2.new(0, 20, 0, 20),
        BackgroundColor3 = checkbox.Value and self.Colors.Checkbox or self.Colors.Header,
        BorderSizePixel = 0,
        Text = checkbox.Value and "✓" or "",
        TextColor3 = self.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold
    })
    
    local CheckboxLabel = Create("TextLabel", {
        Parent = CheckboxFrame,
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 25, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    CheckboxButton.MouseButton1Click:Connect(function()
        checkbox.Value = not checkbox.Value
        CheckboxButton.BackgroundColor3 = checkbox.Value and self.Colors.Checkbox or self.Colors.Header
        CheckboxButton.Text = checkbox.Value and "✓" or ""
        
        if callback then callback(checkbox.Value) end
    end)
    
    return checkbox
end

-- Button
function GUI:CreateButton(section, text, callback)
    local button = {}
    
    local Button = Create("TextButton", {
        Parent = section.Content,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Colors.Button,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = self.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham
    })
    
    Button.MouseEnter:Connect(function()
        Tween(Button, {BackgroundColor3 = self.Colors.ButtonHover})
    end)
    
    Button.MouseLeave:Connect(function()
        Tween(Button, {BackgroundColor3 = self.Colors.Button})
    end)
    
    Button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return button
end

-- Color Picker (Simplified circular version)
function GUI:CreateColorPicker(section, text, default, callback)
    local colorPicker = {}
    colorPicker.Value = default or Color3.new(1, 1, 1)
    
    local ColorFrame = Create("Frame", {
        Parent = section.Content,
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1
    })
    
    local TextLabel = Create("TextLabel", {
        Parent = ColorFrame,
        Size = UDim2.new(1, -60, 0, 20),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local ColorButton = Create("TextButton", {
        Parent = ColorFrame,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -45, 0, 10),
        BackgroundColor3 = colorPicker.Value,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 2
    })
    
    -- Make it circular
    local UICorner = Create("UICorner", {
        Parent = ColorButton,
        CornerRadius = UDim.new(1, 0)
    })
    
    -- Color picker popup
    local ColorPopup = Create("Frame", {
        Parent = ColorFrame,
        Size = UDim2.new(0, self.ColorPickerSize, 0, self.ColorPickerSize + 40),
        Position = UDim2.new(1, 10, 0, 0),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 10
    })
    
    local ColorWheel = Create("ImageLabel", {
        Parent = ColorPopup,
        Size = UDim2.new(0, self.ColorPickerSize, 0, self.ColorPickerSize),
        BackgroundTransparency = 1,
        Image = "rbxassetid://14204231522", -- Color wheel image
        ZIndex = 11
    })
    
    local BrightnessSlider = Create("Frame", {
        Parent = ColorPopup,
        Size = UDim2.new(0, self.ColorPickerSize, 0, 20),
        Position = UDim2.new(0, 0, 0, self.ColorPickerSize + 10),
        BackgroundColor3 = self.Colors.Line,
        BorderSizePixel = 0,
        ZIndex = 11
    })
    
    local BrightnessFill = Create("Frame", {
        Parent = BrightnessSlider,
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 12
    })
    
    local BrightnessButton = Create("TextButton", {
        Parent = BrightnessSlider,
        Size = UDim2.new(0, 6, 0, 24),
        Position = UDim2.new(1, -3, 0.5, -12),
        BackgroundColor3 = self.Colors.Text,
        BorderSizePixel = 0,
        Text = "",
        ZIndex = 13
    })
    
    ColorButton.MouseButton1Click:Connect(function()
        ColorPopup.Visible = not ColorPopup.Visible
    end)
    
    -- Simplified color selection (actual color wheel implementation would be more complex)
    ColorWheel.MouseButton1Down:Connect(function(x, y)
        local absolutePosition = ColorWheel.AbsolutePosition
        local absoluteSize = ColorWheel.AbsoluteSize
        
        local relativeX = math.clamp(x - absolutePosition.X, 0, absoluteSize.X)
        local relativeY = math.clamp(y - absolutePosition.Y, 0, absoluteSize.Y)
        
        local hue = relativeX / absoluteSize.X
        local saturation = 1 - (relativeY / absoluteSize.Y)
        
        colorPicker.Value = Color3.fromHSV(hue, saturation, 1)
        ColorButton.BackgroundColor3 = colorPicker.Value
        
        if callback then callback(colorPicker.Value) end
    end)
    
    return colorPicker
end

-- Keybind
function GUI:CreateKeybind(section, text, default, callback)
    local keybind = {}
    keybind.Value = default or Enum.KeyCode.Unknown
    keybind.Mode = "Toggle" -- Toggle, Hold, Always, Off
    
    local KeybindFrame = Create("Frame", {
        Parent = section.Content,
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1
    })
    
    local KeybindLabel = Create("TextLabel", {
        Parent = KeybindFrame,
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local KeybindButton = Create("TextButton", {
        Parent = KeybindFrame,
        Size = UDim2.new(0, 80, 0, 20),
        Position = UDim2.new(0, 110, 0, 0),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0,
        Text = tostring(default and default.Name or "None"),
        TextColor3 = self.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham
    })
    
    local ModeButton = Create("TextButton", {
        Parent = KeybindFrame,
        Size = UDim2.new(0, 60, 0, 20),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0,
        Text = keybind.Mode,
        TextColor3 = self.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham
    })
    
    local listening = false
    
    KeybindButton.MouseButton1Click:Connect(function()
        if not listening then
            listening = true
            KeybindButton.Text = "..."
            KeybindButton.BackgroundColor3 = self.Colors.Button
            
            local connection
            connection = game:GetService("UserInputService").InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    keybind.Value = input.KeyCode
                    KeybindButton.Text = input.KeyCode.Name
                    KeybindButton.BackgroundColor3 = self.Colors.Header
                    listening = false
                    connection:Disconnect()
                end
            end)
        end
    end)
    
    ModeButton.MouseButton2Click:Connect(function()
        local modes = {"Always", "Off", "Toggle", "Hold"}
        local currentIndex = table.find(modes, keybind.Mode) or 1
        local nextIndex = (currentIndex % #modes) + 1
        keybind.Mode = modes[nextIndex]
        ModeButton.Text = keybind.Mode
    end)
    
    return keybind
end

-- Dropdown
function GUI:CreateDropdown(section, text, options, default, multi, callback)
    local dropdown = {}
    dropdown.Value = multi and {} or nil
    dropdown.Multi = multi or false
    
    local DropdownFrame = Create("Frame", {
        Parent = section.Content,
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1
    })
    
    local DropdownLabel = Create("TextLabel", {
        Parent = DropdownFrame,
        Size = UDim2.new(0, 100, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Colors.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left
    })
    
    local DropdownButton = Create("TextButton", {
        Parent = DropdownFrame,
        Size = UDim2.new(0, 150, 0, 25),
        Position = UDim2.new(0, 110, 0, 0),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0,
        Text = default or "Select...",
        TextColor3 = self.Colors.Text,
        TextSize = 12,
        Font = Enum.Font.Gotham
    })
    
    local DropdownList = Create("ScrollingFrame", {
        Parent = DropdownFrame,
        Size = UDim2.new(0, 150, 0, 0),
        Position = UDim2.new(0, 110, 0, 30),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        Visible = false,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    
    local ListLayout = Create("UIListLayout", {
        Parent = DropdownList,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    DropdownButton.MouseButton1Click:Connect(function()
        DropdownList.Visible = not DropdownList.Visible
        DropdownList.Size = UDim2.new(0, 150, 0, math.min(#options * 25, 125))
    end)
    
    for i, option in ipairs(options) do
        local OptionButton = Create("TextButton", {
            Parent = DropdownList,
            Size = UDim2.new(1, 0, 0, 25),
            BackgroundColor3 = self.Colors.Header,
            BorderSizePixel = 0,
            Text = option,
            TextColor3 = self.Colors.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham
        })
        
        OptionButton.MouseButton1Click:Connect(function()
            if multi then
                if table.find(dropdown.Value, option) then
                    table.remove(dropdown.Value, table.find(dropdown.Value, option))
                    OptionButton.BackgroundColor3 = self.Colors.Header
                else
                    table.insert(dropdown.Value, option)
                    OptionButton.BackgroundColor3 = self.Colors.Button
                end
                
                DropdownButton.Text = #dropdown.Value > 0 and table.concat(dropdown.Value, ", ") or "Select..."
            else
                dropdown.Value = option
                DropdownButton.Text = option
                DropdownList.Visible = false
                OptionButton.BackgroundColor3 = self.Colors.Button
            end
            
            if callback then callback(dropdown.Value) end
        end)
    end
    
    return dropdown
end

-- Configuration System
function GUI:CreateConfigSystem()
    local configTab = self:CreateTab("Configs")
    local configSection = self:CreateSection(configTab, "Configuration Manager")
    
    -- Config list
    local ConfigList = Create("ScrollingFrame", {
        Parent = configSection.Content,
        Size = UDim2.new(1, 0, 0, 200),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    
    local ConfigListLayout = Create("UIListLayout", {
        Parent = ConfigList,
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    -- Config description
    local DescriptionFrame = Create("Frame", {
        Parent = configSection.Content,
        Size = UDim2.new(1, 0, 0, 100),
        BackgroundColor3 = self.Colors.Header,
        BorderSizePixel = 0
    })
    
    local DescriptionLabel = Create("TextLabel", {
        Parent = DescriptionFrame,
        Size = UDim2.new(1, -20, 1, -20),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = "Select a config to view description",
        TextColor3 = self.Colors.TextSecondary,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top
    })
    
    -- Buttons
    local ButtonFrame = Create("Frame", {
        Parent = configSection.Content,
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1
    })
    
    local CreateButton = self:CreateButton({Content = ButtonFrame}, "Create", function()
        self:ShowCreateConfigPopup()
    end)
    
    local LoadButton = self:CreateButton({Content = ButtonFrame}, "Load", function()
        -- Load config implementation
    end)
    
    local SaveButton = self:CreateButton({Content = ButtonFrame}, "Save", function()
        -- Save config implementation
    end)
    
    local RefreshButton = self:CreateButton({Content = ButtonFrame}, "Refresh", function()
        self:RefreshConfigList(ConfigList, DescriptionLabel)
    end)
    
    -- Arrange buttons horizontally
    local ButtonLayout = Create("UIListLayout", {
        Parent = ButtonFrame,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 5)
    })
    
    -- Initial refresh
    self:RefreshConfigList(ConfigList, DescriptionLabel)
    
    return {
        Refresh = function() self:RefreshConfigList(ConfigList, DescriptionLabel) end
    }
end

function GUI:ShowCreateConfigPopup()
    -- Implementation for creating new configs
    print("Create config popup would appear here")
end

function GUI:RefreshConfigList(configList, descriptionLabel)
    -- Clear existing config buttons
    for _, child in ipairs(configList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    -- Add config buttons (placeholder)
    local placeholderConfigs = {
        {Name = "Default Config", Description = "Default configuration settings", Author = "System"},
        {Name = "PVP Config", Description = "Optimized for player vs player combat", Author = "Community"},
        {Name = "Farming Config", Description = "Settings for efficient resource farming", Author = "You"}
    }
    
    for _, config in ipairs(placeholderConfigs) do
        local ConfigButton = Create("TextButton", {
            Parent = configList,
            Size = UDim2.new(1, -10, 0, 30),
            Position = UDim2.new(0, 5, 0, 0),
            BackgroundColor3 = self.Colors.Header,
            BorderSizePixel = 0,
            Text = config.Name,
            TextColor3 = self.Colors.Text,
            TextSize = 12,
            Font = Enum.Font.Gotham
        })
        
        local DeleteButton = Create("TextButton", {
            Parent = ConfigButton,
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -25, 0.5, -10),
            BackgroundColor3 = Color3.fromRGB(220, 60, 60),
            BorderSizePixel = 0,
            Text = "X",
            TextColor3 = self.Colors.Text,
            TextSize = 10,
            Font = Enum.Font.GothamBold,
            Visible = false
        })
        
        ConfigButton.MouseEnter:Connect(function()
            DeleteButton.Visible = true
        end)
        
        ConfigButton.MouseLeave:Connect(function()
            DeleteButton.Visible = false
        end)
        
        ConfigButton.MouseButton1Click:Connect(function()
            descriptionLabel.Text = string.format("Config: %s\n\nDescription: %s\n\nAuthor: %s", 
                config.Name, config.Description, config.Author)
        end)
        
        DeleteButton.MouseButton1Click:Connect(function()
            ConfigButton:Destroy()
            descriptionLabel.Text = "Select a config to view description"
        end)
    end
end

-- Initialize GUI
function GUI:Init()
    if self.Instances.ScreenGui then
        self.Instances.ScreenGui:Destroy()
    end
    
    self:CreateWindow("Roblox Executor GUI")
    self:CreateConfigSystem()
    
    -- Example usage
    local mainTab = self:CreateTab("Main")
    local combatSection = self:CreateSection(mainTab, "Combat")
    
    self:CreateSlider(combatSection, "Aimbot FOV", 1, 360, 120, function(value)
        print("Aimbot FOV set to:", value)
    end)
    
    self:CreateCheckbox(combatSection, "Enable Aimbot", false, function(value)
        print("Aimbot:", value)
    end)
    
    self:CreateKeybind(combatSection, "Aimbot Key", Enum.KeyCode.Q, function()
        print("Aimbot keybind pressed")
    end)
    
    self:CreateLine(mainTab)
    
    local visualSection = self:CreateSection(mainTab, "Visuals")
    
    self:CreateDropdown(visualSection, "ESP Type", {"Box", "Tracer", "Name", "Health"}, "Box", false, function(value)
        print("ESP Type:", value)
    end)
    
    self:CreateColorPicker(visualSection, "ESP Color", Color3.new(1, 0, 0), function(value)
        print("ESP Color:", value)
    end)
    
    self:CreateButton(visualSection, "Apply Settings", function()
        print("Settings applied!")
    end)
    
    self.Visible = true
    self.Instances.ScreenGui.Parent = game:GetService("CoreGui")
    
    return self
end

return GUI
