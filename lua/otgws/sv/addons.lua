--[[
    sends the player a list of all the available addons on spawn
]]
gameevent.Listen("player_activate")
hook.Add("player_activate", "OTGW", function(Data)
    local nID = Data.userid
    local Ply = Player(nID)

    local tAddons = {}

    for _, tAddon in pairs(_G.OTGW.Addons) do
        local tModelFiles, tModelDirs = file.Find("models/*", tAddon.title)
        local bHasModels = #tModelFiles > 0 or #tModelDirs > 0

        local tMatFiles, tMatDirs = file.Find("materials/*", tAddon.title)
        local bHasMaterials = #tMatFiles > 0 or #tMatDirs > 0

        local tResFiles, tResDirs = file.Find("resources/*", tAddon.title)
        local bHasResources = #tResFiles > 0 or #tResDirs > 0

        -- discard unused data
        tAddon.file = ""
        tAddon.mounted = nil
        tAddon.models = nil
        tAddon.timeadded = nil
        tAddon.tags = nil

        if bHasModels or bHasMaterials or bHasResources then
            table.insert(tAddons, tAddon)
        end
    end

    net.Start(_G.OTGW.Config.NetName)
    net.WriteUInt(_G.OTGW.Messages["REQ_ADDONS"], 8)
    net.WriteTable(tAddons)
    net.Send(Ply)
end)

--[[
    stores a list of all the models and which addons contain them
]]
_G.OTGW.Functions["GetModel"] = function(sModel)
    for _, tAddon in pairs(_G.OTGW.Addons) do
        if file.Exists(sModel, tAddon.title) then return tAddon.wsid end
    end
    print(("Could not find addon ID for model %s"):format(sModel))
end