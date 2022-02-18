--[[ 
===============================================================================
                     AccurateWorldMap, by Breaux & Thal-J
===============================================================================
]]--


-- Hi, welcome to the code for AccurateWorldMap
-- Thanks to the esoui glitter community and the authors of Highly Detailed World Map, uespLog, GuildShrines and World Wayshrine Controller for me 
-- being able to figure out how to make this work

-- ascii title art done on https://texteditor.com/ascii-art/

-- define root addon object
local addon = {
	name = "AccurateWorldMap",
	title = "Accurate World Map",
	version = "1.0",
	author = "|CFF0000Breaux|r & |C6b51faThal-J|r",
}


-- defaults

local panelData = {
  type = "panel",
  name = "Accurate World Map",
  author = "Breaux & Thal-J",
}


local normalisedMouseX = 0
local normalisedMouseY = 0
local recordCoordinates = false
local mouseDownOnPolygon = false
local enabled = true
local debug = false
local UNITTAG_PLAYER = 'player' 
local debugOutput = false
local _GetMapTileTexture = GetMapTileTexture
local LAM = LibAddonMenu2
local saveData = {} -- TODO this should be a reference to your actual saved variables table
local panelName = "addonvar" -- TODO the name will be used to create a global variable, pick something unique or you may overwrite an existing variable!
local currentCoordinateCount = 0

local currentPolygon = nil
local polygonData = {}
local newPolygonData = {}

local mapDimensions = 4096 -- px

local isInBlobHitbox = false
local currentlySelectedBlobName = ""
local currentZoneInfo = {}
local isExclusive = false
local hasDragged = false


local currentMapIndex

local waitForRelease = false
local currentMapOffsetX
local currentMapOffsetY






local function print(message, ...)
	df("[%s] %s", addon.name, tostring(message:format(...)))
end


function addon.GetMapTileTexture(index)
    local tex = _GetMapTileTexture(index)

    if (GetCurrentMapIndex() == 1) then
      for i = 1, 16 do
        if tamriel_tiles[i] == tex then
          ---- Replace certain tiles if you are on live server and have spoilers enabled
          if debug then
              i = tostring(i) .. "_debug"  
          end
          return "AccurateWorldMap/tiles/tamriel_" .. i .. ".dds"
        end
      end
    end

    if (GetCurrentMapIndex() == 24) then
      for i = 1, 4 do
        if aurbis_tiles[i] == tex then
          return "AccurateWorldMap/tiles/aurbis_" .. i .. ".dds"
        end
      end
    end
    
    return tex
end

local _GetMapCustomMaxZoom = GetMapCustomMaxZoom

local providedPoiType = 1
local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()



local function toggleDebugOutput()

  if debugOutput == true then
    d("Debug output turned off")
  end

  if debugOutput == false then
    d("Debug output turned on")
  end

  debugOutput = not debugOutput


  
end

local function getCurrentZoneID()

  local zoneID = GetCurrentMapId()

  if (zoneID == nil) then

    -- do something, get the subzone id or figure out why it is nil in the first place
    zoneID = 0
  end


  return zoneID

end




local function getZoneInfoByID(zoneID)


  local zoneData = mapData[getCurrentZoneID()]
  local zoneInfo = zoneData.zoneData

  for zoneIndex, zoneInfo in pairs(zoneInfo) do

    if (zoneInfo.zoneID == zoneID) then
      return zoneInfo
    end
  end
end


local function getZoneIDFromPolygonName(polygonName)
  return tonumber(string.match (polygonName, "%d+"))
end


-- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
-- ██░▄▄▄░██░▄▄▄░██░▄▄▄░████░▄▄▄██░██░██░▀██░██░▄▄▀█▄▄░▄▄█▄░▄██░▄▄▄░██░▀██░██░▄▄▄░██
-- ██▀▀▀▄▄██░███░██▄▄▄▀▀████░▄▄███░██░██░█░█░██░██████░████░███░███░██░█░█░██▄▄▄▀▀██
-- ██░▀▀▀░██░▀▀▀░██░▀▀▀░████░█████▄▀▀▄██░██▄░██░▀▀▄███░███▀░▀██░▀▀▀░██░██▄░██░▀▀▀░██
-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

local zos_WouldProcessMapClick = WouldProcessMapClick
WouldProcessMapClick = function(xN, yN)
  local wouldProcess, resultingMapIndex = zos_WouldProcessMapClick(xN, yN)

  -- check if we are currently hovering over a custom polygon
  if (isInBlobHitbox and currentZoneInfo ~= nil) then
    wouldProcess = false
    resultingMapIndex = GetMapIndexByZoneId(currentZoneInfo.zoneID)
  end

  if (isExclusive) then
    wouldProcess = false
    resultingMapIndex = nil
  end

  return wouldProcess, resultingMapIndex
