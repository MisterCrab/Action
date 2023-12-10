local _G, pairs, type, next, setmetatable, table, math, tonumber, select =
	  _G, pairs, type, next, setmetatable, table, math, tonumber, select 
	  
local wipe											= _G.wipe
local round											= _G.round
local strsub										= _G.strsub	  
local abs 											= math.abs	 
local tsort											= table.sort	  
	  
local TMW 											= _G.TMW

local A 											= _G.Action
local CONST 										= A.Const
local Listener										= A.Listener
local isEnemy										= A.Bit.isEnemy
local TeamCacheFriendly								= A.TeamCache.Friendly
local TeamCacheFriendlyUNITs						= TeamCacheFriendly.UNITs
local BuildToC										= A.BuildToC
local PlayerClass									= A.PlayerClass
	  
local CombatLogGetCurrentEventInfo					= _G.CombatLogGetCurrentEventInfo	  
	  
local 	 UnitIsUnit, 	UnitGUID, 	 UnitCanAttack 	= 
	  _G.UnitIsUnit, _G.UnitGUID, _G.UnitCanAttack
	  
local GameBuild 									= tonumber((select(2, _G.GetBuildInfo())))		  
	  
local player 										= "player"
local function sortByHighest(x, y)
	return x > y
end

local getUnitTarget = setmetatable({}, { 
	__index = function(t, k)
		t[k] = k .. "target"
		return t[k]
	end,
})

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, A_Player, A_CombatTracker, A_IsInRange

