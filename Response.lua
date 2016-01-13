Response = {};

function Response:new(itemLink, playerName,playerIlvl, playerScore, playerGuildRank,playerResponse,note,playerItem,votes)
  local newObject = {};
  setmetatable(newObject, self);
  self.__index = self;
  newObject.itemLink =  itemLink.itemLink or  itemLink or "";
  newObject.playerName =  itemLink.playerName or playerName or "";
  newObject.playerIlvl = itemLink.playerIlvl or playerIlvl or 0;
  newObject.playerScore = itemLink.playerScore or playerScore or 0;
  newObject.playerGuildRank = itemLink.playerGuildRank or  playerGuildRank or "No Guild";
  newObject.playerResponse = itemLink.playerResponse or playerResponse or "";
  newObject.note = itemLink.note or note or "";
  newObject.playerItem = itemLink.playerItem or playerItem or {};
  newObject.votes = itemLink.votes or votes or {};
  return newObject;

end
 
function Response:toString()
  return self.itemLink..self.playerName
end

function Response:setItemLink(itemLink)
  self.itemLink = itemLink;
end

function Response:getItemLink()
  return self.itemLink;
end

function Response:setPlayerName(playerName)
  self.playerName = playerName;
end

function Response:getPlayerName()
  return self.playerName;
end

function Response:setPlayerIlvl(ilvl)
  self.playerIlvl = ilvl;
end

function Response:getPlayerIlvl()
  return self.playerIlvl;
end

function Response:setPlayerScore(playerScore)
  self.playerScore = playerScore;
end

function Response:getPlayerScore()
  return self.playerScore;
end

function Response:setPlayerGuildRank(playerGuildRank)
  self.playerGuildRank = playerGuildRank;
end

function Response:getPlayerGuildRank()
  return self.playerGuildRank;
end
function Response:getPlayerResponse()
  return self.playerResponse;
end
function Response:setPlayerResponse(playerResponse)
  self.playerResponse = playerResponse;
end
function Response:setNote(note)
  self.note = note;
end
function Response:getNote()
   return self.note
end
function Response:addPlayerItem(playerItem)
    table.insert(self.playerItem, playerItem);
end
function Response:removePlayerItem(playerItem)
    table.remove(self.playerItem, playerItem);
end
function Response:getPlayerItem()
    return self.playerItem;
end
function Response:getVotes()
    return self.votes;
end
function Response:addVote(vote)
   table.insert(self.votes, vote);
end
function Response:removeVote(vote)
   local indexValue = -1;
   for i=1, #self.votes do
      if self.votes[i] == vote then
         indexValue = i;
       end
   end
   if (indexValue ~= -1) then
     table.remove(self.votes,indexValue);
   end
end

