local frame = CreateFrame("Frame");
frame:RegisterEvent("PLAYER_LOGIN");
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("INSPECT_READY");

local TEXT_WIDTH = 137;
local ICON_SIZE = 37/2;
--CharacterStatsClassic needs this line:
--CSC_UIFrame.CharacterStatsPanel:SetPoint("TOPLEFT", CharacterModelFrame, "BOTTOMLEFT", -16, 24);

local CPR_buttons = {{1, "HeadSlot"},
				 {2, "NeckSlot"},
				 {3, "ShoulderSlot"},
				 {15, "BackSlot"},
				 {5, "ChestSlot"},
				 {4, "ShirtSlot"},
				 {19, "TabardSlot"},
				 {9, "WristSlot"},
				 {10, "HandsSlot"},
				 {6, "WaistSlot"},
				 {7, "LegsSlot"},
				 {8, "FeetSlot"},
				 {11, "Finger0Slot"},
				 {12, "Finger1Slot"},
				 {13, "Trinket0Slot"},
				 {14, "Trinket1Slot"}}

--Move CharacterFrame right if InspectFrame is already open in Character tab
CharacterFrame:HookScript("OnShow", function()
	if (InspectPaperDollFrame and InspectPaperDollFrame:IsVisible()) then
		CharacterPageRearrange_RepositionObject(CharacterFrame, 80, 0);
	end
end);
--Resize CharacterFrame when switching into and out of Character tab
local function CharacterPageRearrange_PageHook(frameName)
	--CharacterFrame:GetWidth() = 384
    if (frameName == "PaperDollFrame") then
		CharacterFrame:SetWidth(464);
        CharacterFrame:SetAttribute("UIPanelLayout-width", 444);
		for i, button in pairs(CPR_buttons) do
			_G["Character"..button[2]].Text:Show();
		end
    else
		CharacterFrame:SetWidth(384);
        CharacterFrame:SetAttribute("UIPanelLayout-width", 364);
		for i, button in pairs(CPR_buttons) do
			_G["Character"..button[2]].Text:Hide();
		end
    end
    UpdateUIPanelPositions(CharacterFrame)
end
hooksecurefunc("ToggleCharacter", CharacterPageRearrange_PageHook);

frame:SetScript("OnEvent",
	function(self, event, ...)
		if (event == "PLAYER_LOGIN") then
			CharacterAttributesFrame:SetPoint("TOPLEFT", CharacterModelFrame, "BOTTOMLEFT", 1.5, 11);
			CharacterPageRearrange_RearrangeFrame("Character");
			CharacterPageRearrange_PrepButtons("Character");
			CharacterPageRearrange_UpdateLabels("Character");
		elseif (event == "ADDON_LOADED") then
			local arg1 = ...;
			--Hook a script when you try to inspect
			if (arg1 == "Blizzard_InspectUI") then
				CharacterPageRearrange_RearrangeFrame("Inspect");
				--Resize frame
				InspectPaperDollFrame:HookScript("OnShow", function()
					NotifyInspect("target");
					InspectFrame:SetWidth(InspectFrame:GetWidth() + 80);
                    InspectFrame:SetAttribute("UIPanelLayout-width", 444);
					CharacterPageRearrange_RepositionObject(CharacterFrame, 80, 0);
                    UpdateUIPanelPositions(InspectFrame);
					for i, button in pairs(CPR_buttons) do
						if (_G["Inspect"..button[2]].Text) then
							_G["Inspect"..button[2]].Text:Show();
						end
					end
				end);
				InspectPaperDollFrame:HookScript("OnHide", function()
					InspectFrame:SetWidth(InspectFrame:GetWidth() - 80);
                    InspectFrame:SetAttribute("UIPanelLayout-width", 364)
					CharacterPageRearrange_RepositionObject(CharacterFrame, -80, 0);
                    UpdateUIPanelPositions(InspectFrame);
					for i, button in pairs(CPR_buttons) do
						if (_G["Inspect"..button[2]].Text) then
							_G["Inspect"..button[2]].Text:Hide();
						end
					end
				end);
			end
		elseif (event == "PLAYER_EQUIPMENT_CHANGED" or event == "GET_ITEM_INFO_RECEIVED") then
			CharacterPageRearrange_UpdateLabels("Character");
		elseif (event == "INSPECT_READY") then
			--Check if frame exists
			if (InspectPaperDollFrame) then
				CharacterPageRearrange_PrepButtons("Inspect");
				CharacterPageRearrange_UpdateLabels("Inspect");
			end
		end
		--DEFAULT_CHAT_FRAME:AddMessage(":D");
	end);

