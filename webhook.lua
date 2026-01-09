-- ==================== FISH IT WEBHOOK BY RADITYA ====================
-- Delta Executor (Android) Compatible Version - FIXED
-- Performance Monitor + Fixed Blatant Fishing

print("=" .. string.rep("=", 50))
print("🎣 Webhook By Raditya Loaded! (Delta Fixed)")
print("=" .. string.rep("=", 50))

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

-- ==================== MOBILE COMPATIBILITY LAYER ====================
local function isMobileExecutor()
    return identifyexecutor and (identifyexecutor():lower():find("delta") or identifyexecutor():lower():find("mobile"))
end

local function mobileRequest(options)
    local requestFunc = http_request or request or syn and syn.request
    
    if not requestFunc then
        warn("[Delta Compat] No request function found!")
        return {Success = false, StatusCode = 0}
    end
    
    local success, response = pcall(function()
        return requestFunc(options)
    end)
    
    if success then
        return {Success = true, StatusCode = response.StatusCode or response.Code or 200}
    else
        return {Success = false, StatusCode = 0, Error = tostring(response)}
    end
end

local function safeGetMetatable()
    local success, mt = pcall(function()
        return getrawmetatable(game)
    end)
    return success and mt or nil
end

local function safeSetReadonly(tbl, state)
    local funcs = {setreadonly, make_writeable, makewriteable}
    for _, func in ipairs(funcs) do
        if func then
            pcall(function() func(tbl, state) end)
            return true
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

-- ==================== LOAD CRITICAL MODULES ====================
local ItemUtility = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 10))
local TierUtility = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 10))

-- ==================== REMOTES ====================
local RPath = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}
local function GetRemote(remotePath, name, timeout)
    local currentInstance = ReplicatedStorage
    for _, childName in ipairs(remotePath) do
        currentInstance = currentInstance:WaitForChild(childName, timeout or 0.5)
        if not currentInstance then return nil end
    end
    return currentInstance:FindFirstChild(name)
end

local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar")
local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod")
local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted")
local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted")
local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs")
local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState")
local REObtainedNewFishNotification = GetRemote(RPath, "RE/ObtainedNewFishNotification")

-- ==================== VARIABLES ====================
-- Webhook
local WEBHOOK_URL = ""
local WEBHOOK_USERNAME = "Raditya Fish Notify"
local isWebhookEnabled = false
local SelectedRarityCategories = {}
local SelectedWebhookItemNames = {}
local ImageURLCache = {}

-- Blatant Fishing - FIXED TIMING
local blatantInstantState = false
local blatantLoopThread = nil
local blatantEquipThread = nil
local isFishingInProgress = false
local completeDelay = 0.1  -- FIXED: Reduced delay
local cancelDelay = 0.05   -- FIXED: Faster cancel
local loopInterval = 0.3   -- FIXED: Faster loop
_G.RockHub_BlatantActive = false

-- Stats
local totalFishCaught = 0
local successfulWebhooks = 0

-- Performance Stats - REAL TIME
local performanceStats = {
    fps = 0,
    ping = 0,
    lastUpdate = 0
}

-- ==================== PERFORMANCE MONITOR (REAL) ====================
task.spawn(function()
    while true do
        local now = os.clock()
        if now - performanceStats.lastUpdate >= 0.5 then
            -- REAL FPS from workspace physics
            performanceStats.fps = math.floor(workspace:GetRealPhysicsFPS())
            
            -- REAL PING from network stats
            local networkStats = Stats.Network.ServerStatsItem
            local pingValue = networkStats["Data Ping"]
            if pingValue then
                performanceStats.ping = math.floor(pingValue:GetValue())
            end
            
            performanceStats.lastUpdate = now
        end
        task.wait(0.1)
    end
end)

-- ==================== HELPER FUNCTIONS ====================
local function FormatNumber(n)
    n = math.floor(n)
    local formatted = tostring(n):reverse():gsub("%d%d%d", "%1."):reverse()
    return formatted:gsub("^%.", "")
