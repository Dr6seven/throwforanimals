-- PREVIEW UI | Throw For Animals [BETA] by D33RZN
-- Tampilan saja. Tidak memanggil remote game.
-- (Satu-satunya file yang ditulis: ikon minimize, seperti script Bid.)
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local lp = game:GetService("Players").LocalPlayer

local ICON_URL = "https://raw.githubusercontent.com/Dr6seven/throwforanimals/refs/heads/main/icon.png"
local ICON_FILE = "tfa_icon.png"

if getgenv().TFAPreviewUI then pcall(function() getgenv().TFAPreviewUI:Destroy() end) end

local C_BG   = Color3.fromRGB(18, 18, 22)
local C_BAR  = Color3.fromRGB(26, 26, 32)
local C_ROW  = Color3.fromRGB(34, 34, 42)
local C_OFF  = Color3.fromRGB(70, 70, 82)
local C_ON   = Color3.fromRGB(60, 190, 100)
local C_RED  = Color3.fromRGB(150, 55, 55)
local C_GRAY = Color3.fromRGB(150, 150, 160)
local C_WARN = Color3.fromRGB(240, 170, 60)
local C_GOOD = Color3.fromRGB(90, 200, 120)

local function corner(inst, r) Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r) end

local conns = {}
local function track(c) conns[#conns + 1] = c; return c end

local order = 0
local function nextOrder() order += 1; return order end

-- status switch (preview)
local PS = { AutoThrow = false, AutoBuyFood = false, AutoEquipFood = false, AutoTrain = false,
    AutoBar = false, AutoSell = false, AutoEquip = false, AutoFence = false,
    HideMine = false, HideOthers = false, Invisible = false,
    AutoExec = false, AntiAfk = true }

-- ===== ROOT =====
local gui = Instance.new("ScreenGui")
gui.Name = "TFAPreviewUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
getgenv().TFAPreviewUI = gui
gui.Destroying:Connect(function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
end)

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
closeBtn.MouseButton1Click:Connect(function() dlg.Visible = true end)
noBtn.MouseButton1Click:Connect(function() dlg.Visible = false end)
yesBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

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
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - startPoint
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i == dragInput then dragging = false end
    end))
end

-- ===== IKON MINIMIZE (gambar dari icon.png, cadangan huruf "T") =====
local mini = Instance.new("ImageButton")
mini.Size = UDim2.new(0, 46, 0, 46)
mini.BackgroundColor3 = C_BAR
mini.AutoButtonColor = false
mini.Image = ""
mini.ScaleType = Enum.ScaleType.Crop
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

-- unduh gambar sekali, simpan sebagai file lokal, lalu pasang ke ikon
task.spawn(function()
    local okIcon, asset = pcall(function()
        local getAsset = getcustomasset or getsynasset
        if not (writefile and getAsset) then error("executor tidak mendukung writefile/getcustomasset") end
        local data = game:HttpGet(ICON_URL)
        writefile(ICON_FILE, data)
        return getAsset(ICON_FILE)
    end)
    if okIcon and asset and mini.Parent then
        mini.Image = asset
        miniLetter.Visible = false
    end
end)

local iconPlaced = false
minBtn.MouseButton1Click:Connect(function()
    if not iconPlaced then mini.Position = main.Position; iconPlaced = true end
    main.Visible = false
    mini.Visible = true
end)

do -- ikon bisa digeser; tap (tanpa geser) untuk membuka jendela lagi
    local dragging, moved, startPoint, startPos, dragInput
    mini.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, dragInput = true, false, i
            startPoint, startPos = i.Position, mini.Position
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if dragging and (i == dragInput or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - startPoint
            if d.Magnitude > 8 then moved = true end
            if moved then
                mini.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if dragging and i == dragInput then
            dragging = false
            if not moved then mini.Visible = false; main.Visible = true end
        end
    end))
end

-- ===== BODY: SIDEBAR + HALAMAN =====
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
tl.Padding = UDim.new(0, 3)
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
    track(RunService.Heartbeat:Connect(function()
        if not gui.Parent then return end
        frames += 1
        local now = os.clock()
        if now - t0 >= 0.5 then
            fpsLbl.Text = math.floor(frames / (now - t0)) .. " FPS"
            frames, t0 = 0, now
        end
    end))
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

local function newTab(name, ord, icon)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 28)
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.LayoutOrder = ord
    b.Parent = tabList
    corner(b, 8)
    Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 28)
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

local tabDefs = { { "Main", "🏠" }, { "Throw", "🎯" }, { "Training", "💪" },
    { "Sell", "💰" }, { "Pet", "🐾" }, { "Misc", "⚙" } }
for i, t in ipairs(tabDefs) do
    newPage(t[1])
    newTab(t[1], i, t[2])
end

