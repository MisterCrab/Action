local _G, setmetatable, unpack, select, next, type, pairs, ipairs, math, error =
	  _G, setmetatable, unpack, select, next, type, pairs, ipairs, math, error

local huge 									= math.huge
local math_max								= math.max
local math_floor							= math.floor
local math_random							= math.random
local wipe									= _G.wipe
local strsplit								= _G.strsplit
local strjoin								= _G.strjoin
local debugstack							= _G.debugstack

local TMW 									= _G.TMW
local CNDT 									= TMW.CNDT
local Env 									= CNDT.Env
--local AuraTooltipNumber					= Env.AuraTooltipNumber -- this is broken
local AuraTooltipNumberPacked 				= Env.AuraTooltipNumberPacked
local AuraVariableNumber 					= Env.AuraVariableNumber
local strlowerCache  						= TMW.strlowerCache

local A   									= _G.Action
local BuildToC								= A.BuildToC
local CONST 								= A.Const
local Listener								= A.Listener
local insertMulti							= A.TableInsertMulti
local toNum 								= A.toNum
local strElemBuilder						= A.strElemBuilder
local InstanceInfo							= A.InstanceInfo
local Player 								= A.Player
local UnitCooldown							= A.UnitCooldown
local CombatTracker							= A.CombatTracker
local MultiUnits							= A.MultiUnits
local GetToggle								= A.GetToggle
local MouseHasFrame							= A.MouseHasFrame
local UnitInLOS								= A.UnitInLOS
local PlayerClass							= A.PlayerClass
local UnitSpecsMap							= A.UnitSpecsMap

local LibStub								= _G.LibStub
local LibRangeCheck  						= LibStub("LibRangeCheck-3.0")
local LibBossIDs							= LibStub("LibBossIDs-1.0").BossIDs

local TeamCache								= A.TeamCache
local TeamCacheFriendly 					= TeamCache.Friendly
local TeamCacheFriendlyUNITs				= TeamCacheFriendly.UNITs
local TeamCacheFriendlyGUIDs				= TeamCacheFriendly.GUIDs
local TeamCacheFriendlyIndexToPLAYERs		= TeamCacheFriendly.IndexToPLAYERs
local TeamCacheFriendlyIndexToPETs			= TeamCacheFriendly.IndexToPETs
local TeamCacheFriendlyHEALER				= TeamCacheFriendly.HEALER
local TeamCacheFriendlyTANK					= TeamCacheFriendly.TANK
local TeamCacheFriendlyDAMAGER				= TeamCacheFriendly.DAMAGER
local TeamCacheFriendlyDAMAGER_MELEE		= TeamCacheFriendly.DAMAGER_MELEE
--local TeamCacheFriendlyDAMAGER_RANGE		= TeamCacheFriendly.DAMAGER_RANGE
local TeamCacheEnemy 						= TeamCache.Enemy
local TeamCacheEnemyUNITs					= TeamCacheEnemy.UNITs
local TeamCacheEnemyGUIDs					= TeamCacheEnemy.GUIDs
local TeamCacheEnemyIndexToPLAYERs			= TeamCacheEnemy.IndexToPLAYERs
local TeamCacheEnemyIndexToPETs				= TeamCacheEnemy.IndexToPETs
local TeamCacheEnemyHEALER					= TeamCacheEnemy.HEALER
local TeamCacheEnemyTANK					= TeamCacheEnemy.TANK
local TeamCacheEnemyDAMAGER					= TeamCacheEnemy.DAMAGER
local TeamCacheEnemyDAMAGER_MELEE			= TeamCacheEnemy.DAMAGER_MELEE
--local TeamCacheEnemyDAMAGER_RANGE			= TeamCacheEnemy.DAMAGER_RANGE
local ActiveUnitPlates						= MultiUnits:GetActiveUnitPlates()
local ActiveUnitPlatesAny					= MultiUnits:GetActiveUnitPlatesAny()

local CACHE_DEFAULT_TIMER_UNIT				= CONST.CACHE_DEFAULT_TIMER_UNIT

local GameLocale 							= A.FormatGameLocale(_G.GetLocale())
local CombatLogGetCurrentEventInfo			= _G.CombatLogGetCurrentEventInfo
local GetUnitSpeed							= _G.GetUnitSpeed
local C_Spell								= _G.C_Spell
local GetSpellName 							= C_Spell and C_Spell.GetSpellName or _G.GetSpellInfo
local GetSpellInfo							= C_Spell and C_Spell.GetSpellInfo or _G.GetSpellInfo
local GetPartyAssignment 					= _G.GetPartyAssignment	 
local UnitIsUnit, UnitPlayerOrPetInRaid, UnitInAnyGroup, UnitPlayerOrPetInParty, UnitInRange, UnitInVehicle, UnitIsQuestBoss, UnitEffectiveLevel, UnitLevel, UnitThreatSituation, UnitRace, UnitClass, UnitGroupRolesAssigned, UnitClassification, UnitExists, UnitIsConnected, UnitIsCharmed, UnitIsGhost, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitIsPlayer, UnitPlayerControlled, UnitCanAttack, UnitIsEnemy, UnitAttackSpeed,
	  UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitCanCooperate, UnitCastingInfo, UnitChannelInfo, UnitCreatureType, UnitCreatureFamily, UnitHealth, UnitHealthMax, UnitGetIncomingHeals, UnitGUID, UnitHasIncomingResurrection, UnitIsVisible, UnitGetTotalHealAbsorbs, UnitStagger, UnitAura =
	  UnitIsUnit, UnitPlayerOrPetInRaid, UnitInAnyGroup, UnitPlayerOrPetInParty, UnitInRange, UnitInVehicle, UnitIsQuestBoss, UnitEffectiveLevel, UnitLevel, UnitThreatSituation, UnitRace, UnitClass, UnitGroupRolesAssigned, UnitClassification, UnitExists, UnitIsConnected, UnitIsCharmed, UnitIsGhost, UnitIsDeadOrGhost, UnitIsFeignDeath, UnitIsPlayer, UnitPlayerControlled, UnitCanAttack, UnitIsEnemy, UnitAttackSpeed,
	  UnitPowerType, UnitPowerMax, UnitPower, UnitName, UnitCanCooperate, UnitCastingInfo, UnitChannelInfo, UnitCreatureType, UnitCreatureFamily, UnitHealth, UnitHealthMax, UnitGetIncomingHeals, UnitGUID, UnitHasIncomingResurrection, UnitIsVisible, UnitGetTotalHealAbsorbs, UnitStagger, _G.C_UnitAuras.GetAuraDataByIndex
-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, A_GetSpellInfo, A_GetGCD, A_GetCurrentGCD, A_IsTalentLearned, A_IsSpellInRange, A_EnemyTeam, A_GetUnitItem

Listener:Add("ACTION_EVENT_UNIT", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then
		A_Unit						= A.Unit
		A_GetSpellInfo				= A.GetSpellInfo
		A_GetGCD					= A.GetGCD
		A_GetCurrentGCD				= A.GetCurrentGCD
		A_IsTalentLearned			= A.IsTalentLearned
		A_IsSpellInRange			= A.IsSpellInRange
		A_EnemyTeam					= A.EnemyTeam
		A_GetUnitItem				= A.GetUnitItem

		Listener:Remove("ACTION_EVENT_UNIT", "ADDON_LOADED")
	end
end)
-------------------------------------------------------------------------------

local function GetGUID(unitID)
	return TeamCacheFriendlyUNITs[unitID] or TeamCacheEnemyUNITs[unitID] or UnitGUID(unitID)
end

-------------------------------------------------------------------------------
-- Cache
-------------------------------------------------------------------------------
local str_none = "none"
local str_empty = ""

local function PseudoClass(methods)
    local Class = setmetatable(methods, {
		__call = function(self, ...)
			self:New(...)
			return self
		end,
    })
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
		this.bufer[func][keyArg].t = TMW.time + (inv or CACHE_DEFAULT_TIMER_UNIT) + 0.001  -- Add small delay to make sure what it's not previous corroute
		insertMulti(this.bufer[func][keyArg].v, func(...))
		return unpack(this.bufer[func][keyArg].v)
	end,
	Wrap = function(this, func, name)
		if CONST.CACHE_DISABLE then
			return func
		end

		if not this.bufer[func] then
			this.bufer[func] = {}
		end

   		return function(...)
			-- The reason of all this view look is memory hungry eating, this way use around 0 memory now
			local self = ...
			local keyArg = strElemBuilder(name == "UnitGUID" and self.UnitID and UnitGUID(self.UnitID) or self.UnitID or self.ROLE or name, ...)

	        if TMW.time > (this.bufer[func][keyArg] and this.bufer[func][keyArg].t or 0) then
	            return this:newEl(self.Refresh, keyArg, func, ...)
	        else
	            return unpack(this.bufer[func][keyArg].v)
	        end
        end
    end,
	Pass = function(this, func, name)
		if CONST.CACHE_MEM_DRIVE and not CONST.CACHE_DISABLE then
			return this:Wrap(func, name)
		end

		return func
	end,
}

local AuraList = {
    -- CC SCHOOL TYPE
    Magic = {
        118, -- Polymorph
        605, -- Mind Control
        9484, -- Shackle Undead
        2637, -- Hibernate
        20066, -- Repentance
        5782, -- Fear
        3355, -- Freezing Trap
        278468, -- Freezing Trap
        209790, -- Freezing Arrow (hunter pvp)
        6358, -- Seduction
        82691, -- Ring of Frost
        198909, -- Song of Chi-ji (mistweaver monk talent)
        5484, -- Howl of Terror
        6789, -- Mortal Coil
        87204, -- Sin and Punishment
        8122, -- Psychic Scream
        31661, -- Dragon's Breath
        105421, -- Bliding light (paladin talent)
        202274, -- Incendiary brew (brewmaster monk pvp talent)
        15487, -- Silence
        31935, -- Avenger's Shield
        199683, -- Last Word
        47476, -- Strangulate
        31117, -- Unstable Affliction
        853, -- Hammer of Justice
        64044, -- Psychic Horror
        30283, -- Shadowfury
        117526, -- Binding Shot
        118905, -- Static Charge
        179057, -- Chaos Nova
        205630, -- Illidan's Grasp (demon hunter)
        209749, -- Faerie Swarm (Moonkin Disarm)
        204399, -- Earthfury (enhancement shaman pvp talent)
        217832, -- Imprison
        286349, -- Gladiator's Maledict
		22703, -- Summon Infernal
		200166, -- Metamorphosis
		208618, -- Illidan's Grasp (secondary effect)
		211881, -- Fel Eruption
		200200, -- Holy word: Chastise (stunned)
		--200196, -- Holy word: Chastise (incapacitated)
    },
    MagicRooted = {
        233395, -- Frozen Center (DK PvP Frost)
        339, -- Entangling Roots
        122, -- Frost Nova
        102359, -- Mass Entanglement
        96294, -- Chains of Ice
        183218, -- Retri's -70%
    },
    Curse = {
        51514, -- Hex
        -- Warlock BFA
        12889, -- Curse of Tongues
        17227, -- Curse of Weakness
        199954, -- Curse of Fragility
    },
    Disease = {
        196782, -- Outbreak (5 sec infecting dot)
        191587, -- Outbreak (21+ sec dot)
        58180, -- Infected Wounds (Feral slow)
        -- [Blood Plague]
        -- [Frost Fever]
    },
    Poison = {
        19386, -- Wyvern Sting
        202933, -- Spider Sting
        202797, -- Viper Sting
        202900, -- Scorpid Sting
    },
    Physical = {
        115078, -- Paralysis
        6770, -- Sap
        107079, -- Quaking Palm
        207685, -- Sigil of Misery (Havoc Demon hunter)
        5246, -- Intimidating Shout
        99, -- Incapacitating Roar
        1776, -- Gouge
        2094, -- Blind
        186387, -- Bursting Shot (hunter marks ability)
        213691, -- Scatter Shot (hunter pvp talent)
        --25, -- Stun
        1833, -- Cheap Shot
        408, -- Kidney Shot
        5211, -- Mighty Bash
        24394, -- Intimidation
        89766, -- Axe Toss
        108194, -- Asphyxiate (DK)
        118345, -- Pulverize
        119381, -- Leg Sweep
        163505, -- Rake
        199804, -- Between the Eyes
        203123, -- Maim
        236025, -- Enraged Maim
        204399, -- Earthfury (enhancement shaman pvp talent)
        47481, -- Gnaw (DK pet)
        212332, -- Smash (DK transformation pet)
        -- 207167, -- Blinding Sleet (is it physical ? )
        207777, -- Dismantle
        236077, -- Disarm
        233759, -- Grapple Weapon
        212638, -- Tracker's Net (Hunter PvP talent)
        162480, -- Steel Trap (Hunter SV PvE talent)
		-- Warrior
		132168, -- Shockwave
        132169, -- Storm Bolt
		--237744, -- Warbringer
		-- Tauren
		--20549, -- War Stomp
		-- Kul Tiran
		287712, -- Haymaker
    },
    -- CC CONTROL TYPE
    CrowdControl = {
        -- Deprecated
		118, -- Hibernate
    },
    Incapacitated = {
		-- Druid
        99, -- Incapacitating Roar
		203126, -- Maim (Feral PvP talent)
		-- Hunter
		213691, -- Scatter Shot
        3355, -- Freezing Trap
        209790, -- Freezing Arrow
		19386, -- Wyvern Sting
		-- Mage
        118, -- Polymorph
		82691, -- Ring of Frost
		-- Monk
        115078, -- Paralysis
		-- Paladin
        20066, -- Repentance
		-- Priest
        200196, -- Holy Word: Chastise (Holy)
		--605, -- Dominate Mind (Mind Control) this is buff type
		9484, -- Shackle Undead
		-- Rogue
        6770, -- Sap
		1776, -- Gouge
		-- Shaman
        51514, -- Hex (also 211004, 210873, 211015, 211010)
		-- Warlock
		710, -- Banish
		6789, -- Mortal Coil
        -- Pandaren
        107079, -- Quaking Palm
		-- Demon Hunter
		217832, -- Imprison
		--221527, -- Improve Imprison
    },
    Disoriented = {
		-- Death Knight
		207167, -- Blinding Sleet (Frost)
		-- Demon Hunter
		207685, -- Sigil of Misery (Havoc)
		115268, -- Mesmerize
		-- Druid
		--33786, -- Cyclone
		--209753, -- Cyclone (Balance)
		-- Hunter
		--224729, -- Bursting Shot
		186387, -- Bursting Shot (MM)
		-- Mage
		31661, -- Dragon's Breath (Fire)
		-- Monk
		202274, -- Incendiary brew (BW)
		198909, -- Song of Chi-ji (MW)
        -- Paladin
        105421, -- Bliding light (Holy)
		-- Priest
		8122, -- Psychic Scream
		-- Rogue
        2094, -- Blind
		-- Warlock
		5782, -- Fear
		--118699, -- Fear
		--130616, -- Fear
		5484, -- Howl of Terror
		115268, -- Mesmerize (Shivarra)
		6358, -- Seduction (Succubus)
		-- Warrior
		5246, -- Intimidating Shout
    },
    Fear = {
        5782, -- Fear
        5484, -- Howl of Terror
        5246, -- Intimidating Shout
        8122, -- Psychic Scream
        87204, -- Sin and Punishment
        207685, -- Sigil of Misery (Havoc Demon hunter)
    },
    Charmed = {
		-- Deprecated
        605, -- Mind Control
        9484, -- Shackle Undead
    },
    Sleep = {
        2637, -- Hibernate
    },
    Stuned = {
		-- Death Knight
        47481, -- Gnaw (pet)
        212332, -- Smash (transformation pet)
        108194, -- Asphyxiate
		207171, -- Winter is Coming (Remorseless winter stun)
		-- Demon Hunter
		179057, -- Chaos Nova
		200166, -- Metamorphosis
		205630, -- Illidan's Grasp (primary effect)
		208618, -- Illidan's Grasp (secondary effect)
		211881, -- Fel Eruption
		-- Druid
		203123, -- Maim
        5211, -- Mighty Bash
		163505, -- Rake
		--2637, -- Hibernate --FIXME: Not sure if Human race can avert it as stunned effect but it has stun DR
		--236025, -- Enraged Maim --FIXME: same
		-- Hunter
        117526, -- Binding Shot
        19577, -- Intimidation (pet)
		-- Monk
        119381, -- Leg Sweep
		-- Paladin
		853, -- Hammer of Justice
		-- Priest
		200200, -- Holy word: Chastise
		64044, -- Psychic Horror
		-- Rogue
		1833, -- Cheap Shot
        408, -- Kidney Shot
        199804, -- Between the Eyes
		-- Shaman
		118345, -- Pulverize (Primal Earth Elemental)
		118905, -- Static Charge (Capacitor Totem)
		-- Warlock
        30283, -- Shadowfury
        89766, -- Axe Toss (pet)
		22703, -- Summon Infernal
		-- Warrior
        132168, -- Shockwave
        132169, -- Storm Bolt
		237744, -- Warbringer
		-- Tauren
		20549, -- War Stomp
		-- Kul Tiran
		287712, -- Haymaker
    },
    PhysStuned = {
		-- Death Knight
		47481, -- Gnaw (pet)
        212332, -- Smash (transformation pet)
        108194, -- Asphyxiate
		-- Druid
        203123, -- Maim
        5211, -- Mighty Bash
		163505, -- Rake
		-- Hunter
		117526, -- Binding Shot
        19577, -- Intimidation (pet)
		-- Monk
        119381, -- Leg Sweep
        -- Rogue
        1833, -- Cheap Shot
        408, -- Kidney Shot
        199804, -- Between the Eyes
		-- Shaman
		118345, -- Pulverize (Primal Earth Elemental)
        -- Warlock
		89766, -- Axe Toss (pet)
        -- Druid
		203123, -- Maim
        5211, -- Mighty Bash
		163505, -- Rake
		--236025, -- Enraged Maim --FIXME: it's desorient but DR trigger it as stun
		-- Warrior
        132168, -- Shockwave
        132169, -- Storm Bolt
		237744, -- Warbringer
		-- Tauren
		20549, -- War Stomp
		-- Kul Tiran
		287712, -- Haymaker
    },
    Silenced = {
		-- Death Knight
		47476, -- Strangulate (Unholy/Blood)
		-- Demon Hunter
        204490, -- Sigil of Silence (Havoc)
		-- Druid
        78675, -- Solar Beam (Balance)
		-- Hunter
        202933, -- Spider Sting
		-- Paladin
        31935, -- Avenger's Shield	(Prot)
		-- Priest
        15487, -- Silence (Shadow)
		199683, -- Last Word (Holy)
		-- Rogue
        1330, -- Garrote - Silence
        -- Warlock
        31117, -- Unstable Affliction
    },
    Disarmed = {
		-- Rogue
        207777, -- Dismantle
		-- Warrior
        236077, -- Disarm
		-- Monk
        233759, -- Grapple Weapon
		-- Druid
        209749, -- Faerie Swarm
    },
    Rooted = {
        339, -- Entangling Roots Dispel able
        235963, -- Entangling Roots NO Dispel able
        122, -- Frost Nova
        33395, -- Freeze (frost mage water elemental)
        45334, -- Immobilized (wild charge, bear form)
        53148, -- Charge
        64695, -- Earthgrab
        91807, -- Shambling Rush (DK pet)
        102359, -- Mass Entanglement
        105771, -- Charge
        116706, -- Disable
        157997, -- Ice Nova (frost mage talent)
        190927, -- harpoon (survival hunter)
        199042, -- Thunderstruck (Warrior PVP)
        -- 200108, -- Ranger's Net (Hunter talent) (REMOVED)
        201158, -- Super Sticky Tar (Expert Trapper, Hunter talent, Tar Trap effect)
        204085, -- Deathchill (DK PVP)
        212638, -- Tracker's Net (Hunter PvP talent)
        162480, -- Steel Trap (Hunter SV PvE talent)
        228600, -- glacial spike (frost mage talent)
        233395, -- Frozen Center (DK PvP Frost)
        183218, -- Retri's -70%
    },
    Slowed = {
        116, -- Frostbolt
        120, -- Cone of Cold
        2120, -- Flamestrike
        6343, -- Thunder Clap
        1715, -- Hamstring
        3409, -- Crippling Poison
        3600, -- Earthbind
        5116, -- Concussive Shot
        12544, -- Frost Armor
        7992, -- Slowing Poison
        26679, -- Deadly Throw
        35346, -- Warp Time
        44614, -- Flurry
        45524, -- Chains of Ice
        50259, -- Dazed (Wild Charge, druid talent, cat form)
        50433, -- Ankle Crack
        51490, -- Thunderstorm
        61391, -- Typhoon
        12323, -- Piercing Howl
        13810, -- Ice Trap
        15407, -- Mind Flay
        31589, -- Slow
        58180, -- Infected Wounds
        102793, -- Ursol's Vortex
        116095, -- Disable
        121253, -- Keg Smash
        123586, -- Flying Serpent Kick
        135299, -- Tar Trap
        147732, -- Frostbrand Attack
        157981, -- Blast Wave
        160065, -- Tendon Rip
        160067, -- Web Spray
        169733, -- Brutal Bash
        183218, -- Hand of Hindrance
        185763, -- Pistol Shot
        190780, -- Frost Breath (dk frost artifact ability)
        191397, -- Bestial Cunning
        194279, -- Caltrops
        194858, -- Dragonsfire Grenade
        195645, -- Wing Clip
        196840, -- Frost Shock
        198813, -- Vengeful Retreat
        201142, -- Frozen Wake (freezing trap break slow from master trapper survival hunter talent)
        204263, -- Shining Force
        204843, -- Sigil of Chains
        205021, -- Ray of Frost (frost mage talent)
        205320, -- Strike of the Windlord
        205708, -- Chilled (frost mage effect)
        206755, -- Ranger's Net
        206760, -- Night Terrors
        206930, -- Heart Strike
        208278, -- Debilitating Infestation (DK unholy talent)
        209786, -- Goremaw's Bite
        211793, -- Remorseless Winter
        211831, -- Abomination's Might
        212764, -- White Walker
        212792, -- Cone of Cold (frost mage)
        222775, -- Strike from the Shadows
        228354, -- Flurry (frost mage ability)
        210979, -- Focus in the light (holy priest artifact trait)
        248744, -- Shiv
        198145, -- System Shock
    },
    MagicSlowed = {
        116, -- Frostbolt
        120, -- Cone of Cold
        3600, -- Earthbind
        12544, -- Frost Armor
        44614, -- Flurry
        61391, -- Typhoon
        123586, -- Flying Serpent Kick
        147732, -- Frostbrand Attack
        183218, -- Hand of Hindrance
        190780, -- Frost Breath (dk frost artifact ability)
        196840, -- Frost Shock
        201142, -- Frozen Wake (freezing trap break slow from master trapper survival hunter talent)
        204263, -- Shining Force
        204843, -- Sigil of Chains
        205320, -- Strike of the Windlord
        205708, -- Chilled (frost mage effect)
        206760, -- Night Terrors
        209786, -- Goremaw's Bite
        212764, -- White Walker
        212792, -- Cone of Cold (frost mage)
        228354, -- Flurry (frost mage ability)
        210979, -- Focus in the light (holy priest artifact trait)
    },
    BreakAble = {
        118, -- Polymorph
        6770, -- Sap
        20066, -- Repentance
        51514, -- Hex
        2637, -- Hibernate
        5782, -- Fear
        3355, -- Freezing Trap
        209790, -- Freezing Arrow
        6358, -- Seduction
        2094, -- Blind
        19386, -- Wyvern Sting
        82691, -- Ring of Frost
        115078, -- Paralysis
        5484, -- Howl of Terror
        5246, -- Intimidating Shout
        --6789, -- Mortal Coil
        8122, -- Psychic Scream
        99, -- Incapacitating Roar
        1776, -- Gouge
        31661, -- Dragon's Breath
        105421, -- Blinding Light
        186387, -- Bursting Shot
        202274, -- Incendiary brew (brewmaster monk pvp talent)
        207167, -- Blinding Sleet
        213691, -- Scatter Shot
        217832, -- Imprison
        236025, -- Enraged Maim
        207685, -- Sigil of Misery (Havoc Demon hunter)
        -- Rooted CC
        --339, -- Entagle Roots
        212638, -- tracker's net (hunter PvP )
        --102359, -- Mass Entanglement
        --122, -- Frost Nova
        233395, -- Frozen Center (DK PvP Frost)
        107079, -- Quaking Palm
    },
    -- Imun Specific Buffs
    FearImun = {
        212704, -- The Beast Within (Hunter BM PvP)
        287081, -- Lichborne
        8143, -- Tremor Totem
    },
    StunImun = {
        48792, -- Icebound Fortitude
        6615, -- Free Action (Human)
        1953, -- Blink (micro buff)
        287081, -- Lichborne
    },
    Freedom = {
        1044, -- Blessing of Freedom
        48265, -- Death's Advance
        287081, -- Lichborne
        212552, -- Wraith Walk
        227847, -- Bladestorm
        53271, -- Master's Call
        116841, -- Tiger's Lust
        216113, -- Way of the Crane (Monk TT PvP)
    },
    TotalImun = {
		710, -- Banish
        642, -- Divine Shield
        45438, -- Ice Block
        186265, -- Aspect of Turtle
        215769, -- Spirit of Redemption
    },
    DamagePhysImun = {
        1022, -- Blessing of Protection
        188499, -- Blade Dance
        196555, -- Netherwalk
    },
    DamageMagicImun = {    -- When we can't totally damage
        31224, -- Cloak of Shadows
        204018, -- Blessing of Spellwarding
        196555, -- Netherwalk
    },
    CCTotalImun = {
        213610, -- Holy Ward
        227847, -- Bladestorm
    },
    CCMagicImun = {
        31224, -- Cloak of Shadows
        204018, -- Blessing of Spellwarding
        48707, -- Anti-Magic Shell
        8178, -- Grounding Totem Effect
        23920, -- Spell Reflection
        213915, -- Mass reflect
        212295, -- Nether Ward (Warlock)
    },
    Reflect = {            -- Only to cancel reflect effect
        8178, -- Grounding Totem Effect
        23920, -- Spell Reflection
        213915, -- Mass reflect
        212295, -- Nether Ward (Warlock)
    },
    KickImun = { -- Imun Silence too
        209584, -- Zen Focus Tea (Monk TT PvP)
        221703, -- Casting Circle (Warlock PvP)
        196762, -- Inner Focus
        289657, -- Holy Word: Concentration (Holy Priest PvP)
    },
    -- Purje
    ImportantPurje = {
        1022, -- Blessing of Protection
        79206, -- Spiritwalker's Grace
        190319, -- Combustion
        10060, -- Power Infusion
        12042, -- Arcane Power
        12472, -- Icy Veins
        213610, -- Holy Ward
        198111, -- Temporal Shield
        210294, -- Divine Favor
        212295, -- Nether Ward
        271466, -- Luminous Barrier
		311203, -- Moment of Glory
    },
    SecondPurje = {
        1044, -- Blessing of Freedom
        -- We need purje druid only in bear form
        33763, -- Lifebloom
        774, -- Rejuvenation
        155777, -- Rejuvenation (Germination)
        48438, -- Wild Growth
        8936, -- Regrow
        289318, -- Mark of the Wild
    },
    PvEPurje = {
        197797, 210662, 211632, 209033, 198745, 194615, 282098, 301629, 297133, 266201, 258938, 268709, 268375, 274210, 276265,
    },
    -- Speed
    Speed = {
        2983, -- Sprint
        2379, -- Speed
        2645, -- Ghost Wolf
        7840, -- Swim Speed
        36554, -- Shadowstep
        54861, -- Nitro Boosts
        58875, -- Spirit Walk
        65081, -- Body and Soul
        68992, -- Darkflight
        85499, -- Speed of Light
        87023, -- Cauterize
        61684, -- Dash
        77761, -- Stampeding Roar
        108843, -- Blazing Speed
        111400, -- Burning Rush
        116841, -- Tiger's Lust
        118922, -- Posthaste
        119085, -- Chi Torpedo
        121557, -- Angelic Feather
        137452, -- Displacer Beast
        137573, -- Burst of Speed
        192082, -- Wind Rush (shaman wind rush totem talent)
        196674, -- Planewalker (warlock artifact trait)
        197023, -- Cut to the chase (rogue pvp talent)
        199407, -- Light on your feet (mistweaver monk artifact trait)
        201233, -- whirling kicks (windwalaker monk pvp talent)
        201447, -- Ride the wind (windwalaker monk pvp talent)
        209754, -- Boarding Party (rogue pvp talent)
        210980, -- Focus in the light (holy priest artifact trait)
        213177, -- swift as a coursing river (brewmaster artifact trait)
        214121, -- Body and Mind (priest talent)
        215572, -- Frothing Berserker (warrior talent)
        231390, -- Trailblazer (hunter talent)
        186257, -- Aspect of the Cheetah
        204475, -- Windburst (marks hunter artifact ability)
    },
    -- Deff
    DeffBuffsMagic = {
        116849, -- Life Cocoon
        114030, -- Vigilance
        47788, -- Guardian Spirit
        31850, -- Ardent Defender
        871, -- Shield Wall
        118038, -- Die by the Sword
        104773, -- Unending Resolve
        108271, -- Astral Shift
        6940, -- Blessing of Sacrifice
        31224, -- Cloak of Shadows
        48707, -- Anti-Magic Shell
        8178, -- Grounding Totem Effect
        23920, -- Spell Reflection
        213915, -- Mass reflect
        212295, -- Nether Ward (Warlock)
        33206, -- Pain Suppression
        47585, -- Dispersion
        186265, -- Aspect of Turtle
        115176, -- Zen Meditation
        122783, -- Diffuse Magic
        86659, -- Guardian of Ancient Kings
        642, -- Divine Shield
        45438, -- Ice Block
        122278, -- Dampen Harm
        61336, -- Survival Instincts
        45182, -- Cheating Death
        204018, -- Blessing of Spellwarding
        196555, -- Netherwalk
        206803, -- Rain from Above
    },
    DeffBuffs = {
        76577, -- Smoke Bomb
        53480, -- Road of Sacriface
        116849, -- Life Cocoon
        114030, -- Vigilance
        47788, -- Guardian Spirit
        31850, -- Ardent Defender
        871, -- Shield Wall
        118038, -- Die by the Sword
        104773, -- Unending Resolve
        6940, -- Blessing of Sacrifice
        108271, -- Astral Shift
        5277, -- Evasion
        102342, -- Ironbark
        -- 1022, -- Blessing of Protection
        74001, -- Combat Readiness
        -- 31224, -- Cloak of Shadows
        33206, -- Pain Suppression
        47585, -- Dispersion
        186265, -- Aspect of Turtle
        -- 48792, -- Icebound Fortitude
        115176, -- Zen Meditation
        122783, -- Diffuse Magic
        86659, -- Guardian of Ancient Kings
        642, -- Divine Shield
        45438, -- Ice Block
        -- 498, -- Divine Protection
        -- 157913, -- Evanesce
        115203, -- Fortifying Brew
        22812, -- Barkskin
        122278, -- Dampen Harm
        61336, -- Survival Instincts
        45182, -- Cheating Death
        198589, -- Blur
        196555, -- Netherwalk
        243435, -- Fortifying Brew
        206803, -- Rain from Above
    },
    -- Damage buffs / debuffs
    Rage = {
        18499, -- Berserker Rage
        184361, -- Enrage
    },
    DamageBuffs = {
        51690, -- Killing Spree
        -- 79140, -- Vendetta (debuff)
        121471, -- Shadow of Blades
        185313, -- Shadow Dance
        13750, -- Adrenaline Rush
        191427, -- Metamorphosis
        19574, -- Bestial Wrath
        -- 193530, -- Aspect of the Wild (small burst)
        266779, -- Coordinated Assault
        193526, -- Trueshot
        -- 5217, -- Tiger's Fury (small burst)
        106951, -- Berserk
        102560, -- Incarnation: Chosen of Elune
        102543, -- Incarnation: King of the Jungle
        190319, -- Combustion
        12042, -- Arcane Power
        12472, -- Icy Veins
        51271, -- Pillar of Frost
        207289, -- Unholy Frenzy
        31884, -- Avenging Wrath
        236321, -- Warbanner
        107574, -- Avatar
        114050, -- Ascendance
        113858, -- Dark Soul: Instability
        267217, -- Nether Portal
        113860, -- Dark Soul: Misery
        137639, -- Storm, Earth, and Fire
        152173, -- Serenity
    },
    DamageBuffs_Melee = {
        51690, -- Killing Spree
        121471, -- Shadow of Blades
        185313, -- Shadow Dance
        13750, -- Adrenaline Rush
        191427, -- Metamorphosis
        266779, -- Coordinated Assault
        106951, -- Berserk
        102543, -- Incarnation: King of the Jungle
        51271, -- Pillar of Frost
        207289, -- Unholy Frenzy
        31884, -- Avenging Wrath
        236321, -- Warbanner
        107574, -- Avatar
        114050, -- Ascendance
        137639, -- Storm, Earth, and Fire
        152173, -- Serenity
    },
    BurstHaste = {
        90355, -- Ancient Hysteria
        146555, -- Drums of Rage
        178207, -- Drums of Fury
        230935, -- Drums of the Mountain
        2825, -- Bloodlust
        80353, -- Time Warp
        160452, -- Netherwinds
        32182, -- Heroism
        230935, -- Drums of the Mountain
        256740, -- Drums of the Maelstrom
        264667, -- Primal Rage
        390386, -- Fury of the Aspects
        386540, -- Temporal Warp
        381301, -- Feral Hide Drums
    },
    -- SOME SPECIAL
    DamageDeBuffs = {
        79140, -- Vendetta (debuff)
        115080, -- Touhc of Death (debuff)
        122470, -- KARMA
    },
    Flags = {
        156621, -- Alliance flag
        23333,  -- Horde flag
        34976,  -- Netherstorm Flag
        121164, -- Orb of Power
    },
    -- Cast Bars
    Reshift = {
        {118, 45}, -- Polymorph (45 coz of blink available)
        {20066, 30}, -- Repentance
        {51514, 30}, -- Hex
        {19386, 40}, -- Wyvern Sting
    },
    Premonition = {
        {113724, 30}, -- Ring of Frost
        {118, 45}, -- Polymorph (45 coz of blink available while cast)
        {20066, 30}, -- Repentance
        {51514, 30}, -- Hex
        {19386, 40}, -- Wyvern Sting
        {5782, 30}, -- Fear
    },
    CastBarsCC = {
        113724, -- Ring of Frost
        118, -- Polymorph
        20066, -- Repentance
        51514, -- Hex
        19386, -- Wyvern Sting
        5782, -- Fear
        33786, -- Cyclone
        605, -- Mind Control
    },
    AllPvPKickCasts = {
        118, -- Polymorph
        20066, -- Repentance
        51514, -- Hex
        19386, -- Wyvern Sting
        5782, -- Fear
        33786, -- Cyclone
        605, -- Mind Control
        982, -- Revive Pet
        32375, -- Mass Dispel
        203286, -- Greatest Pyroblast
        116858, -- Chaos Bolt
        20484, -- Rebirth
        203155, -- Sniper Shot
        47540, -- Penance
        596, -- Prayer of Healing
        2060, -- Heal
        2061, -- Flash Heal
        32546, -- Binding Heal                        (priest, holy)
        33076, -- Prayer of Mending
        64843, -- Divine Hymn
        120517, -- Halo                                (priest, holy/disc)
        186263, -- Shadow Mend
        194509, -- Power Word: Radiance
        265202, -- Holy Word: Salvation                (priest, holy)
        289666, -- Greater Heal                        (priest, holy)
        740, -- Tranquility
        8936, -- Regrowth
        48438, -- Wild Growth
        289022, -- Nourish                             (druid, restoration)
        1064, -- Chain Heal
        8004, -- Healing Surge
        73920, -- Healing Rain
        77472, -- Healing Wave
        197995, -- Wellspring                          (shaman, restoration)
        207778, -- Downpour                            (shaman, restoration)
        19750, -- Flash of Light
        82326, -- Holy Light
        116670, -- Vivify
        124682, -- Enveloping Mist
        209525, -- Soothing Mist
        227344, -- Surging Mist                        (monk, mistweaver)
    },
}