end

local function GetPlayerDataReplion()
    local ReplionModule = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replion", 5)
    if not ReplionModule then return nil end
    return require(ReplionModule).Client:WaitReplion("Data", 5)
end

local function GetFishNameAndRarity(item)
    local name = item.Identifier or "Unknown"
    local rarity = item.Metadata and item.Metadata.Rarity or "COMMON"
    local itemID = item.Id

    local itemData = nil
    if ItemUtility and itemID then
        pcall(function()
            itemData = ItemUtility:GetItemData(itemID)
            if not itemData then
                local numericID = tonumber(item.Id) or tonumber(item.Identifier)
                if numericID then itemData = ItemUtility:GetItemData(numericID) end
            end
        end)
    end

    if itemData and itemData.Data and itemData.Data.Name then
        name = itemData.Data.Name
    end

    if item.Metadata and item.Metadata.Rarity then
        rarity = item.Metadata.Rarity
    elseif itemData and itemData.Probability and itemData.Probability.Chance and TierUtility then
        local tierObj = nil
        pcall(function()
            tierObj = TierUtility:GetTierFromRarity(itemData.Probability.Chance)
        end)
        if tierObj and tierObj.Name then rarity = tierObj.Name end
    end

    return name, rarity
end

local function GetItemMutationString(item)
    if item.Metadata and item.Metadata.Shiny == true then return "Shiny" end
    return item.Metadata and item.Metadata.VariantId or ""
end

local function GetRobloxAssetImage(assetId)
    if not assetId or assetId == 0 then return nil end
    if ImageURLCache[assetId] then return ImageURLCache[assetId] end
    
    local url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false", assetId)
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
    local r = rarity:upper()
    if r == "SECRET" or r == "DEV" then return 0xFFD700 end
    if r == "MYTHIC" then return 0x9400D3 end
    if r == "LEGENDARY" then return 0xFF4500 end
    if r == "EPIC" then return 0x8A2BE2 end
    if r == "RARE" then return 0x0000FF end
    if r == "UNCOMMON" then return 0x00FF00 end
    return 0x00BFFF
end

local function getWebhookItemOptions()
    local itemNames = {}
    local itemsContainer = ReplicatedStorage:FindFirstChild("Items")
    if itemsContainer then
        for _, itemObject in ipairs(itemsContainer:GetChildren()) do
            local itemName = itemObject.Name
            if type(itemName) == "string" and #itemName >= 3 and itemName:sub(1, 3) ~= "!!!" then
                table.insert(itemNames, itemName)
            end
        end
    end
    table.sort(itemNames)
    return itemNames
end

