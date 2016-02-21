local fusedCouncil = LibStub("AceAddon-3.0"):NewAddon("fusedCouncil","AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0", "AceHook-3.0", "AceTimer-3.0");
 
-- GUI components
local mainFrame;
local minFrame;
local itemsToBeLootedFrames= {};
local itemsLootedFrames = {};
local currentResponseFrames = {};
local currentItemFrame = {};
local currentItemFontString = {};

-- Engine components
local currentItem;
local personSelected;
local itemsToBeLooted;
local itemsLooted;
local lootMethod;
local isMasterLooter;
local isCurrentlyLooting;
local currentLootWindowItems;
local addonPrefix = "FLCPREFIX";
local isTesting;
local dbProfile;
local dbDefaults = {
 
  profile = {
    options = {
      numOfResponseButtons = 7,
      responseButtonNames = {"Bis", "Major","Minor", "Reroll", "OffSpec", "Transmog", "Pass"},
      lootCouncilMembers = {UnitName("player")},
    },
    isTesting = false,
    initializeFromDB = false,
    currentItem = nil,
    personSelected = "",
    itemsToBeLooted = {},
    itemsLooted = {},
  },

};
function fusedCouncil:OnInitialize()
  -- set up GUI components
  mainFrame = fusedCouncil:createMainFrame();
  minFrame = fusedCouncil:createMinFrame();
  
  -- set up DB for saving variables
  self.db = LibStub("AceDB-3.0"):New("FusedCouncilDB",dbDefaults, true);
  self.db:RegisterDefaults(dbDefaults);
  dbProfile = self.db.profile;
    currentItem = nil;
    personSelected = "";
    itemsLooted = {};
    itemsToBeLooted = {};
  if dbProfile.initializeFromDB then
    fusedCouncil:initializeFromDB();
    fusedCouncil:update();

  end
  
  
end


