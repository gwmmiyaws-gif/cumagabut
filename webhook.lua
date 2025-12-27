-- ==================== FISH IT WEBHOOK - AUTHENTIC RAYFIELD STYLE ====================
-- Made by Raditya | Inspired by Rayfield UI Library (sirius.menu/rayfield)

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

print("=" .. string.rep("=", 50))
print("🎣 Webhook By Raditya Loaded!")
print("=" .. string.rep("=", 50))

-- Variables
local isRunning = false
local connections = {}
local totalFishCaught = 0
local successfulWebhooks = 0
local WEBHOOK_URL = ""

-- Rayfield Theme Colors
local Theme = {
    Background = Color3.fromRGB(25, 25, 25),
    Topbar = Color3.fromRGB(34, 34, 34),
    ElementBackground = Color3.fromRGB(35, 35, 35),
    ElementBackgroundHover = Color3.fromRGB(40, 40, 40),
    ElementStroke = Color3.fromRGB(50, 50, 50),
    TextColor = Color3.fromRGB(240, 240, 240),
    ToggleEnabled = Color3.fromRGB(0, 146, 214),
    ToggleDisabled = Color3.fromRGB(100, 100, 100),
    Shadow = Color3.fromRGB(20, 20, 20)
}

-- ==================== FISH DATA FUNCTIONS ====================
local function GetFishData(fishId)
    local fishName = "Unknown Fish"
    local assetId = nil
    
    local success, fishCollection = pcall(function()
        return ReplicatedStorage.Modules.ModelDownloader.Collection.Fish
    end)
    
    if success and fishCollection then
        for _, fishModule in pairs(fishCollection:GetChildren()) do
            if fishModule:IsA("ModuleScript") then
                local modSuccess, data = pcall(function()
                    return require(fishModule)
                end)
                
                if modSuccess and data then
                    local moduleId = data.Id or data.ID or tonumber(fishModule.Name)
                    
                    if moduleId == fishId then
                        fishName = data.Name or data.DisplayName or fishModule.Name
                        assetId = data.AssetId or data.Asset or data.MeshId or data.TextureId
                        
                        if assetId and type(assetId) == "string" then
                            assetId = assetId:match("%d+")
                        end
                        break
                    end
                end
            end
        end
    end
    
    return fishName, assetId
end

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

