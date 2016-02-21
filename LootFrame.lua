local mainAddon = LibStub("AceAddon-3.0"):GetAddon("fusedCouncil");

local lootModule = mainAddon:NewModule("FCLootFrame","AceComm-3.0", "AceSerializer-3.0","AceEvent-3.0","AceTimer-3.0");

-- Gui components
local lootFrame;
local responseFramePool;
local currentResponses = {};

-- engine components
local numItemsRecived;
local options;
local numItemsFound;
local checkAgain;
local itemsFoundtable;

function lootModule:OnInitialize()
    lootFrame = lootModule:createLootFrame();
    responseFramePool = {};
    numItemsFound = 0;
    checkAgain ={};
    currentResponses = {};
    itemsFoundtable = {};
end 

function lootModule:OnEnable()
    self:RegisterComm("FLCPREFIX")
end

-- The function fired everytime the prefix is recived. More info under Ace3comm.
function lootModule:OnCommReceived(prefix, message, distribution, sender)
    -- split the message into the camand and the serialized data(Ace3), strsplit is in the wow api.
   local cmd, serializedPayload = strsplit(" ", message, 2);
   local success, payload = lootModule:Deserialize(serializedPayload);
   if success then
   
     if cmd == "lootTable" then
     print("loottable cmd recived")
      options = payload.optionsTable;
      -- cannot send fuctions over addon msg so only data of the object is recived, make new object.
      local itemData = payload.lootTable;
      payload.lootTable = {};
      for i=1, #itemData do
        table.insert(payload.lootTable, Item:new(itemData[i]));
      end
      numItemsRecived = #payload.lootTable;
       
       for i=1, #payload.lootTable do
          if GetItemInfo(payload.lootTable[i]:getItemLink()) ~= nil then
              lootModule:addResponse(payload.lootTable[i]);
          else
               table.insert(checkAgain, payload.lootTable[i]);
               lootFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
          end
        end
       
       

     end
   else
    print("Deserialization of payload failed");
   end  
    
end -- end LootCommHandler

