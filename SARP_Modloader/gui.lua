 --[[

    SA-RP Modloader
    by Fernando

    File: gui.lua

]]

mlGUI = {}

sX, sY = guiGetScreenSize()
wW, wH = 900, 650

lastTab = 1

local myUploads, allUploads

local bb

function openMLGUI(myUploads_, allUploads_)
    closeMLGUI()

    bb = exports.blur_box:createBlurBox(0, 0,sX, sY, 255,255,255,200, false)
    setElementData(localPlayer, "exclusiveGUI", true)
    triggerEvent("f_toggleCursor", localPlayer, true)
    guiSetInputMode("no_binds_when_editing")

    -- clearChat()

    if myUploads_ then
        myUploads = myUploads_
    end

    if allUploads_ then
        allUploads = allUploads_
    end

    mlGUI.window = guiCreateWindow((sX - wW)/2, (sY - wH)/2, wW, wH, title, false)
    guiWindowSetSizable(mlGUI.window,false)

    mlGUI.bRefresh = guiCreateButton(0, wH-40, wW/4 -5, 35, "Reload my mods", false, mlGUI.window)
    addEventHandler("onClientGUIClick", mlGUI.bRefresh, refreshML, false)
    guiSetProperty(mlGUI.bRefresh, 'NormalTextColour', 'FF00FF00')

    mlGUI.bUpload = guiCreateButton(wW/4  +5, wH-40, wW/4 -5, 35, "Upload a mod", false, mlGUI.window)
    addEventHandler("onClientGUIClick", mlGUI.bUpload, uploadGUI, false)
    guiSetProperty(mlGUI.bUpload, 'NormalTextColour', 'ffffc400')

    mlGUI.bHelp = guiCreateButton(wW/4 + wW/4 +5, wH-40, wW/4 -5, 35, "Help (Tutorials)", false, mlGUI.window)
    addEventHandler("onClientGUIClick", mlGUI.bHelp, function()

        guiSetEnabled(mlGUI.window, false)
        guiSetVisible(mlGUI.window, false)
        helpML()
    end, false)
    guiSetProperty(mlGUI.bHelp, 'NormalTextColour', 'FF03E3FC')

    mlGUI.bClose = guiCreateButton(wW/4 +5 + wW/4 + wW/4, wH-40, wW/4 -5, 35, "Close", false, mlGUI.window)
    addEventHandler("onClientGUIClick", mlGUI.bClose, closeMLGUI, false)

    mlGUI.info = guiCreateLabel(14, 25, wW-10, 20, "Press Reload to scan for new mods and apply all enabled mods. Double click a line from the list to interact with it.", false, mlGUI.window)

    mlGUI.tabs = guiCreateTabPanel(0,50, wW-5, wH-100, false, mlGUI.window)
    mlGUI.vtab = guiCreateTab("Vehicles", mlGUI.tabs)
    setElementData(mlGUI.vtab, "tabID", 1)
    mlGUI.stab = guiCreateTab("Skins", mlGUI.tabs)
    setElementData(mlGUI.stab, "tabID", 2)
    mlGUI.wtab = guiCreateTab("Weapons", mlGUI.tabs)
    setElementData(mlGUI.wtab, "tabID", 3)


    local exist = false
    for mt, v in pairs(myUploads) do
        if #v > 0 then
            exist = true
            break
        end
    end
    if exist then
        mlGUI.uptab = guiCreateTab("My Uploads", mlGUI.tabs)
        setElementData(mlGUI.uptab, "tabID", 4)

        mlGUI.uploads = guiCreateGridList(0, 0, wW -20, wH-125, false, mlGUI.uptab)
        mlGUI.uploads_col_type = guiGridListAddColumn(mlGUI.uploads,"Mod Type",0.07)
        mlGUI.uploads_col_upid = guiGridListAddColumn(mlGUI.uploads,"Upload #",0.05)
        mlGUI.uploads_col_modelid = guiGridListAddColumn(mlGUI.uploads,"New ID",0.05)
        mlGUI.uploads_col_uptype = guiGridListAddColumn(mlGUI.uploads,"Upload Type",0.12)
        mlGUI.uploads_col_title = guiGridListAddColumn(mlGUI.uploads,"Name",0.36)
        mlGUI.uploads_col_update = guiGridListAddColumn(mlGUI.uploads,"Upload Date",0.12)
        mlGUI.uploads_col_status = guiGridListAddColumn(mlGUI.uploads,"Status",0.1)
        mlGUI.uploads_col_admin = guiGridListAddColumn(mlGUI.uploads,"Reviewed by",0.1)
        mlGUI.uploads_col_comment = guiGridListAddColumn(mlGUI.uploads,"Comment",0.2)
        mlGUI.uploads_col_revdate = guiGridListAddColumn(mlGUI.uploads,"Review Date",0.12)

        for modType, v in pairs(myUploads) do
            for k, upload in pairs(v) do


                local niceModType = exports["sarp-new-mods"]:formatModType(upload.modtype)
                local nicePurpose = exports["sarp-new-mods"]:formatModPurpose(tonumber(upload.purpose))

                local row = guiGridListAddRow(mlGUI.uploads)
                guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_type, niceModType, false, true)
                guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_upid, upload.upid, false, true)

                local status = upload.status

                if status == "Accepted" then
                    guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_modelid, upload.modelid, false, true)
                else
                    guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_modelid, "-", false, true)
                end

                guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_uptype, nicePurpose, false, false)
                guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_title, upload.title, false, false)
                guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_update, upload.uploadDate, false, false)


                guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_status, status, false, false)
                if status == "Pending" then
                    guiGridListSetItemColor(mlGUI.uploads, row, mlGUI.uploads_col_status, 255, 231, 122)
                elseif status == "Accepted" then
                    guiGridListSetItemColor(mlGUI.uploads, row, mlGUI.uploads_col_status, 105, 255, 107)
                elseif status == "Declined" then
                    guiGridListSetItemColor(mlGUI.uploads, row, mlGUI.uploads_col_status, 255, 38, 38)
                elseif status == "Cancelled" then
                    guiGridListSetItemColor(mlGUI.uploads, row, mlGUI.uploads_col_status, 187, 187, 187)
                end

                guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_admin, exports.cache:getUsernameFromId(tonumber(upload.revBy)) or upload.revBy, false, false)
                guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_comment, upload.comment or "-", false, false)
                guiGridListSetItemText(mlGUI.uploads, row, mlGUI.uploads_col_revdate, upload.revDate or "-", false, false)

            end
        end

            addEventHandler( "onClientGUIDoubleClick", mlGUI.uploads, clickMyUpload, false)

    end

    if allUploads then

        local exist2 = {}
        for mt, v in pairs(allUploads) do
            if #v > 0 then
                exist2[mt] = true
            end
        end

        local tabID = 5
        for mt1,_ in pairs(exist2) do

            local mt2 = mt1
            if mt2 == "ped" then mt2 = "skin" end
            local t_title = string.format("(Admin) %s Uploads", mt2:gsub("^%l", string.upper))

            local tab = guiCreateTab(t_title, mlGUI.tabs)
            setElementData(tab, "tabID", tabID)
            tabID = tabID + 1

            local grid = guiCreateGridList(0, 0, wW -20, wH-125, false, tab)
            mlGUI.auploads_col_type = guiGridListAddColumn(grid,"Mod Type",0.07)
            mlGUI.auploads_col_upid = guiGridListAddColumn(grid,"Upload #",0.05)
            mlGUI.auploads_col_upby = guiGridListAddColumn(grid,"Uploaded By",0.12)
            mlGUI.auploads_col_modelid = guiGridListAddColumn(grid,"New ID",0.05)
            mlGUI.auploads_col_uptype = guiGridListAddColumn(grid,"Upload Type",0.12)
            mlGUI.auploads_col_title = guiGridListAddColumn(grid,"Name",0.36)
            mlGUI.auploads_col_update = guiGridListAddColumn(grid,"Upload Date",0.12)
            mlGUI.auploads_col_status = guiGridListAddColumn(grid,"Status",0.1)
            mlGUI.auploads_col_admin = guiGridListAddColumn(grid,"Reviewed by",0.1)
            mlGUI.auploads_col_comment = guiGridListAddColumn(grid,"Comment",0.2)
            mlGUI.auploads_col_revdate = guiGridListAddColumn(grid,"Review Date",0.12)

            for modType, v in pairs(allUploads) do
                if modType == mt1 then
                    for k, upload in pairs(v) do


                        local niceModType = exports["sarp-new-mods"]:formatModType(upload.modtype)
                        local nicePurpose = exports["sarp-new-mods"]:formatModPurpose(tonumber(upload.purpose))

                        local row = guiGridListAddRow(grid)
                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_type, niceModType, false, true)
                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_upid, upload.upid, false, true)
                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_upby, (exports.cache:getUsernameFromId(tonumber(upload.uploadBy)) or upload.uploadBy), false, false)

                        local status = upload.status
                        if status == "Accepted" then
                            guiGridListSetItemText(grid, row, mlGUI.auploads_col_modelid, upload.modelid, false, true)
                        else
                            guiGridListSetItemText(grid, row, mlGUI.auploads_col_modelid, "-", false, true)
                        end
                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_uptype, nicePurpose, false, false)
                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_title, upload.title, false, false)
                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_update, upload.uploadDate, false, false)


                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_status, status, false, false)
                        if status == "Pending" then
                            guiGridListSetItemColor(grid, row, mlGUI.auploads_col_status, 255, 231, 122)
                        elseif status == "Accepted" then
                            guiGridListSetItemColor(grid, row, mlGUI.auploads_col_status, 105, 255, 107)
                        elseif status == "Declined" then
                            guiGridListSetItemColor(grid, row, mlGUI.auploads_col_status, 255, 38, 38)
                        elseif status == "Cancelled" then
                            guiGridListSetItemColor(grid, row, mlGUI.auploads_col_status, 187, 187, 187)
                        end

                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_admin, exports.cache:getUsernameFromId(tonumber(upload.revBy)) or upload.revBy, false, false)
                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_comment, upload.comment or "-", false, false)
                        guiGridListSetItemText(grid, row, mlGUI.auploads_col_revdate, upload.revDate or "-", false, false)

                    end
                end
            end
            
            addEventHandler( "onClientGUIDoubleClick", grid, clickAnUpload, false)
        end
    end

    if lastTab then
        local tabs = getElementChildren(mlGUI.tabs)
        for k, tab in pairs(tabs) do
            if isElement(tab) and getElementData(tab, "tabID") == lastTab then
                guiSetSelectedTab(mlGUI.tabs, tab)
                break
            end
        end
    end

    mlGUI.vehicles = guiCreateGridList(0, 0, wW -20, wH-125, false, mlGUI.vtab)
    mlGUI.vehicles_col_model = guiGridListAddColumn(mlGUI.vehicles,"Model ID",0.2)
    mlGUI.vehicles_col_name = guiGridListAddColumn(mlGUI.vehicles,"Vehicle Name",0.3)
    mlGUI.vehicles_col_dff = guiGridListAddColumn(mlGUI.vehicles,"DFF",0.2)
    mlGUI.vehicles_col_txd = guiGridListAddColumn(mlGUI.vehicles,"TXD",0.2)

    mlGUI.skins = guiCreateGridList(0, 0, wW -20, wH-125, false, mlGUI.stab)
    mlGUI.skins_col_model = guiGridListAddColumn(mlGUI.skins,"Model ID",0.2)
    mlGUI.skins_col_name = guiGridListAddColumn(mlGUI.skins,"Skin Name",0.3)
    mlGUI.skins_col_dff = guiGridListAddColumn(mlGUI.skins,"DFF",0.2)
    mlGUI.skins_col_txd = guiGridListAddColumn(mlGUI.skins,"TXD",0.2)

    mlGUI.weapons = guiCreateGridList(0, 0, wW -20, wH-125, false, mlGUI.wtab)
    mlGUI.weapons_col_model = guiGridListAddColumn(mlGUI.weapons,"Model ID",0.2)
    mlGUI.weapons_col_name = guiGridListAddColumn(mlGUI.weapons,"Weapon Name",0.3)
    mlGUI.weapons_col_dff = guiGridListAddColumn(mlGUI.weapons,"DFF",0.2)
    mlGUI.weapons_col_txd = guiGridListAddColumn(mlGUI.weapons,"TXD",0.2)

    local vcount = 0
    if loadedMods["vehicles"] then
        for model, stuff in pairs(loadedMods["vehicles"]) do

            local dff = stuff["dff"]
            local dffEnabled = "Yes"
            if dff and isElement(dff[3]) then
                if dff[2] == "disabled" then
                    dffEnabled = "Disabled"
                end
            else
                dffEnabled = "No"
            end
            local txd = stuff["txd"]
            local txdEnabled = "Yes"
            if txd and isElement(txd[3]) then
                if txd[2] == "disabled" then
                    txdEnabled = "Disabled"
                end
            else
                txdEnabled = "No"
            end

            local row = guiGridListAddRow(mlGUI.vehicles)
            guiGridListSetItemText(mlGUI.vehicles, row, mlGUI.vehicles_col_model, model, false, true)
            guiGridListSetItemText(mlGUI.vehicles, row, mlGUI.vehicles_col_name, getVehicleNameFromModel(model) or "Unknown", false, false)
            guiGridListSetItemText(mlGUI.vehicles, row, mlGUI.vehicles_col_dff, dffEnabled, false, false)
            guiGridListSetItemText(mlGUI.vehicles, row, mlGUI.vehicles_col_txd, txdEnabled, false, false)

            if dffEnabled == "Yes" then
                guiGridListSetItemColor(mlGUI.vehicles, row, 3, 0,255,0)
            elseif dffEnabled == "No" then
                guiGridListSetItemColor(mlGUI.vehicles, row, 3, 255,0,0)
            elseif dffEnabled == "Disabled" then
                guiGridListSetItemColor(mlGUI.vehicles, row, 3, 255,255,0)
            end
            if txdEnabled == "Yes" then
                guiGridListSetItemColor(mlGUI.vehicles, row, 4, 0,255,0)
            elseif txdEnabled == "No" then
                guiGridListSetItemColor(mlGUI.vehicles, row, 4, 255,0,0)
            elseif txdEnabled == "Disabled" then
                guiGridListSetItemColor(mlGUI.vehicles, row, 4, 255,255,0)
            end

            vcount = vcount + 1
        end
    end

    local scount = 0
    if loadedMods["skins"] then
        for model, stuff in pairs(loadedMods["skins"]) do

            local dff = stuff["dff"]
            local dffEnabled = "Yes"
            if dff and isElement(dff[3]) then
                if dff[2] == "disabled" then
                    dffEnabled = "Disabled"
                end
            else
                dffEnabled = "No"
            end
            local txd = stuff["txd"]
            local txdEnabled = "Yes"
            if txd and isElement(txd[3]) then
                if txd[2] == "disabled" then
                    txdEnabled = "Disabled"
                end
            else
                txdEnabled = "No"
            end

            local row = guiGridListAddRow(mlGUI.skins)
            guiGridListSetItemText(mlGUI.skins, row, mlGUI.skins_col_model, model, false, true)
            guiGridListSetItemText(mlGUI.skins, row, mlGUI.skins_col_name, stuff["dff"][1] or stuff["txd"][1] or "Unknown", false, false)
            guiGridListSetItemText(mlGUI.skins, row, mlGUI.skins_col_dff, dffEnabled, false, false)
            guiGridListSetItemText(mlGUI.skins, row, mlGUI.skins_col_txd, txdEnabled, false, false)

            if dffEnabled == "Yes" then
                guiGridListSetItemColor(mlGUI.skins, row, 3, 0,255,0)
            elseif dffEnabled == "No" then
                guiGridListSetItemColor(mlGUI.skins, row, 3, 255,0,0)
            elseif dffEnabled == "Disabled" then
                guiGridListSetItemColor(mlGUI.skins, row, 3, 255,255,0)
            end
            if txdEnabled == "Yes" then
                guiGridListSetItemColor(mlGUI.skins, row, 4, 0,255,0)
            elseif txdEnabled == "No" then
                guiGridListSetItemColor(mlGUI.skins, row, 4, 255,0,0)
            elseif txdEnabled == "Disabled" then
                guiGridListSetItemColor(mlGUI.skins, row, 4, 255,255,0)
            end

            scount = scount + 1
        end
    end


    local wcount = 0
    if loadedMods["weapons"] then
        for model, stuff in pairs(loadedMods["weapons"]) do

            local dff = stuff["dff"]
            local dffEnabled = "Yes"
            if dff and isElement(dff[3]) then
                if dff[2] == "disabled" then
                    dffEnabled = "Disabled"
                end
            else
                dffEnabled = "No"
            end
            local txd = stuff["txd"]
            local txdEnabled = "Yes"
            if txd and isElement(txd[3]) then
                if txd[2] == "disabled" then
                    txdEnabled = "Disabled"
                end
            else
                txdEnabled = "No"
            end

            local row = guiGridListAddRow(mlGUI.weapons)
            guiGridListSetItemText(mlGUI.weapons, row, mlGUI.weapons_col_model, model, false, true)
            guiGridListSetItemText(mlGUI.weapons, row, mlGUI.weapons_col_name, stuff["dff"][1] or stuff["txd"][1] or "Unknown", false, false)
            guiGridListSetItemText(mlGUI.weapons, row, mlGUI.weapons_col_dff, dffEnabled, false, false)
            guiGridListSetItemText(mlGUI.weapons, row, mlGUI.weapons_col_txd, txdEnabled, false, false)

            if dffEnabled == "Yes" then
                guiGridListSetItemColor(mlGUI.weapons, row, 3, 0,255,0)
            elseif dffEnabled == "No" then
                guiGridListSetItemColor(mlGUI.weapons, row, 3, 255,0,0)
            elseif dffEnabled == "Disabled" then
                guiGridListSetItemColor(mlGUI.weapons, row, 3, 255,255,0)
            end
            if txdEnabled == "Yes" then
                guiGridListSetItemColor(mlGUI.weapons, row, 4, 0,255,0)
            elseif txdEnabled == "No" then
                guiGridListSetItemColor(mlGUI.weapons, row, 4, 255,0,0)
            elseif txdEnabled == "Disabled" then
                guiGridListSetItemColor(mlGUI.weapons, row, 4, 255,255,0)
            end

            wcount = wcount + 1
        end
    end

    addEventHandler( "onClientGUIClick", mlGUI.window,
    function (button, state, absoluteX, absoluteY)

        local selTab = guiGetSelectedTab(mlGUI.tabs)
        lastTab = getElementData(selTab, "tabID") or nil

    end)

    addEventHandler( "onClientGUIDoubleClick", mlGUI.vehicles,
        function( button )
            if button == "left" then
                local row, col = guiGridListGetSelectedItem(mlGUI.vehicles)
                if row ~= -1 and col ~= -1 then
                    local model = tostring(guiGridListGetItemText(mlGUI.vehicles, row, 1))
                    local name = tostring(guiGridListGetItemText(mlGUI.vehicles, row, 2))
                    local dff = tostring(guiGridListGetItemText(mlGUI.vehicles, row, 3))
                    local txd = tostring(guiGridListGetItemText(mlGUI.vehicles, row, 4))
                    showEditMod("Vehicle", model, name, dff, txd)
                end
            end
        end,
    false)

    addEventHandler( "onClientGUIDoubleClick", mlGUI.skins,
        function( button )
            if button == "left" then
                local row, col = guiGridListGetSelectedItem(mlGUI.skins)
                if row ~= -1 and col ~= -1 then
                    local model = tostring(guiGridListGetItemText(mlGUI.skins, row, 1))
                    local name = tostring(guiGridListGetItemText(mlGUI.skins, row, 2))
                    local dff = tostring(guiGridListGetItemText(mlGUI.skins, row, 3))
                    local txd = tostring(guiGridListGetItemText(mlGUI.skins, row, 4))
                    showEditMod("Skin", model, name, dff, txd)
                end
            end
        end,
    false)

    addEventHandler( "onClientGUIDoubleClick", mlGUI.weapons,
        function( button )
            if button == "left" then
                local row, col = guiGridListGetSelectedItem(mlGUI.weapons)
                if row ~= -1 and col ~= -1 then
                    local model = tostring(guiGridListGetItemText(mlGUI.weapons, row, 1))
                    local name = tostring(guiGridListGetItemText(mlGUI.weapons, row, 2))
                    local dff = tostring(guiGridListGetItemText(mlGUI.weapons, row, 3))
                    local txd = tostring(guiGridListGetItemText(mlGUI.weapons, row, 4))
                    showEditMod("Weapon", model, name, dff, txd)
                end
            end
        end,
    false)

