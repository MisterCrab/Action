--[[ DOCUMENTATION:
-- Healing Engine has callback "TMW_ACTION_HEALINGENGINE_UNIT_UPDATE"
TMW:RegisterCallback("TMW_ACTION_HEALINGENGINE_UNIT_UPDATE", function(callbackEvent, thisUnit, db, QueueOrder)
	-- Example of implementation is function PerformByProfileHP (in that func 'self' is 'thisUnit')
	-- QueueOrder is used to save some FPS due iterations through all units, 
	-- So once required role is found for certain options (i.e. useDispel)
	-- we can save it for that role and don't use this check again for same role which will save FPS
	
	-- 'thisUnit' has all keys from :Setup method, like:
	-- Unit 			= unitID
	-- GUID 			= unitGUID			
	-- HP 				= 0-100									-- Modified Health Percent
	-- AHP 				= 0-huge 								-- Modified Health Actual
	-- MHP				= 0-huge								-- Maximum  Health Actual
	-- Role 			= "TANK", "HEALER", "DAMAGER", "NONE" 	-- Pet has "DAMAGER" role here
	-- LUA 				= @string 
	-- Enabled  		= @boolean								-- For function SetHealingTarget
	-- useDispel		= @boolean 
	-- useShields		= @boolean 
	-- useHoTs			= @boolean 
	-- useUtils			= @boolean 								-- Offensive and supportive spells such as BoP, Freedom and etc 
	-- isPlayer 		= @boolean 
	-- isPet 			= @boolean 
	-- isSelf	 		= @boolean 
	-- isSelectAble		= @boolean 								-- If possible to target that unit 
	-- incDMG 			= 0-huge 
	-- incOffsetDMG 	= 0-huge 
	-- realHP			= 0-100
	-- realAHP			= 0-huge 				
end)
-- Rest API located at the end of this file 
--]]

local _G, type, pairs, ipairs, setmetatable, table, unpack, math, error = 
	  _G, type, pairs, ipairs, setmetatable, table, unpack, math, error	  
	  
local TMW 								= _G.TMW
local CNDT 								= TMW.CNDT							-- TODO: Remove (old profiles)
local Env 								= CNDT.Env							-- TODO: Remove (old profiles)

local A 								= _G.Action
local CONST 							= A.Const
local UC								= A.Data.UC
local Listener							= A.Listener
local MakeFunctionCachedDynamic			= A.MakeFunctionCachedDynamic
local MakeFunctionCachedStatic			= A.MakeFunctionCachedStatic
local TeamCacheFriendly					= A.TeamCache.Friendly
local TeamCacheFriendlyUNITs			= TeamCacheFriendly.UNITs 			-- unitID to GUID 
local TeamCacheFriendlyGUIDs			= TeamCacheFriendly.GUIDs 			-- GUID to unitID 
local TeamCacheFriendlyIndexToPLAYERs	= TeamCacheFriendly.IndexToPLAYERs 	-- index to unitID 
local TeamCacheFriendlyIndexToPETs		= TeamCacheFriendly.IndexToPETs 	-- index to unitID
local GetToggle							= A.GetToggle
local AuraIsValid						= A.AuraIsValid
local BuildToC							= A.BuildToC
local StdUi								= A.StdUi
local RunLua							= StdUi.RunLua
local isClassic							= StdUi.isClassic 

local GetLOS							= _G.GetLOS

-- [[ Retail ]]	
local Azerite 							= LibStub("AzeriteTraits")			-- TODO: Remove 
--

-- [[ Retired ]]
local RetiredToggleHE					= {									-- TODO: Remove (old profiles)
	["TANK"]							= {
		["TANK"]						= true,
	},
	["HEALER"]							= {
		["HEALER"]						= true,
	},
	["DAMAGER"]							= {
		["DAMAGER"]						= true,
	},
	["RAID"]							= {
		["HEALER"]						= true,
		["DAMAGER"]						= true,
	},
	["ALL"]								= {
		["TANK"]						= true, 
		["HEALER"]						= true,
		["DAMAGER"]						= true,
	},
}
local function IsRetiredProfile()
	return not A.IsInitialized and A.IsGGLprofile
end 
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local 	A_Unit, A_IsUnitFriendly, A_IsUnitEnemy, A_PauseChecks,
		-- [[ Retail ]]
		A_GetLatency, A_GetCurrentGCD, A_GetGCD, A_GetSpellDescription
		--

