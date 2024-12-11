--[[

    SA-RP Modloader
    by Fernando

    File: client.lua

]]

loadedMods = {}

antiSpam = nil
loadingAntiSpam = nil
settingsXMLFile = nil
antiReloadSpam = nil

function cmdModLoader(cmd, bypass)


    if loadingAntiSpam then
        return outputChatBox("Mods are still loading. Please wait...", 255,0,0)
    end

    local b = bypass and type(bypass)=="string" and bypass=="bypass"
    if not b and isTimer(antiSpam) then
        return triggerEvent("displayMesaage", localPlayer, "Please wait before doing this again.", "warning")
    end

    antiSpam = setTimer(function()
        antiSpam = nil
    end, 5000, 1)

    if getElementData(localPlayer, "modloader:previewing") then
        return triggerEvent("displayMesaage", localPlayer, "You must end your Mod Preview before opening the Modloader.", "warning")
    end

    triggerServerEvent("modloader:requestOpenGUI", localPlayer)

end
addCommandHandler("modloader", cmdModLoader, false)

function doRefreshMods()

    local veh = getPedOccupiedVehicle(localPlayer)
    if veh then
        return false, "You must on foot to reload mods."
    end

    if isTimer(antiReloadSpam) then
        return false, "You must wait before reloading mods again."
    end

    if loadingAntiSpam then
        return false, "Mods are still loading. Please wait..."
    end

    local loggedin = getElementData(localPlayer, "account:id")
    if not loggedin then
        return false, "You must be logged in to reload mods."
    end

    if getPedWeaponSlot(localPlayer) ~= 0 then
        return false, "You must unequip your weapon before doing this."
    end

    antiReloadSpam = setTimer(function()
        antiReloadSpam = nil
    end, 10000, 1)

    unloadVehicleMods()
    unloadSkinMods()
    unloadWeaponMods()

    triggerEvent("SARPML_loadMods", localPlayer)

    return true

end

function unloadVehicleMods()
    if loadedMods["vehicles"] then
        for model, stuff in pairs(loadedMods["vehicles"]) do

            local txd = stuff["txd"]
            local dff = stuff["dff"]

            local txdEl, txdEnabled, txdPath
            local dffEl, dffEnabled, dffPath

            if txd then
                txdEl = txd[3]
                txdEnabled = txd[2]
                txdPath = txd[1]
            end

            if dff then
                dffEl = dff[3]
                dffEnabled = dff[2]
                dffPath = dff[1]
            end


            if isElement(dffEl) then
                destroyElement(dffEl)
                engineRestoreModel(model)

                writeModLog("[refreshmods] [veh] restored DFF for "..getVehicleNameFromModel(model).." ("..model..") "..dffPath)
            end
            if isElement(txdEl) then
                destroyElement(txdEl)

                writeModLog("[refreshmods] [veh] restored TXD for "..getVehicleNameFromModel(model).." ("..model..") "..txdPath)
            end
        end
    end
end
function unloadSkinMods()
    if loadedMods["skins"] then
        for model, stuff in pairs(loadedMods["skins"]) do

            local txd = stuff["txd"]
            local dff = stuff["dff"]

            local txdEl, txdEnabled, txdPath
            local dffEl, dffEnabled, dffPath

            if txd then
                txdEl = txd[3]
                txdEnabled = txd[2]
                txdPath = txd[1]
            end

            if dff then
                dffEl = dff[3]
                dffEnabled = dff[2]
                dffPath = dff[1]
            end


            if isElement(dffEl) then
                destroyElement(dffEl)
                engineRestoreModel(model)

                writeModLog("[refreshmods] [skin] restored DFF for "..dffPath.." ("..model..")")
            end
            if isElement(txdEl) then
                destroyElement(txdEl)

                writeModLog("[refreshmods] [skin] restored TXD for "..txdPath.." ("..model..")")
            end
        end
    end
