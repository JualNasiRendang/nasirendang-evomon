-- ╔══════════════════════════════════════════╗
-- ║    NASI RENDANG EVOMON v3 — iOS UI       ║
-- ║    Logic: WORKS build (29/06/26)         ║
-- ║    MODIFIED: Fixed Drag & Minimize        ║
-- ║    OPTIMIZED: Smart Caching for Mobile   ║
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
	local track=I("Frame",{Size=UDim2.fromOffset(50,28),BackgroundColor3=C.OFF,BorderSizePixel=0,Parent=parent})
	corner(track,14)
	local knob=I("Frame",{Size=UDim2.fromOffset(24,24),Position=UDim2.fromOffset(2,2),BackgroundColor3=Color3.fromRGB(200,200,215),BorderSizePixel=0,Parent=track})
	corner(knob,12)
	local hit=I("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=track})
	local en=false
	local function ref()
		if en then track.BackgroundColor3=C.ACC knob.Position=UDim2.fromOffset(24,2) knob.BackgroundColor3=Color3.new(1,1,1)
		else track.BackgroundColor3=C.OFF knob.Position=UDim2.fromOffset(2,2) knob.BackgroundColor3=Color3.fromRGB(200,200,215) end
	end
	return track, hit, function() return en end, function(v) en=v ref() end
end

-- ─── iOS CELL BUILDERS ───────────────────────
local function toggleRow(parent, title, sub)
	local h = sub and 62 or 50
	local cell=I("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h),Parent=parent})
	local l=lbl(cell,title,13,C.TEXT,false)
	if sub then
		l.Position=UDim2.fromOffset(14,12)
		l.Size=UDim2.new(1,-82,0,18)
		l.TextYAlignment=Enum.TextYAlignment.Center
		local s=lbl(cell,sub,10,C.SUB) s.Position=UDim2.fromOffset(14,32) s.Size=UDim2.new(1,-82,0,16)
		s.TextYAlignment=Enum.TextYAlignment.Top
	else
		l.Position=UDim2.fromOffset(14,0)
		l.Size=UDim2.new(1,-82,1,0)
		l.TextYAlignment=Enum.TextYAlignment.Center
	end
	local tr,hit,get,set=mkToggle(cell)
	tr.AnchorPoint=Vector2.new(1,0.5) tr.Position=UDim2.new(1,-14,0.5,0)
	return cell,hit,get,set
end

local function iosSection(page, header, defs)
	if header and header~="" then
		local hf=I("Frame",{Size=UDim2.new(1,0,0,38),BackgroundTransparency=1,Parent=page})
		local hl=lbl(hf,header:upper(),9,C.SUB,true)
		hl.Size=UDim2.new(1,0,0,20) hl.Position=UDim2.fromOffset(4,14)
		hl.TextYAlignment=Enum.TextYAlignment.Bottom
	end

	local grp=I("Frame",{BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=page})
	corner(grp,12)
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
			local h=def.h or 46
			cell=I("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h),Parent=grp})
			r1=lbl(cell,def.txt or "",11,C.SUB)
			r1.Position=UDim2.fromOffset(14,0) r1.Size=UDim2.new(1,-28,1,0)
			r1.TextWrapped=true r1.TextYAlignment=Enum.TextYAlignment.Center
		elseif def.type=="btn" then
			local h=def.h or 50
			cell=I("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h),Parent=grp})
			r1=I("TextButton",{
				Position=UDim2.fromOffset(14,8),Size=UDim2.new(1,-28,0,h-16),
				BackgroundColor3=def.col or C.ACC,BorderSizePixel=0,
				AutoButtonColor=false,Font=Enum.Font.GothamSemibold,
				Text=def.title or "",TextSize=13,
				TextColor3=def.txtcol or Color3.new(1,1,1),
				Parent=cell
			}) corner(r1,10)
		end

		cell.Position=UDim2.fromOffset(0,y)
		if cell.Parent~=grp then cell.Parent=grp end
		totalH=totalH+(cell.Size.Y.Offset)
		table.insert(results,{cell=cell,a=r1,b=r2,c=r3})
	end

	grp.Size=UDim2.new(1,0,0,totalH)
	I("Frame",{Size=UDim2.new(1,0,0,14),BackgroundTransparency=1,Parent=page})
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
				-- Cache Session Prefs
				if not _cachedPrefs and rawget(v, "sessionPrefs") then
					_cachedPrefs = v.sessionPrefs
				end
				-- Cache Speed Controllers
				if rawget(v, "battleSpeedEnabled") ~= nil or rawget(v, "_speedEnabled") ~= nil then
					table.insert(_cachedSpeedControllers, v)
				end
			end
			if _cachedPrefs and #_cachedSpeedControllers > 5 then break end -- Found enough
		end
	end)
end

local function syncAutoSpeed()
	findBattleObjects() -- Will only run GC scan if cache is empty
	
	pcall(function()
		-- Update Prefs
		if _cachedPrefs then
			if S.BattleSpeedup then _cachedPrefs.preferBattleSpeed = true end
			_cachedPrefs.preferAutoBattle = true
		end
		
		-- Update Controllers
		for _, v in ipairs(_cachedSpeedControllers) do
			if rawget(v, "battleSpeedEnabled") ~= nil then
				if S.BattleSpeedup then v.battleSpeedEnabled = true end
				v.autoBattleEnabled = true
			end
			if rawget(v, "_speedEnabled") ~= nil then
				if S.BattleSpeedup and not v._speedEnabled then
					pcall(function() v._speedEnabled = true v:setSpeedButton(true) end)
				end
				if not v._autoEnabled then
					pcall(function() v._autoEnabled = true v:setAutoButton(true) end)
				end
			end
		end
		
		-- Ensure Auto Battle is ON via Service
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

local function findPet()
	local char=plr.Character local hrp=char and char:FindFirstChild("HumanoidRootPart") if not hrp then return nil,nil,nil end
	local bM,bP,bD=nil,nil,S.ScanRadius
	local rc=workspace:FindFirstChild("RuntimeCache")
	local rcc=rc and rc:FindFirstChild("RuntimeCacheClient")
	local petCache=rcc and rcc:FindFirstChild("CreatureModelCache")
	
	local targetFolder = petCache or workspace
	for _,obj in pairs(targetFolder:GetChildren()) do
		if not obj.Name:match("^Pet0_%d+$") or not obj:IsA("Model") then continue end
		if obj==char or Svc.Players:GetPlayerFromCharacter(obj) then continue end
		if obj.Parent.Name=="PartnerPet" or obj:GetFullName():find("NPC") then continue end
		local root=obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
		local hum=obj:FindFirstChildOfClass("Humanoid")
		if root and hum and hum.Health>0 then
			local d=(root.Position-hrp.Position).Magnitude
			if d<bD then bD=d bM=obj bP=root end
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
	local card=I("Frame",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(300,220),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=pg})
	corner(card,20) I("UIStroke",{Color=C.SEP,Thickness=1,Parent=card})
	local bar=I("Frame",{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,10),Size=UDim2.fromOffset(40,4),BackgroundColor3=C.DIM,BorderSizePixel=0,Parent=card}) corner(bar,2)
	local t1=lbl(card,"🔒 Password",16,C.TEXT,true,Enum.TextXAlignment.Center)
	t1.Size=UDim2.new(1,0,0,28) t1.Position=UDim2.fromOffset(0,28) t1.TextXAlignment=Enum.TextXAlignment.Center
	local sub=lbl(card,"Join Discord for password",11,C.SUB,false,Enum.TextXAlignment.Center)
	sub.Size=UDim2.new(1,0,0,18) sub.Position=UDim2.fromOffset(0,56) sub.TextXAlignment=Enum.TextXAlignment.Center
	local inB=I("Frame",{Position=UDim2.fromOffset(20,85),Size=UDim2.new(1,-40,0,42),BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=card}) corner(inB,12)
	local inp=I("TextBox",{Size=UDim2.new(1,-20,1,0),Position=UDim2.fromOffset(10,0),BackgroundTransparency=1,PlaceholderText="Input password...",PlaceholderColor3=C.DIM,Text="",TextSize=14,Font=Enum.Font.GothamBold,TextColor3=C.TEXT,ClearTextOnFocus=false,Parent=inB})
	local stat=lbl(card,"",10,Color3.fromRGB(200,60,60),false,Enum.TextXAlignment.Center)
	stat.Position=UDim2.fromOffset(20,130) stat.Size=UDim2.new(1,-40,0,14) stat.TextXAlignment=Enum.TextXAlignment.Center
	local ub=I("TextButton",{Position=UDim2.fromOffset(20,150),Size=UDim2.new(1,-40,0,44),BackgroundColor3=C.ACC,BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.GothamBold,Text="UNLOCK",TextSize=14,TextColor3=Color3.new(1,1,1),Parent=card}) corner(ub,12)
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
--  MAIN GUI  —  iOS Style
-- ═══════════════════════════════════════════════
local cam = workspace.CurrentCamera
local vp = cam.ViewportSize
local gui=I("ScreenGui",{Name="NREvomon",ResetOnSpawn=false,IgnoreGuiInset=true,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,Parent=PGui})

local win=I("Frame",{
	Name="Win",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
	Size=UDim2.new(0.8, 0, 0.45, 0),
	BackgroundColor3=C.BG,BorderSizePixel=0,Active=true,Parent=gui
})
I("UISizeConstraint", {MaxSize=Vector2.new(480, 280), MinSize=Vector2.new(380, 240), Parent=win})
I("UIAspectRatioConstraint", {AspectRatio=1.7, AspectType=Enum.AspectType.ScaleWithParentSize, Parent=win})
corner(win,16)
I("UIStroke",{Color=C.SEP,Thickness=1,Parent=win})

-- ─── SIDE BAR (TABS) ─────────────────────────
local sideBar=I("Frame",{Size=UDim2.new(0,56,1,0),BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=win})
corner(sideBar,16)
I("Frame",{Position=UDim2.new(0.5,0,0,0),Size=UDim2.new(0.5,0,1,0),BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=sideBar})
I("Frame",{Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=C.SEP,BorderSizePixel=0,Parent=sideBar})

local TABS={
	{id="main", ico="rbxassetid://10723343321", lbl="General",    col=Color3.fromRGB(0, 122, 255)}, -- Blue
	{id="shiny",ico="rbxassetid://10709819149", lbl="Shiny/Prism",   col=Color3.fromRGB(255, 204, 0)}, -- Yellow
	{id="boss", ico="rbxassetid://10747373176", lbl="Boss Farm",    col=Color3.fromRGB(255, 59, 48)}, -- Red
	{id="extra",ico="rbxassetid://10747383819", lbl="Others", col=Color3.fromRGB(88, 86, 214)}, -- Indigo
	{id="about", ico="rbxassetid://10723415535", lbl="About", col=Color3.fromRGB(90, 200, 250)}, -- Light Blue
}
local tabBtns={} local curPage="main"
local tabList=I("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=sideBar})
I("UIListLayout",{FillDirection=Enum.FillDirection.Vertical,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,2),Parent=tabList})

for i,t in ipairs(TABS) do
	local btn=I("TextButton",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,Text="",BorderSizePixel=0,AutoButtonColor=false,Parent=tabList})
	local circ=I("Frame",{
		Size=UDim2.fromOffset(30,30),Position=UDim2.new(0.5,0,0,4),AnchorPoint=Vector2.new(0.5,0),
		BackgroundColor3=t.col,BorderSizePixel=0,Parent=btn
	})
	corner(circ,15)
	local stroke=I("UIStroke",{Color=Color3.new(1,1,1),Thickness=2,Transparency=1,Parent=circ})
	
	local icoL=I("ImageLabel",{
		Size=UDim2.fromOffset(16,16),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),
		BackgroundTransparency=1,Image=t.ico,ImageColor3=Color3.new(1,1,1),
		Parent=circ
	})
	local txtL=lbl(btn,t.lbl,7,C.DIM,false,Enum.TextXAlignment.Center)
	txtL.Size=UDim2.new(1,0,0,10) txtL.Position=UDim2.new(0,0,0,36) txtL.TextXAlignment=Enum.TextXAlignment.Center
	tabBtns[t.id]={btn=btn,ico=icoL,lbl=txtL,circ=circ,stroke=stroke,defCol=t.col}
