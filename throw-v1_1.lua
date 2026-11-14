-- Throw For Animals V1.5 | by D33RZN
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local lp = Players.LocalPlayer
local R = RS:WaitForChild("Remotes", 5)
if not (R and R:WaitForChild("Throw_Start", 5)) then
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "TFA V1.5",
            Text = "This script only works in Throw Food For Animals.",
            Duration = 8,
        })
    end)
    return
end

-- ===== SETTING =====
local SCRIPT_BASE = "https://raw.githubusercontent.com/Dr6seven/throwforanimals/refs/heads/main/"
local SCRIPT_FILES = { "throw-2.lua", "throw.lua" } -- dicoba berurutan sampai ada yang berhasil diunduh
local ICON_URL = "https://raw.githubusercontent.com/Dr6seven/throwforanimals/refs/heads/main/icon/icon.png"
local ICON_FILE = "tfa_icon.png"
local CONFIG_FILE = "ThrowForAnimals_configs.json"
local LASTSTATE_FILE = "ThrowForAnimals_laststate.json"

-- penghitung Total User (layanan gratis dari luar; ganti NS dan SALT)
local COUNTER_BASE = "https://abacus.jasoncameron.dev"
local COUNTER_NS = "throwforanimals-d33rzn"
local COUNTER_KEY = "users"
local SALT = "ganti-teks-acak-ini"

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
local TAMPILKAN_STATUS = false -- true = tampilkan baris status (untuk debug)
local DEBUG_RESOLVE = false    -- true = salin 6 hasil lemparan terakhir ke clipboard (cari nama field)
local THROW_ACCURACY = 1   -- 1 = bar lempar paling atas
local THROW_EXTRA = 0.3    -- tambahan setelah waktu terbang

-- switch yang ikut disimpan di config dan status terakhir
local CONFIG_KEYS = { "AutoTrain", "AutoThrow", "AutoIndex", "AutoBuyFood", "AutoEquipFood", "AutoBar",
    "AutoSell", "AutoEquip", "AutoFence", "Invisible", "AutoExec", "AutoReconnect", "AntiAfk", "ESPPlayer" }

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

local State = { AutoTrain = false, AutoThrow = false, AutoIndex = false, AutoReconnect = false, AutoBuyFood = false, AutoEquipFood = false,
    AutoBar = false, AutoSell = false, AutoEquip = false, AutoFence = false,
    Invisible = false, AutoExec = false, AntiAfk = true, ESPPlayer = false }

local taps, extra, lastId = 0, 0, 0
local running = false
local throwing = false
local throwPause = false
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
-- penanda disimpan per akun (bukan per perangkat) supaya akun kedua ikut terhitung
local function fetchTotalUsers()
    local regFile = "tfa_reg_" .. userKey() .. ".txt"
    local state = (isfile and isfile(regFile)) and readfile(regFile) or ""
    if state ~= "1" then
        if state ~= "pending" then
            local v = counterCall("/hit/" .. COUNTER_NS .. "/" .. userKey())
            if v == 1 then state = "pending"
            elseif v then state = "1" end -- sudah pernah terhitung
        end
        if state == "pending" then
            if writefile then pcall(writefile, regFile, "pending") end
            for _ = 1, 3 do
                if counterCall("/hit/" .. COUNTER_NS .. "/" .. COUNTER_KEY) then
                    state = "1"
                    break
                end
                task.wait(2)
            end
        end
        if state == "1" and writefile then pcall(writefile, regFile, "1") end
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

local WIN_W, WIN_H = 470, 300
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
title.Text = "Throw For Animals V1.6"
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

-- daftar akun owner (UserId -> teks tag), dipakai di Akun Info
local OWNER_IDS = {
    [8925135775] = "Owner",
}

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
tl.Padding = UDim.new(0, 2)
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
        local ic = b:FindFirstChildOfClass("ImageLabel")
        if ic then ic.ImageTransparency = (n == name) and 0 or 0.45 end
    end
end

-- unduh ikon sekali, simpan di folder lokal executor
local ICON_BASE = "https://raw.githubusercontent.com/Dr6seven/throwforanimals/refs/heads/main/icon/"
local function iconAsset(file)
    local path = "tfa_icons/" .. file
    if isfolder and makefolder and not isfolder("tfa_icons") then pcall(makefolder, "tfa_icons") end
    if isfile and writefile and not isfile(path) then
        local ok, data = pcall(function() return game:HttpGet(ICON_BASE .. file) end)
        if ok and type(data) == "string" and #data > 0 then pcall(writefile, path, data) end
    end
    if getcustomasset and isfile and isfile(path) then
        local ok, a = pcall(getcustomasset, path)
        if ok and a then return a end
    end
    return ""
end

local function newTab(name, ord, icon)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 25)
    b.Text = name
    b.Font = Enum.Font.GothamBold
    b.TextSize = 11
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.LayoutOrder = ord
    b.Parent = tabList
    corner(b, 8)
    Instance.new("UIPadding", b).PaddingLeft = UDim.new(0, 28)
    local ic = Instance.new("ImageLabel")
    ic.Size = UDim2.new(0, 18, 0, 18)
    ic.Position = UDim2.new(0, -24, 0.5, -9)
    ic.BackgroundTransparency = 1
    ic.Image = ""
    ic.Parent = b
    task.spawn(function()
        local a = iconAsset(icon)
        if a ~= "" and ic.Parent then ic.Image = a end
    end)
    tabs[name] = b
    b.MouseButton1Click:Connect(function() setTab(name) end)
end

local tabDefs = { { "Main", "home.png" }, { "Throw", "target.png" }, { "Training", "dumbbell.png" },
    { "Sell", "coin.png" }, { "Pet", "paw.png" }, { "Misc", "gear.png" } }
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

local statusLbl, statsLbl, usersLbl, onlineLbl, cfgStatusLbl
local toastLbl, toastTok = nil, 0
local function setStatus(t, color)
    if not TAMPILKAN_STATUS then return end
    if statusLbl and statusLbl.Parent then
        statusLbl.Text = t
        statusLbl.TextColor3 = color or C_GRAY
        return
    end
    -- tanpa baris status di Main: tampilkan sebagai pesan kecil sementara di pojok bawah
    if not (toastLbl and toastLbl.Parent) then
        toastLbl = Instance.new("TextLabel")
        toastLbl.Size = UDim2.new(0, 236, 0, 18)
        toastLbl.Position = UDim2.new(1, -244, 1, -24)
        toastLbl.BackgroundColor3 = C_BG
        toastLbl.BackgroundTransparency = 0.15
        toastLbl.BorderSizePixel = 0
        toastLbl.Font = Enum.Font.Gotham
        toastLbl.TextSize = 9
        toastLbl.TextXAlignment = Enum.TextXAlignment.Left
        toastLbl.TextTruncate = Enum.TextTruncate.AtEnd
        toastLbl.ZIndex = 30
        toastLbl.Parent = body
        corner(toastLbl, 6)
        local pad = Instance.new("UIPadding", toastLbl)
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingRight = UDim.new(0, 6)
    end
    toastTok = toastTok + 1
    local tok = toastTok
    toastLbl.Text = t
    toastLbl.TextColor3 = color or C_GRAY
    toastLbl.Visible = true
    task.delay(4, function()
        if toastTok == tok and toastLbl then toastLbl.Visible = false end
    end)
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
    box.ClipsDescendants = true
    box.TextTruncate = Enum.TextTruncate.AtEnd
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
            e.Text = "(no configs yet)"
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
        if State.AutoThrow or State.AutoIndex then
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
        if not State.AutoThrow and not State.AutoIndex and tpToTraining() then
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
    if State.AutoIndex then return end -- rotasi makanan Auto Index yang mengatur
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

-- ===== POP UP HEWAN =====
local popupHolder = Instance.new("Frame")
popupHolder.Name = "PopupHewan"
popupHolder.BackgroundTransparency = 1
popupHolder.Size = UDim2.new(0, 210, 0, 240)
popupHolder.Position = UDim2.new(0.5, -105, 0, -30)
popupHolder.ZIndex = 50
popupHolder.Parent = gui
local popupList = Instance.new("UIListLayout", popupHolder)
popupList.Padding = UDim.new(0, 5)
popupList.HorizontalAlignment = Enum.HorizontalAlignment.Center
popupList.SortOrder = Enum.SortOrder.LayoutOrder

local POP_RARITY = {
    common = Color3.fromRGB(170, 170, 180),
    uncommon = Color3.fromRGB(90, 200, 120),
    rare = Color3.fromRGB(80, 150, 240),
    epic = Color3.fromRGB(170, 100, 240),
    legendary = Color3.fromRGB(250, 190, 60),
    mythic = Color3.fromRGB(240, 80, 110),
    divine = Color3.fromRGB(255, 235, 140),
    sovereign = Color3.fromRGB(255, 80, 80),
}
local POP_VARIANT = {
    gold = Color3.fromRGB(245, 197, 66),
    diamond = Color3.fromRGB(111, 216, 255),
    emerald = Color3.fromRGB(80, 220, 140),
    rainbow = Color3.fromRGB(255, 150, 255),
    ruby = Color3.fromRGB(235, 60, 80),
}
local POP_SIZE = {
    titanic = Color3.fromRGB(255, 95, 162),
    giant = Color3.fromRGB(255, 154, 60),
}
local popupN = 0

local POP_SFX = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc",
    "Ud", "Dd", "Td", "Qad", "Qid", "Sxd", "Spd", "Ocd", "Nod", "Vg" }

