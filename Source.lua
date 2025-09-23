-- 01Hub v1.8 (Obsidian) — Optimized Full Script
-- Safe-load Obsidian, optimized connections, theme saving, ESP, Movement, Health, Fun, Animations, Premium, Client sided features.

-- ====== CONFIG / RAW URL ======
local OBSIDIAN_RAW = "https://raw.githubusercontent.com/louieiscarl-blip/01Hub/refs/heads/main/source.lua"

-- ====== SERVICES & CACHE ======
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local UserInput      = game:GetService("UserInputService")
local HttpService    = game:GetService("HttpService")
local Workspace      = workspace
local LocalPlayer    = Players.LocalPlayer

-- ====== FILE IO UTILS (best-effort) ======
local hasFile = (type(isfile) == "function") and (type(writefile) == "function") and (type(readfile) == "function") and (type(makefolder) == "function") and (type(isfolder) == "function")
if hasFile then pcall(function() if not isfolder("01Hub") then makefolder("01Hub") end end) end

local function safeWriteJSON(path, tableObj)
    if not hasFile then return end
    pcall(function()
        writefile(path, HttpService:JSONEncode(tableObj))
    end)
end
local function safeReadJSON(path)
    if not hasFile or not isfile(path) then return nil end
    local ok, raw = pcall(function() return readfile(path) end)
    if not ok or not raw then return nil end
    local suc, dec = pcall(function() return HttpService:JSONDecode(raw) end)
    if suc then return dec end
    return nil
end

-- ====== EXECUTION COUNTER ======
local execPath = "01Hub/executions.json"
local executions = 0
do
    local data = safeReadJSON(execPath)
    if type(data) == "table" and tonumber(data.executions) then executions = tonumber(data.executions) end
    executions = executions + 1
    safeWriteJSON(execPath, { executions = executions })
end

-- ====== DETECTORS ======
local function DetectExecutor()
    if identifyexecutor then
        local ok, ex = pcall(identifyexecutor)
        if ok and ex then return tostring(ex) end
    end
    if syn and syn.get_executor then return "Synapse X" end
    if KRNL and KRNL.get_executor then return "Krnl" end
    if getexecutor then return tostring(getexecutor()) end
    return "Unknown"
end
local function DetectDevice()
    if UserInput.TouchEnabled and not UserInput.KeyboardEnabled then return "Mobile" end
    if UserInput.GamepadEnabled and not UserInput.TouchEnabled then return "Console" end
    if UserInput.KeyboardEnabled then return "PC" end
    return "Unknown"
end

-- ====== SAFE-LOAD OBSIDIAN ======
local ok, Obsidian = pcall(function()
    return loadstring(game:HttpGet(OBSIDIAN_RAW))()
end)
if not ok or not Obsidian then
    warn("[01Hub v1.8] Failed to load Obsidian UI library. Check URL / network / executor.")
    return
end

-- instantiate Obsidian
local lib, menu
local okInit, initErr = pcall(function()
    lib = Obsidian({cheatname = "01Hub (Obsidian)", gamename = "Universal"})
    lib:init()
    menu = lib.NewWindow({ title = "01Hub v1.8 (Obsidian)", size = UDim2.new(0, 960, 0, 660) })
end)
if not okInit or not lib or not menu then
    warn("[01Hub v1.8] Obsidian initialization failed:", initErr)
    return
end

-- ====== CONNECTION MANAGEMENT (centralized) ======
local conns = {} -- store RBXScriptConnection objects to manage easier
local function addConn(name, conn)
    if not name or not conn then return end
    if conns[name] then
        pcall(function() conns[name]:Disconnect() end)
    end
    conns[name] = conn
end
local function removeConn(name)
    if conns[name] then
        pcall(function() conns[name]:Disconnect() end)
        conns[name] = nil
    end
end
local function disconnectAll()
    for k,v in pairs(conns) do
        pcall(function() v:Disconnect() end)
        conns[k] = nil
    end
end

-- ====== WINDOW & TABS ======
local HomeTab       = menu:AddTab("Home")
local ThemesTab     = menu:AddTab("Themes")
local MovementsTab  = menu:AddTab("Movements")
local ESPTab        = menu:AddTab("ESP")
local ClientTab     = menu:AddTab("ClientSided")
local AnimTab       = menu:AddTab("Animations")
local PremiumTab    = menu:AddTab("Premium")
local FunTab        = menu:AddTab("Fun")
local HealthTab     = menu:AddTab("Health")

