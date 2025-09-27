local ADDON_NAME 			= ...
local PathToGreenTGA		= [[Interface\AddOns\]] .. ADDON_NAME .. [[\Media\Green.tga]]

local _G, type, pairs, ipairs, select, unpack, table, setmetatable, math, string, error = 	
	  _G, type, pairs, ipairs, select, unpack, table, setmetatable, math, string, error 
	  
local tinsert 				= table.insert	  
local tsort 				= table.sort	  
local strgsub				= string.gsub
local strgmatch				= string.gmatch
local strlen				= string.len
local huge 					= math.huge  
local wipe 					= _G.wipe	
local hooksecurefunc		= _G.hooksecurefunc	  
	  
local TMW 					= _G.TMW
local CNDT 					= TMW.CNDT
local Env 					= CNDT.Env
local strlowerCache  		= TMW.strlowerCache

local A   					= _G.Action	
local CONST 				= A.Const
local Listener				= A.Listener
local Print					= A.Print
local toNum 				= A.toNum
local UnitCooldown			= A.UnitCooldown
local CombatTracker			= A.CombatTracker
local Unit					= A.Unit 
local Player				= A.Player 
local LoC 					= A.LossOfControl
local MultiUnits			= A.MultiUnits
local EnemyTeam				= A.EnemyTeam
local FriendlyTeam			= A.FriendlyTeam
local GetToggle				= A.GetToggle
local BurstIsON				= A.BurstIsON
local AuraIsValid			= A.AuraIsValid
local InstanceInfo			= A.InstanceInfo
local BuildToC				= A.BuildToC
local Enum 					= A.Enum
local TriggerGCD			= Enum.TriggerGCD
local SpellDuration			= Enum.SpellDuration
local SpellProjectileSpeed	= Enum.SpellProjectileSpeed

local TRINKET1				= CONST.TRINKET1
local TRINKET2				= CONST.TRINKET2
local POTION				= CONST.POTION
local HEARTOFAZEROTH		= CONST.HEARTOFAZEROTH
local EQUIPMENT_MANAGER		= CONST.EQUIPMENT_MANAGER
local CACHE_DEFAULT_TIMER	= CONST.CACHE_DEFAULT_TIMER
local SPELLID_FREEZING_TRAP = CONST.SPELLID_FREEZING_TRAP
local SPELLID_STORM_BOLT	= CONST.SPELLID_STORM_BOLT

local LibStub				= _G.LibStub

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_OnGCD, A_GetCurrentGCD, A_GetGCD, A_GetPing, A_GetSpellInfo, A_GetSpellDescription 

Listener:Add("ACTION_EVENT_ACTIONS", "ADDON_LOADED", function(addonName) 
	if addonName == CONST.ADDON_NAME then 
		A_OnGCD					= A.OnGCD
		A_GetCurrentGCD			= A.GetCurrentGCD
		A_GetGCD				= A.GetGCD
		A_GetPing				= A.GetPing
		A_GetSpellInfo			= A.GetSpellInfo
		A_GetSpellDescription	= A.GetSpellDescription
		Listener:Remove("ACTION_EVENT_ACTIONS", "ADDON_LOADED")	
	end 	
end)
-------------------------------------------------------------------------------  
local Azerite 				= LibStub("AzeriteTraits")
local LegendaryCrafting		= LibStub("LegendaryCrafting")
local Pet					= LibStub("PetLibrary")
local SpellRange			= LibStub("SpellRange-1.0")
local IsSpellInRange 		= SpellRange.IsSpellInRange	  
local SpellHasRange			= SpellRange.SpellHasRange
local isSpellRangeException = {
	-- Chi Burst 
	[123986] 	= true,
	-- Eye Beam
	[198013] 	= true,
	-- Darkflight
	[68992] 	= true,
	-- SpatialRift
	[256948]	= true,
	-- Shadowmeld
	[58984]		= true,
	-- LightsJudgment
	[255647]	= true,
	-- EveryManforHimself
	[59752]		= true, 
	-- EscapeArtist
	[20589]		= true,
	-- Stoneform
	[20594] 	= true, 
	-- Fireblood
	[265221]	= true,
	-- Regeneratin
	[291944]	= true,
	-- WilloftheForsaken
	[7744]		= true,
	-- Berserking
	[26297]		= true,
	-- WarStomp
	[20549]		= true, 
	-- BloodFury
	[33697]		= true,
	[20572]		= true,
	[33702]		= true,	
	-- ArcanePulse
	[260364]	= true,
	-- AncestralCall
	[274738]	= true,
	-- BullRush
	[255654]	= true,
	-- ArcaneTorrent
	[28730]		= true, 
	[155145]	= true,
	[80483]		= true,
	[25046]		= true, 
	[232633]	= true,
	[50613]		= true,
	[69179]		= true,
	[202719]	= true,
	[129597]	= true,
	-- RocketBarrage 
	[69041]		= true,
	-- RocketJump
	[69070]		= true,
	-- Metamorphosis 
	[191427]	= true,
	[162264]	= true,
	[187827]	= true,
	-- Typhoon
	[132469]	= true,
}
local ItemHasRange 			= _G.ItemHasRange or _G.C_Item.ItemHasRange
local isItemRangeException 	= {}
local isItemUseException	= {
	-- Crest of Pa'ku
	[165581] = true, 
	-- Mr. Munchykins
	[155567] = true, 
	-- Ingenious Mana Battery
	[169344] = true, 
}
local itemCategory 			= {
	[169311] = "DPS",	-- Ashvane's Razor Coral
	[167555] = "DPS",	-- Pocket-Sized Computation Device
    [165806] = "DPS", 	-- Sinister Gladiator's Maledict
	[165056] = "DEFF", 	-- Sinister Gladiator's Emblem
	[161675] = "DEFF", 	-- Dread Gladiator's Emblem
	[159618] = "DEFF", 	-- Mchimba's Ritual Bandages (Tank Item)
}	  	 

local GetNetStats 			= _G.GetNetStats	  
local GameLocale 			= _G.GetLocale()
local GetCVar				= _G.GetCVar or _G.C_CVar.GetCVar

-- AssistedCombat
local GetNextCastSpell		= _G.C_AssistedCombat and A.MakeFunctionCachedStatic(_G.C_AssistedCombat.GetNextCastSpell)

-- Spell 
local C_Spell						= _G.C_Spell
local FindSpellBookSlotBySpellID	= _G.FindSpellBookSlotBySpellID

local C_SpellBook					= _G.C_SpellBook
local FindSpellBookSlotForSpell		= C_SpellBook.FindSpellBookSlotForSpell

local 	 IsSpellKnownOrOverridesKnown,	  IsPlayerSpell,										 IsUsableSpell, 	 									 IsHelpfulSpell, 										  IsHarmfulSpell,    										  IsAttackSpell, 	 									  IsCurrentSpell =
	  _G.IsSpellKnownOrOverridesKnown, _G.IsPlayerSpell, C_Spell and C_Spell.IsSpellUsable or _G.IsUsableSpell, C_Spell and C_Spell.IsSpellHelpful or _G.IsHelpfulSpell, C_Spell and C_Spell.IsSpellHarmful or _G.IsHarmfulSpell, C_Spell and C_Spell.IsAutoAttackSpell or _G.IsAttackSpell, C_Spell and C_Spell.IsCurrentSpell or _G.IsCurrentSpell

local 	  GetSpellTexture, 	  									  GetSpellLink, 									   GetSpellName,    									GetSpellInfo, 							 					GetSpellDescription, 										 	 GetSpellCount,	   										    GetSpellPowerCost, 	   CooldownDuration,    									   GetSpellCharges,    GetHaste,    GetShapeshiftFormCooldown, 	  GetSpellBaseCooldown,   										   GetSpellAutocast = 
	  TMW.GetSpellTexture, C_Spell and C_Spell.GetSpellLink or _G.GetSpellLink, C_Spell and C_Spell.GetSpellName or _G.GetSpellInfo, C_Spell and C_Spell.GetSpellInfo or _G.GetSpellInfo, C_Spell and C_Spell.GetSpellDescription or _G.GetSpellDescription, C_Spell and C_Spell.GetSpellCastCount or _G.GetSpellCount, C_Spell and C_Spell.GetSpellPowerCost or _G.GetSpellPowerCost, Env.CooldownDuration, C_Spell and C_Spell.GetSpellCharges or _G.GetSpellCharges, _G.GetHaste, _G.GetShapeshiftFormCooldown, _G.GetSpellBaseCooldown, C_Spell and C_Spell.GetSpellAutoCast or _G.GetSpellAutocast

-- Item 	  
local C_Item 						= _G.C_Item
local 	 								   IsUsableItem, 	 								   IsHelpfulItem, 					IsHarmfulItem, 	  														 IsCurrentItem =
	  C_Item and C_Item.IsUsableItem or _G.IsUsableItem, C_Item and C_Item.IsHelpfulItem or _G.IsHelpfulItem, C_Item and C_Item.IsHarmfulItem or _G.IsHarmfulItem, C_Item and C_Item.IsCurrentItem or _G.IsCurrentItem
  
local 	 								  GetItemInfo, 	 									   GetItemIcon, 	  									   GetItemInfoInstant, 	 								    GetItemSpell = 
	  C_Item and C_Item.GetItemInfo or _G.GetItemInfo, C_Item and C_Item.GetItemIconByID or _G.GetItemIcon, C_Item and C_Item.GetItemInfoInstant or _G.GetItemInfoInstant, C_Item and C_Item.GetItemSpell or _G.GetItemSpell	  

-- Talent	  
local     TalentMap,     PvpTalentMap =
	  Env.TalentMap, Env.PvpTalentMap

-- Unit 	  
local  UnitIsUnit,    	UnitAura 								= 
	_G.UnitIsUnit, _G.C_UnitAuras.GetAuraDataByIndex
	
-- Debug 	
local  GetNumSpecializationsForClassID,    GetSpecializationInfo =
	_G.GetNumSpecializationsForClassID, _G.GetSpecializationInfo	

-- Empty 
local nullDescription 		= A.MakeTableReadOnly({ 0, 0, 0, 0, 0, 0, 0, 0 })

-- Auras
local IsBreakAbleDeBuff 	= {}
local IsCycloneDeBuff 		= {
	[GetSpellName(33786)] 	= true,
}
do 
	local tempTable = A.GetAuraList("BreakAble")	
	local tempTableInSkipID = A.GetAuraList("Rooted")
	for j = 1, #tempTable do 
		local isRoots 
		for l = 1, #tempTableInSkipID do 
			if tempTable[j] == tempTableInSkipID[l] then 
				isRoots = true 
				break 
			end 			
		end 
		
		if not isRoots then 
			local spellName = GetSpellName(tempTable[j])
			if spellName then 
				IsBreakAbleDeBuff[tempTable[j]] = true			
				IsBreakAbleDeBuff[spellName] = true 
			else 
				error("Unit.lua has invalid spellID " .. tempTable[j] .. " in Auras.BreakAble")
			end 
		end 
	end 
end 

-- Player 
local GCD_OneSecond 		= {
	[CONST.DRUID_FERAL] 		= true, 			-- Feral
	[CONST.ROGUE_ASSASSINATION] = true, 			-- Assassination
	[CONST.ROGUE_OUTLAW] 		= true, 			-- Outlaw
	[CONST.ROGUE_SUBTLETY] 		= true, 			-- Subtlety
	[CONST.MONK_BREWMASTER]		= true, 			-- Brewmaster
	[CONST.MONK_WINDWALKER] 	= true, 			-- Windwalker
}

local function sortByHighest(x, y)
	return x > y
end

-------------------------------------------------------------------------------
-- Global Cooldown
-------------------------------------------------------------------------------
-- Returns 'true' if duration field of spell/item cooldown used on global cooldown animation
A.OnGCD = TMW.OnGCD

function A.GetCurrentGCD()
	-- @return number 
	-- Current left in second time of in use (spining) GCD, 0 if GCD is not active
	return CooldownDuration("gcd") -- TMW.GCDSpell