function lootModule:addResponse(item)
  print("adding response")
   local _, myIlvl = GetAverageItemLevel();
  local tempResponse = Response:new(item:getItemLink(), GetUnitName("player",false),math.floor(myIlvl+0.5),nil,select(2, GetGuildInfo("player")),nil,nil, lootModule:getPlayersCurrentItems(item:getItemLink()));

  local tempResponseFrame = lootModule:getResponseFrame(item, tempResponse);
  
  table.insert(currentResponses, tempResponseFrame);
  print("i just inserted should be" .. #currentResponses)
  lootModule:update();
  
end

function lootModule:getPlayersCurrentItems(itemLink)

  local itemEquipSlot = select(9, GetItemInfo(itemLink));

  local equipedItemLink = {};
  if itemEquipSlot ~= "" then
      if itemEquipSlot == "INVTYPE_HEAD" then
       table.insert(equipedItemLink, GetInventoryItemLink("player", 1)or "none");
      elseif itemEquipSlot == "INVTYPE_NECK"then
         table.insert(equipedItemLink, GetInventoryItemLink("player", 2)or "none");
      elseif itemEquipSlot == "INVTYPE_SHOULDER" then
         table.insert(equipedItemLink, GetInventoryItemLink("player", 3)or "none");
      elseif itemEquipSlot == "INVTYPE_CHEST" or itemEquipSlot == "INVTYPE_ROBE" then
        table.insert(equipedItemLink, GetInventoryItemLink("player", 5)or "none"); 
      elseif itemEquipSlot == "INVTYPE_WAIST" then
         table.insert(equipedItemLink, GetInventoryItemLink("player", 6)or "none");
      elseif itemEquipSlot == "INVTYPE_LEGS" then
         table.insert(equipedItemLink, GetInventoryItemLink("player", 7)or "none");
      elseif itemEquipSlot == "INVTYPE_FEET" then
           table.insert(equipedItemLink, GetInventoryItemLink("player", 8)or "none");
      elseif itemEquipSlot == "INVTYPE_WRIST" then
        table.insert(equipedItemLink, GetInventoryItemLink("player", 9) or "none");
      elseif itemEquipSlot == "INVTYPE_HAND" then
       table.insert(equipedItemLink, GetInventoryItemLink("player", 10)or "none");
      elseif itemEquipSlot == "INVTYPE_FINGER" then
       table.insert(equipedItemLink, GetInventoryItemLink("player", 11)or "none");
        table.insert(equipedItemLink, GetInventoryItemLink("player", 12)or "none");
      elseif itemEquipSlot == "INVTYPE_TRINKET" then
             table.insert(equipedItemLink, GetInventoryItemLink("player", 13)or "none");
        table.insert(equipedItemLink, GetInventoryItemLink("player", 14)or "none");
      elseif itemEquipSlot == "INVTYPE_CLOAK" then
             table.insert(equipedItemLink, GetInventoryItemLink("player", 15)or "none");
      elseif itemEquipSlot == "INVTYPE_WEAPON" then
      -- one hand wep, return both hands
             table.insert(equipedItemLink, GetInventoryItemLink("player", 16)or "none");
        table.insert(equipedItemLink, GetInventoryItemLink("player", 17)or "none");
      elseif itemEquipSlot == "INVTYPE_SHIELD" or itemEquipSlot == "INVTYPE_WEAPONOFFHAND" or itemEquipSlot == "INVTYPE_HOLDABLE" then
        table.insert(equipedItemLink, GetInventoryItemLink("player", 17)or "none");
      elseif itemEquipSlot == "INVTYPE_2HWEAPON" or itemEquipSlot == "INVTYPE_WEAPONMAINHAND" then
        table.insert(equipedItemLink, GetInventoryItemLink("player", 16)or "none");
      elseif itemEquipSlot == "INVTYPE_RANGED" or itemEquipSlot == "INVTYPE_THROWN"  or itemEquipSlot == "INVTYPE_RANGEDRIGHT"then
        table.insert(equipedItemLink, GetInventoryItemLink("player", 18)or "none");
      end
  end
  return equipedItemLink;
end

function lootModule:update()
  print("updating " .. #currentResponses)
  for i = 1, #currentResponses do
    currentResponses[i]:SetPoint("TopLeft", lootFrame, 0, -100*(i-1));
  end

  if #currentResponses == 0 then
    lootFrame:Hide();
  else
    lootFrame:SetSize(900, 100*#currentResponses);
    lootFrame:Show();
  end
end

function lootModule:reQuery()
  for i=1, #checkAgain do
      local itemName = GetItemInfo(checkAgain[i])
    if itemName then
      local itemFound = table.remove(checkAgain, i);
      table.insert(itemsFoundtable,itemFound );
    end
  end
  
  if #itemsFoundtable == numItemsRecived - #currentResponses then  --if all of our items have been found by the client...

    for i = 1, #itemsFoundtable do
          if GetItemInfo(itemsFoundtable[i]:getItemLink()) ~= nil then
            lootModule:addResponse(itemsFoundtable[i]);
         end
    end 
    lootFrame:UnregisterEvent("GET_ITEM_INFO_RECEIVED");
    itemsFoundtable={};
  end  
  

end
-- FRAME methods
function lootModule:createLootFrame()
  
  local frame = CreateFrame("Frame", nil, UIParent);
  frame:SetFrameStrata("HIGH");
  frame:Hide();
  frame:SetPoint("CENTER", UIParent, "CENTER");
  frame:SetSize(900,400);
  frame:SetMovable(true);
  frame:EnableMouse(true);
  frame:RegisterForDrag("LeftButton");
  frame:SetScript("OnDragStart", function () lootFrame:StartMoving() end);
  frame:SetScript("OnDragStop", function () lootFrame:StopMovingOrSizing() end );
    frame:SetScript("OnEvent", function(self, event)
        if event == "GET_ITEM_INFO_RECEIVED"then
         lootModule:reQuery();
        end
         end);
  return frame;
end
function lootModule:getResponseFrame(item, tempResponse)
      if #responseFramePool == 0 then
      for i=1,5 do
        table.insert(responseFramePool,lootModule:createResponseFrame());
      end
      
    end
    local tempResponseFrame = table.remove(responseFramePool, 1);
    
      for i=1, options.numOfResponseButtons do
      tempResponseFrame.buttons[i]:SetText(options.responseButtonNames[i]);
      tempResponseFrame.buttons[i]:Show();
      tempResponseFrame.buttons[i]:SetScript("OnClick", function(self)
        tempResponse:setPlayerResponse(self:GetText());
        tempResponse:setNote(tempResponseFrame.noteBox:GetText());
        lootModule:removeResponse(tempResponseFrame.responseNum);
        lootModule:SendCommMessage( "FLCPREFIX", "itemResponse ".. lootModule:Serialize({itemResponse = tempResponse}), "RAID" );
         end);
      end
      
      tempResponseFrame.responseNum = #currentResponses+ 1;
      tempResponseFrame.iconFrame.texture:SetTexture(item:getItemTexture());
      tempResponseFrame.lootItemName:SetText(GetItemInfo(item:getItemLink()));
      tempResponseFrame.iconFrame.itemCountFontString:SetText(item:getCount());
      
      tempResponseFrame.iconFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(tempResponseFrame.iconFrame, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(item:getItemLink());
        GameTooltip:Show()
      end);
    
      tempResponseFrame.iconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end);
      
    
    return tempResponseFrame;
end

function lootModule:createResponseFrame()
  
  local tempFrame = CreateFrame("Frame", nil,  lootFrame, "TooltipBorderedFrameTemplate");
  -- populate response window
  tempFrame:SetSize(900,100);
  local tempIconFrame = CreateFrame("Frame", nil,  tempFrame);
  tempIconFrame:SetSize(75,75);
  tempIconFrame:SetPoint("TopLeft",tempFrame , 15, -12 )
  
  tempIconFrame.texture = tempIconFrame:CreateTexture();
  tempIconFrame.texture:SetAllPoints(tempIconFrame);
  tempIconFrame.itemCountFontString = tempIconFrame:CreateFontString(nil,"low", "GameFontNormalHuge");  
  tempIconFrame.itemCountFontString:SetPoint("bottomright",0,0);
    
  tempFrame.iconFrame = tempIconFrame;

  
    tempFrame.buttons = {};
    
    for i= 1, 7 do
      local tempButton = CreateFrame("Button", nil, tempFrame, "MagicButtonTemplate" );
      tempButton:SetText(i);
      tempButton:Hide();
      tempButton:SetPoint("TopLeft",tempFrame, 110+ (110*(i-1)), -40);
      
      tempFrame.buttons[i] = tempButton;
    end
    
    
    
    local noteBox = CreateFrame("EditBox", nil , tempFrame, "InputBoxTemplate");
    noteBox:SetSize(700, 20);
    noteBox:SetPoint("TopLeft",110, -70);
    noteBox:SetAutoFocus(false);
    -- OnEnterPressed
    noteBox:SetScript("OnEnterPressed", function(self)
      self:ClearFocus();
    end);  
    tempFrame.noteBox = noteBox;
    
    tempFrame.lootItemName = tempFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
    tempFrame.lootItemName:SetPoint("TopLeft" ,110, -20);
    
  return tempFrame;
end
function lootModule:removeResponse(index)
    local responseFrame =table.remove(currentResponses, index);
    responseFrame:Hide();
    table.insert(responseFramePool, responseFrame);
    for i=index, #currentResponses do
      currentResponses[i].responseNum = currentResponses[i].responseNum -1;
    end
    lootModule:update();
end