-- small helper wrappers to avoid repeated pcall spam
local function notify(title, content, dur)
    if lib and lib.SendNotification then
        pcall(function() lib:SendNotification(title, content or "", dur or 2) end)
    else
        pcall(function() print("[01Hub]", title, content) end)
    end
end

-- ====== HOME TAB ======
do
    local s = HomeTab:AddSection("Information", 1)
    s:AddText({ text = "01Hub (Obsidian) — v1.8 (Optimized)" })
    s:AddText({ text = "Executor: "..tostring(DetectExecutor()) })
    s:AddText({ text = "Device: "..tostring(DetectDevice()) })
    s:AddText({ text = "Executions (this install): "..tostring(executions) })
    s:AddButton({
        text = "Reset UI (Close Hub)",
        callback = function()
            pcall(function() menu:Close() end)
            notify("01Hub", "UI closed", 2)
        end
    })
end

-- ====== THEMES TAB (multi-textbox & autosave/autofill) ======
local ThemeSection = ThemesTab:AddSection("Themes", 1)
local savedTheme = safeReadJSON("01Hub/theme.json") or nil

local themeDefaults = {
    Topbar = Color3.fromRGB(34,34,34),
    Background = Color3.fromRGB(25,25,25),
    TextColor = Color3.fromRGB(240,240,240),
    Accent = Color3.fromRGB(0,146,214)
}
local customTheme = {
    Topbar = themeDefaults.Topbar,
    Background = themeDefaults.Background,
    TextColor = themeDefaults.TextColor,
    Accent = themeDefaults.Accent
}
-- try to load saved theme into customTheme
if type(savedTheme) == "table" then
    pcall(function()
        for k,v in pairs(savedTheme) do
            if type(v) == "table" and #v == 3 then
                customTheme[k] = Color3.fromRGB(v[1], v[2], v[3])
            end
        end
    end)
end

