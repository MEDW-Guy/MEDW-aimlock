local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local aimbotEnabled = false
local espPlayersEnabled = false
local espBotsEnabled = false
local espModelEnabled = false
local headAimPlayers = false
local botAimEnabled = false
local headAimBots = false
local fov = 120
local teamCheck = false
local currentTarget = nil
local currentTargetDistance = "N/A"
local currentColor = Color3.fromHSV(0, 1, 1)

local fillTransparency = 0.5
local outlineTransparency = 0.3
local smoothing = 0.2
local predictEnabled = true

local activeESP = {}
local pending = {}
local scanning = false

local function isStandardBot(model)
    if not model or model == localPlayer.Character then return false end
    if model:IsA("Tool") then return false end
    if not model:FindFirstChild("HumanoidRootPart") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    return true
end

local function isCustomModel(model)
    if not model or model == localPlayer.Character then return false end
    if model:IsA("Tool") then return false end
    if Players:GetPlayerFromCharacter(model) then return true end

    local function isDecoration(model)
        local name = model.Name:lower()
        local forbidden = {"door", "window", "wall", "floor", "ceiling", "prop", "decoration", "furniture", "stairs", "railing", "pipe", "vent", "crate", "barrel", "container"}
        for _, word in ipairs(forbidden) do
            if string.find(name, word) then
                return true
            end
        end
        local parent = model.Parent
        while parent do
            local pname = parent.Name:lower()
            for _, word in ipairs(forbidden) do
                if string.find(pname, word) then
                    return true
                end
            end
            parent = parent.Parent
        end
        if string.find(model:GetFullName():lower(), "activemap") or string.find(model:GetFullName():lower(), "map") or string.find(model:GetFullName():lower(), "decor") then
            return true
        end
        return false
    end

    if isDecoration(model) then
        return false
    end

    if model:FindFirstChild("Humanoid") then
        return true
    end

    local hasHead = model:FindFirstChild("Head") ~= nil
    local hasAnim = model:FindFirstChild("AnimationController") ~= nil
    local hasRoot = model:FindFirstChild("HumanoidRootPart") ~= nil or model.PrimaryPart ~= nil

    local partCount = 0
    for _, child in ipairs(model:GetDescendants()) do
        if child:IsA("BasePart") then
            partCount = partCount + 1
            if partCount > 3 then break end
        end
    end

    if (hasHead or hasAnim) and (hasRoot or partCount > 3) then
        return true
    end

    local name = model.Name:lower()
    if string.find(name, "character") or string.find(name, "player") or string.find(name, "bot") then
        if hasRoot or partCount > 3 then
            return true
        end
    end

    return false
end

local function getTargetType(model)
    if not model or model == localPlayer.Character then return nil end
    local plr = Players:GetPlayerFromCharacter(model)
    if plr then return "player", plr end
    if isStandardBot(model) then return "bot", model end
    if isCustomModel(model) then return "custom", model end
    return nil
end

local function getName(model, targetType, ref)
    if targetType == "player" and ref then return ref.Name end
    if targetType == "bot" and ref then return ref.Name or "Bot" end
    if targetType == "custom" and ref then return ref.Name or "Model" end
    return model.Name or "?"
end

local function getBillboardPart(model)
    local part = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if part then return part end
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("BasePart") then return child end
    end
    return nil
end

local function addESP(model, targetType, ref)
    if pending[model] or activeESP[model] then return end
    pending[model] = true
    task.spawn(function()
        local name = getName(model, targetType, ref)
        local highlight = Instance.new("Highlight")
        highlight.FillColor = currentColor
        highlight.OutlineColor = Color3.new(1,1,1)
        highlight.FillTransparency = fillTransparency
        highlight.OutlineTransparency = outlineTransparency
        highlight.Adornee = model
        highlight.Parent = model
        local billboard = nil
        local part = getBillboardPart(model)
        if part then
            billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.new(0,200,0,50)
            billboard.StudsOffset = Vector3.new(0,3,0)
            billboard.AlwaysOnTop = true
            billboard.Parent = part
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1,0,1,0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = name
            textLabel.TextColor3 = Color3.new(1,1,1)
            textLabel.TextScaled = false
            textLabel.TextSize = 10
            textLabel.Font = Enum.Font.GothamBold
            textLabel.TextStrokeTransparency = 0.5
            textLabel.Parent = billboard
        end
        activeESP[model] = {highlight, billboard}
        pending[model] = nil
    end)