function fusedCouncil:OnEnable()
  -- register events and addonPrefix for ace3 comm
  self:RegisterEvent("LOOT_OPENED", "LootOpenedHandler");
  self:RegisterComm(addonPrefix, "CommHandler");
  self:RegisterChatCommand("flc", function(input) 
     local args = {strsplit(" ", input)};
        if args[1] ~= nil then
            if args[1] == "options" then
            
            elseif args[1] == "help" then
            
            elseif args[1] == "test" then
                fusedCouncil:test({GetInventoryItemLink("player",1),GetInventoryItemLink("player",1)});
            else
              print("Unrecognized cmd");
            end
        else
          print("no cmd was entered");
        end
  -- options
  -- help
  -- test
  
  
  
  end);
  -- see if this player is currently the ML
  local lootMethodString, masterLooter = GetLootMethod();
  lootMethod = lootMethodString;
  
  if masterLooter == 0 then
    isMasterLooter = true;
  else
    isMasterLooter = false;
  end 
  -- register options
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
                        max = 7,
                        step = 1,
                        set = function(info, val)  dbProfile.options.numOfResponseButtons = val end,
                        get = function(info) return dbProfile.options.numOfResponseButtons end,
                    },
                    button1 = {
                      type = "input",
                      name = "button1",
  
                      order = 2,
                      set = function(info, val) dbProfile.options.responseButtonNames[1] = val end,
                      get  = function(info, val) return dbProfile.options.responseButtonNames[1] end,
                    },
                    button2 = {
                      type = "input",
                      name = "button2",
                      order = 3,
                      hidden = function () return dbProfile.options.numOfResponseButtons < 2 end,
                      set = function(info, val) dbProfile.options.responseButtonNames[2] = val end,
                      get  = function(info, val) return dbProfile.options.responseButtonNames[2] end,
  
                    },
                    button3 = {
                      type = "input",
                      name = "button3",
  
                      order = 4,
                      hidden = function () return dbProfile.options.numOfResponseButtons < 3 end,
                      set = function(info, val) dbProfile.options.responseButtonNames[3] = val end,
                      get  = function(info, val) return dbProfile.options.responseButtonNames[3] end,
  
                    },
                    button4 = {
                      type = "input",
                      name = "button4",
  
                      order = 5,
                      hidden = function () return dbProfile.options.numOfResponseButtons < 4 end,
                      set = function(info, val) dbProfile.options.responseButtonNames[4] = val end,
                      get  = function(info, val) return dbProfile.options.responseButtonNames[4] end,
                    },  
                    button5 = {
                      type = "input",
                      name = "button5",
                      order = 6,
                      hidden = function () return dbProfile.options.numOfResponseButtons < 5 end,
                      set = function(info, val) dbProfile.options.responseButtonNames[5] = val end,
                      get  = function(info, val) return dbProfile.options.responseButtonNames[5] end,
                    },
                    button6 = {
                      type = "input",
                      name = "button6",
                      order = 7,
                      hidden = function () return dbProfile.options.numOfResponseButtons < 6 end,
                      set = function(info, val) dbProfile.options.responseButtonNames[6] = val end,
                      get  = function(info, val) return dbProfile.options.responseButtonNames[6] end,
                    },
                    button7 = {
                      type = "input",
                      name = "button7",
                      order = 8,
                      hidden = function () return dbProfile.options.numOfResponseButtons < 7 end,
                      set = function(info, val) dbProfile.options.responseButtonNames[7] = val end,
                      get  = function(info, val) return dbProfile.options.responseButtonNames[7] end,
                    },                      
                },      
            },
            lootCouncilGroup = {
              order =2,
              type = "group",
              guiInline = true,
              name = "Loot Council",
                args = {
                    help = {
                      order =0,
                      type="description",
                      name = "Allows the configuration of the members on council"
                    
                    },
                    councilInput = {
                      type = "input",
                      name = "Loot Council Member",
                      order = 1,
                      width = "full",
                      set = function(info, val) 
                             -- get string convert to array store array
                              -- { multple values } instantly creates an array with those values
                             dbProfile.options.lootCouncilMembers = {strsplit(",", val)};
                              end,
                      get  = function(info, val) 
                             -- take stored array convert to string and return string
                             local tempString = "";
                           for i=1, #dbProfile.options.lootCouncilMembers do
                           if i == 1 then
                              tempString = dbProfile.options.lootCouncilMembers[i];
                           else
                              tempString = tempString .. "," .. dbProfile.options.lootCouncilMembers[i];
                           end
                           
                           end
                           
                           return tempString;
                       end,
                    },
                    
                },    
            },
            reset = {
              type = "execute",
              name = "reset defaults",
              func = function() fusedCouncil.db:ResetProfile(); end,
              
              
            },
                          
         },
      },
    },
  
  };
  
  LibStub("AceConfig-3.0"):RegisterOptionsTable("FusedCouncil Options", options);
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("FusedCouncil Options", "FusedCouncil", nil, 'global');
end

function fusedCouncil:OnDisable()

end
function fusedCouncil:CommHandler(prefix, message, distribution, sender)
  if prefix == addonPrefix then
     
     local cmd, serializedPayload = strsplit(" ", message, 2);
     local success, payload = self:Deserialize(serializedPayload);
     
     if success then
        -- payload is {lootTable, optionsTable}
        if cmd == "lootTable" then
            if fusedCouncil:playerInCouncil(payload.optionsTable.lootCouncilMembers) and not isMasterLooter and sender ~= UnitName("player") then
                for i=1, #payload.lootTable do
                  local foundItem = fusedCouncil:findItem(itemsToBeLooted, payload.lootTable[i]);
                  if foundItem ~= nil then
                     foundItem:setCount(foundItem:getCount() + 1);
                  else
                     fusedCouncil:addItem(Item:new(payload.lootTable[i]));
                  end
                 
                end
            end -- end if councilmember
        elseif cmd == "itemResponse" then
            print("got a response")
            local newResponse = Response:new(payload.itemResponse);
            fusedCouncil:findItem(itemsToBeLooted,newResponse:getItemLink()):addResponse(newResponse);
        elseif cmd == "vote" then
            local item = fusedCouncil:findItem(itemsToBeLooted,payload.itemLink);
            if item ~= nil then
                item:getResponseFromTable(payload.player):addVote(sender);
            end
        elseif cmd =="unvote" then
            local item = fusedCouncil:findItem(itemsToBeLooted,payload.itemLink);
            if item ~= nil then
                item:getResponseFromTable(payload.player):removeVote(sender);
            end
        elseif cmd == "itemLooted" then
            local item = fusedCouncil:findItem(itemsToBeLooted,payload.itemLink);
            if item ~= nil and not isMasterLooter then
                fusedCouncil:itemGivenHandler(item);
            end
        
        end -- end cmd check
        fusedCouncil:update();
     else
        print("Deserialization of payload in CommHandler failed")
     end -- end success check
  
  end -- end prefix matched