end
addEvent("modloader:openGUI", true)
addEventHandler("modloader:openGUI", root, openMLGUI)


function refreshML()
    guiSetText(mlGUI.info, "Reloading server mods then scanning for new mod-loader mods and loading those enabled...")
    guiLabelSetColor(mlGUI.info, 0,255,0)

    local result, msg = doRefreshMods()
    if result then
        guiSetEnabled(mlGUI.window, false)
    else
        guiSetText(mlGUI.info, msg)
        guiLabelSetColor(mlGUI.info, 255,0,0)
    end
end

function showEditMod(modType, model, name, dff, txd)
    guiSetEnabled(mlGUI.window, false)

    local emW, emH = 300, 180

    mlGUI.emwindow = guiCreateWindow((sX - emW)/2, (sY - emH)/2, emW, emH, "Edit "..modType.." Mod: "..name.." ("..model..")", false)
    guiWindowSetSizable(mlGUI.emwindow,false)

    mlGUI.bEmclose = guiCreateButton(0, emH-40, emW -5, 35, "Close", false, mlGUI.emwindow)
    addEventHandler("onClientGUIClick", mlGUI.bEmclose, closeEditMod, false)

    mlGUI.dffC = guiCreateCheckBox(5, 35, emW - 10, 20, "Replace DFF", false, false, mlGUI.emwindow)
    mlGUI.txdC = guiCreateCheckBox(5, 35 + 30, emW - 10, 20, "Replace TXD", false, false, mlGUI.emwindow)

    if dff == "Yes" then
        guiCheckBoxSetSelected(mlGUI.dffC, true)
    elseif dff == "No" then
        guiSetEnabled(mlGUI.dffC, false)
        guiSetText(mlGUI.dffC, guiGetText(mlGUI.dffC).." (Not found)")
    elseif dff == "Disabled" then
        guiCheckBoxSetSelected(mlGUI.dffC, false)
    end
    if txd == "Yes" then
        guiCheckBoxSetSelected(mlGUI.txdC, true)
    elseif txd == "No" then
        guiSetEnabled(mlGUI.txdC, false)
        guiSetText(mlGUI.txdC, guiGetText(mlGUI.txdC).." (Not found)")
    elseif txd == "Disabled" then
        guiCheckBoxSetSelected(mlGUI.txdC, false)
    end

    mlGUI.bEmsave = guiCreateButton(0, emH-80, emW -5, 35, "Save", false, mlGUI.emwindow)
    addEventHandler("onClientGUIClick", mlGUI.bEmsave, function()

        local dff_ = dff
        if guiGetEnabled(mlGUI.dffC) then
            if guiCheckBoxGetSelected(mlGUI.dffC) then
                dff_ = "enabled"
            else
                dff_ = "disabled"
            end
        else
            dff_ = false
        end
        local txd_ = txd
        if guiGetEnabled(mlGUI.txdC) then
            if guiCheckBoxGetSelected(mlGUI.txdC) then
                txd_ = "enabled"
            else
                txd_ = "disabled"
            end
        else
            txd_ = false
        end

        saveEditMod(modType, model, name, dff_, txd_)
    end, false)
end

function saveEditMod(modType, model, name, dff, txd)
    if modType == "Vehicle" then
        if loadedMods["vehicles"] then
            if loadedMods["vehicles"][tostring(model)] then
                if dff then
                    setSetting("dff"..tostring(model), tostring(dff))
                    loadedMods["vehicles"][tostring(model)]["dff"][2] = tostring(dff)
                    writeModLog("[editmod] [veh] "..getVehicleNameFromModel(tonumber(model)).." ("..model.."): set DFF to "..dff)
                else
                    loadedMods["vehicles"][tostring(model)]["dff"] = nil
                end
                if txd then
                    setSetting("txd"..tostring(model), tostring(txd))
                    loadedMods["vehicles"][tostring(model)]["txd"][2] = tostring(txd)
                    writeModLog("[editmod] [veh] "..getVehicleNameFromModel(tonumber(model)).." ("..model.."): set TXD to "..txd)
                else
                    loadedMods["vehicles"][tostring(model)]["txd"] = nil
                end
            end
        end

        outputChatBox("Saved vehicle mod: "..name.." ("..model.."). Reload mods to apply changes.",0,255,0)

    elseif modType == "Skin" then
        if loadedMods["skins"] then
            if loadedMods["skins"][tostring(model)] then
                if dff then
                    setSetting("dff"..tostring(model), tostring(dff))
                    loadedMods["skins"][tostring(model)]["dff"][2] = tostring(dff)
                    writeModLog("[editmod] [skin] "..name.." ("..model.."): set DFF to "..dff)
                else
                    loadedMods["skins"][tostring(model)]["dff"] = nil
                end
                if txd then
                    setSetting("txd"..tostring(model), tostring(txd))
                    loadedMods["skins"][tostring(model)]["txd"][2] = tostring(txd)
                    writeModLog("[editmod] [skin] "..name.." ("..model.."): set TXD to "..txd)
                else
                    loadedMods["skins"][tostring(model)]["txd"] = nil
                end
            end
        end

        outputChatBox("Saved skin mod: "..name.." ("..model.."). Reload mods to apply changes.",0,255,0)

    elseif modType == "Weapon" then
        if loadedMods["weapons"] then
            if loadedMods["weapons"][tostring(model)] then
                if dff then
                    setSetting("dff"..tostring(model), tostring(dff))
                    loadedMods["weapons"][tostring(model)]["dff"][2] = tostring(dff)
                    writeModLog("[editmod] [weapon] "..name.." ("..model.."): set DFF to "..dff)
                else
                    loadedMods["weapons"][tostring(model)]["dff"] = nil
                end
                if txd then
                    setSetting("txd"..tostring(model), tostring(txd))
                    loadedMods["weapons"][tostring(model)]["txd"][2] = tostring(txd)
                    writeModLog("[editmod] [weapon] "..name.." ("..model.."): set TXD to "..txd)
                else
                    loadedMods["weapons"][tostring(model)]["txd"] = nil
                end
            end
        end

        outputChatBox("Saved weapon mod: "..name.." ("..model.."). Reload mods to apply changes.",0,255,0)
    end

    destroyElement(mlGUI.emwindow)
    openMLGUI()
    if modType=="Weapon" then
        guiSetText(mlGUI.info, "Your weapon model might become invisible after reloading! Drop and pick your gun back up or reconnect.")
        guiLabelSetColor(mlGUI.info, 255,255,0)
    end
