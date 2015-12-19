LootCouncil = {
 window = {},
 minWindow = {},
 childFrame = {},
 title = "Fused Loot Council",
 -- current item will be a frame
 currentItem = nil,
 itemList = {},
 labelButtons = {},
 mainWindowShowing = true,
 passingLootOut = false,
 }

function LootCouncil:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;	
	self:CreateWindow(o)
	return o
end



function LootCouncil:CreateWindow(o)


	
	---------------------------------------------------------------------------------------------------------------------
	----- 									BASE FRAME											   		----- 
	---------------------------------------------------------------------------------------------------------------------
	
	self.window = CreateFrame("Frame", "window",  UIParent, "PortraitFrameTemplate");	
-- create easier name to deal with
	local window = self.window;	
	window:SetFrameStrata("MEDIUM");
	window.parentObject = o;
	local function eventHandeler(self, event, prefix, ...)
		if event == "LOOT_OPENED"  and not window.parentObject.passingLootOut then
			for i=1, GetNumLootItems() do
				local lootIcon, lootName, lootQuality = GetLootSlotInfo(i);
				local lootLink = GetLootSlotLink(i) ;
				window.parentObject:AddItemToList(lootIcon, lootName, lootQuality, lootLink);
				
			end
			window.parentObject:Show();
			window.parentObject.passingLootOut = true;
		elseif event == "CHAT_MSG_ADDON" and prefix == "FLC_PREFIX" then
			local message, _, sender = ...;
			local splitMessage = window.parentObject:split(message,"^");
			if #splitMessage > 0 then
				if splitMessage[1] == "B" then
				for i=1, #splitMessage do
					--print(splitMessage[i])
				end
				
				window.parentObject:AddResponse(splitMessage[2], splitMessage[3], splitMessage[4],splitMessage[5],splitMessage[6], splitMessage[7]);
				end
			
			end
		end

		end
	window:SetScript("OnEvent", eventHandeler);
	window:RegisterEvent("LOOT_OPENED");
	window:RegisterEvent("CHAT_MSG_ADDON");
	RegisterAddonMessagePrefix("FLC_PREFIX");
	
	window:SetPoint("CENTER", UIParent, "CENTER");
	window:SetSize(900,400);
	window:SetMovable(true);
	window:EnableMouse(true);
	window:RegisterForDrag("LeftButton");
	window:SetScript("OnDragStart", function () window:StartMoving() end);
	window:SetScript("OnDragStop", function () window:StopMovingOrSizing() end );
	
	-- Add upper left icon
		window:CreateTexture("illidanTexture");
		SetPortraitToTexture("illidanTexture", "Interface\\ICONS\\Achievement_Boss_Illidan.blp")
		illidanTexture:SetPoint("TopLeft", -10, 10);
	
	-- Display top title for window
		titleFontString = window:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		titleFontString:SetText(self:GetTitle())
		titleFontString:SetPoint("Top" ,0, -5)
	

		
	-- Create Minimize button
		minButton = CreateFrame("Button", "FLC_MinButton", window, "MagicButtonTemplate" );
		minButton:SetSize(23,23);
		minButton:SetText("-");
		minButton:SetBackdropBorderColor(0,0,0,0);
		minButton:ClearAllPoints();
		minButton:SetPoint("TopRight",window, -23, 1);
		
		minButton:SetScript("OnMouseup", function()

		if self:GetMainWindowShowing()  then
				window:Hide();
				self:GetMinWindow():Show();
				self:SetMainWindowShowing(false);
				
				
				
				
		end
	end );
	
	-- Create a window for when we minimize the main window
		self:CreateMinimizeWindow();
		
	-- Create the scrollFrame for the list of responses
		self:CreateResponseFrame();
		
	---------------------------------------------------------------------------------------------------------------------
	----- 								LABEL BUTTONS											   		----- 
	---------------------------------------------------------------------------------------------------------------------
		local labelsNames = {"Name","ilvl","Score", "Current Item", "Rank", "Response", "Note", "Vote", "Votes"}
		
			for i=1 , #labelsNames do
			self.labelButtons[i] = CreateFrame("Button", labelsNames[i].."LabelButton", window, "MagicButtonTemplate" );
			self.labelButtons[i]:SetText(labelsNames[i]);
			self.labelButtons[i]:SetPoint("TopLeft",window, 20+ (90*(i-1)), -100);
		end
	
	
	
		window:CreateTexture("ItemFrameTexture");
		ItemFrameTexture:SetTexture("Interface\\BUTTONS\\UI-Slot-Background.blp");
		ItemFrameTexture:SetSize(75,75);
		ItemFrameTexture:SetPoint("TopLeft", 50, -50);
		
	
