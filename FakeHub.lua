-- ============================== FULL LOAD CHECK ==============================
repeat task.wait() until game:IsLoaded()
repeat task.wait() until game:GetService("Players").LocalPlayer
repeat task.wait() until game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Interface")
task.wait(6)

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local VirtualUser = game:GetService("VirtualUser")

local currentCamera = game.Workspace.CurrentCamera

player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.zero, currentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.zero, currentCamera.CFrame)
end)


local repo="https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library=loadstring(game:HttpGet(repo.."Library.lua"))()
local ThemeManager=loadstring(game:HttpGet(repo.."addons/ThemeManager.lua"))()
local SaveManager=loadstring(game:HttpGet(repo.."addons/SaveManager.lua"))()

-- ============================== SERVICES ==============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local VIM = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

pcall(function()
    UserInputService.MouseIconEnabled = true
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end)
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Assets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes")
local POST = Assets:WaitForChild("POST")
local GET = Assets:WaitForChild("GET")

-- ============================== STABILITY SYSTEM ==============================
local function SafeInvoke(remote, ...)
    local args = {...}
    local maxRetries = 3
    local attempt = 0
    while attempt < maxRetries do
        attempt = attempt + 1
        local success, result = pcall(function()
            return remote:InvokeServer(unpack(args))
        end)
        if success then
            return true, result
        end
        if attempt < maxRetries then
            local delay = 0.3 * (2 ^ (attempt - 1))
            task.wait(delay)
        end
    end
    return false, nil
end

local function SafeFire(remote, ...)
    local args = {...}
    local success = pcall(function()
        remote:FireServer(unpack(args))
    end)
    return success
end

getgenv().SafeInvoke = SafeInvoke
getgenv().SafeFire = SafeFire

local ErrorLog = {}
local MaxLogEntries = 50
local function LogError(category, message)
end
getgenv().PrintErrorLog = function()
end
getgenv().LogError = LogError

local LastServerResponse = tick()
task.spawn(function()
    while task.wait(15) do
        pcall(function() if Player and Player.Parent == Players then LastServerResponse = tick() end end)
    end
end)

