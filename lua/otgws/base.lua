--[[
    Shared global table
]]
_G.OTGW = {
    ["Addons"] = nil,
    ["Config"] = {
        ["NetName"] = "OTGW",
        ["AutoDLMaxSize"] = 5
    },
    ["Functions"] = {}
}

if SERVER then
    _G.OTGW.Addons = engine.GetAddons()
    _G.OTGW["ModelCache"] = {}
end