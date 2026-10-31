-- Throw For Animals [BETA] | by D33RZN
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer
local R = RS:WaitForChild("Remotes")

-- ===== SETTING =====
local RETRY = 3            -- jeda kalau Start ditolak
local SILENT_LIMIT = 20    -- detik tanpa bonus = cek ulang latihan
local TAP_DELAY = 0.15     -- jangan lebih dari 0.4
local TP_HEIGHT = 3.5      -- tinggi teleport di atas lingkaran
local EQUIP_EVERY = 30     -- detik, jeda Auto Equip Best
local SELL_EVERY = 60      -- detik, jeda Auto Sell (jangan di bawah 5)

-- bersihkan versi lama
getgenv().AUTO_TRAIN = false
getgenv().AUTO_TAP = false
if getgenv().__TapConn then pcall(function() getgenv().__TapConn:Disconnect() end) end
if getgenv().ThrowUI then pcall(function() getgenv().ThrowUI:Destroy() end) end
local myToken = (getgenv().__ThrowToken or 0) + 1
getgenv().__ThrowToken = myToken
task.wait(0.3)

local C_BG   = Color3.fromRGB(18, 18, 22)
local C_BAR  = Color3.fromRGB(26, 26, 32)
local C_ROW  = Color3.fromRGB(34, 34, 42)
local C_OFF  = Color3.fromRGB(70, 70, 82)
local C_ON   = Color3.fromRGB(60, 190, 100)
local C_GRAY = Color3.fromRGB(150, 150, 160)
local C_WARN = Color3.fromRGB(240, 170, 60)
local C_GOOD = Color3.fromRGB(90, 200, 120)

local State = { AutoTrain = false, AutoTap = true, AutoEquip = false, AutoSell = false }
local taps, extra, lastId = 0, 0, 0
local running = false
local lastEvent = os.clock()

local function corner(inst, r) Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r) end

-- ===== ROOT =====
local gui = Instance.new("ScreenGui")
gui.Name = "ThrowUI"
gui.ResetOnSpawn = false
local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
getgenv().ThrowUI = gui

local WIN_W, WIN_H = 430, 270
local main = Instance.new("Frame")
main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
main.Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2)
main.BackgroundColor3 = C_BG
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
corner(main, 12)
Instance.new("UIStroke", main).Color = Color3.fromRGB(60, 60, 72)

-- ===== TITLE BAR =====
local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 32)
bar.BackgroundColor3 = C_BAR
bar.BorderSizePixel = 0
bar.Parent = main

