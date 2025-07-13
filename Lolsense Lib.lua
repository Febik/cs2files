local UI = {}
UI.__index = UI
-- Конфигурация
UI.Config = {
    MainColor = Color3.fromRGB(35, 35, 45),
    SecondaryColor = Color3.fromRGB(45, 45, 55),
    AccentColor = Color3.fromRGB(100, 70, 200),
    TextColor = Color3.fromRGB(255, 255, 255),
    Font = Enum.Font.Gotham,
    TabSize = UDim2.new(0, 100, 0, 30),
    ElementSize = UDim2.new(0, 200, 0, 30),
    CornerRadius = UDim.new(0, 5)
}

-- Вспомогательные функции
function UI:Create(class, properties)
    local instance = Instance.new(class)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

function UI:RoundedCorners(parent)
    local corner = self:Create("UICorner", {
        Parent = parent,
        CornerRadius = self.Config.CornerRadius
    })
    return corner
end

-- Основное окно
function UI:CreateWindow(title)
    local ScreenGui = self:Create("ScreenGui", {
        Name = "UI_Library",
        ResetOnSpawn = false
    })

    local MainFrame = self:Create("Frame", {
        Parent = ScreenGui,
        Name = "MainFrame",
        Size = UDim2.new(0, 450, 0, 350),
        Position = UDim2.new(0.5, -225, 0.5, -175),
        BackgroundColor3 = self.Config.MainColor,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Active = true,
        Draggable = true
    })
    self:RoundedCorners(MainFrame)

    local Title = self:Create("TextLabel", {
        Parent = MainFrame,
        Name = "Title",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.Config.SecondaryColor,
        Text = title,
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 16
    })
    self:RoundedCorners(Title)

    local CloseButton = self:Create("TextButton", {
        Parent = Title,
        Name = "CloseButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundColor3 = Color3.fromRGB(200, 50, 50),
        Text = "X",
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 16
    })
    self:RoundedCorners(CloseButton)

    local MinimizeButton = self:Create("TextButton", {
        Parent = Title,
        Name = "MinimizeButton",
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -60, 0, 0),
        BackgroundColor3 = self.Config.SecondaryColor,
        Text = "_",
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 16
    })
    self:RoundedCorners(MinimizeButton)

    local TabsHolder = self:Create("Frame", {
        Parent = MainFrame,
        Name = "TabsHolder",
        Size = UDim2.new(1, 0, 0, 40),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundTransparency = 1
    })

    local UIListLayout = self:Create("UIListLayout", {
        Parent = TabsHolder,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 5)
    })

    local ContentHolder = self:Create("ScrollingFrame", {
        Parent = MainFrame,
        Name = "ContentHolder",
        Size = UDim2.new(1, -20, 1, -80),
        Position = UDim2.new(0, 10, 0, 70),
        BackgroundTransparency = 1,
        ScrollBarThickness = 5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
    })

    local ContentLayout = self:Create("UIListLayout", {
        Parent = ContentHolder,
        Padding = UDim.new(0, 10)
    })

    -- Обработчики событий
    local minimized = false
    local originalSize = MainFrame.Size

    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            MainFrame.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 70)
        else
            MainFrame.Size = originalSize
        end
    end)

    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    -- Функции для работы с окном
    function MainFrame:AddTab(name)
        local UI = getfenv().UI -- Получаем доступ к основной UI таблице
    
		local TabButton = UI:Create("TextButton", { -- Используем UI:Create вместо self:Create
			Parent = TabsHolder,
			Name = name .. "Tab",
			Size = UI.Config.TabSize, -- Используем UI.Config
			BackgroundColor3 = UI.Config.SecondaryColor,
			Text = name,
			TextColor3 = UI.Config.TextColor,
			Font = UI.Config.Font,
			TextSize = 14
		})
		UI:RoundedCorners(TabButton) -- Используем UI:RoundedCorners

		local TabContent = UI:Create("Frame", {
			Parent = ContentHolder,
			Name = name .. "Content",
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			Visible = false
		})

		local TabLayout = UI:Create("UIListLayout", {
			Parent = TabContent,
			Padding = UDim.new(0, 10)
		})

        TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.Size = UDim2.new(1, 0, 0, TabLayout.AbsoluteContentSize.Y)
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, child in ipairs(ContentHolder:GetChildren()) do
                if child:IsA("Frame") then
                    child.Visible = false
                end
            end
            TabContent.Visible = true
        end)

        -- Активируем первую вкладку
        if #TabsHolder:GetChildren() == 2 then -- 1 вкладка + UIListLayout
            TabContent.Visible = true
        end

        function TabContent:AddElement(element)
            element.Parent = TabContent
            return element
        end

        return TabContent
    end
	
	 local windowObject = {
        _screenGui = screenGui,
        _mainFrame = mainFrame,
        _tabsHolder = TabsHolder,
        _contentHolder = ContentHolder,
        _tabs = {}
    }
    setmetatable(windowObject, UI)

    -- Добавляем метод AddTab в объект окна
    function windowObject:AddTab(name)
        local tabButton = UI:Create("TextButton", {
            Parent = self._tabsHolder,
            Name = name .. "Tab",
            Size = UI.Config.TabSize,
            BackgroundColor3 = UI.Config.SecondaryColor,
            Text = name,
            TextColor3 = UI.Config.TextColor,
            Font = UI.Config.Font,
            TextSize = 14
        })
        UI:RoundedCorners(tabButton)

        local tabContent = UI:Create("Frame", {
            Parent = self._contentHolder,
            Name = name .. "Content",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Visible = false
        })

        local tabLayout = UI:Create("UIListLayout", {
            Parent = tabContent,
            Padding = UDim.new(0, 10)
        })

        tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabContent.Size = UDim2.new(1, 0, 0, tabLayout.AbsoluteContentSize.Y)
        end)

        tabButton.MouseButton1Click:Connect(function()
            for _, tab in pairs(self._tabs) do
                tab.content.Visible = false
            end
            tabContent.Visible = true
        end)

        -- Сохраняем вкладку для управления
        self._tabs[name] = {
            button = tabButton,
            content = tabContent
        }

        -- Активируем первую вкладку
        if #self._tabsHolder:GetChildren() == 2 then -- 1 вкладка + UIListLayout
            tabContent.Visible = true
        end

        function tabContent:AddElement(element)
            element.Parent = tabContent
            return element
        end

        return tabContent
    end

    -- Обработчики событий кнопок
    MinimizeButton.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            mainFrame.Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, 0, 70)
        else
            mainFrame.Size = originalSize
        end
    end)

    CloseButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    screenGui.Parent = game:GetService("CoreGui")
    return windowObject
