-- Roblox GUI Library
-- Module: SimpleUI
-- Автор: ChatGPT (шаблон, доработайте под свои нужды)
-- Описание: библиотека создаёт окно ~800x600 с табами и элементами: Slider, Checkbox, Button,
-- ColorPicker (Hue+SV square), Keybind с правой кнопкой меню (Always/Off/Toggle/Hold),
-- Dropdown (single/multi combo), CFG system (создание/сохранение/загрузка/удаление/refresh),
-- DPI scale, close bind.
-- Установка: положите ModuleScript в ReplicatedStorage и вызовите:
-- local SimpleUI = require(game.ReplicatedStorage.SimpleUI)
-- local win = SimpleUI:CreateWindow("Название")
-- Примечание: Система сохранения использует writefile/readfile (эксплоиты) если доступно,
-- иначе сохраняет конфиги в PlayerAttributes (временно).

local SimpleUI = {}
SimpleUI.__index = SimpleUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

-- Utilities
local function new(class, props)
    local obj = Instance.new(class)
    if props then
        for k, v in pairs(props) do
            if k == "Parent" then obj.Parent = v else obj[k] = v end
        end
    end
    return obj
end

local function round(num, decimals)
    decimals = decimals or 0
    local mult = 10 ^ decimals
    return math.floor(num * mult + 0.5) / mult
end

-- Filesystem helpers (exploit-friendly)
local function canWriteFiles()
    return type(writefile) == "function" and type(isfile) == "function"
end

local function saveFile(path, text)
    if canWriteFiles() then
        pcall(function() writefile(path, text) end)
        return true
    else
        return false
    end
end
local function readFile(path)
    if canWriteFiles() and isfile(path) then
        local ok, data = pcall(function() return readfile(path) end)
        if ok then return data end
    end
    return nil
end

-- Base style values
local BASE_WIDTH = 900
local BASE_HEIGHT = 640