-- ===== KOMPONEN =====
local sections = {}
local function section(page, keyword)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundTransparency = 1
    f.LayoutOrder = nextOrder()
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

local function groupTitle(page, text)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.new(1, 1, 1)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = nextOrder()
    l.Parent = page
    return l
end

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

local statusLbl, statsLbl, cfgStatusLbl
local function setStatus(t, color)
    if statusLbl then
        statusLbl.Text = t
        statusLbl.TextColor3 = color or C_GRAY
    end
end

local switchRefresh = {}
local function switchRow(parent, text, desc, key, onChange)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundColor3 = C_ROW
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = nextOrder()
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
        local on = PS[key]
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
    switchRefresh[key] = refresh
    row.MouseButton1Click:Connect(function()
        PS[key] = not PS[key]
        refresh(true)
        if onChange then
            onChange(PS[key])
        else
            setStatus(text .. (PS[key] and ": ON" or ": OFF") .. " (preview)", PS[key] and C_GOOD or C_GRAY)
        end
    end)
    refresh(false)
end

-- Auto Throw dan Auto Training saling mengunci (yang dinyalakan paling akhir mati)
local function exclusive(me, other, meLabel, otherLabel)
    return function(on)
        if on and PS[other] then
            PS[me] = false
            if switchRefresh[me] then switchRefresh[me](true) end
            setStatus(otherLabel .. " lagi nyala, " .. meLabel .. " dibatalkan", C_WARN)
        else
            setStatus(meLabel .. (on and ": ON" or ": OFF") .. " (preview)", on and C_GOOD or C_GRAY)
        end
    end
end

local function infoRow(parent, initial)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    row.BackgroundColor3 = C_ROW
    row.BorderSizePixel = 0
    row.LayoutOrder = nextOrder()
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

local function textBoxRow(parent, titleText, placeholder)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = C_ROW
    row.BorderSizePixel = 0
    row.LayoutOrder = nextOrder()
    row.Parent = parent
    corner(row, 8)

    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(1, -20, 0, 16)
    t.Position = UDim2.new(0, 10, 0, 6)
    t.BackgroundTransparency = 1
    t.Text = titleText
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 0, 24)
    box.Position = UDim2.new(0, 10, 0, 25)
    box.BackgroundColor3 = C_BG
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = C_GRAY
    box.Text = ""
    box.TextColor3 = Color3.new(1, 1, 1)
    box.Font = Enum.Font.Gotham
    box.TextSize = 11
    box.ClearTextOnFocus = false
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.Parent = row
    corner(box, 6)
    Instance.new("UIPadding", box).PaddingLeft = UDim.new(0, 8)
    return box
end

-- deretan tombol sejajar (khusus blok config): defs = { {teks, fungsi, warna?}, ... }
local function buttonsRow(parent, defs)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.LayoutOrder = nextOrder()
    row.Parent = parent
    local l = Instance.new("UIListLayout", row)
    l.FillDirection = Enum.FillDirection.Horizontal
    l.Padding = UDim.new(0, 6)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    local n = #defs
    local gap = (n - 1) * 6 / n
    for i, d in ipairs(defs) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1 / n, -gap, 1, 0)
        b.BackgroundColor3 = d[3] or C_ROW
        b.Text = d[1]
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.GothamBold
        b.TextSize = 11
        b.LayoutOrder = i
        b.Parent = row
        corner(b, 8)
        b.MouseButton1Click:Connect(d[2])
    end
end