task.spawn(function()
    pcall(function()
        Player.Idled:Connect(function()
            pcall(function()
                VIM:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VIM:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end)
    end)
end)

task.spawn(function()
    while task.wait(300) do
        pcall(function()
            local ok, memBefore = pcall(gcinfo)
            collectgarbage("collect")
            local ok2, memAfter = pcall(gcinfo)
        end)
    end
end)

local LastGlobalHeartbeat = tick()
task.spawn(function()
    local watchConn = RunService.Heartbeat:Connect(function() LastGlobalHeartbeat = tick() end)
    while task.wait(10) do
        pcall(function()
            local elapsed = tick() - LastGlobalHeartbeat
            if elapsed > 15 then
                if watchConn then pcall(function() watchConn:Disconnect() end) end
                watchConn = RunService.Heartbeat:Connect(function() LastGlobalHeartbeat = tick() end)
            end
        end)
    end
end)

-- ============================== PLACE CHECK ==============================
local PlaceId = game.PlaceId
local MAIN_MENU_ID = 13379208636
local LOBBY_ID = 14916516914
local TRADE_LOBBY_ID = 14932214603

local function IsMainmenuLobby() return PlaceId == MAIN_MENU_ID end
local function IsLobbyLobby() return PlaceId == LOBBY_ID or PlaceId == TRADE_LOBBY_ID end
local function IsIngameLobby() return not IsMainmenuLobby() and not IsLobbyLobby() end

task.spawn(function()
    local start = tick()
    repeat
        if PlayerGui:FindFirstChild("Interface") then break end
        task.wait()
    until tick() - start > 3
end)

-- ============================== WINDOW ==============================
local Window = Library:CreateWindow({Title="FakeHUB", Center=true, AutoShow=true})

-- ============================== GLOBAL UI FUNCTIONS ==============================
local function isUIHiddenGlobal()
    local ok, hidden = pcall(function()
        return Window and Window.Holder and not Window.Holder.Visible
    end)
    return ok and hidden
end

local function hideUIGlobal()
    pcall(function()
        if Window and Window.Holder and Window.Holder.Visible then
            if Library and Library.Toggle then
                Library:Toggle()
            end
        end
    end)
end

local function showUIGlobal()
    pcall(function()
        if Window and Window.Holder and not Window.Holder.Visible then
            if Library and Library.Toggle then
                Library:Toggle()
            end
        end
    end)
end

getgenv().isUIHidden = isUIHiddenGlobal
getgenv().hideUI = hideUIGlobal
getgenv().showUI = showUIGlobal

-- ============================== FOLDER SETUP ==============================
local FakeHUBFolder = "FakeHUB"
if not isfolder(FakeHUBFolder) then makefolder(FakeHUBFolder) end

local activeFolder
if IsMainmenuLobby() then activeFolder = FakeHUBFolder.."/Mainmenu"
elseif IsLobbyLobby() then activeFolder = FakeHUBFolder.."/Lobby"
elseif IsIngameLobby() then activeFolder = FakeHUBFolder.."/Ingame"
else activeFolder = FakeHUBFolder.."/Default" end
if not isfolder(activeFolder) then makefolder(activeFolder) end

pcall(function()
    if game.Workspace:FindFirstChild("LinoriaLibSettings") then game.Workspace.LinoriaLibSettings:Destroy() end
    if isfolder("LinoriaLibSettings") then delfolder("LinoriaLibSettings") end
end)


-- ============================== SAVE/THEME ==============================
local oldBuildFolderTree = SaveManager.BuildFolderTree
SaveManager.BuildFolderTree = function(...) if oldBuildFolderTree then return oldBuildFolderTree(...) end end
SaveManager:SetLibrary(Library)
SaveManager:SetFolder(activeFolder)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetLibrary(Library)
ThemeManager:SetFolder(FakeHUBFolder)
pcall(function() SaveManager:BuildFolderTree() end)

-- ============================== TABS ==============================
local Tabs = {}
if IsMainmenuLobby() then Tabs.MainMenu = Window:AddTab("Main Menu") end
if IsLobbyLobby() then
    Tabs.Lobby = Window:AddTab("Lobby")
    Tabs.Session = Window:AddTab("Equipment")
    Tabs.Trade = Window:AddTab("Trade")
end
if IsIngameLobby() then
    Tabs.AutoFarm = Window:AddTab("Auto Farm")
    Tabs.Safety = Window:AddTab("Wave")
    Tabs.Webhook = Window:AddTab("Webhook")
end





-- ============================== WEBHOOK NOTIFICATION SECTION (STABLE DETECTION + REAL-TIME LABEL) ==============================
if IsMainmenuLobby() then
    Tabs.Webhook = Window:AddTab("Webhook")

    local WebhookGroup = Tabs.Webhook:AddLeftGroupbox("Webhook")

    -- ========== REAL-TIME FAMILY LABEL (USING SAME STABLE LOGIC AS AUTO SPIN) ==========
    -- (ลบ label และ updater ออกแล้ว)

    -- Helper functions (copied from Auto Spin for consistency)
    local function getFamilyTitle()
        local ui = PlayerGui:FindFirstChild("Interface")
        if not ui then return nil end
        local custom = ui:FindFirstChild("Customisation")
        if not custom then return nil end
        local family = custom:FindFirstChild("Family")
        if not family then return nil end
        local fam = family:FindFirstChild("Family")
        if not fam then return nil end
        return fam:FindFirstChild("Title")
    end

    local function isFamilyTitleReady()
        local title = getFamilyTitle()
        if not title or not title:IsA("TextLabel") then return false end
        if not title.Visible then return false end
        if title.AbsoluteSize.X <= 1 or title.AbsoluteSize.Y <= 1 then return false end
        if title.Text == "" then return false end
        local current = title.Parent
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return true
    end

    local function getCurrentFamilyStable()
        for i = 1, 10 do
            if isFamilyTitleReady() then
                local title = getFamilyTitle()
                if title and title:IsA("TextLabel") then
                    return title.Text
                end
            end
            task.wait(0.1)
        end
        return nil
    end

    -- (ลบ Real-time label updater ออกแล้ว)

    -- ========== WEBHOOK LOGIC (ONLY ONCE PER TARGET FAMILY PER ROLL) ==========
    local webhookURL = ""
    local autoNotifyEnabled = false
    local pingMode = "None"

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Status variables
    local lastSpinCount = -1
    local hasSentForCurrentRoll = false   -- reset after each roll (spin decrease)

    -- Utility functions (same as before, but using stable detection for webhook)
    local function isFamilyTabOpen()
        local success, rollBtn = pcall(function()
            return PlayerGui.Interface.Customisation.Family.Buttons_2.Roll
        end)
        if not success or not rollBtn then return false end
        local visible = rollBtn.Visible
        if not visible then return false end
        local parent = rollBtn.Parent
        while parent and parent ~= PlayerGui do
            if parent:IsA("GuiObject") and not parent.Visible then return false end
            if parent:IsA("ScreenGui") and not parent.Enabled then return false end
            parent = parent.Parent
        end
        return true
    end

    local function GetSpinCountNumber()
        if not isFamilyTabOpen() then return -1 end
        local ok, spinStr = pcall(function()
            return PlayerGui.Interface.Customisation.Family.Buttons_2.Roll.Title.Text
        end)
        if not ok or not spinStr or spinStr == "" then return -1 end
        local num = tonumber(spinStr:match("%d+"))
        return num or -1
    end

    local function GetStoredFamilies()
        local data = {}
        local count = 0
        if not isFamilyTabOpen() then return data, count end
        local ok, familiesFolder = pcall(function()
            return PlayerGui.Interface.Customisation.Storage.Main.Families
        end)
        if not ok or not familiesFolder then return data, count end
        for _, v in ipairs(familiesFolder:GetChildren()) do
            pcall(function()
                local inner = v:FindFirstChild("Inner")
                if inner then
                    local title = inner:FindFirstChild("Title")
                    if title and title:IsA("TextLabel") and title.Text and title.Text ~= "" then
                        table.insert(data, title.Text)
                        count = count + 1
                    end
                end
            end)
        end
        return data, count
    end

    local function GetFamilyRarity(familyName)
        if not familyName then return "Common" end
        local commonList = {"Reeves","Blouse","Inocenio","Munsell","Boyega","Ral","Bozado","Pikale","Hume","Iglehaut"}
        local rareList = {"Braus","Kruger","Azumabito","Smith","Grice","Springer","Kirstein"}
        local epicList = {"Galliard","Zoe","Leonhart","Tybur","Ksaver","Braun","Finger","Arlert"}
        local legendaryList = {"Yeager","Ackerman","Reiss"}
        local mythicList = {"Fritz","Helos"}
        
        for _, name in ipairs(commonList) do
            if familyName:find(name) then return "Common" end
        end
        for _, name in ipairs(rareList) do
            if familyName:find(name) then return "Rare" end
        end
        for _, name in ipairs(epicList) do
            if familyName:find(name) then return "Epic" end
        end
        for _, name in ipairs(legendaryList) do
            if familyName:find(name) then return "Legendary" end
        end
        for _, name in ipairs(mythicList) do
            if familyName:find(name) then return "Mythic" end
        end
        return "Common"
    end

    local function GetColorByRarity(rarity)
        if rarity == "Epic" then return 0x9b59b6
        elseif rarity == "Legendary" then return 0xf1c40f
        elseif rarity == "Mythic" then return 0xe74c3c
        elseif rarity == "Rare" then return 0x3498db
        else return 0x95a5a6 end
    end

    local function SendTargetWebhook(currentFamily, spinNumber)
        if webhookURL == "" then return false end
        local familyList, familyCount = GetStoredFamilies()
        local rarity = GetFamilyRarity(currentFamily)
        local color = GetColorByRarity(rarity)
        local content = nil
        if pingMode == "Everyone" then content = "@everyone"
        elseif pingMode == "Here" then content = "@here" end

        local player = game:GetService("Players").LocalPlayer
        local userId = player.UserId
        local userName = player.Name

        local playerField = string.format("**Username:** @%s\n**User ID:** `%d`", userName, userId)
        local familyField = string.format("**Name:** %s\n**Rarity:** %s", currentFamily, rarity)
        local spinsField = string.format("**Remaining:** %s", spinNumber)

        local storedDisplay = ""
        if familyCount > 0 then
            local maxDisplay = 15
            local displayList = {}
            for i = 1, math.min(#familyList, maxDisplay) do
                table.insert(displayList, string.format("• %s", familyList[i]))
            end
            if #familyList > maxDisplay then
                table.insert(displayList, string.format("• ... and %d more", #familyList - maxDisplay))
            end
            storedDisplay = table.concat(displayList, "\n")
        else
            storedDisplay = "• No stored families"
        end

        local body = game:GetService("HttpService"):JSONEncode({
            content = content,
            embeds = {{
                title = "🎯 TARGET FAMILY FOUND: " .. currentFamily,
                color = color,
                thumbnail = { url = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=420&height=420&format=png", userId) },
                fields = {
                    { name = "━━━━━━━━━ 👤 PLAYER ━━━━━━━━━", value = playerField, inline = false },
                    { name = "━━━━━━━━━ 🏷️ FAMILY ━━━━━━━━━", value = familyField, inline = true },
                    { name = "━━━━━━━━━ 🎲 SPINS ━━━━━━━━━", value = spinsField, inline = true },
                    { name = "━━━━━━━━━ 📦 STORED (" .. familyCount .. ") ━━━━━━━━━", value = storedDisplay, inline = false }
                },
                footer = { text = "FakeHUB • " .. os.date("%Y-%m-%d %H:%M:%S") },
                timestamp = DateTime.now():ToIsoDate()
            }}
        })

        local requestFunction = (syn and syn.request) or (http and http.request) or http_request or request
        if not requestFunction then return false end
        return pcall(function()
            requestFunction({ Url = webhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body })
        end)
    end

    -- MAIN LOOP: Detect spin count decrease → Roll occurred → Then check current family (stable)
    task.spawn(function()
        while true do
            task.wait(0.3)
            if not autoNotifyEnabled or webhookURL == "" then
                lastSpinCount = -1
                hasSentForCurrentRoll = false
                task.wait(1)
                continue
            end

            if not isFamilyTabOpen() then
                task.wait(0.5)
                continue
            end

            local currentSpinNum = GetSpinCountNumber()
            if currentSpinNum == -1 then
                task.wait(0.5)
                continue
            end

            if lastSpinCount == -1 then
                lastSpinCount = currentSpinNum
                task.wait(0.2)
                continue
            end

            -- Spin decreased → a roll happened
            if currentSpinNum < lastSpinCount and lastSpinCount > 0 then
                -- Reset the sent flag for this new roll
                hasSentForCurrentRoll = false

                -- Wait for UI to update and fetch the new family (using stable method)
                local currentFamily = getCurrentFamilyStable()   -- retries up to 1 second
                
                if currentFamily and currentFamily ~= "Unknown" then
                    -- Get target families from Auto Spin dropdown
                    local targetFamilies = {}
                    if Options and Options.AutoSpinFamilies then
                        for name, enabled in pairs(Options.AutoSpinFamilies.Value or {}) do
                            if enabled and not string.match(name, "^%-%-%-") then
                                table.insert(targetFamilies, string.lower(name))
                            end
                        end
                    end
                    
                    local isTarget = false
                    if #targetFamilies > 0 then
                        local lowerFamily = string.lower(currentFamily)
                        for _, target in ipairs(targetFamilies) do
                            if string.find(lowerFamily, target) then
                                isTarget = true
                                break
                            end
                        end
                    end

                    if isTarget and not hasSentForCurrentRoll then
                        SendTargetWebhook(currentFamily, currentSpinNum)
                        hasSentForCurrentRoll = true
                        -- Console output with color
                        local rarity = GetFamilyRarity(currentFamily)
                        local colorCodes = {Common="\27[90m", Rare="\27[94m", Epic="\27[95m", Legendary="\27[93m", Mythic="\27[91m"}
                        local code = colorCodes[rarity] or "\27[97m"
                        print(code .. "✅ FOUND TARGET FAMILY: " .. currentFamily .. " (" .. rarity .. ")\27[0m")
                    end
                else
                    print("[Webhook] Could not retrieve family name after roll")
                end
            end

            lastSpinCount = currentSpinNum
        end
    end)

    -- ========== UI COMPONENTS ==========
    WebhookGroup:AddInput("Webhook_URL", {
        Default = "", Numeric = false, Finished = true,
        Text = "Discord Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(v) webhookURL = v end
    })

    WebhookGroup:AddDropdown("Webhook_PingMode", {
        Text = "Ping Mode",
        Values = {"None", "Everyone", "Here"},
        Default = "None",
        Multi = false,
        Callback = function(v) pingMode = v end
    })

    WebhookGroup:AddButton("Test Send", function()
        SendTargetWebhook("Test Family (Fake)", "?")
    end)

    WebhookGroup:AddToggle("AutoNotifyToggle", {
        Text = "Auto Send Families to Discord",
        Default = false,
        Callback = function(v)
            autoNotifyEnabled = v
            if v then
                lastSpinCount = -1
                hasSentForCurrentRoll = false
                print("[Webhook] Monitoring started.")
            else
                print("[Webhook] Monitoring stopped.")
            end
        end
    })
end
-- ============================== END WEBHOOK SECTION ==============================

-- ============================== POPUP REAL-TIME FAMILY DISPLAY (SMOOTH XENON NEON) ==============================
if IsMainmenuLobby() then
    while not Tabs.Webhook do task.wait(0.1) end

    local PopupGroup = Tabs.Webhook:AddLeftGroupbox("Show Familiy")
    local popupEnabled = false
    local popupGui = nil
    local updateConnection = nil
    local glowConnection = nil
    local isInCustomisationPage = false
    local currentScale = 1.0  -- ขนาดเริ่มต้น 100%

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local RunService = game:GetService("RunService")

    -- ฟังก์ชันตรวจสอบว่า GUI Visible จริง
    local function IsActuallyVisible(gui)
        if not gui or not gui:IsA("GuiObject") then return false end
        if not gui.Visible then return false end
        local current = gui.Parent
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return true
    end

    -- ฟังก์ชันตรวจสอบว่าอยู่ในหน้า Customisation (Family Tab) หรือไม่
    local function IsInCustomisationPage()
        local interface = PlayerGui:FindFirstChild("Interface")
        if not interface then return false end
        
        local custom = interface:FindFirstChild("Customisation")
        if not custom or not IsActuallyVisible(custom) then return false end
        
        local family = custom:FindFirstChild("Family")
        if not family or not IsActuallyVisible(family) then return false end
        
        local fam = family:FindFirstChild("Family")
        if not fam then return false end
        local title = fam:FindFirstChild("Title")
        if not title or not IsActuallyVisible(title) then return false end
        
        return true
    end

    -- ดึงชื่อ Family ปัจจุบัน
    local function GetCurrentFamilyPopup()
        local ok, result = pcall(function()
            return PlayerGui.Interface.Customisation.Family.Family.Title.Text
        end)
        return ok and result or "Unknown"
    end

    -- ดึงจำนวน Spins จาก Roll Button
    local function GetTotalSpins()
        local ok, result = pcall(function()
            return PlayerGui.Interface.Customisation.Family.Buttons_2.Roll.Title.Text
        end)
        if ok and result then
            local num = tonumber(result:match("%d+"))
            return num or 0
        end
        return 0
    end

    -- ฟังก์ชันหา Rarity
    local function GetFamilyRarityPopup(familyName)
        if not familyName or familyName == "Unknown" then return "Common" end
        local clean = familyName:match("^([^%(]+)") or familyName
        clean = clean:gsub("%s+$", "")
        local lower = string.lower(clean)
        
        local rarityMap = {
            Common = {"reeves","blouse","inocenio","munsell","boyega","ral","bozado","pikale","hume","iglehaut"},
            Rare = {"braus","kruger","azumabito","smith","grice","springer","kirstein"},
            Epic = {"galliard","zoe","leonhart","tybur","ksaver","braun","finger","arlert"},
            Legendary = {"yeager","ackerman","reiss"},
            Mythic = {"fritz","helos"}
        }
        for rarity, list in pairs(rarityMap) do
            for _, name in ipairs(list) do
                if lower == name then return rarity end
            end
        end
        return "Common"
    end

    -- สีหลักตาม Rarity
    local function GetBaseColor(rarity)
        if rarity == "Common" then
            return Color3.fromHex("#C0C0C0")
        elseif rarity == "Rare" then
            return Color3.fromHex("#00E5FF")
        elseif rarity == "Epic" then
            return Color3.fromHex("#CC33FF")
        elseif rarity == "Legendary" then
            return Color3.fromHex("#FFD700")
        elseif rarity == "Mythic" then
            return Color3.fromHex("#FF3366")
        else
            return Color3.fromHex("#FFFFFF")
        end
    end

    -- สีสว่าง (สำหรับเรืองแสง)
    local function getBrightColor(baseColor)
        return Color3.new(
            math.min(baseColor.R + 0.35, 1),
            math.min(baseColor.G + 0.35, 1),
            math.min(baseColor.B + 0.35, 1)
        )
    end

    -- อัปเดตขนาด UI
    local function UpdateUIScale()
        if popupGui then
            local scaleObj = popupGui:FindFirstChild("UIScale")
            if scaleObj then
                scaleObj.Scale = currentScale
            end
        end
    end

    -- เอฟเฟกต์ Smooth Pulse
    local function StartSmoothPulse(innerBorder, outerGlow, baseColor)
        if glowConnection then glowConnection:Disconnect() end
        
        local brightColor = getBrightColor(baseColor)
        local time = 0
        local pulseSpeed = 1.2
        
        glowConnection = RunService.RenderStepped:Connect(function(deltaTime)
            if not popupEnabled or not popupGui then return end
            
            time = time + deltaTime * pulseSpeed
            local intensity = (math.sin(time) + 1) / 2
            
            local currentColor = Color3.new(
                baseColor.R + (brightColor.R - baseColor.R) * intensity,
                baseColor.G + (brightColor.G - baseColor.G) * intensity,
                baseColor.B + (brightColor.B - baseColor.B) * intensity
            )
            
            local thickness = 2 + intensity * 1.5
            local glowThickness = 5 + intensity * 3
            local glowTransparency = 0.55 - intensity * 0.25
            
            innerBorder.Color = currentColor
            outerGlow.Color = currentColor
            outerGlow.Thickness = glowThickness
            outerGlow.Transparency = glowTransparency
            innerBorder.Thickness = thickness
        end)
    end

    local function CreatePopupUI()
        if popupGui then popupGui:Destroy() end
        if glowConnection then glowConnection:Disconnect() end

        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "FakeHUBRealTimePopup"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        screenGui.DisplayOrder = 999
        screenGui.IgnoreGuiInset = true
        screenGui.Parent = LocalPlayer.PlayerGui
        popupGui = screenGui

        -- UIScale สำหรับปรับขนาด
        local uiScale = Instance.new("UIScale")
        uiScale.Scale = currentScale
        uiScale.Parent = screenGui

        local mainFrame = Instance.new("Frame")
        mainFrame.Size = UDim2.new(0, 300, 0, 100)
        mainFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
        mainFrame.BackgroundColor3 = Color3.fromHex("#050505")
        mainFrame.BackgroundTransparency = 0.08
        mainFrame.BorderSizePixel = 0
        mainFrame.ClipsDescendants = true
        mainFrame.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 14)
        corner.Parent = mainFrame

        local innerBorder = Instance.new("UIStroke")
        innerBorder.Thickness = 2.5
        innerBorder.Transparency = 0.1
        innerBorder.LineJoinMode = Enum.LineJoinMode.Round
        innerBorder.Parent = mainFrame

        local outerGlow = Instance.new("UIStroke")
        outerGlow.Thickness = 5
        outerGlow.Transparency = 0.55
        outerGlow.LineJoinMode = Enum.LineJoinMode.Round
        outerGlow.Parent = mainFrame

        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 26, 0, 26)
        closeBtn.Position = UDim2.new(1, -34, 0, 6)
        closeBtn.BackgroundTransparency = 0.3
        closeBtn.Text = "X"
        closeBtn.TextColor3 = Color3.new(1,1,1)
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.TextSize = 14
        closeBtn.Parent = mainFrame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 13)
        btnCorner.Parent = closeBtn
        
        closeBtn.MouseEnter:Connect(function()
            closeBtn.BackgroundTransparency = 0.1
        end)
        closeBtn.MouseLeave:Connect(function()
            closeBtn.BackgroundTransparency = 0.3
        end)
        closeBtn.MouseButton1Click:Connect(function()
            if popupGui then popupGui:Destroy() end
            if glowConnection then glowConnection:Disconnect() end
            if Options and Options.PopupRealTimeToggle then
                Options.PopupRealTimeToggle:SetValue(false)
            end
        end)

        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -40, 0, 24)
        titleLabel.Position = UDim2.new(0, 12, 0, 6)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = "CURRENT FAMILY"
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextSize = 12
        titleLabel.TextColor3 = Color3.new(1,1,1)
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = mainFrame

        local familyLabel = Instance.new("TextLabel")
        familyLabel.Size = UDim2.new(1, -50, 0, 42)
        familyLabel.Position = UDim2.new(0, 12, 0, 32)
        familyLabel.BackgroundTransparency = 1
        familyLabel.Text = "Loading..."
        familyLabel.Font = Enum.Font.GothamBlack
        familyLabel.TextSize = 24
        familyLabel.TextColor3 = Color3.new(1,1,1)
        familyLabel.TextXAlignment = Enum.TextXAlignment.Left
        familyLabel.TextScaled = true
        familyLabel.TextWrapped = true
        familyLabel.Parent = mainFrame

        -- เพิ่ม Label แสดง Total Spins
        local spinLabel = Instance.new("TextLabel")
        spinLabel.Size = UDim2.new(1, -40, 0, 20)
        spinLabel.Position = UDim2.new(0, 12, 1, -42)   -- เหนือ footerLabel เล็กน้อย
        spinLabel.BackgroundTransparency = 1
        spinLabel.Text = "Total Spins: 0"
        spinLabel.Font = Enum.Font.GothamMedium
        spinLabel.TextSize = 12
        spinLabel.TextColor3 = Color3.fromHex("#AAAAAA")
        spinLabel.TextXAlignment = Enum.TextXAlignment.Left
        spinLabel.Parent = mainFrame

        local footerLabel = Instance.new("TextLabel")
        footerLabel.Size = UDim2.new(1, -40, 0, 16)
        footerLabel.Position = UDim2.new(0, 12, 1, -20)
        footerLabel.BackgroundTransparency = 1
        footerLabel.Text = "FAKEHUB"
        footerLabel.Font = Enum.Font.GothamMedium
        footerLabel.TextSize = 9
        footerLabel.TextColor3 = Color3.fromHex("#888888")
        footerLabel.TextXAlignment = Enum.TextXAlignment.Left
        footerLabel.Parent = mainFrame

        local currentRarity = nil
        local currentBaseColor = nil
        
        local function UpdateDisplay()
            if not popupGui or not popupEnabled then return end
            
            if not IsInCustomisationPage() then
                if familyLabel.Text ~= "Not in Family page" then
                    familyLabel.Text = "Not in Family page"
                    familyLabel.TextColor3 = Color3.fromHex("#888888")
                    titleLabel.TextColor3 = Color3.fromHex("#888888")
                    closeBtn.BackgroundColor3 = Color3.fromHex("#888888")
                    spinLabel.Text = "Total Spins: -"
                end
                return
            end
            
            local family = GetCurrentFamilyPopup()
            local rarity = GetFamilyRarityPopup(family)
            local baseColor = GetBaseColor(rarity)
            local spins = GetTotalSpins()

            familyLabel.Text = family
            familyLabel.TextColor3 = baseColor
            titleLabel.TextColor3 = baseColor
            closeBtn.BackgroundColor3 = baseColor
            closeBtn.TextColor3 = (rarity == "Legendary" or rarity == "Mythic") and Color3.fromHex("#111111") or Color3.new(1,1,1)
            spinLabel.Text = "Total Spins: " .. tostring(spins)
            
            if currentRarity ~= rarity then
                currentRarity = rarity
                currentBaseColor = baseColor
                StartSmoothPulse(innerBorder, outerGlow, baseColor)
            end
        end

        if updateConnection then updateConnection:Disconnect() end
        updateConnection = RunService.Heartbeat:Connect(function()
            if popupEnabled and popupGui then
                UpdateDisplay()
            end
        end)

        UpdateDisplay()
    end

    -- Slider สำหรับปรับขนาด UI (ปรับได้ 10% - 200%)
    PopupGroup:AddSlider("PopupUIScale", {
        Text = "UI Scale (%)",
        Default = 100,
        Min = 10,
        Max = 200,
        Rounding = 0,
        Suffix = "%",
        Callback = function(v)
            currentScale = v / 100
            UpdateUIScale()
        end
    })

    PopupGroup:AddToggle("PopupRealTimeToggle", {
        Text = "Show Family Popup",
        Default = false,
        Callback = function(v)
            popupEnabled = v
            if v then
                CreatePopupUI()
                -- ลบ Notify ออก
            else
                if updateConnection then updateConnection:Disconnect() end
                if glowConnection then glowConnection:Disconnect() end
                if popupGui then popupGui:Destroy() end
                -- ลบ Notify ออก
            end
        end
    })
end
-- ============================== AUTO SPIN (MAIN MENU) - FIXED SEQUENTIAL CLICK ==============================
if IsMainmenuLobby() then
    local SpinGroup = Tabs.MainMenu:AddLeftGroupbox("Auto Spin")

    local selectedFamilies = {}
    local isSpinning = false
    local stopSpin = false
    local rollDelay = 0.01
    local autoActive = false

    local player = game:GetService("Players").LocalPlayer
    local VIM = game:GetService("VirtualInputManager")
    local GS = game:GetService("GuiService")
    local playerGui = player:WaitForChild("PlayerGui")

    -- ตัวแปรสำหรับป้องกันการแจ้งเตือนซ้ำตอนรอ 10 วินาที
    local notifiedWaitingForSettings = false

    -- ตัวแปรสำหรับจัดการ Join Community Dialog
    local dialogCooldownUntil = 0
    local waitingForDialog = false

    -- ฟังก์ชันตรวจสอบว่า Join Community Dialog ปรากฏอยู่หรือไม่
    local function IsJoinCommunityDialogVisible()
        local success, dialog = pcall(function()
            return game:GetService("CoreGui").RobloxGui.FocusNavigationCoreScriptsWrapper.Dialog
        end)
        if not success or not dialog then return false end
        return dialog.Visible == true
    end

    local function safeSetToggleOff(toggleName)
        pcall(function()
            if Options and Options[toggleName] and Options[toggleName].SetValue then
                Options[toggleName]:SetValue(false)
            end
        end)
    end

    -- ========== ฟังก์ชันหา Rarity สำหรับแสดงผล ==========
    local function GetFamilyRarity(familyName)
        if not familyName then return "Common" end
        local cleanName = familyName:match("^([^%(]+)") or familyName
        cleanName = cleanName:gsub("%s+$", "")
        local commonList = {"Reeves","Blouse","Inocenio","Munsell","Boyega","Ral","Bozado","Pikale","Hume","Iglehaut"}
        local rareList = {"Braus","Kruger","Azumabito","Smith","Grice","Springer","Kirstein"}
        local epicList = {"Galliard","Zoe","Leonhart","Tybur","Ksaver","Braun","Finger","Arlert"}
        local legendaryList = {"Yeager","Ackerman","Reiss"}
        local mythicList = {"Fritz","Helos"}
        
        for _, name in ipairs(commonList) do
            if cleanName:find(name) then return "Common" end
        end
        for _, name in ipairs(rareList) do
            if cleanName:find(name) then return "Rare" end
        end
        for _, name in ipairs(epicList) do
            if cleanName:find(name) then return "Epic" end
        end
        for _, name in ipairs(legendaryList) do
            if cleanName:find(name) then return "Legendary" end
        end
        for _, name in ipairs(mythicList) do
            if cleanName:find(name) then return "Mythic" end
        end
        return "Common"
    end

    -- ฟังก์ชันจัดรูปแบบ Family ให้สวยงาม (ชื่อหลัก + วงเล็บ rarity) ไม่ให้ซ้อนวงเล็บ
    local function FormatFamilyDisplay(rawFamily)
        if not rawFamily or rawFamily == "" then return "Unknown" end
        local baseName = rawFamily:match("^([^%(]+)") or rawFamily
        baseName = baseName:gsub("%s+$", "")
        baseName = baseName:gsub("[()]", "")
        local rarity = GetFamilyRarity(rawFamily)
        return string.format("%s (%s)", baseName, rarity)
    end

    -- ========== UI ELEMENT GETTERS ==========
    local function getInterface() return playerGui:FindFirstChild("Interface") end

    local function getCustomBtn()
        local ts = getInterface() and getInterface():FindFirstChild("Title_Screen")
        if not ts then return nil end
        local btns = ts:FindFirstChild("Buttons")
        if not btns then return nil end
        return btns:FindFirstChild("Customisation")
    end

    local function getFamilyBtn()
        local ui = getInterface()
        if not ui then return nil end
        local custom = ui:FindFirstChild("Customisation")
        if not custom then return nil end
        local cats = custom:FindFirstChild("Categories")
        if not cats then return nil end
        return cats:FindFirstChild("Family")
    end

    local function getRollBtn()
        local ui = getInterface()
        if not ui then return nil end
        local custom = ui:FindFirstChild("Customisation")
        if not custom then return nil end
        local family = custom:FindFirstChild("Family")
        if not family then return nil end
        local btns2 = family:FindFirstChild("Buttons_2")
        if not btns2 then return nil end
        return btns2:FindFirstChild("Roll")
    end

    local function getStorageBtn()
        local ui = getInterface()
        if not ui then return nil end
        local custom = ui:FindFirstChild("Customisation")
        if not custom then return nil end
        local family = custom:FindFirstChild("Family")
        if not family then return nil end
        local btns2 = family:FindFirstChild("Buttons_2")
        if not btns2 then return nil end
        return btns2:FindFirstChild("Storage")
    end

    local function getStorageUI()
        local ui = getInterface()
        if not ui then return nil end
        local custom = ui:FindFirstChild("Customisation")
        if not custom then return nil end
        return custom:FindFirstChild("Storage")
    end

    local function getFamilyTitle()
        local ui = getInterface()
        if not ui then return nil end
        local custom = ui:FindFirstChild("Customisation")
        if not custom then return nil end
        local family = custom:FindFirstChild("Family")
        if not family then return nil end
        local fam = family:FindFirstChild("Family")
        if not fam then return nil end
        return fam:FindFirstChild("Title")
    end

    -- ========== UI HELPERS ==========
    local function isGuiVisible(obj)
        if not obj then return false end
        if not obj:IsA("GuiObject") then return false end
        if not obj.Visible then return false end
        if obj.AbsoluteSize.X <= 1 or obj.AbsoluteSize.Y <= 1 then return false end
        local parent = obj.Parent
        while parent do
            if parent:IsA("ScreenGui") and not parent.Enabled then return false end
            if parent:IsA("GuiObject") and not parent.Visible then return false end
            parent = parent.Parent
        end
        return true
    end

    local function getClickable(obj)
        if not obj then return nil end
        local interact = obj:FindFirstChild("Interact")
        if interact and interact:IsA("GuiObject") then return interact end
        return obj
    end

    -- ฟังก์ชันคลิกแบบใช้ SelectedObject + Enter (ไม่มี highlight ค้าง)
    local function ClickButton(button)
        if not autoActive then return false end
        local target = getClickable(button)
        if not target or not target.Parent or not isGuiVisible(target) then return false end

        if GS.MenuIsOpen then
            VIM:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
            task.wait(0.1)
        end
        if not target.Parent then return false end

        pcall(function()
            target.Selectable = true
            target.SelectionImageObject = nil
        end)

        GS.SelectedObject = target
        task.wait(0.05)
        if GS.SelectedObject ~= target or not target.Parent then
            GS.SelectedObject = nil
            return false
        end

        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.01)
        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.01)
        GS.SelectedObject = nil
        return true
    end

    -- ========== ลำดับการเปิด UI ตามที่กำหนด ==========
    -- 1. กด Customisation
    local function OpenCustomisation()
        local btn = getCustomBtn()
        if btn and isGuiVisible(btn) then
            return ClickButton(btn)
        end
        return false
    end

    -- 2. กด Family (ทำ 2 ครั้ง ห่างกัน 0.25 วินาที)
    local function OpenFamilyTab()
        local btn = getFamilyBtn()
        if not btn or not isGuiVisible(btn) then return false end
        if not ClickButton(btn) then return false end
        task.wait(0.25)
        btn = getFamilyBtn()
        if btn and isGuiVisible(btn) then
            return ClickButton(btn)
        end
        return false
    end

    -- 3. กด Storage (ถ้ามี)
    local function OpenStorageTab()
        local btn = getStorageBtn()
        if btn and isGuiVisible(btn) then
            return ClickButton(btn)
        end
        return false
    end

    -- ฟังก์ชันเตรียม UI ให้พร้อมก่อน Roll (ทำตามลำดับ)
    local function PrepareUI()
        if not autoActive then return false end

        if isGuiVisible(getRollBtn()) then
            return true
        end

        OpenCustomisation()
        task.wait(0.5)
        
        -- แจ้งเตือนขณะรอ 10 วินาที (เฉพาะครั้งแรกในรอบการทำงาน)
        if not notifiedWaitingForSettings then
            Library:Notify("Waiting For Settings", 3)
            notifiedWaitingForSettings = true
        end
        task.wait(10)    -- รอ 10 วินาทีตามที่ผู้ใช้กำหนด

        OpenFamilyTab()
        task.wait(0.25)

        OpenStorageTab()
        task.wait(0.2)

        return isGuiVisible(getRollBtn())
    end

    -- ========== ฟังก์ชันตรวจสอบและดึง Family อย่างมั่นใจ ==========
    local function isFamilyTitleReady()
        local title = getFamilyTitle()
        if not title or not title:IsA("TextLabel") then return false end
        if not title.Visible then return false end
        if title.AbsoluteSize.X <= 1 or title.AbsoluteSize.Y <= 1 then return false end
        if title.Text == "" then return false end
        local current = title.Parent
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return true
    end

    local function waitForStableFamilyTitle()
        for i = 1, 10 do
            if isFamilyTitleReady() then
                return true
            end
            task.wait(0.1)
        end
        return false
    end

    local function getCurrentFamilyStable()
        if not waitForStableFamilyTitle() then
            return nil
        end
        local title = getFamilyTitle()
        if title and title:IsA("TextLabel") then
            return title.Text
        end
        return nil
    end

    -- ========== ฟังก์ชันอื่นๆ ที่จำเป็น ==========
    local FAMILY_LIST = {
        "--- Common ---","Reeves","Blouse","Inocenio","Munsell","Boyega","Ral","Bozado","Pikale","Hume","Iglehaut",
        "--- Rare ---","Braus","Kruger","Azumabito","Smith","Grice","Springer","Kirstein",
        "--- Epic ---","Galliard","Zoe","Leonhart","Tybur","Ksaver","Braun","Finger","Arlert",
        "--- Legendary ---","Yeager","Ackerman","Reiss",
        "--- Mythic ---","Fritz","Helos",
    }

    local function isHeader(name) return string.sub(name, 1, 3) == "---" end

    -- ตรวจสอบสล็อต
    local function IsOnScreen(gui)
        if not gui or not gui:IsA("GuiObject") then return false end
        local current = gui
        while current and current ~= game do
            if current:IsA("GuiObject") and not current.Visible then return false end
            current = current.Parent
        end
        if gui.AbsoluteSize.X <= 0 or gui.AbsoluteSize.Y <= 0 then return false end
        if not gui:IsDescendantOf(playerGui) then return false end
        return true
    end

    local function getSlotObjects()
        local slots = {}
        local ui = getInterface()
        if not ui then return slots end
        local ts = ui:FindFirstChild("Title_Screen")
        if not ts then return slots end
        local slotsFrame = ts:FindFirstChild("Slots")
        if not slotsFrame then return slots end
        for _, slotName in ipairs({"A", "B", "C"}) do
            local slot = slotsFrame:FindFirstChild(slotName)
            if slot then
                local selectBtn = slot:FindFirstChild("Select_" .. slotName)
                if selectBtn then table.insert(slots, selectBtn) end
            end
        end
        return slots
    end

    local function isAnySlotOpen()
        for _, v in ipairs(getSlotObjects()) do
            if IsOnScreen(v) then return true end
        end
        return false
    end

    -- จัดการ Warning popup
    local function handleWarningPopup()
        if not autoActive then return end
        pcall(function()
            local warningMain = playerGui:FindFirstChild("Interface")
            if warningMain then
                warningMain = warningMain:FindFirstChild("Warning")
                if warningMain then
                    warningMain = warningMain:FindFirstChild("Prompt")
                    if warningMain then
                        warningMain = warningMain:FindFirstChild("Main")
                        if warningMain and warningMain.Visible then
                            local familyTitle = getFamilyTitle()
                            local currentFamily = familyTitle and familyTitle.Text or ""
                            local isTarget = false
                            if currentFamily ~= "" and #selectedFamilies > 0 then
                                local lower = string.lower(currentFamily)
                                for _, t in ipairs(selectedFamilies) do
                                    if string.find(lower, string.lower(t)) then
                                        isTarget = true
                                        break
                                    end
                                end
                            end
                            if not isTarget then
                                local yesBtn = warningMain:FindFirstChild("Yes")
                                if yesBtn and isGuiVisible(yesBtn) then
                                    local confirmed = true
                                    for i = 1, 10 do
                                        if not isGuiVisible(yesBtn) then confirmed = false; break end
                                        local recheckTitle = getFamilyTitle()
                                        local recheckFamily = recheckTitle and recheckTitle.Text or ""
                                        if recheckFamily ~= "" and #selectedFamilies > 0 then
                                            local lower2 = string.lower(recheckFamily)
                                            local found = false
                                            for _, t in ipairs(selectedFamilies) do
                                                if string.find(lower2, string.lower(t)) then
                                                    found = true
                                                    break
                                                end
                                            end
                                            if found then confirmed = false; break end
                                        end
                                        task.wait(1)
                                    end
                                    if confirmed then
                                        ClickButton(yesBtn)
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end

    local function getSpinCount()
        local rollBtn = getRollBtn()
        if not rollBtn or not isGuiVisible(rollBtn) then return -1 end
        if rollBtn.Text and rollBtn.Text ~= "" then
            local num = tonumber(rollBtn.Text:match("%d+"))
            if num then return num end
        end
        for _, v in ipairs(rollBtn:GetChildren()) do
            if v:IsA("TextLabel") then
                local num = tonumber(v.Text:match("%d+"))
                if num then return num end
            end
        end
        return -1
    end

    local function isTargetFamily(name)
        if not name or #selectedFamilies == 0 then return false end
        local baseName = name:match("^([^%(]+)") or name
        baseName = baseName:gsub("%s+$", "")
        local lower = string.lower(baseName)
        for _, t in ipairs(selectedFamilies) do
            if string.find(lower, string.lower(t)) then return true end
        end
        return false
    end

    local function updateSpinTime()
        if _G.UpdateLastSpinTime then _G.UpdateLastSpinTime() end
    end

    -- ========== MAIN AUTO SPIN LOOP (พร้อมเช็ค Join Community Dialog) ==========
    local function autoSpinLoop()
        if isSpinning then return end
        isSpinning = true
        stopSpin = false

        if #selectedFamilies == 0 then
            isSpinning = false
            safeSetToggleOff("AutoSpinToggle")
            autoActive = false
            return
        end

        while not stopSpin and autoActive do
            -- ตรวจสอบ Join Community Dialog และ cooldown
            if IsJoinCommunityDialogVisible() then
                waitingForDialog = true
                dialogCooldownUntil = 0
                task.wait(0.5)
                continue
            elseif waitingForDialog then
                -- dialog เพิ่งหายไป เริ่ม cooldown 3 วินาที
                waitingForDialog = false
                dialogCooldownUntil = tick() + 3
                Library:Notify("Join Community dialog closed, waiting 3 seconds before resuming Auto Spin...", 2)
            end

            if dialogCooldownUntil > 0 and tick() < dialogCooldownUntil then
                task.wait(0.2)
                continue
            else
                dialogCooldownUntil = 0
            end

            task.wait(0.05)
            pcall(function()
                handleWarningPopup()
                if isAnySlotOpen() then
                    task.wait(0.5)
                    return
                end

                if not PrepareUI() then
                    task.wait(0.5)
                    return
                end

                local currentRaw = getCurrentFamilyStable()
                if currentRaw then
                    local display = FormatFamilyDisplay(currentRaw)
                    local totalSpins = getSpinCount()
                    Library:Notify(string.format("Current family: %s | Total Spins: %d", display, totalSpins), 2)
                    
                    if isTargetFamily(currentRaw) then
                        Library:Notify(string.format("Stopping spin : %s | Total Spins: %d", display, totalSpins), 10)
                        stopSpin = true
                        return
                    end
                else
                    task.wait(0.5)
                    return
                end

                local spins = getSpinCount()
                if spins == 0 then
                    Library:Notify("No spins left! Stopping.", 3)
                    stopSpin = true
                    return
                end

                local rb = getRollBtn()
                if not rb or not isGuiVisible(rb) then return end

                if not ClickButton(rb) then
                    task.wait(0.01)
                    return
                end

                updateSpinTime()
                task.wait(rollDelay)

                task.wait(0.2)
                local newRaw = getCurrentFamilyStable()
                if newRaw then
                    local newDisplay = FormatFamilyDisplay(newRaw)
                    local remainingSpins = getSpinCount()
                    Library:Notify(string.format("Rolled: %s | Spins left: %d", newDisplay, remainingSpins), 3)
                    
                    if isTargetFamily(newRaw) then
                        Library:Notify(string.format("Target achieved! %s | Total Spins: %d", newDisplay, remainingSpins), 10)
                        stopSpin = true
                        return
                    end
                end

                task.wait(0.001)
            end)
        end

        isSpinning = false
        if autoActive then
            safeSetToggleOff("AutoSpinToggle")
            autoActive = false
        end
    end

    -- ========== UI COMPONENTS ==========
    SpinGroup:AddDropdown("AutoSpinFamilies", {
        Text = "Select Families",
        Values = FAMILY_LIST,
        Multi = true,
        Default = {},
        Callback = function(v)
            selectedFamilies = {}
            for k, val in pairs(v) do
                if val and not isHeader(k) then
                    table.insert(selectedFamilies, k)
                end
            end
        end
    })

    SpinGroup:AddDivider()

    SpinGroup:AddSlider("AutoSpinDelaySlider", {
        Text = "Roll Delay",
        Default = 0.01,
        Min = 0.001,
        Max = 1,
        Rounding = 3,
        Suffix = "s",
        Callback = function(v) rollDelay = v end
    })

    SpinGroup:AddToggle("AutoSpinToggle", {
        Text = "Auto Spin",
        Default = false,
        Callback = function(v)
            if v then
                if #selectedFamilies == 0 then
                    pcall(function()
                        if Options and Options.AutoSpinToggle then
                            Options.AutoSpinToggle:SetValue(false)
                        end
                    end)
                    return
                end
                -- รีเซ็ต flag การแจ้งเตือนเมื่อเริ่ม Auto Spin ใหม่
                notifiedWaitingForSettings = false
                autoActive = true
                stopSpin = false
                task.spawn(autoSpinLoop)
            else
                autoActive = false
                stopSpin = true
                pcall(function() GS.SelectedObject = nil end)
            end
        end
    })
end
-- ============================== TRADE SYSTEM (UPDATED) ==============================
if IsLobbyLobby() then
    task.defer(function()
        local Players = game:GetService("Players")
        local Player = Players.LocalPlayer
        local POST = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("POST")
        
        local file1, file2 = "FakeHUB/saved_players.txt", "FakeHUB/saved_players_2.txt"

        -- ไฟล์ utilities
        local function loadList(f) 
            local t={} 
            if isfile(f) then 
                for n in string.gmatch(readfile(f),"[^\r\n]+") do 
                    n=n:gsub("^%s+",""):gsub("%s+$","") 
                    if n~="" then table.insert(t,n) end 
                end 
            end 
            return t 
        end
        local function saveList(f,t) writefile(f,table.concat(t,"\n")) end
        local function addName(f,n) 
            n=n:gsub("^%s+",""):gsub("%s+$","") 
            if n=="" then return false end 
            local t=loadList(f) 
            for _,v in ipairs(t) do if v:lower()==n:lower() then return false end end 
            table.insert(t,n) 
            saveList(f,t) 
            return true 
        end
        local function addMulti(f,s) 
            local a=0 
            for n in string.gmatch(s,"[^,;\r\n%s]+") do if addName(f,n) then a=a+1 end end 
            return a,0 
        end
        local function removeName(f,n) 
            local t=loadList(f) 
            local r={} 
            for _,v in ipairs(t) do if v~=n then table.insert(r,v) end end 
            saveList(f,r) 
        end
        local function toList(v) 
            local r={} 
            if type(v)=="table" then for k,e in pairs(v) do if e then table.insert(r,k) end end end 
            return r 
        end
        local function inGame(n) 
            if n:lower()==Player.Name:lower() then return false end 
            for _,p in ipairs(Players:GetPlayers()) do if p~=Player and p.Name:lower()==n:lower() then return true end end 
            return false 
        end
        local function filterOnline(l) 
            local o={} 
            for _,n in ipairs(l) do if n~="No Players" and n:lower()~=Player.Name:lower() and inGame(n) then table.insert(o,n) end end 
            return o 
        end
        local function selectAllFromFile(file) 
            local all=loadList(file) 
            local new={} 
            for _,n in ipairs(all) do new[n]=true end 
            return new 
        end
        
        -- Trade logic
        local function isTradeOpen() 
            local success, result = pcall(function() 
                return Player.PlayerGui.Interface.Trading.Prompt.Visible 
            end)
            return success and result or false
        end
        
        local sendCooldown, acceptCooldown = {}, {}
        local lastSend, lastAccept = 0, 0
        
        local trackedPlayers = {}
        
        local function clearCooldownForPlayer(name) 
            sendCooldown[name]=nil
            acceptCooldown[name]=nil 
        end
        
        task.spawn(function()
            while true do
                task.wait(2)
                pcall(function()
                    local currentPlayers = {}
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= Player then
                            currentPlayers[p.Name] = true
                            if not trackedPlayers[p.Name] then
                                trackedPlayers[p.Name] = true
                                clearCooldownForPlayer(p.Name)
                            end
                        end
                    end
                    for name in pairs(trackedPlayers) do
                        if not currentPlayers[name] then
                            trackedPlayers[name] = nil
                        end
                    end
                end)
            end
        end)
        
        -- Send Trade (ใช้รูปแบบ args ที่ถูกต้อง)
        local function sendTrade(n)
            if n:lower()==Player.Name:lower() or not inGame(n) then return end
            local now=tick()
            if sendCooldown[n] and now-sendCooldown[n]<1.5 then return end
            if now-lastSend<0.35 then return end
            lastSend, sendCooldown[n] = now, now
            
            local args = {"Invites", "Invite", n}
            pcall(function()
                POST:FireServer(unpack(args))
            end)
        end
        
        -- Accept Trade (ใช้รูปแบบ args ที่ถูกต้อง)
        local function acceptTrade(n)
            if n:lower()==Player.Name:lower() or not inGame(n) then return end
            local now=tick()
            if acceptCooldown[n] and now-acceptCooldown[n]<1 then return end
            if now-lastAccept<0.25 then return end
            lastAccept, acceptCooldown[n] = now, now
            
            local args = {"Invites", "State", n, "Accept"}
            pcall(function()
                POST:FireServer(unpack(args))
            end)
        end
        
        local function buildSendLoop(getCache)
            return function(toggleRef)
                task.spawn(function()
                    while toggleRef.Enabled do
                        if isTradeOpen() then task.wait(0.3); continue end
                        local targets = filterOnline(toList(getCache()))
                        for _, n in ipairs(targets) do
                            if not toggleRef.Enabled then break end
                            if isTradeOpen() then break end
                            sendTrade(n)
                            task.wait(0.12)
                        end
                        task.wait(0.3)
                    end
                end)
            end
        end

        local function buildAcceptLoop(getCache)
            return function(toggleRef)
                task.spawn(function()
                    while toggleRef.Enabled do
                        if isTradeOpen() then task.wait(0.3); continue end
                        local targets = filterOnline(toList(getCache()))
                        for _, n in ipairs(targets) do
                            if not toggleRef.Enabled then break end
                            if isTradeOpen() then break end
                            acceptTrade(n)
                            task.wait(0.08)
                        end
                        task.wait(0.2)
                    end
                end)
            end
        end
        
        local function addToggles(box, cacheName, getCache)
            local sendToggle = { Enabled = false }
            local acceptToggle = { Enabled = false }
            
            box:AddToggle(cacheName.."_Send", {
                Text = "Send Trade", 
                Default = false, 
                Callback = function(v) 
                    sendToggle.Enabled = v
                    if v then buildSendLoop(getCache)(sendToggle) end 
                end
            })
            box:AddToggle(cacheName.."_Accept", {
                Text = "Auto Accept", 
                Default = false, 
                Callback = function(v) 
                    acceptToggle.Enabled = v
                    if v then buildAcceptLoop(getCache)(acceptToggle) end 
                end
            })
        end
        
        local function buildSavedBox(title, file, cacheName)
            local State = { Cache = {} }
            local box = Tabs.Trade:AddLeftGroupbox(title)
            local dd = box:AddDropdown(cacheName.."_Dropdown", {
                Text = "Players", 
                Values = loadList(file), 
                Multi = true, 
                Default = {}, 
                Callback = function(v) State.Cache = v end
            })
            box:AddInput(cacheName.."_Input", {
                Text = "Add Users", 
                Placeholder = "name1, name2", 
                Default = "", 
                Callback = function(v) State.Input = v end
            })
            box:AddButton("Save", function()
                local txt = State.Input or ""
                if txt ~= "" then
                    addMulti(file, txt)
                    dd:SetValues(loadList(file))
                    pcall(function() 
                        if Options and Options[cacheName.."_Input"] then 
                            Options[cacheName.."_Input"]:SetValue("") 
                        end 
                    end)
                    State.Input = ""
                end
            end)
            box:AddButton("Remove", function() 
                for _, n in ipairs(toList(State.Cache)) do 
                    removeName(file, n) 
                end 
                dd:SetValues(loadList(file)) 
            end)
            box:AddButton("Select All", function() 
                local all = selectAllFromFile(file) 
                dd:SetValue(all)
                State.Cache = all 
            end)
            box:AddButton("Deselect All", function() 
                dd:SetValue({})
                State.Cache = {} 
            end)
            box:AddButton("Refresh", function() 
                dd:SetValues(loadList(file)) 
            end)
            addToggles(box, cacheName, function() return State.Cache end)
        end
        
        -- Current Players (Online)
        local currentState = { Cache = nil }
        local g1 = Tabs.Trade:AddLeftGroupbox("Current Players")
        local cd = g1:AddDropdown("Trade_CurrentDropdown", {
            Text = "Online", 
            Values = {"No Players"}, 
            Multi = true, 
            Default = {}, 
            Callback = function(v) currentState.Cache = v end
        })
        
        g1:AddButton("Select All Online", function()
            local allOnline = {}
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Player then allOnline[p.Name] = true end
            end
            cd:SetValue(allOnline)
            currentState.Cache = allOnline
        end)
        
        g1:AddButton("Deselect All", function()
            cd:SetValue({})
            currentState.Cache = {}
        end)
        
        addToggles(g1, "Trade_Current", function() return currentState.Cache end)
        
        buildSavedBox("Account 1", file1, "Trade_Acc1")
        buildSavedBox("Account 2", file2, "Trade_Acc2")
        
        -- Refresh Online Players List
        task.spawn(function()
            while true do
                task.wait(1.5)
                pcall(function()
                    local onlineList = {}
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= Player then table.insert(onlineList, p.Name) end
                    end
                    cd:SetValues(#onlineList > 0 and onlineList or {"No Players"})
                end)
            end
        end)
    end)
end


-- ============================== SETTING TRADING ==============================
if IsLobbyLobby() then
    local SettingBox = Tabs.Trade:AddLeftGroupbox("Setting Trading")
    
    local selectedOption = "On"
    
    local function setHistory(state)
        local args = {"Functions", "Settings", "History", state}
        return pcall(function()
            game:GetService("ReplicatedStorage"):WaitForChild("Assets")
                :WaitForChild("Remotes"):WaitForChild("GET")
                :InvokeServer(unpack(args))
        end)
    end
    
    SettingBox:AddDropdown("HistoryOptionDropdown", {
        Text = "",
        Values = {"On", "Off"},
        Default = "On",
        Multi = false,
        Callback = function(v)
            selectedOption = v
        end
    })
    
    SettingBox:AddToggle("ApplyHistoryToggle", {
        Text = "Apply History",
        Default = false,
        Callback = function(v)
            if v then
                local success = setHistory(selectedOption)
                task.wait(0.1)
                pcall(function()
                    if Options and Options.ApplyHistoryToggle then
                        Options.ApplyHistoryToggle:SetValue(false)
                    end
                end)
            end
        end
    })
end
-- ============================== AUTO TRADE ALT 2 ==============================
if IsLobbyLobby() then
    task.spawn(function()
        while not Tabs.Trade do task.wait(0.1) end

        local Alt2Box = Tabs.Trade:AddRightGroupbox("Auto Trade : Manual")

        local Alt2Enabled = false
        local Alt2Running = false
        local SelectAmount = 1
        local isWaitingForConfirm = false
        local pendingTargetChange = false
        local newTargetValue = 1

        -- 🔥 ปรับค่าความเร็วให้เร็วที่สุด
        local ClickInterval = 0.015
        local MainLoopDelay = 0.01
        local AddPanelOpenDelay = 0.08
        local CheckWait = 0.005
        local ReduceWait = 0.02
        local AddWait = 0.001               -- ลดเหลือ 0.001 วินาที (เร็วมาก)
        local UIUpdateDelay = 0.03

        local Players = game:GetService("Players")
        local VIM = game:GetService("VirtualInputManager")
        local GS = game:GetService("GuiService")
        local player = Players.LocalPlayer
        local RunService = game:GetService("RunService")

        -- 🔥 Item Mapping (Memory Scroll ใช้ 600_Memory Scroll)
        local itemMapping = {
            ["Memory Scroll"] = "600_Memory Scroll",
            ["Emperor's Key"] = "500_Emperor's Key",
        }
        local SelectedItems = {"Memory Scroll"}

        -- 🔥 ฟังก์ชันเช็คว่า GUI Object ยังใช้งานได้จริงหรือไม่
        local function isGuiAlive(obj)
            if not obj then return false end
            if typeof(obj) ~= "Instance" then return false end
            if not obj.Parent then return false end

            local ok = pcall(function() return obj.AbsoluteSize end)
            if not ok then return false end

            if obj:IsA("GuiObject") then
                if obj.AbsoluteSize.X <= 0 or obj.AbsoluteSize.Y <= 0 then
                    return false
                end
            end

            local current = obj
            while current do
                if current:IsA("GuiObject") and not current.Visible then
                    return false
                end
                if current:IsA("ScreenGui") and not current.Enabled then
                    return false
                end
                current = current.Parent
            end

            return true
        end

        -- 🔥 ฟังก์ชันคลิกด้วยเมาส์ (เร็วสุด)
        local function clickWithMouse(target)
            if not isGuiAlive(target) then
                return false
            end

            local inset = GS:GetGuiInset()
            local x = target.AbsolutePosition.X + (target.AbsoluteSize.X / 2) + inset.X
            local y = target.AbsolutePosition.Y + (target.AbsoluteSize.Y / 2) + inset.Y

            VIM:SendMouseMoveEvent(x, y, game)
            task.wait(0.005)               -- ลดเหลือ 5ms

            VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.005)               -- ลดเหลือ 5ms
            VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
            task.wait(0.01)                -- ลดเหลือ 10ms แต่ยังพอให้เกมประมวลผล

            return true
        end

        -- ฟังก์ชัน click หลัก (ใช้ clickWithMouse)
        local function click(target)
            return clickWithMouse(target)
        end

        local boxOpenedTime = 0
        local hasCheckedInventoryTimeout = false
        local hasCheckedQuantityTimeout = false
        local INVENTORY_LOAD_TIMEOUT = 5
        local QUANTITY_ZERO_TIMEOUT = 3

        local function endTrade()
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Assets")
                    :WaitForChild("Remotes"):WaitForChild("GET")
                    :InvokeServer("S_Trade", "End")
            end)
        end

        local _cachedYouBox = false
        local _lastYouBoxCheck = 0
        local function isYouBoxVisible()
            local now = tick()
            if now - _lastYouBoxCheck < 0.01 then return _cachedYouBox end
            _lastYouBoxCheck = now
            local success, box = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box
            end)
            if not success or not box then _cachedYouBox = false; return false end
            if not box.Visible then _cachedYouBox = false; return false end
            if box.AbsoluteSize.X <= 0 or box.AbsoluteSize.Y <= 0 then _cachedYouBox = false; return false end

            local obj = box
            while obj do
                if obj:IsA("GuiObject") and not obj.Visible then _cachedYouBox = false; return false end
                if obj:IsA("ScreenGui") and not obj.Enabled then _cachedYouBox = false; return false end
                obj = obj.Parent
            end
            _cachedYouBox = true
            return true
        end

        local function isInventoryLoaded()
            local ok, holder = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.List.Holder
            end)
            if not ok or not holder or not holder.Visible then return false end
            local items = holder:FindFirstChild("Items")
            if not items then return false end
            return #items:GetChildren() > 0
        end

        local function getFirstItemQuantity()
            if #SelectedItems == 0 then return 0 end
            local itemName = SelectedItems[1]
            local realName = itemMapping[itemName] or itemName
            local ok, item = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box.Items[realName]
            end)
            if ok and item then
                local label = item.Main and item.Main.Inner and item.Main.Inner.Quantity
                if label then
                    return tonumber(label.Text:match("%d+")) or 0
                end
            end
            return 0
        end

        local function sendStateReady()
            local success1 = false
            local success2 = false
            
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Assets")
                    :WaitForChild("Remotes"):WaitForChild("GET")
                    :InvokeServer("S_Trade", "State", "Receiver", true)
                success1 = true
            end)
            
            pcall(function()
                game:GetService("ReplicatedStorage"):WaitForChild("Assets")
                    :WaitForChild("Remotes"):WaitForChild("GET")
                    :InvokeServer("S_Trade", "State", "Sender", true)
                success2 = true
            end)
            
            return (success1 or success2)
        end

        local function getTradeItem(itemName)
            if not isYouBoxVisible() then return nil end
            local realName = itemMapping[itemName] or itemName
            local success, item = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.List.Holder.Items[realName].Main.Interact
            end)
            return success and item or nil
        end

        local function getAddButton()
            if not isYouBoxVisible() then return nil end
            return pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box.Items.Item_Add
            end) and player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box.Items.Item_Add or nil
        end

        local function getAddButtonTitle()
            if not isYouBoxVisible() then return nil end
            local btn = getAddButton()
            return btn and pcall(function() return btn.Add.Inner.Title.Text end) and btn.Add.Inner.Title.Text or nil
        end

        local function getConfirm()
            return pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Review.Rate.Title
            end) and player.PlayerGui.Interface.Trading.Prompt.Review.Rate.Title or nil
        end

        local function getInventoryCount(itemName)
            if not isYouBoxVisible() then return 0 end
            local realName = itemMapping[itemName] or itemName
            local success, item = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.List.Holder.Items[realName]
            end)
            if success and item then
                local label = item.Main and item.Main.Inner and item.Main.Inner.Quantity
                return label and tonumber(label.Text:match("%d+")) or 0
            end
            return 0
        end

        local function getCurrentAddedCount(itemName)
            if not isYouBoxVisible() then return 0 end
            local realName = itemMapping[itemName] or itemName
            local success, item = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box.Items[realName]
            end)
            if success and item then
                local label = item.Main and item.Main.Inner and item.Main.Inner.Quantity
                return label and tonumber(label.Text:match("%d+")) or 0
            end
            return 0
        end

        local function allItemsMatchTarget(target)
            for _, itemName in ipairs(SelectedItems) do
                if getCurrentAddedCount(itemName) ~= target then
                    return false
                end
            end
            return true
        end

        local function waitForAddedStable(itemName, target, timeout)
            local start = tick()
            local lastAdded = getCurrentAddedCount(itemName)
            local stableTime = 0
            local requiredStable = 0.1
            
            while tick() - start < (timeout or 1.5) do
                if not isYouBoxVisible() then return false end
                local current = getCurrentAddedCount(itemName)
                if current == target then
                    if current == lastAdded then
                        stableTime = stableTime + CheckWait
                        if stableTime >= requiredStable then return true end
                    else 
                        stableTime = 0 
                    end
                else 
                    stableTime = 0 
                end
                lastAdded = current
                task.wait(CheckWait)
            end
            return false
        end

        Alt2Box:AddDropdown("Alt2_ItemSelectDropdown", {
            Text = "Select Items)",
            Values = {"Memory Scroll", "Emperor's Key"},
            Default = {"Memory Scroll"},
            Multi = true,
            Callback = function(val)
                SelectedItems = {}
                for item, enabled in pairs(val) do
                    if enabled then table.insert(SelectedItems, item) end
                end
                if Alt2Enabled then
                    isWaitingForConfirm = false
                    Alt2Running = false
                    pendingTargetChange = true
                    newTargetValue = SelectAmount
                end
            end
        })

        Alt2Box:AddSlider("Alt2_SelectAmountSlider", {
            Text = "Amount Per Item",
            Default = 1, Min = 1, Max = 100, Rounding = 0,
            Callback = function(val)
                if SelectAmount ~= val then
                    SelectAmount = val
                    if Alt2Enabled then
                        isWaitingForConfirm = false
                        Alt2Running = false
                        pendingTargetChange = true
                        newTargetValue = val
                    end
                end
            end
        })

        Alt2Box:AddToggle("Alt2_AutoTradeToggle", {
            Text = "Auto Trade [ Manual ]",
            Default = false,
            Callback = function(v)
                Alt2Enabled = v
                if not v then
                    isWaitingForConfirm = false
                    Alt2Running = false
                    pendingTargetChange = false
                    boxOpenedTime = 0
                    hasCheckedInventoryTimeout = false
                    hasCheckedQuantityTimeout = false
                end
            end
        })

        task.spawn(function()
            local lastConfirmClick = 0
            local confirmCooldown = 0.2
            while true do
                task.wait(0.05)
                pcall(function()
                    if not Alt2Enabled then return end
                    local confirmTitle = getConfirm()
                    if confirmTitle and confirmTitle:IsA("TextLabel") and string.lower(confirmTitle.Text) == "confirm" then
                        local visible = true
                        local obj = confirmTitle
                        while obj do
                            if obj:IsA("GuiObject") and not obj.Visible then visible = false; break end
                            if obj:IsA("ScreenGui") and not obj.Enabled then visible = false; break end
                            obj = obj.Parent
                        end
                        if visible and confirmTitle.AbsoluteSize.X > 0 then
                            if tick() - lastConfirmClick >= confirmCooldown then
                                click(confirmTitle)
                                lastConfirmClick = tick()
                                isWaitingForConfirm = false
                            end
                        end
                    end
                end)
            end
        end)

        task.spawn(function()
            while true do
                task.wait(0.5)
                pcall(function()
                    if not Alt2Enabled then return end
                    
                    if isYouBoxVisible() then
                        if boxOpenedTime == 0 then
                            boxOpenedTime = tick()
                        end
                        
                        local elapsed = tick() - boxOpenedTime
                        
                        if not hasCheckedInventoryTimeout and not isInventoryLoaded() then
                            if elapsed >= INVENTORY_LOAD_TIMEOUT then
                                endTrade()
                                hasCheckedInventoryTimeout = true
                            end
                        else
                            hasCheckedInventoryTimeout = true
                        end
                        
                        if not hasCheckedQuantityTimeout then
                            local qty = getFirstItemQuantity()
                            if qty == 0 then
                                if elapsed >= QUANTITY_ZERO_TIMEOUT then
                                    endTrade()
                                    hasCheckedQuantityTimeout = true
                                end
                            else
                                hasCheckedQuantityTimeout = true
                            end
                        end
                    else
                        boxOpenedTime = 0
                        hasCheckedInventoryTimeout = false
                        hasCheckedQuantityTimeout = false
                    end
                end)
            end
        end)

        -- 🔥 ปรับ processItem: เพิ่ม delay 1 วินาทีหลังจากกดปุ่ม + และใช้ AddWait ที่เร็วมาก
        local function processItem(itemName, target)
            if not isYouBoxVisible() then return false end
            
            local added = getCurrentAddedCount(itemName)
            local inventoryCount = getInventoryCount(itemName)
            local needed = target - added

            if added == target then return true end

            if needed < 0 then
                local realName = itemMapping[itemName] or itemName
                local youItem = pcall(function()
                    return player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box.Items[realName]
                end) and player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box.Items[realName] or nil
                
                if not youItem then return false end
                
                local current = added
                local targetTotal = target
                local clicksNeeded = current - targetTotal
                
                for i = 1, clicksNeeded do
                    if not Alt2Enabled or not isYouBoxVisible() then break end
                    local clickTarget = youItem:FindFirstChild("Main") or youItem
                    if clickTarget then
                        click(clickTarget)
                        task.wait(ReduceWait)
                        if getCurrentAddedCount(itemName) >= targetTotal then break end
                    end
                end
                return true
            end

            local addBtn = getAddButton()
            if not addBtn then return false end
            
            local addTitle = getAddButtonTitle()
            if addTitle == "+" then
                click(addBtn)
                task.wait(1)           -- รอ 1 วินาทีหลังจากกดบวก
                return false
            elseif addTitle ~= "-" then
                return false
            end

            local currentInv = getInventoryCount(itemName)
            if currentInv == 0 then return true end

            local actualNeeded = needed
            if currentInv < needed then
                actualNeeded = currentInv
                target = added + currentInv
            end
            
            if actualNeeded <= 0 then return true end

            local tradeItem = getTradeItem(itemName)
            if not tradeItem then return false end

            local current = added
            local targetTotal = target
            local clicksNeeded = targetTotal - current
            
            for i = 1, clicksNeeded do
                if not Alt2Enabled or not isYouBoxVisible() then break end
                click(tradeItem)
                task.wait(AddWait)     -- 0.001 วินาทีต่อครั้ง (เร็วมาก)
                if getCurrentAddedCount(itemName) >= targetTotal then break end
            end
            
            return true
        end

        task.spawn(function()
            while true do
                task.wait(MainLoopDelay)

                pcall(function()
                    if not Alt2Enabled then return end
                    if not isYouBoxVisible() then
                        Alt2Running = false
                        return
                    end

                    if isWaitingForConfirm then
                        local confirm = getConfirm()
                        if confirm and confirm:IsA("TextLabel") and string.lower(confirm.Text) == "confirm" then
                            click(confirm)
                            task.wait(0.05)
                            isWaitingForConfirm = false
                        end
                        return
                    end

                    if pendingTargetChange then
                        pendingTargetChange = false
                    end

                    if Alt2Running then return end
                    if not isYouBoxVisible() then return end

                    local target = SelectAmount

                    if allItemsMatchTarget(target) then
                        local allStable = true
                        for _, itemName in ipairs(SelectedItems) do
                            if not waitForAddedStable(itemName, target, 1) then
                                allStable = false
                                break
                            end
                        end
                        
                        if allStable then
                            Alt2Running = true
                            sendStateReady()
                            task.wait(0.05)
                            isWaitingForConfirm = true
                            Alt2Running = false
                        end
                        return
                    end

                    Alt2Running = true
                    for _, itemName in ipairs(SelectedItems) do
                        if not Alt2Enabled or not isYouBoxVisible() then break end
                        processItem(itemName, target)
                        task.wait(0.05)   -- delay ระหว่าง items
                    end
                    Alt2Running = false
                end)
            end
        end)
    end)
