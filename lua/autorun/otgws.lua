local tModules = {
    ["Shared"] = {
        "base",
        "comm"
    },

    ["Server"] = {
        "sv/map",
        "sv/addons"
    },

    ["Client"] = {
        "cl/downloader",
        --"cl/entpreview"
    }
}

local function LoadModules(tModuleNames)
    for i, v in pairs(tModuleNames) do
        include(("otgws/%s.lua"):format(v))
    end
end

local function RegisterCSModules(tModuleNames)
    for i, v in pairs(tModuleNames) do
        AddCSLuaFile(("otgws/%s.lua"):format(v))
    end
end

LoadModules(tModules.Shared)

if SERVER then
    LoadModules(tModules.Server)
    RegisterCSModules(tModules.Shared)
    RegisterCSModules(tModules.Client)
else
    LoadModules(tModules.Client)
end