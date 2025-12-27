-- ==================== FISH IT WEBHOOK BY RADITYA ====================
-- Extracted from RockHub Premium - Webhook + Blatant Fishing System

print("=" .. string.rep("=", 50))
print("🎣 Webhook By Raditya Loaded!")
print("=" .. string.rep("=", 50))

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

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

-- Blatant Fishing
local blatantInstantState = false
local blatantLoopThread = nil
local blatantEquipThread = nil
local completeDelay = 3.055
local cancelDelay = 0.3
local loopInterval = 1.715
_G.RockHub_BlatantActive = false

-- Stats
local totalFishCaught = 0
local successfulWebhooks = 0

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
    
    if typeof(request) == "function" then
        local success, response = pcall(function()
            return request({
                Url = url,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json_data
            })
        end)
        
        if success and (response.StatusCode == 200 or response.StatusCode == 204) then
            return true, "Sent"
        end
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

-- ==================== BLATANT FISHING SYSTEM ====================
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
local mt = getrawmetatable(game)
local old_namecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if _G.RockHub_BlatantActive and not checkcaller() then
        if method == "InvokeServer" and (self.Name == "RequestFishingMinigameStarted" or self.Name == "ChargeFishingRod" or self.Name == "UpdateAutoFishingState") then
            return nil
        end
        if method == "FireServer" and self.Name == "FishingCompleted" then
            return nil
        end
    end
    return old_namecall(self, ...)
end)
setreadonly(mt, true)

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
            local RunService = game:GetService("RunService")
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

local function runBlatantInstant()
    if not blatantInstantState then return end

    task.spawn(function()
        local startTime = os.clock()
        local timestamp = os.time() + os.clock()
        
        pcall(function() RF_ChargeFishingRod:InvokeServer(timestamp) end)
        task.wait(0.001)
        pcall(function() RF_RequestFishingMinigameStarted:InvokeServer(-139.6379699707, 0.99647927980797) end)
        
        local completeWaitTime = completeDelay - (os.clock() - startTime)
        if completeWaitTime > 0 then task.wait(completeWaitTime) end
        
        pcall(function() RE_FishingCompleted:FireServer() end)
        task.wait(cancelDelay)
        pcall(function() RF_CancelFishingInputs:InvokeServer() end)
    end)
end

-- ==================== CREATE WINDUI ====================
local Window = WindUI:CreateWindow({
    Title = "Fish It Webhook + Fishing",
    Icon = "rbxassetid://116236936447443",
    Author = "Raditya",
    Folder = "RadityaWebhook",
    Size = UDim2.fromOffset(600, 400),
    Transparent = true,
    Theme = "Rose",
    Resizable = true,
})

-- ==================== WEBHOOK TAB ====================
local WebhookTab = Window:Tab({
    Title = "Webhook",
    Icon = "send"
})

local webhooksec = WebhookTab:Section({
    Title = "Webhook Setup",
    TextSize = 20,
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
            title = "🎣 Raditya Webhook Test",
            description = "Success!",
            color = 0x00FF00,
            footer = {text = "Webhook By Raditya"}
        }
        sendExploitWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, testEmbed)
        WindUI:Notify({Title = "Test Sent!", Duration = 3})
    end
})

-- Stats
local StatsSection = WebhookTab:Section({Title = "Statistics"})
local fishLabel = StatsSection:Label({Title = "Fish Caught", Description = "0"})
local webhookLabel = StatsSection:Label({Title = "Webhooks Sent", Description = "0"})

task.spawn(function()
    while true do
        task.wait(1)
        fishLabel:Set(tostring(totalFishCaught))
        webhookLabel:Set(tostring(successfulWebhooks))
    end
end)

-- ==================== FISHING TAB ====================
local FishingTab = Window:Tab({
    Title = "Fishing",
    Icon = "fish"
})

local blatant = FishingTab:Section({Title = "Blatant Instant Fishing"})

blatant:Input({
    Title = "Loop Interval",
    Value = tostring(loopInterval),
    Placeholder = "1.715",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 0.5 then loopInterval = val end
    end
})

blatant:Input({
    Title = "Complete Delay",
    Value = tostring(completeDelay),
    Placeholder = "3.055",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 0.5 then completeDelay = val end
    end
})

blatant:Input({
    Title = "Cancel Delay",
    Value = tostring(cancelDelay),
    Placeholder = "0.3",
    Callback = function(input)
        local val = tonumber(input)
        if val and val >= 0.1 then cancelDelay = val end
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
                    task.wait(0.1)
                end
            end)
            
            WindUI:Notify({Title = "Blatant Mode ON", Duration = 3, Icon = "zap"})
        else
            if RF_UpdateAutoFishingState then
                pcall(function() RF_UpdateAutoFishingState:InvokeServer(false) end)
            end
            if blatantLoopThread then task.cancel(blatantLoopThread) blatantLoopThread = nil end
            if blatantEquipThread then task.cancel(blatantEquipThread) blatantEquipThread = nil end
            WindUI:Notify({Title = "Stopped", Duration = 2})
        end
    end
})

print("✅ Raditya Webhook + Fishing System Loaded!")
WindUI:Notify({
    Title = "Raditya Script Loaded",
    Content = "Webhook & Blatant Fishing Ready!",
    Duration = 5
})
