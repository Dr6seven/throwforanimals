-- Throw For Animals [BETA] | by D33RZN
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local lp = Players.LocalPlayer
local R = RS:WaitForChild("Remotes")

-- ===== SETTING =====
local SCRIPT_URL = "https://raw.githubusercontent.com/Dr6seven/throwforanimals/refs/heads/main/throw.lua"
local ICON_URL = "https://raw.githubusercontent.com/Dr6seven/throwforanimals/refs/heads/main/icon.png"
local ICON_FILE = "tfa_icon.png"
local CONFIG_FILE = "ThrowForAnimals_configs.json"
local LASTSTATE_FILE = "ThrowForAnimals_laststate.json"

-- penghitung Total User (layanan gratis dari luar; ganti NS dan SALT)
local COUNTER_BASE = "https://abacus.jasoncameron.dev"
local COUNTER_NS = "throwforanimals-d33rzn"
local COUNTER_KEY = "users"
local SALT = "ganti-teks-acak-ini"
local REG_FILE = "tfa_registered.txt"

local RETRY = 3            -- jeda kalau Start latihan ditolak
local SILENT_LIMIT = 20    -- detik tanpa bonus = cek ulang latihan
local TAP_DELAY = 0.15     -- jangan lebih dari 0.4
local TP_HEIGHT = 3.5      -- tinggi teleport di atas lingkaran latihan
local LINE_HEIGHT = 3      -- tinggi teleport di atas garis lempar
local EQUIP_EVERY = 30     -- detik, jeda Auto Equip Best (pet)
local SELL_EVERY = 60      -- detik, jeda Auto Sell (jangan di bawah 5)
local UPGRADE_EVERY = 10   -- detik, jeda Auto Upgrade (bar dan plot)
local FOOD_EVERY = 15      -- detik, jeda Auto Buy dan Equip Food
local FOOD_MAX = 120       -- batas atas indeks makanan
local THROW_ACCURACY = 1   -- 1 = bar lempar paling atas
local THROW_EXTRA = 0.3    -- tambahan setelah waktu terbang

-- switch yang ikut disimpan di config dan status terakhir
local CONFIG_KEYS = { "AutoTrain", "AutoThrow", "AutoBuyFood", "AutoEquipFood", "AutoBar",
    "AutoSell", "AutoEquip", "AutoFence", "HideMine", "HideOthers", "Invisible", "AutoExec", "AntiAfk" }

-- ===== BERSIHKAN VERSI LAMA =====
if getgenv().TFAVisual then pcall(getgenv().TFAVisual.stop) end
getgenv().THROW_POS = nil
if getgenv().__TapConn then pcall(function() getgenv().__TapConn:Disconnect() end) end
if getgenv().__ThrowConns then
    for _, c in ipairs(getgenv().__ThrowConns) do pcall(function() c:Disconnect() end) end
end
getgenv().__ThrowConns = {}
local conns = getgenv().__ThrowConns
local function track(c) conns[#conns + 1] = c; return c end
if getgenv().ThrowUI then pcall(function() getgenv().ThrowUI:Destroy() end) end
local myToken = (getgenv().__ThrowToken or 0) + 1
getgenv().__ThrowToken = myToken
task.wait(0.3)

local C_BG   = Color3.fromRGB(18, 18, 22)
local C_BAR  = Color3.fromRGB(26, 26, 32)
local C_ROW  = Color3.fromRGB(34, 34, 42)
local C_OFF  = Color3.fromRGB(70, 70, 82)
local C_ON   = Color3.fromRGB(60, 190, 100)
local C_RED  = Color3.fromRGB(150, 55, 55)
local C_GRAY = Color3.fromRGB(150, 150, 160)
local C_WARN = Color3.fromRGB(240, 170, 60)
local C_GOOD = Color3.fromRGB(90, 200, 120)

local State = { AutoTrain = false, AutoThrow = false, AutoBuyFood = false, AutoEquipFood = false,
    AutoBar = false, AutoSell = false, AutoEquip = false, AutoFence = false,
    HideMine = false, HideOthers = false, Invisible = false, AutoExec = false, AntiAfk = true }

local taps, extra, lastId = 0, 0, 0
local running = false
local throwing = false
local throws = 0
local lastEvent = os.clock()

local function corner(inst, r) Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r) end
local order = 0
local function nextOrder() order += 1; return order end

-- ===== FILE CONFIG =====
local function fsOk() return writefile and readfile and isfile end

local cfgData = { configs = {}, autoload = nil }
local function readCfgFile()
    if not (fsOk() and isfile(CONFIG_FILE)) then return end
    local okR, data = pcall(function() return HttpService:JSONDecode(readfile(CONFIG_FILE)) end)
    if okR and typeof(data) == "table" and typeof(data.configs) == "table" then
        cfgData.configs = data.configs
        cfgData.autoload = (typeof(data.autoload) == "string" and data.autoload ~= "") and data.autoload or nil
    end
