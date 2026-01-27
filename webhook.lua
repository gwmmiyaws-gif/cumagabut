-- ==================== FISH IT WEBHOOK BY RADITYA ====================
-- Delta Executor (Android) Compatible Version - v3.1 AUTO SAVE CONFIG
-- Enhanced Webhook + Disconnect Monitor + Chloe X Blatant Fishing

print("=" .. string.rep("=", 50))
print("🎣 Webhook By Raditya Loaded! (v3.1 + Auto Save Config)")
print("=" .. string.rep("=", 50))

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")

-- ==================== CONFIG FILE PATH ====================
local CONFIG_FILE = "RadityaWebhook_Config_v3.1.json"

-- ==================== MOBILE COMPATIBILITY LAYER ====================
local function isMobileExecutor()
    if not identifyexecutor then return false end
    local execName = identifyexecutor():lower()
    return execName:find("delta") or execName:find("mobile") or execName:find("android")
end

local function mobileRequest(options)
    local requestFunc = http_request or request or (syn and syn.request) or httprequest
    
    if not requestFunc then
        warn("[Delta Compat] No request function found!")
        return {Success = false, StatusCode = 0, Error = "No HTTP function available"}
    end
    
    local success, response = pcall(function()
        return requestFunc(options)
    end)
    
    if success and response then
        return {
            Success = true, 
            StatusCode = response.StatusCode or response.Code or 200,
            Body = response.Body
        }
    else
        return {
            Success = false, 
            StatusCode = 0, 
            Error = tostring(response)
        }
    end
end

local function safeGetMetatable()
    local funcs = {getrawmetatable, getmetatable}
    for _, func in ipairs(funcs) do
        if func then
            local success, mt = pcall(function()
                return func(game)
            end)
            if success and mt then return mt end
        end
    end
    return nil
end

local function safeSetReadonly(tbl, state)
    if not tbl then return false end
    local funcs = {setreadonly, make_writeable, makewriteable, make_readonly}
    for _, func in ipairs(funcs) do
        if func then
            local success = pcall(function() func(tbl, state) end)
            if success then return true end
        end
    end
    return false
end

local function safeNewCClosure(func)
    local closureFuncs = {newcclosure, newlclosure}
    for _, closureFunc in ipairs(closureFuncs) do
        if closureFunc then
            local success, result = pcall(closureFunc, func)
            if success then return result end
        end
    end
    return func
end

local function safeCheckCaller()
    if checkcaller then return checkcaller() end
    if is_protosmasher_caller then return is_protosmasher_caller() end
    if get_calling_script then return get_calling_script() == nil end
    return true
end

local function safeGetNamecallMethod()
    if getnamecallmethod then return getnamecallmethod() end
    return ""
end

-- ==================== LOAD CRITICAL MODULES ====================
local ItemUtility, TierUtility

local function loadModules()
    local success = pcall(function()
        ItemUtility = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 10))
        TierUtility = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 10))
    end)
    
    if not success then
        warn("[Module Load] Failed to load ItemUtility/TierUtility")
    end
    
    return success
end

loadModules()

-- ==================== REMOTES ====================
local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}

local function GetRemote(remotePath, name, timeout)
    local currentInstance = ReplicatedStorage
    for _, childName in ipairs(remotePath) do
        currentInstance = currentInstance:WaitForChild(childName, timeout or 1)
        if not currentInstance then return nil end
    end
    return currentInstance:FindFirstChild(name)
end

-- Cache remotes
local Remotes = {
    EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar"),
    ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod"),
    RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted"),
    FishingCompleted = GetRemote(RPath, "RE/FishingCompleted"),
    CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs"),
    UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState"),
    ObtainedNewFishNotification = GetRemote(RPath, "RE/ObtainedNewFishNotification")
}

-- ==================== VARIABLES ====================
-- Webhook Configuration
local WEBHOOK_URL = ""
local DISCONNECT_WEBHOOK_URL = ""
local DISCORD_USER_ID = ""
local WEBHOOK_USERNAME = "Raditya Fish Notify v3.1"
local isWebhookEnabled = false
local isDisconnectWebhookEnabled = false
local SelectedRarityCategories = {}
local SelectedWebhookItemNames = {}
local ImageURLCache = {}

-- Chloe X Blatant Fishing Configuration
local blatantInstantState = false
local blatantLoopThread = nil
local blatantEquipThread = nil
_G.Instant = false
local CancelWaitTime = 3
local ResetTimer = 0.5
local hasTriggeredBug = false
local lastFishTime = 0
local fishConnected = false
local lastCancelTime = 0
local hasFishingEffect = false

-- Disconnect Detection
local hasSentDisconnect = false
local disconnectMonitorActive = false

-- Statistics
local totalFishCaught = 0
local successfulWebhooks = 0
local failedWebhooks = 0

-- Performance Statistics
local performanceStats = {
    fps = 0,
    ping = 0,
    memory = 0,
    lastUpdate = 0
}

