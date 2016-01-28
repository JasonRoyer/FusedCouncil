
 FusedCouncil = LibStub("AceAddon-3.0"):NewAddon("FusedCouncil","AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0");
  FusedCouncil:SetDefaultModuleLibraries("AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0");
  FusedCouncil:SetDefaultModuleState(true);
 FusedCouncil_MainFrame = {};
 FusedCouncil_MinFrame = {};
local labelButtons = {};
local currentItemFontString = {};
local itemsToBeLooted = {};
local itemsLooted = {};
local currentItem;
local currentItemFrame ={};
local currentResponseFrames = {};
local itemToBeLootedFrames = {};
local itemsLootedFrames = {};
local addonPrefix = "FusedCouncil";
local personSelected = "";
local isTesting = false;
local fakePeople = {"bob","steve","jason","Ajohny"}
local optionRespones = 1;
local responseNames = {"Bis", "Major","Minor", "Reroll", "OffSpec", "Transmog", "Pass"};
local options = {
  name ="FusedCouncil",
  type="group",
  -- can have set and get defined to get from DB
  args = {
    global = {
       order =1,
       name = "General config",
       type ="group",
       
       args = {
          help = {
             order=0,
             type = "description",
             name = "FusedCouncil is an in game loot distribution system."
          
          },
          
          buttons = {
            order =1,
            type = "group",
            guiInline = true,
            name = "Response Buttons",
              args = {
                  help = {
                    order =0,
                    type="description",
                    name = "Allows the configuration of response buttons"
                  
                  },
                  numButtons = {
                      type = "range",
                    width = 'full',
                      order = 1,
                      name = "Amount of buttons to display:",
                      min = 1,
                      max = 5,
                      step = 1,
                      set = function(info, val)optionRespones = val end,
                      get = function(info) return optionRespones end,
                  },
                  button1 = {
                    type = "input",
                    name = "button1",
                    set = function(info, val) responseNames[1] = val end,
                    get  = function(info, val) return responseNames[1] end,
                  },    
              },      
          },              
       },
    },
  },

};

function FusedCouncil:OnInitialize()
  
  --Set up frames
  FusedCouncil_MainFrame = CreateMainFrame();
  FusedCouncil_MinFrame = CreateMinFrame();
  -- set DB for saving variables
  self.db = LibStub("AceDB-3.0"):New("FusedCouncilDB");
  

end

function FusedCouncil:OnEnable()
  self:RegisterEvent("LOOT_OPENED", "LootOpenedHandeler");
  self:RegisterComm(addonPrefix, "CoreCommHandler")
   -- LibStub("AceConfig-3.0"):RegisterOptionsTable("FusedCouncil", options, {"fcslash", "fcslashtwo"})
  local config = LibStub("AceConfig-3.0")
  config:RegisterOptionsTable("FusedCouncil Options", options)

  local dialog = LibStub("AceConfigDialog-3.0")
  dialog:AddToBlizOptions("FusedCouncil Options", "FusedCouncil", nil, 'global')
end

function FusedCouncil:OnDisable()

end

function FusedCouncil:LootOpenedHandeler()
  local itemLinks = {};
      for i=1, GetNumLootItems() do
        local lootLink = GetLootSlotLink(i) ;

        table.insert(itemLinks, lootLink); 
        AddItem(Item:new(lootLink));
      end
      
      if #itemLinks > 0 then
      local data = FusedCouncil:Serialize(itemLinks) -- itemLinks is a table of item links
      FusedCouncil:SendCommMessage(addonPrefix, "lootTable " .. data, "RAID");

      FusedCouncil_Update();
      end
end -- end LootOpenedHandeler

function FusedCouncil:Test(itemTable)
    isTesting = true;
    local itemLinks = {};
      for i=1, #itemTable do
        local lootLink = itemTable[i] ;
        table.insert(itemLinks, lootLink); 
        AddItem(Item:new(lootLink));
      end
      if #itemLinks > 0 then
      local data = FusedCouncil:Serialize(itemLinks) -- itemLinks is a table of item links
      FusedCouncil:SendCommMessage(addonPrefix, "lootTable " ..data , "RAID");
    
     FusedCouncil_Update();
      end
end -- end Test
 

