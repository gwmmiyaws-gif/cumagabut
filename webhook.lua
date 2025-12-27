-- ==================== FISH IT WEBHOOK BY RADITYA ====================
-- Using RockHub Detection System (ItemUtility Based)

print("=" .. string.rep("=", 50))
print("🎣 Webhook By Raditya Loaded!")
print("=" .. string.rep("=", 50))

-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Variables
local WEBHOOK_URL = ""
local WEBHOOK_USERNAME = "Raditya Fish Notify"
local isRunning = false
local connections = {}
local totalFishCaught = 0
local successfulWebhooks = 0

-- ============================================================
-- 🖼️ SISTEM CACHE GAMBAR (100% SAMA DENGAN ROCKHUB)
-- ============================================================
local ImageURLCache = {}

-- ==================== LOAD MODULES (CRITICAL!) ====================
local ItemUtility = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemUtility", 10))
local TierUtility = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("TierUtility", 10))

-- ==================== FORMAT NUMBER ====================
local function FormatNumber(n)
    n = math.floor(n)
    local formatted = tostring(n):reverse():gsub("%d%d%d", "%1."):reverse()
    return formatted:gsub("^%.", "")
end

-- ==================== GET FISH NAME & RARITY (ROCKHUB METHOD) ====================
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
                if numericID then
                    itemData = ItemUtility:GetItemData(numericID)
                end
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

        if tierObj and tierObj.Name then
            rarity = tierObj.Name
        end
    end

    return name, rarity
end

-- ==================== GET MUTATION STRING ====================
local function GetItemMutationString(item)
    if item.Metadata and item.Metadata.Shiny == true then return "Shiny" end
    return item.Metadata and item.Metadata.VariantId or ""
end

-- ==================== GET ROBLOX IMAGE (ROCKHUB CACHE METHOD) ====================
local function GetRobloxAssetImage(assetId)
    if not assetId or assetId == 0 then return nil end
    
    -- 1. Cek Cache dulu!
    if ImageURLCache[assetId] then
        print("🖼️ Gambar dari cache:", assetId)
        return ImageURLCache[assetId]
    end
    
    -- 2. Jika tidak ada di cache, baru panggil API
    local url = string.format("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png&isCircular=false", assetId)
    local success, response = pcall(game.HttpGet, game, url)
    
    if success then
        local ok, data = pcall(HttpService.JSONDecode, HttpService, response)
        if ok and data and data.data and data.data[1] and data.data[1].imageUrl then
            local finalUrl = data.data[1].imageUrl
            
            -- 3. Simpan ke Cache
            ImageURLCache[assetId] = finalUrl
            print("🖼️ Gambar berhasil diambil dan di-cache:", finalUrl)
            return finalUrl
        end
    end
    
    print("⚠️ Gagal mengambil gambar untuk asset:", assetId)
    return nil
end

-- ==================== GET RARITY COLOR ====================
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