end 
A.GetCurrentGCD = A.MakeFunctionCachedStatic(A.GetCurrentGCD)

function A.GetGCD()
	-- @return number 
	-- Summary time of GCD 
	if TMW.GCD > 0 then
		-- Depended by last used spell 
		return TMW.GCD
	else 
		if GCD_OneSecond[A.PlayerSpec] then 
			return 1
		else 
			-- Depended on current haste
			return 1.5 / (1 + GetHaste() / 100) -- 1.5 / (1 + UnitSpellHaste("player") * 0.01) -- TODO Retest GetHaste vs UnitSpellHaste
		end 
	end    
end

function A.IsActiveGCD()
	-- @return boolean 
	return TMW.GCD ~= 0
end

function A:IsRequiredGCD()
	-- @return boolean, number 
	-- true / false if required, number in seconds how much GCD will be used by action
	if self.Type == "Spell" and TriggerGCD[self.ID] and TriggerGCD[self.ID] > 0 then 
		return true, TriggerGCD[self.ID]
	end 
	
	return false, 0
end 

-------------------------------------------------------------------------------
-- Global Stop Conditions
-------------------------------------------------------------------------------
function A.GetPing()
	-- @return number
	local p = select(4, GetNetStats()) / 1000
	return p 
end 
A.GetPing = A.MakeFunctionCachedStatic(A.GetPing, 0)

function A.GetLatency()
	-- @return number 
	-- Returns summary delay caused by ping and interface respond time (usually not higher than 0.4 sec)
	return toNum[GetCVar("SpellQueueWindow") or 400] / 1000 + (A_GetPing() / 2)
end

function A:ShouldStopByGCD()
	-- @return boolean 
	-- By Global Cooldown
	if self:IsRequiredGCD() then  
		local ping = A_GetPing()
		local delay = ping + 0.65
		-- Outlaw Rogue has 200 ms GCD windows between shots with "Fan the hammer" talent after cast "Pistol Shot"
		if self.LastPlayerCastID == 185763 and self.PlayerSpec == CONST.ROGUE_OUTLAW and self.IsTalentLearned(381846) then 
			delay = ping + 0.2
		end 
		
		return A_GetGCD() - ping > 0.301 and A_GetCurrentGCD() >= delay
	end 
	
	return false 
end 

function A.ShouldStop()
	-- @return boolean 
	-- By Casting
	return Unit("player"):IsCasting() and true 
end 
A.ShouldStop = A.MakeFunctionCachedStatic(A.ShouldStop, 0)

-------------------------------------------------------------------------------
-- Spell
-------------------------------------------------------------------------------
-- Retail TWW now has it through self.ID / Classic still has through :Info()
local spellbasecache  = setmetatable({}, { __index = function(t, v)
	local cd = GetSpellBaseCooldown(v)
	if cd then
		t[v] = cd / 1000
		return t[v]
	end     
	return 0
end })

function A:GetSpellBaseCooldown()
	-- @return number (seconds)
	-- Gives the (unmodified) cooldown
	return spellbasecache[self.ID]
end 

local spellpowercache = setmetatable(
	{ 
		null = {0, 1},
	}, 
	{ 
		__index = function(t, v)
			local pwr = v and GetSpellPowerCost(v)
			if pwr then 
				if pwr[1] then
					t[v] = { pwr[1].cost, pwr[1].type }
					return t[v]
				else
					t[v] = { pwr.cost, pwr.type }
					return t[v]
				end 
			end     
			return t.null
		end,
	}
)

function A:GetSpellPowerCostCache()
	-- THIS IS STATIC CACHED, ONCE CALLED IT WILL NOT REFRESH REALTIME POWER COST
	-- @usage A:GetSpellPowerCostCache() or A.GetSpellPowerCostCache(spellID)
	-- @return cost (@number), type (@number)
	local ID = self
	if type(self) == "table" then 
		ID = self.ID 
	end
    return unpack(spellpowercache[ID]) 
end

function A.GetSpellPowerCost(self)
	-- RealTime with cycle cache
	-- @usage A:GetSpellPowerCost() or A.GetSpellPowerCost(123)
	-- @return cost (@number), type (@number)
	local spellID 
	if type(self) == "table" then 
		spellID = self.ID
	else 
		spellID = self
	end 
	
	local pwr = GetSpellPowerCost(spellID)
	if pwr and pwr[1] then
		return pwr[1].cost, pwr[1].type
	end   	
	return 0, -1
end 
A.GetSpellPowerCost = A.MakeFunctionCachedDynamic(A.GetSpellPowerCost)

local str_null 			= ""
local str_comma			= ","
local str_point			= "%."
local pattern_gmatch 	= "%f[%d]%d[.,%d]*%f[%D]"
local pattern_gsubspace	= "%s"
local descriptioncache 	= setmetatable({}, { __index = function(t, v)
	-- Stores formated string of description
	t[v] = strgsub(strgsub(v, pattern_gsubspace, str_null), str_comma, str_point)
	return t[v]
end })
local descriptiontemp	= {
	-- Stores temprorary data 
}
function A.GetSpellDescription(self)
	-- @usage A:GetSpellDescription() or A.GetSpellDescription(18)
	-- @return table array like where first index is highest number of the description
	local spellID = type(self) == "table" and self.ID or self
	local text = GetSpellDescription(spellID)
	
	if text then 
		-- The way to re-use table anyway is found now 
		if not descriptiontemp[spellID] then 
			descriptiontemp[spellID] = {}
		else 
			wipe(descriptiontemp[spellID])
		end 
		
		for value in strgmatch(descriptioncache[text], pattern_gmatch) do 
			if GameLocale == "frFR" and strlen(value) > 3 then -- French users have wierd syntax of floating dots
				tinsert(descriptiontemp[spellID], toNum[strgsub(value, str_point, str_null)])
			else 
				tinsert(descriptiontemp[spellID], toNum[value])
			end 
		end
		
		if #descriptiontemp[spellID] > 1 then
			tsort(descriptiontemp[spellID], sortByHighest)
		end 

		return descriptiontemp[spellID]
	end
	
	return nullDescription -- can not be used for 'next', 'unpack', 'pairs', 'ipairs'
end
A.GetSpellDescription = A.MakeFunctionCachedDynamic(A.GetSpellDescription)

function A:GetSpellCastTime()
	-- @return number 
	local spellName, _, _, castTime = GetSpellInfo(self.ID)
	if type(spellName) == "table" then 
		castTime = spellName.castTime
	end 
	return (castTime or 0) / 1000 
end 

function A:GetSpellCastTimeCache()
	-- @usage A:GetSpellCastTimeCache() or A.GetSpellCastTimeCache(116)
	-- @return number 
	if type(self) == "table" then 
		return (select(4, self:Info(true)) or 0) / 1000 
	else
		local spellName, _, _, castTime = GetSpellInfo(self)
		if type(spellName) == "table" then 
			castTime = spellName.castTime
		end 	
		return (castTime or 0) / 1000
	end  
end 

function A:GetSpellCharges()
	-- @return number
	local charges = GetSpellCharges(self.ID)
	if not charges then 
		charges = 0
	elseif type(charges) == "table" then 
		charges = charges.currentCharges
	end 
	
	return charges
end

function A:GetSpellChargesMax()
	-- @return number
	local charges, max_charges = GetSpellCharges(self.ID)
	if type(charges) == "table" then 
		max_charges = charges.maxCharges
	end  
	
	if not max_charges then 
		max_charges = 0
	end 
	
	return max_charges	
end

function A:GetSpellChargesFrac()
	-- @return number	
	local charges, maxCharges, start, duration = GetSpellCharges(self.ID)
	if type(charges) == "table" then 		
		maxCharges = charges.maxCharges
		start = charges.cooldownStartTime
		duration = charges.cooldownDuration
		charges = charges.currentCharges
	end  
	
	if not maxCharges then 
		return 0
	end 
	
	if charges == maxCharges then 
		return maxCharges
	end
	
	return charges + ((TMW.time - start) / duration)  
end

function A:GetSpellChargesFullRechargeTime()
	-- @return number
	local charges, _, _, duration = GetSpellCharges(self.ID)
	if type(charges) == "table" then 
		duration = charges.cooldownDuration
	end  
	
	if duration then 
		return (self:GetSpellChargesMax() - self:GetSpellChargesFrac()) * duration
	else 
		return 0
	end 
end 

function A:GetSpellTimeSinceLastCast()
	-- @return number (seconds after last time casted - during fight)
	return CombatTracker:GetSpellLastCast("player", self.ID)
end 

function A:GetSpellCounter()
	-- @return number (total count casted of the spell - during fight)
	return CombatTracker:GetSpellCounter("player", self.ID)
end 

function A:GetSpellAmount(unitID, X)
	-- @return number (taken summary amount of the spell - during fight)
	-- X during which lasts seconds 
	if X then 
		return CombatTracker:GetSpellAmountX(unitID or "player", self.ID, X)
	else 
		return CombatTracker:GetSpellAmount(unitID or "player", self.ID)
	end 
end 

function A:GetSpellAbsorb(unitID)
	-- @return number (taken current absort amount of the spell - during fight)
	return CombatTracker:GetAbsorb(unitID or "player", self.ID)
end 

function A:GetSpellAutocast()
	-- @return boolean, boolean 
	-- Returns autocastable, autostate 
	return GetSpellAutocast(self.ID)
end 

function A:GetSpellBaseDuration()
	-- @return number
	local Duration = SpellDuration[self.ID]
	if not Duration or Duration == 0 then return 0 end

	return Duration[1] / 1000
end

function A:GetSpellMaxDuration()
	-- @return number
	local Duration = SpellDuration[self.ID]
	if not Duration or Duration == 0 then return 0 end

	return Duration[2] / 1000
end

function A:GetSpellPandemicThreshold()
	-- @return number
	local BaseDuration = self:GetSpellBaseDuration()
	if not BaseDuration or BaseDuration == 0 then return 0 end

	return BaseDuration * 0.3
end

function A:GetSpellTravelTime(unitID)
	-- @return number
	local Speed = SpellProjectileSpeed[self.ID]
	if not Speed or Speed == 0 then return 0 end

	local MaxDistance = (unitID and Unit(unitID):GetRange()) or Unit("target"):GetRange()
	if not MaxDistance or MaxDistance == huge then return 0 end

	return MaxDistance / (Speed or 22)
end

function A:DoSpellFilterProjectileSpeed(owner)
	-- @usage
	-- Retail - Action:DoSpellFilterProjectileSpeed(Action.PlayerSpec) or A:DoSpellFilterProjectileSpeed(A.PlayerSpec)
	-- Classic - Action:DoSpellFilterProjectileSpeed(Action.PlayerClass) or A:DoSpellFilterProjectileSpeed(A.PlayerClass)
	-- Must be used after init Action[specID or className] = { ... } and whenever specialization has been changed for Retail version
	local RegisteredSpells = {}

	-- Fetch registered spells during the init
	local ProjectileSpeed
	for _, actionObj in pairs(A[owner]) do
		if actionObj.Type == "Spell" then 
			ProjectileSpeed = SpellProjectileSpeed[actionObj.ID]
			if ProjectileSpeed ~= nil then
				RegisteredSpells[actionObj.ID] = ProjectileSpeed
			end 
		end 
	end

	SpellProjectileSpeed = RegisteredSpells
end

function A:IsSpellLastGCD(byID)
	-- @return boolean
	return (byID and self.ID == A.LastPlayerCastID) or (not byID and self:Info(true) == A.LastPlayerCastName)
end 

function A:IsSpellLastCastOrGCD(byID)
	-- @return boolean
	return self:IsSpellLastGCD(byID) or self:IsSpellInCasting()
end 

function A:IsSpellInFlight(useName, noCache)
	-- @return boolean
	-- noCache will retrieve spellName as its currently appear
	local spell = useName and self:Info(noCache) or self.ID 
	return UnitCooldown:IsSpellInFly("player", spell)
end 