end

local zos_ProcessMapClick = ProcessMapClick
ProcessMapClick = function(xN, yN)

  local setMapResult = zos_ProcessMapClick(xN, yN)

    -- check if we are currently hovering over a custom polygon
    if (isInBlobHitbox and currentZoneInfo ~= nil) then
      setMapResult = SET_MAP_RESULT_FAILED
    end
  
    if (isExclusive) then
      setMapResult = SET_MAP_RESULT_FAILED
    end

  return setMapResult

end

local zos_GetMapMouseoverInfo = GetMapMouseoverInfo
GetMapMouseoverInfo = function(xN, yN)

  local mapIndex = getCurrentZoneID()

  -- invisible blank default mouseover data
  local locationName = ""
  local textureFile = ""
  local widthN = 0.01
  local heightN = 0.01
  local locXN = 0
  local locYN = 0

  -- if the current map is not set to exclusive, or we don't have any data for it, get vanilla values
  if (isExclusive == false or mapData[mapIndex] == nil) then
    locationName, textureFile, widthN, heightN, locXN, locYN = zos_GetMapMouseoverInfo(xN, yN)
  end

  if (mapData[mapIndex] ~= nil) then

    if (isInBlobHitbox) then 

        locationName = currentZoneInfo.zoneName
        textureFile = currentZoneInfo.blobTexture
        widthN = currentZoneInfo.nBlobTextureWidth
        heightN = currentZoneInfo.nBlobTextureHeight
        locXN = currentZoneInfo.xN
        locYN = currentZoneInfo.yN
        
    end

  end

  return locationName, textureFile, widthN, heightN, locXN, locYN
end


local zos_GetFastTravelNodeInfo = GetFastTravelNodeInfo    
GetFastTravelNodeInfo = function(nodeIndex)
  local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked, disabled = zos_GetFastTravelNodeInfo(nodeIndex)

  if debugOutput == true then
        d("Current Node: "..nodeIndex)
        d("Name: "..name)
        d(" ")
  end

  local mapIndex = getCurrentZoneID()


  if (mapData[mapIndex] ~= nil) then

    if (mapData[mapIndex][nodeIndex] ~= nil) then

      local zoneData = mapData[mapIndex]

      if (zoneData[nodeIndex] ~= nil) then 


        if zoneData[nodeIndex].xN ~= nil then
          normalizedX = zoneData[nodeIndex].xN
        end

        if zoneData[nodeIndex].yN ~= nil then
          normalizedY = zoneData[nodeIndex].yN
        end

        if zoneData[nodeIndex].name ~= nil then
          name = zoneData[nodeIndex].name
        end

        if zoneData[nodeIndex].disabled ~= nil then
          if (zoneData[nodeIndex].disabled == false) then
            isLocatedInCurrentMap = true
          end
        end


      end


    end

  end

  return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked, disabled

end
    

-- function to check if the mouse cursor is within or over the map window
local function isMouseWithinMapWindow()
  local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
  return (not ZO_WorldMapContainer:IsHidden() and (mouseOverControl == ZO_WorldMapContainer or mouseOverControl:GetParent() == ZO_WorldMapContainer))
end

local function onMousePressed()

  if isMouseWithinMapWindow() then

    if (recordCoordinates) then 
      PlaySound(SOUNDS.COUNTDOWN_TICK)

      table.insert(newPolygonData, {xN = normalisedMouseX, yN = normalisedMouseY})
      currentCoordinateCount = currentCoordinateCount + 1

    end

    print("Map clicked!")
  end

  if IsControlKeyDown() then
    print("ctrl + click")
  end


end




local function getWorldMapOffsets()

  local currentOffsetX =  math.floor(ZO_WorldMapContainer:GetLeft())
  local currentOffsetY = math.floor(ZO_WorldMapContainer:GetTop())

  return currentOffsetX, currentOffsetY

end