end

function LootCouncil:CreateMinimizeWindow()
	--------------------------------------------------------------------------------------------------------------------
	----- 										 HIDDEN FRAME									   		----- 
	---------------------------------------------------------------------------------------------------------------------
	local minWindow = CreateFrame("Frame", "lcMinFrame",  UIParent, "PortraitFrameTemplate");
-- create easier name to deal with
	self.minWindow = minWindow;
	minWindow:SetPoint("TopRight", self:GetWindow(), "TopRight");
	minWindow:SetSize(100,75);
	minWindow:Hide();
	
-- Create Maximize button
	maxButton = CreateFrame("Button", "lcMinFrameMaxButton", minWindow, "MagicButtonTemplate" );
	maxButton:SetSize(23,23);
	maxButton:SetText("+");
	maxButton:SetBackdropBorderColor(0,0,0,0);
	maxButton:ClearAllPoints();
	maxButton:SetPoint("TopRight",minWindow, -23, 1);
	
	maxButton:SetScript("OnMouseup", function()

		if  not self:GetMainWindowShowing() then
			minWindow:Hide();
			self:GetWindow():Show();
			self:SetMainWindowShowing(true);
		end
	end );
	
-- Create portrait icon for minWindow
	minWindow:CreateTexture("minillidanTexture");
	SetPortraitToTexture("minillidanTexture", "Interface\\ICONS\\Achievement_Boss_Illidan.blp")
	minillidanTexture:SetPoint("TopLeft", -10, 10);
	
end

function LootCouncil:CreateResponseFrame()
	---------------------------------------------------------------------------------------------------------------------
	----- 										 RESPONSE FRAME							   		----- 
	---------------------------------------------------------------------------------------------------------------------

	local responseFrame = CreateFrame("ScrollFrame", "responseFrame",  self:GetWindow(), "MinimalScrollFrameTemplate");
	responseFrame:SetPoint("BottomLeft", self:GetWindow(), 20,20);
	responseFrame:SetSize(800,250);
	responseFrame.background  = responseFrame:CreateTexture("responseFrameBackgroundTexture", "BACKGROUND");
	responseFrame.background:SetTexture(.1,.2,.1, .5);
	responseFrame.background:SetAllPoints(responseFrame);
	responseFrame:EnableMouse(true);
	
	childFrame = CreateFrame("Frame", "childFrame",  self:GetWindow());
	childFrame:SetSize(800,1000);
	responseFrame:SetScrollChild(childFrame);
	self.childFrame = childFrame;
end

function LootCouncil:GetResponses()
	return self.responses;
end

