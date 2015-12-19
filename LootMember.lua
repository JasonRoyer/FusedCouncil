LootMember = {
  frame = {},
  pool = {},
  currentResponses = {}
}

function LootMember:New(o)
  o = o or {};
  setmetatable(o, self);
  self.__index = self;
  self:CreateWindow(o)
  return o
end



function LootMember:CreateWindow(o)
  local frame = CreateFrame("Frame", "memberFrame", UIParent, "TooltipBorderedFrameTemplate");
  frame:SetFrameStrata("HIGH");
  frame:Hide();
  frame:SetPoint("CENTER", UIParent, "CENTER");
  frame:SetSize(900,400);
  frame:SetMovable(true);
  frame:EnableMouse(true);
  frame:RegisterForDrag("LeftButton");
  frame:SetScript("OnDragStart", function () self.frame:StartMoving() end);
  frame:SetScript("OnDragStop", function () self.frame:StopMovingOrSizing() end );

  frame.parentObject = o;

  local function eventHandeler(self, event, prefix,...)
    if event == "CHAT_MSG_ADDON" and prefix == "FLC_PREFIX" then

      local message,_,sender = ...;
      local splitMessage = frame.parentObject:splitMSG(message);

      if #splitMessage > 0 then
        if splitMessage[1] == "A" then
          -- changed this, need to fix it under maina addon
          frame.parentObject:AddResponse(splitMessage[2]);
        end
      end

    end

  end-- end of eventHandeler

  frame:SetScript("OnEvent", eventHandeler);
  frame:RegisterEvent("CHAT_MSG_ADDON");
  RegisterAddonMessagePrefix("FLC_PREFIX");


  self.frame = frame;
end -- end eventHandeler

function LootMember:AddResponse(lootLink)

  local _, myIlvl = GetAverageItemLevel();
  local itemEquipSlot, itemTexture = select(9, GetItemInfo(lootLink));

  local tempResponse = {
    name = GetUnitName("player",false),
    ilvl = math.floor(myIlvl+0.5),
    score = 0,
    rank= select(2, GetGuildInfo("player")),
    response="",
    note=""}

  if _G[itemEquipSlot] ~= nil then
  -- needs to deal with weps. "slot doesnt work"
  print(itemEquipSlot)
  print(_G[itemEquipSlot].."slot")
    tempResponse.currentItem=GetInventoryItemLink("player",GetInventorySlotInfo(_G[itemEquipSlot].."slot"))
  else
    tempResponse.currentItem = "None"
  end

  local tempResponseFrame = GetResponseFrame(self:GetFrame(),itemTexture,lootLink);
  tempResponseFrame.ResponseNum = #self.currentResponses+ 1;
  local object = self;
  -- add button scripts here
  for i=1, #tempResponseFrame.Buttons do

    tempResponseFrame.Buttons[i]:SetScript("OnClick", function(self)
      tempResponse.response = self:GetText();
      tempResponse.note = tempResponseFrame.NoteBox:GetText();
      object:removeResponse(tempResponseFrame.ResponseNum);
      SendAddonMessage( "FLC_PREFIX", "B".. "^".. lootLink ..  "^"..tempResponse.name .. "^".. tempResponse.ilvl .. "^".. tempResponse.score ..
        "^".. tempResponse.currentItem .. "^"..tempResponse.rank .. "^".. tempResponse.response  .. "^"..tempResponse.note, "RAID" );
    end);
  end
  -- set texture
  tempResponseFrame.IconFrame.Texture:SetTexture(itemTexture);

  --  tempFrame.IconFrame:SetScript("OnEnter" and leave
  tempResponseFrame.IconFrame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(tempResponse.Frame.IconFrame, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(lootLink);
    GameTooltip:Show()
  end);

  tempResponseFrame.IconFrame:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end);
  tempResponseFrame.LootItemName:SetText(GetItemInfo(lootLink))

  tempResponse.Frame =  tempResponseFrame;
  table.insert(self.currentResponses, tempResponse);
  self:Update();
end -- end addResponse

function LootMember:Update()
  for i = 1, #self.currentResponses do
    self.currentResponses[i].Frame:SetPoint("TopLeft", self.frame, 0, -100*(i-1));
  end

  if #self.currentResponses == 0 then
    self.frame:Hide();
  else
    self.frame:Show();
  end
end


function LootMember:removeResponse(index)
    ReleaseResponseFrame(table.remove(self.currentResponses, index).Frame);
    self:Update();
end

function LootMember:GetFrame()
  return self.frame;
end

function LootMember:splitMSG(str)
local tempArray = {};
for w in (str.."^"):gmatch("[^^]+") do 
    table.insert(tempArray, w) 
end
return tempArray
end

myMember = LootMember:New(nil);