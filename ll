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
    Title = "Fish Call Logger",
    Author = "Patungin",
    Folder = "FishLogger",
    Size = UDim2.fromOffset(500, 400),
    ToggleKey = Enum.KeyCode.G,
})

local Main = Window:Tab({
    Title = "Logger",
    Icon = "file-text",
})

-- Storage
local LoggedCalls = {}
local IsLogging = false
local LastCallTime = 0
local LogStartTime = 0

-- Stats
local Stats = {
    TotalCalls = 0,
    ChargeRod = 0,
    StartMini = 0,
    CatchFish = 0,
    CancelFish = 0,
}

-- Original functions
local OriginalChargeRod = api.Functions.ChargeRod.InvokeServer
local OriginalStartMini = api.Functions.StartMini.InvokeServer
local OriginalCatchFish = api.Functions.CatchFish.InvokeServer
local OriginalCancelFish = api.Functions.CancelFish.InvokeServer

local function FormatArgs(args)
    local formatted = {}
    for i, v in ipairs(args) do
        if type(v) == "number" then
            formatted[i] = string.format("%.10f", v)
        elseif v == nil then
            formatted[i] = "nil"
        else
            formatted[i] = tostring(v)
        end
    end
    return table.concat(formatted, ", ")
end

local function StartLogging()
    LoggedCalls = {}
    LogStartTime = tick()
    LastCallTime = LogStartTime
    Stats.TotalCalls = 0
    Stats.ChargeRod = 0
    Stats.StartMini = 0
    Stats.CatchFish = 0
    Stats.CancelFish = 0
    
    -- Hook ChargeRod
    api.Functions.ChargeRod.InvokeServer = function(self, ...)
        local result = OriginalChargeRod(self, ...)
        
        if IsLogging then
            local now = tick()
            local delta = now - LastCallTime
            local timestamp = now - LogStartTime
            local args = {...}
            
            local logEntry = string.format(
                "[%.6fs] [Δ%.6fs] ChargeRod(%s)",
                timestamp,
                delta,
                FormatArgs(args)
            )
            
            table.insert(LoggedCalls, logEntry)
            print(logEntry)
            
            Stats.ChargeRod = Stats.ChargeRod + 1
            Stats.TotalCalls = Stats.TotalCalls + 1
            LastCallTime = now
        end
        
        return result
    end
    
    -- Hook StartMini
    api.Functions.StartMini.InvokeServer = function(self, ...)
        local result = OriginalStartMini(self, ...)
        
        if IsLogging then
            local now = tick()
            local delta = now - LastCallTime
            local timestamp = now - LogStartTime
            local args = {...}
            
            local logEntry = string.format(
                "[%.6fs] [Δ%.6fs] StartMini(%s)",
                timestamp,
                delta,
                FormatArgs(args)
            )
            
            table.insert(LoggedCalls, logEntry)
            print(logEntry)
            
            Stats.StartMini = Stats.StartMini + 1
            Stats.TotalCalls = Stats.TotalCalls + 1
            LastCallTime = now
        end
        
        return result
    end
    
    -- Hook CatchFish
    api.Functions.CatchFish.InvokeServer = function(self, ...)
        local result = OriginalCatchFish(self, ...)
        
        if IsLogging then
            local now = tick()
            local delta = now - LastCallTime
            local timestamp = now - LogStartTime
            local args = {...}
            
            local logEntry = string.format(
                "[%.6fs] [Δ%.6fs] CatchFish(%s)",
                timestamp,
                delta,
                FormatArgs(args)
            )
            
            table.insert(LoggedCalls, logEntry)
            print(logEntry)
            
            Stats.CatchFish = Stats.CatchFish + 1
            Stats.TotalCalls = Stats.TotalCalls + 1
            LastCallTime = now
        end
        
        return result
    end
    
    -- Hook CancelFish
    api.Functions.CancelFish.InvokeServer = function(self, ...)
        local result = OriginalCancelFish(self, ...)
        
        if IsLogging then
            local now = tick()
            local delta = now - LastCallTime
            local timestamp = now - LogStartTime
            local args = {...}
            
            local logEntry = string.format(
                "[%.6fs] [Δ%.6fs] CancelFish(%s)",
                timestamp,
                delta,
                FormatArgs(args)
            )
            
            table.insert(LoggedCalls, logEntry)
            print(logEntry)
            
            Stats.CancelFish = Stats.CancelFish + 1
            Stats.TotalCalls = Stats.TotalCalls + 1
            LastCallTime = now
        end
        
        return result
    end
end