end
local function writeCfgFile()
    if not fsOk() then return false end
    return pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode({ configs = cfgData.configs, autoload = cfgData.autoload or "" }))
    end)
end
readCfgFile()

-- ===== TOTAL USER (penghitung akun unik) =====
local function userKey()
    local h1, h2 = 5381, 52711
    for c in (SALT .. tostring(lp.UserId)):gmatch(".") do
        h1 = (h1 * 33 + c:byte()) % 4294967296
        h2 = (h2 * 31 + c:byte()) % 4294967296
    end
    return string.format("u%08x%08x", h1, h2)
end

local function counterCall(path)
    local okH, body = pcall(function() return game:HttpGet(COUNTER_BASE .. path) end)
    if not okH then return nil end
    local okJ, data = pcall(function() return HttpService:JSONDecode(body) end)
    if okJ and typeof(data) == "table" then
        local v = tonumber(data.value) or tonumber(data.count) or tonumber(data.Count)
        if v then return v end
    end
    return tonumber(body)
end

-- akun baru (pertama kali) menambah total sekali; selalu mengembalikan total terbaru
local function fetchTotalUsers()
    local registered = isfile and isfile(REG_FILE)
    if not registered then
        local v = counterCall("/hit/" .. COUNTER_NS .. "/" .. userKey())
        if v == 1 then counterCall("/hit/" .. COUNTER_NS .. "/" .. COUNTER_KEY) end
        if v and writefile then pcall(writefile, REG_FILE, "1") end
    end
    return counterCall("/get/" .. COUNTER_NS .. "/" .. COUNTER_KEY)
end

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

-- ===== IKON MINIMIZE (icon.png, cadangan huruf "T") =====
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

do
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

local statusLbl, statsLbl, usersLbl, cfgStatusLbl
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

local switchRefresh = {}
local switchHandlers = {}

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
    switchRefresh[key] = refresh
    switchHandlers[key] = onChange
    row.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        refresh(true)
        if onChange then onChange(State[key]) end
    end)
    refresh(false)
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

-- dropdown pilih satu; getItems() dipanggil tiap dibuka
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

-- ===== LOGIKA UMUM =====
local function getHRP()
    return lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
end

-- matikan switch dari kode (switch ikut geser ke OFF)
local function forceOff(key)
    State[key] = false
    if switchRefresh[key] then switchRefresh[key](true) end
end

-- ubah satu switch dari kode (visual ikut berubah, handler dipanggil)
local function applyState(key, value)
    if State[key] == nil or State[key] == value then return end
    State[key] = value
    if switchRefresh[key] then switchRefresh[key](false) end
    if switchHandlers[key] then switchHandlers[key](value) end
end

local function restoreLook()
    pcall(function() R.Throw_Cancel:InvokeServer() end)
    local char = lp.Character
    if char then
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                if v.Name ~= "HumanoidRootPart" then v.Transparency = 0 end
                v.LocalTransparencyModifier = 0
            elseif v:IsA("Decal") then
                v.Transparency = 0
            end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then workspace.CurrentCamera.CameraSubject = hum end
    end
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

-- ===== TRAINING (+ TAP BONUS) =====
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

