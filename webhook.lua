-- ==================== FISH IT WEBHOOK BY RADITYA ====================
-- UI Lengkap: Minimize, URL Input, Toggle, Live Log, Copy, Error Detection
-- Made for Mobile/Android Support

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

print("=" .. string.rep("=", 50))
print("🎣 Webhook By Raditya Loaded!")
print("=" .. string.rep("=", 50))

-- ==================== VARIABLES ====================
local isRunning = false
local isMinimized = false
local connections = {}
local fullLog = ""
local imageCache = {}
local fishDataCache = {}
local totalFishCaught = 0
local successfulWebhooks = 0
local errorCount = 0

local WEBHOOK_URL = ""

-- ==================== FUNGSI GAMBAR ====================
local function GetRobloxImage(assetId)
    if imageCache[assetId] then
        return imageCache[assetId]
    end
    
    -- Gunakan request biasa tanpa game:HttpGet untuk bypass executor protection
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
            local imageUrl = data.data[1].imageUrl
            imageCache[assetId] = imageUrl
            return imageUrl
        end
    end
    
    return nil
end

local function FindFishAssetId(fishId)
    if fishDataCache[fishId] then
        return fishDataCache[fishId].assetId, fishDataCache[fishId].name
    end
    
    local success, fishCollection = pcall(function()
        return ReplicatedStorage.Modules.ModelDownloader.Collection.Fish
    end)
    
    if not success or not fishCollection then
        return nil, "Fish #" .. fishId
    end
    
    for _, fishData in pairs(fishCollection:GetChildren()) do
        if fishData:IsA("ModuleScript") then
            local moduleSuccess, fishModule = pcall(function()
                return require(fishData)
            end)
            
            if moduleSuccess and fishModule then
                if fishModule.Id == fishId or fishModule.ID == fishId or tonumber(fishData.Name) == fishId then
                    local assetId = fishModule.AssetId or fishModule.Asset or fishModule.MeshId
                    local fishName = fishModule.Name or fishModule.DisplayName or fishData.Name
                    
                    if assetId and type(assetId) == "string" then
                        assetId = assetId:match("%d+")
                    end
                    
                    if assetId then
                        fishDataCache[fishId] = {
                            assetId = assetId,
                            name = fishName
                        }
                        return assetId, fishName
                    end
                end
            end
        end
    end
    
    return nil, "Fish #" .. fishId
end