local function colorToCSV(c)
    if typeof(c) == "Color3" then
        return ("%d,%d,%d"):format(math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
    end
    return "0,0,0"
end
local function parseRGB(txt)
    if not txt then return nil end
    local r,g,b = txt:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
    if r and g and b then
        r,g,b = tonumber(r), tonumber(g), tonumber(b)
        if r and g and b and r>=0 and r<=255 and g>=0 and g<=255 and b>=0 and b<=255 then
            return Color3.fromRGB(r,g,b)
        end
    end
    return nil
end

ThemeSection:AddTextbox({
    text = "Topbar Color (R,G,B)",
    value = colorToCSV(customTheme.Topbar),
    callback = function(txt)
        local c = parseRGB(txt)
        if c then customTheme.Topbar = c; notify("Themes","Topbar set",1) else notify("Themes","Invalid R,G,B",2) end
    end
})
ThemeSection:AddTextbox({
    text = "Background Color (R,G,B)",
    value = colorToCSV(customTheme.Background),
    callback = function(txt)
        local c = parseRGB(txt)
        if c then customTheme.Background = c; notify("Themes","Background set",1) else notify("Themes","Invalid R,G,B",2) end
    end
})
ThemeSection:AddTextbox({
    text = "Text Color (R,G,B)",
    value = colorToCSV(customTheme.TextColor),
    callback = function(txt)
        local c = parseRGB(txt)
        if c then customTheme.TextColor = c; notify("Themes","Text color set",1) else notify("Themes","Invalid R,G,B",2) end
    end
})
ThemeSection:AddTextbox({
    text = "Accent Color (R,G,B)",
    value = colorToCSV(customTheme.Accent),
    callback = function(txt)
        local c = parseRGB(txt)
        if c then customTheme.Accent = c; notify("Themes","Accent set",1) else notify("Themes","Invalid R,G,B",2) end
    end
})

ThemeSection:AddButton({
    text = "Apply & Save Theme",
    callback = function()
        -- save as arrays for compatibility
        local sav = {
            Topbar = { math.floor(customTheme.Topbar.R*255+0.5), math.floor(customTheme.Topbar.G*255+0.5), math.floor(customTheme.Topbar.B*255+0.5) },
            Background = { math.floor(customTheme.Background.R*255+0.5), math.floor(customTheme.Background.G*255+0.5), math.floor(customTheme.Background.B*255+0.5) },
            TextColor = { math.floor(customTheme.TextColor.R*255+0.5), math.floor(customTheme.TextColor.G*255+0.5), math.floor(customTheme.TextColor.B*255+0.5) },
            Accent = { math.floor(customTheme.Accent.R*255+0.5), math.floor(customTheme.Accent.G*255+0.5), math.floor(customTheme.Accent.B*255+0.5) },
        }
        -- Try to call theme apply on menu or lib if supported; best-effort
        pcall(function() if menu and menu.ApplyTheme then menu:ApplyTheme(customTheme) end end)
        pcall(function() if lib and lib.ApplyTheme then lib:ApplyTheme(customTheme) end end)
        safeWriteJSON("01Hub/theme.json", sav)
        notify("Themes", "Theme applied & saved", 2)
    end
})

ThemeSection:AddButton({
    text = "Reset Theme to Defaults",
    callback = function()
        customTheme = {
            Topbar = themeDefaults.Topbar,
            Background = themeDefaults.Background,
            TextColor = themeDefaults.TextColor,
            Accent = themeDefaults.Accent
        }
        pcall(function() if menu and menu.ApplyTheme then menu:ApplyTheme(customTheme) end end)
        safeWriteJSON("01Hub/theme.json", {
            Topbar = {34,34,34}, Background = {25,25,25}, TextColor = {240,240,240}, Accent = {0,146,214}
        })
        notify("Themes","Reset & saved",2)
    end
})

-- ====== MOVEMENTS (optimized helpers) ======
local MoveSection = MovementsTab:AddSection("Movement", 1)
local function getHumanoid(character)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end
local function safeSetWalkSpeed(val)
    local char = LocalPlayer.Character
    local hum = getHumanoid(char)
    if hum then pcall(function() hum.WalkSpeed = val end) end
end
local function safeSetJumpPower(val)
    local char = LocalPlayer.Character
    local hum = getHumanoid(char)
    if hum then pcall(function() hum.UseJumpPower = true hum.JumpPower = val end) end
end

-- WalkSpeed slider
MoveSection:AddSlider({
    text = "WalkSpeed",
    min = 1, max = 250, value = 16, increment = 1, flag = "walkspeed",
    callback = function(v) safeSetWalkSpeed(v) end
})
-- JumpPower slider
MoveSection:AddSlider({
    text = "JumpPower",
    min = 10, max = 500, value = 50, increment = 1, flag = "jumppower",
    callback = function(v) safeSetJumpPower(v) end
})

-- NoClip (client) optimized: only modify parts that are collidable
local noclipConnName = "noclip"
local function enableNoclip()
    removeConn = removeConn -- quiet to avoid linter warnings
    removeConn = nil
    removeConn = nil
end
MoveSection:AddToggle({
    text = "NoClip (client)",
    flag = "noclip_toggle",
    callback = function(state)
        if state then
            addConn(noclipConnName, RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") and part.CanCollide then
                            pcall(function() part.CanCollide = false end)
                        end
                    end
                end
            end))
            notify("NoClip","Enabled (client)", 1.5)
        else
            removeConn(noclipConnName)
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        pcall(function() part.CanCollide = true end)
                    end
                end
            end
            notify("NoClip","Disabled", 1.2)
        end
    end
})

-- Infinite Jump
local infJumpFlag = false
MoveSection:AddToggle({
    text = "Infinite Jump",
    flag = "infjump",
    callback = function(v) infJumpFlag = v end
})
addConn("jumpReq", UserInput.JumpRequest:Connect(function()
    if infJumpFlag then
        local hum = getHumanoid(LocalPlayer.Character)
        if hum and hum.Health > 0 then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end
end))

-- Double Jump (lightweight)
local doubleEnabled = false
do
    local canDouble, didDouble = false, false
    local function setupForChar(char)
        if not char then return end
        local hum = getHumanoid(char)
        if not hum then return end
        didDouble = false; canDouble = false
        local conn
        conn = hum.StateChanged:Connect(function(oldState, newState)
            if newState == Enum.HumanoidStateType.Freefall then canDouble = true end
            if newState == Enum.HumanoidStateType.Landed then canDouble = false; didDouble = false end
        end)
        addConn("doublehum"..tostring(char:FindFirstChild("Humanoid") or ""), conn)
    end
    if LocalPlayer.Character then setupForChar(LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(setupForChar)

    MoveSection:AddToggle({
        text = "Double Jump",
        flag = "doublejump",
        callback = function(v) doubleEnabled = v end
    })
    addConn("doubleJumpReq", UserInput.JumpRequest:Connect(function()
        if doubleEnabled and canDouble and not didDouble then
            local hum = getHumanoid(LocalPlayer.Character)
            if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end); didDouble = true end
        end
    end))