local titleBox = Instance.new("Frame")
titleBox.Size = UDim2.new(1, -220, 1, 0)
titleBox.Position = UDim2.new(0, 12, 0, 0)
titleBox.BackgroundTransparency = 1
titleBox.Parent = bar
local tbl = Instance.new("UIListLayout", titleBox)
tbl.FillDirection = Enum.FillDirection.Horizontal
tbl.VerticalAlignment = Enum.VerticalAlignment.Center
tbl.SortOrder = Enum.SortOrder.LayoutOrder
tbl.Padding = UDim.new(0, 5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(0, 0, 0, 16)
title.AutomaticSize = Enum.AutomaticSize.X
title.BackgroundTransparency = 1
title.Text = "Throw For Animals [BETA]"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.LayoutOrder = 1
title.Parent = titleBox

local credit = Instance.new("TextLabel")
credit.Size = UDim2.new(0, 0, 0, 10)
credit.AutomaticSize = Enum.AutomaticSize.X
credit.BackgroundTransparency = 1
credit.Text = "by D33RZN"
credit.TextColor3 = C_GRAY
credit.Font = Enum.Font.Gotham
credit.TextSize = 7
credit.LayoutOrder = 2
credit.Parent = titleBox

local search = Instance.new("TextBox")
search.Size = UDim2.new(0, 120, 0, 22)
search.Position = UDim2.new(1, -196, 0, 5)
search.BackgroundColor3 = C_BG
search.PlaceholderText = "Search"
search.PlaceholderColor3 = C_GRAY
search.Text = ""
search.TextColor3 = Color3.new(1, 1, 1)
search.Font = Enum.Font.Gotham
search.TextSize = 11
search.ClearTextOnFocus = false
search.Parent = bar
corner(search, 6)

local function barBtn(text, xOff, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 28, 0, 22)
    b.Position = UDim2.new(1, xOff, 0, 5)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.Parent = bar
    corner(b, 6)
    return b
end
local minBtn = barBtn("-", -64, C_OFF)
local closeBtn = barBtn("X", -32, Color3.fromRGB(200, 50, 50))

-- ===== DIALOG TUTUP =====
local dlg = Instance.new("Frame")
dlg.Size = UDim2.new(1, 0, 1, 0)
dlg.BackgroundColor3 = Color3.new(0, 0, 0)
dlg.BackgroundTransparency = 0.45
dlg.BorderSizePixel = 0
dlg.Active = true
dlg.Visible = false
dlg.ZIndex = 50
dlg.Parent = main

local dbox = Instance.new("Frame")
dbox.Size = UDim2.new(0, 270, 0, 110)
dbox.AnchorPoint = Vector2.new(0.5, 0.5)
dbox.Position = UDim2.new(0.5, 0, 0.5, 0)
dbox.BackgroundColor3 = C_ROW
dbox.BorderSizePixel = 0
dbox.ZIndex = 51
dbox.Parent = dlg
corner(dbox, 10)
Instance.new("UIStroke", dbox).Color = Color3.fromRGB(70, 70, 85)

local dtxt = Instance.new("TextLabel")
dtxt.Size = UDim2.new(1, -20, 0, 50)
dtxt.Position = UDim2.new(0, 10, 0, 10)
dtxt.BackgroundTransparency = 1
dtxt.Text = "Do you want to close this window"
dtxt.TextColor3 = Color3.new(1, 1, 1)
dtxt.Font = Enum.Font.GothamBold
dtxt.TextSize = 13
dtxt.TextWrapped = true
dtxt.ZIndex = 52
dtxt.Parent = dbox

local function dlgBtn(text, xScale, xOff, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 105, 0, 30)
    b.Position = UDim2.new(xScale, xOff, 1, -42)
    b.BackgroundColor3 = color
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 13
    b.ZIndex = 52
    b.Parent = dbox
    corner(b, 8)
    return b
end
local noBtn = dlgBtn("No", 0, 20, Color3.fromRGB(70, 70, 82))
local yesBtn = dlgBtn("Yes", 1, -125, Color3.fromRGB(200, 50, 50))

-- ===== DRAG =====
do
    local dragging, startPos, startPoint, dragInput
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragInput = true, i
            startPoint, startPos = i.Position, main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - startPoint
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i == dragInput then dragging = false end
    end)
end

-- ===== IKON MINIMIZE =====
local mini = Instance.new("ImageButton")
mini.Size = UDim2.new(0, 46, 0, 46)
mini.BackgroundColor3 = C_BAR
mini.AutoButtonColor = false
mini.Image = ""
mini.Position = UDim2.new(0, 16, 0.5, -23)
mini.Visible = false
mini.Parent = gui
corner(mini, 12)
Instance.new("UIStroke", mini).Color = Color3.fromRGB(220, 130, 30)

local miniLetter = Instance.new("TextLabel")
miniLetter.Size = UDim2.new(1, 0, 1, 0)
miniLetter.BackgroundTransparency = 1
miniLetter.Text = "T"
miniLetter.TextColor3 = Color3.new(1, 1, 1)
miniLetter.Font = Enum.Font.GothamBold
miniLetter.TextSize = 22
miniLetter.Parent = mini

local iconPlaced = false
minBtn.MouseButton1Click:Connect(function()
    if not iconPlaced then mini.Position = main.Position; iconPlaced = true end
    main.Visible = false
    mini.Visible = true
end)

