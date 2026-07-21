--══════════════════════════════════════════════════════════════
-- OTH Support Checker
-- Probes the executor for oth.hook / oth.unhook / oth.get_root_callback /
-- oth.is_hook_thread / oth.get_original_thread, then shows the result in a
-- small draggable UI. Safe to run on any executor — every probe is wrapped
-- so a missing global never throws.
--══════════════════════════════════════════════════════════════

local CoreGui = game:GetService("CoreGui")
local UIS = game:GetService("UserInputService")

-- Remove a previous run so re-executing doesn't stack windows.
pcall(function()
	local existing = CoreGui:FindFirstChild("OthSupportChecker")
	if existing then existing:Destroy() end
end)

--──────────────────────────────
-- Probe
--──────────────────────────────
local FUNCS = { "hook", "unhook", "get_root_callback", "is_hook_thread", "get_original_thread" }

local hasOth = (typeof(oth) == "table")
local results = {}
for _, name in ipairs(FUNCS) do
	local present = hasOth and typeof(oth[name]) == "function"
	table.insert(results, { name = name, present = present })
end

local execName = "Unknown"
pcall(function()
	if identifyexecutor then
		local n = identifyexecutor()
		if n then execName = n end
	end
end)

local supportedCount = 0
for _, r in ipairs(results) do if r.present then supportedCount += 1 end end
local fullySupported = hasOth and supportedCount == #FUNCS

--──────────────────────────────
-- Theme + compact layout constants
--──────────────────────────────
local C = {
	BG      = Color3.fromRGB(24, 24, 28),
	CARD    = Color3.fromRGB(32, 32, 38),
	BORDER  = Color3.fromRGB(50, 50, 58),
	TEXT    = Color3.fromRGB(235, 235, 240),
	SUB     = Color3.fromRGB(150, 150, 160),
	GOOD    = Color3.fromRGB(80, 200, 120),
	BAD     = Color3.fromRGB(220, 90, 90),
	ACC     = Color3.fromRGB(90, 140, 255),
}

local WIN_W    = 240
local PAD      = 10
local TITLE_H  = 26
local BANNER_H = 34
local ROW_H    = 20

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 6)
	c.Parent = p
	return c
end

local function stroke(p, col, t)
	local s = Instance.new("UIStroke")
	s.Color = col or C.BORDER
	s.Thickness = t or 1
	s.Parent = p
	return s
end

--──────────────────────────────
-- Root GUI
--──────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name = "OthSupportChecker"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
pcall(function() gui.Parent = CoreGui end)
if not gui.Parent then gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end

local win = Instance.new("Frame")
win.Name = "Window"
win.AnchorPoint = Vector2.new(0.5, 0.5)
win.Position = UDim2.new(0.5, 0, 0.5, 0)
win.Size = UDim2.fromOffset(WIN_W, 200) -- resized to fit content at the bottom
win.BackgroundColor3 = C.BG
win.BorderSizePixel = 0
win.Parent = gui
corner(win, 8)
stroke(win, C.BORDER)

-- Title bar (draggable)
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, TITLE_H)
titleBar.BackgroundTransparency = 1
titleBar.Parent = win

local titleLbl = Instance.new("TextLabel")
titleLbl.BackgroundTransparency = 1
titleLbl.Position = UDim2.fromOffset(PAD, 0)
titleLbl.Size = UDim2.new(1, -40, 1, 0)
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 12
titleLbl.TextColor3 = C.TEXT
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Text = "Nasi OTH Support Checker"
titleLbl.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0.5)
closeBtn.Position = UDim2.new(1, -6, 0.5, 0)
closeBtn.Size = UDim2.fromOffset(18, 18)
closeBtn.BackgroundColor3 = C.CARD
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "×"
closeBtn.TextSize = 13
closeBtn.TextColor3 = C.SUB
closeBtn.Parent = titleBar
corner(closeBtn, 5)
closeBtn.MouseEnter:Connect(function() closeBtn.TextColor3 = C.TEXT end)
closeBtn.MouseLeave:Connect(function() closeBtn.TextColor3 = C.SUB end)
closeBtn.Activated:Connect(function() gui:Destroy() end)

-- Drag handling
do
	local dragging, dragStart, startPos = false, nil, nil
	titleBar.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = inp.Position
			startPos = win.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			local delta = inp.Position - dragStart
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

local sep = Instance.new("Frame")
sep.Position = UDim2.fromOffset(0, TITLE_H)
sep.Size = UDim2.new(1, 0, 0, 1)
sep.BackgroundColor3 = C.BORDER
sep.BorderSizePixel = 0
sep.Parent = win

-- Verdict banner (single line, icon + short text)
local bannerY = TITLE_H + 6
local banner = Instance.new("Frame")
banner.Position = UDim2.fromOffset(PAD, bannerY)
banner.Size = UDim2.new(1, -PAD * 2, 0, BANNER_H)
banner.BackgroundColor3 = fullySupported and Color3.fromRGB(30, 55, 40) or Color3.fromRGB(55, 32, 32)
banner.BorderSizePixel = 0
banner.Parent = win
corner(banner, 6)

