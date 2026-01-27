-- ==================== FISH IT WEBHOOK BY RADITYA ====================
-- Delta Executor (Android) Compatible Version - UPDATED v2.0
-- Enhanced Performance + Stability Improvements

print("=" .. string.rep("=", 50))
print("🎣 Webhook By Raditya Loaded! (v2.0 Updated)")
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
local WEBHOOK_USERNAME = "Raditya Fish Notify v2.0"
local isWebhookEnabled = false
local SelectedRarityCategories = {}
local SelectedWebhookItemNames = {}
local ImageURLCache = {}

-- Blatant Fishing Configuration
local blatantInstantState = false
local blatantLoopThread = nil
local blatantEquipThread = nil
local isFishingInProgress = false
local completeDelay = 0.08
local cancelDelay = 0.04
local loopInterval = 0.25
_G.RockHub_BlatantActive = false

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
            -- Real FPS
            performanceStats.fps = math.floor(workspace:GetRealPhysicsFPS())
            
            -- Real Ping
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
            
            -- Memory usage
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
                    text = string.format("Raditya Webhook v2.0 • Total: %s • %s", 
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

-- ==================== BLATANT FISHING SYSTEM ====================
-- Logic Killer
task.spawn(function()
    local success, FishingController = pcall(function() 
        return require(ReplicatedStorage.Controllers.FishingController) 
    end)
    
    if success and FishingController then
        local Old_Charge = FishingController.RequestChargeFishingRod
        local Old_Cast = FishingController.SendFishingRequestToServer
        
        FishingController.RequestChargeFishingRod = function(...)
            if _G.RockHub_BlatantActive then return end
            return Old_Charge(...)
        end
        
        FishingController.SendFishingRequestToServer = function(...)
            if _G.RockHub_BlatantActive then 
                return false, "Blocked by Raditya v2.0" 
            end
            return Old_Cast(...)
        end
        
        print("✅ Fishing Controller hooked successfully")
    end
end)

-- Remote Killer
task.spawn(function()
    local mt = safeGetMetatable()
    if not mt then 
        warn("[Delta Compat] Metatable hook disabled")
        return 
    end
    
    local old_namecall = mt.__namecall
    safeSetReadonly(mt, false)
    
    mt.__namecall = safeNewCClosure(function(self, ...)
        local method = safeGetNamecallMethod()
        
        if _G.RockHub_BlatantActive and not safeCheckCaller() then
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
    print("✅ Namecall hook installed")
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

            while _G.RockHub_BlatantActive do
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

-- Instant Fishing Core
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
    Title = "Raditya Webhook + Fishing v2.0",
    Icon = "rbxassetid://116236936447443",
    Author = "Raditya (Updated)",
    Folder = "RadityaWebhookV2",
    Size = UDim2.fromOffset(620, 420),
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
    Title = "Webhook Configuration",
})

webhooksec:Input({
    Title = "Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(input) 
        WEBHOOK_URL = input 
        print("Webhook URL updated")
    end
})

webhooksec:Toggle({
    Title = "Enable Fish Notifications",
    Description = "Send caught fish to Discord",
    Value = false,
    Callback = function(state)
        isWebhookEnabled = state
        local msg = state and "Webhook Enabled!" or "Webhook Disabled!"
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
    Title = "Test Webhook",
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
            title = "🎣 Raditya Webhook Test (v2.0)",
            description = "Test successful from updated script!",
            color = 0x00FF00,
            fields = {
                {name = "Executor", value = identifyexecutor and identifyexecutor() or "Unknown", inline = true},
                {name = "User", value = LocalPlayer.Name, inline = true},
                {name = "FPS", value = tostring(performanceStats.fps), inline = true}
            },
            footer = {text = "Raditya Webhook v2.0"},
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
    Placeholder = "0.25",
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
    Placeholder = "0.08",
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
    Placeholder = "0.04",
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
        
        SuppressGameVisuals(state)
        
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
    Title = "Misc",
    Icon = "settings",
})

local miscSec = MiscTab:Section({
    Title = "Utility Features",
})

-- FPS Overlay
local fpsOverlayEnabled = false
local fpsOverlayGui = nil

local function createFPSOverlay()
    if fpsOverlayGui then
        fpsOverlayGui:Destroy()
        fpsOverlayGui = nil
    end
    
    fpsOverlayGui = Instance.new("ScreenGui")
    fpsOverlayGui.Name = "RadityaFPSOverlay"
    fpsOverlayGui.ResetOnSpawn = false
    fpsOverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local frame = Instance.new("Frame")
    frame.Name = "FPSFrame"
    frame.Size = UDim2.new(0, 220, 0, 90)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.Parent = fpsOverlayGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 105, 180)
    stroke.Thickness = 2
    stroke.Transparency = 0.4
    stroke.Parent = frame
    
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSLabel"
    fpsLabel.Size = UDim2.new(1, -10, 0, 28)
    fpsLabel.Position = UDim2.new(0, 5, 0, 5)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: --"
    fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpsLabel.TextSize = 18
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = frame
    
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "PingLabel"
    pingLabel.Size = UDim2.new(1, -10, 0, 28)
    pingLabel.Position = UDim2.new(0, 5, 0, 33)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: --"
    pingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    pingLabel.TextSize = 18
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = frame
    
    local memLabel = Instance.new("TextLabel")
    memLabel.Name = "MemLabel"
    memLabel.Size = UDim2.new(1, -10, 0, 24)
    memLabel.Position = UDim2.new(0, 5, 0, 61)
    memLabel.BackgroundTransparency = 1
    memLabel.Text = "Mem: -- MB"
    memLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    memLabel.TextSize = 14
    memLabel.Font = Enum.Font.Gotham
    memLabel.TextXAlignment = Enum.TextXAlignment.Left
    memLabel.Parent = frame
    
    local success = pcall(function()
        fpsOverlayGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        fpsOverlayGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    task.spawn(function()
        while fpsOverlayEnabled and fpsOverlayGui and fpsOverlayGui.Parent do
            task.wait(0.5)
            
            local fps = performanceStats.fps
            local ping = performanceStats.ping
            local mem = performanceStats.memory
            
            -- FPS coloring
            local fpsColor = Color3.fromRGB(0, 255, 0)
            if fps < 30 then
                fpsColor = Color3.fromRGB(255, 0, 0)
            elseif fps < 50 then
                fpsColor = Color3.fromRGB(255, 255, 0)
            end
            
            -- Ping coloring
            local pingColor = Color3.fromRGB(0, 255, 0)
            if ping > 200 then
                pingColor = Color3.fromRGB(255, 0, 0)
            elseif ping > 100 then
                pingColor = Color3.fromRGB(255, 255, 0)
            end
            
            fpsLabel.Text = string.format("FPS: %d", fps)
            fpsLabel.TextColor3 = fpsColor
            
            pingLabel.Text = string.format("Ping: %d ms", ping)
            pingLabel.TextColor3 = pingColor
            
            memLabel.Text = string.format("Mem: %d MB", mem)
        end
    end)
end

local function removeFPSOverlay()
    if fpsOverlayGui then
        fpsOverlayGui:Destroy()
        fpsOverlayGui = nil
    end
end

miscSec:Toggle({
    Title = "Show FPS & Ping Overlay",
    Description = "Real-time performance stats on screen",
    Value = false,
    Callback = function(state)
        fpsOverlayEnabled = state
        if state then
            createFPSOverlay()
            WindUI:Notify({
                Title = "Overlay Enabled", 
                Content = "Performance stats visible!",
                Duration = 3, 
                Icon = "eye"
            })
        else
            removeFPSOverlay()
            WindUI:Notify({
                Title = "Overlay Disabled", 
                Duration = 2, 
                Icon = "eye-off"
            })
        end
    end
})

-- Anti-AFK
local antiAFKEnabled = false
local antiAFKConnection = nil

miscSec:Toggle({
    Title = "Anti-AFK",
    Description = "Prevent being kicked for inactivity",
    Value = false,
    Callback = function(state)
        antiAFKEnabled = state
        
        if state then
            local VirtualUser = game:GetService("VirtualUser")
            antiAFKConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            WindUI:Notify({
                Title = "Anti-AFK Enabled", 
                Duration = 3, 
                Icon = "shield"
            })
        else
            if antiAFKConnection then
                antiAFKConnection:Disconnect()
                antiAFKConnection = nil
            end
            WindUI:Notify({
                Title = "Anti-AFK Disabled", 
                Duration = 2, 
                Icon = "shield-off"
            })
        end
    end
})

-- Auto Reconnect
local autoReconnectEnabled = false

miscSec:Toggle({
    Title = "Auto Reconnect",
    Description = "Auto rejoin if disconnected",
    Value = false,
    Callback = function(state)
        autoReconnectEnabled = state
        
        if state then
            task.spawn(function()
                local CoreGui = game:GetService("CoreGui")
                
                local function setupReconnect()
                    local success = pcall(function()
                        CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                            if child.Name == 'ErrorPrompt' and child:FindFirstChild("MessageArea") then
                                task.wait(0.5)
                                TeleportService:Teleport(game.PlaceId, LocalPlayer)
                            end
                        end)
                    end)
                    
                    if not success then
                        game:GetService("GuiService").ErrorMessageChanged:Connect(function()
                            task.wait(1)
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        end)
                    end
                end
                
                setupReconnect()
            end)
            
            WindUI:Notify({
                Title = "Auto Reconnect ON", 
                Content = "Will rejoin automatically",
                Duration = 3, 
                Icon = "refresh-cw"
            })
        else
            WindUI:Notify({
                Title = "Auto Reconnect OFF", 
                Content = "Restart script to fully disable",
                Duration = 3, 
                Icon = "x"
            })
        end
    end
})

