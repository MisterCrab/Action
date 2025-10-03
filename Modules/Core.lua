local _G, math, pairs, type, select, setmetatable	= _G, math, pairs, type, select, setmetatable
local huge 											= math.huge

local TMW 											= _G.TMW 
local CNDT 											= TMW.CNDT
local Env 											= CNDT.Env

local A   											= _G.Action
local CONST 										= A.Const
local A_Hide 										= A.Hide
local Create 										= A.Create
local GetToggle										= A.GetToggle
local DetermineUsableObject							= A.DetermineUsableObject
local AuraIsValidByPhialofSerenity					= A.AuraIsValidByPhialofSerenity
local IsExplosivesExists							= A.IsExplosivesExists
local IsCondemnedDemonsExists						= A.IsCondemnedDemonsExists
local IsVoidTendrilsExists							= A.IsVoidTendrilsExists
local IsQueueReady									= A.IsQueueReady
local QueueData										= A.Data.Q
local ShouldStop									= A.ShouldStop
local GetCurrentGCD									= A.GetCurrentGCD
local GetPing										= A.GetPing
local BuildToC										= A.BuildToC

local Re 											= A.Re
local BossMods										= A.BossMods
local InstanceInfo									= A.InstanceInfo
local IsUnitEnemy									= A.IsUnitEnemy
local UnitCooldown									= A.UnitCooldown
local Unit											= A.Unit 
local Player										= A.Player 
local LoC 											= A.LossOfControl
local MultiUnits									= A.MultiUnits

local LoC_GetExtra									= LoC.GetExtra
local CONST_PAUSECHECKS_DISABLED 					= CONST.PAUSECHECKS_DISABLED
local CONST_PAUSECHECKS_DEAD_OR_GHOST				= CONST.PAUSECHECKS_DEAD_OR_GHOST
local CONST_PAUSECHECKS_IS_MOUNTED 					= CONST.PAUSECHECKS_IS_MOUNTED
local CONST_PAUSECHECKS_WAITING 					= CONST.PAUSECHECKS_WAITING
local CONST_PAUSECHECKS_SPELL_IS_TARGETING			= CONST.PAUSECHECKS_SPELL_IS_TARGETING
local CONST_PAUSECHECKS_LOOTFRAME 					= CONST.PAUSECHECKS_LOOTFRAME
local CONST_PAUSECHECKS_IS_EAT_OR_DRINK 			= CONST.PAUSECHECKS_IS_EAT_OR_DRINK
local CONST_AUTOTARGET 								= CONST.AUTOTARGET
local CONST_AUTOATTACK 								= CONST.AUTOATTACK
local CONST_STOPCAST 								= CONST.STOPCAST
local CONST_LEFT 									= CONST.LEFT
local CONST_RIGHT									= CONST.RIGHT
local CONST_SPELLID_COUNTER_SHOT					= CONST.SPELLID_COUNTER_SHOT

local UnitAura										= _G.C_UnitAuras.GetAuraDataByIndex
local UnitIsUnit  									= _G.UnitIsUnit
local UnitIsFriend									= _G.UnitIsFriend

local GetSpellName 									= _G.C_Spell and _G.C_Spell.GetSpellName or _G.GetSpellInfo
local GetCurrentKeyBoardFocus						= _G.GetCurrentKeyBoardFocus
local SpellIsTargeting								= _G.SpellIsTargeting
local IsMouseButtonDown								= _G.IsMouseButtonDown
local HasWandEquipped								= _G.HasWandEquipped
local HasFullControl								= _G.HasFullControl

local BINDPAD 										= _G.BindPadFrame