function A:IsSpellInRange(unitID)
	-- @usage A:IsSpellInRange() or A.IsSpellInRange(spellID, unitID)
	-- @return boolean
	local ID, Name
	if type(self) == "table" then 
		ID = self.ID 
		Name = self:Info()
	else 
		ID = self 
		Name = A_GetSpellInfo(ID)
	end		
	return Name and (IsSpellInRange(ID, unitID) == 1 or (Pet:IsActive() and Pet:IsInRange(ID, unitID))) 
end 

function A:IsSpellInCasting()
	-- @return boolean 
	local castName, _, _, _, spellID = Unit("player"):IsCasting()
	return spellID and spellID == self.ID
end 

function A:IsSpellCurrent()
	-- @return boolean
	return IsCurrentSpell(self.ID)
end 

function A:CanSafetyCastHeal(unitID, offset)
	-- @return boolean 
	local castTime = self:GetSpellCastTime()
	return castTime and (castTime == 0 or castTime > Unit(unitID):TimeToDie() + A_GetCurrentGCD() + (offset or A_GetGCD())) or false 
end 

-------------------------------------------------------------------------------
-- Talent 
-------------------------------------------------------------------------------
function A:IsTalentLearned()
	-- @usage A:IsTalentLearned() or A.IsTalentLearned(spellID)
	-- @return boolean about selected or not (talent or pvptalent)	
	local Name, ID
	if type(self) == "table" then 
		Name = self:Info()
		ID = self.ID
	else 
		Name = A_GetSpellInfo(self)
		ID = self
	end	

	local lowerName = strlowerCache[Name]
	
	-- PvE --
	-- Check by spellID
	local tMap 		= TalentMap[ID]
	-- Fallback to check by spellName 
	--- TWW+ may have idential spells such as Shadow Crash for SPriest (205385, 457042)
	--- Both will be true if we will check my spellName which may apply issues to determine correct one
	--if tMap == 0 then 
	--	tMap		= TalentMap[lowerName]
	--end 
	
	-- PvP --
	-- Check by spellID
	local pvptMap 	= PvpTalentMap[ID]
	-- Fallback to check by spellName 
	if not pvptMap then 
		pvptMap		= PvpTalentMap[lowerName]
	end 
	
	return (tMap and tMap > 0) or (A.IsInPvP and (not A.IsInDuel or A.IsInWarMode) and pvptMap) or (BuildToC < 90000 and Azerite:IsLearnedByConflictandStrife(Name))
end

function A:GetTalentTraits()
	-- @usage A:GetTalentTraits() or A.GetTalentTraits(spellID)
	-- @return number of selected traits, 0 if none 
	local Name, ID
	if type(self) == "table" then 
		Name = self:Info()
		ID = self.ID
	else 
		Name = A_GetSpellInfo(self)
		ID = self
	end	

	local lowerName = strlowerCache[Name]
	
	-- PvE --
	-- Check by spellID
	local tMap 		= TalentMap[ID]
	-- Fallback to check by spellName 
	--- TWW+ may have idential spells such as Shadow Crash for SPriest (205385, 457042)
	--- Both will be true if we will check my spellName which may apply issues to determine correct one
	--if tMap == 0 then 
	--	tMap		= TalentMap[lowerName]
	--end 
	
	-- PvP --
	-- Check by spellID
	local pvptMap 	= PvpTalentMap[ID]
	-- Fallback to check by spellName 
	if not pvptMap then 
		pvptMap		= PvpTalentMap[lowerName]
	end 

	return tMap	or (A.IsInPvP and (not A.IsInDuel or A.IsInWarMode) and PvpTalentMap and 1) or 0
end

-- Remap to keep old code working for it 
-- TODO: Remove in the future
A.IsSpellLearned = A.IsTalentLearned

-------------------------------------------------------------------------------
-- Racial (template)
-------------------------------------------------------------------------------	 
local Racial 												= {
	GetRaceBySpellName 										= {
		-- Darkflight
		[Spell:CreateFromSpellID(68992):GetSpellName()] 	= "Worgen",
		-- SpatialRift
		[Spell:CreateFromSpellID(256948):GetSpellName()] 	= "VoidElf", 				-- NO API 
		-- Shadowmeld
		[Spell:CreateFromSpellID(58984):GetSpellName()] 	= "NightElf",
		-- LightsJudgment
		[Spell:CreateFromSpellID(255647):GetSpellName()] 	= "LightforgedDraenei",
		-- Haymaker
		[Spell:CreateFromSpellID(287712):GetSpellName()] 	= "KulTiran",
		-- EveryManforHimself
		[Spell:CreateFromSpellID(59752):GetSpellName()] 	= "Human", 					-- ThinHuman (? wut)
		-- EscapeArtist
		[Spell:CreateFromSpellID(20589):GetSpellName()] 	= "Gnome",
		-- Stoneform
		[Spell:CreateFromSpellID(20594):GetSpellName()] 	= "Dwarf",
		-- GiftoftheNaaru
		[Spell:CreateFromSpellID(121093):GetSpellName()] 	= "Draenei",
		-- Fireblood
		[Spell:CreateFromSpellID(265221):GetSpellName()] 	= "DarkIronDwarf", 
		-- QuakingPalm
		[Spell:CreateFromSpellID(107079):GetSpellName()] 	= "Pandaren",
		-- Regeneratin
		[Spell:CreateFromSpellID(291944):GetSpellName()] 	= "ZandalariTroll",
		-- WilloftheForsaken
		[Spell:CreateFromSpellID(7744):GetSpellName()] 		= "Scourge", 				-- (this is confirmed) Undead 
		-- Berserking
		[Spell:CreateFromSpellID(26297):GetSpellName()] 	= "Troll",
		-- WarStomp
		[Spell:CreateFromSpellID(20549):GetSpellName()] 	= "Tauren",
		-- BloodFury
		[Spell:CreateFromSpellID(33697):GetSpellName()] 	= "Orc",
		-- ArcanePulse
		[Spell:CreateFromSpellID(260364):GetSpellName()] 	= "Nightborne",
		-- AncestralCall
		[Spell:CreateFromSpellID(274738):GetSpellName()] 	= "MagharOrc",
		-- BullRush
		[Spell:CreateFromSpellID(255654):GetSpellName()] 	= "HighmountainTauren",
		-- ArcaneTorrent
		[Spell:CreateFromSpellID(28730):GetSpellName()] 	= "BloodElf",	
		-- RocketJump
		[Spell:CreateFromSpellID(69070):GetSpellName()] 	= "Goblin",					-- NO API - Should we add RocketBarrage (?) or it's crap damaged spell	
		-- RocketBarrage
		-- NO API
	},
	Temp													= {
		TotalAndMagic 										= {"TotalImun", "DamageMagicImun"},
		TotalAndPhysAndCC									= {"TotalImun", "DamagePhysImun", "CCTotalImun"},
		TotalAndPhysAndCCAndStun							= {"TotalImun", "DamagePhysImun", "CCTotalImun", "StunImun"},
	},
	-- Functions	
	CanUse 													= function(this, self, unitID)
		-- @return boolean 
		A.PlayerRace = this.GetRaceBySpellName[self:Info()]
		
		-- Damage  
		if A.PlayerRace == "LightforgedDraenei" then 
			return 	LoC:Get("SCHOOL_INTERRUPT", "HOLY") == 0 and 
					LoC:IsMissed("SILENCE") and 
					(
						(
							unitID and 	
							Unit(unitID):IsEnemy() and 
							Unit(unitID):GetRange() <= 5  and 
							self:AbsentImun(unitID, this.Temp.TotalAndMagic) 
						) or 						
						MultiUnits:GetByRange(5, 1) >= 1						
					) and 
					(
						not A.IsInPvP or 
						not EnemyTeam("HEALER"):IsBreakAble(5)
					)	
		end 
		
		if A.PlayerRace == "Nightborne" then
			return	LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and 
					LoC:IsMissed("SILENCE") and		
					(
						(
							unitID and 	
							Unit(unitID):IsEnemy() and 
							Unit(unitID):GetRange() <= 5 and 
							self:AbsentImun(unitID, this.Temp.TotalAndMagic)
						) or 
						(
							(
								not unitID or 
								not Unit(unitID):IsEnemy() 
							) and 
							MultiUnits:GetByRange(5, 3) >= 3
						)
					) and 
					(
						not A.IsInPvP or 
						not EnemyTeam("HEALER"):IsBreakAble(5)
					)	
		end 
		
		-- Purge 
		if A.PlayerRace == "BloodElf" then 
			return 	LoC:Get("SCHOOL_INTERRUPT", "ARCANE") == 0 and 
					LoC:IsMissed("SILENCE") 
		end 
		
		-- Healing 
		if A.PlayerRace == "Draenei" then 
			if not unitID or Unit(unitID):IsEnemy() then 
				unitID = "player" 
			end 
			
			return  LoC:Get("SCHOOL_INTERRUPT", "HOLY") == 0 and 
					LoC:IsMissed("SILENCE") and 
					self:AbsentImun(unitID)
		end 
		
		if A.PlayerRace == "ZandalariTroll" then 
			return 	LoC:Get("SCHOOL_INTERRUPT", "NATURE") == 0 and 
					LoC:IsMissed("SILENCE") and 
					Unit("player"):GetStayTime() > 0 
		end 
		
		-- Iterrupts 
		if A.PlayerRace == "Pandaren" then 
			return 	unitID and 		
					Unit(unitID):IsControlAble("incapacitate") and 
					self:AbsentImun(unitID, this.Temp.TotalAndPhysAndCC, true)
		end 
		
		if A.PlayerRace == "KulTiran" then 
			return 	unitID and 
					Unit(unitID):IsControlAble("stun") and 
					self:AbsentImun(unitID, this.Temp.TotalAndPhysAndCC, true)
		end 
		
		if A.PlayerRace == "Tauren" then 
			return 	Player:IsStaying() and 
					(
						(
							unitID and 	
							Unit(unitID):IsEnemy() and 
							Unit(unitID):GetRange() <= 8 and 					
							Unit(unitID):IsControlAble("stun") and 
							self:AbsentImun(unitID, this.Temp.TotalAndPhysAndCCAndStun, true)
						) or 
						(
							(
								not unitID or 
								not Unit(unitID):IsEnemy() 
							) and 
							MultiUnits:GetByRange(8, 1) >= 1
						)
					)	
		end 
		
		if A.PlayerRace == "HighmountainTauren" then 
			return	unitID and 
					Unit(unitID):GetRange() <= 6 and 
					self:AbsentImun(unitID, this.Temp.TotalAndPhysAndCCAndStun, true)
		end 
		
		-- [NO LOGIC - ALWAYS TRUE] 
		return true 		 			
	end,
	CanAuto													= function(this, self, unitID)
		-- Loss Of Control 
		-- "Gnome", "Scourge", "Dwarf", "Human"
		local LOC = LoC.GetExtra[A.PlayerRace]
		if LOC then 
			if LoC:IsValid(LOC.Applied, LOC.Missed) then 
				return true 
			else 
				return false 
			end 
		end 	
	
		-- Damaging   
		if A.PlayerRace == "LightforgedDraenei" then 
			return true 
		end 
		
		if A.PlayerRace == "Nightborne" then 
			return unitID and Unit(unitID):GetCurrentSpeed() >= 100 
		end 	
		
		-- Purge 
		if A.PlayerRace == "BloodElf" then
			return  (
						A.IsInPvP and 
						FriendlyTeam():ArcaneTorrentMindControl()
					) or 				 
					(
						unitID and 
						(not Unit(unitID):IsEnemy() or Unit(unitID):InGroup()) and 
						Unit(unitID):GetRange() <= 8 and 
						AuraIsValid(unitID, "UsePurge", "PurgeFriendly")					
					) or 
					(
						unitID and 
						Unit(unitID):IsEnemy() and 
						Unit(unitID):GetRange() <= 8 and 
						AuraIsValid(unitID, "UsePurge", "PurgeHigh")
					)
		end 
		
		-- Healing 
		if A.PlayerRace == "Draenei" then 
			if Unit(unitID):IsPlayerOrPet() then 
				local PO = GetToggle(8, "PredictOptions")
				-- PO[1] incHeal
				-- PO[2] incDMG
				-- PO[3] threat -- not usable in prediction
				-- PO[4] HoTs
				-- PO[5] absorbPossitive
				-- PO[6] absorbNegative
				local incHeal, incDMG, HoTs, absorbPossitive, absorbNegative = 0, 0, 0, 0, 0
				if PO[1] then 
					incHeal = Unit(unitID):GetIncomingHeals()
				end 
				
				if PO[2] then 
					incDMG = Unit(unitID):GetDMG() * 5
				end 
				
				if PO[4] then -- 4 here!
					HoTs = Unit(unitID):GetHEAL() * 5
				end 
				
				if PO[5] then 
					absorbPossitive = Unit(unitID):GetAbsorb()
					-- Better don't touch it, not tested anyway
					if absorbPossitive >= Unit(unitID):HealthDeficit() then 
						absorbPossitive = 0
					end 
				end 
				
				if PO[6] then 
					absorbNegative = Unit(unitID):GetTotalHealAbsorbs()
				end 
				
				return Unit(unitID):HealthDeficit() >= Unit("player"):HealthMax() * 0.2 + incHeal - incDMG + HoTs - absorbPossitive
			end 
			
			return false 
		end 

		if A.PlayerRace == "ZandalariTroll" then 
			return  Unit("player"):GetDMG() == 0 or 
					(
						A.PlayerClass == "PALADIN" and 
						Unit("player"):HasBuffs(642, true) >= (100 - Unit("player"):HealthPercent()) * 6 / 100
					) or 
					(
						A.PlayerClass == "HUNTER" and 
						Unit("player"):HasBuffs(186265, true) >= (100 - Unit("player"):HealthPercent()) * 6 / 100
					)			
		end 
				
		-- Iterrupts 
		if A.PlayerRace == "Pandaren" then 
			return Unit(unitID):IsCastingRemains() > A_GetCurrentGCD() + 0.1		  
		end 

		if A.PlayerRace == "KulTiran" then  	
			return Unit(unitID):IsCastingRemains() > A_GetCurrentGCD() + 1.1			  
		end 	
		
		if A.PlayerRace == "Tauren" then 
			return  (
						unitID and 					
						Unit(unitID):IsCastingRemains() > A_GetCurrentGCD() + 0.7
					) or 
					(
						(
							not unitID or 
							not Unit(unitID):IsEnemy() 
						) and 
						MultiUnits:GetByRangeCasting(8, 1) >= 1
					)			  
		end 		

		-- Custom GCD
		if A.PlayerRace == "HighmountainTauren" then 
			return Unit(unitID):IsCastingRemains() > A_GetCurrentGCD() + 0.3			  
		end 	
	
		-- Control Avoid 
		if A.PlayerRace == "NightElf" then 
			-- Check Freezing Trap 
			if 	UnitCooldown:GetCooldown("arena", SPELLID_FREEZING_TRAP) > UnitCooldown:GetMaxDuration("arena", SPELLID_FREEZING_TRAP) - 2 and 
				UnitCooldown:IsSpellInFly("arena", SPELLID_FREEZING_TRAP) and 
				Unit("player"):GetDR("incapacitate") > 0 
			then 
				local Caster = UnitCooldown:GetUnitID("arena", SPELLID_FREEZING_TRAP)
				if Caster and not Player:IsStealthed() and Unit(Caster):GetRange() <= 40 and (Unit("player"):GetDMG() == 0 or not Unit("player"):IsFocused("DAMAGER")) then 
					return true 
				end 
			end 
				
			-- Check Storm Bolt 
			if 	UnitCooldown:GetCooldown("arena", SPELLID_STORM_BOLT) > UnitCooldown:GetMaxDuration("arena", SPELLID_STORM_BOLT) - 2 and 
				UnitCooldown:IsSpellInFly("arena", SPELLID_STORM_BOLT) and 
				Unit("player"):GetDR("stun") > 25 -- don't waste on short durations by diminishing
			then 
				local Caster = UnitCooldown:GetUnitID("arena", SPELLID_STORM_BOLT)
				if Caster and not Player:IsStealthed() and Unit(Caster):GetRange() <= 20 then 
					return true 
				end 
			end 
			
			return false 
		end 			
		
		-- Sprint
		if A.PlayerRace == "Worgen" then  
			return Unit(unitID):IsMovingOut()
		end 
		
		-- Bursting 
		if ( A.PlayerRace == "DarkIronDwarf" or A.PlayerRace == "Troll" or A.PlayerRace == "Orc" or A.PlayerRace == "MagharOrc" ) then 
			return BurstIsON(unitID)
		end 	
				
		-- [NO LOGIC - ALWAYS TRUE] 
		return true 
	end, 
}

