-------------------------------------------------------------------------------
--
-- DON'T USE THIS API, IT'S OLD AND WILL BE REMOVED, THIS IS LEAVED HERE TO 
-- PROVIDE SUPPORT FOR OLD PROFILES
--
-------------------------------------------------------------------------------
-- TODO: DON'T FORGET TO REMOVE CALLBACK 'TMW_ACTION_DEPRECATED' !!!!!! <<<=== 

local TMW 							= TMW
local CNDT 							= TMW.CNDT
local Env 							= CNDT.Env
local strlowerCache  				= TMW.strlowerCache

local A 							= Action
local insertMulti					= A.TableInsertMulti
local strElemBuilder				= A.strElemBuilder
local toStr 						= A.toStr
local toNum 						= A.toNum
local InstanceInfo					= A.InstanceInfo
local TeamCache						= A.TeamCache
local HealingEngine					= A.HealingEngine
local LoC							= A.LossOfControl
local MultiUnits					= A.MultiUnits
local Player						= A.Player
local Unit 							= A.Unit 
local EnemyTeam						= A.EnemyTeam
local FriendlyTeam					= A.FriendlyTeam
local GetSpellInfo					= A.GetSpellInfo
local IsSpellInRange				= A.IsSpellInRange
local GetAuraList					= A.GetAuraList
local GetPing						= A.GetPing
local GetGCD						= A.GetGCD
local GetCurrentGCD					= A.GetCurrentGCD
local BossMods						= A.BossMods

local HealingEngineMembersALL		= HealingEngine.GetMembersAll()
local ActiveUnitPlates 				= MultiUnits:GetActiveUnitPlates()

local Azerite						= LibStub("AzeriteTraits")
local Pet							= LibStub("PetLibrary")  

local _G, type, pairs, ipairs, select, setmetatable, unpack, math =
	  _G, type, pairs, ipairs, select, setmetatable, unpack, math

local wipe							= _G.wipe
local huge 							= math.huge	  

local C_Spell						= _G.C_Spell
local OriginalGetSpellInfo 			= C_Spell and C_Spell.GetSpellName or _G.GetSpellInfo
local GetSpellName 					= C_Spell and C_Spell.GetSpellName or _G.GetSpellInfo
local GetInventoryItemCooldown 		= _G.GetInventoryItemCooldown
local GetItemCooldown 				= _G.GetItemCooldown or (_G.C_Container and _G.C_Container.GetItemCooldown)
local UnitIsUnit 					= _G.UnitIsUnit
local 	 IsPlayerSpell,    										IsUsableSpell = 
	  _G.IsPlayerSpell, C_Spell and C_Spell.IsSpellUsable or _G.IsUsableSpell
	  
local MACRO							-- nil 
local BINDPAD 						= _G.BindPadFrame
local WIM							= _G.WIM	 

local ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE = _G.ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE
local ACTION_CONST_CACHE_DEFAULT_TIMER_UNIT 			= _G.ACTION_CONST_CACHE_DEFAULT_TIMER_UNIT
local ACTION_CONST_CACHE_DISABLE						= _G.ACTION_CONST_CACHE_DISABLE
	  
-------------------------------------------------------------------------------
-- Some place to fix issues with Taste rotations 
-------------------------------------------------------------------------------	  
-- Temporary fix while Taste is away
A.CastTime 			 				= A.GetSpellCastTime
A.AzeriteEnabled					= A.IsAzeriteEnabled

local HL         				 	= HeroLib
if HL then 
	local HL_Unit    				= HL.Unit
	local HL_Player   				= HL_Unit.Player
	
	if not HL_Player.InRaid then 
		function HL_Player:InRaid() 
			return TeamCache.Friendly and TeamCache.Friendly.Type == "raid"
		end 
	end 
end 	  
	  
