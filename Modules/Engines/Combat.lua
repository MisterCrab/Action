local _G, type, pairs, table, next, math =
	  _G, type, pairs, table, next, math

local TMW 										= _G.TMW
local A 										= _G.Action
local CONST 									= A.Const
local Listener									= A.Listener
local isEnemy									= A.Bit.isEnemy
local isPlayer									= A.Bit.isPlayer
local BuildToC									= A.BuildToC
local TeamCache									= A.TeamCache
local TeamCacheFriendly							= TeamCache.Friendly
local TeamCacheFriendlyUNITs					= TeamCacheFriendly.UNITs
local TeamCacheFriendlyGUIDs					= TeamCacheFriendly.GUIDs
local TeamCacheFriendlyIndexToPLAYERs			= TeamCacheFriendly.IndexToPLAYERs
--local TeamCacheFriendlyIndexToPETs			= TeamCacheFriendly.IndexToPETs
local TeamCacheEnemy							= TeamCache.Enemy
local TeamCacheEnemyUNITs						= TeamCacheEnemy.UNITs
--local TeamCacheEnemyGUIDs						= TeamCacheEnemy.GUIDs
local TeamCacheEnemyIndexToPLAYERs				= TeamCacheEnemy.IndexToPLAYERs
--local TeamCacheEnemyIndexToPETs				= TeamCacheEnemy.IndexToPETs
local skipedFirstEnter 							= false

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_GetSpellInfo, A_Player, A_Unit, A_CombatTracker, A_GetCurrentGCD, A_GetGCD, ActiveNameplates

Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then
		A_GetSpellInfo							= A.GetSpellInfo
		A_Player								= A.Player
		A_Unit									= A.Unit
		A_CombatTracker							= A.CombatTracker
		A_GetCurrentGCD							= A.GetCurrentGCD
		A_GetGCD 								= A.GetGCD
		ActiveNameplates						= A.MultiUnits:GetActiveUnitPlates()

		Listener:Remove("ACTION_EVENT_COMBAT_TRACKER", "ADDON_LOADED")
	end
end)
-------------------------------------------------------------------------------

-- [[ Retail ]]
local DRData 									= LibStub("DRList-1.0")
--

local tinsert	  								= table.insert
local tremove	  								= table.remove
local huge 										= math.huge
local abs										= math.abs
local math_max									= math.max
local bit										= _G.bit
local bitband									= bit.band
local wipe 										= _G.wipe
local strsub									= _G.strsub

local 	 UnitIsUnit, 	UnitGUID, 	 UnitGetTotalAbsorbs, 	 UnitAffectingCombat =
	  _G.UnitIsUnit, _G.UnitGUID, _G.UnitGetTotalAbsorbs, _G.UnitAffectingCombat

local 	 InCombatLockdown, 	  CombatLogGetCurrentEventInfo =
	  _G.InCombatLockdown, _G.CombatLogGetCurrentEventInfo

local GetSpellName 								= _G.C_Spell and _G.C_Spell.GetSpellName or _G.GetSpellInfo

local cLossOfControl 							= _G.C_LossOfControl
local GetEventInfo 								= cLossOfControl.GetEventInfo or cLossOfControl.GetActiveLossOfControlData
local GetNumEvents 								= cLossOfControl.GetNumEvents or cLossOfControl.GetActiveLossOfControlDataCount

local  CreateFrame,    UIParent					=
	_G.CreateFrame, _G.UIParent

local function GetGUID(unitID)
	return (unitID and (TeamCacheFriendlyUNITs[unitID] or TeamCacheEnemyUNITs[unitID])) or UnitGUID(unitID)
end

local function GetGroupMaxSize(group)
	if group == "arena" then
		return TeamCacheEnemy.MaxSize
	else
		return TeamCacheFriendly.MaxSize
	end
end

local function IsFriendlyHunterIsGUID(GUID)
	-- @return boolean
	-- Note: We have to use this for Unit.lua to determine if hunter is melee or not by some of used specified surv spec spells
	local unitID = TeamCacheFriendlyGUIDs[GUID]
	return unitID and A_Unit(unitID):Class() == "HUNTER"
end