-- ==================== WEBHOOK SYSTEM ====================
local function sendExploitWebhook(url, username, embed_data)
    local payload = {
        username = username,
        embeds = {embed_data}
    }
    
    local json_data = HttpService:JSONEncode(payload)
    local response = mobileRequest({
        Url = url,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = json_data
    })
    
    if response.Success and (response.StatusCode == 200 or response.StatusCode == 204) then
        return true, "Sent"
    end
    return false, "Failed"
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
        local itemData = ItemUtility:GetItemData(itemId)
        
        local assetId = nil
        if itemData and itemData.Data then
            local iconRaw = itemData.Data.Icon or itemData.Data.ImageId
            if iconRaw then
                assetId = tonumber(string.match(tostring(iconRaw), "%d+"))
            end
        end

        local imageUrl = assetId and GetRobloxAssetImage(assetId)
        if not imageUrl then
            imageUrl = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png"
        end
        
        local basePrice = itemData and itemData.SellPrice or 0
        local sellPrice = basePrice * (metadata.SellMultiplier or 1)
        local formattedSellPrice = string.format("%s$", FormatNumber(sellPrice))
        
        local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
        local caughtStat = leaderstats and leaderstats:FindFirstChild("Caught")
        local caughtDisplay = caughtStat and FormatNumber(caughtStat.Value) or "N/A"

        local currentCoins = 0
        local replion = GetPlayerDataReplion()
        if replion then
            local success_curr, CurrencyConfig = pcall(function()
                return require(ReplicatedStorage.Modules.CurrencyUtility.Currency)
            end)
            if success_curr and CurrencyConfig and CurrencyConfig["Coins"] then
                currentCoins = replion:Get(CurrencyConfig["Coins"].Path) or 0
            else
                currentCoins = replion:Get("Coins") or replion:Get({"Coins"}) or 0
            end
        end
        local formattedCoins = FormatNumber(currentCoins)

        local isUserFilterMatch = shouldNotify(fishRarityUpper, metadata, fishName)

        if isWebhookEnabled and WEBHOOK_URL ~= "" and isUserFilterMatch then
            local title_private = string.format("🎣 Raditya Fish Webhook\n\n🐟 New Fish Caught! (%s)", fishName)
            
            local embed = {
                title = title_private,
                description = string.format("Found by **%s**.", LocalPlayer.DisplayName or LocalPlayer.Name),
                color = getRarityColor(fishRarityUpper),
                fields = {
                    {name = "🐟 Fish Name", value = string.format("`%s`", fishName), inline = true},
                    {name = "🏆 Rarity", value = string.format("`%s`", fishRarityUpper), inline = true},
                    {name = "⚖️ Weight", value = string.format("`%s`", fishWeight), inline = true},
                    {name = "✨ Mutation", value = string.format("`%s`", mutationDisplay), inline = true},
                    {name = "💰 Sell Price", value = string.format("`%s`", formattedSellPrice), inline = true},
                    {name = "💵 Current Coins", value = string.format("`%s`", formattedCoins), inline = true},
                },
                thumbnail = {url = imageUrl},
                footer = {
                    text = string.format("Webhook By Raditya • Total Caught: %s • %s", caughtDisplay, os.date("%Y-%m-%d %H:%M:%S"))
                }
            }
            
            local success_send, message = sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, embed)
            if success_send then
                successfulWebhooks = successfulWebhooks + 1
                print("✅ Webhook sent:", fishName)
            end
        end
        
        return true
    end)
    
    if not success then
        warn("[Raditya Webhook] Error:", results)
    end
end

if REObtainedNewFishNotification then
    REObtainedNewFishNotification.OnClientEvent:Connect(function(itemId, metadata, fullData)
        totalFishCaught = totalFishCaught + 1
        pcall(function() onFishObtained(itemId, metadata, fullData) end)
    end)
end

-- ==================== BLATANT FISHING SYSTEM - FIXED ====================
-- Logic Killer
task.spawn(function()
    local S1, FishingController = pcall(function() 
        return require(ReplicatedStorage.Controllers.FishingController) 
    end)
    if S1 and FishingController then
        local Old_Charge = FishingController.RequestChargeFishingRod
        local Old_Cast = FishingController.SendFishingRequestToServer
        
        FishingController.RequestChargeFishingRod = function(...)
            if _G.RockHub_BlatantActive then return end
            return Old_Charge(...)
        end
        FishingController.SendFishingRequestToServer = function(...)
            if _G.RockHub_BlatantActive then return false, "Blocked by Raditya" end
            return Old_Cast(...)
        end
    end
end)

-- Remote Killer
task.spawn(function()
    local mt = safeGetMetatable()
    if not mt then 
        warn("[Delta Compat] Could not get metatable - namecall hook disabled")
        return 
    end
    
    local old_namecall = mt.__namecall
    safeSetReadonly(mt, false)
    
    mt.__namecall = safeNewCClosure(function(self, ...)
        local method = getnamecallmethod()
        if _G.RockHub_BlatantActive and not safeCheckCaller() then
            if method == "InvokeServer" and (self.Name == "RequestFishingMinigameStarted" or self.Name == "ChargeFishingRod" or self.Name == "UpdateAutoFishingState") then
                return nil
            end
            if method == "FireServer" and self.Name == "FishingCompleted" then
                return nil
            end
        end
        return old_namecall(self, ...)
    end)
    
    safeSetReadonly(mt, true)
end)