end

-- CFrame Fly (optimized)
local flyState = { enabled = false, connName = "cfly", speed = 80 }
MoveSection:AddToggle({
    text = "CFrame Fly (toggle)",
    flag = "cfly_toggle",
    callback = function(v)
        flyState.enabled = v
        local char = LocalPlayer.Character
        if not char then return end
        local HRP = char:FindFirstChild("HumanoidRootPart")
        local HUM = getHumanoid(char)
        if not HRP or not HUM then return end
        if v then
            pcall(function() HUM.PlatformStand = true end)
            addConn(flyState.connName, RunService.RenderStepped:Connect(function(dt)
                if not flyState.enabled then return end
                local cam = Workspace.CurrentCamera
                local move = Vector3.zero
                if UserInput:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
                if UserInput:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
                if UserInput:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
                if UserInput:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
                if UserInput:IsKeyDown(Enum.KeyCode.Space) then move += Vector3.new(0,1,0) end
                if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0,1,0) end
                if move.Magnitude > 0 then
                    HRP.CFrame = HRP.CFrame + (move.Unit * flyState.speed * dt)
                end
            end))
            notify("Fly","CFrame Fly enabled",1.6)
        else
            removeConn(flyState.connName)
            pcall(function() HUM.PlatformStand = false end)
            notify("Fly","Disabled",1.2)
        end
    end
})
MoveSection:AddSlider({
    text = "Fly Speed",
    min = 10, max = 500, value = flyState.speed, increment = 5,
    callback = function(v) flyState.speed = v end
})

-- ====== ESP (optimized rendering & caching) ======
local ESPSection = ESPTab:AddSection("ESP", 1)
local ESP = {
    Enabled = false,
    Charms = true,
    Highlight3D = true,
    PlayerNames = true,
    Items = true,
    loopConnName = "espLoop",
    players = {}, -- mapping player -> { highlight, billboard }
    items = {}    -- mapping instance -> { highlight, billboard }
}

local function safeDestroyInstance(i)
    pcall(function()
        if i and i.Parent then i:Destroy() end
    end)
end

local function removeCharms(model)
    if not model then return end
    for _, c in pairs(model:GetDescendants()) do
        if c.Name == "01HubCharm" and c:IsA("BasePart") then pcall(function() c:Destroy() end) end
    end
end

local function createHighlight(target, color)
    if not target then return nil end
    local ok, h = pcall(function()
        local hl = Instance.new("Highlight")
        hl.Name = "01Hub_Highlight"
        hl.Adornee = target
        hl.FillColor = color or Color3.fromRGB(0,200,0)
        hl.OutlineColor = Color3.fromRGB(0,0,0)
        hl.FillTransparency = 0.6
        hl.Parent = target.Parent or Workspace
        return hl
    end)
    return ok and h or nil
end

local function addCharm(part, color)
    pcall(function()
        if not part or not part.Parent then return end
        if part:FindFirstChild("01HubCharm") then return end
        local charm = Instance.new("Part")
        charm.Name = "01HubCharm"
        charm.Size = Vector3.new(0.6,0.6,0.6)
        charm.Shape = Enum.PartType.Ball
        charm.Anchored = false
        charm.CanCollide = false
        charm.Material = Enum.Material.Neon
        charm.Color = color or Color3.new(1,1,1)
        charm.Parent = part.Parent
        charm.CFrame = part.CFrame * CFrame.new(0,2,0)
        local w = Instance.new("WeldConstraint", charm)
        w.Part0 = charm; w.Part1 = part
    end)
end

local function isItemCandidate(inst)
    if not inst then return false end
    if inst:IsA("Tool") then return true end
    if inst:IsA("Model") and (inst:FindFirstChild("Handle") or inst.PrimaryPart) then return true end
    if inst:IsA("BasePart") then
        local pn = inst.Parent and inst.Parent.Name:lower() or ""
        if pn:match("shop") or pn:match("drop") or pn:match("loot") or pn:match("item") then return true end
    end
    return false
end

