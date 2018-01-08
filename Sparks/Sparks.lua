_addon.name = 'Sparks'

_addon.author = 'Brax(orig) - Sammeh Modified - v 2.0.0.2'

_addon.version = '2.0.0.2'

-- 2.0.0.2  Added version for my plugin.  Added in //sparks reset  and cleaned up some output 

require('common');
require('timer');
db = require('map');

npc_name = "";
pkt = {};
all_temp_items = {};
current_temp_items = {};

valid_zones = T{"Western Adoulin","Southern San d'Oria","Windurst Woods","Bastok Markets","Escha - Ru'Aun","Escha - Zi'Tah","Reisinjima"}

valid_zones = {

	[256] = {npc="Eternal Flame", menu=5081}, -- Western Adoulin

	[230] = {npc="Rolandienne", menu=995}, -- Southern San d'Oria

	[235] = {npc="Isakoth", menu=26}, -- Bastok Markets

	[241] = {npc="Fhelm Jobeizat", menu=850}, -- Windurst Woods
	
	[288] = {npc="Affi", menu=9701},  -- Escha Zitah
	
	[289] = {npc="Dremi", menu=9701},  -- Escha RuAun
	
	[291] = {npc="Shiftrix", menu=9701},  -- Reisinjima
	
	}

defaults = {};
settings = defaults;
busy = false;
receivedItem = true;
currentSparks = 0;

local buyQueue = {};
local totalBuy = 0;
local __lclock, __sendclock = 0,0;
local __cycle = 1;

function purchase_item(item)
	print("\30\110[Sparks]Buying item: " .. item .. " #" .. totalBuy);
	if not busy then
		pkt = validate(item);
		if pkt then
			busy = true;
			poke_npc(pkt['Target'], pkt['Target Index']);
			totalBuy = totalBuy - 1;
		else
			print("\30\68[Sparks]Can't find item in menu");
		end;
	else
		print("\30\68[Sparks]Still buying last item");
	end;
end;

