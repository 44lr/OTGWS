--[[
    tries to find which addon contains the map the server's currently on
    if it finds it, make the clients download it
]]
local function RegisterMap()
    local sMap = game.GetMap()

    for _, tAddon in pairs(_G.OTGW.Addons) do
        if file.Exists(("maps/%s.bsp"):format(sMap), tAddon.title) then
            resource.AddWorkshop(tAddon.wsid)
            return
        end
    end
end
RegisterMap()