end

function closeEditMod()
    if isElement(mlGUI.emwindow) then
        destroyElement(mlGUI.emwindow)
        guiSetEnabled(mlGUI.window, true)
    end
end

function helpML()

    local hw,hh = wW/2, wH/3

    mlGUI.helpW = guiCreateWindow((sX - hw)/2, (sY - hh)/2, hw, hh, "Mod Loader - Help", false)
    guiWindowSetSizable(mlGUI.helpW, false)
    guiWindowSetMovable(mlGUI.helpW, false)


    mlGUI.helpMods = guiCreateButton(5, hh-35-40*3-5, hw -10, 35, "I want to try some mods on my game", false, mlGUI.helpW)
    addEventHandler("onClientGUIClick", mlGUI.helpMods, function()

        -- set the other one visible
        if isElement(mlGUI.helpUploadsURL) then
            destroyElement(mlGUI.helpUploadsURL)
            guiSetVisible(mlGUI.helpUploads, true)
        end

        local x,y = guiGetPosition(source, false)
        local x_,y_ = guiGetSize(source, false)
        guiSetVisible(source, false)
        local text = tutURL
        mlGUI.helpModsURL = guiCreateEdit(x,y, x_,y_, text, false, mlGUI.helpW)
        triggerEvent("displayMesaage", localPlayer, helpMsg, "info")
        setClipboard(text)
    end, false)
    guiSetProperty(mlGUI.helpMods , "NormalTextColour", "ffa8ff69")


    mlGUI.helpUploads = guiCreateButton(5, hh-25-40*2-5, hw -10, 35, "I want to submit mods for everyone to see", false, mlGUI.helpW)
    addEventHandler("onClientGUIClick", mlGUI.helpUploads, function()

        -- set the other one visible
        if isElement(mlGUI.helpModsURL) then
            destroyElement(mlGUI.helpModsURL)
            guiSetVisible(mlGUI.helpMods, true)
        end

        local x,y = guiGetPosition(source, false)
        local x_,y_ = guiGetSize(source, false)
        guiSetVisible(source, false)
        local text = uploadTutURL
        mlGUI.helpUploadsURL = guiCreateEdit(x,y, x_,y_, text, false, mlGUI.helpW)
        triggerEvent("displayMesaage", localPlayer, uploadHelpMsg, "info")
        setClipboard(text)
    end, false)
    guiSetProperty(mlGUI.helpUploads , "NormalTextColour", "ff69ffe9")


    mlGUI.helpClose = guiCreateButton(5, hh-40, hw -10, 35, "Close", false, mlGUI.helpW)
    addEventHandler("onClientGUIClick", mlGUI.helpClose, function()
        closeHelpML()
        openMLGUI()
    end, false)
end

function closeHelpML()
    if isElement(mlGUI.helpW) then
        destroyElement(mlGUI.helpW)
    end
end

function closeMLGUI()

    if isElement(mlGUI.window) then
        destroyElement(mlGUI.window)
        mlGUI = {}
    end
    if isElement(bb) then
        exports.blur_box:destroyBlurBox(bb)
        -- showChat(true)
    end

    triggerEvent("f_toggleCursor", localPlayer, false)
    guiSetInputMode("allow_binds")
    setElementData(localPlayer, "exclusiveGUI", nil)
end

--

function viewUploadMsg(success, msg)

    if isElement(mlGUI.clickUplPopup) then destroyElement(mlGUI.clickUplPopup) end
    if isElement(mlGUI.viewUpload) then destroyElement(mlGUI.viewUpload) end

    local upmW, upmH = wW/3, 150

    mlGUI.viewPopup = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, (success and "Information" or "Error"), false)
    guiWindowSetSizable(mlGUI.viewPopup,false)

    mlGUI.viewPopupL = guiCreateLabel(6, 40, upmW - 6*2, upmH/1.5, msg, false, mlGUI.viewPopup)
    guiLabelSetHorizontalAlign(mlGUI.viewPopupL, "center", true)


    mlGUI.viewPopupClose = guiCreateButton(5, upmH-40, upmW -10, 35, "Close", false, mlGUI.viewPopup)
    addEventHandler("onClientGUIClick", mlGUI.viewPopupClose, function()
        destroyElement(mlGUI.viewPopup)

        closeMLGUI()
        executeCommandHandler("modloader", "bypass")

    end, false)

end
addEvent("modloader:viewUploadMsg", true)
addEventHandler("modloader:viewUploadMsg", root, viewUploadMsg)


local drawing = false
local modImage, thingID, reqCancelled
local drawx, drawy

function setDrawingModImage(on, thingID_, cancelled)

    if on and not drawing and tonumber(thingID_) and drawx and drawy then
        drawing = true
        thingID = thingID_
        reqCancelled = cancelled or false
        addEventHandler( "onClientRender", root, drawModImage)
        -- outputDebugString("drawing: yes")
    else
        removeEventHandler( "onClientRender", root, drawModImage)
        drawing = false
        modImage = nil
        modelid = nil
        reqCancelled = nil
        -- outputDebugString("drawing: no")
    end
end

function drawModImage()

    if drawing and thingID then

        if not reqCancelled and not modImage then
            modImage = exports["sarp-new-mods"]:getImage(tonumber(thingID))
        end
        local size = 180
        dxDrawRectangle(drawx, drawy, size, size, tocolor(255,255,255,180), true)

        if not reqCancelled and modImage and isElement(modImage.tex) then

            dxDrawImage(drawx, drawy, size, size, modImage.tex, 0, 0, 0, tocolor(255,255,255,255), true)
        else
            local text = "Loading image..."
            if reqCancelled then
                text = "Image Deleted"
            end
            local length = dxGetTextWidth(text, 1, "default-bold-small")
            local x,y = drawx + size/2 -length/2, drawy + size/2 -10
            dxDrawText(text, x,y, x,y, tocolor(0,0,0,255), 1, "default-bold-small", "left", "top", false, false, true)
        end
    end
end


function viewUpload(mt, upload)

    if isElement(mlGUI.clickUplPopup) then destroyElement(mlGUI.clickUplPopup) end
    guiSetEnabled(mlGUI.window, true)
    guiSetVisible(mlGUI.window, false)

    local upmW, upmH = wW, wH/1.2

    local title = mt.." Mod Upload ID #"..upload.upid

    local windowX, windowY = (sX - upmW)/2, (sY - upmH)/2

    mlGUI.viewUpload = guiCreateWindow(windowX, windowY, upmW, upmH, title, false)
    guiWindowSetSizable(mlGUI.viewUpload, false)
    guiWindowSetMovable(mlGUI.viewUpload, false)


    local status = upload.status
    local purpose = tonumber(upload.purpose)

    local subtitle = ""
    local extra1 = ""
    if purpose > 0 then
        extra1 = "If you paid for this submission you will be refunded the full price. "
    end

    if status == "Pending" then
        subtitle = "You can cancel this mod request by clicking the button below. "..extra1
        subtitle = subtitle.."Please don't contact admins/mod reviewers about your request. It will be handled in due time."
    end

    mlGUI.viewUploadL1 = guiCreateLabel(10, 30, upmW - 10*2, 55, subtitle, false, mlGUI.viewUpload)
    guiLabelSetHorizontalAlign(mlGUI.viewUploadL1, "center", true)


    local ySpace = 65
    local curY = 75
    local startX = 20
    local curX = startX
    local cur = 0
    mlGUI.viewShits = {}

    if status == "Accepted" then

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "Uploaded mod file name", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/4 - startX*2, 30, upload.name, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)

        curX = upmW/4

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "Upload Date", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/4 - startX*1, 30, upload.uploadDate, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)


        curX = upmW/2
        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX, 20, "New unique model ID", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/4 - startX * 1, 30, upload.modelid, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)

        drawx, drawy = curX+(upmW/4 - startX * 1)+30, curY
        drawx = windowX+drawx
        drawy = windowY+drawy

    else
        local divide = 2.6

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "Uploaded mod file name", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/divide - startX*2, 30, upload.name, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)

        curX = upmW/divide

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "Upload Date", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/divide - startX*2, 30, upload.uploadDate, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)

        drawx, drawy = curX+(upmW/divide - startX)+20, curY
        drawx = windowX+drawx
        drawy = windowY+drawy
    end


    curX = startX
    curY = curY + ySpace

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "Mod Author(s)", false, mlGUI.viewUpload)
    guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/2 - startX*2, 30, upload.author, false, mlGUI.viewUpload)
    guiSetEnabled(mlGUI.viewShits[cur], false)


    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateLabel(upmW/2, curY, upmW/2 - startX*2, 20, "Model Info", false, mlGUI.viewUpload)
    guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

    local modelInfo = ""

    local dffSize = tonumber((upload.dffSize or 0))
    dffSize = math.ceil(dffSize/1000) --kb
    local txdSize = tonumber((upload.txdSize or 0))
    txdSize = math.ceil(txdSize/1000) --kb

    modelInfo = "DFF: "..dffSize.." KB, TXD: "..txdSize.." KB"

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateEdit(upmW/2-6, curY+20, upmW/4 - startX, 30, modelInfo, false, mlGUI.viewUpload)
    guiSetEnabled(mlGUI.viewShits[cur], false)


    curY = curY + ySpace

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW - startX*2, 20, "Name (short description/title)", false, mlGUI.viewUpload)
    guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/4 * 3 - startX*2, 30, upload.title, false, mlGUI.viewUpload)
    guiSetEnabled(mlGUI.viewShits[cur], false)

    curY = curY + ySpace

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW - startX*2, 20, "Detailed Description", false, mlGUI.viewUpload)
    guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateMemo(curX-6, curY+20, upmW - startX*2, 30*3, upload.desc, false, mlGUI.viewUpload)
    guiSetEnabled(mlGUI.viewShits[cur], false)

    curY = curY + ySpace + 30*2

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW - startX*2, 20, "Availability", false, mlGUI.viewUpload)
    guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

    local availability = tonumber(upload.purpose)
    if availability < 0 then
        availability = "Faction - "..exports["faction-system"]:getFactionName(math.abs(availability)).." (#"..math.abs(availability)..")"
    elseif availability == 0 then
        availability = "Global - Distributed to all clothing stores"
    elseif availability == 1 then
        availability = "Personal - Only obtainable by mod uploader"
    elseif availability == 2 then
        availability = "Special - Reserved for server/script use only"
    end


    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW - startX*2, 30, availability, false, mlGUI.viewUpload)
    guiSetEnabled(mlGUI.viewShits[cur], false)

    if status == "Pending" or status == "Declined" or status == "Accepted" then

        if status ~= "Pending" then
            mlGUI.viewUploadDelete = guiCreateButton(5, upmH-40*2-2, upmW -10, 35, status=="Accepted" and "Delete Mod" or "Cancel Request", false, mlGUI.viewUpload)
        else
            mlGUI.viewUploadDelete = guiCreateButton(5 + (upmW/2), upmH-40*2-2, upmW -10, 35, status=="Accepted" and "Delete Mod" or "Cancel Request", false, mlGUI.viewUpload)

            mlGUI.viewUploadPreview = guiCreateButton(5, upmH-40*2-2, (upmW/2) -10, 35, "Preview Mod", false, mlGUI.viewUpload)
            guiSetProperty(mlGUI.viewUploadPreview , "NormalTextColour", "ffffb0f6")

            -- 
            addEventHandler("onClientGUIClick", mlGUI.viewUploadPreview, function()
             
                destroyElement(mlGUI.viewUpload)
                setDrawingModImage(false)
                closeMLGUI()

                local img = ((status=="Accepted" and upload.modelid) or (- (tonumber(upload.upid))))
                setPreviewingMod(true, mt, tonumber(upload.upid), img, true)

            end, false)
            guiSetProperty(mlGUI.viewUploadDelete , "NormalTextColour", "ffffff00")
        end
        
        addEventHandler("onClientGUIClick", mlGUI.viewUploadDelete, function()
            
            if (status == "Accepted") and tonumber(upload.purpose) == 0 and not exports["sarp-new-mods"]:isModReviewer(localPlayer) then
                triggerEvent("displayMesaage", localPlayer, "Only staff can disable public mods.", "error")
                return
            end

            guiSetEnabled(mlGUI.viewUpload, false)
            setDrawingModImage(false)
            
            triggerServerEvent("newmods:deleteUpload", localPlayer, mt, upload.upid, true)

        end, false)
        guiSetProperty(mlGUI.viewUploadDelete , "NormalTextColour", "ffffff00")


    end


    mlGUI.viewUploadClose = guiCreateButton(5, upmH-40, upmW -10, 35, "Close", false, mlGUI.viewUpload)
    addEventHandler("onClientGUIClick", mlGUI.viewUploadClose, function()
        closeViewMod()
    end, false)

    setDrawingModImage(true, ((status=="Accepted" and upload.modelid) or (- (tonumber(upload.upid)))), status=="Cancelled")