local function popFmt(n)
    n = tonumber(n)
    if not n or n ~= n then return nil end
    local i = 1
    while n >= 1000 and i < #POP_SFX do
        n = n / 1000
        i += 1
    end
    local s
    if n >= 100 then
        s = ("%.0f"):format(n)
    elseif n >= 10 then
        s = ("%.1f"):format(n)
    else
        s = ("%.2f"):format(n)
    end
    if s:find("%.") then
        s = (s:gsub("0+$", ""))
        s = (s:gsub("%.$", ""))
    end
    return s .. POP_SFX[i]
end

local function popNorm(s) return (tostring(s):lower():gsub("[%s_%-]", "")) end

local function popHitung(m)
    local n = 0
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") then n += 1 end
    end
    return n
end

local function popCariIn(folder, key)
    if not folder then return nil end
    for _, c in ipairs(folder:GetChildren()) do
        if c:IsA("Model") and popNorm(c.Name) == key then return c end
    end
    return nil
end

local popCache = {}
local POP_MUT = { "diamond", "emerald", "gold", "rainbow", "ruby" }

local function popCari(nama)
    local key = popNorm(nama)
    local keys = { key }
    for _, mu in ipairs(POP_MUT) do
        if key:sub(1, #mu) == mu then keys[#keys + 1] = key:sub(#mu + 1) end
        if key:sub(-#mu) == mu then keys[#keys + 1] = key:sub(1, #key - #mu) end
    end
    for _, k in ipairs(keys) do
        local c = popCache[k]
        if c and c.Parent then return c end
    end
    local lokasi = { lp.PlayerGui:FindFirstChild("StudioAnimals") }
    local plots = workspace:FindFirstChild("Plots")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            lokasi[#lokasi + 1] = plot:FindFirstChild("Animals")
        end
    end
    for _, k in ipairs(keys) do
        for _, f in ipairs(lokasi) do
            local m = popCariIn(f, k)
            if m and popHitung(m) >= 5 then
                popCache[k] = m
                return m
            end
        end
    end
    return nil
end

local function popGambar(parent, src, z)
    local vp
    local ok = pcall(function()
        local m = src:Clone()
        if not m then error("clone gagal") end
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("BaseScript") or d:IsA("BillboardGui") or d:IsA("SurfaceGui") then
                d:Destroy()
            end
        end
        vp = Instance.new("ViewportFrame")
        vp.Size = UDim2.new(1, 0, 1, 0)
        vp.BackgroundTransparency = 1
        vp.Ambient = Color3.fromRGB(190, 190, 190)
        vp.ZIndex = z
        vp.Parent = parent
        local cam = Instance.new("Camera")
        cam.FieldOfView = 40
        vp.CurrentCamera = cam
        cam.Parent = vp
        m.Parent = vp
        local piv = m:GetPivot()
        local cf, sz = m:GetBoundingBox()
        local dist = math.max(sz.X, sz.Y, sz.Z) * 1.7 + 1
        local arah = (piv.LookVector + piv.UpVector * 0.35 + piv.RightVector * 0.4).Unit
        cam.CFrame = CFrame.lookAt(cf.Position + arah * dist, cf.Position)
    end)
    if not ok and vp then vp:Destroy() end
    return ok
end

local POP_MUTNAMES = { diamond = true, emerald = true, gold = true, rainbow = true, ruby = true }
local POP_KOSONG = { [""] = true, none = true, ["false"] = true }

-- baca varian (mutasi) dan ukuran dari hasil lemparan; nama field dicari otomatis
local function popBaca(r)
    local varian, ukuran
    for k, v in pairs(r) do
        if type(v) == "string" and k ~= "DisplayName" and k ~= "Rarity" then
            local kl, vl = tostring(k):lower(), v:lower()
            if not POP_KOSONG[vl] then
                if not varian and vl ~= "normal" and (POP_MUTNAMES[vl] or kl:find("mut") or kl:find("variant")) then
                    varian = v
                elseif not ukuran and kl:find("size") then
                    ukuran = v
                end
            end
        end
    end
    return varian, ukuran
end

local function popupHewan(r)
    if typeof(r) ~= "table" then return end
    popupN += 1

    local list = {}
    for _, c in ipairs(popupHolder:GetChildren()) do
        if c:IsA("Frame") then list[#list + 1] = c end
    end
    table.sort(list, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
    while #list >= 3 do table.remove(list, 1):Destroy() end

    local nama = tostring(r.DisplayName or "?")
    local rarity = tostring(r.Rarity or "")
    local varian, ukuran = popBaca(r)
    local income = popFmt(r.Income or r.IncomePerSecond)

    local warnaRar = POP_RARITY[rarity:lower()] or C_GRAY
    local teks1 = varian and varian:upper() or rarity:upper()
    local warna1 = varian and (POP_VARIANT[varian:lower()] or Color3.fromRGB(240, 240, 245)) or warnaRar

    local w = Instance.new("Frame")
    w.LayoutOrder = popupN
    w.Size = UDim2.new(1, 0, 0, 76)
    w.BackgroundTransparency = 1
    w.ZIndex = 50
    w.Parent = popupHolder

    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.Position = UDim2.new(0, 0, 0, -130)
    f.BackgroundColor3 = C_BG
    f.BorderSizePixel = 0
    f.ZIndex = 50
    f.Parent = w
    corner(f, 8)
    local st = Instance.new("UIStroke", f)
    st.Color = Color3.fromRGB(120, 120, 130)
    st.Thickness = 2

    local img = Instance.new("Frame")
    img.Size = UDim2.new(0, 76, 1, 0)
    img.BackgroundColor3 = warnaRar:Lerp(Color3.new(0, 0, 0), 0.55)
    img.BorderSizePixel = 0
    img.ZIndex = 51
    img.Parent = f

    local garis = Instance.new("Frame")
    garis.Size = UDim2.new(0, 1, 1, 0)
    garis.Position = UDim2.new(0, 76, 0, 0)
    garis.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
    garis.BorderSizePixel = 0
    garis.ZIndex = 53
    garis.Parent = f

    local sudah = false
    local ikon = r.Image or r.Icon
    if type(ikon) == "string" and ikon:find("rbx") then
        local il = Instance.new("ImageLabel")
        il.Size = UDim2.new(1, 0, 1, 0)
        il.BackgroundTransparency = 1
        il.Image = ikon
        il.ScaleType = Enum.ScaleType.Fit
        il.ZIndex = 52
        il.Parent = img
        sudah = true
    end
    if not sudah then
        local hl = Instance.new("TextLabel")
        hl.Size = UDim2.new(1, 0, 1, 0)
        hl.BackgroundTransparency = 1
        hl.Text = nama:sub(1, 1):upper()
        hl.TextColor3 = warnaRar
        hl.Font = Enum.Font.GothamBold
        hl.TextSize = 30
        hl.ZIndex = 52
        hl.Parent = img
        task.spawn(function()
            for _ = 1, 8 do
                if not f.Parent then return end
                local src = popCari(nama)
                if src then
                    if popGambar(img, src, 52) then hl:Destroy() end
                    return
                end
                task.wait(0.4)
            end
        end)
    end

    local box = Instance.new("Frame")
    box.Size = UDim2.new(1, -88, 1, -2)
    box.Position = UDim2.new(0, 82, 0, 0)
    box.BackgroundTransparency = 1
    box.ZIndex = 51
    box.Parent = f
    local bl = Instance.new("UIListLayout", box)
    bl.VerticalAlignment = Enum.VerticalAlignment.Center
    bl.SortOrder = Enum.SortOrder.LayoutOrder

    local function baris(order, teks, size, warna)
        local t = Instance.new("TextLabel")
        t.LayoutOrder = order
        t.Size = UDim2.new(1, -24, 0, size + 4)
        t.BackgroundTransparency = 1
        t.Text = teks
        t.TextColor3 = warna
        t.Font = Enum.Font.GothamBold
        t.TextSize = size
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextTruncate = Enum.TextTruncate.AtEnd
        t.ZIndex = 52
        t.Parent = box
    end
    if teks1 ~= "" then baris(1, teks1, 10, warna1) end
    baris(2, nama, 13, Color3.new(1, 1, 1))
    if ukuran then
        baris(3, ukuran:upper(), 10, POP_SIZE[ukuran:lower()] or C_GRAY)
    end
    if income then
        baris(4, "$" .. income .. "/s", 11, C_GOOD)
    end

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 2)
    bar.Position = UDim2.new(0, 0, 1, -2)
    bar.BackgroundColor3 = warna1
    bar.BorderSizePixel = 0
    bar.ZIndex = 53
    bar.Parent = f

    local tertutup = false
    local function tutup()
        if tertutup or not f.Parent then return end
        tertutup = true
        TS:Create(f, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0, 0, 0, -130) }):Play()
        task.wait(0.32)
        w:Destroy()
    end

    local x = Instance.new("TextButton")
    x.Size = UDim2.new(0, 26, 0, 26)
    x.Position = UDim2.new(1, -28, 0, 2)
    x.BackgroundTransparency = 1
    x.Text = "×"
    x.TextColor3 = Color3.fromRGB(200, 200, 205)
    x.Font = Enum.Font.GothamBold
    x.TextSize = 18
    x.AutoButtonColor = false
    x.ZIndex = 54
    x.Parent = f
    x.Activated:Connect(tutup)

    TS:Create(f, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
    TS:Create(bar, TweenInfo.new(3.2, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()
    task.delay(3.2, tutup)
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
    pcall(popupHewan, r)
    if getgenv().__TFAWebhook then pcall(getgenv().__TFAWebhook, r) end
    if DEBUG_RESOLVE then
        pcall(function()
            local f = {}
            for k, v in pairs(r) do f[#f + 1] = tostring(k) .. "=" .. tostring(v) end
            table.sort(f)
            local log = getgenv().__ResolveLog or {}
            table.insert(log, table.concat(f, ", "))
            while #log > 6 do table.remove(log, 1) end
            getgenv().__ResolveLog = log
            if setclipboard then setclipboard(table.concat(log, "\n")) end
        end)
    end

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
    while (State.AutoThrow or State.AutoIndex) and not throwPause and getgenv().__ThrowToken == myToken do
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
        if State.AutoIndex then
            forceOff("AutoThrow")
            setStatus("Auto Index lagi nyala, Auto Throw dibatalkan", C_WARN)
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

-- ===== VISUAL: INVISIBLE (hanya di layarmu) =====
local setInvisible
do
    local origVal = setmetatable({}, { __mode = "k" })
    local invisRunning = false

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

    function setInvisible()
        startInvisLoop()
    end
end

-- ===== ESP PLAYER =====
local setESP
do
    local folder = Instance.new("Folder")
    folder.Name = "ESPPlayer"
    folder.Parent = gui
    local entries = {}
    local conns = {}
    local running = false
    local ESP_COLOR = Color3.fromRGB(255, 80, 80)

    local function hapus(plr)
        local e = entries[plr]
        if e then
            pcall(function() e.hl:Destroy() end)
            pcall(function() e.bb:Destroy() end)
            entries[plr] = nil
        end
    end

    local function pasang(plr)
        if plr == lp then return end
        hapus(plr)
        local char = plr.Character
        local root = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
        if not root then return end

        local hl = Instance.new("Highlight")
        hl.Adornee = char
        hl.FillColor = ESP_COLOR
        hl.FillTransparency = 0.75
        hl.OutlineColor = Color3.new(1, 1, 1)
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = folder

        local bb = Instance.new("BillboardGui")
        bb.Adornee = root
        bb.Size = UDim2.new(0, 150, 0, 18)
        bb.StudsOffset = Vector3.new(0, 3.2, 0)
        bb.AlwaysOnTop = true
        bb.Parent = folder

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = plr.DisplayName
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.TextStrokeTransparency = 0.3
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 13
        lbl.Parent = bb

        entries[plr] = { hl = hl, bb = bb, lbl = lbl, root = root, nama = plr.DisplayName }
    end

    local function pantau(plr)
        if plr == lp then return end
        conns[#conns + 1] = plr.CharacterAdded:Connect(function()
            task.wait(0.5)
            if State.ESPPlayer then pasang(plr) end
        end)
        pasang(plr)
    end

    local function berhenti()
        for _, c in ipairs(conns) do c:Disconnect() end
        conns = {}
        for plr in pairs(entries) do hapus(plr) end
    end

    function setESP(on)
        berhenti()
        if not on then return end
        for _, plr in ipairs(Players:GetPlayers()) do pantau(plr) end
        conns[#conns + 1] = Players.PlayerAdded:Connect(pantau)
        conns[#conns + 1] = Players.PlayerRemoving:Connect(hapus)
        if running then return end
        running = true
        task.spawn(function()
            while getgenv().__ThrowToken == myToken and State.ESPPlayer do
                local char = lp.Character
                local mine = char and char:FindFirstChild("HumanoidRootPart")
                if mine then
                    for _, e in pairs(entries) do
                        if e.root and e.root.Parent then
                            local d = math.floor((e.root.Position - mine.Position).Magnitude)
                            e.lbl.Text = e.nama .. "  [" .. d .. "m]"
                        end
                    end
                end
                task.wait(0.25)
            end
            berhenti()
            running = false
        end)
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

local execLbl
local function execInfo(t, color)
    if execLbl and execLbl.Parent then
        execLbl.Text = t
        execLbl.TextColor3 = color or C_GRAY
    end
    setStatus(t, color)
end

local AUTOEXEC_FLAG = "ThrowForAnimals_autoexec.txt"
local function tulisFlag(v)
    if writefile then pcall(writefile, AUTOEXEC_FLAG, v and "1" or "0") end
end

-- kode yang dijalankan executor setelah pindah server
local function buildQueued()
    local files = {}
    for _, f in ipairs(SCRIPT_FILES) do files[#files + 1] = string.format("%q", SCRIPT_BASE .. f) end
    return table.concat({
        'if not (isfile and isfile("' .. AUTOEXEC_FLAG .. '") and readfile("' .. AUTOEXEC_FLAG .. '") == "1") then return end',
        'getgenv().ThrowAutoStart = true',
        'if not game:IsLoaded() then game.Loaded:Wait() end',
        'task.wait(3)',
        'local urls = {' .. table.concat(files, ", ") .. '}',
        'for _, u in ipairs(urls) do',
        '    local ok, src = pcall(function() return game:HttpGet(u) end)',
        '    if ok and type(src) == "string" and #src > 2000 then',
        '        local fn = loadstring(src)',
        '        if fn then',
        '            fn()',
        '            return',
        '        end',
        '    end',
        'end',
        'warn("[Throw] Auto Execute gagal mengunduh script")',
    }, "\n")
end

local function setAutoExec(on, awal)
    getgenv().__ExecLoop = (getgenv().__ExecLoop or 0) + 1
    if not on then
        if not awal then
            tulisFlag(false)
            execInfo("Auto Execute mati", C_GRAY)
        end
        return
    end

    local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
    if not qot then
        forceOff("AutoExec")
        execInfo("Executor tidak mendukung queue_on_teleport", C_WARN)
        return
    end

    tulisFlag(true)
    if not queuedThisRun then
        local okQ, errQ = pcall(qot, buildQueued())
        if not okQ then
            forceOff("AutoExec")
            execInfo("Gagal mendaftarkan Auto Execute: " .. tostring(errQ), C_WARN)
            return
        end
        queuedThisRun = true
    end

    local myLoop = getgenv().__ExecLoop
    task.spawn(function()
        while State.AutoExec and getgenv().__ExecLoop == myLoop and getgenv().__ThrowToken == myToken do
            saveLastState()
            task.wait(5)
        end
    end)
    execInfo("Auto Execute aktif (jalan lagi setelah pindah server)", C_GOOD)
end

-- ===== ISI HALAMAN =====
-- MAIN
do
    local p = pages.Main

    groupTitle(p, "Welcome")

    -- AKUN INFO
    do
        local Stats = game:GetService("Stats")

        -- sensor username: 2 huruf pertama, sisanya bintang
        local function sensor(nama)
            if #nama <= 2 then return nama end
            return nama:sub(1, 2) .. string.rep("*", #nama - 2)
        end

        local sAcc = section(p, "akun info profil")
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 76)
        row.BackgroundColor3 = C_ROW
        row.BorderSizePixel = 0
        row.LayoutOrder = nextOrder()
        row.Parent = sAcc
        corner(row, 8)

        local avatar = Instance.new("ImageLabel")
        avatar.Size = UDim2.new(0, 60, 0, 60)
        avatar.Position = UDim2.new(0, 8, 0, 8)
        avatar.BackgroundColor3 = C_BG
        avatar.BorderSizePixel = 0
        avatar.Image = ""
        avatar.Parent = row
        corner(avatar, 30)
        task.spawn(function()
            local ok, img = pcall(function()
                return Players:GetUserThumbnailAsync(lp.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            end)
            if ok and img and avatar.Parent then avatar.Image = img end
        end)

        local nameRow = Instance.new("Frame")
        nameRow.Size = UDim2.new(1, -156, 0, 20)
        nameRow.Position = UDim2.new(0, 76, 0, 14)
        nameRow.BackgroundTransparency = 1
        nameRow.Parent = row
        local nl = Instance.new("UIListLayout", nameRow)
        nl.FillDirection = Enum.FillDirection.Horizontal
        nl.VerticalAlignment = Enum.VerticalAlignment.Center
        nl.Padding = UDim.new(0, 6)
        nl.SortOrder = Enum.SortOrder.LayoutOrder

        local disp = Instance.new("TextLabel")
        disp.Size = UDim2.new(0, 0, 0, 20)
        disp.AutomaticSize = Enum.AutomaticSize.X
        disp.BackgroundTransparency = 1
        disp.Text = lp.DisplayName
        disp.TextColor3 = Color3.new(1, 1, 1)
        disp.Font = Enum.Font.GothamBold
        disp.TextSize = 15
        disp.LayoutOrder = 1
        disp.Parent = nameRow

        local ownerLabel = OWNER_IDS[lp.UserId]
        if ownerLabel then
            local tagLbl = Instance.new("TextLabel")
            tagLbl.Size = UDim2.new(0, 0, 0, 16)
            tagLbl.AutomaticSize = Enum.AutomaticSize.X
            tagLbl.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
            tagLbl.Text = " " .. ownerLabel .. " "
            tagLbl.TextColor3 = Color3.new(1, 1, 1)
            tagLbl.Font = Enum.Font.GothamBold
            tagLbl.TextSize = 10
            tagLbl.LayoutOrder = 2
            tagLbl.Parent = nameRow
            corner(tagLbl, 4)
        end

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -156, 0, 14)
        sub.Position = UDim2.new(0, 76, 0, 40)
        sub.BackgroundTransparency = 1
        sub.Text = "@" .. sensor(lp.Name)
        sub.TextColor3 = C_GRAY
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = row

        -- FPS (atas) dan ms (bawah) di sisi kanan kartu
        local function pill(y, text)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(0, 62, 0, 26)
            f.Position = UDim2.new(1, -70, 0, y)
            f.BackgroundColor3 = C_BG
            f.BorderSizePixel = 0
            f.Parent = row
            corner(f, 13)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 1, 0)
            l.BackgroundTransparency = 1
            l.Text = text
            l.TextColor3 = Color3.new(1, 1, 1)
            l.Font = Enum.Font.GothamBold
            l.TextSize = 11
            l.Parent = f
            return l
        end
        local fpsLbl = pill(9, "- FPS")
        local msLbl = pill(41, "- ms")

        local frames, last = 0, os.clock()
        local hb = RunService.Heartbeat:Connect(function() frames = frames + 1 end)
        task.spawn(function()
            while gui.Parent and getgenv().__ThrowToken == myToken do
                task.wait(1)
                local now = os.clock()
                local fps = math.floor(frames / (now - last) + 0.5)
                frames, last = 0, now
                local ms
                pcall(function() ms = Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
                ms = ms or (lp:GetNetworkPing() * 1000)
                fpsLbl.Text = fps .. " FPS"
                msLbl.Text = math.floor(ms + 0.5) .. " ms"
            end
            hb:Disconnect()
        end)
    end

    local s2 = section(p, "user online pengguna script")
    local statRow = Instance.new("Frame")
    statRow.Size = UDim2.new(1, 0, 0, 30)
    statRow.BackgroundTransparency = 1
    statRow.LayoutOrder = nextOrder()
    statRow.Parent = s2

    local function statCell(pos, size, iconFile, text)
        local cell = Instance.new("Frame")
        cell.Size = size
        cell.Position = pos
        cell.BackgroundColor3 = C_ROW
        cell.BorderSizePixel = 0
        cell.Parent = statRow
        corner(cell, 8)
        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.new(0, 16, 0, 16)
        ic.Position = UDim2.new(0, 8, 0.5, -8)
        ic.BackgroundTransparency = 1
        ic.Parent = cell
        task.spawn(function()
            local a = iconAsset(iconFile)
            if a ~= "" and ic.Parent then ic.Image = a end
        end)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -32, 1, 0)
        lbl.Position = UDim2.new(0, 30, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = Color3.new(1, 1, 1)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = cell
        return lbl
    end
    usersLbl = statCell(UDim2.new(0, 0, 0, 0), UDim2.new(0.5, -3, 1, 0), "user.png", "User : -")
    onlineLbl = statCell(UDim2.new(0.5, 3, 0, 0), UDim2.new(0.5, -3, 1, 0), "online.png", "Online : -")

    -- group Discord
    do
        -- matikan sisa musik dari eksekusi sebelumnya
        if getgenv().__TFASound then pcall(function() getgenv().__TFASound:Destroy() end) end

        local DISCORD_LINK = "https://discord.gg/bVv8juvjj"

        groupTitle(p, "Discord")
        local sD = section(p, "discord group komunitas")

        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1, 0, 0, 40)
        row.BackgroundColor3 = C_ROW
        row.BorderSizePixel = 0
        row.Text = ""
        row.LayoutOrder = nextOrder()
        row.Parent = sD
        corner(row, 8)

        local ic = Instance.new("ImageLabel")
        ic.Size = UDim2.new(0, 26, 0, 26)
        ic.Position = UDim2.new(0, 10, 0.5, -13)
        ic.BackgroundTransparency = 1
        ic.Parent = row
        task.spawn(function()
            local a = iconAsset("discord.png")
            if a ~= "" and ic.Parent then ic.Image = a end
        end)

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -52, 0, 16)
        title.Position = UDim2.new(0, 44, 0, 5)
        title.BackgroundTransparency = 1
        title.Text = "Discord Group"
        title.TextColor3 = Color3.new(1, 1, 1)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 12
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = row

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -52, 0, 12)
        sub.Position = UDim2.new(0, 44, 0, 21)
        sub.BackgroundTransparency = 1
        sub.Text = "Tap to copy & open the link"
        sub.TextColor3 = C_GRAY
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 9
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = row

        row.MouseButton1Click:Connect(function()
            local copied = false
            local cb = setclipboard or toclipboard or (syn and syn.write_clipboard)
            if cb then copied = pcall(cb, DISCORD_LINK) end
            pcall(function() game:GetService("GuiService"):OpenBrowserWindow(DISCORD_LINK) end)
            sub.Text = copied and "Link copied!" or DISCORD_LINK
            sub.TextColor3 = C_GOOD
            task.delay(2.5, function()
                if sub.Parent then
                    sub.Text = "Tap to copy & open the link"
                    sub.TextColor3 = C_GRAY
                end
            end)
        end)
    end

    local s3 = section(p, "statistik tap")
    statsLbl = infoRow(s3, "Tap: 0  |  Extra Reps: 0  |  ID: 0")

end

-- THROW
do
    local p = pages.Throw

    -- power maksimal sebenarnya (angka setelah "/" di slider Throw Power);
    -- field ThrowPower di data pemain bisa terbaca 0, jadi diambil yang terbesar dari beberapa sumber
    local function bacaMax(data)
        local terbaik
        local function coba(n)
            n = tonumber(n)
            if n and n >= 26 and (not terbaik or n > terbaik) then terbaik = n end
        end
        local hud = lp.PlayerGui:FindFirstChild("HUD")
        local ps = hud and hud:FindFirstChild("PowerSlider")
        local body = ps and ps:FindFirstChild("Body")
        local lbl = body and body:FindFirstChild("Value")
        if lbl then
            local t = lbl.Text:gsub("<[^>]+>", "")
            local m = t:match("/%s*([%d%.,]+)")
            if m then coba((m:gsub(",", ""))) end
        end
        local ls = lp:FindFirstChild("leaderstats")
        local tp = ls and ls:FindFirstChild("Throw Power")
        if tp then coba(tp.Value) end
        if data then coba(data.ThrowPower) end
        return terbaik
    end

    groupTitle(p, "Throw")
    local s1 = section(p, "auto throw lempar makanan")
    switchRow(s1, "Auto Throw", "Throws food automatically", "AutoThrow", setThrow)

    -- Throw Power per area (power paling ujung tiap area)
    do
        local AREAS = {}
        local idx = 1
        local MARGIN = 20 -- power dikurangi supaya aman dari area berikutnya
        local okAC, ACfg = pcall(function() return game:GetService("ReplicatedStorage").Config.AreasConfig end)
        if okAC then okAC, ACfg = pcall(require, ACfg) end

        -- daftar area dibaca dari game, jadi area baru ikut muncul otomatis
        do
            local daftar = {}
            if okAC and type(ACfg) == "table" and type(ACfg.List) == "table" then
                for _, a in ipairs(ACfg.List) do
                    daftar[#daftar + 1] = { a.Name, a.StartDistance + a.Length - 1 }
                end
                daftar[#daftar + 1] = { "MAX", "MAX" }
            end
            if #daftar == 0 then -- cadangan kalau data game tidak terbaca
                daftar = {
                    { "Forest", 172 }, { "Savanna", 340 }, { "Desert", 508 }, { "Jungle", 676 },
                    { "Ocean", 844 }, { "Mountains", 1036 }, { "Taiga", 1252 }, { "Winter", 1492 },
                    { "Prehistoric Forest", 1756 }, { "Deep Waters", 2044 }, { "Hell", 2380 },
                    { "Ancient Ruins", 2764 }, { "Mythical Paradise", 3244 }, { "Shadow Realm", 4084 },
                    { "Harvest Fields", 5164 }, { "Phantom Harbor", 6244 }, { "Nuclear Wasteland", 7972 },
                    { "Cursed Carnival", 9700 }, { "Eclipse Kingdom", 11428 }, { "MAX", "MAX" },
                }
            end
            AREAS = daftar
        end

        -- nama area dari power (hitungan sendiri, tidak bergantung tulisan di slider)
        local function areaDari(pwr)
            if not okAC then return nil end
            local ok, prog = pcall(function() return ACfg.ProgressForDistance(pwr) end)
            if not ok or type(prog) ~= "number" then return nil end
            local i = math.clamp(math.floor(prog) + 1, 1, #ACfg.List)
            return ACfg.List[i].Name:upper()
        end

        local function sliderBody()
            local hud = lp.PlayerGui:FindFirstChild("HUD")
            local ps = hud and hud:FindFirstChild("PowerSlider")
            return ps and ps:FindFirstChild("Body")
        end
        local function readMax() return bacaMax() end
        local function areaText()
            local body = sliderBody()
            local lbl = body and body:FindFirstChild("Area")
            if not lbl then return nil end
            local t = lbl.Text:gsub("<[^>]+>", "")
            t = t:gsub("^%s*Lands in:%s*", "")
            return t
        end

        local sP = section(p, "throw power kekuatan lempar area forest")

        local prow = Instance.new("Frame")
        prow.Size = UDim2.new(1, 0, 0, 40)
        prow.BackgroundColor3 = C_ROW
        prow.BorderSizePixel = 0
        prow.LayoutOrder = nextOrder()
        prow.Parent = sP
        corner(prow, 8)

        local ptitle = Instance.new("TextLabel")
        ptitle.Size = UDim2.new(1, -20, 0, 16)
        ptitle.Position = UDim2.new(0, 10, 0, 5)
        ptitle.BackgroundTransparency = 1
        ptitle.Text = "Throw Power"
        ptitle.TextColor3 = Color3.new(1, 1, 1)
        ptitle.Font = Enum.Font.GothamBold
        ptitle.TextSize = 12
        ptitle.TextXAlignment = Enum.TextXAlignment.Left
        ptitle.Parent = prow

        local pinfo = Instance.new("TextLabel")
        pinfo.Size = UDim2.new(1, -20, 0, 14)
        pinfo.Position = UDim2.new(0, 10, 0, 22)
        pinfo.BackgroundTransparency = 1
        pinfo.Text = "Pick a target, then press Set"
        pinfo.TextColor3 = C_GRAY
        pinfo.Font = Enum.Font.Gotham
        pinfo.TextSize = 9
        pinfo.TextXAlignment = Enum.TextXAlignment.Left
        pinfo.TextTruncate = Enum.TextTruncate.AtEnd
        pinfo.Parent = prow

        local crow = Instance.new("Frame")
        crow.Size = UDim2.new(1, 0, 0, 32)
        crow.BackgroundColor3 = C_ROW
        crow.BorderSizePixel = 0
        crow.LayoutOrder = nextOrder()
        crow.Parent = sP
        corner(crow, 8)

        local function mk(cls, pos, size, text, color)
            local b = Instance.new(cls)
            b.Position = pos
            b.Size = size
            b.BackgroundColor3 = color
            b.Text = text
            b.TextColor3 = Color3.new(1, 1, 1)
            b.Font = Enum.Font.GothamBold
            b.TextSize = 11
            b.Parent = crow
            corner(b, 6)
            return b
        end
        local prevBtn = mk("TextButton", UDim2.new(0, 8, 0.5, -12), UDim2.new(0, 28, 0, 24), "<", C_BG)
        local areaLbl = mk("TextLabel", UDim2.new(0, 40, 0.5, -12), UDim2.new(1, -134, 0, 24), "", C_BG)
        local nextBtn = mk("TextButton", UDim2.new(1, -90, 0.5, -12), UDim2.new(0, 28, 0, 24), ">", C_BG)
        local setBtn = mk("TextButton", UDim2.new(1, -58, 0.5, -12), UDim2.new(0, 46, 0, 24), "Set", Color3.fromRGB(60, 130, 220))

        local function refresh()
            local a = AREAS[idx]
            if a[2] == "MAX" then
                areaLbl.Text = "MAX"
            else
                areaLbl.Text = a[1] .. "  (" .. tostring(a[2] - MARGIN) .. ")"
            end
        end
        refresh()

        prevBtn.MouseButton1Click:Connect(function()
            idx = (idx - 2) % #AREAS + 1
            refresh()
        end)
        nextBtn.MouseButton1Click:Connect(function()
            idx = idx % #AREAS + 1
            refresh()
        end)

        local busy = false
        setBtn.MouseButton1Click:Connect(function()
            if busy then return end
            busy = true
            local nama, val = AREAS[idx][1], AREAS[idx][2]
            pinfo.Text = "Sending..."
            pinfo.TextColor3 = C_GRAY
            task.spawn(function()
                local mx = readMax()
                if val == "MAX" then
                    if not mx then
                        pinfo.Text = "Can't read max power, open the Throw Power slider"
                        pinfo.TextColor3 = C_WARN
                        busy = false
                        return
                    end
                    val = mx
                else
                    val = val - MARGIN
                    if mx and val >= mx then val = mx - MARGIN end
                end

                local pw, gagal
                for step = 0, 3 do
                    local ok, res = pcall(function()
                        return R.Player_SetThrowPower:InvokeServer(val - step)
                    end)
                    if not ok then
                        gagal = "remote call failed"
                        break
                    end
                    if typeof(res) == "table" and res.Ok == false then
                        gagal = "rejected: " .. tostring(res.Reason)
                        break
                    end
                    local got = typeof(res) == "table" and tonumber(res.Power) or nil
                    if got and got > 0 then
                        pw = got
                        break
                    end
                end

                if pw then
                    local a = areaDari(pw)
                    pinfo.Text = "Power " .. tostring(pw) .. (a and ("  |  Lands in: " .. a) or "")
                    pinfo.TextColor3 = C_GOOD
                else
                    pinfo.Text = "Failed: " .. (gagal or "server replied power 0")
                    pinfo.TextColor3 = C_WARN
                end
                busy = false
            end)
        end)
    end

    -- Auto Index
    groupTitle(p, "Index")
    do
        local RS = game:GetService("ReplicatedStorage")

        -- modul game dimuat saat dibutuhkan (bukan saat script dimuat), supaya tidak error
        -- kalau game belum selesai memuat, misalnya setelah pindah server
        local DC, AC, eco
        local MARGIN = 20         -- jarak aman dari ujung area
        local THROWS_PER_TRY = 20 -- lemparan per power sebelum coba power lain
        local STUCK_THROWS = 300  -- lemparan tanpa hewan baru sebelum area dilewati

        -- rotasi makanan per Tier: tiap tier dipakai makanan paling ujungnya (Index tertinggi yang dimiliki)
        local ULANG_PER_TIER = 1 -- 2 = tiap tier dipakai 2 batch berturut-turut (1,1,2,2,...)
        local LEMPAR_PER_MAKANAN = 15
        local polaIdx, lastFoodTh, failFood = 0, nil, 0
        local foodSekarang, foodAwal = nil, nil
        local FC

        local function muatFoods()
            if FC then return true end
            local ok, m = pcall(require, RS.Config.FoodsConfig)
            if ok and type(m) == "table" and type(m.List) == "table" then
                FC = m
                return true
            end
            return false
        end

        local function tierMax()
            if not muatFoods() then return nil end
            local mx = 0
            for _, f in pairs(FC.List) do
                if type(f) == "table" and (tonumber(f.Tier) or 0) > mx then mx = tonumber(f.Tier) end
            end
            return mx > 0 and mx or nil
        end

        local function makananTier(t, owned)
            local best
            for _, f in pairs(FC.List) do
                if type(f) == "table" and f.Tier == t and f.Index then
                    local punya = (not owned) or owned[f.Index] or owned[tostring(f.Index)]
                    if punya and (not best or f.Index > best) then best = f.Index end
                end
            end
            return best
        end

        local function pakaiMakanan(n)
            if foodSekarang == n then return true end
            local ok, res = pcall(function() return R.Shop_Equip:InvokeServer(n) end)
            if not ok then return false end
            if typeof(res) == "table" and res.Ok == false then
                if not tostring(res.Reason):lower():find("already") then return false end
            end
            foodSekarang = n
            foodEquipped = n
            return true
        end

        local function putarMakanan(th, owned)
            if lastFoodTh and th - lastFoodTh < LEMPAR_PER_MAKANAN then return end
            local maxT = tierMax()
            if not maxT then return end
            local total = maxT * ULANG_PER_TIER
            local t = math.floor((polaIdx % total) / ULANG_PER_TIER) + 1
            local n = makananTier(t, owned)
            if n and pakaiMakanan(n) then
                polaIdx = polaIdx % total + 1
                lastFoodTh = th
                failFood = 0
                setStatus("Auto Index: tier " .. t .. " (#" .. n .. ")", C_GRAY)
            else
                failFood += 1
                if not n or failFood >= 3 then -- tier itu belum dimiliki / ditolak: lewati
                    polaIdx = polaIdx % total + 1
                    failFood = 0
                end
            end
        end

        local setIndex
        local indexRun, mulaiThrow = 0, false
        local function aktif(token)
            return State.AutoIndex and indexRun == token and getgenv().__ThrowToken == myToken
        end

        local sI = section(p, "auto index hewan koleksi")
        switchRow(sI, "Auto Index", "Hunts animals missing from your Index", "AutoIndex", function(on) setIndex(on) end)

        local irow = Instance.new("Frame")
        irow.Size = UDim2.new(1, 0, 0, 26)
        irow.BackgroundColor3 = C_ROW
        irow.BorderSizePixel = 0
        irow.LayoutOrder = nextOrder()
        irow.Parent = sI
        irow.Visible = TAMPILKAN_STATUS
        if not TAMPILKAN_STATUS then irow.Size = UDim2.new(1, 0, 0, 0) end
        corner(irow, 8)
        local ilbl = Instance.new("TextLabel")
        ilbl.Size = UDim2.new(1, -20, 1, 0)
        ilbl.Position = UDim2.new(0, 10, 0, 0)
        ilbl.BackgroundTransparency = 1
        ilbl.Text = "Auto Index belum dijalankan"
        ilbl.TextColor3 = C_GRAY
        ilbl.Font = Enum.Font.Gotham
        ilbl.TextSize = 9
        ilbl.TextXAlignment = Enum.TextXAlignment.Left
        ilbl.TextTruncate = Enum.TextTruncate.AtEnd
        ilbl.Parent = irow

        local function info(t, color)
            ilbl.Text = t
            ilbl.TextColor3 = color or C_GRAY
        end

        local function muat()
            if DC and AC and eco then return true end

            local function ambil(label, getter)
                info("Memuat " .. label .. "...", C_GRAY)
                local obj
                local t0 = os.clock()
                while os.clock() - t0 < 20 do
                    local ok, o = pcall(getter)
                    if ok and o then obj = o break end
                    task.wait(0.5)
                end
                if not obj then
                    info(label .. " tidak ditemukan", C_WARN)
                    return nil
                end
                local hasil, selesai = nil, false
                task.spawn(function()
                    local ok, m = pcall(require, obj)
                    if ok then hasil = m end
                    selesai = true
                end)
                local t1 = os.clock()
                while not selesai and os.clock() - t1 < 15 do task.wait(0.2) end
                if not hasil then info(label .. " gagal dimuat", C_WARN) end
                return hasil
            end

            DC = DC or ambil("DataController", function()
                return lp.PlayerScripts.Client.Controllers.DataController
            end)
            if not DC then return false end
            AC = AC or ambil("AreasConfig", function() return RS.Config.AreasConfig end)
            if not AC then return false end
            eco = eco or ambil("AnimalEconomy", function() return RS.Config.AnimalEconomy end)
            return (DC and AC and eco) and true or false
        end

        local function ambilData()
            if not DC then return nil end
            local ok, data = pcall(function() return DC.GetPlayerData() end)
            if ok and typeof(data) == "table" then return data end
            return nil
        end

        local function hewanArea(a)
            local nama = {}
            local k1, k2 = popNorm(a.Key), popNorm(a.Name)
            for n, d in pairs(eco.List) do
                if type(d) == "table" and d.Area ~= nil then
                    local ar = popNorm(d.Area)
                    if ar == k1 or ar == k2 then nama[#nama + 1] = n end
                end
            end
            return nama
        end

        local function kurang(a, idxT)
            local miss = {}
            local semua = hewanArea(a)
            for _, n in ipairs(semua) do
                if not idxT[n] then miss[#miss + 1] = n end
            end
            return miss, #semua
        end

        -- daftar power yang dicoba, dimulai dari tebakan rank hewan yang kurang
        local function kandidat(a, miss)
            local segLen = a.Length / a.Segments
            local lo = math.max(a.StartDistance, 26)
            local hi = a.StartDistance + a.Length - 1 - MARGIN
            local list, seen = {}, {}
            local function tambah(p)
                p = math.clamp(math.floor(p), lo, hi)
                if not seen[p] then
                    seen[p] = true
                    list[#list + 1] = p
                end
            end
            for _, nama in ipairs(miss) do
                local d = eco.List[nama]
                local r = d and d.Rank or 1
                local s = math.clamp(math.ceil(r * a.Segments / 8), 1, a.Segments)
                tambah(a.StartDistance + (s - 0.5) * segLen)
            end
            tambah(hi)
            for s = a.Segments, 1, -1 do tambah(a.StartDistance + (s - 0.5) * segLen) end
            return list
        end

        -- kirim power ke server; kembalian: true + power dari server, atau false + alasan
        local function setPower(v)
            local okc, res = pcall(function() return R.Player_SetThrowPower:InvokeServer(v) end)
            if not okc then return false, "remote error" end
            if typeof(res) ~= "table" then return false, "balasan " .. tostring(res) end
            if res.Ok == false then return false, tostring(res.Reason) end
            local pw = tonumber(res.Power) or 0
            if pw <= 0 then return false, "power 0" end
            return true, pw
        end

        -- server bisa menolak saat sesi lempar berjalan: coba berulang, lalu jeda lempar sebentar
        local pausing = false
        local function pasangPower(v, token)
            local alasan
            for _ = 1, 8 do
                local ok, hasil = setPower(v)
                if ok then return true, hasil end
                alasan = hasil
                task.wait(0.3)
            end
            pausing = true
            throwPause = true
            local t0 = os.clock()
            while throwing and os.clock() - t0 < 20 and aktif(token) do task.wait(0.2) end
            pcall(restoreLook)
            local ok, hasil = setPower(v)
            task.wait(0.6)
            throwPause = false
            if aktif(token) and not throwing then task.spawn(throwLoop) end
            pausing = false
            if ok then return true, hasil end
            setPower(26) -- jangan biarkan power tertinggal 0
            return false, hasil or alasan
        end

        -- true = area penuh, false = macet, nil = dihentikan
        local function farmArea(a, miss, maxP, token)
            local cands = kandidat(a, miss)
            local stuckBatas = math.clamp(#cands * THROWS_PER_TRY, STUCK_THROWS, 800)
            local sisa = #miss
            local d0 = ambilData()
            local lastGain = d0 and tonumber(d0.Throws) or 0 -- hitungan lemparan saat terakhir dapat hewan baru
            local ci, gagal = 0, 0
            while aktif(token) do
                ci = ci % #cands + 1
                local pwr = cands[ci]
                local okP, hasilP = false, "melebihi power maksimal"
                if pwr < maxP then okP, hasilP = pasangPower(pwr, token) end
                if not aktif(token) then return nil end
                if okP then
                    gagal = 0
                    info(a.Name .. ": power " .. tostring(hasilP) .. " | kurang " .. sisa, C_GRAY)
                    local d1 = ambilData()
                    local mulai = d1 and tonumber(d1.Throws) or lastGain
                    local lastTh, gerak, tCand = mulai, os.clock(), os.clock()
                    while aktif(token) do
                        task.wait(1)
                        if State.AutoTrain then
                            applyState("AutoIndex", false)
                            info("Auto Training menyala, Auto Index dihentikan", C_WARN)
                            return nil
                        end
                        if not throwing and not pausing then task.spawn(throwLoop) end
                        local d = ambilData()
                        if d then
                            local th = tonumber(d.Throws) or lastTh
                            putarMakanan(th, d.OwnedFoods)
                            local m2 = kurang(a, d.Index or {})
                            if #m2 < sisa then
                                sisa = #m2
                                lastGain = th
                                mulai = th
                                tCand = os.clock()
                                info(a.Name .. ": hewan baru, kurang " .. sisa, C_GOOD)
                                if sisa == 0 then return true end
                            end
                            if th > lastTh then
                                lastTh = th
                                gerak = os.clock()
                            end
                            if th - lastGain >= stuckBatas then return false end
                            if th - mulai >= THROWS_PER_TRY then break end
                        end
                        if os.clock() - gerak > 120 then
                            info(a.Name .. ": lemparan tidak jalan, cek makanan/uang", C_WARN)
                            gerak = os.clock()
                        end
                        if os.clock() - tCand > 180 then break end
                    end
                else
                    gagal = gagal + 1
                    info(a.Name .. ": gagal set power (" .. tostring(hasilP) .. ")", C_WARN)
                    if gagal >= #cands then return false end
                    task.wait(1)
                end
            end
            return nil
        end

        local function loopIndex(token)
            info("Memuat data game...", C_GRAY)
            if not muat() then
                if State.AutoIndex then applyState("AutoIndex", false) end
                info("Data game tidak terbaca (game belum selesai dimuat?)", C_WARN)
                return
            end
            info("Data game siap", C_GRAY)
            local lewat = {}
            local jalan = false
            while aktif(token) do
                jalan = true
                info("Membaca data pemain...", C_GRAY)
                local data = ambilData()
                if not data then
                    info("Data pemain belum siap...", C_GRAY)
                    task.wait(3)
                else
                    local idxT = data.Index or {}
                    local maxP = bacaMax(data)
                    if not maxP then
                        applyState("AutoIndex", false)
                        info("Power maksimal tidak terbaca", C_WARN)
                        return
                    end
                    local target, miss
                    local punya, semua = 0, 0
                    info("Menghitung Index...", C_GRAY)
                    for _, a in ipairs(AC.List) do
                        local m, tot = kurang(a, idxT)
                        semua = semua + tot
                        punya = punya + (tot - #m)
                        if not target and #m > 0 and not lewat[a.Key] and a.StartDistance < maxP then
                            target, miss = a, m
                        end
                    end
                    if not target then
                        local n = 0
                        for _ in pairs(lewat) do n = n + 1 end
                        applyState("AutoIndex", false)
                        info("Selesai: Index " .. punya .. "/" .. semua
                            .. (n > 0 and (" | " .. n .. " area dilewati") or ""), C_GOOD)
                        return
                    end
                    info("Index " .. punya .. "/" .. semua .. " | target " .. target.Name, C_GRAY)
                    local hasil = farmArea(target, miss, maxP, token)
                    if hasil == false then lewat[target.Key] = true end
                end
            end
            if not jalan then info("Auto Index berhenti sebelum jalan", C_WARN) end
        end

        setIndex = function(on)
            indexRun = indexRun + 1
            if on then
                if State.AutoTrain then
                    forceOff("AutoIndex")
                    info("Matikan Auto Training dulu", C_WARN)
                    return
                end
                if State.AutoThrow then forceOff("AutoThrow") end
                local d0 = ambilData()
                foodAwal = d0 and tonumber(d0.EquippedFood) or nil
                foodSekarang, polaIdx, lastFoodTh, failFood = nil, 0, nil, 0
                info("Memulai Auto Index...", C_GRAY)
                task.spawn(function(token)
                    local ok, err = pcall(loopIndex, token)
                    if not ok then
                        if State.AutoIndex then applyState("AutoIndex", false) end
                        info("Error: " .. tostring(err), C_WARN)
                        warn("[AutoIndex] " .. tostring(err))
                    end
                end, indexRun)
            else
                info("Auto Index berhenti", C_GRAY)
                task.spawn(function()
                    local t0 = os.clock()
                    while throwing and os.clock() - t0 < 12 do task.wait(0.2) end
                    if foodAwal then
                        pcall(function() R.Shop_Equip:InvokeServer(foodAwal) end)
                        foodEquipped = foodAwal
                        foodSekarang = nil
                    end
                    if not State.AutoThrow then restoreLook() end
                end)
            end
        end
    end

    groupTitle(p, "Food")
    local s2 = section(p, "auto buy food makanan beli")
    switchRow(s2, "Auto Buy Food", "Buys the next food when you can afford it", "AutoBuyFood", function(on)
        if on then startFnLoop("AutoBuyFood", FOOD_EVERY, buyFood) end
    end)

    local s3 = section(p, "auto equip best food makanan")
    switchRow(s3, "Auto Equip Best Food", "Equips the best food you own", "AutoEquipFood", function(on)
        if on then startFnLoop("AutoEquipFood", FOOD_EVERY, equipBestFood) end
    end)
end

-- TRAINING
do
    local p = pages.Training
    groupTitle(p, "Training")
    local s1 = section(p, "auto training latihan tap bonus")
    switchRow(s1, "Auto Training", "Trains and taps the bonus automatically", "AutoTrain", setTrain)

    groupTitle(p, "Upgrade")
    local s2 = section(p, "auto upgrade bar stand")
    switchRow(s2, "Auto Upgrade Bar", "Upgrades the training bar every 10s", "AutoBar", function(on)
        if on then startFnLoop("AutoBar", UPGRADE_EVERY, upgradeBar) end
    end)
end

-- ===== PRIORITAS EQUIP BEST =====
local petBusy = false
local function petCall(remoteName, label)
    while petBusy do task.wait(0.2) end
    petBusy = true
    pcall(callOnce, remoteName, label)
    petBusy = false
end

-- SELL
do
    local p = pages.Sell
    groupTitle(p, "Sell")
    local s1 = section(p, "auto sell jual")
    switchRow(s1, "Auto Sell", "Sells small animals every 60s (pen is safe)", "AutoSell", function(on)
        if on then
            startFnLoop("AutoSell", SELL_EVERY, function()
                if State.AutoEquip then
                    petCall("Plot_EquipBest", "Equip Best")
                    task.wait(1)
                end
                petCall("Plot_SellAll", "Sell All")
            end)
        end
    end)
end

-- PET
do
    local p = pages.Pet
    groupTitle(p, "Pet")
    local s1 = section(p, "auto equip best hewan pet")
    switchRow(s1, "Auto Equip Best", "Equips your best animals every 30s", "AutoEquip", function(on)
        if on then
            startFnLoop("AutoEquip", EQUIP_EVERY, function()
                petCall("Plot_EquipBest", "Equip Best")
            end)
        end
    end)

    groupTitle(p, "Plot")
    local s2 = section(p, "auto upgrade plot kandang fence")
    switchRow(s2, "Auto Upgrade Plot", "Upgrades pen capacity every 10s", "AutoFence", function(on)
        if on then startLoop("AutoFence", "Plot_UpgradeFence", UPGRADE_EVERY, "Upgrade Plot") end
    end)
end

-- MISC: Config, Auto Load Config, Visual, Other
do
    local p = pages.Misc
    local selected
    local selDD, autoTitle

    -- WEBHOOK (kirim hewan ke Discord)
    do
        local StarterGui = game:GetService("StarterGui")
        local WH_FILE = "ThrowForAnimals_webhook.json"
        local req = request or http_request or (syn and syn.request) or (http and http.request)
        local SFX = {}
        for i = 2, #POP_SFX do SFX[POP_SFX[i]:upper()] = 10 ^ (3 * (i - 1)) end

        local cfg = { url = "", min = "", on = false }
        if isfile and readfile and isfile(WH_FILE) then
            local ok, d = pcall(function() return HttpService:JSONDecode(readfile(WH_FILE)) end)
            if ok and type(d) == "table" then
                cfg.url = tostring(d.url or "")
                cfg.min = tostring(d.min or "")
                cfg.on = d.on == true
            end
        end
        local function simpan()
            if writefile then pcall(writefile, WH_FILE, HttpService:JSONEncode(cfg)) end
        end
        local function notif(t, x)
            pcall(function()
                StarterGui:SetCore("SendNotification", { Title = t, Text = x, Duration = 4 })
            end)
        end
        local lastWarn = 0
        local function gagal(x)
            if os.clock() - lastWarn > 30 then
                lastWarn = os.clock()
                notif("Webhook", x)
            end
        end
        local function urlValid(u)
            return u:match("^https://[%w%.]*discord%.com/api/webhooks/%d+/[%w%-_]+") ~= nil
                or u:match("^https://[%w%.]*discordapp%.com/api/webhooks/%d+/[%w%-_]+") ~= nil
        end
        local function parseNilai(s)
            s = tostring(s or ""):gsub("[%s,]", ""):upper()
            local n = tonumber(s)
            if n then return n end
            local num, suf = s:match("^([%d%.]+)(%a+)$")
            num = tonumber(num)
            local m = SFX[suf or ""]
            if num and m then return num * m end
            return nil
        end

        State.Webhook = cfg.on and req ~= nil and urlValid(cfg.url)
        local minNilai = parseNilai(cfg.min) or 0

        groupTitle(p, "Webhook")
        local sw = section(p, "webhook discord hewan notif")
        switchRow(sw, "Webhook", "Sends animals at or above Min. Value to Discord", "Webhook", function(on)
            if on and not req then
                State.Webhook = false
                if switchRefresh.Webhook then switchRefresh.Webhook(true) end
                notif("Webhook", "Your executor does not support HTTP requests")
                return
            end
            if on and not urlValid(cfg.url) then
                State.Webhook = false
                if switchRefresh.Webhook then switchRefresh.Webhook(true) end
                notif("Webhook", "Set a valid webhook URL first")
                return
            end
            cfg.on = on
            simpan()
        end)

        -- URL Webhook dan Min. Value sebaris; kotak isi penuh sampai ujung barisnya
        local sebaris = Instance.new("Frame")
        sebaris.Size = UDim2.new(1, 0, 0, 54)
        sebaris.BackgroundTransparency = 1
        sebaris.LayoutOrder = nextOrder()
        sebaris.Parent = sw
        local sl = Instance.new("UIListLayout", sebaris)
        sl.FillDirection = Enum.FillDirection.Horizontal
        sl.Padding = UDim.new(0, 6)
        sl.SortOrder = Enum.SortOrder.LayoutOrder

        local urlBox = textBoxRow(sebaris, "URL Webhook", "Paste webhook URL")
        urlBox.Parent.Size = UDim2.new(0.62, -3, 0, 54)
        urlBox.Text = cfg.url
        urlBox.FocusLost:Connect(function()
            local u = urlBox.Text:gsub("%s", "")
            if u == cfg.url then
                urlBox.Text = u
                return
            end
            if u ~= "" and not urlValid(u) then
                notif("Webhook", "Invalid webhook URL")
                urlBox.Text = cfg.url
                return
            end
            urlBox.Text = u
            cfg.url = u
            if u == "" and State.Webhook then
                State.Webhook = false
                cfg.on = false
                if switchRefresh.Webhook then switchRefresh.Webhook(true) end
            end
            simpan()
        end)

        local minBox = textBoxRow(sebaris, "Min. Value", "500K, 1.5M, 2B")
        minBox.Parent.Size = UDim2.new(0.38, -3, 0, 54)
        minBox.Text = cfg.min
        minBox.FocusLost:Connect(function()
            local t = minBox.Text:gsub("%s", "")
            if t == "" then
                cfg.min = ""
                minNilai = 0
                simpan()
                return
            end
            local n = parseNilai(t)
            if not n then
                notif("Webhook", "Invalid Min. Value, example: 500K or 1.5M")
                minBox.Text = cfg.min
                return
            end
            cfg.min = t
            minNilai = n
            simpan()
        end)

        -- cari angka income di hasil lemparan; nama field dicoba satu per satu
        local INCOME_KEYS = { "income", "value", "worth" }
        local function bacaIncome(r)
            local n = tonumber(r.Income or r.IncomePerSecond)
            if n then return n end
            for _, key in ipairs(INCOME_KEYS) do
                for k, v in pairs(r) do
                    if tostring(k):lower():find(key, 1, true) and tonumber(v) then return tonumber(v) end
                end
            end
            return nil
        end

        -- dipanggil dari doThrow tiap ada hasil lemparan
        getgenv().__TFAWebhook = function(r)
            if not State.Webhook or typeof(r) ~= "table" or not req then return end
            if not urlValid(cfg.url) then return end
            local income = bacaIncome(r)
            if income and income < minNilai then return end -- income tidak terbaca: tetap dikirim

            local varian, ukuran = popBaca(r)
            local rarity = tostring(r.Rarity or "?")
            local c = POP_RARITY[rarity:lower()]
            local warna = c and (math.floor(c.R * 255) * 65536 + math.floor(c.G * 255) * 256 + math.floor(c.B * 255)) or 5793266
            local body = HttpService:JSONEncode({
                username = "Throw For Animals",
                avatar_url = ICON_URL,
                embeds = { {
                    title = tostring(r.DisplayName or "?"),
                    color = warna,
                    fields = {
                        { name = "Rarity", value = rarity, inline = true },
                        { name = "Income", value = income and popFmt(income) or "?", inline = true },
                        { name = "Variant", value = varian or "-", inline = true },
                        { name = "Size", value = ukuran or "-", inline = true },
                        { name = "Account", value = lp.Name, inline = true },
                    },
                    footer = { text = "Throw For Animals V1.5", icon_url = ICON_URL },
                    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                } },
            })
            task.spawn(function()
                local ok, res = pcall(req, { Url = cfg.url, Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" }, Body = body })
                if not ok then
                    gagal("Failed to send to Discord")
                elseif type(res) == "table" and tonumber(res.StatusCode)
                    and (res.StatusCode < 200 or res.StatusCode >= 300) then
                    gagal("Discord replied " .. tostring(res.StatusCode))
                end
            end)
        end
    end

    local function names()
        local list = {}
        for k in pairs(cfgData.configs) do list[#list + 1] = k end
        table.sort(list)
        return list
    end

    local function autoName()
        local n = cfgData.autoload
        if n and cfgData.configs[n] then return n end
        return nil
    end

    -- baris status config hanya menampilkan status Auto Load
    local function tampilAuto()
        if not cfgStatusLbl then return end
        local n = autoName()
        cfgStatusLbl.Text = n and ("Active : " .. n) or "Inactive"
        cfgStatusLbl.TextColor3 = n and C_GOOD or C_GRAY
    end

    local function cfgStatus() tampilAuto() end -- pesan lain tidak ditampilkan

    local function refreshAuto()
        autoTitle.Text = "Auto Load Config"
        autoTitle.TextColor3 = Color3.new(1, 1, 1)
        tampilAuto()
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

    autoTitle = groupTitle(p, "Auto Load Config")
    local c5 = section(p, "status config")
    cfgStatusLbl = infoRow(c5, "Inactive")
    local c4 = section(p, "auto load config set delete")
    buttonsRow(c4, {
        { "Set", function()
            if not selected or not cfgData.configs[selected] then return end
            cfgData.autoload = selected
            writeCfgFile()
            refreshAuto()
        end },
        { "Delete", function()
            cfgData.autoload = nil
            writeCfgFile()
            refreshAuto()
        end, C_RED },
    })
    refreshAuto()

    groupTitle(p, "Visual")
    local v1 = section(p, "esp player pemain lain")
    switchRow(v1, "ESP Player", "Shows player names and distance", "ESPPlayer", setESP)

    local v3 = section(p, "invisible karakter")
    switchRow(v3, "Invisible", "Hides your character (client side)", "Invisible", setInvisible)

    groupTitle(p, "Other")
    local o1 = section(p, "auto execute")
    switchRow(o1, "Auto Execute", "Re-runs the script after a rejoin or teleport", "AutoExec", setAutoExec)
    local erow = Instance.new("Frame")
    erow.Size = UDim2.new(1, 0, 0, 26)
    erow.BackgroundColor3 = C_ROW
    erow.BorderSizePixel = 0
    erow.LayoutOrder = nextOrder()
    erow.Parent = o1
    erow.Visible = TAMPILKAN_STATUS
    if not TAMPILKAN_STATUS then erow.Size = UDim2.new(1, 0, 0, 0) end
    corner(erow, 8)
    execLbl = Instance.new("TextLabel")
    execLbl.Size = UDim2.new(1, -20, 1, 0)
    execLbl.Position = UDim2.new(0, 10, 0, 0)
    execLbl.BackgroundTransparency = 1
    execLbl.Text = State.AutoExec and "Auto Execute aktif" or "Auto Execute mati"
    execLbl.TextColor3 = C_GRAY
    execLbl.Font = Enum.Font.Gotham
    execLbl.TextSize = 9
    execLbl.TextXAlignment = Enum.TextXAlignment.Left
    execLbl.TextTruncate = Enum.TextTruncate.AtEnd
    execLbl.Parent = erow

    local o2 = section(p, "anti afk")
    switchRow(o2, "Anti AFK", "Prevents idle kicks", "AntiAfk", setAntiAfk)

    -- Auto Reconnect
    do
        local GuiService = game:GetService("GuiService")
        local TeleportService = game:GetService("TeleportService")
        local setAR
        local conns, percobaan, sedang = {}, {}, false

        local o3 = section(p, "auto reconnect masuk lagi terputus kick disconnect")
        switchRow(o3, "Auto Reconnect", "Rejoins if you disconnect or get kicked", "AutoReconnect", function(on) setAR(on) end)

        local rrow = Instance.new("Frame")
        rrow.Size = UDim2.new(1, 0, 0, 26)
        rrow.BackgroundColor3 = C_ROW
        rrow.BorderSizePixel = 0
        rrow.LayoutOrder = nextOrder()
        rrow.Parent = o3
        rrow.Visible = TAMPILKAN_STATUS
        if not TAMPILKAN_STATUS then rrow.Size = UDim2.new(1, 0, 0, 0) end
        corner(rrow, 8)
        local arLbl = Instance.new("TextLabel")
        arLbl.Size = UDim2.new(1, -20, 1, 0)
        arLbl.Position = UDim2.new(0, 10, 0, 0)
        arLbl.BackgroundTransparency = 1
        arLbl.Text = "Auto Reconnect mati"
        arLbl.TextColor3 = C_GRAY
        arLbl.Font = Enum.Font.Gotham
        arLbl.TextSize = 9
        arLbl.TextXAlignment = Enum.TextXAlignment.Left
        arLbl.TextTruncate = Enum.TextTruncate.AtEnd
        arLbl.Parent = rrow

        local function info(t, color)
            arLbl.Text = t
            arLbl.TextColor3 = color or C_GRAY
        end

        local function reconnect(alasan)
            if sedang or not State.AutoReconnect then return end
            if getgenv().__ThrowToken ~= myToken then return end
            sedang = true

            -- maksimal 5 percobaan dalam 5 menit, supaya tidak berputar terus
            local now = os.clock()
            local baru = {}
            for _, t in ipairs(percobaan) do
                if now - t < 300 then baru[#baru + 1] = t end
            end
            percobaan = baru
            if #percobaan >= 5 then
                sedang = false
                applyState("AutoReconnect", false)
                info("Gagal masuk lagi 5 kali, Auto Reconnect dihentikan", C_WARN)
                return
            end
            percobaan[#percobaan + 1] = now
            info("Terputus: " .. tostring(alasan):sub(1, 40) .. " | masuk lagi...", C_WARN)

            -- simpan status dan daftarkan script supaya jalan lagi setelah masuk
            pcall(saveLastState)
            local qot = queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
            if qot and not queuedThisRun then
                tulisFlag(true)
                if pcall(qot, buildQueued()) then queuedThisRun = true end
            end

            task.wait(3 + #percobaan * 2)
            if State.AutoReconnect then
                pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
            end
            task.wait(45)
            sedang = false -- kalau masih di sini, boleh coba lagi
        end

        local function putus()
            for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
            conns = {}
        end

        setAR = function(on)
            putus()
            if not on then
                info("Auto Reconnect mati", C_GRAY)
                return
            end
            conns[#conns + 1] = GuiService.ErrorMessageChanged:Connect(function()
                local msg = GuiService:GetErrorMessage()
                if msg ~= "" then task.spawn(reconnect, msg) end
            end)
            local ok, overlay = pcall(function()
                return game:GetService("CoreGui").RobloxPromptGui.promptOverlay
            end)
            if ok and overlay then
                conns[#conns + 1] = overlay.ChildAdded:Connect(function(c)
                    if c.Name == "ErrorPrompt" then task.spawn(reconnect, "error prompt") end
                end)
            end
            info("Auto Reconnect aktif", C_GOOD)
            local sekarang = GuiService:GetErrorMessage()
            if sekarang ~= "" then task.spawn(reconnect, sekarang) end
        end
    end

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
    local wasThrow = State.AutoThrow or State.AutoIndex
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
setAutoExec(State.AutoExec, true)
setTab("Main")

-- User (total akun) + Online (yang sedang menjalankan script)
task.spawn(function()
    while gui.Parent do
        local n = fetchTotalUsers()
        if usersLbl and usersLbl.Parent then
            usersLbl.Text = "User : " .. (n and tostring(n) or "-")
        end
        task.wait(60)
    end
end)

task.spawn(function()
    local BUCKET = 120
    local lastPinged
    while gui.Parent do
        local b = math.floor(DateTime.now().UnixTimestamp / BUCKET)
        if b ~= lastPinged then
            local v = counterCall("/hit/" .. COUNTER_NS .. "/o" .. b .. userKey())
            if v then
                lastPinged = b
                if v == 1 then
                    for _ = 1, 3 do
                        if counterCall("/hit/" .. COUNTER_NS .. "/on" .. b) then break end
                        task.wait(2)
                    end
                end
            end
        end
        local cur = counterCall("/get/" .. COUNTER_NS .. "/on" .. b)
        local prev = counterCall("/get/" .. COUNTER_NS .. "/on" .. (b - 1))
        local n = math.max(cur or 0, prev or 0)
        if onlineLbl and onlineLbl.Parent then
            onlineLbl.Text = "Online : " .. (n > 0 and tostring(n) or "-")
        end
        task.wait(60)
    end
end)

local fromTeleport = getgenv().ThrowAutoStart
getgenv().ThrowAutoStart = nil
local autoLoadFn = getgenv().__TFAAutoLoad
getgenv().__TFAAutoLoad = nil

if fromTeleport then
    -- dijalankan otomatis setelah pindah server: pulihkan status terakhir
    task.spawn(function()
        local t0 = os.clock()
        repeat task.wait(0.5) until (lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")) or os.clock() - t0 > 30
        task.wait(2)
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