-------------------------------------------------------------------------------
-- Locals: CombatTracker
-------------------------------------------------------------------------------
local CombatTracker 							= {
	Data			 						= {},
	Doubles 								= {
		[3]  								= "Holy + Physical",
		[5]  								= "Fire + Physical",
		[9]  								= "Nature + Physical",
		[17] 								= "Frost + Physical",
		[33] 								= "Shadow + Physical",
		[65] 								= "Arcane + Physical",
		[127]								= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
	},
	SchoolDoubles							= {
		Holy								= {
			[2]								= "Holy",
			[3]								= "Holy + Physical",
			[6]								= "Fire + Holy",
			[10]							= "Nature + Holy",
			[18]							= "Frost + Holy",
			[34]							= "Shadow + Holy",
			[66]							= "Arcane + Holy",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
		Fire								= {
			[4]								= "Fire",
			[5]								= "Fire + Physical",
			[6]								= "Fire + Holy",
			[12]							= "Nature + Fire",
			[20]							= "Frost + Fire",
			[28]							= "Frost + Nature + Fire",
			[36]							= "Shadow + Fire",
			[68]							= "Arcane + Fire",
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
		Nature								= {
			[8]								= "Nature",
			[9]								= "Nature + Physical",
			[10]							= "Nature + Holy",
			[12]							= "Nature + Fire",
			[24]							= "Frost + Nature",
			[28]							= "Frost + Nature + Fire",
			[40]							= "Shadow + Nature",
			[72]							= "Arcane + Nature",
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
		Frost								= {
			[16]							= "Frost",
			[17]							= "Frost + Physical",
			[18]							= "Frost + Holy",
			[20]							= "Frost + Fire",
			[24]							= "Frost + Nature",
			[28]							= "Frost + Nature + Fire",
			[48]							= "Shadow + Frost",
			[80]							= "Arcane + Frost",
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
		Shadow								= {
			[32]							= "Shadow",
			[33]							= "Shadow + Physical",
			[34]							= "Shadow + Holy",
			[36]							= "Shadow + Fire",
			[40]							= "Shadow + Nature",
			[48]							= "Shadow + Frost",
			[96]							= "Arcane + Shadow",
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
		Arcane								= {
			[64]							= "Arcane",
			[65]							= "Arcane + Physical",
			[66]							= "Arcane + Holy",
			[68]							= "Arcane + Fire",
			[72]							= "Arcane + Nature",
			[80]							= "Arcane + Frost",
			[96]							= "Arcane + Shadow",
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
	},
	AddToData 								= function(self, GUID, timestamp)
		if not self.Data[GUID] then
			self.Data[GUID] 				= {
				-- For GC
				lastSeen					= timestamp,
				-- RealTime Damage
				-- Damage Taken
				RealDMG_dmgTaken 			= 0,
				RealDMG_dmgTaken_S 			= 0,
				RealDMG_dmgTaken_P 			= 0,
				RealDMG_dmgTaken_M 			= 0,
				RealDMG_hits_taken 			= 0,
				-- Damage Done
				RealDMG_dmgDone 			= 0,
				RealDMG_dmgDone_S 			= 0,
				RealDMG_dmgDone_P 			= 0,
				RealDMG_dmgDone_M 			= 0,
				RealDMG_hits_done 			= 0,
				-- Sustain Damage
				-- Damage Taken
				DMG_dmgTaken 				= 0,
				DMG_dmgTaken_S 				= 0,
				DMG_dmgTaken_P 				= 0,
				DMG_dmgTaken_M 				= 0,
				DMG_hits_taken 				= 0,
				DMG_lastHit_taken 			= 0,
				-- Damage Done
				DMG_dmgDone 				= 0,
				DMG_dmgDone_S 				= 0,
				DMG_dmgDone_P 				= 0,
				DMG_dmgDone_M 				= 0,
				DMG_hits_done 				= 0,
				DMG_lastHit_done 			= 0,
				-- Sustain Healing
				-- Healing taken
				HPS_heal_taken 				= 0,
				HPS_heal_hits_taken 		= 0,
				HPS_heal_lasttime 			= 0,
				-- Healing Done
				HPS_heal_done 				= 0,
				HPS_heal_hits_done 			= 0,
				HPS_heal_lasttime_done 		= 0,
				-- Shared
				combat_time 				= timestamp,
			}
			-- Taken damage by @player through specific schools
			if GUID == GetGUID("player") then
				self.Data[GUID].School		= {
					DMG_dmgTaken_Holy		= 0,
					DMG_dmgTaken_Holy_LH	= 0,
					DMG_dmgTaken_Fire		= 0,
					DMG_dmgTaken_Fire_LH	= 0,
					DMG_dmgTaken_Nature		= 0,
					DMG_dmgTaken_Nature_LH	= 0,
					DMG_dmgTaken_Frost		= 0,
					DMG_dmgTaken_Frost_LH	= 0,
					DMG_dmgTaken_Shadow		= 0,
					DMG_dmgTaken_Shadow_LH	= 0,
					DMG_dmgTaken_Arcane		= 0,
					DMG_dmgTaken_Arcane_LH	= 0,
				}
			end
		else
			self.Data[GUID].lastSeen 		= timestamp
			if self.Data[GUID].combat_time == 0 then
				self.Data[GUID].combat_time = timestamp
			end
		end
	end,
	CleanTableByTime						= function(t, time)
		local key_time = next(t)
		while key_time ~= nil and key_time < time do
			t[key_time] = nil
			key_time = next(t, key_time)
		end
	end,
	SummTableByTime							= function(t, time)
		local total = 0
		local key_time, key_value = next(t)
		while key_time ~= nil do
			if key_time >= time then
				total = total + key_value
			end
			key_time, key_value = next(t, key_time)
		end
		return total
	end,
}

local CombatTrackerData							= CombatTracker.Data
local CombatTrackerDoubles						= CombatTracker.Doubles
local CombatTrackerSchoolDoubles				= CombatTracker.SchoolDoubles
local CombatTrackerCleanTableByTime				= CombatTracker.CleanTableByTime
local CombatTrackerSummTableByTime				= CombatTracker.SummTableByTime

--[[ ENVIRONMENTAL ]]
CombatTracker.logEnvironmentalDamage			= function(...)
	local timestamp,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_,_, Amount = ... -- CombatLogGetCurrentEventInfo()
	-- Update last hit time
	-- Taken
	CombatTrackerData[DestGUID].DMG_lastHit_taken = timestamp

	-- Totals
	-- Taken
	CombatTrackerData[DestGUID].DMG_dmgTaken = CombatTrackerData[DestGUID].DMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].DMG_hits_taken = CombatTrackerData[DestGUID].DMG_hits_taken + 1

	-- Real Time Damage
	-- Taken
	CombatTrackerData[DestGUID].RealDMG_dmgTaken = CombatTrackerData[DestGUID].RealDMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].RealDMG_hits_taken = CombatTrackerData[DestGUID].RealDMG_hits_taken + 1

	-- Only Taken by Player
	if isPlayer(destFlags) then
		-- DS
		if not CombatTrackerData[DestGUID].DS then
			CombatTrackerData[DestGUID].DS = {}
		end
		CombatTrackerData[DestGUID].DS[timestamp] = (CombatTrackerData[DestGUID].DS[timestamp] or 0) + Amount
		-- DS - Garbage
		CombatTrackerCleanTableByTime(CombatTrackerData[DestGUID].DS, timestamp - 10)
	end
end

--[[ This Logs the damage for every unit ]]
CombatTracker.logDamage 						= function(...)
	local timestamp,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_, spellID, spellName, school, Amount = ... -- CombatLogGetCurrentEventInfo()
	-- Reset and clear
	-- Damage Done
	if timestamp - CombatTrackerData[SourceGUID].DMG_lastHit_done > 5 then
		CombatTrackerData[SourceGUID].DMG_dmgDone = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_S = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_P = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_M = 0
		CombatTrackerData[SourceGUID].DMG_hits_done = 0
	end

	-- Damage Taken
	if timestamp - CombatTrackerData[DestGUID].DMG_lastHit_taken > 5 then
		CombatTrackerData[DestGUID].DMG_dmgTaken = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_S = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_P = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_M = 0
		CombatTrackerData[DestGUID].DMG_hits_taken = 0
	end

	-- Real Time Damage Done
	if timestamp - CombatTrackerData[SourceGUID].DMG_lastHit_done > A_GetGCD() * 2 + 1 then
		CombatTrackerData[SourceGUID].RealDMG_dmgDone = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_S = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_M = 0
		CombatTrackerData[SourceGUID].RealDMG_hits_done = 0
	end

	-- Real Time Damage Taken
	if timestamp - CombatTrackerData[DestGUID].DMG_lastHit_taken > A_GetGCD() * 2 + 1 then
		CombatTrackerData[DestGUID].RealDMG_dmgTaken = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_S = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_M = 0
		CombatTrackerData[DestGUID].RealDMG_hits_taken = 0
	end

	-- School Damage Taken by @player
	if CombatTrackerData[DestGUID].School then
		-- Reset and clear
		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy_LH 	= 0
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy		= 0
		end

		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire_LH 	= 0
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire		= 0
		end

		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature_LH 	= 0
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature		= 0
		end

		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost_LH 	= 0
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost		= 0
		end

		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow_LH 	= 0
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow		= 0
		end

		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane_LH 	= 0
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane		= 0
		end

		-- Add and log
		if CombatTrackerSchoolDoubles.Holy[school] then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy_LH 	= timestamp
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy + Amount
		end

		if CombatTrackerSchoolDoubles.Fire[school] then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire_LH 	= timestamp
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire + Amount
		end

		if CombatTrackerSchoolDoubles.Nature[school] then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature_LH 	= timestamp
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature + Amount
		end

		if CombatTrackerSchoolDoubles.Frost[school] then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost_LH 	= timestamp
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost + Amount
		end

		if CombatTrackerSchoolDoubles.Shadow[school] then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow_LH 	= timestamp
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow + Amount
		end

		if CombatTrackerSchoolDoubles.Arcane[school] then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane_LH 	= timestamp
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane + Amount
		end
	end

	-- Filter by School
	if CombatTrackerDoubles[school] then
		-- Taken
		CombatTrackerData[DestGUID].DMG_dmgTaken_P = CombatTrackerData[DestGUID].DMG_dmgTaken_P + Amount
		CombatTrackerData[DestGUID].DMG_dmgTaken_M = CombatTrackerData[DestGUID].DMG_dmgTaken_M + Amount
		-- Done
		CombatTrackerData[SourceGUID].DMG_dmgDone_P = CombatTrackerData[SourceGUID].DMG_dmgDone_P + Amount
		CombatTrackerData[SourceGUID].DMG_dmgDone_M = CombatTrackerData[SourceGUID].DMG_dmgDone_M + Amount
		-- Real Time Damage - Taken
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = CombatTrackerData[DestGUID].RealDMG_dmgTaken_P + Amount
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_M = CombatTrackerData[DestGUID].RealDMG_dmgTaken_M + Amount
		-- Real Time Damage - Done
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = CombatTrackerData[SourceGUID].RealDMG_dmgDone_P + Amount
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_M = CombatTrackerData[SourceGUID].RealDMG_dmgDone_M + Amount
	elseif school == 1 then
		-- Pysichal
		-- Taken
		CombatTrackerData[DestGUID].DMG_dmgTaken_P = CombatTrackerData[DestGUID].DMG_dmgTaken_P + Amount
		-- Done
		CombatTrackerData[SourceGUID].DMG_dmgDone_P = CombatTrackerData[SourceGUID].DMG_dmgDone_P + Amount
		-- Real Time Damage - Taken
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = CombatTrackerData[DestGUID].RealDMG_dmgTaken_P + Amount
		-- Real Time Damage - Done
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = CombatTrackerData[SourceGUID].RealDMG_dmgDone_P + Amount
	else
		-- Magic
		-- Taken
		CombatTrackerData[DestGUID].DMG_dmgTaken_M = CombatTrackerData[DestGUID].DMG_dmgTaken_M + Amount
		-- Done
		CombatTrackerData[SourceGUID].DMG_dmgDone_M = CombatTrackerData[SourceGUID].DMG_dmgDone_M + Amount
		-- Real Time Damage - Taken
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_M = CombatTrackerData[DestGUID].RealDMG_dmgTaken_M + Amount
		-- Real Time Damage - Done
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_M = CombatTrackerData[SourceGUID].RealDMG_dmgDone_M + Amount
	end

	-- Update last hit time
	-- Taken
	CombatTrackerData[DestGUID].DMG_lastHit_taken = timestamp
	-- Done
	CombatTrackerData[SourceGUID].DMG_lastHit_done = timestamp

	-- Totals
	-- Taken
	CombatTrackerData[DestGUID].DMG_dmgTaken = CombatTrackerData[DestGUID].DMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].DMG_hits_taken = CombatTrackerData[DestGUID].DMG_hits_taken + 1
	-- Done
	CombatTrackerData[SourceGUID].DMG_hits_done = CombatTrackerData[SourceGUID].DMG_hits_done + 1
	CombatTrackerData[SourceGUID].DMG_dmgDone = CombatTrackerData[SourceGUID].DMG_dmgDone + Amount

	-- Real Time Damage
	-- Taken
	CombatTrackerData[DestGUID].RealDMG_dmgTaken = CombatTrackerData[DestGUID].RealDMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].RealDMG_hits_taken = CombatTrackerData[DestGUID].RealDMG_hits_taken + 1
	-- Done
	CombatTrackerData[SourceGUID].RealDMG_dmgDone = CombatTrackerData[SourceGUID].RealDMG_dmgDone + Amount
	CombatTrackerData[SourceGUID].RealDMG_hits_done = CombatTrackerData[SourceGUID].RealDMG_hits_done + 1

	-- Only Taken by Player
	if isPlayer(destFlags) then
		-- Spells
		if not CombatTrackerData[DestGUID].spell_value then
			CombatTrackerData[DestGUID].spell_value = {}
		end

		if not CombatTrackerData[DestGUID].spell_value[spellID] then
			CombatTrackerData[DestGUID].spell_value[spellID] = {}
			if spellName and not CombatTrackerData[DestGUID].spell_value[spellName] then
				CombatTrackerData[DestGUID].spell_value[spellName] = CombatTrackerData[DestGUID].spell_value[spellID]
			end
		end
		CombatTrackerData[DestGUID].spell_value[spellID].TIME 		= timestamp
		CombatTrackerData[DestGUID].spell_value[spellID].Amount		= Amount

		-- DS
		if not CombatTrackerData[DestGUID].DS then
			CombatTrackerData[DestGUID].DS = {}
		end
		CombatTrackerData[DestGUID].DS[timestamp] = (CombatTrackerData[DestGUID].DS[timestamp] or 0) + Amount
		-- DS - Garbage
		CombatTrackerCleanTableByTime(CombatTrackerData[DestGUID].DS, timestamp - 10)
	end
end

--[[ This Logs the swings (damage) for every unit ]]
CombatTracker.logSwing 							= function(...)
	local timestamp,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_, Amount = ... -- CombatLogGetCurrentEventInfo()
	-- Reset and clear
	-- Damage Done
	if timestamp - CombatTrackerData[SourceGUID].DMG_lastHit_done > 5 then
		CombatTrackerData[SourceGUID].DMG_dmgDone = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_S = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_P = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_M = 0
		CombatTrackerData[SourceGUID].DMG_hits_done = 0
	end

	-- Damage Taken
	if timestamp - CombatTrackerData[DestGUID].DMG_lastHit_taken > 5 then
		CombatTrackerData[DestGUID].DMG_dmgTaken = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_S = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_P = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_M = 0
		CombatTrackerData[DestGUID].DMG_hits_taken = 0
	end

	-- Real Time Damage Done
	if timestamp - CombatTrackerData[SourceGUID].DMG_lastHit_done > A_GetGCD() * 2 + 1 then
		CombatTrackerData[SourceGUID].RealDMG_dmgDone = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_S = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_M = 0
		CombatTrackerData[SourceGUID].RealDMG_hits_done = 0
	end

	-- Real Time Damage Taken
	if timestamp - CombatTrackerData[DestGUID].DMG_lastHit_taken > A_GetGCD() * 2 + 1 then
		CombatTrackerData[DestGUID].RealDMG_dmgTaken = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_S = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_M = 0
		CombatTrackerData[DestGUID].RealDMG_hits_taken = 0
	end

	-- Update last  hit time
	CombatTrackerData[DestGUID].DMG_lastHit_taken = timestamp
	CombatTrackerData[SourceGUID].DMG_lastHit_done = timestamp

	-- Damage
	CombatTrackerData[DestGUID].DMG_dmgTaken_P = CombatTrackerData[DestGUID].DMG_dmgTaken_P + Amount
	CombatTrackerData[DestGUID].DMG_dmgTaken = CombatTrackerData[DestGUID].DMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].DMG_hits_taken = CombatTrackerData[DestGUID].DMG_hits_taken + 1
	CombatTrackerData[SourceGUID].DMG_dmgDone_P = CombatTrackerData[SourceGUID].DMG_dmgDone_P + Amount
	CombatTrackerData[SourceGUID].DMG_dmgDone = CombatTrackerData[SourceGUID].DMG_dmgDone + Amount
	CombatTrackerData[SourceGUID].DMG_hits_done = CombatTrackerData[SourceGUID].DMG_hits_done + 1

	-- Real Time Damage
	-- Taken
	CombatTrackerData[DestGUID].RealDMG_dmgTaken_S = CombatTrackerData[DestGUID].RealDMG_dmgTaken_S + Amount
	CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = CombatTrackerData[DestGUID].RealDMG_dmgTaken_P + Amount
	CombatTrackerData[DestGUID].RealDMG_dmgTaken = CombatTrackerData[DestGUID].RealDMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].RealDMG_hits_taken = CombatTrackerData[DestGUID].RealDMG_hits_taken + 1
	-- Done
	CombatTrackerData[SourceGUID].RealDMG_dmgDone_S = CombatTrackerData[SourceGUID].RealDMG_dmgDone_S + Amount
	CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = CombatTrackerData[SourceGUID].RealDMG_dmgDone_P + Amount
	CombatTrackerData[SourceGUID].RealDMG_dmgDone = CombatTrackerData[SourceGUID].RealDMG_dmgDone + Amount
	CombatTrackerData[SourceGUID].RealDMG_hits_done = CombatTrackerData[SourceGUID].RealDMG_hits_done + 1

	-- Only Taken by Player
	if isPlayer(destFlags) then
		-- DS
		if not CombatTrackerData[DestGUID].DS then
			CombatTrackerData[DestGUID].DS = {}
		end
		CombatTrackerData[DestGUID].DS[timestamp] = (CombatTrackerData[DestGUID].DS[timestamp] or 0) + Amount
		-- DS - Garbage
		CombatTrackerCleanTableByTime(CombatTrackerData[DestGUID].DS, timestamp - 10)
	end
