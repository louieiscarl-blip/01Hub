local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/louieiscarl-blip/01Hub/main/Library.lua"))()
local menu = lib:CreateWindow("01Hub v1.8")

-- Movements tab
local move = menu:AddTab("Movements")

move:AddSlider({
    text = "WalkSpeed",
    min = 10, max = 100, value = 16, increment = 1,
    callback = function(val)
        local char = game.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = val end
        end
    end
})

move:AddToggle({
    text = "Fly",
    callback = function(state)
        print("Fly:", state)
    end
})

-- ESP / Misc tab
local misc = menu:AddTab("Misc")
misc:AddButton({
    text = "ESP Debug",
    callback = function()
        print("ESP test")
    end
})
