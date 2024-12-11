-- Fernando

-- ped must be clientside
--  DO NOT MOVE HIM xD
-- he's inside No Sense clothing Montgomery
local PEDX, PEDY, PEDZ = 160.0380859375, -81.189453125, 1001.8046875
local PEDI, PEDD = 18, 2
local PEDROT = 180
local PEDNAME = "Aria Rockefeller"
local PEDSKIN = 150

local jobPed = createPed(PEDSKIN, PEDX,PEDY,PEDZ)
setElementRotation( jobPed, 0,0, PEDROT)
setElementInterior( jobPed , PEDI)
setElementDimension( jobPed, PEDD)
setElementData( jobPed, "talk", 1, false )
setElementData( jobPed, "rpp.npc.type", "clothing_client")
setElementData( jobPed, "name", PEDNAME, false )
setElementData( jobPed, "rpp.npc.name", PEDNAME, false )
setElementFrozen(jobPed, true)
setPedAnimation ( jobPed, "COP_AMBIENT", "Coplook_loop", -1, true, false, false )


local drawing = false
local skinDrawing
local skinImage


-- image drawing
function setDrawingImg(on, skin)
	skinImage = nil
	skinDrawing = nil
	if on and skin then
		skinDrawing = skin
		if not drawing then
			addEventHandler("onClientRender", root, drawSkinImage)
			drawing = true
		end
	else
		if drawing then
			drawing = false
			removeEventHandler("onClientRender", root, drawSkinImage)
		end
	end
end

function drawSkinImage()

	if drawing and skinDrawing then

		local imgPath
		if not skinImage then
			-- iprint(skinDrawing)


			local skinImg = ("%03d"):format((tostring(skinDrawing.id)):gsub(":(.*)$", ""), 10)
			local p = ":account/img/" .. skinImg..".png"

			if fileExists(p) then
				imgPath = p
			else
				skinImage = exports["sarp-new-mods"]:getImage(tonumber(skinDrawing.id))
			end
		end
		local drawx, drawy = skinDrawing.x, skinDrawing.y
		local size = skinDrawing.size
	    dxDrawRectangle(drawx, drawy, size, size, tocolor(0,0,0,200), true)

        if imgPath or skinImage and isElement(skinImage.tex) then

            dxDrawImage(drawx, drawy, size, size, imgPath and imgPath or skinImage.tex, 0, 0, 0, tocolor(255,255,255,255), true)
        else
            local text = "Loading.."
            local length = dxGetTextWidth(text, 1, "default-bold-small")
            local x,y = drawx + size/2 -length/2, drawy + size/2 -10
            dxDrawText(text, x,y, x,y, tocolor(255,255,255,255), 1, "default-bold-small", "left", "top", false, false, true)
        end
	end
end

sW, sH = guiGetScreenSize()

local pedName = nil
list_ = {}
local selected_collection, selected_behalf = nil

function clearMyList()
	list_ = {}
end
addEvent("clearMyList", true)
addEventHandler("clearMyList", resourceRoot, clearMyList)

-- mods wizard gui // Fernando
local MG = {}

function openModsWizard(ped)


	default_ped.ped = ped
	default_ped.model = getElementModel(ped)
	default_ped.rotz = getPedRotation(ped, 'ZYX')
	default_ped.cloth = getElementData(ped, 'clothing:id')
	pedName = getElementData(ped, "rpp.npc.name")

	local y = 33

	local wW, wH = 250, 133+y
	MG.window = guiCreateWindow(sW/2 - wW/2, sH/2 - wH/2, wW, wH, "New Ped Modifications", false)


	MG.addMod = guiCreateButton(10, 25, wW - 20, 30, "Submit a Mod", false, MG.window)
	addEventHandler( "onClientGUIClick", MG.addMod, function()

		closeModsWizard()
		triggerEvent("modloader:forceOpenUpload", localPlayer)

	end, false)
	guiSetProperty(MG.addMod, "NormalTextColour", "FF00FF00")


	MG.myMods = guiCreateButton(10, 25+y, wW - 20, 30, "Personal Mods", false, MG.window)
	addEventHandler( "onClientGUIClick", MG.myMods, function()

		requestModsCollection()

	end, false)
	guiSetProperty(MG.myMods, "NormalTextColour", "FFFFFFFF")

	MG.facMods = guiCreateButton(10, 25+y*2, wW - 20, 30, "Faction Mods", false, MG.window)
	addEventHandler( "onClientGUIClick", MG.facMods, function()
		requestModsCollection(true)
	end, false)
	guiSetProperty(MG.facMods, "NormalTextColour", "FFFFFFFF")


	MG.close = guiCreateButton(10, 25+(y*3), wW - 20, 30, "Close", false, MG.window)


	addEventHandler( "onClientGUIClick", MG.close, closeModsWizard, false)
	addEventHandler('onClientCharacterLogout', localPlayer, closeModsWizard)
	-- triggerServerEvent('clothes:pedSay', localPlayer, pedName, 'greet')
end

function requestModsCollection(faction)
	guiSetEnabled(MG.window, false)
	triggerServerEvent("newmods:requestOpenWizard", localPlayer, faction)
end