end
addEvent("modloader:viewUpload", true)
addEventHandler("modloader:viewUpload", root, viewUpload)


function closeViewMod()
    destroyElement(mlGUI.viewUpload)
    setDrawingModImage(false)

    closeMLGUI()
    executeCommandHandler("modloader", "bypass")
end

function viewUploadAdmin(mt, upload)

    if isElement(mlGUI.clickUplPopup) then destroyElement(mlGUI.clickUplPopup) end
    guiSetEnabled(mlGUI.window, true)
    guiSetVisible(mlGUI.window, false)

    local upmW, upmH = wW, wH

    local title = mt.." Mod Upload ID #"..upload.upid

    local windowX, windowY = (sX - upmW)/2, (sY - upmH)/2

    mlGUI.viewUpload = guiCreateWindow(windowX, windowY, upmW, upmH, title, false)
    guiWindowSetSizable(mlGUI.viewUpload, false)
    guiWindowSetMovable(mlGUI.viewUpload, false)


    local status = upload.status
    local purpose = tonumber(upload.purpose)

    local subtitle = "You are viewing this mod upload request with admin privileges. From this window you can modify (edit text, change preview image), preview the mod itself and change its status (accept & implement / decline)."

    mlGUI.viewUploadL1 = guiCreateLabel(10, 30, upmW - 10*2, 55, subtitle, false, mlGUI.viewUpload)
    guiLabelSetHorizontalAlign(mlGUI.viewUploadL1, "left", true)

    local niceStatus = ""
    local niceReviewer = ""
    local sR, sG, sB = 255,255,255
    if status == "Accepted" then
        niceStatus = "Status: Accepted & Implemented"
        niceReviewer = "Reviewed by: "..(exports.cache:getUsernameFromId(tonumber(upload.revBy)) or upload.revBy).." - "..upload.revDate
        sR, sG, sB = 0,255,0
    elseif status == "Declined" then
        niceStatus = "Status: Declined"
        niceReviewer = "Reviewed by: "..(exports.cache:getUsernameFromId(tonumber(upload.revBy)) or upload.revBy).." - "..upload.revDate
        sR, sG, sB = 255,0,0
    elseif status == "Cancelled" then--OLD
        niceStatus = "Status: Cancelled by Uploader"
        sR, sG, sB = 200,200,200
    elseif status == "Pending" then
        niceStatus = "Status: Pending Review"
        sR, sG, sB = 255,194,0
    end

    local titleFont1 = guiCreateFont(":resources/TitleFont.ttf", 14)
    mlGUI.viewUploadL2 = guiCreateLabel(10, 68, upmW - 10*2, 30, niceStatus, false, mlGUI.viewUpload)
    guiSetFont(mlGUI.viewUploadL2, titleFont1)
    guiLabelSetColor(mlGUI.viewUploadL2, sR, sG, sB)

    if niceReviewer ~= "" then

        local titleFont2 = guiCreateFont(":resources/TitleFont.ttf", 12)
        mlGUI.viewUploadL3 = guiCreateLabel(20, 68, upmW - 20*2, 30, niceReviewer, false, mlGUI.viewUpload)
        guiLabelSetHorizontalAlign(mlGUI.viewUploadL3, "right")
        guiSetFont(mlGUI.viewUploadL3, titleFont2)
        guiLabelSetColor(mlGUI.viewUploadL3, 255, 255, 255)
    end

    -- used to then easily grab the elements because they are created with IDs below for ease
    local guiElements = {}

    local ySpace = 60
    local curY = 95
    local startX = 20
    local curX = startX
    local cur = 0
    mlGUI.viewShits = {}


    if status == "Accepted" then

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "Upload Date", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/4 - startX*2, 30, upload.uploadDate, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)

        curX = upmW/4

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "Uploaded By", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/4 - startX*1, 30, (exports.cache:getUsernameFromId(tonumber(upload.uploadBy)) or upload.uploadBy), false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)


        curX = upmW/2
        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX, 20, "New unique model ID", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/4 - startX * 1, 30, upload.modelid, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)

        drawx, drawy = curX+(upmW/4 - startX * 1)+30, curY
        drawx = windowX+drawx
        drawy = windowY+drawy

    else
        local divide = 2.6

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "Upload Date", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/divide - startX*2, 30, upload.uploadDate, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)

        curX = upmW/divide

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "Uploaded By", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/divide - startX*2, 30, (exports.cache:getUsernameFromId(tonumber(upload.uploadBy)) or upload.uploadBy), false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)

        drawx, drawy = curX+(upmW/divide - startX)+20, curY
        drawx = windowX+drawx
        drawy = windowY+drawy

    end

    curX = startX

    curY = curY + ySpace

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "[EDITABLE] Mod Author(s)", false, mlGUI.viewUpload)
    guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/2 - startX*2, 30, upload.author, false, mlGUI.viewUpload)
    guiElements["author"] = mlGUI.viewShits[cur]
    guiEditSetMaxLength(mlGUI.viewShits[cur], 75)


    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateLabel(upmW/2, curY, upmW/2 - startX*2, 20, "Model Info", false, mlGUI.viewUpload)
    guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

    local modelInfo = ""

    local dffSize = tonumber((upload.dffSize or 0))
    dffSize = math.ceil(dffSize/1000) --kb
    local txdSize = tonumber((upload.txdSize or 0))
    txdSize = math.ceil(txdSize/1000) --kb

    modelInfo = "DFF: "..dffSize.." KB, TXD: "..txdSize.." KB"

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateEdit(upmW/2-6, curY+20, upmW/4 - startX, 30, modelInfo, false, mlGUI.viewUpload)
    guiSetEnabled(mlGUI.viewShits[cur], false)


    curY = curY + ySpace

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW - startX*2, 20, "[EDITABLE] Name (short description/title)", false, mlGUI.viewUpload)
    guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

    cur = cur +1
    mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/4 * 3 - startX*2, 30, upload.title, false, mlGUI.viewUpload)
    guiElements["title"] = mlGUI.viewShits[cur]
    guiEditSetMaxLength(mlGUI.viewShits[cur], 75)

    curY = curY + ySpace

    if status == "Accepted" or status == "Declined" then

        local comment = upload.comment or ""

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*1, 20, "[EDITABLE] Detailed Description", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateMemo(curX-6, curY+20, upmW/2 - startX*1, 30*3, upload.desc, false, mlGUI.viewUpload)
        guiElements["desc"] = mlGUI.viewShits[cur]
        guiSetProperty(mlGUI.viewShits[cur], "MaxTextLength", "500" )

        curX = upmW/2 + startX

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/2 - startX*2, 20, "[EDITABLE] Review Comment", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")
        guiLabelSetColor(mlGUI.viewShits[cur], 71, 252, 255)


        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateMemo(curX-6, curY+20, upmW/2 - startX*2, 30*3, comment, false, mlGUI.viewUpload)
        guiElements["comment"] = mlGUI.viewShits[cur]

        curX = startX

    else

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW - startX*2, 20, "[EDITABLE] Detailed Description", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateMemo(curX-6, curY+20, upmW - startX*2, 30*3, upload.desc, false, mlGUI.viewUpload)
        guiElements["desc"] = mlGUI.viewShits[cur]
    end

    curY = curY + ySpace + 30*2

    local availability = tonumber(upload.purpose)

    local avText = ""

    if availability < 0 then
        avText = "Faction - "..exports["faction-system"]:getFactionName(math.abs(availability)).." (#"..math.abs(availability)..")"
    elseif availability == 0 then
        avText = "Global - Distributed to all clothing stores"
    elseif availability == 1 then
        avText = "Personal - Only obtainable by mod uploader"
    elseif availability == 2 then
        avText = "Special - Reserved for server/script use only"
    end

    if availability ~= 0 and exports["sarp-new-mods"]:isModFullPerm(localPlayer) then

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW - startX*2, 20, "Availability -> Click the button to distribute this mod to all clothing stores", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")


        cur = cur +1
        local divide3 = 1.25

        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/divide3, 30, avText, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)

        cur = cur +1
        local makeGlobal= "Make Global"
        local bwidth = 150

        mlGUI.viewShits[cur] = guiCreateButton(upmW - bwidth - 5, curY+20, bwidth, 30, makeGlobal, false, mlGUI.viewUpload)
        guiElements["makeGlobal"] = mlGUI.viewShits[cur]
        guiSetProperty(mlGUI.viewShits[cur] , "NormalTextColour", "ffffff00")

        addEventHandler("onClientGUIClick", guiElements["makeGlobal"], function()


            guiSetEnabled(mlGUI.viewUpload, false)
            triggerServerEvent("newmods:makeModGlobal", localPlayer, mt, upload.upid)


        end, false)

    elseif availability == 0 then

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, (upmW/4) - startX*2, 20, "Availability:", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")


        cur = cur +1
        local divide3 = 1.25
        local divide32 = 2
        local divide322 = 2

        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/divide3/divide32, 30, avText, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)
        cur = cur +1



        mlGUI.viewShits[cur] = guiCreateLabel(curX + (upmW/divide3/divide32), curY, upmW/divide3/divide32/2, 20, "Gender (0: male, 1: female)", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")
        cur = cur +1

        mlGUI.viewShits[cur] = guiCreateEdit(curX-6 + upmW/divide3/divide32, curY+20, upmW/divide3/divide32/2, 30, upload.gender or 0, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], true)
        local tw = guiGetSize(mlGUI.viewShits[cur], false)
        guiElements["gender"] = mlGUI.viewShits[cur]
        cur = cur +1
        

        mlGUI.viewShits[cur] = guiCreateLabel(curX + (upmW/divide3/divide32) + tw, curY, upmW/divide3/divide32/2, 20, "Race (0: black, 1: white, 2: asian)", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")
        cur = cur +1

        mlGUI.viewShits[cur] = guiCreateEdit(curX-6 + upmW/divide3/divide32 + tw, curY+20, upmW/divide3/divide32/2, 30, upload.race or 1, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], true)
        guiElements["race"] = mlGUI.viewShits[cur]
        cur = cur +1


        local makeGlobal= "Make Personal"
        local bwidth = 150

        mlGUI.viewShits[cur] = guiCreateButton(upmW - bwidth - 5, curY+20, bwidth, 30, makeGlobal, false, mlGUI.viewUpload)
        guiElements["makeGlobal"] = mlGUI.viewShits[cur]
        guiSetProperty(mlGUI.viewShits[cur] , "NormalTextColour", "ffffff00")

        addEventHandler("onClientGUIClick", guiElements["makeGlobal"], function()


            guiSetEnabled(mlGUI.viewUpload, false)
            triggerServerEvent("newmods:makeModGlobal", localPlayer, mt, upload.upid, true)


        end, false)

    else


        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW - startX*2, 20, "Availability", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW - startX*2, 30, avText, false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.viewShits[cur], false)
    end


    if status == "Cancelled" then

        mlGUI.ph = guiCreateButton(5, upmH-40*2-1, upmW -10, 35, "Request was cancelled by uploader", false, mlGUI.viewUpload)
        guiSetEnabled(mlGUI.ph , false)

        -- if exports["sarp-new-mods"]:isModFullPerm(localPlayer) then
            -- can delete request

            mlGUI.delete = guiCreateButton(5, (upmH-40*3-1), (upmW - 5*2), 35, "Permanently Delete", false, mlGUI.viewUpload)
            addEventHandler("onClientGUIClick", mlGUI.delete, function()
                guiSetEnabled(mlGUI.viewUpload, false)
                setDrawingModImage(false)

                triggerServerEvent("newmods:deleteUpload", localPlayer, mt, upload.upid)
            end, false)
            guiSetProperty(mlGUI.delete , "NormalTextColour", "ffff0000")
        -- end
    else

        curY = curY + ySpace
        local divide2 = 1.25
        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateLabel(curX, curY, upmW/divide2, 20, "Preview Image -> Enter a new URL if you wish to change it", false, mlGUI.viewUpload)
        guiSetFont(mlGUI.viewShits[cur], "default-bold-small")

        cur = cur +1
        mlGUI.viewShits[cur] = guiCreateEdit(curX-6, curY+20, upmW/divide2, 30, "", false, mlGUI.viewUpload)
        guiElements["image"] = mlGUI.viewShits[cur]

        cur = cur +1
        local validateImg = "Validate URL"
        local bwidth = 150

        mlGUI.viewShits[cur] = guiCreateButton(upmW - bwidth - 5, curY+20, bwidth, 30, validateImg, false, mlGUI.viewUpload)
        guiElements["upImage"] = mlGUI.viewShits[cur]


        addEventHandler("onClientGUIClick", guiElements["upImage"], function()

            -- update preview image

            local btext = guiGetText(source)
            local newURL = guiGetText(guiElements["image"])
            if btext == validateImg then


                if newURL == "" then
                    return triggerEvent("displayMesaage", localPlayer, "You need to enter a new image URL (from imgur.com for example) to update it.", "error")
                end
                
                local foundillegal2 = urlHasIllegalCharacters(newURL)
                if foundillegal2 then
                    local msg = "Illegal characters found in image URL. An URL looks like this: https://i.imgur.com/x8w8pXe.png"
                    return triggerEvent("displayMesaage", localPlayer, msg, "error")
                end

                if not (string.find(newURL, "http://", 1, true) or string.find(newURL, "https://", 1, true)) then
                    local msg = "Image URL is invalid. An URL looks like this: https://i.imgur.com/x8w8pXe.png"
                    return triggerEvent("displayMesaage", localPlayer, msg, "error")
                end

                guiSetText(source, "Update Image")
                guiSetProperty(source , "NormalTextColour", "ff00ff00")
                triggerEvent("displayMesaage", localPlayer, "Preview image URL is valid. You can now update it.", "success")
            else

                guiSetEnabled(mlGUI.viewUpload, false)
                triggerServerEvent("newmods:fetchImageFromURL", localPlayer, ((status=="Accepted" and upload.modelid) or (- (tonumber(upload.upid)))), newURL, "staffUpload")
            end

        end, false)


        local upText = "Update Editable Details"
        mlGUI.vUUpDetails = guiCreateButton(5, upmH-40*3-1, upmW -10, 35, upText, false, mlGUI.viewUpload)
        guiSetProperty(mlGUI.vUUpDetails , "NormalTextColour", "ffffffff")
        addEventHandler("onClientGUIClick", mlGUI.vUUpDetails, function()

            local author = guiGetText(guiElements["author"])
            local title = guiGetText(guiElements["title"])
            local desc = guiGetText(guiElements["desc"])

            local gender,race
            if isElement(guiElements["gender"]) then
                gender = tonumber(guiGetText(guiElements["gender"]))
                race = tonumber(guiGetText(guiElements["race"]))
            
                if not race or not gender then
                   return triggerEvent("displayMesaage", localPlayer, "Incorrect gender/race.", "error")
                end
            end

            local comment
            if isElement(guiElements["comment"]) then
                comment = guiGetText(guiElements["comment"])
            end

            local foundillegal = xmlHasIllegalCharacters(author) or xmlHasIllegalCharacters(title) or xmlHasIllegalCharacters(desc)
            if comment then
                foundillegal = xmlHasIllegalCharacters(comment)
            end
            if foundillegal then
               return triggerEvent("displayMesaage", localPlayer, "Illegal characters found in author/name/desc/comment. Please don't use: \",',<,>,&", "error")
            end

            guiSetEnabled(mlGUI.viewUpload, false)
            triggerServerEvent("newmods:updateUploadDetails", localPlayer, mt, upload.upid, author, title, desc, comment, gender, race)

        end, false)


        if (status == "Declined" )  then--or status == "Cancelled" --and exports["sarp-new-mods"]:isModFullPerm(localPlayer)
            -- can delete request

            mlGUI.delete = guiCreateButton(5, (upmH-40*2-1), (upmW/6 - 5*2), 35, "Perm. Delete", false, mlGUI.viewUpload)
            addEventHandler("onClientGUIClick", mlGUI.delete, function()
                guiSetEnabled(mlGUI.viewUpload, false)
                setDrawingModImage(false)

                triggerServerEvent("newmods:deleteUpload", localPlayer, mt, upload.upid)
            end, false)
            guiSetProperty(mlGUI.delete , "NormalTextColour", "ffff0000")


            mlGUI.preview = guiCreateButton(upmW/6 + 5, (upmH-40*2-1), (upmW/6 - 5*2), 35, "Preview Mod", false, mlGUI.viewUpload)
            addEventHandler("onClientGUIClick", mlGUI.preview, function()
                destroyElement(mlGUI.viewUpload)
                setDrawingModImage(false)
                closeMLGUI()

                local img = ((status=="Accepted" and upload.modelid) or (- (tonumber(upload.upid))))
                setPreviewingMod(true, mt, tonumber(upload.upid), img)
            end, false)
            guiSetProperty(mlGUI.preview , "NormalTextColour", "ffffb0f6")
        else


            mlGUI.preview = guiCreateButton(5, (upmH-40*2-1), upmW/3 - 5*2, 35, "Preview Mod", false, mlGUI.viewUpload)
            addEventHandler("onClientGUIClick", mlGUI.preview, function()
                destroyElement(mlGUI.viewUpload)
                setDrawingModImage(false)
                closeMLGUI()

                local img = ((status=="Accepted" and upload.modelid) or (- (tonumber(upload.upid))))
                setPreviewingMod(true, mt, tonumber(upload.upid), img)
            end, false)
            guiSetProperty(mlGUI.preview , "NormalTextColour", "ffffb0f6")
        end

        local disText = "Decline Request"
        if status == "Accepted" then
            disText = "Disable Mod"
        end

        mlGUI.decline = guiCreateButton(5 +upmW/3, (upmH-40*2-1), upmW/3 - 5*2, 35, disText, false, mlGUI.viewUpload)
        addEventHandler("onClientGUIClick", mlGUI.decline, function()

            if disText == "Disable Mod" then
                if not exports["sarp-new-mods"]:isModFullPerm(localPlayer) then
                    return triggerEvent("displayMesaage", localPlayer, "Only senior mod reviewers are able to disable mods that are already implemented.", "error")
                end

                if mt == "Skin" then

                    outputChatBox("WARNING: When a mod that was implemented is disabled all CLOTHES ITEMS of that", 255, 255, 0)
                    outputChatBox("skin ID will be wiped from the server.", 255, 255, 0)
                end
            end

            guiSetEnabled(mlGUI.viewUpload, false)
            setDrawingModImage(false)

            enterReviewMessage(mt, upload.upid, false)
        end, false)
        guiSetProperty(mlGUI.decline , "NormalTextColour", "ffff3838")
        guiSetEnabled(mlGUI.decline, (status == "Accepted") or (status=="Pending"))

        mlGUI.accept = guiCreateButton(5 + (upmW/3) + (upmW/3), (upmH-40*2-1), upmW/3 - 5*2, 35, "Accept & Implement", false, mlGUI.viewUpload)
        addEventHandler("onClientGUIClick", mlGUI.accept, function()

            if status == "Declined" and not exports["sarp-new-mods"]:isModFullPerm(localPlayer) then
                return triggerEvent("displayMesaage", localPlayer, "Only senior mod reviewers are able to re-implement disabled mods.", "error")
            end

            guiSetEnabled(mlGUI.viewUpload, false)
            setDrawingModImage(false)

            enterReviewMessage(mt, upload.upid, true)
        end, false)
        guiSetProperty(mlGUI.accept , "NormalTextColour", "ff0dff00")
        guiSetEnabled(mlGUI.accept, (status == "Declined") or (status == "Pending"))
    end


    mlGUI.viewUploadClose = guiCreateButton(5, upmH-40, upmW -10, 35, "Close", false, mlGUI.viewUpload)
    addEventHandler("onClientGUIClick", mlGUI.viewUploadClose, function()
        closeViewModAdmin()
    end, false)

    local img = ((status=="Accepted" and upload.modelid) or (- (tonumber(upload.upid))))
    setDrawingModImage(true, img, status=="Cancelled")