-- ==================== SEND WEBHOOK (ROCKHUB FORMAT) ====================
local function sendWebhook(itemId, metadata)
    task.spawn(function()
        if WEBHOOK_URL == "" or not WEBHOOK_URL:match("discord.com/api/webhooks") then
            print("❌ Webhook URL tidak valid!")
            return
        end
        
        local player = Players.LocalPlayer
        
        -- Buat dummy item object (format sama dengan RockHub)
        local dummyItem = {Id = itemId, Metadata = metadata}
        
        -- Gunakan fungsi deteksi RockHub
        local fishName, fishRarity = GetFishNameAndRarity(dummyItem)
        local fishRarityUpper = fishRarity:upper()
        
        print("✅ Fish detected:", fishName, "| Rarity:", fishRarity)
        
        -- Weight & Mutation
        local fishWeight = metadata and metadata.Weight or 0
        local mutationString = GetItemMutationString(dummyItem)
        local mutationDisplay = mutationString ~= "" and mutationString or "N/A"
        
        -- Ambil Item Data untuk gambar & harga
        local itemData = ItemUtility:GetItemData(itemId)
        local imageUrl = nil
        
        if itemData and itemData.Data then
            local iconRaw = itemData.Data.Icon or itemData.Data.ImageId
            if iconRaw then
                local assetId = tonumber(string.match(tostring(iconRaw), "%d+"))
                if assetId then
                    imageUrl = GetRobloxAssetImage(assetId)
                    print("🔍 Asset ID ditemukan:", assetId)
                end
            end
        end
        
        -- Fallback image
        if not imageUrl then
            imageUrl = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png"
            print("⚠️ Menggunakan gambar fallback")
        end
        
        -- Hitung sell price
        local basePrice = itemData and itemData.SellPrice or 0
        local sellMultiplier = metadata and metadata.SellMultiplier or 1
        local sellPrice = basePrice * sellMultiplier
        local formattedSellPrice = FormatNumber(sellPrice)
        
        -- Get Total Caught
        local leaderstats = player:FindFirstChild("leaderstats")
        local caughtStat = leaderstats and leaderstats:FindFirstChild("Caught")
        local caughtDisplay = caughtStat and FormatNumber(caughtStat.Value) or "N/A"
        
        local color = getRarityColor(fishRarityUpper)
        local title = string.format("🎣 Raditya Fish Webhook\n\n🐟 New Fish Caught! (%s)", fishName)
        
        local embed = {
            ["title"] = title,
            ["description"] = string.format("Caught by **%s**", player.DisplayName or player.Name),
            ["color"] = color,
            ["fields"] = {
                {["name"] = "🐟 Fish Name", ["value"] = string.format("`%s`", fishName), ["inline"] = true},
                {["name"] = "🏆 Rarity", ["value"] = string.format("`%s`", fishRarityUpper), ["inline"] = true},
                {["name"] = "⚖️ Weight", ["value"] = string.format("`%.2f kg`", fishWeight), ["inline"] = true},
                {["name"] = "✨ Mutation", ["value"] = string.format("`%s`", mutationDisplay), ["inline"] = true},
                {["name"] = "💰 Sell Price", ["value"] = string.format("`%s$`", formattedSellPrice), ["inline"] = true},
                {["name"] = "🆔 Fish ID", ["value"] = string.format("`%s`", itemId), ["inline"] = true}
            },
            ["thumbnail"] = {["url"] = imageUrl},
            ["footer"] = {
                ["text"] = string.format("Webhook By Raditya • Total Caught: %s • %s", 
                    caughtDisplay, 
                    os.date("%Y-%m-%d %H:%M:%S"))
            }
        }
        
        local payload = {
            ["username"] = WEBHOOK_USERNAME,
            ["avatar_url"] = "https://cdn-icons-png.flaticon.com/512/2721/2721284.png",
            ["embeds"] = {embed}
        }
        
        local json_data = HttpService:JSONEncode(payload)
        
        local success, response = pcall(function()
            return request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = json_data
            })
        end)
        
        if success and response and response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300 then
            successfulWebhooks = successfulWebhooks + 1
            print("✅ Webhook terkirim:", fishName, "| Image:", imageUrl and "✓" or "✗")
        else
            print("❌ Webhook gagal:", response and response.StatusCode or "No response")
        end
    end)
end

-- ==================== CREATE WINDUI ====================
local Window = WindUI:CreateWindow({
    Title = "Fish It Webhook",
    Icon = "rbxassetid://116236936447443",
    Author = "Raditya",
    Folder = "RadityaWebhook",
    Size = UDim2.fromOffset(600, 360),
    MinSize = Vector2.new(560, 250),
    MaxSize = Vector2.new(950, 760),
    Transparent = true,
    Theme = "Rose",
    Resizable = true,
    SideBarWidth = 190,
    BackgroundImageTransparency = 0.42,
    HideSearchBar = true,
    ScrollBarEnabled = true,
})

local MainTab = Window:Tab({
    Title = "Webhook Settings",
    Icon = "webhook"
})

local ConfigSection = MainTab:Section({
    Title = "Configuration"
})

-- Webhook URL Input
ConfigSection:Input({
    Title = "Discord Webhook URL",
    Description = "Paste your Discord webhook URL here",
    Placeholder = "https://discord.com/api/webhooks/...",
    Callback = function(value)
        WEBHOOK_URL = value
        print("✅ Webhook URL updated")
    end
})