end

-- ─── TOP BAR (RIGHT SIDE) ─────────────────────
local mainArea=I("Frame",{Position=UDim2.new(0,56,0,0),Size=UDim2.new(1,-56,1,0),BackgroundTransparency=1,Parent=win})
local topBar=I("Frame",{Size=UDim2.new(1,0,0,38),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=mainArea})
corner(topBar, 16)
I("Frame",{Position=UDim2.new(0,0,0.5,0),Size=UDim2.new(1,0,0.5,0),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=topBar})
I("Frame",{Position=UDim2.new(0,0,0,0),Size=UDim2.new(0,16,1,0),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=topBar})
local titleLbl=lbl(topBar,"⚡ NR Evomon v3 (30/06/2026 01:00)",12,C.TEXT,true,Enum.TextXAlignment.Left)
titleLbl.Position=UDim2.fromOffset(12,0) titleLbl.Size=UDim2.new(1,-100,1,0)

local dotsCon=I("Frame",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-64,0.5,0),Size=UDim2.fromOffset(50,18),BackgroundTransparency=1,Parent=topBar})
I("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,3),Parent=dotsCon})
local dotRefs={}
for _,info in ipairs({{C.ACC,"C"},{C.BLUE,"L"},{Color3.fromRGB(100,50,200),"E"},{C.GREEN,"F"}}) do
	local d=I("Frame",{Size=UDim2.fromOffset(9,9),BackgroundColor3=Color3.fromRGB(50,50,65),BorderSizePixel=0,Parent=dotsCon}) corner(d,4.5)
	local t=lbl(d,info[2],5,C.BG,true,Enum.TextXAlignment.Center)
	t.Size=UDim2.fromScale(1,1) t.TextXAlignment=Enum.TextXAlignment.Center t.TextYAlignment=Enum.TextYAlignment.Center
	table.insert(dotRefs,{dot=d,col=info[1]})
end
local function updateStatus()
	local cfg={S.AutoCatch,S.AutoLeave,S.PlayerESP,S.ChestFarm}
	for i,v in ipairs(cfg) do dotRefs[i].dot.BackgroundColor3=v and dotRefs[i].col or Color3.fromRGB(50,50,65) end
end

local minBtn=I("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-32,0.5,0),Size=UDim2.fromOffset(22,22),BackgroundColor3=C.CELL,BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.GothamBold,Text="—",TextSize=11,TextColor3=C.SUB,Parent=topBar}) corner(minBtn,11)
local closeBtn=I("TextButton",{AnchorPoint=Vector2.new(1,0.5),Position=UDim2.new(1,-6,0.5,0),Size=UDim2.fromOffset(22,22),BackgroundColor3=Color3.fromRGB(60,20,20),BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.GothamBold,Text="✕",TextSize=10,TextColor3=Color3.fromRGB(255,80,80),Parent=topBar}) corner(closeBtn,11)
I("Frame",{Position=UDim2.new(0,0,1,0),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.SEP,BorderSizePixel=0,Parent=topBar})

local stPill=I("Frame",{Position=UDim2.new(0,10,0,42),Size=UDim2.new(1,-20,0,22),BackgroundColor3=C.CELL,BorderSizePixel=0,Parent=mainArea}) corner(stPill,11)
local statusLbl=lbl(stPill,"● Idle",9,C.SUB,true,Enum.TextXAlignment.Center)
statusLbl.Size=UDim2.fromScale(1,1) statusLbl.TextXAlignment=Enum.TextXAlignment.Center statusLbl.TextYAlignment=Enum.TextYAlignment.Center

local function setStatus(txt,col)
	statusLbl.Text="● "..(txt or "Idle")
	statusLbl.TextColor3=col or C.SUB
end

local catchIndLbl=lbl(mainArea,"—",8,C.DIM,false,Enum.TextXAlignment.Center)
catchIndLbl.AnchorPoint=Vector2.new(0.5,1) catchIndLbl.Position=UDim2.new(0.5,0,1,-2)
catchIndLbl.Size=UDim2.new(1,-24,0,10) catchIndLbl.TextXAlignment=Enum.TextXAlignment.Center

local pageCon=I("Frame",{Position=UDim2.fromOffset(0,68),Size=UDim2.new(1,0,1,-84),BackgroundTransparency=1,ClipsDescendants=true,Parent=mainArea})
local pages={}
local function mkPage(id)
	local sc=I("ScrollingFrame",{Name=id,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ScrollBarThickness=2,ScrollBarImageColor3=C.ACC,CanvasSize=UDim2.new(0,0,0,0),Visible=false,Parent=pageCon})
	I("UIPadding",{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,12),Parent=sc})
	local layout=I("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,4),Parent=sc})
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sc.CanvasSize=UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16) end)
	pages[id]=sc return sc
