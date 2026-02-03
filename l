local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

local svc = {
    RS = game:GetService("ReplicatedStorage"),
}

local mods = {
    Net = svc.RS.Packages._Index["sleitnick_net@0.2.0"].net,
}

local api = {
    Functions = {
        ChargeRod = mods.Net["RF/ChargeFishingRod"],
        StartMini = mods.Net["RF/RequestFishingMinigameStarted"],
        CatchFish = mods.Net["RF/CatchFishCompleted"],
        CancelFish = mods.Net["RF/CancelFishingInputs"],
    },
}

local Window = WindUI:CreateWindow({
    Title = "Fish Logger",
    Author = "Patungin",
    Folder = "FishLogger",
    Size = UDim2.fromOffset(500, 450),
    ToggleKey = Enum.KeyCode.G,
})

local Main = Window:Tab({
    Title = "Logger",
    Icon = "activity",
})

local Replay = Window:Tab({
    Title = "Replay",
    Icon = "play",
})

-- Storage untuk recorded data
local RecordedCalls = {}
local IsRecording = false
local IsReplaying = false
local RecordStartTime = 0

-- Statistik
local Stats = {
    ChargeRodCalls = 0,
    StartMiniCalls = 0,
    CatchCalls = 0,
    CancelCalls = 0,
    TotalCalls = 0,
    AvgDelay = 0,
}

-- Hook functions untuk detect calls
local OriginalChargeRod = api.Functions.ChargeRod.InvokeServer
local OriginalStartMini = api.Functions.StartMini.InvokeServer
local OriginalCatchFish = api.Functions.CatchFish.InvokeServer
local OriginalCancelFish = api.Functions.CancelFish.InvokeServer

local function StartRecording()
    RecordedCalls = {}
    RecordStartTime = tick()
    Stats.ChargeRodCalls = 0
    Stats.StartMiniCalls = 0
    Stats.CatchCalls = 0
    Stats.CancelCalls = 0
    Stats.TotalCalls = 0
    
    -- Hook ChargeRod
    api.Functions.ChargeRod.InvokeServer = function(self, ...)
        if IsRecording then
            local timestamp = tick() - RecordStartTime
            local args = {...}
            
            table.insert(RecordedCalls, {
                Type = "ChargeRod",
                Timestamp = timestamp,
                Args = args
            })
            
            Stats.ChargeRodCalls = Stats.ChargeRodCalls + 1
            Stats.TotalCalls = Stats.TotalCalls + 1
            
            print(string.format("[%.4fs] ChargeRod called | Args: %s", timestamp, table.concat(args, ", ")))
        end
        
        return OriginalChargeRod(self, ...)
    end
    
    -- Hook StartMini
    api.Functions.StartMini.InvokeServer = function(self, ...)
        if IsRecording then
            local timestamp = tick() - RecordStartTime
            local args = {...}
            
            table.insert(RecordedCalls, {
                Type = "StartMini",
                Timestamp = timestamp,
                Args = args
            })
            
            Stats.StartMiniCalls = Stats.StartMiniCalls + 1
            Stats.TotalCalls = Stats.TotalCalls + 1
            
            print(string.format("[%.4fs] StartMini called | Args: %s", timestamp, table.concat(args, ", ")))
        end
        
        return OriginalStartMini(self, ...)
    end
    
    -- Hook CatchFish
    api.Functions.CatchFish.InvokeServer = function(self, ...)
        if IsRecording then
            local timestamp = tick() - RecordStartTime
            local args = {...}
            
            table.insert(RecordedCalls, {
                Type = "CatchFish",
                Timestamp = timestamp,
                Args = args
            })
            
            Stats.CatchCalls = Stats.CatchCalls + 1
            Stats.TotalCalls = Stats.TotalCalls + 1
            
            print(string.format("[%.4fs] CatchFish called", timestamp))
        end
        
        return OriginalCatchFish(self, ...)
    end
    
    -- Hook CancelFish
    api.Functions.CancelFish.InvokeServer = function(self, ...)
        if IsRecording then
            local timestamp = tick() - RecordStartTime
            local args = {...}
            
            table.insert(RecordedCalls, {
                Type = "CancelFish",
                Timestamp = timestamp,
                Args = args
            })
            
            Stats.CancelCalls = Stats.CancelCalls + 1
            Stats.TotalCalls = Stats.TotalCalls + 1
            
            print(string.format("[%.4fs] CancelFish called", timestamp))
        end
        
        return OriginalCancelFish(self, ...)
    end
end