end
function unloadWeaponMods()
    if loadedMods["weapons"] then
        for model, stuff in pairs(loadedMods["weapons"]) do

            local txd = stuff["txd"]
            local dff = stuff["dff"]

            local txdEl, txdEnabled, txdPath
            local dffEl, dffEnabled, dffPath

            if txd then
                txdEl = txd[3]
                txdEnabled = txd[2]
                txdPath = txd[1]
            end

            if dff then
                dffEl = dff[3]
                dffEnabled = dff[2]
                dffPath = dff[1]
            end


            if isElement(dffEl) then
                destroyElement(dffEl)
                engineRestoreModel(model)

                writeModLog("[refreshmods] [weapon] restored DFF for "..dffPath.." ("..model..")")
            end
            if isElement(txdEl) then
                destroyElement(txdEl)

                writeModLog("[refreshmods] [weapon] restored TXD for "..txdPath.." ("..model..")")
            end
        end
    end
end

local function makeReadMe()
    local filePath = readMeName
    if not fileExists(filePath) then

        local newFile = fileCreate(filePath)
        if (newFile) then
            fileWrite(newFile, readMeContent)
            fileClose(newFile)
        end
    else
        fileDelete(filePath)
        makeReadMe()
    end
end

local function makeUploadReadMe()

    local filePath = uploadReadMeName
    if not fileExists(filePath) then

        local newFile = fileCreate(filePath)
        if (newFile) then
            fileWrite(newFile, uploadReadMeContent)
            fileClose(newFile)
        end
    else
        fileDelete(filePath)
        makeUploadReadMe()
    end
end


local function makeMyModLogs()
    if not fileExists(ModLogsName) then

        local newFile = fileCreate(ModLogsName)
        if (newFile) then
            fileWrite(newFile, ModLogsContent)
            fileClose(newFile)
        end
    end
end

function writeModLog(msg)
    if not fileExists(ModLogsName) then
        makeMyModLogs()
    end

    local time = getRealTime()

    local hours = time.hour
    local minutes = time.minute
    local seconds = time.second

    local monthday = time.monthday
    local month = time.month
    local year = time.year

    local dateStr = string.format("%04d-%02d-%02d %02d:%02d:%02d", year + 1900, month + 1, monthday, hours, minutes, seconds)
    local hFile = fileOpen(ModLogsName)
    if hFile then
        fileSetPos( hFile, fileGetSize( hFile ) )
        fileWrite(hFile, "\n"..dateStr.." - "..msg)
        fileFlush(hFile)
        fileClose(hFile)
    end
end

function loadVehicleMods()

    local filePath
    -- Vehicle mods
    for i=1, #vehicleMods do
		local mod = vehicleMods[i]

		local model = mod[1]

        local dfftxdName = mod[2]

        filePath = "mods/"..dfftxdName..".txd"
        if (fileExists(filePath)) then
            local hFile = fileOpen(filePath, true)
            if hFile then
                local count = fileGetSize(hFile)
                local data = fileRead(hFile, count)

                local txdModel = engineLoadTXD(data)
                if txdModel then
                    local enabled = "enabled"
                    if getSetting("txd"..tostring(model)) and getSetting("txd"..tostring(model)) == "disabled" then
                        enabled = "disabled"
                        outputConsole("- Not replacing TXD for "..getVehicleNameFromModel(model).." ("..model..") because you disabled it.")
                    else
                        engineImportTXD(txdModel, model)
                        outputConsole("- Replacing TXD for "..getVehicleNameFromModel(model).." ("..model..").")
                    end

                    if not loadedMods["vehicles"] then
                        loadedMods["vehicles"] = {}
                    end
                    if not loadedMods["vehicles"][tostring(model)] then
                        loadedMods["vehicles"][tostring(model)] = {}
                    end

                    loadedMods["vehicles"][tostring(model)]["txd"] = {filePath, enabled, txdModel}

                    writeModLog("[loadmods] [veh] loaded TXD for "..getVehicleNameFromModel(model).." ("..model..") "..filePath)

                    if not getSetting("txd"..tostring(model)) then
                        setSetting("txd"..tostring(model), tostring("enabled"))
                    end
                else
                    writeModLog("[loadmods] [veh] error loading TXD for "..getVehicleNameFromModel(model).." ("..model..") "..filePath)
                end

                fileClose(hFile)
            end
        end


        filePath = "mods/"..dfftxdName..".dff"
        if (fileExists(filePath)) then
            local hFile = fileOpen(filePath, true)
            if hFile then
                local count = fileGetSize(hFile)
                local data = fileRead(hFile, count)

                local dffModel = engineLoadDFF(data, model)
                if dffModel then
                    local enabled = "enabled"
                    if getSetting("dff"..tostring(model)) and getSetting("dff"..tostring(model)) == "disabled" then
                        enabled = "disabled"
                        outputConsole("- Not replacing DFF for "..getVehicleNameFromModel(model).." ("..model..") because you disabled it.")
                    else
                        engineReplaceModel(dffModel, model)
                        outputConsole("- Replacing DFF for "..getVehicleNameFromModel(model).." ("..model..").")
                    end

                    if not loadedMods["vehicles"] then
                        loadedMods["vehicles"] = {}
                    end
                    if not loadedMods["vehicles"][tostring(model)] then
                        loadedMods["vehicles"][tostring(model)] = {}
                    end

                    loadedMods["vehicles"][tostring(model)]["dff"] = {filePath, enabled, dffModel}

                    writeModLog("[loadmods] [veh] loaded DFF for "..getVehicleNameFromModel(model).." ("..model..") "..filePath)

                    if not getSetting("dff"..tostring(model)) then
                        setSetting("dff"..tostring(model), tostring("enabled"))
                    end
                else

                    writeModLog("[loadmods] [veh] error loading DFF for "..getVehicleNameFromModel(model).." ("..model..") "..filePath)
                end

                fileClose(hFile)
            end
        end
    end