function FusedCouncil:CoreCommHandler(prefix, message, distribution, sender)
 if prefix == addonPrefix then
  local cmd, data = strsplit(" ", message, 2);
  local success, responseObject = FusedCouncil:Deserialize(data)
 
  if success then
    if cmd == "addResponse" then
      local newResponse = Response:new(responseObject);
      FC_FindItem(newResponse:getItemLink()):addResponse(newResponse);
      
      for i=1,#fakePeople do
      newResponse = Response:new(responseObject.itemLink, fakePeople[i], responseObject.playerIlvl - i, 0,responseObject.playerGuildRank, responseObject.playerResponse, i, responseObject.playerItem, nil );
      FC_FindItem(newResponse:getItemLink()):addResponse(newResponse);
      end

      
      FusedCouncil_Update();
    elseif cmd == "vote" then
      print("voting")
      local newResponse = Response:new(responseObject);
      local item = FC_FindItem(newResponse:getItemLink());
      item:getResponseFromTable(newResponse:getPlayerName()):addVote(sender);
      FusedCouncil_Update();
    elseif cmd == "unvote" then
      print("unvoting")
      local newResponse = Response:new(responseObject);
      local item = FC_FindItem(newResponse:getItemLink());
      item:getResponseFromTable(newResponse:getPlayerName()):removeVote(sender);
      FusedCouncil_Update();
    end
  else
    print("Deserialization unsuccessful")
  end
  end
end -- end CoreCommHandler

function AddItem(item)
  table.insert(itemsToBeLooted, item);
  table.insert(itemToBeLootedFrames, FC_GetFreeItemFrame(item));
  
  if currentItem == nil then
     SetCurrentItem(item);
  end
end


function SetCurrentItem(item)
 if currentItem ~= nil then
    ReleaseItemFrame(currentItemFrame);
    for i=1, #currentResponseFrames do
      ReleaseResponseFrame(currentResponseFrames[i]);
      currentResponseFrames[i] = nil;
    end
    personSelected = "";
 end
     currentItem = item;
     currentItemFrame = FC_GetFreeItemFrame(item);
     currentItemFrame:SetPoint("TopLeft", FusedCouncil_MainFrame, 50, -50);
     currentItemFontString:SetText(currentItem:getItemLink());
   FusedCouncil_Update();  
  
end -- end SetCurrentItem
function ClearForNextUse()
 currentItemFontString = {};
 itemsToBeLooted = {};
 itemsLooted = {};
 currentItem = nil;
 currentItemFrame ={};
  for i=1, #currentResponseFrames do
  ReleaseResponseFrame(table.remove(currentResponseFrames, 1));
 end
 for i=1, #currentResponseFrames do
 
 end
 for i=1, #itemToBeLootedFrames do
  ReleaseItemFrame(table.remove(itemToBeLootedFrames, 1));
 end
  for i=1, #itemsLootedFrames do
  ReleaseItemFrame(table.remove(itemsLootedFrames, 1));
 end
 personSelected = "";
 FusedCouncil_MainFrame:Hide();
end
function FC_GiveItem()
  -- fix all this nonsense
  -- does loot change if you loot 1 item then reopen it?
  -- could proccess the loot after you open it again, aka look for item links
  --getlootbyitemLink() function?
  if personSelected ~= "" and FC_FindItemIndex(itemsToBeLooted, currentItem:getItemLink()) ~= -1 then
    local index = FC_FindItemIndex(itemsToBeLooted, currentItem:getItemLink());
    print(index)
    local itemGiven = table.remove(itemsToBeLooted, index);
    local itemGivenFrame = table.remove(itemToBeLootedFrames, index);
    table.insert(itemsLooted, itemGiven);
    itemGivenFrame.highlightFrame:Show();
    table.insert(itemsLootedFrames, itemGivenFrame);
    
    
    if #itemsToBeLooted == 0 then
      ClearForNextUse();
    else
      SetCurrentItem(itemsToBeLooted[1]);
      FusedCouncil_Update();
    end
    
  end