local function mapTick()

  local mouseX, mouseY = GetUIMousePosition()

  local currentOffsetX = ZO_WorldMapContainer:GetLeft()
  local currentOffsetY = ZO_WorldMapContainer:GetTop()
  local parentOffsetX = ZO_WorldMap:GetLeft()
  local parentOffsetY = ZO_WorldMap:GetTop()
  local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
  local parentWidth, parentHeight = ZO_WorldMap:GetDimensions()

  --print(currentOffsetX.." "..currentOffsetY)

  normalisedMouseX = math.floor((((mouseX - currentOffsetX) / mapWidth) * 1000) + 0.5)/1000
  normalisedMouseY = math.floor((((mouseY - currentOffsetY) / mapHeight) * 1000) + 0.5)/1000









  if (currentPolygon ~= nil) then

    -- check to make sure that the user has actually left the hitbox, and is not just hovering over a wayshrine
    if (currentPolygon:IsPointInside(mouseX , mouseY) and currentMapIndex == GetCurrentMapIndex()) then

      --print("still in hitbox!")


    else

      --print("left hitbox!")
      isInBlobHitbox = false
      currentPolygon = nil
      currentZoneInfo = {}

    end

  end

end

function addon.GetMapCustomMaxZoom()
    if not enabled then return _GetMapCustomMaxZoom() end
    if GetMapName() == "Tamriel" then
        return 3
    else
        return _GetMapCustomMaxZoom()
    end
end

local panel = LAM:RegisterAddonPanel(panelName, panelData)
local optionsData = {
    {
        type = "checkbox",
        name = "Enable debug tiles",
        getFunc = function() return saveData.myValue end,
        setFunc = function(value) debug = value end
    }
}

local function checkIfCanTick()

  if isMouseWithinMapWindow() then
    mapTick()
  end


end


local function createOrShowZonePolygon(polygonData, zoneInfo, isDebug)

  local polygonID


  if (zoneInfo ~= nil) then

    polygonID = "blobHitbox-"..zoneInfo.zoneID.."-"..zoneInfo.zoneName


  else

    isDebug = true
    polygonID = "debugPolygon"

  end

  -- check if polygon by this name exists
  if (WINDOW_MANAGER:GetControlByName(polygonID) == nil) then


    local polygon = ZO_WorldMapContainer:CreateControl(polygonID, CT_POLYGON)
    polygon:SetAnchorFill(ZO_WorldMapContainer)


    local polygonCode = ""

    if (isDebug) then
      AWM_EditTextWindow:SetHidden(false)
    end


    for key, data in pairs(polygonData) do

      if (isDebug) then
        polygonCode = polygonCode .. ("{ xN = "..string.format("%.03f", data.xN)..", yN = "..string.format("%.03f", data.yN).." },\n")  
      end


      -- print(tostring("Coordinate set "..key .. ": "))
  
      -- print("X: "..tostring(data.xN))
      -- print("Y: "..tostring(data.yN))
  
  
      polygon:AddPoint(data.xN, data.yN)
  
  
    end

    if (isDebug) then
      AWM_EditTextTextBox:SetText(polygonCode)
    end



  
  
    if (isDebug) then
      polygon:SetCenterColor(0, 1, 0, 0.5)
    else
      polygon:SetCenterColor(0, 0, 0, 0)
    end
    
    polygon:SetMouseEnabled(true)
    polygon:SetHandler("OnMouseDown", function(control, button, ctrl, alt, shift, command)

      if (waitForRelease == false) then
        currentMapOffsetX, currentMapOffsetY = getWorldMapOffsets()
        waitForRelease = true
      end


      currentPolygon = polygon
      ZO_WorldMap_MouseDown(button, ctrl, alt, shift)    
    end)

    polygon:SetHandler("OnMouseUp", function(control, button, upInside, ctrl, alt, shift, command)
      
      ZO_WorldMap_MouseUp(control, button, upInside)



      if (currentZoneInfo ~= nil and upInside and button == MOUSE_BUTTON_INDEX_LEFT) then

        if (waitForRelease) then

          local mapOffsetX, mapOffsetY = getWorldMapOffsets()

          local deltaX, deltaY


          if (mapOffsetX >= currentMapOffsetX) then
            deltaX = mapOffsetX - currentMapOffsetX
          else 
            deltaX = currentMapOffsetX - mapOffsetX
          end

          if (mapOffsetY >= currentMapOffsetY) then
            deltaY = mapOffsetY - currentMapOffsetY
          else 
            deltaY = currentMapOffsetY - mapOffsetY
          end

          print(tostring(deltaX))

          if (deltaX <= 10 and deltaX <= 10) then

            currentPolygon = nil
            isInBlobHitbox = false
      
            SetMapToMapId(currentZoneInfo.zoneID)
            currentZoneInfo = {}
            CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")

          end


        end


      end

      waitForRelease = false

    end)
      
      
      
  
    polygon:SetHandler("OnMouseEnter", function()

      currentMapIndex = GetCurrentMapIndex()
      isInBlobHitbox = true
      --print("User has entered zone hitbox")
      currentPolygon = polygon
  
      -- update with current zone info
      currentZoneInfo = getZoneInfoByID(getZoneIDFromPolygonName(polygon:GetName()))
    end)
  
  else 
    -- it already exists, we just need to show it again
    WINDOW_MANAGER:GetControlByName(polygonID):SetHidden(false)
    WINDOW_MANAGER:GetControlByName(polygonID):SetMouseEnabled(true)
  end