end
addEvent("modloader:viewUploadAdmin", true)
addEventHandler("modloader:viewUploadAdmin", root, viewUploadAdmin)


function closeViewModAdmin()
    destroyElement(mlGUI.viewUpload)
    setDrawingModImage(false)

    closeMLGUI()
    executeCommandHandler("modloader", "bypass")
end


-- message to decline/accept
function enterReviewMessage(mt, upid, accept)
    local hw,hh = wW/2, wH/3

    local title = accept and "Accepting "..mt.." Request ID #"..upid or "Declining "..mt.." Request ID #"..upid

    mlGUI.revMsgW = guiCreateWindow((sX - hw)/2, (sY - hh)/2, hw, hh, title, false)
    guiWindowSetSizable(mlGUI.revMsgW, false)

    mlGUI.revMsgL = guiCreateLabel(15, 25, hw, 20, "Custom message sent to the uploader:", false, mlGUI.revMsgW)
    mlGUI.revMsgMemo = guiCreateMemo(10, 50, hw - 10*2, hh/3, "", false, mlGUI.revMsgW)
    guiSetProperty(mlGUI.revMsgMemo, "MaxTextLength", "500" )

    mlGUI.revMsgSend = guiCreateButton(5, hh-40*2-1, hw -10, 35, accept and "Accept & Implement" or "Decline Request", false, mlGUI.revMsgW)
    if accept then
        guiSetProperty(mlGUI.revMsgSend , "NormalTextColour", "ff00ff00")
    else
        guiSetProperty(mlGUI.revMsgSend , "NormalTextColour", "ffff0000")
    end
    addEventHandler("onClientGUIClick", mlGUI.revMsgSend, function()

        local msg = guiGetText(mlGUI.revMsgMemo) or ""
        if msg == "" then
           return triggerEvent("displayMesaage", localPlayer, "You need to enter a message to "..(accept and "accept" or "decline").." this request.", "error")
        end

        -- if (not accept) and string.len(msg) < 5 then
        --     return triggerEvent("displayMesaage", localPlayer, "Message entered is too short.", "error")
        -- end

        local foundillegal = xmlHasIllegalCharacters(msg)
        if foundillegal then
           return triggerEvent("displayMesaage", localPlayer, "Illegal characters found in your message. Please don't use: \",',<,>,&", "error")
        end


        destroyElement(mlGUI.revMsgW)
        guiSetEnabled(mlGUI.viewUpload, false)
        if not accept then
            triggerServerEvent("newmods:declineUpload", localPlayer, mt, upid, msg)
        else
            triggerServerEvent("newmods:acceptUpload", localPlayer, mt, upid, msg)
        end

    end, false)

    mlGUI.revMsgC = guiCreateButton(5, hh-40, hw -10, 35, "Cancel", false, mlGUI.revMsgW)
    addEventHandler("onClientGUIClick", mlGUI.revMsgC, function()
        destroyElement(mlGUI.revMsgW)
        guiSetEnabled(mlGUI.viewUpload, true)
    end, false)
end

-- after admin view mod edit
function receiveUploadEditConfirmation(success, msg)

    local title = success and "Success!" or "Error"
    modImage = nil -- refresh it


    local upmW, upmH = wW/3, 150

    mlGUI.upmPopup = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, title, false)
    guiWindowSetSizable(mlGUI.upmPopup,false)

    mlGUI.upmPopupL = guiCreateLabel(8, 50, upmW - 8*2, upmH/1.5, msg, false, mlGUI.upmPopup)
    guiLabelSetHorizontalAlign(mlGUI.upmPopupL, "center", true)


    mlGUI.bUpmPopupClose = guiCreateButton(5, upmH-40, upmW -10, 35, "Close", false, mlGUI.upmPopup)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupClose, function()
        setDrawingModImage(false)
        destroyElement(mlGUI.viewUpload)
        destroyElement(mlGUI.upmPopup)
        executeCommandHandler("modloader", "bypass")
    end, false)
end
addEvent("modloader:receiveUploadEditConfirmation", true)
addEventHandler("modloader:receiveUploadEditConfirmation", root, receiveUploadEditConfirmation)


-- player view request
function clickMyUpload()
    local row, col = guiGridListGetSelectedItem(mlGUI.uploads)
    if row ~= -1 and col ~= -1 then
        local mt = tostring(guiGridListGetItemText(mlGUI.uploads, row, 1))
        local upid = tonumber(guiGridListGetItemText(mlGUI.uploads, row, 2))

        if mt and upid then

            guiSetEnabled(mlGUI.window, false)

            local upmW, upmH = 160, 80
            mlGUI.clickUplPopup = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, "", false)
            guiWindowSetSizable(mlGUI.clickUplPopup,false)

            mlGUI.clickUplPopupL = guiCreateLabel(0, upmH/2, upmW, upmH, "Loading..", false, mlGUI.clickUplPopup)
            guiLabelSetHorizontalAlign(mlGUI.clickUplPopupL, "center")

            triggerLatentServerEvent("newmods:loadUploadData", localPlayer, mt, upid, false)
        else
            triggerEvent("displayMesaage", localPlayer, "Unknown error.", "error")
        end
    end
