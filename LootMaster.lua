LootCouncil = {
  Frame = {},
  minWindow = {},
  childFrame = {},
  title = "Fused Loot Council",
  -- current item will be a frame
  currentItem = nil,
  currentItemFontString = {},
  itemList = {},
  labelButtons = {},
  isMainWindowShowing = true,
  isPassingLootOut = false,
  itemFramePool = {},
  responseFramePool = {},
  personSelected = "",
}

function LootCouncil:New(o)
  o = o or {};
  setmetatable(o, self);
  self.__index = self;
  self:CreateWindow(o)
  return o
end

function LootCouncil:CreateWindow(o)
  local tempFrame = CreateFrame("Frame", nil,  UIParent, "PortraitFrameTemplate");

  tempFrame:SetFrameStrata("MEDIUM");
  local function eventHandeler(self, event, prefix, ...)
    if event == "LOOT_OPENED"  and not o.isPassingLootOut then
      for i=1, GetNumLootItems() do
        local lootIcon, lootName, lootQuality = GetLootSlotInfo(i);
        local lootLink = GetLootSlotLink(i) ;
        if lootQuality > 0 then
        o:AddItem(o:CreateItem(lootIcon, lootName, lootQuality, lootLink, i));
        end
      end
      o:ShowMainWindow();
      o.passingLootOut = true;
    elseif event == "CHAT_MSG_ADDON" and prefix == "FLC_PREFIX" then
      local message, _, sender = ...;
      local splitMessage = o:splitMSG(message);
      if #splitMessage > 0 then
        if splitMessage[1] == "B" then
          o:AddResponse(splitMessage[2], splitMessage[3], splitMessage[4],splitMessage[5],splitMessage[6], splitMessage[7],splitMessage[8]);
        end

      end
    end

  end
  tempFrame:SetScript("OnEvent", eventHandeler);
  tempFrame:RegisterEvent("LOOT_OPENED");
  tempFrame:RegisterEvent("CHAT_MSG_ADDON");
  RegisterAddonMessagePrefix("FLC_PREFIX");

  tempFrame:SetPoint("CENTER", UIParent, "CENTER");
  tempFrame:SetSize(900,400);
  tempFrame:SetMovable(true);
  tempFrame:EnableMouse(true);
  tempFrame:RegisterForDrag("LeftButton");
  tempFrame:SetScript("OnDragStart", function () tempFrame:StartMoving() end);
  tempFrame:SetScript("OnDragStop", function () tempFrame:StopMovingOrSizing() end );

  -- Add upper left icon
  tempFrame:CreateTexture("illidanTexture");
  SetPortraitToTexture("illidanTexture", "Interface\\ICONS\\Achievement_Boss_Illidan.blp")
  illidanTexture:SetPoint("TopLeft", -10, 10);

  -- Display top title for window
  titleFontString = tempFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
  titleFontString:SetText(self:GetTitle())
  titleFontString:SetPoint("Top" ,0, -5)



  -- Create Minimize button
  minButton = CreateFrame("Button", "FLC_MinButton", tempFrame, "MagicButtonTemplate" );
  minButton:SetSize(23,23);
  minButton:SetText("-");
  minButton:SetBackdropBorderColor(0,0,0,0);
  minButton:ClearAllPoints();
  minButton:SetPoint("TopRight",tempFrame, -23, 1);

  minButton:SetScript("OnMouseup", function()

      if self:IsMainWindowShowing()  then
        self:ShowMinWindow();
      end
  end );

  -- create reponse table attributes
  local labelsNames = {"Name","ilvl","Score", "Current Item", "Rank", "Response", "Note", "Vote", "Votes"}

  for i=1 , #labelsNames do
    self.labelButtons[i] = CreateFrame("Button", labelsNames[i].."LabelButton", tempFrame, "MagicButtonTemplate" );
    self.labelButtons[i]:SetText(labelsNames[i]);
    self.labelButtons[i]:SetPoint("TopLeft",tempFrame, 20+ (90*(i-1)), -100);
  end
  
  local giveButton = CreateFrame("Button", nil, tempFrame, "MagicButtonTemplate" );
  giveButton:SetText("Give Loot");
  giveButton:SetPoint("TopLeft", 380, -370);
  
  giveButton:SetScript("OnMouseup", function()
    local personIndex;
    for i=1, GetNumGroupMembers() do 
    print("group member" .. GetMasterLootCandidate(o.currentItem.itemPosition,i) .. " person selected " .. o.personSelected)
      if o.personSelected == GetMasterLootCandidate(o.currentItem.itemPosition,i) then
        personIndex = i;
        print(o.personSelected .. " found at " .. personIndex)
      end
    end
    if personIndex ~= nil then
      GiveMasterLoot(o.currentItem.itemPosition, personIndex);
    end
  end );

  tempFrame:CreateTexture("ItemFrameTexture");
  ItemFrameTexture:SetTexture("Interface\\BUTTONS\\UI-Slot-Background.blp");
  ItemFrameTexture:SetSize(75,75);
  ItemFrameTexture:SetPoint("TopLeft", 50, -50);

  self.currentItemFontString = tempFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
  self.currentItemFontString:SetPoint("TopLeft",100 ,-55)

  -- Create a window for when we minimize the main window
  local minWindow = CreateFrame("Frame", "lcMinFrame",  UIParent, "PortraitFrameTemplate");
  -- create easier name to deal with
  minWindow:SetPoint("TopRight", tempFrame, "TopRight");
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

      if  not self:IsMainWindowShowing() then
        self:ShowMainWindow();
      end
  end );

  -- Create portrait icon for minWindow
  minWindow:CreateTexture("minillidanTexture");
  SetPortraitToTexture("minillidanTexture", "Interface\\ICONS\\Achievement_Boss_Illidan.blp")
  minillidanTexture:SetPoint("TopLeft", -10, 10);

  -- Create the scrollFrame for the list of responses

  local responseFrame = CreateFrame("ScrollFrame", "responseFrame",  tempFrame, "MinimalScrollFrameTemplate");
  responseFrame:SetPoint("BottomLeft", tempFrame, 20,20);
  responseFrame:SetSize(800,250);
  responseFrame.background  = responseFrame:CreateTexture("responseFrameBackgroundTexture", "BACKGROUND");
  responseFrame.background:SetTexture(.1,.2,.1, .5);
  responseFrame.background:SetAllPoints(responseFrame);
  responseFrame:EnableMouse(true);

  local childFrame = CreateFrame("Frame", "childFrame",  tempFrame);
  childFrame:SetSize(800,1000);
  responseFrame:SetScrollChild(childFrame);


  self.Frame = tempFrame;
  self.minWindow = minWindow;
  self.childFrame = childFrame;