-- Toggle Webhook
ConfigSection:Toggle({
    Title = "Enable Webhook",
    Description = "Turn on/off the webhook notifications",
    Default = false,
    Callback = function(value)
        isRunning = value
        
        if isRunning then
            if WEBHOOK_URL == "" or not WEBHOOK_URL:match("discord.com/api/webhooks") then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Please enter a valid webhook URL first!",
                    Duration = 5
                })
                return
            end
            
            -- Hook ke event ikan
            local eventSuccess, FishEvent = pcall(function()
                return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
            end)
            
            if not eventSuccess then
                WindUI:Notify({
                    Title = "Error",
                    Content = "Could not find fish event! Game might have updated.",
                    Duration = 5
                })
                return
            end
            
            local conn = FishEvent.OnClientEvent:Connect(function(itemId, metadata1, metadata2, ...)
                -- Parse metadata (ambil yang paling lengkap)
                local finalMetadata = nil
                
                if typeof(metadata2) == "table" and metadata2.InventoryItem and metadata2.InventoryItem.Metadata then
                    finalMetadata = metadata2.InventoryItem.Metadata
                elseif typeof(metadata1) == "table" then
                    finalMetadata = metadata1
                end
                
                totalFishCaught = totalFishCaught + 1
                
                print("🎣 Fish caught! ID:", itemId)
                
                sendWebhook(itemId, finalMetadata)
            end)
            
            table.insert(connections, conn)
            
            WindUI:Notify({
                Title = "Success",
                Content = "Webhook enabled! Catch a fish to test.",
                Duration = 5
            })
        else
            -- Disconnect semua connections
            for _, conn in pairs(connections) do
                conn:Disconnect()
            end
            connections = {}
            
            WindUI:Notify({
                Title = "Disabled",
                Content = "Webhook has been disabled.",
                Duration = 3
            })
        end
    end
})

-- Stats Section
local StatsSection = MainTab:Section({
    Title = "Statistics"
})

local fishLabel = StatsSection:Label({
    Title = "Fish Caught",
    Description = "0"
})

local webhookLabel = StatsSection:Label({
    Title = "Webhooks Sent",
    Description = "0"
})

local cacheLabel = StatsSection:Label({
    Title = "Images Cached",
    Description = "0"
})

-- Update stats setiap detik
task.spawn(function()
    while true do
        task.wait(1)
        fishLabel:Set(tostring(totalFishCaught))
        webhookLabel:Set(tostring(successfulWebhooks))
        
        -- Hitung cache
        local cacheCount = 0
        for _ in pairs(ImageURLCache) do
            cacheCount = cacheCount + 1
        end
        cacheLabel:Set(tostring(cacheCount))
    end
end)

-- Info Section
local InfoSection = MainTab:Section({
    Title = "Information"
})

InfoSection:Label({
    Title = "How to use:",
    Description = "1. Paste your Discord webhook URL\n2. Toggle the webhook on\n3. Catch fish and check Discord!"
})

InfoSection:Label({
    Title = "Features:",
    Description = "✅ RockHub detection system\n✅ ItemUtility based names\n✅ Image caching system\n✅ Real-time statistics"
})

InfoSection:Label({
    Title = "Made by Raditya",
    Description = "Using RockHub detection method"
})

-- Test Button
ConfigSection:Button({
    Title = "Test Webhook",
    Description = "Send a test message to Discord",
    Callback = function()
        if WEBHOOK_URL == "" then
            WindUI:Notify({
                Title = "Error",
                Content = "Please enter webhook URL first!",
                Duration = 3
            })
            return
        end
        
        local testEmbed = {
            title = "🎣 Raditya Fish Webhook Test",
            description = "Webhook test successful! ✅",
            color = 0x00FF00,
            fields = {
                {name = "Player", value = Players.LocalPlayer.DisplayName or Players.LocalPlayer.Name, inline = true},
                {name = "Status", value = "Connected ✓", inline = true},
                {name = "Detection", value = "RockHub Method ✅", inline = true}
            },
            footer = {text = "Webhook By Raditya"}
        }
        
        local payload = {
            username = WEBHOOK_USERNAME,
            embeds = {testEmbed}
        }
        
        local success, response = pcall(function()
            return request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(payload)
            })
        end)
        
        if success and response.StatusCode >= 200 and response.StatusCode < 300 then
            WindUI:Notify({
                Title = "Test Success!",
                Content = "Check your Discord channel",
                Duration = 4
            })
        else
            WindUI:Notify({
                Title = "Test Failed!",
                Content = "Check console for errors",
                Duration = 5
            })
        end
    end
})

print("✅ WindUI loaded successfully!")
print("✅ RockHub detection system active!")
WindUI:Notify({
    Title = "Webhook By Raditya",
    Content = "RockHub detection system loaded!",
    Duration = 5
})