local ClassPortaits 								= {
	["WARRIOR"] 									= CONST.PORTRAIT_WARRIOR,
	["PALADIN"] 									= CONST.PORTRAIT_PALADIN,
	["HUNTER"] 										= CONST.PORTRAIT_HUNTER,
	["ROGUE"] 										= CONST.PORTRAIT_ROGUE,
	["PRIEST"] 										= CONST.PORTRAIT_PRIEST,
	["DEATHKNIGHT"] 								= CONST.PORTRAIT_DEATHKNIGHT, 	-- Custom because it making conflict with Obliteration
	["SHAMAN"]	 									= CONST.PORTRAIT_SHAMAN, 			-- Custom because it making conflict with Bloodlust
	["MAGE"] 										= CONST.PORTRAIT_MAGE,
	["WARLOCK"] 									= CONST.PORTRAIT_WARLOCK,
	["MONK"] 										= CONST.PORTRAIT_MONK,
	["DRUID"] 										= CONST.PORTRAIT_DRUID,
	["DEMONHUNTER"] 								= CONST.PORTRAIT_DEMONHUNTER,
	["EVOKER"] 										= CONST.PORTRAIT_EVOKER,
}

local GetKeyByRace 									= {
	-- I use this to check if we have created for spec needed spell 
	Worgen 											= "Darkflight",
	VoidElf 										= "SpatialRift",
	NightElf 										= "Shadowmeld",
	LightforgedDraenei 								= "LightsJudgment",
	KulTiran 										= "Haymaker",
	Human 											= "EveryManforHimself",
	Gnome 											= "EscapeArtist",
	Dwarf 											= "Stoneform",
	Draenei 										= "GiftoftheNaaru",
	DarkIronDwarf 									= "Fireblood",
	Pandaren 										= "QuakingPalm",
	ZandalariTroll 									= "Regeneratin",
	Scourge 										= "WilloftheForsaken",
	Troll 											= "Berserking",
	Tauren 											= "WarStomp",
	Orc 											= "BloodFury",
	Nightborne 										= "ArcanePulse",
	MagharOrc 										= "AncestralCall",
	HighmountainTauren 								= "BullRush",
	BloodElf 										= "ArcaneTorrent",
	Goblin 											= "RocketJump",
}

local playerClass									= A.PlayerClass
local player										= "player"
local target 										= "target"
local mouseover										= "mouseover"
local targettarget									= "targettarget"

