-- 01Hub v1.8 (WindUI Edition)

local Window = WindUI:CreateWindow({
    Title = "01Hub v1.8",
    Theme = "Dark",
    Folder = "01Hub"
})

-- Movements Tab
local MovTab = Window:Tab({ Title = "Movements", Icon = "zap" })
MovTab:Slider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Callback = function(val)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
})