end

function loadSkinMods()

    local filePath
    -- Skin mods
    for i=1, #skinMods do
		local mod = skinMods[i]

		local model = mod[1]

        local dfftxdName = mod[2]

        filePath = "mods/"..dfftxdName..".txd"
        if (fileExists(filePath)) then

            local hFile = fileOpen(filePath, true)
            if hFile then
                local count = fileGetSize(hFile)
                local data = fileRead(hFile, count)

                local txdModel = engineLoadTXD(data)
                if txdModel then
                    local enabled = "enabled"
                    if getSetting("txd"..tostring(model)) and getSetting("txd"..tostring(model)) == "disabled" then
                        enabled = "disabled"
                        outputConsole("- Not replacing TXD for "..dfftxdName.." ("..model..") because you disabled it.")
                    else
                        engineImportTXD(txdModel, model)
                        outputConsole("- Replacing TXD for "..dfftxdName.." ("..model..").")
                    end

                    if not loadedMods["skins"] then
                        loadedMods["skins"] = {}
                    end
                    if not loadedMods["skins"][tostring(model)] then
                        loadedMods["skins"][tostring(model)] = {}
                    end

                    loadedMods["skins"][tostring(model)]["txd"] = {dfftxdName, enabled, txdModel}

                    writeModLog("[loadmods] [skin] loaded TXD for "..dfftxdName.." ("..model..")")

                    if not getSetting("txd"..tostring(model)) then
                        setSetting("txd"..tostring(model), tostring("enabled"))
                    end
                else
                    writeModLog("[loadmods] [skin] error loading TXD for "..dfftxdName.." ("..model..")")
                end

                fileClose(hFile)
            end
        end

        filePath = "mods/"..dfftxdName..".dff"
        if (fileExists(filePath)) then

            local hFile = fileOpen(filePath, true)
            if hFile then
                local count = fileGetSize(hFile)
                local data = fileRead(hFile, count)

                local dffModel = engineLoadDFF(data, model)
                if dffModel then
                    local enabled = "enabled"
                    if getSetting("dff"..tostring(model)) and getSetting("dff"..tostring(model)) == "disabled" then
                        enabled = "disabled"
                        outputConsole("- Not replacing DFF for "..dfftxdName.." ("..model..") because you disabled it.")
                    else
                        engineReplaceModel(dffModel, model)
                        outputConsole("- Replacing DFF for "..dfftxdName.." ("..model..").")
                    end

                    if not loadedMods["skins"] then
                        loadedMods["skins"] = {}
                    end
                    if not loadedMods["skins"][tostring(model)] then
                        loadedMods["skins"][tostring(model)] = {}
                    end

                    loadedMods["skins"][tostring(model)]["dff"] = {dfftxdName, enabled, dffModel}

                    writeModLog("[loadmods] [skin] loaded DFF for "..dfftxdName.." ("..model..")")

                    if not getSetting("dff"..tostring(model)) then
                        setSetting("dff"..tostring(model), tostring("enabled"))
                    end
                else
                    writeModLog("[loadmods] [skin] error loading DFF for "..dfftxdName.." ("..model..")")
                end

                fileClose(hFile)
            end
        end
    end