end

local function removeESP(model)
    local data = activeESP[model]
    if data then
        if data[1] then data[1]:Destroy() end
        if data[2] then data[2]:Destroy() end
        activeESP[model] = nil
    end
    pending[model] = nil
end

local function clearAllESP()
    for model in pairs(activeESP) do removeESP(model) end
end

local function updateAllColors()
    for model, data in pairs(activeESP) do
        if data and data[1] then
            data[1].FillColor = currentColor
            data[1].FillTransparency = fillTransparency
            data[1].OutlineTransparency = outlineTransparency
        end
    end
end

local function processModel(model)
    if not model or model == localPlayer.Character then return end
    local targetType, ref = getTargetType(model)
    if not targetType then
        if activeESP[model] then removeESP(model) end
        return
    end
    local enabled = false
    if targetType == "player" and espPlayersEnabled then enabled = true
    elseif targetType == "bot" and espBotsEnabled then enabled = true
    elseif targetType == "custom" and espModelEnabled then enabled = true
    end
    if not enabled then
        if activeESP[model] then removeESP(model) end
        return
    end
    if activeESP[model] then return end
    addESP(model, targetType, ref)
end

local function refreshESP()
    if not espPlayersEnabled and not espBotsEnabled and not espModelEnabled then
        clearAllESP()
        return
    end
    if scanning then return end
    scanning = true
    task.spawn(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                processModel(player.Character)
            end
        end
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") then
                processModel(obj)
            elseif obj:IsA("Humanoid") then
                local model = obj.Parent
                if model and model:IsA("Model") then
                    processModel(model)
                end
            end
        end
        scanning = false
    end)
end

local function startTrackingESP()
    Workspace.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if obj:IsA("Model") then
                processModel(obj)
            elseif obj:IsA("Humanoid") then
                local model = obj.Parent
                if model and model:IsA("Model") then
                    processModel(model)
                end
            end
        end)
    end)
    Workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("Model") and activeESP[obj] then
            removeESP(obj)
        elseif obj:IsA("Humanoid") then
            local model = obj.Parent
            if model and model:IsA("Model") and activeESP[model] then
                removeESP(model)
            end
        end
    end)
end

local cachedPlayerTargets = {}
local cachedBotTargets = {}
local cachedCustomTargets = {}

local function rebuildPlayerTargets()
    local new = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            local char = player.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local aimPart = root
                if headAimPlayers then
                    local head = char:FindFirstChild("Head")
                    if head then aimPart = head end
                end
                table.insert(new, { aimPart = aimPart, type = "player", ref = player, model = char })
            end
        end
    end
    cachedPlayerTargets = new
end

local function addStandardBot(model)
    if not botAimEnabled then return end
    if not isStandardBot(model) then return end
    for _, t in ipairs(cachedBotTargets) do
        if t.model == model then return end
    end
    local root = model:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local aimPart = root
    if headAimBots then
        local head = model:FindFirstChild("Head")
        if head and head:IsA("BasePart") then
            aimPart = head
        end
    end
    table.insert(cachedBotTargets, { aimPart = aimPart, type = "bot", ref = model, model = model })
end

local function removeStandardBot(model)
    for i, t in ipairs(cachedBotTargets) do
        if t.model == model then
            table.remove(cachedBotTargets, i)
            break
        end
    end
end

local function addCustomModel(model)
    if not botAimEnabled then return end
    if not espModelEnabled then return end
    if not isCustomModel(model) then return end
    if Players:GetPlayerFromCharacter(model) then return end
    for _, t in ipairs(cachedCustomTargets) do
        if t.model == model then return end
    end
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root then return end
    local aimPart = root
    if headAimBots then
        local head = model:FindFirstChild("Head") or model:FindFirstChild("head")
        if head and head:IsA("BasePart") then
            aimPart = head
        end
    end
    table.insert(cachedCustomTargets, { aimPart = aimPart, type = "custom", ref = model, model = model })
end

local function removeCustomModel(model)
    for i, t in ipairs(cachedCustomTargets) do
        if t.model == model then
            table.remove(cachedCustomTargets, i)
            break
        end
    end
end