-- ==================== CONFIG SAVE/LOAD SYSTEM ====================
local function SaveConfig()
    local config = {
        webhookUrl = WEBHOOK_URL,
        disconnectWebhookUrl = DISCONNECT_WEBHOOK_URL,
        discordUserId = DISCORD_USER_ID,
        isWebhookEnabled = isWebhookEnabled,
        isDisconnectWebhookEnabled = isDisconnectWebhookEnabled,
        selectedRarities = SelectedRarityCategories,
        selectedFishNames = SelectedWebhookItemNames,
        blatantDelay = CancelWaitTime,
        version = "3.1"
    }
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(config)
    end)
    
    if success and encoded then
        writefile(CONFIG_FILE, encoded)
        print("✅ Config saved successfully")
        return true
    else
        warn("❌ Failed to save config")
        return false
    end
end

local function LoadConfig()
    if not isfile(CONFIG_FILE) then
        print("📁 No config file found, using defaults")
        return false
    end
    
    local success, result = pcall(function()
        local fileContent = readfile(CONFIG_FILE)
        return HttpService:JSONDecode(fileContent)
    end)
    
    if success and result then
        WEBHOOK_URL = result.webhookUrl or ""
        DISCONNECT_WEBHOOK_URL = result.disconnectWebhookUrl or ""
        DISCORD_USER_ID = result.discordUserId or ""
        isWebhookEnabled = result.isWebhookEnabled or false
        isDisconnectWebhookEnabled = result.isDisconnectWebhookEnabled or false
        SelectedRarityCategories = result.selectedRarities or {}
        SelectedWebhookItemNames = result.selectedFishNames or {}
        CancelWaitTime = result.blatantDelay or 3
        
        print("✅ Config loaded successfully")
        print("📨 Fish Webhook:", WEBHOOK_URL ~= "" and "Set" or "Empty")
        print("🔔 Disconnect Webhook:", DISCONNECT_WEBHOOK_URL ~= "" and "Set" or "Empty")
        
        return true
    else
        warn("❌ Failed to load config, using defaults")
        return false
    end
end

-- ==================== PERFORMANCE MONITOR ====================
task.spawn(function()
    while task.wait(0.5) do
        local now = os.clock()
        if now - performanceStats.lastUpdate >= 0.5 then
            performanceStats.fps = math.floor(workspace:GetRealPhysicsFPS())
            
            local success = pcall(function()
                local networkStats = Stats.Network.ServerStatsItem
                local pingValue = networkStats["Data Ping"]
                if pingValue then
                    performanceStats.ping = math.floor(pingValue:GetValue())
                end
            end)
            
            if not success then
                performanceStats.ping = 0
            end
            
            local memStats = Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Instances)
            performanceStats.memory = math.floor(memStats)
            
            performanceStats.lastUpdate = now
        end
    end
end)

-- ==================== HELPER FUNCTIONS ====================
local function FormatNumber(n)
    if not n then return "0" end
    n = math.floor(tonumber(n) or 0)
    local formatted = tostring(n):reverse():gsub("(%d%d%d)", "%1."):reverse()
    return formatted:gsub("^%.", "")
end

local function GetPlayerDataReplion()
    local success, replion = pcall(function()
        local ReplionModule = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replion", 5)
        if not ReplionModule then return nil end
        return require(ReplionModule).Client:WaitReplion("Data", 5)
    end)
    
    return success and replion or nil
end

local function GetFishNameAndRarity(item)
    local name = item.Identifier or "Unknown"
    local rarity = "COMMON"
    local itemID = item.Id

    if ItemUtility and itemID then
        local itemData = nil
        pcall(function()
            itemData = ItemUtility:GetItemData(itemID)
            if not itemData then
                local numericID = tonumber(item.Id) or tonumber(item.Identifier)
                if numericID then 
                    itemData = ItemUtility:GetItemData(numericID)
                end
            end
        end)

        if itemData and itemData.Data and itemData.Data.Name then
            name = itemData.Data.Name
        end

        if item.Metadata and item.Metadata.Rarity then
            rarity = item.Metadata.Rarity
        elseif itemData and itemData.Probability and itemData.Probability.Chance and TierUtility then
            pcall(function()
                local tierObj = TierUtility:GetTierFromRarity(itemData.Probability.Chance)
                if tierObj and tierObj.Name then 
                    rarity = tierObj.Name 
                end
            end)
        end
    end

    return name, rarity
end

local function GetItemMutationString(item)
    if not item.Metadata then return "" end
    if item.Metadata.Shiny == true then return "✨ Shiny" end
    return item.Metadata.VariantId or ""
end

local function GetRobloxAssetImage(assetId)
    if not assetId or assetId == 0 then return nil end
    if ImageURLCache[assetId] then return ImageURLCache[assetId] end
    
    local url = string.format(
        "https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false", 
        assetId
    )
    
    local success, response = pcall(game.HttpGet, game, url)
    
    if success then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, response)
        if ok and data and data.data and data.data[1] and data.data[1].imageUrl then
            local finalUrl = data.data[1].imageUrl
            ImageURLCache[assetId] = finalUrl
            return finalUrl
        end
    end
    
    return nil
end

local function getRarityColor(rarity)
    local colorMap = {
        SECRET = 0xFFD700,
        DEV = 0xFFD700,
        MYTHIC = 0x9400D3,
        LEGENDARY = 0xFF4500,
        EPIC = 0x8A2BE2,
        RARE = 0x0000FF,
        UNCOMMON = 0x00FF00,
        COMMON = 0x00BFFF
    }
    
    return colorMap[rarity:upper()] or 0x00BFFF
end