-- Visual Suppressor
local function SuppressGameVisuals(active)
    local Succ, TextController = pcall(function() 
        return require(ReplicatedStorage.Controllers.TextNotificationController) 
    end)
    if Succ and TextController then
        if active then
            if not TextController._OldDeliver then 
                TextController._OldDeliver = TextController.DeliverNotification 
            end
            TextController.DeliverNotification = function(self, data)
                if data and data.Text and (string.find(tostring(data.Text), "Auto Fishing") or string.find(tostring(data.Text), "Reach Level")) then
                    return
                end
                return TextController._OldDeliver(self, data)
            end
        elseif TextController._OldDeliver then
            TextController.DeliverNotification = TextController._OldDeliver
            TextController._OldDeliver = nil
        end
    end

    if active then
        task.spawn(function()
            local CollectionService = game:GetService("CollectionService")
            local PlayerGui = LocalPlayer.PlayerGui
            
            local InactiveColor = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHex("ff5d60")),
                ColorSequenceKeypoint.new(1, Color3.fromHex("ff2256"))
            })

            while _G.RockHub_BlatantActive do
                local targets = {}
                for _, btn in ipairs(CollectionService:GetTagged("AutoFishingButton")) do
                    table.insert(targets, btn)
                end
                
                if #targets == 0 then
                    local btn = PlayerGui:FindFirstChild("Backpack") and PlayerGui.Backpack:FindFirstChild("AutoFishingButton")
                    if btn then table.insert(targets, btn) end
                end

                for _, btn in ipairs(targets) do
                    local grad = btn:FindFirstChild("UIGradient")
                    if grad then grad.Color = InactiveColor end
                end
                
                RunService.RenderStepped:Wait()
            end
        end)
    end
end

-- FIXED: Instant fishing with proper sequencing
local function runBlatantInstant()
    if not blatantInstantState or isFishingInProgress then return end
    
    isFishingInProgress = true
    
    task.spawn(function()
        local timestamp = os.time() + os.clock()
        
        -- Step 1: Charge rod
        local chargeSuccess = pcall(function() 
            RF_ChargeFishingRod:InvokeServer(timestamp) 
        end)
        
        if not chargeSuccess then
            isFishingInProgress = false
            return
        end
        
        task.wait(0.01)
        
        -- Step 2: Start minigame
        local minigameSuccess = pcall(function() 
            RF_RequestFishingMinigameStarted:InvokeServer(-139.6379699707, 0.99647927980797) 
        end)
        
        if not minigameSuccess then
            isFishingInProgress = false
            return
        end
        
        task.wait(completeDelay)
        
        -- Step 3: Complete fishing
        pcall(function() 
            RE_FishingCompleted:FireServer() 
        end)
        
        task.wait(cancelDelay)
        
        -- Step 4: Cancel/reset
        pcall(function() 
            RF_CancelFishingInputs:InvokeServer() 
        end)
        
        isFishingInProgress = false
    end)
end

-- ==================== CREATE WINDUI ====================
local Window = WindUI:CreateWindow({
    Title = "Raditya Webhook + Fishing (Fixed)",
    Icon = "rbxassetid://116236936447443",
    Author = "Raditya",
    Folder = "RadityaWebhook",
    Size = UDim2.fromOffset(600, 400),
    MinSize = Vector2.new(560, 250),
    MaxSize = Vector2.new(950, 760),
    Transparent = true,
    Theme = "Rose",
    Resizable = true,
    SideBarWidth = 190,
})

if isMobileExecutor() then
    print("✅ Delta Mobile Executor detected!")
end

-- ==================== WEBHOOK TAB ====================
local WebhookTab = Window:Tab({
    Title = "Webhook",
    Icon = "send",
})

local webhooksec = WebhookTab:Section({
    Title = "Webhook Setup",
})

webhooksec:Input({
    Title = "Discord Webhook URL",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(input) WEBHOOK_URL = input end
})