function A:IsRacialReady(unitID, skipRange, skipLua, skipShouldStop)
	-- @return boolean 
	-- For [3-4, 6-8]
	return self:RacialIsON() and self:IsReady(unitID, isSpellRangeException[self.ID] or skipRange, skipLua, skipShouldStop) and Racial:CanUse(self, unitID) 
end 

function A:IsRacialReadyP(unitID, skipRange, skipLua, skipShouldStop)
	-- @return boolean 
	-- For [1-2, 5]
	return self:RacialIsON() and self:IsReadyP(unitID, isSpellRangeException[self.ID] or skipRange, skipLua, skipShouldStop) and Racial:CanUse(self, unitID) 
end 

function A:AutoRacial(unitID, skipRange, skipLua, skipShouldStop)
	-- @return boolean 
	return self:IsRacialReady(unitID, skipRange, skipLua, skipShouldStop) and Racial:CanAuto(self, unitID)
end 

-------------------------------------------------------------------------------
-- Item (provided by TMW)
-------------------------------------------------------------------------------	  
function A.GetItemDescription(self)
	-- @usage A:GetItemDescription() or A.GetItemDescription(18)
	-- @return table 
	-- Note: It returns correct value only if item holds spell 
	local _, spellID = GetItemSpell(type(self) == "table" and self.ID or self)
	if spellID then 
		return A_GetSpellDescription(spellID)
	end 
	
	return nullDescription -- can not be used for 'next', 'unpack', 'pairs', 'ipairs'
end
A.GetItemDescription = A.MakeFunctionCachedDynamic(A.GetItemDescription)

local itemspellcache = setmetatable({}, { __index = function(t, v)
    local a = { GetItemSpell(v) }
	if #a > 0 then 
		t[v] = a
	end 
    return a
end })
function A:GetItemSpell()
	-- @return string, number or nil 
	-- Returns: spellName, spellID or nil 
	return unpack(itemspellcache[self.ID])
end

function A:GetItemCooldown()
	-- @return number

	-- Potion Sickness
	-- Unable to consume potions until you rest out of combat for a short duration.
	if self.Type == "Potion" and Unit("player"):HasBuffs(53787) > 0 then 
		return huge
	end 	
	
	local start, duration, enable = self.Item:GetCooldown()
	return (enable == 1 or enable == true) and duration and ((duration == 0 or A_OnGCD(duration)) and 0 or duration - (TMW.time - start)) or huge
end 

function A:GetItemCategory()
	-- @return string 
	-- Note: Only for Type "TrinketBySlot"
	return itemCategory[self.ID]
end 

function A:IsItemCurrent()
	-- @return boolean
	return IsCurrentItem((self:Info()))
end 

-- Next works by TMW components
-- A:IsInRange(unitID) (in Shared)
-- A:GetCount() (in Shared)
-- A:GetEquipped() 
-- A:GetCooldown() (in Shared)
-- A:GetCooldownDuration() 
-- A:GetCooldownDurationNoGCD() 
-- A:GetID() 
-- A:GetName() 
-- A:HasUseEffect() 

-------------------------------------------------------------------------------
-- Item|Spell (provided by Lib LegendaryCrafting)
-------------------------------------------------------------------------------	
-- Item Object 
function A:IsItemLegendaryCrafting()
	-- @return boolean 
	return LegendaryCrafting:IsEquipped(self.ID)
end

function A:GetLegendaryCraftingItem()
	-- @return table or nil 
	-- Look description of the returned methods in Player.lua
	return Player:GetLegendaryCraftingItem(self.ID)
end 

-- Spell Object
function A:HasLegendaryCraftingPower()
	-- @return boolean 
	-- Look description of the returned methods in Player.lua
	-- Note: Object must be a spell !
	return Player:HasLegendaryCraftingPower((self:Info())) -- Shadowlands API written on spellName
end 

-------------------------------------------------------------------------------
-- Determine
-------------------------------------------------------------------------------
function A.DetermineIsSBAObject(...)
	-- @return object or nil 
	for i = 1, select("#", ...) do 
		local object = select(i, ...)
		if object:IsSBA() then 
			return object
		end 
	end 
end 

function A.DetermineHealObject(unitID, skipRange, skipLua, skipShouldStop, skipUsable, ...)
	-- @return object or nil 
	-- Note: :PredictHeal(unitID) must be only ! Use 'self' inside to determine by that which spell is it 
	for i = 1, select("#", ...) do 
		local object = select(i, ...)
		if object:IsReady(unitID, skipRange, skipLua, skipShouldStop, skipUsable) and object:PredictHeal(unitID) then 
			return object
		end 
	end 
end 

function A.DetermineUsableObject(unitID, skipRange, skipLua, skipShouldStop, skipUsable, ...)
	-- @return object or nil 
	for i = 1, select("#", ...) do 
		local object = select(i, ...)
		if object:IsReady(unitID, skipRange, skipLua, skipShouldStop, skipUsable) then 
			return object
		end 
	end 
end 

function A.DetermineIsCurrentObject(...)
	-- @return object or nil 
	for i = 1, select("#", ...) do 
		local object = select(i, ...)
		if object:IsCurrent() then 
			return object
		end 
	end 
end 

function A.DetermineCountGCDs(...)
	-- @return number, count of required summary GCD times to use all in vararg
	local count = 0
	for i = 1, select("#", ...) do 
		local object = select(i, ...)		
		if (not object.isStance or A.PlayerClass ~= "WARRIOR") and object:IsRequiredGCD() and not object:IsBlocked() and not object:IsBlockedBySpellLevel() and (not object.isTalent or object:IsTalentLearned()) and object:GetCooldown() <= A_GetPing() + CACHE_DEFAULT_TIMER + A_GetCurrentGCD() then 
			count = count + 1
		end 
	end 	
	return count
end 

function A.DeterminePowerCost(...)
	-- @return number (required power to use all varargs actions)
	local total = 0
	for i = 1, select("#", ...) do 
		local object = select(i, ...)
		if object and object:IsReadyToUse(nil, true, true) then 
			total = total + object:GetSpellPowerCostCache()
		end 
	end 
	return total
end 

function A.DetermineCooldown(...)
	-- @return number (required summary cooldown time to use all varargs actions)
	local total = 0
	for i = 1, select("#", ...) do 
		local object = select(i, ...)
		if object then 
			total = total + object:GetCooldown()
		end 
	end 
	return total
end 

function A.DetermineCooldownAVG(...)
	-- @return number (required AVG cooldown to use all varargs actions)
	local total, count = 0, 0
	for i = 1, select("#", ...) do 
		local object = select(i, ...)
		if object then 
			total = total + object:GetCooldown()
			count = count + 1
		end 
	end 
	if count > 0 then 
		return total / count
	else 
		return 0 
	end 
end 

-------------------------------------------------------------------------------
-- Shared
-------------------------------------------------------------------------------	  
function A:IsSBA()
	return GetNextCastSpell() == self.ID
end