local function getWebhookItemOptions()
    local itemNames = {}
    local itemsContainer = ReplicatedStorage:FindFirstChild("Items")
    
    if itemsContainer then
        for _, itemObject in ipairs(itemsContainer:GetChildren()) do
            local itemName = itemObject.Name
            if type(itemName) == "string" and #itemName >= 3 and not itemName:match("^!!!") then
                table.insert(itemNames, itemName)
            end
        end
    end
    
    table.sort(itemNames)
    return itemNames
end

-- ==================== WEBHOOK SYSTEM ====================
local function sendExploitWebhook(url, username, embed_data)
    if not url or url == "" then 
        return false, "Empty URL" 
    end
    
    local payload = {
        username = username,
        embeds = {embed_data}
    }
    
    local success, json_data = pcall(HttpService.JSONEncode, HttpService, payload)
    if not success then
        return false, "JSON Encode Error"
    end
    
    local response = mobileRequest({
        Url = url,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = json_data
    })
    
    if response.Success and (response.StatusCode == 200 or response.StatusCode == 204) then
        return true, "Sent"
    end
    
    return false, response.Error or "HTTP Error"
end

local function shouldNotify(fishRarityUpper, fishMetadata, fishName)
    if #SelectedRarityCategories > 0 and table.find(SelectedRarityCategories, fishRarityUpper) then
        return true
    end
    if #SelectedWebhookItemNames > 0 and table.find(SelectedWebhookItemNames, fishName) then
        return true
    end
    return false
end