function openModsCollection(uploads, factions)
	closeModsWizard()

	local title = getElementData(localPlayer, "account:username")
	if factions then
		title = "Faction"

		if uploads["ped"] then
			local count = 0
			for k, upload in pairs(uploads["ped"]) do
				count = count + 1
			end
			if count > 1 then
				title = "Factions"
			end
		end
	end

	local margin = 30
	MG.cwindow = guiCreateWindow(screen_width - width - 45, screen_height - height-110, width, height, "Mods - "..title, false)
	guiWindowSetMovable(MG.cwindow, false)
	guiSetAlpha(MG.cwindow, 0.95)
	guiWindowSetSizable(MG.cwindow, false)


	if not factions then


		MG.label1 = guiCreateLabel(10, height - 30, width - 20, 20, "Your accepted mods are displayed on this list." ,false, MG.cwindow)
		guiLabelSetHorizontalAlign(MG.label1, 'left')

		MG.grid = guiCreateGridList(10, 25, width-20, height - 60, false, MG.cwindow)

        MG.grid_col_upid = guiGridListAddColumn(MG.grid,"Upload ID",0.1)
        MG.grid_col_modelid = guiGridListAddColumn(MG.grid,"Skin ID",0.1)
        MG.grid_col_title = guiGridListAddColumn(MG.grid,"Title",0.5)
        MG.grid_col_purpose = guiGridListAddColumn(MG.grid,"Status",0.15)
        MG.grid_col_update = guiGridListAddColumn(MG.grid,"Upload Date",0.1)

        local skinUploads = uploads["ped"]
        if skinUploads then
        	for k, upload in pairs(skinUploads) do


	            local status = upload.status
	            local purpose = tonumber(upload.purpose)

	            if status == "Accepted" and (purpose == 1 or purpose == 0) then

	        		local row = guiGridListAddRow(MG.grid)

		            guiGridListSetItemText(MG.grid, row, MG.grid_col_upid, upload.upid, false, true)
		            guiGridListSetItemText(MG.grid, row, MG.grid_col_modelid, upload.modelid, false, true)

		            guiGridListSetItemText(MG.grid, row, MG.grid_col_title, upload.title, false, false)


		            if purpose == 1 then
		            	guiGridListSetItemText(MG.grid, row, MG.grid_col_purpose, "Exclusive", false, false)
		                guiGridListSetItemColor(MG.grid, row, MG.grid_col_purpose, 255, 231, 122)
		            elseif purpose == 0 then
		            	guiGridListSetItemText(MG.grid, row, MG.grid_col_purpose, "Global", false, false)
		            	guiGridListSetItemColor(MG.grid, row, MG.grid_col_purpose, 122, 255, 124)
		            end

		            guiGridListSetItemText(MG.grid, row, MG.grid_col_update, upload.uploadDate, false, false)
		        end

        	end

        	MG.change = guiCreateButton(width - 110 - 125, height - 30, 120, 25, '', false, MG.cwindow)
        	guiSetVisible(MG.change, false)

        	MG.obtain = guiCreateButton(width - 110 - 125 - 125, height - 30, 120, 25, '', false, MG.cwindow)
        	guiSetVisible(MG.obtain, false)

        	addEventHandler( "onClientGUIClick", MG.grid,
        	function (button)

        		local row, col = guiGridListGetSelectedItem(source)
			    if row ~= -1 and col ~= -1 then

			        local purpose = tostring(guiGridListGetItemText(source, row, 4))

			        if purpose == "Exclusive" then

			        	guiSetText(MG.change, "Distribute")
			        	guiSetProperty(MG.change, "NormalTextColour", "FF00FF00")
			        	guiSetVisible(MG.change, true)


			        	guiSetText(MG.obtain, "Obtain ($"..obtainCost..")")
			        	guiSetProperty(MG.obtain, "NormalTextColour", "FFFFFFFF")
			    		guiSetVisible(MG.obtain, true)
			        else

			        	guiSetText(MG.change, "Make Exclusive")
			        	guiSetProperty(MG.change, "NormalTextColour", "FFFFFF00")
			        	guiSetVisible(MG.change, true)

			        	guiSetText(MG.obtain, "Obtain")
			        	guiSetProperty(MG.obtain, "NormalTextColour", "FFFFFFFF")
			    		guiSetVisible(MG.obtain, true)
			        end


		        	local modelid = tonumber(guiGridListGetItemText(MG.grid, row, 2))
		        	selected_collection = modelid

		        	if exports["sarp-new-mods"]:isCustomMod(selected_collection, "ped") then
						setElementData(default_ped.ped, "skinID", selected_collection)
					else
						setElementData(default_ped.ped, "skinID", nil)
						setElementModel(default_ped.ped, selected_collection)
					end
					setPedAnimation ( default_ped.ped )

			    else
			    	resetPed()
			    	guiSetVisible(MG.change, false)
			    	guiSetVisible(MG.obtain, false)
			    end

        	end, false)


        	addEventHandler( "onClientGUIClick", MG.cwindow,
        	function (button)

        		if button == "left" then

        			local bt = guiGetText(source)

    				local row, col = guiGridListGetSelectedItem(MG.grid)
		        	local upid = tonumber(guiGridListGetItemText(MG.grid, row, 1))
		        	local modelid = tonumber(guiGridListGetItemText(MG.grid, row, 2))
			        local title = tostring(guiGridListGetItemText(MG.grid, row, 3))

        			if source == MG.change then


        				if bt == "Distribute" then

        					-- make global
							openConfirmChange(upid, modelid, "global")
        				else
        					-- make personal
							openConfirmChange(upid, modelid, "personal")
        				end

        			elseif source == MG.obtain then
        				if bt == "Obtain" then
        					triggerEvent("displayMesaage", localPlayer, "You can purchase these clothes at any clothing store.", "info")
        				else
        					if not exports.global:hasMoney(localPlayer, obtainCost) then
        						triggerEvent("displayMesaage", localPlayer, "You need $"..obtainCost.." to obtain one item of your skin.", "error")
        					else
        						-- get personal skin
        						triggerServerEvent("obtainSkinItem", localPlayer, modelid, obtainCost, title)
        					end
        				end
        			end

        		end
        	end)
        end


		local close = guiCreateButton(width - 110, height - 30, 100, 25, 'Close', false, MG.cwindow)
		addEventHandler('onClientGUIClick', close, closeModsCollection, false)

	else


		MG.label1 = guiCreateLabel(10, height - 30, width - 20, 20, "Accepted faction exclusive mods are displayed on this list." ,false, MG.cwindow)
		guiLabelSetHorizontalAlign(MG.label1, 'left')

		for facid, upl in pairs(uploads) do

			local skinUploads = upl["ped"]
			if skinUploads then

				MG.grid = guiCreateGridList(10, 25, width-20, height - 60, false, MG.cwindow)

		        MG.grid_col_facid = guiGridListAddColumn(MG.grid,"Faction ID",0.1)
		        MG.grid_col_upid = guiGridListAddColumn(MG.grid,"Upload ID",0.1)
		        MG.grid_col_modelid = guiGridListAddColumn(MG.grid,"Skin ID",0.1)
		        MG.grid_col_title = guiGridListAddColumn(MG.grid,"Title",0.5)
		        MG.grid_col_purpose = guiGridListAddColumn(MG.grid,"Status",0.2)
		        MG.grid_col_update = guiGridListAddColumn(MG.grid,"Upload Date",0.1)

				for k, upload in pairs(skinUploads) do

		            local status = upload.status
		            local purpose = tonumber(upload.purpose)

		            if status == "Accepted" and (purpose < 0) then
		            	-- accepted faction mod

		        		local row = guiGridListAddRow(MG.grid)

			            guiGridListSetItemText(MG.grid, row, MG.grid_col_facid, facid, false, true)
			            guiGridListSetItemText(MG.grid, row, MG.grid_col_upid, upload.upid, false, true)
			            guiGridListSetItemText(MG.grid, row, MG.grid_col_modelid, upload.modelid, false, true)

			            guiGridListSetItemText(MG.grid, row, MG.grid_col_title, upload.title, false, false)


		            	guiGridListSetItemText(MG.grid, row, MG.grid_col_purpose, "Exclusive", false, false)
		                guiGridListSetItemColor(MG.grid, row, MG.grid_col_purpose, 255, 231, 122)

			            guiGridListSetItemText(MG.grid, row, MG.grid_col_update, upload.uploadDate, false, false)
			        end
		        end


	        	MG.change = guiCreateButton(width - 110 - 125, height - 30, 120, 25, '', false, MG.cwindow)
	        	guiSetVisible(MG.change, false)

	        	MG.obtain = guiCreateButton(width - 110 - 125 - 125, height - 30, 120, 25, '', false, MG.cwindow)
	        	guiSetVisible(MG.obtain, false)

	        	addEventHandler( "onClientGUIClick", MG.grid,
	        	function (button)

	        		local row, col = guiGridListGetSelectedItem(source)
				    if row ~= -1 and col ~= -1 then


			        	local modelid = tonumber(guiGridListGetItemText(MG.grid, row, 3))
			        	selected_collection = modelid

			        	if exports["sarp-new-mods"]:isCustomMod(selected_collection, "ped") then
							setElementData(default_ped.ped, "skinID", selected_collection)
						else
							setElementData(default_ped.ped, "skinID", nil)
							setElementModel(default_ped.ped, selected_collection)
						end
						setPedAnimation ( default_ped.ped )

				        guiSetText(MG.change, "Distribute")
			        	guiSetProperty(MG.change, "NormalTextColour", "FF00FF00")
			        	guiSetVisible(MG.change, true)


			        	guiSetText(MG.obtain, "Obtain ($"..obtainCost..")")
			        	guiSetProperty(MG.obtain, "NormalTextColour", "FFFFFFFF")
			    		guiSetVisible(MG.obtain, true)

				    else

				    	resetPed()
				    	guiSetVisible(MG.change, false)
				    	guiSetVisible(MG.obtain, false)
				    end

	        	end, false)

	        	addEventHandler( "onClientGUIClick", MG.cwindow,
	        	function (button)

	        		if button == "left" then

	        			local bt = guiGetText(source)

	    				local row, col = guiGridListGetSelectedItem(MG.grid)
			        	local upid = tonumber(guiGridListGetItemText(MG.grid, row, 2))
			        	local modelid = tonumber(guiGridListGetItemText(MG.grid, row, 3))
			        	local title = tostring(guiGridListGetItemText(MG.grid, row, 4))

	        			if source == MG.change then


	        				if bt == "Distribute" then

	        					triggerEvent("displayMesaage", localPlayer, "Only a Lead Admin+ can distribute a faction exclusive mod.", "info")
	        				end

	        			elseif source == MG.obtain then
	        				if not exports.global:hasMoney(localPlayer, obtainCost) then
	        					triggerEvent("displayMesaage", localPlayer, "You need $"..obtainCost.." to obtain one item of your skin.", "error")
        					else
        						-- get faction skin
        						triggerServerEvent("obtainSkinItem", localPlayer, modelid, obtainCost, title)
        					end
	        			end

	        		end
	        	end)
			end

		end

	end

	local close = guiCreateButton(width - 110, height - 30, 100, 25, 'Close', false, MG.cwindow)
	addEventHandler('onClientGUIClick', close, closeModsCollection, false)
	addEventHandler('onClientCharacterLogout', localPlayer, closeModsCollection)
	setSoundVolume(playSound(":resources/inv_open.aac"), 0.3)