Listener:Add("ACTION_EVENT_MULTI_UNITS", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 
		A_Unit 							 			= A.Unit 
		A_Player									= A.Player
		A_CombatTracker								= A.CombatTracker		
		A_IsInRange									= A.IsInRange

		Listener:Remove("ACTION_EVENT_MULTI_UNITS", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------
	  
-------------------------------------------------------------------------------
-- Locals: MultiUnits
-------------------------------------------------------------------------------	  
local MultiUnits 									= {
	activeUnitPlates 								= {},
	activeUnitPlatesAny								= {},
	--activeUnitPlatesGUID 							= {},
	activeExplosives								= {},
	activeCondemnedDemons							= {},
	activeVoidTendrils								= {},
	activeUnitCLEU 									= {},
	tempEnemies										= {},
	timeStampCLEU									= 0,
	onEventWipeCLEU									= {
		["UNIT_DIED"]								= true,
		["UNIT_DESTROYED"]							= true,
		["UNIT_DISSIPATES"]							= true,
		["PARTY_KILL"] 								= true,
		["SPELL_INSTAKILL"] 						= true,
	},
}

local MultiUnitsActiveUnitPlates					= MultiUnits.activeUnitPlates 		-- Only enemies 
local MultiUnitsActiveUnitPlatesAny					= MultiUnits.activeUnitPlatesAny 	-- Enemies + Friendly
--local MultiUnitsActiveUnitPlatesGUID				= MultiUnits.activeUnitPlatesGUID
local MultiUnitsActiveExplosives					= MultiUnits.activeExplosives
local MultiUnitsActiveCondemnedDemons				= MultiUnits.activeCondemnedDemons
local MultiUnitsActiveVoidTendrils					= MultiUnits.activeVoidTendrils
local MultiUnitsActiveUnitCLEU						= MultiUnits.activeUnitCLEU
local MultiUnitsTempEnemies							= MultiUnits.tempEnemies
local MultiUnitsOnEventWipeCLEU						= MultiUnits.onEventWipeCLEU

-- Nameplates
MultiUnits.AddNameplate								= function(unitID)
	if UnitCanAttack(player, unitID) then  
		-- Patch 8.2
		-- 1519 is The Eternal Palace: Precipice of Dreams
		if A.ZoneID ~= 1519 or not A_Unit(unitID):InGroup() then
			MultiUnitsActiveUnitPlates[unitID] 		= getUnitTarget[unitID]
			MultiUnitsActiveUnitPlatesAny[unitID] 	= getUnitTarget[unitID]
			if A_Unit(unitID):IsExplosives() then 
				MultiUnitsActiveExplosives[unitID] = getUnitTarget[unitID]
			end 
			
			-- SL
			if PlayerClass == "DEMONHUNTER" and A_Unit(unitID):IsCondemnedDemon() then 
				MultiUnitsActiveCondemnedDemons[unitID] = getUnitTarget[unitID]
			end 
			
			-- DF
			if A_Unit(unitID):IsVoidTendril() then 
				MultiUnitsActiveVoidTendrils[unitID] = getUnitTarget[unitID]
			end 
			--local GUID 								= UnitGUID(unitID)
			--if GUID then 
				--MultiUnitsActiveUnitPlatesGUID[GUID] 	= getUnitTarget[unitID]
			--end 		
		end 
	else 
		MultiUnitsActiveUnitPlatesAny[unitID] = getUnitTarget[unitID]
	end
end

MultiUnits.RemoveNameplate							= function(unitID)
    MultiUnitsActiveUnitPlates[unitID] 				= nil
    MultiUnitsActiveUnitPlatesAny[unitID] 			= nil
	MultiUnitsActiveExplosives[unitID] 				= nil 
	MultiUnitsActiveCondemnedDemons[unitID] 		= nil 
	MultiUnitsActiveVoidTendrils[unitID] 			= nil 
	--local GUID 									= UnitGUID(unitID)
	--if GUID then 
		--MultiUnitsActiveUnitPlatesGUID[GUID] 		= nil
	--end 
end 

MultiUnits.OnResetSpecificUnits						= function()
	wipe(MultiUnitsActiveExplosives)
	wipe(MultiUnitsActiveCondemnedDemons)
	wipe(MultiUnitsActiveVoidTendrils)
end 

MultiUnits.OnResetNameplates						= function()
	wipe(MultiUnitsActiveUnitPlates)
	wipe(MultiUnitsActiveUnitPlatesAny)
	wipe(MultiUnitsActiveExplosives)
	wipe(MultiUnitsActiveCondemnedDemons)
	wipe(MultiUnitsActiveVoidTendrils)
	--wipe(MultiUnitsActiveUnitPlatesGUID)
end 

-- CLEU 
MultiUnits.OnEventCLEU								= function(...)
	local ts, event, _, SourceGUID, _, SourceFlags, _, DestGUID, _, DestFlags,_, spellID, spellName, _, auraType, Amount = CombatLogGetCurrentEventInfo()
	if isEnemy(DestFlags) then 
		local lastSix = strsub(event, -6)
		if lastSix == "DAMAGE" or ((event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH") and auraType == "DEBUFF" and TeamCacheFriendlyUNITs[player] == SourceGUID) then 
			ts = round(ts, 0)
			-- Create or update 
			if not MultiUnitsActiveUnitCLEU[SourceGUID] then
				MultiUnitsActiveUnitCLEU[SourceGUID] = setmetatable({ TS = ts }, { __mode = "kv" })
			elseif MultiUnitsActiveUnitCLEU[SourceGUID].TS + 1.5 <= ts then
				MultiUnitsActiveUnitCLEU[SourceGUID].TS = ts
			end 						
			
			if abs(ts - MultiUnitsActiveUnitCLEU[SourceGUID].TS) < 0.1 then 
				MultiUnitsActiveUnitCLEU[SourceGUID].TS = ts 
				MultiUnitsActiveUnitCLEU[SourceGUID][DestGUID] = TMW.time
			end 
		end 
	end 
		
	if MultiUnitsOnEventWipeCLEU[event] then 
		for sGUID in pairs(MultiUnitsActiveUnitCLEU) do 
			MultiUnitsActiveUnitCLEU[sGUID][DestGUID] = nil 
		end 
	end 
end 

MultiUnits.OnInitCLEU								= function()
	if A.IamRanger and not A.IamHealer then 
		Listener:Add("ACTION_EVENT_MULTI_UNITS_CLEU", "COMBAT_LOG_EVENT_UNFILTERED", 	MultiUnits.OnEventCLEU		)
		Listener:Add("ACTION_EVENT_MULTI_UNITS_CLEU", "PLAYER_REGEN_ENABLED", 			MultiUnits.OnResetCLEU		)
		Listener:Add("ACTION_EVENT_MULTI_UNITS_CLEU", "PLAYER_REGEN_DISABLED", 			MultiUnits.OnRegenDisabled	)
		return 
	end          
			
	Listener:Remove("ACTION_EVENT_MULTI_UNITS_CLEU", "COMBAT_LOG_EVENT_UNFILTERED")
	Listener:Remove("ACTION_EVENT_MULTI_UNITS_CLEU", "PLAYER_REGEN_ENABLED")
	Listener:Remove("ACTION_EVENT_MULTI_UNITS_CLEU", "PLAYER_REGEN_DISABLED")		 
	MultiUnits.OnResetCLEU()
end 

MultiUnits.OnResetCLEU								= function()
	wipe(MultiUnitsActiveUnitCLEU)
	wipe(MultiUnitsTempEnemies)
end 

-- Shared
MultiUnits.OnResetAll								= function(isInitialLogin)
	if not isInitialLogin then 
		MultiUnits.OnResetNameplates()
		MultiUnits.OnResetCLEU()
	end 
end 

MultiUnits.OnRegenDisabled							= function()
	-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
	local SpellLastCast = A_CombatTracker:GetSpellLastCast(player, A.LastPlayerCastID)
	if (SpellLastCast == 0 or SpellLastCast > 1.5) and A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel and not A_Player:IsStealthed() and A_Player:CastTimeSinceStart() > 5 then 
		MultiUnits.OnResetCLEU()
	end 
end 

-------------------------------------------------------------------------------
-- OnEvent
-------------------------------------------------------------------------------	  
Listener:Add("ACTION_EVENT_MULTI_UNITS_ALL", "PLAYER_ENTERING_WORLD",   			MultiUnits.OnResetAll) 
Listener:Add("ACTION_EVENT_MULTI_UNITS_NAMEPLATES", "NAME_PLATE_UNIT_ADDED",	  	MultiUnits.AddNameplate)
Listener:Add("ACTION_EVENT_MULTI_UNITS_NAMEPLATES", "NAME_PLATE_UNIT_REMOVED", 		MultiUnits.RemoveNameplate)
Listener:Add("ACTION_EVENT_MULTI_UNITS_NAMEPLATES", "PLAYER_REGEN_ENABLED", 		MultiUnits.OnResetSpecificUnits)
TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 					MultiUnits.OnInitCLEU)

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------	
A.MultiUnits = {}  

-- Nameplates 
function A.MultiUnits.GetActiveUnitPlates(self)
	-- @return table (enemy nameplates) 
	-- @usage A.MultiUnits:GetActiveUnitPlates()
	return MultiUnitsActiveUnitPlates
end 

function A.MultiUnits.GetActiveUnitPlatesAny(self)
	-- @return table (enemy + friendly nameplates) 
	-- @usage A.MultiUnits:GetActiveUnitPlatesAny()
	return MultiUnitsActiveUnitPlatesAny
end 

--[[
function A.MultiUnits.GetActiveUnitPlatesGUID(self)
	-- @return table (enemy nameplates GUID) 
	-- @usage A.MultiUnits:GetActiveUnitPlates()
	return MultiUnitsActiveUnitPlatesGUID
end 
]]

function A.MultiUnits.GetBySpell(self, spell, count)
	-- @return number
	-- @usage A.MultiUnits:GetBySpell(@number or @table, @number)
	local total = 0

	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 
		if not A_Unit(namePlateUnitID):IsTotem() then 
			if type(spell) == "table" then 
				if spell:IsInRange(namePlateUnitID) then 
					total = total + 1
				end 
			else
				if A_IsInRange(spell, namePlateUnitID) then 
					total = total + 1
				end 				
			end 
		end 
		
		if count and total >= count then 
			break 
		end 
	end 
	
	return total 	
end 

function A.MultiUnits.GetBySpellIsFocused(self, unitID, spell, count)
	-- @return number, namePlateUnitID
	-- @usage A.MultiUnits:GetBySpellIsFocused(@string, @number or @table, @number)
	-- Returns count of enemies which have focusing in their target specified unitID 
	local total = 0
	local inRange, unitNamePlateID
	
	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 			
		if type(spell) == "table" then 
			inRange = spell:IsInRange(namePlateUnitID) 
		else
			inRange = A_IsInRange(spell, namePlateUnitID)
		end 
		
		if inRange and UnitIsUnit(namePlateUnitID .. "target", unitID) and not A_Unit(namePlateUnitID):IsTotem() then 
			total = total + 1
			unitNamePlateID = namePlateUnitID
		end 
		
		if count and total >= count then 
			break 
		end 
	end  
	
	return total, unitNamePlateID or "none"	
end 

function A.MultiUnits.GetByRange(self, range, count)
	-- @return number
	-- @usage A.MultiUnits:GetByRange(@number, @number)
	local total = 0

	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 
		if (not range or A_Unit(namePlateUnitID):CanInterract(range)) and not A_Unit(namePlateUnitID):IsTotem() then 
			total = total + 1
		end 
		
		if count and total >= count then 
			break 
		end 
	end  
	
	return total 	
end 
A.MultiUnits.GetByRange = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRange)

function A.MultiUnits.GetByRangeInCombat(self, range, count, upTTD)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeInCombat(@number, @number, @number)
	-- All options are optimal
	local total = 0

	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 
		if (A_Unit(namePlateUnitID):CombatTime() > 0 or A_Unit(namePlateUnitID):IsDummy()) and (not range or A_Unit(namePlateUnitID):CanInterract(range)) and (not upTTD or A_Unit(namePlateUnitID):TimeToDie() >= upTTD) and not A_Unit(namePlateUnitID):IsTotem() then 
			total = total + 1
		end 
		
		if count and total >= count then 
			break 
		end 
	end 
	
	return total 
end 
A.MultiUnits.GetByRangeInCombat = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeInCombat)

function A.MultiUnits.GetByRangeCasting(self, range, count, kickAble, spells)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeCasting(@number, @number, @boolean, @table or @spellName or @spellID)
	-- All options are optimal, spells can be table { 123, "Frost Bolt" } or just single spell without table and it can be noted as spellName, spellID or both
	local total = 0

	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 
		local castName, castStartTime, castEndTime, notInterruptable, spellID = A_Unit(namePlateUnitID):IsCasting()
		if castName and (not range or A_Unit(namePlateUnitID):CanInterract(range)) and (not kickAble or not notInterruptable) then -- totems can casting
			if spells then 
				if type(spells) == "table" then 
					for i = 1, #spells do 
						if type(spells[i]) == "number" then 
							if spellID == spells[i] then 
								total = total + 1
							end 
						else 
							if castName == spells[i] then 
								total = total + 1
							end 
						end 						
					end 
				else
					if type(spells) == "number" then 
						if spellID == spells then 
							total = total + 1
						end 
					else 
						if castName == spells then 
							total = total + 1
						end 
					end 
				end 
			else 
				total = total + 1
			end
		end 
		
		if count and total >= count then 
			break 
		end 
	end  
	
	return total 
end 
A.MultiUnits.GetByRangeCasting = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeCasting)

