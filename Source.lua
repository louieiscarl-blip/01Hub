--// Loading Libary
local success, lib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/louieiscarl-blip/01Hub/main/Libary.lua"))()
end)

if not success or not lib then
    warn("[01Hub] Failed to load Libary.lua")
    return
end

--// Creating Menu
local menu = lib:CreateMenu({
    Title = "01Hub v1.8",
    Style = 1
})

--// Tab: Movements
local MovementsTab = menu:CreateTab("Movements")

local MoveSection = MovementsTab:AddSection("Player Movement", 1)
MoveSection:AddSlider({
    text = "WalkSpeed",
    min = 1, max = 200, value = 16, increment = 1,
    callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = val
            end
        end
    end
})

MoveSection:AddSlider({
    text = "JumpPower",
    min = 20, max = 400, value = 50, increment = 1,
    callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.UseJumpPower = true
                hum.JumpPower = val
            end
        end
    end
})

--// Tab: Visuals
local VisualsTab = menu:CreateTab("Visuals")
local VisualsSec = VisualsTab:AddSection("ESP", 1)

VisualsSec:AddToggle({
    text = "Player ESP",
    callback = function(state)
        if state then
            print("ESP enabled")
            -- add ESP logic here
        else
            print("ESP disabled")
        end
    end
})

--// Notification
lib:SendNotification("01Hub", "Loaded v1.8 suc
