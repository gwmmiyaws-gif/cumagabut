--!strict
-- RockHub Premium - Blatant Fishing & Auto Totem Only
-- Converted to Luau with strict type checking

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Window = WindUI:CreateWindow({
    Title = "RockHub - Fish It (Lite)",
    Icon = "rbxassetid://116236936447443",
    Author = "Premium Version",
    Folder = "RockHub",
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

-- =====================================================
-- TYPE DEFINITIONS
-- =====================================================
type RemoteEvent = RemoteEvent
type RemoteFunction = RemoteFunction
type Vector3 = Vector3
type CFrame = CFrame

-- =====================================================
-- SERVICES & GLOBALS
-- =====================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer: Player = Players.LocalPlayer
local RPath: {string} = {"Packages", "_Index", "sleitnick_net@0.2.0", "net"}

-- =====================================================
-- HELPER FUNCTIONS
-- =====================================================
local function GetRemote(remotePath: {string}, name: string, timeout: number?): Instance?
    local currentInstance: Instance = ReplicatedStorage
    for _, childName in ipairs(remotePath) do
        local child = currentInstance:WaitForChild(childName, timeout or 0.5)
        if not child then 
            return nil 
        end
        currentInstance = child
    end
    return currentInstance:FindFirstChild(name)
end

local function GetHRP(): BasePart?
    local Character = LocalPlayer.Character
    if not Character then
        Character = LocalPlayer.CharacterAdded:Wait()
    end
    return Character:WaitForChild("HumanoidRootPart", 5) :: BasePart
end

-- =====================================================
-- REMOTE DEFINITIONS
-- =====================================================
local RE_EquipToolFromHotbar = GetRemote(RPath, "RE/EquipToolFromHotbar") :: RemoteEvent?
local RF_ChargeFishingRod = GetRemote(RPath, "RF/ChargeFishingRod") :: RemoteFunction?
local RF_RequestFishingMinigameStarted = GetRemote(RPath, "RF/RequestFishingMinigameStarted") :: RemoteFunction?
local RE_FishingCompleted = GetRemote(RPath, "RE/FishingCompleted") :: RemoteEvent?
local RF_CancelFishingInputs = GetRemote(RPath, "RF/CancelFishingInputs") :: RemoteFunction?
local RF_UpdateAutoFishingState = GetRemote(RPath, "RF/UpdateAutoFishingState") :: RemoteFunction?
local RE_SpawnTotem = GetRemote(RPath, "RE/SpawnTotem") :: RemoteEvent?

-- =====================================================
-- BLATANT FISHING VARIABLES
-- =====================================================
local blatantInstantState: boolean = false
local blatantLoopThread: thread? = nil
local blatantEquipThread: thread? = nil

local completeDelay: number = 3.055
local cancelDelay: number = 0.3
local loopInterval: number = 1.715

_G.RockHub_BlatantActive = false

-- =====================================================
-- TOTEM VARIABLES
-- =====================================================
local AUTO_TOTEM_ACTIVE: boolean = false
local AUTO_TOTEM_THREAD: thread? = nil
local selectedTotemName: string = "Luck Totem"
local currentTotemExpiry: number = 0

local TOTEM_DATA: {[string]: {Id: number, Duration: number}} = {
    ["Luck Totem"] = {Id = 1, Duration = 3601},
    ["Mutation Totem"] = {Id = 2, Duration = 3601},
    ["Shiny Totem"] = {Id = 3, Duration = 3601}
}

local TOTEM_NAMES: {string} = {"Luck Totem", "Mutation Totem", "Shiny Totem"}

-- =====================================================
-- ANTI-AFK
-- =====================================================
pcall(function()
    local player = LocalPlayer
    for _, v in pairs(getconnections(player.Idled)) do
        if v.Disable then
            v:Disable()
            print("[RockHub Anti-AFK] ON")
        end
    end
end)

-- =====================================================
-- BLATANT FISHING LOGIC
-- =====================================================

-- [1] CONTROLLER KILLER
task.spawn(function()
    local success, FishingController = pcall(function() 
        return require(ReplicatedStorage.Controllers.FishingController) 
    end)
    
    if success and FishingController then
        local Old_Charge = FishingController.RequestChargeFishingRod
        local Old_Cast = FishingController.SendFishingRequestToServer
        
        FishingController.RequestChargeFishingRod = function(...)
            if _G.RockHub_BlatantActive then 
                return 
            end 
            return Old_Charge(...)
        end
        
        FishingController.SendFishingRequestToServer = function(...)
            if _G.RockHub_BlatantActive then 
                return false, "Blocked by RockHub" 
            end
            return Old_Cast(...)
        end
    end
end)

-- [2] REMOTE KILLER
local mt = getrawmetatable(game)
local old_namecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self: Instance, ...: any): any
    local method = getnamecallmethod()
    if _G.RockHub_BlatantActive and not checkcaller() then
        if method == "InvokeServer" and (
            self.Name == "RequestFishingMinigameStarted" or 
            self.Name == "ChargeFishingRod" or 
            self.Name == "UpdateAutoFishingState"
        ) then
            return nil 
        end
        if method == "FireServer" and self.Name == "FishingCompleted" then
            return nil
        end
    end
    return old_namecall(self, ...)
end)