local function rebuildAllTargets()
    task.spawn(function()
        local newBots = {}
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and isStandardBot(obj) then
                local root = obj:FindFirstChild("HumanoidRootPart")
                if root then
                    local aimPart = root
                    if headAimBots then
                        local head = obj:FindFirstChild("Head")
                        if head and head:IsA("BasePart") then
                            aimPart = head
                        end
                    end
                    table.insert(newBots, { aimPart = aimPart, type = "bot", ref = obj, model = obj })
                end
            end
        end
        cachedBotTargets = newBots
        if espModelEnabled then
            local newCustom = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("Model") and isCustomModel(obj) and not Players:GetPlayerFromCharacter(obj) then
                    local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                    if root then
                        local aimPart = root
                        if headAimBots then
                            local head = obj:FindFirstChild("Head") or obj:FindFirstChild("head")
                            if head and head:IsA("BasePart") then
                                aimPart = head
                            end
                        end
                        table.insert(newCustom, { aimPart = aimPart, type = "custom", ref = obj, model = obj })
                    end
                end
            end
            cachedCustomTargets = newCustom
        else
            cachedCustomTargets = {}
        end
    end)
end

local function setupAimTracking()
    rebuildPlayerTargets()
    rebuildAllTargets()
    Players.PlayerAdded:Connect(rebuildPlayerTargets)
    Players.PlayerRemoving:Connect(rebuildPlayerTargets)
    for _, player in ipairs(Players:GetPlayers()) do
        player.CharacterAdded:Connect(rebuildPlayerTargets)
        player.CharacterRemoving:Connect(rebuildPlayerTargets)
    end
    Workspace.DescendantAdded:Connect(function(obj)
        task.defer(function()
            if obj:IsA("Model") then
                addStandardBot(obj)
                addCustomModel(obj)
            elseif obj:IsA("Humanoid") then
                local model = obj.Parent
                if model and model:IsA("Model") then
                    addStandardBot(model)
                    addCustomModel(model)
                end
            end
        end)
    end)
    Workspace.DescendantRemoving:Connect(function(obj)
        if obj:IsA("Model") then
            removeStandardBot(obj)
            removeCustomModel(obj)
        elseif obj:IsA("Humanoid") then
            local model = obj.Parent
            if model and model:IsA("Model") then
                removeStandardBot(model)
                removeCustomModel(model)
            end
        end
    end)
end
setupAimTracking()

local function getCombinedTargets()
    local combined = {}
    for _, t in ipairs(cachedPlayerTargets) do table.insert(combined, t) end
    if botAimEnabled then
        for _, t in ipairs(cachedBotTargets) do table.insert(combined, t) end
        if espModelEnabled then
            for _, t in ipairs(cachedCustomTargets) do table.insert(combined, t) end
        end
    end
    return combined
end

local function getClosestTarget()
    local closest = nil
    local shortestDist = math.huge
    local screenCenter = Camera.ViewportSize / 2
    local playerPos = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    playerPos = playerPos and playerPos.Position or Vector3.new(0,0,0)
    for _, t in ipairs(getCombinedTargets()) do
        local aimPart = t.aimPart
        if aimPart and aimPart.Parent then
            local dist = (playerPos - aimPart.Position).Magnitude
            local screenPoint, onScreen = Camera:WorldToViewportPoint(aimPart.Position)
            local distScreen = (Vector2.new(screenPoint.X, screenPoint.Y) - screenCenter).Magnitude
            if onScreen and distScreen < shortestDist and distScreen <= fov then
                if not teamCheck then
                    closest = t
                    shortestDist = distScreen
                    currentTargetDistance = math.floor(dist)
                end
            end
        end
    end
    return closest
end

local function lockOnTarget()
    if currentTarget and currentTarget.aimPart and currentTarget.aimPart.Parent then
        local aimPart = currentTarget.aimPart
        local targetPos = aimPart.Position
        if predictEnabled then
            local vel = aimPart.Velocity or Vector3.new(0,0,0)
            local pred = math.clamp(0.05 + (currentTargetDistance / 2000), 0.02, 0.1)
            targetPos = targetPos + (vel * pred)
        end
        local desiredCF = CFrame.new(Camera.CFrame.Position, targetPos)
        Camera.CFrame = Camera.CFrame:Lerp(desiredCF, smoothing)
    else
        currentTarget = nil
    end
end

RunService.RenderStepped:Connect(function()
    if aimbotEnabled then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
            if not currentTarget then
                currentTarget = getClosestTarget()
            end
            if currentTarget then
                lockOnTarget()
            end
        else
            currentTarget = nil
        end
    end
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MEDW_Menu"
screenGui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 210, 0, 355)
mainFrame.Position = UDim2.new(1, -225, 0, 20)
mainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
mainFrame.BackgroundTransparency = 0.08
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 10)