end
addEvent("clothes:openModsCollection", true)
addEventHandler("clothes:openModsCollection", root, openModsCollection)

function closeModsCollection()
	if isElement(MG.cwindow) then
		destroyElement(MG.cwindow)
	end
	selected_collection = nil
	resetPed()
end

function openConfirmChange(upid, modelid, tt)
	guiSetVisible(MG.cwindow, false)

	local thisW, thisH = width/1.5, height/2

	local margin = 30
	MG.cwindow2 = guiCreateWindow(screen_width - thisW - 45, screen_height - thisH-110, thisW, thisH, "Confirmation", false)
	guiWindowSetMovable(MG.cwindow2, false)
	guiSetAlpha(MG.cwindow2, 0.95)
	guiWindowSetSizable(MG.cwindow2, false)

	MG.label1 = guiCreateLabel(10, 30, thisW - 20, thisH - (30*2), "Are you sure you wish to make this Skin ID #"..modelid.." "..tt.."?" ,false, MG.cwindow2)
	guiLabelSetHorizontalAlign(MG.label1, 'center')


	local accept = guiCreateButton(thisW/2 + 50, thisH - 30, 100, 25, 'Yes', false, MG.cwindow2)
	addEventHandler('onClientGUIClick', accept, function()
		closeModsConfirm()
		closeModsCollection()
		triggerServerEvent("newmods:makeModGlobal", localPlayer, "skin", upid, (tt=="personal"), true)
	end, false)
	guiSetProperty(accept, "NormalTextColour", "FF00FF00")

	local close = guiCreateButton(thisW/2 - 150, thisH - 30, 100, 25, 'Cancel', false, MG.cwindow2)
	addEventHandler('onClientGUIClick', close, function()
		closeModsConfirm()
		guiSetVisible(MG.cwindow, true)
	end, false)
	addEventHandler('onClientCharacterLogout', localPlayer, closeModsConfirm)
	setSoundVolume(playSound(":resources/inv_open.aac"), 0.3)
end

function closeModsConfirm()
	if isElement(MG.cwindow2) then
		destroyElement(MG.cwindow2)
	end
end


function closeModsWizard()
	if isElement(MG.window) then
		removeEventHandler('onClientCharacterLogout', localPlayer, closeModsWizard)
		destroyElement(MG.window)
		MG = {}
	end
end


-- clothes textures wizard gui


local GUIEditor = {
    button = {},
    window = {}
}

function openClothesWizard(ped)
	closeClothesWizard()

	default_ped.ped = ped
	default_ped.model = getElementModel(ped)
	default_ped.rotz = getPedRotation(ped, 'ZYX')
	default_ped.cloth = getElementData(ped, 'clothing:id')
	pedName = getElementData(ped, "rpp.npc.name")

	local y = 0
	local ys = 36
	local fid = canUploadForFaction(localPlayer)
	if fid then
		y = 36
	end

	GUIEditor.window[1] = guiCreateWindow(1031, 453, 262, 147+y, "Custom Skin Designs", false)
	exports.global:centerWindow(GUIEditor.window[1])
	guiWindowSetSizable(GUIEditor.window[1], false)
	guiWindowSetMovable(GUIEditor.window[1], false)

	GUIEditor.button[2] = guiCreateButton(9, 32, 243, 32, "Submit a Design", false, GUIEditor.window[1])
	guiSetProperty(GUIEditor.button[2], "NormalTextColour", "FF00FF00")

	GUIEditor.button[1] = guiCreateButton(9, 32+ys, 243, 32, "Personal Designs", false, GUIEditor.window[1])
	guiSetProperty(GUIEditor.button[1], "NormalTextColour", "FFFFFFFF")

	if y > 0 then
		GUIEditor.button[4] = guiCreateButton(9, 68+y, 243, 32, "Faction Designs", false, GUIEditor.window[1])
		guiSetProperty(GUIEditor.button[4], "NormalTextColour", "FFFFFFFF")
	end

	GUIEditor.button[3] = guiCreateButton(9, 32+ys+ys+y, 243, 32, "Close", false, GUIEditor.window[1])

	addEventHandler('onClientGUIClick', GUIEditor.window[1], function ()
		if source == GUIEditor.button[3] then
			closeClothesWizard()
		elseif source == GUIEditor.button[2] then
			if isModerator(localPlayer) then
				startWizard_1()
			else
				startWizard_1()
			end
		elseif source == GUIEditor.button[1] then
			listMyClothes()
		elseif source == GUIEditor.button[4] then
			listMyClothes(nil, fid)
		end
	end)

	addEventHandler('onClientCharacterLogout', localPlayer, closeClothesWizard)
	-- triggerServerEvent('clothes:pedSay', localPlayer, pedName, 'greet')
end

function closeClothesWizard()
	if GUIEditor.window[1] and isElement(GUIEditor.window[1]) then
		removeEventHandler('onClientCharacterLogout', localPlayer, closeClothesWizard)
		destroyElement(GUIEditor.window[1])
		setDrawingImg(false)
		GUIEditor.window[1] = nil
		selected_collection = nil
		resetPed()
	end
end

function callback_startWizard_1(ok)
	if ok then

	else
		guiSetText(GUIEditor.button[2], "Submit a new design proposal "..(isModerator(localPlayer) and '' or '($25)'))
		guiSetEnabled(GUIEditor.window[1], true)
		playSoundFrontEnd(4)
	end
end
addEvent('clothes:uploadQuotaCheck', true)
addEventHandler('clothes:uploadQuotaCheck', localPlayer, callback_startWizard_1)