-------------------------------------------------------------------------------
-- Staff
-------------------------------------------------------------------------------
function deepcopy(orig)
    local copy
    if type(orig) == "table" then
        copy = {}
        for i = 1, #orig do
            copy[#copy + 1] = orig[1]
        end
    else 
        copy = orig
    end
    return copy
end

function dynamic_array(dimension)
    local metatable = {}
    for i=1, dimension do
        metatable[i] = {__index = function(tbl, key)
                if i < dimension then
                    tbl[key] = setmetatable({}, metatable[i+1])
                    return tbl[key]
                end
            end
        }
    end
    return setmetatable({}, metatable[1])
end

function quote(str)
    return "\""..str.."\""
end

_G.oLastCall 						= { ["global"] = 0.2 } 
function fLastCall(obj)
    if not oLastCall[obj] then
        oLastCall[obj] = 0
    end
    return TMW.time >= oLastCall[obj]
end

-------------------------------------------------------------------------------
-- API: BossMods Retired 
-------------------------------------------------------------------------------
function A.DBM_PullTimer()
	return BossMods:GetPullTimer()
end 

function A.DBM_GetTimer(name)    
	return BossMods:GetTimer(name)
end 

function A.DBM_IsEngage()
	return BossMods:IsEngage()
end 

function A.BossMods_Pulling()
	return BossMods:GetPullTimer()
end 

-------------------------------------------------------------------------------
-- Reworked
-------------------------------------------------------------------------------
-- Exception
Env.InPvP_Toggle 								= false 

-- Set as default
Env.Instance, Env.Zone 							= "none", "none"
Env.PvPCache									= {}

Env.PvPCache["EnemyHealerUnitID"] 				= TeamCache.Enemy.HEALER
Env.PvPCache["EnemyTankUnitID"] 				= TeamCache.Enemy.TANK
Env.PvPCache["EnemyDamagerUnitID"] 				= TeamCache.Enemy.DAMAGER 
Env.PvPCache["EnemyDamagerUnitID_Melee"] 		= TeamCache.Enemy.DAMAGER_MELEE
Env.PvPCache["EnemyDamagerUnitID_Range"] 		= TeamCache.Enemy.DAMAGER_RANGE
Env.PvPCache["FriendlyHealerUnitID"] 			= TeamCache.Friendly.HEALER
Env.PvPCache["FriendlyTankUnitID"] 				= TeamCache.Friendly.TANK 
Env.PvPCache["FriendlyDamagerUnitID"] 			= TeamCache.Friendly.DAMAGER 
Env.PvPCache["FriendlyMeleeUnitID"] 			= TeamCache.Friendly.DAMAGER_MELEE

-------------------------------------------------------------------------------
-- Remap tables and variables 
------------------------------------------------------------------------------- 
local DeprecatedVariables = {
	PlayerSpec 						= "PlayerSpec",
	PlayerSpecName 					= "PlayerSpecName",
	IamHealer						= "IamHealer",
	InPvP_Status					= "IsInPvP",
	Instance						= "IsInInstance",
	Zone							= "Zone",
	InPvP_Duel						= "IsInDuel",
	ZoneTimeStampSinceJoined		= "TimeStampZone",
	IsGGLprofile					= "IsGGLprofile",
}
local isCleared 
TMW:RegisterCallback("TMW_ACTION_DEPRECATED", function()
	if A.IsInitialized then
		if not isCleared then 
			for k, v in pairs(DeprecatedVariables) do 
				Env[k] 									= nil 
			end 
			-- Update tables 
			Env.PvPCache["Group_EnemySize"] 			= nil
			Env.PvPCache["Group_FriendlySize"] 			= nil
			Env.PvPCache["Group_FriendlyType"]			= nil              
			Env.PvPCache["FriendlyMeleeCounter"] 		= nil			
			isCleared = true 
		end 
		return 
	end  
	
	if not A.IsInitialized then 
		for k, v in pairs(DeprecatedVariables) do 
			if k ~= "InPvP_Status" or not Env.InPvP_Toggle then 
				Env[k] 									= A[v] 
			end 
		end 
		isCleared = nil
		-- Update tables 
		Env.PvPCache["Group_EnemySize"] 				= TeamCache.Enemy.Size
		Env.PvPCache["Group_FriendlySize"] 				= TeamCache.Friendly.Size
		Env.PvPCache["Group_FriendlyType"]				= TeamCache.Friendly.Type or "none"              
		Env.PvPCache["FriendlyMeleeCounter"] 			= 0	
		for k in pairs(TeamCache.Friendly.DAMAGER_MELEE) do 
			Env.PvPCache["FriendlyMeleeCounter"] 		= Env.PvPCache["FriendlyMeleeCounter"] + 1
		end 
		Action.BlackBackgroundSet(true)
	end 
end)

-------------------------------------------------------------------------------
-- Remap functions
------------------------------------------------------------------------------- 
-- Locals 
local TalentMap, PvpTalentMap		= Env.TalentMap, Env.PvpTalentMap

-- Super Globals
Listener 							= A.Listener
UnitCooldown						= A.UnitCooldown
MouseHasFrame						= A.MouseHasFrame

-- Env
Env.GCD								= GetGCD
Env.CurrentTimeGCD					= GetCurrentGCD
Env.CacheGetSpellPowerCost 			= A.GetSpellPowerCostCache
Env.GetPowerCost 					= A.GetSpellPowerCost
Env.GetDescription 					= A.GetSpellDescription

Env.InLOS 							= A.UnitInLOS

Env.PvP 							= {}
Env.PvP.Unit						= Unit  
Env.PvP.EnemyTeam					= EnemyTeam
Env.PvP.FriendlyTeam				= FriendlyTeam

function Env.CheckInPvP()
    return A:CheckInPvP()
end

function Env.GetTimeSinceJoinInstance()
	return A:GetTimeSinceJoinInstance()
end 

function Env.SpellInRange(unitID, spellID)
	return IsSpellInRange(spellID, unitID)
end

function Env.UNITMoving(unitID, mode) 
	if mode == "out" then 
		return Unit(unitID):IsMovingOut(0.25)
	else 
		return Unit(unitID):IsMovingIn(0.25)
	end 
end 

-- Azerite Empower / Azerite Essence
function AzeriteRank(spellID)
	return Azerite:GetRank(spellID)
end

-- Azerite Essence
function AzeriteEssenceGet(spellID)
	return Azerite:EssenceGet(spellID)
end 

function AzeriteEssenceGetMajor()
	return Azerite:EssenceGetMajor()
end 

function AzeriteEssenceHasMajor(spellID)
	return Azerite:EssenceHasMajor(spellID)
end 

function AzeriteEssenceIsMajorUseable() 
	return Azerite:EssenceIsMajorUseable() 
end 

function AzeriteEssenceHasMinor(spellID)
	return Azerite:EssenceHasMinor(spellID)
end 

function AzeriteEssenceConflictandStrife(spellID)
	return Azerite:IsLearnedByConflictandStrife(GetSpellInfo(spellID))
end 

-------------------------------------------------------------------------------
-- Merged without changes
------------------------------------------------------------------------------- 
function Env.InPvP()    
    return Env.InPvP_Status or false
end

function Env.TalentLearn(id)
    return TalentMap[strlowerCache[GetSpellInfo(id)]]
end

function Env.PvPTalentLearn(id)
	local Name = GetSpellInfo(id)
    return (Env.InPvP_Status and PvpTalentMap[strlowerCache[Name]]) or Azerite:IsLearnedByConflictandStrife(Name)
end

function Env.SpellExists(spell)   
    if type(spell) ~= "number" then 
		local s, _, _, _, _, _, spell = OriginalGetSpellInfo(spell)
		if type(s) == "table" then 
			spell = s.spellID
		end 
    end 
    return spell and (IsPlayerSpell(spell) or (Pet:IsActive() and Pet:IsSpellKnown(spell)))
end

function Env.SpellUsable(spell, offset)
    local offset = offset or (GetPing() + 0.05)
    local spellName = GetSpellInfo(spell)
    return IsUsableSpell(spellName) and Env.CooldownDuration(spellName) <= offset -- works for pet spells 01/04/2019
end

function Env.SpellCD(spellID)
    return Env.CooldownDuration(GetSpellInfo(spellID))
end

function Env.SpellCharges(spellID)
	local charges = Env.GetSpellCharges(GetSpellInfo(spellID))
	if type(charges) == "table" then 
		charges = charges.currentCharges
	end  
    return charges or 0
end

function Env.ChargesFrac(spellID)
    local charges, maxCharges, start, duration = Env.GetSpellCharges(GetSpellInfo(spellID))
	if type(charges) == "table" then 		
		maxCharges = charges.maxCharges
		start = charges.cooldownStartTime
		duration = charges.cooldownDuration
		charges = charges.currentCharges
	end  
	
    if charges == maxCharges then 
        return maxCharges
    end
    return charges + ((TMW.time - start) / duration)    
end

local LastCastException = {
	-- List of spells which can be interrupted by next rotation conditions
    [12051]  = true,  -- Evocation
    [15407]  = true,  -- Mind Fly
}

local PassCastToTrue = {
	[293491] = true,  													-- Cyclotronic Blast
	[GetSpellName(293491) or ""] = true, 								-- Cyclotronic Blast
	[295258] = true,  													-- Focused Azerite Beam Rank1
	[299336] = true,  													-- Focused Azerite Beam Rank2 
	[299338] = true,  													-- Focused Azerite Beam Rank3
	[300968] = true,  													-- Imbue Power
}

local function PlayerCastingException()
	local castName, _, _, _, _, _, _, _, spellID = Unit("player"):IsCasting()
	return castName and (LastCastException[castID] or LastCastException[castName])
end 

local function PlayerCastingEnd()
    local _, castingendtime = Env.CastTime() 
    return (castingendtime > 0 and castingendtime) or -1
end

local function PlayerCastingPassToTrue()
	local castID = select(5, Unit("player"):IsCasting())
	return castID and PassCastToTrue[castID]
end 

function Env.ShouldStop() -- true 
    local ping = GetPing()
	local cGCD = GetCurrentGCD()
    return (GetGCD() - cGCD > 0.3 and cGCD >= ping + 0.5) or PlayerCastingPassToTrue() or (not PlayerCastingException() and PlayerCastingEnd() > ping) or false
end

local function MacroFrameIsVisible()
	-- @return boolean 
	if MACRO then 
		return MACRO:IsVisible()
	else 
		MACRO = _G.MacroFrame
	end 
end 

local function BindPadFrameIsVisible()
	-- @return boolean 
	return BINDPAD and BINDPAD:IsVisible()
end 

local WIM_ChatFrames = setmetatable({}, { __index = function(t, i)
	local f = _G["WIM3_msgFrame" .. i .. "MsgBox"]
	if f then 
		t[i] = f
	end 
	return f
end })

function Env.chat()
	-- Chat, Macro, BindPad, TellMeWhen + Retired casts
	if _G.ACTIVE_CHAT_EDIT_BOX or MacroFrameIsVisible() or BindPadFrameIsVisible() or not TMW.Locked or PlayerCastingPassToTrue() then 
		return true
	end 
	
	-- Wim Messanger
	if WIM then 
		for i = 1, huge do 
			if not WIM_ChatFrames[i] then 
				break 
			elseif WIM_ChatFrames[i]:IsVisible() and WIM_ChatFrames[i]:HasFocus() then 
				return true
			end 
		end 
	end  
end

--- ======================= UnitAura ===========================
--- Buffs 
function Env.Buffs(unitID, spell, source, byID)
	return Unit(unitID):HasBuffs(spell, source, byID)
end

function Env.SortBuffs(unitID, spell, source, byID)    
	return Unit(unitID):SortBuffs(spell, source, byID)
end

function Env.BuffStack(unitID, spell, source, byID)
	return Unit(unitID):HasBuffsStacks(spell, source, byID)
end

--- DeBuffs
function Env.DeBuffs(unitID, spell, source, byID)
    return Unit(unitID):HasDeBuffs(spell, source, byID) 
end

function Env.SortDeBuffs(unitID, spell, source, byID)
    return Unit(unitID):SortDeBuffs(spell, source, byID) 
end

function Env.DeBuffStack(unitID, spell, source, byID)
	return Unit(unitID):HasDeBuffsStacks(spell, source, byID)
end

--- Pandemic Threshold
function Env.PT(unitID, spell, debuff, byID)       
	return Unit(unitID):PT(spell, debuff, byID)
end


--- =========================== UNITS ============================
function Env.UNITSpec(unitID, specs)  
	return Unit(unitID):HasSpec(specs)
end

function Env.UNITRole(unitID, role)
    return Unit(unitID):Role(role)
end

function Env.UNITRace(unitID)
    return Unit(unitID):Race()
end

function Env.UNITLevel(unitID)
    return Unit(unitID):GetLevel()
end

function Env.UNITEnemy(unitID)
    return Unit(unitID):IsEnemy()
end

function Env.UNITAgro(unitID, otherunit)
    return Unit(unitID):IsTanking(otherunit)
end

function Env.UNITRange(unitID)
    return Unit(unitID or "target"):GetRange()
end

function Env.UNITCurrentSpeed(unitID)
	return Unit(unitID):GetCurrentSpeed()    
end

function Env.UNITMaxSpeed(unitID)
    return Unit(unitID):GetMaxSpeed()
end

function Env.UNITStaying(unitID)   
	return Unit(unitID):IsStayingTime()
end

function Env.UNITDead(unitID)
    return Unit(unitID):IsDead()
end

function Env.UNITHP(unitID)
    return Unit(unitID):HealthPercent()
end

function Env.UNITBoss(unitID)
    return Unit(unitID or "target"):IsBoss()
end 

--- ========================== SPELLS ===========================
function Env.SpellInteract(unitID, range)  
	return Unit(unitID or "target"):CanInterract(range)
end

function Env.UNITPW(unitID)
    return Unit(unitID or "player"):PowerPercent()
end

function Env.execute_time(spellID) 
    -- @return GCD > CastTime or GCD
	return Player:Execute_Time(spellID)
end

function Env.SpellHaste()
    return Player:SpellHaste()
end

--- ========================== Casts ===========================
function Env.RandomKick(unitID, kickAble)
	return Unit(unitID or "target"):CanInterrupt(kickAble)
end

function Env.CastTime(id, unitID)    
	return Unit(unitID or "player"):CastTime(id)
end

function Env.MyBurst(unit)
    if not unit then unit = "target" end
    return A.Zone == "none" or Unit(unit):IsBoss() or Unit(unit):IsPlayer()
end

function Env.global_invisible()
    return Player:IsStealthed()
end

-- Very OLD 
function Env.QuakingPalm(unitID)
    local total, cur_castleft, pct_castleft, spellID, spellName, notKickAble = Unit(unitID):CastTime()
    if spellID and cur_castleft < GetGCD() then 
        return true 
    end  
end 

--- ========================== ITEMS ===========================
--- TODO: Remove on old profiles since it does now LibPvP 2.1+
function Env.UseItem(slot)    
    local start, duration, enable = GetInventoryItemCooldown("player", slot)    
    if enable == 0 or start + duration - TMW.time > 0 then
        return false
    end    
    return true
end

--- ========================== RACIALS ===========================
--- TODO: Remove on old profiles until June 2019
local Race = {
	SpellID = {
		Human = 59752, 
		NightElf = 58984,
		Dwarf = 20594, 
		Gnome = 20589, 
		Draenei = 28880, 
		Worgen = 68992, 
		Orc = 33697, 
		Troll = 26297, 
		Scourge = 7744,
		Tauren = 20549,
		BloodElf = 28730,
		Goblin = 69070, 
		Pandaren = 107079, 
		VoidElf = 256948,  
		LightforgedDraenei = 255647, 
		DarkIronDwarf = 265221, 
		HighmountainTauren = 255654, 
		Nightborne = 260364,
		MagharOrc = 274738,	
	},
	DAMAGE = {
		Orc = true, 
		Troll = true,
		BloodElf = true, 
		LightforgedDraenei = true,
		DarkIronDwarf = true, 
		Nightborne = true, 
		MagharOrc = true, 
	}, 
    TRINKET = {
        Human = true, 
        Dwarf = true,
        Gnome = true,
        Scourge = true,
        DarkIronDwarf = true,
    },
    DEFF = {
        Dwarf = true,
        Draenei = true,
    },
    SPRINT = {
        Worgen = true, 
        Goblin = true,
        HighmountainTauren = false,
    },
    CC = {
        Tauren = true,
        BloodElf = true,
        Pandaren = false,
        HighmountainTauren = false, 
    }, 	
}

function Env.SpellRace(key)	
    local id = Race.SpellID[A.PlayerRace]
	if id and Race[key][A.PlayerRace] and Env.SpellCD(id) <= 0.02 and Env.SpellExists(GetSpellInfo(id)) then 
		if key == "CC" then 
			if (A.PlayerRace == "BloodElf" or A.PlayerRace == "Tauren") and AoE(1, 8) then 
				return id 
			end 
			
			if A.PlayerRace == "Pandaren" and Env.QuakingPalm("target") then 
				return id 
			end 					
		end 
		
		if key == "SPRINT" then 
			if LoC:Get("ROOT") <= GetCurrentGCD() and LoC:Get("SNARE") <= GetCurrentGCD() then 
				return id 
			end 
		end
		
		if key == "DEFF" then 
			if A.PlayerRace == "Dwarf" and incdmgphys("player") >= incdmg("player") / 2 and TimeToDie("player") <= 10 then 
				return id 
			end 
			
			if A.PlayerRace == "Draenei" and TimeToDieX("player", 25) <= 5 and (UnitIsUnit("target", "player") or Unit("target"):IsEnemy())then 
				return id 
			end 
		end 
		
		if key == "TRINKET" then 
			local Medallion = Env.PvPTalentLearn(208683) and 208683 or 195710	
			if A.PlayerRace == "Human" and LoC:Get("STUN") > 0 and (not Env.InPvP() or Env.SpellCD(Medallion) > 0 or (
				LoC:Get("DISARM") == 0 and 
				LoC:Get("INCAPACITATE") == 0 and
				LoC:Get("DISORIENT") == 0 and
				LoC:Get("FREEZE") == 0 and
				LoC:Get("SILENCE") == 0 and
				LoC:Get("POSSESS") == 0 and
				LoC:Get("SAP") == 0 and
				LoC:Get("CYCLONE") == 0 and
				LoC:Get("BANISH") == 0 and
				LoC:Get("PACIFYSILENCE") == 0 and
				LoC:Get("POLYMORPH") == 0 and
				LoC:Get("SLEEP") == 0 and
				LoC:Get("SHACKLE_UNDEAD") == 0 and
				LoC:Get("FEAR") == 0 and
				LoC:Get("HORROR") == 0 and
				LoC:Get("CHARM") == 0 and
				LoC:Get("ROOT") == 0)) then 
				return id 
			end
			
			if A.PlayerRace == "Dwarf" and (
				LoC:Get("POLYMORPH") > 0 or 
				LoC:Get("SLEEP") > 0 or 
				LoC:Get("SHACKLE_UNDEAD") > 0 or 
				Unit("player"):HasDeBuffs("Poison") > 0 or 
				Unit("player"):HasDeBuffs("Curse") > 0 or 
				Unit("player"):HasDeBuffs("Magic") > 0
			) and (not Env.InPvP() or Env.SpellCD(Medallion) > 0 or (
				LoC:Get("DISARM") == 0 and 
				LoC:Get("INCAPACITATE") == 0 and
				LoC:Get("DISORIENT") == 0 and
				LoC:Get("FREEZE") == 0 and
				LoC:Get("SILENCE") == 0 and
				LoC:Get("POSSESS") == 0 and
				LoC:Get("SAP") == 0 and
				LoC:Get("CYCLONE") == 0 and
				LoC:Get("BANISH") == 0 and
				LoC:Get("PACIFYSILENCE") == 0 and
				LoC:Get("STUN") == 0 and
				LoC:Get("FEAR") == 0 and
				LoC:Get("HORROR") == 0 and
				LoC:Get("CHARM") == 0 and
				LoC:Get("ROOT") == 0				
			)) then 
				return id 
			end 
			
			if A.PlayerRace == "Scourge" and (
				LoC:Get("FEAR") > 0 or 
				LoC:Get("HORROR") > 0 or 
				LoC:Get("SLEEP") > 0 or 
				LoC:Get("CHARM") > 0
			) and (not Env.InPvP() or Env.SpellCD(Medallion) > 0 or (
				LoC:Get("DISARM") == 0 and 
				LoC:Get("INCAPACITATE") == 0 and
				LoC:Get("DISORIENT") == 0 and
				LoC:Get("FREEZE") == 0 and
				LoC:Get("SILENCE") == 0 and
				LoC:Get("POSSESS") == 0 and
				LoC:Get("SAP") == 0 and
				LoC:Get("CYCLONE") == 0 and
				LoC:Get("BANISH") == 0 and
				LoC:Get("PACIFYSILENCE") == 0 and
				LoC:Get("POLYMORPH") == 0 and
				LoC:Get("STUN") == 0 and
				LoC:Get("SHACKLE_UNDEAD") == 0 and 				
				LoC:Get("ROOT") == 0				
			)) then 
				return id
			end 
			
			if A.PlayerRace == "Gnome" and (LoC:Get("ROOT") > 0 or LoC:Get("SNARE") > 0) and (not Env.InPvP() or Env.SpellCD(Medallion) > 0 or (
				LoC:Get("DISARM") == 0 and 
				LoC:Get("INCAPACITATE") == 0 and
				LoC:Get("DISORIENT") == 0 and
				LoC:Get("FREEZE") == 0 and
				LoC:Get("SILENCE") == 0 and
				LoC:Get("POSSESS") == 0 and
				LoC:Get("SAP") == 0 and
				LoC:Get("CYCLONE") == 0 and
				LoC:Get("BANISH") == 0 and
				LoC:Get("PACIFYSILENCE") == 0 and
				LoC:Get("POLYMORPH") == 0 and
				LoC:Get("SLEEP") == 0 and 
				LoC:Get("STUN") == 0 and
				LoC:Get("SHACKLE_UNDEAD") == 0 and 	
				LoC:Get("FEAR") == 0 and    
				LoC:Get("HORROR") == 0 			
			)) then 
				return id 
			end 

		end 
		
		if key == "DAMAGE" then 
			return id 
		end 		
	end 
	
    return false
end 	

function Env.GladiatorMedallion()
	return 
	Env.InPvP() and 
	(
		(
			Env.PvPTalentLearn(208683) and -- Gladiator
			Env.SpellCD(208683) == 0
		) or 
		(
			not Env.PvPTalentLearn(208683) and
			Env.SpellExists(195710) and -- Honor
			Env.SpellCD(195710) == 0
		)
	) and 
	(
		--- PvP Trinket:
		LoC:Get("DISARM") > 0 or 
		LoC:Get("INCAPACITATE") > 0 or 
		LoC:Get("DISORIENT") > 0 or 
		LoC:Get("FREEZE") > 0 or       
		LoC:Get("SILENCE") > 0 or 
		LoC:Get("POSSESS") > 0 or     
		LoC:Get("SAP") > 0 or     
		LoC:Get("CYCLONE") > 0 or 
		LoC:Get("BANISH") > 0 or 
		LoC:Get("PACIFYSILENCE") > 0 or 
		--- Dworf|DarkIronDwarf
		LoC:Get("POLYMORPH") > 0 or     
		LoC:Get("SLEEP") > 0 or 
		LoC:Get("SHACKLE_UNDEAD") > 0 or 
		--- Scourge + WR Berserk Rage + DK Lichborne
		LoC:Get("FEAR") > 0 or     
		LoC:Get("HORROR") > 0 or     
		--- Scourge
		LoC:Get("CHARM") > 0 or         
		--- Gnome and any freedom effects 
		LoC:Get("ROOT") > 0 or         
		LoC:Get("SNARE") > 0 or 
		--- Human + DK Icebound|Lichborne
		LoC:Get("STUN") > 0 
	)	
end

-------------------------------------------------------------------------------
-- Player and Power
------------------------------------------------------------------------------- 
function Env.Stance(n)
	return Player:IsStance(n)
end

function Env.GetStance()
	return Player:GetStance()
end

function Env.GetFalling()
	return Player:IsFalling()
end

function Env.ComboPoints()
    return Player:ComboPoints()
end

-- energy.max
function Env.EnergyMax()
	return Player:EnergyMax()
end
  
-- energy
function Env.Energy()
    return Player:Energy()
end

-- energy.regen
function Env.EnergyRegen()
    return Player:EnergyRegen()
end

-- energy.pct
function Env.EnergyPercentage()
	return Player:EnergyPercentage()
end
  
-- energy.deficit 
function Env.EnergyDeficit()
    return Player:EnergyDeficit()
end

-- "energy.deficit.pct"
function Env.EnergyDeficitPercentage()
	return Player:EnergyDeficitPercentage()
end

-- "energy.regen.pct"
function Env.EnergyRegenPercentage()
	return Player:EnergyRegenPercentage()
end

-- energy.time_to_max
function Env.EnergyTimeToMax()
	return Player:EnergyTimeToMax()
end

-- "energy.time_to_x"
function Env.EnergyTimeToX(Amount, Offset)
	return Player:EnergyTimeToX(Amount, Offset)
end

-- "energy.time_to_x.pct"
function Env.EnergyTimeToXPercentage(Amount)
	return Player:EnergyTimeToXPercentage(Amount)
end

-- "energy.cast_regen"
function Env.EnergyRemainingCastRegen(Offset)
    return Player:EnergyRemainingCastRegen(Offset)
end

-- Predict the expected Energy at the end of the Cast/GCD.
function Env.EnergyPredicted(Offset) 
    return Player:EnergyPredicted(Offset)
end

-- Predict the expected Energy Deficit at the end of the Cast/GCD.
function Env.EnergyDeficitPredicted(Offset)
	return Player:EnergyDeficitPredicted(Offset)
end

-- Predict time to max energy at the end of Cast/GCD
function Env.EnergyTimeToMaxPredicted()
	return Player:EnergyTimeToMaxPredicted()
end

function Env.Rage()
    return Player:Rage()
end

function Env.RageDeficit()
    return Player:RageDeficit()
end

function Env.MultiCast(unitID, spells, range)
	return Unit(unitID):MultiCast(spells, range)
end

Env.PvP.MultiCast = Env.MultiCast
-------------------------------------------------------------------------------
-- PvPLib
-------------------------------------------------------------------------------
local function PseudoClass(methods)
    local Class = setmetatable({ extend = methods }, {
            __call = function(self, ...)
				self:New(...)
				return self.extend				 
            end,
    })
	setmetatable(Class.extend, { __index = Class })
    return Class
end

local Cache = {
	bufer = {},
	newEl = function(this, inv, keyArg, func, ...)
		if not this.bufer[func][keyArg] then 
			this.bufer[func][keyArg] = { v = {} }
		else 
			wipe(this.bufer[func][keyArg].v)
		end 
		this.bufer[func][keyArg].t = TMW.time + (inv or ACTION_CONST_CACHE_DEFAULT_TIMER_UNIT) + 0.001  -- Add small delay to make sure what it's not previous corroute  
		insertMulti(this.bufer[func][keyArg].v, func(...))
		return unpack(this.bufer[func][keyArg].v)
	end,
	Wrap = function(this, func, name)
		if ACTION_CONST_CACHE_DISABLE then 
			return func 
		end 
		
		if not this.bufer[func] then 
			this.bufer[func] = {} 
		end
		
   		return function(...)  
			-- The reason of all this view look is memory hungry eating, this way use around 0 memory now
			local self = ...		
			local keyArg = strElemBuilder(name, ...)		
			
			if TMW.time > (this.bufer[func][keyArg] and this.bufer[func][keyArg].t or 0) then
	            return this:newEl(self.Refresh, keyArg, func, ...)
	        else
	            return unpack(this.bufer[func][keyArg].v)
	        end
        end        
    end,
}

local ItemList = {
	-- Categories
    ["DPS"] = {
        [165806] = true, -- Sinister Gladiator's Maledict
    },
    ["DEFF"] = {
        [165056] = true, -- Sinister Gladiator's Emblem
        [161675] = true, -- Dread Gladiator's Emblem
        [159618] = true, -- Mchimba's Ritual Bandages (Tank Item)
    },
    ["MISC"] = {
        [159617] = true, -- Lustrous Golden Plumage 
    },
}

function Env.GetItemList(ket)
    return ItemList[key]
end 

local Items = TMW:GetItems("13; 14")
Env.Item = PseudoClass({
	IsForbidden = { 
		-- Crest of Pa'ku
		[165581] = true, 
		-- Mr. Munchykins
		[155567] = true, 
		-- Ingenious Mana Battery
		[169344] = true, 		
	},
	IsDPS = Cache:Wrap(function(self)       
			local ID = Items[self.Slot]:GetID() or 0
	        return not ItemList["DEFF"][ID] 
	end, "Slot"),
	IsDEFF = Cache:Wrap(function(self)       
			local ID = Items[self.Slot]:GetID() or 0
	        return not ItemList["DPS"][ID] 
	end, "Slot"),
	IsUsable = Cache:Wrap(function(self, unit) 
			local ID = Items[self.Slot]:GetID() or 0
			local start, duration, enable = Items[self.Slot]:GetCooldown()
			local onCD = enable == 0 or start + duration - TMW.time > 0
	        return not onCD and Items[self.Slot]:GetEquipped() and not self.IsForbidden[ID] and ( not unit or unit == "player" or not ItemHasRange(ID) or Items[self.Slot]:IsInRange(unit) )
	end, "Slot"),	
	GetID = Cache:Wrap(function(self)   			
	        return Items[self.Slot]:GetID() or 0
	end, "Slot"),	
})
function Env.Item:New(Slot, Refresh)
	self.Slot = Slot == 13 and 1 or Slot == 14 and 2 or Slot 
    self.Refresh = Refresh or 0.1
end 

--- ===================== 2.0 REFFERENCE (OLD) ======================
-- Remaping for profiles until Monk release
function Env.Potion(itemID)
	local start, duration, enable = GetItemCooldown(itemID)
	-- Enable will be 0 for things like a potion that was used in combat 
	if enable ~= 0 and (duration == 0 or duration - (TMW.time - start) == 0)  then
        return true
    end    
    return false 
end 
function Env.PvP.GetAuraList(key)
    return GetAuraList(key)
end 
function Env.PvP.GetItemList(ket)
    return ItemList[key]
end 
--- ===================== 1.0 REFFERENCE (OLD) ======================
function Env.PvPKarma(unit) 
    -- True: Is not applied / False: Applied
    return Unit(unit):WithOutKarmed()
end
function Env.PvPDeBuffs(unit, spells)    
    return Unit(unit):HasDeBuffs(spells)
end
function Env.PvPBuffs(unit, spells) 
    return Unit(unit):HasBuffs(spells)     
end
-- DamagerBurst
function Env.PvPUseBurst(unit, Assist, EnemyHealerInCC)
    return Unit(unit or "target"):UseBurst()              
end
function Env.PvPNeedDeff(unit)
    return Unit(unit or "player"):UseDeff()
end
function Env.PvPTargeting(unit)
    return Unit(unit):IsFocused()
end
function Env.PvPTargeting_Melee(unit, burst)   
    return Unit(unit):IsFocused("MELEE")
end
function Env.PvPTargeting_BySpecs(array, specs, unit, range, burst)
    return Unit(unit):IsFocused(specs, burst, nil, range)
end
function Env.PvPExecuteRisk(unit)
    return Unit(unit):IsExecuted()
end
-- Helper
function Env.PvPEnemyUsedBurst(range) 
    return EnemyTeam("DAMAGER"):GetBuffs("DamageBuffs", type(range) == "number" and range or nil)
end
function Env.PvPEnemyBurst(unit, checkdeff)
    if unit == "HEALER" then
        return FriendlyTeam(unit):HealerIsFocused(true, checkdeff)
    else 
        return Unit(unit):IsFocused(nil, true, checkdeff)
    end 
end
function Env.PvPEnemyHealerID()
    return EnemyTeam("HEALER"):GetUnitID()
end
function Env.PvPFriendlyHealerID()
    return FriendlyTeam("HEALER"):GetUnitID()
end
function Env.PvPEnemyHealerInRange(range)
    local unit = EnemyTeam("HEALER"):GetUnitID(range)
    return (unit ~= "none" and unit) or false
end
function Env.PvPEnemyHealerInCC(duration)
    if not duration then duration = 3 end
    return EnemyTeam("HEALER"):GetCC() >= duration
end
function Env.PvPFriendlyHealerInCC(duration)
    if not duration then duration = 3 end;    
    return FriendlyTeam("HEALER"):GetCC() >= duration
end
function Env.Get_PvPFriendlyHealerInCC()  
    return FriendlyTeam("HEALER"):GetCC()
end
function Env.Get_PvPFriendlyHealerInCC_DeBuffs(id, range)  
    local DURATION, UNIT = FriendlyTeam("HEALER"):GetDeBuffs(id, range)
    return DURATION, UNIT
end
function Env.PvPUnitIsHealer(unit)
    return Unit(unit):IsHealer() 
end
function Env.PvPEnemyIsHealer(unit)
    return Unit(unit):IsHealer() 
end
function Env.PvPEnemyIsMelee(unit)
    return Unit(unit):IsMelee() 
end
function Env.PvPUnitIsMelee(unit)
    return Unit(unit):IsMelee() 
end
function Env.PvPAssist() 
    return Unit("target"):IsFocused(nil, true)
end 
-- BreakAble 
function Env.PvPBreakAble(range) 
    return EnemyTeam():IsBreakAble(range) 
end
-- Taunt 
function Env.PvPTauntPet(id)
    return EnemyTeam():IsTauntPetAble(id) 
end 
-- Raid/Group
function Env.CheckRaidDeBuffs(id)
    return FriendlyTeam():GetDeBuffs(id) > 0   
end
function Env.CheckRaidTTD(count, seconds)
    if not count then count = 1 end
    if not seconds then seconds = 4 end   
    return FriendlyTeam():GetTTD(count, seconds) 
end
function Env.ArcaneTorrentMindControl()
    return FriendlyTeam():GetBuffs(605, 8) > 0 
end
-- CastBars
function Env.PvPCatchReshift(offset)
    return EnemyTeam():IsReshiftAble(offset) 
end
function Env.PvPMultiCast(unit, spells, range)
    local total, tleft, pleft, id, spellname = Env.MultiCast(unit, spells, range)   
    return total, tleft, pleft, id, spellname
end

-------------------------------------------------------------------------------
-- HealingEngine
-------------------------------------------------------------------------------
function GetMembers()
    return HealingEngineMembersALL
end 
function MostlyIncDMG(unitID)
    return HealingEngine.IsMostlyIncDMG(unitID)
end 
function Group_incDMG()
    return select(2, HealingEngine.GetIncomingDMG())
end
function Group_getHEAL()
    return select(2, HealingEngine.GetIncomingHPS())
end
function FrequencyAHP(timer)    
    return HealingEngine.GetHealthFrequency(timer)
end 
function AoETTD(timer)
    return HealingEngine.GetTimeToDieUnits(timer)   
end
function AoEBuffsExist(ID, duration)
	return HealingEngine.GetBuffsCount(ID, duration)
end
function AoEHP(pHP)
    return HealingEngine.GetBelowHealthPercentUnits(pHP) 
end
function AoEHealingByRange(range, predictName, isMelee)
	return HealingEngine.HealingByRange(range, predictName, nil, isMelee)
end
function AoEHealingBySpell(spell, predictName, isMelee) 
	return HealingEngine.HealingBySpell(predictName, spell, isMelee)
end
-- Deprecated
function ValidMembers(IsPlayer)
	if not IsPlayer or not _G.HE_Pets then 
		return #HealingEngineMembersALL
	else 
		local total = 0 
		if #HealingEngineMembersALL > 0 then 
			for i = 1, #HealingEngineMembersALL do
				if Unit(HealingEngineMembersALL[i].Unit):IsPlayer() then
					total = total + 1
				end
			end 
		end 
		return total 
	end 
end
function AoEMembers(IsPlayer, SubStract, Limit)
    if not SubStract then SubStract = 1 end 
    if not Limit then Limit = 4 end
    local ValidUnits = ValidMembers(IsPlayer)
    return 
    ( ValidUnits <= 1 and 1 ) or    
    ( ValidUnits <= 3 and 2 ) or 
    ( ValidUnits <= 5 and ValidUnits - SubStract ) or 
    ( 
        ValidUnits > 5 and 
        (
            (
                Limit <= ValidUnits and 
                Limit 
            ) or 
            (
                Limit > ValidUnits and 
                ValidUnits
            )
        )
    )
end
function AoEHPAvg(isPlayer, minCount)
    local total, maxhp, counter = 0, 0, 0
    if tableexist(HealingEngineMembersALL) then 
        for i = 1, #HealingEngineMembersALL do
            if (not isPlayer or Unit(HealingEngineMembersALL[i].Unit):IsPlayer()) then                
                total = total + UnitHealth(HealingEngineMembersALL[i].Unit)
                maxhp = maxhp + UnitHealthMax(HealingEngineMembersALL[i].Unit)
                counter = counter + 1
            end
        end
        if total > 0 and (not minCount or counter >= minCount) then 
            total = total * 100 / maxhp
        end 
    end
    return total  
end
-- Restor Druid 
function Env.AoEFlourish(pHP)   
	local total = 0
	for i = 1, #HealingEngineMembersALL do
		if HealingEngineMembersALL[i].HP <= pHP and
		-- Rejuvenation
		Unit(HealingEngineMembersALL[i].Unit):HasBuffs(774) > 0 and 
		(
			-- Wild Growth
			Unit(HealingEngineMembersALL[i].Unit):HasBuffs(48438) > 0 or 
			-- Lifebloom or Regrowth or Germination
			Unit(HealingEngineMembersALL[i].Unit):HasBuffs({33763, 8936, 155777}) > 0 
		)
		then
			total = total + 1
		end
	end
	return total >= #HealingEngineMembersALL * 0.3
end
-- PVE Dispels
-- NOTE: RETIRED VERSION HAS > INSTEAD OF ACTUAL >=
local types = {
    Poison = {
		-- 8.3 Heartpiercer Venom
		{ id = 316506, dur = 0.5, stack = 0, byID = true },
		-- 8.3 Mind-Numbing Toxin
		{ id = 314593, dur = 0, stack = 0, byID = true },
		-- 8.3 Volatile Rupture
		{ id = 314467, dur = 1.49, stack = 0, byID = true },
        -- Venomfang Strike
        { id = 252687, dur = 0, stack = 0},
        -- Hidden Blade
        { id = 270865, dur = 0, stack = 0},
        -- Embalming Fluid 
        { id = 271564, dur = 0, stack = 2},
        -- Poison Barrage 
        { id = 270507, dur = 0, stack = 0},
        -- Neurotoxin 
        { id = 273563, dur = 1.49, stack = 0},
        -- Cytotoxin 
        { id = 267027, dur = 0, stack = 2},
        -- Venomous Spit
        { id = 272699, dur = 0, stack = 0},
        -- Widowmaker Toxin
        { id = 269298, dur = 0, stack = 2}, 
        -- Stinging Venom
        { id = 275836, dur = 0, stack = 4},  
		-- Crippling Shiv
		{ id = 257777, dur = 0, stack = 0},
    },
    Disease = {
		-- 8.3 Lingering Nausea
		{ id = 250372, dur = 0, stack = 0, byID = true },
		-- 8.3 Crippling Pestilence
		{ id = 314406, dur = 0, stack = 0, byID = true },		
		-- 8.2 Mechagon - Consuming Slime
		{ id = 300659, dur = 0, stack = 0},		
		-- 8.2 Mechagon - Gooped
		{ id = 298124, dur = 0, stack = 0},
		-- 8.2 Mechagon - Suffocating Smog
		{ id = 300650, dur = 0, stack = 0, byID = true },
		-- 8.0.1 Severing Serpent
		{ id = 264520, dur = 0, stack = 0, byID = true },
		-- 8.0.1 Infected Thorn
		{ id = 264050, dur = 0, stack = 0, byID = true },
        -- Infected Wound
        { id = 258323, dur = 0, stack = 1},
        -- Plague Step
        { id = 257775, dur = 0, stack = 0},
        -- Wretched Discharge
        { id = 267763, dur = 0, stack = 0},
        -- Festering Bite
        { id = 263074, dur = 0, stack = 0},
        -- Decaying Mind
        { id = 278961, dur = 0, stack = 0},
        -- Decaying Spores
        { id = 259714, dur = 0, stack = 1},
		-- Decaying Spores
		{ id = 273226, dur = 0, stack = 1},
		-- Rotting Wounds
		{ id = 272588, dur = 0, stack = 0 },
    }, 
    Curse = {
        -- Wracking Pain
        { id = 250096, dur = 0, stack = 0},
        -- Pit of Despair
        { id = 276031, dur = 0, stack = 0},
        -- Hex 
        { id = 270492, dur = 0, stack = 0},
        -- Cursed Slash
        { id = 257168, dur = 0, stack = 2},
        -- Withering Curse
        { id = 252687, dur = 0, stack = 2},
    },
    Magic = {
		-- 8.3 Wildfire
		{ id = 253562, dur = 1.49, stack = 0, byID = true },
		-- 8.3 Heart of Darkness
		{ id = 307645, byID = true, dur = 1.49, stack = 0 },
		-- 8.3 Annihilation
		{ id = 310224, dur = 0, stack = 7, byID = true },
		-- 8.3 Recurring Nightmare
		{ id = 312486, dur = 0, stack = 0, byID = true },	
		-- 8.3 Corrupted Mind
		{ id = 313400, dur = 0, stack = 0, byID = true },	
		-- 8.3 Mind Flay
		{ id = 314592, dur = 1.49, stack = 0, byID = true },
		-- 8.3 Cascading Terror
		{ id = 314483, dur = 0, stack = 0 },	
		-- 8.3 Unleashed Insanity
		{ id = 310361, dur = 0, stack = 0, byID = true },
		-- 8.3 Psychic Scream
		{ id = 308375, dur = 0, stack = 0, byID = true },
		-- 8.3 Void Buffet
		{ id = 297315, dur = 1.49, stack = 0, byID = true },
		-- 8.3 Split Personality
		{ id = 316510, dur = 1.49, stack = 0, byID = true },
		-- 8.2 Mechagon - Blazing Chomp
		{ id = 294929, dur = 0, stack = 0 },		
		-- 8.2 Mechagon - Shrink
		{ id = 299572, dur = 0, stack = 0 },
		-- 8.2 Mechagon - Arcing Zap
		{ id = 294195, dur = 0, stack = 0 },
		-- 8.2 Mechagon - Discom-BOMB-ulator
		{ id = 285460, dur = 0, stack = 0 },
		-- 8.2 Mechagon - Flaming Refuse
		{ id = 294180, dur = 0, stack = 0 },
		-- 8.2 Mechagon - Capacitor Discharge
		{ id = 295168, dur = 0, stack = 0 },
		-- 8.2 Queen Azshara - Arcane Burst
		{ id = 303657, dur = 10, stack = 0 },
		-- 8.2 Za'qul - Dread
		{ id = 292963, dur = 0, stack = 0 },
		-- 8.2 Za'qul - Shattered Psyche
		{ id = 295327, dur = 0, stack = 0 },		
		-- 8.2 Radiance of Azshara - Arcane Bomb
		-- { id = 296746, dur = 0, stack = 0 }, -- need predict unit position to dispel only when they are out of raid 
		-- 8.0.1 Toad Blight
		{ id = 265352, dur = 0.5, stack = 0, byID = true },	
		-- 8.0.1 Freezing Trap
		{ id = 278468, dur = 0, stack = 0, byID = true },
		-- 8.0.1 Frost Shock
        { id = 270499, dur = 0, stack = 0, byID = true },
		-- 8.0.1 Maddening Gaze
		{ id = 272609, dur = 1, stack = 0, byID = true },
		-- The Restless Cabal - Promises of Power 
		{ id = 282562, dur = 0, stack = 2 },
		-- Jadefire Masters - Searing Embers
		{ id = 286988, dur = 0, stack = 0 },
		-- Conclave of the Chosen - Mind Wipe
		{ id = 285878, dur = 0, stack = 0 },
		-- Lady Jaina - Grasp of Frost
		{ id = 287626, dur = 0, stack = 0 },
		-- Whispers of Power
		{ id = 267034, dur = 0, stack = 4 },
		-- Whispers of Power
		{ id = 267037, dur = 0, stack = 4 },
		-- Righteous Flames
		{ id = 258917, dur = 0, stack = 0 },
		-- Suppression Fire
		{ id = 258864, dur = 0, stack = 0 },
		-- Lady Jaina - Hand of Frost
		{ id = 288412, dur = 0, stack = 0 },
        -- Molten Gold
        { id = 255582, dur = 0, stack = 0},
        -- Terrifying Screech
        { id = 255041, dur = 0, stack = 0},
        -- Terrifying Visage
        { id = 255371, dur = 0, stack = 0},
        -- Oiled Blade
        { id = 257908, dur = 0, stack = 0},
        -- Choking Brine
        { id = 264560, dur = 0, stack = 0},
		-- Electrifying Shock
		{ id = 268233, dur = 0, stack = 0},
        -- Touch of the Drowned (if no party member is afflicted by Mental Assault (268391))
        { id = 268322, dur = 0, stack = 0},
        -- Mental Assault 
        { id = 268391, dur = 0, stack = 0},
		-- Wicked Assault
		{ id = 266265, dur = 1.5, stack = 0},
        -- Explosive Void
        { id = 269104, dur = 0, stack = 0},
        -- Choking Waters
        { id = 272571, dur = 0, stack = 0},
        -- Putrid Waters
        { id = 274991, dur = 0, stack = 0},
        -- Flame Shock (if no party member is afflicted by Snake Charm (268008))
        { id = 268013, dur = 0, stack = 0},
        -- Snake Charm
        { id = 268008, dur = 0, stack = 0},
        -- Brain Freeze
        { id = 280605, dur = 1.49, stack = 0},
        -- Transmute: Enemy to Goo
        { id = 268797, dur = 0, stack = 0},
        -- Chemical Burn
        { id = 259856, dur = 0, stack = 0},
        -- Debilitating Shout
        { id = 258128, dur = 0, stack = 0},
        -- Torch Strike 
        { id = 265889, dur = 0, stack = 1},
        -- Fuselighter 
        { id = 257028, dur = 0, stack = 0},
        -- Death Bolt 
        { id = 272180, dur = 0, stack = 0},
        -- Putrid Blood
        { id = 269301, dur = 0, stack = 1},
        -- Grasping Thorns
        { id = 263891, dur = 0, stack = 0},
        -- Fragment Soul
        { id = 264378, dur = 0, stack = 0},
        -- Putrid Waters
        { id = 275014, dur = 0, stack = 0},
		-- Legion: Touch of Corruption
		{ id = 209469, dur = 0, stack = 0, byID = true },		
    }, 
}
local UnitAuras = {
    -- Restor Druid 
    [105] = {
        types.Poison,
        types.Curse,
        types.Magic,
    },
    -- Balance
    [102] = {
        types.Curse,
    },
    -- Feral
    [103] = {
        types.Curse,
    },
    -- Guardian
    [104] = {
        types.Curse,
    },
    -- Arcane
    [62] = {
        types.Curse,
    },
    -- Fire
    [63] = {
        types.Curse,
    },
    -- Frost
    [64] = {
        types.Curse,
    },
    -- Mistweaver
    [270] = {
        types.Poison,
        types.Disease,
        types.Magic,
    },
    -- Windwalker
    [269] = {
        types.Poison,
        types.Disease,
    },
    -- Brewmaster
    [268] = {
        types.Poison,
        types.Disease,
    },
    -- Holy Paladin
    [65] = {
        types.Poison,
        types.Disease,
        types.Magic,
    },
    -- Protection Paladin
    [66] = {
        types.Poison,
        types.Disease,
    },
    -- Retirbution Paladin
    [70] = {
        types.Poison,
        types.Disease,
    },
    -- Discipline Priest 
    [256] = {
        types.Disease,
        types.Magic,
    }, 
    -- Holy Priest 
    [257] = {
        types.Disease,
        types.Magic,
    }, 
    -- Shadow Priest 
    [258] = {
        types.Disease,
    },
    -- Elemental
    [262] = {
        types.Curse,
    },
    -- Enhancement
    [263] = {
        types.Curse,
    },
    -- Restoration
    [264] = {
        types.Curse,
        types.Magic,
    },
    -- Affliction
    [265] = {
        types.Magic,
    },
    -- Demonology
    [266] = {
        types.Magic,
    },
    -- Destruction
    [267] = {
        types.Magic,
    },
}
function Env.PvEDispel(unit)
	if not Env.InPvP() and UnitAuras[A.PlayerSpec] then 
        for k, v in pairs(UnitAuras[A.PlayerSpec]) do 
            for _, Spell in ipairs(v) do 
                duration = (Spell.dur == 0 and GetGCD() + GetCurrentGCD()) or Spell.dur
                -- Exception 
                -- Touch of the Drowned (268322, if no party member is afflicted by Mental Assault (268391))
                -- Flame Shock (268013, if no party member is afflicted by Snake Charm (268008))
                -- Putrid Waters (275014, don't dispel self)
                if Spell.stack == 0 then 
                    if Unit(unit):HasDeBuffs(Spell.id, nil, Spell.byID) > duration then 
                        if 	(Spell.id ~= 268322 or FriendlyTeam():GetDeBuffs(268391) == 0) and 
							(Spell.id ~= 268013 or FriendlyTeam():GetDeBuffs(268008) == 0) and 
							(Spell.id ~= 275014 or not UnitIsUnit("player", unit)) and 
							(Spell.id ~= 268233 or A.ZoneID ~= 1490) 
						then 
                            return true 
                        end
                    end 
                else
                    if Unit(unit):HasDeBuffs(Spell.id, nil, Spell.byID) > duration and Unit(unit):HasDeBuffsStacks(Spell.id, nil, true) > Spell.stack then 
                        if 	(Spell.id ~= 268322 or FriendlyTeam():GetDeBuffs(268391) == 0) and 
							(Spell.id ~= 268013 or FriendlyTeam():GetDeBuffs(268008) == 0) and 
							(Spell.id ~= 275014 or not UnitIsUnit("player", unit)) and 
							(Spell.id ~= 268233 or A.ZoneID ~= 1490)
						then 
                            return true 
                        end
                    end 
                end                 
            end 
        end 
    end 
    return false 
end 

-------------------------------------------------------------------------------
-- CombatTracker
-------------------------------------------------------------------------------	  
function CombatTime(UNIT)
    return Unit(UNIT):CombatTime()
end
function getRealTimeDMG(UNIT)
	return Unit(UNIT):GetRealTimeDMG()
end 
function getRealTimeDPS(UNIT)
	return Unit(UNIT):GetRealTimeDPS()
end 
function getDMG(UNIT)
    return Unit(UNIT):GetDMG()
end 
function getDPS(UNIT)
	return Unit(UNIT):GetDPS()
end 
function getHEAL(UNIT)
    return Unit(UNIT):GetHEAL()   
end
function getHPS(UNIT) 
    return Unit(UNIT):GetHPS()      
end 
function getHealSpellAmount(UNIT, SPELL, TIMER)
    return Unit(UNIT):GetSpellAmountX(SPELL, TIMER)
end
function SpellAmount(UNIT, spellID)
    return Unit(UNIT):GetSpellAmount(spellID)
end
function getAbsorb(UNIT, spellID)
    return Unit(UNIT):GetAbsorb(spellID)
end 
function TimeToDieX(UNIT, X)
    return Unit(UNIT or "target"):TimeToDieX(X or 25)
end
function TimeToDie(UNIT)
    return Unit(UNIT or "target"):TimeToDie()
end
function TimeToDieMagicX(UNIT, X)
    return Unit(UNIT or "target"):TimeToDieMagicX(X or 25)
end
function TimeToDieMagic(UNIT)
    return Unit(UNIT or "target"):TimeToDieMagic()
end
function SpellLastCast(UNIT, SPELL, byID)
	local _, timestamp = Unit(UNIT):GetSpellLastCast(SPELL, byID)
	return timestamp
end 
function SpellTimeSinceLastCast(UNIT, SPELL, byID)
	return Unit(UNIT):GetSpellLastCast(SPELL, byID)
end 
function SpellCounter(UNIT, SPELL, byID)
    return Unit(UNIT):GetSpellCounter(SPELL, byID)
end 
function GetShrimmer(UNIT)
	return Unit(UNIT):GetBlinkOrShrimmer()
end 
function getDR(UNIT, drCat) 
	return Unit(UNIT):GetDR(drCat)
end 
function LastIncDMG(unit, seconds)
    return Unit(unit):GetLastTimeDMGX(seconds)
end
function incdmg(unit)
    return Unit(unit):GetDMG()
end
function incdmgphys(unit)
    return Unit(unit):GetDMG(3)
end
function incdmgmagic(unit)
    return Unit(unit):GetDMG(4)
end
function LossOfControlCreate()
end 
function LossOfControlRemove()
end 
function LossOfControlIsMissed(mustBeMissed)
	return LoC:IsMissed(mustBeMissed)
end 
function LossOfControlGet(locType, name)
	return LoC:Get(locType, name)
end 

-------------------------------------------------------------------------------
-- MultiUnits
-------------------------------------------------------------------------------	  
function GetActiveUnitPlates(reaction)
	-- @return table or nil 
	return ActiveUnitPlates	
end 

function CombatUnits(stop, range, upttd)
	-- @return boolean if stop noted, otherwise number
    return (stop and MultiUnits:GetByRangeInCombat(range, stop, upttd) >= stop) or (not stop and MultiUnits:GetByRangeInCombat(range or 40, nil, upttd))
end

function CastingUnits(stop, range, kickAble)
	-- @return boolean if stop noted, otherwise number
	return (stop and MultiUnits:GetByRangeCasting(range, stop, kickAble) >= stop) or (not stop and MultiUnits:GetByRangeCasting(range or 40, nil, kickAble))
end 

function MassTaunt(stop, range, ttd)
	-- @return boolean if stop noted, otherwise number
    return (stop and MultiUnits:GetByRangeTaunting(range, stop, upttd or 10) >= stop) or (not stop and MultiUnits:GetByRangeTaunting(range or 40, nil, upttd or 10))
end

function PvPMassTaunt(stop, range, outrange)
	-- @return boolean if stop noted, otherwise number
    local totalmobs = 0
    if not range then range = 40 end
    if not outrange then outrange = 8 end       
	for unitID in pairs(ActiveUnitPlates) do
		if Unit(unitID):IsPlayer() and Unit(unitID):GetRange() >= outrange and Unit(unitID):CanInterract(range) then 
			totalmobs = totalmobs + 1            
			
			if stop and totalmobs >= stop then                    
				break
			end    
		end
	end           
    return (stop and totalmobs >= stop) or (not stop and totalmobs)
end

function MultiDots(range, dots, ttd, stop)
	-- @return number 
    return MultiUnits:GetByRangeMissedDoTs(range, stop, dots, ttd)
end

function UnitsDots(stop, dots, range, ttd)
	-- @return boolean if stop noted, otherwise number
	return (stop and MultiUnits:GetByRangeAppliedDoTs(range, stop, dots, ttd) >= stop) or (not stop and MultiUnits:GetByRangeAppliedDoTs(range, stop, dots, ttd))
end

local function GetMobsBySpell(count, spellId, reaction)
	if reaction == "friendly" then 
		return 0
	end 
    return MultiUnits:GetBySpell(spellId, count)
end

local function GetMobsByRange(count, range, reaction)
	if reaction == "friendly" then 
		return 0
	end 
    return MultiUnits:GetByRange(range)
end

function AoE(count, num, reaction) 
    if not reaction  then reaction = "enemy" end  
    if not num 	 then num = 40 end 
	
	local units 
	if num <= ACTION_CONST_CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE then
		units = GetMobsByRange(count, num, reaction)
	else 
		units = GetMobsBySpell(count, num, reaction)
	end                         
               
    if not count then
        return units or 0
    else
        return units and units >= count
    end    
end

function active_enemies()   
	return MultiUnits:GetActiveEnemies(4.5)
end

-------------------------------------------------------------------------------
-- PetLib
-------------------------------------------------------------------------------
function Env.PetSpellInRange(spell, unitID)
	return Pet:IsInRange(spell, unitID)
end 
function Env.PetIsActive()
    return Pet:IsActive()
end
function Env.PetAoE(spellID, stop)
	return Pet:GetMultiUnitsBySpell(spellID, stop)
end 

-------------------------------------------------------------------------------
-- Misc
-------------------------------------------------------------------------------
--[[
local scanTip = CreateFrame("GameTooltip", "Scanner", UIParent, "GameTooltipTemplate")
local scanLine
function ScanToolTip(spellID)
    scanTip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTip:SetSpellByID(spellID)
    scanLine = ScannerTextLeft3
    local t = scanLine:GetText()
    if (not t) then return end
    
    local numbers = {}
    for i=1,Scanner:NumLines() do
        local tooltipText = _G["ScannerTextLeft"..i]:GetText()
        tooltipText = string.gsub( tooltipText, "%p", '' )
        tooltipText = string.gsub( tooltipText, "%s", '' )
        
        for num in string.gmatch(tooltipText, "%d+") do
            table.insert(numbers, num)
        end
    end
    
    scanTip:Hide()
    return numbers
end
]]