local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(-0.05, 0, -0.05, 0)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.new(0,0,0)
shadow.ImageTransparency = 0.6
shadow.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, 0)
content.Position = UDim2.new(0, 0, 0, 0)
content.BackgroundTransparency = 1
content.Parent = mainFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 36)
header.Position = UDim2.new(0, 0, 0, 0)
header.BackgroundTransparency = 1
header.Parent = content

local logo = Instance.new("TextLabel")
logo.Size = UDim2.new(0.7, 0, 1, 0)
logo.Position = UDim2.new(0.15, 0, 0, 0)
logo.BackgroundTransparency = 1
logo.Text = "MEDW"
logo.TextColor3 = Color3.fromRGB(235, 235, 240)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 20
logo.TextXAlignment = Enum.TextXAlignment.Center
logo.TextYAlignment = Enum.TextYAlignment.Center
logo.Parent = header

local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 30, 0, 30)
collapseBtn.Position = UDim2.new(1, -40, 0, 3)
collapseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
collapseBtn.BorderSizePixel = 0
collapseBtn.Text = "−"
collapseBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 24
collapseBtn.TextXAlignment = Enum.TextXAlignment.Center
collapseBtn.TextYAlignment = Enum.TextYAlignment.Center
collapseBtn.Parent = header
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(1, 0)

local sep1 = Instance.new("Frame")
sep1.Size = UDim2.new(0.92, 0, 0, 1)
sep1.Position = UDim2.new(0.04, 0, 0, 38)
sep1.BackgroundColor3 = Color3.fromRGB(65, 65, 75)
sep1.BorderSizePixel = 0
sep1.Parent = content

local function createToggle(label, yPos, callback, initial)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.92, 0, 0, 24)
    line.Position = UDim2.new(0.04, 0, 0, yPos)
    line.BackgroundTransparency = 1
    line.Parent = content

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(205, 205, 215)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Parent = line

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.25, 0, 1, 0)
    btn.Position = UDim2.new(0.72, 0, 0, 0)
    btn.BackgroundColor3 = initial and Color3.fromRGB(0, 140, 0) or Color3.fromRGB(60, 60, 70)
    btn.BorderSizePixel = 0
    btn.Text = initial and "ON" or "OFF"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.TextXAlignment = Enum.TextXAlignment.Center
    btn.TextYAlignment = Enum.TextYAlignment.Center
    btn.Parent = line
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

    local state = initial
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 140, 0) or Color3.fromRGB(60, 60, 70)
        btn.Text = state and "ON" or "OFF"
        callback(state)
    end)
    return btn
end

local espPlayerBtn = createToggle("Player ESP", 46, function(v) espPlayersEnabled = v refreshESP() end, espPlayersEnabled)
local espBotBtn = createToggle("Bot ESP", 72, function(v) espBotsEnabled = v refreshESP() end, espBotsEnabled)
local espModelBtn = createToggle("Model ESP", 98, function(v) espModelEnabled = v refreshESP(); if botAimEnabled then rebuildAllTargets() end end, espModelEnabled)
local aimlockBtn = createToggle("Aimlock", 124, function(v) aimbotEnabled = v end, aimbotEnabled)
local headPlayerBtn = createToggle("Head Aim (P)", 150, function(v) headAimPlayers = v; rebuildPlayerTargets(); currentTarget = nil end, headAimPlayers)
local botAimBtnToggle = createToggle("Bot Aim", 176, function(v) botAimEnabled = v; if v then rebuildAllTargets() else cachedBotTargets = {}; cachedCustomTargets = {} end; currentTarget = nil end, botAimEnabled)
local headBotBtn = createToggle("Head Aim (B)", 202, function(v) headAimBots = v; if botAimEnabled then rebuildAllTargets() end; currentTarget = nil end, headAimBots)

local predLine = Instance.new("Frame")
predLine.Size = UDim2.new(0.92, 0, 0, 22)
predLine.Position = UDim2.new(0.04, 0, 0, 230)
predLine.BackgroundTransparency = 1
predLine.Parent = content