end

-- admin manage request
function clickAnUpload()
    local row, col = guiGridListGetSelectedItem(source)
    if row ~= -1 and col ~= -1 then
        local mt = tostring(guiGridListGetItemText(source, row, 1))
        local upid = tonumber(guiGridListGetItemText(source, row, 2))

        if mt and upid then

            guiSetEnabled(mlGUI.window, false)

            local upmW, upmH = 160, 80
            mlGUI.clickUplPopup = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, "", false)
            guiWindowSetSizable(mlGUI.clickUplPopup,false)

            mlGUI.clickUplPopupL = guiCreateLabel(0, upmH/2, upmW, upmH, "Loading..", false, mlGUI.clickUplPopup)
            guiLabelSetHorizontalAlign(mlGUI.clickUplPopupL, "center")

            triggerLatentServerEvent("newmods:loadUploadData", localPlayer, mt, upid, true)
        else
            triggerEvent("displayMesaage", localPlayer, "Unknown error.", "error")
        end
    end
end

local availableModTypes = {
    [1] = {
        enabled = true,
        name = "ped",
        nice = "Ped (Skin)",
        perm = "player",
    },
    [2] = {
        enabled = true,
        name = "vehicle",
        nice = "Vehicle",
        perm = "staff",
    },
    [3] = {
        enabled = false,
        name = "object",
        nice = "Object",
        perm = "staff",
    },
}


function uploadGUI(button)
    if button == "left" then

        guiSetEnabled(mlGUI.window, false)
        guiSetVisible(mlGUI.window, false)

        local upmW, upmH = wW/2, 300

        mlGUI.upmPopup = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, "Upload a Mod - Choose Type", false)
        guiWindowSetSizable(mlGUI.upmPopup,false)

        mlGUI.helpMeBtn = guiCreateButton((sX - upmW)/2, (sY - upmH)/2 - 40, upmW, 40, "Help - What is this?", false)
        addEventHandler( "onClientGUIClick", mlGUI.helpMeBtn,
        function (button)
            if button == "left" then
                closeUploadPopup()
                helpML()
            end
        end, false)
        guiSetProperty(mlGUI.helpMeBtn , "NormalTextColour", "ff69ebff")
        guiWindowSetMovable(mlGUI.upmPopup, false)

        mlGUI.upmPopupL = guiCreateLabel(6, 40, upmW - 6*2, 80, "You can now upload \"add-on\" mods to the server.\nThese have to be reviewed by staff to ensure certain standards.\nPlease read the rules on Mod Uploads before continuing.\n\nStart by selecting the type of mod:", false, mlGUI.upmPopup)
        guiLabelSetHorizontalAlign(mlGUI.upmPopupL, "center", true)

        mlGUI.modSelect = guiCreateComboBox(6, 125, upmW - 6*2, 100, "Please make a selection", false, mlGUI.upmPopup)
        for k, v in pairsByKeys(availableModTypes) do
            guiComboBoxAddItem(mlGUI.modSelect, v.nice)
        end

        mlGUI.upmPopupL2 = guiCreateLabel(6, upmH-110, upmW - 6*2, 45, "", false, mlGUI.upmPopup)
        guiLabelSetHorizontalAlign(mlGUI.upmPopupL2, "center", true)
        


        local function showError(msg)
            if msg then
                guiLabelSetColor(mlGUI.upmPopupL2, 255,25,25)
                guiSetText(mlGUI.upmPopupL2, msg)
                guiSetEnabled(mlGUI.bUpmPopupContinue, false)
            else
                guiLabelSetColor(mlGUI.upmPopupL2, 187,187,187)
                guiSetText(mlGUI.upmPopupL2, "")
                guiSetEnabled(mlGUI.bUpmPopupContinue, true)
            end
        end


        mlGUI.bUpmPopupContinue = guiCreateButton(5, upmH-80, upmW -10, 35, "Continue", false, mlGUI.upmPopup)
        guiSetProperty(mlGUI.bUpmPopupContinue, "NormalTextColour", "FF00FF00")
        guiSetEnabled(mlGUI.bUpmPopupContinue, false)
        addEventHandler( "onClientGUIClick", mlGUI.bUpmPopupContinue, 
        function (button) 
            if button == "left" then
                local sel = guiComboBoxGetSelected(mlGUI.modSelect)
                if sel == -1 then
                    showError("You have to select a mod type from the list.")
                    return
                end
                local modType = availableModTypes[sel + 1].name
                closeUploadPopup()
                uploadGUIFiles(modType)
            end
        end, false)

        addEventHandler( "onClientGUIComboBoxAccepted", mlGUI.modSelect, 
        function () 
            local sel = guiComboBoxGetSelected(mlGUI.modSelect)
            if sel == -1 then
                showError("You have to select a mod type from the list.")
                return
            end

            local v = availableModTypes[sel + 1]
            if not v.enabled then
                showError((v.nice).." mod uploads are currently disabled. Stay tuned!")
                return
            end
            local perm = v.perm
            if perm == "staff" and not exports["sarp-new-mods"]:isModFullPerm(localPlayer) then
                showError("Sorry, you lack permission to upload "..(v.nice).." mods.")
                return
            end

            showError()
        end, false)

        mlGUI.bUpmPopupClose = guiCreateButton(5, upmH-40, upmW -10, 35, "Cancel", false, mlGUI.upmPopup)
        addEventHandler("onClientGUIClick", mlGUI.bUpmPopupClose, function()
            closeUploadPopup()
            guiSetEnabled(mlGUI.window, true)
            guiSetVisible(mlGUI.window, true)
        end, false)
    end
end

function uploadGUIFiles(modType)
        
    local upmW, upmH = wW/2, 300

    mlGUI.upmPopup = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, "Upload a Mod - Select Files", false)
    guiWindowSetSizable(mlGUI.upmPopup,false)

    mlGUI.helpMeBtn = guiCreateButton((sX - upmW)/2, (sY - upmH)/2 - 40, upmW, 40, "Help - What is this?", false)
    addEventHandler( "onClientGUIClick", mlGUI.helpMeBtn,
    function (button)
        if button == "left" then
            closeUploadPopup()
            helpML()
        end
    end, false)
    guiSetProperty(mlGUI.helpMeBtn , "NormalTextColour", "ff69ebff")
    guiWindowSetMovable(mlGUI.upmPopup, false)

    mlGUI.upmPopupL = guiCreateLabel(6, 40, upmW - 6*2, upmH/1.5, "In order to upload a mod to the server you need to place it in SARP_Modloader/upload before doing this.\n\nThe script will try to locate the .dff and .txd files with name provided.\n\nThis file name can be anything you want as it's only used to find the mod to then upload it to the server.", false, mlGUI.upmPopup)
    guiLabelSetHorizontalAlign(mlGUI.upmPopupL, "center", true)

    local defaultfile = ".dff & .txd file name (both files need to have the same name)"
    mlGUI.upmNameE = guiCreateEdit(6, 165, upmW - 6*2, 26, defaultfile, false, mlGUI.upmPopup)
    addEventHandler("onClientGUIClick", mlGUI.upmNameE, function(button)
        if button == "left" then
            if guiGetText(source) == defaultfile then
                guiSetText(source, "")
            end
        end
    end, false)

    mlGUI.upmLocateFile = guiCreateButton(5, upmH-80, upmW -10, 35, "Locate Mod Files", false, mlGUI.upmPopup)
    addEventHandler("onClientGUIClick", mlGUI.upmLocateFile, function(button)

        if button == "left" then
            local text = tostring(guiGetText(mlGUI.upmNameE))
            if text == defaultfile then return end
            local text_ = string.len(text)
            if text == "" then
                return triggerEvent("displayMesaage", localPlayer, "You need to enter the name of your .dff and .txd mod files to upload.", "error")
            end
            if text_ > 30 then
                return triggerEvent("displayMesaage", localPlayer, "File name is too long!", "error")
            end
            if text:match("%W") then
                return triggerEvent("displayMesaage", localPlayer, "Only alphanumeric file names allowed.", "error")
            end

            local exists, msg = checkModFilesExist(text)
            if not exists then
                return triggerEvent("displayMesaage", localPlayer, msg, "error")
            end

            local works, msg2 = checkModFilesCorrupted(text, modType)
            if not works then
                return triggerEvent("displayMesaage", localPlayer, msg2, "error")
            end
            closeUploadPopup()

            openUploadMod(modType, text)
        end

    end, false)
    guiSetProperty(mlGUI.upmLocateFile , "NormalTextColour", "FFFFFF00")

    mlGUI.bUpmPopupClose = guiCreateButton(5, upmH-40, upmW -10, 35, "Back", false, mlGUI.upmPopup)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupClose, function(button)
        if button == "left" then
            closeUploadPopup()
            uploadGUI(button)
        end
    end, false)
end

function closeUploadPopup()
    destroyElement(mlGUI.upmPopup)
    destroyElement(mlGUI.helpMeBtn)
end

function uploadFieldsCheck()

    local result = true
    local errorTitle, msg = "There's a problem!", "Something went wrong"

    local authors = guiGetText(mlGUI.upmE2)
    local authors_ = string.len(authors)
    local title = guiGetText(mlGUI.upmE3)
    local title_ = string.len(title)
    local description = guiGetText(mlGUI.upmE4)
    local description_ = string.len(description)
    local image = guiGetText(mlGUI.upmE6)
    local image_ = string.len(image)
    local purpose = guiComboBoxGetSelected(mlGUI.upmE5)

    if authors_ < 1 then
       return false, errorTitle, "Author(s) missing. You need to tell us who created the mod you are submitting."
    end
    if title_ <= 5 then
        return false, errorTitle, "Name is too short. Needs to be at least 5 characters."
    end

    if description_ <= 15 then
        return false, errorTitle, "Description is too short. Needs to be at least 15 characters."
    end

    if purpose == -1 then
        return false, errorTitle, "Availability not selected. Please select a type of mod upload."
    end

    if image_ <= 2 then
       return false, errorTitle, "Image URL missing. You need to provide a valid image URL."
    end

    local foundillegal = xmlHasIllegalCharacters(authors) or xmlHasIllegalCharacters(title) or xmlHasIllegalCharacters(description)
    if foundillegal then
        return false, errorTitle, "Illegal characters found in author/name/desc. Please don't use: \",',<,>,&"
    end


    local foundillegal2 = urlHasIllegalCharacters(image)
    if foundillegal2 then
        return false, errorTitle, "Illegal characters found in image URL. An URL looks like this: https://i.imgur.com/x8w8pXe.png"
    end

    if not (string.find(image, "http://", 1, true) or string.find(image, "https://", 1, true)) then
        return false, errorTitle, "Image URL is invalid. An URL looks like this: https://i.imgur.com/x8w8pXe.png"
    end


    return true

end

local antiCheckSpam = getTickCount()

local extraTexts = {
    ["ped"] = {
        desc = "(e.g: physical attributes, clothes, etc)",
        uploadc = "This means that it will be distributed to all Clothing Store NPCs.\n\nIt will also be available at the Custom Skin Texture NPC so that anyone can apply custom shader textures to it.",
    },
    ["vehicle"] = {
        desc = "(e.g: vehicle category, style, number of seats, etc)",
        uploadc = "",
    },
}

