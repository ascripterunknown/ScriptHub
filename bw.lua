-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local PlaceId = game.PlaceId

-- Supported games
local supportedGames = {
    [537413528] = "Ninja Legends",
    [142823291] = "Murder Mystery 2",
}

if not supportedGames[PlaceId] then
    warn("Game not supported.")
    return
end

print("Running in:", supportedGames[PlaceId])

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Kat X",
    Icon = "door-open",
    Author = "by .Nusa!",
    Folder = "Kat X V1.7",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = true,
})

-- Tabs
local mm2Tab = Window:CreateTab("MM2 Tools")
local visTab = Window:CreateTab("Visuals")
local miscTab = Window:CreateTab("Misc")

-- === ESP / Role Highlights ===
local highlights = {}
local highlightEnabled = false
local colors = {
    Murderer = Color3.fromRGB(255, 75, 75),
    Sheriff  = Color3.fromRGB(75, 170, 255),
    Innocent = Color3.fromRGB(80, 255, 120),
}

local function ensureHighlight(plr)
    local char = plr.Character
    if not char then return end
    if highlights[plr] then return highlights[plr] end
    local h = Instance.new("Highlight")
    h.FillTransparency = 0.6
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = char
    h.Adornee = char
    highlights[plr] = h
    return h
end

local function updateHighlight(plr)
    local h = highlights[plr]
    if not h then return end
    local role = plr.Character and plr.Character:GetAttribute("Role") or "Innocent"
    h.FillColor = colors[role] or Color3.fromRGB(200, 200, 200)
    h.Enabled = highlightEnabled
end

mm2Tab:CreateToggle("Show Roles (ESP)", false, function(state)
    highlightEnabled = state
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if state then
                ensureHighlight(plr)
                updateHighlight(plr)
            else
                if highlights[plr] then
                    highlights[plr]:Destroy()
                    highlights[plr] = nil
                end
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if highlightEnabled then
            ensureHighlight(plr)
            updateHighlight(plr)
        end
    end)
end)

RunService.Heartbeat:Connect(function()
    if not highlightEnabled then return end
    for plr, _ in pairs(highlights) do
        pcall(function()
            updateHighlight(plr)
        end)
    end
end)

-- === Gun Drop Indicator ===
local gunBillboards = {}
local function attachBillboard(part)
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(120, 36)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.Parent = part
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 1)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 18
    label.Text = "GUN HERE"
    label.TextColor3 = Color3.fromRGB(255, 255, 0)
    label.Parent = bb
    gunBillboards[part] = bb
end

local function scanForGun()
    local tagged = CollectionService:GetTagged("GunDrop")
    if #tagged > 0 then return tagged end
    local found = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("Tool") and inst.Name:lower() == "gun" and inst.Parent == workspace then
            table.insert(found, inst)
        end
    end
    return found
end

local gunConn
mm2Tab:CreateToggle("Gun Drop Indicator", false, function(state)
    if state then
        gunConn = RunService.Heartbeat:Connect(function()
            pcall(function()
                local guns = scanForGun()
                for _, g in ipairs(guns) do
                    if not gunBillboards[g] then
                        local part = g:FindFirstChild("Handle") or g
                        attachBillboard(part)
                    end
                end
                for inst, bb in pairs(gunBillboards) do
                    if not inst.Parent then
                        bb:Destroy()
                        gunBillboards[inst] = nil
                    end
                end
            end)
        end)
    else
        if gunConn then gunConn:Disconnect() end
        for _, bb in pairs(gunBillboards) do
            bb:Destroy()
        end
        gunBillboards = {}
    end
end)

-- === Movement Tweaks ===
local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
mm2Tab:CreateSlider("WalkSpeed", 8, 100, hum and hum.WalkSpeed or 16, function(v)
    pcall(function()
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h then h.WalkSpeed = v end
    end)
end)

mm2Tab:CreateSlider("Jump Power", 50, 200, hum and hum.JumpPower or 50, function(v)
    pcall(function()
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if h then h.JumpPower = v end
    end)
end)

-- === Visuals ===
local cam = workspace.CurrentCamera
visTab:CreateSlider("FOV", 50, 120, cam.FieldOfView, function(v)
    pcall(function()
        cam.FieldOfView = v
    end)
end)

local crosshair = Instance.new("Frame")
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(2, 2)
crosshair.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
crosshair.Visible = false
crosshair.Parent = player:WaitForChild("PlayerGui")

visTab:CreateToggle("Crosshair", false, function(state)
    crosshair.Visible = state
end)

-- === Round Timer ===
local timerLabel = miscTab:CreateLabel("Round: --:--")
local function fmt(t)
    local m = math.floor(t / 60)
    local s = t % 60
    return string.format("%02d:%02d", m, s)
end

local function bindRoundTimer()
    local roundVal = ReplicatedStorage:FindFirstChild("RoundTime")
    if roundVal and roundVal:IsA("NumberValue") then
        roundVal:GetPropertyChangedSignal("Value"):Connect(function()
            timerLabel:SetText("Round: " .. fmt(math.max(0, math.floor(roundVal.Value))))
        end)
        timerLabel:SetText("Round: " .. fmt(math.floor(roundVal.Value)))
    else
        timerLabel:SetText("Round: --:--")
    end
end
bindRoundTimer()