end

-- Элементы UI
function UI:CreateButton(text)
    local Button = self:Create("TextButton", {
        Size = self.Config.ElementSize,
        BackgroundColor3 = self.Config.SecondaryColor,
        Text = text,
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        AutoButtonColor = false
    })
    self:RoundedCorners(Button)

    local ButtonStroke = self:Create("UIStroke", {
        Parent = Button,
        Color = self.Config.AccentColor,
        Thickness = 1
    })

    Button.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(Button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(
                self.Config.SecondaryColor.R * 255 + 20,
                self.Config.SecondaryColor.G * 255 + 20,
                self.Config.SecondaryColor.B * 255 + 20
            )
        }):Play()
    end)

    Button.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(Button, TweenInfo.new(0.2), {
            BackgroundColor3 = self.Config.SecondaryColor
        }):Play()
    end)

    Button.MouseButton1Down:Connect(function()
        game:GetService("TweenService"):Create(Button, TweenInfo.new(0.1), {
            BackgroundColor3 = self.Config.AccentColor
        }):Play()
    end)

    Button.MouseButton1Up:Connect(function()
        game:GetService("TweenService"):Create(Button, TweenInfo.new(0.1), {
            BackgroundColor3 = self.Config.SecondaryColor
        }):Play()
    end)

    return Button
end