end

--[[ This Logs the healing for every unit ]]
CombatTracker.logHealing			 			= function(...)
	local timestamp,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_, spellID, spellName,_, Amount = ... -- CombatLogGetCurrentEventInfo()
	-- Reset
	-- Taken
	if timestamp - CombatTrackerData[DestGUID].HPS_heal_lasttime > 5 then
		CombatTrackerData[DestGUID].HPS_heal_taken = 0
		CombatTrackerData[DestGUID].HPS_heal_hits_taken = 0
	end

	-- Done
	if timestamp - CombatTrackerData[SourceGUID].HPS_heal_lasttime_done > 5 then
		CombatTrackerData[SourceGUID].HPS_heal_done = 0
		CombatTrackerData[SourceGUID].HPS_heal_hits_done = 0
	end

	-- Update last  hit time
	-- Taken
	CombatTrackerData[DestGUID].HPS_heal_lasttime = timestamp
	-- Done
	CombatTrackerData[SourceGUID].HPS_heal_lasttime_done = timestamp

	-- Totals
	-- Taken
	CombatTrackerData[DestGUID].HPS_heal_taken = CombatTrackerData[DestGUID].HPS_heal_taken + Amount
	CombatTrackerData[DestGUID].HPS_heal_hits_taken = CombatTrackerData[DestGUID].HPS_heal_hits_taken + 1
	-- Done
	CombatTrackerData[SourceGUID].HPS_heal_done = CombatTrackerData[SourceGUID].HPS_heal_done + Amount
	CombatTrackerData[SourceGUID].HPS_heal_hits_done = CombatTrackerData[SourceGUID].HPS_heal_hits_done + 1

	-- Only Taken by Player
	if isPlayer(destFlags) then
		-- Spells
		if not CombatTrackerData[DestGUID].spell_value then
			CombatTrackerData[DestGUID].spell_value = {}
		end

		if not CombatTrackerData[DestGUID].spell_value[spellID] then
			CombatTrackerData[DestGUID].spell_value[spellID] = {}
			if spellName and not CombatTrackerData[DestGUID].spell_value[spellName] then
				CombatTrackerData[DestGUID].spell_value[spellName] 	= CombatTrackerData[DestGUID].spell_value[spellID]
			end
		end
		CombatTrackerData[DestGUID].spell_value[spellID].Amount 	= Amount
		CombatTrackerData[DestGUID].spell_value[spellID].TIME 		= timestamp
	end
end

--[[ This Logs the shields for every player or controlled by player unit ]]
CombatTracker.logAbsorb 						= function(...)
	local _,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_, spellID, spellName,_, auraType, Amount = ... -- CombatLogGetCurrentEventInfo()
	if auraType == "BUFF" and Amount and spellID and isPlayer(destFlags) then
		if not CombatTrackerData[DestGUID].absorb_spells then
			CombatTrackerData[DestGUID].absorb_spells = {}
		end

		CombatTrackerData[DestGUID].absorb_spells[spellID] = (CombatTrackerData[DestGUID].absorb_spells[spellID] or 0) + Amount
		CombatTrackerData[DestGUID].absorb_spells[spellName] = CombatTrackerData[DestGUID].absorb_spells[spellID]
	end
end

CombatTracker.update_logAbsorb					= function(...)
	local timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, srcSpellId, srcSpellName, srcSpellSchool, casterGUID, casterName, casterFlags, casterRaidFlags, spellId, spellName, spellSchool, absorbed
	if type(srcSpellId) == "number" then
		-- Spell
        timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, srcSpellId, srcSpellName, srcSpellSchool, casterGUID, casterName, casterFlags, casterRaidFlags, spellId, spellName, spellSchool, absorbed = ... -- CombatLogGetCurrentEventInfo()
	else
		-- Melee/Ranged
        timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, casterGUID, casterName, casterFlags, casterRaidFlags, spellId, spellName, spellSchool, absorbed = ... -- CombatLogGetCurrentEventInfo()
	end

	-- 'src' params is who caused absorb change
	-- 'dts' params is who got changed absorb
	-- 'caster' params is who and what applied
	-- 'absorbed' param is amount of absorb change
	if type(absorbed) == "number" and type(dstGUID) == "string" and spellId and CombatTrackerData[dstGUID].absorb_spells and CombatTrackerData[dstGUID].absorb_spells[spellId] then
		CombatTrackerData[dstGUID].absorb_spells[spellId] = (CombatTrackerData[dstGUID].absorb_spells[spellId] or 0) - absorbed
		CombatTrackerData[dstGUID].absorb_spells[spellName] = CombatTrackerData[dstGUID].absorb_spells[spellId]
	end
end

CombatTracker.remove_logAbsorb 					= function(...)
	local _,_,_, SourceGUID,_,_,_, DestGUID,_,_,_, spellID, spellName,_, spellType,_, amountMissed = ... -- CombatLogGetCurrentEventInfo()
	if (spellType == "BUFF" or spellType == "ABSORB") and spellID and CombatTrackerData[DestGUID].absorb_spells and CombatTrackerData[DestGUID].absorb_spells[spellID] then
		if spellType == "BUFF" then
			CombatTrackerData[DestGUID].absorb_spells[spellID] 			= nil
			CombatTrackerData[DestGUID].absorb_spells[spellName] 		= nil
		else
			local compare = CombatTrackerData[DestGUID].absorb_spells[spellID] - amountMissed
			if compare <= 0 then
				CombatTrackerData[DestGUID].absorb_spells[spellID] 		= nil
				CombatTrackerData[DestGUID].absorb_spells[spellName] 	= nil
			else
				CombatTrackerData[DestGUID].absorb_spells[spellID] 		= compare
				CombatTrackerData[DestGUID].absorb_spells[spellName] 	= compare
			end
		end
	end
end

--[[ This Logs the last cast and amount for every unit ]]
-- Note: Only @player self and in PvP any players
CombatTracker.logLastCast 						= function(...)
	local timestamp,_,_, SourceGUID,_, sourceFlags,_, _,_,_,_, spellID, spellName = ... -- CombatLogGetCurrentEventInfo()
	if (sourceFlags and ((A.IsInPvP and isPlayer(sourceFlags)) or IsFriendlyHunterIsGUID(SourceGUID))) or SourceGUID == GetGUID("player") then
		-- LastCast time
		if not CombatTrackerData[SourceGUID].spell_lastcast_time then
			CombatTrackerData[SourceGUID].spell_lastcast_time = {}
		end
		CombatTrackerData[SourceGUID].spell_lastcast_time[spellID] 	 	= timestamp
		CombatTrackerData[SourceGUID].spell_lastcast_time[spellName] 	= timestamp

		-- Counter
		if not CombatTrackerData[SourceGUID].spell_counter then
			CombatTrackerData[SourceGUID].spell_counter = {}
		end
		CombatTrackerData[SourceGUID].spell_counter[spellID] 			= (CombatTrackerData[SourceGUID].spell_counter[spellID] or 0) + 1
		CombatTrackerData[SourceGUID].spell_counter[spellName] 			= (CombatTrackerData[SourceGUID].spell_counter[spellName] or 0) + 1
	end
end

--[[ This Logs the reset on death for every unit ]]
CombatTracker.logDied							= function(...)
	local _,_,_,_,_,_,_, DestGUID = ... -- CombatLogGetCurrentEventInfo()
	CombatTrackerData[DestGUID] = nil
end

