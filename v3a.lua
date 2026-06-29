-- ╔══════════════════════════════════════════╗
-- ║    NASI RENDANG EVOMON v3 — iOS UI       ║
-- ║    Logic: WORKS build (29/06/26)         ║
-- ║    MODIFIED: Fixed Drag & Minimize        ║
-- ║    FIXED: Accurate Pet Detection         ║
-- ║    OPTIMIZED: Smart Caching for Mobile   ║
-- ║    UI: Mobile Responsive (Small)         ║
-- ╚══════════════════════════════════════════╝

local Svc = {
	Players  = game:GetService("Players"),
	Run      = game:GetService("RunService"),
	UIS      = game:GetService("UserInputService"),
	VIM      = game:GetService("VirtualInputManager"),
	Http     = game:GetService("HttpService"),
	Teleport = game:GetService("TeleportService"),
}

local RS = game:GetService("ReplicatedStorage")
local plr  = Svc.Players.LocalPlayer
local PGui = plr:WaitForChild("PlayerGui")
if PGui:FindFirstChild("NREvomon") then PGui.NREvomon:Destroy() end

-- ─── BATTLE SERVICES (untuk speedup) ──────────
local _BattleService, _ReqAutoBattle, _BattleChoreoQueueModule
pcall(function()
	_BattleService = require(RS:WaitForChild("Script"):WaitForChild("Battle"):WaitForChild("BattleService"))
end)
pcall(function()
	_ReqAutoBattle = RS:WaitForChild("Remote"):WaitForChild("Battle"):WaitForChild("ReqAutoBattle")
end)
pcall(function()
	_BattleChoreoQueueModule = require(RS:WaitForChild("Script"):WaitForChild("BattleChoreo"):WaitForChild("BattleChoreoQueueModule"))
end)

-- ─── STATE ───────────────────────────────────
local S = {
	AutoCatch       = false,
	AutoLeave       = false,
	BattleSpeedup   = true, -- Battle Speed ON by default
	PlayerESP       = false,
	ChestFarm       = false,
	NoBall          = false,
	AutoKingBall    = false,
	AutoAdvBall     = false,
	AutoPrismBall   = false,
	ShowPityOverlay = false,
	CatchShinyOnly  = false,
	CatchShinyPris  = false,
	Running         = true,
	Closed          = false,
	ChestDelay      = 4,
	ScanRadius      = 500,
	LoopDelay       = 2,
	DebugMode       = true,
	LastDebug       = 0,
	DebugInterval   = 0.5,
	ChestIdx        = 0,
	ESPCache        = {},
	LastPetName     = nil,
}

local DS = { on=false, start=nil, pos=nil, input=nil }
local BS = { on=false, start=nil, pos=nil, input=nil, moved=false }

-- ─── PET NAMES ───────────────────────────────
local PetNames = {
	["Pet0_18"]="Pebble",    ["Pet0_19"]="Pebroll",   ["Pet0_34"]="Budling",
	["Pet0_16"]="Mopebun",   ["Pet0_31"]="Clampip",   ["Pet0_21"]="Sparkit",
	["Pet0_52"]="Lavite",    ["Pet0_80"]="Datubud",   ["Pet0_85"]="Mudbud",
	["Pet0_54"]="Stardrift", ["Pet0_46"]="Glaclide",  ["Pet0_47"]="Glacone",
	["Pet0_10"]="Chirppy",   ["Pet0_11"]="Chirplume", ["Pet0_74"]="Tinkog",
	["Pet0_13"]="Humdig",    ["Pet0_14"]="Flutterby", ["Pet0_24"]="Gulpfish",
	["Pet0_25"]="Mirefish",  ["Pet0_61"]="Frostseer", ["Pet0_64"]="Gempress",
	["Pet0_49"]="Chitmite",  ["Pet0_50"]="Chitgladi", ["Pet0_37"]="Vipip",
	["Pet0_38"]="Vipour",    ["Pet0_66"]="Tarro",     ["Pet0_67"]="Tarragon",
	["Pet0_72"]="Starloop",  ["Pet0_73"]="Starmuse",  ["Pet0_82"]="Wispuff",
	["Pet0_83"]="Wispshade", ["Pet0_44"]="Fluffet",   ["Pet0_58"]="Spikub",
	["Pet0_59"]="Spikumane",
}
local function petName(n) return PetNames[n] or n end

-- ─── BOSS FARM STATE ─────────────────────────
local S_BossLoop = false

-- ─── BOSS LIST ───────────────────────────────
local BOSS_LIST = {
	{ configId = 10001, battlePoolId = 9000001, name = "1. Pebgolem"     },
	{ configId = 10002, battlePoolId = 9000002, name = "2. Clamspire"    },
	{ configId = 10004, battlePoolId = 9000003, name = "3. Empixy"       },
	{ configId = 10005, battlePoolId = 9000004, name = "4. Datunymph"    },
	{ configId = 10008, battlePoolId = 9000005, name = "5. Glacitadel"   },
	{ configId = 10009, battlePoolId = 9000006, name = "6. Volcrest"     },
	{ configId = 10011, battlePoolId = 9000007, name = "7. Tinkore"      },
	{ configId = 10012, battlePoolId = 9000008, name = "8. Frostseer"    },
	{ configId = 10014, battlePoolId = 9000009, name = "9. Chitaladin"   },
	{ configId = 10016, battlePoolId = 9000010, name = "10. Viparch"     },
	{ configId = 10017, battlePoolId = 9000011, name = "11. Starmuse"    },
	{ configId = 10019, battlePoolId = 9000012, name = "12. Spikumane"   },
	{ configId = 10020, battlePoolId = 9000014, name = "13. Sundercrene" },
	{ configId = 10021, battlePoolId = 9000013, name = "14. Arcapex"     },
}