Listener:Add("ACTION_EVENT_HEALINGENGINE", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 
		A_Unit 							= A.Unit 
		A_IsUnitFriendly 				= A.IsUnitFriendly
		A_IsUnitEnemy					= A.IsUnitEnemy
		A_PauseChecks					= A.PauseChecks
		
		-- [[ Retail ]] 
		A_GetLatency					= A.GetLatency
		A_GetCurrentGCD					= A.GetCurrentGCD
		A_GetGCD						= A.GetGCD
		A_GetSpellDescription			= A.GetSpellDescription		
		-- 

		Listener:Remove("ACTION_EVENT_HEALINGENGINE", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------
	  
local tremove							= table.remove 
local tsort								= table.sort 
local huge 								= math.huge
local math_max							= math.max
local math_min							= math.min
local wipe 								= _G.wipe

local 	 UnitGUID, 	  UnitIsUnit 		= 
	  _G.UnitGUID, _G.UnitIsUnit
	  	  
local PredictOptions, SelectStopOptions, dbUnitIDs, db, profileActionDB 
local inCombat, inGroup, maxGroupSize  
local player 							= "player"	
local pet 								= "pet" 
local focus 							= "focus"
local target 							= "target"
local mouseover							= "mouseover"
local none 								= "none"
local healingTarget						= none 
local healingTargetGUID					= none 
local healingTargetDelay 				= 0	  
local healingTargetDelayByEvent			= false 
local isFocusHealing					= false

local frame 							= _G.CreateFrame("Frame", "TargetColor", _G.UIParent)
if _G.BackdropTemplateMixin == nil and frame.SetBackdrop then -- Only expac less than Shadowlands
	frame:SetBackdrop(nil)
end 
frame:SetFrameStrata("TOOLTIP")
frame:SetToplevel(true)
frame:SetSize(1, 1)
frame:SetScale(1)
frame:SetPoint("TOPLEFT", 163, 0)
frame.texture = frame:CreateTexture(nil, "OVERLAY")
frame.texture:SetAllPoints(true)
frame.Colors 							= {
	none								= { UC[0]() },
	-- Raid 
	raid1								= { UC[1]() },
	raid2								= { UC[2]() },
	raid3								= { UC[3]() },
	raid4								= { UC[4]() },
	raid5								= { UC[5]() },
	raid6								= { UC[6]() },
	raid7								= { UC[7]() },
	raid8								= { UC[8]() },
	raid9								= { UC[9]() },
	raid10								= { UC[10]() },
	raid11								= { UC[11]() },
	raid12								= { UC[12]() },
	raid13								= { UC[13]() },
	raid14								= { UC[14]() },
	raid15								= { UC[15]() },
	raid16								= { UC[16]() },
	raid17								= { UC[17]() },
	raid18								= { UC[18]() },
	raid19								= { UC[19]() },
	raid20								= { UC[20]() },
	raid21								= { UC[21]() },
	raid22								= { UC[22]() },
	raid23								= { UC[23]() },
	raid24								= { UC[24]() },
	raid25								= { UC[25]() },
	raid26								= { UC[26]() },
	raid27								= { UC[27]() },
	raid28								= { UC[28]() },
	raid29								= { UC[29]() },
	raid30								= { UC[30]() },
	raid31								= { UC[31]() },
	raid32								= { UC[32]() },
	raid33								= { UC[33]() },
	raid34								= { UC[34]() },
	raid35								= { UC[35]() },
	raid36								= { UC[36]() },
	raid37								= { UC[37]() },
	raid38								= { UC[38]() },
	raid39								= { UC[39]() },
	raid40								= { UC[40]() },
	-- Party 
	party1								= { UC[41]() },
	party2								= { UC[42]() },
	party3								= { UC[43]() },
	party4								= { UC[44]() },	
	-- Player 
	player 								= { UC[45]() },	
	-- Focus 
	focus 								= { UC[46]() },	
	-- Party pet
	partypet1							= { UC[47]() },
	partypet2							= { UC[48]() },
	partypet3							= { UC[49]() },
	partypet4							= { UC[50]() },		
	-- Raid pet
	raidpet1							= { UC[51]() },
	raidpet2							= { UC[52]() },
	raidpet3							= { UC[53]() },
	raidpet4							= { UC[54]() },
	raidpet5							= { UC[55]() },
	raidpet6							= { UC[56]() },
	raidpet7							= { UC[57]() },
	raidpet8							= { UC[58]() },
	raidpet9							= { UC[59]() },
	raidpet10							= { UC[60]() },
	raidpet11							= { UC[61]() },
	raidpet12							= { UC[62]() },
	raidpet13							= { UC[63]() },
	raidpet14							= { UC[64]() },
	raidpet15							= { UC[65]() },
	raidpet16							= { UC[66]() },
	raidpet17							= { UC[67]() },
	raidpet18							= { UC[68]() },
	raidpet19							= { UC[69]() },
	raidpet20							= { UC[70]() },
	raidpet21							= { UC[71]() },
	raidpet22							= { UC[72]() },
	raidpet23							= { UC[73]() },
	raidpet24							= { UC[74]() },
	raidpet25							= { UC[75]() },
	raidpet26							= { UC[76]() },
	raidpet27							= { UC[77]() },
	raidpet28							= { UC[78]() },
	raidpet29							= { UC[79]() },
	raidpet30							= { UC[80]() },
	raidpet31							= { UC[81]() },
	raidpet32							= { UC[82]() },
	raidpet33							= { UC[83]() },
	raidpet34							= { UC[84]() },
	raidpet35							= { UC[85]() },
	raidpet36							= { UC[86]() },
	raidpet37							= { UC[87]() },
	raidpet38							= { UC[88]() },
	raidpet39							= { UC[89]() },
	raidpet40							= { UC[90]() },
}
function frame:SetColor(unitID)
	local unit = unitID or none
	if (self.unit ~= unit or self.mode ~= isFocusHealing) and self.Colors[unit] then
		local colorR, colorG, colorB, colorA = unpack(self.Colors[unit])
		if A.MetaEngine and A.MetaEngine:IsHealthy() and GetToggle(1, "DisableRegularFrames") then
			colorA = 0
		end
		self.texture:SetColorTexture(colorR, colorG, colorB, colorA)
		self.unit = unit
		self.mode = isFocusHealing
		TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "HealingEngine", isFocusHealing and "focus" or "target", unit)
	end 	
end; frame:SetColor()

local function sort_high(x, y)			-- TODO: Remove (old profiles)
	return x > y
end

local function sort_incDMG(x, y)
	return x.incDMG > y.incDMG
end

local function sort_HP(x, y) 
	return x.HP < y.HP 
end

local function sort_AHP(x, y) 
	return x.AHP < y.AHP 
end

local Data; Data 						= {
	IsRunning							= false,	
	Aura 								= {
		Innervate						= 29166,			-- For ManaManagement (Classic has same ID)
		SmokeBomb 						= 76577,			-- PvP Rogue
		DarkestDepths 					= 292127, 			-- 8.2 "The Eternal Palace: Darkest Depths"
		CorruptedExistence				= 316065,			-- 8.3 "Ny'alotha - Ny'alotha" (Ny'alotha, the Waking City)
		GluttonousMiasma				= 329298,			-- 9.0 Gluttonous Miasma, "Hungering Destroyer" boss (Castle Nathria - The Grand Walk)
		ForgeborneReveries 				= 327140,			-- 9.0 Forgeborne Reveries (Necrolords)
		Beacons 						= {156910, 53563}, 	-- TODO: Remove (old profiles)
		SumDMG							= {},				-- TODO: Remove (old profiles)
	},
	UnitIDs  							= setmetatable(
		StdUi:tGenerateHealingEngineUnitIDs({
			-- Some keys can be placed here as initial but its pointless to do since meta method Wipe will remove it before we get with touch them 
		}), { __index = {
			Wipe 						= function()
				for _, v in pairs(Data.UnitIDs) do 
					wipe(v)
				end 
			end,
		},	}),		
	Frequency 							= setmetatable(
		{
			Actual 						= {},
			Temp 						= {},
		}, { __index = { 
			Wipe 						= function()
				for k, v in pairs(Data.Frequency) do 
					if type(v) == "table" then 
						wipe(v)
					else
						Data.Frequency[k] = nil 
					end 
				end 
			end,
		}, }),
	SortedUnitIDs						= setmetatable(
		{}, { __index = {
			Wipe 						= function()
				wipe(Data.SortedUnitIDs)
			end,
		},  }),
	SortedUnitIDs_MostlyIncDMG			= setmetatable(
		{}, { __index = {
			Wipe 						= function()
				wipe(Data.SortedUnitIDs_MostlyIncDMG)
			end,
		},  }),
	QueueOrder							= setmetatable(
		{
			useDispel					= {},
			useShields					= {},
			useHoTs						= {},
			useUtils					= {},
		}, { __index = {
			Wipe 						= function()
				for k, v in pairs(Data.QueueOrder) do 
					if type(v) == "table" then 
						wipe(v)
					else
						Data.QueueOrder[k] = nil 
					end 
				end 
			end,
		},  }),
	BossIDs								= setmetatable(
		{
			-- ["bossGUID"] = { ["holderUnitID"] = true, ["holderUnitID"] = true }
			-- Also jumper back ["holderUnitID"] = "bossGUID" 
		}, { __index = {
			Wipe 						= function()
				wipe(Data.BossIDs)
			end,
		},  }),	
}

-- Push in data some locals which can be used in custom profiles if necessary 
do 
	Data.frame 							= frame
	Data.isClassic						= isClassic
	Data.sort_incDMG					= sort_incDMG
	Data.sort_HP						= sort_HP
	Data.sort_AHP						= sort_AHP
end 

local Aura 								= Data.Aura
local UnitIDs							= Data.UnitIDs
local SortedUnitIDs						= Data.SortedUnitIDs
local SortedUnitIDs_MostlyIncDMG		= Data.SortedUnitIDs_MostlyIncDMG
local Frequency							= Data.Frequency
local FrequencyActual					= Frequency.Actual 
local FrequencyTemp						= Frequency.Temp
local QueueOrder						= Data.QueueOrder
local BossIDs							= Data.BossIDs

local function PerformByProfileHP(self)
	--[[ This is BFA code. Used here for refference on callback.
	if not A.IsBasicProfile and A.IsGGLprofile and A.CurrentProfile ~= "[GGL] Template" then 
		local HP			= self.HP
		local MHP			= self.MHP
		local DMG 			= self.incOffsetDMG
		local Role 			= self.Role
		local unitID 		= self.Unit
		local isSelf 		= self.isSelf
		
		local predictDMG	= PredictOptions[2]
		local predictHoTs 	= PredictOptions[4]
				
		-- Holy Paladin 
		if A_Unit(player):HasSpec(CONST.PALADIN_HOLY) then  		
			-- Dispel 
			if self.useDispel and not QueueOrder.useDispel[Role] and Env.SpellUsable(4987) and (not A.IsInPvP or not isSelf) and Env.Dispel(unitID) then 
				QueueOrder.useDispel[Role] = true 
				
				if isSelf then 
					self:SetupOffsets(db.OffsetSelfDispel, 25)
				elseif Role == "HEALER" then
					self:SetupOffsets(db.OffsetHealersDispel, 25)
				elseif Role == "TANK" then 
					self:SetupOffsets(db.OffsetTanksDispel, 40)
				else 
					self:SetupOffsets(db.OffsetDamagersDispel, 40)
				end 				
				return 
			end 
			
			-- HoTs
			if self.useHoTs and Azerite:GetRank(287268) > 0 and Env.SpellCD(20473) <= A_GetCurrentGCD() and A_Unit(unitID, 1):HasBuffs(287280, true) <= A_GetGCD() then 
				-- Glimmer of Light 
				-- Select unit which hasn't applied Glimmer of Light while out of combat and all group at full health 
				if not QueueOrder.hasLowHealth then 
					if not inCombat and TeamCacheFriendly.Type and self.realHP == 100 then 
						QueueOrder.lastFullHealthUnit = unitID 
						self.HP = 80
						return	
					else 
						if QueueOrder.lastFullHealthUnit then 
							UnitIDs[QueueOrder.lastFullHealthUnit].HP = 100
							UnitIDs[QueueOrder.lastFullHealthUnit].AHP = UnitIDs[QueueOrder.lastFullHealthUnit].MHP
						end 
						QueueOrder.hasLowHealth = true 
					end 
				end 
				
				-- Generally, prioritize players that might die in the next few seconds > non-Beaconed tank (without Glimmer buff) > Beaconed tank (without Glimmer buff) > players without the Glimmer buff
				if not QueueOrder.useHoTs[Role] then 
					if Env.PredictHeal("HolyShock", unitID) then 
						if Role == "TANK" then 
							QueueOrder.useHoTs[Role] = true 
							if A_Unit(unitID):HasBuffs(Aura.Beacons, true) == 0 then 
								HP = 35
							else 
								HP = 45
							end 
						else 
							HP = HP - 35
						end 
					else
						HP = HP - 10
					end 
					
					self.HP = HP 
					return 
				end 
			end 
			
			if predictHoTs and HP < 100 then      
				-- Beacon HPS SYSTEM + hot current ticking and total duration
				local BestowFaith1, BestowFaith2 = A_Unit(unitID):HasBuffs(223306, true)
				if BestowFaith1 > 0 then 
					HP = HP + ( 100 * A_GetSpellDescription(223306)[1] / MHP )
				end 
				
				-- Checking if Member has Beacons on them            
				if A_Unit(unitID):HasBuffs(Aura.Beacons, true) > 0 then
					HP = HP + ( 100 * (A_Unit(player):GetHPS() * 0.4) / MHP ) - ( 100 * (predictDMG and DMG or 0) / MHP )
				end 

				self.HP = HP 
				return 
			end 
		end 
		
		-- Restor Druid 
		if A_Unit(player):HasSpec(CONST.DRUID_RESTORATION) then 	
			-- Dispel 
			if self.useDispel and not QueueOrder.useDispel[Role] and Env.SpellUsable(88423) and (not A.IsInPvP or not isSelf) and Env.Dispel(unitID) then 
				QueueOrder.useDispel[Role] = true 
				
				if isSelf then 
					self:SetupOffsets(db.OffsetSelfDispel, 25)
				elseif Role == "HEALER" then
					self:SetupOffsets(db.OffsetHealersDispel, 25)
				elseif Role == "TANK" then 
					self:SetupOffsets(db.OffsetTanksDispel, 40)
				else 
					self:SetupOffsets(db.OffsetDamagersDispel, 40)
				end 				
				return 
			end 
			
			-- HoTs
			if predictHoTs and self.useHoTs and HP < 100 then   
				local Rejuvenation1, Rejuvenation2 	= A_Unit(unitID):HasBuffs(774, true)
				local Regrowth1, Regrowth2 			= A_Unit(unitID):HasBuffs(8936, true)
				local WildGrowth1, WildGrowth2		= A_Unit(unitID):HasBuffs(48438, true)
				local Lifebloom1, Lifebloom2 		= A_Unit(unitID):HasBuffs(33763, true)                
				local Germination1, Germination2 	= A_Unit(unitID):HasBuffs(155777, true) -- Rejuvenation Talent 
				local summup = 0
				
				wipe(Aura.SumDMG)
				
				if Rejuvenation1 > 0 then 
					summup = summup + (A_GetSpellDescription(774)[1] / Rejuvenation2 * Rejuvenation1)
					Aura.SumDMG[#Aura.SumDMG + 1]	= Rejuvenation1
				else
					-- If current target is Tank then to prevent staying on that target we will cycle rest units 
					if healingTarget and healingTarget ~= "none" and A_Unit(healingTarget):IsTank() then 
						HP = HP - 15
					else 
						summup = summup - (A_GetSpellDescription(774)[1] * 3)
					end 
				end
				
				if Regrowth1 > 0 then 
					summup = summup + (A_GetSpellDescription(8936)[2] / Regrowth2 * Regrowth1)
					Aura.SumDMG[#Aura.SumDMG + 1]	= Regrowth1
				end
				
				if WildGrowth1 > 0 then 
					summup = summup + (A_GetSpellDescription(48438)[1] / WildGrowth2 * WildGrowth1)
					Aura.SumDMG[#Aura.SumDMG + 1]	= WildGrowth1                    
				end
				
				if Lifebloom1 > 0 then 
					summup = summup + (A_GetSpellDescription(33763)[1] / Lifebloom2 * Lifebloom1) 
					Aura.SumDMG[#Aura.SumDMG + 1]	= Lifebloom1    
				end
				
				if Germination1 > 0 then -- same with Rejuvenation
					summup = summup + (A_GetSpellDescription(774)[1] / Germination2 * Germination1)
					Aura.SumDMG[#Aura.SumDMG + 1]	= Germination1    
				end
				
				-- Get longer hot duration and predict incoming damage by that 
				tsort(Aura.SumDMG, sort_high)
				
				-- Now we convert it to persistent (from value to % as HP)
				if summup > 0 then 
					-- current HP % with pre casting heal + predict hot heal - predict incoming dmg DMG
					local HPHotSystem = HP + ( 100 * summup / MHP ) - ( 100 * ((predictDMG and DMG or 0) * Aura.SumDMG[1]) / MHP )
					if HPHotSystem < 100 then
						HP = HPHotSystem
					end
				end

				self.HP = HP
				return 
			end
		end
		
		-- Discipline Priest
		if A_Unit(player):HasSpec(CONST.PRIEST_DISCIPLINE) then                 
			-- Dispel 
			if self.useDispel and not QueueOrder.useDispel[Role] and (not A.IsInPvP or not isSelf) and (Env.Dispel(unitID) or Env.Purje(unitID) or Env.MassDispel(unitID)) then 
				QueueOrder.useDispel[Role] = true 
				
				if isSelf then 
					self:SetupOffsets(db.OffsetSelfDispel, 25)
				elseif Role == "HEALER" then
					self:SetupOffsets(db.OffsetHealersDispel, 25)
				elseif Role == "TANK" then 
					self:SetupOffsets(db.OffsetTanksDispel, 40)
				else 
					self:SetupOffsets(db.OffsetDamagersDispel, 40)
				end 				
				return 
			end 
			
			-- HoTs
			if self.useHoTs and not QueueOrder.useHoTs[Role] and _G.AtonementRenew_Toggle and A_Unit(unitID):HasBuffs(81749, true) <= A_GetCurrentGCD() then 	
				QueueOrder.useHoTs[Role] = true 
				
				if Role == "HEALER" then
					self:SetupOffsets(db.OffsetHealersHoTs, 45)
				elseif Role == "TANK" then 
					self:SetupOffsets(db.OffsetTanksHoTs, 45)
				else 
					self:SetupOffsets(db.OffsetDamagersHoTs, 45)
				end 				
				return 
			end 
						
			-- Misc (no QueueOrder)
			if HP < 100 then                    
				-- HoTs: Atonement priority 
				if predictHoTs and self.useHoTs and A_Unit(unitID):HasBuffs(81749, true) > 0 and Env.oPR and Env.oPR["AtonementHPS"] then 
					local default = HP + ( 100 * Env.oPR["AtonementHPS"] / MHP )
					
					if Role == "HEALER" then
						self:SetupOffsets(db.OffsetHealersHoTs, default)
					elseif Role == "TANK" then 
						self:SetupOffsets(db.OffsetTanksHoTs, default)
					else 
						self:SetupOffsets(db.OffsetDamagersHoTs, default)
					end 					
					return 
				end 
				
				-- Shields: Absorb system 
				if self.useShields and A_Unit(player):CombatTime() <= 5 and (inCombat or (( A.Zone == "arena" or A.Zone == "pvp" ) and A:GetTimeSinceJoinInstance() < 120)) and A_Unit(unitID):GetAbsorb(17) == 0 then 
					local default = HP - 10
					
					if Role == "HEALER" then
						self:SetupOffsets(db.OffsetHealersShields, default)
					elseif Role == "TANK" then 
						self:SetupOffsets(db.OffsetTanksShields, default)
					else 
						self:SetupOffsets(db.OffsetDamagersShields, default)
					end 					
					return 					
				end 
			
				-- Shields: Toggle or PrePare combat or while Rapture always
				if self.useShields and (_G.HE_Absorb or A_Unit(player):CombatTime() <= 5 or A_Unit(player):HasBuffs(47536, true) > A_GetCurrentGCD()) then 
					local default = HP + ( 100 * A_Unit(unitID):GetAbsorb(17) / MHP )
					
					if Role == "HEALER" then
						self:SetupOffsets(db.OffsetHealersShields, default)
					elseif Role == "TANK" then 
						self:SetupOffsets(db.OffsetTanksShields, default)
					else 
						self:SetupOffsets(db.OffsetDamagersShields, default)
					end 					
					return 
				end 
			end			 
		end 
		
		-- Holy Priest
		if A_Unit(player):HasSpec(CONST.PRIEST_HOLY) then
			-- Dispel 
			if self.useDispel and not QueueOrder.useDispel[Role] and (not A.IsInPvP or not isSelf) and (Env.Dispel(unitID) or Env.Purje(unitID) or Env.MassDispel(unitID)) then 
				QueueOrder.useDispel[Role] = true
								
				if isSelf then 
					self:SetupOffsets(db.OffsetSelfDispel, 25)
				elseif Role == "HEALER" then
					self:SetupOffsets(db.OffsetHealersDispel, 25)
				elseif Role == "TANK" then 
					self:SetupOffsets(db.OffsetTanksDispel, 40)
				else 
					self:SetupOffsets(db.OffsetDamagersDispel, 40)
				end 
				return 
			end 
			
			-- HoTs 
			if self.useHoTs and not QueueOrder.useHoTs[Role] and _G.AtonementRenew_Toggle and A_Unit(unitID):HasBuffs(139, true) <= A_GetCurrentGCD() then 
				QueueOrder.useHoTs[Role] = true 
				
				if Role == "HEALER" then
					self:SetupOffsets(db.OffsetHealersHoTs, 45)
				elseif Role == "TANK" then 
					self:SetupOffsets(db.OffsetTanksHoTs, 45)
				else 
					self:SetupOffsets(db.OffsetDamagersHoTs, 45)
				end 
				return 
			end 
			
			-- Misc (no QueueOrder)
			-- Note: Adjust HP if previous unit has been healed recently by spells which triggers bonus heal by talent 
			if predictHoTs and HP < 100 then 
				if Env.UnitIsTrailOfLight(unitID) then 
					-- Single Rotation 
					local ST = Env.IsIconDisplay("TMW:icon:1RhherQmOw_V") or 0
					if ST == 2061 then 
						self.HP = HP + ( 100 * (A_GetSpellDescription(2061)[1] * 0.35) / MHP )
					elseif ST == 2060 then 
						self.HP = HP + ( 100 * (A_GetSpellDescription(2060)[1] * 0.35) / MHP )
					end 
				end 
				return 
			end 			 
		end 
	   
		-- Mistweaver Monk 
		if A_Unit(player):HasSpec(CONST.MONK_MISTWEAVER) then 		
			local MK = A[CONST.MONK_MISTWEAVER]
			if MK and MK.IsDetoxAble then -- 'MK.IsDetoxAble' skips profiles with version which is lower than 15
				self.needDispel = self.useDispel and AuraIsValid(unitID, "UseDispel", "Dispel")
				-- Dispel 
				if self.needDispel and not QueueOrder.useDispel[Role] and (not A.IsInPvP or not isSelf) and MK.IsDetoxAble(unitID, (A_Unit(unitID):TimeToDie()), nil, true) then 
					QueueOrder.useDispel[Role] = true 
					self.modHP = true -- used for SetColorTarget
					
					if isSelf then 
						self:SetupOffsets(db.OffsetSelfDispel, 25)
					elseif Role == "HEALER" then
						self:SetupOffsets(db.OffsetHealersDispel, 25)
					elseif Role == "TANK" then 
						self:SetupOffsets(db.OffsetTanksDispel, 30)
					else 
						self:SetupOffsets(db.OffsetDamagersDispel, 30)
					end 					
					return 
				end 
				
				-- Utils
				if self.useUtils and not QueueOrder.useUtils[Role] and MK.IsTigersLustAble(unitID, (A_Unit(unitID):TimeToDie())) then 
					QueueOrder.useUtils[Role] = true 
					self.modHP = true -- used for SetColorTarget
					
					if Role == "HEALER" then
						self:SetupOffsets(db.OffsetHealersUtils, 35)
					elseif Role == "TANK" then 
						self:SetupOffsets(db.OffsetTanksUtils, 40)
					else 
						self:SetupOffsets(db.OffsetDamagersUtils, 40)
					end 					
					return 
				end 
				
				-- HoTs
				if self.useHoTs and not QueueOrder.useHoTs[Role] and GetToggle(2, "HealingEngineAutoHot") and MK.RenewingMist:IsReady(unitID) and A_Unit(unitID):HasBuffs(MK.RenewingMist.ID, true) <= A_GetCurrentGCD() + A_GetLatency() and (not inCombat or MK.RenewingMist:PredictHeal(unitID)) and MK.RenewingMist:AbsentImun(unitID) then    
					QueueOrder.useHoTs[Role] = true 
					
					if Role == "HEALER" then
						self:SetupOffsets(db.OffsetHealersHoTs, 45)
					elseif Role == "TANK" then 
						self:SetupOffsets(db.OffsetTanksHoTs, 45)
					else 
						self:SetupOffsets(db.OffsetDamagersHoTs, 45)
					end 								
					return 
				end 
			end						 
		end 
	end 
	--]]
end

-- Setup in UnitIDs table for each unitID his own methods 
do 
	local unitMethods					= { __index = {
		CanSelect						= function(self, unitID)
			-- @return boolean 
			local unitID 				= self.Unit or unitID
			local unitGUID 				= self.GUID
			local ZoneID				= A.ZoneID
			
			return 
				A_Unit(unitID):InRange()
				and A_Unit(unitID):IsConnected()
				and not A_Unit(unitID):IsCharmed()			
				and not A_Unit(unitID):InLOS(unitGUID) 
				and 
				(
					(
						not A.IsInPvP and 
						not A_Unit(unitID):IsEnemy()
					) or 
					(
						A.IsInPvP and 
						A_Unit(unitID):DeBuffCyclone(unitGUID) == 0 and 
						( 
							A_Unit(unitID):HasDeBuffs(Aura.SmokeBomb) == 0 or 
							A_Unit(player):HasDeBuffs(Aura.SmokeBomb) > 0
						)  
					)
				) 
				-- Patch 8.2
				-- 1514 is "The Eternal Palace: Darkest Depths"
				and ( ZoneID ~= 1514 or A_Unit(unitID):HasDeBuffs(Aura.DarkestDepths) == 0 )	
				-- Patch 8.3
				-- 1582 is "Ny'alotha - Ny'alotha" (Ny'alotha, the Waking City)
				and ( ZoneID ~= 1582 or A_Unit(unitID):HasDeBuffs(Aura.CorruptedExistence) == 0 or self.realHP <= 70 )
				-- Patch 9.0
				-- 1735 is "Castle Nathria - The Grand Walk"
				and ( ZoneID ~= 1735 or A_Unit(unitID):HasDeBuffs(Aura.GluttonousMiasma) == 0 )
				-- 9.0 Forgeborne Reveries (Necrolords)
				-- TODO: Add check that player is Necrolod (?)
				and self.isPlayer and A_Unit(unitID):HasBuffs(Aura.ForgeborneReveries) == 0
		end,
		CanRessurect					= function(self)
			local unitID 				= self.Unit 
			return not inCombat and not self.isSelf and self.isPlayer and db.SelectResurrects and not A_Unit(unitID):IsGhost() and not A_Unit(unitID):GetIncomingResurrection() and (BuildToC >= 20000 or A.PlayerClass ~= "DRUID")
		end,
		SetupOffsets 					= function(self, manualOffset, autoOffset)
			if manualOffset == 0 then 
				-- Auto 
				self.HP = math_min(autoOffset or self.HP, self.HP) -- Can not be higher than current modified HP
			else 
				-- Manual 
				if db.OffsetMode == "FIXED" then 
					self.HP = manualOffset
				else -- Mobile
					self.HP = self.HP + manualOffset
				end 
			end 			
		end,
		Setup							= function(self, unitID, unitGUID, isPlayer)
			-- @usage: :Setup(unitID, unitGUID[, isPlayer])
			-- Sets the keys in table: 			
			-- Unit 			= unitID
			-- GUID 			= unitGUID			
			-- HP 				= 0-100									-- Modified Health Percent
			-- AHP 				= 0-huge 								-- Modified Health Actual
			-- MHP				= 0-huge								-- Maximum  Health Actual
			-- Role 			= "TANK", "HEALER", "DAMAGER", "NONE" 	-- Pet has "DAMAGER" role here
			-- LUA 				= @string 
			-- Enabled  		= @boolean								-- For function SetHealingTarget
			-- useDispel		= @boolean 
			-- useShields		= @boolean 
			-- useHoTs			= @boolean 
			-- useUtils			= @boolean 								-- Offensive and supportive spells such as BoP, Freedom and etc 
			-- isPlayer 		= @boolean 
			-- isPet 			= @boolean 
			-- isSelf	 		= @boolean 
			-- isSelectAble		= @boolean 								-- If possible to target that unit 
			-- incDMG 			= 0-huge 
			-- incOffsetDMG 	= 0-huge 
			-- realHP			= 0-100
			-- realAHP			= 0-huge 			
			-- Merge all data from db (Enabled, Role, useDispel, useShields, useHoTs, useUtils, isPet, LUA)
			for k, v in pairs(dbUnitIDs[unitID]) do 
				self[k] = v 
			end 
			
			local isPlayer 				= isPlayer
			if isPlayer == nil then 
				isPlayer				= not self.isPet
			end 						
			
			self.Unit 					= unitID 
			self.GUID 					= unitGUID
			self.isPlayer 				= isPlayer	
			self.isSelf					= TeamCacheFriendlyUNITs.player == unitGUID						
			self.realAHP, self.MHP 		= A_Unit(unitID):Health(), A_Unit(unitID):HealthMax()
			if self.MHP == 0 then 
				self.realHP 			= 0 -- Fix beta / ptr "Division by zero"
			else				
				self.realHP 			= 100 * self.realAHP / self.MHP
			end 
			if self.Role == "AUTO" then 
				if not isPlayer then 
					self.Role = "DAMAGER"
				else
					self.Role = A_Unit(unitID):Role()
				end 
			end 
			
			if (not self.isPet or db.SelectPets) and (not A_Unit(unitID):IsDead() or self:CanRessurect()) and self:CanSelect() then 					
				local incomingHeals		= PredictOptions[1] and A_Unit(unitID):GetIncomingHeals() 	 or 0
				local incomingDMG		= PredictOptions[2] and A_Unit(unitID):GetRealTimeDMG() 	 or 0				
				local absorbPossitive 	= PredictOptions[5] and A_Unit(unitID):GetAbsorb()			 or 0
				local absorbNegative	= PredictOptions[6] and A_Unit(unitID):GetTotalHealAbsorbs() or 0							
				
				-- Prediction 
				self.incDMG				= incomingDMG
				if self.MHP == 0 then 
					self.HP 			= 0 -- Fix beta / ptr "Division by zero"
				else
					self.HP				= 100 * (self.realAHP + incomingHeals + absorbPossitive - absorbNegative) / self.MHP -- HoTs and Inc. Damage must be calculated by PerformByProfileHP or by callback "TMW_ACTION_HEALINGENGINE_UNIT_UPDATE"
				end 

				-- Multiplier - Incoming Damage 					
				self.incOffsetDMG		= self.MHP * db.MultiplierIncomingDamageLimit
				if incomingDMG > self.incOffsetDMG then 
					self.incOffsetDMG	= incomingDMG
				end										
				
				-- Multiplier - Threat 
				if not A.IsInPvP and A_Unit(unitID):ThreatSituation() >= 3 then 
					self.HP				= self.HP * db.MultiplierThreat
				end 
				
				-- Multiplier - Pets 
				if self.isPet then 
					if inCombat then 
						self.HP			= self.HP * db.MultiplierPetsInCombat
					else
						self.HP			= self.HP * db.MultiplierPetsOutCombat
					end 
				end 
				
				-- Offsets 
				if isPlayer then 
					if self.Enabled then 
						-- Performs GGL profiles 
						PerformByProfileHP(self)
					end 
					
					local role = self.Role
					if role == "TANK" then 
						self:SetupOffsets(db.OffsetTanks, self.HP - 2)
					elseif role == "HEALER" then
						if self.isSelf and A.IsInPvP then 
							if (not isClassic and A_Unit(player):IsFocused(nil, true)) or (isClassic and A_Unit(player):IsFocused(0)) then 
								self:SetupOffsets(db.OffsetSelfFocused, math_max(self.HP - 20, self.HP)) -- Can not be lower than current modified HP
							else 
								self:SetupOffsets(db.OffsetSelfUnfocused, self.HP - 2)
							end 
						else 
							self:SetupOffsets(db.OffsetHealers, self.HP + 2)
						end
					else
						self:SetupOffsets(db.OffsetDamagers, self.HP - 1)
					end 
				end

				self.isSelectAble		= true 
			else 				
				self.incDMG, self.incOffsetDMG 	= 0, 0
				self.HP							= self.realHP			
				self.isSelectAble				= false 
			end 											 
			
			TMW:Fire("TMW_ACTION_HEALINGENGINE_UNIT_UPDATE", self, db, QueueOrder)				
			-- Calculate Actual (back from modified HP)
			self.AHP					= self.HP * self.MHP / 100			
		end, 
		HasLua							= function(self)
			-- @return boolean 
			return self.LUA ~= ""
		end,
		RunLua 							= function(self, luaCode)
			-- Note: Shortcut to refference 'self' in LUA window is Action.HealingEngine.Data.UnitIDs[thisunit] which is through setfenv is HealingEngine.Data.UnitIDs[thisunit]
			-- Should return 'true' to make conditions viable, if LUA is OFF (i.e. LUA = "") it always returns 'true'
			-- This is the last condition which will be checked before set healing unit, if need to make something different then use callback system "TMW_ACTION_HEALINGENGINE_UNIT_UPDATE"
			return RunLua(luaCode or self.LUA, self.Unit)
		end,
	} }
	for _, unitTable in pairs(UnitIDs) do 
		setmetatable(unitTable, unitMethods)
	end 
end 

local member, memberGUID, memberData
local playerGUID, petGUID, focusGUID 
local function OnUpdate()   
    -- Wipe previous 
	UnitIDs:Wipe() 
	SortedUnitIDs:Wipe()
	SortedUnitIDs_MostlyIncDMG:Wipe()
	QueueOrder:Wipe()
	playerGUID, petGUID, focusGUID 		= nil, nil, nil
	
	-- Solo
    if not inGroup then 
		-- Player 
		member 							= player  
		memberGUID 						= TeamCacheFriendlyUNITs[member]	
		if memberGUID then 
			playerGUID					= memberGUID -- Save for future referrence
			memberData 					= UnitIDs[member]
			memberData:Setup(member, memberGUID, true)				
			FrequencyTemp.MHP 			= (FrequencyTemp.MHP or 0) + memberData.MHP 
			FrequencyTemp.AHP 			= (FrequencyTemp.AHP or 0) + memberData.realAHP				
			if memberData.isSelectAble then 
				SortedUnitIDs[#SortedUnitIDs + 1] 							= memberData
				SortedUnitIDs_MostlyIncDMG[#SortedUnitIDs_MostlyIncDMG + 1] = memberData
			end 
		end 
		
		-- Pet
		member 							= pet  
		memberGUID 						= TeamCacheFriendlyUNITs[member]	
		if memberGUID then 
			petGUID						= memberGUID -- Save for future referrence
			memberData 					= UnitIDs[member]
			memberData:Setup(member, memberGUID, false)				
			FrequencyTemp.MHP 			= (FrequencyTemp.MHP or 0) + memberData.MHP 
			FrequencyTemp.AHP 			= (FrequencyTemp.AHP or 0) + memberData.realAHP				
			if memberData.isSelectAble then 
				SortedUnitIDs[#SortedUnitIDs + 1] 							= memberData
				SortedUnitIDs_MostlyIncDMG[#SortedUnitIDs_MostlyIncDMG + 1] = memberData
			end 
		end 
    end 
	
	-- Focus 
	if BuildToC >= 20000 then 
		-- Replaces party/raid unit by self
		-- We have to replace member by focus only in case if focus is not member of the group
		-- This need for /focus macros otherwise toggles will not work through specific unit (e.g. raid1, party1) if its equal to focus unit like you can't /focus focus
		member 							= focus
		memberGUID						= UnitGUID(member)		
		if memberGUID and memberGUID ~= playerGUID and memberGUID ~= petGUID and not TeamCacheFriendlyGUIDs[memberGUID] and not A_Unit(focus):IsEnemy() then 
			focusGUID					= memberGUID -- Save for future referrence
			memberData 					= UnitIDs[member]
			memberData:Setup(member, memberGUID, A_Unit(member):IsPlayer() or false)	
			FrequencyTemp.MHP 			= (FrequencyTemp.MHP or 0) + memberData.MHP 
			FrequencyTemp.AHP 			= (FrequencyTemp.AHP or 0) + memberData.realAHP					
			if memberData.isSelectAble then 
				SortedUnitIDs[#SortedUnitIDs + 1] 							= memberData
				SortedUnitIDs_MostlyIncDMG[#SortedUnitIDs_MostlyIncDMG + 1] = memberData
			end 
		end 
	end 
            
	-- Group 
	if inGroup then 
		for i = 1, maxGroupSize do
			-- Players 
			member 						= TeamCacheFriendlyIndexToPLAYERs[i]   -- 5th index is player in party group
			memberGUID 					= member and TeamCacheFriendlyUNITs[member]					
			if memberGUID and memberGUID ~= focusGUID then				
				memberData 				= UnitIDs[member]
				memberData:Setup(member, memberGUID, true)					
				FrequencyTemp.MHP 		= (FrequencyTemp.MHP or 0) + memberData.MHP 
				FrequencyTemp.AHP 		= (FrequencyTemp.AHP or 0) + memberData.realAHP				
				if memberData.isSelectAble then 
					SortedUnitIDs[#SortedUnitIDs + 1] 							= memberData
					SortedUnitIDs_MostlyIncDMG[#SortedUnitIDs_MostlyIncDMG + 1] = memberData
				end 
			end 
			
			-- Pets
			member 						= TeamCacheFriendlyIndexToPETs[i]	-- 5th index is player in party group
			memberGUID 					= member and TeamCacheFriendlyUNITs[member]
			if memberGUID and memberGUID ~= focusGUID then 
				memberData 				= UnitIDs[member]
				memberData:Setup(member, memberGUID, false)					
				FrequencyTemp.MHP 		= (FrequencyTemp.MHP or 0) + memberData.MHP 
				FrequencyTemp.AHP 		= (FrequencyTemp.AHP or 0) + memberData.realAHP
				if memberData.isSelectAble then 
					SortedUnitIDs[#SortedUnitIDs + 1] 							= memberData
					SortedUnitIDs_MostlyIncDMG[#SortedUnitIDs_MostlyIncDMG + 1] = memberData
				end 					
			end 			 
		end 
	end 
    
    -- Frequency
    if inGroup then 
		if FrequencyTemp.MHP and FrequencyTemp.MHP > 0 then 
			FrequencyActual[#FrequencyActual + 1] = { 	                
				-- Max Group HP
				MHP		= FrequencyTemp.MHP, 
				-- Current Group Actual HP
				AHP 	= FrequencyTemp.AHP,
				-- Current Time on this record 
				TIME 	= TMW.time, 
			}
			
			-- Clear temp by current (old now) record
			wipe(FrequencyTemp)
			
			-- Clear actual from older records
			for i = #FrequencyActual, 1, -1 do             
				-- Remove data longer than 10 seconds 
				if TMW.time - FrequencyActual[i].TIME > 10 then 
					tremove(FrequencyActual, i)                
				end 
			end 
		end 
	else
		-- Wipe previous
		if #FrequencyActual > 0 then 
			Frequency:Wipe() 
		end 
    end 
    
	-- Sorting
    if #SortedUnitIDs > 1 then 
        -- Sort by most damage receive
        tsort(SortedUnitIDs_MostlyIncDMG, sort_incDMG)  
        
        -- Sort by Percent or Actual
		if db.SelectSortMethod == "HP" then 
			tsort(SortedUnitIDs, sort_HP)
		else 
			tsort(SortedUnitIDs, sort_AHP)
		end 
    end 
end

local function ClearHealingTarget()
	healingTarget 	  		= none
	healingTargetGUID 		= none		
	frame:SetColor(healingTarget) 
end 

local function SetHealingTarget()
	if IsRetiredProfile() then -- TODO: Remove (old profiles)
		if #SortedUnitIDs > 0 then 
			local Toggle = _G.HE_Toggle or "ALL"
			for _, unitTable in ipairs(SortedUnitIDs) do 
				if unitTable.HP < 100 then 
					if unitTable.Enabled and RetiredToggleHE[Toggle][unitTable.Role] then 
						healingTarget 		= unitTable.Unit
						healingTargetGUID 	= unitTable.GUID
						return 
					end 
				else 
					break 
				end 
			end 
		end 
		
		healingTarget 	  	= none
		healingTargetGUID 	= none
		return 
	end 
	
	if #SortedUnitIDs > 0 then 
		for _, unitTable in ipairs(SortedUnitIDs) do 
			if unitTable.HP < 100 then 
				if unitTable.Enabled and unitTable:RunLua() then 
					healingTarget 		= unitTable.Unit
					healingTargetGUID 	= unitTable.GUID
					return 
				end 
			else 
				break 
			end 
		end 
	end 

    healingTarget 	  		= none
    healingTargetGUID 		= none
end

local function SetColorTarget()
	isFocusHealing = (BuildToC >= 20000 and not SelectStopOptions[1] and not SelectStopOptions[2] and not SelectStopOptions[3] and not SelectStopOptions[4] and not SelectStopOptions[5] and not SelectStopOptions[6])
	-- If we have no one to heal or we have already selected unit that need to heal	
	if 	healingTarget == none or healingTargetGUID == none or 
		-- /target mode
		(not isFocusHealing and healingTargetGUID == UnitGUID(target)) or 
		-- /focus mode
		(isFocusHealing and healingTargetGUID == UnitGUID(focus))
	then			
		return frame:SetColor(none)
	end	
	
	if IsRetiredProfile() then -- TODO: Remove (old profiles)
		if A_Unit(target):IsEnemy() or (_G.MouseOver_Toggle and (A.MouseHasFrame() or A_Unit(mouseover):IsEnemy())) or A_Unit(player):IsDead() then 
			return frame:SetColor(none)
		end 
		
		return frame:SetColor(healingTarget)
	end 
	
	-- [1] @mouseover friendly 
	if SelectStopOptions[1] and A_IsUnitFriendly(mouseover) then
		return frame:SetColor(none)
	end
	
	-- [2] @mouseover enemy
	if SelectStopOptions[2] and A_IsUnitEnemy(mouseover) then 
		return frame:SetColor(none)
	end 
	
	-- [3] @target enemy
	if SelectStopOptions[3] and A_IsUnitEnemy(target) then 
		return frame:SetColor(none)
	end 
	
	-- [4] @target boss
	if SelectStopOptions[4] and A_Unit(target):IsBoss() then
		return frame:SetColor(none)
	end     
	
	-- [5] @player dead 
	if SelectStopOptions[5] and A_Unit(player):IsDead() then
		return frame:SetColor(none)
	end  
	
	-- [6] sync-up "Rotation doesn't work if"
	if SelectStopOptions[6] and A_PauseChecks() then 
		return frame:SetColor(none)
	end 
	
	-- Mistweaver Monk
	--if A.CurrentProfile:match("[GGL] Monk") then 
	--	local HealingEnginePreventSuggestHP = GetToggle(2, "HealingEnginePreventSuggestHP")
	--	if HealingEnginePreventSuggestHP and HealingEnginePreventSuggestHP >= 0 then 		
	--		local MK = A[CONST.MONK_MISTWEAVER]
	--		local unitID, spellName = MK.GetStopCastInfo()
	--		if spellName == MK.SoothingMist:Info() then 
	--			if not unitID then 
	--				unitID = A_IsUnitFriendly(mouseover) and mouseover or A_IsUnitFriendly(target) and target 				
	--			end 
	--			
	--			if unitID and A_Unit(unitID):HasBuffs(MK.SoothingMist.ID, true, true) > 0 and (UnitIsUnit(unitID, healingTarget) or (not UnitIDs[healingTarget].modHP and UnitIDs[healingTarget].realHP - A_Unit(unitID):HealthPercent() < HealingEnginePreventSuggestHP)) then 					
	--				return frame:SetColor(none)
	--			end 		
	--		end 
	--	end 
	--end  
	
	return frame:SetColor(healingTarget)
end

local function UpdateTargetLOS()
	if A_Unit(target):IsExists() and not A_Unit(target):IsEnemy() then
		if A.IsInitialized then
			-- New profiles 
			if not A_IsUnitFriendly(mouseover) then 
				GetLOS(target)
			end 		
		elseif A.IsGGLprofile and (not _G.MouseOver_Toggle or A_Unit(mouseover):IsEnemy() or not A.MouseHasFrame()) then 
			-- TODO: Remove on old profiles until June 2019
			-- Old profiles 
			GetLOS(target)
		end 
	end 
end

local function PLAYER_TARGET_CHANGED()
	SetColorTarget()
	-- [3] @target enemy or [4] @target boss
	if db.AfterTargetEnemyOrBossDelay > 0 and (not SelectStopOptions[3] or not SelectStopOptions[4]) then 
		if ((not SelectStopOptions[3] and A_Unit(target):IsEnemy()) or (not SelectStopOptions[4] and A_Unit(target):IsBoss())) then 
			healingTargetDelay = TMW.time + db.AfterTargetEnemyOrBossDelay		
			healingTargetDelayByEvent = true 
		elseif healingTargetDelayByEvent then 
			healingTargetDelay = 0
			healingTargetDelayByEvent = false 
		end 
	end 
	
	-- Update Line of Sight
	UpdateTargetLOS()
end 

local function UPDATE_MOUSEOVER_UNIT()
	SetColorTarget()
	-- [2] @mouseover enemy 
	if db.AfterMouseoverEnemyDelay > 0 and not SelectStopOptions[2] then 
		if A_Unit(mouseover):IsEnemy() then 
			healingTargetDelay = TMW.time + db.AfterMouseoverEnemyDelay
			healingTargetDelayByEvent = true 
		elseif healingTargetDelayByEvent then 
			healingTargetDelay = 0 
			healingTargetDelayByEvent = false 
		end 
	end 
end 

local function UNIT_TARGET(holderUnitID)
	if db.ManaManagementManaBoss >= 0 and inCombat and A.IsInInstance and not A.IsInPvP and TeamCacheFriendly.MaxSize >= 5 and not IsRetiredProfile() then -- TODO: Remove (old profiles) IsRetiredProfile()
		if A_Unit(holderUnitID):IsBoss() and not A_Unit(holderUnitID):IsDead() then 
			local bossGUID = UnitGUID(holderUnitID)
			if not BossIDs[bossGUID] then 
				BossIDs[bossGUID] = {}
			end 
			BossIDs[bossGUID][holderUnitID] = true 
			BossIDs[holderUnitID] = bossGUID
		else 
			local bossGUID = BossIDs[holderUnitID]
			if bossGUID then 
				BossIDs[bossGUID][holderUnitID] = nil 
				BossIDs[holderUnitID] = nil 
			end 			
		end 
	end 
end 

local function Initialize()	
	if not isClassic and profileActionDB and profileActionDB[A.PlayerSpec] then 
		-- Note: The player may have 2 healer specs like Priest, so we have to keep correct db variable
		db 					= profileActionDB[A.PlayerSpec]
		
		PredictOptions		= db.PredictOptions
		SelectStopOptions 	= db.SelectStopOptions	
		dbUnitIDs			= db.UnitIDs				
	end 

	-- Since release of MetaEngine, all classes and specializations have HealingEngine API
	-- It can be disabled in case of performance issues or when doesn't need
	if GetToggle(8, "HealingEngineAPI") then
		if not Data.IsRunning then 
			if BuildToC >= 20000 then 
				Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_FOCUS_CHANGED", 	SetColorTarget)
			end 
			Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_TARGET_CHANGED", 	PLAYER_TARGET_CHANGED)
			Listener:Add("ACTION_EVENT_HEALINGENGINE", "UPDATE_MOUSEOVER_UNIT", 	UPDATE_MOUSEOVER_UNIT)
			Listener:Add("ACTION_EVENT_HEALINGENGINE", "UNIT_TARGET", 				UNIT_TARGET)
			
			local UPD_INTV
			if not TMW.UPD_INTV then 
				TMW.UPD_INTV = 0.3
			end 
			
			frame.elapsed = 0
			frame:SetScript("OnUpdate", function(self, elapsed)
				UPD_INTV		= TMW.UPD_INTV				
				UPD_INTV 		= UPD_INTV > 0.3 and UPD_INTV or 0.3
				self.elapsed 	= self.elapsed + elapsed  
				
				if self.elapsed > UPD_INTV then 
					OnUpdate() 
					
					if TMW.time > healingTargetDelay then 
						SetHealingTarget() 
						SetColorTarget()   
					end 
					
					-- Update Line of Sight
					if self.unit == none then 
						UpdateTargetLOS()
					end 
					
					self.elapsed = 0
				end			
			end)
			
			Data.IsRunning = true 
		end 
	else
		if Data.IsRunning then
			if BuildToC >= 20000 then 
				Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_FOCUS_CHANGED")
			end 			
			Listener:Remove("ACTION_EVENT_HEALINGENGINE", "PLAYER_TARGET_CHANGED")
			Listener:Remove("ACTION_EVENT_HEALINGENGINE", "UPDATE_MOUSEOVER_UNIT")
			Listener:Remove("ACTION_EVENT_HEALINGENGINE", "UNIT_TARGET")
			
			frame:SetScript("OnUpdate", nil)
			ClearHealingTarget()
			
			UnitIDs:Wipe() 
			SortedUnitIDs:Wipe()
			SortedUnitIDs_MostlyIncDMG:Wipe()
			Frequency:Wipe()
			QueueOrder:Wipe()
			BossIDs:Wipe()
			
			Data.IsRunning = false 
		end
	end 
end 


TMW:RegisterCallback("TMW_ACTION_HEALINGENGINE_INITIALIZE", 					Initialize) 
TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 				Initialize) 
TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", 								Initialize) 
TMW:RegisterCallback("TMW_ACTION_DB_UPDATED",									function(callbackEvent, pActionDB)
	if pActionDB and pActionDB[8] then 
		if not isClassic then 
			db = pActionDB[8][A.PlayerSpec]
			profileActionDB = pActionDB[8] -- need for update specialization table when its change by "TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED"
			
			if not db then 
				db = StdUi.Factory[8].PLAYERSPEC
				profileActionDB = nil 
			else 
				TMW:Fire("TMW_ACTION_PROFILE_DB_UPDATED")	
			end 
		else 
			db = pActionDB[8]
			if not db then 
				db = StdUi.Factory[8]
			else 
				TMW:Fire("TMW_ACTION_PROFILE_DB_UPDATED")	
			end 
		end 
	else 
		if not isClassic then 
			db = StdUi.Factory[8].PLAYERSPEC
			profileActionDB = nil 
		else 
			db = StdUi.Factory[8]
		end 
	end 
	
	PredictOptions		= db.PredictOptions
	SelectStopOptions 	= db.SelectStopOptions	
	dbUnitIDs			= db.UnitIDs		
	
	if db.ManaManagementManaBoss < 0 then 
		BossIDs:Wipe()
	end 
	
end)
TMW:RegisterCallback("TMW_ACTION_GROUP_UPDATE",									function()
	inGroup 	 = TeamCacheFriendly.Type
	maxGroupSize = TeamCacheFriendly.MaxSize
	if Data.IsRunning then 
		BossIDs:Wipe()
	end 
end)
TMW:RegisterCallback("TMW_ACTION_METAENGINE_AUTH",								function()
	-- This callback resets frame allowing initial unit to be set correctly
	frame.unit, frame.mode = nil, nil
end)
Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_ENABLED", 				function()
	inCombat = false 
	if Data.IsRunning then 
		wipe(Frequency.Actual)
		BossIDs:Wipe()
	end 
end)
Listener:Add("ACTION_EVENT_HEALINGENGINE", "PLAYER_REGEN_DISABLED", 			function()
	inCombat = true 
	if Data.IsRunning then 
		wipe(Frequency.Actual)
		BossIDs:Wipe()
	end 
end)

-- ============================= API ==============================

-- Globals
A.HealingEngine = { Data = Data }

-- Locals
local HealingEngine = A.HealingEngine

-- Data Controller 
function HealingEngine.SortMembers()
	-- Manual re-sort table 
	if #SortedUnitIDs > 1 then
		-- Sort by most damage receive
        tsort(SortedUnitIDs_MostlyIncDMG, sort_incDMG)  
		
		-- Sort by Percent or Actual
		if db.SelectSortMethod == "HP" then 
			tsort(SortedUnitIDs, sort_HP)
		else 
			tsort(SortedUnitIDs, sort_AHP)
		end 
	end 
end 

-- SetTarget Controller 
function HealingEngine.SetTargetMostlyIncDMG(delay)
	-- Sets in HealingEngine specified unitID with delay which will prevent reset target during next few seconds 	
	if #SortedUnitIDs_MostlyIncDMG > 0 then 
		local wasSet = SortedUnitIDs_MostlyIncDMG[1].Unit == healingTarget
		healingTargetDelay 	= TMW.time + (delay or 0.5)
		healingTargetGUID 	= SortedUnitIDs_MostlyIncDMG[1].GUID
		healingTarget		= SortedUnitIDs_MostlyIncDMG[1].Unit
		if healingTarget and not wasSet then 
			frame:SetColor(healingTarget) 
		end
	end 
end 

function HealingEngine.SetTarget(unitID, delay)
	-- Sets in HealingEngine specified unitID with delay which will prevent reset target during next few seconds 	
	local wasSet = unitID == healingTarget
	healingTargetGUID 		= TeamCacheFriendlyUNITs[unitID] or UnitGUID(unitID)
	healingTarget			= TeamCacheFriendlyGUIDs[healingTargetGUID]
	if healingTarget and not wasSet then 
		healingTargetDelay 	= TMW.time + (delay or 0.5)
		frame:SetColor(healingTarget)		 
	end 
end

-- Group Controller 
function HealingEngine.GetMembersAll()
	-- @return array table of all select able units 
	return SortedUnitIDs 
end 

function HealingEngine.GetMembersByMode(MODE) -- TODO: Remove (old profiles)
	-- @return table 
	local MODE = MODE or (IsRetiredProfile() and _G.HE_Toggle) or "ALL"
	if not Data[MODE] then 
		Data[MODE] = {}
	else
		wipe(Data[MODE])
	end 
	
	for _, unitTable in ipairs(SortedUnitIDs) do 
		if unitTable.Enabled and RetiredToggleHE[MODE][unitTable.Role] then 
			Data[MODE][#Data[MODE] + 1] = unitTable
		end 
	end 	
	
	return Data[MODE]
end 

function HealingEngine.GetBuffsCount(ID, duration, source, byID)
	-- @usage HealingEngine.GetBuffsCount(ID[, duration, source, byID])
	-- @return number 	
	-- Note: Only players 
    local total = 0
	for _, thisUnit in ipairs(SortedUnitIDs) do
		if thisUnit.isPlayer and A_Unit(thisUnit.Unit):HasBuffs(ID, source, byID) > (duration or 0) then
			total = total + 1
		end
	end
	
    return total 
end 

function HealingEngine.GetDeBuffsCount(ID, duration, source, byID)
	-- @usage HealingEngine.GetDeBuffsCount(ID[, duration, source, byID])
	-- @return number 	
	-- Note: Only players 
    local total = 0
	for _, thisUnit in ipairs(SortedUnitIDs) do
		if thisUnit.isPlayer and A_Unit(thisUnit.Unit):HasDeBuffs(ID, source, byID) > (duration or 0) then
			total = total + 1
		end
	end

    return total 
end 

function HealingEngine.GetHealth()
	-- @return number, number 
	-- Returns:
	-- [1] current (per group) health 
	-- [2] maximum (per group) health
	local m = #FrequencyActual
	if m > 0 then 
		return FrequencyActual[m].AHP, FrequencyActual[m].MHP
	end 
	return huge, huge
end 

function HealingEngine.GetHealthAVG() 
	-- @return number 
	-- Returns:
	-- [1] current (per group) health percent (%)
	local m = #FrequencyActual
	if m > 0 then 
		return FrequencyActual[m].AHP * 100 / FrequencyActual[m].MHP
	end 
	return 100  
end 

function HealingEngine.GetHealthFrequency(timer)
	-- @return number 
	-- Returns:
	-- [1] current (per group) health percent (%) changed during lasts 'timer'
	-- Note: Positive (+) is HP gain. Negative (-) is HP lose. Zero (0) is not changed
    local total, counter = 0, 0
	
	if timer > 10 then 
		error("HealingEngine.GetHealthFrequency function accepts maximum 10 as 'timer' argument")
	end 
	
	local m = #FrequencyActual
	if m > 1 and TMW.time - FrequencyActual[1].TIME >= timer then 
		for i = m - 1, 1, -1 do 
			-- Getting history during that time rate
			if TMW.time - FrequencyActual[i].TIME <= timer then 
				counter = counter + 1
				total 	= total + FrequencyActual[i].AHP
			else 
				break 
			end 
		end        
	end 
	
	if total > 0 then   
		total = (FrequencyActual[m].AHP * 100 / FrequencyActual[m].MHP) - (total / counter * 100 / FrequencyActual[m].MHP)
	end  	
	
    return total 
end 
HealingEngine.GetHealthFrequency = MakeFunctionCachedDynamic(HealingEngine.GetHealthFrequency)

function HealingEngine.GetIncomingDMG()
	-- @return number, number 
	-- Returns:
	-- [1] current (per group) health lose per second
	-- [2] average (per unit)  health lose per second 
	local total, avg = 0, 0
 
	for _, thisUnit in ipairs(SortedUnitIDs) do
		total = total + thisUnit.incDMG
	end
	
	if total > 0 then 
		avg = total / #SortedUnitIDs
    end 
	
    return total, avg 
end 
HealingEngine.GetIncomingDMG = MakeFunctionCachedStatic(HealingEngine.GetIncomingDMG)

function HealingEngine.GetIncomingHPS()
	-- @return number, number
	-- Returns: 
	-- [1] current (per group) health gain per second
	-- [2] average (per unit)  health gain per second 
	local total, avg = 0, 0

    for _, thisUnit in ipairs(SortedUnitIDs) do
		total = total + A_Unit(thisUnit.Unit):GetHEAL()
	end
		
	if total > 0 then 
		avg = total / #SortedUnitIDs
    end 
	
    return total, avg 
end 
HealingEngine.GetIncomingHPS = MakeFunctionCachedStatic(HealingEngine.GetIncomingHPS)

function HealingEngine.GetIncomingDMGAVG()
	-- @return number  
	-- Returns:	
	-- [1] current (per group) health percent (%) lose per second	
	local m = #FrequencyActual
    if m > 0 then 
		return HealingEngine.GetIncomingDMG() * 100 / FrequencyActual[m].MHP
    end 
    return 0 
end

function HealingEngine.GetIncomingHPSAVG()
	-- @return number  
	-- Returns:	
	-- [1] current (per group) health percent (%) gain per second	
	local m = #FrequencyActual
    if m > 0 then 
		return HealingEngine.GetIncomingHPS() * 100 / FrequencyActual[m].MHP
    end 
    return 0 
end 

function HealingEngine.GetTimeToFullDie()
	-- @return number 
	-- Returns:	
	-- [1] current time to die for all group members 
	local total = 0
	
	for _, thisUnit in ipairs(SortedUnitIDs) do
		total = total + A_Unit(thisUnit.Unit):TimeToDie()
	end
	
	if total > 0 then 
		return total / #SortedUnitIDs
	end 

	return huge  
end 

function HealingEngine.GetTimeToDieUnits(timer)
	-- @return number 
	-- Returns:	
	-- [1] count of units which are below or equal by TimeToDie to 'timer'
	local total = 0
	
	for _, thisUnit in ipairs(SortedUnitIDs) do
		if A_Unit(thisUnit.Unit):TimeToDie() <= timer then
			total = total + 1
		end
	end 
	
    return total 
end 

function HealingEngine.GetTimeToDieMagicUnits(timer)
	-- @return number 
	-- Returns:	
	-- [1] count of units which are below or equal by TimeToDieMagic to 'timer'	
	local total = 0

	for _, thisUnit in ipairs(SortedUnitIDs) do
		if A_Unit(thisUnit.Unit):TimeToDieMagic() <= timer then
			total = total + 1
		end
	end 
	
    return total 
end 

function HealingEngine.GetTimeToFullHealth()
	-- @return number
	-- Returns:	
	-- [1] current (per group) time to have maximum health 
	local m = #FrequencyActual
	if m > 0 then 
		local HPS = HealingEngine.GetIncomingHPS()
		if HPS > 0 then
			return (FrequencyActual[m].MHP - FrequencyActual[m].AHP) / HPS
		end 
	end 

	return 0 
end 

function HealingEngine.GetMinimumUnits(fullPartyMinus, raidLimit)
	-- @usage HealingEngine.GetMinimumUnits([, fullPartyMinus, raidLimit])
	-- @return number 
	-- This is easy template to known how many people minimum required to be healed by AoE with different group size or if some units out of range or in cyclone and etc..
	-- More easy to figure - which minimum units require if available group members <= 1 / <= 3 / <= 5 or > 5
	local members = #SortedUnitIDs
	return 	( members <= 1 and 1 ) or 
			( members <= 3 and members - math_min(fullPartyMinus or 0, 1)) or 
			( members <= 5 and members - (fullPartyMinus or 0) ) or 
			(
				members > 5 and 
				(
					(
						raidLimit ~= nil and
						(
							(
								members >= raidLimit and 
								raidLimit
							) or 
							(
								members < raidLimit and 
								members
							)
						)
					) or 
					(
						raidLimit == nil and 
						members
					)
				)
			)
end 

function HealingEngine.GetBelowHealthPercentUnits(hp, range)
	-- @usage HealingEngine.GetBelowHealthPercentUnits(hp[, range])
	-- @return number 
	-- Returns:	
	-- [1] count of units which are below or equal to health percent by 'hp' 
	local total = 0 

	for _, thisUnit in ipairs(SortedUnitIDs) do
		if (not range or A_Unit(thisUnit.Unit):CanInterract(range)) and thisUnit.realHP <= hp then
			total = total + 1
		end
	end 
	
	return total 
end; HealingEngine.GetBelowHealthPercentercentUnits = HealingEngine.GetBelowHealthPercentUnits -- Just for refference if old codes still uses it somewhere

function HealingEngine.HealingByRange(range, predictName, spell, isMelee)
	-- @usage HealingEngine.HealingByRange(range, predictName, spell[, isMelee])
	-- @return number 
	-- Returns:	
	-- [1] count of units which can be healed by 'range' and 'predictName'
	-- WARNING: predictName is retired! DO NOT USE IT on new profiles! TODO: Remove 
	local total = 0

	for _, thisUnit in ipairs(SortedUnitIDs) do 
		if (not isMelee or A_Unit(thisUnit.Unit):IsMelee()) and A_Unit(thisUnit.Unit):CanInterract(range) and
			(
				-- Old profiles 
				-- TODO: Remove after rewrite old profiles 
				(not A.IsInitialized and Env.PredictHeal(predictName, thisUnit.Unit)) or 
				-- Old Action profiles 
				(A.IsInitialized and predictName and spell:PredictHeal(predictName, thisUnit.Unit)) or 
				-- New profiles 
				(A.IsInitialized and not predictName and spell:PredictHeal(thisUnit.Unit))  
			)
		then
			total = total + 1
		end
	end 		

	return total 
end 

function HealingEngine.HealingBySpell(predictName, spell, isMelee)
	-- @usage HealingEngine.HealingByRange(predictName, spell[, isMelee])
	-- @return number 
	-- Returns:	
	-- [1] count of units which can be healed by 'spell'
	-- Returns how much members can be healed by specified spell 
	-- WARNING: predictName is retired! DO NOT USE IT on new profiles! TODO: Remove 
	local total = 0
	
	for _, thisUnit in ipairs(SortedUnitIDs) do 
		if (not isMelee or A_Unit(thisUnit.Unit):IsMelee()) and 
			(
				(not A.IsInitialized and Env.SpellInRange(thisUnit.Unit, spell)) or
				(A.IsInitialized and spell:IsInRange(thisUnit.Unit))
			) and 
			(
				-- Old profiles 
				-- TODO: Remove after rewrite old profiles 
				(not A.IsInitialized and Env.PredictHeal(predictName, thisUnit.Unit)) or 
				-- Old Action profiles 
				(A.IsInitialized and predictName and spell:PredictHeal(predictName, thisUnit.Unit)) or 
				-- New profiles 
				(A.IsInitialized and spell:PredictHeal(thisUnit.Unit))
			)
		then
			total = total + 1
		end
	end 		

	return total 
end 

function HealingEngine.HealingBySpiritofPreservation(obj, stop, skipShouldStop)
	-- @usage HealingEngine.HealingBySpiritofPreservation(obj[, stop, skipShouldStop])
	-- @return number 
	-- Returns:	
	-- [1] count of units which can be healed by SpiritofPreservation essence 
	local total 	= 0
	local isTable 	= type(obj) == "table"
	
	for _, thisUnit in ipairs(SortedUnitIDs) do 
		if isTable then 
			if obj:IsReady(thisUnit.Unit, true, nil, skipShouldStop) and Azerite:EssencePredictHealing("Spirit of Preservation", obj.ID, thisUnit.Unit) then
				total = total + 1
			end
		else
			if Env.SpellInRange(thisUnit.Unit, obj) and Azerite:EssencePredictHealing("Spirit of Preservation", obj, thisUnit.Unit) then
				total = total + 1
			end
		end 
		
		if stop and total >= stop then 
			break 
		end 
	end 		

	return total 	
end 

-- Unit Controller 
local emptyTable = {}
function HealingEngine.GetOptionsByUnitID(unitID, unitGUID)
	-- @usage local useDispel, useShields, useHoTs, useUtils, dbUnit = HealingEngine.GetOptionsByUnitID(unitID[, unitGUID])
	-- @return boolean, boolean, boolean, boolean, table
	-- Returns data from DB (not modified data by Healing Engine!):
	-- [1] useDispel
	-- [2] useShields
	-- [3] useHoTs
	-- [4] useUtils
	-- [5] @table itself table with keys: table.Enabled, table.Role, table.useDispel, table.useShields, table.useHoTs, table.useUtils, table.LUA
	-- Note: Don't change key-values in returned [5] table, only for referrence usage!
	local GUID = unitGUID or UnitGUID(unitID)
	if GUID then 
		if GUID == focusGUID and BuildToC >= 20000 then 
			local dbUnit = dbUnitIDs.focus
			if dbUnit then 
				return dbUnit.useDispel, dbUnit.useShields, dbUnit.useHoTs, dbUnit.useUtils, dbUnit
			end 
		else 
			local unit = TeamCacheFriendlyGUIDs[GUID]
			local dbUnit = unit and dbUnitIDs[unit]
			if dbUnit then 
				return dbUnit.useDispel, dbUnit.useShields, dbUnit.useHoTs, dbUnit.useUtils, dbUnit
			end 
		end 
	end 
	
	-- Default return for non in group units 
	local isPlayer = A_Unit(unitID):IsPlayer()
	return isPlayer, true, true, isPlayer, emptyTable, emptyTable
end 

function HealingEngine.IsMostlyIncDMG(unitID)
	-- @return boolean, number 
	-- Returns:
	-- [1] true, if unitID is the same unit which is most injured 
	-- [2] current incoming damage per second 
	if SortedUnitIDs_MostlyIncDMG[1] and UnitIsUnit(unitID, SortedUnitIDs_MostlyIncDMG[1].Unit) then 
		return true, SortedUnitIDs_MostlyIncDMG[1].incDMG
	end 
	return false, 0
end 

function HealingEngine.GetTarget()
	return healingTarget, healingTargetGUID
end 

-- Boss Controller 
function HealingEngine.GetBossHealth()
	-- @return number, number, number, number, number 
	-- Returns:
	-- [1] Average health current 
	-- [2] Average health maximum
	-- [3] Total health current
	-- [4] Total health maximum
	-- [5] Count of bosses 
	local healthCurrent, healthMax, c = 0, 0, 0
	local bossHealth = 0
	for bossGUID, bossHolders in pairs(BossIDs) do 
		if type(bossHolders) == "table" then 
			for bossUnitID in pairs(bossHolders) do 
				bossHealth = A_Unit(bossUnitID):Health()
				if bossHealth > 0 then 
					healthCurrent = healthCurrent + bossHealth
					healthMax = healthMax + A_Unit(bossUnitID):HealthMax()
					c = c + 1
					break 
				end 
			end 
		end 
	end 
	
	if c <= 0 then 
		return 0, 0, 0, 0, 0
	end 
	
	return healthCurrent / c, healthMax / c, healthCurrent, healthMax, c
end 

function HealingEngine.GetBossHealthPercent()
	-- @return number 
	-- Returns current average health percent (of all bosses)
	local curHealth, maxHealth = HealingEngine.GetBossHealth()
	if curHealth <= 0 then 
		return 0
	end 
	
	return curHealth * 100 / maxHealth
end 

function HealingEngine.GetBossTimeToDie()
	-- @return number, number, number, number, number 
	-- Returns:
	-- [1] Average ttd current 
	-- [2] Total ttd current
	-- [3] Count of bosses 
	local curTTD, c = 0, 0
	local ttd = 0
	for bossGUID, bossHolders in pairs(BossIDs) do 
		if type(bossHolders) == "table" then 
			for bossUnitID in pairs(bossHolders) do 
				ttd = A_Unit(bossUnitID):TimeToDie()
				if ttd > 0 then 
					curTTD = curTTD + ttd
					c = c + 1
					break 
				end 
			end 
		end 
	end 
	
	if c <= 0 then 
		return 0, 0, 0
	end 
	
	return curTTD / c, curTTD, c
end 

function HealingEngine.GetBossMain()
	-- @return unitID, unitGUID, unitFocused or nil 
	-- Returns:
	-- [1] unitID
	-- [2] unitGUID
	-- [3] unitFocused how much members focusing that boss 
	local unitID, unitGUID, unitFocused
	local lastUnit 
	local c = 0
	for bossGUID, bossHolders in pairs(BossIDs) do 
		if type(bossHolders) == "table" then 
			c = 0			
			for bossUnitID in pairs(bossHolders) do 
				c = c + 1
				lastUnit = bossUnitID
			end 
			
			if c > (unitFocused or 0) then 
				unitID = lastUnit
				unitGUID = bossGUID
				unitFocused = c 
			end 
		end 
	end 
	
	return unitID, unitGUID, unitFocused
end 

-- Mana Controller 
function HealingEngine.IsManaSave(unitID)
	-- @return boolean 
	-- Returns true if conditions are successful for mana save  
	if db.ManaManagementManaBoss >= 0 then 
		local bossHP = HealingEngine.GetBossHealthPercent() 
		local manaP  = A_Unit(player):PowerPercent()
		if bossHP > 0 and manaP <= bossHP and manaP <= db.ManaManagementManaBoss and A_Unit(player):HasBuffs(Aura.Innervate) == 0 then 
			-- Check stop conditions 
			return not unitID or (A_Unit(unitID):HealthPercent() >= db.ManaManagementStopAtHP and A_Unit(unitID):TimeToDie() >= db.ManaManagementStopAtTTD)
		end 
	end 
end 
HealingEngine.IsManaSave = MakeFunctionCachedDynamic(HealingEngine.IsManaSave)