function A.MultiUnits.GetByRangeTaunting(self, range, count, upTTD)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeTaunting(@number, @number, @number)
	-- All options are optimal
	local total = 0

	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 
		if A_Unit(namePlateUnitID):CombatTime() > 0 and not A_Unit(namePlateUnitID):IsPlayer() and not A_Unit(namePlateUnitID .. "target"):IsTank() and not A_Unit(namePlateUnitID):IsBoss() and (not range or A_Unit(namePlateUnitID):CanInterract(range)) and (not upTTD or A_Unit(namePlateUnitID):TimeToDie() >= upTTD) and not A_Unit(namePlateUnitID):IsTotem() then 
			total = total + 1
		end 
		
		if count and total >= count then 
			break 
		end 
	end  
	
	return total 
end 
A.MultiUnits.GetByRangeTaunting = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeTaunting)

function A.MultiUnits.GetByRangeMissedDoTs(self, range, count, deBuffs, upTTD)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeMissedDoTs(@number, @number, @table or @number, @number)
	-- deBuffs is required, rest options are optimal
	local total = 0

	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 
		if (not A.IsInPvP or A_Unit(namePlateUnitID):IsPlayer()) and A_Unit(namePlateUnitID):CombatTime() > 0 and (not range or A_Unit(namePlateUnitID):CanInterract(range)) and (not upTTD or A_Unit(namePlateUnitID):TimeToDie() >= upTTD) and A_Unit(namePlateUnitID):HasDeBuffs(deBuffs, true) == 0 and not A_Unit(namePlateUnitID):IsTotem() then 
			total = total + 1
		end 
		
		if count and total >= count then 
			break 
		end 
	end  
	
	return total 
