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
    Tabs.Session = Window:AddTab("Skill")
    Tabs.Trade = Window:AddTab("Trade")
end
if IsIngameLobby() then
    Tabs.AutoFarm = Window:AddTab("Auto Farm")
    Tabs.Safety = Window:AddTab("Wave")
    Tabs.Webhook = Window:AddTab("Webhook")
end




-- ============================== WEBHOOK TAB + AUTO NOTIFY ON TARGET FAMILY ==============================
if IsMainmenuLobby() then
    Tabs.Webhook = Window:AddTab("Webhook")

    local WebhookGroup = Tabs.Webhook:AddLeftGroupbox("Webhook")

    local webhookURL = ""
    local autoNotifyEnabled = false

    -- ส่งได้ครั้งเดียวต่อการเปิด Toggle 1 ครั้ง
    local hasSentThisToggle = false

    local lastNotifyFamily = ""
    local lastNotifyTime = 0
    local pingMode = "None"

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    local function GetCurrentFamily()
        local ok, result = pcall(function()
            return PlayerGui.Interface.Customisation.Family.Family.Title.Text
        end)
        return ok and result or "Unknown"
    end

    local function GetSpinCount()
        local ok, result = pcall(function()
            return PlayerGui.Interface.Customisation.Family.Buttons_2.Roll.Title.Text
        end)
        return ok and result or "Unknown"
    end

    local function GetStoredFamilies()
        local data = {}
        local count = 0

        local ok, familiesFolder = pcall(function()
            return PlayerGui.Interface.Customisation.Storage.Main.Families
        end)

        if not ok or not familiesFolder then
            return data, count
        end
        
        for _, v in ipairs(familiesFolder:GetChildren()) do
            pcall(function()

                local inner = v:FindFirstChild("Inner")

                if inner then
                    local title = inner:FindFirstChild("Title")

                    if title
                        and title:IsA("TextLabel")
                        and title.Text
                        and title.Text ~= ""
                    then
                        local fullText = title.Text

                        table.insert(data, fullText)

                        count = count + 1
                    end
                end

            end)
        end
        
        return data, count
    end

    local function SendWebhook(triggerReason)

        if webhookURL == "" then
            return false
        end

        local currentFamily = GetCurrentFamily()
        local spins = GetSpinCount()

        local familyList, familyCount = GetStoredFamilies()

        local storedText =
            #familyList > 0
            and table.concat(familyList, "\n")
            or "None"

        local title = triggerReason or "Notify"

        local color = triggerReason and 65280 or 16766720
        
        local content = nil

        if pingMode == "Everyone" then
            content = "@everyone"

        elseif pingMode == "Here" then
            content = "@here"
        end

        local body = game:GetService("HttpService"):JSONEncode({
            content = content,

            embeds = {{
                title = title,

                color = color,

                fields = {
                    {
                        name = "Current Family",
                        value = "```" .. currentFamily .. "```",
                        inline = true
                    },

                    {
                        name = "Spins Left",
                        value = "```" .. spins .. "```",
                        inline = true
                    },

                    {
                        name = "Stored Families (" .. familyCount .. ")",
                        value = "```" .. storedText .. "```",
                        inline = false
                    }
                },

                footer = {
                    text = "FakeHUB | "
                        .. os.date("%Y-%m-%d %H:%M:%S")
                }
            }}
        })

        local requestFunction =
            (syn and syn.request)
            or (http and http.request)
            or http_request
            or request

        if not requestFunction then
            return false
        end

        return pcall(function()

            requestFunction({
                Url = webhookURL,

                Method = "POST",

                Headers = {
                    ["Content-Type"] = "application/json"
                },

                Body = body
            })

        end)
    end

    -- ============================== MAIN LOOP ==============================
    task.spawn(function()

        while true do
            task.wait(3)

            if not autoNotifyEnabled or webhookURL == "" then
                continue
            end

            -- ส่งได้ครั้งเดียวต่อการเปิด Toggle
            if hasSentThisToggle then
                continue
            end
            
            local currentFamily = GetCurrentFamily()

            if currentFamily == "Unknown" then
                continue
            end
            
            local targetFamilies = {}

            if Options and Options.AutoSpinFamilies then

                for name, enabled in pairs(
                    Options.AutoSpinFamilies.Value or {}
                ) do

                    if enabled
                        and not string.match(name, "^%-%-%-")
                    then
                        table.insert(targetFamilies, name)
                    end
                end
            end
            
            if #targetFamilies == 0 then
                continue
            end
            
            local isTarget = false

            local lowerFamily = string.lower(currentFamily)

            for _, target in ipairs(targetFamilies) do

                if string.find(
                    lowerFamily,
                    string.lower(target)
                ) then
                    isTarget = true
                    break
                end
            end
            
            -- ของเดิมยังอยู่ครบ
            if isTarget and (
                currentFamily ~= lastNotifyFamily
                or (tick() - lastNotifyTime > 30)
            ) then

                local success = SendWebhook(
                    "TARGET FAMILY FOUND: " .. currentFamily
                )

                if success then

                    -- เพิ่มแค่ตัวนี้
                    hasSentThisToggle = true

                    lastNotifyFamily = currentFamily
                    lastNotifyTime = tick()
                end
            end

        end

    end)

    -- ============================== INPUT ==============================
    WebhookGroup:AddInput("Webhook_URL", {
        Default = "",
        Numeric = false,
        Finished = true,

        Text = "Discord Webhook URL",

        Placeholder = "https://discord.com/api/webhooks/...",

        Callback = function(v)
            webhookURL = v
        end
    })

    -- ============================== PING MODE ==============================
    WebhookGroup:AddDropdown("Webhook_PingMode", {

        Text = "Ping Mode",

        Values = {
            "None",
            "Everyone",
            "Here"
        },

        Default = "None",

        Multi = false,

        Callback = function(v)
            pingMode = v
        end
    })

    -- ============================== TEST ==============================
    WebhookGroup:AddButton("Test Send", function()
        if SendWebhook() then end
    end)

    -- ============================== TOGGLE ==============================
    WebhookGroup:AddToggle("AutoNotifyToggle", {

        Text = "Auto Send Families",

        Default = false,

        Callback = function(v)

            autoNotifyEnabled = v

            -- reset ใหม่ทุกครั้งที่เปิด toggle
            if v then
                hasSentThisToggle = false
                lastNotifyFamily = ""
                lastNotifyTime = 0
            end

        end
    })
end
-- ============================== AUTO SPIN (MAIN MENU) - FAMILY TAB CHECK BEFORE ROLL ==============================
if IsMainmenuLobby() then
    local SpinGroup = Tabs.MainMenu:AddLeftGroupbox("Auto Spin")

    local selectedFamilies = {}
    local isSpinning = false
    local stopSpin = false
    local rollDelay = 0.01
    local lastSlotNotify = 0

    local player = game:GetService("Players").LocalPlayer
    local VIM = game:GetService("VirtualInputManager")
    local GS = game:GetService("GuiService")
    local playerGui = player:WaitForChild("PlayerGui")

    local FAMILY_LIST = {
        "--- Common ---",
        "Reeves","Blouse","Inocenio","Munsell","Boyega","Ral","Bozado","Pikale","Hume","Iglehaut",
        "--- Rare ---",
        "Braus","Kruger","Azumabito","Smith","Grice","Springer","Kirstein",
        "--- Epic ---",
        "Galliard","Zoe","Leonhart","Tybur","Ksaver","Braun","Finger","Arlert",
        "--- Legendary ---",
        "Yeager","Ackerman","Reiss",
        "--- Mythic ---",
        "Fritz","Helos",
    }
    
    local function isHeader(name)
        return string.sub(name, 1, 3) == "---"
    end

    local function getInterface()
        return playerGui:FindFirstChild("Interface")
    end

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

    local function getClickable(obj)
        if not obj then return nil end
        local interact = obj:FindFirstChild("Interact")
        if interact and interact:IsA("GuiObject") then return interact end
        return obj
    end

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

    local function press(target)
        target = getClickable(target)
        if not target then return false end
        if not isGuiVisible(target) then return false end
        pcall(function() target.Selectable = true end)
        GS.SelectedObject = nil; task.wait(0.005)
        GS.SelectedObject = target; task.wait(0.005)
        if GS.SelectedObject ~= target then return false end
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game); task.wait(0.005)
        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game); task.wait(0.005)
        GS.SelectedObject = nil
        return true
    end

    local function ensureFamilyTabAndCheckTitle()
        local familyBtn = getFamilyBtn()
        
        if not isGuiVisible(familyBtn) then
            local customBtn = getCustomBtn()
            if isGuiVisible(customBtn) then
                press(customBtn); task.wait(0.1)
            end
            local t = tick()
            while tick() - t < 3 do
                if isGuiVisible(getFamilyBtn()) then break end
                task.wait(0.05)
            end
        end
        
        familyBtn = getFamilyBtn()
        if isGuiVisible(familyBtn) then
            press(familyBtn)
            task.wait(0.1)
        end
        
        local titleChecked = false
        local startCheck = tick()
        
        for i = 1, 10 do
            if tick() - startCheck > 3 then break end
            
            local title = getFamilyTitle()
            if title and title:IsA("TextLabel") and title.Visible and title.Text ~= "" then
                titleChecked = true
                break
            end
            
            familyBtn = getFamilyBtn()
            if isGuiVisible(familyBtn) then
                press(familyBtn)
            end
            task.wait(0.1)
        end
        
        return titleChecked
    end

    local function ensureUIOpen()
        local rollBtn = getRollBtn()
        
        if isGuiVisible(rollBtn) then
            local storageBtn = getStorageBtn()
            local storageUI = getStorageUI()
            if isGuiVisible(storageBtn) and not isGuiVisible(storageUI) then
                press(storageBtn)
                local t = tick()
                while tick() - t < 1 do
                    if isGuiVisible(getStorageUI()) then break end
                    task.wait(0.05)
                end
            end
            return true
        end
        
        local customBtn = getCustomBtn()
        if isGuiVisible(customBtn) then
            press(customBtn); task.wait(0.1)
        end
        
        local t = tick()
        while tick() - t < 3 do
            if isGuiVisible(getFamilyBtn()) then break end
            task.wait(0.05)
        end
        
        local familyBtn = getFamilyBtn()
        if not isGuiVisible(familyBtn) then return false end
        
        if not isGuiVisible(getRollBtn()) then
            press(familyBtn)
            local t2 = tick()
            while tick() - t2 < 1 do
                if isGuiVisible(getRollBtn()) then break end
                task.wait(0.05)
            end
        end
        
        local storageBtn = getStorageBtn()
        local storageUI = getStorageUI()
        if isGuiVisible(storageBtn) and not isGuiVisible(storageUI) then
            press(storageBtn)
            local t3 = tick()
            while tick() - t3 < 1 do
                if isGuiVisible(getStorageUI()) then break end
                task.wait(0.05)
            end
        end
        
        return isGuiVisible(getRollBtn())
    end

    local function getCurrentFamily()
        local title = getFamilyTitle()
        if title and title:IsA("TextLabel") and title.Visible then
            return title.Text
        end
        return nil
    end

    local function getSpinCount()
        local rollBtn = getRollBtn()
        if not isGuiVisible(rollBtn) then return -1 end
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
        local lower = string.lower(name)
        for _, t in ipairs(selectedFamilies) do 
            if string.find(lower, string.lower(t)) then return true end 
        end
        return false
    end

    local function autoSpinLoop()
        if isSpinning then return end
        isSpinning = true; stopSpin = false

        if #selectedFamilies == 0 then 
            isSpinning = false
            Options.AutoSpinToggle:SetValue(false)
            return 
        end

        while not stopSpin do
            if isAnySlotOpen() then
                task.wait(0.5)
                continue
            end

            if not isGuiVisible(getRollBtn()) then
                if not ensureUIOpen() then
                    task.wait(0.1)
                    continue
                end
            else
                ensureUIOpen()
            end

            if not ensureFamilyTabAndCheckTitle() then
                task.wait(0.5)
                continue
            end

            local currentFamily = getCurrentFamily()
            if currentFamily and isTargetFamily(currentFamily) then
                stopSpin = true; break
            end

            if getSpinCount() == 0 then 
                break 
            end

            local rb = getRollBtn()
            if not isGuiVisible(rb) then continue end
            
            if not press(rb) then task.wait(0.01); continue end

            task.wait(rollDelay)

            local newFamily
            for i = 1, 5 do
                newFamily = getCurrentFamily()
                if newFamily then break end
                task.wait(0.01)
            end

            if newFamily and isTargetFamily(newFamily) then 
                stopSpin = true; break 
            end

            task.wait(0.001)
        end

        isSpinning = false
        Options.AutoSpinToggle:SetValue(false)
    end

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
            if v then task.spawn(autoSpinLoop) else stopSpin = true end
        end
    })
