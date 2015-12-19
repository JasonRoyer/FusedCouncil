responseFramePool = {};

local function createResponseFrame(parent,lootLink)
  
  local tempFrame = CreateFrame("Frame", nil,  parent, "TooltipBorderedFrameTemplate");
  -- populate response window
  tempFrame:SetSize(900,100);
  tempIconFrame = CreateFrame("Frame", nil,  tempFrame);
  tempIconFrame:SetSize(75,75);
  tempIconFrame:SetPoint("TopLeft",tempFrame , 15, -12 )
  
  tempIconFrame.Texture = tempIconFrame:CreateTexture();
  tempIconFrame.Texture:SetAllPoints(tempIconFrame);
    
  tempFrame.IconFrame = tempIconFrame;  
  
    local buttonTitles = {"Bis", "Major","Minor", "Reroll", "OffSpec", "Transmog", "Pass"};
    tempFrame.Buttons = {};
    
    for i= 1, #buttonTitles do
      local tempButton = CreateFrame("Button", nil, tempFrame, "MagicButtonTemplate" );
      tempButton:SetText(buttonTitles[i]);
      tempButton:SetPoint("TopLeft",tempFrame, 110+ (110*(i-1)), -40);
      
      tempFrame.Buttons[i] = tempButton;
    end
    
    
    
    local noteBox = CreateFrame("EditBox", nil , tempFrame, "InputBoxTemplate");
    noteBox:SetSize(124*(#buttonTitles-1), 20);
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


function GetResponseFrame(parent)
    if #responseFramePool == 0 then
      for i=1,5 do
        table.insert(responseFramePool,createResponseFrame(parent));
      end
      
    end
    return table.remove(responseFramePool, 1);

end

function ReleaseResponseFrame(frame)
  frame:Hide();
  table.insert(responseFramePool, frame);
end
