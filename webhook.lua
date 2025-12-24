-- Raditya Webhook System with UI
-- Load Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

-- Variables
local WEBHOOK_URL = ""
local WEBHOOK_USERNAME = "Raditya Notify"
local isWebhookEnabled = false
local SelectedRarityCategories = {}
local SelectedItemNames = {}
local NotifyOnMutation = false

-- Global Webhook
local GLOBAL_WEBHOOK_URL = "https://discord.com/api/webhooks/1446677688453566655/Xo6u363NGUlSmxhtfAyjXqw8U9fRkfZ8kdSuDxUf82sDBywgcJkEj3XYngSaKFFWu8Hp"
local GLOBAL_WEBHOOK_USERNAME = "Raditya | Community"
local GLOBAL_RARITY_FILTER = {"SECRET", "TROPHY", "COLLECTIBLE", "DEV"}

local RarityList = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Trophy", "Collectible", "DEV"}

-- Image Cache System
local ImageURLCache = {}

-- Helper Functions
local function FormatNumber(n)
    n = math.floor(n)
    local formatted = tostring(n):reverse():gsub("%d%d%d", "%1."):reverse()
    return formatted:gsub("^%.", "")
end

local function GetRobloxAssetImage(assetId)
    if not assetId or assetId == 0 then return nil end
    
    if ImageURLCache[assetId] then
        return ImageURLCache[assetId]
    end
    
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
    if r == "SECRET" then return 0xFFD700 end
    if r == "MYTHIC" then return 0x9400D3 end
    if r == "LEGENDARY" then return 0xFF4500 end
    if r == "EPIC" then return 0x8A2BE2 end
    if r == "RARE" then return 0x0000FF end
    if r == "UNCOMMON" then return 0x00FF00 end
    return 0x00BFFF
end

local function sendWebhook(url, username, embed_data)
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
                Headers = { ["Content-Type"] = "application/json" },
                Body = json_data
            })
        end)
        
        if success and (response.StatusCode == 200 or response.StatusCode == 204) then
            return true, "Sent"
        elseif success and response.StatusCode then
            return false, "Failed: " .. response.StatusCode
        end
    end
    return false, "No Request Function"
end

local function getItemList()
    local items = {}
    local itemsContainer = ReplicatedStorage:FindFirstChild("Items")
    if itemsContainer then
        for _, item in ipairs(itemsContainer:GetChildren()) do
            local itemName = item.Name
            if type(itemName) == "string" and #itemName >= 3 and itemName:sub(1, 3) ~= "!!!" then
                table.insert(items, itemName)
            end
        end
    end
    table.sort(items)
    return items
end

local function shouldNotify(rarity, metadata, itemName)
    if #SelectedRarityCategories > 0 and table.find(SelectedRarityCategories, rarity:upper()) then
        return true
    end
    
    if #SelectedItemNames > 0 and table.find(SelectedItemNames, itemName) then
        return true
    end
    
    if NotifyOnMutation and (metadata.Shiny or metadata.VariantId) then
        return true
    end
    
    return false
end

local function CensorName(name)
    if #name <= 2 then return string.rep("*", #name) end
    return name:sub(1, 1) .. string.rep("*", #name - 2) .. name:sub(-1)
end

-- Main Webhook Function
local function onItemObtained(itemName, rarity, metadata)
    local success = pcall(function()
        local rarityUpper = rarity:upper()
        local weight = string.format("%.2fkg", metadata.Weight or 0)
        local mutation = (metadata.Shiny and "Shiny") or (metadata.VariantId and "Variant") or "N/A"
        local sellPrice = FormatNumber(metadata.SellPrice or 0)
        
        -- Get Image
        local imageUrl = "https://tr.rbxcdn.com/53eb9b170bea9855c45c9356fb33c070/420/420/Image/Png"
        if metadata.ImageId then
            local assetId = tonumber(string.match(tostring(metadata.ImageId), "%d+"))
            imageUrl = GetRobloxAssetImage(assetId) or imageUrl
        end
        
        -- User Webhook
        if isWebhookEnabled and WEBHOOK_URL ~= "" and shouldNotify(rarity, metadata, itemName) then
            local embed = {
                title = "🎣 Raditya | New Catch!",
                description = string.format("**%s** caught a **%s**!", LocalPlayer.DisplayName or LocalPlayer.Name, itemName),
                color = getRarityColor(rarityUpper),
                fields = {
                    { name = "Item Name", value = itemName, inline = true },
                    { name = "Rarity", value = rarityUpper, inline = true },
                    { name = "Weight", value = weight, inline = true },
                    { name = "Mutation", value = mutation, inline = true },
                    { name = "Sell Price", value = sellPrice .. "$", inline = true },
                },
                thumbnail = { url = imageUrl },
                footer = {
                    text = string.format("Raditya Webhook • %s", os.date("%Y-%m-%d %H:%M:%S"))
                }
            }
            
            local success_send, msg = sendWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, embed)
            if success_send then
                Rayfield:Notify({
                    Title = "Webhook Sent!",
                    Content = "Notification sent for " .. itemName,
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
        
        -- Global Webhook
        if table.find(GLOBAL_RARITY_FILTER, rarityUpper) and GLOBAL_WEBHOOK_URL ~= "" then
            local censoredName = CensorName(LocalPlayer.DisplayName or LocalPlayer.Name)
            local globalEmbed = {
                title = "🌍 Raditya | Global Tracker",
                description = string.format("Player **%s** caught a **%s** rarity item!", censoredName, rarityUpper),
                color = getRarityColor(rarityUpper),
                fields = {
                    { name = "Rarity", value = rarityUpper, inline = true },
                    { name = "Weight", value = weight, inline = true },
                    { name = "Mutation", value = mutation, inline = true },
                },
                thumbnail = { url = imageUrl },
                footer = {
                    text = string.format("Raditya Community • Player: %s • %s", censoredName, os.date("%Y-%m-%d %H:%M:%S"))
                }
            }
            sendWebhook(GLOBAL_WEBHOOK_URL, GLOBAL_WEBHOOK_USERNAME, globalEmbed)
        end
    end)
    
    if not success then
        warn("[Raditya Webhook] Error processing item data")
    end
end

-- Hook into game events (Generic approach)
local function setupHooks()
    -- Try to find RemoteEvent for fish caught
    local foundRemote = false
    
    for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteEvent") and (
            remote.Name:lower():find("fish") or 
            remote.Name:lower():find("catch") or 
            remote.Name:lower():find("obtain")
        ) then
            remote.OnClientEvent:Connect(function(...)
                local args = {...}
                -- Try to parse arguments
                pcall(function()
                    if type(args[1]) == "string" then
                        onItemObtained(args[1], args[2] or "Common", args[3] or {})
                    end
                end)
            end)
            foundRemote = true
        end
    end
    
    if not foundRemote then
        Rayfield:Notify({
            Title = "Warning",
            Content = "Could not find game events. Manual testing only.",
            Duration = 5,
            Image = 4483362458
        })
    end
end

-- Create UI
local Window = Rayfield:CreateWindow({
    Name = "Raditya Webhook",
    LoadingTitle = "Raditya Webhook System",
    LoadingSubtitle = "by Raditya",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "RadityaWebhook",
        FileName = "Config"
    }
})

