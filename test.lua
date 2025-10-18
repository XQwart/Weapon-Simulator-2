--[[
    STKLib v1.0.0
    A modern, professional GUI library for Roblox.
    Designed by AI, inspired by top-tier utility interfaces.
]]

-- Roblox Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- Compression/Encoding Libraries (Must be available in the execution environment)
-- In many executor environments, these are pre-loaded.
local zlib = zlib or {}
local base64 = base64 or {}

-- Fallbacks if libraries aren't present
if not zlib.compress or not zlib.decompress then
    warn("STKLib: ZLIB compression library not found. Config sharing will be disabled.")
    zlib = nil
end
if not base64.encode or not base64.decode then
    warn("STKLib: Base64 library not found. Config sharing will be disabled.")
    base64 = nil
end

-- Main Library
local STKLib = {}
STKLib.Objects = {}
STKLib.Elements = {}
STKLib.Version = "1.0.0"
STKLib.Instance = nil  -- Track the single instance of the library

-- /////////////////////////////////////////////////////////////////////////////
-- THEME & CONFIGURATION
-- /////////////////////////////////////////////////////////////////////////////

STKLib.Theme = {
    Background = Color3.fromRGB(24, 24, 24),    -- #181818
    Accent = Color3.fromRGB(255, 165, 0),       -- #FFA500
    AccentDark = Color3.fromRGB(204, 132, 0),
    Text = Color3.fromRGB(255, 255, 255),
    SecondaryText = Color3.fromRGB(160, 160, 160),
    Secondary = Color3.fromRGB(40, 40, 40),
    Tertiary = Color3.fromRGB(55, 55, 55),
    Stroke = Color3.fromRGB(60, 60, 60),

    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,

    Transparency = 0.2, -- 0 is opaque, 1 is transparent. So 1 - 0.8 = 0.2
    BlurSize = 24,

    AnimationSpeed = 0.2
}

STKLib.Icons = {
    Checkbox_Checked = "rbxassetid://3926307971", -- Checkmark icon
    Dropdown_Arrow = "rbxassetid://3926305904", -- Chevron down
    Logo = "", -- User-defined: "rbxassetid://YOUR_LOGO_ID"
}

-- /////////////////////////////////////////////////////////////////////////////
-- UTILITY FUNCTIONS
-- /////////////////////////////////////////////////////////////////////////////

local Utils = {}
function Utils.Create(instanceType, properties)
    local inst = Instance.new(instanceType)
    for prop, value in pairs(properties or {}) do
        inst[prop] = value
    end
    return inst
end