end

local function recordPolygon()

  if recordCoordinates == true then
    d("Coordinates recorded.")

    createOrShowZonePolygon(newPolygonData)


    newPolygonData = {}
    currentCoordinateCount = 0
    recordCoordinates = false
  end

  if recordCoordinates == false then
    d("Recording coordinates... click on the map to draw a polygon")
    recordCoordinates = true
  end


end

local function getFileDirectoryFromZoneName(providedZoneName)

  local providedZoneName = providedZoneName

  providedZoneName = providedZoneName:gsub("'", "") -- replace all instances of `'` with empty string
  providedZoneName = providedZoneName:gsub(" ", "") -- replace all instances of ` ` with empty string
  providedZoneName = providedZoneName:gsub("-", "") -- replace all instances of ` ` with empty string

  providedZoneName = providedZoneName:lower()

  local blobFileDirectory = ("AccurateWorldMap/blobs/blob-"..providedZoneName..".dds")

  return blobFileDirectory
end




local function getBlobTextureDetails()

  print("getting blob info!")


  -- iterate through all of mapData
  for mapID, zoneData in pairs(mapData) do


    if (zoneData.zoneData ~= nil) then

      print("got to here!")

      local zoneInfo = zoneData.zoneData

      for zoneIndex, zoneInfo in pairs(zoneInfo) do

        print("checking zone info!")

        if (zoneInfo.zoneName ~= nil) then

          print("there is a zone name!")

          if (zoneInfo.blobTexture == nil or zoneInfo.nBlobTextureHeight == nil or zoneInfo.nBlobTextureWidth == nil ) then

            print("loading in textures!")

            local textureDirectory
            
            if (zoneInfo.blobTexture ~= nil) then
              textureDirectory = zoneInfo.blobTexture
            else
              textureDirectory = getFileDirectoryFromZoneName(zoneInfo.zoneName)
            end

            -- load texture into control from name
            AWM_TextureControl:SetTexture(textureDirectory)

            -- check if texture exists before doing stuff
            if (AWM_TextureControl:IsTextureLoaded()) then

              -- get the dimensions
              local textureHeight, textureWidth = AWM_TextureControl:GetTextureFileDimensions()

              -- save texture name and dimensions
              mapData[mapID].zoneData[zoneIndex].blobTexture = textureDirectory
              mapData[mapID].zoneData[zoneIndex].nBlobTextureHeight = textureHeight / mapDimensions
              mapData[mapID].zoneData[zoneIndex].nBlobTextureWidth = textureWidth / mapDimensions

            else

              print("The following texture failed to load: "..textureDirectory)


            end

          end


        end

      end

    end
  end
end


local function cleanUpZoneBlobs()

  local numChildren = ZO_WorldMapContainer:GetNumChildren()


  for i = 1, numChildren do


    local childControl = ZO_WorldMapContainer:GetChild(i)
    local controlName = childControl:GetName()

    if (string.match(controlName, "blobHitbox-")) then
      childControl:SetHidden(true)
      childControl:SetMouseEnabled(false)

    end

  end


end


local function setMapTo(int)

  currentPolygon = nil
  isInBlobHitbox = false

  SetMapToMapId(int)
  currentZoneInfo = {}
  CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")

end




