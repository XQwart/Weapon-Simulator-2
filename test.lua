--[[
    STKLib v1.0.0
    A modern, professional GUI library for Roblox.
]]

-- Roblox Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

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
    Background = Color3.fromRGB(30, 30, 30),    -- Dark gray background
    Accent = Color3.fromRGB(255, 165, 0),       -- Orange accent
    Text = Color3.fromRGB(255, 255, 255),       -- White text
    SecondaryText = Color3.fromRGB(160, 160, 160),
    Secondary = Color3.fromRGB(50, 50, 50),

    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,

    Transparency = 0.2, -- Transparency for a glass-like effect
    AnimationSpeed = 0.2
}

STKLib.Icons = {
    Checkbox_Checked = "rbxassetid://3926307971", -- Checkmark icon
    Logo = "rbxassetid://5123473691" -- Default logo
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

    self.MainFrame = Utils.Create("Frame", {
        Name = "MainFrame",
        Size = self.Size,
        Position = UDim2.new(0.5, -self.Size.X.Offset / 2, 0.5, -self.Size.Y.Offset / 2),
        BackgroundColor3 = STKLib.Theme.Background,
        BackgroundTransparency = STKLib.Theme.Transparency,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.ScreenGui,
        Visible = true  -- Set to true for initial visibility
    })
    
    local corner = Utils.Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.MainFrame })
    
    -- Header
    self.Header = Utils.Create("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = STKLib.Theme.Secondary,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = self.MainFrame
    })

    -- Title
    local titleLabel = Utils.Create("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 100, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Font = STKLib.Theme.FontBold,
        Text = "STK",
        TextColor3 = STKLib.Theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Header
    })

    -- Close Button
    local closeButton = Utils.Create("TextButton", {
        Name = "CloseButton",
        Size = UDim2.fromOffset(30, 30),
        Position = UDim2.new(1, -40, 0, 5),
        BackgroundTransparency = 1,
        Text = "X",
        TextColor3 = STKLib.Theme.Text,
        Font = STKLib.Theme.FontBold,
        TextSize = 16,
        Parent = self.Header
    })

    closeButton.MouseButton1Click:Connect(function()
        self:Toggle()
    end)

    -- Tab Container (Left)
    self.TabContainer = Utils.Create("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(0, 150, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 0.5,
        Parent = self.MainFrame
    })
    local tabLayout = Utils.Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding = UDim.new(0, 5),
        Parent = self.TabContainer
    })

    -- Body
    self.Body = Utils.Create("Frame", {
        Name = "Body",
        Size = UDim2.new(1, -150, 1, -40),
        Position = UDim2.new(0, 150, 0, 40),
        BackgroundTransparency = 1,
        Parent = self.MainFrame
    })

    -- Content Container (Right)
    self.ContentContainer = Utils.Create("Frame", {
        Name = "ContentContainer",
        Size = UDim2.new(1, 0, 1, 0),
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
end

function STKLib.Objects.Window:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
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
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Font = STKLib.Theme.Font,
        Text = "  "..name.."  ",
        TextColor3 = STKLib.Theme.SecondaryText,
        TextSize = 14,
        Parent = self.TabContainer
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
        tab.Button.TextColor3 = isActive and STKLib.Theme.Text or STKLib.Theme.SecondaryText
    end
    
    self.ActiveTab = tabToActivate
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
        Parent = tab.Window.ContentContainer
    })
    
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
        Parent = tab.Window.ContentContainer
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
        ImageTransparency = element.Value and 0 or 1,
        Parent = frame
    })
    Utils.Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = box })
    
    function element:SetValue(newValue, skipCallback)
        newValue = not not newValue
        if element.Value == newValue then return end
        
        element.Value = newValue
        box.ImageTransparency = newValue and 0 or 1
        
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

return STKLib