end
function fusedCouncil:LootOpenedHandler()

end




-- Engine methods

function fusedCouncil:update()
    
    -- repaint all of the items in items[]
    if itemsToBeLootedFrames ~= nil then
      for i=1, #itemsToBeLootedFrames do 
        itemsToBeLootedFrames[i]:SetPoint("TopLeft", mainFrame, 20 + 60 * (i-1), -430);
        local count = itemsToBeLooted[i]:getCount();
        if count > 1 then
           itemsToBeLootedFrames[i].itemCountFontString:SetText(count);
        else
          itemsToBeLootedFrames[i].itemCountFontString:SetText("");
        end
      end
      
    end
    
    if itemsLootedFrames ~= nil then
      for i=1, #itemsLootedFrames do 
        itemsLootedFrames[i]:SetPoint("TopLeft", mainFrame, 20 + 60 * (#itemsToBeLootedFrames + i-1), -430);
        local count = itemsLooted[i]:getCount();
        if count > 1 then
           itemsLootedFrames[i].itemCountFontString:SetText(count);
        else
          itemsLootedFrames[i].itemCountFontString:SetText("");
        end
      end
      
    end
    -- free current responses
    for i=1, #currentResponseFrames do
        fusedCouncil:releaseResponseFrame(currentResponseFrames[i]);
    end
    currentResponseFrames = {};
    -- repaint all the responses
      for i=1, #currentItem:getResponseTable() do
          fusedCouncil:addResponseFrame(currentItem:getResponseTable()[i]);
      end
      
      for i=1, #currentResponseFrames do
          currentResponseFrames[i]:SetPoint("Top", 0, (-30*i) );
            for k=1, #currentResponseFrames[i].texture do
              currentResponseFrames[i].texture[k]:Hide();
            end 
          if personSelected == currentItem:getResponseTable()[i]:getPlayerName() then
            currentResponseFrames[i].texture[2]:Show();
          else
            currentResponseFrames[i].texture[1]:Show();
          end
          if #currentItem:givenTo() > 0 and FC_Utils.tableContains(currentItem:givenTo(), currentResponseFrames[i].subFrames[1].fontString:GetText())then
            currentResponseFrames[i].texture[3]:Show();
          end

          currentResponseFrames[i]:Show();
      end
  local count = currentItem:getCount();
  if count > 1 then
   currentItemFrame.itemCountFontString:SetText(count);
  else
    currentItemFrame.itemCountFontString:SetText("");
  end
  dbProfile.isTesting = isTesting;
  dbProfile.initializeFromDB = true;
  dbProfile.currentItem = currentItem;
  dbProfile.personSelected = personSelected;
  dbProfile.itemsToBeLooted = itemsToBeLooted;
  dbProfile.itemsLooted = itemsLooted;
end

function fusedCouncil:initializeFromDB()
  isTesting = dbProfile.isTesting;
  if dbProfile.currentItem ~= nil then
    local responseTable = {};
    for i=1, #dbProfile.currentItem.responseTable do
      table.insert(responseTable, Response:new(dbProfile.currentItem.responseTable[i]));
    end
    fusedCouncil:setCurrentItem(Item:new(dbProfile.currentItem.itemLink,dbProfile.currentItem.count,responseTable, dbProfile.currentItem.given));
  end 
  
  if dbProfile.personSelected ~= "" then
    personSelected = dbProfile.personSelected;
  end
  
  if #dbProfile.itemsToBeLooted ~= 0 then
      for i=1, #dbProfile.itemsToBeLooted do
        local responseTable = {};
        for k=1, #dbProfile.itemsToBeLooted[i].responseTable do
          table.insert(responseTable, Response:new(dbProfile.itemsToBeLooted[i].responseTable[k]));
        end
        fusedCouncil:addItem(Item:new(dbProfile.itemsToBeLooted[i].itemLink,dbProfile.itemsToBeLooted[i].count, responseTable, dbProfile.itemsToBeLooted[i].given));
      end
  end
  
  if #dbProfile.itemsLooted ~= 0 then
    for i=1, #dbProfile.itemsLooted do
      local responseTable = {};
      for k=1, #dbProfile.itemsLooted[i].responseTable do
        table.insert(responseTable, Response:new(dbProfile.itemsLooted[i].responseTable[k]));
      end
      local tempItem = Item:new(dbProfile.itemsLooted[i].itemLink,dbProfile.itemsLooted[i].count, responseTable, dbProfile.itemsLooted[i].given);
      table.insert(itemsLooted, tempItem);
      local tempFrame = fusedCouncil:getFreeItemFrame(tempItem);
      tempFrame.highlightFrame:Show();
      table.insert(itemsLootedFrames, tempFrame);
    end
  end
end -- end initializeFromDB
function fusedCouncil:setCurrentItem(item)
  if currentItem ~= nil then
      fusedCouncil:releaseItemFrame(currentItemFrame);
      for i=1, #currentResponseFrames do
        fusedCouncil:releaseResponseFrame(currentResponseFrames[i]);
        currentResponseFrames[i] = nil;
      end
      personSelected ="";
  end -- end currentItem reset
  
  currentItem = item;
  currentItemFrame = fusedCouncil:getFreeItemFrame(item);
  if #currentItem:givenTo() > 0 then
    currentItemFrame.highlightFrame:Show();
  end
  currentItemFrame:SetPoint("TopLeft", mainFrame, 50, -50);
  currentItemFontString:SetText(currentItem:getItemLink());


end
function fusedCouncil:addItem(item)
  local foundItem = fusedCouncil:findItem(itemsToBeLooted, item:getItemLink());
  if foundItem == nil then
      table.insert(itemsToBeLooted, item);
      table.insert(itemsToBeLootedFrames, fusedCouncil:getFreeItemFrame(item));
      
      if currentItem == nil then
         fusedCouncil:setCurrentItem(item);
      end
  
  else
    foundItem:setCount(foundItem:getCount() + item:getCount());
  end


end

function fusedCouncil:sort(table, sortFunction, optionsTable)
    -- if the table is alreaded sorted isSorted will stay true
    local isSorted = true;
    
    if optionsTable == nil then
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
    
    else
    
      for i=1, #table-1 do
        local j=i;
        while j > 0 and sortFunction(table[j], table[j+1], optionsTable) do
            isSorted = false;
            local temp = table[j];
            table[j] = table[j+1];
            table[j+1] = temp;
            j=j-1;
        end
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
function fusedCouncil:findItemIndex(table, itemLink)
  for i=1, #table do
    if table[i]:getItemLink() == itemLink then
      return i;
    end
  end
  return -1;
end

function fusedCouncil:findItem(table, itemLink)
  for i=1, #table do
    if table[i]:getItemLink() == itemLink then
      return table[i];
    end
  end
  return nil;
end
function fusedCouncil:findLootCanadaiteIndex(player)

end

function fusedCouncil:itemGivenHandler(item)
  local itemIndex = fusedCouncil:findItemIndex(itemsToBeLooted, item:getItemLink());
      -- handle the gui shit
      if itemsToBeLooted[itemIndex]:getCount() > 1 then
         itemsToBeLooted[itemIndex]:setCount(itemsToBeLooted[itemIndex]:getCount() - 1);
      else
          local itemGiven = table.remove(itemsToBeLooted, itemIndex);
          local itemGivenFrame = table.remove(itemsToBeLootedFrames, itemIndex);
          fusedCouncil:releaseItemFrame(itemGivenFrame);
      end
      
      
      local givenItemIndex = fusedCouncil:findItemIndex(itemsLooted, item:getItemLink());
      
      if givenItemIndex ~= -1 then
          itemsLooted[givenItemIndex]:setCount(itemsLooted[givenItemIndex]:getCount() + 1);
          itemsLooted[givenItemIndex]:give(personSelected);
      else
          local newItem = Item:new(item:getItemLink(), 1, item:getResponseTable(), {personSelected});
          table.insert(itemsLooted, newItem);
          local tempFrame = fusedCouncil:getFreeItemFrame(newItem);
          tempFrame.highlightFrame:Show();
          table.insert(itemsLootedFrames, tempFrame);
      end
    personSelected = "";
      
    fusedCouncil:update();
end
function fusedCouncil:giveItem(item)
  local itemIndex = fusedCouncil:findItemIndex(itemsToBeLooted, currentItem:getItemLink());
  if personSelected ~= "" and itemIndex ~= -1 then
      -- actually give item
      if isMasterLooter then
        if isCurrentlyLooting or isTesting then
          local canadaiteIndex = fusedCouncil:findLootCanadaiteIndex(personSelected);
          if canadaiteIndex ~= -1 or isTesting then
            if not isTesting then
               GiveMasterLoot(fusedCouncil:findItemIndex(currentLootWindowItems,item:getItemLink()), canadaiteIndex);
            end
            fusedCouncil:itemGivenHandler(currentItem);
            fusedCouncil:SendCommMessage(addonPrefix, "itemLooted ".. fusedCouncil:Serialize({itemLink = item:getItemLink()}), "RAID");
          else
            print("That Player is not elegiable for this loot");
          end
        else
            print("you need to be looting the body");
        end
       else 
        print("you are not the master looter");
      end
  
  end

end

function fusedCouncil:createItemTable(itemLinkTable)
  local itemObjectTable = {};
  for i=1, #itemLinkTable do
    local foundItem = fusedCouncil:findItem(itemObjectTable, itemLinkTable[i]);
    if foundItem == nil then
      table.insert(itemObjectTable, Item:new(itemLinkTable[i]));
    else
      foundItem:setCount(foundItem:getCount() +1);
    end
  end
  return itemObjectTable;
end
function fusedCouncil:test(itemTable)
  isTesting = true;
  local itemObjectTable = fusedCouncil:createItemTable(itemTable);
  for i=1, #itemObjectTable do
    fusedCouncil:addItem(itemObjectTable[i]);
  end
  local payload = {lootTable = itemObjectTable, optionsTable = dbProfile.options };
  local serializedPayload = fusedCouncil:Serialize(payload);
  fusedCouncil:SendCommMessage(addonPrefix, "lootTable ".. serializedPayload, "RAID");
  fusedCouncil:update();
end

function fusedCouncil:playerInCouncil(lootCouncilMembers)
for i=1, #lootCouncilMembers do
  if lootCouncilMembers[i] == UnitName("player") then
    return true;
  end
end
  return false;
end
-- Frame methods

local itemFramePool = {};
local responseFramePool = {};

function fusedCouncil:createMainFrame()
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
    mainFrame:Hide();
    minFrame:Show();
  end );
  
    -- create reponse table attributes
  --                      1     2       3           4           5         6         7               9
  local labelsNames = {"Name","ilvl","Score", "Current Item", "Rank", "Response", "Note", "Vote", "Votes"}

  for i=1 , #labelsNames do
    local tempButton = CreateFrame("Button", labelsNames[i].."LabelButton", tempFrame, "MagicButtonTemplate" );
    tempButton:SetText(labelsNames[i]);
    tempButton:SetPoint("TopLeft",tempFrame, 20+ (90*(i-1)), -100);
    tempButton:SetScript("OnMouseDown", function()  
       if currentItem ~= nil then
          if i == 1 then
          fusedCouncil:sort(currentItem:getResponseTable(), FC_Utils.nameCompare);
          elseif i==2 then
          fusedCouncil:sort(currentItem:getResponseTable(), FC_Utils.ilvlCompare);
          elseif i ==3 then
          fusedCouncil:sort(currentItem:getResponseTable(), FC_Utils.scoreCompare);
          elseif i==4 then
          fusedCouncil:sort(currentItem:getResponseTable(), FC_Utils.itemCompare);
          elseif i==5 then
          fusedCouncil:sort(currentItem:getResponseTable(), FC_Utils.rankCompare);
          elseif i==6 then
          
          fusedCouncil:sort(currentItem:getResponseTable(), FC_Utils.responseCompare, dbProfile.options);
          elseif i==7 then
          fusedCouncil:sort(currentItem:getResponseTable(), FC_Utils.noteCompare);
          elseif i==9 then
          fusedCouncil:sort(currentItem:getResponseTable(), FC_Utils.votesCompare);
          end
          fusedCouncil:update();
       end
    
    end);
  end
  
  local giveButton = CreateFrame("Button", nil, tempFrame, "MagicButtonTemplate" );
  giveButton:SetText("Give Loot");
  giveButton:SetPoint("TopLeft", 380, -390);
  
  giveButton:SetScript("OnMouseup", function()

    fusedCouncil:giveItem(currentItem);
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
end


function fusedCouncil:createMinFrame()

  -- Create a window for when we minimize the main window
  local minFrame = CreateFrame("Frame", "lcMinFrame",  UIParent, "PortraitFrameTemplate");
  -- create easier name to deal with
  minFrame:SetPoint("TopRight", mainFrame, "TopRight");
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
    minFrame:Hide();
    mainFrame:Show();
  end );

  -- Create portrait icon for minWindow
  minFrame:CreateTexture("minillidanTexture");
  SetPortraitToTexture("minillidanTexture", "Interface\\ICONS\\Achievement_Boss_Illidan.blp")
  minillidanTexture:SetPoint("TopLeft", -10, 10);
  
  return minFrame;
end

function fusedCouncil:createItemFrame()
  local tempFrame = CreateFrame("Frame", nil, mainFrame);
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

  tempFrame.itemCountFontString = tempFrame:CreateFontString(nil,"low", "GameFontNormalHuge");
  tempFrame.itemCountFontString:SetPoint("bottomright",0,0);
  return tempFrame;
end
function fusedCouncil:createResponseFrame()
  local tempFrame =  CreateFrame("Frame", nil,  mainFrame.childFrame);
   tempFrame:SetSize(800,25);
  tempFrame:Hide();
  tempFrame:EnableMouse(true);
  tempFrame.texture = {};
  for i=1, 4 do
      tempFrame.texture[i] = tempFrame:CreateTexture(nil, "BACKGROUND");
      tempFrame.texture[i]:SetAllPoints(tempFrame);
      tempFrame.texture[i]:Hide();
  end
  tempFrame.texture[1]:SetTexture(.9,.9,.1,.1);
  tempFrame.texture[2]:SetTexture(.9,.9,.1,.3);
  tempFrame.texture[3]:SetTexture(.9,.1,.1,.3);
  tempFrame.texture[4]:SetTexture(.1,.9,.1,.3);
  tempFrame:SetScript("OnMouseDown", function(self, button)
      if button == "LeftButton" then
        personSelected = tempFrame.subFrames[1].fontString:GetText();
        fusedCouncil:update();
      elseif button == "RightButton" then
        personSelected ="";
        fusedCouncil:update();
      end
  end );
  tempFrame:SetScript("OnEnter", function() 

  tempFrame.texture[4]:Show();
   end);
  tempFrame:SetScript("OnLeave", function()   
   tempFrame.texture[4]:Hide();
    end);
  
  tempFrame.subFrames = {};
  for i =1, 9 do
    tempFrame.subFrames[i] = CreateFrame("Frame", nil,  tempFrame);
    tempFrame.subFrames[i] :SetSize(88,25);
    tempFrame.subFrames[i] :SetPoint("TopLeft",(90*(i-1)),0);
    tempcolor= tempFrame.subFrames[i] :CreateTexture(nil, "BACKGROUND");
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


function fusedCouncil:getFreeItemFrame(item)
  if #itemFramePool == 0 then
    for i=1,5 do
      table.insert(itemFramePool, fusedCouncil:createItemFrame());
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
    fusedCouncil:setCurrentItem(item);
    fusedCouncil:update();
  end);
  
  return tempItemFrame;