local GUIEditor1 = {
    label = {},
    button = {},
    window = {},
    combobox = {}
}
-- 15 hour limit below
function startWizard_1()
	if (getElementData(localPlayer, 'hoursplayed') or 0) < 0 then
		playSoundFrontEnd(4)
		outputChatBox("You must have played at least 15 hours on this character to submit a new design.", 255,0,0)
	elseif not exports.global:hasMoney(localPlayer, 25) then
		playSoundFrontEnd(4)
		outputChatBox("You need $25 to submit a new design proposal.", 255,0,0)
	else
		local s = getSkinSlots(localPlayer)
		local current = #list_
		if current >= s then
			triggerEvent("displayMesaage", localPlayer, "You have "..current.." out of maximum "..s.." custom skins. Visit F10 - Premium Features to obtain more!", 'info')
			return
		end

		closeWizard_1()
		closeClothesWizard()
		closeWindow()
		--playSoundFrontEnd(11)

		GUIEditor1.window[1] = guiCreateWindow(639, 397, 193, 300, "New design proposal", false)
		guiWindowSetSizable(GUIEditor1.window[1], false)
		exports.global:centerWindow(GUIEditor1.window[1])
		guiWindowSetMovable(GUIEditor1.window[1], false)

		GUIEditor1.label[1] = guiCreateLabel(20, 25, 193 - 20*2, 21, "Vanilla          New", false, GUIEditor1.window[1])
		guiLabelSetHorizontalAlign(GUIEditor1.label[1], "center")

		GUIEditor1.combobox[1] = guiCreateComboBox(20, 47, 154/2, 300, "", false, GUIEditor1.window[1])
		GUIEditor1.combobox[2] = guiCreateComboBox(20+154/2, 47, 154/2, 300, "", false, GUIEditor1.window[1])

		local count = 0
		for k, skinid in pairs(normalSkins) do

			guiComboBoxAddItem(GUIEditor1.combobox[1], skinid)
			count = count + 1
		end

		local moddedSkins = getElementData(getRootElement(), "moddedSkins")
		table.sort(moddedSkins, function( a, b ) return a.modelid < b.modelid end )
		for i, skin in pairs(moddedSkins) do

			if tonumber(skin.purpose) == 0 then
				guiComboBoxAddItem(GUIEditor1.combobox[2], skin.modelid)
				count = count + 1
			end
		end


		GUIEditor1.button[1] = guiCreateButton(15, 250, 74, 32, "Cancel", false, GUIEditor1.window[1])
		GUIEditor1.button[2] = guiCreateButton(101, 250, 74, 32, "Next", false, GUIEditor1.window[1])
		guiSetEnabled(GUIEditor1.button[2], false)

		GUIEditor1.label.skininfo = guiCreateLabel(16,78,193 - 16*2.5, 160, '' , false, GUIEditor1.window[1])
		guiLabelSetHorizontalAlign(GUIEditor1.label.skininfo, 'center', true)

		addEventHandler('onClientGUIClick', GUIEditor1.window[1], clickWizard_1)
		addEventHandler('onClientCharacterLogout', localPlayer, closeWizard_1)
		addEventHandler('onClientGUIComboBoxAccepted', GUIEditor1.combobox[1], collectionSelect)
		addEventHandler('onClientGUIComboBoxAccepted', GUIEditor1.combobox[2], collectionSelect)
	end
end

function closeWizard_1()
	if GUIEditor1.window[1] and isElement(GUIEditor1.window[1]) then
		removeEventHandler('onClientGUIClick', GUIEditor1.window[1], clickWizard_1)
		removeEventHandler('onClientCharacterLogout', localPlayer, closeWizard_1)
		removeEventHandler('onClientGUIComboBoxAccepted', GUIEditor1.combobox[1], collectionSelect)
		removeEventHandler('onClientGUIComboBoxAccepted', GUIEditor1.combobox[2], collectionSelect)
		destroyElement(GUIEditor1.window[1])
		setDrawingImg(false)
		GUIEditor1.window[1] = nil
		resetPed()
	end
end


function warnModdedCustom()

	local n = false

	local moddedSkins = getElementData(getRootElement(), "moddedSkins")
	for i, skin in pairs(moddedSkins) do

		if tonumber(skin.modelid) == tonumber(selected_collection) then
			n = true
			break
		end
	end

	if n then
		outputChatBox("INFO: The system currently only applies your image to the first texture in finds in the TXD.", 255,194,14)
	end
end

function clickWizard_1()
	if source == GUIEditor1.button[1] then
		closeWizard_1()
	elseif source == GUIEditor1.button[2] then


		local fid = canUploadForFaction(localPlayer)
		if fid then
			startWizard_2_faction(fid)
		else
			startWizard_2()
		end
	end
end

local GUIEditor2 = {
    button = {},
    window = {},
    edit = {},
    label = {},
    radiobutton = {},
}

function startWizard_2_faction(fid)
	closeWizard_2_faction()
	closeWizard_1()
	playSoundFrontEnd(12)
	GUIEditor2.window[1] = guiCreateWindow(709, 366, 323, 135, "New design proposal", false)
	guiWindowSetSizable(GUIEditor2.window[1], false)
	guiWindowSetMovable(GUIEditor2.window[1], false)

	exports.global:centerWindow(GUIEditor2.window[1])

	GUIEditor2.button[1] = guiCreateButton(11, 98, 147, 27, "Back", false, GUIEditor2.window[1])
	GUIEditor2.button[2] = guiCreateButton(165, 98, 147, 27, "Next", false, GUIEditor2.window[1])

	local fname = exports["faction-system"]:getFactionName(fid)
	GUIEditor2.label[1] = guiCreateLabel(10, 27, 303, 18, "I am submiting this for benefits on behalf of...", false, GUIEditor2.window[1])
    GUIEditor2.radiobutton[1] = guiCreateRadioButton(27, 48, 286, 15, exports.global:getPlayerName(localPlayer), false, GUIEditor2.window[1])
    GUIEditor2.radiobutton[2] = guiCreateRadioButton(27, 69, 286, 15, exports["faction-system"]:getFactionName(fid) , false, GUIEditor2.window[1])
    guiRadioButtonSetSelected(GUIEditor2.radiobutton[1], true)

    addEventHandler('onClientGUIClick', GUIEditor2.window[1], function ()
		if source == GUIEditor2.button[1] then
			closeWizard_2_faction()
			startWizard_1()
		elseif source == GUIEditor2.button[2] then
			warnModdedCustom()
			selected_behalf = guiRadioButtonGetSelected(GUIEditor2.radiobutton[2]) -- faction
			startWizard_2()
		end
	end)

	addEventHandler('onClientCharacterLogout', localPlayer, closeWizard_2_faction)
end

function closeWizard_2_faction()
	if GUIEditor2.window[1] and isElement(GUIEditor2.window[1]) then
		destroyElement(GUIEditor2.window[1])
		setDrawingImg(false)
	end
	removeEventHandler('onClientCharacterLogout', localPlayer, closeWizard_2_faction)
end

function startWizard_2()
	closeWizard_2()
	closeWizard_2_faction()
	closeWizard_1()
	playSoundFrontEnd(12)
	guiSetInputEnabled(true)
	GUIEditor2.window[1] = guiCreateWindow(709, 366, 323, 135, "New design proposal", false)
	guiWindowSetSizable(GUIEditor2.window[1], false)
	guiWindowSetMovable(GUIEditor2.window[1], false)
	exports.global:centerWindow(GUIEditor2.window[1])

	GUIEditor2.button[1] = guiCreateButton(11, 98, 147, 27, "Back", false, GUIEditor2.window[1])
	GUIEditor2.button[2] = guiCreateButton(165, 98, 147, 27, "Upload", false, GUIEditor2.window[1])

	GUIEditor2.label[1] = guiCreateLabel(10, 25, 105, 23, "Image file URL:", false, GUIEditor2.window[1])
	guiLabelSetVerticalAlign(GUIEditor2.label[1], "center")

	GUIEditor2.edit[1] = guiCreateEdit(115, 25, 197, 23, "", false, GUIEditor2.window[1])
	guiEditSetMaxLength(GUIEditor2.edit[1], 200)

	GUIEditor2.label[3] = guiCreateLabel(10, 50, 105, 23, "Clothes description:", false, GUIEditor2.window[1])
	guiLabelSetVerticalAlign(GUIEditor2.label[3], "center")

	GUIEditor2.edit[2] = guiCreateEdit(115, 50, 197, 23, "", false, GUIEditor2.window[1])
	guiEditSetMaxLength(GUIEditor2.edit[2], 100)

	local maxSize = 100000 --100kb

	GUIEditor2.label[2] = guiCreateLabel(10, 73, 302, 18, "Example: http://i.imgur.com/MG9pkfl.png; Maximum filesize: "..tostring(maxSize/1000).."kb", false, GUIEditor2.window[1])
	guiSetFont(GUIEditor2.label[2], "default-small")
	guiLabelSetColor(GUIEditor2.label[2], 103, 103, 103)
	guiLabelSetHorizontalAlign(GUIEditor2.label[2], "right", false)
	guiLabelSetVerticalAlign(GUIEditor2.label[2], "center")

	addEventHandler('onClientGUIClick', GUIEditor2.window[1], function ()
		if source == GUIEditor2.button[1] then
			closeWizard_2()
			local fid = canUploadForFaction(localPlayer)
			if fid then
				startWizard_2_faction(fid)
			else
				startWizard_1()
			end
		elseif source == GUIEditor2.button[2] then
			local url = guiGetText(GUIEditor2.edit[1])
			local desc = guiGetText(GUIEditor2.edit[2])
			if string.len(url) < 1 then
				guiSetText(GUIEditor2.label[2], 'Please enter a direct image link.')
				playSoundFrontEnd(4)
			elseif string.len(desc) < 1 then
				guiSetText(GUIEditor2.label[2], 'Please describe how this design look like.')
				playSoundFrontEnd(4)
			elseif not exports.global:hasMoney(localPlayer, 25) then
				triggerServerEvent('clothes:pedSay', localPlayer, pedName, "Could I have $25 please?")
				playSoundFrontEnd(4)
			else
				guiSetText(GUIEditor2.label[2], 'Retrieving image from URL. Please wait..')
				guiSetEnabled(GUIEditor2.window[1], false)
				triggerServerEvent('clothes:wizard2Result', resourceRoot, url, desc, selected_collection, selected_behalf)
				playSoundFrontEnd(12)
			end
		end
	end)

	addEventHandler('onClientCharacterLogout', localPlayer, closeWizard_2)
