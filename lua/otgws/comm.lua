if SERVER then util.AddNetworkString(_G.OTGW.Config.NetName) end

--[[
    TO-DO:  Reinforce structure described below, based on argument order
            and use manual serialization / deserialization to improve network performance

    declaration of messages and their respective data

    structure:
                MESSAGENAME =>  * Keys =>   * Client => Name, Type (dictionary)
                                            * Server => Name, Type (dictionary)

                                * Handler (function)
                                * ID (number)
]]
local tMessages = {
    ["REQ_ADDONS"] = {},
    ["GET_MODEL"] = {}
}

--[[
    assign IDs to message types
]]
local tIDs = {}
local function PopulateIDs()
    local iCounter = 1
    for i, v in pairs(tMessages) do
        tIDs[i] = iCounter
        iCounter = iCounter + 1
    end
end
PopulateIDs()

local function MessageNameFromID(nID)
    for i, v in pairs(tIDs) do
        if v == nID then return i end
    end
end

--[[
    server message handler declarations
]]
if SERVER then
    tMessages["GET_MODEL"]["Handler"] = function(Player)
        local sModelPath = net.ReadString()
        if not sModelPath then
            print("no path")
            return
        end

        local nAddonId = _G.OTGW.Functions.GetModel(sModelPath)
        if not nAddonId then
            print("no id")
            return
        end

        net.Start(_G.OTGW.Config.NetName)
        net.WriteUInt(_G.OTGW.Messages["GET_MODEL"], 8)
        net.WriteUInt(nAddonId, 32)
        net.Send(Player)
    end
end

--[[
    client message handler declarations
]]
if CLIENT then
    tMessages["REQ_ADDONS"]["Handler"] = function(tKeys)
        local tAddons = net.ReadTable()
        _G.OTGW.Addons = tAddons
    end

    tMessages["GET_MODEL"]["Handler"] = function(tKeys)
        local nAddonID = net.ReadUInt(32)
        if nAddonID == 0 then return end

        _G.OTGW.Functions.DownloadAndMount(nAddonID)
    end
end

--[[
    server receiver func
]]
if SERVER then
    local function OnMessage(nLen, Player)
        local nMessageID = net.ReadUInt(8)
        if nMessageID == 0 then 
            return error("Message has no ID")
        end

        local sMessageType = MessageNameFromID(nMessageID)
        if not sMessageType then
            return error(("unable to find message type for id %i"):format(nMessageID))
        end
        
        tMessages[sMessageType].Handler(Player)
    end

    net.Receive(_G.OTGW.Config.NetName, OnMessage)
end

--[[
    client receiver func
]]
if CLIENT then
    local function OnMessage(nLen)
        local nMessageID = net.ReadUInt(8)
        if nMessageID == 0 then 
            return error("Message has no ID")
        end

        local sMessageType = MessageNameFromID(nMessageID)
        if not sMessageType then
            return error(("unable to find message type for id %i"):format(nMessageID))
        end

        tMessages[sMessageType].Handler()
    end

    net.Receive(_G.OTGW.Config.NetName, OnMessage)
end

_G.OTGW["Messages"] = tIDs