-- ==================== CREATE RAYFIELD UI ====================
local function createUI()
    if CoreGui:FindFirstChild("RayfieldWebhook") then
        CoreGui:FindFirstChild("RayfieldWebhook"):Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RayfieldWebhook"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    if gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = CoreGui
    end
    
    -- Main Container
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 500, 0, 350)
    Main.Position = UDim2.new(0.5, -250, 0.5, -175)
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = Main
    
    -- Shadow Effect
    local Shadow = Instance.new("Frame")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 0, 1, 0)
    Shadow.Position = UDim2.new(0, 0, 0, 0)
    Shadow.BackgroundTransparency = 1
    Shadow.ZIndex = 0
    Shadow.Parent = Main
    
    local ShadowImage = Instance.new("ImageLabel")
    ShadowImage.Size = UDim2.new(1, 47, 1, 47)
    ShadowImage.Position = UDim2.new(0.5, 0, 0.5, 0)
    ShadowImage.AnchorPoint = Vector2.new(0.5, 0.5)
    ShadowImage.BackgroundTransparency = 1
    ShadowImage.Image = "rbxassetid://5554236805"
    ShadowImage.ImageColor3 = Theme.Shadow
    ShadowImage.ImageTransparency = 0.4
    ShadowImage.ScaleType = Enum.ScaleType.Slice
    ShadowImage.SliceCenter = Rect.new(23, 23, 277, 277)
    ShadowImage.Parent = Shadow
    
    -- Topbar
    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 45)
    Topbar.BackgroundColor3 = Theme.Topbar
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main
    
    local TopbarCorner = Instance.new("UICorner")
    TopbarCorner.CornerRadius = UDim.new(0, 8)
    TopbarCorner.Parent = Topbar
    
    local TopbarFix = Instance.new("Frame")
    TopbarFix.Size = UDim2.new(1, 0, 0, 20)
    TopbarFix.Position = UDim2.new(0, 0, 1, -20)
    TopbarFix.BackgroundColor3 = Theme.Topbar
    TopbarFix.BorderSizePixel = 0
    TopbarFix.Parent = Topbar
    
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, 0, 0, 1)
    Divider.Position = UDim2.new(0, 0, 1, 0)
    Divider.BackgroundColor3 = Theme.ElementStroke
    Divider.BorderSizePixel = 0
    Divider.Parent = Topbar
    
    -- Title
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -90, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Fish It Webhook"
    Title.TextColor3 = Theme.TextColor
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Topbar
    
    local Subtitle = Instance.new("TextLabel")
    Subtitle.Size = UDim2.new(1, -90, 0, 12)
    Subtitle.Position = UDim2.new(0, 15, 0, 24)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = "by Raditya"
    Subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
    Subtitle.TextSize = 11
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.Parent = Topbar
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundColor3 = Theme.ElementBackground
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Theme.TextColor
    CloseBtn.TextSize = 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = Topbar
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 6)
    CloseBtnCorner.Parent = CloseBtn
    
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(220, 50, 70)}):Play()
    end)
    
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.ElementBackground}):Play()
    end)
    
    CloseBtn.MouseButton1Click:Connect(function()
        TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 0, 0, 0)}):Play()
        task.wait(0.3)
        ScreenGui:Destroy()
        for _, conn in pairs(connections) do
            conn:Disconnect()
        end
    end)
    
    -- Content
    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -30, 1, -75)
    Content.Position = UDim2.new(0, 15, 0, 60)
    Content.BackgroundTransparency = 1
    Content.Parent = Main
    
    -- Webhook URL Input
    local InputLabel = Instance.new("TextLabel")
    InputLabel.Size = UDim2.new(1, 0, 0, 16)
    InputLabel.BackgroundTransparency = 1
    InputLabel.Text = "Webhook URL"
    InputLabel.TextColor3 = Theme.TextColor
    InputLabel.TextSize = 13
    InputLabel.Font = Enum.Font.GothamBold
    InputLabel.TextXAlignment = Enum.TextXAlignment.Left
    InputLabel.Parent = Content
    
    local InputContainer = Instance.new("Frame")
    InputContainer.Size = UDim2.new(1, 0, 0, 40)
    InputContainer.Position = UDim2.new(0, 0, 0, 22)
    InputContainer.BackgroundColor3 = Theme.ElementBackground
    InputContainer.BorderSizePixel = 0
    InputContainer.Parent = Content
    
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = InputContainer
    
    local InputStroke = Instance.new("UIStroke")
    InputStroke.Color = Theme.ElementStroke
    InputStroke.Thickness = 1
    InputStroke.Parent = InputContainer
    
    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -20, 1, 0)
    InputBox.Position = UDim2.new(0, 10, 0, 0)
    InputBox.BackgroundTransparency = 1
    InputBox.Text = ""
    InputBox.PlaceholderText = "discord.com/api/webhooks/..."
    InputBox.TextColor3 = Theme.TextColor
    InputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    InputBox.TextSize = 12
    InputBox.Font = Enum.Font.Gotham
    InputBox.TextXAlignment = Enum.TextXAlignment.Left
    InputBox.ClearTextOnFocus = false
    InputBox.Parent = InputContainer
    
    -- Toggle Element
    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, 0, 0, 16)
    ToggleLabel.Position = UDim2.new(0, 0, 0, 78)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = "Enable Webhook"
    ToggleLabel.TextColor3 = Theme.TextColor
    ToggleLabel.TextSize = 13
    ToggleLabel.Font = Enum.Font.GothamBold
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = Content
    
    local ToggleContainer = Instance.new("Frame")
    ToggleContainer.Size = UDim2.new(1, 0, 0, 40)
    ToggleContainer.Position = UDim2.new(0, 0, 0, 100)
    ToggleContainer.BackgroundColor3 = Theme.ElementBackground
    ToggleContainer.BorderSizePixel = 0
    ToggleContainer.Parent = Content
    
    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 6)
    ToggleCorner.Parent = ToggleContainer
    
    local ToggleStroke = Instance.new("UIStroke")
    ToggleStroke.Color = Theme.ElementStroke
    ToggleStroke.Thickness = 1
    ToggleStroke.Parent = ToggleContainer
    
    local ToggleText = Instance.new("TextLabel")
    ToggleText.Size = UDim2.new(1, -70, 1, 0)
    ToggleText.Position = UDim2.new(0, 12, 0, 0)
    ToggleText.BackgroundTransparency = 1
    ToggleText.Text = "Status: Disabled"
    ToggleText.TextColor3 = Color3.fromRGB(180, 180, 180)
    ToggleText.TextSize = 12
    ToggleText.Font = Enum.Font.Gotham
    ToggleText.TextXAlignment = Enum.TextXAlignment.Left
    ToggleText.Parent = ToggleContainer
    
    -- Rayfield-style Toggle Switch
    local ToggleOuter = Instance.new("Frame")
    ToggleOuter.Size = UDim2.new(0, 44, 0, 24)
    ToggleOuter.Position = UDim2.new(1, -56, 0.5, -12)
    ToggleOuter.BackgroundColor3 = Theme.ToggleDisabled
    ToggleOuter.BorderSizePixel = 0
    ToggleOuter.Parent = ToggleContainer
    
    local ToggleOuterCorner = Instance.new("UICorner")
    ToggleOuterCorner.CornerRadius = UDim.new(1, 0)
    ToggleOuterCorner.Parent = ToggleOuter
    
    local ToggleOuterStroke = Instance.new("UIStroke")
    ToggleOuterStroke.Color = Color3.fromRGB(125, 125, 125)
    ToggleOuterStroke.Thickness = 2
    ToggleOuterStroke.Parent = ToggleOuter
    
    local ToggleInner = Instance.new("Frame")
    ToggleInner.Size = UDim2.new(0, 18, 0, 18)
    ToggleInner.Position = UDim2.new(0, 3, 0.5, -9)
    ToggleInner.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
    ToggleInner.BorderSizePixel = 0
    ToggleInner.Parent = ToggleOuter
    
    local ToggleInnerCorner = Instance.new("UICorner")
    ToggleInnerCorner.CornerRadius = UDim.new(1, 0)
    ToggleInnerCorner.Parent = ToggleInner
    
    local ToggleButton = Instance.new("TextButton")
    ToggleButton.Size = UDim2.new(1, 0, 1, 0)
    ToggleButton.BackgroundTransparency = 1
    ToggleButton.Text = ""
    ToggleButton.Parent = ToggleOuter
    
    -- Stats
    local StatsLabel = Instance.new("TextLabel")
    StatsLabel.Size = UDim2.new(1, 0, 0, 16)
    StatsLabel.Position = UDim2.new(0, 0, 0, 156)
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Text = "Statistics"
    StatsLabel.TextColor3 = Theme.TextColor
    StatsLabel.TextSize = 13
    StatsLabel.Font = Enum.Font.GothamBold
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatsLabel.Parent = Content
    
    local StatsContainer = Instance.new("Frame")
    StatsContainer.Size = UDim2.new(1, 0, 0, 80)
    StatsContainer.Position = UDim2.new(0, 0, 0, 178)
    StatsContainer.BackgroundColor3 = Theme.ElementBackground
    StatsContainer.BorderSizePixel = 0
    StatsContainer.Parent = Content
    
    local StatsCorner = Instance.new("UICorner")
    StatsCorner.CornerRadius = UDim.new(0, 6)
    StatsCorner.Parent = StatsContainer
    
    local StatsStroke = Instance.new("UIStroke")
    StatsStroke.Color = Theme.ElementStroke
    StatsStroke.Thickness = 1
    StatsStroke.Parent = StatsContainer
    
    local FishStat = Instance.new("TextLabel")
    FishStat.Name = "FishStat"
    FishStat.Size = UDim2.new(1, -20, 0, 20)
    FishStat.Position = UDim2.new(0, 10, 0, 10)
    FishStat.BackgroundTransparency = 1
    FishStat.Text = "🐟 Fish Caught: 0"
    FishStat.TextColor3 = Theme.TextColor
    FishStat.TextSize = 12
    FishStat.Font = Enum.Font.Gotham
    FishStat.TextXAlignment = Enum.TextXAlignment.Left
    FishStat.Parent = StatsContainer
    
    local WebhookStat = Instance.new("TextLabel")
    WebhookStat.Name = "WebhookStat"
    WebhookStat.Size = UDim2.new(1, -20, 0, 20)
    WebhookStat.Position = UDim2.new(0, 10, 0, 32)
    WebhookStat.BackgroundTransparency = 1
    WebhookStat.Text = "✅ Webhooks Sent: 0"
    WebhookStat.TextColor3 = Theme.TextColor
    WebhookStat.TextSize = 12
    WebhookStat.Font = Enum.Font.Gotham
    WebhookStat.TextXAlignment = Enum.TextXAlignment.Left
    WebhookStat.Parent = StatsContainer
    
    local StatusStat = Instance.new("TextLabel")
    StatusStat.Name = "StatusStat"
    StatusStat.Size = UDim2.new(1, -20, 0, 20)
    StatusStat.Position = UDim2.new(0, 10, 0, 54)
    StatusStat.BackgroundTransparency = 1
    StatusStat.Text = "⚡ Status: Ready"
    StatusStat.TextColor3 = Theme.TextColor
    StatusStat.TextSize = 12
    StatusStat.Font = Enum.Font.Gotham
    StatusStat.TextXAlignment = Enum.TextXAlignment.Left
    StatusStat.Parent = StatsContainer
    
    -- ==================== WEBHOOK FUNCTION ====================
    local function sendWebhook(fishId, weight, metadata)
        task.spawn(function()
            if WEBHOOK_URL == "" or not WEBHOOK_URL:match("discord.com/api/webhooks") then
                StatusStat.Text = "⚠️ Status: Invalid URL"
                StatusStat.TextColor3 = Color3.fromRGB(255, 150, 100)
                return
            end
            
            local player = Players.LocalPlayer
            local fishName, assetId = GetFishData(fishId)
            local imageUrl = assetId and GetRobloxImage(assetId) or nil
            
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
                WebhookStat.Text = "✅ Webhooks Sent: " .. successfulWebhooks
                StatusStat.Text = "⚡ Status: Sent - " .. fishName
                StatusStat.TextColor3 = Color3.fromRGB(100, 255, 150)
            else
                StatusStat.Text = "⚠️ Status: Failed"
                StatusStat.TextColor3 = Color3.fromRGB(255, 150, 100)
            end
        end)
    end
    
    -- ==================== TOGGLE FUNCTION ====================
    ToggleButton.MouseButton1Click:Connect(function()
        isRunning = not isRunning
        
        if isRunning then
            WEBHOOK_URL = InputBox.Text
            
            if WEBHOOK_URL == "" or not WEBHOOK_URL:match("discord.com/api/webhooks") then
                StatusStat.Text = "⚠️ Status: Invalid URL"
                StatusStat.TextColor3 = Color3.fromRGB(255, 150, 100)
                isRunning = false
                return
            end
            
            -- Animate toggle ON
            TweenService:Create(ToggleOuter, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = Theme.ToggleEnabled}):Play()
            TweenService:Create(ToggleOuterStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(0, 170, 255)}):Play()
            TweenService:Create(ToggleInner, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(1, -21, 0.5, -9)}):Play()
            ToggleText.Text = "Status: Enabled"
            ToggleText.TextColor3 = Color3.fromRGB(150, 255, 150)
            StatusStat.Text = "⚡ Status: Monitoring..."
            StatusStat.TextColor3 = Color3.fromRGB(150, 150, 255)
            
            -- Hook event
            local eventSuccess, FishEvent = pcall(function()
                return ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net["RE/ObtainedNewFishNotification"]
            end)
            
            if not eventSuccess then
                StatusStat.Text = "⚠️ Status: Event Not Found"
                StatusStat.TextColor3 = Color3.fromRGB(255, 100, 100)
                isRunning = false
                TweenService:Create(ToggleOuter, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = Theme.ToggleDisabled}):Play()
                TweenService:Create(ToggleOuterStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(125, 125, 125)}):Play()
                TweenService:Create(ToggleInner, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 3, 0.5, -9)}):Play()
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
                FishStat.Text = "🐟 Fish Caught: " .. totalFishCaught
                
                sendWebhook(fishId, weight, metadata2)
            end)
            
            table.insert(connections, conn)
        else
            -- Animate toggle OFF
            TweenService:Create(ToggleOuter, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = Theme.ToggleDisabled}):Play()
            TweenService:Create(ToggleOuterStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Color = Color3.fromRGB(125, 125, 125)}):Play()
            TweenService:Create(ToggleInner, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {Position = UDim2.new(0, 3, 0.5, -9)}):Play()
            ToggleText.Text = "Status: Disabled"
            ToggleText.TextColor3 = Color3.fromRGB(180, 180, 180)
            StatusStat.Text = "⚡ Status: Stopped"
            StatusStat.TextColor3 = Theme.TextColor
            
            for _, conn in pairs(connections) do
                conn:Disconnect()
            end
            connections = {}
        end
    end)
    
    -- Entrance Animation (Rayfield style)
    Main.Size = UDim2.new(0, 0, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.6, Enum.EasingStyle.Exponential), {Size = UDim2.new(0, 500, 0, 350)}):Play()
end

-- ==================== RUN ====================
createUI()
print("✅ Rayfield-style UI Loaded!")