end

-- ═══════════════════════════════════════════════
--  PAGE: UMUM
-- ═══════════════════════════════════════════════
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

local stRows=iosSection(pgMain,"Status",{{type="info",txt="Idle",h=40}})
local statusLbl2=stRows[1].a
statusLbl2.TextXAlignment=Enum.TextXAlignment.Center

local _setStatus=setStatus
setStatus=function(txt,col)
	_setStatus(txt,col)
	if statusLbl2 and statusLbl2.Parent then statusLbl2.Text=txt statusLbl2.TextColor3=col or C.SUB end
end

-- ═══════════════════════════════════════════════
--  PAGE: SHINY
-- ═══════════════════════════════════════════════
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
local pbHit,pbSet = ballRows[3].a,ballRows[3].c

local pityRows=iosSection(pgShiny,"Pity Status",{{type="info",txt="💎 Prismatic: —/—\n✨ Shiny: —/—",h=54}})
local pityLbl=pityRows[1].a
pityLbl.TextXAlignment=Enum.TextXAlignment.Center pityLbl.TextYAlignment=Enum.TextYAlignment.Center

iosSection(pgShiny,"Info",{{type="info",txt="Shiny Only: Auto Leave ON.\nShiny & Prismatic: Catch stop at pity 149/150.",h=52}})

