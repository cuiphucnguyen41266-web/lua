local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer
if not player then
	local waited = 0
	repeat
		task.wait(0.1)
		waited = waited + 0.1
		player = Players.LocalPlayer
	until player or waited >= 20
end
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")
local LOAD_COUNT = 0
pcall(function()
	if readfile then
		LOAD_COUNT = tonumber(readfile("TvT_Hub/loadcount.txt")) or 0
	end
end)
LOAD_COUNT = LOAD_COUNT + 1
pcall(function()
	if writefile then
		pcall(makefolder, "TvT_Hub")
		writefile("TvT_Hub/loadcount.txt", tostring(LOAD_COUNT))
		writefile("TvT_Hub/lastrun.txt", tostring(os.clock()))
	end
end)
local function build()
	do
		local ok, hui = pcall(function() return gethui() end)
		local container = (ok and hui) or playerGui
		for _, g in ipairs(container:GetChildren()) do
			if g.Name == "TvT_Menu" or g.Name == "TvT_Err" or g.Name == "TvT_Crash" then g:Destroy() end
		end
	end
	for _, key in ipairs({ "TvTConn", "TvTUIConn", "TvTESPConn" }) do
		if _G[key] then
			pcall(function() _G[key]:Disconnect() end)
			_G[key] = nil
		end
	end
	pcall(function() if _G.TvTThrone then _G.TvTThrone:Destroy() end _G.TvTThrone = nil end)
	pcall(function() if _G.TvTClone then _G.TvTClone:Destroy() end _G.TvTClone = nil end)
	pcall(function() if _G.TvTDeathMark then _G.TvTDeathMark:Destroy() end _G.TvTDeathMark = nil end)
	local THEME = { dark = false, invis = false }
	pcall(function()
		if readfile then
			THEME.dark = (readfile("TvT_Hub/theme.txt") == "dark")
			THEME.invis = (readfile("TvT_Hub/invis.txt") == "1")
		end
	end)
	local FONT_COLOR = nil
	pcall(function()
		if readfile and isfile and isfile("TvT_Hub/fontcolor.txt") then
			local c = readfile("TvT_Hub/fontcolor.txt")
			local r, g2, b = string.match(c, "(%d+),(%d+),(%d+)")
			if r then FONT_COLOR = Color3.fromRGB(tonumber(r), tonumber(g2), tonumber(b)) end
		end
	end)
	local CONFIG = {
		antiTeleport = false, horizontalTolerance = 3, verticalTolerance = 10, flingSpeedLimit = 150,
		speedOn = false, speedVal = 16, jumpOn = false, jumpVal = 50,
		noclipOn = false, autoJumpOn = false, infJumpOn = false,
		spinOn = false, spinVal = 180,
		flyOn = false, flyVal = 50,
		keepTo = false, keepFrom = false, keepAllFrom = false,
		chamsOn = false, chamsColor = Color3.fromRGB(255, 60, 60),
		dragonOn = false, dragonLay = false, dragonBaseY = nil,
		cloneOn = false, cloneDelay = 2,
		deathMarkOn = false, throneOn = false,
		autoExec = false, bgTrans = 0, bgPath = "",
	}
	local char, humanoid, hrp
	local lastPos, lastCFrame = Vector3.zero, CFrame.new()
	local spinAngle = 0
	local selectedPlayer = nil
	local function tween(obj, time, style, props)
		TweenService:Create(obj, TweenInfo.new(time, style, Enum.EasingDirection.Out), props):Play()
	end
	local BG_FOLDER, BG_PRE = "TvT_Hub", "bg_"
	local BACKGROUND = { imageLabel = nil }
	local fileFunc = {
		list = listfiles, isFile = isfile, make = makefolder,
		write = writefile, read = readfile,
		asset = (getcustomasset or getsynasset),
	}
	pcall(function() if fileFunc.make then fileFunc.make(BG_FOLDER) end end)
	pcall(function() if fileFunc.make then fileFunc.make("autoexec") end end)
	local function scanBackgrounds()
		local list = {}
		pcall(function()
			for _, p in ipairs(fileFunc.list(BG_FOLDER)) do
				if string.match(p, "%.png$") or string.match(p, "%.jpe?g$") then
					table.insert(list, p)
				end
			end
		end)
		table.sort(list)
		return list
	end
	local function saveSelection(path, trans)
		pcall(function() fileFunc.write(BG_FOLDER .. "/selected.txt", (path or "") .. "|" .. tostring(trans or 0)) end)
	end
	local function loadSelection()
		local ok, txt = pcall(function() return fileFunc.read(BG_FOLDER .. "/selected.txt") end)
		if ok and txt and txt ~= "" then
			local path, trans = string.match(txt, "^(.-)|(.+)$")
			if path then return (path ~= "" and path or nil), tonumber(trans) end
			return txt
		end
		return nil, nil
	end
	local function applyBackground(path)
		if not BACKGROUND.imageLabel then return end
		if not path or path == "" then
			BACKGROUND.imageLabel.Image = ""
			CONFIG.bgPath = ""
			saveSelection("", CONFIG.bgTrans)
			return
		end
		if not fileFunc.asset or not fileFunc.isFile then return end
		if not fileFunc.isFile(path) then return end
		local ok2, asset = pcall(function() return fileFunc.asset(path) end)
		if ok2 and asset then
			BACKGROUND.imageLabel.Image = asset
			BACKGROUND.imageLabel.ImageTransparency = CONFIG.bgTrans
			CONFIG.bgPath = path
			saveSelection(path, CONFIG.bgTrans)
		end
	end
	local GLASS_BG = THEME.dark and Color3.fromRGB(38, 42, 54) or Color3.fromRGB(255, 255, 255)
	local GLASS_TOP = THEME.dark and Color3.fromRGB(48, 53, 68) or Color3.fromRGB(255, 255, 255)
	local GLASS_BOT = THEME.dark and Color3.fromRGB(28, 32, 42) or Color3.fromRGB(246, 250, 254)
	local DARK = THEME.dark and Color3.new(1, 1, 1) or (FONT_COLOR or Color3.fromRGB(35, 45, 65))
	local GRAY = THEME.dark and Color3.fromRGB(185, 195, 210)
		or (FONT_COLOR and FONT_COLOR:Lerp(Color3.fromRGB(125, 135, 150), 0.45) or Color3.fromRGB(75, 85, 105))
	local function makeGlass(obj, radius, trans)
		obj.BackgroundColor3 = GLASS_BG
		obj.BackgroundTransparency = trans or 0.35
		obj.ClipsDescendants = true
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, radius or 14)
		c.Parent = obj
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, GLASS_TOP),
			ColorSequenceKeypoint.new(1, GLASS_BOT),
		})
		g.Rotation = 65
		g.Parent = obj
		return obj
	end
	local function attachDrag(guiObj, onTap, dragTarget)
		guiObj.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then return end
			local target = dragTarget or guiObj
			local startPos, start = target.Position, input.Position
			local moved = false
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.Change then
					local delta = input.Position - start
					if delta.Magnitude > 8 then moved = true end
					target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
						startPos.Y.Scale, startPos.Y.Offset + delta.Y)
				elseif input.UserInputState == Enum.UserInputState.End then
					conn:Disconnect()
					if not moved and onTap then task.spawn(onTap) end
				end
			end)
		end)
	end
	local function makeLabel(parent, pos, size, text, sizeText, bold, align)
		local l = Instance.new("TextLabel")
		l.Position, l.Size = pos, size
		l.BackgroundTransparency = 1
		l.Text = text
		l.TextColor3 = bold and DARK or GRAY
		l.TextSize = sizeText or 14
		l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
		l.TextXAlignment = align or Enum.TextXAlignment.Left
		l.TextYAlignment = Enum.TextYAlignment.Center
		l.Parent = parent
		return l
	end
	local function makeButton(parent, pos, size, text, callback)
		local b = Instance.new("TextButton")
		b.Position, b.Size = pos, size
		b.Text, b.TextColor3 = text, DARK
		b.TextSize, b.Font = 14, Enum.Font.GothamBold
		b.AutoButtonColor = false
		makeGlass(b, 12, 0.35)
		b.Parent = parent
		if callback then b.MouseButton1Click:Connect(callback) end
		return b
	end
	local function makeSwitch(parent, pos, initial, onChange)
		local sw = Instance.new("Frame")
		sw.Position, sw.Size = pos, UDim2.new(0, 38, 0, 20)
		makeGlass(sw, 999, 0.15)
		sw.Parent = parent
		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 15, 0, 15)
		makeGlass(knob, 999, 0.05)
		knob.Parent = sw
		local hit = Instance.new("TextButton")
		hit.Size = UDim2.new(1, 0, 1, 0)
		hit.BackgroundTransparency = 1
		hit.Text = ""
		hit.Parent = sw
		local state = initial
		local function set(v)
			state = v
			tween(knob, 0.2, Enum.EasingStyle.Quint, {
				Position = v and UDim2.new(1, -18, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)})
			tween(sw, 0.2, Enum.EasingStyle.Quint, {
				BackgroundColor3 = v and Color3.fromRGB(88, 200, 120) or Color3.fromRGB(150, 155, 165)})
		end
		set(initial)
		hit.MouseButton1Click:Connect(function()
			set(not state)
			if onChange then onChange(state) end
		end)
		return sw
	end
	local function makeInputBox(parent, pos, size, defaultText)
		local wrap = Instance.new("Frame")
		wrap.Position, wrap.Size = pos, size
		makeGlass(wrap, 8, 0.25)
		wrap.Parent = parent
		local box = Instance.new("TextBox")
		box.Size = UDim2.new(1, -10, 1, 0)
		box.Position = UDim2.new(0, 5, 0, 0)
		box.BackgroundTransparency = 1
		box.TextColor3, box.TextSize, box.Font = DARK, 14, Enum.Font.GothamBold
		box.TextXAlignment = Enum.TextXAlignment.Center
		box.ClearTextOnFocus = false
		box.Text = defaultText or ""
		box.Parent = wrap
		return box
	end
	local function makeSlider(parent, y, text, sliderMax, inputMax, default, callback, decimals)
		decimals = decimals or 0
		makeLabel(parent, UDim2.new(0, 0, 0, y), UDim2.new(0, 200, 0, 20), text, 14, true)
		local valueBox = makeInputBox(parent, UDim2.new(1, -86, 0, y - 3), UDim2.new(0, 86, 0, 26),
			string.format("%." .. decimals .. "f", default))
		local bar = Instance.new("Frame")
		bar.Position = UDim2.new(0, 0, 0, y + 26)
		bar.Size = UDim2.new(1, -96, 0, 8)
		makeGlass(bar, 999, 0.4)
		bar.Parent = parent
		local fill = Instance.new("Frame")
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
		fill.BackgroundTransparency = 0.25
		local fc = Instance.new("UICorner")
		fc.CornerRadius = UDim.new(1, 0)
		fc.Parent = fill
		fill.Parent = bar
		local knob = Instance.new("Frame")
		knob.Size = UDim2.new(0, 16, 0, 16)
		makeGlass(knob, 999, 0)
		knob.Parent = bar
		local current = default
		local function set(v, fire)
			current = math.clamp(v, 0, inputMax)
			local alpha = math.clamp(c
