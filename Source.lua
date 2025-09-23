-- // 01Hub v1.8 Optimized \\ --
-- Author: CarlXD (Sakupen01 Project)
-- Optimized build for smoother execution and reduced lag.

-- // Services // --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // Utility Functions // --
local function safe(p, f)
    return pcall(function() return f() end)
end

local function safeWrite(path, data)
    safe(true, function()
        writefile(path, HttpService:JSONEncode(data))
    end)
end

local function safeRead(path)
    local ok, res = pcall(function()
        if isfile(path) then
            return HttpService:JSONDecode(readfile(path))
        end
    end)
    return ok and res or nil
end

local function notify(title, text, dur)
    if lib and lib.SendNotification then
        lib:SendNotification(title, text, dur or 2)
    end
end

-- // Load UI Library (Obsidian) // --
local success, lib = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Example.lua"))()
end)

if not success or not lib then
    warn("01Hub: Failed to load UI library.")
    return
end

local menu = lib:Create({
    title = "01Hub v1.8",
    subtitle = "Sakupen01 Project",
    theme = "Dark"
})

-- // Tabs // --
local MovementsTab = menu:Tab("Movements")
local VisualsTab = menu:Tab("Visuals")
local ClientTab = menu:Tab("ClientSided")
local ThemesTab = menu:Tab("Themes")
local PremiumTab = menu:Tab("Premium")

-- =====================================================
-- =============== THEMES TAB ==========================
-- =====================================================
local customTheme = {
    Topbar = Color3.fromRGB(30,30,30),
    Background = Color3.fromRGB(20,20,20),
    TabBackground = Color3.fromRGB(25,25,25),
    TextColor = Color3.fromRGB(255,255,255)
}

local ThemesSection = ThemesTab:Section("Theme Settings")
ThemesSection:AddColor({
    text = "Topbar",
    color = customTheme.Topbar,
    callback = function(c) customTheme.Topbar = c end
})
ThemesSection:AddButton({
    text = "Apply Custom Theme",
    callback = function()
        pcall(function() menu:ApplyTheme(customTheme) end)
        notify("Themes","Custom theme applied")
        safeWrite("01Hub/theme.json", customTheme)
    end
})

-- Auto-load saved theme
do
    local saved = safeRead("01Hub/theme.json")
    if type(saved) == "table" then
        pcall(function() menu:ApplyTheme(saved) end)
    end
end

-- =====================================================
-- =============== MOVEMENTS TAB =======================
-- =====================================================
local MoveSection = MovementsTab:Section("Player Movement")

MoveSection:AddSlider({
    text = "WalkSpeed",
    min = 1, max = 200, value = 16,
    callback = function(val)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = val end
    end
})

MoveSection:AddSlider({
    text = "JumpPower",
    min = 20, max = 400, value = 50,
    callback = function(val)
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.UseJumpPower = true hum.JumpPower = val end
    end
})

-- NoClip
local noclipConn
MoveSection:AddToggle({
    text = "NoClip",
    callback = function(state)
        if state then
            if noclipConn then noclipConn:Disconnect() end
            noclipConn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end
            end)
            notify("NoClip","Enabled")
        else
            if noclipConn then noclipConn:Disconnect() noclipConn = nil end
            notify("NoClip","Disabled")
        end
    end
})

-- =====================================================
-- =============== VISUALS TAB (ESP) ===================
-- =====================================================
local espEnabled = false
local itemEspEnabled = false
local espConnections = {}

local function clearEsp()
    for _,v in pairs(espConnections) do v:Disconnect() end
    espConnections = {}
end

local function drawEsp()
    clearEsp()
    if not espEnabled then return end

    for _,plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local box = Drawing.new("Square")
            box.Color = Color3.fromRGB(0,255,0)
            box.Thickness = 1
            box.Transparency = 1
            box.Filled = false

            local conn = RunService.RenderStepped:Connect(function()
                if hrp and hrp.Parent then
                    local pos, vis = Camera:WorldToViewportPoint(hrp.Position)
                    if vis then
                        box.Size = Vector2.new(50,50)
                        box.Position = Vector2.new(pos.X-25,pos.Y-25)
                        box.Visible = true
                    else
                        box.Visible = false
                    end
                else
                    box:Remove()
                    conn:Disconnect()
                end
            end)
            table.insert(espConnections, conn)
        end
    end
end

local VisualSection = VisualsTab:Section("ESP Settings")
VisualSection:AddToggle({
    text = "Player ESP",
    callback = function(state)
        espEnabled = state
        if espEnabled then drawEsp() else clearEsp() end
    end
})

VisualSection:AddToggle({
    text = "Item ESP",
    callback = function(state)
        itemEspEnabled = state
        notify("ESP","Item ESP "..(state and "On" or "Off"))
    end
})

-- =====================================================
-- =============== CLIENT-SIDED TAB ====================
-- =====================================================
local ClientSection = ClientTab:Section("Animations & More")

ClientSection:AddButton({
    text = "Play Dance Animation",
    callback = function()
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://3189773368" -- Dance anim
            local track = hum:LoadAnimation(anim)
            track:Play()
        end
    end
})

-- =====================================================
-- =============== PREMIUM TAB =========================
-- =====================================================
local PremiumSection = PremiumTab:Section("Extras")
PremiumSection:AddLabel("Coming Soon: Cosmetic Unlocks")

-- =====================================================
-- =============== FINAL ===============================
-- =====================================================
notify("01Hub","Loaded v1.8 Optimized")