local AssociativeTables = setmetatable({ NullTable = {} }, { -- Only for Auras!
	--__mode = "kv",
	__index = function(t, v)
	-- @return table
	-- Returns converted array like table to associative like with key-val as spellName and spellID with true val
	-- For situations when Action is not initialized and when 'v' is table always return self 'v' to keep working old profiles which use array like table
	-- Note: GetSpellName instead of A_GetSpellInfo because we will use it one time either if GC collected dead links, pointless for performance A_GetSpellInfo anyway
	if not v then
		if A.IsInitialized then -- old profiles are funky some times..
			local error_snippet = debugstack():match("%p%l+%s\"?%u%u%u%s%u%l.*")
			if error_snippet then
				error("Unit.lua script tried to put in AssociativeTables 'nil' as index and it caused null table return. The script successfully found the first occurrence of the error stack in the TMW snippet: " .. error_snippet, 0)
			else
				error("Unit.lua script tried to put in AssociativeTables 'nil' as index and it caused null table return.\n" .. debugstack())
			end
		end
		return t.NullTable
	end

	local v_type = type(v)
	if v_type == "table" then
		if not A.IsInitialized then
			--print("NON-STATIC:", tostring(v), " Key:", next(v))
			return v
		end

		if #v > 0 then
			t[v] = {}

			local index, val = next(v)
			while index ~= nil do
				if type(val) == "string" then
					if AuraList[val] then
						-- Put associatived spellName (@string) and spellID (@number)
						for spellNameOrID, spellBoolean in pairs(t[val]) do
							t[v][spellNameOrID] = spellBoolean
						end
					else -- Here is expected name of the spell always
						-- Put associatived spellName (@string)
						t[v][val] = true
					end
				else -- Here is expected id of the spell always
					-- Put associatived spellName (@string)
					local spellName = GetSpellName(val)
					if spellName then
						t[v][spellName] = true
					end

					-- Put associatived spellID (@number)
					t[v][val] = true
				end

				index, val = next(v, index)
			end
		else
			t[v] = v
		end
	elseif AuraList[v] then
		t[v] = {}

		local spellName
		for _, spellID in ipairs(AuraList[v]) do
			spellName = GetSpellName(spellID)
			if spellName then
				t[v][spellName] = true
			end
			t[v][spellID] = true
		end
	else
		-- Otherwise create new table and put spellName with spellID (if possible) for single entrance to keep return @table
		t[v] = {}

		local spellName = GetSpellName(v_type == "string" and not v:find("%D") and toNum[v] or v) -- TMW lua code passing through 'thisobj.Name' @string type
		if spellName then
			t[v][spellName] = true
		end

		t[v][v] = true
	end

	--print("Created associatived table:")
	--print(tostring(v), "  Output:", tostring(t[v]), " Key:", next(t[v]))

	return t[v]
end })

local IsMustBeByID = {
	-- Note: This table holds all spellIDs which must be always query byID since they have shared spellNames but different effects!
	-- Warlock
	[31117] 		= true, 	-- Unstable Affliction (silence after dispel)
	-- Druid
	[163505] 		= true, 	-- Rake (stun from stealth)
	--[231052] 		= true, 	-- Rake (dot) spell -- seems old id which is not valid in BFA
	[155722] 		= true, 	-- Rake (dot)
	[203123] 		= true, 	-- Maim (stun)
	[236025] 		= true, 	-- Enraged Maim (incapacitate)
	[339] 			= true, 	-- Entangling Roots (dispel able)
	[235963] 		= true, 	-- Entangling Roots (NO dispel able)
	-- Death Knight
	[204085] 		= true, 	-- Deathchill (Frost - PvP Roots)
	[207171] 		= true, 	-- Winter is Coming (Frost - Remorseless Winter Stun)
	-- Rogue
	[703] 			= true, 	-- Garroute - Dot
	[1330] 			= true, 	-- Garroute - Silence
	-- Paladin
	--[216411] 		= true, 	-- BUFFS: Holy Shock 	(Divine Purpose)
	--[216413] 		= true, 	-- BUFFS: Light of Down (Divine Purpose)
	-- Priest
	[200200] 		= true, 	-- Holy word: Chastise (Holy stun)
	[200196] 		= true, 	-- Holy Word: Chastise (Holy incapacitate)
	-- Demon Hunter
	[217832]		= true, 	-- Imprison
	[200166]		= true, 	-- Metamorphosis
}

local function IsAuraEqual(spellName, spellID, spellInput, byID)
	-- @return boolean
	if byID then
		if #spellInput > 0 then 				-- ArrayTables
			for i = 1, #spellInput do
				if AuraList[spellInput[i]] then
					for _, auraListID in ipairs(AuraList[spellInput[i]]) do
						if spellID == auraListID then
							return true
						end
					end
				elseif spellID == spellInput[i] then
					return true
				end
			end
		else 									-- AssociativeTables
			return spellInput[spellID]
		end
	else
		if #spellInput > 0 then 				-- ArrayTables
			for i = 1, #spellInput do
				if AuraList[spellInput[i]] then
					for _, auraListID in ipairs(AuraList[spellInput[i]]) do
						if spellName == A_GetSpellInfo(auraListID) then
							return true
						end
					end
				elseif IsMustBeByID[spellInput[i]] then -- Retail only
					if spellID == spellInput[i] then
						return true
					end
				elseif spellName == A_GetSpellInfo(spellInput[i]) then
					return true
				end
			end
		else 									-- AssociativeTables
			return spellInput[spellName]
		end
	end
end

-------------------------------------------------------------------------------
-- API: Core (Action Rotation Conditions)
-------------------------------------------------------------------------------
function A.GetAuraList(key)
	-- @return table
    return AuraList[key]
end

function A.IsUnitFriendly(unitID)
	-- @return boolean
	if unitID == "mouseover" then
		return 	GetToggle(2, unitID) and MouseHasFrame() and not A_Unit(unitID):IsEnemy()
	else
		return 	(
					not GetToggle(2, "mouseover") or
					not A_Unit("mouseover"):IsExists() or
					A_Unit("mouseover"):IsEnemy()
				) and
				not A_Unit(unitID):IsEnemy() and
				A_Unit(unitID):IsExists()
	end
end
A.IsUnitFriendly = A.MakeFunctionCachedDynamic(A.IsUnitFriendly)

function A.IsUnitEnemy(unitID)
	-- @return boolean
	if unitID == "mouseover" then
		return  GetToggle(2, unitID) and A_Unit(unitID):IsEnemy()
	elseif unitID == "focustarget" then
		return 	GetToggle(2, unitID) and
				( not GetToggle(2, "mouseover") or not A_Unit("mouseover"):IsEnemy() ) and
				not A_Unit("target"):IsEnemy() and
				-- Exception to don't pull by mistake mob
				A_Unit(unitID):CombatTime() > 0 and
				A_Unit(unitID):IsEnemy() and
				-- LOS checking
				not UnitInLOS(unitID)
	elseif unitID == "targettarget" then
		return 	GetToggle(2, unitID) and
				( not GetToggle(2, "mouseover") or not A_Unit("mouseover"):IsEnemy() ) and
				( not GetToggle(2, "focustarget") or not A_Unit("focustarget"):IsEnemy() ) and
				not A_Unit("target"):IsEnemy() and
				-- Exception to don't pull by mistake mob
				A_Unit(unitID):CombatTime() > 0 and
				A_Unit(unitID):IsEnemy() and
				-- LOS checking
				not UnitInLOS(unitID)
	else
		return 	( not GetToggle(2, "mouseover") or not MouseHasFrame() ) and A_Unit(unitID):IsEnemy()
	end
end
A.IsUnitEnemy = A.MakeFunctionCachedDynamic(A.IsUnitEnemy)

