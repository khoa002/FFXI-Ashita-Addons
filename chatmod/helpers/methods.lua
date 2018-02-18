
function showmessage(mid,actor,target,text) 
    if(string.find(text,'$up')    ~= nil)then text =string.gsub(text,'$up',  string.char(0x81, 0xAA) ) end
    if(string.find(text,'$down')    ~= nil)then text =string.gsub(text,'$down',  string.char(0x81, 0xAB) ) end
    if(string.find(text,'$right')    ~= nil)then text =string.gsub(text,'$right',  string.char(0x81, 0xA8) ) end
    if(string.find(text,'$red')    ~= nil)then text =string.gsub(text,'$red',  string.char(0x1F, 39) ) end
    if(string.find(text,'$green')    ~= nil)then text =string.gsub(text,'$green',  string.char(0x1F, 204) ) end
    AshitaCore:GetChatManager():AddChatMessage(mid,text)
end

function getrelations(id)
	if(id >= 0)then
        local index = "other"
        for i=0 ,AshitaCore:GetDataManager():GetParty():GetAllianceParty0MemberCount()-1,1 do
            if(AshitaCore:GetDataManager():GetParty():GetMemberServerId(i) == id)then
                if(i == 0)then
                    index = "self"
                else
                    index  = "party"
                end
            end
        end
        for i=0 ,AshitaCore:GetDataManager():GetParty():GetAllianceParty1MemberCount()-1,1 do
            if(AshitaCore:GetDataManager():GetParty():GetMemberServerId(i+6) == id)then
                index  = "allies"
            end
        end
        for i=0 ,AshitaCore:GetDataManager():GetParty():GetAllianceParty2MemberCount()-1,1 do
            if(AshitaCore:GetDataManager():GetParty():GetMemberServerId(i+12) == id)then
                index  = "allies"
            end
        end
        return index
    elseif(bit.band(id,0x0FFF) >= 1792)then
        return "other"
    else
        local name = AshitaCore:GetDataManager():GetEntity():GetName(bit.band(id,0x0FFF))
        if (name == nil)then
            name = "Out Of Range"
        end
        local index = "other"
        local mobT = AshitaCore:GetDataManager():GetEntity():GetClaimServerId(bit.band(id,0x0FFF))
        if(mobT == AshitaCore:GetDataManager():GetParty():GetMemberServerId(0))then
            index = "foe"
        end
        for i=1 ,AshitaCore:GetDataManager():GetParty():GetAllianceParty0MemberCount()-1,1 do
            if(AshitaCore:GetDataManager():GetParty():GetMemberServerId(i) == mobT)then
                index  = "foe"
            end
        end
        for i=0 ,AshitaCore:GetDataManager():GetParty():GetAllianceParty1MemberCount()-1,1 do
            if(AshitaCore:GetDataManager():GetParty():GetMemberServerId(i+6) == mobT)then
                index  = "foe"
            end
        end
        for i=0 ,AshitaCore:GetDataManager():GetParty():GetAllianceParty2MemberCount()-1,1 do
            if(AshitaCore:GetDataManager():GetParty():GetMemberServerId(i+6) == mobT)then
                index  = "foe"
            end
        end
        return index
    end
end

function gettargets(act)
    local targets = {}
    for i = 1,act.target_count do
        for n = 1,act.targets[i].action_count do
            targets[i] = { get_name(act.targets[i].id) , act.targets[i].actions[1].param }
            act.targets[i].actions[n].message = 0
        end
    end
    return act,targets
end

function getmaname(id,action)
	if (table.haskey(mabil, action)) then
		return mabil[action].en;
	else
		return "(Unknown mabil)";
	end;
end 

function getjaname(id, action)
	if (table.haskey(jabil, action)) then
		return jabil[action].en;
	else
		return "(Unknown jabil)";
	end;
end;

function GetIndexById(id)
    for x = 0, 2303 do
        local ent = GetEntity(x);
        if (ent ~= nil and ent.ServerId == id) then
            return ent;
        end
    end    
    return 0;
end

function bust_rate(num)
    if (num <= 5 or num == 11 )then
        return ' ';
    end
    return (string.format(' [Chance to Bust]: %.1f ',(num-5)*16.67) .. string.char(0x81, 0x93)):color(4) .. string.char(0x1F, 1);
end

function color(text,int)
    if(text == nil)then
        text = "???" .. int
    end
    if int <= 255 then
        loc_col = string.char(0x1F, int)
        else
        loc_col = string.char(0x1E, int - 254)
    end
    return loc_col .. text .. string.char(0x1F, 1)
end

function lucky(roll,num)
    if(roll_luck[roll] == num or num == 11)then
        return string.char(31,158) ..( "(Lucky!) ") .. string.char(0x1F, 1)
    end
    return " "
end