-- tap bonus nempel ke Auto Training: event dari server membawa ID bonus
getgenv().__TapConn = R.Training_Bonus.OnClientEvent:Connect(function(...)
    lastEvent = os.clock()
    if not State.AutoTrain then return end
    local id
    for _, a in ipairs({ ... }) do
        if typeof(a) == "number" then id = a; break end
    end
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
        if State.AutoThrow then
            forceOff("AutoTrain")
            setStatus("Auto Throw lagi nyala, Auto Training dibatalkan", C_WARN)
            return
        end
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

-- ===== LOOP UMUM (Equip Best, Sell, Upgrade) =====
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

local function startFnLoop(key, interval, fn)
    if loops[key] then return end
    loops[key] = true
    task.spawn(function()
        while State[key] and getgenv().__ThrowToken == myToken do
            local okF, err = pcall(fn)
            if not okF then setStatus("Error: " .. tostring(err), C_WARN) end
            local t0 = os.clock()
            while State[key] and getgenv().__ThrowToken == myToken and os.clock() - t0 < interval do
                task.wait(0.5)
            end
        end
        loops[key] = false
    end)
end

local function startLoop(key, remoteName, interval, label)
    startFnLoop(key, interval, function() callOnce(remoteName, label) end)
end

-- upgrade bar stand (kalau TooFar, teleport ke lingkaran latihan, kecuali Auto Throw nyala)
local function upgradeBar()
    local okC, res = pcall(function() return R.Stand_Upgrade:InvokeServer() end)
    if okC and typeof(res) == "table" and res.Ok == false and tostring(res.Reason) == "TooFar" then
        if not State.AutoThrow and tpToTraining() then
            task.wait(0.6)
            okC, res = pcall(function() return R.Stand_Upgrade:InvokeServer() end)
        end
    end
    if not okC then
        setStatus("Upgrade Bar: error", C_WARN)
    elseif typeof(res) == "table" and res.Ok == false then
        setStatus("Upgrade Bar: " .. tostring(res.Reason), C_WARN)
    else
        setStatus("Upgrade Bar: " .. summarize(res), C_GOOD)
    end
end

-- ===== MAKANAN (indeks lebih tinggi dianggap lebih baik) =====
local foodNext = 1       -- indeks berikutnya yang dicoba dibeli
local foodBest = 0       -- indeks makanan terbaik yang sudah dimiliki
local foodEquipped = 0

local function buyFood()
    for _ = 1, 80 do
        if not State.AutoBuyFood then return end
        if foodNext > FOOD_MAX then
            setStatus("Buy Food: sudah mencapai batas indeks", C_GRAY)
            return
        end
        local okB, res = pcall(function() return R.Shop_Buy:InvokeServer(foodNext) end)
        if not okB then
            setStatus("Buy Food: error", C_WARN)
            return
        end
        local reason = (typeof(res) == "table" and res.Ok == false) and tostring(res.Reason):lower() or nil
        if not reason then
            foodBest = math.max(foodBest, foodNext)
            setStatus("Beli makanan #" .. foodNext .. " berhasil", C_GOOD)
            foodNext += 1
            task.wait(0.3)
        elseif reason:find("owned") or reason:find("already") or reason:find("bought") then
            foodBest = math.max(foodBest, foodNext)
            foodNext += 1
            task.wait(0.15)
        else
            setStatus("Buy Food #" .. foodNext .. ": " .. reason, C_WARN)
            return
        end
    end
end

local function equipBestFood()
    -- belum tahu makanan terbaik: coba dari atas, yang pertama berhasil di-equip = terbaik yang dimiliki
    if foodBest <= 0 then
        for i = FOOD_MAX, 1, -1 do
            if not State.AutoEquipFood then return end
            local okE, res = pcall(function() return R.Shop_Equip:InvokeServer(i) end)
            local reason = (okE and typeof(res) == "table" and res.Ok == false) and tostring(res.Reason):lower() or nil
            if okE and (not reason or reason:find("already")) then
                foodBest = i
                foodEquipped = i
                setStatus("Makanan terbaik #" .. i .. " dipakai", C_GOOD)
                return
            end
            task.wait(0.08)
        end
        setStatus("Equip Food: tidak ada makanan yang bisa di-equip", C_WARN)
        return
    end

    if foodBest == foodEquipped then return end
    local okE, res = pcall(function() return R.Shop_Equip:InvokeServer(foodBest) end)
    if okE and not (typeof(res) == "table" and res.Ok == false) then
        foodEquipped = foodBest
        setStatus("Equip makanan #" .. foodBest, C_GOOD)
    else
        setStatus("Equip Food #" .. foodBest .. ": " .. summarize(res), C_WARN)
    end
end

-- ===== AUTO THROW =====
-- garis lempar global: Workspace.StarterArea.CrossLine
local function getThrowLine()
    local area = workspace:FindFirstChild("StarterArea")
    return area and area:FindFirstChild("CrossLine")
end

local function tpToThrow(useSaved)
    local h = getHRP()
    if not h then return false end
    local saved = getgenv().THROW_POS

    if useSaved and saved then
        h.CFrame = CFrame.new(saved + Vector3.new(0, 0.5, 0))
        return true
    end

    local line = getThrowLine()
    if line and line:IsA("BasePart") then
        local p = line.Position
        h.CFrame = CFrame.new(p.X, p.Y + LINE_HEIGHT, p.Z)
        return true
    end

    if saved then
        h.CFrame = CFrame.new(saved + Vector3.new(0, 0.5, 0))
        return true
    end
    return false
end

local tooFarStreak = 0

local function doThrow()
    local s = R.Throw_Start:InvokeServer()
    if typeof(s) ~= "table" then
        setStatus("Start: balasan tidak dikenal", C_WARN)
        task.wait(2)
        return
    end

    if not s.Ok then
        local why = tostring(s.Reason)
        if why == "TooFar" then
            tooFarStreak += 1
            if tooFarStreak >= 6 then
                setStatus("TooFar terus: cek garis lempar", C_WARN)
                tooFarStreak = 0
                task.wait(5)
            elseif tpToThrow(tooFarStreak >= 3) then
                setStatus("TooFar, balik ke posisi lempar...", C_GRAY)
                task.wait(0.6)
            else
                setStatus("TooFar: posisi lempar tidak ditemukan", C_WARN)
                task.wait(2)
            end
        elseif why == "Busy" then
            setStatus("Busy, reset sesi lempar", C_WARN)
            pcall(function() R.Throw_Complete:InvokeServer() end)
            task.wait(0.5)
            pcall(function() R.Throw_Cancel:InvokeServer() end)
            task.wait(1)
        elseif why == "Cooldown" then
            task.wait(0.5)
        else
            setStatus("Start ditolak: " .. why, C_WARN)
            task.wait(2)
        end
        return
    end
    tooFarStreak = 0

    -- Start berhasil = posisi ini valid, simpan sebagai cadangan
    if not getgenv().THROW_POS then
        local h = getHRP()
        if h then getgenv().THROW_POS = h.Position end
    end

    local r = R.Throw_Resolve:InvokeServer(THROW_ACCURACY)
    if typeof(r) ~= "table" or not r.Ok then
        setStatus("Resolve gagal", C_WARN)
        pcall(function() R.Throw_Cancel:InvokeServer() end)
        task.wait(2)
        return
    end

    throws += 1
    setStatus(("Lempar #%d: %s (%s)"):format(throws, tostring(r.DisplayName), tostring(r.Rarity)), C_GOOD)

    task.wait((tonumber(r.FlightTime) or 6) + THROW_EXTRA)

    local done = false
    task.spawn(function()
        pcall(function() R.Throw_Complete:InvokeServer() end)
        done = true
    end)
    local t0 = os.clock()
    while not done and os.clock() - t0 < 3 do task.wait(0.1) end

    task.wait(0.5)
    tpToThrow()   -- karakter dipindah game ke kandang, balik ke garis lempar
end

local function throwLoop()
    throwing = true
    if tpToThrow() then
        setStatus("Teleport ke garis lempar...", C_GRAY)
        task.wait(0.5)
    end
    while State.AutoThrow and getgenv().__ThrowToken == myToken do
        local okT, err = pcall(doThrow)
        if not okT then
            setStatus("Error: " .. tostring(err), C_WARN)
            task.wait(2)
        end
        task.wait(0.2)
    end
    throwing = false
end

local function setThrow(on)
    if on then
        if State.AutoTrain then
            forceOff("AutoThrow")
            setStatus("Auto Training lagi nyala, Auto Throw dibatalkan", C_WARN)
            return
        end
        if throwing then return end
        task.spawn(throwLoop)
    else
        setStatus("Menghentikan lempar...", C_GRAY)
        task.spawn(function()
            local t0 = os.clock()
            while throwing and os.clock() - t0 < 12 do task.wait(0.2) end
            restoreLook()
            setStatus("Lempar berhenti", C_GRAY)
        end)
    end
end

-- ===== VISUAL: HIDE ANIMALS + INVISIBLE (hanya di layarmu) =====
local setHide, setInvisible
do
    local origVal = setmetatable({}, { __mode = "k" })
    local hiddenRoots = {}
    local loopRunning, invisRunning = false, false
    local plotCache, plotCacheAt = nil, 0

    local function posOf(inst)
        if inst:IsA("Model") then return inst:GetPivot().Position end
        if inst:IsA("BasePart") then return inst.Position end
        return nil
    end

    local function centroidXZ(container, limit)
        local sx, sz, n = 0, 0, 0
        for _, d in ipairs(container:GetDescendants()) do
            if d:IsA("BasePart") then
                sx += d.Position.X
                sz += d.Position.Z
                n += 1
                if n >= (limit or 300) then break end
            end
        end
        if n == 0 then return nil end
        return Vector3.new(sx / n, 0, sz / n)
    end

    -- deteksi plot milikmu: voting 4 cara
    local function detectPlot()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return nil, "Workspace.Plots tidak ada" end
        local votes = {}
        local function vote(plot, weight) votes[plot] = (votes[plot] or 0) + weight end

        -- A: TrainingRig_<namamu>
        local nameKeys = { lp.Name:lower(), lp.DisplayName:lower() }
        for _, plot in ipairs(plots:GetChildren()) do
            local server = plot:FindFirstChild("Server")
            if server then
                for _, c in ipairs(server:GetChildren()) do
                    local n = c.Name:lower()
                    if n:sub(1, 12) == "trainingrig_" then
                        local owner = n:sub(13)
                        for _, k in ipairs(nameKeys) do
                            if k ~= "" and owner == k then vote(plot, 3); break end
                        end
                    end
                end
            end
        end

        -- B: PullUpStand sejajar dengan TrainingArea milikmu
        local props = workspace:FindFirstChild("LocalPlotProps")
        local area = props and props:FindFirstChild("TrainingArea")
        local ap = area and posOf(area)
        if ap then
            for _, plot in ipairs(plots:GetChildren()) do
                local server = plot:FindFirstChild("Server")
                local stand = server and server:FindFirstChild("PullUpStand")
                local sp = stand and posOf(stand)
                if sp and math.abs(sp.X - ap.X) < 8 and math.abs(sp.Z - ap.Z) < 8 then vote(plot, 3) end
            end
        end

        -- C: OwnerTag berisi namamu / UserId
        local keys = { lp.Name:lower(), lp.DisplayName:lower(), tostring(lp.UserId) }
        local function matches(s)
            s = tostring(s):lower()
            for _, k in ipairs(keys) do
                if k ~= "" and s:find(k, 1, true) then return true end
            end
            return false
        end
        for _, plot in ipairs(plots:GetChildren()) do
            local tag = plot:FindFirstChild("OwnerTag")
            if tag then
                local found = false
                for _, v in pairs(tag:GetAttributes()) do
                    if matches(v) then found = true end
                end
                for _, d in ipairs(tag:GetDescendants()) do
                    if (d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue")) and matches(d.Value) then
                        found = true
                    elseif (d:IsA("TextLabel") or d:IsA("TextBox")) and matches(d.Text) then
                        found = true
                    elseif d:IsA("ObjectValue") and d.Value == lp then
                        found = true
                    end
                    for _, v in pairs(d:GetAttributes()) do
                        if matches(v) then found = true end
                    end
                end
                if found then vote(plot, 2) end
            end
        end

        -- D: pagar plot paling dekat dengan LocalPlotProps
        if props then
            local c = centroidXZ(props, 300)
            if c then
                local best, bestD
                for _, plot in ipairs(plots:GetChildren()) do
                    local fence = plot:FindFirstChild("Fence")
                    local fc = fence and centroidXZ(fence, 300)
                    if fc then
                        local d = (fc - c).Magnitude
                        if not bestD or d < bestD then best, bestD = plot, d end
                    end
                end
                if best and bestD < 45 then vote(best, 1) end
            end
        end

        local best, bestV = nil, 0
        for _, plot in ipairs(plots:GetChildren()) do
            local v = votes[plot] or 0
            if v > bestV then best, bestV = plot, v end
        end
        if not best then return nil, "tidak ada cara yang cocok" end
        return best, "suara " .. bestV
    end

    local function getMyPlot()
        if plotCache and plotCache.Parent and os.clock() - plotCacheAt < 10 then
            return plotCache, "cache"
        end
        local p, info = detectPlot()
        if p then plotCache, plotCacheAt = p, os.clock() end
        return p, info
    end

    local function hideObject(o, hidden)
        if o:IsA("BasePart") or o:IsA("Decal") or o:IsA("Texture") then
            if hidden then
                if origVal[o] == nil then origVal[o] = o.Transparency end
                o.Transparency = 1
            elseif origVal[o] ~= nil then
                o.Transparency = origVal[o]
                origVal[o] = nil
            end
        elseif o:IsA("BillboardGui") or o:IsA("SurfaceGui") or o:IsA("ParticleEmitter")
            or o:IsA("Beam") or o:IsA("Trail") or o:IsA("Highlight") or o:IsA("Light") then
            if hidden then
                if origVal[o] == nil then origVal[o] = o.Enabled end
                o.Enabled = false
            elseif origVal[o] ~= nil then
                o.Enabled = origVal[o]
                origVal[o] = nil
            end
        end
    end

    local function setRootHidden(root, hidden)
        if hidden then
            if hiddenRoots[root] then return end
            for _, d in ipairs(root:GetDescendants()) do hideObject(d, true) end
            hiddenRoots[root] = root.DescendantAdded:Connect(function(d) hideObject(d, true) end)
        else
            local c = hiddenRoots[root]
            if c then c:Disconnect(); hiddenRoots[root] = nil end
            for _, d in ipairs(root:GetDescendants()) do hideObject(d, false) end
        end
    end

    local function visualTick()
        local plots = workspace:FindFirstChild("Plots")
        if not plots then return end
        local minePlot = getMyPlot()
        for _, plot in ipairs(plots:GetChildren()) do
            local animals = plot:FindFirstChild("Animals")
            if animals then
                local want
                if plot == minePlot then
                    want = State.HideMine
                elseif minePlot then
                    want = State.HideOthers
                else
                    want = false   -- plotmu belum ketahuan: jangan sembunyikan apa pun
                end
                setRootHidden(animals, want)
            end
        end
    end

    local function startVisualLoop()
        if loopRunning then return end
        if not (State.HideMine or State.HideOthers) then
            pcall(visualTick)   -- semua mati: kembalikan seperti semula
            return
        end
        loopRunning = true
        task.spawn(function()
            while getgenv().__ThrowToken == myToken and (State.HideMine or State.HideOthers) do
                pcall(visualTick)
                task.wait(3)
            end
            pcall(visualTick)
            loopRunning = false
        end)
    end

    local function invisTick(on)
        local char = lp.Character
        if not char then return end
        for _, d in ipairs(char:GetDescendants()) do hideObject(d, on) end
    end

    local function startInvisLoop()
        if invisRunning then return end
        if not State.Invisible then
            pcall(invisTick, false)
            return
        end
        invisRunning = true
        task.spawn(function()
            while getgenv().__ThrowToken == myToken and State.Invisible do
                pcall(invisTick, true)
                task.wait(0.5)
            end
            pcall(invisTick, false)
            invisRunning = false
        end)
    end

    function setHide(on)
        startVisualLoop()
        if on then
            local p, how = getMyPlot()
            if p then
                setStatus("Plot kamu: " .. p.Name .. " (" .. how .. ")", C_GOOD)
            else
                setStatus("Plot kamu belum ketemu, tidak ada yang disembunyikan", C_WARN)
            end
        end
    end

    function setInvisible()
        startInvisLoop()
    end
end

-- ===== ANTI AFK, AUTO EXECUTE =====
local function setAntiAfk(on)
    if getgenv().__AfkConn then
        pcall(function() getgenv().__AfkConn:Disconnect() end)
        getgenv().__AfkConn = nil
    end
    if on then
        getgenv().__AfkConn = lp.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end

local queuedThisRun = false

local function saveLastState()
    if not writefile then return end
    local data = {}
    for _, k in ipairs(CONFIG_KEYS) do data[k] = State[k] == true end
    pcall(function() writefile(LASTSTATE_FILE, HttpService:JSONEncode(data)) end)
end

local function setAutoExec(on)
    getgenv().__ExecLoop = (getgenv().__ExecLoop or 0) + 1
    if not on then return end

    if SCRIPT_URL:find("NAMA_FILE", 1, true) then
        forceOff("AutoExec")
        setStatus("Auto Execute: isi SCRIPT_URL dulu di bagian SETTING", C_WARN)
        return
    end
    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if not qot then
        forceOff("AutoExec")
        setStatus("Auto Execute: executor tidak mendukung queue_on_teleport", C_WARN)
        return
    end

    if not queuedThisRun then
        qot('getgenv().ThrowAutoStart = true\nloadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()')
        queuedThisRun = true
    end

    local myLoop = getgenv().__ExecLoop
    task.spawn(function()
        while State.AutoExec and getgenv().__ExecLoop == myLoop and getgenv().__ThrowToken == myToken do
            saveLastState()
            task.wait(5)
        end
    end)
    setStatus("Auto Execute aktif (jalan lagi setelah pindah server)", C_GOOD)
end

-- ===== ISI HALAMAN =====
-- MAIN
do
    local p = pages.Main
    local s1 = section(p, "status")
    statusLbl = infoRow(s1, "Siap")

    local s2 = section(p, "total user pengguna script")
    usersLbl = infoRow(s2, "Total User: ...")

    local s3 = section(p, "statistik tap")
    statsLbl = infoRow(s3, "Tap: 0  |  Extra Reps: 0  |  ID: 0")

    local s4 = section(p, "info")
    infoRow(s4, "Auto Throw dan Auto Training tidak bisa nyala bareng. Yang dinyalakan paling akhir otomatis mati.")
end

-- THROW
do
    local p = pages.Throw
    groupTitle(p, "Throw")
    local s1 = section(p, "auto throw lempar makanan")
    switchRow(s1, "Auto Throw", "Lempar makanan otomatis (bar paling atas)", "AutoThrow", setThrow)

    groupTitle(p, "Food")
    local s2 = section(p, "auto buy food makanan beli")
    switchRow(s2, "Auto Buy Food", "Beli makanan berikutnya otomatis kalau uang cukup", "AutoBuyFood", function(on)
        if on then startFnLoop("AutoBuyFood", FOOD_EVERY, buyFood) end
    end)

    local s3 = section(p, "auto equip best food makanan")
    switchRow(s3, "Auto Equip Best Food", "Pakai makanan terbaik yang sudah dimiliki", "AutoEquipFood", function(on)
        if on then startFnLoop("AutoEquipFood", FOOD_EVERY, equipBestFood) end
    end)
end

-- TRAINING
do
    local p = pages.Training
    groupTitle(p, "Training")
    local s1 = section(p, "auto training latihan tap bonus")
    switchRow(s1, "Auto Training", "Teleport ke lingkaran latihan kalau perlu, mulai otomatis, dan tap bonus otomatis", "AutoTrain", setTrain)

    groupTitle(p, "Upgrade")
    local s2 = section(p, "auto upgrade bar stand")
    switchRow(s2, "Auto Upgrade Bar", "Upgrade bar latihan tiap 10 detik (uang harus cukup)", "AutoBar", function(on)
        if on then startFnLoop("AutoBar", UPGRADE_EVERY, upgradeBar) end
    end)
end

-- SELL
do
    local p = pages.Sell
    groupTitle(p, "Sell")
    local s1 = section(p, "auto sell jual")
    switchRow(s1, "Auto Sell", "Jual hewan kecil tiap 60 detik (hewan di kandang aman)", "AutoSell", function(on)
        if on then startLoop("AutoSell", "Plot_SellAll", SELL_EVERY, "Sell All") end
    end)
end

-- PET
do
    local p = pages.Pet
    groupTitle(p, "Pet")
    local s1 = section(p, "auto equip best hewan pet")
    switchRow(s1, "Auto Equip Best", "Pasang hewan terbaik otomatis tiap 30 detik", "AutoEquip", function(on)
        if on then startLoop("AutoEquip", "Plot_EquipBest", EQUIP_EVERY, "Equip Best") end
    end)

    groupTitle(p, "Plot")
    local s2 = section(p, "auto upgrade plot kandang fence")
    switchRow(s2, "Auto Upgrade Plot", "Upgrade plot (kapasitas kandang) tiap 10 detik (uang harus cukup)", "AutoFence", function(on)
        if on then startLoop("AutoFence", "Plot_UpgradeFence", UPGRADE_EVERY, "Upgrade Plot") end
    end)
end

-- MISC: Config, Auto Load Config, Visual, Other
do
    local p = pages.Misc
    local selected
    local selDD, autoTitle

    local function names()
        local list = {}
        for k in pairs(cfgData.configs) do list[#list + 1] = k end
        table.sort(list)
        return list
    end

    local function cfgStatus(t, color)
        if cfgStatusLbl then
            cfgStatusLbl.Text = t
            cfgStatusLbl.TextColor3 = color or C_GRAY
        end
    end

    local function autoName()
        local n = cfgData.autoload
        if n and cfgData.configs[n] then return n end
        return nil
    end

    local function refreshAuto()
        local n = autoName()
        autoTitle.Text = "Auto Load Config [" .. (n or "kosong") .. "]"
        autoTitle.TextColor3 = n and C_GOOD or Color3.new(1, 1, 1)
    end

    local function snapshot()
        local data = {}
        for _, k in ipairs(CONFIG_KEYS) do data[k] = State[k] == true end
        return data
    end

    local function applyConfig(data)
        for _, k in ipairs(CONFIG_KEYS) do
            if data[k] == false then applyState(k, false) end
        end
        for _, k in ipairs(CONFIG_KEYS) do
            if data[k] == true then applyState(k, true) end
        end
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
            if not fsOk() then
                cfgStatus("Executor tidak mendukung penyimpanan file", C_WARN)
                return
            end
            local n = (nameBox.Text or ""):match("^%s*(.-)%s*$")
            if n == "" then n = selected end
            if not n or n == "" then
                cfgStatus("Isi nama config dulu", C_WARN)
                return
            end
            cfgData.configs[n] = snapshot()
            local okW = writeCfgFile()
            selected = n
            selDD.setValue(n)
            nameBox.Text = n
            if okW then
                cfgStatus("Config '" .. n .. "' disimpan", C_GOOD)
            else
                cfgStatus("Gagal menulis file config", C_WARN)
            end
            refreshAuto()
        end },
        { "Load Config", function()
            if not selected or not cfgData.configs[selected] then
                cfgStatus("Pilih config dulu", C_WARN)
                return
            end
            applyConfig(cfgData.configs[selected])
            cfgStatus("Config '" .. selected .. "' dimuat", C_GOOD)
        end },
        { "Delete Config", function()
            if not selected or not cfgData.configs[selected] then
                cfgStatus("Pilih config dulu", C_WARN)
                return
            end
            local gone = selected
            cfgData.configs[gone] = nil
            if cfgData.autoload == gone then cfgData.autoload = nil end
            writeCfgFile()
            selected = nil
            selDD.setValue(nil)
            nameBox.Text = ""
            refreshAuto()
            cfgStatus("Config '" .. gone .. "' dihapus", C_GRAY)
        end, C_RED },
    })

    autoTitle = groupTitle(p, "Auto Load Config [kosong]")
    local c4 = section(p, "auto load config set delete")
    buttonsRow(c4, {
        { "Set", function()
            if not selected or not cfgData.configs[selected] then
                cfgStatus("Pilih config di Select Config dulu (kosong = Auto Load tidak aktif)", C_WARN)
                return
            end
            cfgData.autoload = selected
            writeCfgFile()
            refreshAuto()
            cfgStatus("Auto Load diset ke '" .. selected .. "'", C_GOOD)
        end },
        { "Delete", function()
            cfgData.autoload = nil
            writeCfgFile()
            refreshAuto()
            cfgStatus("Auto Load dikosongkan", C_GRAY)
        end, C_RED },
    })

    local c5 = section(p, "status config")
    cfgStatusLbl = infoRow(c5, fsOk() and "Config tersimpan di file executor." or "Executor tidak mendukung penyimpanan file.")
    refreshAuto()

    groupTitle(p, "Visual")
    local v1 = section(p, "hide my animals sembunyikan hewan saya")
    switchRow(v1, "Hide My Animals", "Sembunyikan hewan milikmu (hanya di layarmu)", "HideMine", setHide)

    local v2 = section(p, "hide other people's animals sembunyikan hewan pemain lain")
    switchRow(v2, "Hide Other People's Animals", "Sembunyikan hewan milik pemain lain (hanya di layarmu)", "HideOthers", setHide)

    local v3 = section(p, "invisible karakter")
    switchRow(v3, "Invisible", "Sembunyikan karakter kamu (hanya di layarmu)", "Invisible", setInvisible)

    groupTitle(p, "Other")
    local o1 = section(p, "auto execute")
    switchRow(o1, "Auto Execute", "Jalankan script lagi otomatis setelah pindah server", "AutoExec", setAutoExec)

    local o2 = section(p, "anti afk")
    switchRow(o2, "Anti AFK", "Cegah kena kick karena diam terlalu lama", "AntiAfk", setAntiAfk)

    -- Auto Load Config dipanggil nanti di bagian MULAI lewat fungsi ini
    getgenv().__TFAAutoLoad = function()
        local n = autoName()
        if n then
            applyConfig(cfgData.configs[n])
            cfgStatus("Auto Load: config '" .. n .. "' dimuat", C_GOOD)
        end
    end