end 
A.MultiUnits.GetByRangeMissedDoTs = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeMissedDoTs)

function A.MultiUnits.GetByRangeAppliedDoTs(self, range, count, deBuffs, upTTD)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeAppliedDoTs(@number, @number, @table or @number, @number)
	-- deBuffs is required, rest options are optimal
	local total = 0

	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 
		if A_Unit(namePlateUnitID):CombatTime() > 0 and (not range or A_Unit(namePlateUnitID):CanInterract(range)) and (not upTTD or A_Unit(namePlateUnitID):TimeToDie() >= upTTD) and A_Unit(namePlateUnitID):HasDeBuffs(deBuffs, true) > 0 and not A_Unit(namePlateUnitID):IsTotem() then 
			total = total + 1
		end 
		
		if count and total >= count then 
			break 
		end 
	end  
	
	return total 
end 
A.MultiUnits.GetByRangeAppliedDoTs = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeAppliedDoTs)

function A.MultiUnits.GetByRangeIsFocused(self, unitID, range, count)
	-- @return number, namePlateUnitID
	-- @usage A.MultiUnits:GetByRangeIsFocused(@string, @number, @number)
	-- Returns count of enemies which have focusing in their target specified unitID 
	local total = 0
	local unitNamePlateID

	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 
		if UnitIsUnit(namePlateUnitID .. "target", unitID) and (not range or A_Unit(namePlateUnitID):CanInterract(range)) and not A_Unit(namePlateUnitID):IsTotem() then 
			total = total + 1
			unitNamePlateID = namePlateUnitID
		end 
		
		if count and total >= count then 
			break 
		end 
	end  
	
	return total, unitNamePlateID or "none"	