function Utils.Tween(instance, properties)
    local tweenInfo = TweenInfo.new(STKLib.Theme.AnimationSpeed, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

function Utils.GenerateId()
    return HttpService:GenerateGUID(false)
end

-- /////////////////////////////////////////////////////////////////////////////
-- WINDOW CLASS
-- /////////////////////////////////////////////////////////////////////////////

STKLib.Objects.Window = {}
STKLib.Objects.Window.__index = STKLib.Objects.Window

function STKLib:Load(options)
    if STKLib.Instance then
        warn("STKLib: An instance is already loaded. Please close it before loading a new one.")
        return STKLib.Instance
    end

    options = options or {}
    local self = setmetatable({}, STKLib.Objects.Window)

    self.Title = options.Title or "STKLib"
    self.Size = options.Size or UDim2.fromOffset(600, 400)
    self.Keybind = options.Keybind or Enum.KeyCode.RightShift

    self.Tabs = {}
    self.ActiveTab = nil
    self.Visible = false
    self.Elements = {} -- Stores all elements by ID for config management

    STKLib.Instance = self  -- Set the single instance

    self:InitializeUI()
    self:SetupInput()

    -- Add the essential Config tab
    self:AddConfigTab()

    return self
end

function STKLib.Objects.Window:InitializeUI()
    self.ScreenGui = Utils.Create("ScreenGui", {
        Name = "STKLib_ScreenGui",
        Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        ResetOnSpawn = false
    })

    local blur = Utils.Create("BlurEffect", {
        Size = STKLib.Theme.BlurSize,
        Parent = game.Lighting
    })

    self.MainFrame = Utils.Create("Frame", {
        Name = "MainFrame",
        Size = self.Size,
        Position = UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2),
        BackgroundColor3 = STKLib.Theme.Background,
        BackgroundTransparency = STKLib.Theme.Transparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.ScreenGui,
        Visible = false
    })
    
    local corner = Utils.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.MainFrame })
    local stroke = Utils.Create("UIStroke", { Color = STKLib.Theme.Accent, Thickness = 1.5, Parent = self.MainFrame })

    -- Header
    self.Header = Utils.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = STKLib.Theme.Secondary,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })

    -- Logo
    local logo = Utils.Create("ImageLabel", {
        Name = "Logo",
        Size = UDim2.fromOffset(24, 24),
        Position = UDim2.fromOffset(10, 8),
        BackgroundTransparency = 1,
        Image = STKLib.Icons.Logo or "rbxassetid://5123473691", -- Default Roblox studio logo
        Parent = self.Header
    })
    
    -- Title
    local titleLabel = Utils.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.fromOffset(40, 0),
        BackgroundTransparency = 1,
        Font = STKLib.Theme.FontBold,
        Text = self.Title,
        TextColor3 = STKLib.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Header
    })

    -- Tab Container (Top)
    self.TabContainer = Utils.Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.new(0, 140, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Header
    })
    local tabLayout = Utils.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 10),
        Parent = self.TabContainer
    })

    -- Body
    self.Body = Utils.Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 1, -40),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = self.MainFrame
    })

    -- SubTab Container (Left)
    self.SubTabContainer = Utils.Create("ScrollingFrame", {
        Name = "SubTabContainer",
        Size = UDim2.new(0, 150, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = STKLib.Theme.Accent,
        Parent = self.Body
    })
    local subTabLayout = Utils.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = self.SubTabContainer
    })
    local subTabPadding = Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        Parent = self.SubTabContainer
    })

    -- Content Container (Right)
    self.ContentContainer = Utils.Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, -150, 1, 0),
        Position = UDim2.new(0, 150, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Body
    })
    
    -- Draggable Logic
    local dragging = false
    local dragInput, dragStart, startPos
    self.Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.MainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                local delta = input.Position - dragStart
                self.MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end
    end)
    
    -- Blur management
    self.ScreenGui:GetPropertyChangedSignal("Enabled"):Connect(function()
        blur.Enabled = self.ScreenGui.Enabled
    end)
    blur.Enabled = self.ScreenGui.Enabled
end

function STKLib.Objects.Window:SetupInput()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == self.Keybind then
            self:Toggle()
        end
    end)
end

function STKLib.Objects.Window:Toggle()
    self.Visible = not self.Visible
    self.MainFrame.Visible = self.Visible
    if self.Visible then
        Utils.Tween(self.MainFrame, {Position = UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2)})
    end
end

function STKLib.Objects.Window:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
        -- Find and disable the blur effect
        local blur = game.Lighting:FindFirstChild("BlurEffect")
        if blur and blur.Parent == game.Lighting then
            blur.Enabled = false
        end
    end
    STKLib.Instance = nil  -- Reset the single instance
end

-- /////////////////////////////////////////////////////////////////////////////
-- TAB CLASS
-- /////////////////////////////////////////////////////////////////////////////

STKLib.Objects.Tab = {}
STKLib.Objects.Tab.__index = STKLib.Objects.Tab