end
function fusedCouncil:getFreeResponseFrame(response)
  if #responseFramePool == 0 then
    for i=1,5 do
      table.insert(responseFramePool, fusedCouncil:createResponseFrame());
    end

  end
  return table.remove(responseFramePool, 1);

end

function fusedCouncil:releaseResponseFrame(frame)
   frame:Hide();
  for i=1,3 do
    frame.subFrames[4].itemFrames[i]:Hide();
  end
  frame.subFrames[8].voteButton:SetText("Vote");
  for k=1, #frame.texture do
    frame.texture[k]:Hide();
  end 
  table.insert(responseFramePool, frame);
end
function fusedCouncil:releaseItemFrame(frame)
  frame:Hide();
  frame.highlightFrame:Hide();
  frame.itemCountFontString:SetText("");
  table.insert(itemFramePool, frame);
end

function fusedCouncil:addResponseFrame(responseObject)
 local response = fusedCouncil:getFreeResponseFrame();
  
  response.subFrames[1].fontString:SetText(responseObject:getPlayerName());
  response.subFrames[2].fontString:SetText(responseObject:getPlayerIlvl());
  response.subFrames[3].fontString:SetText(responseObject:getPlayerScore());
  fusedCouncil:setupSubFrameFour(response.subFrames[4], responseObject);
  response.subFrames[5].fontString:SetText(responseObject:getPlayerGuildRank());
  response.subFrames[6].fontString:SetText(responseObject:getPlayerResponse());
  fusedCouncil:setupSubFrameSeven(response.subFrames[7], responseObject);
  fusedCouncil:setupSubFrameEight(response.subFrames[8], responseObject);
  response.subFrames[9].fontString:SetText(#responseObject:getVotes());

  
  table.insert(currentResponseFrames, response);
end

function fusedCouncil:setupSubFrameFour(frame, responseObject)
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

function fusedCouncil:setupSubFrameSeven(frame, responseObject)

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

function fusedCouncil:setupSubFrameEight(frame,responseObject)
   local votes = responseObject:getVotes();
  for i=1, #votes do
      if votes[i] == UnitName("player") then
          frame.voteButton:SetText("UnVote");
      end
  end
  frame.voteButton:SetScript("OnClick", function(self) 

      if self:GetText() == "Vote" then 
         if not currentItem:hasVoteFrom(UnitName("player")) then
        fusedCouncil:SendCommMessage(addonPrefix, "vote ".. fusedCouncil:Serialize({itemLink = responseObject:getItemLink(), player = responseObject:getPlayerName()}), "RAID");
        end
      elseif self:GetText() == "UnVote" then
        fusedCouncil:SendCommMessage(addonPrefix, "unvote ".. fusedCouncil:Serialize({itemLink = responseObject:getItemLink(), player = responseObject:getPlayerName()}), "RAID");
      end

  end);
 
end


