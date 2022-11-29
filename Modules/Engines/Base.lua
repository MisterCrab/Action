-------------------------------------------------------------------------------
--[[ 
Global nil-able variables:
A.Zone				(@string)		"none", "pvp", "arena", "party", "raid", "scenario"
A.ZoneID			(@number) 		wow.gamepedia.com/UiMapID
A.IsInInstance		(@boolean)
A.TimeStampZone 	(@number)
A.TimeStampDuel 	(@number)
A.IsInPvP 			(@boolean)
A.IsInDuel			(@boolean)
A.IsInWarMode		(@boolean)

Global tables:
A.InstanceInfo 		(@table: Name, Type, difficultyID, ID, GroupSize, isRated, KeyStone)
A.TeamCache			(@table) - return cached units + info about friendly and enemy group
]]
-------------------------------------------------------------------------------
local _G, pairs, type, math 					= 
	  _G, pairs, type, math
	  
local TMW 										= _G.TMW
local A   										= _G.Action
local CONST 									= A.Const
local Listener									= A.Listener	

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit 

Listener:Add("ACTION_EVENT_BASE", "ADDON_LOADED", function(event, addonName) -- "ACTION_EVENT_BASE" fires with arg1 event!
	if addonName == CONST.ADDON_NAME then 
		A_Unit = A.Unit 
		Listener:Remove("ACTION_EVENT_BASE", "ADDON_LOADED")	
	end 	
end)
-------------------------------------------------------------------------------

local InstanceInfo								= {}
local TeamCache									= { 
	Friendly 									= {
		Size									= 1,
		MaxSize									= 1,
		UNITs									= {},
		GUIDs									= {},
		IndexToPLAYERs							= {},
		IndexToPETs								= {},
		-- [[ Retail only ]]
		HEALER									= {},
		TANK									= {},
		DAMAGER									= {},
		DAMAGER_MELEE							= {},
		DAMAGER_RANGE							= {},
	},
	Enemy 										= {
		Size 									= 0,
		MaxSize									= 0,
		UNITs									= {},
		GUIDs									= {},
		IndexToPLAYERs							= {},
		IndexToPETs								= {},	
		-- [[ Retail only ]]		
		HEALER									= {},
		TANK									= {},
		DAMAGER									= {},
		DAMAGER_MELEE							= {},
		DAMAGER_RANGE							= {},
	},
}

local TeamCacheFriendly 						= TeamCache.Friendly
local TeamCacheFriendlyUNITs					= TeamCacheFriendly.UNITs -- unitID to unitGUID
local TeamCacheFriendlyGUIDs					= TeamCacheFriendly.GUIDs -- unitGUID to unitID
local TeamCacheFriendlyIndexToPLAYERs			= TeamCacheFriendly.IndexToPLAYERs
local TeamCacheFriendlyIndexToPETs				= TeamCacheFriendly.IndexToPETs
local TeamCacheFriendlyHEALER					= TeamCacheFriendly.HEALER
local TeamCacheFriendlyTANK						= TeamCacheFriendly.TANK
local TeamCacheFriendlyDAMAGER					= TeamCacheFriendly.DAMAGER
local TeamCacheFriendlyDAMAGER_MELEE			= TeamCacheFriendly.DAMAGER_MELEE
local TeamCacheFriendlyDAMAGER_RANGE			= TeamCacheFriendly.DAMAGER_RANGE
local TeamCacheEnemy 							= TeamCache.Enemy
local TeamCacheEnemyUNITs						= TeamCacheEnemy.UNITs -- unitID to unitGUID
local TeamCacheEnemyGUIDs						= TeamCacheEnemy.GUIDs -- unitGUID to unitID
local TeamCacheEnemyIndexToPLAYERs				= TeamCacheEnemy.IndexToPLAYERs
local TeamCacheEnemyIndexToPETs					= TeamCacheEnemy.IndexToPETs
local TeamCacheEnemyHEALER						= TeamCacheEnemy.HEALER
local TeamCacheEnemyTANK						= TeamCacheEnemy.TANK
local TeamCacheEnemyDAMAGER						= TeamCacheEnemy.DAMAGER
local TeamCacheEnemyDAMAGER_MELEE				= TeamCacheEnemy.DAMAGER_MELEE
local TeamCacheEnemyDAMAGER_RANGE				= TeamCacheEnemy.DAMAGER_RANGE

local huge 										= math.huge 
local wipe										= _G.wipe 
local C_PvP 									= _G.C_PvP
local C_ChallengeMode							= _G.C_ChallengeMode
local C_Map										= _G.C_Map