end
function FusedCouncil_Update()

    -- repaint all of the items in items[]
    if itemToBeLootedFrames ~= nil then
      for i=1, #itemToBeLootedFrames do 
        itemToBeLootedFrames[i]:SetPoint("TopLeft", FusedCouncil_MainFrame, 20 + 60 * (i-1), -430);
      end
      
    end
    
    if itemsLootedFrames ~= nil then
      for i=1, #itemsLootedFrames do 
        itemsLootedFrames[i]:SetPoint("TopLeft", FusedCouncil_MainFrame, 20 + 60 * (#itemToBeLootedFrames + i-1), -430);
      end
      
    end
    -- free current responses
    for i=1, #currentResponseFrames do
        ReleaseResponseFrame(currentResponseFrames[i]);
    end
    currentResponseFrames = {};
    -- repaint all the responses
    for i=1, #currentItem:getResponseTable() do
        FusedCouncil_AddResponse(currentItem:getResponseTable()[i]);
        currentResponseFrames[i]:SetPoint("Top", 0, (-30*i) );
        if personSelected == currentResponseFrames[i].subFrames[1].fontString:GetText() then
          currentResponseFrames[i].texture:SetTexture(.9,.9,.1,.5);
        else
          currentResponseFrames[i].texture:SetTexture(.9,.9,.1,.1);
        end
        currentResponseFrames[i]:Show();
    end


end
 
function FC_FindItemIndex(itemTable, itemLink)
  for i=1, #itemTable do
    if itemTable[i]:getItemLink() == itemLink then
      return i;
    end
  end
  return -1;
end
function FC_FindItem(itemLink)
  for i=1, #itemsToBeLooted do
    if itemsToBeLooted[i]:getItemLink() == itemLink then
      return itemsToBeLooted[i];
    end
  end
  return nil;
end

function FC_Sort(table, sortFunction)
    -- if the table is alreaded sorted isSorted will stay true
    local isSorted = true;
    for i=1, #table-1 do
      local j=i;
      while j > 0 and sortFunction(table[j], table[j+1]) do
          isSorted = false;
          local temp = table[j];
          table[j] = table[j+1];
          table[j+1] = temp;
          j=j-1;
      end
    end
    -- if it was already sorted reverse the list
    if isSorted then
      for i=1, #table/2 do
        local temp = table[i];
        table[i] = table[#table - (i-1)]
        table[#table - (i-1)] = temp;
      end
    end

end
-------------------------------------------
-------     CREATE FRAMES SECTION ---------
-------------------------------------------

local itemFramePool = {};
local responseFramePool = {};
function CreateMainFrame()
  local tempFrame = CreateFrame("Frame", nil,  UIParent, "PortraitFrameTemplate");
  tempFrame:SetPoint("CENTER", UIParent, "CENTER");
  tempFrame:SetSize(900,425);
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
  titleFontString:SetText("Fused Council")
  titleFontString:SetPoint("Top" ,0, -5)



  -- Create Minimize button
  minButton = CreateFrame("Button", "FLC_MinButton", tempFrame, "MagicButtonTemplate" );
  minButton:SetSize(23,23);
  minButton:SetText("-");
  minButton:SetBackdropBorderColor(0,0,0,0);
  minButton:ClearAllPoints();
  minButton:SetPoint("TopRight",tempFrame, -23, 1);

  minButton:SetScript("OnMouseup", function()
    FusedCouncil_MainFrame:Hide();
    FusedCouncil_MinFrame:Show();
  end );
  
    -- create reponse table attributes
  --                      1     2       3           4           5         6         7               9
  local labelsNames = {"Name","ilvl","Score", "Current Item", "Rank", "Response", "Note", "Vote", "Votes"}

  for i=1 , #labelsNames do
    labelButtons[i] = CreateFrame("Button", labelsNames[i].."LabelButton", tempFrame, "MagicButtonTemplate" );
    labelButtons[i]:SetText(labelsNames[i]);
    labelButtons[i]:SetPoint("TopLeft",tempFrame, 20+ (90*(i-1)), -100);
    labelButtons[i]:SetScript("OnMouseDown", function()  
       if currentItem ~= nil then
          if i == 1 then
          FC_Sort(currentItem:getResponseTable(), FC_Utils.nameCompare);
          elseif i==2 then
          FC_Sort(currentItem:getResponseTable(), FC_Utils.ilvlCompare);
          elseif i ==3 then
          FC_Sort(currentItem:getResponseTable(), FC_Utils.scoreCompare);
          elseif i==4 then
          FC_Sort(currentItem:getResponseTable(), FC_Utils.itemCompare);
          elseif i==5 then
          FC_Sort(currentItem:getResponseTable(), FC_Utils.rankCompare);
          elseif i==6 then
          
          FC_Sort(currentItem:getResponseTable(), FC_Utils.responseCompare);
          elseif i==7 then
          FC_Sort(currentItem:getResponseTable(), FC_Utils.noteCompare);
          elseif i==9 then
          FC_Sort(currentItem:getResponseTable(), FC_Utils.votesCompare);
          end
          FusedCouncil_Update();
       end
    
    end);
  end
  
  local giveButton = CreateFrame("Button", nil, tempFrame, "MagicButtonTemplate" );
  giveButton:SetText("Give Loot");
  giveButton:SetPoint("TopLeft", 380, -390);
  
  giveButton:SetScript("OnMouseup", function()

    FC_GiveItem();
  end );

  tempFrame:CreateTexture("ItemFrameTexture");
  ItemFrameTexture:SetTexture("Interface\\BUTTONS\\UI-Slot-Background.blp");
  ItemFrameTexture:SetSize(75,75);
  ItemFrameTexture:SetPoint("TopLeft", 50, -50);

  currentItemFontString = tempFrame:CreateFontString(nil, "BACKGROUND", "GameFontNormal")
  currentItemFontString:SetPoint("TopLeft",100 ,-55)


  -- Create the scrollFrame for the list of responses

  local responseFrame = CreateFrame("ScrollFrame", "responseFrame",  tempFrame, "MinimalScrollFrameTemplate");
  responseFrame:SetPoint("TopLeft", tempFrame, 20, -125);
  responseFrame:SetSize(800,250);
  responseFrame.background  = responseFrame:CreateTexture("responseFrameBackgroundTexture", "BACKGROUND");
  responseFrame.background:SetTexture(.1,.2,.1, .5);
  responseFrame.background:SetAllPoints(responseFrame);
  responseFrame:EnableMouse(true);

  local childFrame = CreateFrame("Frame", "childFrame",  tempFrame);
  childFrame:SetSize(800,1000);
  responseFrame:SetScrollChild(childFrame);
  tempFrame.childFrame = childFrame;
  
  


return tempFrame;
end -- end CreateMainFrame

function CreateMinFrame()

  -- Create a window for when we minimize the main window
  local minFrame = CreateFrame("Frame", "lcMinFrame",  UIParent, "PortraitFrameTemplate");
  -- create easier name to deal with
  minFrame:SetPoint("TopRight", FusedCouncil_MainFrame, "TopRight");
  minFrame:SetSize(100,75);
  minFrame:Hide();

  -- Create Maximize button
  maxButton = CreateFrame("Button", "lcMinFrameMaxButton", minFrame, "MagicButtonTemplate" );
  maxButton:SetSize(23,23);
  maxButton:SetText("+");
  maxButton:SetBackdropBorderColor(0,0,0,0);
  maxButton:ClearAllPoints();
  maxButton:SetPoint("TopRight",minFrame, -23, 1);

  maxButton:SetScript("OnMouseup", function()
    FusedCouncil_MinFrame:Hide();
    FusedCouncil_MainFrame:Show();
  end );

  -- Create portrait icon for minWindow
  minFrame:CreateTexture("minillidanTexture");
  SetPortraitToTexture("minillidanTexture", "Interface\\ICONS\\Achievement_Boss_Illidan.blp")
  minillidanTexture:SetPoint("TopLeft", -10, 10);
  
  return minFrame;
end -- end CreateMinFrame

function FC_GetFreeItemFrame(item)
  if #itemFramePool == 0 then
    for i=1,5 do
      table.insert(itemFramePool,CreateItemFrame());
    end

  end
  local tempItemFrame =  table.remove(itemFramePool, 1);
  tempItemFrame.texture:SetTexture(item:getItemTexture());
  tempItemFrame:Show();
  tempItemFrame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(tempItemFrame, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(item:getItemLink());
    GameTooltip:Show()
  end);

  tempItemFrame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end);
  
  tempItemFrame:SetScript("OnMouseDown", function()
    SetCurrentItem(item);
  end);
  
  return tempItemFrame;
end -- end FC_GetFreeItemFrame
function FC_GetFreeResponseFrame(response)
  if #responseFramePool == 0 then
    for i=1,5 do
      table.insert(responseFramePool,CreateResponseFrame());
    end

  end
  return table.remove(responseFramePool, 1);

end -- end FC_GetFreeResponseFrame


function CreateItemFrame()
  local tempFrame = CreateFrame("Frame", nil, FusedCouncil_MainFrame);
  tempFrame:SetSize(50,50);
  tempFrame.texture = tempFrame:CreateTexture(nil, "BACKGROUND");
  tempFrame.texture:SetAllPoints(tempFrame);
  tempFrame.highlightFrame = CreateFrame("Frame", nil, tempFrame);
  tempFrame.highlightFrame:SetSize(50,50);
  tempFrame.highlightFrame:SetPoint("TopLeft",0,0);
  tempFrame.highlightFrame:Hide();
  tempFrame.highlightFrame.texture = tempFrame.highlightFrame:CreateTexture();
  tempFrame.highlightFrame.texture:SetTexture(1,0,0,.2);
  tempFrame.highlightFrame.texture:SetSize(50,50);
  tempFrame.highlightFrame.texture:SetPoint("TopLeft", 0, 0)

  return tempFrame;
end
function CreateResponseFrame()
  local tempFrame =  CreateFrame("Frame", nil,  FusedCouncil_MainFrame.childFrame);
   tempFrame:SetSize(800,25);
  tempFrame:Hide();
  tempFrame:EnableMouse(true);
  tempFrame.texture = tempFrame:CreateTexture(nil, "BACKGROUND");
  tempFrame.texture:SetAllPoints(tempFrame);
  tempFrame:SetScript("OnMouseDown", function()
      personSelected = tempFrame.subFrames[1].fontString:GetText();
      FusedCouncil_Update();
  end );
  
  tempFrame.subFrames = {};
  for i =1, 9 do
    tempFrame.subFrames[i] = CreateFrame("Frame", nil,  tempFrame);
    tempFrame.subFrames[i] :SetSize(88,25);
    tempFrame.subFrames[i] :SetPoint("TopLeft",(90*(i-1)),0);
    tempcolor= tempFrame.subFrames[i] :CreateTexture(nil, "BACKGROUND");
 --   tempcolor:SetTexture(1-(.1*i),1-(.1*i),.1, .5);
    tempcolor:SetAllPoints(tempFrame.subFrames[i] );
    if i == 4 then
      tempFrame.subFrames[i].itemFrames = {};
      for k=1,3 do 
        local tempItemFrame = CreateFrame("Frame", nil,tempFrame.subFrames[i]);
        tempItemFrame:SetSize(25,25);
        if k == 1 then
            tempItemFrame:SetPoint("Center",0,0);
        elseif k == 2 then
            tempItemFrame:SetPoint("Center",-13,0);
        elseif k == 3 then
            tempItemFrame:SetPoint("Center",13,0);
        end
         tempItemFrame.itemTexture = tempItemFrame:CreateTexture(nil,"Background")
         tempItemFrame.itemTexture:SetAllPoints(tempItemFrame);
          tempFrame.subFrames[i].itemFrames[k] = tempItemFrame;
      end -- end for loop k
    elseif i == 7 then
          local noteFrame = CreateFrame("Frame", nil,tempFrame.subFrames[i]);
          noteFrame:SetSize(35,35);
          noteFrame:SetPoint("Center",0,0);
          noteFrame.texture = noteFrame:CreateTexture(nil,"Background")
          noteFrame.texture:SetAllPoints(noteFrame);
          tempFrame.subFrames[i].noteFrame = noteFrame;
      
    elseif i ==8 then
          tempFrame.subFrames[i].voteButton = CreateFrame("Button", nil, tempFrame.subFrames[i], "MagicButtonTemplate" );
          tempFrame.subFrames[i].voteButton:SetText("Vote");
          tempFrame.subFrames[i].voteButton:SetPoint("Center",0,0);
    else
      tempFrame.subFrames[i].fontString = tempFrame.subFrames[i]:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
      tempFrame.subFrames[i].fontString:SetPoint("CENTER",0, 0);
    end
  end
 
 return tempFrame;
end

function FusedCouncil_SetupSubFrameFour(frame, responseObject)
  local numItemsEquip = #responseObject:getPlayerItem();
  if numItemsEquip > 0 and responseObject:getPlayerItem()[1] ~= "none" then
    if numItemsEquip == 1 then
         frame.itemFrames[1]:Show();
        frame.itemFrames[1].itemTexture:SetTexture(select(10,GetItemInfo(responseObject:getPlayerItem()[1])));
        
        frame.itemFrames[1]:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.itemFrames[1], "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(responseObject:getPlayerItem()[1]);
        GameTooltip:Show()
       end);
       frame.itemFrames[1]:SetScript("OnLeave", function()
          GameTooltip:Hide();
       end);
    else
       for i=1,2 do
        frame.itemFrames[i+1]:Show();
        frame.itemFrames[i+1].itemTexture:SetTexture(select(10,GetItemInfo(responseObject:getPlayerItem()[i])));
        
        frame.itemFrames[i+1]:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.itemFrames[i+1], "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(responseObject:getPlayerItem()[i]);
        GameTooltip:Show()
       end);
       frame.itemFrames[i+1]:SetScript("OnLeave", function()
          GameTooltip:Hide()
       end);
       end
    end
  end
end -- end FusedCouncil_SetupSubFrameFour

function FusedCouncil_SetupSubFrameSeven(frame, responseObject)

  if responseObject:getNote() == "" then
  frame.noteFrame.texture:SetTexture("Interface\\CHATFRAME\\UI-ChatIcon-Chat-Disabled.blp");
  else
  frame.noteFrame.texture:SetTexture("Interface\\CHATFRAME\\UI-ChatIcon-Chat-Up.blp");
  end
  frame.noteFrame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(frame.noteFrame, "ANCHOR_RIGHT")
    GameTooltip:SetText(responseObject:getNote());
    GameTooltip:Show()
  end);

  frame.noteFrame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end);