-- ─── COLORS (iOS Dark) ────────────────────────
local C = {
	BG    = Color3.fromRGB(18,18,22),
	SHEET = Color3.fromRGB(28,28,34),
	CELL  = Color3.fromRGB(38,38,46),
	ACC   = Color3.fromRGB(100,60,220),
	ACC2  = Color3.fromRGB(130,90,255),
	TEXT  = Color3.fromRGB(240,240,250),
	SUB   = Color3.fromRGB(150,150,170),
	DIM   = Color3.fromRGB(80,80,100),
	OFF   = Color3.fromRGB(50,50,65),
	GREEN = Color3.fromRGB(48,210,100),
	BLUE  = Color3.fromRGB(0,150,255),
	YELL  = Color3.fromRGB(255,210,50),
	ORG   = Color3.fromRGB(255,140,0),
	SEP   = Color3.fromRGB(50,50,62),
	MID    = Color3.fromRGB(150,150,170),
	YELLOW = Color3.fromRGB(255,210,50),
	ORANGE = Color3.fromRGB(255,140,0),
	DIM2   = Color3.fromRGB(50,50,65),
}

-- ─── UI PRIMITIVES ───────────────────────────
local function I(cls, props)
	local o = Instance.new(cls)
	for k,v in pairs(props or {}) do o[k]=v end
	return o
end
local function corner(p,r) local c=I("UICorner",{CornerRadius=UDim.new(0,r or 10)}) c.Parent=p return c end
local function sep(p,y)
	local f=I("Frame",{Position=UDim2.new(0,16,0,y or 0),Size=UDim2.new(1,-16,0,1),BackgroundColor3=C.SEP,BorderSizePixel=0,Parent=p})
	return f
end
local function lbl(p,txt,sz,col,bold,xa)
	return I("TextLabel",{
		BackgroundTransparency=1,Text=txt,TextSize=sz or 12,
		TextColor3=col or C.TEXT,
		Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
		TextXAlignment=xa or Enum.TextXAlignment.Left,
		Parent=p,
	})
end

