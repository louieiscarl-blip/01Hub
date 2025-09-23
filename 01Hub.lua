-- Obsidian Hub v1.8 with Addons
-- Carl01

-- Load Obsidian
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()

-- Addons
local ThemeManager, SaveManager
pcall(function() ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))() end)
pcall(function() SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))() end)

-- Window Setup
local Window = Library:CreateWindow({
    Name = "01Hub v1.8",
    IntroText = "Loading 01Hub...",
    LoadingTitle = "01Hub",
    LoadingSubtitle = "Executor detected",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "01Hub",
        FileName = "Settings"
    },
    Discord = {
        Enabled = true,
        Invite = "497SkTSE",
        RememberJoins = true
    }
})

-- Tabs
local HomeTab = Window:CreateTab("Home")
local MovementTab = Window:CreateTab("Movements")
local ESPTab = Window:CreateTab("ESP")
local ThemesTab = Window:CreateTab("Themes")

-- Home Example
HomeTab:CreateLabel("Welcome to 01Hub v1.8")
HomeTab:CreateLabel("Executor: " .. identifyexecutor())
HomeTab:CreateLabel("Device: " .. (UserInputService.TouchEnabled and "Mobile" or "PC/Console"))

-- Movements
MovementTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end
})

MovementTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 400},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.UseJumpPower = true hum.JumpPower = val end
        end
    end
})

-- ESP Example (basic toggle)
local espEnabled = false
ESPTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(state)
        espEnabled = state
        print("ESP is now", state and "ON" or "OFF")
    end
})

-- Themes / Addons
if ThemeManager then
    ThemeManager:SetLibrary(Library)
    ThemeManager:ApplyTheme("Dark")
    ThemeManager:CreateThemeManager(ThemesTab)
end

if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:BuildConfigSection(HomeTab)
end

-- Example keybind
HomeTab:CreateKeybind({
    Name = "Toggle UI",
    CurrentKeybind = "RightControl",
    Flag = "ToggleUIBind",
    Callback = function()
        Library:Toggle()
    end
})

Library:Notify("01Hub v1.8", "Loaded successfully with addons!")