do
    local dragging, moved, startPoint, startPos, dragInput
    mini.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, dragInput = true, false, i
            startPoint, startPos = i.Position, mini.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - startPoint
            if d.Magnitude > 8 then moved = true end
            if moved then
                mini.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if dragging and i == dragInput then
            dragging = false
            if not moved then mini.Visible = false; main.Visible = true end
        end
    end)
end

-- ===== BODY =====
local body = Instance.new("Frame")
body.Size = UDim2.new(1, 0, 1, -32)
body.Position = UDim2.new(0, 0, 0, 32)
body.BackgroundTransparency = 1
body.Parent = main

local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 96, 1, 0)
sidebar.BackgroundColor3 = C_BAR
sidebar.BorderSizePixel = 0
sidebar.Parent = body

local tabList = Instance.new("Frame")
tabList.Size = UDim2.new(1, 0, 1, -30)
tabList.BackgroundTransparency = 1
tabList.Parent = sidebar
local tl = Instance.new("UIListLayout", tabList)
tl.Padding = UDim.new(0, 4)
tl.SortOrder = Enum.SortOrder.LayoutOrder
local tp = Instance.new("UIPadding", tabList)
tp.PaddingTop = UDim.new(0, 8)
tp.PaddingLeft = UDim.new(0, 6)
tp.PaddingRight = UDim.new(0, 6)

local fpsLbl = Instance.new("TextLabel")
fpsLbl.Size = UDim2.new(1, -12, 0, 16)
fpsLbl.Position = UDim2.new(0, 6, 1, -22)
fpsLbl.BackgroundTransparency = 1
fpsLbl.Text = "-- FPS"
fpsLbl.TextColor3 = C_GRAY
fpsLbl.Font = Enum.Font.Gotham
fpsLbl.TextSize = 10
fpsLbl.TextXAlignment = Enum.TextXAlignment.Left
fpsLbl.Parent = sidebar
do
    local frames, t0 = 0, os.clock()
    RunService.Heartbeat:Connect(function()
        if not gui.Parent then return end
        frames += 1
        local now = os.clock()
        if now - t0 >= 0.5 then
            fpsLbl.Text = math.floor(frames / (now - t0)) .. " FPS"
            frames, t0 = 0, now
        end
    end)
end

local pages, tabs = {}, {}
local function newPage(name)
    local p = Instance.new("ScrollingFrame")
    p.Size = UDim2.new(1, -96, 1, 0)
    p.Position = UDim2.new(0, 96, 0, 0)
    p.BackgroundTransparency = 1
    p.BorderSizePixel = 0
    p.ScrollBarThickness = 4
    p.AutomaticCanvasSize = Enum.AutomaticSize.Y
    p.CanvasSize = UDim2.new(0, 0, 0, 0)
    p.Visible = false
    p.Parent = body
    local l = Instance.new("UIListLayout", p)
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", p)
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pages[name] = p
    return p
end

local function setTab(name)
    for n, p in pairs(pages) do p.Visible = (n == name) end
    for n, b in pairs(tabs) do
        b.BackgroundColor3 = (n == name) and C_ROW or C_BAR
        b.TextColor3 = (n == name) and Color3.new(1, 1, 1) or C_GRAY
    end
end

local function newTab(name, order, icon)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 30)
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.LayoutOrder = order
    b.Parent = tabList
    corner(b, 8)
    Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 32)
    local ic = Instance.new("TextLabel")
    ic.Size = UDim2.new(0, 24, 1, 0)
    ic.Position = UDim2.new(0, -26, 0, 0)
    ic.BackgroundTransparency = 1
    ic.Text = icon
    ic.TextSize = 15
    ic.Font = Enum.Font.GothamBold
    ic.TextColor3 = Color3.new(1, 1, 1)
    ic.Parent = b
    tabs[name] = b
    b.MouseButton1Click:Connect(function() setTab(name) end)
end

local mainPage = newPage("Main")
local miscPage = newPage("Misc")
newTab("Main", 1, "🏠")
newTab("Misc", 2, "⚙")