local MainTab = Window:CreateTab("🎣 Webhook", 4483362458)
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

-- Webhook URL Input
local Section1 = MainTab:CreateSection("Webhook Configuration")

local WebhookInput = MainTab:CreateInput({
    Name = "Discord Webhook URL",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        WEBHOOK_URL = text
    end
})

-- Enable Toggle
local EnableToggle = MainTab:CreateToggle({
    Name = "Enable Webhook Notifications",
    CurrentValue = false,
    Flag = "WebhookEnabled",
    Callback = function(value)
        isWebhookEnabled = value
        if value then
            if WEBHOOK_URL == "" or not WEBHOOK_URL:find("discord.com") then
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Please enter a valid Discord webhook URL!",
                    Duration = 5,
                    Image = 4483362458
                })
                EnableToggle:Set(false)
            else
                Rayfield:Notify({
                    Title = "Webhook Active",
                    Content = "Notifications are now enabled!",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end
    end
})

-- Test Button
local TestButton = MainTab:CreateButton({
    Name = "Test Webhook",
    Callback = function()
        if WEBHOOK_URL == "" then
            Rayfield:Notify({
                Title = "Error",
                Content = "Enter webhook URL first!",
                Duration = 3,
                Image = 4483362458
            })
            return
        end
        
        local testEmbed = {
            title = "✅ Raditya Webhook Test",
            description = "Webhook is working successfully!",
            color = 0x00FF00,
            fields = {
                { name = "Player", value = LocalPlayer.DisplayName or LocalPlayer.Name, inline = true },
                { name = "Status", value = "Connected", inline = true },
            },
            footer = {
                text = "Raditya Webhook System"
            }
        }
        
        local success, msg = sendWebhook(WEBHOOK_URL, WEBHOOK_USERNAME, testEmbed)
        if success then
            Rayfield:Notify({
                Title = "Test Successful!",
                Content = "Check your Discord channel!",
                Duration = 3,
                Image = 4483362458
            })
        else
            Rayfield:Notify({
                Title = "Test Failed",
                Content = msg or "Unknown error",
                Duration = 5,
                Image = 4483362458
            })
        end
    end
})

-- Filters Section
local Section2 = SettingsTab:CreateSection("Notification Filters")

local RarityDropdown = SettingsTab:CreateDropdown({
    Name = "Filter by Rarity",
    Options = RarityList,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "RarityFilter",
    Callback = function(options)
        SelectedRarityCategories = {}
        for _, opt in ipairs(options) do
            table.insert(SelectedRarityCategories, opt:upper())
        end
    end
})

local ItemDropdown = SettingsTab:CreateDropdown({
    Name = "Filter by Item Name",
    Options = getItemList(),
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "ItemFilter",
    Callback = function(options)
        SelectedItemNames = options
    end
})

local MutationToggle = SettingsTab:CreateToggle({
    Name = "Notify on Mutations (Shiny/Variant)",
    CurrentValue = false,
    Flag = "MutationNotify",
    Callback = function(value)
        NotifyOnMutation = value
    end
})

-- Setup hooks
setupHooks()

Rayfield:Notify({
    Title = "Raditya Webhook",
    Content = "System loaded successfully!",
    Duration = 3,
    Image = 4483362458
})

print("[Raditya Webhook] Loaded successfully!")
