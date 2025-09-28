local TMW 									= _G.TMW
local GetSpellTexture						= TMW.GetSpellTexture

local A 									= _G.Action
local wipe									= _G.wipe
local tostringall							= _G.tostringall

local GetSpellBaseCooldown				 	= _G.GetSpellBaseCooldown
local GetSpellDescription					= _G.C_Spell.GetSpellDescription
local GetSpellInfo							= _G.C_Spell.GetSpellInfo

function UpdateTriggerGCD()
	if TMW.db.global.TriggerGCD then 
		wipe(TMW.db.global.TriggerGCD)
	else 
		TMW.db.global.TriggerGCD = {}
	end 
	local TriggerGCD = TMW.db.global.TriggerGCD
	
	local spellInfo, spellName, spellID, base, baseGCD
	for i = 1, 1000000 do 
		spellInfo = GetSpellInfo(i)
		if spellInfo then
			spellName, spellID = spellInfo.name, spellInfo.spellID
			if spellID == i and spellName:find("[\128-\255]") and GetSpellTexture(spellID) then 
				if GetSpellDescription(spellID) then 
					base, baseGCD = GetSpellBaseCooldown(spellID)
					if base and baseGCD then 
						TriggerGCD[tostringall(i .. "	")] = baseGCD
						-- RegEx (\d)\s("]) => $1]
					end 
				end 
			end
		end
	end 
	
	A.Print("TriggerGCD updated!")
end 