local function cleanupAllESP()
    for pl,info in pairs(ESP.players) do
        pcall(function() if info.highlight then info.highlight:Destroy() end end)
        pcall(function() if info.billboard then info.billboard:Destroy() end end)
        removeCharms(pl.Character or {})
    end
    table.clear(ESP.players)
    for inst,info in pairs(ESP.items) do
        pcall(function() if info.highlight then info.highlight:Destroy() end end)
        pcall(function() if info.billboard then info.billboard:Destroy() end end)
        removeCharms(inst)
    end
    table.clear(ESP.items)
end

local function espRender()
    -- players (iterate Players:GetPlayers once)
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == LocalPlayer then
            -- skip local
        else
            local char = pl.Character
            local root = char and (char:FindFirstChild("HumanoidRootPart") or char.PrimaryPart)
            if root then
                -- highlight
                if ESP.Highlight3D then
                    if not (ESP.players[pl] and ESP.players[pl].highlight) then
                        local ok, h = pcall(createHighlight, root, Color3.fromRGB(0,200,0))
                        ESP.players[pl] = ESP.players[pl] or {}
                        ESP.players[pl].highlight = ok and h or nil
                    end
                else
                    if ESP.players[pl] and ESP.players[pl].highlight then safeDestroyInstance(ESP.players[pl].highlight); ESP.players[pl].highlight=nil end
                end
                -- charms
                if ESP.Charms then addCharm(root, Color3.fromRGB(0,200,0)) end
                -- billboard name
                if ESP.PlayerNames then
                    if not (ESP.players[pl] and ESP.players[pl].billboard) then
                        pcall(function()
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "01Hub_PlayerName"
                            bb.Adornee = root
                            bb.ExtentsOffset = Vector3.new(0,2.5,0)
                            bb.Size = UDim2.new(0,120,0,36)
                            bb.AlwaysOnTop = true
                            local label = Instance.new("TextLabel", bb)
                            label.Size = UDim2.new(1,0,1,0)
                            label.BackgroundTransparency = 1
                            label.Text = pl.Name
                            label.TextScaled = true
                            label.TextColor3 = Color3.fromRGB(255,255,255)
                            bb.Parent = root
                            ESP.players[pl] = ESP.players[pl] or {}
                            ESP.players[pl].billboard = bb
                        end)
                    end
                else
                    if ESP.players[pl] and ESP.players[pl].billboard then safeDestroyInstance(ESP.players[pl].billboard); ESP.players[pl].billboard=nil end
                end
            else
                -- cleanup if no root
                if ESP.players[pl] then
                    pcall(function() if ESP.players[pl].highlight then ESP.players[pl].highlight:Destroy() end end)
                    pcall(function() if ESP.players[pl].billboard then ESP.players[pl].billboard:Destroy() end end)
                    removeCharms(pl.Character or {})
                    ESP.players[pl] = nil
                end
            end
        end
    end

    -- items: iterate workspace descendants but with early break if too many (prevent heavy loops)
    local count = 0
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if isItemCandidate(inst) then
            if inst:IsDescendantOf(LocalPlayer.Character) then
                -- skip
            else
                local adorn = nil
                if inst:IsA("Tool") then adorn = inst:FindFirstChild("Handle") or inst:FindFirstChildWhichIsA("BasePart") end
                if inst:IsA("Model") then adorn = inst.PrimaryPart or inst:FindFirstChild("Handle") or inst:FindFirstChildWhichIsA("BasePart") end
                if inst:IsA("BasePart") then adorn = inst end
                if adorn then
                    if ESP.Highlight3D then
                        if not (ESP.items[inst] and ESP.items[inst].highlight) then
                            local ok, h = pcall(createHighlight, adorn, Color3.fromRGB(255,200,0))
                            ESP.items[inst] = ESP.items[inst] or {}
                            ESP.items[inst].highlight = ok and h or nil
                        end
                    else
                        if ESP.items[inst] and ESP.items[inst].highlight then safeDestroyInstance(ESP.items[inst].highlight); ESP.items[inst].highlight=nil end
                    end
                    if ESP.Charms then addCharm(adorn, Color3.fromRGB(255,200,0)) end
                    if not (ESP.items[inst] and ESP.items[inst].billboard) then
                        pcall(function()
                            local bb = Instance.new("BillboardGui")
                            bb.Name = "01Hub_Item"
                            bb.Adornee = adorn
                            bb.ExtentsOffset = Vector3.new(0,1,0)
                            bb.Size = UDim2.new(0,120,0,28)
                            bb.AlwaysOnTop = true
                            local label = Instance.new("TextLabel", bb)
                            label.Size = UDim2.new(1,0,1,0)
                            label.BackgroundTransparency = 1
                            label.Text = inst.Name or "Item"
                            label.TextScaled = true
                            label.TextColor3 = Color3.fromRGB(255,255,255)
                            bb.Parent = adorn
                            ESP.items[inst] = ESP.items[inst] or {}
                            ESP.items[inst].billboard = bb
                        end)
                    end
                end
            end
        end
        count = count + 1
        if count > 1200 then break end -- safety cap per frame
    end