local function CalculateStats()
    if #RecordedCalls < 2 then return end
    
    local totalDelay = 0
    for i = 2, #RecordedCalls do
        totalDelay = totalDelay + (RecordedCalls[i].Timestamp - RecordedCalls[i-1].Timestamp)
    end
    
    Stats.AvgDelay = totalDelay / (#RecordedCalls - 1)
end

local function ReplayRecording()
    if #RecordedCalls == 0 then
        Window:Notify({
            Title = "Error",
            Content = "No recorded data to replay!",
            Duration = 3
        })
        return
    end
    
    task.spawn(function()
        local replayStart = tick()
        
        for _, call in ipairs(RecordedCalls) do
            if not IsReplaying then break end
            
            -- Wait until exact timestamp
            local targetTime = replayStart + call.Timestamp
            local waitTime = targetTime - tick()
            if waitTime > 0 then
                task.wait(waitTime)
            end
            
            -- Execute call
            pcall(function()
                if call.Type == "ChargeRod" then
                    api.Functions.ChargeRod:InvokeServer(unpack(call.Args))
                elseif call.Type == "StartMini" then
                    api.Functions.StartMini:InvokeServer(unpack(call.Args))
                elseif call.Type == "CatchFish" then
                    api.Functions.CatchFish:InvokeServer(unpack(call.Args))
                elseif call.Type == "CancelFish" then
                    api.Functions.CancelFish:InvokeServer(unpack(call.Args))
                end
                
                print(string.format("[REPLAY %.4fs] %s executed", call.Timestamp, call.Type))
            end)
        end
        
        Window:Notify({
            Title = "Replay Complete",
            Content = "Replayed " .. #RecordedCalls .. " calls",
            Duration = 3
        })
    end)
end

-- UI - Logger Tab
local RecordSection = Main:Section({
    Title = "Recording Controls"
})

RecordSection:Toggle({
    Title = "Start Recording",
    Description = "Record all fishing calls",
    Default = false,
    Callback = function(state)
        IsRecording = state
        
        if state then
            StartRecording()
            Window:Notify({
                Title = "Recording Started",
                Content = "Now go fish manually!",
                Duration = 3
            })
        else
            CalculateStats()
            Window:Notify({
                Title = "Recording Stopped",
                Content = "Recorded " .. Stats.TotalCalls .. " calls",
                Duration = 3
            })
        end
    end
})

local StatsSection = Main:Section({
    Title = "Recording Stats"
})

local TotalCallsLabel = StatsSection:Label({
    Title = "Total Calls: 0"
})

local ChargeRodLabel = StatsSection:Label({
    Title = "ChargeRod: 0"
})

local StartMiniLabel = StatsSection:Label({
    Title = "StartMini: 0"
})

local CatchFishLabel = StatsSection:Label({
    Title = "CatchFish: 0"
})

local CancelFishLabel = StatsSection:Label({
    Title = "CancelFish: 0"
})

local AvgDelayLabel = StatsSection:Label({
    Title = "Avg Delay: 0.000s"
})

local DataSection = Main:Section({
    Title = "Data Management"
})

DataSection:Button({
    Title = "Export to Console",
    Description = "Print all recorded data",
    Callback = function()
        print("========== RECORDED FISHING DATA ==========")
        print("Total Calls:", #RecordedCalls)
        print("Duration:", RecordedCalls[#RecordedCalls] and RecordedCalls[#RecordedCalls].Timestamp or 0, "seconds")
        print("\n--- Call Details ---")
        
        for i, call in ipairs(RecordedCalls) do
            print(string.format("[%d] %.4fs | %s | Args: %s", 
                i, 
                call.Timestamp, 
                call.Type, 
                table.concat(call.Args or {}, ", ")
            ))
        end
        
        print("==========================================")
        
        Window:Notify({
            Title = "Exported",
            Content = "Check console (F9)",
            Duration = 2
        })
    end
})

DataSection:Button({
    Title = "Clear Recording",
    Callback = function()
        RecordedCalls = {}
        Stats.ChargeRodCalls = 0
        Stats.StartMiniCalls = 0
        Stats.CatchCalls = 0
        Stats.CancelCalls = 0
        Stats.TotalCalls = 0
        Stats.AvgDelay = 0
        
        Window:Notify({
            Title = "Cleared",
            Content = "All recording data cleared",
            Duration = 2
        })
    end
})

-- UI - Replay Tab
local ReplaySection = Replay:Section({
    Title = "Replay Controls"
})

ReplaySection:Toggle({
    Title = "Start Replay",
    Description = "Replay recorded fishing pattern",
    Default = false,
    Callback = function(state)
        IsReplaying = state
        
        if state then
            ReplayRecording()
        end
    end
})

local ReplayInfoSection = Replay:Section({
    Title = "Replay Information"
})

local RecordedCallsLabel = ReplayInfoSection:Label({
    Title = "Recorded Calls: 0"
})

local DurationLabel = ReplayInfoSection:Label({
    Title = "Duration: 0.00s"
})

-- Update stats loop
spawn(function()
    while true do
        TotalCallsLabel:Set("Total Calls: " .. Stats.TotalCalls)
        ChargeRodLabel:Set("ChargeRod: " .. Stats.ChargeRodCalls)
        StartMiniLabel:Set("StartMini: " .. Stats.StartMiniCalls)
        CatchFishLabel:Set("CatchFish: " .. Stats.CatchCalls)
        CancelFishLabel:Set("CancelFish: " .. Stats.CancelCalls)
        AvgDelayLabel:Set(string.format("Avg Delay: %.4fs", Stats.AvgDelay))
        
        RecordedCallsLabel:Set("Recorded Calls: " .. #RecordedCalls)
        
        if #RecordedCalls > 0 then
            local duration = RecordedCalls[#RecordedCalls].Timestamp
            DurationLabel:Set(string.format("Duration: %.2fs", duration))
        else
            DurationLabel:Set("Duration: 0.00s")
        end
        
        task.wait(0.1)
    end
end)

Window:Notify({
    Title = "Fish Logger Loaded!",
    Content = "Record your fishing pattern & replay it",
    Duration = 5
})

print("🎣 Fish Logger & Replayer Loaded!")
print("1. Toggle 'Start Recording'")
print("2. Fish manually in-game")
print("3. Stop recording")
print("4. Go to Replay tab and toggle 'Start Replay'")