end

-- exported
function isReplacingSkin(skinid)
    local mods = loadedMods["skins"]

    if mods then

        for model, tab in pairs(mods) do
            local hasEnabled = false

            if tab["dff"] then
                for k, mod in pairs(tab["dff"]) do
                    if k == 2 and mod == "enabled" then
                        -- enabled
                        hasEnabled = true
                    end
                end
            end

            if tab["txd"] then
                for k, mod in pairs(tab["txd"]) do
                    if k == 2 and mod == "enabled" then
                        -- enabled
                        hasEnabled = true
                    end
                end
            end


            if hasEnabled and tonumber(model) == tonumber(skinid) then
                return true
            end
        end
    end
    return false
end

function loadWeaponMods()

    local filePath
    -- Weapon mods
    for i=1, #weaponMods do
        local mod = weaponMods[i]

        local model = mod[1]

        local dfftxdName = mod[2]

        filePath = "mods/"..dfftxdName..".txd"
        if (fileExists(filePath)) then

            local hFile = fileOpen(filePath, true)
            if hFile then
                local count = fileGetSize(hFile)
                local data = fileRead(hFile, count)

                local txdModel = engineLoadTXD(data)
                if txdModel then
                    local enabled = "enabled"
                    if getSetting("txd"..tostring(model)) and getSetting("txd"..tostring(model)) == "disabled" then
                        enabled = "disabled"
                        outputConsole("- Not replacing TXD for "..dfftxdName.." ("..model..") because you disabled it.")
                    else
                        engineImportTXD(txdModel, model)
                        outputConsole("- Replacing TXD for "..dfftxdName.." ("..model..").")
                    end

                    if not loadedMods["weapons"] then
                        loadedMods["weapons"] = {}
                    end
                    if not loadedMods["weapons"][tostring(model)] then
                        loadedMods["weapons"][tostring(model)] = {}
                    end

                    loadedMods["weapons"][tostring(model)]["txd"] = {dfftxdName, enabled, txdModel}

                    writeModLog("[loadmods] [weapon] loaded TXD for "..dfftxdName.." ("..model..")")

                    if not getSetting("txd"..tostring(model)) then
                        setSetting("txd"..tostring(model), tostring("enabled"))
                    end
                else
                    writeModLog("[loadmods] [weapon] error loading TXD for "..dfftxdName.." ("..model..")")
                end

                fileClose(hFile)
            end
        end

        filePath = "mods/"..dfftxdName..".dff"
        if (fileExists(filePath)) then

            local hFile = fileOpen(filePath, true)
            if hFile then
                local count = fileGetSize(hFile)
                local data = fileRead(hFile, count)

                local dffModel = engineLoadDFF(data, model)
                if dffModel then
                    local enabled = "enabled"
                    if getSetting("dff"..tostring(model)) and getSetting("dff"..tostring(model)) == "disabled" then
                        enabled = "disabled"
                        outputConsole("- Not replacing DFF for "..dfftxdName.." ("..model..") because you disabled it.")
                    else
                        engineReplaceModel(dffModel, model)
                        outputConsole("- Replacing DFF for "..dfftxdName.." ("..model..").")
                    end

                    if not loadedMods["weapons"] then
                        loadedMods["weapons"] = {}
                    end
                    if not loadedMods["weapons"][tostring(model)] then
                        loadedMods["weapons"][tostring(model)] = {}
                    end

                    loadedMods["weapons"][tostring(model)]["dff"] = {dfftxdName, enabled, dffModel}

                    writeModLog("[loadmods] [weapon] loaded DFF for "..dfftxdName.." ("..model..")")

                    if not getSetting("dff"..tostring(model)) then
                        setSetting("dff"..tostring(model), tostring("enabled"))
                    end
                else
                    writeModLog("[loadmods] [weapon] error loading DFF for "..dfftxdName.." ("..model..")")
                end

                fileClose(hFile)
            end
        end
    end
end

