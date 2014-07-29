local npcid = 390000
LottoSettings = {};
LottoEntries = {};
LottoEntriez = {};
LottoEntriez["SERVER"] = {};
local function LottoLoader(event)
local LS = WorldDBQuery("SELECT * FROM lotto.settings;");
	if(LS)then
		repeat
			LottoSettings["SERVER"] = {
				item = LS:GetUInt32(1),
				timer = LS:GetUInt32(2),
				operation = LS:GetUInt32(3),
				mumax = LS:GetUInt32(4)
										};
		until not LS:NextRow()
	end	
	
local LE = WorldDBQuery("SELECT * FROM lotto.entries;");
LottoEntriez["SERVER"].pot = 0;
	if(LE)then
		repeat
			LottoEntries[LE:GetUInt32(0)] = {
								id = LE:GetUInt32(0),
								name = LE:GetString(1),
								count = LE:GetUInt32(2)
											};
			if(LE:GetUInt32(2) > 0)then
				LottoEntriez[(#LottoEntriez+1)] = {
									id = LE:GetUInt32(0),
									name = LE:GetString(1),
									count = LE:GetUInt32(2)
												};
				LottoEntriez["SERVER"].pot = ((LottoEntriez["SERVER"].pot)+(LE:GetUInt32(2)))
			end
		until not LE:NextRow()
	end
	
end

LottoLoader(1)

local function GetId(name)
	for id=1, #LottoEntries do
		if(LottoEntries[id].name==name)then
			return id;
		end
	end
end

local function NewLottoEntry(name, chain)
local NLEID = (#LottoEntries+1)

WorldDBExecute("REPLACE INTO lotto.entries SET `name`='"..name.."';")

LottoEntries[NLEID] = {
			id = NLEID,
			name = name
					};
LottoEntriez[NLEID] = {
			id = NLEID,
			name = name,
			count = 0
					};
end

local function EnterLotto(name, id)

local elcount = LottoEntriez[id].count + 1
	
	WorldDBQuery("UPDATE lotto.entries SET `count` = '"..elcount.."' WHERE `name` = '"..name.."';")
	LottoEntries[id].count = elcount
	LottoEntriez[id].count = elcount
	GetPlayerByName(name):SendBroadcastMessage("You have entered "..elcount.." times.")
	LottoEntriez["SERVER"].pot = ((LottoEntriez["SERVER"].pot)+(elcount))
	
end

local function FlushLotto(id)
	WorldDBQuery("UPDATE lotto.entries SET `count` = '0' WHERE `id` = '"..id.."';")
	LottoEntriez[id].count = 0
end

local function Tally(event)
print("tally")
	if(#LottoEntriez < 4)then
		SendWorldMessage("Not enough Loco Lotto Entries this round.")
	else
		local multiplier = math.random(1, LottoSettings["SERVER"].mumax)
		local win = math.random(1, #LottoEntriez)
		local name = LottoEntriez[win].name
		local player = GetPlayerByName(name)

			if(player)then
				local bet = ((LottoEntriez[win].count)*multiplier)
				SendWorldMessage("Contgratulations to "..LottoEntriez[win].name.." our new winner. Total:"..(LottoEntriez["SERVER"].pot+bet)..". Its LOCO!!")
				player:AddItem(LottoSettings["SERVER"].item, (LottoEntries["SERVER"].pot+bet))
			
				for a=1, #LottoEntries do
					FlushLotto(a)
					LottoEntriez["SERVER"].pot = 0	
				end
			else
				SendWorldMessage("No Winners this Loco lotto round.")
			end
	end
	if(LottoSettings["SERVER"].operation==1)then
		CreateLuaEvent(Tally, LottoSettings["SERVER"].timer, 1)
	end
end

local function LottoOnHello(event, player, unit)
local lohid = GetId(player:GetName())
	if(lohid==nil)then
		NewLottoEntry(player:GetName(), 0)
		LottoOnHello(event, player, unit)
	else
	VendorRemoveAllItems(npcid)
	player:GossipClearMenu()
	player:GossipMenuAddItem(0, "You have entered "..LottoEntries[lohid].count.." times", 0, 10)
	player:GossipMenuAddItem(0, "Enter the lotto.", 0, 100)
	player:GossipMenuAddItem(0, "never mind.", 0, 11)
	player:GossipSendMenu(1, unit)
	end
end

local function LottoOnSelect(event, player, unit, sender, intid, code)
	if(intid<=10)then
		LottoOnHello(1, player, unit)
	end
	if(intid==11)then
		player:GossipComplete()
	end

	if(intid==100)then
		local id = GetId(player:GetName())
		
			if(player:GetItemCount(LottoSettings["SERVER"].item)==0)then
				player:SendBroadcastMessage("You Loco .. you dont have enough currency to enter.")
			else
				EnterLotto(player:GetName(), id)
			end
			LottoOnHello(1, player, unit)
	end
end

RegisterCreatureGossipEvent(npcid, 1, LottoOnHello)
RegisterCreatureGossipEvent(npcid, 2, LottoOnSelect)

print("Grumbo'z Loco Lottery Online.")

	if(LottoSettings["SERVER"].operation==1)then
		CreateLuaEvent(Tally, LottoSettings["SERVER"].timer, 1)
	else
		print("...System idle...")
	end