end

function closeWizard_2()
	if GUIEditor2.window[1] and isElement(GUIEditor2.window[1]) then
		destroyElement(GUIEditor2.window[1])
		setDrawingImg(false)
		GUIEditor2.window[1] = nil
		resetPed()
		guiSetInputEnabled(false)
	end
	removeEventHandler('onClientCharacterLogout', localPlayer, closeWizard_2)
end

function wizard2Result(result, for_faction)
	if result == 'ok' then
		playSoundFrontEnd(12)
		listMyClothes(nil, for_faction)
	else
		guiSetText(GUIEditor2.label[2], result)
		guiSetEnabled(GUIEditor2.window[1], true)
		playSoundFrontEnd(4)
	end
end
addEvent('clothes:wizard2Result', true)
addEventHandler('clothes:wizard2Result', resourceRoot, wizard2Result)

function listMyClothes(list, for_faction)
	triggerEvent('npc:togShopWindow', localPlayer, false)
	closeClothesWizard()
	closeWizard_2()
	if window and isElement(window) then
		if list and exports.global:countTable(list) > 0 then
			list_ = list
		else
			list_ = {}
		end
		guiSetEnabled(window, true)
		guiSetVisible(loading_label, false)
		listCreateGuiElements(true)
	else
		local margin = 30
		window = guiCreateWindow(screen_width - width - 45, screen_height - height-110, width, height, "Designs - ".. (for_faction and (exports["faction-system"]:getFactionName(for_faction).."") or (exports.global:getPlayerName(localPlayer))), false)
		guiWindowSetMovable(window, false)
		guiSetEnabled(window, false)
		guiSetAlpha(window, 0.95)
		guiWindowSetSizable(window, false)

		loading_label = guiCreateLabel(10, 25, width - 20, height - 60, "Loading.." ,false, window)
		guiLabelSetHorizontalAlign(loading_label, 'center')
		guiLabelSetVerticalAlign(loading_label, 'center')

		local close = guiCreateButton(width - 110, height - 30, 100, 25, 'Close', false, window)
		addEventHandler('onClientGUIClick', close, closeWindow, false)
		addEventHandler('onClientCharacterLogout', localPlayer, closeWindow)
		--Now request custom clothes from server
		triggerServerEvent('clothes:list', localPlayer, nil, for_faction)
		setSoundVolume(playSound(":resources/inv_open.aac"), 0.3)
	end

end
addEvent('clothes:listMyClothes', true)
addEventHandler('clothes:listMyClothes', root, listMyClothes)

local GUIEditor3 = {
    edit = {},
    button = {},
    window = {},
    label = {},
    combobox = {}
}