end

local function startESP()
    removeConn = removeConn -- no-op to quiet linter
    removeConn = nil
    if conns[ESP.loopConnName] then return end
    addConn(ESP.loopConnName, RunService.RenderStepped:Connect(function()
        if not ESP.Enabled then return end
        espRender()
    end))
end
local function stopESP()
    removeConn(ESP.loopConnName)
    cleanupAllESP()
end

ESPSection:AddToggle({ text = "Enable ESP", flag = "esp_enable", callback = function(v) ESP.Enabled = v if v then startESP() else stopESP() end end })
ESPSection:AddToggle({ text = "Charms (Neon)", flag = "esp_charms", current = true, callback = function(v) ESP.Charms = v end })
ESPSection:AddToggle({ text = "3D Highlight", flag = "esp_3d", current = true, callback = function(v) ESP.Highlight3D = v end })
ESPSection:AddToggle({ text = "Show Player Names", flag = "esp_names", current = true, callback = function(v) ESP.PlayerNames = v end })
ESPSection:AddToggle({ text = "Detect Items", flag = "esp_items", current = true, callback = function(v) ESP.Items = v end })
ESPSection:AddButton({ text = "Clear ESP Decorations", callback = function() cleanupAllESP(); notify("ESP","Cleared",1.2) end })

-- ====== ANIMATIONS TAB ======
local AnimSection = AnimTab:AddSection("Animations", 1)
local function playAnimID(id)
    local idn = tonumber(id)
    if not idn then notify("Anim","Invalid ID",2); return end
    local hum = getHumanoid(LocalPlayer.Character)
    if not hum then notify("Anim","No Humanoid",2); return end
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://"..tostring(idn)
    local ok, track = pcall(function() return hum:LoadAnimation(anim) end)
    if ok and track then pcall(function() track:Play() end) else notify("Anim","Failed to play",2) end
end

AnimSection:AddButton({ text = "Dance (preset)", callback = function() playAnimID(182436842) end })
AnimSection:AddButton({ text = "Zombie (preset)", callback = function() playAnimID(616158929) end })
AnimSection:AddInput({ text = "Custom Anim ID", placeholder = "Animation ID", callback = function(s) playAnimID(s) end })
AnimSection:AddButton({ text = "Stop All Local Animations", callback = function()
    local hum = getHumanoid(LocalPlayer.Character)
    if hum then for _, tr in ipairs(hum:GetPlayingAnimationTracks()) do pcall(function() tr:Stop() end) end end
end })

-- ====== CLIENT SIDED TAB ======
local ClientSection = ClientTab:AddSection("Client Visuals", 1)
ClientSection:AddInput({
    text = "Custom Display Name (visual only)",
    placeholder = "Name (visual)",
    callback = function(s)
        pcall(function() LocalPlayer.DisplayName = tostring(s) end)
        notify("Client","DisplayName changed (visual only)",1.2)
    end
})
ClientSection:AddSlider({
    text = "Camera FOV",
    min = 50, max = 140, value = Workspace.CurrentCamera.FieldOfView or 70, increment = 1,
    callback = function(v) pcall(function() Workspace.CurrentCamera.FieldOfView = v end) end
})
ClientSection:AddSlider({
    text = "Gravity (workspace)",
    min = 0, max = 300, value = Workspace.Gravity or 196.2, increment = 1,
    callback = function(v) pcall(function() Workspace.Gravity = v end) end
})