-------------------------------------------------------------------------------
-- API: Unit
-------------------------------------------------------------------------------
local Info = {
	CacheMoveIn					= setmetatable({}, { __mode = "kv" }),
	CacheMoveOut				= setmetatable({}, { __mode = "kv" }),
	CacheMoving 				= setmetatable({}, { __mode = "kv" }),
	CacheStaying				= setmetatable({}, { __mode = "kv" }),
	CacheInterrupt 				= setmetatable({}, { __mode = "kv" }),
	SpecsWithExecute			= {71, 72},
	SpecsMoonkinRestor			= {102, 105},
	SpecsFeralGuardian			= {103, 104},
	SpecIs 						= {
        ["MELEE"] 				= {251, 252, 577, 103, BuildToC >= 70003 and 255 or nil, 269, 70, 259, 260, 261, 263, 71, 72, 250, 581, 104, 268, 66, 73},
        ["RANGE"] 				= {102, 253, 254, BuildToC < 70003 and 255 or nil, 62, 63, 64, 258, 262, 265, 266, 267},
        ["HEALER"] 				= {105, 270, 65, 256, 257, 264, 1468, 1473},
        ["TANK"] 				= {250, 581, 104, 268, 66, 73},
        ["DAMAGER"] 			= {251, 252, 577, 103, 255, 269, 70, 259, 260, 261, 263, 71, 72, 102, 253, 254, 62, 63, 64, 258, 262, 265, 266, 267, 1467},
    },
	ClassSpecBuffs				= {
		["WARRIOR"] 			= {
			[CONST.WARRIOR_ARMS] = {
				56638, 								-- Taste for Blood
				64976, 								-- Juggernaut
			}, 
			[CONST.WARRIOR_FURY] = 29801, 			-- Rampage
			[CONST.WARRIOR_PROTECTION] = 50227, 	-- Sword and Board
		},
		["PALADIN"]	= {
			[CONST.PALADIN_RETRIBUTION] = 20375,	-- Seal of Command
			[CONST.PALADIN_HOLY] = 31836,			-- Light's Grace
			[CONST.PALADIN_PROTECTION] = 25781,		-- Righteous Fury
		},
		["HUNTER"] = {
			[CONST.HUNTER_BEASTMASTERY] = 20895,	-- Spirit Bond
			[CONST.HUNTER_MARKSMANSHIP] = 19506,	-- Trueshot Aura
		},
		["ROGUE"] = {
			[CONST.ROGUE_SUBTLETY] = {
				36554, 								-- Shadowstep
				31223,								-- Master of Subtlety
			},
			[CONST.ROGUE_OUTLAW] = 51690,			-- Killing Spree
		},
		["PRIEST"] = {
			[CONST.PRIEST_HOLY] = 47788,			-- Guardian Spirit
			[CONST.PRIEST_DISCIPLINE] = 52800,		-- Borrowed Time
			[CONST.PRIEST_SHADOW] = {
				15473, 								-- Shadowform
				15286,								-- Vampiric Embrace
			},
		},
		["SHAMAN"] = {
			[CONST.SHAMAN_ELEMENTAL] = {
				57663,								-- Totem of Wrath
				51470,								-- Elemental Oath
			},
			[CONST.SHAMAN_ENCHANCEMENT] = 30809,	-- Unleashed Rage
			[CONST.SHAMAN_RESTORATION] = 49284,		-- Earth Shield
		},
		["MAGE"] = {
			[CONST.MAGE_FROST] = 43039,				-- Ice Barrier
			[CONST.MAGE_FIRE] = 11129,				-- Combustion
			[CONST.MAGE_ARCANE] = 31583,			-- Arcane Empowerment
		},
		["WARLOCK"] = {
			[CONST.WARLOCK_DESTRUCTION] = 30302,	-- Nether Protection
		},
		["DRUID"] = {
			[CONST.DRUID_BALANCE] = 24907,			-- Moonkin Aura
			[CONST.DRUID_FERAL] = 24932,			-- Leader of the Pack
			[CONST.DRUID_RESTORATION] = 34123,		-- Tree of Life
		},
		["DEATHKNIGHT"] = {
			[CONST.DEATHKNIGHT_UNHOLY] = 49222,		-- Bone Shield
			[CONST.DEATHKNIGHT_FROST] = 55610,		-- Icy Talons
			[CONST.DEATHKNIGHT_BLOOD] = {
				49016,								-- Hysteria
				53138,								-- Abomination's Might
			},
		},
	},
	ClassSpecSpells 			= {
		["WARRIOR"]				= {
			[CONST.WARRIOR_ARMS] = {
				47486,								-- Mortal Strike
				46924,								-- Bladestorm
				56638, 								-- Taste for Blood
				64976, 								-- Juggernaut
			},
			[CONST.WARRIOR_FURY] = {
				23881,								-- Bloodthirst
				29801, 								-- Rampage
			},
			[CONST.WARRIOR_PROTECTION] = {
				47498,								-- Devastate
				50227, 								-- Sword and Board
			},
		},
		["PALADIN"]	= {
			[CONST.PALADIN_RETRIBUTION] = {
				35395,								-- Crusader Strike
				53385,								-- Divine Storm
				20066,								-- Repentance
				20375,								-- Seal of Command
			}, 
			[CONST.PALADIN_HOLY] = {
				48825,								-- Holy Shock
				31836,								-- Light's Grace
			},
			[CONST.PALADIN_PROTECTION] = 48827,		-- Avenger's Shield
		},
		["HUNTER"] = {
			[CONST.HUNTER_BEASTMASTERY] = {
				19577,								-- Intimidation
				20895,								-- Spirit Bond
			},
			[CONST.HUNTER_MARKSMANSHIP] = {
				34490,								-- Silencing Shot
				53209,								-- Chimera Shot
				19506,								-- Trueshot Aura
			},
			[CONST.HUNTER_SURVIVAL] = {
				60053,								-- Explosive Shot
			},
		},
		["ROGUE"] = {
			[CONST.ROGUE_ASSASSINATION] = 48666,	-- Mutilate
			[CONST.ROGUE_OUTLAW] = {
				51690, 								-- Killing Spree
				13877,								-- Blade Flurry
				13750,								-- Adrenaline Rush
			},
			[CONST.ROGUE_SUBTLETY] = {
				48660,								-- Hemorrhage
				36554, 								-- Shadowstep
				31223,								-- Master of Subtlety
			},
		},
		["PRIEST"] = {
			[CONST.PRIEST_HOLY] = {
				34861,								-- Circle of Healing
				47788,								-- Guardian Spirit
			},
			[CONST.PRIEST_DISCIPLINE] = {
				33206,								-- Pain Suppression
				10060,								-- Power Infusion
				53007,								-- Penance
				52800,								-- Borrowed Time
			},
			[CONST.PRIEST_SHADOW] = {
				15473, 								-- Shadowform
				15286,								-- Vampiric Embrace
				15487,								-- Silence
				48160,								-- Vampiric Touch
			},
		},
		["SHAMAN"] = {
			[CONST.SHAMAN_ELEMENTAL] = {
				57663,								-- Totem of Wrath
				51470,								-- Elemental Oath
				59159,								-- Thunderstorm
				16166,								-- Elemental Mastery
			},
			[CONST.SHAMAN_ENCHANCEMENT] = {
				30809,								-- Unleashed Rage
				51533,								-- Feral Spirit
				30823,								-- Shamanistic Rage
				17364,								-- Stormstrike
			},
			[CONST.SHAMAN_RESTORATION] = {
				49284,								-- Earth Shield
				61301,								-- Riptide
				51886,								-- Cleanse Spirit
			},
		},
		["MAGE"] = {
			[CONST.MAGE_FROST] = {
				43039,								-- Ice Barrier
				44572,								-- Deep Freeze
			},
			[CONST.MAGE_FIRE] = {
				11129,								-- Combustion
				42945,								-- Blast Wave
				42950,								-- Dragon's Breath
				55360,								-- Living Bomb
			},
			[CONST.MAGE_ARCANE] = {
				31583,								-- Arcane Empowerment
				44781,								-- Arcane Barrage
			},
		},
		["WARLOCK"] = {
			[CONST.WARLOCK_AFFLICTION] = {
				59164,								-- Haunt
				47843,								-- Unstable Affliction
			},
			[CONST.WARLOCK_DEMONOLOGY] = 59672,		-- Metamorphosis
			[CONST.WARLOCK_DESTRUCTION] = {
				30302,								-- Nether Protection
				59172,								-- Chaos Bolt
				47847,								-- Shadowfury
			},
		},
		["DRUID"] = {
			[CONST.DRUID_BALANCE] = {
				24907,								-- Moonkin Aura
				53201,								-- Starfall
				61384,								-- Typhoon
			},
			[CONST.DRUID_FERAL] = {
				24932,								-- Leader of the Pack
				48566,								-- Mangle (Cat)
				48564,								-- Mangle (Bear)
			},
			[CONST.DRUID_RESTORATION] = {
				34123,								-- Tree of Life
				18562,								-- Swiftmend
			},
		},
		["DEATHKNIGHT"] = {
			[CONST.DEATHKNIGHT_UNHOLY] = {
				49222,								-- Bone Shield
				55271,								-- Scourge Strike
			},
			[CONST.DEATHKNIGHT_FROST] = {
				55610,								-- Icy Talons
				55268,								-- Frost Strike
				51411,								-- Howling Blast
				49203,								-- Hungering Cold
			},
			[CONST.DEATHKNIGHT_BLOOD] = {
				49016,								-- Hysteria
				53138,								-- Abomination's Might
				55262,								-- Heart Strike
			},
		},
	},
	ClassIsMelee = {
        ["WARRIOR"] 			= true,
        ["PALADIN"] 			= true,
        ["HUNTER"] 				= false,
        ["ROGUE"] 				= true,
        ["PRIEST"] 				= false,
        ["DEATHKNIGHT"] 		= true,
        ["SHAMAN"] 				= false,
        ["MAGE"] 				= false,
        ["WARLOCK"] 			= false,
        ["MONK"] 				= true,
        ["DRUID"] 				= false,
        ["DEMONHUNTER"] 		= true,
    },
	ClassCanBeHealer			= {
		["PALADIN"] 			= true,
		["PRIEST"]				= true,
		["SHAMAN"] 				= true,
		["DRUID"] 				= true,
		["MONK"]				= true,
		["EVOKER"]				= true,
	},
	ClassCanBeTank				= {
        ["WARRIOR"] 			= 71,						-- Defensive Stance
        ["PALADIN"] 			= 25781, 					-- Righteous Fury
        ["DRUID"] 				= {5487, 9634},				-- Bear Form, Dire Bear Form
		["MONK"]				= true,
		["SHAMAN"]				= BuildToC < 30000, 		-- T3 tank in Classic/TBC possible 
		["DEMONHUNTER"]			= true,
		["DEATHKNIGHT"]			= 48263,					-- Blood Presence		
	},
	ClassCanBeMelee				= {
        ["WARRIOR"] 			= true,
        ["PALADIN"] 			= true,
		["HUNTER"]				= BuildToC >= 70003,
        ["ROGUE"] 				= true,
        ["SHAMAN"] 				= true,
        ["DRUID"] 				= true,
		["MONK"]				= true,
		["DEMONHUNTER"]			= true,
		["DEATHKNIGHT"]			= true,
	},
	AllCC 						= {"Silenced", "Stuned", "Sleep", "Fear", "Disoriented", "Incapacitated"},
	CreatureType				= setmetatable(
		-- Formats localization to English locale
		-- Revision BFA 8.3.0.33941 April 2020
		{
			enUS				= {
				["Beast"]				= "Beast",				-- [1]
				["Dragonkin"]			= "Dragonkin",			-- [2]
				["Demon"]				= "Demon",				-- [3]
				["Elemental"]			= "Elemental",			-- [4]
				["Giant"]				= "Giant",				-- [5]
				["Undead"]				= "Undead",				-- [6]
				["Humanoid"]			= "Humanoid",			-- [7]
				["Critter"]				= "Critter",			-- [8]
				["Mechanical"]			= "Mechanical",			-- [9]
				["Not specified"]		= "Not specified",		-- [10]
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["Totem"]				= "Totem",				-- [11]
				["Non-combat Pet"]		= "Non-combat Pet",		-- [12]
				["Gas Cloud"]			= "Gas Cloud",			-- [13]
				["Wild Pet"]			= "Wild Pet",			-- [14]
				["Aberration"]			= "Aberration",			-- [15]
			},
			ruRU				= {
				["Животное"]			= "Beast",				-- [1]
				["Дракон"]				= "Dragonkin",			-- [2]
				["Демон"]				= "Demon",				-- [3]
				["Элементаль"]			= "Elemental",			-- [4]
				["Великан"]				= "Giant",				-- [5]
				["Нежить"]				= "Undead",				-- [6]
				["Гуманоид"]			= "Humanoid",			-- [7]
				["Существо"]			= "Critter",			-- [8]
				["Механизм"]			= "Mechanical",			-- [9]
				["Не указано"]			= "Not specified",		-- [10]
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["Тотем"]				= "Totem",				-- [11]
				["Спутник"]				= "Non-combat Pet",		-- [12]
				["Облако газа"]			= "Gas Cloud",			-- [13]
				["Дикий питомец"]		= "Wild Pet",			-- [14]
				["Аберрация"]			= "Aberration",			-- [15]
			},
			frFR				= {
				["Bête"]				= "Beast",				-- [1]
				["Draconien"]			= "Dragonkin",			-- [2]
				["Démon"]				= "Demon",				-- [3]
				["Élémentaire"]			= "Elemental",			-- [4]
				["Géant"]				= "Giant",				-- [5]
				["Mort-vivant"]			= "Undead",				-- [6]
				["Humanoïde"]			= "Humanoid",			-- [7]
				["Bestiole"]			= "Critter",			-- [8]
				["Mécanique"]			= "Mechanical",			-- [9] -- Classic
				["Machine"]				= "Mechanical",			-- [9] -- Retail
				["Non spécifié"]		= "Not specified",		-- [10]
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["Totem"]				= "Totem",				-- [11]
				["Mascotte pacifique"]	= "Non-combat Pet",		-- [12]
				["Nuage de gaz"]		= "Gas Cloud",			-- [13]
				["Mascotte sauvage"]	= "Wild Pet",			-- [14]
				["Aberration"]			= "Aberration",			-- [15]
			},
			deDE				= {
				["Wildtier"]			= "Beast",				-- [1]
				["Drachkin"]			= "Dragonkin",			-- [2]
				["Dämon"]				= "Demon",				-- [3]
				["Elementar"]			= "Elemental",			-- [4]
				["Riese"]				= "Giant",				-- [5]
				["Untoter"]				= "Undead",				-- [6]
				["Humanoid"]			= "Humanoid",			-- [7]
				["Tier"]				= "Critter",			-- [8] -- Classic
				["Kleintier"]			= "Critter",			-- [8] -- Retail
				["Mechanisch"]			= "Mechanical",			-- [9]
				["Nicht spezifiziert"]	= "Not specified",		-- [10]
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["Totem"]				= "Totem",				-- [11]
				["Haustier"]			= "Non-combat Pet",		-- [12]
				["Gaswolke"]			= "Gas Cloud",			-- [13]
				["Ungezähmtes Tier"]	= "Wild Pet",			-- [14]
				["Entartung"]			= "Aberration",			-- [15]
			},
			esES				= {
				["Bestia"]				= "Beast",				-- [1]
				["Dragonante"]			= "Dragonkin",			-- [2]
				["Demonio"]				= "Demon",				-- [3]
				["Elemental"]			= "Elemental",			-- [4]
				["Gigante"]				= "Giant",				-- [5]
				["No-muerto"]			= "Undead",				-- [6]
				["Humanoide"]			= "Humanoid",			-- [7]
				["Alimaña"]				= "Critter",			-- [8]
				["Mecánico"]			= "Mechanical",			-- [9]
				["Sin especificar"]		= "Not specified",		-- [10]
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["Tótem"]				= "Totem",				-- [11]
				["Mascota mansa"]		= "Non-combat Pet",		-- [12]
				["Nube de gas"]			= "Gas Cloud",			-- [13]
				["Mascota salvaje"]		= "Wild Pet",			-- [14]
				["Aberración"]			= "Aberration",			-- [15]
			},
			ptPT				= {
				["Fera"]				= "Beast",				-- [1]
				["Draconiano"]			= "Dragonkin",			-- [2]
				["Demônio"]				= "Demon",				-- [3]
				["Elemental"]			= "Elemental",			-- [4]
				["Gigante"]				= "Giant",				-- [5]
				["Morto-vivo"]			= "Undead",				-- [6]
				["Humanoide"]			= "Humanoid",			-- [7]
				["Bicho"]				= "Critter",			-- [8]
				["Mecânico"]			= "Mechanical",			-- [9]
				["Não Especificado"]	= "Not specified",		-- [10]
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["Totem"]				= "Totem",				-- [11]
				["Mascote"]				= "Non-combat Pet",		-- [12]
				["Nuvem de Gás"]		= "Gas Cloud",			-- [13]
				["Mascote Selvagem"]	= "Wild Pet",			-- [14]
				["Aberração"]			= "Aberration",			-- [15]
			},
			itIT				= {
				["Bestia"]				= "Beast",				-- [1]
				["Dragoide"]			= "Dragonkin",			-- [2]
				["Demone"]				= "Demon",				-- [3]
				["Elementale"]			= "Elemental",			-- [4]
				["Gigante"]				= "Giant",				-- [5]
				["Non Morto"]			= "Undead",				-- [6]
				["Umanoide"]			= "Humanoid",			-- [7]
				["Animale"]				= "Critter",			-- [8]
				["Unità Meccanica"]		= "Mechanical",			-- [9]
				["Non Specificato"]		= "Not specified",		-- [10]
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["Totem"]				= "Totem",				-- [11]
				["Mascotte"]			= "Non-combat Pet",		-- [12]
				["Nuvola di Gas"]		= "Gas Cloud",			-- [13]
				["Mascotte Selvatica"]	= "Wild Pet",			-- [14]
				["Aberrazione"]			= "Aberration",			-- [15]
			},
			koKR				= {
				["야수"]					= "Beast",				-- [1]
				["용족"]					= "Dragonkin",			-- [2]
				["악마"]					= "Demon",				-- [3]
				["정령"]					= "Elemental",			-- [4]
				["거인"]					= "Giant",				-- [5]
				["언데드"]					= "Undead",				-- [6]
				["인간형"]					= "Humanoid",			-- [7]
				["동물"]					= "Critter",			-- [8]
				["기계"]					= "Mechanical",			-- [9]
				["기타"]					= "Not specified",		-- [10]
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["토템"]					= "Totem",				-- [11]
				["애완동물"]				= "Non-combat Pet",		-- [12]
				["가스 구름"]				= "Gas Cloud",			-- [13]
				["야생 애완동물"]			= "Wild Pet",			-- [14]
				["돌연변이"]				= "Aberration",			-- [15]
			},
			zhCN				= {
				["野兽"]				= "Beast",				-- [1]
				["龙类"]					= "Dragonkin",			-- [2]
				["恶魔"]				= "Demon",				-- [3]
				["元素生物"]				= "Elemental",			-- [4]
				["巨人"]				= "Giant",				-- [5]
				["亡灵"]				= "Undead",				-- [6]
				["人型生物"]				= "Humanoid",			-- [7]
				["小动物"]				= "Critter",			-- [8]
				["机械"]				= "Mechanical",			-- [9]
				["未指定"]				= "Not specified",		-- [10]
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["图腾"]				= "Totem",				-- [11]
				["非战斗宠物"]			= "Non-combat Pet",		-- [12]
				["气体云雾"]				= "Gas Cloud",			-- [13]
				["野生宠物"]				= "Wild Pet",			-- [14]
				["畸变怪"]				= "Aberration",			-- [15]
			},
			zhTW				= {
				["野獸"]				= "Beast",				-- [1]
				["龍類"]				= "Dragonkin",			-- [2]
				["惡魔"]				= "Demon",				-- [3]
				["元素生物"]				= "Elemental",			-- [4]
				["巨人"]				= "Giant",				-- [5]
				["不死族"]				= "Undead",				-- [6]
				["人型生物"]				= "Humanoid",			-- [7] Classic
				["人形生物"]				= "Humanoid",			-- [7] Retail
				["小動物"]				= "Critter",			-- [8]
				["機械"]				= "Mechanical",			-- [9]
				["未指定"]				= "Not specified",		-- [10] Classic
				["不明"]				= "Not specified",		-- [10] Retail
				[""]					= "Not specified",		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
				["圖騰"]				= "Totem",				-- [11]
				["非戰鬥寵物"]			= "Non-combat Pet",		-- [12]
				["氣體雲"]				= "Gas Cloud",			-- [13]
				["野生寵物"]				= "Wild Pet",			-- [14]
				["變異怪"]				= "Aberration",			-- [15]
			},
		},
		{
			__index = function(t, v)
				return t[GameLocale][v]
			end,
		}
	),
	CreatureFamily				= setmetatable(
		-- Formats localization to English locale
		-- Revision BFA 8.3.0.33941 April 2020
		{
			enUS				= {
				["Wolf"]					= "Wolf",					-- [1]
				["Cat"]						= "Cat",					-- [2]
				["Spider"]					= "Spider",					-- [3]
				["Bear"]					= "Bear",					-- [4]
				["Boar"]					= "Boar",					-- [5]
				["Crocolisk"]				= "Crocolisk",				-- [6]
				["Carrion Bird"]			= "Carrion Bird",			-- [7]
				["Crab"]					= "Crab",					-- [8]
				["Gorilla"]					= "Gorilla",				-- [9]
				["Raptor"]					= "Raptor",					-- [11]
				["Tallstrider"]				= "Tallstrider",			-- [12]
				["Felhunter"]				= "Felhunter",				-- [15]
				["Voidwalker"]				= "Voidwalker",				-- [16]
				["Succubus"]				= "Succubus",				-- [17]
				["Doomguard"]				= "Doomguard",				-- [19]
				["Scorpid"]					= "Scorpid",				-- [20]
				["Turtle"]					= "Turtle",					-- [21]
				["Imp"]						= "Imp",					-- [23]
				["Bat"]						= "Bat",					-- [24]
				["Hyena"]					= "Hyena",					-- [25]
				["Owl"]						= "Owl",					-- [26] Classic
				["Bird of Prey"]			= "Bird of Prey",			-- [26] Retail
				["Wind Serpent"]			= "Wind Serpent",			-- [27]
				["Remote Control"]			= "Remote Control",			-- [28]
				["Felguard"]				= "Felguard",				-- [29]
				["Dragonhawk"]				= "Dragonhawk",				-- [30]
				["Ravager"]					= "Ravager",				-- [31]
				["Warp Stalker"]			= "Warp Stalker",			-- [32]
				["Sporebat"]				= "Sporebat",				-- [33]
				["Ray"]						= "Ray",					-- [34]
				["Serpent"]					= "Serpent",				-- [35]
				["Moth"]					= "Moth",					-- [37]
				["Chimaera"]				= "Chimaera",				-- [38]
				["Devilsaur"]				= "Devilsaur",				-- [39]
				["Ghoul"]					= "Ghoul",					-- [40]
				["Silithid"]				= "Silithid",				-- [41]
				["Worm"]					= "Worm",					-- [42]
				["Clefthoof"]				= "Clefthoof",				-- [43]
				["Wasp"]					= "Wasp",					-- [44]
				["Core Hound"]				= "Core Hound",				-- [45]
				["Spirit Beast"]			= "Spirit Beast",			-- [46]
				["Water Elemental"]			= "Water Elemental",		-- [49]
				["Fox"]						= "Fox",					-- [50]
				["Monkey"]					= "Monkey",					-- [51]
				["Dog"]						= "Dog",					-- [52]
				["Beetle"]					= "Beetle",					-- [53]
				["Shale Spider"]			= "Shale Spider",			-- [55]
				["Zombie"]					= "Zombie",					-- [56]
				["<< QA TEST FAMILY >>"]	= "<< QA TEST FAMILY >>",	-- [57]
				["Hydra"]					= "Hydra",					-- [68]
				["Fel Imp"]					= "Fel Imp",				-- [100]
				["Voidlord"]				= "Voidlord",				-- [101]
				["Shivarra"]				= "Shivarra",				-- [102]
				["Observer"]				= "Observer",				-- [103]
				["Wrathguard"]				= "Wrathguard",				-- [104]
				["Infernal"]				= "Infernal",				-- [108]
				["Fire Elemental"]			= "Fire Elemental",			-- [116]
				["Earth Elemental"]			= "Earth Elemental",		-- [117]
				["Crane"]					= "Crane",					-- [125]
				["Water Strider"]			= "Water Strider",			-- [126]
				["Rodent"]					= "Rodent",					-- [127]
				["Quilen"]					= "Quilen",					-- [128]
				["Goat"]					= "Goat",					-- [129]
				["Basilisk"]				= "Basilisk",				-- [130]
				["Direhorn"]				= "Direhorn",				-- [138]
				["Storm Elemental"]			= "Storm Elemental",		-- [145]
				["Terrorguard"]				= "Terrorguard",			-- [147]
				["Abyssal"]					= "Abyssal",				-- [148]
				["Riverbeast"]				= "Riverbeast",				-- [150]
				["Stag"]					= "Stag",					-- [151]
				["Mechanical"]				= "Mechanical",				-- [154]
				["Abomination"]				= "Abomination",			-- [155]
				["Scalehide"]				= "Scalehide",				-- [156]
				["Oxen"]					= "Oxen",					-- [157]
				["Feathermane"]				= "Feathermane",			-- [160]
				["Lizard"]					= "Lizard",					-- [288]
				["Pterrordax"]				= "Pterrordax",				-- [290]
				["Toad"]					= "Toad",					-- [291]
				["Krolusk"]					= "Krolusk",				-- [292]
				["Blood Beast"]				= "Blood Beast",			-- [296]
			},
			ruRU				= {
				["Волк"]					= "Wolf",					-- [1]
				["Кошка"]					= "Cat",					-- [2]
				["Паук"]					= "Spider",					-- [3]
				["Медведь"]					= "Bear",					-- [4]
				["Вепрь"]					= "Boar",					-- [5]
				["Кроколиск"]				= "Crocolisk",				-- [6]
				["Падальщик"]				= "Carrion Bird",			-- [7]
				["Краб"]					= "Crab",					-- [8]
				["Горилла"]					= "Gorilla",				-- [9]
				["Ящер"]					= "Raptor",					-- [11]
				["Долгоног"]				= "Tallstrider",			-- [12]
				["Охотник Скверны"]			= "Felhunter",				-- [15]
				["Демон Бездны"]			= "Voidwalker",				-- [16]
				["Суккуб"]					= "Succubus",				-- [17]
				["Страж ужаса"]				= "Doomguard",				-- [19]
				["Скорпид"]					= "Scorpid",				-- [20]
				["Черепаха"]				= "Turtle",					-- [21]
				["Бес"]						= "Imp",					-- [23]
				["Летучая мышь"]			= "Bat",					-- [24]
				["Гиена"]					= "Hyena",					-- [25]
				["Сова"]					= "Owl",					-- [26] Classic
				["Хищная птица"]			= "Bird of Prey",			-- [26] Retail
				["Крылатый змей"]			= "Wind Serpent",			-- [27]
				["Управление"]				= "Remote Control",			-- [28]
				["Страж Скверны"]			= "Felguard",				-- [29]
				["Дракондор"]				= "Dragonhawk",				-- [30]
				["Опустошитель"]			= "Ravager",				-- [31]
				["Прыгуана"]				= "Warp Stalker",			-- [32]
				["Спороскат"]				= "Sporebat",				-- [33]
				["Скат"]					= "Ray",					-- [34]
				["Змей"]					= "Serpent",				-- [35]
				["Мотылек"]					= "Moth",					-- [37]
				["Химера"]					= "Chimaera",				-- [38]
				["Дьявозавр"]				= "Devilsaur",				-- [39]
				["Вурдалак"]				= "Ghoul",					-- [40]
				["Силитид"]					= "Silithid",				-- [41]
				["Червь"]					= "Worm",					-- [42]
				["Копытень"]				= "Clefthoof",				-- [43]
				["Оса"]						= "Wasp",					-- [44]
				["Гончая недр"]				= "Core Hound",				-- [45]
				["Дух зверя"]				= "Spirit Beast",			-- [46]
				["Элементаль воды"]			= "Water Elemental",		-- [49]
				["Лисица"]					= "Fox",					-- [50]
				["Обезьяна"]				= "Monkey",					-- [51]
				["Собака"]					= "Dog",					-- [52]
				["Жук"]						= "Beetle",					-- [53]
				["Сланцевый паук"]			= "Shale Spider",			-- [55]
				["Зомби"]					= "Zombie",					-- [56]
				["<< QA TEST FAMILY >>"]	= "<< QA TEST FAMILY >>",	-- [57]
				["Гидра"]					= "Hydra",					-- [68]
				["Бес Скверны"]				= "Fel Imp",				-- [100]
				["Повелитель Бездны"]		= "Voidlord",				-- [101]
				["Шиварра"]					= "Shivarra",				-- [102]
				["Наблюдатель"]				= "Observer",				-- [103]
				["Страж гнева"]				= "Wrathguard",				-- [104]
				["Инфернал"]				= "Infernal",				-- [108]
				["Элементаль огня"]			= "Fire Elemental",			-- [116]
				["Элементаль земли"]		= "Earth Elemental",		-- [117]
				["Журавль"]					= "Crane",					-- [125]
				["Водный долгоног"]			= "Water Strider",			-- [126]
				["Грызун"]					= "Rodent",					-- [127]
				["Цийлинь"]					= "Quilen",					-- [128]
				["Козел"]					= "Goat",					-- [129]
				["Василиск"]				= "Basilisk",				-- [130]
				["Дикорог"]					= "Direhorn",				-- [138]
				["Элементаль бури"]			= "Storm Elemental",		-- [145]
				["Стражник жути"]			= "Terrorguard",			-- [147]
				["Абиссал"]					= "Abyssal",				-- [148]
				["Речное чудище"]			= "Riverbeast",				-- [150]
				["Олень"]					= "Stag",					-- [151]
				["Механизм"]				= "Mechanical",				-- [154]
				["Поганище"]				= "Abomination",			-- [155]
				["Чешуешкурые"]				= "Scalehide",				-- [156]
				["Быки"]					= "Oxen",					-- [157]
				["Шерстоперые"]				= "Feathermane",			-- [160]
				["Ящерица"]					= "Lizard",					-- [288]
				["Терродактиль"]			= "Pterrordax",				-- [290]
				["Жаба"]					= "Toad",					-- [291]
				["Кролуск"]					= "Krolusk",				-- [292]
				["Кровавое чудовище"]		= "Blood Beast",			-- [296]
			},
			frFR				= {
				["Loup"]					= "Wolf",					-- [1]
				["Félin"]					= "Cat",					-- [2]
				["Araignée"]				= "Spider",					-- [3]
				["Ours"]					= "Bear",					-- [4]
				["Sanglier"]				= "Boar",					-- [5]
				["Crocilisque"]				= "Crocolisk",				-- [6]
				["Charognard"]				= "Carrion Bird",			-- [7]
				["Crabe"]					= "Crab",					-- [8]
				["Gorille"]					= "Gorilla",				-- [9]
				["Raptor"]					= "Raptor",					-- [11]
				["Haut-trotteur"]			= "Tallstrider",			-- [12]
				["Chasseur corrompu"]		= "Felhunter",				-- [15]
				["Marcheur du Vide"]		= "Voidwalker",				-- [16]
				["Succube"]					= "Succubus",				-- [17]
				["Garde funeste"]			= "Doomguard",				-- [19]
				["Scorpide"]				= "Scorpid",				-- [20]
				["Tortue"]					= "Turtle",					-- [21]
				["Diablotin"]				= "Imp",					-- [23]
				["Chauve-souris"]			= "Bat",					-- [24]
				["Hyène"]					= "Hyena",					-- [25]
				["Chouette"]				= "Owl",					-- [26] Classic
				["Oiseau de proie"]			= "Bird of Prey",			-- [26] Retail
				["Serpent des vents"]		= "Wind Serpent",			-- [27]
				["Télécommande"]			= "Remote Control",			-- [28]
				["Gangregarde"]				= "Felguard",				-- [29]
				["Faucon-dragon"]			= "Dragonhawk",				-- [30]
				["Ravageur"]				= "Ravager",				-- [31]
				["Traqueur dim."]			= "Warp Stalker",			-- [32]
				["Sporoptère"]				= "Sporebat",				-- [33]
				["Raie"]					= "Ray",					-- [34]
				["Serpent"]					= "Serpent",				-- [35]
				["Phalène"]					= "Moth",					-- [37]
				["Chimère"]					= "Chimaera",				-- [38]
				["Diablosaure"]				= "Devilsaur",				-- [39]
				["Goule"]					= "Ghoul",					-- [40]
				["Silithide"]				= "Silithid",				-- [41]
				["Ver"]						= "Worm",					-- [42]
				["Sabot-fourchu"]			= "Clefthoof",				-- [43]
				["Guêpe"]					= "Wasp",					-- [44]
				["Chien du magma"]			= "Core Hound",				-- [45]
				["Esprit de bête"]			= "Spirit Beast",			-- [46]
				["Élémentaire d'eau"]		= "Water Elemental",		-- [49]
				["Renard"]					= "Fox",					-- [50]
				["Singe"]					= "Monkey",					-- [51]
				["Chien"]					= "Dog",					-- [52]
				["Hanneton"]				= "Beetle",					-- [53]
				["Araignée de schiste"]		= "Shale Spider",			-- [55]
				["Zombie"]					= "Zombie",					-- [56]
				["<< QA TEST FAMILY >>"]	= "<< QA TEST FAMILY >>",	-- [57]
				["Hydre"]					= "Hydra",					-- [68]
				["Diablotin gangrené"]		= "Fel Imp",				-- [100]
				["Seigneur du Vide"]		= "Voidlord",				-- [101]
				["Shivarra"]				= "Shivarra",				-- [102]
				["Observateur"]				= "Observer",				-- [103]
				["Garde-courroux"]			= "Wrathguard",				-- [104]
				["Infernal"]				= "Infernal",				-- [108]
				["Élémentaire de feu"]		= "Fire Elemental",			-- [116]
				["Élémentaire de terre"]	= "Earth Elemental",		-- [117]
				["Grue"]					= "Crane",					-- [125]
				["Trotteur aquatique"]		= "Water Strider",			-- [126]
				["Rongeur"]					= "Rodent",					-- [127]
				["Quilen"]					= "Quilen",					-- [128]
				["Chèvre"]					= "Goat",					-- [129]
				["Basilic"]					= "Basilisk",				-- [130]
				["Navrecorne"]				= "Direhorn",				-- [138]
				["Élém. de tempête"]		= "Storm Elemental",		-- [145]
				["Garde de terreur"]		= "Terrorguard",			-- [147]
				["Abyssal"]					= "Abyssal",				-- [148]
				["Potamodonte"]				= "Riverbeast",				-- [150]
				["Cerf"]					= "Stag",					-- [151]
				["Mécanique"]				= "Mechanical",				-- [154]
				["Abomination"]				= "Abomination",			-- [155]
				["Peau écailleuse"]			= "Scalehide",				-- [156]
				["Bovin"]					= "Oxen",					-- [157]
				["Crin-de-plume"]			= "Feathermane",			-- [160]
				["Lézard"]					= "Lizard",					-- [288]
				["Pterreurdactyle"]			= "Pterrordax",				-- [290]
				["Crapaud"]					= "Toad",					-- [291]
				["Krolusk"]					= "Krolusk",				-- [292]
				["Bête de sang"]			= "Blood Beast",			-- [296]
			},
			deDE				= {
				["Wolf"]					= "Wolf",					-- [1]
				["Katze"]					= "Cat",					-- [2]
				["Spinne"]					= "Spider",					-- [3]
				["Bär"]						= "Bear",					-- [4]
				["Eber"]					= "Boar",					-- [5]
				["Krokilisk"]				= "Crocolisk",				-- [6]
				["Aasvogel"]				= "Carrion Bird",			-- [7]
				["Krebs"]					= "Crab",					-- [8]
				["Gorilla"]					= "Gorilla",				-- [9]
				["Raptor"]					= "Raptor",					-- [11]
				["Weitschreiter"]			= "Tallstrider",			-- [12]
				["Teufelsjäger"]			= "Felhunter",				-- [15]
				["Leerwandler"]				= "Voidwalker",				-- [16]
				["Sukkubus"]				= "Succubus",				-- [17]
				["Verdammniswache"]			= "Doomguard",				-- [19]
				["Skorpid"]					= "Scorpid",				-- [20]
				["Schildkröte"]				= "Turtle",					-- [21]
				["Wichtel"]					= "Imp",					-- [23]
				["Fledermaus"]				= "Bat",					-- [24]
				["Hyäne"]					= "Hyena",					-- [25]
				["Eule"]					= "Owl",					-- [26] Classic
				["Raubvogel"]				= "Bird of Prey",			-- [26] Retail
				["Windnatter"]				= "Wind Serpent",			-- [27]
				["Ferngesteuert"]			= "Remote Control",			-- [28]
				["Teufelswache"]			= "Felguard",				-- [29]
				["Drachenfalke"]			= "Dragonhawk",				-- [30]
				["Felshetzer"]				= "Ravager",				-- [31]
				["Sphärenjäger"]			= "Warp Stalker",			-- [32]
				["Sporensegler"]			= "Sporebat",				-- [33]
				["Rochen"]					= "Ray",					-- [34]
				["Schlange"]				= "Serpent",				-- [35]
				["Motte"]					= "Moth",					-- [37]
				["Schimäre"]				= "Chimaera",				-- [38]
				["Teufelssaurier"]			= "Devilsaur",				-- [39]
				["Ghul"]					= "Ghoul",					-- [40]
				["Silithid"]				= "Silithid",				-- [41]
				["Wurm"]					= "Worm",					-- [42]
				["Grollhuf"]				= "Clefthoof",				-- [43]
				["Wespe"]					= "Wasp",					-- [44]
				["Kernhund"]				= "Core Hound",				-- [45]
				["Geisterbestie"]			= "Spirit Beast",			-- [46]
				["Wasserelementar"]			= "Water Elemental",		-- [49]
				["Fuchs"]					= "Fox",					-- [50]
				["Affe"]					= "Monkey",					-- [51]
				["Hund"]					= "Dog",					-- [52]
				["Käfer"]					= "Beetle",					-- [53]
				["Schieferspinne"]			= "Shale Spider",			-- [55]
				["Zombie"]					= "Zombie",					-- [56]
				["<< QA TEST FAMILY >>"]	= "<< QA TEST FAMILY >>",	-- [57]
				["Hydra"]					= "Hydra",					-- [68]
				["Teufelswichtel"]			= "Fel Imp",				-- [100]
				["Leerenfürst"]				= "Voidlord",				-- [101]
				["Shivarra"]				= "Shivarra",				-- [102]
				["Beobachter"]				= "Observer",				-- [103]
				["Zornwächter"]				= "Wrathguard",				-- [104]
				["Höllenbestie"]			= "Infernal",				-- [108]
				["Feuerelementar"]			= "Fire Elemental",			-- [116]
				["Erdelementar"]			= "Earth Elemental",		-- [117]
				["Kranich"]					= "Crane",					-- [125]
				["Wasserschreiter"]			= "Water Strider",			-- [126]
				["Nager"]					= "Rodent",					-- [127]
				["Qilen"]					= "Quilen",					-- [128]
				["Ziege"]					= "Goat",					-- [129]
				["Basilisk"]				= "Basilisk",				-- [130]
				["Terrorhorn"]				= "Direhorn",				-- [138]
				["Sturmelementar"]			= "Storm Elemental",		-- [145]
				["Terrorwache"]				= "Terrorguard",			-- [147]
				["Abyssal"]					= "Abyssal",				-- [148]
				["Flussbestie"]				= "Riverbeast",				-- [150]
				["Hirsch"]					= "Stag",					-- [151]
				["Mechanisch"]				= "Mechanical",				-- [154]
				["Monstrosität"]			= "Abomination",			-- [155]
				["Schuppenbalg"]			= "Scalehide",				-- [156]
				["Ochse"]					= "Oxen",					-- [157]
				["Federmähnen"]				= "Feathermane",			-- [160]
				["Echse"]					= "Lizard",					-- [288]
				["Pterrordax"]				= "Pterrordax",				-- [290]
				["Kröte"]					= "Toad",					-- [291]
				["Krolusk"]					= "Krolusk",				-- [292]
				["Blutbestie"]				= "Blood Beast",			-- [296]
			},
			esES				= {
				["Lobo"]					= "Wolf",					-- [1]
				["Felino"]					= "Cat",					-- [2]
				["Araña"]					= "Spider",					-- [3]
				["Oso"]						= "Bear",					-- [4]
				["Jabalí"]					= "Boar",					-- [5]
				["Crocolisco"]				= "Crocolisk",				-- [6]
				["Carroñero"]				= "Carrion Bird",			-- [7]
				["Cangrejo"]				= "Crab",					-- [8]
				["Gorila"]					= "Gorilla",				-- [9]
				["Raptor"]					= "Raptor",					-- [11]
				["Zancudo"]					= "Tallstrider",			-- [12] Spain Classic
				["Zancaalta"]				= "Tallstrider",			-- [12] Spain Retail / Mexico Classic
				["Manáfago"]				= "Felhunter",				-- [15]
				["Abisario"]				= "Voidwalker",				-- [16]
				["Súcubo"]					= "Succubus",				-- [17]
				["Guardia maldito"]			= "Doomguard",				-- [19] Spain Classic
				["Guardia apocalíptico"]	= "Doomguard",				-- [19] Spain Retail / Mexico Classic
				["Escórpido"]				= "Scorpid",				-- [20]
				["Tortuga"]					= "Turtle",					-- [21]
				["Diablillo"]				= "Imp",					-- [23]
				["Murciélago"]				= "Bat",					-- [24]
				["Hiena"]					= "Hyena",					-- [25]
				["Búho"]					= "Owl",					-- [26] Classic
				["Ave rapaz"]				= "Bird of Prey",			-- [26] Retail
				["Dragón alado"]			= "Wind Serpent",			-- [27] Spain
				["Serpiente alada"]			= "Wind Serpent",			-- [27] Mexico
				["Control remoto"]			= "Remote Control",			-- [28]
				["Guardia vil"]				= "Felguard",				-- [29]
				["Dracohalcón"]				= "Dragonhawk",				-- [30]
				["Devastador"]				= "Ravager",				-- [31]
				["Acechador deformado"]		= "Warp Stalker",			-- [32]
				["Esporiélago"]				= "Sporebat",				-- [33]
				["Raya"]					= "Ray",					-- [34] Spain
				["Mantarraya"]				= "Ray",					-- [34] Mexico
				["Serpiente"]				= "Serpent",				-- [35]
				["Palomilla"]				= "Moth",					-- [37]
				["Quimera"]					= "Chimaera",				-- [38]
				["Demosaurio"]				= "Devilsaur",				-- [39]
				["Necrófago"]				= "Ghoul",					-- [40]
				["Silítido"]				= "Silithid",				-- [41]
				["Gusano"]					= "Worm",					-- [42]
				["Uñagrieta"]				= "Clefthoof",				-- [43]
				["Avispa"]					= "Wasp",					-- [44]
				["Can del Núcleo"]			= "Core Hound",				-- [45]
				["Bestia espíritu"]			= "Spirit Beast",			-- [46]
				["Elemental de agua"]		= "Water Elemental",		-- [49]
				["Zorro"]					= "Fox",					-- [50]
				["Mono"]					= "Monkey",					-- [51]
				["Perro"]					= "Dog",					-- [52]
				["Alfazaque"]				= "Beetle",					-- [53]
				["Araña de esquisto"]		= "Shale Spider",			-- [55]
				["Zombi"]					= "Zombie",					-- [56]
				["<< QA TEST FAMILY >>"]	= "<< QA TEST FAMILY >>",	-- [57]
				["Hidra"]					= "Hydra",					-- [68]
				["Diablillo vil"]			= "Fel Imp",				-- [100]
				["Señor del Vacío"]			= "Voidlord",				-- [101]
				["Shivarra"]				= "Shivarra",				-- [102]
				["Observador"]				= "Observer",				-- [103]
				["Guardia de cólera"]		= "Wrathguard",				-- [104]
				["Infernal"]				= "Infernal",				-- [108]
				["Elemental de fuego"]		= "Fire Elemental",			-- [116]
				["Elemental de tierra"]		= "Earth Elemental",		-- [117]
				["Grulla"]					= "Crane",					-- [125]
				["Zancudo acuático"]		= "Water Strider",			-- [126]
				["Roedor"]					= "Rodent",					-- [127]
				["Quilen"]					= "Quilen",					-- [128]
				["Cabra"]					= "Goat",					-- [129]
				["Basilisco"]				= "Basilisk",				-- [130]
				["Cuernoatroz"]				= "Direhorn",				-- [138]
				["Elem. de tormenta"]		= "Storm Elemental",		-- [145] Spain
				["Elemental tormenta"]		= "Storm Elemental",		-- [145] Mexico
				["Guarda terrorífico"]		= "Terrorguard",			-- [147]
				["Abisal"]					= "Abyssal",				-- [148]
				["Bestia fluvial"]			= "Riverbeast",				-- [150] Spain
				["Bestia del río"]			= "Riverbeast",				-- [150] Mexico
				["Venado"]					= "Stag",					-- [151]
				["Máquina"]					= "Mechanical",				-- [154] Spain
				["Mecánico"]				= "Mechanical",				-- [154] Mexico
				["Abominación"]				= "Abomination",			-- [155]
				["Pielescama"]				= "Scalehide",				-- [156]
				["Buey"]					= "Oxen",					-- [157]
				["Cuellipluma"]				= "Feathermane",			-- [160] Spain
				["Crinpluma"]				= "Feathermane",			-- [160] Mexico
				["Lagarto"]					= "Lizard",					-- [288]
				["Pterrordáctilo"]			= "Pterrordax",				-- [290]
				["Sapo"]					= "Toad",					-- [291]
				["Crolusco"]				= "Krolusk",				-- [292] Spain
				["Krolusko"]				= "Krolusk",				-- [292] Maxico
				["Bestia de sangre"]		= "Blood Beast",			-- [296]
			},
			ptPT				= {
				["Lobo"]					= "Wolf",					-- [1]
				["Gato"]					= "Cat",					-- [2]
				["Aranha"]					= "Spider",					-- [3]
				["Urso"]					= "Bear",					-- [4]
				["Javali"]					= "Boar",					-- [5]
				["Crocolisco"]				= "Crocolisk",				-- [6]
				["Ave Carniceira"]			= "Carrion Bird",			-- [7]
				["Caranguejo"]				= "Crab",					-- [8]
				["Gorila"]					= "Gorilla",				-- [9]
				["Raptor"]					= "Raptor",					-- [11]
				["Moa"]						= "Tallstrider",			-- [12]
				["Caçador Vil"]				= "Felhunter",				-- [15]
				["Emissário do Caos"]		= "Voidwalker",				-- [16]
				["Súcubo"]					= "Succubus",				-- [17]
				["Demonarca"]				= "Doomguard",				-- [19]
				["Escorpídeo"]				= "Scorpid",				-- [20]
				["Tartaruga"]				= "Turtle",					-- [21]
				["Diabrete"]				= "Imp",					-- [23]
				["Morcego"]					= "Bat",					-- [24]
				["Hiena"]					= "Hyena",					-- [25]
				["Coruja"]					= "Owl",					-- [26] Classic
				["Ave de Rapina"]			= "Bird of Prey",			-- [26] Retail
				["Serpente Alada"]			= "Wind Serpent",			-- [27]
				["Controle Remoto"]			= "Remote Control",			-- [28]
				["Guarda Vil"]				= "Felguard",				-- [29]
				["Falcodrago"]				= "Dragonhawk",				-- [30]
				["Assolador"]				= "Ravager",				-- [31]
				["Espreitador Dimens."]		= "Warp Stalker",			-- [32]
				["Quirósporo"]				= "Sporebat",				-- [33]
				["Arraia"]					= "Ray",					-- [34]
				["Serpente"]				= "Serpent",				-- [35]
				["Mariposa"]				= "Moth",					-- [37]
				["Quimera"]					= "Chimaera",				-- [38]
				["Demossauro"]				= "Devilsaur",				-- [39]
				["Carniçal"]				= "Ghoul",					-- [40]
				["Silitídeo"]				= "Silithid",				-- [41]
				["Verme"]					= "Worm",					-- [42]
				["Fenoceronte"]				= "Clefthoof",				-- [43]
				["Vespa"]					= "Wasp",					-- [44]
				["Cão-magma"]				= "Core Hound",				-- [45]
				["Fera Espiritual"]			= "Spirit Beast",			-- [46]
				["Elemental da Água"]		= "Water Elemental",		-- [49]
				["Raposa"]					= "Fox",					-- [50]
				["Macaco"]					= "Monkey",					-- [51]
				["Cachorro"]				= "Dog",					-- [52]
				["Besouro"]					= "Beetle",					-- [53]
				["Aranha Xistosa"]			= "Shale Spider",			-- [55]
				["Zumbi"]					= "Zombie",					-- [56]
				["Beetle <zzOLD>"]			= "<< QA TEST FAMILY >>",	-- [57]
				["Hidra"]					= "Hydra",					-- [68]
				["Diabrete Vil"]			= "Fel Imp",				-- [100]
				["Senhor do Caos"]			= "Voidlord",				-- [101]
				["Shivarra"]				= "Shivarra",				-- [102]
				["Observador"]				= "Observer",				-- [103]
				["Guardião Colérico"]		= "Wrathguard",				-- [104]
				["Infernal"]				= "Infernal",				-- [108]
				["Elemental do Fogo"]		= "Fire Elemental",			-- [116]
				["Elemental da Terra"]		= "Earth Elemental",		-- [117]
				["Garça"]					= "Crane",					-- [125]
				["Caminhante das Águas"]	= "Water Strider",			-- [126]
				["Roedor"]					= "Rodent",					-- [127]
				["Quílen"]					= "Quilen",					-- [128]
				["Bode"]					= "Goat",					-- [129]
				["Basilisco"]				= "Basilisk",				-- [130]
				["Escornante"]				= "Direhorn",				-- [138]
				["Elemental Tempestade"]	= "Storm Elemental",		-- [145]
				["Deimoguarda"]				= "Terrorguard",			-- [147]
				["Abissal"]					= "Abyssal",				-- [148]
				["Fera-do-rio"]				= "Riverbeast",				-- [150]
				["Cervo"]					= "Stag",					-- [151]
				["Mecânico"]				= "Mechanical",				-- [154]
				["Abominação"]				= "Abomination",			-- [155]
				["Courescama"]				= "Scalehide",				-- [156]
				["Boi"]						= "Oxen",					-- [157]
				["Aquifélix"]				= "Feathermane",			-- [160]
				["Lagarto"]					= "Lizard",					-- [288]
				["Pterrordax"]				= "Pterrordax",				-- [290]
				["Sapo"]					= "Toad",					-- [291]
				["Crolusco"]				= "Krolusk",				-- [292]
				["Fera Sangrenta"]			= "Blood Beast",			-- [296]
			},
			itIT				= {
				["Lupo"]					= "Wolf",					-- [1]
				["Felino"]					= "Cat",					-- [2]
				["Ragno"]					= "Spider",					-- [3]
				["Orso"]					= "Bear",					-- [4]
				["Cinghiale"]				= "Boar",					-- [5]
				["Crocolisco"]				= "Crocolisk",				-- [6]
				["Mangiacarogne"]			= "Carrion Bird",			-- [7]
				["Granchio"]				= "Crab",					-- [8]
				["Gorilla"]					= "Gorilla",				-- [9]
				["Raptor"]					= "Raptor",					-- [11]
				["Zampalunga"]				= "Tallstrider",			-- [12]
				["Vilsegugio"]				= "Felhunter",				-- [15]
				["Ombra del Vuoto"]			= "Voidwalker",				-- [16]
				["Succube"]					= "Succubus",				-- [17]
				["Demone Guardiano"]		= "Doomguard",				-- [19]
				["Scorpide"]				= "Scorpid",				-- [20]
				["Tartaruga"]				= "Turtle",					-- [21]
				["Imp"]						= "Imp",					-- [23]
				["Pipistrello"]				= "Bat",					-- [24]
				["Iena"]					= "Hyena",					-- [25]
				["Rapace"]					= "Bird of Prey",			-- [26]
				["Serpente Volante"]		= "Wind Serpent",			-- [27]
				["Controllo a Distanza"]	= "Remote Control",			-- [28]
				["Vilguardia"]				= "Felguard",				-- [29]
				["Dragofalco"]				= "Dragonhawk",				-- [30]
				["Devastatore"]				= "Ravager",				-- [31]
				["Segugio Distorcente"]		= "Warp Stalker",			-- [32]
				["Sporofago"]				= "Sporebat",				-- [33]
				["Pastinaca"]				= "Ray",					-- [34]
				["Serpente"]				= "Serpent",				-- [35]
				["Falena"]					= "Moth",					-- [37]
				["Chimera"]					= "Chimaera",				-- [38]
				["Gigantosauro"]			= "Devilsaur",				-- [39]
				["Ghoul"]					= "Ghoul",					-- [40]
				["Silitide"]				= "Silithid",				-- [41]
				["Verme"]					= "Worm",					-- [42]
				["Mammuceronte"]			= "Clefthoof",				-- [43]
				["Vespa"]					= "Wasp",					-- [44]
				["Segugio del Nucleo"]		= "Core Hound",				-- [45]
				["Bestia Eterea"]			= "Spirit Beast",			-- [46]
				["Elementale d'Acqua"]		= "Water Elemental",		-- [49]
				["Volpe"]					= "Fox",					-- [50]
				["Scimmia"]					= "Monkey",					-- [51]
				["Cane"]					= "Dog",					-- [52]
				["Scarabeo"]				= "Beetle",					-- [53]
				["Ragno Roccioso"]			= "Shale Spider",			-- [55]
				["Zombi"]					= "Zombie",					-- [56]
				["<< QA TEST FAMILY >>"]	= "<< QA TEST FAMILY >>",	-- [57]
				["Idra"]					= "Hydra",					-- [68]
				["Vilimp"]					= "Fel Imp",				-- [100]
				["Signore del Vuoto"]		= "Voidlord",				-- [101]
				["Shivarra"]				= "Shivarra",				-- [102]
				["Osservatore"]				= "Observer",				-- [103]
				["Guardia dell'Ira"]		= "Wrathguard",				-- [104]
				["Infernale"]				= "Infernal",				-- [108]
				["Elementale del Fuoco"]	= "Fire Elemental",			-- [116]
				["Elementale di Terra"]		= "Earth Elemental",		-- [117]
				["Gru"]						= "Crane",					-- [125]
				["Gerride"]					= "Water Strider",			-- [126]
				["Roditore"]				= "Rodent",					-- [127]
				["Quilen"]					= "Quilen",					-- [128]
				["Caprone"]					= "Goat",					-- [129]
				["Basilisco"]				= "Basilisk",				-- [130]
				["Cornofurente"]			= "Direhorn",				-- [138]
				["Elementale Tempesta"]		= "Storm Elemental",		-- [145]
				["Guardia Maligna"]			= "Terrorguard",			-- [147]
				["Abission"]				= "Abyssal",				-- [148]
				["Bestia dei Fiumi"]		= "Riverbeast",				-- [150]
				["Cervo"]					= "Stag",					-- [151]
				["Unità Meccanica"]			= "Mechanical",				-- [154]
				["Abominio"]				= "Abomination",			-- [155]
				["Scagliamanto"]			= "Scalehide",				-- [156]
				["Yak"]						= "Oxen",					-- [157]
				["Piumanto"]				= "Feathermane",			-- [160]
				["Lucertola"]				= "Lizard",					-- [288]
				["Pterrordattilo"]			= "Pterrordax",				-- [290]
				["Rospo"]					= "Toad",					-- [291]
				["Krolusk"]					= "Krolusk",				-- [292]
				["Bestia di Sangue"]		= "Blood Beast",			-- [296]
			},
			koKR				= {
				["늑대"]						= "Wolf",					-- [1]
				["살쾡이"]					= "Cat",					-- [2]
				["거미"]						= "Spider",					-- [3]
				["곰"]						= "Bear",					-- [4]
				["멧돼지"]					= "Boar",					-- [5]
				["악어"]						= "Crocolisk",				-- [6]
				["독수리"]					= "Carrion Bird",			-- [7]
				["게"]						= "Crab",					-- [8]
				["고릴라"]					= "Gorilla",				-- [9]
				["랩터"]						= "Raptor",					-- [11]
				["타조"]						= "Tallstrider",			-- [12]
				["지옥사냥개"]				= "Felhunter",				-- [15]
				["보이드워커"]				= "Voidwalker",				-- [16] Classic
				["공허방랑자"]				= "Voidwalker",				-- [16] Retail
				["서큐버스"]					= "Succubus",				-- [17]
				["파멸의수호병"]				= "Doomguard",				-- [19] Classic
				["파멸수호병"]				= "Doomguard",				-- [19] Retail
				["전갈"]						= "Scorpid",				-- [20]
				["거북"]						= "Turtle",					-- [21]
				["임프"]						= "Imp",					-- [23]
				["박쥐"]						= "Bat",					-- [24]
				["하이에나"]					= "Hyena",					-- [25]
				["올빼미"]					= "Owl",					-- [26] Classic
				["맹금"]						= "Bird of Prey",			-- [26] Retail
				["천둥매"]					= "Wind Serpent",			-- [27]
				["무선조종 장난감"]			= "Remote Control",			-- [28]
				["지옥수호병"]				= "Felguard",				-- [29]
				["용매"]						= "Dragonhawk",				-- [30]
				["칼날발톱"]					= "Ravager",				-- [31]
				["차원의 추적자"]				= "Warp Stalker",			-- [32]
				["포자박쥐"]					= "Sporebat",				-- [33]
				["가오리"]					= "Ray",					-- [34]
				["뱀"]						= "Serpent",				-- [35]
				["나방"]						= "Moth",					-- [37]
				["키메라"]					= "Chimaera",				-- [38]
				["데빌사우루스"]				= "Devilsaur",				-- [39]
				["구울"]						= "Ghoul",					-- [40]
				["실리시드"]					= "Silithid",				-- [41]
				["벌레"]						= "Worm",					-- [42]
				["갈래발굽"]					= "Clefthoof",				-- [43]
				["말벌"]						= "Wasp",					-- [44]
				["심장부 사냥개"]				= "Core Hound",				-- [45]
				["야수 정령"]				= "Spirit Beast",			-- [46]
				["물의 정령"]				= "Water Elemental",		-- [49]
				["여우"]						= "Fox",					-- [50]
				["원숭이"]					= "Monkey",					-- [51]
				["개"]						= "Dog",					-- [52]
				["딱정벌레"]					= "Beetle",					-- [53]
				["혈암거미"]					= "Shale Spider",			-- [55]
				["좀비"]						= "Zombie",					-- [56]
				["<< QA 테스트용 >>"]		= "<< QA TEST FAMILY >>",	-- [57]
				["히드라"]					= "Hydra",					-- [68]
				["지옥 임프"]				= "Fel Imp",				-- [100]
				["공허군주"]					= "Voidlord",				-- [101]
				["쉬바라"]					= "Shivarra",				-- [102]
				["감시자"]					= "Observer",				-- [103]
				["격노수호병"]				= "Wrathguard",				-- [104]
				["지옥불정령"]				= "Infernal",				-- [108]
				["불의 정령"]				= "Fire Elemental",			-- [116]
				["대지의 정령"]				= "Earth Elemental",		-- [117]
				["학"]						= "Crane",					-- [125]
				["소금쟁이"]					= "Water Strider",			-- [126]
				["설치류"]					= "Rodent",					-- [127]
				["기렌"]						= "Quilen",					-- [128]
				["염소"]						= "Goat",					-- [129]
				["바실리스크"]				= "Basilisk",				-- [130]
				["공포뿔"]					= "Direhorn",				-- [138]
				["폭풍의 정령"]				= "Storm Elemental",		-- [145]
				["공포수호병"]				= "Terrorguard",			-- [147]
				["심연불정령"]				= "Abyssal",				-- [148]
				["강물하마"]					= "Riverbeast",				-- [150]
				["순록"]						= "Stag",					-- [151]
				["기계"]						= "Mechanical",				-- [154]
				["누더기골렘"]				= "Abomination",			-- [155]
				["비늘가죽"]					= "Scalehide",				-- [156]
				["소"]						= "Oxen",					-- [157]
				["뾰족갈기"]					= "Feathermane",			-- [160]
				["도마뱀"]					= "Lizard",					-- [288]
				["테러닥스"]					= "Pterrordax",				-- [290]
				["두꺼비"]					= "Toad",					-- [291]
				["크롤러스크"]				= "Krolusk",				-- [292]
				["피의 괴물"]				= "Blood Beast",			-- [296]
			},
			zhCN				= {
				["狼"]						= "Wolf",					-- [1]
				["豹"]						= "Cat",					-- [2]
				["蜘蛛"]						= "Spider",					-- [3]
				["熊"]						= "Bear",					-- [4]
				["野猪"]						= "Boar",					-- [5]
				["鳄鱼"]						= "Crocolisk",				-- [6]
				["食腐鸟"]					= "Carrion Bird",			-- [7]
				["螃蟹"]						= "Crab",					-- [8]
				["猩猩"]						= "Gorilla",				-- [9]
				["迅猛龙"]					= "Raptor",					-- [11]
				["陆行鸟"]					= "Tallstrider",			-- [12]
				["地狱猎犬"]					= "Felhunter",				-- [15]
				["虚空行者"]					= "Voidwalker",				-- [16]
				["魅魔"]						= "Succubus",				-- [17]
				["末日守卫"]					= "Doomguard",				-- [19]
				["蝎子"]						= "Scorpid",				-- [20]
				["海龟"]						= "Turtle",					-- [21]
				["小鬼"]						= "Imp",					-- [23]
				["蝙蝠"]						= "Bat",					-- [24]
				["土狼"]						= "Hyena",					-- [25]
				["猫头鹰"]					= "Owl",					-- [26] Classic
				["猛禽"]						= "Bird of Prey",			-- [26] Retail
				["风蛇"]						= "Wind Serpent",			-- [27]
				["远程控制"]					= "Remote Control",			-- [28]
				["恶魔卫士"]					= "Felguard",				-- [29]
				["龙鹰"]						= "Dragonhawk",				-- [30]
				["掠食者"]					= "Ravager",				-- [31]
				["迁跃捕猎者"]				= "Warp Stalker",			-- [32]
				["孢子蝠"]					= "Sporebat",				-- [33]
				["鳐鱼"]						= "Ray",					-- [34]
				["蛇"]						= "Serpent",				-- [35]
				["蛾子"]						= "Moth",					-- [37]
				["奇美拉"]					= "Chimaera",				-- [38]
				["魔暴龙"]					= "Devilsaur",				-- [39]
				["食尸鬼"]					= "Ghoul",					-- [40]
				["异种虫"]					= "Silithid",				-- [41]
				["蠕虫"]						= "Worm",					-- [42]
				["裂蹄牛"]					= "Clefthoof",				-- [43]
				["巨蜂"]						= "Wasp",					-- [44]
				["熔岩犬"]					= "Core Hound",				-- [45]
				["灵魂兽"]					= "Spirit Beast",			-- [46]
				["水元素"]					= "Water Elemental",		-- [49]
				["狐狸"]						= "Fox",					-- [50]
				["猴子"]						= "Monkey",					-- [51]
				["狗"]						= "Dog",					-- [52]
				["甲虫"]						= "Beetle",					-- [53]
				["页岩蛛"]					= "Shale Spider",			-- [55]
				["僵尸"]						= "Zombie",					-- [56]
				["<< QA TEST FAMILY >>"]	= "<< QA TEST FAMILY >>",	-- [57]
				["九头蛇"]					= "Hydra",					-- [68]
				["邪能小鬼"]					= "Fel Imp",				-- [100]
				["空灵领主"]					= "Voidlord",				-- [101]
				["破坏魔"]					= "Shivarra",				-- [102]
				["眼魔"]						= "Observer",				-- [103]
				["愤怒卫士"]					= "Wrathguard",				-- [104]
				["地狱火"]					= "Infernal",				-- [108]
				["火元素"]					= "Fire Elemental",			-- [116]
				["土元素"]					= "Earth Elemental",		-- [117]
				["鹤"]						= "Crane",					-- [125]
				["水黾"]						= "Water Strider",			-- [126]
				["啮齿动物"]					= "Rodent",					-- [127]
				["魁麟"]						= "Quilen",					-- [128]
				["山羊"]						= "Goat",					-- [129]
				["石化蜥蜴"]					= "Basilisk",				-- [130]
				["恐角龙"]					= "Direhorn",				-- [138]
				["风暴元素"]					= "Storm Elemental",		-- [145]
				["恐惧卫士"]					= "Terrorguard",			-- [147]
				["深渊魔"]					= "Abyssal",				-- [148]
				["淡水兽"]					= "Riverbeast",				-- [150]
				["雄鹿"]						= "Stag",					-- [151]
				["机械"]						= "Mechanical",				-- [154]
				["憎恶"]						= "Abomination",			-- [155]
				["鳞甲类"]					= "Scalehide",				-- [156]
				["牛"]						= "Oxen",					-- [157]
				["羽鬃兽"]					= "Feathermane",			-- [160]
				["蜥蜴"]						= "Lizard",					-- [288]
				["翼手龙"]					= "Pterrordax",				-- [290]
				["蟾蜍"]						= "Toad",					-- [291]
				["三叶虫"]					= "Krolusk",				-- [292]
				["血兽"]						= "Blood Beast",			-- [296]
			},
			zhTW				= {
				["狼"]						= "Wolf",					-- [1]
				["豹"]						= "Cat",					-- [2] Classic
				["大貓"]						= "Cat",					-- [2] Retail
				["蜘蛛"]						= "Spider",					-- [3]
				["熊"]						= "Bear",					-- [4]
				["野豬"]						= "Boar",					-- [5]
				["鱷魚"]						= "Crocolisk",				-- [6]
				["食腐鳥"]					= "Carrion Bird",			-- [7]
				["螃蟹"]						= "Crab",					-- [8]
				["猩猩"]						= "Gorilla",				-- [9]
				["迅猛龍"]					= "Raptor",					-- [11]
				["陸行鳥"]					= "Tallstrider",			-- [12]
				["地獄獵犬"]					= "Felhunter",				-- [15] Classic
				["惡魔獵犬"]					= "Felhunter",				-- [15] Retail
				["虛空行者"]					= "Voidwalker",				-- [16] Classic
				["虛無行者"]					= "Voidwalker",				-- [16] Retail
				["魅魔"]						= "Succubus",				-- [17]
				["末日守衛"]					= "Doomguard",				-- [19]
				["蠍子"]						= "Scorpid",				-- [20]
				["海龜"]						= "Turtle",					-- [21]
				["小鬼"]						= "Imp",					-- [23]
				["蝙蝠"]						= "Bat",					-- [24]
				["土狼"]						= "Hyena",					-- [25]
				["貓頭鷹"]					= "Owl",					-- [26] Classic
				["猛禽"]						= "Bird of Prey",			-- [26] Retail
				["風蛇"]						= "Wind Serpent",			-- [27]
				["遙控"]						= "Remote Control",			-- [28]
				["惡魔守衛"]					= "Felguard",				-- [29]
				["龍鷹"]						= "Dragonhawk",				-- [30]
				["劫毀者"]					= "Ravager",				-- [31]
				["扭曲巡者"]					= "Warp Stalker",			-- [32]
				["孢子蝙蝠"]					= "Sporebat",				-- [33]
				["魟魚"]						= "Ray",					-- [34]
				["毒蛇"]						= "Serpent",				-- [35]
				["蛾"]						= "Moth",					-- [37]
				["奇美拉"]					= "Chimaera",				-- [38]
				["魔暴龍"]					= "Devilsaur",				-- [39]
				["食屍鬼"]					= "Ghoul",					-- [40]
				["異種蟲族"]					= "Silithid",				-- [41]
				["蟲"]						= "Worm",					-- [42]
				["裂蹄"]						= "Clefthoof",				-- [43]
				["黃蜂"]						= "Wasp",					-- [44]
				["熔核犬"]					= "Core Hound",				-- [45]
				["靈獸"]						= "Spirit Beast",			-- [46]
				["水元素"]					= "Water Elemental",		-- [49]
				["狐狸"]						= "Fox",					-- [50]
				["猴子"]						= "Monkey",					-- [51]
				["狗"]						= "Dog",					-- [52]
				["甲蟲"]						= "Beetle",					-- [53]
				["岩蛛"]						= "Shale Spider",			-- [55]
				["殭屍"]						= "Zombie",					-- [56]
				["<< QA TEST FAMILY >>"]	= "<< QA TEST FAMILY >>",	-- [57]
				["多頭蛇"]					= "Hydra",					-- [68]
				["魔化小鬼"]					= "Fel Imp",				-- [100]
				["虛無領主"]					= "Voidlord",				-- [101]
				["希瓦拉"]					= "Shivarra",				-- [102]
				["觀察者"]					= "Observer",				-- [103]
				["憤怒守衛"]					= "Wrathguard",				-- [104]
				["煉獄火"]					= "Infernal",				-- [108]
				["火元素"]					= "Fire Elemental",			-- [116]
				["土元素"]					= "Earth Elemental",		-- [117]
				["鶴"]						= "Crane",					-- [125]
				["水黽"]						= "Water Strider",			-- [126]
				["齧齒類"]					= "Rodent",					-- [127]
				["麒麟獸"]					= "Quilen",					-- [128]
				["山羊"]						= "Goat",					-- [129]
				["蜥蜴"]						= "Basilisk",				-- [130]
				["恐角龍"]					= "Direhorn",				-- [138]
				["風暴元素"]					= "Storm Elemental",		-- [145]
				["恐懼護衛"]					= "Terrorguard",			-- [147]
				["冥淵火"]					= "Abyssal",				-- [148]
				["河獸"]						= "Riverbeast",				-- [150]
				["雄鹿"]						= "Stag",					-- [151]
				["機械"]						= "Mechanical",				-- [154]
				["憎惡體"]					= "Abomination",			-- [155]
				["鱗皮"]						= "Scalehide",				-- [156]
				["玄牛"]						= "Oxen",					-- [157]
				["羽鬃"]						= "Feathermane",			-- [160]
				["蜥蜴"]						= "Lizard",					-- [288]
				["翼手龍"]					= "Pterrordax",				-- [290]
				["青蛙"]						= "Toad",					-- [291]
				["葉殼蟲"]					= "Krolusk",				-- [292]
				["血獸"]						= "Blood Beast",			-- [296]
			},
		},
		{
			__index = function(t, v)
				return t[GameLocale][v]
			end,
		}
	),
	IsDummy 					= {
		-- City (SW, Orgri, ...)
		[31146] = true, -- Raider's Training Dummy
		[31144] = true, -- Training Dummy
		[32666] = true, -- Training Dummy
		[32667] = true, -- Training Dummy
		[46647] = true, -- Training Dummy
		-- MoP Shrine of Two Moons
		[67127] = true, -- Training Dummy
		-- WoD Alliance Garrison
		[87317] = true, -- Mage Tower Damage Training Dummy
		[87318] = true, -- Mage Tower Damage Dungeoneer's Training Dummy (& Garrison)
		[87320] = true, -- Mage Tower Damage Raider's Training Dummy
		[88314] = true, -- Tanking Dungeoneer's Training Dummy
		[88316] = true, -- Healing Training Dummy ----> FRIENDLY
		-- WoD Horde Garrison
		[87760] = true, -- Mage Tower Damage Training Dummy
		[87761] = true, -- Mage Tower Damage Dungeoneer's Training Dummy (& Garrison)
		[87762] = true, -- Mage Tower Damage Raider's Training Dummy
		[88288] = true, -- Tanking Dungeoneer's Training Dummy
		[88289] = true, -- Healing Training Dummy ----> FRIENDLY
		-- Legion Rogue Class Order Hall
		[92164] = true, -- Training Dummy
		[92165] = true, -- Dungeoneer's Training Dummy
		[92166] = true, -- Raider's Training Dummy
		-- Legion Priest Class Order Hall
		[107555] = true, -- Bound void Wraith
		[107556] = true, -- Bound void Walker
		-- Legion Druid Class Order Hall
		[113964] = true, -- Raider's Training Dummy
		[113966] = true, -- Dungeoneer's Training Dummy
		-- Legion Warlock Class Order Hall
		[102052] = true, -- Rebellious imp
		[102048] = true, -- Rebellious Felguard
		[102045] = true, -- Rebellious WrathGuard
		[101956] = true, -- Rebellious Fel Lord
		-- Legion Mage Class Order Hall
		[103397] = true, -- Greater Bullwark Construct
		[103404] = true, -- Bullwark Construct
		[103402] = true, -- Lesser Bullwark Construct
		-- BfA Dazar'Alor
		[144081] = true, -- Training Dummy
		[144082] = true, -- Training Dummy
		[144085] = true, -- Training Dummy
		[144086] = true, -- Raider's Training Dummy
		-- Misc/Unknown
		[79987]  = true, -- Location Unknown
		[92169]  = true, -- Tanking (Eastern Plaguelands)
		[96442]  = true, -- Damage (Location Unknown)
		[109595] = true, -- Location Unknown
		[113963] = true, -- Damage (Location Unknown)
		[131985] = true, -- Damage (Zuldazar)
		[131990] = true, -- Tanking (Zuldazar)
		[132976] = true, -- Morale Booster (Zuldazar)
		-- Level 1
		[17578]  = true, -- Lvl 1 (The Shattered Halls)
		[60197]  = true, -- Lvl 1 (Scarlet Monastery)
		[64446]  = true, -- Lvl 1 (Scarlet Monastery)
		[144077] = true, -- Lvl 1 (Dazar'alor) - Morale Booster
		-- Level 3
		[44171]  = true, -- Lvl 3 (New Tinkertown, Dun Morogh)
		[44389]  = true, -- Lvl 3 (Coldridge Valley)
		[44848]  = true, -- Lvl 3 (Camp Narache, Mulgore)
		[44548]  = true, -- Lvl 3 (Elwynn Forest)
		[44614]  = true, -- Lvl 3 (Teldrassil, Shadowglen)
		[44703]  = true, -- Lvl 3 (Ammen Vale)
		[44794]  = true, -- Lvl 3 (Dethknell, Tirisfal Glades)
		[44820]  = true, -- Lvl 3 (Valley of Trials, Durotar)
		[44937]  = true, -- Lvl 3 (Eversong Woods, Sunstrider Isle)
		[48304]  = true, -- Lvl 3 (Kezan)
		-- Level 55
		[32541]  = true, -- Lvl 55 (Plaguelands: The Scarlet Enclave)
		[32545]  = true, -- Lvl 55 (Eastern Plaguelands)
		-- Level 65
		[32542]  = true, -- Lvl 65 (Eastern Plaguelands)
		-- Level 75
		[32543]  = true, -- Lvl 75 (Eastern Plaguelands)
		-- Level 80
		[32546]  = true, -- Lvl 80 (Eastern Plaguelands)
		-- Level 95
		[79414]  = true, -- Lvl 95 (Broken Shore, Talador)
		-- Level 100
		[87321]  = true, -- Lvl 100 (Stormshield) - Healing
		[88835]  = true, -- Lvl 100 (Warspear) - Healing
		[88906]  = true, -- Lvl 100 (Nagrand)
		[88967]  = true, -- Lvl 100 (Lunarfall, Frostwall)
		[89078]  = true, -- Lvl 100 (Frostwall, Lunarfall)
		-- Levl 100 - 110
		[92167]  = true, -- Lvl 100 - 110 (The Maelstrom, Eastern Plaguelands, The Wandering Isle)
		[92168]  = true, -- Lvl 100 - 110 (The Wandering Isles, Easter Plaguelands)
		[100440] = true, -- Lvl 100 - 110 (The Wandering Isles)
		[100441] = true, -- Lvl 100 - 110 (The Wandering Isles)
		[107483] = true, -- Lvl 100 - 110 (Skyhold)
		[107557] = true, -- Lvl 100 - 110 (Netherlight Temple) - Healing
		[108420] = true, -- Lvl 100 - 110 (Stormwind City, Durotar)
		[111824] = true, -- Lvl 100 - 110 (Azsuna)
		[113674] = true, -- Lvl 100 - 110 (Mardum, the Shattered Abyss) - Dungeoneer
		[113676] = true, -- Lvl 100 - 110 (Mardum, the Shattered Abyss)
		[113687] = true, -- Lvl 100 - 110 (Mardum, the Shattered Abyss) - Swarm
		[113858] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113859] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113862] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113863] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113871] = true, -- Lvl 100 - 110 (Trueshot Lodge) - Damage
		[113967] = true, -- Lvl 100 - 110 (The Dreamgrove) - Healing
		[114832] = true, -- Lvl 100 - 110 (Stormwind City)
		[114840] = true, -- Lvl 100 - 110 (Orgrimmar)
		-- Level 102
		[87322]  = true, -- Lvl 102 (Stormshield) - Tank
		[88836]  = true, -- Lvl 102 (Warspear) - Tank
		[93828]  = true, -- Lvl 102 (Hellfire Citadel)
		[97668]  = true, -- Lvl 102 (Highmountain)
		[98581]  = true, -- Lvl 102 (Highmountain)
		-- Level 110 - 120
		[126781] = true, -- Lvl 110 - 120 (Boralus) - Damage
		[131989] = true, -- Lvl 110 - 120 (Boralus) - Damage
		[131994] = true, -- Lvl 110 - 120 (Boralus) - Healing
		[153285] = true, -- Lvl 110 - 120 (Ogrimmar) - Damage
		[153292] = true, -- Lvl 110 - 120 (Stormwind) - Damage
		-- Level 111 - 120
		[131997] = true, -- Lvl 111 - 120 (Boralus, Zuldazar) - PVP Damage
		[131998] = true, -- Lvl 111 - 120 (Boralus, Zuldazar) - PVP Healing
		-- Level 112 - 120
		[144074] = true, -- Lvl 112 - 120 (Dazar'alor) - PVP Healing
		-- Level 112 - 122
		[131992] = true, -- Lvl 112 - 122 (Boralus) - Tanking
		-- Level 113 - 120
		[132036] = true, -- Lvl 113 - 120 (Boralus) - Healing
		-- Level 113 - 122
		[144078] = true, -- Lvl 113 - 122 (Dazar'alor) - Tanking
		-- Level 114 - 120
		[144075] = true, -- Lvl 114 - 120 (Dazar'alor) - Healing
		-- Level ??
		[24792]  = true, -- Lvl ?? Boss (Location Unknown)
		[30527]  = true, -- Lvl ?? Boss (Location Unknown)
		[87329]  = true, -- Lvl ?? (Stormshield) - Tank
		[88837]  = true, -- Lvl ?? (Warspear) - Tank
		[107202] = true, -- Lvl ?? (Broken Shore) - Raider
		[107484] = true, -- Lvl ?? (Skyhold)
		[113636] = true, -- Lvl ?? (Mardum, the Shattered Abyss) - Raider
		[113860] = true, -- Lvl ?? (Trueshot Lodge) - Damage
		[113864] = true, -- Lvl ?? (Trueshot Lodge) - Damage
		[70245]  = true, -- Lvl ?? (Throne of Thunder)
		[131983] = true, -- Lvl ?? (Boralus) - Damage
		  -- Shadowlands Kyrian
		[154586] = true, -- Stalwart Phalanx
		[154585] = true, -- Valiant's Resolve
		[154583] = true, -- Starlwart Guardian
		[154580] = true, -- Reinforced Guardian
		[160325] = true, -- Humility's Obedience
		[154564] = true, -- Valiant's Humility
		[154567] = true, -- Purity's Cleaning
		[160435] = true, --?? Kyrian Combat Trainer Raider's Training Dummy
		[160432] = true, --60 Kyrian Combat Trainer Training Dummy
		[160434] = true, --62 Kyrian Combat Trainer Dungeoneer's Training Dummy
		-- Shadowlands Venthyr
		[173942] = true, -- Training Dummy
		[175449] = true, -- Raider's Training Dummy
		[175450] = true, -- Dungeoneer's Training Dummy
		[175451] = true, -- Dungeoneer's Tanking Dummy
		[175452] = true, -- Raider's Tanking Dummy
		[175455] = true, -- Cleave Training Dummy
		[175456] = true, -- Swarm Training Dummy
		[175462] = true, -- Sinfall Fiend
		[173072] = true, --60 Training Dummy
		-- Shadowlands Night Fae
		[174565] = true, -- Dungeoneer's Tanking Dummy
		[174566] = true, -- Raider's Tanking Dummy
		[174567] = true, -- Raider's Training Dummy
		[174568] = true, -- Dungeoneer's Training Dummy
		[174569] = true, -- Training Dummy
		[174570] = true, -- Swarm Training Dummy
		[175471] = true, -- Cleave Training Dummy
		[174571] = true, --60 Cleave Training Dummy
		-- Shadowlands Necrolord
		[174491] = true, -- Tanking Dummy
		[174488] = true, -- Raider's Training Dummy
		[174484] = true, -- Dungeoneer's Training Dummy
		[174487] = true, -- Training Dummy
		[174489] = true, --60 Necromantic Guide Healing Dummy
		-- Other
		[65310] = true, -- Turnip Punching Bag
		[173877] = true, -- Reinforced Target Dungeoneer's Training Dummy
		[173867] = true, -- Stalwart Totem Raider's Training Dummy
		[151022] = true, -- Training Dummy
		[171961] = true, -- Damaged Kyrian Combat Trainer Training Dummy
		[173873] = true, -- Reinforced Death Elemental Dungeoneer's Training Dummy
		[173866] = true, -- Reinforced Totem Dungeoneer's Training Dummy
		[173870] = true, -- Stalwart Death Elemental Raider's Training Dummy
		[173879] = true, -- Stalwart Target Raider's Training Dummy
		[149860] = true, -- Training Dummy
		[174435] = true, -- Training Dummy
		-- DragonFlight
		[198594] = true, -- Cleave Training Dummy
		[194648] = true, -- Training Dummy
		[189632] = true, -- Animated Duelist
		[194643] = true, -- Dungeoneer's Training Dummy
		[197833] = true, -- PvP Training Dummy
		[194644] = true, -- Dungeoneer's Training Dummy
		[189617] = true, -- Boulderfist Raider's Tanking Dummy
		[194649] = true, -- Normal Tanking Dummy
		[194645] = true, -- Healing Training Dummy
		[197834] = true, -- Healing PvP Training Dummy
		[194646] = true, -- Healing Training Dummy
		[193563] = true, -- Azure Span Training Dummy
		-- The War Within Dornogal
		[219250] = true, -- PvP Training Dummy <Damage>
		[225982] = true, -- Cleave Training Dummy <Damage>
		[225982] = true, -- Cleave Training Dummy <Damage>
		[225980] = true, -- Training Dummy <Healing>
		[225976] = true, -- Normal Tank Dummy <Tanking>
		[225977] = true, -- Dungeoneer's Training Dummy <Tanking>
		[225978] = true, -- Crystalmaw <Raider's Tanking Dummy>
		[225983] = true, -- Dungeoneer's Training Dummy <Damage>
		[225985] = true, -- Kelpfist <Raider's Training Dummy>
		[225984] = true, -- Training Dummy <Damage>
	},
	IsDummyPvP 					= {
		-- City (SW, Orgri, ...)
		[114840] = true, -- Raider's Training Dummy
		[114832] = true,
		[131997] = true,
		-- The War Within Dornogal
		[219250] = true, -- PvP Training Dummy <Damage>
	},
	IsCondemnedDemon			= {
		[169428]				= "Wrathguard",
		[169421]				= "Felguard",
		[169426]				= "Infernal",
		[169429]				= "Shivarra",
		[168932]				= "Doomguard",
		[169304]				= "Condemned Demon",
		[169425]				= "Felhound",
		[169430]				= "Ur'zul",
	},
	IsVoidTendril				= {
		[65282]					= "Void Tendril",
	},
	ExplosivesName				= {
		[GameLocale] 			= "Explosives",
		ruRU					= "Взрывчатка",
		enGB					= "Explosives",
		enUS					= "Explosives",
		deDE					= "Sprengstoff",
		esES					= "Explosivos",
		esMX					= "Explosivos",
		frFR					= "Explosifs",
		itIT					= "Esplosivi",
		ptPT					= "Explosivos",
		ptBR					= "Explosivos",
		koKR					= "폭발물",
		zhCN					= "爆炸物",
		zhTW					= "爆炸物",
	},
	IncorporealBeingName		= {
		[GameLocale] 			= "Incorporeal Being",
		ruRU					= "Бестелесный дух",
		enGB					= "Incorporeal Being",
		enUS					= "Incorporeal Being",
		deDE					= "Körperloses Wesen",
		esES					= "Ser incorpóreo",
		esMX					= "Ser incorpóreo",
		frFR					= "Etre immatériel",
		itIT					= "Essere Incorporeo",
		ptPT					= "Ser Incorpóreo",
		ptBR					= "Ser Incorpóreo",
		koKR					= "무형의 존재",
		zhCN					= "虚体生物",
		zhTW					= "虚体生物",
	},
	OrbOfAscendanceName			= {
		[GameLocale] 			= "Orb of Ascendance",
		ruRU					= "Сфера вознесения",
		enGB					= "Orb of Ascendance",
		enUS					= "Orb of Ascendance",
		deDE					= "Kugel der Aszendenz",
		esES					= "Orbe de Ascensión",
		esMX					= "Orbe de Ascensión",
		frFR					= "Orbe de Sublimation",
		itIT					= "Globo dell'Ascesa",
		ptPT					= "Orbe da Ascendência",
		ptBR					= "Orbe da Ascendência",
		koKR					= "승천의 보주",
		zhCN					= "扬升宝珠",
		zhTW					= "扬升宝珠",
	},
	IsBoss 						= {
		-- City (SW, Orgri, ...)
		[31146] = true, -- Raider's Training Dummy
		-- WoD Alliance Garrison
		[87320] = true, -- Mage Tower Damage Raider's Training Dummy
		[88314] = true, -- Tanking Dungeoneer's Training Dummy
		[88316] = true, -- Healing Training Dummy ----> FRIENDLY
		-- WoD Horde Garrison
		[87762] = true, -- Mage Tower Damage Raider's Training Dummy
		[88288] = true, -- Tanking Dungeoneer's Training Dummy
		[88289] = true, -- Healing Training Dummy ----> FRIENDLY
		-- Legion Druid Class Order Hall
		[113964] = true, -- Raider's Training Dummy
		-- Legion Rogue Class Order Hall
		[92166] = true, -- Raider's Training Dummy
		-- BfA Dazar'Alor
		[144086] = true, -- Raider's Training Dummy
		-- Level ??
		[24792]  = true, -- Lvl ?? Boss (Location Unknown)
		[30527]  = true, -- Lvl ?? Boss (Location Unknown)
		[87329]  = true, -- Lvl ?? (Stormshield) - Tank
		[88837]  = true, -- Lvl ?? (Warspear) - Tank
		[107202] = true, -- Lvl ?? (Broken Shore) - Raider
		[107484] = true, -- Lvl ?? (Skyhold)
		[113636] = true, -- Lvl ?? (Mardum, the Shattered Abyss) - Raider
		[113860] = true, -- Lvl ?? (Trueshot Lodge) - Damage
		[113864] = true, -- Lvl ?? (Trueshot Lodge) - Damage
		[70245]  = true, -- Lvl ?? (Throne of Thunder)
		[131983] = true, -- Lvl ?? (Boralus) - Damage
	},
	IsNotBoss 					= {
		-- BfA
		-- Shadow of Zul
		[138489] = true,
	},
	ControlAbleClassification 	= {
		["trivial"] 			= true,
		["minus"] 				= true,
		["normal"] 				= true,
		["rare"] 				= true,
		["rareelite"] 			= true,
		["elite"] 				= true,
		["worldboss"] 			= false,
		[""] 					= true,
	},
	FlagsBuffs					= {
		[156621] 				= true,
		[156618] 				= true,
		[34976] 				= true,
		[GetSpellName(156621)] 	= true,
		[GetSpellName(156618)]	= true,
		[GetSpellName(34976)] 	= true,
	},
	Cyclone 					= {
		SpellName 				= {
			[GetSpellName(33786)] = true, 	-- Cyclone
			[GetSpellName(710)] = true,		-- Banish
		},
		OnEvent					= {
			["SPELL_AURA_APPLIED"] = "Add",
			["SPELL_AURA_REFRESH"] = "Add",
			["SPELL_AURA_REMOVED"] = "Remove",
		},
		GUIDs 					= {},
	},
}

local InfoCacheMoveIn						= Info.CacheMoveIn
local InfoCacheMoveOut						= Info.CacheMoveOut
local InfoCacheMoving						= Info.CacheMoving
local InfoCacheStaying						= Info.CacheStaying
local InfoCacheInterrupt					= Info.CacheInterrupt

local InfoSpecsWithExecute 					= Info.SpecsWithExecute
local InfoSpecsMoonkinRestor 				= Info.SpecsMoonkinRestor
local InfoSpecsFeralGuardian 				= Info.SpecsFeralGuardian
local InfoSpecIs 							= Info.SpecIs
local InfoClassSpecBuffs					= Info.ClassSpecBuffs
local InfoClassSpecSpells					= Info.ClassSpecSpells
local InfoClassIsMelee 						= Info.ClassIsMelee
local InfoClassCanBeHealer 					= Info.ClassCanBeHealer
local InfoClassCanBeTank 					= Info.ClassCanBeTank
local InfoClassCanBeMelee 					= Info.ClassCanBeMelee
local InfoAllCC 							= Info.AllCC

local InfoCreatureType 						= Info.CreatureType
local InfoCreatureFamily					= Info.CreatureFamily
local InfoIsDummy							= Info.IsDummy
local InfoIsDummyPvP						= Info.IsDummyPvP
local InfoIsVoidTendriln					= Info.IsVoidTendril
local InfoIsCondemnedDemon					= Info.IsCondemnedDemon
local InfoExplosivesName 					= Info.ExplosivesName
local InfoIncorporealBeingName				= Info.IncorporealBeingName
local InfoOrbOfAscendanceName				= Info.OrbOfAscendanceName

local InfoIsBoss 							= Info.IsBoss
local InfoIsNotBoss 						= Info.IsNotBoss
local InfoControlAbleClassification			= Info.ControlAbleClassification
local InfoFlagsBuffs 						= Info.FlagsBuffs

local InfoCyclone							= Info.Cyclone
local InfoCycloneSpellName					= InfoCyclone.SpellName
local InfoCycloneOnEvent					= InfoCyclone.OnEvent
local InfoCycloneGUIDs						= InfoCyclone.GUIDs

A.Unit = PseudoClass({
	-- If it's by "UnitGUID" then it will use cache for different unitID with same unitGUID (which is not really best way to waste performance)
	-- Use "UnitGUID" only on high required resource functions
	-- Pass - no cache at all
	-- Wrap - is a cache
	Name 									= Cache:Pass(function(self)
		-- @return string
		local unitID 						= self.UnitID
		return UnitName(unitID) or str_none
	end, "UnitID"),
	Race 									= Cache:Pass(function(self)
		-- @return string
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then
			return A.PlayerRace
		end

		return select(2, UnitRace(unitID)) or str_none
	end, "UnitID"),
	Class 									= Cache:Pass(function(self)
		-- @return string
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then
			return PlayerClass
		end

		return select(2, UnitClass(unitID)) or str_none
	end, "UnitID"),
	Role 									= Cache:Pass(function(self, hasRole) 
		-- @param hasRole 	- nil or string one of follows: "TANK", "HEALER", "DAMAGER", "NONE"
		-- @return boolean	- if 'hasRole' passed as string
		-- @return string	- otherwise returns role of unitID: "TANK", "HEALER", "DAMAGER", "NONE"
		local unitID 						= self.UnitID
		local role							= UnitGroupRolesAssigned(unitID)
		
		if not role or role == "NONE" then
			if A.ZoneID == 480 then
				-- Proving Grounds
				local npcID = self(unitID):InfoGUID()
				if npcID == 72218 then
					-- Oto the Protector
					role = "TANK"
				elseif npcID == 71828 then
					-- Sikari the Mistweaver
					role = "HEALER"
				else
					role = "DAMAGER"
				end
			elseif hasRole then 
				if hasRole == "HEALER" then 
					return self(unitID):IsHealer()
				elseif hasRole == "TANK" then 
					return self(unitID):IsTank()
				elseif hasRole == "DAMAGER" then 
					return self(unitID):IsDamager()
				elseif hasRole == "NONE" then 
					return true
				else 
					return false
				end 
			else 
				if self(unitID):IsHealer() then 
					return "HEALER"
				elseif self(unitID):IsTank() then 
					return "TANK"
				elseif self(unitID):IsDamager() then 
					return "DAMAGER"
				else 
					return "NONE"
				end 
			end
		end

		return (hasRole and hasRole == role) or (not hasRole and role)
	end, "UnitID"),
	Classification							= Cache:Pass(function(self)
		-- @return string or empty string
		local unitID 						= self.UnitID
		return UnitClassification(unitID) or str_empty
	end, "UnitID"),
	CreatureType							= Cache:Pass(function(self)
		-- @return string or empty string
		-- Returns formated string to English, possible string returns:
		-- "Beast"				-- [1]
		-- "Dragonkin"			-- [2]
		-- "Demon"				-- [3]
		-- "Elemental"			-- [4]
		-- "Giant"				-- [5]
		-- "Undead"				-- [6]
		-- "Humanoid"			-- [7]
		-- "Critter"			-- [8]
		-- "Mechanical",		-- [9]
		-- "Not specified"		-- [10]
		-- "Not specified"		-- [10]	(The default UI displays an empty string instead of "Not specified" for units with that creature type)
		-- "Totem"				-- [11]
		-- "Non-combat Pet"		-- [12]
		-- "Gas Cloud"			-- [13]
		-- "Wild Pet"			-- [14]
		-- "Aberration"			-- [15]
		local unitID 						= self.UnitID
		local unitCreatureType 				= UnitCreatureType(unitID)
		return unitCreatureType and InfoCreatureType[unitCreatureType] or str_empty
	end, "UnitID"),
	CreatureFamily							= Cache:Pass(function(self)
		-- @return string or empty string
		-- Returns formated string to English, possible string returns:
		-- "Wolf"					-- [1]
		-- "Cat"					-- [2]
		-- "Spider"					-- [3]
		-- "Bear"					-- [4]
		-- "Boar"					-- [5]
		-- "Crocolisk"				-- [6]
		-- "Carrion Bird"			-- [7]
		-- "Crab"					-- [8]
		-- "Gorilla"				-- [9]
		-- "Raptor"					-- [11]
		-- "Tallstrider"			-- [12]
		-- "Felhunter"				-- [15]
		-- "Voidwalker"				-- [16]
		-- "Succubus"				-- [17]
		-- "Doomguard"				-- [19]
		-- "Scorpid"				-- [20]
		-- "Turtle"					-- [21]
		-- "Imp"					-- [23]
		-- "Bat"					-- [24]
		-- "Hyena"					-- [25]
		-- "Bird of Prey"			-- [26]
		-- "Wind Serpent"			-- [27]
		-- "Remote Control"			-- [28]
		-- "Felguard"				-- [29]
		-- "Dragonhawk"				-- [30]
		-- "Ravager"				-- [31]
		-- "Warp Stalker"			-- [32]
		-- "Sporebat"				-- [33]
		-- "Ray"					-- [34]
		-- "Serpent"				-- [35]
		-- "Moth"					-- [37]
		-- "Chimaera"				-- [38]
		-- "Devilsaur"				-- [39]
		-- "Ghoul"					-- [40]
		-- "Silithid"				-- [41]
		-- "Worm"					-- [42]
		-- "Clefthoof"				-- [43]
		-- "Wasp"					-- [44]
		-- "Core Hound"				-- [45]
		-- "Spirit Beast"			-- [46]
		-- "Water Elemental"		-- [49]
		-- "Fox"					-- [50]
		-- "Monkey"					-- [51]
		-- "Dog"					-- [52]
		-- "Beetle"					-- [53]
		-- "Shale Spider"			-- [55]
		-- "Zombie"					-- [56]
		-- "<< QA TEST FAMILY >>"	-- [57]
		-- "Hydra"					-- [68]
		-- "Fel Imp"				-- [100]
		-- "Voidlord"				-- [101]
		-- "Shivarra"				-- [102]
		-- "Observer"				-- [103]
		-- "Wrathguard"				-- [104]
		-- "Infernal"				-- [108]
		-- "Fire Elemental"			-- [116]
		-- "Earth Elemental"		-- [117]
		-- "Crane"					-- [125]
		-- "Water Strider"			-- [126]
		-- "Rodent"					-- [127]
		-- "Quilen"					-- [128]
		-- "Goat"					-- [129]
		-- "Basilisk"				-- [130]
		-- "Direhorn"				-- [138]
		-- "Storm Elemental"		-- [145]
		-- "Terrorguard"			-- [147]
		-- "Abyssal"				-- [148]
		-- "Riverbeast"				-- [150]
		-- "Stag"					-- [151]
		-- "Mechanical"				-- [154]
		-- "Abomination"			-- [155]
		-- "Scalehide"				-- [156]
		-- "Oxen"					-- [157]
		-- "Feathermane"			-- [160]
		-- "Lizard"					-- [288]
		-- "Pterrordax"				-- [290]
		-- "Toad"					-- [291]
		-- "Krolusk"				-- [292]
		-- "Blood Beast"			-- [296]
		local unitID 						= self.UnitID
		local unitCreatureFamily			= UnitCreatureFamily(unitID)
		return unitCreatureFamily and InfoCreatureFamily[unitCreatureFamily] or str_empty
	end, "UnitID"),
	InfoGUID 								= Cache:Wrap(function(self, unitGUID)
		-- @return
		-- For players: Player-[server ID]-[player UID] (Example: "Player-970-0002FD64")
		-- For creatures, pets, objects, and vehicles: [Unit type]-0-[server ID]-[instance ID]-[zone UID]-[ID]-[spawn UID] (Example: "Creature-0-970-0-11-31146-000136DF91")
		-- Unit Type Names: "Player", "Creature", "Pet", "GameObject", "Vehicle", and "Vignette" they are always in English
		-- [1] utype
		-- [2] zero 		or server_id
		-- [3] server_id 	or player_uid
		-- [4] instance_id	or nil
		-- [5] zone_uid		or nil
		-- [6] npc_id		or nil
		-- [7] spawn_uid 	or nil
		-- or nil
		-- Nill-able: unitGUID
		local unitID 						= self.UnitID
		local GUID 							= unitGUID or UnitGUID(unitID)
		if GUID then
			local utype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", GUID)
			if utype then
				return utype, toNum[zero], toNum[server_id], instance_id and toNum[instance_id], zone_uid and toNum[zone_uid], npc_id and toNum[npc_id], spawn_uid and toNum[spawn_uid]
			end
		end
	end, "UnitID"),
	InLOS 									= Cache:Pass(function(self, unitGUID)
		-- @return boolean
		-- Nill-able: unitGUID
		local unitID 						= self.UnitID
		return UnitInLOS(unitID, unitGUID)
	end, "UnitID"),
	InGroup 								= Cache:Pass(function(self, includeAnyGroups, unitGUID)
		-- @return boolean
		local unitID 						= self.UnitID
		if includeAnyGroups then
			return UnitInAnyGroup(unitID)
		else
			local GUID = unitGUID or GetGUID(unitID)
			return GUID and (TeamCacheFriendlyGUIDs[GUID] or TeamCacheEnemyGUIDs[GUID])
		end
	end, "UnitID"),
	InParty									= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitPlayerOrPetInParty(unitID)
	end, "UnitID"),
	InRaid									= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitPlayerOrPetInRaid(unitID)
	end, "UnitID"),
	InRange 								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsUnit(unitID, "player") or UnitInRange(unitID)
	end, "UnitID"),
	InVehicle								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitInVehicle(unitID)
	end, "UnitID"),
	InCC 									= Cache:Pass(function(self, index)
		-- @return number (time in seconds of remain crownd control)
		-- Nill-able: index
		local unitID 						= self.UnitID
		local value 						= self(unitID):DeBuffCyclone()
		if value == 0 then
			for i = (index or 1), #InfoAllCC do
				value = self(unitID):HasDeBuffs(InfoAllCC[i])
				if value ~= 0 then
					break
				end
			end
		end
		return value
	end, "UnitID"),
	IsEnemy									= Cache:Wrap(function(self, isPlayer)
		-- @return boolean
		-- Nill-able: isPlayer
		local unitID 						= self.UnitID
		return unitID and (UnitCanAttack("player", unitID) or UnitIsEnemy("player", unitID)) and (not isPlayer or UnitIsPlayer(unitID))
	end, "UnitGUID"),
	IsHealer 								= Cache:Pass(function(self, class)  
		-- @return boolean
		-- Nill-able: class
		local unitID 						= self.UnitID
		local unitID_class 					= class or self(unitID):Class()		
		if InfoClassCanBeHealer[unitID_class] then
			local isEnemy 					= self(unitID):IsEnemy()
			if isEnemy then
				if TeamCacheEnemyHEALER[unitID] or self(unitID):HasSpec(InfoSpecIs.HEALER) then
					return true
				elseif BuildToC >= 50500 and (A.Zone == "pvp" or A.Zone == "arena") then
					return false
				end
			else
				if TeamCacheFriendlyHEALER[unitID] then
					return true
				end
				
				local role = UnitGroupRolesAssigned(unitID)
				if role == "HEALER" or (UnitIsUnit(unitID, "player") and self(unitID):HasSpec(InfoSpecIs.HEALER)) then
					return true
				elseif role and role ~= "NONE" then
					return false
				elseif GetPartyAssignment("maintank", unitID) or GetPartyAssignment("mainassist", unitID) then
					return false
				end
			end
			
			-- Fallback
			if unitID_class == "PALADIN" then 				
				local _, power = UnitPowerType(unitID)
				local _, offhand = UnitAttackSpeed(unitID)
				if power ~= "MANA" or offhand ~= nil then
					return false
				else
					local tankBuff = self(unitID):HasBuffs(tankBuffsOrCanBeTank)
					if tankBuff > 0 then 
						-- Protection
						if not A_GetUnitItem or isEnemy or A_GetUnitItem(unitID, CONST.INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD, nil, true) then -- byPassDistance, so if buff is up he's more likely tank
							return false
						end
					else
						-- Retribution
						if not isEnemy and A_GetUnitItem and not A_GetUnitItem(unitID, CONST.INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD) then
							return false
						end
					end
				end				
			elseif unitID_class == "DRUID" then 
				local _, power = UnitPowerType(unitID)
				if power ~= "MANA" or self(unitID):HasBuffs(InfoClassCanBeTank[unitID_class]) > 0 then
					return false
				end
			elseif unitID_class == "MONK" then
				local _, power = UnitPowerType(unitID)
				local _, offhand = UnitAttackSpeed(unitID)
				if power == "MANA" then
					return true
				elseif offhand ~= nil then
					return false
				elseif UnitStagger and UnitStagger(unitID) ~= 0 then
					return false
				end					
			elseif unitID_class == "PRIEST" then
				local _, power = UnitPowerType(unitID)
				if power ~= "MANA" then
					return false
				end
			elseif unitID_class == "SHAMAN" then
				local _, power = UnitPowerType(unitID)
				local _, offhand = UnitAttackSpeed(unitID)
				if power ~= "MANA" or offhand ~= nil then
					return false
				end			
			end
			
			if not A.IsInPvP then 
				local unitIDtarget = strjoin("", unitID, "target")
				if UnitIsUnit(unitID, strjoin("", unitIDtarget, "target")) and self(unitIDtarget):IsBoss() then 
					return false 
				end
			end				
			
											-- bypass it in PvP 
			local taken_dmg 				= (self(unitID):IsEnemy() and self(unitID):IsPlayer() and 0) or CombatTracker:GetDMG(unitID)
			local done_dmg					= CombatTracker:GetDPS(unitID)
			local done_hps					= CombatTracker:GetHPS(unitID)
			return done_hps > taken_dmg and done_hps > done_dmg  
		end 
	end, "UnitID"),
	IsHealerClass							= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return InfoClassCanBeHealer[self(unitID):Class()]
	end, "UnitID"),	
	IsTank 									= Cache:Pass(function(self, class)    
		-- @return boolean 
		-- Nill-able: class
		local unitID 						= self.UnitID
		local unitID_class 					= class or self(unitID):Class()
		local tankBuffsOrCanBeTank			= InfoClassCanBeTank[unitID_class]
		if tankBuffsOrCanBeTank then 
			local isEnemy 					= self(unitID):IsEnemy()
			if isEnemy then
				if TeamCacheEnemyTANK[unitID] or self(unitID):HasSpec(InfoSpecIs.TANK) then
					return true
				elseif BuildToC >= 50500 and (A.Zone == "pvp" or A.Zone == "arena") then
					return false
				end
			else
				if TeamCacheFriendlyTANK[unitID] then
					return true
				end
				
				local role = UnitGroupRolesAssigned(unitID)
				if role == "TANK" or GetPartyAssignment("maintank", unitID) or (UnitIsUnit(unitID, "player") and self(unitID):HasSpec(InfoSpecIs.TANK)) then
					return true
				elseif role and role ~= "NONE" then
					return false
				end	
			end		
			
			-- Fallback
			if unitID_class == "PALADIN" then 
				local _, power = UnitPowerType(unitID)
				local _, offhand = UnitAttackSpeed(unitID)
				if power ~= "MANA" or offhand ~= nil then
					return false
				else
					local tankBuff = self(unitID):HasBuffs(tankBuffsOrCanBeTank)
					if tankBuff > 0 then 
						-- Protection
						if not A_GetUnitItem or isEnemy or A_GetUnitItem(unitID, CONST.INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD, nil, true) then -- byPassDistance, so if buff is up he's more likely tank
							return true
						end
					else
						-- Retribution
						if A.IsInPvP or self(unitID):ThreatSituation(strjoin("", unitID, "target")) < 3 then
							return false
						end
					end
				end
			elseif unitID_class == "DRUID" then 
				local _, power = UnitPowerType(unitID)
				return power == "RAGE" or self(unitID):HasBuffs(tankBuffsOrCanBeTank) > 0
			elseif unitID_class == "WARRIOR" then				
				local _, offhand = UnitAttackSpeed(unitID)
				-- 1h+shield ensures he's friendly tank
				if offhand == nil and not isEnemy and A_GetUnitItem and A_GetUnitItem(unitID, CONST.INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD) then -- don't byPassDistance
					return true
				end
				
				if self(unitID):HasBuffs(tankBuffsOrCanBeTank) == 0 and (A.IsInPvP or self(unitID):ThreatSituation(strjoin("", unitID, "target")) < 3) then
					return false
					-- ↓↓↓ if warrior in Defensive Stance or has threat he can be tank even without shield equipped aka fury tank, then we will use generic approach below to recognize it ↓↓↓
				end
			elseif unitID_class == "MONK" then
				local _, power = UnitPowerType(unitID)
				local _, offhand = UnitAttackSpeed(unitID)
				if power == "MANA" or offhand ~= nil then
					return false
				elseif UnitStagger and UnitStagger(unitID) ~= 0 then
					return true
				end				
			elseif unitID_class == "DEATHKNIGHT" then
				local _, offhand = UnitAttackSpeed(unitID)
				return offhand == nil and self(unitID):HasBuffs(tankBuffsOrCanBeTank) > 0
			end
			
			if not A.IsInPvP then 
				local unitIDtarget = strjoin("", unitID, "target")
				if UnitIsUnit(unitID, strjoin("", unitIDtarget, "target")) and self(unitIDtarget):IsBoss() then 
					return true 
				end
			end					
			
			local taken_dmg 				= CombatTracker:GetDMG(unitID)
			local done_dmg					= CombatTracker:GetDPS(unitID)
			local done_hps					= CombatTracker:GetHPS(unitID)
			return taken_dmg > done_dmg and taken_dmg > done_hps
		end 
	end, "UnitID"),	
	IsTankClass								= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return InfoClassCanBeTank[self(unitID):Class()] and true -- don't touch true otherwise it may return table or number because of tank buffs
	end, "UnitID"),	
	IsDamager								= Cache:Pass(function(self, class)    
		-- @return boolean 
		local unitID 						= self.UnitID
		local unitID_class 					= class or self(unitID):Class()
		local isEnemy 						= self(unitID):IsEnemy()
	    if isEnemy then
			if TeamCacheEnemyDAMAGER[unitID] or self(unitID):HasSpec(InfoSpecIs.DAMAGER) then
				return true
			elseif BuildToC >= 50500 and (A.Zone == "pvp" or A.Zone == "arena") then
				return false
			end
		else
			if TeamCacheFriendlyDAMAGER[unitID] then
				return true
			end
			
			local role = UnitGroupRolesAssigned(unitID)
			if role == "DAMAGER" or (UnitIsUnit(unitID, "player") and self(unitID):HasSpec(InfoSpecIs.DAMAGER)) then
				return true
			elseif role and role ~= "NONE" then
				return false
			elseif GetPartyAssignment("maintank", unitID) then
				return false
			end
		end
		
		-- Fallback
		if unitID_class == "PALADIN" then 
			local _, power = UnitPowerType(unitID)
			local _, offhand = UnitAttackSpeed(unitID)
			if power ~= "MANA" or offhand ~= nil then
				return true
			else
				local tankBuff = self(unitID):HasBuffs(InfoClassCanBeTank[unitID_class])
				if tankBuff > 0 then 
					-- Protection
					if not A_GetUnitItem or isEnemy or A_GetUnitItem(unitID, CONST.INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD, nil, true) then -- byPassDistance, so if buff is up he's more likely tank
						return false
					end
				else
					-- Retribution
					if not isEnemy and A_GetUnitItem and not A_GetUnitItem(unitID, CONST.INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD) then
						return true
					end
				end
			end			
		elseif unitID_class == "DRUID" then 			
			if self(unitID):HasBuffs(InfoClassCanBeTank[unitID_class]) > 0 then
				return false
			end
			
			local _, power = UnitPowerType(unitID)
			return power == "ENERGY" or power == "LUNARPOWER" 
		elseif unitID_class == "MONK" then
			local _, power = UnitPowerType(unitID)
			local _, offhand = UnitAttackSpeed(unitID)
			if power == "MANA" then
				return false
			elseif offhand ~= nil or (UnitStagger and UnitStagger(unitID) == 0) then
				return true
			end
		elseif unitID_class == "PRIEST" then
			local _, power = UnitPowerType(unitID)
			if power ~= "MANA" then
				return true
			end
		elseif unitID_class == "SHAMAN" then
			local _, power = UnitPowerType(unitID)
			local _, offhand = UnitAttackSpeed(unitID)
			if power ~= "MANA" or offhand ~= nil then
				return true
			end	
		end
		
		if not A.IsInPvP then 
			local unitIDtarget = strjoin("", unitID, "target")
			if UnitIsUnit(unitID, strjoin("", unitIDtarget, "target")) and self(unitIDtarget):IsBoss() then 
				return false 
			end
		end		
		
											-- bypass it in PvP 
		local taken_dmg 					= (isEnemy and self(unitID):IsPlayer() and 0) or CombatTracker:GetDMG(unitID) 
		local done_dmg						= CombatTracker:GetDPS(unitID)
		local done_hps						= CombatTracker:GetHPS(unitID)
		return done_dmg > taken_dmg and done_dmg > done_hps 
	end, "UnitID"),	
	IsMelee 								= Cache:Pass(function(self, class) 
		-- @return boolean 
		local unitID 						= self.UnitID
		local unitID_class 					= class or self(unitID):Class()		
		if InfoClassCanBeMelee[unitID_class] then
			local isEnemy 					= self(unitID):IsEnemy()
			if isEnemy then
				if TeamCacheEnemyDAMAGER_MELEE[unitID] or self(unitID):HasSpec(InfoSpecIs.MELEE) then
					return true
				elseif BuildToC >= 50500 and (A.Zone == "pvp" or A.Zone == "arena") then
					return false
				end
			else
				if TeamCacheFriendlyDAMAGER_MELEE[unitID] then
					return true
				end

				local role = UnitGroupRolesAssigned(unitID)
				if role == "TANK" or (role == "DAMAGER" and (unitID_class == "PALADIN" or unitID_class == "MONK")) or GetPartyAssignment("maintank", unitID) or (UnitIsUnit(unitID, "player") and self(unitID):HasSpec(InfoSpecIs.MELEE)) then
					return true
				elseif role == "HEALER" then
					return false
				end
			end 
			
			-- Fallback
			if unitID_class == "PALADIN" then	
				local _, power = UnitPowerType(unitID)
				local _, offhand = UnitAttackSpeed(unitID)
				if power ~= "MANA" or offhand ~= nil then
					return true
				else
					local tankBuff = self(unitID):HasBuffs(InfoClassCanBeTank[unitID_class])
					if tankBuff > 0 then 
						-- Protection
						if not A_GetUnitItem or isEnemy or A_GetUnitItem(unitID, CONST.INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD, nil, true) then -- byPassDistance, so if buff is up he's more likely tank
							return true
						end
					else
						-- Retribution
						if not isEnemy and A_GetUnitItem and not A_GetUnitItem(unitID, CONST.INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD) then
							return true
						end
						
															-- bypass it in PvP 
						local taken_dmg 					= (isEnemy and self(unitID):IsPlayer() and 0) or CombatTracker:GetDMG(unitID) 
						local done_dmg						= CombatTracker:GetDPS(unitID)
						local done_hps						= CombatTracker:GetHPS(unitID)
						return done_dmg > taken_dmg and done_dmg > done_hps 
					end
				end
			elseif unitID_class == "HUNTER" then
				return
				(
					self(unitID):GetSpellCounter(186270) > 0 or -- Raptor Strike
					self(unitID):GetSpellCounter(259387) > 0 or -- Mongoose Bite
					self(unitID):GetSpellCounter(190925) > 0 or -- Harpoon
					self(unitID):GetSpellCounter(259495) > 0    -- Firebomb
				)
			elseif unitID_class == "SHAMAN" then
				local _, offhand = UnitAttackSpeed(unitID)
				return offhand ~= nil
			elseif unitID_class == "MONK" then
				local _, power = UnitPowerType(unitID)
				local _, offhand = UnitAttackSpeed(unitID)
				if power == "MANA" then
					return false
				elseif offhand ~= nil or (UnitStagger and UnitStagger(unitID) > 0) then
					return true
				else
														-- bypass it in PvP 
					local taken_dmg 					= (isEnemy and self(unitID):IsPlayer() and 0) or CombatTracker:GetDMG(unitID) 
					local done_dmg						= CombatTracker:GetDPS(unitID)
					local done_hps						= CombatTracker:GetHPS(unitID)
					return done_dmg > taken_dmg and done_dmg > done_hps 
				end
			elseif unitID_class == "DRUID" then
				local _, power = UnitPowerType(unitID)
				return power == "ENERGY" or power == "RAGE"
			else 				
				return true -- Warrior, Rogue, DH, DK
			end
		end 
	end, "UnitID"),
	IsMeleeClass							= Cache:Pass(function(self)  
		-- @return boolean
		local unitID 						= self.UnitID
		return InfoClassCanBeMelee[self(unitID):Class()]
	end, "UnitID"),
	IsDead 									= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsDeadOrGhost(unitID) and not UnitIsFeignDeath(unitID)
	end, "UnitID"),
	IsGhost									= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsGhost(unitID)
	end, "UnitID"),
	IsPlayer								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsPlayer(unitID)
	end, "UnitID"),
	IsPet									= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return not UnitIsPlayer(unitID) and UnitPlayerControlled(unitID)
	end, "UnitID"),
	IsPlayerOrPet							= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsPlayer(unitID) or UnitPlayerControlled(unitID)
	end, "UnitID"),
	IsNPC									= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return not UnitPlayerControlled(unitID)
	end, "UnitID"),
	IsVisible								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsVisible(unitID)
	end, "UnitID"),
	IsExists 								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitExists(unitID)
	end, "UnitID"),
	IsNameplate								= Cache:Pass(function(self)
		-- @return boolean, nameplateUnitID or nil
		-- Note: Only enemy plates
		local unitID 						= self.UnitID
		for nameplateUnit in pairs(ActiveUnitPlates) do
			if UnitIsUnit(unitID, nameplateUnit) then
				return true, nameplateUnit
			end
		end
	end, "UnitID"),
	IsNameplateAny							= Cache:Pass(function(self)
		-- @return boolean, nameplateUnitID or nil
		-- Note: Any plates
		local unitID 						= self.UnitID
		for nameplateUnit in pairs(ActiveUnitPlatesAny) do
			if UnitIsUnit(unitID, nameplateUnit) then
				return true, nameplateUnit
			end
		end
	end, "UnitID"),
	IsConnected								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsConnected(unitID)
	end, "UnitID"),
	IsCharmed								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitIsCharmed(unitID)
	end, "UnitID"),
	IsMounted								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player")  then
			return Player:IsMounted()
		end
		return select(2, self(unitID):GetCurrentSpeed()) >= 200
	end, "UnitID"),
	IsMovingOut								= Cache:Pass(function(self, snap_timer)
		-- @return boolean
		-- snap_timer must be in miliseconds e.g. 0.2 or leave it empty, it's how often unit must be updated between snapshots to understand in which side he's moving
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then
			return true
		end

		local unitSpeed 					= self(unitID):GetCurrentSpeed()
		if unitSpeed > 0 then
			if unitSpeed == self("player"):GetCurrentSpeed() then
				return true
			end

			local GUID 						= UnitGUID(unitID)
			local _, min_range				= self(unitID):GetRange()
			if not InfoCacheMoveOut[GUID] then
				InfoCacheMoveOut[GUID] = {
					Snapshot 	= 1,
					TimeStamp 	= TMW.time,
					Range 		= min_range,
					Result 		= false,
				}
				return false
			end

			if TMW.time - InfoCacheMoveOut[GUID].TimeStamp <= (snap_timer or 0.2) then
				return InfoCacheMoveOut[GUID].Result
			end

			InfoCacheMoveOut[GUID].TimeStamp = TMW.time

			if min_range == InfoCacheMoveOut[GUID].Range then
				return InfoCacheMoveOut[GUID].Result
			end

			if min_range > InfoCacheMoveOut[GUID].Range then
				InfoCacheMoveOut[GUID].Snapshot = InfoCacheMoveOut[GUID].Snapshot + 1
			else
				InfoCacheMoveOut[GUID].Snapshot = InfoCacheMoveOut[GUID].Snapshot - 1
			end

			InfoCacheMoveOut[GUID].Range = min_range

			if InfoCacheMoveOut[GUID].Snapshot >= 3 then
				InfoCacheMoveOut[GUID].Snapshot = 2
				InfoCacheMoveOut[GUID].Result = true
				return true
			else
				if InfoCacheMoveOut[GUID].Snapshot < 0 then
					InfoCacheMoveOut[GUID].Snapshot = 0
				end
				InfoCacheMoveOut[GUID].Result = false
				return false
			end
		end
	end, "UnitGUID"),
	IsMovingIn								= Cache:Pass(function(self, snap_timer)
		-- @return boolean
		-- snap_timer must be in miliseconds e.g. 0.2 or leave it empty, it's how often unit must be updated between snapshots to understand in which side he's moving
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then
			return true
		end

		local unitSpeed 					= self(unitID):GetCurrentSpeed()
		if unitSpeed > 0 then
			if unitSpeed == self("player"):GetCurrentSpeed() then
				return true
			end

			local GUID 						= UnitGUID(unitID)
			local _, min_range				= self(unitID):GetRange()
			if not InfoCacheMoveIn[GUID] then
				InfoCacheMoveIn[GUID] = {
					Snapshot 	= 1,
					TimeStamp 	= TMW.time,
					Range 		= min_range,
					Result 		= false,
				}
				return false
			end

			if TMW.time - InfoCacheMoveIn[GUID].TimeStamp <= (snap_timer or 0.2) then
				return InfoCacheMoveIn[GUID].Result
			end

			InfoCacheMoveIn[GUID].TimeStamp = TMW.time

			if min_range == InfoCacheMoveIn[GUID].Range then
				return InfoCacheMoveIn[GUID].Result
			end

			if min_range < InfoCacheMoveIn[GUID].Range then
				InfoCacheMoveIn[GUID].Snapshot = InfoCacheMoveIn[GUID].Snapshot + 1
			else
				InfoCacheMoveIn[GUID].Snapshot = InfoCacheMoveIn[GUID].Snapshot - 1
			end

			InfoCacheMoveIn[GUID].Range = min_range

			if InfoCacheMoveIn[GUID].Snapshot >= 3 then
				InfoCacheMoveIn[GUID].Snapshot = 2
				InfoCacheMoveIn[GUID].Result = true
				return true
			else
				if InfoCacheMoveIn[GUID].Snapshot < 0 then
					InfoCacheMoveIn[GUID].Snapshot = 0
				end
				InfoCacheMoveIn[GUID].Result = false
				return false
			end
		end
	end, "UnitGUID"),
	IsMoving								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then
			return Player:IsMoving()
		else
			return self(unitID):GetCurrentSpeed() ~= 0
		end
	end, "UnitID"),
	IsMovingTime							= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then
			return Player:IsMovingTime()
		else
			local GUID						= UnitGUID(unitID)
			local isMoving  				= self(unitID):IsMoving()
			if isMoving then
				if not InfoCacheMoving[GUID] or InfoCacheMoving[GUID] == 0 then
					InfoCacheMoving[GUID] = TMW.time
				end
			else
				InfoCacheMoving[GUID] = 0
			end
			return (InfoCacheMoving[GUID] == 0 and -1) or TMW.time - InfoCacheMoving[GUID]
		end
	end, "UnitGUID"),
	IsStaying								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then
			return Player:IsStaying()
		else
			return self(unitID):GetCurrentSpeed() == 0
		end
	end, "UnitID"),
	IsStayingTime							= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		if UnitIsUnit(unitID, "player") then
			return Player:IsStayingTime()
		else
			local GUID						= UnitGUID(unitID)
			local isMoving  				= self(unitID):IsMoving()
			if not isMoving then
				if not InfoCacheStaying[GUID] or InfoCacheStaying[GUID] == 0 then
					InfoCacheStaying[GUID] = TMW.time
				end
			else
				InfoCacheStaying[GUID] = 0
			end
			return (InfoCacheStaying[GUID] == 0 and -1) or TMW.time - InfoCacheStaying[GUID]
		end
	end, "UnitGUID"),
	IsCasting 								= Cache:Wrap(function(self)
		-- @return:
		-- [1] castName (@string or @nil)
		-- [2] castStartedTime (@number or @nil)
		-- [3] castEndTime (@number or @nil)
		-- [4] notInterruptable (@boolean, false is able to be interrupted)
		-- [5] spellID (@number or @nil)
		-- [6] isChannel (@boolean)
		local unitID 						= self.UnitID
		local isChannel
		local castName, _, _, castStartTime, castEndTime, _, _, notInterruptable, spellID = UnitCastingInfo(unitID)
		if not castName then
			castName, _, _, castStartTime, castEndTime, _, notInterruptable, spellID = UnitChannelInfo(unitID)
			if castName then
				isChannel = true
			end
		end
		return castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel
	end, "UnitGUID"),
	IsCastingRemains						= Cache:Pass(function(self, argSpellID)
		-- @return:
		-- [1] Currect Casting Left Time (seconds) (@number)
		-- [2] Current Casting Left Time (percent) (@number)
		-- [3] spellID (@number)
		-- [4] spellName (@string)
		-- [5] notInterruptable (@boolean, false is able to be interrupted)
		-- [6] isChannel (@boolean)
		-- Nill-able: argSpellID
		local unitID 						= self.UnitID
		return select(2, self(unitID):CastTime(argSpellID))
	end, "UnitGUID"),
	CastTime								= Cache:Pass(function(self, argSpellID)
		-- @return:
		-- [1] Total Casting Time (@number)
		-- [2] Currect Casting Left (X -> 0) Time (seconds) (@number)
		-- [3] Current Casting Done (0 -> 100) Time (percent) (@number)
		-- [4] spellID (@number)
		-- [5] spellName (@string)
		-- [6] notInterruptable (@boolean, false is able to be interrupted)
		-- [7] isChannel (@boolean)
		-- Nill-able: argSpellID
		local unitID 						= self.UnitID
		local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = self(unitID):IsCasting()

		local TotalCastTime, CurrentCastTimeSeconds, CurrentCastTimeLeftPercent = 0, 0, 0
		if unitID == "player" and (argSpellID or spellID) then
			local s, _, _, castTime = GetSpellInfo(argSpellID or spellID) -- Must be real-time data
			if type(s) == "table" then
				castTime = s.castTime
			end
			TotalCastTime = (castTime or 0) / 1000
			CurrentCastTimeSeconds = TotalCastTime
		end

		if castName and (not argSpellID or A_GetSpellInfo(argSpellID) == castName) then
			TotalCastTime = (castEndTime - castStartTime) / 1000
			CurrentCastTimeSeconds = (TMW.time * 1000 - castStartTime) / 1000
			CurrentCastTimeLeftPercent = CurrentCastTimeSeconds * 100 / TotalCastTime
		end

		return TotalCastTime, TotalCastTime - CurrentCastTimeSeconds, CurrentCastTimeLeftPercent, spellID, castName, notInterruptable, isChannel
	end, "UnitGUID"),
	MultiCast 								= Cache:Pass(function(self, spells, range)
		-- @return
		-- [1] Total CastTime
		-- [2] Current CastingTime Left
		-- [3] Current CastingTime Percent (from 0% as start til 100% as finish)
		-- [4] SpellID
		-- [5] SpellName
		-- [6] notInterruptable (@boolean, false is able to be interrupted)
		-- Note: spells accepts only table or nil to get list from "CastBarsCC"
		local unitID 						= self.UnitID
		local castTotal, castLeft, castLeftPercent, castID, castName, notInterruptable = self(unitID):CastTime()

		if castLeft > 0 and (not range or self(unitID):GetRange() <= range) then
			local query = (type(spells) == "table" and spells) or AuraList.CastBarsCC
			for i = 1, #query do
				if castID == query[i] or castName == A_GetSpellInfo(query[i]) then
					return castTotal, castLeft, castLeftPercent, castID, castName, notInterruptable
				end
			end
		end

		return 0, 0, 0
	end, "UnitGUID"),
	IsControlAble 							= Cache:Pass(function(self, drCat, DR_Tick)
		-- @return boolean
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
		-- Nill-able: DR_Tick, if its nil function returns true whenever non-imun drCat is apply able
		local unitID 						= self.UnitID
		if not A.IsInPvP then
			return not self(unitID):IsBoss() and InfoControlAbleClassification[self(unitID):Classification()] and (not drCat or self(unitID):GetDR(drCat) > (drDiminishing or 0))
		else
			return not drCat or self(unitID):GetDR(drCat) > (drDiminishing or 0)
		end
	end, "UnitID"),
	-- CreatureType: Bool extenstion
	IsUndead								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return self(unitID):CreatureType() == "Undead"
	end, "UnitID"),
	IsDemon									= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return self(unitID):CreatureType() == "Demon"
	end, "UnitID"),
	IsHumanoid								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return self(unitID):CreatureType() == "Humanoid"
	end, "UnitID"),
	IsElemental								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return self(unitID):CreatureType() == "Elemental"
	end, "UnitID"),
	IsTotem 								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return self(unitID):CreatureType() == "Totem"
	end, "UnitID"),
	-- CreatureType: End
	IsDummy									= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		local _, _, _, _, _, npc_id 		= self(unitID):InfoGUID()
		return npc_id and InfoIsDummy[npc_id]
	end, "UnitID"),
	IsDummyPvP								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		local _, _, _, _, _, npc_id 		= self(unitID):InfoGUID()
		return npc_id and InfoIsDummyPvP[npc_id]
	end, "UnitID"),
	IsVoidTendril							= Cache:Pass(function(self)
		-- @return string
		-- Returns english name of the Void Tendril
		-- Note: DF+ Priest's talent Void Tendrils
		if BuildToC >= 100000 then
			local unitID 					= self.UnitID
			if self(unitID):IsNPC() and self(unitID):CreatureType() == "Not specified" then
				local npc_id				= select(6, self(unitID):InfoGUID())
				return npc_id and InfoIsVoidTendriln[npc_id]
			end
		end
	end, "UnitID"),
	IsCondemnedDemon						= Cache:Pass(function(self)
		-- @return string
		-- Returns english name of the Condemned Demon
		-- Note: Shadowlands+ "Fodder to the Flame" summoned NPC by Demon Hunter's Necrolord Covenant
		if BuildToC >= 90000 and PlayerClass == "DEMONHUNTER" then
			local unitID 					= self.UnitID
			if self(unitID):IsNPC() and self(unitID):IsDemon() then
				local npc_id				= select(6, self(unitID):InfoGUID())
				return npc_id and InfoIsCondemnedDemon[npc_id]
			end
		end
	end, "UnitID"),
	IsExplosives							= Cache:Pass(function(self)
		-- @return boolean
		-- Note: Legion+ dungeon 7+ key
		if InstanceInfo.KeyStone and InstanceInfo.KeyStone >= 7 then
			local unitID 					= self.UnitID
			local Name 						= UnitName(unitID)
			return Name and InfoExplosivesName[GameLocale] == Name
		end
	end, "UnitID"),
	IsIncorporealBeing						= Cache:Pass(function(self)
		-- @return boolean
		-- Note: DF 10.1+
		if InstanceInfo.KeyStone and InstanceInfo.KeyStone >= 7 then
			local unitID 					= self.UnitID
			local Name 						= UnitName(unitID)
			return Name and InfoIncorporealBeingName[GameLocale] == Name
		end
	end, "UnitID"),
	IsOrbOfAscendance						= Cache:Pass(function(self)
		-- @return boolean
		-- Note: TWW 11.0+
		if InstanceInfo.KeyStone and InstanceInfo.KeyStone >= 2 then
			local unitID 					= self.UnitID
			local Name 						= UnitName(unitID)
			return Name and InfoOrbOfAscendanceName[GameLocale] == Name
		end
	end, "UnitID"),
	IsCracklingShard						= Cache:Pass(function(self)
		-- @return boolean
		-- Note: 1580 is Ny'alotha - Vision of Destiny, patch 8.3
		local unitID 						= self.UnitID
		if A.ZoneID == 1580 and select(6, self(unitID):InfoGUID()) == 158327 then
			return true
		end
	end, "UnitID"),
	IsBoss 									= Cache:Pass(function(self)
	    -- @return boolean
		local unitID 						= self.UnitID
		local _, _, _, _, _, npc_id 		= self(unitID):InfoGUID()
		if npc_id and not InfoIsNotBoss[npc_id] then
			if InfoIsBoss[npc_id] or LibBossIDs[npc_id] or self(unitID):GetLevel() == -1 or UnitIsQuestBoss(unitID) or UnitEffectiveLevel(unitID) == -1 then
				return true
			else
				for i = 1, CONST.MAX_BOSS_FRAMES do
					if UnitIsUnit(unitID, "boss" .. i) then
						return true
					end
				end
			end
		end
	end, "UnitID"),
	ThreatSituation							= Cache:Pass(function(self, otherunit)
		-- @return number
		-- Returns: status (0 -> 3), percent of threat, value or threat
		-- Nill-able: otherunit
		local unitID 						= self.UnitID
		return UnitThreatSituation(unitID, otherunit or "target") or 0
	end, "UnitID"),
	IsTanking 								= Cache:Pass(function(self, otherunit, range)
		-- @return boolean
		-- Nill-able: otherunit, range
		local unitID 						= self.UnitID
		local ThreatThreshold 				= 3
		local ThreatSituation 				= self(unitID):ThreatSituation(otherunit or "target")
		return ((A.IsInPvP and UnitIsUnit(unitID, (otherunit or "target") .. "target")) or (not A.IsInPvP and ThreatSituation >= ThreatThreshold)) or self(unitID):IsTankingAoE(range)
	end, "UnitID"),
	IsTankingAoE 							= Cache:Pass(function(self, range)
		-- @return boolean
		-- Nill-able: range
		local unitID 						= self.UnitID
		local ThreatThreshold 				= 3
		for unit in pairs(ActiveUnitPlates) do
			local ThreatSituation 			= self(unitID):ThreatSituation(unit)
			if ((A.IsInPvP and UnitIsUnit(unitID, unit .. "target")) or (not A.IsInPvP and ThreatSituation >= ThreatThreshold)) and (not range or self(unit .. "target"):CanInterract(range)) then
				return true
			end
		end
	end, "UnitID"),
	IsPenalty								= Cache:Pass(function(self)
		-- @return boolean
		-- Note: Returns true if unit has penalty for healing or damage
		local unitID 						= self.UnitID
		local unitLvL						= self(unitID):GetLevel()
		return unitLvL > 0 and unitLvL < A.PlayerLevel - 10
	end, "UnitID"),
	GetLevel 								= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		return UnitLevel(unitID) or 0
	end, "UnitID"),
	GetCurrentSpeed 						= Cache:Wrap(function(self)
		-- @return number (current), number (max)
		local unitID 						= self.UnitID
		local current_speed, max_speed 		= GetUnitSpeed(unitID)
		return math_floor(current_speed / 7 * 100), math_floor(max_speed / 7 * 100)
	end, "UnitGUID"),
	GetMaxSpeed								= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		return select(2, self(unitID):GetCurrentSpeed())
	end, "UnitGUID"),
	GetTotalHealAbsorbs						= Cache:Pass(function(self)
		-- @return number
		-- Note:
		-- Returns the total amount of healing the unit can absorb without gaining health
		-- Abilities like Necrotic Strike cause affected units to absorb healing without gaining health
		local unitID 						= self.UnitID
		if BuildToC < 50500 then
			return 0
		end
		return UnitGetTotalHealAbsorbs(unitID) or 0
	end, "UnitID"),
	GetTotalHealAbsorbsPercent				= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		local maxHP							= self(unitID):HealthMax()
		if maxHP == 0 then
			return 0
		else
			return self(unitID):GetTotalHealAbsorbs() * 100 / maxHP
		end
	end, "UnitID"),
	-- Combat: Diminishing
	GetDR 									= Cache:Pass(function(self, drCat)
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
		local unitID 						= self.UnitID
		return CombatTracker:GetDR(unitID, drCat)
	end, "UnitID"),
	-- Combat: UnitCooldown
	GetCooldown								= Cache:Pass(function(self, spellID)
		-- @return number, number (remain cooldown time in seconds, start time stamp when spell was used and counter launched)
		local unitID 						= self.UnitID
		return UnitCooldown:GetCooldown(unitID, spellID)
	end, "UnitID"),
	GetMaxDuration							= Cache:Pass(function(self, spellID)
		-- @return number (max cooldown of the spell on a unit)
		local unitID 						= self.UnitID
		return UnitCooldown:GetMaxDuration(unitID, spellID)
	end, "UnitID"),
	GetUnitID								= Cache:Pass(function(self, spellID)
		-- @return unitID (who last casted spell) otherwise nil
		local unitID 						= self.UnitID
		return UnitCooldown:GetUnitID(unitID, spellID)
	end, "UnitID"),
	GetBlinkOrShrimmer						= Cache:Pass(function(self)
		-- @return number, number, number
		-- [1] Current Charges, [2] Current Cooldown, [3] Summary Cooldown
		local unitID 						= self.UnitID
		return UnitCooldown:GetBlinkOrShrimmer(unitID)
	end, "UnitID"),
	IsSpellInFly							= Cache:Pass(function(self, spellID)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitCooldown:IsSpellInFly(unitID, spellID) -- Retail has spellID
	end, "UnitID"),
	-- Combat: CombatTracker
	CombatTime 								= Cache:Pass(function(self)
		-- @return number, unitGUID
		local unitID 						= self.UnitID
		return CombatTracker:CombatTime(unitID)
	end, "UnitID"),
	GetLastTimeDMGX 						= Cache:Pass(function(self, x)
		-- @return number: taken amount in the last 'x' seconds
		local unitID 						= self.UnitID
		return CombatTracker:GetLastTimeDMGX(unitID, x)
	end, "UnitID"),
	GetRealTimeDMG							= Cache:Pass(function(self, index)
		-- @return number: taken total, hits, phys, magic, swing
		local unitID 						= self.UnitID
		if index then
			return select(index, CombatTracker:GetRealTimeDMG(unitID))
		else
			return CombatTracker:GetRealTimeDMG(unitID)
		end
	end, "UnitID"),
	GetRealTimeDPS 							= Cache:Pass(function(self, index)
		-- @return number: done total, hits, phys, magic, swing
		local unitID 						= self.UnitID
		if index then
			return select(index, CombatTracker:GetRealTimeDPS(unitID))
		else
			return CombatTracker:GetRealTimeDPS(unitID)
		end
	end, "UnitID"),
	GetDMG 									= Cache:Pass(function(self, index)
		-- @return number: taken total, hits, phys, magic
		local unitID 						= self.UnitID
		if index then
			return select(index, CombatTracker:GetDMG(unitID))
		else
			return CombatTracker:GetDMG(unitID)
		end
	end, "UnitID"),
	GetDPS 									= Cache:Pass(function(self, index)
		-- @return number: done total, hits, phys, magic
		local unitID 						= self.UnitID
		if index then
			return select(index, CombatTracker:GetDPS(unitID))
		else
			return CombatTracker:GetDPS(unitID)
		end
	end, "UnitID"),
	GetHEAL 								= Cache:Pass(function(self, index)
		-- @return number: taken total, hits
		local unitID 						= self.UnitID
		if index then
			return select(index, CombatTracker:GetHEAL(unitID))
		else
			return CombatTracker:GetHEAL(unitID)
		end
	end, "UnitID"),
	GetHPS 									= Cache:Pass(function(self, index)
		-- @return number: done total, hits
		local unitID 						= self.UnitID
		if index then
			return select(index, CombatTracker:GetHPS(unitID))
		else
			return CombatTracker:GetHPS(unitID)
		end
	end, "UnitID"),
	GetSchoolDMG							= Cache:Pass(function(self, index)
		-- @return number
		-- [1] Holy
		-- [2] Fire
		-- [3] Nature
		-- [4] Frost
		-- [5] Shadow
		-- [6] Arcane
		-- Note: By @player only!
		local unitID 						= self.UnitID
		if index then
			return select(index, CombatTracker:GetSchoolDMG(unitID))
		else
			return CombatTracker:GetSchoolDMG(unitID)
		end
	end, "UnitID"),
	GetSpellAmountX 						= Cache:Pass(function(self, spell, x)
		-- @return number: if was taken in the last 'x' seconds by 'spell'
		local unitID 						= self.UnitID
		return CombatTracker:GetSpellAmountX(unitID, spell, x)
	end, "UnitID"),
	GetSpellAmount 							= Cache:Pass(function(self, spell)
		-- @return number: taken last time by 'spell'
		local unitID 						= self.UnitID
		return CombatTracker:GetSpellAmount(unitID, spell)
	end, "UnitID"),
	GetSpellLastCast 						= Cache:Pass(function(self, spell)
		-- @return number, number
		-- time in seconds since last cast, timestamp of start
		local unitID 						= self.UnitID
		return CombatTracker:GetSpellLastCast(unitID, spell)
	end, "UnitID"),
	GetSpellCounter 						= Cache:Pass(function(self, spell)
		-- @return number (counter of total used 'spell' during all fight)
		local unitID 						= self.UnitID
		return CombatTracker:GetSpellCounter(unitID, spell)
	end, "UnitID"),
	GetAbsorb 								= Cache:Pass(function(self, spell)
		-- @return number: taken absorb total (or by specified 'spell')
		local unitID 						= self.UnitID
		return CombatTracker:GetAbsorb(unitID, spell)
	end, "UnitID"),
	TimeToDieX 								= Cache:Pass(function(self, x)
		-- @return number
		local unitID 						= self.UnitID
		return CombatTracker:TimeToDieX(unitID, x)
	end, "UnitID"),
	TimeToDie 								= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		return CombatTracker:TimeToDie(unitID)
	end, "UnitID"),
	TimeToDieMagicX 						= Cache:Pass(function(self, x)
		-- @return number
		local unitID 						= self.UnitID
		return CombatTracker:TimeToDieMagicX(unitID, x)
	end, "UnitID"),
	TimeToDieMagic							= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		return CombatTracker:TimeToDieMagic(unitID)
	end, "UnitID"),
	-- Combat: End
	GetIncomingResurrection					= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitHasIncomingResurrection(unitID)
	end, "UnitID"),
	GetIncomingHeals						= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		return UnitGetIncomingHeals(unitID) or 0
	end, "UnitID"),
	GetRange 								= Cache:Wrap(function(self)
		-- @return number (max), number (min)
		local unitID 						= self.UnitID
		local min_range, max_range 			= LibRangeCheck:GetRange(unitID)
		if not max_range then
			return huge, min_range or huge
		end

		-- Limit range to 60 if unitID is nameplated and max range over normal behavior
		if max_range > CONST.CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE and self(unitID):IsNameplateAny() then
			if min_range > CONST.CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE then
				min_range = CONST.CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE
			end
			return CONST.CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE, min_range
		end

	    return max_range, min_range
	end, "UnitGUID"),
	CanInterract							= Cache:Pass(function(self, range)
		-- @return boolean
		local unitID 						= self.UnitID
		local min_range 					= self(unitID):GetRange()

		-- Holy Paladin Talent Range buff +50%
		if self("player"):HasSpec(65) and self("player"):HasBuffs(214202, true) > 0 then
			range = range * 1.5
		end
		-- Moonkin and Restor +5 yards
		if self("player"):HasSpec(InfoSpecsMoonkinRestor) and A_IsTalentLearned(197488) then
			range = range + 5
		end
		-- Feral and Guardian +3 yards
		if self("player"):HasSpec(InfoSpecsFeralGuardian) and A_IsTalentLearned(197488) then
			range = range + 3
		end

		return min_range and min_range > 0 and range and min_range <= range
	end, "UnitID"),
	CanInterrupt							= Cache:Pass(function(self, kickAble, auras, minX, maxX)
		-- @return boolean
		-- Nill-able: kickAble, auras, minX, maxX
		local unitID 						= self.UnitID
		local castName, castStartTime, castEndTime, notInterruptable, spellID, isChannel = self(unitID):IsCasting()
		if castName and (not kickAble or not notInterruptable) then
			if auras and self(unitID):HasBuffs(auras) > 0 then
				return false
			end

			local GUID 						= UnitGUID(unitID)
			if not InfoCacheInterrupt[GUID] then
				InfoCacheInterrupt[GUID] = {}
			end

			if InfoCacheInterrupt[GUID].LastCast ~= castName then
				-- Soothing Mist
				if castName ~= A_GetSpellInfo(209525) then
					InfoCacheInterrupt[GUID].LastCast 	= castName
					InfoCacheInterrupt[GUID].Timer 		= math_random(minX or 34, maxX or 68)
				else
					InfoCacheInterrupt[GUID].LastCast 	= castName
					InfoCacheInterrupt[GUID].Timer 		= math_random(minX or 7, maxX or 13)
				end
			end

			local castPercent = ((TMW.time * 1000) - castStartTime) * 100 / (castEndTime - castStartTime)
			return castPercent >= InfoCacheInterrupt[GUID].Timer
		end
	end, "UnitID"),
	CanCooperate							= Cache:Pass(function(self, otherunit)
		-- @return boolean
		local unitID 						= self.UnitID
		return UnitCanCooperate(unitID, otherunit)
	end, "UnitID"),
	HasSpec									= Cache:Pass(function(self, specID)	
		-- @return boolean 
		local unitID 						= self.UnitID
		
		if UnitIsUnit(unitID, "player") then
			local playerSpecID = A.PlayerSpec
			if type(specID) == "table" then
				for i = 1, #specID do if specID[i] == playerSpecID then return true end end
			else
				return specID == playerSpecID
			end
		else
			local name, server = UnitName(unitID)
			if not name then
				return		
			elseif server then
				name = strjoin("-", name, server)
			end
			
			if UnitSpecsMap[name] then
				if type(specID) == "table" then
					for i = 1, #specID do if specID[i] == UnitSpecsMap[name] then return true end end
				else
					return specID == UnitSpecsMap[name]
				end
			else
				local unitClass = self(unitID):Class()
				
				-- Search by auras 
				local unitClassBuffs = InfoClassSpecBuffs[unitClass]
				if unitClassBuffs then 
					local unitSpecBuffs
					if type(specID) == "table" then
						for i = 1, #specID do
							unitSpecBuffs = unitClassBuffs[specID[i]]
							if unitSpecBuffs and self(unitID):HasBuffs(unitSpecBuffs) > 0 then 
								return true 
							end 
						end  
					else
						unitSpecBuffs = unitClassBuffs[specID]
						if unitSpecBuffs and self(unitID):HasBuffs(unitSpecBuffs) > 0 then 
							return true 
						end 
					end 
				end 
				
				-- Search by used spells 
				-- Note: Used in PvP for any players. Doesn't work in PvE mode.
				local unitClassSpells = InfoClassSpecSpells[unitClass]
				if unitClassSpells then 
					local unitSpecSpells
					if type(specID) == "table" then
						for i = 1, #specID do
							unitSpecSpells = unitClassSpells[specID[i]]
							
							if unitSpecSpells then 
								if type(unitSpecSpells) == "table" then 
									for _, spellID in ipairs(unitSpecSpells) do 
										if self(unitID):GetSpellCounter(spellID) > 0 then 
											return true 
										end 
									end 
								else 
									if self(unitID):GetSpellCounter(unitSpecSpells) > 0 then 
										return true 
									end 
								end 
							end 
						end  
					else
						unitSpecSpells = unitClassSpells[specID]
						if unitSpecSpells then 
							if type(unitSpecSpells) == "table" then 
								for _, spellID in ipairs(unitSpecSpells) do 
									if self(unitID):GetSpellCounter(spellID) > 0 then 
										return true 
									end 
								end 
							else 
								if self(unitID):GetSpellCounter(unitSpecSpells) > 0 then 
									return true 
								end 
							end 
						end 
					end 
				end 				
			end
		end
	end, "UnitID"),
	HasFlags 								= Cache:Pass(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
	    return self(unitID):HasBuffs(InfoFlagsBuffs) > 0 or self(unitID):HasDeBuffs(121177) > 0
	end, "UnitID"),
	Health									= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
	    return UnitHealth(unitID)
	end, "UnitID"),
	HealthMax								= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
	    return UnitHealthMax(unitID)
	end, "UnitID"),
	HealthDeficit							= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
	    return self(unitID):HealthMax() - self(unitID):Health()
	end, "UnitID"),
	HealthDeficitPercent					= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		local maxHP							= self(unitID):HealthMax()
		if maxHP == 0 then
			return 0 						-- Fix beta / ptr "Division by zero"
		else
			return self(unitID):HealthDeficit() * 100 / maxHP
		end
	end, "UnitID"),
	HealthPercent							= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		local maxHP							= self(unitID):HealthMax()
		if maxHP == 0 then
			return 0 						-- Fix beta / ptr "Division by zero"
		else
			return self(unitID):Health() * 100 / maxHP
		end
	end, "UnitID"),
	HealthPercentLosePerSecond				= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		local maxHP							= self(unitID):HealthMax()
		if maxHP == 0 then
			return 0 						-- Fix beta / ptr "Division by zero"
		else
			return math_max((self(unitID):GetDMG() * 100 / maxHP) - (self(unitID):GetHEAL() * 100 / maxHP), 0)
		end
	end, "UnitID"),
	HealthPercentGainPerSecond				= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
		local maxHP							= self(unitID):HealthMax()
		if maxHP == 0 then
			return 0 						-- Fix beta / ptr "Division by zero"
		else
			return math_max((self(unitID):GetHEAL() * 100 / maxHP) - (self(unitID):GetDMG() * 100 / maxHP), 0)
		end
	end, "UnitID"),
	Power									= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
	    return UnitPower(unitID)
	end, "UnitID"),
	PowerType								= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
	    return select(2, UnitPowerType(unitID))
	end, "UnitID"),
	PowerMax								= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
	    return UnitPowerMax(unitID)
	end, "UnitID"),
	PowerDeficit							= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
	    return self(unitID):PowerMax() - self(unitID):Power()
	end, "UnitID"),
	PowerDeficitPercent						= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
	    return self(unitID):PowerDeficit() * 100 / self(unitID):PowerMax()
	end, "UnitID"),
	PowerPercent							= Cache:Pass(function(self)
		-- @return number
		local unitID 						= self.UnitID
	    return self(unitID):Power() * 100 / self(unitID):PowerMax()
	end, "UnitID"),
	AuraTooltipNumberByIndex				= Cache:Wrap(function(self, spell, filter, caster, byID, kindKey, requestedIndex)
		-- @return number
		-- Arguments
		-- kindKey @string "applications"|"isStealable"|"sourceUnit"|"isNameplateOnly"|"isHelpful"|"name"|"canApplyAura"|"isHarmful"|"isRaid"|"timeMod"|"auraInstanceID"|"nameplateShowAll"|"nameplateShowPersonal"|"icon"|"points"(returns table)|"isFromPlayerOrPlayerPet"|"expirationTime"|"duration"|"isBossAura"|"spellId"
		-- 		This argument used to identify instance of aura on tooltip (can be 2+ identical auras applied but with different attributes, example: procs from same weapon enchants on both hands) 
		--
		-- requestedIndex @number 
		--		This argument selects number by using index on tooltip (can return 0 on index which is not supposed to be zero, just skipping such index by adding +1 will help)
		-- Nill-able: filter, byID, kindKey, requestedIndex
		local unitID 						= self.UnitID
		local filter 						= filter or "HELPFUL"
		local auraData, foundData, name 
		for i = 1, huge do
			auraData = UnitAura(unitID, i, filter)
			if not auraData then 
				break 
			elseif IsAuraEqual(auraData.name, auraData.spellId, AssociativeTables[spell], byID) then
				foundData = auraData
				name = strlowerCache[auraData.name]
				break
			end
		end
				
		if foundData then 
			-- Since LARGE_NUMBER_SEPERATOR is no longer correct and TMW has no fix for this we will use AuraTooltipNumberPacked function by index for now instead of AuraTooltipNumber
			local kindKey = kindKey or (filter ~= "HELPFUL" and "isHarmful") or "isHelpful"
			local requestedIndex = requestedIndex or 1
			return AuraTooltipNumberPacked(unitID, name, kindKey, caster, requestedIndex)
		end 
		
		return 0
	end, "UnitGUID"),
	AuraVariableNumber						= Cache:Wrap(function(self, spell, filter, caster, byID)
		-- @return number
		-- Nill-able: filter, caster, byID
		local unitID 						= self.UnitID
		local filter 						= filter or "HELPFUL"
		local auraData, foundData
		for i = 1, huge do
			auraData = UnitAura(unitID, i, filter)
			if not auraData then 
				break 
			elseif IsAuraEqual(auraData.name, auraData.spellId, AssociativeTables[spell], byID) and (not caster or UnitIsUnit("player", auraData.sourceUnit)) then
				foundData = auraData
				break
			end
		end
		
		if foundData then 
			for i = 1, #foundData.points do
				local v = foundData.points[i]
				if v and v > 0 then return v end
			end
		end
		
		return 0
	end, "UnitGUID"),
	DeBuffCyclone 							= Cache:Pass(function(self, customGUID)
		-- @return number
		-- Note: Supports Banish
		local unitID 						= self.UnitID
		local unitGUID 						= customGUID or UnitGUID(unitID)

		if InfoCycloneGUIDs[unitGUID] then
			local _, auraData
			for i = 1, huge do
				auraData = UnitAura(unitID, i, "HARMFUL")
				if not auraData then
					break
				elseif InfoCycloneSpellName[auraData.name] then
					return auraData.expirationTime == 0 and huge or auraData.expirationTime - TMW.time
				end
			end
		end

		return 0
	end, "UnitID"),
	--[[HasDeBuffs 								= Cache:Pass(function(self, spell, caster, byID)
		-- @return number, number
		-- current remain, total applied duration
		-- Sorting method
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID
        return self(unitID):SortDeBuffs(spell, caster, byID or IsMustBeByID[spell])
    end, "UnitID"),]]
	SortDeBuffs								= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number, number
		-- Returns sorted by highest and limited by 1-3 firstly found: current remain, total applied duration
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID
		local filter
		if caster then
			filter = "HARMFUL PLAYER"
		else
			filter = "HARMFUL"
		end
		local remain_dur, total_dur 		= 0, 0

		local c = 0
		local _, auraData
		for i = 1, huge do
			auraData = UnitAura(unitID, i, filter)

			if not auraData then break
			elseif IsAuraEqual(auraData.name, auraData.spellId, AssociativeTables[spell], byID) then
				local current_dur = auraData.expirationTime == 0 and huge or auraData.expirationTime - TMW.time
				if current_dur > remain_dur then
					c = c + 1
					remain_dur = current_dur
					total_dur = auraData.duration

					if remain_dur == huge or c >= (type(spell) == "table" and 3 or 1) then
						break
					end
				end
			end
		end

		return remain_dur, total_dur
    end, "UnitGUID"),
	HasDeBuffsStacks						= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID
		local filter
		if caster then
			filter = "HARMFUL PLAYER"
		else
			filter = "HARMFUL"
		end

		local _, auraData
		for i = 1, huge do
			auraData = UnitAura(unitID, i, filter)
			if not auraData then
				break
			elseif IsAuraEqual(auraData.name, auraData.spellId, AssociativeTables[spell], byID) then
				return auraData.applications == 0 and 1 or auraData.applications
			end
		end

		return 0
	end, "UnitGUID"),
	-- Pandemic Threshold
	PT										= Cache:Wrap(function(self, spell, debuff, byID)
		-- @return boolean
		-- Note: If duration remains <= 30% only for auras applied by @player
		-- Nill-able: debuff, byID
		local unitID 						= self.UnitID
		local filter
		if debuff then
			filter = "HARMFUL PLAYER"
		else
			filter = "HELPFUL"
		end

		local duration = 0
		local _, auraData
		for i = 1, huge do
			auraData = UnitAura(unitID, i, filter)
			if not auraData then
				break
			elseif IsAuraEqual(auraData.name, auraData.spellId, AssociativeTables[spell], byID) then
				duration = auraData.expirationTime == 0 and 1 or ((auraData.expirationTime - TMW.time) / auraData.duration)
				if duration <= 0.3 then
					return true
				end
			end
		end

		return duration <= 0.3
	end, "UnitGUID"),
	HasBuffs 								= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number, number
		-- current remain, total applied duration
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID
		local filter 						= "HELPFUL"
		if caster then
			filter = "HELPFUL"
		end
		local _, auraData
		for i = 1, huge do
			auraData = UnitAura(unitID, i, filter)
			if not auraData then break end
			if IsAuraEqual(auraData.name, auraData.spellId, AssociativeTables[spell], byID) then
				return auraData.expirationTime == 0 and huge or auraData.expirationTime - TMW.time, auraData.duration
			end
		end
		return 0, 0
	end, "UnitGUID"),
	SortBuffs 								= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number, number
		-- Returns sorted by highest: current remain, total applied duration
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID
		local filter 						= "HELPFUL"
		if caster then
			filter = "HELPFUL"
		end
		local remain_dur, total_dur 		= 0, 0

		local _, auraData
		for i = 1, huge do
			auraData = UnitAura(unitID, i, filter)
			if not auraData then
				break
			elseif IsAuraEqual(auraData.name, auraData.spellId, AssociativeTables[spell], byID) then
				local current_dur = auraData.expirationTime == 0 and huge or auraData.expirationTime - TMW.time
				if current_dur > remain_dur then
					remain_dur, total_dur = current_dur, auraData.duration
					if remain_dur == huge then
						break
					end
				end
			end
		end
		return remain_dur, total_dur
	end, "UnitGUID"),
	HasBuffsStacks 							= Cache:Wrap(function(self, spell, caster, byID)
		-- @return number
		-- Nill-able: caster, byID
		local unitID 						= self.UnitID
		local filter 						= "HELPFUL"
		if caster then
			filter = "HELPFUL"
		end

		local _, auraData
		for i = 1, huge do
			auraData = UnitAura(unitID, i, filter)
			if not auraData then
				break
			elseif IsAuraEqual(auraData.name, auraData.spellId, AssociativeTables[spell], byID) then
				return auraData.applications == 0 and 1 or auraData.applications
			end
		end
		return 0
	end, "UnitGUID"),
	WithOutKarmed 							= Cache:Wrap(function(self)
		-- @return boolean
		local unitID 						= self.UnitID

		if self(unitID):IsEnemy() then
			if TeamCacheFriendly.Size > 0 and self(unitID):HasBuffs(122470) > 0 then
				for i = 1, TeamCacheFriendly.MaxSize do
					local member = TeamCacheFriendlyIndexToPLAYERs[i]
					-- Forbearance players
					if member and self(member):HasDeBuffs(25771) >= 20 then
						return true
					end

					member = TeamCacheFriendlyIndexToPETs[i]
					-- Forbearance pets
					if member and self(member):HasDeBuffs(25771) >= 20 then
						return true
					end
				end

				return false
			end
		else
			local arena
			if TeamCacheEnemy.Size > 0 and self(unitID):HasBuffs(122470) > 0 then
				for i = 1, TeamCacheEnemy.MaxSize do
					arena = TeamCacheEnemyIndexToPLAYERs[i]
					-- Forbearance players
					if arena and self(arena):HasDeBuffs(25771) >= 20 then
						return true
					end

					arena = TeamCacheEnemyIndexToPETs[i]
					-- Forbearance pets
					if arena and self(arena):HasDeBuffs(25771) >= 20 then
						return true
					end
				end

				return false
			end
		end

		return true
	end, "UnitGUID"),
	IsFocused 								= Cache:Wrap(function(self, specs, burst, deffensive, range)
		-- @return boolean
		-- Nill-able: specs, burst, deffensive, range
		local unitID 						= self.UnitID

		if self(unitID):IsEnemy() then
			if next(TeamCacheFriendlyDAMAGER) then
				local member
				for member in pairs(TeamCacheFriendlyDAMAGER) do
					if UnitIsUnit(member .. "target", unitID)
					and not UnitIsUnit(member, "player")
					and (not specs or 		(specs == "MELEE" and self(member):IsMelee()))
					and (not burst or 		self(member):HasBuffs("DamageBuffs") > 2)
					and (not deffensive or 	self(unitID):HasBuffs("DeffBuffs") < 2)
					and (not range or 		self(member):GetRange() <= range) then
						return true
					end
				end
			end
		else
			local arena
			local specsmap = (specs and InfoSpecIs[specs]) or specs or false
			if next(TeamCacheEnemyDAMAGER) then
				for arena in pairs(TeamCacheEnemyDAMAGER) do
					if UnitIsUnit(arena .. "target", unitID)
					and (not specsmap or 	self(arena):HasSpec(specsmap))
					and (not burst or 		self(arena):HasBuffs("DamageBuffs") > 2)
					and (not deffensive or 	self(unitID):HasBuffs("DeffBuffs") < 2)
					and (not range or 		self(arena):GetRange() <= range) then
						return true
					end
				end
			else
				for arena in pairs(ActiveUnitPlates) do
					if UnitIsUnit(arena .. "target", unitID)
					and (not specsmap or 	self(arena):HasSpec(specsmap))
					and (not burst or 		self(arena):HasBuffs("DamageBuffs") > 2)
					and (not deffensive or 	self(unitID):HasBuffs("DeffBuffs") < 2)
					and (not range or 		self(arena):GetRange() <= range) then
						return true
					end
				end
			end
		end
	end, "UnitGUID"),
	IsExecuted 								= Cache:Wrap(function(self)
		-- @return boolean
		local unitID 						= self.UnitID

		if self(unitID):IsEnemy() then
			return self(unitID):TimeToDieX(20) <= A_GetGCD() + A_GetCurrentGCD()
		else
			if next(TeamCacheEnemyDAMAGER_MELEE) and self(unitID):TimeToDieX(20) <= A_GetGCD() + A_GetCurrentGCD() then
				for arena in pairs(TeamCacheEnemyDAMAGER_MELEE) do
					if self(arena):HasSpec(InfoSpecsWithExecute) and UnitIsUnit(arena .. "target", unitID) and self(arena):Power() >= 20 and (not UnitIsUnit(unitID, "player") or self(arena):GetRange() < 7) then
						return true
					end
				end
			end
		end
	end, "UnitGUID"),
	UseBurst 								= Cache:Wrap(function(self, pBurst)
		-- @return boolean
		-- Nill-able: pBurst
		local unitID 						= self.UnitID

		if self(unitID):IsEnemy() then
			return self(unitID):IsPlayer() and
			(
				A.Zone == str_none or
				self(unitID):TimeToDieX(25) <= A_GetGCD() * 4 or
				(
					self(unitID):IsHealer() and
					(
						(
							self(unitID):CombatTime() > 5 and
							self(unitID):TimeToDie() <= 10 and
							self(unitID):HasBuffs("DeffBuffs") == 0
						) or
						self(unitID):HasDeBuffs("Silenced") >= A_GetGCD() * 2 or
						self(unitID):HasDeBuffs("Stuned") >= A_GetGCD() * 2
					)
				) or
				self(unitID):IsFocused(nil, true) or
				A_EnemyTeam("HEALER"):GetCC() >= A_GetGCD() * 3 or
				(
					pBurst and
					self("player"):HasBuffs("DamageBuffs") >= A_GetGCD() * 3
				)
			)
		elseif A.IamHealer then
			-- For HealingEngine as Healer
			return self(unitID):IsPlayer() and
			(
				self(unitID):IsExecuted() or
				(
					A.IsInPvP and
					(
						(
							self(unitID):HasFlags() and
							self(unitID):CombatTime() > 0 and
							self(unitID):GetRealTimeDMG() > 0 and
							self(unitID):TimeToDie() <= 14 and
							(
								self(unitID):TimeToDie() <= 8 or
								self(unitID):HasBuffs("DeffBuffs") < 1
							)
						) or
						(
							self(unitID):IsFocused(nil, true) and
							(
								self(unitID):TimeToDie() <= 10 or
								self(unitID):HealthPercent() <= 70
							)
						)
					)
				)
			)
		end
	end, "UnitGUID"),
	UseDeff 								= Cache:Wrap(function(self)
		-- @return boolean
		local unitID 						= self.UnitID
		return
		(
			self(unitID):IsExecuted() or
			self(unitID):IsFocused(nil, true) or
			(
				self(unitID):TimeToDie() < 8 and
				self(unitID):IsFocused()
			) or
			self(unitID):HasDeBuffs("DamageDeBuffs") > 5
		)
	end, "UnitGUID"),
})
A.Unit.HasDeBuffs = A.Unit.SortDeBuffs