function LootCouncil:AddResponse(...)
		local tempFrame =  CreateFrame("Frame", nil,  self:GetChildFrame());
		local subFrames = {};
		for i =1, 9 do
		subFrames[i] = CreateFrame("Frame", nil,  tempFrame);
		subFrames[i] :SetSize(88,25);
		subFrames[i] :SetPoint("TopLeft",(90*(i-1)),0);
		 tempcolor= subFrames[i] :CreateTexture(nil, "BACKGROUND");
	tempcolor:SetTexture(1-(.1*i),1-(.1*i),.1, .5);
	tempcolor:SetAllPoints(subFrames[i] );
		end
		tempFrame:SetSize(800,25);
		frameTuple = {};
		for i=1, select("#", ...)do
			frameTuple[i] = subFrames[i]:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
			tempToken = select(i +1, ...);
			frameTuple[i]:SetText(tempToken);
			frameTuple[i]:SetPoint("CENTER",0, 0); 
			if tempToken ~= nil then
			--print(tempToken.. " ".. 20+ (90*(i-1)) )
			end
		end
		
		local itemResponseList = self.itemList[self:FindItemIndex(select(1, ...))].responses;
		

		tempFrame:SetPoint("Top", 0, -25*(#itemResponseList) )
		itemResponseList[#itemResponseList + 1] = tempFrame;
		self:GetChildFrame():SetSize(800, 2500 *(#self.itemList));
	
end

function LootCouncil:FindItemIndex(itemLink)
  for i=1, #self.itemList do
      if self.itemList[i].itemLink == itemLink then
      return i;
      end
  end
  return -1;
end


function LootCouncil:Update()
	if self.currentItem ~= nil then
		self.currentItem.frame:SetPoint("TopLeft", self:GetWindow(), 50, -50);
		-- Name of item currently being displayed
		self.currentItem.itemNameFontString = self:GetWindow():CreateFontString(nil, "BACKGROUND", "GameFontNormal")
		self.currentItem.itemNameFontString:SetText(self.currentItem.itemName);
		self.currentItem.itemNameFontString:SetPoint("TopLeft",100 ,-55)
	end
	if self.itemList ~= nil then
		for i=1, #self.itemList do
			self.itemList[i].frame:SetPoint("TopLeft", self:GetWindow(), 20 + 60 * (i-1), -410);
		end
	end
	
end
function LootCouncil:CreateItem(lootIcon, lootName, lootQuality, lootLink)

	local tempItem = {itemIcon = lootIcon, itemName = lootName, itemQuality = lootQuality, itemLink=lootLink, responses = {}}
		tempItem.frame = CreateFrame("Frame", "itemFrame".. (#self.itemList + 1),  self:GetWindow());
		tempItem.frame:SetSize(50,50);
		tempItem.frame.Item = tempItem.frame;
		tempTexture = tempItem.frame:CreateTexture("itemFrame".. (#self.itemList + 1).. "Texture");
		tempTexture:SetTexture(lootIcon);
		tempTexture:SetAllPoints(tempItem.frame);
			
		tempItem.frame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(tempItem.frame, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink(lootLink);
			GameTooltip:Show()
		end);
	
		tempItem.frame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end);
		local councilObject = self;
		tempItem.frame:SetScript("OnMouseDown", function()
		  tempMovableItem = councilObject:GetCurrentItem();
		  
		
		 end);
		
		return tempItem;

end
function LootCouncil:AddItemToList(lootIcon, lootName, lootQuality, lootLink)
	
		local tempItem = self:CreateItem(lootIcon, lootName, lootQuality, lootLink);
			
			
			self.itemList[#self.itemList + 1] = tempItem;
			
		if  self:GetCurrentItem() == nil then
			self:SetCurrentItem(lootIcon, lootName, lootQuality, lootLink, #self.itemList + 1);
		end
		
		SendAddonMessage( "FLC_PREFIX", "A".. "^"..lootLink, "RAID" );
		self:Update();
end

function LootCouncil:split(str, pat)
local tempArray = {};
for w in (str.."^"):gmatch("[^^]+") do 
    table.insert(tempArray, w) 
end
return tempArray
end

function LootCouncil:GetWindow()
	return self.window;
end

function LootCouncil:GetChildFrame()
	return self.childFrame;
end

function LootCouncil:GetMinWindow()
	return self.minWindow;
end



function LootCouncil:GetTitle()
	return self.title;
end

function LootCouncil:SetTitle(titleString)
	self.title = titleString;
end

function LootCouncil:GetCurrentItem()
	return self.currentItem;
end


function LootCouncil:SetCurrentItem(lootIcon, lootName, lootQuality, lootLink, itemPosition)
	
	self.currentItem = self:CreateItem(lootIcon, lootName, lootQuality, lootLink) ;
	self.currentItem.itemPosition = itemPosition;
end

function LootCouncil:GetMainWindowShowing()
	return self.mainWindowShowing;
end

function LootCouncil:SetMainWindowShowing(setBool)
	self.mainWindowShowing = setBool;
end

function LootCouncil:Show()
	self.window:Show();
end




myLC = LootCouncil:New(nil);
--myLC:AddResponse("Doom", "733", "0", "shit", "GOD", "GIMME", "MVP", "VOTE", "all");
--myLC:SetCurrentItem(GetInventoryItemID("player",GetInventorySlotInfo("ChestSlot")), GetInventoryItemLink("player",GetInventorySlotInfo("ChestSlot")));
--myLC:SetCurrentItem(GetInventoryItemID("player",GetInventorySlotInfo("ChestSlot")), GetInventoryItemLink("player",GetInventorySlotInfo("ChestSlot")));

SLASH_FLC1 = "/flc"
SlashCmdList["FLC"] = function() myLC:Show() end ;