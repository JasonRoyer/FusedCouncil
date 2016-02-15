Item = {}

function Item:new(itemLink, responseTable)
  local newObject = {};
  setmetatable(newObject,self);
  self.__index = self;
  newObject.itemLink = itemLink or "";
  newObject.responseTable = responseTable or {};
  _ , _ , newObject.itemRarity, _ , _ , _ , _ ,_ ,newObject.ItemEquipLoc, newObject.itemTexture = GetItemInfo(itemLink);

  return newObject;

end
function Item:hasVoteFrom(player)
  for i=1, #self.responseTable do
    local votes = self.responseTable[i]:getVotes();
    for k=1, #votes do
      if votes[k] == player then
        return true;
      end
    end
  end
  return false;
end
function Item:getItemLink()
  return self.itemLink;
end

function Item:setItemLink(itemLink)
  self.itemLink = itemLink;
  _ , _ , self.itemRarity, _ , _ , _ ,_ ,self.ItemEquipLoc, self.itemTexture = GetItemInfo(itemLink);
end

function Item:getResponseFromTable(player)
    for i=1, #self.responseTable do
      if self.responseTable[i]:getPlayerName() == player then
        return self.responseTable[i];
      end
    end
    return nil;
end

function Item:getResponseTable()
  return self.responseTable;
end

function Item:addResponse(value)
  table.insert(self.responseTable, value);
end

function Item:removeResponse(value)
  table.remove(self.responseTable, value);
end

function Item:getItemRarity()
  return self.itemRarity;
end

function Item:getItemEquipLoc()
  return self.ItemEquipLoc;
end

function Item:getItemTexture()
  return self.itemTexture;
end