--[[ This Logs the DR (Diminishing Returns) for enemy unit PvE dr or player ]]
CombatTracker.logDR								= function(timestamp, EVENT, DestGUID, destFlags, spellID)
	if isEnemy(destFlags) then
		local drCat = DRData:GetCategoryBySpellID(spellID)
		if drCat and (DRData:IsPvECategory(drCat) or isPlayer(destFlags)) then
			local CombatTrackerDataGUID = CombatTrackerData[DestGUID]
			if not CombatTrackerDataGUID.DR then
				CombatTrackerDataGUID.DR = {}
			end

			-- All addons included DR library sample have wrong code to perform CLEU
			-- The main their fail is what DR should be starts AS SOON AS AURA IS APPLIED (not after expire)
			-- They do their approach because "SPELL_AURA_REFRESH" can catch "fake" refreshes caused by spells that break after a certain amount of damage
			-- But we will avoid such situation by "SPELL_AURA_BROKEN" and "SPELL_AURA_BROKEN_SPELL" through skip next "SPELL_AURA_REFRESH" which can be fired within the next 1.3 seconds
			local dr = CombatTrackerDataGUID.DR[drCat]

			-- DR skips next "fake" event "SPELL_AURA_REFRESH" if aura broken by damage
			if EVENT == "SPELL_AURA_BROKEN" or EVENT == "SPELL_AURA_BROKEN_SPELL" then
				if dr then
					dr.brokenTime 					= timestamp + 1.3 -- Adds 1.3 seconds, so if in the next 1.3 seconds fired "SPELL_AURA_REFRESH" that will be skipped. 0.3 is recommended latency
				end
				return
			end

			-- DR always starts by "SPELL_AURA_APPLIED" or if its already applied then by "SPELL_AURA_REFRESH"
			if EVENT == "SPELL_AURA_APPLIED" or (EVENT == "SPELL_AURA_REFRESH" and timestamp > (dr and dr.brokenTime or 0)) then
				-- Remove DR if its expired
				if dr and dr.reset < timestamp then
					dr.diminished 					= 100
					dr.application 					= 0
					dr.reset 						= 0
					dr.brokenTime					= 0
				end

				-- Add DR
				if not dr then
					-- If there isn't already a table, make one
					-- Start it at 1th application because the unit just got diminished
					CombatTrackerDataGUID.DR[drCat] = {
						application 				= 1,
						applicationMax 				= DRData:GetApplicationMax(drCat),
						diminished 					= DRData:GetNextDR(1, drCat) * 100,
						reset				 		= timestamp + DRData:GetResetTime(drCat),
						brokenTime					= 0,
					}
				else
					-- Diminish the unit by one tick
					-- Ticks go 100% -> 0%
					if dr.diminished and dr.diminished ~= 0 then
						dr.application 				= dr.application + 1
						dr.diminished 				= DRData:GetNextDR(dr.application, drCat) * 100
						dr.reset 					= timestamp + DRData:GetResetTime(drCat)
						dr.brokenTime				= 0
					end
				end
			end
		end
	end
end