-- ====== PREMIUM (cosmetic) ======
local PremiumSection = PremiumTab:AddSection("Premium (Cosmetic)", 1)
PremiumSection:AddLabel({ text = "Cosmetic features - client only" })
PremiumSection:AddButton({
    text = "Spawn Draggable ClickTP",
    callback = function()
        local gui = Instance.new("ScreenGui")
        gui.Name = "01Hub_ClickTP"
        gui.ResetOnSpawn = false
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        local btn = Instance.new("TextButton", gui)
        btn.Size = UDim2.new(0,130,0,48)
        btn.Position = UDim2.new(0.5,-65,0.88,-24)
        btn.Text = "ClickTP"
        btn.Draggable = true
        btn.BackgroundTransparency = 0.35
        btn.MouseButton1Down:Connect(function()
            local m = LocalPlayer:GetMouse()
            if m.Target then pcall(function() LocalPlayer.Character:MoveTo(m.Hit.p + Vector3.new(0,3,0)) end) end
        end)
        notify("Premium","ClickTP spawned",1.5)
    end
})
local flingPower = 450
PremiumSection:AddSlider({
    text = "Fling Strength",
    min = 50, max = 4000, value = flingPower, increment = 10,
    callback = function(v) flingPower = v end
})
PremiumSection:AddButton({
    text = "Fling Self (local)",
    callback = function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() hrp.Velocity = hrp.CFrame.LookVector * flingPower + Vector3.new(0, flingPower/2, 0) end) end
    end
})

-- ====== HEALTH TAB ======
local HealthSection = HealthTab:AddSection("Survival", 1)
local autoHealConnName = "autoHeal"
HealthSection:AddToggle({
    text = "Auto Heal (client)",
    flag = "autoheal",
    callback = function(v)
        if not v then removeConn(autoHealConnName); notify("Health","Auto Heal disabled",1) return end
        removeConn(autoHealConnName)
        addConn(autoHealConnName, RunService.Heartbeat:Connect(function()
            local hum = getHumanoid(LocalPlayer.Character)
            if hum and hum.Health < hum.MaxHealth then pcall(function() hum.Health = hum.MaxHealth end) end
        end))
        notify("Health","Auto Heal enabled",1.5)
    end
})
local godConnName = "godmode"
HealthSection:AddToggle({
    text = "Godmode (client)",
    flag = "godmode",
    callback = function(v)
        if not v then removeConn(godConnName); notify("Godmode","Disabled",1); return end
        removeConn(godConnName)
        addConn(godConnName, RunService.Heartbeat:Connect(function()
            local hum = getHumanoid(LocalPlayer.Character)
            if hum then pcall(function() hum.Health = hum.MaxHealth end) end
        end))
        notify("Godmode","Client-side enabled",2)
    end
})

-- ====== FUN TAB ======
local FunSection = FunTab:AddSection("Fun", 1)
local platformPool = {}  -- pool of created platforms (max 2)
local function spawnPlatformAtHRP()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if #platformPool >= 2 then
        local old = table.remove(platformPool, 1)
        pcall(function() if old and old.Parent then old:Destroy() end end)
    end
    local p = Instance.new("Part")
    p.Name = "01Hub_Platform"
    p.Size = Vector3.new(10,1,10)
    p.Anchored = true
    p.CanCollide = true
    p.CFrame = hrp.CFrame * CFrame.new(0,-4,0)
    p.Parent = Workspace
    table.insert(platformPool, p)
    notify("Fun","Platform spawned",1.2)
end
FunSection:AddButton({ text = "Create Platform (max 2)", callback = spawnPlatformAtHRP })
FunSection:AddButton({ text = "Clear Platforms", callback = function()
    for _,p in ipairs(platformPool) do pcall(function() if p and p.Parent then p:Destroy() end end) end
    platformPool = {}
    notify("Fun","Platforms cleared",1)
end })

-- ====== CLEANUP UTILITIES ======
local function cleanupESPObjects() cleanupAllESP() end
local function cleanupAll()
    -- disconnect conns
    disconnectAll()
    -- cleanup ESP & platform visuals & GUIs
    cleanupAllESP()
    for _, p in ipairs(platformPool) do pcall(function() if p and p.Parent then p:Destroy() end end) end
    platformPool = {}
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            local g = pg:FindFirstChild("01Hub_ClickTP")
            if g then g:Destroy() end
        end
    end)
    notify("01Hub","Cleaned up all connections & visuals",1.5)
end

-- Bind cleanup on close
game:BindToClose(function() pcall(cleanupAll) end)

-- ====== FINISH ======
notify("01Hub v1.8", "Loaded (Obsidian) — Exec: "..DetectExecutor().." / "..DetectDevice(), 4)

-- return helpers so you can call cleanup from REPL
return {
    cleanup = cleanupAll,
    lib = lib,
    menu = menu
}