function A:IsExists(replacementByPass)   
	-- @return boolean
	if self.Type == "Spell" then 
		-- DON'T USE HERE A.GetSpellInfo COZ IT'S CACHE WHICH WILL WORK WRONG DUE RACE CHANGES
		local spellName, _, _, _, _, _, spellID = GetSpellInfo((self:Info()) or "") 
		if type(spellName) == "table" then 
			spellID = spellName.spellID
			spellName = spellName.name
		end 		
		-- spellID will be nil in case of if it's not a player's spell 
		-- spellName will not be equal to self:Info() if it's replacement spell like "Chi-Torpedo" and "Roll"
		return spellName and ((not replacementByPass or spellName == self:Info()) and (type(spellID) == "number" and (IsPlayerSpell(spellID) or (Pet:IsActive() and Pet:IsSpellKnown(spellID)) or FindSpellBookSlotBySpellID(spellID, false))) or FindSpellBookSlotForSpell(spellName)) and true -- TODO: Re-do v2
	end 
	
	if self.Type == "SwapEquip" then 
		return self.Equip1() or self.Equip2()
	end 
	
	return self:GetEquipped() or self:GetCount() > 0	
end

function A:IsUsable(extraCD, skipUsable)
	-- @return boolean 
	-- skipUsable can be number to check specified power
	
	if self.Type == "Spell" then 
		-- C_Spell.IsSpellUsable returns falsely true through spellID if player hasn't learned the spell 30/08/2024 TWW
		return (skipUsable or (type(skipUsable) == "number" and Unit("player"):Power() >= skipUsable) or IsUsableSpell(self.ID)) and self:GetCooldown() <= A_GetPing() + CACHE_DEFAULT_TIMER + (self:IsRequiredGCD() and A_GetCurrentGCD() or 0) + (extraCD or 0) and (IsSpellKnownOrOverridesKnown(self.ID) or (Pet:IsActive() and Pet:IsSpellKnown(self.ID)))
	end 
	
	return not isItemUseException[self.ID] and (skipUsable == true or (type(skipUsable) == "number" and Unit("player"):Power() >= skipUsable) or IsUsableItem((self:Info()))) and self:GetItemCooldown() <= A_GetPing() + CACHE_DEFAULT_TIMER + (self:IsRequiredGCD() and A_GetCurrentGCD() or 0) + (extraCD or 0)
end

function A:IsHarmful()
	-- @return boolean 
	if self.Type == "Spell" then 
		return IsHarmfulSpell(self.ID) or IsAttackSpell(self.ID)
	end 
	
	return IsHarmfulItem((self:Info()))
end 

function A:IsHelpful()
	-- @return boolean 
	if self.Type == "Spell" then 
		return IsHelpfulSpell(self.ID)
	end 
	
	return IsHelpfulItem((self:Info()))
end 

function A:IsInRange(unitID)
	-- @return boolean
	if self.skipRange then 
		return true 
	end 
	
	local unitID = unitID or "target"
	
	if self.Type == "SwapEquip" or UnitIsUnit("player", unitID) then 
		return true 
	end 
	
	if self.Type == "Spell" then 
		return self:IsSpellInRange(unitID)
	end 
	
	return self.Item:IsInRange(unitID)
end 

function A:IsCurrent()
	-- @return boolean
	-- Note: Only Spell, Item, Trinket 
	return (self.Type == "Spell" and self:IsSpellCurrent()) or ((self.Type == "Item" or self.Type == "Trinket") and self:IsItemCurrent()) or false 
end 

function A:HasRange()
	-- @return boolean 
	if self.Type == "Spell" then 
		return not isSpellRangeException[self.ID] and SpellHasRange(self.ID)
	end 
	
	if self.Type == "SwapEquip" then
		return false 
	end 
	
	return not isItemRangeException[self:GetID()] and ItemHasRange((self:Info()))
end 

function A:GetCooldown()
	-- @return number
	if self.Type == "SwapEquip" then 
		return (Player:IsSwapLocked() and huge) or 0
	end 
	
	if self.Type == "Spell" then 
		if self.isStance then 
			local start, duration = GetShapeshiftFormCooldown(self.isStance)
			if start and start ~= 0 then
				return (duration == 0 and 0) or (duration - (TMW.time - start))
			end
			
			return 0
		else 
			return CooldownDuration(self.ID)
		end 
	end 
	
	return self:GetItemCooldown()
end 

function A:GetCount()
	-- @return number
	if self.Type == "Spell" then 
		return GetSpellCount(self.ID) or 0
	end 
	
	return self.Item:GetCount() or 0
end 

function A:AbsentImun(unitID, imunBuffs, skipKarma)
	-- @return boolean 
	-- Note: Checks for friendly / enemy Imun auras and compares it with remain duration 
	if not unitID or UnitIsUnit(unitID, "player") then 
		return true 
	else 
		local isTable = type(self) == "table"
		local isEnemy = Unit(unitID):IsEnemy()
		
		-- Super trick for Queue System, it will save in cache imunBuffs on first entire call by APL and Queue will be allowed to handle cache to compare Imun 
		if isTable and imunBuffs then 
			self.AbsentImunQueueCache = imunBuffs
			self.AbsentImunQueueCache2 = skipKarma
		end 	
		
		local MinDur = ((not isTable or self.Type ~= "Spell") and 0) or self:GetSpellCastTime()
		if MinDur > 0 then 
			MinDur = MinDur + (self:IsRequiredGCD() and A_GetCurrentGCD() or 0)
		end
		
		if Unit(unitID):DeBuffCyclone() > MinDur or (isEnemy and (not A.IsInitialized or GetToggle(1, "StopAtBreakAble")) and Unit(unitID):HasDeBuffs(IsBreakAbleDeBuff) > MinDur) then 
			return false 
			--[[
			local remainTime, auraData
			for i = 1, huge do			
				auraData = UnitAura(unitID, i, "HARMFUL")
				if not auraData then
					break 
				elseif IsCycloneDeBuff[auraData.name] or (isStopAtBreakAble and isEnemy and IsBreakAbleDeBuff[auraData.name]) then 
					remainTime = auraData.expirationTime == 0 and huge or auraData.expirationTime - TMW.time
					if remainTime > MinDur then 
						return false 
					end 
				end 
			end	]]
		end 		
		
		if isEnemy and imunBuffs and A.IsInPvP and Unit(unitID):IsPlayer() then  
			-- Light and faster check Fury Warriors
			--if type(imunBuffs) == "table" then 				
			--	for i = 1, #imunBuffs do 
			--		if imunBuffs[i] == "Freedom" and Unit(unitID):HasSpec(CONST.WARRIOR_FURY) then 
			--			return false 
			--		end 
			--	end 
			--elseif imunBuffs == "Freedom" and Unit(unitID):HasSpec(CONST.WARRIOR_FURY) then
			--	return false  								
			--end 
			
			-- Check remain things
			 if Unit(unitID):HasBuffs(imunBuffs) > MinDur then 
				return false 
			end 
		end 
		
		if not skipKarma and isEnemy and not Unit(unitID):WithOutKarmed() then 
			return false 
		end 

		return true
	end 
end 

function A:IsBlockedByAny()
	-- @return boolean
	return 	   self:IsBlocked() 
			or self:IsBlockedByQueue() 
			or (self.Type == "Spell" and (self:IsBlockedBySpellLevel() or (self.isTalent and not self:IsTalentLearned()) or (self.isCovenant and not self:IsCovenantAvailable()))) 
			or (self.Type ~= "Spell" and self.Type ~= "SwapEquip" and self:GetCount() == 0 and not self:GetEquipped())
end 

function A:IsSuspended(delay, reset)
	-- @return boolean
	-- Returns true if action should be delayed before use, reset argument is a internal refresh cycle of expiration future time
	if (self.expirationSuspend or 0) + reset <= TMW.time then
		self.expirationSuspend = TMW.time + delay
	end 

	return self.expirationSuspend > TMW.time
end