function openUploadMod(modtype, name)
    guiSetEnabled(mlGUI.window, false)
    guiSetVisible(mlGUI.window, false)

    local upmW, upmH = sX / 1.2, sY / 1.15

    mlGUI.upmwindow = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, "Upload a Mod  -  "..string.upper(modtype), false)
    guiWindowSetSizable(mlGUI.upmwindow,false)

    mlGUI.bUpmClose = guiCreateButton(upmW/2 + 5, upmH-40, upmW/2 -10, 35, "Cancel", false, mlGUI.upmwindow)
    addEventHandler("onClientGUIClick", mlGUI.bUpmClose, closeUploadMod, false)

    local subText = "By submitting this mod you understand that it may be rejected if it is not deemed fit for public use. Mod reviewers may alter info such as the title and preview image of your mod.\nReminder: If you are unsure of what you are doing or have questions regarding a certain feature please consult the tutorial."
    mlGUI.upmL7 = guiCreateLabel(20, upmH-87, upmW - 20*2, 50, subText, false, mlGUI.upmwindow)
    mlGUI.bUpmSubmit = guiCreateButton(0, upmH-40, upmW/2 -5, 35, "Continue", false, mlGUI.upmwindow)
    addEventHandler("onClientGUIClick", mlGUI.bUpmSubmit, function(button)
        if button == "left" then

            local yes, title, msg = uploadFieldsCheck()
            if not yes then
                openUploadModPopup(title, msg)
            else
                openUploadModConfirm(modtype)
            end

        end
    end, false)
    guiSetProperty(mlGUI.bUpmSubmit, "NormalTextColour", "ff00ff00")

    local label1 = "You can upload a mod that you have stored in the SARP_Modloader folder under 'upload'.\n\nYour mod will be sent to the server which will allow it to be streamed for all players once accepted & implemented.\n\nHow does it work?\n\n  - Your "..modtype.." is assigned to a new unique ID.\n  - Everyone will be able to see your mod on their game.\n  - Mod files are never downloaded by other players: they're stored on the server so no one can steal them."
    mlGUI.upmL1 = guiCreateLabel(14, 30, upmW - 30, 160, label1, false, mlGUI.upmwindow)
    guiLabelSetHorizontalAlign(mlGUI.upmL1, "left", true)


    mlGUI.upmL2 = guiCreateLabel(20, 195, upmW/2 - 20*2, 20, "Mod being uploaded (dff and txd)", false, mlGUI.upmwindow)
    guiSetFont(mlGUI.upmL2, "default-bold-small")
    mlGUI.upmE1 = guiCreateEdit(14, 215, upmW/2 - 14*2, 30, name, false, mlGUI.upmwindow)
    guiSetEnabled(mlGUI.upmE1 , false)

    local author = ""
    if exports["sarp-new-mods"]:isModFullPerm(localPlayer) then
        author = "-"
    end

    mlGUI.upmL3 = guiCreateLabel((upmW/2 - 20*2) + 20*2, 195, upmW/2 - 20*2, 20, "Author(s) of the mod (nicknames)", false, mlGUI.upmwindow)
    guiSetFont(mlGUI.upmL3, "default-bold-small")
    mlGUI.upmE2 = guiCreateEdit(upmW/2 - 14*2 + 14*2, 215, upmW/2 - 14*2, 30, author, false, mlGUI.upmwindow)
    guiEditSetMaxLength(mlGUI.upmE2, 75)

    local title = ""
    if exports["sarp-new-mods"]:isModFullPerm(localPlayer) then
        title = name
    end

    mlGUI.upmL4 = guiCreateLabel(20, 260, upmW - 20*2, 20, "Name (short description/title)", false, mlGUI.upmwindow)
    guiSetFont(mlGUI.upmL4, "default-bold-small")
    mlGUI.upmE3 = guiCreateEdit(14, 280, upmW - 14*2, 30, title, false, mlGUI.upmwindow)
    guiEditSetMaxLength(mlGUI.upmE3, 75)

    local desc = ""
    if exports["sarp-new-mods"]:isModFullPerm(localPlayer) then
        desc = "Placeholder text ------------------------------"
    end

    mlGUI.upmL5 = guiCreateLabel(20, 260+65, upmW - 20*2, 20, "Detailed description of the mod "..extraTexts[modtype].desc, false, mlGUI.upmwindow)
    guiSetFont(mlGUI.upmL5, "default-bold-small")
    mlGUI.upmE4 = guiCreateMemo(14, 280+65, upmW - 14*2, 65, desc, false, mlGUI.upmwindow)
    guiSetProperty(mlGUI.upmE4, "MaxTextLength", "500" )

    mlGUI.upmL6 = guiCreateLabel(20, 280+65+65+10, upmW - 20*2, 20, "Availability of the mod", false, mlGUI.upmwindow)
    guiSetFont(mlGUI.upmL6, "default-bold-small")
    mlGUI.upmE5 = guiCreateComboBox(15, 280+65+65+30, upmW - 15*2, 80, "Select an option", false, mlGUI.upmwindow)
    guiComboBoxSetSelected(mlGUI.upmE5, -1)
    guiSetAlpha(mlGUI.upmE5, 1)

    local lastindex = -1
    for id, v in pairsByKeys(uploadTypes) do
        local ftype = false
        for _,_modtype in pairs(v.allowedTypes) do
            if modtype == _modtype then
                ftype = true
                break
            end
        end
        if ftype then

            if (v.perm == "player") or (v.perm == "staff" and exports["sarp-new-mods"]:isModFullPerm(localPlayer)) then
                guiComboBoxAddItem(mlGUI.upmE5, v.desc)
                lastindex = lastindex + 1
            end
        end
    end

    if exports["sarp-new-mods"]:isModFullPerm(localPlayer) then
        guiComboBoxSetSelected(mlGUI.upmE5, lastindex)
    end

    mlGUI.upmL7 = guiCreateLabel(20, 280+65+65+65, upmW - 20*2, 20, "Preview image URL - maximum 100 x 100 pixels; must be SQUARE; must have transparent background; uploaded to Imgur.com", false, mlGUI.upmwindow)
    guiSetFont(mlGUI.upmL7, "default-bold-small")
    
    local imgurl = ""
    if exports["sarp-new-mods"]:isModFullPerm(localPlayer) then
        imgurl = "https://i.imgur.com/tuzvEyC.png"
    end
    mlGUI.upmE6 = guiCreateEdit(14, 280+65+65+65+20, upmW - 14*2, 30, imgurl, false, mlGUI.upmwindow)
    guiEditSetMaxLength(mlGUI.upmE6, 100)
end

-- remote triggered
function openUploadModPopup(title_, msg)

    local title = title_ or "Error!"

    if isElement(mlGUI.upmwindow) then
        guiSetEnabled(mlGUI.upmwindow, false)
        guiSetAlpha(mlGUI.upmwindow, 0.2)
    else
        return outputChatBox(title.." | "..msg, 255,255,255)
    end

    if isElement(mlGUI.upmPopup2) then destroyElement(mlGUI.upmPopup2) end
    if isElement(mlGUI.upmPopupConfirm) then destroyElement(mlGUI.upmPopupConfirm) end
    if isElement(mlGUI.upmPopup2) then destroyElement(mlGUI.upmPopup2) end

    local upmW, upmH = wW/3, 150

    mlGUI.upmPopup = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, title, false)
    guiWindowSetSizable(mlGUI.upmPopup,false)

    mlGUI.upmPopupL = guiCreateLabel(6, 40, upmW - 6*2, upmH/1.5, msg, false, mlGUI.upmPopup)
    guiLabelSetHorizontalAlign(mlGUI.upmPopupL, "center", true)


    mlGUI.bUpmPopupClose = guiCreateButton(5, upmH-40, upmW -10, 35, "Close", false, mlGUI.upmPopup)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupClose, function()
        destroyElement(mlGUI.upmPopup)
        if isElement(mlGUI.upmwindow) then
            guiSetEnabled(mlGUI.upmwindow, true)
            guiSetAlpha(mlGUI.upmwindow, 0.8)
        end
    end, false)
end
addEvent("modloader:receiveUploadConfirmation_notFinal", true)
addEventHandler("modloader:receiveUploadConfirmation_notFinal", root, openUploadModPopup)

-- remote triggered
function openUploadModPopup2(success, msg)

    -- final confirmation : close will return to the main modloader window

    if not isElement(mlGUI.upmwindow) then
        if success then
            outputChatBox("Success: "..msg, 0,255,0)
        else
            outputChatBox("Error: "..msg, 255,0,0)
        end
        return
    end

    if isElement(mlGUI.upmPopup) then destroyElement(mlGUI.upmPopup) end
    if isElement(mlGUI.upmPopupConfirm) then destroyElement(mlGUI.upmPopupConfirm) end
    if isElement(mlGUI.upmPopup2) then destroyElement(mlGUI.upmPopup2) end

    local upmW, upmH = wW/3, 150

    mlGUI.upmPopup2 = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, (success and "Upload Successfull" or "Upload Failed"), false)
    guiWindowSetSizable(mlGUI.upmPopup2,false)

    mlGUI.upmPopup2L = guiCreateLabel(6, 40, upmW - 6*2, upmH/1.5, msg, false, mlGUI.upmPopup2)
    guiLabelSetHorizontalAlign(mlGUI.upmPopup2L, "center", true)


    mlGUI.bUpmPopupClose = guiCreateButton(5, upmH-40, upmW -10, 35, "Close", false, mlGUI.upmPopup2)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupClose, function()
        destroyElement(mlGUI.upmPopup2)
        if isElement(mlGUI.upmwindow) then
            destroyElement(mlGUI.upmwindow)
            closeMLGUI()
            lastTab = 4
            executeCommandHandler("modloader", "bypass")
        end
    end, false)
end
addEvent("modloader:receiveUploadConfirmation", true)
addEventHandler("modloader:receiveUploadConfirmation", root, openUploadModPopup2)


-- local popup
function openUploadModConfirm(modtype)

    guiSetEnabled(mlGUI.upmwindow, false)
    guiSetAlpha(mlGUI.upmwindow, 0.2)

    local upmW, upmH = wW/3, 150

    mlGUI.upmPopupConfirm = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, "Confirmation", false)
    guiWindowSetSizable(mlGUI.upmPopupConfirm,false)

    mlGUI.upmPopupConfirmL = guiCreateLabel(10, 30, upmW - 10*2, upmH/1.5, "Are you sure you want to submit your mod?\n\nPlease review the mod information you entered and ensure it's correct.", false, mlGUI.upmPopupConfirm)
    guiLabelSetHorizontalAlign(mlGUI.upmPopupConfirmL, "center", true)


    mlGUI.bUpmPopupSubmit = guiCreateButton(5, upmH-40, upmW/2 -10, 35, "Continue", false, mlGUI.upmPopupConfirm)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupSubmit, function()



        local modelname = guiGetText(mlGUI.upmE1)
        local authors = guiGetText(mlGUI.upmE2)
        local title = guiGetText(mlGUI.upmE3)
        local description = guiGetText(mlGUI.upmE4)
        local imgurl = guiGetText(mlGUI.upmE6)
        local purpose = guiComboBoxGetSelected(mlGUI.upmE5)
        local purposeText = guiComboBoxGetItemText(mlGUI.upmE5, purpose)
        for purposeID, v in pairsByKeys(uploadTypes) do -- Fetch actual purpose ID
            if v.desc == purposeText then
                purpose = purposeID
                break
            end
        end

        local t = {name = modelname, author = authors, title = title, desc = description, purpose = purpose, image = imgurl}

        guiSetEnabled(mlGUI.upmPopupConfirm, false)
        triggerServerEvent("newmods:preSubmitModUpload", localPlayer, modtype, t)
    end, false)
    guiSetProperty(mlGUI.bUpmPopupSubmit, "NormalTextColour", "ff00ff00")

    mlGUI.bUpmPopupClose = guiCreateButton(upmW/2 + 5, upmH-40, upmW/2 -10, 35, "Close", false, mlGUI.upmPopupConfirm)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupClose, function()
        destroyElement(mlGUI.upmPopupConfirm)
        guiSetEnabled(mlGUI.upmwindow, true)
        guiSetAlpha(mlGUI.upmwindow, 0.8)
    end, false)
end

function closeUploadMod()
    if isElement(mlGUI.upmwindow) then
        destroyElement(mlGUI.upmwindow)
        guiSetEnabled(mlGUI.window, true)
        guiSetVisible(mlGUI.window, true)
    end
end


addEventHandler( "onClientResourceStop", resourceRoot,
function()
    if isElement(bb) then
        exports.blur_box:destroyBlurBox(bb)
        setElementData(localPlayer, "exclusiveGUI", nil)
    end
end)


function askToPayForUpload(modType, mod, dffdata, txddata, extra)
    if isElement(mlGUI.upmPopupConfirm) then destroyElement(mlGUI.upmPopupConfirm) end

    local totaluploads, maxFreeModUploads, gcPrice = unpack(extra)

    local upmW, upmH = wW/3, 250

    mlGUI.upmPopupConfirm = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, "Redeem a Mod Upload", false)
    guiWindowSetSizable(mlGUI.upmPopupConfirm,false)

    mlGUI.upmPopupConfirmL = guiCreateLabel(10, 30, upmW - 10*2, upmH/1.5, "Personal Mod Upload\n\nYou have maxed out "..totaluploads.."/"..maxFreeModUploads.." free uploads.\n\nA mod upload will now cost "..gcPrice.." coins.\nYou can find more about this currency on: "..premiumURL.."\n\nUpon continuing you will be charged for the submission. If your request is declined the full price in coins you paid is refunded.", false, mlGUI.upmPopupConfirm)
    guiLabelSetHorizontalAlign(mlGUI.upmPopupConfirmL, "center", true)


    mlGUI.bUpmPopupSubmit = guiCreateButton(5, upmH-40, upmW/2 -10, 35, "Purchase & Submit", false, mlGUI.upmPopupConfirm)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupSubmit, function()

        guiSetEnabled(mlGUI.upmPopupConfirm, false)

        triggerServerEvent("newmods:validateUpload", localPlayer, modType, mod, dffdata, txddata, 1, extra)
    end, false)
    guiSetProperty(mlGUI.bUpmPopupSubmit, "NormalTextColour", "ff00ff00")

    mlGUI.bUpmPopupClose = guiCreateButton(upmW/2 + 5, upmH-40, upmW/2 -10, 35, "Cancel", false, mlGUI.upmPopupConfirm)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupClose, function()
        triggerEvent("modloader:receiveUploadConfirmation", localPlayer, false, "Upload cancelled.")
    end, false)

