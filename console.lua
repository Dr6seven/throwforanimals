-- Console buatan (otomatis dibuat kalau belum ada)
if not getgenv().Log then
    local UIS = game:GetService("UserInputService")
    local g = Instance.new("ScreenGui")
    g.Name = "MyConsole"
    g.ResetOnSpawn = false
    g.DisplayOrder = 999
    g.Parent = (gethui and gethui()) or game:GetService("CoreGui")
    getgenv().__CON = g

    local f = Instance.new("Frame", g)
    f.Size = UDim2.new(0, 340, 0, 220)
    f.Position = UDim2.new(0.5, -170, 0.5, -110)
    f.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
    f.BorderSizePixel = 0

    local top = Instance.new("TextLabel", f)
    top.Size = UDim2.new(1, -110, 0, 26)
    top.BackgroundColor3 = Color3.fromRGB(40, 40, 62)
    top.BorderSizePixel = 0
    top.Text = "  Console (geser di sini)"
    top.TextColor3 = Color3.new(1, 1, 1)
    top.Font = Enum.Font.GothamBold
    top.TextSize = 12
    top.TextXAlignment = Enum.TextXAlignment.Left

    local function btn(t, x)
        local b = Instance.new("TextButton", f)
        b.Size = UDim2.new(0, 34, 0, 26)
        b.Position = UDim2.new(1, x, 0, 0)
        b.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
        b.BorderSizePixel = 0
        b.Text = t
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        return b
    end
    local bX = btn("X", -34)
    local bClr = btn("Clr", -68)
    local bCp = btn("Cp", -102)

    local sc = Instance.new("ScrollingFrame", f)
    sc.Position = UDim2.new(0, 4, 0, 30)
    sc.Size = UDim2.new(1, -8, 1, -34)
    sc.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
    sc.BorderSizePixel = 0
    sc.ScrollBarThickness = 5
    sc.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sc.CanvasSize = UDim2.new(0, 0, 0, 0)

    local lb = Instance.new("TextLabel", sc)
    lb.Size = UDim2.new(1, -8, 0, 0)
    lb.AutomaticSize = Enum.AutomaticSize.Y
    lb.Position = UDim2.new(0, 4, 0, 0)
    lb.BackgroundTransparency = 1
    lb.Text = ""
    lb.TextColor3 = Color3.fromRGB(200, 255, 200)
    lb.TextSize = 12
    lb.Font = Enum.Font.Code
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.TextYAlignment = Enum.TextYAlignment.Top
    lb.TextWrapped = true

    local buf = ""
    getgenv().Log = function(...)
        local p = {}
        for i, v in ipairs({ ... }) do p[i] = tostring(v) end
        buf = buf .. table.concat(p, " ") .. "\n"
        if #buf > 30000 then buf = buf:sub(-30000) end
        lb.Text = buf
        task.defer(function() sc.CanvasPosition = Vector2.new(0, 1e6) end)
    end
    getgenv().LogDump = function(t, ind, d)
        ind = ind or ""
        d = d or 0
        if d > 2 then return end
        for k, v in pairs(t) do
            if typeof(v) == "table" then
                getgenv().Log(ind .. tostring(k) .. " = {")
                getgenv().LogDump(v, ind .. "  ", d + 1)
                getgenv().Log(ind .. "}")
            else
                getgenv().Log(ind .. tostring(k) .. " = " .. tostring(v))
            end
        end
    end

    bClr.MouseButton1Click:Connect(function() buf = ""; lb.Text = "" end)
    bX.MouseButton1Click:Connect(function() g:Destroy(); getgenv().Log = nil end)
    bCp.MouseButton1Click:Connect(function() if setclipboard then setclipboard(buf) end end)

    local drag, ds, sp
    top.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag, ds, sp = true, i.Position, f.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
end

local Log, LogDump = getgenv().Log, getgenv().LogDump
local R = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")

-- Auto Tap Bonus
getgenv().AUTO_TAP = true
if getgenv().__TapConn then pcall(function() getgenv().__TapConn:Disconnect() end) end

local KEYS = { "Id", "ID", "Index", "Slot", "Lane", "Button", "Bonus", "Type", "Position", "Pos", "Number", "Value" }

local function pickValue(args)
    for _, a in ipairs(args) do
        if typeof(a) == "number" then return a end
        if typeof(a) == "table" then
            for _, k in ipairs(KEYS) do
                if typeof(a[k]) == "number" then return a[k] end
            end
            for _, v in pairs(a) do
                if typeof(v) == "number" then return v end
            end
        end
    end
    return nil
end

getgenv().__TapConn = R.Training_Bonus.OnClientEvent:Connect(function(...)
    local args = { ... }
    Log("[EVENT] Training_Bonus")
    for i, v in ipairs(args) do
        if typeof(v) == "table" then
            Log(" arg" .. i .. " = table")
            LogDump(v, "   ")
        else
            Log(" arg" .. i .. " =", tostring(v))
        end
    end

    if not getgenv().AUTO_TAP then return end
    local val = pickValue(args)
    if val == nil then
        Log("tidak ada angka di event, tap dilewati")
        return
    end

    task.spawn(function()
        task.wait(0.15)
        local ok, res = pcall(function() return R.Training_TapBonus:InvokeServer(val) end)
        Log("[TAP]", val, "ok:", ok, typeof(res))
        if typeof(res) == "table" then LogDump(res) end
    end)
end)

Log("Auto tap bonus aktif, mulai latihan manual")
-- berhenti: getgenv().AUTO_TAP = false