function A.Unit:New(UnitID, Refresh)
	if not UnitID then
		local error_snippet = debugstack():match("%p%l+%s\"?%u%u%u%s%u%l.*")
		if error_snippet then
			error("Unit.lua Action.Unit():.. was used with 'nil' unitID. Found problem in TMW snippet here:" .. error_snippet, 0)
		else
			error("Unit.lua Action.Unit():.. was used with 'nil' unitID.\n" .. debugstack())
		end
	end
	self.UnitID 	= UnitID
	self.Refresh 	= Refresh
end

------------------------------------------------------------------------------- -- STOPPED HERE, For UNIT need to check self() how it will works
-- API: FriendlyTeam
-------------------------------------------------------------------------------
A.FriendlyTeam = PseudoClass({
	-- Note: Return field 'unitID' will return "none" if is not found
	-- Note: If 'ROLE' specified then it will except "player", otherwise will include
	GetUnitID 								= Cache:Pass(function(self, range)
		-- @return string
		-- Nill-able: range
		local ROLE 							= self.ROLE

		if ROLE then
			if TeamCacheFriendly[ROLE] then
				for member in pairs(TeamCacheFriendly[ROLE]) do
					if not A_Unit(member):IsDead() and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
						return member
					end
				end
			end
		else
			if TeamCacheFriendly.Type then
				local member
				for i = 1, TeamCacheFriendly.MaxSize do
					member = TeamCacheFriendlyIndexToPLAYERs[i]
					if member and not A_Unit(member):IsDead() and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
						return member
					end
				end
			end
		end

		return str_none
	end, "ROLE"),
	GetCC 									= Cache:Wrap(function(self, spells)
		-- @return number, unitID
		-- Nill-able: spells
		local ROLE 							= self.ROLE
		local duration, member

		if TeamCacheFriendly.Size <= 1 then
			member = "player"
			if A_Unit(member):Role(ROLE) then
				if spells then
					duration = A_Unit(member):HasDeBuffs(spells)
					if duration ~= 0 then
						return duration, member
					end
				else
					duration = A_Unit(member):InCC()
					if duration ~= 0 then
						return duration, member
					end
				end
			end

			return 0, str_none
		end

		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if spells then
					duration = A_Unit(member):HasDeBuffs(spells)
				else
					duration = A_Unit(member):InCC()
				end

				if duration ~= 0 then
					return duration, member
				end
			end
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member then
					if spells then
						duration = A_Unit(member):HasDeBuffs(spells)
					else
						duration = A_Unit(member):InCC()
					end

					if duration ~= 0 then
						return duration, member
					end
				end
			end

			if not TeamCacheFriendly.Type then
				duration = A_Unit("player"):HasDeBuffs(spells)
				if duration ~= 0 then
					return duration, "player"
				end
			end
		end

		return 0, str_none
	end, "ROLE"),
	GetBuffs 								= Cache:Wrap(function(self, spells, range, source)
		-- @return number, unitID
		-- Nill-able: range, source
		local ROLE 							= self.ROLE
		local duration, member

		if TeamCacheFriendly.Size <= 1 then
			if A_Unit("player"):Role(ROLE) then
				duration = A_Unit("player"):HasBuffs(spells, source)
				if duration ~= 0 then
					return duration, "player"
				end
			end
			return 0, str_none
		end

		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
					duration = A_Unit(member):HasBuffs(spells, source)
					if duration ~= 0 then
						return duration, member
					end
				end
			end
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
					duration = A_Unit(member):HasBuffs(spells, source)
					if duration ~= 0 then
						return duration, member
					end
				end
			end

			if not TeamCacheFriendly.Type then
				duration = A_Unit("player"):HasBuffs(spells, source)
				if duration ~= 0 then
					return duration, "player"
				end
			end
		end

		return 0, str_none
	end, "ROLE"),
	GetBuffsCount							= Cache:Wrap(function(self, spells, duration, source, byID)
		-- @return number
		-- Nill-able: duration, source, byID
		local ROLE = self.ROLE
		local total = 0
		local member

		if TeamCacheFriendly.Size <= 1 then
			if A_Unit("player"):Role(ROLE) then
				if A_Unit("player"):HasBuffs(spells, source, byID) > (duration or 0) then
					return 1
				end
			end
			return 0
		end

		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if A_Unit(member):HasBuffs(spells, source, byID) > (duration or 0) then
					total = total + 1
				end
			end
			return total
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and A_Unit(member):HasBuffs(spells, source, byID) > (duration or 0) then
					total = total + 1
				end
			end
			return total
		end
	end, "ROLE"),
	GetDeBuffs		 						= Cache:Wrap(function(self, spells, range)
		-- @return number, unitID
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local duration, member

		if TeamCacheFriendly.Size <= 1 then
			if A_Unit("player"):Role(ROLE) then
				duration = A_Unit("player"):HasDeBuffs(spells)
				if duration ~= 0 then
					return duration, "player"
				end
			end
			return 0, str_none
		end

		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
					duration = A_Unit(member):HasDeBuffs(spells)
					if duration ~= 0 then
						return duration, member
					end
				end
			end
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
					duration = A_Unit(member):HasDeBuffs(spells)
					if duration ~= 0 then
						return duration, member
					end
				end
			end

			if not TeamCacheFriendly.Type then
				duration = A_Unit("player"):HasDeBuffs(spells)
				if duration ~= 0 then
					return duration, "player"
				end
			end
		end

		return 0, str_none
	end, "ROLE"),
	GetDeBuffsCount							= Cache:Wrap(function(self, spells, duration, source, byID)
		-- @return number
		-- Nill-able: duration, source, byID
		local ROLE = self.ROLE
		local total = 0
		local member

		if TeamCacheFriendly.Size <= 1 then
			if A_Unit("player"):Role(ROLE) then
				if A_Unit("player"):HasDeBuffs(spells, source, byID) > (duration or 0) then
					return 1
				end
			end
			return 0
		end

		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if A_Unit(member):HasDeBuffs(spells, source, byID) > (duration or 0) then
					total = total + 1
				end
			end
			return total
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and A_Unit(member):HasDeBuffs(spells, source, byID) > (duration or 0) then
					total = total + 1
				end
			end
			return total
		end
	end, "ROLE"),
	GetTTD 									= Cache:Pass(function(self, count, seconds, range)
		-- @return boolean, counter, unitID
		-- Nill-able: range
		local ROLE 							= self.ROLE

		if TeamCacheFriendly.Size <= 1 then
			if A_Unit("player"):Role(ROLE) and A_Unit("player"):TimeToDie() <= seconds then
				return 1 >= count, 1, "player"
			end

			return false, 0, str_none
		end

		local counter = 0
		local member, lastmember
		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) and A_Unit(member):TimeToDie() <= seconds then
					counter = counter + 1
					if counter >= count then
						return true, counter, member
					end
					lastmember = member
				end
			end
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) and A_Unit(member):TimeToDie() <= seconds then
					counter = counter + 1
					if counter >= count then
						return true, counter, member
					end
					lastmember = member
				end
			end

			if not TeamCacheFriendly.Type and A_Unit("player"):TimeToDie() <= seconds then
				counter = counter + 1
				if counter >= count then
					return true, counter, "player"
				end
				lastmember = "player"
			end
		end

		return false, counter, lastmember or str_none
	end, "ROLE"),
	AverageTTD 								= Cache:Pass(function(self, range)
		-- @return number, number
		-- Returns average time to die of valid players in group, count of valid players in group
		-- Nill-able: range
		local ROLE 							= self.ROLE

		if TeamCacheFriendly.Size <= 1 then
			if A_Unit("player"):Role(ROLE) then
				return A_Unit("player"):TimeToDie(), 1
			end
			return 0, 0
		end

		local member
		local value, members				= 0, 0
		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
					value = value + A_Unit(member):TimeToDie()
					members = members + 1
				end
			end
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) then
					value = value + A_Unit(member):TimeToDie()
					members = members + 1
				end
			end

			if not TeamCacheFriendly.Type then
				value = value + A_Unit("player"):TimeToDie()
				members = members + 1
			end
		end

		if members > 0 then
			value = value / members
		end

		return value, members
	end, "ROLE"),
	MissedBuffs 							= Cache:Wrap(function(self, spells, source)
		-- @return boolean, unitID
		-- Nill-able: source
		local ROLE 							= self.ROLE

		if TeamCacheFriendly.Size <= 1 then
			if A_Unit("player"):Role(ROLE) then
				if A_Unit("player"):HasBuffs(spells, source) == 0 then
					return true, "player"
				end
			end
			return false, str_none
		end

		local member
		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if A_Unit(member):InRange() and not A_Unit(member):IsDead() and A_Unit(member):HasBuffs(spells, source) == 0 then
					return true, member
				end
			end
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and A_Unit(member):InRange() and not A_Unit(member):IsDead() and A_Unit(member):HasBuffs(spells, source) == 0 then
					return true, member
				end
			end

			if not TeamCacheFriendly.Type and A_Unit("player"):HasBuffs(spells, source) == 0 then
				return true, "player"
			end
		end

		return false, str_none
	end, "ROLE"),
	PlayersInCombat 						= Cache:Wrap(function(self, range, combatTime)
		-- @return boolean, unitID
		-- Nill-able: range, combatTime
		local ROLE 							= self.ROLE
		local member

		if TeamCacheFriendly.Size <= 1 then
			if A_Unit("player"):Role(ROLE) then
				if A_Unit("player"):CombatTime() > 0 and (not combatTime or A_Unit("player"):CombatTime() <= combatTime) then
					return true, "player"
				end
			end
			return false, str_none
		end

		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) and A_Unit(member):CombatTime() > 0 and (not combatTime or A_Unit(member):CombatTime() <= combatTime) then
					return true, member
				end
			end
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and A_Unit(member):InRange() and (not range or A_Unit(member):GetRange() <= range) and A_Unit(member):CombatTime() > 0 and (not combatTime or A_Unit(member):CombatTime() <= combatTime) then
					return true, member
				end
			end

			if not TeamCacheFriendly.Type and A_Unit("player"):CombatTime() > 0 and (not combatTime or A_Unit("player"):CombatTime() <= combatTime) then
				return true, "player"
			end
		end

		return false, str_none
	end, "ROLE"),
	HealerIsFocused 						= Cache:Wrap(function(self, burst, deffensive, range)
		-- @return boolean, unitID
		-- Nill-able: burst, deffensive, range
		-- Note: No 'ROLE' here

		for member in pairs(TeamCacheFriendlyHEALER) do
			if A_Unit(member):InRange() and A_Unit(member):IsFocused(nil, burst, deffensive, range) then
				return true, member
			end
		end

		return false, str_none
	end, "ROLE"),
	ArcaneTorrentMindControl 				= Cache:Pass(function(self)
		-- @return boolean, unitID
		-- Note: This is a buff type since MindControl is a buff
		-- Note: Doesn't checking "player" here since it's poinless
		local ROLE 							= self.ROLE
		local member

		if ROLE and TeamCacheFriendly[ROLE] then
			for member in pairs(TeamCacheFriendly[ROLE]) do
				if not UnitIsUnit(member, "player") and A_Unit(member):HasBuffs(605) > 0 and A_Unit(member):GetRange() <= 8 then
					return true, member
				end
			end
		else
			for i = 1, TeamCacheFriendly.MaxSize do
				member = TeamCacheFriendlyIndexToPLAYERs[i]
				if member and A_Unit(member):HasBuffs(605) > 0 and A_Unit(member):GetRange() <= 8 then
					return true, member
				end
			end
		end

		return false, str_none
	end, "ROLE"),
})