-------------------------------------------------------------------------------
-- Conditions
-------------------------------------------------------------------------------
local FoodAndDrink 									= {
	[GetSpellName(167152)] 							= true, -- Refreshment (Mage's eat) note: can glitch under same name with some other buffs so added check in-combat will avoid it
	[GetSpellName(43180)] 							= true, -- Food
	[GetSpellName(27089)] 							= true, -- Drink
	[GetSpellName(257427)] 							= true, -- Food & Drink
	[GetSpellName(462177)] 							= true, -- Food and Drink
}
local FoodAndDrinkBlacklist 						= {
	[GetSpellName(396092) or ""]					= true, -- Well Fed
}
local function IsDrinkingOrEating()
	-- @return boolean 
	local auraData
	for i = 1, huge do 
		auraData = UnitAura(player, i, "HELPFUL")
		if not auraData then 
			break 
		elseif FoodAndDrink[auraData.name] and not FoodAndDrinkBlacklist[auraData.name] and (i > 1 or Unit("player"):CombatTime() == 0) then 
			return true 
		end 
	end 
end 

local function PauseChecks()  	
	if not TMW.Locked or GetCurrentKeyBoardFocus() ~= nil or (BINDPAD and BINDPAD:IsVisible()) then 
		return CONST_PAUSECHECKS_DISABLED
	end 
		
    if GetToggle(1, "CheckVehicle") and Unit(player):InVehicle() then
        return CONST_PAUSECHECKS_DISABLED
    end	
	
	if 	(GetToggle(1, "CheckDeadOrGhost") and Unit(player):IsDead()) or 
		(
			GetToggle(1, "CheckDeadOrGhostTarget") and 
			(
				(Unit(target):IsDead() and not UnitIsFriend(player, target) and (not A.IsInPvP or Unit(target):Class() ~= "HUNTER")) or 
				(GetToggle(2, mouseover) and Unit(mouseover):IsDead() and not UnitIsFriend(player, mouseover) and (not A.IsInPvP or Unit(mouseover):Class() ~= "HUNTER"))
			)
		) 
	then 																																																									-- exception in PvP Hunter 
		return CONST_PAUSECHECKS_DEAD_OR_GHOST
	end 		
	
	if GetToggle(1, "CheckMount") and Player:IsMounted() then 																																												-- exception Divine Steed and combat mounted auras
		return CONST_PAUSECHECKS_IS_MOUNTED
	end 

	if GetToggle(1, "CheckCombat") and Unit(player):CombatTime() == 0 and Unit(target):CombatTime() == 0 and not Player:IsStealthed() and BossMods:GetPullTimer() == 0 then 																-- exception Stealthed and DBM pulling event 
		return CONST_PAUSECHECKS_WAITING
	end 	
	
	if GetToggle(1, "CheckSpellIsTargeting") and SpellIsTargeting() then
		return CONST_PAUSECHECKS_SPELL_IS_TARGETING
	end	
	
	if GetToggle(1, "CheckLootFrame") and _G.LootFrame:IsShown() then
		return CONST_PAUSECHECKS_LOOTFRAME
	end	
	
	if GetToggle(1, "CheckEatingOrDrinking") and Player:IsStaying() and Unit(player):CombatTime() == 0 and IsDrinkingOrEating() then
		return CONST_PAUSECHECKS_IS_EAT_OR_DRINK
	end	
end
PauseChecks 				= A.MakeFunctionCachedStatic(PauseChecks)
A.PauseChecks 				= PauseChecks

local GetMetaType = setmetatable({}, { __index = function(t, v)
	local istype = type(v)
	t[v] = istype	
	return istype
end })

local TotalAndKickImun		= {"TotalImun", "KickImun"}
local Medallion 			= LoC_GetExtra["GladiatorMedallion"] -- BFA, Legion, WoD

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
A.AntiFakeWhite					 				= Create({ Type = "SpellSingleColor", 	ID = 1,		Color = "WHITE",     															  Hidden = true         		   												})
A.Trinket1 										= Create({ Type = "TrinketBySlot", 		ID = CONST.INVSLOT_TRINKET1,	 				BlockForbidden = true, Desc = "Upper Trinket (/use 13)" 																	})
A.Trinket2 										= Create({ Type = "TrinketBySlot", 		ID = CONST.INVSLOT_TRINKET2, 					BlockForbidden = true, Desc = "Lower Trinket (/use 14)"																		})
A.Shoot											= Create({ Type = "Spell", 				ID = 5019, 										QueueForbidden = true, BlockForbidden = true, Hidden = true,  Desc = "Wand" 												})
A.AutoShot										= Create({ Type = "Spell", 				ID = 75, 										QueueForbidden = true, BlockForbidden = true, Hidden = true,  Desc = "Hunter's shoot" 										})
A.HS											= Create({ Type = "Item", 				ID = 5512, 										QueueForbidden = true, Desc = "[6] HealthStone", 					skipRange = true										})
A.AbyssalHealingPotion							= Create({ Type = "Item", 				ID = 169451, 									QueueForbidden = true, Desc = "[6] HealingPotion", 					skipRange = true										})
if BuildToC < 90000 then 
	A.GladiatorMedallion						= Create({ Type = "Spell", 				ID = CONST.SPELLID_GLADIATORS_MEDALLION, 		QueueForbidden = true, Desc = "[5] Trinket", BlockForbidden = true, skipRange = true, isTalent = true 						})
	A.HonorMedallion							= Create({ Type = "Spell", 				ID = CONST.SPELLID_HONOR_MEDALLION, 			QueueForbidden = true, Desc = "[5] Trinket", BlockForbidden = true, skipRange = true, isReplacement = true					})
else 	
	-- SL
	if BuildToC >= 90000 then 
		A.PhialofSerenity						= Create({ Type = "Item",  				ID = 177278,									QueueForbidden = true, Desc = "[6] HealingPotion|Dispel",			skipRange = true										})
		A.SpiritualHealingPotion				= Create({ Type = "Item",  				ID = 171267,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						})
	end 
	
	-- DF
	if BuildToC >= 100000 then 
		A.RefreshingHealingPotion1				= Create({ Type = "Item",  				ID = 191378,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						})
		A.RefreshingHealingPotion2				= Create({ Type = "Item",  				ID = 191379,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						})
		A.RefreshingHealingPotion3				= Create({ Type = "Item",  				ID = 191380,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						})
	end 
	
	-- TWW 
	if BuildToC >= 110000 then 
		A.DemonicHS								= Create({ Type = "Item", 				ID = 224464,									QueueForbidden = true, Desc = "[6] HealthStone", 					skipRange = true										}) -- Demonic Healthstone
		A.AlgariHealingPotion1					= Create({ Type = "Item",  				ID = 211878,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						}) -- Algari Healing Potion
		A.AlgariHealingPotion2					= Create({ Type = "Item",  				ID = 212942,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						}) -- Fleeting Algari Healing Potion
		A.AlgariHealingPotion3					= Create({ Type = "Item",  				ID = 211879,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						}) -- Algari Healing Potion
		A.AlgariHealingPotion4					= Create({ Type = "Item",  				ID = 212943,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						}) -- Fleeting Algari Healing Potion
		A.AlgariHealingPotion5					= Create({ Type = "Item",  				ID = 212944,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						}) -- Fleeting Algari Healing Potion
		A.AlgariHealingPotion6					= Create({ Type = "Item",  				ID = 211880,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						}) -- Algari Healing Potion
		A.AlgariHealingPotion7					= Create({ Type = "Item",  				ID = 212318,									QueueForbidden = true, Desc = "[6] HealingPotion",					skipRange = true, Texture = 169451						}) -- QA Algari Healing Potion
	end 
	
	-- TWW 11.1.7: AssistedCombat
	if BuildToC >= 110107 then
		local ID 								= _G.C_AssistedCombat and _G.C_AssistedCombat.GetActionSpell and _G.C_AssistedCombat.GetActionSpell() or 1229376
		A.SBA									= Create({ Type = "Spell",  			ID = ID, 										Macro = "/cast spell:thisID", Desc = "Single-Button Assistant", 	skipRange = true, FixedTexture = 6718291				})
	end
	
	-- TWW 11.2
	if BuildToC >= 110200 then 
		A.InvigoratingHealingPotion1 			= Create({ Type = "Item", 				ID = 244835, 									QueueForbidden = true, Desc = "[6] HealingPotion", 					skipRange = true, Texture = 169451						}) -- Invigorating Healing Potion
		A.InvigoratingHealingPotion2		 	= Create({ Type = "Item", 				ID = 244838, 									QueueForbidden = true, Desc = "[6] HealingPotion", 					skipRange = true, Texture = 169451						})
		A.InvigoratingHealingPotion3 			= Create({ Type = "Item", 				ID = 244839, 									QueueForbidden = true, Desc = "[6] HealingPotion", 					skipRange = true, Texture = 169451						})
		A.FleetingInvigoratingHealingPotion 	= Create({ Type = "Item", 				ID = 244849, 									QueueForbidden = true, Desc = "[6] HealingPotion", 					skipRange = true, Texture = 169451						}) -- Fleeting Invigorating Healing Potion
	end
end

local function IsShoot(unit)
	return 	playerClass ~= "WARRIOR" and playerClass ~= "ROGUE" and 		-- their shot must be in profile 
			GetToggle(1, "AutoShoot") and not Player:IsShooting() and  
			(
				(playerClass == "HUNTER" and A.AutoShot:IsReadyP(unit)) or 	-- :IsReady also checks ammo amount by :IsUsable method
				(playerClass ~= "HUNTER" and HasWandEquipped() and A.Shoot:IsInRange(unit) and GetCurrentGCD() <= GetPing() and (not GetToggle(1, "AutoAttack") or not Player:IsAttacking() or Unit(unit):GetRange() > 6))
			)
end 


function A.CanUseHealthstoneOrHealingPotion()
	-- @return object 
	if not Player:IsStealthed() then 	
		-- Healthstone | HealingPotion
		local Healthstone = GetToggle(1, "HealthStone") 
		if Healthstone >= 0 and (BuildToC < 110000 or A.ZoneID ~= 1684 or Unit(player):HasDeBuffs(320102) == 0) then -- Retail: Theater of Pain zone excluding "Blood and Glory" debuff
			local HS = A.HS:IsReadyByPassCastGCD(player) and A.HS or (BuildToC >= 110000 and A.DemonicHS:IsReadyByPassCastGCD(player) and A.DemonicHS)
			if HS then 					
				if Healthstone >= 100 then -- AUTO 
					if Unit(player):TimeToDie() <= 9 and Unit(player):HealthPercent() <= 40 then 
						return HS
					end 
				elseif Unit(player):HealthPercent() <= Healthstone then 
					return HS							 
				end
			elseif A.Zone ~= "arena" and (A.Zone ~= "pvp" or not InstanceInfo.isRated) then 
				local InvigoratingHealingPotion 	= BuildToC >= 110200 and DetermineUsableObject(player, nil, nil, true, nil, A.FleetingInvigoratingHealingPotion, A.InvigoratingHealingPotion3, A.InvigoratingHealingPotion2, A.InvigoratingHealingPotion1)
				local AlgariHealingPotion 			= BuildToC >= 110000 and DetermineUsableObject(player, nil, nil, true, nil, A.AlgariHealingPotion7, A.AlgariHealingPotion6, A.AlgariHealingPotion5, A.AlgariHealingPotion4, A.AlgariHealingPotion3, A.AlgariHealingPotion2, A.AlgariHealingPotion1)
				local RefreshingHealingPotion 		= BuildToC >= 100000 and DetermineUsableObject(player, nil, nil, true, nil, A.RefreshingHealingPotion3, A.RefreshingHealingPotion2, A.RefreshingHealingPotion1)
				local HealingPotion = (InvigoratingHealingPotion  	and InvigoratingHealingPotion:IsReadyByPassCastGCD(player)  and InvigoratingHealingPotion)  or  -- TWW 11.2
									  (AlgariHealingPotion  		and AlgariHealingPotion:IsReadyByPassCastGCD(player)  	  	and AlgariHealingPotion)  		or  -- TWW
									  (RefreshingHealingPotion  	and RefreshingHealingPotion:IsReadyByPassCastGCD(player)  	and RefreshingHealingPotion)  	or  -- DF
									  (A.SpiritualHealingPotion 	and A.SpiritualHealingPotion:IsReadyByPassCastGCD(player) 	and A.SpiritualHealingPotion) 	or  -- SL
									  (A.AbyssalHealingPotion   	and A.AbyssalHealingPotion:IsReadyByPassCastGCD(player)	  	and A.AbyssalHealingPotion)			-- BFA
									  
				
				if HealingPotion then 
					if Healthstone >= 100 then -- AUTO 
						if Unit(player):TimeToDie() <= 9 and Unit(player):HealthPercent() <= 40 and Unit(player):HealthDeficit() >= (HealingPotion:GetItemDescription()[1] or 0) then 
							if HealingPotion:GetItemDescription()[1]  == nil then
								error("HealingPotion is nil, wrong itemID? " .. HealingPotion.ID)
							end 
							return HealingPotion
						end 
					elseif Unit(player):HealthPercent() <= Healthstone then 
						return HealingPotion						 
					end			  
				end 
			end 
		end
		
		-- PhialofSerenity
		if BuildToC >= 90000 and A.Zone ~= "arena" and (A.Zone ~= "pvp" or not InstanceInfo.isRated) and A.PhialofSerenity:IsReadyByPassCastGCD(player) then 
			-- Healing 
			local PhialofSerenityHP, PhialofSerenityOperator, PhialofSerenityTTD = GetToggle(2, "PhialofSerenityHP"), GetToggle(2, "PhialofSerenityOperator"), GetToggle(2, "PhialofSerenityTTD")
			if PhialofSerenityOperator == "AND" then 
				if (PhialofSerenityHP <= 0 or Unit(player):HealthPercent() <= PhialofSerenityHP) and (PhialofSerenityTTD <= 0 or Unit(player):TimeToDie() <= PhialofSerenityTTD) then 
					return A.PhialofSerenity
				end 
			else
				if (PhialofSerenityHP > 0 and Unit(player):HealthPercent() <= PhialofSerenityHP) or (PhialofSerenityTTD > 0 and Unit(player):TimeToDie() <= PhialofSerenityTTD) then 
					return A.PhialofSerenity
				end 
			end 
			
			-- Dispel 
			if AuraIsValidByPhialofSerenity() then 
				return A.PhialofSerenity	
			end 
		end 
	end
end; local CanUseHealthstoneOrHealingPotion = A.CanUseHealthstoneOrHealingPotion

local function SetMetaAlpha(meta, alpha)
	local frame = TMW.profile[1][meta]
	if frame and frame:GetAlpha() ~= alpha then
		frame:SetAlpha(alpha)
	end
end

function A.Rotation(icon)
	local APL = A[A.PlayerSpec]
	if not A.IsInitialized or not APL then 
		return A_Hide(icon)		
	end 	
	
	local meta 		= icon.ID
	local metaobj  	= APL[meta]
	local metatype 	= GetMetaType[metaobj or "nil"]
	
	-- [1] CC / [2] Interrupt 
	if meta <= 2 then 
		if metatype == "function" then 
			if metaobj(icon) then 
				return true
			elseif GetToggle(1, "AntiFakePauses")[meta] then
				return A.AntiFakeWhite:Show(icon)
			end 
		end 						
		
		return A_Hide(icon)
	end 
	
	-- [5] Trinket 
	if meta == 5 then 
		local result, isApplied, RacialAction
		
		-- Use racial available trinkets if we don't have additional RACIAL_LOC
		-- Note: Additional RACIAL_LOC is the main reason why I avoid here :AutoRacial (see below 'if isApplied then')
		if GetToggle(1, "Racial") then 
			local playerRace 	= playerRace
			
			RacialAction 		= APL[GetKeyByRace[playerRace]]			
			local RACIAL_LOC 	= LoC_GetExtra[playerRace]							-- Loss Of Control 
			if RACIAL_LOC and RacialAction and RacialAction:IsReady(player, true) and RacialAction:IsExists() then 
				result, isApplied = LoC:IsValid(RACIAL_LOC.Applied, RACIAL_LOC.Missed, playerRace == "Dwarf" or playerRace == "Gnome")
				if result then 
					return RacialAction:Show(icon)
				end 
			end 		
		end	
		
		-- Use specialization spell trinkets
		if metatype == "function" and metaobj(icon) then  
			return true 			
		end 	

		-- Use (H)G.Medallion
		-- Note: Shadowlands no longer have it
		if BuildToC < 90000 and Medallion.isValid() and LoC:IsValid(Medallion.Applied) then 			
			return A.GladiatorMedallion:Show(icon)	
		end 
		
		-- Use racial if nothing is not available 
		if isApplied then 
			return RacialAction:Show(icon)
		end 
			
		return A_Hide(icon)		 
	end 
	
	local PauseChecks = PauseChecks()
	if PauseChecks then
		if meta == 3 then 
			if PauseChecks ~= CONST_PAUSECHECKS_DISABLED then
				SetMetaAlpha(meta, 0)
			else
				SetMetaAlpha(meta, 1)
			end
			return A:Show(icon, PauseChecks)
		end  
		return A_Hide(icon)	
	end	
	
	-- [6] Passive: @player, @raid1, @party1, @arena1 
	if meta == 6 then 
		-- Shadowmeld
		if APL.Shadowmeld and APL.Shadowmeld:AutoRacial(player) then 
			return APL.Shadowmeld:Show(icon)
		end 
		
		-- Stopcasting
		if GetToggle(1, "StopCast") then 
			local _, castLeft, _, _, castName, notInterruptable = Unit(player):CastTime() 
			if castName then 
				-- Catch Counter Shot 
				if A.IsInPvP and not notInterruptable and UnitCooldown:GetCooldown("arena", CONST_SPELLID_COUNTER_SHOT) > UnitCooldown:GetMaxDuration("arena", CONST_SPELLID_COUNTER_SHOT) - 1 and UnitCooldown:IsSpellInFly("arena", CONST_SPELLID_COUNTER_SHOT) then 
					local Caster = UnitCooldown:GetUnitID("arena", CONST_SPELLID_COUNTER_SHOT)
					if Caster and Unit(Caster):GetRange() <= 40 and Unit(player):HasBuffs(TotalAndKickImun) == 0 then 
						return A:Show(icon, CONST_STOPCAST)
					end 
				end 
				
				-- Mythic 7+ 
				-- Quaking Affix
				if InstanceInfo.KeyStone and InstanceInfo.KeyStone >= 7 and InstanceInfo.GroupSize <= 5 then 
					local QuakingDeBuff = Unit(player):HasDeBuffs(240447, true)
					if QuakingDeBuff ~= 0 and castLeft >= QuakingDeBuff - GetPing() - 0.1 then 
						return A:Show(icon, CONST_STOPCAST)
					end 
				end 
			end 
		end 
		
		-- Cursor 
		if A.GameTooltipClick and not IsMouseButtonDown("LeftButton") and not IsMouseButtonDown("RightButton") then 			
			if A.GameTooltipClick == "LEFT" then 
				return A:Show(icon, CONST_LEFT)			 
			elseif A.GameTooltipClick == "RIGHT" then 
				return A:Show(icon, CONST_RIGHT)
			end 
		end 
		
		-- ReTarget ReFocus 
		if (A.Zone == "arena" or A.Zone == "pvp") and (A:GetTimeSinceJoinInstance() >= 30 or Unit(player):CombatTime() > 0) then 
			if Re:CanTarget(icon) then 
				return true
			end 
			
			if Re:CanFocus(icon) then 
				return true
			end
		end 
		
		-- Healthstone | RefreshingHealingPotion | SpiritualHealingPotion | AbyssalHealingPotion | PhialofSerenity
		local HealingObject = CanUseHealthstoneOrHealingPotion() 
		if HealingObject then 
			return HealingObject:Show(icon)
		end 		
		
		-- AutoTarget 
		if GetToggle(1, "AutoTarget") and Unit(player):CombatTime() > 0 and not Unit(target):IsExplosives() and not Unit(target):IsCondemnedDemon() and not Unit(target):IsVoidTendril() and (not A.IamHealer or not Unit(target):IsExists() or Unit(target):IsEnemy()) then 
			if IsExplosivesExists() or IsCondemnedDemonsExists() or IsVoidTendrilsExists(true) then
				return A:Show(icon, CONST_AUTOTARGET)			  				 
			end 
			
			if  (not Unit(target):IsExists() or (A.Zone ~= "none" and not A.IsInPvP and not Unit(target):IsCracklingShard() and Unit(target):CombatTime() == 0 and Unit(target):IsEnemy() and Unit(target):HealthPercent() >= 100)) 	-- No existed or switch target in PvE if we accidentally selected out of combat unit  			
				and ((not A.IsInPvP and MultiUnits:GetByRangeInCombat(nil, 1) >= 1) or A.Zone == "pvp") 																																-- If rotation mode is PvE and in 40 yards any in combat enemy (exception target) or we're on (R)BG 
			then 
				return A:Show(icon, CONST_AUTOTARGET)
			end 
			
			-- Patch 8.2
			-- 1519 is The Eternal Palace: Precipice of Dreams
			-- Switch target if accidentally selected player in group under Delirium Realm (DeBuff)
			if not A.IsInPvP and A.ZoneID == 1519 and Unit(target):IsEnemy() and Unit(target):IsPlayer() and Unit(target):InGroup() then 
				return A:Show(icon, CONST_AUTOTARGET)
			end 
		end 
	end 
	
	-- Queue System
	if IsQueueReady(meta) then
		if meta == 3 then SetMetaAlpha(meta, 1) end
		return QueueData[1]:Show(icon)				 
    end 
	
	-- Hide frames which are not used by profile
	if metatype ~= "function" then 
		return A_Hide(icon)
	end 	
	
	-- Save unit for AutoAttack, AutoShoot
	local unit, useShoot
	if IsUnitEnemy(mouseover) then 
		unit = mouseover
	elseif IsUnitEnemy(target) then 
		unit = target
	elseif IsUnitEnemy(targettarget) then 
		unit = targettarget
	end 	
	
	-- [3] Single / [4] AoE: AutoAttack
	if unit and (meta == 3 or meta == 4) and not Player:IsStealthed() and Unit(player):IsCastingRemains() == 0 and HasFullControl() then 
		if not IsShoot(unit) and unit ~= targettarget and GetToggle(1, "AutoAttack") and not Player:IsAttacking() then 
				-- Use AutoAttack only if not a hunter or it's is out of range by AutoShot 
			if 	(playerClass ~= "HUNTER" or not GetToggle(1, "AutoShoot") or not Player:IsShooting() or not A.AutoShot:IsInRange(unit)) and 
				-- ByPass Rogue's mechanic
				(playerClass ~= "ROGUE" or ((unit ~= mouseover or UnitIsUnit(unit, target)) and Unit(unit):HasDeBuffs("BreakAble") == 0)) and 
				-- ByPass Warlock's mechanic 
				(playerClass ~= "WARLOCK" or Unit(unit):GetRange() <= 5)
			then 
				if meta == 3 then SetMetaAlpha(meta, 1) end
				return A:Show(icon, CONST_AUTOATTACK)
			end 
		end 
	end 	
	
	-- [3] Single / [4] AoE / [6-8] Passive: @player-party1-3, @raid1-3, @arena1-3 + Active: other AntiFakes
	if metaobj(icon) then 
		if meta == 3 then SetMetaAlpha(meta, 1) end
		return true 
	end 
	
	-- [3] Set Class Portrait
	if meta == 3 and not GetToggle(1, "DisableClassPortraits") then 
		SetMetaAlpha(meta, 0)
		return A:Show(icon, ClassPortaits[playerClass])
	end 
	
	-- [7] CC Focus / [8] Interrupt Focus / [9] CC2 / [10] CC2 Focus
	if BuildToC >= 20000 and metaobj and meta >= 7 and GetToggle(1, "AntiFakePauses")[meta - 4] then 
		return A.AntiFakeWhite:Show(icon)
	end 	
	
	A_Hide(icon)			
end 

-- setfenv will make working it way faster as lua condition for TMW frames 
do 
	local vType
	for k, v in pairs(A) do 
		vType = type(v)
		if (vType == "table" or vType == "function") and _G[k] == nil and Env[k] == nil then 
			Env[k] = v
		end		
	end 
end 
--[[
CNDT.EnvMeta.__index = function(t, v)		
	if _G[v] ~= nil then 	
		return _G[v]
	else		
		local vType = type(A[v])
		if vType == "table" or vType == "function" then 
			t[v] = A[v]
		end 
		return A[v]
	end 
end]]