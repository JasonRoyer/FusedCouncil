--[[
  This page contains code for the pop up response window.
A table of item links is passed via Ace3Comm lib and proccessed.
Then a response is sent back as a table 
the table feilds are:
  link - the item link of the item to respond about
  name - the name of the player responding
  ilvl - the ilvl of the player responding
  score - the score of the player responding (to be implemented later)
  rank - the guild rank of the player responding
  response - the response about the item IE pass, need ext...
  note - a note writen by the player responding to the loot council
  currentItem - the item the player responding currently has equiped


]]--
local addon = LibStub("AceAddon-3.0"):GetAddon("FusedCouncil");
-- LootModule = LibStub("AceAddon-3.0"):NewAddon("FusedCouncil_LootFrame","AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0");
LootModule = addon:NewModule("FusedCouncil_LootFrame");

-- The main frame that contains the frames for responding
FusedCouncil_LootFrame = {};
-- A pool of frames that are used to generate the content within the main frame
local responseFramePool = {};
-- a table of the current frames being used to show content on the main frame
local currentResponses = {};
local itemTablex = {};
local itemsFound = 0
local checkAgain = {}
local itemsFoundAgain = {};
local optionsx = {};
function LootModule:OnInitialize()
  FusedCouncil_LootFrame = FC_CreateLootFrame();
end



function LootModule:OnEnable()
  self:RegisterComm("FusedCouncil");
end


-- The function fired everytime the prefix is recived. More info under Ace3comm.
function LootModule:OnCommReceived(prefix, message, distribution, sender)
 
    -- split the message into the camand and the serialized data(Ace3), strsplit is in the wow api.
   local cmd, data, optionsTable = strsplit(" ", message, 3);
   
   if cmd == "lootTable" then
      local success, options = LootModule:Deserialize(optionsTable);
      
      if success then
        optionsx = options;

        local success2, itemTable = LootModule:Deserialize(data);
        if success2 then
          itemTablex = itemTable;
          for i = 1, #itemTable do
            if GetItemInfo(itemTable[i]) ~= nil then
               FC_AddResponse(itemTable[i]);
            else 
               table.insert(checkAgain, itemTable[i]);
               FusedCouncil_LootFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
           end
          end
        else
           print("failed " .. itemTable);
        end
      else
        print("failed " .. options);
      end
   
   end
   
   
 
    
end -- end LootCommHandler



local function ReQuery()
  for i=1, #checkAgain do
      local itemName = GetItemInfo(checkAgain[i])
    if itemName then
      local itemFound = table.remove(checkAgain, i);
      table.insert(itemsFoundAgain,itemFound );
      itemsFound = itemsFound + 1
    end
  end
  
  if itemsFound == #itemTablex then  --if all of our items have been found by the client...

    for i = 1, #itemsFoundAgain do
          if GetItemInfo(itemsFoundAgain[i]) ~= nil then
             FC_AddResponse(itemsFoundAgain[i]);
         end
    end 
    FusedCouncil_LootFrame:UnregisterEvent("GET_ITEM_INFO_RECEIVED")
    itemsFound = 0;
    itemsFoundAgain={};
  end
end

function LootModule:OnDisable()

end


--[[
   Takes an empty responseFrame from the pool and fills in item information from the link provided.
  The frame is the visual window for responding when sent an item. The frame contains a table with
  fields relating to what is needed to respond(see top of class)
  
  @param  lootLink  an item link supplied by the wow api to identify an item.

]]
function FC_AddResponse(itemLink)
   local _, myIlvl = GetAverageItemLevel();
  -- GetItemInfo will return nil if the player has not seen the item before, aka my lvl 10
  local itemEquipSlot, itemTexture = select(9, GetItemInfo(itemLink));
  local tempResponse = Response:new(itemLink, GetUnitName("player",false),math.floor(myIlvl+0.5),nil,select(2, GetGuildInfo("player")),nil,nil,FC_GetPlayersCurrentItem(itemLink));

  local tempResponseFrame = FC_GetResponseFrame(FusedCouncil_LootFrame);
  tempResponseFrame.ResponseNum = #currentResponses+ 1;
  
  for i=1, optionsx.numButtons do
      tempResponseFrame.Buttons[i]:SetText(optionsx.responseNames[i]);
      tempResponseFrame.Buttons[i]:Show();
      tempResponseFrame.Buttons[i]:SetScript("OnClick", function(self)
        tempResponse:setPlayerResponse(self:GetText());
        tempResponse:setNote(tempResponseFrame.NoteBox:GetText());
        RC_RemoveResponse(tempResponseFrame.ResponseNum);
        LootModule:SendCommMessage( "FusedCouncil", "addResponse ".. LootModule:Serialize(tempResponse), "RAID" );
     end);
  end
  
  tempResponseFrame.IconFrame.Texture:SetTexture(itemTexture);

  tempResponseFrame.IconFrame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(tempResponseFrame.IconFrame, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(itemLink);
    GameTooltip:Show()
  end);

  tempResponseFrame.IconFrame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end);
  tempResponseFrame.LootItemName:SetText(GetItemInfo(itemLink));

  tempResponseFrame.response = tempResponse;
  table.insert(currentResponses, tempResponseFrame);
  FC_Update();
  
