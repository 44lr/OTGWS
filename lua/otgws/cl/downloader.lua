--[[
	TO-DO:
		make sure all addons are loaded before running flushlods
		fix functions that share the same name
]]

-- holds queue for addon downloads (read from last to first)
local tQueue = {}
local tQueueRegistered = {}

local nDefaultMountTimeout = 1
local nMountTimeout = nDefaultMountTimeout

-- models that have already been requested
local tIgnoreCache = {}

local function RequestModel(sModelPath)
    if (sModelPath:sub(sModelPath:len() - 2, sModelPath:len()) != "mdl") then return end

    print(("Requesting model %s"):format(sModelPath))

    net.Start(_G.OTGW.Config.NetName)
    net.WriteUInt(_G.OTGW.Messages["GET_MODEL"], 8)
    net.WriteString(sModelPath)
    net.SendToServer()
end

local function RegisterEntity(Ent)
    local sModel = Ent:GetModel()

    if Ent.Base then if Ent.Base:sub(1, 4) == "arc9" then sModel = Ent.ViewModel end end
    if not sModel then return end

    if not util.IsValidModel(sModel) and not tIgnoreCache[sModel] then
        tIgnoreCache[sModel] = true
        RequestModel(sModel)
    end
end

local function OnEntityAdded(Ent)
    local sTimerName = ("OTGW_EntityCheck%i"):format(Ent:EntIndex())
    timer.Create(sTimerName, 0.1, 10, function()
        if Ent:IsValid() then
            RegisterEntity(Ent)
            timer.Remove(sTimerName)
        end
    end)
end

hook.Add("OnEntityCreated", "OTGW_Downloader", OnEntityAdded)

local function DownloadAndMount(sAddonID)
    if file.Exists(("cache/workshop/%s.gma"):format(sAddonID), "GAME") then
        local bSuccess, tFiles = game.MountGMA(("cache/workshop/%s.gma"):format(sAddonID))
        if bSuccess then RunConsoleCommand("r_flushlod") end
        return
    end

    steamworks.DownloadUGC(sAddonID, function(sPath, File)
        print(sPath)
        local bSuccess, tFiles = game.MountGMA(sPath)
        if bSuccess then RunConsoleCommand("r_flushlod") end
    end)
end

local function GetDependencies(sAddonID)
    if tQueueRegistered[sAddonID] then return end
    tQueueRegistered[sAddonID] = true

    nMountTimeout = nDefaultMountTimeout
    steamworks.FileInfo(sAddonID, function(tInfo)
        table.insert(tQueue, sAddonID)
        for i, v in pairs(tInfo.children) do GetDependencies(v) end
    end)
end

_G.OTGW.Functions["DownloadAndMount"] = function(nAddonID)
    if tQueueRegistered[tostring(nAddonID)] then return end
    GetDependencies(nAddonID)
end

local nLastThink = SysTime()

function OnThink()
    local nTime = SysTime()

    nMountTimeout = nMountTimeout - (nTime - nLastThink)
    nLastThink = nTime

    if #tQueue == 0 then return end

    if nMountTimeout <= 0 then
        print("Fetching addons")
        for i=#tQueue, 1, -1 do
            DownloadAndMount(tQueue[i])
            table.remove(tQueue, i)
        end
        nMountTimeout = nDefaultMountTimeout
    end
end
hook.Add("Think", "OTGW_Downloader", OnThink)

timer.Create("OTGW_WaitForAddons", 0.1, 0, function()
    if _G.OTGW.Addons then
        timer.Remove("OTGW_WaitForAddons")

        local tOldAddons = engine.GetAddons()
        local tOldAddonNames = {}
        for _, tAddon in pairs(tOldAddons) do tOldAddonNames[tAddon.title] = true end

        for _, tAddon in pairs(_G.OTGW.Addons) do
            steamworks.FileInfo(tostring(tAddon.wsid), function(tData)
                if (tAddon.size <= _G.OTGW.Config.AutoDLMaxSize * 1024 * 1024) and not tOldAddonNames[tAddon.title] then
                    DownloadAndMount(tostring(tAddon.wsid))
                end
            end)
        end
    end
end)