end
-- ============================== MISC: AUTO TELEPORT ==============================
if IsLobbyLobby() then
    task.spawn(function()
        while not Tabs.Trade do task.wait(0.1) end
        task.wait(0.5)

        local MiscGroup = Tabs.Trade:AddRightGroupbox("Misc : Auto Save")

        local alreadyTeleported = false
        local hasChecked = false
        local panelWasOpen = false
        local holderCheckCount = 0
        local MAX_HOLDER_CHECKS = 30
        
        local LOBBY_ID = 14916516914
        local TeleportService = game:GetService("TeleportService")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local RunService = game:GetService("RunService")
        
        local CONFIG_FILE = "FakeHUB/teleport_config.json"
        local MonitorEnabled = false
        local minScrolls = 1
        
        if isfile(CONFIG_FILE) then
            pcall(function()
                local data = game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE))
                MonitorEnabled = data.MonitorEnabled or false
                minScrolls = data.minScrolls or 1
            end)
        end
        
        local function saveConfig()
            local data = {
                MonitorEnabled = MonitorEnabled,
                minScrolls = minScrolls,
                lastSaved = os.date("%Y-%m-%d %H:%M:%S")
            }
            pcall(function()
                if not isfolder("FakeHUB") then makefolder("FakeHUB") end
                writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(data))
            end)
        end
        
        MiscGroup:AddSlider("AutoTeleport_MinScrollsSlider", {
            Text = "Teleport when <= (scrolls)",
            Default = minScrolls,
            Min = 0,
            Max = 100,
            Rounding = 0,
            Callback = function(v)
                minScrolls = v
                saveConfig()
            end
        })
        
        MiscGroup:AddDropdown("AutoTeleport_EnableDropdown", {
            Text = "Auto Teleport When Low",
            Values = {"Disabled", "Enabled"},
            Default = MonitorEnabled and "Enabled" or "Disabled",
            Multi = false,
            Callback = function(val)
                MonitorEnabled = (val == "Enabled")
                saveConfig()
                if MonitorEnabled then
                    hasChecked = false
                    alreadyTeleported = false
                    panelWasOpen = false
                    holderCheckCount = 0
                end
            end
        })

        MiscGroup:AddDivider()
        MiscGroup:AddLabel("Destination: Lobby")
        
        local function isAddPanelOpen()
            local success, title = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box.Items.Item_Add.Add.Inner.Title
            end)
            if success and title and title:IsA("TextLabel") then
                return title.Text == "-"
            end
            return false
        end
        
        local function isHolderFullyLoaded()
            local success, result = pcall(function()
                local holder = player.PlayerGui.Interface.Trading.Prompt.List.Holder
                if not holder then return false end
                if not holder.Visible then return false end
                local items = holder:FindFirstChild("Items")
                if not items then return false end
                if items:FindFirstChild("600_Memory Scroll") then
                    return true
                end
                return false
            end)
            return success and result or false
        end
        
        local function getInventoryCount()
            local success, count = pcall(function()
                local scroll = game:GetService("Players").LocalPlayer.PlayerGui.Interface.Trading.Prompt.List.Holder.Items["600_Memory Scroll"]
                if not scroll then return 0 end
                local main = scroll:FindFirstChild("Main")
                if not main then return 0 end
                local inner = main:FindFirstChild("Inner")
                if not inner then return 0 end
                local quantity = inner:FindFirstChild("Quantity")
                if quantity and quantity:IsA("TextLabel") and quantity.Text then
                    local num = tonumber(quantity.Text:match("%d+"))
                    return num or 0
                end
                return 0
            end)
            return (success and count) or 0
        end

        local function teleportToLobby()
            if alreadyTeleported then return end
            alreadyTeleported = true
            task.wait(0.1)
            pcall(function() TeleportService:Teleport(LOBBY_ID, player) end)
        end
        
        local function resetSessionState()
            hasChecked = false
            alreadyTeleported = false
            panelWasOpen = false
            holderCheckCount = 0
        end

        RunService.RenderStepped:Connect(function()
            if not MonitorEnabled then
                return
            end
            
            if alreadyTeleported then
                return
            end
            
            local tradeOpen = false
            pcall(function()
                local trading = player.PlayerGui:FindFirstChild("Interface")
                if trading then
                    trading = trading:FindFirstChild("Trading")
                    if trading then
                        tradeOpen = trading.Visible == true
                    end
                end
            end)
            
            if not tradeOpen then
                if hasChecked then resetSessionState() end
                return
            end
            
            local panelOpen = isAddPanelOpen()
            
            if panelOpen then
                if not panelWasOpen then
                    panelWasOpen = true
                    holderCheckCount = 0
                end
                
                if not hasChecked then
                    holderCheckCount = holderCheckCount + 1
                    
                    if isHolderFullyLoaded() then
                        hasChecked = true
                        local count = getInventoryCount()
                        if count <= minScrolls then
                            teleportToLobby()
                        end
                    elseif holderCheckCount >= MAX_HOLDER_CHECKS then
                        hasChecked = true
                    end
                end
            else
                if panelWasOpen then
                    panelWasOpen = false
                    holderCheckCount = 0
                end
            end
        end)
    end)
end
-- ============================== UI SETTINGS (SaveManager only, no extra file) ==============================
local UISettingsTab = Window:AddTab("Settings")
local MenuGroup = UISettingsTab:AddLeftGroupbox("Menu")

-- ============================== SAFE TOGGLE FUNCTIONS ==============================
local function IsUIVisible()
    return Window and Window.Holder and Window.Holder.Visible
end

local function HideUI()
    -- Behaves exactly like pressing the "End" keybind
    pcall(function()
        if IsUIVisible() then
            Library:Toggle()
        end
    end)
end

-- ============================== AUTO HIDE TOGGLE (Saved by SaveManager) ==============================
MenuGroup:AddToggle("HideUIToggle", {
    Text = "Auto Hide UI",
    Default = false,                       -- will be overridden by SaveManager on load
    Callback = function(v)
        -- Do NOT hide/show immediately. This setting only affects the next time the script loads.
        -- The actual hiding is done in the autoload block below.
        -- SaveManager will save the value automatically, no extra file needed.
        -- Note: The user can still manually hide using the keybind.
    end
})

-- ============================== UNLOAD ==============================
MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

-- ============================== KEYBIND ==============================
MenuGroup:AddLabel("Menu Bind"):AddKeyPicker(
    "MenuKeybind",
    {
        Default = "End",
        NoUI = true,
        Text = "Menu Keybind",
        Callback = function(key)
            if Library and Options.MenuKeybind then
                Library.ToggleKeybind = Options.MenuKeybind
            end
        end
    }
)

task.defer(function()
    pcall(function()
        if Options and Options.MenuKeybind and Library then
            Library.ToggleKeybind = Options.MenuKeybind
        end
    end)
end)

-- ============================== CONFIG SECTION PATCH (Delete config) ==============================
local oldBuildConfigSection = SaveManager.BuildConfigSection
function SaveManager:BuildConfigSection(tab)
    if oldBuildConfigSection then
        oldBuildConfigSection(self, tab)
    end

    local section = tab:AddRightGroupbox("Configuration")
    section:AddButton("Delete config", function()
        if not Options or not Options.SaveManager_ConfigList then return end
        local name = Options.SaveManager_ConfigList.Value
        if not name then return end

        local filePath = self.Folder .. "/settings/" .. name .. ".json"
        if isfile(filePath) then
            delfile(filePath)
            Options.SaveManager_ConfigList:SetValues(self:RefreshConfigList())
            Options.SaveManager_ConfigList:SetValue(nil)
        end
    end)
end

SaveManager:BuildConfigSection(UISettingsTab)

-- ============================== THEME ==============================
pcall(function()
    if ThemeManager and ThemeManager.BuiltInThemes and ThemeManager.BuiltInThemes["Jester"] then
        ThemeManager:ApplyTheme("Jester")
        ThemeManager:SaveDefault("Jester")
    elseif ThemeManager and ThemeManager.ApplyTheme then
        ThemeManager:ApplyTheme("Default")
    end
end)

-- ============================== AUTOLOAD + AUTO HIDE ==============================
task.spawn(function()
    task.wait(0.25)

    -- Load the config (this will set the value of HideUIToggle, but the callback will not hide because we removed the immediate hide)
    pcall(function()
        SaveManager:LoadAutoloadConfig()
    end)

    -- Wait until the window actually exists
    for i = 1, 40 do
        if Window and Window.Holder then break end
        task.wait(0.05)
    end
    task.wait(0.15) -- extra delay to ensure everything is ready

    -- If the toggle is ON, hide the UI once (this happens only when the script loads, i.e., "next time the UI opens")
    if Toggles["HideUIToggle"] and Toggles["HideUIToggle"].Value and IsUIVisible() then
        HideUI()
    end
end)
-- ============================== MAIN MENU UI (SELECT START + CLICK JOIN COMMUNITY ONLY) ==============================
if IsMainmenuLobby() then
    local g = Tabs.MainMenu:AddRightGroupbox("Select Start")

    local d, s, a = 1, false, "A"

    local Players = game:GetService("Players")
    local VIM = game:GetService("VirtualInputManager")
    local GS = game:GetService("GuiService")

    local p = Players.LocalPlayer
    local PlayerGui = p.PlayerGui

    local function GetSlots()
        local i = PlayerGui:FindFirstChild("Interface")
        if not i then return nil end
        local t = i:FindFirstChild("Title_Screen")
        if not t then return nil end
        return t:FindFirstChild("Slots")
    end

    local function GetLogo()
        local i = PlayerGui:FindFirstChild("Interface")
        if not i then return nil end
        local t = i:FindFirstChild("Title_Screen")
        if not t then return nil end
        return t:FindFirstChild("Logo")
    end

    local function IsVisible(obj)
        if not obj then return false end
        if obj:IsA("ScreenGui") then return obj.Enabled end
        if obj:IsA("GuiObject") then
            return obj.Visible and obj.AbsoluteSize.X > 1 and obj.AbsoluteSize.Y > 1
        end
        return false
    end

    local function IsLogoActuallyVisible(obj)
        if not obj then return false end
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            if obj.ImageTransparency < 0.95 and obj.AbsoluteSize.X > 5 and obj.AbsoluteSize.Y > 5 then
                return true
            end
        end
        for _, v in ipairs(obj:GetDescendants()) do
            if v:IsA("ImageLabel") or v:IsA("ImageButton") then
                if v.Visible and v.ImageTransparency < 0.95 and v.AbsoluteSize.X > 5 and v.AbsoluteSize.Y > 5 then
                    return true
                end
            end
            if v:IsA("TextLabel") or v:IsA("TextButton") then
                if v.Visible and v.TextTransparency < 0.95 and v.AbsoluteSize.X > 5 and v.AbsoluteSize.Y > 5 then
                    return true
                end
            end
        end
        return false
    end

    -- คลิกปุ่มแบบแม่นยำ
    local function clickButton(target)
        if not target or not target.Visible then return false end
        
        local obj = target
        while obj and obj ~= p.PlayerGui do
            if obj:IsA("GuiObject") and not obj.Visible then return false end
            if obj:IsA("ScreenGui") and not obj.Enabled then return false end
            obj = obj.Parent
        end
        
        if target.AbsoluteSize.X <= 0 or target.AbsoluteSize.Y <= 0 then return false end
        
        GS.SelectedObject = target
        task.wait(0.05)
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.1)
        GS.SelectedObject = nil
        
        return true
    end

    local function SelectSlot()
        if not s then return false end
        local map = {A = "Select_A", B = "Select_B", C = "Select_C"}
        local Slots = GetSlots()
        if not Slots then return false end
        local slot = Slots:FindFirstChild(a)
        if not slot then return false end
        local button = slot:FindFirstChild(map[a])
        if not button then return false end
        return clickButton(button)
    end

    g:AddDropdown("SlotSelectionDropdown", {
        Values = {"A","B","C"}, Default = "A", Multi = false,
        Text = "Select Slot", Callback = function(x) a = x end
    })
    g:AddDivider()
    g:AddSlider("SelectDelaySlider", {
        Text = "Delay", Default = d, Min = 0.1, Max = 10, Rounding = 1,
        Callback = function(x) d = x end
    })
    g:AddDivider()
    g:AddToggle("AutoClickSelectToggle", {
        Text = "Auto Click [ SELECT ]", Default = false,
        Callback = function(x)
            s = x
            if not x then return end
            task.spawn(function()
                while s do
                    task.wait(0.3)
                    local Slots = GetSlots()
                    if IsLogoActuallyVisible(GetLogo()) then continue end
                    if not IsVisible(Slots) then continue end
                    SelectSlot()
                    task.wait(d)
                end
            end)
        end
    })

 -- ============================== CLICK JOIN COMMUNITY ==============================
local C = Tabs.MainMenu:AddRightGroupbox("Join Community")

local autoJoinEnabled = false
local autoNotNowEnabled = false

local function IsJoinCommunityDialogVisible()
    local success, dialog = pcall(function()
        return game:GetService("CoreGui").RobloxGui.FocusNavigationCoreScriptsWrapper.Dialog
    end)
    if not success or not dialog then return false end
    return dialog.Visible == true
end

-- 🔥 ดึงปุ่มทั้งหมดใน ActionsContainer ที่เป็น GuiButton และ Visible
local function getDialogButtons()
    local success, actionsContainer = pcall(function()
        return game:GetService("CoreGui").RobloxGui
            .FocusNavigationCoreScriptsWrapper.Dialog.DialogContentWrapper.Dialog
            .DialogInner.DialogBody.DialogActions.ActionsContainer
    end)
    if not success or not actionsContainer then return {} end
    
    local buttons = {}
    for _, child in ipairs(actionsContainer:GetChildren()) do
        if child:IsA("GuiButton") and child.Visible and child.AbsoluteSize.X > 0 and child.AbsoluteSize.Y > 0 then
            table.insert(buttons, child)
        end
    end
    return buttons
end

-- 🔥 คลิกปุ่มแรก → Join Community
local function clickJoinButton()
    local buttons = getDialogButtons()
    if #buttons >= 1 then
        return clickButton(buttons[1])
    end
    return false
end

-- 🔥 คลิกปุ่มที่สอง → Not Now
local function clickNotNowButton()
    local buttons = getDialogButtons()
    if #buttons >= 2 then
        return clickButton(buttons[2])
    end
    return false
end

C:AddToggle("AutoDialogClickerToggle", {
    Text = "Auto Click 'Join Community'", Default = false,
    Callback = function(v)
        autoJoinEnabled = v
    end
})

C:AddToggle("AutoNotNowClickerToggle", {
    Text = "Not Click Join Commu", Default = false,
    Callback = function(v)
        autoNotNowEnabled = v
    end
})

task.spawn(function()
    while true do
        task.wait(0.3)
        pcall(function()
            if IsJoinCommunityDialogVisible() then
                if autoJoinEnabled then
                    clickJoinButton()
                elseif autoNotNowEnabled then
                    clickNotNowButton()
                end
            end
        end)
    end
end)
end

-- ============================== AUTO JOIN ==============================
if IsMainmenuLobby() then
    local J = Tabs.MainMenu:AddRightGroupbox("Auto Join")

    local D2 = 0
    local Dst = "Lobby"
    local E = false
    local R = false
    local Lf = 0

    local Players = game:GetService("Players")
    local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local function IsFollowFrameOpen()
        local ok, follow = pcall(function()
            return PlayerGui.Interface.Title_Screen.Follow
        end)
        if not ok or not follow then return false end
        return follow.Visible == true
    end

    local function TeleportTo(destination)
        local args = {"Functions", "Teleport", destination}
        pcall(function()
            GET:InvokeServer(unpack(args))
        end)
    end

    J:AddDropdown("JoinDestinationDropdown", {
        Values = {"Lobby","Trade"}, Default = "Lobby", Multi = false,
        Text = "Teleport To", Callback = function(x) Dst = x end
    })
    J:AddSlider("AutoJoinDelaySlider", {
        Text = "Delay (seconds)", Default = 0, Min = 0, Max = 120, Rounding = 0,
        Callback = function(x) D2 = x end
    })
    J:AddToggle("MyToggle", {
        Text = "Auto Join", Default = false,
        Callback = function(x)
            E = x
            if not x then R = false; return end
            if R then return end
            R = true
            task.spawn(function()
                while E do
                    task.wait(0.3)
                    
                    if not IsFollowFrameOpen() then
                        continue
                    end
                    
                    if tick() - Lf < 2 then continue end
                    if D2 > 0 then task.wait(D2) end
                    Lf = tick()
                    TeleportTo(Dst)
                end
                R = false
            end)
        end
    })
end
-- ============================== TELEPORT NOW ==============================
if IsMainmenuLobby() or IsLobbyLobby() then
    local tab = Tabs.MainMenu or Tabs.Lobby
    local g = tab:AddLeftGroupbox("Teleport Now")
    local l = g:AddLabel("")
    local function DoTP(id) pcall(function() TeleportService:Teleport(id, Player) end) end
    local function AddConfirm(name, id, time)
        local c = false
        g:AddButton(name, function()
            if c then DoTP(id)
            else
                c = true; l:SetText("Are you sure?")
                task.delay(time or 3, function() c = false; l:SetText("") end)
            end
        end)
    end
    AddConfirm("Teleport to Main Menu", MAIN_MENU_ID, 1.5)
    AddConfirm("Teleport to Lobby", LOBBY_ID)
    AddConfirm("Teleport to Trading", TRADE_LOBBY_ID)
    
    -- ============================== AUTO TELEPORT AFTER TIME ==============================
    g:AddDivider()
    
    local autoTeleportEnabled = false
    local autoTeleportTime = 0
    local teleportAttempts = 0
    local maxAttempts = 5
    local isTeleporting = false
    local startTime = 0
    
    -- Slider สำหรับตั้งเวลา (0-600 วินาที)
    g:AddSlider("AutoTeleportTimeSlider", {
        Text = "Teleport Main Menu After x Minute",
        Default = 0,
        Min = 0,
        Max = 600,
        Rounding = 0,
        Suffix = "sec",
        Callback = function(v)
            autoTeleportTime = v
        end
    })
    
    -- Toggle สำหรับเปิด/ปิดระบบ
    g:AddToggle("AutoTeleportToggle", {
        Text = "Enable Auto Teleport",
        Default = false,
        Callback = function(v)
            autoTeleportEnabled = v
            if not v then
                teleportAttempts = 0
                isTeleporting = false
                startTime = 0
            else
                teleportAttempts = 0
                isTeleporting = false
                startTime = tick()
            end
        end
    })
    
    -- Loop สำหรับตรวจสอบเวลาและ Teleport (ทำงานทุก place id)
    task.spawn(function()
        while true do
            task.wait(1) -- ตรวจสอบทุก 1 วินาที
            
            if autoTeleportEnabled and not isTeleporting then
                local elapsed = tick() - startTime
                if elapsed >= autoTeleportTime then
                    isTeleporting = true
                    teleportAttempts = 0
                end
            end
            
            if autoTeleportEnabled and isTeleporting then
                teleportAttempts = teleportAttempts + 1
                
                -- พยายาม Teleport
                pcall(function() TeleportService:Teleport(MAIN_MENU_ID, Player) end)
                
                -- ถ้าพยายามครบ 5 ครั้งแล้ว ให้ปิดเกม
                if teleportAttempts >= maxAttempts then
                    game:Shutdown()
                end
                
                task.wait(5) -- รอ 5 วินาทีก่อนพยายามครั้งต่อไป
            end
        end
    end)
end
-- ============================== AUTO MISSION / RAID / WAVES (TABBED) ==============================
-- หา Remote แบบไดนามิก (Us Suite style)
local function findMissionRemote()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local remotesFolder = ReplicatedStorage:FindFirstChild("Assets") 
        and ReplicatedStorage.Assets:FindFirstChild("Remotes")
        or ReplicatedStorage:FindFirstChild("Remotes")
        or ReplicatedStorage:FindFirstChild("Network")
        or ReplicatedStorage:FindFirstChild("RemoteEvents")
    
    if not remotesFolder then
        for _, child in ipairs(ReplicatedStorage:GetChildren()) do
            if child:IsA("Folder") and (child.Name:lower():find("remote") or child.Name:lower():find("network")) then
                remotesFolder = child
                break
            end
        end
    end
    
    local getRemote = remotesFolder and remotesFolder:FindFirstChild("GET") 
        or ReplicatedStorage:FindFirstChild("GET")
        or ReplicatedStorage:FindFirstChild("GetRemote")
        or ReplicatedStorage:FindFirstChild("RequestData")
    
    return getRemote
end

local MissionGET = findMissionRemote()

-- Fallback รอ Remote โหลด
if not MissionGET then
    local waited = 0
    while not MissionGET and waited < 5 do
        task.wait(0.5)
        MissionGET = findMissionRemote()
        waited = waited + 0.5
    end
end

-- ฟังก์ชันเรียก Remote แบบปลอดภัย (Us Suite style)
local function SafeMissionCall(...)
    if not MissionGET then return false, nil end
    local args = {...}
    local success, result = pcall(function()
        return MissionGET:InvokeServer(unpack(args, 1, table.getn(args)))
    end)
    return success, result
end