function editMyClothes(index)
	close_editMyClothes()
	local clothes = list_[index]
	if clothes then
		toggleGui( window, false )
		guiSetInputEnabled(true)
		GUIEditor3.window[1] = guiCreateWindow(1031, 640, 338, 235, "Editing design #"..index, false)
		guiWindowSetSizable(GUIEditor3.window[1], false)
		guiWindowSetMovable(GUIEditor3.window[1], false)

		guiSetAlpha(GUIEditor3.window[1], 0.95)
		exports.global:centerWindow(GUIEditor3.window[1])

		GUIEditor3.button[1] = guiCreateButton(175, 136, 149, 25, "Save", false, GUIEditor3.window[1])
		guiSetProperty(GUIEditor3.button[1], "NormalTextColour", "ff97ff7a")

		GUIEditor3.label[1] = guiCreateLabel(16, 36, 149, 18, "Vanilla/New Skins:", false, GUIEditor3.window[1])

		GUIEditor3.combobox[1] = guiCreateComboBox(16, 54, 149/2, 25, "", false, GUIEditor3.window[1])
		GUIEditor3.combobox[2] = guiCreateComboBox(16+149/2, 54, 149/2, 25, "", false, GUIEditor3.window[1])


		local n = false
		for k, skinid in pairs(normalSkins) do
			if tonumber(clothes.skin) == skinid then
				n = true
				break
			end
		end

		if n then
			guiComboBoxAddItem(GUIEditor3.combobox[1], clothes.skin)
		else
			guiComboBoxAddItem(GUIEditor3.combobox[2], clothes.skin)
		end

		local count = 0
		for k, skinid in pairs(normalSkins) do
			if skinid ~= clothes.skin then

				guiComboBoxAddItem(GUIEditor3.combobox[1], skinid)
				count = count + 1
			end
		end

		local moddedSkins = getElementData(getRootElement(), "moddedSkins")
		table.sort(moddedSkins, function( a, b ) return a.modelid < b.modelid end )
		for i, skin in pairs(moddedSkins) do

			if tonumber(skin.purpose) == 0 then
				local skinid = skin.modelid
				if skinid ~= clothes.skin then

					guiComboBoxAddItem(GUIEditor3.combobox[2], skinid)
					count = count + 1
				end
			end
		end
		exports.global:guiComboBoxAdjustHeight ( GUIEditor3.combobox[1], count )
		exports.global:guiComboBoxAdjustHeight ( GUIEditor3.combobox[2], count )

		if n then
			guiComboBoxSetSelected ( GUIEditor3.combobox[1], 0 )
		else
			guiComboBoxSetSelected ( GUIEditor3.combobox[2], 0 )
		end


		guiSetEnabled(GUIEditor3.combobox[1], canEditModel(clothes))
		guiSetEnabled(GUIEditor3.combobox[2], canEditModel(clothes))

		local size = 145
		local wx,wy = guiGetPosition(GUIEditor3.window[1], false)
		local ww,wh = guiGetSize(GUIEditor3.window[1], false)

		local ix, iy = wx + ww/2-size/2, wy - size - 6
		local theSkin = {id = tonumber(clothes.skin), x = ix, y = iy, size = size}

		setDrawingImg(true, theSkin)


		local info2 = ""
		local info = getSkinBasicInfo(tonumber(clothes.skin))
		if type(info)=="table" then
			info2 = info.title.."\n\nContact the creator for the texture image:\nUsername: "..(exports.cache:getUsernameFromId(info.uploadBy))
		else
			info2 = info
		end

		GUIEditor3.label.skininfo = guiCreateLabel(16,78,338/2 -16*2.5, 160, info2, false, GUIEditor3.window[1])
		guiLabelSetHorizontalAlign(GUIEditor3.label.skininfo, 'left', true)


		GUIEditor3.label[2] = guiCreateLabel(175, 36, 149, 18, "Price: ($50~$10,000)", false, GUIEditor3.window[1])
		GUIEditor3.edit[1] = guiCreateEdit(175, 54, 149, 25, clothes.price or defaultSkinCost, false, GUIEditor3.window[1])
		guiEditSetMaxLength(GUIEditor3.edit[1], 5)
		guiSetEnabled(GUIEditor3.edit[1], canEditPrice(clothes))

		GUIEditor3.label[3] = guiCreateLabel(175, 83, 149, 18, "Clothes description:", false, GUIEditor3.window[1])
		GUIEditor3.edit[2] = guiCreateEdit(175, 101, 149, 25, clothes.description or "A set of clean clothes", false, GUIEditor3.window[1])
		guiEditSetMaxLength(GUIEditor3.edit[2], 200)

		GUIEditor3.button[2] = guiCreateButton(175, 165, 149, 25, "Delete", false, GUIEditor3.window[1])
		guiSetProperty(GUIEditor3.button[2], "NormalTextColour", "ffff0000")
		--guiSetEnabled(GUIEditor3.button[2],isDeletable(clothes))

		GUIEditor3.button[3] = guiCreateButton(175, 195, 149, 25, "Cancel", false, GUIEditor3.window[1])
		guiSetProperty(GUIEditor3.button[3], "NormalTextColour", "ff858585")


		addEventHandler('onClientCharacterLogout', localPlayer, close_editMyClothes)
		addEventHandler('onClientGUIComboBoxAccepted', GUIEditor3.combobox[1], collectionSelect)
		addEventHandler('onClientGUIComboBoxAccepted', GUIEditor3.combobox[2], collectionSelect)

		addEventHandler('onClientGUIClick', GUIEditor3.window[1], function ()
			-- close
			if source == GUIEditor3.button[3] then
				close_editMyClothes()
			-- save
			elseif source == GUIEditor3.button[1] then
				local a = false
				local citem = guiComboBoxGetSelected ( GUIEditor3.combobox[1] )
				if citem == -1 then
					citem = guiComboBoxGetSelected ( GUIEditor3.combobox[2] )
					a = true
				end

				local skin = tonumber( guiComboBoxGetItemText ( GUIEditor3.combobox[1] , citem ))
				if a then
					skin = tonumber( guiComboBoxGetItemText ( GUIEditor3.combobox[2] , citem ))
					sendModWarning()
				end

				local price = guiGetText(GUIEditor3.edit[1])
				price = tonumber(price) and exports.global:roundNumber(tonumber(price)) or nil
				local desc = guiGetText(GUIEditor3.edit[2])
				if not price or price > 10000 or price < 50 then
					playSoundFrontEnd(4)
					guiSetText(GUIEditor3.window[1], "Error! Price must be ranging from $50 up to $10,000.")
				elseif string.len(desc) < 1 then
					playSoundFrontEnd(4)
					guiSetText(GUIEditor3.window[1], "Error! Description is required.")
				else
					list_[index].price=price
					list_[index].description=desc
					list_[index].skin=skin
					triggerServerEvent('clothing:save', resourceRoot, list_[index], localPlayer)
					close_editMyClothes()
					closeWindow()
				end
			-- delete
			elseif source == GUIEditor3.button[2] then
				if isDeletable( clothes ) then
					deleteMyClothes( index, true )
				else
					-- Checking on server if there's any clothes item for this instance existed anywhere in game.
					triggerServerEvent( 'clothes:deleteMyClothes', resourceRoot, index )
					guiSetText( GUIEditor3.button[2], 'Deleting...' )
					toggleGui( GUIEditor3.window[1], false )
				end
			end
		end)
	end
end

-- delete the file client side.
function deleteClientside(id)
    local path = getPath( id )
    if fileExists( path ) then
        fileDelete( path )
    end
end
addEvent("clothes:deleteFile", true)
addEventHandler("clothes:deleteFile", resourceRoot, deleteClientside)

function deleteMyClothes( index, ok, why )
	if ok then
		-- delete the file client side.
		deleteClientside(index)
		-- delete server side
		triggerServerEvent( 'clothing:delete', resourceRoot, index, "deleteMyClothes" )
		close_editMyClothes()
		closeWindow()
	else
		exports.global:playSoundError()
		exports.hud:sendBottomNotification( localPlayer, "no/sense", "This clothing design can not be removed. "..why )
		if GUIEditor3.button[2] and isElement( GUIEditor3.button[2] ) then
			guiSetText( GUIEditor3.button[2], "Delete" )
		end
		toggleGui( GUIEditor3.window[1], true )
	end
end
addEvent( 'clothes:deleteMyClothes', true )
addEventHandler( 'clothes:deleteMyClothes', resourceRoot, deleteMyClothes )

function close_editMyClothes()
	if GUIEditor3.window[1] and isElement(GUIEditor3.window[1]) then
		removeEventHandler('onClientCharacterLogout', localPlayer, close_editMyClothes)
		removeEventHandler('onClientGUIComboBoxAccepted', GUIEditor3.combobox[1], collectionSelect)
		removeEventHandler('onClientGUIComboBoxAccepted', GUIEditor3.combobox[2], collectionSelect)
		destroyElement(GUIEditor3.window[1])
		setDrawingImg(false)
		GUIEditor3.window[1] = nil
		guiSetInputEnabled(false)
		toggleGui( window, true )
	end
end

function collectionSelect()
	if source == GUIEditor1.combobox[1] or source == GUIEditor1.combobox[2] then

		setDrawingImg(false)
		if source == GUIEditor1.combobox[1] then
			guiComboBoxSetSelected(GUIEditor1.combobox[2], -1)
		else
			guiComboBoxSetSelected(GUIEditor1.combobox[1], -1)
		end

		local item = guiComboBoxGetSelected ( source )
		selected_collection = tonumber( guiComboBoxGetItemText ( source, item ))


		local size = 145
		local wx,wy = guiGetPosition(GUIEditor1.window[1], false)
		local ww,wh = guiGetSize(GUIEditor1.window[1], false)


		local theSkin = {id = selected_collection, x = wx + ww/2-size/2, y = wy - size - 6, size = size}
		setDrawingImg(true, theSkin)

		guiSetEnabled(GUIEditor1.button[2], true)

		local info2 = ""
		local info = getSkinBasicInfo(selected_collection)
		if type(info)=="table" then
			info2 = info.title.."\n\nContact the creator for the texture image:\nUsername: "..(exports.cache:getUsernameFromId(info.uploadBy))
		else
			info2 = info
		end
		guiSetText(GUIEditor1.label.skininfo , info2)

	elseif source == GUIEditor3.combobox[1] or source == GUIEditor3.combobox[2] then

		setDrawingImg(false)

		if source == GUIEditor3.combobox[1] then
			guiComboBoxSetSelected(GUIEditor3.combobox[2], -1)
		else
			guiComboBoxSetSelected(GUIEditor3.combobox[1], -1)
		end

		local item = guiComboBoxGetSelected ( source )
		selected_collection = tonumber( guiComboBoxGetItemText ( source , item ))

		local size = 145
		local wx,wy = guiGetPosition(GUIEditor3.window[1], false)
		local ww,wh = guiGetSize(GUIEditor3.window[1], false)


		local theSkin = {id = selected_collection, x = wx + ww/2-size/2, y = wy - size - 6, size = size}
		setDrawingImg(true, theSkin)

		local info2 = ""
		local info = getSkinBasicInfo(selected_collection)
		if type(info)=="table" then
			info2 = info.title.."\n\nContact the creator for the texture image:\nUsername: "..(exports.cache:getUsernameFromId(info.uploadBy))
		else
			info2 = info
		end

		guiSetText(GUIEditor3.label.skininfo , info2)
	end
