--- 
local DateTime 														= "28.09.2025"
---
local pcall, ipairs, pairs, type, assert, error, setfenv, getmetatable, setmetatable, loadstring, next, unpack, select, _G, coroutine, table, math, string =
	  pcall, ipairs, pairs, type, assert, error, setfenv, getmetatable, setmetatable, loadstring, next, unpack, select, _G, coroutine, table, math, string
	
local debugprofilestop												= _G.debugprofilestop
local hooksecurefunc												= _G.hooksecurefunc
local wipe															= _G.wipe	
local tinsert														= table.insert 
local tremove														= table.remove 
local tsort															= table.sort 
local huge	 														= math.huge
local math_floor													= math.floor
local math_random													= math.random
local math_max														= math.max
local math_min														= math.min
local strgsub 														= string.gsub	
local strjoin	 													= string.join  
local strupper 														= string.upper
local strformat														= string.format

local TMW 															= _G.TMW
local Env 															= TMW.CNDT.Env
local GetGCD														= TMW.GetGCD
local strlowerCache  												= TMW.strlowerCache
local safecall														= TMW.safecall
TMW.GCD 															= TMW.GCD or GetGCD() -- Fixes nil able compare error because UpdateGlobals launches with delay

local LibStub														= _G.LibStub
local StdUi 														= LibStub("StdUi"):NewInstance()
local LibDBIcon	 													= LibStub("LibDBIcon-1.0")
local LSM 															= LibStub("LibSharedMedia-3.0")
	  LSM:Register(LSM.MediaType.STATUSBAR, "Flat", [[Interface\Addons\]] .. _G.ACTION_CONST_ADDON_NAME .. [[\Media\Flat]])
local isClassic														= _G.WOW_PROJECT_ID == _G.WOW_PROJECT_CLASSIC
StdUi.isClassic 													= isClassic	  
local owner															= isClassic and "PlayerClass" or "PlayerSpec"

local C_Spell														= _G.C_Spell
local 	 GetRealmName, 	  GetNumSpecializationsForClassID, 	  GetSpecializationInfo, 	GetSpecialization,    GetFramerate, 	GetBindingFromClick,    GetBindingText,	   GetSpellInfo,    					     								GetSpellAvailableLevel,    GetMaxLevelForPlayerExpansion = 
	  _G.GetRealmName, _G.GetNumSpecializationsForClassID, _G.GetSpecializationInfo, _G.GetSpecialization, _G.GetFramerate,  _G.GetBindingFromClick, _G.GetBindingText, _G.GetSpellInfo or C_Spell.GetSpellInfo, C_Spell.GetSpellLevelLearned or _G.GetSpellAvailableLevel, _G.GetMaxLevelForPlayerExpansion	  
	  
local 	 UnitName,    UnitClass,    UnitLevel,    UnitExists, 	 UnitIsUnit,    UnitGUID,    					  UnitAura,     UnitPower = 
	  _G.UnitName, _G.UnitClass, _G.UnitLevel, _G.UnitExists, _G.UnitIsUnit, _G.UnitGUID, _G.C_UnitAuras.GetAuraDataByIndex, _G.UnitPower	  
	    
local GameLocale 													= _G.GetLocale()
local BOOKTYPE_SPELL												= _G.BOOKTYPE_SPELL
local BOOKTYPE_PET													= _G.BOOKTYPE_PET
local DEFAULT_CHAT_FRAME											= _G.DEFAULT_CHAT_FRAME
local BindPadFrame 													= _G.BindPadFrame
local GameTooltip													= _G.GameTooltip
local UIParent														= _G.UIParent
local C_UI															= _G.C_UI  
local FindSpellBookSlotBySpellID 									= _G.FindSpellBookSlotBySpellID	
local CombatLogGetCurrentEventInfo									= _G.CombatLogGetCurrentEventInfo
local CreateFrame 													= _G.CreateFrame 	
local PlaySound														= _G.PlaySound	  
local InCombatLockdown												= _G.InCombatLockdown
local IsAltKeyDown													= _G.IsAltKeyDown
local IsControlKeyDown												= _G.IsControlKeyDown
local IsShiftKeyDown												= _G.IsShiftKeyDown
local ChatEdit_InsertLink											= _G.ChatEdit_InsertLink
local CopyTable														= _G.CopyTable
local TOOLTIP_UPDATE_TIME											= _G.TOOLTIP_UPDATE_TIME

_G.Action 															= LibStub("AceAddon-3.0"):NewAddon("Action", "AceEvent-3.0") 
Env.Action 															= _G.Action
local Action 														= _G.Action 
Action.DateTime														= DateTime
Action.StdUi 														= StdUi 
Action.BuildToC														= select(4, _G.GetBuildInfo())
Action.PlayerRace 													= select(2, _G.UnitRace("player"))
Action.PlayerClassName, Action.PlayerClass, Action.PlayerClassID  	= UnitClass("player")

local BuildToC														= Action.BuildToC

-- Backwards compatibility for GetMouseFocus	  
local GetMouseFocus = _G.GetMouseFocus
local GetMouseFoci 	= _G.GetMouseFoci
function Action.GetMouseFocus()
    if GetMouseFoci then
        local frames = GetMouseFoci()
        return frames and frames[1]
    else
        return GetMouseFocus()
    end
end 

-- Remap
local 	MacroLibrary, 
		TMWdb, TMWdbprofile, TMWdbglobal, pActionDB, gActionDB,
		A_Player, A_Unit, A_UnitInLOS, A_FriendlyTeam, A_EnemyTeam, A_TeamCacheFriendlyUNITs,
		A_Listener,	A_SetToggle, A_GetToggle, A_GetLocalization, A_Print, A_MacroQueue, A_IsActionTable,
		A_OnGCD, A_IsActiveGCD, A_GetGCD, A_GetCurrentGCD, A_GetSpellInfo, A_IsQueueRunningAuto, A_WipeTableKeyIdentify, A_GetActionTableByKey,
		A_ToggleMainUI, A_ToggleMinimap, A_MinimapIsShown, A_BlackBackgroundIsShown, A_BlackBackgroundSet, 
		A_InterruptGetSliders, A_InterruptIsON, A_InterruptIsBlackListed, A_InterruptEnabled,
		A_AuraGetCategory, A_AuraIsON, A_AuraIsBlackListed,
		toStr, round, tabFrame, strOnlyBuilder	
do 
	Action.FormatGameLocale = function(GameLocale)
		if GameLocale == "enGB" then 
			GameLocale = "enUS"
		elseif GameLocale == "esMX" then 
			-- Mexico used esES
			GameLocale = "esES"
		elseif GameLocale == "ptBR" then 
			-- Brazil used ptPT 
			GameLocale = "ptPT"
		end 
		
		return GameLocale
	end 
	
	GameLocale = Action.FormatGameLocale(GameLocale)
	Action.FormatedGameLocale = GameLocale
end 		

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------
-- Note: L (@table localized with current language of interface), CL (@string current selected language of interface), GameLocale (@string game language default), Localization (@table clear with all locales)
local CL, L = "enUS"
local Localization = {
	[GameLocale] = {},
	enUS = {			
		NOSUPPORT = "this profile is not supported ActionUI yet",	
		DEBUG = "|cffff0000[Debug] Error Identification: |r",			
		ISNOTFOUND = "is not found!",			
		CREATED = "created",
		YES = "Yes",
		NO = "No",
		TOGGLEIT = "Switch it",
		SELECTED = "Selected",
		RESET = "Reset",
		RESETED = "Reseted",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro already existed!|r",
		MACROLIMIT = "|cffff0000Can't create macro, you reached limit. You need to delete at least one macro!|r",	
		MACROINCOMBAT = "|cffff0000Can't create macro in combat. You need to leave combat!|r",
		MACROSIZE = "|cffff0000Macro size can't exceed 255 bytes!|r",
		GLOBALAPI = "API Global: ",
		RESIZE = "Resize",
		RESIZE_TOOLTIP = "Click-and-drag to resize",
		CLOSE = "Close",
		APPLY = "Apply",
		UPGRADEDFROM = "upgraded from ",
		UPGRADEDTO = " to ",		
		PROFILESESSION = {
			BUTTON = "Profile Session\nLeft click opens user panel\nRight click opens development panel",
			BNETSAVED = "Your user key has been successfully cached for an offline profile session!",
			BNETMESSAGE = "Battle.net is offline!\nPlease restart game with enabled Battle.net!",
			BNETMESSAGETRIAL = "!! Your character is on trial and can't use an offline profile session !!",
			EXPIREDMESSAGE = "Your subscription for %s is expired!\nPlease contact profile developer!",
			AUTHMESSAGE = "Thank you for using premium profile\nTo authorize your key please contact profile developer!", 
			AUTHORIZED = "Your key is authorized!",
			REMAINING = "[%s] remains %d secs",
			DISABLED = "[%s] |cffff0000expired session!|r",
			PROFILE = "Profile:",
			TRIAL = "(trial)",
			FULL = "(premium)",
			UNKNOWN = "(not authorized)",
			DEVELOPMENTPANEL = "Development",
			USERPANEL = "User",
			PROJECTNAME = "Project Name",
			PROJECTNAMETT = "Your development/project/routines/brand name",
			SECUREWORD = "Secure Word",
			SECUREWORDTT = "Your secured word as master password to project name",
			KEYTT = "'dev_key' used in ProfileSession:Setup('dev_key', {...})",
			KEYTTUSER = "Send this key to profile author!",
		},
		SLASH = {
			LIST = "List of slash commands:",
			OPENCONFIGMENU = "shows config menu of the Action",
			OPENCONFIGMENUTOASTER = "shows config menu of the Toaster",
			HELP = "shows help info",
			QUEUEHOWTO = "macro (toggle) for sequence system (Queue), the TABLENAME is a label reference for SpellName|ItemName (in english)",
			QUEUEEXAMPLE = "example of Queue usage",
			BLOCKHOWTO = "macro (toggle) for disable|enable any actions (Blocker), the TABLENAME is a label reference for SpellName|ItemName (in english)",
			BLOCKEXAMPLE = "example of Blocker usage",
			RIGHTCLICKGUIDANCE = "Most elements are left and right click-able. Right click will create macro toggle so you can consider the above suggestion",				
			INTERFACEGUIDANCE = "UI explains:",
			INTERFACEGUIDANCEEACHSPEC = "[Each spec] relative for CURRENT selected specialization",
			INTERFACEGUIDANCEALLSPECS = "[All specs] relative for your ALL available character specializations",
			INTERFACEGUIDANCEGLOBAL = "[Global] relative for ALL your account, ALL characters, ALL specializations",
			ATTENTION = "|cffff0000PAY ATTENTION|r functional of Action available only for profiles released after 31.05.2019. The old profile will be updated for this system in future",		
			TOTOGGLEBURST = "to toggle Burst Mode",
			TOTOGGLEMODE = "to toggle PvP / PvE",
			TOTOGGLEAOE = "to toggle AoE",
		},
		TAB = {
			RESETBUTTON = "Reset settings",
			RESETQUESTION = "Are you sure?",
			SAVEACTIONS = "Save Actions Settings",
			SAVEINTERRUPT = "Save Interrupt Lists",
			SAVEDISPEL = "Save Auras Lists",
			SAVEMOUSE = "Save Cursor Lists",
			SAVEMSG = "Save MSG Lists",
			SAVEHE = "Save Healing Engine Settings",
			SAVEHOTKEYS = "Save Hotkeys Settings",
			LUAWINDOW = "LUA Configure",
			LUATOOLTIP = "To refer to the checking unit, use 'thisunit' without quotes\nCode must have boolean return (true) to process conditions\nThis code has setfenv which means what you no need to use Action. for anything that have it\n\nIf you want to remove already default code you will need to write 'return true' without quotes instead of remove them all",
			BRACKETMATCH = "Bracket Matching",
			CLOSELUABEFOREADD = "Close LUA Configuration before add",
			FIXLUABEFOREADD = "You need to fix errors in LUA Configuration before to add",
			RIGHTCLICKCREATEMACRO = "Right click: Create macro",
			ROWCREATEMACRO = "Right click: Create macro to set current value for all ceils in this row\nShift + Right click: Create macro to set opposite value for all 'boolean' ceils in this row",
			CEILCREATEMACRO = "Right click: Create macro to set '%s' value for '%s' ceil in this row\nShift + Right click: Create macro to set '%s' value for '%s' ceil-\n-and opposite value for other 'boolean' ceils in this row",	
			NOTHING = "Profile has no configuration for this tab",
			HOW = "Apply:",
			HOWTOOLTIP = "Global: All account, all characters and all specializations",
			GLOBAL = "Global",
			ALLSPECS = "To all specializations of the character",
			THISSPEC = "To the current specialization of the character",			
			KEY = "Key:",
			CONFIGPANEL = "'Add' Configuration",
			BLACKLIST = "Black List",
			LANGUAGE = "[English]",
			AUTO = "Auto",
			SESSION = "Session: ",
			PREVIEWBYTES = "Preview: %s bytes (255 max limit, 210 max recommended)",
			[1] = {
				HEADBUTTON = "General",	
				HEADTITLE = "[Each spec] Primary",
				PVEPVPTOGGLE = "PvE / PvP Manual Toggle",
				PVEPVPTOGGLETOOLTIP = "Forcing a profile to switch to another mode\n(especially useful when the War Mode is ON)\n\nRightClick: Create macro", 
				PVEPVPRESETTOOLTIP = "Reset manual toggle to auto select",
				CHANGELANGUAGE = "Switch language",
				CHARACTERSECTION = "Character Section",
				AUTOTARGET = "Auto Target",
				AUTOTARGETTOOLTIP = "If the target is empty, but you are in combat, it will return the nearest enemy\nThe switcher works in the same way if the target has immunity in PvP\n\nRightClick: Create macro",					
				POTION = "Potion",
				HEARTOFAZEROTH = "Heart of Azeroth",
				COVENANT = "Covenant abilities",
				RACIAL = "Racial spell",
				STOPCAST = "Stop casting",
				SYSTEMSECTION = "System Section",
				LOSSYSTEM = "LOS System",
				LOSSYSTEMTOOLTIP = "ATTENTION: This option causes delay of 0.3s + current spinning gcd\nif unit being checked it is located in a lose (for example, behind a box at arena)\nYou must also enable the same setting in Advanced Settings\nThis option blacklists unit which in a lose and\nstops providing actions to it for N seconds\n\nRightClick: Create macro",
				STOPATBREAKABLE = "Stop Damage On BreakAble",
				STOPATBREAKABLETOOLTIP = "Will stop harmful damage on enemies\nIf they have CC such as Polymorph\nIt doesn't cancel auto attack!\n\nRightClick: Create macro",
				BOSSTIMERS = "Boss Timers",
				BOSSTIMERSTOOLTIP = "Required DBM or BigWigs addons\n\nTracking pull timers and some specific events such as trash incoming.\nThis feature is not availble for all the profiles!\n\nRightClick: Create macro",
				FPS = "FPS Optimization",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Increases frames per second by increasing the dynamic dependency\nframes of the refresh cycle (call) of the rotation cycle\n\nYou can also manually set the interval following a simple rule:\nThe larger slider then more FPS, but worse rotation update\nToo high value can cause unpredictable behavior!\n\nRightClick: Create macro",					
				PVPSECTION = "PvP Section",
				REFOCUS = "Return previous saved @focus\n(arena1-5 units only)\nIt recommended against invisibility classes\n\nRightClick: Create macro",
				RETARGET = "Return previous saved @target\n(arena1-5 units only)\nIt recommended against hunters with 'Feign Death' and any unforeseen target drops\n\nRightClick: Create macro",
				TRINKETS = "Trinkets",
				TRINKET = "Trinket",
				BURST = "Burst Mode",
				BURSTEVERYTHING = "Everything",
				BURSTTOOLTIP = "Everything - On cooldown\nAuto - Boss or Players\nOff - Disabled\n\nRightClick: Create macro\nIf you would like set fix toggle state use argument: 'Everything', 'Auto', 'Off'\n/run Action.ToggleBurst('Everything', 'Auto')",					
				HEALTHSTONE = "Healthstone | Healing Potion",
				HEALTHSTONETOOLTIP = "Set percent health (HP)\n\nRightClick: Create macro",
				COLORTITLE = "Color Picker",
				COLORUSE = "Use custom color",
				COLORUSETOOLTIP = "Switcher between default and custom colors",
				COLORELEMENT = "Element",
				COLOROPTION = "Option",
				COLORPICKER = "Picker",
				COLORPICKERTOOLTIP = "Click to open setup window for your selected 'Element' > 'Option'\nRight mouse button to move opened window",
				FONT = "Font",
				NORMAL = "Normal",
				DISABLED = "Disabled",
				HEADER = "Header",
				SUBTITLE = "Subtitle",
				TOOLTIP = "Tooltip",
				BACKDROP = "Backdrop",
				PANEL = "Panel",
				SLIDER = "Slider",
				HIGHLIGHT = "Highlight",
				BUTTON = "Button",
				BUTTONDISABLED = "Button Disabled",
				BORDER = "Border",
				BORDERDISABLED = "Border Disabled",	
				PROGRESSBAR = "Progress Bar",
				COLOR = "Color",
				BLANK = "Blank",
				SELECTTHEME = "Select Ready Theme",
				THEMEHOLDER = "choose theme",
				BLOODYBLUE = "Bloody Blue",
				ICE = "Ice",
				AUTOATTACK = "Auto Attack",
				AUTOSHOOT = "Auto Shoot",				
				PAUSECHECKS = "[All specs]\nRotation doesn't work if:",
				ANTIFAKEPAUSES = "AntiFake Pauses",
				ANTIFAKEPAUSESSUBTITLE = "While the hotkey is held down",
				ANTIFAKEPAUSESTT = "Depending on the hotkey you select,\nonly the code assigned to it will work when you hold it down",
				VEHICLE = "InVehicle",
				VEHICLETOOLTIP = "Example: Catapult, Firing gun",
				DEADOFGHOSTPLAYER = "You're dead",
				DEADOFGHOSTTARGET = "Target is dead",
				DEADOFGHOSTTARGETTOOLTIP = "Exception enemy hunter if he selected as primary target",
				MOUNT = "IsMounted",
				COMBAT = "Out of combat", 
				COMBATTOOLTIP = "If You and Your target out of combat. Invisible is exception\n(while stealthed this condition will skip)",
				SPELLISTARGETING = "SpellIsTargeting",
				SPELLISTARGETINGTOOLTIP = "Example: Blizzard, Heroic Leap, Freezing Trap",
				LOOTFRAME = "LootFrame",
				EATORDRINK = "Is Eating or Drinking",
				MISC = "Misc:",		
				DISABLEROTATIONDISPLAY = "Hide display rotation",
				DISABLEROTATIONDISPLAYTOOLTIP = "Hides the group, which is usually at the\ncenter bottom of the screen",
				DISABLEBLACKBACKGROUND = "Hide black background", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Hides the black background in the upper left corner\nATTENTION: This can cause unpredictable behavior!",
				DISABLEPRINT = "Hide print",
				DISABLEPRINTTOOLTIP = "Hides chat notifications from everything\nATTENTION: This will also hide [Debug] Error Identification!",
				DISABLEMINIMAP = "Hide icon on minimap",
				DISABLEMINIMAPTOOLTIP = "Hides minimap icon of this UI",
				DISABLEPORTRAITS = "Hide class portrait",
				DISABLEROTATIONMODES = "Hide rotation modes",
				DISABLESOUNDS = "Disable sounds",
				DISABLEADDONSCHECK = "Disable addons check",
				HIDEONSCREENSHOT = "Hide on screenshot",
				HIDEONSCREENSHOTTOOLTIP = "During the screenshot hides all TellMeWhen\nand Action frames, and then shows them back",
			},
			[2]	= {
				COVENANTCONFIGURE = "Covenant Options",
				PROFILECONFIGURE = "Profile Options",
				FLESHCRAFTHP = "Fleshcraft\nHealth Percent",
				FLESHCRAFTTTD = "Fleshcraft\nTime To Die",
				PHIALOFSERENITYHP = "Phial of Serenity\nHealth Percent",
				PHIALOFSERENITYTTD = "Phial of Serenity\nTime To Die",
				PHIALOFSERENITYDISPEL = "Phial of Serenity - Dispel",
				PHIALOFSERENITYDISPELTOOLTIP = "If enabled, it will remove the effects specified in the 'Auras' tab regardless of the checkboxes of that tab\n\n",
				AND = "And",
				OR = "Or",
				OPERATOR = "Operator",
				TOOLTIPOPERATOR = "It's logical operator between two adjacent conditions\nIf choice is 'And' then both must be successful\nIf choice is 'Or' then one of two conditions must be successful\n\n",
				TOOLTIPTTD = "This value is in seconds, compares as <=\nIt's mathematical calculation based on incoming damage to complete death\n\n",
				TOOLTIPHP = "This value is in percents, compares as <=\nIt's current character's health in percents\n\n",
			},
			[3] = {
				HEADBUTTON = "Actions",
				HEADTITLE = "Blocker | Queue",
				ENABLED = "Enabled",
				NAME = "Name",
				DESC = "Note",
				ICON = "Icon",
				SETBLOCKER = "Set\nBlocker",
				SETBLOCKERTOOLTIP = "This will block selected action in rotation\nIt will never use it\n\nRightClick: Create macro",
				SETQUEUE = "Set\nQueue",
				SETQUEUETOOLTIP = "This will queue action in rotation\nIt will use it as soon as it possible\n\nRightClick: Create macro\nYou can pass additional conditions in created macro for queue\nSuch as on which unit to use (UnitID is key), example: { Priority = 1, UnitID = 'player' }\nYou can find acceptable keys with description in the function 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Blocked: |r",
				UNBLOCKED = "|cff00ff00Unblocked: |r",
				KEY = "[Key: ",
				KEYTOTAL = "[Queued Total: ",
				KEYTOOLTIP = "Use this key in 'Messages' tab",
				MACRO = "Macro",
				MACROTOOLTIP = "Should be short as much as it possible, macro is limited up to 255 bytes\nwhere ~45 bytes should be left reserved for multi-chain, multiline is supported\n\nIf Macro is omit will be used default autounit construction:\n\"/cast [@unitID]spellName\" or \"/cast [@unitID]spellName(Rank %d)\" or \"/use item:itemID\"\n\nMacro always should be added to actions which have anything like\n/cast [@player]spell:thisID\n/castsequence reset=1 spell:thisID, nil\n\nAccepts patterns:\n\"spell:12345\" will be replaced by spellName taken from numbers\n\"thisID\" will be replaced by self.SlotID or self.ID\n\"(Rank %d+)\" will replace Rank by localized word\nAny pattern can be combined, for example \"spell:thisID(Rank 1)\"",				
				ISFORBIDDENFORMACRO = "is forbidden to change macro!",
				ISFORBIDDENFORBLOCK = "is forbidden for blocker!",
				ISFORBIDDENFORQUEUE = "is forbidden for queue!",
				ISQUEUEDALREADY = "is already existing in queue!",
				QUEUED = "|cff00ff00Queued: |r",
				QUEUEREMOVED = "|cffff0000Removed from queue: |r",
				QUEUEPRIORITY = " has priority #",
				QUEUEBLOCKED = "|cffff0000can't be queued because SetBlocker blocked it!|r",
				SELECTIONERROR = "|cffff0000You didn't selected row!|r",
				AUTOHIDDEN = "[All specs] AutoHide unavailable actions",
				AUTOHIDDENTOOLTIP = "Makes Scroll Table smaller and clear by visual hide\nFor example character class has few racials but can use one, this option will hide others racials\nJust for comfort view",
				CHECKSPELLLVL = "[All specs] Check required spell level",
				CHECKSPELLLVLTOOLTIP = "All spells which is not available by character level will be blocked\nThey will be updated every time with level up",
				CHECKSPELLLVLERROR = "Already initialized!",
				CHECKSPELLLVLERRORMAXLVL = "You're at MAX possible level!",
				CHECKSPELLLVLMACRONAME = "CheckSpellLevel",
				LUAAPPLIED = "LUA code was applied to ",
				LUAREMOVED = "LUA was removed from ",
			},
			[4] = {
				HEADBUTTON = "Interrupts",	
				HEADTITLE = "Profile Interrupts",					
				ID = "ID",
				NAME = "Name",
				ICON = "Icon",
				USEKICK = "Kick",
				USECC = "CC",
				USERACIAL = "Racial",
				MIN = "Min: ",
				MAX = "Max: ",
				SLIDERTOOLTIP = "Sets the interruption between min and max percentage duration of the cast\n\nThe red color of the values means that they are too close to each other and dangerous to use\n\nOFF state means that these sliders are not available for this list",
				USEMAIN = "[Main] Use",
				USEMAINTOOLTIP = "Enables or disables the list with its units to interrupt\n\nRightClick: Create macro",
				MAINAUTO = "[Main] Auto",
				MAINAUTOTOOLTIP = "If enabled:\nPvE: Interrupts any available cast\nPvP: If it's healer and will die in less than 6 seconds either if it's player without in range enemy healers\n\nIf disabled:\nInterrupts only spells added in the scroll table for that list\n\nRightClick: Create macro",
				USEMOUSE = "[Mouse] Use",
				USEMOUSETOOLTIP = "Enables or disables the list with its units to interrupt\n\nRightClick: Create macro",
				MOUSEAUTO = "[Mouse] Auto",
				MOUSEAUTOTOOLTIP = "If enabled:\nPvE: Interrupts any available cast\nPvP: Interrupts only spells added in the scroll table for PvP and Heal lists and only players\n\nIf disabled:\nInterrupts only spells added in the scroll table for that list\n\nRightClick: Create macro",
				USEHEAL = "[Heal] Use",
				USEHEALTOOLTIP = "Enables or disables the list with its units to interrupt\n\nRightClick: Create macro",
				HEALONLYHEALERS = "[Heal] Only Healers",
				HEALONLYHEALERSTOOLTIP = "If enabled:\nInterrupts only healers\n\nIf disabled:\nInterrupts any enemy role\n\nRightClick: Create macro",
				USEPVP = "[PvP] Use",
				USEPVPTOOLTIP = "Enables or disables the list with its units to interrupt\n\nRightClick: Create macro",
				PVPONLYSMART = "[PvP] Smart",
				PVPONLYSMARTTOOLTIP = "If enabled will interrupt by advanced logic:\n1) Chain control on your healer\n2) Someone have Burst buffs >4 sec\n3) Someone will die in less than 8 sec\n4) You (or @target) can be executed\n\nIf disabled will interrupt without advanced logic\n\nRightClick: Create macro",
				INPUTBOXTITLE = "Write spell:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): clear text and remove focus",
				INTEGERERROR = "Integer overflow attempting to store > 7 numbers", 
				SEARCH = "Search by name or ID",
				ADD = "Add Interrupt",					
				ADDERROR = "|cffff0000You didn't specify anything in 'Write spell' or spell is not found!|r",
				ADDTOOLTIP = "Add spell from 'Write spell'\neditbox to current selected list",
				REMOVE = "Remove Interrupt",
				REMOVETOOLTIP = "Remove selected spell in scroll table row from the current list",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "[Each spec]",
				USEDISPEL = "Use Dispel",
				USEPURGE = "Use Purge",
				USEEXPELENRAGE = "Expel Enrage",
				HEADTITLE = "[Global]",
				MODE = "Mode:",
				CATEGORY = "Category:",
				POISON = "Dispel poisons",
				DISEASE = "Dispel diseases",
				CURSE = "Dispel curses",
				MAGIC = "Dispel magic",
				MAGICMOVEMENT = "Dispel magic slow/roots",
				PURGEFRIENDLY = "Purge friendly",
				PURGEHIGH = "Purge enemy (high priority)",
				PURGELOW = "Purge enemy (low priority)",
				ENRAGE = "Expel Enrage",	
				BLEEDS = "Bleeds",
				BLESSINGOFPROTECTION = "Blessing of Protection",
				BLESSINGOFFREEDOM = "Blessing of Freedom",
				BLESSINGOFSACRIFICE = "Blessing of Sacrifice",
				BLESSINGOFSANCTUARY = "Blessing of Sanctuary",
				ROLE = "Role",
				ID = "ID",
				NAME = "Name",
				DURATION = "Duration\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icon",					
				ROLETOOLTIP = "Your role to use it",
				DURATIONTOOLTIP = "React on aura if the duration of the aura is longer (>) of the specified seconds\nIMPORTANT: Auras without duration such as 'Divine favor'\n(Light Paladin) must be 0. This means that the aura is present!",
				STACKSTOOLTIP = "React on aura if it has more or equal (>=) specified stacks",									
				BYID = "Use ID\ninstead Name",
				BYIDTOOLTIP = "By ID must be checking ALL spells\nwhich have same name, but assume different auras\nsuch as 'Unstable Affliction'",					
				CANSTEALORPURGE = "Only if can\nsteal or purge",					
				ONLYBEAR = "Only if unit\nin 'Bear form'",									
				CONFIGPANEL = "'Add Aura' Configuration",
				ANY = "Any",
				HEALER = "Healer",
				DAMAGER = "Tank|Damager",
				ADD = "Add Aura",					
				REMOVE = "Remove Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursor",
				HEADTITLE = "Mouse Interaction",
				USETITLE = "[Each spec] Buttons Config:",
				USELEFT = "Use Left click",
				USELEFTTOOLTIP = "This using macro /target mouseover which is not itself click!\n\nRightClick: Create macro",
				USERIGHT = "Use Right click",
				LUATOOLTIP = "To refer to the checking unit, use 'thisunit' without quotes\nIf you use LUA in Category 'GameToolTip' then thisunit is not valid\nCode must have boolean return (true) to process conditions\nThis code has setfenv which means what you no need use Action. for anything that have it\n\nIf you want to remove already default code you will need write 'return true' without quotes instead of remove all",							
				BUTTON = "Click",
				NAME = "Name",
				LEFT = "Left click",
				RIGHT = "Right click",
				ISTOTEM = "IsTotem",
				ISTOTEMTOOLTIP = "If enabled then will check @mouseover on type 'Totem' for given name\nAlso prevent click in situation if your @target already has there any totem",				
				INPUTTITLE = "Enter the name of the object (localized!)", 
				INPUT = "This entry is case non sensitive",
				ADD = "Add",
				REMOVE = "Remove",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "spirit link totem",
				HEALINGTIDETOTEM = "healing tide totem",
				CAPACITORTOTEM = "capacitor totem",					
				SKYFURYTOTEM = "skyfury totem",					
				ANCESTRALPROTECTIONTOTEM = "ancestral protection totem",					
				COUNTERSTRIKETOTEM = "counterstrike totem",
				EXPLOSIVES = "explosives",
				WRATHGUARD = "wrathguard",
				FELGUARD = "felguard",
				INFERNAL = "infernal",
				SHIVARRA = "shivarra",
				DOOMGUARD = "doomguard",
				FELHOUND = "felhound",
				["UR'ZUL"] = "ur'zul",
				-- Optional totems
				TREMORTOTEM = "tremor totem",
				GROUNDINGTOTEM = "grounding totem",
				WINDRUSHTOTEM = "wind rush totem",
				EARTHBINDTOTEM = "earthbind totem",
				-- GameToolTips
				ALLIANCEFLAG = "alliance flag",
				HORDEFLAG = "horde flag",
				NETHERSTORMFLAG = "netherstorm flag",
				ORBOFPOWER = "orb of power",
			},
			[7] = {
				HEADBUTTON = "Messages",
				HEADTITLE = "Message System",
				USETITLE = "[Each spec]",
				MSG = "MSG System",
				MSGTOOLTIP = "Checked: working\nUnchecked: not working\n\nRightClick: Create macro",
				CHANNELS = "Channels",
				CHANNEL = "Channel ",
				DISABLERETOGGLE = "Block queue remove",
				DISABLERETOGGLETOOLTIP = "Preventing by repeated message deletion from queue system\nE.g. possible spam macro without being removed\n\nRightClick: Create macro",
				MACRO = "Macro for your group:",
				MACROTOOLTIP = "This is what should be sent to the group chat to trigger the assigned action on the specified key\nTo address the action to a specific unit, add them to the macro or leave it as it is for the appointment in Single/AoE rotation\nSupported: raid1-40, party1-4, player, arena1-5\nONLY ONE UNIT FOR ONE MESSAGE!\n\nYour companions can use macros as well, but be careful, they must be loyal to this!\nDON'T LET THE MACRO TO UNIMINANCES AND PEOPLE NOT IN THE THEME!",
				KEY = "Key",
				KEYERROR = "You did not specify a key!",
				KEYERRORNOEXIST = "key does not exist!",
				KEYTOOLTIP = "You must specify a key to bind the action\nYou can extract the key in the 'Actions' tab",
				MATCHERROR = "this given name already matches, use another!",				
				SOURCE = "The name of the person who said",					
				WHOSAID = "Who said",
				SOURCETOOLTIP = "This is optional. You can leave it blank (recommended)\nIf you want to configure it, the name must be exactly the same as in the chat group",
				NAME = "Contains a message",
				ICON = "Icon",
				INPUT = "Enter a phrase for the system message",
				INPUTTITLE = "Phrase",
				INPUTERROR = "You have not entered a phrase!",
				INPUTTOOLTIP = "The phrase will be triggered on any match in the group chat (/party)\nIt's not case sensitive\nContains patterns, this means that a phrase written by someone with the combination of the words raid, party, arena, party or player\nadaptates the action to the desired meta slot\nYou don’t need to set the listed patterns here, they are used as an addition to the macro\nIf the pattern is not found, then slots for Single and AoE rotations will be used",				
			},
			[8] = {
				HEADBUTTON = "Healing System",
				OPTIONSPANEL = "Options",
				OPTIONSPANELHELP = [[The settings of this panel affect 'Healing Engine' + 'Rotation'
									
									'Healing Engine' this name we refer to @target selection system through 
									the macro /target 'unitID'
									
									'Rotation' this name we refer to itself healing/damage rotation 
									for current primary unit (@target or @mouseover)
									
									Sometimes you will see 'profile must have code for it' text which means
									what related features can not work without add by profile author 
									special code for it inside lua snippets
									
									Each element has tooltip, so read it carefully and test if necessary in 
									'Proving Grounds' scenario before you will start real fight]],
				SELECTOPTIONS = "-- choose options --",
				PREDICTOPTIONS = "Predict Options",
				PREDICTOPTIONSTOOLTIP = "Supported: 'Healing Engine' + 'Rotation' (profile must have code for it)\n\nThese options affect:\n1. Health prediction of the group member for @target selection ('Healing Engine')\n2. Calculation of what healing action to use on @target/@mouseover ('Rotation')\n\nRight click: Create macro",
				INCOMINGHEAL = "Incoming heal",
				INCOMINGDAMAGE = "Incoming damage",
				THREATMENT = "Threatment (PvE)",
				SELFHOTS = "HoTs",
				ABSORBPOSSITIVE = "Absorb Positive",
				ABSORBNEGATIVE = "Absorb Negative",
				SELECTSTOPOPTIONS = "Target Stop Options",
				SELECTSTOPOPTIONSTOOLTIP = "Supported: 'Healing Engine'\n\nThese options affect only @target selection, and specifically\nprevent its selection if one of the options is successful\n\nRight click: Create macro",
				SELECTSTOPOPTIONS1 = "@mouseover friendly",
				SELECTSTOPOPTIONS2 = "@mouseover enemy",
				SELECTSTOPOPTIONS3 = "@target enemy",
				SELECTSTOPOPTIONS4 = "@target boss",
				SELECTSTOPOPTIONS5 = "@player dead",
				SELECTSTOPOPTIONS6 = "sync-up 'Rotation doesn't work if'",
				SELECTSORTMETHOD = "Target Sort Method",
				SELECTSORTMETHODTOOLTIP = "Supported: 'Healing Engine'\n\n'Health Percent' sorts @target selection with the least health in the percent ratio\n'Health Actual' sorts @target selection with the least health in the exact ratio\n\nRight click: Create macro",
				SORTHP = "Health Percent",
				SORTAHP = "Health Actual",
				AFTERTARGETENEMYORBOSSDELAY = "Target Delay\nAfter @target enemy or boss",
				AFTERTARGETENEMYORBOSSDELAYTOOLTIP = "Supported: 'Healing Engine'\n\nDelay (in seconds) before select next target after select an enemy or boss in @target\n\nOnly works if 'Target Stop Options' has '@target enemy' or '@target boss' turned off\n\nDelay is updated every time when conditions are successful or is reset otherwise\n\nRight click: Create macro",
				AFTERMOUSEOVERENEMYDELAY = "Target Delay\nAfter @mouseover enemy",
				AFTERMOUSEOVERENEMYDELAYTOOLTIP = "Supported: 'Healing Engine'\n\nDelay (in seconds) before select next target after select an enemy in @mouseover\n\nOnly works if 'Target Stop Options' has '@mouseover enemy' turned off\n\nDelay is updated every time when conditions are successful or is reset otherwise\n\nRight click: Create macro",
				HEALINGENGINEAPI = "Enable Healing Engine API",
				HEALINGENGINEAPITOOLTIP = "When enabled, all supported 'Healing Engine' options and settings will work",
				SELECTPETS = "Enable Pets",
				SELECTPETSTOOLTIP = "Supported: 'Healing Engine'\n\nSwitches pets to handle them by all API in 'Healing Engine'\n\nRight click: Create macro",
				SELECTRESURRECTS = "Enable Resurrects",
				SELECTRESURRECTSTOOLTIP = "Supported: 'Healing Engine'\n\nToggles dead players for @target selection\n\nOnly works out of combat\n\nRight click: Create macro",
				HELP = "Help",
				HELPOK = "Gotcha",
				ENABLED = "/tar", 
				ENABLEDTOOLTIP = "Supported: 'Healing Engine'\n\nTurns off/on '/target %s'",
				UNITID = "unitID", 
				NAME = "Name",
				ROLE = "Role",
				ROLETOOLTIP = "Supported: 'Healing Engine'\n\nResponsible for priority in @target selection, which is controlled by offsets\nPets are always 'Damagers'",
				DAMAGER = "Damager",
				HEALER = "Healer",
				TANK = "Tank",
				UNKNOWN = "Unknown",
				USEDISPEL = "Dispel",
				USEDISPELTOOLTIP = "Supported: 'Healing Engine' (profile must have code for it) + 'Rotation' (profile must have code for it)\n\n'Healing Engine': Allows to '/target %s' for dispel\n'Rotation': Allows to use dispel on '%s'\n\nDispel list specified in the 'Auras' tab",
				USESHIELDS = "Shields",
				USESHIELDSTOOLTIP = "Supported: 'Healing Engine' (profile must have code for it) + 'Rotation' (profile must have code for it)\n\n'Healing Engine': Allows to '/target %s' for shields\n'Rotation': Allows to use shields on '%s'",
				USEHOTS = "HoTs",
				USEHOTSTOOLTIP = "Supported: 'Healing Engine' (profile must have code for it) + 'Rotation' (profile must have code for it)\n\n'Healing Engine': Allows to '/target %s' for HoTs\n'Rotation': Allows to use HoTs on '%s'",
				USEUTILS = "Utils",
				USEUTILSTOOLTIP = "Supported: 'Healing Engine' (profile must have code for it) + 'Rotation' (profile must have code for it)\n\n'Healing Engine': Allows to '/target %s' for utils\n'Rotation': Allows to use utils on '%s'\n\nUtils mean actions support category such as Freedom, some of them can be specified in the 'Auras' tab",
				GGLPROFILESTOOLTIP = "\n\nGGL profiles will skip pets for this %s ceil in 'Healing Engine'(@target selection)",
				LUATOOLTIP = "Supported: 'Healing Engine'\n\nUses the code you wrote as the last condition checked before '/target %s'",
				LUATOOLTIPADDITIONAL = "\n\nTo refer for metatable which contain 'thisunit' data such as health use:\nlocal memberData = HealingEngine.Data.UnitIDs[thisunit]\nif memberData then Print(thisunit .. ' (' .. Unit(thisunit):Name() .. ')' .. ' has real health percent: ' .. memberData.realHP .. ' and modified: ' .. memberData.HP) end",
				AUTOHIDE = "Auto Hide",
				AUTOHIDETOOLTIP = "This is only visual effect!\nAutomatically filters the list and shows only available unitID",						
				PROFILES = "Profiles",
				PROFILESHELP = [[The settings of this panel affect 'Healing Engine' + 'Rotation'
								 
								 Each profile records absolutely all the settings of the current tab
								 Thus, you can change the behavior of target selection and healing rotation on the fly
								 
								 For example: You can create one profile for working on groups 2 and 3, and the second 
								 for the entire raid, and at the same time change it with a macro, 
								 which can also be created
								 
								 It's important to understand that each change made in this tab must be manually re-saved
				]],
				PROFILE = "Profile",
				PROFILEPLACEHOLDER = "-- no profile or has unsaved changes for previous profile --",
				PROFILETOOLTIP = "Write name of the new profile in editbox below and click 'Save'\n\nChanges will not be saved in real time!\nEvery time when you make any changes in case to save them you have to click again 'Save' for selected profile",
				PROFILELOADED = "Loaded profile: ",
				PROFILESAVED = "Saved profile: ",
				PROFILEDELETED = "Deleted profile: ",
				PROFILEERRORDB = "ActionDB is not initialized!",
				PROFILEERRORNOTAHEALER = "You must be healer to use it!",
				PROFILEERRORINVALIDNAME = "Invalid profile name!",
				PROFILEERROREMPTY = "You haven't selected profile!",
				PROFILEWRITENAME = "Write name of the new profile",
				PROFILESAVE = "Save",
				PROFILELOAD = "Load",
				PROFILEDELETE = "Delete",
				CREATEMACRO = "Right click: Create macro",
				PRIORITYHEALTH = "Health Priority",
				PRIORITYHELP = [[The settings of this panel affect only 'Healing Engine'

								 Using these settings, you can change the priority of 
								 target selection depending on the settings
								 
								 These settings change virtually health, allowing 
								 the sorting method to expand units filter not only  
								 according to their real + prediction options health

								 The sorting method sorts all units for least health
								 
								 Multiplier is number by which health will be multiplied
								 
								 Offset is number that will be set as fixed percentage or 
								 processed arithmetically (-/+ HP) depending on 'Offset Mode'
								 
								 'Utils' means offensive spells such as 'Blessing of Freedom'
				]],
				MULTIPLIERS = "Multipliers",
				MULTIPLIERINCOMINGDAMAGELIMIT = "Incoming Damage Limit",
				MULTIPLIERINCOMINGDAMAGELIMITTOOLTIP = "Limits incoming real time damage since damage can be so\nlarge that the system stops 'getting off' from the @target.\nPut 1 if you want to get an unmodified value\n\nRight click: Create macro",
				MULTIPLIERTHREAT = "Threat",
				MULTIPLIERTHREATTOOLTIP = "Processed if exist an increased threat (i.e. unit is tanking)\nPut 1 if you want to get an unmodified value\n\nRight click: Create macro",
				MULTIPLIERPETSINCOMBAT = "Pets In Combat",
				MULTIPLIERPETSINCOMBATTOOLTIP = "Pets must be enabled to make it work!\nPut 1 if you want to get an unmodified value\n\nRight click: Create macro",
				MULTIPLIERPETSOUTCOMBAT = "Pets Out Combat",
				MULTIPLIERPETSOUTCOMBATTOOLTIP = "Pets must be enabled to make it work!\nPut 1 if you want to get an unmodified value\n\nRight click: Create macro",
				OFFSETS = "Offsets",
				OFFSETMODE = "Offset Mode",
				OFFSETMODEFIXED = "Fixed",
				OFFSETMODEARITHMETIC = "Arithmetic",
				OFFSETMODETOOLTIP = "'Fixed' will set exact same value in health percent\n'Arithmetic' will -/+ value to health percent\n\nRight click: Create macro",
				OFFSETSELFFOCUSED = "Self Focused (PvP)",
				OFFSETSELFFOCUSEDTOOLTIP = "Processed if enemy players targeting you in PvP mode\n\nRight click: Create macro",
				OFFSETSELFUNFOCUSED = "Self UnFocused (PvP)",
				OFFSETSELFUNFOCUSEDTOOLTIP = "Processed if enemy players NOT targeting you in PvP mode\n\nRight click: Create macro",
				OFFSETSELFDISPEL = "Self Dispel",
				OFFSETSELFDISPELTOOLTIP = "GGL profiles usually have PvE condition for it\n\nDispel list specified in the 'Auras' tab\n\nRight click: Create macro",
				OFFSETHEALERS = "Healers",
				OFFSETTANKS = "Tanks",
				OFFSETDAMAGERS = "Damagers",
				OFFSETHEALERSDISPEL = "Healers Dispel",
				OFFSETHEALERSTOOLTIP = "Processed only on other healers\n\nDispel list specified in the 'Auras' tab\n\nRight click: Create macro",
				OFFSETTANKSDISPEL = "Tanks Dispel",
				OFFSETTANKSDISPELTOOLTIP = "Dispel list specified in the 'Auras' tab\n\nRight click: Create macro",
				OFFSETDAMAGERSDISPEL = "Damagers Dispel",
				OFFSETDAMAGERSDISPELTOOLTIP = "Dispel list specified in the 'Auras' tab\n\nRight click: Create macro",
				OFFSETHEALERSSHIELDS = "Healers Shields",
				OFFSETHEALERSSHIELDSTOOLTIP = "Included self (@player)\n\nRight click: Create macro",
				OFFSETTANKSSHIELDS = "Tanks Shields",
				OFFSETDAMAGERSSHIELDS = "Damagers Shields",
				OFFSETHEALERSHOTS = "Healers HoTs",
				OFFSETHEALERSHOTSTOOLTIP = "Included self (@player)\n\nRight click: Create macro",
				OFFSETTANKSHOTS = "Tanks HoTs",
				OFFSETDAMAGERSHOTS = "Damagers HoTs",
				OFFSETHEALERSUTILS = "Healers Utils",
				OFFSETHEALERSUTILSTOOLTIP = "Included self (@player)\n\nRight click: Create macro",
				OFFSETTANKSUTILS = "Tanks Utils",
				OFFSETDAMAGERSUTILS = "Damagers Utils",
				MANAMANAGEMENT = "Mana Management",
				MANAMANAGEMENTHELP = [[The settings of this panel affect only 'Rotation'
									   
									   Profile must have code for it! 
									   
									   Works if:
									   1. Inside instance
									   2. In PvE mode 
									   3. In combat  
									   4. Group size >= 5
									   5. Have a boss(-es) focused by members
				]],
				MANAMANAGEMENTMANABOSS = "Your Mana Percent <= Average Boss(-es) Health Percent",
				MANAMANAGEMENTMANABOSSTOOLTIP = "Starts saving mana phase if condition successful\n\nLogic depends on profile which you use!\n\nNot all profiles supported this setting!\n\nRight click: Create macro",
				MANAMANAGEMENTSTOPATHP = "Stop Management\nHealth Percent",
				MANAMANAGEMENTSTOPATHPTOOLTIP = "Stops saving mana if primary unit\n(@target/@mouseover) has health percent below this value\n\nNot all profiles supported this setting!\n\nRight click: Create macro",
				OR = "OR",
				MANAMANAGEMENTSTOPATTTD = "Stop Management\nTime To Die",
				MANAMANAGEMENTSTOPATTTDTOOLTIP = "Stops saving mana if primary unit\n(@target/@mouseover) has time to die (in seconds) below this value\n\nNot all profiles supported this setting!\n\nRight click: Create macro",
				MANAMANAGEMENTPREDICTVARIATION = "Mana Conservation Effectiveness",
				MANAMANAGEMENTPREDICTVARIATIONTOOLTIP = "Only affects the 'AUTO' healing abilities settings!\n\nThis is a multiplier on which pure healing will be calculated when the mana save phase was started\n\nThe higher the level, the more mana save, but less APM\n\nRight click: Create macro",
			},
			[9] = {
				HEADBUTTON = "Hotkeys",
				FRAMEWORK = "[Each spec] Framework",
				HOTKEYINSTRUCTION = "Press or click any hotkey or mouse button to assign",
				META = "Meta",
				METAENGINEROWTT = "Double Left Click assign hotkey\nDouble Right Click unassign hotkey",
				ACTION = "Action",
				HOTKEY = "Hotkey",
				HOTKEYASSIGN = "Create",
				HOTKEYUNASSIGN = "Unbind",
				ASSIGNINCOMBAT = "|cffff0000Can't assign in combat!",
				PRIORITIZEPASSIVE = "Prioritize Passive",
				PRIORITIZEPASSIVETT = "Enabled: Rotation, Secondary Rotation will do passive rotation first, then native rotation on down click\nDisabled: Rotation, Secondary Rotation will do native rotation on down click, then passive rotation on up click",
				CHECKSELFCAST = "checkselfcast",
				CHECKSELFCASTTT = "Enabled: If the SELFCAST modifier is held down, resolves the unit to player on click buttons",
				UNITTT = "Enables or disables click buttons for this unit in passive rotation",
			},
		},
	},
	ruRU = {
		NOSUPPORT = "данный профиль еще не поддерживает ActionUI",
		DEBUG = "|cffff0000[Debug] Идентификатор ошибки: |r",			
		ISNOTFOUND = "не найдено!",				
		CREATED = "создан",
		YES = "Да",
		NO = "Нет",	
		TOGGLEIT = "Переключить",
		SELECTED = "Выбрано",
		RESET = "Сброс",
		RESETED = "Сброшено",
		MACRO = "Макрос",
		MACROEXISTED = "|cffff0000Макрос уже существует!|r",
		MACROLIMIT = "|cffff0000Не удается создать макрос, вы достигли лимита. Удалите хотя бы один макрос!|r",
		MACROINCOMBAT = "|cffff0000Не удается создать макрос в бою. Вы должны выйти из боя!|r",
		MACROSIZE = "|cffff0000Размер макроса не может превышать 255 байт!|r",
		GLOBALAPI = "API Глобальное: ",	
		RESIZE = "Изменить размер",
		RESIZE_TOOLTIP = "Чтобы изменить размер, нажмите и тащите",	
		CLOSE = "Закрыть",
		APPLY = "Применить",
		UPGRADEDFROM = "обновлен с ",
		UPGRADEDTO = " до ",
		PROFILESESSION = {
			BUTTON = "Сессия профиля\nЛевый щелчок открывает панель пользователя\nПравый щелчок открывает панель разработки",
			BNETSAVED = "Ваш пользовательский ключ успешно сохранен в кеше для офлайн сессии профиля!",
			BNETMESSAGE = "Battle.net оффлайн!\nПожалуйста, перезапустите игру с включенным Battle.net!",
			BNETMESSAGETRIAL = "!! Ваш персонаж является пробным и не может использовать офлайн сессию профиля !!",
			EXPIREDMESSAGE = "Ваша подписка на %s истекла!\nПожалуйста, обратитесь к разработчику профиля!",
			AUTHMESSAGE = "Спасибо за использование премиум профиля\nДля авторизации вашего ключа, пожалуйста, обратитесь к разработчику профиля!",
			AUTHORIZED = "Ваш ключ авторизован!",
			REMAINING = "[%s] осталось %d сек.",
			DISABLED = "[%s] |cffff0000истекла сессия!|r",
			PROFILE = "Профиль:",
			TRIAL = "(пробный)",
			FULL = "(премиум)",
			UNKNOWN = "(не авторизован)",
			DEVELOPMENTPANEL = "Разработка",
			USERPANEL = "Пользователь",
			PROJECTNAME = "Имя Проекта",
			PROJECTNAMETT = "Ваша разработка/проект/рутины/бренд название",
			SECUREWORD = "Кодовое Слово",
			SECUREWORDTT = "Ваше кодовое слово как мастер пароль к имени проекта",
			KEYTT = "'dev_key' используется в ProfileSession:Setup('dev_key', {...})",		
			KEYTTUSER = "Отошлите этот ключ автору профиля!",
		},
		SLASH = {
			LIST = "Список слеш команд:",
			OPENCONFIGMENU = "открыть конфиг меню Action",
			OPENCONFIGMENUTOASTER = "открыть конфиг меню Toaster",
			HELP = "помощь и информация",
			QUEUEHOWTO = "макрос (переключатель) для системы очередности (Очередь), там где TABLENAME это метка для ИмениСпособности|ИмениПредмета (на английском)",
			QUEUEEXAMPLE = "пример использования Очереди",
			BLOCKHOWTO = "макрос (переключатель) для отключения|включения любых действий (Блокировка), там где TABLENAME это метка для ИмениСпособности|ИмениПредмета (на английском)",
			BLOCKEXAMPLE = "пример использования Блокировки",
			RIGHTCLICKGUIDANCE = "Большинство элементов кликабельны левой и правой кнопкой мышки. Правая кнопка мышки создаст макрос, так что вы можете не брать во внимание выше изложенную подсказку",						
			INTERFACEGUIDANCE = "UI пояснения:",
			INTERFACEGUIDANCEEACHSPEC = "[Каждый спек] относится к ТЕКУЩЕЙ выбранной специализации",
			INTERFACEGUIDANCEALLSPECS = "[Все спеки] относится ко ВСЕМ доступным на персонаже специализациям",
			INTERFACEGUIDANCEGLOBAL = "[Глобально] относится к ВСЕМУ вашему аккаунту, к ВСЕМ персонажам, к ВСЕМ специализациям",
			ATTENTION = "|cffff0000ОБРАТИТЕ ВНИМАНИЕ|r функционал Action доступен лишь для профилей вышедших после 31.05.2019. Предыдущие профиля будут обновлены для этой системы в будущем",		
			TOTOGGLEBURST = "чтобы переключить Режим Бурстов",
			TOTOGGLEMODE = "чтобы переключить PvP / PvE",
			TOTOGGLEAOE = "чтобы переключить AoE",
		},
		TAB = {
			RESETBUTTON = "Сбросить настройки",
			RESETQUESTION = "Вы точно уверены?",
			SAVEACTIONS = "Сохранить Настройки Действий",
			SAVEINTERRUPT = "Сохранить Списки Прерываний",
			SAVEDISPEL = "Сохранить Списки Аур",
			SAVEMOUSE = "Сохранить Списки Курсора",
			SAVEMSG = "Сохранить Списки MSG",			
			SAVEHE = "Сохранить Настройки Системы Исцеления",
			SAVEHOTKEYS = "Сохранить Настройки Клавиш",
			LUAWINDOW = "LUA Конфигурация",
			LUATOOLTIP = "Для обращения к проверяемому юниту используйте 'thisunit' без кавычек\nКод должен иметь логический возрат (true) для того чтобы условия срабатывали\nКод имеет setfenv, это означает, что не нужно использовать Action. для чего-либо что имеет это\n\nЕсли вы хотите удалить по-умолчанию установленный код, то нужно написать 'return true' без кавычек,\nвместо простого удаления",	
			BRACKETMATCH = "Закрывать Скобки",
			CLOSELUABEFOREADD = "Закройте LUA Конфигурацию прежде чем добавлять",
			FIXLUABEFOREADD = "Исправьте ошибки в LUA Конфигурации прежде чем добавлять",
			RIGHTCLICKCREATEMACRO = "Правая кнопка мышки: Создать макрос",
			ROWCREATEMACRO = "Правая кнопка мышки: Создать макрос устанавливающий текущее значение для всех ячеек в этой строке\nShift + Правая кнопка мышки: Создать макрос устанавливающий противоположное значение для всех 'boolean' ячеек в этой строке",
			CEILCREATEMACRO = "Правая кнопка мышки: Создать макрос устанавливающий '%s' значение для '%s' ячейки в этой строке\nShift + Правая кнопка мышки: Создать макрос устанавливающий '%s' значение для '%s' ячейки-\n-и противоположное значение для других 'boolean' ячеек в этой строке",
			NOTHING = "Профиль не имеет конфигурации для этой вкладки",
			HOW = "Применить:",
			HOWTOOLTIP = "Глобально: Весь аккаунт, все персонажи и все спеки",
			GLOBAL = "Глобально",
			ALLSPECS = "Ко всем специализациям персонажа",
			THISSPEC = "К текущей специализации персонажа",			
			KEY = "Ключ:",	
			CONFIGPANEL = "'Добавить' Конфигурация",
			BLACKLIST = "Черный Список",
			LANGUAGE = "[Русский]",
			AUTO = "Авто",
			SESSION = "Сессия: ",
			PREVIEWBYTES = "Предпросмотр: %s байтов (255 макс. лимит, 210 макс. рекомендуется)",
			[1] = {
				HEADBUTTON = "Общее",
				HEADTITLE = "[Каждый спек] Основное",					
				PVEPVPTOGGLE = "PvE / PvP Ручной Переключатель",
				PVEPVPTOGGLETOOLTIP = "Принудительно переключить профиль в другой режим\n(особенно полезно при включенном Режиме Войны)\n\nПравая кнопка мышки: Создать макрос", 
				PVEPVPRESETTOOLTIP = "Сброс ручного переключателя в автоматический выбор",
				CHANGELANGUAGE = "Смена языка",
				CHARACTERSECTION = "Секция Персонажа",
				AUTOTARGET = "Авто Цель",
				AUTOTARGETTOOLTIP = "Если цель пуста, но вы в бою, то вернет ближайшего противника в цель\nАналогично работает свитчер если в PvP цель имеет иммунитет\n\nПравая кнопка мышки: Создать макрос",					
				POTION = "Зелье",
				HEARTOFAZEROTH = "Сердце Азерота",
				COVENANT = "Завет Способности",
				RACIAL = "Расовая Способность",
				STOPCAST = "Стоп Произнесение",
				SYSTEMSECTION = "Секция Систем",
				LOSSYSTEM = "LOS Система",
				LOSSYSTEMTOOLTIP = "ВНИМАНИЕ: Эта опция вызывает задержку 0.3сек + тек. крутящийся гкд\nесли проверяемый юнит находится в лосе (например за столбом на арене)\nВы также должны включить такую же настройку в Advanced Settings\nДанная опция заносит в черный список проверяемого юнита\nи перестает на N секунд предоставлять к нему действия если юнит в лосе\n\nПравая кнопка мышки: Создать макрос",
				STOPATBREAKABLE = "Стоп урон на ломающемся контроле",
				STOPATBREAKABLETOOLTIP = "Остановит вредоносный урон по врагам\nЕсли у них есть CC, например, Превращение\nЭто не отменяет автоатаку!\n\nПравая кнопка мышки: Создать макрос",
				BOSSTIMERS = "Босс Таймеры",
				BOSSTIMERSTOOLTIP = "Требует DBM или BigWigs аддоны\n\nОтслеживает пулл таймер и некоторые спец. события такие как 'след.треш'.\nЭта опция доступна не для всех профилей!\n\nПравая кнопка мышки: Создать макрос",
				FPS = "FPS Оптимизация",
				FPSSEC = " (сек)",
				FPSTOOLTIP = "AUTO: Повышение кадров в секунду за счет увеличения в динамической зависимости\nкадров интервала обновления (вызова) цикла ротации\n\nВы также можете вручную задать интервал следуя простому правилу:\nЧем больше ползунок, тем больше кадров, но хуже обновление ротации\nСлишком высокое значение может вызвать непредсказуемое поведение!\n\nПравая кнопка мышки: Создать макрос",					
				PVPSECTION = "Секция PvP",
				REFOCUS = "Возвращать предыдущий сохраненный @focus (arena1-5 юниты только)\nРекомендуется против классов с невидимостью\n\nПравая кнопка мышки: Создать макрос",
				RETARGET = "Возвращать предыдущий сохраненный @target (arena1-5 юниты только)\nРекомендуется против Охотников с 'Притвориться мертвым'\nи(или) при любых непредвиденных сбросов цели\n\nПравая кнопка мышки: Создать макрос",
				TRINKETS = "Аксессуары",
				TRINKET = "Аксессуар",
				BURST = "Режим Бурстов",
				BURSTEVERYTHING = "Все что угодно",
				BURSTTOOLTIP = "Все что угодно - По доступности способности\nАвто - Босс или Игрок\nOff - Выключено\n\nПравая кнопка мышки: Создать макрос\nЕсли вы предпочитаете фиксированное состояние, то используйте аргумент: 'Everything', 'Auto', 'Off'\n/run Action.ToggleBurst('Everything', 'Auto')",					
				HEALTHSTONE = "Камень здоровья | Лечебное зелье",
				HEALTHSTONETOOLTIP = "Выставить процент своего здоровья при котором использовать\n\nПравая кнопка мышки: Создать макрос",
				COLORTITLE = "Палитра Цветов",
				COLORUSE = "Использовать пользовательский цвет",
				COLORUSETOOLTIP = "Переключатель между стандартными и пользовательскими цветами",
				COLORELEMENT = "Элемент",
				COLOROPTION = "Опция",
				COLORPICKER = "Выбиратель цвета",
				COLORPICKERTOOLTIP = "Нажмите, чтобы открыть окно настройки для выбранного 'Элемент' > 'Параметр'\nПравая кнопка мыши, чтобы переместить открытое окно",
				FONT = "Шрифт",
				NORMAL = "Нормальный",
				DISABLED = "Отключенный",
				HEADER = "Заголовок",
				SUBTITLE = "Подзаголовок",
				TOOLTIP = "Подсказка",
				BACKDROP = "Фон",
				PANEL = "Панель",
				SLIDER = "Ползунок",
				HIGHLIGHT = "Подсветка",
				BUTTON = "Кнопка",
				BUTTONDISABLED = "Кнопка Отключенная",
				BORDER = "Бордюр",
				BORDERDISABLED = "Бордюр Отключенный",	
				PROGRESSBAR = "Индикатор",
				COLOR = "Цвет",
				BLANK = "Пустая",
				SELECTTHEME = "Выбрать Готовую Тему",
				THEMEHOLDER = "выбрать тему",
				BLOODYBLUE = "Кроваво-Синий",
				ICE = "Ледяной",
				AUTOATTACK = "Авто Атака",
				AUTOSHOOT = "Авто Выстрел",	
				PAUSECHECKS = "[Все спеки]\nРотация не работает если:",
				ANTIFAKEPAUSES = "Паузы AntiFake",
				ANTIFAKEPAUSESSUBTITLE = "Пока горячая клавиша удерживается",
				ANTIFAKEPAUSESTT = "В зависимости от выбора горячей клавиши,\nпри ее удержании будет работать только предназначенный для нее код",
				VEHICLE = "В спец.транспорте",
				VEHICLETOOLTIP = "Например: Катапульта, Обстреливающая пушка",
				DEADOFGHOSTPLAYER = "Вы мертвы",
				DEADOFGHOSTTARGET = "Цель мертва",
				DEADOFGHOSTTARGETTOOLTIP = "Исключение вражеский Охотник если выбран в качестве цели",
				MOUNT = "Вы на\nтранспорте",
				COMBAT = "Не в бою", 
				COMBATTOOLTIP = "Если Вы и Ваша цель не в бою. Исключение незаметность\n(будучи в скрытости это условие не работает)",
				SPELLISTARGETING = "Курсор ожидает клик",
				SPELLISTARGETINGTOOLTIP = "Например: Снежная Буря, Героический прыжок, Замораживающая ловушка",
				LOOTFRAME = "Открыто окно добычи\n(лута)",		
				EATORDRINK = "Вы Пьете или Едите",
				MISC = "Разное:",
				DISABLEROTATIONDISPLAY = "Скрыть отображение\nротации",
				DISABLEROTATIONDISPLAYTOOLTIP = "Скрывает группу, которая обычно в\nцентральной нижней части экрана",
				DISABLEBLACKBACKGROUND = "Скрыть черный фон", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Скрывает черный фон в левом верхнем углу\nВНИМАНИЕ: Это может вызвать непредсказуемое поведение!",
				DISABLEPRINT = "Скрыть печать",
				DISABLEPRINTTOOLTIP = "Скрывает уведомления этого UI в чате\nВНИМАНИЕ: Это также скрывает [Debug] Идентификатор ошибки!",
				DISABLEMINIMAP = "Скрыть значок на миникарте",
				DISABLEMINIMAPTOOLTIP = "Скрывает значок этого UI",
				DISABLEPORTRAITS = "Скрыть классовый портрет",
				DISABLEROTATIONMODES = "Скрыть режимы ротации",
				DISABLESOUNDS = "Отключить звуки",
				DISABLEADDONSCHECK = "Отключить проверку аддонов",
				HIDEONSCREENSHOT = "Скрывать на скриншоте",
				HIDEONSCREENSHOTTOOLTIP = "Во время скриншота прячет все фреймы TellMeWhen\nи Action, а после показывает их обратно",
			},			
			[2]	= {
				COVENANTCONFIGURE = "Опции Завета",
				PROFILECONFIGURE = "Опции Профиля",
				FLESHCRAFTHP = "Скульптор плоти\nПроцент Здоровья",
				FLESHCRAFTTTD = "Скульптор плоти\nВремя До Смерти",
				PHIALOFSERENITYHP = "Флакон Безмятежности\nПроцент Здоровья",
				PHIALOFSERENITYTTD = "Флакон Безмятежности\nВремя До Смерти",
				PHIALOFSERENITYDISPEL = "Флакон Безмятежности - Диспел",
				PHIALOFSERENITYDISPELTOOLTIP = "Если включено, то будут сниматься эффекты, указанные во вкладке 'Ауры', независимо от чекбоксов той же вкладке\n\n",
				AND = "И",
				OR = "Или",
				OPERATOR = "Оператор",
				TOOLTIPOPERATOR = "Это логический оператор между двумя соседними условиями\nЕсли выбрано 'И', то оба должны быть успешными\nЕсли выбран вариант 'Или', то должно выполняться одно из двух условий\n\n",
				TOOLTIPTTD = "Это значение в секундах, сравнивается как <=\nЭто математический расчет на основе входящего урона до смерти\n\n",
				TOOLTIPHP = "Это значение в процентах, сравнивается как <=\nЭто текущее здоровье персонажа в процентах\n\n",
			},
			[3] = {
				HEADBUTTON = "Действия",
				HEADTITLE = "Блокировка | Очередь",
				ENABLED = "Включено",
				NAME = "Название",
				DESC = "Заметка",
				ICON = "Значок",
				SETBLOCKER = "Установить\nБлокировку",
				SETBLOCKERTOOLTIP = "Это заблокирует выбранное действие в ротации\nЭто никогда не будет использовано\n\nПравая кнопка мыши: Создать макрос", 
				SETQUEUE = "Установить\nОчередь",
				SETQUEUETOOLTIP = "Это поставит действие в очередь ротации\nЭто использует действие по первой доступности\n\nПравая кнопка мыши: Создать макрос\nВы можете передать дополнительные условия в созданном макросе для очереди\nТакие как на какой цели использовать (UnitID является ключом), например: { Priority = 1, UnitID = 'player' }\nВы можете найти ключи с описанием в функции 'Action:SetQueue' (Action.lua)", 
				BLOCKED = "|cffff0000Заблокировано: |r",
				UNBLOCKED = "|cff00ff00Разблокировано: |r",
				KEY = "[Ключ: ",
				KEYTOTAL = "[Суммарно Очереди: ",
				KEYTOOLTIP = "Используйте этот ключ во вкладке 'Сообщения'",
				MACRO = "Макрос",
				MACROTOOLTIP = "Макрос должен быть коротким, размер макроса ограничен 255 байт\nпримерно 45 байт зарезервированы для мультицепочек, поддерживается многострочность\n\nЕсли макрос опущен, будет использовано автогенерируемое стандартное оформление:\n\"/cast [@unitID]spellName\" или \"/cast [@unitID]spellName(Rank %d)\" или \"/use item:itemID\"\n\nМакрос всегда должен добавляться к действиям, в которых есть что-то вроде\n/cast [@player]spell:thisID\n/castsequence reset=1 spell:thisID, nil\n\nПоддерживаются шаблоны:\n\"spell:12345\" будет заменено на имя заклинания, полученное по номеру\n\"thisID\" будет заменено на self.SlotID или self.ID\n\"(Rank %d+)\" заменит Rank на локализованное слово\nЛюбые шаблоны можно комбинировать, например \"spell:thisID(Rank 1)\"",
				ISFORBIDDENFORMACRO = "запрещен для изменения макроса!",
				ISFORBIDDENFORBLOCK = "запрещен для установки в блокировку!",
				ISFORBIDDENFORQUEUE = "запрещен для установки в очередь!",
				ISQUEUEDALREADY = "уже в состоит в очереди!",
				QUEUED = "|cff00ff00Установлен в очередь: |r",
				QUEUEREMOVED = "|cffff0000Удален из очереди: |r",
				QUEUEPRIORITY = " имеет приоритет #",
				QUEUEBLOCKED = "|cffff0000не может быть поставлен в очередь поскольку установлена блокировка!|r",
				SELECTIONERROR = "|cffff0000Вы не выбрали строку!|r",
				AUTOHIDDEN = "[Все спеки] АвтоСкрытие недоступных действий",
				AUTOHIDDENTOOLTIP = "Делает прокручивающейся список меньше и чистее за счет визуального скрытия\nНапример, класс персонажа имеет несколько расовых способностей, но может использовать лишь одну, эта опция скроет остальные\nПросто для удобства просмотра",
				CHECKSPELLLVL = "[Все спеки] Проверять необходимый уровень способности",
				CHECKSPELLLVLTOOLTIP = "Все способности которые не доступны по уровню персонажа будут заблокированы\nОни будут обновляться каждый раз по достижению нового уровня",					
				CHECKSPELLLVLERROR = "Уже инициализировано!",
				CHECKSPELLLVLERRORMAXLVL = "Вы на МАКСИМАЛЬНО возможном уровне!",
				CHECKSPELLLVLMACRONAME = "Проверять Уровень Способностей",
				LUAAPPLIED = "LUA код был добавлен к ",
				LUAREMOVED = "LUA код был удален из ",
			},
			[4] = {
				HEADBUTTON = "Прерывания",	
				HEADTITLE = "Прерывания Профиля",					
				ID = "ID",
				NAME = "Название",
				ICON = "Значок",
				USEKICK = "Киком",
				USECC = "СС",
				USERACIAL = "Расовой",
				MIN = "Мин: ",
				MAX = "Макс: ",
				SLIDERTOOLTIP = "Устанавливает прерывание между минимальной и максимальной процентной продолжительностью произнесения\n\nКрасный цвет значений означает, что они слишком близки друг к другу и опасны для использования\n\nСостояние OFF означает, что эти ползунки не доступны для этого списка",
				USEMAIN = "[Main] Использовать",
				USEMAINTOOLTIP = "Включает или отключает список с его юнитами для прерывания\n\nПравый щелчок: Создать макрос",
				MAINAUTO = "[Main] Авто",
				MAINAUTOTOOLTIP = "Если включено:\nPvE: Прерывает любое доступное произнесение\nPvP: Если юнит является лекарем и умрет менее чем за 6 секунд, либо если это игрок находящийся вне зоны досягаемости вражеских целителей\n\nЕсли отключено:\nПрерывает только заклинания, добавленные в таблицу для этого списка\n\nПравый щелчок: Создать макрос",
				USEMOUSE = "[Mouse] Использовать",
				USEMOUSETOOLTIP = "Включает или отключает список с его юнитами для прерывания\n\nПравый щелчок: Создать макрос",
				MOUSEAUTO = "[Mouse] Авто",
				MOUSEAUTOTOOLTIP = "Если включено:\nPvE: Прерывает доступное произнесение\nPvP: Прерывает только заклинания, добавленные в таблицу для PvP и Heal списков, и только игроков\n\nЕсли отключено:\nПрерывает только заклинания, добавленные в таблицу для этого списка\n\nПравый щелчок: Создать макрос",
				USEHEAL = "[Heal] Использовать",
				USEHEALTOOLTIP = "Включает или отключает список с его юнитами для прерывания\n\nПравый щелчок: Создать макрос",
				HEALONLYHEALERS = "[Heal] Только Лекарей",
				HEALONLYHEALERSTOOLTIP = "Если включено:\nПрерывает только лекарей\n\nЕсли отключено:\nПрерывает любую роль врага\n\nПравый щелчок: Создать макрос",
				USEPVP = "[PvP] Использовать",
				USEPVPTOOLTIP = "Включает или отключает список с его юнитами для прерывания\n\nПравый щелчок: Создать макрос",
				PVPONLYSMART = "[PvP] Умный",
				PVPONLYSMARTTOOLTIP = "Если включено, будет прерывать продвинутой логикой:\n1) Цепочка контроля вашего лекаря\n2) У кого-то есть эффект бурста >4 сек\n3) Кто-то умрет менее чем за 8 секунд\n4) Вы (или @target) HP приближаетесь к Казнь фазе\n\nЕсли отключено, будет прерывать без продвинутой логики\n\nПравый клик: Создать макрос",				
				INPUTBOXTITLE = "Введите способность:",
				INPUTBOXTOOLTIP = "ESCAPE (ESC): стереть текст и убрать фокус ввода",
				SEARCH = "Поиск по имени или ID",
				INTEGERERROR = "Целочисленное переполнение при попытке ввода > 7 чисел", 				
				ADD = "Добавить Прерывание",
				ADDERROR = "|cffff0000Вы ничего не указали в 'Введите способность'\nили способность не найдена!|r",				
				ADDTOOLTIP = "Добавить способность из поля ввода 'Введите способность' в текущий выбранный список",					
				REMOVE = "Удалить Прерывание",
				REMOVETOOLTIP = "Удалить выбранную способность в прокручивающейся таблице из текущего списка",					
			},
			[5] = { 
				HEADBUTTON = "Ауры",					
				USETITLE = "[Каждый спек]",
				USEDISPEL = "Использовать Диспел",
				USEPURGE = "Использовать Пурж",
				USEEXPELENRAGE = "Снимать Исступления",
				HEADTITLE = "[Глобально]",	
				MODE = "Режим:",
				CATEGORY = "Категория:",
				POISON = "Диспел ядов",
				DISEASE = "Диспел болезней",
				CURSE = "Диспел проклятий",
				MAGIC = "Диспел магического",
				MAGICMOVEMENT = "Диспел магич. замедлений/рут",
				PURGEFRIENDLY = "Пурж союзников",
				PURGEHIGH = "Пурж врагов (высокий приоритет)",
				PURGELOW = "Пурж врагов (низкий приоритет)",
				ENRAGE = "Снятие исступлений",
				BLEEDS = "Кровотечения",
				BLESSINGOFPROTECTION = "Благословение защиты",
				BLESSINGOFFREEDOM = "Благословение cвободы",
				BLESSINGOFSACRIFICE = "Благословение жертвенности",
				BLESSINGOFSANCTUARY = "Благословение святилища",	
				ROLE = "Роль",
				ID = "ID",
				NAME = "Название",
				DURATION = "Длитель-\nность >",
				STACKS = "Стаки\n >=",
				ICON = "Значок",
				ROLETOOLTIP = "Ваша роль для использования этого",
				DURATIONTOOLTIP = "Реагировать если продолжительность ауры больше (>) указанных секунд\nВНИМАНИЕ: Ауры без продолжительности такие как 'Божественное одобрение'\n(Свет Паладин) должны быть 0. Это значит аура присутствует!",
				STACKSTOOLTIP = "Реагировать если кол-во ауры (стаки) больше (>=) указанных",					
				BYID = "Использовать ID\nвместо Имени",
				BYIDTOOLTIP = "По ID должны проверяться ВСЕ способности, которые имеют\nодинаковое имя, но подразумевают разные ауры.\nТакие как 'Нестабильное колдовство'",					
				CANSTEALORPURGE = "Только если можно\nукрасть или спуржить",					
				ONLYBEAR = "Только если юнит\nв 'Облике медведя'",									
				CONFIGPANEL = "'Добавить Ауру' Конфигурация",
				ANY = "Любая",
				HEALER = "Лекарь",
				DAMAGER = "Танк|Урон",
				ADD = "Добавить Ауру",					
				REMOVE = "Удалить Ауру",				
			},				
			[6] = {
				HEADBUTTON = "Курсор",
				HEADTITLE = "Взаимодействие Мышки",		
				USETITLE = "[Каждый спек] Конфигурация кнопок:",
				USELEFT = "Использовать Левый щелчок",
				USELEFTTOOLTIP = "Используется макрос /target mouseover это не является самим щелчком!\n\nПравая кнопка мыши: Создать макрос",
				USERIGHT = "Использовать Правый щелчок",
				LUATOOLTIP = "Для обращения к проверяемому юниту используйте 'thisunit' без кавычек\nЕсли вы используете LUA в категории 'GameToolTip' тогда thisunit не имеет никакого значения\nКод должен иметь логический возрат (true) для того чтобы условия срабатывали\nКод имеет setfenv, это означает, что не нужно использовать Action. для чего-либо что имеет это\n\nЕсли вы хотите удалить по-умолчанию установленный код, то нужно написать 'return true'без кавычек,\nвместо простого удаления",														
				BUTTON = "Щелчок",
				NAME = "Название",
				LEFT = "Левый щелчок",
				RIGHT = "Правый щелчок",
				ISTOTEM = "Является тотемом",
				ISTOTEMTOOLTIP = "Если включено, то будет проверять @mouseover на тип 'Тотем' для данного имени\nТакже предотвращает клик в случае если в @target уже есть какой-либо тотем",
				INPUTTITLE = "Введите название объекта (на русском!)", 
				INPUT = "Этот ввод является не чувствительным к регистру",
				ADD = "Добавить",
				REMOVE = "Удалить",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "тотем духовной связи",
				HEALINGTIDETOTEM = "тотем целительного прилива",
				CAPACITORTOTEM = "тотем конденсации",					
				SKYFURYTOTEM = "тотем небесной ярости",					
				ANCESTRALPROTECTIONTOTEM = "тотем защиты предков",					
				COUNTERSTRIKETOTEM = "тотем контрудара",
				EXPLOSIVES = "взрывчатка",
				WRATHGUARD = "страж гнева",
				FELGUARD = "страж скверны",
				INFERNAL = "инфернал",
				SHIVARRA = "шиварра",
				DOOMGUARD = "страж ужаса",
				FELHOUND = "гончая скверны",
				["UR'ZUL"] = "ур'зул",
				-- Optional totems
				TREMORTOTEM = "тотем трепета",
				GROUNDINGTOTEM = "тотем заземления",
				WINDRUSHTOTEM = "тотем ветряного порыва",
				EARTHBINDTOTEM = "тотем оков земли",
				-- GameToolTips
				ALLIANCEFLAG = "флаг альянса",
				HORDEFLAG = "флаг орды",
				NETHERSTORMFLAG = "флаг пустоверти",
				ORBOFPOWER = "сфера могущества",
			},
			[7] = {
				HEADBUTTON = "Сообщения",
				HEADTITLE = "Система Сообщений",
				USETITLE = "[Каждый спек]",
				MSG = "MSG Система",				
				MSGTOOLTIP = "Включено: работает\nНЕ включено: не работает\n\nПравая кнопка мыши: Создать макрос",
				CHANNELS = "Каналы",
				CHANNEL = "Канал ",		
				DISABLERETOGGLE = "Блокировать снятие очереди",
				DISABLERETOGGLETOOLTIP = "Предотвращает повторным сообщением удаление из системы очереди\nИными словами позволяет спамить макрос без риска быть снятым\n\nПравая кнопка мыши: Создать макрос",
				MACRO = "Макрос для вашей группы:",
				MACROTOOLTIP = "Это то, что должно посылаться в чат группы для срабатывания назначенного действия по заданному ключу\nЧтобы адресовать действие к конкретному юниту допишите их в макрос или оставьте как есть для назначения в Single/AoE ротацию\nПоддерживаются: raid1-40, party1-4, player, arena1-5\nТОЛЬКО ОДИН ЮНИТ ЗА ОДНО СООБЩЕНИЕ!\n\nВаши напарники могут использовать макрос также, но осторожно, они должны быть лояльны к этому!\nНЕ ДАВАЙТЕ МАКРОС НЕЗНАКОМЦАМ И ЛЮДЯМ НЕ В ТЕМЕ!",
				KEY = "Ключ",
				KEYERROR = "Вы не указали ключ!",
				KEYERRORNOEXIST = "ключ не существует!",
				KEYTOOLTIP = "Вы должны указать ключ, чтобы привязать действие\nВы можете извлечь ключ во вкладке 'Действия'",
				MATCHERROR = "данное имя уже совпадает, используйте другое!",
				SOURCE = "Имя сказавшего",	
				WHOSAID = "Кто сказал",
				SOURCETOOLTIP = "Это опционально. Вы можете оставить это пустым (рекомендуется)\nВ случае если вы хотите настроить это, то имя должно быть точно таким же как в группе чата",
				NAME = "Содержит в сообщении",
				ICON = "Значок",
				INPUT = "Введите фразу для системы сообщений",
				INPUTTITLE = "Фраза",
				INPUTERROR = "Вы не ввели фразу!",
				INPUTTOOLTIP = "Фраза будет срабатывать на любое совпадение в чате группы (/party)\nЯвляется не чувствительным к регистру\nСодержит патерны, это означает, что сказанная кем-то фраза с комбинацией слов raid, party, arena, party или player\nпереназначит действие на нужный мета слот\nВам не нужно задавать перечисленные патерны здесь, они используются как приписка к макросу\nЕсли патерн не найден, то будут использоваться слоты для Single и AoE ротаций",
			},
			[8] = {
				HEADBUTTON = "Система Исцеления",
				OPTIONSPANEL = "Опции",
				OPTIONSPANELHELP = [[Настройки этой панели влияют на 'Healing Engine' + 'Rotation'
				
									'Healing Engine' это название мы относим к системе выбора @target через
									макрос /target 'unitID'
									
									'Rotation' это название мы относим к самой исцеление/урон наносящей ротации
									для текущего главного юнита (@target или @mouseover)
									
									Иногда вы будете видеть текст 'профиль должен иметь код для этого', который 
									имеет в виду, что относяющиеся функции могут не работать без добавления от 
									автора профиля специального кода для этого внутри lua фрагментов
									
									Каждый элемент имеет подсказу, так что читайте это осторожно и тестируйте
									если необходимо в сценарии 'Арена испытаний' прежде чем начать реальный бой]],
				SELECTOPTIONS = "-- выберите опции --",
				PREDICTOPTIONS = "Опции Прогноза",
				PREDICTOPTIONSTOOLTIP = "Поддерживает: 'Healing Engine' + 'Rotation' (профиль должен иметь код для этого)\n\nЭти опции влияют на:\n1. Прогноз здоровья участника группы для @target выбора ('Healing Engine')\n2. Калькуляция какое следующее исцеляющее действие использовать на @target/@mouseover ('Rotation')\n\nПравая кнопка мышки: Создать макрос",
				INCOMINGHEAL = "Входящее исцеление",
				INCOMINGDAMAGE = "Входящий урон",
				THREATMENT = "Угроза (PvE)",
				SELFHOTS = "ХоТы",
				ABSORBPOSSITIVE = "Поглощение Положительное",
				ABSORBNEGATIVE = "Поглощение Негативное",
				SELECTSTOPOPTIONS = "Цель Стоп Опции",
				SELECTSTOPOPTIONSTOOLTIP = "Поддерживает: 'Healing Engine'\n\nЭти опции влияют только на выбор @target, и конкретно\nпредотвращают этот выбор если одна из опций является успешной\n\nПравая кнопка мышки: Создать макрос",
				SELECTSTOPOPTIONS1 = "@mouseover союзник",
				SELECTSTOPOPTIONS2 = "@mouseover противник",
				SELECTSTOPOPTIONS3 = "@target противник",
				SELECTSTOPOPTIONS4 = "@target босс",
				SELECTSTOPOPTIONS5 = "@player мертв",
				SELECTSTOPOPTIONS6 = "синхр. 'Ротация не работает если'",
				SELECTSORTMETHOD = "Цель Метод Сортировки",
				SELECTSORTMETHODTOOLTIP = "Поддерживает: 'Healing Engine'\n\n'Процентное Здоровье' сортирует выбор @target по наименьшему здоровью в процентном соотношении\n'Актуальное Здоровье' сортирует выбор @target по наименьшему здоровью в точном соотношении\n\nПравая кнопка мышки: Создать макрос",
				SORTHP = "Процентное Здоровье",
				SORTAHP = "Актуальное Здоровье",
				AFTERTARGETENEMYORBOSSDELAY = "Задержка Цели\nПосле @target противника или босса",
				AFTERTARGETENEMYORBOSSDELAYTOOLTIP = "Поддерживает: 'Healing Engine'\n\nЗадержка (в секундах) прежде чем выбрать следующую цель после выбора противника или босса в @target\n\nРаботает только если 'Цель Стоп Опции' имеет '@target противник' или '@target босс' выключенным\n\nЗадержка обновляется каждый раз когда условия являются успешными или сбрасывается в ином случае\n\nПравая кнопка мышки: Создать макрос",
				AFTERMOUSEOVERENEMYDELAY = "Задержка Цели\nПосле @mouseover противника",
				AFTERMOUSEOVERENEMYDELAYTOOLTIP = "Поддерживает: 'Healing Engine'\n\nЗадержка (в секундах) прежде чем выбрать следующую цель после выбора противника в @mouseover\n\nРаботает только если 'Цель Стоп Опции' имеет '@mouseover противник' выключен\n\nЗадержка обновляется каждый раз когда условия являются успешными или сбрасывается в ином случае\n\nПравая кнопка мышки: Создать макрос",
				HEALINGENGINEAPI = "Включить API Healing Engine",
				HEALINGENGINEAPITOOLTIP = "Когда включено, все поддерживаемые опции и настройки 'Healing Engine' будут работать",
				SELECTPETS = "Включить Питомцев",
				SELECTPETSTOOLTIP = "Поддерживает: 'Healing Engine'\n\nПереключает питомцев, чтобы обрабатывать их всему API в 'Healing Engine'\n\nПравая кнопка мышки: Создать макрос",
				SELECTRESURRECTS = "Включить Воскрешения",
				SELECTRESURRECTSTOOLTIP = "Поддерживает: 'Healing Engine'\n\nПереключает мертвых игроков для выбора в @target\n\nРаботает только вне боя\n\nПравая кнопка мышки: Создать макрос",
				HELP = "Помощь",
				HELPOK = "Понял",
				ENABLED = "/tar", 
				ENABLEDTOOLTIP = "Поддерживает: 'Healing Engine'\n\nВключает\выключает '/target %s'",
				UNITID = "unitID",
				NAME = "Имя",
				ROLE = "Роль",
				ROLETOOLTIP = "Поддерживает: 'Healing Engine'\n\nОтвечает за приоритет в выборе @target, который контролируется оффсетами\nПитомцы всегда имеют роль 'Урон'",
				DAMAGER = "Урон",
				HEALER = "Лекарь",
				TANK = "Танк",
				UNKNOWN = "Неизвестно",
				USEDISPEL = "Дис\nпел",
				USEDISPELTOOLTIP = "Поддерживает: 'Healing Engine' (профиль должен иметь код для этого) + 'Rotation' (профиль должен иметь код для этого)\n\n'Healing Engine': Позволяет '/target %s' для диспела\n'Rotation': Позволяет использовать диспел на '%s'\n\nДиспел лист задан во вкладке 'Ауры'",
				USESHIELDS = "Щиты",
				USESHIELDSTOOLTIP = "Поддерживает: 'Healing Engine' (профиль должен иметь код для этого) + 'Rotation' (профиль должен иметь код для этого)\n\n'Healing Engine': Позволяет '/target %s' для щитов\n'Rotation': Позволяет использовать щиты на '%s'",
				USEHOTS = "ХоТы",
				USEHOTSTOOLTIP = "Поддерживает: 'Healing Engine' (профиль должен иметь код для этого) + 'Rotation' (профиль должен иметь код для этого)\n\n'Healing Engine': Позволяет '/target %s' для ХоТов\n'Rotation': Позволяет использовать ХоТы на '%s'",
				USEUTILS = "Ути\nлиты",
				USEUTILSTOOLTIP = "Поддерживает: 'Healing Engine' (профиль должен иметь код для этого) + 'Rotation' (профиль должен иметь код для этого)\n\n'Healing Engine': Позволяет '/target %s' для утилит\n'Rotation': Позволяет использовать утилиты на '%s'\n\nУтилиты имеется в виду действия поддерживающей категории такие как Благословенная свобода, некоторые из них задаются во вкладке 'Ауры'",
				GGLPROFILESTOOLTIP = "\n\nGGL профиля будут пропускать питомцев для этой %s ячейки в 'Healing Engine'(выбор @target)",
				LUATOOLTIP = "Поддерживает: 'Healing Engine'\n\nИспользует код, который вы напишите как последнее условие проверки прежде чем '/target %s'",
				LUATOOLTIPADDITIONAL = "\n\nЧтобы попасть в метатаблицу, которая содержит 'thisunit' данные такие как здоровье, используйте:\nlocal memberData = HealingEngine.Data.UnitIDs[thisunit]\nif memberData then Print(thisunit .. ' (' .. Unit(thisunit):Name() .. ')' .. ' has real health percent: ' .. memberData.realHP .. ' and modified: ' .. memberData.HP) end",
				AUTOHIDE = "Авто Скрытие",
				AUTOHIDETOOLTIP = "Это только для визуального эффекта!\nАвтоматически фильтрует список и показывает только доступные unitID",						
				PROFILES = "Профиля",
				PROFILESHELP = [[Настройки этой панели влияют на 'Healing Engine' + 'Rotation'
				
								 Каждый профиль записывает абсолютно все настройки текущей вкладки 
								 Тем самым вы можете менять поведения выбора цели и исцеляющей ротации прямо на лету
								 
								 Например: Вы можете создать один профиль для работы по группам 2 и 3, и второстепенный
								 для всего рейда, и в это же время менять это макросом, который также 
								 может быть создан 
								 
								 Важно понимать, что каждое сделанное изменение в этой вкладке должно быть
								 вручную пере-сохранено 
				]],
				PROFILE = "Профиль",
				PROFILEPLACEHOLDER = "-- нет профиля или имеются несохраненные изменения для предыдущего --",
				PROFILETOOLTIP = "Напишите название нового профиля в строке ввода ниже и кликните 'Сохранить'\n\nИзменения не будут сохранены в реальном времени!\nКаждый раз когда вы делаете любое изменение, чтобы сохранить их вы должны кликнуть заново 'Сохранить' для выбранного профиля",
				PROFILELOADED = "Загружен профиль: ",
				PROFILESAVED = "Сохранен профиль: ",
				PROFILEDELETED = "Удален профиль: ",
				PROFILEERRORDB = "ActionDB не инициализирован!",
				PROFILEERRORNOTAHEALER = "Вы должны быть лекарем, чтобы использовать это!",
				PROFILEERRORINVALIDNAME = "Некорректное название профиля!",
				PROFILEERROREMPTY = "Вы не выбрали профиль!",
				PROFILEWRITENAME = "Напишите название нового профиля",
				PROFILESAVE = "Сохранить",
				PROFILELOAD = "Загрузить",
				PROFILEDELETE = "Удалить",
				CREATEMACRO = "Правая кнопка мышки: Создать макрос",
				PRIORITYHEALTH = "Приоритет Здоровья",
				PRIORITYHELP = [[Настройки этой панели влияют только на 'Healing Engine'
								 Используя эти настройки, вы можете изменить приоритет 
								 выбора цели в зависимости от настроек 

								 Эти настройки изменяют виртуально здоровье, позволяя 
								 сортирующему методу расширить фильтр юнитов не только 
								 по их реальному + прогнозируемые опции здоровью 
								 
								 Сортирующий метод сортирует всех юнитов по наименьшему здоровью 

								 Множитель это число на которое здоровье будет умножено
								 
								 Оффсет это число, которое будет установлено фиксированно как 
								 процент здоровья или обработано арифметически (-/+ ХП) в 
								 зависимости от 'Режим Оффсетов'
								 
								 'Утилиты' имеется в виду поддерживающие способности такие как 
								 'Благословенная свобода'
				]],
				MULTIPLIERS = "Множители",
				MULTIPLIERINCOMINGDAMAGELIMIT = "Лимит Входящего Урона",
				MULTIPLIERINCOMINGDAMAGELIMITTOOLTIP = "Ограничивает входящий урон так как урон может быть\nнастолько огромным, что система перестанет 'слезать' с @target.\nПоставьте 1 если хотите получить немодифицированное значение\n\nПравая кнопка мышки: Создать макрос",
				MULTIPLIERTHREAT = "Угроза",
				MULTIPLIERTHREATTOOLTIP = "Обрабатывается если существует повышенная угроза (т.е. юнит танкует)\nПоставьте 1 если хотите получить немодифицированное значение\n\nПравая кнопка мышки: Создать макрос",
				MULTIPLIERPETSINCOMBAT = "Питомцы В Бою",
				MULTIPLIERPETSINCOMBATTOOLTIP = "Питомцы должны быть включенны, чтобы это работало!\nПоставьте 1 если хотите получить немодифицированное значение\n\nПравая кнопка мышки: Создать макрос",
				MULTIPLIERPETSOUTCOMBAT = "Питомцы Вне Боя",
				MULTIPLIERPETSOUTCOMBATTOOLTIP = "Питомцы должны быть включенны, чтобы это работало!\nПоставьте 1 если хотите получить немодифицированное значение\n\nПравая кнопка мышки: Создать макрос",
				OFFSETS = "Оффсеты",
				OFFSETMODE = "Режим Оффсетов",
				OFFSETMODEFIXED = "Фиксированно",
				OFFSETMODEARITHMETIC = "Арифметически",
				OFFSETMODETOOLTIP = "'Фиксированно' будет устанавливать точно такое же значение в процент здоровья\n'Арифметически' будет -/+ значение к проценту здоровья\n\nПравая кнопка мышки: Создать макрос",
				OFFSETSELFFOCUSED = "Вы - мишень (PvP)",
				OFFSETSELFFOCUSEDTOOLTIP = "Обрабатывается если вражеские игроки нацеливаются на вас в PvP режиме\n\nПравая кнопка мышки: Создать макрос",
				OFFSETSELFUNFOCUSED = "Вы - не мишень (PvP)",
				OFFSETSELFUNFOCUSEDTOOLTIP = "Обрабатывается если вражеские игроки НЕ нацеливаются на вас в PvP режиме\n\nПравая кнопка мышки: Создать макрос",
				OFFSETSELFDISPEL = "Диспел Себя",
				OFFSETSELFDISPELTOOLTIP = "GGL профиля обычно имеют PvE условие для этого\n\nДиспел список задается во вкладке 'Ауры'\n\nПравая кнопка мышки: Создать макрос",
				OFFSETHEALERS = "Лекари",
				OFFSETTANKS = "Танки",
				OFFSETDAMAGERS = "Уроны",
				OFFSETHEALERSDISPEL = "Диспел Лекари",
				OFFSETHEALERSTOOLTIP = "Обрабатывается только на других лекарях\n\nДиспел список задается во вкладке 'Ауры'\n\nПравая кнопка мышки: Создать макрос",
				OFFSETTANKSDISPEL = "Диспел Танки",
				OFFSETTANKSDISPELTOOLTIP = "Диспел список задается во вкладке 'Ауры'\n\nПравая кнопка мышки: Создать макрос",
				OFFSETDAMAGERSDISPEL = "Диспел Уроны",
				OFFSETDAMAGERSDISPELTOOLTIP = "Диспел список задается во вкладке 'Ауры'\n\nПравая кнопка мышки: Создать макрос",
				OFFSETHEALERSSHIELDS = "Щиты Лекари",
				OFFSETHEALERSSHIELDSTOOLTIP = "Включительно себя (@player)\n\nПравая кнопка мышки: Создать макрос",
				OFFSETTANKSSHIELDS = "Щиты Танки",
				OFFSETDAMAGERSSHIELDS = "Щиты Уроны",
				OFFSETHEALERSHOTS = "ХоТы Лекари",
				OFFSETHEALERSHOTSTOOLTIP = "Включительно себя (@player)\n\nПравая кнопка мышки: Создать макрос",
				OFFSETTANKSHOTS = "ХоТы Танки",
				OFFSETDAMAGERSHOTS = "ХоТы Уроны",
				OFFSETHEALERSUTILS = "Утилиты Лекари",
				OFFSETHEALERSUTILSTOOLTIP = "Включительно себя (@player)\n\nПравая кнопка мышки: Создать макрос",
				OFFSETTANKSUTILS = "Утилиты Танки",
				OFFSETDAMAGERSUTILS = "Утилиты Уроны",
				MANAMANAGEMENT = "Управление Маной",
				MANAMANAGEMENTHELP = [[Настройки этой панели влияют только на 'Rotation'
									   
									   Профиль должен иметь код для этого!
										
									   Работает если:
									   1. Внутри подземелья
									   2. В режиме PvE 
									   3. В бою 
									   4. Размер группы >= 5
									   5. Имеется босс(-ы) нацеленные участниками группы
				]],
				MANAMANAGEMENTMANABOSS = "Ваш Процент Маны <= Средний Процент Здоровья Босса(-ов)",
				MANAMANAGEMENTMANABOSSTOOLTIP = "Начинает сохранять мана фазу если условие успешно\n\nЛогика зависит от профиля, который вы используете!\n\nНе все профиля поддерживают эту настройку!\n\nПравая кнопка мышки: Создать макрос",
				MANAMANAGEMENTSTOPATHP = "Стоп Управление\nПроцент Здоровья",
				MANAMANAGEMENTSTOPATHPTOOLTIP = "Прекращает сохранять ману если главный юнит\n(@target/@mouseover) имеет процент здоровья ниже этого значения\n\nНе все профиля поддерживают эту настройку!\n\nПравая кнопка мышки: Создать макрос",
				OR = "ИЛИ",
				MANAMANAGEMENTSTOPATTTD = "Стоп Управление\nВремя До Смерти",
				MANAMANAGEMENTSTOPATTTDTOOLTIP = "Прекращает сохранять ману если главный юнит\n(@target/@mouseover) имеет время до смерти (в секундах) ниже этого значения\n\nНе все профиля поддерживают эту настройку!\n\nПравая кнопка мышки: Создать макрос",
				MANAMANAGEMENTPREDICTVARIATION = "Эффективность Сохранения Маны",
				MANAMANAGEMENTPREDICTVARIATIONTOOLTIP = "Влияет только на 'AUTO' настройки исцеляющих способностей!\n\nЭто множитель на которой будет скалькулировано чистое исцеление когда фаза сохранения маны была начата\n\nЧем выше уровень тем больше сохранения маны, но меньше APM\n\nПравая кнопка мышки: Создать макрос",
			},			
			[9] = {
				HEADBUTTON = "Клавиши",
				FRAMEWORK = "[Каждый спек] Каркас",
				HOTKEYINSTRUCTION = "Нажмите или кликните любую горячую клавишу или кнопку мышки для назначения",
				META = "Мета",
				METAENGINEROWTT = "Двойной левый клик назначает горячую клавишу\nДвойной правый клик снимает назначение",
				ACTION = "Действие",
				HOTKEY = "Горячая клавиша",
				HOTKEYASSIGN = "Создать",
				HOTKEYUNASSIGN = "Отвязать",
				ASSIGNINCOMBAT = "|cffff0000Нельзя назначить в бою!",
				PRIORITIZEPASSIVE = "Приоритет пассивной ротации",
				PRIORITIZEPASSIVETT = "Включено: Rotation, Secondary Rotation сначала выполнит пассивную ротацию, затем нативную при нажатии\nОтключено: Rotation, Secondary Rotation сначала выполнит нативную при нажатии, затем пассивную при отпускании",
				CHECKSELFCAST = "Применять к себе",
				CHECKSELFCASTTT = "Включено: Если удерживается модификатор SELFCAST, на кнопках клика целью будете вы",
				UNITTT = "Включает или отключает кнопки клика для этого юнита в пассивной ротации",
			},
		},
	},
	deDE = {			
		NOSUPPORT = "das Profil wird bisher nicht unterstützt",	
		DEBUG = "|cffff0000[Debug] Identifikationsfehler: |r",			
		ISNOTFOUND = "nicht gefunden!",			
		CREATED = "erstellt",
		YES = "Ja",
		NO = "Nein",
		TOGGLEIT = "Wechsel",
		SELECTED = "Ausgewählt",
		RESET = "Zurücksetzen",
		RESETED = "Zurückgesetzt",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro bereits vorhanden!|r",
		MACROLIMIT = "|cffff0000Makrolimit erreicht, lösche vorher eins!|r",
		MACROINCOMBAT = "|cffff0000Im Kampf kann kein Makro erstellt werden. Du musst aus dem Kampf herauskommen!|r",
		MACROSIZE = "|cffff0000Die Makrogröße darf 255 Bytes nicht überschreiten!|r",		
		GLOBALAPI = "API Global: ",
		RESIZE = "Größe ändern",
		RESIZE_TOOLTIP = "Click-und-bewege um die Größe zu ändern",
		CLOSE = "Schließen",
		APPLY = "Anwenden",
		UPGRADEDFROM = "aktualisiert von ",
		UPGRADEDTO = " zu ",		
		PROFILESESSION = {
			BUTTON = "Profilsitzung\nLinksklick öffnet das Benutzerpanel\nRechtsklick öffnet das Entwicklungsfenster",
			BNETSAVED = "Ihr Benutzerschlüssel wurde erfolgreich für eine Offline-Profilsitzung zwischengespeichert!",
			BNETMESSAGE = "Battle.net ist offline!\nBitte starte das Spiel mit aktiviertem Battle.net neu!",
			BNETMESSAGETRIAL = "!! Ihr Charakter steht auf Probe und kann keine Offline-Profilsitzung verwenden !!",
			EXPIREDMESSAGE = "Ihr Abonnement für %s ist abgelaufen!\nBitte wenden Sie sich an den Profilentwickler!",
			AUTHMESSAGE = "Vielen Dank, dass Sie das Premium-Profil verwenden\nUm Ihren Schlüssel zu autorisieren, wenden Sie sich bitte an den Profilentwickler!", 
			AUTHORIZED = "Ihr Schlüssel ist berechtigt!",
			REMAINING = "[%s] bleibt %d Sekunden",
			DISABLED = "[%s] |cffff0000Abgelaufene Sitzung!|r",
			PROFILE = "Profil:",
			TRIAL = "(testversion)",
			FULL = "(prämie)",
			UNKNOWN = "(nicht berechtigt)",
			DEVELOPMENTPANEL = "Entwicklung",
			USERPANEL = "Benutzer",
			PROJECTNAME = "Projektname",
			PROJECTNAMETT = "Ihre Entwicklung/Projekt/Routinen/Markenname",
			SECUREWORD = "Sicheres Wort",
			SECUREWORDTT = "Ihr gesichertes Wort als Master-Passwort zum Projektnamen",
			KEYTT = "'dev_key' benutzt in ProfileSession:Setup('dev_key', {...})",	
			KEYTTUSER = "Senden Sie diesen Schlüssel an den Autor des Profils!",			
		},
		SLASH = {
			LIST = "Liste der Slash-Befehle:",
			OPENCONFIGMENU = "Menü Öffnen Action",
			OPENCONFIGMENUTOASTER = "Menü Öffnen Toaster",
			HELP = "Zeigt dir die Hilfe an",
			QUEUEHOWTO = "Makro (Toggle) für Sequenzsystem (Queue), TABLENAME ist eine Bezeichnung für SpellName | ItemName (auf Englisch)",
			QUEUEEXAMPLE = "Beispiel für das Sequenzsystem",
			BLOCKHOWTO = "Makro (Umschalten) zum Deaktivieren | Aktivieren beliebiger Aktionen (Blocker), TABLENAME ist eine Bezeichnung für SpellName | ItemName (auf Englisch)",
			BLOCKEXAMPLE = "Beispiel zum Deaktivierungssystem",
			RIGHTCLICKGUIDANCE = "Die meisten Elemente können mit der linken und rechten Maustaste angeklickt werden. Durch Klicken mit der rechten Maustaste wird ein Makrowechsel erstellt, sodass Sie sich nicht um das obige Hilfehandbuch kümmern müssen",				
			INTERFACEGUIDANCE = "UI erklrüngen7:",
			INTERFACEGUIDANCEEACHSPEC = "[Jede Klasse] Spezifiziert für deine jetzige Skillung",
			INTERFACEGUIDANCEALLSPECS = "[Alle Klassen] Spezifiziert für alle Skillungen deines Characters",
			INTERFACEGUIDANCEGLOBAL = "[Global] Spezifiziert für alle auf deinem Account, Alle Charaktere, Alle Skillungen",
			ATTENTION = "|cffff0000TAKE ATTENTION|r Funktionsumfang von Action nur für Profile verfügbar, die nach dem 31.05.2019 veröffentlicht wurden. Das alte Profil würde zukünftig für dieses System aktualisiert",
			TOTOGGLEBURST = "um den Burst-Modus umzuschalten",
			TOTOGGLEMODE = "PvP / PvE umschalten",
			TOTOGGLEAOE = "um AoE umzuschalten",			
		},
		TAB = {
			RESETBUTTON = "Einstellungen zurücksetzten",
			RESETQUESTION = "Bist du dir SICHER?",
			SAVEACTIONS = "Einstellungen Speichern",
			SAVEINTERRUPT = "Speicher Unterbrechungsliste",
			SAVEDISPEL = "Speicher Auraliste",
			SAVEMOUSE = "Speicher Cursorliste",
			SAVEMSG = "Speicher Nachrichtrenliste",			
			SAVEHE = "Einstellungen Heilsystem",
			SAVEHOTKEYS = "Hotkey-Einstellungen speichern",
			LUAWINDOW = "LUA Einstellung",
			LUATOOLTIP = "Verwenden Sie 'thisunit' ohne Anführungszeichen, um auf die Prüfungseinheit zu verweisen.\nCode muss einen 'boolean' Rückgabewert (true) haben, um Bedingungen zu verarbeiten\nDieser Code hat setfenv, was bedeutet, dass Sie Action. nicht benötigen. für alles, was es hat\n\nWenn Sie bereits Standardcode entfernen möchten, müssen Sie 'return true' ohne Anführungszeichen schreiben, anstatt alle zu entfernen",
			BRACKETMATCH = "Bracket Matching",
			CLOSELUABEFOREADD = "Vor dem Adden LUA Konfiguration schließen!",
			FIXLUABEFOREADD = "LUA Fehler beheben bevor du es hinzufügst",
			RIGHTCLICKCREATEMACRO = "Rechtsklick: Erstelle macro",
			ROWCREATEMACRO = "Rechtsklick: Erstelle macro, um den aktuellen Wert für alle Zellen in dieser Zeile festzulegen\nUmschalt + Rechtsklick: Erstelle macro, um den entgegengesetzten Wert für alle 'boolean' Decken in dieser Zeile festzulegen",
			CEILCREATEMACRO = "Rechtsklick: Erstelle macro, um '%s' Wert für '%s' Ceil in dieser Zeile festzulegen\nUmschalt + Rechtsklick: Erstelle macro, um '%s' Wert für '%s' Ceil-\n-und entgegengesetzten Wert für festzulegen andere 'boolean' Decken in dieser Reihe",				
			NOTHING = "Keine Konfiguration für das Profil",
			HOW = "Bestätigen:",
			HOWTOOLTIP = "Global: Alle Accounrs, alle Charaktere und alle Skillungen",
			GLOBAL = "Global",
			ALLSPECS = "Für alle Skillungen auf diesen Charakter",
			THISSPEC = "Für die jetzige Skillung auf dem Charakter",			
			KEY = "Schlüssel:",
			CONFIGPANEL = "Konfiguration Hinzufügen",
			BLACKLIST = "Schwarze Liste",
			LANGUAGE = "[Deutsche]",
			AUTO = "Auto",
			SESSION = "Session: ",
			PREVIEWBYTES = "Vorschau: %s Bytes (255 Höchstgrenze, 210 empfohlen)",
			[1] = {
				HEADBUTTON = "General",	
				HEADTITLE = "[Jede Skillung] Primär",
				PVEPVPTOGGLE = "PvE / PvP Manual Toggle",
				PVEPVPTOGGLETOOLTIP = "Erzwingen, dass ein Profil in einen anderen Modus wechselt\n(besonders nützlich, wenn der Kriegsmodus aktiviert ist)\n\nRechtsklick: Makro erstellen", 
				PVEPVPRESETTOOLTIP = "Manuelle Umschaltung auf automatische Auswahl zurücksetzen",
				CHANGELANGUAGE = "Sprache wechseln",
				CHARACTERSECTION = "Character Fenster",
				AUTOTARGET = "Automatisches Ziel",
				AUTOTARGETTOOLTIP = "Wenn kein Ziel vorhanden, Sie sich jedoch in einem Kampf befinden, wird der nächste Feind ausgewählt.\nDer Umschalter funktioniert auf die gleiche Weise, wenn das Ziel Immunität gegen PvP hat.\n\nRechtsklick: Makro erstellen",					
				POTION = "Potion",
				HEARTOFAZEROTH = "Herz von Azeroth",
				COVENANT = "Fähigkeiten des Bundes",
				RACIAL = "Rassenfähigkeit",
				STOPCAST = "Hör auf zu gießen",
				SYSTEMSECTION = "Systemmenu",
				LOSSYSTEM = "LOS System",
				LOSSYSTEMTOOLTIP = "ACHTUNG: Diese Option führt zu einer Verzögerung von 0,3 s + der aktuellen Spinning-GCD.\nwenn überprüft wird, ob sich die Einheit in Sichtweite befindet (z. B. hinter einer Box in der Arena).\nDiese Option muss auch in den erweiterten Einstellungen aktiviert werden a lose und\nunterbricht die Bereitstellung von Aktionen für N Sekunden\n\nRechtsklick: Makro erstellen",
				STOPATBREAKABLE = "Stoppt den Schaden bei Zerbrechlichkeit",
				STOPATBREAKABLETOOLTIP = "Verhindert schädlichen Schaden bei Feinden\nWenn sie CC wie Polymorph haben\nDer automatische Angriff wird nicht abgebrochen!\n\nRechtsklick: Makro erstellen",
				BOSSTIMERS = "Bosse Timers",
				BOSSTIMERSTOOLTIP = "Erforderliche DBM oder BigWigs addons\n\nVerfolgen von Pull-Timern und bestimmten Ereignissen, z. B. eingehendem Thrash.\nDiese Funktion ist nicht für alle Profile verfügbar!\n\nKlicken mit der rechten Maustaste: Makro erstellen",
				FPS = "FPS Optimierungen",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Erhöht die Frames pro Sekunde durch Erhöhen der dynamischen Abhängigkeit.\nFrames des Aktualisierungszyklus (Aufruf) des Rotationszyklus\n\nSie können das Intervall auch nach einer einfachen Regel manuell einstellen:\nDer größere Schieberegler als mehr FPS, aber schlechtere Rotation Update\nZu hoher Wert kann zu unvorhersehbarem Verhalten führen!\n\nRechtsklick: Makro erstellen",					
				PVPSECTION = "PvP Einstellungen",
				REFOCUS = "Vorheriges gespeichertes @focus zurückgeben\n(nur Arena1-5-Einheiten)\nEs wird für Unsichtbarkeitsklassen empfohlen\n\nRechtsklick: Makro erstellen",
				RETARGET = "Vorheriges gespeichertes @Ziel zurückgeben\n(nur Arena1-5-Einheiten)\nEs wird gegen Jäger mit 'Totstellen' und unvorhergesehenen Zielabwürfen empfohlen\n\nRechtsklick: Makro erstellen",
				TRINKETS = "Schmuckstücke",
				TRINKET = "Schmuck",
				BURST = "Burst Modus",
				BURSTEVERYTHING = "Alles",
				BURSTTOOLTIP = "Alles - Auf Abklingzeit\nAuto - Boss oder Spieler\nAus - Deaktiviert\nRechtsklick: Makro erstellen\nWenn Sie einen festen Umschaltstatus festlegen möchten, verwenden Sie das Argument in: 'Everything', 'Auto', 'Off'\n/run Action.ToggleBurst('Everything', 'Auto')",					
				HEALTHSTONE = "Gesundheitsstein | Heiltrank",
				HEALTHSTONETOOLTIP = "Wann der GeSu benutzt werden soll!\n\nRechtsklick: Makro erstellen",
				COLORTITLE = "Farbwähler",
				COLORUSE = "Verwenden Sie eine benutzerdefinierte Farbe",
				COLORUSETOOLTIP = "Wechseln Sie zwischen Standard- und benutzerdefinierten Farben",
				COLORELEMENT = "Element",
				COLOROPTION = "Möglichkeit",
				COLORPICKER = "Auswahl",
				COLORPICKERTOOLTIP = "Klicken Sie hier, um das Setup-Fenster für das ausgewählte 'Element'> 'Option' zu öffnen\nRechte Maustaste zum Verschieben des geöffneten Fensters",
				FONT = "Schriftart",
				NORMAL = "Normal",
				DISABLED = "Deaktiviert",
				HEADER = "Header",
				SUBTITLE = "Untertitel",
				TOOLTIP = "Tooltip",
				BACKDROP = "Hintergrund",
				PANEL = "Panel",
				SLIDER = "Schieberegler",
				HIGHLIGHT = "Markieren",
				BUTTON = "Taste",
				BUTTONDISABLED = "Taste Deaktiviert",
				BORDER = "Rand",
				BORDERDISABLED = "Rand Deaktiviert",	
				PROGRESSBAR = "Fortschrittsanzeige",
				COLOR = "Farbe",
				BLANK = "Leer",
				SELECTTHEME = "Wählen Sie Bereites Thema",
				THEMEHOLDER = "Thema wählen",
				BLOODYBLUE = "Blutiges Blau",
				ICE = "Eis",
				AUTOATTACK = "Automatischer Angriff",
				AUTOSHOOT = "Automatisches Schießen",	
				PAUSECHECKS = "[Jede Klasse]\nRota funktioniert nicht wenn:",
				ANTIFAKEPAUSES = "AntiFake-Pausen",
				ANTIFAKEPAUSESSUBTITLE = "Während der Hotkey gedrückt gehalten wird",
				ANTIFAKEPAUSESTT = "Je nachdem, welchen Hotkey Sie auswählen,\nfunktioniert nur der ihm zugewiesene Code, wenn Sie ihn gedrückt halten",
				VEHICLE = "Im Fahrzeug",
				VEHICLETOOLTIP = "Beispiel: Katapult, Pistole abfeuern",
				DEADOFGHOSTPLAYER = "Wenn du Tot bist",
				DEADOFGHOSTTARGET = "Das Ziel Tot ist",
				DEADOFGHOSTTARGETTOOLTIP = "Ausnahme feindlicher Jäger, wenn er als Hauptziel ausgewählt ist",
				MOUNT = "Aufgemounted",
				COMBAT = "Nicht im Kampf", 
				COMBATTOOLTIP = "Wenn Sie und Ihr Ziel außerhalb des Kampfes sind. Unsichtbar ist eine Ausnahme.\n(Wenn diese Bedingung getarnt ist, wird sie übersprungen.)",
				SPELLISTARGETING = "Fähigkeit dich im Ziel hat",
				SPELLISTARGETINGTOOLTIP = "Example: Blizzard, Heldenhafter Sprung, Eiskältefalle",
				LOOTFRAME = "Beutefenster",
				EATORDRINK = "Isst oder trinkt",
				MISC = "Verschiedenes:",		
				DISABLEROTATIONDISPLAY = "Verstecke Rotationsanzeige",
				DISABLEROTATIONDISPLAYTOOLTIP = "Blendet die Gruppe aus, die sich normalerweise im unteren Bereich des Bildschirms befindet",
				DISABLEBLACKBACKGROUND = "Verstecke den schwarzen Hintergrund", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Verbirgt den schwarzen Hintergrund in der oberen linken Ecke.\nACHTUNG: Dies kann zu unvorhersehbarem Verhalten führen!",
				DISABLEPRINT = "Verstecke Text",
				DISABLEPRINTTOOLTIP = "Verbirgt Chat-Benachrichtigungen vor allem\nACHTUNG: Dadurch wird auch die [Debug] -Fehleridentifikation ausgeblendet!",
				DISABLEMINIMAP = "Verstecke Minimap Symbol",
				DISABLEMINIMAPTOOLTIP = "Blendet das Minikartensymbol dieser Benutzeroberfläche aus",
				DISABLEPORTRAITS = "Klassenporträt ausblenden",
				DISABLEROTATIONMODES = "Drehmodi ausblenden",
				DISABLESOUNDS = "Sounds deaktivieren",
				DISABLEADDONSCHECK = "Add-Ons-Prüfung deaktivieren",
				HIDEONSCREENSHOT = "Auf dem Screenshot verstecken",
				HIDEONSCREENSHOTTOOLTIP = "Während des Screenshots werden alle TellMeWhen\nund Action frames ausgeblendet und anschließend wieder angezeigt",
			},
			[2]	= {
				COVENANTCONFIGURE = "Covenant-Optionen",
				PROFILECONFIGURE = "Profiloptionen",
				FLESHCRAFTHP = "Fleischformung\nGesundheitsprozent",
				FLESHCRAFTTTD = "Fleischformung\nZeit zu sterben",
				PHIALOFSERENITYHP = "Phiole der Gelassenheit\nGesundheitsprozent",
				PHIALOFSERENITYTTD = "Phiole der Gelassenheit\nZeit zu sterben",
				PHIALOFSERENITYDISPEL = "Phiole der Gelassenheit - Dispel",
				PHIALOFSERENITYDISPELTOOLTIP = "Wenn diese Option aktiviert ist, werden die auf der Registerkarte 'Auren'\nangegebenen Effekte unabhängig von den Kontrollkästchen dieser Registerkarte entfernt\n\n",
				AND = "Und",
				OR = "Oder",
				OPERATOR = "Operator",
				TOOLTIPOPERATOR = "Der logische Operator zwischen zwei benachbarten Bedingungen\nWenn die Auswahl 'Und' ist, müssen beide erfolgreich sein\nWenn die Auswahl 'Oder' ist, muss eine von zwei Bedingungen erfolgreich sein\n\n",
				TOOLTIPTTD = "Dieser Wert ist in Sekunden angegeben und wird mit <= verglichen\nDie mathematische Berechnung basiert auf dem ankommenden Schaden bis zum vollständigen Tod\n\n",
				TOOLTIPHP = "Dieser Wert ist in Prozent angegeben, verglichen mit <=\nDer Zustand des aktuellen Charakters in Prozent\n\n",
			},
			[3] = {
				HEADBUTTON = "Actions",
				HEADTITLE = "Blocker | Warteschleife",
				ENABLED = "Aktiviert",
				NAME = "Name",
				DESC = "Notiz",
				ICON = "Icon",
				SETBLOCKER = "Set\nBlocker",
				SETBLOCKERTOOLTIP = "Dadurch wird die ausgewählte Aktion in der Rotation blockiert.\nSie wird niemals verwendet.\n\nRechtsklick: Makro erstellen",
				SETQUEUE = "Set\nWarteschleife",
				SETQUEUETOOLTIP = "Der nächste Spell wird in die Warteschleife gessetzt\n Er wird benutzt sobald es möglich ist\n\nRechtsklick: Makro erstellen\nWie auf welchem Gerät zu verwenden (UnitID ist Schlüssel), zum beispiel: { Priority = 1, UnitID = 'player' }\nSie können akzeptable Schlüssel mit Beschreibung in der Funktion finden 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Blockiert: |r",
				UNBLOCKED = "|cff00ff00Freigestellt: |r",
				KEY = "[Schlüssel: ",
				KEYTOTAL = "[Warteschlangensumme: ",
				KEYTOOLTIP = "Benutze den Schlüssel im 'Mitteilungen' Fenster", 
				MACRO = "Makro",
				MACROTOOLTIP = "Soll so kurz wie möglich sein, Makro ist auf 255 Bytes begrenzt\netwa 45 Bytes sollten für Mehrfachkette reserviert werden, Mehrzeilen werden unterstützt\n\nWenn das Makro weggelassen wird, wird die Standard-Autounit-Erstellung verwendet:\n\"/cast [@unitID]spellName\" oder \"/cast [@unitID]spellName(Rank %d)\" oder \"/use item:itemID\"\n\nMakro muss immer Aktionen hinzugefügt werden, die so etwas wie\n/cast [@player]spell:thisID\n/castsequence reset=1 spell:thisID, nil\nenthalten\n\nAkzeptiert Muster:\n\"spell:12345\" wird durch spellName ersetzt, abgeleitet von den Zahlen\n\"thisID\" wird durch self.SlotID oder self.ID ersetzt\n\"(Rank %d+)\" ersetzt Rank durch das lokalisierte Wort\nJedes Muster kann kombiniert werden, zum Beispiel \"spell:thisID(Rank 1)\"",
				ISFORBIDDENFORMACRO = "ist verboten, Makros zu ändern!",
				ISFORBIDDENFORBLOCK = "Verboten für die Blocker!",
				ISFORBIDDENFORQUEUE = "Verboten für die Warteschleife!",
				ISQUEUEDALREADY = "Schon in der Warteschleife drin!",
				QUEUED = "|cff00ff00Eingereiht: |r",
				QUEUEREMOVED = "|cffff0000Entfernt aus der Warteschleife: |r",
				QUEUEPRIORITY = " hat Priorität #",
				QUEUEBLOCKED = "|cffff0000Kann nicht eingereiht werden das der Spell geblockt ist!|r",
				SELECTIONERROR = "|cffff0000Du hast nichts ausgewählt!|r",
				AUTOHIDDEN = "[Alle Spezialisierungen] Nicht verfügbare Aktionen automatisch ausblenden",
				AUTOHIDDENTOOLTIP = "Verkleinern Sie die Bildlauftabelle und löschen Sie sie durch visuelles Ausblenden\nZum Beispiel hat die Charakterklasse nur wenige Rassen, kann aber eine verwenden. Diese Option versteckt andere Rassen\nNur zur Komfortsicht",
				CHECKSPELLLVL = "[Alle Spezialisierungen] Überprüfe den vorrausgesetzten Spell Level",
				CHECKSPELLLVLTOOLTIP = "Alle Zaubersprüche, die auf Charakterebene nicht verfügbar sind, werden blockiert.\nSie werden jedes Mal mit einer höheren Stufe aktualisiert",
				CHECKSPELLLVLERROR = "Schon installiert!",
				CHECKSPELLLVLERRORMAXLVL = "Max Level erreicht!",
				CHECKSPELLLVLMACRONAME = "Spell Level überprüfen",
				LUAAPPLIED = "LUA-Code wurde angewendet auf ",
				LUAREMOVED = "LUA-Code wurde gelöscht von ",
			},
			[4] = {
				HEADBUTTON = "Unterbrechungen",	
				HEADTITLE = "Profile Unterbrechungen",				
				ID = "ID",
				NAME = "Name",
				ICON = "Icon",
				USEKICK = "Kick",
				USECC = "CC",
				USERACIAL = "Rassisch",
				MIN = "Min: ",
				MAX = "Max: ",
				SLIDERTOOLTIP = "Legt die Unterbrechung zwischen minimaler und maximaler prozentualen Dauer des Zaubers fest\n\nDie rote Farbe der Werte bedeutet, dass diese zu nahe beieinander liegen und es zu gefährlich ist diese so zu verwenden\n\nAUS-Status bedeutet, dass diese Schieberegler für diese Liste nicht verfügbar sind",
				USEMAIN = "[Main] Nutzen",
				USEMAINTOOLTIP = "Aktiviert oder deaktiviert die Liste mit ihren zu unterbrechenden Einheiten\n\nRechtsklick: Makro erstellen",
				MAINAUTO = "[Main] Auto",
				MAINAUTOTOOLTIP = "Wenn aktiviert:\nPvE: Unterbricht jeden verfügbaren Zauber\nPvP: Wenn es ein Heiler ist und dieser in weniger als 6 Sekunden stirbt oder wenn es ein Spieler ohne gegnerische Heiler in Reichweite ist\n\nWenn deaktiviert:\nUnterbricht nur Zauber, die in der Tabelle für diese Liste hinzugefügt wurden\n\nRechtsklick: Makro erstellen",
				USEMOUSE = "[Mouse] Nutzen",
				USEMOUSETOOLTIP = "Aktiviert oder deaktiviert die Liste mit ihren zu unterbrechenden Einheiten\n\nRechtsklick: Makro erstellen",
				MOUSEAUTO = "[Mouse] Auto",
				MOUSEAUTOTOOLTIP = "Wenn aktiviert:\nPvE: Unterbricht jeden verfügbaren Zauber\nPvP: Unterbricht nur Zauber, die in der Tabelle für PvP und Heal hinzugefügt wurden, und nur Spieler\n\nWenn deaktiviert:\nUnterbricht nur Zauber, die in der Tabelle für diese Liste hinzugefügt wurden\n\nRechtsklick: Makro erstellen",
				USEHEAL = "[Heal] Nutzen",
				USEHEALTOOLTIP = "Aktiviert oder deaktiviert die Liste mit ihren zu unterbrechenden Einheiten\n\nRechtsklick: Makro erstellen",
				HEALONLYHEALERS = "[Heal] Nur Heiler",
				HEALONLYHEALERSTOOLTIP = "Wenn aktiviert:\nUnterbricht nur Heiler\n\nWenn deaktiviert:\nUnterbricht alle Feinde\n\nRechtsklick: Makro erstellen",
				USEPVP = "[PvP] Nutzen",
				USEPVPTOOLTIP = "Aktiviert oder deaktiviert die Liste mit ihren zu unterbrechenden Einheiten\n\nRechtsklick: Makro erstellen",
				PVPONLYSMART = "[PvP] Clever",
				PVPONLYSMARTTOOLTIP = "Wenn aktiviert wird durch erweiterte Logik unterbrochen:\n1) Unterbrechungskette auf deinen Heiler\n2) Dein Partner (oder du) hat seinen Burst aktiv >4 sek\n3) Wenn jemand in weniger als 8 Sekunden stirbt\n4) Du (oder @target) kann hingerichtet werden\n\nWenn deaktiviert wird ohne erweiterte Logik unterbrochen\n\nRechtsklick: Makro erstellen",
				INPUTBOXTITLE = "Spell eintragen:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): Lösch den Text und entferne den Fokus",
				INTEGERERROR = "Integer overflow attempting to store > 7 numbers", 
				SEARCH = "Suche nach Name oder SpellID",
				ADD = "Unterbrechung hinzufügen",					
				ADDERROR = "|cffff0000Du hast in 'Zauberspell' nichts angegeben, oder der Zauber wurde nicht gefunden!|r",
				ADDTOOLTIP = "Füge Fähigkeit von 'Zauberspell'\n Zu deiner Liste",
				REMOVE = "Entferne Unterbrechung",
				REMOVETOOLTIP = "Entfernt markierten Spell von deiner Liste",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "[Jede Klasse]",
				USEDISPEL = "Benutze Dispel",
				USEPURGE = "Benutze Purge",
				USEEXPELENRAGE = "Entferne Enrage",
				HEADTITLE = "[Global]",
				MODE = "Mode:",
				CATEGORY = "Kategorie:",
				POISON = "Dispel Gifte",
				DISEASE = "Dispel Krankheiten",
				CURSE = "Dispel Flüche",
				MAGIC = "Dispel Magische Effekte",
				MAGICMOVEMENT = "Dispel Magische verlangsamungen/festhalten",
				PURGEFRIENDLY = "Purge Partner",
				PURGEHIGH = "Purge Gegner (Hohe Priorität)",
				PURGELOW = "Purge Gegner (Geringe Priorität)",
				ENRAGE = "Entferne Enrage",	
				BLEEDS = "Blutungen",
				BLESSINGOFPROTECTION = "Segen des Schutzes",
				BLESSINGOFFREEDOM = "Segen der Freiheit",
				BLESSINGOFSACRIFICE = "Segen der Opferung",
				BLESSINGOFSANCTUARY = "Segen des Refugiums",	
				ROLE = "Rolle",
				ID = "ID",
				NAME = "Name",
				DURATION = "Dauer\n >",
				STACKS = "Stapel\n >=",
				ICON = "Symbol",					
				ROLETOOLTIP = "Deine Rolle, es zu benutzen",
				DURATIONTOOLTIP = "Reagiere auf Aura, wenn die Dauer der Aura länger (>) als die angegebenen Sekunden ist.\nWICHTIG: Auren ohne Dauer wie 'Göttliche Gunst'\n(Lichtpaladin) müssen 0 sein. Dies bedeutet, dass die Aura vorhanden ist!",
				STACKSTOOLTIP = "Reagiere auf Aura, wenn es mehr oder gleiche (>=) spezifizierte Stapel hat",									
				BYID = "Benutze ID\nAnstatt Name",
				BYIDTOOLTIP = "Nach ID müssen ALLE Rechtschreibungen\nüberprüft werden, die den gleichen Namen haben, aber unterschiedliche Auren annehmen, z. B. 'Instabiles Gebrechen'",					
				CANSTEALORPURGE = "Nur wenn ich\n Klauen oder Entfernen kann",					
				ONLYBEAR = "Nur wenn der Gegner\nin 'Bär Form'ist",									
				CONFIGPANEL = "'Aura hinzufügen' Menü",
				ANY = "Jeder",
				HEALER = "Heiler",
				DAMAGER = "Tank|Damager",
				ADD = "Aura hinzufügen",					
				REMOVE = "Aura entfernen",					
			},				
			[6] = {
				HEADBUTTON = "Zeiger",
				HEADTITLE = "Maus Interaktion",
				USETITLE = "[Jede Klasse] Tasten Menü:",
				USELEFT = "Benutze Links Klick",
				USELEFTTOOLTIP = "Dies erfolgt mit einem Makro / Ziel-Mouseover, bei dem es sich nicht um einen Klick handelt!\n\nRechtsklick: Makro erstellen",
				USERIGHT = "Benutze Rechts Klick",
				LUATOOLTIP = "Verwenden Sie 'thisunit' ohne Anführungszeichen, um auf die Prüfungseinheit zu verweisen.\nWenn Sie in der Kategorie 'GameToolTip' LUA verwenden, ist diese Einheit ungültig.\nCode muss eine boolesche Rückgabe (trifft zu) für die Verarbeitung von Bedingungen haben Verwenden Sie Action. für alles, was es hat\n\nWenn Sie bereits Standardcode entfernen möchten, müssen Sie 'return true' ohne Anführungszeichen schreiben, anstatt alle zu entfernen",							
				BUTTON = "Klick",
				NAME = "Name",
				LEFT = "Linkklick",
				RIGHT = "Rechtsklick",
				ISTOTEM = "im Totem",
				ISTOTEMTOOLTIP = "Wenn diese Option aktiviert ist, wird @mouseover auf 'Totem' für die Art des Totems überprüft.\nVermeiden Sie auch, dass Sie in eine Situation klicken, in der Ihr @target bereits ein Totem enthält",				
				INPUTTITLE = "Geben Sie den Namen des Objekts ein (localized!)", 
				INPUT = "Dieser Eintrag unterscheidet nicht zwischen Groß- und Kleinschreibung",
				ADD = "Hinzufügen",
				REMOVE = "Entfernen",
				-- GlobalFactory default name preset in lower case!				
				SPIRITLINKTOTEM = "totem der geistverbindung",
				HEALINGTIDETOTEM = "totem der heilungsflut",
				CAPACITORTOTEM = "totem der energiespeicherung",					
				SKYFURYTOTEM = "totem des himmelszorns",					
				ANCESTRALPROTECTIONTOTEM = "totem des schutzes der ahnen",					
				COUNTERSTRIKETOTEM = "totem des gegenschlags",
				EXPLOSIVES = "sprengstoff",
				WRATHGUARD = "zornwächter",
				FELGUARD = "teufelswache",
				INFERNAL = "höllenbestie",
				SHIVARRA = "shivarra",
				DOOMGUARD = "verdammniswache",
				FELHOUND = "teufelshund",
				["UR'ZUL"] = "ur'zul",
				-- Optional totems
				TREMORTOTEM = "totem des erdstoßes",
				GROUNDINGTOTEM = "totem der erdung",
				WINDRUSHTOTEM = "totem des windsturms",
				EARTHBINDTOTEM = "totem der erdbindung",
				-- GameToolTips
				ALLIANCEFLAG = "siegesflagge der allianz",
				HORDEFLAG = "siegesflagge der horde",
				NETHERSTORMFLAG = "nethersturmflagge",
				ORBOFPOWER = "kugel der macht",                                    
			},
			[7] = {
				HEADBUTTON = "Mitteilungen",
				HEADTITLE = "Nachrichten System",
				USETITLE = "[Jede Klasse]",
				MSG = "MSG System",
				MSGTOOLTIP = "Aktiviert: Funktioniert \nDeaktiviert: Funktioniert nicht\n\nRightClick: Create macro",
				CHANNELS = "Kanäle",
				CHANNEL = "Kanal ",	
				DISABLERETOGGLE = "Warteschlange entfernen",
				DISABLERETOGGLETOOLTIP = "Verhindert durch wiederholtes Löschen von Nachrichten aus dem Warteschlangensystem\nE.g. Mögliches Spam-Makro, ohne entfernt zu werden\n\nRechtsklick: Makro erstellen",
				MACRO = "Macro für deine Gruppe:",
				MACROTOOLTIP = "Dies sollte an den Gruppenchat gesendet werden, um die zugewiesene Aktion auf der angegebenen Taste auszulösen.\nUm die Aktion an eine bestimmte Einheit zu richten, fügen Sie sie dem Makro hinzu oder lassen Sie sie unverändert, wie sie für den Termin in der Einzel- / AoE-Rotation vorgesehen ist.\nUnterstützt : raid1-40, party1-4, player, arena1-5\nNUR EINE EINHEIT FÜR EINE NACHRICHT!\n\nIhre Gefährten können auch Makros verwenden, aber seien Sie vorsichtig, sie müssen dem treu bleiben!\nLASSEN SIE DAS NICHT MAKRO ZU UNIMINANZEN UND MENSCHEN NICHT IM THEMA!",
				KEY = "Taste",
				KEYERROR = "Du hast keine Taste ausgewählt!",
				KEYERRORNOEXIST = "Taste existiert nicht!",
				KEYTOOLTIP = "Sie müssen eine Taste zum auswählen der Aktion angeben.\nSie können die Taste auf der Registerkarte 'Aktionen' finden",
				MATCHERROR = "Der name ist bereits vorhanden, bitte nimm einen anderen!",				
				SOURCE = "Der Name der Person, die das gesagt hat",					
				WHOSAID = "Wer es sagt",
				SOURCETOOLTIP = "Dies ist optional. Du kannst dieses Feld leer lassen (empfohlen).\nWenn du es konfigurieren möchtest, muss der Name exakt mit dem in der Chatgruppe übereinstimmen",
				NAME = "Enthält eine Nachricht",
				ICON = "Symbol",
				INPUT = "Gib einen Text für das Nachrichtensystem ein",
				INPUTTITLE = "Text",
				INPUTERROR = "Du hast keinen Text angegeben!",
				INPUTTOOLTIP = "Der Text wird ausgelöst sobald einer aus deiner Gruppe im Gruppenchat schreibt (/party)\nEr ist nicht Groß geschrieben\n Enthält Muster, das heisst der Text, die von jemandem mit der Kombination der Wörter Schlachtzug, Party, Arena, Party oder Spieler gesprochen wird, passt die Aktion an den gewünschten Meta-Slot an.\nDie hier aufgeführten Muster müssen nicht festgelegt werden Wird das Muster nicht gefunden, werden Slots für Single- und AoE-Rotationen verwendet",				
			},
			[8] = { 
				HEADBUTTON = "Heilungs System",
				OPTIONSPANEL = "Optionen",
				OPTIONSPANELHELP = [[Die Einstellungen dieses Panels wirken sich aus 'Healing Engine' + 'Rotation'
									
									'Healing Engine' Diesen Namen beziehen wir uns auf @target Auswahlsystem durch
									das Makro / Ziel 'unitID'
									
									'Rotation' Diesen Namen bezeichnen wir als Heilungs- / Schadensrotation
									für die aktuelle primäre Einheit (@target oder @mouseover)
									
									Manchmal wirst du sehen 'profil muss Code dafür haben' Text was bedeutet
									Welche verwandten Funktionen können nicht funktionieren, ohne vom Profilautor hinzugefügt zu werden?
									spezieller Code dafür in Lua-snippets
									
									Jedes Element verfügt über einen Tooltip. Lesen Sie ihn daher sorgfältig durch und testen Sie ihn gegebenenfalls in 
									'Proving Grounds' Szenario, bevor Sie echte Kampf beginnen]],
				SELECTOPTIONS = "-- option auswählen --",
				PREDICTOPTIONS = "Vorhersage Optionen",
				PREDICTOPTIONSTOOLTIP = "Unterstützt: 'Healing Engine' + 'Rotation' (profil muss Code dafür haben)\n\nDiese Optionen betreffen:\n1. Gesundheitsvorhersage des Gruppenmitglieds für die @targetauswahl('Healing Engine')\n2. Berechnung der Heilungsaktion für @target/@mouseover('Rotation')\n\nKlick: Makro erstellen",
				INCOMINGHEAL = "Einkommende Heilung",
				INCOMINGDAMAGE = "Einkommender Schaden",
				THREATMENT = "Behandlung (PvE)",
				SELFHOTS = "HoTs",
				ABSORBPOSSITIVE = "Possitiv absorbieren",
				ABSORBNEGATIVE = "Negativ absorbieren",
				SELECTSTOPOPTIONS = "Ziel Stop Options",
				SELECTSTOPOPTIONSTOOLTIP = "Unterstützt: 'Healing Engine'\n\nDiese Optionen wirken sich nur auf die @target auswahl aus und verhindern insbesondere die Auswahl, wenn eine der Optionen erfolgreich ist.\n\nRechtsklick: Makro erstellen",
				SELECTSTOPOPTIONS1 = "@mouseover freundlich",
				SELECTSTOPOPTIONS2 = "@mouseover gegner",
				SELECTSTOPOPTIONS3 = "@target gegner",
				SELECTSTOPOPTIONS4 = "@target boss",
				SELECTSTOPOPTIONS5 = "@player tot",
				SELECTSTOPOPTIONS6 = "synchro-en 'Rota funktioniert nicht wenn'",
				SELECTSORTMETHOD = "Ziel Sortiermethode",
				SELECTSORTMETHODTOOLTIP = "Unterstützt: 'Healing Engine'\n\n'Gesundheit Prozent' sortiert die @target auswahl mit der geringsten Gesundheit im Prozentverhältnis\n'Wirkliche Gesundheit' sortiert die @targetauswahl mit dem geringsten Zustand im genauen Verhältnis\n\nKlick: Makro erstellen",
				SORTHP = "Gesundheit Prozent",
				SORTAHP = "Wirkliche Gesundheit",
				AFTERTARGETENEMYORBOSSDELAY = "Ziel verzögern\nNach @target gegner or boss",
				AFTERTARGETENEMYORBOSSDELAYTOOLTIP = "Unterstützt: 'Healing Engine'\n\nVerzögern (in Sekunden) bevor Auswahl nächstes Ziel nach Auswahl des Gegners oder Boss in @target\n\nNur funktioniert wenn 'Ziel Stop Options' hat '@target gegner' oder '@target boss' ausschalten\n\nVerzögerung wird jedes Mal aktualisiert, wenn die Bedingungen erfolgreich sind oder anderweitig zurückgesetzt werden\n\nRechts klick: Erstelle Makro",
				AFTERMOUSEOVERENEMYDELAY = "Ziel Verzögerung\nNach @mouseover gegner",
				AFTERMOUSEOVERENEMYDELAYTOOLTIP = "Unterstützt: 'Healing Engine'\n\nVerzögerung (in Sekunden) vor der Auswahl des nächsten Ziels nach der Auswahl eines Feindes in @mouseover\n\nFunkioniert nur wenn 'Ziel Stop Options' hat '@mouseover gegner' ausschlaten\n\nDie Verzögerung wird jedes Mal aktualisiert, wenn die Bedingungen erfolgreich sind oder anderweitig zurückgesetzt werden\n\nRechts klick: Erstelle Makro",
				HEALINGENGINEAPI = "Healing Engine API aktivieren",
				HEALINGENGINEAPITOOLTIP = "Wenn aktiviert, funktionieren alle unterstützten 'Healing Engine'-Optionen und -Einstellungen",
				SELECTPETS = "Aktiviere Begleiter",
				SELECTPETSTOOLTIP = "Unterstützt: 'Healing Engine'\n\nWechselt Begleiter, um sie von allen API in 'Healing Engine'\n\nRechts klick: Erstelle Makro",
				SELECTRESURRECTS = "Aktiviert Wiederbelebung",
				SELECTRESURRECTSTOOLTIP = "Unterstützt: 'Healing Engine'\n\nSchaltet tote Spieler für die @target auswahl um\n\nFunktiuniert nur ausserhalb des Kampfes \n\nRechts klick: Erstellt Makro",
				HELP = "Hilfe",
				HELPOK = "Gotcha",
				ENABLED = "/tar", 
				ENABLEDTOOLTIP = "Unterstützt: 'Healing Engine'\n\nWechselt an/aus '/target %s'",
				UNITID = "unitID",
				NAME = "Name",
				ROLE = "Rolle",
				ROLETOOLTIP = "Unterstützt: 'Healing Engine'\n\nVerantwortlich für die Priorität in @target auswahl, welches durch Offsets gesteuert wird\nBegleiter sind immer 'Schadens'",
				DAMAGER = "Schaden",
				HEALER = "Heiler",
				TANK = "Tank",
				UNKNOWN = "Unbekannt",
				USEDISPEL = "Dispel",
				USEDISPELTOOLTIP = "Unterstützt: 'Healing Engine' (profil muss Code dafür haben) + 'Rotation' (profil muss Code dafür haben)\n\n'Healing Engine': Erlaubt to '/target %s' for dispel\n'Rotation':Ermöglicht die Verwendung von dispel on '%s'\n\nAuf der Registerkarte 'Auras' angegebene Liste zerstreuen",
				USESHIELDS = "Shields",
				USESHIELDSTOOLTIP = "Unterstützt: 'Healing Engine' (profil muss Code dafür haben) + 'Rotation' (profil muss Code dafür haben)\n\n'Healing Engine': Erlaubt to '/target %s' for shields\n'Rotation': Ermöglicht die Verwendung von Schildern '%s'",
				USEHOTS = "HoTs",
				USEHOTSTOOLTIP = "Unterstützt: 'Healing Engine' (profil muss Code dafür haben) + 'Rotation' (profil muss Code dafür haben)\n\n'Healing Engine': Erlaubt to '/target %s' for HoTs\n'Rotation': Ermöglicht die Verwendung von HoTs '%s'",
				USEUTILS = "Utils",
				USEUTILSTOOLTIP = "Unterstützt: 'Healing Engine' (profil muss Code dafür haben) + 'Rotation' (profil muss Code dafür haben)\n\n'Healing Engine': Erlaubt '/target %s' for utils\n'Rotation':Ermöglicht die Verwendung von Utils '%s'\n\nUtils mean actions support category such as Freedom, some of them can be specified in the 'Auras' tab",
				GGLPROFILESTOOLTIP = "\n\nGGL-Profile überspringen hierfür Begleiter %s ceil in 'Healing Engine'(@target selection)",
				LUATOOLTIP = "Unterstützt: 'Healing Engine'\n\nVerwendet den Code, den Sie geschrieben haben, als letzte zuvor überprüfte Bedingung '/target %s'",
				LUATOOLTIPADDITIONAL = "\n\nUm auf Metatable zu verweisen, die enthalten 'thisunit' Daten wie Gesundheitsnutzung:\nlocal memberData = HealingEngine.Data.UnitIDs[thisunit]\nif memberData then Print(thisunit .. ' (' .. Unit(thisunit):Name() .. ')' .. ' has real health percent: ' .. memberData.realHP .. ' and modified: ' .. memberData.HP) end",
				AUTOHIDE = "Automatisch Verstecken",
				AUTOHIDETOOLTIP = "Dies ist nur ein visueller Effekt!\nFiltert die Liste automatisch und zeigt nur die verfügbare unitID an",
				CEILCREATEMACRO = "\n\nRechts klick: Erstelle Makro to set '%s' value for '%s' ceil in this row\nShift + Rechts klick: Erstelle Makro um '%s' zu setzten '%s' Ceil-\n- und entgegengesetzten Wert für andere 'boolean' Decken in dieser Reihe",
				ROWCREATEMACRO = "Rechts klick: Erstelle Makro um den aktuellen Wert für alle Decken in dieser Zeile festzulegen\nShift + Rechts klick: Erstelle Makro für alle den entgegengesetzten Wert setzen 'boolean' Decken in dieser Reihe",
				PROFILES = "Profile",
				PROFILESHELP = [[Die Einstellungen dieses Panels wirken sich aus 'Healing Engine' + 'Rotation'
								 
								 Jedes Profil zeichnet absolut alle Einstellungen der aktuellen Registerkarte auf
								 Auf diese Weise können Sie das Verhalten der Zielauswahl und der Heilungsrotation
								 im laufenden Betrieb ändern
								 
								 Beispiel: Sie können ein Profil für die Arbeit an den Gruppen 2 und 3 und das zweite Profil erstellen
								 für den gesamten Überfall, und ändern Sie es gleichzeitig mit einem Makro,
								 die auch erstellt werden kann
								 
								 Es ist wichtig zu verstehen, dass jede auf dieser Registerkarte vorgenommene Änderung manuell neu gespeichert werden muss
				]],
				PROFILE = "Profil",
				PROFILEPLACEHOLDER = "-- kein profil oder hat nicht gespeicherte Änderungen für das vorherige profil --",
				PROFILETOOLTIP = "Schreiben Sie den Namen des neuen Profils in das Bearbeitungsfeld unten und klicken Sie auf 'Save'\n\nÄnderungen werden nicht in Echtzeit gespeichert!\nJedes Mal, wenn Sie Änderungen vornehmen, um sie zu speichern, müssen Sie erneut klicken 'Save' um das Profil auszuwählen",
				PROFILELOADED = "Profil laden: ",
				PROFILESAVED = "Profil speichern: ",
				PROFILEDELETED = "Profil löschen: ",
				PROFILEERRORDB = "ActionDB wird nicht initialisiert!",
				PROFILEERRORNOTAHEALER = "Du musst Heiler sein, um es zu benutzen!!",
				PROFILEERRORINVALIDNAME = "Ungültiger Profilname!",
				PROFILEERROREMPTY = "Sie haben kein Profil ausgewählt!",
				PROFILEWRITENAME = "Schreiben Sie den Namen des neuen Profils",
				PROFILESAVE = "Speichern",
				PROFILELOAD = "Laden",
				PROFILEDELETE = "Löschen",
				CREATEMACRO = "Rechts klick: Makro erstellen",
				PRIORITYHEALTH = "Gesundheitspriorität",
				PRIORITYHELP = [[Die Einstellungen dieses Bedienfelds wirken sich nur aus 'Healing Engine'

								 Mit diesen Einstellungen können Sie die Priorität von ändern
								 Zielauswahl abhängig von den Einstellungen
								 
								 Diese Einstellungen ändern praktisch den Zustand, sodass die 
								 Sortiermethode den Filter von Einheiten nicht nur nach dem 
								 Zustand ihrer tatsächlichen + Vorhersageoptionen erweitern kann
								 
								 Die Sortiermethode sortiert alle Einheiten nach dem geringsten Gesundheitszustand
								 
								 Der Multiplikator ist die Zahl, mit der die Gesundheit multipliziert wird
								 
								 Der Versatz ist die Zahl, die als fester Prozentsatz oder festgelegt wird
								 arithmetisch verarbeitet (-/+ HP) abhängig von 'Offset Modus'
								 
								 'Utils' bedeutet offensive Zauber wie 'Blessing of Freedom'
				]],
				MULTIPLIERS = "Multiplikatoren",
				MULTIPLIERINCOMINGDAMAGELIMIT = "Eingehende Schadensgrenze",
				MULTIPLIERINCOMINGDAMAGELIMITTOOLTIP = "Begrenzt den eingehenden Echtzeitschaden, da der Schaden so groß sein kann, dass das System stoppt 'aussteigen' vom @target.\nPut 1 wenn Sie einen unveränderten Wert erhalten möchten\n\nRechts klick: Makro erstellen",
				MULTIPLIERTHREAT = "Bedrohung",
				MULTIPLIERTHREATTOOLTIP = "Wird verarbeitet, wenn eine erhöhte Bedrohung vorliegt (i.e. Gerät tankt)\nPut 1 wenn Sie einen unveränderten Wert erhalten möchten\n\nRechts klick: Makro erstellen",
				MULTIPLIERPETSINCOMBAT = "Begleiter im Kampf",
				MULTIPLIERPETSINCOMBATTOOLTIP = "Begleiter muss aktiviert sein, damit es funktioniert!\nGeben Sie 1 ein, wenn Sie einen unveränderten Wert erhalten möchten\n\nRechts klick: Makro erstellen",
				MULTIPLIERPETSOUTCOMBAT = "Begleiter ausserhalb des Kampfes",
				MULTIPLIERPETSOUTCOMBATTOOLTIP = "Begleiter muss aktiviert sein, damit es funktioniert!\nGeben Sie 1 ein wenn Sie einen unveränderten Wert erhalten möchten\n\nRechts klick: Makro erstellen",
				OFFSETS = "Offsets",
				OFFSETMODE = "Offset Modus",
				OFFSETMODEFIXED = "Fest",
				OFFSETMODEARITHMETIC = "Arithmetik",
				OFFSETMODETOOLTIP = "'Fest' setzt genau den gleichen Wert in Prozent in Gesundheit\n'Arithmetik' wird -/+ Wert auf Gesundheit Prozent\n\nRechts klick: Makro erstellen",
				OFFSETSELFFOCUSED = "Selbst\nfokussiert (PvP)",
				OFFSETSELFFOCUSEDTOOLTIP = "Wird verarbeitet, wenn feindliche Spieler im PvP-Modus auf dich zielen\n\nRechts klick: Makro erstellen",
				OFFSETSELFUNFOCUSED = "Selbst\nunkonzentriert (PvP)",
				OFFSETSELFUNFOCUSEDTOOLTIP = "Wird verarbeitet, wenn feindliche Spieler dich im PvP-Modus NICHT als Ziel wählen\n\nRechts klick: Makro erstellen",
				OFFSETSELFDISPEL = "Selbst Dispel",
				OFFSETSELFDISPELTOOLTIP = "GGL-Profile haben normalerweise eine PvE-Bedingung\n\nDispel Liste in der 'Auras' tab\n\nRechts klick: Makro erstellen",
				OFFSETHEALERS = "Heiler",
				OFFSETTANKS = "Tanks",
				OFFSETDAMAGERS = "Schaden",
				OFFSETHEALERSDISPEL = "Heiler Dispel",
				OFFSETHEALERSTOOLTIP = "Nur bei anderen Heilern verarbeitet\n\nDispel Liste in der 'Auras' tab\n\nRechts klick: Makro erstellen",
				OFFSETTANKSDISPEL = "Tanks Dispel",
				OFFSETTANKSDISPELTOOLTIP = "Dispel Liste in der 'Auras' tab\n\nRechts klick: Makro erstellen",
				OFFSETDAMAGERSDISPEL = "Schaden Dispel",
				OFFSETDAMAGERSDISPELTOOLTIP = "Liste in der 'Auras' tab\n\nRechts klick: Makro erstellen",
				OFFSETHEALERSSHIELDS = "Heiler Schilde",
				OFFSETHEALERSSHIELDSTOOLTIP = "Inklusive Selbst (@player)\n\nRechts klick: Makro erstellen",
				OFFSETTANKSSHIELDS = "Tanks Schilde",
				OFFSETDAMAGERSSHIELDS = "Schaden Schilde",
				OFFSETHEALERSHOTS = "Heiler HoTs",
				OFFSETHEALERSHOTSTOOLTIP = "Inklusive Selbst (@player)\n\nRechts klick: Makro erstellen",
				OFFSETTANKSHOTS = "Tanks HoTs",
				OFFSETDAMAGERSHOTS = "Schaden HoTs",
				OFFSETHEALERSUTILS = "Heiler Utils",
				OFFSETHEALERSUTILSTOOLTIP = "Inklusive Selbst (@player)\n\nRechts klick: Makro erstellen",
				OFFSETTANKSUTILS = "Tanks Utils",
				OFFSETDAMAGERSUTILS = "Schadens Utils",
				MANAMANAGEMENT = "Mana Manager",
				MANAMANAGEMENTHELP = [[Die Einstellungen dieses Bedienfelds wirken sich nur aus 'Rotation'
									   
									   Profil muss Code dafür haben!
									   
									  Funktioniert wenn:
									  1. Innerhalb der Instanz
									  2. Im PvE-Modus
									  3. Im Kampf
									  4. Gruppengröße> = 5
									  5. Lassen Sie einen Boss(-es) von Mitgliedern fokussieren
				]],
				MANAMANAGEMENTMANABOSS = "Ihr Mana-Prozentsatz <= Durchschnittlicher Gesundheits-Prozentsatz des Boss",
				MANAMANAGEMENTMANABOSSTOOLTIP = "Startet das Speichern der Mana-Phase, wenn die Bedingung erfolgreich ist\n\nDie Logik hängt vom verwendeten Profil ab!\n\nNicht alle Profile unterstützen diese Einstellung!\n\nRechts klick: Makro erstellen",
				MANAMANAGEMENTSTOPATHP = "Management beenden\nGesundheitsprozentsatz",
				MANAMANAGEMENTSTOPATHPTOOLTIP = "Stoppt das Speichern von Mana, wenn die Gesundheit der primären Einheit\n(@target/@mouseover) unter diesem Wert liegt\n\nNicht alle Profile unterstützen diese Einstellung!\n\nRechts klick: Makro erstellen",
				OR = "OR",
				MANAMANAGEMENTSTOPATTTD = "Stop Verwaltung\nZeit zu sterben",
				MANAMANAGEMENTSTOPATTTDTOOLTIP = "Stoppt das Speichern von Mana, wenn die primäre Einheit\n(@target/@mouseover) Zeit hat, um (in Sekunden) unter diesem Wert zu sterben\n\nNicht alle Profile unterstützen diese Einstellung!\n\nRechts klick: Makro erstellen",
				MANAMANAGEMENTPREDICTVARIATION = "Wirksamkeit der Manakonservierung",
				MANAMANAGEMENTPREDICTVARIATIONTOOLTIP = "Beeinflusst nur die Einstellungen der 'AUTO'-Heilfähigkeiten!\n\nDies ist ein Multiplikator, anhand dessen die reine Heilung berechnet wird, wenn die Manasparphase gestartet wurde\n\n Je höher die Stufe, desto mehr Manasparen, aber weniger APM\n\nRechts klick: Makro erstellen",			
			},
			[9] = {
				HEADBUTTON = "Tastenkürzel",
				FRAMEWORK = "[Jede Spezialisierung] Rahmenwerk",
				HOTKEYINSTRUCTION = "Drücken oder klicken Sie eine beliebige Hotkey- oder Maustaste, um zuzuweisen",
				META = "Meta",
				METAENGINEROWTT = "Doppel-Linksklick weist Hotkey zu\nDoppel-Rechtsklick hebt Hotkey auf",
				ACTION = "Aktion",
				HOTKEY = "Hotkey",
				HOTKEYASSIGN = "Erstellen",
				HOTKEYUNASSIGN = "Lösen",
				ASSIGNINCOMBAT = "|cffff0000Kann im Kampf nicht zuweisen!",
				PRIORITIZEPASSIVE = "Passive Rotation priorisieren",
				PRIORITIZEPASSIVETT = "Aktiviert: Rotation, Sekundärrotation führt zuerst passive Rotation aus, dann native Rotation beim Drücken\nDeaktiviert: Rotation, Sekundärrotation führt zuerst native Rotation beim Drücken aus, dann passive Rotation beim Loslassen",
				CHECKSELFCAST = "Auf sich selbst anwenden",
				CHECKSELFCASTTT = "Aktiviert: Wenn der SELFCAST-Modifikator gehalten wird, sind Sie bei Klick-Tasten das Ziel",
				UNITTT = "Aktiviert oder deaktiviert Klick-Tasten für diese Einheit in der passiven Rotation",
			},
		},
	},
	frFR = {			
		NOSUPPORT = "ce profil n'est pas encore supporté par ActionUI",	
		DEBUG = "|cffff0000[Debug] Identification d'erreur : |r",			
		ISNOTFOUND = "n'est pas trouvé!",			
		CREATED = "créé",
		YES = "Oui",
		NO = "Non",
		TOGGLEIT = "Basculer ON/OFF",
		SELECTED = "Selectionné",
		RESET = "Réinitialiser",
		RESETED = "Remis à zéro",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000La macro existe déjà !|r",
		MACROLIMIT = "|cffff0000Impossible de créer la macro, vous avez atteint la limite. Vous devez supprimer au moins une macro!|r",
		MACROINCOMBAT = "|cffff0000Impossible de créer une macro en combat. Vous devez quitter le combat!|r",	
		MACROSIZE = "|cffff0000La taille de la macro ne peut pas dépasser 255 octets!|r",		
		GLOBALAPI = "API Globale: ",
		RESIZE = "Redimensionner",
		RESIZE_TOOLTIP = "Cliquer et faire glisser pour redimensionner",
		CLOSE = "Fermer",
		APPLY = "Appliquer",
		UPGRADEDFROM = "mise à niveau depuis ",
		UPGRADEDTO = " à ",		
		PROFILESESSION = {
			BUTTON = "Séance de profil\nUn clic gauche ouvre le panneau utilisateur\nUn clic droit ouvre le panneau de développement",
			BNETSAVED = "Votre clé utilisateur a été mise en cache avec succès pour une session de profil hors ligne!",
			BNETMESSAGE = "Battle.net est hors ligne!\nVeuillez redémarrer le jeu avec Battle.net activé!",
			BNETMESSAGETRIAL = "!! Votre personnage est à l'essai et ne peut pas utiliser une session de profil hors ligne !!",
			EXPIREDMESSAGE = "Votre abonnement pour %s a expiré!\nVeuillez contacter le développeur du profil!",
			AUTHMESSAGE = "Merci d'utiliser le profil premium\nPour autoriser votre clé, veuillez contacter le développeur de profil!", 
			AUTHORIZED = "Votre clé est autorisée!",
			REMAINING = "[%s] reste %d secondes",
			DISABLED = "[%s] |cffff0000session expirée!|r",
			PROFILE = "Profil:",
			TRIAL = "(essai)",
			FULL = "(prime)",
			UNKNOWN = "(pas autorisé)",
			DEVELOPMENTPANEL = "Développement",
			USERPANEL = "Utilisateur",
			PROJECTNAME = "Nom du Projet",
			PROJECTNAMETT = "Votre développement/projet/routines/nom de marque",
			SECUREWORD = "Mot Sécurisé",
			SECUREWORDTT = "Votre mot sécurisé comme mot de passe principal pour le nom du projet",
			KEYTT = "'dev_key' utilisé dans ProfileSession:Setup('dev_key', {...})",
			KEYTTUSER = "Envoyer cette clé à l'auteur du profil!",
		},
		SLASH = {
			LIST = "Liste des commandes slash:",
			OPENCONFIGMENU = "Voir le menu de configuration Action",
			OPENCONFIGMENUTOASTER = "Voir le menu de configuration Toaster",
			HELP = "Voir le menu d'aide",
			QUEUEHOWTO = "macro (toggle) pour la séquence système (Queue), la TABLENAME est la table de référence pour les noms de sort et d'objet SpellName|ItemName (on english)",
			QUEUEEXAMPLE = "exemple d'utilisation de Queue(file d'attende)",
			BLOCKHOWTO = "macro (toggle) pour désactiver|activer n'importe quelles actions (Blocker-Blocage), la TABLENAME est la table de référence pour les noms de sort et d'objet SpellName|ItemName (on english)",
			BLOCKEXAMPLE = "exemple d'usage Blocker (Blocage)",
			RIGHTCLICKGUIDANCE = "Vous pouvez faire un clic droit ou gauche sur la plupart des éléments. Un clicque droit va créer la macro toggle donc ne vous souciez pas de laide au dessus",				
			INTERFACEGUIDANCE = "Explications de l'UI:",
			INTERFACEGUIDANCEEACHSPEC = "[Each spec] concernant votre spécialisation ACTUELLE",
			INTERFACEGUIDANCEALLSPECS = "[All specs] concernant TOUTES les spécialisations de votre personnage",
			INTERFACEGUIDANCEGLOBAL = "[Global] concernant TOUT vos compte, TOUT vos personnage et TOUTES vos spécialisations",
			ATTENTION = "|cffff0000FAIS ATTENTION|r Les fonction de ActionUI est disponible uniquement pour les profiles publié après le 31.05.2019. Les anciens profiles seront mise à jour pour ce système",	
			TOTOGGLEBURST = "pour basculer en mode rafale",
			TOTOGGLEMODE = "pour basculer PvP / PvE",
			TOTOGGLEAOE = "pour basculer en zone d'effet (AoE)",			
		},
		TAB = {
			RESETBUTTON = "Réinitiliser les paramètres",
			RESETQUESTION = "Êtes-vous sûr?",
			SAVEACTIONS = "Sauvegarder les paramètres d'Actions",
			SAVEINTERRUPT = "Sauvegarder la liste d'Interruption",
			SAVEDISPEL = "Sauvergarder la liste d'Auras",
			SAVEMOUSE = "Sauvergarder la liste d'Curseur",
			SAVEMSG = "Sauvergarder la liste d'Messages",
			SAVEHE = "Sauvegarder les paramètres d'Système de guérison",
			SAVEHOTKEYS = "Enregistrer les paramètres des raccourcis",
			LUAWINDOW = "Configuration LUA",
			LUATOOLTIP = "Pour se réferer à l'unité vérifié, utiliser 'thisunit' sans les guillemets\nLe code doit retourner un booléen (true) pour activer les conditions\nLe code contient setfenv ce qui siginfie que vous n'avez pas bessoin d'utiliser Action. pour tout ce qui l'a\n\nSi vous voulez supprimer le code déjà par défaut, vous devez écrire 'return true' sans guillemets au lieu de tout supprimer",
			BRACKETMATCH = "Repérage des paires de\nparenthèse", 
			CLOSELUABEFOREADD = "Fermer la configuration LUA avant de l'ajouter",
			FIXLUABEFOREADD = "Vous devez corriger les erreurs dans la configuration LUA avant de l'ajouter",
			RIGHTCLICKCREATEMACRO = "Clique droit: Créer la macro",
			CEILCREATEMACRO = "Clic droit: Créer la macro pour définir la valeur '%s' pour '%s' cellules dans cette ligne\nShift + Clic droit: Créer la macro pour définir la valeur '%s' pour '%s' ceil-\n-et la valeur opposée pour d'autres plafonds 'booléens' dans cette ligne",
			ROWCREATEMACRO = "Clic droit: Créer la macro pour définir la valeur de toutes les cellules dans cette ligne\nShift + Clic droit: Créer la macro pour définir une valeur opposée pour tous les plafonds 'booléens' de cette ligne",				
			NOTHING = "Le profile n'a pas de configuration pour cette onglet",
			HOW = "Appliquer:",
			HOWTOOLTIP = "Globale: Tous les comptes, tous les personnages et toutes les spécialisations",
			GLOBAL = "Globale",
			ALLSPECS = "Pour toutes les spécialisations de votre personnage",
			THISSPEC = "Pour la spécialisation actuelle de votre personnage",			
			KEY = "Touche:",
			CONFIGPANEL = "'Ajouter' Configuration",
			BLACKLIST = "Liste Noire",
			LANGUAGE = "[Français]",
			AUTO = "Auto",
			SESSION = "Session: ",
			PREVIEWBYTES = "Aperçu: %s octets (limite max 255, 210 recommandé)",
			[1] = {
				HEADBUTTON = "Générale",	
				HEADTITLE = "[Each spec] Primary",
				PVEPVPTOGGLE = "PvE / PvP basculement manuelle",
				PVEPVPTOGGLETOOLTIP = "Focer un profile a basculer dans l'autre mode (PVE/PVP)\n(Utile avec le mode de guerre activé)\n\nClique Droit : Créer la macro", 
				PVEPVPRESETTOOLTIP = "Réinitialiser le basculemant en automatique",
				CHANGELANGUAGE = "Changer la langue",
				CHARACTERSECTION = "Section du personnage",
				AUTOTARGET = "Ciblage Automatique",
				AUTOTARGETTOOLTIP = "Si vous n'avez pas de cible, mais que vous êtes en combat, il va choisir la cible la plus proche\n Le basculement fonctionne de la même manière si la cible est immunisé en PVP\n\nClique droit : Créer la macro",					
				POTION = "Potion",
				HEARTOFAZEROTH = "Coeur d'Azeroth",
				COVENANT = "Capacités de l'Alliance",
				RACIAL = "Sort Raciaux",
				STOPCAST = "Arrêtez le casting",
				SYSTEMSECTION = "Section système",
				LOSSYSTEM = "Système LOS",
				LOSSYSTEMTOOLTIP = "ATTENTION: Cette option cause un delai de 0.3s + votre gcd en cours\nSi la cible verifié n'est pas dans la ligne de vue (par exemple, derrière une boite en arène) \nVous devez aussi activer ce paramètre dans les paramètres avancés\nCette option blacklistes l'unité qui n'est pas à vue et\narrête d'effectuer des actions sur elle pendant N secondes\n\nClique droit : Créer la macro",
				STOPATBREAKABLE = "Stop Damage On BreakAble",
				STOPATBREAKABLETOOLTIP = "Arrêtera les dégâts sur les ennemis\nSi ils ont un CC tel que Polymorph\nIl n'annule pas l'attaque automatique!\n\nClique droit : Créer la macro",
				BOSSTIMERS = "Boss Timeurs",
				BOSSTIMERSTOOLTIP = "Addons DBM ou BigWigs requis\n\nSuit les timeur de pull and certain événement spécifique comme l'arrivé de trash.\nCette fonction n'est pas disponible pour tout les profiles!\n\nClique droit : Créer la macro",
				FPS = "FPS Optimisation",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO:  Augmente les images par seconde en augmentant la dépendance dynamique\nimage du cycle de rafraichisement (call) du cycle de rotation\n\nVous pouvez régler manuellement l'intervalle en suivant cette règle simple:\nPlus le slider est grand plus vous avez de FPS, mais pire sera la mise à jour de la rotation\nUne valeur trop élevée peut entraîner un comportement imprévisible!\n\nClique droit : Créer la macro",
				PVPSECTION = "Section PvP",
				REFOCUS = "Remet le @focus sauvé précédemment\n(Uniquement pour les cibles arena1-5)\nCela est recommandé pour les cible qui ont un sort d'invicibilité\n\nClique droit : Créer la macro",
				RETARGET = "Remet le @target sauvé précédemment\n(Uniquement pour les cibles arena1-5)\nCela est recommander contre les chasseurs avec 'Feindre la mort' et les perte de cible imprévu\n\nClique droit : Créer la macro",
				TRINKETS = "Bijoux",
				TRINKET = "Bijou",
				BURST = "Mode Burst",
				BURSTEVERYTHING = "Tout",
				BURSTTOOLTIP = "Tout - On cooldown\nAuto - Boss or Joueur\nOff - Désactiver\n\nClique droit : Créer la macro\nSi vous voulez régler comment bascule les cooldowns utiliser l'argumment: 'Everything', 'Auto', 'Off'\n/run Action.ToggleBurst('Everything', 'Auto')",					
				HEALTHSTONE = "Pierre de soin | Potion de soin",
				HEALTHSTONETOOLTIP = "Choisisez le pourcentage de vie (HP)\n\nClique droit : Créer la macro",
				COLORTITLE = "Pipette à couleurs",
				COLORUSE = "Utiliser une couleur personnalisée",
				COLORUSETOOLTIP = "Commutateur entre les couleurs par défaut et les couleurs personnalisées",
				COLORELEMENT = "Élément",
				COLOROPTION = "Option",
				COLORPICKER = "Sélecteur",
				COLORPICKERTOOLTIP = "Cliquez pour ouvrir la fenêtre de configuration de votre 'Élément' > 'Option' sélectionné\nBouton droit de la souris pour déplacer la fenêtre ouverte",
				FONT = "Police de caractère",
				NORMAL = "Ordinaire",
				DISABLED = "Désactivé",
				HEADER = "Entête",
				SUBTITLE = "Sous-titre",
				TOOLTIP = "Info-bulle",
				BACKDROP = "Toile de fond",
				PANEL = "Panneau",
				SLIDER = "Glissière",
				HIGHLIGHT = "Surligner",
				BUTTON = "Bouton",
				BUTTONDISABLED = "Bouton Désactivé",
				BORDER = "Frontière",
				BORDERDISABLED = "Frontière Désactivé",	
				PROGRESSBAR = "Barre de progression",
				COLOR = "Couleur",
				BLANK = "Vide",
				SELECTTHEME = "Sélectionnez le thème prêt",
				THEMEHOLDER = "choisissez le thème",
				BLOODYBLUE = "Sanglant Bleu",
				ICE = "La glace",
				AUTOATTACK = "Attaque automatique",
				AUTOSHOOT = "Tir automatique",	
				PAUSECHECKS = "[All specs]\nLa rotation ne fonction pas, si:",
				ANTIFAKEPAUSES = "AntiFake Pauses",
				ANTIFAKEPAUSESSUBTITLE = "Pendant que la touche de raccourci est maintenue enfoncée",
				ANTIFAKEPAUSESTT = "Selon le raccourci clavier que vous sélectionnez,\nseul le code qui lui est attribué fonctionnera lorsque vous le maintenez enfoncé",
				VEHICLE = "EnVéhicule",
				VEHICLETOOLTIP = "Exemple: Catapulte, ...",
				DEADOFGHOSTPLAYER = "Vous êtes mort!",
				DEADOFGHOSTTARGET = "Votre cible est morte",
				DEADOFGHOSTTARGETTOOLTIP = "Exception des chasseurs ennemi si il est en cible principale",
				MOUNT = "EnMonture",
				COMBAT = "Hors de combat", 
				COMBATTOOLTIP = "Si vous et votre cible êtes hors de combat. L'invicibilité cause une exception\n(Quand vous êtes camouflé, cette condition est ignoré)",
				SPELLISTARGETING = "Ciblage d'un sort",
				SPELLISTARGETINGTOOLTIP = "Exemple: Blizzard, Bond héroïque, Piège givrant",
				LOOTFRAME = "Fenêtre du butin",
				EATORDRINK = "Est-ce que manger ou boire",
				MISC = "Autre:",		
				DISABLEROTATIONDISPLAY = "Cacher l'affichage de la\nrotation",
				DISABLEROTATIONDISPLAYTOOLTIP = "Cacher le groupe, qui se trouve par défaut\n en bas au centre de l'écran",
				DISABLEBLACKBACKGROUND = "Cacher le fond noir", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Cacher le fond noir dans le coin en haut à gauche\nATTENTION: Cela peut entraîner un comportement imprévisible de la rotation!",
				DISABLEPRINT = "Cacher les messages chat",
				DISABLEPRINTTOOLTIP = "Cacher toutes les notification du chat\nATTENTION: Cela cache aussi les message de [Debug] Identification d'erreur!",
				DISABLEMINIMAP = "Cacher l'icone de la minimap",
				DISABLEMINIMAPTOOLTIP = "Cacher l'icone de la minmap de cette interface",
				DISABLEPORTRAITS = "Masquer le portrait de classe",
				DISABLEROTATIONMODES = "Masquer les modes de rotation",
				DISABLESOUNDS = "Désactiver les sons",
				DISABLEADDONSCHECK = "Désactiver la vérification des addons",
				HIDEONSCREENSHOT = "Masquer sur la capture d'écran",
				HIDEONSCREENSHOTTOOLTIP = "Pendant la capture d'écran, tous les cadres TellMeWhen\net Action sont masqués, puis rediffusés",
			},
			[2]	= {
				COVENANTCONFIGURE = "Options d'alliance",
				PROFILECONFIGURE = "Options de profil",
				FLESHCRAFTHP = "Chair recomposée\nPourcentage de santé",
				FLESHCRAFTTTD = "Chair recomposée\nL'heure de mourir",
				PHIALOFSERENITYHP = "Fiole de sérénité\nPourcentage de santé",
				PHIALOFSERENITYTTD = "Fiole de sérénité\nL'heure de mourir",
				PHIALOFSERENITYDISPEL = "Fiole de sérénité - Dispel",
				PHIALOFSERENITYDISPELTOOLTIP = "Si activé, il supprimera les effets spécifiés dans l'onglet 'Auras' indépendamment des cases à cocher de cet onglet\n\n",
				AND = "Et",
				OR = "Ou",
				OPERATOR = "Opérateur",
				TOOLTIPOPERATOR = "C'est un opérateur logique entre deux conditions adjacentes\nSi le choix est 'Et', les deux doivent être réussis\nSi le choix est 'Ou', l'une des deux conditions doit être réussie\n\n",
				TOOLTIPTTD = "Cette valeur est en secondes, se compare comme <=\nC'est le calcul mathématique basé sur les dégâts reçus pour terminer la mort\n\n",
				TOOLTIPHP = "Cette valeur est en pourcentage, comparée à <=\nC'est la santé actuelle du personnage en pourcentages\n\n",
			},
			[3] = {
				HEADBUTTON = "Actions",
				HEADTITLE = "Blocage | File d'attente",
				ENABLED = "Activer",
				NAME = "Nom",
				DESC = "Note",
				ICON = "Icone",
				SETBLOCKER = "Activer\nBloquer",
				SETBLOCKERTOOLTIP = "Cela bloque l'action sélectionné dans la rotation\nElle ne sera jamais utiliser\n\nClique droit: Créer la macro",
				SETQUEUE = "Activer\nQueue(file d'attente)",
				SETQUEUETOOLTIP = "Cela met l'action en queue dans la rotation\nElle sera utilisé le plus tôt possible\n\nClique droit: Créer la macro\nVous pouvez passer des conditions supplémentaires dans la macro créée pour la file d'attente\nComme sur quelle unité utiliser (UnitID est la clé), exemple: { Priority = 1, UnitID = 'player' }\nVous pouvez trouver des clés acceptables avec une description dans la fonction 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloqué: |r",
				UNBLOCKED = "|cff00ff00Débloqué: |r",
				KEY = "[Key: ",
				KEYTOTAL = "[Total de la file d'attente: ",
				KEYTOOLTIP = "Utiliser ce mot clef dans l'onglet 'Messages'",
				MACRO = "Macro",
				MACROTOOLTIP = "Doit être aussi court que possible, le macro est limité à 255 octets\nenviron 45 octets doivent être réservés pour la chaîne multiple, le multilignes est pris en charge\n\nSi le Macro est omis, la construction autounit par défaut sera utilisée :\n\"/cast [@unitID]spellName\" ou \"/cast [@unitID]spellName(Rank %d)\" ou \"/use item:itemID\"\n\nLe Macro doit toujours être ajouté aux actions contenant quelque chose comme\n/cast [@player]spell:thisID\n/castsequence reset=1 spell:thisID, nil\n\nAccepte les motifs :\n\"spell:12345\" sera remplacé par spellName obtenu à partir des numéros\n\"thisID\" sera remplacé par self.SlotID ou self.ID\n\"(Rank %d+)\" remplacera Rank par le mot localisé\nTout motif peut être combiné, par exemple \"spell:thisID(Rank 1)\"",
				ISFORBIDDENFORMACRO = "il est interdit de changer de macro!",
				ISFORBIDDENFORBLOCK = "est indertit pour la file bloquer!",
				ISFORBIDDENFORQUEUE = "est indertit pour la file d'attente!",
				ISQUEUEDALREADY = "est déjà dans la file d'attente!",
				QUEUED = "|cff00ff00Mise en attente: |r",
				QUEUEREMOVED = "|cffff0000Retirer de la file d'attente: |r",
				QUEUEPRIORITY = " est prioritaire #",
				QUEUEBLOCKED = "|cffff0000ne peut être mise en attente car le blocage est activé!|r",
				SELECTIONERROR = "|cffff0000Vous n'avez pas sélectionné de ligne!|r",
				AUTOHIDDEN = "[All specs] Masquer automatiquement les actions non disponibles",
				AUTOHIDDENTOOLTIP = "Rendre la table de défilement plus petite et claire en masquant visuellement\nPar exemple, la classe de personnage a peu de caractères raciaux, mais peut en utiliser un. Cette option masquera les autres caractères raciaux\nJuste pour le confort vue",
				CHECKSPELLLVL = "[All specs] Vérifier le niveau du sort",
				CHECKSPELLLVLTOOLTIP = "Tout les sort qui ne sont pas disponible par le personnage à cause de son level seront bloqué\nCela se met à jour à chaque fois que vous gagnez un niveau",
				CHECKSPELLLVLERROR = "Déjà initialisé!",
				CHECKSPELLLVLERRORMAXLVL = "Vous êtes au niveau MAX!",
				CHECKSPELLLVLMACRONAME = "VérifierNiveauSort",
				LUAAPPLIED = "Le code LUA a été appliqué à",
				LUAREMOVED = "Le code LUA a été retiré de",
			},
			[4] = {
				HEADBUTTON = "Interruptions",	
				HEADTITLE = "Profile pour les Interruptions",					
				ID = "ID",
				NAME = "Nom du sort",
				ICON = "Icone",
				USEKICK = "Kick",
				USECC = "CC",
				USERACIAL = "Racial",				
				MIN = "Min: ",
				MAX = "Max: ",
				SLIDERTOOLTIP = "Définit la valeur d'interruption du cast en pourcentage entre le min et le max\n\nLa couleur rouge des valeurs signifie qu'elles sont trop proches l'une de l'autre et dangereuses à utiliser\n\nOFF indique que ces réglages ne sont pas disponibles pour cette liste",
				USEMAIN = "[Principal] Utiliser",
				USEMAINTOOLTIP = "Active ou désactive la liste avec ces unités à interrompre\n\nClic droit: Créer une macro",
				MAINAUTO = "[Principal] Auto",
				MAINAUTOTOOLTIP = "Si activé:\nPvE: interrompt tous les sorts disponibles\nPvP: Si c'est un soigneur et qu'il va mourir en moins de 6 secondes ou que c'est un joueur sans soigneur ennemi à portée\n\nSi désactivé:\ninterrompt uniquement les sorts ajoutés dans la table pour cette liste\n\nClic droit: Créer une macro",
				USEMOUSE = "[Souris] Utiliser",
				USEMOUSETOOLTIP = "Active ou désactive la liste avec ces unités à interrompre\n\nClic droit: Créer une macro",
				MOUSEAUTO = "[Souris] Auto",
				MOUSEAUTOTOOLTIP = "Si activé:\nPvE: interrompt tous les sorts disponibles\nPvP: interrompt uniquement les sorts ajoutés dans la table pour les listes PvP et Soigneur et uniquement les personnages joueurs\n\nSi désactivé:\ninterrompt uniquement les sorts ajoutés dans la table pour cette liste\n\nClic droit: Créer une macro",
				USEHEAL = "[Soigneur] Utiliser",
				USEHEALTOOLTIP = "Active ou désactive la liste avec ces unités à interrompre\n\nClic droit: Créer une macro",
				HEALONLYHEALERS = "[Soigneur] Seulement les soigneurs",
				HEALONLYHEALERSTOOLTIP = "Si activé:\nInterrompt uniquement les soigneurs\n\nSi désactivé:\nInterrompt tout rôle ennemi\n\nClic droit: Créer une macro",
				USEPVP = "[PvP] Utiliser",
				USEPVPTOOLTIP = "Active ou désactive la liste avec ces unités à interrompre\n\nClic droit: Créer une macro",
				PVPONLYSMART = "[PvP] Intelligent",
				PVPONLYSMARTTOOLTIP = "Si activé, utilisera une logique avancée pour les interruptions:\n1) Une chaîne de contrôle sur votre soigneur\n2) Quelqu'un a des buffs de Dégats > 4 sec\n3) Quelqu'un va mourir en moins de 8 sec\n4) Vos PV (ou ceux de votre @cible) vont passer en phase d'exécution\n\nSi désactivé, interrompt sans logique avancée\n\nClic droit: créer une macro",
				INPUTBOXTITLE = "Ajouter un sort:",					
				INPUTBOXTOOLTIP = "ECHAP (ESC): supprimer texte and focus",
				INTEGERERROR = "Plus de 7 chiffres ont été rentré", 
				SEARCH = "Recherche par nom ou ID",
				ADD = "Ajouter une Interruption",					
				ADDERROR = "|cffff0000Vous n'avez rien préciser dans 'Ajouter un sort' ou le sort n'est pas trouvé!|r",
				ADDTOOLTIP = "Ajouter un sort depuis 'Ajouter un sort'\nDe la boite de texte à votre liste actuelle",
				REMOVE = "Retirer Interruption",
				REMOVETOOLTIP = "Retire le sort sélectionné de votre liste actuelle",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "[Each spec]",
				USEDISPEL = "Utiliser Dispel",
				USEPURGE = "Utiliser Purge",
				USEEXPELENRAGE = "Supprimer Enrage",
				HEADTITLE = "[Global]",
				MODE = "Mode:",
				CATEGORY = "Catégorie:",
				POISON = "Dispel poisons",
				DISEASE = "Dispel maladie",
				CURSE = "Dispel malédiction",
				MAGIC = "Dispel magique",
				MAGICMOVEMENT = "Dispel magique ralentissement/roots",
				PURGEFRIENDLY = "Purge amical",
				PURGEHIGH = "Purge ennemie (priorité haute)",
				PURGELOW = "Purge ennemie (priorité basse)",
				ENRAGE = "Supprimer Enrage",	
				BLEEDS = "Saignements",
				BLESSINGOFPROTECTION = "Bénédiction de protection",
				BLESSINGOFFREEDOM = "Bénédiction de liberté",
				BLESSINGOFSACRIFICE = "Bénédiction de sacrifice",
				BLESSINGOFSANCTUARY = "Bénédiction de sanctuaire",	
				ROLE = "Role",
				ID = "ID",
				NAME = "Nom",
				DURATION = "Durée\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icône",					
				ROLETOOLTIP = "Rôle pour l'utiliser",
				DURATIONTOOLTIP = "Réagit à l'aura si la durée de l'aura est plus grande (>) que le temps spécifié en secondes\nIMPORTANT: les auras sans durée comme 'Faveur divine'\n(Paladin Sacrée) doivent être à 0. Cela signifie que l'aura est présente!",
				STACKSTOOLTIP = "Réagit à l'aura si le nombre de stack est plus grand ou égale (>=) au nombre de stacks spécifié",									
				BYID = "Utiliser l'ID\nplutôt que le nom",
				BYIDTOOLTIP = "Par ID, TOUT les sorts qui ont le même\nnom seront vérifier, mais qui sont des auras différentes\ncomme 'Affliction Instable'",					
				CANSTEALORPURGE = "Seulement si vous pouvez\nvolé ou purge",					
				ONLYBEAR = "Seulement si la cible\nest en 'Forme d'ours'",									
				CONFIGPANEL = " Configuration 'Ajouter une Aura'",
				ANY = "N'importe lequel",
				HEALER = "Heal",
				DAMAGER = "Tank|Dps",
				ADD = "Ajouter Aura",					
				REMOVE = "Retirer Aura",					
			},				
			[6] = {
				HEADBUTTON = "Curseur",
				HEADTITLE = "Interaction Souris",
				USETITLE = "[Each spec] Cougiration des Bouttons:",
				USELEFT = "Utiliser Clique Gauche",
				USELEFTTOOLTIP = "Cette macro utilise le survol de la souris pas bessoin de clique!\n\nClique droit : Créer la macro",
				USERIGHT = "Utiliser Clique Droit",
				LUATOOLTIP = "Pour se réferer à l'unité vérifié, utiliser 'thisunit' sans les guillemets\nSi vous utiliser le code LUA dans la catégorie 'GameToolTip' alors 'thisunit' n'est pas valide\nLe code doit retourner un booléen (true) pour activer les conditions\nLe code contient setfenv ce qui siginfie que vous n'avez pas bessoin d'utiliser Action. pour tout ce qui l'a\n\nSi vous voulez supprimer le code déjà par défaut, vous devez écrire 'return true' sans guillemets au lieu de tout supprimer",
				BUTTON = "Cliquer",
				NAME = "Nom",
				LEFT = "Clique Gauche",
				RIGHT = "Clique Droit",
				ISTOTEM = "EstunTotem",
				ISTOTEMTOOLTIP = "Si activer cela va donner le nom si votre souris survol un totem\nAussi empêche de clic dans le cas où votre cible a déjà un totem",				
				INPUTTITLE = "Entrée le nom d'un objet (localisé!)", 
				INPUT = "Ce texte est case insensitive",
				ADD = "Ajouter",
				REMOVE = "Retirer",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "totem de lien d'esprit",
				HEALINGTIDETOTEM = "totem de marée de soins",
				CAPACITORTOTEM = "totem condensateur",					
				SKYFURYTOTEM = "totem fureur-du-ciel",					
				ANCESTRALPROTECTIONTOTEM = "totem de protection ancestrale",					
				COUNTERSTRIKETOTEM = "totem de réplique",
				EXPLOSIVES = "explosifs",
				WRATHGUARD = "garde-courroux",
				FELGUARD = "gangregarde",
				INFERNAL = "infernal",
				SHIVARRA = "shivarra",
				DOOMGUARD = "garde funeste",
				FELHOUND = "gangrechien",
				["UR'ZUL"] = "ur'zul",
				-- Optional totems
				TREMORTOTEM = "totem de séisme",
				GROUNDINGTOTEM = "totem de glèbe",
				WINDRUSHTOTEM = "totem de bouffée de vent",
				EARTHBINDTOTEM = "totem de lien terrestre",
				-- GameToolTips
				ALLIANCEFLAG = "drapeau de l’alliance",
				HORDEFLAG = "drapeau de la horde",
				NETHERSTORMFLAG = "drapeau de raz-de-néant",
				ORBOFPOWER = "orbe de puissance",
			},
			[7] = {
				HEADBUTTON = "Messages",
				HEADTITLE = "Système de Message",
				USETITLE = "[Each spec]",
				MSG = "Système MSG ",
				MSGTOOLTIP = "Coché: fonctionne\nDécoché: ne fonctionne pas\n\nClique droit : Créer la macro",
				CHANNELS = "Chaînes",
				CHANNEL = "Chaîne ",	
				DISABLERETOGGLE = "Block queue remove",
				DISABLERETOGGLETOOLTIP = "Préviens la répétition de retrait de message de la file d'attente\nE.g. Possible de spam la macro sans que le message soit retirer\n\nClique droit : Créer la macro",
				MACRO = "Macro pour votre groupe:",
				MACROTOOLTIP = "C’est ce qui doit être envoyé au groupe de discussion pour déclencher l’action assignée sur le mot clé spécifié\nPour adresser l'action à une unité spécifique, ajoutez-les à la macro ou laissez-la telle quelle pour l'affecter à la rotation Single/AoE.\nPris en charge: raid1-40, party1-4, player, arena1-5\nUNE SEULE UNITÉ POUR UN MESSAGE!\n\nVos compagnons peuvent aussi utiliser des macros, mais attention, ils doivent être fidèles à cela!\nNE PAS LAISSER LA MACRO AUX GENS N'UTILISANT PAS CE GENRE DE PROGRAMME (RISQUE DE REPORT)!",
				KEY = "Mot clef",
				KEYERROR = "Vous n'avez pas spécifié de mot clef!",
				KEYERRORNOEXIST = "Le mot clef n'existe pas!",
				KEYTOOLTIP = "Vous devez spécifier un mot clef pour lier à une action\nVous pouvez extraire un mot clef depuis l'onglet 'Actions'",
				MATCHERROR = "le nom existe déjà, utiliser un autre!",				
				SOURCE = "Le nom de la personne à qui le dire",					
				WHOSAID = "À qui le dire",
				SOURCETOOLTIP = "Ceci est optionel. Vous pouvez le liasser vide (recommandé)\nVous pouvez le configurer, le nom doit être le même quecelui du groupe de discussion",
				NAME = "Contiens un message",
				ICON = "Icône",
				INPUT = "Entrée une phrase pour le systéme de message",
				INPUTTITLE = "Phrase",
				INPUTERROR = "Vous n'avez pas rentré de phrase!",
				INPUTTOOLTIP = "La phrase sera déclenchée sur toute correspondance dans le chat de groupe (/party)\nCe n’est pas sensible à la casse\nContient des patterns, ce qui signifie que si la phrase est dite par des personne dans le chat raid, arène, groupe ou  par un joueur\ncela adapte l'action en fonction du groupe qui l'a dis\nVous n'avez pas besoin de préciser les pattern, ils sont utilisés comme un ajout à la macro\nSi le pattern n'est pas trouvé, les macros pour la rotation Single et AoE seront utilisé",				
			},
			[8] = {
				HEADBUTTON = "Système de guérison",
				OPTIONSPANEL = "Options",
				OPTIONSPANELHELP = [[Les paramètres de ce panneau affectent 'Healing Engine' + 'Rotation'
									
								   'Healing Engine' ce nom correspond au système de sélection @target par
									la macro /target 'unitID'
									
									'Rotation' ce nom correspond à la rotation de guérison/dégats elle même
									pour l'unité principale actuelle (@target ou @mouseover)
									
									Parfois, vous verrez le texte 'le profil doit avoir du code pour cela', ce qui signifie
									que les fonctionnalités ne peuvent pas fonctionner sans ajout de code lua spécial 
									par l'auteur du profil
									
									Chaque élément a une info-bulle, alors lisez attentivement et testez si nécessaire dans le
									Scénario 'Ordalie' avant de commencer un vrai combat]],
				SELECTOPTIONS = "-- choisissez les options --",
				PREDICTOPTIONS = "Options de prédiction",
				PREDICTOPTIONSTOOLTIP = "Supporté: 'Healing Engine' + 'Rotation' (le profil doit avoir du code pour cela)\n\nCes options affectent:\n1. Prédiction de santé du membre du groupe pour @target ('Healing Engine')\n2. Calcul de quelle action de soin utiliser pour @target/@mouseover ('Rotation')\n\nClic droit: Créer la macro",
				INCOMINGHEAL = "Soins entrants",
				INCOMINGDAMAGE = "Dégats entrants",
				THREATMENT = "Menace (PvE)",
				SELFHOTS = "HoTs",
				ABSORBPOSSITIVE = "Absorbe positif",
				ABSORBNEGATIVE = "Absorbe négatif",
				SELECTSTOPOPTIONS = "Options de stopcast des cibles",
				SELECTSTOPOPTIONSTOOLTIP = "Supporté: 'Healing Engine'\n\nCes options affectent seulement la @target et\nempêche spécifiquement sa sélection si l'une des options réussit\n\nClic droit: Créer la macro",
				SELECTSTOPOPTIONS1 = "@mouseover amical",
				SELECTSTOPOPTIONS2 = "@mouseover ennemi",
				SELECTSTOPOPTIONS3 = "@target ennemi",
				SELECTSTOPOPTIONS4 = "@target boss",
				SELECTSTOPOPTIONS5 = "@player mort",
				SELECTSTOPOPTIONS6 = "synchroniser 'La rotation ne fonction pas, si'",
				SELECTSORTMETHOD = "Méthode de tri des cibles",
				SELECTSORTMETHODTOOLTIP = "Supporté: 'Healing Engine'\n\n'Pourcentage de santé' classe les @target selon le plus faible ratio de Pourcentage de santé\n'Santé réelle' classe les @target leur ratio de vie réelle\n\nClic droit: Créer la macro",
				SORTHP = "Pourcentage de santé",
				SORTAHP = "Santé réelle",
				AFTERTARGETENEMYORBOSSDELAY = "Délai cible\nAprès un @target ennemi ou boss",
				AFTERTARGETENEMYORBOSSDELAYTOOLTIP = "Supporté: 'Healing Engine'\n\nDélai (en secondes) avant de sélectionner la cible suivante après avoir ciblé un ennemi ou un boss @target\n\nFonctionne uniquement si 'Options de stopcast des cibles' a '@target ennemi' ou '@target boss' désactivé\n\nLe délai est mis à jour à chaque fois que les conditions sont réussies ou est réinitialisé autrement\n\nClic droit: Créer la macro",
				AFTERMOUSEOVERENEMYDELAY = "Délai cible\nAprès un @mouseover ennemi",
				AFTERMOUSEOVERENEMYDELAYTOOLTIP = "Supporté: 'Healing Engine'\n\nDélai (en secondes) avant de sélectionner la cible suivante après avoir ciblé un ennemi avec @mouseover\n\nFonctionne uniquement si 'Options de stopcast des cibles' a '@mouseover ennemi' désactivé\n\nLe délai est mis à jour à chaque fois que les conditions sont réussies ou est réinitialisé autrement\n\nClic droit: Créer la macro",
				HEALINGENGINEAPI = "Activer l'API Healing Engine",
				HEALINGENGINEAPITOOLTIP = "Lorsque activé, toutes les options et paramètres 'Healing Engine' pris en charge fonctionneront",
				SELECTPETS = "Activer les familiers",
				SELECTPETSTOOLTIP = "Supported: 'Healing Engine'\n\nChange les animaux de compagnie pour les gérer par toutes les API 'Healing Engine'\n\nClic droit: Créer la macro", 
				SELECTRESURRECTS = "Activer les résurrections",
				SELECTRESURRECTSTOOLTIP = "Supporté: 'Healing Engine'\n\nActive la sélection de joueurs morts avec @target\n\nFonctionne seulement hors de combat\n\nClic droit: Créer la macro",
				HELP = "A l'aide",
				HELPOK = "Compris",
				ENABLED = "/tar", 
				ENABLEDTOOLTIP = "Supporté: 'Healing Engine'\n\nDésactiver/sur '/target %s'",
				UNITID = "unitID", 
				NAME = "Nom",
				ROLE = "Rôle",
				ROLETOOLTIP = "Supporté: 'Healing Engine'\n\nResponsable de la priorité dans la selection de @target, qui est contrôlé par des décalages\nLes familiers sont toujours des 'dégâts'",
				DAMAGER = "DPS",
				HEALER = "Soigneur",
				TANK = "Tank",
				UNKNOWN = "Inconnu",
				USEDISPEL = "Dissi\nper",
				USEDISPELTOOLTIP = "Supporté: 'Healing Engine' (le profil doit avoir du code pour cela) + 'Rotation' (le profil doit avoir du code pour cela)\n\n'Healing Engine': Permet de '/target %s' pour les dissipations\n'Rotation': Permet d'utiliser les dissipations sur '%s'\n\nnListe de dissipations spécifiée dans l'onglet 'Auras'",
				USESHIELDS = "Bouc\nliers",
				USESHIELDSTOOLTIP = "Supporté: 'Healing Engine' (le profil doit avoir du code pour cela) + 'Rotation' (le profil doit avoir du code pour cela)\n\n'Healing Engine': Permet de '/target %s' pour les boucliers\n'Rotation': Permet d'utiliser les boucliers sur '%s'",
				USEHOTS = "HoTs",
				USEHOTSTOOLTIP = "Supporté: 'Healing Engine' (le profil doit avoir du code pour cela) + 'Rotation' (le profil doit avoir du code pour cela)\n\n'Healing Engine': Permet de '/target %s' pour les soins sur la durée\n'Rotation': Permet d'utiliser les soins sur la durée sur '%s'",
				USEUTILS = "Utils",
				USEUTILSTOOLTIP = "Supporté: 'Healing Engine' (le profil doit avoir du code pour cela) + 'Rotation' (le profil doit avoir du code pour cela)\n\n'Healing Engine': Permet de '/target %s' pour les utilitaires\n'Rotation': Permet d'activer les utilitaires sur '%s'\n\nLes utilitaires signifient des catégories de support d'actions telles que la bénédiction de liberté, certaines d'entre elles peuvent être spécifiées dans l'onglet 'Auras'",
				GGLPROFILESTOOLTIP = "\n\nLes profils GGL ignoreront les familiers pour ce seuil %s dans 'Healing Engine'(@target selection)",
				LUATOOLTIP = "Supporté: 'Healing Engine'\n\nUtilise le code que vous avez écrit comme dernière condition vérifiée pour '/target %s'",
				LUATOOLTIPADDITIONAL = "\n\nPour se référer à metatable qui contient des données 'thisunit' telles que l'utilisation de la santé:\nlocal memberData = HealingEngine.Data.UnitIDs[thisunit]\nif memberData then Print(thisunit .. ' (' .. Unit(thisunit):Name() .. ')' .. ' has real health percent: ' .. memberData.realHP .. ' and modified: ' .. memberData.HP) end",
				AUTOHIDE = "Cacher Automatiquement",
				AUTOHIDETOOLTIP = "Ce n'est qu'un effet visuel!\nFiltre automatiquement la liste et affiche uniquement l'ID d'unité disponible",
				PROFILES = "Profils",
				PROFILESHELP = [[Les paramètres de ce panneau affectent 'Healing Engine' + 'Rotation'
								 
								 Chaque profil enregistre absolument tous les paramètres de l'onglet actuel
								 Ainsi, vous pouvez modifier le comportement de la sélection des cibles et de la rotation de guérison à la volée
								 
								 Par exemple: vous pouvez créer un profil qui fonctionne sur les groupes 2 et 3, et le second 
								 pour l'ensemble du raid, et en même temps le changer avec une macro,
								 qui peut également être créé
								 
								 Il est important de comprendre que chaque modification effectuée dans cet onglet doit être réenregistrée manuellement
				]],
				PROFILE = "Profil",
				PROFILEPLACEHOLDER = "-- aucun profil ou modifications non enregistrées pour le profil précédent --",
				PROFILETOOLTIP = "Écrivez le nom du nouveau profil dans la zone d'édition ci-dessous et cliquez sur 'Enregistrer'\n\nLes modifications ne seront pas enregistrées en temps réel!\nChaque fois que vous apportez des modifications, vous devez cliquer à nouveau sur 'Enregistrer' pour le profil sélectionné",
				PROFILELOADED = "Profil chargé: ",
				PROFILESAVED = "Profil enregistré: ",
				PROFILEDELETED = "Profil supprimé: ",
				PROFILEERRORDB = "ActionDB n'est pas initialisé!",
				PROFILEERRORNOTAHEALER = "Vous devez être soigneur pour l'utiliser!",
				PROFILEERRORINVALIDNAME = "Nom de profil invalide!",
				PROFILEERROREMPTY = "Vous n'avez pas sélectionné de profil!",
				PROFILEWRITENAME = "Ecrire le nom du nouveau profil",
				PROFILESAVE = "Sauvegarder",
				PROFILELOAD = "Charger",
				PROFILEDELETE = "Supprimer",
				CREATEMACRO = "Clic droit: Créer la macro",
				PRIORITYHEALTH = "Priorité de santé",
				PRIORITYHELP = [[Les paramètres de ce panneau affectent uniquement 'Healing Engine'

								 En utilisant ces paramètres, vous pouvez modifier la priorité de 
								 sélection de la cible en fonction des paramètres
								 
								 Ces paramètres changent virtuellement la santé, permettant  
								 la méthode de tri pour étendre le filtre des unités non seulement  
								 en fonction de leurs options de prédiction réelles + santé
								 
								 La méthode de tri gère toutes les unités qui ont le moins de santé
								 
								 Le multiplicateur est le nombre par lequel la santé sera multipliée
								 
								 Le décalage est le nombre qui sera défini comme un pourcentage fixe ou
								 traité arithmétiquement (-/+ HP) en fonction du 'mode de décalage'
								 
								 'Utils' signifient les sorts offensifs tels que 'Benediction de Liberté'
				]],
				MULTIPLIERS = "Multiplicateurs",
				MULTIPLIERINCOMINGDAMAGELIMIT = "Limite de dommages entrants",
				MULTIPLIERINCOMINGDAMAGELIMITTOOLTIP = "Limite les dommages entrants en temps réel, car les dommages peuvent être tellement\ngrand que le système cesse de 'switcher' de la @target.\nMettez 1 si vous voulez obtenir une valeur non modifiée\n\nClic droit: Créer la macro",
				MULTIPLIERTHREAT = "Menace",
				MULTIPLIERTHREATTOOLTIP = "Traité s'il existe une menace accrue (c'est-à-dire que l'unité est en train de tanker)\nMettez 1 si vous voulez obtenir une valeur non modifiée\n\nClic droit: Créer la macro",
				MULTIPLIERPETSINCOMBAT = "Familiers en combat",
				MULTIPLIERPETSINCOMBATTOOLTIP = "Les familiers doivent être activés pour fonctionner!\nMettez 1 si vous voulez obtenir une valeur non modifiée\n\nClic droit: Créer la macro",
				MULTIPLIERPETSOUTCOMBAT = "Familiers hors de combat",
				MULTIPLIERPETSOUTCOMBATTOOLTIP = "Les familiers doivent être activés pour fonctionner!\nMettez 1 si vous voulez obtenir une valeur non modifiée\n\nClic droit: Créer la macro",
				OFFSETS = "Décalages",
				OFFSETMODE = "Mode de décalage",
				OFFSETMODEFIXED = "Fixe",
				OFFSETMODEARITHMETIC = "Arithmétique",
				OFFSETMODETOOLTIP = "'Fixe' définira exactement la même valeur en pourcentage de santé\n'Arithmétique' sera - / + la valeur pour la santé en pour cent\n\nClic droit: Créer la macro",
				OFFSETSELFFOCUSED = "Focus\nsur soi même (PvP)",
				OFFSETSELFFOCUSEDTOOLTIP = "Traité si les joueurs ennemis vous ciblent en mode PvP\n\nClic droit: Créer la macro",
				OFFSETSELFUNFOCUSED = "Focus\nsur un allié (PvP)",
				OFFSETSELFUNFOCUSEDTOOLTIP = "Traité si les joueurs ennemis ne vous ciblent PAS en mode PvP\n\nClic droit: Créer la macro",
				OFFSETSELFDISPEL = "Dissipations\nsur soi même",
				OFFSETSELFDISPELTOOLTIP = "Les profils GGL ont généralement une condition PvE pour cela\n\nListe de dissipations spécifiée dans l'onglet 'Auras'\n\nClic droit: Créer la macro",
				OFFSETHEALERS = "Soigneurs",
				OFFSETTANKS = "Tanks",
				OFFSETDAMAGERS = "DPS",
				OFFSETHEALERSDISPEL = "Dissipation\ndes soigneurs",
				OFFSETHEALERSTOOLTIP = "Traité uniquement sur les autres soigneurs\n\nListe de dissipations spécifiée dans l'onglet 'Auras'\n\nClic droit: Créer la macro",
				OFFSETTANKSDISPEL = "Dissipations\ndes Tanks",
				OFFSETTANKSDISPELTOOLTIP = "Liste de dissipations spécifiée dans l'onglet 'Auras'\n\nClic droit: Créer la macro",
				OFFSETDAMAGERSDISPEL = "Dissipations\ndes DPS",
				OFFSETDAMAGERSDISPELTOOLTIP = "Liste de dissipations spécifiée dans l'onglet 'Auras'\n\nClic droit: Créer la macro",
				OFFSETHEALERSSHIELDS = "Boucliers\ndes soigneurs",
				OFFSETHEALERSSHIELDSTOOLTIP = "Inclus soi-même (@player)\n\nClic droit: Créer la macro",
				OFFSETTANKSSHIELDS = "Boucliers\ndes Tanks",
				OFFSETDAMAGERSSHIELDS = "Boucliers\ndes DPS",
				OFFSETHEALERSHOTS = "Soins sur la\ndurée des soigneurs",
				OFFSETHEALERSHOTSTOOLTIP = "Inclus soi-même (@player)\n\nClic droit: Créer la macro",
				OFFSETTANKSHOTS = "Soins sur la\ndurée des Tanks",
				OFFSETDAMAGERSHOTS = "Soins sur la\ndurée des DPS",
				OFFSETHEALERSUTILS = "Utils sur\nles Soigneurs",
				OFFSETHEALERSUTILSTOOLTIP = "Inclus soi-même (@player)\n\nClic droit: Créer la macro",
				OFFSETTANKSUTILS = "Utils sur\nles Tanks",
				OFFSETDAMAGERSUTILS = "Utils sur\nles DPS",
				MANAMANAGEMENT = "Gestion du Mana",
				MANAMANAGEMENTHELP = [[Les paramètres de ce panneau affectent uniquement 'Rotation'
									   
									   Le profil doit avoir du code pour cela! 
															   
									   Fonctionne si:
									   1. Dans une instance
									   2. En mode PvE 
									   3. En combat  
									   4. Taille du groupe >= 5
									   5. A un ou plusieurs boss ciblés par des membres alliés
				]],
				MANAMANAGEMENTMANABOSS = "Votre pourcentage de mana <= moyenne de santé du Boss",
				MANAMANAGEMENTMANABOSSTOOLTIP = "Commence à économiser du mana si la condition est réussie\n\nLa logique dépend du profil que vous utilisez!\n\nTous les profils ne prennent pas en charge ce paramètre!\n\nClic droit: Créer la macro",
				MANAMANAGEMENTSTOPATHP = "Arrêter la gestion\nPourcentage de santé",
				MANAMANAGEMENTSTOPATHPTOOLTIP = "Arrête d'économiser du mana si l'unité principale\n(@target/@mouseover) a un pourcentage de santé inférieur à cette valeur\n\nTous les profils ne prennent pas en charge ce paramètre!\n\nClic droit: Créer la macro",
				OR = "OR",
				MANAMANAGEMENTSTOPATTTD = "Arrêter la gestion\nTemps avant de mourir",
				MANAMANAGEMENTSTOPATTTDTOOLTIP = "Arrête d'économiser du mana si l'unité principale\n(@target/@mouseover) a un temps avant de mourir (en secondes) inférieur à cette valeur\n\nTous les profils ne prennent pas en charge ce paramètre!\n\nClic droit: Créer la macro",
				MANAMANAGEMENTPREDICTVARIATION = "Efficacité de la conservation du mana",
				MANAMANAGEMENTPREDICTVARIATIONTOOLTIP = "N'affecte que les paramètres des capacités de guérison 'AUTO'!\n\nC'est un multiplicateur sur lequel la guérison pure sera calculée lorsque la phase de sauvegarde de mana a été lancée\n\nPlus le niveau est élevé, plus de sauvegarde de mana, mais moins d'APM\n\nClic droit: Créer la macro",
			},
			[9] = {
				HEADBUTTON = "Raccourcis",
				FRAMEWORK = "[Chaque spé] Cadriciel",
				HOTKEYINSTRUCTION = "Appuyez ou cliquez sur n’importe quelle touche de raccourci ou bouton de souris pour assigner",
				META = "Meta",
				METAENGINEROWTT = "Double clic gauche pour assigner le raccourci\nDouble clic droit pour désassigner le raccourci",
				ACTION = "Action",
				HOTKEY = "Raccourci",
				HOTKEYASSIGN = "Créer",
				HOTKEYUNASSIGN = "Dissocier",
				ASSIGNINCOMBAT = "|cffff0000Impossible d’assigner en combat !",
				PRIORITIZEPASSIVE = "Prioriser rotation passive",
				PRIORITIZEPASSIVETT = "Activé : Rotation, Rotation secondaire effectueront d’abord la rotation passive, puis la rotation native lors du clic enfoncé\nDésactivé : Rotation, Rotation secondaire effectueront d’abord la rotation native lors du clic enfoncé, puis la rotation passive lors du relâchement",
				CHECKSELFCAST = "Appliquer à soi-même",
				CHECKSELFCASTTT = "Activé : si le modificateur SELFCAST est maintenu, vous serez la cible des boutons de clic",
				UNITTT = "Active ou désactive les boutons de clic pour cette unité en rotation passive",
			},
		},
	},
	itIT = {			
		NOSUPPORT = "questo profilo non supporta ancora ActionUI",	
		DEBUG = "|cffff0000[Debug] Identificativo di Errore: |r",			
		ISNOTFOUND = "non trovato!",			
		CREATED = "creato",
		YES = "Si",
		NO = "No",
		TOGGLEIT = "Switch it",
		SELECTED = "Selezionato",
		RESET = "Riavvia",
		RESETED = "Riavviato",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000La Macro esiste gia!|r",
		MACROLIMIT = "|cffff0000Non posso creare la macro, hai raggiunto il limite. Devi cancellare almeno una macro!|r",
		MACROINCOMBAT = "|cffff0000Impossibile creare macro in combattimento. Devi lasciare il combattimento!|r",	
		MACROSIZE = "|cffff0000La dimensione della macro non può superare i 255 byte!|r",
		GLOBALAPI = "API Globale: ",
		RESIZE = "Ridimensiona",
		RESIZE_TOOLTIP = "Seleziona e tracina per ridimensionare",
		CLOSE = "Vicino",
		APPLY = "Applicare",
		UPGRADEDFROM = "aggiornato da ",
		UPGRADEDTO = " per ",		
		PROFILESESSION = {
			BUTTON = "Sessione di profilo\nIl clic sinistro apre il pannello utente\nFare clic con il pulsante destro del mouse apre il pannello di sviluppo",
			BNETSAVED = "La tua chiave utente è stata memorizzata correttamente nella cache per una sessione del profilo offline!",
			BNETMESSAGE = "Battle.net è offline!\nRiavvia il gioco con Battle.net abilitato!",
			BNETMESSAGETRIAL = "!! Il tuo personaggio è in prova e non può utilizzare una sessione del profilo offline !!",
			EXPIREDMESSAGE = "Il tuo abbonamento a %s è scaduto!\nSi prega di contattare lo sviluppatore del profilo!",
			AUTHMESSAGE = "Grazie per aver utilizzato il profilo premium\nPer autorizzare la tua chiave contatta lo sviluppatore del profilo!", 
			AUTHORIZED = "La tua chiave è autorizzata!",
			REMAINING = "[%s] rimane %d sec",
			DISABLED = "[%s] |cffff0000sessione scaduta!|r",
			PROFILE = "Profilo:",
			TRIAL = "(prova)",
			FULL = "(premio)",
			UNKNOWN = "(non autorizzato)",
			DEVELOPMENTPANEL = "Sviluppo",
			USERPANEL = "Utente",
			PROJECTNAME = "Nome del Progetto",
			PROJECTNAMETT = "Il tuo sviluppo/progetto/routine/marchio",
			SECUREWORD = "Parola Sicura",
			SECUREWORDTT = "La tua parola protetta come password principale per il nome del progetto",
			KEYTT = "'dev_key' usato in ProfileSession:Setup('dev_key', {...})",
			KEYTTUSER = "Invia questa chiave all'autore del profilo!",
		},
		SLASH = {
			LIST = "Lista comandi:",
			OPENCONFIGMENU = "mostra il menu di configurazione Action",
			OPENCONFIGMENUTOASTER = "mostra il menu di configurazione Toaster",
			HELP = "mostra info di aiuto",
			QUEUEHOWTO = "macro (toggle) per il sistema di coda (Coda), la TABLENAME é etichetta di riferimento per incantesimo|oggetto (in inglese)",
			QUEUEEXAMPLE = "esempio per uso della Coda",
			BLOCKHOWTO = "macro (toggle) per disabilitare|abilitare le azioni (Blocco), é etichetta di riferimento per incantesimo|oggetto (in inglese)",
			BLOCKEXAMPLE = "esempio per uso del Blocker",
			RIGHTCLICKGUIDANCE = "La maggior parte degli elementi sono pulsanti cliccabili sinistro e destro del mouse. Il pulsante destro del mouse creerà una macro, in modo che tu non possa tener conto del suggerimento di cui sopra",				
			INTERFACEGUIDANCE = "spiegazioni UI:",
			INTERFACEGUIDANCEEACHSPEC = "[Spec Corrente] si riferisce alla CORRENTE specializzazione",
			INTERFACEGUIDANCEALLSPECS = "[Spec Tutte] si applica a TUTTE le specializzazioni di un personaggio.",
			INTERFACEGUIDANCEGLOBAL = "[Spec Globale] si applica GLOBALMENTE al tuo account TUTTI i personaggi TUTTE le specializzazioni.",
			ATTENTION = "|cffff0000FAI ATTENZIONE|r La funzionalità Action è disponibile solo per i profili rilasciati dopo il 31.05.2019. I profili precedenti verranno aggiornati in futuro.",			
			TOTOGGLEBURST = "per attivare / disattivare la modalità Burst",
			TOTOGGLEMODE = "per attivare / disattivare PvP / PvE",
			TOTOGGLEAOE = "per attivare / disattivare AoE",
		},
		TAB = {
			RESETBUTTON = "Riavvia settaggi",
			RESETQUESTION = "Sei sicuro?",
			SAVEACTIONS = "Salva settaggi Actions",
			SAVEINTERRUPT = "Salva liste Interruzioni",
			SAVEDISPEL = "Salva liste Auree",
			SAVEMOUSE = "Salva liste cursori",
			SAVEMSG = "Salva liste MSG",
			SAVEHE = "Salva liste Sistema di guarigione",
			SAVEHOTKEYS = "Salva impostazioni tasti rapidi",
			LUAWINDOW = "Configura LUA",
			LUATOOLTIP = "Per fare riferimento all unità da controllare, usa il nome senza virgolette \nIl codice deve avere un valore(true) per funzionare \nIl codice ha setfenv, significa che non devi usare Action. \n\nSe vuoi rimpiazzare il codice predefinito, devi rimpiazzare con un 'return true' senza virgolette, \n invece di cancellarlo",
			BRACKETMATCH = "Verifica parentesi",
			CLOSELUABEFOREADD = "Chiudi la configurazione LUA prima di aggiungere",
			FIXLUABEFOREADD = "Devi correggere gli errori nella configurazione LUA prima di aggiungere",
			RIGHTCLICKCREATEMACRO = "Pulsanmte destro: Crea macro",
			ROWCREATEMACRO = "Pulsanmte destro: Crea macro per impostare il valore corrente per tutti i ceils in questa riga\nShift + Pulsanmte destro: Crea macro per impostare un valore opposto per tutti i ceils 'boolean' in questa riga",
			CEILCREATEMACRO = "Pulsanmte destro: Crea macro per impostare il valore '%s' per il ceil '%s' in questa riga\nShift + Pulsanmte destro: Crea macro per impostare il valore '%s' per '%s' ceil-\n-e il valore opposto per altri ceils 'boolean' in questa riga",	
			NOTHING = "Il profilo non ha una configuration per questo tab",
			HOW = "Applica:",
			HOWTOOLTIP = "Global: Tutto account, tutti i personaggi e tutte le specializzazioni",
			GLOBAL = "Globale",
			ALLSPECS = "A tutte le specializzazioni di un personaggio",
			THISSPEC = "Alla specializzazione corrente del personaggio",			
			KEY = "Chiave:",
			CONFIGPANEL = "'Aggiungi' Configurazione",
			BLACKLIST = "Lista Nera",
			LANGUAGE = "[Italiano]",
			AUTO = "Auto",
			SESSION = "Sessione: ",
			PREVIEWBYTES = "Anteprima: %s byte (limite massimo 255, 210 consigliati)",
			[1] = {
				HEADBUTTON = "Generale",	
				HEADTITLE = "[Spec Tutte] Primaria",
				PVEPVPTOGGLE = "PvE / PvP interruttore manuale",
				PVEPVPTOGGLETOOLTIP = "Forza il cambio di un profilo\n(utile quando Modalitá guerra é attiva)\n\nTastodestro: Crea macro", 
				PVEPVPRESETTOOLTIP = "Resetta interruttore manuale - auto",
				CHANGELANGUAGE = "Cambia Lingua",
				CHARACTERSECTION = "Seleziona personaggio",
				AUTOTARGET = "Bersaglio automatico",
				AUTOTARGETTOOLTIP = "Se il bersaglio non é selezionato e sei in combattimento, ritorna il nemico piú vicino\nInterruttore funziona nella stesso modo se il bersaglio selezionato é immune|non in PvP\n\nTastodestro: Crea macro",					
				POTION = "Pozione",
				HEARTOFAZEROTH = "Cuore di Azeroth",
				COVENANT = "Abilità dell'alleanza",
				RACIAL = "Abilitá Raziale",
				STOPCAST = "Smetti di lanciare",
				SYSTEMSECTION = "Area systema",
				LOSSYSTEM = "Sistema di linea di vista [LOS]",
				LOSSYSTEMTOOLTIP = "ATTENZIONE: Questa opzione causa un ritardo di 0.3s + piu tempo del sistema di recupero globale [srg]\nse il bersaglio é in los (per esempio dietro una cassa in arena)\nDevi anche abilitare lo stesso settaggio in Settaggi Avanzati\nQuesta opzione mette in blacklists bersagli fuori los e\nferma le azioni verso il bersaglio per N secondio\n\nTastodestro: Crea macro",
				STOPATBREAKABLE = "Stop Damage On BreakAble",
				STOPATBREAKABLETOOLTIP = "Fermerà i danni dannosi ai nemici\nSe hanno CC come Polymorph\nNon annulla l'attacco automatico!\n\nTastodestro: Crea macro",
				BOSSTIMERS = "Boss Timers",
				BOSSTIMERSTOOLTIP = "Addon DBM o BigWigs richiesti\n\nTiene traccia dei timer di avvio combattimento e alcuni eventi specific tipo patrol in arrivo.\nQuesta funzionalitá é disponibile per tutti i profili!\n\nTastodestro: Crea macro",
				FPS = "Ottimizzazione FPS",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Aumenta i frames per second incrementando la dipendenza dinamica\ndei frames del ciclo di refresh (call) della rotazione\n\nPuoi settare manualmente l'intervallo seguendo questa semplice regola:\nPiú é altop lo slider piú é l'FPS, ma peggiore sará l'update della rotazione\nValori troppo alti possono portare a risultati imprevedibili!\n\nTastodestro: Crea macro",					
				PVPSECTION = "Sezione PvP",
				REFOCUS = "Identifica il focus precedente @focus\n(solo arena unitá 1-5)\nraccomandato contro le classi con capacitá di invisibilitá\n\nTastodestro: Crea macro",
				RETARGET = "Identifica il bersaglio precedente @target\n(solo arena unitá 1-5)\nraccomandato contro cacciatori con capacitá 'Morte Fasulla' e altre abilitá che deselezionano il bersaglio\n\nTastodestro: Crea macro",
				TRINKETS = "Ninnolo",
				TRINKET = "Ninnoli",
				BURST = "Modalitá raffica",
				BURSTEVERYTHING = "Utilizza Tutto",
				BURSTTOOLTIP = "Utilizza Tutto - appena esce dal coll down\nAuto - Boss o Giocatore\nOff - Disabilitata\n\nTastodestro: Crea macro\nSe desidere utilizzare specifici attributi utilizza in: 'Everything', 'Auto', 'Off'\n/run Action.ToggleBurst('Everything', 'Auto')",					
				HEALTHSTONE = "Healthstone | Pozione curativa",
				HEALTHSTONETOOLTIP = "Seta la percentuale di vita (HP)\n\nTastodestro: Crea macro",
				COLORTITLE = "Color Picker",
				COLORUSE = "Usa colore personalizzato",
				COLORUSETOOLTIP = "Commutazione tra colori predefiniti e personalizzati",
				COLORELEMENT = "Elemento",
				COLOROPTION = "Opzione",
				COLORPICKER = "Picker",
				COLORPICKERTOOLTIP = "Fare clic per aprire la finestra di configurazione per 'Elemento' selezionato > 'Opzione'\nTasto destro del mouse per spostare la finestra aperta",
				FONT = "Font",
				NORMAL = "Normale",
				DISABLED = "Disabilitato",
				HEADER = "Intestazione",
				SUBTITLE = "Sottotitolo",
				TOOLTIP = "Tooltip",
				BACKDROP = "Fondale",
				PANEL = "Pannello",
				SLIDER = "Slider",
				HIGHLIGHT = "Evidenziare",
				BUTTON = "Pulsante",
				BUTTONDISABLED = "Pulsante Disabilitato",
				BORDER = "Confine",
				BORDERDISABLED = "Confine Disabilitato",	
				PROGRESSBAR = "Barra di avanzamento",
				COLOR = "Colore",
				BLANK = "Vuoto",
				SELECTTHEME = "Seleziona Tema pronto",
				THEMEHOLDER = "scegli il tema",
				BLOODYBLUE = "Sanguinoso Blu",
				ICE = "Ghiaccio",
				AUTOATTACK = "Attacco automatico",
				AUTOSHOOT = "Scatto automatico",	
				PAUSECHECKS = "[All specs]\nLa rotazione non funziona, se:",
				ANTIFAKEPAUSES = "AntiFake si ferma",
				ANTIFAKEPAUSESSUBTITLE = "Mentre il tasto di scelta rapida è tenuto premuto",
				ANTIFAKEPAUSESTT = "A seconda del tasto di scelta rapida selezionato,\nquando lo si tiene premuto funzionerà solo il codice ad esso assegnato",
				VEHICLE = "NelVeicolo",
				VEHICLETOOLTIP = "Esempio: Catapulta, Cannone",
				DEADOFGHOSTPLAYER = "Sei Morto",
				DEADOFGHOSTTARGET = "Il bersaglio é morto",
				DEADOFGHOSTTARGETTOOLTIP = "Eccezione il cacciatore bersaglio se é selezionato come bersaglio primario",
				MOUNT = "ACavallo",
				COMBAT = "Non in combattimento", 
				COMBATTOOLTIP = "Se tu e il tuo bersaglio siete non in combattimento. l' invisibile non viene considerato\n(quando invisibile questa condizione viene non valutata|saltata)",
				SPELLISTARGETING = "IncantesimoHaBersaglio",
				SPELLISTARGETINGTOOLTIP = "Esembio: Tormento, Balzo eroico, Trappola congelante",
				LOOTFRAME = "Bottino",
				EATORDRINK = "Sta mangiando o bevendo",
				MISC = "Varie:",		
				DISABLEROTATIONDISPLAY = "Nascondi|Mostra la rotazione",
				DISABLEROTATIONDISPLAYTOOLTIP = "Nasconde il gruppo, che generalmente siu trova al\ncentro in basso dello schermo",
				DISABLEBLACKBACKGROUND = "Nascondi lo sfondo nero", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Nasconde lo sfondo nero nell'angolo in alto a sinistra dello schermo\nATTENZIONE: puo causare comportamenti anomali della applicazione!",
				DISABLEPRINT = "Nascondi|Stampa",
				DISABLEPRINTTOOLTIP = "Nasconde notifice di chat per tutto\nATTENZIONE: Questa opzione nasconde anche le notifiche [Debug] Identificazione errori!",
				DISABLEMINIMAP = "Nasconde icona nella minimap",
				DISABLEMINIMAPTOOLTIP = "Nasconde l'icona di questa UI dalla minimappa",
				DISABLEPORTRAITS = "Nascondi ritratto di classe",
				DISABLEROTATIONMODES = "Nascondi le modalità di rotazione",
				DISABLESOUNDS = "Disabilita i suoni",
				DISABLEADDONSCHECK = "Disattivare i componenti aggiuntivi",
				HIDEONSCREENSHOT = "Nascondi sullo screenshot",
				HIDEONSCREENSHOTTOOLTIP = "Durante lo screenshot nasconde tutti i frame TellMeWhen\ne Action, quindi li mostra di nuovo",
			},
			[2]	= {
				COVENANTCONFIGURE = "Opzioni del patto",
				PROFILECONFIGURE = "Opzioni profilo",
				FLESHCRAFTHP = "Forgiatura della Carne\nPercentuale di salute",
				FLESHCRAFTTTD = "Forgiatura della Carne\nTempo di morire",
				PHIALOFSERENITYHP = "Fiala della Serenità\nPercentuale di salute",
				PHIALOFSERENITYTTD = "Fiala della Serenità\nTempo di morire",
				PHIALOFSERENITYDISPEL = "Fiala della Serenità - Dissoluzione",
				PHIALOFSERENITYDISPELTOOLTIP = "Se abilitato, rimuoverà gli effetti specificati nella scheda 'Aure' indipendentemente dalle caselle di controllo di quella scheda\n\n",
				AND = "E",
				OR = "O",
				OPERATOR = "Operatore",
				TOOLTIPOPERATOR = "È un operatore logico tra due condizioni adiacenti\nSe la scelta è 'E', entrambe devono avere successo\nSe la scelta è 'O', una delle due condizioni deve avere successo\n\n",
				TOOLTIPTTD = "Questo valore è espresso in secondi, confronta come <=\nÈ un calcolo matematico basato sul danno in arrivo per la morte completa\n\n",
				TOOLTIPHP = "Questo valore è in percentuale, rispetto a <=\nÈ la salute attuale del personaggio in percentuale\n\n",
			},
			[3] = {
				HEADBUTTON = "Azioni",
				HEADTITLE = "Blocco | Coda",
				ENABLED = "Abilitato",
				NAME = "Nome",
				DESC = "Nota",
				ICON = "Icona",
				SETBLOCKER = "Setta\nBlocco",
				SETBLOCKERTOOLTIP = "Blocca l'azione selezionata da esser eseguta nella rotazione\nNon verrá usata in nessuna condizione\n\nTastodestro: Crea macro",
				SETQUEUE = "Set\nCoda",
				SETQUEUETOOLTIP = "Accoda l'azione selezionata alla rotazione\nUtilizza l'azione appena é possibile\n\nTastodestro: Crea macro\nPuoi passare ulteriori condizioni nella macro creata per la coda\nCome ad esempio quale unit utilizzare (UnitID è chiave), esempio: { Priority = 1, UnitID = 'player' }\nÈ possibile trovare chiavi accettabili con descrizione nella funzione 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloccato: |r",
				UNBLOCKED = "|cff00ff00Sbloccato: |r",
				KEY = "[Chiave: ",
				KEYTOTAL = "[Totale coda: ",
				KEYTOOLTIP = "Usa questa chiave nel tab 'Messaggi'",
				MACRO = "Macro",
				MACROTOOLTIP = "Deve essere il più breve possibile, il macro è limitato a 255 byte\ncirca 45 byte devono essere riservati per catene multiple, è supportato il multilinea\n\nSe il Macro viene omesso, verrà utilizzata la costruzione autounit predefinita:\n\"/cast [@unitID]spellName\" o \"/cast [@unitID]spellName(Rank %d)\" o \"/use item:itemID\"\n\nIl Macro deve sempre essere aggiunto ad azioni che contengono qualcosa come\n/cast [@player]spell:thisID\n/castsequence reset=1 spell:thisID, nil\n\nAccetta pattern:\n\"spell:12345\" verrà sostituito da spellName ottenuto dai numeri\n\"thisID\" verrà sostituito da self.SlotID o self.ID\n\"(Rank %d+)\" sostituirà Rank con la parola localizzata\nQualsiasi pattern può essere combinato, per esempio \"spell:thisID(Rank 1)\"",
				ISFORBIDDENFORMACRO = "è vietato cambiare macro!",
				ISFORBIDDENFORBLOCK = "non può esser messo in blocco!",
				ISFORBIDDENFORQUEUE = "non può esser messo in coda!",
				ISQUEUEDALREADY = "esiste giá nella coda!",
				QUEUED = "|cff00ff00Nella Coda: |r",
				QUEUEREMOVED = "|cffff0000Rimosso dalla Coda: |r",
				QUEUEPRIORITY = " ha prioritá #",
				QUEUEBLOCKED = "|cffff0000non può essere in Coda perché é giá bloccato!|r",
				SELECTIONERROR = "|cffff0000Non hai selezionato una riga!|r",
				AUTOHIDDEN = "[All specs] Nascondi automaticamente le azioni non disponibili",
				AUTOHIDDENTOOLTIP = "Rende la Tabella di Scorrimento più piccola e chiara per nascondere l'immagine\nAd esempio, la classe personaggio ha poche razze ma può usarne una, questa opzione nasconderà altre razze\nSolo per una visione confortevole",
				CHECKSPELLLVL = "[All specs] Verifica il livello richiesto",
				CHECKSPELLLVLTOOLTIP = "Tutti gli spell non disponibilit dat il livello del personaggio sono bloccati\nTorneranno disponibili non appena il personaggio raggiunge il livello richiesto",
				CHECKSPELLLVLERROR = "Giá inizializzato!",
				CHECKSPELLLVLERRORMAXLVL = "Sel al livello MAX possibile!",
				CHECKSPELLLVLMACRONAME = "VerificaLivello",
				LUAAPPLIED = "LUA code é applicato a ",
				LUAREMOVED = "LUA code é rimosso da ",
			},
			[4] = {
				HEADBUTTON = "Interruzioni",	
				HEADTITLE = "Profile per le interruzioni",					
				ID = "ID",
				NAME = "Nome",
				ICON = "Icona",
				USEKICK = "Calcio",
				USECC = "CC",
				USERACIAL = "Razziale",
				MIN = "Min: ",
				MAX = "Max: ",
				SLIDERTOOLTIP = "Imposta l'interruzione tra la durata percentuale minima e massima del cast\n\nIl colore rosso dei valori indica che sono troppo vicini tra loro e pericolosi da usare\n\nLo stato OFF indica che questi cursori non sono disponibili per questo elenco",
				USEMAIN = "[Main] Uso",
				USEMAINTOOLTIP = "Abilita o disabilita l'interruzione dell'elenco con le sue unità\n\nTastodestro: Crea macro",
				MAINAUTO = "[Main] Auto",
				MAINAUTOTOOLTIP = "Se abilitato:\nPvE: interrompe qualsiasi cast disponibile\nPvP: se è un guaritore e morirà in meno di 6 secondi o se è un giocatore senza i guaritori nemici nel raggio di azione\n\nSe disabilitato:\nInterrompe solo gli incantesimi aggiunti nella tabella di scorrimento per quell'elenco\n\nTastodestro: Crea macro",
				USEMOUSE = "[Mouse] Uso",
				USEMOUSETOOLTIP = "Abilita o disabilita l'interruzione dell'elenco con le sue unità\n\nTastodestro: Crea macro",
				MOUSEAUTO = "[Mouse] Auto",
				MOUSEAUTOTOOLTIP = "Se abilitato:\nPvE: interrompe qualsiasi cast disponibile\nPvP: interrompe solo gli incantesimi aggiunti nella tabella di scorrimento per gli elenchi PvP e Guarigione e solo i giocatori\n\nSe disabilitato:\nInterrompe solo gli incantesimi aggiunti nella tabella di scorrimento per quell'elenco\n\nTastodestro: Crea macro",
				USEHEAL = "[Heal] Uso",
				USEHEALTOOLTIP = "Abilita o disabilita l'interruzione dell'elenco con le sue unità\n\nTastodestro: Crea macro",
				HEALONLYHEALERS = "[Heal] Only Healers",
				HEALONLYHEALERSTOOLTIP = "Se abilitato:\nInterrompe solo i guaritori\n\nSe disabilitato:\nInterrompe qualsiasi ruolo nemico\n\nTastodestro: Crea macro",
				USEPVP = "[PvP] Uso",
				USEPVPTOOLTIP = "Abilita o disabilita l'interruzione dell'elenco con le sue unità\n\nTastodestro: Crea macro",
				PVPONLYSMART = "[PvP] Inteligente",
				PVPONLYSMARTTOOLTIP = "Se abilitato, verrà interrotto dalla logica avanzata:\n1) Controllo a catena sul curatore\n2) Bersaglio amico (o tu) ha il raffica di buff con tempo residuo >4 sec\n3) Qualcuno muore in meno di 8 sec\n4) I punti vita tuoi (o @target) vengono considerati\n\nNon selezionato: interrompe sempre gli incantesimi nella lista senza ulteriori logiche\n\nTastodestro: Crea macro",				
				INPUTBOXTITLE = "Srivi Incantesimo :",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): cancella incantesimo e rimuove il focus",
				INTEGERERROR = "Errore Integer overflow > tentativo di memorizzare piú di 7 numeri", 
				SEARCH = "Cerca per nome o ID ",
				ADDERROR = "|cffff0000Non hai specificato niente in 'Scrivi Incantesimo' o l'incantesimo non é stato trovato!|r",
				ADD = "Aggiungi Interruzione",					
				ADDTOOLTIP = "Aggiungi incantesimo indicato in 'Scrivi Incantesimo'\nalla lista selezionata",
				REMOVE = "Rimuovi Interruzione",
				REMOVETOOLTIP = "Rimuovi l'incantesimo alla riga selezionata della lista",
			},
			[5] = { 	
				HEADBUTTON = "Auree",					
				USETITLE = "[Each spec]",
				USEDISPEL = "Usa Dissoluzione",
				USEPURGE = "Usa Epurazione",
				USEEXPELENRAGE = "Usa Enrage",
				HEADTITLE = "[Globale]",
				MODE = "Modo:",
				CATEGORY = "Categoria:",
				POISON = "Dissolvi Veleni",
				DISEASE = "Dissolvi Malattie",
				CURSE = "Dissolvi Maledizioni",
				MAGIC = "Dissolvi Magia",
				MAGICMOVEMENT = "Dissolvi magia rallentamento/radici",
				PURGEFRIENDLY = "Epura amico",
				PURGEHIGH = "Epura nemico (alta prioritá)",
				PURGELOW = "Epura nemico  (bassa prioritá)",
				ENRAGE = "Expel Enrage",	
				BLEEDS = "Emorragie",
				BLESSINGOFPROTECTION = "Benedizione della Protezione",
				BLESSINGOFFREEDOM = "Benedizione della Libertà",
				BLESSINGOFSACRIFICE = "Benedizione del Sacrificio",
				BLESSINGOFSANCTUARY = "Benedizione del Santuario",	
				ROLE = "Ruolo",
				ID = "ID",
				NAME = "Nome",
				DURATION = "Durata\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icona",					
				ROLETOOLTIP = "Il tuo ruolo per usarla",
				DURATIONTOOLTIP = "Reazione all'aura se la durata é maggiore di (>) secondi specificati\nIMPORTANTE: Auree senza una durata come 'Favore Divino'\n(Paladino della luce) devono essere a 0. Questo indica che l'aura é presente!",
				STACKSTOOLTIP = "Reazione all'aura se la durata é maggiore o eguale a (>=) degli stack specificati",									
				BYID = "Utilizza ID\ninvece del nome",
				BYIDTOOLTIP = "L'ID deve testare TUTTE gli incantesimi\nche hanno lo stesso nome, ma hanno diversi livelli\ncome 'Afflizione Instabile'",					
				CANSTEALORPURGE = "Solo se può\nrubare o epurare",					
				ONLYBEAR = "Solo se bersaglio\nin 'Forma D'Orso'",									
				CONFIGPANEL = "'Aggiungi Aura' Configurazione",
				ANY = "Qualsiasi",
				HEALER = "Curatore",
				DAMAGER = "Tank|Danno",
				ADD = "Aggiungi Aura",					
				REMOVE = "Rimuovi Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursore",
				HEADTITLE = "Interazione con mouse",
				USETITLE = "[Spec Corrente] Configurazione pulsanti:",
				USELEFT = "Utilizza click sinistro",
				USELEFTTOOLTIP = "Utilizza macro /target mouseover che non é un click!\n\nTastodestro: Crea macro",
				USERIGHT = "Utilizza click destro",
				LUATOOLTIP = "Per fare riferimento all'unitá da controllare, utilizza 'thisunit' senza virgolette\nSe usi LUA nella categoria 'GameToolTip' questa unitaá non é allora valida\nIl codice deve avere un ritorno logico (vero) perche sia attivato\nQuesto codice ha setfenv questo significa che non hai bisogno di usare Action.\n\nSe vuoi rimuovere il codice predefinito, devi scrivere 'return true' senza virgolette\ninvece di una semplice eliminazione",							
				BUTTON = "Click",
				NAME = "Nome",
				LEFT = "Click sinistro",
				RIGHT = "Click Destro",
				ISTOTEM = "IsTotem",
				ISTOTEMTOOLTIP = "Se abilitato, controlla @mouseover per il tipo 'Totem' con il nome specificato\nPreviene anche il cast nel caso il totem @target sia giá presente",				
				INPUTTITLE = "inserisci il nome dell'oggetto (nella lingua di gioco!)", 
				INPUT = "Questo inserimento non é influenzato da maiuscole|minuscole",
				ADD = "Aggiungi",
				REMOVE = "Rimuovi",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "totem del collegamento spirituale",
				HEALINGTIDETOTEM = "totem della marea curativa",
				CAPACITORTOTEM = "totem della condensazione elettrica",					
				SKYFURYTOTEM = "totem della furia del cielo",					
				ANCESTRALPROTECTIONTOTEM = "totem del risveglio ancestrale",					
				COUNTERSTRIKETOTEM = "totem del controassalto",
				EXPLOSIVES = "esplosivi",
				WRATHGUARD = "guardia dell'ira",
				FELGUARD = "vilguardia",
				INFERNAL = "infernale",
				SHIVARRA = "shivarra",
				DOOMGUARD = "demone guardiano",
				FELHOUND = "vilsegugio",
				["UR'ZUL"] = "ur'zul",
				-- Optional totems
				TREMORTOTEM = "totem del tremore",
				GROUNDINGTOTEM = "totem dell'adescamento magico",
				WINDRUSHTOTEM = "totem del soffio di vento",
				EARTHBINDTOTEM = "totem del vincolo terrestre",
				-- GameToolTips
				ALLIANCEFLAG = "bandiera dell'alleanza",
				HORDEFLAG = "bandiera dell'orda",
				NETHERSTORMFLAG = "bandiera di landa fatua",
				ORBOFPOWER = "globo del potere",
			},
			[7] = {
				HEADBUTTON = "Messaggi",
				HEADTITLE = "Messaggio di sistema",
				USETITLE = "[Spec Corrente]",
				MSG = "MSG Sistema",
				MSGTOOLTIP = "Selezionato: attivo\nNon selezionato: non attivo\n\nTastodestro: Crea macro",
				CHANNELS = "Canali",
				CHANNEL = "Canale ",	
				DISABLERETOGGLE = "Blocca Coda Rimuovi",
				DISABLERETOGGLETOOLTIP = "Previeni l'eliminazione di un incantesimo dalla coda con un messaggio ripetuto\nEsempio, consente di inviare una macro spam senza rischiare eliminazioni non volute\n\nTastodestro: Crea macro",
				MACRO = "Macro per il tuo gruppo:",
				MACROTOOLTIP = "Questo è ciò che dovrebbe alla chat di gruppo per attivare l'azione assegnata ad una chiave specifica\nPer indirizzare un'azione a una unitá specifica, aggiungerlo alla macro o lasciala così com'è per l'utilizzo in rotazione singola/AoE\nSupportati: raid1-40, party1-4, player, arena1-5\nSOLO UN'UNITÀ PER MESSAGGIO!\n\nI tuoi compagni possono usare anche loro macro, ma fai attenzione, devono essere macro allineate!",
				KEY = "Chiave",
				KEYERROR = "Non hai specificato una chiave!",
				KEYERRORNOEXIST = "la chiave non esite!",
				KEYTOOLTIP = "Devi specificare una chiave per vincolare l'azione\nPuoi verificare|leggere lachiave nel Tab 'Azioni'",
				MATCHERROR = "il nome che stai usando esiste giá, usane un altro!",				
				SOURCE = "Il nomme della persona che ha detto",
				WHOSAID = "Che ha detto",
				SOURCETOOLTIP = "Opzionale. Puoi lasciarlo vuoto (raccomndato)\nSe vuoi configurarlo, il nome deve essere esattamente lo stesso indicato nella chat del gruppo",
				NAME = "Contiene un messaggio",
				ICON = "Icona",
				INPUT = "Inserire una frase da usare come messaggio di sistema",
				INPUTTITLE = "Frase",
				INPUTERROR = "Non hai inserito una frase!",
				INPUTTOOLTIP = "La frase verrà attivata in corrispondenza ai riscontri nella chat di gruppo(/party)\nNon é sensibile alle maiuscole\nIdentifica pattern, ciò significa che una frase scritta in chat con la combinazione delle parole raid, party, arena, party, player\nattiva l'azione nel meta slot desiderato\nNon hai bisogno di impostare i pattern elencati, sono usati on top alla macro\nIf non trova nessun pattern, allora verra usato lo slot per rotazione Singola e ad area",				
			},
			[8] = { -- this tab was translated by using google translate, if some one will wish to fix something let me know 
				HEADBUTTON = "Sistema di guarigione",
				OPTIONSPANEL = "Opzioni",
				OPTIONSPANELHELP = [[Le impostazioni di questo pannello influiscono 'Healing Engine' + 'Rotation'
									
									'Healing Engine' questo nome ci riferiamo al sistema di selezione @target attraverso
									la macro /target 'unitID'
									
									'Rotation' questo nome ci riferiamo a se stesso rotazione di guarigione/danno
									per l'unità primaria corrente (@target o @mouseover)
									
									A volte vedrai il testo 'profilo deve avere un codice per esso' che significa
									quali funzioni correlate non possono funzionare senza aggiungere l'autore del profilo
									codice speciale all'interno dei frammenti di lua
									
									Ogni elemento ha un tooltip, quindi leggilo attentamente e testalo se necessario
									Scenario 'Arena d'Addestramento' prima di iniziare un vero combattimento]],
				SELECTOPTIONS = "-- scegli le opzioni --",
				PREDICTOPTIONS = "Opzioni di previsione",
				PREDICTOPTIONSTOOLTIP = "Supportato: 'Healing Engine' + 'Rotation' (profilo deve avere un codice per esso)\n\nQueste opzioni influiscono:\n1. Previsione di integrità del membro del gruppo per la selezione di @target ('Healing Engine')\n2. Calcolo dell'azione terapeutica da utilizzare su @target/@mouseover ('Rotation')\n\nPulsanmte destro: Crea macro",
				INCOMINGHEAL = "Guarigione in arrivo",
				INCOMINGDAMAGE = "Danno in arrivo",
				THREATMENT = "Minaccia (PvE)",
				SELFHOTS = "HoTs",
				ABSORBPOSSITIVE = "Assorbi Positivo",
				ABSORBNEGATIVE = "Assorbi Negativo",
				SELECTSTOPOPTIONS = "Opzioni lo stop target",
				SELECTSTOPOPTIONSTOOLTIP = "Supportato: 'Healing Engine'\n\nQueste opzioni riguardano solo la selezione di @target e in particolare\nimpedirne la selezione se una delle opzioni ha esito positivo\n\nPulsanmte destro: Crea macro",
				SELECTSTOPOPTIONS1 = "@mouseover amichevole",
				SELECTSTOPOPTIONS2 = "@mouseover nemico",
				SELECTSTOPOPTIONS3 = "@target nemico",
				SELECTSTOPOPTIONS4 = "@target boss",
				SELECTSTOPOPTIONS5 = "@player morto",
				SELECTSTOPOPTIONS6 = "sincronizzare 'La rotazione non funziona, se'",
				SELECTSORTMETHOD = "Metodo di ordinamento target",
				SELECTSORTMETHODTOOLTIP = "Supportato: 'Healing Engine'\n\n'Percentuale di salute' ordina la selezione @target con il minor livello di integrità nel rapporto percentuale\n'Salute reale' ordina la selezione di @target con la minima salute nel rapporto esatto\n\nPulsanmte destro: Crea macro",
				SORTHP = "Percentuale di salute",
				SORTAHP = "Salute reale",
				AFTERTARGETENEMYORBOSSDELAY = "Ritardo target\nDopo @target nemico o boss",
				AFTERTARGETENEMYORBOSSDELAYTOOLTIP = "Supportato: 'Healing Engine'\n\nRitarda (in secondi) prima di selezionare il bersaglio successivo dopo aver selezionato un nemico o un boss in @target\n\nFunziona solo se 'Opzioni lo stop target' ha '@target nemico' o '@target boss' disattivato\n\nIl ritardo viene aggiornato ogni volta che le condizioni hanno esito positivo o viene reimpostato in altro modo\n\nPulsanmte destro: Crea macro",
				AFTERMOUSEOVERENEMYDELAY = "Ritardo target\nDopo il nemico @mouseover",
				AFTERMOUSEOVERENEMYDELAYTOOLTIP = "Supportato: 'Healing Engine'\n\nRitarda (in secondi) prima di selezionare il bersaglio successivo dopo aver selezionato un nemico in @mouseover\n\nFunziona solo se 'Opzioni lo stop target' ha disattivato '@mouseover nemico'\n\nIl ritardo viene aggiornato ogni volta che le condizioni hanno esito positivo o viene reimpostato in altro modo\n\nPulsanmte destro: Crea macro",
				HEALINGENGINEAPI = "Abilita API del Healing Engine",
				HEALINGENGINEAPITOOLTIP = "Quando abilitato, tutte le opzioni e impostazioni supportate di 'Healing Engine' funzioneranno",
				SELECTPETS = "Abilita Famigli",
				SELECTPETSTOOLTIP = "Supportato: 'Healing Engine'\n\nCambia animali domestici per gestirli da tutte le API in 'Healing Engine'\n\nPulsanmte destro: Crea macro",
				SELECTRESURRECTS = "Abilita Resurrezioni",
				SELECTRESURRECTSTOOLTIP = "Supportato: 'Healing Engine'\n\nAttiva/disattiva i giocatori morti per la selezione di @target\n\nFunziona solo fuori combattimento\n\nPulsanmte destro: Crea macro",
				HELP = "Aiuto",
				HELPOK = "Gotcha",
				ENABLED = "/tar", 
				ENABLEDTOOLTIP = "Supportato: 'Healing Engine'\n\nAttiva/disattiva '/target %s'",
				UNITID = "unitID", 
				NAME = "Nome",
				ROLE = "Ruolo",
				ROLETOOLTIP = "Supportato: 'Healing Engine'\n\nResponsabile della priorità nella selezione @target, che è controllata da offset\nGli animali domestici sono sempre 'Assaltatore'",
				DAMAGER = "Assaltatore",
				HEALER = "Guaritore",
				TANK = "Difensore",
				UNKNOWN = "Sconosciuto",
				USEDISPEL = "Dissi\npare",
				USEDISPELTOOLTIP = "Supportato: 'Healing Engine' (profilo deve avere un codice per esso) + 'Rotation' (profilo deve avere un codice per esso)\n\n'Healing Engine': Lo permette '/target %s' per dissipare\n'Rotation': Permette di usare dispel on '%s'\n\nElimina l'elenco specificato nella scheda 'Auree'",
				USESHIELDS = "Scudo",
				USESHIELDSTOOLTIP = "Supportato: 'Healing Engine' (profilo deve avere un codice per esso) + 'Rotation' (profilo deve avere un codice per esso)\n\n'Healing Engine': Lo permette '/target %s' per scudo\n'Rotation': Permette di usare scudo on '%s'",
				USEHOTS = "HoTs",
				USEHOTSTOOLTIP = "Supportato: 'Healing Engine' (profilo deve avere un codice per esso) + 'Rotation' (profilo deve avere un codice per esso)\n\n'Healing Engine': Lo permette '/target %s' per HoTs\n'Rotation': Permette di usare HoTs on '%s'",
				USEUTILS = "Utilità",
				USEUTILSTOOLTIP = "Supportato: 'Healing Engine' (profilo deve avere un codice per esso) + 'Rotation' (profilo deve avere un codice per esso)\n\n'Healing Engine': Lo permette '/target %s' per utilità\n'Rotation': Permette di usare utilità on '%s'\n\nUtilità significa azioni che supportano la categoria come 'Benedizione della Libertà', alcune delle quali possono essere specificate nella scheda 'Aure'",
				GGLPROFILESTOOLTIP = "\n\nI profili GGL salteranno gli animali domestici per questo %s ceil in 'Healing Engine' (selezione @target)",
				LUATOOLTIP = "Supportato: 'Healing Engine'\n\nUtilizza il codice che hai scritto come ultima condizione verificata in precedenza '/target %s'",
				LUATOOLTIPADDITIONAL = "\n\nPer fare riferimento a metatable che contengono dati 'thisunit' come l'uso della salute:\nlocal memberData = HealingEngine.Data.UnitIDs[thisunit]\nif memberData then Print(thisunit .. ' (' .. Unit(thisunit):Name() .. ')' .. ' has real health percent: ' .. memberData.realHP .. ' and modified: ' .. memberData.HP) end",
				AUTOHIDE = "Nascondi Automaticamente",
				AUTOHIDETOOLTIP = "Questo è solo un effetto visivo!\nFiltra automaticamente l'elenco e mostra solo unitID disponibile",						
				PROFILES = "Profili",
				PROFILESHELP = [[Le impostazioni di questo pannello influiscono 'Healing Engine' + 'Rotation'
								 
								 Ogni profilo registra assolutamente tutte le impostazioni della scheda corrente
								 Pertanto, è possibile modificare al volo il comportamento della selezione del bersaglio 
								 e della rotazione di guarigione
								 
								 Ad esempio: è possibile creare un profilo per lavorare sui gruppi 2 e 3 e il secondo
								 per l'intero raid e allo stesso tempo cambiarlo con una macro,
								 che può anche essere creato
								 
								 È importante comprendere che ogni modifica apportata in questa scheda deve essere 
								 salvata di nuovo manualmente
				]],
				PROFILE = "Profilo",
				PROFILEPLACEHOLDER = "-- nessun profilo o ha modifiche non salvate per il profilo precedente --",
				PROFILETOOLTIP = "Scrivi il nome del nuovo profilo nella casella di modifica in basso e fai clic su 'Salva'\n\nLe modifiche non verranno salvate in tempo reale!\nOgni volta che si apportano modifiche per salvarle, è necessario fare nuovamente clic su 'Salva' per il profilo selezionato",
				PROFILELOADED = "Profilo caricato: ",
				PROFILESAVED = "Profilo salvato: ",
				PROFILEDELETED = "Profilo cancellato: ",
				PROFILEERRORDB = "ActionDB non è inizializzato!",
				PROFILEERRORNOTAHEALER = "Devi essere un guaritore per usarlo!",
				PROFILEERRORINVALIDNAME = "Nome profilo non valido!",
				PROFILEERROREMPTY = "Non hai selezionato il profilo!",
				PROFILEWRITENAME = "Scrivi il nome del nuovo profilo",
				PROFILESAVE = "Salva",
				PROFILELOAD = "Caricare",
				PROFILEDELETE = "Elimina",
				CREATEMACRO = "Pulsanmte destro: Crea macro",
				PRIORITYHEALTH = "Priorità di salute",
				PRIORITYHELP = [[Le impostazioni di questo pannello influiscono 'Healing Engine'

								 Utilizzando queste impostazioni, è possibile modificare la priorità di
								 selezione target in base alle impostazioni
								 
								 Queste impostazioni cambiano virtualmente l'integrità, permettendo
								 il metodo di ordinamento per espandere le unità non solo filtra
								 secondo le loro reali + opzioni di previsione salute

								 Il metodo di ordinamento ordina tutte le unità per la salute minima
								 
								 Il moltiplicatore è il numero per il quale verrà moltiplicata la salute
								 
								 Offset è il numero che verrà impostato come percentuale fissa o
								 elaborato in modo aritmetico (-/+ HP) in base alla 'Modalità offset'
								 
								 'Utilità' significa incantesimi offensivi come 'Benedizione della Libertà'
				]],
				MULTIPLIERS = "Moltiplicatori",
				MULTIPLIERINCOMINGDAMAGELIMIT = "Limite danni in entrata",
				MULTIPLIERINCOMINGDAMAGELIMITTOOLTIP = "Limita i danni in arrivo in tempo reale poiché i danni possono essere così\nlargati che il sistema smette di 'scendere' da @target.\nMetti 1 se vuoi ottenere un valore non modificato\n\nPulsanmte destro: Crea macro",
				MULTIPLIERTHREAT = "Minaccia",
				MULTIPLIERTHREATTOOLTIP = "Elaborato se esiste una minaccia maggiore (ad es. L'unità sta tankando)\nMetti 1 se vuoi ottenere un valore non modificato\n\nPulsanmte destro: Crea macro",
				MULTIPLIERPETSINCOMBAT = "Famigli in combattimento",
				MULTIPLIERPETSINCOMBATTOOLTIP = "Pets must be enabled to make it work!\nMetti 1 se vuoi ottenere un valore non modificato\n\nPulsanmte destro: Crea macro",
				MULTIPLIERPETSOUTCOMBAT = "Famigli fuori combattimento",
				MULTIPLIERPETSOUTCOMBATTOOLTIP = "Gli animali domestici devono essere abilitati per farlo funzionare!\nMetti 1 se vuoi ottenere un valore non modificato\n\nPulsanmte destro: Crea macro",
				OFFSETS = "Offsets",
				OFFSETMODE = "Modalità offset",
				OFFSETMODEFIXED = "Fisso",
				OFFSETMODEARITHMETIC = "Aritmetica",
				OFFSETMODETOOLTIP = "'Fisso' imposterà lo stesso valore esatto in percentuale di salute\n'Aritmetica' -/+ valuterà la percentuale di salute\n\nPulsanmte destro: Crea macro",
				OFFSETSELFFOCUSED = "Se stesso\nFocalizzato (PvP)",
				OFFSETSELFFOCUSEDTOOLTIP = "Elaborato se i giocatori nemici ti prendono di mira in modalità PvP\n\nPulsanmte destro: Crea macro",
				OFFSETSELFUNFOCUSED = "Se stesso\nNon Focalizzato (PvP)",
				OFFSETSELFUNFOCUSEDTOOLTIP = "Elaborato se i giocatori nemici NON ti bersagliano in modalità PvP\n\nPulsanmte destro: Crea macro",
				OFFSETSELFDISPEL = "Se stesso Dissipare",
				OFFSETSELFDISPELTOOLTIP = "I profili GGL di solito hanno una condizione PvE per questo\n\nElimina l'elenco specificato nella scheda 'Auree'\n\nPulsanmte destro: Crea macro",
				OFFSETHEALERS = "Guaritori",
				OFFSETTANKS = "Difensori",
				OFFSETDAMAGERS = "Assaltatori",
				OFFSETHEALERSDISPEL = "Guaritori Dissipare",
				OFFSETHEALERSTOOLTIP = "Elaborato solo su altri guaritori\n\nElimina l'elenco specificato nella scheda 'Auree'\n\nPulsanmte destro: Crea macro",
				OFFSETTANKSDISPEL = "Difensori Dissipare",
				OFFSETTANKSDISPELTOOLTIP = "Elimina l'elenco specificato nella scheda 'Auree'\n\nPulsanmte destro: Crea macro",
				OFFSETDAMAGERSDISPEL = "Assaltatori Dissipare",
				OFFSETDAMAGERSDISPELTOOLTIP = "Elimina l'elenco specificato nella scheda 'Auree'\n\nPulsanmte destro: Crea macro",
				OFFSETHEALERSSHIELDS = "Guaritori Scudo",
				OFFSETHEALERSSHIELDSTOOLTIP = "Auto inclusa (@player)\n\nPulsanmte destro: Crea macro",
				OFFSETTANKSSHIELDS = "Difensori Scudo",
				OFFSETDAMAGERSSHIELDS = "Assaltatori Scudo",
				OFFSETHEALERSHOTS = "Guaritori HoTs",
				OFFSETHEALERSHOTSTOOLTIP = "Auto inclusa (@player)\n\nPulsanmte destro: Crea macro",
				OFFSETTANKSHOTS = "Difensori HoTs",
				OFFSETDAMAGERSHOTS = "Assaltatori HoTs",
				OFFSETHEALERSUTILS = "Guaritori Utilità",
				OFFSETHEALERSUTILSTOOLTIP = "Auto inclusa (@player)\n\nPulsanmte destro: Crea macro",
				OFFSETTANKSUTILS = "Difensori Utilità",
				OFFSETDAMAGERSUTILS = "Assaltatori Utilità",
				MANAMANAGEMENT = "Gestione del mana",
				MANAMANAGEMENTHELP = [[Le impostazioni di questo pannello influiscono solo 'Rotation'
									   
									   Il profilo deve avere un codice per questo! 
									   
									   Funziona se:
									   1. Istanza interna
									   2. In modalità PvE
									   3. In combattimento  
									   4. Dimensione del gruppo >= 5
									   5. Avere un capo (i) focalizzato dai membri
				]],
				MANAMANAGEMENTMANABOSS = "La tua percentuale di mana <= percentuale di salute media dei boss",
				MANAMANAGEMENTMANABOSSTOOLTIP = "Inizia a salvare la fase di mana se la condizione ha esito positivo\n\nLa logica dipende dal profilo che si utilizza!\n\nNon tutti i profili supportano questa impostazione!\n\nPulsanmte destro: Crea macro",
				MANAMANAGEMENTSTOPATHP = "Interrompere la gestione\nPercentuale di salute",
				MANAMANAGEMENTSTOPATHPTOOLTIP = "Smette di salvare mana se unità primaria\n(@target/@mouseover) ha una percentuale di integrità inferiore a questo valore\n\nNon tutti i profili supportano questa impostazione!\n\nPulsanmte destro: Crea macro",
				OR = "O",
				MANAMANAGEMENTSTOPATTTD = "Interrompere la gestione\nTempo di morire",
				MANAMANAGEMENTSTOPATTTDTOOLTIP = "Smette di salvare mana se unità primaria\n(@target/@mouseover) ha il tempo di morire (in secondi) al di sotto di questo valore\n\nNon tutti i profili supportano questa impostazione!\n\nPulsanmte destro: Crea macro",
				MANAMANAGEMENTPREDICTVARIATION = "Efficacia di conservazione del mana",
				MANAMANAGEMENTPREDICTVARIATIONTOOLTIP = "Influisce solo sulle impostazioni delle abilità di guarigione 'AUTO'!\n\nQuesto è un moltiplicatore su cui verrà calcolata la guarigione pura all'avvio della fase di salvataggio del mana\n\nMaggiore è il livello, maggiore è il risparmio di mana, ma meno APM\n\nPulsanmte destro: Crea macro",
			},			
			[9] = {
				HEADBUTTON = "Tasti di scelta rapida",
				FRAMEWORK = "[Ogni spec] Struttura",
				HOTKEYINSTRUCTION = "Premi o clicca qualsiasi tasto rapido o pulsante del mouse per assegnare",
				META = "Meta",
				METAENGINEROWTT = "Doppio clic sinistro per assegnare il tasto rapido\nDoppio clic destro per rimuovere l’assegnazione",
				ACTION = "Azione",
				HOTKEY = "Tasto rapido",
				HOTKEYASSIGN = "Crea",
				HOTKEYUNASSIGN = "Disassocia",
				ASSIGNINCOMBAT = "|cffff0000Impossibile assegnare in combattimento!",
				PRIORITIZEPASSIVE = "Dai priorità alla rotazione passiva",
				PRIORITIZEPASSIVETT = "Abilitato: Rotazione, Rotazione Secondaria eseguiranno prima la rotazione passiva, poi la rotazione nativa al clic verso il basso\nDisabilitato: Rotazione, Rotazione Secondaria eseguiranno prima la rotazione nativa al clic verso il basso, poi la rotazione passiva al rilascio",
				CHECKSELFCAST = "Applicare a se stessi",
				CHECKSELFCASTTT = "Abilitato: Se il modificatore SELFCAST è tenuto premuto, sui pulsanti di clic sarete voi il bersaglio",
				UNITTT = "Abilita o disabilita i pulsanti di clic per questa unità in rotazione passiva",
			},
		},
	},
	esES = {			
		NOSUPPORT = "No soportamos este perfil ActionUI todavía",	
		DEBUG = "|cffff0000[Debug] Error identificado: |r",			
		ISNOTFOUND = "no encontrado!",			
		CREATED = "creado",
		YES = "Si",
		NO = "No",
		TOGGLEIT = "Cambiar",
		SELECTED = "Seleccionado",
		RESET = "Reiniciar",
		RESETED = "Reiniciado",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro ya existe!|r",
		MACROLIMIT = "|cffff0000No se puede crear la macro, límite alcanzado. Debes borrar al menos una macro!|r",
		MACROINCOMBAT = "|cffff0000No se puede crear macro en combate. Necesitas salir del combate!|r",
		MACROSIZE = "|cffff0000El tamaño de la macro no puede superar los 255 bytes!|r",
		GLOBALAPI = "API Global: ",
		RESIZE = "Redimensionar",
		RESIZE_TOOLTIP = "Click-y-arrastrar para redimensionar",
		CLOSE = "Cerca",
		APPLY = "Aplicar",
		UPGRADEDFROM = "actualizado de ",
		UPGRADEDTO = " a ",		
		PROFILESESSION = {
			BUTTON = "Sesión de perfil\nEl clic izquierdo abre el panel de usuario\nEl clic derecho abre el panel de desarrollo",
			BNETSAVED = "¡Su clave de usuario se ha almacenado correctamente en caché para una sesión de perfil sin conexión!",
			BNETMESSAGE = "¡Battle.net está desconectado!\n¡Reinicia el juego con Battle.net habilitado!",
			BNETMESSAGETRIAL = "!! Tu personaje está en prueba y no puede usar una sesión de perfil sin conexión !!",
			EXPIREDMESSAGE = "¡Tu suscripción para %s ha caducado!\n¡Por favor, póngase en contacto con el desarrollador del perfil!",
			AUTHMESSAGE = "Gracias por usar el perfil premium\nPara autorizar su clave, póngase en contacto con el desarrollador del perfil!",
			AUTHORIZED = "Su clave está autorizada!",			
			REMAINING = "[%s] permanece %d segundos",
			DISABLED = "[%s] |cffff0000sesión expirada!|r",
			PROFILE = "Perfil:",
			TRIAL = "(ensayo)",
			FULL = "(la prima)",
			UNKNOWN = "(no autorizado)",
			DEVELOPMENTPANEL = "Desarrollo",
			USERPANEL = "Usuario",
			PROJECTNAME = "Nombre del Proyecto",
			PROJECTNAMETT = "Tu desarrollo/proyecto/rutinas/nombre de marca",
			SECUREWORD = "Palabra Segura",
			SECUREWORDTT = "Su palabra segura como contraseña maestra para el nombre del proyecto",
			KEYTT = "'dev_key' utilizado en ProfileSession:Setup('dev_key', {...})",
			KEYTTUSER = "Enviar esta clave al autor del perfil!",
		},
		SLASH = {
			LIST = "Lista de comandos:",
			OPENCONFIGMENU = "Mostrar menú de configuración Action",
			OPENCONFIGMENUTOASTER = "Mostrar menú de configuración Toaster",
			HELP = "Mostrar ayuda",
			QUEUEHOWTO = "macro (toggle) para sistema de secuencia (Cola), TABLENAME es una etiqueta de referencia para SpellName|ItemName (en inglés)",
			QUEUEEXAMPLE = "ejemplo de uso de Cola",
			BLOCKHOWTO = "macro (toggle) para deshabilitar|habilitar cualquier acción (Blocker), TABLENAME es una etiqueta de referencia para SpellName|ItemName (en inglés)",
			BLOCKEXAMPLE = "ejemplo de uso de Blocker",
			RIGHTCLICKGUIDANCE = "La mayoría de elementos son usables con el botón izquierdo y derecho del ratón. El botón derecho del ratón creará un macro toggle por lo que puedes considerar la sugerencia anterior",				
			INTERFACEGUIDANCE = "Explicación de la UI:",
			INTERFACEGUIDANCEEACHSPEC = "[Each spec] relativa a la ACTUAL especialización seleccionada",
			INTERFACEGUIDANCEALLSPECS = "[All specs] relativa a TODAS las especializaciones disponibles de tus personajes",
			INTERFACEGUIDANCEGLOBAL = "[Global] relativa a toda tu cuenta, TODOS los personajes, TODAS las especializaciones",
			ATTENTION = "|cffff0000ATENCIÓN|r Acción funcional solo para perfiles creados después del 31.05.2019. Los perfiles antiguos serán actualizados para este sistema en el futuro",			
			TOTOGGLEBURST = "para alternar el modo de ráfaga",
			TOTOGGLEMODE = "para alternar PvP / PvE",
			TOTOGGLEAOE = "para alternar AoE",
		},
		TAB = {
			RESETBUTTON = "Reiniciar ajustes",
			RESETQUESTION = "¿Estás seguro?",
			SAVEACTIONS = "Guardar ajustes de Acciones",
			SAVEINTERRUPT = "Guardar Lista de Interrupciones",
			SAVEDISPEL = "Guardar Lista de Auras",
			SAVEMOUSE = "Guardar Lista de Cursor",
			SAVEMSG = "Guardar Lista de Mensajes",
			SAVEHE = "Guardar ajustes de Sistema de curacióne",
			SAVEHOTKEYS = "Guardar configuración de teclas rápidas",
			LUAWINDOW = "Configurar LUA",
			LUATOOLTIP = "Para referirse a la unidad de comprobación, usa 'thisunit' sin comillas\nEl código debe tener retorno boolean (true) para procesar las condiciones\nEste código tiene setfenv que significa lo que no necesitas usar Action. para cualquier cosa que tenga it\n\nSi quieres borrar un codigo default necesitas escribir 'return true' sin comillas en vez de removerlo todo",
			BRACKETMATCH = "Correspondencia de corchetes",
			CLOSELUABEFOREADD = "Cerrar las configuración de LUA antes de añadir",
			FIXLUABEFOREADD = "Debes arreglas los errores en la Configuración de LUA antes de añadir",
			RIGHTCLICKCREATEMACRO = "Botón derecho: Crear macro",
			CEILCREATEMACRO = "Botón derecho: Crear macro para establecer el valor '%s' para el techo '%s' en esta fila\nShift + botón derecho: Crear macro para establecer el valor '%s' para '%s' ceil-\n-y el valor opuesto para otros techos 'boolean' en esta fila",
			ROWCREATEMACRO = "Botón derecho: Crear macro para establecer el valor actual para todos los techos en esta fila\nShift + botón derecho: Crear macro para establecer un valor opuesto para todos los techos 'boolean' en esta fila",				
			NOTHING = "El Perfil no tiene configuración para este apartado",
			HOW = "Aplicar:",
			HOWTOOLTIP = "Global: Todas las cuentas, personajes y especializaciones",
			GLOBAL = "Global",
			ALLSPECS = "Para todas las especializaciones del personaje",
			THISSPEC = "Para la especialización actual del personaje",			
			KEY = "Tecla:",
			CONFIGPANEL = "'Añadir' Configuración",
			BLACKLIST = "Lista Negra",
			LANGUAGE = "[Español]",
			AUTO = "Auto",
			SESSION = "Sesión: ",
			PREVIEWBYTES = "Vista previa: %s bytes (límite máximo 255, 210 recomendados)",
			[1] = {
				HEADBUTTON = "General",	
				HEADTITLE = "[Each spec] Primaria",
				PVEPVPTOGGLE = "PvE / PvP Mostrar Manual",
				PVEPVPTOGGLETOOLTIP = "Forzar un perfil a cambiar a otro modo\n(especialmente útil cuando el War Mode está ON)\n\nClickDerecho: Crear macro", 
				PVEPVPRESETTOOLTIP = "Reiniciar mostrar manual a selección automática",
				CHANGELANGUAGE = "Cambiar idioma",
				CHARACTERSECTION = "Sección de Personaje",
				AUTOTARGET = "Auto Target",
				AUTOTARGETTOOLTIP = "Si el target está vacío, pero estás en combate, devolverá el que esté más cerca\nEl cambiador funciona de la misma manera si el target tiene inmunidad en PvP\n\nClickDerecho: Crear macro",					
				POTION = "Poción",
				HEARTOFAZEROTH = "Corazón de Azeroth",
				COVENANT = "Habilidades del pacto",
				RACIAL = "Habilidad Racial",
				STOPCAST = "Deja de lanzar",
				SYSTEMSECTION = "Sección del sistema",
				LOSSYSTEM = "Sistema LOS",
				LOSSYSTEMTOOLTIP = "ATENCIÓN: Esta opción causa un delay de 0.3s + un giro actual de gcd\nsi la unidad está siendo comprobada esta se localizará como pérdida (por ejemplo, detrás de una caja en la arena)\nDebes también habilitar las mismas opciones en Opciones Avanzadas\nEsta opción pone en una lista negra la unidad con perdida y\n deja de producir acciones a esta durante N segundos\n\nClickDerecho: Crear macro",
				STOPATBREAKABLE = "Detener el daño en el descanso",
				STOPATBREAKABLETOOLTIP = "Detendrá el daño dañino en los enemigos\nSi tienen CC como Polymorph\nNo cancela el ataque automático!\n\nClickDerecho: Crear macro",
				BOSSTIMERS = "Jefes Tiempos",
				BOSSTIMERSTOOLTIP = "Complementos DBM o BigWigs requeridos\n\nRastrea tiempos de pull y algunos eventos específicos como la basura que pueda venir.\nEsta característica no está disponible para todos los perfiles!\n\nClickDerecho: Crear macro",
				FPS = "Optimización de FPS",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Incrementa los frames por segundo aumentando la dependencia dinámica\nframes del ciclo de recarga (llamada) del ciclo de rotación\n\nTambién puedes establecer manualmente el intervalo siguiendo una regla simple:\nCuanto mayor sea el desplazamiento, mayor las FPS, pero peor actualización de rotación\nUn valor demasiado alto puede causar un comportamiento impredecible!\n\nClickDerecho: Crear macro",					
				PVPSECTION = "Sección PvP",
				REFOCUS = "Devuelve el guardado anterior @focus\n(arena1-5 unidades solamente)\nEs recomendable contra clases con invisibilidad\n\nClickDerecho: Crear macro",
				RETARGET = "Devuelve el guardado anterior @target\n(arena1-5 unidades solamente)\nEs recomendable contra cazadores con 'Feign Death' and cualquier objetivo imprevisto cae\n\nClickDerecho: Crear macro",
				TRINKETS = "Trinkets",
				TRINKET = "Trinket",
				BURST = "Modo Bursteo",
				BURSTEVERYTHING = "Todo",
				BURSTTOOLTIP = "Todo - En cooldown\nAuto - Boss o Jugadores\nOff - Deshabilitado\n\nClickDerechohabilitado\n\nClickDerecho: Crear macro\nSi quieres establecer el estado de conmutación fija usa el argumento en: 'Everything', 'Auto', 'Off'\n/run Action.ToggleBurst('Everything', 'Auto')",					
				HEALTHSTONE = "Healthstone | Poción curativa",
				HEALTHSTONETOOLTIP = "Establecer porcentaje de vida (HP)\n\nClickDerecho: Crear macro",
				COLORTITLE = "Selector de color",
				COLORUSE = "Usar color personalizado",
				COLORUSETOOLTIP = "Cambiar entre colores predeterminados y personalizados",
				COLORELEMENT = "Elemento",
				COLOROPTION = "Opción",
				COLORPICKER = "Recogedor",
				COLORPICKERTOOLTIP = "Haga clic para abrir la ventana de configuración para su 'Elemento'> 'Opción' seleccionado\nBotón derecho del mouse para mover la ventana abierta",
				FONT = "Fuente",
				NORMAL = "Normal",
				DISABLED = "Discapacitado",
				HEADER = "Encabezamiento",
				SUBTITLE = "Subtitular",
				TOOLTIP = "Información sobre herramientas",
				BACKDROP = "Fondo",
				PANEL = "Panel",
				SLIDER = "Control deslizante",
				HIGHLIGHT = "Realce",
				BUTTON = "Botón",
				BUTTONDISABLED = "Botón Discapacitado",
				BORDER = "Frontera",
				BORDERDISABLED = "Frontera Discapacitado",	
				PROGRESSBAR = "Barra de progreso",
				COLOR = "Color",
				BLANK = "Blanco",
				SELECTTHEME = "Seleccionar Tema Listo",
				THEMEHOLDER = "escoge un tema",
				BLOODYBLUE = "Sangriento Azul",
				ICE = "Hielo",
				AUTOATTACK = "Auto ataque",
				AUTOSHOOT = "Disparo automático",	
				PAUSECHECKS = "[All specs]\nLa rotación no funciona si:",
				ANTIFAKEPAUSES = "Pausas de AntiFake",
				ANTIFAKEPAUSESSUBTITLE = "Mientras se mantiene presionada la tecla de acceso rápido",
				ANTIFAKEPAUSESTT = "Dependiendo de la tecla de acceso rápido que selecciones,\nsolo el código asignado a ella funcionará cuando la mantengas presionada",
				VEHICLE = "En Vehículo",
				VEHICLETOOLTIP = "Ejemplo: Catapulta, arma de fuego",
				DEADOFGHOSTPLAYER = "Estás muerto",
				DEADOFGHOSTTARGET = "El Target está muerto",
				DEADOFGHOSTTARGETTOOLTIP = "Excepción a enemigo hunter if seleccionó como objetivo principal",
				MOUNT = "En montura",
				COMBAT = "Fuera de comabte", 
				COMBATTOOLTIP = "Si tu y tu target estáis fuera de combate. Invisible es una excepción\n(mientras te mantengas en sigilo esta condición se omitirá)",
				SPELLISTARGETING = "Hechizo está apuntando",
				SPELLISTARGETINGTOOLTIP = "Ejemplo: Blizzard, Salto heroico, Trampa de congelación",
				LOOTFRAME = "Frame de botín",
				EATORDRINK = "Está comiendo o bebiendo",
				MISC = "Misc:",		
				DISABLEROTATIONDISPLAY = "Esconder mostrar rotación",
				DISABLEROTATIONDISPLAYTOOLTIP = "Esconder el grupo, que está ubicado normalmente en la\nparte inferior central de la pantalla",
				DISABLEBLACKBACKGROUND = "Esconder fondo negro", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Esconder el fondo negro en la esquina izquierda\nATENCIÓN: Esto puede causar comportamientos impredecibles!",
				DISABLEPRINT = "Esconder impresión",
				DISABLEPRINTTOOLTIP = "Esconder notificaciones de chat de todo\nATENCIÓN: Esto también esconderá [Debug] Error Identificado!",
				DISABLEMINIMAP = "Esconder icono en el minimapa",
				DISABLEMINIMAPTOOLTIP = "Esconder icono de esta UI en el minimapa",
				DISABLEPORTRAITS = "Ocultar retrato de clase",
				DISABLEROTATIONMODES = "Ocultar modos de rotación",
				DISABLESOUNDS = "Desactivar sonidos",
				DISABLEADDONSCHECK = "Desactivar la comprobación de complementos",
				HIDEONSCREENSHOT = "Ocultar en captura de pantalla",
				HIDEONSCREENSHOTTOOLTIP = "Durante la captura de pantalla, se ocultan todos los cuadros de TellMeWhen\ny Action, y luego se muestran de nuevo",
			},
			[2]	= {
				COVENANTCONFIGURE = "Opciones de pacto",
				PROFILECONFIGURE = "Opciones de perfil",
				FLESHCRAFTHP = "Modelar carne\nPorcentaje de salud",
				FLESHCRAFTTTD = "Modelar carne\nTiempo De morir",
				PHIALOFSERENITYHP = "Ampolla de serenidad\nPorcentaje de salud",
				PHIALOFSERENITYTTD = "Ampolla de serenidad\nTiempo De morir",
				PHIALOFSERENITYDISPEL = "Ampolla de serenidad - Dispel",
				PHIALOFSERENITYDISPELTOOLTIP = "Si está habilitado, eliminará los efectos especificados en la pestaña 'Auras' independientemente de las casillas de verificación de esa pestaña\n\n",
				AND = "Y",
				OR = "O",
				OPERATOR = "Operador",
				TOOLTIPOPERATOR = "Es un operador lógico entre dos condiciones adyacentes\nSi la opción es 'Y', entonces ambas deben tener éxito\nSi la opción es 'O', entonces una de las dos condiciones debe ser exitosa\n\n",
				TOOLTIPTTD = "Este valor está en segundos, se compara con <=\nEs un cálculo matemático basado en el daño entrante para completar la muerte\n\n",
				TOOLTIPHP = "Este valor está en porcentaje, comparado con <=\nEs la salud actual del personaje en porcentajes\n\n",
			},
			[3] = {
				HEADBUTTON = "Acciones",
				HEADTITLE = "Bloquear | Cola",
				ENABLED = "Activado",
				NAME = "Nombre",
				DESC = "Nota",
				ICON = "Icono",
				SETBLOCKER = "Establecer\nBloquear",
				SETBLOCKERTOOLTIP = "Esto bloqueará la acción seleccionada en la rotación\nNunca la usará\n\nClickDerecho: Crear macro",
				SETQUEUE = "Establecer\nCola",
				SETQUEUETOOLTIP = "Pondrá la acción en la cola de rotación\nLo usará lo antes posible\n\nClickDerecho: Crear macro\nPuede pasar condiciones adicionales en la macro creada para la cola\nComo en qué unit usar (UnitID es la clave), ejemplo: { Priority = 1, UnitID = 'player' }\nPuede encontrar claves aceptables con descripción en la función 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloqueado: |r",
				UNBLOCKED = "|cff00ff00Desbloqueado: |r",
				KEY = "[Tecla: ",
				KEYTOTAL = "[Cola Total: ",
				KEYTOOLTIP = "Usa esta tecla en la pestaña 'Mensajes'",
				MACRO = "Macro",
				MACROTOOLTIP = "Debe ser lo más corto posible, el macro está limitado a 255 bytes\naproximadamente 45 bytes deben reservarse para multi-cadena, se soporta multilínea\n\nSi se omite el Macro, se usará la construcción autounit por defecto:\n\"/cast [@unitID]spellName\" o \"/cast [@unitID]spellName(Rank %d)\" o \"/use item:itemID\"\n\nEl Macro siempre debe añadirse a acciones que tengan algo como\n/cast [@player]spell:thisID\n/castsequence reset=1 spell:thisID, nil\n\nAcepta patrones:\n\"spell:12345\" se reemplazará por spellName obtenido de los números\n\"thisID\" se reemplazará por self.SlotID o self.ID\n\"(Rank %d+)\" reemplazará Rank por la palabra localizada\nCualquier patrón puede combinarse, por ejemplo \"spell:thisID(Rank 1)\"",
				ISFORBIDDENFORMACRO = "está prohibido cambiar la macro!",
				ISFORBIDDENFORBLOCK = "está prohibido ponerlo en bloquear!",
				ISFORBIDDENFORQUEUE = "está prohibido ponerlo en cola!",
				ISQUEUEDALREADY = "ya existe en la cola!",
				QUEUED = "|cff00ff00Cola: |r",
				QUEUEREMOVED = "|cffff0000Borrado de la cola: |r",
				QUEUEPRIORITY = " tiene prioridad #",
				QUEUEBLOCKED = "|cffff0000no puede añadirse a la cola porque SetBlocker lo ha bloqueado!|r",
				SELECTIONERROR = "|cffff0000No has seleccionado una fila!|r",
				AUTOHIDDEN = "[All specs] AutoOcultar acciones no disponibles",
				AUTOHIDDENTOOLTIP = "Hace que la tabla de desplazamiento sea más pequeña y clara ocultándola visualmente\nPor ejemplo, el tipo de personaje tiene pocos racials pero puede usar uno, esta opción hará que se escondan los demás raciales\nPara que sea más cómodo visualmente",				
				CHECKSPELLLVL = "[All specs] Comprueba el nivel requerido de la habilidad",
				CHECKSPELLLVLTOOLTIP = "Todas las habilidades que no estén disponibles por el nivel del personaje serán bloqueadas\nSerán actualizadas cada vez que se sube de nivel",
				CHECKSPELLLVLERROR = "Ya inicializado!",
				CHECKSPELLLVLERRORMAXLVL = "Estás al MÁXIMO nivel posible!",
				CHECKSPELLLVLMACRONAME = "Comprueba el nivel de la habilidad",
				LUAAPPLIED = "El código LUA ha sido aplicado a ",
				LUAREMOVED = "El código LUA ha sido removido de ",
			},
			[4] = {
				HEADBUTTON = "Interrupciones",	
				HEADTITLE = "Perfil de Interrupciones",					
				ID = "ID",
				NAME = "Nombre",
				ICON = "Icono",
				USEKICK = "Patada",
				USECC = "CC",
				USERACIAL = "Racial",
				MIN = "Min: ",
				MAX = "Max: ",
				SLIDERTOOLTIP = "Establece la interrupción entre el porcentaje mínimo y máximo de duración del lanzamiento\n\nEl color rojo de los valores significa que están demasiado cerca uno del otro y son peligrosos de usar\n\nEl estado OFF significa que estos controles deslizantes no están disponibles para esta lista",
				USEMAIN = "[Main] Utilizar",
				USEMAINTOOLTIP = "Habilita o deshabilita la lista con sus unidades para interrumpir\n\nClickDerecho: Crear macro",
				MAINAUTO = "[Main] Auto",
				MAINAUTOTOOLTIP = "Si está habilitado:\nPvE: interrumpe cualquier lanzamiento disponible\nPvP: si es healer y morirá en menos de 6 segundos, ya sea si es un jugador sin healers enemigos dentro del alcance\n\nSi está deshabilitado:\nInterrumpe solo los hechizos agregados en la tabla de desplazamiento para esa lista\n\nClickDerecho: Crear macro",
				USEMOUSE = "[Mouse] Utilizar",
				USEMOUSETOOLTIP = "Habilita o deshabilita la lista con sus unidades para interrumpir\n\nClickDerecho: Crear macro",
				MOUSEAUTO = "[Mouse] Auto",
				MOUSEAUTOTOOLTIP = "Si está habilitado:\nPvE: interrumpe cualquier lanzamiento disponible\nPvP: interrumpe solo los hechizos agregados en la tabla de desplazamiento para las listas PvP y Curar y solo para los jugadores\n\nSi está deshabilitado:\nInterrumpe solo los hechizos agregados en la tabla de desplazamiento para esa lista\n\nClickDerecho: Crear macro",
				USEHEAL = "[Heal] Utilizar",
				USEHEALTOOLTIP = "Habilita o deshabilita la lista con sus unidades para interrumpir\n\nClickDerecho: Crear macro",
				HEALONLYHEALERS = "[Heal] Solamente Healers",
				HEALONLYHEALERSTOOLTIP = "Si está habilitado:\nInterrumpe solo a los healers\n\nSi está deshabilitado:\nInterrumpe cualquier vocación enemiga\n\nClickDerecho: Crear macro",
				USEPVP = "[PvP] Utilizar",
				USEPVPTOOLTIP = "Habilita o deshabilita la lista con sus unidades para interrumpir\n\nClickDerecho: Crear macro",
				PVPONLYSMART = "[PvP] Inteligente",
				PVPONLYSMARTTOOLTIP = "Si está habilitado, se interrumpirá por lógica avanzada:\n1) Chain control en tu healer\n2) Alguien amigo (o tu) teneis buffs de Burst > 4 segundos\n3) Alguien morirá en menos de 8 segundos\n4) Tu (o @target) HP va a ejecutar la fase\n\nDesmarcado: interrumpirá esta lista siempre sin ningún tipo de lógica\n\nClickDerecho: Crear macro",		
				INPUTBOXTITLE = "Escribir habilidad:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): limpiar texto y borrar focus",
				INTEGERERROR = "Desbordamiento de enteros intentando almacenar > 7 números", 
				SEARCH = "Buscar por nombre o ID",
				ADD = "Añadir Interrupción",					
				ADDERROR = "|cffff0000No has especificado nada en 'Escribir Habilidad' o la habilidad no ha sido encontrada!|r",
				ADDTOOLTIP = "Añade habilidad del 'Escribir Habilidad'\n edita el cuadro a la lista seleccionada actual",
				REMOVE = "Borrar Interrupción",
				REMOVETOOLTIP = "Borra la habilidad seleccionada de la fila de la lista actual",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "[Each spec]",
				USEDISPEL = "Usar Dispel",
				USEPURGE = "Usar Purga",
				USEEXPELENRAGE = "Expel Enrague",
				HEADTITLE = "[Global]",
				MODE = "Modo:",
				CATEGORY = "Categoría:",
				POISON = "Dispelea venenos",
				DISEASE = "Dispelea enfermedades",
				CURSE = "Dispelea maldiciones",
				MAGIC = "Dispelea magias",
				MAGICMOVEMENT = "Dispelea relentizaciones/raíces",
				PURGEFRIENDLY = "Purgar amigo",
				PURGEHIGH = "Purgar enemigo (prioridad alta)",
				PURGELOW = "Purgar enemigo (prioridad baja)",
				ENRAGE = "Expel Enrague",
				BLEEDS = "Hemorragias",
				BLESSINGOFPROTECTION = "Bendición de Protección",
				BLESSINGOFFREEDOM = "Bendición de Libertad",
				BLESSINGOFSACRIFICE = "Bendición de Sacrificio",
				BLESSINGOFSANCTUARY = "Bendición de santuario",	
				ROLE = "Rol",
				ID = "ID",
				NAME = "Nombre",
				DURATION = "Duración\n >",
				STACKS = "Marcas\n >=",
				ICON = "Icono",					
				ROLETOOLTIP = "Tu rol para usar",
				DURATIONTOOLTIP = "Reacciona al aura si la duración de esta es mayor (>) de los segundos especificados\nIMPORTANTE: Auras sin duración como 'favor divido'\n(sanazión de Paladin) debe ser 0. Esto significa que el aura está presente!",
				STACKSTOOLTIP = "Reacciona al aura si tiene más o igual (>=) marcas especificadas",									
				BYID = "usar ID\nen vez de Nombre",
				BYIDTOOLTIP = "Por ID debe comprobar TODAS las habilidades\ncon el mismo nombre, pero asumir diferentes auras\ncomo 'Afliccion inestable'",					
				CANSTEALORPURGE = "Solo si puedes\nrobar o purgar",					
				ONLYBEAR = "Solo si la unidad está\nen 'Forma de oso'",									
				CONFIGPANEL = "'Añadir Aura' Configuración",
				ANY = "Cualquiera",
				HEALER = "Healer",
				DAMAGER = "Tanque|Dañador",
				ADD = "Añadir Aura",					
				REMOVE = "Borrar Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursor",
				HEADTITLE = "Interacción del ratón",
				USETITLE = "[Each spec] Configuración de botones:",
				USELEFT = "Usar click izquierdo",
				USELEFTTOOLTIP = "Estás usando macro /target mouseover lo que no significa click!\n\nClickDerecho: Crear macro",
				USERIGHT = "Usar click derecho",
				LUATOOLTIP = "Para referirse a la unidad seleccionada, usa 'thisunit' sin comillas\nSi usas LUA en Categoría 'GameToolTip' entonces thisunit no es válido\nEl código debe tener boolean return (true) para procesar las condiciones\nEste código tiene setfenv que significa que no necesitas usar Action. para ninguna que lo tenga\n\nSi quieres borrar el codigo por defecto necesitarás escribir 'return true' sin comillas en vez de borrarlo todo",							
				BUTTON = "Click",
				NAME = "Nombre",
				LEFT = "Click izquierdo",
				RIGHT = "Click Derecho",
				ISTOTEM = "Es Totem",
				ISTOTEMTOOLTIP = "Si está activado comprobará @mouseover en tipo 'Totem' para el nombre dado\nTambién prevendrá click en situaciones si tu @target ya tiene algún totem",				
				INPUTTITLE = "Escribe el nombre del objeto (localizado!)", 
				INPUT = "Esta entrada no puede escribirse en mayúsculas",
				ADD = "Añadir",
				REMOVE = "Borrar",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "tótem enlace de espíritu",
				HEALINGTIDETOTEM = "tótem de marea de sanación",
				CAPACITORTOTEM = "tótem capacitador",					
				SKYFURYTOTEM = "tótem furia del cielo",					
				ANCESTRALPROTECTIONTOTEM = "tótem de protección ancestral",					
				COUNTERSTRIKETOTEM = "tótem de golpe de contraataque",
				EXPLOSIVES = "explosivos",
				WRATHGUARD = "guardia de cólera",
				FELGUARD = "guardia vil",
				INFERNAL = "infernal",
				SHIVARRA = "shivarra",
				DOOMGUARD = "guardia apocalíptico",
				FELHOUND = "can manáfago",
				["UR'ZUL"] = "ur'zul",
				-- Optional totems
				TREMORTOTEM = "tótem de tremor",
				GROUNDINGTOTEM = "grounding totem",
				WINDRUSHTOTEM = "tótem de carga de viento",
				EARTHBINDTOTEM = "tótem nexo terrestre",
				-- GameToolTips
				ALLIANCEFLAG = "bandera de la alianza",
				HORDEFLAG = "bandera de la horda",
				NETHERSTORMFLAG = "bandera de la tormenta abisal",
				ORBOFPOWER = "orbe de poder",
			},
			[7] = {
				HEADBUTTON = "Mensajes",
				HEADTITLE = "Mensaje del Sistema",
				USETITLE = "[Each spec]",
				MSG = "Sistema de MSG",
				MSGTOOLTIP = "Marcado: funcionando\nDesmarcado: sin funcionar\n\nClickDerecho: Crear macro",
				CHANNELS = "Canales",
				CHANNEL = "Canal ",	
				DISABLERETOGGLE = "Bloquear borrar cola",
				DISABLERETOGGLETOOLTIP = "Prevenir la repetición de mensajes borrados de la cola del sistema\nE.j. Posible spam de macro sin ser removida\n\nClickDerecho: Crear macro",
				MACRO = "Macro para tu grupo:",
				MACROTOOLTIP = "Esto es lo que debe ser enviado al chat de grupo para desencadenar la acción asignada en la tecla específica\nPara direccionar la acción específica de la unidad, añádelos al macro o déjalo tal como está en la rotación Single/AoE\nSoportado: raid1-40, party1-4, player, arena1-5\nSOLO UNA UNIDAD POR MENSAJE!\n\nTus compañeros pueden usar macros también, pero ten cuidado, deben ser leales a esto!\n NO DES ESTA MACRO A LA GENTE QUE NO LE PUEDA GUSTAR QUE USES BOT!",
				KEY = "Tecla",
				KEYERROR = "No has especificado una tecla!",
				KEYERRORNOEXIST = "La tecla no existe!",
				KEYTOOLTIP = "Debes especificar una tecla para bindear la acción\nPuedes extraer la tecla en el apartado 'Acciones'",
				MATCHERROR = "Este nombre ya coincide, usa otro!",				
				SOURCE = "El nombre de la personaje que dijo",					
				WHOSAID = "Quien dijo",
				SOURCETOOLTIP = "Esto es opcional. Puede dejarlo en blanco (recomendado)\nSi quieres configurarlo, el nombre debe ser exactamente el mismo al del chat de grupo",
				NAME = "Contiene un mensaje",
				ICON = "Icono",
				INPUT = "Escribe una frase para el sistema de mensajes",
				INPUTTITLE = "Frase",
				INPUTERROR = "No has escrito una frase!",
				INPUTTOOLTIP = "La frase aparecerá en cualquier coincidencia del chat de grupo (/party)\nNo se distingue entre mayúsculas y minúsculas\nContiene patrones, significa que la frase escrita por alguien con la combinación de palabras de raid, party, arena, party, player\nse adapta la acción a la meta slot deseada\nNo necesitas establecer los patrones listados aquí, se utilizan como un añadido a la macro\nSi el patrón no es encontrado, los espacios para las rotaciones Single y AoE serán usadas",				
			},
			[8] = {
				HEADBUTTON = "Sistema de Cura",
				OPTIONSPANEL = "Opciones",
				OPTIONSPANELHELP = [[Las opciones de este panel afectan al 'Healing Engine' + 'Rotation'
									
									Nos referimos al 'Healing Engine' con la selección del sistema a través de @target
									con macro /target 'unitID'
									
									Nos referimos a 'Rotation' para rotación de la cura/daño
									para la actual primera unidad (@target o @mouseover)
									
									Hay veces que verás 'el perfil debe tener código para ello' que quiere decir
									que característica no funciona sin añadir un
									código especial de perfil de autor dentro del lua
									
									Cada elemento tiene información (tooltip), lee atentamente y prueba si es necesarioso
									en el escenario 'Terreno de Pruebas' antes de empezar la pelea real]],									
				SELECTOPTIONS = "-- seleccionar opciones --",
				PREDICTOPTIONS = "Predecir Opciones",
				PREDICTOPTIONSTOOLTIP = "Soportado: 'Healing Engine' + 'Rotation' (el perfil debe tener código para ello)\n\nEstas opciones afectan:\n1. Predicción de cura del miembro del grupo para la selección del @target ('Healing Engine')\n2. Cálculo de que acción de cura se usa en @target/@mouseover ('Rotation')\n\nBotón derecho: Crear macro",
				INCOMINGHEAL = "Cura Entrante",
				INCOMINGDAMAGE = "Daño Entrante",
				THREATMENT = "Amenaza (PvE)",
				SELFHOTS = "HoTs", -- ´de uno mismo
				ABSORBPOSSITIVE = "Absorción Positiva",
				ABSORBNEGATIVE = "Absorción Negativa",
				SELECTSTOPOPTIONS = "Opciones de parada de Target",
				SELECTSTOPOPTIONSTOOLTIP = "Soportado: 'Healing Engine'\n\nEstas opciones afectan solo a la selección de @target, y en especial\npreviene la selección si una de las opciones es satisfactoria\n\nBotón derecho: Crear macro",
				SELECTSTOPOPTIONS1 = "@mouseover amigo",
				SELECTSTOPOPTIONS2 = "@mouseover enemigo",
				SELECTSTOPOPTIONS3 = "@target enemigo",
				SELECTSTOPOPTIONS4 = "@target boss",
				SELECTSTOPOPTIONS5 = "@player muerto",
				SELECTSTOPOPTIONS6 = "sincronizar 'La rotación no funciona si'",
				SELECTSORTMETHOD = "Método de orden de target",
				SELECTSORTMETHODTOOLTIP = "Soportado: 'Healing Engine'\n\n'Porcentaje de Vida' ordena la selección del @target con el último ratio deporcentage de vida\n'Vida Actual' ordena la selección del @target con el ratio exacto de vida\n\Botón derecho: Crear macro",
				SORTHP = "Porcentaje de Vida",
				SORTAHP = "Vida Actual",
				AFTERTARGETENEMYORBOSSDELAY = "Retraso/Adelanto del Target\n @target enemigo o boss",
				AFTERTARGETENEMYORBOSSDELAYTOOLTIP = "Soportado: 'Healing Engine'\n\nRetraso (en segundos) antes de seleccionar el siguiente target después de seleccionar un enemigo o boss en @target\n\nSolo funciona si la opción 'Opciones de para Target' tiene '@target enemigo' o '@target boss' deshabilitada\n\nEl retraso se actualiza cada vez cuando las condiciones se realizan satisfactoriamente o se reinician\n\nBotón derecho: Crear macro",
				AFTERMOUSEOVERENEMYDELAY = "Target Retraso\nAdelanto @mouseover enemigo",
				AFTERMOUSEOVERENEMYDELAYTOOLTIP = "Soportado: 'Healing Engine'\n\nRetraso (en segundos) antes de seleccionar el siguiente target después de seleccionar un enemy en @mouseover\n\nSolo funciona si la opción 'Opciones de para Target' tiene '@mouseover enemigo' deshabilitada\n\nEl retraso se actualiza cada vez cuando las condiciones se realizan satisfactoriamente o se reinician\n\nBotón derecho: Crear macro",
				HEALINGENGINEAPI = "Habilitar API de Healing Engine",
				HEALINGENGINEAPITOOLTIP = "Al habilitarse, todas las opciones y configuraciones compatibles con 'Healing Engine' funcionarán",
				SELECTPETS = "Habilitar Mascotas",
				SELECTPETSTOOLTIP = "Soportado: 'Healing Engine'\n\nCambia mascotas para manejarlas por todas las API en 'Healing Engine'\n\nBotón derecho: Crear macro",
				SELECTRESURRECTS = "Enable Resurrects",
				SELECTRESURRECTSTOOLTIP = "Soportado: 'Healing Engine'\n\nAlterna jugadores muertos por la selección de @target \n\nSolo funciona fuera de combate\n\nBotón derecho: Crear macro",
				HELP = "Ayuda",
				HELPOK = "Entendido",
				ENABLED = "/tar", 
				ENABLEDTOOLTIP = "Soportado: 'Healing Engine'\n\nApagar/Encender '/target %s'",
				UNITID = "unitID",
				NAME = "Nombre",
				ROLE = "Rol",
				ROLETOOLTIP = "Soportado: 'Healing Engine'\n\nResponsable de la prioridad en la selección de @target, que se controla mediante compensaciones\nLas mascotas son siempre 'Dañadores'",
				DAMAGER = "Dañador",
				HEALER = "Healer",
				TANK = "Tanque",
				UNKNOWN = "Desconocido",
				USEDISPEL = "Disipar",
				USEDISPELTOOLTIP = "Soportado: 'Healing Engine' (el perfil debe tener código para ello) + 'Rotation' (el perfil debe tener código para ello)\n\n'Healing Engine': Permite '/target %s' para dispel\n'Rotation': Permite usar disipar en '%s'\n\nDisipar la lista especificada en la pestaña 'Auras'",
				USESHIELDS = "Escu\ndos",
				USESHIELDSTOOLTIP = "Soportado: 'Healing Engine' (el perfil debe tener código para ello) + 'Rotation' (el perfil debe tener código para ello)\n\n'Healing Engine': Permite '/target %s' para escudos\n'Rotation': Permite usar escudos en '%s'",
				USEHOTS = "HoTs",
				USEHOTSTOOLTIP = "Soportado: 'Healing Engine' (el perfil debe tener código para ello) + 'Rotation' (el perfil debe tener código para ello)\n\n'Healing Engine': Permite '/target %s' para HoTs\n'Rotation': Permite usarlo con HoTs en '%s'",
				USEUTILS = "Utils",
				USEUTILSTOOLTIP = "Soportado: 'Healing Engine' (el perfil debe tener código para ello) + 'Rotation' (el perfil debe tener código para ello)\n\n'Healing Engine': Permite '/target %s' para utilidades\n'Rotation': Permite usarlo en '%s'\n\nLas utilidades significan una categoría de soporte de acciones como 'Bendición de libertad', algunas de ellas se pueden especificar en la pestaña 'Auras'",
				GGLPROFILESTOOLTIP = "\n\nLos perfiles de GGL esquivarán las petas para este %s ceil en 'Healing Engine'(@target selection)",
				LUATOOLTIP = "Soportado: 'Healing Engine'\n\nUtiliza el código que escribió como la última condición verificada antes '/target %s'",
				LUATOOLTIPADDITIONAL = "\n\nPara referirse a metatabla que contiene datos de 'thisunit' como el uso de la salud:\nlocal memberData = HealingEngine.Data.UnitIDs[thisunit]\nif memberData then Print(thisunit .. ' (' .. Unit(thisunit):Name() .. ')' .. ' has real health percent: ' .. memberData.realHP .. ' and modified: ' .. memberData.HP) end",
				AUTOHIDE = "Auto Esconder",
				AUTOHIDETOOLTIP = "Esto es solo un efecto visual!\nFiltra automáticamente la lista y muestra solo unitID disponible",
				PROFILES = "Perfiles",
				PROFILESHELP = [[La configuración de este panel afecta 'Healing Engine' + 'Rotation'
								 
								Cada perfil registra absolutamente todas las configuraciones de la pestaña actual
								Por lo tanto, puede cambiar el comportamiento de la selección de objetivos y la rotación
								de curación sobre la marcha
								 
								Por ejemplo: puede crear un perfil para trabajar en los grupos 2 y 3, y el segundo
								para toda la incursión, y al mismo tiempo cambiarlo con una macro,
								que también se puede crear
								 
								Es importante comprender que cada cambio realizado en esta pestaña debe guardarse manualmente
				]],
				PROFILE = "Perfil",
				PROFILEPLACEHOLDER = "-- sin perfil o tiene cambios sin guardar para el perfil anterior --",
				PROFILETOOLTIP = "Escriba el nombre del nuevo perfil en el cuadro de edición a continuación y haga clic en 'Guardar'\n\n¡Los cambios no se guardarán en tiempo real!\nCada vez que realice cambios en caso de guardarlos, debe hacer clic nuevamente en 'Guardar' para el perfil seleccionado",
				PROFILELOADED = "Perfil cargado: ",
				PROFILESAVED = "Perfil guardado: ",
				PROFILEDELETED = "Borrar perfil: ",
				PROFILEERRORDB = "ActionDB no están inicializado!",
				PROFILEERRORNOTAHEALER = "¡Debes ser sanadora para usarlo!",
				PROFILEERRORINVALIDNAME = "Nombre de perfil inválido!",
				PROFILEERROREMPTY = "No has seleccionado el perfil!",
				PROFILEWRITENAME = "Escribe el nombre del nuevo perfil",
				PROFILESAVE = "Guardar",
				PROFILELOAD = "Cargar",
				PROFILEDELETE = "Borrar",
				CREATEMACRO = "Botón derecho: Crear macro",
				PRIORITYHEALTH = "Prioridad de Cura",
				PRIORITYHELP = [[La configuración de este panel solo afecta 'Healing Engine'

								Con esta configuración, puede cambiar la prioridad de
								selección de objetivo según la configuración
								 
								Estas configuraciones cambian virtualmente la salud, permitiendo
								El método de clasificación para expandir unidades filtra no solo
								según sus opciones de predicción real + salud

								El método de clasificación clasifica todas las unidades por menos salud
								El multiplicador es el número por el cual se multiplicará la salud.
								 
								La compensación es un número que se establecerá como porcentaje fijo o
								procesado aritméticamente (-/+ HP) dependiendo del 'Modo de compensación'
								 
								'Utils' significa hechizos ofensivos como 'Bendición de libertad'
				]],
				MULTIPLIERS = "Multiplicadores",
				MULTIPLIERINCOMINGDAMAGELIMIT = "Límite de daño entrante",
				MULTIPLIERINCOMINGDAMAGELIMITTOOLTIP = "Limita el daño entrante en tiempo real ya que el daño puede ser tan\ngrande que el sistema se detiene 'baja' del @target.\nPonga 1 si desea obtener un valor no modificado\n\nBotón derecho: Crear macro",
				MULTIPLIERTHREAT = "Amenaza",
				MULTIPLIERTHREATTOOLTIP = "Procesado si existe una amenaza mayor (por ejemplo si la unidad está atacando)\nPonga 1 si desea obtener un valor no modificado\n\nBotón derecho: Crear macro",
				MULTIPLIERPETSINCOMBAT = "Mascotas en combate",
				MULTIPLIERPETSINCOMBATTOOLTIP = "¡Las mascotas deben estar habilitadas para que funcione!\nPonga 1 si desea obtener un valor no modificado\n\nBotón derecho: Crear macro",
				MULTIPLIERPETSOUTCOMBAT = "Mascotas fuera de combate",
				MULTIPLIERPETSOUTCOMBATTOOLTIP = "¡Las mascotas deben estar habilitadas para que funcione!\nPonga 1 si desea obtener un valor no modificado\n\nBotón derecho: Crear macro",
				OFFSETS = "Desplazamientos",
				OFFSETMODE = "Modo de desplazamiento",
				OFFSETMODEFIXED = "Fijo",
				OFFSETMODEARITHMETIC = "Aritmética",
				OFFSETMODETOOLTIP = "'Fijo' establecerá exactamente el mismo valor en porcentaje de salud\n'Aritmética' será -/+ valor al porcentaje de salud\n\nBotón derecho: Crear macro",
				OFFSETSELFFOCUSED = "Auto\nenfocado (PvP)",
				OFFSETSELFFOCUSEDTOOLTIP = "Procesado si los jugadores enemigos te atacan en modo PvP\n\nBotón derecho: Crear macro",
				OFFSETSELFUNFOCUSED = "Auto\ndesenfocado (PvP)",
				OFFSETSELFUNFOCUSEDTOOLTIP = "Procesado si los jugadores enemigos NO te apuntan en modo PvP\n\nBotón derecho: Crear macro",
				OFFSETSELFDISPEL = "Disipador\n(a uno mismo)",
				OFFSETSELFDISPELTOOLTIP = "Los perfiles GGL normalmente tienen condiciones PvE para esto\n\nDisipar la lista especificada en la pestaña 'Auras'\n\nBotón derecho: Crear macro",
				OFFSETHEALERS = "Healers",
				OFFSETTANKS = "Tanques",
				OFFSETDAMAGERS = "Dañadores",
				OFFSETHEALERSDISPEL = "Disipador Healers",
				OFFSETHEALERSTOOLTIP = "Procesado solo en otros healers\n\nDisipar la lista especificada en la pestaña 'Auras'\n\nBotón derecho: Crear macro",
				OFFSETTANKSDISPEL = "Disipador Tanque",
				OFFSETTANKSDISPELTOOLTIP = "Disipar la lista especificada en la pestaña 'Auras'\n\nBotón derecho: Crear macro",
				OFFSETDAMAGERSDISPEL = "Disipador Dañadores",
				OFFSETDAMAGERSDISPELTOOLTIP = "Disipar la lista especificada en la pestaña 'Auras'\n\nBotón derecho: Crear macro",
				OFFSETHEALERSSHIELDS = "Escudos Healers",
				OFFSETHEALERSSHIELDSTOOLTIP = "Auto incluído (@player)\n\nBotón derecho: Crear macro",
				OFFSETTANKSSHIELDS = "Tanques Dañadores",
				OFFSETDAMAGERSSHIELDS = "Escudos Dañadores",
				OFFSETHEALERSHOTS = "HoTs Healer",
				OFFSETHEALERSHOTSTOOLTIP = "Auto incluído (@player)\n\nBotón derecho: Crear macro",
				OFFSETTANKSHOTS = "HoTs Tanque",
				OFFSETDAMAGERSHOTS = "HoTs Dañadores",
				OFFSETHEALERSUTILS = "Utils Healer",
				OFFSETHEALERSUTILSTOOLTIP = "Auto incluído (@player)\n\nBotón derecho: Crear macro",
				OFFSETTANKSUTILS = "Utils Tanque",
				OFFSETDAMAGERSUTILS = "Utils Dañadores",
				MANAMANAGEMENT = "Manejo de Maná",
				MANAMANAGEMENTHELP = [[La configuración de este panel solo afecta 'Rotation'
									   
									   ¡El perfil debe tener código para esto!
									   
									   Funciona en:
									   1. Dentro de Instancias
									   2. En modo PvE
									   3. En combate  
									   4. Grupos de >= 5
									   5. Tener boss(-es) focuseados por miembros
				]],
				MANAMANAGEMENTMANABOSS = "Tu Porcentaje de Mana <= Promedio del Porcentaje de Vida del Boss(-es)",
				MANAMANAGEMENTMANABOSSTOOLTIP = "Comienza a guardar la fase de maná si la condición es exitosa\n\nLa lógica depende del perfíl que uses!\n\nNo todos los perfiles soportan estas opciones!\n\nRight click: Create macro",
				MANAMANAGEMENTSTOPATHP = "Parar la gestión\nPorcentaje de salud",
				MANAMANAGEMENTSTOPATHPTOOLTIP = "Deja de guardar maná si la unidad principal\n(@target/@mouseover)tiene un porcentaje de salud por debajo de este valor\n\n¡No todos los perfiles admiten esta configuración!\n\nBotón derecho: Crear macro",
				OR = "O",
				MANAMANAGEMENTSTOPATTTD = "Parar la gestión\nTiempo de Morir",
				MANAMANAGEMENTSTOPATTTDTOOLTIP = "Deja de guardar maná si la unidad principal\n(@target/@mouseover) tiene tiempo de morir (en segundos) por debajo de este valor\n\n¡No todos los perfiles admiten esta configuración!\n\nBotón derecho: Crear macro",
				MANAMANAGEMENTPREDICTVARIATION = "Efectividad de conservación de maná",
				MANAMANAGEMENTPREDICTVARIATIONTOOLTIP = "¡Solo afecta la configuración de las habilidades de curación 'AUTO'!\n\nEste es un multiplicador en el que se calculará la curación pura cuando se inició la fase de guardado de maná\n\nCuanto mayor sea el nivel, mayor será el ahorro de maná, pero menos APM\n\nBotón derecho: Crear macro",			
			},			
			[9] = {
				HEADBUTTON = "Teclas rápidas",
				FRAMEWORK = "[Cada especialización] Marco",
				HOTKEYINSTRUCTION = "Presione o haga clic en cualquier tecla rápida o botón del ratón para asignar",
				META = "Meta",
				METAENGINEROWTT = "Doble clic izquierdo para asignar la tecla rápida\nDoble clic derecho para desasignar la tecla rápida",
				ACTION = "Acción",
				HOTKEY = "Tecla rápida",
				HOTKEYASSIGN = "Crear",
				HOTKEYUNASSIGN = "Desvincular",
				ASSIGNINCOMBAT = "|cffff0000¡No se puede asignar en combate!",
				PRIORITIZEPASSIVE = "Priorizar rotación pasiva",
				PRIORITIZEPASSIVETT = "Activado: Rotación, Rotación Secundaria harán primero la rotación pasiva, luego la rotación nativa al hacer clic al presionar\nDesactivado: Rotación, Rotación Secundaria harán primero la rotación nativa al hacer clic al presionar, luego la rotación pasiva al soltar",
				CHECKSELFCAST = "Aplicar a uno mismo",
				CHECKSELFCASTTT = "Activado: Si se mantiene el modificador SELFCAST, en los botones de clic usted será el objetivo",
				UNITTT = "Activa o desactiva los botones de clic para esta unidad en rotación pasiva",
			},
		},
	},
	ptPT = {		
		NOSUPPORT = "este perfil não suporta o ActionUI ainda",	
		DEBUG = "|cffff0000[Debug] Identificação de erro: |r",			
		ISNOTFOUND = "não encontrado!",			
		CREATED = "criado",
		YES = "Sim",
		NO = "Não",
		TOGGLEIT = "Trocar",
		SELECTED = "Selecionado",
		RESET = "Resetar",
		RESETED = "Resetado",
		MACRO = "Macro",
		MACROEXISTED = "|cffff0000Macro já existe!|r",
		MACROLIMIT = "|cffff0000Impossível criar macro. Você já chegou no limite. Você precisa remover pelo menos um macro!|r",	
		MACROINCOMBAT = "|cffff0000Impossível criar macro em combate. Você precisa sair de combate!|r",
		MACROSIZE = "|cffff0000O tamanho da macro não pode exceder 255 bytes!|r",
		GLOBALAPI = "API Global: ",
		RESIZE = "Redimensionar",
		RESIZE_TOOLTIP = "Clique-e-arraste to redimensionar",
		CLOSE = "Fechar",
		APPLY = "Aplicar",
		UPGRADEDFROM = "Melhorado de ",
		UPGRADEDTO = " para ",		
		PROFILESESSION = {
			BUTTON = "Sessão de perfil\nClique esquerdo abre o painel do usuário\nClique com o botão direito para abrir o painel de desenvolvimento",
			BNETSAVED = "Sua chave de usuário foi armazenada em cache com sucesso para uma sessão de perfil offline!",
			BNETMESSAGE = "Battle.net está offline!\nPor favor, reinicie o jogo com o Battle.net ativado!",
			BNETMESSAGETRIAL = "!! Seu personagem está em teste e não pode usar uma sessão de perfil offline !!",
			EXPIREDMESSAGE = "Sua assinatura para %s expirou!\nEntre em contato com o desenvolvedor do perfil!",
			AUTHMESSAGE = "Obrigado por usar o perfil premium\nPara autorizar sua chave, entre em contato com o desenvolvedor do perfil!", 
			AUTHORIZED = "Sua chave está autorizada!",		
			REMAINING = "[%s] permanece %d segundos",
			DISABLED = "[%s] |cffff0000sessão expirada!|r",
			PROFILE = "Perfil:",
			TRIAL = "(julgamento)",
			FULL = "(prêmio)",
			UNKNOWN = "(não autorizado)",
			DEVELOPMENTPANEL = "Desenvolvimento",
			USERPANEL = "Do utilizador",
			PROJECTNAME = "Nome do Projeto",
			PROJECTNAMETT = "Seu desenvolvimento/projeto/rotinas/nome da marca",
			SECUREWORD = "Palavra Segura",
			SECUREWORDTT = "Sua palavra segura como senha mestra para o nome do projeto",
			KEYTT = "'dev_key' usado em ProfileSession:Setup('dev_key', {...})",
			KEYTTUSER = "Envie esta chave para o autor do perfil!",
		},
		SLASH = {
			LIST = "Lista de comandos:",
			OPENCONFIGMENU = "exibe o menu de configurações Action",
			OPENCONFIGMENUTOASTER = "exibe o menu de configurações Toaster",
			HELP = "exibe informações de ajuda",
			QUEUEHOWTO = "macro (ativável) para o sistema de sequência (Queue), o TABLENAME é uma referência para o SpellName|ItemName (em Inglês)",
			QUEUEEXAMPLE = "exemplo de uso da Queue",
			BLOCKHOWTO = "macro (ativável) para habilitar|desabilitar qualquer ação (Blocker), o TABLENAME é uma referência para o SpellName|ItemName (em Inglês)",
			BLOCKEXAMPLE = "exemplo de uso do Blocker",
			RIGHTCLICKGUIDANCE = "Maioria dos elementos podem ser clicados com o botão esquerdo ou direito. O botão direito criará um ativador de macro então pode considerar a sugestão acima",				
			INTERFACEGUIDANCE = "Explicações da UI:",
			INTERFACEGUIDANCEEACHSPEC = "[Each spec] relativa para a especialização ATUAL",
			INTERFACEGUIDANCEALLSPECS = "[All specs] relativa para TODAS as especializações disponíveis para o personagem",
			INTERFACEGUIDANCEGLOBAL = "[Global] relativa para TODA sua conta, TODOS os personagems, TODAS as especializações",
			ATTENTION = "|cffff0000ATENÇÂO|r função do Action disponível apenas para pefís lançados após 31.05.2019. O perfíl antigo será atualizado para o sistema no futuro",		
			TOTOGGLEBURST = "ativar o  Burst Mode",
			TOTOGGLEMODE = "ativar o PvP / PvE",
			TOTOGGLEAOE = "ativar o AoE",
		},
		TAB = {
			RESETBUTTON = "Resetar configurações",
			RESETQUESTION = "Tem certeza?",
			SAVEACTIONS = "Salvar configurações das Actions",
			SAVEINTERRUPT = "Salvar lista de Interrupts",
			SAVEDISPEL = "Salvar lista de Auras",
			SAVEMOUSE = "Salvar lista de Cursors",
			SAVEMSG = "Salvar lista de MSG",
			SAVEHE = "Salvar configurações das Sistema de Cura",
			SAVEHOTKEYS = "Salvar configurações de atalhos",
			LUAWINDOW = "Configurar LUA",
			LUATOOLTIP = "Para se referir a unidade checada, use 'thisunit' sem aspas\nCódigo deve retornar um Boolean (true) para processar as condições\nEste código tem setfenv o que significa que você não precisa usar o Action para nada que já tenha ele\n\nSe quiser remover o código padrão você precisará escrever 'return true' sem aspas no lugar de remover tudo",
			BRACKETMATCH = "Igualar colchetes",
			CLOSELUABEFOREADD = "Fechar configuração LUA antes de salvar",
			FIXLUABEFOREADD = "Você precisa corrigir os erros do LUA antes de salvar",
			RIGHTCLICKCREATEMACRO = "RightClick: Criar macro",
			CEILCREATEMACRO = "Clique direito: Criar macro para estabelecer '%s' um valor de '%s' teto nessa linha\nShift + Clique direito: Criar macro para estabelecer '%s' um valor de '%s' teto-\n-e valor oposto para outros valores teto 'boolean' nessa linha",
			ROWCREATEMACRO = "Clique direito: Criar macro para estabelecer um valor atual para todos os tetos nessa linha\nShift + Clique direito: Criar macro para estabelecer um valor oposto para todos os tetos 'boolean' nessa linha",
			NOTHING = "Este perfil não possui configurações para esta aba",
			HOW = "Aplicar:",
			HOWTOOLTIP = "Global: Toda a conta, todos os personagens e todas as especializações",
			GLOBAL = "Global",
			ALLSPECS = "Para todas as especializações do personagem",
			THISSPEC = "Para a especialização atual do personagem",			
			KEY = "Chave:",
			CONFIGPANEL = "'Adicionar' Configuração",
			BLACKLIST = "Lista Negra",
			LANGUAGE = "[Português]",
			AUTO = "Auto",
			SESSION = "Sessão: ",
			PREVIEWBYTES = "Pré-visualização: %s bytes (limite máximo 255, 210 recomendados)",
			[1] = {
				HEADBUTTON = "Geral",	
				HEADTITLE = "[Each spec] Primário",
				PVEPVPTOGGLE = "PvE / PvP Ativação manual",
				PVEPVPTOGGLETOOLTIP = "Forçar um perfil a trocar para outro modo\n(especialmente útil quando o WarMode está ligado)\n\nRightClick: Criar macro", 
				PVEPVPRESETTOOLTIP = "Resetar a ativação manual para seleção automática",
				CHANGELANGUAGE = "Trocar língua",
				CHARACTERSECTION = "Seção de personagens",
				AUTOTARGET = "Alvo automático",
				AUTOTARGETTOOLTIP = "Se o alvo está vazio, mas você está em combate, será retornado o inimigo mais próximo\nO trocador funciona da mesma maneira se o alvo possui alguma imunidade em PVP\n\nRightClick: Criar macro",					
				POTION = "Poção",
				HEARTOFAZEROTH = "Coração de Azeroth",
				COVENANT = "Habilidades da Aliança",
				RACIAL = "Magia Racial",
				STOPCAST = "Parar de conjurar",
				SYSTEMSECTION = "Seção de Sistema",
				LOSSYSTEM = "Sistema LOS",
				LOSSYSTEMTOOLTIP = "ATENÇÃO: Esta opção causa um delay de 0.3s + o gcd atual\nse a unidade estiver localizada fora de LOS (por exemplo, atrás de uma caixa em arena)\nVocê também deve ativar a mesma opção em Configurações Avançadas\nEsta opção coloca na Lista Negra as unidades que não estiverem em LOS\ne para de prover ações para ela por N segundo\n\nRightClick: Criar macro",
				HEALINGENGINEPETS = "HealingEngine pets",
				HEALINGENGINEPETSTOOLTIP = "Incluir os pets do jogador na seleção de alvos e calcular cura para eles\n\nRightClick: Criar macro",
				STOPATBREAKABLE = "Pare o dano quando Quebravel",
				STOPATBREAKABLETOOLTIP = "Irá para o dano em alvos\nSe eles estiverem em CC como Polymorph\nO auto-ataque não é cancelado!\n\nRightClick: Criar macro",
				ALL = "Todos",
				RAID = "Raid",
				TANK = "Apenas Tanks",
				DAMAGER = "Apenas Causadores de Dano",
				HEALER = "Apenas Curadores",
				HEALINGENGINETOOLTIP = "Esta opção é relativa a seleção de alvos para curadores\nTodos: Todos os membros\nRaid: Todos os membros sem os tanks\n\nRightClick: Criar macro\nSe você gostaria de setar um estado de ativação use o argumento em (ARG): 'ALL', 'RAID', 'TANK', 'HEALER', 'DAMAGER'",				
				BOSSTIMERS = "Contadores do Chefes",
				BOSSTIMERSTOOLTIP = "Suplementos DBM ou BigWigs necessários\n\nRastreando contadoes de pull e alguns eventos específicos como trash a caminho.\nEsta funcionalidade não está disponível para todos os profiles\n\nRightClick: Criar macro",
				FPS = "Otimização de FPS",
				FPSSEC = " (sec)",
				FPSTOOLTIP = "AUTO: Aumenta os quadros por segundo por meio de aumento na depêndencia dinâmica \nquadros do ciclo de atualização (call) do ciclo de rotação\n\nVocê pode setar o intervalo manualmente seguindo uma simples regra:\nQuanto maior o slider maior o FPS, mas pior será a atualização da rotação\nValores muito altos podem causar comportamento imprevisível!\n\nRightClick: Criar macro",					
				PVPSECTION = "Seção PVP",
				REFOCUS = "Retorna @focus anterior\n(arena1-5 units only)\nRecomendado contra classes com invisibilidade\n\nRightClick: Criar macro",
				RETARGET = "Retorna @target anterior\n(arena1-5 units only)\nRecomendado contra caçadores usando 'Fingir de Morto' e outras perdas de alvo não previstas\n\nRightClick: Criar macro",
				TRINKETS = "Berloques",
				TRINKET = "Berloque",
				BURST = "Modo Explosão",
				BURSTEVERYTHING = "Tudo",
				BURSTTOOLTIP = "Tudo - Em recarga\nAuto - Chefe ou Jogadores\nOff - Desativado\n\nRightClick: Criar macro\nSe você gostaria de fixar o estado de ativação utilize o argumento em: 'Everything', 'Auto', 'Off'\n/run Action.ToggleBurst('Everything', 'Auto')",					
				HEALTHSTONE = "Pedra da vida | Poção de Cura",
				HEALTHSTONETOOLTIP = "Setar percentagem de vida (HP)\n\nRightClick: Criar macro",
				COLORTITLE = "Seletor de cor",
				COLORUSE = "Usar cor customizada",
				COLORUSETOOLTIP = "Trocar a cor padrão pela cor customizada",
				COLORELEMENT = "Elemento",
				COLOROPTION = "Opção",
				COLORPICKER = "Seletor",
				COLORPICKERTOOLTIP = "Clique para abrir a janela de configuração para o seu 'Element' selecionado > 'Option'\nBotão direito do mouse para mover a janela",
				FONT = "Fonte",
				NORMAL = "Normal",
				DISABLED = "Desabilitado",
				HEADER = "Cabeçalho",
				SUBTITLE = "Legenda",
				TOOLTIP = "Tooltip",
				BACKDROP = "Pano de fundo",
				PANEL = "Painel",
				SLIDER = "Slider",
				HIGHLIGHT = "Highlight",
				BUTTON = "Botão",
				BUTTONDISABLED = "Botão Desabilitado",
				BORDER = "Borda",
				BORDERDISABLED = "Borda Desabilitada",	
				PROGRESSBAR = "Barra de progresso",
				COLOR = "Cor",
				BLANK = "Em branco",
				SELECTTHEME = "Selecionar o tema de Pronto",
				THEMEHOLDER = "escolher tema",
				BLOODYBLUE = "Bloody Blue",
				ICE = "Gelo",
				AUTOATTACK = "Auto Attack",
				AUTOSHOOT = "Auto Shoot",
				PAUSECHECKS = "[All specs]\nRotação não funciona se:",
				ANTIFAKEPAUSES = "Pausas AntiFake",
				ANTIFAKEPAUSESSUBTITLE = "Enquanto a tecla de atalho é mantida pressionada",
				ANTIFAKEPAUSESTT = "Dependendo da tecla de atalho selecionada,\nsomente o código atribuído a ela funcionará quando você a mantiver pressionada",
				VEHICLE = "InVehicle",
				VEHICLETOOLTIP = "Example: Catapulta, Atirando",
				DEADOFGHOSTPLAYER = "Você está morto",
				DEADOFGHOSTTARGET = "Alvo está morto",
				DEADOFGHOSTTARGETTOOLTIP = "Caçador inimigo como exceção se ele for selecionado como alvo principal",
				MOUNT = "IsMounted",
				COMBAT = "Fora de combate", 
				COMBATTOOLTIP = "Se você e seu alvo estiverem fora de combate. Invisibilidade é exceção\n(quando invisivel esta condição será ignorada)",
				SPELLISTARGETING = "SpellIsTargeting",
				SPELLISTARGETINGTOOLTIP = "Exemplo: Nevasca, Salto Heroico, Armadilha Congelante",
				LOOTFRAME = "LootFrame",
				EATORDRINK = "Está comendo ou bebendo",
				MISC = "Misc:",		
				DISABLEROTATIONDISPLAY = "Esconder display da rotação",
				DISABLEROTATIONDISPLAYTOOLTIP = "Esconde o grupo, que está normalmente no\ncentro abaixo da sua tela",
				DISABLEBLACKBACKGROUND = "Esconder o fundo preto", 
				DISABLEBLACKBACKGROUNDTOOLTIP = "Esconde o fundo preto na parte superior esquerda\nATENÇÃO: Isto pode causar comportamento imprevisível!",
				DISABLEPRINT = "Esconder print",
				DISABLEPRINTTOOLTIP = "Esconder notificações de tudo\nATENÇÃO: Isso também esconderá Identificações de Erro [Debug]!",
				DISABLEMINIMAP = "Esconder icone no minimapa",
				DISABLEMINIMAPTOOLTIP = "Esconde o icone do minimapa desta UI",
				DISABLEPORTRAITS = "Esconder retrato da classe",
				DISABLEROTATIONMODES = "Esconder modos da rotação",
				DISABLESOUNDS = "Desabilitar sons",
				DISABLEADDONSCHECK = "Desabilitar verificação de complementos",
				HIDEONSCREENSHOT = "Esconder em capturas de tela",
				HIDEONSCREENSHOTTOOLTIP = "Durante a captura de tela esconda todos os quadros de Action do TellMeWhen,\n e então os mostra de volta",
			},
			[2]	= {
				COVENANTCONFIGURE = "Opções de aliança",
				PROFILECONFIGURE = "Opções de Perfil",
				FLESHCRAFTHP = "Moldacarne\nPorcentagem de Saúde",
				FLESHCRAFTTTD = "Moldacarne\nHora de morrer",
				PHIALOFSERENITYHP = "Frasco da Serenidade\nPorcentagem de Saúde",
				PHIALOFSERENITYTTD = "Frasco da Serenidade\nHora de morrer",
				PHIALOFSERENITYDISPEL = "Frasco da Serenidade - Dispel",
				PHIALOFSERENITYDISPELTOOLTIP = "Se ativado, ele removerá os efeitos especificados na guia 'Auras' independentemente das caixas de seleção dessa guia\n\n",
				AND = "E",
				OR = "Ou",
				OPERATOR = "Operador",
				TOOLTIPOPERATOR = "É um operador lógico entre duas condições adjacentes\nSe a escolha for 'E', ambas devem ser bem-sucedidas\nSe a escolha for 'Ou', uma das duas condições deve ser bem-sucedida\n\n",
				TOOLTIPTTD = "Este valor é em segundos, compara como <=\nÉ um cálculo matemático baseado no dano recebido até a morte completa\n\n",
				TOOLTIPHP = "Este valor é em porcentagem, comparado com <=\nA saúde do personagem atual em porcentagens\n\n",
			},
			[3] = {
				HEADBUTTON = "Ações",
				HEADTITLE = "Blocker | Queue",
				ENABLED = "Ativado",
				NAME = "Nome",
				DESC = "Nota",
				ICON = "Icone",
				SETBLOCKER = "Setar\nBloqueador",
				SETBLOCKERTOOLTIP = "Isso bloqueara a dada action na rotação\nEla nunca será utilizada\n\nRightClick: Criar macro",
				SETQUEUE = "Setar\nFila",
				SETQUEUETOOLTIP = "Isto colocará a action na fila\nEla será usada assim que possível\n\nRightClick: Criar macro\nVocê pode passar condições adicionais para o macro criado para a fila\nComo em qual unidade utilizar (UnitID é a chave), example: { Priority = 1, UnitID = 'player' }\nVocê pode achar as chaves aceitáveisna descrição da função 'Action:SetQueue' (Action.lua)",
				BLOCKED = "|cffff0000Bloqueado: |r",
				UNBLOCKED = "|cff00ff00Desbloqueado: |r",
				KEY = "[Key: ",
				KEYTOTAL = "[Total enfileirado: ",
				KEYTOOLTIP = "Use esta chave na aba 'Mensagens'",
				MACRO = "Macro",
				MACROTOOLTIP = "Deve ser o mais curto possível, o macro é limitado a 255 bytes\ncerca de 45 bytes devem ser reservados para múltipla cadeia, multilinha é suportado\n\nSe o Macro for omitido, será usada a construção autounit padrão:\n\"/cast [@unitID]spellName\" ou \"/cast [@unitID]spellName(Rank %d)\" ou \"/use item:itemID\"\n\nO Macro sempre deve ser adicionado a ações que tenham algo como\n/cast [@player]spell:thisID\n/castsequence reset=1 spell:thisID, nil\n\nAceita padrões:\n\"spell:12345\" será substituído por spellName obtido a partir dos números\n\"thisID\" será substituído por self.SlotID ou self.ID\n\"(Rank %d+)\" substituirá Rank pela palavra localizada\nQualquer padrão pode ser combinado, por exemplo \"spell:thisID(Rank 1)\"",
				ISFORBIDDENFORMACRO = "é proibido alterar macro!",
				ISFORBIDDENFORBLOCK = "é proibido para o bloqueado!",
				ISFORBIDDENFORQUEUE = "é proibido para a fila!",
				ISQUEUEDALREADY = "já existe na fila!",
				QUEUED = "|cff00ff00Enfileirado: |r",
				QUEUEREMOVED = "|cffff0000Removido da fila: |r",
				QUEUEPRIORITY = " tem prioridade #",
				QUEUEBLOCKED = "|cffff0000não pode ser enfileirado por que SetBlocker o bloqueou!|r",
				SELECTIONERROR = "|cffff0000Você não escolheu uma linha!|r",
				AUTOHIDDEN = "[All specs] Esconder automáticamente seções indisponíveis",
				AUTOHIDDENTOOLTIP = "Torna a tabela menor e mais clara\nPor exemplo a classe do personagem tem poucas raciais mas pode usar uma, esta opção irá esconder as outras raciais.\nApenas para conforto visual",
				CHECKSPELLLVL = "[All specs] Checar o nível da magia requerido",
				CHECKSPELLLVLTOOLTIP = "Todas as magias que não estão disponíveis no nível do personagem serão bloqueadas\nElas serão atualizadas toda vez ao subir de nível",
				CHECKSPELLLVLERROR = "Já inicializado",
				CHECKSPELLLVLERRORMAXLVL = "Você já está no level máximo possível",
				CHECKSPELLLVLMACRONAME = "CheckSpellLevel",
				LUAAPPLIED = "Código LUA foi aplicado em ",
				LUAREMOVED = "Código LUA foi removido de ",
			},
			[4] = {
				HEADBUTTON = "Interrupções",	
				HEADTITLE = "Interrupções do Perfil",					
				ID = "ID",
				NAME = "Nome",
				ICON = "Icone",
				USEKICK = "Chute",
				USECC = "CC",
				USERACIAL = "Racial",
				MIN = "Min: ",
				MAX = "Max: ",
				SLIDERTOOLTIP = "Seta a interrupção entre o a porcentagem minima e máxima do cast\n\nA cor vermelha dos valores significa que eles estão muito próximos um do outro e é perigoso de usar\n\nEstado OFF significa que os sliders não estão disponíveis para esta lista",
				USEMAIN = "[Main] Usar",
				USEMAINTOOLTIP = "Habilita ou desabilita a lista com suas unidades para interromper\n\nRightClick: Criar macro",
				MAINAUTO = "[Main] Auto",
				MAINAUTOTOOLTIP = "Se ativado:\nPvE: Interrompe qualquer cast disponível\nPvP: Se for um curador e ele vai morrer em menos de 6 segundos ou se o jogador não estiver no alcance do curador inimigo\n\nSe desabilitado:\nInterrompe apenas as magias adicionadas na lista\n\nRightClick: Criar macro",
				USEMOUSE = "[Mouse] Usar",
				USEMOUSETOOLTIP = "Habilita ou desabilita a lista com usas unidades para interromper\n\nRightClick: Criar macro",
				MOUSEAUTO = "[Mouse] Auto",
				MOUSEAUTOTOOLTIP = "Se ativado:\nPvE: Interrompe qualquer cast disponível\nPvP: Interrompe apenas magias na tabela de listas para PvP e curadores e apenas jogadores\n\nSe desabilitado:\nInterrompe apenas as magias na tabela daquela lista\n\nRightClick: Criar macro",
				USEHEAL = "[Heal] Usar",
				USEHEALTOOLTIP = "Habilita ou desabilita a lista com unidadades para interromper\n\nRightClick: Criar macro",
				HEALONLYHEALERS = "[Heal] Apenas curadores",
				HEALONLYHEALERSTOOLTIP = "Se ativado:\nInterrompe apenas curadores\n\nSe desabilitado:\nInterrompe qualquer função inimiga\n\nRightClick: Criar macro",
				USEPVP = "[PvP] Use",
				USEPVPTOOLTIP = "Habilita ou desabilita a lista com unidadades para interromper\n\nRightClick: Criar macro",
				PVPONLYSMART = "[PvP] Inteligente",
				PVPONLYSMARTTOOLTIP = "Se ativado irá interromper com lógica avançada:\n1) Controle em cadeia no eu curador\n2) Alguém tem buffs de explosão >4 sec\n3) Alguém vai morrer em menos de 8 segundos\n4) Você (ou @target) podem ser executados\n\nSe desativado irá interromper sem lógica avançada\n\nRightClick: Criar macro",
				INPUTBOXTITLE = "Escrever magia:",					
				INPUTBOXTOOLTIP = "ESCAPE (ESC): Limpar texto e remover focus",
				INTEGERERROR = "Transbordo de Inteiro tentando armazenar > 7 números.", 
				SEARCH = "Procure por nome ou ID",
				ADD = "Adicionar Interrupção",					
				ADDERROR = "|cffff0000Você não especificou nada em  'Escrever magia' ou a magia não foi encontrada!|r",
				ADDTOOLTIP = "Adicionar magia do campo 'Escrever magia'\n para a lista selecionada",
				REMOVE = "Remover interrupção",
				REMOVETOOLTIP = "Remove a magia selecionada da tabela da lista atual",
			},
			[5] = { 	
				HEADBUTTON = "Auras",					
				USETITLE = "[Each spec]",
				USEDISPEL = "Usar Dispel",
				USEPURGE = "Usar Purge",
				USEEXPELENRAGE = "Remover Enrage",
				HEADTITLE = "[Global]",
				MODE = "Modo:",
				CATEGORY = "Categoria:",
				POISON = "Remover venenos",
				DISEASE = "Remover doenças",
				CURSE = "Remover maldições",
				MAGIC = "Remover magic",
				MAGICMOVEMENT = "Remover lentidão/enraizamento mágico",
				PURGEFRIENDLY = "Expurgar aliado",
				PURGEHIGH = "Expurgar inimigo (prioridade alta)",
				PURGELOW = "Expurgar inimigo (prioridade baixa)",
				ENRAGE = "Remover Enrage",	
				BLEEDS = "Bleedings",
				BLESSINGOFPROTECTION = "Benção da Proteção",
				BLESSINGOFFREEDOM = "Benção da Liberdade",
				BLESSINGOFSACRIFICE = "Benção do Sacrificio",
				BLESSINGOFSANCTUARY = "Benção do Santuário",
				ROLE = "Função",
				ID = "ID",
				NAME = "Nome",
				DURATION = "Duração\n >",
				STACKS = "Stacks\n >=",
				ICON = "Icone",					
				ROLETOOLTIP = "Sua função utiliza",
				DURATIONTOOLTIP = "Reaja na aura se a duração da aura for maior (>) do que os segundos especificados\nIMPORTANTE: Auras sem duração como 'Graça divina'\n(Paladino Sagrado) devem ser 0. Isso significa que a aura está presente!",
				STACKSTOOLTIP = "Reaja na aura se ela tiver uma quantia de stacks maiour ou igual (>=) a quantia especificada",									
				BYID = "Use ID\nao inves do Nome",
				BYIDTOOLTIP = "Por ID se deve checar TODAS as magias\nque possuem o mesmo nome, mas assuma que são auras diferentes\ncomo 'Corrupção Instavel'",					
				CANSTEALORPURGE = "Somente se puder\nroubar ou expurgar",					
				ONLYBEAR = "Somente se a unidade estiver\nna 'Forma de Urso'",									
				CONFIGPANEL = "Configuração de 'Adicionar Aura'",
				ANY = "Qualquer",
				HEALER = "Curador",
				DAMAGER = "Tank|Causador de dano",
				ADD = "Adicionar Aura",					
				REMOVE = "Remover Aura",					
			},				
			[6] = {
				HEADBUTTON = "Cursor",
				HEADTITLE = "Interação com Mouse",
				USETITLE = "[Each spec] Configuração de Botões:",
				USELEFT = "Usar botão esquerdo",
				USELEFTTOOLTIP = "Este macro usa '/target mouseover' o que em si não é um click!\n\nRightClick: Criar macro",
				USERIGHT = "Usar botão direito",
				LUATOOLTIP = "Para se referir a unidade sendo checada, use 'thisunit' sem aspas\nSe usar LUA na Categoria 'GameToolTip' então thisunit não será valido\nCódigo deve ter um retorno booleano (true) para processar as condições\nEste código tem setfenv o que significa que você não precisa usar o Action para nada que o tenha\n\nSe quiser remover o código padrão você precisará escrever 'return true' sem aspas no lugar de remover tudo",							
				BUTTON = "Click",
				NAME = "Nome",
				LEFT = "Click Esquerdo",
				RIGHT = "Click Direito",
				ISTOTEM = "IsTotem",
				ISTOTEMTOOLTIP = "Se ativado então vai checar por @mouseover no tipo 'Totem' para o dado nome\nTambém previne a situação de o seu @target já ser um totem",				
				INPUTTITLE = "Digite o nome do objeto (localizado!)", 
				INPUT = "Este campo não é sensivel ao case",
				ADD = "Adicionar",
				REMOVE = "Remover",
				-- GlobalFactory default name preset in lower case!					
				SPIRITLINKTOTEM = "totem do vínculo do espirito",
				HEALINGTIDETOTEM = "totem da maré curativa",
				CAPACITORTOTEM = "totem capacitor",					
				SKYFURYTOTEM = "totem da furia do céu",					
				ANCESTRALPROTECTIONTOTEM = "totem da proteção ancestral",					
				COUNTERSTRIKETOTEM = "totem contragolpe",
				EXPLOSIVES = "explosives",
				WRATHGUARD = "guardião colérico",
				FELGUARD = "guarda vil",
				INFERNAL = "infernal",
				SHIVARRA = "shivarra",
				DOOMGUARD = "demonarca",
				FELHOUND = "canisvil",
				["UR'ZUL"] = "ur'zul",
				-- Optional totems
				TREMORTOTEM = "totem sísmico",
				GROUNDINGTOTEM = "totem de aterramento",
				WINDRUSHTOTEM = "totem de rajada de vento",
				EARTHBINDTOTEM = "totem de prisão terrena",
				-- GameToolTips
				ALLIANCEFLAG = "bandeira da aliança",
				HORDEFLAG = "bandeira da horda",
				NETHERSTORMFLAG = "bandeira de eternévoa",
				ORBOFPOWER = "orbe do poder",
			},
			[7] = {
				HEADBUTTON = "Mensagens",
				HEADTITLE = "Sistema de Mensagens",
				USETITLE = "[Each spec]",
				MSG = "Sistema de MSG",
				MSGTOOLTIP = "Marcado: funcionando\nDesmarcado: não funcionando\n\nRightClick: Criar macro",
				CHANNELS = "Canais",
				CHANNEL = "Canal ",			
				DISABLERETOGGLE = "Bloquear remover fila",
				DISABLERETOGGLETOOLTIP = "Prevenido devido remoções repetidas de mensagens do sistema de filas\nEx.: Possível macro de spam não sendo removido\n\nRightClick: Criar macro",
				MACRO = "Macro para seu grupo:",
				MACROTOOLTIP = "Isso é o que deve ser enviado para o chat de grupo para ativar a ação atribuida na tecla especificada\nPara atribuir a ação a uma unidade especifica, adicione as unidades para o macro ou deixe como está para a rotação de Alvo único/AoE\nSuportados: raid1-40, party1-4, player, arena1-5\nAPENAS UMA UNIDADE POR MENSAGEM!\n\nSeus companheiros também podem usar macros, mas tome cuidado, eles devem ser leais a isto!\nNÃO LIBERE A MACRO PARA PESSOAS QUE NÃO ESTÃO NO TEMA!",
				KEY = "Chave",
				KEYERROR = "Você não especificou uma chave!",
				KEYERRORNOEXIST = "Chave não existe!",
				KEYTOOLTIP = "Você precisa especificar uma tecla para vincular à action\nVocê pode extrair uma tecla na aba 'Actions'",
				MATCHERROR = "o nome passado já existe, use outro!",				
				SOURCE = "O nome da pessoa que disse",					
				WHOSAID = "Quem disse",
				SOURCETOOLTIP = "Isso é opcional. Você pode deixar em branco (recomendado)\nSe quiser configurar, o nome deve ser exatamente igual ao que está no chat de grupo",
				NAME = "Contém uma mensagem",
				ICON = "Icone",
				INPUT = "Digite uma frase para mensagem do sistema",
				INPUTTITLE = "Frase",
				INPUTERROR = "Você não forneceu uma frase!",
				INPUTTOOLTIP = "A frase será ativada em qualquer palavra no chat de grupo (/party) que está de acordo com a condição\nNão é case-sensitive\nContém padrões, isso significa que a frase escrita por alguém com a combinação das palavras raid, party, arena, player\nadapta a action para o dado slot\nVocê não precisa setar os padrões aqui, elas são usadas como adição ao macro\nSe o padrão não for encontrado, então os slots para rotações single e AoE serão utilizados",				
			},
			[8] = { 
				HEADBUTTON = "Sistema de Cura",
				OPTIONSPANEL = "Opções",
				OPTIONSPANELHELP = [[As definições desse painel afetam a 'Healing Engine' + 'Rotation'
									
									'Healing Engine' esse nome se refere ao sistema de seleção de @target 
									através do macro /target 'unitID'
									
									'Rotation' esse nome nós referimos às rotações de cura/dano para 
									a unidade primária atual (@target ou @mouseover)
									
									Algumas vezes você verá a mensagem 'o perfil deve conter o código para ele' o que significa que
									os recursos relacionados não funcionam sem códigos especiais a serem adicionados pelo autor 
									dentro dos trechos em LUA
									
									Cada elemento tem sua dica, então leia cuidadosamente, faça testes e se necessesário vá ao 
									'Campo de Testes' antes de você começar uma luta de verdade]],
				SELECTOPTIONS = "-- escolha as opções --",
				PREDICTOPTIONS = "Opções de Previsão",
				PREDICTOPTIONSTOOLTIP = "Suportados: 'Healing Engine' + 'Rotation' (o perfil deve ter o códigoo para isso)\n\nEssas opções afetam:\n1. Previsão de vida de membro do grupo para a seleção de @target ('Healing Engine')\n2. Cálculo de qual Ação de Cura será usada no @target/@mouseover ('Rotation')\n\nClique direito: Criar macro",
				INCOMINGHEAL = "Cura a ser recebida",
				INCOMINGDAMAGE = "Dano a ser recebido",
				THREATMENT = "Modo (PvE)",
				SELFHOTS = "HoTs", -- próprios
				ABSORBPOSSITIVE = "Absorver Positivo",
				ABSORBNEGATIVE = "Absorver Negativo",
				SELECTSTOPOPTIONS = "Opçõess de parar o alvo",
				SELECTSTOPOPTIONSTOOLTIP = "Suportados: 'Healing Engine'\n\nEssas opçõess afetam apenas a seleção de @target, e especificamente\nprevine a sua seleção se uma das opções é em-sucedida\n\nClique direito: Criar macro",
				SELECTSTOPOPTIONS1 = "@mouseover amigo",
				SELECTSTOPOPTIONS2 = "@mouseover inimigo",
				SELECTSTOPOPTIONS3 = "@target inimigo",
				SELECTSTOPOPTIONS4 = "@target boss",
				SELECTSTOPOPTIONS5 = "@player morto",
				SELECTSTOPOPTIONS6 = "sincronizar 'Rotação não funciona se'",
				SELECTSORTMETHOD = "Método de classificação do alvo",
				SELECTSORTMETHODTOOLTIP = "Suportados: 'Healing Engine'\n\n'Porcentagem de Vida' escolhe o @target com a menor porcentagem de vida\n'Vida Atual' escolhe o @target com menos vida especificada\n\nClique direito: Criar macro",
				SORTHP = "Porcentagem de Vida",
				SORTAHP = "Vida Atual",
				AFTERTARGETENEMYORBOSSDELAY = "Atraso de Alvo\nDepois do @target inimigo ou boss",
				AFTERTARGETENEMYORBOSSDELAYTOOLTIP = "Suportados: 'Healing Engine'\n\nAtraso (em segundos) antes de selecionar o próximo alvo após selecionar um inimigo ou boss ser selecionado @target\n\nFunciona apenas se 'Opções de parar o alvo' contém'@target inimigo' ou '@target boss' desligado\n\nAtraso é atualizado toda vez que as condições são bem-sucedidas, do contrário são resetadas\n\nClique direito: Criar macro",
				AFTERMOUSEOVERENEMYDELAY = "Atraso do Alvo\nApós @mouseover inimigo",
				AFTERMOUSEOVERENEMYDELAYTOOLTIP = "Suportados: 'Healing Engine'\n\nAtraso (em segundos) antes de selecionar o próximo alvo após selecionar um inimigo com @mouseover\n\nFunciona apenas se 'Opções de parar o alvo' contém '@mouseover inimigo' desligado\n\nAtraso é atualizado toda vez que as condições são bem-sucedidas, do contrário são resetadas\n\nClique direito: Criar macro",
				HEALINGENGINEAPI = "Ativar API do Healing Engine",
				HEALINGENGINEAPITOOLTIP = "Quando ativado, todas as opções e configurações suportadas do 'Healing Engine' funcionarão",
				SELECTPETS = "Ativar Familiares",
				SELECTPETSTOOLTIP = "Suportados: 'Healing Engine'\n\nTroca os pets para lidar com toda a API em 'Healing Engine'\n\nClique direito: Criar macro",  
				SELECTRESURRECTS = "Ativar Resurrects",
				SELECTRESURRECTSTOOLTIP = "Suportados: 'Healing Engine'\n\nAlterna os jogadores mortos para a seleção de @target\n\nFunciona apenas fora de combate\n\nClique direito: Criar macro",
				HELP = "Ajuda",
				HELPOK = "Entendi",
				ENABLED = "/tar", 
				ENABLEDTOOLTIP = "Suportados: 'Healing Engine'\n\nAlterna off/on '/target %s'",
				UNITID = "unitID",
				NAME = "Nome",
				ROLE = "Função",
				ROLETOOLTIP = "Suportados: 'Healing Engine'\n\nResponsável pela prioridade da seleção de @target, que é controlado pelos offsets\nPets são sempre 'Danos'",
				DAMAGER = "Dano",
				HEALER = "Healer",
				TANK = "Tank",
				UNKNOWN = "Desconhecido",
				USEDISPEL = "Dispel",
				USEDISPELTOOLTIP = "Suportados: 'Healing Engine' (o perfil deve ter o código para isso) + 'Rotation' (o perfil deve ter o código para isso)\n\n'Healing Engine': Permite o '/target %s' para dispel\n'Rotation': Permite o uso do dispel no '%s'\n\nLista de Dispels especificados na aba 'Auras'",
				USESHIELDS = "Shields",
				USESHIELDSTOOLTIP = "Suportados: 'Healing Engine' (o perfil deve ter o código para isso) + 'Rotation' (o perfil deve ter o código para isso)\n\n'Healing Engine': Permite o '/target %s' para shields\n'Rotation': Permite o uso de shields no '%s'",
				USEHOTS = "HoTs",
				USEHOTSTOOLTIP = "Suportados: 'Healing Engine' (o perfil deve ter o código para isso) + 'Rotation' (o perfil deve ter o código para isso)\n\n'Healing Engine': Permite o '/target %s' para HoTs\n'Rotation': Permite o uso de HoTs no '%s'",
				USEUTILS = "Utils",
				USEUTILSTOOLTIP = "Suportados: 'Healing Engine' (o perfil deve ter o código para isso) + 'Rotation' (o perfil deve ter o código para isso)\n\n'Healing Engine': Permite o '/target %s' para utils\n'Rotation': Permite o uso de utilidades no '%s'\n\nUtilidades significa ações suportads como Freedom, do paladino\n\nAlgumas delas podem ser especificadas na aba 'Auras'",
				GGLPROFILESTOOLTIP = "\n\nPerfis do GGL irão pular os pets para isso %s teto em 'Healing Engine'(seleção de @target)",
				LUATOOLTIP = "Suportados: 'Healing Engine'\n\nUsa o código que você escreveu como a última condição verificada antes '/target %s'",
				LUATOOLTIPADDITIONAL = "\n\nPara se referir aos dados metatable no 'thisunit' tal como a vida, use:\nlocal memberData = HealingEngine.Data.UnitIDs[thisunit]\nif memberData then Print(thisunit .. ' (' .. Unit(thisunit):Name() .. ')' .. ' has real health percent: ' .. memberData.realHP .. ' and modified: ' .. memberData.HP) end",
				AUTOHIDE = "Esconder auto",
				AUTOHIDETOOLTIP = "Isso é apenas um efeito visual!\nFiltra a lista automaticamente e mostra apenas as unitID disponíveis",
				PROFILES = "Perfis",
				PROFILESHELP = [[As definições nesse painel afetam 'Healing Engine' + 'Rotation'
								 
								 Cada perfil registra absolutamente todas as configurações da aba atual
								 Assim, você pode alterar o comportamento da seleção de alvos e da rotação de cura em tempo real
								 
								 Por exemplo: Você pode criar um perfil para trabalhar nos grupos 2 e 3 e o segundo 
								 durante toda a raid, e ao mesmo tempo, pode alterá-lo com uma macro, 
								 que também pode ser criada
								 
								 É importante entender que cada mudança feita nessa aba deve ser manualmente salva novamente
				]],
				PROFILE = "Perfil",
				PROFILEPLACEHOLDER = "-- nenhum perfil ou alterações não salvas no perfil anterior --",
				PROFILETOOLTIP = "Escreva o nome do novo perfil na caixa de texto abaixo e clique em 'Salvar'\n\nAs mudanças não serão salvas em tempo real!\nToda vez que você fizer qualquer mudança para salvá-las você deve clicar novamente em 'Salvar' para o perfil selecionado",
				PROFILELOADED = "Perfil carregado: ",
				PROFILESAVED = "Perfil salvo: ",
				PROFILEDELETED = "Perfil deletado: ",
				PROFILEERRORDB = "ActionDB não está nicializada!",
				PROFILEERRORNOTAHEALER = "Você deve ser um healer para usar isso!",
				PROFILEERRORINVALIDNAME = "Nome de perfil inválido!",
				PROFILEERROREMPTY = "Você não selecionou um perfil!",
				PROFILEWRITENAME = "Escreva o nome do perfil",
				PROFILESAVE = "Salvar",
				PROFILELOAD = "Carregar",
				PROFILEDELETE = "Deletar",
				CREATEMACRO = "Clique direito: Criar macro",
				PRIORITYHEALTH = "Prioridade de Vida",
				PRIORITYHELP = [[As definições desse painel afetam apenas a 'Healing Engine'

								 Ao usar essas definições, você pode alterar a prioridade 
								 de seleção de alvo dependendo das configurações
								 
								 As configurações mudam a vida virtual, permitindo 
								 que o método de classificação expanda as unidades de filtro não apenas  
								 de acordo com a opções de vida real + previsão

								 O método de classificação classifica todas as unidades por menos vida
								 
								 Multiplicador é um número pelo qual a vida será multiplicada
								 
								 Offset é um número que irá estabelecer uma porcentagem fixa ou 
								 processada aritmeticamente (-/+ HP) dependendo do 'Modo de Offset'
								 
								 'Utils' significa feitiços ofensivos tais como 'Benção da Liberdade'
				]],
				MULTIPLIERS = "Multiplicador",
				MULTIPLIERINCOMINGDAMAGELIMIT = "Limite de dano a ser recebido",
				MULTIPLIERINCOMINGDAMAGELIMITTOOLTIP = "Limita o dano a ser recebido em tempo real desde que o dano possa ser tão\ngrande que o sistema 'fica preso' no @target.\nColoque 1 se quiser um valor a não ser modificado\n\nClique direito: Criar macro",
				MULTIPLIERTHREAT = "Ameaça",
				MULTIPLIERTHREATTOOLTIP = "Processada se existir uma ameaça maior (exemplo: unidade está tankando)\nColoque 1 se quiser um valor a não ser modificado\n\nClique direito: Criar macro",
				MULTIPLIERPETSINCOMBAT = "Pets em Combate",
				MULTIPLIERPETSINCOMBATTOOLTIP = "Pets devem estar ativos para funcionar!\nColoque 1 se quiser um valor a não ser modificado\n\nClique direito: Criar macro",
				MULTIPLIERPETSOUTCOMBAT = "Pets fora de combate",
				MULTIPLIERPETSOUTCOMBATTOOLTIP = "Pets devem estar ativos para funcionar!\nColoque 1 se quiser um valor a não ser modificado\n\nClique direito: Criar macro",
				OFFSETS = "Offsets",
				OFFSETMODE = "Modo de Offset",
				OFFSETMODEFIXED = "Fixo",
				OFFSETMODEARITHMETIC = "Aritmético",
				OFFSETMODETOOLTIP = "'Fixo' irá estabelecer o mesmo valor exato que a porcentagem de vida\n'Aritmético' irá -/+ usar o valor de porcentagem de vida\n\nClique direito: Criar macro",
				OFFSETSELFFOCUSED = "Foco\npróprio (PvP)",
				OFFSETSELFFOCUSEDTOOLTIP = "Processado se os inimigos estão te alvejando no modo PvP\n\nClique direito: Criar macro",
				OFFSETSELFUNFOCUSED = "Sem Foco\npróprio (PvP)",
				OFFSETSELFUNFOCUSEDTOOLTIP = "Processado se os inimigos NÃO estão te alvejando no modo PvP\n\nClique direito: Criar macro",
				OFFSETSELFDISPEL = "Dispel próprio",
				OFFSETSELFDISPELTOOLTIP = "Os perfis da GGL normalmente possuem condições PvE para isso\n\nLista de dispels especificadas na aba 'Auras'\n\nClique direito: Criar macro",
				OFFSETHEALERS = "Healers",
				OFFSETTANKS = "Tanks",
				OFFSETDAMAGERS = "Danos",
				OFFSETHEALERSDISPEL = "Dispel de Healers",
				OFFSETHEALERSTOOLTIP = "Processado apenas nos outros healers\n\nLista de dispels especificadas na aba 'Auras'\n\nClique direito: Criar macro",
				OFFSETTANKSDISPEL = "Dispel de Tanks",
				OFFSETTANKSDISPELTOOLTIP = "Lista de dispels especificadas na aba 'Auras'\n\nClique direito: Criar macro",
				OFFSETDAMAGERSDISPEL = "Dispel dos danos",
				OFFSETDAMAGERSDISPELTOOLTIP = "Lista de dispels especificadas na aba 'Auras'\n\nClique direito: Criar macro",
				OFFSETHEALERSSHIELDS = "Shields dos Healers",
				OFFSETHEALERSSHIELDSTOOLTIP = "Inclui o próprio (@player)\n\nClique direito: Criar macro",
				OFFSETTANKSSHIELDS = "Shields dos Tanks",
				OFFSETDAMAGERSSHIELDS = "Shields do Danos",
				OFFSETHEALERSHOTS = "HoTs dos Healers",
				OFFSETHEALERSHOTSTOOLTIP = "Inclui o próprio (@player)\n\nClique direito: Criar macro",
				OFFSETTANKSHOTS = "HoTs dos Tanks",
				OFFSETDAMAGERSHOTS = "HoTs dos Danos",
				OFFSETHEALERSUTILS = "Utils dos Healers",
				OFFSETHEALERSUTILSTOOLTIP = "Inclui o próprio (@player)\n\nClique direito: Criar macro",
				OFFSETTANKSUTILS = "Utils dos Tanks",
				OFFSETDAMAGERSUTILS = "Utils dos Danos",
				MANAMANAGEMENT = "Gerenciador de Mana",
				MANAMANAGEMENTHELP = [[As definições desse painel afetam apenas 'Rotation'
									   
									   O perfil deve conter o código para isso! 
									   
									   Funciona se:
									   1. Dentro da instância
									   2. No modo PvE 
									   3. Em combate  
									   4. Tamanho do grupo >= 5
									   5. Contém boss(es) focados por membros
				]],
				MANAMANAGEMENTMANABOSS = "Sua Porcentagem de Mana <= Percentual de vida médio dos boss(es)",
				MANAMANAGEMENTMANABOSSTOOLTIP = "Começa a economizar mana se a condição é bem-sucedida\n\nA lógica depende do perfi que você usa!\n\nNem todos os perfis suportam essa configuração!\n\nClique direito: Criar macro",
				MANAMANAGEMENTSTOPATHP = "Para Gerenciamento\nPorcentagem de Vida",
				MANAMANAGEMENTSTOPATHPTOOLTIP = "Para de economizar mana se a unidade primária\n(@target/@mouseover) tem porcentagem de vida abaixo desse valor\n\nNem todos os perfis suportam essa configuração!\n\nClique direito: Criar macro",
				OR = "OU",
				MANAMANAGEMENTSTOPATTTD = "Para Gerenciamento\nTempo para morrer",
				MANAMANAGEMENTSTOPATTTDTOOLTIP = "Para de economizar mana se a unidade primária\n(@target/@mouseover) tem tempo para morrer (em segundos) abaixo desse valor\n\nNem todos os perfis suportam essa configuração!\n\nClique direito: Criar macro",
				MANAMANAGEMENTPREDICTVARIATION = "Eficácia da Conservação de Mana",
				MANAMANAGEMENTPREDICTVARIATIONTOOLTIP = "Afeta apenas as configurações das habilidades de cura 'AUTO'!\n\nEste é um multiplicador no qual a cura pura será calculada quando a fase de economia de mana foi iniciada\n\nQuanto maior o nível, mais economia de mana, mas menos APM\n\nClique direito: Criar macro",	
			},			
			[9] = {
				HEADBUTTON = "Atalhos",
				FRAMEWORK = "[Cada especialização] Estrutura",
				HOTKEYINSTRUCTION = "Pressione ou clique em qualquer tecla de atalho ou botão do mouse para atribuir",
				META = "Meta",
				METAENGINEROWTT = "Duplo clique esquerdo para atribuir o atalho\nDuplo clique direito para desatribuir o atalho",
				ACTION = "Ação",
				HOTKEY = "Atalho",
				HOTKEYASSIGN = "Criar",
				HOTKEYUNASSIGN = "Desvincular",
				ASSIGNINCOMBAT = "|cffff0000Não é possível atribuir em combate!",
				PRIORITIZEPASSIVE = "Priorizar rotação passiva",
				PRIORITIZEPASSIVETT = "Ativado: Rotação, Rotação Secundária farão primeiro a rotação passiva, depois a rotação nativa ao clicar\nDesativado: Rotação, Rotação Secundária farão primeiro a rotação nativa ao clicar, depois a rotação passiva ao soltar",
				CHECKSELFCAST = "Aplicar em si mesmo",
				CHECKSELFCASTTT = "Ativado: Se o modificador SELFCAST for mantido, nos botões de clique você será o alvo",
				UNITTT = "Ativa ou desativa os botões de clique para esta unidade na rotação passiva",
			},
		},
	},
}
do 
	local function CreateRoutineToENG(t, mirror)
		-- This need to prevent any text blanks caused by missed keys 
		for k, v in pairs(t) do 
			if k ~= "enUS" and type(v) == "table" then 
				local index = Localization[k] and mirror or mirror[k]
				setmetatable(v, { __index = index })
				CreateRoutineToENG(v, index)
			end 
		end 
	end 
	CreateRoutineToENG(Localization, Localization.enUS)
end 

function Action.GetLocalization()
	-- @return table localized with current language of interface 
	CL 	= gActionDB and Localization[gActionDB.InterfaceLanguage] and gActionDB.InterfaceLanguage or next(Localization[GameLocale]) and GameLocale or "enUS"
	L 	= Localization[CL]
	return L
end 

function Action.GetCL()
	-- @return string (Current locale language of the UI)
	return CL 
end 

-------------------------------------------------------------------------------
-- DB: Database
-------------------------------------------------------------------------------
Action.Const 	= {}
Action.Enum 	= {}
Action.Data 	= {	
	ProfileUI = {},
	ProfileDB = {},
	ProfileEnabled = {
		["[GGL] Test"] 		= false,
		["[GGL] Template"] 	= false,
	},
	DefaultProfile = {
		["WARRIOR"] 		= "[GGL] Warrior",
		["PALADIN"] 		= "[GGL] Paladin",
		["HUNTER"] 			= "[GGL] Hunter",
		["ROGUE"] 			= "[GGL] Rogue",
		["PRIEST"] 			= "[GGL] Priest",
		["SHAMAN"] 			= "[GGL] Shaman",
		["MAGE"] 			= "[GGL] Mage",
		["WARLOCK"] 		= "[GGL] Warlock",
		["MONK"] 			= "[GGL] Monk",
		["DRUID"] 			= "[GGL] Druid",
		["DEATHKNIGHT"] 	= "[GGL] Death Knight",
		["DEMONHUNTER"] 	= "[GGL] Demon Hunter",
		["BASIC"]			= "[GGL] Basic",
	},
	-- UI template config  
	theme = {
		off 				= "|cffff0000OFF|r",
		on 					= "|cff00ff00ON|r",
		dd = {
			width 			= 125,
			height 			= 25,
		},
	},
	-- Color
    C = {
		-- Standart 
        ["GREEN"] 			= "ff00ff00",
        ["RED"] 			= "ffff0000d",
        ["BLUE"] 			= "ff0900ffd",        
        ["YELLOW"]	 		= "ffffff00d",
        ["PINK"] 			= "ffff00ffd",
        ["LIGHT BLUE"] 		= "ff00ffffd",
		-- Nicely
		["LIGHTRED"]        = "ffff6060d",
		["TORQUISEBLUE"]	= "ff00C78Cd",
		["SPRINGGREEN"]	  	= "ff00FF7Fd",
		["GREENYELLOW"]   	= "ffADFF2Fd",
		["PURPLE"]		    = "ffDA70D6d",
		["GOLD"]            = "ffffcc00d",
		["GOLD2"]			= "ffFFC125d",
		["GREY"]            = "ff888888d",
		["WHITE"]           = "ffffffffd",
		["SUBWHITE"]        = "ffbbbbbbd",
		["MAGENTA"]         = "ffff00ffd",
		["ORANGEY"]		    = "ffFF4500d",
		["CHOCOLATE"]		= "ffCD661Dd",
		["CYAN"]            = "ff00ffffd",
		["IVORY"]			= "ff8B8B83d",
		["LIGHTYELLOW"]	    = "ffFFFFE0d",
		["SEXGREEN"]		= "ff71C671d",
		["SEXTEAL"]		    = "ff388E8Ed",
		["SEXPINK"]		    = "ffC67171d",
		["SEXBLUE"]		    = "ff00E5EEd",
		["SEXHOTPINK"]	    = "ffFF6EB4d",		
    },
   	-- Universal Color
	UC = {
		[""] = function() return 0, 0, 0, 1.0 end,
		[0] = function() return 0, 0, 0, 1.0 end,
		[1] = function() return 0.192157, 0.878431, 0.015686, 1.0 end,
		[2] = function() return 0.780392, 0.788235, 0.745098, 1.0 end,
		[3] = function() return 0.498039, 0.184314, 0.521569, 1.0 end,
		[4] = function() return 0.627451, 0.905882, 0.882353, 1.0 end,
		[5] = function() return 0.145098, 0.658824, 0.121569, 1.0 end,
		[6] = function() return 0.639216, 0.490196, 0.921569, 1.0 end,
		[7] = function() return 0.172549, 0.368627, 0.427451, 1.0 end,
		[8] = function() return 0.949020, 0.333333, 0.980392, 1.0 end,
		[9] = function() return 0.109804, 0.388235, 0.980392, 1.0 end,
		[10] = function() return 0.615686, 0.694118, 0.435294, 1.0 end,
		[11] = function() return 0.066667, 0.243137, 0.572549, 1.0 end,
		[12] = function() return 0.113725, 0.129412, 1.000000, 1.0 end,
		[13] = function() return 0.592157, 0.023529, 0.235294, 1.0 end,
		[14] = function() return 0.545098, 0.439216, 1.000000, 1.0 end,
		[15] = function() return 0.890196, 0.800000, 0.854902, 1.0 end,
		[16] = function() return 0.513725, 0.854902, 0.639216, 1.0 end,
		[17] = function() return 0.078431, 0.541176, 0.815686, 1.0 end,
		[18] = function() return 0.109804, 0.184314, 0.666667, 1.0 end,
		[19] = function() return 0.650980, 0.572549, 0.098039, 1.0 end,
		[20] = function() return 0.541176, 0.466667, 0.027451, 1.0 end,	
		[21] = function() return 0.000000, 0.988235, 0.462745, 1.0 end,	
		[22] = function() return 0.211765, 0.443137, 0.858824, 1.0 end,	
		[23] = function() return 0.949020, 0.949020, 0.576471, 1.0 end,	
		[24] = function() return 0.972549, 0.800000, 0.682353, 1.0 end,	
		[25] = function() return 0.031373, 0.619608, 0.596078, 1.0 end,	
		[26] = function() return 0.670588, 0.925490, 0.513725, 1.0 end,	
		[27] = function() return 0.647059, 0.945098, 0.031373, 1.0 end,	
		[28] = function() return 0.058824, 0.490196, 0.054902, 1.0 end,	
		[29] = function() return 0.050980, 0.992157, 0.239216, 1.0 end,	
		[30] = function() return 0.949020, 0.721569, 0.388235, 1.0 end,	
		[31] = function() return 0.254902, 0.749020, 0.627451, 1.0 end,	
		[32] = function() return 0.470588, 0.454902, 0.603922, 1.0 end,	
		[33] = function() return 0.384314, 0.062745, 0.266667, 1.0 end,	
		[34] = function() return 0.639216, 0.168627, 0.447059, 1.0 end,	
		[35] = function() return 0.874510, 0.058824, 0.400000, 1.0 end,	
		[36] = function() return 0.925490, 0.070588, 0.713725, 1.0 end,	
		[37] = function() return 0.098039, 0.803922, 0.905882, 1.0 end,	
		[38] = function() return 0.243137, 0.015686, 0.325490, 1.0 end,	
		[39] = function() return 0.847059, 0.376471, 0.921569, 1.0 end,	
		[40] = function() return 0.341176, 0.533333, 0.231373, 1.0 end,	
		[41] = function() return 0.345098, 0.239216, 0.741176, 1.0 end,	
		[42] = function() return 0.407843, 0.501961, 0.086275, 1.0 end,	
		[43] = function() return 0.160784, 0.470588, 0.164706, 1.0 end,	
		[44] = function() return 0.725490, 0.572549, 0.647059, 1.0 end,	
		[45] = function() return 0.788235, 0.470588, 0.858824, 1.0 end,	
		[46] = function() return 0.615686, 0.227451, 0.988235, 1.0 end,	
		[47] = function() return 0.486275, 0.176471, 1.000000, 1.0 end,	
		[48] = function() return 0.031373, 0.572549, 0.152941, 1.0 end,	
		[49] = function() return 0.874510, 0.239216, 0.239216, 1.0 end,	
		[50] = function() return 0.117647, 0.870588, 0.635294, 1.0 end,	
		[51] = function() return 0.458824, 0.945098, 0.784314, 1.0 end,	
		[52] = function() return 0.239216, 0.654902, 0.278431, 1.0 end,	
		[53] = function() return 0.537255, 0.066667, 0.905882, 1.0 end,	
		[54] = function() return 0.333333, 0.415686, 0.627451, 1.0 end,	
		[55] = function() return 0.576471, 0.811765, 0.011765, 1.0 end,	
		[56] = function() return 0.517647, 0.164706, 0.627451, 1.0 end,	
		[57] = function() return 0.439216, 0.074510, 0.941176, 1.0 end,	
		[58] = function() return 0.984314, 0.854902, 0.376471, 1.0 end,	
		[59] = function() return 0.082353, 0.286275, 0.890196, 1.0 end,	
		[60] = function() return 0.058824, 0.003922, 0.964706, 1.0 end,	
		[61] = function() return 0.956863, 0.509804, 0.949020, 1.0 end,	
		[62] = function() return 0.474510, 0.858824, 0.031373, 1.0 end,	
		[63] = function() return 0.509804, 0.882353, 0.423529, 1.0 end,	
		[64] = function() return 0.337255, 0.647059, 0.427451, 1.0 end,	
		[65] = function() return 0.611765, 0.525490, 0.352941, 1.0 end,	
		[66] = function() return 0.921569, 0.129412, 0.913725, 1.0 end,	
		[67] = function() return 0.117647, 0.933333, 0.862745, 1.0 end,	
		[68] = function() return 0.733333, 0.015686, 0.937255, 1.0 end,	
		[69] = function() return 0.819608, 0.392157, 0.686275, 1.0 end,	
		[70] = function() return 0.823529, 0.976471, 0.541176, 1.0 end,	
		[71] = function() return 0.043137, 0.305882, 0.800000, 1.0 end,	
		[72] = function() return 0.737255, 0.270588, 0.760784, 1.0 end,	
		[73] = function() return 0.807843, 0.368627, 0.058824, 1.0 end,	
		[74] = function() return 0.364706, 0.078431, 0.078431, 1.0 end,	
		[75] = function() return 0.094118, 0.901961, 1.000000, 1.0 end,	
		[76] = function() return 0.772549, 0.690196, 0.047059, 1.0 end,	
		[77] = function() return 0.415686, 0.784314, 0.854902, 1.0 end,	
		[78] = function() return 0.470588, 0.733333, 0.047059, 1.0 end,	
		[79] = function() return 0.619608, 0.086275, 0.572549, 1.0 end,	
		[80] = function() return 0.517647, 0.352941, 0.678431, 1.0 end,	
		[81] = function() return 0.003922, 0.149020, 0.694118, 1.0 end,	
		[82] = function() return 0.454902, 0.619608, 0.831373, 1.0 end,	
		[83] = function() return 0.674510, 0.741176, 0.050980, 1.0 end,	
		[84] = function() return 0.560784, 0.713725, 0.784314, 1.0 end,	
		[85] = function() return 0.400000, 0.721569, 0.737255, 1.0 end,	
		[86] = function() return 0.094118, 0.274510, 0.392157, 1.0 end,	
		[87] = function() return 0.298039, 0.498039, 0.462745, 1.0 end,	
		[88] = function() return 0.125490, 0.196078, 0.027451, 1.0 end,	
		[89] = function() return 0.937255, 0.564706, 0.368627, 1.0 end,	
		[90] = function() return 0.929412, 0.592157, 0.501961, 1.0 end,	
		-- Reserved 
		[91] = function() return 0.411765, 0.760784, 0.176471, 1.0 end,	
		[92] = function() return 0.780392, 0.286275, 0.415686, 1.0 end,	
		[93] = function() return 0.584314, 0.811765, 0.956863, 1.0 end,	
		[94] = function() return 0.513725, 0.658824, 0.650980, 1.0 end,	
		[95] = function() return 0.913725, 0.180392, 0.737255, 1.0 end,	
		[96] = function() return 0.576471, 0.250980, 0.160784, 1.0 end,	
		[97] = function() return 0.803922, 0.741176, 0.874510, 1.0 end,	
		[98] = function() return 0.647059, 0.874510, 0.713725, 1.0 end,	
		[99] = function() return 0.007843, 0.301961, 0.388235, 1.0 end,	
		[100] = function() return 0.572549, 0.705882, 0.984314, 1.0 end,	
	}, 
	-- Queue List
    Q = {},
	-- Timers
	T = {},
	-- Toggle Cache 
	TG = {},	
	-- Auras 
	Auras = {},
	-- Print Cache 
	PrintCache = {},
}

local ActionConst													= Action.Const
local ActionData 													= Action.Data 
local ActionDataQ 													= ActionData.Q
local ActionDataT 													= ActionData.T
local ActionDataTG													= ActionData.TG
local ActionDataAuras												= ActionData.Auras
local ActionDataPrintCache											= ActionData.PrintCache
local ActionHasRunningDB, ActionHasFinishedLoading

-- Pack constants
do 
	for constant, v in pairs(_G) do 
		if type(constant) == "string" and constant:match("ACTION_CONST_") then 
			ActionConst[constant:gsub("ACTION_CONST_", "")] = v
		end 
	end 
end 

-- Templates
-- Important: Default LUA overwrite problem was fixed by additional LUAVER key, however [3] "QLUA" and "LUA" was leaved and only 'Reset Settings' can clear it 
function StdUi:tGenerateMinMax(t, min1, min2, addmax, isfixedmax)
	t.Min = math_random(min1, min2)
	if isfixedmax then 
		t.Max = addmax
	else 
		t.Max = math_max(math_random(t.Min, t.Min + addmax), t.Min + 17)
	end 
	return t  
end 

function StdUi:tGenerateHealingEngineUnitIDs(optionsTable)
	local t = {}
	
	local unitID
	for _, unit in ipairs({ "focus", "player", "pet", "party", "raid", "partypet", "raidpet" }) do 
		if unit:match("raid") then 			
			for i = 1, 40 do 
				unitID = unit .. i
				t[unitID] = CopyTable(optionsTable)
				
				if optionsTable.Role and unitID:match("pet") then 
					t[unitID].isPet = true
				end
			end 
		elseif unit:match("party") then 
			for i = 1, 4 do 
				unitID = unit .. i
				t[unitID] = CopyTable(optionsTable)
				
				if optionsTable.Role and unitID:match("pet") then 
					t[unitID].isPet = true
				end
			end 
		else
			t[unit] = CopyTable(optionsTable)
			
			if optionsTable.Role and unit:match("pet") then 
				t[unit].isPet = true
			end
		end 				
	end 
	
	return t 
end 

-- pActionDB DefaultBase
local Factory = {
	-- Special keys: 
	-- PLAYERSPEC 		will convert to available spec on character 
	-- ISINTERRUPT 		will swap ID to locale Name as key and create formated table 
	-- ISCURSOR 		will swap key localized Name from Localization table and create formated table 
	[1] = {		
		AntiFakePauses = {
			[1] = false,
			[2] = false,
			[3] = false,
			[4] = false,
			[5] = false,
			[6] = false,
		},		
		CheckVehicle = true, 
		CheckDeadOrGhost = true, 
		CheckDeadOrGhostTarget = false,
		CheckMount = false, 
		CheckCombat = false, 
		CheckSpellIsTargeting = true, 
		CheckLootFrame = true, 	
		CheckEatingOrDrinking = true,
		DisableRotationDisplay = false,
		DisableBlackBackground = false,
		DisablePrint = false,
		DisableMinimap = false,
		DisableClassPortraits = false,
		DisableRotationModes = false,
		DisableSounds = true,
		DisableAddonsCheck = false,
		HideOnScreenshot = true,	
		CVars = {
			[1] = true, 	-- "Contrast"
			[2] = true, 	-- "Brightness"
			[3] = true, 	-- "Gamma"
			[4] = true, 	-- "colorblindsimulator"
			[5] = true, 	-- "colorblindWeaknessFactor"
			[6] = true, 	-- "SpellQueueWindow"
			[7] = true, 	-- "doNotFlashLowHealthWarning"
			[8] = true, 	-- "nameplateMaxDistance"
			[9] = true, 	-- "nameplateNotSelectedAlpha"
			[10] = true, 	-- "nameplateOccludedAlphaMult"
			[11] = true, 	-- "breakUpLargeNumbers"
			[12] = true, 	-- "screenshotQuality"
			[13] = true, 	-- "nameplateShowEnemies"
			[14] = true, 	-- "autoSelfCast"
		},
		ColorPickerUse = false,
		ColorPickerElement = "backdrop",
		ColorPickerOption = "panel",
		ColorPickerConfig = { 
			-- All tables must be empty
			font = {
				color = {
					normal = {},
					disabled = {},
					header = {},
					subtitle = {}, 	-- custom (not implement in StdUi)
					tooltip = {},	-- custom (not implement in StdUi)
				},
			},
			backdrop = {
				panel = {},
				slider = {},
				highlight = {},
				button = {},
				buttonDisabled = {},
				border = {},
				borderDisabled = {},
			},
			progressBar = {
				color = {},					
			},
			highlight = {
				color = {},
				blank = {},
			},
		},					
		PLAYERSPEC = {			
			AutoTarget = true, 
			Potion = true, 
			HeartOfAzeroth = true, 	-- Leave it just for work on old expansion (8.2-8.3.7)
			Covenant = true,		-- Shadowlands 
			Racial = true,	
			StopCast = true,
			AutoShoot = true,
			AutoAttack = true, 			
			BossMods = true,
			LOSCheck = true, 
			StopAtBreakAble = false,			
			FPS = -0.01, 	
			Trinkets = {
				[1] = true, 
				[2] = true, 
			},
			Burst = "Auto",
			HealthStone = 20, 
			ReFocus = true, 
			ReTarget = true, 			
		},
	}, 
	[2]	= {
		-- Shadowlands Covenant
		PLAYERSPEC = {	
			FleshcraftHP = 40,
			FleshcraftOperator = "AND",
			FleshcraftTTD = 15,
			PhialofSerenityHP = 25,
			PhialofSerenityOperator = "AND",
			PhialofSerenityTTD = 6,
			PhialofSerenityDispel = true,
		},
	},
	[3] = {			
		AutoHidden = true,
		CheckSpellLevel = true,
		LastDisableName = "",
		PLAYERSPEC = {			
			disabledActions = {},
			luaActions = {},
			QluaActions = {},
			macroActions = {},
		},
	},
	[4] = {
		-- Category
		BlackList = {
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		},
		MainPvE = StdUi:tGenerateMinMax({
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		}, 13, 37, 45),
		MousePvE = StdUi:tGenerateMinMax({
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		}, 13, 37, 45),
		MainPvP = StdUi:tGenerateMinMax({
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		}, 17, 37, 55),
		MousePvP = StdUi:tGenerateMinMax({
			[GameLocale] = {
				ISINTERRUPT = true,
			},	
		}, 17, 37, 55),
		Heal = StdUi:tGenerateMinMax({
			[GameLocale] = {	
				ISINTERRUPT = true,
				-- Priest
				[47540] = "Penance",
				[596] = "Prayer of Healing",
				[2060] = "Heal",
				[2061] = "Flash Heal",
				[33076] = "Prayer of Mending",
				[64843] = "Divine Hymn",
				[120517] = "Halo",
				[194509] = "Power Word: Radiance",
				[265202] = "Holy Word: Salvation",
				[289666] = "Greater Heal",
				-- Druid
				[740] = "Tranquility",
				[8936] = "Regrowth",
				[289022] = "Nourish",
				[48438] = "Wild Growth",
				-- Shaman
				[8004] = "Healing Surge",
				[1064] = "Chain Heal",
				[73920] = "Healing Rain",
				[77472] = "Healing Wave",
				[197995] = "Wellspring",
				[207778] = "Downpour",
				-- Paladin
				[19750] = "Flash of Light",
				[82326] = "Holy Light",
				-- Monk
				[116670] = "Vivify",
				[124682] = "Enveloping Mist",
				[227344] = "Surging Mist",
				[115175] = "Soothing Mist",	
			},			
		}, 43, 70, math_random(87, 95), true),
		PvP = StdUi:tGenerateMinMax({
			[GameLocale] = {
				ISINTERRUPT = true,
				[113724] = "Ring of Frost",
				[118] = "Pollymorph",
				[605] = "Mind Control",
				[982] = "Revive pet",
				[5782] = "Fear",
				[20066] = "Repitance",
				[51514] = "Hex",
				[33786] = "Cyclone",
				[32375] = "Mass dispel",				
				[12051] = "Evocation",
				[20484] = "Rebirth",
				-- On choice
				[258925] = "Fel Barrage",
				[198013] = "Eye Beam",
				[339] = "Roots",
			},	
		}, 34, 58, 37),	
		-- Checkbox 
		PLAYERSPEC = {
			-- Checkbox 
			UseMain 		= true,
			UseMouse 		= true, 			
			UseHeal 		= true, 
			UsePvP			= true,
			-- Sub-Checkbox (below Checkbox i.e. additional conditions)
			MainAuto		= true,
			MouseAuto 		= true,
			HealOnlyHealers = true,
			PvPOnlySmart 	= true,
		},
	},
	[5] = {
		PLAYERSPEC = {
			UseDispel = true,			
			UsePurge = true,
			UseExpelEnrage = true,
			-- DispelPurgeEnrageRemap func will push needed keys here 
		},
	},
	[6] = {
		PLAYERSPEC = {
			UseLeft = true,
			UseRight = true,
			PvE = {
				UnitName = {
					[GameLocale] = {
						ISCURSOR = true,
						[Localization[GameLocale]["TAB"][6]["EXPLOSIVES"]] 					= { isTotem = true,  Button = "LEFT", LUA = [[return InstanceInfo.KeyStone and InstanceInfo.KeyStone >= 7]], LUAVER = 1 },
						[Localization[GameLocale]["TAB"][6]["WRATHGUARD"]] 					= { isTotem = false, Button = "LEFT", LUA = [[return Unit(thisunit):IsCondemnedDemon()]], LUAVER = 1 },
						[Localization[GameLocale]["TAB"][6]["FELGUARD"]] 					= { isTotem = false, Button = "LEFT", LUA = [[return Unit(thisunit):IsCondemnedDemon()]], LUAVER = 1 },
						[Localization[GameLocale]["TAB"][6]["INFERNAL"]] 					= { isTotem = false, Button = "LEFT", LUA = [[return Unit(thisunit):IsCondemnedDemon()]], LUAVER = 1 },
						[Localization[GameLocale]["TAB"][6]["SHIVARRA"]] 					= { isTotem = false, Button = "LEFT", LUA = [[return Unit(thisunit):IsCondemnedDemon()]], LUAVER = 1 },
						[Localization[GameLocale]["TAB"][6]["DOOMGUARD"]] 					= { isTotem = false, Button = "LEFT", LUA = [[return Unit(thisunit):IsCondemnedDemon()]], LUAVER = 1 },
						[Localization[GameLocale]["TAB"][6]["FELHOUND"]] 					= { isTotem = false, Button = "LEFT", LUA = [[return Unit(thisunit):IsCondemnedDemon()]], LUAVER = 1 },
						[Localization[GameLocale]["TAB"][6]["UR'ZUL"]] 						= { isTotem = false, Button = "LEFT", LUA = [[return Unit(thisunit):IsCondemnedDemon()]], LUAVER = 1 },
					},
				},
				GameToolTip = {
					[GameLocale] = {
						ISCURSOR = true,
					},
				},
				UI = {
					[GameLocale] = {
						ISCURSOR = true,
					},
				},
			},
			PvP = {
				UnitName = {
					[GameLocale] = {
						ISCURSOR = true,
						[Localization[GameLocale]["TAB"][6]["SPIRITLINKTOTEM"]] 			= { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["HEALINGTIDETOTEM"]] 			= { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["CAPACITORTOTEM"]] 				= { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["SKYFURYTOTEM"]] 				= { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["ANCESTRALPROTECTIONTOTEM"]] 	= { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["COUNTERSTRIKETOTEM"]] 			= { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["TREMORTOTEM"]] 				= { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["GROUNDINGTOTEM"]] 				= { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["WINDRUSHTOTEM"]] 				= { isTotem = true, Button = "LEFT" },
						[Localization[GameLocale]["TAB"][6]["EARTHBINDTOTEM"]] 				= { isTotem = true, Button = "LEFT" },
						-- TODO: Add Shadowlands "Vesper Totem"
					}, 
				},
				GameToolTip = {
					[GameLocale] = {
						ISCURSOR = true,
						[Localization[GameLocale]["TAB"][6]["ALLIANCEFLAG"]] 				= { Button = "RIGHT" },
						[Localization[GameLocale]["TAB"][6]["HORDEFLAG"]] 					= { Button = "RIGHT" },
						[Localization[GameLocale]["TAB"][6]["NETHERSTORMFLAG"]] 			= { Button = "RIGHT" },
						[Localization[GameLocale]["TAB"][6]["ORBOFPOWER"]] 					= { Button = "RIGHT" },
					},
				},
				UI = {
					[GameLocale] = {
						ISCURSOR = true,
					},
				},
			},
		},
	},
	[7] = {
		PLAYERSPEC = {
			Channels = { 
				[1] = false, 	-- whisper
				[2] = true, 	-- party
				[3] = true, 	-- raid
			}, 
			DisableReToggle = false,
			msgList = {},
		},
	},
	[8] = {
		PLAYERSPEC = {
			PredictOptions = {
				[1] = true, 	-- Incoming heal 
				[2] = true,		-- Incoming damage 
				[3] = true, 	-- Threatment (PvE)
				[4] = true, 	-- HoTs
				[5] = false, 	-- Absorb Possitive
				[6] = true, 	-- Absorb Negative				
			},
			SelectStopOptions = {
				-- Classic: true, otherwise false means /focus healing
				[1] = BuildToC < 20000,  -- @mouseover friendly 
				[2] = BuildToC < 20000,  -- @mouseover enemy 
				[3] = BuildToC < 20000,  -- @target enemy 
				[4] = BuildToC < 20000,  -- @target boss 
				[5] = BuildToC < 20000,  -- @player dead 
				[6]	= false, -- sync-up "Rotation doesn't work if"
			},
			SelectSortMethod = "HP",	
			AfterTargetEnemyOrBossDelay = 0,	-- SelectStopOptions must be off for: [3] @target enemy or [4] @target boss
			AfterMouseoverEnemyDelay = 0,		-- SelectStopOptions must be off for: [2] @mouseover enemy 
			HealingEngineAPI = true,
			SelectPets = true,
			SelectResurrects = true, 			-- Classic Druids haven't it.. 
			UnitIDs = StdUi:tGenerateHealingEngineUnitIDs({ Enabled = true, Role = "AUTO", useDispel = true, useShields = true, useHoTs = true, useUtils = true, LUA = "" }), 
			AutoHide = true,
			Profile = "",
			Profiles = {
				--[[
					["profileName"] = {
						-- Contain the copy of all this except Profiles table and Profile key 
					},
				]]
			},
			-- Multipliers
			MultiplierIncomingDamageLimit = 0.15,
			MultiplierThreat = 0.95,
			MultiplierPetsInCombat = 1.35,
			MultiplierPetsOutCombat = 1.15,

			-- Offsets 
			OffsetMode = "FIXED",
			
			OffsetSelfFocused = 0,
			OffsetSelfUnfocused = 0,
			OffsetSelfDispel = 0,
			
			OffsetHealers = 0,
			OffsetHealersDispel = 0,
			OffsetHealersShields = 0,
			OffsetHealersHoTs = 0,
			OffsetHealersUtils = 0,
			
			OffsetTanks = 0,
			OffsetTanksDispel = 0,
			OffsetTanksShields = 0,
			OffsetTanksHoTs = 0,
			OffsetTanksUtils = 0,
			
			OffsetDamagers = 0,						
			OffsetDamagersDispel = 0,						
			OffsetDamagersShields = 0,						
			OffsetDamagersHoTs = 0,
			OffsetDamagersUtils = 0,	

			-- Mana Management
			ManaManagementManaBoss = 30,
			ManaManagementStopAtHP = 40,
			ManaManagementStopAtTTD = 6,
			ManaManagementPredictVariation = 4,
		},
	},
	[9] = {
		PLAYERSPEC = {
			Framework = "MetaEngine",
			MetaEngine = {
				Hotkeys = {
					[1] 							= { meta = 1,  action = "AntiFake CC", 					hotkey = "" },
					[2] 							= { meta = 2,  action = "AntiFake Interrupt", 			hotkey = "" },
					[3] 							= { meta = 3,  action = "Rotation", 					hotkey = "" },
					[4]								= { meta = 4,  action = "Secondary Rotation", 			hotkey = "" },
					[5] 							= { meta = 5,  action = "Trinket Rotation", 			hotkey = "" },
					[7] 							= { meta = 7,  action = "AntiFake CC Focus", 			hotkey = "" },
					[8] 							= { meta = 8,  action = "AntiFake Interrupt Focus", 	hotkey = "" },
					[9] 							= { meta = 9,  action = "AntiFake CC2", 				hotkey = "" },
					[10] 							= { meta = 10, action = "AntiFake CC2 Focus", 			hotkey = "" },
				},
				PrioritizePassive = true,
				checkselfcast = false,
				raid = true,
				party = true,
				arena = true,
			},
		},
	},
}; StdUi.Factory = Factory

-- gActionDB DefaultBase
local GlobalFactory = {	
	InterfaceLanguage = "Auto",	
	minimap = {},
	[5] = {		
		PvE = {
			BlackList = {},
			PurgeFriendly = {
				-- Mind Control (it's buff)
				[605] = { canStealOrPurge = true },
				-- Seduction
				[270920] = { canStealOrPurge = true, LUAVER = 2, LUA = [[ -- Don't purge if we're Mage
				return PlayerClass ~= "MAGE" ]] },
			},
			PurgeHigh = {
				-- 8.2 Mechagon: Defensive Countermeasure
				[297133] = { canStealOrPurge = true, byID = true },	
				-- 8.2 Mechagon: Enlarge
				[301629] = { canStealOrPurge = true, dur = 3, byID = true },	
				-- 8.1 Dungeon: Bone Shield
				[266201] = { canStealOrPurge = true, byID = true },	
				-- 8.1 Dungeon: Swiftness
				[276265] = { canStealOrPurge = true, stack = 3, byID = true },	
				-- 8.0.1 Dungeon: Reanimated Bones
				[274210] = { canStealOrPurge = true, byID = true },					
				-- 8.0.1 Dungeon: Detect Thoughts
				[268375] = { canStealOrPurge = true, byID = true },	
				-- 8.0.1 Dungeon: Earth Shield
				[268709] = { canStealOrPurge = true, byID = true },	
				-- Gilded Claws
				[255579] = { canStealOrPurge = true, dur = 7 },		
				-- Gathered Souls
				[254974] = { canStealOrPurge = true },
				-- Healing Balm
				[257397] = { canStealOrPurge = true },
				-- Bound by Shadow
				[269935] = { canStealOrPurge = true, LUAVER = 2, LUA = [[ -- Don't purge if we're Mage
				return PlayerClass ~= "MAGE" ]] },
				-- Induce Regeneration
				[270901] = { canStealOrPurge = true, dur = 7 },
				-- Tidal Surge
				[267977] = { canStealOrPurge = true, dur = 10, LUAVER = 2, LUA = [[ -- Only if we're Mage
				return PlayerClass == "MAGE" ]] },
				-- Mending Rapids
				[268030] = { canStealOrPurge = true, dur = 4 },
				-- Watertight Shell
				[256957] = { canStealOrPurge = true },
				-- Bolstering Shout
				[275826] = { canStealOrPurge = true, dur = 2 },
				-- Electrified Scales
				[272659] = { canStealOrPurge = true, dur = 2 },
				-- Embryonic Vigor
				[269896] = { canStealOrPurge = true },
				-- Accumulate Charge
				[265912] = { canStealOrPurge = true, stack = 3 },
				-- Tectonic Barrier
				[263215] = { canStealOrPurge = true },
				-- Azerite Injection
				[262947] = { canStealOrPurge = true },
				-- Overcharge
				[262540] = { canStealOrPurge = true },
				-- Watery Dome
				[258153] = { canStealOrPurge = true },
				-- Gift of G'huun
				[265091] = { canStealOrPurge = true },
				-- Soul Fetish
				[278551] = { canStealOrPurge = true },				
				-- Mythic: Arcane Blitz
				[197797] = { canStealOrPurge = true, dur = 3 },
				-- Unstable Flux
				[210662] = { canStealOrPurge = true, dur = 3 },
				-- Brand of the Legion
				[211632] = { canStealOrPurge = true, dur = 3 },
				-- Fortification
				[209033] = { canStealOrPurge = true, dur = 3 },
				-- Protective Light
				[198745] = { canStealOrPurge = true, dur = 3 },
				-- Sea Legs
				[194615] = { canStealOrPurge = true, dur = 1 },
				-- Gift of Wind
				[282098] = { canStealOrPurge = true, dur = 1 },					
			},
			PurgeLow = {
				-- 8.0.1 Tol Dagor: Inner Flames
				[258938] = { canStealOrPurge = true, byID = true },	
				-- Dino Might
				[256849] = { canStealOrPurge = true },
				-- Induce Regeneration
				[270901] = { canStealOrPurge = true },
				-- Tidal Surge
				[267977] = { canStealOrPurge = true, dur = 3, LUAVER = 2, LUA = [[ -- Only if we're Mage
				return PlayerClass == "MAGE" ]] },
				-- Consuming Void
				[276767] = { canStealOrPurge = true },
				-- Spirited Defense
				[265368] = { canStealOrPurge = true },
			},
			Poison = {
				-- 8.3 Heartpiercer Venom
				[316506] = { byID = true, dur = 0.5 },
				-- 8.3 Mind-Numbing Toxin
				[314593] = { byID = true },
				-- 8.3 Volatile Rupture
				[314467] = { byID = true, dur = 1.49 },
				-- Venomfang Strike
				[252687] = {},
				-- Poisoning Strike
				[257436] = { stack = 3 },
				-- Hidden Blade
				[270865] = {},
				-- Embalming Fluid 
				[271564] = { stack = 3 },
				-- Poison Barrage 
				[270507] = {},
				-- Neurotoxin 
				[273563] = { dur = 1.49 },
				-- Cytotoxin 
				[267027] = { stack = 2 },
				-- Venomous Spit
				[272699] = {},
				-- Widowmaker Toxin
				[269298] = { stack = 2 }, 
				-- Stinging Venom
				[275836] = { stack = 5 },    
				-- Crippling Shiv
				[257777] = { dur = 1.49 },
			},
			Disease = {
				-- 8.3 Lingering Nausea
				[250372] = { byID = true, dur = 1.49 },
				-- 8.3 Crippling Pestilence
				[314406] = { byID = true, dur = 1.49 },
				-- 8.2 Mechagon - Consuming Slime
				[300659] = {},
				-- 8.2 Mechagon - Gooped
				[298124] = {},
				-- 8.2 Mechagon - Suffocating Smog
				[300650] = {},
				-- 8.0.1 Severing Serpent
				[264520] = { byID = true },
				-- 8.0.1 Infected Thorn
				[264050] = { byID = true, dur = 1.49 },
				-- Infected Wound
				[258323] = { stack = 1 },
				-- Plague Step
				[257775] = {},
				-- Wretched Discharge
				[267763] = {},				
				-- Festering Bite
				[263074] = {},
				-- Decaying Mind
				[278961] = {},
				-- Decaying Spores
				[259714] = {},
				-- Decaying Spores
				[273226] = { byID = true, stack = 2 },
				-- Rotting Wounds
				[272588] = { byID = true },
			}, 
			Curse = {
				-- Unstable Hex
				--[252781] = {}, -- recommended: don't dispel 						
				-- Wracking Pain
				[250096] = {},
				-- Pit of Despair
				[276031] = { dur = 1 },
				-- Hex 
				[270492] = {},
				-- Cursed Slash
				[257168] = { stack = 2 },
				-- Withering Curse
				[252687] = { stack = 2 },				
			},
			Magic = {	
				-- 8.3 Wildfire
				[253562] = { byID = true, dur = 1.49 },
				-- 8.3 Heart of Darkness
				[307645] = { byID = true, dur = 1.49 },
				-- 8.3 Annihilation
				[310224] = { byID = true, stack = 8 },
				-- 8.3 Recurring Nightmare
				[312486] = { byID = true, stack = 1 },
				-- 8.3 Corrupted Mind
				[313400] = { byID = true },
				-- 8.3 Mind Flay
				[314592] = { byID = true, dur = 1.49 },
				-- 8.3 Cascading Terror
				[314483] = { dur = 1.49  },
				-- 8.3 Unleashed Insanity
				[310361] = { byID = true, dur = 1.49 },
				-- 8.3 Psychic Scream
				[308375] = { byID = true, dur = 1 },
				-- 8.3 Void Buffet
				[297315] = { byID = true, dur = 1.49 },
				-- 8.3 Split Personality
				[316510] = { byID = true, dur = 1.49 },
				-- 8.2 Mechagon - Blazing Chomp
				[294929] = { byID = true },
				-- 8.2 Mechagon - Shrink
				[299572] = { byID = true },
				-- 8.2 Mechagon - Arcing Zap
				[294195] = { byID = true },
				-- 8.2 Mechagon - Discom-BOMB-ulator
				[285460] = { byID = true },
				-- 8.2 Mechagon - Flaming Refuse
				[294180] = { byID = true },
				-- 8.2 Mechagon -  Capacitor Discharge
				[295168] = { byID = true },
				-- 8.2 Queen Azshara - Arcane Burst
				[303657] = { byID = true, dur = 10 },
				-- 8.2 Za'qul - Dread
				[292963] = { byID = true },
				-- 8.2 Za'qul - Shattered Psyche
				[295327] = { byID = true },
				-- 8.2 Radiance of Azshara - Arcane Bomb
				-- [296746] = { byID = true }, -- need predict unit position to dispel only when they are out of raid 
				-- 8.0.1 Toad Blight
				[265352] = { byID = true, dur = 0.5 },
				-- 8.0.1 Freezing Trap
				[278468] = { byID = true, dur = 1.5 },
				-- 8.0.1 Frost Shock
				[270499] = { byID = true, dur = 1.5 },
				-- 8.0.1 Maddening Gaze
				[272609] = { byID = true, dur = 1 },
				-- The Restless Cabal - Promises of Power 
				[282562] = { byID = true, stack = 3 },				
				-- Jadefire Masters - Searing Embers
				[286988] = { byID = true },
				-- Conclave of the Chosen - Mind Wipe
				[285878] = { byID = true },
				-- Lady Jaina - Grasp of Frost
				[287626] = { byID = true },
				-- Lady Jaina - Hand of Frost
				[288412] = { byID = true },
				-- Whispers of Power
				[267034] = { stack = 4 },
				-- Whispers of Power
				[267037] = { stack = 4 },
				-- Righteous Flames
				[258917] = { byID = true },
				-- Suppression Fire
				[258864] = { byID = true },
				-- Molten Gold
				[255582] = {},
				-- Terrifying Screech
				[255041] = {},
				-- Terrifying Visage
				[255371] = {},
				-- Oiled Blade
				[257908] = {},
				-- Choking Brine
				[264560] = {},
				-- Electrifying Shock
				[268233] = { LUAVER = 1, LUA = [[ 
					-- Skips Mechagon - Mechagon Island, boss: Naeno Megacrash
					return ZoneID ~= 1490
				]] },
				-- Touch of the Drowned 
				[268322] = { LUAVER = 2, LUA = [[ -- if no party member is afflicted by Mental Assault (268391)
				return FriendlyTeam():GetDeBuffs(268391) == 0 ]] },
				-- Mental Assault 
				[268391] = {},
				-- Wicked Assault
				[266265] = { dur = 1.5 },
				-- Explosive Void
				[269104] = {},
				-- Choking Waters
				[272571] = {},
				-- Putrid Waters
				[274991] = {},
				-- Flame Shock 
				[268013] = { LUAVER = 2, LUA = [[ -- if no party member is afflicted by Snake Charm (268008)
				return FriendlyTeam():GetDeBuffs(268008) == 0 ]] },
				-- Snake Charm
				[268008] = {},
				-- Brain Freeze
				[280605] = { dur = 1.49 },
				-- Transmute: Enemy to Goo
				[268797] = {},
				-- Chemical Burn
				[259856] = {},
				-- Debilitating Shout
				[258128] = {},
				-- Torch Strike 
				[265889] = { stack = 2 },
				-- Fuselighter 
				[257028] = {},
				-- Death Bolt 
				[272180] = {},
				-- Putrid Blood
				[269301] = { stack = 2 },
				-- Grasping Thorns
				[263891] = {},
				-- Fragment Soul
				[264378] = {},
				-- Putrid Waters
				[275014] = { LUAVER = 2, LUA = [[ -- Don't dispel self
				return not UnitIsUnit("player", thisunit) ]] },
				-- Legion: Touch of Corruption
				[209469] = { byID = true },				
			}, 
			MagicMovement = {
			},
			Enrage = {
				-- Unholy Frenzy
				[320012] = { byID = true },
				-- Loyal Beasts
				[326450] = { byID = true },
				-- Undying Rage
				[333227] = { byID = true },
				-- Enrage
				[334800] = { byID = true },
				-- Fanatic's Rage
				[255824] = { dur = 8 },
				-- Bestial Wrath
				[257476] = {},
				-- Ancestral Fury
				[269976] = {},
				-- Warcry
				[265081] = {},
				-- Wicked Frenzy
				[266209] = {},
				-- Enrage
				[324085] = {},
				-- Seething Rage
				[320703] = { stack = 5 },
				-- Raging Tantrum
				[333241] = {},
				-- Battle Trance
				[342139] = {},
				-- Vengeful Rage
				[327155] = {},
				-- Enraged
				[324737] = { stack = 1 },
				-- Angering Shriek
				[334967] = {},
				-- Death Wish
				[331510] = {},
				-- Frenzy
				[321220] = {},
				-- Unstoppable Frenzy
				[331347] = {},
				-- Motivated
				[334470] = {},
				-- Unravel Flesh				
				[322888] = {},
				-- Enraging Anguish
				[340117] = {},
			},
			Bleeds = {
			},
			BlessingofProtection = {
			},
			BlessingofFreedom = {
			},
			BlessingofSacrifice = {
			},
			BlessingofSanctuary = {
			},
		},
		PvP = {
			BlackList = {},
			PurgeFriendly = {
				-- Mind Control (it's buff)
				[605] = { canStealOrPurge = true },
			},
			PurgeHigh = {
				-- Paladin: Blessing of Protection
				[1022] = { dur = 1 },
				-- Paladin: Divine Favor 
				[210294] = { dur = 0 },
				-- Priest: Power Infusion
				[10060] = { dur = 4 },
				-- Priest: Holy Ward
				[213610] = { dur = 3 },
				-- Priest: Luminous Barrier
				[271466] = { dur = 0 },
				-- Shaman: Spiritwalker's Grace
				[79206] = { dur = 1 },
				-- Mage: Combustion
				[190319] = { dur = 4 },
				-- Mage: Arcane Power
				[12042] = { dur = 4 },
				-- Mage: Icy Veins
				[12472] = { dur = 4 },
				-- Mage: Temporal Shield
				[198111] = { dur = 0 },
				-- Warlock: Nether Ward
				[212295] = { dur = 1 },
				-- Moment of Glory
				[311203] = { dur = 0 },
			},
			PurgeLow = {
				-- Paladin: Blessing of Freedom  
				[1044] = { dur = 1.5 },
				-- Druid: Lifebloom
				[33763] = { dur = 0, onlyBear = true },
				-- Druid: Rejuvenation
				[774] = { dur = 0, onlyBear = true },
				-- Druid: Germination
				[155777] = { dur = 0, onlyBear = true },
				-- Druid: Wild Growth 
				[48438] = { dur = 0, onlyBear = true },
				-- Druid: Regrow
				[8936] = { dur = 0, onlyBear = true },
			},
			Poison = {
				-- Hunter: Wyvern Sting
				[19386] = { dur = 0 },
				-- Hunter: Spider Sting 
				[202933] = { dur = 1 },
				-- Hunter: Viper Sting
				[202797] = { dur = 3 },
				-- Hunter: Scorpid Sting
				[202900] = { dur = 1.5 },				
			},
			Disease = {
				-- Druid: Infected Wounds
				[58180] = { role = "DAMAGER", dur = 0 },
				-- Death Knight: Outbreak (5 sec dot)
				[196782] = { dur = 0 },
				-- Death Knight: Outbreak (21 sec dot)
				[191587] = { role = "DAMAGER", dur = 18 },
			},
			Curse = {
				-- Shaman: Hex 
				[51514] = { dur = 1 },
				-- Warlock: Curse of Tongues
				[12889] = { dur = 3 },
				-- Warlock: Curse of Weakness
				[17227] = { dur = 3 },
				-- Warlock: Curse of Fragility
				[199954] = { dur = 3 },
			},
			Magic = {
				-- Paladin: Repentance
				[20066] = { dur = 1.5 },
				-- Paladin: Bliding light
				[105421] = { dur = 1.5 },
				-- Paladin: Avenger's Shield
				[31935] = { dur = 1.5 },
				-- Paladin: Hammer of Justice
				[853] = { dur = 0 },
				-- Hunter: Freezing Trap
				[3355] = { dur = 1.5 },
				-- Hunter: Freezing Trap
				[278468] = { byID = true, dur = 1.5 },
				-- Hunter: Freezing Arrow 
				[209790] = { dur = 1.5 },
				-- Hunter: Binding Shot
				[117526] = { dur = 1 },
				-- Priest: Mind Control 
				[605] = { dur = 0 },
				-- Priest: Psychic Scream
				[8122] = { dur = 1.5 },
				-- Priest: Shackle Undead 
				[9484] = { dur = 1 },
				-- Priest: Silence
				[15487] = { dur = 1 },
				-- Priest: Last Word
				[199683] = { dur = 1 },
				-- Priest: Psychic Horror
				[64044] = { dur = 0 },
				-- Priest: Holy word: Chastise
				[200200] = { dur = 0 }, 
				-- Shaman: Static Charge
				[118905] = { dur = 0 },
				-- Shaman: Earthfury
				[204399] = { dur = 0 },
				-- Mage: Polymorph 
				[118] = { dur = 1.5 },
				-- Mage: Ring of Frost
				[82691] = { dur = 1.5 },
				-- Mage: Dragon's Breath
				[31661] = { dur = 1.5 },														
				-- Warlock: Fear 
				[5782] = { dur = 1.5 },
				-- Warlock: Seduction
				[6358] = { dur = 1.5 },	
				-- Warlock: Howl of Terror
				[5484] = { dur = 1.5 },
				-- Warlock: Mortal Coil
				[6789] = { dur = 1 },
				-- Warlock: Sin and Punishment
				[87204] = { dur = 1 },
				-- Warlock: Unstable Affliction
				[31117] = { dur = 1, byID = true },
				-- Warlock: Shadowfury
				[30283] = { dur = 1 },
				-- Warlock: Summon Infernal
				[22703] = { dur = 1.4 },
				-- Monk: Song of Chi-ji
				[198909] = { dur = 1.5 },
				-- Monk: Incendiary brew
				[202274] = { dur = 1.5 },
				-- Druid: Hibernate 
				[2637] = { dur = 1.5 },
				-- Druid: Faerie Swarm
				[209749] = { dur = 0 },	
				-- Demon Hunter: Chaos Nova
				[179057] = { dur = 0 },
				-- Demon Hunter: Illidan's Grasp
				[205630] = { dur = 0, byID = true },
				-- Demon Hunter: Imprison
				[217832] = { dur = 0, byID = true },
				-- Demon Hunter: Metamorphosis
				[200166] = { dur = 1.4, byID = true }, 
				-- Demon Hunter: Fel Eruption
				[211881] = { dur = 0 },
				-- Death Knight: Strangulate
				[47476] = { dur = 1 },				
				-- Misc: Gladiator's Maledict
				[286349] = { dur = 0 },
			},
			MagicMovement = {
				-- Paladin: Hand of Hindrance
				[183218] = { dur = 1 },
				-- Mage: Frost Nova 
				[122] = { dur = 1 },
				-- Druid: Mass Entanglement
				[102359] = { dur = 1 },
				-- Druid: Entangling Roots
				[339] = { dur = 1, byID = true },
				-- Death Knight: Frozen Center
				[233395] = { dur = 1 },
			},
			Enrage = {
				-- Berserker Rage
				[18499] = { dur = 1 },
				-- Enrage
				[184361] = { dur = 1 },
			},
			Bleeds = {
			},
			BlessingofProtection = {
			},
			BlessingofFreedom = {
			},
			BlessingofSacrifice = {
			},
			BlessingofSanctuary = {
			},
		},
	},
}; StdUi.GlobalFactory = GlobalFactory

-- Table controllers 
local function tMerge(default, new, special, nonexistremove)
	-- Forced push all keys new > default 
	-- if special true will replace/format special keys 
	local result = {}
	
	for k, v in pairs(default) do 
		if type(v) == "table" then 
			if special and k == "PLAYERSPEC" then
				local classID = Action.PlayerClassID or select(3, UnitClass("player"))
				local n = GetNumSpecializationsForClassID(classID)
                for i = 1, n + 1 do 
                    local specID = i <= n and GetSpecializationInfo(i) or 1453
					result[specID] = tMerge(v, v, special, nonexistremove)
					
					-- Set default false on AutoAttack for non-melee and AutoShoot for healers
					if result[specID].AutoAttack or result[specID].AutoShoot then
						if ActionData.HealerSpecs[specID] then
							result[specID].AutoShoot = false
							result[specID].AutoAttack = false
						elseif ActionData.RangerSpecs[specID] then
							result[specID].AutoAttack = false
						end
					end
				end	
			elseif special and v.ISINTERRUPT then 
				result[k] = {}
				local Enabled, useKick, useCC, useRacial
				for ID, IDv in pairs(v) do
					if type(ID) == "number" then 
						local spellName = GetSpellInfo(ID)
						if type(spellName) == "table" then 
							spellName = spellName.name
						end 
						
						if spellName then 
							if type(IDv) == "table" then
								if IDv.Enabled == nil then 
									Enabled = true 
								else 
									Enabled = IDv.Enabled
								end 
								
								if IDv.useKick == nil then 
									useKick = true 
								else
									useKick = IDv.useKick
								end 
								
								if IDv.useCC == nil then 
									useCC = true
								else
									useCC = IDv.useCC
								end 
								
								if IDv.useRacial == nil then 
									useRacial = true 
								else
									useRacial = IDv.useRacial
								end 
							else
								Enabled, useKick, useCC, useRacial = true, true, true, true
							end 
							result[k][spellName] = { Enabled = Enabled, ID = ID, useKick = useKick, useCC = useCC, useRacial = useRacial } 
						else 
							A_Print(L["DEBUG"] .. (ID or "") .. " (spellName - ISINTERRUPT) " .. L["ISNOTFOUND"]:lower())							
						end 
					end 
				end
			elseif special and v.ISCURSOR then 
				result[k] = {}
				for KeyLocale, Val in pairs(v) do 					
					if type(Val) == "table" then 				
						result[k][KeyLocale] = { Enabled = true, Button = Val.Button, isTotem = Val.isTotem, LUA = Val.LUA, LUAVER = Val.LUAVER } 
					end 
				end 
			elseif new[k] ~= nil then 
				result[k] = tMerge(v, new[k], special, nonexistremove)
			else
				result[k] = tMerge(v, v, special, nonexistremove)
			end 
		elseif new[k] ~= nil then 	
			result[k] = new[k]
		elseif not nonexistremove then  	
			result[k] = v				
		end 
	end 
	
	if new ~= default then 
		for k, v in pairs(new) do 
			if type(v) == "table" then 
				result[k] = tMerge(type(result[k]) == "table" and result[k] or v, v, special, nonexistremove)
			else 
				result[k] = v
			end 
		end 
	end
	
	return result
end

local function tCompare(default, new, upkey, skip)
	local result = {}
	
	if (new == nil or next(new) == nil) and default ~= nil then 
		result = tMerge(result, default)		
	else 				
		if type(default) == "table" then 
			for k, v in pairs(default) do
				if not skip and new[k] ~= nil then 
					if type(v) == "table" then 
						result[k] = tCompare(v, new[k], k)
					elseif type(v) == type(new[k]) then 
						-- Overwrite default LUA specified in profile (default) even if user made custom (new), doesn't work for [3] "QLUA" and "LUA" 
						if k == "LUA" and default.LUAVER ~= nil and default.LUAVER ~= new.LUAVER then 							
							result[k] = v
							A_Print(L["DEBUG"] .. (upkey or "") .. " (LUA) " .. " " .. L["RESETED"]:lower())
						elseif k == "LUAVER" then 
							result[k] = v  
						else 
							result[k] = new[k]
						end 					 	
					elseif new[k] ~= nil then 
						result[k] = v
					end 
				else
					result[k] = v 
				end			
			end 
		end 
		
		for k, v in pairs(new) do 
			if type(v) == "table" then 	
				result[k] = tCompare(result[k], v, k, true)		
			elseif result[k] == nil then 
				result[k] = v
			--else 
				-- Debugs keys which has been updated by default 
				--A_Print(L["DEBUG"] .. "tCompare key: " .. k .. "  upkey: " .. (upkey or ""))				
			end	
		end 
	end 				
	
	return result 
end

local function tPushKeys(default, new, path)
	if new then 
		for k, v in pairs(new) do 
			if k == "PLAYERSPEC" then 
				local classID = Action.PlayerClassID or select(3, UnitClass("player"))
				for i = 1, GetNumSpecializationsForClassID(classID) do 
					local specID = GetSpecializationInfo(i)
					if default[specID] == nil then 
						default[specID] = {}
					end 
					tPushKeys(default[specID], v, (path or "") .. "[" .. specID .. "]")
				end	
			elseif k == GameLocale or k == "GameLocale" then -- avoid miss typo 
				for locale, localeTable in pairs(default) do 
					if type(locale) == "string" and type(localeTable) == "table" then 
						if type(v) ~= "table" then 
							default[locale] = v 
							A_Print(L.DEBUG .. (path or "") .. "[" .. locale .. "] " .. L.CREATED)
						else 
							-- The names for next table enterence must be localized 
							tPushKeys(default[locale], v, (path or "") .. "[" .. locale .. "]")
						end 
					end 
				end 
			else 
				local path = path 
				if type(k) == "number" then 
					path = (path or "") .. "[" .. k .. "]"
				else
					path = (path and path .. "." or "") .. k 
				end 
				
				if type(v) == "table" then 
					if default[k] == nil then
						default[k] = v 
						A_Print(L.DEBUG .. path .. " " .. L.CREATED)
					else 
						tPushKeys(default[k], v, path)
					end 					
				else 
					default[k] = v 
					A_Print(L.DEBUG .. path .. " " .. L.CREATED)
				end 					
			end
		end 
	end 
	return default
end 

local function tEraseKeys(default, new, path)
	-- Cleans in 'default' table keys which persistent in 'new' table includes special keys
	if new then 
		for k, v in pairs(new) do 
			if default[k] ~= nil then 
				local path = path 
				if type(k) == "number" then 
					path = (path or "") .. "[" .. k .. "]"
				else
					path = (path and path .. "." or "") .. k 
				end 
				
				if type(v) == "table" then 
					tEraseKeys(default[k], v, path)
				else 
					default[k] = nil 
					A_Print(L.DEBUG .. path .. " " .. L.RESETED:lower())
				end 
			elseif k == "PLAYERSPEC" then 
				local classID = Action.PlayerClassID or select(3, UnitClass("player"))
				for i = 1, GetNumSpecializationsForClassID(classID) do 
					local specID = GetSpecializationInfo(i)
					tEraseKeys(default[specID], v, (path or "") .. "[" .. specID .. "]")
				end	
			elseif k == GameLocale or k == "GameLocale" then -- avoid miss typo 
				for locale, localeTable in pairs(default) do 
					if type(locale) == "string" and type(localeTable) == "table" then 
						if type(v) ~= "table" then 
							default[locale] = nil 
							A_Print(L.DEBUG .. (path or "") .. "[" .. locale .. "] " .. L.RESETED:lower())
						else 
							-- The names for next table enterence must be localized 
							tEraseKeys(default[locale], v, (path or "") .. "[" .. locale .. "]")
						end 
					end 
				end 	
			end
		end 
	end 
	return default
end 

local Upgrade 					= {	
	pUpgrades					= {
		[1]						= function()
			tEraseKeys(pActionDB[4], { 
				PvETargetMouseover = true,
				PvPTargetMouseover = true,
			}, "pActionDB[4]")
		end,
		[2]						= function()
			-- Reset CheckSpellLevel in Shadowlands
			if Action.BuildToC < 90001 then 
				return false 
			end 
			
			pActionDB[3].CheckSpellLevel = true 
		end, 
		[3]						= function()
			tEraseKeys(pActionDB[4], { 
				Heal = {
					["GameLocale"] = {
						[32546] = true,
					},
				},
			}, "pActionDB[4]")
		end,
		[4]						= function()
			tEraseKeys(pActionDB[4], { 
				Heal = {
					["GameLocale"] = {
						[186263] = true,
					},
				},
			}, "pActionDB[4]")
		end,
		[5]						= function()
			tEraseKeys(pActionDB[4], { 
				Heal = {
					["GameLocale"] = {
						[191837] = true,
					},
				},
			}, "pActionDB[4]")
		end,
		[6]						= function()
			-- Defaults to /focus mode healing or /target if Classic is Vanilla
			local SelectStopOptions = pActionDB[8].SelectStopOptions or pActionDB[8][Action.PlayerSpec].SelectStopOptions 
			local value = Action.BuildToC < 20000
			for i = 1, 5 do 
				SelectStopOptions[i] = value
			end
		end,
		[7]						= function()
			-- Fixed miss typo AntiFake CC2, should be mouseover/target instead of focus on A[9], and focus as CC2 Focus on A[10]
			local MetaEngine = pActionDB[9].MetaEngine or pActionDB[9][Action.PlayerSpec].MetaEngine
			local Hotkeys = MetaEngine.Hotkeys
			Hotkeys[9].action = "AntiFake CC2"
			Hotkeys[10].action = "AntiFake CC2 Focus"
		end,
		[8]						= function()
			-- Just Retail ugrade to fix missing 6-7 upgrades on other specs
			local value = Action.BuildToC < 20000
			for spec, specDB in pairs(pActionDB[8]) do 
				for i = 1, 5 do
					specDB.SelectStopOptions[i] = value
				end
			end
			
			for spec, specDB in pairs(pActionDB[9]) do 
				specDB.MetaEngine.Hotkeys[9].action = "AntiFake CC2"
				specDB.MetaEngine.Hotkeys[10].action = "AntiFake CC2 Focus"
			end
		end,
	},
	gUpgrades					= {
		[1]						= function()
			tEraseKeys(gActionDB[5], { 
				Disease = {
					-- Plague 
					[269686] = true,
				},
				Magic = {
					-- Reap Soul
					[288388] = true,
					-- 8.3 Grasping Tendrils
					[315176] = true,
					-- 8.3 Annihilation
					[306982] = true,
				},
			}, "gActionDB[5]")
		end,
		[2]						= function()
			-- Miss typo with [1]
			tEraseKeys(gActionDB[5].PvE, { 
				Disease = {
					-- Plague 
					[269686] = true,
				},
				Magic = {
					-- Reap Soul
					[288388] = true,
					-- 8.3 Grasping Tendrils
					[315176] = true,
					-- 8.3 Annihilation
					[306982] = true,
				},
			}, "gActionDB[5].PvE")
		end,
		[3]						= function()
			-- Add new Shadowlands auras
			if Action.BuildToC < 90001 then 
				return false 
			end 
			
			tPushKeys(gActionDB[5], {
				PvP = {
					Magic = {
						-- Kyrian - Warlock: Scouring Tithe
						[312321] = { dur = 1.5 },
						-- Venthyr - Priest: Mindgames
						[323673] = { dur = 1.5 },
						-- Venthyr - Mage: ShiftingPower
						[314791] = { dur = 0 },
						-- Venthyr - DemonHunter: SinfulBrand
						[317009] = { dur = 1.5 },						
					},
					Poison = {
						-- NightFae - Rogue: Sepsis
						[328305] = { dur = 0 },
					},
					Bleeds = {
						-- Venthyr - Hunter: FlayedShot
						[324149] = { dur = 0 },
					},							
				},
				PvE = {
					Magic = {
						-- 9.0.1 Necrotic Wake (Mythic Dungeon): Frozen Binds
						[320788] = { dur = 1.5 },
						-- 9.0.1 An Affront of Challengers (Mythic Dungeon): Spectral Transference
						[320272] = { dur = 1.5 },
						-- 9.0.1 Halkias (Mythic Dungeon): Sinlight Visions
						[322977] = { dur = 0 },
						-- 9.0.1 Mueh'zala (Mythic Dungeon): Cosmic Artifice
						[325725] = { dur = 0 },
						-- 9.0.1 (Mythic Dungeon): Slime Injection
						[329110] = { dur = 0 },
					},
					Disease = {
						-- 9.0.1 Plaguefall (Mythic Dungeon): Debilitating Plague
						[324652] = { dur = 1.5 },
					},
				},
			}, "gActionDB[5]")
		end,
		[4] 					= function()
			tEraseKeys(gActionDB[5].PvP, { 
				PurgeLow = {
					-- Druid: Mark of the Wild
					[289318] = true,
				},
			}, "gActionDB[5].PvP")
		end,
		[5] 					= function()
			tEraseKeys(gActionDB[5].PvP, { 
				Magic = {
					[226943] = true,
				},
			}, "gActionDB[5].PvP")
		end,
	},
	pUpgradesForProfile			= {},
	SortMethod					= function(a, b)
		return (a and a.Version or 0) < (b and b.Version or 0)
	end,
	Perform						= function(self)
		if not pActionDB or not gActionDB then 
			error("Failed to properly upgrade ActionDB")
			return 
		end 
		
		local oldVer
		-- pActionDB
		oldVer = pActionDB.Ver -- Ver here
		for ver, func in ipairs(self.pUpgrades) do 
			if (pActionDB.Ver or 0) < ver then 
				if func() ~= false then 
					pActionDB.Ver = ver
				else 
					break 
				end 
			end 
		end				
		if pActionDB.Ver ~= oldVer then 
			A_Print("|cff00cc66ActionDB.profile|r " .. L["UPGRADEDFROM"] .. (oldVer or 0) .. L["UPGRADEDTO"] .. pActionDB.Ver .. "|r")
		end 
		
		-- gActionDB
		oldVer = gActionDB.Ver -- Ver here
		for ver, func in ipairs(self.gUpgrades) do 
			if (gActionDB.Ver or 0) < ver then 
				if func() ~= false then 
					gActionDB.Ver = ver
				else 
					break 
				end 
			end 
		end	
		if gActionDB.Ver ~= oldVer then 
			A_Print("|cff00cc66ActionDB.global|r " .. L["UPGRADEDFROM"] .. (oldVer or 0) .. L["UPGRADEDTO"] .. gActionDB.Ver .. "|r")
		end 
		
		-- pActionDB for current profile 
		local profileUpgrades = self.pUpgradesForProfile[Action.CurrentProfile]
		if profileUpgrades then 
			oldVer = pActionDB.Version -- Version here
			
			if #profileUpgrades > 1 then 
				tsort(profileUpgrades, self.SortMethod)			
			end 
			
			for _, profileUpgrade in ipairs(profileUpgrades) do 
				if (pActionDB.Version or 0) < profileUpgrade.Version then 
					if profileUpgrade.Func(pActionDB) ~= false then 
						pActionDB.Version = profileUpgrade.Version
					else 
						break 
					end 
				end 
			end
			
			if pActionDB.Version ~= oldVer then 
				A_Print("|cff00cc66" .. Action.CurrentProfile .. "|r " .. L["UPGRADEDFROM"] .. (oldVer or 0) .. L["UPGRADEDTO"] .. pActionDB.Version .. "|r")
			end 			
		end 	
	end,
	RegisterForProfile 			= function(self, profileName, version, func)
		-- This is for profile use in the lua snippets, they are initializing before call this function
		-- @usage: 
		--[[
		Action.Upgrade:RegisterForProfile(Action.CurrentProfile, 1, function(pActionDB)
			if Action.BuildToC < 90001 then 
				return false -- if function returns 'false' it doesn't perform notify, the placement of return is matters
			end 
			-- do your staff of itself upgrade here, in case of example if we're above or equal 90001 xpac
			pActionDB[2][PLAYERSPEC].toggleTable = nil 
			pActionDB[7][PLAYERSPEC].msgList[Message] = nil 
			-- alternative method of above which is better because it prints what it deletes
			-- accepts special keys also 
			Action.Upgrade.tEraseKeys(pActionDB, {
				[2] = {
					["PLAYERSPEC"] = {
						toggleTable = true,
					},
				},
				[7] = {
					["PLAYERSPEC"] = {
						msgList = {
							["Message"] = true,
						},
					},
				},
			}, "cff00cc66ActionDB") -- the start path which will be added to next paths until final at the stage of erase 
		end)
		]]
		if not self.pUpgradesForProfile[profileName] then 
			self.pUpgradesForProfile[profileName] = {}
		end 
		
		tinsert(self.pUpgradesForProfile[profileName], { Version = version, Func = func })
	end,
}
do 
	-- Push the utils 	
	Upgrade.tMerge = tMerge
	Upgrade.tCompare = tCompare
	Upgrade.tPushKeys = tPushKeys
	Upgrade.tEraseKeys = tEraseKeys

	-- Push to global 
	Action.Upgrade = Upgrade
end 

-- DB controllers
local function dbUpdate()
	TMWdb 			= TMW.db
	TMWdbprofile	= TMWdb.profile 
	TMWdbglobal		= TMWdb.global 
	pActionDB 		= TMWdbprofile.ActionDB
	gActionDB		= TMWdbglobal.ActionDB
	
	-- Fixes Resizer_Generic error if user tried to open ui in combat
	if TMWdbglobal and not TMWdbglobal.AllowCombatConfig then 
		TMWdbglobal.AllowCombatConfig = true
	end 	
	
	-- On hook InitializeDatabase
	if not Action.CurrentProfile and TMWdb then 
		Action.CurrentProfile = TMWdb:GetCurrentProfile()
	end 

	-- Note: Doesn't fires if speclization changed!
	TMW:Fire("TMW_ACTION_DB_UPDATED", pActionDB, gActionDB) 
end 

-- gActionDB[5] -> pActionDB[5]
local function DispelPurgeEnrageRemap()
	-- Note: This function should be called every time when [5] "Auras" in UI has been changed or shown
	-- Creates localization on keys and put them into profile db relative spec 
	wipe(ActionDataAuras)
	for Mode, Mode_v in pairs(gActionDB[5]) do 
		if not ActionDataAuras[Mode] then 
			ActionDataAuras[Mode] = {}
		end 
		for Category, Category_v in pairs(Mode_v) do 			
			if not ActionDataAuras[Mode][Category] then 
				ActionDataAuras[Mode][Category] = {} 
			end 
			for SpellID, v in pairs(Category_v) do 
				local Name = GetSpellInfo(SpellID)
				if type(Name) == "table" then 
					Name = Name.name
				end 
						
				if Name then 
					ActionDataAuras[Mode][Category][Name] = { 
						ID = SpellID, 
						Name = Name, 
						Enabled = true,
						Role = v.role or "ANY",
						Dur = v.dur or 0,
						Stack = v.stack or 0,
						byID = v.byID,
						canStealOrPurge = v.canStealOrPurge,
						onlyBear = v.onlyBear,
						LUA = v.LUA,
					} 
					if v.enabled ~= nil then 
						ActionDataAuras[Mode][Category][Name].Enabled = v.enabled 
					end 
				else 
					A_Print(L["DEBUG"] .. (SpellID or "") .. " (spellName - DispelPurgeEnrageRemap) " .. L["ISNOTFOUND"]:lower())	
				end 
			end 			 
		end 
	end 
	-- Creates relative to each specs which can dispel or purge anyhow
	local UnitAuras = {
		-- Restor Druid 
		[ActionConst.DRUID_RESTORATION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Curse,
					ActionDataAuras.PvE.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Curse,
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Balance
		[ActionConst.DRUID_BALANCE] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,	
					ActionDataAuras.PvE.Poison,		
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,		
					ActionDataAuras.PvP.Poison,		
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Feral
		[ActionConst.DRUID_FERAL] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,
					ActionDataAuras.PvE.Poison,	
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,
					ActionDataAuras.PvP.Poison,						
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Guardian
		[ActionConst.DRUID_GUARDIAN] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,	
					ActionDataAuras.PvE.Poison,		
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,
					ActionDataAuras.PvP.Poison,		
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Arcane
		[ActionConst.MAGE_ARCANE] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Fire
		[ActionConst.MAGE_FIRE] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Frost
		[ActionConst.MAGE_FROST] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,					
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Mistweaver
		[ActionConst.MONK_MISTWEAVER] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,
					ActionDataAuras.PvE.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
			},
		},
		-- Windwalker
		[ActionConst.MONK_WINDWALKER] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,					
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,					
				},
			},
		},
		-- Brewmaster
		[ActionConst.MONK_BREWMASTER] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,					
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,					
				},
			},
		},
		-- Holy Paladin
		[ActionConst.PALADIN_HOLY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,	
					ActionDataAuras.PvE.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				BlessingofProtection = {
					ActionDataAuras.PvE.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvE.BlessingofFreedom,
				},
				BlessingofSacrifice = { 
					ActionDataAuras.PvE.BlessingofSacrifice,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,	
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				BlessingofProtection = {
					ActionDataAuras.PvP.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvP.BlessingofFreedom,
				},
				BlessingofSacrifice = { 
					ActionDataAuras.PvP.BlessingofSacrifice,
				},
			},
		},
		-- Protection Paladin
		[ActionConst.PALADIN_PROTECTION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,						
				},
				BlessingofProtection = {
					ActionDataAuras.PvE.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvE.BlessingofFreedom,
				},
				BlessingofSacrifice = { 
					ActionDataAuras.PvE.BlessingofSacrifice,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,						
				},
				BlessingofProtection = {
					ActionDataAuras.PvP.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvP.BlessingofFreedom,
				},
				BlessingofSacrifice = { 
					ActionDataAuras.PvP.BlessingofSacrifice,
				},
			},
		},
		-- Retirbution Paladin
		[ActionConst.PALADIN_RETRIBUTION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Poison,
					ActionDataAuras.PvE.Disease,						
				},
				BlessingofProtection = {
					ActionDataAuras.PvE.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvE.BlessingofFreedom,
				},
				BlessingofSanctuary = { 
					ActionDataAuras.PvE.BlessingofSanctuary,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Poison,
					ActionDataAuras.PvP.Disease,						
				},
				BlessingofProtection = {
					ActionDataAuras.PvP.BlessingofProtection,
				},
				BlessingofFreedom = {
					ActionDataAuras.PvP.BlessingofFreedom,
				},
				BlessingofSanctuary = { 
					ActionDataAuras.PvP.BlessingofSanctuary,
				},
			},
		},
		-- Discipline Priest 
		[ActionConst.PRIEST_DISCIPLINE] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Magic,
					ActionDataAuras.PvE.Disease,						
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Magic,
					ActionDataAuras.PvP.Disease,						
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		}, 
		-- Holy Priest 
		[ActionConst.PRIEST_HOLY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvE.Magic,
					ActionDataAuras.PvE.Disease,						
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {
					ActionDataAuras.PvP.Magic,
					ActionDataAuras.PvP.Disease,						
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		}, 
		-- Shadow Priest 
		[ActionConst.PRIEST_SHADOW] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Disease,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Disease,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Elemental
		[ActionConst.SHAMAN_ELEMENTAL] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Enhancement
		[ActionConst.SHAMAN_ENCHANCEMENT] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,						
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Restoration
		[ActionConst.SHAMAN_RESTORATION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvE.Curse,
					ActionDataAuras.PvE.Magic,					
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {					
					ActionDataAuras.PvP.Curse,
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Affliction
		[ActionConst.WARLOCK_AFFLICTION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvE.Magic,					
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Demonology
		[ActionConst.WARLOCK_DEMONOLOGY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvE.Magic,					
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Destruction
		[ActionConst.WARLOCK_DESTRUCTION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvE.Magic,					
				},
				MagicMovement = {
					ActionDataAuras.PvE.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Dispel = {										
					ActionDataAuras.PvP.Magic,
				},
				MagicMovement = {
					ActionDataAuras.PvP.MagicMovement,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
			},
		},
		-- Assassination
		[ActionConst.ROGUE_ASSASSINATION] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Outlaw
		[ActionConst.ROGUE_OUTLAW] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Subtlety 
		[ActionConst.ROGUE_SUBTLETY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Beast Mastery
		[ActionConst.HUNTER_BEASTMASTERY] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Marksmanship
		[ActionConst.HUNTER_MARKSMANSHIP] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Survival
		[ActionConst.HUNTER_SURVIVAL] = {
			PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvE.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvE.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvE.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvE.Enrage,
				},
			},
			PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
				PurgeFriendly = {
					ActionDataAuras.PvP.PurgeFriendly,
				},
				PurgeHigh = {
					ActionDataAuras.PvP.PurgeHigh,
				},
				PurgeLow = {
					ActionDataAuras.PvP.PurgeLow,
				},
				Enrage = {
					ActionDataAuras.PvP.Enrage,
				},
			},
		},
		-- Havoc
        [ActionConst.DEMONHUNTER_HAVOC] = {
            PvE = {
				BlackList = {
					ActionDataAuras.PvE.BlackList,
				},
                Dispel = {                    
                    ActionDataAuras.PvE.Magic,                    
                },
                PurgeFriendly = {
                    ActionDataAuras.PvE.PurgeFriendly,
                },
                PurgeHigh = {
                    ActionDataAuras.PvE.PurgeHigh,
                },
                PurgeLow = {
                    ActionDataAuras.PvE.PurgeLow,
                },
            },
            PvP = {
				BlackList = {
					ActionDataAuras.PvP.BlackList,
				},
                Dispel = {                    
                    ActionDataAuras.PvP.Magic,                    
                },
                PurgeFriendly = {
                    ActionDataAuras.PvP.PurgeFriendly,
                },
                PurgeHigh = {
                    ActionDataAuras.PvP.PurgeHigh,
                },
                PurgeLow = {
                    ActionDataAuras.PvP.PurgeLow,
                },
            },
        },
	}
	
	-- Insert to profile db generated above 
	-- Note: Retail required to create table here 
	if not ActionDataAuras.DisableCheckboxes then 
		ActionDataAuras.DisableCheckboxes = {}
	end 	
	
	for specID, specTable in pairs(pActionDB[5]) do 
		if UnitAuras[specID] then 
			ActionDataAuras.DisableCheckboxes[specID] = { UsePurge = true, UseExpelEnrage = true }
			for Mode, Mode_v in pairs(UnitAuras[specID]) do 
				for Category, Category_v in pairs(Mode_v) do 
					if not specTable[Mode] then 
						specTable[Mode] = {}
					end 
					if not specTable[Mode][Category] then 
						specTable[Mode][Category] = {}
					end 

					-- Always to reset
					if specTable[Mode][Category][GameLocale] then 
						wipe(specTable[Mode][Category][GameLocale])
					else 
						specTable[Mode][Category][GameLocale] = {}
					end 
				
					if Category:match("Purge") then 
						ActionDataAuras.DisableCheckboxes[specID].UsePurge = false 
					elseif Category:match("Enrage") then 	
						ActionDataAuras.DisableCheckboxes[specID].UseExpelEnrage = false 
					end		
					
					if #Category_v > 0 then 
						for i = 1, #Category_v do 
							for k, v in pairs(Category_v[i]) do 
								specTable[Mode][Category][GameLocale][k] = v
							end 
						end
					else -- Not sure if we really need this but why not ..
						for k, v in pairs(Category_v) do 
							specTable[Mode][Category][GameLocale][k] = v
						end 
					end 
				end 	
			end
			
			-- Set false in db if we found what no longer can use checkboxes
			for Checkbox, v in pairs(ActionDataAuras.DisableCheckboxes[specID]) do 
				if v then 
					specTable[Checkbox] = not v
				end 
			end
		else 
			specTable.UsePurge = false 
			specTable.UseExpelEnrage = false			
		end 		
	end 
end

-------------------------------------------------------------------------------
-- UI: Containers
-------------------------------------------------------------------------------
function StdUi:ShowTooltip(parent, show, ID, Type)
	if show then
		if ID == nil or Type == "SwapEquip" then  
			GameTooltip:Hide()
			return 
		end
		GameTooltip:SetOwner(parent)
		if Type == "Trinket" or Type == "Potion" or Type == "Item" then 
			GameTooltip:SetItemByID(ID) 
		elseif Type == "Spell" then 
			GameTooltip:SetSpellByID(ID)
		else 
			GameTooltip:SetText(ID)
		end 
	else
		GameTooltip:Hide()
	end
end
function StdUi:LayoutSpace(parent)
	-- Util for EasyLayout to create "space" in row since it support only elements
	return self:Subtitle(parent, "")
end 
function StdUi:GetWidthByColumn(parent, col, offset)
	-- Util for EasyLayout to provide correctly width for dropdown menu since lib has bug to properly resize it 
	local left = parent.layout.padding.left
	local right = parent.layout.padding.right
	local width = parent:GetWidth() - parent.layout.padding.left - parent.layout.padding.right
	local gutter = parent.layout.gutter
	local columns = parent.layout.columns
	return (width / (columns / col)) - 2 * gutter + (offset or 0)
end 
function StdUi:ClipScrollTableColumn(parent, height)
	local columnHeadFrame 	= parent.head
	local columns			= parent.columns
	for i = 1, #columnHeadFrame.columns do
		local columnFrame = columnHeadFrame.columns[i]
		
		columnFrame.text:SetText(columns[i].name)
		columnFrame.text:ClearAllPoints()
		columnFrame.text:SetPoint("TOP", columnFrame, "TOP", 0, 0)
		columnFrame.text:SetPoint("BOTTOM", columnFrame, "BOTTOM", 0, 0)
		columnFrame.text:SetWidth(columns[i].width - 2 * 2.5)
	end 
end 
function StdUi:GetAnchor(tab, spec)
	-- Uses for EasyLayout (resizer / toggles)
	if tab.childs[spec].scrollChild then 
		return tab.childs[spec].scrollChild
	else 
		return tab.childs[spec]
	end  
end 
function StdUi:GetAnchorKids(tab, spec)
	-- Uses for EasyLayout (resizer / toggles)
	if tab.childs[spec].scrollChild then 
		return tab.childs[spec].scrollChild:GetChildrenWidgets()
	else 
		return tab.childs[spec]:GetChildrenWidgets()
	end  
end 
function StdUi:AddToggleWidgets(toggleWidgets, ...)
	local child 
	for i = 1, select("#", ...) do 
		child = select(i, ...)
		if child.isWidget then 
			if child.layout then 
				self:AddToggleWidgets(toggleWidgets, child:GetChildren())
			elseif child.Identify and child.Identify.Toggle then 
				toggleWidgets[child.Identify.Toggle] = child
			end 
		end 
	end 
end 
function StdUi:EnumerateToggleWidgets(tabChild, anchor)
	tabChild.toggleWidgets = {}
	self:AddToggleWidgets(tabChild.toggleWidgets, anchor:GetChildren())
end 
function StdUi:CreateResizer(parent)
	local parent = parent
	if not parent then parent = self end 
	if not TMW or parent.resizer then return end 
	-- Pre Loading options if case if first time it failed 
	if TMW.Classes.Resizer_Generic == nil then 
		TMW:LoadOptions()
	end 	
	local frame = {}
	frame.resizer = TMW.Classes.Resizer_Generic:New(parent)
	frame.resizer:Show()
	frame.resizer.y_min = parent:GetHeight()
	frame.resizer.x_min = parent:GetWidth()
	if TELLMEWHEN_VERSIONNUMBER  >= 87302 then 
		frame.resizer.resizeButton.module.IsEnabled = true 
	end 
	TMW:TT(frame.resizer.resizeButton, L["RESIZE"], L["RESIZE_TOOLTIP"], 1, 1)
	return frame
end 

function Action.ConvertSpellNameToID(spellName)
	local Name, _, _, _, _, _, ID = GetSpellInfo(spellName)
	if type(Name) == "table" then 
		ID = Name.spellID
		Name = Name.name
	end 
				
	if not Name then 
		for i = 1, 350000 do 
			Name, _, _, _, _, _, ID = GetSpellInfo(i)
			if type(Name) == "table" then 				
				ID = Name.spellID
				Name = Name.name
			end 
			if Name ~= nil and Name ~= "" and Name == spellName then 
				return ID
			end 
		end 
	end 
	return ID 
end 
Action.ConvertSpellNameToID = TMW:MakeSingleArgFunctionCached(Action.ConvertSpellNameToID)
function Action.CraftMacro(macroName, macroBody, perCharacter, useQuestionIcon, leaveNewLine, isHidden)
	-- @usage: Action.CraftMacro(@string, @string[, @boolean, @boolean, @boolean, @boolean])
	-- 1. macroName the name of the macro title 
	-- 2. macroBody the text of the macro 
	-- 3. perCharacter, must be true if need create macro in character's tab 
	-- 4. useQuestionIcon, must be true if need use default question texture 
	-- 5. leaveNewLine, must be true if need leave '\n' in macroBody
	-- 6. isHidden, must be true if need create macro without cause opened macro frame 
	local macroName = macroName:gsub("\n", " ")
	local macroBody = not leaveNewLine and macroBody:gsub("\n", " ") or macroBody
	local error 	= MacroLibrary:CraftMacro(macroName, not useQuestionIcon and MacroLibrary.Data.Icons[1], macroBody, perCharacter, isHidden)	
	
	if error == "MacroExists" then 
		A_Print(macroName .. " - " .. L["MACROEXISTED"])		
	elseif error == "InCombatLockdown" then 
		A_Print(L["MACROINCOMBAT"])		 
	elseif error == "MacroLimit" then 
		A_Print(L["MACROLIMIT"])	
	else 
		A_Print(L["MACRO"] .. " " .. macroName .. " " .. L["CREATED"] .. "!")
	end 
end
function Action:IsActionTable(tabl)
	-- @return boolean
	-- Noe: Returns true if it's action created by .Create method 
	local this = tabl or self 
	return this.Type and this.SubType and this.Desc and true 
end 
function Action.GetActionTableByKey(key)
	-- @return table or nil 
	-- Note: Returns table object which can be used to pass methods by specified key 
	local owner = Action[owner]
	local A = Action[owner] and Action[owner][key]
	if type(A) == "table" and A_IsActionTable(A) then 
		return A
	else
		A = Action[key]
		if type(A) == "table" and A_IsActionTable(A) then 
			return A
		end 
	end 
end 
function Action:GetTableKeyIdentify()
	-- Using to link key in DB
	if not self.TableKeyIdentify then 
		self.TableKeyIdentify = strOnlyBuilder(self.SubType, self.ID, self.Desc, self.Color, self.Macro)
	end 
	return self.TableKeyIdentify
end
function Action.WipeTableKeyIdentify()
	-- Using to reset cached key due spell changes by level (Retail) or changes by rank (Classic)	
	local owner = Action[owner]
	if Action[owner] then 
		for _, actionData in pairs(Action[owner]) do 
			if type(actionData) == "table" and actionData.TableKeyIdentify then 
				actionData.TableKeyIdentify = nil 
			end 
		end 
	end 
	
	for _, actionData in pairs(Action) do 
		if type(actionData) == "table" and actionData.TableKeyIdentify then 
			actionData.TableKeyIdentify = nil 
		end 
	end 
end 

-------------------------------------------------------------------------------
-- UI: ColorPicker - Container
-------------------------------------------------------------------------------
local ColorPicker 						= {
	Themes								= {
		BloodyBlue						= {
			["progressBar"] = {
				["color"] = {
					["a"] = 0.5,
					["r"] = 1,
					["g"] = 0.8313725490196078,
					["b"] = 0.788235294117647,
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 0.8117647058823529,
						["r"] = 0.3294117647058824,
					},
					["subtitle"] = {
						["a"] = 1,
						["b"] = 0.7803921568627451,
						["g"] = 0.6078431372549019,
						["r"] = 0.4549019607843137,
					},
					["disabled"] = {
						["a"] = 1,
						["b"] = 0.1843137254901961,
						["g"] = 0.1843137254901961,
						["r"] = 0.1843137254901961,
					},
					["header"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 0.9137254901960784,
						["r"] = 0.1058823529411765,
					},
					["tooltip"] = {
						["a"] = 1,
						["b"] = 0.7803921568627451,
						["g"] = 0.6078431372549019,
						["r"] = 0.4549019607843137,
					},
				},
			},
			["highlight"] = {
				["color"] = {
					["a"] = 0.4,
					["r"] = 1,
					["g"] = 0,
					["b"] = 0.1803921568627451,
				},
				["blank"] = {
					["a"] = 0,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.8,
					["r"] = 0,
					["g"] = 0.01568627450980392,
					["b"] = 0.1098039215686275,
				},
				["highlight"] = {
					["a"] = 0.5,
					["r"] = 0.192156862745098,
					["g"] = 0.4823529411764706,
					["b"] = 0.4980392156862745,
				},
				["border"] = {
					["a"] = 1,
					["r"] = 0.2627450980392157,
					["g"] = 0.01176470588235294,
					["b"] = 0.04313725490196078,
				},
				["button"] = {
					["a"] = 1,
					["r"] = 0.1294117647058823,
					["g"] = 0.00392156862745098,
					["b"] = 0.01568627450980392,
				},
				["buttonDisabled"] = {
					["a"] = 1,
					["r"] = 0.07058823529411765,
					["g"] = 0.0196078431372549,
					["b"] = 0.02352941176470588,
				},
				["borderDisabled"] = {
					["a"] = 1,
					["r"] = 0.09411764705882353,
					["g"] = 0.1098039215686275,
					["b"] = 0.1058823529411765,
				},
				["slider"] = {
					["a"] = 1,
					["r"] = 0.02352941176470588,
					["g"] = 0.03529411764705882,
					["b"] = 0.1490196078431373,
				},
			},
		},
		Orhell 							= {
			["progressBar"] = {
				["color"] = {
					["a"] = 0.5,
					["r"] = 1,
					["g"] = 0.9,
					["b"] = 0,
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["r"] = 0.5450980392156862,
						["g"] = 0,
						["b"] = 0.00392156862745098,
					},
					["subtitle"] = {
						["a"] = 1,
						["r"] = 1,
						["g"] = 0.2823529411764706,
						["b"] = 0,
					},
					["disabled"] = {
						["a"] = 1,
						["r"] = 0.55,
						["g"] = 0.55,
						["b"] = 0.55,
					},
					["tooltip"] = {
						["a"] = 1,
						["r"] = 1,
						["g"] = 0.07450980392156863,
						["b"] = 0,
					},
					["header"] = {
						["a"] = 1,
						["r"] = 1,
						["g"] = 0.3529411764705882,
						["b"] = 0,
					},
				},
			},
			["highlight"] = {
				["color"] = {
					["a"] = 0.4,
					["r"] = 1,
					["g"] = 0.9,
					["b"] = 0,
				},
				["blank"] = {
					["a"] = 0,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.35,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["highlight"] = {
					["a"] = 0.5,
					["r"] = 0.4,
					["g"] = 0.4,
					["b"] = 0,
				},
				["border"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["button"] = {
					["a"] = 1,
					["r"] = 0.2,
					["g"] = 0,
					["b"] = 0.03137254901960784,
				},
				["buttonDisabled"] = {
				},
				["borderDisabled"] = {
					["a"] = 1,
					["r"] = 0.4,
					["g"] = 0.4,
					["b"] = 0.4,
				},
				["slider"] = {
					["a"] = 1,
					["r"] = 0.15,
					["g"] = 0.15,
					["b"] = 0.15,
				},
			},
		},
		Bubblegum 						= {
			["progressBar"] = {
				["color"] = {
					["a"] = 0.5,
					["b"] = 0,
					["g"] = 0.9,
					["r"] = 1,
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["b"] = 0.5411764705882353,
						["g"] = 0.392156862745098,
						["r"] = 1,
					},
					["subtitle"] = {
						["a"] = 1,
						["b"] = 0.6862745098039216,
						["g"] = 1,
						["r"] = 0.3254901960784314,
					},
					["disabled"] = {
					},
					["tooltip"] = {
						["a"] = 1,
						["b"] = 0,
						["g"] = 0.8196060657501221,
						["r"] = 0.9999977946281433,
					},
					["header"] = {
						["a"] = 1,
						["b"] = 0.5411764705882353,
						["g"] = 0.392156862745098,
						["r"] = 1,
					},
				},
			},
			["highlight"] = {
				["color"] = {
					["a"] = 0.4,
					["b"] = 0.9529411764705882,
					["g"] = 0.9764705882352941,
					["r"] = 1,
				},
				["blank"] = {
					["a"] = 0,
					["b"] = 0,
					["g"] = 0,
					["r"] = 0,
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.6,
					["b"] = 0.06666666666666667,
					["g"] = 0.06666666666666667,
					["r"] = 0.06666666666666667,
				},
				["highlight"] = {
					["a"] = 0.5,
					["b"] = 0,
					["g"] = 0.4,
					["r"] = 0.4,
				},
				["border"] = {
					["a"] = 1,
					["b"] = 0,
					["g"] = 0,
					["r"] = 0,
				},
				["button"] = {
					["a"] = 1,
					["b"] = 0.2980392156862745,
					["g"] = 0.2352941176470588,
					["r"] = 0.192156862745098,
				},
				["buttonDisabled"] = {
					["a"] = 1,
					["b"] = 0.15,
					["g"] = 0.15,
					["r"] = 0.15,
				},
				["borderDisabled"] = {
					["a"] = 1,
					["b"] = 0,
					["g"] = 0,
					["r"] = 0,
				},
				["slider"] = {
					["a"] = 1,
					["b"] = 0.15,
					["g"] = 0.15,
					["r"] = 0.15,
				},
			},
		},
		DreamyPurple 					= {
			["progressBar"] = {
				["color"] = {
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["r"] = 0.803921568627451,
						["g"] = 0.3882352941176471,
						["b"] = 1,
					},
					["subtitle"] = {
						["a"] = 1,
						["r"] = 0.5411764705882353,
						["g"] = 0,
						["b"] = 0.7137254901960784,
					},
					["disabled"] = {
					},
					["tooltip"] = {
						["a"] = 1,
						["r"] = 0.8705882352941177,
						["g"] = 0.2509803921568627,
						["b"] = 1,
					},
					["header"] = {
						["a"] = 1,
						["r"] = 0.792156862745098,
						["g"] = 0,
						["b"] = 0.5529411764705883,
					},
				},
			},
			["highlight"] = {
				["color"] = {
				},
				["blank"] = {
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.56,
					["r"] = 0.09803921568627451,
					["g"] = 0,
					["b"] = 0.1568627450980392,
				},
				["highlight"] = {
				},
				["border"] = {
				},
				["button"] = {
					["a"] = 1,
					["r"] = 0.3450980392156863,
					["g"] = 0,
					["b"] = 0.4627450980392157,
				},
				["buttonDisabled"] = {
				},
				["borderDisabled"] = {
				},
				["slider"] = {
				},
			},
		},
		HotTomato						= {
			["progressBar"] = {
				["color"] = {
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 1,
						["r"] = 1,
					},
					["subtitle"] = {
						["a"] = 1,
						["b"] = 0.9921568627450981,
						["g"] = 1,
						["r"] = 0.996078431372549,
					},
					["disabled"] = {
						["a"] = 1,
						["b"] = 0,
						["g"] = 0,
						["r"] = 0,
					},
					["tooltip"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 1,
						["r"] = 1,
					},
					["header"] = {
						["a"] = 1,
						["b"] = 1,
						["g"] = 0.9803921568627451,
						["r"] = 0.9921568627450981,
					},
				},
			},
			["highlight"] = {
				["color"] = {
					["a"] = 0.79,
					["r"] = 1,
					["g"] = 0.01568627450980392,
					["b"] = 0,
				},
				["blank"] = {
					["a"] = 0.82,
					["r"] = 0.9294117647058824,
					["g"] = 0.9294117647058824,
					["b"] = 0.9294117647058824,
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.36,
					["b"] = 0,
					["g"] = 0,
					["r"] = 0.5843137254901961,
				},
				["highlight"] = {
					["a"] = 1,
					["r"] = 1,
					["g"] = 1,
					["b"] = 1,
				},
				["border"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["button"] = {
					["a"] = 1,
					["r"] = 0.07450980392156863,
					["g"] = 0.07450980392156863,
					["b"] = 0.07450980392156863,
				},
				["buttonDisabled"] = {
					["a"] = 0.97,
					["r"] = 0.5686274509803921,
					["g"] = 0,
					["b"] = 0,
				},
				["borderDisabled"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["slider"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
			},
		},
		Ice 	 						= {
			["progressBar"] = {
				["color"] = {
					["a"] = 0.5,
					["r"] = 0,
					["g"] = 0.8901960784313725,
					["b"] = 1,
				},
			},
			["font"] = {
				["color"] = {
					["normal"] = {
						["a"] = 1,
						["r"] = 0.5686274509803921,
						["g"] = 0.9019607843137255,
						["b"] = 1,
					},
					["subtitle"] = {
						["a"] = 1,
						["r"] = 0.1411764705882353,
						["g"] = 0.8784313725490196,
						["b"] = 1,
					},
					["disabled"] = {
						["a"] = 1,
						["r"] = 0.2745098039215687,
						["g"] = 0.5725490196078431,
						["b"] = 0.6941176470588235,
					},
					["tooltip"] = {
						["a"] = 1,
						["r"] = 0.2862745098039216,
						["g"] = 0.788235294117647,
						["b"] = 1,
					},
					["header"] = {
						["a"] = 1,
						["r"] = 0,
						["g"] = 1,
						["b"] = 0.984313725490196,
					},
				},
			},
			["highlight"] = {
				["color"] = {
					["a"] = 0.4,
					["r"] = 0,
					["g"] = 0.8627450980392157,
					["b"] = 1,
				},
				["blank"] = {
					["a"] = 0,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
			},
			["backdrop"] = {
				["panel"] = {
					["a"] = 0.8,
					["r"] = 0.00784313725490196,
					["g"] = 0.00784313725490196,
					["b"] = 0.07450980392156863,
				},
				["highlight"] = {
					["a"] = 0.5,
					["r"] = 0.9215686274509803,
					["g"] = 0.9647058823529412,
					["b"] = 1,
				},
				["border"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["button"] = {
					["a"] = 1,
					["r"] = 0.06274509803921569,
					["g"] = 0.1764705882352941,
					["b"] = 0.3098039215686275,
				},
				["buttonDisabled"] = {
					["a"] = 1,
					["r"] = 0.00784313725490196,
					["g"] = 0.06666666666666667,
					["b"] = 0.1647058823529412,
				},
				["borderDisabled"] = {
					["a"] = 1,
					["r"] = 0,
					["g"] = 0,
					["b"] = 0,
				},
				["slider"] = {
				},
			},
		},						
	},
	Cache 								= {}, 										-- Stores default StdUi colors 	
	StdUiObjects						= CopyTable(Factory[1].ColorPickerConfig),	-- Stores objects as key and function as value. It doesn't cache 'highlight' because his data receives with real time by OnEnter handler
	strupperCache 						= setmetatable({}, {
		__index = function(t, i)
			if not i then return end
			local o
			if type(i) == "number" then
				o = i
			else
				o = strupper(i)
			end
			t[i] = o
			return o
		end,
		__call = function(t, i)
			return t[i]
		end,
	}),
	tReplaceRGBA						= function(self, inT, fromT)
		-- @return nil 
		-- Replaces values for equal keys in 'inT' table from 'fromT' table without create new 
		for k, v in pairs(fromT) do 
			inT[k] = v
		end 
	end,
	tEqualRGBA							= function(self, x, y)
		-- @return boolean 
		return x.r == y.r and x.g == y.g and x.b == y.b and x.a == y.a
	end,
	tFindByOption						= function(self, t, option)
		-- @return table or nil 
		-- Usage: 
		-- 't' table in which do search i.e. StdUi.config[element]
		-- 'option' string i.e. StdUi.config[element][option] or StdUi.config[element] > color > normal (option)
		if t[option] then 
			return t[option]
		else 
			for k, v in pairs(t) do 
				if type(v) == "table" then  
					return self:tFindByOption(v, option)
				end 
			end 
		end 
	end,
	HasRGBA								= function(self, t)
		return t.r and t.g and t.b and t.a and true  
	end,
	MakeCache 							= function(self)
		if not next(self.Cache) then 
			local function CopyStdUiColors(toT, fromT, checkT)
				for k, v in pairs(fromT) do 
					if type(v) == "table" then 
						if self:HasRGBA(v) then 
							toT[k] = CopyTable(v)
						elseif checkT[k] then 
							toT[k] = {}
							CopyStdUiColors(toT[k], v, checkT[k])
						end 
					end 
				end 
			end 
			CopyStdUiColors(self.Cache, StdUi.config, Factory[1].ColorPickerConfig)
		end 
	end,
	MakeColors 							= function(self, t, element)
		-- Used for everything
		-- @usage: ColorPicker:MakeColors([t, element])
		-- Note: 
		--		 't' is manual color table i.e. self.Cache to reset 
		-- 		 'element' is a first level passthrough key i.e. font (element) > color > normal (option)
		for k, v in pairs(t or pActionDB[1].ColorPickerConfig) do 
			if self:HasRGBA(v) then 			
				self:MakeOn(element, k, v)
			elseif next(v) then 
				self:MakeColors(v, element or k)
			end 			 
		end 
	end,	
	SetElementsIn						= function(self, t)
		-- @return t 
		-- Formates 't' table to create dropdown 'Element'
		if #t > 0 then 
			wipe(t)
		end 
		
		for k in pairs(Factory[1].ColorPickerConfig) do 
			local upLetters = self.strupperCache[k]			
			t[#t + 1] = { text = L["TAB"][1][upLetters] or k, value = k }
		end 
		
		return t
	end,
	SetOptionsIn						= function(self, t, element, search)
		-- @return t 
		-- Formates 't' table to create dropdown 'Option'
		-- @usage: ColorPicker:SetOptionsIn(t, element) 
		if not search and #t > 0 then 
			wipe(t)
		end 
		
		for k, v in pairs(search or Factory[1].ColorPickerConfig[element]) do 
			if not next(v) or self:HasRGBA(v) then 
				local upLetters = self.strupperCache[k]
				t[#t + 1] = { text = L["TAB"][1][upLetters] or k, value = k }
			else 
				self:SetOptionsIn(t, element, v)
			end 
		end 
		
		return t
	end,
	SetThemesIn							= function(self, t)
		-- @return t 
		-- Formates 't' table to create dropdown 'Theme'
		if #t > 0 then 
			wipe(t)
		end 
		
		for k in pairs(self.Themes) do 
			local upLetters = self.strupperCache[k]			
			t[#t + 1] = { text = L["TAB"][1][upLetters] or k, value = k }
		end 
		
		return t
	end,
	ResetColors							= function(self)
		-- Used for everything 
		self:MakeColors(self.Cache)
		self.wasChanged = nil 
	end, 
	MakeOn								= function(self, element, option, t)
		-- Used for target apply to custom 
		-- @usage: ColorPicker:MakeOn(element, option[, t])
		local tStdUiConfig 		= self:tFindByOption(StdUi.config[element], option)
		local tCurrentConfig 	= t or self:tFindByOption(pActionDB[1].ColorPickerConfig[element], option)
		
		if self:HasRGBA(tCurrentConfig) and not self:tEqualRGBA(tStdUiConfig, tCurrentConfig) then 
			self:tReplaceRGBA(tStdUiConfig, tCurrentConfig)
			
			-- Refresh already created frames 
			local objects = self:tFindByOption(self.StdUiObjects[element], option)
			if objects and next(objects) then 
				for obj, method in pairs(objects) do 										
					if type(obj) == "table" then -- exclude texture from stdUi.config (related to updates with BackdropTemplateMixin)
						obj[method](obj, tStdUiConfig.r, tStdUiConfig.g, tStdUiConfig.b, tStdUiConfig.a)
						
						-- Refresh highlight 
						obj.origBackdropBorderColor = nil 
						if obj.target then 
							obj.target.origBackdropBorderColor = nil 
						end 	
					end 					
				end 
			end 
			
			self.wasChanged = true
		end 
	end,
	ResetOn								= function(self, element, option)
		-- Used for target reset to default 
		-- @usage: ColorPicker:ResetOn(element, option)		
		self:MakeOn(element, option, self:tFindByOption(self.Cache[element], option))
	end,
	Initialize							= function(self)
		self:MakeCache()
		if A_GetToggle(1, "ColorPickerUse") then 
			self:MakeColors()
		elseif self.wasChanged then 
			self:ResetColors()
		end 
		
		-- Fix StdUi bug with tab buttons, they become in disabled state 
		if tabFrame then 
			for _, tab in ipairs(tabFrame.tabs) do
				if tab.button and tabFrame.selected ~= tab.name then
					tab.button:Enable()
				end 
			end 
		end 
	end,
}; Action.ColorPicker = ColorPicker
do 
	-- Inserts in StdUi.config missed but required parts 
	local f = CreateFrame("Frame")
	f.subtitle = f:CreateFontString(nil, StdUi.config.font.strata, "GameFontNormal")
	local r, g, b = f.subtitle:GetTextColor()
	StdUi.config.font.color.subtitle 	= { r = r, g = g, b = b, a = 1 }
	StdUi.config.font.color.tooltip 	= { r = r, g = g, b = b, a = 1 } -- Equal to 'subtitle'

	function StdUi:Subtitle(parent, text, inherit)
		-- This is special envelope indicates that created fontString is subtitle
		local fs = StdUi:FontString(parent, text, inherit)
		if fs.SetTextColor then 
			if not ColorPicker.StdUiObjects.font.color.subtitle[fs] then 
				ColorPicker.StdUiObjects.font.color.subtitle[fs] = "SetTextColor"
			end 
			local c = StdUi.config.font.color.subtitle
			fs:SetTextColor(c.r, c.g, c.b, c.a)
		end 
		return fs 
	end 
end 

hooksecurefunc(StdUi, "SetTextColor", function(self, fontString, colorType)
	if fontString.SetTextColor then 
		colorType = colorType or "normal"	
		if colorType == "disabled" then 
			-- Remove from all enabled objects  	
			for k, v in pairs(ColorPicker.StdUiObjects.font.color) do 
				if k ~= colorType then 
					v[fontString] = nil 
				end 
			end 							
		else 
			-- Remove from all disabled objects  
			ColorPicker.StdUiObjects.font.color[colorType][fontString] 	= nil 
		end 
		
		if colorType == "header" then 
			-- Remove doubles 
			ColorPicker.StdUiObjects.font.color.normal[fontString] 		= nil 	
		end 
		
		if not ColorPicker.StdUiObjects.font.color[colorType][fontString] then 			
			ColorPicker.StdUiObjects.font.color[colorType][fontString] 	= "SetTextColor"
		end 	
	end 
end)

hooksecurefunc(StdUi, "HighlightButtonTexture", function(self, button)
	hooksecurefunc(button, "SetHighlightTexture", function(self, texObj)
		if texObj then 
			if not ColorPicker.StdUiObjects.highlight.color[texObj] then 
				ColorPicker.StdUiObjects.highlight.color[texObj] = "SetColorTexture"
			end 
		elseif self.highlightTexture then 
			ColorPicker.StdUiObjects.highlight.color[self.highlightTexture] = nil 
		end 
	end)
end)

hooksecurefunc(StdUi, "ApplyBackdrop", function(self, frame, type, border, insets)
	local isProgressBar = type == nil and border == nil and insets == nil and frame:GetObjectType() == "StatusBar"
	
	if isProgressBar then 
		if not ColorPicker.StdUiObjects.progressBar.color[frame] then 
			ColorPicker.StdUiObjects.progressBar.color[frame] 		= "SetStatusBarColor"
		end 
	else 		
		type 	= type 	 or "button"
		border 	= border or "border"
	
		if type == "buttonDisabled" or border == "borderDisabled" then 
			-- Remove from all enabled objects  	
			ColorPicker.StdUiObjects.backdrop.button[frame] 		= nil 	
			ColorPicker.StdUiObjects.backdrop.border[frame] 		= nil 	
		else 
			-- Remove from all disabled objects 
			ColorPicker.StdUiObjects.backdrop.buttonDisabled[frame] = nil 
			ColorPicker.StdUiObjects.backdrop.borderDisabled[frame] = nil 
		end 
		
		if not ColorPicker.StdUiObjects.backdrop[type][frame] then 
			ColorPicker.StdUiObjects.backdrop[type][frame]	 		= "SetBackdropColor"
		end 
		
		if not ColorPicker.StdUiObjects.backdrop[border][frame] then 
			ColorPicker.StdUiObjects.backdrop[border][frame]  		= "SetBackdropBorderColor"
		end 	
	end 
end)

hooksecurefunc(StdUi, "FrameTooltip", function(self, owner)
	-- StdUi v3 added a lot of bugs with tooltips, this code supposed to fix them 
	owner.stdUiTooltip:SetParent(UIParent)
	owner.stdUiTooltip:SetFrameStrata("TOOLTIP")
	owner.stdUiTooltip:SetClampedToScreen(true)
	local fs = owner.stdUiTooltip.text
	local _, oldHeight = fs:GetFont()
	fs:SetFontSize(oldHeight * 1.2) -- Retail used 1.2
	
	-- This is part of Color Picker 
	if not ColorPicker.StdUiObjects.font.color.tooltip[fs] then 
		ColorPicker.StdUiObjects.font.color.tooltip[fs] = "SetTextColor"
		local c = StdUi.config.font.color.tooltip
		fs:SetTextColor(c.r, c.g, c.b, c.a)
	end 
end)

-------------------------------------------------------------------------------
-- UI: LUA - Container
-------------------------------------------------------------------------------
local Functions = {}
local FormatedLuaCode = setmetatable({}, { __index = function(t, luaCode)
	t[luaCode] = setmetatable({}, { __index = function(tbl, thisunit)
		tbl[thisunit] = luaCode:gsub("thisunit", '"' .. thisunit .. '"') 
		return tbl[thisunit]
    end })
	return t[luaCode]
end })
local function GetCompiledFunction(luaCode, thisunit)
	local func, err
	luaCode = FormatedLuaCode[luaCode][thisunit or ""] 
	if Functions[luaCode] then
		return Functions[luaCode]
	end	

	func, err = loadstring(luaCode)
	
	if func then
		setfenv(func, setmetatable(Action, { __index = _G }))
		Functions[luaCode] = func
	end	
	return func, err
end; StdUi.GetCompiledFunction = GetCompiledFunction
local function RunLua(luaCode, thisunit)
	if not luaCode or luaCode == "" then 
		return true 
	end 
	
	local func = GetCompiledFunction(luaCode, thisunit)
	return func and func()
end; StdUi.RunLua = RunLua
function StdUi:CreateLuaEditor(parent, title, w, h, editTT)
	-- @return frame which is simular between WeakAura and TellMeWhen (if IndentationLib loaded, otherwise without effects like colors and tabulations)
	local LuaWindow = self:Window(parent, w, h, title)
	LuaWindow:SetShown(false)
	LuaWindow:SetFrameStrata("DIALOG")
	LuaWindow:SetMovable(false)
	LuaWindow:EnableMouse(false)
	self:GlueAfter(LuaWindow, Action.MainUI, 0, 0)	
	
	LuaWindow.UseBracketMatch = self:Checkbox(LuaWindow, L["TAB"]["BRACKETMATCH"])
	self:GlueTop(LuaWindow.UseBracketMatch, LuaWindow, 15, -15, "LEFT")
	
	LuaWindow.LineNumber = self:Subtitle(LuaWindow, "")
	LuaWindow.LineNumber:SetFontSize(14)
	self:GlueTop(LuaWindow.LineNumber, LuaWindow, 0, -30)
	
	local widget = self:MultiLineBox(LuaWindow, 100, 5, "") 
	widget.editBox.stdUi = self
	widget.scrollFrame.stdUi = self
	LuaWindow.EditBox = widget.editBox
	LuaWindow.EditBox:SetText("")
	LuaWindow.EditBox.panel:SetBackdropColor(0, 0, 0, 1)
	self:GlueAcross(LuaWindow.EditBox.panel, LuaWindow, 5, -50, -5, 5)
	
	if editTT then 
		self:FrameTooltip(LuaWindow.EditBox, editTT, nil, "TOPLEFT", "TOPLEFT")
	end 	
	
	-- The indention lib overrides GetText, but for the line number
	-- display we need the original, so save it here
	LuaWindow.EditBox.GetOriginalText = LuaWindow.EditBox.GetText
	-- ForAllIndentsAndPurposes
	local IndentationLib = _G.IndentationLib
	if IndentationLib then
		-- Monkai   
		local theme = {		
			["Table"] = "|c00ffffff",
			["Arithmetic"] = "|c00f92672",
			["Relational"] = "|c00ff3333",
			["Logical"] = "|c00f92672",
			["Special"] = "|c0066d9ef",
			["Keyword"] =  "|c00f92672",
			["Comment"] = "|c0075715e",
			["Number"] = "|c00ae81ff",
			["String"] = "|c00e6db74"
		}
  
		local color_scheme = { [0] = "|r" }
		color_scheme[IndentationLib.tokens.TOKEN_SPECIAL] = theme["Special"]
		color_scheme[IndentationLib.tokens.TOKEN_KEYWORD] = theme["Keyword"]
		color_scheme[IndentationLib.tokens.TOKEN_COMMENT_SHORT] = theme["Comment"]
		color_scheme[IndentationLib.tokens.TOKEN_COMMENT_LONG] = theme["Comment"]
		color_scheme[IndentationLib.tokens.TOKEN_NUMBER] = theme["Number"]
		color_scheme[IndentationLib.tokens.TOKEN_STRING] = theme["String"]

		color_scheme["..."] = theme["Table"]
		color_scheme["{"] = theme["Table"]
		color_scheme["}"] = theme["Table"]
		color_scheme["["] = theme["Table"]
		color_scheme["]"] = theme["Table"]

		color_scheme["+"] = theme["Arithmetic"]
		color_scheme["-"] = theme["Arithmetic"]
		color_scheme["/"] = theme["Arithmetic"]
		color_scheme["*"] = theme["Arithmetic"]
		color_scheme[".."] = theme["Arithmetic"]

		color_scheme["=="] = theme["Relational"]
		color_scheme["<"] = theme["Relational"]
		color_scheme["<="] = theme["Relational"]
		color_scheme[">"] = theme["Relational"]
		color_scheme[">="] = theme["Relational"]
		color_scheme["~="] = theme["Relational"]

		color_scheme["and"] = theme["Logical"]
		color_scheme["or"] = theme["Logical"]
		color_scheme["not"] = theme["Logical"]
		
		IndentationLib.enable(LuaWindow.EditBox, color_scheme, 4)		
	end 
	
	-- Bracket Matching
	LuaWindow.EditBox:SetScript("OnChar", function(self, char)		
		if not IsControlKeyDown() and LuaWindow.UseBracketMatch:GetChecked() then 
			if char == "(" then
				LuaWindow.EditBox:Insert(")")
				LuaWindow.EditBox:SetCursorPosition(LuaWindow.EditBox:GetCursorPosition() - 1)
			elseif char == "{" then
				LuaWindow.EditBox:Insert("}")
				LuaWindow.EditBox:SetCursorPosition(LuaWindow.EditBox:GetCursorPosition() - 1)
			elseif char == "[" then
				LuaWindow.EditBox:Insert("]")
				LuaWindow.EditBox:SetCursorPosition(LuaWindow.EditBox:GetCursorPosition() - 1)
			end	
		end 
	end)
		
	-- Update Line Number 
	LuaWindow.EditBox:HookScript("OnCursorChanged", function() 
		local cursorPosition = LuaWindow.EditBox:GetCursorPosition()
		local next = -1
		local line = 0
		while (next and cursorPosition >= next) do
			next = LuaWindow.EditBox.GetOriginalText(LuaWindow.EditBox):find("[\n]", next + 1)
			line = line + 1
		end
		LuaWindow.LineNumber:SetText(line)
	end)	
	
	-- Set manual black color (if enabled custom Color Picker)
	LuaWindow.EditBox:HookScript("OnShow", function(self)
		if A_GetToggle(1, "ColorPickerUse") then 
			self.panel:SetBackdropColor(0, 0, 0, 1)
		end 
	end)
	
	-- Close handlers 		
	LuaWindow.closeBtn:SetScript("OnClick", function(self) 
		LuaWindow.LineNumber:SetText(nil)
		local Code = LuaWindow.EditBox:GetText()
		local CodeClear = Code:gsub("[\r\n\t%s]", "")		
		if CodeClear ~= nil and CodeClear:len() > 0 then 
			-- Check user mistakes with quotes on thisunit 
			if Code:find("'thisunit'") or Code:find('"thisunit"') then 				
				LuaWindow.EditBox.LuaErrors = true	
				error("thisunit must be without quotes!")
				return
			end 
		
			-- Check syntax on errors
			local func, err = GetCompiledFunction(Code)
			if not func then 				
				LuaWindow.EditBox.LuaErrors = true	
				error(err or "Unexpected error in GetCompiledFunction function - Code exists in table but 'err' become 'nil'")
				return
			end 
			
			-- Check game API on errors
			local success, errorMessage = pcall(func)
			if not success then  					
				LuaWindow.EditBox.LuaErrors = true		
				error(errorMessage)
				return
			end 		
			
			LuaWindow.EditBox.LuaErrors = nil 
		else 
			LuaWindow.EditBox.LuaErrors = nil
			LuaWindow.EditBox:SetText("")
		end 
		self:GetParent():Hide()
	end)
	
	LuaWindow:SetScript("OnHide", function(self)
		self.closeBtn:Click() 
	end)
	
	LuaWindow.EditBox:SetScript("OnEscapePressed", function() 
		LuaWindow.closeBtn:Click() 
	end)
	
	return LuaWindow
end 

-- [3] LUA API 
function Action:GetLUA()
	return pActionDB[3][Action.PlayerSpec].luaActions[self:GetTableKeyIdentify()] 
end

function Action:SetLUA(luaCode)
	pActionDB[3][Action.PlayerSpec].luaActions[self:GetTableKeyIdentify()] = luaCode
end 

function Action:RunLua(thisunit)
	return RunLua(self:GetLUA(), thisunit)
end

-- [3] QLUA API 
function Action:GetQLUA()
	return pActionDB[3][Action.PlayerSpec].QluaActions[self:GetTableKeyIdentify()] 
end

function Action:SetQLUA(luaCode)
	pActionDB[3][Action.PlayerSpec].QluaActions[self:GetTableKeyIdentify()] = luaCode
end 

function Action:RunQLua(thisunit)
	return RunLua(self:GetQLUA(), thisunit)
end

-------------------------------------------------------------------------------
-- UI: Macro - Container
-------------------------------------------------------------------------------
local MacroAPI; MacroAPI = {
	spellgsub = function(s)
		local spellID = Action.toNum[s]
		local spellName = A_GetSpellInfo(spellID)
		return spellName or ""
	end,
	rank_localizations = {
		enUS = "Rank",
		ruRU = "Уровень",
		-- Unconfirmed:
		deDE = "Stufe",
		frFR = "Niveau",
		esES = "Rango",
		itIT = "Grado",
		ptBR = "Classe",
		koKR = "등급",
		zhCN = "等级",
		zhTW = "等級",
	},
	rankgsub = function(lvl)
		return strformat("(%s %s)", MacroAPI.rank_localizations[GameLocale] or MacroAPI.rank_localizations.enUS, lvl)
	end,
	Format = setmetatable({ 
			[""] = "",
		}, {
		__call = function(t, action, macro)
			if t[macro] then 
				return t[macro]
			end 
			
			-- thisID → action.SlotID or action.ID
			macro = macro:gsub("thisID", toStr(action.SlotID or action.ID))
			
			-- spell:%d+ → A_GetSpellInfo(%d+)
			macro = macro:gsub("spell:(%d+)", MacroAPI.spellgsub)
			
			-- (Rank %d+) → game client localized word
			macro = macro:gsub("%(Rank (%d+)%)", MacroAPI.rankgsub)

			t[macro] = macro		
			return macro
		end,
	}),	
	WipeFormat = function()
		-- This function used to update spellName in macros on talent and specialization change to avoid cache issues
		if InCombatLockdown() then
			MacroAPI.IsPendingWipeFormat = true
			return
		end
		
		wipe(MacroAPI.Format)
		MacroAPI.Format[""] = ""		
	end,
	WipeDefaultMacros = function()
		-- This function used to update [@mouseover] macro construction on GetToggle(2, "mouseover") change
		if InCombatLockdown() then
			MacroAPI.IsPendingWipeDefaultMacros = true
			return
		end
		
		MacroAPI.WipeFormat()
		local owner = isClassic and Action.PlayerClass or Action.PlayerSpec
		for k, v in pairs(Action[owner]) do
			if type(v) == "table" and v.Macro == "" then
				v:SetDefaultMacro()
			end
		end
		
		TMW:Fire("TMW_ACTION_METAENGINE_RECONFIGURE")
	end,
	PLAYER_REGEN_ENABLED = function()
		if MacroAPI.IsPendingWipeDefaultMacros then
			MacroAPI.WipeDefaultMacros() -- MacroAPI.WipeFormat() -> MacroAPI.WipeDefaultMacros()	
		elseif MacroAPI.IsPendingWipeFormat then
			MacroAPI.WipeFormat()
		end
		MacroAPI.IsPendingWipeDefaultMacros = nil
		MacroAPI.IsPendingWipeFormat = nil
	end,
	Reset = function(self)
		A_Listener:Remove("ACTION_EVENT_MACROAPI", "PLAYER_REGEN_ENABLED")
		A_Listener:Remove("ACTION_EVENT_MACROAPI", "PLAYER_TALENT_UPDATE")
		A_Listener:Remove("ACTION_EVENT_MACROAPI", "ACTIVE_TALENT_GROUP_CHANGED")
		TMW:UnregisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED")	
		self.IsPendingWipeDefaultMacros = nil
		self.IsPendingWipeFormat = nil
	end,
	Initialize = function(self)
		A_Listener:Add("ACTION_EVENT_MACROAPI", "PLAYER_REGEN_ENABLED", self.PLAYER_REGEN_ENABLED)
		A_Listener:Add("ACTION_EVENT_MACROAPI", "PLAYER_TALENT_UPDATE", self.WipeFormat)
		A_Listener:Add("ACTION_EVENT_MACROAPI", "ACTIVE_TALENT_GROUP_CHANGED", self.WipeFormat)
		TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", self.WipeFormat)	
	end,	
}

-- Doesn't need OnProfileChanged because we only wipe macros on changed spells to get correct name
-- Macro body obtained through self action and should not conflict with actions from previous profile
function StdUi:CreateMacroEditor(parent, title, w, h, editTT)
	-- @return frame
	local MacroWindow = self:Window(parent, w, h, title)
	MacroWindow:SetShown(false)
	MacroWindow:SetFrameStrata("DIALOG")
	MacroWindow:SetMovable(false)
	MacroWindow:EnableMouse(false)
	self:GlueBefore(MacroWindow, Action.MainUI, 0, 0)	
	
	MacroWindow.UseBracketMatch = self:Checkbox(MacroWindow, L["TAB"]["BRACKETMATCH"])
	self:GlueTop(MacroWindow.UseBracketMatch, MacroWindow, 15, -15, "LEFT")	
		
	MacroWindow.LineNumber = self:Subtitle(MacroWindow, "")
	MacroWindow.LineNumber:SetFontSize(14)
	self:GlueTop(MacroWindow.LineNumber, MacroWindow, 0, -30)
	
	local widget = self:MultiLineBox(MacroWindow, 100, 5, "") 
	widget.editBox.stdUi = self
	widget.scrollFrame.stdUi = self
	MacroWindow.EditBox = widget.editBox
	MacroWindow.EditBox:SetText("")
	MacroWindow.EditBox.panel:SetBackdropColor(0, 0, 0, 1)
	self:GlueAcross(MacroWindow.EditBox.panel, MacroWindow, 5, -50, -5, (h-50)/2+35)	
	
	local preview = self:MultiLineBox(MacroWindow, 100, 5, "") 
	preview.editBox.stdUi = self
	preview.scrollFrame.stdUi = self
	MacroWindow.Preview = preview.editBox
	MacroWindow.Preview:SetText("")
	MacroWindow.Preview:Disable()
	MacroWindow.Preview.panel:SetBackdropColor(0, 0, 0, 1)
	self:GlueAcross(MacroWindow.Preview.panel, MacroWindow, 5, -50-MacroWindow.EditBox.panel:GetHeight()-30, -5, 5)
	MacroWindow.Preview.Subtitle = self:Subtitle(MacroWindow, strformat(L["TAB"]["PREVIEWBYTES"], 0))
	MacroWindow.Preview.Subtitle:SetFontSize(14)
	MacroWindow.Preview.SkipNextTimer = 0
	self:GlueAbove(MacroWindow.Preview.Subtitle, MacroWindow.Preview, 0, 5, "TOP")
	
	if editTT then 
		self:FrameTooltip(MacroWindow.EditBox, editTT, nil, "TOPRIGHT", "TOPRIGHT")
	end 	
	
	-- The indention lib overrides GetText, but for the line number
	-- display we need the original, so save it here
	MacroWindow.EditBox.GetOriginalText = MacroWindow.EditBox.GetText
	-- ForAllIndentsAndPurposes
	local IndentationLib = _G.IndentationLib
	if IndentationLib then
		-- Monkai   
		local theme = {		
			["Table"] = "|c00ffffff",
			["Arithmetic"] = "|c00f92672",
			["Relational"] = "|c00ff3333",
			["Logical"] = "|c00f92672",
			["Special"] = "|c0066d9ef",
			["Keyword"] =  "|c00f92672",
			["Comment"] = "|c0075715e",
			["Number"] = "|c00ae81ff",
			["String"] = "|c00e6db74"
		}
  
		local color_scheme = { [0] = "|r" }
		color_scheme[IndentationLib.tokens.TOKEN_SPECIAL] = theme["Special"]
		color_scheme[IndentationLib.tokens.TOKEN_KEYWORD] = theme["Keyword"]
		-- Macros haven't comments
		--color_scheme[IndentationLib.tokens.TOKEN_COMMENT_SHORT] = theme["Comment"]
		--color_scheme[IndentationLib.tokens.TOKEN_COMMENT_LONG] = theme["Comment"]
		color_scheme[IndentationLib.tokens.TOKEN_NUMBER] = theme["Number"]
		color_scheme[IndentationLib.tokens.TOKEN_STRING] = theme["String"]

		color_scheme["..."] = theme["Table"]
		color_scheme["{"] = theme["Table"]
		color_scheme["}"] = theme["Table"]
		color_scheme["["] = theme["Table"]
		color_scheme["]"] = theme["Table"]

		color_scheme["+"] = theme["Arithmetic"]
		color_scheme["-"] = theme["Arithmetic"]
		color_scheme["/"] = theme["Arithmetic"]
		color_scheme["*"] = theme["Arithmetic"]
		color_scheme[".."] = theme["Arithmetic"]

		color_scheme["=="] = theme["Relational"]
		color_scheme["<"] = theme["Relational"]
		color_scheme["<="] = theme["Relational"]
		color_scheme[">"] = theme["Relational"]
		color_scheme[">="] = theme["Relational"]
		color_scheme["~="] = theme["Relational"]

		color_scheme["and"] = theme["Logical"]
		color_scheme["or"] = theme["Logical"]
		color_scheme["not"] = theme["Logical"]
		
		IndentationLib.enable(MacroWindow.EditBox, color_scheme, 4)		
	end 
	
	-- Bracket Matching and schedule Preview
	local pattern1 = "[ \t]*(.-)[ \t]*\r?\n" -- DON'T USE %s instead of white space, left and right trims each line
	local pattern2 = "\n*(.*[^\n])\n*" -- removes empty new lines before and after text
	function MacroWindow.Preview.SetFormattedMacro()
		local cleanMacro = strOnlyBuilder(MacroWindow.EditBox:GetText(), "\n"):gsub(pattern1, "%1\n"):gsub(pattern2, "%1")
		MacroWindow.Preview:SetText(MacroAPI.Format(MacroWindow.action, cleanMacro))
		MacroWindow.Preview.Subtitle:SetText(strformat(L["TAB"]["PREVIEWBYTES"], #cleanMacro))
	end
	
	MacroWindow.EditBox:SetScript("OnChar", function(self, char)		
		if not IsControlKeyDown() and MacroWindow.UseBracketMatch:GetChecked() then 
			if char == "(" then
				MacroWindow.EditBox:Insert(")")
				MacroWindow.EditBox:SetCursorPosition(MacroWindow.EditBox:GetCursorPosition() - 1)
			elseif char == "{" then
				MacroWindow.EditBox:Insert("}")
				MacroWindow.EditBox:SetCursorPosition(MacroWindow.EditBox:GetCursorPosition() - 1)
			elseif char == "[" then
				MacroWindow.EditBox:Insert("]")
				MacroWindow.EditBox:SetCursorPosition(MacroWindow.EditBox:GetCursorPosition() - 1)
			end	
		end 
		
		if TMW.time > MacroWindow.Preview.SkipNextTimer then
			MacroWindow.Preview:SetText("")
			MacroWindow.Preview.Subtitle:SetText(strformat(L["TAB"]["PREVIEWBYTES"], 0))
			Action.TimerSetRefreshAble("MacroWindow.Preview", 1.5, MacroWindow.Preview.SetFormattedMacro)
		end		
	end)

	-- Update Line Number and Text Size
	MacroWindow.EditBox:HookScript("OnCursorChanged", function() 
		local cursorPosition = MacroWindow.EditBox:GetCursorPosition()
		local next = -1
		local line = 0
		while (next and cursorPosition >= next) do
			next = MacroWindow.EditBox.GetOriginalText(MacroWindow.EditBox):find("[\n]", next + 1)
			line = line + 1
		end
		MacroWindow.LineNumber:SetText(line)		
	end)	
	
	-- Set manual black color (if enabled custom Color Picker)
	MacroWindow.EditBox:HookScript("OnShow", function(self)
		if A_GetToggle(1, "ColorPickerUse") then 
			self.panel:SetBackdropColor(0, 0, 0, 1)
		end 
	end)
	MacroWindow.Preview:HookScript("OnShow", function(self)
		if A_GetToggle(1, "ColorPickerUse") then 
			self.panel:SetBackdropColor(0, 0, 0, 1)
		end 
	end)	
	
	-- Close handlers 		
	MacroWindow.closeBtn:SetScript("OnClick", function(self) 
		local newUnformattedMacro = strOnlyBuilder(MacroWindow.EditBox:GetText(), "\n"):gsub(pattern1, "%1\n"):gsub(pattern2, "%1")
		local _, oldUnformattedMacro = MacroWindow.action:GetMacro()
		
		if newUnformattedMacro ~= oldUnformattedMacro and (oldUnformattedMacro ~= "" or #newUnformattedMacro > 3) then 
			-- Check user mistakes with quotes on thisID 
			if newUnformattedMacro:find("'thisID'") or newUnformattedMacro:find('"thisID"') then 				
				error("thisID must be without quotes!")
				return
			end 
			
			-- Check user mistakes with quotes on spell 
			if newUnformattedMacro:find("'spell'") or newUnformattedMacro:find('"spell"') then 				
				error("spell must be without quotes!")
				return
			end	
			
			if MacroWindow.action:CanSetMacro(newUnformattedMacro) then
				MacroWindow.action:SetUserMacro(newUnformattedMacro)
				Action.TimerDestroy("MacroWindow.Preview")
				if #newUnformattedMacro <= 3 then
					MacroWindow.Preview.SkipNextTimer = TMW.time + 2
					MacroWindow.EditBox:SetText(MacroWindow.action.Macro or "")
					MacroWindow.Preview.SetFormattedMacro()
					Action.TimerDestroy("MacroWindow.Preview")
				end
			else
				return -- prevents hide window, for example await out of combat to finish save
			end			
		end
		self:GetParent():Hide()		
	end)
	
	MacroWindow:SetScript("OnHide", function(self)
		self.closeBtn:Click() 
	end)
	
	MacroWindow.EditBox:SetScript("OnEscapePressed", function() 
		MacroWindow.closeBtn:Click() 
	end)
	
	return MacroWindow
end 

-- [3] Macro API
function Action:CanSetMacro(newMacro)
	if self.MacroForbidden or self.Hidden then 
		-- A_Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORMACRO"])
        return true -- just to allow to hide MacroEditor
	end
	
	if InCombatLockdown() then
		A_Print(L["MACROINCOMBAT"])
		return
	end
	
	if #newMacro > 255 then
		A_Print(L["MACROSIZE"])
		return	
	end
	
	return true
end

function Action:SetUserMacro(newMacro)
	-- Used on UI by user
	if newMacro == self.Macro or #newMacro <= 3 then
		-- Reset or removed or empty
		if not isClassic then 
			pActionDB[3][Action.PlayerSpec].macroActions[self:GetTableKeyIdentify()] = nil
		else
			pActionDB[3].macroActions[self:GetTableKeyIdentify()] = nil
		end
	else
		if not isClassic then 
			pActionDB[3][Action.PlayerSpec].macroActions[self:GetTableKeyIdentify()] = newMacro
		else
			pActionDB[3].macroActions[self:GetTableKeyIdentify()] = newMacro
		end
	end

	TMW:Fire("TMW_ACTION_METAENGINE_RECONFIGURE")
	return newMacro
end

function Action:SetDefaultMacro()
	-- Used on Create by default or profile
	-- Objective most of macros from this function can be used for generic meta1-5 setup because meta6-10 have different units
	local pattern
	
	if self.Type == "Spell" then
		pattern = "/cast spell:"
		
		if self:HasRange() then
			local hasfocus = BuildToC >= 20000 
			local togglemouseover = A_GetToggle(2, "mouseover")
			local togglefocus = A_GetToggle(2, "focus")
			local togglefocustarget = A_GetToggle(2, "focustarget")
			local toggletargettarget = A_GetToggle(2, "targettarget")
			if not hasfocus then
				togglefocus, togglefocustarget = false, false
			end
			if not Action.IamHealer then
				toggletargettarget, togglefocustarget = false, false
			end
	
			local isHelp = self:IsHelpful()
			local isHarm = self:IsHarmful()
			if isHelp and isHarm then
			  --[@mouseover,exists][@focus,help][@target,help][@target,harm][@focustarget,harm][@targettarget,harm][@player]
				local firstCDNT = not (togglefocustarget == false and toggletargettarget == false)
				local lastCNDT = not (togglemouseover == false and togglefocus == false and togglefocustarget == false and toggletargettarget == false)
				pattern = strOnlyBuilder(
					"/cast ", 	togglemouseover == false and 								"" or "[@mouseover,exists]", 
								togglefocus == false and 									"" or "[@focus,help]",
								not firstCDNT and 											"" or "[help][harm]",
								togglefocustarget == false and 								"" or "[@focustarget,harm]",
								toggletargettarget == false and 							"" or "[@targettarget,harm]",
								not lastCNDT and 											"" or "[]",											
																								  "spell:"
				)
			elseif isHelp then
			  --[@mouseover,help][@focus,help][@target,help][@player]
				local lastCNDT = not (togglemouseover == false and togglefocus == false)
				pattern = strOnlyBuilder(
					"/cast ", 	togglemouseover == false and 								"" or "[@mouseover,help]", 
								togglefocus == false and 									"" or "[@focus,help]",
								not lastCNDT and 											"" or "[]",									
																								  "spell:"
				)
			else
			  --[@mouseover,harm][@target,harm][@focustarget,harm][@targettarget,harm]
				local firstCDNT = not (togglefocustarget == false and toggletargettarget == false)
				local lastCNDT = not (togglemouseover == false and togglefocustarget == false and toggletargettarget == false)
				pattern = strOnlyBuilder(
					"/cast ", 	togglemouseover == false and 								"" or "[@mouseover,harm]", 
								not firstCDNT and 											"" or "[harm]",
								togglefocustarget == false and 								"" or "[@focustarget,harm]",
								toggletargettarget == false and 							"" or "[@targettarget,harm]",
								not lastCNDT and 											"" or "[]",											
																								  "spell:"
				)
			end
		end
	end
	
	if (self.Type == "Item" and self.SubType ~= "ItemBySlot") or (self.Type == "Trinket" and self.SubType ~= "TrinketBySlot") then
		pattern = "/use item:"
		
		if self:HasRange() then
			local hasfocus = BuildToC >= 20000 
			local togglemouseover = A_GetToggle(2, "mouseover")
			local togglefocus = A_GetToggle(2, "focus")
			local togglefocustarget = A_GetToggle(2, "focustarget")
			local toggletargettarget = A_GetToggle(2, "targettarget")
			if not hasfocus then
				togglefocus, togglefocustarget = false, false
			end
			if not Action.IamHealer then
				toggletargettarget, togglefocustarget = false, false
			end
			
			local isHelp = self:IsHelpful()
			local isHarm = self:IsHarmful()
			if isHelp and isHarm then
			  --[@mouseover,exists][@focus,help][@target,help][@target,harm][@focustarget,harm][@targettarget,harm][@player]
				local firstCDNT = not (togglefocustarget == false and toggletargettarget == false)
				local lastCNDT = not (togglemouseover == false and togglefocus == false and togglefocustarget == false and toggletargettarget == false)
				pattern = strOnlyBuilder(
					"/use ", 	togglemouseover == false and 								"" or "[@mouseover,exists]", 
								togglefocus == false and 									"" or "[@focus,help]",
								not firstCDNT and 											"" or "[help][harm]",
								togglefocustarget == false and 								"" or "[@focustarget,harm]",
								toggletargettarget == false and 							"" or "[@targettarget,harm]",
								not lastCNDT and 											"" or "[]",											
																								  "item:"
				)
			elseif isHelp then
			  --[@mouseover,help][@focus,help][@target,help][@player]
				local lastCNDT = not (togglemouseover == false and togglefocus == false)
				pattern = strOnlyBuilder(
					"/use ", 	togglemouseover == false and 								"" or "[@mouseover,help]", 
								togglefocus == false and 									"" or "[@focus,help]",
								not lastCNDT and 											"" or "[]",											
																								  "item:"
				)
			else
			  --[@mouseover,harm][@target,harm][@focustarget,harm][@targettarget,harm]
				local firstCDNT = not (togglefocustarget == false and toggletargettarget == false)
				local lastCNDT = not (togglemouseover == false and togglefocustarget == false and toggletargettarget == false)				
				pattern = strOnlyBuilder(
					"/use ", 	togglemouseover == false and 								"" or "[@mouseover,harm]", 
								not firstCDNT and  											"" or "[harm]",
								togglefocustarget == false and 								"" or "[@focustarget,harm]",
								toggletargettarget == false and 							"" or "[@targettarget,harm]",
								not lastCNDT and 											"" or "[]",											
																								  "item:"
				)
			end
		end
	end
	
	if self.Type == "Potion" then
		pattern = "/use item:"
	end
	
	if self.SubType == "TrinketBySlot" or self.SubType == "ItemBySlot" then
		pattern = "/use "
	end
		
	local patternRank = ""
	if self.Type == "Spell" then
		if self.isRank then
			patternRank = Action.strOnlyBuilder("(Rank ", self.isRank, ")")	
		elseif self.useMinRank then		
			local rangeRank
			if type(self.useMinRank) == "table" then
				rangeRank = math_min(unpack(self.useMinRank))
			end
			patternRank = Action.strOnlyBuilder("(Rank ", rangeRank or 1, ")")
		elseif self.useMaxRank then
			local rangeRank
			if type(self.useMaxRank) == "table" then
				rangeRank = math_max(unpack(self.useMaxRank))
			end
			patternRank = Action.strOnlyBuilder(rangeRank or "")
		end
	end
	
	assert(pattern, "Action:SetDefaultMacro can't recognize pattern is 'nil' for ID " .. (self.SlotID or self.ID))
	self.Macro = Action.strOnlyBuilder(
		pattern,
		self.SlotID or self.ID,					
		patternRank
	)
	
	return self.Macro
end

function Action:GetMacro()
	-- @return @string formattedMacro, @string unformattedMacro, @boolean isUserMacro
	-- Priority if not forbidden
	-- 	User's macros → Profile macros → Default macros
	-- otherwise
	--	Profile macros → Default macros
	if self.Hidden then
		return "", "", false
	end
	
	if self.MacroForbidden then
		return MacroAPI.Format(self, self.Macro), self.Macro, false
	end
	
	local userMacro 
	if not isClassic then
		userMacro = pActionDB[3][Action.PlayerSpec].macroActions[self:GetTableKeyIdentify()]
	else
		userMacro = pActionDB[3].macroActions[self:GetTableKeyIdentify()]
	end
	
	return MacroAPI.Format(self, userMacro or self.Macro), userMacro or self.Macro, userMacro and true
end

-------------------------------------------------------------------------------
-- UI: MetaEngine - Container
-------------------------------------------------------------------------------
-- Actions
function Action:SetDefaultAction()
	-- Used on Create by default or profile	
	if not self.Hidden and self.Macro == "" and (self.Type == "Spell" or self.Type == "Item" or self.Type == "Potion" or self.Type == "Trinket") then		
		-- Macro
		if not self.Click and self.Type ~= "Spell" then 
			-- since itemName is not available at login without cache and Click often doesn't work on itemID, the best remaining solution is Macro unless profile sets Click
			self:SetDefaultMacro()
			return
		end
		
		-- Click		
		local Click = self.Click or {}
		self.Click = Click
		Click.type = Click.type or (self.Type == "Spell" and "spell") or "item"
		Click.typerelease = Click.typerelease or Click.type
		
		if Click.type == "spell" then
			Click.item = Click.item or "nil"
			if not Click.spell then
				if self.isRank then
					local pattern = Action.strOnlyBuilder("spell:", self.ID, "(Rank ", self.isRank, ")")
					Click.spell = MacroAPI.Format(self, pattern)
				elseif self.useMinRank then		
					local rangeRank
					if type(self.useMinRank) == "table" then
						rangeRank = math_min(unpack(self.useMinRank))
					end
					local pattern = Action.strOnlyBuilder("spell:", self.ID, "(Rank ", rangeRank or 1, ")")
					Click.spell = MacroAPI.Format(self, pattern)
				elseif self.useMaxRank then
					local rangeRank
					if type(self.useMaxRank) == "table" then
						rangeRank = math_max(unpack(self.useMaxRank))
					end
					local pattern = Action.strOnlyBuilder("spell:", self.ID, rangeRank or "")
					Click.spell = MacroAPI.Format(self, pattern)
				else
					Click.spell = self:Info()
				end
			end
		elseif Click.type == "item" then
			-- itemID or itemName or bag, slot = "^(%d+)%s+(%d+)$") → slot = "^(%d+)$"
			Click.item = Click.item or self.SlotID or self.ID
			Click.spell = Click.spell or "nil"
		elseif Click.type == "cancelaura" then		
			Click.item = Click.item or "nil"
			-- "unit", "spell"[, "rank"] → "target-slot" → "index"[, "filter"]
			if not Click["target-slot"] and not Click.index then
				-- "unit", "spell"[, "rank"]
				Click.spell = Click.spell or self:Info()
				Click.unit = Click.unit or "player"
				if not Click.rank then
					if self.isRank then
						Click.rank = self.isRank
					elseif self.useMinRank then		
						local rangeRank = 1
						if type(self.useMinRank) == "table" then
							rangeRank = math_min(unpack(self.useMinRank))
						end
						Click.rank = rangeRank
					elseif self.useMaxRank then
						local rangeRank = "nil"
						if type(self.useMaxRank) == "table" then
							rangeRank = math_max(unpack(self.useMaxRank))
						end
						Click.rank = rangeRank
					else
						Click.rank = "nil"
					end
				end
			elseif Click["target-slot"] then
				-- "target-slot"
				Click.spell = "nil"
				Click.index = "nil"			
			elseif Click.index then				
				-- "index"[, "filter"]
				Click.spell = "nil"
				Click["target-slot"] = "nil"
			end
		end

		if not Click.unit and not Click.autounit then
			local isHelp = self:IsHelpful()
			local isHarm = self:IsHarmful()		
			Click.autounit = (isHelp and isHarm and "both") or (isHelp and "help") or (isHarm and "harm") or "both" -- the last is fallback			
		end
		if Click.autounit then
			Click.unit = "nil" -- fault protection
		end
		
		assert(Click.type ~= "macro" and Click.typerelease ~= "macro", 'Click cannot be "macro" for ID ' .. (self.SlotID or self.ID))
		assert(not Click.autounit or Click.autounit == "harm" or Click.autounit == "help" or Click.autounit == "both", '"autounit" used with wrong value for ID ' .. (self.SlotID or self.ID))		
	end	
	
	assert(type(self.Macro) == "string", "Macro must be string for ID " .. (self.SlotID or self.ID))
end

-- Keybindings
TMW:RegisterSelfDestructingCallback("TMW_ACTION_METAENGINE_AUTH", function()
	-- There is no event like UPDATE_BINDINGS, so lets do custom, regardless of active engine as this is just UI visuals
	local function OVERRIDE_UPDATE_BINDINGS(owner, isPriority, key, ...)
		if isPriority and not owner.ClearAttributes then
			local Hotkeys
			if not isClassic then				
				Hotkeys = pActionDB[9][Action.PlayerSpec].MetaEngine.Hotkeys
			else
				Hotkeys = pActionDB[9].MetaEngine.Hotkeys
			end
			
			for slot, v in pairs(Hotkeys) do
				if key == v.hotkey then
					v.hotkey = ""
					TMW:Fire("TMW_ACTION_METAENGINE_REFRESH_UI")
					return
				end
			end
		end
	end
	
	hooksecurefunc(_G, "SetOverrideBinding", OVERRIDE_UPDATE_BINDINGS)
	hooksecurefunc(_G, "SetOverrideBindingClick", OVERRIDE_UPDATE_BINDINGS)
	hooksecurefunc(_G, "SetOverrideBindingItem", OVERRIDE_UPDATE_BINDINGS)
	hooksecurefunc(_G, "SetOverrideBindingMacro", OVERRIDE_UPDATE_BINDINGS)
	hooksecurefunc(_G, "SetOverrideBindingSpell", OVERRIDE_UPDATE_BINDINGS)

	return true
end)

-------------------------------------------------------------------------------
-- UI: API
-------------------------------------------------------------------------------
-- [1] Mode 
function Action.ToggleMode()
	Action.IsLockedMode = true
	Action.IsInPvP = not Action.IsInPvP	
	A_Print(L["SELECTED"] .. ": " .. (Action.IsInPvP and "PvP" or "PvE"))
	TMW:Fire("TMW_ACTION_MODE_CHANGED")
end 

-- [1] Burst 
ActionDataPrintCache.ToggleBurst = {1, "Burst"}
function Action.ToggleBurst(fixed, between)
	local Current = A_GetToggle(1, "Burst")
	
	local set
	if between and fixed ~= between then 	
		if Current == fixed then 
			set = between
		else 
			set = fixed
		end 
	end 
	
	if Current ~= "Off" then 		
		ActionDataTG.Burst = Current
		Current = "Off"
	elseif ActionDataTG.Burst == nil then  
		Current = "Everything"
		ActionDataTG.Burst = Current
	else
		Current = ActionDataTG.Burst
	end 			
	
	ActionDataPrintCache.ToggleBurst[3] = L["TAB"][1]["BURST"] .. ": "
	A_SetToggle(ActionDataPrintCache.ToggleBurst, set or fixed or Current)	
end 

function Action.BurstIsON(unitID)	
	-- @return boolean
	local Current = A_GetToggle(1, "Burst")
	
	if Current == "Auto" then  
		local unit = unitID or "target"
		return A_Unit(unitID):IsPlayer() or A_Unit(unitID):IsBoss()
	elseif Current == "Everything" then 
		return true 
	end 		
	
	return false 			
end 

-- [1] Racial 
function Action.RacialIsON(self)
	-- @usage Action.RacialIsON() or Action:RacialIsON()
	-- @return boolean
	return A_GetToggle(1, "Racial") and (not self or self:IsExists())
end 

-- [1] ReTarget // ReFocus
local Re; Re = {
	Units = { "arena1", "arena2", "arena3", "arena4", "arena5" },
	-- Textures 
	target = {
		["arena1"] = ActionConst.PVP_TARGET_ARENA1,
		["arena2"] = ActionConst.PVP_TARGET_ARENA2,
		["arena3"] = ActionConst.PVP_TARGET_ARENA3,
		["arena4"] = ActionConst.PVP_TARGET_ARENA4,
		["arena5"] = ActionConst.PVP_TARGET_ARENA5,
	},
	focus = {
		["arena1"] = ActionConst.PVP_FOCUS_ARENA1,
		["arena2"] = ActionConst.PVP_FOCUS_ARENA2,
		["arena3"] = ActionConst.PVP_FOCUS_ARENA3,
		["arena4"] = ActionConst.PVP_FOCUS_ARENA4,
		["arena5"] = ActionConst.PVP_FOCUS_ARENA5,
	},	
	-- OnEvent 
	PLAYER_TARGET_CHANGED = function()
		if (Action.Zone == "arena" or Action.Zone == "pvp") then 			
			if UnitExists("target") then 
				Re.LastTargetIsExists = true 
				for i = 1, #Re.Units do
					if UnitIsUnit("target", Re.Units[i]) then 
						Re.LastTargetUnitID = Re.Units[i]
						Re.LastTargetTexture = Re.target[Re.LastTargetUnitID]
						break
					end 
				end 
			else
				Re.LastTargetIsExists = false 
			end 
		end 		
	end,	
	PLAYER_FOCUS_CHANGED = function()
		if (Action.Zone == "arena" or Action.Zone == "pvp") then 
			if UnitExists("focus") then 
				Re.LastFocusIsExists = true 
				for i = 1, #Re.Units do 
					if UnitIsUnit("focus", Re.Units[i]) then 
						Re.LastFocusUnitID = Re.Units[i]
						Re.LastFocusTexture = Re.focus[Re.LastFocusUnitID]
						break
					end 
				end 
			else
				Re.LastFocusIsExists = false 
			end 
		end 
	end,
	-- OnInitialize, OnProfileChanged
	Reset 			= function(self)	
		A_Listener:Remove("ACTION_EVENT_RE", 	 "PLAYER_TARGET_CHANGED")
		A_Listener:Remove("ACTION_EVENT_RE", 	 "PLAYER_FOCUS_CHANGED")
		self.LastTargetIsExists	 	= nil
		self.LastTargetUnitID 	 	= nil 
		self.LastTargetTexture 	 	= nil 
		self.LastFocusIsExists 	 	= nil 
		self.LastFocusUnitID 	 	= nil
		self.LastFocusTexture 	 	= nil

		Action.Re:ClearTarget()
		Action.Re:ClearFocus()
	end,
	Initialize		= function(self)	
		if A_GetToggle(1, "ReTarget") then 
			A_Listener:Add(   "ACTION_EVENT_RE", "PLAYER_TARGET_CHANGED", self.PLAYER_TARGET_CHANGED)
			self.PLAYER_TARGET_CHANGED()
		else 
			A_Listener:Remove("ACTION_EVENT_RE", "PLAYER_TARGET_CHANGED")
			self.LastTargetIsExists	= nil
			self.LastTargetUnitID 	= nil 
			self.LastTargetTexture 	= nil 			
		end 
		
		if A_GetToggle(1, "ReFocus") then 
			A_Listener:Add(   "ACTION_EVENT_RE", "PLAYER_FOCUS_CHANGED",  self.PLAYER_FOCUS_CHANGED)
			self.PLAYER_FOCUS_CHANGED()
		else 
			A_Listener:Remove("ACTION_EVENT_RE", "PLAYER_FOCUS_CHANGED")
			self.LastFocusIsExists 	= nil 
			self.LastFocusUnitID 	= nil
			self.LastFocusTexture 	= nil			
		end 		
	end,
}

Action.Re = {
	-- Target 
	SetTarget 	= function(self, unitID)
		-- Creates schedule to set in target the 'unitID'
		if not Re.target[unitID] then 
			error("Action.Re:SetTarget must have valid for own API the 'unitID' param. Input: " .. (unitID or "nil"))
			return 
		end
		
		Re.ManualTargetUnitID 	= unitID
		Re.ManualTargetTexture 	= Re.target[unitID]
	end,	
	ClearTarget = function(self)
		Re.ManualTargetUnitID 	= nil 
		Re.ManualTargetTexture 	= nil 		
	end,
	CanTarget	= function(self, icon)
		-- @return boolean 
		-- Note: Only for internal use for Core.lua
		if not Re.LastTargetIsExists and Re.LastTargetTexture and UnitExists(Re.LastTargetUnitID) then 
			return Action:Show(icon, Re.LastTargetTexture)
		end 
		
		if Re.ManualTargetTexture and UnitExists(Re.ManualTargetUnitID) then 
			if UnitIsUnit("target", Re.ManualTargetUnitID) then 				
				return self:ClearTarget() 
			else 
				return Action:Show(icon, Re.ManualTargetTexture)
			end 
		end 
	end,
	-- Focus 
	SetFocus 	= function(self, unitID)
		-- Creates schedule to set in focus the 'unitID'
		if not Re.focus[unitID] then 
			error("Action.Re:SetFocus must have valid for own API the 'unitID' param. Input: " .. (unitID or "nil"))
			return 
		end
		
		Re.ManualFocusUnitID 	= unitID
		Re.ManualFocusTexture 	= Re.focus[unitID]
	end,	
	ClearFocus 	= function(self)
		Re.ManualFocusUnitID 	= nil 
		Re.ManualFocusTexture 	= nil 		
	end,
	CanFocus	= function(self, icon)
		-- @return boolean 
		-- Note: Only for internal use for Core.lua
		if not Re.LastFocusIsExists and Re.LastFocusTexture and UnitExists(Re.LastFocusUnitID) then 
			return Action:Show(icon, Re.LastFocusTexture)
		end 
		
		if Re.ManualFocusTexture and UnitExists(Re.ManualFocusUnitID) then 
			if UnitIsUnit("focus", Re.ManualFocusUnitID) then 				
				return self:ClearFocus() 
			else 
				return Action:Show(icon, Re.ManualFocusTexture)
			end 
		end 
	end,
}

-- [1] LOS System (Line of Sight)
local LineOfSight = {
	Cache 			= setmetatable({}, { __mode = "kv" }),
	Timer			= 5,	
	TimerHE			= 8,
	NamePlateFrame	= setmetatable({}, { __index = function(t, i)
		if _G["NamePlate" .. i] then 
			t[i] = _G["NamePlate" .. i]
			return t[i]
		end 
	end }),
	-- Functions
	UnitInLOS 		= function(self, unitID, unitGUID)		
		if Action.IsInitialized and not A_GetToggle(1, "LOSCheck") then  -- TODO: Remove Action.IsInitialized (old profiles)
			return false 
		end 

		if not UnitIsUnit("target", unitID) and A_Unit(unitID):IsNameplateAny() then 
			-- Not valid for @target
			local UnitFrame, NamePlateFrame
			for i = 1, huge do 
				NamePlateFrame = self.NamePlateFrame[i]
				if not NamePlateFrame then 
					break 
				else
					UnitFrame = NamePlateFrame.UnitFrame
					if UnitFrame and UnitFrame.unitExists and UnitIsUnit(UnitFrame.unit, unitID) then
						return UnitFrame:GetEffectiveAlpha() <= 0.400001
					end		
				end 
			end 
		else 
			local GUID = unitGUID or UnitGUID(unitID)
			-- If not exists (GUID check) or in GetLOS cache and less than expiration time means in the loss of sight 
			return not GUID or (self.Cache[GUID] and TMW.time < self.Cache[GUID])
		end 
	end,
	Wipe 			= function(self)
		-- Physical reset 
		self.PhysicalUnitID 	= nil
		self.PhysicalUnitGUID	= nil	
		self.PhysicalUnitWait 	= nil
	end,
	Reset 			= function(self)		
		A_Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"UI_ERROR_MESSAGE")
		A_Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"COMBAT_LOG_EVENT_UNFILTERED")
		A_Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"PLAYER_REGEN_ENABLED")
		A_Listener:Remove("ACTION_EVENT_LOS_SYSTEM", 	"PLAYER_REGEN_DISABLED")
		self:Wipe()
		wipe(self.Cache)	
	end,
	-- OnEvent
	UI_ERROR_MESSAGE = function(self, ...)
		if (Action.IsInitialized or _G.LOSCheck) and select(2, ...) == ActionConst.SPELL_FAILED_LINE_OF_SIGHT then   -- TODO: Remove Action.IsInitialized and _G.LOSCheck (old profiles)
			if self.PhysicalUnitID and TMW.time >= self.PhysicalUnitWait then 
				if self.PhysicalUnitGUID then 
					self.Cache[self.PhysicalUnitGUID] = TMW.time + self.TimerHE
				else 
					local GUID = UnitGUID(self.PhysicalUnitID)
					if GUID then 
						self.Cache[GUID] = TMW.time + self.Timer
					end 
				end 
				
				self:Wipe()				
			end 
		end 	
	end,
	COMBAT_LOG_EVENT_UNFILTERED = function(self, ...)
		if Action.IsInitialized or _G.LOSCheck then -- TODO: Remove Action.IsInitialized and _G.LOSCheck (old profiles)
			local _, event, _, SourceGUID, _,_,_, DestGUID = CombatLogGetCurrentEventInfo()	
			if event == "SPELL_CAST_SUCCESS" and self.Cache[DestGUID] and SourceGUID and SourceGUID == A_TeamCacheFriendlyUNITs.player then 
				self.Cache[DestGUID] = nil 
				if self.PhysicalUnitID and DestGUID == (self.PhysicalUnitGUID or UnitGUID(self.PhysicalUnitID)) then 
					self:Wipe()
				end 
			end 	
		end 
	end,
	Initialize		= function(self, isLaunchOLD) -- TODO: Remove isLaunchOLD (old profiles)
		if (isLaunchOLD == nil and A_GetToggle(1, "LOSCheck")) or (isLaunchOLD ~= nil and isLaunchOLD == true) then 	
			A_Listener:Add("ACTION_EVENT_LOS_SYSTEM", "UI_ERROR_MESSAGE", 				function(...) self:UI_ERROR_MESSAGE(...) 			end)
			A_Listener:Add("ACTION_EVENT_LOS_SYSTEM", "COMBAT_LOG_EVENT_UNFILTERED", 	function(...) self:COMBAT_LOG_EVENT_UNFILTERED(...) end)
			A_Listener:Add("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_ENABLED", 			function() 	  wipe(self.Cache)						end)
			A_Listener:Add("ACTION_EVENT_LOS_SYSTEM", "PLAYER_REGEN_DISABLED", 			function() 	  wipe(self.Cache)						end)
		else 			
			self:Reset()			
		end 
	end,
}

function Action.SetTimerLOS(timer, isTarget)
	-- Sets timer for non-@target\@target units to skip them during 'timer' (seconds) after message receive
	if isTarget then 
		LineOfSight.TimerHE = timer 
	else 
		LineOfSight.Timer = timer 
	end 
end 

function Action.UnitInLOS(unitID, unitGUID)
	-- @return boolean
	return LineOfSight:UnitInLOS(unitID, unitGUID)
end 

function _G.GetLOS(unitID) 
	-- External physical button use 
	if (not Action.IsInitialized and _G.LOSCheck) or (Action.IsInitialized and A_GetToggle(1, "LOSCheck")) then -- TODO: Remove LOSCheck (old profiles)		
		if not A_IsActiveGCD() and (not LineOfSight.PhysicalUnitID or TMW.time > LineOfSight.PhysicalUnitWait) and (unitID ~= "target" or not LineOfSight.PhysicalUnitWait or TMW.time > LineOfSight.PhysicalUnitWait + 1) and not A_UnitInLOS(unitID) then 
			LineOfSight.PhysicalUnitID = unitID
			if unitID == "target" then 
				LineOfSight.PhysicalUnitGUID = UnitGUID(unitID)
			end 
			-- 0.3 seconds is how much time need wait before start trigger message because if make it earlier it can trigger message from another unit  
			LineOfSight.PhysicalUnitWait = TMW.time + 0.3 
		end 
	end 
end 

-- [1] HideOnScreenshot
local ScreenshotHider = {
	HiddenFrames	  = {},
	-- OnEvent 
	OnStart			  = function(self)
		if Action.IsInitialized then 
			-- TellMeWhen 
			for i = 1, huge do 
				local FrameName = "TellMeWhen_Group" .. i
				if _G[FrameName] then 
					if _G[FrameName]:IsShown() then 
						tinsert(self.HiddenFrames, FrameName)
						_G[FrameName]:Hide()
					end 
				else 
					break 
				end 
			end 	
			
			-- UI 
			if Action.MainUI and Action.MainUI:IsShown() then 
				tinsert(self.HiddenFrames, "MainUI")
				A_ToggleMainUI()
			end 
			
			if A_MinimapIsShown() then 
				tinsert(self.HiddenFrames, "Minimap")
				A_ToggleMinimap(false)
			end 
			
			if A_BlackBackgroundIsShown() then 
				tinsert(self.HiddenFrames, "BlackBackground")
				A_BlackBackgroundSet(false)
			end 
		end 
	end,
	OnStop			  = function(self)
		if #self.HiddenFrames > 0 then 
			for i = 1, #self.HiddenFrames do 
				if self.HiddenFrames[i] == "MainUI" then 
					A_ToggleMainUI()
				elseif self.HiddenFrames[i] == "Minimap" then 
					A_ToggleMinimap(true)
				elseif self.HiddenFrames[i] == "BlackBackground" then 
					A_BlackBackgroundSet(true)	
				elseif _G[self.HiddenFrames[i]] then 
					_G[self.HiddenFrames[i]]:Show()
				end 
			end 
			
			wipe(self.HiddenFrames)
		end 	
	end,
	-- UI 
	Reset			= function(self)
		A_Listener:Remove("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_STARTED"		)
		A_Listener:Remove("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_FAILED"		)
		A_Listener:Remove("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_SUCCEEDED"		)
		self:OnStop()
	end,
	Initialize 		 = function(self)
		if A_GetToggle(1, "HideOnScreenshot") then 
			A_Listener:Add("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_STARTED", 	function() self:OnStart() end)
			A_Listener:Add("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_FAILED", 		function() self:OnStop()  end)
			A_Listener:Add("ACTION_EVENT_SCREENSHOT", "SCREENSHOT_SUCCEEDED", 	function() self:OnStop()  end)
		else 
			self:Reset()
		end 
	end,	
}; Action.ScreenshotHider = ScreenshotHider

-- [1] PlaySound 
function Action.PlaySound(sound)
	if not A_GetToggle(1, "DisableSounds") then 
		PlaySound(sound)
	end 
end 

-- [2] AoE toggle through Ctrl+Left Click on main picture 
ActionDataPrintCache.ToggleAoE = {2, "AoE"}
function Action.ToggleAoE()
	A_SetToggle(ActionDataPrintCache.ToggleAoE)
end 

-- [3] SpellLevel (skipping unknown spells by character level)
local SpellLevel; SpellLevel 		= { 
	Blocked 						= {},
	SetToggle 						= {3, "CheckSpellLevel"},
	SetName							= {3, "LastDisableName"}, -- In case if user log on character which has not max level then it will be reseted until manual assign it back to disable
	GetLevel						= function(self)
		return Action.PlayerLevel or UnitLevel("player")
	end,
	GetMaxLevelXpac					= function(self)
		if Action.BuildToC >= 90001 then 
			return GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion() or 60
		else
			return _G.MAX_PLAYER_LEVEL_TABLE[_G.GetExpansionLevel()]
		end 
	end,
	Reset 							= function(self)	
		if pActionDB and pActionDB[3] then 
			pActionDB[3].CheckSpellLevel = false 
			pActionDB[3].LastDisableName = UnitName("player") or "" 
		end 
	
		if self.Initialized then 
			TMW:UnregisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", self.PLAYER_SPECIALIZATION_CHANGED)
			-- A_Listener:Remove("ACTION_EVENT_SPELLLEVEL", "LEARNED_SPELL_IN_TAB") -- Removed since TWW
			A_Listener:Remove("ACTION_EVENT_SPELLLEVEL", "PLAYER_LEVEL_UP")
			
			self.Initialized = nil
			A_WipeTableKeyIdentify()
			wipe(self.Blocked)						
			
			TMW:Fire("TMW_ACTION_SPELL_BOOK_CHANGED")
		end 
	end,
	Update							= function(self)
		A_WipeTableKeyIdentify()
		wipe(self.Blocked)
		
		local book, slot, availableLevel
		for _, v in pairs(Action[Action.PlayerSpec]) do 
			if type(v) == "table" and v.Type == "Spell" and type(v.ID) == "number" then 
				book, slot 		= BOOKTYPE_SPELL,  	FindSpellBookSlotBySpellID(v.ID, false)  
				if not slot then 
					book, slot 	= BOOKTYPE_PET, 	FindSpellBookSlotBySpellID(v.ID, true)
				end 
				
				if slot then 
					availableLevel = GetSpellAvailableLevel(slot, book)						
					if availableLevel and availableLevel > self:GetLevel() then 
						self.Blocked[v.ID] = true 
					end 
				end
			end 
		end 
		
		TMW:Fire("TMW_ACTION_SPELL_BOOK_CHANGED")
	end,
	PLAYER_LEVEL_UP					= function(...)
		local level 		= ... or UnitLevel("player")
		Action.PlayerLevel 	= level
		if level >= SpellLevel:GetMaxLevelXpac() then 
			A_Print(L["DEBUG"] .. L["TAB"][3]["CHECKSPELLLVLERRORMAXLVL"])
			SpellLevel:Reset(true)		
			TMW:Fire("TMW_ACTION_SPELL_BOOK_MAX_LEVEL") -- To disable checkbox
		elseif not Action[Action.PlayerSpec] then 
			SpellLevel:Reset()
		else 				
			SpellLevel:Update()
		end 			
	end,
	PLAYER_SPECIALIZATION_CHANGED	= function()
		if not Action[Action.PlayerSpec] then 
			SpellLevel:Reset()
		else 
			SpellLevel:Update()
		end 
	end,
	Initialize						= function(self)	
		if Action[Action.PlayerSpec] and self:GetLevel() < SpellLevel:GetMaxLevelXpac() then 
			local CheckSpellLevel = A_GetToggle(3, "CheckSpellLevel")
			if not CheckSpellLevel and UnitName("player") ~= A_GetToggle(3, "LastDisableName") then 
				self.SetToggle[3] = L["TAB"][3]["CHECKSPELLLVL"] .. ": "
				A_SetToggle(self.SetToggle, true)
				CheckSpellLevel = true 
			end 
			
			if CheckSpellLevel then 
				if not self.Initialized then 
					TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", 		self.PLAYER_SPECIALIZATION_CHANGED)
					-- A_Listener:Add("ACTION_EVENT_SPELLLEVEL", "LEARNED_SPELL_IN_TAB", 		self.PLAYER_SPECIALIZATION_CHANGED)	-- Removed since TWW
					A_Listener:Add("ACTION_EVENT_SPELLLEVEL", "PLAYER_LEVEL_UP", 			self.PLAYER_LEVEL_UP)					
					self:Update()
					self.Initialized = true
				--else 
					--A_Print(L["DEBUG"] .. L["TAB"][3]["CHECKSPELLLVLERROR"])
				end 
			else 
				self:Reset()
			end 
		else
			self:Reset()
		end 		
	end,
	-- Test: /run MAX_PLAYER_LEVEL_TABLE[GetExpansionLevel()] = 1; Action.Listener:Trigger("PLAYER_LEVEL_UP", 1) 				-- Until Shadowlands
	-- Test: /run _G.GetMaxLevelForPlayerExpansion = function() return 60 end; Action.Listener:Trigger("PLAYER_LEVEL_UP", 60) 	-- Since Shadowlands
}

function Action:IsBlockedBySpellLevel()
	-- @return boolean
	return SpellLevel.Initialized and SpellLevel.Blocked[self.ID]
end 

-- [3] SetBlocker 
function Action:IsBlocked()
	-- @return boolean 
	return pActionDB[3][Action.PlayerSpec].disabledActions[self:GetTableKeyIdentify()] == true
end

function Action:SetBlocker()
	-- Sets block on action
	-- Note: /run Action[Action.PlayerSpec].WordofGlory:SetBlocker()
	if self.BlockForbidden and not self:IsBlocked() then 
		A_Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORBLOCK"])
        return 		
	end 
	
	local Identify = self:GetTableKeyIdentify()
	if self:IsBlocked() then 
		pActionDB[3][Action.PlayerSpec].disabledActions[Identify] = nil 
		A_Print(L["TAB"][3]["UNBLOCKED"] .. self:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify:gsub("nil", "") .. "]")
	else 
		pActionDB[3][Action.PlayerSpec].disabledActions[Identify] = true
		A_Print(L["TAB"][3]["BLOCKED"] .. self:Link() .. " " ..  L["TAB"][3]["KEY"] .. Identify:gsub("nil", "") .. "]")
	end 
	
	TMW:Fire("TMW_ACTION_SET_BLOCKER_CHANGED", self)
end

function Action.MacroBlocker(key)
	-- Sets block on action with avoid lua errors for non exist key
	local object = A_GetActionTableByKey(key)
	if not object then 
		A_Print(L["DEBUG"] .. (key or "") .. " " .. L["ISNOTFOUND"])
		return 	 
	end 
	object:SetBlocker()
end

-- [3] SetQueue (Queue System)
local Queue; Queue 				= {
	-- These units are used to auto-determine .MetaSlot if its not specified
	GetMetaByUnitID				= { 
		arena1					= 6, 	
		arena2					= 7, 	
		arena3					= 8, 	
		arena4					= 9, 	
		arena5					= 10, 	
		arenapet1				= 6, 	
		arenapet2				= 7, 	
		arenapet3				= 8, 	
		arenapet4				= 9, 	
		arenapet5				= 10, 	
		raid1 					= 6, 
		raid2 					= 7, 
		raid3 					= 8, 
		raid4 					= 9, 
		raid5 					= 10, 
		raidpet1 				= 6, 
		raidpet2 				= 7, 
		raidpet3 				= 8, 
		raidpet4 				= 9, 
		raidpet5 				= 10, 		
		party1 					= 6, 
		party2 					= 7, 
		party3 					= 8,
		party4 					= 9,
		-- no player as meta 10 to avoid possible conflicts 
		partypet1				= 6, 
		partypet2				= 7, 
		partypet3				= 8,
		partypet4				= 9,		
		-- no pet as meta 10 to avoid possible conflicts 
	},
	EmptyArgs					= {},
	Temp 						= {
		SilenceON				= { Silence = true },
		SilenceOFF				= { Silence = false },
	},
	IsTypeValid					= {
		Spell					= true,
		Trinket					= true,
		Potion 					= true,
		Item 					= true,
		SwapEquip				= true,
	},
	Reset 						= function()
		A_Listener:Remove("ACTION_EVENT_QUEUE", "UNIT_SPELLCAST_SUCCEEDED")
		A_Listener:Remove("ACTION_EVENT_QUEUE", "BAG_UPDATE_COOLDOWN")
		A_Listener:Remove("ACTION_EVENT_QUEUE", "ITEM_UNLOCKED")
		A_Listener:Remove("ACTION_EVENT_QUEUE", "ACTIVE_TALENT_GROUP_CHANGED")		
		A_Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_SPECIALIZATION_CHANGED")
		A_Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_REGEN_ENABLED")	
		A_Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_TALENT_UPDATE")
		A_Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_EQUIPMENT_CHANGED")	
		A_Listener:Remove("ACTION_EVENT_QUEUE", "PLAYER_ENTERING_WORLD")	
		TMW:UnregisterCallback("TMW_ACTION_MODE_CHANGED", 		Queue.OnEventToReset,  "TMW_ACTION_MODE_CHANGED_QUEUE_RESET")
		TMW:UnregisterCallback("TMW_ACTION_SOUL_BINDS_UPDATED", Queue.OnEventToReset,  "TMW_ACTION_SOUL_BINDS_UPDATED_QUEUE_RESET")
	end, 
	IsThisMeta 					= function(meta)
		return (not ActionDataQ[1].MetaSlot and (meta == 3 or meta == 4)) or ActionDataQ[1].MetaSlot == meta
	end, 
	IsInterruptAbleChannel 		= {
		-- Monk MW: Smoothing Mist 
		[115175]				= true,
	},
	-- Events
	UNIT_SPELLCAST_SUCCEEDED 	= function(...)
		local source, _, spellID = ...
		if (source == "player" or source == "pet") and ActionDataQ[1] and ActionDataQ[1].Type == "Spell" and A_GetSpellInfo(spellID) == ActionDataQ[1]:Info() then 			
			getmetatable(ActionDataQ[1]).__index:SetQueue(Queue.Temp.SilenceON)
		end 	
	end,
	BAG_UPDATE_COOLDOWN			= function()
		if ActionDataQ[1] and ActionDataQ[1].Item and ActionDataQ[1].Item.GetCooldown then 
			local start, duration, enable = ActionDataQ[1].Item:GetCooldown()			
			if enable ~= 0 and duration ~= 0 and duration and not A_OnGCD(duration) and TMW.time - start < A_GetGCD() * 1.5 then 
				getmetatable(ActionDataQ[1]).__index:SetQueue(Queue.Temp.SilenceON)								 
				return
			end 
			-- For things like a potion that was used in combat and the cooldown hasn't yet started counting down
			if enable == 0 and ActionDataQ[1].Type ~= "Trinket" then 
				getmetatable(ActionDataQ[1]).__index:SetQueue(Queue.Temp.SilenceON)
			end 
		end 	
	end,
	ITEM_UNLOCKED				= function()
		if ActionDataQ[1] and ActionDataQ[1].Type == "SwapEquip" then 
			getmetatable(ActionDataQ[1]).__index:SetQueue(Queue.Temp.SilenceON)
		end 
	end, 	
	OnEventToResetNoCombat 		= function(isSilenced)
		-- ByPass wrong reset events by equip swap during combat
		if A_Unit("player"):CombatTime() == 0 then 
			Queue.OnEventToReset(isSilenced)
		end 
	end, 
	OnEventToReset 				= function(isSilenced)
		if #ActionDataQ > 0 then 
			for i = #ActionDataQ, 1, -1 do 
				if ActionDataQ[i] and ActionDataQ[i].Queued then 
					getmetatable(ActionDataQ[i]).__index:SetQueue((isSilenced == true and Queue.Temp.SilenceON) or Queue.Temp.SilenceOFF)
				end 
			end 		
		end 
		wipe(ActionDataQ) 
		Queue.Reset()
	end, 
}

function Action:QueueValidCheck()
	-- @return boolean
	-- Note: This thing does mostly tasks but still causing some issues with certain spells which should be blacklisted or avoided through another way (ideally) 
	-- Example of issue: Monk can set Queue for Resuscitate while has @target an enemy and it will true because it will set to variable "player" which is also true and correct!
	-- Why "player"? Coz while @target an enemy you can set queue of supportive spells for "self" and if they will be used on enemy then they will be applied on "player" 	
	local isCastingName, _, _, _, castID, isChannel = A_Unit("player"):IsCasting()
	if (not isCastingName or isCastingName ~= self:Info()) and (not isChannel or Queue.IsInterruptAbleChannel[castID]) then
		if self.Type == "SwapEquip" or self.isStance then 
			return true 
		elseif not self:HasRange() then 
			return self:AbsentImun(self.UnitID, self.AbsentImunQueueCache, self.AbsentImunQueueCache2)	-- Well at least will do something, better than nothing 
		else 
			local isHarm 	= self:IsHarmful()
			local unitID 	= self.UnitID or (self.Type == "Spell" and (((isHarm or self:IsHelpful()) and "target") or "player")) or (self.Type ~= "Spell" and ((isHarm and "target") or (not Action.IamHealer and "player"))) or "target"
			self.UnitID		= unitID
			-- IsHelpful for Item under testing phase
			-- unitID 		= self.UnitID or (self.Type == "Spell" and (((isHarm or self:IsHelpful()) and "target") or "player")) or (self.Type ~= "Spell" and (((isHarm or self:IsHelpful()) and "target") or (not Action.IamHealer and "player"))) or "target"
			
			if isHarm then 
				return A_Unit(unitID):IsEnemy() and (self.NoRange or self:IsInRange(unitID)) and self:AbsentImun(unitID, self.AbsentImunQueueCache, self.AbsentImunQueueCache2)
			else 
				return UnitIsUnit(unitID, "player") or ((self.NoRange or self:IsInRange(unitID)) and self:AbsentImun(unitID))
			end 
		end 
	end 
	return false 
end 

function Action.CancelAllQueue()
	Queue.OnEventToReset(true)
end 

function Action.CancelAllQueueForMeta(meta)
	local index 			= #ActionDataQ 
	if index > 0 then 
		for i = index, 1, -1 do 
			if (not ActionDataQ[i].MetaSlot and (meta == 3 or meta == 4)) or ActionDataQ[i].MetaSlot == meta then 
				getmetatable(ActionDataQ[i]).__index:SetQueue(Queue.Temp.SilenceON)
			end 
		end 
	end 
end 

function Action.IsQueueRunning()
	-- @return boolean 
	return #ActionDataQ > 0
end 

function Action.IsQueueRunningAuto()
	-- @return boolean 	
	local index = #ActionDataQ
	return index > 0 and (ActionDataQ[index].Auto or ActionDataQ[1].Auto)
end 

function Action.IsQueueReady(meta)
	-- @return boolean
	local index = #ActionDataQ
    if index > 0 and Queue.IsThisMeta(meta) then 		
		local self = ActionDataQ[1]
		
		-- Cancel 
		if self.Auto and self.Start and TMW.time - self.Start > (ActionData.QueueAutoResetTimer or 10) then 
			Queue.OnEventToReset()
			return false 
		end 	
		
		if not Queue.IsTypeValid[self.Type or ""] then 
			A_Print(L["DEBUG"] .. self:Link() .. " " .. L["ISNOTFOUND"])          
			getmetatable(self).__index:SetQueue()
			return false 
		end 
		
		if self.Type == "Spell" and self:IsSpellInCasting() then 
			-- Note: Adds small delay to prevent double casting
			self.lastCastingUpdateByQueue = TMW.time
		end 
		
		-- Check 
		if self.Type == "SwapEquip" then 
			return 	not A_Player:IsSwapLocked() 
					and (not self.PowerCustom or UnitPower("player", self.PowerType) >= (self.PowerCost or 0)) 
					and (self.Auto or self:RunQLua(self.UnitID)) 
					and (not self.isCP or A_Player:ComboPoints("target") >= (self.CP or 1))  
		else 
			-- Note: Equip, Count, Existance of action already checked in Action:SetQueue 
			return  (self.UnitID == "player" or self:QueueValidCheck())
					and self:IsUsable(self.ExtraCD) 
					and (not self.PowerCustom or UnitPower("player", self.PowerType) >= (self.PowerCost or 0)) 
					and (self.Auto or self:RunQLua(self.UnitID)) 
					and (not self.isCP or A_Player:ComboPoints("target") >= (self.CP or 1))
					and (self.Type ~= "Spell" or ((self:GetSpellCastTime() == 0 or self.NoStaying or not A_Player:IsMoving()) and (TMW.time - (self.lastCastingUpdateByQueue or 0) > 0.15 or (ActionDataQ[2] and ActionDataQ[2].ID == self.ID)))) -- prevents double casting unless otherwise set
		end 
    end 
	
    return false 
end 

function Action:IsBlockedByQueue()
	-- @return boolean 
	return 	not self.QueueForbidden  
			and #ActionDataQ > 0  
			and self.Type == ActionDataQ[1].Type  
			and ( not ActionDataQ[1].PowerType or self.PowerType == ActionDataQ[1].PowerType )  
			and ( not ActionDataQ[1].PowerCost or UnitPower("player", self.PowerType) < ActionDataQ[1].PowerCost )
			and ( not ActionDataQ[1].CP or A_Player:ComboPoints("target") < ActionDataQ[1].CP )
end

function Action:IsQueued()
	-- @return boolean 
    return self.Queued
end 

function Action:SetQueue(args) 
	-- Sets queue on action 
	-- Note: /run Action[Action.PlayerSpec].WordofGlory:SetQueue()
	-- QueueAuto: Action:SetQueue({ Auto = true, Silence = true, Priority = 1 }) -- simcraft like 	
	--[[@usage: args (table)
	 	Optional: 
			PowerType (number) custom offset 														(passing conditions to func IsQueueReady)
			PowerCost (number) custom offset 														(passing conditions to func IsQueueReady)
			ExtraCD (number) custom offset															(passing conditions to func IsQueueReady)
			Silence (boolean) if true don't display print 
			UnitID (string) specified for spells usually to check their for range on certain unit 	(passing conditions to func QueueValidCheck)
			NoRange (boolean) will skip range check 												(passing conditions to func QueueValidCheck)
			NoStaying (boolean) will skip moving check 												(passing conditions to func QueueValidCheck)
			Value (boolean) sets custom fixed statement for queue
			Priority (number) put in specified priority 
			MetaSlot (number) usage for MSG system to set queue on fixed position 
			Auto (boolean) usage to skip RunQLua 
			CP (number) usage to queue action on specified combo points 							(passing conditions to func IsQueueReady)
	]]
	-- Check validance 
	if not self.Queued and (not self:IsExists() or self:IsBlockedBySpellLevel()) then  
		A_Print(L["DEBUG"] .. self:Link() .. " " .. L["ISNOTFOUND"]) 
		return 
	end 
	
	local printKey 	= self.Desc .. (type(self.Color) == "string" and self.Color or "")	-- type fixes some poorly designed addon that overwrites the .Color key in each global table and its subtables with its own function 
		  printKey	= (printKey ~= "" and (" " .. L["TAB"][3]["KEY"] .. printKey .. "]")) or ""
	
	local args = args or Queue.EmptyArgs	
	local Identify = self:GetTableKeyIdentify()
	if self.QueueForbidden or (self.isStance and A_Player:IsStance(self.isStance)) or ((self.Type == "Trinket" or self.Type == "Item") and not self:GetItemSpell()) then 
		if not args.Silence then 
			A_Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORQUEUE"] .. printKey)
		end  
		return 
-- 	Let for user allow run blocked actions whenever he wants, anyway why not 
--	elseif self:IsBlocked() and not self.Queued then 
--		if not args.Silence then 
--			A_Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["QUEUEBLOCKED"] .. printKey)
--		end 
--		return 
	end
	
	if args.Value ~= nil and self.Queued == args.Value then 
		if not args.Silence then 
			A_Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISQUEUEDALREADY"] .. printKey)
		end 
		return 
	end 
	
	if args.Value ~= nil then 
		self.Queued = args.Value 
	else 
		self.Queued = not self.Queued
	end 
	
	local priority = (args.Priority and (args.Auto or not A_IsQueueRunningAuto()) and (args.Priority > #ActionDataQ + 1 and #ActionDataQ + 1 or args.Priority)) or #ActionDataQ + 1	
    if not args.Silence then		
		if self.Queued then 
			A_Print(L["TAB"][3]["QUEUED"] .. self:Link() .. L["TAB"][3]["QUEUEPRIORITY"] .. priority .. ". " .. L["TAB"][3]["KEYTOTAL"] .. #ActionDataQ + 1 .. "]")
		else
			A_Print(L["TAB"][3]["QUEUEREMOVED"] .. self:Link() .. printKey)
		end 
    end 
    
	if not self.Queued then 
		for i = #ActionDataQ, 1, -1 do 
			if ActionDataQ[i]:GetTableKeyIdentify() == Identify then 
				tremove(ActionDataQ, i)
				if #ActionDataQ == 0 then 
					Queue.Reset()
					return 
				end 				
			end 
		end 
		return
	end 
    	
	-- Do nothing if it does in spam with always true as insert to queue list 	
	if args.Value and #ActionDataQ > 0 then 
		for i = #ActionDataQ, 1, -1 do
			if ActionDataQ[i]:GetTableKeyIdentify() == Identify then 
				return
			end 
		end 
	end
	
	-- Since devs expects to make "arena1" running at A[6] without need for .MetaSlot specified 
	-- This part of code determines .MetaSlot depending on UnitID
	local meta = args.MetaSlot or Queue.GetMetaByUnitID[args.UnitID]	
    tinsert(ActionDataQ, priority, setmetatable({ UnitID = args.UnitID, MetaSlot = meta, Auto = args.Auto, Start = TMW.time, CP = args.CP }, { __index = self })) -- Don't touch creation tables here!

	if args.PowerType then 
		-- Note: we set it as true to use in function Action.IsQueueReady()
		ActionDataQ[priority].PowerType = args.PowerType   	
		ActionDataQ[priority].PowerCustom = true
	end	
	if args.PowerCost then 
		ActionDataQ[priority].PowerCost = args.PowerCost
		ActionDataQ[priority].PowerCustom = true
	end 		 	
	if args.ExtraCD then
		ActionDataQ[priority].ExtraCD = args.ExtraCD 
	end 	
	if args.NoStaying then
		ActionDataQ[priority].NoStaying = args.NoStaying 
	end 	
	
	-- Ryan's fix Action:SetQueue() is missing CP passing to IsQueueReady logic
	if args.CP then
		ActionDataQ[priority].CP = args.CP 
		ActionDataQ[priority].isCP = true
	end		
	
    A_Listener:Add("ACTION_EVENT_QUEUE", "UNIT_SPELLCAST_SUCCEEDED", 		Queue.UNIT_SPELLCAST_SUCCEEDED										)
	A_Listener:Add("ACTION_EVENT_QUEUE", "BAG_UPDATE_COOLDOWN", 			Queue.BAG_UPDATE_COOLDOWN											)	
	A_Listener:Add("ACTION_EVENT_QUEUE", "ITEM_UNLOCKED",					Queue.ITEM_UNLOCKED													)
	A_Listener:Add("ACTION_EVENT_QUEUE", "ACTIVE_TALENT_GROUP_CHANGED", 	Queue.OnEventToReset												)	
    A_Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_SPECIALIZATION_CHANGED", 	Queue.OnEventToReset												)
	A_Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_REGEN_ENABLED", 			Queue.OnEventToReset												)
	A_Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_TALENT_UPDATE", 			Queue.OnEventToReset												)
	A_Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_EQUIPMENT_CHANGED", 		Queue.OnEventToResetNoCombat										)
	A_Listener:Add("ACTION_EVENT_QUEUE", "PLAYER_ENTERING_WORLD", 			Queue.OnEventToReset												)
	TMW:RegisterCallback("TMW_ACTION_MODE_CHANGED", 						Queue.OnEventToReset,  "TMW_ACTION_MODE_CHANGED_QUEUE_RESET"		)
	TMW:RegisterCallback("TMW_ACTION_SOUL_BINDS_UPDATED", 					Queue.OnEventToReset,  "TMW_ACTION_SOUL_BINDS_UPDATED_QUEUE_RESET"	)
end

function Action.MacroQueue(key, args)
	-- Sets queue on action with avoid lua errors for non exist key
	local object = A_GetActionTableByKey(key)
	if not object then 
		A_Print(L["DEBUG"] .. (key or "") .. " " .. L["ISNOTFOUND"])
		return 	 
	end 
	object:SetQueue(args)
end

-- [4] Interrupts
-- Note:  Toggle				"Main", "Mouse", "PvP", "Heal"									-- This is short assignment for reference to Checkbox and Category
--								nil (which is "Main" or "Mouse")
--		  Checkbox 				"UseMain", "UseMouse", "UsePvP", "UseHeal" 						-- for internal info 
--		  Category 				"MainPvE", "MainPvP", "MousePvE", "MousePvP", "PvP", "Heal"		-- for internal info 
local Interrupts 				= {
	CastMustDoneTimeByToggle 	= setmetatable({}, { 
		__index = function(t, category)
			t[category] = setmetatable({}, { 
				__call = function(this, spellName, castStartTime, castEndTime, countGCD)
					if not this[spellName] then 
						this[spellName] = {}
					end 
					local thisCast = this[spellName]
					
					-- Refresh Interval 
					-- If new cast begin or we re-specified 'countGCD' of the already started (written with interval) cast
					if thisCast.lastEndTime ~= castEndTime or thisCast.countGCD ~= countGCD then 
						local castFullTime 			= castEndTime - castStartTime
						local min, max				
						if Action.IsInPvP and ((not isClassic and spellName == A_GetSpellInfo(209525)) or spellName == A_GetSpellInfo(47540)) then -- Smoothing Mist or Penance
							min, max 				= 3, 18
						else 
							min, max 				= A_InterruptGetSliders(category)
						end 
						
						if countGCD then 
							-- If enabled then we will limit 'mustDoneTime' to have it available for interrupt with the next gcd 
							castFullTime			= math_max(castFullTime - A_GetGCD(), 0)
						end 
						
						thisCast.mustDoneTime 		= math_random(min, max) * castFullTime / 100
						thisCast.lastEndTime		= castEndTime
						thisCast.countGCD			= countGCD
					end 
					
					return thisCast.mustDoneTime
				end,
			})
			return t[category]
		end,
	}),
	SmartInterrupt				= function()
		-- Note: This function is cached 
		local HealerInCC = not Action.IamHealer and A_FriendlyTeam("HEALER", 1):GetCC() or 0
		return 	(HealerInCC > 0 and HealerInCC < A_GetGCD() + A_GetCurrentGCD()) or 
				A_FriendlyTeam("DAMAGER", 2):GetBuffs("DamageBuffs") > 4 or 
				A_FriendlyTeam():GetTTD(1, 8, 40) or 
				A_Unit("target"):IsExecuted() or 
				A_Unit("player"):IsExecuted() or 
				A_EnemyTeam("DAMAGER", 2):GetBuffs("DamageBuffs") > 4
	end,
	GetCategory					= function(self, unitID, toggle, ignoreToggle)
		-- @return category, toggle 		
		local ToggleType = (toggle and self.GetToggleType[toggle]) or "Unknown"
		if ToggleType == "Unknown" then
			if ignoreToggle then 
				return toggle, toggle
			end 
		
			if unitID == "mouseover" and not UnitIsUnit(unitID, "target") then -- and (not Action.IamHealer or not UnitIsUnit(unitID, "targettarget"))
				return self:GetCategory(unitID, "Mouse")
			else 
				return self:GetCategory(unitID, "Main")
			end 
		elseif self.FormatToggleType[ToggleType] then 
			return self.FormatToggleType[ToggleType][Action.IsInPvP or false], ToggleType
		else 
			return toggle, toggle
		end 
	end,
	GetCheckbox					= {
		Main 					= "UseMain",
		MainPvE					= "UseMain",
		MainPvP					= "UseMain",
		Mouse 					= "UseMouse",
		MousePvP				= "UseMouse",
		MousePvE				= "UseMouse",
		PvP						= "UsePvP",
		Heal 					= "UseHeal",
	},
	GetToggleType				= {		
		Main 					= "Main",
		MainPvE					= "Main",		-- prevent wrong usage
		MainPvP					= "Main",		-- prevent wrong usage
		Mouse 					= "Mouse",
		MousePvE				= "Mouse",		-- prevent wrong usage
		MousePvP				= "Mouse",		-- prevent wrong usage	
		PvP 					= "PvP",
		Heal 					= "Heal",
	},
	FormatToggleType	 		= {
		Main					= {
			[true] 				= "MainPvP",
			[false] 			= "MainPvE",
		},
		Mouse 					= {
			[true] 				= "MousePvP",
			[false] 			= "MousePvE",
		},
	},
}

function Action.InterruptGetSliders(category)
	-- @return number, number or nil 
	local Slider = pActionDB[4][category]
	if Slider then 
		return Slider.Min, Slider.Max
	end 
end 

function Action.InterruptIsON(toggleOrCategory)
	-- @return boolean 	
	local checkbox = Interrupts.GetCheckbox[toggleOrCategory]
	return checkbox and pActionDB[4][Action.PlayerSpec][checkbox]
end 

function Action.InterruptIsBlackListed(unitID, spellName)
	-- @return boolean, boolean, boolean
	local blackListed = pActionDB[4].BlackList[GameLocale][spellName]
	if blackListed and blackListed.Enabled then 
		if RunLua(blackListed.LUA, unitID) then 
			return blackListed.useKick, blackListed.useCC, blackListed.useRacial
		end 
	end 
end 

function Action.InterruptEnabled(category, spellName)
	-- @return boolean 
	local interrupt = pActionDB[4][category][GameLocale][spellName]
	return interrupt and interrupt.Enabled
end 

function Action.InterruptIsValid(unitID, toggle, ignoreToggle, countGCD)
	-- @return boolean, boolean, boolean, boolean, number, number
	-- @usage  useKick, useCC, useRacial, notInterruptable, castRemainsTime, castDoneTime = Action.InterruptIsValid(unitID[, toggle, ignoreToggle, countGCD])
	-- Basically conception of the 'countGCD' is Action.InterruptIsValid(unitID, nil, nil, not Action.InterruptNonGCD:IsReady(unitID)), so it will pick up in count GCD for current loop while primary non-gcd interrupt(s) unavailable 
	-- 'ignoreToggle' 	if true will skip check for enabled toggle and transforms 'toggle' to be 'category' if its Unknown (i.e. custom category added by callback)
	-- 'countGCD' 		if true will limit max interval to have it interrupted in the next gcd 
	
	-- ATTENTION
	-- This thing doesn't check distance and imun to kick
	
	local castRemainsTime, castDoneTime = 0, 0
	local category, toggle = Interrupts:GetCategory(unitID, toggle, ignoreToggle)
	
	if ignoreToggle or A_InterruptIsON(toggle) then 	
		local spellName, castStartTime, castEndTime, notInterruptable = A_Unit(unitID):IsCasting()
		if spellName then 		
			-- milliseconds > seconds 
			castStartTime 			= castStartTime / 1000
			castEndTime   			= castEndTime / 1000			
			castDoneTime			= TMW.time - castStartTime 	-- 0 -> inif seconds
			castRemainsTime			= castEndTime - TMW.time	-- inif -> 0 seconds
			
			local Interrupt 	
			local MainAuto			= toggle == "Main" 	and A_GetToggle(4, "MainAuto")
			local MouseAuto			= toggle == "Mouse" and A_GetToggle(4, "MouseAuto")
			if not MainAuto and not MouseAuto then 
				Interrupt 			= pActionDB[4][category][GameLocale][spellName]	
				-- If it's not any cast and not exists in the list 
				if not Interrupt or not Interrupt.Enabled then 
					return false, false, false, notInterruptable, castRemainsTime, castDoneTime
				end 
			end 
							
			local useKick, useCC, useRacial = true, true, true 			
			if Interrupt then 
				useKick				= Interrupt.useKick
				useCC				= Interrupt.useCC
				useRacial			= Interrupt.useRacial
			end 
			
			local blackListedKick, blackListedCC, blackListedRacial = A_InterruptIsBlackListed(unitID, spellName)	
			if blackListedKick 		then useKick 	= false end 
			if blackListedCC 		then useCC		= false end 
			if blackListedRacial	then useRacial	= false end  
			
			-- If all types unavailable 
			if not useRacial and not useCC and not useKick then 
				return false, false, false, notInterruptable, castRemainsTime, castDoneTime
			end 
			
			-- If interval is not reached 
			local mustDoneTime = Interrupts.CastMustDoneTimeByToggle[category](spellName, castStartTime, castEndTime, countGCD or notInterruptable) -- Note: Usually primary interrupt (Kick) without GCD but it's not ready if its notInterruptable, so we want to replace it by gcd based interrupts 
			if castDoneTime < mustDoneTime then 
				return false, false, false, notInterruptable, castRemainsTime, castDoneTime
			end 						
			
			-- If additional conditions aren't successful
			if toggle == "PvP" then 
				if UnitIsUnit(unitID, "target") or (A_GetToggle(4, "PvPOnlySmart") and not Interrupts.SmartInterrupt()) then 
					return false, false, false, notInterruptable, castRemainsTime, castDoneTime
				end 
			end 
			
			if toggle == "Heal" then 
				if UnitIsUnit(unitID, "target") or (A_GetToggle(4, "HealOnlyHealers") and not A_Unit(unitID):IsHealer()) then 
					return false, false, false, notInterruptable, castRemainsTime, castDoneTime
				end 
			end 
			
			if toggle == "Main" then 
				if MainAuto then 
					-- We want to interrupt only not imun units 
					if category == "MainPvE" then 
						if A_Unit(unitID):IsTotem() or A_Unit(unitID):IsDummy() or (not isClassic and (A_Unit(unitID):IsExplosives() or A_Unit(unitID):IsCracklingShard())) then 
							return false, false, false, notInterruptable, castRemainsTime, castDoneTime
						end 
					end 
					
					-- We want to interrupt only if it's healer and will die in less than 6 seconds or if it's player without in range enemy healers 
					if category == "MainPvP" then 
						local isHealer = A_Unit(unitID):IsHealer() 
						if (isHealer and A_Unit(unitID):TimeToDie() > 6) or (not isHealer and (not A_Unit(unitID):IsPlayer() or A_EnemyTeam("HEALER"):GetUnitID(60) ~= "none")) then
							return false, false, false, notInterruptable, castRemainsTime, castDoneTime
						end 
					end 
				end 
			end 
			
			if toggle == "Mouse" then 				
				if MouseAuto then 
					-- We want to interrupt only not imun units 
					if category == "MousePvE" then 
						if A_Unit(unitID):IsTotem() or A_Unit(unitID):IsDummy() or (not isClassic and (A_Unit(unitID):IsExplosives() or A_Unit(unitID):IsCracklingShard())) then 
							return false, false, false, notInterruptable, castRemainsTime, castDoneTime
						end 
					end 
					
					-- We want to interrupt only PvP and Heal casts by players
					if category == "MousePvP" then 
						if not A_Unit(unitID):IsPlayer() or (not A_InterruptEnabled("PvP", spellName) and not A_InterruptEnabled("Heal", spellName)) then 
							return false, false, false, notInterruptable, castRemainsTime, castDoneTime
						end 
					end 
				end 
			end 
			
			-- If custom lua is not successful, conception is to have it last checked 
			if Interrupt and not RunLua(Interrupt.LUA, unitID) then 
				return false, false, false, notInterruptable, castRemainsTime, castDoneTime
			end 

			return useKick, useCC, useRacial, notInterruptable, castRemainsTime, castDoneTime
		end 
	end 
	return false, false, false, false, castRemainsTime, castDoneTime
end 

-- [5] Auras
-- Note: Toggle  	"UseDispel", "UsePurge", "UseExpelEnrage"
--		 Category 	"Dispel", "MagicMovement", "PurgeFriendly", "PurgeHigh", "PurgeLow", "Enrage", "BlackList", 
--					"BlessingofProtection", "BlessingofFreedom", "BlessingofSacrifice", "BlessingofSanctuary"		-- only Paladin ( BlessingofSacrifice is Prot/Holy, BlessingofSanctuary	is Retribution )
function Action.AuraIsON(Toggle)
	-- @return boolean 
	return (type(Toggle) == "boolean" and Toggle == true) or pActionDB[5][Action.PlayerSpec][Toggle]
end 

function Action.AuraGetCategory(Category)
	-- @return table or nil (if not found category in certain Mode), string or (Filter)
	--[[ table basic structure:
		[Name] = { ID, Name, Enabled, Role, Dur, Stack, byID, canStealOrPurge, onlyBear, LUA }
		-- Look DispelPurgeEnrageRemap about table create 
	]]
	local Mode = Action.IsInPvP and "PvP" or "PvE"
	local Filter = "HARMFUL"
	if Category:match("Purge") or Category:match("Enrage") then 
		Filter = "HELPFUL"
	elseif Category:match("BlackList") then 
		Filter = "HARMFUL HELPFUL"
	end 
	
	local Aura = pActionDB[5][Action.PlayerSpec][Mode]
	if Aura and Aura[Category] then 
		return Aura[Category][GameLocale], Filter
	end 
	
	Aura = ActionDataAuras[Mode]
	if Aura then 
		return Aura[Category], Filter
	end 
	
	return nil, Filter	
end

function Action.AuraIsBlackListed(unitID)
	-- @return boolean 
	local Aura, Filter = A_AuraGetCategory("BlackList")
	if Aura and next(Aura) then 
		local _, AuraData, Dur, auraData
		for i = 1, huge do 
			auraData = UnitAura(unitID, i, Filter)
			if auraData then
				AuraData = Aura[auraData.name]
				if AuraData and AuraData.Enabled and (AuraData.Role == "ANY" or (AuraData.Role == "HEALER" and Action.IamHealer) or (AuraData.Role == "DAMAGER" and not Action.IamHealer)) and (not AuraData.byID or auraData.spellId == AuraData.ID) then 
					Dur = auraData.expirationTime == 0 and huge or auraData.expirationTime - TMW.time
					if Dur > AuraData.Dur and (AuraData.Stack == 0 or auraData.applications >= AuraData.Stack) and (not AuraData.canStealOrPurge or auraData.isStealable == true) and (not AuraData.onlyBear or A_Unit(unitID):HasBuffs(5487) > 0) and RunLua(AuraData.LUA, unitID) then
						return true
					end 
				end 
			else
				break 
			end 
		end 
	end 
end 

function Action.AuraIsValid(unitID, Toggle, Category)
	-- @return boolean 
	if Category ~= "BlackList" and A_AuraIsON(Toggle) then 
		local Aura, Filter = A_AuraGetCategory(Category)
		if Aura and not A_AuraIsBlackListed(unitID) then 
			local _, AuraData, Dur, auraData
			for i = 1, huge do	
				auraData = UnitAura(unitID, i, Filter)		
				if auraData then	
					AuraData = Aura[auraData.name]
					if AuraData and AuraData.Enabled and (AuraData.Role == "ANY" or (AuraData.Role == "HEALER" and Action.IamHealer) or (AuraData.Role == "DAMAGER" and not Action.IamHealer)) and (not AuraData.byID or auraData.spellId == AuraData.ID) then 					
						Dur = auraData.expirationTime == 0 and huge or auraData.expirationTime - TMW.time
						if Dur > AuraData.Dur and (AuraData.Stack == 0 or auraData.applications >= AuraData.Stack) and (not AuraData.canStealOrPurge or auraData.isStealable == true) and (not AuraData.onlyBear or A_Unit(unitID):HasBuffs(5487) > 0) and RunLua(AuraData.LUA, unitID) then
							return true
						end 
					end 
				else
					break 
				end 
			end 
		end
	end 
end

-- [6] Cursor 
local Cursor; Cursor 		= {
	OnEvent 				= function(self)
		-- Note: self here is not self to the Cursor table, it's self to the frame 
		if Cursor.Initialized then 
			local UseLeft = A_GetToggle(6, "UseLeft")
			local UseRight = A_GetToggle(6, "UseRight")
			if UseLeft or UseRight then 
				local M = Action.IsInPvP and "PvP" or "PvE"
				local ObjectName = UnitName("mouseover")
				if ObjectName then 		
					-- UnitName 
					local UnitNameKey = pActionDB[6][Action.PlayerSpec][M]["UnitName"][GameLocale][ObjectName:lower()]
					if UnitNameKey and UnitNameKey.Enabled and ((UnitNameKey.Button == "LEFT" and UseLeft) or (UnitNameKey.Button == "RIGHT" and UseRight)) and (not UnitNameKey.isTotem or A_Unit("mouseover"):IsTotem() and not A_Unit("target"):IsTotem()) and RunLua(UnitNameKey.LUA, "mouseover") then 
						Cursor.lastMouseName = ObjectName
						Action.GameTooltipClick = UnitNameKey.Button
						return
					end 
				elseif self:IsVisible() and self:GetEffectiveAlpha() >= 1 then
					-- GameTooltip 
					local focus = Action.GetMouseFocus() 	
					if focus and (not focus.IsForbidden or not focus:IsForbidden()) then
						local GameTooltipTable 
						if focus.GetName and focus:GetName() == "WorldFrame" then 
							GameTooltipTable = pActionDB[6][Action.PlayerSpec][M]["GameToolTip"][GameLocale]
						else 
							GameTooltipTable = pActionDB[6][Action.PlayerSpec][M]["UI"][GameLocale]
						end 
						
						if next(GameTooltipTable) then 						
							local Regions = { self:GetRegions() }
							for i = 1, #Regions do 					
								local region = Regions[i]									
								if region and region.GetText then 									
									local text = region:GetText()										
									if text then 
										text = text:lower()
										local GameTooltipKey = GameTooltipTable[text]
										if GameTooltipKey and GameTooltipKey.Enabled and ((GameTooltipKey.Button == "LEFT" and UseLeft) or (GameTooltipKey.Button == "RIGHT" and UseRight)) and (not GameTooltipKey.isTotem or A_Unit("mouseover"):IsTotem() and not A_Unit("target"):IsTotem()) and RunLua(GameTooltipKey.LUA, "mouseover") then 								
											Action.GameTooltipClick = GameTooltipKey.Button
											return 									
										end 
									end 
								end 
							end 
						end 
					end 					
				end
			end 
			
			Cursor.lastMouseName 	= nil 
			Action.GameTooltipClick = nil 	
		end		
	end,
	CURSOR_CHANGED			= function()	
	 	Cursor.lastEventTime = TMW.time
	 	if Action.GameTooltipClick and not Cursor.lastMouseName then			
	 		Action.GameTooltipClick = nil 	 
	 	end 
	end,
	UPDATE_MOUSEOVER_UNIT 	= function()	
		Cursor.lastEventTime = TMW.time
		if not Cursor.lastMouseName or Cursor.lastMouseName ~= UnitName("mouseover") then 
			Cursor.Update()			
		end 
	end,	
	Reset 					= function(self)
		A_Listener:Remove("ACTION_EVENT_CURSOR_FEATURE", "CURSOR_CHANGED")
		A_Listener:Remove("ACTION_EVENT_CURSOR_FEATURE", "UPDATE_MOUSEOVER_UNIT")	
		Action.GameTooltipClick = nil 
		self.lastMouseName		= nil 	
		self.Initialized 		= nil 		
	end, 
	Initialize				= function(self)
		local wasHooked = self.IsHooked
		if not self.IsHooked then 
			self.GameTooltip 			= _G.GameTooltip			
			self.lastSetDefaultAnchor 	= TOOLTIP_UPDATE_TIME
			self.lastEventTime 			= TOOLTIP_UPDATE_TIME		
			self.Update 				= function()
				self.OnEvent(self.GameTooltip)
			end 
			
			-- Add
			self.GameTooltip:HookScript("OnShow", function(this)													-- UI:Add
				if self.Initialized and TMW.time - self.lastEventTime > 0.4 and TMW.time - (self.lastSetDefaultAnchor - TOOLTIP_UPDATE_TIME) > 0.4 then 
					Cursor.Update()
				end 
			end)
			self.GameTooltip:HookScript("OnTooltipSetDefaultAnchor", function(this)  								-- GameObjects:Add (passthrough)
				if self.Initialized and not Action.GameTooltipClick and not UnitExists("mouseover") then		
					self.lastSetDefaultAnchor = TMW.time + TOOLTIP_UPDATE_TIME
					self.lastMouseName = nil 			 
				end 
			end) 
			A_Listener:Add("ACTION_EVENT_CURSOR_FEATURE", "UPDATE_MOUSEOVER_UNIT", self.UPDATE_MOUSEOVER_UNIT)		-- Units:Add	
			
			-- Remove
			self.GameTooltip:HookScript("OnTooltipCleared", function() 												-- UI:Remove
				if Action.GameTooltipClick and TMW.time - self.lastEventTime > 0.4 then 
					Action.GameTooltipClick = nil 
					self.lastMouseName		= nil 
				end
			end)					
			A_Listener:Add("ACTION_EVENT_CURSOR_FEATURE", "CURSOR_CHANGED", 	self.CURSOR_CHANGED) 				-- GameObjects:Remove				
			self.GameTooltip:HookScript("OnUpdate", function(this, elapse)											
				-- Note: UPDATE_MOUSEOVER_UNIT doesn't fires if you move out cursor from unit, so we will use this to simulate same event 
				if self.Initialized then 
					if self.lastMouseName then 																		-- Units:Remove 
						if self.lastMouseName ~= UnitName("mouseover") then 
							Action.GameTooltipClick = nil
							self.lastMouseName		= nil 	
						end
					else																							
						if not Action.GameTooltipClick and self.lastSetDefaultAnchor >= TMW.time then 				-- GameObjects:Add (continue)
							Cursor.Update()
							if Action.GameTooltipClick then 
								self.lastSetDefaultAnchor = TOOLTIP_UPDATE_TIME
							end 
						end 
						
						if Action.GameTooltipClick and this:GetEffectiveAlpha() < 1 then 							-- Remove All 
							-- Note: Just super additional condition to avoid any possible missed issues before OnTooltipCleared will be triggered 
							Action.GameTooltipClick = nil
						end 
					end 
				end 
			end)
		
			self.IsHooked = true 
		end 
		
		self.Initialized = A_GetToggle(6, "UseLeft") or A_GetToggle(6, "UseRight")
		if wasHooked then 
			if self.Initialized then
				A_Listener:Add("ACTION_EVENT_CURSOR_FEATURE", "CURSOR_CHANGED", 		self.CURSOR_CHANGED)
				A_Listener:Add("ACTION_EVENT_CURSOR_FEATURE", "UPDATE_MOUSEOVER_UNIT", 	self.UPDATE_MOUSEOVER_UNIT)	
			else
				self:Reset()
			end 
		end 
	end,
}

-- [7] MSG System (Message) 
local MSG; MSG 				= {
	units 					= { "raid%d+", "raidpet%d+", "party%d+", "partypet%d+", "arena%d+", "arenapet%d+", "player", "target" }, -- "focus", "nameplate" and etc haven't API, it will be passed as no unit if specified in phrase!
	group 					= { 
		{ u = "raid1", 		meta = 6 	}, 
		{ u = "raid2", 		meta = 7	}, 
		{ u = "raid3", 		meta = 8	}, 
		{ u = "raid4", 		meta = 9	}, 
		{ u = "raid5", 		meta = 10	}, 
		{ u = "raidpet1", 	meta = 6 	}, 
		{ u = "raidpet2", 	meta = 7	}, 
		{ u = "raidpet3", 	meta = 8	}, 
		{ u = "raidpet4", 	meta = 9	}, 
		{ u = "raidpet5", 	meta = 10	}, 		
		{ u = "party1", 	meta = 6 	}, 
		{ u = "party2", 	meta = 7	}, 
		{ u = "party3", 	meta = 8	},
		{ u = "party4", 	meta = 9	},
		-- no player as meta 10 to avoid possible conflicts 
		{ u = "partypet1", 	meta = 6 	}, 
		{ u = "partypet2", 	meta = 7	}, 
		{ u = "partypet3", 	meta = 8	},
		{ u = "partypet4", 	meta = 9	},
		-- no pet as meta 10 to avoid possible conflicts 
	}, 
	arena 					= {
		arena1				= 6, 	
		arena2				= 7, 	
		arena3				= 8, 	
		arena4				= 9, 	
		arena5				= 10, 	
		arenapet1			= 6, 	
		arenapet2			= 7, 	
		arenapet3			= 8, 	
		arenapet4			= 9, 	
		arenapet5			= 10, 			
	},
	set 					= {},
	SetToggle				= {7, "Channels"},
	OnEvent					= function(...)
		local msgList = A_GetToggle(7, "msgList")
		if type(msgList) ~= "table" or not next(msgList) then 
			return 
		end 
		
		local msg, sname  = ... 
		msg = msg:lower()
		for Name, v in pairs(msgList) do 
			if v.Enabled and msg:match(Name) and (not v.Source or v.Source == sname) then 
				local Obj = Action[Action.PlayerSpec][v.Key] 
				if Obj and (not A_GetToggle(7, "DisableReToggle") or not Obj:IsQueued()) then  							
					wipe(MSG.set)
					
					local unit					
					for j = 1, #MSG.units do 
						unit = msg:match(MSG.units[j])
						if unit then 
							break
						end 
					end 	
					
					if unit then 
						if RunLua(v.LUA, unit) then 														
							if unit:match("raid") or unit:match("party") then							
								local group_type = Action.TeamCache.Friendly.Type
								for j = 1, #MSG.group do 
									if (j <= 10 and group_type == "raid") or (j > 10 and group_type == "party") then 
										if UnitIsUnit(unit, MSG.group[j].u) then 	
											MSG.set.MetaSlot = MSG.group[j].meta											 
											MSG.set.UnitID = MSG.group[j].u
											A_MacroQueue(v.Key, MSG.set)							
											break 
										end 
									else 
										break 
									end 
								end 											
							elseif unit:match("arena") then
								if MSG.arena[unit] then 
									MSG.set.UnitID 		= unit
									MSG.set.MetaSlot 	= MSG.arena[unit] 							
									A_MacroQueue(v.Key, MSG.set)
								end 
							else 
								-- Note: "player", "target"
								MSG.set.UnitID 			= unit 
								A_MacroQueue(v.Key, MSG.set)
							end 
						end 
					else
						-- Note: Determine unit by object:
						-- @target if any object is harm or (is help and (its spell or we're healer)) or (non-spell object and we're healer)
						-- @player if (non-spell object and we're not healer) or for all otherwise conditions 
						-- meta slot will be 3 
						-- So basically harm and help both false objects will be applied to @player, any items will be applied to @player if not a healer or to @target, any spells will be applied to @player if we're not a healer or to @target 
						if v.LUA ~= nil and v.LUA ~= "" and Obj:HasRange() then 
							unit = ((Obj:IsHarmful() or (Obj:IsHelpful() and (Obj.Type == "Spell" or Action.IamHealer))) and "target") or (Obj.Type ~= "Spell" and ((not Action.IamHealer and "player") or "target")) or "player"
						end 
					
						if RunLua(v.LUA, unit or "target") then
							MSG.set.UnitID = unit -- or "target"
							A_MacroQueue(v.Key, MSG.set)
						end 
					end	
					
					return 
				end							 
			end        
		end 	
	end,
	Reset 					= function(self)
		A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_WHISPER")
		A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY")
		A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY_LEADER")
		A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID")
		A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID_LEADER")	
	end,
	Initialize				= function(self)
		local channels = A_GetToggle(7, "Channels")
		if channels[1] then 
			A_Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_WHISPER", 			self.OnEvent)
		else 
			A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_WHISPER")	
		end 			
		
		if channels[2] then 
			A_Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_PARTY", 			self.OnEvent)
			A_Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_PARTY_LEADER", 	self.OnEvent)
		else 
			A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY")
			A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_PARTY_LEADER")			
		end 
		
		if channels[3] then 
			A_Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_RAID", 			self.OnEvent)
			A_Listener:Add("ACTION_EVENT_MSG", "CHAT_MSG_RAID_LEADER", 		self.OnEvent)
		else 
			A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID")
			A_Listener:Remove("ACTION_EVENT_MSG", "CHAT_MSG_RAID_LEADER")			
		end 						
	end,
	IsEnabled 				= function(self)
		local channels = A_GetToggle(7, "Channels")
		for i = 1, #channels do 
			if channels[i] then 
				return true 
			end 
		end 
	end,
}	

function Action.ToggleMSG(val)
	MSG.SetToggle[3] = L["TAB"][7]["MSG"] .. ": "
	A_SetToggle(MSG.SetToggle, val)
	MSG:Initialize()	
	if tabFrame then 
		local spec 	= Action.PlayerSpec .. CL
		local tab 	= tabFrame.tabs[7]
		if tab and tab.childs[spec] and tab.childs[spec].toggleWidgets and tab.childs[spec].toggleWidgets then 
			local DisableReToggle = tab.childs[spec].toggleWidgets.DisableReToggle
			if DisableReToggle then 
				DisableReToggle:GetScript("OnShow")(DisableReToggle)
			end
			
			local Macro = tab.childs[spec].toggleWidgets.Macro
			if Macro then 
				Macro:GetScript("OnTextChanged")(Macro)
			end
		end
	end 
end 

-- [8] Healing Engine 
local HealingEngine 		= {
	canSetToggle			= {
		PredictOptions		= {8, "PredictOptions"},
		SelectStopOptions	= {8, "SelectStopOptions"}, 
	},
	canSetUnitIDs			= {
		UnitIDs				= {8, "UnitIDs", nil, true},
	},	
	printAllNotEqual		= function(self, t1, t2, text)
		for k, v in pairs(t1) do 
			if v ~= t2[k] then 
				A_Print(text .. L["TAB"][8][k:upper()] .. " = ", t2[k])
			end 
		end 
	end,
	tempNormalToggle		= {8},
	tMergeProfile			= function(self, fromLoad, toLoad)
		for k, v in pairs(fromLoad) do 
			if toLoad[k] ~= nil then 
				if type(v) == "table" then 
					if self.canSetToggle[k] then 
						local useSetToggle
						
						for k1, v1 in ipairs(A_GetToggle(8, k)) do 
							if v1 ~= v[k1] then 
								useSetToggle = true 
								break
							end 
						end 
						
						if useSetToggle then 
							self.canSetToggle[k][3] = L["TAB"][8][k:upper()] .. ": "
							A_SetToggle(self.canSetToggle[k], v)
						end 
					elseif self.canSetUnitIDs[k] then 
						A_SetToggle(self.canSetUnitIDs[k], v)
						
						-- Due how SetToggle released we can't use print inside, so we will do it here 						
						for unitID, unitData in pairs(toLoad.UnitIDs) do 
							self:printAllNotEqual(unitData, v[unitID], unitID .. ": ")							
						end 
					else
						A_Print(L["DEBUG"] .. "invalid " .. k .. ". Func: HealingEngine.tMergeProfile")
					end 					
				else 
					if A_GetToggle(8, k) ~= v then 
						self.tempNormalToggle[2] = k 
						self.tempNormalToggle[3] = L["TAB"][8][k:upper()] .. ": "
						A_SetToggle(self.tempNormalToggle, v)
					end 
				end 
			end 
		end 
	end,
	tSaveProfile			= function(self, fromSave, toSave)
		for k, v in pairs(fromSave) do 
			if k ~= "Profiles" and k ~= "Profile" then 
				if type(v) == "table" then 
					toSave[k] = {}
					self:tSaveProfile(v, toSave[k])
				else 
					toSave[k] = v
				end 
			end 
		end 
	end,
	HasErrors				= function(self, profileName)
		if not ActionHasRunningDB then 
			A_Print(L["DEBUG"] .. L["TAB"][8]["PROFILEERRORDB"])
			return true
		end 
		
		if (not isClassic and not Action.IamHealer) or (isClassic and not A_Unit("player"):IsHealerClass()) then 
			A_Print(L["DEBUG"] .. L["TAB"][8]["PROFILEERRORNOTAHEALER"])
			return true
		end 
		
		if (type(profileName) ~= "string" and type(profileName) ~= "number") or profileName == "" then 
			A_Print(L["DEBUG"] .. L["TAB"][8]["PROFILEERRORINVALIDNAME"])
			return true
		end 		
	end,
	GetCurrentProfile 		= function(self)
		-- @return table 
		if not isClassic then 
			return pActionDB[8][Action.PlayerSpec]
		else 
			return pActionDB[8]
		end 
	end,
}

function Action.HealingEngineProfileLoad(profileName)
	-- Debug 
	if HealingEngine:HasErrors(profileName) then 
		return 
	end 
	
	-- Work 
	local profileCurrent = HealingEngine:GetCurrentProfile()
	local profileNew = profileCurrent.Profiles[profileName]
	if not profileNew then
		A_Print(L["DEBUG"] .. profileName .. L["ISNOTFOUND"])		
		return 
	end 
	
	local profileCurrent = HealingEngine:GetCurrentProfile()
	HealingEngine:tMergeProfile(profileNew, profileCurrent)
	profileCurrent.Profile = profileName -- Don't touch..
	--TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_UPDATE") -- no need, SetToggle for UnitIDs key will fire it 
	A_Print(L["TAB"][8]["PROFILELOADED"] .. profileName)
	TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Loaded", profileName) -- Don't touch..
end 

function Action.HealingEngineProfileSave(profileName)
	-- Debug 
	if HealingEngine:HasErrors(profileName) then 
		return 
	end 
	
	-- Work 
	local profileCurrent = HealingEngine:GetCurrentProfile()
	if not profileCurrent.Profiles[profileName] then 
		profileCurrent.Profiles[profileName] = {}
	else 
		wipe(profileCurrent.Profiles[profileName])
	end 
	
	HealingEngine:tSaveProfile(profileCurrent, profileCurrent.Profiles[profileName])
	profileCurrent.Profile = profileName -- Don't touch..
	A_Print(L["TAB"][8]["PROFILESAVED"] .. profileName)
	TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Saved", profileName) -- Don't touch..
end 

function Action.HealingEngineProfileDelete(profileName)
	-- Debug 
	if HealingEngine:HasErrors(profileName) then 
		return 
	end 
	
	-- Work 
	local profileCurrent = HealingEngine:GetCurrentProfile()
	if not profileCurrent.Profiles[profileName] then 
		A_Print(L["DEBUG"] .. profileName .. L["ISNOTFOUND"])		
		return 
	end 
	
	local _, _, _, macroID = MacroLibrary:GetInfo(profileName)
	if macroID then 
		MacroLibrary:DeleteMacro(macroID)
	end 
	
	wipe(profileCurrent.Profiles[profileName])
	profileCurrent.Profiles[profileName] = nil
	profileCurrent.Profile = "" -- Don't touch..
	A_Print(L["TAB"][8]["PROFILEDELETED"] .. profileName)
	TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Deleted", profileCurrent.Profile) -- Don't touch..
end 

-------------------------------------------------------------------------------
-- UI: Toggles
-------------------------------------------------------------------------------
local OnToggleHandler		= {
	-- Tabs 
	[1]						= {
		-- Toggles 
		Burst				= function() 
			TMW:Fire("TMW_ACTION_BURST_CHANGED")
			TMW:Fire("TMW_ACTION_CD_MODE_CHANGED") -- Taste's callback 
		end,
		ReFocus				= function() 
			Re:Initialize()
		end,
		ReTarget			= function() 
			Re:Initialize()
		end,
		LOSCheck			= function() 
			LineOfSight:Initialize() 
		end,
	},
	[2]						= {
		-- Toggles 
		AoE					= function() 
			TMW:Fire("TMW_ACTION_AOE_CHANGED")
			TMW:Fire("TMW_ACTION_AOE_MODE_CHANGED") -- Taste's callback 
		end,
		mouseover 			= function()
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "Script", "ScriptToggleMouseover")
		end,
		focus	 			= function(db)
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "Script", "ScriptToggleFocus")
			if db.focus then				
				-- Disables all SelectStopOptions
				local needset
				local sso = A_GetToggle(8, "SelectStopOptions")				
				for i = 1, #sso do
					if sso[i] then
						sso[i] = false
						needset = true
					end
				end
				if needset then
					A_SetToggle({8, "SelectStopOptions"}, sso)
				end
			else
				-- Defaults all SelectStopOptions if no one is enabled
				local sso = A_GetToggle(8, "SelectStopOptions")				
				for i = 1, #sso do
					if sso[i] then
						return
					end
				end
				A_SetToggle({8, "SelectStopOptions"}, CopyTable(Factory[8].SelectStopOptions or Factory[8].PLAYERSPEC.SelectStopOptions))
			end
		end,
		focustarget 			= function()
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "Script", "ScriptToggleFocustarget")
		end,
		targettarget 			= function()
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "Script", "ScriptToggleTargettarget")
		end,
	},
	[4]						= {
		-- Toggles 
		BlackList			= function()
			TMW:Fire("TMW_ACTION_INTERRUPTS_UI_UPDATE")			
		end,
		MainPvE				= function()
			TMW:Fire("TMW_ACTION_INTERRUPTS_UI_UPDATE")			
		end,
		MousePvE			= function()
			TMW:Fire("TMW_ACTION_INTERRUPTS_UI_UPDATE")			
		end,
		MainPvP				= function()
			TMW:Fire("TMW_ACTION_INTERRUPTS_UI_UPDATE")			
		end,
		MousePvP			= function()
			TMW:Fire("TMW_ACTION_INTERRUPTS_UI_UPDATE")			
		end,
		Heal				= function()
			TMW:Fire("TMW_ACTION_INTERRUPTS_UI_UPDATE")			
		end,
		PvP					= function()
			TMW:Fire("TMW_ACTION_INTERRUPTS_UI_UPDATE")			
		end,
	},
	[6]						= {
		-- Toggles 
		UseLeft				= function() 
			Cursor:Initialize() 
		end,
		UseRight			= function() 
			Cursor:Initialize() 
		end,
	},
	[8]						= {
		-- Toggles 
		UnitIDs 			= function() 
			TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_UPDATE") 
			TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "") 
		end,
		HealingEngineAPI	= function()
			TMW:Fire("TMW_ACTION_HEALINGENGINE_INITIALIZE") 
		end,
	},
	[9]						= {
		MetaEngine			= function()
			TMW:Fire("TMW_ACTION_METAENGINE_REFRESH_UI")
		end,
		-- Below is only working inside of UI checkboxes
		PrioritizePassive	= function()
			TMW:Fire("TMW_ACTION_METAENGINE_RECONFIGURE")
		end,
		checkselfcast		= function()
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "Script", "ScriptToggleCheckSelfCast")
		end,
		raid 				= function()
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "Script", "ScriptToggleRaid")
		end,
		party 				= function()
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "Script", "ScriptToggleParty")
		end,
		arena 				= function()
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "Script", "ScriptToggleArena")
		end,
	},
}; Action.OnToggleHandler = OnToggleHandler
local function tCustomMerge(db, custom, n, toggle, text, silence, opposite)
	for k, v in pairs(custom) do
		if db[k] ~= nil and type(db[k]) == type(v) then 
			if type(v) == "table" then 
				tCustomMerge(db[k], v, n, toggle, text, silence, opposite)
			else 
				db[k] = v					
				if not silence and text then A_Print(text .. " " .. k .. " = ", db[k]) end 
			end 
		else
			if not silence 				then A_Print(L["DEBUG"] .. n .. " " .. toggle .. " " .. k .. " = " .. toStr[v] .. " " .. L["ISNOTFOUND"] .. ". Func: Action.SetToggle") end 
		end 
	end 
	
	-- Set opposite values in remain toggles for shared table 
	if opposite then 
		for k, v in pairs(db) do 
			if custom[k] == nil and type(v) == "boolean" then
				db[k] = not v	
				if not silence and text then A_Print(text .. " " .. k .. " = ", db[k]) end 
			end
		end 
	end 
end 

function Action.SetToggle(arg, custom, opposite)
	-- @usage: Action.SetToggle({ tab.name (@number), key (@string ActionDB)[, text (@string optional for Print), silence (@boolean optional for Print)] }[, custom (@any value to set - optional)[, opposite (@boolean)]])
	-- Syntax: Action.SetToggle({ n, key[, text, silence] } [, custom[, opposite]])
	-- 'opposite' designed only for 'custom' use as table, 'opposite' if specified as 'true' will set opposite statement for remain booleans in the shared tables
	-- Note: Search by profile toggles and then by global 
	if not ActionHasRunningDB then 
		A_Print(Action.CurrentProfile .. " " .. L["NOSUPPORT"])
		return
	end 		
	 
	local n, toggle, text, silence 	= unpack(arg); n = n or "nil"; toggle = toggle or "nil"
	local owner						= Action[owner]
	local db 						= pActionDB[n]
	
	-- Check if exist 
	if not db or (db[toggle] == nil and (db[owner] == nil or db[owner][toggle] == nil)) then 
		if gActionDB[n] and gActionDB[n][toggle] then 
			db = gActionDB[n]	
		elseif gActionDB[toggle] then 
			db = gActionDB
		else 
			if not silence then A_Print(L["DEBUG"] .. n .. " " .. toggle .. " " .. L["ISNOTFOUND"] .. ". Func: Action.SetToggle") end
			return 
		end 
	elseif db[toggle] == nil then 
		db = db[owner]
	end 

	-- Run set 
	if custom ~= nil then 
		if type(custom) == "table" then 
			-- We will assume what db is also a table without check it
			local db = db[toggle]
			tCustomMerge(db, custom, n, toggle, text, silence, opposite)
		else 
			db[toggle] = custom 	
		end 
	elseif type(db[toggle]) == "table" then 
		-- Usually only for Dropdown in multi, usable for asoc too for boolean values. Logic is simply:
		-- 1 Create (or refresh) cache of all instances in DB if any is ON (true or with value), then turn all OFF if anything was ON. 
		-- 2 Or if all OFF then:
		-- 2.1 If no cache (means all was OFF) then make ON all (next time it will repeat 1 step to create cache)
		-- 2.2 If cache exist then turn ON from cache 
		-- /run TMW.db.profile.ActionDB[1][Action.PlayerSpec].Trinkets.Cache = nil		
		local db = db[toggle]
		local anyIsON = false
		for k, v in pairs(db) do 
			if v == true then 
				if not db.Cache then 
					db.Cache = {}								
				else 
					wipe(db.Cache)
				end 
				
				for k1, v1 in pairs(db) do 
					if k1 ~= "Cache" then 
						db.Cache[k1] = v1
					end
				end		
				
				anyIsON = true 
				break 
			end 
		end 
		
		if anyIsON then 
			for k, v in pairs(db) do
				if k ~= "Cache" and v == true then 
					--
						db[k] = not v					
						if not silence and text then A_Print(text .. " " .. k .. " = ", db[k]) end 
					--
				end 
			end 
		elseif db.Cache then 			
			for k, v in pairs(db.Cache) do	
				if k ~= "Cache" then 
					if db[k] ~= nil then 
						db[k] = v	
						if not silence and text then A_Print(text .. " " .. k .. " = ", db[k]) end		
					else
						-- Conflict, cache contain unexist anymore key, so delete it..
						db.Cache[k] = nil 
						if not silence 			then A_Print(L["DEBUG"] .. n .. " " .. toggle .. " " .. k .. " = " .. toStr[v] .. " " .. L["ISNOTFOUND"] .. ". Func: Action.SetToggle. " .. L["RESETED"] .. "!") end
					end 
				else 
						-- Conflict, delete cache from cache.. 
						db.Cache[k] = nil 
						if not silence 			then A_Print(L["DEBUG"] .. n .. " " .. toggle .. " " .. k .. " = {} " .. L["ISNOTFOUND"] .. ". Func: Action.SetToggle. " .. L["RESETED"] .. "!") end
				end 
			end 
		else 
			for k, v in pairs(db) do
				if k ~= "Cache" and type(v) == "boolean" then 
					--
						db[k] = not v					
						if not silence and text then A_Print(text .. " " .. k .. " = ", db[k]) end	
					-- 
				end
			end 				
		end 
	else 
		db[toggle] = not db[toggle]			 			
	end
	
	-- Run Handlers
	if OnToggleHandler[n] and OnToggleHandler[n][toggle] then
		OnToggleHandler[n][toggle](db)
	end
	
	-- For Print and UI 
	local dbValue = db[toggle]

	-- Run Print 
	local printType = type(dbValue)
	if printType ~= "nil" and printType ~= "table" and not silence and text then 
		-- Print for "table" working above, this print for boolean, number and string 
		A_Print(text, dbValue)
	end 		
			
	-- Run UI refresh 
	-- Note: Any changes done here must be synchronized with InterfaceLanguage
	if tabFrame then 		
		local spec 	= owner .. CL
		local tab 	= tabFrame.tabs[n]
		local kid	= tab and tab.childs[spec] and tab.childs[spec].toggleWidgets and tab.childs[spec].toggleWidgets[toggle]
		if kid then 
			if kid.Identify.Type == "Checkbox" then
				if n == 4 or n == 8 then 
					-- Exception to trigger OnValueChanged callback 
					kid:SetChecked(dbValue)
				else 
					kid.isChecked = dbValue 
					if kid.isChecked then
						kid.checkedTexture:Show()
					else 
						kid.checkedTexture:Hide()
					end							
				end
			end 
			
			if kid.Identify.Type == "Dropdown" then						
				if kid.multi then 
					for i, v in ipairs(kid.optsFrame.scrollChild.items) do 
						v.isChecked  = dbValue[i]
						kid.value[i] = dbValue[i]
						if v.isChecked then 
							v.checkedTexture:Show()									
						else 
							v.checkedTexture:Hide()
						end 
					end 						
					kid:SetText(kid:FindValueText(dbValue))
				else 
					kid.value = dbValue
					kid:SetText(kid:FindValueText(dbValue))
				end 
			end 
			
			if kid.Identify.Type == "Slider" then							
				kid:SetValue(dbValue) 
			end
			
			-- ScrollTable should be updated through events/callbacks
		end 			
	end 		 	
end 	

function Action.GetToggle(n, toggle, specID)
	-- @usage: Action.GetToggle(tab.name (@number), key (@string ActionDB)[, specID (@number)])
	if not ActionHasRunningDB then 		
		if toggle == "FPS" then
			return TMWdbglobal.Interval
		end 
		if ActionHasFinishedLoading then 
			A_Print(Action.CurrentProfile .. " - Toggle: [" .. (n or "") .. "] " .. toggle .. " " .. (L and L["NOSUPPORT"] or ""), nil, true)
		end
		return
	end 
	
	local bool 
	if gActionDB[toggle] ~= nil then 	
		bool = gActionDB[toggle] 
	elseif pActionDB[n] then 
		if pActionDB[n][toggle] ~= nil then 
			bool = pActionDB[n][toggle] 
		elseif pActionDB[n][specID or Action.PlayerSpec] ~= nil then
			if toggle == "HeartOfAzeroth" then 
				bool = BuildToC >= 80200 and BuildToC < 90001 and pActionDB[n][specID or Action.PlayerSpec][toggle]
			elseif toggle == "Covenant" then 
				bool = BuildToC >= 90001 and pActionDB[n][specID or Action.PlayerSpec][toggle]
			else
				bool = pActionDB[n][specID or Action.PlayerSpec][toggle] 
			end 
		end 
	end 

	return bool	
end 	

ActionDataPrintCache.DisableMinimap = {1, "DisableMinimap"}
function Action.ToggleMinimap(state)
	if Action.Minimap then 
		if type(state) == "nil" then 
			if Action.IsInitialized then 
				ActionDataPrintCache.DisableMinimap[3] = L["TAB"][1]["DISABLEMINIMAP"] .. " : "
				A_SetToggle(ActionDataPrintCache.DisableMinimap)
			end
			if not (pActionDB and not pActionDB[1].DisableMinimap) then 
				LibDBIcon:Hide("ActionUI")
			else 
				LibDBIcon:Show("ActionUI")
			end 
		else
			if state then 
				LibDBIcon:Show("ActionUI")
			else 
				LibDBIcon:Hide("ActionUI")
			end 
		end 
	end 
end 

function Action.MinimapIsShown()
	-- @return boolean 
	return LibDBIcon.objects["ActionUI"] and LibDBIcon.objects["ActionUI"]:IsShown()
end 

function Action.ToggleMainUI()
	if not Action.PlayerSpec or (not Action.MainUI and not Action.IsInitialized) then 
		return 
	end 
	local specID, specName 	= Action.PlayerSpec, Action.PlayerSpecName 
	local spec 				= specID .. Action.GetCL()
	local MainUI			= Action.MainUI
	if MainUI then 	
		if not MainUI:GetPropagateKeyboardInput() and not InCombatLockdown() then 
			MainUI:SetPropagateKeyboardInput(true)
		end 
		
		if MainUI:IsShown() then 
			MainUI:SetShown(not MainUI:IsShown())
			return
		elseif not pActionDB then -- MainUI.Profiles.OnValueChanged
			return 
		else 
			MainUI:SetShown(not MainUI:IsShown())	
			MainUI.PDateTime:SetText(Action.Data.ProfileUI.DateTime or "")	
			MainUI.Profiles:SetText(Action.CurrentProfile or "")
		end 
	else 
		Action.MainUI = StdUi:Window(UIParent, 540, 650, "The Action")
		MainUI		  = Action.MainUI		
		MainUI.titlePanel.label:SetFontSize(20)
		MainUI.default_w = MainUI:GetWidth()
		MainUI.default_h = MainUI:GetHeight()
		MainUI.titlePanel:SetPoint("TOP", 0, -20)
		MainUI:SetFrameStrata("HIGH")
		MainUI:SetPoint("CENTER")
		MainUI:SetShown(true) 
		MainUI:RegisterEvent("BARBER_SHOP_OPEN")
		MainUI:RegisterEvent("BARBER_SHOP_CLOSE")		
		MainUI:SetScript("OnEvent", function(self, event, ...)
			if (event == "BARBER_SHOP_OPEN" or event == "BARBER_SHOP_CLOSE") and self:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)
				
		MainUI:EnableKeyboard(true)
		if not InCombatLockdown() then 
			MainUI:SetPropagateKeyboardInput(true)
		end 
		-- Catches the game menu bind just before it fires.
		MainUI:SetScript("OnKeyDown", function(self, Key)				
			if GetBindingFromClick(Key) == "TOGGLEGAMEMENU" and self:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)
		-- Disallows closing the dialogs once the game menu bind is processed.
		hooksecurefunc("ToggleGameMenu", function()			
			if MainUI:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)	
		-- Catches shown (aka clicks) on default "?" GameMenu 
		MainUI.GameMenuFrame = _G.GameMenuFrame
		MainUI.GameMenuFrame:HookScript("OnShow", function()
			if MainUI:IsShown() then 
				Action.ToggleMainUI()
			end 
		end)
		
		MainUI.Session = StdUi:Subtitle(MainUI, L["TAB"]["SESSION"])
		MainUI.Session.OnTimerTick = function()		
			local remain, isStop = Action.GetSession()
			local remain_profile, remain_profile_secs, userStatus, profileName, locales = Action.ProfileSession:GetSession()
			if profileName then 
				if MainUI.Session.fontHeight ~= "compact" then 
					MainUI.Session.fontHeight = "compact"
					MainUI.Session.fontSize = MainUI.Session.fontSize or select(2, MainUI.Session:GetFont())
					MainUI.Session:SetFontSize( MainUI.Session.fontSize * 1.015 )
				end
				
				userStatus 	  = userStatus or "UNKNOWN"
				local CL 	  = Action.GetCL()
				local STATUS  = locales[userStatus] and (locales[userStatus][CL] or locales[userStatus].enUS) or L["PROFILESESSION"][userStatus]
				--local PROFILE = locales and locales.PROFILE and (locales.PROFILE[CL] or locales.PROFILE.enUS) or L["PROFILESESSION"]["PROFILE"]
				--MainUI.Session:SetText(L["TAB"]["SESSION"]:join(remain, (" | %s %s %s"):format(PROFILE, remain_profile, STATUS)))
				MainUI.Session:SetText(strjoin("", L["TAB"]["SESSION"], remain, (" | %s %s"):format(remain_profile, STATUS)))
			else 
				if MainUI.Session.fontHeight ~= "normal" then 
					MainUI.Session.fontHeight = "normal"
					MainUI.Session.fontSize = MainUI.Session.fontSize or select(2, MainUI.Session:GetFont())
					MainUI.Session:SetFontSize( MainUI.Session.fontSize * 1.05 )
				end 
				
				MainUI.Session:SetText(strjoin("", L["TAB"]["SESSION"], remain))
			end 
			if isStop and remain_profile_secs == 0 then 
				Action.TimerDestroy("Session")
			end 
		end		
		StdUi:GlueTop(MainUI.Session, MainUI, 11, -10, "LEFT")
		MainUI:HookScript("OnShow", function(self)
			if MainUI.ProfileSession.UI.lastState then 
				MainUI.ProfileSession.UI.lastState = nil 
				MainUI.ProfileSession.UI:Switch(MainUI.ProfileSession.UI.mouse_button)
			end 
			MainUI.Session.OnTimerTick()
			Action.TimerSetTicker("Session", 0.5, MainUI.Session.OnTimerTick)
		end)
		MainUI:HookScript("OnHide", function(self)
			if MainUI.ProfileSession.UI:IsShown() then
				MainUI.ProfileSession.UI.lastState = "shown"
				MainUI.ProfileSession.UI:Switch()
			end 
			Action.TimerDestroy("Session")
		end)
		MainUI.Session.OnTimerTick()
		Action.TimerSetTicker("Session", 0.5, MainUI.Session.OnTimerTick)
		
		MainUI.PDateTime = StdUi:Subtitle(MainUI, Action.Data.ProfileUI.DateTime or "")
		MainUI.PDateTime:SetJustifyH("RIGHT")
		
		MainUI.GDateTime = StdUi:Subtitle(MainUI, L["GLOBALAPI"] .. Action.DateTime)	
		MainUI.GDateTime:SetJustifyH("RIGHT")
		
		local r, g, b, a = MainUI.GDateTime:GetTextColor()
		MainUI.Profiles = StdUi:Dropdown(MainUI, 170, MainUI.GDateTime:GetHeight() * 1.5)
		MainUI.Profiles:SetText(Action.CurrentProfile or "")
		MainUI.Profiles:SetBackdropColor(0, 0, 0, 0)
		MainUI.Profiles:SetBackdropBorderColor(r, g, b, 0.25)
		MainUI.Profiles:RegisterForClicks("LeftButtonUp")
		MainUI.Profiles:SetScript("OnClick", function(self, button, down)
			if InCombatLockdown() then 
				if self.optsFrame:IsVisible() then 
					self:ToggleOptions()
				end 			
			else 
				if not self.opts then 
					self.opts = {}
				else 
					wipe(self.opts)
				end 
				
				for profile in pairs(TMWdb.profiles) do 
					self.opts[#self.opts + 1] = { text = profile, value = profile }
				end 
				
				tsort(self.opts, self.SortDSC)
				
				self:SetOptions(self.opts)
				self:ToggleOptions()
				
				local height = MainUI:GetHeight() - 40
				self.optsFrame:SetHeight(math_min(#self.opts * 20 + 4, height))
				self.optsFrame.scrollChild:SetHeight(math_min(#self.opts * 20, height))
			end 
		end)				
		MainUI.Profiles.OnValueChanged = function(self, val)          
			if InCombatLockdown() then
				self.value = Action.CurrentProfile or ""
				self:SetText(Action.CurrentProfile or "")
				if self.optsFrame:IsVisible() then 
					self:ToggleOptions()
				end 
			else 
				TMWdb:SetProfile(val)
				Action.ToggleMainUI()
			end 
		end		
		MainUI.Profiles.SortDSC = function(a, b)
			return a.text:lower() < b.text:lower()
		end
		MainUI.Profiles.dropTex:ClearAllPoints()
		MainUI.Profiles.text:SetJustifyH("RIGHT")		
		MainUI.Profiles.text:SetTextColor(r, g, b, a)	
		MainUI.Profiles.optsFrame:SetBackdropColor(0, 0, 0, 1)
		MainUI.Profiles.optsFrame:SetFrameStrata("TOOLTIP")
		StdUi:GlueAcross(MainUI.Profiles.text, MainUI.Profiles, 19, -2, -2, 2)
		
		StdUi:GlueLeft(MainUI.Profiles.dropTex, MainUI.Profiles, 5, 0, true)
		StdUi:GlueRight(MainUI.Profiles.text, MainUI.Profiles, 0, 0, true)
		StdUi:GlueBefore(MainUI.Profiles, MainUI.closeBtn, -5, 2)
		StdUi:GlueBelow(MainUI.PDateTime, MainUI.Profiles, 0, 0, "RIGHT")
		StdUi:GlueBelow(MainUI.GDateTime, MainUI.PDateTime, 0, 0, "RIGHT")
		
		MainUI.AllReset = StdUi:SquareButton(MainUI, MainUI.closeBtn:GetWidth(), MainUI.Profiles:GetHeight())	
		MainUI.AllReset:SetBackdropColor(0, 0, 0, 0)		
		MainUI.AllReset:SetBackdropBorderColor(0, 0, 0, 0)		
		MainUI.AllReset:SetIcon([[Interface\Buttons\UI-RefreshButton]], MainUI.closeBtn:GetWidth(), MainUI.Profiles:GetHeight(), true)		
		MainUI.AllReset:SetScript("OnClick", function()
			MainUI.ResetQuestion:SetShown(not MainUI.ResetQuestion:IsShown())
		end)
		StdUi:FrameTooltip(MainUI.AllReset, L["TAB"]["RESETBUTTON"], nil, "TOP", true)	
		StdUi:GlueLeft(MainUI.AllReset, MainUI.Profiles, -1, 0)
		
		MainUI.ProfileSession = StdUi:SquareButton(MainUI, MainUI.closeBtn:GetWidth(), MainUI.Profiles:GetHeight())	
		MainUI.ProfileSession:SetBackdropColor(0, 0, 0, 0)		
		MainUI.ProfileSession:SetBackdropBorderColor(0, 0, 0, 0)		
		MainUI.ProfileSession:SetIcon([[Interface\Buttons\UI-GuildButton-PublicNote-Up]], MainUI.closeBtn:GetWidth(), MainUI.Profiles:GetHeight(), true)	
		MainUI.ProfileSession:RegisterForClicks("LeftButtonUp", "RightButtonUp")
		MainUI.ProfileSession:SetScript("OnClick", function(this, button)
			this.UI.lastButton = button
			this.UI:Switch(button)
		end)
		MainUI.ProfileSession.UI = Action.ProfileSession.UI
		StdUi:FrameTooltip(MainUI.ProfileSession, L["PROFILESESSION"]["BUTTON"], nil, "TOP", true)	
		StdUi:GlueLeft(MainUI.ProfileSession, MainUI.AllReset, -1, 0)
		
		MainUI.ResetQuestion = StdUi:Window(MainUI, 350, 300, L["TAB"]["RESETQUESTION"])
		MainUI.ResetQuestion:SetPoint("CENTER")
		MainUI.ResetQuestion:SetFrameStrata("TOOLTIP")
		MainUI.ResetQuestion:SetFrameLevel(50)
		MainUI.ResetQuestion:SetBackdropColor(0, 0, 0, 1)
		MainUI.ResetQuestion:SetMovable(false)
		MainUI.ResetQuestion:SetShown(false)
		MainUI.ResetQuestion:SetScript("OnDragStart", nil)
		MainUI.ResetQuestion:SetScript("OnDragStop", nil)
		MainUI.ResetQuestion:SetScript("OnReceiveDrag", nil)
		
		MainUI.CheckboxSaveActions 		= StdUi:Checkbox(MainUI.ResetQuestion, L["TAB"]["SAVEACTIONS"], 300)
		MainUI.CheckboxSaveInterrupt 	= StdUi:Checkbox(MainUI.ResetQuestion, L["TAB"]["SAVEINTERRUPT"], 300)			
		MainUI.CheckboxSaveDispel 		= StdUi:Checkbox(MainUI.ResetQuestion, L["TAB"]["SAVEDISPEL"], 300)
		MainUI.CheckboxSaveMouse		= StdUi:Checkbox(MainUI.ResetQuestion, L["TAB"]["SAVEMOUSE"], 300)	
		MainUI.CheckboxSaveMSG 			= StdUi:Checkbox(MainUI.ResetQuestion, L["TAB"]["SAVEMSG"], 300)
		MainUI.CheckboxSaveHE 			= StdUi:Checkbox(MainUI.ResetQuestion, L["TAB"]["SAVEHE"], 300)
		MainUI.CheckboxSaveHotkeys		= StdUi:Checkbox(MainUI.ResetQuestion, L["TAB"]["SAVEHOTKEYS"], 300)
		
		MainUI.Yes = StdUi:Button(MainUI.ResetQuestion, 150, 35, L["YES"])		
		StdUi:GlueBottom(MainUI.Yes, MainUI.ResetQuestion, 20, 20, "LEFT")
		MainUI.Yes:SetScript("OnClick", function()
			local ProfileSave, GlobalSave = {}, {}
			
			local profileVer = pActionDB.Ver
			local globalVer  = gActionDB.Ver 
			
			if MainUI.CheckboxSaveActions:GetChecked() then 
				ProfileSave[3] = {}
				for k, v in pairs(pActionDB[3]) do 
					if type(v) == "table" then
						ProfileSave[3][k] = v					
					end 
				end
			end 
			if MainUI.CheckboxSaveInterrupt:GetChecked() then 
				ProfileSave[4] = {}
				for k, v in pairs(pActionDB[4]) do 
					if type(v) == "table" then 
						v.Min = nil 
						v.Max = nil 
					end 
					
					ProfileSave[4][k] = v
				end
			end 
			if MainUI.CheckboxSaveDispel:GetChecked() then 
				GlobalSave[5] = {}
				for k, v in pairs(gActionDB[5]) do					
					GlobalSave[5][k] = v					
				end
			end 
			if MainUI.CheckboxSaveMouse:GetChecked() then 	
				ProfileSave[6] = {}
				for k, v in pairs(pActionDB[6]) do
					if type(v) == "table" then 
						if not ProfileSave[6][k] then 
							ProfileSave[6][k] = {}
						end 
						ProfileSave[6][k].PvE = v.PvE
						ProfileSave[6][k].PvP = v.PvP
					end 
				end
			end 
			if MainUI.CheckboxSaveMSG:GetChecked() then 	
				ProfileSave[7] = {}
				for k, v in pairs(pActionDB[7]) do
					if type(v) == "table" then 	
						if not ProfileSave[7][k] then 
							ProfileSave[7][k] = {}
						end 
						ProfileSave[7][k].msgList = v.msgList						
					end 
				end
			end 
			if MainUI.CheckboxSaveHE:GetChecked() then 	
				ProfileSave[8] = {}
				for k, v in pairs(pActionDB[8]) do
					if type(v) == "table" then 	
						ProfileSave[8][k] = v					
					end 
				end
			end 
			if MainUI.CheckboxSaveHotkeys:GetChecked() then 	
				ProfileSave[9] = {}
				for k, v in pairs(pActionDB[9]) do
					ProfileSave[9][k] = v
				end
			end 
			
			wipe(gActionDB)
			wipe(pActionDB)
			if next(ProfileSave) then 
				ProfileSave.Ver = profileVer 
				TMWdbprofile.ActionDB = ProfileSave				
			else
				TMWdbprofile.ActionDB = nil 
			end 
			if next(GlobalSave) then 
				GlobalSave.Ver = globalVer
				TMWdbglobal.ActionDB = GlobalSave
			else 
				TMWdbglobal.ActionDB = nil 
			end 
			
			C_UI.Reload()	
		end)
		
		MainUI.No = StdUi:Button(MainUI.ResetQuestion, 150, 35, L["NO"])
		StdUi:GlueBottom(MainUI.No, MainUI.ResetQuestion, -20, 20, "RIGHT")
		MainUI.No:SetScript("OnClick", function()
			MainUI.ResetQuestion:Hide()
		end)			

		StdUi:GlueBelow(MainUI.CheckboxSaveActions, MainUI.ResetQuestion.titlePanel.label, -10, -5, "LEFT") -- 30 + MainUI.Yes:GetHeight()
		StdUi:GlueBelow(MainUI.CheckboxSaveInterrupt, MainUI.CheckboxSaveActions, 0, -10, "LEFT")
		StdUi:GlueBelow(MainUI.CheckboxSaveDispel, MainUI.CheckboxSaveInterrupt, 0, -10, "LEFT")
		StdUi:GlueBelow(MainUI.CheckboxSaveMouse, MainUI.CheckboxSaveDispel, 0, -10, "LEFT")
		StdUi:GlueBelow(MainUI.CheckboxSaveMSG, MainUI.CheckboxSaveMouse, 0, -10, "LEFT")
		StdUi:GlueBelow(MainUI.CheckboxSaveHE, MainUI.CheckboxSaveMSG, 0, -10, "LEFT")
		StdUi:GlueBelow(MainUI.CheckboxSaveHotkeys, MainUI.CheckboxSaveHE, 0, -10, "LEFT")
		
		tabFrame = StdUi:TabPanel(MainUI, nil, nil, {
			{
				name = 1,
				title = L["TAB"][1]["HEADBUTTON"],
				childs = {},
			},
			{
				name = 2,
				title = specName,
				childs = {},
			},
			{
				name = 3,
				title = L["TAB"][3]["HEADBUTTON"],
				childs = {},
			},
			{
				name = 4,
				title = L["TAB"][4]["HEADBUTTON"],	
				childs = {},		
			},
			{
				name = 5,
				title = L["TAB"][5]["HEADBUTTON"],		
				childs = {},
			},
			{
				name = 6,
				title = L["TAB"][6]["HEADBUTTON"],		
				childs = {},
			},			
			{
				name = 7,
				title = L["TAB"][7]["HEADBUTTON"],	
				childs = {},
			},
			{
				name = 8,
				title = L["TAB"][8]["HEADBUTTON"],
				childs = {},
			},
			{
				name = 9,
				title = L["TAB"][9]["HEADBUTTON"],
				childs = {},
			},
		}); MainUI.tabFrame = tabFrame
		StdUi:GlueAcross(tabFrame, MainUI, 10, -60, -10, 10)
		tabFrame.container:SetPoint("TOPLEFT", tabFrame.buttonContainer, "BOTTOMLEFT", 0, 0)
		tabFrame.container:SetPoint("TOPRIGHT", tabFrame.buttonContainer, "BOTTOMRIGHT", 0, 0)	
		
		-- Redraw buttons to split them into second line above 
		tabFrame.OriginalDrawButtons = tabFrame.DrawButtons
		tabFrame.CustomDrawButtons = function(self)
			local usedWidth = 0
			local containerWidth = self.buttonContainer:GetWidth()
			
			local prevBtn
			for i = 1, #self.tabs do 
				usedWidth = usedWidth + self.tabs[i].button:GetWidth()
				self.tabs[i].button:ClearAllPoints()
				
				if not prevBtn then 
					self.stdUi:GlueTop(self.tabs[i].button, self.buttonContainer, 0, 0, "LEFT")
				elseif usedWidth > containerWidth then 
					usedWidth = usedWidth - containerWidth
					self.stdUi:GlueAbove(self.tabs[i].button, self.buttonContainer, 0, 1, "LEFT")
				else 
					self.stdUi:GlueRight(self.tabs[i].button, prevBtn, 5, 0)
				end 
				
				usedWidth = usedWidth + 5
				prevBtn = self.tabs[i].button
			end 
		end 
		tabFrame.DrawButtons = function(self)
			self:OriginalDrawButtons()
			self:CustomDrawButtons()
		end 
		
		-- Create resizer		
		MainUI.resizer = StdUi:CreateResizer(MainUI)
		if MainUI.resizer then 							
			function MainUI.UpdateResizeForKids(kids)
				for _, kid in ipairs(kids) do							
					-- EasyLayout (kid parent)
					if kid.layout and kid.rows then 
						kid:DoLayout()
					end 	
					-- Dropdown (kid parent)
					if kid.dropTex then 
						-- EasyLayout will resize button so we can don't care
						-- Resize scroll "panel" (container) 
						local dropdownWidth = kid:GetWidth()
						kid.optsFrame:SetWidth(dropdownWidth)
						-- Resize scroll "lines" (list grid)
						for _, item in ipairs(kid.optsFrame.scrollChild.items) do 
							item:SetWidth(dropdownWidth)									
						end 									
					end 
					-- ScrollTable (kid parent)
					if kid.data and kid.columns then 
						local currWidth, needRowResize
						local remainWidth, c = 0, 0

						for i, column in ipairs(kid.columns) do 
							if column.defaultwidth then
								c = c + 1										
								if not currWidth then 
									currWidth = MainUI:GetWidth()
								end 
								
								-- Column resize
								column.width = round(column.defaultwidth + remainWidth + ((currWidth - MainUI.default_w) / (column.resizeDivider or 1)), 0)
								if column.maxwidth and column.width > column.maxwidth then 
									-- If column limited to width then we can add remain width to rest columns
									-- Note: Currently works only if first found indexes have it, don't want to add more code here due performance waste
									-- If need to reverse of adding remain width column must have 'column.addwidthtoprevious = true'
									remainWidth = remainWidth + (column.width - column.maxwidth)
									column.width = column.maxwidth
								end 
								
								if column.addwidthtoprevious then 
									kid.columns[i - 1]:SetWidth(kid.columns[i - 1].width + remainWidth)
									remainWidth = 0
								end 
								
								column:SetWidth(column.width)
								needRowResize = true 

								if not column.resizeDivider or c >= column.resizeDivider then 
									break 
								end
							end 
						end
						
						if needRowResize then 
							-- Fix StdUi 
							-- Another bug in Lib.. without this rows will jumps down if base parent has scrollchild as well 
							if not kid.hasClampDisabled then 
								kid.scrollFrame:SetClampedToScreen(false)
								kid.hasClampDisabled = true 
							end 
							-- Row resize
							kid.numberOfRows = kid.defaultrows.numberOfRows + round((MainUI:GetHeight() - MainUI.default_h) / kid.defaultrows.rowHeight, 0)
							kid:SetDisplayRows(kid.numberOfRows, kid.rowHeight)	
						end 
					end 
				end 	
			end

			local lastUpdate	
			function MainUI.UpdateResize(self, _, manual) 
				if not manual and TMW.time - (lastUpdate or 0) < 0.05 then 
					return 
				end 
				
				tabFrame:CustomDrawButtons()
				lastUpdate 	= manual == true and 0 or TMW.time 												
				local spec	= Action.PlayerSpec .. CL
				for i, tab in ipairs(tabFrame.tabs) do	
					if tab.childs[spec] then	
						-- Easy Layout (base parent)
						local anchor = StdUi:GetAnchor(tab, spec)
						if anchor.layout and anchor.rows then -- and (manual or (i > 2 and i ~= 8)) then 
							anchor:DoLayout()
						end	

						MainUI.UpdateResizeForKids(StdUi:GetAnchorKids(tab, spec))		
					end 	
				end
			end
			
			local isSizing = false
			MainUI.resizer.resizer.resizeButton:HookScript("OnMouseUp", function()	
				isSizing = false
				MainUI:SetScript("OnUpdate", nil)
				MainUI:UpdateResize(nil, true)
			end)
			MainUI.resizer.resizer.resizeButton:HookScript("OnMouseDown", function()	
				isSizing = true
				MainUI:SetScript("OnUpdate", MainUI.UpdateResize)
			end)
			-- Next events making semi-fix overleap problem
			MainUI.resizer.resizer.resizeButton:HookScript("OnLeave", function() 
				if not isSizing then 
					MainUI:UpdateResize(nil, true)
				end 
			end)
			MainUI.resizer.resizer.resizeButton:HookScript("OnEnter", function() 
				if not isSizing then 
					MainUI:UpdateResize(nil, true)
				end 
			end)			
			-- I don't know how to fix layout overleap problem caused by resizer after finish, so I did some trick through this:
			-- If you have a better idea let me know - just please no coroutine
			MainUI:HookScript("OnHide", function(self) 
				MainUI.RememberTab = tabFrame.selected 
				tabFrame:SelectTab(tabFrame.tabs[1].name)		
				MainUI:UpdateResize(nil, true)
			end)
			MainUI:HookScript("OnShow", function(self)
				if MainUI.RememberTab then 
					tabFrame:SelectTab(tabFrame.tabs[MainUI.RememberTab].name)
				end 				
				MainUI:UpdateResize(nil, true)
				TMW:TT(self.resizer.resizer.resizeButton, L["RESIZE"], L["RESIZE_TOOLTIP"], 1, 1)
			end)
		end 
	end 
	
	Action.PlaySound(5977)
	
	tabFrame:EnumerateTabs(function(tab)
		for k, v in pairs(tab.childs) do
			if k ~= spec then 
				v:Hide()
			end 
		end		
		if tab.childs[spec] then 
			tab.childs[spec]:Show()				
			return
		end  
		if tab.name == 1 or tab.name == 2 or tab.name == 8 then 
			tab.childs[spec] = StdUi:ScrollFrame(tab.frame, tab.frame:GetWidth(), tab.frame:GetHeight()) 			
			tab.childs[spec]:SetAllPoints()
			tab.childs[spec]:Show()			
		else 
			tab.childs[spec] = StdUi:Frame(tab.frame) 
			tab.childs[spec]:SetAllPoints()		
			tab.childs[spec]:Show()
		end
		tab.childs[spec].specID = specID -- Retail uses it for InterfaceLanguage.OnValueChanged
		
		local MainUI			= Action.MainUI
		local ActionConst		= Action.Const
		local ActionData		= Action.Data
		local themeON			= ActionData.theme.on
		local themeOFF			= ActionData.theme.off
		local themeHeight		= ActionData.theme.dd.height
		local themeWidth		= ActionData.theme.dd.width		
		
		local anchor 			= StdUi:GetAnchor(tab, spec) 		
		local tabName			= tab.name
		local tabDB				= pActionDB[tabName]
		local specDB 			= tabDB and tabDB[specID]		
		TMW:RegisterCallback("TMW_ACTION_DB_UPDATED", function()
			if pActionDB then 
				tabDB			= pActionDB[tabName]
				specDB 			= tabDB and tabDB[specID]
			end 
		end)
		
		-- Tab Title 
		local UI_Title = StdUi:Subtitle(anchor, tab.title)
		UI_Title:SetFont(UI_Title:GetFont(), 15)
		StdUi:GlueTop(UI_Title, anchor, 0, -10)
		if not StdUi.config.font.color.yellow then 
			local colored = { UI_Title:GetTextColor() }
			StdUi.config.font.color.yellow = { r = colored[1], g = colored[2], b = colored[3], a = colored[4] }
		end 
		
		local UI_Separator = StdUi:Subtitle(anchor, "")
		StdUi:GlueBelow(UI_Separator, UI_Title, 0, -5)
		
		-- We should leave "OnShow" handlers because user can swap language, otherwise in performance case better remove it 		
		if tabName == 1 then 	
			UI_Title:SetText(L["TAB"][tabName]["HEADTITLE"])
			-- Fix StdUi 
			-- Lib has missed scrollframe as widget
			StdUi:InitWidget(anchor)			
			StdUi:EasyLayout(anchor, { padding = { top = 40, right = 10 + 20 } })
			
			local PvEPvPToggle = StdUi:Button(anchor, StdUi:GetWidthByColumn(anchor, 5.5), themeHeight, L["TOGGLEIT"])
			PvEPvPToggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			PvEPvPToggle:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					Action.ToggleMode()
				elseif button == "RightButton" then 
					Action.CraftMacro("PvEPvPToggle", [[/run Action.ToggleMode()]])	
				end 
			end)
			StdUi:FrameTooltip(PvEPvPToggle, L["TAB"][tabName]["PVEPVPTOGGLETOOLTIP"], nil, "TOPRIGHT", true)
			PvEPvPToggle.FontStringTitle = StdUi:Subtitle(PvEPvPToggle, L["TAB"][tabName]["PVEPVPTOGGLE"])
			StdUi:GlueAbove(PvEPvPToggle.FontStringTitle, PvEPvPToggle)					
			
			local PvEPvPresetbutton = StdUi:SquareButton(anchor, PvEPvPToggle:GetHeight(), PvEPvPToggle:GetHeight(), "DELETE")
			PvEPvPresetbutton:SetScript("OnClick", function()
				Action.IsLockedMode = false
				Action.IsInPvP = Action:CheckInPvP()	
				Action.Print(L["RESETED"] .. ": " .. (Action.IsInPvP and "PvP" or "PvE"))
				TMW:Fire("TMW_ACTION_MODE_CHANGED")
			end)
			StdUi:FrameTooltip(PvEPvPresetbutton, L["TAB"][tabName]["PVEPVPRESETTOOLTIP"], nil, "TOPRIGHT", true)	
			StdUi:GlueAfter(PvEPvPresetbutton, PvEPvPToggle, 0, 0)

			local InterfaceLanguages = {
				{ text = L["TAB"]["AUTO"], value = "Auto" },	
			}
			for Language in pairs(Localization) do 
				tinsert(InterfaceLanguages, { text = Language .. " " .. Localization[Language]["TAB"]["LANGUAGE"], value = Language })
			end 
			local InterfaceLanguage = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, InterfaceLanguages)         
			InterfaceLanguage:SetValue(gActionDB.InterfaceLanguage)
			InterfaceLanguage.OnValueChanged = function(self, val)                				
				gActionDB.InterfaceLanguage = val				
				Action.GetLocalization()	
				
				MainUI.AllReset.stdUiTooltip:SetText(L["TAB"]["RESETBUTTON"])
				MainUI.ProfileSession.stdUiTooltip:SetText(L["PROFILESESSION"]["BUTTON"])
				if MainUI.ProfileSession.UI:IsShown() then 
					MainUI.ProfileSession.UI:Switch(MainUI.ProfileSession.UI.lastButton)
				end 
				MainUI.GDateTime:SetText(L["GLOBALAPI"] .. DateTime)
				MainUI.ResetQuestion.titlePanel.label:SetText(L["TAB"]["RESETQUESTION"])				
				MainUI.Yes.text:SetText(L["YES"])
				MainUI.No.text:SetText(L["NO"])
				MainUI.CheckboxSaveActions:SetText(L["TAB"]["SAVEACTIONS"])
				MainUI.CheckboxSaveInterrupt:SetText(L["TAB"]["SAVEINTERRUPT"])
				MainUI.CheckboxSaveDispel:SetText(L["TAB"]["SAVEDISPEL"])
				MainUI.CheckboxSaveMouse:SetText(L["TAB"]["SAVEMOUSE"])
				MainUI.CheckboxSaveMSG:SetText(L["TAB"]["SAVEMSG"])
				MainUI.CheckboxSaveHE:SetText(L["TAB"]["SAVEHE"])
				
				if StdUi.colorPickerFrame then 
					StdUi.colorPickerFrame.okButton.text:SetText(L["APPLY"])
					StdUi.colorPickerFrame.cancelButton.text:SetText(L["CLOSE"])
					StdUi.colorPickerFrame.resetButton.text:SetText(L["RESET"])
				end 
				
				for i = 1, #tabFrame.tabs do 
					tabFrame.tabs[i].title = L["TAB"][i] and L["TAB"][i]["HEADBUTTON"] or tabFrame.tabs[i].title
				end 
				tabFrame:DrawButtons()		
				
				local ScrollTable
				local frameLimit = 0
				for _, thisTab in ipairs(tabFrame.tabs) do
					for childSpec, child in pairs(thisTab.childs) do 
						if childSpec ~= spec and child.toggleWidgets then 
							for toggle, kid in pairs(child.toggleWidgets) do 
								local dbValue = Action.GetToggle(thisTab.name, toggle, child.specID)
								
								-- SetValue not uses here because it will trigger OnValueChanged which we don't need in case of performance optimization
								if kid.Identify.Type == "Checkbox" then
									if n == 4 or n == 8 then 
										-- Exception to trigger OnValueChanged callback 
										kid:SetChecked(dbValue)
									else 
										kid.isChecked = dbValue
										if kid.isChecked then
											kid.checkedTexture:Show()
										else 
											kid.checkedTexture:Hide()
										end
									end 
								end 
								
								if kid.Identify.Type == "Dropdown" then						
									if kid.multi then 											
										for i, v in ipairs(kid.optsFrame.scrollChild.items) do 
											v.isChecked  = dbValue[i]	
											kid.value[i] = dbValue[i]	
											if v.isChecked then 
												v.checkedTexture:Show()									
											else 
												v.checkedTexture:Hide()
											end 
										end 						
										kid:SetText(kid:FindValueText(dbValue))
									else 
										kid.value = dbValue
										kid.text:SetText(kid:FindValueText(dbValue))
									end 
								end 
								
								if kid.Identify.Type == "Slider" then	
									kid:SetValue(dbValue) 
								end 

								-- ScrollTable updates every time when tab triggers OnShow event or through additional events/callbacks
							end
								
							frameLimit = frameLimit + #StdUi:GetAnchorKids(thisTab, childSpec)							 
						end 
					end 
				end	
				
				if frameLimit >= 1600 then -- 1600 should be super safe zone to don't overleap frame limit, broken limit at 2411+ 
					C_UI.Reload()
					return 
				end 
				
				Action.ToggleMainUI()
				Action.ToggleMainUI()	
			end			
			InterfaceLanguage.Identify = { Type = "Dropdown", Toggle = "InterfaceLanguage" }
			InterfaceLanguage.FontStringTitle = StdUi:Subtitle(InterfaceLanguage, L["TAB"][tabName]["CHANGELANGUAGE"])
			StdUi:GlueAbove(InterfaceLanguage.FontStringTitle, InterfaceLanguage)
			InterfaceLanguage.text:SetJustifyH("CENTER")															
			
			local AutoTarget = StdUi:Checkbox(anchor, L["TAB"][tabName]["AUTOTARGET"])	
			AutoTarget:SetChecked(specDB.AutoTarget)	
			AutoTarget:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			AutoTarget:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					specDB.AutoTarget = not specDB.AutoTarget	
					self:SetChecked(specDB.AutoTarget)	
					Action.Print(L["TAB"][tabName]["AUTOTARGET"] .. ": ", specDB.AutoTarget)	
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["AUTOTARGET"], [[/run Action.SetToggle({]] .. tabName .. [[, "AutoTarget", "]] .. L["TAB"][tabName]["AUTOTARGET"] .. [[: "})]])	
				end 
			end)
			AutoTarget.Identify = { Type = "Checkbox", Toggle = "AutoTarget" }			
			StdUi:FrameTooltip(AutoTarget, L["TAB"][tabName]["AUTOTARGETTOOLTIP"], nil, "TOPRIGHT", true)		
			AutoTarget.FontStringTitle = StdUi:Subtitle(AutoTarget, L["TAB"][tabName]["CHARACTERSECTION"])
			StdUi:GlueAbove(AutoTarget.FontStringTitle, AutoTarget)
			
			local Potion = StdUi:Checkbox(anchor, L["TAB"][tabName]["POTION"])		
			Potion:SetChecked(specDB.Potion)
			Potion:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Potion:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					specDB.Potion = not specDB.Potion
					self:SetChecked(specDB.Potion)	
					Action.Print(L["TAB"][tabName]["POTION"] .. ": ", specDB.Potion)	
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["POTION"], [[/run Action.SetToggle({]] .. tabName .. [[, "Potion", "]] .. L["TAB"][tabName]["POTION"] .. [[: "})]])	
				end 
			end)
			Potion.Identify = { Type = "Checkbox", Toggle = "Potion" }	
			Potion:SetScript("OnShow", function()
				if Action.IsBasicProfile then 
					if not Potion.isDisabled then 
						Potion:Disable()
						Potion:SetChecked(false)
					end 
				elseif Potion.isDisabled then  					
					Potion:SetChecked(specDB.Potion)
					Potion:Enable()
				end 			
			end)
			Potion:GetScript("OnShow")()
			StdUi:FrameTooltip(Potion, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true) 
			
			local HeartOfAzeroth, Covenant
			if Action.BuildToC < 90001 then 
				HeartOfAzeroth = StdUi:Checkbox(anchor, L["TAB"][tabName]["HEARTOFAZEROTH"])		
				HeartOfAzeroth:SetChecked(specDB.HeartOfAzeroth)
				HeartOfAzeroth:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				HeartOfAzeroth:SetScript("OnClick", function(self, button, down)	
					if not self.isDisabled then 	
						if button == "LeftButton" then 
							specDB.HeartOfAzeroth = not specDB.HeartOfAzeroth
							self:SetChecked(specDB.HeartOfAzeroth)	
							Action.Print(L["TAB"][tabName]["HEARTOFAZEROTH"] .. ": ", specDB.HeartOfAzeroth)	
						elseif button == "RightButton" then 
							Action.CraftMacro(L["TAB"][tabName]["HEARTOFAZEROTH"], [[/run Action.SetToggle({]] .. tabName .. [[, "HeartOfAzeroth", "]] .. L["TAB"][tabName]["HEARTOFAZEROTH"] .. [[: "})]])	
						end 
					end
				end)
				HeartOfAzeroth.Identify = { Type = "Checkbox", Toggle = "HeartOfAzeroth" }		
				StdUi:FrameTooltip(HeartOfAzeroth, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)
				if Action.BuildToC < 80200 then 
					HeartOfAzeroth:Disable()
				end 
			elseif Action.BuildToC < 100000 then 
				Covenant = StdUi:Checkbox(anchor, L["TAB"][tabName]["COVENANT"])		
				Covenant:SetChecked(specDB.Covenant)
				Covenant:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				Covenant:SetScript("OnClick", function(self, button, down)	
					if not self.isDisabled then 	
						if button == "LeftButton" then 
							specDB.Covenant = not specDB.Covenant
							self:SetChecked(specDB.Covenant)	
							Action.Print(L["TAB"][tabName]["COVENANT"] .. ": ", specDB.Covenant)	
						elseif button == "RightButton" then 
							Action.CraftMacro(L["TAB"][tabName]["COVENANT"], [[/run Action.SetToggle({]] .. tabName .. [[, "Covenant", "]] .. L["TAB"][tabName]["COVENANT"] .. [[: "})]])	
						end 
					end
				end)
				Covenant.Identify = { Type = "Checkbox", Toggle = "Covenant" }		
				StdUi:FrameTooltip(Covenant, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)
			end 

			local Racial = StdUi:Checkbox(anchor, L["TAB"][tabName]["RACIAL"])			
			Racial:SetChecked(specDB.Racial)
			Racial:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Racial:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					specDB.Racial = not specDB.Racial
					self:SetChecked(specDB.Racial)	
					Action.Print(L["TAB"][tabName]["RACIAL"] .. ": ", specDB.Racial)	
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["RACIAL"], [[/run Action.SetToggle({]] .. tabName .. [[, "Racial", "]] .. L["TAB"][tabName]["RACIAL"] .. [[: "})]])	
				end 
			end)
			Racial.Identify = { Type = "Checkbox", Toggle = "Racial" }
			StdUi:FrameTooltip(Racial, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	

			local StopCast = StdUi:Checkbox(anchor, L["TAB"][tabName]["STOPCAST"])			
			StopCast:SetChecked(specDB.StopCast)
			StopCast:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			StopCast:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					specDB.StopCast = not specDB.StopCast
					self:SetChecked(specDB.StopCast)	
					Action.Print(L["TAB"][tabName]["STOPCAST"] .. ": ", specDB.StopCast)	
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["STOPCAST"], [[/run Action.SetToggle({]] .. tabName .. [[, "StopCast", "]] .. L["TAB"][tabName]["STOPCAST"] .. [[: "})]])	
				end 
			end)
			StopCast.Identify = { Type = "Checkbox", Toggle = "StopCast" }
			StdUi:FrameTooltip(StopCast, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	
			
			local ReTarget = StdUi:Checkbox(anchor, "ReTarget")			
			ReTarget:SetChecked(specDB.ReTarget)
			ReTarget:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			ReTarget:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					specDB.ReTarget = not specDB.ReTarget
					self:SetChecked(specDB.ReTarget)	
					Action.Print("ReTarget" .. ": ", specDB.ReTarget)	
					Re:Initialize()
				elseif button == "RightButton" then 
					Action.CraftMacro("ReTarget", [[/run Action.SetToggle({]] .. tabName .. [[, "ReTarget", "]] .. "ReTarget" .. [[: "})]])	
				end 
			end)
			ReTarget.Identify = { Type = "Checkbox", Toggle = "ReTarget" }
			StdUi:FrameTooltip(ReTarget, L["TAB"][tabName]["RETARGET"], nil, "TOPRIGHT", true)
			ReTarget.FontStringTitle = StdUi:Subtitle(ReTarget, L["TAB"][tabName]["PVPSECTION"])
			StdUi:GlueAbove(ReTarget.FontStringTitle, ReTarget)			

			local ReFocus = StdUi:Checkbox(anchor, "ReFocus")
			ReFocus:SetChecked(specDB.ReFocus)
			ReFocus:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			ReFocus:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					specDB.ReFocus = not specDB.ReFocus
					self:SetChecked(specDB.ReFocus)	
					Action.Print("ReFocus" .. ": ", specDB.ReFocus)
					Re:Initialize()					
				elseif button == "RightButton" then 
					Action.CraftMacro("ReFocus", [[/run Action.SetToggle({]] .. tabName .. [[, "ReFocus", "]] .. "ReFocus" .. [[: "})]])	
				end 
			end)
			ReFocus.Identify = { Type = "Checkbox", Toggle = "ReFocus" }
			StdUi:FrameTooltip(ReFocus, L["TAB"][tabName]["REFOCUS"], nil, "TOPRIGHT", true)
			
			local LosSystem = StdUi:Checkbox(anchor, L["TAB"][tabName]["LOSSYSTEM"])
			LosSystem:SetChecked(specDB.LOSCheck)
			LosSystem:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			LosSystem:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					specDB.LOSCheck = not specDB.LOSCheck
					self:SetChecked(specDB.LOSCheck)	
					Action.Print(L["TAB"][tabName]["LOSSYSTEM"] .. ": ", specDB.LOSCheck)
					LineOfSight:Initialize()	
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["LOSSYSTEM"], [[/run Action.SetToggle({]] .. tabName .. [[, "LOSCheck", "]] .. L["TAB"][tabName]["LOSSYSTEM"] .. [[: "})]])	
				end 
			end)
			LosSystem.Identify = { Type = "Checkbox", Toggle = "LOSCheck" }				
			StdUi:FrameTooltip(LosSystem, L["TAB"][tabName]["LOSSYSTEMTOOLTIP"], nil, "TOPLEFT", true)
			LosSystem.FontStringTitle = StdUi:Subtitle(LosSystem, L["TAB"][tabName]["SYSTEMSECTION"])
			StdUi:GlueAbove(LosSystem.FontStringTitle, LosSystem)								
			
			local BossMods = StdUi:Checkbox(anchor, L["TAB"][tabName]["BOSSTIMERS"])
			BossMods:SetChecked(specDB.BossMods)
			BossMods:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			BossMods:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then 	
					if button == "LeftButton" then 
						specDB.BossMods = not specDB.BossMods
						self:SetChecked(specDB.BossMods)					
						Action.Print(L["TAB"][tabName]["BOSSTIMERS"] .. ": ", specDB.BossMods)	
					elseif button == "RightButton" then 
						Action.CraftMacro(L["TAB"][tabName]["BOSSTIMERS"], [[/run Action.SetToggle({]] .. tabName .. [[, "BossMods", "]] .. L["TAB"][tabName]["BOSSTIMERS"] .. [[: "})]])	
					end 
				end
			end)
			BossMods.Identify = { Type = "Checkbox", Toggle = "BossMods" }
			BossMods:SetScript("OnShow", function()
				if not Action.BossMods:HasAnyAddon() then 
					BossMods:Disable()
					-- Just for visual update what it's complete turned off
					BossMods:SetChecked(false)
				else 
					BossMods:Enable()
					BossMods:SetChecked(specDB.BossMods)
				end 
			end)
			BossMods:GetScript("OnShow")()
			StdUi:FrameTooltip(BossMods, L["TAB"][tabName]["BOSSTIMERSTOOLTIP"], nil, "TOPLEFT", true)

			local StopAtBreakAble = StdUi:Checkbox(anchor, L["TAB"][tabName]["STOPATBREAKABLE"], 50)			
			StopAtBreakAble:SetChecked(specDB.StopAtBreakAble)
			StopAtBreakAble:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			StopAtBreakAble:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then 
					if button == "LeftButton" then 
						specDB.StopAtBreakAble = not specDB.StopAtBreakAble
						self:SetChecked(specDB.StopAtBreakAble)	
						Action.Print(L["TAB"][tabName]["STOPATBREAKABLE"] .. ": ", specDB.StopAtBreakAble)	
					elseif button == "RightButton" then 
						Action.CraftMacro(L["TAB"][tabName]["STOPATBREAKABLE"], [[/run Action.SetToggle({]] .. tabName .. [[, "StopAtBreakAble", "]] .. L["TAB"][tabName]["STOPATBREAKABLE"] .. [[: "})]])	
					end 
				end 
			end)
			StopAtBreakAble.Identify = { Type = "Checkbox", Toggle = "StopAtBreakAble" }
			StdUi:FrameTooltip(StopAtBreakAble, L["TAB"][tabName]["STOPATBREAKABLETOOLTIP"], nil, "TOPLEFT", true)	
			
			local FPS = StdUi:Slider(anchor, StdUi:GetWidthByColumn(anchor, 5.8), themeHeight, specDB.FPS, false, -0.01, 1.5)
			FPS:SetPrecision(2)
			FPS:SetScript("OnMouseUp", function(self, button, down)
				if button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["FPS"], [[/run Action.SetToggle({]] .. tabName .. [[, "FPS", "]] .. L["TAB"][tabName]["FPS"] .. [[: "}, ]] .. specDB.FPS .. [[)]])	
				end					
			end)		
			FPS.Identify = { Type = "Slider", Toggle = "FPS" }		
			FPS.OnValueChanged = function(self, value)
				if value < 0 then 
					value = -0.01
				end 
				specDB.FPS = value
				FPS.FontStringTitle:SetText(L["TAB"][tabName]["FPS"] .. ": |cff00ff00" .. (value < 0 and "AUTO" or (value .. L["TAB"][tabName]["FPSSEC"])))
			end
			StdUi:FrameTooltip(FPS, L["TAB"][tabName]["FPSTOOLTIP"], nil, "TOPRIGHT", true)	
			FPS.FontStringTitle = StdUi:Subtitle(anchor, L["TAB"][tabName]["FPS"] .. ": |cff00ff00" .. (specDB.FPS < 0 and "AUTO" or (specDB.FPS .. L["TAB"][tabName]["FPSSEC"])))
			StdUi:GlueAbove(FPS.FontStringTitle, FPS)					
			
			local Trinkets = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, {
				{ text = L["TAB"][tabName]["TRINKET"] .. " 1", value = 1 },
				{ text = L["TAB"][tabName]["TRINKET"] .. " 2", value = 2 },
			}, nil, true, true)
			Trinkets:SetPlaceholder(" -- " .. L["TAB"][tabName]["TRINKETS"] .. " -- ") 	
			for i, v in ipairs(Trinkets.optsFrame.scrollChild.items) do 
				v:SetChecked(specDB.Trinkets[i])
			end			
			Trinkets.OnValueChanged = function(self, value)			
				for i, v in ipairs(self.optsFrame.scrollChild.items) do 					
					if specDB.Trinkets[i] ~= v:GetChecked() then
						specDB.Trinkets[i] = v:GetChecked()
						Action.Print(L["TAB"][tabName]["TRINKET"] .. " " .. i .. ": ", specDB.Trinkets[i])
					end 				
				end 				
			end				
			Trinkets:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Trinkets:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["TRINKETS"], [[/run Action.SetToggle({]] .. tabName .. [[, "Trinkets", "]] .. L["TAB"][tabName]["TRINKET"] .. [[:"})]])	
				end
			end)		
			Trinkets.Identify = { Type = "Dropdown", Toggle = "Trinkets" }			
			Trinkets.FontStringTitle = StdUi:Subtitle(Trinkets, L["TAB"][tabName]["TRINKETS"])
			StdUi:FrameTooltip(Trinkets, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)
			StdUi:GlueAbove(Trinkets.FontStringTitle, Trinkets)
			Trinkets.text:SetJustifyH("CENTER")			
						
			local Burst = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, {
				{ text = L["TAB"][tabName]["BURSTEVERYTHING"], 	value = "Everything" 	},
				{ text = L["TAB"]["AUTO"], 						value = "Auto" 			},				
				{ text = "Off", 								value = "Off" 			},
			})		          
			Burst:SetValue(specDB.Burst)
			Burst.OnValueChanged = function(self, val)                
				specDB.Burst = val 
				TMW:Fire("TMW_ACTION_BURST_CHANGED")
				TMW:Fire("TMW_ACTION_CD_MODE_CHANGED") -- Taste's callback 
				if val ~= "Off" then 
					ActionData.TG["Burst"] = val
				end 
				Action.Print(L["TAB"][tabName]["BURST"] .. ": ", specDB.Burst)
			end
			Burst:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Burst:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["BURST"], [[/run Action.ToggleBurst()]])	
				end
			end)		
			Burst.Identify = { Type = "Dropdown", Toggle = "Burst" }	
			StdUi:FrameTooltip(Burst, L["TAB"][tabName]["BURSTTOOLTIP"], nil, "TOPLEFT", true)
			Burst.FontStringTitle = StdUi:Subtitle(Burst, L["TAB"][tabName]["BURST"])
			StdUi:GlueAbove(Burst.FontStringTitle, Burst)	
			Burst.text:SetJustifyH("CENTER")				

			local HealthStone = StdUi:Slider(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, specDB.HealthStone, false, -1, 100)	
			HealthStone:SetScript("OnMouseUp", function(self, button, down)
				if button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["HEALTHSTONE"], [[/run Action.SetToggle({]] .. tabName .. [[, "HealthStone", "]] .. L["TAB"][tabName]["HEALTHSTONE"] .. [[: "}, ]] .. specDB.HealthStone .. [[)]])	
				end					
			end)		
			HealthStone.Identify = { Type = "Slider", Toggle = "HealthStone" }		
			HealthStone.OnValueChanged = function(self, value)
				local value = math_floor(value) 
				specDB.HealthStone = value
				self.FontStringTitle:SetText(L["TAB"][tabName]["HEALTHSTONE"] .. ": |cff00ff00" .. (value < 0 and "|cffff0000OFF|r" or value >= 100 and "|cff00ff00AUTO|r" or value))
			end
			StdUi:FrameTooltip(HealthStone, L["TAB"][tabName]["HEALTHSTONETOOLTIP"], nil, "TOPLEFT", true)	
			HealthStone.FontStringTitle = StdUi:Subtitle(anchor, L["TAB"][tabName]["HEALTHSTONE"] .. ": |cff00ff00" .. (specDB.HealthStone < 0 and "|cffff0000OFF|r" or specDB.HealthStone >= 100 and "|cff00ff00AUTO|r" or specDB.HealthStone))
			StdUi:GlueAbove(HealthStone.FontStringTitle, HealthStone)
			
			local AutoAttack = StdUi:Checkbox(anchor, L["TAB"][tabName]["AUTOATTACK"])			
			AutoAttack:SetChecked(specDB.AutoAttack)
			AutoAttack:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			AutoAttack:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					specDB.AutoAttack = not specDB.AutoAttack
					self:SetChecked(specDB.AutoAttack)	
					Action.Print(L["TAB"][tabName]["AUTOATTACK"] .. ": ", specDB.AutoAttack)	
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["AUTOATTACK"], [[/run Action.SetToggle({]] .. tabName .. [[, "AutoAttack", "]] .. L["TAB"][tabName]["AUTOATTACK"] .. [[: "})]])	
				end 
			end)
			AutoAttack.Identify = { Type = "Checkbox", Toggle = "AutoAttack" }
			StdUi:FrameTooltip(AutoAttack, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	
			
			local AutoShoot = StdUi:Checkbox(anchor, L["TAB"][tabName]["AUTOSHOOT"])			
			AutoShoot:SetChecked(specDB.AutoShoot)
			AutoShoot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			AutoShoot:SetScript("OnClick", function(self, button, down)	
				if not self.isDisabled then 
					if button == "LeftButton" then 
						specDB.AutoShoot = not specDB.AutoShoot
						self:SetChecked(specDB.AutoShoot)	
						Action.Print(L["TAB"][tabName]["AUTOSHOOT"] .. ": ", specDB.AutoShoot)	
					elseif button == "RightButton" then 
						Action.CraftMacro(L["TAB"][tabName]["AUTOSHOOT"], [[/run Action.SetToggle({]] .. tabName .. [[, "AutoShoot", "]] .. L["TAB"][tabName]["AUTOSHOOT"] .. [[: "})]])	
					end 
				end
			end)
			AutoShoot.Identify = { Type = "Checkbox", Toggle = "AutoShoot" }
			AutoShoot.MakeUpdate = function()
				if Action.PlayerClass ~= "WARRIOR" and Action.PlayerClass ~= "ROGUE" and Action.PlayerClass ~= "HUNTER" and not HasWandEquipped() then 
					if not AutoShoot.isDisabled then 
						AutoShoot:Disable()
					end 
				elseif AutoShoot.isDisabled then  
					AutoShoot:Enable()
				end 				
			end 
			AutoShoot:SetScript("OnShow", AutoShoot.MakeUpdate) 
			AutoShoot:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
			AutoShoot:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_EQUIPMENT_CHANGED" then 
					AutoShoot.MakeUpdate()
				end 
			end)
			AutoShoot:GetScript("OnShow")()
			StdUi:FrameTooltip(AutoShoot, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)
			
			local ColorPicker	= Action.ColorPicker
			local Color 		= { 
				Title 			= StdUi:Subtitle(anchor, L["TAB"][tabName]["COLORTITLE"]),
				Elements 		= {}, 	-- Stores static array like table for 'Element' dropdown 
				Options 		= {},	-- Stores dynamic array like table for 'Option' dropdown depends on 'Element' choice
				Themes			= {},	-- Stores static array like table for 'Theme' dropdown
				SetupStates 	= function(self)
					-- Switches between enabled and disabled 
					if not tabDB.ColorPickerUse then -- don't touch
						self.Picker:Disable()
						self.Element:Disable()
						self.Option:Disable()
						self.Theme:Disable()	
						self.ThemeApplyButton:Disable()
						-- Set back manual custom backdrop color 
						MainUI.ResetQuestion:SetBackdropColor(0, 0, 0, 1)
					else
						self.Picker:Enable()
						self.Element:Enable()
						self.Option:Enable()
						self.Theme:Enable()
						self.Theme:OnValueChanged(self.Theme:GetValue()) -- to enable 'ThemeApplyButton' if necessary
						self:SetupPicker()
					end 					
				end,	
				SetupPicker		= function(self)
					local e, o	= self.Element:GetValue(), self.Option:GetValue()
					local c 	= ColorPicker:tFindByOption(StdUi.config[e], o)		
					
					-- Switches color of checkbox 
					self.Picker:SetColor(c)
					-- Switches color of Color Frame 
					if StdUi.colorPickerFrame and StdUi.colorPickerFrame:IsVisible() then 
						StdUi.colorPickerFrame:SetColorRGBA(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
						StdUi.colorPickerFrame.oldTexture:SetVertexColor(c.r or 1, c.g or 1, c.b or 1, c.a or 1)
					end 					
				end,					
			}				
			
			Color.Title:SetAllPoints()			
			Color.Title:SetJustifyH("CENTER")
			Color.Title:SetFontSize(14)

			Color.UseColor = StdUi:Checkbox(anchor, L["TAB"][tabName]["COLORUSE"], 250)
			Color.UseColor:SetChecked(tabDB.ColorPickerUse)
			Color.UseColor.OnValueChanged = function(self, state, value)
				tabDB.ColorPickerUse = state		
				Action.Print(L["TAB"][tabName]["COLORTITLE"] .. " - " .. L["TAB"][tabName]["COLORUSE"] .. ": ", state)
				ColorPicker:Initialize()
				Color:SetupStates()

				-- Hide color frame 
				if self.stdUi.colorPickerFrame and self.stdUi.colorPickerFrame:IsVisible() then 
					self.stdUi.colorPickerFrame:Hide()
				end 
			end	
			Color.UseColor.Identify = { Type = "Checkbox", Toggle = "ColorPickerUse" }
			StdUi:FrameTooltip(Color.UseColor, L["TAB"][tabName]["COLORUSETOOLTIP"], nil, "TOPRIGHT", true)
			
			Color.Picker = StdUi:ColorInput(anchor, L["TAB"][tabName]["COLORPICKER"])
			Color.Picker.prevRGBA = {} -- Stores previous state of color with alpha (associative table)
			Color.Picker.okCallback = function(cpf)
				wipe(Color.Picker.prevRGBA)
				Color.Picker:SetColor(cpf:GetColor())
				
				Color.currentTheme = nil 
				if Color.ThemeApplyButton.isDisabled then 
					local currentTheme = Color.Theme:GetValue()
					if ColorPicker.Themes[currentTheme] then 
						Color.ThemeApplyButton:Enable()
					end
				end
			end 
			Color.Picker.cancelCallback	= function()
				if next(Color.Picker.prevRGBA) then 
					Color.Picker:SetColor(Color.Picker.prevRGBA)
					wipe(Color.Picker.prevRGBA)
				end 
			end
			Color.Picker:HookScript("OnClick", function(self)
				if self.isDisabled then 
					return 
				end 
				
				local colorPickerFrame = self.stdUi.colorPickerFrame
				if not colorPickerFrame.isModified then 
					-- Make move able  
					colorPickerFrame:SetMovable(true)
					colorPickerFrame:EnableMouse(true)
					colorPickerFrame:RegisterForDrag("RightButton")
					colorPickerFrame:SetScript("OnDragStart", colorPickerFrame.StartMoving)
					colorPickerFrame:SetScript("OnDragStop", function(this)
						this:StopMovingOrSizing()
						this.xOfs, this.yOfs = select(4, this:GetPoint())
					end)
					colorPickerFrame:SetClampedToScreen(true)
					
					-- Create reset button 
					colorPickerFrame.resetButton = StdUi:Button(colorPickerFrame, colorPickerFrame.cancelButton:GetWidth(), colorPickerFrame.cancelButton:GetHeight(), L["RESET"])
					colorPickerFrame.resetButton:RegisterForClicks("LeftButtonUp")
					colorPickerFrame.resetButton:SetScript("OnClick", function(this, button, down)
						if not this.isDisabled then
							local e, o = tabDB.ColorPickerElement, tabDB.ColorPickerOption -- don't touch 
							ColorPicker:ResetOn(e, o)	
							colorPickerFrame:SetColor(ColorPicker:tFindByOption(ColorPicker.Cache[e], o))							
						end 
					end)
					StdUi:GlueAbove(colorPickerFrame.resetButton, colorPickerFrame.cancelButton, 0, 5)					
			
					-- Since StdUi used as new instance hooksecurefunc doesn't work on thigs used directly inside lib
					-- Add to StdUiObjects OK / Cancel buttons   
					self.stdUi:ApplyBackdrop(colorPickerFrame.okButton)					
					self.stdUi:SetTextColor(colorPickerFrame.okButton.text, "normal")
					colorPickerFrame.okButton.text:SetText(L["APPLY"])
					self.stdUi:ApplyBackdrop(colorPickerFrame.cancelButton)					
					self.stdUi:SetTextColor(colorPickerFrame.cancelButton.text, "normal")
					colorPickerFrame.cancelButton.text:SetText(L["CLOSE"])									
					
					-- Create hook to hide with main UI
					MainUI:HookScript("OnHide", function(this)
						if colorPickerFrame:IsVisible() then 
							colorPickerFrame:Hide()
						end 
					end)
					
					colorPickerFrame.isModified = true
				end 								
				
				if not self.isLocalHooked then 
					-- Just part of code to make in real time view changes 
					self.temp = {} -- Temporary table for r,g,b,a since StdUi has recreate table return for :GetColor			
					
					colorPickerFrame:HookScript("OnColorSelect", function(this)
						if this:IsVisible() then 
							self.temp.r, self.temp.g, self.temp.b, self.temp.a = this:GetColorRGBA()
							self:OnValueChanged(self.temp)					
						end 
					end)
					
					self.isLocalHooked 	= true 
				end 
				
				colorPickerFrame.okCallback = self.okCallback
				colorPickerFrame.cancelCallback = self.cancelCallback
				-- Remember previous color + alpha states 
				if not next(self.prevRGBA) then  
					self.prevRGBA.r, self.prevRGBA.g, self.prevRGBA.b, self.prevRGBA.a = self.color.r or 1, self.color.g or 1, self.color.b or 1, self.color.a or 1
				end 
				
				-- Move to saved last position 
				if colorPickerFrame.xOfs and colorPickerFrame.yOfs then 
					colorPickerFrame:SetPoint("CENTER", colorPickerFrame.xOfs, colorPickerFrame.yOfs)
				end 
			end)
			Color.Picker.OnValueChanged = function(self, v)  
				if not self.isDisabled then 
					local e, o 			= Color.Element:GetValue(), Color.Option:GetValue()
					local t 			= ColorPicker:tFindByOption(tabDB.ColorPickerConfig[e], o)
					t.r, t.g, t.b, t.a 	= v.r, v.g, v.b, v.a
					ColorPicker:MakeOn(e, o, v)										
				end 
			end
			-- We don't use Identify here since pointless with dropdowns 
			StdUi:FrameTooltip(Color.Picker, L["TAB"][tabName]["COLORPICKERTOOLTIP"], nil, "TOPLEFT", true)			
			
			Color.Element = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, ColorPicker:SetElementsIn(Color.Elements))		
			Color.Element:SetValue(tabDB.ColorPickerElement)
			Color.Element.OnValueChanged = function(self, val)      
				tabDB.ColorPickerElement = val 
				Action.Print(L["TAB"][tabName]["COLORTITLE"] .. " - " .. L["TAB"][tabName]["COLORELEMENT"] .. ": ", val)				
				
				-- Change table structure for 'Option' dropdown and resize height
				Color.Option:SetOptions(ColorPicker:SetOptionsIn(Color.Options, val))				
				
				-- Refresh current selection if it's not equal 
				-- Note: We must do this instead of fixed set because :SetValue will always fire print 
				local current_value = Color.Option:GetValue()
				local equal_value 
				for _, v in ipairs(Color.Options) do 
					if current_value == v.value then 
						equal_value = true 
						break 
					end 
				end 
				if not equal_value then 
					Color.Option:SetValue(Color.Options[1].value)
					--Color:SetupPicker() -- will be fired through OnValueChanged of 'Option' dropdown 
				else 
					Color:SetupPicker()
				end 								
			end
			Color.Element:RegisterForClicks("LeftButtonUp")
			Color.Element:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					self:ToggleOptions()
				end 
			end)		
			Color.Element.Identify = { Type = "Dropdown", Toggle = "ColorPickerElement" }	
			Color.Element.FontStringTitle = StdUi:Subtitle(Color.Element, L["TAB"][tabName]["COLORELEMENT"])
			StdUi:GlueAbove(Color.Element.FontStringTitle, Color.Element)	
			Color.Element.text:SetJustifyH("CENTER")	
			
			Color.Option = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, ColorPicker:SetOptionsIn(Color.Options, Color.Element:GetValue()))		
			Color.Option:SetValue(tabDB.ColorPickerOption)
			Color.Option.OnValueChanged = function(self, val)                
				tabDB.ColorPickerOption = val 				
				Action.Print(L["TAB"][tabName]["COLORTITLE"] .. " - " .. L["TAB"][tabName]["COLOROPTION"] .. ": ", tabDB.ColorPickerOption)
				
				-- Refresh RGBA of checkbox and color frame
				Color:SetupPicker()
			end
			Color.Option:RegisterForClicks("LeftButtonUp")
			Color.Option:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					self:ToggleOptions()
				end 
			end)		
			Color.Option.Identify = { Type = "Dropdown", Toggle = "ColorPickerOption" }	
			Color.Option.FontStringTitle = StdUi:Subtitle(Color.Option, L["TAB"][tabName]["COLOROPTION"])
			StdUi:GlueAbove(Color.Option.FontStringTitle, Color.Option)	
			Color.Option.text:SetJustifyH("CENTER")
			
			Color.Theme = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 9), themeHeight, ColorPicker:SetThemesIn(Color.Themes))	
			Color.Theme:SetPlaceholder(L["TAB"][tabName]["THEMEHOLDER"])
			Color.Theme.OnValueChanged = function(self, val) 
				if not self.isDisabled then 
					if Color.currentTheme == val then 
						if not Color.ThemeApplyButton.isDisabled then 
							Color.ThemeApplyButton:Disable()
						end 
					else
						if Color.ThemeApplyButton.isDisabled then 
							Color.ThemeApplyButton:Enable()
						end 
					end 
				end 
			end
			Color.Theme:RegisterForClicks("LeftButtonUp")
			Color.Theme:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					self:ToggleOptions()
				end 
			end)		
			Color.Theme.FontStringTitle = StdUi:Subtitle(Color.Theme, L["TAB"][tabName]["SELECTTHEME"])
			StdUi:GlueAbove(Color.Theme.FontStringTitle, Color.Theme)	
			Color.Theme.text:SetJustifyH("CENTER")
			
			Color.ThemeApplyButton = StdUi:Button(anchor, StdUi:GetWidthByColumn(anchor, 2), themeHeight, L["APPLY"])
			Color.ThemeApplyButton:RegisterForClicks("LeftButtonUp")
			Color.ThemeApplyButton:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 		
					local currentTheme = Color.Theme:GetValue()
					if ColorPicker.Themes[currentTheme] then 						
						-- Apply selected theme 
						ColorPicker:MakeColors(ColorPicker.Themes[currentTheme])

						-- Save selected theme to db 
						tabDB.ColorPickerConfig = tMerge(tabDB.ColorPickerConfig, ColorPicker.Themes[currentTheme])
						
						-- Refresh rest  
						Color:SetupPicker()
						wipe(Color.Picker.prevRGBA)
						Color.currentTheme = currentTheme
						self:Disable()						
					end 
				end 
			end)
			Color.ThemeApplyButton:Disable()
			
			Color:SetupStates()
			Color:SetupPicker()						

			local PauseChecksPanel = StdUi:PanelWithTitle(anchor, tab.frame:GetWidth() - 30, 390, L["TAB"][tabName]["PAUSECHECKS"])
			PauseChecksPanel.titlePanel.label:SetFontSize(14)
			StdUi:EasyLayout(PauseChecksPanel, { padding = { top = 10 } })	
			
			local AntiFakeItems = {
				{ text = "START AntiFake CC", value = 1 },
				{ text = "START AntiFake Interrupt", value = 2 },
			}
			if Action.BuildToC >= 20000 then 
				AntiFakeItems[#AntiFakeItems + 1] = { text = "START AntiFake CC Focus", value = 3 }
				AntiFakeItems[#AntiFakeItems + 1] = { text = "START AntiFake Interrupt Focus", value = 4 }
				AntiFakeItems[#AntiFakeItems + 1] = { text = "START AntiFake CC2", value = 5 }
				AntiFakeItems[#AntiFakeItems + 1] = { text = "START AntiFake CC2 Focus", value = 6 }									
			end 
			local AntiFakePauses = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, AntiFakeItems, nil, true, true)
			AntiFakePauses:SetPlaceholder(" -- " .. L["TAB"][tabName]["ANTIFAKEPAUSES"] .. " -- ") 	
			for i, v in ipairs(AntiFakePauses.optsFrame.scrollChild.items) do 
				v:SetChecked(tabDB.AntiFakePauses[i])
			end			
			AntiFakePauses.OnValueChanged = function(self, value)			
				for i, v in ipairs(self.optsFrame.scrollChild.items) do 					
					if tabDB.AntiFakePauses[i] ~= v:GetChecked() then
						tabDB.AntiFakePauses[i] = v:GetChecked()
						Action.Print(L["TAB"][tabName]["ANTIFAKEPAUSES"] .. " - " .. AntiFakeItems[i].text .. ": ", tabDB.AntiFakePauses[i])
					end 				
				end 				
			end				
			AntiFakePauses:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			AntiFakePauses:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["ANTIFAKEPAUSES"], [[/run Action.SetToggle({]] .. tabName .. [[, "AntiFakePauses", "]] .. L["TAB"][tabName]["ANTIFAKEPAUSES"] .. [[:"})]])	
				end
			end)	
			AntiFakePauses.Identify = { Type = "Dropdown", Toggle = "AntiFakePauses" }			
			AntiFakePauses.FontStringTitle = StdUi:Subtitle(AntiFakePauses, L["TAB"][tabName]["ANTIFAKEPAUSESSUBTITLE"])
			StdUi:FrameTooltip(AntiFakePauses, strjoin("\n\n", L["TAB"][tabName]["ANTIFAKEPAUSESTT"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "TOP", true)
			StdUi:GlueAbove(AntiFakePauses.FontStringTitle, AntiFakePauses)
			AntiFakePauses.text:SetJustifyH("CENTER")			

			local CheckSpellIsTargeting = StdUi:Checkbox(anchor, L["TAB"][tabName]["SPELLISTARGETING"])		
			CheckSpellIsTargeting:SetChecked(tabDB.CheckSpellIsTargeting)
			CheckSpellIsTargeting:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			CheckSpellIsTargeting:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.CheckSpellIsTargeting = not tabDB.CheckSpellIsTargeting
					self:SetChecked(tabDB.CheckSpellIsTargeting)	
					Action.Print(L["TAB"][tabName]["SPELLISTARGETING"] .. ": ", tabDB.CheckSpellIsTargeting)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["SPELLISTARGETING"], [[/run Action.SetToggle({]] .. tabName .. [[, "CheckSpellIsTargeting", "]] .. L["TAB"][tabName]["SPELLISTARGETING"] .. [[: "})]])	
				end 
			end)
			CheckSpellIsTargeting.Identify = { Type = "Checkbox", Toggle = "CheckSpellIsTargeting" }
			StdUi:FrameTooltip(CheckSpellIsTargeting, strjoin("\n\n", L["TAB"][tabName]["SPELLISTARGETINGTOOLTIP"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "BOTTOMRIGHT", true)
			
			local CheckLootFrame = StdUi:Checkbox(anchor, L["TAB"][tabName]["LOOTFRAME"])
			CheckLootFrame:SetChecked(tabDB.CheckLootFrame)
			CheckLootFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			CheckLootFrame:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.CheckLootFrame = not tabDB.CheckLootFrame
					self:SetChecked(tabDB.CheckLootFrame)	
					Action.Print(L["TAB"][tabName]["LOOTFRAME"] .. ": ", tabDB.CheckLootFrame)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["LOOTFRAME"], [[/run Action.SetToggle({]] .. tabName .. [[, "CheckLootFrame", "]] .. L["TAB"][tabName]["LOOTFRAME"] .. [[: "})]])	
				end 
			end)
			CheckLootFrame.Identify = { Type = "Checkbox", Toggle = "CheckLootFrame" }	
			StdUi:FrameTooltip(CheckLootFrame, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOMLEFT", true)			

			local CheckVehicle = StdUi:Checkbox(anchor, L["TAB"][tabName]["VEHICLE"])			
			CheckVehicle:SetChecked(tabDB.CheckVehicle)
			CheckVehicle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			CheckVehicle:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.CheckVehicle = not tabDB.CheckVehicle
					self:SetChecked(tabDB.CheckVehicle)	
					Action.Print(L["TAB"][tabName]["VEHICLE"] .. ": ", tabDB.CheckVehicle)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["VEHICLE"], [[/run Action.SetToggle({]] .. tabName .. [[, "CheckVehicle", "]] .. L["TAB"][tabName]["VEHICLE"] .. [[: "})]])	
				end 
			end)
			CheckVehicle.Identify = { Type = "Checkbox", Toggle = "CheckVehicle" }
			StdUi:FrameTooltip(CheckVehicle, strjoin("\n\n", L["TAB"][tabName]["VEHICLETOOLTIP"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "BOTTOMRIGHT", true)				
			
			local CheckDeadOrGhost = StdUi:Checkbox(anchor, L["TAB"][tabName]["DEADOFGHOSTPLAYER"])	
			CheckDeadOrGhost:SetChecked(tabDB.CheckDeadOrGhost)
			CheckDeadOrGhost:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			CheckDeadOrGhost:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.CheckDeadOrGhost = not tabDB.CheckDeadOrGhost
					self:SetChecked(tabDB.CheckDeadOrGhost)	
					Action.Print(L["TAB"][tabName]["DEADOFGHOSTPLAYER"] .. ": ", tabDB.CheckDeadOrGhost)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DEADOFGHOSTPLAYER"], [[/run Action.SetToggle({]] .. tabName .. [[, "CheckDeadOrGhost", "]] .. L["TAB"][tabName]["DEADOFGHOSTPLAYER"] .. [[: "})]])	
				end 
			end)
			CheckDeadOrGhost.Identify = { Type = "Checkbox", Toggle = "CheckDeadOrGhost" }
			StdUi:FrameTooltip(CheckDeadOrGhost, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOMLEFT", true)
			
			local CheckMount = StdUi:Checkbox(anchor, L["TAB"][tabName]["MOUNT"])
			CheckMount:SetChecked(tabDB.CheckMount)
			CheckMount:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			CheckMount:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.CheckMount = not tabDB.CheckMount
					self:SetChecked(tabDB.CheckMount)	
					Action.Print(L["TAB"][tabName]["MOUNT"] .. ": ", tabDB.CheckMount)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["MOUNT"], [[/run Action.SetToggle({]] .. tabName .. [[, "CheckMount", "]] .. L["TAB"][tabName]["MOUNT"] .. [[: "})]])	
				end 
			end)
			CheckMount.Identify = { Type = "Checkbox", Toggle = "CheckMount" }	
			StdUi:FrameTooltip(CheckMount, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOMRIGHT", true)					
			
			local CheckDeadOrGhostTarget = StdUi:Checkbox(anchor, L["TAB"][tabName]["DEADOFGHOSTTARGET"])
			CheckDeadOrGhostTarget:SetChecked(tabDB.CheckDeadOrGhostTarget)			
			CheckDeadOrGhostTarget:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			CheckDeadOrGhostTarget:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.CheckDeadOrGhostTarget = not tabDB.CheckDeadOrGhostTarget
					self:SetChecked(tabDB.CheckDeadOrGhostTarget)	
					Action.Print(L["TAB"][tabName]["DEADOFGHOSTTARGET"] .. ": ", tabDB.CheckDeadOrGhostTarget)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DEADOFGHOSTTARGET"], [[/run Action.SetToggle({]] .. tabName .. [[, "CheckDeadOrGhostTarget", "]] .. L["TAB"][tabName]["DEADOFGHOSTTARGET"] .. [[: "})]])	
				end 
			end)
			CheckDeadOrGhostTarget.Identify = { Type = "Checkbox", Toggle = "CheckDeadOrGhostTarget" }
			StdUi:FrameTooltip(CheckDeadOrGhostTarget, strjoin("\n\n", L["TAB"][tabName]["DEADOFGHOSTTARGETTOOLTIP"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "BOTTOMLEFT", true)						

			local CheckCombat = StdUi:Checkbox(anchor, L["TAB"][tabName]["COMBAT"])	
			CheckCombat:SetChecked(tabDB.CheckCombat)
			CheckCombat:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			CheckCombat:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.CheckCombat = not tabDB.CheckCombat
					self:SetChecked(tabDB.CheckCombat)	
					Action.Print(L["TAB"][tabName]["COMBAT"] .. ": ", tabDB.CheckCombat)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["COMBAT"], [[/run Action.SetToggle({]] .. tabName .. [[, "CheckCombat", "]] .. L["TAB"][tabName]["COMBAT"] .. [[: "})]])	
				end 
			end)
			CheckCombat.Identify = { Type = "Checkbox", Toggle = "CheckCombat" }
			StdUi:FrameTooltip(CheckCombat, strjoin("\n\n", L["TAB"][tabName]["COMBATTOOLTIP"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "BOTTOMRIGHT", true)			

			local CheckEatingOrDrinking = StdUi:Checkbox(anchor, L["TAB"][tabName]["EATORDRINK"])
			CheckEatingOrDrinking:SetChecked(tabDB.CheckEatingOrDrinking)
			CheckEatingOrDrinking:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			CheckEatingOrDrinking:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.CheckEatingOrDrinking = not tabDB.CheckEatingOrDrinking
					self:SetChecked(tabDB.CheckEatingOrDrinking)	
					Action.Print(L["TAB"][tabName]["EATORDRINK"] .. ": ", tabDB.CheckEatingOrDrinking)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["EATORDRINK"], [[/run Action.SetToggle({]] .. tabName .. [[, "CheckEatingOrDrinking", "]] .. L["TAB"][tabName]["EATORDRINK"] .. [[: "})]])	
				end 
			end)
			CheckEatingOrDrinking.Identify = { Type = "Checkbox", Toggle = "CheckEatingOrDrinking" }
			StdUi:FrameTooltip(CheckEatingOrDrinking, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOMLEFT", true)				
			
			local Misc = StdUi:Header(PauseChecksPanel, L["TAB"][tabName]["MISC"])
			Misc:SetAllPoints()			
			Misc:SetJustifyH("CENTER")
			Misc:SetFontSize(14)
			
			local DisableRotationDisplay = StdUi:Checkbox(anchor, L["TAB"][tabName]["DISABLEROTATIONDISPLAY"])
			DisableRotationDisplay:SetChecked(tabDB.DisableRotationDisplay)
			DisableRotationDisplay:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableRotationDisplay:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.DisableRotationDisplay = not tabDB.DisableRotationDisplay
					self:SetChecked(tabDB.DisableRotationDisplay)	
					Action.Print(L["TAB"][tabName]["DISABLEROTATIONDISPLAY"] .. ": ", tabDB.DisableRotationDisplay)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DISABLEROTATIONDISPLAY"], [[/run Action.SetToggle({]] .. tabName .. [[, "DisableRotationDisplay", "]] .. L["TAB"][tabName]["DISABLEROTATIONDISPLAY"] .. [[: "})]])	
				end 
			end)
			DisableRotationDisplay.Identify = { Type = "Checkbox", Toggle = "DisableRotationDisplay" }
			StdUi:FrameTooltip(DisableRotationDisplay, strjoin("\n\n", L["TAB"][tabName]["DISABLEROTATIONDISPLAYTOOLTIP"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "BOTTOMRIGHT", true)	
			
			local DisableBlackBackground = StdUi:Checkbox(anchor, L["TAB"][tabName]["DISABLEBLACKBACKGROUND"])
			DisableBlackBackground:SetChecked(tabDB.DisableBlackBackground)			
			DisableBlackBackground:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableBlackBackground:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.DisableBlackBackground = not tabDB.DisableBlackBackground
					self:SetChecked(tabDB.DisableBlackBackground)	
					Action.Print(L["TAB"][tabName]["DISABLEBLACKBACKGROUND"] .. ": ", tabDB.DisableBlackBackground)
					Action.BlackBackgroundSet(not tabDB.DisableBlackBackground)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DISABLEBLACKBACKGROUND"], [[/run Action.SetToggle({]] .. tabName .. [[, "DisableBlackBackground", "]] .. L["TAB"][tabName]["DISABLEBLACKBACKGROUND"] .. [[: "}); Action.BlackBackgroundSet(not Action.GetToggle(1, "DisableBlackBackground"))]])	
				end 
			end)
			DisableBlackBackground.Identify = { Type = "Checkbox", Toggle = "DisableBlackBackground" }
			StdUi:FrameTooltip(DisableBlackBackground, strjoin("\n\n", L["TAB"][tabName]["DISABLEBLACKBACKGROUNDTOOLTIP"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "BOTTOMLEFT", true)	

			local DisablePrint = StdUi:Checkbox(anchor, L["TAB"][tabName]["DISABLEPRINT"])
			DisablePrint:SetChecked(tabDB.DisablePrint)		
			DisablePrint:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisablePrint:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.DisablePrint = not tabDB.DisablePrint
					self:SetChecked(tabDB.DisablePrint)	
					Action.Print(L["TAB"][tabName]["DISABLEPRINT"] .. ": ", tabDB.DisablePrint)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DISABLEPRINT"], [[/run Action.SetToggle({]] .. tabName .. [[, "DisablePrint", "]] .. L["TAB"][tabName]["DISABLEPRINT"] .. [[: "})]])	
				end 
			end)
			DisablePrint.Identify = { Type = "Checkbox", Toggle = "DisablePrint" }
			StdUi:FrameTooltip(DisablePrint, strjoin("\n\n", L["TAB"][tabName]["DISABLEPRINTTOOLTIP"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "BOTTOMRIGHT", true)

			local DisableMinimap = StdUi:Checkbox(anchor, L["TAB"][tabName]["DISABLEMINIMAP"])
			DisableMinimap:SetChecked(tabDB.DisableMinimap)	
			DisableMinimap:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableMinimap:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 					
					Action.ToggleMinimap()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DISABLEMINIMAP"], [[/run Action.ToggleMinimap()]])	
				end 
			end)
			DisableMinimap.Identify = { Type = "Checkbox", Toggle = "DisableMinimap" }
			StdUi:FrameTooltip(DisableMinimap, strjoin("\n\n", L["TAB"][tabName]["DISABLEMINIMAPTOOLTIP"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "BOTTOMLEFT", true)	
						
			local DisableClassPortraits = StdUi:Checkbox(anchor, L["TAB"][tabName]["DISABLEPORTRAITS"])
			DisableClassPortraits:SetChecked(tabDB.DisableClassPortraits)		
			DisableClassPortraits:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableClassPortraits:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.DisableClassPortraits = not tabDB.DisableClassPortraits
					self:SetChecked(tabDB.DisableClassPortraits)	
					Action.Print(L["TAB"][tabName]["DISABLEPORTRAITS"] .. ": ", tabDB.DisableClassPortraits)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DISABLEPORTRAITS"], [[/run Action.SetToggle({]] .. tabName .. [[, "DisableClassPortraits", "]] .. L["TAB"][tabName]["DISABLEPORTRAITS"] .. [[: "})]])	
				end 
			end)
			DisableClassPortraits.Identify = { Type = "Checkbox", Toggle = "DisableClassPortraits" }	
			StdUi:FrameTooltip(DisableClassPortraits, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOMRIGHT", true)	

			local DisableRotationModes = StdUi:Checkbox(anchor, L["TAB"][tabName]["DISABLEROTATIONMODES"])
			DisableRotationModes:SetChecked(tabDB.DisableRotationModes)		
			DisableRotationModes:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableRotationModes:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.DisableRotationModes = not tabDB.DisableRotationModes
					self:SetChecked(tabDB.DisableRotationModes)	
					Action.Print(L["TAB"][tabName]["DISABLEROTATIONMODES"] .. ": ", tabDB.DisableRotationModes)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DISABLEROTATIONMODES"], [[/run Action.SetToggle({]] .. tabName .. [[, "DisableRotationModes", "]] .. L["TAB"][tabName]["DISABLEROTATIONMODES"] .. [[: "})]])	
				end 
			end)
			DisableRotationModes.Identify = { Type = "Checkbox", Toggle = "DisableRotationModes" }	
			StdUi:FrameTooltip(DisableRotationModes, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOMLEFT", true)	
			
			local DisableSounds = StdUi:Checkbox(anchor, L["TAB"][tabName]["DISABLESOUNDS"])
			DisableSounds:SetChecked(tabDB.DisableSounds)		
			DisableSounds:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableSounds:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.DisableSounds = not tabDB.DisableSounds
					self:SetChecked(tabDB.DisableSounds)	
					Action.Print(L["TAB"][tabName]["DISABLESOUNDS"] .. ": ", tabDB.DisableSounds)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DISABLESOUNDS"], [[/run Action.SetToggle({]] .. tabName .. [[, "DisableSounds", "]] .. L["TAB"][tabName]["DISABLESOUNDS"] .. [[: "})]])	
				end 
			end)
			DisableSounds.Identify = { Type = "Checkbox", Toggle = "DisableSounds" }
			StdUi:FrameTooltip(DisableSounds, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOMRIGHT", true)	

			local HideOnScreenshot = StdUi:Checkbox(anchor, L["TAB"][tabName]["HIDEONSCREENSHOT"])
			HideOnScreenshot:SetChecked(tabDB.HideOnScreenshot)	
			HideOnScreenshot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			HideOnScreenshot:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.HideOnScreenshot = not tabDB.HideOnScreenshot
					self:SetChecked(tabDB.HideOnScreenshot)	
					Action.Print(L["TAB"][tabName]["HIDEONSCREENSHOT"] .. ": ", tabDB.HideOnScreenshot)
					ScreenshotHider:Initialize()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["HIDEONSCREENSHOT"], [[/run Action.SetToggle({]] .. tabName .. [[, "HideOnScreenshot", "]] .. L["TAB"][tabName]["HIDEONSCREENSHOT"] .. [[: "}); Action.ScreenshotHider:Initialize()]])	
				end 
			end)
			HideOnScreenshot.Identify = { Type = "Checkbox", Toggle = "HideOnScreenshot" }
			StdUi:FrameTooltip(HideOnScreenshot, strjoin("\n\n", L["TAB"][tabName]["HIDEONSCREENSHOTTOOLTIP"], L["TAB"]["RIGHTCLICKCREATEMACRO"]), nil, "BOTTOMLEFT", true)	
			
			local DisableAddonsCheck = StdUi:Checkbox(anchor, L["TAB"][tabName]["DISABLEADDONSCHECK"])
			DisableAddonsCheck:SetChecked(tabDB.DisableAddonsCheck)	
			DisableAddonsCheck:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableAddonsCheck:SetScript("OnClick", function(self, button, down)	
				if button == "LeftButton" then 
					tabDB.DisableAddonsCheck = not tabDB.DisableAddonsCheck
					self:SetChecked(tabDB.DisableAddonsCheck)	
					Action.Print(L["TAB"][tabName]["DISABLEADDONSCHECK"] .. ": ", tabDB.DisableAddonsCheck)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["DISABLEADDONSCHECK"], [[/run Action.SetToggle({]] .. tabName .. [[, "DisableAddonsCheck", "]] .. L["TAB"][tabName]["DISABLEADDONSCHECK"] .. [[: "})]])	
				end 
			end)			
			DisableAddonsCheck.Identify = { Type = "Checkbox", Toggle = "DisableAddonsCheck" }		
			StdUi:FrameTooltip(DisableAddonsCheck, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOMRIGHT", true)		
			
			local CVarsItems = {
				{ text = "Contrast", 							value = 1 },
				{ text = "Brightness", 							value = 2 },
				{ text = "Gamma", 								value = 3 },
				{ text = "colorblindsimulator", 				value = 4 },
				{ text = "colorblindWeaknessFactor", 			value = 5 },
				{ text = "SpellQueueWindow", 					value = 6 },
				{ text = "doNotFlashLowHealthWarning", 			value = 7 },
				{ text = "nameplateMaxDistance", 				value = 8 },
				{ text = "nameplateNotSelectedAlpha", 			value = 9 },
				{ text = "nameplateOccludedAlphaMult", 			value = 10 },
				{ text = "breakUpLargeNumbers", 				value = 11 },
				{ text = "screenshotQuality", 					value = 12 },
				{ text = "nameplateShowEnemies", 				value = 13 },
				{ text = "autoSelfCast", 						value = 14 },
			}
			local CVars = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, CVarsItems, nil, true, true)
			CVars:SetPlaceholder(" -- CVars -- ") 	
			for i, v in ipairs(CVars.optsFrame.scrollChild.items) do 
				v:SetChecked(tabDB.CVars[i])
			end			
			CVars.OnValueChanged = function(self, value)			
				for i, v in ipairs(self.optsFrame.scrollChild.items) do 					
					if tabDB.CVars[i] ~= v:GetChecked() then
						tabDB.CVars[i] = v:GetChecked()
						Action.Print("CVar - " .. CVarsItems[i].text .. ": ", tabDB.CVars[i])
					end 				
				end 				
			end				
			CVars:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			CVars:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				elseif button == "RightButton" then 
					Action.CraftMacro("CVars", [[/run Action.SetToggle({]] .. tabName .. [[, "CVars", "CVars:"})]])	
				end
			end)	
			CVars.Identify = { Type = "Dropdown", Toggle = "CVars" }			
			CVars.FontStringTitle = StdUi:Subtitle(CVars, "CVars")
			StdUi:FrameTooltip(CVars, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOP", true)
			StdUi:GlueAbove(CVars.FontStringTitle, CVars)
			CVars.text:SetJustifyH("CENTER")				
			
			local GlobalOverlay = anchor:AddRow()					
			GlobalOverlay:AddElement(PvEPvPToggle, { column = 5.35 })			
			GlobalOverlay:AddElement(StdUi:LayoutSpace(anchor), { column = 0.65 })			
			GlobalOverlay:AddElement(InterfaceLanguage, { column = 6 })			
			anchor:AddRow({ margin = { top = 10 } }):AddElements(ReTarget, Trinkets, { column = "even" })			
			anchor:AddRow():AddElements(ReFocus or StdUi:LayoutSpace(anchor), Burst, { column = "even" })			
			local SpecialRow = anchor:AddRow()
			SpecialRow:AddElement(FPS, { column = 6 })
			SpecialRow:AddElement(HealthStone, { column = 6 })
			anchor:AddRow({ margin = { top = 10 } }):AddElements(AutoTarget, LosSystem, 											{ column = "even" })
			anchor:AddRow({ margin = { top = -5 } }):AddElements(Potion, BossMods, 													{ column = "even" })						
			anchor:AddRow({ margin = { top = -5 } }):AddElements(Racial, StopAtBreakAble, 											{ column = "even" })	
			anchor:AddRow({ margin = { top = -5 } }):AddElements(HeartOfAzeroth or Covenant or AutoAttack, StopCast, 				{ column = "even" })
			anchor:AddRow({ margin = { top = -5 } }):AddElements(AutoShoot, StdUi:LayoutSpace(anchor), 								{ column = "even" })
			anchor:AddRow():AddElements(Color.Title, { column = "even" })	
			anchor:AddRow({ margin = { top = -10 } }):AddElements(Color.UseColor, Color.Picker, { column = "even" })	
			anchor:AddRow():AddElements(Color.Element, Color.Option, { column = "even" })	
			local ThemeRow = anchor:AddRow({ margin = { top = 5 }})
			ThemeRow:AddElement(Color.Theme, { column = 9 })
			ThemeRow:AddElement(Color.ThemeApplyButton, { column = 3 })
			anchor:AddRow():AddElement(PauseChecksPanel)
			PauseChecksPanel:AddRow():AddElement(PauseChecksPanel.titlePanel.label, { column = 12 })
			PauseChecksPanel:AddRow({ margin = { top = 10 } }):AddElement(AntiFakePauses, { column = 12 })
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckSpellIsTargeting, CheckLootFrame, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckVehicle, CheckDeadOrGhost, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckMount, CheckDeadOrGhostTarget, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(CheckCombat, CheckEatingOrDrinking, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -15 } }):AddElement(Misc)		
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableRotationDisplay, DisableBlackBackground, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisablePrint, DisableMinimap, { column = "even" })			
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableClassPortraits, DisableRotationModes, { column = "even" })		
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableSounds, HideOnScreenshot, { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = -10 } }):AddElements(DisableAddonsCheck, StdUi:LayoutSpace(anchor), { column = "even" })	
			PauseChecksPanel:AddRow({ margin = { top = 0 } }):AddElement(CVars, { column = 12 })
			PauseChecksPanel:DoLayout()		
			-- Add empty space for scrollframe after all elements 
			anchor:AddRow():AddElement(StdUi:LayoutSpace(anchor))	
			-- Fix StdUi 			
			-- Lib is not optimized for resize since resizer changes only source parent, this is deep child parent 
			function anchor:DoLayout()
				local l = self.layout
				local width = tab.frame:GetWidth() - l.padding.left - l.padding.right

				local y = -l.padding.top
				for i = 1, #self.rows do
					local r = self.rows[i]
					y = y - r:DrawRow(width, y)
				end
			end			
		
			anchor:DoLayout()		
		end 
		
		if tabName == 2 then 	
			-- Fix StdUi 
			-- Lib has missed scrollframe as widget (need to have function GetChildrenWidgets)
			StdUi:InitWidget(anchor)
			
            UI_Title:SetText(specName)			
			tab.title = specName
			tabFrame:DrawButtons()	
			
			local ProfileUI = ActionData.ProfileUI
			if not ProfileUI or not ProfileUI[tabName] or not ProfileUI[tabName][specID] or not next(ProfileUI[tabName][specID]) then 
				UI_Title:SetText(L["TAB"]["NOTHING"])
				return 
			end 
			local TabProfileUI = ProfileUI[tabName][specID]

			local options = TabProfileUI.LayoutOptions
			if options then 
				if not options.padding then 
					options.padding = {}
				end 
				
				if not options.padding.top then 
					options.padding.top = 35 
				end 	

				-- Cut out scrollbar 
				if not options.padding.right then 
					options.padding.right = 10 + 20
				elseif options.padding.right < 20 then 
					options.padding.right = options.padding.right + 20
				end 
			end 			
			
			StdUi:EasyLayout(anchor, options or { padding = { top = 35, right = 10 + 20 } })	
			
			-- Shadowlands Covenant
			if Action.BuildToC >= 90001 and Action.BuildToC < 100000 and (not TabProfileUI.HasCovenantUI or not TabProfileUI.HasCovenantUI[spec]) then 
				local CovenantUI = {
					{ -- [1] 
						{
							E 				= "Header",
							L 				= { ANY = L["TAB"][tabName]["COVENANTCONFIGURE"] },
						},
					}, 
					{ -- [2]
						{
							E 				= "Slider", 													
							MIN 			= -1, 
							MAX	 			= 100,							
							DB		 		= "FleshcraftHP",
							ONLYOFF 		= true,
							L 				= { ANY = L["TAB"][tabName]["FLESHCRAFTHP"] }, 
							TT 				= { ANY = L["TAB"][tabName]["TOOLTIPHP"] .. L["TAB"]["RIGHTCLICKCREATEMACRO"] }, 
							M 				= {},
						},
						{
							E 				= "Dropdown", 													
							OT 				= {
								{ text = L["TAB"][tabName]["AND"], 	value = "AND" },
								{ text = L["TAB"][tabName]["OR"], 	value = "OR"  },
							},					
							DB		 		= "FleshcraftOperator",
							L 				= { ANY = L["TAB"][tabName]["OPERATOR"] },
							TT 				= { ANY = L["TAB"][tabName]["TOOLTIPOPERATOR"] .. L["TAB"]["RIGHTCLICKCREATEMACRO"] }, 	
							M 				= {},
						},
						{
							E 				= "Slider", 													
							MIN 			= -1, 
							MAX	 			= 50,							
							DB		 		= "FleshcraftTTD",
							ONLYOFF 		= true,
							L 				= { ANY = L["TAB"][tabName]["FLESHCRAFTTTD"] }, 
							TT 				= { ANY = L["TAB"][tabName]["TOOLTIPTTD"] .. L["TAB"]["RIGHTCLICKCREATEMACRO"] }, 
							M 				= {},
						},
					},
					{ -- [3]
						{
							E 				= "Slider", 													
							MIN 			= -1, 
							MAX	 			= 100,							
							DB		 		= "PhialofSerenityHP",
							ONLYOFF 		= true,
							L 				= { ANY = L["TAB"][tabName]["PHIALOFSERENITYHP"] }, 
							TT 				= { ANY = L["TAB"][tabName]["TOOLTIPHP"] .. L["TAB"]["RIGHTCLICKCREATEMACRO"] }, 
							M 				= {},
						},
						{
							E 				= "Dropdown", 													
							OT 				= {
								{ text = L["TAB"][tabName]["AND"], 	value = "AND" },
								{ text = L["TAB"][tabName]["OR"], 	value = "OR"  },
							},					
							DB		 		= "PhialofSerenityOperator",
							L 				= { ANY = L["TAB"][tabName]["OPERATOR"] },
							TT 				= { ANY = L["TAB"][tabName]["TOOLTIPOPERATOR"] .. L["TAB"]["RIGHTCLICKCREATEMACRO"] }, 	
							M 				= {},
						},
						{
							E 				= "Slider", 													
							MIN 			= -1, 
							MAX	 			= 50,							
							DB		 		= "PhialofSerenityTTD",
							ONLYOFF 		= true,
							L 				= { ANY = L["TAB"][tabName]["PHIALOFSERENITYTTD"] }, 
							TT 				= { ANY = L["TAB"][tabName]["TOOLTIPTTD"] .. L["TAB"]["RIGHTCLICKCREATEMACRO"] }, 
							M 				= {},
						},
					},
					{ -- [4]
						{
							E 				= "Checkbox", 
							DB 				= "PhialofSerenityDispel",
							L 				= { ANY = L["TAB"][tabName]["PHIALOFSERENITYDISPEL"] }, 
							TT 				= { ANY = L["TAB"][tabName]["PHIALOFSERENITYDISPELTOOLTIP"] .. L["TAB"]["RIGHTCLICKCREATEMACRO"] }, 
							M 				= {},				
						},					
					},
					{ -- [5]
						{
							E 				= "Header",
							L 				= { ANY = L["TAB"][tabName]["PROFILECONFIGURE"] },
						},
					},
				}
				
				if not TabProfileUI.HasCovenantUI then 
					TabProfileUI.HasCovenantUI = {}
					for i = 1, #CovenantUI do 
						tinsert(TabProfileUI, i, CovenantUI[i])
					end 
				else 
					for i = 1, #CovenantUI do 
						TabProfileUI[i] = CovenantUI[i]
					end 
				end
				TabProfileUI.HasCovenantUI[spec] = true 
			end 
			
			local interfaceLanguage = gActionDB.InterfaceLanguage
			local specRow, obj
			for row = 1, #TabProfileUI do 
				specRow = anchor:AddRow(TabProfileUI[row].RowOptions)	
				for element = 1, #TabProfileUI[row] do 
					local config 	= TabProfileUI[row][element]	
					local cL	 	= (config.L  and (interfaceLanguage and  config.L[interfaceLanguage] and interfaceLanguage or config.L[GameLocale]  and GameLocale)) or "enUS"
					local cTT 		= (config.TT and (interfaceLanguage and config.TT[interfaceLanguage] and interfaceLanguage or config.TT[GameLocale] and GameLocale)) or "enUS"	
					
					if config.E == "Label" then 
						obj = StdUi:Label(anchor, config.L.ANY or config.L[cL], config.S or 14)
					end
					
					if config.E == "Header" then 
						obj = StdUi:Header(anchor, config.L.ANY or config.L[cL])
						obj:SetAllPoints()			
						obj:SetJustifyH("CENTER")						
						obj:SetFontSize(config.S or 14)	
					end 
					
					if config.E == "Button" then 
						obj = StdUi:Button(anchor, StdUi:GetWidthByColumn(anchor, math_floor(12 / #TabProfileUI[row])), config.H or 20, config.L.ANY or config.L[cL])
						obj:RegisterForClicks("LeftButtonUp", "RightButtonUp")
						if config.OnClick then 
							obj:SetScript("OnClick", function(self, button, down)
								if not self.isDisabled then 
									config.OnClick(self, button, down) 
								end 
							end)
						end 
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[cTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)
						--obj.FontStringTitle = StdUi:Subtitle(obj, config.L.ANY or config.L[cL])
						--StdUi:GlueAbove(obj.FontStringTitle, obj)
						if config.isDisabled then 
							obj:Disable()
						end 
					end 
					
					if config.E == "Checkbox" then 						
						obj = StdUi:Checkbox(anchor, config.L.ANY or config.L[cL])						
						obj:SetChecked(specDB[config.DB])
						obj:RegisterForClicks("LeftButtonUp", "RightButtonUp")
						obj:SetScript("OnClick", function(self, button, down)	
							if not self.isDisabled then 	
								if button == "LeftButton" then 
									specDB[config.DB] = not specDB[config.DB]
									self:SetChecked(specDB[config.DB])	
									if OnToggleHandler[tabName][config.DB] then 
										OnToggleHandler[tabName][config.DB](specDB)
									end
									Action.Print((config.L.ANY or config.L[cL]) .. ": ", specDB[config.DB])	
								elseif button == "RightButton" and config.M then 
									Action.CraftMacro( config.L.ANY or config.L[cL], config.M.Custom or ([[/run Action.SetToggle({]] .. (config.M.TabN or tabName) .. [[, "]] .. config.DB .. [[", "]] .. (config.M.Print or config.L.ANY or config.L[cL]) .. [[: "}, ]] .. (config.M.Value or "nil") .. [[)]]), 1 )	
								end 
							end
						end)
						obj.Identify = { Type = config.E, Toggle = config.DB }
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[cTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)
						if config.isDisabled then 
							obj:Disable()
						end 
					end 
					
					if config.E == "Dropdown" then
						-- Get formated by localization in OT
						local FormatedOT 
						for p = 1, #config.OT do 
							if type(config.OT[p].text) == "table" then 
								FormatedOT = {}
								for j = 1, #config.OT do 
									if type(config.OT[j].text) ~= "table" then 
										FormatedOT[#FormatedOT + 1] = config.OT[j]
									else
										local OT = interfaceLanguage and config.OT[j].text[interfaceLanguage] and interfaceLanguage or config.OT[j].text[GameLocale] and GameLocale or "enUS"
										FormatedOT[#FormatedOT + 1] = { text = config.OT[j].text.ANY or config.OT[j].text[OT], value = config.OT[j].value }
									end 
								end
								break 
							end 
						end 
						obj = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, math_floor(12 / #TabProfileUI[row])), config.H or 20, FormatedOT or config.OT, nil, config.MULT, config.MULT or false)
						if config.SetPlaceholder then 
							obj:SetPlaceholder(config.SetPlaceholder.ANY or config.SetPlaceholder[cL])
						end 
						if config.MULT then 
							for i, v in ipairs(obj.optsFrame.scrollChild.items) do 
								v:SetChecked(specDB[config.DB][i])
							end
							obj.OnValueChanged = function(self, value)			
								for i, v in ipairs(self.optsFrame.scrollChild.items) do 					
									if specDB[config.DB][i] ~= v:GetChecked() then
										specDB[config.DB][i] = v:GetChecked()
										Action.Print((config.L.ANY or config.L[cL]) .. ": " .. self.options[i].text .. " = ", specDB[config.DB][i])
									end 				
								end 				
							end
						else 
							obj:SetValue(specDB[config.DB])
							obj.OnValueChanged = function(self, val)                
								specDB[config.DB] = val 
								if (config.isNotEqualVal and val ~= config.isNotEqualVal) or (config.isNotEqualVal == nil and val ~= "Off" and val ~= "OFF" and val ~= 0) then 
									ActionData.TG[config.DB] = val
								end 
								Action.Print((config.L.ANY or config.L[cL]) .. ": ", specDB[config.DB])
							end
						end 
						obj:RegisterForClicks("LeftButtonUp", "RightButtonUp")
						obj:SetScript("OnClick", function(self, button, down)
							if not self.isDisabled then 
								if button == "LeftButton" then 
									self:ToggleOptions()
								elseif button == "RightButton" and config.M then 
									Action.CraftMacro( config.L.ANY or config.L[cL], config.M.Custom or ([[/run Action.SetToggle({]] .. (config.M.TabN or tabName) .. [[, "]] .. config.DB .. [[", "]] .. (config.M.Print or config.L.ANY or config.L[cL]) .. [[: "}, ]] .. (config.M.Value or (not config.MULT and self:GetValue() and ([["]] .. self:GetValue() .. [["]])) or "nil") .. [[)]]), 1 )								
								end
							end
						end)
						obj.Identify = { Type = config.E, Toggle = config.DB }
						obj.FontStringTitle = StdUi:Subtitle(obj, config.L.ANY or config.L[cL])
						obj.FontStringTitle:SetJustifyH("CENTER")
						obj.text:SetJustifyH("CENTER")
						StdUi:GlueAbove(obj.FontStringTitle, obj)						
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[cTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)	
						if config.isDisabled then 
							obj:Disable()
						end 
					end 
					
					if config.E == "Slider" then	
						obj = StdUi:Slider(anchor, math_floor(12 / #TabProfileUI[row]), config.H or 20, specDB[config.DB], false, config.MIN or -1, config.MAX or 100)	
						if config.Precision then 
							obj:SetPrecision(config.Precision)
						end
						if config.M then 
							obj:SetScript("OnMouseUp", function(self, button, down)
								if button == "RightButton" then 
									Action.CraftMacro( config.L.ANY or config.L[cL], [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. config.DB .. [[", "]] .. (config.M.Print or config.L.ANY or config.L[cL]) .. [[: "}, ]] .. specDB[config.DB] .. [[)]], 1 )	
								end					
							end)
						end 
						local ONOFF = function(value)
							if config.ONLYON then 
								return (config.L.ANY or config.L[cL]) .. ": |cff00ff00" .. (value >= config.MAX and "|cff00ff00AUTO|r" or value)
							elseif config.ONLYOFF then 
								return (config.L.ANY or config.L[cL]) .. ": |cff00ff00" .. (value <= config.MIN and "|cffff0000OFF|r" or value)
							elseif config.ONOFF then 
								return (config.L.ANY or config.L[cL]) .. ": |cff00ff00" .. (value <= config.MIN and "|cffff0000OFF|r" or value >= config.MAX and "|cff00ff00AUTO|r" or value)
							else
								return (config.L.ANY or config.L[cL]) .. ": |cff00ff00" .. value .. "|r"
							end 
						end 
						obj.OnValueChanged = function(self, value)
							if not config.Precision then 
								value = math_floor(value) 
							elseif value < 0 then 
								value = config.MIN or -1
							end
							specDB[config.DB] = value
							self.FontStringTitle:SetText(ONOFF(value))
						end
						obj.Identify = { Type = config.E, Toggle = config.DB }						
						obj.FontStringTitle = StdUi:Subtitle(obj, ONOFF(specDB[config.DB]))
						obj.FontStringTitle:SetJustifyH("CENTER")						
						StdUi:GlueAbove(obj.FontStringTitle, obj)						
						StdUi:FrameTooltip(obj, (config.TT and (config.TT.ANY or config.TT[cTT])) or config.M and L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "BOTTOM", true)						
					end 
					
					if config.E == "LayoutSpace" then	
						obj = StdUi:LayoutSpace(anchor)
					end 
					
					local margin = config.ElementOptions and config.ElementOptions.margin or { top = 10 } 					
					specRow:AddElement(obj, { column = math_floor(12 / #TabProfileUI[row]), margin = margin })
				end
			end
			
			-- Add some empty space after all elements 
			if #TabProfileUI > 12 then 
				for row = 1, 2 do 
					anchor:AddRow():AddElement(StdUi:LayoutSpace(anchor), { column = 12, margin = { top = 10 } })	
				end 
			end 
			
			-- Fix StdUi 			
			-- Lib is not optimized for resize since resizer changes only source parent, this is deep child parent 
			function anchor:DoLayout()
				local l = self.layout
				local width = tab.frame:GetWidth() - l.padding.left - l.padding.right

				local y = -l.padding.top
				for i = 1, #self.rows do
					local r = self.rows[i]
					y = y - r:DrawRow(width, y)
				end
			end			

			anchor:DoLayout()	
		end 
		
		if tabName == 3 then 
			if not Action[specID] then 
				UI_Title:SetText(L["TAB"]["NOTHING"])
				return
			end 
			UI_Title:SetText(L["TAB"][tabName]["HEADTITLE"])
			StdUi:EasyLayout(anchor, { padding = { top = 50 } })	
			
			local Scroll, ScrollTable, Key, SetQueue, SetBlocker, MacroButton, MacroEditor, LuaButton, LuaEditor, QLuaButton, QLuaEditor, AutoHidden, CheckSpellLevel
			
			local AutoHiddenEvents				= {
				["ACTIVE_TALENT_GROUP_CHANGED"]	= true,
				["BAG_UPDATE"]					= true,
				["BAG_UPDATE_COOLDOWN"]			= true,
				["PLAYER_EQUIPMENT_CHANGED"]	= true,
				["UNIT_INVENTORY_CHANGED"]		= true,
				["UI_INFO_MESSAGE"]				= true,
				--["UNIT_PET"] 					= true, -- Replaced by callbacks "TMW_ACTION_PET_LIBRARY_MAIN_PET_UP" and "TMW_ACTION_PET_LIBRARY_MAIN_PET_DOWN"
				--["PLAYER_LEVEL_UP"]			= true,	-- Retail: Replaced by callback "TMW_ACTION_SPELL_BOOK_CHANGED"	
			}
			local AutoHiddenToggle				= function()
				local script 					= ScrollTable:GetScript("OnEvent")
				if Action.GetToggle(tabName, "AutoHidden") then 
					-- Registers events 
					for k in pairs(AutoHiddenEvents) do 
						ScrollTable:RegisterEvent(k)
					end 
					
					-- Registers callback (Retail: SpellLevel)					
					TMW:RegisterCallback("TMW_ACTION_SPELL_BOOK_CHANGED", 			script)
					TMW:RegisterCallback("TMW_ACTION_PET_LIBRARY_MAIN_PET_UP", 		script)
					TMW:RegisterCallback("TMW_ACTION_PET_LIBRARY_MAIN_PET_DOWN", 	script)
				else 
					-- Unregisters events 
					for k in pairs(AutoHiddenEvents) do 
						ScrollTable:UnregisterEvent(k)
					end 
					
					-- Unregisters callback 
					TMW:UnregisterCallback("TMW_ACTION_SPELL_BOOK_CHANGED", 		script)
					TMW:UnregisterCallback("TMW_ACTION_PET_LIBRARY_MAIN_PET_UP", 	script)
					TMW:UnregisterCallback("TMW_ACTION_PET_LIBRARY_MAIN_PET_DOWN",  script)
				end 
			end 
			
			-- UI: Scroll
			Scroll 						= setmetatable({
				OnClickCell 			= function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
					if button == "LeftButton" then						
						if rowData.MacroForbidden or not Action.MetaEngine or not Action.MetaEngine:IsSafe() then
							MacroButton.FontStringMacro:SetText(themeOFF)
							MacroEditor.EditBox:Disable()
							MacroButton:Disable()
						else
							local formattedMacro, unformattedMacro, isUserMacro = rowData:GetMacro()
							MacroEditor.action = rowData
							MacroEditor.Preview.SkipNextTimer = TMW.time + 2
							MacroEditor.EditBox:SetText(unformattedMacro)
							MacroEditor.Preview:SetText(formattedMacro)								
							MacroEditor.Preview.SetFormattedMacro()							
							MacroEditor.EditBox:Enable()
							MacroButton:Enable()
							Action.TimerDestroy("MacroWindow.Preview")
							if isUserMacro then
								MacroButton.FontStringMacro:SetText(themeON)
							else
								MacroButton.FontStringMacro:SetText(themeOFF)
							end
						end
						
						local luaCode = rowData:GetLUA() or ""
						LuaEditor.EditBox:SetText(luaCode)
						if luaCode and luaCode ~= "" then 
							LuaButton.FontStringLUA:SetText(themeON)
						else 
							LuaButton.FontStringLUA:SetText(themeOFF)
						end 
						
						local QluaCode = rowData:GetQLUA() or ""
						QLuaEditor.EditBox:SetText(QluaCode)
						if QluaCode and QluaCode ~= "" then 
							QLuaButton.FontStringLUA:SetText(themeON)
						else 
							QLuaButton.FontStringLUA:SetText(themeOFF)
						end 					
						
						Key:SetText(rowData.TableKeyName)
						Key:ClearFocus()
						
						if columnData.index == "Enabled" then
							rowData:SetBlocker()
							table:ClearSelection()
						elseif IsShiftKeyDown() then
							local actionLink 
							if BindPadFrame and BindPadFrame:IsVisible() then 
								actionLink = rowData:Info()
							else 
								actionLink = rowData:Link()
							end 
							
							ChatEdit_InsertLink(actionLink)				
						end 
					end
				end,
				OnClickHeader 			= function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						Key:ClearFocus()	
					end	
				end, 
				ColorTrue 				= { r = 0, g = 1, b = 0, a = 1 },
				ColorFalse 				= { r = 1, g = 0, b = 0, a = 1 },
			}, { __index 				= function(t, v) return t.Table[v] end })
			Scroll.Table 				= StdUi:ScrollTable(anchor, {
                {
                    name = L["TAB"][tabName]["ENABLED"],
                    width = 70,
                    align = "LEFT",
                    index = "Enabled",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "True" then
                            return Scroll.ColorTrue
                        end
                        if value == "False" then
                            return Scroll.ColorFalse
                        end
                    end,
					events = {
						OnClick = Scroll.OnClickCell,
					},
                },
                {
                    name = "ID",
                    width = 70,
                    align = "LEFT",
                    index = "ID",
                    format = "number",  
					events = {
						OnClick = Scroll.OnClickCell,
					},
                },
                {
                    name = L["TAB"][tabName]["NAME"],
                    width = 197,
					defaultwidth = 197,
					resizeDivider = 2,
					defaultSort = "dsc",
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {
						OnClick = Scroll.OnClickCell,
					},
                },
				{
                    name = L["TAB"][tabName]["DESC"],
                    width = 90,
					defaultwidth = 90,
					resizeDivider = 2,
                    align = "LEFT",
                    index = "Desc",
                    format = "string",
					events = {
						OnClick = Scroll.OnClickCell,
					},
                },
                {
                    name = L["TAB"][tabName]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, rowData.ID, rowData.Type)    							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)   							
                        end,
						OnClick = Scroll.OnClickCell,
                    },
                },
            }, 15, 25)
			ScrollTable					= Scroll.Table 	-- Shortcut
			anchor.ScrollTable 			= ScrollTable 	-- For SetBlocker reference					
			ScrollTable.defaultrows 	= { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable.Data 			= {}
			ScrollTable.SORTBY 			= 3
			ScrollTable:SortData(ScrollTable.SORTBY)
			ScrollTable:SortData(ScrollTable.SORTBY)
			ScrollTable:RegisterEvents(nil, { OnClick = Scroll.OnClickHeader })
            ScrollTable:EnableSelection(true)			
			ScrollTable.OnPairs			= function(self, k, v, isAutoHidden)
				if type(v) == "table" and not v.Hidden and not v.HiddenUI and v.Type and v.ID and v.Desc then  
					local Enabled = v:IsBlocked() and "False" or "True"
					local isShown = true 
					
					-- AutoHidden unavailable 
					if isAutoHidden and v.ID ~= ActionConst.PICKPOCKET then 								
						if v.Type == "SwapEquip" then 
							if not v:IsExists() then 
								isShown = false 
							end 
						elseif v.Type == "Spell" then 															
							if not v:IsExists(v.isReplacement) or v:IsBlockedBySpellLevel() or (v.isTalent and not v:IsTalentLearned()) or (v.isCovenant and not v:IsCovenantLearned()) then 
								isShown = false 
							end 
						else 
							if v.Type == "Trinket" then 
								if not v:GetEquipped() then 
									isShown = false 
								end 
							else 
								if not (v:GetCount() > 0 or v:GetEquipped()) then 
									isShown = false 
								end 
							end								
						end 
					end 
					
					if isShown then 
						tinsert(self.Data, setmetatable({ 
							Enabled = Enabled, 				
							Name = (v:Info()) or "",
							Icon = (v.Type == "Spell" and (select(2, Action.GetSpellTexture(v, v.TextureID)))) or (v:Icon()) or ActionConst.TRUE_PORTRAIT_PICKPOCKET,
							TableKeyName = k,
						}, { __index = Action[specID][k] or Action }))
					end 
				end
			end 
			ScrollTable.MakeUpdate		= function(self)
				local isAutoHidden 		= Action.GetToggle(tabName, "AutoHidden")
				
				wipe(ScrollTable.Data)					
				for k, v in pairs(Action[specID]) do 
					ScrollTable:OnPairs(k, v, isAutoHidden)
				end
				for k, v in pairs(Action) do 
					ScrollTable:OnPairs(k, v, isAutoHidden)
				end
				
				ScrollTable:SetData(ScrollTable.Data)
				ScrollTable:SortData(ScrollTable.SORTBY)
				
				-- Update selection
				local index = ScrollTable:GetSelection()
				if not index then 
					Key:SetText("")
					Key:ClearFocus() 
				else 
					local data = ScrollTable:GetRow(index)
					if data then 
						if data.TableKeyName ~= Key:GetText() then 
							Key:SetText(data.TableKeyName)
						end 
					else 
						Key:SetText("")
						Key:ClearFocus() 
					end 
				end
			end 
			ScrollTable:SetScript("OnShow", ScrollTable.MakeUpdate)
			ScrollTable:SetScript("OnEvent", function(self, event, ...)				
				if ScrollTable:IsVisible() and Action.GetToggle(tabName, "AutoHidden") then 
					-- Update ScrollTable 
					-- If pet has been gone or summoned or swaped
					if event == "UNIT_PET" or event == "UNIT_INVENTORY_CHANGED" then 
						if ... == "player" then 						
							ScrollTable:MakeUpdate()
						end 
					-- If war mode has been changed 
					elseif event == "UI_INFO_MESSAGE" then 
						if Action.UI_INFO_MESSAGE_IS_WARMODE(...) then 
							ScrollTable:MakeUpdate()
						end
					-- If items/talents have been updated 
					else 		
						ScrollTable:MakeUpdate()
					end 
				end  
			end)
			hooksecurefunc(ScrollTable, "ClearSelection", function()	
				if MacroEditor:IsShown() then 
					MacroEditor.closeBtn:Click()
					MacroEditor.Preview.SkipNextTimer = TMW.time + 2
					MacroEditor.EditBox:SetText("")
					MacroEditor.Preview:SetText("")
					Action.TimerDestroy("MacroWindow.Preview")						
				end 		
				
				LuaEditor.EditBox:SetText("")
				if LuaEditor:IsShown() then 
					LuaEditor.closeBtn:Click()
				end 
				
				QLuaEditor.EditBox:SetText("")
				if QLuaEditor:IsShown() then 
					QLuaEditor.closeBtn:Click()
				end 				
			end)
			TMW:RegisterCallback("TMW_ACTION_SET_BLOCKER_CHANGED", function(callbackEvent, callbackAction)
				if ScrollTable:IsVisible() then 
					local Identify = callbackAction:GetTableKeyIdentify()
					for i = 1, #ScrollTable.data do 
						if Identify == ScrollTable.data[i]:GetTableKeyIdentify() then 
							if callbackAction:IsBlocked() then 
								ScrollTable.data[i].Enabled = "False"
							else 
								ScrollTable.data[i].Enabled = "True"
							end								 			
						end 
					end		
					ScrollTable:ClearSelection() 
				end 
			end)
			TMW:RegisterCallback("TMW_ACTION_SOUL_BINDS_UPDATED", function(callbackEvent)
				if ScrollTable:IsVisible() then 
					ScrollTable.MakeUpdate()
				end 
			end)
			
			-- UI: Key 
			Key 						= StdUi:SimpleEditBox(anchor, 150, themeHeight, "")	
			Key.FontString 				= StdUi:Subtitle(Key, L["TAB"]["KEY"]) 
			Key:SetJustifyH("CENTER")			
			Key:SetScript("OnTextChanged", function(self)
				local index = ScrollTable:GetSelection()				
				if not index then 
					self:SetText("")
					return
				else 
					local data = ScrollTable:GetRow(index)						
					if data and data.TableKeyName ~= self:GetText() then 
						self:SetText(data.TableKeyName)
					end 
				end 
            end)
			Key:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()                
            end)
			Key:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)	
			StdUi:GlueAbove(Key.FontString, Key)		
			StdUi:FrameTooltip(Key, L["TAB"][tabName]["KEYTOOLTIP"], nil, "TOP", true)	
			
			-- UI: SetQueue
			SetQueue 					= StdUi:Button(anchor, anchor:GetWidth() / 2 + 20, 30, L["TAB"][tabName]["SETQUEUE"])
			SetQueue.SetToggleOptions 	= { Priority = 1 }
			SetQueue:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			SetQueue:SetScript("OnClick", function(self, button, down)
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][tabName]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					if data.QueueForbidden or ((data.Type == "Trinket" or data.Type == "Item") and not data:GetItemSpell()) then 
						Action.Print(L["DEBUG"] .. data:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORQUEUE"])
					-- I decided unlocked Queue for blocked actions
					--elseif data:IsBlocked() and not data.Queued then 
						--Action.Print(L["DEBUG"] .. data:Link() .. " " .. L["TAB"][3]["QUEUEBLOCKED"])
					else
						if button == "LeftButton" then 	
							local action = getmetatable(data).__index
							action:SetQueue(self.SetToggleOptions)							
						elseif button == "RightButton" then 						
							Action.CraftMacro("Queue: " .. data.TableKeyName, [[#showtooltip ]] .. data:Info() .. "\n" .. [[/run Action.MacroQueue("]] .. data.TableKeyName .. [[", { Priority = 1 })]], 1, true, true)	
						end
					end 
				end 
			end)			         
            StdUi:FrameTooltip(SetQueue, L["TAB"][tabName]["SETQUEUETOOLTIP"], nil, "TOPLEFT", true)	
			
			-- UI: SetBlocker
			SetBlocker 					= StdUi:Button(anchor, anchor:GetWidth() / 2 + 20, 30, L["TAB"][tabName]["SETBLOCKER"])
			SetBlocker:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			SetBlocker:SetScript("OnClick", function(self, button, down)
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][tabName]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					if button == "LeftButton" then 
						data:SetBlocker()						
					elseif button == "RightButton" then 						
						Action.CraftMacro("Block: " .. data.TableKeyName, [[#showtooltip ]] .. data:Info() .. "\n" .. [[/run Action.MacroBlocker("]] .. data.TableKeyName .. [[")]], 1, true, true)	
					end
				end 
			end)			         
            StdUi:FrameTooltip(SetBlocker, L["TAB"][tabName]["SETBLOCKERTOOLTIP"], nil, "TOPRIGHT", true)
						
			-- UI: LuaButton
			LuaButton 					= StdUi:Button(anchor, 50, themeHeight - 3, "LUA")
			LuaButton.FontStringLUA 	= StdUi:Subtitle(LuaButton, themeOFF)
			LuaButton:SetScript("OnClick", function()		
				if QLuaEditor:IsShown() then 
					QLuaEditor.closeBtn:Click()
					return 
				end 
				
				if not LuaEditor:IsShown() then 
					local index = ScrollTable:GetSelection()				
					if not index then 
						Action.Print(L["TAB"][tabName]["SELECTIONERROR"]) 
					else 				
						LuaEditor:Show()
					end 
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueAbove(LuaButton, SetQueue, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, 0, 0)
			
			-- UI: LuaEditor
			LuaEditor 					= StdUi:CreateLuaEditor(anchor, L["TAB"]["LUAWINDOW"], MainUI.default_w, MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			LuaEditor:HookScript("OnHide", function(self)
				local index = ScrollTable:GetSelection()
				local data = index and ScrollTable:GetRow(index) or nil
				if not self.EditBox.LuaErrors and data then 
					local luaCode = self.EditBox:GetText()
					local Identify = data:GetTableKeyIdentify()
					if luaCode == "" then 
						luaCode = nil 
					end 
					local isChanged = data:GetLUA() ~= luaCode
					
					data:SetLUA(luaCode)
					if data:GetLUA() then 
						LuaButton.FontStringLUA:SetText(themeON)
						if isChanged then 
							Action.Print(L["TAB"][tabName]["LUAAPPLIED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					else 
						LuaButton.FontStringLUA:SetText(themeOFF)	
						if isChanged then 
							Action.Print(L["TAB"][tabName]["LUAREMOVED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					end 
				end 
			end)
			
			-- UI: QLuaButton	
			QLuaButton					= StdUi:Button(anchor, 50, themeHeight - 3, "QLUA")
			QLuaButton.FontStringLUA 	= StdUi:Subtitle(QLuaButton, themeOFF)
			QLuaButton:SetScript("OnClick", function()		
				if LuaEditor:IsShown() then 
					LuaEditor.closeBtn:Click()
					return 
				end 
				
				if not QLuaEditor:IsShown() then 
					local index = ScrollTable:GetSelection()				
					if not index then 
						Action.Print(L["TAB"][tabName]["SELECTIONERROR"]) 
					else 		
						local data = ScrollTable:GetRow(index)
						if not data:GetQLUA() and (data.QueueForbidden or ((data.Type == "Trinket" or data.Type == "Item") and not data:GetItemSpell())) then 
							Action.Print(L["DEBUG"] .. data:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORQUEUE"] .. " " .. L["TAB"][3]["KEY"] .. data.TableKeyName .. "]")
						else 
							QLuaEditor:Show()
						end 
					end 
				else 
					QLuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueAbove(QLuaButton, LuaButton, 0, 0)
			StdUi:GlueLeft(QLuaButton.FontStringLUA, QLuaButton, 0, 0)
			
			-- UI: QLuaEditor
			QLuaEditor					= StdUi:CreateLuaEditor(anchor, "Queue " .. L["TAB"]["LUAWINDOW"], MainUI.default_w, MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			QLuaEditor:HookScript("OnHide", function(self)
				local index = ScrollTable:GetSelection()
				local data = index and ScrollTable:GetRow(index) or nil
				if not self.EditBox.LuaErrors and data then 
					local luaCode = self.EditBox:GetText()
					local Identify = data:GetTableKeyIdentify()
					if luaCode == "" then 
						luaCode = nil 
					end 
					local isChanged = data:GetQLUA() ~= luaCode
					
					data:SetQLUA(luaCode)
					if data:GetQLUA() then 
						QLuaButton.FontStringLUA:SetText(themeON)
						if isChanged then 
							Action.Print("Queue " .. L["TAB"][tabName]["LUAAPPLIED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					else 
						QLuaButton.FontStringLUA:SetText(themeOFF)	
						if isChanged then 
							Action.Print("Queue " .. L["TAB"][tabName]["LUAREMOVED"] .. data:Link() .. " " .. L["TAB"][3]["KEY"] .. Identify .. "]")
						end 
					end 
				end 
			end)
			
			-- UI: MacroButton
			MacroButton 				= StdUi:Button(anchor, 50, themeHeight - 3, L["TAB"][tabName]["MACRO"])
			MacroButton.FontStringMacro	= StdUi:Subtitle(MacroButton, themeOFF)
			MacroButton:Disable()
			MacroButton:SetScript("OnClick", function()	
				if not MacroEditor:IsShown() then
					local index = ScrollTable:GetSelection()
					if not index then 
						Action.Print(L["TAB"][tabName]["SELECTIONERROR"]) 
					else 				
						MacroEditor:Show()
					end 
				else
					MacroEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueLeft(MacroButton, QLuaButton.FontStringLUA, -5, 0)
			StdUi:GlueLeft(MacroButton.FontStringMacro, MacroButton, 0, 0)
			
			-- UI: MacroEditor
			MacroEditor					= StdUi:CreateMacroEditor(anchor, L["TAB"][tabName]["MACRO"], MainUI.default_w, MainUI.default_h, L["TAB"][tabName]["MACROTOOLTIP"])
			MacroEditor:HookScript("OnHide", function(self)
				local index = ScrollTable:GetSelection()
				local data = index and ScrollTable:GetRow(index) or nil
				if data then 
					if data.MacroForbidden then 
						A_Print(L["DEBUG"] .. self:Link() .. " " .. L["TAB"][3]["ISFORBIDDENFORMACRO"])
						MacroButton.FontStringMacro:SetText(themeOFF)						
					end

					local _, _, isUserMacro = data:GetMacro()
					if not data.MacroForbidden and isUserMacro then 
						MacroButton.FontStringMacro:SetText(themeON)
					else 
						MacroButton.FontStringMacro:SetText(themeOFF)
					end 
				end 
			end)						
			
			-- UI: AutoHidden
			AutoHiddenToggle() -- Initialize
			AutoHidden 					= StdUi:Checkbox(anchor, L["TAB"][tabName]["AUTOHIDDEN"])
			AutoHidden:SetChecked(tabDB.AutoHidden)
			AutoHidden:RegisterForClicks("LeftButtonUp")
			AutoHidden.ToggleTable = {tabName, "AutoHidden", L["TAB"][tabName]["AUTOHIDDEN"] .. ": "}
			AutoHidden:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					if button == "LeftButton" then 
						Action.SetToggle(self.ToggleTable)
						ScrollTable:MakeUpdate()
						AutoHiddenToggle()
					end 
				end 
			end)
			AutoHidden.Identify = { Type = "Checkbox", Toggle = "AutoHidden" }
			StdUi:FrameTooltip(AutoHidden, L["TAB"][tabName]["AUTOHIDDENTOOLTIP"], nil, "TOP", true)				
			
			-- UI: CheckSpellLevel
			CheckSpellLevel 				= StdUi:Checkbox(anchor, L["TAB"][tabName]["CHECKSPELLLVL"])	
			CheckSpellLevel:SetChecked(tabDB.CheckSpellLevel)
			CheckSpellLevel:RegisterForClicks("LeftButtonUp")
			CheckSpellLevel.ToggleTable = {tabName, "CheckSpellLevel", L["TAB"][tabName]["CHECKSPELLLVL"] .. ": "}
			CheckSpellLevel.ToggleName  = {tabName, "LastDisableName"}
			CheckSpellLevel:SetScript("OnClick", function(self, button, down)
				if not self.isDisabled then 
					if button == "LeftButton" then 	
						if tabDB.CheckSpellLevel then 
							Action.SetToggle(self.ToggleName, UnitName("player"))
						end 
						Action.SetToggle(self.ToggleTable)
						SpellLevel:Initialize()
					end 
				end 
			end)
			CheckSpellLevel:SetScript("OnShow", function(self)
				if UnitLevel("player") >= SpellLevel:GetMaxLevelXpac() then 
					if tabDB.CheckSpellLevel then 
						self:Click("LeftButton")
					end 
					self:Disable()
				else 
					self:Enable()
				end 
			end)
			TMW:RegisterCallback("TMW_ACTION_SPELL_BOOK_MAX_LEVEL", function() CheckSpellLevel:Disable() end)
			CheckSpellLevel.Identify = { Type = "Checkbox", Toggle = "CheckSpellLevel" }
			StdUi:FrameTooltip(CheckSpellLevel, L["TAB"][tabName]["CHECKSPELLLVLTOOLTIP"], nil, "TOP", true)

			anchor:AddRow({ margin = { left = -15, right = -15 } }):AddElement(ScrollTable)
			anchor:AddRow({ margin = { left = -15, right = -15 } }):AddElement(Key)
			anchor:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElement(AutoHidden)
			anchor:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElement(CheckSpellLevel)
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(SetBlocker, SetQueue, { column = "even" })
			anchor:DoLayout()
			
			-- If we had return back to this tab then handler will be skipped 
			if MainUI.RememberTab == tabName then
				ScrollTable:MakeUpdate()
			end 	
		end 
		
		if tabName == 4 then					
			UI_Title:Hide()		
			StdUi:EasyLayout(anchor)
						
			local Category,			Scroll,			SliderMin,			SliderMax,
				  UseMain, 			UseMouse,		UseHeal, 			UsePvP, 		-- Checkbox (Toggle "Main", "Mouse", "PvP", "Heal" -> Checkbox)
				  MainAuto, 		MouseAuto,		HealOnlyHealers, 	PvPOnlySmart, 	-- Sub-Checkbox
				  ConfigPanel, 		ResetButton, 	LuaButton, 			LuaEditor,				  
				  InputBox, 		How,  			Add, 				Remove		
			local ScrollTable
			
			local function ValidateSliderColor()
				local min, max = SliderMin:GetValue(), SliderMax:GetValue()				
				if max - min < 17 then 
					local category  = Category:GetValue()
					if tabDB[category].Min and tabDB[category].Max then 
						SliderMin.FontStringTitle:SetText(L["TAB"][tabName]["MIN"] .. "|cffff0000" .. min .. "%|r")			 
						SliderMax.FontStringTitle:SetText(L["TAB"][tabName]["MAX"] .. "|cffff0000" .. max .. "%|r")	
					end 
				else				
					SliderMin.FontStringTitle:SetText(L["TAB"][tabName]["MIN"] .. "|cff00ff00" .. min .. "%|r")			 
					SliderMax.FontStringTitle:SetText(L["TAB"][tabName]["MAX"] .. "|cff00ff00" .. max .. "%|r")	
				end 
			end 
						
			local function CheckboxsMakeUpdate()	
				tab.isUpdatingCheckboxes = true 
				
				local category = Category:GetValue()
		
				if category == "MainPvE" or category == "MainPvP" then 
					-- Checkbox 
					UseMain:Enable()
					UseMouse:Disable()
					UseHeal:Disable()
					UsePvP:Disable()
					-- Sub-Checkbox
					if Action.InterruptIsON("Main") then 
						MainAuto:Enable()
					else 
						MainAuto:Disable()
					end 
					MouseAuto:Disable()
					HealOnlyHealers:Disable()
					PvPOnlySmart:Disable()
					
					tab.isUpdatingCheckboxes = nil 
					return 
				end 
				
				if category == "MousePvE" or category == "MousePvP" then 
					-- Checkbox 
					UseMain:Disable()
					UseMouse:Enable()
					UseHeal:Disable()
					UsePvP:Disable()
					-- Sub-Checkbox
					MainAuto:Disable()
					if Action.InterruptIsON("Mouse") then 
						MouseAuto:Enable()
					else 
						MouseAuto:Disable()
					end 
					HealOnlyHealers:Disable()
					PvPOnlySmart:Disable()
					
					tab.isUpdatingCheckboxes = nil 
					return 
				end 
				
				if category == "Heal" then 
					-- Checkbox 
					UseMain:Disable()
					UseMouse:Disable()
					UseHeal:Enable()
					UsePvP:Disable()
					-- Sub-Checkbox
					MainAuto:Disable()
					MouseAuto:Disable()
					if Action.InterruptIsON("Heal") then 
						HealOnlyHealers:Enable()
					else 
						HealOnlyHealers:Disable()
					end 					
					PvPOnlySmart:Disable()
					
					tab.isUpdatingCheckboxes = nil 
					return 
				end
				
				if category == "PvP" then 
					-- Checkbox 
					UseMain:Disable()
					UseMouse:Disable()
					UseHeal:Disable()
					UsePvP:Enable()
					-- Sub-Checkbox
					MainAuto:Disable()
					MouseAuto:Disable()
					HealOnlyHealers:Disable()
					if Action.InterruptIsON("PvP") then 
						PvPOnlySmart:Enable()
					else 
						PvPOnlySmart:Disable()
					end 

					tab.isUpdatingCheckboxes = nil 
					return 					
				end
			
				-- BlackList or custom category
				-- Checkbox 
				UseMain:Disable()
				UseMouse:Disable()
				UseHeal:Disable()
				UsePvP:Disable()
				-- Sub-Checkbox
				MainAuto:Disable()
				MouseAuto:Disable()
				HealOnlyHealers:Disable()
				PvPOnlySmart:Disable()
					
				tab.isUpdatingCheckboxes = nil 
			end 
			
			local function CreateCheckbox(db)
				local thisL  = L["TAB"][tabName][db:upper()]
				local thisTT = L["TAB"][tabName][(db:upper() or "nil") .. "TOOLTIP"]
				local Checkbox = StdUi:Checkbox(anchor, thisL, 250)
				Checkbox:SetChecked(specDB[db])
				Checkbox:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				Checkbox:SetScript("OnClick", function(self, button, down)
					if not self.isDisabled then						
						if button == "LeftButton" then 
							specDB[db] = not specDB[db]	
							self:SetChecked(specDB[db])	
							Action.Print(thisL .. ": ", specDB[db])	
						elseif button == "RightButton" then 
							Action.CraftMacro(thisL, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. db .. [[", "]] .. thisL .. [[: "})]])	
						end
					end 
					
					InputBox:ClearFocus()
				end)
				Checkbox.OnValueChanged = function(self, state, val)
					if not tab.isUpdatingCheckboxes then 
						CheckboxsMakeUpdate()
					end 
				end
				Checkbox.Identify = { Type = "Checkbox", Toggle = db }		
				if thisTT then 
					StdUi:FrameTooltip(Checkbox, thisTT, nil, "TOP", true)
				end 
				return Checkbox
			end 
			
			local function TabUpdate()
				tab.isUpdating = true 
				ScrollTable:MakeUpdate()
				SliderMin:MakeUpdate()
				SliderMax:MakeUpdate()
				ValidateSliderColor()
				ConfigPanel:MakeUpdate()
				CheckboxsMakeUpdate()				
				tab.isUpdating = nil 			
			end 
			
			-- UI: Category
			Category = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 12, 30), themeHeight, {
				{ text = L["TAB"]["BLACKLIST"], 												value = "BlackList" 			},
				{ text = "[MainPvE] @target" .. (Action.IamHealer and "||targettarget" or ""), 	value = "MainPvE" 				},
				{ text = "[MainPvP] @target" .. (Action.IamHealer and "||targettarget" or ""), 	value = "MainPvP" 				},	
				{ text = "[MousePvE] @mouseover", 												value = "MousePvE" 				},	
				{ text = "[MousePvP] @mouseover", 												value = "MousePvP" 				},
				{ text = "[Heal] @arena1-5/ME:40", 												value = "Heal" 					},				
				{ text = "[PvP] @arena1-5/ME:40", 												value = "PvP" 					},
			}, "Main" .. (Action.IsInPvP and "PvP" or "PvE"))	
			Category.OnValueChanged = TabUpdate
			Category.text:SetJustifyH("CENTER")	
			TMW:Fire("TMW_ACTION_INTERRUPTS_UI_CREATE_CATEGORY", Category) -- Need for push custom options 
						
			-- UI: Scroll
			Scroll = setmetatable({
				OnClickCell = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
					if button == "LeftButton" then		
						if IsShiftKeyDown() then
							if not columnData.db then 
								local actionLink 
								if BindPadFrame and BindPadFrame:IsVisible() then 
									actionLink = rowData.Name
								else 
									actionLink = Action.GetSpellLink(rowData.ID)
								end 
								
								ChatEdit_InsertLink(actionLink)		
							end 
						else  								
							if columnData.db then 
								local category = Category:GetValue()
								tabDB[category][GameLocale][rowData.Name][columnData.db] = not tabDB[category][GameLocale][rowData.Name][columnData.db]
								
								local status = tabDB[category][GameLocale][rowData.Name][columnData.db] 
								if status then 
									rowData[columnData.index] = "ON"
								else 
									rowData[columnData.index] = "OFF"
								end 
								
								Action.Print(Action.GetSpellLink(rowData.ID) .. " " .. columnData.name .. ": " .. rowData[columnData.index])	
								table:ClearSelection()
							else 
								LuaEditor.EditBox:SetText(rowData.LUA or "")
								if rowData.LUA and rowData.LUA ~= "" then 
									LuaButton.FontStringLUA:SetText(themeON)
								else 
									LuaButton.FontStringLUA:SetText(themeOFF)
								end 
									
								InputBox:SetNumber(rowData.ID)
								InputBox.val = rowData.ID 														
							end 							
						end												
					elseif button == "RightButton" then 
						local macroName 
						local category = Category:GetValue()
						
						if IsShiftKeyDown() then
							if columnData.db then
								-- Make macro to set exact same current ceil data and set opposite for others ceils (only booleans)								
								local spellDB = tabDB[category][GameLocale][rowData.Name]
								macroName = category .. ";" .. rowData.ID .. ";opposite;" .. columnData.db
								Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. category .. [[", "]] .. category .. [[;]] .. rowData.Name .. [[:"}, {]] .. GameLocale .. [[ = {]] .. [[["]] .. rowData.Name .. [["] = {Enabled = true, ]] .. columnData.db .. [[ = ]] .. Action.toStr[spellDB[columnData.db]] .. [[}}}, true)]], true)
							else 
								-- Make macro to set opposite current row data (only booleans)
								macroName = category .. ";" .. rowData.ID .. ";opposite"
								Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. category .. [[", "]] .. category .. [[;]] .. rowData.Name .. [[:"}, {]] .. GameLocale .. [[ = {]] .. [[["]] .. rowData.Name .. [["] = {Enabled = true}}}, true)]], true)
							end 
						elseif columnData.db then
							-- Make macro to set exact same current ceil data
							local spellDB = tabDB[category][GameLocale][rowData.Name]
							macroName = category .. ";" .. rowData.ID .. ";" .. columnData.db
							Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. category .. [[", "]] .. category .. [[;]] .. rowData.Name .. [[:"}, {]] .. GameLocale .. [[ = {]] .. [[["]] .. rowData.Name .. [["] = {]] .. columnData.db .. [[ = ]] .. Action.toStr[spellDB[columnData.db]] .. [[}}})]], true)
						else 
							-- Make macro to set exact same current row data
							local spellDB = tabDB[category][GameLocale][rowData.Name]
							macroName = category .. ";" .. rowData.ID
							Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. category .. [[", "]] .. category .. [[;]] .. rowData.Name .. [[:"}, {]] .. GameLocale .. [[ = {]] .. [[["]] .. rowData.Name .. [["] = { useKick = ]] .. Action.toStr[spellDB.useKick] .. [[, useCC = ]] .. Action.toStr[spellDB.useCC] .. [[, useRacial = ]] .. Action.toStr[spellDB.useRacial] .. [[}}})]], true)								
						end 
					end 	
					
					InputBox:ClearFocus()						
				end,
				OnClickHeader = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						table.SORTBY = columnIndex						
					end	
					
					InputBox:ClearFocus()	
				end, 
				ColorON 				= { r = 0, g = 1, b = 0, a = 1 },
				ColorOFF 				= { r = 1, g = 0, b = 0, a = 1 },
			}, { __index = function(t, v) return t.Table[v] end })
			Scroll.Table = StdUi:ScrollTable(anchor, {
                {
                    name = L["TAB"][tabName]["ID"],
                    width = 60,
                    align = "LEFT",
                    index = "ID",
                    format = "number",  
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"]["ROWCREATEMACRO"])       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = Scroll.OnClickCell,
					},
                },
                {
                    name = L["TAB"][tabName]["NAME"],
                    width = 172,
					defaultwidth = 172,
					defaultSort = "dsc",
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"]["ROWCREATEMACRO"])       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = Scroll.OnClickCell,
					},
                },
                {
                    name = L["TAB"][tabName]["USEKICK"],
                    width = 65,
                    align = "CENTER",
                    index = "useKickIndex",
					db = "useKick",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return Scroll.ColorON
                        end
                        if value == "OFF" then
                            return Scroll.ColorOFF
                        end
                    end,
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"]["CEILCREATEMACRO"]:format(rowData[columnData.index], columnData.name, rowData[columnData.index], columnData.name))       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = Scroll.OnClickCell,
					},
                },
				{
                    name = L["TAB"][tabName]["USECC"],
                    width = 65,
                    align = "CENTER",
                    index = "useCCIndex",
					db = "useCC",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return Scroll.ColorON
                        end
                        if value == "OFF" then
                            return Scroll.ColorOFF
                        end
                    end,
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"]["CEILCREATEMACRO"]:format(rowData[columnData.index], columnData.name, rowData[columnData.index], columnData.name))       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = Scroll.OnClickCell,
					},
                },
				{
                    name = L["TAB"][tabName]["USERACIAL"],
                    width = 65,
                    align = "CENTER",
                    index = "useRacialIndex",
					db = "useRacial",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return Scroll.ColorON
                        end
                        if value == "OFF" then
                            return Scroll.ColorOFF
                        end
                    end,
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"]["CEILCREATEMACRO"]:format(rowData[columnData.index], columnData.name, rowData[columnData.index], columnData.name))       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = Scroll.OnClickCell,
					},
                },
				{
                    name = L["TAB"][tabName]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, rowData.ID, "Spell")       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = Scroll.OnClickCell,
                    },
                },
            }, 10, 25)	
			ScrollTable = Scroll.Table
			ScrollTable:RegisterEvents(nil, { OnClick = Scroll.OnClickHeader })
			ScrollTable.SORTBY = 2
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)	
			ScrollTable:SetScript("OnShow", TabUpdate) 
			ScrollTable.MakeUpdate = function()		
				if not anchor:IsShown() then -- anchor here because it's scroll child and methods :IsVisible and :IsShown can skip it in theory 
					return 
				end 
				
				local self = ScrollTable
				if not self.Data then 
					self.Data = {}
				else 
					wipe(self.Data)
				end 
				
				local category = Category:GetValue()
				for spellName, v in pairs(tabDB[category][GameLocale]) do 
					if v.Enabled then 
						local useKickIndex, useCCIndex, useRacialIndex = v.useKick, v.useCC, v.useRacial
						useKickIndex 	= useKickIndex 		and "ON" or "OFF"
						useCCIndex 		= useCCIndex 		and "ON" or "OFF"
						useRacialIndex 	= useRacialIndex 	and "ON" or "OFF"
						tinsert(self.Data, setmetatable({ 									
							Name 			= spellName,
							Icon 			= (select(3, Action.GetSpellInfo(v.ID))),	
							useKickIndex 	= useKickIndex,
							useCCIndex 		= useCCIndex,
							useRacialIndex 	= useRacialIndex,
						}, { __index = v }))
					end 
				end
				
				self:ClearSelection()			
				self:SetData(self.Data)
				self:SortData(self.SORTBY)
			end
			TMW:RegisterCallback("TMW_ACTION_INTERRUPTS_UI_UPDATE", ScrollTable.MakeUpdate)	-- Fired from SetToggle for 'Category'		
			
			-- UI: SliderMin
			SliderMin = StdUi:Slider(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, tabDB[Category:GetValue()][GameLocale].Min or 0, false, 0, 99)							
			SliderMin.OnValueChanged = function(self, value)
				if not tab.isUpdating then 
					if not self.isDisabled then 
						local category = Category:GetValue()
						if tabDB[category].Min then 
							tabDB[category].Min = value
							self.FontStringTitle:SetText(L["TAB"][tabName]["MIN"] .. "|cff00ff00" .. value .. "%|r")
							
							if value > SliderMax:GetValue() then 
								SliderMax:SetValue(value)
							end 
							
							ValidateSliderColor()
						end 												
					else 
						self:SetValue(0)
						self.FontStringTitle:SetText(L["TAB"][tabName]["MIN"] .. "|cffff0000OFF|r")
					end 
					
					InputBox:ClearFocus()
				end 
			end
			SliderMin.MakeUpdate = function(self)
				local category  = Category:GetValue()
				local value 	= tabDB[category].Min 
				
				if value then 
					self.isDisabled = false 
					self:SetValue(value)
					self.FontStringTitle:SetText(L["TAB"][tabName]["MIN"] .. "|cff00ff00" .. value .. "%|r")
				else
					self.isDisabled = true 
					self:SetValue(0)
					self.FontStringTitle:SetText(L["TAB"][tabName]["MIN"] .. "|cffff0000OFF|r")
				end 								
			end 
			StdUi:FrameTooltip(SliderMin, L["TAB"][tabName]["SLIDERTOOLTIP"], nil, "BOTTOM", true)	
			SliderMin.FontStringTitle = StdUi:Subtitle(anchor, L["TAB"][tabName]["MIN"] .. "|cff00ff00" .. SliderMin:GetValue() .. "%|r")
			StdUi:GlueAbove(SliderMin.FontStringTitle, SliderMin)
			
			-- UI: SliderMax
			SliderMax = StdUi:Slider(anchor, StdUi:GetWidthByColumn(anchor, 6), themeHeight, tabDB[Category:GetValue()][GameLocale].Max or 0, false, 0, 99)							
			SliderMax.OnValueChanged = function(self, value)
				if not tab.isUpdating then 
					if not self.isDisabled then  
						local category = Category:GetValue()
						if tabDB[category].Max then 
							tabDB[category].Max = value
							self.FontStringTitle:SetText(L["TAB"][tabName]["MAX"] .. "|cff00ff00" .. value .. "%|r")
							
							if value < SliderMin:GetValue() then 
								SliderMin:SetValue(value)
							end 
							
							ValidateSliderColor()
						end 
					else 
						self:SetValue(0)
						self.FontStringTitle:SetText(L["TAB"][tabName]["MAX"] .. "|cffff0000OFF|r")
					end 
					
					InputBox:ClearFocus()
				end 
			end
			SliderMax.MakeUpdate = function(self)
				local category 	= Category:GetValue()
				local value 	= tabDB[category].Max
				
				if value then 
					self.isDisabled = false 
					self:SetValue(value)
					self.FontStringTitle:SetText(L["TAB"][tabName]["MAX"] .. "|cff00ff00" .. value .. "%|r")
				else
					self.isDisabled = true 
					self:SetValue(0)
					self.FontStringTitle:SetText(L["TAB"][tabName]["MAX"] .. "|cffff0000OFF|r")
				end 								
			end 
			StdUi:FrameTooltip(SliderMax, L["TAB"][tabName]["SLIDERTOOLTIP"], nil, "BOTTOM", true)	
			SliderMax.FontStringTitle = StdUi:Subtitle(anchor, L["TAB"][tabName]["MAX"] .. "|cff00ff00" .. SliderMax:GetValue() .. "%|r")
			StdUi:GlueAbove(SliderMax.FontStringTitle, SliderMax)
			
			-- UI: Checkboxs
			UseMain 		= CreateCheckbox("UseMain")
			MainAuto 		= CreateCheckbox("MainAuto")
			UseMouse 		= CreateCheckbox("UseMouse")
			MouseAuto 		= CreateCheckbox("MouseAuto")
			UseHeal 		= CreateCheckbox("UseHeal")
			HealOnlyHealers = CreateCheckbox("HealOnlyHealers")
			UsePvP 			= CreateCheckbox("UsePvP")
			PvPOnlySmart 	= CreateCheckbox("PvPOnlySmart")		
			
			-- UI: ConfigPanel
			ConfigPanel = StdUi:PanelWithTitle(anchor, StdUi:GetWidthByColumn(anchor, 12, 30), themeHeight * 2 + 10, L["TAB"]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(12)
			ConfigPanel.MakeUpdate = function(self)
				ResetButton:Click()
			end 
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { padding = { top = 50 } })
			
			-- UI: ResetButton
			ResetButton = StdUi:Button(anchor, 70, themeHeight, L["RESET"])
			ResetButton:SetScript("OnClick", function(self, button, down)
				InputBox:ClearFocus()
				InputBox:SetText("")
				InputBox.val = ""
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(themeOFF)
			end)
			StdUi:GlueTop(ResetButton, ConfigPanel, 0, 0, "LEFT")	

			-- UI: LuaButton
			LuaButton = StdUi:Button(anchor, 50, themeHeight, "LUA")
			LuaButton.FontStringLUA = StdUi:Subtitle(LuaButton, themeOFF)
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)
			
			-- UI: LuaEditor
			LuaEditor = StdUi:CreateLuaEditor(anchor, L["TAB"]["LUAWINDOW"], MainUI.default_w, MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(themeON)
				else 
					LuaButton.FontStringLUA:SetText(themeOFF)
				end 
			end)
											
			-- UI: InputBox
			InputBox = StdUi:SearchEditBox(anchor, StdUi:GetWidthByColumn(ConfigPanel, 12), 20, L["TAB"][tabName]["SEARCH"])
			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetNumber()
				if text == 0 then 
					text = self:GetText()
				end 
				
				if text ~= nil and text ~= "" then					
					if type(text) == "number" then 
						self.val = text					
						if self.val > 9999999 then 						
							self.val = ""
							self:SetText(self.val)							
							Action.Print(L["DEBUG"] .. L["TAB"][tabName]["INTEGERERROR"]) 
							return 
						end 
						StdUi:ShowTooltip(self, true, self.val, "Spell") 
					else 
						StdUi:ShowTooltip(self, false)
						Action.TimerSetRefreshAble("ConvertSpellNameToID", 1, function() 
							self.val = Action.ConvertSpellNameToID(text)
							StdUi:ShowTooltip(self, true, self.val, "Spell") 							
						end)
					end 					
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.val = ""
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
					StdUi:ShowTooltip(self, false)
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function(self)
                StdUi:ShowTooltip(self, false)
				Add:Click()                
            end)
			InputBox:SetScript("OnEscapePressed", function(self)
                StdUi:ShowTooltip(self, false)
				self.val = ""
				self:SetText("")
				self:ClearFocus() 
            end)			
			InputBox:HookScript("OnHide", function(self)
				StdUi:ShowTooltip(self, false)
			end)
			InputBox.val = ""
			InputBox.FontStringTitle = StdUi:Subtitle(InputBox, L["TAB"][tabName]["INPUTBOXTITLE"])			
			StdUi:FrameTooltip(InputBox, L["TAB"][tabName]["INPUTBOXTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	

			-- UI: How
			How = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 12), 25, {				
				{ text = L["TAB"]["GLOBAL"], 	value = "GLOBAL" 	},				
				{ text = L["TAB"]["ALLSPECS"], 	value = "ALLSPECS" 	},
			}, "ALLSPECS")
			How:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
			How.text:SetJustifyH("CENTER")	
			How.FontStringTitle = StdUi:Subtitle(How, L["TAB"]["HOW"])
			StdUi:FrameTooltip(How, L["TAB"]["HOWTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(How.FontStringTitle, How)					
			
			-- UI: Add 
			Add = StdUi:Button(anchor, InputBox:GetWidth(), 25, L["TAB"][tabName]["ADD"])
			Add:SetScript("OnClick", function(self, button, down)	
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				
				local spellID 	= InputBox.val
				local spellName = Action.GetSpellInfo(spellID)	
				if not spellID or not spellName or spellName == "" or spellID <= 1 then 
					Action.Print(L["TAB"][tabName]["ADDERROR"]) 
				else 
					local category 	= Category:GetValue()
					local codeLua 	= LuaEditor.EditBox:GetText()
					if codeLua == "" then 
						codeLua = nil 
					end 
					
					local index = ScrollTable:GetSelection()	
					local data  = index and ScrollTable:GetRow(index)	
					local useKick, useCC, useRacial = true, true, true 
					if data then 
						useKick, useCC, useRacial = data.useKick, data.useCC, data.useRacial
					end 
					local howTo = How:GetValue()					
					if howTo == "GLOBAL" then 
						for _, profile in pairs(TMWdb.profiles) do 
							if profile.ActionDB and profile.ActionDB[tabName] and profile.ActionDB[tabName][category] and profile.ActionDB[tabName][category][GameLocale] then 	
								profile.ActionDB[tabName][category][GameLocale][spellName] = { Enabled = true, ID = spellID, Name = spellName, LUA = codeLua, useKick = useKick, useCC = useCC, useRacial = useRacial }
							end 
						end 					
					elseif howTo == "ALLSPECS" then 
						tabDB[category][GameLocale][spellName] = { Enabled = true, ID = spellID, Name = spellName, LUA = codeLua, useKick = useKick, useCC = useCC, useRacial = useRacial }
					end 			

					ScrollTable:MakeUpdate()	
					ResetButton:Click()
				end 
			end)          
            StdUi:FrameTooltip(Add, L["TAB"][tabName]["ADDTOOLTIP"], nil, "TOPRIGHT", true)
			
			-- UI: Remove 
			Remove = StdUi:Button(anchor, InputBox:GetWidth(), 25, L["TAB"][tabName]["REMOVE"])	
			Remove:SetScript("OnClick", function(self, button, down)
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local category 	= Category:GetValue()
					local data 		= ScrollTable:GetRow(index)									
					local howTo 	= How:GetValue()
					if howTo == "GLOBAL" then 
						for _, profile in pairs(TMWdb.profiles) do 
							if profile.ActionDB and profile.ActionDB[tabName] and profile.ActionDB[tabName][category] and profile.ActionDB[tabName][category][GameLocale] then 
								if StdUi.Factory[tabName][category][GameLocale][data.ID] and profile.ActionDB[tabName][category][GameLocale][data.Name] then 
									profile.ActionDB[tabName][category][GameLocale][data.Name].Enabled = false
								else 
									profile.ActionDB[tabName][category][GameLocale][data.Name] = nil
								end 														
							end 
						end 
					elseif howTo == "ALLSPECS" then 
						if StdUi.Factory[tabName][category][GameLocale][data.ID] then 
							tabDB[category][GameLocale][data.Name].Enabled = false
						else 
							tabDB[category][GameLocale][data.Name] = nil
						end 	
					end 
					
					ScrollTable:MakeUpdate()
					ResetButton:Click()
				end 
			end)           
            StdUi:FrameTooltip(Remove, L["TAB"][tabName]["REMOVETOOLTIP"], nil, "TOPLEFT", true)				
						
			anchor:AddRow({ margin = { top = 10, left = -15, right = -15 } }):AddElement(Category)
			anchor:AddRow({ margin = { top = 15, left = -15, right = -15 } }):AddElement(ScrollTable)
			anchor:AddRow({ margin = { top = 0, left = -15, right = -15 } }):AddElements(SliderMin, SliderMax, { column = "even" })
			anchor:AddRow({ margin = { top = -5, left = -15, right = -15 } }):AddElements(UseMain, UseMouse, UseHeal, UsePvP, { column = "even" })
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(MainAuto, MouseAuto, HealOnlyHealers, PvPOnlySmart, { column = "even" })
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)
			ConfigPanel:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()		
			anchor:AddRow({ margin = { left = -15, right = -15 } }):AddElement(How)
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			anchor:DoLayout()
			
			-- If we had return back to this tab then handler will be skipped 
			if MainUI.RememberTab == tabName then 
				TabUpdate()
			end 
		end 
		
		if tabName == 5 then 	
			UI_Title:SetText(L["TAB"][tabName]["HEADTITLE"])
			UI_Title:SetFontSize(13)		
			StdUi:EasyLayout(anchor, { padding = { top = 10 } })
			
			local ActionDataAuras = ActionData.Auras
			local function GetCategory()
				local cct = {		
					{ text = L["TAB"]["BLACKLIST"], value = "BlackList" },
					{ text = L["TAB"][tabName]["POISON"], value = "Poison" },				
					{ text = L["TAB"][tabName]["DISEASE"], value = "Disease" },
					{ text = L["TAB"][tabName]["CURSE"], value = "Curse" },				
					{ text = L["TAB"][tabName]["MAGIC"], value = "Magic" },
					{ text = L["TAB"][tabName]["MAGICMOVEMENT"], value = "MagicMovement" },				
					{ text = L["TAB"][tabName]["PURGEFRIENDLY"], value = "PurgeFriendly" },
					{ text = L["TAB"][tabName]["PURGEHIGH"], value = "PurgeHigh" },				
					{ text = L["TAB"][tabName]["PURGELOW"], value = "PurgeLow" },
					{ text = L["TAB"][tabName]["ENRAGE"], value = "Enrage" },				
					{ text = L["TAB"][tabName]["BLEEDS"], value = "Bleeds" },				
				}
				if Action.PlayerClass == "PALADIN" then 
					tinsert(cct, { text = L["TAB"][tabName]["BLESSINGOFPROTECTION"], value = "BlessingofProtection" })
					tinsert(cct, { text = L["TAB"][tabName]["BLESSINGOFFREEDOM"], value = "BlessingofFreedom" })
					tinsert(cct, { text = L["TAB"][tabName]["BLESSINGOFSACRIFICE"], value = "BlessingofSacrifice" })
					tinsert(cct, { text = L["TAB"][tabName]["BLESSINGOFSANCTUARY"], value = "BlessingofSanctuary" })
				end 
				return cct
			end 
			
			local UsePanel = StdUi:PanelWithTitle(anchor, anchor:GetWidth() - 30, 43, L["TAB"][tabName]["USETITLE"])
			UsePanel.titlePanel.label:SetFontSize(13)
			UsePanel.titlePanel.label:SetTextColor(UI_Title:GetTextColor())
			StdUi:GlueTop(UsePanel.titlePanel, UsePanel, 0, -2)
			StdUi:EasyLayout(UsePanel, { gutter = 0, padding = { top = UsePanel.titlePanel.label:GetHeight() + 10 } })			
			local UseDispel = StdUi:Checkbox(anchor, L["TAB"][tabName]["USEDISPEL"])
			local UsePurge = StdUi:Checkbox(anchor, L["TAB"][tabName]["USEPURGE"])	
			local UseExpelEnrage = StdUi:Checkbox(anchor, L["TAB"][tabName]["USEEXPELENRAGE"])
			local Mode = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6, 15), themeHeight, {				
				{ text = "PvE", value = "PvE" },				
				{ text = "PvP", value = "PvP" },
			}, Action.IsInPvP and "PvP" or "PvE")	
			local Category = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6, 15), themeHeight, GetCategory(), "Magic")	
			TMW:Fire("TMW_ACTION_AURAS_UI_CREATE_CATEGORY", Category) -- Need for push custom options 
			local ConfigPanel = StdUi:PanelWithTitle(anchor, StdUi:GetWidthByColumn(anchor, 12, 30), 140, L["TAB"][tabName]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(14)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { gutter = 0, padding = { top = 40 } })
			local ResetConfigPanel = StdUi:Button(anchor, 70, themeHeight, L["RESET"])
			local LuaButton = StdUi:Button(anchor, 50, themeHeight, "LUA")
			LuaButton.FontStringLUA = StdUi:Subtitle(LuaButton, themeOFF)
			local LuaEditor = StdUi:CreateLuaEditor(anchor, L["TAB"]["LUAWINDOW"], MainUI.default_w, MainUI.default_h, L["TAB"]["LUATOOLTIP"])
			local Role = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(ConfigPanel, 4), 25, {				
				{ text = L["TAB"][tabName]["ANY"], value = "ANY" },				
				{ text = L["TAB"][tabName]["HEALER"], value = "HEALER" },
				{ text = L["TAB"][tabName]["DAMAGER"], value = "DAMAGER" },
			}, "ANY")
			local Duration = StdUi:EditBox(anchor, StdUi:GetWidthByColumn(ConfigPanel, 4), 25, 0)
			local Stack = StdUi:NumericBox(anchor, StdUi:GetWidthByColumn(ConfigPanel, 4), 25, 0)			
			local ByID = StdUi:Checkbox(anchor, L["TAB"][tabName]["BYID"])
			local canStealOrPurge = StdUi:Checkbox(anchor, L["TAB"][tabName]["CANSTEALORPURGE"])	
			local onlyBear = StdUi:Checkbox(anchor, L["TAB"][tabName]["ONLYBEAR"])	
			local InputBox = StdUi:SearchEditBox(anchor, StdUi:GetWidthByColumn(ConfigPanel, 12, 15), 20, L["TAB"][4]["SEARCH"])						
			local Add = StdUi:Button(anchor, StdUi:GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tabName]["ADD"])
			local Remove = StdUi:Button(anchor, StdUi:GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tabName]["REMOVE"])

			local function ClearAllEditBox(clearInput)
				if clearInput then 
					InputBox:SetText("")
				end
				InputBox:ClearFocus()
				Duration:ClearFocus()
				Stack:ClearFocus()
			end 
			
			-- [ScrollTable] BEGIN			
			local function ShowCellTooltip(parent, show, data)
				if show == "Hide" then 
					GameTooltip:Hide()
				else 
					GameTooltip:SetOwner(parent)				
					if show == "Role" then
						GameTooltip:SetText(L["TAB"][tabName]["ROLETOOLTIP"], StdUi.config.font.color.yellow.r, StdUi.config.font.color.yellow.g, StdUi.config.font.color.yellow.b, 1, true)
					elseif show == "Dur" then 
						GameTooltip:SetText(L["TAB"][tabName]["DURATIONTOOLTIP"], StdUi.config.font.color.yellow.r, StdUi.config.font.color.yellow.g, StdUi.config.font.color.yellow.b, 1, true)
					elseif show == "Stack" then 
						GameTooltip:SetText(L["TAB"][tabName]["STACKSTOOLTIP"], StdUi.config.font.color.yellow.r, StdUi.config.font.color.yellow.g, StdUi.config.font.color.yellow.b, 1, true)					
					end 
				end
			end 
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then							
					if IsShiftKeyDown() then
						local actionLink 
						if BindPadFrame and BindPadFrame:IsVisible() then 
							actionLink = rowData.Name
						else 
							actionLink = Action.GetSpellLink(rowData.ID)
						end 
						
						ChatEdit_InsertLink(actionLink)				
					else  
						LuaEditor.EditBox:SetText(rowData.LUA or "")
						if rowData.LUA and rowData.LUA ~= "" then 
							LuaButton.FontStringLUA:SetText(themeON)
						else 
							LuaButton.FontStringLUA:SetText(themeOFF)
						end 
						
						Role:SetValue(rowData.Role)
						Duration:SetNumber(rowData.Dur)
						Stack:SetNumber(rowData.Stack)
						ByID:SetChecked(rowData.byID)
						canStealOrPurge:SetChecked(rowData.canStealOrPurge)
						onlyBear:SetChecked(rowData.onlyBear)
						InputBox:SetNumber(rowData.ID)					
						ClearAllEditBox()
					end 
				end 				
			end 			
			
			local ScrollTable = StdUi:ScrollTable(anchor, {
				{
                    name = L["TAB"][tabName]["ROLE"],
                    width = 70,
                    align = "LEFT",
                    index = "RoleLocale",
                    format = "string",
					events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowCellTooltip(cellFrame, "Role")   							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowCellTooltip(cellFrame, "Hide")    							
                        end,
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tabName]["ID"],
                    width = 60,
                    align = "LEFT",
                    index = "ID",
                    format = "number", 
					events = {                        
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tabName]["NAME"],
                    width = 167,
					defaultwidth = 167,
					defaultSort = "dsc",
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tabName]["DURATION"],
                    width = 80,
                    align = "LEFT",
                    index = "Dur",
                    format = "number",
					events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowCellTooltip(cellFrame, "Dur")   							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowCellTooltip(cellFrame, "Hide") 							
                        end,
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tabName]["STACKS"],
                    width = 50,
                    align = "LEFT",
                    index = "Stack",
                    format = "number", 
					events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            ShowCellTooltip(cellFrame, "Stack")      						
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            ShowCellTooltip(cellFrame, "Hide")  							
                        end,
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tabName]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, rowData.ID, "Spell")  							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)    						
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 10, 25)
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						ClearAllEditBox()	
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 3
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			StdUi:ClipScrollTableColumn(ScrollTable, 35)
			
			local function ScrollTableData()
				DispelPurgeEnrageRemap()
				local CategoryValue = Category:GetValue()
				local ModeValue = Mode:GetValue()
				local data = {}
				for k, v in pairs(ActionDataAuras[ModeValue][CategoryValue]) do 
					if v.Enabled then 
						v.Icon = select(3, Action.GetSpellInfo(v.ID))
						v.RoleLocale = L["TAB"][tabName][v.Role]
						tinsert(data, v)
					end 
				end
				return data
			end 
			local function ScrollTableUpdate()
				ClearAllEditBox(true)
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableData())					
				ScrollTable:SortData(ScrollTable.SORTBY)						
			end 						
			
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				ResetConfigPanel:Click()
			end)
			-- [ScrollTable] END 
			
			UseDispel:SetChecked(specDB.UseDispel)
			UseDispel:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseDispel:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						specDB.UseDispel = not specDB.UseDispel
						self:SetChecked(specDB.UseDispel)	
						Action.Print(L["TAB"][tabName]["USEDISPEL"] .. ": ", specDB.UseDispel)	
					elseif button == "RightButton" then 
						Action.CraftMacro(L["TAB"][tabName]["USEDISPEL"], [[/run Action.SetToggle({]] .. tabName .. [[, "UseDispel", "]] .. L["TAB"][tabName]["USEDISPEL"] .. [[: "})]])	
					end
				end 
			end)
			UseDispel.Identify = { Type = "Checkbox", Toggle = "UseDispel" }
			StdUi:FrameTooltip(UseDispel, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPRIGHT", true)	
	
			UsePurge:SetChecked(specDB.UsePurge)
			UsePurge:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UsePurge:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						specDB.UsePurge = not specDB.UsePurge
						self:SetChecked(specDB.UsePurge)	
						Action.Print(L["TAB"][tabName]["USEPURGE"] .. ": ", specDB.UsePurge)	
					elseif button == "RightButton" then 
						Action.CraftMacro(L["TAB"][tabName]["USEPURGE"], [[/run Action.SetToggle({]] .. tabName .. [[, "UsePurge", "]] .. L["TAB"][tabName]["USEPURGE"] .. [[: "})]])	
					end 
				end
			end)
			UsePurge.Identify = { Type = "Checkbox", Toggle = "UsePurge" }
			StdUi:FrameTooltip(UsePurge, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOP", true)	
			if not ActionDataAuras.DisableCheckboxes[specID] or ActionDataAuras.DisableCheckboxes[specID].UsePurge then 
				UsePurge:Disable()
			end 			

			UseExpelEnrage:SetChecked(specDB.UseExpelEnrage)
			UseExpelEnrage:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseExpelEnrage:SetScript("OnClick", function(self, button, down)	
				ClearAllEditBox()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						specDB.UseExpelEnrage = not specDB.UseExpelEnrage
						self:SetChecked(specDB.UseExpelEnrage)	
						Action.Print(L["TAB"][tabName]["USEEXPELENRAGE"] .. ": ", specDB.UseExpelEnrage)	
					elseif button == "RightButton" then 
						Action.CraftMacro(L["TAB"][tabName]["USEEXPELENRAGE"], [[/run Action.SetToggle({]] .. tabName .. [[, "UseExpelEnrage", "]] .. L["TAB"][tabName]["USEEXPELENRAGE"] .. [[: "})]])	
					end 
				end
			end)
			UseExpelEnrage.Identify = { Type = "Checkbox", Toggle = "UseExpelEnrage" }	
			StdUi:FrameTooltip(UseExpelEnrage, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)	
			if not ActionDataAuras.DisableCheckboxes[specID] or ActionDataAuras.DisableCheckboxes[specID].UseExpelEnrage then 
				UseExpelEnrage:Disable()
			end 
			
			Mode.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end	
			Mode.FontStringTitle = StdUi:Subtitle(Mode, L["TAB"][tabName]["MODE"])
			StdUi:GlueAbove(Mode.FontStringTitle, Mode)	
			Mode.text:SetJustifyH("CENTER")	
			Mode:HookScript("OnClick", ClearAllEditBox)
			
			Category.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end				
			Category.FontStringTitle = StdUi:Subtitle(Category, L["TAB"][tabName]["CATEGORY"])			
			StdUi:GlueAbove(Category.FontStringTitle, Category)	
			Category.text:SetJustifyH("CENTER")													
			Category:HookScript("OnClick", ClearAllEditBox)
								
			Role.text:SetJustifyH("CENTER")
			Role.FontStringTitle = StdUi:Subtitle(Role, L["TAB"][tabName]["ROLE"])
			Role:HookScript("OnClick", ClearAllEditBox)			
			StdUi:FrameTooltip(Role, L["TAB"][tabName]["ROLETOOLTIP"], nil, "TOPRIGHT", true)
			StdUi:GlueAbove(Role.FontStringTitle, Role)	
			
			Duration:SetJustifyH("CENTER")
			Duration:SetScript("OnEnterPressed", function(self)
                self:ClearFocus() 				
            end)
			Duration:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)
			Duration:SetScript("OnTextChanged", function(self)
				local val = self:GetText():gsub("[^%d%.]", "")
				self:SetNumber(val)
			end)
			Duration:SetScript("OnEditFocusLost", function(self)
				local text = self:GetText()				
				if text == nil or text == "" or not text:find("%d") or text:sub(1, 1) == "." or (text:len() > 1 and text:sub(1, 1) == "0" and not text:find("%.")) then 
					self:SetNumber(0)
				elseif text:sub(-1) == "." then 
					self:SetNumber(text:gsub("%.", ""))
				end 
			end)
			local Font = strgsub(strgsub(L["TAB"][tabName]["DURATION"], "\n", ""), "-", "")
			Duration.FontStringTitle = StdUi:Subtitle(Duration, Font)			
			StdUi:FrameTooltip(Duration, L["TAB"][tabName]["DURATIONTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(Duration.FontStringTitle, Duration)	
						
            Stack:SetMaxValue(1000)
            Stack:SetMinValue(0)
			Stack:SetJustifyH("CENTER")
			Stack:SetScript("OnEnterPressed", function(self)
                self:ClearFocus() 				
            end)
			Stack:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)
			Stack:SetScript("OnEditFocusLost", function(self)
				local text = self:GetText()	
				if text == nil or text == "" then 
					self:SetNumber(0)
				end 
			end)
			local Font = strgsub(L["TAB"][tabName]["STACKS"], "\n", "")
			Stack.FontStringTitle = StdUi:Subtitle(Stack, Font)			
			StdUi:FrameTooltip(Stack, L["TAB"][tabName]["STACKSTOOLTIP"], nil, "TOPLEFT", true)
			StdUi:GlueAbove(Stack.FontStringTitle, Stack)						
													
			StdUi:FrameTooltip(ByID, L["TAB"][tabName]["BYIDTOOLTIP"], nil, "BOTTOMRIGHT", true)	
			ByID:HookScript("OnClick", ClearAllEditBox)	
			
			canStealOrPurge:HookScript("OnClick", ClearAllEditBox)						
			onlyBear:HookScript("OnClick", ClearAllEditBox)
			
			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetNumber()
				if text == 0 then 
					text = self:GetText()
				end 
				
				if text ~= nil and text ~= "" then					
					if type(text) == "number" then 
						self.val = text					
						if self.val > 9999999 then 						
							self.val = ""						
							self:SetText(self.val)							
							Action.Print(L["DEBUG"] .. L["TAB"][4]["INTEGERERROR"]) 
							return 
						end 
						StdUi:ShowTooltip(self, true, self.val, "Spell") 
					else 
						StdUi:ShowTooltip(self, false)
						Action.TimerSetRefreshAble("ConvertSpellNameToID", 1, function() 
							self.val = Action.ConvertSpellNameToID(text)
							StdUi:ShowTooltip(self, true, self.val, "Spell") 							
						end)
					end 					
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.val = ""
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
					StdUi:ShowTooltip(self, false)
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function(self)
                StdUi:ShowTooltip(self, false)
				Add:Click()				              
            end)
			InputBox:SetScript("OnEscapePressed", function(self)
                StdUi:ShowTooltip(self, false)
				InputBox:ClearFocus()
            end)
			InputBox:HookScript("OnHide", function(self)
				StdUi:ShowTooltip(self, false)
			end)
			InputBox.val = ""
			InputBox.FontStringTitle = StdUi:Subtitle(InputBox, L["TAB"][4]["INPUTBOXTITLE"])			
			StdUi:FrameTooltip(InputBox, L["TAB"][4]["INPUTBOXTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	
			
			Add:SetScript("OnClick", function(self, button, down)
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				local SpellID = InputBox.val
				local Name = Action.GetSpellInfo(SpellID)	
				if not SpellID or Name == nil or Name == "" or SpellID <= 1 then 
					Action.Print(L["TAB"][4]["ADDERROR"]) 
				else
					local M = Mode:GetValue()
					local C = Category:GetValue()
					local CodeLua = LuaEditor.EditBox:GetText()
					if CodeLua == "" then 
						CodeLua = nil 
					end 
					-- Prevent overwrite by next time loading if user applied own changes 
					local LUAVER 
					if gActionDB[tabName][M][C][SpellID] then 
						LUAVER = gActionDB[tabName][M][C][SpellID].LUAVER 
					end 
									
					gActionDB[tabName][M][C][SpellID] = { 
						ID = SpellID, 
						Name = Name, 
						enabled = true,
						role = Role:GetValue(),
						dur = round(Action.toNum[Duration:GetNumber()], 3) or 0,
						stack = Stack:GetNumber() or 0,
						byID = ByID:GetChecked(),
						canStealOrPurge = canStealOrPurge:GetChecked(),
						onlyBear = onlyBear:GetChecked(),
						LUA = CodeLua,
						LUAVER = LUAVER,
					}
					ScrollTableUpdate()						
				end 
			end)         
            StdUi:FrameTooltip(Add, L["TAB"][4]["ADDTOOLTIP"], nil, "TOPRIGHT", true)		

			Remove:SetScript("OnClick", function(self, button, down)
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)	
					if StdUi.GlobalFactory[tabName][Mode:GetValue()][Category:GetValue()][data.ID] then 
						gActionDB[tabName][Mode:GetValue()][Category:GetValue()][data.ID].enabled = false						
					else 
						gActionDB[tabName][Mode:GetValue()][Category:GetValue()][data.ID] = nil
					end 					
					ScrollTableUpdate()					
				end 
			end)            
            StdUi:FrameTooltip(Remove, L["TAB"][4]["REMOVETOOLTIP"], nil, "TOPLEFT", true)							          
				
			anchor:AddRow({ margin = { top = -4, left = -15, right = -15 } }):AddElement(UsePanel)	
			UsePanel:AddRow({ margin = { top = -7 } }):AddElements(UseDispel, UsePurge, UseExpelEnrage, { column = "even" })
			UsePanel:DoLayout()	
			anchor:AddRow({ margin = { top = -10 } }):AddElement(UI_Title)			
			anchor:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElements(Mode, Category, { column = "even" })			
			anchor:AddRow({ margin = { top = 13, left = -15, right = -15 } }):AddElement(ScrollTable)
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)
			ConfigPanel:AddRow():AddElements(Role, Duration, Stack, { column = "even" })						
			ConfigPanel:AddRow({ margin = { top = -10 } }):AddElements(ByID, canStealOrPurge, onlyBear, { column = "even" })
			ConfigPanel:AddRow({ margin = { top = 5 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()							
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			anchor:DoLayout()				
			UI_Title:SetJustifyH("CENTER")
			
			ResetConfigPanel:SetScript("OnClick", function()
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(themeOFF)
				Role:SetValue("ANY")
				Duration:SetNumber(0)
				Stack:SetNumber(0)
				ByID:SetChecked(false)
				canStealOrPurge:SetChecked(false)
				onlyBear:SetChecked(false)
				InputBox.val = ""
				InputBox:SetText("")					
				ClearAllEditBox()
			end)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(themeON)
				else 
					LuaButton.FontStringLUA:SetText(themeOFF)
				end 
			end)
			
			-- If we had return back to this tab then handler will be skipped 
			if MainUI.RememberTab == tabName then 
				ScrollTableUpdate()
			end			
		end 
		
		if tabName == 6 then 	
			UI_Title:SetText(L["TAB"][tabName]["HEADTITLE"])
			StdUi:GlueTop(UI_Title, anchor, 0, -5)			
			StdUi:EasyLayout(anchor, { padding = { top = 20 } })
			
			local UsePanel = StdUi:PanelWithTitle(anchor, anchor:GetWidth() - 30, 50, L["TAB"][tabName]["USETITLE"])
			UsePanel.titlePanel.label:SetFontSize(14)
			UsePanel.titlePanel.label:SetTextColor(UI_Title:GetTextColor())
			StdUi:GlueTop(UsePanel.titlePanel, UsePanel, 0, -5)
			StdUi:EasyLayout(UsePanel, { gutter = 0, padding = { top = UsePanel.titlePanel.label:GetHeight() + 10 } })			
			local UseLeft = StdUi:Checkbox(anchor, L["TAB"][tabName]["USELEFT"])
			local UseRight = StdUi:Checkbox(anchor, L["TAB"][tabName]["USERIGHT"])
			local Mode = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6, 15), themeHeight, {				
				{ text = "PvE", value = "PvE" },				
				{ text = "PvP", value = "PvP" },
			}, Action.IsInPvP and "PvP" or "PvE")	
			local Category = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6, 15), themeHeight, {				
				{ text = "UnitName", 				value = "UnitName" },				
				{ text = "GameToolTip: Objects", 	value = "GameToolTip" },
				{ text = "GameToolTip: UI", 		value = "UI" },
			}, "UnitName")	
			TMW:Fire("TMW_ACTION_CURSOR_UI_CREATE_CATEGORY", Category) -- Need for push custom options 
			local ConfigPanel = StdUi:PanelWithTitle(anchor, StdUi:GetWidthByColumn(anchor, 12, 30), 95, L["TAB"]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(14)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { padding = { top = 50 } })
			local ResetConfigPanel = StdUi:Button(anchor, 70, themeHeight, L["RESET"])
			local LuaButton = StdUi:Button(anchor, 50, themeHeight, "LUA")
			LuaButton.FontStringLUA = StdUi:Subtitle(LuaButton, themeOFF)
			local LuaEditor = StdUi:CreateLuaEditor(anchor, L["TAB"]["LUAWINDOW"], MainUI.default_w, MainUI.default_h, L["TAB"][tabName]["LUATOOLTIP"])
			local Button = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(ConfigPanel, 4), 25, {				
				{ text = L["TAB"][tabName]["LEFT"], value = "LEFT" },				
				{ text = L["TAB"][tabName]["RIGHT"], value = "RIGHT" },		
			}, "LEFT")
			local isTotem = StdUi:Checkbox(anchor, L["TAB"][tabName]["ISTOTEM"])				
			local InputBox = StdUi:SearchEditBox(anchor, StdUi:GetWidthByColumn(ConfigPanel, 12), 20, L["TAB"][tabName]["INPUT"])		
			local How = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 12), 25, {				
				{ text = L["TAB"]["GLOBAL"], value = "GLOBAL" },				
				{ text = L["TAB"]["ALLSPECS"], value = "ALLSPECS" },
				{ text = L["TAB"]["THISSPEC"], value = "THISSPEC" },
			}, "THISSPEC")	
			local Add = StdUi:Button(anchor, StdUi:GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tabName]["ADD"])
			local Remove = StdUi:Button(anchor, StdUi:GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][tabName]["REMOVE"])
			
			-- [ScrollTable] BEGIN			
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(themeON)
					else 
						LuaButton.FontStringLUA:SetText(themeOFF)
					end 
					Button:SetValue(rowData.Button)
					isTotem:SetChecked(rowData.isTotem)
					InputBox:SetText(rowData.Name)	
					InputBox:ClearFocus()
				end 				
			end 			
			
			local ScrollTable = StdUi:ScrollTable(anchor, {
				{
                    name = L["TAB"][tabName]["BUTTON"],
                    width = 120,
                    align = "LEFT",
                    index = "ButtonLocale",
                    format = "string",
					events = {
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tabName]["NAME"],
                    width = 357,
					defaultwidth = 357,
					defaultSort = "dsc",
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
            }, 12, 20)
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						InputBox:ClearFocus()
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 2
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			
			local cacheData = {}
			local function ScrollTableData()
				isTotem:SetChecked(false)
				local CategoryValue = Category:GetValue()								
				local ModeValue = Mode:GetValue()
				wipe(cacheData)
				for k, v in pairs(specDB[ModeValue][CategoryValue][GameLocale]) do 
					if v.Enabled then 
						tinsert(cacheData, setmetatable({ 
								Name = k, 				
								ButtonLocale = L["TAB"][tabName][v.Button],
							}, { __index = v }))
					end 
				end			
				return cacheData
			end 
			local function ScrollTableUpdate()
				InputBox:ClearFocus()
				InputBox:SetText("")
				InputBox.val = ""
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableData())					
				ScrollTable:SortData(ScrollTable.SORTBY)						
			end 						
			
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				ResetConfigPanel:Click()
			end)
			-- [ScrollTable] END 
			
			UseLeft:SetChecked(specDB.UseLeft)
			UseLeft:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseLeft:SetScript("OnClick", function(self, button, down)	
				InputBox:ClearFocus()				
				if button == "LeftButton" then 
					specDB.UseLeft = not specDB.UseLeft
					self:SetChecked(specDB.UseLeft)	
					Action.Print(L["TAB"][tabName]["USELEFT"] .. ": ", specDB.UseLeft)	
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["USELEFT"], [[/run Action.SetToggle({]] .. tabName .. [[, "UseLeft", "]] .. L["TAB"][tabName]["USELEFT"] .. [[: "})]])	
				end				
			end)
			UseLeft.Identify = { Type = "Checkbox", Toggle = "UseLeft" }
			StdUi:FrameTooltip(UseLeft, L["TAB"][tabName]["USELEFTTOOLTIP"], nil, "TOPRIGHT", true)
			
			UseRight:SetChecked(specDB.UseRight)
			UseRight:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			UseRight:SetScript("OnClick", function(self, button, down)	
				InputBox:ClearFocus()				
				if button == "LeftButton" then 
					specDB.UseRight = not specDB.UseRight
					self:SetChecked(specDB.UseRight)	
					Action.Print(L["TAB"][tabName]["USERIGHT"] .. ": ", specDB.UseRight)	
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["USERIGHT"], [[/run Action.SetToggle({]] .. tabName .. [[, "UseRight", "]] .. L["TAB"][tabName]["USERIGHT"] .. [[: "})]])	
				end				
			end)
			UseRight.Identify = { Type = "Checkbox", Toggle = "UseRight" }
			StdUi:FrameTooltip(UseRight, L["TAB"]["RIGHTCLICKCREATEMACRO"], nil, "TOPLEFT", true)
			
			Mode.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end	
			Mode.FontStringTitle = StdUi:Subtitle(Mode, L["TAB"][5]["MODE"])
			StdUi:GlueAbove(Mode.FontStringTitle, Mode)	
			Mode.text:SetJustifyH("CENTER")	
			Mode:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
			
			Category.OnValueChanged = function(self, val)   
				ScrollTableUpdate()							
			end				
			Category.FontStringTitle = StdUi:Subtitle(Category, L["TAB"][5]["CATEGORY"])			
			StdUi:GlueAbove(Category.FontStringTitle, Category)	
			Category.text:SetJustifyH("CENTER")													
			Category:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
								
			Button.text:SetJustifyH("CENTER")
			Button:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)			
			
			StdUi:FrameTooltip(isTotem, L["TAB"][tabName]["ISTOTEMTOOLTIP"], nil, "BOTTOMLEFT", true)	
			isTotem:HookScript("OnClick", function(self)
				if not self.isDisabled then 
					InputBox:ClearFocus()
				end 
			end)	
			
			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetText()
				
				if text ~= nil and text ~= "" then										
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			InputBox:SetScript("OnEscapePressed", function()
				InputBox:ClearFocus()
			end)
			InputBox.FontStringTitle = StdUi:Subtitle(InputBox, L["TAB"][tabName]["INPUTTITLE"])			
			StdUi:FrameTooltip(InputBox, L["TAB"][4]["INPUTBOXTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	
			
			How.text:SetJustifyH("CENTER")	
			How.FontStringTitle = StdUi:Subtitle(How, L["TAB"]["HOW"])
			StdUi:FrameTooltip(How, L["TAB"]["HOWTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(How.FontStringTitle, How)	
			How:HookScript("OnClick", function()
				InputBox:ClearFocus()
			end)
			
			Add:SetScript("OnClick", function(self, button, down)
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				local Name = InputBox:GetText()
				if Name == nil or Name == "" then 
					Action.Print(L["TAB"][tabName]["INPUTTITLE"]) 
				else					
					Name = Name:lower()
					local M = Mode:GetValue()
					local C = Category:GetValue()					
					local CodeLua = LuaEditor.EditBox:GetText()
					if CodeLua == "" then 
						CodeLua = nil 
					end 
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMWdb.profiles) do 
							if profile.ActionDB and profile.ActionDB[tabName] then 
								for SPEC_ID in pairs(profile.ActionDB[tabName]) do
									-- Prevent overwrite by next time loading if user applied own changes 
									local LUAVER 
									if profile.ActionDB[tabName][SPEC_ID][M][C][GameLocale][Name] then 
										LUAVER = profile.ActionDB[tabName][SPEC_ID][M][C][GameLocale][Name].LUAVER 
									end 
									
									profile.ActionDB[tabName][SPEC_ID][M][C][GameLocale][Name] = { 
										Enabled = true,
										Button = Button:GetValue(),
										isTotem = isTotem:GetChecked(),
										LUA = CodeLua,
										LUAVER = LUAVER,
									}
								end 
							end 
						end 					
					elseif HowTo == "ALLSPECS" then 
						for SPEC_ID in pairs(tabDB) do 
							-- Prevent overwrite by next time loading if user applied own changes 
							local LUAVER 
							if tabDB[SPEC_ID][M][C][GameLocale][Name] then 
								LUAVER = tabDB[SPEC_ID][M][C][GameLocale][Name].LUAVER 
							end 
									
							tabDB[SPEC_ID][M][C][GameLocale][Name] = { 
								Enabled = true,
								Button = Button:GetValue(),
								isTotem = isTotem:GetChecked(),
								LUA = CodeLua,
								LUAVER = LUAVER,
							}
						end 
					else 
						-- Prevent overwrite by next time loading if user applied own changes 
						local LUAVER 
						if specDB[M][C][GameLocale][Name] then 
							LUAVER = specDB[M][C][GameLocale][Name].LUAVER 
						end 
							
						specDB[M][C][GameLocale][Name] = { 
							Enabled = true,
							Button = Button:GetValue(),
							isTotem = isTotem:GetChecked(),
							LUA = CodeLua,
							LUAVER = LUAVER,
						}
					end 
					ScrollTableUpdate()						
				end 
			end)         	

			Remove:SetScript("OnClick", function(self, button, down)
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					local Name = data.Name
					local M = Mode:GetValue()
					local C = Category:GetValue()	
					local HowTo = How:GetValue()
					if HowTo == "GLOBAL" then 
						for _, profile in pairs(TMWdb.profiles) do 
							if profile.ActionDB and profile.ActionDB[tabName] then 
								for SPEC_ID in pairs(profile.ActionDB[tabName]) do
									if profile.ActionDB[tabName][SPEC_ID] and profile.ActionDB[tabName][SPEC_ID][M] and profile.ActionDB[tabName][SPEC_ID][M][C] and profile.ActionDB[tabName][SPEC_ID][M][C][GameLocale] then 
										if StdUi.Factory[tabName].PLAYERSPEC[M][C][GameLocale][Name] and profile.ActionDB[tabName][SPEC_ID][M][C][GameLocale][Name] then 
											profile.ActionDB[tabName][SPEC_ID][M][C][GameLocale][Name].Enabled = false
										else 
											profile.ActionDB[tabName][SPEC_ID][M][C][GameLocale][Name] = nil
										end 
									end 
								end 
							end 
						end 					  
					elseif HowTo == "ALLSPECS" then
						for SPEC_ID in pairs(tabDB) do 
							if StdUi.Factory[tabName].PLAYERSPEC[M][C][GameLocale][Name] and tabDB[SPEC_ID][M][C][GameLocale][Name] then 
								tabDB[SPEC_ID][M][C][GameLocale][Name].Enabled = false 
							else 
								tabDB[SPEC_ID][M][C][GameLocale][Name] = nil
							end 
						end 
					else 
						if StdUi.Factory[tabName].PLAYERSPEC[M][C][GameLocale][Name] and specDB[M][C][GameLocale][Name] then 
							specDB[M][C][GameLocale][Name].Enabled = false
						else 
							specDB[M][C][GameLocale][Name] = nil
						end 
					end 
					ScrollTableUpdate()					
				end 
			end)            							          
				
			anchor:AddRow({ margin = { left = -15, right = -15 } }):AddElement(UsePanel)	
			UsePanel:AddRow():AddElements(UseLeft, UseRight, { column = "even" })
			UsePanel:DoLayout()						
			anchor:AddRow({ margin = { top = 5, left = -15, right = -15 } }):AddElements(Mode, Category, { column = "even" })			
			anchor:AddRow({ margin = { top = 5, left = -15, right = -15 } }):AddElement(ScrollTable)
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)						
			ConfigPanel:AddRow({ margin = { top = -20, left = -15, right = -15 } }):AddElements(Button, isTotem, { column = "even" })
			ConfigPanel:AddRow({ margin = { left = -15, right = -15 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()							
			anchor:AddRow({ margin = { left = -15, right = -15 } }):AddElement(How)
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			anchor:DoLayout()				
			
			ResetConfigPanel:SetScript("OnClick", function()
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(themeOFF)
				isTotem:SetChecked(false)
				InputBox:SetText("")					
				InputBox:ClearFocus()
			end)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(themeON)
				else 
					LuaButton.FontStringLUA:SetText(themeOFF)
				end 
			end)	

			-- If we had return back to this tab then handler will be skipped 
			if MainUI.RememberTab == tabName then 
				ScrollTableUpdate()
			end			
		end 
		
		if tabName == 7 then 
			if not Action[specID] then -- specID is Action.PlayerClass if Classic or Action.PlayerSpec if Retail
				UI_Title:SetText(L["TAB"]["NOTHING"])
				return 
			end 		
			UI_Title:SetText(L["TAB"][tabName]["HEADTITLE"])
			StdUi:GlueTop(UI_Title, anchor, 0, -5)			
			StdUi:EasyLayout(anchor, { padding = { top = 20 } })
			
			local UsePanel = StdUi:PanelWithTitle(anchor, anchor:GetWidth() - 30, 50, L["TAB"][tabName]["USETITLE"])
			UsePanel.titlePanel.label:SetFontSize(14)
			UsePanel.titlePanel.label:SetTextColor(UI_Title:GetTextColor())
			StdUi:GlueTop(UsePanel.titlePanel, UsePanel, 0, 0)
			StdUi:EasyLayout(UsePanel, { padding = { top = UsePanel.titlePanel.label:GetHeight() + 10 } })			
			local Channels
			local DisableReToggle = StdUi:Checkbox(anchor, L["TAB"][tabName]["DISABLERETOGGLE"])
			local ScrollTable 
			local Macro = StdUi:SimpleEditBox(anchor, StdUi:GetWidthByColumn(anchor, 12), 20, "")	
			local ConfigPanel = StdUi:PanelWithTitle(anchor, StdUi:GetWidthByColumn(anchor, 12, 30), 100, L["TAB"]["CONFIGPANEL"])	
			ConfigPanel.titlePanel.label:SetFontSize(13)
			StdUi:GlueTop(ConfigPanel.titlePanel, ConfigPanel, 0, -5)
			StdUi:EasyLayout(ConfigPanel, { padding = { top = 50 } })
			local ResetConfigPanel = StdUi:Button(anchor, 70, themeHeight, L["RESET"])
			local LuaButton = StdUi:Button(anchor, 50, themeHeight, "LUA")
			LuaButton.FontStringLUA = StdUi:Subtitle(LuaButton, themeOFF)
			local LuaEditor = StdUi:CreateLuaEditor(anchor, L["TAB"]["LUAWINDOW"], MainUI.default_w, MainUI.default_h, L["TAB"]["LUATOOLTIP"])						
			local Key = StdUi:SimpleEditBox(anchor, StdUi:GetWidthByColumn(ConfigPanel, 6), 20, "") 
			local Source = StdUi:SimpleEditBox(anchor, StdUi:GetWidthByColumn(ConfigPanel, 6), 20, "") 
			local InputBox = StdUi:SearchEditBox(anchor, StdUi:GetWidthByColumn(ConfigPanel, 12), 20, L["TAB"][tabName]["INPUT"])			
			local Add = StdUi:Button(anchor, StdUi:GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][6]["ADD"])
			local Remove = StdUi:Button(anchor, StdUi:GetWidthByColumn(ConfigPanel, 6), 25, L["TAB"][6]["REMOVE"])
			
			-- [ScrollTable] BEGIN			
			local function OnClickCell(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
				if button == "LeftButton" then		
					LuaEditor.EditBox:SetText(rowData.LUA or "")
					if rowData.LUA and rowData.LUA ~= "" then 
						LuaButton.FontStringLUA:SetText(themeON)
					else 
						LuaButton.FontStringLUA:SetText(themeOFF)
					end 
					Macro:GetScript("OnTextChanged")(Macro, true, rowData, rowIndex)
					Macro:ClearFocus()										
					Key:SetText(rowData.Key)
					Key:ClearFocus()
					Source:SetText(rowData.Source or "")
					Source:ClearFocus()
					InputBox:SetText(rowData.Name)	
					InputBox:ClearFocus()
				end 				
			end 
			ScrollTable = StdUi:ScrollTable(anchor, {
				{
                    name = L["TAB"][tabName]["KEY"],
                    width = 100,
                    align = "LEFT",
                    index = "Key",
                    format = "string",
					events = {
						OnClick = OnClickCell,
                    },
                },
                {
                    name = L["TAB"][tabName]["NAME"],
                    width = 207,
					defaultwidth = 207,
					defaultSort = "dsc",
                    align = "LEFT",
                    index = "Name",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tabName]["WHOSAID"],
                    width = 120,
                    align = "LEFT",
                    index = "Source",
                    format = "string",
					events = {                        
						OnClick = OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tabName]["ICON"],
                    width = 50,
                    align = "LEFT",
                    index = "Icon",
                    format = "icon",
                    sortable = false,
                    events = {
                        OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, rowData.ID, rowData.Type)  							
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)    						
                        end,
						OnClick = OnClickCell,
                    },
                },
            }, 14, 20)			
			local headerEvents = {
				OnClick = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						ScrollTable.SORTBY = columnIndex
						Macro:ClearFocus()					
						Key:ClearFocus()
						Source:ClearFocus()
						InputBox:ClearFocus()						
					end	
				end, 
			}
			ScrollTable:RegisterEvents(nil, headerEvents)
			ScrollTable.SORTBY = 2
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			
			local cacheData = {}
			local function ScrollTableData()
				wipe(cacheData)
				for k, v in pairs(specDB.msgList) do 
					if v.Enabled then 
						if Action[specID][v.Key] then 
							tinsert(cacheData, setmetatable({
								Enabled = v.Enabled,
								Key = v.Key,
								Source = v.Source or "",
								LUA = v.LUA,
								Name = k, 								
								Icon = (Action[specID][v.Key]:Icon()),
							}, { __index = Action[specID][v.Key] }))
						else 
							v = nil 
						end 
					end 
				end			
				return cacheData
			end 
			local function ScrollTableUpdate()
				Macro:ClearFocus()				
				Key:ClearFocus()
				Source:ClearFocus()
				InputBox:ClearFocus()				
				ScrollTable:ClearSelection()			
				ScrollTable:SetData(ScrollTableData())					
				ScrollTable:SortData(ScrollTable.SORTBY)						
			end 						
			
			ScrollTable:SetScript("OnShow", function()
				ScrollTableUpdate()
				ResetConfigPanel:Click()
			end)			
			-- [ScrollTable] END
			
			Channels = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(anchor, 6), 20, {
				{ text = "/w", value = 1 },
				{ text = "/party", value = 2 },
				{ text = "/raid", value = 3 },
			}, nil, true, true)
			Channels:SetPlaceholder(" -- " .. L["TAB"][tabName]["CHANNELS"] .. " -- ") 	
			for i, v in ipairs(Channels.optsFrame.scrollChild.items) do 
				v:SetChecked(specDB.Channels[i])
			end			
			Channels.OnValueChanged = function(self, value)			
				for i, v in ipairs(self.optsFrame.scrollChild.items) do 					
					if specDB.Channels[i] ~= v:GetChecked() then
						specDB.Channels[i] = v:GetChecked()
						Action.Print(L["TAB"][tabName]["CHANNEL"] .. self.options[i].text .. ": ", specDB.Channels[i])
						Macro:GetScript("OnTextChanged")(Macro)
						DisableReToggle:GetScript("OnShow")(DisableReToggle)
						MSG:Initialize()
					end 				
				end 				
			end				
			Channels:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Channels:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["MSG"], [[/run Action.ToggleMSG()]])	
				end
			end)		
			Channels.Identify = { Type = "Dropdown", Toggle = "Channels" }			
			Channels.FontStringTitle = StdUi:Subtitle(Channels, L["TAB"][tabName]["CHANNELS"])
			StdUi:FrameTooltip(Channels, L["TAB"][tabName]["MSGTOOLTIP"], nil, "TOPLEFT", true)
			StdUi:GlueAbove(Channels.FontStringTitle, Channels)
			Channels.text:SetJustifyH("CENTER")				
			
			DisableReToggle:SetChecked(specDB.DisableReToggle)
			DisableReToggle:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			DisableReToggle:SetScript("OnClick", function(self, button, down)	
				Macro:ClearFocus()	
				Key:ClearFocus()
				Source:ClearFocus()				
				InputBox:ClearFocus()
				if not self.isDisabled then 
					if button == "LeftButton" then 
						specDB.DisableReToggle = not specDB.DisableReToggle
						self:SetChecked(specDB.DisableReToggle)	
						Action.Print(L["TAB"][tabName]["DISABLERETOGGLE"] .. ": ", specDB.DisableReToggle)	
					elseif button == "RightButton" then 
						Action.CraftMacro(L["TAB"][tabName]["DISABLERETOGGLE"], [[/run Action.SetToggle({]] .. tabName .. [[, "DisableReToggle", "]] .. L["TAB"][tabName]["DISABLERETOGGLE"] .. [[: "})]])	
					end		
				end 
			end)
			DisableReToggle.Identify = { Type = "Checkbox", Toggle = "DisableReToggle" }
			StdUi:FrameTooltip(DisableReToggle, L["TAB"][tabName]["DISABLERETOGGLETOOLTIP"], nil, "TOPLEFT", true)
			DisableReToggle:SetScript("OnShow", function(self) 
				if not MSG:IsEnabled() then 
					self:Disable()
				else 
					self:Enable()
				end 
			end)
			if not MSG:IsEnabled() then 
				DisableReToggle:Disable()
			end 
			
			Macro:SetScript("OnTextChanged", function(self, userInput, rowData, rowIndex)
				local index = rowIndex or ScrollTable:GetSelection()				
				if not index then 
					return
				else 
					local rowData = rowData or ScrollTable:GetRow(index)					
					if rowData then 
						local slashText
						local items = Channels.optsFrame.scrollChild.items
						local options = Channels.options
						if items[1]:GetChecked() then 
							slashText = "/w " .. A_Unit("player"):Name() .. " "					
						else
							for i = 2, #items do 
								if items[i]:GetChecked() then 
									slashText = options[i].text .. " "
									break
								end
							end 
						end 				
						local thisname = rowData.Name and slashText and slashText .. rowData.Name or ""
						if thisname ~= self:GetText() then 
							self:SetText(thisname)
						end 
					end 
				end 
            end)
			Macro:SetScript("OnEnterPressed", function(self)
                self:ClearFocus()                
            end)
			Macro:SetScript("OnEscapePressed", function(self)
				self:ClearFocus() 
            end)				
			Macro.Identify = { Type = "EditBox", Toggle = "Macro" } -- just to passthrough for Action.ToggleMSG to make Macro:GetScript("OnTextChanged")(Macro)
			Macro:SetJustifyH("CENTER")
			Macro.FontString = StdUi:Subtitle(Macro, L["TAB"][tabName]["MACRO"])
			StdUi:GlueAbove(Macro.FontString, Macro) 
			StdUi:FrameTooltip(Macro, L["TAB"][tabName]["MACROTOOLTIP"], nil, "TOP", true)			
			
			Key:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			Key:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
			end)
			Key:SetJustifyH("CENTER")
			Key.FontString = StdUi:Subtitle(Key, L["TAB"][tabName]["KEY"])
			StdUi:GlueAbove(Key.FontString, Key)	
			StdUi:FrameTooltip(Key, L["TAB"][tabName]["KEYTOOLTIP"], nil, "TOPRIGHT", true)	

			Source:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			Source:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
			end)
			Source:SetJustifyH("CENTER")
			Source.FontString = StdUi:Subtitle(Source, L["TAB"][tabName]["SOURCE"])
			StdUi:GlueAbove(Source.FontString, Source)	
			StdUi:FrameTooltip(Source, L["TAB"][tabName]["SOURCETOOLTIP"], nil, "TOPLEFT", true)

			InputBox:SetScript("OnTextChanged", function(self)
				local text = self:GetText()
				
				if text ~= nil and text ~= "" then										
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
				end 
            end)
			InputBox:SetScript("OnEnterPressed", function() 
				Add:Click()
			end)
			InputBox:SetScript("OnEscapePressed", function(self)
				self:ClearFocus()
			end)
			InputBox.FontStringTitle = StdUi:Subtitle(InputBox, L["TAB"][tabName]["INPUTTITLE"])						
			StdUi:GlueAbove(InputBox.FontStringTitle, InputBox)	
			StdUi:FrameTooltip(InputBox, L["TAB"][tabName]["INPUTTOOLTIP"], nil, "TOP", true)			
			
			Add:SetScript("OnClick", function(self, button, down)		
				if LuaEditor:IsShown() then
					Action.Print(L["TAB"]["CLOSELUABEFOREADD"])
					return 
				elseif LuaEditor.EditBox.LuaErrors then 
					Action.Print(L["TAB"]["FIXLUABEFOREADD"])
					return 
				end 
				
				local Name = InputBox:GetText()
				if Name == nil or Name == "" then 
					Action.Print(L["TAB"][tabName]["INPUTERROR"]) 
					return 
				end 
				
				local TableKey = Key:GetText()
				if TableKey == nil or TableKey == "" then 
					Action.Print(L["TAB"][tabName]["KEYERROR"]) 
					return 
				elseif not Action[specID][TableKey] then 
					Action.Print(TableKey .. " " .. L["TAB"][tabName]["KEYERRORNOEXIST"]) 
					return 
				end 				
			
				Name = Name:lower()	
				for k, v in pairs(specDB.msgList) do 
					if v.Enabled and Name:match(k) and Name ~= k then 
						Action.Print(Name .. " " .. L["TAB"][tabName]["MATCHERROR"]) 
						return 
					end
				end 
				
				local SourceName = Source:GetText()
				if SourceName == "" then 
					SourceName = nil
				end 				
				
				local CodeLua = LuaEditor.EditBox:GetText()
				if CodeLua == "" then 
					CodeLua = nil 
				end 
				
				-- Prevent overwrite by next time loading if user applied own changes 
				local LUAVER 
				if specDB.msgList[Name] then 
					LUAVER = specDB.msgList[Name].LUAVER
				end 

				specDB.msgList[Name] = { 
					Enabled = true,
					Key = TableKey,
					Source = SourceName,
					LUA = CodeLua,
					LUAVER = LUAVER,
				}
 
				ScrollTableUpdate()										 
			end)         	

			Remove:SetScript("OnClick", function(self, button, down)		
				local index = ScrollTable:GetSelection()				
				if not index then 
					Action.Print(L["TAB"][3]["SELECTIONERROR"]) 
				else 
					local data = ScrollTable:GetRow(index)
					local Name = data.Name
					if ActionData.ProfileDB[tabName][specID].msgList[Name] then 
						specDB.msgList[Name].Enabled = false							
					else 
						specDB.msgList[Name] = nil	
					end 					
					ScrollTableUpdate()					
				end 
			end)            							          
				
			anchor:AddRow({ margin = { left = -15, right = -15 } }):AddElement(UsePanel)	
			UsePanel:AddRow({ margin = { left = -15, right = -15 } }):AddElements(Channels, DisableReToggle, { column = "even" })
			UsePanel:DoLayout()								
			anchor:AddRow({ margin = { top = 10, left = -15, right = -15 } }):AddElement(ScrollTable)
			anchor:AddRow({ margin = { left = -15, right = -15 } }):AddElement(Macro)
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(ConfigPanel)						
			ConfigPanel:AddRow({ margin = { top = -15, left = -15, right = -15 } }):AddElements(Key, Source, { column = "even" })
			ConfigPanel:AddRow({ margin = { left = -15, right = -15 } }):AddElement(InputBox)
			ConfigPanel:DoLayout()							
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElements(Add, Remove, { column = "even" })
			anchor:DoLayout()				
			
			ResetConfigPanel:SetScript("OnClick", function()
				Macro:SetText("")
				Macro:ClearFocus()	
				Key:SetText("")
				Key:ClearFocus()
				Source:SetText("")
				Source:ClearFocus()
				InputBox:SetText("")
				InputBox:ClearFocus()				
				LuaEditor.EditBox:SetText("")
				LuaButton.FontStringLUA:SetText(themeOFF)
			end)
			StdUi:GlueTop(ResetConfigPanel, ConfigPanel, 0, 0, "LEFT")
			
			LuaButton:SetScript("OnClick", function()
				if not LuaEditor:IsShown() then 
					LuaEditor:Show()
				else 
					LuaEditor.closeBtn:Click()
				end 
			end)
			StdUi:GlueTop(LuaButton, ConfigPanel, 0, 0, "RIGHT")
			StdUi:GlueLeft(LuaButton.FontStringLUA, LuaButton, -5, 0)

			LuaEditor:HookScript("OnHide", function(self)
				if self.EditBox:GetText() ~= "" then 
					LuaButton.FontStringLUA:SetText(themeON)
				else 
					LuaButton.FontStringLUA:SetText(themeOFF)
				end 
			end)

			-- If we had return back to this tab then handler will be skipped 
			if MainUI.RememberTab == tabName then 
				ScrollTableUpdate()
			end	
		end
		
		if tabName == 8 then 
			-- Fix StdUi 
			-- Lib has missed scrollframe as widget (need to have function GetChildrenWidgets)
			StdUi:InitWidget(anchor)		
			
			UI_Title:Hide()					
			StdUi:EasyLayout(anchor, { padding = { top = 2, left = 8, right = 8 + 20 } })
			
			local isHealer = true -- Since release of MetaEngine, all classes and specializations have HealingEngine API
			local 	isDemo = false -- Hides player name for demonstration 
			local 	PanelOptions,
						ResetOptions, HelpOptions,	-- Other roles available
						PredictOptions,				-- Other roles available
						SelectStopOptions, SelectSortMethod,
						AfterTargetEnemyOrBossDelay, AfterMouseoverEnemyDelay,
						HealingEngineAPI, SelectPets, SelectResurrects,
					PanelUnitIDs,
						UnitIDs, 
						AutoHide,
					PanelProfiles,
						ResetProfile, HelpProfile,
						Profile, 
						EditBoxProfile,
						SaveProfile, LoadProfile, RemoveProfile,
					PanelPriority,
						ResetPriority, HelpPriority,
						Multipliers,
						MultiplierIncomingDamageLimit, 	MultiplierThreat,
						MultiplierPetsInCombat, 		MultiplierPetsOutCombat,
						Offsets,
						OffsetMode,
						OffsetSelfFocused, 		OffsetSelfUnfocused, 	OffsetSelfDispel,
						OffsetHealers, 			OffsetTanks, 			OffsetDamagers,
						OffsetHealersDispel, 	OffsetTanksDispel, 		OffsetDamagersDispel,
						OffsetHealersShields, 	OffsetTanksShields, 	OffsetDamagersShields, 
						OffsetHealersHoTs, 		OffsetTanksHoTs, 		OffsetDamagersHoTs, 
						OffsetHealersUtils, 	OffsetTanksUtils, 		OffsetDamagersUtils,
					PanelManaManagement,
						ResetManaManagement, HelpManaManagement,
						ManaManagementManaBoss,
						ManaManagementStopAtHP, OR, ManaManagementStopAtTTD,
					HelpWindow, LuaEditor, 
					ScrollTable, 				-- Shortcut for UnitIDs.Table 
					PriorityResetWidgets,		-- Need for button ResetPriority	
					ResetManaManagementWidges	-- Need for button ResetManaManagement
			local columnEven, columnFour = { column = "even" }, { column = 4 }

			local function CreatePanel(title, gutter)
				local panel
				if title then 
					panel = StdUi:PanelWithTitle(anchor, StdUi:GetWidthByColumn(anchor, 12, 30), height or 1, title)	
					panel.titlePanel.label:SetFontSize(15)				
					StdUi:GlueTop(panel.titlePanel, panel, 0, -5)
				else 
					panel = StdUi:Panel(anchor, StdUi:GetWidthByColumn(anchor, 12, 30), height or 1)
				end 
				StdUi:EasyLayout(panel, { gutter = gutter, padding = { left = 0, right = 0, bottom = 5 } })

				-- Remap it to make resize able height and ignore for rows which aren't specified for healer 
				panel.DoLayout = function(self)
					if self.rows == nil then 
						return 
					end 
					
					-- Custom update kids of this panel to determine new total height
					MainUI.UpdateResizeForKids(self:GetChildrenWidgets())
					
					local l = self.layout;
					local width = self:GetWidth() - l.padding.left - l.padding.right;

					local y = -l.padding.top;
					for i = 1, #self.rows do
						local row = self.rows[i];
						y = y - row:DrawRow(width, y);
					end
					
					if not title or not self.hasConfiguredHeight then -- no title means what panel has ScrollTable which need to resize every time 
						self:SetHeight(-y)						 
						if not title then 
							self.hasConfiguredHeight = true 
						end 
					end
				end 
				
				return panel 
			end 
					
			local function CreateSliderAfter(db)
				local title = db:upper()
				local titleText = L["TAB"][tabName][title]
				local tooltipText = L["TAB"][tabName][title .. "TOOLTIP"] or L["TAB"][tabName]["CREATEMACRO"]
				
				local slider = StdUi:Slider(PanelOptions, StdUi:GetWidthByColumn(PanelOptions, 6), themeHeight, specDB[db], false, 0, 600)
				slider:SetScript("OnMouseUp", function(self, button, down)
					if button == "RightButton" then 
						local macroName = titleText:gsub("\n", " ")
						Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. db .. [[", "]] .. macroName .. [[: "}, ]] .. specDB[db] .. [[)]], true)
					end					
				end)		
				slider.Identify = { Type = "Slider", Toggle = db }					
				slider.MakeTextUpdate = function(self, value)
					if value <= 0 then 
						self.FontStringTitle:SetText(titleText .. ": |cffff0000OFF|r")
					else 
						self.FontStringTitle:SetText(titleText .. ": |cff00ff00" .. value .. "|r")
					end  
				end 
				slider.OnValueChanged = function(self, value)
					specDB[db] = value
					self:MakeTextUpdate(value)
					TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
				end								
				slider.FontStringTitle = StdUi:Subtitle(PanelOptions, "")
				slider.FontStringTitle:SetJustifyH("CENTER")
				slider:MakeTextUpdate(specDB[db])				
				StdUi:GlueAbove(slider.FontStringTitle, slider)
				if tooltipText then 
					StdUi:FrameTooltip(slider, tooltipText, nil, "BOTTOM", true)	
				end 
				return slider
			end 
			
			local function CreateCheckbox(parent, db, useMacro, useCallback)
				local title = db:upper()
				local titleText = L["TAB"][tabName][title]
				local tooltipText = L["TAB"][tabName][title .. "TOOLTIP"] or L["TAB"][tabName]["CREATEMACRO"]
				
				local checkbox = StdUi:Checkbox(parent, titleText, 250)
				checkbox:SetChecked(specDB[db])
				checkbox:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				checkbox:SetScript("OnClick", function(self, button, down)
					if not self.isDisabled then						
						if button == "LeftButton" then 
							specDB[db] = not specDB[db]	
							self:SetChecked(specDB[db])	
							if OnToggleHandler[tabName][db] then 
								OnToggleHandler[tabName][db](specDB)
							end
							Action.Print(titleText .. ": ", specDB[db])			
						elseif button == "RightButton" and useMacro then 
							Action.CraftMacro(titleText, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. db .. [[", "]] .. titleText .. [[: "})]], true)	
						end						
					end 
				end)			
				checkbox.OnValueChanged = function(self, state, val)	
					if useCallback then 
						ScrollTable:MakeUpdate()	
					end 
					TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
				end				 
				checkbox.Identify = { Type = "Checkbox", Toggle = db }	
				if tooltipText then 
					StdUi:FrameTooltip(checkbox, tooltipText, nil, "TOP", true)
				end 
				return checkbox			
			end 
			
			local function CreateSliderMultiplier(db)
				local title = db:upper()
				local titleText = L["TAB"][tabName][title]
				local tooltipText = L["TAB"][tabName][title .. "TOOLTIP"] or L["TAB"][tabName]["CREATEMACRO"]
				
				local slider = StdUi:Slider(PanelPriority, StdUi:GetWidthByColumn(PanelPriority, 6), themeHeight, specDB[db], false, 0.01, 2)
				slider:SetPrecision(2)
				slider:SetScript("OnMouseUp", function(self, button, down)
					if button == "RightButton" then 
						local macroName = titleText:gsub("\n", " ")
						Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. db .. [[", "]] .. macroName .. [[: "}, ]] .. specDB[db] .. [[)]], true)	
					end					
				end)		
				slider.Identify = { Type = "Slider", Toggle = db }					
				slider.MakeTextUpdate = function(self, value)
					self.FontStringTitle:SetText(titleText .. ": |cff00ff00" .. value .. "|r")
				end 
				slider.OnValueChanged = function(self, value)
					specDB[db] = value
					self:MakeTextUpdate(value)
					TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
				end								
				slider.FontStringTitle = StdUi:Subtitle(PanelPriority, "")
				slider.FontStringTitle:SetJustifyH("RIGHT")
				slider:MakeTextUpdate(specDB[db])				
				StdUi:GlueAbove(slider.FontStringTitle, slider, 0, 0, "RIGHT")
				if tooltipText then 
					StdUi:FrameTooltip(slider, tooltipText, nil, "BOTTOM", true)	
				end 
				return slider
			end 
			
			local function CreateSliderOffset(db)
				local title = db:upper()
				local titleText = L["TAB"][tabName][title]
				local tooltipText = L["TAB"][tabName][title .. "TOOLTIP"] or L["TAB"][tabName]["CREATEMACRO"]
				
				local slider = StdUi:Slider(PanelPriority, StdUi:GetWidthByColumn(PanelPriority, 6), themeHeight, specDB[db], false, -100, 100)
				slider:SetPrecision(0)
				slider:SetScript("OnMouseUp", function(self, button, down)
					if button == "RightButton" then 
						local macroName = titleText:gsub("\n", " ")
						Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. db .. [[", "]] .. macroName .. [[: "}, ]] .. specDB[db] .. [[)]], true)	
					end					
				end)		
				slider.Identify = { Type = "Slider", Toggle = db }					
				slider.MakeTextUpdate = function(self, value)
					if value == 0 then 
						self.FontStringTitle:SetText(titleText .. ": |cff00ff00AUTO|r")
					else 
						self.FontStringTitle:SetText(titleText .. ": |cff00ff00" .. value .. "|r")
					end  
				end 
				slider.OnValueChanged = function(self, value)
					if value >= -1 and value <= 1 then 
						self:SetPrecision(-1)
					else 
						self:SetPrecision(0)
					end 
					specDB[db] = value
					self:MakeTextUpdate(value)
					TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
				end								
				slider.FontStringTitle = StdUi:Subtitle(PanelPriority, "")
				slider.FontStringTitle:SetJustifyH("RIGHT")
				slider:MakeTextUpdate(specDB[db])				
				StdUi:GlueAbove(slider.FontStringTitle, slider, 0, 0, "RIGHT")
				if tooltipText then 
					StdUi:FrameTooltip(slider, tooltipText, nil, "BOTTOM", true)	
				end 
				return slider
			end 
			
			local function TabUpdate()
				if isHealer then 
					ScrollTable:MakeUpdate()			-- Refresh units 
					EditBoxProfile:ClearFocus()
				end 
			end 						
			
			-- UI: PanelOptions
			PanelOptions = CreatePanel(L["TAB"][tabName]["OPTIONSPANEL"])	
			
			-- UI: PanelOptions - ResetOptions
			ResetOptions = StdUi:Button(PanelOptions, 70, themeHeight, L["RESET"])		
			ResetOptions:SetScript("OnClick", function(self, button, down)
				local db 
				if StdUi.Factory[tabName].PLAYERSPEC then
					db = StdUi.Factory[tabName].PLAYERSPEC
				else 
					db = StdUi.Factory[tabName]
				end
				
				for k, v in pairs(db) do 										
					if k == "PredictOptions" and PredictOptions then 						
						local isChanged 
						for k1, v1 in ipairs(v) do 
							if PredictOptions.value[k1] ~= v1 then 
								PredictOptions.value[k1] = v1 	
								isChanged = true 
							end 
						end 
						
						if isChanged then 
							PredictOptions:SetValue(PredictOptions.value) 
							-- OnValueChanged will set specDB and make Action.Print
						end 
					end 
					
					if k == "SelectStopOptions" and SelectStopOptions then 
						local isChanged 
						for k1, v1 in ipairs(v) do 
							if SelectStopOptions.value[k1] ~= v1 then 
								SelectStopOptions.value[k1] = v1 	
								isChanged = true 
							end 
						end 
						
						if isChanged then 
							SelectStopOptions:SetValue(SelectStopOptions.value) 
							-- OnValueChanged will set specDB and make Action.Print
						end 						
					end 	
					
					if k == "SelectSortMethod" and SelectSortMethod then
						if SelectSortMethod:GetValue() ~= v then 
							SelectSortMethod:SetValue(v) 
							-- OnValueChanged will set specDB and make Action.Print 
						end 
					end 
					
					if k == "AfterTargetEnemyOrBossDelay" and AfterTargetEnemyOrBossDelay then 
						if AfterTargetEnemyOrBossDelay:GetValue() ~= v then 
							AfterTargetEnemyOrBossDelay:SetValue(v) 
							-- OnValueChanged will set specDB
							Action.Print(L["TAB"][tabName][k:upper()]:gsub("\n", " ") .. ": ", AfterTargetEnemyOrBossDelay.FontStringTitle:GetText())	
						end 
					end 
					
					if k == "AfterMouseoverEnemyDelay" and AfterMouseoverEnemyDelay then 
						if AfterMouseoverEnemyDelay:GetValue() ~= v then 
							AfterMouseoverEnemyDelay:SetValue(v) 
							-- OnValueChanged will set specDB
							Action.Print(L["TAB"][tabName][k:upper()]:gsub("\n", " ") .. ": ", AfterMouseoverEnemyDelay.FontStringTitle:GetText())	
						end 
					end 
					
					if k == "HealingEngineAPI" and HealingEngineAPI then 
						if HealingEngineAPI:GetChecked() ~= v then 
							HealingEngineAPI:SetChecked(v)
							specDB[k] = v 
							Action.Print(L["TAB"][tabName][k:upper()] .. ": ", specDB[k])	
						end 
					end 
					
					if k == "SelectPets" and SelectPets then 
						if SelectPets:GetChecked() ~= v then 
							SelectPets:SetChecked(v)
							specDB[k] = v 
							Action.Print(L["TAB"][tabName][k:upper()] .. ": ", specDB[k])	
						end 
					end 
					
					if k == "SelectResurrects" and SelectResurrects then 
						if SelectResurrects:GetChecked() ~= v then 
							SelectResurrects:SetChecked(v)
							specDB[k] = v 
							Action.Print(L["TAB"][tabName][k:upper()] .. ": ", specDB[k])
						end 
					end 
				end 
			end)
			StdUi:GlueTop(ResetOptions, PanelOptions, 0, 0, "LEFT")			
			StdUi:ApplyBackdrop(ResetOptions, "panel", "border")
			
			-- UI: PanelOptions - HelpOptions
			HelpOptions = StdUi:Button(PanelOptions, 70, themeHeight, L["TAB"][tabName]["HELP"]) 
			HelpOptions:SetScript("OnClick", function(self, button, down)
				HelpWindow:Open(L["TAB"][tabName]["OPTIONSPANELHELP"])
			end)
			StdUi:GlueTop(HelpOptions, PanelOptions, 0, 0, "RIGHT")	
			StdUi:ApplyBackdrop(HelpOptions, "panel", "border")
			
			-- UI: PanelOptions - PredictOptions
			PredictOptions = StdUi:Dropdown(PanelOptions, StdUi:GetWidthByColumn(PanelOptions, 12), themeHeight, {
				{ text = L["TAB"][tabName]["INCOMINGHEAL"], 		value = 1 },
				{ text = L["TAB"][tabName]["INCOMINGDAMAGE"], 		value = 2 },
				{ text = L["TAB"][tabName]["THREATMENT"], 			value = 3 },
				{ text = L["TAB"][tabName]["SELFHOTS"], 			value = 4 },
				{ text = L["TAB"][tabName]["ABSORBPOSSITIVE"], 		value = 5 },
				{ text = L["TAB"][tabName]["ABSORBNEGATIVE"], 		value = 6 },
			}, nil, true, true)
			PredictOptions:SetPlaceholder(L["TAB"][tabName]["SELECTOPTIONS"]) 	
			for i, v in ipairs(PredictOptions.optsFrame.scrollChild.items) do 
				v:SetChecked(specDB.PredictOptions[i])
			end			
			PredictOptions.OnValueChanged = function(self, value)	
				local isChanged
				for i, v in ipairs(self.optsFrame.scrollChild.items) do 
					if specDB.PredictOptions[i] ~= v:GetChecked() then 
						specDB.PredictOptions[i] = v:GetChecked()
						Action.Print(L["TAB"][tabName]["PREDICTOPTIONS"] .. ": " .. self.options[i].text .. " = ", specDB.PredictOptions[i])
						isChanged = true 
					end 
				end 
				
				if isChanged then 
					TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
				end 
			end				
			PredictOptions:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			PredictOptions:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["PREDICTOPTIONS"], [[/run Action.SetToggle({]] .. tabName .. [[, "PredictOptions", "]] .. L["TAB"][tabName]["PREDICTOPTIONS"] .. [[:"})]], true)	
				end
			end)		
			PredictOptions.Identify = { Type = "Dropdown", Toggle = "PredictOptions" }			
			PredictOptions.FontStringTitle = StdUi:Subtitle(PredictOptions, L["TAB"][tabName]["PREDICTOPTIONS"])
			StdUi:FrameTooltip(PredictOptions, L["TAB"][tabName]["PREDICTOPTIONSTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(PredictOptions.FontStringTitle, PredictOptions)
			PredictOptions.text:SetJustifyH("CENTER")		
			
			-- UI: PanelOptions - SelectStopOptions
		if isHealer then -- isHealer START
			SelectStopOptions = StdUi:Dropdown(PanelOptions, StdUi:GetWidthByColumn(PanelOptions, 6), themeHeight, {
				{ text = L["TAB"][tabName]["SELECTSTOPOPTIONS1"], 		value = 1 },
				{ text = L["TAB"][tabName]["SELECTSTOPOPTIONS2"], 		value = 2 },
				{ text = L["TAB"][tabName]["SELECTSTOPOPTIONS3"], 		value = 3 },
				{ text = L["TAB"][tabName]["SELECTSTOPOPTIONS4"], 		value = 4 },
				{ text = L["TAB"][tabName]["SELECTSTOPOPTIONS5"], 		value = 5 },
				{ text = L["TAB"][tabName]["SELECTSTOPOPTIONS6"], 		value = 6 },
			}, nil, true, true)
			SelectStopOptions:SetPlaceholder(L["TAB"][tabName]["SELECTOPTIONS"]) 				
			for i, v in ipairs(SelectStopOptions.optsFrame.scrollChild.items) do 
				v:SetChecked(specDB.SelectStopOptions[i])
			end	
			SelectStopOptions.OnValueChanged = function(self, value)
				local isChanged
				for i, v in ipairs(self.optsFrame.scrollChild.items) do 
					if specDB.SelectStopOptions[i] ~= v:GetChecked() then 
						specDB.SelectStopOptions[i] = v:GetChecked() 
						Action.Print(L["TAB"][tabName]["SELECTSTOPOPTIONS"] .. ": " .. self.options[i].text .. " = ", specDB.SelectStopOptions[i])
						isChanged = true 
					end 
				end 

				if isChanged then 
					TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
				end 
			end				
			SelectStopOptions:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			SelectStopOptions:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["SELECTSTOPOPTIONS"], [[/run Action.SetToggle({]] .. tabName .. [[, "SelectStopOptions", "]] .. L["TAB"][tabName]["SELECTSTOPOPTIONS"] .. [[:"})]], true)	
				end
			end)		
			SelectStopOptions.Identify = { Type = "Dropdown", Toggle = "SelectStopOptions" }			
			SelectStopOptions.FontStringTitle = StdUi:Subtitle(SelectStopOptions, L["TAB"][tabName]["SELECTSTOPOPTIONS"])
			StdUi:FrameTooltip(SelectStopOptions, L["TAB"][tabName]["SELECTSTOPOPTIONSTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(SelectStopOptions.FontStringTitle, SelectStopOptions)
			SelectStopOptions.text:SetJustifyH("CENTER")	 
			
			-- UI: PanelOptions - SelectSortMethod	
			SelectSortMethod = StdUi:Dropdown(PanelOptions, StdUi:GetWidthByColumn(PanelOptions, 6), themeHeight, {
				{ text = L["TAB"][tabName]["SORTHP"], 		value = "HP"  },
				{ text = L["TAB"][tabName]["SORTAHP"], 		value = "AHP" },
			}, specDB.SelectSortMethod)			
			SelectSortMethod.OnValueChanged = function(self, value)	 
				if specDB.SelectSortMethod ~= value then 
					specDB.SelectSortMethod = value 
					Action.Print(L["TAB"][tabName]["SELECTSORTMETHOD"] .. ": ", L["TAB"][tabName]["SORT" .. value] or value)
					TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
				end 				
			end				
			SelectSortMethod:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			SelectSortMethod:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["SELECTSORTMETHOD"], [[/run Action.SetToggle({]] .. tabName .. [[, "SelectSortMethod", "]] .. L["TAB"][tabName]["SELECTSORTMETHOD"] .. [[:"}, ]] .. self.value .. [[)]], true)	
				end
			end)		
			SelectSortMethod.Identify = { Type = "Dropdown", Toggle = "SelectSortMethod" }			
			SelectSortMethod.FontStringTitle = StdUi:Subtitle(SelectSortMethod, L["TAB"][tabName]["SELECTSORTMETHOD"])
			StdUi:FrameTooltip(SelectSortMethod, L["TAB"][tabName]["SELECTSORTMETHODTOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(SelectSortMethod.FontStringTitle, SelectSortMethod)
			SelectSortMethod.text:SetJustifyH("CENTER")	
			
			-- UI: PanelOptions - AfterTargetEnemyOrBossDelay
			AfterTargetEnemyOrBossDelay = CreateSliderAfter("AfterTargetEnemyOrBossDelay")
			
			-- UI: PanelOptions - AfterMouseoverEnemyDelay
			AfterMouseoverEnemyDelay = CreateSliderAfter("AfterMouseoverEnemyDelay")
			
			-- UI: PanelOptions - HealingEngineAPI
			HealingEngineAPI = CreateCheckbox(PanelOptions, "HealingEngineAPI", true) -- yes macro, no callback
			
			-- UI: PanelOptions - SelectPets
			SelectPets = CreateCheckbox(PanelOptions, "SelectPets", true, true) -- yes macro, yes callback
			
			-- UI: PanelOptions - SelectResurrects
			SelectResurrects = CreateCheckbox(PanelOptions, "SelectResurrects", true) -- yes macro, no callback 
			if StdUi.isClassic and Action.PlayerClass == "DRUID" then 
				-- Druid in Classic hasn't ressurect
				SelectResurrects:Disable()
				SelectResurrects:SetChecked(false, true) -- only internal 
				specDB.SelectResurrects = false 
			end 
		end -- isHealer END 

			-- UI: PanelUnitIDs
		if isHealer then -- isHealer START 
			PanelUnitIDs = CreatePanel()

			-- UI: PanelUnitIDs - UnitIDs
			UnitIDs = setmetatable({
				OnClickCell 	= function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)				
					if button == "LeftButton" then		
						if IsShiftKeyDown() then
							if not columnData.db then 
								ChatEdit_InsertLink(rowData.Name)		
							end 
						elseif columnData.db then			
							if columnData.db ~= "LUA" and type(specDB.UnitIDs[rowData.unitID][columnData.db]) == "boolean" then  
								specDB.UnitIDs[rowData.unitID][columnData.db] = not specDB.UnitIDs[rowData.unitID][columnData.db]
								
								local status = specDB.UnitIDs[rowData.unitID][columnData.db]
								if status then 
									rowData[columnData.index] = columnData.db == "Enabled" and "True" or "ON"
								else 
									rowData[columnData.index] = columnData.db == "Enabled" and "False" or "OFF"
								end 
								
								Action.Print(columnData.gname .. " " .. rowData.unitID .. (rowData.unitName ~= "" and " (" .. rowData.unitName .. ")" or "") .. ": " .. rowData[columnData.index])									
								table:Refresh()
								TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
							end 
							
							if columnData.db == "Role" and not rowData.unitID:match("pet") then -- Ignore pets for Role 
								local currentRole = specDB.UnitIDs[rowData.unitID][columnData.db]
								
								if currentRole == "AUTO" then 
									currentRole = "DAMAGER"
									specDB.UnitIDs[rowData.unitID][columnData.db] = currentRole 
									rowData[columnData.index] = "*" .. L["TAB"][tabName][currentRole]
								elseif currentRole == "DAMAGER" then 
									currentRole = "HEALER"
									specDB.UnitIDs[rowData.unitID][columnData.db] = currentRole 
									rowData[columnData.index] = "*" .. L["TAB"][tabName][currentRole]
								elseif currentRole == "HEALER" then 
									currentRole = "TANK"
									specDB.UnitIDs[rowData.unitID][columnData.db] = currentRole 
									rowData[columnData.index] = "*" .. L["TAB"][tabName][currentRole]
								elseif currentRole == "TANK" then 
									currentRole = "AUTO"
									specDB.UnitIDs[rowData.unitID][columnData.db] = currentRole 
									local isSelf = Action.TeamCache.Friendly.UNITs.player == Action.TeamCache.Friendly.UNITs[rowData.unitID]
									rowData[columnData.index] = L["TAB"][tabName][Action.Unit(rowData.unitID):Role()] or isSelf and L["TAB"][tabName]["HEALER"] or Action.Unit(rowData.unitID):InGroup() and L["TAB"][tabName]["DAMAGER"] or L["TAB"][tabName]["UNKNOWN"]
								end 
								
								Action.Print(rowData.unitID .. (rowData.unitName ~= "" and " (" .. rowData.unitName .. ")" or "") .. " " .. columnData.gname .. ": " .. rowData[columnData.index])									
								table:Refresh()
								TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
							end 
						
							if columnData.db == "LUA" then 
								if table.selected ~= rowIndex then 
									table:SetSelection(rowIndex)
								end 
								
								LuaEditor.lastRow = rowIndex								
								if not LuaEditor:IsShown() then 									
									LuaEditor.EditBox:SetText(specDB.UnitIDs[rowData.unitID][columnData.db])
									LuaEditor:Show()
								else 
									LuaEditor.closeBtn:Click()
								end 								
							end 
							
							return true -- must be true to prevent call default handler (which clears or selects row)
						end	
					elseif button == "RightButton" then 
						local macroName 
						
						if IsShiftKeyDown() then
							if columnData.db then
								-- Make macro to set exact same current ceil data and set opposite for others ceils (only booleans)								
								local unitDB = specDB.UnitIDs[rowData.unitID]
								macroName = rowData.unitID .. ";opposite;" .. columnData.db
								Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "UnitIDs", "]] .. rowData.unitID .. [[:"}, {]] .. rowData.unitID .. [[ = { ]] .. columnData.db .. [[ = ]] .. ((columnData.db == "LUA" or columnData.db == "Role") and [["]] .. unitDB[columnData.db] .. [["]] or Action.toStr[unitDB[columnData.db]]) .. [[}}, true)]], true)
							else 
								-- Make macro to set opposite current row data (only booleans)
								macroName = rowData.unitID .. ";opposite"
								Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "UnitIDs", "]] .. rowData.unitID .. [[:"}, {]] .. rowData.unitID .. [[ = {}}, true)]], true)
							end 
						elseif columnData.db then
							-- Make macro to set exact same current ceil data
							local unitDB = specDB.UnitIDs[rowData.unitID]
							macroName = rowData.unitID .. ";" .. columnData.db
							Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "UnitIDs", "]] .. rowData.unitID .. [[:"}, {]] .. rowData.unitID .. [[ = { ]] .. columnData.db .. [[ = ]] .. ((columnData.db == "LUA" or columnData.db == "Role") and [["]] .. unitDB[columnData.db] .. [["]] or Action.toStr[unitDB[columnData.db]]) .. [[}})]], true)
						else 
							-- Make macro to set exact same current row data
							local unitDB = specDB.UnitIDs[rowData.unitID]
							macroName = rowData.unitID 
							Action.CraftMacro(macroName, [[/run Action.SetToggle({]] .. tabName .. [[, "UnitIDs", "]] .. rowData.unitID .. [[:"}, {]] .. rowData.unitID .. [[ = { Enabled = ]] .. Action.toStr[unitDB.Enabled] .. [[, Role = "]] .. unitDB.Role .. [[", useDispel = ]] .. Action.toStr[unitDB.useDispel] .. [[, useShields = ]] .. Action.toStr[unitDB.useShields] .. [[, useHoTs = ]] .. Action.toStr[unitDB.useHoTs] .. [[, useUtils = ]] .. Action.toStr[unitDB.useUtils] .. [[}})]], true)		
						end 
					end 							
				end,
				OnClickHeader 	= function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
					if button == "LeftButton" then
						table.SORTBY = columnIndex						
					end		
				end, 
				ColorTrue 		= { r = 0, g = 1, b = 0, a = 1 },
				ColorFalse 		= { r = 1, g = 0, b = 0, a = 1 },
			}, { __index = function(t, v) return t.Table[v] end })
			UnitIDs.Table = StdUi:ScrollTable(PanelUnitIDs, { 
				{
					name = L["TAB"][tabName]["ENABLED"],
					gname = L["TAB"][tabName]["ENABLED"],
					textTT = L["TAB"][tabName]["ENABLEDTOOLTIP"],
                    width = 35,
                    align = "LEFT",
                    index = "IndexEnabled",
					db = "Enabled",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "True" then
                            return UnitIDs.ColorTrue
                        end
                        if value == "False" then
                            return UnitIDs.ColorFalse
                        end
                    end,
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, columnData.textTT:format(rowData.unitID) .. "\n\n" .. L["TAB"]["CEILCREATEMACRO"]:format(rowData[columnData.index], columnData.gname, rowData[columnData.index], columnData.gname))       			
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
					},
				},
				{
                    name = "",
					gname = "",
					textTT = L["TAB"]["ROWCREATEMACRO"],
                    width = 25,
                    align = "CENTER",
                    index = "IndexIcon",
                    format = "icon",
                    events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, columnData.textTT)       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
                    },
                },
				{
                    name = L["TAB"][tabName]["UNITID"],
					gname = L["TAB"][tabName]["UNITID"],
					textTT = L["TAB"]["ROWCREATEMACRO"],
                    width = 62,					
					defaultSort = "dsc",
                    align = "LEFT",
                    index = "IndexUnitID",
                    format = "string",
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, columnData.textTT)       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
					},
                },
                {
                    name = L["TAB"][tabName]["NAME"],
					gname = L["TAB"][tabName]["NAME"],
					textTT = L["TAB"]["ROWCREATEMACRO"],
                    width = 57,
					defaultwidth = 57,
					resizeDivider = 2,
                    align = "LEFT",
                    index = "IndexName",
                    format = "string",
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, columnData.textTT)       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
					},
                },
                {
                    name = L["TAB"][tabName]["ROLE"],
					gname = L["TAB"][tabName]["ROLE"],
					textTT = L["TAB"][tabName]["ROLETOOLTIP"],
                    width = 60,
					defaultwidth = 60,
					maxwidth = 90,
					addwidthtoprevious = true,
					resizeDivider = 2,
                    align = "LEFT",
                    index = "IndexRole",
					db = "Role",
                    format = "string",
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, columnData.textTT .. "\n\n" .. L["TAB"]["CEILCREATEMACRO"]:format(rowData[columnData.index], columnData.gname, rowData[columnData.index], columnData.gname))       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
					},
                },
				{
                    name = L["TAB"][tabName]["USEDISPEL"],
					gname = L["TAB"][tabName]["USEDISPEL"]:gsub("\n", ""),
                    width = 50,
                    align = "CENTER",
                    index = "IndexDispel",
					db = "useDispel",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return UnitIDs.ColorTrue
                        end
                        if value == "OFF" then
                            return UnitIDs.ColorFalse
                        end
                    end,
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"][tabName]["USEDISPELTOOLTIP"]:format(rowData.unitID, rowData.unitID) .. L["TAB"][tabName]["GGLPROFILESTOOLTIP"]:format(columnData.gname) .. "\n\n" .. L["TAB"]["CEILCREATEMACRO"]:format(rowData[columnData.index], columnData.gname, rowData[columnData.index], columnData.gname))       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
					},
                },		
				{
                    name = L["TAB"][tabName]["USESHIELDS"],
					gname = L["TAB"][tabName]["USESHIELDS"]:gsub("\n", ""),
                    width = 50,
                    align = "CENTER",
                    index = "IndexShields",
					db = "useShields",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return UnitIDs.ColorTrue
                        end
                        if value == "OFF" then
                            return UnitIDs.ColorFalse
                        end
                    end,
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"][tabName]["USESHIELDSTOOLTIP"]:format(rowData.unitID, rowData.unitID) .. L["TAB"][tabName]["GGLPROFILESTOOLTIP"]:format(columnData.gname) .. "\n\n" .. L["TAB"]["CEILCREATEMACRO"]:format(rowData[columnData.index], columnData.gname, rowData[columnData.index], columnData.gname))       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
					},
                },	
				{
                    name = L["TAB"][tabName]["USEHOTS"],
					gname = L["TAB"][tabName]["USEHOTS"]:gsub("\n", ""),
                    width = 50,
                    align = "CENTER",
                    index = "IndexHoTs",
					db = "useHoTs",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return UnitIDs.ColorTrue
                        end
                        if value == "OFF" then
                            return UnitIDs.ColorFalse
                        end
                    end,
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"][tabName]["USEHOTSTOOLTIP"]:format(rowData.unitID, rowData.unitID) .. L["TAB"][tabName]["GGLPROFILESTOOLTIP"]:format(columnData.gname) .. "\n\n" .. L["TAB"]["CEILCREATEMACRO"]:format(rowData[columnData.index], columnData.gname, rowData[columnData.index], columnData.gname))       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
					},
                },	
				{
                    name = L["TAB"][tabName]["USEUTILS"],
					gname = L["TAB"][tabName]["USEUTILS"]:gsub("\n", ""),
                    width = 50,
                    align = "CENTER",
                    index = "IndexUtils",
					db = "useUtils",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return UnitIDs.ColorTrue
                        end
                        if value == "OFF" then
                            return UnitIDs.ColorFalse
                        end
                    end,
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"][tabName]["USEUTILSTOOLTIP"]:format(rowData.unitID, rowData.unitID) .. L["TAB"][tabName]["GGLPROFILESTOOLTIP"]:format(columnData.gname) .. "\n\n" .. L["TAB"]["CEILCREATEMACRO"]:format(rowData[columnData.index], columnData.gname, rowData[columnData.index], columnData.gname))       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
					},
                },	
				{
                    name = "LUA",
					gname = "LUA",
                    width = 35,
                    align = "CENTER",
                    index = "IndexLUA",
					db = "LUA",
                    format = "string",
                    color = function(table, value, rowData, columnData)
                        if value == "ON" then
                            return UnitIDs.ColorTrue
                        end
                        if value == "OFF" then
                            return UnitIDs.ColorFalse
                        end
                    end,
					events = {
						OnEnter = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)                        
                            StdUi:ShowTooltip(cellFrame, true, L["TAB"][tabName]["LUATOOLTIP"]:format(rowData.unitID) .. "\n\n" .. L["TAB"]["CEILCREATEMACRO"]:format(columnData.gname, columnData.gname, columnData.gname, columnData.gname))       							 
                        end,
                        OnLeave = function(rowFrame, cellFrame)
                            StdUi:ShowTooltip(cellFrame, false)  							
                        end,
						OnClick = UnitIDs.OnClickCell,
					},
                },	
            }, 12, 25)	
			ScrollTable = UnitIDs.Table
			ScrollTable:RegisterEvents(nil, { OnClick = UnitIDs.OnClickHeader })
			ScrollTable.SORTBY = 3
			ScrollTable.defaultrows = { numberOfRows = ScrollTable.numberOfRows, rowHeight = ScrollTable.rowHeight }
			ScrollTable:EnableSelection(true)
			ScrollTable.MakeUpdate = function()								
				if not anchor:IsShown() or ScrollTable.IsUpdating then -- anchor here because it's scroll child and methods :IsVisible and :IsShown can skip it in theory 
					return 
				end 
				
				local self = ScrollTable
				self.IsUpdating = true 
				if not self.data then 
					self.data = {}
				else 
					wipe(self.data)
				end 
				
				local useAutoHide 	= specDB.AutoHide
				local usePets		= specDB.SelectPets			
				
				local TeamCache		= Action.TeamCache.Friendly
				local inGroup		= TeamCache.Type 
				local guidToUnit	= TeamCache.GUIDs 
				local unitToGUID	= TeamCache.UNITs
				
				local focusGUID		= unitToGUID.focus or (not StdUi.isClassic and UnitGUID("focus"))
				local playerGUID	= unitToGUID.player
				
				for unitID, v in pairs(specDB.UnitIDs) do 					
					local isPet = unitID:match("pet") 
					local unitSkip
					
					if not usePets and isPet then 
						unitSkip			= true 
					end 
					
					if useAutoHide then 
						-- If not exists 
						if not unitSkip and not unitToGUID[unitID] and (unitID ~= "focus" or not Action.Unit(unitID):IsExists()) then 
							unitSkip 		= true 
						end 
						
						-- If player and group is 'raid'
						if not unitSkip and inGroup == "raid" and unitID == "player" then 
							unitSkip 		= true 
						end 
						
						-- If player/pet/party/raid is 'focus'
						if not unitSkip and focusGUID and unitID == "focus" and guidToUnit[focusGUID] then 
							unitSkip 		= true 
						end 
						
						-- Remove party from raid or raid from party 
						if not unitSkip and inGroup and not unitID:match(inGroup) and (unitID:match("party") or unitID:match("raid")) then 
							unitSkip 		= true 
						end 
					end 
				
					if not unitSkip then 
						local unitName 		= Action.Unit(unitID):Name()
						if unitName == "none" then 
							unitName 		= ""
						elseif isDemo and unitID == "player" then   
							unitName		= "NameCharacter"
						end 												

						local IndexEnabled	= v.Enabled 		and "True" 	or "False"
						local IndexIcon 	= unitName ~= "" 	and ActionConst[isPet and "TRUE_PORTRAIT_PET" or "TRUE_PORTRAIT_" .. Action.Unit(unitID):Class()] or ActionConst.TRUE_PORTRAIT_PICKPOCKET
						local IndexRole		
						if v.Role == "AUTO" then 
							if not isPet then 
								IndexRole = L["TAB"][tabName][Action.Unit(unitID):Role()] or unitToGUID[unitID] == playerGUID and L["TAB"][tabName]["HEALER"] or Action.Unit(unitID):InGroup() and L["TAB"][tabName]["DAMAGER"] or L["TAB"][tabName]["UNKNOWN"]
							else 
								IndexRole = L["TAB"][tabName]["DAMAGER"] 
							end 
						else 
							if not isPet then 
								IndexRole = L["TAB"][tabName][v.Role] and ("*" .. L["TAB"][tabName][v.Role]) or L["TAB"][tabName]["UNKNOWN"]
							else 
								IndexRole = L["TAB"][tabName]["DAMAGER"] 
							end 
						end 
						local IndexDispel 	= v.useDispel 		and "ON" 	or "OFF"						
						local IndexShields 	= v.useShields 		and "ON" 	or "OFF"						
						local IndexHoTs 	= v.useHoTs 		and "ON" 	or "OFF"
						local IndexUtils 	= v.useUtils	 	and "ON" 	or "OFF"
						local IndexLUA		= v.LUA ~= ""		and "ON"	or "OFF"
						tinsert(self.data, setmetatable({ 		
							unitID 			= unitID,
							unitName		= unitName,	
							IndexEnabled	= IndexEnabled,
							IndexIcon		= IndexIcon,							
							IndexUnitID		= unitID,
							IndexName 		= unitName,
							IndexRole		= IndexRole,
							IndexDispel 	= IndexDispel,
							IndexShields 	= IndexShields,
							IndexHoTs 		= IndexHoTs,
							IndexUtils		= IndexUtils,
							IndexLUA		= IndexLUA,
						}, { __index = v })) -- meta index is not used here but why not to add ?
					end 
				end
				
				self:ClearSelection()			
				self:SetData(self.data)
				self:SortData(self.SORTBY)
				self.IsUpdating = nil 
			end				
			ScrollTable.OriginalSetSelection = ScrollTable.SetSelection
			ScrollTable.SetSelection = function(self, rowIndex, internal)				
				self:OriginalSetSelection(rowIndex)
				-- Refresh or reset LuaEditor if row selection changed exactly manual 
				if not internal and not self.IsUpdating and LuaEditor and LuaEditor:IsShown() then 
					local rowData = rowIndex and self:GetRow(rowIndex)
					if rowData then
						LuaEditor.EditBox:SetText(specDB.UnitIDs[rowData.unitID].LUA)
					else 
						LuaEditor.EditBox:SetText("")
						LuaEditor.closeBtn:Click() 
					end 
				end
			end 
			ScrollTable.OriginalRefresh = ScrollTable.Refresh 
			ScrollTable.Refresh = function(self)
				if LuaEditor and LuaEditor:IsShown() and (not self.selected or not self:GetRow(self.selected)) then 
					LuaEditor.EditBox:SetText("")
					LuaEditor.closeBtn:Click()  
				end
				self:OriginalRefresh()
			end 
			TMW:RegisterCallback("TMW_ACTION_HEALING_ENGINE_UI_UPDATE", ScrollTable.MakeUpdate)	-- Fired from SetToggle for UnitIDs (which is also affected from HealingEngineProfileLoad)
			TMW:RegisterCallback("TMW_ACTION_GROUP_UPDATE", 			ScrollTable.MakeUpdate) -- Fired from Base.lua 			
			if not StdUi.isClassic then 
				-- Retail: Add event for focus change 
				ScrollTable:RegisterEvent("PLAYER_FOCUS_CHANGED")
				ScrollTable:SetScript("OnEvent", 						ScrollTable.MakeUpdate)
			end  
			StdUi:ClipScrollTableColumn(ScrollTable, 35)
			
			-- UI: PanelUnitIDs - AutoHide
			AutoHide = CreateCheckbox(PanelUnitIDs, "AutoHide", false, true) -- no macro, yes callback  
		end -- isHealer END 
			
			-- UI: PanelProfiles
		if isHealer then -- isHealer START	
			PanelProfiles = CreatePanel(L["TAB"][tabName]["PROFILES"], 1)	
			
			-- UI: PanelProfiles - ResetProfile (corner button)
			ResetProfile = StdUi:Button(PanelProfiles, 70, themeHeight, L["RESET"])
			ResetProfile:SetScript("OnClick", function(self, button, down)
				for profileName in pairs(specDB.Profiles) do 
					if profileName and profileName ~= "" then 
						Action.HealingEngineProfileDelete(profileName)
					end 
				end 
			end)
			StdUi:GlueTop(ResetProfile, PanelProfiles, 0, 0, "LEFT")	
			StdUi:ApplyBackdrop(ResetProfile, "panel", "border")
			
			-- UI: PanelProfiles - HelpProfile (corner button)
			HelpProfile = StdUi:Button(PanelProfiles, 70, themeHeight, L["TAB"][tabName]["HELP"])
			HelpProfile:SetScript("OnClick", function(self, button, down)
				HelpWindow:Open(L["TAB"][tabName]["PROFILESHELP"])
			end)
			StdUi:GlueTop(HelpProfile, PanelProfiles, 0, 0, "RIGHT")
			StdUi:ApplyBackdrop(HelpProfile, "panel", "border")
			
			-- UI: PanelProfiles - Profile
			local ProfileData = {}
			local function GetProfiles()
				wipe(ProfileData)
				for profileName in pairs(specDB.Profiles) do 
					ProfileData[#ProfileData + 1] = { text = profileName, value = profileName }
				end 
				
				return ProfileData
			end
			TMW:RegisterCallback("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", function(callbackEvent, callbackAction, profileCurrent)
				if Profile and EditBoxProfile then 
					if callbackAction == "Saved" or callbackAction == "Deleted" then 
						Profile:SetOptions(GetProfiles())
					end 
					Profile:SetValue(profileCurrent)
					if EditBoxProfile:IsShown() then 
						if callbackAction ~= "Changed" then 
							EditBoxProfile:SetText("")						
						end 
						EditBoxProfile:ClearFocus()
					end 
				end 
			end)
			
			Profile = StdUi:Dropdown(PanelProfiles, StdUi:GetWidthByColumn(PanelProfiles, 12), themeHeight, GetProfiles(), specDB.Profile)
			Profile:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			Profile:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					if #self.options > 0 then  
						self:ToggleOptions()
					end 
				elseif button == "RightButton" and self.value and self.value ~= "" then 
					Action.CraftMacro(L["TAB"][tabName]["PROFILE"] .. " " .. L["TAB"][tabName]["PROFILELOAD"] .. ": " .. self.value, [[/run Action.HealingEngineProfileLoad("]] .. self.value .. [[")]], true)	
				end
			end)
			Profile.OnValueChanged = function(self, value)
				if specDB.Profile ~= value then 
					specDB.Profile = value or ""
				end 
			end
			Profile:SetPlaceholder(L["TAB"][tabName]["PROFILEPLACEHOLDER"])
			Profile.Identify = { Type = "Dropdown", Toggle = "Profile" }			
			Profile.FontStringTitle = StdUi:Subtitle(Profile, L["TAB"][tabName]["PROFILE"])
			Profile.text:SetJustifyH("CENTER")
			StdUi:GlueAbove(Profile.FontStringTitle, Profile)
			StdUi:FrameTooltip(Profile, L["TAB"][tabName]["PROFILETOOLTIP"], nil, "TOP", true)									
			
			-- UI: PanelProfiles - EditBoxProfile    
			EditBoxProfile = StdUi:SearchEditBox(PanelProfiles, StdUi:GetWidthByColumn(PanelProfiles, 12), 20, L["TAB"][tabName]["PROFILEWRITENAME"])
			EditBoxProfile:SetScript("OnTextChanged", function(self)
				local text = self:GetText()
				if text ~= nil and text ~= "" then									
					self.placeholder.icon:Hide()
					self.placeholder.label:Hide()					
				else 
					self.placeholder.icon:Show()
					self.placeholder.label:Show()
				end 
            end)
			EditBoxProfile:SetScript("OnEnterPressed", function(self)
				SaveProfile:Click()                
            end)
			EditBoxProfile:SetScript("OnEscapePressed", function(self)
				self:SetText("")
				self:ClearFocus() 
            end)			
			StdUi:ApplyBackdrop(EditBoxProfile, "panel", "border")
			
			-- UI: PanelProfiles - SaveProfile
			SaveProfile = StdUi:Button(PanelProfiles, 0, 30, L["TAB"][tabName]["PROFILESAVE"])
			SaveProfile:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			SaveProfile:SetScript("OnClick", function(self, button, down)
				-- First get from editbox field 					
				local profileCurrent = EditBoxProfile:GetText()
				
				-- Secondary get from dropdown 
				if profileCurrent == nil or profileCurrent == "" then 
					profileCurrent = Profile:GetValue()
				end 

				if profileCurrent == nil or profileCurrent == "" then 
					Action.Print(L["DEBUG"] .. L["TAB"][tabName]["PROFILEERROREMPTY"])
					return 
				end 
				
				if button == "LeftButton" then 				
					Action.HealingEngineProfileSave(profileCurrent)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["PROFILE"] .. " " .. L["TAB"][tabName]["PROFILESAVE"] .. ": " .. profileCurrent, [[/run Action.HealingEngineProfileSave("]] .. profileCurrent .. [[")]], true)					
				end 
			end)	
			StdUi:FrameTooltip(SaveProfile, L["TAB"][tabName]["CREATEMACRO"], nil, "BOTTOM", true)	
			StdUi:ApplyBackdrop(SaveProfile, "panel", "buttonDisabled")	
			
			-- UI: PanelProfiles - LoadProfile
			LoadProfile = StdUi:Button(PanelProfiles, 0, 30, L["TAB"][tabName]["PROFILELOAD"])
			LoadProfile:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			LoadProfile:SetScript("OnClick", function(self, button, down)
				local profileCurrent = Profile:GetValue()
				if profileCurrent == nil or profileCurrent == "" then 
					Action.Print(L["DEBUG"] .. L["TAB"][tabName]["PROFILEERROREMPTY"])
					return 
				end 
								
				if button == "LeftButton" then 
					Action.HealingEngineProfileLoad(profileCurrent) 
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["PROFILE"] .. " " .. L["TAB"][tabName]["PROFILELOAD"] .. ": " .. profileCurrent, [[/run Action.HealingEngineProfileLoad("]] .. profileCurrent .. [[")]], true)					
				end 
			end)	
			StdUi:FrameTooltip(LoadProfile, L["TAB"][tabName]["CREATEMACRO"], nil, "BOTTOM", true)	
			StdUi:ApplyBackdrop(LoadProfile, "panel", "buttonDisabled")	
			
			-- UI: PanelProfiles - RemoveProfile
			RemoveProfile = StdUi:Button(PanelProfiles, 0, 30, L["TAB"][tabName]["PROFILEDELETE"])
			RemoveProfile:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			RemoveProfile:SetScript("OnClick", function(self, button, down)
				local profileCurrent = Profile:GetValue()
				if profileCurrent == nil or profileCurrent == "" then 
					Action.Print(L["DEBUG"] .. L["TAB"][tabName]["PROFILEERROREMPTY"])
					return 
				end 
				
				if button == "LeftButton" then 					
					Action.HealingEngineProfileDelete(profileCurrent)
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["PROFILE"] .. " " .. L["TAB"][tabName]["PROFILEDELETE"] .. ": " .. profileCurrent, [[/run Action.HealingEngineProfileDelete("]] .. profileCurrent .. [[")]], true)					
				end 
			end)	
			StdUi:FrameTooltip(RemoveProfile, L["TAB"][tabName]["CREATEMACRO"], nil, "BOTTOM", true)
			StdUi:ApplyBackdrop(RemoveProfile, "panel", "buttonDisabled")	
		end -- isHealer END 
		
			-- UI: PanelPriority and Mana Management 
		if isHealer then -- isHealer START 
			PanelPriority = CreatePanel(L["TAB"][tabName]["PRIORITYHEALTH"], 2)	
			
			-- UI: PanelPriority - ResetPriority (corner button)
			ResetPriority = StdUi:Button(PanelPriority, 70, themeHeight, L["RESET"])
			ResetPriority:SetScript("OnClick", function(self, button, down)
				local db 
				if StdUi.Factory[tabName].PLAYERSPEC then
					db = StdUi.Factory[tabName].PLAYERSPEC
				else 
					db = StdUi.Factory[tabName]
				end
				
				for k, v in pairs(db) do 
					if PriorityResetWidgets[k] and PriorityResetWidgets[k]:GetValue() ~= v then 
						PriorityResetWidgets[k]:SetValue(v)
						-- OnValueChanged will set specDB
						if PriorityResetWidgets[k].Identify.Type == "Slider" then 
							Action.Print(PriorityResetWidgets[k].FontStringTitle:GetText() or v)	
						end 
					end 
				end 
			end)
			StdUi:GlueTop(ResetPriority, PanelPriority, 0, 0, "LEFT")	
			StdUi:ApplyBackdrop(ResetPriority, "panel", "border")
			
			-- UI: PanelPriority - HelpPriority (corner button)
			HelpPriority = StdUi:Button(PanelPriority, 70, themeHeight, L["TAB"][tabName]["HELP"])
			HelpPriority:SetScript("OnClick", function(self, button, down)
				HelpWindow:Open(L["TAB"][tabName]["PRIORITYHELP"])
			end)
			StdUi:GlueTop(HelpPriority, PanelPriority, 0, 0, "RIGHT")
			StdUi:ApplyBackdrop(HelpPriority, "panel", "border")			
			
			-- UI: PanelPriority - Multipliers (title)
			Multipliers = StdUi:Header(PanelPriority, L["TAB"][tabName]["MULTIPLIERS"])
			Multipliers:SetAllPoints()			
			Multipliers:SetJustifyH("CENTER")
			Multipliers:SetFontSize(15)	
			-- UI: PanelPriority - MultiplierIncomingDamageLimit
			MultiplierIncomingDamageLimit 	= CreateSliderMultiplier("MultiplierIncomingDamageLimit")			
			-- UI: PanelPriority - MultiplierThreat
			MultiplierThreat 				= CreateSliderMultiplier("MultiplierThreat")
			-- UI: PanelPriority - MultiplierPetsInCombat
			MultiplierPetsInCombat			= CreateSliderMultiplier("MultiplierPetsInCombat")
			-- UI: PanelPriority - MultiplierPetsOutCombat
			MultiplierPetsOutCombat			= CreateSliderMultiplier("MultiplierPetsOutCombat")
			
			-- UI: PanelPriority - Offsets (title)
			Offsets = StdUi:Header(PanelPriority, L["TAB"][tabName]["OFFSETS"])
			Offsets:SetAllPoints()			
			Offsets:SetJustifyH("CENTER")
			Offsets:SetFontSize(15)
			
			-- UI: PanelPriority - OffsetMode 
			OffsetMode = StdUi:Dropdown(PanelPriority, StdUi:GetWidthByColumn(PanelPriority, 12), themeHeight, {
				{ text = L["TAB"][tabName]["OFFSETMODEFIXED"], 			value = "FIXED"  },
				{ text = L["TAB"][tabName]["OFFSETMODEARITHMETIC"], 	value = "ARITHMETIC" },
			}, specDB.OffsetMode)			
			OffsetMode.OnValueChanged = function(self, value)	 
				if specDB.OffsetMode ~= value then 
					specDB.OffsetMode = value 
					Action.Print(L["TAB"][tabName]["OFFSETMODE"] .. ": ", L["TAB"][tabName]["OFFSETMODE" .. value] or value)
					TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
				end 				
			end				
			OffsetMode:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			OffsetMode:SetScript("OnClick", function(self, button, down)
				if button == "LeftButton" then 
					self:ToggleOptions()
				elseif button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["OFFSETMODE"], [[/run Action.SetToggle({]] .. tabName .. [[, "OffsetMode", "]] .. L["TAB"][tabName]["OFFSETMODE"] .. [[:"}, ]] .. self.value .. [[)]], true)	
				end
			end)		
			OffsetMode.Identify = { Type = "Dropdown", Toggle = "OffsetMode" }			
			OffsetMode.FontStringTitle = StdUi:Subtitle(OffsetMode, L["TAB"][tabName]["OFFSETMODE"])
			StdUi:FrameTooltip(OffsetMode, L["TAB"][tabName]["OFFSETMODETOOLTIP"], nil, "TOP", true)
			StdUi:GlueAbove(OffsetMode.FontStringTitle, OffsetMode)
			OffsetMode.text:SetJustifyH("CENTER")	
			
			-- UI: PanelPriority - OffsetSelfFocused
			OffsetSelfFocused				= CreateSliderOffset("OffsetSelfFocused")
			-- UI: PanelPriority - OffsetSelfUnfocused
			OffsetSelfUnfocused				= CreateSliderOffset("OffsetSelfUnfocused")
			-- UI: PanelPriority - OffsetSelfDispel
			OffsetSelfDispel				= CreateSliderOffset("OffsetSelfDispel")
			-- UI: PanelPriority - OffsetHealers
			OffsetHealers					= CreateSliderOffset("OffsetHealers")
			-- UI: PanelPriority - OffsetTanks
			OffsetTanks						= CreateSliderOffset("OffsetTanks")
			-- UI: PanelPriority - OffsetDamagers
			OffsetDamagers					= CreateSliderOffset("OffsetDamagers")
			-- UI: PanelPriority - OffsetHealersDispel
			OffsetHealersDispel				= CreateSliderOffset("OffsetHealersDispel")
			-- UI: PanelPriority - OffsetTanksDispel
			OffsetTanksDispel				= CreateSliderOffset("OffsetTanksDispel")
			-- UI: PanelPriority - OffsetDamagersDispel
			OffsetDamagersDispel			= CreateSliderOffset("OffsetDamagersDispel")
			-- UI: PanelPriority - OffsetHealersShields
			OffsetHealersShields			= CreateSliderOffset("OffsetHealersShields")
			-- UI: PanelPriority - OffsetTanksShields
			OffsetTanksShields				= CreateSliderOffset("OffsetTanksShields")
			-- UI: PanelPriority - OffsetDamagersShields
			OffsetDamagersShields			= CreateSliderOffset("OffsetDamagersShields")
			-- UI: PanelPriority - OffsetHealersHoTs
			OffsetHealersHoTs				= CreateSliderOffset("OffsetHealersHoTs")
			-- UI: PanelPriority - OffsetTanksHoTs
			OffsetTanksHoTs					= CreateSliderOffset("OffsetTanksHoTs")
			-- UI: PanelPriority - OffsetDamagersHoTs
			OffsetDamagersHoTs				= CreateSliderOffset("OffsetDamagersHoTs")
			-- UI: PanelPriority - OffsetHealersUtils
			OffsetHealersUtils				= CreateSliderOffset("OffsetHealersUtils")
			-- UI: PanelPriority - OffsetTanksUtils
			OffsetTanksUtils				= CreateSliderOffset("OffsetTanksUtils")
			-- UI: PanelPriority - OffsetDamagersUtils
			OffsetDamagersUtils				= CreateSliderOffset("OffsetDamagersUtils")
			
			-- UI: PanelManaManagement
			PanelManaManagement = CreatePanel(L["TAB"][tabName]["MANAMANAGEMENT"], 3)
			
			-- UI: PanelManaManagement - ResetManaManagement (corner button)
			ResetManaManagement = StdUi:Button(PanelManaManagement, 70, themeHeight, L["RESET"])
			ResetManaManagement:SetScript("OnClick", function(self, button, down)
				local db 
				if StdUi.Factory[tabName].PLAYERSPEC then
					db = StdUi.Factory[tabName].PLAYERSPEC
				else 
					db = StdUi.Factory[tabName]
				end
				
				for k, v in pairs(db) do 
					if ResetManaManagementWidges[k] and ResetManaManagementWidges[k]:GetValue() ~= v then 
						ResetManaManagementWidges[k]:SetValue(v)
						-- OnValueChanged will set specDB
						Action.Print(ResetManaManagementWidges[k].FontStringTitle:GetText())	
					end 
				end 
			end)
			StdUi:GlueTop(ResetManaManagement, PanelManaManagement, 0, 0, "LEFT")	
			StdUi:ApplyBackdrop(ResetManaManagement, "panel", "border")
			
			-- UI: PanelManaManagement - HelpManaManagement (corner button)
			HelpManaManagement = StdUi:Button(PanelManaManagement, 70, themeHeight, L["TAB"][tabName]["HELP"])
			HelpManaManagement:SetScript("OnClick", function(self, button, down)
				HelpWindow:Open(L["TAB"][tabName]["MANAMANAGEMENTHELP"])
			end)
			StdUi:GlueTop(HelpManaManagement, PanelManaManagement, 0, 0, "RIGHT")
			StdUi:ApplyBackdrop(HelpManaManagement, "panel", "border")
			
			-- UI: PanelManaManagement - ManaManagementManaBoss
			ManaManagementManaBoss = StdUi:Slider(PanelManaManagement, 0, themeHeight, specDB.ManaManagementManaBoss, false, -1, 100)
			ManaManagementManaBoss:SetScript("OnMouseUp", function(self, button, down)
				if button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["MANAMANAGEMENTMANABOSS"], [[/run Action.SetToggle({]] .. tabName .. [[, "ManaManagementManaBoss", "]] .. L["TAB"][tabName]["MANAMANAGEMENTMANABOSS"] .. [[: "}, ]] .. specDB.ManaManagementManaBoss .. [[)]], true)	
				end					
			end)		
			ManaManagementManaBoss.Identify = { Type = "Slider", Toggle = "ManaManagementManaBoss" }					
			ManaManagementManaBoss.MakeTextUpdate = function(self, value)
				if value < 0 then 
					self.FontStringTitle:SetText(L["TAB"][tabName]["MANAMANAGEMENTMANABOSS"] .. ": |cffff0000OFF|r")
				else 
					self.FontStringTitle:SetText(L["TAB"][tabName]["MANAMANAGEMENTMANABOSS"] .. ": |cff00ff00" .. value .. "|r")
				end  
			end 
			ManaManagementManaBoss.OnValueChanged = function(self, value)
				specDB.ManaManagementManaBoss = value
				self:MakeTextUpdate(value)
				TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
			end								
			ManaManagementManaBoss.FontStringTitle = StdUi:Subtitle(PanelManaManagement, "")
			ManaManagementManaBoss:MakeTextUpdate(specDB.ManaManagementManaBoss)			
			ManaManagementManaBoss:SetPrecision(0)		
			StdUi:GlueAbove(ManaManagementManaBoss.FontStringTitle, ManaManagementManaBoss)
			StdUi:FrameTooltip(ManaManagementManaBoss, L["TAB"][tabName]["MANAMANAGEMENTMANABOSSTOOLTIP"], nil, "BOTTOM", true)	

			-- UI: PanelManaManagement - ManaManagementStopAtHP
			ManaManagementStopAtHP = StdUi:Slider(PanelManaManagement, 0, themeHeight, specDB.ManaManagementStopAtHP, false, -1, 99)
			ManaManagementStopAtHP:SetScript("OnMouseUp", function(self, button, down)
				if button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["MANAMANAGEMENTSTOPATHP"], [[/run Action.SetToggle({]] .. tabName .. [[, "ManaManagementStopAtHP", "]] .. L["TAB"][tabName]["MANAMANAGEMENTSTOPATHP"] .. [[: "}, ]] .. specDB.ManaManagementStopAtHP .. [[)]], true)	
				end					
			end)		
			ManaManagementStopAtHP.Identify = { Type = "Slider", Toggle = "ManaManagementStopAtHP" }					
			ManaManagementStopAtHP.MakeTextUpdate = function(self, value)
				if value >= 100 then 
					self.FontStringTitle:SetText(L["TAB"][tabName]["MANAMANAGEMENTSTOPATHP"] .. ": |cff00ff00AUTO|r")
				elseif value < 0 then 
					self.FontStringTitle:SetText(L["TAB"][tabName]["MANAMANAGEMENTSTOPATHP"] .. ": |cffff0000OFF|r")
				else 
					self.FontStringTitle:SetText(L["TAB"][tabName]["MANAMANAGEMENTSTOPATHP"] .. ": |cff00ff00" .. value .. "|r")
				end  
			end 
			ManaManagementStopAtHP.OnValueChanged = function(self, value)
				specDB.ManaManagementStopAtHP = value
				self:MakeTextUpdate(value)
				TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
			end								
			ManaManagementStopAtHP.FontStringTitle = StdUi:Subtitle(PanelManaManagement, "")
			ManaManagementStopAtHP:MakeTextUpdate(specDB.ManaManagementStopAtHP)
			ManaManagementStopAtHP:SetPrecision(0)			
			StdUi:GlueAbove(ManaManagementStopAtHP.FontStringTitle, ManaManagementStopAtHP)
			StdUi:FrameTooltip(ManaManagementStopAtHP, L["TAB"][tabName]["MANAMANAGEMENTSTOPATHPTOOLTIP"], nil, "BOTTOM", true)	
			
			-- UI: PanelManaManagement - OR 
			OR = StdUi:Header(PanelManaManagement, L["TAB"][tabName]["OR"])
			OR:SetAllPoints()			
			OR:SetJustifyH("CENTER")
			OR:SetFontSize(14)
			
			-- UI: PanelManaManagement - ManaManagementStopAtTTD
			ManaManagementStopAtTTD = StdUi:Slider(PanelManaManagement, 0, themeHeight, specDB.ManaManagementStopAtTTD, false, -1, 99)
			ManaManagementStopAtTTD:SetScript("OnMouseUp", function(self, button, down)
				if button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["MANAMANAGEMENTSTOPATTTD"], [[/run Action.SetToggle({]] .. tabName .. [[, "ManaManagementStopAtTTD", "]] .. L["TAB"][tabName]["MANAMANAGEMENTSTOPATTTD"] .. [[: "}, ]] .. specDB.ManaManagementStopAtTTD .. [[)]], true)	
				end					
			end)		
			ManaManagementStopAtTTD.Identify = { Type = "Slider", Toggle = "ManaManagementStopAtTTD" }					
			ManaManagementStopAtTTD.MakeTextUpdate = function(self, value)
				if value >= 100 then 
					self.FontStringTitle:SetText(L["TAB"][tabName]["MANAMANAGEMENTSTOPATTTD"] .. ": |cff00ff00AUTO|r")
				elseif value < 0 then 
					self.FontStringTitle:SetText(L["TAB"][tabName]["MANAMANAGEMENTSTOPATTTD"] .. ": |cffff0000OFF|r")
				else 
					self.FontStringTitle:SetText(L["TAB"][tabName]["MANAMANAGEMENTSTOPATTTD"] .. ": |cff00ff00" .. value .. "|r")
				end  
			end 
			ManaManagementStopAtTTD.OnValueChanged = function(self, value)
				specDB.ManaManagementStopAtTTD = value
				self:MakeTextUpdate(value)
				TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
			end								
			ManaManagementStopAtTTD.FontStringTitle = StdUi:Subtitle(PanelManaManagement, "")
			ManaManagementStopAtTTD:MakeTextUpdate(specDB.ManaManagementStopAtTTD)	
			ManaManagementStopAtTTD:SetPrecision(0)
			StdUi:GlueAbove(ManaManagementStopAtTTD.FontStringTitle, ManaManagementStopAtTTD)
			StdUi:FrameTooltip(ManaManagementStopAtTTD, L["TAB"][tabName]["MANAMANAGEMENTSTOPATTTDTOOLTIP"], nil, "BOTTOM", true)	
			
			-- UI: PanelManaManagement - ManaManagementPredictVariation
			ManaManagementPredictVariation = StdUi:Slider(PanelManaManagement, 0, themeHeight, specDB.ManaManagementPredictVariation, false, 1, 15)
			ManaManagementPredictVariation:SetScript("OnMouseUp", function(self, button, down)
				if button == "RightButton" then 
					Action.CraftMacro(L["TAB"][tabName]["MANAMANAGEMENTPREDICTVARIATION"], [[/run Action.SetToggle({]] .. tabName .. [[, "ManaManagementPredictVariation", "]] .. L["TAB"][tabName]["MANAMANAGEMENTPREDICTVARIATION"] .. [[: "}, ]] .. specDB.ManaManagementPredictVariation .. [[)]], true)	
				end					
			end)		
			ManaManagementPredictVariation.Identify = { Type = "Slider", Toggle = "ManaManagementPredictVariation" }					
			ManaManagementPredictVariation.MakeTextUpdate = function(self, value)
				self.FontStringTitle:SetText(L["TAB"][tabName]["MANAMANAGEMENTPREDICTVARIATION"] .. ": |cff00ff00" .. value .. "|r")  
			end 
			ManaManagementPredictVariation.OnValueChanged = function(self, value)
				specDB.ManaManagementPredictVariation = value
				self:MakeTextUpdate(value)
				TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
			end								
			ManaManagementPredictVariation.FontStringTitle = StdUi:Subtitle(PanelManaManagement, "")
			ManaManagementPredictVariation:MakeTextUpdate(specDB.ManaManagementPredictVariation)			
			ManaManagementPredictVariation:SetPrecision(1)		
			StdUi:GlueAbove(ManaManagementPredictVariation.FontStringTitle, ManaManagementPredictVariation)
			StdUi:FrameTooltip(ManaManagementPredictVariation, L["TAB"][tabName]["MANAMANAGEMENTPREDICTVARIATIONTOOLTIP"], nil, "BOTTOM", true)	
		end -- isHealer END
			
			-- UI: HelpWindow
			HelpWindow = StdUi:Window(MainUI, anchor:GetWidth() - 30, anchor:GetHeight() - 60, L["TAB"][tabName]["HELP"]) -- MainUI here for clip anchoring
			HelpWindow:SetPoint("CENTER")
			HelpWindow:SetFrameStrata("TOOLTIP")
			HelpWindow:SetFrameLevel(49)
			HelpWindow:SetBackdropColor(0, 0, 0, 1)
			HelpWindow:SetMovable(false)
			HelpWindow:SetShown(false)
			HelpWindow:SetScript("OnDragStart", nil)
			HelpWindow:SetScript("OnDragStop", nil)
			HelpWindow:SetScript("OnReceiveDrag", nil)			
			HelpWindow.Open = function(self, text)
				self:SetShown(not self:IsShown())
				if self:IsShown() then 
					self.HelpText:SetText(Action.LTrim(text))	
				end 
			end 			
			HelpWindow.HelpText = StdUi:Label(HelpWindow, "")	
			HelpWindow.HelpText:SetJustifyH("CENTER")
			HelpWindow.HelpText:SetFontSize(13)
			StdUi:GlueAcross(HelpWindow.HelpText, HelpWindow, 10, -30, -10, 30)
			HelpWindow.ButtonOK = StdUi:Button(HelpWindow, HelpWindow:GetWidth() - 30, 35, L["TAB"][tabName]["HELPOK"])		
			StdUi:GlueBottom(HelpWindow.ButtonOK, HelpWindow, 0, 20, "CENTER")
			HelpWindow.ButtonOK:SetScript("OnClick", function()
				HelpWindow:Hide()
			end)
			
			-- UI: LuaEditor
		if isHealer then 
			LuaEditor = StdUi:CreateLuaEditor(anchor.scrollFrame, L["TAB"]["LUAWINDOW"], MainUI.default_w, MainUI.default_h, L["TAB"]["LUATOOLTIP"] .. L["TAB"][tabName]["LUATOOLTIPADDITIONAL"])
			LuaEditor:HookScript("OnHide", function(self)
				-- Apply or remove LUA if LuaEditor was closed and then refresh scroll table for visual effect 
				local rowData = ScrollTable.selected and ScrollTable:GetRow(ScrollTable.selected) 
				if rowData then 
					local oldCode = specDB.UnitIDs[rowData.unitID].LUA 
					local luaCode = self.EditBox:GetText()
														
					if luaCode ~= "" and not self.EditBox.LuaErrors then 		
						specDB.UnitIDs[rowData.unitID].LUA = luaCode
						rowData.IndexLUA = "ON"						
					else 
						specDB.UnitIDs[rowData.unitID].LUA = ""
						rowData.IndexLUA = "OFF"
					end 	
					
					if oldCode ~= specDB.UnitIDs[rowData.unitID].LUA then 		
						Action.Print(rowData.unitID .. (rowData.unitName ~= "" and " (" .. rowData.unitName .. ")" or "") .. " LUA: " .. rowData.IndexLUA)						
						ScrollTable:Refresh()
						TMW:Fire("TMW_ACTION_HEALING_ENGINE_UI_PROFILE", "Changed", "")
					end 
				end 
			end)
			-- If tab changed 
			anchor:HookScript("OnHide", function()
				LuaEditor.EditBox:SetText("")
				LuaEditor.closeBtn:Click()
			end)
		end
			
		if isHealer then 
			PriorityResetWidgets 				= {
				MultiplierIncomingDamageLimit 	= MultiplierIncomingDamageLimit, 	
				MultiplierThreat 				= MultiplierThreat,
				MultiplierPetsInCombat			= MultiplierPetsInCombat, 		
				MultiplierPetsOutCombat			= MultiplierPetsOutCombat,
				OffsetMode						= OffsetMode,
				OffsetSelfFocused				= OffsetSelfFocused, 		
				OffsetSelfUnfocused				= OffsetSelfUnfocused, 	
				OffsetSelfDispel				= OffsetSelfDispel,
				OffsetHealers					= OffsetHealers, 			
				OffsetTanks						= OffsetTanks, 			
				OffsetDamagers					= OffsetDamagers,
				OffsetHealersDispel				= OffsetHealersDispel, 	
				OffsetTanksDispel				= OffsetTanksDispel, 		
				OffsetDamagersDispel			= OffsetDamagersDispel,
				OffsetHealersShields			= OffsetHealersShields, 	
				OffsetTanksShields				= OffsetTanksShields, 	
				OffsetDamagersShields			= OffsetDamagersShields, 
				OffsetHealersHoTs				= OffsetHealersHoTs, 		
				OffsetTanksHoTs					= OffsetTanksHoTs, 		
				OffsetDamagersHoTs				= OffsetDamagersHoTs, 
				OffsetHealersUtils				= OffsetHealersUtils, 	
				OffsetTanksUtils				= OffsetTanksUtils, 		
				OffsetDamagersUtils				= OffsetDamagersUtils,
			}	
			ResetManaManagementWidges			= {
				ManaManagementManaBoss			= ManaManagementManaBoss,
				ManaManagementStopAtHP			= ManaManagementStopAtHP,
				ManaManagementStopAtTTD			= ManaManagementStopAtTTD,
				ManaManagementPredictVariation	= ManaManagementPredictVariation,
			}
		end 				
			
			-- Add PanelOptions					
			PanelOptions:AddRow({ margin = { top = 36 } }):AddElement(PredictOptions)
		if isHealer then 
			PanelOptions:AddRow({ margin = { top = 0  } }):AddElements(SelectStopOptions, 				SelectSortMethod, 												columnEven)
			PanelOptions:AddRow({ margin = { top = 10 } }):AddElements(AfterTargetEnemyOrBossDelay, 	AfterMouseoverEnemyDelay, 										columnEven)
			PanelOptions:AddRow({ margin = { top = -10, bottom = 5 } }):AddElements(HealingEngineAPI, 	SelectPets, 				SelectResurrects, 					columnFour)
		end 
			PanelOptions:DoLayout()
			anchor:AddRow({ margin = { left = -15, right = -15 } }):AddElement(PanelOptions)	

			-- Add PanelUnitIDs		
		if isHealer then 
			PanelUnitIDs:AddRow({ margin = { top = 25, left = -10, right = -10 } }):AddElement(ScrollTable)
			PanelUnitIDs:AddRow({ margin = { top = -10, bottom = 5 } }):AddElement(AutoHide)
			PanelUnitIDs:DoLayout()
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(PanelUnitIDs)
		end 

			-- Add PanelProfiles
		if isHealer then 			
			PanelProfiles:AddRow({ margin = { top = 35, left = 5, right = 5 } }):AddElement(Profile)
			PanelProfiles:AddRow({ margin = { top = -10, left = 5, right = 5 } }):AddElement(EditBoxProfile)
			PanelProfiles:AddRow({ margin = { top = -10, left = 5, right = 5, bottom = 10 } }):AddElements(SaveProfile, LoadProfile, RemoveProfile, 					columnFour)
			PanelProfiles:DoLayout()
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(PanelProfiles)
		end 
		
			-- Add PanelPriority		
		if isHealer then 				
			PanelPriority:AddRow({ margin = { top = 35 } }):AddElement(Multipliers)
			PanelPriority:AddRow({ margin = { top = 0, left = 5, right = 5 } }):AddElements(				MultiplierIncomingDamageLimit, 		MultiplierThreat, 							columnEven)
			PanelPriority:AddRow({ margin = { top = 10, left = 5, right = 5 } }):AddElements(				MultiplierPetsInCombat, 			MultiplierPetsOutCombat, 					columnEven)	
			PanelPriority:AddRow({ margin = { top = 10, left = 5, right = 5 } }):AddElement(Offsets)
			PanelPriority:AddRow({ margin = { top = 0, left = 5, right = 5 } }):AddElement(OffsetMode)
			PanelPriority:AddRow({ margin = { top = 10, left = 5, right = 5 } }):AddElements(				OffsetSelfFocused, 		OffsetSelfUnfocused, 	OffsetSelfDispel, 				columnFour)
			PanelPriority:AddRow({ margin = { top = 10, left = 5, right = 5 } }):AddElements(				OffsetHealers, 			OffsetTanks, 			OffsetDamagers, 				columnFour)
			PanelPriority:AddRow({ margin = { top = 10, left = 5, right = 5 } }):AddElements(				OffsetHealersDispel, 	OffsetTanksDispel, 		OffsetDamagersDispel, 			columnFour)
			PanelPriority:AddRow({ margin = { top = 10, left = 5, right = 5 } }):AddElements(				OffsetHealersShields, 	OffsetTanksShields, 	OffsetDamagersShields, 			columnFour)
			PanelPriority:AddRow({ margin = { top = 10, left = 5, right = 5 } }):AddElements(				OffsetHealersHoTs, 		OffsetTanksHoTs, 		OffsetDamagersHoTs, 			columnFour)
			PanelPriority:AddRow({ margin = { top = 10, left = 5, right = 5, bottom = 10 } }):AddElements(	OffsetHealersUtils, 	OffsetTanksUtils, 		OffsetDamagersUtils, 			columnFour)	
			PanelPriority:DoLayout()
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(PanelPriority)
		end 
			
			-- Add PanelManaManagement
		if isHealer then 				
			PanelManaManagement:AddRow({ margin = { top = 40, left = 5, right = 5 } }):AddElement(ManaManagementManaBoss)
			local PanelManaManagementRow = PanelManaManagement:AddRow({ margin = { top = 15, left = 5, right = 5 } })
			PanelManaManagementRow:AddElement(ManaManagementStopAtHP,	{ column = 5.5 })
			PanelManaManagementRow:AddElement(OR,						{ column = 1 })
			PanelManaManagementRow:AddElement(ManaManagementStopAtTTD,	{ column = 5.5 })
			PanelManaManagement:AddRow({ margin = { top = 15, left = 5, right = 5 } }):AddElement(ManaManagementPredictVariation)
			PanelManaManagement:DoLayout()
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(PanelManaManagement)				
		end 

			-- Add empty row 
			anchor:AddRow({ margin = { top = -5 } }):AddElement(StdUi:LayoutSpace(anchor))	
			
			-- Fix StdUi 			
			-- Lib is not optimized for resize since resizer changes only source parent, this is deep child parent 
			function anchor:DoLayout()
				local l = self.layout
				local width = tab.frame:GetWidth() - l.padding.left - l.padding.right

				local y = -l.padding.top
				for i = 1, #self.rows do
					local r = self.rows[i]
					y = y - r:DrawRow(width, y)
				end
			end		
			
			anchor:DoLayout()	
			anchor:SetScript("OnShow", TabUpdate)							
			
			-- If we had return back to this tab then handler will be skipped 
			if MainUI.RememberTab == tabName then
				TabUpdate()
			end										
		end 
		
		if tabName == 9 then
			UI_Title:Hide()	
			StdUi:EasyLayout(anchor)		
			
			local columnEven = { column = "even" }		
			local 	PanelFramework,
					MetaEnginePanel
			
			local function CreatePanel(title, gutter)
				local panel
				if title then 
					panel = StdUi:PanelWithTitle(anchor, StdUi:GetWidthByColumn(anchor, 12, 30), height or 1, title)	
					panel.titlePanel.label:SetFontSize(15)				
					StdUi:GlueTop(panel.titlePanel, panel, 0, -5)
				else 
					panel = StdUi:Panel(anchor, StdUi:GetWidthByColumn(anchor, 12, 30), height or 1)
				end 
				StdUi:EasyLayout(panel, { gutter = gutter, padding = { left = 0, right = 0, bottom = 5 } })

				-- Remap it to make resize able height and ignore for rows which aren't specified for healer 
				panel.DoLayout = function(self)
					if self.rows == nil then 
						return 
					end 
					
					-- Custom update kids of this panel to determine new total height
					MainUI.UpdateResizeForKids(self:GetChildrenWidgets())
					
					local l = self.layout;
					local width = self:GetWidth() - l.padding.left - l.padding.right;

					local y = -l.padding.top;
					for i = 1, #self.rows do
						local row = self.rows[i];
						y = y - row:DrawRow(width, y);
					end
					
					if title == "Meta Engine" or not self.hasConfiguredHeight then -- means what panel has ScrollTable which need to resize every time 
						self:SetHeight(-y)						 
						if title == "Meta Engine" then 
							self.hasConfiguredHeight = true 
						end 
					end
				end 
				
				return panel 
			end 			
			local function CreateCheckbox(parent, width, title, tooltip, rootDB, toggleName, useMacro)
				local checkbox = StdUi:Checkbox(parent, title, width or 150)
				checkbox:SetChecked(rootDB[toggleName])
				checkbox:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				checkbox:SetScript("OnClick", function(self, button, down)
					if not self.isDisabled then						
						if button == "LeftButton" then 
							rootDB[toggleName] = not rootDB[toggleName]	
							self:SetChecked(rootDB[toggleName])	
							if OnToggleHandler[tabName][toggleName] then 
								OnToggleHandler[tabName][toggleName]()
							end
							Action.Print(title .. ": ", rootDB[toggleName])			
						elseif button == "RightButton" and useMacro then 
							local nameDB = rootDB == specDB.MetaEngine and "MetaEngine" or "v2"
							Action.CraftMacro(title, [[/run Action.SetToggle({]] .. tabName .. [[, "]] .. nameDB .. [[", "]] .. title .. [[: "}, {]] .. toggleName .. [[ = not Action.GetToggle(]] .. tabName .. [[, "]] .. nameDB .. [[").]] .. toggleName .. [[})]])	
						end						
					end 
				end)					 
				checkbox.Identify = { Type = "Checkbox", Toggle = toggleName }	
				if tooltip then 
					StdUi:FrameTooltip(checkbox, tooltip, nil, "TOP", true)
				end 
				return checkbox			
			end 
			
			-- UI: PanelFramework
			PanelFramework = CreatePanel(L["TAB"][tabName]["FRAMEWORK"])	
			
			-- UI: PanelFramework - Category
			PanelFramework.Category = StdUi:Dropdown(anchor, StdUi:GetWidthByColumn(PanelFramework, 12), themeHeight, {
				{ text = "v1", value = "v1" },
				{ text = "Meta Engine", value = "MetaEngine" },
			--	{ text = "v2", value = "v2" },				
			}, specDB.Framework)	
			PanelFramework.Category:SetScript("OnClick", function(self, button)
				if InCombatLockdown() then
					if self.optsFrame:IsVisible() then 
						self:ToggleOptions()
					end 
				else
					self:ToggleOptions()
				end
			end)
			PanelFramework.Category.OnValueChanged = function(self, value)
				specDB.Framework = value
				MetaEnginePanel:SetShown(value == "MetaEngine")
				if value == "MetaEngine" then
					MetaEnginePanel.ScrollTable.MakeUpdate()
				end
				TMW:Fire("TMW_ACTION_METAENGINE_RECONFIGURE")
			end
			PanelFramework.Category.text:SetJustifyH("CENTER")				
			
			------------------------------------- 
			-- MetaEngine
			--	
			local function UpdateMetaEngineCheckboxes()
				local rootDB = specDB.MetaEngine
				for childName, childFrame in pairs(MetaEnginePanel) do
					if type(childFrame) == "table" and childFrame.Identify and childFrame.Identify.Type == "Checkbox" and childFrame:GetChecked() ~= rootDB[childFrame.Identify.Toggle] then
						childFrame:SetChecked(rootDB[childFrame.Identify.Toggle], true)
						OnToggleHandler[tabName][childFrame.Identify.Toggle]()
					end
				end					
			end 
			local function DrawMetaEngine()				
				if Action.MetaEngine and Action.MetaEngine:IsSafe() then
					-- Add MetaEngine					
					for i = 1, #PanelFramework.Category.options do
						if PanelFramework.Category.options[i].value == "MetaEngine" then
							MetaEnginePanel:SetShown(specDB.Framework == "MetaEngine")
							if specDB.Framework == "MetaEngine" then
								MetaEnginePanel.ScrollTable.MakeUpdate()
								UpdateMetaEngineCheckboxes()
							end
							return
						end
					end
					
					PanelFramework.Category.options[#PanelFramework.Category.options + 1] = { text = "Meta Engine", value = "MetaEngine" }
					PanelFramework.Category:SetOptions(PanelFramework.Category.options)
					PanelFramework.Category:SetValue(specDB.Framework)
					MetaEnginePanel.ScrollTable.MakeUpdate()
					UpdateMetaEngineCheckboxes()
				else 
					-- Remove MetaEngine
					for i = 1, #PanelFramework.Category.options do
						if PanelFramework.Category.options[i].value == "MetaEngine" then
							tremove(PanelFramework.Category.options, i)
							PanelFramework.Category:SetOptions(PanelFramework.Category.options)
							PanelFramework.Category:SetValue(specDB.Framework ~= "MetaEngine" and specDB.Framework or PanelFramework.Category.options[#PanelFramework.Category.options].value)					
						end
					end				
				end			
			end
			local function SetBindMetaEngine(bind)
				if InCombatLockdown() then
					A_Print(L["TAB"][tabName]["ASSIGNINCOMBAT"])
					return
				end
				
				local index = MetaEnginePanel.ScrollTable:GetSelection()
				local rowData = index and MetaEnginePanel.ScrollTable:GetRow(index) or nil					
				if rowData and bind ~= MetaEnginePanel.KeybindWindow.bindOld then
					-- Find and remove bind if assigned on something else
					for _, v in pairs(specDB.MetaEngine.Hotkeys) do
						if v.hotkey == bind then
							v.hotkey = ""
						end
					end
				
					rowData.Hotkey = bind
					specDB.MetaEngine.Hotkeys[rowData.Slot].hotkey = bind
					
					MetaEnginePanel.ScrollTable:Refresh()				
					TMW:Fire("TMW_ACTION_METAENGINE_REASSIGN", rowData.Slot, bind)
				end
			end
			
			-- UI: MetaEngine
			MetaEnginePanel = CreatePanel("Meta Engine")
			
			-- UI: MetaEngine - ScrollTable
			MetaEnginePanel.OnClickCell = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)	
				table:SetSelection(rowIndex)
				MetaEnginePanel.KeybindWindow.bindOld = rowData.Hotkey
				MetaEnginePanel.KeybindWindow.bind = rowData.Hotkey
				MetaEnginePanel.KeybindWindow:SetWindowTitle(rowData.Action)
				MetaEnginePanel.KeybindWindow.messageLabel:SetText(rowData.Hotkey ~= "" and GetBindingText(rowData.Hotkey) or L["TAB"][tabName]["HOTKEYINSTRUCTION"])
				
				return true -- prevents deselect row
			end
			MetaEnginePanel.OnDoubleClickCell = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex, button)
				table:SetSelection(rowIndex)
				if button == "LeftButton" then	
					MetaEnginePanel.KeybindWindow.bindOld = rowData.Hotkey
					MetaEnginePanel.KeybindWindow.bind = rowData.Hotkey
					MetaEnginePanel.KeybindWindow:SetWindowTitle(rowData.Action)
					MetaEnginePanel.KeybindWindow.messageLabel:SetText(rowData.Hotkey ~= "" and GetBindingText(rowData.Hotkey) or L["TAB"][tabName]["HOTKEYINSTRUCTION"])
					MetaEnginePanel.KeybindWindow:Show()
				elseif button == "RightButton" then
					SetBindMetaEngine("")
					MetaEnginePanel.KeybindWindow:Hide()					
				end
			end
			MetaEnginePanel.OnEnterCell = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
				StdUi:ShowTooltip(cellFrame, true, L["TAB"][tabName]["METAENGINEROWTT"])
				GameTooltip:ClearAllPoints()
				StdUi:GlueAbove(GameTooltip, cellFrame, cellFrame:GetWidth(), 0, "RIGHT")
			end
			MetaEnginePanel.OnLeaveCell = function(table, cellFrame, rowFrame, rowData, columnData, rowIndex)
				StdUi:ShowTooltip(cellFrame, false)
			end
			MetaEnginePanel.OnClickHeader = function(table, columnFrame, columnHeadFrame, columnIndex, button, ...)
				table.SORTBY = columnIndex
			end			
			MetaEnginePanel.ScrollTable = StdUi:ScrollTable(MetaEnginePanel, { 
				{
					name = L["TAB"][tabName]["META"],
                    width = 60,
                    align = "CENTER",
                    index = "Meta",
					defaultSort = "desc", -- StdUi has bug with sorting, desc is actually asc
                    format = "number",					
				},
				{
					name = L["TAB"][tabName]["ACTION"],
                    width = 200,
                    align = "LEFT",
                    index = "Action",
                    format = "string",
				},
				{
					name = L["TAB"][tabName]["HOTKEY"],
                    width = 214,
					defaultwidth = 214,
                    align = "CENTER",
                    index = "Hotkey",
                    format = "custom",
					renderer = function(cellFrame, value, rowData, columnData)
						local slot = rowData.Slot
						local hotkey = specDB.MetaEngine.Hotkeys[slot].hotkey
						
						if not cellFrame.texture then
							local table = MetaEnginePanel.ScrollTable
							local iconSize = columnData.iconSize or table.rowHeight
							cellFrame.texture = table.stdUi:Texture(cellFrame, iconSize, iconSize, value)
							cellFrame.texture:SetPoint("RIGHT", -15, 0)
						end 
						
						if hotkey ~= "" then
							cellFrame.text:SetText(GetBindingText(hotkey))
							cellFrame.texture:SetTexture(nil)
						else
							cellFrame.text:SetText("")
							cellFrame.texture:SetTexture("Interface/MacroFrame/MacroFrame-Icon.blp")
						end						
					end,
				},
            }, 15, 25)	
			MetaEnginePanel.ScrollTable:RegisterEvents(
				{ OnClick = MetaEnginePanel.OnClickCell, OnDoubleClick = MetaEnginePanel.OnDoubleClickCell, OnEnter = MetaEnginePanel.OnEnterCell, OnLeave = MetaEnginePanel.OnLeaveCell },
				{ OnClick = MetaEnginePanel.OnClickHeader }
			)
			MetaEnginePanel.ScrollTable.SORTBY = 1
			MetaEnginePanel.ScrollTable.defaultrows = { numberOfRows = MetaEnginePanel.ScrollTable.numberOfRows, rowHeight = MetaEnginePanel.ScrollTable.rowHeight }
			MetaEnginePanel.ScrollTable:EnableSelection(true)
			MetaEnginePanel.ScrollTable.MakeUpdate = function()
				local self = MetaEnginePanel.ScrollTable
				if not anchor:IsShown() or self.IsUpdating then -- anchor here because it's scroll child and methods :IsVisible and :IsShown can skip it in theory 
					return 
				end
				
				self.IsUpdating = true 
				if not self.data then 
					self.data = {}
				else 
					wipe(self.data)
				end 

				for slot, v in pairs(specDB.MetaEngine.Hotkeys) do
					tinsert(self.data, {
						Slot = slot,
						Meta = v.meta,
						Action = v.action,
						Hotkey = v.hotkey,						
					})
				end
				
				self:ClearSelection()			
				self:SetData(self.data)
				self:SortData(self.SORTBY)
				self.IsUpdating = nil 
			end
			StdUi:ClipScrollTableColumn(MetaEnginePanel.ScrollTable, 35)

			-- UI: MetaEngine - KeybindWindow
			MetaEnginePanel.KeybindWindow = StdUi:Confirm(L["TAB"][tabName]["HOTKEY"], L["TAB"][tabName]["HOTKEYINSTRUCTION"], {				
				Unassign = {
					text    = L["TAB"][tabName]["HOTKEYUNASSIGN"],
					onClick = function(self)
						SetBindMetaEngine("")
						self.window:Hide()
					end,
				},
				Assign = {
					text    = L["TAB"][tabName]["HOTKEYASSIGN"],
					onClick = function(self)
						SetBindMetaEngine(self.window.bind)
						self.window:Hide()
					end,
				},
			})
			StdUi:SetObjSize(MetaEnginePanel.KeybindWindow.buttons.Unassign, 140, 40)
			MetaEnginePanel.KeybindWindow.buttons.Unassign:ClearAllPoints()
			StdUi:GlueBottom(MetaEnginePanel.KeybindWindow.buttons.Unassign, MetaEnginePanel.KeybindWindow, 5 + MetaEnginePanel.KeybindWindow.buttons.Unassign:GetWidth() / 2, 15)
			
			StdUi:SetObjSize(MetaEnginePanel.KeybindWindow.buttons.Assign, 140, 40)
			MetaEnginePanel.KeybindWindow.buttons.Assign:ClearAllPoints()
			StdUi:GlueBottom(MetaEnginePanel.KeybindWindow.buttons.Assign, MetaEnginePanel.KeybindWindow, -5 - MetaEnginePanel.KeybindWindow.buttons.Assign:GetWidth() / 2, 15)
			
			MetaEnginePanel.KeybindWindow.messageLabel:SetFontSize(16)
			MetaEnginePanel.KeybindWindow.backdrop = { MetaEnginePanel.KeybindWindow:GetBackdropColor() }
			MetaEnginePanel.KeybindWindow.backdrop[4] = 0.95 -- Alpha, default: 0.8
			MetaEnginePanel.KeybindWindow:SetBackdropColor(unpack(MetaEnginePanel.KeybindWindow.backdrop))
			MetaEnginePanel.KeybindWindow:SetParent(MetaEnginePanel)
			MetaEnginePanel.KeybindWindow:SetFrameStrata("DIALOG")
			MetaEnginePanel.KeybindWindow:SetSize(700, 230)
			MetaEnginePanel.KeybindWindow:SetShown(false)		
			MetaEnginePanel.KeybindWindow:SetMovable(false)
			MetaEnginePanel.KeybindWindow:RegisterForDrag("")
			MetaEnginePanel.KeybindWindow:SetScript("OnDragStart", nil)
			MetaEnginePanel.KeybindWindow:SetScript("OnDragStop", nil)
			MetaEnginePanel.KeybindWindow:EnableKeyboard(true)
			MetaEnginePanel.KeybindWindow:EnableGamePadButton(true)	
			MetaEnginePanel.KeybindWindow.IgnoredKeyOrButton = {
				LeftButton = true,
				RightButton = true,
				BUTTON1 = true,
				BUTTON2 = true,
				UNKNOWN = true,
				ESCAPE = true,
				LSHIFT = true,
				RSHIFT = true,
				LCTRL = true,
				RCTRL = true,
				LALT = true,
				RALT = true,
				LMETA = true,
				RMETA = true,
				LSTRG = true,
				RSTRG = true,
			}
			MetaEnginePanel.KeybindWindow.ButtonFormat = {
				LeftButton = "BUTTON1",
				RightButton = "BUTTON2",
				MiddleButton = "BUTTON3",	
				[1] = "MOUSEWHEELUP",
				[-1] = "MOUSEWHEELDOWN",
			}
			MetaEnginePanel.KeybindWindow.OnButton = function(self, keyOrButton)
				if keyOrButton == "ESCAPE" then
					self:Hide()
					return
				end
				
				if self.IgnoredKeyOrButton[keyOrButton] or GetBindingFromClick(keyOrButton) == "SCREENSHOT" then
					return
				end

				local keyPressed = self.ButtonFormat[keyOrButton] or keyOrButton	  
				if keyPressed then
					keyPressed = keyPressed:upper()
					-- Notes: That will be funny if STRG replaces CTRL on German and Austrian clients as bind modifier
					self.bind = strOnlyBuilder(IsAltKeyDown() and "ALT-" or "", IsControlKeyDown() and "CTRL-" or "", IsShiftKeyDown() and "SHIFT-" or "", keyPressed)
					self.messageLabel:SetText(GetBindingText(self.bind))
				end
			end
			MetaEnginePanel.KeybindWindow:SetScript("OnKeyDown", MetaEnginePanel.KeybindWindow.OnButton)
			MetaEnginePanel.KeybindWindow:SetScript("OnGamePadButtonDown", MetaEnginePanel.KeybindWindow.OnButton)
			MetaEnginePanel.KeybindWindow:SetScript("OnMouseDown", MetaEnginePanel.KeybindWindow.OnButton)
			MetaEnginePanel.KeybindWindow:SetScript("OnMouseWheel", MetaEnginePanel.KeybindWindow.OnButton)
			
			-- UI: MetaEngine - PrioritizePassive
			MetaEnginePanel.PrioritizePassive = CreateCheckbox(MetaEnginePanel, 100, L["TAB"][tabName]["PRIORITIZEPASSIVE"], L["TAB"][tabName]["PRIORITIZEPASSIVETT"], specDB.MetaEngine, "PrioritizePassive")

			-- UI: MetaEngine - checkselfcast
			MetaEnginePanel.checkselfcast = CreateCheckbox(MetaEnginePanel, 100, L["TAB"][tabName]["CHECKSELFCAST"], L["TAB"][tabName]["CHECKSELFCASTTT"], specDB.MetaEngine, "checkselfcast")
			
			-- UI: MetaEngine - raid
			MetaEnginePanel.raid = CreateCheckbox(MetaEnginePanel, 30, "@raid", L["TAB"][tabName]["UNITTT"], specDB.MetaEngine, "raid")
			
			-- UI: MetaEngine - party
			MetaEnginePanel.party = CreateCheckbox(MetaEnginePanel, 30, "@party", L["TAB"][tabName]["UNITTT"], specDB.MetaEngine, "party")
			
			-- UI: MetaEngine - arena
			MetaEnginePanel.arena = CreateCheckbox(MetaEnginePanel, 30, "@arena", L["TAB"][tabName]["UNITTT"], specDB.MetaEngine, "arena")
					
			-- Hides or shows panel with options
			TMW:RegisterCallback("TMW_ACTION_METAENGINE_REFRESH_UI", DrawMetaEngine)
			TMW:RegisterCallback("TMW_ACTION_METAENGINE_AUTH", DrawMetaEngine)
			DrawMetaEngine()
			
			
			------------------------------------- 
			-- Add PanelFramework
			PanelFramework:AddRow({ margin = { top = 25 } }):AddElement(PanelFramework.Category)
			PanelFramework:DoLayout()
			anchor:AddRow({ margin = { left = -15, right = -15 } }):AddElement(PanelFramework)	

			-- Add MetaEnginePanel
			MetaEnginePanel:AddRow({ margin = { top = 50, left = -10, right = -10 } }):AddElement(MetaEnginePanel.ScrollTable)
			MetaEnginePanel.CheckboxRow1 = MetaEnginePanel:AddRow({ margin = { top = -10, bottom = 5 } })
			MetaEnginePanel.CheckboxRow1:AddElement(MetaEnginePanel.PrioritizePassive, { column = 8 })
			MetaEnginePanel.CheckboxRow1:AddElement(MetaEnginePanel.checkselfcast, { column = 4 })
			MetaEnginePanel.CheckboxRow2 = MetaEnginePanel:AddRow({ margin = { top = -5, bottom = 5 } })
			MetaEnginePanel.CheckboxRow2:AddElement(MetaEnginePanel.raid, { column = 4 })
			MetaEnginePanel.CheckboxRow2:AddElement(MetaEnginePanel.party, { column = 4 })
			MetaEnginePanel.CheckboxRow2:AddElement(MetaEnginePanel.arena, { column = 4 })
			MetaEnginePanel:DoLayout()
			anchor:AddRow({ margin = { top = -10, left = -15, right = -15 } }):AddElement(MetaEnginePanel)
			
			-- Add empty row 
			anchor:AddRow({ margin = { top = -5 } }):AddElement(StdUi:LayoutSpace(anchor))	
			
			-- Fix StdUi 			
			-- Lib is not optimized for resize since resizer changes only source parent, this is deep child parent 
			function anchor:DoLayout()
				local l = self.layout
				local width = tab.frame:GetWidth() - l.padding.left - l.padding.right

				local y = -l.padding.top
				for i = 1, #self.rows do
					local r = self.rows[i]
					y = y - r:DrawRow(width, y)
				end
			end					
			
			anchor:DoLayout()	
			anchor:SetScript("OnShow", DrawMetaEngine)						
			
			-- If we had return back to this tab then handler will be skipped 
			if MainUI.RememberTab == tabName then
				DrawMetaEngine()
			end	
		end
		
		StdUi:EnumerateToggleWidgets(tab.childs[spec], anchor)		
	end)
end

-------------------------------------------------------------------------------
-- Debug  
-------------------------------------------------------------------------------
function Action.Print(text, bool, ignore)
	if not ignore and pActionDB and pActionDB[1] and pActionDB[1].DisablePrint then 
		return 
	end 
    DEFAULT_CHAT_FRAME:AddMessage(strjoin(" ", "|cff00ccffAction:|r", text .. (bool ~= nil and toStr[bool] or "")))
end

function Action.PrintHelpToggle()
	A_Print("|cff00cc66Shift+LeftClick|r " .. L["SLASH"]["TOTOGGLEBURST"])
	A_Print("|cff00cc66Ctrl+LeftClick|r " .. L["SLASH"]["TOTOGGLEMODE"])
	A_Print("|cff00cc66Alt+LeftClick|r " .. L["SLASH"]["TOTOGGLEAOE"])
end 

-------------------------------------------------------------------------------
-- Specializations
-------------------------------------------------------------------------------
-- TODO: Just temporary fix for low level characters until v2 release, have to make it better
local classSpecIds = {
	DRUID 				= {102,103,104,105}, -- Retail version
	HUNTER 				= {253,254,255},
	MAGE 				= {62,63,64},
	PALADIN 			= {65,66,70},
	PRIEST 				= {256,257,258},
	ROGUE 				= {259,260,261},
	SHAMAN 				= {262,263,264},
	WARLOCK 			= {265,266,267},
	WARRIOR 			= {71,72,73},
	DEATHKNIGHT 		= {250,251,252},
	MONK				= {268,270,269},
	DEMONHUNTER			= {577,581},
	EVOKER 				= {1467,1468,1473},
}; ActionData.classSpecIds = classSpecIds
local specs = {
	-- 4th index is localizedName of the specialization 
	[253]	= {"Beast Mastery", 461112, "DAMAGER"},
	[254]	= {"Marksmanship", 236179, "DAMAGER"},
	[255]	= {"Survival", 461113, "DAMAGER"},

	[71]	= {"Arms", 132355, "DAMAGER"},
	[72]	= {"Fury", 132347, "DAMAGER"},
	[73]	= {"Protection", 132341, "TANK"},

	[65]	= {"Holy", 135920, "HEALER"},
	[66]	= {"Protection", 236264, "TANK"},
	[70]	= {"Retribution", 135873, "DAMAGER"},

	[62]	= {"Arcane", 135932, "DAMAGER"},
	[63]	= {"Fire", 135810, "DAMAGER"},
	[64]	= {"Frost", 135846, "DAMAGER"},

	[256]	= {"Discipline", 135940, "HEALER"},
	[257]	= {"Holy", 237542, "HEALER"},
	[258]	= {"Shadow", 136207, "DAMAGER"},

	[265]	= {"Affliction", 136145, "DAMAGER"},
	[266]	= {"Demonology", 136172, "DAMAGER"},
	[267]	= {"Destruction", 136186, "DAMAGER"},

	[102]	= {"Balance", 136096, "DAMAGER"},
	[103]	= {"Feral", 132115, "DAMAGER"},
	[104]	= {"Guardian", 132276, "TANK"}, -- Retail version
	[105]	= {"Restoration", 136041, "HEALER"},

	[262]	= {"Elemental", 136048, "DAMAGER"},
	[263]	= {"Enhancement", 237581, "DAMAGER"},
	[264]	= {"Restoration", 136052, "HEALER"},

	[259]	= {"Assassination", 236270, "DAMAGER"},
	[260]	= {"Outlaw", 236286, "DAMAGER"},
	[261]	= {"Subtlety", 132320, "DAMAGER"},
	
	[250]	= {"Blood", 135770, "TANK"},
	[251]	= {"Frost", 135773, "DAMAGER"},
	[252]	= {"Unholy", 135775, "DAMAGER"},
	
	[268]	= {"Brewmaster", 608951, "TANK"},
	[270]	= {"Mistweaver", 608952, "DAMAGER"},
	[269]	= {"Windwalker", 608953, "DAMAGER"},
	
	[577]	= {"Havoc", 1247264, "DAMAGER"},
	[581]	= {"Vengeance", 1247265, "TANK"},
	
	[1467]	= {"Devastation", 4511811, "DAMAGER"},
	[1468]	= {"Preservation", 4511812, "HEALER"},
	[1473]	= {"Augmentation", 5198700, "HEALER"},
}; ActionData.specs = specs

function Action.GetCurrentSpecializationInfo() 
	-- @return specID, specName
	local specIDs = classSpecIds[Action.PlayerClass]
	
	local specID, specName
	for i = 1, #specIDs do
		if specs[specIDs[i]][3] == "DAMAGER" then 
			specID = specIDs[i]
			specName = specs[specIDs[i]][1]
		end
	end

	return specID, specName -- TODO: Localize specName
end

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------
local HealerSpecs 						= {
	[ActionConst.DRUID_RESTORATION]		= true, 
	[ActionConst.MONK_MISTWEAVER] 		= true, 
	[ActionConst.PALADIN_HOLY]  		= true, 
	[ActionConst.PRIEST_DISCIPLINE] 	= true, 
	[ActionConst.PRIEST_HOLY] 			= true, 
	[ActionConst.SHAMAN_RESTORATION] 	= true, 
	[ActionConst.EVOKER_PRESERVATION] 	= true, 
}; ActionData.HealerSpecs = HealerSpecs
local RangerSpecs 						= {
	--[ActionConst.PALADIN_HOLY] 		= true,
	[ActionConst.HUNTER_BEASTMASTERY]	= true,
	[ActionConst.HUNTER_MARKSMANSHIP]	= true,
	--[ActionConst.PRIEST_DISCIPLINE]	= true,
	--[ActionConst.PRIEST_HOLY]			= true,
	[ActionConst.PRIEST_SHADOW]			= true,
	[ActionConst.SHAMAN_ELEMENTAL]		= true,
	--[ActionConst.SHAMAN_RESTORATION]	= true,
	[ActionConst.MAGE_ARCANE]			= true,
	[ActionConst.MAGE_FIRE]				= true,
	[ActionConst.MAGE_FROST]			= true,
	[ActionConst.WARLOCK_AFFLICTION]	= true,
	[ActionConst.WARLOCK_DEMONOLOGY]	= true,	
	[ActionConst.WARLOCK_DESTRUCTION]	= true,	
	--[ActionConst.MONK_MISTWEAVER]		= true,	
	[ActionConst.DRUID_BALANCE]			= true,	
	--[ActionConst.DRUID_RESTORATION]	= true,	
	[ActionConst.EVOKER_DEVASTATION] 	= true,
}; ActionData.RangerSpecs = RangerSpecs
function Action:PLAYER_SPECIALIZATION_CHANGED(event, unit)
	Action.PlayerLevel = Action.PlayerLevel or UnitLevel("player")
	local PlayerLevel = Action.PlayerLevel
	
	local specID, specName
	if PlayerLevel >= 10 then 
		specID, specName = GetSpecializationInfo(GetSpecialization() or 0) 
	else
		specID, specName = Action.GetCurrentSpecializationInfo()
	end 
	
	if not specID or not specName then 
		-- This data can be nil if fired without receive information from server, so we will keep previous data saved if we have
		return 
	end 	
	
	local oldSpec	 = Action.PlayerSpec
	Action.PlayerSpec, Action.PlayerSpecName = specID, specName
    Action.IamHealer = HealerSpecs[Action.PlayerSpec]
	Action.IamRanger = Action.IamHealer or RangerSpecs[Action.PlayerSpec]
	Action.IamMelee  = not Action.IamRanger
		
	if oldSpec ~= Action.PlayerSpec then 
		if Action.IsInitialized then 
			-- Redraw tab container headers 
			if Action.MainUI then 
				if Action.MainUI:IsShown() then 
					A_ToggleMainUI()
					A_ToggleMainUI()
				end 
				-- Refresh title of spec 
				tabFrame.tabs[2].title = Action.PlayerSpecName
				tabFrame:DrawButtons()	
			end 
			
			-- Initialization ReTarget ReFocus 
			Re:Initialize()
			
			-- Initialization LOS System		
			LineOfSight:Initialize()
			
			-- Initialization Cursor  
			Cursor:Initialize()
			
			-- Initialization MSG System
			MSG:Initialize()						
		end 

		TMW:Fire("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", event, unit)		-- For MultiUnits, SpellLevel, HealingEngine
		TMW:Fire("TMW_ACTION_DEPRECATED")										-- TODO: Remove 
	end 
end
TMW:RegisterSelfDestructingCallback("TMW_DB_INITIALIZED", function()
	-- Note:
	-- "PLAYER_SPECIALIZATION_CHANGED" will not be fired if player joins in the instance with spec which is not equal to what was used before loading screen	
	-- "TMW_DB_INITIALIZED" callback fires after "PLAYER_LOGIN" but with same time so basically it's "PLAYER_LOGIN" with properly order
	Action:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	Action:RegisterEvent("PLAYER_ENTERING_WORLD", "PLAYER_SPECIALIZATION_CHANGED")
	Action:PLAYER_SPECIALIZATION_CHANGED("PLAYER_LOGIN")
	dbUpdate()
	return true -- Signal RegisterSelfDestructingCallback to unregister
end)

local function OnInitialize()	
	-- This function calls only if TMW finished EVERYTHING load
	-- This will initialize ActionDB for current profile by Action.Data.ProfileUI > Action.Data.ProfileDB (which in profile snippet)	
		
	-- Update local variables, fires 2 times here 
	dbUpdate()
	local profile 			= TMWdb:GetCurrentProfile()
	
	Action.IsInitialized 	= nil	
	Action.IsLockedMode 	= nil	
	Action.IsGGLprofile 	= profile:match("GGL") and true or false  	-- Don't remove it because this is validance for HealingEngine   
	Action.IsBasicProfile 	= profile == "[GGL] Basic"
	Action.CurrentProfile 	= profile	
	TMW:Fire("TMW_ACTION_DEPRECATED")									-- TODO: Remove 
	
	----------------------------------
	-- TMW CORE SNIPPETS FIX
	----------------------------------	
	-- Finally owner of TMW fixed it in 8.6.6
	if TELLMEWHEN_VERSIONNUMBER < 86603 and not Action.IsInitializedSnippetsFix then 
		-- TMW owner has trouble with ICON and GROUP PRE SETUP, he trying :setup() frames before lua snippets would be loaded 
		-- Yeah he has callback ON PROFILE to run it but it's POST handler which triggers AFTER :setup() and it cause errors for nil objects (coz they are in snippets :D which couldn't be loaded before frames)
		local function OnProfileFix()
			if not TMW.Initialized or not TMW.InitializedDatabase then
				return
			end		
			
			local snippets = {}
			for k, v in TMW:InNLengthTable(TMWdbprofile.CodeSnippets) do
				snippets[#snippets + 1] = v
			end 
			TMW:SortOrderedTables(snippets)
			for _, snippet in ipairs(snippets) do
				if snippet.Enabled and not TMW.SNIPPETS:HasRanSnippet(snippet) then
					TMW.SNIPPETS:RunSnippet(snippet)						
				end										
			end						      
		end	
		TMW:RegisterCallback("TMW_GLOBAL_UPDATE", OnProfileFix, "TMW_SNIPPETS_FIX")	
		Action.IsInitializedSnippetsFix = true 
	end 	
	
	----------------------------------
	-- Register Localization
	----------------------------------	
	A_GetLocalization()
	
	----------------------------------
	-- Profile Manipulation
	----------------------------------	
	local PlayerClass		= Action.PlayerClass
	local DefaultProfile 	= ActionData.DefaultProfile
	local ProfileEnabled	= ActionData.ProfileEnabled
	local ProfileUI			= ActionData.ProfileUI
	local ProfileDB			= ActionData.ProfileDB	
	
	-- Load default profile if current profile is generated as default
	local defaultprofile = UnitName("player") .. " - " .. GetRealmName()
	if profile == defaultprofile then 
		local AllProfiles = TMWdb.profiles
		if AllProfiles then 
			if DefaultProfile[PlayerClass] and AllProfiles[DefaultProfile[PlayerClass]] then 
				if TMW.Locked then 
					TMW:LockToggle()
				end 
				TMWdb:SetProfile(DefaultProfile[PlayerClass])
				return true -- Signal RegisterSelfDestructingCallback to unregister
			end		
		
			if AllProfiles[DefaultProfile["BASIC"]] then 
				if TMW.Locked then 
					TMW:LockToggle()
				end 
				TMWdb:SetProfile(DefaultProfile["BASIC"])
				return true -- Signal RegisterSelfDestructingCallback to unregister 
			end 	
		end 
	end 		
		
	-- Check if profile support Action
	if not ProfileEnabled[profile] then 
		LineOfSight:Initialize(Action.IsGGLprofile)	-- TODO: Remove (old profiles)
		
		if TMWdbprofile.ActionDB then 
			TMWdbprofile.ActionDB = nil
			
			-- Update local variables 
			dbUpdate()
			
			A_Print("|cff00cc66" .. profile .. " - profile.ActionDB|r " .. L["RESETED"]:lower())
		end 
		
		if Action.Minimap and LibDBIcon then 
			LibDBIcon:Hide("ActionUI")
		end 
		
		wipe(ProfileUI)
		wipe(ProfileDB)	
		Queue.OnEventToReset()

		ActionHasFinishedLoading = true 
		return true -- Signal RegisterSelfDestructingCallback to unregister 
	end 	 
	
	-- ProfileUI > ProfileDB creates template to merge in Factory after
	if type(ProfileUI) == "table" and next(ProfileUI) then 
		wipe(ProfileDB)
		-- Prevent developer's by mistake sensitive wrong assigns 
		if not ActionData.ReMapDB then 
			ActionData.ReMapDB 		= {
				["mouseover"] 		= "mouseover",
				["targettarget"] 	= "targettarget", 
				["focustarget"]		= "focustarget",
				["aoe"] 			= "AoE",
			}
		end 
		local ReMap = ActionData.ReMapDB
		
		local DB, DBV
		for i, tabVal in pairs(ProfileUI) do
			if type(i) == "number" and type(tabVal) == "table" then 							-- get tab 
				for specID, specVal in pairs(tabVal) do 										-- get spec in tab 	
					if not ProfileDB[i] 		then ProfileDB[i] = {} 			end 
					if not ProfileDB[i][specID] then ProfileDB[i][specID] = {} 	end 		
					
					if i == 2 then 																-- tab [2] for toggles 					
						for row = 1, #specVal do 												-- get row for spec in tab 						
							for element = 1, #specVal[row] do 									-- get element in row for spec in tab 
								DB = specVal[row][element].DB 
								if ReMap[strlowerCache[DB]] then 
									DB = ReMap[strlowerCache[DB]]
								end 
								
								DBV = specVal[row][element].DBV
								if DB ~= nil and DBV ~= nil then 								-- if default value for DB inside UI 
									ProfileDB[i][specID][DB] = DBV
								end 
							end						
						end
					end 
					
					if i == 7 then 																-- tab [7] for MSG 	
						if not ProfileDB[i][specID].msgList then ProfileDB[i][specID].msgList = {} end 	
						ProfileDB[i][specID].msgList = specVal
					end
				end 
			end 
		end 
	end 	
		
	-- profile	
	if not TMWdbprofile.ActionDB then 
		A_Print("|cff00cc66ActionDB.profile|r " .. L["CREATED"])
		Factory.Ver = #Upgrade.pUpgrades
	end	
	TMWdbprofile.ActionDB = tCompare(tMerge(Factory, ProfileDB, true), TMWdbprofile.ActionDB) 

	-- global
	if not TMWdbglobal.ActionDB then 		
		A_Print("|cff00cc66ActionDB.global|r " .. L["CREATED"])
		GlobalFactory.Ver = #Upgrade.gUpgrades
	end
	TMWdbglobal.ActionDB = tCompare(GlobalFactory, TMWdbglobal.ActionDB)
	
	-- Avoid lua errors with calls GetToggle 	
	ActionHasRunningDB = true 
	ActionHasFinishedLoading = true 
	-- Again, update local variables: pActionDB and gActionDB mostly 
	dbUpdate()	
	Upgrade:Perform()
	
	----------------------------------
	-- All remaps and additional sort DB 
	----------------------------------		
	-- Note: These functions must be call whenever relative settings in UI has been changed in their certain places!
	local DisableBlackBackground = A_GetToggle(1, "DisableBlackBackground")
	if DisableBlackBackground then 
		A_BlackBackgroundSet(not DisableBlackBackground)
	end 
	DispelPurgeEnrageRemap() -- [5] global -> profile
	
	----------------------------------	
	-- Welcome Notification
	----------------------------------	
    A_Print(L["SLASH"]["LIST"])
	A_Print("|cff00cc66/action|r - "  .. L["SLASH"]["OPENCONFIGMENU"])		
	A_Print("|cff00cc66/action help|r - " .. L["SLASH"]["HELP"])			
	A_Print("|cff00cc66/action toaster|r - " .. L["SLASH"]["OPENCONFIGMENUTOASTER"])	

	----------------------------------	
	-- Initialization
	----------------------------------	
	-- Initialization ColorPicker 
	ColorPicker:Initialize()
	
	-- Initialization ReTarget ReFocus 
	Re:Initialize()
	
	-- Initialization ScreenshotHider
	ScreenshotHider:Initialize()
	
	-- Initialization LOS System
	LineOfSight:Initialize()
	
	-- Initialization MacroAPI
	MacroAPI:Initialize()	
	
	-- Initialization SpellLevel if it was selected in db or player level lower than MAX on this expansion	
	SpellLevel:Initialize()
	
	-- Initialization Cursor  
	Cursor:Initialize()
	
	-- Initialization MSG System
	MSG:Initialize()
	
	-- Minimap
	if not Action.Minimap and LibDBIcon then 
		local ldbObject = {
			type = "launcher",
			icon = ActionConst.AUTOTARGET, 
			label = "ActionUI",
			OnClick = function(self, button)
				if button == "RightButton" and Action.Toaster.IsInitialized then 
					Action.Toaster:Toggle()
				else 
					A_ToggleMainUI()
				end 
			end,
			OnTooltipShow = function(tooltip)
				tooltip:AddLine("ActionUI")
			end,
		}
		LibDBIcon:Register("ActionUI", ldbObject, gActionDB.minimap)
		LibDBIcon:Refresh("ActionUI", gActionDB.minimap)
		Action.Minimap = true 
		A_ToggleMinimap()
	else
		A_ToggleMinimap(A_GetToggle(1, "Minimap"))
	end 
		
	-- Modified update engine of TMW core with additional FPS Optimization	
	if not Action.IsInitializedModifiedTMW and TMW then
		-- [[ REMAP ]]
		local IconsToUpdate 	= TMW.IconsToUpdate
		local GroupsToUpdate 	= TMW.GroupsToUpdate	
		local UpdateGlobals		= TMW.UpdateGlobals
		local Locked, Time, FPS, Framerate
		-- 
	
		local LastUpdate = 0
		local updateInProgress, shouldSafeUpdate
		local start, group, icon, ConditionObject
		-- Assume in combat unless we find out otherwise.
		local inCombatLockdown = 1

		-- Limit in milliseconds for each OnUpdate cycle.
		local CoroutineLimit = 50
		
		TMW:RegisterEvent("UNIT_FLAGS", function(event, unit)
			if unit == "player" then
				inCombatLockdown = InCombatLockdown()
			end
		end)	
		
		local function checkYield()
			if inCombatLockdown and debugprofilestop() - start > CoroutineLimit then
				TMW:Debug("OnUpdate yielded early at %s", Time)

				coroutine.yield()
			end
		end	

		-- This is the main update engine of TMW.
		local function OnUpdate()
			while true do
				UpdateGlobals()
				TMW.GCD  = TMW.GCD or GetGCD() 	-- Update GCD: 02/09/2024 is no longer in TMW 
				Locked = TMW.Locked				-- custom 
				Time = TMW.time 				-- custom

				if updateInProgress then
					-- If the previous update cycle didn't finish (updateInProgress is still true)
					-- then we should enable safecalling icon updates in order to prevent catastrophic failure of the whole addon
					-- if only one icon or icon type is malfunctioning.
					if not shouldSafeUpdate then
						TMW:Debug("Update error detected. Switching to safe update mode!")
						shouldSafeUpdate = true
					end
				end
				updateInProgress = true
				
				TMW:Fire("TMW_ONUPDATE_PRE", Time, Locked)
				-- FPS Optimization
				FPS = A_GetToggle(1, "FPS")
				if not FPS or FPS < 0 then 
					Framerate = GetFramerate() or 0
					if Framerate > 0 and Framerate < 100 then
						FPS = (100 - Framerate) / 900
						if FPS < 0.04 then 
							FPS = 0.04
						end 
					else
						FPS = 0.03
					end					
				end 				
				TMW.UPD_INTV = FPS + 0.001					
			
				if LastUpdate <= Time - TMW.UPD_INTV then
					LastUpdate = Time
					if TMW.profilingEnabled and TellMeWhen_CpuProfileDialog:IsShown() then 
						TMW:CpuProfileReset()
					end 

					TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_PRE", Time, Locked)
					
					if Locked then
						for i = 1, #GroupsToUpdate do
							-- GroupsToUpdate only contains groups with conditions
							group = GroupsToUpdate[i]
							ConditionObject = group and group.ConditionObject -- Fix for default engine 
							if ConditionObject and (ConditionObject.UpdateNeeded or ConditionObject.NextUpdateTime < Time) then
								ConditionObject:Check()

								if inCombatLockdown then checkYield() end
							end
						end
				
						if shouldSafeUpdate then
							for i = 1, #IconsToUpdate do
								icon = IconsToUpdate[i]
								safecall(icon.Update, icon)
								if inCombatLockdown then checkYield() end
							end
						else
							for i = 1, #IconsToUpdate do
								--local icon = IconsToUpdate[i]
								IconsToUpdate[i]:Update()

								-- inCombatLockdown check here to avoid a function call.
								if inCombatLockdown then checkYield() end
							end
						end
					end

					TMW:Fire("TMW_ONUPDATE_TIMECONSTRAINED_POST", Time, Locked)
				end

				updateInProgress = nil
				
				if inCombatLockdown then checkYield() end

				TMW:Fire("TMW_ONUPDATE_POST", Time, Locked)

				coroutine.yield()
			end
		end 

		local Coroutine 
		local OriginalOnUpdate = TMW.OnUpdate 
		function TMW:OnUpdate()
			start = debugprofilestop()			
			
			if not Coroutine or coroutine.status(Coroutine) == "dead" then
				if Coroutine then
					TMW:Debug("Rebirthed OnUpdate coroutine at %s", TMW.time)
				end
				
				Coroutine = coroutine.create(OnUpdate)
			end
			
			assert(coroutine.resume(Coroutine))
		end

		local function CheckInterval()
			if Action.IsInitialized then 				
				if TMW:GetScript("OnUpdate") ~= TMW.OnUpdate then 
					TMW:SetScript("OnUpdate", TMW.OnUpdate)
				end 
			else 
				if TMW:GetScript("OnUpdate") ~= OriginalOnUpdate then 
					TMW:SetScript("OnUpdate", OriginalOnUpdate)
				end 
			end 
		end
		
		TMW:RegisterCallback("TMW_SAFESETUP_COMPLETE", 		CheckInterval) 
		TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", 	CheckInterval) 
		TMW:RegisterCallback("TMW_ACTION_ON_PROFILE_POST", 	CheckInterval) 
		
		local isIconEditorHooked
		hooksecurefunc(TMW, "LockToggle", function() 
			if not isIconEditorHooked then 
				TellMeWhen_IconEditor:HookScript("OnHide", function() 
					if TMW.Locked then 
						CheckInterval()						
					end 
				end)
				isIconEditorHooked = true
			end
			if TMW.Locked then
				CheckInterval()
			end 			
		end)			
		
		-- Loading options 
		if TMW.Classes.Resizer_Generic == nil then 
			TMW:LoadOptions()
		end 		
		
		Action.IsInitializedModifiedTMW = true 
	end 		
			
	-- Make frames work able 
	TMW:Fire("TMW_ACTION_IS_INITIALIZED_PRE", pActionDB, gActionDB)
	Action.IsInitialized = true 
	TMW:Fire("TMW_ACTION_IS_INITIALIZED", pActionDB, gActionDB)	
	return true -- Signal RegisterSelfDestructingCallback to unregister
end
local function OnRemap()
	MacroLibrary						= LibStub("MacroLibrary")	
	A_Player							= Action.Player 			
	A_Unit 								= Action.Unit		
	A_UnitInLOS							= Action.UnitInLOS
	A_FriendlyTeam						= Action.FriendlyTeam
	A_EnemyTeam							= Action.EnemyTeam
	A_TeamCacheFriendlyUNITs			= Action.TeamCache.Friendly.UNITs
	A_Listener							= Action.Listener		
	A_SetToggle							= Action.SetToggle
	A_GetToggle							= Action.GetToggle
	A_GetLocalization					= Action.GetLocalization
	A_Print								= Action.Print
	A_MacroQueue						= Action.MacroQueue
	A_IsActionTable						= Action.IsActionTable
	A_OnGCD								= Action.OnGCD	
	A_IsActiveGCD						= Action.IsActiveGCD
	A_GetGCD							= Action.GetGCD
	A_GetCurrentGCD						= Action.GetCurrentGCD
	A_GetSpellInfo						= Action.GetSpellInfo
	A_IsQueueRunningAuto				= Action.IsQueueRunningAuto
	A_WipeTableKeyIdentify				= Action.WipeTableKeyIdentify
	A_GetActionTableByKey				= Action.GetActionTableByKey
	A_ToggleMainUI						= Action.ToggleMainUI
	A_ToggleMinimap						= Action.ToggleMinimap
	A_MinimapIsShown					= Action.MinimapIsShown
	A_BlackBackgroundIsShown			= Action.BlackBackgroundIsShown
	A_BlackBackgroundSet				= Action.BlackBackgroundSet
	A_InterruptGetSliders				= Action.InterruptGetSliders
	A_InterruptIsON						= Action.InterruptIsON
	A_InterruptIsBlackListed			= Action.InterruptIsBlackListed
	A_InterruptEnabled					= Action.InterruptEnabled
	A_AuraGetCategory					= Action.AuraGetCategory
	A_AuraIsON							= Action.AuraIsON
	A_AuraIsBlackListed					= Action.AuraIsBlackListed
	toStr								= Action.toStr
	round 								= _G.round					
	Interrupts.SmartInterrupt 			= Action.MakeFunctionCachedStatic(Interrupts.SmartInterrupt)		
	strOnlyBuilder						= Action.strOnlyBuilder
end 

function Action:ADDON_LOADED(event, addonName)	
	----------------------------------
	-- OnLoading 
	----------------------------------
	if addonName ~= ActionConst.ADDON_NAME then return end  
	self:UnregisterEvent(event)
	self.baseName = addonName
	----------------------------------
	-- Remap
	----------------------------------
	OnRemap()
	----------------------------------
	-- Register Slash Commands
	----------------------------------
	_G.SLASH_ACTION1 = "/action"
	_G.SlashCmdList.ACTION = function(input) 
		if not L then return end -- If we trying show UI before DB finished load locales 
		if not ActionData.ProfileEnabled[Action.CurrentProfile] then 
			A_Print(Action.CurrentProfile .. " " .. L["NOSUPPORT"])
			return 
		end 
		if not input or #input > 0 then 
			if input:lower() == "toaster" and Action.Toaster.IsInitialized then 
				Action.Toaster:Toggle()
			else 
				A_Print(L["SLASH"]["LIST"])
				A_Print("|cff00cc66/action|r - " .. L["SLASH"]["OPENCONFIGMENU"])
				A_Print("|cff00cc66/action toaster|r - " .. L["SLASH"]["OPENCONFIGMENUTOASTER"])
				A_Print('|cff00cc66/run Action.MacroQueue("TABLE_NAME")|r - ' .. L["SLASH"]["QUEUEHOWTO"])
				A_Print('|cff00cc66/run Action.MacroQueue("WordofGlory")|r - ' .. L["SLASH"]["QUEUEEXAMPLE"])		
				A_Print('|cff00cc66/run Action.MacroBlocker("TABLE_NAME")|r - ' .. L["SLASH"]["BLOCKHOWTO"])
				A_Print('|cff00cc66/run Action.MacroBlocker("FelRush")|r - ' .. L["SLASH"]["BLOCKEXAMPLE"])	
				A_Print(L["SLASH"]["RIGHTCLICKGUIDANCE"])
				A_Print(L["SLASH"]["INTERFACEGUIDANCE"])
				A_Print(L["SLASH"]["INTERFACEGUIDANCEEACHSPEC"])
				A_Print(L["SLASH"]["INTERFACEGUIDANCEALLSPECS"])
				A_Print(L["SLASH"]["INTERFACEGUIDANCEGLOBAL"])
				A_Print(L["SLASH"]["ATTENTION"])
			end 
		else 
			A_ToggleMainUI()
		end 
	end 	
	----------------------------------
	-- Register ActionDB defaults
	----------------------------------	
	local function OnSwap(event, profileEvent, arg2, arg3)	
		Action.IsInitialized = nil		
		-- If we have activated features from previous profile 
		if ActionHasRunningDB then 	
			-- Reset Queue
			Queue:OnEventToReset() 
			-- ReFocus ReTarget 
			Re:Reset()
			-- ScreenshotHider - Only here!!
			ScreenshotHider:Reset()
			-- LOS System 
			LineOfSight:Reset()
			-- SpellLevel
			SpellLevel:Reset()
			-- MacroAPI
			MacroAPI:Reset()
			-- Cursor 
			Cursor:Reset()
			-- MSG System 
			MSG:Reset()
		end 		
		ActionHasRunningDB = nil 
		ActionHasFinishedLoading = nil 
		
		-- Turn off everything 
		if Action.MainUI and Action.MainUI:IsShown() then 
			A_ToggleMainUI()
		end
		
		-- TMW has wrong condition which prevent run already running snippets and it cause issue to refresh same variables as example, so let's fix this 
		-- Note: Can cause issues if there loops, timers, frames or hooks 	
		if profileEvent == "OnProfileChanged" then
			-- Need manual update it one more time here 
			Action.CurrentProfile = TMW.db:GetCurrentProfile()
		
			local snippets = {}
			for k, v in TMW:InNLengthTable(TMW.db.profile.CodeSnippets) do -- Don't touch here TMW.db.profile.CodeSnippets, locales aren't refreshed by dbUpdate at this step!!
				snippets[#snippets + 1] = v
			end 
			TMW:SortOrderedTables(snippets)
			for _, snippet in ipairs(snippets) do
				if snippet.Enabled and TMW.SNIPPETS:HasRanSnippet(snippet) then
					TMW.SNIPPETS:RunSnippet(snippet)						
				end										
			end
			
			-- Wipe childs otherwise it will cause bug what changed profile will use frames by previous profile 
			if Action.MainUI then 
				tabFrame:EnumerateTabs(function(tab)
					if tab.childs then 
						for k in pairs(tab.childs) do
							tab.childs[k]:Hide() 
						end	
						wipe(tab.childs)
					end
				end)
			end 
		end 	
		
		OnInitialize()		
		TMW:Fire("TMW_ACTION_ON_PROFILE_POST") -- Callback for HybridProfile.lua (don't remove in future)
	end
	TMW:RegisterCallback("TMW_ON_PROFILE", OnSwap)
	TMW:RegisterSelfDestructingCallback("TMW_SAFESETUP_COMPLETE", OnInitialize)	
end
Action:RegisterEvent("ADDON_LOADED")