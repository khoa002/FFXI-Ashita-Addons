_addon.name = "FastCS"
_addon.author = "Cairthenn"
_addon.version = "1.2"

--Requires:

require('common')

-- Settings:

defaults = {}
defaults.frame_rate_divisor = 2
defaults.exclusions = {"home point #1", "home point #2", "home point #3", "home point #4", "home point #5", "survival guide", "waypoint", "treasure casket"}
settings = defaults;

-- Globals:
__Globals = {
    enabled = false, -- Boolean that indicates whether the Config speed-up is currently enabled
    zoning  = false, -- Boolean that indicates whether the player is zoning with the config speed-up enabled
}

-- Help text definition:

helptext = "\30\110[FastCS] \30\31- Command List:\n" ..
"\30\69 1. \30\31help - Displays this help menu.\n" ..
"\30\69 2a. \30\31fps [30|60|uncapped]\n" ..
"\30\69 2b. \30\31frameratedivisor [2|1|0]\n" ..
"     - Changes the default FPS after exiting a cutscene.\n" ..
"     - The prefix can be used interchangeably. For example, \"fastcs fps 2\" will set the default to 30 FPS.\n" ..
"\30\69 3. \30\31exclusion [add|remove] <name>\n" ..
"     - Adds or removes a target from the exclusions list. Case insensitive.";
 
function disable()

    __Globals.enabled = false;
    
	AshitaCore:GetChatManager():QueueCommand("/fps " .. (settings.frame_rate_divisor < 1 and .1 or settings.frame_rate_divisor or 2), -1);
    
end

function enable()
    
    __Globals.enabled = true;
    
	AshitaCore:GetChatManager():QueueCommand("/fps .1", -1);	

end

ashita.register_event('unload', disable);
ashita.register_event('outgoing_packet', function(id, size, packet, packet_modified, blocked)

    if id == 0x00D and __Globals.enabled then -- Last packet sent when zoning out
        disable();
        __Globals.zoning = true;
    end;
  
	return false;
end);

ashita.register_event('incoming_packet', function(id, size, packet, packet_modified, blocked)

    if id == 0x00A and packet_modified == nil and __Globals.zoning then
        enable();
        __Globals.zoning = false;
    end
	
	-- Character Update Packet; Check for status change --
	if id == 0x037 then
		local status = struct.unpack('B', packet, 0x030 + 1);
		if (status == 4 and __Globals.enabled == false) then
			local targetName = AshitaCore:GetDataManager():GetTarget():GetTargetName();
			if (targetName ~= nil) then
				if (not table.hasvalue(settings.exclusions, targetName:lower())) then
					enable();
				end;
			end;
		elseif (__Globals.enabled == true) then
			disable();
		end;
	end;
    
	return false;
end)

ashita.register_event('load', function()
    local player = GetPlayerEntity();
    
    if player and player.Status == 4 then
        AshitaCore:GetChatManager():QueueCommand("/fps .1", -1);	
    end
    
end);

ashita.register_event('command', function(cmd, nType)
	-- Get the command arguments..
    local args = cmd:args();
	
	if (#args >= 1 and args[1] == "/fastcs") then		
		local command = "";
		if (args[2] == nil) then
			command = "help";
		else
			command = args[2]:lower();
		end;
		table.remove(args, 1);
		table.remove(args, 1);
		
		if command == "help" then
			print(string.format("%s", helptext));
		elseif command == "fps" or command == "frameratedivisor" then
			if #args == 0 then
				settings.frame_rate_divisor = (settings.frame_rate_divisor + 1) % 3;
				local help_message = (settings.frame_rate_divisor < 1) and "Uncapped" or (settings.frame_rate_divisor == 1) and "60 FPS" or (settings.frame_rate_divisor == 2) and "30 FPS";
				print("\30\32[FastCS]Default frame rate divisor is now: " .. settings.frame_rate_divisor .. " (" .. help_message .. ")");
			elseif #args == 1 then
				if args[1] == "60" or args[1] == "1" then
					settings.frame_rate_divisor = 1;
				elseif args[1] == "30" or args[1] == "2" then
					settings.frame_rate_divisor = 2;
				elseif args[1] == "uncapped" or args[1] == "0" then
					settings.frame_rate_divisor = 0;
				end;				
				
				local help_message = (settings.frame_rate_divisor < 1) and "Uncapped" or (settings.frame_rate_divisor == 1) and "60 FPS" or (settings.frame_rate_divisor == 2) and "30 FPS";
				print("\30\32[FastCS]Default frame rate divisor is now: " .. settings.frame_rate_divisor .. " (" .. help_message .. ")");
			else
				print("\30\58[FastCS]Error: The command syntax for fps was invalid.");
			end;
			
			--settings:save();
		elseif command == "exclusion" then
			if #args == 2 then
				if args[1] == "add" then
					settings.exclusions:add(args[2]:lower());
					print("\30\110[FastCS]: " .. args[2] .. " added to the exclusions list.");
				elseif args[1] == "remove" then
					settings.exclusions:remove(args[2]:lower());
					print("\30\110[FastCS]: " .. args[2] .. " removed from the exclusions list.");
				else
					print("\30\58[FastCS]Error: The command syntax for exclusion was invalid.");
				end;
				
				--settings:save();				
			else				
				print("\30\58[FastCS]Error: The command syntax for exclusion was invalid.");
			end;
		else
			print("\30\58[FastCS]Error: The command syntax was invalid.");
		end;	

		return true;
	end;
	
	return false;
end);