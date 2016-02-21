FC_Utils ={
nameCompare = function(response1, response2) 
 return response1:getPlayerName() > response2:getPlayerName();

end;

ilvlCompare = function(response1, response2)
  return response1:getPlayerIlvl() > response2:getPlayerIlvl();
end;

scoreCompare = function(response1, response2)
  return response1:getPlayerScore() > response2:getPlayerScore();
end;

itemCompare = function(response1, response2)
    local itemlvl1 = select(4,GetItemInfo(response1:getItemLink()));
    local itemlvl2 = select(4, GetItemInfo(response2:getItemLink()));
    if itemlvl1 ~= nil and itemlvl2 ~= nil then
      return itemlvl1 > itemlvl2;
    end
    return false;
    
end;

rankCompare = function(response1, response2)
      local playerRank1 = select(3, GetGuildInfo(response1:getPlayerName()));
      local playerRank2 = select(3, GetGuildInfo(response2:getPlayerName()));
      -- GM is rank 0 lowest rank should be highest num
      print(playerRank1.. " " ..playerRank2)
      return playerRank1 < playerRank2;

end;

responseCompare = function(response1, response2, optionsTable)
-- prob need to do options here?
   local index1 = optionsTable.numOfResponseButtons;
   local index2 = optionsTable.numOfResponseButtons;
   for i=1, optionsTable.numOfResponseButtons do
      if response1 == optionsTable.responseButtonNames[i] then
          index1 = i;
      end
      if response2 == optionsTable.responseButtonNames[i] then
        index2 = i;
      end
   end
    return index1 < index2;
end;

noteCompare = function(response1, response2)
  return response1:getNote() ~= "" and response2:getNote() == "";
end;

votesCompare = function(response1,response2)
   return #response1:getVotes() > #response2:getVotes();
end;

tableContains = function(table,element)
   local flag  = false;
   for i=1, #table do
    if table[i] == element then
      flag = true;
    end
   end
   return flag;
end;

};