-- ==================== DISCONNECT WEBHOOK SYSTEM ====================
local function SendDisconnectWebhook(reason)
    if not isDisconnectWebhookEnabled or hasSentDisconnect then
        return
    end
    
    hasSentDisconnect = true
    
    local webhookUrl = DISCONNECT_WEBHOOK_URL
    if not webhookUrl or webhookUrl == "" then
        warn("[Disconnect] No webhook URL set")
        return
    end
    
    local playerName = LocalPlayer.Name
    local displayName = LocalPlayer.DisplayName
    local userId = tostring(LocalPlayer.UserId)
    
    -- Format timestamp
    local timeData = os.date("*t")
    local timestamp = string.format(
        "%02d/%02d/%04d %02d:%02d %s",
        timeData.day,
        timeData.month,
        timeData.year,
        timeData.hour > 12 and timeData.hour - 12 or timeData.hour,
        timeData.min,
        timeData.hour >= 12 and "PM" or "AM"
    )
    
    -- Prepare mention
    local mentionText = ""
    if DISCORD_USER_ID and DISCORD_USER_ID ~= "" then
        mentionText = string.format("🔔 <@%s> Your account got disconnected!", DISCORD_USER_ID:gsub("%D", ""))
    else
        mentionText = "🔔 Account Disconnected Alert!"
    end
    
    -- Clean reason
    local cleanReason = (reason and reason ~= "") and reason or "Unknown Reason / Kicked"
    
    -- Get current stats
    local currentCoins = 0
    local caughtCount = 0
    
    pcall(function()
        local replion = GetPlayerDataReplion()
        if replion then
            currentCoins = replion:Get("Coins") or replion:Get({"Coins"}) or 0
        end
        
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local caughtStat = leaderstats:FindFirstChild("Caught")
            if caughtStat then
                caughtCount = caughtStat.Value
            end
        end
    end)
    
    local embed = {
        title = "⚠️ PLAYER DISCONNECTED",
        description = mentionText,
        color = 0xFF0000,
        fields = {
            {name = "👤 Player Name", value = string.format("`%s (@%s)`", playerName, displayName), inline = true},
            {name = "🆔 User ID", value = string.format("`%s`", userId), inline = true},
            {name = "⏰ Time", value = string.format("`%s`", timestamp), inline = false},
            {name = "❌ Disconnect Reason", value = string.format("```%s```", cleanReason), inline = false},
            {name = "💰 Last Coins", value = string.format("`%s`", FormatNumber(currentCoins)), inline = true},
            {name = "🐟 Fish Caught", value = string.format("`%s`", FormatNumber(caughtCount)), inline = true},
        },
        thumbnail = {
            url = "https://media.tenor.com/rx88bhLtmyUAAAAi/gawr-gura.gif"
        },
        footer = {
            text = "Raditya Disconnect Monitor v3.1",
            icon_url = "https://i.imgur.com/WltO8IG.png"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
    }
    
    task.spawn(function()
        local success, message = sendExploitWebhook(webhookUrl, "Raditya Disconnect Alert", embed)
        if success then
            print("✅ Disconnect webhook sent successfully")
        else
            warn("❌ Failed to send disconnect webhook:", message)
        end
    end)
end

-- Monitor for disconnects
local function StartDisconnectMonitor()
    if disconnectMonitorActive then return end
    disconnectMonitorActive = true
    
    -- Monitor ErrorMessageChanged
    GuiService.ErrorMessageChanged:Connect(function(errorMessage)
        if errorMessage and errorMessage ~= "" and not hasSentDisconnect then
            print("[Disconnect Detected] Reason:", errorMessage)
            SendDisconnectWebhook(errorMessage)
        end
    end)
    
    -- Monitor OnTeleport
    LocalPlayer.OnTeleport:Connect(function(teleportState)
        if teleportState == Enum.TeleportState.Started then
            hasSentDisconnect = true
            print("[Teleport Detected] Blocking disconnect webhook")
        end
    end)
    
    -- Monitor Player Removing
    Players.PlayerRemoving:Connect(function(player)
        if player == LocalPlayer and not hasSentDisconnect then
            SendDisconnectWebhook("Player was removed from server")
        end
    end)
    
    print("✅ Disconnect monitor started")
end

local function onFishObtained(itemId, metadata, fullData)
    local success, results = pcall(function()
        local dummyItem = {Id = itemId, Metadata = metadata}
        local fishName, fishRarity = GetFishNameAndRarity(dummyItem)
        local fishRarityUpper = fishRarity:upper()

        local fishWeight = string.format("%.2fkg", metadata.Weight or 0)
        local mutationString = GetItemMutationString(dummyItem)
        local mutationDisplay = mutationString ~= "" and mutationString or "N/A"
        
        local itemData = ItemUtility and ItemUtility:GetItemData(itemId)
        
        local assetId = nil
        if itemData and itemData.Data then
            local iconRaw = itemData.Data.Icon or itemData.Data.ImageId
            if iconRaw then
                assetId = tonumber(string.match(tostring(iconRaw), "%d+"))
            end
        end

        local imageUrl = assetId and GetRobloxAssetImage(assetId) or 
                        "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png"
        
        local basePrice = (itemData and itemData.SellPrice) or 0
        local sellPrice = basePrice * (metadata.SellMultiplier or 1)
        local formattedSellPrice = FormatNumber(sellPrice) .. "$"
        
        local caughtDisplay = "N/A"
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        if leaderstats then
            local caughtStat = leaderstats:FindFirstChild("Caught")
            if caughtStat then
                caughtDisplay = FormatNumber(caughtStat.Value)
            end
        end

        local currentCoins = 0
        local replion = GetPlayerDataReplion()
        if replion then
            pcall(function()
                local CurrencyConfig = require(ReplicatedStorage.Modules.CurrencyUtility.Currency)
                if CurrencyConfig and CurrencyConfig["Coins"] then
                    currentCoins = replion:Get(CurrencyConfig["Coins"].Path) or 0
                else
                    currentCoins = replion:Get("Coins") or replion:Get({"Coins"}) or 0
                end
            end)
        end
        local formattedCoins = FormatNumber(currentCoins)

        local isUserFilterMatch = shouldNotify(fishRarityUpper, metadata, fishName)

        if isWebhookEnabled and WEBHOOK_URL ~= "" and isUserFilterMatch then
            local embed = {
                title = string.format("🎣 New Fish Caught! (%s)", fishName),
                description = string.format("Caught by **%s**", LocalPlayer.DisplayName or LocalPlayer.Name),
                color = getRarityColor(fishRarityUpper),
                fields = {
                    {name = "🐟 Fish Name", value = string.format("`%s`", fishName), inline = true},
                    {name = "🏆 Rarity", value = string.format("`%s`", fishRarityUpper), inline = true},
                    {name = "⚖️ Weight", value = string.format("`%s`", fishWeight), inline = true},
                    {name = "✨ Mutation", value = string.format("`%s`", mutationDisplay), inline = true},
                    {name = "💰 Sell Price", value = string.format("`%s`", formattedSellPrice), inline = true},
                    {name = "💵 Coins", value = string.format("`%s`", formattedCoins), inline = true},
                    {name = "📊 Performance", value = string.format("`FPS: %d | Ping: %dms`", 
                        performanceStats.fps, performanceStats.ping), inline = false}
                },
                thumbnail = {url = imageUrl},
                footer = {
                    text = string.format("Raditya Webhook v3.1 • Total: %s • %s", 
                        caughtDisplay, os.date("%Y-%m-%d %H:%M:%S"))
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
            }
            
            local success_send, message = sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, embed)
            if success_send then
                successfulWebhooks = successfulWebhooks + 1
                print(string.format("✅ Webhook sent: %s (%s)", fishName, fishRarityUpper))
            else
                failedWebhooks = failedWebhooks + 1
                warn(string.format("❌ Webhook failed: %s", message))
            end
        end
        
        return true
    end)
    
    if not success then
        warn("[Fish Obtained Error]:", results)
    end
end

-- Hook fish notification
if Remotes.ObtainedNewFishNotification then
    Remotes.ObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata, fullData)
        totalFishCaught = totalFishCaught + 1
        task.spawn(function()
            pcall(function() 
                onFishObtained(itemId, metadata, fullData) 
            end)
        end)
    end)
end

-- ==================== CHLOE X BLATANT FISHING SYSTEM ====================
-- Logic Killer
task.spawn(function()
    local success, FishingController = pcall(function() 
        return require(ReplicatedStorage.Controllers.FishingController) 
    end)
    
    if success and FishingController then
        local Old_Charge = FishingController.RequestChargeFishingRod
        local Old_Cast = FishingController.SendFishingRequestToServer
        
        FishingController.RequestChargeFishingRod = function(...)
            if _G.Instant then return end
            return Old_Charge(...)
        end
        
        FishingController.SendFishingRequestToServer = function(...)
            if _G.Instant then 
                return false, "Blocked by Chloe X Blatant" 
            end
            return Old_Cast(...)
        end
        
        print("✅ Fishing Controller hooked (Chloe X)")
    end
end)