-- ─── TOGGLE ──────────────────────────────────
local function mkToggle(parent)
	local track=I("Frame",{Size=UDim2.fromOffset(44,24),BackgroundColor3=C.OFF,BorderSizePixel=0,Parent=parent})
	corner(track,12)
	local knob=I("Frame",{Size=UDim2.fromOffset(20,20),Position=UDim2.fromOffset(2,2),BackgroundColor3=Color3.fromRGB(200,200,215),BorderSizePixel=0,Parent=track})
	corner(knob,10)
	local hit=I("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=track})
	local en=false
	local function ref()
		if en then track.BackgroundColor3=C.ACC knob.Position=UDim2.fromOffset(22,2) knob.BackgroundColor3=Color3.new(1,1,1)
		else track.BackgroundColor3=C.OFF knob.Position=UDim2.fromOffset(2,2) knob.BackgroundColor3=Color3.fromRGB(200,200,215) end
	end
	return track, hit, function() return en end, function(v) en=v ref() end
end

-- ─── iOS CELL BUILDERS ───────────────────────
local function toggleRow(parent, title, sub)
	local h = sub and 54 or 44
	local cell=I("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h),Parent=parent})
	local l=lbl(cell,title,12,C.TEXT,false)
	if sub then
		l.Position=UDim2.fromOffset(12,8)
		l.Size=UDim2.new(1,-70,0,16)
		l.TextYAlignment=Enum.TextYAlignment.Center
		local s=lbl(cell,sub,9,C.SUB) s.Position=UDim2.fromOffset(12,24) s.Size=UDim2.new(1,-70,0,14)
		s.TextYAlignment=Enum.TextYAlignment.Top
	else
		l.Position=UDim2.fromOffset(12,0)
		l.Size=UDim2.new(1,-70,1,0)
		l.TextYAlignment=Enum.TextYAlignment.Center
	end
	local tr,hit,get,set=mkToggle(cell)
	tr.AnchorPoint=Vector2.new(1,0.5) tr.Position=UDim2.new(1,-12,0.5,0)
	return cell,hit,get,set
end

local function iosSection(page, header, defs)
	if header and header~="" then
		local hf=I("Frame",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,Parent=page})
		local hl=lbl(hf,header:upper(),8,C.SUB,true)
		hl.Size=UDim2.new(1,0,0,18) hl.Position=UDim2.fromOffset(4,12)
		hl.TextYAlignment=Enum.TextYAlignment.Bottom
	end

	local grp=I("Frame",{BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=page})
	corner(grp,10)
	I("UIStroke",{Color=C.SEP,Thickness=0.5,Parent=grp})

	local results={}
	local totalH=0

	for i,def in ipairs(defs) do
		local cell,r1,r2,r3
		local y=totalH

		if i>1 then
			sep(grp, y)
			y=y+1
			totalH=totalH+1
		end

		if def.type=="toggle" then
			cell,r1,r2,r3=toggleRow(grp,def.title,def.sub)
		elseif def.type=="info" then
			local h=def.h or 40
			cell=I("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h),Parent=grp})
			r1=lbl(cell,def.txt or "",10,C.SUB)
			r1.Position=UDim2.fromOffset(12,0) r1.Size=UDim2.new(1,-24,1,0)
			r1.TextWrapped=true r1.TextYAlignment=Enum.TextYAlignment.Center
		elseif def.type=="btn" then
			local h=def.h or 44
			cell=I("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h),Parent=grp})
			r1=I("TextButton",{
				Position=UDim2.fromOffset(12,6),Size=UDim2.new(1,-24,0,h-12),
				BackgroundColor3=def.col or C.ACC,BorderSizePixel=0,
				AutoButtonColor=false,Font=Enum.Font.GothamSemibold,
				Text=def.title or "",TextSize=12,
				TextColor3=def.txtcol or Color3.new(1,1,1),
				Parent=cell
			}) corner(r1,8)
		end

		cell.Position=UDim2.fromOffset(0,y)
		if cell.Parent~=grp then cell.Parent=grp end
		totalH=totalH+(cell.Size.Y.Offset)
		table.insert(results,{cell=cell,a=r1,b=r2,c=r3})
	end

	grp.Size=UDim2.new(1,0,0,totalH)
	I("Frame",{Size=UDim2.new(1,0,0,10),BackgroundTransparency=1,Parent=page})
	return results
end

-- ─── BATTLE SPEED LOGIC ──────────────────────
local function applyBattleSpeedup()
	if not S.BattleSpeedup then return end
	pcall(function()
		local choreo = RS:WaitForChild("Script"):WaitForChild("BattleChoreo"):WaitForChild("Basic"):WaitForChild("BattleChoreoConst")
		choreo = require(choreo)
		if choreo then
			choreo.DefaultActionWaitTime = 0.01
			choreo.ActionWaitTimeByType = { [1] = 0.01, [3] = 0.01 }
			choreo.SettleNodeWaitTime = 0.01
			if rawget(choreo, "SettleNodeWaitTimeByType") ~= nil then choreo.SettleNodeWaitTimeByType = {} end
			choreo.StartBattleBeforeChoreographyDelayTime = 0.01
			choreo.FirstRoundEmptyActionResultsAnimationCompleteDelay = 0.01
			choreo.ForceSwitchAnimationCompleteDelay = 0.01
			choreo.OpeningThrowBallPreDelay = 0.01
			choreo.OpeningThrowBallPostDelay = 0.01
		end
	end)

	pcall(function()
		local ControllerManager = require(RS:WaitForChild("Core"):WaitForChild("Controller"):WaitForChild("ControllerManager"))
		local catchCtrl = ControllerManager.getController("BattleCatchPetWindowController")
		if catchCtrl and not catchCtrl._NR_catchHooked then
			catchCtrl._NR_catchHooked = true
			local origStartCatchAnim = catchCtrl.startCatchAnim
			catchCtrl.startCatchAnim = function(self, u191, p192)
				local battleData, callback
				if self == catchCtrl then battleData = u191 callback = p192
				else battleData = self callback = u191 end
				local success = false
				if typeof(battleData) == "table" and typeof(battleData.actionResults) == "table" then
					for i = #battleData.actionResults, 1, -1 do
						local r = battleData.actionResults[i]
						if typeof(r) == "table" and typeof(r.catchInfo) == "table" then
							success = typeof(r.catchInfo.failIndex) ~= "number"
							break
						end
					end
				end
				if success then
					pcall(function() catchCtrl:finishCatchPetResultUi(battleData) end)
					if typeof(callback) == "function" then callback() end
				else
					task.spawn(function()
						task.wait(0.5)
						if typeof(origStartCatchAnim) == "function" then origStartCatchAnim(self, u191, p192)
						else if typeof(callback) == "function" then callback() end end
					end)
				end
			end
		end
	end)
end

-- ─── SMART BATTLE CACHE ──────────────────────
local _cachedPrefs = nil
local _cachedSpeedControllers = {}

local function findBattleObjects()
	if _cachedPrefs and #_cachedSpeedControllers > 0 then return end
	pcall(function()
		for _, v in pairs(getgc(true)) do
			if typeof(v) == "table" then
				if not _cachedPrefs and rawget(v, "sessionPrefs") then _cachedPrefs = v.sessionPrefs end
				if rawget(v, "battleSpeedEnabled") ~= nil or rawget(v, "_speedEnabled") ~= nil then table.insert(_cachedSpeedControllers, v) end
			end
			if _cachedPrefs and #_cachedSpeedControllers > 5 then break end
		end
	end)
end

local function syncAutoSpeed()
	findBattleObjects()
	pcall(function()
		if _cachedPrefs then
			if S.BattleSpeedup then _cachedPrefs.preferBattleSpeed = true end
			_cachedPrefs.preferAutoBattle = true
		end
		for _, v in ipairs(_cachedSpeedControllers) do
			if rawget(v, "battleSpeedEnabled") ~= nil then
				if S.BattleSpeedup then v.battleSpeedEnabled = true end
				v.autoBattleEnabled = true
			end
			if rawget(v, "_speedEnabled") ~= nil then
				if S.BattleSpeedup and not v._speedEnabled then pcall(function() v._speedEnabled = true v:setSpeedButton(true) end) end
				if not v._autoEnabled then pcall(function() v._autoEnabled = true v:setAutoButton(true) end) end
			end
		end
		local inBattle = _BattleService and _BattleService.getCurrentBattle and _BattleService.getCurrentBattle() ~= nil
		if inBattle then
			pcall(function() _BattleService.autoBattle(true) end)
			pcall(function() if _ReqAutoBattle then _ReqAutoBattle:InvokeServer(true) end end)
		end
	end)
end

-- ─── GAME HELPERS ────────────────────────────
local function pressKey(k,dur)
	pcall(function() Svc.VIM:SendKeyEvent(true,k,false,game) task.wait(dur or 0.05) Svc.VIM:SendKeyEvent(false,k,false,game) end)
end

local function chestDir()
	local rc=workspace:FindFirstChild("RuntimeCache") if not rc then return nil end
	local rcc=rc:FindFirstChild("RuntimeCacheClient") if not rcc then return nil end
	return rcc:FindFirstChild("Chest")
end

local function teleportChest()
	local char=plr.Character local root=char and char:FindFirstChild("HumanoidRootPart") if not root then return end
	local dir=chestDir() if not dir then return end
	local list={} for _,c in ipairs(dir:GetChildren()) do if c:IsA("Folder") or c:IsA("Model") then table.insert(list,c) end end
	if #list==0 then return end
	S.ChestIdx=S.ChestIdx+1 if S.ChestIdx>#list then S.ChestIdx=1 end
	local bp=list[S.ChestIdx]:FindFirstChildWhichIsA("BasePart",true)
	if bp then root.CFrame=bp.CFrame*CFrame.new(0,3,0) end
end

local function ServerHop()
	local ok,result=pcall(function()
		local servers=Svc.Http:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"))
		local possible={}
		for _,s in ipairs(servers.data) do if s.playing<s.maxPlayers and s.id~=game.JobId then table.insert(possible,s.id) end end
		if #possible>0 then Svc.Teleport:TeleportToPlaceInstance(game.PlaceId, possible[math.random(1,#possible)], plr)
		else warn("[ServerHop] Tidak ada server lain.") end
	end)
	if not ok then warn("[ServerHop] Error:",result) end
end

-- ─── SOUND ───────────────────────────────────
local function playShinySound()
	task.spawn(function() pcall(function()
		local ss=game:GetService("SoundService")
		local s=Instance.new("Sound") s.SoundId="rbxassetid://4612359460" s.Volume=1 s.RollOffMaxDistance=10000 s.Parent=ss
		s.Loaded:Wait() s:Play() task.wait(s.TimeLength+0.5) s:Destroy()
	end) end)
end
local function playPrismaticSound()
	task.spawn(function() pcall(function()
		local ss=game:GetService("SoundService")
		local s=Instance.new("Sound") s.SoundId="rbxassetid://4612359460" s.Volume=1 s.RollOffMaxDistance=10000 s.Parent=ss
		s.Loaded:Wait() s:Play() task.wait(s.TimeLength+0.2) s:Play() task.wait(s.TimeLength+0.5) s:Destroy()
	end) end)
end

-- ─── PITY / SHINY DETECTION ──────────────────
local function getPityInfo()
	local sp=PGui:FindFirstChild("SparklePityText",true)
	if sp then local c,m=sp.Text:match("(%d+)/(%d+)") if c then return tonumber(c),tonumber(m) end end
	return nil,nil
end

local function isShiny()
	local sp=PGui:FindFirstChild("ShinyPityText",true)
	if sp and sp.Text=="--" then return true end
	local bg=PGui:FindFirstChild("BattleGui",true)
	if bg then for _,o in ipairs(bg:GetDescendants()) do
		if (o:IsA("TextLabel") or o:IsA("TextButton")) and o.Text:find("Shiny Evomon") then return true end
	end end
	return false
end

local _cc,_ct=false,0
local function catchVisible()
	if os.clock()-_ct<0.3 then return _cc end _ct=os.clock()
	_cc=(PGui:FindFirstChild("Catch",true)~=nil or PGui:FindFirstChild("CatchButton",true)~=nil
		or PGui:FindFirstChild("Catch(2/2)",true)~=nil or PGui:FindFirstChild("BattleGui",true)~=nil)
	return _cc
end

-- ─── ACCURATE PET DETECTION ──────────────────
local function findPet()
	local char=plr.Character local hrp=char and char:FindFirstChild("HumanoidRootPart") if not hrp then return nil,nil,nil end
	local bM,bP,bD=nil,nil,S.ScanRadius
	
	-- SCAN RUNTIME CACHE (Primary)
	local rc=workspace:FindFirstChild("RuntimeCache")
	if rc then
		for _, child in ipairs(rc:GetDescendants()) do
			if child:IsA("Model") and child.Name:match("^Pet0_%d+$") then
				local root=child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
				if root then
					local d=(root.Position-hrp.Position).Magnitude
					if d<bD then bD=d bM=child bP=root end
				end
			end
		end
	end
	
	-- SCAN WORKSPACE (Fallback)
	if not bM then
		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Model") and child.Name:match("^Pet0_%d+$") then
				if child==char or Svc.Players:GetPlayerFromCharacter(child) then continue end
				local root=child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
				if root then
					local d=(root.Position-hrp.Position).Magnitude
					if d<bD then bD=d bM=child bP=root end
				end
			end
		end
	end
	
	return bM,bP,bD
end

-- ─── PASSWORD ────────────────────────────────
local PASS,CACHE="1306","nr_evomon_cache.txt"
local unlocked=false
local function cacheOk() local ok,d=pcall(readfile,CACHE) return ok and d~="" and (os.time()-tonumber(d or 0))<18000 end
local function saveCache() pcall(writefile,CACHE,tostring(os.time())) end

local function mkPassGate()
	local pg=I("ScreenGui",{Name="NRPass",ResetOnSpawn=false,IgnoreGuiInset=true,Parent=PGui})
	I("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(5,5,10),BackgroundTransparency=0.3,BorderSizePixel=0,Parent=pg})
	local card=I("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(260,200),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=pg})
	corner(card,16) I("UIStroke",{Color=C.SEP,Thickness=1,Parent=card})
	local bar=I("Frame",{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,8),Size=UDim2.fromOffset(30,3),BackgroundColor3=C.DIM,BorderSizePixel=0,Parent=card}) corner(bar,1.5)
	local t1=lbl(card,"🔒 Password",14,C.TEXT,true,Enum.TextXAlignment.Center)
	t1.Size=UDim2.new(1,0,0,24) t1.Position=UDim2.fromOffset(0,24) t1.TextXAlignment=Enum.TextXAlignment.Center
	local sub=lbl(card,"Join Discord for password",10,C.SUB,false,Enum.TextXAlignment.Center)
	sub.Size=UDim2.new(1,0,0,16) sub.Position=UDim2.fromOffset(0,48) sub.TextXAlignment=Enum.TextXAlignment.Center
	local inB=I("Frame",{Position=UDim2.fromOffset(20,70),Size=UDim2.new(1,-40,0,36),BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=card}) corner(inB,10)
	local inp=I("TextBox",{Size=UDim2.new(1,-20,1,0),Position=UDim2.fromOffset(10,0),BackgroundTransparency=1,PlaceholderText="Input password...",PlaceholderColor3=C.DIM,Text="",TextSize=12,Font=Enum.Font.GothamBold,TextColor3=C.TEXT,ClearTextOnFocus=false,Parent=inB})
	local stat=lbl(card,"",9,Color3.fromRGB(200,60,60),false,Enum.TextXAlignment.Center)
	stat.Position=UDim2.fromOffset(20,110) stat.Size=UDim2.new(1,-40,0,12) stat.TextXAlignment=Enum.TextXAlignment.Center
	local ub=I("TextButton",{Position=UDim2.fromOffset(20,130),Size=UDim2.new(1,-40,0,36),BackgroundColor3=C.ACC,BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.GothamBold,Text="UNLOCK",TextSize=12,TextColor3=Color3.new(1,1,1),Parent=card}) corner(ub,10)
	local function try()
		if inp.Text==PASS then stat.Text="✅ Access Granted!" stat.TextColor3=C.GREEN saveCache() task.wait(0.5) pg:Destroy() unlocked=true
		else stat.Text="❌ Wrong password!" inp.Text="" end
	end
	ub.Activated:Connect(try) inp.FocusLost:Connect(function(e) if e then try() end end)
	return pg
end

if not cacheOk() then local pg=mkPassGate() repeat task.wait(0.1) until unlocked or not pg.Parent if not unlocked then return end else unlocked=true end

-- ─── CATCH LOGIC ─────────────────────────────
local function handleCatch()
	if (S.CatchShinyOnly or S.CatchShinyPris) and isShiny() then playShinySound() return end
	if S.CatchShinyPris then
		local cur,max=getPityInfo()
		if cur and max and cur>=(max-1) then pressKey(Enum.KeyCode.C,0.1) return end
	end
	if S.AutoLeave then pressKey(Enum.KeyCode.C,0.1)
	elseif not S.NoBall then
		if S.AutoKingBall and isShiny() then pressKey(Enum.KeyCode.Three,0.1) task.wait(0.1) end
		if S.AutoAdvBall and isShiny() then pressKey(Enum.KeyCode.Two,0.1) task.wait(0.1) end
		if S.AutoPrismBall and isShiny() then pressKey(Enum.KeyCode.Four,0.1) task.wait(0.1) end
		pressKey(Enum.KeyCode.E,0.05)
	end
end

local function onPrismaticReady()
	warn("💎 PRISMATIC READY! Auto Leave ON!")
	S.AutoLeave=true lSet(true) updateStatus()
	playPrismaticSound()
end

-- ═══════════════════════════════════════════════
--  MAIN GUI  —  iOS Style (Responsive Mobile)
-- ═══════════════════════════════════════════════
local cam = workspace.CurrentCamera
local gui=I("ScreenGui",{Name="NREvomon",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=PGui})

local win=I("Frame",{
	Name="Win",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
	Size=UDim2.new(0.75, 0, 0.42, 0),
	BackgroundColor3=C.BG,BorderSizePixel=0,Active=true,Parent=gui
})
I("UISizeConstraint", {MaxSize=Vector2.new(420, 240), MinSize=Vector2.new(340, 200), Parent=win})
I("UIAspectRatioConstraint", {AspectRatio=1.75, AspectType=Enum.AspectType.ScaleWithParentSize, Parent=win})
corner(win,14)
I("UIStroke",{Color=C.SEP,Thickness=1,Parent=win})

-- ─── SIDE BAR (TABS) ─────────────────────────
local sideBar=I("Frame",{Size=UDim2.new(0,50,1,0),BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=win})
corner(sideBar,14)
I("Frame",{Position=UDim2.new(0.5,0,0,0),Size=UDim2.new(0.5,0,1,0),BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=sideBar})
I("Frame",{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=C.SEP,BorderSizePixel=0,Parent=sideBar})

local TABS={
	{id="main", ico="rbxassetid://10723343321", lbl="General",    col=Color3.fromRGB(0, 122, 255)},
	{id="shiny",ico="rbxassetid://10709819149", lbl="Shiny/Prism",   col=Color3.fromRGB(255, 204, 0)},
	{id="boss", ico="rbxassetid://10747373176", lbl="Boss Farm",    col=Color3.fromRGB(255, 59, 48)},
	{id="extra",ico="rbxassetid://10747383819", lbl="Others", col=Color3.fromRGB(88, 86, 214)},
	{id="about", ico="rbxassetid://10723415535", lbl="About", col=Color3.fromRGB(90, 200, 250)},
}
local tabBtns={} local curPage="main"
local tabList=I("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=sideBar})
I("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,2),Parent=tabList})

for i,t in ipairs(TABS) do
	local btn=I("TextButton",{Size=UDim2.new(1,0,0,44),BackgroundTransparency=1,Text="",BorderSizePixel=0,AutoButtonColor=false,Parent=tabList})
	local circ=I("Frame",{
		Size=UDim2.fromOffset(28,28),Position=UDim2.new(0.5,0,0,2),AnchorPoint=Vector2.new(0.5,0),
		BackgroundColor3=t.col,BorderSizePixel=0,Parent=btn
	})
	corner(circ,14)
	local stroke=I("UIStroke",{Color=Color3.new(1,1,1),Thickness=2,Transparency=1,Parent=circ})
	local icoL=I("ImageLabel",{Size=UDim2.fromOffset(14,14),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),BackgroundTransparency=1,Image=t.ico,ImageColor3=Color3.new(1,1,1),Parent=circ})
	local txtL=lbl(btn,t.lbl,6,C.DIM,false,Enum.TextXAlignment.Center)
	txtL.Size=UDim2.new(1,0,0,10) txtL.Position=UDim2.new(0,0,0,32) txtL.TextXAlignment=Enum.TextXAlignment.Center
	tabBtns[t.id]={btn=btn,ico=icoL,lbl=txtL,circ=circ,stroke=stroke,defCol=t.col}
end

-- ─── TOP BAR ─────────────────────────────────
local mainArea=I("Frame",{Position=UDim2.new(0,50,0,0),Size=UDim2.new(1,-50,1,0),BackgroundTransparency=1,Parent=win})
local topBar=I("Frame",{Size=UDim2.new(1,0,0,34),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=mainArea})
corner(topBar, 14)
I("Frame",{Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0.5,0),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=topBar})
local titleLbl=lbl(topBar,"⚡ NR Evomon v3 (30/06/26 1:15)",10,C.TEXT,true)
titleLbl.Position=UDim2.fromOffset(10,0) titleLbl.Size=UDim2.new(1,-80,1,0)

local dotsCon=I("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-54,0.5,0),Size=UDim2.fromOffset(44,16),BackgroundTransparency=1,Parent=topBar})
I("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,2),Parent=dotsCon})
local dotRefs={}
for _,info in ipairs({{C.ACC,"C"},{C.BLUE,"L"},{Color3.fromRGB(100,50,200),"E"},{C.GREEN,"F"}}) do
	local d=I("Frame",{Size=UDim2.fromOffset(8,8),BackgroundColor3=Color3.fromRGB(50,50,65),BorderSizePixel=0,Parent=dotsCon}) corner(d,4)
	local t=lbl(d,info[2],4,C.BG,true,Enum.TextXAlignment.Center)
	t.Size=UDim2.fromScale(1,1) t.TextYAlignment=Enum.TextYAlignment.Center
	table.insert(dotRefs,{dot=d,col=info[1]})
end
local function updateStatus()
	local cfg={S.AutoCatch,S.AutoLeave,S.PlayerESP,S.ChestFarm}
	for i,v in ipairs(cfg) do dotRefs[i].dot.BackgroundColor3=v and dotRefs[i].col or Color3.fromRGB(50,50,65) end
end

local minBtn=I("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-28,0.5,0),Size=UDim2.fromOffset(20,20),BackgroundColor3=C.CELL,BorderSizePixel=0,Text="—",TextSize=10,TextColor3=C.SUB,Parent=topBar}) corner(minBtn,10)
local closeBtn=I("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-4,0.5,0),Size=UDim2.fromOffset(20,20),BackgroundColor3=Color3.fromRGB(60,20,20),BorderSizePixel=0,Text="✕",TextSize=9,TextColor3=Color3.fromRGB(255,80,80),Parent=topBar}) corner(closeBtn,10)

local stPill=I("Frame",{Position=UDim2.new(0,10,0,38),Size=UDim2.new(1,-20,0,20),BackgroundColor3=C.CELL,BorderSizePixel=0,Parent=mainArea}) corner(stPill,10)
local statusLbl=lbl(stPill,"● Idle",8,C.SUB,true,Enum.TextXAlignment.Center)
statusLbl.Size=UDim2.fromScale(1,1) statusLbl.TextYAlignment=Enum.TextYAlignment.Center

local function setStatus(txt,col) statusLbl.Text="● "..(txt or "Idle") statusLbl.TextColor3=col or C.SUB end

local catchIndLbl=lbl(mainArea,"—",7,C.DIM,false,Enum.TextXAlignment.Center)
catchIndLbl.AnchorPoint=Vector2.new(0.5,1) catchIndLbl.Position=UDim2.new(0.5,0,1,-1)
catchIndLbl.Size=UDim2.new(1,-24,0,8)

local pageCon=I("Frame",{Position=UDim2.fromOffset(0,62),Size=UDim2.new(1,0,1,-74),BackgroundTransparency=1,ClipsDescendants=true,Parent=mainArea})
local pages={}
local function mkPage(id)
	local sc=I("ScrollingFrame",{Name=id,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarThickness=1,ScrollBarImageColor3=C.ACC,CanvasSize=UDim2.new(0,0,0,0),Visible=false,Parent=pageCon})
	I("UIPadding",{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,10),Parent=sc})
	local layout=I("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,3),Parent=sc})
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sc.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+12) end)
	pages[id]=sc return sc
end

-- ─── PAGES (Original Features Preserved) ─────
local pgMain=mkPage("main")
local autoRows=iosSection(pgMain,"Automation",{
	{type="toggle",title="Auto Farm & Catch",sub="Find and catch pet automatically"},
	{type="toggle",title="Auto Leave",sub="Cancel catch/No catch pet"},
	{type="toggle",title="Battle Speedup",sub="Fast Battle skip animation"},
	{type="toggle",title="Manual Catch",sub="Manual Catch Ball"},
})
local cHit,cGet,cSet = autoRows[1].a,autoRows[1].b,autoRows[1].c
local lHit,lGet,lSet = autoRows[2].a,autoRows[2].b,autoRows[2].c
local bsHit,bsGet,bsSet = autoRows[3].a,autoRows[3].b,autoRows[3].c
local nbHit,nbGet,nbSet = autoRows[4].a,autoRows[4].b,autoRows[4].c
bsSet(true)

local stRows=iosSection(pgMain,"Status",{{type="info",txt="Idle",h=36}})
local statusLbl2=stRows[1].a statusLbl2.TextXAlignment=Enum.TextXAlignment.Center
local _setStatus=setStatus
setStatus=function(txt,col) _setStatus(txt,col) if statusLbl2 and statusLbl2.Parent then statusLbl2.Text=txt statusLbl2.TextColor3=col or C.SUB end end

local pgShiny=mkPage("shiny")
local shinyRows=iosSection(pgShiny,"Mode Shiny",{
	{type="toggle",title="📊 Show Pity Overlay",sub="Show current pity on screen"},
	{type="toggle",title="✨ Catch Shiny Only",sub="Auto Leave ON, only catch shiny"},
	{type="toggle",title="💎 Shiny & Prismatic",sub="Auto Leave will ON at pity 149/150"},
})
local ovHit,ovGet,ovSet = shinyRows[1].a,shinyRows[1].b,shinyRows[1].c
local soHit,soGet,soSet = shinyRows[2].a,shinyRows[2].b,shinyRows[2].c
local spHit,spGet,spSet = shinyRows[3].a,shinyRows[3].b,shinyRows[3].c

local ballRows=iosSection(pgShiny,"Switch Ball saat Shiny",{
	{type="toggle",title="👑 King Ball"},
	{type="toggle",title="⚡ Adv. Ball"},
	{type="toggle",title="🔮 Prism. Ball"},
})
local akHit,akGet,akSet = ballRows[1].a,ballRows[1].b,ballRows[1].c
local abHit,abGet,abSet = ballRows[2].a,ballRows[2].b,ballRows[2].c
local pbHit,pbGet,pbSet = ballRows[3].a,ballRows[3].b,ballRows[3].c

local pityRows=iosSection(pgShiny,"Pity Status",{{type="info",txt="💎 Prismatic: —/—\n✨ Shiny: —/—",h=48}})
local pityLbl=pityRows[1].a pityLbl.TextXAlignment=Enum.TextXAlignment.Center

local pgExtra=mkPage("extra")
local espRows=iosSection(pgExtra,"Player ESP",{{type="toggle",title="Highlight + Name + Dist."}})
local eHit,eGet,eSet = espRows[1].a,espRows[1].b,espRows[1].c
local chestRows=iosSection(pgExtra,"Chest Farm",{{type="toggle",title="Auto Farm Chest"}})
local chHit,chGet,chSet = chestRows[1].a,chestRows[1].b,chestRows[1].c
local chStRows=iosSection(pgExtra,"Status Chest",{{type="info",txt="Inactive",h=32}})
local chStLbl=chStRows[1].a chStLbl.TextXAlignment=Enum.TextXAlignment.Center
local manRows=iosSection(pgExtra,"",{{type="btn",title="📦 Next Chest (Manual)",col=C.CELL,txtcol=C.TEXT}})
local manBtn=manRows[1].a

local pgBoss=mkPage("boss")
iosSection(pgBoss,"Boss Farm",{{type="info",txt="Loop ON = Loop Boss Fight NO CD.",h=32}})

local pgAbout=mkPage("about")
iosSection(pgAbout,"Info Script",{{type="info",txt="⚡ NR Evomon v3\nScript made for you.",h=40}})
iosSection(pgAbout,"Version",{{type="info",txt="Build Version: V3 (WORKS)\nUpdate: 30 June 2026",h=40}})

-- ─── TAB SWITCHING ───────────────────────────
local function showPage(id)
	for pid,pg in pairs(pages) do pg.Visible=(pid==id) end
	for tid,obj in pairs(tabBtns) do
		local sel=(tid==id)
		obj.stroke.Transparency=sel and 0 or 1
		obj.circ.BackgroundColor3=sel and obj.defCol or obj.defCol:Lerp(Color3.new(0,0,0), 0.3)
		obj.lbl.TextColor3=sel and C.TEXT or C.DIM
		obj.ico.ImageTransparency=sel and 0 or 0.3
	end
	curPage=id
end
for id,obj in pairs(tabBtns) do obj.btn.Activated:Connect(function() showPage(id) end) end
showPage("main")

-- ─── BUBBLE & DRAG ───────────────────────────
local bubble=I("TextButton",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(36,36),BackgroundColor3=C.ACC,BorderSizePixel=0,Text="⚡",TextSize=14,TextColor3=Color3.new(1,1,1),Visible=false,ZIndex=10,Parent=gui})
corner(bubble,18)

topBar.InputBegan:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then DS.on=true DS.start=inp.Position DS.pos=win.Position end end)
Svc.UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton1 then DS.on=false BS.on=false end end)
minBtn.Activated:Connect(function() local ab=win.AbsolutePosition local sz=win.AbsoluteSize bubble.Position=UDim2.fromOffset(ab.X+sz.X/2,ab.Y+sz.Y/2) win.Visible=false bubble.Visible=true end)
bubble.Activated:Connect(function() if not BS.moved then win.Visible=true bubble.Visible=false end end)

Svc.UIS.InputChanged:Connect(function(inp)
	if DS.on and inp.UserInputType==Enum.UserInputType.MouseMovement then
		local d=inp.Position-DS.start win.Position=UDim2.new(DS.pos.X.Scale,DS.pos.X.Offset+d.X,DS.pos.Y.Scale,DS.pos.Y.Offset+d.Y)
	end
end)

-- ─── EVENT CONNECTIONS (Original Logic) ───────
cHit.Activated:Connect(function() S.AutoCatch=not S.AutoCatch cSet(S.AutoCatch) updateStatus() setStatus(S.AutoCatch and "Looking for pet..." or "Idle") end)
lHit.Activated:Connect(function() S.AutoLeave=not S.AutoLeave lSet(S.AutoLeave) updateStatus() end)
bsHit.Activated:Connect(function() S.BattleSpeedup=not S.BattleSpeedup bsSet(S.BattleSpeedup) if S.BattleSpeedup then applyBattleSpeedup() end end)
eHit.Activated:Connect(function() S.PlayerESP=not S.PlayerESP eSet(S.PlayerESP) updateStatus() end)
chHit.Activated:Connect(function() S.ChestFarm=not S.ChestFarm chSet(S.ChestFarm) updateStatus() end)
closeBtn.Activated:Connect(function() S.Running=false gui:Destroy() end)

-- ─── MAIN LOOPS (Optimized) ───────────────────
task.spawn(function()
	while task.wait(S.LoopDelay) do
		if not S.Running then break end
		if not S.AutoCatch then continue end
		if catchVisible() then handleCatch() continue end
		pcall(function()
			local m,p,d=findPet()
			if m and p then
				S.LastPetName=petName(m.Name)
				setStatus(string.format("→ %s (%.1f m)",S.LastPetName,d*0.28),C.BLUE)
				local char=plr.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
				if hum then hum:MoveTo(p.Position) end
			else setStatus("No pet nearby") end
		end)
	end
end)

task.spawn(function() -- Battle Sync
	while task.wait(2) do
		if not S.Running then break end
		local inBattle = _BattleService and _BattleService.getCurrentBattle and _BattleService.getCurrentBattle() ~= nil
		if inBattle then syncAutoSpeed() end
	end
end)

updateStatus()
setStatus("Idle")
print("⚡ NR Evomon v3 FULL Optimized loaded!")