local predLbl = Instance.new("TextLabel")
predLbl.Size = UDim2.new(0.6, 0, 1, 0)
predLbl.Position = UDim2.new(0, 0, 0, 0)
predLbl.BackgroundTransparency = 1
predLbl.Text = "Predict"
predLbl.TextColor3 = Color3.fromRGB(205, 205, 215)
predLbl.Font = Enum.Font.GothamMedium
predLbl.TextSize = 13
predLbl.TextXAlignment = Enum.TextXAlignment.Left
predLbl.TextYAlignment = Enum.TextYAlignment.Center
predLbl.Parent = predLine

local predBtn = Instance.new("TextButton")
predBtn.Size = UDim2.new(0.2, 0, 1, 0)
predBtn.Position = UDim2.new(0.75, 0, 0, 0)
predBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
predBtn.BorderSizePixel = 0
predBtn.Text = "ON"
predBtn.TextColor3 = Color3.new(1,1,1)
predBtn.Font = Enum.Font.GothamBold
predBtn.TextSize = 11
predBtn.Parent = predLine
Instance.new("UICorner", predBtn).CornerRadius = UDim.new(0, 5)
predBtn.MouseButton1Click:Connect(function()
    predictEnabled = not predictEnabled
    predBtn.BackgroundColor3 = predictEnabled and Color3.fromRGB(0, 140, 0) or Color3.fromRGB(60, 60, 70)
    predBtn.Text = predictEnabled and "ON" or "OFF"
end)

local function createSlider(label, yPos, minVal, maxVal, initial, callback)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(0.92, 0, 0, 24)
    line.Position = UDim2.new(0.04, 0, 0, yPos)
    line.BackgroundTransparency = 1
    line.Parent = content

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.3, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = Color3.fromRGB(190, 190, 200)
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Center
    lbl.Parent = line

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0.55, 0, 0.7, 0)
    slider.Position = UDim2.new(0.38, 0, 0.15, 0)
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
    slider.BorderSizePixel = 0
    slider.Parent = line
    Instance.new("UICorner", slider).CornerRadius = UDim.new(0, 4)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initial - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = currentColor
    fill.BorderSizePixel = 0
    fill.Parent = slider
    Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((initial - minVal) / (maxVal - minVal), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
    knob.BorderSizePixel = 0
    knob.Text = ""
    knob.Parent = slider
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    local function update(inputPos)
        local relX = inputPos.X - slider.AbsolutePosition.X
        local w = slider.AbsoluteSize.X
        local val = math.clamp(relX / w, 0, 1) * (maxVal - minVal) + minVal
        val = math.round(val * 100) / 100
        fill.Size = UDim2.new((val - minVal) / (maxVal - minVal), 0, 1, 0)
        knob.Position = UDim2.new((val - minVal) / (maxVal - minVal), -6, 0.5, -6)
        callback(val)
    end

    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(input.Position)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            update(input.Position)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            update(input.Position)
            dragging = true
        end
    end)
    return fill, knob
end

local _, _ = createSlider("Fill", 258, 0, 1, fillTransparency, function(v)
    fillTransparency = v
    updateAllColors()
end)

local _, _ = createSlider("Outline", 284, 0, 1, outlineTransparency, function(v)
    outlineTransparency = v
    updateAllColors()
end)

local _, _ = createSlider("Smooth", 310, 0.05, 0.95, smoothing, function(v)
    smoothing = v
end)

local distLabel = Instance.new("TextLabel")
distLabel.Size = UDim2.new(0.4, 0, 0, 18)
distLabel.Position = UDim2.new(0.04, 0, 0, 332)
distLabel.BackgroundTransparency = 1
distLabel.Text = "Dist: N/A"
distLabel.TextColor3 = Color3.fromRGB(170, 170, 180)
distLabel.Font = Enum.Font.GothamBold
distLabel.TextSize = 12
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.Parent = content

local colorSlider = Instance.new("Frame")
colorSlider.Size = UDim2.new(0.5, 0, 0, 14)
colorSlider.Position = UDim2.new(0.45, 0, 0, 334)
colorSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
colorSlider.BorderSizePixel = 0
colorSlider.Parent = content
Instance.new("UICorner", colorSlider).CornerRadius = UDim.new(0, 4)

local colorFill = Instance.new("Frame")
colorFill.Size = UDim2.new(0,0,1,0)
colorFill.BackgroundColor3 = Color3.fromHSV(0,1,1)
colorFill.BorderSizePixel = 0
colorFill.Parent = colorSlider
Instance.new("UICorner", colorFill).CornerRadius = UDim.new(0, 4)