-- Remote Killer
task.spawn(function()
    local mt = safeGetMetatable()
    if not mt then 
        warn("[Chloe X] Metatable hook disabled")
        return 
    end
    
    local old_namecall = mt.__namecall
    safeSetReadonly(mt, false)
    
    mt.__namecall = safeNewCClosure(function(self, ...)
        local method = safeGetNamecallMethod()
        
        if _G.Instant and not safeCheckCaller() then
            local remoteName = self.Name
            
            if method == "InvokeServer" then
                if remoteName == "RequestFishingMinigameStarted" or 
                   remoteName == "ChargeFishingRod" or 
                   remoteName == "UpdateAutoFishingState" then
                    return nil
                end
            elseif method == "FireServer" and remoteName == "FishingCompleted" then
                return nil
            end
        end
        
        return old_namecall(self, ...)
    end)
    
    safeSetReadonly(mt, true)
    print("✅ Namecall hook installed (Chloe X)")
end)

-- Visual Suppressor
local function SuppressGameVisuals(active)
    pcall(function()
        local TextController = require(ReplicatedStorage.Controllers.TextNotificationController)
        
        if active then
            if not TextController._OldDeliver then 
                TextController._OldDeliver = TextController.DeliverNotification 
            end
            
            TextController.DeliverNotification = function(self, data)
                if data and data.Text then
                    local text = tostring(data.Text)
                    if text:find("Auto Fishing") or text:find("Reach Level") then
                        return
                    end
                end
                return TextController._OldDeliver(self, data)
            end
        elseif TextController._OldDeliver then
            TextController.DeliverNotification = TextController._OldDeliver
            TextController._OldDeliver = nil
        end
    end)

    if active then
        task.spawn(function()
            local CollectionService = game:GetService("CollectionService")
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            
            local InactiveColor = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHex("ff5d60")),
                ColorSequenceKeypoint.new(1, Color3.fromHex("ff2256"))
            })

            while _G.Instant do
                local targets = CollectionService:GetTagged("AutoFishingButton")
                
                if #targets == 0 then
                    local btn = PlayerGui:FindFirstChild("Backpack")
                    if btn then
                        btn = btn:FindFirstChild("AutoFishingButton")
                        if btn then targets = {btn} end
                    end
                end

                for _, btn in ipairs(targets) do
                    local grad = btn:FindFirstChild("UIGradient")
                    if grad then 
                        grad.Color = InactiveColor 
                    end
                end
                
                task.wait(0.1)
            end
        end)
    end
end

-- Hook FishCaught for Chloe X
if not fishConnected then
    local success, FishingController = pcall(function() 
        return require(ReplicatedStorage.Controllers.FishingController) 
    end)
    
    if success and FishingController then
        local OriginalFishCaught = FishingController.FishCaught
        
        function FishingController.FishCaught(...)
            if _G.Instant then
                lastFishTime = tick()
            end
            return OriginalFishCaught(...)
        end
        
        fishConnected = true
    end
end

-- Initial Bug Trigger (Chloe X Method)
task.spawn(function()
    repeat
        task.wait(0.1)
    until _G.Instant
    
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    task.wait(0.1)
    
    if char:FindFirstChild("!!!FISHING_VIEW_MODEL!!!") then
        pcall(function()
            Remotes.EquipToolFromHotbar:FireServer(1)
        end)
    end
    
    task.wait(0.1)
    
    local cosmeticFolder = workspace:FindFirstChild("CosmeticFolder")
    
    if not hasTriggeredBug then
        if cosmeticFolder and not cosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) then
            pcall(function()
                Remotes.ChargeFishingRod:InvokeServer(2)
                Remotes.RequestFishingMinigameStarted:InvokeServer(-1.25, 1)
            end)
        end
    end
    
    if cosmeticFolder and not cosmeticFolder:FindFirstChild(tostring(LocalPlayer.UserId)) then
        pcall(function()
            Remotes.ChargeFishingRod:InvokeServer(2)
            Remotes.RequestFishingMinigameStarted:InvokeServer(-1.25, 1)
        end)
        
        local startTime = tick()
        local initialFishTime = lastFishTime
        
        while _G.Instant and lastFishTime == initialFishTime do
            task.wait(0.1)
        end
        
        if startTime < lastFishTime then
            pcall(function()
                Remotes.ChargeFishingRod:InvokeServer(2)
                Remotes.RequestFishingMinigameStarted:InvokeServer(-1.25, 1)
                Remotes.CancelFishingInputs:InvokeServer()
                Remotes.ChargeFishingRod:InvokeServer(2)
                Remotes.RequestFishingMinigameStarted:InvokeServer(-1.25, 1)
            end)
            hasTriggeredBug = true
        end
    end
end)

-- Completion Spam (Chloe X Method)
task.spawn(function()
    while task.wait(0.1) do
        if _G.Instant then
            repeat
                task.wait(0.2)
                pcall(function()
                    Remotes.FishingCompleted:FireServer()
                end)
            until not _G.Instant
        end
    end
end)

-- Play Effect Detection
local REPlayEffect = GetRemote(RPath, "RE/PlayFishingEffect")
if REPlayEffect and typeof(REPlayEffect) == "Instance" and REPlayEffect:IsA("RemoteEvent") then
    REPlayEffect.OnClientEvent:Connect(function(player, _, effectType)
        if player == LocalPlayer and effectType == 2 then
            hasFishingEffect = true
        end
    end)
