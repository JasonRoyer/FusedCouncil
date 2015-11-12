LootMember = {
frame = {},
responses = {}
}

function LootMember:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;	
	self:CreateWindow(o)
	return o
end

function LootMember:CreateWindow(o)
 self.frame = CreateFrame("Frame", "memberFrame",  UIParent, "TooltipBorderedFrameTemplate");
 
	local frame = self.frame;
	 frame:SetFrameStrata("HIGH");
	self.frame:SetPoint("CENTER", UIParent, "CENTER");
	self.frame:SetSize(900,400);
	self.frame:SetMovable(true);
	self.frame:EnableMouse(true);
	self.frame:RegisterForDrag("LeftButton");
	self.frame:SetScript("OnDragStart", function () self.frame:StartMoving() end);
	self.frame:SetScript("OnDragStop", function () self.frame:StopMovingOrSizing() end );
	
	self.frame.parentObject = o;
	local function eventHandeler(self, event, prefix, ...)
		if event == "CHAT_MSG_ADDON" and prefix == "FLC_PREFIX" then
			local message, _, sender = ...;
			local splitMessage = frame.parentObject:split(message,"^");
			if #splitMessage > 0 then
				if splitMessage[1] == "A" then
					frame.parentObject:AddResponseWindow(splitMessage[2], #frame.parentObject.responses +1);
				end
			
			end
		end
	end
	self.frame:SetScript("OnEvent", eventHandeler);
	self.frame:RegisterEvent("CHAT_MSG_ADDON");
	RegisterAddonMessagePrefix("FLC_PREFIX");
	

end
function LootMember:Update()
for i = 1, #self.responses do
		self.responses[i].frame:SetPoint("TopLeft", self.frame, 0, -100*(i-1));
	end
	
	if #self.responses == 0 then
		self.frame:Hide();
	end
end
function LootMember:AddResponseWindow(lootLink, currentResponseNum)
	local _, myIlvl = GetAverageItemLevel();
	
	-- might be problem here
	local itemEquipSlot, itemTexture = select(9, GetItemInfo(lootLink));
	local tempResponse = {name =GetUnitName("player",false),
			ilvl = math.floor(myIlvl+0.5),
			score = 0,
			rank= select(2, GetGuildInfo("player")),
			response="",
			note=""}
			if _G[itemEquipSlot] ~= nil then
			tempResponse.currentItem=GetInventoryItemLink("player",GetInventorySlotInfo(_G[itemEquipSlot].."slot"))
			else tempResponse.currentItem = "None" end
						
	tempResponse.frame = CreateFrame("Frame", nil,  self.frame, "TooltipBorderedFrameTemplate");
	-- populate response window
	tempResponse.frame:SetSize(900,100);
	
	tempResponse.frame.IconFrame = CreateFrame("Frame", nil,  self.frame);
	tempResponse.frame.IconFrame :SetSize(75,75);
	tempResponse.frame.IconFrame:SetPoint("TopLeft", 15, -12 )
	tempTexture = tempResponse.frame.IconFrame :CreateTexture("itemFrame".. (#self.responses + 1).. "Texture");
		tempTexture:SetTexture(itemTexture);
		tempTexture:SetAllPoints(tempResponse.frame.IconFrame);
			
		tempResponse.frame.IconFrame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(tempResponse.frame.IconFrame, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink(lootLink);
			GameTooltip:Show()
		end);
	
		tempResponse.frame.IconFrame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end);
		
		local buttonTitles = {"Bis", "Major","Minor", "Reroll", "OffSpec", "Transmog", "Pass"}
		local noteBox = CreateFrame("EditBox", nil , tempResponse.frame, "InputBoxTemplate");
		noteBox:SetSize(124*(#buttonTitles-1), 20);
		noteBox:SetPoint("TopLeft",110, -70);
		noteBox:SetAutoFocus(false);
		-- OnEnterPressed
		noteBox:SetScript("OnEnterPressed", function(self)
			self:ClearFocus();
		end);
		
		
		local object = self;
		for i= 1, #buttonTitles do
			local tempButton = CreateFrame("Button", nil, tempResponse.frame, "MagicButtonTemplate" );
			tempButton:SetText(buttonTitles[i]);
			tempButton:SetPoint("TopLeft",tempResponse.frame, 110+ (110*(i-1)), -40);
			
			tempButton:SetScript("OnClick", function(self)
			tempResponse.response = self:GetText();
			tempResponse.note = noteBox:GetText();
			object:removeResponse(currentResponseNum);
			SendAddonMessage( "FLC_PREFIX", "B".. "^".. tempResponse.name .. "^".. tempResponse.ilvl .. "^".. tempResponse.score .. 
									"^".. tempResponse.currentItem .. "^"..tempResponse.rank .. "^".. tempResponse.response  .. "^"..tempResponse.note, "RAID" );
		end);
		end
		
		lootItemName = tempResponse.frame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		lootItemName:SetText(GetItemInfo(lootLink))
		lootItemName:SetPoint("TopLeft" ,110, -20)
		
		table.insert(self.responses, tempResponse);
	self:Update();
end
function LootMember:removeResponse(index)
		table.remove(self.responses, index);
		self:Update();
end

function LootMember:split(str, pat)
local tempArray = {};
for w in (str.."^"):gmatch("[^^]+") do 
    table.insert(tempArray, w) 
end
return tempArray
end

myMember = LootMember:New(nil);