end


function LootCouncil:Update()
  if self.currentItem ~= nil then
    self.currentItem.frame:SetPoint("TopLeft", self:GetWindow(), 50, -50);
    self.currentItemFontString:SetText(self.currentItem.itemName);
    for i=1, #self.currentItem.responses do
      self.currentItem.responses[i]:Show();
      self.currentItem.responses[i]:SetPoint("Top", 0, -25*i);
    end
    self.childFrame:SetSize(800, 26 *(#self.currentItem.responses));
  end
  if self.itemList ~= nil then
    for i=1, #self.itemList do
      self.itemList[i].frame:SetPoint("TopLeft", self:GetWindow(), 20 + 60 * (i-1), -410);
    end
  end

end

function LootCouncil:AddResponse(...)
  local reponse = self:GetEmptyResponseFrame();
  
  for i=2, select("#", ...) do
    reponse.subFrames[i-1].fontString:SetText(select(i, ...));
  end

  local itemResponseList = self.itemList[self:FindItemIndex(select(1, ...))].responses;

  itemResponseList[#itemResponseList + 1] = reponse;
  self:Update();
end

function LootCouncil:GetEmptyResponseFrame()
  if #self.responseFramePool == 0 then
    for i=1,5 do
      table.insert(self.responseFramePool,self:CreateResponseFrame());
    end

  end
  return table.remove(self.responseFramePool, 1);

end

function LootCouncil:FindItemIndex(itemLink)
  for i=1, #self.itemList do
      if self.itemList[i].itemLink == itemLink then
      return i;
      end
  end
  return -1;
end

function LootCouncil:CreateResponseFrame()
  local tempFrame =  CreateFrame("Frame", nil,  self.childFrame);
   tempFrame:SetSize(800,25);
  tempFrame:Hide();
  tempFrame:EnableMouse(true);
  local object= self;
  tempFrame:SetScript("OnMouseDown", function()
      object.personSelected = tempFrame.subFrames[1].fontString:GetText();
     
  end );
  
  tempFrame.subFrames = {};
  for i =1, 9 do
    tempFrame.subFrames[i] = CreateFrame("Frame", nil,  tempFrame);
    tempFrame.subFrames[i] :SetSize(88,25);
    tempFrame.subFrames[i] :SetPoint("TopLeft",(90*(i-1)),0);
    tempcolor= tempFrame.subFrames[i] :CreateTexture(nil, "BACKGROUND");
    tempcolor:SetTexture(1-(.1*i),1-(.1*i),.1, .5);
    tempcolor:SetAllPoints(tempFrame.subFrames[i] );
    tempFrame.subFrames[i].fontString = tempFrame.subFrames[i]:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
    tempFrame.subFrames[i].fontString:SetPoint("CENTER",0, 0);
  end
 
 return tempFrame;
end


----- HELPER FUNCTIONS -------
--
--
--
--
--
--
function LootCouncil:AddItem(item)

  self.itemList[#self.itemList + 1] = item;

  if  self:GetCurrentItem() == nil then

    self:SetCurrentItem(item, #self.itemList + 1);
  end

  SendAddonMessage( "FLC_PREFIX", "A".. "^"..item.itemLink, "RAID" );
  self:Update();
end

function LootCouncil:CreateItem(lootIcon, lootName, lootQuality, lootLink, itemPositioni, responsesi)
  if responsesi == nil then
  responsesi ={};
  end
  local tempItem = {itemIcon = lootIcon, itemName = lootName, itemQuality = lootQuality, itemLink=lootLink, responses = responsesi, itemPosition = itemPositioni}
  tempItem.frame = self:GetEmptyItemFrame();
  tempItem.frame:Show();
  tempItem.frame.Item = tempItem.frame;
  tempItem.frame.texture:SetTexture(lootIcon);

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
    councilObject:SetCurrentItem(tempItem);
    councilObject:Update();
  end);

  return tempItem;

end
function LootCouncil:GetEmptyItemFrame()
  if #self.itemFramePool == 0 then
    for i=1,5 do
      table.insert(self.itemFramePool,self:CreateItemFrame());
    end

  end
  return table.remove(self.itemFramePool, 1);

end

function LootCouncil:CreateItemFrame()
  local tempFrame = CreateFrame("Frame", nil,  self:GetWindow());
  tempFrame:SetSize(50,50);
  tempFrame.texture = tempFrame:CreateTexture();
  tempFrame.texture:SetAllPoints(tempFrame);
  return tempFrame;
end

function LootCouncil:ReleaseItemFrame(frame)
  frame:Hide();
  table.insert(self.itemFramePool, frame);
end
function LootCouncil:GetTitle()
  return self.title;
end

function LootCouncil:GetWindow()
  return self.Frame;
end
function LootCouncil:GetCurrentItem()
  return self.currentItem;
end

function LootCouncil:IsMainWindowShowing()
  return self.isMainWindowShowing;
end

function LootCouncil:SetCurrentItem(item)
  if self.currentItem ~= nil then
    self:ReleaseItemFrame(self.currentItem.frame);
    for i=1, #self.currentItem.responses do
      self.currentItem.responses[i]:Hide();
    end
  end
  self.currentItem = self:CreateItem(item.itemIcon, item.itemName, item.itemQuality, item.itemLink, item.itemPosition, item.responses) ;
end

function LootCouncil:splitMSG(str)
  local tempArray = {};
  for w in (str.."^"):gmatch("[^^]+") do
    table.insert(tempArray, w)
  end
  return tempArray
end

function LootCouncil:ShowMinWindow()
  self.Frame:Hide();
  self.minWindow:Show();
  self.isMainWindowShowing = false;
end

function LootCouncil:ShowMainWindow()
  self.minWindow:Hide();
  self.Frame:Show();
  self.isMainWindowShowing = true;
end



myLC = LootCouncil:New(nil);

SLASH_FLC1 = "/flc"
SlashCmdList["FLC"] = function() myLC:Show() end ;
