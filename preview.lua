-- PREVIEW CONFIG UI | Throw For Animals [BETA] by D33RZN
-- Tampilan saja. Tidak memanggil remote game dan tidak menulis file.
local UIS = game:GetService("UserInputService")
local lp = game:GetService("Players").LocalPlayer

if getgenv().ConfigPreviewUI then pcall(function() getgenv().ConfigPreviewUI:Destroy() end) end

local C_BG   = Color3.fromRGB(18, 18, 22)
local C_BAR  = Color3.fromRGB(26, 26, 32)
local C_ROW  = Color3.fromRGB(34, 34, 42)
local C_OFF  = Color3.fromRGB(70, 70, 82)
local C_RED  = Color3.fromRGB(150, 55, 55)
local C_GRAY = Color3.fromRGB(150, 150, 160)
local C_WARN = Color3.fromRGB(240, 170, 60)
local C_GOOD = Color3.fromRGB(90, 200, 120)

local function corner(inst, r) Instance.new("UICorner", inst).CornerRadius = UDim.new(0, r) end

local conns = {}
local function track(c) conns[#conns + 1] = c; return c end

-- ===== ROOT =====
local gui = Instance.new("ScreenGui")
gui.Name = "ConfigPreviewUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999
local ok = pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not ok or not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end
getgenv().ConfigPreviewUI = gui
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
minBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

do -- drag lewat title bar
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
b.Size = UDim2.new(1, 0, 0, 28)
b.Text = name
b.Font = Enum.Font.GothamBold
b.TextSize = 11
b.TextXAlignment = Enum.TextXAlignment.Left
b.LayoutOrder = order
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
local function makeLabel(parent, text, x, y, w, h, size, color, font)
local l = Instance.new("TextLabel")
l.Size = UDim2.new(w[1], w[2], 0, h)
l.Position = UDim2.new(0, x, 0, y)
l.BackgroundTransparency = 1
l.Text = text
l.TextColor3 = color or Color3.new(1, 1, 1)
l.Font = font or Enum.Font.GothamBold
l.TextSize = size or 12
l.TextXAlignment = Enum.TextXAlignment.Left
l.Parent = parent
return l
end

local function rowFrame(parent, height)
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, height)
row.BackgroundColor3 = C_ROW
row.BorderSizePixel = 0
row.LayoutOrder = #parent:GetChildren()
row.Parent = parent
corner(row, 8)
return row
end

local function groupTitle(parent, text)
local l = Instance.new("TextLabel")
l.Size = UDim2.new(1, 0, 0, 16)
l.BackgroundTransparency = 1
l.Text = text
l.TextColor3 = Color3.new(1, 1, 1)
l.Font = Enum.Font.GothamBold
l.TextSize = 12
l.TextXAlignment = Enum.TextXAlignment.Left
l.LayoutOrder = #parent:GetChildren()
l.Parent = parent
end

local function infoRow(parent, initial)
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 0)
row.AutomaticSize = Enum.AutomaticSize.Y
row.BackgroundColor3 = C_ROW
row.BorderSizePixel = 0
row.LayoutOrder = #parent:GetChildren()
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
local row = rowFrame(parent, 54)
makeLabel(row, titleText, 10, 6, { 1, -20 }, 16, 12)
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

-- deretan tombol sejajar: defs = { {teks, fungsi, warna?}, ... }
local function buttonsRow(parent, defs)
local row = Instance.new("Frame")
row.Size = UDim2.new(1, 0, 0, 30)
row.BackgroundTransparency = 1
row.LayoutOrder = #parent:GetChildren()
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
holder.LayoutOrder = #parent:GetChildren()
holder.Parent = parent
local hl = Instance.new("UIListLayout", holder)
hl.Padding = UDim.new(0, 4)
hl.SortOrder = Enum.SortOrder.LayoutOrder