end

-- Cancel on Timeout (Chloe X Method)
task.spawn(function()
    while true do
        repeat
            task.wait(CancelWaitTime)
        until _G.Instant
        
        local currentTime = tick()
        
        if not hasFishingEffect and currentTime - lastFishTime > CancelWaitTime - ResetTimer then
            pcall(function()
                Remotes.CancelFishingInputs:InvokeServer()
            end)
            lastCancelTime = currentTime
        end
        
        hasFishingEffect = false
    end
end)

-- ==================== CREATE WINDUI ====================
-- Load saved config first
LoadConfig()

local Window = WindUI:CreateWindow({
    Title = "Raditya Webhook v3.1 (Auto Save)",
    Icon = "rbxassetid://116236936447443",
    Author = "Raditya (Chloe X Blatant)",
    Folder = "RadityaWebhookV31",
    Size = UDim2.fromOffset(640, 480),
    MinSize = Vector2.new(560, 250),
    MaxSize = Vector2.new(950, 760),
    Transparent = true,
    Theme = "Rose",
    Resizable = true,
    SideBarWidth = 190,
})

if isMobileExecutor() then
    print("✅ Mobile Executor detected!")
    WindUI:Notify({
        Title = "Mobile Detected",
        Content = "Delta/Mobile compatibility enabled!",
        Duration = 4,
        Icon = "smartphone"
    })
end

-- ==================== WEBHOOK TAB ====================
local WebhookTab = Window:Tab({
    Title = "Webhook",
    Icon = "send",
})

local webhooksec = WebhookTab:Section({
    Title = "Fish Webhook Configuration",
})

webhooksec:Input({
    Title = "Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Value = WEBHOOK_URL,
    Callback = function(input) 
        WEBHOOK_URL = input 
        SaveConfig()
        print("Fish Webhook URL updated & saved")
    end
})

webhooksec:Toggle({
    Title = "Enable Fish Notifications",
    Description = "Send caught fish to Discord",
    Value = isWebhookEnabled,
    Callback = function(state)
        isWebhookEnabled = state
        SaveConfig()
        local msg = state and "Fish Webhook Enabled!" or "Fish Webhook Disabled!"
        local icon = state and "check" or "x"
        WindUI:Notify({Title = msg, Duration = 3, Icon = icon})
    end
})