local function updatePityUI()
	local col=C.SUB
	local cur,max=getPityInfo()
	local prisText=(cur and max) and string.format("💎 Prismatic: %d/%d%s",cur,max,(cur>=(max-1)) and " ⚠️" or "") or "💎 Prismatic: —/—"
	if cur and max and cur>=(max-1) then col=C.ORG end
	local shinyPity=PGui:FindFirstChild("ShinyPityText",true) local shinyText="✨ Shiny: —/—"
	if shinyPity then
		local sc,sm=shinyPity.Text:match("(%d+)/(%d+)")
		if sc and sm then
			sc,sm=tonumber(sc),tonumber(sm)
			shinyText=string.format("✨ Shiny: %d/%d%s",sc,sm,(sc>=sm) and " ⚠️" or "")
			if sc>=sm and col~=C.ORG then col=C.YELL end
		end
	end
	pityLbl.Text=prisText.."\n"..shinyText pityLbl.TextColor3=col
end

-- ═══════════════════════════════════════════════
--  PAGE: LAINNYA
-- ═══════════════════════════════════════════════
local pgExtra=mkPage("extra")

local espRows=iosSection(pgExtra,"Player ESP",{
	{type="toggle",title="Highlight + Name + Dist.",sub="Show highlight body & player distance"},
})
local eHit,eGet,eSet = espRows[1].a,espRows[1].b,espRows[1].c

local chestRows=iosSection(pgExtra,"Chest Farm",{
	{type="toggle",title="Auto Farm Chest",sub="Auto Teleport to chest"},
})
local chHit,chGet,chSet = chestRows[1].a,chestRows[1].b,chestRows[1].c

local chStRows=iosSection(pgExtra,"Status Chest",{{type="info",txt="Inactive",h=36}})
local chStLbl=chStRows[1].a chStLbl.TextXAlignment=Enum.TextXAlignment.Center

local manRows=iosSection(pgExtra,"",{{type="btn",title="📦 Next Chest (Manual)",col=C.CELL,txtcol=C.TEXT}})
local manBtn=manRows[1].a