function UI:CreateCheckBox(text, default)
    local CheckBoxFrame = self:Create("Frame", {
        Size = self.Config.ElementSize,
        BackgroundColor3 = self.Config.SecondaryColor
    })
    self:RoundedCorners(CheckBoxFrame)

    local CheckBox = self:Create("TextButton", {
        Parent = CheckBoxFrame,
        Name = "CheckBox",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(0, 10, 0.5, -10),
        BackgroundColor3 = self.Config.MainColor,
        Text = "",
        AutoButtonColor = false
    })
    self:RoundedCorners(CheckBox)

    local CheckMark = self:Create("ImageLabel", {
        Parent = CheckBox,
        Name = "CheckMark",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://7072718162", -- Галочка
        ImageColor3 = self.Config.AccentColor,
        Visible = default or false
    })

    local Label = self:Create("TextLabel", {
        Parent = CheckBoxFrame,
        Name = "Label",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 40, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local value = default or false

    CheckBox.MouseButton1Click:Connect(function()
        value = not value
        CheckMark.Visible = value
        
        game:GetService("TweenService"):Create(CheckBox, TweenInfo.new(0.1), {
            BackgroundColor3 = value and self.Config.AccentColor or self.Config.MainColor
        }):Play()
    end)

    local CheckBoxAPI = {}
    function CheckBoxAPI:GetValue()
        return value
    end
    function CheckBoxAPI:SetValue(newValue)
        value = newValue
        CheckMark.Visible = value
        CheckBox.BackgroundColor3 = value and self.Config.AccentColor or self.Config.MainColor
    end

    return CheckBoxFrame, CheckBoxAPI
end

function UI:CreateSlider(text, min, max, default, precise)
    local SliderFrame = self:Create("Frame", {
        Size = self.Config.ElementSize,
        BackgroundColor3 = self.Config.SecondaryColor
    })
    self:RoundedCorners(SliderFrame)

    local Label = self:Create("TextLabel", {
        Parent = SliderFrame,
        Name = "Label",
        Size = UDim2.new(1, -10, 0, 20),
        Position = UDim2.new(0, 10, 0, 5),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local ValueLabel = self:Create("TextLabel", {
        Parent = SliderFrame,
        Name = "ValueLabel",
        Size = UDim2.new(0, 50, 0, 20),
        Position = UDim2.new(1, -60, 0, 5),
        BackgroundTransparency = 1,
        Text = tostring(default or min),
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right
    })

    local SliderTrack = self:Create("Frame", {
        Parent = SliderFrame,
        Name = "SliderTrack",
        Size = UDim2.new(1, -20, 0, 5),
        Position = UDim2.new(0, 10, 0, 30),
        BackgroundColor3 = self.Config.MainColor
    })
    self:RoundedCorners(SliderTrack)

    local SliderFill = self:Create("Frame", {
        Parent = SliderTrack,
        Name = "SliderFill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = self.Config.AccentColor
    })
    self:RoundedCorners(SliderFill)

    local SliderButton = self:Create("TextButton", {
        Parent = SliderTrack,
        Name = "SliderButton",
        Size = UDim2.new(0, 15, 0, 15),
        Position = UDim2.new(0, 0, 0.5, -7.5),
        BackgroundColor3 = self.Config.AccentColor,
        Text = "",
        AutoButtonColor = false
    })
    self:RoundedCorners(SliderButton)

    local value = math.clamp(default or min, min, max)
    local sliding = false

    local function updateSlider(val)
        value = precise and val or math.floor(val)
        local ratio = (value - min) / (max - min)
        SliderFill.Size = UDim2.new(ratio, 0, 1, 0)
        SliderButton.Position = UDim2.new(ratio, -7.5, 0.5, -7.5)
        ValueLabel.Text = tostring(value)
    end

    updateSlider(value)

    SliderButton.MouseButton1Down:Connect(function()
        sliding = true
    end)

    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = game:GetService("Players").LocalPlayer:GetMouse().X
            local absolutePos = SliderTrack.AbsolutePosition.X
            local absoluteSize = SliderTrack.AbsoluteSize.X
            
            local ratio = math.clamp((mousePos - absolutePos) / absoluteSize, 0, 1)
            local newValue = min + (max - min) * ratio
            updateSlider(newValue)
        end
    end)

    local SliderAPI = {}
    function SliderAPI:GetValue()
        return value
    end
    function SliderAPI:SetValue(newValue)
        updateSlider(math.clamp(newValue, min, max))
    end

    return SliderFrame, SliderAPI
end

function UI:CreateDropDown(text, options, default)
    local DropDownFrame = self:Create("Frame", {
        Size = self.Config.ElementSize,
        BackgroundColor3 = self.Config.SecondaryColor,
        ClipsDescendants = true
    })
    self:RoundedCorners(DropDownFrame)

    local DropDownButton = self:Create("TextButton", {
        Parent = DropDownFrame,
        Name = "DropDownButton",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = self.Config.SecondaryColor,
        Text = text .. ": " .. (options[default or 1] or ""),
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false
    })
    self:RoundedCorners(DropDownButton)

    local DropDownList = self:Create("ScrollingFrame", {
        Parent = DropDownFrame,
        Name = "DropDownList",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 35),
        BackgroundColor3 = self.Config.MainColor,
        ScrollBarThickness = 5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false
    })
    self:RoundedCorners(DropDownList)

    local ListLayout = self:Create("UIListLayout", {
        Parent = DropDownList,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        DropDownList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end)

    for i, option in ipairs(options) do
        local OptionButton = self:Create("TextButton", {
            Parent = DropDownList,
            Name = "Option" .. i,
            Size = UDim2.new(1, -10, 0, 25),
            Position = UDim2.new(0, 5, 0, (i-1)*30),
            BackgroundColor3 = self.Config.SecondaryColor,
            Text = option,
            TextColor3 = self.Config.TextColor,
            Font = self.Config.Font,
            TextSize = 14,
            AutoButtonColor = false
        })
        self:RoundedCorners(OptionButton)

        OptionButton.MouseButton1Click:Connect(function()
            DropDownButton.Text = text .. ": " .. option
            value = option
            DropDownList.Visible = false
            DropDownFrame.Size = self.Config.ElementSize
        end)

        OptionButton.MouseEnter:Connect(function()
            game:GetService("TweenService"):Create(OptionButton, TweenInfo.new(0.1), {
                BackgroundColor3 = self.Config.AccentColor
            }):Play()
        end)

        OptionButton.MouseLeave:Connect(function()
            game:GetService("TweenService"):Create(OptionButton, TweenInfo.new(0.1), {
                BackgroundColor3 = self.Config.SecondaryColor
            }):Play()
        end)
    end

    local value = options[default or 1]
    local expanded = false

    DropDownButton.MouseButton1Click:Connect(function()
        expanded = not expanded
        DropDownList.Visible = expanded
        
        if expanded then
            local contentSize = #options * 30 + 5
            local maxSize = math.min(contentSize, 150)
            DropDownFrame.Size = UDim2.new(self.Config.ElementSize.X.Scale, self.Config.ElementSize.X.Offset, 0, 35 + maxSize)
            DropDownList.Size = UDim2.new(1, 0, 0, maxSize)
        else
            DropDownFrame.Size = self.Config.ElementSize
        end
    end)

    local DropDownAPI = {}
    function DropDownAPI:GetValue()
        return value
    end
    function DropDownAPI:SetValue(newValue)
        if table.find(options, newValue) then
            value = newValue
            DropDownButton.Text = text .. ": " .. newValue
        end
    end

    return DropDownFrame, DropDownAPI
end

function UI:CreateComboBox(text, options, default)
    local ComboBoxFrame = self:Create("Frame", {
        Size = self.Config.ElementSize,
        BackgroundColor3 = self.Config.SecondaryColor
    })
    self:RoundedCorners(ComboBoxFrame)

    local ComboBox = self:Create("TextBox", {
        Parent = ComboBoxFrame,
        Name = "ComboBox",
        Size = UDim2.new(1, -40, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = self.Config.MainColor,
        Text = options[default or 1] or "",
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        ClearTextOnFocus = false
    })
    self:RoundedCorners(ComboBox)

    local DropButton = self:Create("TextButton", {
        Parent = ComboBoxFrame,
        Name = "DropButton",
        Size = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -30, 0, 0),
        BackgroundColor3 = self.Config.AccentColor,
        Text = "▼",
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        AutoButtonColor = false
    })
    self:RoundedCorners(DropButton)

    local DropDownList = self:Create("ScrollingFrame", {
        Parent = ComboBoxFrame,
        Name = "DropDownList",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 1, 5),
        BackgroundColor3 = self.Config.MainColor,
        ScrollBarThickness = 5,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        ZIndex = 2
    })
    self:RoundedCorners(DropDownList)

    local ListLayout = self:Create("UIListLayout", {
        Parent = DropDownList,
        SortOrder = Enum.SortOrder.LayoutOrder
    })

    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        DropDownList.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y)
    end)

    for i, option in ipairs(options) do
        local OptionButton = self:Create("TextButton", {
            Parent = DropDownList,
            Name = "Option" .. i,
            Size = UDim2.new(1, -10, 0, 25),
            Position = UDim2.new(0, 5, 0, (i-1)*30),
            BackgroundColor3 = self.Config.SecondaryColor,
            Text = option,
            TextColor3 = self.Config.TextColor,
            Font = self.Config.Font,
            TextSize = 14,
            AutoButtonColor = false,
            ZIndex = 3
        })
        self:RoundedCorners(OptionButton)

        OptionButton.MouseButton1Click:Connect(function()
            ComboBox.Text = option
            DropDownList.Visible = false
        end)

        OptionButton.MouseEnter:Connect(function()
            game:GetService("TweenService"):Create(OptionButton, TweenInfo.new(0.1), {
                BackgroundColor3 = self.Config.AccentColor
            }):Play()
        end)

        OptionButton.MouseLeave:Connect(function()
            game:GetService("TweenService"):Create(OptionButton, TweenInfo.new(0.1), {
                BackgroundColor3 = self.Config.SecondaryColor
            }):Play()
        end)
    end

    local expanded = false

    DropButton.MouseButton1Click:Connect(function()
        expanded = not expanded
        DropDownList.Visible = expanded
        DropDownList.Size = UDim2.new(1, 0, 0, math.min(#options * 30 + 5, 150))
    end)

    ComboBox.FocusLost:Connect(function()
        if not table.find(options, ComboBox.Text) then
            ComboBox.Text = options[default or 1]
        end
    end)

    local ComboBoxAPI = {}
    function ComboBoxAPI:GetValue()
        return ComboBox.Text
    end
    function ComboBoxAPI:SetValue(newValue)
        if table.find(options, newValue) then
            ComboBox.Text = newValue
        end
    end

    return ComboBoxFrame, ComboBoxAPI
end

function UI:CreateColorPicker(text, defaultColor)
    local ColorPickerFrame = self:Create("Frame", {
        Size = self.Config.ElementSize,
        BackgroundColor3 = self.Config.SecondaryColor
    })
    self:RoundedCorners(ColorPickerFrame)

    local Label = self:Create("TextLabel", {
        Parent = ColorPickerFrame,
        Name = "Label",
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local ColorPreview = self:Create("Frame", {
        Parent = ColorPickerFrame,
        Name = "ColorPreview",
        Size = UDim2.new(0.5, -5, 1, -10),
        Position = UDim2.new(0.5, 5, 0, 5),
        BackgroundColor3 = defaultColor or Color3.new(1, 1, 1)
    })
    self:RoundedCorners(ColorPreview)

    local ColorPickerWindow = self:Create("Frame", {
        Parent = ColorPickerFrame,
        Name = "ColorPickerWindow",
        Size = UDim2.new(0, 200, 0, 200),
        Position = UDim2.new(1, 5, 0, 0),
        BackgroundColor3 = self.Config.MainColor,
        Visible = false,
        ZIndex = 2
    })
    self:RoundedCorners(ColorPickerWindow)

    local ColorSpectrum = self:Create("ImageLabel", {
        Parent = ColorPickerWindow,
        Name = "ColorSpectrum",
        Size = UDim2.new(0, 180, 0, 180),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        Image = "rbxassetid://14204231522", -- Палитра цветов
        ZIndex = 3
    })
    self:RoundedCorners(ColorSpectrum)

    local ColorSelector = self:Create("Frame", {
        Parent = ColorSpectrum,
        Name = "ColorSelector",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0.5, -5, 0.5, -5),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 2,
        BorderColor3 = Color3.new(1, 1, 1),
        ZIndex = 4
    })
    self:RoundedCorners(ColorSelector)

    local BrightnessSlider = self:Create("Frame", {
        Parent = ColorPickerWindow,
        Name = "BrightnessSlider",
        Size = UDim2.new(0, 20, 0, 180),
        Position = UDim2.new(1, -30, 0, 10),
        BackgroundColor3 = Color3.new(0, 0, 0),
        ZIndex = 3
    })
    self:RoundedCorners(BrightnessSlider)

    local BrightnessGradient = self:Create("UIGradient", {
        Parent = BrightnessSlider,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
        }),
        Rotation = 90
    })

    local BrightnessSelector = self:Create("Frame", {
        Parent = BrightnessSlider,
        Name = "BrightnessSelector",
        Size = UDim2.new(1, 0, 0, 5),
        Position = UDim2.new(0, 0, 0.5, -2.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 2,
        BorderColor3 = Color3.new(0, 0, 0),
        ZIndex = 4
    })
    self:RoundedCorners(BrightnessSelector)

    local currentColor = defaultColor or Color3.new(1, 1, 1)
    local brightness = 1
    local pickingColor = false
    local pickingBrightness = false

    local function updateColor()
        local h, s, v = currentColor:ToHSV()
        local newColor = Color3.fromHSV(h, s, brightness)
        ColorPreview.BackgroundColor3 = newColor
        return newColor
    end

    ColorPreview.MouseButton1Click:Connect(function()
        ColorPickerWindow.Visible = not ColorPickerWindow.Visible
    end)

    ColorSpectrum.MouseButton1Down:Connect(function(x, y)
        pickingColor = true
        local absolutePos = ColorSpectrum.AbsolutePosition
        local absoluteSize = ColorSpectrum.AbsoluteSize
        
        local function updateSelector()
            local relativeX = math.clamp(x - absolutePos.X, 0, absoluteSize.X)
            local relativeY = math.clamp(y - absolutePos.Y, 0, absoluteSize.Y)
            
            local h = relativeX / absoluteSize.X
            local s = 1 - (relativeY / absoluteSize.Y)
            currentColor = Color3.fromHSV(h, s, 1)
            
            ColorSelector.Position = UDim2.new(h, -5, 1 - s, -5)
            updateColor()
        end
        
        updateSelector()
        
        local connection
        connection = game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and pickingColor then
                updateSelector()
            end
        end)
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                pickingColor = false
                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end)

    BrightnessSlider.MouseButton1Down:Connect(function(x, y)
        pickingBrightness = true
        local absolutePos = BrightnessSlider.AbsolutePosition
        local absoluteSize = BrightnessSlider.AbsoluteSize
        
        local function updateBrightness()
            local relativeY = math.clamp(y - absolutePos.Y, 0, absoluteSize.Y)
            brightness = 1 - (relativeY / absoluteSize.Y)
            
            BrightnessSelector.Position = UDim2.new(0, 0, 1 - brightness, -2.5)
            updateColor()
        end
        
        updateBrightness()
        
        local connection
        connection = game:GetService("UserInputService").InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and pickingBrightness then
                updateBrightness()
            end
        end)
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                pickingBrightness = false
                if connection then
                    connection:Disconnect()
                end
            end
        end)
    end)

    local ColorPickerAPI = {}
    function ColorPickerAPI:GetValue()
        return updateColor()
    end
    function ColorPickerAPI:SetValue(newColor)
        currentColor = newColor
        brightness = math.max(newColor.R, newColor.G, newColor.B)
        updateColor()
    end

    return ColorPickerFrame, ColorPickerAPI