-- ===== KOMPONEN =====
local sections = {}
local function section(page, keyword)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1
    f.LayoutOrder = #sections + 1
    f.Parent = page
    local l = Instance.new("UIListLayout", f)
    l.Padding = UDim.new(0, 4)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    sections[#sections + 1] = { f, keyword:lower() }
    return f
end

search:GetPropertyChangedSignal("Text"):Connect(function()
    local q = search.Text:lower()
    for _, s in ipairs(sections) do
        s[1].Visible = (q == "") or (s[2]:find(q, 1, true) ~= nil)
    end
end)

local function textBlock(parent, titleText, desc, widthOffset)
    local txt = Instance.new("Frame")
    txt.Size = UDim2.new(1, widthOffset, 0, 0)
    txt.AutomaticSize = Enum.AutomaticSize.Y
    txt.BackgroundTransparency = 1
    txt.Position = UDim2.new(0, 10, 0, 0)
    txt.Parent = parent
    local l = Instance.new("UIListLayout", txt)
    l.Padding = UDim.new(0, 2)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    local pad = Instance.new("UIPadding", txt)
    pad.PaddingTop = UDim.new(0, 7)
    pad.PaddingBottom = UDim.new(0, 7)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, 0, 0, 16)
    t.BackgroundTransparency = 1
    t.Text = titleText
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.LayoutOrder = 1
    t.Parent = txt

    if desc then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(1, 0, 0, 0)
        d.AutomaticSize = Enum.AutomaticSize.Y
        d.BackgroundTransparency = 1
        d.Text = desc
        d.TextColor3 = C_GRAY
        d.Font = Enum.Font.Gotham
        d.TextSize = 10
        d.TextWrapped = true
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.TextYAlignment = Enum.TextYAlignment.Top
        d.LayoutOrder = 2
        d.Parent = txt
    end
end

local statusLbl, statsLbl
local function setStatus(t, color)
    if statusLbl and statusLbl.Parent then
        statusLbl.Text = t
        statusLbl.TextColor3 = color or C_GRAY
    end
end
local function updateStats()
    if statsLbl and statsLbl.Parent then
        statsLbl.Text = "Tap: " .. taps .. "  |  Extra Reps: " .. extra .. "  |  ID: " .. lastId
    end
end

local function switchRow(parent, text, desc, key, onChange)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundColor3 = C_ROW
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = 1
    row.Parent = parent
    corner(row, 8)
    Instance.new("UISizeConstraint", row).MinSize = Vector2.new(0, 38)
    textBlock(row, text, desc, -64)

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 20)
    pill.Position = UDim2.new(1, -50, 0.5, -10)
    pill.Parent = row
    corner(pill, 10)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Parent = pill
    corner(knob, 8)

    local function refresh(animate)
        local on = State[key]
        local col = on and C_ON or C_OFF
        local pos = on and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
        if animate then
            local info = TweenInfo.new(0.15)
            TS:Create(pill, info, { BackgroundColor3 = col }):Play()
            TS:Create(knob, info, { Position = pos }):Play()
        else
            pill.BackgroundColor3 = col
            knob.Position = pos
        end
    end
    row.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        refresh(true)
        if onChange then onChange(State[key]) end
    end)
    refresh(false)
end

local function buttonRow(parent, text, desc, cb)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundColor3 = C_ROW
    row.Text = ""
    row.AutoButtonColor = true
    row.LayoutOrder = 1
    row.Parent = parent
    corner(row, 8)
    Instance.new("UISizeConstraint", row).MinSize = Vector2.new(0, 38)
    textBlock(row, text, desc, -20)
    row.MouseButton1Click:Connect(cb)
end

local function infoRow(parent, initial)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundColor3 = C_ROW
    row.LayoutOrder = 1
    row.Parent = parent
    corner(row, 8)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 0)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = initial
    lbl.TextColor3 = C_GRAY
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextYAlignment = Enum.TextYAlignment.Top
    lbl.Parent = row
    Instance.new("UIPadding", lbl).PaddingTop = UDim.new(0, 8)
    Instance.new("UIPadding", row).PaddingBottom = UDim.new(0, 8)
    return lbl
end