setreadonly(mt, true)

-- [3] UI SPOOF
local function SuppressGameVisuals(active: boolean): ()
    local success, TextController = pcall(function() 
        return require(ReplicatedStorage.Controllers.TextNotificationController) 
    end)
    
    if success and TextController then
        if active then
            if not TextController._OldDeliver then 
                TextController._OldDeliver = TextController.DeliverNotification 
            end
            TextController.DeliverNotification = function(self, data)
                if data and data.Text and (
                    string.find(tostring(data.Text), "Auto Fishing") or 
                    string.find(tostring(data.Text), "Reach Level")
                ) then
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
            local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
            
            local InactiveColor = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromHex("ff5d60")), 
                ColorSequenceKeypoint.new(1, Color3.fromHex("ff2256"))
            })

            while _G.RockHub_BlatantActive do
                local targets: {Instance} = {}
                
                for _, btn in ipairs(CollectionService:GetTagged("AutoFishingButton")) do
                    table.insert(targets, btn)
                end
                
                if #targets == 0 then
                    local btn = PlayerGui:FindFirstChild("Backpack") 
                        and PlayerGui.Backpack:FindFirstChild("AutoFishingButton")
                    if btn then 
                        table.insert(targets, btn) 
                    end
                end

                for _, btn in ipairs(targets) do
                    local grad = btn:FindFirstChild("UIGradient")
                    if grad then
                        grad.Color = InactiveColor
                    end
                end
                
                RunService.RenderStepped:Wait()
            end
        end)
    end
end

-- [4] INSTANT FISH FUNCTION
local function runBlatantInstant(): ()
    if not blatantInstantState then 
        return 
    end
    
    task.spawn(function()
        local startTime: number = os.clock()
        local timestamp: number = os.time() + os.clock()
        
        pcall(function() 
            if RF_ChargeFishingRod then
                RF_ChargeFishingRod:InvokeServer(timestamp) 
            end
        end)
        task.wait(0.001)
        
        pcall(function() 
            if RF_RequestFishingMinigameStarted then
                RF_RequestFishingMinigameStarted:InvokeServer(-139.6379699707, 0.99647927980797) 
            end
        end)
        
        local completeWaitTime: number = completeDelay - (os.clock() - startTime)
        if completeWaitTime > 0 then 
            task.wait(completeWaitTime) 
        end
        
        pcall(function() 
            if RE_FishingCompleted then
                RE_FishingCompleted:FireServer() 
            end
        end)
        task.wait(cancelDelay)
        
        pcall(function() 
            if RF_CancelFishingInputs then
                RF_CancelFishingInputs:InvokeServer() 
            end
        end)
    end)
end

-- =====================================================
-- TOTEM LOGIC
-- =====================================================
local function GetPlayerDataReplion()
    local ReplionModule = ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Replion", 10)
    if not ReplionModule then 
        return nil 
    end
    local ReplionClient = require(ReplionModule).Client
    return ReplionClient:WaitReplion("Data", 5)
end

local function GetTotemUUID(name: string): string?
    local replion = GetPlayerDataReplion()
    if not replion then 
        return nil 
    end
    
    local success, inventoryData = pcall(function() 
        return replion:GetExpect("Inventory") 
    end)
    
    if success and inventoryData.Totems then 
        for _, item in ipairs(inventoryData.Totems) do 
            if tonumber(item.Id) == TOTEM_DATA[name].Id and (item.Count or 1) >= 1 then 
                return item.UUID 
            end 
        end 
    end
    
    return nil
end

local function RunAutoTotemLoop(): ()
    if AUTO_TOTEM_THREAD then 
        task.cancel(AUTO_TOTEM_THREAD) 
    end
    
    AUTO_TOTEM_THREAD = task.spawn(function()
        while AUTO_TOTEM_ACTIVE do
            local timeLeft: number = currentTotemExpiry - os.time()
            
            if timeLeft <= 0 then
                local uuid: string? = GetTotemUUID(selectedTotemName)
                if uuid then
                    pcall(function() 
                        if RE_SpawnTotem then
                            RE_SpawnTotem:FireServer(uuid) 
                        end
                    end)
                    currentTotemExpiry = os.time() + TOTEM_DATA[selectedTotemName].Duration
                    
                    task.spawn(function() 
                        for i = 1, 3 do 
                            task.wait(0.2) 
                            pcall(function() 
                                if RE_EquipToolFromHotbar then
                                    RE_EquipToolFromHotbar:FireServer(1) 
                                end
                            end) 
                        end 
                    end)
                end
            end
            
            task.wait(1)
        end
    end)
end