webhooksec:Toggle({
    Title = "Enable Fish Notifications",
    Value = false,
    Callback = function(state)
        isWebhookEnabled = state
        if state then
            WindUI:Notify({Title = "Webhook ON!", Duration = 3, Icon = "check"})
        else
            WindUI:Notify({Title = "Webhook OFF!", Duration = 3, Icon = "x"})
        end
    end
})

webhooksec:Dropdown({
    Title = "Filter by Name",
    Values = getWebhookItemOptions(),
    Multi = true,
    AllowNone = true,
    Callback = function(names) SelectedWebhookItemNames = names or {} end
})

webhooksec:Dropdown({
    Title = "Filter by Rarity",
    Values = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Multi = true,
    AllowNone = true,
    Callback = function(categories)
        SelectedRarityCategories = {}
        for _, cat in ipairs(categories or {}) do
            table.insert(SelectedRarityCategories, cat:upper())
        end
    end
})

webhooksec:Button({
    Title = "Test Webhook",
    Icon = "send",
    Callback = function()
        if WEBHOOK_URL == "" then
            WindUI:Notify({Title = "Error", Content = "Enter webhook URL first!", Duration = 3})
            return
        end
        local testEmbed = {
            title = "🎣 Raditya Webhook Test (Fixed)",
            description = "Success from Delta Executor!",
            color = 0x00FF00,
            footer = {text = "Webhook By Raditya - Fixed Version"}
        }
        sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, testEmbed)
        WindUI:Notify({Title = "Test Sent!", Duration = 3})
    end
})

local StatsSection = WebhookTab:Section({Title = "Statistics"})
local fishLabel = StatsSection:Paragraph({Title = "Fish Caught: 0", Content = ""})
local webhookLabel = StatsSection:Paragraph({Title = "Webhooks Sent: 0", Content = ""})

task.spawn(function()
    while true do
        task.wait(1)
        pcall(function()
            fishLabel:SetTitle("Fish Caught: " .. tostring(totalFishCaught))
            webhookLabel:SetTitle("Webhooks Sent: " .. tostring(successfulWebhooks))
        end)
    end
end)

-- ==================== FISHING TAB ====================
local FishingTab = Window:Tab({
    Title = "Fishing",
    Icon = "fish",
})

local blatant = FishingTab:Section({
    Title = "Blatant Instant Fishing (FIXED)",
})

blatant:Input({
    Title = "Loop Interval (seconds)",
    Value = tostring(loopInterval),
    Placeholder = "0.3",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 0.1 then loopInterval = val end
    end
})

blatant:Input({
    Title = "Complete Delay (seconds)",
    Value = tostring(completeDelay),
    Placeholder = "0.1",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 0.05 then completeDelay = val end
    end
})

blatant:Input({
    Title = "Cancel Delay (seconds)",
    Value = tostring(cancelDelay),
    Placeholder = "0.05",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 0.01 then cancelDelay = val end
    end
})

blatant:Toggle({
    Title = "Enable Instant Fishing (Blatant)",
    Value = false,
    Callback = function(state)
        blatantInstantState = state
        _G.RockHub_BlatantActive = state
        
        SuppressGameVisuals(state)
        
        if state then
            if RF_UpdateAutoFishingState then
                pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
                task.wait(0.5)
                pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
            end

            blatantLoopThread = task.spawn(function()
                while blatantInstantState do
                    runBlatantInstant()
                    task.wait(loopInterval)
                end
            end)

            if blatantEquipThread then task.cancel(blatantEquipThread) end
            blatantEquipThread = task.spawn(function()
                while blatantInstantState do
                    pcall(function() RE_EquipToolFromHotbar:FireServer(1) end)
                    task.wait(0.5)
                end
            end)
            
            WindUI:Notify({Title = "Blatant Mode ON", Duration = 3, Icon = "zap"})
        else
            if RF_UpdateAutoFishingState then
                pcall(function() RF_UpdateAutoFishingState:InvokeServer(false) end)
            end
            if blatantLoopThread then task.cancel(blatantLoopThread) blatantLoopThread = nil end
            if blatantEquipThread then task.cancel(blatantEquipThread) blatantEquipThread = nil end
            isFishingInProgress = false
            WindUI:Notify({Title = "Stopped", Duration = 2})
        end
    end
})