-- ===== LOGIKA =====
local function getHRP()
    return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
end

-- lingkaran latihan ada di plot milik sendiri (posisinya beda tiap server)
local function getTrainSpot()
    local props = workspace:FindFirstChild("LocalPlotProps")
    local area = props and props:FindFirstChild("TrainingArea")
    return area and area:FindFirstChild("TrainingSpot")
end

local function tpToTraining()
    local spot = getTrainSpot()
    local h = getHRP()
    if not (spot and h) then return false end
    h.CFrame = CFrame.new(spot.Position + Vector3.new(0, TP_HEIGHT, 0))
    return true
end

local function alive()
    return State.AutoTrain and getgenv().__ThrowToken == myToken
end

-- Auto Tap Bonus (event dari server membawa ID bonus)
local function pickValue(args)
    for _, a in ipairs(args) do
        if typeof(a) == "number" then return a end
    end
    return nil
end

getgenv().__TapConn = R.Training_Bonus.OnClientEvent:Connect(function(...)
    lastEvent = os.clock()
    if not State.AutoTap then return end
    local id = pickValue({ ... })
    if not id then return end
    task.spawn(function()
        task.wait(TAP_DELAY)
        local okT, res = pcall(function() return R.Training_TapBonus:InvokeServer(id) end)
        if okT and typeof(res) == "table" and res.Ok then
            taps += 1
            extra += tonumber(res.ExtraReps) or 0
            lastId = id
            updateStats()
        end
    end)
end)

-- Auto Training (Start, teleport kalau TooFar, Busy = sudah latihan)
local function trainLoop()
    running = true
    local started = false
    while alive() do
        if started and os.clock() - lastEvent > SILENT_LIMIT then
            started = false
            setStatus("Bonus berhenti, cek ulang latihan...", C_WARN)
        end

        if not started then
            local okS, res = pcall(function() return R.Training_Start:InvokeServer() end)
            local reason = (okS and typeof(res) == "table" and res.Ok == false) and tostring(res.Reason) or nil

            if not okS then
                setStatus("Start error", C_WARN)
                task.wait(RETRY)
            elseif reason == "Busy" then
                started = true
                lastEvent = os.clock()
                setStatus("Latihan sudah aktif (Busy)", C_GOOD)
            elseif reason == "TooFar" then
                if tpToTraining() then
                    setStatus("Teleport ke lingkaran latihan...", C_GRAY)
                    task.wait(0.6)
                else
                    setStatus("Lingkaran latihan tidak ditemukan", C_WARN)
                    task.wait(RETRY)
                end
            elseif reason then
                setStatus("Start ditolak: " .. reason, C_WARN)
                task.wait(RETRY)
            else
                started = true
                lastEvent = os.clock()
                setStatus("Latihan berjalan", C_GOOD)
            end
        end
        task.wait(1)
    end
    running = false
end

local function stopTraining()
    pcall(function() R.Training_Stop:InvokeServer() end)
end

local function setTrain(on)
    if on then
        if running then return end
        task.spawn(trainLoop)
    else
        setStatus("Menghentikan latihan...", C_GRAY)
        task.spawn(function()
            local t0 = os.clock()
            while running and os.clock() - t0 < 5 do task.wait(0.1) end
            stopTraining()
            setStatus("Latihan berhenti", C_GRAY)
        end)
    end
end

-- Auto Equip Best dan Auto Sell (tanpa argumen, diulang tiap beberapa detik)
local loops = {}