end

-- ===== TUTUP =====
closeBtn.MouseButton1Click:Connect(function() dlg.Visible = true end)
noBtn.MouseButton1Click:Connect(function() dlg.Visible = false end)
yesBtn.MouseButton1Click:Connect(function()
    local wasTrain = State.AutoTrain
    local wasThrow = State.AutoThrow
    for k in pairs(State) do State[k] = false end
    getgenv().__ThrowToken = (getgenv().__ThrowToken or 0) + 1
    if getgenv().__TapConn then pcall(function() getgenv().__TapConn:Disconnect() end) end
    if getgenv().__AfkConn then pcall(function() getgenv().__AfkConn:Disconnect() end) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    if wasTrain then task.spawn(function() task.wait(1.2); stopTraining() end) end
    if wasThrow then task.spawn(function() task.wait(1.5); restoreLook() end) end
    gui:Destroy()
end)

-- ===== MULAI =====
setAntiAfk(State.AntiAfk)
setAutoExec(State.AutoExec)
setTab("Main")

-- Total User: daftarkan akun ini (sekali) lalu tampilkan total
task.spawn(function()
    local n = fetchTotalUsers()
    if usersLbl and usersLbl.Parent then
        usersLbl.Text = n and ("Total User: " .. n) or "Total User: -"
    end
end)

local fromTeleport = getgenv().ThrowAutoStart
getgenv().ThrowAutoStart = nil
local autoLoadFn = getgenv().__TFAAutoLoad
getgenv().__TFAAutoLoad = nil

if fromTeleport then
    -- dijalankan otomatis setelah pindah server: pulihkan status terakhir
    task.spawn(function()
        task.wait(4)
        if isfile and readfile and isfile(LASTSTATE_FILE) then
            local okR, data = pcall(function()
                return HttpService:JSONDecode(readfile(LASTSTATE_FILE))
            end)
            if okR and typeof(data) == "table" then
                for _, k in ipairs(CONFIG_KEYS) do
                    if data[k] == true then applyState(k, true) end
                end
                setStatus("Status terakhir dipulihkan", C_GOOD)
            end
        end
    end)
elseif autoLoadFn then
    task.spawn(function()
        task.wait(2)
        autoLoadFn()
    end)
end