function loadMods()
    loadedMods = {}

    loadModSettings()

    loadVehicleMods()
    loadSkinMods()
    loadWeaponMods()

    if isElement(mlGUI.window) then
        openMLGUI()
    end

    outputConsole("Loaded mod-loader mods.")
    triggerServerEvent("ML:makeServerLog", localPlayer, loadedMods)

    loadingAntiSpam = nil
end

function applyModLoaderMods(onlyML)

    loadingAntiSpam = true

    if not onlyML then
        -- load server mods
        triggerEvent("mods:applyVehSkinMods", localPlayer)
        outputConsole("Loaded server mods.")
    end

    outputConsole("Loading mod-loader mods...")
    setTimer(function()
        loadMods()
    end, 5000, 1)


end
addEvent("SARPML_loadMods", true)
addEventHandler("SARPML_loadMods", root, applyModLoaderMods)

function setSetting(setting, value)
    if value then
        value = tostring(value)
        xmlNodeSetAttribute(settingsXMLFile, setting, value)
    end
    xmlSaveFile(settingsXMLFile)
end

function getSetting(setting)
    if setting then
        local val = xmlNodeGetAttribute(settingsXMLFile, setting)
        if val then
            return val
        else
            return false
        end
    else
        return false
    end
end

function loadModSettings()
    if isElement(settingsXMLFile) then
        xmlUnloadFile(settingsXMLFile)
    end
    settingsXMLFile = xmlLoadFile(settingsFile)
    if not settingsXMLFile then
        settingsXMLFile = xmlCreateFile(settingsFile, "settings")
    end
end

local function onResourceStart()

    makeReadMe()
    makeUploadReadMe()
    makeMyModLogs()
    loadModSettings()

	-- mod loading moved to account login.
end
addEventHandler( "onClientResourceStart", getResourceRootElement(getThisResource()), onResourceStart )


function findModAndSend(modType, mod, av, extra)
    local name = mod.name
    local pathDff = "upload/"..name..".dff"
    local pathTxd = "upload/"..name..".txd"

    local dffdata, txddata

    local dffError = false

    if fileExists(pathDff) then
        local f = fileOpen(pathDff, true)
        if f then
            local count = fileGetSize(f)
            local data = fileRead(f, count)
            dffdata = data
            fileClose(f)
        else
            dffError = true
        end
    else
        dffError = true
    end

    if dffError then
        return triggerEvent("modloader:receiveUploadConfirmation_notFinal", localPlayer, false, "Failed to get "..name..".dff for upload.")
    end

    local txdError = false

    if fileExists(pathTxd) then
        local f = fileOpen(pathTxd, true)
        if f then
            local count = fileGetSize(f)
            local data = fileRead(f, count)
            txddata = data
            fileClose(f)
        else
            txdError = true
        end
    else
        txdError = true
    end

    if txdError then
        return triggerEvent("modloader:receiveUploadConfirmation_notFinal", localPlayer, false, "Failed to get "..name..".txd for upload.")
    end

    av = tonumber(av)
    if av == 1 then
        -- personal upload (first few free)

        local totaluploads, maxFreeModUploads, gcPrice = unpack(extra)
        local isAdm = exports["sarp-new-mods"]:isModFullPerm(localPlayer) -- pay check #1

        if totaluploads >= maxFreeModUploads then--and not isAdm 
            -- ask to pay
            triggerEvent("modloader:askToPayForUpload", localPlayer, modType, mod, dffdata, txddata, extra)
        else
            -- if totaluploads >= maxFreeModUploads and isAdm then
            --     outputChatBox("Bypassing max "..maxFreeModUploads.." free uploads limit as Mod Reviewer..", 255,194, 14)
            -- end
            -- finish saving mod
            triggerServerEvent("newmods:saveModFromClient", localPlayer, modType, mod, dffdata, txddata, av, extra)
        end
    elseif av == 2 then
        -- faction upload (free - limited to slots)
        triggerEvent("modloader:askToSelectFaction", localPlayer, modType, mod, dffdata, txddata, extra)
    elseif av == 3 or av == 4 then
        -- global/server upload (free)
        triggerEvent("modloader:askToUploadGlobalServer", localPlayer, modType, av, mod, dffdata, txddata)
    else
        triggerEvent("modloader:receiveUploadConfirmation", localPlayer, false, "dis should never happen")
    end
