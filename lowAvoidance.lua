local L = setmetatable({}, {__index=function(t,i) return i end})

local result = {
	miss     = 0,
	dodge    = 0,
	parry    = 0,
	block    = 0,
	critical = 0,
	crushing = 0,
	hit      = 0,
}

local talentedcritreduct = 0;
local targetlevel = 70;

local dataobj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("lowAvoidance", {icon = "Interface\\Icons\\Ability_Defend", text = "|cffff0000"..L["Critable"].."|r"})

local f = CreateFrame("Frame")

f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

local function UpdateHitTable()
	local level = UnitLevel("player");
	targetlevel = level + 3;
	if UnitExists("target") then targetlevel = UnitLevel("target"); end

	local defbase, defbonus = UnitDefense("player");
	local defskillmod = (defbase + defbonus - targetlevel * 5) * 0.04;
	local leveldiff = targetlevel - level;

	result.miss = max(5 + defskillmod, 0);
	result.dodge = GetDodgeChance() - leveldiff * 0.2;
	result.parry = GetParryChance() - leveldiff * 0.2;
	result.block = GetBlockChance() - leveldiff * 0.2;
	result.critical = max(5 - defskillmod - talentedcritreduct - GetCombatRatingBonus(CR_CRIT_TAKEN_MELEE), 0);
	result.crushing = max(10 * leveldiff - 15, 0);
	result.hit = 0;

	local mainhand = GetInventoryItemLink("player", 16);
	if not mainhand then result.parry = 0; else
		local _, _, _, _, _, _, _, _, mainhandtype = GetItemInfo(mainhand);
		if (mainhandtype ~= "INVTYPE_WEAPON") and (mainhandtype ~= "INVTYPE_WEAPONMAINHAND") and (mainhandtype ~= "INVTYPE_2HWEAPON") then
			result.parry = 0;
		end
	end

	local offhand = GetInventoryItemLink("player", 17);
	if not offhand then result.block = 0; else
		local _, _, _, _, _, _, _, _, offhandtype = GetItemInfo(offhand);
		if offhandtype ~= "INVTYPE_SHIELD" then result.block = 0; end
	end

	local leftover = 100;

	result.miss = min(result.miss, leftover);
	leftover = leftover - result.miss;

	result.dodge = min(result.dodge, leftover);
	leftover = leftover - result.dodge;

	result.parry = min(result.parry, leftover);
	leftover = leftover - result.parry;

	result.block = min(result.block, leftover);
	leftover = leftover - result.block;

	result.critical = min(result.critical, leftover);
	leftover = leftover - result.critical;

	result.crushing = min(result.crushing, leftover);
	leftover = leftover - result.crushing;

	result.hit = leftover;

	if result.critical > 0 then
		dataobj.text = "|cffff0000"..L["Critable"].."|r";
	elseif result.crushing > 0 then
		dataobj.text =  "|cffff8000"..L["Crushable"].."|r";
	else
		dataobj.text = "|cff00ff00"..L["Uncrushable"].."|r";
	end
end

function f:PLAYER_LOGIN()
	self:RegisterEvent("UNIT_INVENTORY_CHANGED");
	self:RegisterEvent("UNIT_AURA");
	self:RegisterEvent("ADDON_LOADED");
	self:RegisterEvent("PLAYER_TARGET_CHANGED");

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil

	local _, class = UnitClass("player");
	local uncrit = 0;

	-- SoTF
	if ( class == "DRUID" ) then
		talentedcritreduct = select(5, GetTalentInfo(2, 16));
	-- SoH
	elseif ( class == "ROGUE" ) then
		talentedcritreduct = select(5, GetTalentInfo(3, 3));
	end

end

f.UNIT_INVENTORY_CHANGED = UpdateHitTable
f.UNIT_AURA = UpdateHitTable
f.ADDON_LOADED = UpdateHitTable
f.PLAYER_TARGET_CHANGED = UpdateHitTable

local function GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth() * 2 / 3) and "RIGHT" or (x < UIParent:GetWidth() / 3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight() / 2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

function dataobj.OnLeave() GameTooltip:Hide() end

function dataobj.OnEnter(self)
 	GameTooltip:SetOwner(self, "ANCHOR_NONE")
	GameTooltip:SetPoint(GetTipAnchor(self))
	GameTooltip:ClearLines()

	GameTooltip:AddLine("lowAvoidance")
	GameTooltip:AddLine(" ")

	GameTooltip:AddLine(L["Defensive Combat Table vs Level"].." "..targetlevel)
	GameTooltip:AddLine(" ")

	GameTooltip:AddDoubleLine(L["Miss"], string.format("%.2f%%", result.miss))
	GameTooltip:AddDoubleLine(L["Dodge"], string.format("%.2f%%", result.dodge))
	GameTooltip:AddDoubleLine(L["Parry"], string.format("%.2f%%", result.parry))
	GameTooltip:AddDoubleLine(L["Block"], string.format("%.2f%%", result.block))
	GameTooltip:AddDoubleLine(L["Critical"], string.format("%.2f%%", result.critical))
	GameTooltip:AddDoubleLine(L["Crushing"], string.format("%.2f%%", result.crushing))
	GameTooltip:AddDoubleLine(L["Hit"], string.format("%.2f%%", result.hit))

	GameTooltip:Show()
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