local verdictLbl = Instance.new("TextLabel")
verdictLbl.BackgroundTransparency = 1
verdictLbl.Position = UDim2.fromOffset(8, 3)
verdictLbl.Size = UDim2.new(1, -16, 0, 14)
verdictLbl.Font = Enum.Font.GothamBold
verdictLbl.TextSize = 11
verdictLbl.TextXAlignment = Enum.TextXAlignment.Left
verdictLbl.TextColor3 = fullySupported and C.GOOD or C.BAD
verdictLbl.Text = fullySupported and ("✓ Full oth support")
	or (hasOth and ("⚠ Partial oth (" .. supportedCount .. "/" .. #FUNCS .. ")")
	or ("✗ No oth support"))
verdictLbl.Parent = banner

local subLbl = Instance.new("TextLabel")
subLbl.BackgroundTransparency = 1
subLbl.Position = UDim2.fromOffset(8, 17)
subLbl.Size = UDim2.new(1, -16, 0, 14)
subLbl.Font = Enum.Font.Gotham
subLbl.TextSize = 9
subLbl.TextXAlignment = Enum.TextXAlignment.Left
subLbl.TextColor3 = C.SUB
subLbl.Text = execName .. (fullySupported and " — hookfunction/oth.hook both safe." or " — fall back to hookfunction.")
subLbl.Parent = banner

-- Function-by-function list
local listY = bannerY + BANNER_H + 6
local listFrame = Instance.new("Frame")
listFrame.Position = UDim2.fromOffset(PAD, listY)
listFrame.Size = UDim2.new(1, -PAD * 2, 0, #FUNCS * ROW_H)
listFrame.BackgroundColor3 = C.CARD
listFrame.BorderSizePixel = 0
listFrame.Parent = win
corner(listFrame, 6)
stroke(listFrame, C.BORDER)

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 0)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = listFrame

for i, r in ipairs(results) do
	local row = Instance.new("Frame")
	row.LayoutOrder = i
	row.Size = UDim2.new(1, 0, 0, ROW_H)
	row.BackgroundTransparency = 1
	row.Parent = listFrame

	if i > 1 then
		local rowSep = Instance.new("Frame")
		rowSep.Size = UDim2.new(1, 0, 0, 1)
		rowSep.BackgroundColor3 = C.BORDER
		rowSep.BorderSizePixel = 0
		rowSep.Parent = row
	end

	local nameLbl = Instance.new("TextLabel")
	nameLbl.BackgroundTransparency = 1
	nameLbl.Position = UDim2.fromOffset(8, 0)
	nameLbl.Size = UDim2.new(1, -66, 1, 0)
	nameLbl.Font = Enum.Font.Code
	nameLbl.TextSize = 10
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.TextColor3 = C.TEXT
	nameLbl.Text = "oth." .. r.name
	nameLbl.Parent = row

	local statusLbl = Instance.new("TextLabel")
	statusLbl.AnchorPoint = Vector2.new(1, 0.5)
	statusLbl.Position = UDim2.new(1, -8, 0.5, 0)
	statusLbl.Size = UDim2.fromOffset(46, 16)
	statusLbl.Font = Enum.Font.GothamBold
	statusLbl.TextSize = 9
	statusLbl.TextXAlignment = Enum.TextXAlignment.Right
	statusLbl.TextColor3 = r.present and C.GOOD or C.BAD
	statusLbl.Text = r.present and "FOUND" or "MISSING"
	statusLbl.Parent = row
end

-- Copy-report button (report text carries the executor name / full detail —
-- no separate footer line needed, keeps the window short)
local copyY = listY + #FUNCS * ROW_H + 6
local copyBtn = Instance.new("TextButton")
copyBtn.Position = UDim2.fromOffset(PAD, copyY)
copyBtn.Size = UDim2.new(1, -PAD * 2, 0, 22)
copyBtn.BackgroundColor3 = C.ACC
copyBtn.BorderSizePixel = 0
copyBtn.AutoButtonColor = false
copyBtn.Font = Enum.Font.GothamBold
copyBtn.TextSize = 10
copyBtn.TextColor3 = Color3.new(1, 1, 1)
copyBtn.Text = "Copy Report"
copyBtn.Parent = win
corner(copyBtn, 6)

copyBtn.Activated:Connect(function()
	local lines = { "OTH Support Report — " .. execName, "" }
	for _, r in ipairs(results) do
		table.insert(lines, (r.present and "[FOUND]   " or "[MISSING] ") .. "oth." .. r.name)
	end
	table.insert(lines, "")
	table.insert(lines, fullySupported and "VERDICT: Fully supported" or "VERDICT: Not fully supported")
	local report = table.concat(lines, "\n")
	local ok = pcall(function() setclipboard(report) end)
	copyBtn.Text = ok and "Copied!" or "Clipboard unavailable"
	task.delay(1.5, function()
		if copyBtn.Parent then copyBtn.Text = "Copy Report" end
	end)
end)

-- Resize window to fit content exactly.
win.Size = UDim2.fromOffset(WIN_W, copyY + 22 + PAD)