function A:IsCastable(unitID, skipRange, skipShouldStop, isMsg, skipUsable)
	-- @return boolean
	-- Checks toggle, cooldown and range 
	
	if isMsg or ((skipShouldStop or not self.ShouldStop()) and not self:ShouldStopByGCD()) then 
		if 	self.Type == "Spell" and 
			not self:IsBlockedBySpellLevel() and 	
			( not self.isTalent or self:IsTalentLearned() ) and 
			( not self.isCovenant or self:IsCovenantAvailable() ) and 
		--	( not self.isReplacement or self:IsExists(true) ) and 			
			( skipRange or not unitID or not self:HasRange() or self:IsInRange(unitID) ) and 
			self:IsUsable(nil, skipUsable) and 
			-- Patch 8.2
			-- 1518 is The Eternal Palace - The Queen's Court 
			-- 301244 is Repeat Performance (DeBuff)
			( A.ZoneID ~= 1518 or Unit("player"):HasDeBuffs(301244) == 0 or (A.LastPlayerCastName ~= self:Info() and Player:CastRemains(self.ID) == 0) ) and 
			-- Patch 8.3
			-- 1582 is "Ny'alotha - Ny'alotha" (Ny'alotha, the Waking City)
			-- 316065 is Corrupted Existence (DeBuff)
			( A.ZoneID ~= 1582 or not unitID or Unit(unitID):IsEnemy() or Unit(unitID):HasDeBuffs(316065) == 0 or Unit(unitID):HealthPercent() <= 70 ) and 
			-- Mythic 7+ 
			-- Quaking Affix 
			( not InstanceInfo.KeyStone or InstanceInfo.KeyStone < 7 or InstanceInfo.GroupSize > 5 or Unit("player"):HasDeBuffs(240447, true) == 0 or self:GetSpellCastTime() < Unit("player"):HasDeBuffs(240447, true) - A_GetPing() - 0.1 )			
		then 
			return true 				
		end 
		
		if 	self.Type == "Trinket" then 
			local ID = self.ID		
			if 	ID ~= nil and 
				-- This also checks equipment (in idea because slot return ID which we compare)
				( A.Trinket1.ID == ID and GetToggle(1, "Trinkets")[1] or A.Trinket2.ID == ID and GetToggle(1, "Trinkets")[2] ) and 
				self:IsUsable(nil, skipUsable) and 
				( skipRange or not unitID or not self:HasRange() or self:IsInRange(unitID) )
			then 
				return true 
			end 
		end 
		
		if 	self.Type == "Potion" and 
			A.Zone ~= "arena" and
			(
				A.Zone ~= "pvp" or 
				not InstanceInfo.isRated
			) and
			GetToggle(1, "Potion") and 
			self:GetCount() > 0 and 
			self:GetItemCooldown() == 0 
		then
			return true 
		end 
		
		if  self.Type == "Item" and 
			A.Zone ~= "arena" and
			(
				A.Zone ~= "pvp" or 
				not InstanceInfo.isRated
			) and
			( self:GetCount() > 0 or self:GetEquipped() ) and 
			self:GetItemCooldown() == 0 and 
			( skipRange or not unitID or not self:HasRange() or self:IsInRange(unitID) )
		then
			return true 
		end 
	end 
	
	return false 
end

function A:IsReady(unitID, skipRange, skipLua, skipShouldStop, skipUsable)
	-- @return boolean
	-- For [3-4, 6-8]
    return 	not self:IsBlocked() and 
			not self:IsBlockedByQueue() and 
			self:IsCastable(unitID, skipRange, skipShouldStop, nil, skipUsable) and 
			( skipLua or self:RunLua(unitID) )
end 

function A:IsReadyP(unitID, skipRange, skipLua, skipShouldStop, skipUsable)
	-- @return boolean
	-- For [1-2, 5]
    return 	self:IsCastable(unitID, skipRange, skipShouldStop, nil, skipUsable) and (skipLua or self:RunLua(unitID))
end 

function A:IsReadyM(unitID, skipRange, skipUsable)
	-- @return boolean
	-- For MSG System or bypass ShouldStop with GCD checks and blocked conditions 
	if unitID == "" then 
		unitID = nil 
	end 
    return 	self:IsCastable(unitID, skipRange, nil, true, skipUsable) and self:RunLua(unitID)
end 

function A:IsReadyByPassCastGCD(unitID, skipRange, skipLua, skipUsable)
	-- @return boolean
	-- For [3-4, 6-8]
    return 	not self:IsBlocked() and 
			not self:IsBlockedByQueue() and 
			self:IsCastable(unitID, skipRange, nil, true, skipUsable) and 
			( skipLua or self:RunLua(unitID) )
end 

function A:IsReadyByPassCastGCDP(unitID, skipRange, skipLua, skipUsable)
	-- @return boolean
	-- For [1-2, 5]
    return 	self:IsCastable(unitID, skipRange, nil, true, skipUsable) and (skipLua or self:RunLua(unitID))
end 

function A:IsReadyToUse(unitID, skipShouldStop, skipUsable)
	-- @return boolean 
	-- Note: unitID is nil here always 
	return 	not self:IsBlocked() and 
			not self:IsBlockedByQueue() and 
			self:IsCastable(nil, true, skipShouldStop, nil, skipUsable)
end 

-------------------------------------------------------------------------------
-- Misc
-------------------------------------------------------------------------------
-- KeyName
local function tableSearch(self, array)
	if type(array) ~= "table" then return end
	for k, v in pairs(array) do 
		if type(v) == "table" and self == v then 
			return k 
		end 
	end 
end 

function A:GetKeyName()
	-- Returns @nil or @string as key name in the table
	return tableSearch(self, A[A.PlayerSpec]) or tableSearch(self, A)
end 

-- Spell  
local spellinfocache = setmetatable({}, { __index = function(t, v)
    local a
	if C_Spell and C_Spell.GetSpellInfo then 
		local s = GetSpellInfo(v)
		if s then 
			a = { s.name, s.rank, s.iconID, s.castTime, s.minRange, s.maxRange, s.spellID, s.originalIconID }
		else 
			a = { }
		end 
	else 
		a = { GetSpellInfo(v) }
	end 
	
    t[v] = a
    return a
end })

function A:GetSpellInfo(noCache)
	local ID = self
	if type(self) == "table" then 
		ID = self.ID 
	end
	
	if ID then 
		if noCache then 
			if C_Spell and C_Spell.GetSpellInfo then 
				local s = GetSpellInfo(ID)
				if s then 
					return s.name, s.rank, s.iconID, s.castTime, s.minRange, s.maxRange, s.spellID, s.originalIconID
				end 
			else 
				return GetSpellInfo(ID)
			end 
		else 
			return unpack(spellinfocache[ID])
		end 
	end 
end

function A:GetSpellLink()
	local ID = self
	if type(self) == "table" then 
		ID = self.ID 
	end
    return GetSpellLink(ID) or ""
end 

function A:GetSpellIcon()
	return select(3, self:GetSpellInfo())
end

function A:GetSpellTexture(custom)
	if self.SubType == "HeartOfAzeroth" then 
		return "texture", HEARTOFAZEROTH
	end
    return "texture", GetSpellTexture(custom or self.ID)
end 

-- Spell Colored Texturre
function A:GetColoredSpellTexture(custom)
    return "state; texture", {Color = A.Data.C[self.Color] or self.Color, Alpha = 1, Texture = ""}, GetSpellTexture(custom or self.ID)
end 

-- SingleColor
function A:GetColorTexture()
    return "state", {Color = A.Data.C[self.Color] or self.Color, Alpha = 1, Texture = PathToGreenTGA}
end 

-- Item
local iteminfocache = setmetatable({}, { __index = function(t, v)	
    local a = { GetItemInfo(v) }
	if #a > 0 then 
		t[v] = a
	end 
    return a
end })

function A:GetItemInfo(custom)
	local ID	
	local isTable = not custom and type(self) == "table"
	if isTable then 
		ID = self.ID 
	else 
		ID = custom or self 
	end
	
	if ID then 
		if #iteminfocache[ID] > 1 then 
			return unpack(iteminfocache[ID]) 
		elseif isTable then 
			local spellName = self:GetItemSpell()			
			return spellName or self:GetKeyName() or ""
		end
	end 
end

function A:GetItemLink()
    return select(2, self:GetItemInfo()) or ""
end 

function A:GetItemIcon(custom)
	return select(10, self:GetItemInfo(custom)) or select(5, GetItemInfoInstant(custom or self.ID))
end

function A:GetItemTexture(custom)
	local texture
	if self.Type == "Trinket" then 
		if A.Trinket1.ID == self.ID then 
			texture = TRINKET1
		else 
			texture = TRINKET2
		end
	elseif self.Type == "Potion" then 
		texture = POTION
	else 
		texture = self:GetItemIcon(custom)
	end
	
    return "texture", texture
end 

-- Item Colored Texture
function A:GetColoredItemTexture(custom)
    return "state; texture", {Color = A.Data.C[self.Color] or self.Color, Alpha = 1, Texture = ""}, (custom and GetItemIcon(custom)) or self:GetItemIcon()
end 

-- Swap Colored Texture
function A:GetColoredSwapTexture(custom)
    return "state; texture", {Color = A.Data.C[self.Color] or self.Color, Alpha = 1, Texture = ""}, custom or self.ID
end 

-------------------------------------------------------------------------------
-- Cache Manager
-------------------------------------------------------------------------------
do 
	if BuildToC >= 100000 then 
		local function WipeCache()
			wipe(TMW.GetSpellTexture)
			
			wipe(spellbasecache)	
			wipe(spellinfocache)
			
			wipe(spellpowercache)
			wipe(descriptioncache)
			
			wipe(itemspellcache)
			wipe(iteminfocache)		
			
			-- Update Actions tab in UI if AutoHidden is enabled
			TMW:Fire("TMW_ACTION_SPELL_BOOK_CHANGED")
		end 

		-- Post-Init 
		TMW:RegisterSelfDestructingCallback("TMW_ACTION_IS_INITIALIZED", function()
			--Listener:Add("ACTION_EVENT_ACTIONS", "SPELLS_CHANGED", WipeCache) -- commented because it wipes cache in combat which we don't want to 
			Listener:Add("ACTION_EVENT_ACTIONS", "PLAYER_TALENT_UPDATE", WipeCache)
			Listener:Add("ACTION_EVENT_ACTIONS", "ACTIVE_TALENT_GROUP_CHANGED", WipeCache)
			TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", WipeCache)
			TMW:RegisterCallback("TMW_ACTION_MODE_CHANGED", WipeCache)
			return true -- Signal RegisterSelfDestructingCallback to unregister
		end)
	end 
end 

-------------------------------------------------------------------------------
-- UI: Create
-------------------------------------------------------------------------------
-- Receive information from server about items before start UI builder
local ItemIDs = {} 
hooksecurefunc(TMW, "SortOrderedTables", function()
	-- This function working only before RunSnippet
	if #ItemIDs > 0 then 
		for _, id in ipairs(ItemIDs) do 
			GetItemInfo(id)	
		end 
		wipe(ItemIDs)
	end
end)

-- Debug created actions 
local TableKeys = {}
TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", function()
	-- Debug for SetBlocker and SetQueue for shared internal table keys 	
	local err, specID
	for i = 1, GetNumSpecializationsForClassID(A.PlayerClassID) do 
		specID = GetSpecializationInfo(i)
		if A[specID] then 
			for key, action in pairs(A[specID]) do 
				if type(action) == "table" and action:IsActionTable() and not action.Hidden then 				
					if TableKeys[action:GetTableKeyIdentify()] then 
						err = (err or "Script found duplicate .TableKeyIdentify:\n") .. key .. " = " .. TableKeys[action:GetTableKeyIdentify()] .. ". Output: " .. action.TableKeyIdentify .. "\n"
					else 
						TableKeys[action:GetTableKeyIdentify()] = key 
					end 

					if action.Macro and #action.Macro > 255 then
						err = (err or "") .. key .. " macro exceeds 255 bytes (" .. #action.Macro .. " current bytes)\n"
					end
				end 
			end 
		end 
		wipe(TableKeys)
	end 	
	
	if err then 
		error(err)
	end 
end)