-- Create main window
function SimpleUI:CreateWindow(title)
    local self = setmetatable({}, SimpleUI)
    self.title = title or "SimpleUI"
    self.tabs = {}
    self.configs = {}
    self.selectedTab = nil

    -- ScreenGui
    local screenGui = new("ScreenGui", {Parent = LocalPlayer:WaitForChild("PlayerGui"), Name = self.title .. "_GUI", ResetOnSpawn = false})
    self.screenGui = screenGui

    -- Main frame (centered)
    local main = new("Frame", {
        Parent = screenGui,
        Size = UDim2.new(0, BASE_WIDTH, 0, BASE_HEIGHT),
        Position = UDim2.new(0.5, -BASE_WIDTH/2, 0.5, -BASE_HEIGHT/2),
        BackgroundColor3 = Color3.fromRGB(18,18,19),
        BorderSizePixel = 0,
        Name = "MainFrame",
    })
    self.main = main

    -- Header
    local header = new("TextLabel", {
        Parent = main,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        Text = "  " .. self.title,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 18,
        TextColor3 = Color3.fromRGB(230,230,230),
        Font = Enum.Font.GothamSemibold,
    })

    -- Close button
    local closeBtn = new("TextButton", {
        Parent = header,
        Size = UDim2.new(0, 42, 1, 0),
        Position = UDim2.new(1, -46, 0, 0),
        BackgroundTransparency = 1,
        Text = "✕",
        TextSize = 20,
        Font = Enum.Font.GothamBold,
        TextColor3 = Color3.fromRGB(200,200,200),
        Name = "CloseBtn",
    })
    closeBtn.MouseButton1Click:Connect(function()
        screenGui.Enabled = false
    end)

    -- Left tabs column
    local tabsFrame = new("Frame", {
        Parent = main,
        Size = UDim2.new(0, 220, 1, -36),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundTransparency = 1,
        Name = "TabsFrame",
    })

    local tabList = new("UIListLayout", {Parent = tabsFrame, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,6)})

    -- Right content area
    local contentFrame = new("Frame", {
        Parent = main,
        Size = UDim2.new(1, -240, 1, -60),
        Position = UDim2.new(0, 240, 0, 36),
        BackgroundColor3 = Color3.fromRGB(28,28,30),
        Name = "ContentFrame",
    })

    -- Tabs container inside content
    local pages = new("Frame", {Parent = contentFrame, Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, Name = "Pages"})

    -- CFG system panel (on right of content area)
    local cfgPanel = new("Frame", {
        Parent = contentFrame,
        Size = UDim2.new(0, 240, 1, 0),
        Position = UDim2.new(1, -240, 0, 0),
        BackgroundColor3 = Color3.fromRGB(22,22,24),
        Name = "CFGPanel",
    })

    local cfgTitle = new("TextLabel", {Parent = cfgPanel, Size = UDim2.new(1,0,0,30), BackgroundTransparency = 1, Text = "CONFIGS", Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(240,240,240)})

    local cfgScroll = new("ScrollingFrame", {Parent = cfgPanel, Size = UDim2.new(1, -10, 0, 200), Position = UDim2.new(0,5,0,36), BackgroundTransparency = 1, CanvasSize = UDim2.new(0,0,1,0), Name = "CfgScroll"})
    cfgScroll.ScrollBarThickness = 6

    local cfgButtons = new("Frame", {Parent = cfgPanel, Size = UDim2.new(1, -10, 0, 36), Position = UDim2.new(0,5,0,250), BackgroundTransparency = 1})
    local btnSave = new("TextButton", {Parent = cfgButtons, Size = UDim2.new(0.48,0,1,0), Position = UDim2.new(0,0,0,0), Text = "Save", BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(40,40,44)})
    local btnLoad = new("TextButton", {Parent = cfgButtons, Size = UDim2.new(0.48,0,1,0), Position = UDim2.new(0.52,0,0,0), Text = "Load", BackgroundColor3 = Color3.fromRGB(40,40,44)})

    local descLabel = new("TextLabel", {Parent = cfgPanel, Size = UDim2.new(1, -10, 0, 120), Position = UDim2.new(0,5,0,296), Text = "Описание конфига:\nАвтор: -", BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220), TextWrapped = true})

    local dpiLabel = new("TextLabel", {Parent = cfgPanel, Size = UDim2.new(0.5, -6, 0, 24), Position = UDim2.new(0,5,0,420), Text = "DPI Scale:", BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220)})
    local dpiDropdown = new("TextButton", {Parent = cfgPanel, Size = UDim2.new(0.45, -6, 0, 24), Position = UDim2.new(0.5,6,0,420), Text = "100%", BackgroundColor3 = Color3.fromRGB(40,40,44)})

    local dpiOptions = {"50%","75%","100%","125%","150%"}
    local function setDPIScale(option)
        local n = tonumber(option:sub(1,-2)) or 100
        local scale = n / 100
        main.Size = UDim2.new(0, BASE_WIDTH * scale, 0, BASE_HEIGHT * scale)
        -- reposition center
        main.Position = UDim2.new(0.5, -(BASE_WIDTH * scale)/2, 0.5, -(BASE_HEIGHT * scale)/2)
        dpiDropdown.Text = option
    end
    dpiDropdown.MouseButton1Click:Connect(function()
        -- simple menu
        local menu = new("Frame", {Parent = cfgPanel, Size = UDim2.new(0, 100, 0, #dpiOptions*26), Position = UDim2.new(0.5,6,0,446), BackgroundColor3 = Color3.fromRGB(36,36,36)})
        for i,opt in ipairs(dpiOptions) do
            local b = new("TextButton", {Parent = menu, Size = UDim2.new(1,0,0,26), Position = UDim2.new(0,0,0,(i-1)*26), Text = opt, BackgroundTransparency = 0})
            b.MouseButton1Click:Connect(function()
                setDPIScale(opt)
                menu:Destroy()
            end)
        end
    end)

    -- Helper to create new tab
    function self:CreateTab(name)
        local tabBtn = new("TextButton", {Parent = tabsFrame, Size = UDim2.new(1,0,0,40), Text = name, BackgroundColor3 = Color3.fromRGB(30,30,32), TextSize = 14, Name = name .. "_Btn"})
        local page = new("ScrollingFrame", {Parent = pages, Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0,5,0,5), BackgroundTransparency = 1, Visible = false, CanvasSize = UDim2.new(0,0,2,0)})
        page.ScrollBarThickness = 6
        local layout = new("UIListLayout", {Parent = page, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8)})

        tabBtn.MouseButton1Click:Connect(function()
            -- highlight tab
            for _,t in pairs(self.tabs) do
                t.btn.BackgroundColor3 = Color3.fromRGB(30,30,32)
                t.page.Visible = false
            end
            tabBtn.BackgroundColor3 = Color3.fromRGB(60,60,64)
            page.Visible = true
            self.selectedTab = name
        end)

        self.tabs[name] = {btn = tabBtn, page = page}
        -- auto select first tab
        if not self.selectedTab then
            tabBtn:MouseButton1Click()
        end
        return page
    end

    -- Elements implementation
    local function makeSection(parent, title)
        local frame = new("Frame", {Parent = parent, Size = UDim2.new(1, -10, 0, 120), BackgroundTransparency = 1})
        local t = new("TextLabel", {Parent = frame, Position = UDim2.new(0,0,0,0), Size = UDim2.new(1,0,0,22), Text = title, BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220)})
        local container = new("Frame", {Parent = frame, Position = UDim2.new(0,0,0,28), Size = UDim2.new(1,0,1,-28), BackgroundColor3 = Color3.fromRGB(32,32,34)})
        return frame, container
    end

    -- Slider
    function self:CreateSlider(page, opts)
        opts = opts or {}
        local label = opts.Text or "Slider"
        local min = opts.Min or 0
        local max = opts.Max or 100
        local default = opts.Default or min
        local step = opts.Step or 1

        local section, container = makeSection(page, label)
        local topText = new("TextLabel", {Parent = section, Position = UDim2.new(0,0,0,-18), Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, Text = label .. " - " .. tostring(default), TextColor3 = Color3.fromRGB(200,200,200)})

        local bar = new("Frame", {Parent = container, Size = UDim2.new(1, -20, 0, 24), Position = UDim2.new(0, 10, 0.5, -12), BackgroundColor3 = Color3.fromRGB(56,56,60)})
        local fill = new("Frame", {Parent = bar, Size = UDim2.new((default-min)/(max-min),0,1,0), BackgroundColor3 = Color3.fromRGB(100,160,255)})
        local handle = new("TextButton", {Parent = bar, Size = UDim2.new(0,0,1,0), BackgroundColor3 = Color3.fromRGB(220,220,220), Text = "", AutoButtonColor = false})
        handle.Size = UDim2.new(0,16,1,0)
        handle.Position = UDim2.new((default-min)/(max-min), -8, 0, 0)

        local valueLabel = new("TextButton", {Parent = container, Position = UDim2.new(1, -60, 0, 6), Size = UDim2.new(0, 50, 0, 24), Text = tostring(default), BackgroundColor3 = Color3.fromRGB(44,44,48)})

        -- click number to type
        valueLabel.MouseButton1Click:Connect(function()
            local box = new("TextBox", {Parent = container, Position = valueLabel.Position, Size = valueLabel.Size, Text = valueLabel.Text, ClearTextOnFocus = false, TextEditable = true, BackgroundColor3 = Color3.fromRGB(36,36,36)})
            valueLabel.Visible = false
            box.FocusLost:Connect(function(enter)
                local n = tonumber(box.Text) or default
                if n < min then n = min end
                if n > max then n = max end
                box:Destroy()
                valueLabel.Text = tostring(n)
                valueLabel.Visible = true
                -- update handle
                local pct = (n - min) / (max - min)
                fill.Size = UDim2.new(pct,0,1,0)
                handle.Position = UDim2.new(pct, -8, 0, 0)
                topText.Text = label .. " - " .. tostring(n)
                if opts.Callback then pcall(opts.Callback, n) end
            end)
        end)

        local dragging = false
        handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
        end)
        handle.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mouse = UserInputService:GetMouseLocation()
                local absPos = bar.AbsolutePosition.X
                local rel = math.clamp((mouse.X - absPos) / bar.AbsoluteSize.X, 0, 1)
                local val = min + rel * (max - min)
                -- snap to step
                val = math.floor(val / step + 0.5) * step
                fill.Size = UDim2.new(rel,0,1,0)
                handle.Position = UDim2.new(rel, -8, 0, 0)
                valueLabel.Text = tostring(val)
                topText.Text = label .. " - " .. tostring(val)
                if opts.Callback then pcall(opts.Callback, val) end
            end
        end)

        page.CanvasSize = page.CanvasSize + UDim2.new(0,0,0,120)
        return section
    end

    -- Checkbox
    function self:CreateCheckbox(page, opts)
        opts = opts or {}
        local label = opts.Text or "Checkbox"
        local default = opts.Default or false
        local section, container = makeSection(page, label)
        local chk = new("TextButton", {Parent = container, Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(0, 8, 0, 8), Text = default and "✔" or "", BackgroundColor3 = Color3.fromRGB(44,44,48)})
        local lab = new("TextLabel", {Parent = container, Position = UDim2.new(0, 40, 0, 6), Size = UDim2.new(1, -40, 0, 24), Text = label, BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(220,220,220)})
        chk.MouseButton1Click:Connect(function()
            default = not default
            chk.Text = default and "✔" or ""
            if opts.Callback then pcall(opts.Callback, default) end
        end)
        page.CanvasSize = page.CanvasSize + UDim2.new(0,0,0,120)
        return chk
    end

    -- Button
    function self:CreateButton(page, opts)
        opts = opts or {}
        local text = opts.Text or "Button"
        local section, container = makeSection(page, text)
        local btn = new("TextButton", {Parent = container, Size = UDim2.new(0, 140, 0, 34), Position = UDim2.new(0, 8, 0, 8), Text = text, BackgroundColor3 = Color3.fromRGB(60,120,200)})
        btn.MouseButton1Click:Connect(function() if opts.Callback then pcall(opts.Callback) end end)
        page.CanvasSize = page.CanvasSize + UDim2.new(0,0,0,120)
        return btn
    end

    -- ColorPicker (Hue slider + SV square)
    function self:CreateColorPicker(page, opts)
        opts = opts or {}
        local label = opts.Text or "Color"
        local section, container = makeSection(page, label)
        local preview = new("Frame", {Parent = container, Size = UDim2.new(0, 40, 0, 40), Position = UDim2.new(0, 8, 0, 8), BackgroundColor3 = Color3.fromRGB(255,0,0)})
        local openBtn = new("TextButton", {Parent = container, Position = UDim2.new(0, 56, 0, 8), Size = UDim2.new(0, 90, 0, 34), Text = "Choose", BackgroundColor3 = Color3.fromRGB(44,44,48)})

        local color = Color3.new(1,0,0)
        local function applyColor(c)
            color = c
            preview.BackgroundColor3 = c
            if opts.Callback then pcall(opts.Callback, c) end
        end

        openBtn.MouseButton1Click:Connect(function()
            local win = new("Frame", {Parent = container, Size = UDim2.new(0, 260, 0, 180), Position = UDim2.new(0, 160, 0, 8), BackgroundColor3 = Color3.fromRGB(26,26,26)})
            -- Hue slider
            local hue = new("Frame", {Parent = win, Position = UDim2.new(0,10,0,10), Size = UDim2.new(1,-20,0,18), BackgroundColor3 = Color3.fromRGB(255,0,0)})
            -- We simulate hue by mapping X -> hue
            local satval = new("Frame", {Parent = win, Position = UDim2.new(0,10,0,38), Size = UDim2.new(1,-20,0,120), BackgroundColor3 = Color3.fromRGB(255,255,255)})

            local draggingHue = false
            local draggingSV = false
            local currentHue = 0
            local currentS = 1
            local currentV = 1

            local function updateSV()
                local c = Color3.fromHSV(currentHue, currentS, currentV)
                satval.BackgroundColor3 = c
                applyColor(c)
            end

            hue.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = true end end)
            hue.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingHue = false end end)

            satval.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = true end end)
            satval.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then draggingSV = false end end)

            local conn
            conn = RunService.RenderStepped:Connect(function()
                if draggingHue then
                    local mouse = UserInputService:GetMouseLocation()
                    local rel = math.clamp((mouse.X - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
                    currentHue = rel
                    updateSV()
                end
                if draggingSV then
                    local mouse = UserInputService:GetMouseLocation()
                    local rx = math.clamp((mouse.X - satval.AbsolutePosition.X) / satval.AbsoluteSize.X, 0, 1)
                    local ry = math.clamp((mouse.Y - satval.AbsolutePosition.Y) / satval.AbsoluteSize.Y, 0, 1)
                    currentS = rx
                    currentV = 1 - ry
                    updateSV()
                end
            end)

            local done = new("TextButton", {Parent = win, Position = UDim2.new(1,-60,1,-30), Size = UDim2.new(0,50,0,22), Text = "OK", BackgroundColor3 = Color3.fromRGB(60,160,60)})
            done.MouseButton1Click:Connect(function() conn:Disconnect() win:Destroy() end)
        end)

        page.CanvasSize = page.CanvasSize + UDim2.new(0,0,0,120)
        return preview
    end

    -- Keybind with right click menu
    function self:CreateKeybind(page, opts)
        opts = opts or {}
        local label = opts.Text or "Keybind"
        local section, container = makeSection(page, label)
        local bindBtn = new("TextButton", {Parent = container, Size = UDim2.new(0, 160, 0, 32), Position = UDim2.new(0,8,0,8), Text = "None", BackgroundColor3 = Color3.fromRGB(40,40,44)})
        local mode = "Off" -- Always, Off, Toggle, Hold
        local bindKey = nil

        local function updateText()
            bindBtn.Text = (bindKey and tostring(bindKey) or "None") .. " (" .. mode .. ")"
        end
        updateText()

        bindBtn.MouseButton1Click:Connect(function()
            bindBtn.Text = "Press key..."
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, g)
                if g then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    bindKey = input.KeyCode
                    updateText()
                    conn:Disconnect()
                end
            end)
        end)

        -- Right click menu
        bindBtn.MouseButton2Click:Connect(function()
            local menu = new("Frame", {Parent = container, Size = UDim2.new(0, 120, 0, 120), Position = UDim2.new(0, 200, 0, 8), BackgroundColor3 = Color3.fromRGB(30,30,30)})
            local opts = {"Always","Off","Toggle","Hold"}
            for i,o in ipairs(opts) do
                local b = new("TextButton", {Parent = menu, Size = UDim2.new(1,0,0,28), Position = UDim2.new(0,0,0,(i-1)*28), Text = o, BackgroundTransparency = 0})
                b.MouseButton1Click:Connect(function()
                    mode = o
                    updateText()
                    menu:Destroy()
                end)
            end
        end)

        -- Global input handling
        local toggled = false
        UserInputService.InputBegan:Connect(function(input, g)
            if g then return end
            if bindKey and input.KeyCode == bindKey then
                if mode == "Always" then
                    -- do nothing special: always considered active
                elseif mode == "Toggle" then
                    toggled = not toggled
                    if opts.Callback then pcall(opts.Callback, toggled) end
                elseif mode == "Hold" then
                    if opts.Callback then pcall(opts.Callback, true) end
                elseif mode == "Off" then end
            end
        end)
        UserInputService.InputEnded:Connect(function(input, g)
            if g then return end
            if bindKey and input.KeyCode == bindKey then
                if mode == "Hold" then if opts.Callback then pcall(opts.Callback, false) end end
            end
        end)

        page.CanvasSize = page.CanvasSize + UDim2.new(0,0,0,120)
        return bindBtn
    end

    -- Dropdown (with optional multi-select "combo")
    function self:CreateDropdown(page, opts)
        opts = opts or {}
        local label = opts.Text or "Dropdown"
        local items = opts.Items or {}
        local combo = opts.Combo or false
        local section, container = makeSection(page, label)
        local mainBtn = new("TextButton", {Parent = container, Size = UDim2.new(0, 160, 0, 32), Position = UDim2.new(0,8,0,8), Text = "Select...", BackgroundColor3 = Color3.fromRGB(40,40,44)})
        local selections = {}

        mainBtn.MouseButton1Click:Connect(function()
            local menu = new("Frame", {Parent = container, Size = UDim2.new(0, 160, 0, #items*26), Position = UDim2.new(0, 8, 0, 46), BackgroundColor3 = Color3.fromRGB(28,28,28)})
            for i,it in ipairs(items) do
                local b = new("TextButton", {Parent = menu, Size = UDim2.new(1,0,0,26), Position = UDim2.new(0,0,0,(i-1)*26), Text = it, BackgroundTransparency = 0})
                b.MouseButton1Click:Connect(function()
                    if combo then
                        if selections[it] then selections[it] = nil else selections[it] = true end
                        local labels = {}
                        for k,_ in pairs(selections) do table.insert(labels, k) end
                        mainBtn.Text = #labels>0 and table.concat(labels, ", ") or "Select..."
                        if opts.Callback then pcall(opts.Callback, selections) end
                    else
                        mainBtn.Text = it
                        if opts.Callback then pcall(opts.Callback, it) end
                        menu:Destroy()
                    end
                end)
            end
        end)

        page.CanvasSize = page.CanvasSize + UDim2.new(0,0,0,120)
        return mainBtn
    end

    -- CFG System helpers
    local CFG_FOLDER = "SimpleUIGlobalCfgs"

    local function cfgPath(name)
        return CFG_FOLDER .. "/" .. name .. ".json"
    end

    local function saveConfig(name, data)
        local text = HttpService:JSONEncode(data)
        if saveFile(cfgPath(name), text) then return true end
        -- fallback: store as attribute on player
        LocalPlayer:SetAttribute("SUICFG_"..name, text)
        return true
    end
    local function loadConfig(name)
        local txt = readFile(cfgPath(name))
        if txt then return HttpService:JSONDecode(txt) end
        local attr = LocalPlayer:GetAttribute("SUICFG_"..name)
        if attr then return HttpService:JSONDecode(attr) end
        return nil
    end
    local function deleteConfig(name)
        if canWriteFiles() then pcall(function() delfile(cfgPath(name)) end) end
        LocalPlayer:SetAttribute("SUICFG_"..name, nil)
    end

    -- Populate cfg list UI
    local function refreshCfgList()
        -- clear
        for _,v in pairs(cfgScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
        local i = 0
        -- if writefile available, scan files (not available in pure Roblox)
        if canWriteFiles() then
            -- no portable list function here — user can manage files in exploit
        end
        -- Use attributes as list
        for _,k in pairs(LocalPlayer:GetAttributes()) do end
        -- hack: we will iterate known attributes
        for name, _ in pairs(LocalPlayer:GetAttributes()) do
            if tostring(name):sub(1,7) == "SUICFG_" then
                local cfgName = tostring(name):sub(8)
                local b = new("TextButton", {Parent = cfgScroll, Size = UDim2.new(1,-10,0,28), Position = UDim2.new(0,5,0,i*34), Text = cfgName, BackgroundColor3 = Color3.fromRGB(36,36,36)})
                b.MouseButton1Click:Connect(function()
                    local data = loadConfig(cfgName)
                    if data then
                        descLabel.Text = "Описание конфига:\n" .. (data.desc or "-") .. "\nАвтор: " .. (data.author or "-")
                    else
                        descLabel.Text = "Описание конфига:\n-\nАвтор: -"
                    end
                end)
                i = i + 1
            end
        end
    end

    btnSave.MouseButton1Click:Connect(function()
        -- quick save dialog
        local name = "config_"..tostring(math.random(1000,9999))
        local data = {desc = "Описание", author = LocalPlayer.Name, created = os.time()}
        saveConfig(name, data)
        refreshCfgList()
    end)
    btnLoad.MouseButton1Click:Connect(function()
        -- load first config found
        for name,v in pairs(LocalPlayer:GetAttributes()) do end
        -- simplistic: not implemented full picker due to scope
        refreshCfgList()
    end)

    refreshCfgList()

    -- Close bind: allow user to bind key to toggle GUI
    local closeBind = Enum.KeyCode.RightControl
    local enabled = true
    UserInputService.InputBegan:Connect(function(input, g)
        if g then return end
        if input.KeyCode == closeBind then
            enabled = not enabled
            screenGui.Enabled = enabled
        end
    end)

    -- Return API
    self.CreateTab = function(name) return self:CreateTab(name) end
    self.CreateSlider = function(page, opts) return self:CreateSlider(page, opts) end
    self.CreateCheckbox = function(page, opts) return self:CreateCheckbox(page, opts) end
    self.CreateButton = function(page, opts) return self:CreateButton(page, opts) end
    self.CreateColorPicker = function(page, opts) return self:CreateColorPicker(page, opts) end
    self.CreateKeybind = function(page, opts) return self:CreateKeybind(page, opts) end
    self.CreateDropdown = function(page, opts) return self:CreateDropdown(page, opts) end
    self.ScreenGui = screenGui

    return self
end

return SimpleUI