do
	local hf=I("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Parent=pgExtra})
	local hl=lbl(hf,"TELEPORT TO PLAYER",9,C.SUB,true) hl.Size=UDim2.fromScale(1,1) hl.Position=UDim2.fromOffset(4,0) hl.TextYAlignment=Enum.TextYAlignment.Bottom

	local grp=I("Frame",{BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=pgExtra}) corner(grp,12)
	I("UIStroke",{Color=C.SEP,Thickness=0.5,Parent=grp})

		local ddRow=I("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=grp})
		local ddLbl=lbl(ddRow,"Choose player...",13,C.SUB) ddLbl.Position=UDim2.fromOffset(14,0) ddLbl.Size=UDim2.new(1,-50,1,0) ddLbl.TextYAlignment=Enum.TextYAlignment.Center
		local arr=lbl(ddRow,"▼",12,C.DIM,false,Enum.TextXAlignment.Center) arr.AnchorPoint=Vector2.new(1,0.5) arr.Position=UDim2.new(1,-14,0.5,0) arr.Size=UDim2.fromOffset(20,20)
		local ddBtn=I("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=ddRow})

		sep(grp,46)

		local btnRow=I("Frame",{Position=UDim2.fromOffset(0,47),Size=UDim2.new(1,0,0,46),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=grp})
	local refB=I("TextButton",{Position=UDim2.fromOffset(14,8),Size=UDim2.new(0.45,-14,0,30),BackgroundColor3=C.CELL,BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.Gotham,Text="🔄 Refresh",TextSize=11,TextColor3=C.SUB,Parent=btnRow}) corner(refB,8)
	local tpB=I("TextButton",{AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-14,0,8),Size=UDim2.new(0.55,-14,0,30),BackgroundColor3=C.ACC,BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.GothamBold,Text="🚀 Teleport",TextSize=11,TextColor3=Color3.new(1,1,1),Parent=btnRow}) corner(tpB,8)

	grp.Size=UDim2.new(1,0,0,93)
	I("Frame",{Size=UDim2.new(1,0,0,10),BackgroundTransparency=1,Parent=pgExtra})

	local ddList=I("ScrollingFrame",{Size=UDim2.fromOffset(200,100),BackgroundColor3=C.SHEET,ScrollBarThickness=2,ScrollBarImageColor3=C.ACC,CanvasSize=UDim2.new(0,0,0,0),ZIndex=50,Visible=false,Parent=win})
	corner(ddList,10) I("UIStroke",{Color=C.SEP,Thickness=1,Parent=ddList})
	I("UIListLayout",{Parent=ddList})

	local selPlayer=nil local ddOpen=false

	local function populateDrop()
		for _,c in ipairs(ddList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		local names={} for _,p in ipairs(Svc.Players:GetPlayers()) do if p~=plr then table.insert(names,p.Name) end end
		if #names==0 then table.insert(names,"(No Player)") end
		for i,name in ipairs(names) do
			local opt=I("TextButton",{LayoutOrder=i,Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,Font=Enum.Font.Gotham,Text=name,TextSize=12,TextColor3=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=51,Parent=ddList})
			I("UIPadding",{PaddingLeft=UDim.new(0,12),Parent=opt})
			opt.MouseButton1Click:Connect(function() selPlayer=name ddLbl.Text=name ddLbl.TextColor3=C.TEXT ddOpen=false ddList.Visible=false arr.Text="▼" end)
		end
		ddList.CanvasSize=UDim2.new(0,0,0,#names*32)
	end
	populateDrop()

	ddBtn.MouseButton1Click:Connect(function()
		populateDrop()
		ddOpen=not ddOpen ddList.Visible=ddOpen arr.Text=ddOpen and "▲" or "▼"
		if ddOpen then
			local abs=ddRow.AbsolutePosition local sz=ddRow.AbsoluteSize
			ddList.Position=UDim2.fromOffset(abs.X-win.AbsolutePosition.X, abs.Y-win.AbsolutePosition.Y+sz.Y+4)
			ddList.Size=UDim2.fromOffset(sz.X,math.min(#ddList:GetChildren()*32,120))
		end
	end)
	refB.MouseButton1Click:Connect(populateDrop)
	tpB.MouseButton1Click:Connect(function()
		if not selPlayer or selPlayer=="((No Player)" then return end
		local tgt=Svc.Players:FindFirstChild(selPlayer) local char=plr.Character local root=char and char:FindFirstChild("HumanoidRootPart")
		if tgt and root then local tc=tgt.Character local tr=tc and tc:FindFirstChild("HumanoidRootPart") if tr then root.CFrame=tr.CFrame*CFrame.new(0,0,3) end end
	end)
end

-- ═══════════════════════════════════════════════
--  PAGE: ABOUT
-- ═══════════════════════════════════════════════
local pgAbout=mkPage("about")

iosSection(pgAbout,"Info Script",{{type="info",txt="⚡ NR Evomon v3\nScript made for you to help play game more easyly.",h=60}})

iosSection(pgAbout,"Thankyou",{{type="info",txt="Special thanks to NicS, Pokeking & Donation to help some features works.",h=80}})

iosSection(pgAbout,"Version",{{type="info",txt="Build Version: V3 (WORKS)\nLast Update: 30 June 2026 0:30 AM",h=46}})

-- ═══════════════════════════════════════════════
--  PAGE: BOSS FARM
-- ═══════════════════════════════════════════════
local pgBoss = mkPage("boss")

iosSection(pgBoss,"Boss Farm",{{type="info",txt="Choose boss → Enter Battle.\nLoop ON = Loop Boss Fight NO CD.\nLoop OFF = Stop Loop.",h=52}})

do
	local hf=I("Frame",{Size=UDim2.new(1,0,0,26),BackgroundTransparency=1,Parent=pgBoss})
	local hl=lbl(hf,"Choose BOSS",9,C.SUB,true) hl.Size=UDim2.fromScale(1,1) hl.Position=UDim2.fromOffset(4,0) hl.TextYAlignment=Enum.TextYAlignment.Bottom

	local grpBoss=I("Frame",{BackgroundColor3=C.SHEET,BorderSizePixel=0,Parent=pgBoss}) corner(grpBoss,12)
	I("UIStroke",{Color=C.SEP,Thickness=0.5,Parent=grpBoss})

		local bddRow=I("Frame",{Size=UDim2.new(1,0,0,46),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=grpBoss})
		local bddLbl=lbl(bddRow,"Choose boss...",13,C.SUB) bddLbl.Position=UDim2.fromOffset(14,0) bddLbl.Size=UDim2.new(1,-50,1,0) bddLbl.TextYAlignment=Enum.TextYAlignment.Center
		local bddArr=lbl(bddRow,"▼",12,C.DIM,false,Enum.TextXAlignment.Center) bddArr.AnchorPoint=Vector2.new(1,0.5) bddArr.Position=UDim2.new(1,-14,0.5,0) bddArr.Size=UDim2.fromOffset(20,20)
		local bddBtn=I("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="",Parent=bddRow})

		sep(grpBoss,46)

		local bBtnRow=I("Frame",{Position=UDim2.fromOffset(0,47),Size=UDim2.new(1,0,0,46),BackgroundColor3=C.BG,BorderSizePixel=0,Parent=grpBoss})
		local enterBtn=I("TextButton",{Position=UDim2.fromOffset(14,8),Size=UDim2.new(1,-28,0,30),BackgroundColor3=C.ACC,BorderSizePixel=0,AutoButtonColor=false,Font=Enum.Font.GothamBold,Text="⚔️ Enter Battle",TextSize=13,TextColor3=Color3.new(1,1,1),Parent=bBtnRow}) corner(enterBtn,8)

	grpBoss.Size=UDim2.new(1,0,0,93)
	I("Frame",{Size=UDim2.new(1,0,0,4),BackgroundTransparency=1,Parent=pgBoss})

	local bddList=I("ScrollingFrame",{Size=UDim2.fromOffset(200,120),BackgroundColor3=C.SHEET,ScrollBarThickness=2,ScrollBarImageColor3=C.ACC,CanvasSize=UDim2.new(0,0,0,0),ZIndex=50,Visible=false,Parent=win})
	corner(bddList,10) I("UIStroke",{Color=C.SEP,Thickness=1,Parent=bddList})
	I("UIListLayout",{Parent=bddList})

	local selBoss = nil
	local bddOpen = false

	local function populateBossDrop()
		for _,c in ipairs(bddList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for i,boss in ipairs(BOSS_LIST) do
			local opt=I("TextButton",{LayoutOrder=i,Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,Font=Enum.Font.Gotham,Text=boss.name,TextSize=12,TextColor3=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=51,Parent=bddList})
			I("UIPadding",{PaddingLeft=UDim.new(0,12),Parent=opt})
			opt.MouseButton1Click:Connect(function()
				selBoss=boss bddLbl.Text=boss.name bddLbl.TextColor3=C.TEXT bddOpen=false bddList.Visible=false bddArr.Text="▼"
			end)
		end
		bddList.CanvasSize=UDim2.new(0,0,0,#BOSS_LIST*32)
	end

	bddBtn.MouseButton1Click:Connect(function()
		populateBossDrop()
		bddOpen=not bddOpen bddList.Visible=bddOpen bddArr.Text=bddOpen and "▲" or "▼"
		if bddOpen then
			local abs=bddRow.AbsolutePosition local sz=bddRow.AbsoluteSize
			bddList.Position=UDim2.fromOffset(abs.X-win.AbsolutePosition.X, abs.Y-win.AbsolutePosition.Y+sz.Y+4)
			bddList.Size=UDim2.fromOffset(sz.X, math.min(#BOSS_LIST*32, 160))
		end
	end)

	local loopRows=iosSection(pgBoss,"Loop",{{type="toggle",title="🔁 Loop Boss Battle",sub="Auto Battle Boss Non-stop"}})
	local bossLoopHit,bossLoopGet,bossLoopSet = loopRows[1].a,loopRows[1].b,loopRows[1].c

	local bossStRows=iosSection(pgBoss,"Status",{{type="info",txt="—",h=54}})
	local bossStLbl=bossStRows[1].a bossStLbl.TextXAlignment=Enum.TextXAlignment.Center

	iosSection(pgBoss,"Info",{{type="info",txt="Use Active pet minimum 2.",h=52}})

	local function getActiveTeamPets()
		local function sr(p)
			local ok, r = pcall(function()
				local o = RS
				for _, s in ipairs(p:split(".")) do
					o = o:FindFirstChild(s)
					if not o then return nil end
				end
				if o and o:IsA("ModuleScript") then return require(o) end
				return nil
			end)
			return ok and r or nil
		end

		local PS = sr("Storage.PetStorage")
		local PGS = sr("Storage.PetGroupStorage")
		local CDM = sr("Core.Config.ConfigDataManager")
		local CC = sr("Core.Config.ConfigConst")

		local function getCfgName(id)
			if not CDM or not CC or typeof(id) ~= "number" then return nil end
			local ok, r = pcall(function() return CDM.getConfig(CC.ConfigName.PET, id) end)
			if ok and typeof(r) == "table" then return r.name end
			return nil
		end

		if not PS or not PGS then return nil, "PetStorage / PetGroupStorage not found." end
		local petList = PS.getPetList and PS.getPetList()
		if typeof(petList) ~= "table" then return nil, "Could not read pet list." end
		local group = PGS.getPetGroup and PGS.getPetGroup()
		if typeof(group) ~= "table" then return nil, "Could not read pet group." end
		local gid = group.currentGroupId or 1
		local gd = group.petGroupList and group.petGroupList[gid]
		local uuids = (gd and gd.petUuids) or {}
		if #uuids == 0 then return nil, "No pets in current team." end
		local result = {}
		for idx, uuid in ipairs(uuids) do
			if typeof(uuid) == "string" and uuid ~= "" then
				local pd = petList[uuid]
				if typeof(pd) == "table" then
					table.insert(result, {
						uuid     = uuid,
						configId = pd.configId,
						name     = getCfgName(pd.configId) or tostring(pd.configId),
						level    = pd.level,
					})
				end
			end
		end
		if #result == 0 then return nil, "No valid pets found." end
		return result, nil
	end

	local function doEnterBattle(boss)
		pcall(function()
			local rc=workspace:FindFirstChild("RuntimeCache")
			local rcs=rc and rc:FindFirstChild("RuntimeCacheServer")
			local cache=rcs and rcs:FindFirstChild("CreatureModelCache")
			if cache then
				for _,child in ipairs(cache:GetChildren()) do
					local cid=child:GetAttribute("configId") or child:GetAttribute("ConfigId")
					if tonumber(cid)==boss.configId then
						local petModel=child:FindFirstChildWhichIsA("Model")
						local bossRoot=petModel and (petModel:FindFirstChild("HumanoidRootPart") or petModel.PrimaryPart)
						local char=plr.Character local myRoot=char and char:FindFirstChild("HumanoidRootPart")
						if bossRoot and myRoot then myRoot.CFrame=bossRoot.CFrame*CFrame.new(0,0,4) end
						break
					end
				end
			end
		end)
		task.wait(0.2)
		local pets, err = getActiveTeamPets()
		if not pets then
			bossStLbl.Text="❌ Gagal baca pet team!\n"..(err or "") bossStLbl.TextColor3=Color3.fromRGB(200,60,60)
			return false
		end
		local uid = pets[1].uuid
		local remote = nil
		pcall(function() remote = RS.Remote.Battle.ReqEnterNpcBattle end)
		if remote then
			remote:FireServer(boss.configId, boss.battlePoolId, uid)
			bossStLbl.Text="⚔️ "..boss.name.."\nEntered! Pet: "..(pets[1].name or uid) bossStLbl.TextColor3=C.GREEN
			local waited=0 repeat task.wait(0.5) waited=waited+0.5 until waited>=15
			return true
		else
			bossStLbl.Text="❌ Remote Not Found" bossStLbl.TextColor3=Color3.fromRGB(200,60,60)
			return false
		end
	end

	enterBtn.MouseButton1Click:Connect(function()
		if not selBoss then bossStLbl.Text="❌ Choose boss first!" bossStLbl.TextColor3=Color3.fromRGB(200,60,60) return end
		if S_BossLoop then bossStLbl.Text="⚠️ Loop ON\nTurn off Loop!" bossStLbl.TextColor3=C.ORG return end
		bossStLbl.Text="⏳ Entering "..selBoss.name.."..." bossStLbl.TextColor3=C.ACC
		task.spawn(function() doEnterBattle(selBoss) end)
	end)

	bossLoopHit.Activated:Connect(function()
		if S.Closed then return end
		S_BossLoop = not S_BossLoop bossLoopSet(S_BossLoop)
		if S_BossLoop then
			if not selBoss then
				bossStLbl.Text="❌ Choose boss first!" bossStLbl.TextColor3=Color3.fromRGB(200,60,60)
				S_BossLoop=false bossLoopSet(false) return
			end
			bossStLbl.Text="🔁 Loop Boss: "..selBoss.name bossStLbl.TextColor3=C.BLUE
			task.spawn(function()
				while S_BossLoop and not S.Closed do
					local inBattle = _BattleService and _BattleService.getCurrentBattle and _BattleService.getCurrentBattle() ~= nil
					if not inBattle then doEnterBattle(selBoss) end
					task.wait(5)
				end
			end)
		else bossStLbl.Text="—" bossStLbl.TextColor3=C.DIM end
	end)
end

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

-- ─── PITY OVERLAY ────────────────────────────
local pityOverlay=I("Frame",{AnchorPoint=Vector2.new(0.5,0),Position=UDim2.new(0.5,0,0,60),Size=UDim2.new(0.4,0,0,120),BackgroundTransparency=1,ZIndex=20,Visible=false,Parent=gui})
local pityOverlayLbl=I("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="💎 —/—\n✨ —/—",TextSize=14,TextScaled=true,Font=Enum.Font.GothamBold,TextColor3=Color3.new(1,1,1),TextStrokeTransparency=0,TextStrokeColor3=Color3.new(0,0,0),TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Top,ZIndex=20,Parent=pityOverlay})

-- ─── BUBBLE ──────────────────────────────────
local bubble=I("TextButton",{AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(44,44),BackgroundColor3=C.ACC,BorderSizePixel=0,AutoButtonColor=false,Active=true,Font=Enum.Font.GothamBold,Text="⚡",TextSize=18,TextColor3=Color3.new(1,1,1),Visible=false,ZIndex=10,Parent=gui})
corner(bubble,22)

-- ─── DRAG LOGIC ──────────────────────────────
topBar.InputBegan:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 then
		DS.on=true DS.start=inp.Position DS.pos=win.Position
		inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then DS.on=false end end)
	end
end)
topBar.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseMovement then DS.input=inp end end)

minBtn.Activated:Connect(function()
	if S.Closed then return end
	local ab=win.AbsolutePosition local sz=win.AbsoluteSize
	bubble.Position=UDim2.fromOffset(ab.X+sz.X/2,ab.Y+sz.Y/2)
	win.Visible=false bubble.Visible=true
end)

bubble.InputBegan:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
		BS.on=true BS.moved=false BS.start=inp.Position BS.pos=bubble.Position
		inp.Changed:Connect(function() if inp.UserInputState==Enum.UserInputState.End then BS.on=false if not BS.moved and not S.Closed then win.Visible=true bubble.Visible=false end end end)
	end
end)
bubble.InputChanged:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then BS.input=inp end end)

Svc.UIS.InputChanged:Connect(function(inp)
	if DS.on and DS.input and inp==DS.input and DS.start then
		local d=inp.Position-DS.start win.Position=UDim2.new(DS.pos.X.Scale,DS.pos.X.Offset+d.X,DS.pos.Y.Scale,DS.pos.Y.Offset+d.Y)
	end
	if BS.on and BS.input and inp==BS.input and BS.start and BS.pos then
		local d=inp.Position-BS.start
		if math.abs(d.X)>4 or math.abs(d.Y)>4 then BS.moved=true end
		bubble.Position=UDim2.new(BS.pos.X.Scale,BS.pos.X.Offset+d.X,BS.pos.Y.Scale,BS.pos.Y.Offset+d.Y)
	end
end)

-- ─── EVENT CONNECTIONS ───────────────────────
cHit.Activated:Connect(function()
	if S.Closed then return end
	S.AutoCatch=not S.AutoCatch cSet(S.AutoCatch) updateStatus()
	setStatus(S.AutoCatch and "Looking for a pet..." or "Idle", S.AutoCatch and C.BLUE or C.SUB)
	if not S.AutoCatch then catchIndLbl.Text="—" catchIndLbl.TextColor3=C.DIM end
end)

lHit.Activated:Connect(function()
	if S.Closed then return end
	if S.CatchShinyOnly or S.CatchShinyPris then return end
	S.AutoLeave=not S.AutoLeave lSet(S.AutoLeave) updateStatus()
end)

bsHit.Activated:Connect(function()
	if S.Closed then return end
	S.BattleSpeedup=not S.BattleSpeedup bsSet(S.BattleSpeedup)
	if S.BattleSpeedup then applyBattleSpeedup() end
end)

nbHit.Activated:Connect(function()
	if S.Closed then return end
	S.NoBall=not S.NoBall nbSet(S.NoBall)
end)

eHit.Activated:Connect(function()
	if S.Closed then return end
	S.PlayerESP=not S.PlayerESP eSet(S.PlayerESP) updateStatus()
	for _,obj in pairs(S.ESPCache) do if obj.hl then obj.hl.Enabled=S.PlayerESP end if obj.bb then obj.bb.Enabled=S.PlayerESP end end
end)

chHit.Activated:Connect(function()
	if S.Closed then return end
	S.ChestFarm=not S.ChestFarm chSet(S.ChestFarm) updateStatus()
	if S.ChestFarm then chStLbl.Text="Active ✅" chStLbl.TextColor3=C.GREEN
	else chStLbl.Text="Inactive" chStLbl.TextColor3=C.DIM end
end)

ovHit.Activated:Connect(function()
	if S.Closed then return end
	S.ShowPityOverlay=not S.ShowPityOverlay ovSet(S.ShowPityOverlay)
	pityOverlay.Visible=S.ShowPityOverlay
end)

soHit.Activated:Connect(function()
	if S.Closed then return end
	S.CatchShinyOnly=not S.CatchShinyOnly soSet(S.CatchShinyOnly)
	if S.CatchShinyOnly then
		if S.CatchShinyPris then S.CatchShinyPris=false spSet(false) end
		S.AutoCatch=true cSet(true) S.AutoLeave=true lSet(true) updateStatus()
		setStatus("Looking for a pet...",C.SUB) warn("✨ Catch Shiny Only: ON")
	else
		S.AutoCatch=false cSet(false) S.AutoLeave=false lSet(false) updateStatus()
		setStatus("Idle") warn("✨ Catch Shiny Only: OFF")
	end
end)

spHit.Activated:Connect(function()
	if S.Closed then return end
	S.CatchShinyPris=not S.CatchShinyPris spSet(S.CatchShinyPris)
	if S.CatchShinyPris then
		if S.CatchShinyOnly then S.CatchShinyOnly=false soSet(false) end
		S.AutoCatch=true cSet(true)
		local cur,max=getPityInfo()
		if cur and max and cur>=(max-1) then S.AutoLeave=true lSet(true) else S.AutoLeave=false lSet(false) end
		updateStatus() setStatus("Looking for a pet...",C.SUB) warn("💎 Catch Shiny & Prismatic: ON")
	else
		S.AutoCatch=false cSet(false) S.AutoLeave=false lSet(false) updateStatus()
		setStatus("Idle") warn("💎 Catch Shiny & Prismatic: OFF")
	end
end)

akHit.Activated:Connect(function()
	if S.Closed then return end S.AutoKingBall=not S.AutoKingBall akSet(S.AutoKingBall)
	if S.AutoKingBall then S.AutoAdvBall=false abSet(false) S.AutoPrismBall=false pbSet(false) end
end)
abHit.Activated:Connect(function()
	if S.Closed then return end S.AutoAdvBall=not S.AutoAdvBall abSet(S.AutoAdvBall)
	if S.AutoAdvBall then S.AutoKingBall=false akSet(false) S.AutoPrismBall=false pbSet(false) end
end)
pbHit.Activated:Connect(function()
	if S.Closed then return end S.AutoPrismBall=not S.AutoPrismBall pbSet(S.AutoPrismBall)
	if S.AutoPrismBall then S.AutoKingBall=false akSet(false) S.AutoAdvBall=false abSet(false) end
end)

manBtn.MouseButton1Click:Connect(function() if not S.Closed then teleportChest() end end)

closeBtn.Activated:Connect(function()
	S.Running=false S.Closed=true S_BossLoop=false S.AutoCatch=false S.AutoLeave=false S.PlayerESP=false S.ChestFarm=false
	gui:Destroy()
end)

-- ─── MAIN LOOPS ──────────────────────────────
task.spawn(function()
	while task.wait(S.LoopDelay) do
		if not S.Running then break end
		if not S.AutoCatch and not S.AutoLeave then continue end
		if catchVisible() then
			catchIndLbl.Text="⚡ Catch Screen Active" catchIndLbl.TextColor3=C.GREEN
			handleCatch() continue
		else catchIndLbl.Text="—" catchIndLbl.TextColor3=C.DIM end
		if S.AutoCatch then
			pcall(function()
				local m,p,d=findPet()
				if m and p then
					S.LastPetName=petName(m.Name)
					setStatus(string.format("→ %s (%.1f m)",S.LastPetName,d*0.28),C.BLUE)
					local char=plr.Character local hum=char and char:FindFirstChildOfClass("Humanoid")
					if hum then
						local keys={Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D}
						for _=1,math.random(2,4) do local k=keys[math.random(1,4)] Svc.VIM:SendKeyEvent(true,k,false,game) task.wait(math.random(10,25)/100) Svc.VIM:SendKeyEvent(false,k,false,game) task.wait(0.5) end
						hum:MoveTo(p.Position)
					end
				else setStatus(string.format("No pet (r=%.0fm)",S.ScanRadius*0.28)) end
			end)
		else setStatus("Auto Leave standby...",C.SUB) end
	end
end)

task.spawn(function() -- Watchdog
	while task.wait(2) do
		if not S.Running then break end
		if (S.AutoCatch or S.AutoLeave) and catchVisible() then
			catchIndLbl.Text="⚡ Catch Screen Active" catchIndLbl.TextColor3=C.GREEN
			handleCatch()
		end
	end
end)

task.spawn(function() -- Chest
	while task.wait() do
		if not S.Running then break end
		if S.ChestFarm then
			teleportChest()
			chStLbl.Text=string.format("Active ✅ [#%d]",S.ChestIdx) chStLbl.TextColor3=C.GREEN
			local el=0 while el<S.ChestDelay and S.ChestFarm do pressKey(Enum.KeyCode.E,0.05) task.wait(0.2) el=el+0.2 end
		else task.wait(0.5) end
	end
end)

task.spawn(function() -- Pity watcher
	while task.wait(1) do
		if not S.Running then break end
		if curPage=="shiny" then updatePityUI() end
		if S.ShowPityOverlay then
			local cur,max=getPityInfo()
			local ps=(cur and max) and string.format("💎 %d/%d",cur,max) or "💎 —/—"
			local sh=PGui:FindFirstChild("ShinyPityText",true) local ss="✨ —/—"
			if sh then local sc,sm=sh.Text:match("(%d+)/(%d+)") if sc then ss=string.format("✨ %s/%s",sc,sm) end end
			local pet=S.LastPetName and ("["..S.LastPetName.."]\n") or ""
			pityOverlayLbl.Text=pet..ps.."\n"..ss
		end
		if S.CatchShinyPris then
			local cur,max=getPityInfo()
			if cur and max then
				local ready=cur>=(max-1)
				if ready and not S.AutoLeave then onPrismaticReady()
				elseif not ready and S.AutoLeave and not isShiny() then
					S.AutoLeave=false lSet(false) updateStatus()
					setStatus(string.format("💎 Farming... %d/%d",cur,max),C.SUB)
				end
			end
		end
	end
end)

-- ─── BATTLE SPEED MAINTENANCE ────────────────
task.spawn(function()
	task.wait(2)
	if not S.Closed then applyBattleSpeedup() end
	while task.wait(10) do
		if not S.Running or S.Closed then break end
		if S.BattleSpeedup then pcall(applyBattleSpeedup) end
	end
end)

local _lastSync = 0
task.spawn(function()
	while task.wait(1) do
		if not S.Running or S.Closed then break end
		local inBattle = _BattleService and _BattleService.getCurrentBattle and _BattleService.getCurrentBattle() ~= nil
		if inBattle then
			if os.clock() - _lastSync > 5 then
				_lastSync = os.clock()
				pcall(syncAutoSpeed)
			end
		end
	end
end)

updateStatus()
setStatus("Idle")
print("⚡ NR Evomon v3 smart optimized loaded!")