local function ExportLog()
    if #LoggedCalls == 0 then
        print("No logged calls to export!")
        return
    end
    
    print("\n" .. string.rep("=", 80))
    print("FISHING CALL LOG - Copy everything below this line")
    print(string.rep("=", 80))
    print("Total Calls:", Stats.TotalCalls)
    print("Duration:", string.format("%.3fs", LoggedCalls[#LoggedCalls] and (tick() - LogStartTime) or 0))
    print("\nBreakdown:")
    print("  ChargeRod:", Stats.ChargeRod)
    print("  StartMini:", Stats.StartMini)
    print("  CatchFish:", Stats.CatchFish)
    print("  CancelFish:", Stats.CancelFish)
    print(string.rep("-", 80))
    
    for i, log in ipairs(LoggedCalls) do
        print(log)
    end
    
    print(string.rep("=", 80))
    print("END OF LOG")
    print(string.rep("=", 80) .. "\n")
end

local function ExportAsCode()
    if #LoggedCalls == 0 then
        print("No logged calls to export!")
        return
    end
    
    print("\n" .. string.rep("=", 80))
    print("LUA CODE - Copy everything below")
    print(string.rep("=", 80))
    print([[
-- Auto-generated fishing pattern
local function ReplayPattern()
    local api = {
        Functions = {
            ChargeRod = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/ChargeFishingRod"],
            StartMini = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/RequestFishingMinigameStarted"],
            CatchFish = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/CatchFishCompleted"],
            CancelFish = game:GetService("ReplicatedStorage").Packages._Index["sleitnick_net@0.2.0"].net["RF/CancelFishingInputs"],
        }
    }
    
    local calls = {
]])
    
    -- Parse dan export calls
    for i, log in ipairs(LoggedCalls) do
        local delta = log:match("%[Δ([%d%.]+)s%]")
        local funcName = log:match("]%s(%w+)%(")
        local args = log:match("%((.*)%)")
        
        if delta and funcName and args then
            print(string.format('        {delta = %.6f, func = "%s", args = {%s}},', tonumber(delta), funcName, args))
        end
    end
    
    print([[    }
    
    for _, call in ipairs(calls) do
        task.wait(call.delta)
        
        if call.func == "ChargeRod" then
            api.Functions.ChargeRod:InvokeServer(unpack(call.args))
        elseif call.func == "StartMini" then
            api.Functions.StartMini:InvokeServer(unpack(call.args))
        elseif call.func == "CatchFish" then
            api.Functions.CatchFish:InvokeServer(unpack(call.args))
        elseif call.func == "CancelFish" then
            api.Functions.CancelFish:InvokeServer(unpack(call.args))
        end
    end
end

-- Run the pattern
while true do
    ReplayPattern()
end
]])
    
    print(string.rep("=", 80))
    print("END OF CODE")
    print(string.rep("=", 80) .. "\n")
end

-- UI
local ControlSection = Main:Section({
    Title = "Logging Controls"
})

ControlSection:Toggle({
    Title = "Start Logging",
    Description = "Log all fishing calls with delta timing",
    Default = false,
    Callback = function(state)
        IsLogging = state
        
        if state then
            StartLogging()
            print("\n[LOGGER] Started logging fishing calls...")
            Window:Notify({
                Title = "Logging Started",
                Content = "Go fish manually! Check console (F9)",
                Duration = 3
            })
        else
            print("[LOGGER] Stopped logging")
            Window:Notify({
                Title = "Logging Stopped",
                Content = "Logged " .. Stats.TotalCalls .. " calls",
                Duration = 3
            })
        end
    end
})

local StatsSection = Main:Section({
    Title = "Statistics"
})

local TotalLabel = StatsSection:Label({
    Title = "Total Calls: 0"
})

local ChargeLabel = StatsSection:Label({
    Title = "ChargeRod: 0"
})

local MiniLabel = StatsSection:Label({
    Title = "StartMini: 0"
})

local CatchLabel = StatsSection:Label({
    Title = "CatchFish: 0"
})

local CancelLabel = StatsSection:Label({
    Title = "CancelFish: 0"
})

local ExportSection = Main:Section({
    Title = "Export Options"
})

ExportSection:Button({
    Title = "Export as Log",
    Description = "Export readable log to console",
    Callback = function()
        ExportLog()
        Window:Notify({
            Title = "Exported",
            Content = "Check console (F9) and copy the log",
            Duration = 3
        })
    end
})

ExportSection:Button({
    Title = "Export as Lua Code",
    Description = "Export as executable Lua script",
    Callback = function()
        ExportAsCode()
        Window:Notify({
            Title = "Exported",
            Content = "Check console (F9) and copy the code",
            Duration = 3
        })
    end
})

ExportSection:Button({
    Title = "Clear Log",
    Callback = function()
        LoggedCalls = {}
        Stats.TotalCalls = 0
        Stats.ChargeRod = 0
        Stats.StartMini = 0
        Stats.CatchFish = 0
        Stats.CancelFish = 0
        
        Window:Notify({
            Title = "Cleared",
            Content = "All logs cleared",
            Duration = 2
        })
    end
})

-- Update stats
spawn(function()
    while true do
        TotalLabel:Set("Total Calls: " .. Stats.TotalCalls)
        ChargeLabel:Set("ChargeRod: " .. Stats.ChargeRod)
        MiniLabel:Set("StartMini: " .. Stats.StartMini)
        CatchLabel:Set("CatchFish: " .. Stats.CatchFish)
        CancelLabel:Set("CancelFish: " .. Stats.CancelFish)
        
        task.wait(0.1)
    end
end)

Window:Notify({
    Title = "Fish Logger Loaded!",
    Content = "Record calls with delta timing",
    Duration = 5
})

print("🎣 Fish Call Logger Loaded!")
print("Press F9 to open console")
print("\nInstructions:")
print("1. Toggle 'Start Logging'")
print("2. Fish manually (1-2 cycles)")
print("3. Toggle off logging")
print("4. Click 'Export as Log' or 'Export as Lua Code'")
print("5. Copy from console")