end
-- ============================== TRADE SYSTEM ==============================
if IsLobbyLobby() then
    task.defer(function()
        local file1 = "FakeHUB/saved_players.txt"
        local file2 = "FakeHUB/saved_players_2.txt"

        local function loadList(f) local t={} if isfile(f) then for n in string.gmatch(readfile(f),"[^\r\n]+") do n=n:gsub("^%s+",""):gsub("%s+$","") if n~="" then table.insert(t,n) end end end return t end
        local function saveList(f,t) writefile(f,table.concat(t,"\n")) end
        local function addName(f,n) n=n:gsub("^%s+",""):gsub("%s+$","") if n=="" then return false end local t=loadList(f) for _,v in ipairs(t) do if v:lower()==n:lower() then return false end end table.insert(t,n) saveList(f,t) return true end
        local function addMulti(f,s) local a,d=0,0 for n in string.gmatch(s,"[^,;\r\n%s]+") do if addName(f,n) then a=a+1 else d=d+1 end end return a,d end
        local function removeName(f,n) local t=loadList(f) local r={} for _,v in ipairs(t) do if v~=n then table.insert(r,v) end end saveList(f,r) end
        local function toList(v) local r={} if type(v)=="table" then for k,e in pairs(v) do if e then table.insert(r,k) end end end return r end
        local function inGame(n) if n:lower()==Player.Name:lower() then return false end for _,p in ipairs(Players:GetPlayers()) do if p~=Player and p.Name:lower()==n:lower() then return true end end return false end
        local function filterOnline(l) local o={} for _,n in ipairs(l) do if n~="No Players" and n:lower()~=Player.Name:lower() and inGame(n) then table.insert(o,n) end end return o end
        
        local function selectAllFromFile(file)
            local all = loadList(file)
            local newVal = {}
            for _, name in ipairs(all) do
                newVal[name] = true
            end
            return newVal
        end

        local function isTradeOpen()
            local ok, r = pcall(function() return Player.PlayerGui.Interface.Trading.Prompt.Visible end)
            return ok and r
        end

        local sendCooldown, acceptCooldown = {}, {}
        local lastSend, lastAccept = 0, 0
        
        local function clearCooldownForPlayer(name)
            sendCooldown[name] = nil
            acceptCooldown[name] = nil
        end
        
        local trackedPlayers = {}
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
        
        local function sendTrade(n)
            if n:lower()==Player.Name:lower() or not inGame(n) then return end
            local now = tick()
            if sendCooldown[n] and now-sendCooldown[n] < 1.5 then return end
            if now-lastSend < 0.35 then return end
            lastSend, sendCooldown[n] = now, now
            pcall(function() POST:FireServer("Invites","Invite",n) end)
        end
        
        local function acceptTrade(n)
            if n:lower()==Player.Name:lower() or not inGame(n) then return end
            local now = tick()
            if acceptCooldown[n] and now-acceptCooldown[n] < 1 then return end
            if now-lastAccept < 0.25 then return end
            lastAccept, acceptCooldown[n] = now, now
            pcall(function() POST:FireServer("Invites","State",n,"Accept") end)
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
            
            box:AddToggle(cacheName.."_Send", {Text="Send Trade", Default=false, Callback=function(v)
                sendToggle.Enabled = v
                if v then buildSendLoop(getCache)(sendToggle) end
            end})
            box:AddToggle(cacheName.."_Accept", {Text="Auto Accept", Default=false, Callback=function(v)
                acceptToggle.Enabled = v
                if v then buildAcceptLoop(getCache)(acceptToggle) end
            end})
        end

        local function buildSavedBox(title, file, cacheName)
            local State = {}
            local box = Tabs.Trade:AddLeftGroupbox(title)
            local dd = box:AddDropdown(cacheName.."_Dropdown", {Text="Players", Values=loadList(file), Multi=true, Default={}, Callback=function(v) State.Cache=v end})
            
            local inputField = box:AddInput(cacheName.."_Input", {
                Text = "Add Users",
                Placeholder = "name1, name2",
                Default = "",
                Callback = function(v)
                    State.Input = v
                end
            })
            
            box:AddButton("Save", function()
                local inputText = State.Input or ""
                if inputText ~= "" then
                    addMulti(file, inputText)
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
                for _, n in ipairs(toList(State.Cache)) do removeName(file, n) end
                dd:SetValues(loadList(file))
            end)
            
            box:AddButton("Select All", function()
                local allSelected = selectAllFromFile(file)
                dd:SetValue(allSelected)
                State.Cache = allSelected
            end)
            
            box:AddButton("Deselect All", function()
                dd:SetValue({})
                State.Cache = {}
            end)
            
            box:AddButton("Refresh", function() dd:SetValues(loadList(file)) end)
            addToggles(box, cacheName, function() return State.Cache end)
        end

        local currentState = { Cache = nil }
        local g1 = Tabs.Trade:AddLeftGroupbox("Current Players")
        local cd = g1:AddDropdown("Trade_CurrentDropdown", {Text="Online", Values={"No Players"}, Multi=true, Default={}, Callback=function(v) currentState.Cache=v end})
        
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

        task.spawn(function()
            while true do
                task.wait(1.5)
                pcall(function()
                    local f = {}
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= Player then table.insert(f, p.Name) end
                    end
                    cd:SetValues(#f > 0 and f or {"No Players"})
                end)
            end
        end)
    end)
end
-- ============================== AUTO TELEPORT TO PLAYER (ADDGROUP) ==============================
if IsLobbyLobby() then
    task.spawn(function()
        while not Tabs.Trade do task.wait(0.1) end

        local TeleportGroup = Tabs.Trade:AddLeftGroupbox("Auto Teleport To Player")

        local isEnabled = false
        local targetUsername = ""
        local minMemoryScroll = 2
        local lastTeleportTime = 0
        local TELEPORT_COOLDOWN = 3
        local hasStopped = false
        local hasNotifiedInsufficient = false
        local hasCheckedMemoryThisSession = false  -- เช็คว่าเช็ค Memory ไปแล้วหรือยัง

        local VIM = game:GetService("VirtualInputManager")
        local GS = game:GetService("GuiService")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer

        -- โหลดค่าจาก Config
        local CONFIG_FILE = "FakeHUB/teleport_to_player_config.json"
        if isfile(CONFIG_FILE) then
            pcall(function()
                local data = game:GetService("HttpService"):JSONDecode(readfile(CONFIG_FILE))
                targetUsername = data.targetUsername or ""
                isEnabled = data.isEnabled or false
                minMemoryScroll = data.minMemoryScroll or 2
            end)
        end

        local function saveConfig()
            local data = {
                targetUsername = targetUsername,
                isEnabled = isEnabled,
                minMemoryScroll = minMemoryScroll,
                lastSaved = os.date("%Y-%m-%d %H:%M:%S")
            }
            pcall(function()
                if not isfolder("FakeHUB") then makefolder("FakeHUB") end
                writefile(CONFIG_FILE, game:GetService("HttpService"):JSONEncode(data))
            end)
        end

        -- หยุดการทำงานทั้งหมดทันที
        local function stopAllAndDisable()
            if hasStopped then return end
            hasStopped = true
            isEnabled = false
            pcall(function()
                if Options and Options.TeleportToPlayer_AutoToggle then
                    Options.TeleportToPlayer_AutoToggle:SetValue(false)
                end
            end)
            Library:Notify("🛑 System STOPPED - Same server as target & Memory verified", 3)
        end

        -- รีเซ็ตสถานะ
        local function resetNotificationState()
            hasNotifiedInsufficient = false
            hasStopped = false
            hasCheckedMemoryThisSession = false
        end

        local function clickButton(target)
            if not target or not target.Visible then return false end
            
            local obj = target
            while obj and obj ~= player.PlayerGui do
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

        local function clickOkButton()
            pcall(function()
                local dialog = game:GetService("CoreGui").RobloxGui.FocusNavigationCoreScriptsWrapper.Dialog
                if not dialog or not dialog.Visible then return false end
                
                local okButton = dialog.DialogContentWrapper.Dialog.DialogInner.DialogBody.DialogActions.ActionsContainer:FindFirstChild("1-OK")
                if okButton and okButton.Visible then
                    return clickButton(okButton)
                end
            end)
            return false
        end

        -- เช็ค Memory Scroll เพียงครั้งเดียว (ไม่กดซ้ำ)
        local function checkMemoryScrollOnce()
            if hasCheckedMemoryThisSession then
                return true  -- เช็คไปแล้ว ข้าม
            end
            
            local inventoryIcon = player.PlayerGui.Interface.Topbar.Main.Categories.Inventory
            if not inventoryIcon then 
                return false 
            end
            
            -- เปิด Inventory แค่ครั้งเดียว
            clickButton(inventoryIcon)
            task.wait(0.5)
            
            local count = 0
            local found = false
            
            for retry = 1, 5 do
                pcall(function()
                    local scroll = player.PlayerGui.Interface.Inventory.Main.Holder.Items["605 - Memory Scroll"]
                    if scroll then
                        local main = scroll:FindFirstChild("Main")
                        if main then
                            local inner = main:FindFirstChild("Inner")
                            if inner then
                                local quantity = inner:FindFirstChild("Quantity")
                                if quantity and quantity:IsA("TextLabel") and quantity.Text then
                                    local text = quantity.Text
                                    count = tonumber(text:match("%d+")) or 0
                                    found = true
                                end
                            end
                        end
                    end
                end)
                if found then break end
                task.wait(0.3)
            end
            
            -- ปิด Inventory
            task.wait(0.2)
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            task.wait(0.2)
            
            -- บันทึกว่าเช็คแล้ว
            hasCheckedMemoryThisSession = true
            
            if count < minMemoryScroll then
                if not hasNotifiedInsufficient then
                    Library:Notify("📦 Memory Scroll: " .. count .. " / Required: " .. minMemoryScroll .. " (Insufficient)", 3)
                    hasNotifiedInsufficient = true
                end
                return false
            else
                if hasNotifiedInsufficient then
                    hasNotifiedInsufficient = false
                end
                Library:Notify("📦 Memory Scroll: " .. count .. " (Sufficient)", 2)
                return true
            end
        end

        local function TeleportToPlayer(username)
            if not username or username == "" then 
                return false 
            end
            
            -- 1. คลิกปุ่ม Friends
            local friendsIcon = player.PlayerGui.Interface.Topbar.Main.Icons.Friends
            if not friendsIcon then return false end
            clickButton(friendsIcon)
            task.wait(0.5)
            
            -- 2. คลิกที่ช่อง Entered
            local entered = player.PlayerGui.Interface.Friends.Main.Details.Main.Entered
            if not entered then return false end
            
            local interact = entered:FindFirstChild("Interact")
            clickButton(interact or entered)
            task.wait(0.5)
            
            -- 3. ใส่ Username ลงใน TextBox โดยตรง
            local textBox = entered:FindFirstChild("Input") or 
                            entered:FindFirstChild("TextBox") or 
                            entered:FindFirstChild("Text") or
                            entered:FindFirstChildWhichIsA("TextBox")
            
            if textBox and textBox:IsA("TextBox") then
                textBox.Text = username
                task.wait(0.1)
                local changeEvent = textBox.Changed:Connect(function() end)
                changeEvent:Disconnect()
            else
                for i = 1, #username do
                    local char = string.sub(username, i, i)
                    local keyCode = nil
                    
                    if char:match("[A-Za-z]") then
                        if char:match("[A-Z]") then
                            VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
                        end
                        keyCode = Enum.KeyCode[string.upper(char)]
                    elseif char:match("[0-9]") then
                        local numMap = {["0"]="Zero", ["1"]="One", ["2"]="Two", ["3"]="Three", ["4"]="Four", 
                                       ["5"]="Five", ["6"]="Six", ["7"]="Seven", ["8"]="Eight", ["9"]="Nine"}
                        keyCode = Enum.KeyCode[numMap[char]]
                    elseif char == "_" then
                        keyCode = Enum.KeyCode.Minus
                        VIM:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
                    end
                    
                    if keyCode then
                        VIM:SendKeyEvent(true, keyCode, false, game)
                        task.wait(0.03)
                        VIM:SendKeyEvent(false, keyCode, false, game)
                        if char:match("[A-Z]") or char == "_" then
                            task.wait(0.02)
                            VIM:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
                        end
                    end
                    task.wait(0.05)
                end
            end
            
            task.wait(0.3)
            
            -- 4. กด Enter เพื่อส่งและเทเลพอร์ต
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            
            return true
        end

        local function isPlayerInGame(username)
            if not username or username == "" then return false end
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower() == username:lower() then
                    return true
                end
            end
            return false
        end

        -- UI Elements
        TeleportGroup:AddInput("TeleportToPlayer_Username", {
            Text = "Target Username",
            Placeholder = "Enter username...",
            Default = targetUsername,
            Callback = function(v)
                targetUsername = v
                saveConfig()
                resetNotificationState()
            end
        })

        TeleportGroup:AddSlider("TeleportToPlayer_MinScrolls", {
            Text = "Min Memory Scroll Required",
            Default = minMemoryScroll,
            Min = 0,
            Max = 500,
            Rounding = 0,
            Callback = function(v)
                minMemoryScroll = v
                saveConfig()
                resetNotificationState()
            end
        })

        TeleportGroup:AddToggle("TeleportToPlayer_AutoToggle", {
            Text = "Auto Teleport When Not In Same Server",
            Default = isEnabled,
            Callback = function(v)
                if hasStopped then
                    Library:Notify("⚠️ System already stopped", 2)
                    return
                end
                isEnabled = v
                saveConfig()
                if v then
                    Library:Notify("✅ Auto Teleport ENABLED", 2)
                    resetNotificationState()
                else
                    Library:Notify("⚠️ Auto Teleport DISABLED", 2)
                end
            end
        })

        -- Main Loop
        task.spawn(function()
            while true do
                task.wait(5)
                
                if hasStopped then continue end
                clickOkButton()
                
                if not isEnabled then continue end
                if targetUsername == "" then continue end
                
                -- ถ้าอยู่เซิฟเดียวกันกับเป้าหมาย
                if isPlayerInGame(targetUsername) then
                    -- เช็ค Memory Scroll แค่ครั้งเดียว
                    local memoryEnough = checkMemoryScrollOnce()
                    if memoryEnough then
                        -- ถ้า Memory เพียงพอ และอยู่เซิฟเดียวกัน → หยุดการทำงานทั้งหมดทันที
                        stopAllAndDisable()
                    end
                    continue
                end
                
                -- ถ้ายังไม่เคยเช็ค Memory มาก่อน และไม่อยู่ในเซิฟเดียวกัน
                if not hasCheckedMemoryThisSession then
                    if not checkMemoryScrollOnce() then
                        -- Memory ไม่พอ หยุดทำงาน
                        hasStopped = true
                        isEnabled = false
                        continue
                    end
                end
                
                if tick() - lastTeleportTime < TELEPORT_COOLDOWN then continue end
                
                local success = TeleportToPlayer(targetUsername)
                if success then
                    lastTeleportTime = tick()
                end
            end
        end)
        
        -- Auto Click OK Loop
        task.spawn(function()
            while true do
                task.wait(1)
                if hasStopped then continue end
                clickOkButton()
            end
        end)
    end)
end
-- ============================== TRADE BOX DETECTOR + AUTO ADD ==============================
if IsLobbyLobby() then
    task.spawn(function()
        while not Tabs.Trade do
            task.wait(0.1)
        end

        local TradeDetectorBox = Tabs.Trade:AddRightGroupbox("Trade Box Detector")

        local Players = game:GetService("Players")
        local GuiService = game:GetService("GuiService")
        local VirtualInputManager = game:GetService("VirtualInputManager")

        local player = Players.LocalPlayer

        local isDetectorEnabled = false
        local wasBoxOpen = false
        local selectedSide = "Receiver"
        local selectedItems = {"Memory Scroll"}
        local selectedCosmetics = {}
        local addAmountItems = 1
        local addAmountCosmetics = 0
        local isAdding = false
        local lastConfirmClick = 0
        local CONFIRM_COOLDOWN = 0.5

        local readyLoopRunning = false
        local readyLoopToggle = { Enabled = false }

        local stallStartTime = 0
        local STALL_TIMEOUT = 5

        local ADD_DELAY = 0.008
        local PANEL_WAIT = 0.2
        local CLICK_WAIT = 0.05
        local RETRY_WAIT = 0.1
        local BATCH_SIZE = 10
        local BATCH_DELAY = 0.02
        local MAX_RETRY_AFTER_STALL = 3
        local READY_LOOP_DELAY = 0.2
        local COSMETICS_MAX = 10

        local OTHER_BOX_CHECK_TIMEOUT = 1.25
        
        -- CLICK MODE
        local clickMode = "Hover"
        local hasHiddenUIThisSession = false

        local HOLDER_NAMES = {
            ["Memory Scroll"] = "600_Memory Scroll",
            ["Emperor's Key"] = "500_Emperor's Key",
        }

        -- ============================== SAFE GUI ==============================

        local function isGuiAlive(obj)
            if not obj then
                return false
            end

            if typeof(obj) ~= "Instance" then
                return false
            end

            if not obj.Parent then
                return false
            end

            local ok = pcall(function()
                return obj.AbsoluteSize
            end)

            if not ok then
                return false
            end

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

        local function safeSelectObject(obj)
            if not isGuiAlive(obj) then
                return false
            end

            local ok = pcall(function()
                GuiService.SelectedObject = nil
                task.wait()

                if not isGuiAlive(obj) then
                    return
                end

                GuiService.SelectedObject = obj
            end)

            return ok
        end

        local function clearSelectedObject()
            pcall(function()
                GuiService.SelectedObject = nil
            end)
        end
        
        -- HOVER CLICK METHOD
        local function clickWithHover(target)
            if not isGuiAlive(target) then
                clearSelectedObject()
                return false
            end

            safeSelectObject(target)
            task.wait(0.05)

            if not isGuiAlive(target) then
                clearSelectedObject()
                return false
            end

            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            task.wait(0.1)

            clearSelectedObject()

            return true
        end
        
        -- MOUSE CLICK METHOD
        local function clickWithMouse(target)
            if not isGuiAlive(target) then
                return false
            end
            
            -- Hide UI once per trade box session
            if not hasHiddenUIThisSession then
                if Window and Window.Holder and Window.Holder.Visible then
                    if Library and Library.Toggle then
                        Library:Toggle()
                        hasHiddenUIThisSession = true
                        task.wait(0.15)
                    end
                end
            end
            
            -- Get real mouse position with GuiInset
            local inset = GuiService:GetGuiInset()
            local x = target.AbsolutePosition.X + (target.AbsoluteSize.X / 2) + inset.X
            local y = target.AbsolutePosition.Y + (target.AbsoluteSize.Y / 2) + inset.Y
            
            -- Move mouse to target
            VirtualInputManager:SendMouseMoveEvent(x, y, game)
            task.wait(0.05)
            
            -- Click
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
            task.wait(0.1)
            
            return true
        end
        
        local function showUIIfHidden()
            if hasHiddenUIThisSession then
                if Window and Window.Holder and not Window.Holder.Visible then
                    if Library and Library.Toggle then
                        Library:Toggle()
                    end
                end
                hasHiddenUIThisSession = false
            end
        end
        
        -- MAIN CLICK DISPATCHER
        local function clickTarget(target)
            if clickMode == "Mouse" then
                return clickWithMouse(target)
            else
                return clickWithHover(target)
            end
        end

        -- ============================== FUNCTIONS ==============================

        local function getOtherBoxItemCount(itemName)
            local holderName = HOLDER_NAMES[itemName]
            if not holderName then
                return 0
            end

            local ok, item = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Tab.Display.Other.Box.Items[holderName]
            end)

            if ok and item then
                local main = item:FindFirstChild("Main")
                local inner = main and main:FindFirstChild("Inner")
                local qty = inner and inner:FindFirstChild("Quantity")

                if qty and qty:IsA("TextLabel") then
                    return tonumber(qty.Text:match("%d+")) or 0
                end
            end

            return 0
        end

        local function hasOtherBoxChanged()
            local totalItems = 0

            for _, itemName in ipairs(selectedItems) do
                totalItems = totalItems + getOtherBoxItemCount(itemName)
            end

            return totalItems > 0
        end

        local function waitForOtherBoxStable()
            local lastCount = 0
            local stableStart = tick()

            while true do
                local currentCount = 0

                for _, itemName in ipairs(selectedItems) do
                    currentCount = currentCount + getOtherBoxItemCount(itemName)
                end

                if currentCount ~= lastCount then
                    lastCount = currentCount
                    stableStart = tick()
                end

                if tick() - stableStart >= OTHER_BOX_CHECK_TIMEOUT then
                    return true
                end

                if currentCount == 0 and tick() - stableStart >= 0.1 then
                    return true
                end

                task.wait(0.05)
            end
        end

        local function getHolderCount(itemName)
            local holderName = HOLDER_NAMES[itemName]

            if not holderName then
                return 0
            end

            local ok, item = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.List.Holder.Items[holderName]
            end)

            if ok and item then
                local main = item:FindFirstChild("Main")
                local inner = main and main:FindFirstChild("Inner")
                local qty = inner and inner:FindFirstChild("Quantity")

                if qty and qty:IsA("TextLabel") then
                    return tonumber(qty.Text:match("%d+")) or 0
                end
            end

            return 0
        end

        local function isYouBoxVisible()
            local ok, box = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box
            end)

            if not ok or not box then
                return false
            end

            return isGuiAlive(box)
        end

        local function getAddButtonTitle()
            local ok, title = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box.Items.Item_Add.Add.Inner.Title
            end)

            if ok and title and title:IsA("TextLabel") then
                return title.Text
            end

            return nil
        end

        local function getConfirmTitle()
            local ok, title = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Review.Rate.Title
            end)

            if ok and title and title:IsA("TextLabel") then
                return title.Text
            end

            return nil
        end

        local function isConfirmVisible()
            local ok, confirm = pcall(function()
                return player.PlayerGui.Interface.Trading.Prompt.Review.Rate
            end)

            if not ok or not confirm then
                return false
            end

            if not isGuiAlive(confirm) then
                return false
            end

            local title = getConfirmTitle()

            return title and string.lower(title) == "confirm"
        end

        local function clickConfirm()
            local now = tick()

            if now - lastConfirmClick < CONFIRM_COOLDOWN then
                return false
            end

            local target = nil

            pcall(function()
                target = player.PlayerGui.Interface.Trading.Prompt.Review.Rate
            end)

            if not isGuiAlive(target) then
                clearSelectedObject()
                return false
            end

            local success = clickTarget(target)

            lastConfirmClick = now

            return success
        end

        local function clickAddButton()
            local target = nil

            pcall(function()
                target = player.PlayerGui.Interface.Trading.Prompt.Tab.Display.You.Box.Items.Item_Add
            end)

            if not isGuiAlive(target) then
                clearSelectedObject()
                return false
            end

            local success = clickTarget(target)
            
            task.wait(0.1)

            return success
        end

        local function ensureAddPanelOpen()
            for _ = 1, 3 do
                local title = getAddButtonTitle()

                if title == "-" then
                    return true
                end

                if title == "+" then
                    clickAddButton()
                    task.wait(PANEL_WAIT)
                else
                    task.wait(RETRY_WAIT)
                end
            end

            return getAddButtonTitle() == "-"
        end

        local function endTrade()
            pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Assets")
                    :WaitForChild("Remotes")
                    :WaitForChild("GET")
                    :InvokeServer("S_Trade", "End")
            end)
        end

        local function addItem(side, category, item, amount)
            local successCount = 0
            local batchCount = 0
            local stallCount = 0
            local lastSuccessTime = tick()

            local actualAmount =
                (category == "Cosmetics")
                and math.min(amount, COSMETICS_MAX)
                or amount

            local GET = game:GetService("ReplicatedStorage")
                :WaitForChild("Assets")
                :WaitForChild("Remotes")
                :WaitForChild("GET")

            local args = {
                "S_Trade",
                "Item",
                side,
                "Add",
                category,
                item
            }

            for i = 1, actualAmount do
                if not isDetectorEnabled then
                    break
                end

                if not isYouBoxVisible() then
                    stallCount = stallCount + 1

                    if stallCount > MAX_RETRY_AFTER_STALL then
                        break
                    end

                    task.wait(0.3)
                    continue
                else
                    stallCount = 0
                end

                if tick() - lastSuccessTime > 2 then
                    break
                end

                local ok = pcall(function()
                    GET:InvokeServer(unpack(args))
                end)

                if ok then
                    successCount = successCount + 1
                    lastSuccessTime = tick()
                end

                batchCount = batchCount + 1

                if batchCount >= BATCH_SIZE then
                    task.wait(BATCH_DELAY)
                    batchCount = 0
                else
                    task.wait(ADD_DELAY)
                end
            end

            return successCount
        end

        local function sendReady(side)
            return pcall(function()
                game:GetService("ReplicatedStorage")
                    :WaitForChild("Assets")
                    :WaitForChild("Remotes")
                    :WaitForChild("GET")
                    :InvokeServer("S_Trade", "State", side, true)
            end)
        end

        local function startReadyLoop()
            if readyLoopRunning then
                return
            end

            readyLoopRunning = true
            readyLoopToggle.Enabled = true

            task.spawn(function()
                while readyLoopToggle.Enabled do
                    if not isDetectorEnabled then
                        break
                    end

                    if isYouBoxVisible() then
                        sendReady(selectedSide)
                    end

                    task.wait(READY_LOOP_DELAY)
                end

                readyLoopRunning = false
            end)
        end

        local function stopReadyLoop()
            readyLoopToggle.Enabled = false
            readyLoopRunning = false
        end

        -- ============================== UI ==============================

        TradeDetectorBox:AddDropdown("TradeDetector_SideDropdown", {
            Text = "Select Side",
            Values = {"Receiver", "Sender"},
            Default = "Receiver",
            Multi = false,
            Callback = function(v)
                selectedSide = v
            end
        })

        TradeDetectorBox:AddDropdown("TradeDetector_ItemDropdown", {
            Text = "Select Items",
            Values = {"Memory Scroll", "Emperor's Key"},
            Default = {"Memory Scroll"},
            Multi = true,
            Callback = function(v)
                selectedItems = {}

                for name, enabled in pairs(v) do
                    if enabled then
                        table.insert(selectedItems, name)
                    end
                end
            end
        })

        TradeDetectorBox:AddSlider("TradeDetector_AmountSlider", {
            Text = "Amount Items",
            Default = 1,
            Min = 1,
            Max = 100,
            Rounding = 0,
            Callback = function(v)
                addAmountItems = v
            end
        })

        TradeDetectorBox:AddDropdown("TradeDetector_CosmeticsDropdown", {
            Text = "Select Cosmetics",
            Values = {
                "Angel's Halo",
                "Radiant Headband",
                "Kitsune Mask",
                "Blood Vial",
                "Kitsune Ribbon"
            },
            Default = {},
            Multi = true,
            Callback = function(v)
                selectedCosmetics = {}

                for name, enabled in pairs(v) do
                    if enabled then
                        table.insert(selectedCosmetics, name)
                    end
                end
            end
        })

        TradeDetectorBox:AddSlider("TradeDetector_CosmeticsAmountSlider", {
            Text = "Amount per Cosmetic",
            Default = 0,
            Min = 0,
            Max = 10,
            Rounding = 0,
            Callback = function(v)
                addAmountCosmetics = v
            end
        })

        -- CLICK MODE DROPDOWN
        TradeDetectorBox:AddDropdown("TradeDetector_ClickMode", {
            Text = "Click Mode",
            Values = {"Hover", "Mouse"},
            Default = "Hover",
            Multi = false,
            Callback = function(v)
                clickMode = v
            end
        })

        TradeDetectorBox:AddToggle("TradeDetector_Toggle", {
            Text = "Auto Add + Ready + Confirm",
            Default = false,
            Callback = function(v)
                isDetectorEnabled = v
                wasBoxOpen = false
                isAdding = false

                stopReadyLoop()

                stallStartTime = 0

                clearSelectedObject()
                
                if not v then
                    showUIIfHidden()
                    hasHiddenUIThisSession = false
                end

                if v then
                    if #selectedItems == 0 and #selectedCosmetics == 0 then
                        return
                    end
                end
            end
        })

        -- ============================== CONFIRM LOOP ==============================

        task.spawn(function()
            while true do
                task.wait(0.1)

                pcall(function()
                    if not isDetectorEnabled then
                        clearSelectedObject()
                        return
                    end

                    if isConfirmVisible() then
                        clickConfirm()
                    end
                end)
            end
        end)

        -- ============================== STALL LOOP ==============================

        task.spawn(function()
            while true do
                task.wait(0.5)

                pcall(function()
                    if not isDetectorEnabled then
                        stallStartTime = 0
                        return
                    end

                    if not isYouBoxVisible() then
                        stallStartTime = 0
                        return
                    end

                    if getAddButtonTitle() == "+" then
                        if stallStartTime == 0 then
                            stallStartTime = tick()
                        elseif tick() - stallStartTime >= STALL_TIMEOUT then
                            endTrade()
                            stallStartTime = 0
                        end
                    else
                        stallStartTime = 0
                    end
                end)
            end
        end)

        -- ============================== MAIN LOOP ==============================

        task.spawn(function()
            while true do
                task.wait(0.15)

                pcall(function()
                    if not isDetectorEnabled then
                        wasBoxOpen = false
                        isAdding = false

                        stopReadyLoop()
                        clearSelectedObject()
                        
                        if clickMode == "Mouse" then
                            showUIIfHidden()
                        end

                        return
                    end

                    local isOpen = isYouBoxVisible()

                    if isOpen and not wasBoxOpen then
                        wasBoxOpen = true
                        stallStartTime = 0
                        
                        if clickMode == "Mouse" then
                            hasHiddenUIThisSession = false
                        end

                        task.wait(0.3)

                        if not isYouBoxVisible() then
                            wasBoxOpen = false
                            return
                        end

                        if not ensureAddPanelOpen() then
                            return
                        end

                        if isAdding then
                            return
                        end

                        isAdding = true

                        waitForOtherBoxStable()

                        if not isDetectorEnabled or not isYouBoxVisible() then
                            isAdding = false
                            return
                        end

                        local grandTotal = 0

                        if #selectedItems > 0 then
                            for _, item in ipairs(selectedItems) do
                                local available = getHolderCount(item)
                                local toAdd = math.min(available, addAmountItems)

                                if toAdd > 0 then
                                    local cnt = addItem(
                                        selectedSide,
                                        "Items",
                                        item,
                                        toAdd
                                    )

                                    grandTotal = grandTotal + cnt
                                end

                                task.wait(0.05)
                            end
                        end

                        if addAmountCosmetics > 0 and #selectedCosmetics > 0 then
                            for _, item in ipairs(selectedCosmetics) do
                                if not isDetectorEnabled or not isYouBoxVisible() then
                                    break
                                end

                                local cnt = addItem(
                                    selectedSide,
                                    "Cosmetics",
                                    item,
                                    addAmountCosmetics
                                )

                                grandTotal = grandTotal + cnt

                                task.wait(0.05)
                            end
                        end

                        task.wait(0.15)

                        startReadyLoop()

                        isAdding = false

                    elseif not isOpen and wasBoxOpen then
                        wasBoxOpen = false
                        isAdding = false

                        stopReadyLoop()

                        stallStartTime = 0

                        clearSelectedObject()
                        
                        if clickMode == "Mouse" then
                            showUIIfHidden()
                            hasHiddenUIThisSession = false
                        end
                    end
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
-- ============================== UI SETTINGS ==============================
local UISettingsTab = Window:AddTab("Settings")

local MenuGroup = UISettingsTab:AddLeftGroupbox("Menu")

local hideUIFile = FakeHUBFolder .. "/hide_ui.txt"

-- ============================== LOAD HIDE STATE ==============================
local shouldHideUI = false

pcall(function()
    if isfile(hideUIFile) then
        shouldHideUI = (readfile(hideUIFile) == "true")
    end
end)

-- ============================== SAFE TOGGLE FUNCTIONS ==============================
local function IsUIVisible()
    return Window and Window.Holder and Window.Holder.Visible
end

local function HideUI()
    pcall(function()
        if IsUIVisible() then
            Library:Toggle()
        end
    end)
end

local function ShowUI()
    pcall(function()
        if Window and Window.Holder and not Window.Holder.Visible then
            Library:Toggle()
        end
    end)
end

-- ============================== AUTO HIDE TOGGLE ==============================
MenuGroup:AddToggle("HideUIToggle", {
    Text = "Auto Hide UI",
    Default = shouldHideUI,
    Callback = function(v)
        pcall(function()
            writefile(hideUIFile, tostring(v))
        end)
    end
})

-- ============================== UNLOAD ==============================
MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

-- ============================== KEYBIND ==============================
MenuGroup:AddLabel("Menu Bind"):AddKeyPicker("MenuKeybind", {
    Default = "End",
    NoUI = true,
    Text = "Menu Keybind"
})

task.defer(function()
    pcall(function()
        if Options and Options.MenuKeybind then
            Library.ToggleKeybind = Options.MenuKeybind
        end
    end)
end)

-- ============================== CONFIG SECTION PATCH ==============================
local oldBuildConfigSection = SaveManager.BuildConfigSection

function SaveManager:BuildConfigSection(tab)
    if oldBuildConfigSection then
        oldBuildConfigSection(self, tab)
    end

    local section = tab:AddRightGroupbox("Configuration")

    section:AddButton("Delete config", function()
        if not Options or not Options.SaveManager_ConfigList then
            return
        end

        local name = Options.SaveManager_ConfigList.Value

        if not name then
            return
        end

        local filePath = self.Folder .. "/settings/" .. name .. ".json"

        if isfile(filePath) then
            delfile(filePath)

            Options.SaveManager_ConfigList:SetValues(
                self:RefreshConfigList()
            )

            Options.SaveManager_ConfigList:SetValue(nil)
        end
    end)
end

SaveManager:BuildConfigSection(UISettingsTab)

-- ============================== THEME (BACKGROUND ONLY) ==============================
pcall(function()

    if ThemeManager
        and ThemeManager.BuiltInThemes
        and ThemeManager.BuiltInThemes["Jester"]
    then
        ThemeManager:ApplyTheme("Jester")
        ThemeManager:SaveDefault("Jester")

    elseif ThemeManager and ThemeManager.ApplyTheme then
        ThemeManager:ApplyTheme("Default")
    end

end)

-- ============================== FORCE DEFAULT THEME ==============================
pcall(function()
    if ThemeManager
        and ThemeManager.BuiltInThemes
        and ThemeManager.BuiltInThemes["Jester"]
    then
        ThemeManager:ApplyTheme("Jester")
        ThemeManager:SaveDefault("Jester")

    elseif ThemeManager and ThemeManager.ApplyTheme then
        ThemeManager:ApplyTheme("Default")
    end
end)

-- ============================== AUTOLOAD + AUTO HIDE ==============================
task.spawn(function()

    task.wait(0.25)

    pcall(function()
        SaveManager:LoadAutoloadConfig()
    end)

    -- รอ Window โหลดจริง
    for i = 1, 40 do
        if Window and Window.Holder then
            break
        end

        task.wait(0.05)
    end

    task.wait(0.15)

    -- ใช้ Toggle ของ Linoria เท่านั้น
    pcall(function()
        if isfile(hideUIFile)
            and readfile(hideUIFile) == "true"
        then
            HideUI()
        end
    end)

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
    local lastNotify = 0

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
                        if tick() - lastNotify > 3 then
                            Library:Notify("⚠️ Follow Frame closed! Waiting...", 3)
                            lastNotify = tick()
                        end
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
end
-- ============================== AUTO MISSION ==============================
if Tabs.Lobby then

    local LobbyGroupLeft = Tabs.Lobby:AddLeftGroupbox("Auto Mission")

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
        "No Perks",
        "No Skills",
        "No Memories",
        "Nightmare",
        "Oddball",
        "Injury Prone",
        "Chronic Injuries",
        "Fog",
        "Glass Cannon",
        "Time Trial",
        "Boring",
        "Simple"
    }

    local State = {
        Name = "Shiganshina",
        Objective = "Skirmish",
        Difficulty = "Easy",
        Modifiers = {}
    }

    local MissionDelay = 0

    local missionRunning = false
    local missionBusy = false
    local sessionId = 0

    -- ============================== NORMALIZE MODIFIERS ==============================
    local function normalizeModifiers(modTable)

        local list = {}

        if type(modTable) ~= "table" then
            return list
        end

        for k, v in pairs(modTable) do

            if v == true then
                list[#list + 1] = k

            elseif type(v) == "string" then
                list[#list + 1] = v
            end
        end

        return list
    end

    -- ============================== LEVEL CHECK ==============================
    local function GetPlayerLevel()

        local success, level = pcall(function()

            local title =
                game:GetService("Players")
                .LocalPlayer
                .PlayerGui
                :FindFirstChild("Interface")
                and game.Players.LocalPlayer
                .PlayerGui.Interface
                :FindFirstChild("Gear_Up")
                and game.Players.LocalPlayer
                .PlayerGui.Interface.Gear_Up
                :FindFirstChild("HUD")
                and game.Players.LocalPlayer
                .PlayerGui.Interface.Gear_Up.HUD
                :FindFirstChild("Level")
                and game.Players.LocalPlayer
                .PlayerGui.Interface.Gear_Up.HUD.Level
                :FindFirstChild("Title")

            if not title then
                return 1
            end

            local txt =
                tostring(title.Text)

            local num =
                tonumber(
                    txt:match("%d+")
                )

            return num or 1
        end)

        return success and level or 1
    end

    -- ============================== HARDEST CYCLE ==============================
    local function GetHardestCycle()

        local level =
            GetPlayerLevel()

        -- LV 100+
        if level >= 100 then

            return {
                "Aberrant"
            }
        end

        -- LV 41 - 99
        if level > 40 then

            return {
                "Aberrant",
                "Severe",
                "Hard",
                "Normal",
                "Easy"
            }
        end

        -- LV 1 - 40
        return {
            "Hard",
            "Normal",
            "Easy"
        }
    end

    -- ============================== CREATE MISSION ==============================
    local function SyncCreate(data)

        local list =
            MissionObjectives[data.Name]
            or {"Skirmish"}

        local objective = data.Objective

        if objective == "Random" then

            local filtered = {}

            for _, v in ipairs(list) do

                if v ~= "Random" then
                    filtered[#filtered + 1] = v
                end
            end

            objective =
                filtered[math.random(#filtered)]
        end

        GET:InvokeServer(
            "S_Missions",
            "Create",
            {
                Difficulty = data.Difficulty,
                Type = "Missions",
                Name = data.Name
            }
        )

        task.wait(0.05)

        GET:InvokeServer(
            "S_Missions",
            "Create",
            {
                Difficulty = data.Difficulty,
                Type = "Missions",
                Name = data.Name,
                Objective = objective
            }
        )
    end

    -- ============================== APPLY MODIFIERS ==============================
    local function ApplyModifiers(list)

        for _, mod in ipairs(list) do

            GET:InvokeServer(
                "S_Missions",
                "Modify",
                mod
            )

            task.wait(0.08)
        end
    end

    -- ============================== MAIN LOOP ==============================
    local function MissionLoop(mySession)

        while missionRunning
            and sessionId == mySession
        do

            if missionBusy then
                task.wait(0.05)
                continue
            end

            missionBusy = true

            local currentModifiers = {}

            pcall(function()

                if Options
                    and Options.ModifiersDropdown
                    and Options.ModifiersDropdown.Value
                then

                    currentModifiers = normalizeModifiers(
                        Options.ModifiersDropdown.Value
                    )
                end
            end)

            local locked = {
                Name = State.Name,
                Objective = State.Objective,
                Difficulty = State.Difficulty,
                Modifiers = currentModifiers
            }

            State.Modifiers = currentModifiers

            -- ============================== HARDEST MODE ==============================
            if locked.Difficulty == "Hardest" then

                local cycleList =
                    GetHardestCycle()

                for _, diff in ipairs(cycleList) do

                    if not missionRunning
                        or sessionId ~= mySession
                    then
                        break
                    end

                    -- REFRESH DROPDOWN VALUES
                    local currentMission =
                        State.Name

                    local currentObjective =
                        State.Objective

                    local currentModifiers =
                        State.Modifiers

                    local objectiveList =
                        MissionObjectives[currentMission]
                        or {"Skirmish"}

                    -- RANDOM OBJECTIVE
                    if currentObjective == "Random" then

                        local filtered = {}

                        for _, v in ipairs(objectiveList) do

                            if v ~= "Random" then
                                filtered[#filtered + 1] = v
                            end
                        end

                        currentObjective =
                            filtered[
                                math.random(#filtered)
                            ]
                    end

                    -- CREATE
                    GET:InvokeServer(
                        "S_Missions",
                        "Create",
                        {
                            Difficulty = diff,
                            Type = "Missions",
                            Name = currentMission
                        }
                    )

                    task.wait(0.05)

                    GET:InvokeServer(
                        "S_Missions",
                        "Create",
                        {
                            Difficulty = diff,
                            Type = "Missions",
                            Name = currentMission,
                            Objective = currentObjective
                        }
                    )

                    -- WAIT BEFORE MODIFY
                    task.wait(0.15)

                    -- APPLY MODIFIERS
                    ApplyModifiers(currentModifiers)

                    -- WAIT BEFORE START
                    task.wait(
                        0.2 + (#currentModifiers * 0.08)
                    )

                    -- START
                    GET:InvokeServer(
                        "S_Missions",
                        "Start"
                    )

                    -- MOVE NEXT STEP
                    task.wait(3.5)
                end

            else

                -- ============================== NORMAL MODE ==============================
                SyncCreate(locked)

                task.wait(0.12 + MissionDelay)

                ApplyModifiers(locked.Modifiers)

                task.wait(
                    0.2 + (#locked.Modifiers * 0.08)
                )

                local verifiedModifiers = {}

                pcall(function()

                    if Options
                        and Options.ModifiersDropdown
                        and Options.ModifiersDropdown.Value
                    then

                        verifiedModifiers = normalizeModifiers(
                            Options.ModifiersDropdown.Value
                        )
                    end
                end)

                if #verifiedModifiers > #locked.Modifiers then

                    ApplyModifiers(verifiedModifiers)

                    task.wait(0.15)
                end

                GET:InvokeServer(
                    "S_Missions",
                    "Start"
                )

                task.wait(0.45)
            end

            missionBusy = false
        end
    end

    -- ============================== UI ==============================
    LobbyGroupLeft:AddDropdown("MissionDropdown", {
        Values = {
            "Shiganshina",
            "Trost",
            "Outskirts",
            "Giant Forest",
            "Utgard",
            "Loading Docks",
            "Stohess"
        },

        Default = State.Name,

        Multi = false,

        Text = "Mission",

        Callback = function(val)

            State.Name = val

            local newObjectives =
                MissionObjectives[val]
                or {"Skirmish"}

            State.Objective = newObjectives[1]

            if Options and Options.ObjectiveDropdown then

                Options.ObjectiveDropdown:SetValues(
                    newObjectives
                )

                Options.ObjectiveDropdown:SetValue(
                    newObjectives[1]
                )
            end
        end
    })

    LobbyGroupLeft:AddDropdown("ObjectiveDropdown", {

        Values = MissionObjectives[State.Name],

        Default = "Skirmish",

        Multi = false,

        Text = "Objective",

        Callback = function(val)
            State.Objective = val
        end
    })

    LobbyGroupLeft:AddDropdown("DifficultyDropdown", {

        Values = {
            "Easy",
            "Normal",
            "Hard",
            "Severe",
            "Aberrant",
            "Hardest"
        },

        Default = "Easy",

        Multi = false,

        Text = "Mode",

        Callback = function(val)
            State.Difficulty = val
        end
    })

    LobbyGroupLeft:AddDropdown("ModifiersDropdown", {

        Values = ModifiersList,

        Default = {},

        Multi = true,

        Text = "Modifiers",

        Callback = function(val)
            State.Modifiers = val or {}
        end
    })

    LobbyGroupLeft:AddSlider("MissionDelaySlider", {

        Text = "Delay",

        Default = 0,

        Min = 0,

        Max = 60,

        Rounding = 0,

        Callback = function(val)
            MissionDelay = val
        end
    })

    LobbyGroupLeft:AddToggle("AutoStartMissionToggle", {

        Text = "Start Mission",

        Default = false,

        Callback = function(v)

            if v then

                if missionRunning then
                    return
                end

                missionRunning = true

                sessionId = sessionId + 1

                local mySession = sessionId

                task.spawn(function()
                    MissionLoop(mySession)
                end)

            else

                missionRunning = false

                sessionId = sessionId + 1

                pcall(function()

                    GET:InvokeServer(
                        "S_Missions",
                        "Leave"
                    )

                end)
            end
        end
    })
end
-- ============================== EQUIP SKILL ==============================
if IsLobbyLobby() then
    local SkillGroupRight = Tabs.Session:AddLeftGroupbox("Equip Skill")

    local selectedSkills = {}
    local isEquipping = false

    local SKILLS = {
        ["Drill Thrust"] = {slot = 1, id = "14"},
        ["Torrential Steel"] = {slot = 2, id = "23"}
    }

    local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")

    local function clearSlot(slotNumber)
        local args = {"S_Equipment", "Skill_State", slotNumber, "7"}
        pcall(function() GET:InvokeServer(unpack(args)) end)
    end

    local function equipSkill(skillName)
        local skillData = SKILLS[skillName]
        if not skillData then return end
        
        local args = {"S_Equipment", "Skill_State", skillData.slot, skillData.id}
        pcall(function() GET:InvokeServer(unpack(args)) end)
    end

    local function clearAllSlots()
        for slot = 1, 5 do
            clearSlot(slot)
            task.wait(0.05)
        end
        clearSlot(5)
        task.wait(0.05)
    end

    local function executeEquip()
        if isEquipping then return end
        isEquipping = true
        
        task.spawn(function()
            clearAllSlots()
            task.wait(0.1)
            
            for skillName, enabled in pairs(selectedSkills) do
                if enabled then
                    equipSkill(skillName)
                    task.wait(0.05)
                end
            end
            
            isEquipping = false
        end)
    end

    SkillGroupRight:AddDropdown("EquipSkill_Dropdown", {
        Text = "Select Skills",
        Values = {"Drill Thrust", "Torrential Steel"},
        Default = {},
        Multi = true,
        Callback = function(v)
            selectedSkills = v
        end
    })

    SkillGroupRight:AddToggle("EquipSkill_Toggle", {
        Text = "Equip Skills",
        Default = false,
        Callback = function(v)
            if v then
                executeEquip()
                task.wait(0.1)
                pcall(function()
                    if Options and Options.EquipSkill_Toggle then
                        Options.EquipSkill_Toggle:SetValue(false)
                    end
                end)
            end
        end
    })
end
-- ============================== AUTO UPGRADE ==============================
if IsLobbyLobby() then
    local UpgradeTabbox = Tabs.Session:AddLeftTabbox("Auto Upgrade")

    local BladeTab = UpgradeTabbox:AddTab("Blade")

    getgenv().AutoUpgradeBlade = false
    getgenv().UpgradeRunning = false
    getgenv().UpgradeCooldown = 5

    local ALL_BLADE_STATS = {
        "ODM_Gas", "ODM_Speed", "ODM_Range", "ODM_Control",
        "Crit_Damage", "ODM_Damage", "Crit_Chance", "Blade_Durability"
    }

    local function batchUpgradeBlade()
        if not GET then return false end
        local args = { "S_Equipment", "Upgrade", ALL_BLADE_STATS }
        return pcall(function()
            GET:InvokeServer(unpack(args))
        end)
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
        Text = "Auto Upgrade Blade (Batch Mode)",
        Default = false,
        Callback = function(state)
            getgenv().AutoUpgradeBlade = state

            if state and not getgenv().UpgradeRunning then
                getgenv().UpgradeRunning = true

                task.spawn(function()
                    local hasNotified = false
                    
                    while getgenv().AutoUpgradeBlade do
                        pcall(function()
                            batchUpgradeBlade()
                            
                            if not hasNotified then
                                task.wait(getgenv().UpgradeCooldown)
                                hasNotified = true
                            end
                            
                            task.wait(getgenv().UpgradeCooldown)
                        end)
                    end
                    getgenv().UpgradeRunning = false
                end)
            end
        end
    })

    local SpearTab = UpgradeTabbox:AddTab("Thunder Spear")

    getgenv().AutoUpgradeSpear = false
    getgenv().SpearUpgradeRunning = false
    getgenv().SpearUpgradeCooldown = 5

    local ALL_SPEAR_STATS = {
        "ODM_Gas", "ODM_Speed", "ODM_Range", "ODM_Control",
        "Crit_Damage", "ODM_Damage", "Crit_Chance", "Blade_Durability"
    }

    local function batchUpgradeSpear()
        if not GET then return false end
        local args = { "S_Equipment", "Upgrade", ALL_SPEAR_STATS }
        return pcall(function()
            GET:InvokeServer(unpack(args))
        end)
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
        Text = "Auto Upgrade Thunder Spear (Batch Mode)",
        Default = false,
        Callback = function(state)
            getgenv().AutoUpgradeSpear = state

            if state and not getgenv().SpearUpgradeRunning then
                getgenv().SpearUpgradeRunning = true

                task.spawn(function()
                    local hasNotified = false
                    
                    while getgenv().AutoUpgradeSpear do
                        pcall(function()
                            batchUpgradeSpear()
                            
                            if not hasNotified then
                                task.wait(getgenv().SpearUpgradeCooldown)
                                hasNotified = true
                            end
                            
                            task.wait(getgenv().SpearUpgradeCooldown)
                        end)
                    end
                    getgenv().SpearUpgradeRunning = false
                end)
            end
        end
    })
end
-- ============================== UNLOCK SKILLS ==============================
if IsLobbyLobby() then
    local UnlockGroupRight = Tabs.Session:AddRightGroupbox("Unlock Skills")
    
    local SupportSkills = {
        {id = "70", name = "Durability I"},{id = "71", name = "Control I"},{id = "72", name = "Bandages"},{id = "73", name = "Durability II"},
        {id = "74", name = "Trained Cadet"},{id = "75", name = "Regen I"},{id = "76", name = "Red Flare"},{id = "77", name = "Durability III"},
        {id = "78", name = "Target Acquisition"},{id = "79", name = "Control II"},{id = "80", name = "Support Perk Slot"},
        {id = "81", name = "Regen II [ Left ]"},{id = "82", name = "Advanced Medic [ Left ]"},{id = "83", name = "Titan Shifter [ Left ]"},
        {id = "84", name = "Portable Resupply [ Left ]"},{id = "85", name = "Regen IV [ Left ]"},{id = "86", name = "Master Medic [ Left ]"},
        {id = "87", name = "Regen V [ Left ]"},{id = "88", name = "Resourceful [ Left ]"},{id = "89", name = "Regen VI [ Left ]"},
        {id = "90", name = "Cooldown I [ Right ]"},{id = "91", name = "Injury III [ Right ]"},{id = "92", name = "Cooldown I [ Right ]"},
        {id = "93", name = "Acoustic Shells [ Right ]"},{id = "94", name = "Cooldown II [ Right ]"},{id = "95", name = "Order: Advance [ Right ]"},
        {id = "96", name = "Injury II [ Right ]"},{id = "97", name = "Black Flare [ Right ]"},{id = "98", name = "Cooldown II [ Right ]"}
    }
    local OffensiveSkills = {
        {id = "1", name = "Damage I"},{id = "2", name = "Duration I"},{id = "3", name = "Hand Grinder"},{id = "4", name = "Durability I"},
        {id = "5", name = "Duration II"},{id = "6", name = "Durability II"},{id = "7", name = "Blade Dance"},{id = "8", name = "Durability III"},
        {id = "9", name = "Crit Chance I"},{id = "10", name = "Crit Damage I"},{id = "11", name = "Offense Perk Slot"},{id = "12", name = "Damage II"},
        {id = "13", name = "Crit Chance II"},{id = "14", name = "Drill Thrust [ Right ]"},{id = "15", name = "Crit Chance III [ Right ]"},
        {id = "16", name = "Crit Damage II [ Right ]"},{id = "17", name = "Eye Gouge [ Right ]"},{id = "18", name = "Crit Chance IV [ Right ]"},
        {id = "19", name = "Crit Damage III [ Right ]"},{id = "20", name = "Momentum [ Right ]"},{id = "21", name = "Crit Chance V [ Right ]"},
        {id = "22", name = "Crit Damage IV [ Right ]"},{id = "23", name = "Torrential Steel [ Right ]"},{id = "24", name = "Crit Chance VI [ Right ]"},
        {id = "25", name = "Crit Damage V [ Right ]"},{id = "26", name = "Rising Slash [ Left ]"},{id = "27", name = "Duration III [ Left ]"},
        {id = "28", name = "Durability IV [ Left ]"},{id = "29", name = "Refined Technique [ Left ]"},{id = "30", name = "Damage III [ Left ]"},
        {id = "31", name = "Duration IV [ Left ]"},{id = "32", name = "Bloodlust [ Left ]"},{id = "33", name = "Durability V [ Left ]"},
        {id = "34", name = "Damage IV [ Left ]"},{id = "35", name = "Lethal Tempo [ Left ]"},{id = "36", name = "Duration V [ Left ]"},
        {id = "37", name = "Damage V [ Left ]"}
    }
    local DefendSkills = {
        {id = "38", name = "Health I"},{id = "39", name = "Injury I"},{id = "40", name = "Counter"},{id = "41", name = "Health II"},
        {id = "42", name = "Injury II"},{id = "43", name = "Defense Perk Slot"},{id = "44", name = "Health III"},{id = "45", name = "Survivalist I"},
        {id = "46", name = "Health IV [ Right ]"},{id = "47", name = "Emergency Relocation [ Right ]"},{id = "48", name = "Health V [ Right ]"},
        {id = "49", name = "Health VI [ Right ]"},{id = "50", name = "Super Guts [ Right ]"},{id = "51", name = "Health VII [ Right ]"},
        {id = "52", name = "Health VIII [ Right ]"},{id = "53", name = "Adrenaline [ Right ]"},{id = "54", name = "Health IX [ Right ]"},
        {id = "55", name = "Health X [ Right ]"},{id = "56", name = "Autodidact [ Right ]"},{id = "57", name = "Health XI [ Right ]"},
        {id = "58", name = "Tank I [ Left ]"},{id = "59", name = "Hardy Counter [ Left ]"},{id = "60", name = "Tank II [ Left ]"},
        {id = "61", name = "Tank III [ Left ]"},{id = "62", name = "Survivalist II [ Left ]"},{id = "63", name = "Tank IV [ Left ]"},
        {id = "64", name = "Tank V [ Left ]"},{id = "65", name = "Forceful Rebound [ Left ]"},{id = "66", name = "Tank VI [ Left ]"},
        {id = "67", name = "Tank VII [ Left ]"},{id = "68", name = "Tough As Nails [ Left ]"},{id = "69", name = "Tank VIII [ Left ]"}
    }
    
    getgenv().SelectedSupport = {}
    getgenv().SelectedOffensive = {}
    getgenv().SelectedDefend = {}
    getgenv().UnlockRunning = false

    local function getSupportNames() local t={} for _,s in ipairs(SupportSkills) do t[#t+1]=s.name end return t end
    local function getOffensiveNames() local t={} for _,s in ipairs(OffensiveSkills) do t[#t+1]=s.name end return t end
    local function getDefendNames() local t={} for _,s in ipairs(DefendSkills) do t[#t+1]=s.name end return t end
    local function getSupportID(name) for _,s in ipairs(SupportSkills) do if s.name==name then return s.id end end return nil end
    local function getOffensiveID(name) for _,s in ipairs(OffensiveSkills) do if s.name==name then return s.id end end return nil end
    local function getDefendID(name) for _,s in ipairs(DefendSkills) do if s.name==name then return s.id end end return nil end

    UnlockGroupRight:AddDropdown("SupportSkillsDropdown", {Values=getSupportNames(), Default={}, Multi=true, Text="Support Skills", Callback=function(v) getgenv().SelectedSupport=v end})
    UnlockGroupRight:AddDropdown("OffensiveSkillsDropdown", {Values=getOffensiveNames(), Default={}, Multi=true, Text="Offensive Skills", Callback=function(v) getgenv().SelectedOffensive=v end})
    UnlockGroupRight:AddDropdown("DefendSkillsDropdown", {Values=getDefendNames(), Default={}, Multi=true, Text="Defend Skills", Callback=function(v) getgenv().SelectedDefend=v end})
    UnlockGroupRight:AddDivider()
    UnlockGroupRight:AddToggle("UnlockSkillsToggle", {Text="Unlock Selected Skills", Default=false, Callback=function(v)
        if not v or getgenv().UnlockRunning then return end
        getgenv().UnlockRunning = true
        task.spawn(function()
            local queue = {}
            local function collectOrdered(selectedTable, getIDFunc)
                local temp = {}
                for name, enabled in pairs(selectedTable) do
                    if enabled then
                        local id = getIDFunc(name)
                        if id then table.insert(temp, tonumber(id)) end
                    end
                end
                table.sort(temp)
                for _, id in ipairs(temp) do table.insert(queue, tostring(id)) end
            end
            collectOrdered(getgenv().SelectedSupport, getSupportID)
            collectOrdered(getgenv().SelectedOffensive, getOffensiveID)
            collectOrdered(getgenv().SelectedDefend, getDefendID)
            if #queue == 0 then getgenv().UnlockRunning=false return end
            for i, id in ipairs(queue) do
                if not getgenv().UnlockRunning then break end
                pcall(function() SafeInvoke(GET, "S_Equipment", "Unlock", { id }) end)
                task.wait(0.03 + (i % 3 == 0 and 0.05 or 0))
            end
            getgenv().UnlockRunning = false
        end)
    end})
end


-- ============================== BOOST SELECTION ==============================
if IsLobbyLobby() then
    local BoostGroup = Tabs.Lobby:AddRightGroupbox("Boost Selection")
    
    local selectedCurrency = "Gems"
    local purchaseAmount = 1
    local selectedBoosts = {}
    local selectedUseBoosts = {}
    
    local ALL_BOOSTS = {
        "2X XP Boost [30M]", "2X Luck [30M]", "2X Gold [30M]",
        "2X XP Boost [1H]", "2X Luck [1H]", "2X Gold [1H]",
        "2X XP Boost [2H]", "2X Luck [2H]", "2X Gold [2H]"
    }
    
    local USE_BOOSTS_LIST = {
        "2x XP Boost [30m]", "2x Luck Boost [30m]", "2x Gold Boost [30m]",
        "2x XP Boost [1h]", "2x Luck Boost [1h]", "2x Gold Boost [1h]",
        "2x XP Boost [2h]", "2x Luck Boost [2h]", "2x Gold Boost [2h]"
    }
    
    local BOOST_MAP = {
        ["2X XP Boost [30M]"] = {type = "xp", duration = "30M", gemsId = 1, canesId = 1},
        ["2X XP Boost [1H]"] = {type = "xp", duration = "1H", gemsId = 2, canesId = 2},
        ["2X XP Boost [2H]"] = {type = "xp", duration = "2H", gemsId = 3, canesId = 3},
        ["2X Luck [30M]"] = {type = "luck", duration = "30M", gemsId = 4, canesId = 4},
        ["2X Luck [1H]"] = {type = "luck", duration = "1H", gemsId = 5, canesId = 5},
        ["2X Luck [2H]"] = {type = "luck", duration = "2H", gemsId = 6, canesId = 6},
        ["2X Gold [30M]"] = {type = "gold", duration = "30M", gemsId = 7, canesId = 7},
        ["2X Gold [1H]"] = {type = "gold", duration = "1H", gemsId = 8, canesId = 8},
        ["2X Gold [2H]"] = {type = "gold", duration = "2H", gemsId = 9, canesId = 9},
    }
    
    local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
    
    local function purchaseBoost(boostName)
        local data = BOOST_MAP[boostName]
        if not data then return false end
        
        local boostTypeStr = selectedCurrency == "Gems" and "1_Boosts" or "2_Boosts"
        local id = selectedCurrency == "Gems" and data.gemsId or data.canesId
        
        local args = {"S_Market", "Buy", boostTypeStr, id, purchaseAmount}
        return pcall(function() GET:InvokeServer(unpack(args)) end)
    end
    
    local function useBoost(boostName)
        local args = {"S_Inventory", "Item", boostName}
        return pcall(function() GET:InvokeServer(unpack(args)) end)
    end
    
    BoostGroup:AddDropdown("Boost_ListDropdown", {
        Text = "Select Boosts",
        Values = ALL_BOOSTS,
        Default = {},
        Multi = true,
        Callback = function(val) selectedBoosts = val end
    })
    
    BoostGroup:AddDropdown("Boost_CurrencyDropdown", {
        Text = "Buy From",
        Values = {"Gems", "Canes"},
        Default = "Gems",
        Multi = false,
        Callback = function(v) selectedCurrency = v end
    })
    
    BoostGroup:AddSlider("Boost_AmountSlider", {
        Text = "Quantity",
        Default = 1,
        Min = 1,
        Max = 50,
        Rounding = 0,
        Callback = function(v) purchaseAmount = v end
    })
    
    BoostGroup:AddToggle("Boost_PurchaseToggle", {
        Text = "Purchase",
        Default = false,
        Callback = function(v)
            if not v then return end
            
            task.spawn(function()
                for boostName, enabled in pairs(selectedBoosts) do
                    if enabled then
                        purchaseBoost(boostName)
                        task.wait(0.15)
                    end
                end
                task.wait(0.3)
                pcall(function()
                    if Options and Options.Boost_PurchaseToggle then
                        Options.Boost_PurchaseToggle:SetValue(false)
                    end
                end)
            end)
        end
    })
    
    BoostGroup:AddDivider()
    
    BoostGroup:AddDropdown("Boost_UseDropdown", {
        Text = "Select Boosts to Use",
        Values = USE_BOOSTS_LIST,
        Default = {},
        Multi = true,
        Callback = function(val) selectedUseBoosts = val end
    })
    
    BoostGroup:AddToggle("Boost_AutoUseToggle", {
        Text = "Auto Use Boost (5x each)",
        Default = false,
        Callback = function(v)
            if not v then return end
            
            task.spawn(function()
                -- 🔥 อ่านค่าจาก Options โดยตรง เพื่อเลี่ยง race condition
                local currentSelection = {}
                pcall(function()
                    if Options and Options.Boost_UseDropdown and Options.Boost_UseDropdown.Value then
                        currentSelection = Options.Boost_UseDropdown.Value
                    end
                end)
                
                -- ถ้า Options ยังไม่พร้อม ให้ใช้ตัวแปร fallback (selectedUseBoosts)
                if not next(currentSelection) then
                    currentSelection = selectedUseBoosts
                end
                
                if not next(currentSelection) then
                    Library:Notify("⚠️ No boost selected!", 2)
                    -- ปิด toggle หลังจากแจ้ง
                    task.wait(0.3)
                    pcall(function()
                        if Options and Options.Boost_AutoUseToggle then
                            Options.Boost_AutoUseToggle:SetValue(false)
                        end
                    end)
                    return
                end
                
                for boostName, enabled in pairs(currentSelection) do
                    if enabled then
                        for i = 1, 5 do
                            useBoost(boostName)
                            task.wait(0.15)  -- เพิ่มดีเลย์ให้เสถียร
                        end
                    end
                end
                
                task.wait(0.3)
                pcall(function()
                    if Options and Options.Boost_AutoUseToggle then
                        Options.Boost_AutoUseToggle:SetValue(false)
                    end
                end)
            end)
        end
    })
end
-- ============================== PRESTIGE ==============================
if IsLobbyLobby() then
    local PrestigeGroup = Tabs.Session:AddRightGroupbox("Prestige")
    
    getgenv().PrestigeEnabled = false
    getgenv().PrestigeRunning = false
    getgenv().SelectedBoost = nil
    getgenv().SelectedTalent = nil
    
    local TalentsDB = {
        ["Offense ☆"] = {"Crescendo", "Blitzblade", "Swiftshot", "Surgeshot"},
        ["Offense ☆☆"] = {"Stalwart", "Stormcharged"},
        ["Offense ☆☆☆"] = {"Quakestrike", "Furyforge", "Assassin", "Amputation", "Marksman"},
        ["Offense ☆☆☆☆"] = {"Overslash", "Gambler", "Afterimages"},
        ["Defense ☆"] = {"Guardian", "Deflectra"},
        ["Defense ☆☆"] = {"Aegisurge", "Riposte"},
        ["Defense ☆☆☆"] = {"Resilience", "Vengeflare", "Steel Frame"},
        ["Defense ☆☆☆☆"] = {"Necromantic", "Thanatophobia"},
        ["Support ☆"] = {"Cooldown Blitz", "Mendmaster"},
        ["Support ☆☆"] = {"Lifefeed", "Vitalize", "Gem Fiend"},
        ["Support ☆☆☆"] = {"Omnirange", "Flashstep", "Tactician"},
        ["Support ☆☆☆☆"] = {"Bloodthief", "Apotheosis"}
    }
    
    -- 🔥 ฟังก์ชันสุ่ม Talent จากทั้งหมด
    local function getRandomTalent()
        local allTalents = {}
        for _, talents in pairs(TalentsDB) do
            for _, talent in ipairs(talents) do
                table.insert(allTalents, talent)
            end
        end
        if #allTalents == 0 then return nil end
        return allTalents[math.random(#allTalents)]
    end
    
    local function doPrestige()
        if not getgenv().PrestigeEnabled then return false end
        if not getgenv().SelectedBoost then return false end
        
        local talent = getgenv().SelectedTalent
        if talent == "Random" then
            talent = getRandomTalent()
            if not talent then return false end
        end
        
        if not talent then return false end
        
        SafeInvoke(GET, "S_Equipment", "Talents")
        task.wait(1)
        return pcall(function()
            SafeInvoke(GET, "S_Equipment", "Prestige", {
                Boosts = getgenv().SelectedBoost,
                Talents = talent
            })
        end)
    end
    
    PrestigeGroup:AddDropdown("BoostDropdown", {
        Values = {"None","Luck Boost","Exp Boost","Gold Boost"},
        Default = "None",
        Multi = false,
        Text = "Boost Type",
        Callback = function(v)
            getgenv().SelectedBoost = (v ~= "None") and v or nil
        end
    })
    
    PrestigeGroup:AddDropdown("TalentCategoryDropdown", {
        Values = {"Offense ☆","Offense ☆☆","Offense ☆☆☆","Offense ☆☆☆☆",
                  "Defense ☆","Defense ☆☆","Defense ☆☆☆","Defense ☆☆☆☆",
                  "Support ☆","Support ☆☆","Support ☆☆☆","Support ☆☆☆☆"},
        Default = "Offense ☆",
        Multi = false,
        Text = "Category",
        Callback = function(v)
            if Options and Options.TalentDropdown then
                local talents = TalentsDB[v] or {}
                -- 🔥 เพิ่มตัวเลือก "Random" ไว้หน้า list
                local talentList = {"Random"}
                for _, t in ipairs(talents) do
                    table.insert(talentList, t)
                end
                Options.TalentDropdown:SetValues(talentList)
                -- ถ้าเดิมเลือก "Random" ไว้ก็คงไว้ ไม่งั้นไปที่ตัวแรกใน list (Random หรือ Talent แรก)
                local current = getgenv().SelectedTalent
                if current == "Random" or (current and table.find(talentList, current)) then
                    Options.TalentDropdown:SetValue(current)
                else
                    Options.TalentDropdown:SetValue(talentList[1])  -- "Random"
                    getgenv().SelectedTalent = talentList[1]
                end
            end
        end
    })
    
    -- 🔥 TalentDropdown เริ่มต้นใส่ "Random" ด้วย
    local initialTalents = TalentsDB["Offense ☆"]
    local talentList = {"Random"}
    for _, t in ipairs(initialTalents) do
        table.insert(talentList, t)
    end
    
    PrestigeGroup:AddDropdown("TalentDropdown", {
        Values = talentList,
        Default = talentList[2],  -- "Crescendo" (ข้าม "Random")
        Multi = false,
        Text = "Talent",
        Callback = function(v)
            getgenv().SelectedTalent = v
        end
    })
    
    PrestigeGroup:AddDivider()
    
    PrestigeGroup:AddToggle("PrestigeToggle", {
        Text = "Auto Prestige",
        Default = false,
        Callback = function(v)
            getgenv().PrestigeEnabled = v
            if v then
                if not getgenv().SelectedBoost then
                    getgenv().PrestigeEnabled = false
                    return
                end
                if not getgenv().SelectedTalent then
                    getgenv().PrestigeEnabled = false
                    return
                end
                if not getgenv().PrestigeRunning then
                    getgenv().PrestigeRunning = true
                    task.spawn(function()
                        local success = doPrestige()
                        getgenv().PrestigeEnabled = false
                        getgenv().PrestigeRunning = false
                    end)
                end
            else
                getgenv().PrestigeRunning = false
            end
        end
    })
end
-- ============================== AUTO CLAIMS ==============================
if IsLobbyLobby() then
    local AutoClaimGroup = Tabs.Session:AddLeftGroupbox("Auto Claims")
    
    getgenv().ClaimQuestEnabled = false
    getgenv().ClaimQuestRunning = false
    getgenv().ClaimAchievementEnabled = false
    getgenv().ClaimAchievementRunning = false
    getgenv().ClaimDelay = 0
    
    local QuestList = {
        {name="Novice Adventurer", category="Main"},{name="Seasoned Operative", category="Main"},{name="Master Of Missions", category="Main"},{name="Elite Taskmaster", category="Main"},{name="Legendary Quester", category="Main"},{name="Completionist", category="Main"},{name="Rookie Raider", category="Main"},{name="Raid Veteran", category="Main"},{name="Raid Commander", category="Main"},{name="Raid Warlord", category="Main"},{name="Raid Conqueror", category="Main"},{name="Precise Striker", category="Main"},{name="Critical Sniper", category="Main"},{name="Devastating Precision", category="Main"},{name="Critical Master", category="Main"},{name="Critical Legend", category="Main"},{name="Critical Demigod", category="Main"},{name="Novice Wrecker", category="Main"},{name="Demolition Expert", category="Main"},{name="Destruction Maestro", category="Main"},{name="Damage Dynamo", category="Main"},{name="Cataclysmic Force", category="Main"},{name="Devastation Virtuoso", category="Main"},{name="Titan Hunter", category="Main"},{name="Titan Slayer", category="Main"},{name="Titan Executioner", category="Main"},{name="Titan Butcher", category="Main"},{name="Titan Dominator", category="Main"},{name="Titan Conqueror", category="Main"},{name="Rookie Adventurer", category="Main"},{name="Seasoned Warrior", category="Main"},{name="Master Of Experience", category="Main"},{name="Legendary Ascendant", category="Main"},{name="Divine Prestige", category="Main"},{name="Ultimate Champion", category="Main"},{name="Prestige Aspirant", category="Main"},{name="Prestige Challenger", category="Main"},{name="Prestige Enthusiast", category="Main"},{name="Prestige Expert", category="Main"},
        {name="Casual Explorer", category="Side"},{name="Guardian Angel", category="Side"},{name="Penny Pincher", category="Side"},{name="Eye Of The Storm", category="Side"},{name="Shifting Apprentice", category="Side"},{name="Skill Novice", category="Side"},{name="Team Player", category="Side"},{name="Wealth Accumulator", category="Side"},{name="Rescuer Extraordinaire", category="Side"},{name="Teamwork Enthusiast", category="Side"},{name="Dedicated Adventurer", category="Side"},{name="Skill Practitioner", category="Side"},{name="Shifting Adept", category="Side"},{name="Leg Lacerator", category="Side"},{name="Treasure Hunter", category="Side"},{name="Seasoned Gamer", category="Side"},{name="Cooperative Expert", category="Side"},{name="Skill Expert", category="Side"},{name="Lifesaver Pro", category="Side"},{name="Shifting Expert", category="Side"},{name="Arm Annihilator", category="Side"},{name="Skill Master", category="Side"},{name="Titan Torturer", category="Side"},{name="Teamwork Specialist", category="Side"},{name="Fortune Hoarder", category="Side"},{name="Saving Supreme", category="Side"},{name="Endurance Champion", category="Side"},{name="Shifting Master", category="Side"},{name="Shifting Guru", category="Side"},{name="Titan Annihilator", category="Side"},{name="Teamwork Virtuoso", category="Side"},{name="Timeless Immortal", category="Side"},{name="Money Magician", category="Side"},{name="Skill Virtuoso", category="Side"},{name="Player's Champion", category="Side"},{name="Teamwork Maestro", category="Side"},{name="Skill Prodigy", category="Side"},{name="Legendary Superior", category="Side"},{name="Titan's Nightmare", category="Side"},{name="Ultimate Protector", category="Side"},{name="Ultimate Victor", category="Side"},{name="Shifting Virtuoso", category="Side"},
        {name="Daily 1", category="Daily"},{name="Daily 2", category="Daily"},{name="Daily 3", category="Daily"},
        {name="Weekly 1", category="Weekly"},{name="Weekly 2", category="Weekly"},{name="Weekly 3", category="Weekly"},{name="Weekly 4", category="Weekly"},
        {name="Towers", category="Spears"},{name="Escort", category="Spears"},{name="Ice Burst Stones", category="Spears"},{name="Retrieve Missing Supplies", category="Spears"},{name="Defend Missing Supplies", category="Spears"}
    }
    
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
                getgenv().ClaimQuestRunning = true
                task.spawn(claimAllQuests)
            end
        end
    })
    
    AutoClaimGroup:AddToggle("ClaimAchievementToggle", {
        Text = "Claim Achievement",
        Default = false,
        Callback = function(v)
            getgenv().ClaimAchievementEnabled = v
            if v and not getgenv().ClaimAchievementRunning then
                getgenv().ClaimAchievementRunning = true
                task.spawn(claimAllAchievements)
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








-- ============================== MISC ==============================
local MiscGroup =
    Tabs.AutoFarm:AddLeftGroupbox("Misc")

-- ============================== PLAYER STATS ==============================
local StatsGui = nil
local StatsEnabled = false

local function CreatePlayerStatsHUD()

    if StatsGui then
        StatsGui:Destroy()
        StatsGui = nil
    end

    local Players =
        game:GetService("Players")

    local ReplicatedStorage =
        game:GetService("ReplicatedStorage")

    local LocalPlayer =
        Players.LocalPlayer

    local PlayerGui =
        LocalPlayer:WaitForChild("PlayerGui")

    -- ==================== GUI ====================
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "FakeHubPlayerStats"
    Gui.IgnoreGuiInset = true
    Gui.ResetOnSpawn = false
    Gui.Parent = PlayerGui

    StatsGui = Gui

    -- ==================== MAIN FRAME ====================
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 210, 0, 112)
    Frame.Position = UDim2.new(0.5, -105, 0, 8)
    Frame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    Frame.BackgroundTransparency = 0.15
    Frame.BorderSizePixel = 0
    Frame.Parent = Gui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color = Color3.fromRGB(80, 80, 120)
    Stroke.Thickness = 1
    Stroke.Transparency = 0.5
    Stroke.Parent = Frame

    -- ==================== ACCENT ====================
    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(1, 0, 0, 2)
    AccentBar.BackgroundColor3 =
        Color3.fromRGB(100, 120, 255)

    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = Frame

    -- ==================== TIMER TITLE ====================
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 16)
    Title.Position = UDim2.new(0, 0, 0, 6)
    Title.BackgroundTransparency = 1
    Title.Text = "FARM TIMER"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 9
    Title.TextColor3 =
        Color3.fromRGB(100, 110, 180)

    Title.Parent = Frame

    -- ==================== TIMER ====================
    local TimerLabel =
        Instance.new("TextLabel")

    TimerLabel.Size =
        UDim2.new(1, 0, 0, 28)

    TimerLabel.Position =
        UDim2.new(0, 0, 0, 18)

    TimerLabel.BackgroundTransparency = 1

    TimerLabel.Text = "00:00:00"

    TimerLabel.Font =
        Enum.Font.GothamBold

    TimerLabel.TextSize = 20

    TimerLabel.TextColor3 =
        Color3.fromRGB(230, 230, 255)

    TimerLabel.Parent = Frame

    -- ==================== DIVIDER ====================
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(0.9, 0, 0, 1)
    Divider.Position = UDim2.new(0.05, 0, 0, 50)
    Divider.BackgroundColor3 =
        Color3.fromRGB(80, 80, 120)

    Divider.BackgroundTransparency = 0.6
    Divider.BorderSizePixel = 0
    Divider.Parent = Frame

    -- ==================== PLAYER STATS ====================
    local StatsTitle =
        Instance.new("TextLabel")

    StatsTitle.Size =
        UDim2.new(1, 0, 0, 12)

    StatsTitle.Position =
        UDim2.new(0, 0, 0, 56)

    StatsTitle.BackgroundTransparency = 1
    StatsTitle.Text = "PLAYER STATS"

    StatsTitle.Font =
        Enum.Font.GothamBold

    StatsTitle.TextSize = 8

    StatsTitle.TextColor3 =
        Color3.fromRGB(100, 200, 255)

    StatsTitle.Parent = Frame

    -- ==================== VALUES ====================
    local function MakeStat(name, x, y, color)

        local Text =
            Instance.new("TextLabel")

        Text.Size =
            UDim2.new(0, 50, 0, 16)

        Text.Position =
            UDim2.new(0, x, 0, y)

        Text.BackgroundTransparency = 1
        Text.Text = name

        Text.Font =
            Enum.Font.GothamBold

        Text.TextSize = 10

        Text.TextColor3 =
            Color3.fromRGB(180, 180, 220)

        Text.Parent = Frame

        local Value =
            Instance.new("TextLabel")

        Value.Size =
            UDim2.new(0, 60, 0, 16)

        Value.Position =
            UDim2.new(0, x + 40, 0, y)

        Value.BackgroundTransparency = 1
        Value.Text = "0"

        Value.Font =
            Enum.Font.GothamBold

        Value.TextSize = 10

        Value.TextColor3 = color
        Value.Parent = Frame

        return Value
    end

    local LevelValue =
        MakeStat(
            "Level",
            10,
            72,
            Color3.fromRGB(255, 200, 100)
        )

    local GoldValue =
        MakeStat(
            "Gold",
            110,
            72,
            Color3.fromRGB(255, 215, 100)
        )

    local GemsValue =
        MakeStat(
            "Gems",
            10,
            92,
            Color3.fromRGB(100, 200, 255)
        )

    local CanesValue =
        MakeStat(
            "Canes",
            110,
            92,
            Color3.fromRGB(255, 150, 180)
        )

    -- ==================== TIMER ====================
    getgenv().FarmStartTime =
        getgenv().FarmStartTime or tick()

    local function FormatTime(sec)

        return string.format(
            "%02d:%02d:%02d",
            math.floor(sec / 3600),
            math.floor((sec % 3600) / 60),
            math.floor(sec % 60)
        )
    end

    task.spawn(function()

        while StatsEnabled
            and Gui.Parent
        do

            task.wait(1)

            TimerLabel.Text =
                FormatTime(
                    tick()
                    - getgenv().FarmStartTime
                )
        end
    end)

    -- ==================== FORMAT ====================
    local function FormatNumber(num)

        if num >= 1000000 then

            return string.format(
                "%.1fM",
                num / 1000000
            )

        elseif num >= 1000 then

            return string.format(
                "%.1fK",
                num / 1000
            )
        end

        return tostring(num)
    end

    -- ==================== UPDATE ====================
    local function UpdateStats(data)

        pcall(function()

            if data and data.Slots then

                local slot =
                    data.Current_Slot or "A"

                local slotData =
                    data.Slots[slot]

                if slotData then

                    if slotData.Progression
                        and slotData.Progression.Level
                    then

                        LevelValue.Text =
                            tostring(
                                slotData.Progression.Level
                            )
                    end

                    if slotData.Currency then

                        if slotData.Currency.Gold then

                            GoldValue.Text =
                                FormatNumber(
                                    slotData.Currency.Gold
                                )
                        end

                        if slotData.Currency.Gems then

                            GemsValue.Text =
                                FormatNumber(
                                    slotData.Currency.Gems
                                )
                        end

                        if slotData.Currency.Canes then

                            CanesValue.Text =
                                FormatNumber(
                                    slotData.Currency.Canes
                                )
                        end
                    end
                end
            end
        end)
    end

    -- ==================== FETCH ====================
    local function FetchAndUpdate()

        task.spawn(function()

            pcall(function()

                local remoteGET =
                    ReplicatedStorage
                    :WaitForChild("Assets")
                    :WaitForChild("Remotes")
                    :WaitForChild("GET")

                local data =
                    remoteGET:InvokeServer(
                        "Data",
                        "Copy",
                        LocalPlayer.UserId
                    )

                if data
                    and type(data) == "table"
                then
                    UpdateStats(data)
                end
            end)
        end)
    end

    task.spawn(function()

        while StatsEnabled
            and Gui.Parent
        do

            task.wait(5)

            FetchAndUpdate()
        end
    end)

    FetchAndUpdate()
end

-- ============================== TOGGLE ==============================
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

-- ============================== SAFETY SLIDER ==============================
if Tabs.AutoFarm then
    local SafetyGroup = Tabs.AutoFarm:AddRightGroupbox("Safety Settings")
    SafetyGroup:AddLabel(" -- 25s is safe! --")
    SafetyGroup:AddSlider("SafetyTimeSlider", {
        Text="--- End Missions ---", Default=25, Min=15, Max=60, Rounding=0,
        Callback=function(val)
            getgenv().SafetyTime = math.floor(val)
        end,
        Drag = true
    })
    
    -- 🔥 ตัวเลือกจำนวนไททันที่เหลือก่อนหยุดฆ่า (ก่อน Safety Time)
    getgenv().StopAtTitansLeft = getgenv().StopAtTitansLeft or 10   -- ค่าเริ่มต้น 10 ตัว
    
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
    G.RipperSafety = false
    G.canExecuteRipper = false
    G.SafetyTime = G.SafetyTime or 25
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

    local BladeTab = AutoFarmTabbox:AddTab("Blade")

    BladeTab:AddDropdown("FarmModeDropdown", {
        Values = {"Tween","Teleport"}, 
        Default = "",
        Multi = false, 
        Text = "Farm Select",
        Callback = function(val)
            G.FarmMode = val
            if PendingFarmStart and G.AutoFarmBlade then
                G.Farm = true
                PendingFarmStart = false
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
            if v then
                if G.AutoThunderSpear then
                    if isThunderSpear() then
                        task.wait(0.05)
                        pcall(function()
                            if Options and Options.AutoFarmBlade then
                                Options.AutoFarmBlade:SetValue(false)
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
                
                if not G.FarmMode or G.FarmMode == "" then
                    PendingFarmStart = true
                    G.Farm = false
                    G.AutoFarmBlade = true
                    return
                end
                
                G.AutoFarmBlade = true
                G.Farm = true
                PendingFarmStart = false
            else
                G.AutoFarmBlade = false
                G.Farm = false
                PendingFarmStart = false
            end
        end
    })

    BladeTab:AddToggle("AutoReloadBlade", {
        Text="Auto Reload Blade", Default=false,
        Callback=function(v) G.AutoReloadBlade = v end
    })
    
    BladeTab:AddToggle("StartRejoin", {
        Text="Auto Retry", Default=false,
        Callback=function(v) G.StartRejoin = v end
    })
    
    BladeTab:AddToggle("RipperSafetyToggle", {
        Text="Ripper Safe (No Physics Bug)", Default=false,
        Callback=function(v)
            G.RipperSafety = v
            if not v then G.canExecuteRipper = false end
        end
    })

    local SpearTab = AutoFarmTabbox:AddTab("Thunder Spear")
    
    SpearTab:AddToggle("AutoThunderSpearToggle", {
        Text = "Auto Thunder Spear",
        Default = false,
        Callback = function(v)
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
            end)
        end
    end)

    local TeleportGroup = Tabs.AutoFarm:AddRightGroupbox("Teleport Now")
    local tpLabel = TeleportGroup:AddLabel("")
    local function AddConfirmTP(name, id, time)
        local c = false
        TeleportGroup:AddButton(name, function()
            if c then pcall(function() TeleportService:Teleport(id, Player) end)
            else
                c = true; tpLabel:SetText("Are you sure?")
                task.delay(time or 3, function() c = false; tpLabel:SetText("") end)
            end
        end)
    end
    AddConfirmTP("Teleport to Main Menu", MAIN_MENU_ID, 1.5)
    AddConfirmTP("Teleport to Lobby", LOBBY_ID)
end
-- ============================== THUNDER SPEAR CORE LOGIC (AOE DAMAGE MULTI-TITAN + RELOAD CYCLE) ==============================
if ({[MAIN_MENU_ID]=true,[LOBBY_ID]=true})[game.PlaceId] then return end

local TitansFolder = workspace:WaitForChild("Titans")

task.spawn(function()
    task.wait(1)

    local player = game:GetService("Players").LocalPlayer
    local RunService = game:GetService("RunService")
    local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
    local POST = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("POST")

    -- ==================== SHARED CORE (เหมือนกับ Farm Core) ====================
    local ActiveTitans = {}          -- {titanModel, napePart}
    local LastScan = 0
    local SCAN_RATE = 0.02

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
        for _, t in ipairs(titansFolder:GetChildren()) do
            if t:IsA("Model") and IsTitanAlive(t) then
                local nape = GetNape(t)
                if nape then
                    table.insert(ActiveTitans, {titan = t, nape = nape})
                end
            end
        end
    end

    local function GetClosestEntry(hrpPos)
        local best, bestD = nil, 1e9
        for _, entry in ipairs(ActiveTitans) do
            local n = entry.nape
            local dx = hrpPos.X - n.Position.X
            local dy = hrpPos.Y - n.Position.Y
            local dz = hrpPos.Z - n.Position.Z
            local d = dx*dx + dy*dy + dz*dz
            if d < bestD then
                bestD = d
                best = entry
            end
        end
        return best
    end

    -- ==================== NO-CLIP & MOVEMENT ====================
    local CharParts = {}
    local CharRef = nil

    local function NoclipOn()
        local char = player.Character
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

    local function NoclipOff()
        for i = 1, #CharParts do
            local p = CharParts[i]
            if p and p.Parent then
                p.CanCollide = true
            end
        end
    end

    local _vel = Vector3.zero
    local function MoveFastTween(targetPos, maxSpeed)
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dx = targetPos.X - hrp.Position.X
        local dy = targetPos.Y - hrp.Position.Y
        local dz = targetPos.Z - hrp.Position.Z
        local distH = math.sqrt(dx*dx + dz*dz)
        local distTotal = math.sqrt(dx*dx + dy*dy + dz*dz)
        if distTotal < 2 then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            _vel = Vector3.zero
            return
        end
        local speed = math.min(maxSpeed * 1.5, 1000)
        local desired = Vector3.zero
        if distH > 1 then
            local m = speed / distH
            desired = Vector3.new(dx * m, 0, dz * m)
        end
        if math.abs(dy) > 1 then
            local vy = math.clamp(dy * 20, -speed, speed)
            desired = Vector3.new(desired.X, vy, desired.Z)
        end
        _vel = _vel:Lerp(desired, 0.35)
        if distTotal < 25 then
            _vel = _vel * math.max(0.3, distTotal / 25)
        end
        if _vel.Magnitude > speed then
            _vel = _vel.Unit * speed
        end
        hrp.AssemblyLinearVelocity = _vel
        hrp.AssemblyAngularVelocity = Vector3.zero
    end

    local _teleportBp, _teleportBg = nil, nil
    local function MoveStableTeleport(targetPos)
        local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local dist = (hrp.Position - targetPos).Magnitude
        if dist > 30 then
            hrp.CFrame = CFrame.new(targetPos)
        end
        if not _teleportBp or not _teleportBp.Parent then
            _teleportBp = Instance.new("BodyPosition")
            _teleportBp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
            _teleportBp.P = 50000
            _teleportBp.D = 1000
            _teleportBp.Parent = hrp
        end
        _teleportBp.Position = targetPos
        if not _teleportBg or not _teleportBg.Parent then
            _teleportBg = Instance.new("BodyGyro")
            _teleportBg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
            _teleportBg.P = 50000
            _teleportBg.D = 500
            _teleportBg.Parent = hrp
        end
        _teleportBg.CFrame = CFrame.lookAt(targetPos, targetPos + Vector3.new(0, 0, -1))
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        _vel = Vector3.zero
    end

    local function CleanupTeleport()
        if _teleportBp then _teleportBp:Destroy(); _teleportBp = nil end
        if _teleportBg then _teleportBg:Destroy(); _teleportBg = nil end
    end

    -- ==================== THUNDER SPEAR SPECIFIC LOGIC ====================
    local CurrentEntry = nil
    local LockedUntil = 0
    local CurrentFirePower = 8

    -- 🔥 ค่ารัศมีระเบิด AOE (สามารถปรับใน GUI ได้)
    local EXPLOSION_RADIUS = 0.13  -- ค่าเริ่มต้น 0.13 (ใช้ร่วมกับเกม) หรือจะใช้ค่าที่กำหนดเอง

    local function ReloadSpears()
        pcall(function()
            POST:FireServer("Attacks", "Reload", workspace:WaitForChild("Climbable"):WaitForChild("_Walls"):WaitForChild("Gate"):WaitForChild("GasTanks"):WaitForChild("Refill"))
        end)
        CurrentFirePower = 8
    end

    -- 🔥🔥🔥 ยิงหอก + ระเบิด AOE ครั้งเดียว 🔥🔥🔥
    local function FireThunderSpearAOE()
        if #ActiveTitans == 0 then return end

        -- ถ้าหมดพลัง รีโหลดเร็ว
        if CurrentFirePower <= 0 then
            ReloadSpears()
            task.wait(0.1)  -- หน่วงสั้น ๆ ให้โหลดเสร็จ (ลดจาก 0.5)
            return
        end

        local entry = CurrentEntry
        if not entry or not entry.nape then return end

        local napePos = entry.nape.Position

        -- ยิงหอก 1 นัด
        pcall(function()
            GET:InvokeServer("Spears", "S_Fire", tostring(CurrentFirePower))
            CurrentFirePower = CurrentFirePower - 1
        end)

        -- 🔥 ระเบิดครั้งเดียว ณ ตำแหน่ง Nape เป้าหมายหลัก
        -- ใช้รัศมีจาก G.ThunderSpearExplodeRadius (ปรับให้กว้างพอจะโดนทุกตัว)
        local G = getgenv()
        local radius = G.ThunderSpearExplodeRadius or 30   -- ค่าเริ่มต้น 30 (ครอบคลุมกลุ่มไททัน)
        pcall(function()
            POST:FireServer("Spears", "S_Explode", napePos, radius)
        end)
    end

    local function IsRewardsUIVisible()
        local success = false
        pcall(function()
            local interface = player.PlayerGui:FindFirstChild("Interface")
            if interface then
                local rewards = interface:FindFirstChild("Rewards")
                if rewards and rewards.Visible == true then
                    success = true
                end
            end
        end)
        return success
    end

    -- ==================== MAIN LOOP ====================
    local ThunderConn
    local function CreateThunderLoop()
        if ThunderConn then ThunderConn:Disconnect() end
        ThunderConn = RunService.Heartbeat:Connect(function()
            local ok = pcall(function()
                local G = getgenv()
                if not G.AutoThunderSpear then
                    NoclipOff()
                    CurrentEntry = nil
                    CleanupTeleport()
                    return
                end

                if IsRewardsUIVisible() then
                    G.AutoThunderSpear = false
                    if Options and Options.AutoThunderSpear then
                        Options.AutoThunderSpear:SetValue(false)
                    end
                    return
                end

                local char = player.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hrp or not hum or hum.Health <= 0 then
                    CurrentEntry = nil
                    CleanupTeleport()
                    return
                end

                hrp.AssemblyAngularVelocity = Vector3.zero

                if hrp.Position.Y < -50 then
                    hrp.CFrame = CFrame.new(hrp.Position.X, 80, hrp.Position.Z)
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    _vel = Vector3.zero
                    return
                end

                ScanTitans()

                if #ActiveTitans == 0 then
                    CurrentEntry = nil
                    LockedUntil = 0
                    NoclipOn()
                    CleanupTeleport()
                    local dy = 80 - hrp.Position.Y
                    hrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(dy * 5, -50, 50), 0)
                    _vel = Vector3.zero
                    return
                end

                -- ล็อกเป้าหมาย
                local now = tick()
                if CurrentEntry then
                    local entry = CurrentEntry
                    if not entry.titan or not IsTitanAlive(entry.titan) or not entry.nape or not entry.nape.Parent then
                        CurrentEntry = nil
                    else
                        local d = (hrp.Position - entry.nape.Position).Magnitude
                        if d > 150 and now > LockedUntil then
                            CurrentEntry = nil
                        end
                    end
                end

                if not CurrentEntry then
                    CurrentEntry = GetClosestEntry(hrp.Position)
                    if CurrentEntry then
                        LockedUntil = now + 0.35
                    else
                        return
                    end
                end

                local nape = CurrentEntry.nape
                local hoverHeight = G.ThunderSpearHoverHeight or 120
                local hoverSpeed = G.ThunderSpearHoverSpeed or 120
                local ty = nape.Position.Y + hoverHeight
                local tp = Vector3.new(nape.Position.X, ty, nape.Position.Z)

                NoclipOn()

                if G.ThunderSpearFarmMode == "Teleport" then
                    MoveStableTeleport(tp)
                else
                    CleanupTeleport()
                    MoveFastTween(tp, hoverSpeed)
                end

                -- 🔥 ยิง + ระเบิด AOE ครั้งเดียว (ทุกฮาร์ทบีท)
                FireThunderSpearAOE()
            end)

            if not ok then
                task.wait(1)
                CreateThunderLoop()
            end
        end)
    end

    CreateThunderLoop()

    -- ตัวสำรองกรณี Heartbeat หลุด
    task.spawn(function()
        while task.wait(2) do
            if not ThunderConn or not ThunderConn.Connected then
                CreateThunderLoop()
            end
        end
    end)
end)

-- ============================== FARM CORE ==============================
local TitansFolder = workspace:WaitForChild("Titans")

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

local function AreBladesEmpty()
    local success, result = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        local sets = player.PlayerGui.Interface.HUD.Main.Top["7"].Blades.Sets
        if sets and sets:IsA("TextLabel") then
            local text = sets.Text
            return text:match("^0%s*/") ~= nil
        end
        return false
    end)
    return success and result
end

local function GetBrokenBladeCount()
    local success, count = pcall(function()
        local char = game:GetService("Players").LocalPlayer.Character
        if not char then return 0 end
        local broken = 0
        for _, child in ipairs(char:GetDescendants()) do
            if child.Name:match("^Blade_%d+$") and child:GetAttribute("Broken") == true then
                broken = broken + 1
            end
        end
        return broken
    end)
    return (success and count) or 0
end

local function IsReloadingOrEmpty()
    return AreBladesEmpty() or GetBrokenBladeCount() >= 14
end

-- ตารางรวมข้อมูลไททันที่มีชีวิต (โมเดล + Nape) – รีเฟรชทุก 0.02 วินาที
local ActiveTitans = {}          -- {titanModel, napePart}
local LastScan = 0
local SCAN_RATE = 0.02

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

-- สแกนไททันทั้งหมดใน workspace.Titans โดยไม่สนใจชื่อ (UUID ไม่ซ้ำกัน)
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
    for _, t in ipairs(titansFolder:GetChildren()) do
        if t:IsA("Model") and IsTitanAlive(t) then
            local nape = GetNape(t)
            if nape then
                table.insert(ActiveTitans, {titan = t, nape = nape})
            end
        end
    end
end

-- หาไททันที่ใกล้ที่สุดจาก ActiveTitans
local function GetClosestEntry(hrpPos)
    local best, bestD = nil, 1e9
    for _, entry in ipairs(ActiveTitans) do
        local n = entry.nape
        local dx = hrpPos.X - n.Position.X
        local dy = hrpPos.Y - n.Position.Y
        local dz = hrpPos.Z - n.Position.Z
        local d = dx*dx + dy*dy + dz*dz
        if d < bestD then
            bestD = d
            best = entry
        end
    end
    return best
end

-- ส่วน Noclip & การเคลื่อนที่ (ปรับจูนให้เหมาะกับหลายเป้าหมาย)
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

local function NoclipOff()
    for i = 1, #CharParts do
        local p = CharParts[i]
        if p and p.Parent then
            p.CanCollide = true
        end
    end
end

local _vel = Vector3.zero
local function MoveFastTween(targetPos, maxSpeed)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dx = targetPos.X - hrp.Position.X
    local dy = targetPos.Y - hrp.Position.Y
    local dz = targetPos.Z - hrp.Position.Z
    local distH = math.sqrt(dx*dx + dz*dz)
    local distTotal = math.sqrt(dx*dx + dy*dy + dz*dz)

    if distTotal < 2 then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        _vel = Vector3.zero
        return
    end

    local speed = math.min(maxSpeed * 1.5, 1000)
    local desired = Vector3.zero

    if distH > 1 then
        local m = speed / distH
        desired = Vector3.new(dx * m, 0, dz * m)
    end

    if math.abs(dy) > 1 then
        local vy = math.clamp(dy * 20, -speed, speed)
        desired = Vector3.new(desired.X, vy, desired.Z)
    end

    _vel = _vel:Lerp(desired, 0.35)

    if distTotal < 25 then
        _vel = _vel * math.max(0.3, distTotal / 25)
    end

    if _vel.Magnitude > speed then
        _vel = _vel.Unit * speed
    end

    hrp.AssemblyLinearVelocity = _vel
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local _teleportBp, _teleportBg = nil, nil
local function MoveStableTeleport(targetPos)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dist = (hrp.Position - targetPos).Magnitude
    if dist > 30 then
        hrp.CFrame = CFrame.new(targetPos)
    end

    if not _teleportBp or not _teleportBp.Parent then
        _teleportBp = Instance.new("BodyPosition")
        _teleportBp.MaxForce = Vector3.new(1e5, 1e5, 1e5)
        _teleportBp.P = 50000
        _teleportBp.D = 1000
        _teleportBp.Parent = hrp
    end
    _teleportBp.Position = targetPos

    if not _teleportBg or not _teleportBg.Parent then
        _teleportBg = Instance.new("BodyGyro")
        _teleportBg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
        _teleportBg.P = 50000
        _teleportBg.D = 500
        _teleportBg.Parent = hrp
    end
    _teleportBg.CFrame = CFrame.lookAt(targetPos, targetPos + Vector3.new(0, 0, -1))

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
    _vel = Vector3.zero
end

local function CleanupTeleport()
    if _teleportBp then _teleportBp:Destroy(); _teleportBp = nil end
    if _teleportBg then _teleportBg:Destroy(); _teleportBg = nil end
end

-- ระบบล็อกเป้าหมายและป้องกันการกระโดดไปมา
local CurrentEntry = nil
local LockedUntil = 0
local isDead = false
local IdleHoverY = 80

local function IsRewardsUIVisible()
    local success = false
    pcall(function()
        local interface = Player.PlayerGui:FindFirstChild("Interface")
        if interface then
            local rewards = interface:FindFirstChild("Rewards")
            if rewards and rewards.Visible == true then
                success = true
            end
        end
    end)
    return success
end

local function OnDeath()
    isDead = true
    CurrentEntry = nil
    LockedUntil = 0
    NapeCache = setmetatable({}, {__mode = "k"})
    ActiveTitans = {}
    CharRef = nil
    CharParts = {}
    _vel = Vector3.zero
    CleanupTeleport()
end

local function OnSpawn(char)
    isDead = false
    CharRef = nil
    _vel = Vector3.zero
    CleanupTeleport()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(OnDeath)
    end
end

if Player.Character then OnSpawn(Player.Character) end
Player.CharacterAdded:Connect(OnSpawn)

local FarmConn = nil
local LastAtk = 0
local ATK_DELAY = 0.015

-- โจมตีไททันทั้งหมดที่อยู่ใน ActiveTitans พร้อมกัน
local function AttackAllTitans()
    if #ActiveTitans == 0 then return end

    local G = getgenv()
    local elapsed = G.FarmStartTime > 0 and (tick() - G.FarmStartTime) or 0
    local safe = elapsed >= (G.SafetyTime or 25)
    local dmg = safe and 9999 or 2500

    -- 🔥 ป้องกันการฆ่าไททันตัวสุดท้ายก่อน Safety Time (ใช้ค่าที่ผู้ใช้ตั้ง)
    local stopAt = G.StopAtTitansLeft or 1   -- ค่าเริ่มต้น 1
    if not safe and #ActiveTitans <= stopAt then
        return  -- ข้ามการโจมตีในรอบนี้
    end

    SafeFire(POST, "Attacks", "Slash", true)

    for _, entry in ipairs(ActiveTitans) do
        local nape = entry.nape
        if nape and nape.Parent then
            SafeFire(POST, "Hitboxes", "Register", nape, dmg, 0)
        end
    end
end

local function CreateFarmLoop()
    if FarmConn then FarmConn:Disconnect() end
    FarmConn = RunService.Heartbeat:Connect(function()
        local ok = pcall(function()
            local G = getgenv()
            if not G.Farm or isDead then return end

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
                _vel = Vector3.zero
                return
            end

            ScanTitans()

            -- ไม่มีไททัน → ลอยนิ่ง
            if #ActiveTitans == 0 then
                CurrentEntry = nil
                LockedUntil = 0
                NoclipOn()
                CleanupTeleport()
                local dy = IdleHoverY - hrp.Position.Y
                hrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(dy * 5, -50, 50), 0)
                _vel = Vector3.zero
                return
            end

            -- ล็อกเป้าหมาย (ป้องกันเปลี่ยนเป้าถี่เกิน)
            local now = tick()
            if CurrentEntry then
                local entry = CurrentEntry
                if not entry.titan or not IsTitanAlive(entry.titan) or not entry.nape or not entry.nape.Parent then
                    CurrentEntry = nil
                else
                    local d = (hrp.Position - entry.nape.Position).Magnitude
                    if d > 150 and now > LockedUntil then
                        CurrentEntry = nil
                    end
                end
            end

            if not CurrentEntry then
                CurrentEntry = GetClosestEntry(hrp.Position)
                if CurrentEntry then
                    LockedUntil = now + 0.35
                else
                    return
                end
            end

            local entry = CurrentEntry
            local nape = entry.nape
            local ty = nape.Position.Y + G.HoverHeight
            local tp = Vector3.new(nape.Position.X, ty, nape.Position.Z)

            NoclipOn()

            if G.FarmMode == "Teleport" then
                MoveStableTeleport(tp)
            else
                CleanupTeleport()
                MoveFastTween(tp, G.HoverSpeed)
            end

            if IsReloadingOrEmpty() then return end

            if now - LastAtk < ATK_DELAY then return end
            LastAtk = now

            AttackAllTitans()
        end)

        if not ok then
            task.wait(1)
            CreateFarmLoop()
        end
    end)
end

CreateFarmLoop()

-- ตัวสำรองกรณี Heartbeat หลุด
task.spawn(function()
    while task.wait(2) do
        if not FarmConn or not FarmConn.Connected then
            CreateFarmLoop()
        end
    end
end)


getgenv().AutoReloadBlade = false

getgenv().ReloadConfig = {
    LoopDelay = 0.01,
    RefillCooldown = 2,
    ReloadAtBroken = 14,
    RefillAtHUD = "0/x",
    HUDCheckPattern = "^0%s*/",
}

task.spawn(function()
    local player = game:GetService("Players").LocalPlayer
    local lastRefill = 0

    while true do
        task.wait(getgenv().ReloadConfig.LoopDelay)

        pcall(function()
            if not getgenv().AutoReloadBlade then return end

            local char = player.Character
            if not char then return end

            local cfg = getgenv().ReloadConfig
            local now = tick()

            local broken = 0
            for _, child in ipairs(char:GetDescendants()) do
                if child.Name:match("^Blade_%d+$") and child:GetAttribute("Broken") == true then
                    broken = broken + 1
                end
            end

            local sets = player.PlayerGui.Interface.HUD.Main.Top["7"].Blades.Sets
            local setsText = sets and sets.Text or ""

            if broken >= cfg.ReloadAtBroken then
                game:GetService("ReplicatedStorage"):WaitForChild("Assets")
                    :WaitForChild("Remotes"):WaitForChild("GET")
                    :InvokeServer("Blades", "Reload")
            end

            if now - lastRefill >= cfg.RefillCooldown and setsText:match(cfg.HUDCheckPattern) then
                game:GetService("ReplicatedStorage"):WaitForChild("Assets")
                    :WaitForChild("Remotes"):WaitForChild("POST")
                    :FireServer("Attacks", "Reload",
                        workspace:WaitForChild("Climbable"):WaitForChild("_Walls"):WaitForChild("Gate"):WaitForChild("GasTanks"):WaitForChild("Refill"))
                lastRefill = now
            end
        end)
    end
end)
-- ============================== RIPPER AUTO ==============================
if getgenv().RipperLoaded then return end
getgenv().RipperLoaded = true

local player = game:GetService("Players").LocalPlayer
local titansFolder = workspace:WaitForChild("Titans")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GET = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")

local G = getgenv()
G.RipperSafety = false
G.canExecuteRipper = false
G.RipperActive = false
G.FarmStartTime = tick()

local SKILL_ICONS = {
    ["rbxassetid://15215073606"] = true,
    ["rbxassetid://15215081865"] = true,
}

if not SafeInvoke then
    function SafeInvoke(...)
        return pcall(function() end), nil
    end
end

local function isBlade()
    local weapon = G.GetDetectedWeapon and G.GetDetectedWeapon() or "Unknown"
    return weapon == "Blade"
end

local function isSafeTimeReached()
    local safetyTime = G.SafetyTime or 25
    local elapsed = G.FarmStartTime and G.FarmStartTime > 0 and (tick() - G.FarmStartTime) or 0
    return elapsed >= safetyTime
end

local function getHotbarSlots()
    return player.PlayerGui:FindFirstChild("Interface")
       and player.PlayerGui.Interface:FindFirstChild("HUD")
       and player.PlayerGui.Interface.HUD:FindFirstChild("Main")
       and player.PlayerGui.Interface.HUD.Main:FindFirstChild("Top")
       and player.PlayerGui.Interface.HUD.Main.Top:FindFirstChild("7")
       and player.PlayerGui.Interface.HUD.Main.Top["7"]:FindFirstChild("Hotbar")
end

local function getSkillIconImage(slotNumber)
    local hotbar = getHotbarSlots()
    if not hotbar then return nil end
    
    local slot = hotbar:FindFirstChild("Skill_" .. slotNumber)
    if not slot then return nil end
    
    local inner = slot:FindFirstChild("Inner")
    if not inner then return nil end
    
    local icon = inner:FindFirstChild("Icon")
    if icon and icon:IsA("ImageLabel") and icon.Visible and icon.Image ~= "" then
        return icon.Image
    end
    
    return nil
end

local function isTargetSkill(slotNumber)
    local iconImage = getSkillIconImage(slotNumber)
    return iconImage and SKILL_ICONS[iconImage]
end

local function getTargetSkillSlots()
    local targetSlots = {}
    for slot = 1, 5 do
        if isTargetSkill(slot) then
            table.insert(targetSlots, slot)
        end
    end
    return targetSlots
end

local function getCooldown(slotNumber)
    local ok, num = pcall(function()
        local label = player.PlayerGui
            :WaitForChild("Interface",2):WaitForChild("HUD",2):WaitForChild("Main",2)
            :WaitForChild("Top",2):WaitForChild("7",2)
            :WaitForChild("Hotbar",2):WaitForChild("Skill_"..slotNumber,2)
            :WaitForChild("Cooldown",2):WaitForChild("Label",2)
        return tonumber(string.match(label.Text, "%d+%.?%d*"))
    end)
    return (ok and num) or 0
end

local function fireSkill(slotNumber)
    local args = {"S_Skills", "Usage", slotNumber}
    return pcall(function()
        GET:InvokeServer(unpack(args))
    end)
end

local function getNape(titan)
    local hitboxes = titan:FindFirstChild("Hitboxes")
    if not hitboxes then return end
    local hit = hitboxes:FindFirstChild("Hit")
    if not hit then return end
    local nape = hit:FindFirstChild("Nape")
    if nape and nape:IsA("BasePart") then return nape end
end

local function jitter(pos)
    return pos + Vector3.new(
        math.random(-2,2),
        math.random(-2,2),
        math.random(-2,2)
    )
end

local function runRipperOnce(slotNumber)
    if not G.canExecuteRipper then return false end

    local char = player.Character
    if not char then return false end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local lockedPos = root.Position
    local lockedCF = root.CFrame

    if not fireSkill(slotNumber) then return false end

    local napes = {}
    for _, titan in ipairs(titansFolder:GetChildren()) do
        if titan:IsA("Model") and titan.Name ~= "Attack_Titan" then
            local n = getNape(titan)
            if n then
                table.insert(napes, n)
            end
        end
    end

    for _, n in ipairs(napes) do
        n.CanCollide = false
        n.Anchored = true
        n.Size = Vector3.new(150,150,150)
        n.Transparency = 1
        n.Position = lockedPos
    end

    for i = 1,20 do
        if root and root.Parent then
            root.CFrame = lockedCF
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        for _, n in ipairs(napes) do
            if n and n.Parent then
                n.Position = jitter(lockedPos)
            end
        end
        task.wait(0.003)
    end

    for _, titan in ipairs(titansFolder:GetChildren()) do
        if titan:IsA("Model") and titan.Name ~= "Attack_Titan" then
            local n = getNape(titan)
            local fake = titan:FindFirstChild("Fake")
            local head = fake and fake:FindFirstChild("Head")
            if n and head then
                n.Position = head.Position - Vector3.new(2,5,0)
                n.Transparency = 1
                n.CanCollide = false
                n.Anchored = true
            end
        end
    end

    return true
end

local function getReadySlots()
    local readySlots = {}
    local targetSlots = getTargetSkillSlots()
    
    for _, slot in ipairs(targetSlots) do
        local cd = getCooldown(slot)
        if cd == 0 or cd == 90 then
            table.insert(readySlots, slot)
        end
    end
    return readySlots
end

task.spawn(function()
    while true do
        task.wait(0.1)

        pcall(function()
            if not G.RipperSafety then
                G.canExecuteRipper = false
                G.RipperActive = false
                return
            end

            if not isBlade() then
                G.canExecuteRipper = false
                G.RipperActive = false
                return
            end

            if not isSafeTimeReached() then 
                G.canExecuteRipper = false
                G.RipperActive = false
                return 
            end

            local readySlots = getReadySlots()
            
            if #readySlots == 0 then 
                G.canExecuteRipper = false
                G.RipperActive = false
                return 
            end

            G.RipperActive = true
            G.canExecuteRipper = true

            for _, slot in ipairs(readySlots) do
                if not G.RipperSafety then break end
                if not isBlade() then break end
                if not isSafeTimeReached() then break end
                
                runRipperOnce(slot)
                task.wait(0.15)
            end

            G.canExecuteRipper = false
            G.RipperActive = false

            task.wait(1)
        end)
    end
end)
-- ============================== AUTO RETRY ==============================
if Tabs.AutoFarm then
    task.spawn(function()
        local lastClick = 0
        local cooldown = 2
        local hasNotifiedThisRound = false  -- 🔥 เช็คว่าแจ้งเตือนไปแล้วหรือยังในรอบนี้
        
        -- ฟังก์ชันเช็ค visibility แบบเดียวกับที่คุณให้มา
        local function IsActuallyVisible(gui)
            if not gui or not gui.Visible then
                return false
            end
            local current = gui.Parent
            while current and current ~= game do
                if current:IsA("GuiObject") then
                    if not current.Visible then
                        return false
                    end
                end
                current = current.Parent
            end
            return true
        end
        
        -- 🔥 ตัวแปรตามสถานะ open/close
        local LastState = nil
        
        while true do
            task.wait(0.2)
            
            if not getgenv().StartRejoin then 
                LastState = nil
                hasNotifiedThisRound = false  -- 🔥 รีเซ็ตเมื่อปิด
                continue 
            end
            
            local player = game:GetService("Players").LocalPlayer
            local VIM = game:GetService("VirtualInputManager")
            local GS = game:GetService("GuiService")
            
            local interface = player.PlayerGui:FindFirstChild("Interface")
            if not interface then 
                LastState = nil
                hasNotifiedThisRound = false  -- 🔥 รีเซ็ตเมื่อไม่มี Interface
                continue 
            end
            
            local rewards = interface:FindFirstChild("Rewards")
            if not rewards then 
                LastState = nil
                hasNotifiedThisRound = false  -- 🔥 รีเซ็ตเมื่อไม่มี Rewards
                continue 
            end
            
            local retry = rewards.Main.Info.Main.Buttons.Retry
            if not retry then 
                LastState = nil
                hasNotifiedThisRound = false  -- 🔥 รีเซ็ตเมื่อไม่มีปุ่ม
                continue 
            end
            
            -- 🔥 เช็คสถานะ open/close
            local currentState = IsActuallyVisible(retry) and "open" or "close"
            
            -- 🔥 รีเซ็ต notify flag เมื่อปุ่มปิดไปแล้วเปิดใหม่
            if currentState ~= LastState then
                LastState = currentState
                if currentState == "open" then
                    hasNotifiedThisRound = false  -- 🔥 ปุ่มเปิดใหม่ ให้ notify ได้อีกครั้ง
                end
            end
            
            -- 🔥 ต้องเป็น OPEN เท่านั้นถึงจะทำงานต่อ
            if currentState ~= "open" then continue end
            if not retry.Visible then continue end
            if retry.AbsoluteSize.X <= 0 or retry.AbsoluteSize.Y <= 0 then continue end
            
            if tick() - lastClick < cooldown then continue end
            
            local obj = retry
            local allVisible = true
            while obj and obj ~= player.PlayerGui do
                if obj:IsA("GuiObject") and not obj.Visible then allVisible = false; break end
                if obj:IsA("ScreenGui") and not obj.Enabled then allVisible = false; break end
                obj = obj.Parent
            end
            if not allVisible then continue end
            
            GS.SelectedObject = retry
            task.wait(0.05)
            VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.05)
            VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            task.wait(0.1)
            GS.SelectedObject = nil
            
            lastClick = tick()
            
            -- 🔥 แจ้งเตือนครั้งเดียวต่อรอบ
            if not hasNotifiedThisRound then
                hasNotifiedThisRound = true
                pcall(function()
                    Library:Notify("🔄 Retry Clicked!", 3)
                end)
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
    
    local function sendWebhook(missionState)
        if webhookURL == "" then return end
        
        local player = game:GetService("Players").LocalPlayer
        
        local data = nil
        local ok, d = pcall(function()
            local GET = game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET")
            return GET:InvokeServer("Data", "Copy")
        end)
        if ok and d then data = d
        else
            local ok2, d2 = pcall(function()
                return run_on_actor(getactors()[1], [[
                    local args = {"Data", "Copy"}
                    return game:GetService("ReplicatedStorage"):WaitForChild("Assets"):WaitForChild("Remotes"):WaitForChild("GET"):InvokeServer(unpack(args))
                ]])
            end)
            if ok2 and d2 then data = d2 else return end
        end
        
        if not data or not data.Slots then return end
        local slot = data.Slots[data.Current_Slot or "A"]
        if not slot then return end
        
        local fields = {}
        
        -- ========== ADD MISSION INFO (MAP, DIFFICULTY, OBJECTIVE, MODIFIERS) ==========
        if data.Map then
            local modsText = "None"
            if data.Map.Modifiers and type(data.Map.Modifiers) == "table" then
                local modList = {}
                -- รองรับทั้ง table array และ table dictionary
                for k, v in pairs(data.Map.Modifiers) do
                    if type(k) == "number" then
                        table.insert(modList, tostring(v))
                    elseif type(v) == "boolean" and v then
                        table.insert(modList, tostring(k))
                    elseif type(v) == "string" then
                        table.insert(modList, v)
                    end
                end
                if #modList > 0 then
                    modsText = table.concat(modList, ", ")
                end
            end
            local mapValue = string.format("```Map: %s\nDifficulty: %s\nObjective: %s\nModifiers: %s```",
                data.Map.Map or "Unknown",
                data.Map.Difficulty or "Unknown",
                data.Map.Objective or "Unknown",
                modsText
            )
            table.insert(fields, {
                name = "📍 Mission Info",
                value = mapValue,
                inline = false
            })
        end
        
        if filters.Currency then
            table.insert(fields, {
                name = "Currency",
                value = string.format("```Gold: %s\nGems: %s\nCanes: %s\nShards: %s```",
                    fmt(slot.Currency and slot.Currency.Gold or 0),
                    fmt(slot.Currency and slot.Currency.Gems or 0),
                    fmt(slot.Currency and slot.Currency.Canes or 0),
                    fmt(slot.Currency and slot.Currency.Shards or 0)
                ),
                inline = true
            })
        end
        
        if filters.Progression then
            table.insert(fields, {
                name = "Progression",
                value = string.format("```Level: %s\nPrestige: %s\nXP: %s/%s```",
                    slot.Progression and slot.Progression.Level or 0,
                    slot.Progression and slot.Progression.Prestige or 0,
                    fmt(slot.Progression and slot.Progression.XP or 0),
                    fmt(slot.Progression and slot.Progression.Max_XP or 0)
                ),
                inline = true
            })
        end
        
        if filters.Loadout then
            table.insert(fields, {
                name = "Loadout",
                value = string.format("```Weapon: %s\nSlot: %s\nSpins: %s```",
                    slot.Weapon or "?",
                    data.Current_Slot or "A",
                    fmt(slot.Total_Spins or 0)
                ),
                inline = true
            })
        end
        
        if filters.Inventory and slot.Inventory and slot.Inventory.Items then
            local text, count = getItems(slot.Inventory.Items, "• ")
            if text then
                table.insert(fields, {
                    name = "Inventory (" .. count .. " items)",
                    value = "```" .. text .. "```",
                    inline = false
                })
            end
        end
        
        if filters.Cosmetics and slot.Inventory and slot.Inventory.Cosmetics then
            local text, count = getItems(slot.Inventory.Cosmetics, "• ")
            if text then
                table.insert(fields, {
                    name = "Cosmetics (" .. count .. " items)",
                    value = "```" .. text .. "```",
                    inline = false
                })
            end
        end
        
        local isCompleted = missionState and (missionState:find("COMPLETED") or missionState:find("FINISHED"))
        local color = isCompleted and 65280 or 16711680
        
        local body = game:GetService("HttpService"):JSONEncode({
            embeds = {{
                title = (missionState or "Mission End") .. " - " .. player.Name,
                color = color,
                fields = fields,
                footer = {text = os.date("%Y-%m-%d %H:%M:%S")}
            }}
        })
        
        pcall(function()
            request({Url = webhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body})
        end)
    end
    
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
            
            task.wait(1.5)
            
            local missionState = getMissionState()
            
            if missionState == lastMissionState and missionState ~= "" then return end
            lastMissionState = missionState
            
            sendWebhook(missionState)
            hasSentWebhook = true
        end)
    end)
    
    WebhookGroup:AddInput("WebhookURL", {
        Default = "", Numeric = false, Finished = true,
        Text = "Discord Webhook URL",
        Placeholder = "https://discord.com/api/webhooks/...",
        Callback = function(v) webhookURL = v end
    })
    
    WebhookGroup:AddDivider()
    
    WebhookGroup:AddDropdown("WebhookFilters", {
        Values = {"Currency", "Progression", "Loadout", "Inventory", "Cosmetics"},
        Default = {"Currency", "Progression", "Loadout", "Inventory", "Cosmetics"},
        Multi = true,
        Text = "Report Items",
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
            if not v then hasSentWebhook = false; lastMissionState = "" end
        end
    })
    
    WebhookGroup:AddButton("Test Send", function()
        if webhookURL == "" then return end
        local body = game:GetService("HttpService"):JSONEncode({
            content = "Test from Us Suite!",
            embeds = {{title = "Webhook Working!", color = 65280, footer = {text = os.date("%Y-%m-%d %H:%M:%S")}}}
        })
        pcall(function() request({Url = webhookURL, Method = "POST", Headers = {["Content-Type"] = "application/json"}, Body = body}) end)
    end)
end
-- ============================== MISC (SKIP CUTSCENE) ==============================
if Tabs.AutoFarm then
    local MiscGroup = Tabs.AutoFarm:AddRightGroupbox("Skip Cutscene")
    
    local skipEnabled = false
    local skipRunning = false
    
    local function clickSkipButton()
        local player = game:GetService("Players").LocalPlayer
        local VIM = game:GetService("VirtualInputManager")
        local GS = game:GetService("GuiService")
        
        local interface = player.PlayerGui:FindFirstChild("Interface")
        if not interface then return false end
        
        local skip = interface:FindFirstChild("Skip")
        if not skip or not skip.Visible then return false end
        
        local target = skip:FindFirstChild("Main")
        if not target then return false end
        if not target.Visible then return false end
        if target.AbsoluteSize.X <= 0 or target.AbsoluteSize.Y <= 0 then return false end
        
        local obj = target
        while obj and obj ~= player.PlayerGui do
            if obj:IsA("GuiObject") and not obj.Visible then return false end
            if obj:IsA("ScreenGui") and not obj.Enabled then return false end
            obj = obj.Parent
        end
        
        GS.SelectedObject = target
        task.wait(0.05)
        VIM:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
        task.wait(0.05)
        VIM:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
        task.wait(0.1)
        GS.SelectedObject = nil
        
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
            
            local interface = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Interface")
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
    
    SpearGroup:AddToggle("AutoSpearQuestToggle", {
        Text="Auto Spear Quest",
        Default=false,
        Callback=function(v)
            spearQuestEnabled = v
            if v and not spearQuestRunning then
                spearQuestRunning = true
                task.spawn(function()
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
