-- ==================== FISH IT WEBHOOK BY RADITYA ====================
-- Using WindUI Library with Auto Fish Name Detection + FIXED IMAGE SYSTEM

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
local fishCache = {} -- Cache untuk data ikan

-- ============================================================
-- 🖼️ SISTEM CACHE GAMBAR (FIXED)
-- ============================================================
local ImageURLCache = {} -- Table untuk menyimpan Link Gambar (ID -> URL)

-- ==================== FORMAT NUMBER ====================
local function FormatNumber(n)
    n = math.floor(n)
    local formatted = tostring(n):reverse():gsub("%d%d%d", "%1."):reverse()
    return formatted:gsub("^%.", "")
end

-- ==================== AUTO DETECT FISH DATA ====================
local function GetFishData(fishId)
    -- Cek cache dulu
    if fishCache[fishId] then
        return fishCache[fishId].name, fishCache[fishId].assetId
    end
    
    local fishName = "Unknown Fish"
    local assetId = nil
    
    -- Ambil dari Fish Collection
    local success, fishCollection = pcall(function()
        return ReplicatedStorage.Modules.ModelDownloader.Collection.Fish
    end)
    
    if success and fishCollection then
        -- Loop semua fish modules
        for _, fishModule in pairs(fishCollection:GetChildren()) do
            if fishModule:IsA("ModuleScript") then
                local modSuccess, fishData = pcall(function()
                    return require(fishModule)
                end)
                
                if modSuccess and fishData then
                    -- Cek ID (bisa Id, ID, atau nama module)
                    local moduleId = fishData.Id or fishData.ID or fishData.id
                    
                    -- Jika nama module adalah angka, itu bisa jadi ID
                    if not moduleId and tonumber(fishModule.Name) then
                        moduleId = tonumber(fishModule.Name)
                    end
                    
                    if moduleId == fishId then
                        -- Ambil nama ikan (bisa Name, DisplayName, FishName, dll)
                        fishName = fishData.Name or 
                                   fishData.DisplayName or 
                                   fishData.FishName or 
                                   fishData.name or 
                                   fishModule.Name or
                                   "Fish #" .. fishId
                        
                        -- Ambil Asset ID untuk gambar
                        assetId = fishData.AssetId or 
                                 fishData.Asset or 
                                 fishData.MeshId or 
                                 fishData.TextureId or
                                 fishData.ImageId or
                                 fishData.Icon
                        
                        -- Extract angka dari rbxassetid://
                        if assetId and type(assetId) == "string" then
                            assetId = tonumber(string.match(tostring(assetId), "%d+"))
                        elseif assetId and type(assetId) == "number" then
                            assetId = assetId
                        end
                        
                        -- Cache hasil
                        fishCache[fishId] = {
                            name = fishName,
                            assetId = assetId
                        }
                        
                        print("✅ Found fish:", fishId, "=", fishName, "| Asset:", assetId or "none")
                        break
                    end
                end
            end
        end
    else
        warn("❌ Tidak bisa akses Fish Collection!")
    end
    
    -- Kalau masih tidak ketemu, coba cara alternatif
    if fishName == "Unknown Fish" then
        print("⚠️ Fish ID", fishId, "tidak ditemukan di Collection, mencoba cara alternatif...")
        
        -- Cara 2: Cek apakah ada folder dengan nama ID
        pcall(function()
            if fishCollection then
                local fishFolder = fishCollection:FindFirstChild(tostring(fishId))
                if fishFolder then
                    fishName = fishFolder.Name
                    print("✅ Found via folder name:", fishName)
                end
            end
        end)
    end
    
    return fishName, assetId
end

-- ==================== GET ROBLOX IMAGE (FIXED WITH CACHE) ====================
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
            
            -- 3. Simpan ke Cache agar request berikutnya instan
            ImageURLCache[assetId] = finalUrl
            print("🖼️ Gambar berhasil diambil dan di-cache:", finalUrl)
            return finalUrl
        end
    end
    
    print("⚠️ Gagal mengambil gambar untuk asset:", assetId)
    return nil
end

-- ==================== SEND WEBHOOK (FIXED) ====================
local function sendWebhook(fishId, weight, metadata)
    task.spawn(function()
        if WEBHOOK_URL == "" or not WEBHOOK_URL:match("discord.com/api/webhooks") then
            print("❌ Webhook URL tidak valid!")
            return
        end
        
        local player = Players.LocalPlayer
        
        -- Auto detect nama dan gambar ikan
        local fishName, assetId = GetFishData(fishId)
        
        -- Gunakan sistem cache untuk gambar
        local imageUrl = assetId and GetRobloxAssetImage(assetId)
        
        -- Fallback image jika tidak ada
        if not imageUrl then
            imageUrl = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png"
            print("⚠️ Menggunakan gambar fallback")
        end
        
        local color = 3066993
        if weight then
            if weight > 10 then color = 15844367
            elseif weight > 5 then color = 16766720
            elseif weight > 2 then color = 5814783 end
        end
        
        local title = string.format("🎣 Raditya Fish Webhook\n\n🐟 New Fish Caught! (%s)", fishName)
        
        local embed = {
            ["title"] = title,
            ["description"] = string.format("Caught by **%s**", player.DisplayName or player.Name),
            ["color"] = color,
            ["fields"] = {
                {["name"] = "🐟 Fish Name", ["value"] = string.format("`%s`", fishName), ["inline"] = true},
                {["name"] = "🆔 Fish ID", ["value"] = string.format("`%s`", fishId), ["inline"] = true},
                {["name"] = "⚖️ Weight", ["value"] = weight and (string.format("`%.2f kg`", weight)) or "`N/A`", ["inline"] = true}
            },
            ["thumbnail"] = {["url"] = imageUrl},
            ["footer"] = {
                ["text"] = string.format("Webhook By Raditya • Total Caught: %d • %s", 
                    totalFishCaught, 
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
            
            local conn = FishEvent.OnClientEvent:Connect(function(fishId, metadata1, metadata2, ...)
                local weight = nil
                
                if typeof(metadata1) == "table" and metadata1.Weight then
                    weight = metadata1.Weight
                end
                
                if typeof(metadata2) == "table" and metadata2.InventoryItem and metadata2.InventoryItem.Metadata then
                    weight = metadata2.InventoryItem.Metadata.Weight or weight
                end
                
                totalFishCaught = totalFishCaught + 1
                
                print("🎣 Fish caught! ID:", fishId, "| Weight:", weight and string.format("%.2f kg", weight) or "Unknown")
                
                sendWebhook(fishId, weight, metadata2)
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
    Description = "✅ Auto fish name detection\n✅ Image caching system\n✅ Weight tracking\n✅ Real-time statistics"
})

InfoSection:Label({
    Title = "Made by Raditya",
    Description = "Auto-detects fish names & images from game"
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
                {name = "Cache System", value = "Active ✅", inline = true}
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
print("✅ Image cache system active!")
WindUI:Notify({
    Title = "Webhook By Raditya",
    Content = "UI loaded! Configure your webhook to start.",
    Duration = 5
})