ashita.register_event('command', function(cmd, nType)
	-- Get the command arguments..
    local args = cmd:args();
	local cmd = args[2];
	
	if (#args >=2 and args[1] == '/sparks') then
		table.remove(args, 1);
		table.remove(args, 1);
		
		for i,v in pairs(args) do
			args[i] = ParseAutoTranslate(args[i], false);
		end;
		
		local item = table.concat(args, " "):lower();
		ki = 0;
		
		if cmd == 'buy' then
			if not busy then
				pkt = validate(item);
				if pkt then
					busy = true;
					poke_npc(pkt['Target'], pkt['Target Index']);
				else
					print("\30\68[Sparks]Can't find item in menu");
				end;
			else
				print("\30\68[Sparks]Still buying last item");
			end;
		elseif cmd == 'buyall' then
			local currentzone = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
			
			if currentzone == 241 or currentzone == 230 or currentzone == 235 or currentzone == 256 then
				count_inv();
				local sparksAddy = ashita.memory.find('FFXiMain.dll', 0, '', 0x46CAD8, 0);
				local currSparks = ashita.memory.read_uint32(sparksAddy);
				
				-- Change freeslots to match the number based on sparks possible to purchase
				local itemCost = fetch_db(item).Cost;
				local totalPurchase = math.floor(currSparks / itemCost);
				
				if totalPurchase < freeslots then
					freeslots = totalPurchase;
				end;
				
				totalBuy = freeslots;
				
				print("\30\110[Sparks]You can purchase " .. freeslots .. " total items, buying " .. item .. " until full");
				
				local currentloop = 0;
				while currentloop < freeslots do
					currentloop = currentloop + 1;
					-- Add to queue
					table.insert(buyQueue, item);
				end;
			else
				print("\30\68[Sparks]You are not currently in a zone with a sparks NPC");
			end;			
		elseif cmd == 'buyki' then
			if not busy then
				ki = 1;
				print("\30\110[Sparks]Buying KI: " .. item);
				pkt = validate(item);
				if pkt then
					busy = true;
					poke_npc(pkt['Target'], pkt['Target Index']);
				else
					print("\30\68[Sparks]Can't find item in menu");
				end;
			else
				print("\30\68[Sparks]Still buying last item");
			end;
		elseif cmd == 'find' then
			table.vprint(fetch_db(item));
		elseif cmd == 'buyalltemps' then
			local currentzone = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
			
			if currentzone == 291 or currentzone == 289 or currentzone == 288 then
				find_current_temp_items();
				find_missing_temp_items();
				number_of_missing_items = 0;
				
				for countmissing, countitems in pairs(missing_temp_items) do
					number_of_missing_items = number_of_missing_items + 1;
				end;
				
				print("\30\110[Sparks]Number of missing items: " .. number_of_missing_items);
				if number_of_missing_items ~= 0 then
					for keya,itema in pairs(missing_temp_items) do
						for keyb,itemb in pairs(db) do
							if itemb.TempItem == 1 then
								if keyb == itema then
									local item = itemb.Name:lower();
									print("\30\110[Sparks]Buying temp item: " .. item);
									if not busy then
										pkt = validate(item);
										if pkt then
											busy = true;
											poke_npc(pkt['Target'], pkt['Target Index']);
										else
											print("\30\68[Sparks]Can't find item in menu");
										end;
									else
										print("\30\68[Sparks]Still buying last item");
									end;
									
									sleepcounter = 0;
									while busy and sleepcounter < 5 do
										coroutine.sleep(1);
										sleepcounter = sleepcounter + 1;
										if sleepcounter == "4" then
											print("\30\68[Sparks]Probably lost a packet, waited too long!");
										end;
									end;
								end;
							end;
						end;
					end;
				end;
			else				
				print("\30\68[Sparks]You are not currently in a Geas Fete area");
			end;
		elseif cmd == 'listtemp' then
			local currentzone = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
			if currentzone == 291 or currentzone == 289 or currentzone == 288 then
				find_current_temp_items();
				find_missing_temp_items();
				number_of_missing_items = 0;
				for countmissing,countitems in pairs(missing_temp_items) do
					number_of_missing_items = number_of_missing_items  + 1;
				end;
				
				print("\30\110[Sparks]Number of missing items: " .. number_of_missing_items);
			else
				print("\30\68[Sparks]You are not currently in a Geas Fete area");
			end;
		elseif cmd == 'listki' then
			find_missing_ki();
			
			-- if found_mollifier == 0 then 
				-- windower.add_to_chat(8,"Mollifier: Missing")
			-- else
				-- windower.add_to_chat(8,"Mollifier: Check")
			-- end
			-- if found_radialens == 0 then 
				-- windower.add_to_chat(8,"Radialens: Missing")
			-- else
				-- windower.add_to_chat(8,"Radialens: Check")
			-- end
			-- if found_tribulens == 0 then 
				-- windower.add_to_chat(8,"Tribulens: Missing")
			-- else
				-- windower.add_to_chat(8,"Tribulens: Check")
			-- end
		elseif cmd == 'buyallki' then
			-- local currentzone = windower.ffxi.get_info()['zone']
			-- if currentzone == 291 or currentzone == 289 or currentzone == 288 then 
				-- find_missing_ki()
				-- number_of_missing_items = 0
				-- for countmissing,countitems in pairs(missing_ki) do
					-- number_of_missing_items = number_of_missing_items +1
				-- end
				-- windower.add_to_chat(8,'Number of Missing Items: '..number_of_missing_items)
				-- if number_of_missing_items ~= 0 then 
					-- for keya,itema in pairs(missing_ki) do
						-- for keyb,itemb in pairs(db) do
							-- if itemb.TempItem == 2 then
								-- if itemb.Name:lower() == itema:lower() then
									-- local item = itemb.Name:lower()
									-- windower.add_to_chat(8,'Buying Temp Item:'..item)
									-- if not busy then
										-- pkt = validate(item)
										-- if pkt then
											-- busy = true
											-- poke_npc(pkt['Target'],pkt['Target Index'])
										-- else 
											-- windower.add_to_chat(2,"Can't find item in menu")
										-- end
									-- else
										-- windower.add_to_chat(2,"Still buying last item")
									-- end
									-- sleepcounter = 0
									-- while busy and sleepcounter < 5 do
										-- coroutine.sleep(1)
										-- sleepcounter = sleepcounter + 1
										-- if sleepcounter == "4" then
											-- windower.add_to_chat(2,"Probably lost a packet, waited too long!")
										-- end
									-- end
								-- end
							-- end
						-- end
					-- end
				-- end
			-- else 
			  -- windower.add_to_chat(8,'You are not in a Gaes Fete Area')
			-- end
		elseif cmd == 'reset' then
			reset_me();
		end;
		
		return true;
	end;
	
	return false;
end);

function validate(item)
	local zone = AshitaCore:GetDataManager():GetParty():GetMemberZone(0);
	local me,target_index,target_id,distance;
	local result = {};

	if valid_zones[zone] then
		for x = 0, 2303 do
			local e = GetEntity(x);
			if (e ~= nil and e.WarpPointer ~= 0) then
				if (e.Name == GetPlayerEntity().Name) then
					result['me'] = i;
				elseif e.Name == valid_zones[zone].npc then
					target_index = e.TargetIndex;
					target_id = e.ServerId;
					npc_name = e.Name;
					result['Menu ID'] = valid_zones[zone].menu;					
					distance = e.Distance;
				end;
			end
		end
	
		if math.sqrt(distance) < 6 then
            local ite = fetch_db(item);
			if ite then
				result['Target'] = target_id;
				result['Option Index'] = ite['Option'];
				result['_unknown1'] = ite['Index'];
				result['Target Index'] = target_index;
				result['Zone'] = zone;
			end;
		else
			print("\30\68[Sparks]Too far from npc");
		end
	else
		print("\30\68[Sparks]Not in a zone with a sparks npc");
	end;

	if result['Zone'] == nil then result = nil end;
	return result;
end




function fetch_db(item)
 for i,v in pairs(db) do
  if string.lower(v.Name) == string.lower(item) then
	return v;
  end;
 end;
end;

function find_all_tempitems()
	for i,v in pairs(db) do
		if v.TempItem == 1 then
			all_temp_items[#all_temp_items+1] = i
		end
	end
end


function find_current_temp_items()
 count = 0
 current_temp_items = {}
 tempitems = windower.ffxi.get_items().temporary
 for key,item in pairs(tempitems) do
-- print(key,item)
 if key ~= 'max' and key ~= 'count'  and key ~= 'enabled' then
 	for ida,itema in pairs(item) do
		if itema ~= 0 and ida == 'id' then 
			count = count + 1
			current_temp_items[#current_temp_items+1] = itema
		end
	end
 end
 end
 
end

function find_missing_temp_items()
 missing_temp_items = {}
 for key,item in pairs(all_temp_items) do
	itemmatch = 0
	for keya,itema in pairs(current_temp_items) do
		if item == itema then
			itemmatch = 1
		end
	end
	if itemmatch == 0 then
		missing_temp_items[#missing_temp_items+1] = item
		-- print(db[item].Name)
	end
 end
 --print(table.concat(missing_temp_items, ', '))
end

function find_missing_ki()
	missing_ki = {}
 	found_mollifier = 0
	found_radialens = 0
	found_tribulens = 0
	local keyitems = windower.ffxi.get_key_items()
	for id,ki in pairs(keyitems) do
		if ki == 3032 then
			found_mollifier = 1
		elseif ki == 3031 then
			found_radialens = 1
		elseif ki == 2894 then
			found_tribulens = 1
		end
	end
	if found_mollifier == 0 then
		missing_ki[#missing_ki+1] = "mollifier"
	end
	if found_tribulens == 0 then
		missing_ki[#missing_ki+1] = "tribulens"
	end
	if found_radialens == 0 then
		missing_ki[#missing_ki+1] = "radialens"
	end
	--print(table.concat(missing_ki, ', '))
end


ashita.register_event('incoming_packet', function(id, size, packet, packet_modified, blocked)
	if id == 0x020 then
		local itemID = struct.unpack('H', packet, 0x0C + 1);
		if (itemID > 0) then
			local foundItem = AshitaCore:GetResourceManager():GetItemById(itemID);
			if (foundItem) then
				local itemName = foundItem.Name[0];
				receivedItem = true;
			end;
		end;
	end;

	if id == 0x032 or id == 0x034 then
	 if busy == true and pkt then
		if npc_name ~= 'Dremi' and npc_name ~= 'Affi' and npc_name ~= 'Shiftrix' then
			-- build packet
			local packet = struct.pack('bbbbihhhbbhh', 0x05B, 0x05, 0x00, 0x00, pkt['Target'], pkt['Option Index'], pkt['_unknown1'], pkt['Target Index'], 1, 0, pkt['Zone'], pkt['Menu ID']):totable();
			AddOutgoingPacket(0x05B, packet);

			packet = struct.pack('bbbbihhhbbhh', 0x05B, 0x05, 0x00, 0x00, pkt['Target'], 0, 16384, pkt['Target Index'], 0, 0, pkt['Zone'], pkt['Menu ID']):totable();
			AddOutgoingPacket(0x05B, packet);
			
		else  -- reisinjima does it different....
			-- build packet
			local packet = struct.pack('bbbbihhhbbhh', 0x05B, 0x05, 0x00, 0x00, pkt['Target'], pkt['Option Index'], pkt['_unknown1'], pkt['Target Index'], 1, 0, pkt['Zone'], pkt['Menu ID']):totable();
			AddOutgoingPacket(0x05B, packet);
			
			if ki == 0 then
				packet = struct.pack('bbbbihhhbbhh', 0x05B, 0x05, 0x00, 0x00, pkt['Target'], 14, pkt['_unknown1'], pkt['Target Index'], 1, 0, pkt['Zone'], pkt['Menu ID']):totable();
				AddOutgoingPacket(0x05B, packet);
			elseif ki == 1 then 
				packet = struct.pack('bbbbihhhbbhh', 0x05B, 0x05, 0x00, 0x00, pkt['Target'], 3, pkt['_unknown1'], pkt['Target Index'], 1, 0, pkt['Zone'], pkt['Menu ID']):totable();
				AddOutgoingPacket(0x05B, packet);
			end;
			
			-- send exit menu
			packet = struct.pack('bbbbihhhbbhh', 0x05B, 0x05, 0x00, 0x00, pkt['Target'], 0, pkt['_unknown1'], pkt['Target Index'], 0, 0, pkt['Zone'], pkt['Menu ID']):totable();
			AddOutgoingPacket(0x05B, packet);
		end;

		local packet = struct.pack('bbbbhh', 0x016, 0x02, 0x00, 0x00, GetPlayerEntity().TargetIndex, 0):totable();
		AddOutgoingPacket(0x016, packet);
		busy = false;
		lastpkt = pkt;
		pkt = {};
		return true;
	 end;
	end;
	
	return false;
end);

function reset_me()
	if lastpkt then
		local packet = struct.pack('bbbbihhhbbhh', 0x05B, 0x05, 0x00, 0x00, lastpkt['Target'], lastpkt['Option Index'], "16384", lastpkt['Target Index'], 0, 0, lastpkt['Zone'], lastpkt['Menu ID']):totable();
		AddOutgoingPacket(0x05B, packet);
	end;
end;

function count_inv()
	local playerinv = AshitaCore:GetDataManager():GetInventory();
	local uinv = 0;
	for i = 1, playerinv:GetContainerMax(0) do
		local item = playerinv:GetItem(0, i-1);
		if (item ~= nil and item.Id ~= 0) then
			uinv = uinv + 1;
		end
	end
	freeslots = playerinv:GetContainerMax(0) - uinv;
	--print(freeslots);
end


function poke_npc(npc,target_index)

	if npc and target_index then
		local pokeNpcPacket = struct.pack('bbbbihhhhfff', 0x01A, 0x07, 0, 0, npc, target_index, 0, 0, 0, 0, 0, 0):totable();			
		AddOutgoingPacket(0x01A, pokeNpcPacket);
	end;

end

ashita.register_event('load', function()
	find_all_tempitems()
end)

ashita.register_event('render', function()
    if(#buyQueue > 0) then
		__sendclock = os.clock() - __lclock;
		if(__cycle == 1 and __sendclock >= 1.0) then
			if receivedItem then
				receivedItem = false;
				purchase_item(buyQueue[1]);
				table.remove(buyQueue, 1);
			end;
			
			__lclock = os.clock();
		end
	else
		__lclock = os.clock();
    end
end );