function STKLib.Objects.Window:AddTab(name)
    local self = self
    local tab = setmetatable({}, STKLib.Objects.Tab)
    
    tab.Name = name
    tab.Window = self
    tab.SubTabs = {}
    tab.ActiveSubTab = nil
    
    -- Create the top tab button
    tab.Button = Utils.Create("TextButton", {
        Name = name,
        Size = UDim2.new(0, 0, 0, 25),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = STKLib.Theme.Font,
        Text = "  "..name.."  ",
        TextColor3 = STKLib.Theme.SecondaryText,
        TextSize = 14,
        Parent = self.TabContainer
    })

    local indicator = Utils.Create("Frame", {
        Name = "Indicator",
        Size = UDim2.new(1, -10, 0, 2),
        Position = UDim2.new(0.5, 0, 1, -2),
        AnchorPoint = Vector2.new(0.5, 1),
        BackgroundColor3 = STKLib.Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = tab.Button
    })
    Utils.Create("UICorner", {Parent = indicator})
    
    -- SubTab list for this tab
    tab.SubTabList = Utils.Create("Frame", {
        Name = name .. "_SubTabs",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.SubTabContainer
    })
    Utils.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = tab.SubTabList
    })
    
    -- Content container for this tab
    tab.Content = Utils.Create("Frame", {
        Name = name.."_Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.ContentContainer,
    })
    
    tab.Button.MouseButton1Click:Connect(function()
        self:SetActiveTab(tab)
    end)
    
    table.insert(self.Tabs, tab)
    if not self.ActiveTab then
        self:SetActiveTab(tab)
    end
    
    return tab
end

function STKLib.Objects.Window:SetActiveTab(tabToActivate)
    if self.ActiveTab == tabToActivate then return end
    
    for _, tab in ipairs(self.Tabs) do
        local isActive = (tab == tabToActivate)
        tab.SubTabList.Visible = isActive
        tab.Content.Visible = isActive
        tab.Button.TextColor3 = isActive and STKLib.Theme.Text or STKLib.Theme.SecondaryText
        tab.Button.Indicator.Visible = isActive
    end
    
    self.ActiveTab = tabToActivate
    
    -- Activate the first sub-tab if one exists and none are active
    if #tabToActivate.SubTabs > 0 and not tabToActivate.ActiveSubTab then
        tabToActivate:SetActiveSubTab(tabToActivate.SubTabs[1])
    end
end

-- /////////////////////////////////////////////////////////////////////////////
-- SUB-TAB CLASS
-- /////////////////////////////////////////////////////////////////////////////

STKLib.Objects.SubTab = {}
STKLib.Objects.SubTab.__index = STKLib.Objects.SubTab

function STKLib.Objects.Tab:AddSubTab(name)
    local tab = self
    local subTab = setmetatable({}, STKLib.Objects.SubTab)
    
    subTab.Name = name
    subTab.ParentTab = tab
    
    -- Create the left-side button
    subTab.Button = Utils.Create("TextButton", {
        Name = name,
        Size = UDim2.new(1, -20, 0, 30),
        BackgroundColor3 = STKLib.Theme.Background,
        Font = STKLib.Theme.Font,
        Text = name,
        TextColor3 = STKLib.Theme.SecondaryText,
        TextSize = 14,
        Parent = tab.SubTabList
    })
    Utils.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = subTab.Button })
    
    -- Content area for this sub-tab
    subTab.Content = Utils.Create("ScrollingFrame", {
        Name = name.."_Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 2, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = STKLib.Theme.Accent,
        Visible = false,
        Parent = tab.Content
    })
    local layout = Utils.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, 10),
        Parent = subTab.Content
    })
    local padding = Utils.Create("UIPadding", {
        PaddingTop = UDim.new(0, 15),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        Parent = subTab.Content
    })
    
    subTab.Button.MouseButton1Click:Connect(function()
        tab:SetActiveSubTab(subTab)
    end)
    
    table.insert(tab.SubTabs, subTab)
    
    if not tab.ActiveSubTab then
        tab:SetActiveSubTab(subTab)
    end
    
    return subTab
end

function STKLib.Objects.Tab:SetActiveSubTab(subTabToActivate)
    if self.ActiveSubTab == subTabToActivate then return end
    
    for _, subTab in ipairs(self.SubTabs) do
        local isActive = (subTab == subTabToActivate)
        subTab.Content.Visible = isActive
        subTab.Button.BackgroundColor3 = isActive and STKLib.Theme.Secondary or STKLib.Theme.Background
        subTab.Button.TextColor3 = isActive and STKLib.Theme.Text or STKLib.Theme.SecondaryText
    end
    
    self.ActiveSubTab = subTabToActivate