local 	 IsInRaid, 	  IsInGroup, 	IsInInstance, 	 IsActiveBattlefieldArena, 	  RequestBattlefieldScoreData = 
	  _G.IsInRaid, _G.IsInGroup, _G.IsInInstance, _G.IsActiveBattlefieldArena, _G.RequestBattlefieldScoreData

local 	 UnitIsUnit, 	UnitInBattleground,    UnitGUID = 
	  _G.UnitIsUnit, _G.UnitInBattleground, _G.UnitGUID

local 	 GetInstanceInfo, 	 GetNumArenaOpponents, 	  GetNumArenaOpponentSpecs,    GetNumBattlefieldScores,    GetNumGroupMembers =
	  _G.GetInstanceInfo, _G.GetNumArenaOpponents, _G.GetNumArenaOpponentSpecs, _G.GetNumBattlefieldScores, _G.GetNumGroupMembers

local IsWarModeDesired							= C_PvP.IsWarModeDesired
local IsRatedMap								= C_PvP.IsRatedMap	  
local GetActiveKeystoneInfo 					= C_ChallengeMode.GetActiveKeystoneInfo	
local GetBestMapForUnit 						= C_Map.GetBestMapForUnit	

local player 									= "player"
local pet										= "pet"
local target 									= "target"
local targettarget								= "targettarget"

-------------------------------------------------------------------------------
-- Instance, Zone, Mode, Duel, TeamCache
-------------------------------------------------------------------------------	  
A.TeamCache 	= TeamCache
A.InstanceInfo 	= InstanceInfo

function A:GetTimeSinceJoinInstance()
	-- @return number
	return (self.TimeStampZone and TMW.time - self.TimeStampZone) or huge
end 

function A:GetTimeDuel()
	-- @return number
	return (self.IsInDuel and TMW.time - self.TimeStampDuel - CONST.CACHE_DEFAULT_OFFSET_DUEL) or 0
end 
 
function A:CheckInPvP()
	-- @return boolean
    if  
		self.Zone == "arena" or 
		self.Zone == "pvp" or 
		UnitInBattleground(player) or 
		IsActiveBattlefieldArena() or
		( self.Zone ~= "party" and self.Zone ~= "raid" and self.Zone ~= "scenario" and IsWarModeDesired() ) or
		-- Patch 8.2
		-- 1519 is The Eternal Palace: Precipice of Dreams
		( A.ZoneID ~= 1519 and A_Unit(target):IsPlayer() and (A_Unit(target):IsEnemy() or (A_Unit(targettarget):IsPlayer() and A_Unit(targettarget):IsEnemy())) )
	then 
		return true 
	end 
	return false 
end

function A.UI_INFO_MESSAGE_IS_WARMODE(...)
	-- @return boolean
	local _, MSG = ...		
    return (type(MSG) == "string" and (MSG == CONST.ERR_PVP_WARMODE_TOGGLE_OFF or MSG == CONST.ERR_PVP_WARMODE_TOGGLE_ON)) or false
end 

local GetEventInfo 						= {
	CHALLENGE_MODE_COMPLETED 			= "CHALLENGE",
	CHALLENGE_MODE_RESET				= "CHALLENGE",
	--CHALLENGE_MODE_KEYSTONE_SLOTTED 	= "CHALLENGE", -- seems doesn't triggered enough well since map update theoricaly delayed
	CHALLENGE_MODE_START				= "CHALLENGE",
	CHALLENGE_MODE_MAPS_UPDATE			= "CHALLENGE",
	UPDATE_INSTANCE_INFO				= "INSTANCE",
	ZONE_CHANGED						= "ZONE",
	ZONE_CHANGED_INDOORS				= "ZONE",
	ZONE_CHANGED_NEW_AREA				= "ZONE",
	PLAYER_LOGIN						= "ENTERING",
	PLAYER_ENTERING_WORLD				= "ENTERING",
	PLAYER_ENTERING_BATTLEGROUND		= "ENTERING",
	PLAYER_TARGET_CHANGED				= "TARGET",	
	DUEL_REQUESTED						= "DUEL",
	DUEL_FINISHED						= "DUEL",	
	UI_INFO_MESSAGE						= "UI_INFO_MESSAGE",
	GROUP_ROSTER_UPDATE					= "UNITS",
	ARENA_OPPONENT_UPDATE				= "UNITS",
}
local IsInstanceZone					= {
	CHALLENGE							= true,
	INSTANCE							= true,
	ZONE								= true,
	ENTERING							= true,		
}
local IsModeDuel						= {
	--CHALLENGE							= true,		
	--INSTANCE							= true,
	ZONE								= true,
	ENTERING							= true,
	TARGET								= true,
	DUEL								= true,
	UI_INFO_MESSAGE						= true,
}
local IsUnitUpdate						= {
	--CHALLENGE							= true,	
	INSTANCE							= true,
	ZONE								= true,
	ENTERING							= true,
	UNITS								= true,
}

