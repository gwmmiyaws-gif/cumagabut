-- ==================== FISH IT WEBHOOK BY RADITYA ====================
-- Delta Executor (Android) Compatible Version - v3.0 DISCONNECT DETECTION
-- Enhanced Webhook + Disconnect Monitor

print("=" .. string.rep("=", 50))
print("🎣 Webhook By Raditya Loaded! (v3.0 + Disconnect Detection)")
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
local WEBHOOK_USERNAME = "Raditya Fish Notify v3.0"
local isWebhookEnabled = false
local isDisconnectWebhookEnabled = false
local SelectedRarityCategories = {}
local SelectedWebhookItemNames = {}
local ImageURLCache = {}

-- Blatant Fishing Configuration (FROM REFERENCE SCRIPT)
local blatantInstantState = false
local blatantLoopThread = nil
local blatantEquipThread = nil
local isFishingInProgress = false
local completeDelay = 0.1
local cancelDelay = 0.05
local loopInterval = 0.3
_G.RockHub_BlatantActive = false

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
        color = 0xFF0000, -- Red
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
            text = "Raditya Disconnect Monitor v3.0",
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
    
    -- Monitor OnTeleport (prevents double webhook on teleport)
    LocalPlayer.OnTeleport:Connect(function(teleportState)
        if teleportState == Enum.TeleportState.Started then
            hasSentDisconnect = true
            print("[Teleport Detected] Blocking disconnect webhook")
        end
    end)
    
    -- Monitor Player Removing (kick detection)
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
                    text = string.format("Raditya Webhook v3.0 • Total: %s • %s", 
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

-- ==================== BLATANT FISHING SYSTEM (FROM REFERENCE) ====================
-- Instant fishing with proper sequencing
local function runBlatantInstant()
    if not blatantInstantState or isFishingInProgress then return end
    
    isFishingInProgress = true
    
    task.spawn(function()
        local success = pcall(function()
            local timestamp = os.time() + os.clock()
            
            -- Step 1: Charge
            if Remotes.ChargeFishingRod then
                Remotes.ChargeFishingRod:InvokeServer(timestamp)
            end
            
            task.wait(0.01)
            
            -- Step 2: Start minigame
            if Remotes.RequestFishingMinigameStarted then
                Remotes.RequestFishingMinigameStarted:InvokeServer(-139.6379699707, 0.99647927980797)
            end
            
            task.wait(completeDelay)
            
            -- Step 3: Complete
            if Remotes.FishingCompleted then
                Remotes.FishingCompleted:FireServer()
            end
            
            task.wait(cancelDelay)
            
            -- Step 4: Cancel
            if Remotes.CancelFishingInputs then
                Remotes.CancelFishingInputs:InvokeServer()
            end
        end)
        
        if not success then
            warn("[Fishing Error] Cycle failed")
        end
        
        isFishingInProgress = false
    end)
end

-- ==================== CREATE WINDUI ====================
local Window = WindUI:CreateWindow({
    Title = "Raditya Webhook + Disconnect v3.0",
    Icon = "rbxassetid://116236936447443",
    Author = "Raditya (Disconnect Update)",
    Folder = "RadityaWebhookV3",
    Size = UDim2.fromOffset(620, 450),
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
    Callback = function(input) 
        WEBHOOK_URL = input 
        print("Fish Webhook URL updated")
    end
})

webhooksec:Toggle({
    Title = "Enable Fish Notifications",
    Description = "Send caught fish to Discord",
    Value = false,
    Callback = function(state)
        isWebhookEnabled = state
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
    Callback = function(names) 
        SelectedWebhookItemNames = names or {} 
        print(string.format("Selected %d fish names", #SelectedWebhookItemNames))
    end
})

webhooksec:Dropdown({
    Title = "Filter by Rarity",
    Description = "Select rarities to notify",
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Multi = true,
    AllowNone = true,
    Callback = function(categories)
        SelectedRarityCategories = {}
        for _, cat in ipairs(categories or {}) do
            table.insert(SelectedRarityCategories, cat:upper())
        end
        print(string.format("Selected %d rarities", #SelectedRarityCategories))
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
            title = "🎣 Raditya Fish Webhook Test (v3.0)",
            description = "Test successful from updated script!",
            color = 0x00FF00,
            fields = {
                {name = "Executor", value = identifyexecutor and identifyexecutor() or "Unknown", inline = true},
                {name = "User", value = LocalPlayer.Name, inline = true},
                {name = "FPS", value = tostring(performanceStats.fps), inline = true}
            },
            footer = {text = "Raditya Webhook v3.0"},
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
    Callback = function(input)
        DISCONNECT_WEBHOOK_URL = input
        print("Disconnect Webhook URL updated")
    end
})

disconnectSec:Input({
    Title = "Discord User ID (Optional)",
    Placeholder = "123456789012345678",
    Description = "Your Discord ID for @ mentions",
    Callback = function(input)
        DISCORD_USER_ID = input:gsub("%D", "")
        print("Discord User ID updated:", DISCORD_USER_ID)
    end
})

disconnectSec:Toggle({
    Title = "Enable Disconnect Alerts",
    Description = "Get notified when disconnected",
    Value = false,
    Callback = function(state)
        isDisconnectWebhookEnabled = state
        
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
        
        hasSentDisconnect = false -- Reset flag for testing
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
    Title = "Blatant Instant Fishing",
    Description = "Optimized fishing automation"
})

blatant:Input({
    Title = "Loop Interval (seconds)",
    Description = "Time between fishing cycles",
    Value = tostring(loopInterval),
    Placeholder = "0.3",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 0.1 and val <= 5 then 
            loopInterval = val 
            print("Loop interval:", val)
        end
    end
})

blatant:Input({
    Title = "Complete Delay (seconds)",
    Description = "Delay before completing",
    Value = tostring(completeDelay),
    Placeholder = "0.1",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 0.05 and val <= 1 then 
            completeDelay = val 
            print("Complete delay:", val)
        end
    end
})

blatant:Input({
    Title = "Cancel Delay (seconds)",
    Description = "Delay before canceling",
    Value = tostring(cancelDelay),
    Placeholder = "0.05",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 0.01 and val <= 1 then 
            cancelDelay = val 
            print("Cancel delay:", val)
        end
    end
})

blatant:Toggle({
    Title = "Enable Instant Fishing",
    Description = "Blatant mode - very fast",
    Value = false,
    Callback = function(state)
        blatantInstantState = state
        _G.RockHub_BlatantActive = state
        
        if state then
            -- Enable auto fishing
            if Remotes.UpdateAutoFishingState then
                pcall(function() 
                    Remotes.UpdateAutoFishingState:InvokeServer(true) 
                end)
                task.wait(0.5)
                pcall(function() 
                    Remotes.UpdateAutoFishingState:InvokeServer(true) 
                end)
            end

            -- Start fishing loop
            blatantLoopThread = task.spawn(function()
                while blatantInstantState do
                    runBlatantInstant()
                    task.wait(loopInterval)
                end
            end)

            -- Keep rod equipped
            if blatantEquipThread then task.cancel(blatantEquipThread) end
            blatantEquipThread = task.spawn(function()
                while blatantInstantState do
                    if Remotes.EquipToolFromHotbar then
                        pcall(function() 
                            Remotes.EquipToolFromHotbar:FireServer(1) 
                        end)
                    end
                    task.wait(0.5)
                end
            end)
            
            WindUI:Notify({
                Title = "Blatant Mode ON", 
                Content = "Instant fishing activated!",
                Duration = 3, 
                Icon = "zap"
            })
        else
            -- Disable auto fishing
            if Remotes.UpdateAutoFishingState then
                pcall(function() 
                    Remotes.UpdateAutoFishingState:InvokeServer(false) 
                end)
            end
            
            -- Stop threads
            if blatantLoopThread then 
                task.cancel(blatantLoopThread) 
                blatantLoopThread = nil 
            end
            if blatantEquipThread then 
                task.cancel(blatantEquipThread) 
                blatantEquipThread = nil 
            end
            
            isFishingInProgress = false
            
            WindUI:Notify({
                Title = "Blatant Mode OFF", 
                Duration = 2,
                Icon = "x"
            })
        end
    end
})

blatant:Paragraph({
    Title = "⚠️ Warning",
    Content = "Blatant mode is detectable. Use at your own risk. Lower delays = faster but more obvious."
})

-- ==================== MISC TAB ====================
local MiscTab = Window:Tab({
    Title = "Info",
    Icon = "info",
})

local infoSec = MiscTab:Section({
    Title = "Script Information",
})

infoSec:Paragraph({
    Title = "Version & Features",
    Content = [[
Version: v3.0 - Disconnect Detection Update

Features:
- Discord Fish Webhook
- Disconnect Alerts with @ mention
- Blatant Instant Fishing
- Mobile Compatibility
- Real-time Stats
]]
})

infoSec:Paragraph({
    Title = "Disconnect Monitor",
    Content = [[
The disconnect monitor will automatically:
✅ Detect kicks/disconnects
✅ Send webhook with reason
✅ Tag your Discord (if ID set)
✅ Show last stats (coins, fish)
⚠️ Won't trigger on teleports
]]
})

local perfSec = MiscTab:Section({
    Title = "Performance",
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

-- ==================== FINAL NOTIFICATIONS ====================
print("=" .. string.rep("=", 50))
print("✅ Raditya Webhook + Disconnect v3.0 Loaded!")
print("📨 Fish Webhook System Ready")
print("🔔 Disconnect Monitor Ready")
print("🎣 Blatant Fishing Ready")
print("=" .. string.rep("=", 50))

WindUI:Notify({
    Title = "Script Loaded!",
    Content = "Raditya v3.0 - Disconnect Detection Added!",
    Duration = 5,
    Icon = "check-circle"
})