end
addEvent("modloader:askToPayForUpload", true)
addEventHandler("modloader:askToPayForUpload", root, askToPayForUpload)

-- Fernando: Added Gender & Race dropdowns for public skins
-- 10/04/2021

local waitTimer
local fBasemodel
function askToUploadGlobalServer(modType, av, mod, dffdata, txddata)
    if isElement(mlGUI.upmPopupConfirm) then destroyElement(mlGUI.upmPopupConfirm) end

    local upmW, upmH = wW/3, 345

    mlGUI.upmPopupConfirm = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, "Upload Mod - Global (Public)", false)
    guiWindowSetSizable(mlGUI.upmPopupConfirm,false)

    mlGUI.upmPopupConfirmL = guiCreateLabel(10, 30, upmW - 10*2, upmH/1.5, "Global Mod Upload\n\nYou are about to submit a mod that will be available for everyone on the server.\n\n"..extraTexts[modType].uploadc, false, mlGUI.upmPopupConfirm)
    guiLabelSetHorizontalAlign(mlGUI.upmPopupConfirmL, "center", true)

    if modType == "ped" then

        local gender_c = guiCreateComboBox(10, upmH-40*3, upmW - 10*2, 80, "", false, mlGUI.upmPopupConfirm)
        guiComboBoxAddItem(gender_c, "Male")
        guiComboBoxAddItem(gender_c, "Female")
        guiComboBoxSetSelected(gender_c, 0)
        exports.global:guiComboBoxAdjustHeight(gender_c)

        local race_c = guiCreateComboBox(10, upmH-40*2, upmW - 10*2, 80, "", false, mlGUI.upmPopupConfirm)
        guiComboBoxAddItem(race_c, "Black")
        guiComboBoxAddItem(race_c, "White")
        guiComboBoxAddItem(race_c, "Asian")
        guiComboBoxSetSelected(race_c, 0)
        exports.global:guiComboBoxAdjustHeight(race_c)

        mlGUI.bUpmPopupSubmit = guiCreateButton(5, upmH-40, upmW/2 -10, 35, "Acknowledge & Submit", false, mlGUI.upmPopupConfirm)
        addEventHandler("onClientGUIClick", mlGUI.bUpmPopupSubmit, function()

            guiSetEnabled(mlGUI.upmPopupConfirm, false)

            local gender,race = guiComboBoxGetItemText(gender_c, guiComboBoxGetSelected(gender_c)), guiComboBoxGetItemText(race_c, guiComboBoxGetSelected(race_c))
            local newgender, newrace = 0,0
            if gender == "Female" then
                newgender = 1
            end
            if race == "White" then
                newrace = 1
            elseif race == "Asian" then
                newrace = 2
            end

            triggerServerEvent("newmods:validateUpload", localPlayer, modType, mod, dffdata, txddata, av, {newgender, newrace})
        end, false)

        -- enable after a while
        guiSetEnabled(mlGUI.bUpmPopupSubmit, false)
        guiSetEnabled(mlGUI.bUpmPopupClose, false)
        
        waitTimer = setTimer(function()
            guiSetEnabled(mlGUI.bUpmPopupSubmit, true)
            guiSetEnabled(mlGUI.bUpmPopupClose, true)
        end, 5000, 1)

    elseif modType == "vehicle" then

        -- adjust window size
        upmW, upmH = wW/3, 225
        guiSetSize(mlGUI.upmPopupConfirm, upmW, upmH, false)
        exports.global:centerWindow(mlGUI.upmPopupConfirm)


        fBasemodel = nil

        local label = guiCreateLabel(10, upmH-40*3, upmW - 10*2, 40, "MTA Vehicle Base Model:\n(Add-on will inherit its properties)", false, mlGUI.upmPopupConfirm)
        guiLabelSetHorizontalAlign(label, "center", true)

        local basemodel_text = "MTA SA Vehicle ID/Name"
        local basemodel_e = guiCreateEdit(10, upmH-40*2, upmW - 10*2, 30, basemodel_text, false, mlGUI.upmPopupConfirm)
        guiEditSetMaxLength(basemodel_e, 35)

        addEventHandler( "onClientGUIClick", basemodel_e, 
        function (button) 
            if button == "left" then
                if guiGetText(source) == basemodel_text then
                    guiSetText(source, "")
                end
            end
        end, false)

        addEventHandler( "onClientGUIChanged", basemodel_e, 
        function ()
            local text = guiGetText(source)
            
            local baseid
            if tonumber(text) then
                if getVehicleNameFromModel(tonumber(text)) then
                    baseid = tonumber(text)
                end
            else
                local model = getVehicleModelFromName(text)
                if model then
                    baseid = model
                end
            end

            if not baseid then
                guiSetEnabled(mlGUI.bUpmPopupSubmit, false)
            else
                triggerEvent("displayMesaage", localPlayer, "Valid vehicle model: "..getVehicleNameFromModel(baseid).. " (#"..baseid..")", "success")
                guiSetEnabled(mlGUI.bUpmPopupSubmit, true)
                fBasemodel = baseid
            end

        end, false)

        mlGUI.bUpmPopupSubmit = guiCreateButton(5, upmH-40, upmW/2 -10, 35, "Acknowledge & Submit", false, mlGUI.upmPopupConfirm)
        addEventHandler("onClientGUIClick", mlGUI.bUpmPopupSubmit, function()

            guiSetEnabled(mlGUI.upmPopupConfirm, false)
            triggerServerEvent("newmods:validateUpload", localPlayer, modType, mod, dffdata, txddata, av, {fBasemodel})
        end, false)
    
        -- disabled til validation
        guiSetEnabled(mlGUI.bUpmPopupSubmit, false)
    else

        -- adjust window size
        upmW, upmH = wW/3, 200
        guiSetSize(mlGUI.upmPopupConfirm, upmW, upmH, false)
        exports.global:centerWindow(mlGUI.upmPopupConfirm)

        mlGUI.bUpmPopupSubmit = guiCreateButton(5, upmH-40, upmW/2 -10, 35, "Acknowledge & Submit", false, mlGUI.upmPopupConfirm)
        addEventHandler("onClientGUIClick", mlGUI.bUpmPopupSubmit, function()

            guiSetEnabled(mlGUI.upmPopupConfirm, false)

            triggerServerEvent("newmods:validateUpload", localPlayer, modType, mod, dffdata, txddata, av, {})
        end, false)
    end
    guiSetProperty(mlGUI.bUpmPopupSubmit, "NormalTextColour", "ff00ff00")

    mlGUI.bUpmPopupClose = guiCreateButton(upmW/2 + 5, upmH-40, upmW/2 -10, 35, "Cancel", false, mlGUI.upmPopupConfirm)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupClose, function()
        triggerEvent("modloader:receiveUploadConfirmation", localPlayer, false, "Upload cancelled.")
    end, false)


end
addEvent("modloader:askToUploadGlobalServer", true)
addEventHandler("modloader:askToUploadGlobalServer", root, askToUploadGlobalServer)


function askToSelectFaction(modType, mod, dffdata, txddata, extra)
    if isElement(mlGUI.upmPopupConfirm) then destroyElement(mlGUI.upmPopupConfirm) end

    local fTable = unpack(extra)

    local upmW, upmH = wW/3, 250

    mlGUI.upmPopupConfirm = guiCreateWindow((sX - upmW)/2, (sY - upmH)/2, upmW, upmH, "Upload Mod - Select Faction", false)
    guiWindowSetSizable(mlGUI.upmPopupConfirm,false)

    mlGUI.upmPopupConfirmL = guiCreateLabel(10, 30, upmW - 10*2, upmH/2, "Faction Mod Upload\n\nYou are about to upload a mod that will be exclusively available for members of a certain faction. Select one from the list.", false, mlGUI.upmPopupConfirm)
    guiLabelSetHorizontalAlign(mlGUI.upmPopupConfirmL, "center", true)

    mlGUI.upmPopupFactionC = guiCreateComboBox(10, upmH-130, upmW - 10*2, upmH/3, "Select a faction", false, mlGUI.upmPopupConfirm)

    for facid, fac in pairsByKeys(fTable) do
        guiComboBoxAddItem(mlGUI.upmPopupFactionC, exports["faction-system"]:getFactionName(facid))
    end

    mlGUI.bUpmPopupSubmit = guiCreateButton(5, upmH-40, upmW/2 -10, 35, "Confirm & Submit", false, mlGUI.upmPopupConfirm)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupSubmit, function()

        local fselected = guiComboBoxGetSelected(mlGUI.upmPopupFactionC)
        if fselected ~= -1 then
            fselected = guiComboBoxGetItemText(mlGUI.upmPopupFactionC, fselected)
            guiSetEnabled(mlGUI.upmPopupConfirm, false)

            triggerServerEvent("newmods:validateUpload", localPlayer, modType, mod, dffdata, txddata, 2, {fTable, fselected})
        else
            triggerEvent("displayMesaage", localPlayer, "You need to select a faction from the list to upload for.", "info")
        end

    end, false)
    guiSetProperty(mlGUI.bUpmPopupSubmit, "NormalTextColour", "ff00ff00")

    mlGUI.bUpmPopupClose = guiCreateButton(upmW/2 + 5, upmH-40, upmW/2 -10, 35, "Cancel", false, mlGUI.upmPopupConfirm)
    addEventHandler("onClientGUIClick", mlGUI.bUpmPopupClose, function()
        triggerEvent("modloader:receiveUploadConfirmation", localPlayer, false, "Upload cancelled.")
    end, false)

end
addEvent("modloader:askToSelectFaction", true)
addEventHandler("modloader:askToSelectFaction", root, askToSelectFaction)


function clearChat()
    local lines = getChatboxLayout()["chat_lines"]
    for i=1,lines do
        outputChatBox("  ")
    end
end

function forceOpenUpload()
    executeCommandHandler("modloader")
    setTimer(function()
        if isElement(mlGUI.window) then
            uploadGUI("left")
        end
    end, 500, 1)
end
addEvent("modloader:forceOpenUpload", true)
addEventHandler("modloader:forceOpenUpload", root, forceOpenUpload)

local gr = {}

function chooseSkinGenderRace(upID)
    closeCSGR()

    outputChatBox("You need to define your skin's gender & race for it to appear in clothing stores properly.", 255,194,14)

    local _ww, _wh = 200,150
    gr.w = guiCreateWindow(0,0,_ww, _wh, "Editing Skin Upload ID #"..upID, false)
    exports.global:centerWindow(gr.w)

    local gender_c = guiCreateComboBox(10, 25, _ww - 10*2, 80, "", false, gr.w)
    guiComboBoxAddItem(gender_c, "Male")
    guiComboBoxAddItem(gender_c, "Female")
    guiComboBoxSetSelected(gender_c, 0)
    exports.global:guiComboBoxAdjustHeight(gender_c)

    local race_c = guiCreateComboBox(10, 55, _ww - 10*2, 80, "", false, gr.w)
    guiComboBoxAddItem(race_c, "Black")
    guiComboBoxAddItem(race_c, "White")
    guiComboBoxAddItem(race_c, "Asian")
    guiComboBoxSetSelected(race_c, 0)
    exports.global:guiComboBoxAdjustHeight(race_c)

    local accept = guiCreateButton(10, 86,  _ww - 10*2, 26, "Save", false, gr.w)
    guiSetProperty(accept, "NormalTextColour", "FF00FF00")

    local close = guiCreateButton(10, 116,  _ww - 10*2, 26, "Cancel", false, gr.w)
    
    addEventHandler( "onClientGUIClick", gr.w, 
    function (button) 
        if button ~= "left" then return end
        if source == close then
            closeCSGR()
        elseif source == accept then

            local gender1,race1 = guiComboBoxGetItemText(gender_c, guiComboBoxGetSelected(gender_c)), guiComboBoxGetItemText(race_c, guiComboBoxGetSelected(race_c))
            local newgender, newrace = 0,0

            if gender1 == "Female" then
                newgender = 1
            end
            if race1 == "White" then
                newrace = 1
            elseif race1 == "Asian" then
                newrace = 2
            end

            closeCSGR()
            triggerServerEvent("newmods:updateGenderRace", localPlayer, upID, newgender,newrace)
        end
    end)

end
addEvent("modloader:chooseSkinGenderRace", true)
addEventHandler("modloader:chooseSkinGenderRace", root, chooseSkinGenderRace)


function closeCSGR()
    if isElement(gr.w) then
        destroyElement(gr.w)
        gr = {}
    end
end

-- chooseSkinGenderRace({id=1}) -- testing