-- =====================================================
-- UI CREATION
-- =====================================================
local farm = Window:Tab({
    Title = "Fishing",
    Icon = "fish",
    Locked = false,
})

-- BLATANT SECTION
local blatant = farm:Section({
    Title = "Blatant Mode",
    TextSize = 20,
})

local LoopIntervalInput = blatant:Input({
    Title = "Blatant Interval",
    Value = tostring(loopInterval),
    Icon = "fast-forward",
    Type = "Input",
    Placeholder = "1.58",
    Callback = function(input: string)
        local newInterval: number? = tonumber(input)
        if newInterval and newInterval >= 0.5 then 
            loopInterval = newInterval 
        end
    end
})

local CompleteDelayInput = blatant:Input({
    Title = "Complete Delay",
    Value = tostring(completeDelay),
    Icon = "loader",
    Type = "Input",
    Placeholder = "2.75",
    Callback = function(input: string)
        local newDelay: number? = tonumber(input)
        if newDelay and newDelay >= 0.5 then 
            completeDelay = newDelay 
        end
    end
})

local CancelDelayInput = blatant:Input({
    Title = "Cancel Delay",
    Value = tostring(cancelDelay),
    Icon = "clock",
    Type = "Input",
    Placeholder = "0.3",
    Callback = function(input: string)
        local newDelay: number? = tonumber(input)
        if newDelay and newDelay >= 0.1 then 
            cancelDelay = newDelay 
        end
    end
})

local togblat = blatant:Toggle({
    Title = "Instant Fishing (Blatant)",
    Value = false,
    Callback = function(state: boolean)
        blatantInstantState = state
        _G.RockHub_BlatantActive = state
        
        SuppressGameVisuals(state)
        
        if state then
            -- Server State ON
            if RF_UpdateAutoFishingState then
                pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
                task.wait(0.5)
                pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
                pcall(function() RF_UpdateAutoFishingState:InvokeServer(true) end)
            end

            -- Loop
            blatantLoopThread = task.spawn(function()
                while blatantInstantState do
                    runBlatantInstant()
                    task.wait(loopInterval)
                end
            end)

            -- Auto Equip
            if blatantEquipThread then 
                task.cancel(blatantEquipThread) 
            end
            
            blatantEquipThread = task.spawn(function()
                while blatantInstantState do
                    pcall(function() 
                        if RE_EquipToolFromHotbar then
                            RE_EquipToolFromHotbar:FireServer(1) 
                        end
                    end)
                    task.wait(0.1) 
                end
            end)
            
            WindUI:Notify({
                Title = "Blatant Mode ON",
                Duration = 3,
                Icon = "zap"
            })
        else
            -- Server State OFF
            if RF_UpdateAutoFishingState then
                pcall(function() RF_UpdateAutoFishingState:InvokeServer(false) end)
            end

            if blatantLoopThread then 
                task.cancel(blatantLoopThread) 
                blatantLoopThread = nil 
            end
            
            if blatantEquipThread then 
                task.cancel(blatantEquipThread) 
                blatantEquipThread = nil 
            end
            
            WindUI:Notify({
                Title = "Stopped",
                Duration = 2
            })
        end
    end
})

-- TOTEM SECTION
local premium = Window:Tab({
    Title = "Premium",
    Icon = "star",
    Locked = false,
})

local totem = premium:Section({
    Title = "Auto Spawn Totem",
    TextSize = 20
})

local TOTEM_STATUS_PARAGRAPH = totem:Paragraph({
    Title = "Status",
    Content = "Waiting...",
    Icon = "clock"
})

local choosetot = totem:Dropdown({
    Title = "Pilih Jenis Totem",
    Values = TOTEM_NAMES,
    Value = selectedTotemName,
    Multi = false,
    Callback = function(name: string)
        selectedTotemName = name
        currentTotemExpiry = 0
    end
})

local togtot = totem:Toggle({
    Title = "Enable Auto Totem (Single)",
    Desc = "Mode Normal",
    Value = false,
    Callback = function(state: boolean)
        AUTO_TOTEM_ACTIVE = state
        if state then
            RunAutoTotemLoop()
        else
            if AUTO_TOTEM_THREAD then 
                task.cancel(AUTO_TOTEM_THREAD) 
            end
        end
    end
})

-- =====================================================
-- FINALIZATION
-- =====================================================
Window:Tag({
    Title = "Lite V1.0",
    Color = Color3.fromHex("#F5C527"),
    Radius = 9,
})

Window:EditOpenButton({
    Title = "RockHub - Fish It",
    Icon = "rbxassetid://116236936447443",
    CornerRadius = UDim.new(0, 30),
    StrokeThickness = 1.5,
    Color = ColorSequence.new(
        Color3.fromHex("FF0F7B"),
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

WindUI:Notify({
    Title = "RockHub Lite Loaded",
    Content = "Blatant Fishing & Auto Totem Ready",
    Duration = 5,
    Icon = "info"
})