end
addEvent("modloader:getModFromClient", true)
addEventHandler("modloader:getModFromClient", root, findModAndSend)


-- Admin Preview mod
function setPreviewingMod(on, mt, upid, imgid, isPlayer)
    triggerEvent("displayMesaage", localPlayer, "Starting mod preview..", "success")
    triggerServerEvent("newmods:previewUploadedMod", localPlayer, on, mt, upid, imgid, isPlayer)
end


-- Checks called from GUI
function checkModFilesExist(name)
    local pathDff = "upload/"..name..".dff"
    local pathTxd = "upload/"..name..".txd"


    if not fileExists(pathDff) then
        return false, "Did not find SARP_Modloader/"..pathDff
    end
    if not fileExists(pathTxd) then
        return false, "Did not find SARP_Modloader/"..pathTxd
    end

    return true
end

local tx,ty,tz = 2117.12109375, 2987.7158203125, 25

local baseModels = {
    ["ped"] = 1,
    ["vehicle"] = 400,
}

function checkModFilesCorrupted(name, modType)

    if not baseModels[modType] then
        return false, modType.." is currently not supported."
    end

    local pathDff = "upload/"..name..".dff"
    local pathTxd = "upload/"..name..".txd"

    local txdModel = engineLoadTXD(pathTxd)
    if not txdModel then
        destroyElement(txdModel)
        return false, name..".txd is corrupted and could not be loaded."
    end

    local testModel = baseModels[modType]

    local dffModel = engineLoadDFF(pathDff, testModel)
    if not dffModel then
        destroyElement(dffModel)
        return false, name..".dff is corrupted and could not be loaded."
    end


    local testElement
    if modType == "ped" then

        -- try the mod on a test ped
        testElement = createPed(testModel, tx,ty,tz)

    elseif modType == "vehicle" then

        -- try the mod on a test vehicle
        testElement = createVehicle(testModel, tx,ty,tz)
    end

    if not engineImportTXD(txdModel, testModel) then
        engineRestoreModel(testModel)
        destroyElement(txdModel)
        destroyElement(dffModel)
        destroyElement(testElement)
        return false, name..".txd is corrupted and cannot be applied."
    end
    if not engineReplaceModel(dffModel, testModel) then
        engineRestoreModel(testModel)
        destroyElement(dffModel)
        destroyElement(txdModel)
        destroyElement(testElement)
        return false, name..".txd is corrupted and cannot be applied."
    end

    engineRestoreModel(testModel)
    destroyElement(testElement)
    destroyElement(dffModel)
    destroyElement(txdModel)

    return true
end

local mass_types = {
    ["vehicle"] = true
}
local mass_path = "massupload_%s/"
local list_file = "list.txt"

local dtimer
local utimer
local uploaded