-- dropdown pilih satu (tanpa teks "Select Option"); getItems() dipanggil tiap dibuka
local function makeDropdown(parent, titleText, getItems, onPick)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, 0, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = nextOrder()
    holder.Parent = parent
    local hl = Instance.new("UIListLayout", holder)
    hl.Padding = UDim.new(0, 4)
    hl.SortOrder = Enum.SortOrder.LayoutOrder

    local head = Instance.new("TextButton")
    head.Size = UDim2.new(1, 0, 0, 38)
    head.BackgroundColor3 = C_ROW
    head.Text = ""
    head.AutoButtonColor = false
    head.LayoutOrder = 1
    head.Parent = holder
    corner(head, 8)

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -40, 0, 16)
    tLbl.Position = UDim2.new(0, 10, 0, 11)
    tLbl.BackgroundTransparency = 1
    tLbl.Text = titleText
    tLbl.TextColor3 = Color3.new(1, 1, 1)
    tLbl.Font = Enum.Font.GothamBold
    tLbl.TextSize = 12
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = head

    local valueLbl = Instance.new("TextLabel")
    valueLbl.Size = UDim2.new(1, -40, 0, 14)
    valueLbl.Position = UDim2.new(0, 10, 0, 21)
    valueLbl.BackgroundTransparency = 1
    valueLbl.Text = ""
    valueLbl.Visible = false
    valueLbl.TextColor3 = C_GRAY
    valueLbl.Font = Enum.Font.Gotham
    valueLbl.TextSize = 10
    valueLbl.TextXAlignment = Enum.TextXAlignment.Left
    valueLbl.Parent = head

    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 24, 0, 20)
    arrow.Position = UDim2.new(1, -30, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = "v"
    arrow.TextColor3 = Color3.new(1, 1, 1)
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 13
    arrow.Parent = head

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1, 0, 0, 30)
    list.BackgroundColor3 = C_ROW
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 3
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.Visible = false
    list.LayoutOrder = 2
    list.Parent = holder
    corner(list, 8)
    local ll = Instance.new("UIListLayout", list)
    ll.Padding = UDim.new(0, 2)
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    local lpad = Instance.new("UIPadding", list)
    lpad.PaddingTop = UDim.new(0, 3)
    lpad.PaddingLeft = UDim.new(0, 4)
    lpad.PaddingRight = UDim.new(0, 4)

    local api = {}
    function api.setValue(text)
        if text and text ~= "" then
            valueLbl.Text = text
            valueLbl.Visible = true
            tLbl.Position = UDim2.new(0, 10, 0, 5)
        else
            valueLbl.Text = ""
            valueLbl.Visible = false
            tLbl.Position = UDim2.new(0, 10, 0, 11)
        end
    end

    local function close()
        list.Visible = false
        arrow.Text = "v"
    end

    head.MouseButton1Click:Connect(function()
        if list.Visible then close() return end
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
        end
        local items = getItems()
        if #items == 0 then
            local e = Instance.new("TextLabel")
            e.Size = UDim2.new(1, 0, 0, 24)
            e.BackgroundTransparency = 1
            e.Text = "(belum ada config)"
            e.TextColor3 = C_GRAY
            e.Font = Enum.Font.Gotham
            e.TextSize = 11
            e.Parent = list
        end
        for i, name in ipairs(items) do
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 24)
            b.BackgroundColor3 = C_BG
            b.Text = name
            b.TextColor3 = Color3.new(1, 1, 1)
            b.Font = Enum.Font.Gotham
            b.TextSize = 11
            b.LayoutOrder = i
            b.Parent = list
            corner(b, 6)
            b.MouseButton1Click:Connect(function()
                api.setValue(name)
                close()
                onPick(name)
            end)
        end
        list.Size = UDim2.new(1, 0, 0, math.clamp(#items * 26 + 8, 30, 112))
        list.Visible = true
        arrow.Text = "^"
    end)
    return api
end

-- ===== ISI HALAMAN (PREVIEW, TANPA TOMBOL MANUAL) =====
-- MAIN
do
    local p = pages.Main
    local s1 = section(p, "status")
    statusLbl = infoRow(s1, "Preview: belum terhubung ke game")

    local s2 = section(p, "statistik tap")
    statsLbl = infoRow(s2, "Tap: 0  |  Extra Reps: 0  |  ID: 0")

    local s3 = section(p, "info")
    infoRow(s3, "Auto Throw dan Auto Training tidak bisa nyala bareng. Yang dinyalakan paling akhir otomatis mati.")
end

-- THROW
do
    local p = pages.Throw
    groupTitle(p, "Throw")
    local s1 = section(p, "auto throw lempar makanan")
    switchRow(s1, "Auto Throw", "Lempar makanan otomatis (bar paling atas)", "AutoThrow",
        exclusive("AutoThrow", "AutoTrain", "Auto Throw", "Auto Training"))

    groupTitle(p, "Food")
    local s2 = section(p, "auto buy food makanan beli")
    switchRow(s2, "Auto Buy Food", "Beli makanan berikutnya otomatis kalau uang cukup", "AutoBuyFood")

    local s3 = section(p, "auto equip best food makanan")
    switchRow(s3, "Auto Equip Best Food", "Pakai makanan terbaik yang sudah dimiliki", "AutoEquipFood")
end

-- TRAINING
do
    local p = pages.Training
    groupTitle(p, "Training")
    local s1 = section(p, "auto training latihan tap bonus")
    switchRow(s1, "Auto Training", "Teleport ke lingkaran latihan kalau perlu, mulai otomatis, dan tap bonus otomatis", "AutoTrain",
        exclusive("AutoTrain", "AutoThrow", "Auto Training", "Auto Throw"))

    groupTitle(p, "Upgrade")
    local s2 = section(p, "auto upgrade bar stand")
    switchRow(s2, "Auto Upgrade Bar", "Upgrade bar latihan tiap 10 detik (uang harus cukup)", "AutoBar")
end

-- SELL
do
    local p = pages.Sell
    groupTitle(p, "Sell")
    local s1 = section(p, "auto sell jual")
    switchRow(s1, "Auto Sell", "Jual hewan kecil tiap 60 detik (hewan di kandang aman)", "AutoSell")
end

-- PET
do
    local p = pages.Pet
    groupTitle(p, "Pet")
    local s1 = section(p, "auto equip best hewan pet")
    switchRow(s1, "Auto Equip Best", "Pasang hewan terbaik otomatis tiap 30 detik", "AutoEquip")

    groupTitle(p, "Plot")
    local s2 = section(p, "auto upgrade plot kandang fence")
    switchRow(s2, "Auto Upgrade Plot", "Upgrade plot (kapasitas kandang) tiap 10 detik (uang harus cukup)", "AutoFence")
end

-- MISC: Config, Auto Load Config, Visual, Other
do
    local p = pages.Misc
    local configs = { ["Farm AFK"] = true, ["Throw Only"] = true }   -- contoh, hanya di memori
    local selected, autoName = nil, nil
    local selDD, autoTitle

    local function names()
        local list = {}
        for k in pairs(configs) do list[#list + 1] = k end
        table.sort(list)
        return list
    end

    local function cfgStatus(t, color)
        if cfgStatusLbl then
            cfgStatusLbl.Text = t
            cfgStatusLbl.TextColor3 = color or C_GRAY
        end
    end

    local function refreshAuto()
        autoTitle.Text = "Auto Load Config [" .. (autoName or "kosong") .. "]"
        autoTitle.TextColor3 = autoName and C_GOOD or Color3.new(1, 1, 1)
    end

    groupTitle(p, "Config")
    local c1 = section(p, "config name nama")
    local nameBox = textBoxRow(c1, "Config Name", "Write config name here")

    local c2 = section(p, "select config pilih")
    selDD = makeDropdown(c2, "Select Config", names, function(n)
        selected = n
        nameBox.Text = n
    end)

    local c3 = section(p, "save load delete config")
    buttonsRow(c3, {
        { "Save Config", function()
            local n = (nameBox.Text or ""):match("^%s*(.-)%s*$")
            if n == "" then n = selected end
            if not n or n == "" then
                cfgStatus("Isi nama config dulu", C_WARN)
                return
            end
            configs[n] = true
            selected = n
            selDD.setValue(n)
            nameBox.Text = n
            cfgStatus("Config '" .. n .. "' disimpan (preview)", C_GOOD)
        end },
        { "Load Config", function()
            if not selected then
                cfgStatus("Pilih config dulu", C_WARN)
                return
            end
            cfgStatus("Config '" .. selected .. "' dimuat (preview)", C_GOOD)
        end },
        { "Delete Config", function()
            if not selected then
                cfgStatus("Pilih config dulu", C_WARN)
                return
            end
            local gone = selected
            configs[gone] = nil
            if autoName == gone then autoName = nil; refreshAuto() end
            selected = nil
            selDD.setValue(nil)
            nameBox.Text = ""
            cfgStatus("Config '" .. gone .. "' dihapus (preview)", C_GRAY)
        end, C_RED },
    })

    autoTitle = groupTitle(p, "Auto Load Config [kosong]")
    local c4 = section(p, "auto load config set delete")
    buttonsRow(c4, {
        { "Set", function()
            if not selected then
                cfgStatus("Pilih config di Select Config dulu (kosong = Auto Load tidak aktif)", C_WARN)
                return
            end
            autoName = selected
            refreshAuto()
            cfgStatus("Auto Load diset ke '" .. autoName .. "' (preview)", C_GOOD)
        end },
        { "Delete", function()
            autoName = nil
            refreshAuto()
            cfgStatus("Auto Load dikosongkan (preview)", C_GRAY)
        end, C_RED },
    })

    local c5 = section(p, "status config")
    cfgStatusLbl = infoRow(c5, "Preview: tidak menulis file config dan tidak memanggil game.")

    groupTitle(p, "Visual")
    local v1 = section(p, "hide my animals sembunyikan hewan saya")
    switchRow(v1, "Hide My Animals", "Sembunyikan hewan milikmu", "HideMine")

    local v2 = section(p, "hide other people's animals sembunyikan hewan pemain lain")
    switchRow(v2, "Hide Other People's Animals", "Sembunyikan hewan milik pemain lain", "HideOthers")

    local v3 = section(p, "invisible karakter")
    switchRow(v3, "Invisible", "Sembunyikan karakter kamu", "Invisible")

    groupTitle(p, "Other")
    local o1 = section(p, "auto execute")
    switchRow(o1, "Auto Execute", "Jalankan script lagi otomatis setelah pindah server", "AutoExec")

    local o2 = section(p, "anti afk")
    switchRow(o2, "Anti AFK", "Cegah kena kick karena diam terlalu lama", "AntiAfk")
end

setTab("Misc")