function A.FriendlyTeam:New(ROLE, Refresh)
    self.ROLE = ROLE
    self.Refresh = Refresh or 0.05
end

-------------------------------------------------------------------------------
-- API: EnemyTeam
-------------------------------------------------------------------------------
A.EnemyTeam = PseudoClass({
	-- Note: Return field 'unitID' will return "none" if is not found
	GetUnitID 								= Cache:Pass(function(self, range, specs)
		-- @return string
		-- Nill-able: range, specs
		local ROLE 							= self.ROLE

		if ROLE then
			if TeamCacheEnemy[ROLE] then
				for arena in pairs(TeamCacheEnemy[ROLE]) do
					if not A_Unit(arena):IsDead() and (not specs or A_Unit(arena):HasSpec(specs)) and (not range or A_Unit(arena):GetRange() <= range) then
						return arena
					end
				end
			end
		else
			if TeamCacheEnemy.Type then
				local arena
				for i = 1, TeamCacheEnemy.MaxSize do
					arena = TeamCacheEnemyIndexToPLAYERs[i]
					if arena and not A_Unit(arena):IsDead() and (not specs or A_Unit(arena):HasSpec(specs)) and (not range or (A_Unit(arena):GetRange() > 0 and A_Unit(arena):GetRange() <= range)) then
						return arena
					end
				end
			end
		end

		return str_none
	end, "ROLE"),
	GetCC 									= Cache:Wrap(function(self, spells)
		-- @return number, unitID
		-- Note: If 'ROLE' is "HEALER" then it will except healers if they are in @target
		-- Nill-able: spells
		local ROLE 							= self.ROLE
		local duration, arena

		if ROLE and TeamCacheEnemy[ROLE] then
			for arena in pairs(TeamCacheEnemy[ROLE]) do
				if ROLE ~= "HEALER" or not UnitIsUnit(arena, "target") then
					if spells then
						duration = A_Unit(arena):HasDeBuffs(spells)
						if duration ~= 0 then
							return duration, arena
						end
					else
						duration = A_Unit(arena):InCC()
						if duration ~= 0 then
							return duration, arena
						end
					end
				end
			end
		else
			for i = 1, TeamCacheEnemy.MaxSize do
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena then
					if spells then
						duration = A_Unit(arena):HasDeBuffs(spells)
						if duration ~= 0 then
							return duration, arena
						end
					else
						duration = A_Unit(arena):InCC()
						if duration ~= 0 then
							return duration, arena
						end
					end
				end
			end
		end

		return 0, str_none
	end, "ROLE"),
	GetBuffs 								= Cache:Wrap(function(self, spells, range, source)
		-- @return number, unitID
		-- Nill-able: range, source
		local ROLE 							= self.ROLE
		local duration, arena

		if ROLE and TeamCacheEnemy[ROLE] then
			for arena in pairs(TeamCacheEnemy[ROLE]) do
				if not range or A_Unit(arena):GetRange() <= range then
					duration = A_Unit(arena):HasBuffs(spells, source)
					if duration ~= 0 then
						return duration, arena
					end
				end
			end
		else
			for i = 1, TeamCacheEnemy.MaxSize do
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and (not range or A_Unit(arena):GetRange() <= range) then
					duration = A_Unit(arena):HasBuffs(spells, source)
					if duration ~= 0 then
						return duration, arena
					end
				end
			end
		end

		return 0, str_none
	end, "ROLE"),
	GetDeBuffs 								= Cache:Wrap(function(self, spells, range)
		-- @return number, unitID
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local duration, arena

		if ROLE and TeamCacheEnemy[ROLE] then
			for arena in pairs(TeamCacheEnemy[ROLE]) do
				if not range or A_Unit(arena):GetRange() <= range then
					duration = A_Unit(arena):HasDeBuffs(spells)
					if duration ~= 0 then
						return duration, arena
					end
				end
			end
		else
			for i = 1, TeamCacheEnemy.MaxSize do
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and (not range or A_Unit(arena):GetRange() <= range) then
					duration = A_Unit(arena):HasDeBuffs(spells)
					if duration ~= 0 then
						return duration, arena
					end
				end
			end
		end

		return 0, str_none
	end, "ROLE"),
	GetTTD 									= Cache:Pass(function(self, count, seconds, range)
		-- @return boolean, counter, unitID
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local counter = 0
		local arena, lastarena

		if ROLE and TeamCacheEnemy[ROLE] then
			for arena in pairs(TeamCacheEnemy[ROLE]) do
				if (not range or A_Unit(arena):GetRange() <= range) and A_Unit(arena):TimeToDie() <= seconds then
					counter = counter + 1
					if counter >= count then
						return true, counter, arena
					end
					lastarena = arena
				end
			end
		else
			for i = 1, TeamCacheEnemy.MaxSize do
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and (not range or A_Unit(arena):GetRange() <= range) and A_Unit(arena):TimeToDie() <= seconds then
					counter = counter + 1
					if counter >= count then
						return true, counter, arena
					end
					lastarena = arena
				end
			end
		end

		return false, counter, lastarena or str_none
	end, "ROLE"),
	AverageTTD 								= Cache:Pass(function(self, range)
		-- @return number, number
		-- Returns average time to die of valid players, count of valid players
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local value, members				= 0, 0

		if ROLE and TeamCacheEnemy[ROLE] then
			for arena in pairs(TeamCacheEnemy[ROLE]) do
				if (not range or A_Unit(arena):GetRange() <= range) then
					value = value + A_Unit(arena):TimeToDie()
					arenas = arenas + 1
				end
			end
		else
			for i = 1, TeamCacheEnemy.MaxSize do
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena and (not range or A_Unit(arena):GetRange() <= range) then
					value = value + A_Unit(arena):TimeToDie()
					arenas = arenas +  1
				end
			end
		end

		if arenas > 0 then
			value = value / arenas
		end

		return value, arenas
	end, "ROLE"),
	IsBreakAble 							= Cache:Wrap(function(self, range)
		-- @return boolean, unitID
		-- Nill-able: range
		local ROLE 							= self.ROLE
		local arena

		if ROLE and TeamCacheEnemy[ROLE] then
			for arena in pairs(TeamCacheEnemy[ROLE]) do
				if not UnitIsUnit(arena, "target") and (not range or A_Unit(arena):GetRange() <= range) and A_Unit(arena):HasDeBuffs("BreakAble") ~= 0 then
					return true, arena
				end
			end
		else
			-- Note: It's much faster than querying through index
			for arena in pairs(ActiveUnitPlates) do
				if A_Unit(arena):IsPlayer() and A_Unit(arena):Role(ROLE) and not UnitIsUnit("target", arena) and (not range or A_Unit(arena):GetRange() <= range) and A_Unit(arena):HasDeBuffs("BreakAble") ~= 0 then
					return true, arena
				end
			end
		end

		return false, str_none
	end, "ROLE"),
	PlayersInRange 							= Cache:Pass(function(self, stop, range)
		-- @return boolean, number, unitID
		-- Nill-able: stop, range
		local ROLE 							= self.ROLE
		local count 						= 0
		local arena

		if ROLE and TeamCacheEnemy[ROLE] then
			for arena in pairs(TeamCacheEnemy[ROLE]) do
				if not range or A_Unit(arena):GetRange() <= range then
					count = count + 1
					if not stop or count >= stop then
						return true, count, arena
					end
				end
			end
		else
			for arena in pairs(ActiveUnitPlates) do
				if A_Unit(arena):IsPlayer() and A_Unit(arena):Role(ROLE) and (not range or A_Unit(arena):GetRange() <= range) then
					count = count + 1
					if not stop or count >= stop then
						return true, count, arena
					end
				end
			end
		end

		return false, count, arena or str_none
	end, "ROLE"),
	-- [[ Without ROLE argument ]]
	HasInvisibleUnits 						= Cache:Pass(function(self, checkVisible)
		-- @return boolean, unitID, unitClass
		-- Nill-able: checkVisible
		local arena, class

		for i = 1, TeamCacheEnemy.MaxSize do
			arena = TeamCacheEnemyIndexToPLAYERs[i]
			if arena and not A_Unit(arena):IsDead() then
				class = A_Unit(arena):Class()
				if (class == "MAGE" or class == "ROGUE" or class == "DRUID") and (not checkVisible or not A_Unit(arena):IsVisible()) then
					return true, arena, class
				end
			end
		end

		return false, str_none, str_none
	end, "ROLE"),
	IsTauntPetAble 							= Cache:Pass(function(self, spell, max_index)
		-- @return boolean, unitID
		-- Nill-able: max_index
		if TeamCacheEnemy.Size > 0 then
			local pet, spell_type
			for i = 1, (max_index or (TeamCacheEnemy.MaxSize >= 3 and 3) or TeamCacheEnemy.MaxSize) do -- Retail 3, Classic 10
				pet = TeamCacheEnemyIndexToPETs[i]
				if pet then
					spell_type = type(spell)
					if not spell or (spell_type == "table" and spell:IsInRange(pet)) or (spell_type ~= "table" and A_IsSpellInRange(spell, pet)) then
						return true, pet
					end
				end
			end
		end

		return false, str_none
	end, "ROLE"),
	IsCastingBreakAble 						= Cache:Pass(function(self, offset)
		-- @return boolean, unitID
		-- Nill-able: offset
		local arena

		for i = 1, TeamCacheEnemy.MaxSize do
			arena = TeamCacheEnemyIndexToPLAYERs[i]
			if arena then
				local _, castRemain, _, _, castName = A_Unit(arena):CastTime()
				if castRemain > 0 and castRemain <= (offset or 0.5) then
					for _, spell in ipairs(AuraList.Premonition) do
						if A_GetSpellInfo(spell[1]) == castName and A_Unit(arena):GetRange() <= spell[2] then
							return true, arena
						end
					end
				end
			end
		end

		return false, str_none
	end, "ROLE"),
	IsReshiftAble 							= Cache:Pass(function(self, offset)
		-- @return boolean, unitID
		-- Nill-able: offset
		local arena

		if not A_Unit("player"):IsFocused("MELEE") then
			for i = 1, TeamCacheEnemy.MaxSize do
				arena = TeamCacheEnemyIndexToPLAYERs[i]
				if arena then
					local _, castRemain, _, _, castName = A_Unit(arena):CastTime()
					if castRemain > 0 and castRemain <= A_GetCurrentGCD() + A_GetGCD() + (offset or 0.05) then
						for _, spell in ipairs(AuraList.Reshift) do
							if A_GetSpellInfo(spell[1]) == castName and A_Unit(arena):GetRange() <= spell[2] then
								return true, arena
							end
						end
					end
				end
			end
		end

		return false, str_none
	end, "ROLE"),
	IsPremonitionAble 						= Cache:Pass(function(self, offset)
		-- @return boolean, unitID
		-- Nill-able: offset
		local arena

		for i = 1, TeamCacheEnemy.MaxSize do
			arena = TeamCacheEnemyIndexToPLAYERs[i]
			if arena then
				local _, castRemain, _, _, castName = A_Unit(arena):CastTime()
				if castRemain > 0 and castRemain <= A_GetGCD() + (offset or 0.05) then
					for _, spell in ipairs(AuraList.Premonition) do
						if A_GetSpellInfo(spell[1]) == castName and A_Unit(arena):GetRange() <= spell[2] then
							return true, arena
						end
					end
				end
			end
		end

		return false, str_none
	end, "ROLE"),
})

