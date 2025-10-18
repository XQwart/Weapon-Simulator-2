-- STKLib.lua
local STKLib = {}
STKLib.__index = STKLib

-- Конфигурация
STKLib.configs = {}
STKLib.currentConfig = nil

-- Основные цвета
STKLib.colors = {
    background = Color3.fromRGB(24, 24, 24),
    accent = Color3.fromRGB(255, 165, 0),
    text = Color3.fromRGB(255, 255, 255),
}

-- Инициализация
function STKLib.new()
    local self = setmetatable({}, STKLib)
    self:initializeUI()
    return self
end

function STKLib:initializeUI()
    -- Создание основного контейнера
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Size = UDim2.new(0.5, 0, 0.5, 0)
    self.mainFrame.Position = UDim2.new(0.25, 0, 0.25, 0)
    self.mainFrame.BackgroundColor3 = self.colors.background
    self.mainFrame.BackgroundTransparency = 0.7
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

    -- Логотип
    local logo = Instance.new("ImageLabel")
    logo.Size = UDim2.new(0.1, 0, 0.1, 0)
    logo.Position = UDim2.new(0.05, 0, 0.05, 0)
    logo.Image = "rbxassetid://YOUR_LOGO_ASSET_ID" -- Замените на свой ID
    logo.Parent = self.mainFrame

    -- Элементы интерфейса
    self:setupTabs()
    self:setupConfigManager()
end

function STKLib:setupTabs()
    -- Пример вкладок
    self.tabContainer = Instance.new("Frame")
    self.tabContainer.Size = UDim2.new(1, 0, 0.1, 0)
    self.tabContainer.Position = UDim2.new(0, 0, 0, 0)
    self.tabContainer.BackgroundColor3 = self.colors.background
    self.tabContainer.Parent = self.mainFrame

    -- Создание кнопок вкладок
    local tabButton1 = self:createTabButton("Tab 1", function() self:showTab("Tab 1") end)
    local tabButton2 = self:createTabButton("Tab 2", function() self:showTab("Tab 2") end)
    tabButton1.Parent = self.tabContainer
    tabButton2.Parent = self.tabContainer

    -- Показать первую вкладку по умолчанию
    self:showTab("Tab 1")
end

function STKLib:createTabButton(name, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.1, 0, 1, 0)
    button.BackgroundColor3 = self.colors.accent
    button.TextColor3 = self.colors.text
    button.Text = name
    button.MouseButton1Click:Connect(callback)
    return button
end

function STKLib:showTab(tabName)
    print("Showing tab:", tabName)
    -- Логика отображения содержимого вкладки
end

function STKLib:setupConfigManager()
    -- Создание менеджера конфигураций
    self.configFrame = Instance.new("Frame")
    self.configFrame.Size = UDim2.new(1, 0, 0.9, 0)
    self.configFrame.Position = UDim2.new(0, 0, 0.1, 0)
    self.configFrame.BackgroundColor3 = self.colors.background
    self.configFrame.BackgroundTransparency = 0.7
    self.configFrame.Parent = self.mainFrame

    -- Поля для управления конфигурациями
    self:createConfigControls()
end

function STKLib:createConfigControls()
    local configLabel = Instance.new("TextLabel")
    configLabel.Size = UDim2.new(1, 0, 0.1, 0)
    configLabel.BackgroundColor3 = self.colors.background
    configLabel.TextColor3 = self.colors.text
    configLabel.Text = "Config Manager"
    configLabel.Parent = self.configFrame

    -- Поле для имени конфигурации
    self.configInput = Instance.new("TextBox")
    self.configInput.Size = UDim2.new(0.8, 0, 0.1, 0)
    self.configInput.Position = UDim2.new(0.1, 0, 0.15, 0)
    self.configInput.BackgroundColor3 = self.colors.accent
    self.configInput.TextColor3 = self.colors.text
    self.configInput.PlaceholderText = "Enter config name"
    self.configInput.Parent = self.configFrame

    -- Кнопка для создания конфигурации
    local createButton = Instance.new("TextButton")
    createButton.Size = UDim2.new(0.3, 0, 0.1, 0)
    createButton.Position = UDim2.new(0.1, 0, 0.3, 0)
    createButton.BackgroundColor3 = self.colors.accent
    createButton.TextColor3 = self.colors.text
    createButton.Text = "Create Config"
    createButton.MouseButton1Click:Connect(function()
        self:createConfig(self.configInput.Text)
    end)
    createButton.Parent = self.configFrame
end

function STKLib:createConfig(name)
    if self.configs[name] then
        warn("Config already exists!")
        return
    end
    self.configs[name] = {}
    print("Config created:", name)
end

function STKLib:saveConfig(name)
    -- Логика сохранения конфигурации
    print("Config saved:", name)
end

function STKLib:loadConfig(name)
    -- Логика загрузки конфигурации
    print("Config loaded:", name)
end

function STKLib:deleteConfig(name)
    self.configs[name] = nil
    print("Config deleted:", name)
end

function STKLib:shareConfig(name)
    if not self.configs[name] then
        warn("Config does not exist!")
        return
    end
    -- Преобразование конфигурации в строку
    return "encoded_config_string" -- Пример, замените на свою логику
end

return STKLib