-- ==================== MISC TAB ====================
local MiscTab = Window:Tab({
    Title = "Misc",
    Icon = "settings",
})

local miscSec = MiscTab:Section({
    Title = "Miscellaneous Features",
})

-- FPS Overlay Variables
local fpsOverlayEnabled = false
local fpsOverlayGui = nil

local function createFPSOverlay()
    -- Remove old overlay if exists
    if fpsOverlayGui then
        fpsOverlayGui:Destroy()
        fpsOverlayGui = nil
    end
    
    -- Create ScreenGui
    fpsOverlayGui = Instance.new("ScreenGui")
    fpsOverlayGui.Name = "RadityaFPSOverlay"
    fpsOverlayGui.ResetOnSpawn = false
    fpsOverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Create Frame background
    local frame = Instance.new("Frame")
    frame.Name = "FPSFrame"
    frame.Size = UDim2.new(0, 200, 0, 80)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel = 0
    frame.Parent = fpsOverlayGui
    
    -- Add UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    -- Add UIStroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 105, 180)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = frame
    
    -- FPS Label
    local fpsLabel = Instance.new("TextLabel")
    fpsLabel.Name = "FPSLabel"
    fpsLabel.Size = UDim2.new(1, -10, 0, 30)
    fpsLabel.Position = UDim2.new(0, 5, 0, 5)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS: --"
    fpsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpsLabel.TextSize = 20
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = frame
    
    -- Ping Label
    local pingLabel = Instance.new("TextLabel")
    pingLabel.Name = "PingLabel"
    pingLabel.Size = UDim2.new(1, -10, 0, 30)
    pingLabel.Position = UDim2.new(0, 5, 0, 40)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "Ping: --"
    pingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    pingLabel.TextSize = 20
    pingLabel.Font = Enum.Font.GothamBold
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = frame
    
    -- Parent to CoreGui or PlayerGui
    local success = pcall(function()
        fpsOverlayGui.Parent = game:GetService("CoreGui")
    end)
    
    if not success then
        fpsOverlayGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Update loop
    task.spawn(function()
        while fpsOverlayEnabled and fpsOverlayGui do
            task.wait(0.5)
            
            if not fpsOverlayGui or not fpsOverlayGui.Parent then break end
            
            local fps = performanceStats.fps
            local ping = performanceStats.ping
            
            -- Update FPS with color
            local fpsColor = Color3.fromRGB(0, 255, 0) -- Green
            if fps < 30 then
                fpsColor = Color3.fromRGB(255, 0, 0) -- Red
            elseif fps < 50 then
                fpsColor = Color3.fromRGB(255, 255, 0) -- Yellow
            end
            
            fpsLabel.Text = string.format("FPS: %d", fps)
            fpsLabel.TextColor3 = fpsColor
            
            -- Update Ping with color
            local pingColor = Color3.fromRGB(0, 255, 0) -- Green
            if ping > 200 then
                pingColor = Color3.fromRGB(255, 0, 0) -- Red
            elseif ping > 100 then
                pingColor = Color3.fromRGB(255, 255, 0) -- Yellow
            end
            
            pingLabel.Text = string.format("Ping: %d ms", ping)
            pingLabel.TextColor3 = pingColor
        end
    end)
end

local function removeFPSOverlay()
    if fpsOverlayGui then
        fpsOverlayGui:Destroy()
        fpsOverlayGui = nil
    end
end