--[[ These are the events we're looking for and its respective action ]]
CombatTracker.OnEventCLEU 						= {
	["SPELL_DAMAGE"] 						= CombatTracker.logDamage,
	["DAMAGE_SHIELD"] 						= CombatTracker.logDamage,
	["DAMAGE_SPLIT"]						= CombatTracker.logDamage,
	["SPELL_PERIODIC_DAMAGE"] 				= CombatTracker.logDamage,
	["SPELL_BUILDING_DAMAGE"] 				= CombatTracker.logDamage,
	["RANGE_DAMAGE"] 						= CombatTracker.logDamage,
	["SWING_DAMAGE"] 						= CombatTracker.logSwing,
	["ENVIRONMENTAL_DAMAGE"]				= CombatTracker.logEnvironmentalDamage,
	["SPELL_HEAL"] 							= CombatTracker.logHealing,
	["SPELL_PERIODIC_HEAL"] 				= CombatTracker.logHealing,
	["SPELL_AURA_APPLIED"] 					= CombatTracker.logAbsorb,
	["SPELL_AURA_REFRESH"] 					= CombatTracker.logAbsorb,
	["SPELL_ABSORBED"]						= CombatTracker.update_logAbsorb,
	["SPELL_AURA_REMOVED"] 					= CombatTracker.remove_logAbsorb,
	["SPELL_MISSED"] 						= CombatTracker.remove_logAbsorb,
	["SPELL_CAST_SUCCESS"] 					= CombatTracker.logLastCast,
	["UNIT_DIED"] 							= CombatTracker.logDied,
	["UNIT_DESTROYED"]						= CombatTracker.logDied,
	["UNIT_DISSIPATES"]						= CombatTracker.logDied,
	["PARTY_KILL"] 							= CombatTracker.logDied,
	["SPELL_INSTAKILL"] 					= CombatTracker.logDied,
}

CombatTracker.OnEventDR							= {
	["SPELL_AURA_BROKEN"]					= CombatTracker.logDR,
	["SPELL_AURA_BROKEN_SPELL"]				= CombatTracker.logDR,
	["SPELL_AURA_APPLIED"]					= CombatTracker.logDR,
	["SPELL_AURA_REFRESH"]					= CombatTracker.logDR,
}

local CombatTrackerOnEventCLEU					= CombatTracker.OnEventCLEU
local CombatTrackerOnEventDR					= CombatTracker.OnEventDR

-------------------------------------------------------------------------------
-- Locals: UnitTracker
-------------------------------------------------------------------------------
local UnitTracker 								= {
	Data 								= {},
	InfoByUnitID 						= {
		-- Defaults
		["player"] 						= {},
	},
	isShrimmer 							= {
		[GetSpellName(212653)] = true,
		[212653] = true,
	},
	isBlink								= {
		[GetSpellName(1953)] = true,
		[1953] = true,
		[119415] = true,
	},
	isBlockedForTracker					= {
		[212653] = true,
		[119415] = true,
		[1953] = true,
		[GetSpellName(212653)] = true,
		[GetSpellName(119415)] = true,
	},
	isNotResetFlyingEvent				= {
		["SUCCESS"] = true,
		["T_START"] = true,
		["_FAILED"] = true,
		["_CREATE"] = true,
		["_SUMMON"]	= true,
	},
	maxResetFlyingTimer					= 4,
	-- OnEvent
	UNIT_SPELLCAST_SUCCEEDED			= function(self, unitID, spellID)
		if unitID ~= "player" and self.InfoByUnitID[unitID] and self.InfoByUnitID[unitID][spellID] and (not self.InfoByUnitID[unitID][spellID].inPvP or A.IsInPvP) and (not self.InfoByUnitID[unitID][spellID].isFriendly or not A_Unit(unitID):IsEnemy()) then
			local GUID = GetGUID(unitID)

			if GUID then
				if not self.Data[GUID] then
					self.Data[GUID] = {}
				end

				if not self.Data[GUID][spellID] then
					self.Data[GUID][spellID] = {}
				end

				self.Data[GUID][spellID].start 					= TMW.time
				self.Data[GUID][spellID].expire 				= TMW.time + self.InfoByUnitID[unitID][spellID].Timer
				self.Data[GUID][spellID].isFlying 				= true
				self.Data[GUID][spellID].blackListCLEU 			= self.InfoByUnitID[unitID][spellID].blackListCLEU
				self.Data[GUID][spellID].enemy 					= A_Unit(unitID):IsEnemy()
				if self.InfoByUnitID[unitID][spellID].useName then
					self.Data[GUID][A_GetSpellInfo(spellID)] = self.Data[GUID][spellID]
				end
			end
		end
	end,
	UNIT_SPELLCAST_SUCCEEDED_PLAYER		= function(self, unitID, spellID)
		if unitID == "player" then
			local GUID 		= GetGUID(unitID)
			local spellName = A_GetSpellInfo and A_GetSpellInfo(spellID) or GetSpellName(spellID)
			local timestamp = TMW.time
			
			if not self.Data[GUID] then 
				self.Data[GUID] = {}
			end 	

			if not self.Data[GUID][spellID] then 
				self.Data[GUID][spellID] = {}
			end 				
			
			if not self.Data[GUID][spellID].isFlying then 
				self.Data[GUID][spellID].start 	  = timestamp
				self.Data[GUID][spellID].isFlying = true 
			end 
			
			self.Data[GUID][spellName] = self.Data[GUID][spellID]
			
			-- We will log CombatTrackerData here because this event fires earlier than CLEU 
			CombatTracker:AddToData(GUID, timestamp)
			CombatTracker.logLastCast(timestamp, nil, nil, GUID, nil, nil, nil, nil, nil, nil, nil, spellID, spellName)			
		end
	end,
	SPELL_CAST_SUCCESS					= function(self, SourceGUID, sourceFlags, spellID)
		-- Note: This trigger is used only for Blink and Shrimmer
		if self.isBlockedForTracker[spellID] and A.IsInPvP and isEnemy(sourceFlags) and isPlayer(sourceFlags) then
			-- Shrimmer
			if self.isShrimmer[spellID] then
				local ShrimmerCD = 0
				if not self.Data[SourceGUID] then
					self.Data[SourceGUID] = {}
				end

				if not self.Data[SourceGUID].Shrimmer then
					self.Data[SourceGUID].Shrimmer = {}
				end

				tinsert(self.Data[SourceGUID].Shrimmer, TMW.time + 20)

				-- Since it has only 2 charges by default need remove old ones
				if #self.Data[SourceGUID].Shrimmer > 2 then
					tremove(self.Data[SourceGUID].Shrimmer, 1)
				end
			-- Blink
			elseif self.isBlink[spellID] then
				if not self.Data[SourceGUID] then
					self.Data[SourceGUID] = {}
				end

				self.Data[SourceGUID].Blink = TMW.time + 15
			end
		end
	end,
	UNIT_DIED							= function(self, DestGUID)
		self.Data[DestGUID] = nil
	end,
	RESET_IS_FLYING						= function(self, EVENT, SourceGUID, spellID, spellName)
		-- Makes exception for events with _CREATE _FAILED _START since they are point less to be triggered
		if self.Data[SourceGUID] then
			if self.Data[SourceGUID][spellID] and self.Data[SourceGUID][spellID].isFlying and (not self.Data[SourceGUID][spellID].blackListCLEU or not self.Data[SourceGUID][spellID].blackListCLEU[EVENT]) then
				local lastSeven = strsub(EVENT, -7)
				if not self.isNotResetFlyingEvent[lastSeven] then
					self.Data[SourceGUID][spellID].isFlying = false
				end
			end

			if self.Data[SourceGUID][spellName] and self.Data[SourceGUID][spellName].isFlying and (not self.Data[SourceGUID][spellName].blackListCLEU or not self.Data[SourceGUID][spellName].blackListCLEU[EVENT]) then
				local lastSeven = strsub(EVENT, -7)
				if not self.isNotResetFlyingEvent[lastSeven] then
					self.Data[SourceGUID][spellName].isFlying = false
				end
			end
		end
	end,
	IsEventIsDied						= {
		["UNIT_DIED"] 					= true,
		["UNIT_DESTROYED"]				= true,
		["UNIT_DISSIPATES"]				= true,
		["PARTY_KILL"] 					= true,
		["SPELL_INSTAKILL"] 			= true,
	},
}

local UnitTrackerData							= UnitTracker.Data
local UnitTrackerInfoByUnitID					= UnitTracker.InfoByUnitID
local UnitTrackerIsBlockedForTracker			= UnitTracker.isBlockedForTracker
local UnitTrackerMaxResetFlyingTimer 			= UnitTracker.maxResetFlyingTimer
local UnitTrackerIsEventIsDied					= UnitTracker.IsEventIsDied

-------------------------------------------------------------------------------
-- Locals: LossOfControl
-------------------------------------------------------------------------------
local LossOfControl								= {
	LastEvent 									= 0,
	RemapType									= {
		["STUN_MECHANIC"]						= "STUN",
		["FEAR_MECHANIC"]						= "FEAR",
		--["INTERRUPT"]							= "SCHOOL_INTERRUPT",
		--["SCHOOL_INTERRUPT"]					= "INTERRUPT",
	},
	TextToName									= {},
	["SCHOOL_INTERRUPT"]						= {
		["PHYSICAL"] = {
			bit = 0x1,
			result = 0,
		},
		["HOLY"] = {
			bit = 0x2,
			result = 0,
		},
		["FIRE"] = {
			bit = 0x4,
			result = 0,
		},
		["NATURE"] = {
			bit = 0x8,
			result = 0,
		},
		["FROST"] = {
			bit = 0x10,
			result = 0,
		},
		["SHADOW"] = {
			bit = 0x20,
			result = 0,
		},
		["ARCANE"] = {
			bit = 0x40,
			result = 0,
		},
	},
	["BANISH"] 									= 0,
	["CHARM"] 									= 0,
	["CYCLONE"]									= 0,
	["DAZE"]									= 0, -- "Confused" / "Slowed"
	["DISARM"]									= 0,
	["DISORIENT"]								= 0,
	["DISTRACT"]								= 0,
	["FREEZE"]									= 0,
	["HORROR"]									= 0,
	["INCAPACITATE"]							= 0,
	["INTERRUPT"]								= 0,
	--["SCHOOL_INTERRUPT"]						= 0,
	--["INVULNERABILITY"]						= 0,
	--["MAGICAL_IMMUNITY"]						= 0,
	["PACIFY"]									= 0,
	["PACIFYSILENCE"]							= 0, -- "Disabled"
	["POLYMORPH"]								= 0,
	["POSSESS"]									= 0, -- Mind Control (?)
	["SAP"]										= 0,
	["SHACKLE_UNDEAD"]							= 0,
	["SLEEP"]									= 0,
	["SNARE"]									= 0, -- "Snared" slow usually example Concussive Shot
	["TURN_UNDEAD"]								= 0, -- "Feared Undead" currently not usable in BFA PvP but usable in Shadowlands now
	--["LOSECONTROL_TYPE_SCHOOLLOCK"] 			= 0, -- HAS SPECIAL HANDLING (per spell school) as "SCHOOL_INTERRUPT"
	["ROOT"]									= 0, -- "Rooted"
	["CONFUSE"]									= 0, -- "Confused" / "Slowed"
	["STUN"]									= 0, -- "Stunned"
	["SILENCE"]									= 0, -- "Silenced"
	["FEAR"]									= 0, -- "Feared"
}

do
	for name, val in pairs(LossOfControl) do
		if name ~= "LastEvent" then
			if name == "RemapType" then
				for k, v in pairs(val) do
					LossOfControl.TextToName[_G["LOSS_OF_CONTROL_DISPLAY_" .. k]] = v
				end
			elseif type(val) == "number" then
				LossOfControl.TextToName[_G["LOSS_OF_CONTROL_DISPLAY_" .. name]] = name
			end
		end
	end
end

LossOfControl.OnEvent							= function(...)
    if TMW.time == LossOfControl.LastEvent then
        return
    end
    LossOfControl.LastEvent = TMW.time

	local isValidType = false
    for eventIndex = 1, GetNumEvents() do
        local locType, _, text, _, start, _, duration, lockoutSchool = GetEventInfo(eventIndex)
		if type(locType) == "table" then
			locType, text, start, duration, lockoutSchool = locType.locType, locType.displayText, locType.startTime, locType.duration, locType.lockoutSchool
		end

		if locType == "SCHOOL_INTERRUPT" then
			-- Check that the user has requested the schools that are locked out.
			if lockoutSchool and lockoutSchool ~= 0 then
				for name, val in pairs(LossOfControl[locType]) do
					if bitband(lockoutSchool, val.bit) ~= 0 then
						isValidType = true
						LossOfControl[locType][name].result = (start or 0) + (duration or 0)
					end
				end
			end
		elseif text then
			local name = LossOfControl.TextToName[text]
			if name then
				-- Check that the user has requested the category that is active on the player.
				isValidType = true
				LossOfControl[name] = (start or 0) + (duration or 0)
			end
		end
    end

    -- Reset running durations.
    if not isValidType then
        for _, name in pairs(LossOfControl.TextToName) do
            if LossOfControl[name] > 0 then
                LossOfControl[name] = 0
            end
        end
    end
end

-------------------------------------------------------------------------------
-- OnEvent
-------------------------------------------------------------------------------
local COMBAT_LOG_EVENT_UNFILTERED 				= function(...)
	local timestamp = TMW.time
	local _, EVENT, _, SourceGUID, _, sourceFlags, _, DestGUID, _, destFlags, _, spellID, spellName, spellSchool, auraType, a16, a17, a18, a19, a20, a21, a22, a23, a24 = CombatLogGetCurrentEventInfo()

	--[[ For Test
	if EVENT:match("SPELL_AURA") then
		local te = {CombatLogGetCurrentEventInfo()}
		local str
		for i = 1, #te do
			str = tostring(te[i])
			if str == GetSpellName(322507) or te[i] == 322507 or str == GetSpellName(325092) or te[i] == 325092 then
				--print("[" .. i .. "] " .. tostring(te[i]))
				print(unpack(te))
				break
			end
		end
	end
	]]

	-- Add the unit to our data if we dont have it
	CombatTracker:AddToData(SourceGUID, timestamp)
	CombatTracker:AddToData(DestGUID, timestamp)

	-- Trigger
	if CombatTrackerOnEventCLEU[EVENT] then
		CombatTrackerOnEventCLEU[EVENT](timestamp, EVENT, _, SourceGUID, _, sourceFlags, _, DestGUID, _, destFlags, _, spellID, spellName, spellSchool, auraType, a16, a17, a18, a19, a20, a21, a22, a23, a24)
	end

	-- Diminishing (DR-Tracker)
	if CombatTrackerOnEventDR[EVENT] and (auraType == "DEBUFF" or a18 == "DEBUFF") then
		CombatTrackerOnEventDR[EVENT](timestamp, EVENT, DestGUID, destFlags, spellID)
	end

	-- PvP players tracker (Shrimmer / Blink)
	if EVENT == "SPELL_CAST_SUCCESS" then
		UnitTracker:SPELL_CAST_SUCCESS(SourceGUID, sourceFlags, spellID)
	end

	-- Reset isFlying
	if UnitTrackerIsEventIsDied[EVENT] then
		UnitTracker:UNIT_DIED(DestGUID)
	else
		local firstFive = strsub(EVENT, 1, 5)
		if firstFive == "SPELL" and not UnitTrackerIsBlockedForTracker[spellName] then
			UnitTracker:RESET_IS_FLYING(EVENT, SourceGUID, spellID, spellName)
		end
	end
end

local UNIT_SPELLCAST_SUCCEEDED					= function(...)
	local unitID, _, spellID = ...
	if unitID and not UnitTrackerIsBlockedForTracker[spellID] then
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED(unitID, spellID)
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED_PLAYER(unitID, spellID)
	end
end

TMW:RegisterCallback("TMW_ACTION_ENTERING",											function(event, subevent)
	if skipedFirstEnter then
		if subevent ~= "UPDATE_INSTANCE_INFO" then
		end
	else
		skipedFirstEnter = true
	end
end)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "COMBAT_LOG_EVENT_UNFILTERED", 			COMBAT_LOG_EVENT_UNFILTERED	)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_SPELLCAST_SUCCEEDED", 			UNIT_SPELLCAST_SUCCEEDED	)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_REGEN_ENABLED", 				function()
	if A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel and not A_Player:IsStealthed() then
		wipe(UnitTrackerData)
		wipe(CombatTrackerData)
	end

	local GUID = GetGUID("player")
	CombatTracker:AddToData(GUID, TMW.time)
	if CombatTrackerData[GUID] then
		CombatTrackerData[GUID].combat_time = 0
	end
end)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_REGEN_DISABLED", 				function()
	-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
	local SpellLastCast = A_CombatTracker:GetSpellLastCast("player", A.LastPlayerCastID)
	if (SpellLastCast == 0 or SpellLastCast > 1.5) and A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel and not A_Player:IsStealthed() and A_Player:CastTimeSinceStart() > 5 then
		wipe(UnitTrackerData)
		wipe(CombatTrackerData)
	end

	local GUID = GetGUID("player")
	CombatTracker:AddToData(GUID, TMW.time)
	if CombatTrackerData[GUID] then
		CombatTrackerData[GUID].combat_time = TMW.time
	end
end)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "LOSS_OF_CONTROL_UPDATE", 				LossOfControl.OnEvent		)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "LOSS_OF_CONTROL_ADDED", 				LossOfControl.OnEvent		)