function A.EnemyTeam:New(ROLE, Refresh)
    self.ROLE = ROLE
    self.Refresh = Refresh or 0.05
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
local EventInfo		 					= {
	["UNIT_DIED"] 						= "RESET",
	["UNIT_DESTROYED"]					= "RESET",
	["UNIT_DISSIPATES"]					= "RESET",
	["PARTY_KILL"] 						= "RESET",
	["SPELL_INSTAKILL"] 				= "RESET",
}
Listener:Add("ACTION_EVENT_UNIT", "COMBAT_LOG_EVENT_UNFILTERED", 		function(...)
	local _, EVENT, _, _, _, _, _, DestGUID, _, _, _, _, spellName = CombatLogGetCurrentEventInfo()
	if EventInfo[EVENT] == "RESET" then
		InfoCacheMoveIn[DestGUID] 		= nil
		InfoCacheMoveOut[DestGUID] 		= nil
		InfoCacheMoving[DestGUID]		= nil
		InfoCacheStaying[DestGUID]		= nil
		InfoCacheInterrupt[DestGUID]	= nil
		InfoCycloneGUIDs[DestGUID]		= nil
	end

	if spellName and InfoCycloneSpellName[spellName] then
		-- Cyclone and Banish can not be both applied at the same time, so why not
		if InfoCycloneOnEvent[EVENT] == "Add" then
			InfoCycloneGUIDs[DestGUID] 	= true
		elseif InfoCycloneOnEvent[EVENT] == "Remove" then
			InfoCycloneGUIDs[DestGUID]	= nil
		end
	end
end)