-- FPS Overlay Toggle
miscSec:Toggle({
    Title = "Show FPS & Ping",
    Description = "Display real-time FPS and Ping on screen",
    Value = false,
    Callback = function(state)
        fpsOverlayEnabled = state
        if state then
            createFPSOverlay()
            WindUI:Notify({Title = "FPS Overlay ON", Content = "Real-time stats displayed!", Duration = 3, Icon = "eye"})
        else
            removeFPSOverlay()
            WindUI:Notify({Title = "FPS Overlay OFF", Duration = 2, Icon = "eye-off"})
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
            WindUI:Notify({Title = "Anti-AFK ON", Duration = 3, Icon = "shield"})
        else
            if antiAFKConnection then
                antiAFKConnection:Disconnect()
                antiAFKConnection = nil
            end
            WindUI:Notify({Title = "Anti-AFK OFF", Duration = 2, Icon = "shield-off"})
        end
    end
})

-- Auto Reconnect
miscSec:Toggle({
    Title = "Auto Reconnect",
    Description = "Automatically rejoin if disconnected",
    Value = false,
    Callback = function(state)
        if state then
            task.spawn(function()
                local TeleportService = game:GetService("TeleportService")
                local CoreGui = game:GetService("CoreGui")
                
                -- Monitor for disconnect prompts
                local function checkForDisconnect()
                    local success = pcall(function()
                        CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
                            if child.Name == 'ErrorPrompt' and child:FindFirstChild("MessageArea") then
                                task.wait(0.5)
                                TeleportService:Teleport(game.PlaceId, LocalPlayer)
                            end
                        end)
                    end)
                    
                    if not success then
                        -- Fallback method
                        game:GetService("GuiService").ErrorMessageChanged:Connect(function()
                            task.wait(1)
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        end)
                    end
                end
                
                checkForDisconnect()
            end)
            WindUI:Notify({Title = "Auto Reconnect ON", Duration = 3, Icon = "refresh-cw"})
        else
            WindUI:Notify({Title = "Auto Reconnect OFF", Content = "Restart script to disable", Duration = 3, Icon = "x"})
        end
    end
})

miscSec:Button({
    Title = "Rejoin Server",
    Description = "Manually rejoin current server",
    Icon = "repeat",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end
})

-- ==================== PERFORMANCE TAB (INFO ONLY) ====================
local PerformanceTab = Window:Tab({
    Title = "Info",
    Icon = "info",
})

local perfSec = PerformanceTab:Section({
    Title = "Performance Information",
})

local fpsInfoLabel = perfSec:Paragraph({
    Title = "FPS: Calculating...",
    Content = "Real-time frames per second"
})

local pingInfoLabel = perfSec:Paragraph({
    Title = "Ping: Calculating...",
    Content = "Network latency in milliseconds"
})

-- Real-time update loop for info tab
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            local fps = performanceStats.fps
            local ping = performanceStats.ping
            
            -- Color coding for FPS
            local fpsStatus = "🟢"
            if fps < 30 then
                fpsStatus = "🔴"
            elseif fps < 50 then
                fpsStatus = "🟡"
            end
            
            -- Color coding for Ping
            local pingStatus = "🟢"
            if ping > 200 then
                pingStatus = "🔴"
            elseif ping > 100 then
                pingStatus = "🟡"
            end
            
            fpsInfoLabel:SetTitle(string.format("%s FPS: %d", fpsStatus, fps))
            pingInfoLabel:SetTitle(string.format("%s Ping: %d ms", pingStatus, ping))
        end)
    end
end)

perfSec:Paragraph({
    Title = "Performance Guide",
    Content = "🟢 Good • 🟡 Medium • 🔴 Poor\n\nFPS: 60+ (Good), 30-59 (Medium), <30 (Poor)\nPing: <100ms (Good), 100-200ms (Medium), >200ms (Poor)"
})

perfSec:Paragraph({
    Title = "Delta Compatibility",
    Content = "This script is optimized for Delta Executor on Android devices. All mobile-specific functions are handled automatically."
})

print("✅ Raditya Webhook + Fishing System Loaded! (FIXED)")
WindUI:Notify({
    Title = "Raditya Script Loaded",
    Content = "Fixed Version with Performance Monitor!",
    Duration = 5
})