local function summarize(res)
    if typeof(res) ~= "table" then return tostring(res) end
    local p = {}
    for k, v in pairs(res) do p[#p + 1] = tostring(k) .. "=" .. tostring(v) end
    local s = table.concat(p, ", ")
    return #s > 90 and s:sub(1, 90) .. "..." or s
end

local function callOnce(remoteName, label)
    local okC, res = pcall(function() return R[remoteName]:InvokeServer() end)
    if not okC then
        setStatus(label .. ": error", C_WARN)
    elseif typeof(res) == "table" and res.Ok == false then
        setStatus(label .. ": " .. tostring(res.Reason), C_WARN)
    else
        setStatus(label .. ": " .. summarize(res), C_GOOD)
    end
end

local function startLoop(key, remoteName, interval, label)
    if loops[key] then return end
    loops[key] = true
    task.spawn(function()
        while State[key] and getgenv().__ThrowToken == myToken do
            callOnce(remoteName, label)
            local t0 = os.clock()
            while State[key] and getgenv().__ThrowToken == myToken and os.clock() - t0 < interval do
                task.wait(0.5)
            end
        end
        loops[key] = false
    end)
end

-- ===== ISI HALAMAN =====
local s1 = section(mainPage, "auto training latihan")
switchRow(s1, "Auto Training", "Teleport ke lingkaran latihan kalau perlu, mulai otomatis, dan cek ulang kalau berhenti", "AutoTrain", setTrain)

local s2 = section(mainPage, "auto tap bonus")
switchRow(s2, "Auto Tap Bonus", "Tap bonus latihan otomatis (nyala sendiri, bisa dipakai bareng latihan manual)", "AutoTap")

local s5 = section(mainPage, "auto equip best hewan")
switchRow(s5, "Auto Equip Best", "Pasang hewan terbaik otomatis tiap 30 detik", "AutoEquip", function(on)
    if on then startLoop("AutoEquip", "Plot_EquipBest", EQUIP_EVERY, "Equip Best") end
end)

local s6 = section(mainPage, "auto sell jual")
switchRow(s6, "Auto Sell", "Jual hewan kecil tiap 60 detik (hewan di kandang aman)", "AutoSell", function(on)
    if on then startLoop("AutoSell", "Plot_SellAll", SELL_EVERY, "Sell All") end
end)

local s3 = section(mainPage, "statistik tap")
statsLbl = infoRow(s3, "Tap: 0  |  Extra Reps: 0  |  ID: 0")
local s4 = section(mainPage, "status")
statusLbl = infoRow(s4, "Siap")

local m1 = section(miscPage, "teleport lingkaran latihan")
buttonRow(m1, "Teleport ke Lingkaran", "Pindah ke lingkaran latihan sekarang", function()
    if tpToTraining() then
        setStatus("Teleport ke lingkaran latihan", C_GOOD)
    else
        setStatus("Lingkaran latihan tidak ditemukan", C_WARN)
    end
end)

local m4 = section(miscPage, "equip best sekarang")
buttonRow(m4, "Equip Best Sekarang", "Pasang hewan terbaik sekali", function()
    task.spawn(callOnce, "Plot_EquipBest", "Equip Best")
end)

local m5 = section(miscPage, "sell all sekarang jual")
buttonRow(m5, "Sell All Sekarang", "Jual hewan kecil sekali", function()
    task.spawn(callOnce, "Plot_SellAll", "Sell All")
end)

local m2 = section(miscPage, "stop latihan")
buttonRow(m2, "Stop Latihan", "Panggil Training_Stop sekarang (matikan Auto Training dulu)", function()
    stopTraining()
    setStatus("Training_Stop dikirim", C_GOOD)
end)

local m3 = section(miscPage, "reset statistik")
buttonRow(m3, "Reset Statistik", "Nolkan hitungan tap", function()
    taps, extra, lastId = 0, 0, 0
    updateStats()
end)

-- ===== TUTUP =====
closeBtn.MouseButton1Click:Connect(function() dlg.Visible = true end)
noBtn.MouseButton1Click:Connect(function() dlg.Visible = false end)
yesBtn.MouseButton1Click:Connect(function()
    local was = State.AutoTrain
    State.AutoTrain = false
    State.AutoTap = false
    State.AutoEquip = false
    State.AutoSell = false
    getgenv().__ThrowToken = (getgenv().__ThrowToken or 0) + 1
    if getgenv().__TapConn then pcall(function() getgenv().__TapConn:Disconnect() end) end
    if was then task.spawn(function() task.wait(1.2); stopTraining() end) end
    gui:Destroy()
end)

setTab("Main")