local eventInfo, oldMode, counter, guid, arena, arenapet, arenapetguid, member, memberpet, memberpetguid
local function OnEvent(event, ...)  
	eventInfo 							= GetEventInfo[event]
	
	-- Update Instance, Zone
	if IsInstanceZone[eventInfo] then
		A.IsInInstance, A.Zone 			= IsInInstance()
		A.ZoneID 						= GetBestMapForUnit(player) or 0
		
		local name, instanceType, difficultyID, _, _, _, _, instanceID, instanceGroupSize = GetInstanceInfo()
		if name then 
			InstanceInfo.Name 			= name 
			InstanceInfo.Type 			= instanceType
			InstanceInfo.difficultyID 	= difficultyID
			InstanceInfo.ID 			= instanceID
			InstanceInfo.GroupSize		= instanceGroupSize
			InstanceInfo.isRated		= IsRatedMap() or (select(2, IsActiveBattlefieldArena()))
			InstanceInfo.KeyStone		= GetActiveKeystoneInfo() or 0
			if eventInfo ~= "CHALLENGE" then 
				A.TimeStampZone 		= TMW.time
			end 
		end 
	end 
	
	-- Update Mode, Duel
    if IsModeDuel[eventInfo] and not A.IsLockedMode then
		oldMode 						= A.IsInPvP
		
		-- Warmode
		if eventInfo == "UI_INFO_MESSAGE" and A.UI_INFO_MESSAGE_IS_WARMODE(...) then     
			A.IsInPvP 					= IsWarModeDesired()
			A.IsInWarMode 				= A.IsInPvP or nil			 
		end            
		
		-- Duel 
		if eventInfo == "DUEL" then 
			if event == "DUEL_REQUESTED" then
				A.IsInPvP, A.IsInDuel, A.TimeStampDuel = true, true, TMW.time
			else
				A.IsInPvP, A.IsInDuel, A.TimeStampDuel = A:CheckInPvP(), nil, nil				
			end   
		end 
		
		-- Zone, Target
		if eventInfo ~= "DUEL" and eventInfo ~= "UI_INFO_MESSAGE" and not A.IsInDuel then                             			
			A.IsInPvP 					= A:CheckInPvP()  						 
		end  
		
		if oldMode ~= A.IsInPvP then 
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
		end 
	end
	
	-- Update Units 
	if IsUnitUpdate[eventInfo] then 
		-- Wipe Friendly 
		for _, v in pairs(TeamCacheFriendly) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 
		
		-- Wipe Enemy
		for _, v in pairs(TeamCacheEnemy) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 		                             
		
		-- Enemy  		
		if A.Zone == "arena" then 
			-- GetNumArenaOpponentSpecs  (only retail) and can track enemies before arena start
			-- GetNumArenaOpponents after gates open 
			TeamCacheEnemy.Size = GetNumArenaOpponentSpecs and GetNumArenaOpponentSpecs() or GetNumArenaOpponents()    
			TeamCacheEnemy.Type = "arena"
			TeamCacheEnemy.MaxSize = 5
		elseif A.Zone == "pvp" then
			RequestBattlefieldScoreData()                
			TeamCacheEnemy.Size = GetNumBattlefieldScores()         
			TeamCacheEnemy.Type = "arena"
			TeamCacheEnemy.MaxSize = 40
		else
			TeamCacheEnemy.Size = 0 
			TeamCacheEnemy.Type = nil 
			TeamCacheEnemy.MaxSize = 0
		end
		TeamCacheEnemy.MaxSize = TeamCacheEnemy.Size	
		
		if TeamCacheEnemy.Size > 0 and TeamCacheEnemy.Type then  
			counter = 0
			for i = 1, huge do 
				arena = TeamCacheEnemy.Type .. i
				guid  = UnitGUID(arena)
				
				if guid then 
					counter = counter + 1
					
					TeamCacheEnemyUNITs[arena] 					= guid
					TeamCacheEnemyGUIDs[guid] 					= arena		
					TeamCacheEnemyIndexToPLAYERs[i] 			= arena		
					if A_Unit(arena):IsHealer() then 
						TeamCacheEnemyHEALER[arena] 			= arena
					elseif A_Unit(arena):IsTank() then 
						TeamCacheEnemyTANK[arena] 				= arena
					else
						TeamCacheEnemyDAMAGER[arena] 			= arena
						if A_Unit(arena):IsMelee() then 
							TeamCacheEnemyDAMAGER_MELEE[arena] 	= arena
						else 
							TeamCacheEnemyDAMAGER_RANGE[arena] 	= arena
						end                        
					end
					
					arenapet 									= TeamCacheEnemy.Type .. pet .. i
					arenapetguid 								= UnitGUID(arenapet)
					if arenapetguid then 
						TeamCacheEnemyUNITs[arenapet] 			= arenapetguid
						TeamCacheEnemyGUIDs[arenapetguid] 		= arenapet					
						TeamCacheEnemyIndexToPETs[i] 			= arenapet	
					end 
				end

				if counter >= TeamCacheEnemy.Size or i >= TeamCacheEnemy.MaxSize then 
					if counter >= TeamCacheEnemy.Size then 
						TeamCacheEnemy.MaxSize = counter
					end 
					break 
				end 
			end   
		end          
		
		-- Friendly
		TeamCacheFriendly.Size = GetNumGroupMembers()
		if IsInRaid() then
			TeamCacheFriendly.Type = "raid"
			TeamCacheFriendly.MaxSize = 40
		elseif IsInGroup() then
			TeamCacheFriendly.Type = "party"   
			TeamCacheFriendly.MaxSize = TeamCacheFriendly.Size - 1			
		else 
			TeamCacheFriendly.Type = nil 
			TeamCacheFriendly.MaxSize = TeamCacheFriendly.Size
		end  
			
		guid = UnitGUID(player)
		TeamCacheFriendlyUNITs[player] 	= guid
		TeamCacheFriendlyGUIDs[guid] 	= player 	
		
		if TeamCacheFriendly.Size > 0 and TeamCacheFriendly.Type then 
			counter = 0
			for i = 1, huge do 
				member = TeamCacheFriendly.Type .. i
				guid   = UnitGUID(member)
				
				if guid then 
					counter = counter + 1
					
					TeamCacheFriendlyUNITs[member] 						= guid 
					TeamCacheFriendlyGUIDs[guid] 						= member 
					TeamCacheFriendlyIndexToPLAYERs[i] 					= member
					if not UnitIsUnit(member, player) then 
						if A_Unit(member):IsHealer() then 
							TeamCacheFriendlyHEALER[member]	 			= member
						elseif A_Unit(member):IsTank() then  
							TeamCacheFriendlyTANK[member] 				= member
						else 
							TeamCacheFriendlyDAMAGER[member] 			= member
							if A_Unit(member):IsMelee() then 
								TeamCacheFriendlyDAMAGER_MELEE[member] 	= member
							else 
								TeamCacheFriendlyDAMAGER_RANGE[member] 	= member
							end 
						end
					end
					
					memberpet 											= TeamCacheFriendly.Type .. pet .. i
					memberpetguid 										= UnitGUID(memberpet)
					if memberpetguid then 
						TeamCacheFriendlyUNITs[memberpet] 				= memberpetguid
						TeamCacheFriendlyGUIDs[memberpetguid] 			= memberpet					
						TeamCacheFriendlyIndexToPETs[i] 				= memberpet	
					end 
				end 
				
				if counter >= TeamCacheFriendly.Size or i >= TeamCacheFriendly.MaxSize then 
					if counter >= TeamCacheFriendly.Size then 
						TeamCacheFriendly.MaxSize = counter
					end 
					break 
				end 
			end 
		end	

		if event ~= "PLAYER_LOGIN" then
			TMW:Fire("TMW_ACTION_GROUP_UPDATE", event)					-- callback is used in Action UI [8] tab 
		end 
	end 
	
	if eventInfo == "ENTERING" and event ~= "PLAYER_LOGIN" then
		TMW:Fire("TMW_ACTION_ENTERING", event)							-- callback is used in PetLibrary.lua, HealingEngine.lua, HybridProfile.lua (retired) 
	end 
	
	TMW:Fire("TMW_ACTION_DEPRECATED") 									-- TODO: Remove in the future
end 

-- Register events 
for event in pairs(GetEventInfo) do 
	Listener:Add("ACTION_EVENT_BASE", event, OnEvent)
end 