local function OnAddonLoaded(event, addonName)
  if addonName ~= addon.name then return end
  EVENT_MANAGER:UnregisterForEvent(addon.name, EVENT_ADD_ON_LOADED)
  


  getBlobTextureDetails()


  -- AccurateWorldMapTLC = CreateTopLevelWindow("AccurateWorldMapTLC")
  -- AccurateWorldMapTLC:SetResizeToFitDescendents(true) --will make the TLC window resize with it's childen -> the Tex01 texture control
  -- comment these two to hide the control
  AWM_TextureControl:SetAlpha(0)


  ZO_MapPin.TOOLTIP_CREATORS[MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE].creator = function(pin)
		local nodeIndex = pin:GetFastTravelNodeIndex()
		local _, name, _, _, _, _, _, _, _, disabled = GetFastTravelNodeInfo(nodeIndex)
		local info_tooltip
		if not IsInGamepadPreferredMode() then 
			if not disabled then
				if nodeIndex ~= 215 and nodeIndex ~= 221 or ZO_Map_GetFastTravelNode() then -- Eyevea and the Earth Forge cannot be "jumped" to so we'll add "This area is not accessible via jumping." when they're not using a wayshrine
					InformationTooltip:AppendWayshrineTooltip(pin)																			-- Normal Wayshrine tooltip data
				else
					InformationTooltip:AddLine(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())	-- Wayshrine Name
					InformationTooltip:AddLine("This location can only be traveled to via other Wayshrines.", "", 1, 0, 0)				-- "This area is not accessible via jumping."
				end	
			else
				InformationTooltip:AddLine(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())		-- Wayshrine Name Only (unknown wayshrine)
			end		
		end
	end

  SLASH_COMMANDS["/awm_debug"] = toggleDebugOutput
  SLASH_COMMANDS["/get_map_id"] = function() print(tostring(GetCurrentMapId())) end
  SLASH_COMMANDS["/zones_debug"] = initialise
  SLASH_COMMANDS["/record_polygon"] = recordPolygon
  SLASH_COMMANDS["/get_blobs"] = getBlobTextureDetails
  SLASH_COMMANDS["/get_controls"] = cleanUpZoneBlobs
  SLASH_COMMANDS["/set_map_to"] = setMapTo

--   SLASH_COMMANDS["/joke"] = function() 
--     d(GetRandomElement(jokes)) 
-- end
  
  GetMapTileTexture = addon.GetMapTileTexture
  GetMapCustomMaxZoom = addon.GetMapCustomMaxZoom
  

end




-- Function that gets called whenever the user changes zone, or clicks to a new zone on the world map.

local function onZoneChanged()

  local zoneName = GetUnitZone(UNITTAG_PLAYER)
  local mapIndex = getCurrentZoneID()

  print("Zone changed!")



  -- Delete any existing controls on the world map before iterating over anything else
  cleanUpZoneBlobs()

  if (mapIndex ~= nil) then


    print("Current map id: ".. mapIndex)


    -- Check if the current zone/map has any custom map data set to it
    if (mapData[mapIndex] ~= nil) then
      
      print("This map has custom data!")


      if (mapData[mapIndex].isExclusive ~= nil) then
        isExclusive = mapData[mapIndex].isExclusive
      else
        isExclusive = false
      end


      if (mapData[mapIndex].zoneData ~= nil) then
        print("This map has custom zone data!")
        local zoneData = mapData[mapIndex].zoneData

        for zoneAttribute, zoneInfo in pairs(zoneData) do


          if (zoneInfo.zoneName ~= nil) then

            print(zoneInfo.zoneName)

            print(tostring(zoneAttribute))
            print(tostring(zoneInfo))

            if (zoneInfo.xN ~= nil and zoneInfo.yN ~= nil) then
              if (zoneInfo.blobTexture ~= nil and zoneInfo.nBlobTextureHeight ~= nil and zoneInfo.nBlobTextureHeight ~= nil ) then
                if (zoneInfo.zonePolygonData ~= nil) then

                  createOrShowZonePolygon(zoneInfo.zonePolygonData, zoneInfo)


                  -- add polygons, make zone data

                else 
                  print("Warning: Custom Zone "..zoneInfo.zoneName.." ".."is missing its hitbox polygon!")
                end
              else
                print("Warning: Custom Zone "..zoneInfo.zoneName.." ".."is missing its texture details!")

                -- rerun texture details for this zone
                -- getTextureDetails() --getTextureDetails(nil)

              end
            else
              print("Warning: Custom Zone "..zoneInfo.zoneName.." ".." has invalid zone coordinates!")
            end
          else
            print("Warning: Custom Zone ID #"..tostring(zoneInfo.zoneID).." has no name!")
          end
        end
      end

    else
      isExclusive = false
    end
  end
  print("isExclusive: "..tostring(isExclusive))
end


-- Registering events and callbacks
LAM:RegisterOptionControls(panelName, optionsData)
EVENT_MANAGER:RegisterForEvent(addon.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent("onMouseDown", EVENT_GLOBAL_MOUSE_DOWN, onMousePressed)
EVENT_MANAGER:RegisterForUpdate("uniqueName", 0, checkIfCanTick)
CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", onZoneChanged)