miscSec:Button({
    Title = "Rejoin Server",
    Description = "Manually rejoin current server",
    Icon = "repeat",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

miscSec:Button({
    Title = "Server Hop",
    Description = "Join a different server",
    Icon = "shuffle",
    Callback = function()
        local success = pcall(function()
            local servers = game.HttpService:JSONDecode(
                game:HttpGet(string.format(
                    "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100", 
                    game.PlaceId
                ))
            )
            
            if servers and servers.data then
                for _, server in pairs(servers.data) do
                    if server.id ~= game.JobId then
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                        break
                    end
                end
            end
        end)
        
        if not success then
            WindUI:Notify({
                Title = "Server Hop Failed", 
                Content = "Trying alternate method...",
                Duration = 3,
                Icon = "alert-circle"
            })
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end
    end
})

-- ==================== INFO TAB ====================
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "info",
})

local perfSec = InfoTab:Section({
    Title = "Performance Information",
})

local fpsInfoLabel = perfSec:Paragraph({
    Title = "FPS: Calculating...",
    Content = "Real-time frames per second"
})

local pingInfoLabel = perfSec:Paragraph({
    Title = "Ping: Calculating...",
    Content = "Network latency (milliseconds)"
})

local memInfoLabel = perfSec:Paragraph({
    Title = "Memory: Calculating...",
    Content = "Instance memory usage"
})

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local fps = performanceStats.fps
            local ping = performanceStats.ping
            local mem = performanceStats.memory
            
            -- FPS status
            local fpsStatus = "🟢"
            if fps < 30 then
                fpsStatus = "🔴"
            elseif fps < 50 then
                fpsStatus = "🟡"
            end
            
            -- Ping status
            local pingStatus = "🟢"
            if ping > 200 then
                pingStatus = "🔴"
            elseif ping > 100 then
                pingStatus = "🟡"
            end
            
            -- Memory status
            local memStatus = "🟢"
            if mem > 1000 then
                memStatus = "🔴"
            elseif mem > 500 then
                memStatus = "🟡"
            end
            
            fpsInfoLabel:SetTitle(string.format("%s FPS: %d", fpsStatus, fps))
            pingInfoLabel:SetTitle(string.format("%s Ping: %d ms", pingStatus, ping))
            memInfoLabel:SetTitle(string.format("%s Memory: %d MB", memStatus, mem))
        end)
    end
