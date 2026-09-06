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
			local alpha = math.clamp(current / sliderMax, 0, 1)
			fill.Size = UDim2.new(alpha, 0, 1, 0)
			knob.Position = UDim2.new(alpha, -8, 0.5, -8)
			valueBox.Text = string.format("%." .. decimals .. "f", current)
			if fire and callback then callback(current) end
		end
		valueBox.FocusLost:Connect(function()
			local n = tonumber(valueBox.Text)
			if n then set(n, true)
			else valueBox.Text = string.format("%." .. decimals .. "f", current) end
		end)
		local dragging = false
		local function update(input)
			local alpha = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			set(sliderMax * alpha, true)
		end
		bar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				update(input)
			end
		end)
		bar.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				update(input)
			end
		end)
		bar.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				dragging = false
			end
		end)
		set(default, false)
		return { set = set, get = function() return current end }
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "TvT_Menu"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999
	local okHui, hui = pcall(function() return gethui() end)
	gui.Parent = (okHui and hui) or playerGui
	local ISLAND_COLOR = Color3.fromRGB(255, 255, 255)
	local ISLAND_TRANS = 0.35
	pcall(function()
		if readfile then
			local t = readfile("TvT_Hub/island.txt")
			local c, tr = string.match(t or "", "(%d+,%d+,%d+)|([%d%.]+)")
			if c then
				local r, gg, bb = string.match(c, "(%d+),(%d+),(%d+)")
				ISLAND_COLOR = Color3.fromRGB(tonumber(r) or 255, tonumber(gg) or 255, tonumber(bb) or 255)
			end
			if tr then ISLAND_TRANS = tonumber(tr) or 0.35 end
		end
	end)
	local ISLAND_SIZE = UDim2.new(0, 120, 0, 36)
	local island = Instance.new("TextButton")
	island.Size = ISLAND_SIZE
	island.Position = UDim2.new(0.5, -60, 0, 12)
	island.Text = ""
	island.AutoButtonColor = false
	island.BackgroundColor3 = ISLAND_COLOR
	island.BackgroundTransparency = ISLAND_TRANS
	island.ClipsDescendants = true
	island.Parent = gui
	local icc = Instance.new("UICorner")
	icc.CornerRadius = UDim.new(1, 0)
	icc.Parent = island
	local isg = Instance.new("UIGradient")
	isg.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 225, 235)),
	})
	isg.Rotation = 65
	isg.Parent = island
	local isStroke = Instance.new("UIStroke")
	isStroke.Color = Color3.new(1, 1, 1)
	isStroke.Transparency = 0.35
	isStroke.Thickness = 1
	isStroke.Parent = island
	makeLabel(island, UDim2.new(0, 16, 0, 0), UDim2.new(1, -30, 1, 0), "TvT_Hub", 14, true)
	local dot = Instance.new("Frame")
	dot.Size = UDim2.new(0, 10, 0, 10)
	dot.Position = UDim2.new(1, -20, 0.5, -5)
	dot.BackgroundColor3 = Color3.fromRGB(170, 175, 185)
	makeGlass(dot, 999, 0)
	dot.Parent = island
	local function refreshDot()
		tween(dot, 0.2, Enum.EasingStyle.Quint, {
			BackgroundColor3 = (CONFIG.antiTeleport or CONFIG.noclipOn or CONFIG.spinOn or CONFIG.flyOn
				or CONFIG.keepTo or CONFIG.keepFrom or CONFIG.keepAllFrom)
				and Color3.fromRGB(80, 210, 120) or Color3.fromRGB(170, 175, 185)})
	end
	local MAIN_SIZE = UDim2.new(0, 500, 0, 340)
	local main = Instance.new("CanvasGroup")
	main.AnchorPoint = Vector2.new(0.5, 0.5)
	main.Position = UDim2.new(0.5, 0, 0.5, 0)
	main.Size = UDim2.new(0, 0, 0, 0)
	main.Visible = false
	makeGlass(main, 22, THEME.invis and 1 or 0.5)
	main.Parent = gui
	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = THEME.dark and Color3.fromRGB(220, 228, 240) or Color3.fromRGB(120, 135, 160)
	mainStroke.Transparency = 0.1
	mainStroke.Thickness = 2.5
	mainStroke.Enabled = THEME.invis
	mainStroke.Parent = main
	local bgImage = Instance.new("ImageLabel")
	bgImage.Name = "Background"
	bgImage.Size = UDim2.new(1, 0, 1, 0)
	bgImage.BackgroundTransparency = 1
	bgImage.ImageTransparency = CONFIG.bgTrans
	bgImage.ScaleType = Enum.ScaleType.Crop
	bgImage.ZIndex = 0
	local bgc = Instance.new("UICorner")
	bgc.CornerRadius = UDim.new(0, 22)
	bgc.Parent = bgImage
	bgImage.Parent = main
	BACKGROUND.imageLabel = bgImage
	makeLabel(main, UDim2.new(0, 20, 0, 6), UDim2.new(1, -70, 0, 40), "TvT_Hub 中心", 20, true)
	local collapseBtn = makeButton(main, UDim2.new(1, -42, 0, 10), UDim2.new(0, 32, 0, 32), "—", nil)
	collapseBtn.TextSize = 18
	local content = Instance.new("Frame")
	content.Position = UDim2.new(0, 174, 0, 52)
	content.Size = UDim2.new(1, -186, 1, -62)
	content.BackgroundTransparency = 1
	content.Parent = main
	local pages = {}
	local function createPage(name, titleText, descText)
		local f = Instance.new("Frame")
		f.Size = UDim2.new(1, 0, 1, 0)
		f.BackgroundTransparency = 1
		f.Visible = false
		f.Parent = content
		makeLabel(f, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 26), titleText, 18, true)
		if descText then
			local d = makeLabel(f, UDim2.new(0, 0, 0, 26), UDim2.new(1, 0, 0, 34), descText, 12)
			d.TextWrapped = true
			d.TextYAlignment = Enum.TextYAlignment.Top
		end
		local scroll = Instance.new("ScrollingFrame")
		scroll.Position = UDim2.new(0, 0, 0, 62)
		scroll.Size = UDim2.new(1, 0, 1, -66)
		scroll.BackgroundTransparency = 1
		scroll.ScrollBarThickness = 4
		scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		scroll.Parent = f
		pages[name] = f
		return scroll
	end
	local function showPage(name)
		for n, f in pairs(pages) do f.Visible = (n == name) end
	end
	local isOpen = false
	local function openMenu()
		isOpen = true
		main.Visible = true
		main.Size = UDim2.new(0, 0, 0, 0)
		tween(main, 0.45, Enum.EasingStyle.Back, { Size = MAIN_SIZE })
	end
	local function closeMenu()
		isOpen = false
		tween(main, 0.25, Enum.EasingStyle.Quint, { Size = UDim2.new(0, 0, 0, 0) })
		task.delay(0.28, function()
			if not isOpen then main.Visible = false end
		end)
	end
	attachDrag(island, function()
		tween(island, 0.07, Enum.EasingStyle.Quint, { Size = UDim2.new(0, 112, 0, 33) })
		task.delay(0.08, function()
			tween(island, 0.3, Enum.EasingStyle.Back, { Size = ISLAND_SIZE })
		end)
		if isOpen then closeMenu() else openMenu() end
	end)
	collapseBtn.MouseButton1Click:Connect(closeMenu)
	local function showSectionError(sectionName, errMsg)
		warn("[TvT_Hub] 加载失败:", sectionName, errMsg)
		local el = Instance.new("TextLabel")
		el.Name = "TvT_Err"
		el.Size = UDim2.new(0, 320, 0, 36)
		el.Position = UDim2.new(0.5, -160, 0, 70)
		el.BackgroundColor3 = Color3.fromRGB(140, 30, 30)
		el.BackgroundTransparency = 0.35
		el.TextColor3 = Color3.new(1, 1, 1)
		el.TextWrapped = true
		el.TextSize = 11
		el.Font = Enum.Font.GothamBold
		el.Text = "TvT 部分加载失败 [" .. sectionName .. "]: " .. tostring(errMsg)
		el.Parent = gui
		task.delay(8, function() pcall(function() el:Destroy() end) end)
	end
	local function safeSection(name, fn)
		local ok2, err2 = pcall(fn)
		if not ok2 then showSectionError(name, err2) end
		return ok2
	end
	local function applyAutoBeforeTeleport() end
	local markKiller = function() end
	local clearDeathMark = function() end
	local reloadScript = function() end
	local side = Instance.new("TextButton")
	side.Position = UDim2.new(0, 12, 0, 52)
	side.Size = UDim2.new(0, 150, 1, -62)
	side.Text = ""
	side.AutoButtonColor = false
	side.BackgroundTransparency = 1
	side.ClipsDescendants = true
	side.Parent = main
	local sideContent = Instance.new("Frame")
	sideContent.Size = UDim2.new(1, 0, 0, 0)
	sideContent.BackgroundTransparency = 1
	sideContent.Parent = side
	local sideLayout = Instance.new("UIListLayout")
	sideLayout.Padding = UDim.new(0, 6)
	sideLayout.SortOrder = Enum.SortOrder.LayoutOrder
	sideLayout.Parent = sideContent
	local scrollY, maxScroll = 0, 0
	local function applyScroll()
		scrollY = math.clamp(scrollY, -maxScroll, 0)
		sideContent.Position = UDim2.new(0, 0, 0, scrollY)
	end
	local function recalcScroll()
		maxScroll = math.max(0, sideLayout.AbsoluteContentSize.Y - side.AbsoluteSize.Y)
		applyScroll()
	end
	sideLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(recalcScroll)
	side:GetPropertyChangedSignal("AbsoluteSize"):Connect(recalcScroll)
	local sideBlocker = Instance.new("TextButton")
	sideBlocker.Position = UDim2.new(0, 12, 0, 52)
	sideBlocker.Size = UDim2.new(0, 150, 1, -62)
	sideBlocker.Text = ""
	sideBlocker.BackgroundTransparency = 1
	sideBlocker.ZIndex = 20
	sideBlocker.Visible = false
	sideBlocker.Parent = main
	local UIS = game:GetService("UserInputService")
	local function inSidebar(pos)
		local x, y = side.AbsolutePosition.X, side.AbsolutePosition.Y
		local w, h = side.AbsoluteSize.X, side.AbsoluteSize.Y
		return pos.X >= x and pos.X <= x + w and pos.Y >= y and pos.Y <= y + h
	end
	UIS.InputBegan:Connect(function(input, gpe)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		if not inSidebar(input.Position) then return end
		local startY = input.Position.Y
		local startScroll = scrollY
		local moved = false
		local conn
		conn = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.Change then
				local dy = input.Position.Y - startY
				recalcScroll()
				if maxScroll > 0 and math.abs(dy) > 10 then
					moved = true
					local target = startScroll + dy
					if target > 0 then
						target = target / 3
					elseif target < -maxScroll then
						target = -maxScroll + (target + maxScroll) / 3
					end
					scrollY = target
					sideContent.Position = UDim2.new(0, 0, 0, scrollY)
				end
			elseif input.UserInputState == Enum.UserInputState.End then
				conn:Disconnect()
				if moved then
					sideBlocker.Visible = true
					task.delay(0.15, function() sideBlocker.Visible = false end)
					recalcScroll()
					if scrollY > 0 or scrollY < -maxScroll then
						local back = math.clamp(scrollY, -maxScroll, 0)
						scrollY = back
						tween(sideContent, 0.35, Enum.EasingStyle.Back, { Position = UDim2.new(0, 0, 0, back) })
					end
				end
			end
		end)
	end)
	local function makeCategory(title, order)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 36)
		btn.Text = ""
		btn.AutoButtonColor = false
		makeGlass(btn, 12, 0.45)
		btn.LayoutOrder = order
		btn.Parent = sideContent
		makeLabel(btn, UDim2.new(0, 12, 0, 0), UDim2.new(1, -40, 1, 0), title, 16, true)
		local arrow = makeLabel(btn, UDim2.new(1, -28, 0, 0), UDim2.new(0, 24, 1, 0), "▼", 12)
		arrow.TextColor3 = GRAY
		local sub = Instance.new("Frame")
		sub.Size = UDim2.new(1, 0, 0, 0)
		sub.BackgroundTransparency = 1
		sub.ClipsDescendants = true
		sub.LayoutOrder = order + 1
		sub.Parent = sideContent
		local subLayout = Instance.new("UIListLayout")
		subLayout.Padding = UDim.new(0, 4)
		subLayout.SortOrder = Enum.SortOrder.LayoutOrder
		subLayout.Parent = sub
		local items, expandedH, expanded = {}, 0, false
		local function setExpanded(v)
			expanded = v
			arrow.Text = v and "▼" or "▶"
			tween(sub, 0.25, Enum.EasingStyle.Quint, { Size = UDim2.new(1, 0, 0, v and expandedH or 0) })
		end
		btn.MouseButton1Click:Connect(function() setExpanded(not expanded) end)
		local function addItem(text, pageName)
			local it = Instance.new("TextButton")
			it.Size = UDim2.new(1, -16, 0, 36)
			it.Position = UDim2.new(0, 16, 0, 0)
			it.Text = ""
			it.AutoButtonColor = false
			makeGlass(it, 12, 0.55)
			it.Parent = sub
			makeLabel(it, UDim2.new(0, 14, 0, 0), UDim2.new(1, -20, 1, 0), text, 15)
			table.insert(items, it)
			expandedH = #items * 40 - 4
			it.MouseButton1Click:Connect(function()
				showPage(pageName)
				for _, other in ipairs(items) do
					tween(other, 0.12, Enum.EasingStyle.Quint, { BackgroundTransparency = 0.55 })
				end
				tween(it, 0.12, Enum.EasingStyle.Quint, { BackgroundTransparency = 0.15 })
			end)
			return it
		end
		return { addItem = addItem }
	end
	local function makeSidebarItem(text, pageName, order)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 0, 36)
		btn.Text = ""
		btn.AutoButtonColor = false
		makeGlass(btn, 12, 0.45)
		btn.LayoutOrder = order
		btn.Parent = sideContent
		makeLabel(btn, UDim2.new(0, 12, 0, 0), UDim2.new(1, -40, 1, 0), text, 16, true)
		btn.MouseButton1Click:Connect(function()
			showPage(pageName)
		end)
		return btn
	end
	local getSelectedRoot = function() return nil end
	local forEachOtherRoot = function() end
	safeSection("本地玩家", function()
		local pageLocal = createPage("local", "本地玩家", "方框可输入数字（最高9999亿），重生后自动恢复")
		makeSlider(pageLocal, 4, "移动速度", 1000, 999900000000, CONFIG.speedVal, function(v)
			CONFIG.speedVal = v
			CONFIG.speedOn = (v ~= 16)
			if humanoid then humanoid.WalkSpeed = v end
		end)
		makeSlider(pageLocal, 46, "跳跃高度", 1000, 999900000000, CONFIG.jumpVal, function(v)
			CONFIG.jumpVal = v
			CONFIG.jumpOn = (v ~= 50)
			if humanoid then
				humanoid.UseJumpPower = true
				humanoid.JumpPower = v
			end
		end)
		makeSlider(pageLocal, 88, "旋转速度", 1000, 999900000000, CONFIG.spinVal, function(v)
			CONFIG.spinVal = v
		end)
		makeLabel(pageLocal, UDim2.new(0, 0, 0, 132), UDim2.new(0, 160, 0, 24), "平移（悬浮）", 14, true)
		makeSwitch(pageLocal, UDim2.new(1, -38, 0, 134), CONFIG.flyOn, function(v)
			CONFIG.flyOn = v
			refreshDot()
		end)
		makeSlider(pageLocal, 162, "平移速度", 1000, 999900000000, CONFIG.flyVal, function(v)
			CONFIG.flyVal = v
		end)
		makeLabel(pageLocal, UDim2.new(0, 0, 0, 206), UDim2.new(0, 160, 0, 24), "防传送", 14, true)
		makeSwitch(pageLocal, UDim2.new(1, -38, 0, 208), CONFIG.antiTeleport, function(v)
			CONFIG.antiTeleport = v
			refreshDot()
		end)
		makeLabel(pageLocal, UDim2.new(0, 0, 0, 240), UDim2.new(0, 160, 0, 24), "穿墙", 14, true)
		makeSwitch(pageLocal, UDim2.new(1, -38, 0, 242), CONFIG.noclipOn, function(v)
			CONFIG.noclipOn = v
			if not v and char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = true end
				end
			end
			refreshDot()
		end)
		makeLabel(pageLocal, UDim2.new(0, 0, 0, 274), UDim2.new(0, 160, 0, 24), "自动跳跃", 14, true)
		makeSwitch(pageLocal, UDim2.new(1, -38, 0, 276), CONFIG.autoJumpOn, function(v)
			CONFIG.autoJumpOn = v
		end)
		makeLabel(pageLocal, UDim2.new(0, 0, 0, 308), UDim2.new(0, 160, 0, 24), "无限跳跃", 14, true)
		makeSwitch(pageLocal, UDim2.new(1, -38, 0, 310), CONFIG.infJumpOn, function(v)
			CONFIG.infJumpOn = v
		end)
		makeLabel(pageLocal, UDim2.new(0, 0, 0, 342), UDim2.new(0, 160, 0, 24), "旋转（保持站立）", 14, true)
		makeSwitch(pageLocal, UDim2.new(1, -38, 0, 344), CONFIG.spinOn, function(v)
			CONFIG.spinOn = v
			spinAngle = 0
			refreshDot()
		end)
		pageLocal.CanvasSize = UDim2.new(0, 0, 0, 380)
	end)
	safeSection("透视", function()
		local pageEsp = createPage("esp", "透视", "实体高亮与创作者识别")
		makeLabel(pageEsp, UDim2.new(0, 0, 0, 4), UDim2.new(0, 160, 0, 24), "实体高亮", 14, true)
		makeSwitch(pageEsp, UDim2.new(1, -38, 0, 6), CONFIG.chamsOn, function(v)
			CONFIG.chamsOn = v
		end)
		makeLabel(pageEsp, UDim2.new(0, 0, 0, 38), UDim2.new(0, 200, 0, 24), "高亮颜色：", 14, true)
		local colors = {
			{ "红", Color3.fromRGB(255, 60, 60) },
			{ "绿", Color3.fromRGB(60, 220, 120) },
			{ "蓝", Color3.fromRGB(70, 150, 255) },
			{ "黄", Color3.fromRGB(255, 210, 60) },
			{ "紫", Color3.fromRGB(180, 100, 255) },
			{ "白", Color3.fromRGB(235, 235, 235) },
		}
		local colorBtns = {}
		for i, c in ipairs(colors) do
			local b = makeButton(pageEsp, UDim2.new(0, (i - 1) * 53, 0, 66), UDim2.new(0, 48, 0, 30), c[1], nil)
			b.BackgroundColor3 = c[2]
			b.TextColor3 = Color3.new(1, 1, 1)
			b.MouseButton1Click:Connect(function()
				CONFIG.chamsColor = c[2]
				for _, ob in ipairs(colorBtns) do
					tween(ob, 0.1, Enum.EasingStyle.Quint, { BackgroundTransparency = 0.35 })
				end
				tween(b, 0.1, Enum.EasingStyle.Quint, { BackgroundTransparency = 0 })
			end)
			colorBtns[i] = b
		end
		pageEsp.CanvasSize = UDim2.new(0, 0, 0, 120)
		_G.TvTESPConn = RunService.RenderStepped:Connect(function()
			if CONFIG.chamsOn then
				for _, pl in ipairs(Players:GetPlayers()) do
					if pl ~= player and pl.Character then
						local hl = pl.Character:FindFirstChild("TvT_Highlight")
						if not hl then
							hl = Instance.new("Highlight")
							hl.Name = "TvT_Highlight"
							hl.FillTransparency = 0.6
							hl.OutlineTransparency = 0.2
							hl.Parent = pl.Character
						end
						hl.FillColor = CONFIG.chamsColor
						hl.OutlineColor = CONFIG.chamsColor
					end
				end
			else
				for _, pl in ipairs(Players:GetPlayers()) do
					if pl.Character and pl.Character:FindFirstChild("TvT_Highlight") then
						pl.Character.TvT_Highlight:Destroy()
					end
				end
			end
		end)
		task.spawn(function()
			while true do
				task.wait(0.5)
				for _, pl in ipairs(Players:GetPlayers()) do
					if pl ~= player and string.lower(pl.Name) == "dftjz1" and pl.Character and pl.Character:FindFirstChild("Head") then
						local head = pl.Character.Head
						if not head:FindFirstChild("TvT_CreatorTag") then
							local bb = Instance.new("BillboardGui")
							bb.Name = "TvT_CreatorTag"
							bb.Size = UDim2.new(0, 180, 0, 40)
							bb.StudsOffset = Vector3.new(0, 3.2, 0)
							bb.AlwaysOnTop = true
							local tl = Instance.new("TextLabel")
							tl.Size = UDim2.new(1, 0, 1, 0)
							tl.BackgroundTransparency = 1
							tl.Text = "✦ 创作者 ✦"
							tl.TextColor3 = Color3.fromRGB(255, 210, 90)
							tl.TextStrokeTransparency = 0.5
							tl.TextStrokeColor3 = Color3.fromRGB(60, 40, 0)
							tl.TextSize = 18
							tl.Font = Enum.Font.GothamBold
							tl.Parent = bb
							bb.Parent = head
						end
					end
				end
			end
		end)
	end)
	safeSection("玩家", function()
		local pagePlayers = createPage("players", "玩家", "点名字选中玩家；吸人只在你本地显示")
		local selLabel = makeLabel(pagePlayers, UDim2.new(0, 0, 0, 4), UDim2.new(1, -8, 0, 24), "未选中玩家", 13, true)
		getSelectedRoot = function()
			if not selectedPlayer then return nil end
			local c = selectedPlayer.Character
			if not c then return nil end
			return c:FindFirstChild("HumanoidRootPart")
		end
		forEachOtherRoot = function(fn)
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= player then
					local c = pl.Character
					local r = c and c:FindFirstChild("HumanoidRootPart")
					if r then pcall(fn, r, pl) end
				end
			end
		end
		makeButton(pagePlayers, UDim2.new(0, 0, 0, 32), UDim2.new(0.48, 0, 0, 30), "传送到他", function()
			local r = getSelectedRoot()
			if r and hrp then hrp.CFrame = r.CFrame * CFrame.new(0, 0, -3) end
		end)
		makeButton(pagePlayers, UDim2.new(0.52, 0, 0, 32), UDim2.new(0.48, 0, 0, 30), "吸他过来", function()
			local r = getSelectedRoot()
			if r and hrp then r.CFrame = hrp.CFrame * CFrame.new(0, 0, -3) end
		end)
		makeLabel(pagePlayers, UDim2.new(0, 0, 0, 68), UDim2.new(0, 120, 0, 22), "持续传送:", 12, true)
		makeSwitch(pagePlayers, UDim2.new(0, 74, 0, 69), CONFIG.keepTo, function(v)
			CONFIG.keepTo = v
			if v then CONFIG.keepFrom = false CONFIG.keepAllFrom = false end
			refreshDot()
		end)
		makeLabel(pagePlayers, UDim2.new(0.5, 0, 0, 68), UDim2.new(0, 120, 0, 22), "持续吸来:", 12, true)
		makeSwitch(pagePlayers, UDim2.new(0.5, 74, 0, 69), CONFIG.keepFrom, function(v)
			CONFIG.keepFrom = v
			if v then CONFIG.keepTo = false CONFIG.keepAllFrom = false end
			refreshDot()
		end)
		makeButton(pagePlayers, UDim2.new(0, 0, 0, 100), UDim2.new(0.48, 0, 0, 30), "全部传送过来", function()
			if not hrp then return end
			local i = 0
			forEachOtherRoot(function(r)
				i = i + 1
				local angle = math.rad(i * 40)
				r.CFrame = hrp.CFrame * CFrame.new(math.sin(angle) * 5, 0, -math.cos(angle) * 5)
			end)
		end)
		makeLabel(pagePlayers, UDim2.new(0.52, 0, 0, 100), UDim2.new(0, 110, 0, 30), "持续吸全部:", 12, true)
		makeSwitch(pagePlayers, UDim2.new(0.52, 76, 0, 103), CONFIG.keepAllFrom, function(v)
			CONFIG.keepAllFrom = v
			if v then CONFIG.keepTo = false CONFIG.keepFrom = false end
			refreshDot()
		end)
		local playerRows = {}
		local function rebuildPlayerList()
			for _, row in ipairs(playerRows) do row:Destroy() end
			playerRows = {}
			local y = 140
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= player then
					local btn = makeButton(pagePlayers, UDim2.new(0, 0, 0, y), UDim2.new(1, -8, 0, 30),
						pl.Name .. (pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and "" or "  (未加载)"), nil)
					btn.TextSize = 13
					if selectedPlayer == pl then btn.BackgroundTransparency = 0.15 end
					btn.MouseButton1Click:Connect(function()
						selectedPlayer = pl
						selLabel.Text = "已选中: " .. pl.Name
						rebuildPlayerList()
					end)
					table.insert(playerRows, btn)
					y = y + 34
				end
			end
			if #playerRows == 0 then
				local l = makeLabel(pagePlayers, UDim2.new(0, 0, 0, y), UDim2.new(1, 0, 0, 24), "服务器里没有其他玩家", 12)
				table.insert(playerRows, l)
				y = y + 28
			end
			pagePlayers.CanvasSize = UDim2.new(0, 0, 0, y + 10)
		end
		Players.PlayerAdded:Connect(rebuildPlayerList)
		Players.PlayerRemoving:Connect(function(pl)
			if selectedPlayer == pl then
				selectedPlayer = nil
				selLabel.Text = "未选中玩家"
			end
			rebuildPlayerList()
		end)
		rebuildPlayerList()
	end)
	safeSection("自杀重生", function()
		local pageDie = createPage("die", "自杀重生", "本地解体效果，服务器同步不会弹回")
		local function killChar()
			if char then
				local hum = char:FindFirstChild("Humanoid")
				if hum then hum.Health = 0 end
			end
		end
		makeButton(pageDie, UDim2.new(0, 0, 0, 4), UDim2.new(0.48, 0, 0, 44), "普通重生", killChar)
		makeButton(pageDie, UDim2.new(0.52, 0, 0, 4), UDim2.new(0.48, 0, 0, 44), "爆炸重生", function()
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					local ex = Instance.new("Explosion")
					ex.Position = root.Position
					ex.BlastRadius = 10
					ex.Parent = workspace
				end
			end
			task.delay(0.15, killChar)
		end)
		makeButton(pageDie, UDim2.new(0, 0, 0, 58), UDim2.new(0.48, 0, 0, 44), "身体分离", function()
			local c = char
			if not c then return end
			c.Archivable = true
			local okClone, clone = pcall(function() return c:Clone() end)
			if not okClone or not clone then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") then p.LocalTransparencyModifier = 1 end
			end
			clone.Parent = workspace
			for _, v in ipairs(clone:GetDescendants()) do
				if v:IsA("Motor6D") or v:IsA("Weld") or v:IsA("WeldConstraint") then
					pcall(function() v:Destroy() end)
				end
			end
			for _, part in ipairs(clone:GetChildren()) do
				if part:IsA("BasePart") then
					local n = part.Name
					if n:find("Arm") or n:find("Hand") then
						part.AssemblyLinearVelocity = Vector3.new(math.random(-50, 50), 50, math.random(-50, 50))
						part.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), math.random(-8, 8), 0)
					elseif n:find("Leg") or n:find("Foot") then
						part.AssemblyLinearVelocity = Vector3.new(math.random(-50, 50), 35, math.random(-50, 50))
						part.AssemblyAngularVelocity = Vector3.new(math.random(-8, 8), 0, math.random(-8, 8))
					elseif n == "Torso" or n == "UpperTorso" or n == "LowerTorso" then
						part.AssemblyLinearVelocity = Vector3.new(0, 80, 0)
					elseif n == "Head" then
						part.AssemblyLinearVelocity = Vector3.new(math.random(-25, 25), 60, math.random(-25, 25))
					else
						part.AssemblyLinearVelocity = Vector3.new(0, 20, 0)
					end
					part.CanCollide = true
				end
			end
			game:GetService("Debris"):AddItem(clone, 5)
			task.delay(0.4, killChar)
		end)
		makeButton(pageDie, UDim2.new(0.52, 0, 0, 58), UDim2.new(0.48, 0, 0, 44), "头分离", function()
			local c = char
			if not c then return end
			local head = c:FindFirstChild("Head")
			if not head then return end
			head.Archivable = true
			local okClone, fake = pcall(function() return head:Clone() end)
			if not okClone or not fake then return end
			fake.CFrame = head.CFrame
			fake.CanCollide = false
			fake.Parent = workspace
			fake.AssemblyLinearVelocity = Vector3.new(math.random(-15, 15), 240, math.random(-15, 15))
			fake.AssemblyAngularVelocity = Vector3.new(math.random(-12, 12), math.random(-12, 12), 0)
			game:GetService("Debris"):AddItem(fake, 5)
			head.LocalTransparencyModifier = 1
			for _, d in ipairs(head:GetDescendants()) do
				if d:IsA("Decal") then d.Transparency = 1 end
			end
			task.delay(5, function()
				if head and head.Parent then
					head.LocalTransparencyModifier = 0
					for _, d in ipairs(head:GetDescendants()) do
						if d:IsA("Decal") then d.Transparency = 0 end
					end
				end
			end)
		end)
		pageDie.CanvasSize = UDim2.new(0, 0, 0, 120)
	end)
	safeSection("服务器", function()
		local pageServer = createPage("server", "服务器", "点「玩家 ▶」展开该服务器在线玩家名单和ID")
		local topBar = Instance.new("Frame")
		topBar.Position = UDim2.new(0, 0, 0, 4)
		topBar.Size = UDim2.new(1, -8, 0, 34)
		topBar.BackgroundTransparency = 1
		topBar.Parent = pageServer
		makeButton(topBar, UDim2.new(0, 0, 0, 0), UDim2.new(0.32, 0, 0, 34), "重进本服", function()
			applyAutoBeforeTeleport()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
		end)
		makeButton(topBar, UDim2.new(0.34, 0, 0, 0), UDim2.new(0.32, 0, 0, 34), "离开服务器", function()
			player:Kick("已离开服务器")
		end)
		local serverEntries = {}
		local function relayoutServers()
			local y = 46
			for _, e in ipairs(serverEntries) do
				e.box.Position = UDim2.new(0, 0, 0, y)
				y = y + (e.expanded and (38 + e.h) or 34) + 4
			end
			pageServer.CanvasSize = UDim2.new(0, 0, 0, y + 10)
		end
		local function fetchServerPlayers()
			local map = {}
			local reqFunc = (syn and syn.request) or request or http_request
			if not reqFunc then return map end
			for st = 0, 30, 10 do
				local okR, res = pcall(function()
					return reqFunc({
						Url = ("https://www.roblox.com/games/getgameinstancesjson?placeId=%d&startindex=%d"):format(game.PlaceId, st),
						Method = "GET",
						Headers = { ["Content-Type"] = "application/json" },
					})
				end)
				if okR and res and res.StatusCode == 200 and res.Body then
					local okJ, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
					if okJ and data and data.Games then
						for _, g in ipairs(data.Games) do
							if g.Id then map[g.Id] = g.CurrentPlayers or {} end
						end
						if #data.Games < 10 then break end
					else
						break
					end
				else
					break
				end
			end
			return map
		end
		local function makeServerEntry(s, players)
			local entry = { expanded = false, h = 30 }
			local box = Instance.new("Frame")
			box.BackgroundTransparency = 1
			box.ClipsDescendants = true
			box.Size = UDim2.new(1, -8, 0, 34)
			box.Parent = pageServer
			entry.box = box
			local joinBtn = makeButton(box, UDim2.new(0, 0, 0, 0), UDim2.new(1, -66, 0, 34),
				string.format("%d/%d 人 · 延迟 %dms · %s",
					tonumber(s.playing) or 0, tonumber(s.maxPlayers) or 0,
					tonumber(s.ping) or 0, tostring(s.id or "?"):sub(1, 8)), nil)
			joinBtn.TextSize = 12
			joinBtn.MouseButton1Click:Connect(function()
				applyAutoBeforeTeleport()
				TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, player)
			end)
			local expandBtn = makeButton(box, UDim2.new(1, -62, 0, 0), UDim2.new(0, 62, 0, 34), "玩家 ▶", nil)
			expandBtn.TextSize = 12
			local listFrame = Instance.new("Frame")
			listFrame.Position = UDim2.new(0, 8, 0, 38)
			listFrame.Size = UDim2.new(1, -16, 0, 0)
			listFrame.BackgroundTransparency = 1
			listFrame.Parent = box
			local rows = 0
			if players and #players > 0 then
				for i, p in ipairs(players) do
					makeLabel(listFrame, UDim2.new(0, 0, 0, (i - 1) * 26), UDim2.new(1, 0, 0, 24),
						string.format("%s  ·  ID %d", tostring(p.Username), tonumber(p.Id) or 0), 11)
					rows = rows + 1
				end
			else
				makeLabel(listFrame, UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, 24), "（无法获取玩家列表）", 11)
				rows = 1
			end
			entry.h = rows * 26 + 6
			listFrame.Size = UDim2.new(1, -16, 0, entry.h)
			expandBtn.MouseButton1Click:Connect(function()
				entry.expanded = not entry.expanded
				expandBtn.Text = entry.expanded and "玩家 ▼" or "玩家 ▶"
				tween(box, 0.2, Enum.EasingStyle.Quint, {
					Size = UDim2.new(1, -8, 0, entry.expanded and (38 + entry.h) or 34)})
				relayoutServers()
			end)
			return entry
		end
		local function loadServers()
			for _, e in ipairs(serverEntries) do e.box:Destroy() end
			serverEntries = {}
			local status = makeLabel(pageServer, UDim2.new(0, 0, 0, 46), UDim2.new(1, 0, 0, 30), "正在获取服务器列表…", 13)
			local reqFunc = (syn and syn.request) or request or http_request
			if not reqFunc then
				status.Text = "此注入器不支持 HTTP 请求"
				return
			end
			local okR, res = pcall(function()
				return reqFunc({
					Url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId),
					Method = "GET",
					Headers = { ["Content-Type"] = "application/json" },
				})
			end)
			if not okR or not res or res.StatusCode ~= 200 then
				status.Text = "获取失败，请重试"
				return
			end
			local okJ, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
			if not okJ or not data or not data.data then
				status.Text = "解析失败"
				return
			end
			local playerMap = fetchServerPlayers()
			status:Destroy()
			for _, s in ipairs(data.data) do
				if s.id and s.id ~= game.JobId then
					table.insert(serverEntries, makeServerEntry(s, playerMap[s.id]))
				end
			end
			if #serverEntries == 0 then
				makeLabel(pageServer, UDim2.new(0, 0, 0, 46), UDim2.new(1, 0, 0, 30), "没有其他服务器", 13)
			end
			relayoutServers()
		end
		makeButton(topBar, UDim2.new(0.68, 0, 0, 0), UDim2.new(0.32, 0, 0, 34), "刷新列表", loadServers)
		loadServers()
	end)
	local bgTransSlider
	safeSection("菜单背景", function()
		local pageBg = createPage("bg", "背景", "默认 = 液态玻璃。图片放 workspace/" .. BG_FOLDER .. "，命名如 " .. BG_PRE .. "1.png")
		makeButton(pageBg, UDim2.new(0, 0, 0, 4), UDim2.new(0, 100, 0, 30), "刷新列表", nil)
		bgTransSlider = makeSlider(pageBg, 40, "背景图透明度 %", 90, 90, math.floor(CONFIG.bgTrans * 100), function(v)
			CONFIG.bgTrans = v / 100
			if BACKGROUND.imageLabel and BACKGROUND.imageLabel.Image ~= "" then
				BACKGROUND.imageLabel.ImageTransparency = CONFIG.bgTrans
			end
		end)
		local function loadBgList()
			for _, c in ipairs(pageBg:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end
			if not fileFunc.list then
				makeLabel(pageBg, UDim2.new(0, 0, 0, 94), UDim2.new(1, 0, 0, 30), "此注入器不支持文件功能", 13)
				return
			end
			local files = scanBackgrounds()
			local y = 94
			local defaultBtn = makeButton(pageBg, UDim2.new(0, 0, 0, y), UDim2.new(1, -8, 0, 34), "默认（液态玻璃）", nil)
			defaultBtn.TextSize = 13
			defaultBtn.MouseButton1Click:Connect(function()
				applyBackground("")
				loadBgList()
			end)
			y = y + 38
			for _, path in ipairs(files) do
				local name = string.match(path, "[^/\\]+$")
				local b = makeButton(pageBg, UDim2.new(0, 0, 0, y), UDim2.new(1, -8, 0, 34), name, nil)
				b.TextSize = 13
				b.MouseButton1Click:Connect(function() applyBackground(path) end)
				y = y + 38
			end
			if #files == 0 then
				makeLabel(pageBg, UDim2.new(0, 0, 0, y + 6), UDim2.new(1, 0, 0, 30),
					"没有找到图片，请放入 " .. BG_FOLDER .. " 文件夹", 13)
				y = y + 40
			end
			pageBg.CanvasSize = UDim2.new(0, 0, 0, y + 10)
		end
		for _, c in ipairs(pageBg:GetChildren()) do
			if c:IsA("TextButton") and c.Text == "刷新列表" then
				c.MouseButton1Click:Connect(loadBgList)
			end
		end
		_G.TvTLoadBg = loadBgList
	end)
	safeSection("音乐", function()
		local pageMusic = createPage("music", "音乐", "输入 ID 或链接，输入框内容不会自动清空")
		local sound = Instance.new("Sound")
		sound.Volume = 1
		sound.Parent = gui
		local idBox = makeInputBox(pageMusic, UDim2.new(0, 0, 0, 4), UDim2.new(1, 0, 0, 32), "")
		idBox.TextXAlignment = Enum.TextXAlignment.Left
		idBox.Font = Enum.Font.Gotham
		idBox.PlaceholderText = "输入音乐 ID"
		local playing = false
		local playBtn = makeButton(pageMusic, UDim2.new(0, 0, 0, 44), UDim2.new(0.48, 0, 0, 34), "播放", nil)
		makeButton(pageMusic, UDim2.new(0.52, 0, 0, 44), UDim2.new(0.48, 0, 0, 34), "停止", function()
			sound:Stop()
			playing = false
			playBtn.Text = "播放"
		end)
		playBtn.MouseButton1Click:Connect(function()
			local raw = idBox.Text
			if raw == "" then return end
			local id = raw:gsub("%D", "")
			if id == "" then return end
			if not playing then
				if sound.SoundId ~= "rbxassetid://" .. id then
					sound.SoundId = "rbxassetid://" .. id
					sound.TimePosition = 0
				end
				sound:Play()
				playing = true
				playBtn.Text = "暂停"
			else
				sound:Pause()
				playing = false
				playBtn.Text = "播放"
			end
		end)
		sound.Ended:Connect(function()
			playing = false
			playBtn.Text = "播放"
		end)
		local timeLabel = makeLabel(pageMusic, UDim2.new(0, 0, 0, 88), UDim2.new(0, 60, 0, 16), "0:00", 12)
		local totalLabel = makeLabel(pageMusic, UDim2.new(1, -60, 0, 88), UDim2.new(0, 60, 0, 16), "0:00", 12, false, Enum.TextXAlignment.Right)
		local progBar = Instance.new("Frame")
		progBar.Position = UDim2.new(0, 0, 0, 108)
		progBar.Size = UDim2.new(1, 0, 0, 8)
		makeGlass(progBar, 999, 0.4)
		progBar.Parent = pageMusic
		local progFill = Instance.new("Frame")
		progFill.Size = UDim2.new(0, 0, 1, 0)
		progFill.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
		progFill.BackgroundTransparency = 0.25
		local pfc = Instance.new("UICorner")
		pfc.CornerRadius = UDim.new(1, 0)
		pfc.Parent = progFill
		progFill.Parent = progBar
		local function fmt(t)
			t = math.max(0, math.floor(t))
			return string.format("%d:%02d", math.floor(t / 60), t % 60)
		end
		local progDragging = false
		local function seek(input)
			if sound.TimeLength > 0 then
				local alpha = math.clamp((input.Position.X - progBar.AbsolutePosition.X) / progBar.AbsoluteSize.X, 0, 1)
				sound.TimePosition = alpha * sound.TimeLength
			end
		end
		progBar.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				progDragging = true
				seek(input)
			end
		end)
		progBar.InputChanged:Connect(function(input)
			if progDragging and (input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch) then
				seek(input)
			end
		end)
		progBar.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch then
				progDragging = false
			end
		end)
		makeSlider(pageMusic, 126, "音量（最大10）", 10, 10, 1, function(v)
			sound.Volume = v
		end, 1)
		makeSlider(pageMusic, 172, "音乐速度", 1000, 1000, 1, function(v)
			sound.PlaybackSpeed = v
		end, 1)
		makeLabel(pageMusic, UDim2.new(0, 0, 0, 216), UDim2.new(0, 160, 0, 24), "循环播放", 14, true)
		makeSwitch(pageMusic, UDim2.new(1, -38, 0, 218), false, function(v)
			sound.Looped = v
		end)
		pageMusic.CanvasSize = UDim2.new(0, 0, 0, 255)
		_G.TvTUIConn = RunService.RenderStepped:Connect(function()
			if sound.TimeLength > 0 then
				progFill.Size = UDim2.new(math.clamp(sound.TimePosition / sound.TimeLength, 0, 1), 0, 1, 0)
				totalLabel.Text = fmt(sound.TimeLength)
			else
				totalLabel.Text = "0:00"
			end
			timeLabel.Text = fmt(sound.TimePosition)
		end)
	end)
	safeSection("自动", function()
		local pageAuto = createPage("auto", "自动执行", "开启后，进任何服务器都自动运行本脚本")
		local autoStatus = makeLabel(pageAuto, UDim2.new(0, 0, 0, 40), UDim2.new(1, -8, 0, 60), "", 12)
		local function findScriptFile()
			local candidates = {
				"TvT_Hub/script.lua", "TvT_Hub/script.txt",
				"tvt.lua", "TVT.lua", "TvT.lua", "TvT_Hub.lua", "script.lua",
			}
			for _, p in ipairs(candidates) do
				local ok, r = pcall(function() return isfile(p) end)
				if ok and r then return p end
			end
			local found = nil
			pcall(function()
				for _, p in ipairs(listfiles("")) do
					if string.match(p, "%.lua$") and not string.match(p, "TvT_Auto") then
						found = p
						break
					end
				end
			end)
			return found
		end
		local function refreshAutoStatus(msg)
			if msg then autoStatus.Text = msg return end
			local okF, fileExists = pcall(function() return isfile("autoexec/TvT_Auto.lua") end)
			if okF and fileExists then
				autoStatus.Text = "状态：已开启（进任何服务器自动执行）"
			else
				autoStatus.Text = "状态：已关闭"
			end
		end
		makeLabel(pageAuto, UDim2.new(0, 0, 0, 4), UDim2.new(0, 160, 0, 24), "跨服自动执行", 14, true)
		makeSwitch(pageAuto, UDim2.new(1, -38, 0, 6), false, function(v)
			CONFIG.autoExec = v
			if v then
				local path = findScriptFile()
				if not path then
					refreshAutoStatus("开启失败：找不到脚本文件。\n请先在 Delta 编辑器里把本脚本「保存」到 workspace（名字随意，比如 tvt.lua），保存后再开这个开关。")
					return
				end
				local loader = 'loadstring(readfile("' .. path .. '"))()'
				local okW, errW = pcall(function()
					writefile("autoexec/TvT_Auto.lua", loader)
				end)
				if okW then
					refreshAutoStatus("成功！已关联脚本文件：" .. path .. "\n以后进任何服务器都会自动执行。\n如果没效果，在 Delta 脚本列表长按 tvt.lua 勾选自动执行。")
				else
					refreshAutoStatus("写文件失败：" .. tostring(errW))
				end
			else
				pcall(function() delfile("autoexec/TvT_Auto.lua") end)
				refreshAutoStatus()
			end
		end)
		makeLabel(pageAuto, UDim2.new(0, 0, 0, 108), UDim2.new(1, -8, 0, 50),
			"原理：往 autoexec 写一个加载器，每次进游戏自动读取你保存的脚本文件运行。脚本文件只需保存一次，以后更新脚本重新保存即可。", 12)
		refreshAutoStatus()
		pageAuto.CanvasSize = UDim2.new(0, 0, 0, 170)
	end)
	safeSection("娱乐", function()
		local pageFun = createPage("fun", "娱乐", "各种本地娱乐功能")
		makeLabel(pageFun, UDim2.new(0, 0, 0, 4), UDim2.new(0, 160, 0, 24), "游龙模式", 14, true)
		makeSwitch(pageFun, UDim2.new(1, -38, 0, 6), false, function(v)
			CONFIG.dragonOn = v
			if v and hrp then
				CONFIG.dragonBaseY = hrp.Position.Y
			end
		end)
		makeLabel(pageFun, UDim2.new(0, 0, 0, 38), UDim2.new(0, 160, 0, 24), "影分身", 14, true)
		makeSwitch(pageFun, UDim2.new(1, -38, 0, 40), false, function(v)
			CONFIG.cloneOn = v
			if not v and _G.TvTClone then
				pcall(function() _G.TvTClone:Destroy() end)
				_G.TvTClone = nil
			end
		end)
		makeSlider(pageFun, 70, "分身延迟（秒）", 5, 5, CONFIG.cloneDelay, function(v)
			CONFIG.cloneDelay = v
		end)
		makeLabel(pageFun, UDim2.new(0, 0, 0, 120), UDim2.new(0, 160, 0, 24), "死亡回放", 14, true)
		makeSwitch(pageFun, UDim2.new(1, -38, 0, 122), CONFIG.deathMarkOn, function(v)
			CONFIG.deathMarkOn = v
		end)
		makeLabel(pageFun, UDim2.new(0, 0, 0, 154), UDim2.new(0, 200, 0, 24), "放置王座", 14, true)
		makeSwitch(pageFun, UDim2.new(1, -38, 0, 156), false, function(v)
			CONFIG.throneOn = v
			if v then
				spawnThrone()
			else
				destroyThrone(true)
			end
		end)
		makeLabel(pageFun, UDim2.new(0, 0, 0, 188), UDim2.new(1, -8, 0, 24), "崩溃：弹出封号画面，点离开退出游戏", 12)
		makeButton(pageFun, UDim2.new(0, 0, 0, 218), UDim2.new(1, -8, 0, 42), "崩 溃", function()
			local cg = Instance.new("ScreenGui")
			cg.Name = "TvT_Crash"
			cg.ResetOnSpawn = false
			cg.DisplayOrder = 9999
			local okc, huic = pcall(function() return gethui() end)
			cg.Parent = (okc and huic) or playerGui
			local overlay = Instance.new("TextButton")
			overlay.Size = UDim2.new(1, 0, 1, 0)
			overlay.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
			overlay.BackgroundTransparency = 0.1
			overlay.Text = ""
			overlay.ZIndex = 50
			overlay.Parent = cg
			local box = Instance.new("Frame")
			box.Size = UDim2.new(0, 320, 0, 200)
			box.Position = UDim2.new(0.5, -160, 0.5, -100)
			box.BackgroundColor3 = Color3.fromRGB(45, 45, 52)
			box.ZIndex = 51
			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(0, 12)
			bc.Parent = box
			box.Parent = cg
			local t1 = Instance.new("TextLabel")
			t1.Size = UDim2.new(1, -40, 0, 40)
			t1.Position = UDim2.new(0, 20, 0, 20)
			t1.BackgroundTransparency = 1
			t1.Text = "你已被封号"
			t1.TextColor3 = Color3.fromRGB(255, 90, 90)
			t1.TextSize = 24
			t1.Font = Enum.Font.GothamBold
			t1.ZIndex = 52
			t1.Parent = box
			local t2 = Instance.new("TextLabel")
			t2.Size = UDim2.new(1, -40, 0, 60)
			t2.Position = UDim2.new(0, 20, 0, 66)
			t2.BackgroundTransparency = 1
			t2.TextWrapped = true
			t2.Text = "你的账号因违反 Roblox 使用条款已被封禁。\n账号即将被删除，所有数据无法恢复。"
			t2.TextColor3 = Color3.fromRGB(220, 220, 225)
			t2.TextSize = 15
			t2.Font = Enum.Font.Gotham
			t2.ZIndex = 52
			t2.Parent = box
			local leaveBtn = Instance.new("TextButton")
			leaveBtn.Size = UDim2.new(0, 140, 0, 40)
			leaveBtn.Position = UDim2.new(0.5, -70, 1, -60)
			leaveBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
			leaveBtn.Text = "离开"
			leaveBtn.TextColor3 = Color3.new(1, 1, 1)
			leaveBtn.TextSize = 18
			leaveBtn.Font = Enum.Font.GothamBold
			leaveBtn.ZIndex = 52
			local lbc = Instance.new("UICorner")
			lbc.CornerRadius = UDim.new(0, 8)
			lbc.Parent = leaveBtn
			leaveBtn.Parent = box
			leaveBtn.MouseButton1Click:Connect(function()
				player:Kick("你的账号已被删除")
			end)
		end)
		local function swordSlashEffect()
			if not hrp then return end
			local Debris = game:GetService("Debris")
			local rootCF = hrp.CFrame
			local pos = rootCF.Position
			local look = rootCF.LookVector
			local dir = Vector3.new(look.X, 0, look.Z)
			if dir.Magnitude < 0.1 then dir = Vector3.new(0, 0, -1) end
			dir = dir.Unit
			local perp = Vector3.new(-dir.Z, 0, dir.X)
			-- 关键修复：先探测完整条线的地面高度（此刻场上还没有任何特效零件，射线不会被自己的特效挡住）
			local gyList = {}
			for i = 1, 22 do
				local center = pos + dir * (3 + i * 4.5)
				local ray = workspace:Raycast(center + Vector3.new(0, 30, 0), Vector3.new(0, -600, 0))
				gyList[i] = (ray and ray.Position.Y) or (pos.Y - 3.2)
			end
			local craterRay = workspace:Raycast(pos + Vector3.new(0, 30, 0), Vector3.new(0, -600, 0))
			local craterY = (craterRay and craterRay.Position.Y) or (pos.Y - 3.2)
			pcall(function()
				local s = Instance.new("Sound")
				s.SoundId = "rbxasset://sounds/swordslash.wav"
				s.Volume = 1
				s.Parent = hrp
				s:Play()
				Debris:AddItem(s, 2)
			end)
			-- 天上剑气
			local beam = Instance.new("Part")
			beam.Anchored = true
			beam.CanCollide = false
			beam.Material = Enum.Material.Neon
			beam.Color = Color3.fromRGB(170, 235, 255)
			beam.Transparency = 0.1
			beam.Size = Vector3.new(2, 18, 80)
			beam.CFrame = CFrame.new(pos + dir * 40 + Vector3.new(0, 4, 0)) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), math.rad(18))
			beam.Parent = workspace
			TweenService:Create(beam, TweenInfo.new(0.6), { Transparency = 1, Size = Vector3.new(0.3, 28, 80) }):Play()
			Debris:AddItem(beam, 0.7)
			-- 大地裂缝（用提前测好的高度，稳稳贴地）
			for i = 1, 22 do
				local d = 3 + i * 4.5
				local center = pos + dir * d
				local gy = gyList[i]
				local gap = 2 + i * 0.18
				for side = -1, 1, 2 do
					local rock = Instance.new("Part")
					rock.Anchored = true
					rock.CanCollide = false
					rock.Material = Enum.Material.Slate
					rock.Color = Color3.fromRGB(15, 10, 12)
					rock.Size = Vector3.new(2.2 + math.random(0, 20) / 10, 2.5 + math.random(0, 25) / 10, 3.2 + math.random(0, 20) / 10)
					local off = center + perp * (side * (gap / 2 + 1.3))
					rock.CFrame = CFrame.new(off.X, gy + 0.4, off.Z) * CFrame.Angles(math.rad(math.random(-10, 10)), math.rad(math.random(-40, 40)), math.rad(side * math.random(5, 14)))
					rock.Parent = workspace
					Debris:AddItem(rock, 40)
				end
				local lava = Instance.new("Part")
				lava.Anchored = true
				lava.CanCollide = false
				lava.Material = Enum.Material.Neon
				lava.Color = Color3.fromRGB(255, 80, 30)
				lava.Size = Vector3.new(gap, 0.25, 4.4)
				lava.CFrame = CFrame.new(center.X, gy + 0.12, center.Z) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
				lava.Parent = workspace
				Debris:AddItem(lava, 40)
			end
			-- 脚下爆碎岩块（贴地）
			for i = 1, 8 do
				local a = math.rad(i * 45)
				local rock = Instance.new("Part")
				rock.Anchored = true
				rock.CanCollide = false
				rock.Material = Enum.Material.Slate
				rock.Color = Color3.fromRGB(20, 14, 16)
				rock.Size = Vector3.new(1.5 + math.random(0, 15) / 10, 1.5 + math.random(0, 20) / 10, 1.5)
				local off = pos + Vector3.new(math.cos(a) * 3, 0, math.sin(a) * 3)
				rock.CFrame = CFrame.new(off.X, craterY + 0.8, off.Z) * CFrame.Angles(math.rad(math.random(-20, 20)), math.rad(math.random(-40, 40)), math.rad(math.random(-20, 20)))
				rock.Parent = workspace
				Debris:AddItem(rock, 40)
			end
			local ring = Instance.new("Part")
			ring.Shape = Enum.PartType.Cylinder
			ring.Size = Vector3.new(0.3, 4, 4)
			ring.CFrame = CFrame.new(pos.X, craterY + 0.3, pos.Z) * CFrame.Angles(0, 0, math.rad(90))
			ring.Anchored = true
			ring.CanCollide = false
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(170, 235, 255)
			ring.Transparency = 0.2
			ring.Parent = workspace
			TweenService:Create(ring, TweenInfo.new(1), { Size = Vector3.new(0.3, 90, 90), Transparency = 1 }):Play()
			Debris:AddItem(ring, 1.1)
			local flash = Instance.new("PointLight")
			flash.Color = Color3.fromRGB(200, 240, 255)
			flash.Range = 40
			flash.Brightness = 8
			flash.Parent = hrp
			TweenService:Create(flash, TweenInfo.new(1.2), { Brightness = 0 }):Play()
			Debris:AddItem(flash, 1.4)
			local cam = workspace.CurrentCamera
			if cam then
				task.spawn(function()
					for i = 1, 14 do
						pcall(function()
							cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * 0.7, (math.random() - 0.5) * 0.7, 0)
						end)
						task.wait(0.03)
					end
				end)
			end
		end
		local function giveSword()
			pcall(function()
				local bp = player:FindFirstChildOfClass("Backpack")
				if bp then
					local old = bp:FindFirstChild("TvT_Sword")
					if old then old:Destroy() end
				end
				if char then
					local old2 = char:FindFirstChild("TvT_Sword")
					if old2 then old2:Destroy() end
				end
			end)
			local tool = Instance.new("Tool")
			tool.Name = "TvT_Sword"
			tool.RequiresHandle = true
			tool.ToolTip = "挥动它，劈开大地（20秒后被踢）"
			local handle = Instance.new("Part")
			handle.Name = "Handle"
			handle.Size = Vector3.new(0.4, 1.6, 0.4)
			handle.Color = Color3.fromRGB(45, 38, 55)
			handle.Material = Enum.Material.Granite
			handle.Parent = tool
			local blade = Instance.new("Part")
			blade.Size = Vector3.new(0.14, 4.6, 0.8)
			blade.Color = Color3.fromRGB(215, 245, 255)
			blade.Material = Enum.Material.Neon
			blade.Parent = tool
			local w = Instance.new("Weld")
			w.Part0 = handle
			w.Part1 = blade
			w.C0 = CFrame.new(0, 3.0, 0)
			w.Parent = blade
			local guard = Instance.new("Part")
			guard.Size = Vector3.new(1.2, 0.25, 1.2)
			guard.Color = Color3.fromRGB(215, 175, 90)
			guard.Material = Enum.Material.SmoothPlastic
			guard.Parent = tool
			local w2 = Instance.new("Weld")
			w2.Part0 = handle
			w2.Part1 = guard
			w2.C0 = CFrame.new(0, 0.9, 0)
			w2.Parent = guard
			tool.Parent = player:FindFirstChildOfClass("Backpack") or playerGui
			local swung = false
			tool.Activated:Connect(function()
				if swung then return end
				swung = true
				pcall(swordSlashEffect)
				task.delay(20, function()
					pcall(function() player:Kick("剑气反噬 · 20秒已到") end)
				end)
			end)
		end
		makeLabel(pageFun, UDim2.new(0, 0, 0, 270), UDim2.new(1, -8, 0, 24), "神剑：获得后装备，点击挥动 → 剑气劈裂大地，20秒后被踢", 12)
		makeButton(pageFun, UDim2.new(0, 0, 0, 300), UDim2.new(1, -8, 0, 40), "一剑开天", function()
			giveSword()
		end)
		pageFun.CanvasSize = UDim2.new(0, 0, 0, 355)
		task.spawn(function()
			while true do
				task.wait(0.45)
				if CONFIG.dragonOn then
					CONFIG.dragonLay = not CONFIG.dragonLay
				end
			end
		end)
		local cloneBuf = {}
		task.spawn(function()
			while true do
				task.wait(0.1)
				if CONFIG.cloneOn then
					if hrp and humanoid and humanoid.Health > 0 then
						table.insert(cloneBuf, { t = os.clock(), cf = hrp.CFrame })
						local keep = CONFIG.cloneDelay + 2
						while #cloneBuf > 2 and cloneBuf[1].t < os.clock() - keep do
							table.remove(cloneBuf, 1)
						end
						if _G.TvTClone == nil or _G.TvTClone.Parent == nil or not _G.TvTClone:IsDescendantOf(workspace) then
							pcall(function() if _G.TvTClone then _G.TvTClone:Destroy() end end)
							char.Archivable = true
							local okc2, c = pcall(function() return char:Clone() end)
							if okc2 and c then
								for _, p in ipairs(c:GetDescendants()) do
									if p:IsA("BasePart") then
										p.Anchored = true
										p.CanCollide = false
										p.LocalTransparencyModifier = 0.45
									elseif p:IsA("Decal") then
										p.Transparency = 0.5
									end
								end
								local ch = c:FindFirstChildOfClass("Humanoid")
								if ch then
									ch.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
								end
								c.Parent = workspace
								_G.TvTClone = c
							end
						end
						if _G.TvTClone then
							local targetT = os.clock() - CONFIG.cloneDelay
							local bestCF = nil
							for i = #cloneBuf, 1, -1 do
								if cloneBuf[i].t <= targetT then
									bestCF = cloneBuf[i].cf
									break
								end
							end
							local cr = _G.TvTClone:FindFirstChild("HumanoidRootPart")
							if bestCF and cr then
								cr.CFrame = bestCF
							end
						end
					end
				else
					if #cloneBuf > 0 then cloneBuf = {} end
				end
			end
		end)
		markKiller = function()
			pcall(function()
				if _G.TvTDeathMark then _G.TvTDeathMark:Destroy() end
			end)
			_G.TvTDeathMark = nil
			local myPos = hrp and hrp.Position or nil
			if not myPos then return end
			local best, bestDist = nil, 80
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= player and pl.Character and pl.Character:FindFirstChild("Humanoid")
					and pl.Character.Humanoid.Health > 0 then
					local r = pl.Character:FindFirstChild("HumanoidRootPart")
					if r then
						local d = (r.Position - myPos).Magnitude
						if d < bestDist then
							best, bestDist = pl, d
						end
					end
				end
			end
			if not best then return end
			local folder = Instance.new("Folder")
			folder.Name = "TvT_KillerMark"
			local hl = Instance.new("Highlight")
			hl.FillColor = Color3.fromRGB(255, 40, 40)
			hl.OutlineColor = Color3.fromRGB(255, 120, 120)
			hl.FillTransparency = 0.5
			hl.OutlineTransparency = 0
			hl.Adornee = best.Character
			hl.Parent = folder
			local head = best.Character:FindFirstChild("Head")
			if head then
				local bb = Instance.new("BillboardGui")
				bb.Adornee = head
				bb.Size = UDim2.new(0, 140, 0, 44)
				bb.StudsOffset = Vector3.new(0, 2.5, 0)
				bb.AlwaysOnTop = true
				local tl = Instance.new("TextLabel")
				tl.Size = UDim2.new(1, 0, 1, 0)
				tl.BackgroundTransparency = 1
				tl.TextWrapped = true
				tl.Text = "击杀者\n" .. best.Name
				tl.TextColor3 = Color3.fromRGB(255, 70, 70)
				tl.TextSize = 14
				tl.Font = Enum.Font.GothamBold
				tl.Parent = bb
				bb.Parent = folder
			end
			folder.Parent = workspace
			_G.TvTDeathMark = folder
		end
		clearDeathMark = function()
			pcall(function() if _G.TvTDeathMark then _G.TvTDeathMark:Destroy() end end)
			_G.TvTDeathMark = nil
		end
		function destroyThrone(sink)
			local m = _G.TvTThrone
			if not m then return end
			_G.TvTThrone = nil
			pcall(function()
				if humanoid and humanoid.SeatPart and humanoid.SeatPart:IsDescendantOf(m) then
					humanoid.Sit = false
					humanoid.Jump = true
				end
			end)
			if sink then
				local base = m:FindFirstChild("TBase")
				if base then
					local tw = TweenService:Create(base, TweenInfo.new(1.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { CFrame = base.CFrame * CFrame.new(0, -9, 0) })
					tw:Play()
					tw.Completed:Connect(function() pcall(function() m:Destroy() end) end)
					task.delay(1.6, function() pcall(function() m:Destroy() end) end)
				else
					pcall(function() m:Destroy() end)
				end
			else
				pcall(function() m:Destroy() end)
			end
		end
		function spawnThrone()
			destroyThrone(false)
			if not hrp then return end
			local flatLook = hrp.CFrame.LookVector
			local dir = Vector3.new(flatLook.X, 0, flatLook.Z)
			if dir.Magnitude < 0.1 then dir = Vector3.new(0, 0, -1) end
			dir = dir.Unit
			local origin = hrp.Position + dir * 7 + Vector3.new(0, 30, 0)
			local ray = workspace:Raycast(origin, Vector3.new(0, -300, 0))
			local gy = (ray and ray.Position.Y) or (hrp.Position.Y - 3)
			local cx, cz = origin.X, origin.Z
			local targetCF = CFrame.new(Vector3.new(cx, gy + 2.2, cz))
			local m = Instance.new("Model")
			m.Name = "TvT_Throne"
			local parts = {}
			local function addP(size, off, color, mat, shape)
				local p = Instance.new("Part")
				p.Size = size
				p.CFrame = targetCF * off
				p.Color = color
				p.Material = mat or Enum.Material.Granite
				if shape then p.Shape = shape end
				p.Anchored = true
				p.CanCollide = true
				p.Parent = m
				table.insert(parts, p)
				return p
			end
			addP(Vector3.new(7, 0.5, 7), CFrame.new(0, -1.9, 0), Color3.fromRGB(25, 23, 35))
			addP(Vector3.new(5.6, 0.5, 5.6), CFrame.new(0, -1.4, 0), Color3.fromRGB(32, 30, 45))
			local base = addP(Vector3.new(4.4, 0.8, 4.4), CFrame.new(0, -0.6, 0), Color3.fromRGB(38, 35, 52))
			base.Name = "TBase"
			local seat = Instance.new("Seat")
			seat.Size = Vector3.new(2.2, 0.6, 2.2)
			seat.CFrame = targetCF * CFrame.new(0, 0.1, 0.3)
			seat.Color = Color3.fromRGB(200, 165, 90)
			seat.Material = Enum.Material.SmoothPlastic
			seat.Anchored = true
			seat.Parent = m
			table.insert(parts, seat)
			addP(Vector3.new(2.6, 3.4, 0.5), CFrame.new(0, 1.8, 1.15), Color3.fromRGB(38, 35, 52))
			addP(Vector3.new(2.6, 0.35, 0.6), CFrame.new(0, 3.55, 1.15), Color3.fromRGB(215, 175, 90), Enum.Material.SmoothPlastic)
			addP(Vector3.new(0.45, 1.1, 0.45), CFrame.new(-1.05, 4.2, 1.15), Color3.fromRGB(38, 35, 52))
			addP(Vector3.new(0.45, 1.1, 0.45), CFrame.new(1.05, 4.2, 1.15), Color3.fromRGB(38, 35, 52))
			addP(Vector3.new(0.55, 0.55, 0.55), CFrame.new(-1.05, 4.95, 1.15), Color3.fromRGB(170, 90, 255), Enum.Material.Neon, Enum.PartType.Ball)
			addP(Vector3.new(0.55, 0.55, 0.55), CFrame.new(1.05, 4.95, 1.15), Color3.fromRGB(170, 90, 255), Enum.Material.Neon, Enum.PartType.Ball)
			addP(Vector3.new(0.5, 1.1, 2.2), CFrame.new(-1.45, 0.75, 0.3), Color3.fromRGB(38, 35, 52))
			addP(Vector3.new(0.5, 1.1, 2.2), CFrame.new(1.45, 0.75, 0.3), Color3.fromRGB(38, 35, 52))
			addP(Vector3.new(0.6, 0.25, 0.6), CFrame.new(-1.45, 1.4, 1.15), Color3.fromRGB(215, 175, 90), Enum.Material.SmoothPlastic)
			addP(Vector3.new(0.6, 0.25, 0.6), CFrame.new(1.45, 1.4, 1.15), Color3.fromRGB(215, 175, 90), Enum.Material.SmoothPlastic)
			addP(Vector3.new(4.5, 0.15, 4.5), CFrame.new(0, -0.15, 0), Color3.fromRGB(170, 90, 255), Enum.Material.Neon)
			local light = Instance.new("PointLight")
			light.Color = Color3.fromRGB(170, 90, 255)
			light.Range = 18
			light.Brightness = 0
			light.Parent = base
			local pe = Instance.new("ParticleEmitter")
			pe.Rate = 70
			pe.Lifetime = NumberRange.new(0.5, 1.2)
			pe.Speed = NumberRange.new(4, 10)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.Color = ColorSequence.new(Color3.fromRGB(190, 120, 255), Color3.fromRGB(255, 210, 120))
			pe.Size = NumberSequence.new(0.4)
			pe.LightEmission = 1
			pe.Enabled = false
			pe.Parent = base
			m.Parent = workspace
			_G.TvTThrone = m
			local ring = Instance.new("Part")
			ring.Shape = Enum.PartType.Cylinder
			ring.Size = Vector3.new(0.2, 2, 2)
			ring.CFrame = CFrame.new(Vector3.new(cx, gy + 0.15, cz)) * CFrame.Angles(0, 0, math.rad(90))
			ring.Anchored = true
			ring.CanCollide = false
			ring.Material = Enum.Material.Neon
			ring.Color = Color3.fromRGB(190, 120, 255)
			ring.Transparency = 0.3
			ring.Parent = workspace
			TweenService:Create(ring, TweenInfo.new(0.9, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = Vector3.new(0.2, 30, 30), Transparency = 1 }):Play()
			game:GetService("Debris"):AddItem(ring, 1)
			pe.Enabled = true
			local twInfo = TweenInfo.new(2.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
			for _, p in ipairs(parts) do
				p.CFrame = p.CFrame * CFrame.new(0, -9, 0)
				TweenService:Create(p, twInfo, { CFrame = p.CFrame * CFrame.new(0, 9, 0) }):Play()
			end
			TweenService:Create(light, TweenInfo.new(1.5), { Brightness = 2.2 }):Play()
			task.delay(2.5, function() pcall(function() pe.Enabled = false end) end)
		end
	end)
	safeSection("设置", function()
		local pageSettings = createPage("settings", "设置", "外观设置立即生效并永久保存")
		reloadScript = function()
			pcall(function() gui:Destroy() end)
			for _, key in ipairs({ "TvTConn", "TvTUIConn", "TvTESPConn" }) do
				if _G[key] then
					pcall(function() _G[key]:Disconnect() end)
					_G[key] = nil
				end
			end
			task.delay(0.1, function()
				local ok2, err2 = xpcall(build, function(m) return debug.traceback(m, 1) end)
				if not ok2 then warn("[TvT_Hub] 重载出错:", err2) end
			end)
		end
		local function closeScript()
			pcall(function() gui:Destroy() end)
			for _, key in ipairs({ "TvTConn", "TvTUIConn", "TvTESPConn" }) do
				if _G[key] then
					pcall(function() _G[key]:Disconnect() end)
					_G[key] = nil
				end
			end
		end
		local function saveIslandPref()
			pcall(function()
				local c = island.BackgroundColor3
				writefile("TvT_Hub/island.txt", tostring(math.floor(c.R * 255)) .. "," .. tostring(math.floor(c.G * 255)) .. "," .. tostring(math.floor(c.B * 255)) .. "|" .. tostring(island.BackgroundTransparency))
			end)
		end
		makeLabel(pageSettings, UDim2.new(0, 0, 0, 4), UDim2.new(0, 160, 0, 24), "深色模式", 14, true)
		makeSwitch(pageSettings, UDim2.new(1, -38, 0, 6), THEME.dark, function(v)
			pcall(function() writefile("TvT_Hub/theme.txt", v and "dark" or "light") end)
			task.delay(0.2, reloadScript)
		end)
		makeLabel(pageSettings, UDim2.new(0, 0, 0, 38), UDim2.new(0, 160, 0, 24), "纯透明背景", 14, true)
		makeSwitch(pageSettings, UDim2.new(1, -38, 0, 40), THEME.invis, function(v)
			THEME.invis = v
			main.BackgroundTransparency = v and 1 or 0.5
			mainStroke.Enabled = v
			pcall(function() writefile("TvT_Hub/invis.txt", v and "1" or "0") end)
		end)
		makeSlider(pageSettings, 72, "灵动岛透明度 %", 90, 90, math.floor(ISLAND_TRANS * 100), function(v)
			island.BackgroundTransparency = v / 100
			saveIslandPref()
		end)
		makeLabel(pageSettings, UDim2.new(0, 0, 0, 122), UDim2.new(0, 200, 0, 24), "灵动岛颜色：", 14, true)
		local paletteFrame = Instance.new("Frame")
		paletteFrame.Size = UDim2.new(0, 320, 0, 340)
		paletteFrame.Position = UDim2.new(0.5, -160, 0.5, -170)
		makeGlass(paletteFrame, 20, 0.1)
		paletteFrame.Visible = false
		paletteFrame.ZIndex = 40
		paletteFrame.Parent = main
		local pTitle = makeLabel(paletteFrame, UDim2.new(0, 16, 0, 10), UDim2.new(1, -60, 0, 26), "调色盘", 16, true)
		pTitle.ZIndex = 41
		local pClose = makeButton(paletteFrame, UDim2.new(1, -40, 0, 10), UDim2.new(0, 28, 0, 28), "×", function()
			paletteFrame.Visible = false
		end)
		pClose.TextSize = 18
		pClose.ZIndex = 41
		local selectedColor = ISLAND_COLOR
		local preview = Instance.new("Frame")
		preview.Size = UDim2.new(0, 44, 0, 44)
		preview.Position = UDim2.new(0.5, -22, 0, 246)
		preview.BackgroundColor3 = selectedColor
		preview.ZIndex = 41
		local pvc = Instance.new("UICorner")
		pvc.CornerRadius = UDim.new(1, 0)
		pvc.Parent = preview
		preview.Parent = paletteFrame
		local wheelDots = {}
		local function makeDot(x, y, color)
			local dot = makeButton(paletteFrame, UDim2.new(0, x - 13, 0, y - 13), UDim2.new(0, 26, 0, 26), "", nil)
			dot.BackgroundColor3 = color
			dot.BackgroundTransparency = 0.1
			dot.ZIndex = 41
			local dc = Instance.new("UICorner")
			dc.CornerRadius = UDim.new(1, 0)
			dc.Parent = dot
			dot.MouseButton1Click:Connect(function()
				selectedColor = color
				preview.BackgroundColor3 = color
				for _, d in ipairs(wheelDots) do d.BackgroundTransparency = 0.1 end
				dot.BackgroundTransparency = 0
			end)
			table.insert(wheelDots, dot)
			return dot
		end
		for i = 1, 24 do
			local hue = (i - 1) / 24
			local angle = math.rad((i - 1) * 15 - 90)
			makeDot(160 + math.cos(angle) * 96, 148 + math.sin(angle) * 96, Color3.fromHSV(hue, 0.85, 1))
		end
		for i = 1, 6 do
			local v = 0.2 + (i - 1) * 0.16
			local angle = math.rad((i - 1) * 60 - 90)
			makeDot(160 + math.cos(angle) * 42, 148 + math.sin(angle) * 42, Color3.fromHSV(0, 0, v))
		end
		local okBtn = makeButton(paletteFrame, UDim2.new(0, 40, 1, -46), UDim2.new(0, 90, 0, 32), "确定", function()
			paletteFrame.Visible = false
			island.BackgroundColor3 = selectedColor
			saveIslandPref()
		end)
		okBtn.ZIndex = 41
		local cancelBtn = makeButton(paletteFrame, UDim2.new(1, -130, 1, -46), UDim2.new(0, 90, 0, 32), "取消", function()
			paletteFrame.Visible = false
		end)
		cancelBtn.ZIndex = 41
		local islColors = {
			{ "白", Color3.fromRGB(255, 255, 255) },
			{ "黑", Color3.fromRGB(35, 35, 42) },
			{ "红", Color3.fromRGB(255, 90, 90) },
			{ "蓝", Color3.fromRGB(90, 160, 255) },
			{ "紫", Color3.fromRGB(180, 110, 255) },
			{ "金", Color3.fromRGB(255, 205, 110) },
		}
		for i, c in ipairs(islColors) do
			local b = makeButton(pageSettings, UDim2.new(0, (i - 1) * 50, 0, 148), UDim2.new(0, 44, 0, 28), c[1], function()
				island.BackgroundColor3 = c[2]
				selectedColor = c[2]
				preview.BackgroundColor3 = c[2]
				saveIslandPref()
			end)
			b.BackgroundColor3 = c[2]
			if c[1] == "黑" then b.TextColor3 = Color3.new(1, 1, 1) end
		end
		makeButton(pageSettings, UDim2.new(0, 0, 0, 184), UDim2.new(0, 110, 0, 30), "打开调色盘", function()
			paletteFrame.Visible = true
		end)
		makeLabel(pageSettings, UDim2.new(0, 0, 0, 222), UDim2.new(0, 200, 0, 24), "字体颜色：", 14, true)
		local fontColors = {
			{ "默认", nil },
			{ "", Color3.fromRGB(35, 45, 65) },
			{ "", Color3.fromRGB(220, 60, 60) },
			{ "", Color3.fromRGB(50, 110, 220) },
			{ "", Color3.fromRGB(150, 80, 220) },
			{ "", Color3.fromRGB(190, 140, 40) },
		}
		for i, c in ipairs(fontColors) do
			local b = makeButton(pageSettings, UDim2.new(0, (i - 1) * 50, 0, 248), UDim2.new(0, 44, 0, 28), c[1], function()
				if c[2] == nil then
					pcall(function() delfile("TvT_Hub/fontcolor.txt") end)
				else
					pcall(function()
						writefile("TvT_Hub/fontcolor.txt", tostring(math.floor(c[2].R * 255)) .. "," .. tostring(math.floor(c[2].G * 255)) .. "," .. tostring(math.floor(c[2].B * 255)))
					end)
				end
				task.delay(0.15, reloadScript)
			end)
			if c[2] then
				b.BackgroundColor3 = c[2]
				b.Text = ""
			end
		end
		makeButton(pageSettings, UDim2.new(0, 0, 0, 286), UDim2.new(0.48, 0, 0, 32), "重新加载脚本", reloadScript)
		makeButton(pageSettings, UDim2.new(0.52, 0, 0, 286), UDim2.new(0.48, 0, 0, 32), "关闭脚本", closeScript)
		makeButton(pageSettings, UDim2.new(0, 0, 0, 326), UDim2.new(1, -8, 0, 32), "重置所有功能", function()
			pcall(function()
				if humanoid then
					humanoid.WalkSpeed = 16
					humanoid.UseJumpPower = true
					humanoid.JumpPower = 50
				end
				if hrp then hrp.Anchored = false end
				if char then
					for _, p in ipairs(char:GetDescendants()) do
						if p:IsA("BasePart") then p.CanCollide = true end
					end
				end
			end)
			reloadScript()
		end)
		makeLabel(pageSettings, UDim2.new(0, 0, 0, 366), UDim2.new(1, -8, 0, 40),
			"重置所有功能：把全部功能恢复到默认并刷新界面。", 12)
		pageSettings.CanvasSize = UDim2.new(0, 0, 0, 410)
	end)
	safeSection("关于", function()
		local pageAbout = createPage("about", "关于", "TvT_Hub 脚本信息")
		local injName = "未知"
		pcall(function()
			if identifyexecutor then
				local a, b = identifyexecutor()
				injName = tostring(a) .. (b and (" " .. tostring(b)) or "")
			end
		end)
		local UPDATE_COUNT = 34
		local LAST_UPDATE = "2026年9月6日"
		local qq = "3906339715"
		makeLabel(pageAbout, UDim2.new(0, 0, 0, 4), UDim2.new(1, -8, 0, 24), "注入器：" .. injName, 13, true)
		local timeLbl = makeLabel(pageAbout, UDim2.new(0, 0, 0, 32), UDim2.new(1, -8, 0, 24), "", 13, true)
		task.spawn(function()
			while timeLbl and timeLbl.Parent do
				timeLbl.Text = "现在时间：" .. os.date("%Y年%m月%d日 %H:%M:%S")
				task.wait(1)
			end
		end)
		local lines = {
			"你的 ID：" .. tostring(player.UserId),
			"你的昵称：" .. player.Name .. ((player.DisplayName and player.DisplayName ~= player.Name) and ("（" .. player.DisplayName .. "）") or ""),
			"更新次数：" .. UPDATE_COUNT .. " 次",
			"最近更新：" .. LAST_UPDATE,
			"脚本已加载：" .. tostring(LOAD_COUNT) .. " 次",
		}
		local y = 60
		for _, t in ipairs(lines) do
			makeLabel(pageAbout, UDim2.new(0, 0, 0, y), UDim2.new(1, -8, 0, 24), t, 13, true)
			y = y + 28
		end
		makeLabel(pageAbout, UDim2.new(0, 0, 0, y), UDim2.new(1, -96, 0, 30), "脚本创造者QQ：" .. qq, 14, true)
		local copyBtn = makeButton(pageAbout, UDim2.new(1, -90, 0, y), UDim2.new(0, 86, 0, 30), "复制", nil)
		local copiedTip = makeLabel(pageAbout, UDim2.new(0, 0, 0, y + 36), UDim2.new(1, -8, 0, 22), "", 12)
		copyBtn.MouseButton1Click:Connect(function()
			pcall(function()
				if setclipboard then setclipboard(qq) end
			end)
			copiedTip.Text = "已复制到剪贴板"
			task.delay(2, function() copiedTip.Text = "" end)
		end)
		pageAbout.CanvasSize = UDim2.new(0, 0, 0, y + 70)
	end)
	safeSection("侧栏", function()
		local catGeneral = makeCategory("通用", 1)
		catGeneral.addItem("本地玩家", "local")
		catGeneral.addItem("透视", "esp")
		catGeneral.addItem("玩家", "players")
		catGeneral.addItem("自杀重生", "die")
		catGeneral.addItem("服务器", "server")
		makeSidebarItem("音乐", "music", 3)
		makeSidebarItem("背景", "bg", 4)
		makeSidebarItem("自动执行", "auto", 5)
		makeSidebarItem("娱乐", "fun", 9)
		makeSidebarItem("设置", "settings", 10)
		makeSidebarItem("关于", "about", 11)
		showPage("local")
	end)
	local dragHandle = Instance.new("TextButton")
	dragHandle.Size = UDim2.new(1, -60, 0, 48)
	dragHandle.Position = UDim2.new(0, 0, 0, 0)
	dragHandle.BackgroundTransparency = 1
	dragHandle.Text = ""
	dragHandle.ZIndex = 10
	dragHandle.Parent = main
	attachDrag(dragHandle, nil, main)
	safeSection("核心功能", function()
		local function bindCharacter(c)
			char = c
			humanoid = c:WaitForChild("Humanoid")
			hrp = c:WaitForChild("HumanoidRootPart")
			lastPos = hrp.Position
			lastCFrame = hrp.CFrame
			spinAngle = 0
			CONFIG.dragonLay = false
			pcall(clearDeathMark)
			if CONFIG.speedOn then humanoid.WalkSpeed = CONFIG.speedVal end
			if CONFIG.jumpOn then
				humanoid.UseJumpPower = true
				humanoid.JumpPower = CONFIG.jumpVal
			end
			humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
				if CONFIG.infJumpOn and humanoid.Jump then
					humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end)
			humanoid.Died:Connect(function()
				if CONFIG.deathMarkOn then
					task.wait(0.1)
					pcall(markKiller)
				end
			end)
		end
		if player.Character then bindCharacter(player.Character) end
		player.CharacterAdded:Connect(bindCharacter)
		_G.TvTConn = RunService.Heartbeat:Connect(function(dt)
			if not hrp or not humanoid then return end
			if humanoid.Health <= 0 then return end
			if CONFIG.speedOn and humanoid.WalkSpeed ~= CONFIG.speedVal then
				humanoid.WalkSpeed = CONFIG.speedVal
			end
			if CONFIG.jumpOn and humanoid.JumpPower ~= CONFIG.jumpVal then
				humanoid.UseJumpPower = true
				humanoid.JumpPower = CONFIG.jumpVal
			end
			local selRoot = getSelectedRoot()
			if CONFIG.keepTo and selRoot then
				hrp.CFrame = selRoot.CFrame * CFrame.new(0, 0, -3)
			elseif CONFIG.keepFrom and selRoot then
				selRoot.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
			elseif CONFIG.keepAllFrom then
				forEachOtherRoot(function(r)
					r.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
				end)
			end
			if CONFIG.flyOn then
				local dir = humanoid.MoveDirection
				if dir.Magnitude > 0 then
					hrp.CFrame = CFrame.new(hrp.Position + dir * CONFIG.flyVal * dt)
				end
				hrp.AssemblyLinearVelocity = Vector3.zero
				lastPos = hrp.Position
				lastCFrame = hrp.CFrame
			end
			if CONFIG.autoJumpOn
				and humanoid.FloorMaterial ~= Enum.Material.Air
				and humanoid:GetState() == Enum.HumanoidStateType.Running then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
			if CONFIG.noclipOn and char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then p.CanCollide = false end
				end
			end
			if CONFIG.spinOn then
				spinAngle = (spinAngle + math.rad(CONFIG.spinVal) * dt) % (math.pi * 2)
				hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
				lastPos = hrp.Position
				lastCFrame = hrp.CFrame
			end
			if CONFIG.dragonOn then
				if CONFIG.dragonBaseY == nil then
					CONFIG.dragonBaseY = hrp.Position.Y
				end
				local _, yaw = hrp.CFrame:ToEulerAnglesYXZ()
				local base = hrp.Position + humanoid.MoveDirection * math.max(humanoid.WalkSpeed, 16) * dt
				base = Vector3.new(base.X, CONFIG.dragonBaseY, base.Z)
				if CONFIG.dragonLay then
					hrp.CFrame = CFrame.new(base - Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(-90), 0, 0)
				else
					hrp.CFrame = CFrame.new(base) * CFrame.Angles(0, yaw, 0)
				end
				hrp.AssemblyLinearVelocity = Vector3.zero
				lastPos = hrp.Position
				lastCFrame = hrp.CFrame
			else
				CONFIG.dragonBaseY = nil
			end
			if not CONFIG.antiTeleport then
				lastPos = hrp.Position
				lastCFrame = hrp.CFrame
				return
			end
			if humanoid.SeatPart then
				lastPos = hrp.Position
				lastCFrame = hrp.CFrame
				return
			end
			if hrp.Anchored then hrp.Anchored = false end
			local vel = hrp.AssemblyLinearVelocity
			local hSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
			if hSpeed > CONFIG.flingSpeedLimit and humanoid.MoveDirection.Magnitude < 0.1 then
				hrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(vel.Y, -50, 50), 0)
				return
			end
			local currentPos = hrp.Position
			local predicted = lastPos + vel * dt
			local hErr = math.max(
				math.abs(currentPos.X - predicted.X),
				math.abs(currentPos.Z - predicted.Z))
			local vErr = math.abs(currentPos.Y - predicted.Y)
			if hErr > CONFIG.horizontalTolerance or vErr > CONFIG.verticalTolerance then
				hrp.CFrame = lastCFrame
			else
				lastPos = currentPos
				lastCFrame = hrp.CFrame
			end
		end)
	end)
	task.spawn(function()
		local savedBg, savedBgTrans = loadSelection()
		if savedBgTrans then
			CONFIG.bgTrans = math.clamp(savedBgTrans, 0, 0.9)
		end
		if savedBg then
			for i = 1, 10 do
				pcall(function() applyBackground(savedBg) end)
				if BACKGROUND.imageLabel and BACKGROUND.imageLabel.Image ~= "" then
					break
				end
				task.wait(1)
			end
		end
	end)
	task.delay(1.4, function()
		pcall(function()
			showPage("about")
			openMenu()
		end)
	end)
end
local ok, err = xpcall(build, function(m) return debug.traceback(m, 1) end)
if not ok then
	warn("[TvT_Hub] 出错:", err)
	pcall(function()
		local eg = Instance.new("ScreenGui")
		eg.Name = "TvT_Err"
		eg.ResetOnSpawn = false
		local ok2 = pcall(function() eg.Parent = gethui() end)
		if not ok2 or not eg.Parent then eg.Parent = playerGui end
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -60, 0, 90)
		l.Position = UDim2.new(0, 30, 0, 200)
		l.BackgroundColor3 = Color3.fromRGB(120, 25, 25)
		l.BackgroundTransparency = 0.25
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextWrapped = true
		l.TextSize = 12
		l.Text = "TvT 启动失败（截图发给作者）：\n" .. tostring(err)
		l.Parent = eg
	end)
end