webhooksec:Dropdown({
    Title = "Filter by Fish Name",
    Description = "Select specific fish to notify",
    Values = getWebhookItemOptions(),
    Multi = true,
    AllowNone = true,
    Default = SelectedWebhookItemNames,
    Callback = function(names) 
        SelectedWebhookItemNames = names or {} 
        SaveConfig()
        print(string.format("Selected %d fish names & saved", #SelectedWebhookItemNames))
    end
})

webhooksec:Dropdown({
    Title = "Filter by Rarity",
    Description = "Select rarities to notify",
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Multi = true,
    AllowNone = true,
    Default = SelectedRarityCategories,
    Callback = function(categories)
        SelectedRarityCategories = {}
        for _, cat in ipairs(categories or {}) do
            table.insert(SelectedRarityCategories, cat:upper())
        end
        SaveConfig()
        print(string.format("Selected %d rarities & saved", #SelectedRarityCategories))
    end
})

webhooksec:Button({
    Title = "Test Fish Webhook",
    Description = "Send a test message",
    Icon = "send",
    Callback = function()
        if WEBHOOK_URL == "" then
            WindUI:Notify({
                Title = "Error", 
                Content = "Enter webhook URL first!", 
                Duration = 3,
                Icon = "alert-circle"
            })
            return
        end
        
        local testEmbed = {
            title = "🎣 Raditya Fish Webhook Test (v3.1)",
            description = "Test successful! Config auto-saved!",
            color = 0x00FF00,
            fields = {
                {name = "Executor", value = identifyexecutor and identifyexecutor() or "Unknown", inline = true},
                {name = "User", value = LocalPlayer.Name, inline = true},
                {name = "FPS", value = tostring(performanceStats.fps), inline = true}
            },
            footer = {text = "Raditya Webhook v3.1 - Chloe X Blatant"},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }
        
        local success, msg = sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, testEmbed)
        if success then
            WindUI:Notify({Title = "Test Sent!", Content = "Check your Discord!", Duration = 3, Icon = "check"})
        else
            WindUI:Notify({Title = "Test Failed!", Content = msg, Duration = 3, Icon = "x"})
        end
    end
})

-- ==================== DISCONNECT WEBHOOK SECTION ====================
local disconnectSec = WebhookTab:Section({
    Title = "Disconnect Alert Configuration",
})

disconnectSec:Input({
    Title = "Disconnect Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Description = "Separate webhook for disconnect alerts",
    Value = DISCONNECT_WEBHOOK_URL,
    Callback = function(input)
        DISCONNECT_WEBHOOK_URL = input
        SaveConfig()
        print("Disconnect Webhook URL updated & saved")
    end
})

disconnectSec:Input({
    Title = "Discord User ID (Optional)",
    Placeholder = "123456789012345678",
    Description = "Your Discord ID for @ mentions",
    Value = DISCORD_USER_ID,
    Callback = function(input)
        DISCORD_USER_ID = input:gsub("%D", "")
        SaveConfig()
        print("Discord User ID updated & saved:", DISCORD_USER_ID)
    end
})

disconnectSec:Toggle({
    Title = "Enable Disconnect Alerts",
    Description = "Get notified when disconnected",
    Value = isDisconnectWebhookEnabled,
    Callback = function(state)
        isDisconnectWebhookEnabled = state
        SaveConfig()
        
        if state then
            if DISCONNECT_WEBHOOK_URL == "" then
                WindUI:Notify({
                    Title = "Warning",
                    Content = "Set disconnect webhook URL first!",
                    Duration = 3,
                    Icon = "alert-triangle"
                })
                isDisconnectWebhookEnabled = false
                return
            end
            
            StartDisconnectMonitor()
            WindUI:Notify({
                Title = "Disconnect Monitor ON",
                Content = "You'll be notified on disconnect",
                Duration = 3,
                Icon = "shield"
            })
        else
            WindUI:Notify({
                Title = "Disconnect Monitor OFF",
                Duration = 2,
                Icon = "shield-off"
            })
        end
    end
})

disconnectSec:Button({
    Title = "Test Disconnect Webhook",
    Description = "Send test disconnect alert",
    Icon = "alert-circle",
    Callback = function()
        if DISCONNECT_WEBHOOK_URL == "" then
            WindUI:Notify({
                Title = "Error",
                Content = "Set disconnect webhook URL first!",
                Duration = 3,
                Icon = "x"
            })
            return
        end
        
        hasSentDisconnect = false
        SendDisconnectWebhook("Manual Test - Disconnect Detection")
        WindUI:Notify({
            Title = "Test Sent!",
            Content = "Check your Discord!",
            Duration = 3,
            Icon = "check"
        })
    end
})

local StatsSection = WebhookTab:Section({Title = "Statistics"})
local fishLabel = StatsSection:Paragraph({Title = "Fish Caught: 0", Content = ""})
local webhookLabel = StatsSection:Paragraph({Title = "Webhooks Sent: 0", Content = ""})
local failedLabel = StatsSection:Paragraph({Title = "Failed: 0", Content = ""})

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            fishLabel:SetTitle("Fish Caught: " .. FormatNumber(totalFishCaught))
            webhookLabel:SetTitle("Webhooks Sent: " .. FormatNumber(successfulWebhooks))
            failedLabel:SetTitle("Failed: " .. FormatNumber(failedWebhooks))
        end)
    end
end)

-- ==================== FISHING TAB ====================
local FishingTab = Window:Tab({
    Title = "Fishing",
    Icon = "fish",
})

local blatant = FishingTab:Section({
    Title = "Chloe X Blatant Fishing",
    Description = "Advanced instant fishing system"
})

blatant:Input({
    Title = "Cancel Wait Time (seconds)",
    Description = "Delay before auto-cancel",
    Value = tostring(CancelWaitTime),
    Placeholder = "3",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 1 and val <= 10 then 
            CancelWaitTime = val 
            SaveConfig()
            print("Cancel Wait Time set to:", val)
        end
    end
})

blatant:Toggle({
    Title = "Enable Chloe X Blatant Fishing",
    Description = "Instant fishing with advanced hooks",
    Value = false,
    Callback = function(state)
        _G.Instant = state
        
        SuppressGameVisuals(state)
        
        if state then
            -- Auto-equip rod
            task.spawn(function()
                while _G.Instant do
                    if Remotes.EquipToolFromHotbar then
                        pcall(function() 
                            Remotes.EquipToolFromHotbar:FireServer(1) 
                        end)
                    end
                    task.wait(0.5)
                end
            end)
            
            WindUI:Notify({
                Title = "Chloe X Blatant ON", 
                Content = "Advanced fishing activated!",
                Duration = 3, 
                Icon = "zap"
            })
        else
            pcall(function()
                Remotes.CancelFishingInputs:InvokeServer()
            end)
            
            WindUI:Notify({
                Title = "Chloe X Blatant OFF", 
                Duration = 2,
                Icon = "x"
            })
        end
    end
})

blatant:Paragraph({
    Title = "ℹ️ How It Works",
    Content = [[
Chloe X Blatant uses advanced hooks:
✅ Controller method hijacking
✅ Namecall interception  
✅ Visual suppression
✅ Auto bug triggering
✅ Smart timeout canceling

More stable than basic instant fishing!
]]
})

-- ==================== CONFIG TAB ====================
local ConfigTab = Window:Tab({
    Title = "Config",
    Icon = "save",
})

local configSec = ConfigTab:Section({
    Title = "Configuration Management",
})

configSec:Paragraph({
    Title = "🔄 Auto Save System",
    Content = [[
Your settings are automatically saved:
✅ Webhook URLs
✅ Discord User ID  
✅ Filter settings (rarity & names)
✅ Blatant fishing delays
✅ Toggle states

Config loads on script execution!
]]
})

configSec:Button({
    Title = "💾 Save Config Now",
    Description = "Manually save current settings",
    Icon = "save",
    Callback = function()
        if SaveConfig() then
            WindUI:Notify({
                Title = "Config Saved!",
                Content = "All settings saved successfully",
                Duration = 3,
                Icon = "check"
            })
        else
            WindUI:Notify({
                Title = "Save Failed!",
                Content = "Could not save config",
                Duration = 3,
                Icon = "x"
            })
        end
    end
})

configSec:Button({
    Title = "🔄 Reload Config",
    Description = "Load saved settings",
    Icon = "refresh-cw",
    Callback = function()
        if LoadConfig() then
            WindUI:Notify({
                Title = "Config Loaded!",
                Content = "Settings restored from save",
                Duration = 3,
                Icon = "check"
            })
        else
            WindUI:Notify({
                Title = "Load Failed!",
                Content = "No config file found",
                Duration = 3,
                Icon = "x"
            })
        end
    end
})

configSec:Button({
    Title = "🗑️ Delete Config",
    Description = "Reset all settings to default",
    Icon = "trash-2",
    Callback = function()
        if isfile(CONFIG_FILE) then
            delfile(CONFIG_FILE)
            WindUI:Notify({
                Title = "Config Deleted!",
                Content = "All settings reset. Restart script to apply.",
                Duration = 4,
                Icon = "trash-2"
            })
        else
            WindUI:Notify({
                Title = "No Config!",
                Content = "No saved config to delete",
                Duration = 3,
                Icon = "info"
            })
        end
    end
})

local configInfo = ConfigTab:Section({
    Title = "Current Configuration",
})

local configDisplay = configInfo:Paragraph({
    Title = "📋 Loaded Settings",
    Content = "Loading..."
})

task.spawn(function()
    while task.wait(2) do
        pcall(function()
            local info = string.format([[
Fish Webhook: %s
Disconnect Webhook: %s
Discord ID: %s
Fish Webhook: %s
Disconnect Monitor: %s
Selected Rarities: %d
Selected Fish: %d
Blatant Delay: %.1fs
]],
                WEBHOOK_URL ~= "" and "✅ Set" or "❌ Empty",
                DISCONNECT_WEBHOOK_URL ~= "" and "✅ Set" or "❌ Empty",
                DISCORD_USER_ID ~= "" and "✅ Set" or "❌ Empty",
                isWebhookEnabled and "🟢 ON" or "🔴 OFF",
                isDisconnectWebhookEnabled and "🟢 ON" or "🔴 OFF",
                #SelectedRarityCategories,
                #SelectedWebhookItemNames,
                CancelWaitTime
            )
            
            configDisplay:SetContent(info)
        end)
    end
end)

-- ==================== INFO TAB ====================
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "info",
})

