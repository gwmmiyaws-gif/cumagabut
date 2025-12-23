-- ==================== FISH IT WEBHOOK WITH FULL UI (MOBILE FRIENDLY) ====================
-- UI lengkap dengan Start, Stop, Copy Log, dan Live Error Detection

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

-- ==================== KONFIGURASI ====================
local WEBHOOK_URL = "https://discord.com/api/webhooks/1446677688453566655/Xo6u363NGUlSmxhtfAyjXqw8U9fRkfZ8kdSuDxUf82sDBywgcJkEj3XYngSaKFFWu8Hp"

-- Variables
local isRunning = false
local connections = {}
local fullLog = ""
local imageCache = {}
local fishDataCache = {}
local totalFishCaught = 0
local successfulWebhooks = 0

-- ==================== FUNGSI GAMBAR ====================
local function GetRobloxImage(assetId)
    if imageCache[assetId] then
        return imageCache[assetId]
    end
    
    local url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. assetId .. "&size=420x420&format=Png&isCircular=false"
    local success, response = pcall(function()
        return game:HttpGet(url)
    end)
    
    if success then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response)
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
    -- Hapus UI lama
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
    MainFrame.Size = UDim2.new(0, 400, 0, 600)
    MainFrame.Position = UDim2.new(0.5, -200, 0.5, -300)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 15)
    MainCorner.Parent = MainFrame
    
    -- Shadow
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
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🎣 Fish It Webhook"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 20
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
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
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        for _, conn in pairs(connections) do
            conn:Disconnect()
        end
    end)
    
    -- Status Panel
    local StatusPanel = Instance.new("Frame")
    StatusPanel.Size = UDim2.new(1, -30, 0, 120)
    StatusPanel.Position = UDim2.new(0, 15, 0, 75)
    StatusPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    StatusPanel.BorderSizePixel = 0
    StatusPanel.Parent = MainFrame
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 12)
    StatusCorner.Parent = StatusPanel
    
    -- Status Text
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
    
    -- Buttons Panel
    local ButtonsPanel = Instance.new("Frame")
    ButtonsPanel.Size = UDim2.new(1, -30, 0, 55)
    ButtonsPanel.Position = UDim2.new(0, 15, 0, 210)
    ButtonsPanel.BackgroundTransparency = 1
    ButtonsPanel.Parent = MainFrame
    
    local StartBtn = Instance.new("TextButton")
    StartBtn.Name = "StartBtn"
    StartBtn.Size = UDim2.new(0.48, 0, 1, 0)
    StartBtn.Position = UDim2.new(0, 0, 0, 0)
    StartBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 80)
    StartBtn.Text = "▶ START"
    StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartBtn.TextSize = 16
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.BorderSizePixel = 0
    StartBtn.Parent = ButtonsPanel
    
    local StartBtnCorner = Instance.new("UICorner")
    StartBtnCorner.CornerRadius = UDim.new(0, 10)
    StartBtnCorner.Parent = StartBtn
    
    local StopBtn = Instance.new("TextButton")
    StopBtn.Name = "StopBtn"
    StopBtn.Size = UDim2.new(0.48, 0, 1, 0)
    StopBtn.Position = UDim2.new(0.52, 0, 0, 0)
    StopBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    StopBtn.Text = "⬛ STOP"
    StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    StopBtn.TextSize = 16
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.BorderSizePixel = 0
    StopBtn.Parent = ButtonsPanel
    
    local StopBtnCorner = Instance.new("UICorner")
    StopBtnCorner.CornerRadius = UDim.new(0, 10)
    StopBtnCorner.Parent = StopBtn
    
    -- Copy Button
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(1, -30, 0, 45)
    CopyBtn.Position = UDim2.new(0, 15, 0, 275)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 220)
    CopyBtn.Text = "📋 COPY LOG"
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.TextSize = 15
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.BorderSizePixel = 0
    CopyBtn.Parent = MainFrame
    
    local CopyBtnCorner = Instance.new("UICorner")
    CopyBtnCorner.CornerRadius = UDim.new(0, 10)
    CopyBtnCorner.Parent = CopyBtn
    
    -- Log Frame
    local LogFrame = Instance.new("ScrollingFrame")
    LogFrame.Name = "LogFrame"
    LogFrame.Size = UDim2.new(1, -30, 0, 250)
    LogFrame.Position = UDim2.new(0, 15, 0, 335)
    LogFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    LogFrame.BorderSizePixel = 0
    LogFrame.ScrollBarThickness = 8
    LogFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    LogFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    LogFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    LogFrame.Parent = MainFrame
    
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
    local errorCount = 0
    
    local function sendWebhook(fishId, weight, metadata)
        task.spawn(function()
            local player = Players.LocalPlayer
            local assetId, fishName = FindFishAssetId(fishId)
            local imageUrl = nil
            
            if assetId then
                imageUrl = GetRobloxImage(assetId)
                addLog("🖼️ Asset ID: " .. assetId .. (imageUrl and " (Image found)" or " (No image)"), Color3.fromRGB(150, 150, 255))
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
                {["name"] = "🕐 Time", ["value"] = "```" .. os.date("%H:%M:%S") .. "```", ["inline"] = true}
            }
            
            local embed = {
                ["title"] = "🎣 Ikan Tertangkap!",
                ["description"] = "**" .. player.Name .. "** menangkap **" .. fishName .. "**!",
                ["color"] = color,
                ["fields"] = fields,
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
            
            local webhookSuccess, response = pcall(function()
                return HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson, false)
            end)
            
            if webhookSuccess then
                successfulWebhooks = successfulWebhooks + 1
                WebhookCounter.Text = "✅ Webhooks Sent: " .. successfulWebhooks
                addLog("✅ Webhook sent: " .. fishName, Color3.fromRGB(100, 255, 100))
            else
                errorCount = errorCount + 1
                ErrorText.Text = "⚠️ Errors: " .. errorCount
                addLog("❌ Webhook failed: " .. tostring(response), Color3.fromRGB(255, 100, 100))
                
                if setclipboard then
                    setclipboard(string.format("Fish: %s | ID: %d | Weight: %.2f kg", fishName, fishId, weight or 0))
                    addLog("📋 Data copied to clipboard", Color3.fromRGB(255, 200, 100))
                end
            end
        end)
    end
    
    -- ==================== START/STOP ====================
    local function startMonitoring()
        if isRunning then
            addLog("⚠️ Already running!", Color3.fromRGB(255, 200, 0))
            return
        end
        
        isRunning = true
        StatusText.Text = "Status: 🟢 Running"
        StatusText.TextColor3 = Color3.fromRGB(100, 255, 100)
        addLog("✅ Monitoring started!", Color3.fromRGB(100, 255, 100))
        
        -- Test HttpService
        local httpTest = pcall(function()
            game:HttpGet("https://httpbin.org/get")
        end)
        
        if not httpTest then
            addLog("⚠️ HttpService disabled! Webhook won't work", Color3.fromRGB(255, 150, 50))
            addLog("💡 Data will be copied to clipboard instead", Color3.fromRGB(200, 200, 255))
        else
            addLog("✅ HttpService enabled", Color3.fromRGB(100, 255, 100))
        end
        
        -- Hook event
        local eventSuccess, FishEvent = pcall(function()
            return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
        end)
        
        if not eventSuccess then
            addLog("❌ Cannot find fish event!", Color3.fromRGB(255, 50, 50))
            isRunning = false
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
            
            addLog("🎣 Fish caught! ID: " .. fishId .. " | Weight: " .. (weight and string.format("%.2f kg", weight) or "Unknown"), Color3.fromRGB(100, 200, 255))
            
            sendWebhook(fishId, weight, metadata2)
        end)
        
        table.insert(connections, conn)
        addLog("🎣 Ready! Catch a fish to test", Color3.fromRGB(255, 255, 100))
    end
    
    local function stopMonitoring()
        if not isRunning then
            addLog("⚠️ Not running!", Color3.fromRGB(255, 200, 0))
            return
        end
        
        isRunning = false
        StatusText.Text = "Status: 🔴 Stopped"
        StatusText.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        for _, conn in pairs(connections) do
            conn:Disconnect()
        end
        connections = {}
        
        addLog("🛑 Monitoring stopped", Color3.fromRGB(255, 100, 100))
    end
    
    local function copyLog()
        if fullLog == "" then
            addLog("⚠️ No log to copy!", Color3.fromRGB(255, 200, 0))
            return
        end
        
        if setclipboard then
            setclipboard(fullLog)
            addLog("📋 Log copied to clipboard!", Color3.fromRGB(100, 255, 100))
        else
            addLog("❌ Clipboard not supported on this executor", Color3.fromRGB(255, 100, 100))
        end
    end
    
    -- Button events
    StartBtn.MouseButton1Click:Connect(startMonitoring)
    StopBtn.MouseButton1Click:Connect(stopMonitoring)
    CopyBtn.MouseButton1Click:Connect(copyLog)
    
    -- Initial logs
    addLog("🎣 Fish It Webhook UI Loaded!", Color3.fromRGB(100, 255, 255))
    addLog("📱 Mobile/Android compatible", Color3.fromRGB(200, 200, 200))
    addLog("🚀 Click START to begin", Color3.fromRGB(200, 200, 200))
end

-- ==================== JALANKAN ====================
createUI()
print("✅ Fish It Webhook UI loaded successfully!")