local colorKnob = Instance.new("TextButton")
colorKnob.Size = UDim2.new(0, 12, 0, 12)
colorKnob.Position = UDim2.new(0, -6, 0.5, -6)
colorKnob.BackgroundColor3 = Color3.fromRGB(235, 235, 240)
colorKnob.BorderSizePixel = 0
colorKnob.Text = ""
colorKnob.Parent = colorSlider
Instance.new("UICorner", colorKnob).CornerRadius = UDim.new(1, 0)

local function updateColorSlider(value)
    value = math.clamp(value,0,1)
    currentColor = Color3.fromHSV(value,1,1)
    colorFill.BackgroundColor3 = currentColor
    colorFill.Size = UDim2.new(value,0,1,0)
    colorKnob.Position = UDim2.new(value, -6, 0.5, -6)
    updateAllColors()
end

local function makeColorDraggable()
    local dragging = false
    local function getValue(inputPos)
        local relX = inputPos.X - colorSlider.AbsolutePosition.X
        local w = colorSlider.AbsoluteSize.X
        return math.clamp(relX / w, 0, 1)
    end
    colorKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateColorSlider(getValue(input.Position))
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateColorSlider(getValue(input.Position))
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    colorSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            updateColorSlider(getValue(input.Position))
            dragging = true
        end
    end)
end
makeColorDraggable()

RunService.RenderStepped:Connect(function()
    if aimbotEnabled and currentTarget and currentTarget.aimPart and currentTarget.aimPart.Parent then
        local root = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local d = (root.Position - currentTarget.aimPart.Position).Magnitude
            distLabel.Text = "Dist: " .. math.floor(d) .. "m"
        else
            distLabel.Text = "Dist: N/A"
        end
    else
        distLabel.Text = "Dist: N/A"
    end
end)

-- ===== Collapse (финальный, без смещений) =====
local collapsed = false
local originalSize = UDim2.new(0, 210, 0, 355)

local collapseCircle = Instance.new("TextButton")
collapseCircle.Size = UDim2.new(0, 38, 0, 38)
collapseCircle.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
collapseCircle.BackgroundTransparency = 0
collapseCircle.BorderSizePixel = 1
collapseCircle.BorderColor3 = Color3.fromRGB(70, 70, 80)
collapseCircle.Visible = false
collapseCircle.Text = "−"
collapseCircle.TextColor3 = Color3.fromRGB(255, 255, 255)
collapseCircle.Font = Enum.Font.GothamBold
collapseCircle.TextSize = 30
collapseCircle.TextXAlignment = Enum.TextXAlignment.Center
collapseCircle.TextYAlignment = Enum.TextYAlignment.Center
collapseCircle.ZIndex = 10
collapseCircle.Parent = screenGui
Instance.new("UICorner", collapseCircle).CornerRadius = UDim.new(1, 0)

local shadowCircle = Instance.new("ImageLabel")
shadowCircle.Size = UDim2.new(1, 10, 1, 10)
shadowCircle.Position = UDim2.new(-0.05, 0, -0.05, 0)
shadowCircle.BackgroundTransparency = 1
shadowCircle.Image = "rbxassetid://1316045217"
shadowCircle.ImageColor3 = Color3.new(0,0,0)
shadowCircle.ImageTransparency = 0.5
shadowCircle.ZIndex = 9
shadowCircle.Parent = collapseCircle

local function setCircleToButtonPosition()
    local btnPos = collapseBtn.AbsolutePosition
    if btnPos.X > 0 and btnPos.Y > 0 then
        local offsetX = (38 - 30) / 2
        local offsetY = (38 - 30) / 2
        collapseCircle.Position = UDim2.new(0, btnPos.X - offsetX, 0, btnPos.Y - offsetY)
    end
end

collapseBtn.MouseButton1Click:Connect(function()
    collapsed = true
    setCircleToButtonPosition()
    collapseCircle.Visible = true
    mainFrame.Visible = false
end)

collapseCircle.MouseButton1Click:Connect(function()
    collapsed = false
    collapseCircle.Visible = false
    mainFrame.Visible = true
    mainFrame.Size = originalSize
end)

mainFrame:GetPropertyChangedSignal("Position"):Connect(function()
    if collapseCircle.Visible then
        setCircleToButtonPosition()
    end
end)

mainFrame.Visible = true
collapseCircle.Visible = false

updateColorSlider(0)
startTrackingESP()
refreshESP()