-------------------------------------------------------------------------------
-- OnUpdate
-------------------------------------------------------------------------------
local Frame = CreateFrame("Frame", nil, UIParent)
Frame:SetScript("OnUpdate", function(self, elapsed)
	self.TimeSinceLastUpdate = (self.TimeSinceLastUpdate or 0) + elapsed
	if self.TimeSinceLastUpdate > 15 then
		local GUID, Data = next(CombatTrackerData)

		while GUID ~= nil do
			if TMW.time - Data.lastSeen > 60 then
				CombatTrackerData[GUID] = nil
				Data = nil
				TMW:Fire("TMW_ACTION_COMBAT_TRACKER_GUID_WIPE", GUID)
			end

			GUID, Data = next(CombatTrackerData,  GUID)
		end

		self.TimeSinceLastUpdate = 0
	end
end)

-------------------------------------------------------------------------------
-- API: CombatTracker
-------------------------------------------------------------------------------
local function UnitHasCombat(unitID)
	-- @return boolean
	-- Note: Special function supposed to make forced unit in combat if UnitAffectingCombat doesn't work for specific npcID
	return A_Unit(unitID):IsCracklingShard()
end

A.CombatTracker									= {
	--[[ Returns the total ammount of time a unit is in-combat for ]]
	CombatTime									= function(self, unitID)
		-- @return number, GUID
		local unit = unitID or "player"
		local GUID = GetGUID(unit)

		if CombatTrackerData[GUID] and CombatTrackerData[GUID].combat_time ~= 0 then
			if (UnitIsUnit(unit, "player") and InCombatLockdown()) or UnitAffectingCombat(unit) or UnitHasCombat(unit) or A_Unit(unit):IsDummy() then
				return TMW.time - CombatTrackerData[GUID].combat_time, GUID
			else
				CombatTrackerData[GUID].combat_time = 0
			end
		end
		return 0, GUID
	end,
	--[[ Get Last X seconds incoming DMG (10 sec max, default X is 5) ]]
	GetLastTimeDMGX								= function(self, unitID, X)
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] and CombatTrackerData[GUID].DS then
			return CombatTrackerSummTableByTime(CombatTrackerData[GUID].DS, TMW.time - (X or 5))
		end
		return 0
	end,
	--[[ Get RealTime DMG Taken ]]
	GetRealTimeDMG								= function(self, unitID)
		local total, Hits, phys, magic, swing 	= 0, 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)

		if combatTime > 0 and TMW.time - CombatTrackerData[GUID].DMG_lastHit_taken <= A_GetGCD() * 2 + 1 then
			Hits 		= CombatTrackerData[GUID].RealDMG_hits_taken
			if Hits > 0 then
				total 	= CombatTrackerData[GUID].RealDMG_dmgTaken / Hits
				phys 	= CombatTrackerData[GUID].RealDMG_dmgTaken_P / Hits
				magic 	= CombatTrackerData[GUID].RealDMG_dmgTaken_M / Hits
				swing 	= CombatTrackerData[GUID].RealDMG_dmgTaken_S / Hits
			end
		end
		return total, Hits, phys, magic, swing
	end,
	--[[ Get RealTime DMG Done ]]
	GetRealTimeDPS								= function(self, unitID)
		local total, Hits, phys, magic, swing 	= 0, 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)

		if combatTime > 0 and TMW.time - CombatTrackerData[GUID].DMG_lastHit_done <= A_GetGCD() * 2 + 1 then
			Hits 		= CombatTrackerData[GUID].RealDMG_hits_done
			if Hits > 0 then
				total 	= CombatTrackerData[GUID].RealDMG_dmgDone / Hits
				phys 	= CombatTrackerData[GUID].RealDMG_dmgDone_P / Hits
				magic 	= CombatTrackerData[GUID].RealDMG_dmgDone_M / Hits
				swing 	= CombatTrackerData[GUID].RealDMG_dmgDone_S / Hits
			end
		end
		return total, Hits, phys, magic, swing
	end,
	--[[ Get DMG Taken ]]
	GetDMG										= function(self, unitID)
		local total, Hits, phys, magic 			= 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)

		if combatTime > 0 and TMW.time - CombatTrackerData[GUID].DMG_lastHit_taken <= 5 then
			total 	= CombatTrackerData[GUID].DMG_dmgTaken / combatTime
			phys 	= CombatTrackerData[GUID].DMG_dmgTaken_P / combatTime
			magic 	= CombatTrackerData[GUID].DMG_dmgTaken_M / combatTime
			Hits 	= CombatTrackerData[GUID].DMG_hits_taken or 0
		end
		return total, Hits, phys, magic
	end,
	--[[ Get DMG Done ]]
	GetDPS										= function(self, unitID)
		local total, Hits, phys, magic 			= 0, 0, 0, 0
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] and TMW.time - CombatTrackerData[GUID].DMG_lastHit_done <= 5 then
			Hits 		= CombatTrackerData[GUID].DMG_hits_done
			if Hits > 0 then
				total 	= CombatTrackerData[GUID].DMG_dmgDone / Hits
				phys 	= CombatTrackerData[GUID].DMG_dmgDone_P / Hits
				magic 	= CombatTrackerData[GUID].DMG_dmgDone_M / Hits
			end
		end
		return total, Hits, phys, magic
	end,
	--[[ Get Heal Taken ]]
	GetHEAL										= function(self, unitID)
		local total, Hits 						= 0, 0
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] and TMW.time - CombatTrackerData[GUID].HPS_heal_lasttime <= 5 then
			Hits 		= CombatTrackerData[GUID].HPS_heal_hits_taken
			if Hits > 0 then
				total 	= CombatTrackerData[GUID].HPS_heal_taken / Hits
			end
		end
		return total, Hits
	end,
	--[[ Get Heal Done ]]
	GetHPS										= function(self, unitID)
		local total, Hits 						= 0, 0
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] then
			Hits = CombatTrackerData[GUID].HPS_heal_hits_done
			if Hits > 0 then
				total = CombatTrackerData[GUID].HPS_heal_done / Hits
			end
		end
		return total, Hits
	end,
	-- [[ Get School Damage Taken (by @player only) ]]
	GetSchoolDMG								= function(self, unitID)
		-- @return number
		-- [1] Holy
		-- [2] Fire
		-- [3] Nature
		-- [4] Frost
		-- [5] Shadow
		-- [6] Arcane
		local Holy, Fire, Nature, Frost, Shadow, Arcane = 0, 0, 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)

		if combatTime > 0 and CombatTrackerData[GUID].School then
			local timestamp = TMW.time
			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Holy_LH <= 5 then
				Holy = CombatTrackerData[GUID].School.DMG_dmgTaken_Holy / combatTime
			end

			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Fire_LH <= 5 then
				Fire = CombatTrackerData[GUID].School.DMG_dmgTaken_Fire / combatTime
			end

			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Nature_LH <= 5 then
				Nature = CombatTrackerData[GUID].School.DMG_dmgTaken_Nature / combatTime
			end

			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Frost_LH <= 5 then
				Frost = CombatTrackerData[GUID].School.DMG_dmgTaken_Frost / combatTime
			end

			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Shadow_LH <= 5 then
				Shadow = CombatTrackerData[GUID].School.DMG_dmgTaken_Shadow / combatTime
			end

			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Arcane_LH <= 5 then
				Arcane = CombatTrackerData[GUID].School.DMG_dmgTaken_Arcane / combatTime
			end
		end
		return Holy, Fire, Nature, Frost, Shadow, Arcane
	end,
	--[[ Get Spell Amount Taken (if was taken) in the last X seconds ]]
	GetSpellAmountX								= function(self, unitID, spell, X)
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] and CombatTrackerData[GUID].spell_value and CombatTrackerData[GUID].spell_value[spell] and TMW.time - CombatTrackerData[GUID].spell_value[spell].TIME <= (X or 5) then
			return CombatTrackerData[GUID].spell_value[spell].Amount
		end
		return 0
	end,
	--[[ Get Spell Amount Taken last time (if didn't called upper function with timer) ]]
	GetSpellAmount								= function(self, unitID, spell)
		local GUID 								= GetGUID(unitID)

		return (CombatTrackerData[GUID] and CombatTrackerData[GUID].spell_value and CombatTrackerData[GUID].spell_value[spell] and CombatTrackerData[GUID].spell_value[spell].Amount) or 0
	end,
	--[[ This is tracks CLEU spells only if they was applied/missed/reflected e.g. received in any form by end unit to feedback that info ]]
	--[[ Instead of this function for spells which have flying but wasn't received by end unit, since spell still in the fly, you need use A.UnitCooldown ]]
	-- Note: Only @player self and in PvP any players
	GetSpellLastCast 							= function(self, unitID, spell)
		-- @return number, number
		-- time in seconds since last cast, timestamp of start
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] and CombatTrackerData[GUID].spell_lastcast_time and CombatTrackerData[GUID].spell_lastcast_time[spell] then
			local start = CombatTrackerData[GUID].spell_lastcast_time[spell]
			return TMW.time - start, start
		end
		return A.IsOLDprofile and 0 or huge, 0 -- TODO: Remove "A.IsOLDprofile and 0 or"
	end,
	--[[ Get Count Spell of total used during fight ]]
	-- Note: Only @player self and in PvP any players
	GetSpellCounter								= function(self, unitID, spell)
		-- @return number
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] and CombatTrackerData[GUID].spell_counter then
			return CombatTrackerData[GUID].spell_counter[spell] or 0
		end
		return 0
	end,
	--[[ Get Absorb Taken ]]
	-- Note: Only players or controlled by players (pets)
	GetAbsorb									= function(self, unitID, spell)
		-- @return number
		if not spell then
			return UnitGetTotalAbsorbs(unitID)
		else
			local GUID	 						= GetGUID(unitID)

			if GUID and CombatTrackerData[GUID] and CombatTrackerData[GUID].absorb_spells then
				local absorb = CombatTrackerData[GUID].absorb_spells[spell] or 0
				if absorb < 0 then
					absorb = abs(A_Unit(unitID):AuraVariableNumber(spell, "HELPFUL"))
				end

				return absorb
			end
		end

		return 0
	end,
	--[[ Get DR: Diminishing (only enemy) ]]
	GetDR 										= function(self, unitID, drCat)
		-- @return: DR_Tick (@number), DR_Remain (@number: 0 -> 18), DR_Application (@number: 0 -> 5), DR_ApplicationMax (@number: 5 <-> 0)
		-- DR_Tick is Tick (number: 100 -> 50 -> 25 -> 0) where 0 is fully imun, 100 is no imun
		-- "taunt" has unique Tick (number: 100 -> 65 -> 42 -> 27 -> 0)
		-- DR_Remain is remain in seconds time before DR_Application will be reset
		-- DR_Application is how much DR stacks were applied currently and DR_ApplicationMax is how much by that category can be applied in total
		--[[ drCat accepts:
			"disorient"						-- TBC Retail
			"incapacitate"					-- Any
			"silence"						-- WOTLK+ Retail
			"stun"							-- Any
			"random_stun"					-- non-Retail
			"taunt"							-- Retail
			"root"							-- Any
			"random_root"					-- non-Retail
			"disarm"						-- Classic+ Retail
			"knockback"						-- Retail
			"counterattack"					-- TBC+ non-Retail
			"chastise"						-- TBC
			"kidney_shot"					-- Classic TBC
			"unstable_affliction"			-- TBC
			"death_coil"					-- TBC
			"fear"							-- Classic+ non-Retail
			"mind_control"					-- Classic+ non-Retail
			"horror"						-- WOTLK+ non-Retail
			"opener_stun"					-- WOTLK
			"scatter"						-- TBC+ non-Retail
			"cyclone"						-- WOTLK+ non-Retail
			"charge"						-- WOTLK
			"deep_freeze_rof"				-- CATA+ non-Retail
			"bind_elemental"				-- CATA+ non-Retail
			"frost_shock"					-- Classic

			non-Player unitID considered as PvE spells and accepts only:
			"stun", "kidney_shot"						-- Classic
			"stun", "random_stun", "kidney_shot"		-- TBC
			"stun", "random_stun", "opener_stun"		-- WOTLK
			"stun", "random_stun", "cyclone"			-- CATA
			"taunt", "stun"								-- Retail

			Same note should be kept in Unit(unitID):IsControlAble, Unit(unitID):GetDR(), CombatTracker.GetDR(unitID)
		]]
		local GUID 								= GetGUID(unitID)
		local DR 								= CombatTrackerData[GUID] and CombatTrackerData[GUID].DR and CombatTrackerData[GUID].DR[drCat]
		if DR and DR.reset and DR.reset >= TMW.time then
			return DR.diminished, DR.reset - TMW.time, DR.application, DR.applicationMax
		end

		return 100, 0, 0, 0
	end,
	--[[ Time To Die ]]
	TimeToDieX									= function(self, unitID, X)
		local UNIT 								= unitID or "target"
		local ttd 								= 500

		-- Training dummy totems exception
		if A.Zone ~= "none" or not A_Unit(UNIT):IsDummy() then 
			local health 						= A_Unit(UNIT):Health()
			local DMG, Hits 					= self:GetDMG(UNIT)
			
			-- We need "health > 0" condition to ensure that the unit is still alive
			if health <= 0 then return 0 end
			if DMG >= 1 and Hits > 1 then		
				ttd = (health - ( A_Unit(UNIT):HealthMax() * (X / 100) )) / DMG
			end 
		end		

		return ttd
	end,
	TimeToDie									= function(self, unitID)
		local UNIT 								= unitID or "target"
		local ttd 								= 500		

		-- Training dummy totems exception
		if A.Zone ~= "none" or not A_Unit(UNIT):IsDummy() then 
			local health 						= A_Unit(UNIT):Health()
			local DMG, Hits 					= self:GetDMG(UNIT)
			
			-- We need "health > 0" condition to ensure that the unit is still alive
			if health <= 0 then return 0 end
			if DMG >= 1 and Hits > 1 then
				ttd = health / DMG
			end 
		end

		return ttd
	end,
	TimeToDieMagicX								= function(self, unitID, X)
		local UNIT 								= unitID or "target"
		local ttd 								= 500

		-- Training dummy totems exception
		if A.Zone ~= "none" or not A_Unit(UNIT):IsDummy() then 
			local health 						= A_Unit(UNIT):Health()			
			local _, Hits, _, DMG 				= self:GetDMG(UNIT)
			
			-- We need "health > 0" condition to ensure that the unit is still alive
			if health <= 0 then return 0 end
			if DMG >= 1 and Hits > 1 then
				ttd = (health - ( A_Unit(UNIT):HealthMax() * (X / 100) )) / DMG
			end 
		end				

		return ttd
	end,
	TimeToDieMagic								= function(self, unitID)
		local UNIT 								= unitID or "target"
		local ttd 								= 500
		
		-- Training dummy totems exception
		if A.Zone ~= "none" or not A_Unit(UNIT):IsDummy() then 
			local health 						= A_Unit(UNIT):Health()
			local _, Hits, _, DMG 				= self:GetDMG(UNIT)
			
			-- We need "health > 0" condition to ensure that the unit is still alive
			if health <= 0 then return 0 end
			if DMG >= 1 and Hits > 1 then
				ttd = health / DMG
			end 
		end

		return ttd
	end,
}

-------------------------------------------------------------------------------
-- API: UnitCooldown
-------------------------------------------------------------------------------
-- Note: For Retail argument spellID may be spellName if last argument useName for A.UnitCooldown:Register was passed as true (For Register, UnRegister methods must be always spellID)
A.UnitCooldown 									= {
	Register							= function(self, unit, spellID, timer, isFriendlyArg, inPvPArg, CLEUbl, useName)
		-- unit accepts "arena", "raid", "party", their number
		-- isFriendlyArg, inPvPArg are optional
		-- CLEUbl is a table = { ['Event_CLEU'] = true, } which to skip and don't reset by them in fly
		if UnitTracker.isBlink[spellID] or UnitTracker.isShrimmer[spellID] then
			A.Print("[Error] Can't register Blink or Shrimmer because they are already registered. Please use function Action.UnitCooldown:GetBlinkOrShrimmer(unitID)")
			return
		end

		if unit == "player" then
			A.Print("[Error] Can't register self as " .. unit .. " because it's already registred to track only flying spells!")
			return
		end

		if unit:match("target") or unit:match("focus") or unit:match("nameplate") then
			A.Print("[Error] Can't register invalid unitID as " .. unit)
			return
		end

		local inPvP 	 = inPvPArg
		local isFriendly = isFriendlyArg
		if unit:match("arena") then
			inPvP = true
		elseif unit:match("party") or unit:match("raid") then
			isFriendly = true
		end

		if unit == "arena" or unit == "raid" or unit == "party" then
			for i = 1, (unit == "party" and 4 or 40) do
				local unitID = unit .. i
				if not UnitTrackerInfoByUnitID[unitID] then
					UnitTrackerInfoByUnitID[unitID] = {}
				end
				UnitTrackerInfoByUnitID[unitID][spellID] = { isFriendly = isFriendly, inPvP = inPvP, Timer = timer, blackListCLEU = CLEUbl, useName = useName }
			end
		else
			if not UnitTrackerInfoByUnitID[unit] then
				UnitTrackerInfoByUnitID[unit] = {}
			end
			UnitTrackerInfoByUnitID[unit][spellID] = { isFriendly = isFriendly, inPvP = inPvP, Timer = timer, blackListCLEU = CLEUbl, useName = useName }
		end
	end,
	UnRegister							= function(self, unit, spellID)
		if unit == "player" then
			A.Print("[Error] Can't unregister self as " .. unit .. " because it will break functional")
			return
		end

		if unit == "arena" or unit == "raid" or unit == "party" then
			for i = 1, (unit == "party" and 4 or 40) do
				local unitID = unit .. i
				if not spellID then
					UnitTrackerInfoByUnitID[unitID] = nil
				else
					if UnitTrackerInfoByUnitID[unitID] then
						UnitTrackerInfoByUnitID[unitID][spellID] = nil
					end
				end
			end
		else
			if not spellID then
				UnitTrackerInfoByUnitID[unit] = nil
			else
				UnitTrackerInfoByUnitID[unit][spellID] = nil
			end
		end
		wipe(UnitTrackerData)
	end,
	GetCooldown							= function(self, unit, spellID)
		-- @return number, number (remain cooldown time in seconds, start time stamp when spell was used and counter launched)
		if unit == "any" or unit == "enemy" or unit == "friendly" then
			for _, v in pairs(UnitTrackerData) do
				if v[spellID] and v[spellID].expire and (unit == "any" or (unit == "enemy" and v[spellID].enemy) or (unit == "friendly" and not v[spellID].enemy)) then
					return math_max(v[spellID].expire - TMW.time, 0), v[spellID].start
				end
			end
		elseif unit == "arena" or unit == "raid" or unit == "party" then
			for i = 1, (unit == "party" and 4 or 40) do
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then
					if unit == "party" or i >= GetGroupMaxSize(unit) then
						break
					end
				elseif UnitTrackerData[GUID] and UnitTrackerData[GUID][spellID] and UnitTrackerData[GUID][spellID].expire then
					return math_max(UnitTrackerData[GUID][spellID].expire - TMW.time, 0), UnitTrackerData[GUID][spellID].start
				end
			end
		else
			local GUID = GetGUID(unit)
			if GUID and UnitTrackerData[GUID] and UnitTrackerData[GUID][spellID] and UnitTrackerData[GUID][spellID].expire then
				return math_max(UnitTrackerData[GUID][spellID].expire - TMW.time, 0), UnitTrackerData[GUID][spellID].start
			end
		end
		return 0, 0
	end,
	GetMaxDuration						= function(self, unit, spellID)
		-- @return number (max cooldown of the spell on a unit)
		if unit == "any" or unit == "enemy" or unit == "friendly" then
			for _, v in pairs(UnitTrackerData) do
				if v[spellID] and v[spellID].expire and (unit == "any" or (unit == "enemy" and v[spellID].enemy) or (unit == "friendly" and not v[spellID].enemy)) then
					return math_max(v[spellID].expire - v[spellID].start, 0)
				end
			end
		elseif unit == "arena" or unit == "raid" or unit == "party" then
			for i = 1, (unit == "party" and 4 or 40) do
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then
					if unit == "party" or i >= GetGroupMaxSize(unit) then
						break
					end
				elseif UnitTrackerData[GUID] and UnitTrackerData[GUID][spellID] and UnitTrackerData[GUID][spellID].expire then
					return math_max(UnitTrackerData[GUID][spellID].expire - UnitTrackerData[GUID][spellID].start, 0)
				end
			end
		else
			local GUID = GetGUID(unit)
			if GUID and UnitTrackerData[GUID] and UnitTrackerData[GUID][spellID] and UnitTrackerData[GUID][spellID].expire then
				return math_max(UnitTrackerData[GUID][spellID].expire - UnitTrackerData[GUID][spellID].start, 0)
			end
		end
		return 0
	end,
	GetUnitID 							= function(self, unit, spellID)
		-- @return unitID (who last casted spell) otherwise nil
		if unit == "any" or unit == "enemy" or unit == "friendly" then
			for GUID, v in pairs(UnitTrackerData) do
				if v[spellID] and v[spellID].expire and v[spellID].expire - TMW.time >= 0 and (unit == "any" or (unit == "enemy" and v[spellID].enemy) or (unit == "friendly" and not v[spellID].enemy)) then
					if unit == "any" or unit == "enemy" then
						if A.Zone == "none" then
							if ActiveNameplates then
								for unitID in pairs(ActiveNameplates) do
									if GUID == UnitGUID(unitID) then -- Not GetGUID(unitID) because it will never be Base members
										return unitID
									end
								end
							end
						else
							for i = 1, TeamCacheEnemy.MaxSize do
								if TeamCacheEnemyIndexToPLAYERs[i] and GUID == TeamCacheEnemyUNITs[TeamCacheEnemyIndexToPLAYERs[i]] then
									return TeamCacheEnemyIndexToPLAYERs[i]
								end
							end
						end
					end

					if (unit == "any" or unit == "friendly") and TeamCacheFriendly.Type then
						for i = 1, TeamCacheFriendly.MaxSize do
							if TeamCacheFriendlyIndexToPLAYERs[i] and GUID == TeamCacheFriendlyUNITs[TeamCacheFriendlyIndexToPLAYERs[i]] then
								return TeamCacheFriendlyIndexToPLAYERs[i]
							end
						end
					end
				end
			end
		elseif unit == "arena" or unit == "raid" or unit == "party" then
			for i = 1, (unit == "party" and 4 or 40) do
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then
					if unit == "party" or i >= GetGroupMaxSize(unit) then
						break
					end
				elseif UnitTrackerData[GUID] and UnitTrackerData[GUID][spellID] and UnitTrackerData[GUID][spellID].expire and UnitTrackerData[GUID][spellID].expire - TMW.time >= 0 then
					return unitID
				end
			end
		end
	end,
	--[[ Mage Shrimmer/Blink Tracker (only enemy) ]]
	GetBlinkOrShrimmer					= function(self, unit)
		-- @return number, number, number
		-- [1] Current Charges, [2] Current Cooldown, [3] Summary Cooldown
		local charges, cooldown, summary_cooldown = 1, 0, 0
		if unit == "any" or unit == "enemy" or unit == "friendly" then
			for _, v in pairs(UnitTrackerData) do
				if v.Shrimmer then
					charges = 2
					for i = #v.Shrimmer, 1, -1 do
						cooldown = v.Shrimmer[i] - TMW.time
						if cooldown > 0 then
							charges = charges - 1
							summary_cooldown = summary_cooldown + cooldown
						end
					end
					break
				elseif v.Blink then
					cooldown = v.Blink - TMW.time
					if cooldown <= 0 then
						cooldown = 0
					else
						charges = 0
						summary_cooldown = cooldown
					end
					break
				end
			end
		elseif unit == "arena" or unit == "raid" or unit == "party" then
			for i = 1, (unit == "party" and 4 or 40) do
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then
					break
				elseif UnitTrackerData[GUID] then
					if UnitTrackerData[GUID].Shrimmer then
						charges = 2
						for i = #UnitTrackerData[GUID].Shrimmer, 1, -1 do
							cooldown = UnitTrackerData[GUID].Shrimmer[i] - TMW.time
							if cooldown > 0 then
								charges = charges - 1
								summary_cooldown = summary_cooldown + cooldown
							end
						end
						break
					elseif UnitTrackerData[GUID].Blink then
						cooldown = UnitTrackerData[GUID].Blink - TMW.time
						if cooldown <= 0 then
							cooldown = 0
						else
							charges = 0
							summary_cooldown = cooldown
						end
						break
					end
				end
			end
		else
			local GUID = GetGUID(unit)
			if GUID and UnitTrackerData[GUID] then
				if UnitTrackerData[GUID].Shrimmer then
					charges = 2
					for i = #UnitTrackerData[GUID].Shrimmer, 1, -1 do
						cooldown = UnitTrackerData[GUID].Shrimmer[i] - TMW.time
						if cooldown > 0 then
							charges = charges - 1
							summary_cooldown = summary_cooldown + cooldown
						end
					end
				elseif UnitTrackerData[GUID].Blink then
					cooldown = UnitTrackerData[GUID].Blink - TMW.time
					if cooldown <= 0 then
						cooldown = 0
					else
						charges = 0
						summary_cooldown = cooldown
					end
				end
			end
		end
		return charges, cooldown, summary_cooldown
	end,
	--[[ Is In Flying Spells Tracker ]]
	IsSpellInFly						= function(self, unit, spell)
		-- @return boolean
		if unit == "any" or unit == "enemy" or unit == "friendly" then
			for _, v in pairs(UnitTrackerData) do
				if v[spell] and v[spell].isFlying and (unit == "any" or (unit == "enemy" and v[spell].enemy) or (unit == "friendly" and not v[spell].enemy)) then
					if TMW.time - v[spell].start > UnitTrackerMaxResetFlyingTimer then
						v[spell].isFlying = false
					end
					return v[spell].isFlying
				end
			end
		elseif unit == "arena" or unit == "raid" or unit == "party" then
			for i = 1, (unit == "party" and 4 or 40) do
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then
					if unit == "party" or i >= GetGroupMaxSize(unit) then
						break
					end
				elseif UnitTrackerData[GUID] and UnitTrackerData[GUID][spell] and UnitTrackerData[GUID][spell].isFlying then
					if TMW.time - UnitTrackerData[GUID][spell].start > UnitTrackerMaxResetFlyingTimer then
						UnitTrackerData[GUID][spell].isFlying = false
					end
					return UnitTrackerData[GUID][spell].isFlying
				end
			end
		else
			local GUID = GetGUID(unit)
			if GUID and UnitTrackerData[GUID] and UnitTrackerData[GUID][spell] and UnitTrackerData[GUID][spell].isFlying then
				if TMW.time - UnitTrackerData[GUID][spell].start > UnitTrackerMaxResetFlyingTimer then
					UnitTrackerData[GUID][spell].isFlying = false
				end
				return UnitTrackerData[GUID][spell].isFlying
			end
		end
	end,
}

-- Tracks Freezing Trap
A.UnitCooldown:Register("arena", CONST.SPELLID_FREEZING_TRAP, 30, false, true, nil, true)
-- Tracks Counter Shot (it's fly able spell and can be avoided by stopcasting)
A.UnitCooldown:Register("arena", CONST.SPELLID_COUNTER_SHOT,  24, false, true, nil, true)
-- Tracks Storm Bolt
A.UnitCooldown:Register("arena", CONST.SPELLID_STORM_BOLT, 	 25, false, true, nil, true)

-------------------------------------------------------------------------------
-- API: LossOfControl
-------------------------------------------------------------------------------
A.LossOfControl									= {
	-- All below methods are for PLAYER only
	Get											= function(self, locType, name)
		-- @return number (remain duration in seconds of LossOfControl)
		local result = 0
		if name then
			result = LossOfControl[locType][name] and LossOfControl[locType][name].result or 0
		else
			result = LossOfControl[locType] or 0
		end

		return math_max(result - TMW.time, 0)
	end,
	IsMissed									= function(self, MustBeMissed)
		-- @return boolean
		local result = true
		if type(MustBeMissed) == "table" then
			for i = 1, #MustBeMissed do
				if self:Get(MustBeMissed[i]) > 0 then
					result = false
					break
				end
			end
		else
			result = self:Get(MustBeMissed) == 0
		end
		return result
	end,
	IsValid										= function(self, MustBeApplied, MustBeMissed, Exception)
		-- @return boolean (if result is fully okay), boolean (if result is not okay but we can pass it to use another things as remove control)
		local isApplied = false
		local result = isApplied

		for i = 1, #MustBeApplied do
			if self:Get(MustBeApplied[i]) > 0 then
				isApplied = true
				result = isApplied
				break
			end
		end

		-- Exception
		if Exception and not isApplied then
			-- Dwarf in DeBuffs
			if A.PlayerRace == "Dwarf" then
				isApplied = A_Unit("player"):HasDeBuffs("Poison") > 0 or A_Unit("player"):HasDeBuffs("Curse") > 0 or A_Unit("player"):HasDeBuffs("Magic") > 0
			end
			-- Gnome in current speed
			if A.PlayerRace == "Gnome" then
				local cSpeed = A_Unit("player"):GetCurrentSpeed()
				isApplied = cSpeed > 0 and cSpeed < 100
			end
		end

		if isApplied and MustBeMissed then
			for i = 1, #MustBeMissed do
				if self:Get(MustBeMissed[i]) > 0 then
					result = false
					break
				end
			end
		end

		return result, isApplied
	end,
	GetExtra 									= {
		["GladiatorMedallion"] 					= {
			Applied = {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "SLEEP", "SHACKLE_UNDEAD", "FEAR", "HORROR", "CHARM", "ROOT", "SNARE", "STUN"},
			isValid = function()
				return A.IsInPvP and
				(
					A.GladiatorMedallion:IsReady("player", true) or
					(
						A.HonorMedallion:IsExists() and
						A.HonorMedallion:IsReady("player", true)
					)
				)
			end,
		},
		["Human"] 								= {
			Applied								= {"STUN"},
			Missed 								= {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "SLEEP", "SHACKLE_UNDEAD", "FEAR", "HORROR", "CHARM", "ROOT"},
		},
		["Dwarf"] = {
			Applied 							= {"POLYMORPH", "SLEEP", "SHACKLE_UNDEAD"},
			Missed 								= {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "STUN", "FEAR", "HORROR", "CHARM", "ROOT"},
		},
		["Scourge"] 							= {
			Applied 							= {"FEAR", "HORROR", "SLEEP", "CHARM"},
			Missed 								= {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "STUN", "SHACKLE_UNDEAD", "ROOT"},
		},
		["Gnome"]	 							= {
			Applied 							= {"ROOT", "SNARE"},
			Missed 								= {"DISARM", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "SLEEP", "STUN", "SHACKLE_UNDEAD", "FEAR", "HORROR"},
		},
	},
}
