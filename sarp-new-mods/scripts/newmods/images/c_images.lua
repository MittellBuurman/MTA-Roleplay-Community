-- Fernando

local client_images = {}
local searched = {}

-- exported
function getImage(id)

	id = tonumber(id)
	if id then

		if client_images[id] then -- if image is found somewhere client side.
			return client_images[id]

		else -- if image is NOT found anywhere client side.
			if not searched[id] then
				searched[id] = getTickCount()
			end
			if (getTickCount() - searched[id]) > refresh_rate then
				searched[id] = getTickCount()
				triggerServerEvent("newmods:obtainImage", localPlayer, id)
				-- if debugMode then
				-- 	outputChatBox("Asking server for image model id "..id)
				-- end
			end
		end
	end
end

function receiveImage(id, data)
	-- https://wiki.multitheftauto.com/wiki/Texture_pixels
	local texture = dxCreateTexture(data)
	if texture then

		--cleanup previous
		if client_images[id] then
			if isElement(client_images[id].tex) then
				destroyElement(client_images[id].tex)
			end
		end

		client_images[id] = {tex = texture}
		-- if debugMode then
		-- 	outputChatBox("Texture for model id "..id.." successfully created")
		-- end
	end

end
addEvent("newmods:receiveImage", true)
addEventHandler("newmods:receiveImage", root, receiveImage)

function deleteImages()
	for id, img in ipairs(client_images) do
		if isElement(img.tex) then
			destroyElement(img.tex)
			-- if debugMode then
			-- 	outputChatBox("Deleting image "..id.." from client cache")
			-- end
		end
	end
	client_images = {}
	searched = {}
end
addEvent("newmods:deleteImages", true)
addEventHandler("newmods:deleteImages", root, deleteImages)

function testImage(filedata, id, giveresponse, theMod)
	local tp = "temp/"..id..".png"
	local f = fileCreate(tp)
	if f then
		fileWrite(f, filedata)
		local size = fileGetSize(f)
		fileClose(f)
		fileDelete(tp)
		if size > maxImageFileSize then

			if giveresponse then
				local respMsg = "Image file size must be max "..(maxImageFileSize/1024).." kb"
				triggerServerEvent("newmods:makeResponse", localPlayer, localPlayer, giveresponse, false, respMsg)
			end
			return
		end

		local tex = dxCreateTexture(filedata)
		if tex then
			local w,h = dxGetMaterialSize( tex )
			destroyElement(tex)

			if tonumber(w) ~= tonumber(h) then
				if giveresponse then
					local respMsg = "Image must be square: Max "..maxImageWidth.." x "..maxImageWidth.." pixels. Use Imgur editor to crop."
					triggerServerEvent("newmods:makeResponse", localPlayer, localPlayer, giveresponse, false, respMsg)
				end
				return
			end

			if tonumber(w) > maxImageWidth then
				if giveresponse then
					local respMsg = "Image too large: Max "..maxImageWidth.." x "..maxImageWidth.." pixels. Use Imgur editor to crop."
					triggerServerEvent("newmods:makeResponse", localPlayer, localPlayer, giveresponse, false, respMsg)
				end
				return
			end

			-- success
			triggerServerEvent("newmods:storeImage", localPlayer, id, filedata, giveresponse, theMod)

		else
			if giveresponse then
				local respMsg = "URL doesn't lead to a valid image file (check if it ends in .png)"
				triggerServerEvent("newmods:makeResponse", localPlayer, localPlayer, giveresponse, false, respMsg)
			end
		end
	else
		if giveresponse then
			local respMsg = "Failed to store image in server"
			triggerServerEvent("newmods:makeResponse", localPlayer, localPlayer, giveresponse, false, respMsg)
		end
	end
end
addEvent("newmods:testImage", true)
addEventHandler("newmods:testImage", root, testImage)


-- testing draw image cached
-- sx,sy = guiGetScreenSize()
-- addEventHandler( "onClientRender", root,
-- function ()
-- 	local img = getImage(4)
-- 	if img and img.tex then
-- 		local imw, imh = 100,100
-- 		dxDrawImage(sx/2 - imw/2, sy/2 - imh/2, imw, imh, img.tex)
-- 	end
-- end)

-- testing upload image from url
-- function testImgUpload()
-- 	local url = "https://i.imgur.com/03OlKAo.png"
-- 	triggerServerEvent("newmods:fetchImageFromURL", localPlayer, 5, url, "playerUpload")
-- end
-- addCommandHandler("testimg", testImgUpload)
