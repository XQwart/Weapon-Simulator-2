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
    -- ВАЖНО: Создаем ScreenGui сначала!
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "STKLibUI"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Создание основного контейнера
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Size = UDim2.new(0.5, 0, 0.5, 0)
    self.mainFrame.Position = UDim2.new(0.25, 0, 0.25, 0)
    self.mainFrame.BackgroundColor3 = self.colors.background
    self.mainFrame.BackgroundTransparency = 0.1 -- Уменьшил прозрачность для лучшей видимости
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Parent = self.screenGui -- Теперь добавляем в ScreenGui
    
    -- Добавляем возможность перетаскивания
    self:makeDraggable(self.mainFrame)
    
    -- Добавляем UICorner для закругленных углов
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = self.mainFrame

    -- Логотип (заглушка, так как нет реального изображения)
    local logoFrame = Instance.new("Frame")
    logoFrame.Size = UDim2.new(0.1, 0, 0.1, 0)
    logoFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
    logoFrame.BackgroundColor3 = self.colors.accent
    logoFrame.Parent = self.mainFrame
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 4)
    logoCorner.Parent = logoFrame

    -- Элементы интерфейса
    self:setupTabs()
    self:setupConfigManager()
end

function STKLib:makeDraggable(frame)
    local dragToggle = nil
    local dragStart = nil
    local startPos = nil
    
    local function updateInput(input)
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = frame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
            updateInput(input)
        end
    end)
end

function STKLib:setupTabs()
    -- Пример вкладок
    self.tabContainer = Instance.new("Frame")
    self.tabContainer.Size = UDim2.new(1, 0, 0.1, 0)
    self.tabContainer.Position = UDim2.new(0, 0, 0, 0)
    self.tabContainer.BackgroundColor3 = self.colors.background
    self.tabContainer.BackgroundTransparency = 0.5
    self.tabContainer.Parent = self.mainFrame

    -- Создание кнопок вкладок с правильным позиционированием
    local tabButton1 = self:createTabButton("Tab 1", 0, function() self:showTab("Tab 1") end)
    local tabButton2 = self:createTabButton("Tab 2", 1, function() self:showTab("Tab 2") end)
    tabButton1.Parent = self.tabContainer
    tabButton2.Parent = self.tabContainer

    -- Показать первую вкладку по умолчанию
    self:showTab("Tab 1")
end

function STKLib:createTabButton(name, index, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.15, 0, 0.8, 0)
    button.Position = UDim2.new(0.2 + (index * 0.16), 0, 0.1, 0) -- Правильное позиционирование
    button.BackgroundColor3 = self.colors.accent
    button.TextColor3 = self.colors.text
    button.Text = name
    button.Font = Enum.Font.SourceSans
    button.TextScaled = true
    button.MouseButton1Click:Connect(callback)
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 4)
    buttonCorner.Parent = button
    
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
    self.configFrame.BackgroundTransparency = 0.9
    self.configFrame.Parent = self.mainFrame

    -- Поля для управления конфигурациями
    self:createConfigControls()
end

function STKLib:createConfigControls()
    local configLabel = Instance.new("TextLabel")
    configLabel.Size = UDim2.new(1, 0, 0.1, 0)
    configLabel.BackgroundTransparency = 1
    configLabel.TextColor3 = self.colors.text
    configLabel.Text = "Config Manager"
    configLabel.Font = Enum.Font.SourceSansBold
    configLabel.TextScaled = true
    configLabel.Parent = self.configFrame

    -- Поле для имени конфигурации
    self.configInput = Instance.new("TextBox")
    self.configInput.Size = UDim2.new(0.8, 0, 0.1, 0)
    self.configInput.Position = UDim2.new(0.1, 0, 0.15, 0)
    self.configInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    self.configInput.TextColor3 = self.colors.text
    self.configInput.PlaceholderText = "Enter config name"
    self.configInput.Font = Enum.Font.SourceSans
    self.configInput.TextScaled = true
    self.configInput.Parent = self.configFrame
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 4)
    inputCorner.Parent = self.configInput

    -- Кнопка для создания конфигурации
    local createButton = Instance.new("TextButton")
    createButton.Size = UDim2.new(0.3, 0, 0.1, 0)
    createButton.Position = UDim2.new(0.1, 0, 0.3, 0)
    createButton.BackgroundColor3 = self.colors.accent
    createButton.TextColor3 = self.colors.text
    createButton.Text = "Create Config"
    createButton.Font = Enum.Font.SourceSans
    createButton.TextScaled = true
    createButton.MouseButton1Click:Connect(function()
        self:createConfig(self.configInput.Text)
    end)
    createButton.Parent = self.configFrame
    
    local createCorner = Instance.new("UICorner")
    createCorner.CornerRadius = UDim.new(0, 4)
    createCorner.Parent = createButton
end

function STKLib:createConfig(name)
    if name == "" then
        warn("Please enter a config name!")
        return
    end
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