end -- end FC_AddResponse


--[[
  Return the item that is currently equpped in the slot that also goes with the itemLink provided.
  
  @Param itemLink
  @return itemLink
]]
function FC_GetPlayersCurrentItem(itemLink)

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
end -- end FC_GetPlayersCurrentItem




function RC_RemoveResponse(index)
    FC_ReleaseResponseFrame(table.remove(currentResponses, index));
    for i=index, #currentResponses do
      currentResponses[i].ResponseNum = currentResponses[i].ResponseNum -1;
    end
    FC_Update();
end -- end RC_RemoveResponse


function FC_Update()
  for i = 1, #currentResponses do
    currentResponses[i]:SetPoint("TopLeft", FusedCouncil_LootFrame, 0, -100*(i-1));
  end

  if #currentResponses == 0 then
    FusedCouncil_LootFrame:Hide();
  else
    FusedCouncil_LootFrame:SetSize(900, 100*#currentResponses);
    FusedCouncil_LootFrame:Show();
  end
end -- end FC_Update

function FC_GetResponseFrame(parent)
    if #responseFramePool == 0 then
      for i=1,5 do
        table.insert(responseFramePool,FC_CreateResponseFrame(parent));
      end
      
    end
    return table.remove(responseFramePool, 1);

end -- end FC_GetResponseFrame

function FC_CreateResponseFrame(parent)
  
  local tempFrame = CreateFrame("Frame", nil,  parent, "TooltipBorderedFrameTemplate");
  -- populate response window
  tempFrame:SetSize(900,100);
  local tempIconFrame = CreateFrame("Frame", nil,  tempFrame);
  tempIconFrame:SetSize(75,75);
  tempIconFrame:SetPoint("TopLeft",tempFrame , 15, -12 )
  
  tempIconFrame.Texture = tempIconFrame:CreateTexture();
  tempIconFrame.Texture:SetAllPoints(tempIconFrame);
    
  tempFrame.IconFrame = tempIconFrame;  
  
    tempFrame.Buttons = {};
    
    for i= 1, 7 do
      local tempButton = CreateFrame("Button", nil, tempFrame, "MagicButtonTemplate" );
      tempButton:SetText(i);
      tempButton:Hide();
      tempButton:SetPoint("TopLeft",tempFrame, 110+ (110*(i-1)), -40);
      
      tempFrame.Buttons[i] = tempButton;
    end
    
    
    
    local noteBox = CreateFrame("EditBox", nil , tempFrame, "InputBoxTemplate");
    noteBox:SetSize(700, 20);
    noteBox:SetPoint("TopLeft",110, -70);
    noteBox:SetAutoFocus(false);
    -- OnEnterPressed
    noteBox:SetScript("OnEnterPressed", function(self)
      self:ClearFocus();
    end);  
    tempFrame.NoteBox = noteBox;
    
    tempFrame.LootItemName = tempFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
    tempFrame.LootItemName:SetPoint("TopLeft" ,110, -20);
    
  return tempFrame;
end -- end createResponseFrame



function FC_ReleaseResponseFrame(frame)
  frame:Hide();
  table.insert(responseFramePool, frame);
end

function FC_CreateLootFrame()

  local frame = CreateFrame("Frame", "memberFrame", UIParent);
  frame:SetFrameStrata("HIGH");
  frame:Hide();
  frame:SetPoint("CENTER", UIParent, "CENTER");
  frame:SetSize(900,400);
  frame:SetMovable(true);
  frame:EnableMouse(true);
  frame:RegisterForDrag("LeftButton");
  frame:SetScript("OnDragStart", function () FusedCouncil_LootFrame:StartMoving() end);
  frame:SetScript("OnDragStop", function () FusedCouncil_LootFrame:StopMovingOrSizing() end );
  frame:SetScript("OnEvent", function(self, event)
        if event == "GET_ITEM_INFO_RECEIVED"then
        print("recived info")
         ReQuery();
        end
         end);
  return frame;
end