-- ==================== BUAT UI ====================
local function createUI()
    if CoreGui:FindFirstChild("FishItWebhookUI") then
        CoreGui:FindFirstChild("FishItWebhookUI"):Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FishItWebhookUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 420, 0, 700)
    MainFrame.Position = UDim2.new(0.5, -210, 0.5, -350)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 15)
    MainCorner.Parent = MainFrame
    
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 40, 1, 40)
    Shadow.Position = UDim2.new(0, -20, 0, -20)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://5554236805"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.6
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    Shadow.ZIndex = -1
    Shadow.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 60)
    TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 15)
    TitleCorner.Parent = TitleBar
    
    local TitleCover = Instance.new("Frame")
    TitleCover.Size = UDim2.new(1, 0, 0, 30)
    TitleCover.Position = UDim2.new(0, 0, 1, -30)
    TitleCover.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    TitleCover.BorderSizePixel = 0
    TitleCover.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -120, 1, 0)
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🎣 Webhook By Raditya"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Minimize Button
    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 45, 0, 45)
    MinimizeBtn.Position = UDim2.new(1, -110, 0, 7.5)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 220)
    MinimizeBtn.Text = "−"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = 28
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.BorderSizePixel = 0
    MinimizeBtn.Parent = TitleBar
    
    local MinimizeBtnCorner = Instance.new("UICorner")
    MinimizeBtnCorner.CornerRadius = UDim.new(0, 10)
    MinimizeBtnCorner.Parent = MinimizeBtn
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 45, 0, 45)
    CloseBtn.Position = UDim2.new(1, -55, 0, 7.5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 28
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TitleBar
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 10)
    CloseBtnCorner.Parent = CloseBtn
    
    -- Content Frame (yang bisa di-minimize)
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, 0, 1, -60)
    ContentFrame.Position = UDim2.new(0, 0, 0, 60)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame
    
    -- Webhook URL Input
    local UrlFrame = Instance.new("Frame")
    UrlFrame.Size = UDim2.new(1, -30, 0, 90)
    UrlFrame.Position = UDim2.new(0, 15, 0, 15)
    UrlFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    UrlFrame.BorderSizePixel = 0
    UrlFrame.Parent = ContentFrame
    
    local UrlCorner = Instance.new("UICorner")
    UrlCorner.CornerRadius = UDim.new(0, 12)
    UrlCorner.Parent = UrlFrame
    
    local UrlLabel = Instance.new("TextLabel")
    UrlLabel.Size = UDim2.new(1, -20, 0, 25)
    UrlLabel.Position = UDim2.new(0, 10, 0, 8)
    UrlLabel.BackgroundTransparency = 1
    UrlLabel.Text = "🌐 Webhook URL:"
    UrlLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    UrlLabel.TextSize = 14
    UrlLabel.Font = Enum.Font.GothamBold
    UrlLabel.TextXAlignment = Enum.TextXAlignment.Left
    UrlLabel.Parent = UrlFrame
    
    local UrlInput = Instance.new("TextBox")
    UrlInput.Name = "UrlInput"
    UrlInput.Size = UDim2.new(1, -20, 0, 45)
    UrlInput.Position = UDim2.new(0, 10, 0, 35)
    UrlInput.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    UrlInput.BorderSizePixel = 0
    UrlInput.Text = ""
    UrlInput.PlaceholderText = "Paste webhook URL here..."
    UrlInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    UrlInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    UrlInput.TextSize = 11
    UrlInput.Font = Enum.Font.Code
    UrlInput.TextXAlignment = Enum.TextXAlignment.Left
    UrlInput.ClearTextOnFocus = false
    UrlInput.Parent = UrlFrame
    
    local UrlInputCorner = Instance.new("UICorner")
    UrlInputCorner.CornerRadius = UDim.new(0, 8)
    UrlInputCorner.Parent = UrlInput
    
    local UrlInputPadding = Instance.new("UIPadding")
    UrlInputPadding.PaddingLeft = UDim.new(0, 10)
    UrlInputPadding.PaddingRight = UDim.new(0, 10)
    UrlInputPadding.Parent = UrlInput
    
    -- Status Panel
    local StatusPanel = Instance.new("Frame")
    StatusPanel.Size = UDim2.new(1, -30, 0, 120)
    StatusPanel.Position = UDim2.new(0, 15, 0, 120)
    StatusPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    StatusPanel.BorderSizePixel = 0
    StatusPanel.Parent = ContentFrame
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 12)
    StatusCorner.Parent = StatusPanel
    
    local StatusText = Instance.new("TextLabel")
    StatusText.Name = "StatusText"
    StatusText.Size = UDim2.new(1, -20, 0, 25)
    StatusText.Position = UDim2.new(0, 10, 0, 10)
    StatusText.BackgroundTransparency = 1
    StatusText.Text = "Status: ⚪ Idle"
    StatusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    StatusText.TextSize = 15
    StatusText.Font = Enum.Font.GothamBold
    StatusText.TextXAlignment = Enum.TextXAlignment.Left
    StatusText.Parent = StatusPanel
    
    local FishCounter = Instance.new("TextLabel")
    FishCounter.Name = "FishCounter"
    FishCounter.Size = UDim2.new(1, -20, 0, 20)
    FishCounter.Position = UDim2.new(0, 10, 0, 40)
    FishCounter.BackgroundTransparency = 1
    FishCounter.Text = "🐟 Fish Caught: 0"
    FishCounter.TextColor3 = Color3.fromRGB(150, 150, 150)
    FishCounter.TextSize = 13
    FishCounter.Font = Enum.Font.Gotham
    FishCounter.TextXAlignment = Enum.TextXAlignment.Left
    FishCounter.Parent = StatusPanel
    
    local WebhookCounter = Instance.new("TextLabel")
    WebhookCounter.Name = "WebhookCounter"
    WebhookCounter.Size = UDim2.new(1, -20, 0, 20)
    WebhookCounter.Position = UDim2.new(0, 10, 0, 65)
    WebhookCounter.BackgroundTransparency = 1
    WebhookCounter.Text = "✅ Webhooks Sent: 0"
    WebhookCounter.TextColor3 = Color3.fromRGB(150, 150, 150)
    WebhookCounter.TextSize = 13
    WebhookCounter.Font = Enum.Font.Gotham
    WebhookCounter.TextXAlignment = Enum.TextXAlignment.Left
    WebhookCounter.Parent = StatusPanel
    
    local ErrorText = Instance.new("TextLabel")
    ErrorText.Name = "ErrorText"
    ErrorText.Size = UDim2.new(1, -20, 0, 20)
    ErrorText.Position = UDim2.new(0, 10, 0, 90)
    ErrorText.BackgroundTransparency = 1
    ErrorText.Text = "⚠️ Errors: 0"
    ErrorText.TextColor3 = Color3.fromRGB(150, 150, 150)
    ErrorText.TextSize = 13
    ErrorText.Font = Enum.Font.Gotham
    ErrorText.TextXAlignment = Enum.TextXAlignment.Left
    ErrorText.Parent = StatusPanel
    
    -- Toggle Frame (ON/OFF Switch)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, -30, 0, 70)
    ToggleFrame.Position = UDim2.new(0, 15, 0, 255)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = ContentFrame
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 12)
    ToggleCorner.Parent = ToggleFrame
    
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -130, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 15, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = "⚡ Webhook Status"
    ToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ToggleLabel.TextSize = 16
    ToggleLabel.Font = Enum.Font.GothamBold
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = ToggleFrame
    
    -- Toggle Button (ON/OFF)
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 100, 0, 45)
    ToggleButton.Position = UDim2.new(1, -115, 0.5, -22.5)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    ToggleButton.Text = "OFF"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 18
    ToggleButton.Font = Enum.Font.GothamBold
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Parent = ToggleFrame
    
    local ToggleButtonCorner = Instance.new("UICorner")
    ToggleButtonCorner.CornerRadius = UDim.new(0, 10)
    ToggleButtonCorner.Parent = ToggleButton
    
    -- Copy Button
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(1, -30, 0, 50)
    CopyBtn.Position = UDim2.new(0, 15, 0, 340)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 220)
    CopyBtn.Text = "📋 COPY LOG"
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.TextSize = 16
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.BorderSizePixel = 0
    CopyBtn.Parent = ContentFrame
    
    local CopyBtnCorner = Instance.new("UICorner")
    CopyBtnCorner.CornerRadius = UDim.new(0, 10)
    CopyBtnCorner.Parent = CopyBtn
    
    -- Log Frame
    local LogFrame = Instance.new("ScrollingFrame")
    LogFrame.Name = "LogFrame"
    LogFrame.Size = UDim2.new(1, -30, 0, 230)
    LogFrame.Position = UDim2.new(0, 15, 0, 405)
    LogFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    LogFrame.BorderSizePixel = 0
    LogFrame.ScrollBarThickness = 8
    LogFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogFrame.Parent = ContentFrame
    
    local LogCorner = Instance.new("UICorner")
    LogCorner.CornerRadius = UDim.new(0, 12)
    LogCorner.Parent = LogFrame
    
    local LogLayout = Instance.new("UIListLayout")
    LogLayout.SortOrder = Enum.SortOrder.LayoutOrder
    LogLayout.Padding = UDim.new(0, 5)
    LogLayout.Parent = LogFrame
    
    local LogPadding = Instance.new("UIPadding")
    LogPadding.PaddingTop = UDim.new(0, 10)
    LogPadding.PaddingLeft = UDim.new(0, 10)
    LogPadding.PaddingRight = UDim.new(0, 10)
    LogPadding.PaddingBottom = UDim.new(0, 10)
    LogPadding.Parent = LogFrame
    
    -- ==================== FUNGSI LOG ====================
    local function addLog(text, color)
        local timestamp = os.date("[%H:%M:%S] ")
        local logLine = timestamp .. text
        fullLog = fullLog .. logLine .. "\n"
        
        local LogText = Instance.new("TextLabel")
        LogText.Size = UDim2.new(1, -20, 0, 20)
        LogText.BackgroundTransparency = 1
        LogText.Text = logLine
        LogText.TextColor3 = color or Color3.fromRGB(200, 200, 200)
        LogText.TextSize = 11
        LogText.Font = Enum.Font.Code
        LogText.TextXAlignment = Enum.TextXAlignment.Left
        LogText.TextWrapped = true
        LogText.AutomaticSize = Enum.AutomaticSize.Y
        LogText.Parent = LogFrame
        
        task.wait()
        LogFrame.CanvasPosition = Vector2.new(0, LogFrame.AbsoluteCanvasSize.Y)
    end
    
    -- ==================== FUNGSI WEBHOOK ====================
    local function sendWebhook(fishId, weight, metadata)
        task.spawn(function()
            if WEBHOOK_URL == "" then
                addLog("❌ Webhook URL kosong! Isi URL dulu", Color3.fromRGB(255, 100, 100))
                errorCount = errorCount + 1
                ErrorText.Text = "⚠️ Errors: " .. errorCount
                return
            end
            
            local player = Players.LocalPlayer
            local assetId, fishName = FindFishAssetId(fishId)
            local imageUrl = nil
            
            if assetId then
                imageUrl = GetRobloxImage(assetId)
                if imageUrl then
                    addLog("🖼️ Gambar ditemukan: Asset " .. assetId, Color3.fromRGB(150, 255, 150))
                else
                    addLog("⚠️ Gambar tidak ditemukan untuk Asset " .. assetId, Color3.fromRGB(255, 200, 100))
                end
            end
            
            local color = 3066993
            if weight then
                if weight > 10 then color = 15844367
                elseif weight > 5 then color = 16766720
                elseif weight > 2 then color = 5814783 end
            end
            
            local fields = {
                {["name"] = "🐟 Ikan", ["value"] = "```" .. fishName .. "```", ["inline"] = true},
                {["name"] = "🆔 ID", ["value"] = "```" .. fishId .. "```", ["inline"] = true},
                {["name"] = "⚖️ Berat", ["value"] = weight and ("```" .. string.format("%.2f kg", weight) .. "```") or "```N/A```", ["inline"] = true},
                {["name"] = "👤 Player", ["value"] = "```" .. player.Name .. "```", ["inline"] = true},
                {["name"] = "🕐 Waktu", ["value"] = "```" .. os.date("%H:%M:%S") .. "```", ["inline"] = true}
            }
            
            local embed = {
                ["title"] = "🎣 Ikan Tertangkap!",
                ["description"] = "**" .. player.Name .. "** menangkap **" .. fishName .. "**!",
                ["color"] = color,
                ["fields"] = fields,
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
            
            -- Gunakan request untuk bypass executor protection
            local webhookSuccess, response = pcall(function()
                return request({
                    Url = WEBHOOK_URL,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = HttpService:JSONEncode(data)
                })
            end)
            
            if webhookSuccess and response and response.StatusCode and response.StatusCode >= 200 and response.StatusCode < 300 then
                successfulWebhooks = successfulWebhooks + 1
                WebhookCounter.Text = "✅ Webhooks Sent: " .. successfulWebhooks
                addLog("✅ Webhook terkirim: " .. fishName, Color3.fromRGB(100, 255, 100))
            else
                errorCount = errorCount + 1
                ErrorText.Text = "⚠️ Errors: " .. errorCount
                local errorMsg = "Unknown error"
                if response and response.StatusCode then
                    errorMsg = "HTTP " .. response.StatusCode
                elseif response then
                    errorMsg = tostring(response)
                end
                addLog("❌ Webhook gagal: " .. errorMsg, Color3.fromRGB(255, 100, 100))
                
                -- Fallback: copy to clipboard
                if setclipboard then
                    local clipText = string.format("🎣 Fish: %s | ID: %d | Weight: %.2f kg", fishName, fishId, weight or 0)
                    setclipboard(clipText)
                    addLog("📋 Data di-copy ke clipboard", Color3.fromRGB(255, 200, 100))
                end
            end
        end)
    end
    
    -- ==================== TOGGLE FUNCTION ====================
    local function toggleWebhook()
        if not isRunning then
            -- START
            WEBHOOK_URL = UrlInput.Text
            
            if WEBHOOK_URL == "" or not WEBHOOK_URL:match("discord.com/api/webhooks") then
                addLog("❌ Webhook URL tidak valid!", Color3.fromRGB(255, 50, 50))
                return
            end
            
            isRunning = true
            ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
            ToggleButton.Text = "ON"
            StatusText.Text = "Status: 🟢 Running"
            StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
            addLog("✅ Webhook aktif!", Color3.fromRGB(100, 255, 100))
            
            -- Test request function
            local requestTest = pcall(function()
                request({Url = "https://httpbin.org/get", Method = "GET"})
            end)
            
            if not requestTest then
                addLog("⚠️ Request function tidak tersedia!", Color3.fromRGB(255, 150, 50))
                addLog("💡 Coba executor lain (Arceus X, Delta X, Fluxus)", Color3.fromRGB(200, 200, 255))
            else
                addLog("✅ Request function tersedia", Color3.fromRGB(100, 255, 100))
            end
            
            -- Hook event
            local eventSuccess, FishEvent = pcall(function()
                return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
            end)
            
            if not eventSuccess then
                addLog("❌ Event ikan tidak ditemukan!", Color3.fromRGB(255, 50, 50))
                isRunning = false
                ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
                ToggleButton.Text = "OFF"
                StatusText.Text = "Status: 🔴 Error"
                return
            end
            
            addLog("✅ Event hooked: ObtainedNewFishNotification", Color3.fromRGB(150, 255, 150))
            
            local conn = FishEvent.OnClientEvent:Connect(function(fishId, metadata1, metadata2, ...)
                local weight = nil
                
                if typeof(metadata1) == "table" and metadata1.Weight then
                    weight = metadata1.Weight
                end
                
                if typeof(metadata2) == "table" and metadata2.InventoryItem and metadata2.InventoryItem.Metadata then
                    weight = metadata2.InventoryItem.Metadata.Weight or weight
                end
                
                totalFishCaught = totalFishCaught + 1
                FishCounter.Text = "🐟 Fish Caught: " .. totalFishCaught
                
                addLog("🎣 Ikan tertangkap! ID: " .. fishId .. " | Berat: " .. (weight and string.format("%.2f kg", weight) or "Unknown"), Color3.fromRGB(100, 200, 255))
                
                sendWebhook(fishId, weight, metadata2)
            end)
            
            table.insert(connections, conn)
            addLog("🎣 Siap! Tangkap ikan untuk test", Color3.fromRGB(255, 255, 100))
            
        else
            -- STOP
            isRunning = false
            ToggleButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
            ToggleButton.Text = "OFF"
            StatusText.Text = "Status: 🔴 Stopped"
            StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
            
            for _, conn in pairs(connections) do
                conn:Disconnect()
            end
            connections = {}
            
            addLog("🛑 Webhook dimatikan", Color3.fromRGB(255, 100, 100))
        end
    end
    
    -- ==================== MINIMIZE FUNCTION ====================
    local function toggleMinimize()
        isMinimized = not isMinimized
        
        if isMinimized then
            ContentFrame.Visible = false
            MainFrame.Size = UDim2.new(0, 420, 0, 60)
            MinimizeBtn.Text = "+"
        else
            ContentFrame.Visible = true
            MainFrame.Size = UDim2.new(0, 420, 0, 700)
            MinimizeBtn.Text = "−"
        end
    end
    
    local function copyLog()
        if fullLog == "" then
            addLog("⚠️ Tidak ada log untuk di-copy!", Color3.fromRGB(255, 200, 0))
            return
        end
        
        if setclipboard then
            setclipboard(fullLog)
            addLog("📋 Log berhasil di-copy ke clipboard!", Color3.fromRGB(100, 255, 100))
        else
            addLog("❌ Clipboard tidak support di executor ini", Color3.fromRGB(255, 100, 100))
        end
    end
    
    -- Button Events
    ToggleButton.MouseButton1Click:Connect(toggleWebhook)
    MinimizeBtn.MouseButton1Click:Connect(toggleMinimize)
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        for _, conn in pairs(connections) do
            conn:Disconnect()
        end
    end)
    CopyBtn.MouseButton1Click:Connect(copyLog)
    
    -- Initial Logs
    addLog("🎣 Webhook By Raditya Loaded!", Color3.fromRGB(100, 255, 255))
    addLog("📱 UI siap digunakan", Color3.fromRGB(200, 200, 200))
    addLog("🌐 Masukkan webhook URL lalu klik ON", Color3.fromRGB(200, 200, 200))
    addLog("💡 Gunakan tombol − untuk minimize UI", Color3.fromRGB(200, 200, 200))
end

-- ==================== JALANKAN ====================
createUI()
print("✅ UI Loaded! Check your screen")