end)

perfSec:Paragraph({
    Title = "Performance Guide",
    Content = [[
🟢 Good • 🟡 Medium • 🔴 Poor

FPS: 60+ (Good), 30-59 (Medium), <30 (Poor)
Ping: <100ms (Good), 100-200ms (Medium), >200ms (Poor)
Memory: <500MB (Good), 500-1000MB (Medium), >1000MB (Poor)
]]
})

local infoSec = InfoTab:Section({
    Title = "Script Information",
})

infoSec:Paragraph({
    Title = "Version",
    Content = "v2.0 - Updated Build"
})

infoSec:Paragraph({
    Title = "Author",
    Content = "Raditya (Enhanced by AI)"
})

infoSec:Paragraph({
    Title = "Executor Compatibility",
    Content = string.format([[
Current Executor: %s

✅ Delta (Android)
✅ Mobile Executors
✅ Desktop Executors
✅ Auto-detection enabled
]], identifyexecutor and identifyexecutor() or "Unknown")
})

infoSec:Paragraph({
    Title = "Features",
    Content = [[
- Discord Webhook Notifications
- Blatant Instant Fishing
- FPS & Ping Overlay
- Anti-AFK Protection
- Auto Reconnect
- Server Hopping
- Performance Monitoring
- Mobile Compatibility
]]
})

infoSec:Button({
    Title = "Copy Discord Support",
    Description = "Get help and updates",
    Icon = "message-circle",
    Callback = function()
        setclipboard("https://discord.gg/raditya") -- Replace with actual invite
        WindUI:Notify({
            Title = "Copied!", 
            Content = "Discord invite copied to clipboard",
            Duration = 3,
            Icon = "check"
        })
    end
})

-- ==================== FINAL NOTIFICATIONS ====================
print("=" .. string.rep("=", 50))
print("✅ Raditya Webhook + Fishing v2.0 Loaded!")
print("📊 Performance Monitor Active")
print("🎣 Fishing System Ready")
print("📨 Webhook System Ready")
print("=" .. string.rep("=", 50))

WindUI:Notify({
    Title = "Script Loaded Successfully!",
    Content = "Raditya Webhook v2.0 - All systems operational",
    Duration = 5,
    Icon = "check-circle"
})