local head = Instance.new("TextButton")  
head.Size = UDim2.new(1, 0, 0, 42)  
head.BackgroundColor3 = C_ROW  
head.Text = ""  
head.AutoButtonColor = false  
head.LayoutOrder = 1  
head.Parent = holder  
corner(head, 8)  
makeLabel(head, titleText, 10, 6, { 1, -40 }, 16, 12)  
local valueLbl = makeLabel(head, "Select Option", 10, 24, { 1, -40 }, 14, 10, C_GRAY, Enum.Font.Gotham)  
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
        valueLbl.TextColor3 = Color3.new(1, 1, 1)  
    else  
        valueLbl.Text = "Select Option"  
        valueLbl.TextColor3 = C_GRAY  
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

-- ===== HALAMAN SELAIN MISC (placeholder) =====
for _, t in ipairs(tabDefs) do
if t[1] ~= "Misc" then
infoRow(pages[t[1]], "Preview: isi tab " .. t[1] .. " ada di script utama.")
end
end

-- ===== MISC: CONFIG (data hanya di memori) =====
local misc = pages.Misc
local configs = { ["Farm AFK"] = true, ["Throw Only"] = true }   -- contoh
local selected, autoSel, autoName = nil, nil, nil
local statusLbl, autoLbl, selDD, autoDD

local function names()
local list = {}
for k in pairs(configs) do list[#list + 1] = k end
table.sort(list)
return list
end

local function setStatus(t, color)
if statusLbl then
statusLbl.Text = t
statusLbl.TextColor3 = color or C_GRAY
end
end

local function refreshAuto()
if autoName then
autoLbl.Text = "Auto Load aktif: " .. autoName
autoLbl.TextColor3 = C_GOOD
else
autoLbl.Text = "Kosong (Auto Load tidak aktif)"
autoLbl.TextColor3 = C_GRAY
end
end

groupTitle(misc, "Config")
local nameBox = textBoxRow(misc, "Config Name", "Write config name here")
selDD = makeDropdown(misc, "Select Config", names, function(n)
selected = n
nameBox.Text = n
end)

buttonsRow(misc, {
{ "Save Config", function()
local n = (nameBox.Text or ""):match("^%s*(.-)%s*$")
if n == "" then n = selected end
if not n or n == "" then
setStatus("Isi nama config dulu", C_WARN)
return
end
configs[n] = true
selected = n
selDD.setValue(n)
nameBox.Text = n
setStatus("Config '" .. n .. "' disimpan (preview)", C_GOOD)
end },
{ "Load Config", function()
if not selected then
setStatus("Pilih config dulu", C_WARN)
return
end
setStatus("Config '" .. selected .. "' dimuat (preview)", C_GOOD)
end },
{ "Delete Config", function()
if not selected then
setStatus("Pilih config dulu", C_WARN)
return
end
local gone = selected
configs[gone] = nil
if autoName == gone then autoName = nil; refreshAuto() end
if autoSel == gone then autoSel = nil; autoDD.setValue(nil) end
selected = nil
selDD.setValue(nil)
nameBox.Text = ""
setStatus("Config '" .. gone .. "' dihapus (preview)", C_GRAY)
end, C_RED },
})

groupTitle(misc, "Auto Load Config")
autoDD = makeDropdown(misc, "Select Config", names, function(n) autoSel = n end)
autoLbl = infoRow(misc, "")
refreshAuto()

buttonsRow(misc, {
{ "Set", function()
if not autoSel then
setStatus("Pilih config dulu (kosong = Auto Load tidak aktif)", C_WARN)
return
end
autoName = autoSel
refreshAuto()
setStatus("Auto Load diset ke '" .. autoName .. "' (preview)", C_GOOD)
end },
{ "Delete", function()
autoName = nil
autoSel = nil
autoDD.setValue(nil)
refreshAuto()
setStatus("Auto Load dikosongkan (preview)", C_GRAY)
end, C_RED },
})

statusLbl = infoRow(misc, "Preview: tidak menulis file dan tidak memanggil game.")

setTab("Misc")