end

function UI:CreateBind(text, defaultKey)
    local BindFrame = self:Create("Frame", {
        Size = self.Config.ElementSize,
        BackgroundColor3 = self.Config.SecondaryColor
    })
    self:RoundedCorners(BindFrame)

    local Label = self:Create("TextLabel", {
        Parent = BindFrame,
        Name = "Label",
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left
    })

    local BindButton = self:Create("TextButton", {
        Parent = BindFrame,
        Name = "BindButton",
        Size = UDim2.new(0.4, -10, 1, -10),
        Position = UDim2.new(0.6, 5, 0, 5),
        BackgroundColor3 = self.Config.MainColor,
        Text = tostring(defaultKey or Enum.KeyCode.Unknown),
        TextColor3 = self.Config.TextColor,
        Font = self.Config.Font,
        TextSize = 14,
        AutoButtonColor = false
    })
    self:RoundedCorners(BindButton)

    local currentKey = defaultKey or Enum.KeyCode.Unknown
    local listening = false

    BindButton.MouseButton1Click:Connect(function()
        listening = not listening
        if listening then
            BindButton.Text = "..."
            BindButton.BackgroundColor3 = self.Config.AccentColor
        else
            BindButton.Text = tostring(currentKey)
            BindButton.BackgroundColor3 = self.Config.MainColor
        end
    end)

    local connection
    connection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
        if listening and not gameProcessed then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                currentKey = input.KeyCode
                BindButton.Text = tostring(currentKey)
                listening = false
                BindButton.BackgroundColor3 = self.Config.MainColor
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                currentKey = Enum.KeyCode.MouseButton1
                BindButton.Text = "MouseButton1"
                listening = false
                BindButton.BackgroundColor3 = self.Config.MainColor
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                currentKey = Enum.KeyCode.MouseButton2
                BindButton.Text = "MouseButton2"
                listening = false
                BindButton.BackgroundColor3 = self.Config.MainColor
            end
        end
    end)

    local BindAPI = {}
    function BindAPI:GetValue()
        return currentKey
    end
    function BindAPI:SetValue(newKey)
        currentKey = newKey
        BindButton.Text = tostring(newKey)
    end

    return BindFrame, BindAPI
end

return UI