addCommandHandler("startmassupload", function(cmd, modtype)
    if not exports.integration:isPlayerScripter(localPlayer) then
        return outputChatBox("Scripter only", 255,0,0)
    end

    if not modtype or not mass_types[modtype] then
        outputChatBox(tostring(inspect(mass_types)), 255,126,0)
        return outputChatBox("SYNTAX: /"..cmd.." [Mod Type from the list above]", 255,194,14)
    end

    if isTimer(utimer) then
        return outputChatBox("BUSY UPLOADING", 255,0,0)
    end
    if isTimer(dtimer) then
        return outputChatBox("BUSY DELETING", 255,0,0)
    end
    if uploaded then
        return outputChatBox("Restart the resource if you want to mass-upload again", 255,0,0)
    end

    local folder = string.format(mass_path,modtype)

    local list = folder..list_file
    if not fileExists(list) then
        return outputChatBox("[client] File names (excluding extensions like .dff) need to be listed in '"..list_file.."' one name per line", 255,255,0)
    end

    local f = fileOpen(list)
    if not f then return outputChatBox("Error", 255,0,0) end

    local content = fileRead(f, fileGetSize(f))
    fileClose(f)

    local mods = {}

    local tab = split(content, "\n")
    local lineNumber = 1
    for k, line in pairs(tab) do
        line = line:gsub("%\r", "")

        local tab = split(line,",")
        if not tab[2] then
            outputChatBox("Missing base model ID/name after a comma".." (Line "..lineNumber..")", 255,0,0)
            return outputChatBox("Example: deluxo,496  or  deluxo,Blista Compact")
        end

        local name = tab[1]
        local base = tab[2]

        local dff = folder..name..".dff"
        local txd = folder..name..".txd"
        if not fileExists(dff) then
            return outputChatBox("Aborting, file doesn't exist: "..dff.." (Line "..lineNumber..")", 255,0,0)
        end
        if not fileExists(txd) then
            return outputChatBox("Aborting, file doesn't exist: "..txd.." (Line "..lineNumber..")", 255,0,0)
        end

        local baseid
        if tonumber(base) then
            if not getVehicleNameFromModel(tonumber(base)) then
                return outputChatBox("Unknown MTA vehicle ID '"..base.."' on "..name.." (Line "..lineNumber..")", 255,0,0)
            end
            baseid = tonumber(base)
        else
            local model = getVehicleModelFromName(base)
            if not model then
                return outputChatBox("Unknown MTA vehicle name '"..base.."' on "..name.." (Line "..lineNumber..")", 255,0,0)
            end
            baseid = model
        end

        table.insert(mods, {name=name, dff=dff, txd=txd, baseid=baseid})
        lineNumber = lineNumber + 1
    end

    local interval = 3000
    local total = (table.size(mods))
    local totaltime = interval*total
    
    utimer = setTimer(function()
        utimer = nil
    end, totaltime, total)

    outputChatBox("-- WILL CAUSE SERVER LAG --", 255,0,0)
    outputChatBox("Uploading "..total.." mods, finishing in approx. "..(totaltime/1000).." seconds", 255,194,14)

    local curr = 0
    uploaded = {}

    for k, mod in pairs(mods) do
        local dff = fileOpen(mod.dff)
        if not dff then
            return outputChatBox("Error opening file: "..mod.dff, 255,0,0)
        end
        local txd = fileOpen(mod.txd)
        if not txd then
            return outputChatBox("Error opening file: "..mod.txd, 255,0,0)
        end
        local dffdata = fileRead(dff, fileGetSize(dff))
        fileClose(dff)
        local txddata = fileRead(txd, fileGetSize(txd))
        fileClose(txd)

        local mod2 = {
            name = mod.name,
            title = mod.name,
            author = "MASS UPLOAD",
            desc = "",
            modelid = 0,
            baseid = mod.baseid
        }

        setTimer(function()
            outputChatBox("Uploading "..mod.name.." (base: "..getVehicleNameFromModel(mod.baseid)..") ..", 187,187,187)
            triggerServerEvent("newmods:validateUpload", localPlayer, "vehicle", mod2, dffdata, txddata, 4, {mod.baseid}, true)
            table.insert(uploaded, mod.name)

        end, interval+(curr*interval), 1)
        curr = curr + 1
    end

    outputChatBox("/deletemassuploads to undo what you just uploaded", 255,126,0)
end, false)

addCommandHandler("deletemassuploads", function(cmd)
    if not exports.integration:isPlayerScripter(localPlayer) then
        return outputChatBox("Scripter only", 255,0,0)
    end

    if isTimer(utimer) then
        return outputChatBox("BUSY UPLOADING", 255,0,0)
    end
    if isTimer(dtimer) then
        return outputChatBox("BUSY DELETING", 255,0,0)
    end
    if not uploaded then
        return outputChatBox("Havent mass-uploaded anything", 255,0,0)
    end

    local interval = 3000
    local total = (table.size(uploaded))
    local totaltime = interval*total

    dtimer = setTimer(function()
        dtimer = nil
    end, totaltime, total)

    outputChatBox("-- WILL CAUSE SERVER LAG --", 255,0,0)
    outputChatBox("Deleting "..total.." uploaded mods, finishing in approx. "..(totaltime/1000).." seconds", 255,194,14)

    local curr = 0
    for k, name in pairs(uploaded) do

        setTimer(function()
            outputChatBox("Deleting uploaded mod '"..name.."' ..", 220,220,220)
            triggerServerEvent("newmods:forceDeleteMod", localPlayer, "vehicle", name)
        end, interval+(curr*interval), 1)

        curr = curr + 1
    end

    uploaded = nil
end, false)