Listener:Add("ACTION_EVENT_UNIT", "PLAYER_REGEN_ENABLED", 				function()
	if A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel then
		for _, tfunc in pairs(Cache.bufer) do
			for keyArg, tkeyArg in pairs(tfunc) do
				if TMW.time - tkeyArg.t > 10 then
					tfunc[keyArg] = nil
				end
			end
		end
		wipe(InfoCacheMoveIn)
		wipe(InfoCacheMoveOut)
		wipe(InfoCacheMoving)
		wipe(InfoCacheStaying)
		wipe(InfoCacheInterrupt)
	end
end)

Listener:Add("ACTION_EVENT_UNIT", "PLAYER_REGEN_DISABLED", 				function()
	-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
	local LastTimeCasted = CombatTracker:GetSpellLastCast("player", A.LastPlayerCastID)
	if (LastTimeCasted == 0 or LastTimeCasted > 1.5) and A.Zone ~= "arena" and A.Zone ~= "pvp" and not A.IsInDuel and not Player:IsStealthed() and Player:CastTimeSinceStart() > 5 then
		wipe(InfoCacheMoveIn)
		wipe(InfoCacheMoveOut)
		wipe(InfoCacheMoving)
		wipe(InfoCacheStaying)
		wipe(InfoCacheInterrupt)
	end
end)

TMW:RegisterCallback("TMW_ACTION_ENTERING",								function(event, subevent)
	if subevent ~= "UPDATE_INSTANCE_INFO" then
		for _, tfunc in pairs(Cache.bufer) do
			for keyArg, tkeyArg in pairs(tfunc) do
				if TMW.time - tkeyArg.t > 10 then
					tfunc[keyArg] = nil
				end
			end
		end
		wipe(InfoCacheMoveIn)
		wipe(InfoCacheMoveOut)
		wipe(InfoCacheMoving)
		wipe(InfoCacheStaying)
		wipe(InfoCacheInterrupt)
		-- Only here InfoCycloneGUIDs
		wipe(InfoCycloneGUIDs)
	end
end)