function CharacterPageRearrange_RearrangeFrame(target)
	--Move things around
	CharacterPageRearrange_RepositionObject(_G[target.."HeadSlot"], 243, 0);
	CharacterPageRearrange_RepositionObject(_G[target.."MainHandSlot"], -42, 0);
	CharacterPageRearrange_RepositionObject(_G[target.."ModelFrame"], -42, 0);
	if (target == "Character") then
		CharacterPageRearrange_RepositionObject(CharacterResistanceFrame, -42, 0);
	end
	
	--Change spacings
	for i=2, #CPR_buttons do
		_G[target..CPR_buttons[i][2]]:SetPoint("TOPLEFT", _G[target..CPR_buttons[i-1][2]], "BOTTOMLEFT", 0, -2);
	end
	
	--Replace textures
	local paperDoll = "PaperDollFrame";
	if (target == "Inspect") then
		paperDoll = target..paperDoll;
	end
	paperDoll = _G[paperDoll];
	for i = 1, paperDoll:GetNumRegions() do
		local region = select(i, paperDoll:GetRegions());
		if (region:GetObjectType() == "Texture") then
			if (region:GetTexture() == "Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1") then
				region:SetTexture("Interface/AddOns/CharacterPageRearrange/UI-Character-CharacterTab-L1");
			elseif (region:GetTexture() == "Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-R1") then
				region:SetTexture("Interface/AddOns/CharacterPageRearrange/UI-Character-CharacterTab-R1");
				region:SetSize(256, 256);
			elseif (region:GetTexture() == "Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-BottomLeft") then
				region:SetTexture("Interface/AddOns/CharacterPageRearrange/UI-Character-CharacterTab-BottomLeft");
			elseif (region:GetTexture() == "Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-BottomRight") then
				region:SetTexture("Interface/AddOns/CharacterPageRearrange/UI-Character-CharacterTab-BottomRight");
				region:SetSize(256, 256);
			end
		end
	end
	
	for i, button in pairs(CPR_buttons) do
		--Buttons are 37x37, but the borders are 64x64
		_G[target..button[2]]:GetNormalTexture():SetSize(ICON_SIZE * 64/37, ICON_SIZE * 64/37);
		_G[target..button[2]]:SetSize(ICON_SIZE, ICON_SIZE);
		
		--TODO: Figure out how to move the tooltip to the right edge
	end
end

function CharacterPageRearrange_UpdateLabels(target)
	local unit = "player";
	if (target == "Inspect") then
		unit = "target";
	end
	
	for i, button in pairs(CPR_buttons) do
		--[[if (target == "Inspect") then
			DEFAULT_CHAT_FRAME:AddMessage(string.gsub(GetInventoryItemLink(unit, button[1]), "|", "||"));
		end]]--
		
		local itemLink = GetInventoryItemLink(unit, button[1]);
		if (_G[target..button[2]].Label) then
			if (itemLink) then
				local color, itemString, itemName = string.match(itemLink, "|c(%x*)|H([-:%a%d]*)|h%[(.-)%]|h|r");
				if (itemName) then
					local labelText = string.format("|c%s|H%s|h%s|h|r", color, itemString, itemName);
					_G[target..button[2]].Label:SetText(labelText);
					
					local end_index = -3;
					while (_G[target..button[2]].Label:GetStringWidth() > TEXT_WIDTH) do
						end_index = end_index - 1;
						labelText = string.format("|c%s|H%s|h%s|h|r", color, itemString, string.sub(itemName, 1, end_index).."...");
						_G[target..button[2]].Label:SetText(labelText);
					end
				end
			else
				_G[target..button[2]].Label:SetText();
			end
		end
	end
end

function CharacterPageRearrange_RepositionObject(obj, x, y, pt)
	local anchor, relto, relpt, xofs, yofs;
    if pt == nil then
        for i = 1, obj:GetNumPoints() do
            anchor, relto, relpt, xofs, yofs = obj:GetPoint(i);
            obj:SetPoint(anchor, relto, relpt, xofs + x, yofs + y);
        end
    else
        anchor, relto, relpt, xofs, yofs = obj:GetPoint(pt);
        obj:SetPoint(anchor, relto, relpt, xofs + x, yofs + y);
    end
end

function CharacterPageRearrange_PrepButtons(target)
	for i, button in pairs(CPR_buttons) do
		--Make sure the labels actually exist
		if (not _G[target..button[2]].Text) then
			_G[target..button[2]].Text = CreateFrame("Button", _G[target..button[2]]:GetName().."Label", _G[target.."Frame"]);
			_G[target..button[2]].Text:SetSize(TEXT_WIDTH, ICON_SIZE);
			_G[target..button[2]].Text:SetPoint("LEFT", _G[target..button[2]], "RIGHT", 2, 0);
			--Tried to add a background color to the text but it doesn't look nice...
			--_G[target..button[2]].BG = _G[target..button[2]].Text:CreateTexture(nil, "ARTWORK");
			--_G[target..button[2]].BG:SetAllPoints();
			--_G[target..button[2]].BG:SetColorTexture(0xF5/0xFF, 0xB1/0xFF, 0x33/0xFF, 0.1);
		end
		if (not _G[target..button[2]].Label) then
				_G[target..button[2]].Label = _G[target..button[2]].Text:CreateFontString(nil, "ARTWORK");
			_G[target..button[2]].Label:SetFontObject(GameFontNormalSmall);
			_G[target..button[2]].Label:SetPoint("LEFT", _G[target..button[2]], "RIGHT", 2, 0);
		end
		
		--Set the label text and extend the hitbox of the button
		local offsets = {_G[target..button[2]]:GetHitRectInsets()};
		_G[target..button[2]].Text:SetFontString(_G[target..button[2]].Label);
		_G[target..button[2]]:SetHitRectInsets(offsets[1], -TEXT_WIDTH, offsets[3], offsets[4]);
	end
end