end

local GUIEditor4 = {
    button = {},
    window = {},
    label = {}
}

function openManu(cid)
	if window and isElement(window) then
		guiSetEnabled(window, false)
	end
	GUIEditor4.window[1] = guiCreateWindow(1002, 246, 500, 400, "Welcome to no/sense Clothing Manufactor!", false)
	guiWindowSetSizable(GUIEditor4.window[1], false)
	guiWindowSetMovable(GUIEditor4.window[1], false)
	exports.global:centerWindow(GUIEditor4.window[1])

	GUIEditor4.button[1] = guiCreateButton(388, 354, 87, 27, "Next", false, GUIEditor4.window[1])
	GUIEditor4.button[2] = guiCreateButton(291, 354, 87, 27, "Close", false, GUIEditor4.window[1])
    GUIEditor4.button[3] = guiCreateButton(20, 354, 250, 27, "Manufacture Instantly ((50 GCs))", false, GUIEditor4.window[1])
    guiSetVisible(GUIEditor4.button[3], false)

	local intro = "Welcome to no/sense Clothing Manufactor!\n\nOur goal is to help you, our clients, to manufacture new or existing clothing lines"
		.." in an ethically responsible way.\n\nWe are able to source all materials you will need to make your clothing, we're able to ship your merchandise worldwide after production "
		.."is completed. We can be your agent and do all this work for you. We save you time and money by taking the hassle out of having to communicate with multiple people, we will be"
		.." your main contact point for everything you need.\n\nWe have a well established network and team of suppliers and manufacturers that we have built strong working relationships"
		.." with which will all be necessary to get your brand off to a strong start. Whether you are an established professional designer or someone with a great idea that you want your"
		.." shot in fashion, the team at no/sense Clothing Manufacturing can help you!"
	local cloth_info = nil
	GUIEditor4.label[1] = guiCreateLabel(26, 34, 443, 302, intro, false, GUIEditor4.window[1])
	guiLabelSetHorizontalAlign(GUIEditor4.label[1], "left", true)
	guiLabelSetVerticalAlign(GUIEditor4.label[1], "center")

	addEventHandler('onClientGUIClick', GUIEditor4.window[1], function ()
		if source == GUIEditor4.button[1] then
			if guiGetText(GUIEditor4.button[1]) == 'Next' then
				local clothing = list_[cid]
				if clothing and not cloth_info then
					cloth_info = 	"Clothes ID: "..clothing.id.."\n"..
									"Collection ((Base skin)): "..clothing.skin.."\n"..
									"Description: "..clothing.description.."\n"..
									"Designer: "..clothing.creator_charname.."\n"..
									"Designed Date: "..(clothing.fdate or exports.datetime:formatTimeInterval(clothing.date)).."\n"..
									"\n\nPlease make sure the draft is flawless before manufacturing!"
				end
				guiSetText(GUIEditor4.label[1], cloth_info or "Errors occurred while fetching design info.")
				guiLabelSetHorizontalAlign(GUIEditor4.label[1], "center", true)
				guiSetText(GUIEditor4.button[2], 'Back')
				guiSetText(GUIEditor4.button[1], 'Manufacture')
                -- guiSetVisible(GUIEditor4.button[3], true)
			elseif guiGetText(GUIEditor4.button[1]) == 'Manufacture' then
				playSoundFrontEnd(6)
				if triggerServerEvent('clothes:manufacture', resourceRoot, cid) then
					guiSetEnabled(GUIEditor4.window[1], false)
					guiSetEnabled(GUIEditor4.button[1], false)
				end
			end
		elseif source == GUIEditor4.button[2] then
			if guiGetText(GUIEditor4.button[2]) == 'Close' then
				closeManu()
			elseif guiGetText(GUIEditor4.button[2]) == 'Back' then
				guiSetText(GUIEditor4.button[1], 'Next')
				guiSetText(GUIEditor4.button[2], 'Close')
				guiSetText(GUIEditor4.label[1], intro)
				guiLabelSetHorizontalAlign(GUIEditor4.label[1], "left", true)
			end
        elseif source == GUIEditor4.button[3] and guiGetVisible(GUIEditor4.button[3]) then
            playSoundFrontEnd(6)
            if triggerServerEvent('clothes:manufacture', resourceRoot, cid, true) then
                guiSetEnabled(GUIEditor4.window[1], false)
                guiSetEnabled(GUIEditor4.button[1], false)
            end
		end
	end)

	addEventHandler('onClientCharacterLogout', localPlayer, closeManu)
end

function closeManu()
	if GUIEditor4.window[1] and isElement(GUIEditor4.window[1]) then
		removeEventHandler('onClientCharacterLogout', localPlayer, closeManu)
		destroyElement(GUIEditor4.window[1])
		setDrawingImg(false)
		GUIEditor4.window[1] = nil
		if window and isElement(window) then
			guiSetEnabled(window, true)
			closeWindow()--close all
		end
	end
end

function callback_Manu(result, why)
	if GUIEditor4.window[1] and isElement(GUIEditor4.window[1]) then
		guiSetEnabled(GUIEditor4.window[1], true)
		guiSetEnabled(GUIEditor4.button[1], false)
        guiSetEnabled(GUIEditor4.button[3], false)
		guiSetText(GUIEditor4.button[2], 'Close')
		guiSetText(GUIEditor4.label[1], why)
	end
end
addEvent('clothes:callback_Manu', true)
addEventHandler('clothes:callback_Manu', resourceRoot, callback_Manu)

local GUIEditor5 = {
    button = {},
    window = {},
    label = {}
}