-- Create action with args 
function A.Create(args)
	--[[@usage: args (@table)
		Required: 
			Type (@string)					- Spell|SpellSingleColor|Item|ItemSingleColor|Potion|Trinket|TrinketBySlot|HeartOfAzeroth|SwapEquip|Script
			ID (@number) 					- spellID | itemID | textureID, textureID used only for SwapEquip|Script
			Color (@string) 				- only if Type is SpellSingleColor|ItemSingleColor but optionally supported by Spell|Item|SwapEquip|Script, hex or upper-case name of color in A.Data.C[Color]
			Equip1, Equip2 (@function) 		- only if Type is SwapEquip, used in A:IsExists() to determine between which equipments do swap
	 	Optional:			
			Desc (@string) 					- description used in A:GetTableKeyIdentify and in UI in the Actions tab in Desc ceil 
			Hidden (@boolean) 				- hides action from UI and skips it in MetaEngine
			HiddenUI (@boolean)				- hides action from UI only, if both Hidden and HiddenUI are set then Hidden will take over priority
			QueueForbidden (@boolean) 		- if true, user will not be able to set queue on it
			BlockForbidden (@boolean)		- if true, user will not be able to set blocker on it
			Texture (@number) 				- only if Type is Spell|Item|Potion|Trinket|HeartOfAzeroth|SwapEquip, sets texture from Spell|Item data base
			FixedTexture (@number or @file) - only if Type is Spell|Item|Potion|Trinket|SwapEquip, sets texture from texture data base
			MetaSlot (@number) 				- shows action in predetermined meta-slot when its queued
			CP (@number)					- combo points to check in A:SetQueue()
			isCP (@boolean) 				- A:SetQueue will check CP or at least one
		Optional-Relative:
			covenantID (@number) 			- [Shadowlans] A:IsReady, A:IsCastable and such will check A:IsCovenantAvailable(), requires Spell|SpellSingleColor	as Type		
			isRank (@number) 				- [Classics] will use specified rank of spell through additional frame, requires Spell|SpellSingleColor as Type			
			useMaxRank (@boolean or @table) - [Classics] will overwrite current ID by highest available rank and sets isRank, example of @table {1, 2, 4, 6, 7}, requires Spell|SpellSingleColor as Type
			useMinRank (@boolean or @table) - [Classics] will overwrite current ID by lowest available rank and sets isRank, example of @table {1, 2, 4, 6, 7}, requires Spell|SpellSingleColor as Type			
			isStance (@number) 				- uses GetShapeshiftFormCooldown instead of A:GetCooldown() for number of stance, requires Spell as Type
			isTalent (@boolean) 			- A:IsReady, A:IsCastable and such will check A:IsTalentLearned(), requires Spell|SpellSingleColor|HeartOfAzeroth as Type
			isReplacement (@boolean) 		- A:IsReady, A:IsCastable and such will check A:IsExists(true), requires Spell|SpellSingleColor|HeartOfAzeroth as Type
			skipRange (@boolean) 			- A:IsInRange will always return true, used on actions with indirect ranges (AoE), requires Spell|SpellSingleColor|Item|ItemSingleColor|Trinket|TrinketBySlot|HeartOfAzeroth as Type		
			... 							- any custom key-value will be inserted also 

			
		<|> MetaEngine <|>
		All settings below are processed during initialization. Actions are skipped if they have Hidden = true or if MetaEngine is not available.
		Each created action can be used in one of the following ways:
			1) Action:ExecuteScript() method:
				@required
					Type = "Script"
					Script (@string) wraps script in restricted env, can be used in-combat. Built-in variables:
						this1-this10 used as reference to active meta-button, 									this6 -- unavailable, 		this -- w/o number is reference to shared container
						this1click-this10click used as reference to click-button of the Active meta-button, 	this6click -- unavailable, 	thisclick -- is reference to click-button of the HealingEngine
						thisclick6-thisclick10 used as reference to click-button of the Passive meta-slot
				@optional
					Refs (@table) will SetFrameRef, allows you to reference added frames in Script. Example:
						Refs = {
							["name"] = frame,
						}
					Name (@string) name of script, used to replace return in :Info() method just for visual appearance in UI.
					
			2) Action:Show(), Action.Hide() methods:					
				@required
					IsAntiFake (@boolean) used to make action act as an active meta-button in associated slots, otherwise active meta-buttons on [1]-[2],[7]-[10] will not perform it.
				@optional
					Refs (@table) will SetFrameRef, allows you to reference added frames in Script. Example:
						Refs = {
							["name"] = frame,
						}
					Script (@string) wraps script in restricted env at the end of action wrapper, can be used in-combat. Built-in variables are same as in Type = "Script" (see above)
					Macro (@string) should be short as much as it possible, macro is limited up to 255 bytes where ~45 bytes should be left reserved for multi-chain, multiline is supported.
									accepts patterns: "spell:12345" will be replaced by spellName taken from numbers
													  "thisID" will be replaced by self.SlotID or self.ID
													  "(Rank %d+)" will replace Rank by localized word
													  any pattern can be combined like "spell:thisID(Rank 1)"
					MacroForbidden (@boolean) if true, user will not be able to set and overwrite macro.
					Click (@table) used to configure click-button of the meta-slot
						Click = {
							-- if any of the keys are missing then their corresponded key-val will be created automatically
							autounit = "help" or "harm" or "both", 	-- auto set unit based on meta-slot and prioritizes unit depending on value with combination of toggles, examples:
																	-- meta6 with autounit = "both" for Tranquilizing Shot and Purge will set [@raid1,harm][@party1,harm][@arena1,harm][@raid1,help][@party1,help]
																	-- meta6 with autounit = "help" for Tranquilizing Shot and Purge will set [@raid1,help][@party1,help]
																	-- meta6 with autounit = "harm" for Tranquilizing Shot and Purge will set [@raid1,harm][@party1,harm][@arena1,harm]
																	-- meta3 with autounit = "both" for Holy Shock will set [@mouseover,exists][@focus,help][@target,help][@target,harm][@focustarget,harm][@targettarget,harm][@player]
																	-- meta3 with autounit = "help" for Holy Shock will set [@mouseover,help][@focus,help][@target,help][@player]
																	-- meta3 with autounit = "harm" for Holy Shock will set [@mouseover,harm][@target,harm][@focustarget,harm][@targettarget,harm][@player]
							-- OR --
							unit = "unitID",						-- as you can see autounit will not set "player" and "cursor" in many cases, this is why Death and Delay and such spells must be manually adjusted as unit = "player" without using autounit

							type = "spell" or "item" or ..., 		-- cannot be "macro" here, skip it unless you gonna use something especial like "toy" or "action" button as automatically only sets "spell" or "item"
							typerelease = type, 					-- must be same as type
							macrobefore = "macrotext",				-- macro to be used before click
							macroafter = "macrotext",				-- macro to be used after click
							spell = spellID or "spellName",			-- if type and typerelease is "spell"
							item = itemID or "itemName",			-- if type and typerelease is "item"
							... 									-- any custom key(@string)-value(@string,@boolean,@number) will be inserted also
						}
				Only Macro will take effect if Click and Macro both are set	but preferable choice is Click instead of Macro (see below), without MacroForbidden user will able to set own macro through UI which will lead to take priority over set in profile Macro and Click.
				If Macro/Click is omit then it will automatically generate one of them.

		Fast Track
			All about which you should care is /castsequence|[@player]|[@cursor] and setting IsAntiFake, the other things are plug and play.

		Additional notes
			MetaEngine has own taint paths, attempting to penetrate it will not only disable MetaEngine, but also may uninstall it.
			MetaEngine by default works inside of A[1]-A[10] functions and HealingEngine, although through callback it can be used anywhere as long as actions are created.
			
			Calling same action will not be performed twice until it will be rotated. Repeatedly call ExecuteScript is not possible within same iteration.
			The main purpose of using Script is to update toggles and perform other buttons to inherit its attributes and pass them to the active meta-button but that will work as long as nothing else override it, for example:
				Refs = { ["ToT"] = _G.ToT }
				Script = 'local ToTMacro = self:GetFrameRef("ToT"):GetAttributes("macrotext"); this3:SetAttribute("macrotext", ToTMacro); this3:SetAttribute("macroactive", ToTMacro)'
			That's it, you just connected the usual API to the MetaEngine for the 3rd active meta-button. "macroactive" is used to maintain the macrotext of ToTMacro in "macrotext" of meta-button when chained.
			Alternatively, you can just set Macro to click your button:
				Macro = "/click ".._G.ToT:GetName()
			
			All General and HealingEngine actions are pre-allocated:
			/tar 	arena1-5, party1-4, player, partypet1-4, raid1-40, raidpet1-40, mouseover, focus
			/focus  arena1-5, party1-4, player, partypet1-4, raid1-40, raidpet1-40
			/use 13, 14, any Healthstone, any HealingPotion (see Core.lua)
			/stopcasting, /targetenemy, /targetlasttarget, /startattack, /stopattack
			
			
			Structure and construction:
				-- Means
				@all 			- defined actions from Action[owner], Core.lua and undefined actions from Constans.lua, where owner is Action.PlayerSpec if Retail, otherwise Action.PlayerClass
				@owner 			- defined actions from Action[owner]
				N/A 			- not available
				%expression% 	- value of expression
				.. 				- concatenation
				...				- everything
				|				- operator "or"
				:				- taken from
				=>				- equal to
				→				- next priority on chain
				DOWN 			- on event of click or press down
				UP				- on event of click or press up

				-- Active
				  slot	 description	  				variables	      			nameUI 						actions
				• [1]  Active meta-button 			this1,  this1click  		"AntiFake CC"					@owner if action.IsAntiFake, autounit resolves unit to mouseover (harm) and target 
				• [2]  Active meta-button 			this2,  this2click  		"AntiFake Interrupt"			@owner if action.IsAntiFake, autounit resolves unit to mouseover (harm) and target
				• [5]  Active meta-button 			this5,  this5click  		"Trinket Rotation"				@all, 					   	 autounit resolves unit to mouseover, target, focustarget, targettarget (harm) and player
				• [7]  Active meta-button 			this7,  this7click  		"AntiFake CC Focus"				@owner if action.IsAntiFake, autounit resolves unit to focus
				• [8]  Active meta-button 			this8,  this8click  		"AntiFake Interrupt Focus"		@owner if action.IsAntiFake, autounit resolves unit to focus
				• [9]  Active meta-button 			this9,  this9click  		"AntiFake CC2"					@owner if action.IsAntiFake, autounit resolves unit to mouseover (harm) and target
				• [10] Active meta-button 			this10, this10click 		"AntiFake CC2 Focus"			@owner if action.IsAntiFake, autounit resolves unit to focus
					Attributes						
						this%slot%: 
							"pressAndHoldAction", true
							"type", "macro"
							"macroactive", action:GetMacro() - OR - this%slot%click=>action.Click
							"macrotext", macroactive
							"typerelease", "click"
							"clickbutton", this
							... -- custom attributes by Script
						this%slot%click:
							"pressAndHoldAction", true
							"type", "spell|item|..." -- cannot be "macro" here
							"typerelease", type
							"spell|item|...", spellID|itemID|...
							"unit", unitID
							"autounit", "harm|help|both"
							... -- custom attributes from Click table or set by Script
					DOWN 	this%slot%:"macrotext"=>this%slot%:"macroactive" →
					UP 		this:"macrotext"=>this:"macropassive"..thisclick
				  slot	 description	  				variables	      			nameUI 						actions	
				• [3]  Active meta-button 			this3, this3click  			"Rotation"						@all, autounit resolves unit to mouseover,focus,target,focustarget,targettarget
				• [4]  Active meta-button 			this4, this4click  			"Secondary Rotation"			@all, autounit resolves unit to mouseover,focus,target,focustarget,targettarget
					Attributes
							same as above except
						this%slot%:
							"clickbutton", thisclick|this -- depending on "toggleprioritizepassive"
					DOWN 	this%slot%:"macrotext"=>this:"macropassive"..this%slot%:"macroactive" →
					UP 		thisclick:"target|focus"

				-- Passive
				  slot	 description	  				variables	      			nameUI 						actions
				• [6]  Passive Rotation Unit1		this, thisclick6				N/A							@all if not action.IsAntiFake, autounit resolves unit to arena1,raid1,party1
				• [7]  Passive Rotation Unit2		this, thisclick7				N/A							@all if not action.IsAntiFake, autounit resolves unit to arena2,raid2,party2
				• [8]  Passive Rotation Unit3		this, thisclick8				N/A							@all if not action.IsAntiFake, autounit resolves unit to arena3,raid3,party3
				• [9]  Passive Rotation Unit4		this, thisclick9				N/A							@all if not action.IsAntiFake, autounit resolves unit to arena4,raid4,party4
				• [10] Passive Rotation Unit5		this, thisclick10				N/A							@all if not action.IsAntiFake, autounit resolves unit to arena5,raid5,player
					Attributes							
						this: 
							"pressAndHoldAction", true
							"typerelease", "macro"
							"macropassive%slot%", action:GetMacro() - OR - thisclick%slot%=>action.Click
							"macropassive", "macropassive"6-10
							"macrotext", macropassive..thisclick
							"hasfocus" true if not vanilla classic
							"toggleraid" => GetToggle(9, "MetaEngine").raid
							"toggleparty" => GetToggle(9, "MetaEngine").party
							"togglearena" => GetToggle(9, "MetaEngine").arena
							"togglemouseover" => GetToggle(2, "mouseover")
							"togglefocus" => GetToggle(2, "focus")
							"togglefocustarget" => GetToggle(2, "focustarget")
							"toggletargettarget" => GetToggle(2, "targettarget")
							"togglehealer" => A.IamHealer
							"toggleprioritizepassive" => GetToggle(9, "MetaEngine").PrioritizePassive
							"togglecheckselfcast" => GetToggle(9, "MetaEngine").checkselfcast 
							-- => nil/true/false is enabled/enabled/disabled, if toggle is missing that considered as nil => enabled, focustarget and targettarget will be disabled if not A.IamHealer, focus and focustarget will be disabled on vanilla classic
							"state-%unitID%", "harm|help|unexists" -- target,focus,mouseover,targettarget,focustarget,party1-4,arena1-5,raid1-5
							... -- custom attributes by Script
						thisclick%slot%: 
							"pressAndHoldAction", true
							"type", "spell|item|..." -- cannot be "macro" here
							"typerelease", type
							"spell|item|...", spellID|itemID|...
							"unit", unitID
							"autounit", "harm|help|both"
							... -- custom attributes from Click table or set by Script

				-- Special
				  slot	 							  	variables	      			nameUI 						actions
				• ["Script"] 							all							action:Info() (Actions tab)	action:ExecuteScript()
				• ["HealingEngine"]  					thisclick					N/A							/tar 	party1-4, player, partypet1-4, raid1-40, raidpet1-40, focus
																												/focus 	party1-4, player, partypet1-4, raid1-40, raidpet1-40
					Attributes						
						thisclick:
							"pressAndHoldAction", true
							"typerelease", "target|focus"
							"type", typerelease -- if not Retail
							"unit", unitID -- party1-4, player, partypet1-4, focus, raid1-40, raidpet1-40
							... -- custom attributes by Script

			Since project was developed to share [7]-[10] at the same time as passive rotation and active buttons for AntiFake CC Focus and AntiFake Interrupt Focus, such actions for active button must be defined with IsAntiFake:
				• Active [7] AntiFake CC Focus			=> action.IsAntiFake = true
				• Active [8] AntiFake Interrupt Focus	=> action.IsAntiFake = true
				• Active [9] AntiFake CC2 Focus			=> action.IsAntiFake = true
				• Active [10] AntiFake Interrupt2 Focus	=> action.IsAntiFake = true			

			Therefore, UI is configured to show up only active meta-buttons with which user can interact to respect old-developed conception because of that this6 and this6click variables have no refences and don't exist, since HealingEngine is not a meta-button at all, it's also not present in the UI 
			The manipulation with this7-10 and this7-10click actually does it on AntiFakeCCFocus, AntiFakeInterruptFocus, AntiFakeCCFocus2, AntiFakeInterruptFocus2 which are the active meta-buttons of 7-10 meta-slots, while keeping the passive slots 6-10 working through manipulation with this, thisclick6-10

			HealingEngine integrated inside of active meta-buttons on click up event
			HealingEngine has A[1]-A[10] function-independent OnUpdate frame, and its priority order doesn't really matters
			
			Each active meta-button can perform actions according to the structure above
			Keypressing [1]-[2],[5],[7]-[10] of active meta-button chains: Active meta-button → Passive [6]→[10] → HealingEngine
			Keypressing [3]-[4] of active meta-button chains: Passive [6]→[10] → Active meta-button → HealingEngine
			Keypressing priority can be changed in UI by PrioritizePassive toggle for [3]-[4]
			
			Since TWW the macro body has max limit of 255 bytes and can't click buttons that would execute other macros, this is not enough to perform only on macros full multi-chain such as A[6]→A[7]→A[8]→A[9]→A[10]→A[3]→HealingEngine per one keypress especially when macro have russian or chinese letters which consumes 2 bytes per letter instead of 1.
			To mitigate this issue each keypress will perform 'A' scenario on down and then 'B' scenario on up, each event will remap self button to other no-macro buttons or perform combination of macros.
			As result, ~45 bytes should be left reserved for multi-chain if macros are used.
			Now, if lazy profile developer didn't read till this he might will use something like that:
				A.Spell.Macro = "/cast [@mouseover,help][@focus,help][]Благословенная свобода" through "/cast [@mouseover,help][@focus,help][]spell:1044"
				39 + 21*2 = 81 bytes
			What if lazy developer will set such macros for passive?
				A.Unit1Spell.Macro = "/cast [@raid1,exists][@party1,exists]Благословенная свобода"
				38 + 21*2 = 80 bytes
			What will happen on multi-chain when all of them are up?
				/cast [@raid1,exists][@party1,exists]Благословенная свобода -- 80 bytes +1 byte from \n
				/cast [@raid2,exists][@party2,exists]Благословенная свобода -- 80 bytes +1 byte from \n
				/cast [@raid3,exists][@party3,exists]Благословенная свобода -- 80 bytes +1 byte from \n
				/cast [@raid--ooops bro 255 bytes limit, the rest is cutted-off
			How it should be mitigated?
				A.Unit1Spell.Macro = ""
				A.Unit1Spell.Click = { autounit = "help", type = "spell", spell = 1044 }
				- OR -
				A.SpellRaid1.Click = { unit = "raid1" }
				A.SpellRaid2.Click = { unit = "raid2" }
				A.SpellRaid3.Click = { unit = "raid3" }
				A.SpellParty1.Click = { unit = "party1" }
				A.SpellParty2.Click = { unit = "party2" }
				A.SpellParty3.Click = { unit = "party3" }
				- OR -
				A.Unit1Spell.Macro = nil
				A.Unit1Spell.Click = nil
				just do nothing, as mentioned before, such keys will be auto generated, although they cannot automatically determine when action should be used as /cast [@player] or [@cursor] or /castsequence, therefore, they need to be defined manually
				

		Functions
			function Action.MetaEngine:GetErrorCodes()
				-- @return table
				-- log of errors
			end

			function Action.MetaEngine:IsSafe()
				-- @return boolean
				-- is authorized
			end

			function Action.MetaEngine:IsHealthy()
				-- @return boolean
				-- is in work-able configuration, indicates it's running
			end
			
		Callbacks
			TMW:Fire("TMW_ACTION_METAENGINE_RECONFIGURE")												-- used out of combat to refresh everything, if used in combat it will queue up pending reconfigure on the next out of combat event
			TMW:Fire("TMW_ACTION_METAENGINE_REASSIGN"[, slot, bind])									-- used out of combat to refresh bindings
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", slot or "Script" or "HealingEngine", action[, "unitID" or textureID])
			Examples
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", 3, Action.BlessingofFreedom)
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", 6, Action, CONST_STOPCAST)
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "HealingEngine", "target" or "focus", "unitID") 	-- unitID: raid1-40, raidpet1-40, party1-4, partypet1-4, player, focus. Used and controlled by HealingEngine.lua, attempting to use it with profile code will result in conflict
	]]
	local action
	local arg			= args or {}	
	arg.Desc 			= arg.Desc or ""
	arg.SubType 		= arg.Type
	arg.Macro 			= arg.Macro or ""
	
	-- Type "Spell" 
	if arg.Type == "Spell" or arg.Type == "HeartOfAzeroth" then 		
		-- Forced Type 
		arg.Type = "Spell"
		-- Methods Remap
		arg.Info = A.GetSpellInfo
		arg.Link = A.GetSpellLink		
		arg.Icon = A.GetSpellIcon
		if arg.Color then 
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return A.GetColoredSpellTexture(arg, arg.TextureID)
				end 
			elseif arg.FixedTexture then 
				arg.Texture = function()
					return "texture", arg.FixedTexture
				end 	
			else 
				arg.Texture = A.GetColoredSpellTexture
			end 		
		else 
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return A.GetSpellTexture(arg, arg.TextureID)
				end 
			elseif arg.FixedTexture then 
				arg.Texture = function()
					return "texture", arg.FixedTexture
				end 	
			else 
				arg.Texture = A.GetSpellTexture	
			end
		end 
		-- Power 
		arg.PowerCost, arg.PowerType = A.GetSpellPowerCostCache(arg.ID)

		-- ActionObj
		action = setmetatable(arg, { __index = A }) 
		
		-- MetaEngine
		action:SetDefaultAction()
		
		return action
	end 
	
	-- Type "Spell" 
	if arg.Type == "SpellSingleColor" then 
		-- Forced Type 
		arg.Type = "Spell"
		-- Methods Remap
		arg.Info = A.GetSpellInfo
		arg.Link = A.GetSpellLink		
		arg.Icon = A.GetSpellIcon
		-- This using static and fixed only color so no need texture
		arg.Texture = A.GetColorTexture
		-- Power 
		arg.PowerCost, arg.PowerType = A.GetSpellPowerCostCache(arg.ID)	

		-- ActionObj
		action = setmetatable(arg, { __index = A })
		
		-- MetaEngine
		action:SetDefaultAction()
		
		return action
	end 
	
	-- Type "Trinket", "Potion", "Item"
	if arg.Type == "Trinket" or arg.Type == "Potion" or arg.Type == "Item" then 
		-- Methods Remap
		arg.Info = A.GetItemInfo
		arg.Link = A.GetItemLink		
		arg.Icon = A.GetItemIcon
		if arg.Color then 
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return A.GetColoredItemTexture(arg, arg.TextureID)
				end 
			elseif arg.FixedTexture then 
				arg.Texture = function()
					return "texture", arg.FixedTexture
				end 	
			else 
				arg.Texture = A.GetColoredItemTexture
			end 		
		else 		
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return A.GetItemTexture(arg, arg.TextureID)
				end 
			elseif arg.FixedTexture then 
				arg.Texture = function()
					return "texture", arg.FixedTexture
				end 	
			else 
				arg.Texture = A.GetItemTexture
			end 
		end	
		-- Misc
		arg.Item = TMW.Classes.ItemByID:New(arg.ID)
		ItemIDs[#ItemIDs + 1] = arg.ID
		
		-- ActionObj
		action = setmetatable(arg, { __index = function(self, key)
			if A[key] then
				return A[key]
			else
				return self.Item[key]
			end
		end })
		
		-- MetaEngine
		action:SetDefaultAction()
		
		return action
	end 
	
	-- Type "Trinket", "Item"
	if arg.Type == "TrinketBySlot" or arg.Type == "ItemBySlot" then 
		-- Forced Type 
		if arg.Type == "TrinketBySlot" then 
			arg.Type = "Trinket"
		else 
			arg.Type = "Item"
		end 	
		-- Methods Remap
		arg.Info = A.GetItemInfo
		arg.Link = A.GetItemLink		
		arg.Icon = A.GetItemIcon
		if arg.Color then 
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return A.GetColoredItemTexture(arg, arg.TextureID)
				end 
			else 
				arg.Texture = A.GetColoredItemTexture
			end 		
		else 		
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return A.GetItemTexture(arg, arg.TextureID)
				end 
			else 
				arg.Texture = A.GetItemTexture
			end 
		end	
		-- Misc
		arg.Item = TMW.Classes.ItemBySlot:New(arg.ID)	
		if arg.Item:GetID() then 
			ItemIDs[#ItemIDs + 1] = arg.Item:GetID()
		end 
		
		-- ActionObj
		arg.SlotID = arg.ID -- fix for MacroAPI in Action:SetDefaultMacro() function
		arg.ID = nil
		action = setmetatable(arg, { __index = function(self, key)
			if key == "ID" then 
				return self.Item:GetID()
			end 
			
			if A[key] then
				return A[key]
			else
				return self.Item[key]
			end
		end })
		
		-- MetaEngine
		action:SetDefaultAction()
		
		return action
	end 
	
	-- Type "Item"
	if arg.Type == "ItemSingleColor" then
		-- Forced Type 
		arg.Type = "Item" 
		-- Methods Remap	
		arg.Info = A.GetItemInfo
		arg.Link = A.GetItemLink		
		arg.Icon = A.GetItemIcon
		-- This using static and fixed only color so no need texture
		arg.Texture = A.GetColorTexture		
		-- Misc 
		arg.Item = TMW.Classes.ItemByID:New(arg.ID)
		ItemIDs[#ItemIDs + 1] = arg.ID

		-- ActionObj
		action = setmetatable(arg, { __index = function(self, key)
			if A[key] then
				return A[key]
			else
				return self.Item[key]
			end
		end })
		
		-- MetaEngine
		action:SetDefaultAction()
		
		return action
	end 
	
	-- Type "SwapEquip"
	if arg.Type == "SwapEquip" then 		
		-- Methods Remap
		arg.Info = function()
			return EQUIPMENT_MANAGER
		end 
		arg.Link = arg.Info		
		arg.Icon = function()
			return arg.ID 
		end 
		if arg.Color then 
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return A.GetColoredSwapTexture(arg, arg.TextureID)
				end 
			elseif arg.FixedTexture then 
				arg.Texture = function()
					return "texture", arg.FixedTexture
				end 				
			else 
				arg.Texture = A.GetColoredSwapTexture
			end 		
		else 		
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return "texture", arg.TextureID
				end 
			elseif arg.FixedTexture then 
				arg.Texture = function()
					return "texture", arg.FixedTexture
				end 				
			else 
				arg.Texture = function()
					return "texture", arg.ID
				end 
			end 
		end	
		
		-- ActionObj
		action = setmetatable(arg, { __index = A })
		
		-- MetaEngine
		action:SetDefaultAction()
		
		return action
	end 
	
	-- Type "Script" (MetaEngine)
	if arg.Type == "Script" then
		arg.ID = arg.ID or CONST.PAUSECHECKS_DISABLED
		-- Methods Remap
		arg.Info = function()
			return arg.Name or "Script"
		end 
		arg.Link = arg.Info		
		arg.Icon = function()
			return arg.ID 
		end 
		if arg.Color then 
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return A.GetColoredSwapTexture(arg, arg.TextureID)
				end 
			elseif arg.FixedTexture then 
				arg.Texture = function()
					return "texture", arg.FixedTexture
				end 				
			else 
				arg.Texture = A.GetColoredSwapTexture
			end 		
		else 		
			if arg.Texture then 
				arg.TextureID = arg.Texture
				arg.Texture = function()
					return "texture", arg.TextureID
				end 
			elseif arg.FixedTexture then 
				arg.Texture = function()
					return "texture", arg.FixedTexture
				end 				
			else 
				arg.Texture = function()
					return "texture", arg.ID
				end 
			end 
		end	
		
		arg.QueueForbidden = true
		arg.MacroForbidden = true
		return setmetatable(arg, { __index = A })
	end
	
	-- nil
	arg.Hidden = true 		
	return setmetatable(arg, { __index = A })		 
end 