-- ใช้ Tabs.Lobby เหมือนของเก่า
if Tabs.Lobby then

    -- ========== ฟังก์ชันตรวจสอบ Lobby Key หรือ Inventory ==========
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local function IsActuallyVisible(gui)
        if not gui or not gui:IsA("GuiObject") then return false end
        if not gui.Visible then return false end
        local current = gui.Parent
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return true
    end

    local function isUIActive()
        -- ตรวจสอบ Interface.Gear_Up.Lobby.Key
        local keyGui = player.PlayerGui:FindFirstChild("Interface")
        if keyGui then
            keyGui = keyGui:FindFirstChild("Gear_Up")
            if keyGui then
                keyGui = keyGui:FindFirstChild("Lobby")
                if keyGui then
                    keyGui = keyGui:FindFirstChild("Key")
                end
            end
        end
        local keyVisible = (keyGui and IsActuallyVisible(keyGui)) or false

        -- ตรวจสอบ Interface.Topbar.Main.Categories.Inventory
        local invGui = player.PlayerGui:FindFirstChild("Interface")
        if invGui then
            invGui = invGui:FindFirstChild("Topbar")
            if invGui then
                invGui = invGui:FindFirstChild("Main")
                if invGui then
                    invGui = invGui:FindFirstChild("Categories")
                    if invGui then
                        invGui = invGui:FindFirstChild("Inventory")
                    end
                end
            end
        end
        local inventoryVisible = (invGui and IsActuallyVisible(invGui)) or false

        return (keyVisible or inventoryVisible)
    end
    -- =====================================================

    local AutoMissionTabbox = Tabs.Lobby:AddLeftTabbox("Auto Content")

    -- ============================== TAB: MISSION ==============================
    local MissionTab = AutoMissionTabbox:AddTab("Mission")

    local MissionObjectives = {
        ["Shiganshina"] = {"Skirmish","Breach","Random"},
        ["Trost"] = {"Skirmish","Protect","Random"},
        ["Outskirts"] = {"Skirmish","Escort","Random"},
        ["Giant Forest"] = {"Skirmish","Guard","Random"},
        ["Utgard"] = {"Skirmish","Defend","Random"},
        ["Loading Docks"] = {"Skirmish","Stall","Random"},
        ["Stohess"] = {"Skirmish","Random"}
    }

    local ModifiersList = {
        "No Perks", "No Skills", "No Memories", "Nightmare", "Oddball",
        "Injury Prone", "Chronic Injuries", "Fog", "Glass Cannon", "Time Trial", "Boring", "Simple"
    }

    local MODIFIER_ORDER = {
        "No Perks", "No Skills", "No Memories", "Nightmare", "Oddball",
        "Injury Prone", "Chronic Injuries", "Fog", "Glass Cannon", "Time Trial", "Boring", "Simple"
    }

    local State_Mission = {
        Name = "Shiganshina",
        Objective = "Skirmish",
        Difficulty = "Hardest"
    }

    local MissionDelay = 0
    local missionRunning = false
    local missionBusy = false
    local missionSessionId = 0
    local lastNotifiedMissionMods = ""

    pcall(function()
        if Options and Options.MissionDropdown and Options.MissionDropdown.Value then State_Mission.Name = Options.MissionDropdown.Value end
        if Options and Options.ObjectiveDropdown and Options.ObjectiveDropdown.Value then State_Mission.Objective = Options.ObjectiveDropdown.Value end
        if Options and Options.MissionDifficultyDropdown and Options.MissionDifficultyDropdown.Value then State_Mission.Difficulty = Options.MissionDifficultyDropdown.Value end
        if Options and Options.MissionDelaySlider and Options.MissionDelaySlider.Value then MissionDelay = tonumber(Options.MissionDelaySlider.Value) or 0 end
    end)

    local function GetPlayerLevel()
        local success, level = pcall(function()
            local player = game:GetService("Players").LocalPlayer
            local playerGui = player:FindFirstChild("PlayerGui")
            if not playerGui then return 1 end
            local interface = playerGui:FindFirstChild("Interface")
            if not interface then return 1 end
            local gearUp = interface:FindFirstChild("Gear_Up")
            if not gearUp then return 1 end
            local hud = gearUp:FindFirstChild("HUD")
            if not hud then return 1 end
            local levelFrame = hud:FindFirstChild("Level")
            if not levelFrame then return 1 end
            local title = levelFrame:FindFirstChild("Title")
            if not title then return 1 end
            local txt = tostring(title.Text)
            local num = tonumber(txt:match("%d+"))
            return num or 1
        end)
        return success and level or 1
    end

    local function GetDifficultyCycle(missionType)
        local level = GetPlayerLevel()
        if missionType == "Raids" then
            if level >= 100 then return {"Aberrant"}
            elseif level >= 60 then return {"Aberrant", "Severe", "Hard"}
            elseif level >= 40 then return {"Severe", "Hard", "Normal"}
            else return {"Hard", "Normal", "Easy"} end
        end
        if level >= 100 then return {"Aberrant"}
        elseif level >= 60 then return {"Aberrant", "Severe", "Hard", "Normal", "Easy"}
        elseif level >= 40 then return {"Severe", "Hard", "Normal", "Easy"}
        else return {"Hard", "Normal", "Easy"} end
    end

    local function formatMissionModifiers(modList)
        if not modList or #modList == 0 then return nil end
        local sorted = {}
        for _, ordered in ipairs(MODIFIER_ORDER) do
            for _, m in ipairs(modList) do
                if m == ordered then table.insert(sorted, m); break end
            end
        end
        for _, m in ipairs(modList) do
            local found = false
            for _, ordered in ipairs(MODIFIER_ORDER) do
                if m == ordered then found = true; break end
            end
            if not found then table.insert(sorted, m) end
        end
        return "Modifiers:\n" .. table.concat(sorted, "\n")
    end

    local function CreateMission(missionName, objective, difficulty)
        if not missionRunning then return false end
        local success, _ = SafeMissionCall("S_Missions", "Create", {
            Difficulty = difficulty, 
            Type = "Missions", 
            Name = missionName, 
            Objective = objective
        })
        task.wait(0.15)
        return success
    end

    local function ClearMissionModifiers()
        if not missionRunning then return end
        for retry = 1, 2 do
            if not missionRunning then break end
            local success = SafeMissionCall("S_Missions", "ClearModifiers")
            if success then break end
            task.wait(0.2)
        end
        task.wait(0.3)
    end

    local function ApplyMissionModifiers()
        if not missionRunning then return end
        local selected = {}
        pcall(function()
            if Options and Options.MissionModifiersDropdown and Options.MissionModifiersDropdown.Value then
                local val = Options.MissionModifiersDropdown.Value
                if type(val) == "table" then
                    for mod, enabled in pairs(val) do
                        if enabled then table.insert(selected, mod) end
                    end
                end
            end
        end)
        if #selected == 0 then return end
        
        local modsString = table.concat(selected, ", ")
        if lastNotifiedMissionMods ~= modsString then
            lastNotifiedMissionMods = modsString
        end
        
        ClearMissionModifiers()
        if not missionRunning then return end
        
        for _, mod in ipairs(selected) do
            if not missionRunning then break end
            local success = false
            for retry = 1, 3 do
                if not missionRunning then break end
                success = SafeMissionCall("S_Missions", "Modify", mod)
                if success then break end
                task.wait(0.2)
            end
            task.wait(0.15)
        end
        task.wait(0.4)
    end

    local function StartMission()
        if not missionRunning then return end
        task.wait(0.1)
        SafeMissionCall("S_Missions", "Start")
    end

    local function LeaveMission()
        SafeMissionCall("S_Missions", "Leave")
    end

    local function GetMyMission()
        local start = tick()
        while (tick() - start) < 2 do
            local missions = game:GetService("ReplicatedStorage"):FindFirstChild("Missions")
            if missions then
                for _, mission in next, missions:GetChildren() do
                    if mission:FindFirstChild("Leader") and mission.Leader.Value == game.Players.LocalPlayer.Name then
                        return mission
                    end
                end
            end
            task.wait(0.1)
        end
        return nil
    end

    local function MissionLoop(mySession)
        task.wait(1)
        if MissionDelay > 0 then task.wait(MissionDelay) end
        
        while missionRunning and missionSessionId == mySession do
            if missionBusy then task.wait(0.05); continue end
            missionBusy = true
            
            local currentMission = State_Mission.Name
            local currentObjective = State_Mission.Objective
            local currentDifficulty = State_Mission.Difficulty

            if currentDifficulty == "Hardest" then
                local cycle = GetDifficultyCycle("Missions")
                local created = false
                for _, diff in ipairs(cycle) do
                    if not missionRunning or missionSessionId ~= mySession then break end
                    if State_Mission.Difficulty ~= "Hardest" then break end
                    
                    local objList = MissionObjectives[currentMission] or {"Skirmish"}
                    local obj = currentObjective
                    if obj == "Random" then
                        local filtered = {}
                        for _, v in ipairs(objList) do if v ~= "Random" then filtered[#filtered+1] = v end end
                        obj = filtered[math.random(#filtered)]
                    end
                    
                    CreateMission(currentMission, obj, diff)
                    task.wait(0.2)
                    
                    if GetMyMission() then
                        created = true
                        Library:Notify(string.format("Creating mission: %s - %s (%s)", currentMission, obj, diff), 2)
                        break
                    else
                        LeaveMission()
                        task.wait(0.5)
                    end
                    
                    if not missionRunning then break end
                end
                
                if not created then
                    Library:Notify("Mission creation failed, retrying later", 3)
                    missionBusy = false
                    task.wait(2)
                    continue
                end
                
                ApplyMissionModifiers()
                if not missionRunning then missionBusy = false; continue end
                task.wait(0.3)
                Library:Notify("Starting mission", 2)
                StartMission()
                local startTick = tick()
                repeat task.wait(0.05) until not missionRunning or missionSessionId ~= mySession or tick() - startTick >= 3.5
                if MissionDelay > 0 then task.wait(MissionDelay) end
                
            else
                local objList = MissionObjectives[currentMission] or {"Skirmish"}
                local obj = currentObjective
                if obj == "Random" then
                    local filtered = {}
                    for _, v in ipairs(objList) do if v ~= "Random" then filtered[#filtered+1] = v end end
                    obj = filtered[math.random(#filtered)]
                end
                
                CreateMission(currentMission, obj, currentDifficulty)
                task.wait(0.2)
                
                if not GetMyMission() then
                    Library:Notify("Mission creation failed, resetting lobby...", 2)
                    LeaveMission()
                    missionBusy = false
                    task.wait(0.5)
                    continue
                end
                
                Library:Notify(string.format("Creating mission: %s - %s (%s)", currentMission, obj, currentDifficulty), 2)
                ApplyMissionModifiers()
                if not missionRunning then missionBusy = false; continue end
                task.wait(0.3)
                Library:Notify("Starting mission", 2)
                StartMission()
                local startTick = tick()
                repeat task.wait(0.05) until not missionRunning or missionSessionId ~= mySession or tick() - startTick >= 0.45
            end
            missionBusy = false
        end
    end

    MissionTab:AddDropdown("MissionDropdown", {
        Values = {"Shiganshina","Trost","Outskirts","Giant Forest","Utgard","Loading Docks","Stohess"},
        Default = State_Mission.Name,
        Text = "Mission",
        Callback = function(val)
            State_Mission.Name = val
            local newObjs = MissionObjectives[val] or {"Skirmish"}
            State_Mission.Objective = newObjs[1]
            if Options and Options.MissionObjectiveDropdown then
                Options.MissionObjectiveDropdown:SetValues(newObjs)
                Options.MissionObjectiveDropdown:SetValue(newObjs[1])
            end
        end
    })

    MissionTab:AddDropdown("MissionObjectiveDropdown", {
        Values = MissionObjectives["Shiganshina"],
        Default = State_Mission.Objective,
        Text = "Objective",
        Callback = function(val) State_Mission.Objective = val end
    })

    MissionTab:AddDropdown("MissionDifficultyDropdown", {
        Values = {"Easy","Normal","Hard","Severe","Aberrant","Hardest"},
        Default = State_Mission.Difficulty,
        Text = "Mode",
        Callback = function(val) State_Mission.Difficulty = val end
    })

    MissionTab:AddDropdown("MissionModifiersDropdown", {
        Values = ModifiersList,
        Default = {},
        Multi = true,
        Text = "Modifiers",
        Callback = function() end
    })

    MissionTab:AddSlider("MissionDelaySlider", {
        Text = "Delay",
        Default = MissionDelay,
        Min = 0, Max = 60, Rounding = 0,
        Callback = function(v) MissionDelay = v end
    })

    -- ตัวแปรกลางสำหรับ Auto Content (เพิ่มตรงนี้)
    local activeAutoContent = nil  -- "mission", "raid", "waves"

    -- ========== ปรับ Toggle Mission ==========
    local missionPendingStart = false
    local missionStartTask = nil

    local missionToggle = MissionTab:AddToggle("AutoStartMissionToggle", {
        Text = "Start Mission",
        Default = false,
        Callback = function(v)
            if v then
                if missionRunning or missionPendingStart then return end
                if activeAutoContent ~= nil then
                    Library:Notify("Select one Toggle", 2)
                    pcall(function()
                        if Options and Options.AutoStartMissionToggle then
                            Options.AutoStartMissionToggle:SetValue(false)
                        end
                    end)
                    return
                end
                activeAutoContent = "mission"
                missionPendingStart = true
                missionStartTask = task.spawn(function()
                    while missionPendingStart do
                        if isUIActive() then
                            Library:Notify("Content Ready (Mission)", 2)
                            break
                        end
                        task.wait(0.5)
                    end
                    if missionPendingStart then
                        missionRunning = true
                        missionBusy = false
                        missionSessionId = missionSessionId + 1
                        task.spawn(MissionLoop, missionSessionId)
                    end
                    missionPendingStart = false
                end)
            else
                missionPendingStart = false
                if missionStartTask then task.cancel(missionStartTask) end
                missionRunning = false
                missionSessionId = missionSessionId + 1
                LeaveMission()
                if activeAutoContent == "mission" then activeAutoContent = nil end
            end
        end
    })

    -- ============================== TAB: RAID ==============================
    local RaidTab = AutoMissionTabbox:AddTab("Raid")

    local RaidObjectives = {
        ["Attack Titan"] = {name = "Trost", objective = "Attack Titan", hasMinimum = false},
        ["Armored Titan"] = {name = "Shiganshina", objective = "Armored Titan", hasMinimum = false},
        ["Female Titan"] = {name = "Stohess", objective = "Female Titan", hasMinimum = false},
        ["Colossal Titan"] = {name = "Shiganshina", objective = "Colossal Titan", hasMinimum = true, minimum = 3}
    }

    local State_Raid = { Boss = "Attack Titan", Difficulty = "Hardest" }
    local RaidDelay = 0
    local raidRunning = false
    local raidBusy = false
    local raidSessionId = 0
    local lastNotifiedRaidMods = ""

    pcall(function()
        if Options and Options.RaidBossDropdown and Options.RaidBossDropdown.Value then State_Raid.Boss = Options.RaidBossDropdown.Value end
        if Options and Options.RaidDifficultyDropdown and Options.RaidDifficultyDropdown.Value then State_Raid.Difficulty = Options.RaidDifficultyDropdown.Value end
        if Options and Options.RaidDelaySlider and Options.RaidDelaySlider.Value then RaidDelay = tonumber(Options.RaidDelaySlider.Value) or 0 end
    end)

    local function CreateRaid(bossName, difficulty)
        if not raidRunning then return false end
        local data = RaidObjectives[bossName]
        if not data then return false end
        
        local createArgs = {
            Difficulty = difficulty, 
            Type = "Raids", 
            Name = data.name, 
            Objective = data.objective
        }
        if data.hasMinimum then createArgs.Minimum = data.minimum end
        
        local success, _ = SafeMissionCall("S_Missions", "Create", createArgs)
        task.wait(0.15)
        return success
    end

    local function ClearRaidModifiers()
        if not raidRunning then return end
        for retry = 1, 2 do
            if not raidRunning then break end
            local success = SafeMissionCall("S_Missions", "ClearModifiers")
            if success then break end
            task.wait(0.2)
        end
        task.wait(0.3)
    end

    local function ApplyRaidModifiers()
        if not raidRunning then return end
        local selected = {}
        pcall(function()
            if Options and Options.RaidModifiersDropdown and Options.RaidModifiersDropdown.Value then
                local val = Options.RaidModifiersDropdown.Value
                if type(val) == "table" then
                    for mod, enabled in pairs(val) do
                        if enabled then table.insert(selected, mod) end
                    end
                end
            end
        end)
        if #selected == 0 then return end
        local modsString = table.concat(selected, ", ")
        if lastNotifiedRaidMods ~= modsString then
            lastNotifiedRaidMods = modsString
        end
        ClearRaidModifiers()
        if not raidRunning then return end
        for _, mod in ipairs(selected) do
            if not raidRunning then break end
            local success = false
            for retry = 1, 3 do
                if not raidRunning then break end
                success = SafeMissionCall("S_Missions", "Modify", mod)
                if success then break end
                task.wait(0.2)
            end
            task.wait(0.15)
        end
        task.wait(0.4)
    end

    local function StartRaid()
        if not raidRunning then return end
        task.wait(0.1)
        SafeMissionCall("S_Missions", "Start")
    end

    local function LeaveRaid()
        SafeMissionCall("S_Missions", "Leave")
    end

    local function RaidLoop(mySession)
        task.wait(1)
        if RaidDelay > 0 then task.wait(RaidDelay) end
        
        while raidRunning and raidSessionId == mySession do
            if raidBusy then task.wait(0.05); continue end
            raidBusy = true
            local currentBoss = State_Raid.Boss
            local currentDifficulty = State_Raid.Difficulty

            if currentDifficulty == "Hardest" then
                local cycle = GetDifficultyCycle("Raids")
                local created = false
                for _, diff in ipairs(cycle) do
                    if not raidRunning or raidSessionId ~= mySession then break end
                    if State_Raid.Difficulty ~= "Hardest" then break end
                    
                    CreateRaid(currentBoss, diff)
                    task.wait(0.2)
                    
                    if GetMyMission() then
                        created = true
                        Library:Notify(string.format("Creating raid: %s (%s)", currentBoss, diff), 2)
                        break
                    else
                        LeaveRaid()
                        task.wait(0.5)
                    end
                    
                    if not raidRunning then break end
                end
                
                if not created then
                    Library:Notify("Raid creation failed, retrying later", 3)
                    raidBusy = false
                    task.wait(2)
                    continue
                end
                
                ApplyRaidModifiers()
                if not raidRunning then raidBusy = false; continue end
                task.wait(0.3)
                Library:Notify("Starting raid", 2)
                StartRaid()
                local startTick = tick()
                repeat task.wait(0.05) until not raidRunning or raidSessionId ~= mySession or tick() - startTick >= 3.5
                if RaidDelay > 0 then task.wait(RaidDelay) end
                
            else
                CreateRaid(currentBoss, currentDifficulty)
                task.wait(0.2)
                
                if not GetMyMission() then
                    Library:Notify("Raid creation failed, resetting lobby...", 2)
                    LeaveRaid()
                    raidBusy = false
                    task.wait(0.5)
                    continue
                end
                
                Library:Notify(string.format("Creating raid: %s (%s)", currentBoss, currentDifficulty), 2)
                ApplyRaidModifiers()
                if not raidRunning then raidBusy = false; continue end
                task.wait(0.3)
                Library:Notify("Starting raid", 2)
                StartRaid()
                local startTick = tick()
                repeat task.wait(0.05) until not raidRunning or raidSessionId ~= mySession or tick() - startTick >= 0.45
            end
            raidBusy = false
        end
    end

    RaidTab:AddDropdown("RaidBossDropdown", {
        Values = {"Attack Titan","Armored Titan","Female Titan","Colossal Titan"},
        Default = State_Raid.Boss,
        Text = "Raid Boss",
        Callback = function(v) State_Raid.Boss = v end
    })

    RaidTab:AddDropdown("RaidDifficultyDropdown", {
        Values = {"Easy","Normal","Hard","Severe","Aberrant","Hardest"},
        Default = State_Raid.Difficulty,
        Text = "Mode",
        Callback = function(v) State_Raid.Difficulty = v end
    })

    RaidTab:AddDropdown("RaidModifiersDropdown", {
        Values = ModifiersList,
        Default = {},
        Multi = true,
        Text = "Modifiers",
        Callback = function() end
    })

    RaidTab:AddSlider("RaidDelaySlider", {
        Text = "Delay",
        Default = RaidDelay,
        Min = 0, Max = 60, Rounding = 0,
        Callback = function(v) RaidDelay = v end
    })

    -- ========== ปรับ Toggle Raid ==========
    local raidPendingStart = false
    local raidStartTask = nil

    local raidToggle = RaidTab:AddToggle("AutoRaidToggle", {
        Text = "Start Raid",
        Default = false,
        Callback = function(v)
            if v then
                if raidRunning or raidPendingStart then return end
                if activeAutoContent ~= nil then
                    Library:Notify("Select one Toggle", 2)
                    pcall(function()
                        if Options and Options.AutoRaidToggle then
                            Options.AutoRaidToggle:SetValue(false)
                        end
                    end)
                    return
                end
                activeAutoContent = "raid"
                raidPendingStart = true
                raidStartTask = task.spawn(function()
                    while raidPendingStart do
                        if isUIActive() then
                            Library:Notify("Content Ready (Raid)", 2)
                            break
                        end
                        task.wait(0.5)
                    end
                    if raidPendingStart then
                        raidRunning = true
                        raidBusy = false
                        raidSessionId = raidSessionId + 1
                        task.spawn(RaidLoop, raidSessionId)
                    end
                    raidPendingStart = false
                end)
            else
                raidPendingStart = false
                if raidStartTask then task.cancel(raidStartTask) end
                raidRunning = false
                raidSessionId = raidSessionId + 1
                LeaveRaid()
                if activeAutoContent == "raid" then activeAutoContent = nil end
            end
        end
    })

    -- ============================== TAB: WAVES ==============================
    local WavesTab = AutoMissionTabbox:AddTab("Waves")

    local wavesRunning = false
    local wavesBusy = false
    local wavesSessionId = 0

    local function CreateWave()
        if not wavesRunning then return false end
        local success, _ = SafeMissionCall("S_Missions", "Create", {
            Difficulty = "Easy",
            Type = "Waves",
            Name = "Trost",
            Objective = "Waves"
        })
        task.wait(0.15)
        return success
    end

    local function StartWave()
        if not wavesRunning then return end
        task.wait(0.1)
        SafeMissionCall("S_Missions", "Start")
    end

    local function LeaveWave()
        SafeMissionCall("S_Missions", "Leave")
    end

    local function WavesLoop(mySession)
        task.wait(1)
        while wavesRunning and wavesSessionId == mySession do
            if wavesBusy then
                task.wait(0.05)
                continue
            end
            wavesBusy = true

            CreateWave()
            task.wait(0.2)

            if not wavesRunning then break end

            Library:Notify("Creating wave", 2)
            Library:Notify("Starting wave", 2)
            StartWave()

            local startTick = tick()
            repeat
                task.wait(0.05)
                if not wavesRunning or wavesSessionId ~= mySession then break end
            until tick() - startTick >= 0.45

            wavesBusy = false
        end
    end

    -- ========== ปรับ Toggle Waves ==========
    local wavesPendingStart = false
    local wavesStartTask = nil

    local wavesToggle = WavesTab:AddToggle("AutoWavesToggle", {
        Text = "Start Waves",
        Default = false,
        Callback = function(v)
            if v then
                if wavesRunning or wavesPendingStart then return end
                if activeAutoContent ~= nil then
                    Library:Notify("Select one Toggle", 2)
                    pcall(function()
                        if Options and Options.AutoWavesToggle then
                            Options.AutoWavesToggle:SetValue(false)
                        end
                    end)
                    return
                end
                activeAutoContent = "waves"
                wavesPendingStart = true
                wavesStartTask = task.spawn(function()
                    while wavesPendingStart do
                        if isUIActive() then
                            Library:Notify("Content Ready (Waves)", 2)
                            break
                        end
                        task.wait(0.5)
                    end
                    if wavesPendingStart then
                        wavesRunning = true
                        wavesBusy = false
                        wavesSessionId = wavesSessionId + 1
                        local mySession = wavesSessionId
                        task.spawn(function()
                            WavesLoop(mySession)
                        end)
                    end
                    wavesPendingStart = false
                end)
            else
                wavesPendingStart = false
                if wavesStartTask then task.cancel(wavesStartTask) end
                wavesRunning = false
                wavesBusy = false
                wavesSessionId = wavesSessionId + 1
                LeaveWave()
                if activeAutoContent == "waves" then activeAutoContent = nil end
            end
        end
    })

end

-- ============================== AUTO UPGRADE ==============================
if IsLobbyLobby() then
    local UpgradeTabbox = Tabs.Session:AddLeftTabbox("Auto Upgrade")

    -- ========== ฟังก์ชันอ่านค่า Gold / Gems โดยตรง (ไม่ต้องพึ่งส่วนอื่น) ==========
    local function getGoldAmount()
        local player = game:GetService("Players").LocalPlayer
        local gold = 0
        pcall(function()
            local topbar = player.PlayerGui.Interface.Topbar.Main.Currencies
            if topbar then
                local goldLabel = topbar.Gold and topbar.Gold:FindFirstChild("Amount")
                if goldLabel and goldLabel.Text then
                    local goldText = goldLabel.Text:gsub("[^%d]", "")
                    gold = tonumber(goldText) or 0
                end
            end
        end)
        return gold
    end

    -- ========== ฟังก์ชันตรวจสอบว่า UI การอัปเกรดอยู่ในสถานะ "Ready" ==========
    local function isUpgradeReady()
        local player = game:GetService("Players").LocalPlayer
        local ready = false
        pcall(function()
            local equipment = player.PlayerGui.Interface:FindFirstChild("Equipment")
            if equipment then
                local statusLabel = equipment:FindFirstChild("Status") 
                                    or equipment:FindFirstChild("ReadyLabel")
                if statusLabel and statusLabel:IsA("TextLabel") then
                    if statusLabel.Text and statusLabel.Text:find("Ready") then
                        ready = true
                    end
                else
                    ready = true
                end
            else
                ready = true
            end
        end)
        return ready
    end

    -- =================== BLADE TAB ===================
    local BladeTab = UpgradeTabbox:AddTab("Blade")

    getgenv().AutoUpgradeBlade = false
    getgenv().UpgradeRunning = false
    getgenv().BladeUpgradeDelay = 0

    local ALL_BLADE_STATS = {
        "ODM_Gas", "ODM_Speed", "ODM_Range", "ODM_Control",
        "Crit_Damage", "ODM_Damage", "Crit_Chance", "Blade_Durability"
    }

    local function batchUpgradeBlade()
        if not GET then return false end
        local args = { "S_Equipment", "Upgrade", ALL_BLADE_STATS }
        local success = pcall(function()
            GET:InvokeServer(unpack(args))
        end)
        return success
    end

    BladeTab:AddSlider("BladeUpgradeDelaySlider", {
        Text = "Upgrade Delay (seconds)",
        Default = 0,
        Min = 0,
        Max = 60,
        Rounding = 0,
        Callback = function(v)
            getgenv().BladeUpgradeDelay = v
        end
    })

    BladeTab:AddToggle("AutoUpgradeBladeToggle", {
        Text = "Auto Upgrade Blade",
        Default = false,
        Callback = function(state)
            getgenv().AutoUpgradeBlade = state

            if state and not getgenv().UpgradeRunning then
                getgenv().UpgradeRunning = true

                task.spawn(function()
                    while getgenv().AutoUpgradeBlade do
                        local ready = isUpgradeReady()
                        local gold = getGoldAmount()
                        local delay = getgenv().BladeUpgradeDelay

                        if ready and gold >= 1000 then
                            batchUpgradeBlade()
                            if delay > 0 then
                                task.wait(delay)
                            else
                                task.wait()
                            end
                        else
                            task.wait(2)
                        end
                    end
                    getgenv().UpgradeRunning = false
                end)
            end
        end
    })

    -- =================== THUNDER SPEAR TAB ===================
    local SpearTab = UpgradeTabbox:AddTab("Thunder Spear")

    getgenv().AutoUpgradeSpear = false
    getgenv().SpearUpgradeRunning = false
    getgenv().SpearUpgradeDelay = 0

    local ALL_SPEAR_STATS = {
        "Blast_Radius",
        "TS_Damage",
        "TS_Gas",
        "TS_Range",
        "TS_Control",
        "Crit_Chance",
        "Crit_Damage",
        "TS_Speed"
    }

    local function batchUpgradeSpear()
        if not GET then return false end
        local args = { "S_Equipment", "Upgrade", ALL_SPEAR_STATS }
        local success = pcall(function()
            GET:InvokeServer(unpack(args))
        end)
        return success
    end

    SpearTab:AddSlider("SpearUpgradeDelaySlider", {
        Text = "Upgrade Delay (seconds)",
        Default = 0,
        Min = 0,
        Max = 60,
        Rounding = 0,
        Callback = function(v)
            getgenv().SpearUpgradeDelay = v
        end
    })

    SpearTab:AddToggle("AutoUpgradeSpearToggle", {
        Text = "Auto Upgrade Thunder Spear",
        Default = false,
        Callback = function(state)
            getgenv().AutoUpgradeSpear = state

            if state and not getgenv().SpearUpgradeRunning then
                getgenv().SpearUpgradeRunning = true

                task.spawn(function()
                    while getgenv().AutoUpgradeSpear do
                        local ready = isUpgradeReady()
                        local gold = getGoldAmount()
                        local delay = getgenv().SpearUpgradeDelay

                        if ready and gold >= 1000 then
                            batchUpgradeSpear()
                            if delay > 0 then
                                task.wait(delay)
                            else
                                task.wait()
                            end
                        else
                            task.wait(2)
                        end
                    end
                    getgenv().SpearUpgradeRunning = false
                end)
            end
        end
    })
end


-- ============================== UNLOCK SKILLS (SILENT MODE - SINGLE DELAY) ==============================
if IsLobbyLobby() then
    local UnlockGroupLeft = Tabs.Session:AddLeftGroupbox("Unlock Skills")

    -- กำหนดข้อมูลของแต่ละสาย
    local branches = {
        ["Support Left"] = {
            ids = {
                "70","71","72","73","74","75","76","77","78","79",
                "80","81","82","83","84","85","86","87","88","89"
            }
        },
        ["Support Right"] = {
            ids = {
                "70","71","72","73","74","75","76","77","78","79",
                "80","90","91","92","93","94","95","96","97","98"
            }
        },
        ["Offense Left"] = {
            ids = {
                "1","2","3","4","5","6","7","8","9","10","11","12","13",
                "26","27","28","29","30","31","32","33","34","35","36","37"
            }
        },
        ["Offense Right"] = {
            ids = {
                "1","2","3","4","5","6","7","8","9","10","11","12","13",
                "14","15","16","17","18","19","20","21","22","23","24","25"
            }
        },
        ["Defense Left"] = {
            ids = {
                "38","39","40","41","42","43","44","45",
                "58","59","60","61","62","63","64","65","66","67","68","69"
            }
        },
        ["Defense Right"] = {
            ids = {
                "38","39","40","41","42","43","44","45",
                "46","47","48","49","50","51","52","53","54","55","56","57"
            }
        }
    }

    -- ตัวแปรเก็บค่าที่เลือก
    local selected = { Support = nil, Offense = nil, Defense = nil }
    local orderLabel = nil
    local isUnlocking = false

    -- ตัวแปรสำหรับ delay เดียว
    local unlockDelay = 0.08

    -- ฟังก์ชันอัปเดต Order Label
    local function updateOrderLabel()
        local items = {}
        if selected.Defense then items[#items+1] = "Defense " .. selected.Defense end
        if selected.Offense then items[#items+1] = "Offense " .. selected.Offense end
        if selected.Support then items[#items+1] = "Support " .. selected.Support end
        local orderText = "Order:\n"
        if #items == 0 then
            orderText = orderText .. "   (none selected)"
        else
            for i, v in ipairs(items) do
                orderText = orderText .. string.format("   %d. %s\n", i, v)
            end
        end
        if orderLabel then orderLabel:SetText(orderText) end
    end

    -- สร้าง dropdown
    local function createDropdown(category, text)
        local dropdown = UnlockGroupLeft:AddDropdown(category .. "SideDropdown", {
            Text = text,
            Values = {"None", "Left", "Right"},
            Default = "None",
            Multi = false,
            Callback = function(v)
                if v == "None" then selected[category] = nil else selected[category] = v end
                updateOrderLabel()
            end
        })
        return dropdown
    end

    local supportDropdown = createDropdown("Support", "Support Side")
    local offenseDropdown = createDropdown("Offense", "Offense Side")
    local defenseDropdown = createDropdown("Defense", "Defense Side")

    -- Label แสดงลำดับ
    orderLabel = UnlockGroupLeft:AddLabel("Order:\n   (none selected)", true)

    -- Slider เดียวสำหรับตั้งค่า Delay
    UnlockGroupLeft:AddSlider("UnlockDelaySlider", {
        Text = "Unlock Delay (sec)",
        Default = 0.08,
        Min = 0.01,
        Max = 1,
        Rounding = 2,
        Callback = function(v) unlockDelay = v end
    })

    -- ปุ่ม Clear All Selections
    UnlockGroupLeft:AddButton("Clear All Selections", function()
        supportDropdown:SetValue("None")
        offenseDropdown:SetValue("None")
        defenseDropdown:SetValue("None")
        selected.Support = nil
        selected.Offense = nil
        selected.Defense = nil
        updateOrderLabel()
    end)

    UnlockGroupLeft:AddDivider()

    -- ฟังก์ชัน Unlock ทีละ ID (เงียบ)
    local function unlockSingleId(id, retryCount)
        retryCount = retryCount or 0
        local success, err = pcall(function()
            GET:InvokeServer("S_Equipment", "Unlock", { id })
        end)
        if not success and retryCount < 3 then
            task.wait(0.2)
            return unlockSingleId(id, retryCount + 1)
        end
        return success, err
    end

    -- ฟังก์ชัน Unlock ทั้งสาย (เงียบ ไม่มี notify)
    local function unlockBranch(ids)
        for _, id in ipairs(ids) do
            unlockSingleId(id)
            task.wait(unlockDelay)
        end
    end

    -- ฟังก์ชันรอ UI และแสดง Gold (ครั้งเดียว)
    local function showGoldAndWait()
        -- รอ Window.Holder แสดง
        while not (Window and Window.Holder and Window.Holder.Visible) do
            task.wait(0.1)
        end
        -- รอให้ Gold Amount มีค่า
        local player = game:GetService("Players").LocalPlayer
        local goldLabel = nil
        repeat
            task.wait(0.1)
            goldLabel = player.PlayerGui:FindFirstChild("Interface") and
                        player.PlayerGui.Interface:FindFirstChild("Topbar") and
                        player.PlayerGui.Interface.Topbar:FindFirstChild("Main") and
                        player.PlayerGui.Interface.Topbar.Main:FindFirstChild("Currencies") and
                        player.PlayerGui.Interface.Topbar.Main.Currencies:FindFirstChild("Gold") and
                        player.PlayerGui.Interface.Topbar.Main.Currencies.Gold:FindFirstChild("Amount")
        until goldLabel and goldLabel.Text and goldLabel.Text:gsub("[^%d]", "") ~= ""
        local goldText = goldLabel.Text:gsub("[^%d]", "")
        local goldAmount = tonumber(goldText) or 0
        Library:Notify(string.format("💰 Gold: %s", goldAmount), 3)
        task.wait(0.2)
    end

    -- Toggle สำหรับเริ่มปลดล็อค
    UnlockGroupLeft:AddToggle("UnlockSkillsToggle", {
        Text = "Start Unlock Skills Blades",
        Default = false,
        Callback = function(v)
            if not v then return end
            if isUnlocking then
                pcall(function()
                    if Options and Options.UnlockSkillsToggle then
                        Options.UnlockSkillsToggle:SetValue(false)
                    end
                end)
                return
            end

            -- แสดง Gold เพียงครั้งเดียว
            showGoldAndWait()

            -- รวบรวมสายที่เลือก (เรียงลำดับ: Defense, Offense, Support)
            local queue = {}
            if selected.Defense then
                local side = selected.Defense
                local branchName = "Defense " .. side
                table.insert(queue, branches[branchName].ids)
            end
            if selected.Offense then
                local side = selected.Offense
                local branchName = "Offense " .. side
                table.insert(queue, branches[branchName].ids)
            end
            if selected.Support then
                local side = selected.Support
                local branchName = "Support " .. side
                table.insert(queue, branches[branchName].ids)
            end

            if #queue == 0 then
                pcall(function()
                    if Options and Options.UnlockSkillsToggle then
                        Options.UnlockSkillsToggle:SetValue(false)
                    end
                end)
                return
            end

            isUnlocking = true
            task.spawn(function()
                for i, ids in ipairs(queue) do
                    unlockBranch(ids)
                    if i < #queue then
                        task.wait(unlockDelay)  -- ใช้ delay เดียวกันระหว่าง branch
                    end
                end
                isUnlocking = false
                pcall(function()
                    if Options and Options.UnlockSkillsToggle then
                        Options.UnlockSkillsToggle:SetValue(false)
                    end
                end)
            end)
        end
    })
end
-- ============================== BOOST SELECTION ==============================
if IsLobbyLobby() then

    local BoostGroup = Tabs.Lobby:AddRightGroupbox("Boost Selection")

    local purchaseAmount = 1
    local purchaseDelay = 0
    local isReady = false

    local ALL_BOOSTS = {
        "2X XP Boost [30M]", "2X Luck [30M]", "2X Gold [30M]",
        "2X XP Boost [1H]", "2X Luck [1H]", "2X Gold [1H]",
        "2X XP Boost [2H]", "2X Luck [2H]", "2X Gold [2H]"
    }

    -- ราคาตาม duration
    local PRICE_MAP = {
        ["30M"] = 4499,
        ["1H"] = 7999,
        ["2H"] = 13999,
    }

    local function getBoostPrice(boostName)
        for duration, price in pairs(PRICE_MAP) do
            if boostName:find(duration) then
                return price
            end
        end
        return 0
    end

    -- ฟังก์ชันจัดรูปแบบตัวเลขแบบมี comma
    local function formatNumberWithComma(num)
        local formatted = tostring(num)
        local k = 0
        for i = #formatted - 2, 1, -3 do
            k = k + 1
            formatted = formatted:sub(1, i) .. "," .. formatted:sub(i + 1)
        end
        return formatted
    end

    local BOOST_MAP = {
        ["2X XP Boost [30M]"] = {type = "xp", duration = "30M", id = 1},
        ["2X XP Boost [1H]"] = {type = "xp", duration = "1H", id = 2},
        ["2X XP Boost [2H]"] = {type = "xp", duration = "2H", id = 3},
        ["2X Luck [30M]"] = {type = "luck", duration = "30M", id = 4},
        ["2X Luck [1H]"] = {type = "luck", duration = "1H", id = 5},
        ["2X Luck [2H]"] = {type = "luck", duration = "2H", id = 6},
        ["2X Gold [30M]"] = {type = "gold", duration = "30M", id = 7},
        ["2X Gold [1H]"] = {type = "gold", duration = "1H", id = 8},
        ["2X Gold [2H]"] = {type = "gold", duration = "2H", id = 9},
    }

    local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")

    local function waitForUIMenu()
        while not (Window and Window.Holder and Window.Holder.Visible) do
            task.wait(0.05)
        end
    end

    local function waitForTopbar()
        local player = game:GetService("Players").LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui", 10)
        local interface = playerGui:WaitForChild("Interface", 10)
        local topbar = interface:WaitForChild("Topbar", 10)
        return topbar
    end

    local function checkCurrencies()
        local gemsAmount = 0
        local goldAmount = 0
        pcall(function()
            local topbar = waitForTopbar()
            local main = topbar:FindFirstChild("Main")
            if main then
                local currencies = main:FindFirstChild("Currencies")
                if currencies then
                    local gemsLabel = currencies:FindFirstChild("Gems") and currencies.Gems:FindFirstChild("Amount")
                    local goldLabel = currencies:FindFirstChild("Gold") and currencies.Gold:FindFirstChild("Amount")
                    if gemsLabel and gemsLabel.Text then
                        local gemText = gemsLabel.Text:gsub("[^%d]", "")
                        gemsAmount = tonumber(gemText) or 0
                    end
                    if goldLabel and goldLabel.Text then
                        local goldText = goldLabel.Text:gsub("[^%d]", "")
                        goldAmount = tonumber(goldText) or 0
                    end
                end
            end
        end)
        return gemsAmount, goldAmount
    end

    local function startReadyCheck()
        task.spawn(function()
            waitForUIMenu()
            waitForTopbar()
            while true do
                local gemsAmount, goldAmount = checkCurrencies()
                if gemsAmount > 1 or goldAmount > 1 then
                    isReady = true
                else
                    isReady = false
                end
                task.wait(2)
            end
        end)
    end

    startReadyCheck()

    local function purchaseBoost(boostName)
        local data = BOOST_MAP[boostName]
        if not data then return false end
        if not isReady then return false end
        local args = {"S_Market", "Buy", "1_Boosts", data.id, purchaseAmount}
        return pcall(function() GET:InvokeServer(unpack(args)) end)
    end

    BoostGroup:AddDropdown("Boost_ListDropdown", {
        Text = " --- Select Boosts ---",
        Values = ALL_BOOSTS,
        Default = {},
        Multi = true,
        Callback = function() end
    })

    BoostGroup:AddSlider("Boost_AmountSlider", {
        Text = "Amount",
        Default = 1, Min = 1, Max = 50, Rounding = 0,
        Callback = function(v) purchaseAmount = v end
    })

    BoostGroup:AddSlider("Boost_DelaySlider", {
        Text = "Purchase Delay (seconds)",
        Default = 0, Min = 0, Max = 60, Rounding = 0,
        Callback = function(v) purchaseDelay = v end
    })

    BoostGroup:AddToggle("Boost_PurchaseToggle", {
        Text = "Purchase",
        Default = false,
        Callback = function(v)
            if not v then return end

            local waited = 0
            while not (Window and Window.Holder and Window.Holder.Visible) and waited < 1 do
                task.wait(0.05)
                waited = waited + 0.05
            end
            task.wait(0.1)

            if not isReady then
                pcall(function()
                    if Options and Options.Boost_PurchaseToggle then
                        Options.Boost_PurchaseToggle:SetValue(false)
                    end
                end)
                return
            end

            task.spawn(function()
                local purchaseSelection = {}
                pcall(function()
                    if Options and Options.Boost_ListDropdown and Options.Boost_ListDropdown.Value then
                        purchaseSelection = Options.Boost_ListDropdown.Value
                    end
                end)

                local selectedNames = {}
                for boostName, enabled in pairs(purchaseSelection) do
                    if enabled then
                        table.insert(selectedNames, boostName)
                    end
                end

                if #selectedNames == 0 then
                    pcall(function()
                        if Options and Options.Boost_PurchaseToggle then
                            Options.Boost_PurchaseToggle:SetValue(false)
                        end
                    end)
                    return
                end

                for boostName, enabled in pairs(purchaseSelection) do
                    if enabled then
                        if not isReady then break end
                        purchaseBoost(boostName)
                        if purchaseDelay > 0 then task.wait(purchaseDelay) else task.wait(0.15) end
                    end
                end

                pcall(function()
                    if Options and Options.Boost_PurchaseToggle then
                        Options.Boost_PurchaseToggle:SetValue(false)
                    end
                end)
            end)
        end
    })

    local goldBoosts = {
        "2x Gold Boost [2h]",
        "2x Gold Boost [1h]",
        "2x Gold Boost [30m]",
        "2x Gold Boost [15m]",
        "2x Gold Boost [5m]"
    }

    local luckBoosts = {
        "2x Luck Boost [2h]",
        "2x Luck Boost [1h]",
        "2x Luck Boost [30m]",
        "2x Luck Boost [15m]",
        "2x Luck Boost [5m]"
    }

    local xpBoosts = {
        "2x XP Boost [2h]",
        "2x XP Boost [1h]",
        "2x XP Boost [30m]",
        "2x XP Boost [15m]",
        "2x XP Boost [5m]"
    }

    local function useBoost(boostName)
        local args = {"S_Inventory", "Item", boostName}
        return pcall(function() GET:InvokeServer(unpack(args)) end)
    end

    BoostGroup:AddToggle("Boost_AutoUseToggle", {
        Text = "Auto Use All Boosts",
        Default = false,
        Callback = function(v)
            if not v then return end

            local waited = 0
            while not (Window and Window.Holder and Window.Holder.Visible) and waited < 1 do
                task.wait(0.05)
                waited = waited + 0.05
            end
            task.wait(0.1)

            if not isReady then
                pcall(function()
                    if Options and Options.Boost_AutoUseToggle then
                        Options.Boost_AutoUseToggle:SetValue(false)
                    end
                end)
                return
            end

            task.spawn(function()
                for i = 1, 5 do
                    if not isReady then break end
                    if goldBoosts[i] then useBoost(goldBoosts[i]) end
                    task.wait(0.01)
                    if not isReady then break end
                    if luckBoosts[i] then useBoost(luckBoosts[i]) end
                    task.wait(0.01)
                    if not isReady then break end
                    if xpBoosts[i] then useBoost(xpBoosts[i]) end
                    task.wait(0.01)
                end

                pcall(function()
                    if Options and Options.Boost_AutoUseToggle then
                        Options.Boost_AutoUseToggle:SetValue(false)
                    end
                end)
            end)
        end
    })

end
-- ============================== PRESTIGE (PER-STEP GOLD REQUIREMENTS WITH CUSTOM MIN/MAX, FORCE ONLY CURRENT STEP) ==============================
if IsLobbyLobby() then
    local PrestigeGroup = Tabs.Session:AddRightGroupbox("Prestige")

    -- ตัวแปร global
    getgenv().PrestigeEnabled = false
    getgenv().SelectedBoost = "Gold Boost"
    getgenv().ForceGoldRequirement = false

    -- ค่าเริ่มต้น Gold requirements (หน่วยเป็นล้าน) ตามที่กำหนด: max ของแต่ละขั้น
    local DEFAULT_GOLD_REQUIREMENTS_M = {200, 400, 600, 800, 1000}
    getgenv().PrestigeGoldRequirement = {200, 400, 600, 800, 1000}
    
    -- กำหนดช่วง min/max สำหรับแต่ละ slider (max = ค่า requirement, min = 0)
    local SLIDER_RANGES = {
        {min = 0,   max = 200},   -- 0 → 1
        {min = 0,   max = 400},   -- 1 → 2
        {min = 0,   max = 600},   -- 2 → 3
        {min = 0,   max = 800},   -- 3 → 4
        {min = 0,   max = 1000},  -- 4 → 5
    }
    
    -- สร้างฟังก์ชัน sync ค่าเริ่มต้นจาก Options
    local function syncFromOptions()
        if Options then
            for i = 1, 5 do
                local optName = "GoldReq_"..(i-1).."to"..i
                if Options[optName] and Options[optName].Value ~= nil then
                    getgenv().PrestigeGoldRequirement[i] = Options[optName].Value
                else
                    getgenv().PrestigeGoldRequirement[i] = DEFAULT_GOLD_REQUIREMENTS_M[i]
                end
            end
            if Options.BoostDropdown and Options.BoostDropdown.Value then
                getgenv().SelectedBoost = Options.BoostDropdown.Value
            end
            if Options.ForceGoldToggle ~= nil then
                getgenv().ForceGoldRequirement = Options.ForceGoldToggle.Value or false
            end
            if Options.PrestigeToggle ~= nil then
                getgenv().PrestigeEnabled = Options.PrestigeToggle.Value or false
            end
        end
    end

    syncFromOptions()

    -- Max Level per Prestige step
    local MAX_LEVEL_FOR_PRESTIGE = {100, 125, 150, 175, 200}

    -- Talents list
    local AllTalents = {
        "Crescendo", "Blitzblade", "Swiftshot", "Surgeshot",
        "Stalwart", "Stormcharged",
        "Quakestrike", "Furyforge", "Assassin", "Amputation", "Marksman",
        "Overslash", "Gambler", "Afterimages",
        "Guardian", "Deflectra",
        "Aegisurge", "Riposte",
        "Resilience", "Vengeflare", "Steel Frame",
        "Necromantic", "Thanatophobia",
        "Cooldown Blitz", "Mendmaster",
        "Lifefeed", "Vitalize", "Gem Fiend",
        "Omnirange", "Flashstep", "Tactician",
        "Bloodthief", "Apotheosis"
    }

    local RemainingTalents = {}
    local function resetTalentPool()
        RemainingTalents = {}
        for _, t in ipairs(AllTalents) do table.insert(RemainingTalents, t) end
    end
    resetTalentPool()

    local function getRandomTalent()
        if #RemainingTalents == 0 then return nil end
        local idx = math.random(1, #RemainingTalents)
        local talent = RemainingTalents[idx]
        table.remove(RemainingTalents, idx)
        return talent
    end

    local PrestigeCooldown = 0.3
    local PrestigeRunning = false

    -- ตัวแปรสำหรับจำกัดการแจ้งเตือน gold (แสดงครั้งเดียวต่อ step และต่อสถานะ gold พอ/ไม่พอ)
    local lastGoldNotifyStep = -1
    local lastGoldNotifyStatus = nil

    -- ========== Helper functions ==========
    local function getGold()
        local player = game:GetService("Players").LocalPlayer
        local gold = 0
        pcall(function()
            local topbar = player.PlayerGui.Interface.Topbar.Main.Currencies
            if topbar then
                local goldLabel = topbar.Gold and topbar.Gold:FindFirstChild("Amount")
                if goldLabel and goldLabel.Text then
                    local goldText = goldLabel.Text:gsub("[^%d]", "")
                    gold = tonumber(goldText) or 0
                end
            end
        end)
        return gold
    end

    local function getLevel()
        local player = game:GetService("Players").LocalPlayer
        local level = 0
        pcall(function()
            local levelLabel = player.PlayerGui.Interface.Gear_Up.HUD.Level.Title
            if levelLabel and levelLabel.Text then
                local levelText = levelLabel.Text:match("%d+")
                level = tonumber(levelText) or 0
            end
        end)
        return level
    end

    local function getXPPercent()
        local player = game:GetService("Players").LocalPlayer
        local percent = 0
        pcall(function()
            local xpLabel = player.PlayerGui.Interface.Gear_Up.XP.Percentage
            if xpLabel and xpLabel.Text then
                local xpText = xpLabel.Text:match("(%d+)%%")
                percent = tonumber(xpText) or 0
            end
        end)
        return percent
    end

    -- ========== UI: Sliders แต่ละตัวมี min/max และ default = ค่า max ตามขั้น ==========
    PrestigeGroup:AddSlider("GoldReq_0to1", { 
        Text = "       0 → 1  (200M)", 
        Default = getgenv().PrestigeGoldRequirement[1], 
        Min = SLIDER_RANGES[1].min, 
        Max = SLIDER_RANGES[1].max, 
        Rounding = 0, 
        Suffix = "M", 
        Callback = function(v) getgenv().PrestigeGoldRequirement[1] = math.floor(v) end 
    })
    PrestigeGroup:AddSlider("GoldReq_1to2", { 
        Text = "       1 → 2  (400M)", 
        Default = getgenv().PrestigeGoldRequirement[2], 
        Min = SLIDER_RANGES[2].min, 
        Max = SLIDER_RANGES[2].max, 
        Rounding = 0, 
        Suffix = "M", 
        Callback = function(v) getgenv().PrestigeGoldRequirement[2] = math.floor(v) end 
    })
    PrestigeGroup:AddSlider("GoldReq_2to3", { 
        Text = "       2 → 3  (600M)", 
        Default = getgenv().PrestigeGoldRequirement[3], 
        Min = SLIDER_RANGES[3].min, 
        Max = SLIDER_RANGES[3].max, 
        Rounding = 0, 
        Suffix = "M", 
        Callback = function(v) getgenv().PrestigeGoldRequirement[3] = math.floor(v) end 
    })
    PrestigeGroup:AddSlider("GoldReq_3to4", { 
        Text = "       3 → 4  (800M)", 
        Default = getgenv().PrestigeGoldRequirement[4], 
        Min = SLIDER_RANGES[4].min, 
        Max = SLIDER_RANGES[4].max, 
        Rounding = 0, 
        Suffix = "M", 
        Callback = function(v) getgenv().PrestigeGoldRequirement[4] = math.floor(v) end 
    })
    PrestigeGroup:AddSlider("GoldReq_4to5", { 
        Text = "       4 → 5  (1000M)", 
        Default = getgenv().PrestigeGoldRequirement[5], 
        Min = SLIDER_RANGES[5].min, 
        Max = SLIDER_RANGES[5].max, 
        Rounding = 0, 
        Suffix = "M", 
        Callback = function(v) getgenv().PrestigeGoldRequirement[5] = math.floor(v) end 
    })

    PrestigeGroup:AddDropdown("BoostDropdown", { 
        Values = {"Luck Boost","Exp Boost","Gold Boost"}, 
        Default = getgenv().SelectedBoost, 
        Text = "Boost", 
        Callback = function(v) getgenv().SelectedBoost = v end 
    })
    PrestigeGroup:AddSlider("PrestigeCooldownSlider", { 
        Text = "Delay", 
        Default = PrestigeCooldown, 
        Min = 0.2, 
        Max = 2, 
        Rounding = 1, 
        Suffix = "s", 
        Callback = function(v) PrestigeCooldown = v end 
    })
    PrestigeGroup:AddToggle("ForceGoldToggle", { 
        Text = "Force Gold Requirement", 
        Default = getgenv().ForceGoldRequirement, 
        Callback = function(v) 
            getgenv().ForceGoldRequirement = v
            lastGoldNotifyStep = -1
            lastGoldNotifyStatus = nil
        end 
    })
    PrestigeGroup:AddToggle("PrestigeToggle", { 
        Text = "Auto Prestige", 
        Default = getgenv().PrestigeEnabled, 
        Callback = function(v) 
            getgenv().PrestigeEnabled = v
            if not v then
                lastGoldNotifyStep = -1
                lastGoldNotifyStatus = nil
            end
        end 
    })

    -- ========== Condition & Logic ==========
    local function canPrestige(currentPrestige, currentLevel, currentXP, currentGold)
        if currentPrestige >= 5 then return false, "max" end
        local requiredLevel = MAX_LEVEL_FOR_PRESTIGE[currentPrestige + 1]
        if currentLevel < requiredLevel then return false, "level" end
        if currentXP < 100 then return false, "xp" end
        
        if getgenv().ForceGoldRequirement then
            local requiredGoldM = getgenv().PrestigeGoldRequirement[currentPrestige + 1] or 0
            local requiredGold = requiredGoldM * 1000000
            if currentGold < requiredGold then
                if lastGoldNotifyStep ~= currentPrestige or lastGoldNotifyStatus ~= false then
                    lastGoldNotifyStep = currentPrestige
                    lastGoldNotifyStatus = false
                    local needM = requiredGoldM
                    local currentM = math.floor(currentGold / 1000000)
                    Library:Notify(string.format("💰 Gold not enough for Prestige %d→%d: need %dM, have %dM", currentPrestige, currentPrestige+1, needM, currentM), 3)
                end
                return false, "gold"
            else
                if lastGoldNotifyStep ~= currentPrestige or lastGoldNotifyStatus ~= true then
                    lastGoldNotifyStep = currentPrestige
                    lastGoldNotifyStatus = true
                    Library:Notify(string.format("✅ Gold requirement met for Prestige %d→%d", currentPrestige, currentPrestige+1), 3)
                end
            end
        end
        return true, "ok"
    end

    local function doPrestige()
        if not getgenv().PrestigeEnabled then return false end

        local player = game:GetService("Players").LocalPlayer
        local currentPrestige = player:GetAttribute("Prestige") or 0
        local currentLevel = getLevel()
        local currentXP = getXPPercent()
        local currentGold = getGold()

        local can, reason = canPrestige(currentPrestige, currentLevel, currentXP, currentGold)

        if not can then
            if reason == "max" then
                if getgenv().PrestigeEnabled then
                    getgenv().PrestigeEnabled = false
                    pcall(function() if Options and Options.PrestigeToggle then Options.PrestigeToggle:SetValue(false) end end)
                end
            end
            return false
        end

        local talent = getRandomTalent()
        if not talent then
            resetTalentPool()
            talent = getRandomTalent()
            if not talent then return false end
        end

        local Event = game:GetService("ReplicatedStorage").Assets.Remotes.GET
        pcall(function() Event:InvokeServer("S_Equipment", "Talents") end)
        task.wait(0.3)
        pcall(function()
            Event:InvokeServer("S_Equipment", "Prestige", {
                Boosts = getgenv().SelectedBoost,
                Talents = talent
            })
        end)
        -- ไม่แสดง notify ความสำเร็จ
        lastGoldNotifyStep = -1
        lastGoldNotifyStatus = nil
        return true
    end

    task.spawn(function()
        while true do
            task.wait(PrestigeCooldown)
            pcall(function()
                if not getgenv().PrestigeEnabled then
                    PrestigeRunning = false
                    return
                end
                if PrestigeRunning then return end
                PrestigeRunning = true
                doPrestige()
                PrestigeRunning = false
            end)
        end
    end)
end
-- ============================== AUTO CLAIMS (FIXED READY STATUS - NO CURRENCY DISPLAY) ==============================
if IsLobbyLobby() then
    local AutoClaimGroup = Tabs.Session:AddLeftGroupbox("Auto Claims")
    
    getgenv().ClaimQuestEnabled = false
    getgenv().ClaimQuestRunning = false
    getgenv().ClaimAchievementEnabled = false
    getgenv().ClaimAchievementRunning = false
    getgenv().ClaimDelay = 0
    
    -- Label สำหรับแสดงสถานะ (ไม่แสดงจำนวน Gold/Gems)
    local statusLabel = AutoClaimGroup:AddLabel("Status: Checking...", true)
    
    -- ฟังก์ชันตรวจสอบ currencies
    local function getCurrencyValues()
        local player = game:GetService("Players").LocalPlayer
        local goldAmount = 0
        local gemsAmount = 0
        
        pcall(function()
            local topbar = player.PlayerGui.Interface.Topbar.Main.Currencies
            if topbar then
                local goldLabel = topbar.Gold and topbar.Gold:FindFirstChild("Amount")
                local gemsLabel = topbar.Gems and topbar.Gems:FindFirstChild("Amount")
                if goldLabel and goldLabel.Text then
                    local goldText = goldLabel.Text:gsub("[^%d]", "")
                    goldAmount = tonumber(goldText) or 0
                end
                if gemsLabel and gemsLabel.Text then
                    local gemsText = gemsLabel.Text:gsub("[^%d]", "")
                    gemsAmount = tonumber(gemsText) or 0
                end
            end
        end)
        return goldAmount, gemsAmount
    end
    
    local function isCurrenciesReady()
        local gold, gems = getCurrencyValues()
        return (gold > 0 or gems > 0)
    end
    
    -- อัปเดตสถานะ (แสดงแค่ Ready/Not Ready)
    task.spawn(function()
        while true do
            task.wait(1)
            pcall(function()
                local ready = isCurrenciesReady()
                if ready then
                    statusLabel:SetText("Status: Ready")
                else
                    statusLabel:SetText("Status: Not Ready (Waiting for Gold/Gems)")
                end
            end)
        end
    end)
    
    local QuestList = {
        {name="Novice Adventurer", category="Main"},{name="Seasoned Operative", category="Main"},{name="Master Of Missions", category="Main"},{name="Elite Taskmaster", category="Main"},{name="Legendary Quester", category="Main"},{name="Completionist", category="Main"},{name="Rookie Raider", category="Main"},{name="Raid Veteran", category="Main"},{name="Raid Commander", category="Main"},{name="Raid Warlord", category="Main"},{name="Raid Conqueror", category="Main"},{name="Precise Striker", category="Main"},{name="Critical Sniper", category="Main"},{name="Devastating Precision", category="Main"},{name="Critical Master", category="Main"},{name="Critical Legend", category="Main"},{name="Critical Demigod", category="Main"},{name="Novice Wrecker", category="Main"},{name="Demolition Expert", category="Main"},{name="Destruction Maestro", category="Main"},{name="Damage Dynamo", category="Main"},{name="Cataclysmic Force", category="Main"},{name="Devastation Virtuoso", category="Main"},{name="Titan Hunter", category="Main"},{name="Titan Slayer", category="Main"},{name="Titan Executioner", category="Main"},{name="Titan Butcher", category="Main"},{name="Titan Dominator", category="Main"},{name="Titan Conqueror", category="Main"},{name="Rookie Adventurer", category="Main"},{name="Seasoned Warrior", category="Main"},{name="Master Of Experience", category="Main"},{name="Legendary Ascendant", category="Main"},{name="Divine Prestige", category="Main"},{name="Ultimate Champion", category="Main"},{name="Prestige Aspirant", category="Main"},{name="Prestige Challenger", category="Main"},{name="Prestige Enthusiast", category="Main"},{name="Prestige Expert", category="Main"},
        {name="Casual Explorer", category="Side"},{name="Guardian Angel", category="Side"},{name="Penny Pincher", category="Side"},{name="Eye Of The Storm", category="Side"},{name="Shifting Apprentice", category="Side"},{name="Skill Novice", category="Side"},{name="Team Player", category="Side"},{name="Wealth Accumulator", category="Side"},{name="Rescuer Extraordinaire", category="Side"},{name="Teamwork Enthusiast", category="Side"},{name="Dedicated Adventurer", category="Side"},{name="Skill Practitioner", category="Side"},{name="Shifting Adept", category="Side"},{name="Leg Lacerator", category="Side"},{name="Treasure Hunter", category="Side"},{name="Seasoned Gamer", category="Side"},{name="Cooperative Expert", category="Side"},{name="Skill Expert", category="Side"},{name="Lifesaver Pro", category="Side"},{name="Shifting Expert", category="Side"},{name="Arm Annihilator", category="Side"},{name="Skill Master", category="Side"},{name="Titan Torturer", category="Side"},{name="Teamwork Specialist", category="Side"},{name="Fortune Hoarder", category="Side"},{name="Saving Supreme", category="Side"},{name="Endurance Champion", category="Side"},{name="Shifting Master", category="Side"},{name="Shifting Guru", category="Side"},{name="Titan Annihilator", category="Side"},{name="Teamwork Virtuoso", category="Side"},{name="Timeless Immortal", category="Side"},{name="Money Magician", category="Side"},{name="Skill Virtuoso", category="Side"},{name="Player's Champion", category="Side"},{name="Teamwork Maestro", category="Side"},{name="Skill Prodigy", category="Side"},{name="Legendary Superior", category="Side"},{name="Titan's Nightmare", category="Side"},{name="Ultimate Protector", category="Side"},{name="Ultimate Victor", category="Side"},{name="Shifting Virtuoso", category="Side"},
        {name="Daily 1", category="Daily"},{name="Daily 2", category="Daily"},{name="Daily 3", category="Daily"},
        {name="Weekly 1", category="Weekly"},{name="Weekly 2", category="Weekly"},{name="Weekly 3", category="Weekly"},{name="Weekly 4", category="Weekly"},
        {name="Towers", category="Spears"},{name="Escort", category="Spears"},{name="Ice Burst Stones", category="Spears"},{name="Retrieve Missing Supplies", category="Spears"},{name="Defend Missing Supplies", category="Spears"}
    }
    
    -- ฟังก์ชันรอ Currency (ใช้ path เดียวกับที่ใช้ตรวจสอบ)
    local function waitForCurrency()
        while not (Window and Window.Holder and Window.Holder.Visible) do
            task.wait(0.1)
        end
        
        local gold, gems = 0, 0
        repeat
            task.wait(0.1)
            gold, gems = getCurrencyValues()
        until gold > 0 or gems > 0
    end
    
    local function claimAllQuests()
        while getgenv().ClaimQuestEnabled do
            for i, quest in ipairs(QuestList) do
                if not getgenv().ClaimQuestEnabled then break end
                pcall(function() SafeInvoke(GET, "Functions", "Quest", quest.name, quest.category) end)
                task.wait(0.1 + math.random()*0.03 + getgenv().ClaimDelay)
            end
        end
        getgenv().ClaimQuestRunning = false
    end
    
    local function claimAllAchievements()
        for id = 1, 71 do
            if not getgenv().ClaimAchievementEnabled then break end
            pcall(function() SafeInvoke(GET, "S_Achievements", "Claim", id) end)
            task.wait(0.1 + math.random()*0.03 + getgenv().ClaimDelay)
        end
        getgenv().ClaimAchievementEnabled = false
        getgenv().ClaimAchievementRunning = false
        pcall(function()
            if Options and Options.ClaimAchievementToggle then
                Options.ClaimAchievementToggle:SetValue(false)
            end
        end)
    end
    
    AutoClaimGroup:AddToggle("ClaimQuestToggle", {
        Text = "Claim Quest",
        Default = false,
        Callback = function(v)
            getgenv().ClaimQuestEnabled = v
            if v and not getgenv().ClaimQuestRunning then
                task.spawn(function()
                    task.wait(2)
                    waitForCurrency()
                    getgenv().ClaimQuestRunning = true
                    claimAllQuests()
                end)
            end
        end
    })
    
    AutoClaimGroup:AddToggle("ClaimAchievementToggle", {
        Text = "Claim Achievement",
        Default = false,
        Callback = function(v)
            getgenv().ClaimAchievementEnabled = v
            if v and not getgenv().ClaimAchievementRunning then
                task.spawn(function()
                    task.wait(2)
                    waitForCurrency()
                    getgenv().ClaimAchievementRunning = true
                    claimAllAchievements()
                end)
            end
        end
    })
    
    AutoClaimGroup:AddSlider("ClaimDelaySlider", {
        Text = "Claim Delay (sec)",
        Default = 0,
        Min = 0,
        Max = 60,
        Rounding = 1,
        Compact = false,
        Callback = function(v)
            getgenv().ClaimDelay = v
        end
    })
end
-- ============================== WEAPON GATE SYSTEM ==============================
do
    local DETECTED_WEAPON = "Unknown"
    local detectionComplete = false
    
    task.spawn(function()
        while not detectionComplete do
            local success, weapon = pcall(function()
                local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
                local data = GET:InvokeServer("Data", "Copy")
                local slot = data.Current_Slot or "A"
                return data.Slots[slot].Weapon or "Unknown"
            end)
            
            if success and weapon and weapon ~= "Unknown" then
                DETECTED_WEAPON = weapon
                
                local weaponLower = string.lower(tostring(weapon))
                
                if weaponLower:find("blade") or weaponLower:find("aottg") then
                    DETECTED_WEAPON = "Blade"
                elseif weaponLower:find("spear") or weaponLower:find("thunder") then
                    DETECTED_WEAPON = "Thunder Spear"
                end
                
                detectionComplete = true
            else
                task.wait(1)
            end
        end
    end)
    
    getgenv().GetDetectedWeapon = function()
        return DETECTED_WEAPON
    end
end

-- ============================== MISC (เฉพาะในเกม) ==============================
if IsIngameLobby() and Tabs.AutoFarm then
    local MiscGroup = Tabs.AutoFarm:AddLeftGroupbox("Misc")

    -- ============================== PLAYER STATS (JESTER THEME - UNIFIED BORDER) ==============================
    local StatsGui = nil
    local StatsEnabled = false
    local scaleFactor = 1

    local JESTER = {
        Background = Color3.fromHex("1c1c1c"),
        Accent = Color3.fromHex("db4467"),
        Font = Color3.fromHex("ffffff"),
        Outline = Color3.fromHex("373737")
    }

    -- ตัวแปร global สำหรับ Farm Timer (เริ่มนับอัตโนมัติเมื่อเห็น STATUS ON)
    getgenv().FarmTimerStarted = getgenv().FarmTimerStarted or false
    getgenv().FarmStartTime = getgenv().FarmStartTime or nil
    getgenv().FarmLastOnTime = getgenv().FarmLastOnTime or 0   -- เวลาล่าสุดที่ STATUS ON

    -- ฟังก์ชันรีเซ็ต timer (เมื่อ OFF นานเกินไป)
    local function resetFarmTimer()
        if getgenv().FarmTimerStarted then
            getgenv().FarmTimerStarted = false
            getgenv().FarmStartTime = nil
            getgenv().FarmLastOnTime = 0
        end
    end

    -- ฟังก์ชันตรวจสอบว่า GUI ปรากฏจริงหรือไม่
    local function IsActuallyVisible(gui)
        if not gui or not gui:IsA("GuiObject") then return false end
        if not gui.Visible then return false end
        local current = gui.Parent
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return true
    end

    -- ฟังก์ชันตรวจสอบว่า UI Objectives ปรากฏหรือไม่ (ใช้แสดงสถานะ ON/OFF)
    local function isObjectivesVisible()
        local player = game:GetService("Players").LocalPlayer
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return false end
        for _, v in ipairs(playerGui:GetDescendants()) do
            if v.Name == "Objectives" and IsActuallyVisible(v) then
                return true
            end
        end
        return false
    end

    -- ========== ระบบยืนยัน STATUS ON ก่อนเริ่มนับ (เช็ค 10 ครั้งใน 2 วินาที) ==========
    local function waitForStableOn()
        local onCount = 0
        local startTime = tick()
        local maxDuration = 2
        local requiredCount = 10
        while tick() - startTime < maxDuration do
            if isObjectivesVisible() then
                onCount = onCount + 1
            else
                onCount = 0
            end
            if onCount >= requiredCount then
                return true
            end
            task.wait(0.05)
        end
        return false
    end

    -- ฟังก์ชันเริ่มนับ (ทำงานอัตโนมัติ ไม่ขึ้นกับ StatsEnabled)
    local function startFarmTimerIfNeeded()
        if getgenv().FarmTimerStarted then return end
        if waitForStableOn() then
            getgenv().FarmTimerStarted = true
            getgenv().FarmStartTime = tick()
            getgenv().FarmLastOnTime = tick()
        end
    end

    -- ฟังก์ชันสำหรับ UI ที่เรียกใช้เพื่อเอา elapsed time
    local function getFarmElapsedTime()
        if getgenv().FarmTimerStarted and getgenv().FarmStartTime then
            return tick() - getgenv().FarmStartTime
        else
            return 0
        end
    end

    -- ========== BACKGROUND TIMER MANAGER (รันตลอดเวลา) ==========
    task.spawn(function()
        while true do
            -- ตรวจสอบและเริ่มนับถ้ายังไม่ได้เริ่ม
            startFarmTimerIfNeeded()

            -- ตรวจสอบว่า OFF นานเกิน 3 วินาทีหรือไม่ ถ้าใช่ให้รีเซ็ต timer
            if getgenv().FarmTimerStarted then
                if not isObjectivesVisible() then
                    local offDuration = tick() - (getgenv().FarmLastOnTime > 0 and getgenv().FarmLastOnTime or tick())
                    if offDuration > 3 then
                        resetFarmTimer()
                    end
                else
                    -- อัปเดตเวลาล่าสุดที่ ON
                    getgenv().FarmLastOnTime = tick()
                end
            end

            task.wait(0.5)
        end
    end)

    -- เพิ่ม Slider สำหรับปรับขนาด UI (Scale)
    MiscGroup:AddSlider("UIScaleSlider", {
        Text = "UI Scale (%)",
        Default = 100,
        Min = 50,
        Max = 200,
        Rounding = 0,
        Suffix = "%",
        Callback = function(v)
            scaleFactor = v / 100
            if StatsEnabled and StatsGui then
                local scaleObj = StatsGui:FindFirstChild("UIScale")
                if scaleObj then
                    scaleObj.Scale = scaleFactor
                end
            end
        end
    })

    local function CreatePlayerStatsHUD()
        if StatsGui then
            StatsGui:Destroy()
            StatsGui = nil
        end

        local Players = game:GetService("Players")
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

        local Gui = Instance.new("ScreenGui")
        Gui.Name = "FakeHubPlayerStats"
        Gui.IgnoreGuiInset = true
        Gui.ResetOnSpawn = false
        Gui.Parent = PlayerGui
        StatsGui = Gui

        local uiScale = Instance.new("UIScale")
        uiScale.Scale = scaleFactor
        uiScale.Parent = Gui

        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0, 520, 0, 116)
        Frame.Position = UDim2.new(0.5, -260, 0, 12)
        Frame.BackgroundColor3 = JESTER.Background
        Frame.BackgroundTransparency = 0.05
        Frame.BorderSizePixel = 0
        Frame.Parent = Gui

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 10)
        Corner.Parent = Frame

        local Gradient = Instance.new("UIGradient")
        Gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, JESTER.Background),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 22, 22))
        })
        Gradient.Rotation = 90
        Gradient.Parent = Frame

        local Stroke = Instance.new("UIStroke")
        Stroke.Color = JESTER.Accent
        Stroke.Thickness = 1.2
        Stroke.Transparency = 0.55
        Stroke.Parent = Frame

        -- Timer UI
        local TimerTitle = Instance.new("TextLabel")
        TimerTitle.Size = UDim2.new(0, 170, 0, 20)
        TimerTitle.Position = UDim2.new(0, 14, 0, 10)
        TimerTitle.BackgroundTransparency = 1
        TimerTitle.Text = "FARM TIMER"
        TimerTitle.Font = Enum.Font.GothamSemibold
        TimerTitle.TextSize = 12
        TimerTitle.TextColor3 = JESTER.Font
        TimerTitle.TextXAlignment = Enum.TextXAlignment.Left
        TimerTitle.Parent = Frame

        local TimerValue = Instance.new("TextLabel")
        TimerValue.Size = UDim2.new(0, 200, 0, 42)
        TimerValue.Position = UDim2.new(0, 14, 0, 32)
        TimerValue.BackgroundTransparency = 1
        TimerValue.Text = "00:00:00"
        TimerValue.Font = Enum.Font.GothamBold
        TimerValue.TextSize = 34
        TimerValue.TextColor3 = JESTER.Font
        TimerValue.TextXAlignment = Enum.TextXAlignment.Left
        TimerValue.Parent = Frame

        local StatusTitle = Instance.new("TextLabel")
        StatusTitle.Size = UDim2.new(0, 170, 0, 16)
        StatusTitle.Position = UDim2.new(0, 14, 0, 80)
        StatusTitle.BackgroundTransparency = 1
        StatusTitle.Text = "STATUS:"
        StatusTitle.Font = Enum.Font.GothamMedium
        StatusTitle.TextSize = 10
        StatusTitle.TextColor3 = JESTER.Font
        StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
        StatusTitle.Parent = Frame

        local StatusValue = Instance.new("TextLabel")
        StatusValue.Size = UDim2.new(0, 150, 0, 16)
        StatusValue.Position = UDim2.new(0, 65, 0, 80)
        StatusValue.BackgroundTransparency = 1
        StatusValue.Text = "OFF"
        StatusValue.Font = Enum.Font.GothamBold
        StatusValue.TextSize = 11
        StatusValue.TextColor3 = Color3.fromRGB(255, 100, 100)
        StatusValue.TextXAlignment = Enum.TextXAlignment.Left
        StatusValue.Parent = Frame

        local Divider = Instance.new("Frame")
        Divider.Size = UDim2.new(0, 1, 0, 90)
        Divider.Position = UDim2.new(0.5, -1, 0, 13)
        Divider.BackgroundColor3 = JESTER.Accent
        Divider.BackgroundTransparency = 0.65
        Divider.BorderSizePixel = 0
        Divider.Parent = Frame

        local StatsContainer = Instance.new("Frame")
        StatsContainer.Size = UDim2.new(0, 230, 0, 72)
        StatsContainer.Position = UDim2.new(1, -245, 0, 12)
        StatsContainer.BackgroundTransparency = 1
        StatsContainer.Parent = Frame

        local StatsTitle = Instance.new("TextLabel")
        StatsTitle.Size = UDim2.new(1, 0, 0, 20)
        StatsTitle.Position = UDim2.new(0, 0, 0, 0)
        StatsTitle.BackgroundTransparency = 1
        StatsTitle.Text = "PLAYER STATS"
        StatsTitle.Font = Enum.Font.GothamSemibold
        StatsTitle.TextSize = 12
        StatsTitle.TextColor3 = JESTER.Font
        StatsTitle.TextXAlignment = Enum.TextXAlignment.Right
        StatsTitle.Parent = StatsContainer

        local function MakeStatRow(name, xPos, yPos)
            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(0, 105, 0, 18)
            Holder.Position = UDim2.new(0, xPos, 0, yPos)
            Holder.BackgroundTransparency = 1
            Holder.Parent = StatsContainer

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0, 45, 1, 0)
            Label.Position = UDim2.new(0, 0, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = name
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 11
            Label.TextColor3 = JESTER.Font
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Holder

            local Value = Instance.new("TextLabel")
            Value.Size = UDim2.new(0, 60, 1, 0)
            Value.Position = UDim2.new(0, 45, 0, 0)
            Value.BackgroundTransparency = 1
            Value.Text = "0"
            Value.Font = Enum.Font.GothamBold
            Value.TextSize = 13
            Value.TextColor3 = JESTER.Accent
            Value.TextXAlignment = Enum.TextXAlignment.Left
            Value.Parent = Holder

            return Value
        end

        local LevelVal = MakeStatRow("Level", 0, 28)
        local GemsVal  = MakeStatRow("Gems", 120, 28)
        local GoldVal  = MakeStatRow("Gold", 0, 52)
        -- Canes removed

        local function FormatTime(sec)
            return string.format("%02d:%02d:%02d",
                math.floor(sec / 3600),
                math.floor((sec % 3600) / 60),
                math.floor(sec % 60))
        end

        -- Loop อัปเดต UI Stats และ Timer (เฉพาะเมื่อ StatsEnabled=true)
        task.spawn(function()
            while StatsEnabled and Gui.Parent do
                task.wait(0.3)
                
                local objectivesVisible = isObjectivesVisible()
                local elapsed = getFarmElapsedTime()
                TimerValue.Text = FormatTime(elapsed)
                
                if objectivesVisible then
                    StatusValue.Text = "ON"
                    StatusValue.TextColor3 = Color3.fromRGB(0, 255, 0)
                else
                    StatusValue.Text = "OFF"
                    StatusValue.TextColor3 = Color3.fromRGB(255, 100, 100)
                end
            end
        end)

        local function FormatNumber(num)
            if num >= 1e6 then
                return string.format("%.2fM", num / 1e6)
            elseif num >= 1e3 then
                return string.format("%.1fK", num / 1e3)
            else
                return tostring(num)
            end
        end

        local function UpdateStats(data)
            pcall(function()
                if data and data.Slots then
                    local slot = data.Current_Slot or "A"
                    local slotData = data.Slots[slot]

                    if slotData then
                        if slotData.Progression and slotData.Progression.Level then
                            LevelVal.Text = tostring(slotData.Progression.Level)
                        end

                        if slotData.Currency then
                            if slotData.Currency.Gold then
                                GoldVal.Text = FormatNumber(slotData.Currency.Gold)
                            end
                            if slotData.Currency.Gems then
                                GemsVal.Text = FormatNumber(slotData.Currency.Gems)
                            end
                            -- Canes removed
                        end
                    end
                end
            end)
        end

        local function FetchAndUpdate()
            task.spawn(function()
                pcall(function()
                    local remoteGET = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
                    local data = remoteGET:InvokeServer("Data", "Copy", LocalPlayer.UserId)
                    if data and type(data) == "table" then
                        UpdateStats(data)
                    end
                end)
            end)
        end

        task.spawn(function()
            while StatsEnabled and Gui.Parent do
                task.wait(5)
                FetchAndUpdate()
            end
        end)

        FetchAndUpdate()
    end

    MiscGroup:AddToggle("PlayerStatsToggle", {
        Text = "Player Stats",
        Default = false,
        Callback = function(v)
            StatsEnabled = v
            if v then
                CreatePlayerStatsHUD()
            else
                if StatsGui then
                    StatsGui:Destroy()
                    StatsGui = nil
                end
            end
        end
    })

    -- ============================== QUALITY CONTROL ==============================
    MiscGroup:AddDropdown("RenderModeDropdown", {
        Text = "FPS Performance",
        Values = {"Low Graphic", "Delete Map", "Disable 3D Render", "Disable Text DMG"},
        Default = {},
        Multi = true,
        Callback = function(v)
            -- จัดการ Low Graphic
            if v["Low Graphic"] then
                pcall(function()
                    game:GetService("Lighting").Brightness = 0
                    game:GetService("Lighting").GlobalShadows = false
                    game:GetService("Lighting").FogEnd = 0
                    settings().Rendering.QualityLevel = 1
                    game:GetService("Workspace").TintColor = Color3.new(0, 0, 0)
                    if sethiddenproperty then
                        sethiddenproperty(game:GetService("Workspace"), "Terrain", nil)
                    end
                end)
            else
                pcall(function()
                    game:GetService("Lighting").Brightness = 1
                    game:GetService("Lighting").GlobalShadows = true
                    game:GetService("Lighting").FogEnd = 100000
                    settings().Rendering.QualityLevel = 21
                    game:GetService("Workspace").TintColor = Color3.new(1, 1, 1)
                end)
            end

            -- จัดการ Delete Map
            if v["Delete Map"] then
                local climbable = workspace:FindFirstChild("Climbable")
                local unclimbable = workspace:FindFirstChild("Unclimbable")
                if climbable or unclimbable then
                    if climbable then
                        for _, child in ipairs(climbable:GetChildren()) do
                            pcall(function() child:Destroy() end)
                        end
                    end
                    if unclimbable then
                        local preserve = {Reloads = true, Objective = true, Cutscene = true}
                        for _, child in ipairs(unclimbable:GetChildren()) do
                            if not preserve[child.Name] then
                                pcall(function() child:Destroy() end)
                            end
                        end
                    end
                end
            end

            -- จัดการ Disable 3D Render (พร้อมปรับ Material และ Quality Level)
            if v["Disable 3D Render"] then
                pcall(function()
                    game:GetService("RunService"):Set3dRenderingEnabled(false)
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                    for _, part in ipairs(workspace:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Material = Enum.Material.Plastic
                            part.Reflectance = 0
                        end
                    end
                end)
            else
                pcall(function()
                    game:GetService("RunService"):Set3dRenderingEnabled(true)
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
                end)
            end

            -- จัดการ Disable Text DMG
            if v["Disable Text DMG"] then
                for i = 1, 5 do
                    pcall(function()
                        local args = {
                            "Functions",
                            "Settings",
                            "Damage_Indicator",
                            "Off"
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET"):InvokeServer(unpack(args))
                    end)
                    task.wait(0.1)
                end
            else
                for i = 1, 5 do
                    pcall(function()
                        local args = {
                            "Functions",
                            "Settings",
                            "Damage_Indicator",
                            "On"
                        }
                        game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET"):InvokeServer(unpack(args))
                    end)
                    task.wait(0.1)
                end
            end
        end
    })

    -- ============================== FPS LIMITER (SLIDER) ==============================
    MiscGroup:AddSlider("FPSLimitSlider", {
        Text = "Set FPS",
        Default = 60,
        Min = 5,
        Max = 120,
        Rounding = 0,
        Suffix = " FPS",
        Callback = function(v)
            pcall(function()
                if setfpscap then
                    setfpscap(v)
                else
                    local fpsCap = syn and syn.set_fps_cap or (setfpscap and setfpscap)
                    if fpsCap then
                        fpsCap(v)
                    end
                end
            end)
        end
    })
end

-- ============================== SAFETY SLIDER ==============================
if Tabs.AutoFarm then
    local SafetyGroup = Tabs.AutoFarm:AddRightGroupbox("Safety Settings")
    SafetyGroup:AddLabel(" -- 60s is safe! --")
    SafetyGroup:AddSlider("SafetyTimeSlider", {
        Text="--- End Missions ---", Default=60, Min=0, Max=60, Rounding=0,
        Callback=function(val)
            getgenv().SafetyTime = math.floor(val)
        end,
        Drag = true
    })
    
    getgenv().StopAtTitansLeft = getgenv().StopAtTitansLeft or 10
    
    SafetyGroup:AddSlider("StopAtTitansLeftSlider", {
        Text="⚠️ Stop attacking when ≤ X titans left (before safe time)",
        Default = getgenv().StopAtTitansLeft,
        Min = 10,
        Max = 15,
        Rounding = 0,
        Callback = function(val)
            getgenv().StopAtTitansLeft = math.floor(val)
        end
    })
end
-- ============================== AUTO FARM TAB (SMART WEAPON DETECT) ==============================
local PendingFarmStart = false

-- ฟังก์ชันตรวจสอบ UI Objectives สำหรับควบคุมการเริ่มฟาร์ม
local function isObjectivesVisibleForFarm()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local function IsActuallyVisible(gui)
        if not gui or not gui:IsA("GuiObject") then return false end
        if not gui.Visible then return false end
        local current = gui.Parent
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return true
    end
    
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v.Name == "Objectives" then
            if IsActuallyVisible(v) then
                return true
            end
        end
    end
    return false
end

-- ตัวแปรเก็บสถานะ Objectives สำหรับควบคุม Farm
local farmObjectivesReady = false
local lastObjectivesCheck = 0

local function updateFarmObjectivesStatus()
    if tick() - lastObjectivesCheck >= 0.5 then
        lastObjectivesCheck = tick()
        farmObjectivesReady = isObjectivesVisibleForFarm()
    end
    return farmObjectivesReady
end

if Tabs.AutoFarm then
    local AutoFarmTabbox = Tabs.AutoFarm:AddLeftTabbox("Auto Farm")
    local G = getgenv()

    G.Farm = false
    G.AutoFarmBlade = false
    G.AutoReloadBlade = false
    G.AutoThunderSpear = false
    G.StartRejoin = false
    G.FarmMode = nil
    G.HoverSpeed = 120
    G.HoverHeight = 120
    G.SafetyTime = G.SafetyTime or 60
    G.LeaveMinimum = 1
    G.AttackInterval = 0.15
    
    G.ThunderSpearFarmMode = "Tween"
    G.ThunderSpearHoverSpeed = 120
    G.ThunderSpearHoverHeight = 120
    G.ThunderSpearFirePower = 8
    G.ThunderSpearExplodeRadius = 0.13

    local function getCurrentWeapon()
        return G.GetDetectedWeapon and G.GetDetectedWeapon() or "Unknown"
    end
    
    local function isBlade()
        return getCurrentWeapon() == "Blade"
    end
    
    local function isThunderSpear()
        return getCurrentWeapon() == "Thunder Spear"
    end

    local function resolveConflictingToggles()
        if G.AutoFarmBlade and G.AutoThunderSpear then
            if isBlade() then
                G.AutoThunderSpear = false
                pcall(function()
                    if Options and Options.AutoThunderSpearToggle then
                        Options.AutoThunderSpearToggle:SetValue(false)
                    end
                end)
            elseif isThunderSpear() then
                G.AutoFarmBlade = false
                G.Farm = false
                PendingFarmStart = false
                pcall(function()
                    if Options and Options.AutoFarmBlade then
                        Options.AutoFarmBlade:SetValue(false)
                    end
                end)
            else
                G.AutoFarmBlade = false
                G.AutoThunderSpear = false
                G.Farm = false
                PendingFarmStart = false
                pcall(function()
                    if Options and Options.AutoFarmBlade then
                        Options.AutoFarmBlade:SetValue(false)
                    end
                    if Options and Options.AutoThunderSpearToggle then
                        Options.AutoThunderSpearToggle:SetValue(false)
                    end
                end)
            end
        end
    end

    local function waitForUI()
        local waited = 0
        while not (Window and Window.Holder and Window.Holder.Visible) and waited < 1 do
            task.wait(0.05)
            waited = waited + 0.05
        end
    end

    local BladeTab = AutoFarmTabbox:AddTab("Blade")

    BladeTab:AddDropdown("FarmModeDropdown", {
        Values = {"Tween","Teleport"}, 
        Default = "",
        Multi = false, 
        Text = "Farm Select",
        Callback = function(val)
            G.FarmMode = val
            if PendingFarmStart and G.AutoFarmBlade and (G.FarmMode == "Tween" or G.FarmMode == "Teleport") then
                if updateFarmObjectivesStatus() then
                    G.Farm = true
                    PendingFarmStart = false
                end
            end
        end
    })

    BladeTab:AddSlider("HoverSpeedSlider", {
        Text="Hover Speed", Default=G.HoverSpeed, Min=50, Max=1000, Rounding=0,
        Callback=function(val) G.HoverSpeed = val end
    })
    
    BladeTab:AddSlider("HoverHeightSlider", {
        Text="Hover Height", Default=G.HoverHeight, Min=0, Max=400, Rounding=0,
        Callback=function(val) G.HoverHeight = val end
    })

    BladeTab:AddToggle("AutoFarmBlade", {
        Text="Auto Farm Blade", Default=false,
        Callback=function(v)
            -- รอ 1 วินาทีเมื่อเปิด toggle ครั้งแรก
            if v then task.wait(1) end
            waitForUI()
            if v then
                if G.AutoThunderSpear then
                    if isThunderSpear() then
                        task.wait(0.05)
                        pcall(function()
                            if Options and Options.AutoThunderSpearToggle then
                                Options.AutoThunderSpearToggle:SetValue(false)
                            end
                        end)
                        return
                    else
                        G.AutoThunderSpear = false
                        pcall(function()
                            if Options and Options.AutoThunderSpearToggle then
                                Options.AutoThunderSpearToggle:SetValue(false)
                            end
                        end)
                    end
                end
                
                if not G.FarmMode or (G.FarmMode ~= "Tween" and G.FarmMode ~= "Teleport") then
                    Library:Notify("⚠️ Please select Farm Mode (Tween/Teleport) first!", 3)
                    pcall(function()
                        if Options and Options.AutoFarmBlade then
                            Options.AutoFarmBlade:SetValue(false)
                        end
                    end)
                    return
                end
                
                G.AutoFarmBlade = true
                if updateFarmObjectivesStatus() then
                    G.Farm = true
                else
                    G.Farm = false
                end
                PendingFarmStart = false
            else
                G.AutoFarmBlade = false
                G.Farm = false
                PendingFarmStart = false
                -- หยุดการเคลื่อนที่ทั้งหมด
                CleanupSmoothMovement()
                CurrentEntry = nil
            end
        end
    })

    BladeTab:AddToggle("AutoReloadBlade", {
        Text="Auto Reload Blade", Default=false,
        Callback=function(v) 
            if v then task.wait(1) end
            G.AutoReloadBlade = v
            if not v then
                getgenv().IsReloading = false
                getgenv().IsRefilling = false
                reloadInProgress = false
                refillInProgress = false
                refillStage = 0
            end
        end
    })
    
    BladeTab:AddToggle("StartRejoin", {
        Text="Auto Retry", Default=false,
        Callback=function(v) 
            if v then task.wait(1) end
            G.StartRejoin = v 
        end
    })
    


    local SpearTab = AutoFarmTabbox:AddTab("Thunder Spear")
    
    SpearTab:AddToggle("AutoThunderSpearToggle", {
        Text = "Auto Thunder Spear",
        Default = false,
        Callback = function(v)
            if v then task.wait(1) end
            waitForUI()
            if v then
                if G.AutoFarmBlade then
                    if isBlade() then
                        task.wait(0.05)
                        pcall(function()
                            if Options and Options.AutoThunderSpearToggle then
                                Options.AutoThunderSpearToggle:SetValue(false)
                            end
                        end)
                        return
                    else
                        G.AutoFarmBlade = false
                        G.Farm = false
                        PendingFarmStart = false
                        pcall(function()
                            if Options and Options.AutoFarmBlade then
                                Options.AutoFarmBlade:SetValue(false)
                            end
                        end)
                    end
                end
                
                G.AutoThunderSpear = true
            else
                G.AutoThunderSpear = false
            end
        end
    })
    
    SpearTab:AddDivider()
    
    SpearTab:AddDropdown("ThunderSpear_FarmMode", {
        Values = {"Tween","Teleport"},
        Default = "Tween",
        Multi = false,
        Text = "Farm Mode",
        Callback = function(v) G.ThunderSpearFarmMode = v end
    })
    
    SpearTab:AddSlider("ThunderSpear_HoverSpeed", {
        Text="Hover Speed", Default=120, Min=50, Max=1000, Rounding=0,
        Callback=function(v) G.ThunderSpearHoverSpeed = v end
    })
    
    SpearTab:AddSlider("ThunderSpear_HoverHeight", {
        Text="Hover Height", Default=120, Min=0, Max=400, Rounding=0,
        Callback=function(v) G.ThunderSpearHoverHeight = v end
    })

    task.spawn(function()
        while true do
            task.wait(0.5)
            pcall(function()
                resolveConflictingToggles()
                -- เช็คว่า AutoFarmBlade เปิดอยู่มั้ย ถ้าปิดอย่าทำอะไร
                if G.AutoFarmBlade and not G.Farm and not PendingFarmStart then
                    if updateFarmObjectivesStatus() and G.FarmMode and (G.FarmMode == "Tween" or G.FarmMode == "Teleport") then
                        G.Farm = true
                    end
                end
            end)
        end
    end)

    local TeleportGroup = Tabs.AutoFarm:AddRightGroupbox("Teleport Now")
    local tpLabel = TeleportGroup:AddLabel("")
    local function AddConfirmTP(name, id, time)
        local c = false
        TeleportGroup:AddButton(name, function()
            if c then
                pcall(function() TeleportService:Teleport(id, Player) end)
            else
                c = true
                tpLabel:SetText("Are you sure?")
                task.delay(time or 3, function() c = false; tpLabel:SetText("") end)
            end
        end)
    end
    AddConfirmTP("Teleport to Main Menu", MAIN_MENU_ID, 1.5)
    AddConfirmTP("Teleport to Lobby", LOBBY_ID)
    
    -- ============================== COMBINED AUTO ACTION (TELEPORT + KILL) ==============================
    TeleportGroup:AddDivider()
    
    local combinedDelay = 0
    local selectedActions = {}  -- e.g., {"Teleport to Main Menu", "Kill Character"}
    local combinedEnabled = false
    local combinedTimerRunning = false
    local combinedStartTime = 0
    local actionPending = false
    local teleportAttempts = 0
    local maxAttempts = 5
    
    TeleportGroup:AddSlider("CombinedActionDelaySlider", {
        Text = "Set Delay (seconds)",
        Default = 0,
        Min = 0,
        Max = 600,
        Rounding = 0,
        Suffix = " sec",
        Callback = function(v)
            combinedDelay = v
        end
    })
    
    TeleportGroup:AddDropdown("CombinedActionsDropdown", {
        Values = {"Teleport to Main Menu", "Kill Character"},
        Default = {},
        Multi = true,
        Text = "Select [ Multi ]",
        Callback = function(v)
            if type(v) == "table" then
                selectedActions = v
            else
                selectedActions = {v}
            end
        end
    })
    
    local function performTeleportToMainMenu()
        teleportAttempts = teleportAttempts + 1
        pcall(function() TeleportService:Teleport(MAIN_MENU_ID, Player) end)
        if teleportAttempts >= maxAttempts then
            game:Shutdown()
        end
    end
    
    local function performKillCharacter()
        local player = game.Players.LocalPlayer
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = 0
        end
    end
    
    local function executeCombinedActions()
        if not actionPending then return end
        actionPending = false
        combinedTimerRunning = false
        
        for _, action in ipairs(selectedActions) do
            if action == "Teleport to Main Menu" then
                performTeleportToMainMenu()
            elseif action == "Kill Character" then
                performKillCharacter()
            end
            task.wait(0.2)  -- slight delay between actions if both selected
        end
        teleportAttempts = 0
    end
    
    local function startCombinedTimer()
        if combinedTimerRunning then return end
        if combinedDelay <= 0 then
            -- execute immediately
            if #selectedActions > 0 then
                actionPending = true
                executeCombinedActions()
            end
            return
        end
        
        combinedTimerRunning = true
        actionPending = true
        combinedStartTime = tick()
        
        task.spawn(function()
            while combinedEnabled and actionPending do
                local elapsed = tick() - combinedStartTime
                if elapsed >= combinedDelay then
                    executeCombinedActions()
                    break
                end
                task.wait(0.1)
            end
        end)
    end
    
    local function stopCombinedTimer()
        actionPending = false
        combinedTimerRunning = false
        teleportAttempts = 0
    end
    
    TeleportGroup:AddToggle("CombinedActionToggle", {
        Text = "Enable Failed Safe",
        Default = false,
        Callback = function(v)
            if v then task.wait(1) end
            combinedEnabled = v
            if v then
                startCombinedTimer()
            else
                stopCombinedTimer()
            end
        end
    })
end

local TitansFolder = workspace:FindFirstChild("Titans")

local function IsInCutscene()
    local ok, result = pcall(function()
        local gui = Player:FindFirstChild("PlayerGui")
        if not gui then return false end
        local Interface = gui:FindFirstChild("Interface")
        if not Interface then return false end
        local skip = Interface:FindFirstChild("Skip")
        local skipWarning = Interface:FindFirstChild("Skip_Warning")
        return (skip and skip.Visible) or (skipWarning and skipWarning.Visible) or false
    end)
    return ok and result or false
end

if ({[MAIN_MENU_ID]=true,[LOBBY_ID]=true})[game.PlaceId] then return end

if not TitansFolder then
    TitansFolder = workspace:FindFirstChild("Titans")
    if not TitansFolder then
        TitansFolder = Instance.new("Folder")
        TitansFolder.Name = "Titans"
        TitansFolder.Parent = workspace
    end
end

-- ============================== FARM CORE (SMOOTH TWEEN MOVEMENT) ==============================
local TitansFolder = workspace:FindFirstChild("Titans")

local function IsInCutscene()
    local ok, result = pcall(function()
        local gui = Player:FindFirstChild("PlayerGui")
        if not gui then return false end
        local Interface = gui:FindFirstChild("Interface")
        if not Interface then return false end
        local skip = Interface:FindFirstChild("Skip")
        local skipWarning = Interface:FindFirstChild("Skip_Warning")
        return (skip and skip.Visible) or (skipWarning and skipWarning.Visible) or false
    end)
    return ok and result or false
end

if ({[MAIN_MENU_ID]=true,[LOBBY_ID]=true})[game.PlaceId] then return end

if not TitansFolder then
    TitansFolder = workspace:FindFirstChild("Titans")
    if not TitansFolder then
        TitansFolder = Instance.new("Folder")
        TitansFolder.Name = "Titans"
        TitansFolder.Parent = workspace
    end
end

-- ==================== ฟังก์ชันตรวจสอบ Objectives ====================
local function isObjectivesActiveForCore()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local function IsActuallyVisible(gui)
        if not gui or not gui:IsA("GuiObject") then return false end
        if not gui.Visible then return false end
        local current = gui.Parent
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return true
    end
    
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v.Name == "Objectives" then
            if IsActuallyVisible(v) then
                return true
            end
        end
    end
    return false
end

-- ==================== ตรวจสอบ Slay UI ====================
local slayCache = false
local slayCacheTime = 0
local SLAY_CACHE_DURATION = 0.1

local function isSlayObjectiveVisible()
    local now = tick()
    if now - slayCacheTime < SLAY_CACHE_DURATION then
        return slayCache
    end
    slayCacheTime = now
    
    local player = game:GetService("Players").LocalPlayer
    local targetGui = player.PlayerGui:FindFirstChild("Interface")
    if targetGui then
        targetGui = targetGui:FindFirstChild("HUD")
        if targetGui then
            targetGui = targetGui:FindFirstChild("Objectives")
            if targetGui then
                targetGui = targetGui:FindFirstChild("Main")
                if targetGui then
                    targetGui = targetGui:FindFirstChild("Slay")
                    if targetGui and targetGui:IsA("TextLabel") then
                        local visible = true
                        local current = targetGui
                        while current do
                            if current:IsA("GuiObject") and not current.Visible then visible = false break end
                            if current:IsA("ScreenGui") and not current.Enabled then visible = false break end
                            current = current.Parent
                        end
                        if visible and targetGui.AbsoluteSize.X > 0 and targetGui.AbsoluteSize.Y > 0 then
                            slayCache = true
                            return true
                        end
                    end
                end
            end
        end
    end
    slayCache = false
    return false
end

-- ==================== เพิ่มระบบตรวจจับ Mission สำหรับ Shiganshina Breach ====================
local isShiganshinaBreachMission = false
local isProtectHQActive = false
local protectHQCompleted = false
local lastMissionCheck = 0

-- ฟังก์ชันอัปเดตข้อมูล Mission (เรียกทุก 3 วินาที)
local function updateMissionInfo()
    local now = tick()
    if now - lastMissionCheck < 3 then return end
    lastMissionCheck = now
    
    pcall(function()
        local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
        local data = GET:InvokeServer("Data", "Copy")
        if data and data.Map then
            local mapName = data.Map.Map or ""
            local objective = data.Map.Objective or ""
            if mapName == "Shiganshina" and objective == "Breach" then
                if not isShiganshinaBreachMission then
                    isShiganshinaBreachMission = true
                    Library:Notify("[DEBUG] Shiganshina Breach mission detected - Slay check disabled until Protect_HQ appears", 4)
                end
            else
                if isShiganshinaBreachMission then
                    isShiganshinaBreachMission = false
                    isProtectHQActive = false
                    protectHQCompleted = false
                    Library:Notify("[DEBUG] Not Shiganshina Breach - Returning to normal mode", 3)
                end
            end
        end
    end)
end

-- ฟังก์ชันตรวจสอบ Protect_HQ
local function checkProtectHQ()
    if not isShiganshinaBreachMission then return end
    
    local player = game:GetService("Players").LocalPlayer
    local protect = player.PlayerGui:FindFirstChild("Interface") and 
                    player.PlayerGui.Interface:FindFirstChild("HUD") and
                    player.PlayerGui.Interface.HUD:FindFirstChild("Objectives") and
                    player.PlayerGui.Interface.HUD.Objectives:FindFirstChild("Main") and
                    player.PlayerGui.Interface.HUD.Objectives.Main:FindFirstChild("Protect_HQ")
    
    if protect and protect:IsA("TextLabel") and protect.Visible then
        if not isProtectHQActive then
            isProtectHQActive = true
            protectHQCompleted = false
            Library:Notify("[DEBUG] Protect_HQ appeared - Slay check will be re-enabled after completing Protect_HQ", 3)
        end
        
        -- ตรวจสอบความคืบหน้า
        local text = protect.Text
        local current, max = text:match("(%d+)/(%d+)")
        if current and max then
            if tonumber(current) >= tonumber(max) and not protectHQCompleted then
                protectHQCompleted = true
                Library:Notify("[DEBUG] Protect_HQ completed ("..current.."/"..max..") - Re-enabling Slay check", 3)
            end
        end
    else
        if isProtectHQActive and not protectHQCompleted then
            -- Protect_HQ หายไปแต่ยังไม่ครบ? อาจเป็นด่านอื่น
            isProtectHQActive = false
        end
    end
end

-- เริ่มลูปตรวจจับ Mission และ Protect_HQ
task.spawn(function()
    while true do
        updateMissionInfo()
        checkProtectHQ()
        task.wait(1)
    end
end)

-- ==================== BOSS DETECTION ====================
local BOSS_NAMES = {
    Attack_Titan = true, Armored_Titan = true, Female_Titan = true,
    Beast_Titan = true, Colossal_Titan = true, Warhammer_Titan = true,
    Jaw_Titan = true, Cart_Titan = true
}
local attackTitanSpawnTime = nil

-- ==================== STRUCTURE ====================
local ActiveTitans = {}
local LastScan = 0
local SCAN_RATE = 0.1
local NapeCache = setmetatable({}, {__mode = "k"})

local function IsTitanAlive(t)
    local h = t:FindFirstChildWhichIsA("Humanoid")
    return h and h.Health > 10
end

local function GetNape(t)
    local c = NapeCache[t]
    if c then return c end
    local hitboxes = t:FindFirstChild("Hitboxes")
    if hitboxes then
        local hit = hitboxes:FindFirstChild("Hit")
        if hit then
            local nape = hit:FindFirstChild("Nape")
            if nape and nape:IsA("BasePart") then
                NapeCache[t] = nape
                return nape
            end
        end
    end
    return nil
end

local function ScanTitans()
    local now = tick()
    if now - LastScan < SCAN_RATE then return end
    LastScan = now
    local titansFolder = workspace:FindFirstChild("Titans")
    if not titansFolder then
        table.clear(ActiveTitans)
        return
    end
    table.clear(ActiveTitans)
    local attackFound = false
    for _, t in ipairs(titansFolder:GetChildren()) do
        if t:IsA("Model") and IsTitanAlive(t) then
            local fake = t:FindFirstChild("Fake")
            if fake and fake:FindFirstChild("Collision") and not fake.Collision.CanCollide then
                continue
            end
            local nape = GetNape(t)
            if nape then
                local isBoss = BOSS_NAMES[t.Name] or false
                if t.Name == "Attack_Titan" then attackFound = true end
                table.insert(ActiveTitans, {titan = t, nape = nape, isBoss = isBoss, titanName = t.Name})
            end
        end
    end
    if attackFound then
        if not attackTitanSpawnTime then attackTitanSpawnTime = now end
    else
        attackTitanSpawnTime = nil
    end
end

local function GetBestTarget(hrpPos)
    local now = tick()
    local attackReady = true
    if attackTitanSpawnTime then
        attackReady = (now - attackTitanSpawnTime) >= 5
    end
    local bestBoss, bestBossDist = nil, math.huge
    local bestNormal, bestNormalDist = nil, math.huge
    for _, entry in ipairs(ActiveTitans) do
        if entry.titanName == "Attack_Titan" and not attackReady then continue end
        local n = entry.nape
        local dx = hrpPos.X - n.Position.X
        local dz = hrpPos.Z - n.Position.Z
        local distSq = dx*dx + dz*dz
        if entry.isBoss then
            if distSq < bestBossDist then bestBossDist = distSq; bestBoss = entry end
        else
            if distSq < bestNormalDist then bestNormalDist = distSq; bestNormal = entry end
        end
    end
    return bestBoss or bestNormal
end

local CharParts = {}
local CharRef = nil
local function NoclipOn()
    local char = Player.Character
    if not char then return end
    if char ~= CharRef then
        CharRef = char
        CharParts = {}
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                CharParts[#CharParts + 1] = v
            end
        end
    end
    for i = 1, #CharParts do
        if CharParts[i] and CharParts[i].Parent then
            CharParts[i].CanCollide = false
        end
    end
end

-- ========== SMOOTH TWEEN MOVEMENT ==========
local bodyPos = nil
local bodyGyro = nil

local function InitSmoothMovement(hrp)
    if not bodyPos or not bodyPos.Parent then
        if bodyPos then bodyPos:Destroy() end
        bodyPos = Instance.new("BodyPosition")
        bodyPos.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        bodyPos.P = 3500
        bodyPos.D = 700
        bodyPos.Parent = hrp
    end
    if not bodyGyro or not bodyGyro.Parent then
        if bodyGyro then bodyGyro:Destroy() end
        bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        bodyGyro.P = 6000
        bodyGyro.D = 1200
        bodyGyro.Parent = hrp
    end
end

local function CleanupSmoothMovement()
    if bodyPos then bodyPos:Destroy(); bodyPos = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
end

local function MoveSmooth(hrp, targetPos, targetLookDir)
    if not hrp then return end
    InitSmoothMovement(hrp)
    bodyPos.Position = targetPos
    if targetLookDir then
        bodyGyro.CFrame = CFrame.lookAt(targetPos, targetLookDir)
    else
        bodyGyro.CFrame = CFrame.lookAt(targetPos, targetPos + Vector3.new(0, 0, -1))
    end
end

local function MoveStableTeleport(hrp, targetPos)
    if not hrp then return end
    hrp.CFrame = CFrame.new(targetPos)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    CleanupSmoothMovement()
end

local CurrentEntry = nil
local isDead = false
local IdleHoverY = 80

local function IsRewardsUIVisible()
    local interface = Player.PlayerGui:FindFirstChild("Interface")
    if interface then
        local rewards = interface:FindFirstChild("Rewards")
        if rewards and rewards.Visible then return true end
    end
    return false
end

local function OnDeath()
    isDead = true
    CurrentEntry = nil
    NapeCache = setmetatable({}, {__mode = "k"})
    ActiveTitans = {}
    CharRef = nil
    CharParts = {}
    CleanupSmoothMovement()
end

local function OnSpawn(char)
    isDead = false
    CharRef = nil
    CleanupSmoothMovement()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Died:Connect(OnDeath) end
end

if Player.Character then OnSpawn(Player.Character) end
Player.CharacterAdded:Connect(OnSpawn)

local FarmConn = nil
local FARM_ATTACK_INTERVAL = 0.15
local LastAttackTime = 0

-- ==================== Wave Safety ====================
local waveWaiting = false
local lastDefendText = ""
local function getWaveProgress()
    local player = game:GetService("Players").LocalPlayer
    local defend = player.PlayerGui:FindFirstChild("Interface") and 
                   player.PlayerGui.Interface:FindFirstChild("HUD") and
                   player.PlayerGui.Interface.HUD:FindFirstChild("Objectives") and
                   player.PlayerGui.Interface.HUD.Objectives:FindFirstChild("Main") and
                   player.PlayerGui.Interface.HUD.Objectives.Main:FindFirstChild("Defend")
    if defend and defend:IsA("TextLabel") and defend.Visible then
        local text = defend.Text
        local current, max = text:match("(%d+)/(%d+)")
        if current and max then
            return tonumber(current), tonumber(max), text
        end
    end
    return nil, nil, nil
end

-- ========== โจมตีไททันทั้งหมด (ปรับให้เมื่อถึง Safety Time จะยกเลิกทุกการตรวจสอบ) ==========
local function AttackAllTitans()
    if #ActiveTitans == 0 then return end
    if not isObjectivesActiveForCore() then return end
    
    if getgenv().IsReloading or getgenv().IsRefilling then
        return
    end

    local G = getgenv()
    local elapsed = (G.FarmStartTime and tick() - G.FarmStartTime) or 0
    local safe = elapsed >= (G.SafetyTime or 60)

    if safe then
        SafeFire(POST, "Attacks", "Slash", true)
        for _, entry in ipairs(ActiveTitans) do
            local nape = entry.nape
            if nape and nape.Parent then
                SafeFire(POST, "Hitboxes", "Register", nape, 9999, 0)
            end
        end
        return
    end

    if isShiganshinaBreachMission and not protectHQCompleted then
        SafeFire(POST, "Attacks", "Slash", true)
        for _, entry in ipairs(ActiveTitans) do
            local nape = entry.nape
            if nape and nape.Parent then
                SafeFire(POST, "Hitboxes", "Register", nape, 2500, 0)
            end
        end
        return
    end

    local currentWave, maxWave, defendText = getWaveProgress()
    if currentWave and maxWave and currentWave < maxWave then
        local nearComplete = (currentWave >= maxWave - 2)
        if nearComplete then
            if elapsed < (G.SafetyTime or 60) then
                if not waveWaiting then
                    waveWaiting = true
                    Library:Notify(string.format("Wave nearly complete (%d/%d), waiting for safety timer (%.0f/%.0f sec)", currentWave, maxWave, elapsed, G.SafetyTime or 60), 3)
                end
                return
            else
                if waveWaiting then
                    waveWaiting = false
                    Library:Notify("Safety timer reached, resuming attack!", 2)
                end
            end
        else
            waveWaiting = false
        end
    elseif currentWave and currentWave == maxWave then
        waveWaiting = false
    elseif not currentWave then
        waveWaiting = false
    end

    local slayVisible = isSlayObjectiveVisible()
    
    if not slayVisible then
        local dmg = 2500
        SafeFire(POST, "Attacks", "Slash", true)
        for _, entry in ipairs(ActiveTitans) do
            local nape = entry.nape
            if nape and nape.Parent then
                SafeFire(POST, "Hitboxes", "Register", nape, dmg, 0)
            end
        end
        return
    end
    
    local dmg = 2500
    local stopAt = G.StopAtTitansLeft or 1
    if not safe and #ActiveTitans <= stopAt then
        return
    end

    SafeFire(POST, "Attacks", "Slash", true)
    for _, entry in ipairs(ActiveTitans) do
        local nape = entry.nape
        if nape and nape.Parent then
            SafeFire(POST, "Hitboxes", "Register", nape, dmg, 0)
        end
    end
end

-- ========== ฟังก์ชันหลักฟาร์ม ==========
local function FarmUpdate()
    pcall(function()
        local G = getgenv()
        
        if not G.AutoFarmBlade then
            if G.Farm then
                G.Farm = false
            end
            return
        end
        
        if not G.Farm or isDead then return end
        
        if getgenv().IsReloading or getgenv().IsRefilling then
            return
        end
        
        if G.AutoFarmBlade and not G.Farm then
            G.Farm = true
            G.FarmStartTime = tick()
        end
        
        if IsRewardsUIVisible() then
            G.Farm = false
            if Options and Options.AutoFarmBlade then
                Options.AutoFarmBlade:SetValue(false)
            end
            return
        end

        local char = Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            OnDeath()
            return
        end

        hrp.AssemblyAngularVelocity = Vector3.zero

        if hrp.Position.Y < -50 then
            hrp.CFrame = CFrame.new(hrp.Position.X, IdleHoverY, hrp.Position.Z)
            hrp.AssemblyLinearVelocity = Vector3.zero
            CleanupSmoothMovement()
            return
        end

        ScanTitans()

        if #ActiveTitans == 0 then
            CurrentEntry = nil
            NoclipOn()
            CleanupSmoothMovement()
            local dy = IdleHoverY - hrp.Position.Y
            hrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(dy * 5, -50, 50), 0)
            return
        end

        if not CurrentEntry or not IsTitanAlive(CurrentEntry.titan) then
            CurrentEntry = GetBestTarget(hrp.Position)
        end
        
        if not CurrentEntry then return end

        local nape = CurrentEntry.nape
        if not nape then
            CurrentEntry = nil
            return
        end

        local ty = nape.Position.Y + (G.HoverHeight or 120)
        local tp = Vector3.new(nape.Position.X, ty, nape.Position.Z)
        local lookDir = Vector3.new(nape.Position.X, ty, nape.Position.Z - 5)

        NoclipOn()

        if G.FarmMode == "Teleport" then
            MoveStableTeleport(hrp, tp)
        else
            MoveSmooth(hrp, tp, lookDir)
        end

        local now = tick()
        if now - LastAttackTime >= FARM_ATTACK_INTERVAL then
            LastAttackTime = now
            AttackAllTitans()
        end
    end)
end

local function CreateFarmLoop()
    if FarmConn then FarmConn:Disconnect() end
    FarmConn = RunService.Heartbeat:Connect(FarmUpdate)
end

CreateFarmLoop()

task.spawn(function()
    while true do
        task.wait(0.1)
        local G = getgenv()
        if G.AutoFarmBlade then
            if not G.Farm then
                G.Farm = true
                G.FarmStartTime = tick()
                CurrentEntry = nil
                LastAttackTime = tick()
            end
        else
            if G.Farm then
                G.Farm = false
                CurrentEntry = nil
                CleanupSmoothMovement()
            end
        end
    end
end)

task.spawn(function()
    while task.wait(2) do
        if not FarmConn or not FarmConn.Connected then
            CreateFarmLoop()
        end
    end
end)

--// =====================================================
--// GLOBAL TOGGLE
--// =====================================================

getgenv().AutoReloadBlade = false
getgenv().IsReloading = false
getgenv().IsRefilling = false

--// =====================================================
--// AUTO BLADE RELOAD + REFILL SYSTEM (POST + KEYPRESS ONLY)
--// =====================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

--// =====================================================
--// SETTINGS
--// =====================================================

local Settings = {
    CheckDelay = 0.03,
    BladeReload = {
        Cooldown = 0.5,
        ConfirmCountRequired = 5,
    },
    Refill = {
        Cooldown = 2,
    }
}

--// =====================================================
--// REMOTES
--// =====================================================

local POST = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("POST")

--// =====================================================
--// KEY PRESS (R) - หลายวิธีเพื่อความเข้ากันได้
--// =====================================================

local VIM = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

local function PressR_VIM()
    pcall(function()
        VIM:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.02)
        VIM:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end)
end

local function PressR_VirtualUser()
    pcall(function()
        VirtualUser:KeyDown(Enum.KeyCode.R)
        task.wait(0.02)
        VirtualUser:KeyUp(Enum.KeyCode.R)
    end)
end

local function PressR_Context()
    pcall(function()
        local ContextActionService = game:GetService("ContextActionService")
        ContextActionService:Simulate(Enum.UserInputType.Keyboard, Enum.KeyCode.R, true)
        task.wait(0.02)
        ContextActionService:Simulate(Enum.UserInputType.Keyboard, Enum.KeyCode.R, false)
    end)
end

local PressR = nil
if pcall(function() return VIM.SendKeyEvent end) and VIM then
    PressR = PressR_VIM
elseif pcall(function() return VirtualUser.KeyDown end) and VirtualUser then
    PressR = PressR_VirtualUser
else
    PressR = PressR_Context
end

--// =====================================================
--// UI
--// =====================================================

local Sets = LocalPlayer
    :WaitForChild("PlayerGui")
    :WaitForChild("Interface")
    :WaitForChild("HUD")
    :WaitForChild("Main")
    :WaitForChild("Top")
    :WaitForChild("7")
    :WaitForChild("Blades")
    :WaitForChild("Sets")

--// =====================================================
--// INTERNAL
--// =====================================================

local LastBladeReload = 0
local LastRefillFire = 0
local BladeEmptyConfirmCounter = 0
local IsReloadingRapid = false

--// =====================================================
--// CHECK REAL BLADES
--// =====================================================

local function GetBladeMissingCount()
    local CharacterFolder = workspace:FindFirstChild("Characters")
    if not CharacterFolder then return nil, nil end

    local Character = CharacterFolder:FindFirstChild(LocalPlayer.Name)
    if not Character then return nil, nil end

    local Rig = Character:FindFirstChild("Rig_" .. LocalPlayer.Name)
    if not Rig then return nil, nil end

    local LeftHand = Rig:FindFirstChild("LeftHand")
    local RightHand = Rig:FindFirstChild("RightHand")
    if not LeftHand or not RightHand then return nil, nil end

    local leftMissing = 0
    local rightMissing = 0

    for i = 1,7 do
        local L = LeftHand:FindFirstChild("Blade_" .. i)
        local R = RightHand:FindFirstChild("Blade_" .. i)
        if L and L.Transparency == 1 then leftMissing = leftMissing + 1 end
        if R and R.Transparency == 1 then rightMissing = rightMissing + 1 end
    end

    return leftMissing, rightMissing
end

local function AreBladesEmpty()
    local leftMissing, rightMissing = GetBladeMissingCount()
    if leftMissing == nil then return false end
    return leftMissing == 7 and rightMissing == 7
end

--// =====================================================
--// FIND REFILL OBJECT (DYNAMIC, BASED ON USER'S EXAMPLE)
--// =====================================================
local function FindRefillObject()
    -- วิธีที่ 1: ใช้ path เดิมที่ผู้ใช้ให้ (Climbable._Walls.Gate:GetChildren()[50].Refill)
    local success, refill = pcall(function()
        local gate = workspace:FindFirstChild("Climbable") and workspace.Climbable:FindFirstChild("_Walls") and workspace.Climbable._Walls:FindFirstChild("Gate")
        if gate then
            local children = gate:GetChildren()
            for i, child in ipairs(children) do
                local ref = child:FindFirstChild("Refill")
                if ref then return ref end
            end
        end
        return nil
    end)
    if success and refill then return refill end

    -- วิธีที่ 2: หา GasTanks แล้วหา Refill
    success, refill = pcall(function()
        local gasTanks = workspace:FindFirstChild("Climbable") and workspace.Climbable:FindFirstChild("_Walls") and workspace.Climbable._Walls:FindFirstChild("Gate") and workspace.Climbable._Walls.Gate:FindFirstChild("GasTanks")
        if gasTanks then
            return gasTanks:FindFirstChild("Refill")
        end
        return nil
    end)
    if success and refill then return refill end

    -- วิธีที่ 3: ค้นหาทั่ว workspace ที่มีชื่อ "Refill"
    success, refill = pcall(function()
        return workspace:FindFirstChild("Refill", true)
    end)
    if success and refill then return refill end

    return nil
end

--// =====================================================
--// REFILL BLADE SETS (ใช้ POST Remote) - ตั้ง flag refilling
--// =====================================================
local function FireRefill()
    if not getgenv().AutoReloadBlade then return end
    local now = tick()
    if now - LastRefillFire < Settings.Refill.Cooldown then return end
    
    LastRefillFire = now
    getgenv().IsRefilling = true
    
    local refillObj = FindRefillObject()
    if refillObj then
        pcall(function()
            POST:FireServer("Attacks", "Reload", refillObj)
        end)
    else
        -- fallback: ใช้ path ตามที่ผู้ใช้ให้โดยตรง
        pcall(function()
            local gate = workspace:FindFirstChild("Climbable") and workspace.Climbable:FindFirstChild("_Walls") and workspace.Climbable._Walls:FindFirstChild("Gate")
            if gate then
                local children = gate:GetChildren()
                if children[50] and children[50]:FindFirstChild("Refill") then
                    POST:FireServer("Attacks", "Reload", children[50].Refill)
                end
            end
        end)
    end
    
    task.wait(0.5)
    getgenv().IsRefilling = false
end

--// =====================================================
--// RAPID RELOAD (กด R ซ้ำๆ) - ตั้ง flag reloading
--// =====================================================
local function RapidReloadBlades()
    if not getgenv().AutoReloadBlade then return end
    if IsReloadingRapid then return end
    
    IsReloadingRapid = true
    getgenv().IsReloading = true
    
    task.spawn(function()
        while getgenv().AutoReloadBlade and AreBladesEmpty() do
            local now = tick()
            if now - LastBladeReload >= Settings.BladeReload.Cooldown then
                LastBladeReload = now
                PressR()
            end
            task.wait(0.08)
        end
        getgenv().IsReloading = false
        IsReloadingRapid = false
    end)
end

--// =====================================================
--// MAIN LOOP (ปรับ: เมื่อ Sets = 0/3 ให้ refill ทันที)
--// =====================================================
task.spawn(function()
    while true do
        if getgenv().AutoReloadBlade then
            local success, text = pcall(function()
                return tostring(Sets.Text)
            end)

            if success then
                text = text:gsub("%s+", "")
                local bladesEmpty = AreBladesEmpty()

                -- ถ้า Sets = 0/3 (Blade Sets หมด) ให้ refill ทันที (ไม่ต้องรอ 5 วินาที)
                if text == "0/3" then
                    FireRefill()
                else
                    -- ถ้า blades จริงๆ หมด แต่ Sets ยังไม่หมด (อาจเป็น bug หรือ blades ขาด) ให้ reload
                    if bladesEmpty then
                        BladeEmptyConfirmCounter = BladeEmptyConfirmCounter + 1
                        if BladeEmptyConfirmCounter >= Settings.BladeReload.ConfirmCountRequired then
                            RapidReloadBlades()
                            BladeEmptyConfirmCounter = 0
                        end
                    else
                        BladeEmptyConfirmCounter = 0
                    end
                end
            end
        else
            BladeEmptyConfirmCounter = 0
            IsReloadingRapid = false
            getgenv().IsReloading = false
            getgenv().IsRefilling = false
        end
        task.wait(Settings.CheckDelay)
    end
end)

-- ========== WATCHDOG ป้องกันการค้าง reload/refill (เพิ่มโดยไม่แตะของเก่า) ==========
task.spawn(function()
    local STUCK_TIMEOUT = 5
    while true do
        task.wait(0.5)
        pcall(function()
            if getgenv().AutoReloadBlade then
                local now = tick()
                if getgenv().IsReloading then
                    if not _G.ReloadStartTime then _G.ReloadStartTime = now end
                    if now - _G.ReloadStartTime > STUCK_TIMEOUT then
                        getgenv().IsReloading = false
                        if IsReloadingRapid then IsReloadingRapid = false end
                        BladeEmptyConfirmCounter = 0
                        PressR()
                        _G.ReloadStartTime = nil
                    end
                else
                    _G.ReloadStartTime = nil
                end
                if getgenv().IsRefilling then
                    if not _G.RefillStartTime then _G.RefillStartTime = now end
                    if now - _G.RefillStartTime > STUCK_TIMEOUT then
                        getgenv().IsRefilling = false
                        _G.RefillStartTime = nil
                    end
                else
                    _G.RefillStartTime = nil
                end
            else
                _G.ReloadStartTime = nil
                _G.RefillStartTime = nil
            end
        end)
    end
end)


-- ============================== THUNDER SPEAR CORE LOGIC ==============================
if ({[MAIN_MENU_ID]=true,[LOBBY_ID]=true})[game.PlaceId] then return end

local TitansFolder = workspace:WaitForChild("Titans")

-- ฟังก์ชันตรวจสอบ Objectives สำหรับ Thunder Spear
local function isObjectivesActiveForSpear()
    local player = game:GetService("Players").LocalPlayer
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return false end
    
    local function IsActuallyVisible(gui)
        if not gui or not gui:IsA("GuiObject") then return false end
        if not gui.Visible then return false end
        local current = gui.Parent
        while current do
            if current:IsA("GuiObject") and not current.Visible then return false end
            if current:IsA("ScreenGui") and not current.Enabled then return false end
            current = current.Parent
        end
        return true
    end
    
    for _, v in ipairs(playerGui:GetDescendants()) do
        if v.Name == "Objectives" then
            if IsActuallyVisible(v) then
                return true
            end
        end
    end
    return false
end

task.spawn(function()
    task.wait(1)

    local player = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
    local POST = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("POST")

    local CurrentTarget = nil
    local LastRefill = 0
    local LastUpdate = 0
    local HasTeleported = false
    local BodyPosition = nil
    local BodyGyro = nil

    local CurrentFirePower = 0
    local EXPLODE_RADIUS = 35
    local BURST_SHOTS = 3
    local AOE_EXPLOSIONS_PER_TARGET = 6

    local function getGameMode()
        local success, data = pcall(function()
            return GET:InvokeServer("Data", "Copy")
        end)
        if success and data then
            if data.Map and data.Map.Type then
                return data.Map.Type
            elseif data.Raid then
                return "Raid"
            elseif data.Waves then
                return "Waves"
            end
        end
        local success2, state = pcall(function()
            return player.PlayerGui.Interface.Rewards.Main.Info.State.Text
        end)
        if success2 and state then
            if state:find("MISSION") then return "Mission"
            elseif state:find("RAID") then return "Raid"
            elseif state:find("WAVE") then return "Waves"
            end
        end
        return "Mission"
    end

    local NapeCache = {}
    local function GetNape(titan)
        if not titan or not titan.Parent then return nil end
        if NapeCache[titan] then return NapeCache[titan] end
        local hitboxes = titan:FindFirstChild("Hitboxes")
        if not hitboxes then return nil end
        local hit = hitboxes:FindFirstChild("Hit")
        if not hit then return nil end
        local nape = hit:FindFirstChild("Nape")
        if nape and nape:IsA("BasePart") then
            NapeCache[titan] = nape
            return nape
        end
        return nil
    end

    local CachedTitans = {}
    local LastTitanUpdate = 0
    local TITAN_CACHE_TIME = 0.02
    local function GetAliveTitans()
        local now = tick()
        if now - LastTitanUpdate < TITAN_CACHE_TIME then return CachedTitans end
        LastTitanUpdate = now
        CachedTitans = {}
        for _, titan in ipairs(TitansFolder:GetChildren()) do
            local hum = titan:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 10 then
                CachedTitans[#CachedTitans+1] = titan
            end
        end
        return CachedTitans
    end

    local function GetNearestTitan(titans, hrp)
        local nearest, shortest = nil, math.huge
        local hrpPos = hrp.Position
        for _, titan in ipairs(titans) do
            local nape = GetNape(titan)
            if nape then
                local dist = (hrpPos - nape.Position).Magnitude
                if dist < shortest then shortest = dist; nearest = titan end
            end
        end
        return nearest
    end

    local CachedCharParts = {}
    local CachedCharRef = nil
    local function ForceNoclip()
        local char = player.Character
        if not char then return end
        if char ~= CachedCharRef then
            CachedCharRef = char
            CachedCharParts = {}
            for _, v in ipairs(char:GetDescendants()) do
                if v:IsA("BasePart") then
                    CachedCharParts[#CachedCharParts+1] = v
                end
            end
        end
        for i = 1, #CachedCharParts do
            local part = CachedCharParts[i]
            if part and part.Parent then part.CanCollide = false end
        end
    end

    local function RestoreCollision()
        for i = 1, #CachedCharParts do
            local part = CachedCharParts[i]
            if part and part.Parent then part.CanCollide = true end
        end
    end

    local function MoveToTween(targetPos, speed)
        local char = player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        ForceNoclip()
        local diff = targetPos - hrp.Position
        local distH = math.sqrt(diff.X * diff.X + diff.Z * diff.Z)
        local hVel = Vector3.zero
        if distH > 0.5 then
            local mul = math.min(distH * 15, speed * 1.8) / distH
            hVel = Vector3.new(diff.X * mul, 0, diff.Z * mul)
        end
        local absY = diff.Y < 0 and -diff.Y or diff.Y
        local vVel = absY > 0.5 and (diff.Y > 0 and math.min(diff.Y * 12, speed * 1.5) or math.max(diff.Y * 12, -speed * 1.5)) or 0
        hrp.AssemblyLinearVelocity = Vector3.new(hVel.X, vVel, hVel.Z)
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    local function ReloadSpears()
        pcall(function()
            POST:FireServer("Attacks", "Reload", workspace:WaitForChild("Climbable"):WaitForChild("_Walls"):WaitForChild("Gate"):WaitForChild("GasTanks"):WaitForChild("Refill"))
        end)
        CurrentFirePower = 8
    end

    local function FireSingleShot()
        if CurrentFirePower <= 0 then
            ReloadSpears()
            task.wait(0.05)
            if CurrentFirePower == 0 then return end
        end
        pcall(function()
            GET:InvokeServer("Spears", "S_Fire", "1")
            CurrentFirePower = CurrentFirePower - 1
        end)
    end

    local function ExplodeAt(position)
        for i = 1, AOE_EXPLOSIONS_PER_TARGET do
            pcall(function()
                POST:FireServer("Spears", "S_Explode", position, EXPLODE_RADIUS)
            end)
            task.wait(0.002)
        end
    end

    local function AOEBombardment(centerPos, radius)
        local titans = GetAliveTitans()
        for _, titan in ipairs(titans) do
            local nape = GetNape(titan)
            if nape then
                local dist = (centerPos - nape.Position).Magnitude
                if dist <= radius then
                    ExplodeAt(nape.Position)
                end
            end
        end
        ExplodeAt(centerPos)
    end

    local function ThunderBurstAttack(napePos)
        for i = 1, BURST_SHOTS do
            FireSingleShot()
            task.wait(0.008)
        end
        AOEBombardment(napePos, 120)
    end

    local function IsTitanValid(titan)
        if not titan or not titan.Parent then return false end
        local hum = titan:FindFirstChildOfClass("Humanoid")
        return hum and hum.Health > 10
    end

    RunService.Heartbeat:Connect(function()
        pcall(function()
            local now = tick()
            if now - LastUpdate < 0.02 then return end
            LastUpdate = now

            local G = getgenv()
            if not G.AutoThunderSpear then
                RestoreCollision()
                CurrentTarget = nil
                HasTeleported = false
                if BodyPosition then BodyPosition:Destroy(); BodyPosition = nil end
                if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
                return
            end
            
            -- ถ้า Objectives ไม่แสดง ให้หยุดทำงาน
            if not isObjectivesActiveForSpear() then
                if G.AutoThunderSpear then
                    G.AutoThunderSpear = false
                    if Options and Options.AutoThunderSpearToggle then
                        Options.AutoThunderSpearToggle:SetValue(false)
                    end
                end
                return
            end

            local char = player.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then return end
            if hum.Health <= 0 then return end

            hrp.AssemblyAngularVelocity = Vector3.zero

            local titans = GetAliveTitans()
            if #titans == 0 then
                CurrentTarget = nil
                HasTeleported = false
                if BodyPosition then BodyPosition:Destroy(); BodyPosition = nil end
                if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
                return
            end

            if not IsTitanValid(CurrentTarget) then
                CurrentTarget = nil
                HasTeleported = false
                if BodyPosition then BodyPosition:Destroy(); BodyPosition = nil end
                if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
            end

            if not CurrentTarget then
                CurrentTarget = GetNearestTitan(titans, hrp)
                HasTeleported = false
                if BodyPosition then BodyPosition:Destroy(); BodyPosition = nil end
                if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
            end
            if not CurrentTarget then return end

            local nape = GetNape(CurrentTarget)
            if not nape then
                CurrentTarget = nil
                HasTeleported = false
                if BodyPosition then BodyPosition:Destroy(); BodyPosition = nil end
                if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
                return
            end

            local hoverHeight = G.ThunderSpearHoverHeight or 120
            local hoverSpeed = G.ThunderSpearHoverSpeed or 250
            local targetHeight = nape.Position.Y + hoverHeight
            local targetPos = Vector3.new(nape.Position.X, targetHeight, nape.Position.Z)

            if G.ThunderSpearFarmMode == "Teleport" then
                if not HasTeleported then
                    ForceNoclip()
                    hrp.CFrame = CFrame.new(targetPos)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero

                    if BodyPosition then BodyPosition:Destroy() end
                    if BodyGyro then BodyGyro:Destroy() end
                    BodyPosition = Instance.new("BodyPosition")
                    BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                    BodyPosition.P = 50000
                    BodyPosition.D = 500
                    BodyPosition.Position = targetPos
                    BodyPosition.Parent = hrp

                    BodyGyro = Instance.new("BodyGyro")
                    BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                    BodyGyro.P = 50000
                    BodyGyro.D = 500
                    local direction = Vector3.new(nape.Position.X - targetPos.X, 0, nape.Position.Z - targetPos.Z)
                    BodyGyro.CFrame = direction.Magnitude > 0 and CFrame.new(Vector3.zero, direction) or CFrame.new(Vector3.zero)
                    BodyGyro.Parent = hrp

                    HasTeleported = true
                else
                    ForceNoclip()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end
            else
                MoveToTween(targetPos, hoverSpeed)
            end

            local gameMode = getGameMode()
            if gameMode == "Mission" then
                local elapsed = (G.FarmStartTime and (tick() - G.FarmStartTime)) or 0
                local safe = elapsed >= (G.SafetyTime or 60)
                local stopAt = G.StopAtTitansLeft or 1
                if not safe and #titans <= stopAt then
                    return
                end
            end

            ThunderBurstAttack(nape.Position)
        end)
    end)
end)



-- ============================== AUTO RETRY (SILENT MODE) ==============================
if Tabs.AutoFarm then
    task.spawn(function()
        local cooldown = 2.5
        local lastClick = 0
        local hasNotifiedThisRound = false
        local rewardDetectedTime = 0
        local waitingForRetry = false
        local retryAttempts = 0
        local maxAttempts = 3
        
        local function IsActuallyVisible(gui)
            if not gui or not gui.Visible then return false end
            local current = gui.Parent
            while current and current ~= game do
                if current:IsA("GuiObject") and not current.Visible then return false end
                current = current.Parent
            end
            return true
        end
        
        local LastState = nil
        
        while true do
            task.wait(0.2)
            
            if not getgenv().StartRejoin then
                LastState = nil
                hasNotifiedThisRound = false
                waitingForRetry = false
                rewardDetectedTime = 0
                retryAttempts = 0
                continue
            end
            
            local player = game:GetService("Players").LocalPlayer
            local VIM = game:GetService("VirtualInputManager")
            local GS = game:GetService("GuiService")
            local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
            
            local interface = player.PlayerGui:FindFirstChild("Interface")
            if not interface then
                LastState = nil
                hasNotifiedThisRound = false
                waitingForRetry = false
                rewardDetectedTime = 0
                retryAttempts = 0
                continue
            end
            
            local rewards = interface:FindFirstChild("Rewards")
            if not rewards then
                LastState = nil
                hasNotifiedThisRound = false
                waitingForRetry = false
                rewardDetectedTime = 0
                retryAttempts = 0
                continue
            end
            
            local retry = rewards.Main.Info.Main.Buttons.Retry
            if not retry then
                LastState = nil
                hasNotifiedThisRound = false
                waitingForRetry = false
                rewardDetectedTime = 0
                retryAttempts = 0
                continue
            end
            
            local currentState = IsActuallyVisible(retry) and "open" or "close"
            
            if currentState == "open" and LastState ~= "open" then
                rewardDetectedTime = tick()
                waitingForRetry = true
                retryAttempts = 0
            end
            
            LastState = currentState
            
            if not waitingForRetry then continue end
            
            if tick() - rewardDetectedTime >= 2.5 then
                if retryAttempts >= maxAttempts then
                    waitingForRetry = false
                    retryAttempts = 0
                    task.wait(2)
                    continue
                end
                
                if not IsActuallyVisible(retry) then
                    waitingForRetry = false
                    retryAttempts = 0
                    continue
                end
                
                local allVisible = true
                local obj = retry
                while obj and obj ~= player.PlayerGui do
                    if obj:IsA("GuiObject") and not obj.Visible then allVisible = false break end
                    if obj:IsA("ScreenGui") and not obj.Enabled then allVisible = false break end
                    obj = obj.Parent
                end
                if not allVisible then
                    waitingForRetry = false
                    continue
                end
                
                GS.SelectedObject = retry
                task.wait(0.05)
                VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
                task.wait(0.1)
                GS.SelectedObject = nil
                
                retryAttempts = retryAttempts + 1
                waitingForRetry = false
            end
        end
    end)
end


-- ============================== WEBHOOK TAB ==============================
if Tabs.Webhook then
    local WebhookGroup = Tabs.Webhook:AddLeftGroupbox("Discord Webhook")
    
    local webhookURL = ""
    local webhookEnabled = false
    local hasSentWebhook = false
    local lastMissionState = ""
    local webhookMode = "All Data"
    local webhookPingMode = "None"
    
    -- Reward Webhook variables
    local gamesPlayed = 0
    local gamesPlayedPath = "FakeHUB/games_played.txt"
    
    if isfile(gamesPlayedPath) then
        gamesPlayed = tonumber(readfile(gamesPlayedPath)) or 0
    else
        writefile(gamesPlayedPath, "0")
    end
    
    local function incrementGamesPlayed()
        gamesPlayed = gamesPlayed + 1
        writefile(gamesPlayedPath, tostring(gamesPlayed))
    end
    
    -- ========== โหลด Items Module สำหรับแมปไอคอน ==========
    local ItemsModule = nil
    local IconToNameMap = {}
    
    local function loadItemsModule()
        local success, module = pcall(function()
            return require(game:GetService("ReplicatedStorage").Modules.Storage.Items)
        end)
        if success and type(module) == "table" then
            ItemsModule = module
            for itemName, itemData in pairs(module) do
                if type(itemData) == "table" and itemData.Image then
                    local img = tostring(itemData.Image)
                    local assetId = img:match("rbxassetid://(%d+)") or img:match("^(%d+)$")
                    if assetId then
                        IconToNameMap[assetId] = itemName
                    end
                end
            end
            return true
        end
        return false
    end
    
    task.spawn(function()
        task.wait(1)
        loadItemsModule()
    end)
    
    local function findUIElements()
        local player = game:GetService("Players").LocalPlayer
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then return nil, nil end
        local interface = playerGui:FindFirstChild("Interface")
        if not interface then return nil, nil end
        local rewards = interface:FindFirstChild("Rewards")
        if not rewards then return nil, nil end
        local main = rewards:FindFirstChild("Main")
        if not main then return nil, nil end
        local info = main:FindFirstChild("Info")
        if not info then return nil, nil end
        local mainInfo = info:FindFirstChild("Main")
        if not mainInfo then return nil, nil end
        local statsFrame = mainInfo:FindFirstChild("Stats")
        local itemsFrame = mainInfo:FindFirstChild("Items")
        return statsFrame, itemsFrame
    end
    
    local function waitForServerData(maxWait)
        local start = tick()
        local lastData = nil
        local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
        while tick() - start < maxWait do
            local success, data = pcall(function()
                return GET:InvokeServer("Data", "Copy")
            end)
            if success and data and data.Slots then
                local slot = data.Slots[data.Current_Slot or "A"]
                if slot and slot.Currency and slot.Progression then
                    if (slot.Currency.Gold or 0) > 0 or (slot.Currency.Gems or 0) > 0 or (slot.Progression.Level or 0) > 0 then
                        lastData = data
                        break
                    end
                end
                lastData = data
            end
            task.wait(0.3)
        end
        return lastData
    end
    
    local function waitForUIElements(maxWait)
        local start = tick()
        local statsFrame, itemsFrame = nil, nil
        while tick() - start < maxWait do
            statsFrame, itemsFrame = findUIElements()
            local hasStat = false
            local hasItem = false
            if statsFrame then
                for _, v in ipairs(statsFrame:GetChildren()) do
                    if v:IsA("Frame") and v:FindFirstChild("Amount") then
                        local amount = v.Amount.Text
                        if amount and amount ~= "0" and amount ~= "" then
                            hasStat = true
                            break
                        end
                    end
                end
            end
            if itemsFrame then
                for _, v in ipairs(itemsFrame:GetChildren()) do
                    if v:IsA("Frame") and v:FindFirstChild("Main") then
                        local inner = v.Main:FindFirstChild("Inner")
                        if inner and inner.Quantity and inner.Quantity.Text ~= "0" and inner.Quantity.Text ~= "" then
                            hasItem = true
                            break
                        end
                    end
                end
            end
            if hasStat or hasItem then break end
            task.wait(0.2)
        end
        return findUIElements()
    end
    
    -- ฟังก์ชันดึงรายการไอเทมทั้งหมด (ไม่รวมซ้ำ, เรียงตามลำดับที่พบ + จัดลำดับความสำคัญ)
    local function getAllRewards()
        local player = game:GetService("Players").LocalPlayer
        local mainInfo = player.PlayerGui.Interface.Rewards.Main.Info.Main
        local rewardsList = {} -- แต่ละ element จะเป็น {name, qty, rare}
        
        -- ฟังก์ชัน extract จาก Frame
        local function extractFromFrame(frame)
            local qtyText = nil
            local itemName = nil
            local isRare = false
            
            -- กรณีมี Main.Inner (ไอเทมส่วนใหญ่)
            local mainObj = frame:FindFirstChild("Main")
            local inner = mainObj and mainObj:FindFirstChild("Inner")
            if inner then
                local qtyObj = inner:FindFirstChild("Quantity")
                if qtyObj and qtyObj:IsA("TextLabel") then
                    qtyText = qtyObj.Text
                    local num = tonumber(qtyText:match("%d+"))
                    if num and num > 0 then
                        -- หาชื่อจาก Icon
                        local icon = inner:FindFirstChild("Icon")
                        if icon and icon:IsA("ImageLabel") and icon.Image then
                            local assetId = tostring(icon.Image):match("rbxassetid://(%d+)") or tostring(icon.Image):match("^(%d+)$")
                            if assetId and IconToNameMap[assetId] then
                                itemName = IconToNameMap[assetId]
                            end
                        end
                        if not itemName then
                            local title = inner:FindFirstChild("Title")
                            if title and title:IsA("TextLabel") and title.Text ~= "" then
                                itemName = title.Text
                            else
                                local nameObj = inner:FindFirstChild("Name")
                                if nameObj and nameObj:IsA("TextLabel") and nameObj.Text ~= "" then
                                    itemName = nameObj.Text
                                end
                            end
                        end
                        -- ตรวจสอบ Rarity สีแดง
                        local rarity = inner:FindFirstChild("Rarity")
                        if rarity and rarity.BackgroundColor3 == Color3.fromRGB(255, 0, 0) then
                            isRare = true
                        end
                    end
                end
            else
                -- fallback สำหรับ Perk หรือโครงสร้างอื่น
                local nameLabel = frame:FindFirstChild("Name") or frame:FindFirstChild("Title")
                local amountLabel = frame:FindFirstChild("Amount") or frame:FindFirstChild("Quantity")
                if nameLabel and nameLabel:IsA("TextLabel") and amountLabel and amountLabel:IsA("TextLabel") then
                    local num = tonumber(amountLabel.Text:match("%d+"))
                    if num and num > 0 then
                        qtyText = amountLabel.Text
                        itemName = nameLabel.Text
                    end
                end
            end
            
            if itemName and qtyText then
                table.insert(rewardsList, { name = itemName, qty = qtyText, rare = isRare })
                return true
            end
            return false
        end
        
        -- สแกนแบบ recursive ทุก Frame ใน mainInfo (รวม Items, Obtained, และอื่นๆ)
        local function scanAll(obj)
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("Frame") then
                    if extractFromFrame(child) then
                        -- พบแล้ว ไม่ต้องสแกนลึกต่อ (เพราะไอเทมอยู่ใน Frame นี้)
                    else
                        scanAll(child)
                    end
                end
            end
        end
        scanAll(mainInfo)
        
        -- จัดลำดับตามความต้องการ: EXP > Gold > Canes > ที่เหลือตามชื่อ
        local priorityOrder = { "XP", "Gold", "Canes" }
        local function getPriority(name)
            for i, p in ipairs(priorityOrder) do
                if string.lower(name) == string.lower(p) then
                    return i
                end
            end
            return 999
        end
        table.sort(rewardsList, function(a, b)
            local pa = getPriority(a.name)
            local pb = getPriority(b.name)
            if pa ~= pb then return pa < pb end
            return a.name < b.name
        end)
        
        return rewardsList
    end
    
    -- ฟังก์ชันหลักส่ง Reward Webhook
    local function sendRewardWebhook()
        if webhookURL == "" then return end
        incrementGamesPlayed()
        
        if not ItemsModule or #IconToNameMap == 0 then
            loadItemsModule()
        end
        
        -- ดึงสถิติจาก Stats Frame
        local statsFrame, _ = findUIElements()
        local stats = {}
        if statsFrame then
            for _, v in ipairs(statsFrame:GetChildren()) do
                if v:IsA("Frame") and v:FindFirstChild("Stat") and v:FindFirstChild("Amount") then
                    local statName = string.gsub(v.Name, "_", " ")
                    stats[statName] = v.Amount.Text
                end
            end
        end
        
        -- ดึงรายการไอเทมทั้งหมด
        local rewards = getAllRewards()
        
        -- แยก Special (Rarity สีแดง)
        local specials = {}
        for _, item in ipairs(rewards) do
            if item.rare then
                table.insert(specials, item)
            end
        end
        
        -- ดึงข้อมูลสะสม (Level, Gold, Gems) จาก Server
        local player = game:GetService("Players").LocalPlayer
        local total = { Level = 1, Gold = 0, Gems = 0 }
        pcall(function()
            local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
            local mapData = GET:InvokeServer("Data", "Copy")
            local slotIndex = player:GetAttribute("Slot") or "A"
            if mapData and mapData.Slots and mapData.Slots[slotIndex] then
                local slot = mapData.Slots[slotIndex]
                if slot.Currency then
                    total.Gold = slot.Currency.Gold or 0
                    total.Gems = slot.Currency.Gems or 0
                end
                if slot.Progression then
                    total.Level = slot.Progression.Level or 1
                end
            end
        end)
        
        local hasSpecial = #specials > 0
        local executor = identifyexecutor and identifyexecutor() or "Unknown"
        
        -- กำหนด content สำหรับ ping ตามที่ผู้ใช้เลือก
        local pingContent = nil
        if webhookPingMode == "Everyone" then
            pingContent = "@everyone"
        elseif webhookPingMode == "Here" then
            pingContent = "@here"
        else
            pingContent = nil
        end
        
        local function formatTable(tbl)
            local str = ""
            for k, v in pairs(tbl) do
                str = str .. string.format("%s: %s\n", k, tostring(v))
            end
            return str ~= "" and str or "None"
        end
        
        local function formatRewardsList(list)
            if #list == 0 then return "None" end
            local lines = {}
            for _, item in ipairs(list) do
                lines[#lines+1] = string.format("• %s (x%s)", item.name, item.qty)
            end
            return table.concat(lines, "\n")
        end
        
        local payload = {
            content = (hasSpecial and pingContent) or nil,
            embeds = {{
                title = "FakeHUB Rewards",
                color = hasSpecial and 0xff0000 or 0x2b2d31,
                fields = {
                    { name = "Information", value = string.format("\nUser: %s\nGames Played: %d\nExecutor: %s\n", player.Name, gamesPlayed, executor), inline = true },
                    { name = "Total Stats", value = string.format("\nLevel : %s\nGold  : %s\nGems  : %s\n", total.Level, total.Gold, total.Gems), inline = true },
                    { name = "Combat", value = "\n" .. formatTable(stats) .. "\n", inline = true },
                    { name = "Rewards", value = "\n" .. formatRewardsList(rewards) .. "\n", inline = false },
                    { name = "Special", value = "\n" .. (hasSpecial and formatRewardsList(specials) or "None") .. "\n", inline = false }
                },
                footer = { text = "FakeHUB • " .. os.date("%Y-%m-%d %H:%M:%S") },
                timestamp = DateTime.now():ToIsoDate()
            }}
        }
        
        pcall(function()
            request({ Url = webhookURL, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = game:GetService("HttpService"):JSONEncode(payload) })
        end)
    end
    
    -- ส่วน All Data Webhook (คงเดิม)
    local filters = {
        Currency = true,
        Progression = true,
        Loadout = true,
        Inventory = true,
        Cosmetics = true,
    }
    
    local function fmt(n)
        if type(n) ~= "number" then return tostring(n) end
        if n >= 1e9 then return string.format("%.2fB", n/1e9)
        elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
        elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
        else return tostring(n) end
    end
    
    local function getItems(tbl, prefix)
        if not tbl then return nil end
        local items = {}
        for name, qty in pairs(tbl) do
            table.insert(items, {name = name, qty = qty})
        end
        table.sort(items, function(a, b)
            return string.lower(a.name) < string.lower(b.name)
        end)
        local lines = {}
        for _, item in ipairs(items) do
            table.insert(lines, (prefix or "• ") .. item.name .. ": x" .. tostring(item.qty))
        end
        return #lines > 0 and table.concat(lines, "\n") or nil, #lines
    end
    
    local function getMissionState()
        local ok, state = pcall(function()
            return game:GetService("Players").LocalPlayer.PlayerGui.Interface.Rewards.Main.Info.State.Text
        end)
        return ok and state or ""
    end
    
    local function formatModifiersText(modifiers)
        local order = {
            "No Perks", "No Skills", "No Memories", "Nightmare", "Oddball",
            "Injury Prone", "Chronic Injuries", "Fog", "Glass Cannon", "Time Trial", "Boring", "Simple"
        }
        if not modifiers or type(modifiers) ~= "table" then return "None" end
        local modList = {}
        for k, v in pairs(modifiers) do
            if type(k) == "number" then modList[#modList+1] = tostring(v)
            elseif type(v) == "boolean" and v then modList[#modList+1] = tostring(k)
            elseif type(v) == "string" then modList[#modList+1] = v end
        end
        local sortedMods = {}
        for _, modName in ipairs(order) do
            for _, m in ipairs(modList) do
                if m == modName then table.insert(sortedMods, m) break end
            end
        end
        for _, m in ipairs(modList) do
            local found = false
            for _, ordered in ipairs(order) do if m == ordered then found = true break end end
            if not found then table.insert(sortedMods, m) end
        end
        if #sortedMods == 0 then return "None" end
        return "- " .. table.concat(sortedMods, "\n- ")
    end
    
    local function sendMissionEndWebhook(missionState)
        if webhookURL == "" then return end
        
        local serverData = waitForServerData(3)
        if not serverData or not serverData.Slots then
            task.wait(0.5)
            serverData = waitForServerData(1)
        end
        waitForUIElements(2)
        local player = game:GetService("Players").LocalPlayer
        if not serverData then
            pcall(function()
                local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
                serverData = GET:InvokeServer("Data", "Copy")
            end)
        end
        if not serverData or not serverData.Slots then return end
        local slot = serverData.Slots[serverData.Current_Slot or "A"]
        if not slot then return end
        local fields = {}
        if serverData.Map then
            local modsText = formatModifiersText(serverData.Map.Modifiers)
            local mapValue = string.format("Map: %s\nDifficulty: %s\nObjective: %s\n\nModifiers:\n%s",
                serverData.Map.Map or "Unknown",
                serverData.Map.Difficulty or "Unknown",
                serverData.Map.Objective or "Unknown",
                modsText)
            table.insert(fields, {name = "Mission Info", value = mapValue, inline = false})
        end
        if filters.Currency then
            table.insert(fields, {name = "Currency", value = string.format("Gold: %s\nGems: %s\nCanes: %s\nShards: %s",
                fmt(slot.Currency and slot.Currency.Gold or 0),
                fmt(slot.Currency and slot.Currency.Gems or 0),
                fmt(slot.Currency and slot.Currency.Canes or 0),
                fmt(slot.Currency and slot.Currency.Shards or 0)), inline = true})
        end
        if filters.Progression then
            table.insert(fields, {name = "Progression", value = string.format("Level: %s\nPrestige: %s\nXP: %s/%s",
                slot.Progression and slot.Progression.Level or 0,
                slot.Progression and slot.Progression.Prestige or 0,
                fmt(slot.Progression and slot.Progression.XP or 0),
                fmt(slot.Progression and slot.Progression.Max_XP or 0)), inline = true})
        end
        if filters.Loadout then
            table.insert(fields, {name = "Loadout", value = string.format("Weapon: %s\nSlot: %s\nSpins: %s",
                slot.Weapon or "?",
                serverData.Current_Slot or "A",
                fmt(slot.Total_Spins or 0)), inline = true})
        end
        if filters.Inventory and slot.Inventory and slot.Inventory.Items then
            local text, count = getItems(slot.Inventory.Items, "• ")
            if text then table.insert(fields, {name = "Inventory ("..count.." items)", value = ""..text.."", inline = false}) end
        end
        if filters.Cosmetics and slot.Inventory and slot.Inventory.Cosmetics then
            local text, count = getItems(slot.Inventory.Cosmetics, "• ")
            if text then table.insert(fields, {name = "Cosmetics ("..count.." items)", value = ""..text.."", inline = false}) end
        end
        local isCompleted = missionState and (missionState:find("COMPLETED") or missionState:find("FINISHED"))
        local color = isCompleted and 65280 or 16711680
        local body = game:GetService("HttpService"):JSONEncode({
            embeds = {{
                title = (missionState or "All Data") .. " - " .. player.Name,
                color = color,
                fields = fields,
                footer = {text = os.date("%Y-%m-%d %H:%M:%S")}
            }}
        })
        pcall(function()
            request({Url = webhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
        end)
    end
    
    -- ตรวจจับการเปิด Rewards UI
    task.spawn(function()
        local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
        local rewards = playerGui.Interface.Rewards
        rewards:GetPropertyChangedSignal("Visible"):Connect(function()
            if not rewards.Visible then
                hasSentWebhook = false
                lastMissionState = ""
                return
            end
            if not webhookEnabled then return end
            if hasSentWebhook then return end
            if webhookURL == "" then return end
            task.wait(2.5)
            if webhookMode == "Reward Webhook" then
                sendRewardWebhook()
                hasSentWebhook = true
            else
                local missionState = getMissionState()
                if missionState == lastMissionState and missionState ~= "" then return end
                lastMissionState = missionState
                sendMissionEndWebhook(missionState)
                hasSentWebhook = true
            end
        end)
    end)
    
    -- ========== UI Components ==========
    WebhookGroup:AddInput("WebhookURL", {
        Default = "", Numeric = false, Finished = true,
        Text = "Discord Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(v) webhookURL = v end
    })
    
    WebhookGroup:AddDivider()
    
    WebhookGroup:AddDropdown("WebhookMode", {
        Text = "Webhook Type",
        Values = {"All Data", "Reward Webhook"},
        Default = "All Data",
        Multi = false,
        Callback = function(v) webhookMode = v end
    })
    
    -- ========== Dropdown สำหรับเลือก Ping Mode (ใช้ได้กับ Reward Webhook เท่านั้น) ==========
    WebhookGroup:AddDropdown("WebhookPingMode", {
        Text = "Ping Mode (For Special Drops)",
        Values = {"None", "@here", "@everyone"},
        Default = "None",
        Multi = false,
        Callback = function(v)
            webhookPingMode = v
        end
    })
    
    WebhookGroup:AddDivider()
    
    local filterDropdown = WebhookGroup:AddDropdown("WebhookFilters", {
        Values = {"Currency", "Progression", "Loadout", "Inventory", "Cosmetics"},
        Default = {"Currency", "Progression", "Loadout", "Inventory", "Cosmetics"},
        Multi = true,
        Text = "Report Only for All Data ",
        Callback = function(v)
            filters.Currency = v["Currency"] or false
            filters.Progression = v["Progression"] or false
            filters.Loadout = v["Loadout"] or false
            filters.Inventory = v["Inventory"] or false
            filters.Cosmetics = v["Cosmetics"] or false
        end
    })
    
    WebhookGroup:AddDivider()
    
    WebhookGroup:AddToggle("WebhookToggle", {
        Text = "Enable Auto Webhook",
        Default = false,
        Callback = function(v)
            webhookEnabled = v
            if not v then 
                hasSentWebhook = false
                lastMissionState = ""
            end
        end
    })
    
    WebhookGroup:AddButton("Test Send", function()
        if webhookURL == "" then return end
        local testBody = game:GetService("HttpService"):JSONEncode({
            content = "Test from FakeHUB!",
            embeds = {{
                title = "Webhook Working!",
                color = 65280,
                fields = {
                    {name = "Mode", value = webhookMode, inline = true},
                    {name = "Ping Mode", value = webhookPingMode, inline = true},
                    {name = "Test Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true}
                },
                footer = {text = "FakeHUB Webhook Test"}
            }}
        })
        pcall(function()
            request({Url = webhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = testBody})
            Library:Notify("Test webhook sent!", 2)
        end)
    end)
end


-- ============================== SET DESCRIPTION (INGAME) ==============================
if IsIngameLobby() and Tabs.Webhook then
    local descGroup = Tabs.Webhook:AddRightGroupbox("Set Description")

    -- ฟังก์ชันจัดรูปแบบตัวเลข
    local function formatNumber(n)
        if type(n) ~= "number" then return "0" end
        return tostring(n):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    end

    -- ฟังก์ชันดึงเวลาประเทศไทย (GMT+7)
    local function getThaiTime()
        local utcHour = tonumber(os.date("!%H"))
        local utcMin  = tonumber(os.date("!%M"))
        local thaiHour = (utcHour + 7) % 24
        return string.format("%02d:%02d", thaiHour, utcMin)
    end

    -- รายการประเภท Description
    local descriptionTypes = {
        "Horst Description",
    }

    local selectedType = descriptionTypes[1]

    descGroup:AddDropdown("DescTypeDropdown", {
        Text = "Description Type",
        Values = descriptionTypes,
        Default = selectedType,
        Multi = false,
        Callback = function(v)
            selectedType = v
        end
    })

    descGroup:AddToggle("SetDescToggle", {
        Text = "Apply Description (once, after 10s)",
        Default = false,
        Callback = function(v)
            if not v then return end

            task.spawn(function()
                task.wait(1)

                if selectedType == "Horst Description" then
                    local success, data = pcall(function()
                        return GET:InvokeServer("Data", "Copy")
                    end)

                    if success and data and data.Slots then
                        local currentSlot = data.Current_Slot or "A"
                        local slotData = data.Slots[currentSlot]

                        if slotData then
                            local level = slotData.Progression and slotData.Progression.Level or 0
                            local prestige = slotData.Progression and slotData.Progression.Prestige or 0
                            local slot = currentSlot
                            local gold = slotData.Currency and slotData.Currency.Gold or 0
                            local gems = slotData.Currency and slotData.Currency.Gems or 0
                            -- 🔥 ใช้ data.Spins แทน slotData.Total_Spins
                            local spins = data.Spins or 0
                            local thaiTime = getThaiTime()

                            local description = string.format(
                                "🎖️ Lv: %d  👑 Prestige: %d  💾 Slot: %s  💰 Gold: %s  💎 Gems: %s  🎲 Spins: %s  🕐 Time: %s",
                                level, prestige, slot, formatNumber(gold), formatNumber(gems), formatNumber(spins), thaiTime
                            )

                            if _G and _G.Horst_SetDescription then
                                _G.Horst_SetDescription(description)
                            end
                        end
                    end
                end

                pcall(function()
                    if Options and Options.SetDescToggle then
                        Options.SetDescToggle:SetValue(false)
                    end
                end)
            end)
        end
    })
end



-- ============================== MISC (SKIP CUTSCENE) ==============================
if Tabs.AutoFarm then
    local MiscGroup = Tabs.AutoFarm:AddRightGroupbox("Skip Cutscene")
    
    local skipEnabled = false
    local skipRunning = false
    
    local Players = game:GetService("Players")
    local GuiService = game:GetService("GuiService")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local lp = Players.LocalPlayer
    
    local function clickSkipButton()
        local playerGui = lp:FindFirstChild("PlayerGui")
        if not playerGui then return false end
        
        local interface = playerGui:FindFirstChild("Interface")
        if not interface then return false end
        
        local skipFrame = interface:FindFirstChild("Skip")
        if not skipFrame or not skipFrame.Visible then return false end
        
        -- หาปุ่ม Interact (ตามตัวอย่างที่ให้มา)
        local interactBtn = skipFrame:FindFirstChild("Interact")
        if not interactBtn or not interactBtn.Visible then return false end
        
        -- ปิดเมนูค้าง (ถ้ามี)
        if GuiService.MenuIsOpen then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
            task.wait(0.1)
        end
        
        -- กดปุ่มโดยใช้ SelectedObject
        GuiService.SelectedObject = interactBtn
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        GuiService.SelectedObject = nil
        
        return true
    end
    
    task.spawn(function()
        local hasClicked = false
        
        while true do
            task.wait(0.5)
            
            if not skipEnabled then
                hasClicked = false
                continue
            end
            
            local interface = lp.PlayerGui:FindFirstChild("Interface")
            local skip = interface and interface:FindFirstChild("Skip")
            if not skip or not skip.Visible then
                hasClicked = false
                continue
            end
            
            if hasClicked then continue end
            
            if clickSkipButton() then
                hasClicked = true
            end
        end
    end)
    
    MiscGroup:AddToggle("SkipCutSceneToggle", {
        Text="Skip Cut Scene",
        Default=false,
        Callback=function(v)
            skipEnabled = v
            if not v then
                skipRunning = false
            end
        end
    })
end

-- ============================== AUTO SPEAR QUEST ==============================
if Tabs.AutoFarm then
    local SpearGroup = Tabs.AutoFarm:AddRightGroupbox("Auto Spear Quest")
    
    local spearQuestEnabled = false
    local spearQuestRunning = false
    
    -- ดึง Remote GET สำหรับเรียก quest
    local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
    
    -- ฟังก์ชันเรียก Update_Spear_Towers 6 ครั้ง
    local function callSpearQuestUpdate()
        for i = 1, 6 do
            if not spearQuestEnabled then break end
            local args = {"Quests", "Update_Spear_Towers", true}
            pcall(function()
                GET:InvokeServer(unpack(args))
            end)
            task.wait(0.2)
        end
    end
    
    SpearGroup:AddToggle("AutoSpearQuestToggle", {
        Text="Auto Spear Quest",
        Default=false,
        Callback=function(v)
            spearQuestEnabled = v
            if v and not spearQuestRunning then
                spearQuestRunning = true
                task.spawn(function()
                    -- เรียก Update_Spear_Towers 6 ครั้ง ก่อนเริ่มเดินเก็บของ
                    callSpearQuestUpdate()
                    
                    -- โค้ดเดิมที่เดินไปเก็บ supplies (ไม่แก้ไข)
                    repeat task.wait() until game.Players.LocalPlayer.Character
                    local hrp = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                    
                    local Unclimbable = workspace:FindFirstChild("Unclimbable")
                    if Unclimbable then
                        local baseCircle = Unclimbable:FindFirstChild("Supplies_Circle")
                        local baseHitbox = baseCircle and baseCircle:FindFirstChild("Hitbox")
                        
                        for lap = 1, 3 do
                            if not spearQuestEnabled then break end
                            
                            local supplies = {}
                            for _, obj in ipairs(Unclimbable:GetChildren()) do
                                if obj.Name:find("ThunderSpear_Supplies") then
                                    table.insert(supplies, obj)
                                end
                            end
                            
                            for _, supply in ipairs(supplies) do
                                if not spearQuestEnabled then break end
                                
                                local hitbox = supply:FindFirstChild("Hitbox")
                                if hitbox and hitbox.Parent then
                                    hrp.CFrame = hitbox.CFrame
                                    hrp.Velocity = Vector3.zero
                                    hrp.RotVelocity = Vector3.zero
                                    task.wait(0.5)
                                end
                                
                                if baseHitbox and baseHitbox.Parent then
                                    hrp.CFrame = baseHitbox.CFrame
                                    hrp.Velocity = Vector3.zero
                                    hrp.RotVelocity = Vector3.zero
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                    
                    spearQuestRunning = false
                    if spearQuestEnabled then
                        spearQuestEnabled = false
                        pcall(function()
                            SpearGroup:GetToggle("AutoSpearQuestToggle"):SetValue(false)
                        end)
                    end
                end)
            else
                spearQuestRunning = false
            end
        end
    })
end

-- ============================== WAVE TAB ==============================
if IsIngameLobby() then

    local WaveGroup = Tabs.Safety:AddLeftGroupbox("Wave")

    local autoVoteSkip = false

    task.spawn(function()

        while true do
            task.wait(1)

            if not autoVoteSkip then
                continue
            end

            pcall(function()

                local args = {
                    "Waves",
                    "Update"
                }

                game:GetService("ReplicatedStorage")
                    :WaitForChild("Assets")
                    :WaitForChild("Remotes")
                    :WaitForChild("POST")
                    :FireServer(unpack(args))

            end)
        end

    end)

    WaveGroup:AddToggle("AutoVoteSkipToggle", {
        Text = "Auto Vote Skip",
        Default = false,

        Callback = function(v)
            autoVoteSkip = v
        end
    })

end