function openDist(cid)
	if window and isElement(window) then
		guiSetEnabled(window, false)
	end
	GUIEditor5.window[1] = guiCreateWindow(1002, 246, 500, 400, "Welcome to no/sense Distribution System!", false)
	guiWindowSetSizable(GUIEditor5.window[1], false)
	guiWindowSetMovable(GUIEditor5.window[1], false)
	exports.global:centerWindow(GUIEditor5.window[1])

	GUIEditor5.button[1] = guiCreateButton(388, 354, 87, 27, "Close", false, GUIEditor5.window[1])
	GUIEditor5.button[2] = guiCreateButton(291, 354, 87, 27, "Get Product", false, GUIEditor5.window[1])
	-- GUIEditor5.button[3] = guiCreateButton(194, 354, 87, 27, "Distribute Globally", false, GUIEditor5.window[1])
	
	-- GUIEditor5.button[4] = guiCreateButton(97, 354, 87, 27, "Sell to no/sense", false, GUIEditor5.window[1])
	GUIEditor5.button[4] = guiCreateButton(97, 354, 87*2, 27, "Distribute Globally", false, GUIEditor5.window[1])--renamed
	guiSetProperty(GUIEditor5.button[4], "NormalTextColour", "FF00FF00")

	local intro = "Welcome to no/sense Distribution System!\n\nOur goal is to help you, our clients, to manufacture new or existing clothing lines"
		.." in an ethically responsible way.\n\nWe are able to source all materials you will need to make your clothing, we're able to ship your merchandise worldwide after production "
		.."is completed. We can be your agent and do all this work for you. We save you time and money by taking the hassle out of having to communicate with multiple people, we will be"
		.." your main contact point for everything you need.\n\nWe have a well established network and team of suppliers and manufacturers that we have built strong working relationships"
		.." with which will all be necessary to get your brand off to a strong start. Whether you are an established professional designer or someone with a great idea that you want your"
		.." shot in fashion, the team at no/sense Clothing Manufacturing can help you!"
	local cloth_info = nil
	GUIEditor5.label[1] = guiCreateLabel(26, 34, 443, 302, intro, false, GUIEditor5.window[1])
	guiLabelSetHorizontalAlign(GUIEditor5.label[1], "left", true)
	guiLabelSetVerticalAlign(GUIEditor5.label[1], "center")

	addEventHandler('onClientGUIClick', GUIEditor5.window[1], function ()
		if source == GUIEditor5.button[2] then
			if guiGetText(GUIEditor5.button[2]) == 'Get Product' then
				-- need space for it.
				local clothing = list_[cid]
				if not exports.global:hasSpaceForItem(localPlayer, 16, clothing.skin) then
					guiSetText(GUIEditor5.label[1], "Your invetory is full.")
					guiLabelSetHorizontalAlign(GUIEditor5.label[1], "center", true)
					playSoundFrontEnd(4)
					return
				end
				-- need money even for the first clothes.
				-- local price = 2^clothing.sold
				local price = defaultSkinCost--new
				if not exports.global:hasMoney(localPlayer, price) then
					guiSetText(GUIEditor5.label[1], "You lack of money to get this product.")
					guiLabelSetHorizontalAlign(GUIEditor5.label[1], "center", true)
					playSoundFrontEnd(4)
					return
				end

				if clothing and not cloth_info then
					cloth_info = 	"Clothes ID: "..clothing.id.."\n"..
									"Collection ((Base skin)): "..clothing.skin.."\n"..
									"Description: "..clothing.description.."\n"..
									"Designer: "..clothing.creator_charname.."\n"..
									"Designed Date: "..(clothing.fdate or exports.datetime:formatTimeInterval(clothing.date)).."\n"..
									"Sold out: "..exports.global:formatMoney( clothing.sold ).."\n"..
									"Price: $"..exports.global:formatMoney( price ).."\n"..
									"\n\nIMPORTANT: This option will generate ONE set of clothes of this design.\n"
									-- .."The initial price is $1 and you can get unlimited sets of clothes. However, if this design is distribited privately (only accessible by you), everytime this design is sold out, the price will get doubled as you Get Product of your own design."
									.."The price to obtain your product is set to $"..price.."."
				end
				guiSetText(GUIEditor5.label[1], cloth_info or "Errors occurred while fetching design info.")
				guiLabelSetHorizontalAlign(GUIEditor5.label[1], "center", true)
				guiSetText(GUIEditor5.button[1], 'Back')
				guiSetText(GUIEditor5.button[2], 'Confirm')
				-- guiSetVisible(GUIEditor5.button[3], false)
				guiSetVisible(GUIEditor5.button[4], false)
			elseif guiGetText(GUIEditor5.button[2]) == 'Confirm' then
				playSoundFrontEnd(6)
				if triggerServerEvent('clothes:getProduct', resourceRoot, cid) then
					guiSetText(GUIEditor5.label[1], "Validating & Retrieving..")
					guiLabelSetHorizontalAlign(GUIEditor5.label[1], "center", true)
					guiSetEnabled(GUIEditor5.window[1], false)
				end
			elseif guiGetText(GUIEditor5.button[2]) == 'Distribute' then
				playSoundFrontEnd(6)
				if triggerServerEvent('clothes:sellProduct', resourceRoot, cid) then
					guiSetText(GUIEditor5.label[1], "Validating & Submitting..")
					guiLabelSetHorizontalAlign(GUIEditor5.label[1], "center", true)
					guiSetEnabled(GUIEditor5.window[1], false)
				end
			end
		elseif source == GUIEditor5.button[1] then
			if guiGetText(GUIEditor5.button[1]) == 'Close' then
				closeDist()
			elseif guiGetText(GUIEditor5.button[1]) == 'Back' then
				guiSetText(GUIEditor5.button[1], 'Close')
				guiSetText(GUIEditor5.button[2], 'Get Product')
				guiSetText(GUIEditor5.label[1], intro)
				guiLabelSetHorizontalAlign(GUIEditor5.label[1], "left", true)
				-- guiSetVisible(GUIEditor5.button[3], true)
				guiSetVisible(GUIEditor5.button[4], true)
			end
		-- elseif source == GUIEditor5.button[3] then
		-- 	playSoundFrontEnd(4)
		-- 	outputChatBox("This feature is currently under construction.", 255,0,0)
		elseif source == GUIEditor5.button[4] then
			local clothing = list_[cid]
			if clothing and not cloth_info then
				-- local price = 200
				cloth_info = 	"Clothes ID: "..clothing.id.."\n"..
								"Collection ((Base skin)): "..clothing.skin.."\n"..
								"Description: "..clothing.description.."\n"..
								"Designer: "..clothing.creator_charname.."\n"..
								"Designed Date: "..(clothing.fdate or exports.datetime:formatTimeInterval(clothing.date)).."\n"..
								"Sold out: "..exports.global:formatMoney( clothing.sold ).."\n"..
								"Pricetag in store: $"..exports.global:formatMoney( clothing.price ).."\n"..
								"\n\nIMPORTANT: After giving your design to no/sense, your clothing design will be distributed publicly & globally in all clothing stores.\n"..
								"You don't receive any profit cut from selling this kind of clothes. ((OOC restriction to prevent money farming by uploading skins))\n"..
								"It will still take up a slot permanently in your collection."
			end
			guiSetText(GUIEditor5.label[1], cloth_info or "Errors occurred while fetching design info.")
			guiLabelSetHorizontalAlign(GUIEditor5.label[1], "center", true)
			guiSetText(GUIEditor5.button[1], 'Back')
			guiSetText(GUIEditor5.button[2], 'Distribute')
			-- guiSetVisible(GUIEditor5.button[3], false)
			guiSetVisible(GUIEditor5.button[4], false)
		end
	end)

	addEventHandler('onClientCharacterLogout', localPlayer, closeDist)
end

function closeDist()
	if GUIEditor5.window[1] and isElement(GUIEditor5.window[1]) then
		removeEventHandler('onClientCharacterLogout', localPlayer, closeDist)
		destroyElement(GUIEditor5.window[1])
		setDrawingImg(false)
		GUIEditor5.window[1] = nil
		if window and isElement(window) then
			guiSetEnabled(window, true)
			closeWindow()--close all
		end
	end
end

function callback_Dis(result)
	if GUIEditor5.window[1] and isElement(GUIEditor5.window[1]) then
		guiSetEnabled(GUIEditor5.window[1], true)
		guiSetEnabled(GUIEditor5.button[2], false)
		guiSetText(GUIEditor5.button[1], 'Close')
		guiSetText(GUIEditor5.label[1], result.why)
		guiLabelSetHorizontalAlign(GUIEditor5.label[1], "center", true)
		if result and result.action == 'getProduct' and result.done then
			list_[result.id].sold = result.sold
		elseif result and result.action == 'sellProduct' and result.done then
			list_[result.id].distribution = result.dist
		end
	end
end
addEvent('clothes:callback_Dis', true)
addEventHandler('clothes:callback_Dis', resourceRoot, callback_Dis)

function toggleGui( gui, state )
	if gui and isElement( gui ) then
		return guiSetEnabled( gui, state and true or false )
	end
end

addEventHandler('onClientResourceStop', resourceRoot, function()
	guiSetInputEnabled(false)
end, false)


function sendModWarning()
	outputChatBox("Please note that this system only works with new mods that have 1 texture image the TXD.", 255, 25, 25)
	outputChatBox("If there are more than 1 texture in the file it will try to pick the first one (subject to change).", 255, 194, 14)
end