end

-- /////////////////////////////////////////////////////////////////////////////
-- ELEMENT: LABEL
-- /////////////////////////////////////////////////////////////////////////////
function STKLib.Objects.SubTab:AddLabel(text)
    local label = Utils.Create("TextLabel", {
        Text = text,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = STKLib.Theme.FontBold,
        TextColor3 = STKLib.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Content
    })
    return label
end

-- /////////////////////////////////////////////////////////////////////////////
-- ELEMENT: CHECKBOX
-- /////////////////////////////////////////////////////////////////////////////
STKLib.Elements.Checkbox = {}
STKLib.Elements.Checkbox.__index = STKLib.Elements.Checkbox

function STKLib.Objects.SubTab:AddCheckbox(options)
    local subTab = self
    options = options or {}
    
    local element = setmetatable({}, STKLib.Elements.Checkbox)
    element.Id = options.Id or Utils.GenerateId()
    element.Value = options.Default or false
    element.Callback = options.Callback or function() end
    
    local frame = Utils.Create("Frame", {
        Name = options.Text or "Checkbox",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Parent = subTab.Content
    })
    
    local label = Utils.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, -30, 1, 0),
        BackgroundTransparency = 1,
        Font = STKLib.Theme.Font,
        Text = options.Text or "Checkbox",
        TextColor3 = STKLib.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    
    local box = Utils.Create("ImageButton", {
        Name = "Box",
        Size = UDim2.fromOffset(20, 20),
        Position = UDim2.new(1, -20, 0.5, -10),
        BackgroundColor3 = STKLib.Theme.Secondary,
        Image = STKLib.Icons.Checkbox_Checked,
        ImageColor3 = STKLib.Theme.Accent,
        ImageTransparency = element.Value and 0 or 1,
        Parent = frame
    })
    Utils.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = box })
    Utils.Create("UIStroke", { Color = STKLib.Theme.Stroke, Parent = box })
    
    function element:SetValue(newValue, skipCallback)
        newValue = not not newValue
        if element.Value == newValue then return end
        
        element.Value = newValue
        Utils.Tween(box, {ImageTransparency = newValue and 0 or 1})
        
        if not skipCallback then
            element.Callback(newValue)
        end
    end
    
    box.MouseButton1Click:Connect(function()
        element:SetValue(not element.Value)
    end)
    
    subTab.ParentTab.Window.Elements[element.Id] = element
    return element
end

-- /////////////////////////////////////////////////////////////////////////////
-- ELEMENT: SLIDER
-- /////////////////////////////////////////////////////////////////////////////
STKLib.Elements.Slider = {}
STKLib.Elements.Slider.__index = STKLib.Elements.Slider

function STKLib.Objects.SubTab:AddSlider(options)
    local subTab = self
    options = options or {}
    
    local element = setmetatable({}, STKLib.Elements.Slider)
    element.Id = options.Id or Utils.GenerateId()
    element.Min = options.Min or 0
    element.Max = options.Max or 100
    element.Value = options.Default or element.Min
    element.Callback = options.Callback or function() end
    
    local frame = Utils.Create("Frame", {
        Name = options.Text or "Slider",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = subTab.Content
    })

    local label = Utils.Create("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = STKLib.Theme.Font,
        Text = options.Text or "Slider",
        TextColor3 = STKLib.Theme.Text,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local valueLabel = Utils.Create("TextLabel", {
        Name = "ValueLabel",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Font = STKLib.Theme.Font,
        TextColor3 = STKLib.Theme.SecondaryText,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame
    })
    
    local track = Utils.Create("Frame", {
        Name = "Track",
        Size = UDim2.new(1, 0, 0, 6),
        Position = UDim2.new(0, 0, 0, 25),
        BackgroundColor3 = STKLib.Theme.Secondary,
        Parent = frame
    })
    Utils.Create("UICorner", {Parent = track})
    
    local fill = Utils.Create("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = STKLib.Theme.Accent,
        Parent = track
    })
    Utils.Create("UICorner", {Parent = fill})

    local dragging = false
    
    function element:SetValue(newValue, skipCallback)
        newValue = math.clamp(newValue, element.Min, element.Max)
        if element.Value == newValue then return end
        
        element.Value = newValue
        local percentage = (newValue - element.Min) / (element.Max - element.Min)
        Utils.Tween(fill, { Size = UDim2.new(percentage, 0, 1, 0) })
        valueLabel.Text = string.format("%.2f", newValue)
        
        if not skipCallback then
            element.Callback(newValue)
        end
    end
    
    local function updateFromInput(input)
        local pos = input.Position.X
        local start = track.AbsolutePosition.X
        local width = track.AbsoluteSize.X
        local percentage = math.clamp((pos - start) / width, 0, 1)
        local newValue = element.Min + (element.Max - element.Min) * percentage
        element:SetValue(newValue)
    end
    
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromInput(input)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput(input)
        end
    end)

    element:SetValue(element.Value, true)
    subTab.ParentTab.Window.Elements[element.Id] = element
    return element