local infoSec = InfoTab:Section({
    Title = "Script Information",
})

infoSec:Paragraph({
    Title = "📦 Version & Features",
    Content = [[
Version: v3.1 - Auto Save Config

✨ New in v3.1:
- Auto save/load configuration
- Chloe X blatant fishing
- Config management tab
- Improved stability

Features:
✅ Discord Fish Webhook
✅ Disconnect Alerts
✅ Auto Config Save
✅ Chloe X Blatant
✅ Mobile Support
]]
})

infoSec:Paragraph({
    Title = "🎣 Blatant Fishing Info",
    Content = [[
Now using Chloe X method:
✅ More stable than basic instant
✅ Controller hijacking
✅ Visual suppression
✅ Auto bug triggering
✅ Smart timeout handling

Recommended delay: 2-3 seconds
]]
})

local perfSec = InfoTab:Section({
    Title = "Performance Monitor",
})

local fpsLabel = perfSec:Paragraph({
    Title = "FPS: --",
    Content = "Current frames per second"
})

local pingLabel = perfSec:Paragraph({
    Title = "Ping: --",
    Content = "Network latency"
})

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local fps = performanceStats.fps
            local ping = performanceStats.ping
            
            local fpsStatus = fps >= 60 and "🟢" or (fps >= 30 and "🟡" or "🔴")
            local pingStatus = ping < 100 and "🟢" or (ping < 200 and "🟡" or "🔴")
            
            fpsLabel:SetTitle(string.format("%s FPS: %d", fpsStatus, fps))
            pingLabel:SetTitle(string.format("%s Ping: %d ms", pingStatus, ping))
        end)
    end
end)

-- ==================== AUTO-START DISCONNECT MONITOR ====================
if isDisconnectWebhookEnabled and DISCONNECT_WEBHOOK_URL ~= "" then
    StartDisconnectMonitor()
    print("✅ Auto-started disconnect monitor from saved config")
end

-- ==================== FINAL NOTIFICATIONS ====================
print("=" .. string.rep("=", 50))
print("✅ Raditya Webhook v3.1 Loaded!")
print("💾 Config System: Auto Save/Load")
print("📨 Fish Webhook System Ready")
print("🔔 Disconnect Monitor Ready")
print("🎣 Chloe X Blatant Fishing Ready")
print("=" .. string.rep("=", 50))

WindUI:Notify({
    Title = "Script Loaded!",
    Content = "Raditya v3.1 - Auto Save Config + Chloe X!",
    Duration = 5,
    Icon = "check-circle"
})

-- Show loaded config status
if WEBHOOK_URL ~= "" or DISCONNECT_WEBHOOK_URL ~= "" then
    task.wait(2)
    WindUI:Notify({
        Title = "Config Loaded!",
        Content = "Previous settings restored automatically",
        Duration = 4,
        Icon = "database"
    })
end
