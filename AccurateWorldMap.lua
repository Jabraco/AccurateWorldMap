--[[===========================================================================
                      AccurateWorldMap, by Breaux & Thal-J
===============================================================================

-- ascii title art done on https://texteditor.com/ascii-art/
-- https://textfancy.com/multiline-text-art/


TJ Todo:

- update print function to only print out if isDebug is enabled in settings
- link that up to settings as well
- saved variables
- add arcane university battlegroudn blob using blackreach circle blobs
- add IC Sewers blob to IC map
- hide player marker and group markers on world map for v1
- Remove dragonhold from the map when you've done the quest
- add dragonhold island to the map

Things to ask breaux:

- blob for earth forge in reach map, get breaux to draw one
- add IC Sewers blob to IC map
- ask breaux if you can make tideholm its own blob, also do the same for coral wasten

Breaux Todo:

- Dranil Kir (mini zone)
- Silitar (mini zone)
- Vivec City on vvardenfell


Interesting events to consider:

* EVENT_SHOW_WORLD_MAP

* EVENT_ZONE_CHANGED (*string* _zoneName_, *string* _subZoneName_, *bool* _newSubzone_, *integer* _zoneId_, *integer* _subZoneId_)
* EVENT_GROUP_TYPE_CHANGED (*bool* _largeGroup_)
* EVENT_GROUP_UPDATE
* EVENT_GROUP_MEMBER_JOINED (*string* _memberCharacterName_, *string* _memberDisplayName_, *bool* _isLocalPlayer_)
* EVENT_GROUP_MEMBER_LEFT (*string* _memberCharacterName_, *[GroupLeaveReason|#GroupLeaveReason]* _reason_, *bool* _isLocalPlayer_, *bool* _isLeader_, *string* _memberDisplayName_, *bool* _actionRequiredVote_)
* EVENT_GROUP_MEMBER_ROLE_CHANGED (*string* _unitTag_, *[LFGRole|#LFGRole]* _newRole_)
* EVENT_GROUP_MEMBER_SUBZONE_CHANGED

* EVENT_QUEST_ADVANCED (*luaindex* _journalIndex_, *string* _questName_, *bool* _isPushed_, *bool* _isComplete_, *bool* _mainStepChanged_)
* EVENT_QUEST_COMPLETE (*string* _questName_, *integer* _level_, *integer* _previousExperience_, *integer* _currentExperience_, *integer* _championPoints_, *[QuestType|#QuestType]* _questType_, *[InstanceDisplayType|#InstanceDisplayType]* _instanceDisplayType_)

* EVENT_GLOBAL_MOUSE_DOWN (*[MouseButtonIndex|#MouseButtonIndex]* _button_, *bool* _ctrl_, *bool* _alt_, *bool* _shift_, *bool* _command_)
* EVENT_GLOBAL_MOUSE_UP (*[MouseButtonIndex|#MouseButtonIndex]* _button_, *bool* _ctrl_, *bool* _alt_, *bool* _shift_, *bool* _command_)

---------------------------------------------------------------------------]]--


-------------------------------------------------------------------------------
-- Root addon object
-------------------------------------------------------------------------------

AccurateWorldMap = getAddonInfo("AccurateWorldMap")

-- define default options
AccurateWorldMap.options = {}

-------------------------------------------------------------------------------
-- Globals
-------------------------------------------------------------------------------

-- bools
local recordCoordinates = false
local mouseDownOnPolygon = false
local enabled = true
local debug = false
local debugOutput = false
local isExclusive = false
local hasDragged = false
local isInBlobHitbox = false
local waitForRelease = false


local normalisedMouseX = 0
local normalisedMouseY = 0


local _GetMapTileTexture = GetMapTileTexture

local currentCoordinateCount = 0

local currentPolygon = nil
local polygonData = {}
local newPolygonData = {}
local currentZoneInfo = {}




local currentlySelectedBlobName = ""


AWM_MouseOverGrungeTex = CreateControl("AWM_MouseOverGrungeTex", ZO_WorldMap, CT_TEXTURE)
AWM_MouseOverGrungeTex:SetTexture("/esoui/art/performance/statusmetermunge.dds")

local currentMapIndex


local currentMapOffsetX
local currentMapOffsetY

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local mapDimensions = 4096 -- px

function AccurateWorldMap.GetMapTileTexture(index)
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

-------------------------------------------------------------------------------
-- Process map click functions
-------------------------------------------------------------------------------

-- These functions control when the user's click is passed through to the map 
-- for events such as zone changing, we want to override that so that we can
-- make sure our custom polygons get the priority, as long as isExclusive = true.

-------------------------------------------------------------------------------

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

        if (currentZoneInfo.zoneDescription ~= nil) then
          ZO_WorldMapMouseOverDescription:SetText(currentZoneInfo.zoneDescription)
        end

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
      ZO_WorldMapMouseOverDescription:SetText("")
      AWM_MouseOverGrungeTex:SetHidden(true)

    end

  end

end

function AccurateWorldMap.GetMapCustomMaxZoom()
    if not enabled then return _GetMapCustomMaxZoom() end
    if GetMapName() == "Tamriel" then
        return 3
    else
        return _GetMapCustomMaxZoom()
    end
end



local function checkIfCanTick()

  if isMouseWithinMapWindow()  then
    mapTick()
  else
    if (isWorldMapShown()) then
      ZO_WorldMapMouseOverDescription:SetText("")
      AWM_MouseOverGrungeTex:SetHidden(true)
    end
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
      AWM_MouseOverGrungeTex:SetHidden(false)
  
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

  -- transform "Stros M'Kai" to "strosmkai"
  providedZoneName = providedZoneName:gsub("'", "")
  providedZoneName = providedZoneName:gsub(" ", "")
  providedZoneName = providedZoneName:gsub("-", "") 
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


local function onPlayerLoaded()


  zo_callLater(function()
    getBlobTextureDetails() 

    zo_callLater(function() getBlobTextureDetails() end, 1000 )

  end, 2000 )


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
  
  -- ignore any other addon that isn't ours, we only care when our addon is loaded
  if addonName ~= AccurateWorldMap.name then
     return 
  end
  
  -- our addon has loaded, we don't need to know about any future Addon Loaded events
  EVENT_MANAGER:UnregisterForEvent(AccurateWorldMap.name, EVENT_ADD_ON_LOADED)
  
  getBlobTextureDetails()
  ZO_WorldMapMouseOverDescription:SetFont("ZoFontGameLargeBold")
  local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()

  local enlargeConst = 1.5

  AWM_MouseOverGrungeTex:SetAnchor(TOPLEFT, ZO_WorldMap, TOPLEFT, (mapWidth - (mapWidth*enlargeConst))/2, -(0.47 * mapHeight))
  AWM_MouseOverGrungeTex:SetDrawTier(DT_PARENT)
  AWM_MouseOverGrungeTex:SetDimensions(mapWidth*enlargeConst, mapHeight)
  AWM_MouseOverGrungeTex:SetDrawLayer(DL_OVERLAY)
  AWM_MouseOverGrungeTex:SetDrawLayer(DL_CONTROLS)
  AWM_MouseOverGrungeTex:SetAlpha(0.50)
  AWM_MouseOverGrungeTex:SetHidden(true)

  ZO_WorldMap:SetAutoRectClipChildren(true)




  AWM_TextureControl:SetAlpha(0)


  ZO_MapPin.TOOLTIP_CREATORS[MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE].creator = function(pin)
		local nodeIndex = pin:GetFastTravelNodeIndex()
		local _, name, _, _, _, _, _, _, _, disabled = GetFastTravelNodeInfo(nodeIndex)
		local info_tooltip
		if not IsInGamepadPreferredMode() then 
			if not disabled then
				if nodeIndex ~= 215 and nodeIndex ~= 221 or ZO_Map_GetFastTravelNode() then -- Eyevea and the Earth Forge cannot be "jumped" to so we'll add "This area is not accessible via jumping." when they're not using a wayshrine
					InformationTooltip:AppendWayshrineTooltip(pin) -- Normal Wayshrine tooltip data
				else
					InformationTooltip:AddLine(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())	-- Wayshrine Name
					InformationTooltip:AddLine("This location can only be accessed via other Wayshrines.", "", 1, 0, 0)				-- "This area is not accessible via jumping."
				end	
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
  SLASH_COMMANDS["/print"] = print

  
  GetMapTileTexture = AccurateWorldMap.GetMapTileTexture
  GetMapCustomMaxZoom = AccurateWorldMap.GetMapCustomMaxZoom
  

end


-------------------------------------------------------------------------------
--  On zone/map change callback function
-------------------------------------------------------------------------------

local function onZoneChanged()

  local mapIndex = getCurrentZoneID()

  print("Zone changed!")


  -- Delete any existing controls on the world map before iterating over anything else
  cleanUpZoneBlobs()
  AWM_MouseOverGrungeTex:SetHidden(true)


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


-------------------------------------------------------------------------------
-- Registering for events and callbacks
-------------------------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent(AccurateWorldMap.name, EVENT_ADD_ON_LOADED, OnAddonLoaded)
EVENT_MANAGER:RegisterForEvent("onMouseDown", EVENT_GLOBAL_MOUSE_DOWN, onMousePressed)
EVENT_MANAGER:RegisterForEvent(AccurateWorldMap.name, EVENT_PLAYER_ACTIVATED, onPlayerLoaded)
EVENT_MANAGER:RegisterForUpdate("uniqueName", 0, checkIfCanTick)
CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", onZoneChanged)

-- TODO: use this to fix gamepad mode
-- local function NormalizePreferredMousePositionToMap()
--   if IsInGamepadPreferredMode() then
--       local x, y = ZO_WorldMapScroll:GetCenter()
--       return NormalizePointToControl(x, y, ZO_WorldMapContainer)
--   else
--       return NormalizeMousePositionToControl(ZO_WorldMapContainer)
--   end
-- end