end

-- /////////////////////////////////////////////////////////////////////////////
-- CONFIG SYSTEM
-- /////////////////////////////////////////////////////////////////////////////
function STKLib.Objects.Window:AddConfigTab()
    local window = self
    local configTab = window:AddTab("Configs")
    local mainSubTab = configTab:AddSubTab("Manage")

    -- Config list
    mainSubTab:AddLabel("Your Configs")
    local configListFrame = Utils.Create("ScrollingFrame", {
        Name = "ConfigList",
        Size = UDim2.new(1, 0, 0, 150),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 2,
        Parent = mainSubTab.Content
    })
    local listLayout = Utils.Create("UIListLayout", {
        Parent = configListFrame,
        Padding = UDim.new(0, 5)
    })
    
    -- Controls
    mainSubTab:AddLabel("Create & Share")
    local nameInput = Utils.Create("TextBox", {
        Name = "ConfigNameInput",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = STKLib.Theme.Secondary,
        Font = STKLib.Theme.Font,
        Text = "",
        PlaceholderText = "Enter config name...",
        TextColor3 = STKLib.Theme.Text,
        TextSize = 14,
        Parent = mainSubTab.Content
    })
    Utils.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = nameInput})
    
    local buttonsFrame = Utils.Create("Frame", {
        Size = UDim2.new(1,0,0,30),
        BackgroundTransparency = 1,
        Parent = mainSubTab.Content
    })
    Utils.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0,10),
        Parent = buttonsFrame
    })

    local function createButton(text, parent)
        local btn = Utils.Create("TextButton", {
            Name = text,
            Size = UDim2.new(0.3, 0, 1, 0),
            BackgroundColor3 = STKLib.Theme.Accent,
            Font = STKLib.Theme.Font,
            Text = text,
            TextColor3 = STKLib.Theme.Text,
            TextSize = 14,
            Parent = parent
        })
        Utils.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = btn})
        return btn
    end

    local createBtn = createButton("Create", buttonsFrame)
    local importBtn = createButton("Import", buttonsFrame)
    
    -- Config state
    local configs = {}
    
    local function refreshConfigList()
        configListFrame:ClearAllChildren()
        
        for name, data in pairs(configs) do
            local itemFrame = Utils.Create("Frame", {
                Name = name,
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = STKLib.Theme.Secondary,
                Parent = configListFrame
            })
            Utils.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = itemFrame})
            
            local label = Utils.Create("TextLabel", {
                Size = UDim2.new(0.5, 0, 1, 0),
                Position = UDim2.fromOffset(10, 0),
                BackgroundTransparency = 1,
                Font = STKLib.Theme.Font,
                Text = name,
                TextColor3 = STKLib.Theme.Text,
                TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
                Parent = itemFrame
            })
            
            local loadBtn = Utils.Create("TextButton", {
                Size = UDim2.fromOffset(40, 20),
                Position = UDim2.new(1, -140, 0.5, -10),
                BackgroundColor3 = STKLib.Theme.Accent,
                Font = STKLib.Theme.Font, Text = "Load", TextColor3 = STKLib.Theme.Text, TextSize = 12,
                Parent = itemFrame
            })
            Utils.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = loadBtn})
            
            local shareBtn = Utils.Create("TextButton", {
                Size = UDim2.fromOffset(40, 20),
                Position = UDim2.new(1, -90, 0.5, -10),
                BackgroundColor3 = STKLib.Theme.Tertiary,
                Font = STKLib.Theme.Font, Text = "Share", TextColor3 = STKLib.Theme.Text, TextSize = 12,
                Parent = itemFrame
            })
            Utils.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = shareBtn})
            
            local deleteBtn = Utils.Create("TextButton", {
                Size = UDim2.fromOffset(40, 20),
                Position = UDim2.new(1, -40, 0.5, -10),
                BackgroundColor3 = Color3.fromRGB(200, 50, 50),
                Font = STKLib.Theme.Font, Text = "Del", TextColor3 = STKLib.Theme.Text, TextSize = 12,
                Parent = itemFrame
            })
            Utils.Create("UICorner", {CornerRadius = UDim.new(0, 4), Parent = deleteBtn})
            
            loadBtn.MouseButton1Click:Connect(function() window:LoadConfig(name) end)
            deleteBtn.MouseButton1Click:Connect(function() window:DeleteConfig(name) end)
            shareBtn.MouseButton1Click:Connect(function()
                local code = window:ShareConfig(name)
                if code then
                    setclipboard(code)
                    print("STKLib: Config code copied to clipboard!")
                end
            end)
        end
    end

    function window:SaveConfig(name)
        local data = {}
        for id, element in pairs(window.Elements) do
            if element.Value ~= nil then
                data[id] = element.Value
            end
        end
        configs[name] = data
        refreshConfigList()
        print("STKLib: Config '"..name.."' saved.")
    end

    function window:LoadConfig(name)
        local data = configs[name]
        if not data then return warn("STKLib: Config '"..name.."' not found.") end
        
        for id, value in pairs(data) do
            if window.Elements[id] and window.Elements[id].SetValue then
                window.Elements[id]:SetValue(value, false) -- Trigger callbacks to update game state
            end
        end
        print("STKLib: Config '"..name.."' loaded.")
    end

    function window:DeleteConfig(name)
        configs[name] = nil
        refreshConfigList()
        print("STKLib: Config '"..name.."' deleted.")
    end

    function window:ShareConfig(name)
        local data = configs[name]
        if not data then warn("STKLib: Config not found."); return nil end
        if not zlib or not base64 then warn("STKLib: Missing libraries for sharing."); return nil end

        local success, result = pcall(function()
            local jsonString = HttpService:JSONEncode(data)
            local compressed = zlib.compress(jsonString)
            return base64.encode(compressed)
        end)

        if success then return result else warn("STKLib: Error encoding config:", result); return nil end
    end

    function window:ImportConfig(code)
        if not zlib or not base64 then warn("STKLib: Missing libraries for importing."); return end
        
        local success, result = pcall(function()
            local decodedB64 = base64.decode(code)
            local decompressed = zlib.decompress(decodedB64)
            return HttpService:JSONDecode(decompressed)
        end)
        
        if success then
            local configName = "Imported-"..string.sub(HttpService:GenerateGUID(false), 1, 4)
            configs[configName] = result
            refreshConfigList()
            window:LoadConfig(configName)
            print("STKLib: Successfully imported config as '"..configName.."'.")
        else
            warn("STKLib: Failed to import config. Invalid code.", result)
        end
    end
    
    createBtn.MouseButton1Click:Connect(function()
        local name = nameInput.Text
        if name and name ~= "" and not configs[name] then
            window:SaveConfig(name)
            nameInput.Text = ""
        else
            warn("STKLib: Invalid or duplicate config name.")
        end
    end)
    
    importBtn.MouseButton1Click:Connect(function()
        local code = getclipboard()
        if code and type(code) == "string" and #code > 10 then
            window:ImportConfig(code)
        else
            warn("STKLib: Clipboard does not contain a valid config code.")
        end
    end)
    
    refreshConfigList()
end

return STKLib