end 
A.MultiUnits.GetByRangeIsFocused = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeIsFocused)

function A.MultiUnits.GetByRangeAreaTTD(self, range)
	-- @return number
	-- @usage A.MultiUnits:GetByRangeAreaTTD(@number)
	local total, ttds = 0, 0

	for namePlateUnitID in pairs(MultiUnitsActiveUnitPlates) do 
		if (not range or A_Unit(namePlateUnitID):CanInterract(range)) and not A_Unit(namePlateUnitID):IsTotem() then 
			total = total + 1
			ttds = ttds + A_Unit(namePlateUnitID):TimeToDie()
		end 
	end  
	
	if total > 0 then 
		return ttds / total 
	else 
		return total 	
	end 
end 
A.MultiUnits.GetByRangeAreaTTD = A.MakeFunctionCachedDynamic(A.MultiUnits.GetByRangeAreaTTD)

-- CLEU
function A.MultiUnits.GetActiveEnemies(self, timer, skipClear)
	-- @return number 
	-- @usage for range specs, A.MultiUnits:GetActiveEnemies(5) or A.MultiUnits:GetActiveEnemies()
	-- skipClear is argument which will prevent to clear old destinations if it's true
	
	if not A.IamRanger then
		A.Print("[Error] MultiUnits - You're not ranged specialization to use Action.MultiUnits:GetActiveEnemies function!")
	end 
	
	local total = 0
	local timer = timer or 5
	-- Check what everything is valid to use CLEU 
	if next(MultiUnitsActiveUnitCLEU) and A_Unit("target"):IsEnemy() then 
		local tGUID = UnitGUID("target")
		if tGUID then
			-- Count by 'timer' cleaved destinations
			wipe(MultiUnitsTempEnemies)
			
			-- Get sourceGUID and his destinations
			for sGUID, sGUIDdests in pairs(MultiUnitsActiveUnitCLEU) do 
				-- If sourceGUID has our targetGUID
				if sGUIDdests[tGUID] then 	
					local counter = 0
					
					for dGUID, dGUIDtime in pairs(sGUIDdests) do 
						if dGUID ~= "TS" then 
							-- Clear old to make less resource eat on the next function use 
							if not skipClear and TMW.time - dGUIDtime > timer then 
								sGUIDdests[dGUID] = nil 
							-- Add counter 
							else 
								counter = counter + 1
							end 
						end 
					end 
					
					-- Put counter in temp which will be used to summary all results and return by sort highest counter
					if counter > 0 then 
						MultiUnitsTempEnemies[#MultiUnitsTempEnemies + 1] = counter
					end 
				end 
			end 
			
			-- Summary if something was found 
			if #MultiUnitsTempEnemies > 0 then 
				if #MultiUnitsTempEnemies > 1 then 
					tsort(MultiUnitsTempEnemies, sortByHighest)				
				end 
				
				total = MultiUnitsTempEnemies[1]
			end 
		end 
	end 
	
	-- Alternative search by in combat nameplates by range (in case if CLEU went wrong)
	if total and total <= 0 then 
		total = self:GetByRangeInCombat(nil, 10)
	end 
	
	return total or 0
end 
A.MultiUnits.GetActiveEnemies = A.MakeFunctionCachedDynamic(A.MultiUnits.GetActiveEnemies, CONST.CACHE_DEFAULT_TIMER_MULTIUNIT_CLEU)

-- Explosives
function A.IsExplosivesExists()
	-- @return boolean
	if BuildToC >= 90000 or (GameBuild < 33237 or GameBuild >= 33369) then 
		if not A.IamMelee then 
			return next(MultiUnitsActiveExplosives)
		elseif next(MultiUnitsActiveExplosives) then 
			for unitID in pairs(MultiUnitsActiveExplosives) do 
				if A_Unit(unitID):GetRange() <= 10 and not A_Unit(unitID):InLOS() then 
					return true 
				end 
			end 
		end 
	elseif next(MultiUnitsActiveExplosives) then 
		for unitID in pairs(MultiUnitsActiveExplosives) do 
			if (not A.IamMelee or A_Unit(unitID):GetRange() <= 10) and (A_Unit(unitID):CombatTime() > 0 or A_Unit(unitID):HealthPercent() < 100) and not A_Unit(unitID):InLOS() then 
				return true 
			end 
		end 
	end 
end 

-- CondemnedDemons
function A.IsCondemnedDemonsExists()
	-- @return boolean
	if BuildToC >= 90000 and PlayerClass == "DEMONHUNTER" then 
		if not A.IamMelee then 
			return next(MultiUnitsActiveCondemnedDemons)
		elseif next(MultiUnitsActiveCondemnedDemons) then 
			for unitID in pairs(MultiUnitsActiveCondemnedDemons) do 
				if A_Unit(unitID):GetRange() <= 5 and not A_Unit(unitID):InLOS() then 
					return true 
				end 
			end 
		end 
	end 
end 

-- VoidTendrils
function A.IsVoidTendrilsExists(isAffectedMe)
	-- @return boolean
	if BuildToC >= 100000 and A.IsInPvP and next(MultiUnitsActiveVoidTendrils) then 
		local range 
		for unitID, unitIDtarget in pairs(MultiUnitsActiveVoidTendrils) do 
			range = A_Unit(unitID):GetRange()
			if (range <= 10 or (not A.IamMelee and range <= 40)) and (not isAffectedMe or (UnitIsUnit(unitIDtarget, player) and A_Unit(player):HasDeBuffs(114404) > 0)) and not A_Unit(unitID):InLOS() then 
				return true 
			end 
		end 
	end 
end 
