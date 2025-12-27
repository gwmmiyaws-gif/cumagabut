-- ==================== FISH IT WEBHOOK BY RADITYA ====================
-- Using WindUI Library with Auto Fish Name Detection

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
local isRunning = false
local connections = {}
local totalFishCaught = 0
local successfulWebhooks = 0
local fishCache = {} -- Cache untuk data ikan

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
                                 fishData.ImageId
                        
                        -- Extract angka dari rbxassetid://
                        if assetId and type(assetId) == "string" then
                            assetId = assetId:match("%d+")
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

-- ==================== GET ROBLOX IMAGE ====================
local function GetRobloxImage(assetId)
    if not assetId then return nil end
    
    local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false"
    
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "GET"
        })
    end)
    
    if success and response and response.Body then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        
        if decodeSuccess and data and data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end
    
    return nil
end

-- ==================== SEND WEBHOOK ====================
local function sendWebhook(fishId, weight, metadata)
    task.spawn(function()
        if WEBHOOK_URL == "" or not WEBHOOK_URL:match("discord.com/api/webhooks") then
            print("❌ Webhook URL tidak valid!")
            return
        end
        
        local player = Players.LocalPlayer
        
        -- Auto detect nama dan gambar ikan
        local fishName, assetId = GetFishData(fishId)
        local imageUrl = nil
        
        if assetId then
            imageUrl = GetRobloxImage(assetId)
            if imageUrl then
                print("🖼️ Gambar ditemukan:", imageUrl)
            else
                print("⚠️ Gambar tidak ditemukan untuk asset:", assetId)
            end
        end
        
        local color = 3066993
        if weight then
            if weight > 10 then color = 15844367
            elseif weight > 5 then color = 16766720
            elseif weight > 2 then color = 5814783 end
        end
        
        local embed = {
            ["title"] = "🎣 Ikan Tertangkap!",
            ["description"] = "**" .. player.Name .. "** menangkap **" .. fishName .. "**!",
            ["color"] = color,
            ["fields"] = {
                {["name"] = "🐟 Ikan", ["value"] = "```" .. fishName .. "```", ["inline"] = true},
                {["name"] = "🆔 Fish ID", ["value"] = "```" .. fishId .. "```", ["inline"] = true},
                {["name"] = "⚖️ Berat", ["value"] = weight and ("```" .. string.format("%.2f kg", weight) .. "```") or "```N/A```", ["inline"] = true}
            },
            ["footer"] = {["text"] = "Webhook By Raditya"},
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%S")
        }
        
        if imageUrl then
            embed["thumbnail"] = {["url"] = imageUrl}
        end
        
        local data = {
            ["username"] = "Fish It Bot",
            ["avatar_url"] = "https://cdn-icons-png.flaticon.com/512/2721/2721284.png",
            ["embeds"] = {embed}
        }
        
        local success, response = pcall(function()
            return request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(data)
            })
        end)
        
        if success and response and response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300 then
            successfulWebhooks = successfulWebhooks + 1
            print("✅ Webhook terkirim:", fishName)
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
    Title = "Webhook URL",
    Description = "Paste your Discord webhook URL here",
    Placeholder = "discord.com/api/webhooks/...",
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

-- Update stats setiap detik
task.spawn(function()
    while true do
        task.wait(1)
        fishLabel:Set(tostring(totalFishCaught))
        webhookLabel:Set(tostring(successfulWebhooks))
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
    Title = "Made by Raditya",
    Description = "Auto-detects fish names from game"
})

print("✅ WindUI loaded successfully!")
WindUI:Notify({
    Title = "Webhook By Raditya",
    Content = "UI loaded! Configure your webhook to start.",
    Duration = 5
})