end -- end FusedCouncil_SetupSubFrameSeven

function FusedCouncil_SetupSubFrameEight(frame,responseObject)
   local votes = responseObject:getVotes();
  for i=1, #votes do
      if votes[i] == UnitName("player") then
          frame.voteButton:SetText("UnVote");
      end
  end
  frame.voteButton:SetScript("OnClick", function(self) 

      if self:GetText() == "Vote" then 
         if not currentItem:hasVoteFrom(UnitName("player")) then
        self:SetText("UnVote");
        FusedCouncil:SendCommMessage(addonPrefix, "vote ".. FusedCouncil:Serialize(responseObject), "RAID");
        end
      elseif self:GetText() == "UnVote" then
        self:SetText("Vote");
        FusedCouncil:SendCommMessage(addonPrefix, "unvote ".. FusedCouncil:Serialize(responseObject), "RAID");
      end

  end);
 
end

function FusedCouncil_AddResponse(responseObject)
 local response = FC_GetFreeResponseFrame();
  
  response.subFrames[1].fontString:SetText(responseObject:getPlayerName());
  response.subFrames[2].fontString:SetText(responseObject:getPlayerIlvl());
  response.subFrames[3].fontString:SetText(responseObject:getPlayerScore());
  FusedCouncil_SetupSubFrameFour(response.subFrames[4], responseObject);
  response.subFrames[5].fontString:SetText(responseObject:getPlayerGuildRank());
  response.subFrames[6].fontString:SetText(responseObject:getPlayerResponse());
  FusedCouncil_SetupSubFrameSeven(response.subFrames[7], responseObject);
  FusedCouncil_SetupSubFrameEight(response.subFrames[8], responseObject);
  response.subFrames[9].fontString:SetText(#responseObject:getVotes());

  
  table.insert(currentResponseFrames, response);
end -- end  FusedCouncil_AddResponse

function ReleaseItemFrame(frame)
  frame:Hide();
  frame.highlightFrame:Hide();
  table.insert(itemFramePool, frame);
end
function ReleaseResponseFrame(frame)
  frame:Hide();
  for i=1,3 do
    frame.subFrames[4].itemFrames[i]:Hide();
  end
  frame.subFrames[8].voteButton:SetText("Vote");
  
  table.insert(responseFramePool, frame);
end

SLASH_FLC1 = "/flc"
SlashCmdList["FLC"] = function() 
  print("slash cammand")
    FusedCouncil:Test({GetInventoryItemLink("player",1),GetInventoryItemLink("player",5)})
  end
 
