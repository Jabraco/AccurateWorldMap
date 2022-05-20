--[[===========================================================================
                      AccurateWorldMap Utility Functions
===============================================================================

                Utility functions that help the main addon work.

---------------------------------------------------------------------------]]--

-------------------------------------------------------------------------------
-- Get base addon object and callbacks
-------------------------------------------------------------------------------

AWM = AWM or {}
local LocalCallbackManager = ZO_CallbackObject:Subclass()

-------------------------------------------------------------------------------
-- Get addon info from addon manifest
-------------------------------------------------------------------------------

function getAddonInfo(addonName)

  local AddOnManager = GetAddOnManager()
  local numAddons = AddOnManager:GetNumAddOns()

  for i = 1, numAddons do -- loop through all currently installed addon

    -- get addon info from manifest
    local name, title, author, description = AddOnManager:GetAddOnInfo(i)

    if (name == addonName) then -- we've found our addon!

      local addonTable = {}
      local version = AddOnManager:GetAddOnVersion(i)

      -- set addon data to metatable
      addonTable.title = title
      addonTable.name = name
      addonTable.author = author
      addonTable.description = description
      addonTable.version = tostring(version)
      addonTable.options = {}

      return addonTable
    end
  end
end

-------------------------------------------------------------------------------
-- Merge multiple tables into one
-------------------------------------------------------------------------------

local mergedTable = {}

function join(extra, newWorldspace)

  if (newWorldspace) then
    mergedTable = {}
  end

  table.insert(mergedTable, extra)
  return mergedTable
end

-------------------------------------------------------------------------------
-- Print text to chat
-------------------------------------------------------------------------------

function print(message, isForced, ...)
  if (AWM.options.isDebug or isForced) then
    df("[%s] %s", AWM.name, tostring(message):format(...))
  end
end

-------------------------------------------------------------------------------
-- Check if mouse is inside of the map window
-------------------------------------------------------------------------------

function isMouseWithinMapWindow()
  local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
  return (not ZO_WorldMapContainer:IsHidden() and (mouseOverControl == ZO_WorldMapContainer or mouseOverControl:GetParent() == ZO_WorldMapContainer))
end

-------------------------------------------------------------------------------
-- Check if world map window is being shown
-------------------------------------------------------------------------------

local canFireCallback = false

function isWorldMapShown()

  local isMapShown = (not ZO_WorldMapContainer:IsHidden() or ZO_WorldMap_IsWorldMapShowing())

  if (isMapShown and canFireCallback) then

    zo_callLater(function()
  
      CALLBACK_MANAGER:FireCallbacks("OnWorldMapShown", nil)

    end, 300 )

    canFireCallback = false

  end

  if (not isMapShown and not canFireCallback) then

    canFireCallback = true

  end

  return isMapShown
end
  
-------------------------------------------------------------------------------
-- Get world map offsets from the sides of the screen
-------------------------------------------------------------------------------

function getWorldMapOffsets()
  return math.floor(ZO_WorldMapContainer:GetLeft()), math.floor(ZO_WorldMapContainer:GetTop())
end

-------------------------------------------------------------------------------
-- Determine whether a variable X is numeric or not
-------------------------------------------------------------------------------

function isNumeric(x)
  if tonumber(x) ~= nil then
      return true
  end
  return false
end

-------------------------------------------------------------------------------
-- Check if table has a certain value
-------------------------------------------------------------------------------

function hasValue (tab, val)
  for index, value in ipairs(tab) do
      if value == val then
          return true
      end
  end
  return false
end

-------------------------------------------------------------------------------
-- Simpler function to check if user is in gamepad mode
-------------------------------------------------------------------------------

local lastGamepadPreference

function isInGamepadMode()

  if (lastGamepadPreference ~= IsInGamepadPreferredMode()) then
    lastGamepadPreference = IsInGamepadPreferredMode()
    AWM.canRedrawMap = true
  end

  return IsInGamepadPreferredMode()
end

-------------------------------------------------------------------------------
-- Get current cursor's position in screenspace
-------------------------------------------------------------------------------

function getMouseCoordinates()

  if (isInGamepadMode()) then
    return ZO_WorldMapScroll:GetCenter()
  else
    return GetUIMousePosition()
  end
end

-------------------------------------------------------------------------------
-- Get normalised cursor coordinates relative to worldmap
-------------------------------------------------------------------------------

function getNormalisedMouseCoordinates()

  local mouseX, mouseY = getMouseCoordinates()

  local currentOffsetX = ZO_WorldMapContainer:GetLeft()
  local currentOffsetY = ZO_WorldMapContainer:GetTop()
  local parentOffsetX = ZO_WorldMap:GetLeft()
  local parentOffsetY = ZO_WorldMap:GetTop()
  local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
  local parentWidth, parentHeight = ZO_WorldMap:GetDimensions()

  local normalisedMouseX = math.floor((((mouseX - currentOffsetX) / mapWidth) * 1000) + 0.5)/1000
  local normalisedMouseY = math.floor((((mouseY - currentOffsetY) / mapHeight) * 1000) + 0.5)/1000

  return normalisedMouseX, normalisedMouseY

end

-------------------------------------------------------------------------------
-- Get the mapID of the current zone
-------------------------------------------------------------------------------

function getCurrentMapID()

  local zoneID = GetCurrentMapId()

  if (zoneID == nil) then
    zoneID = 0
  end

  return zoneID

end

-------------------------------------------------------------------------------
-- Get zoneInfo object by ID
-------------------------------------------------------------------------------

function getZoneInfoByID(zoneID)

  if (mapData ~= nil) then

    for mapID, mapInfo in pairs(mapData) do

      if (mapInfo.zoneData ~= nil) then

        local zoneInfo = mapInfo.zoneData

          for zoneIndex, zoneInfo in pairs(zoneInfo) do
        
            if (zoneInfo.zoneID == zoneID) then
              return zoneInfo
            end
          end
      end

    end
  end
end

-------------------------------------------------------------------------------
-- Get map name from ID
-------------------------------------------------------------------------------

function getZoneNameFromID(zoneID)

  local zoneInfo = getZoneInfoByID(zoneID)

  -- does this map have a custom name / are custom names enabled? 
  if ((zoneInfo ~= nil and zoneInfo.overrideLoreRenames ~= nil) or AWM.options.loreRenames) then

    if (zoneInfo ~= nil) then

      return zoneInfo.zoneName

    else

      return GetMapNameById(zoneID)

    end

  else
    -- else return vanilla name
    return GetMapNameById(zoneID)

  end

end

-------------------------------------------------------------------------------
-- Get map id from zone hitbox polygon name
-------------------------------------------------------------------------------

function getMapIDFromPolygonName(polygonName)
  return tonumber(string.match (polygonName, "%d+"))
end

-------------------------------------------------------------------------------
-- Get blob file directory from map name
-------------------------------------------------------------------------------

function getFileDirectoryFromMapName(providedZoneName)
  local providedZoneName = providedZoneName

  -- example: transform "Stros M'Kai" to "strosmkai"
  providedZoneName = providedZoneName:gsub("'", "")
  providedZoneName = providedZoneName:gsub(" ", "")
  providedZoneName = providedZoneName:gsub("-", "") 
  providedZoneName = providedZoneName:lower()

  local blobFileDirectory = ("AccurateWorldMap/blobs/blob-"..providedZoneName..".dds")
  return blobFileDirectory
end

-------------------------------------------------------------------------------
-- Hide all zone blobs (hitboxes) on the map
-------------------------------------------------------------------------------

function hideAllZoneBlobs()

  for i = 1, ZO_WorldMapContainer:GetNumChildren() do

    local childControl = ZO_WorldMapContainer:GetChild(i)
    local controlName = childControl:GetName()

    if (string.match(controlName, "blobHitbox-")) then
      childControl:SetHidden(true)
      childControl:SetMouseEnabled(false)

    end

  end
end

-------------------------------------------------------------------------------
-- Navigate map to provided map via map data object or ID
-------------------------------------------------------------------------------

local GPS = LibGPS3

function navigateToMap(mapInfo)

  local mapID

  -- mapInfo can be either an int or a zoneData object, need to determine which it is
  -- if it's a zoneData object, then it will have an id

  if (mapInfo ~= nil) then

    if (isNumeric(mapInfo)) then -- it is an int

      mapID = tonumber(mapInfo)

    else -- it is not an int

      if (mapInfo.zoneID ~= nil) then -- it is a zoneData object

        mapID = mapInfo.zoneID
  
      end

    end



    SetMapToMapId(mapID)
    GPS:SetPlayerChoseCurrentMap()
    hideAllZoneBlobs()
    CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")

    -- force map to zoom out
    local mapPanAndZoom = ZO_WorldMap_GetPanAndZoom()
    mapPanAndZoom:SetCurrentNormalizedZoom(0)
      
  end

end




-------------------------------------------------------------------------------
-- Get current zone info table if it exists
-------------------------------------------------------------------------------

function getCurrentZoneInfo()

  return getZoneInfoByID(getCurrentMapID())

end

-------------------------------------------------------------------------------
-- Update location info on the side bar
-------------------------------------------------------------------------------

function updateLocationsInfo()

  if (VOTANS_IMPROVED_LOCATIONS) then
    VOTANS_IMPROVED_LOCATIONS.mapData = nil
    WORLD_MAP_LOCATIONS:BuildLocationList()
  else
    local locations = WORLD_MAP_LOCATIONS
    locations.data.mapData = nil

    ZO_ScrollList_Clear(locations.list)
    local scrollData = ZO_ScrollList_GetDataList(locations.list)

    local mapData = locations.data:GetLocationList()

    for i,entry in ipairs(mapData) do
      scrollData[#scrollData + 1] = ZO_ScrollList_CreateDataEntry(1, entry)
    end

    ZO_ScrollList_Commit(locations.list)

  end
end

-------------------------------------------------------------------------------
-- Get whether the current map is exclusive or not
-------------------------------------------------------------------------------

function getIsCurrentMapExclusive()

  local currentZoneInfo = getCurrentZoneInfo()

  return (currentZoneInfo ~= nil and (currentZoneInfo.isExclusive ~= nil and currentZoneInfo.isExclusive)) 

end

-------------------------------------------------------------------------------
-- Get whether the provided map has custom zone data or not
-------------------------------------------------------------------------------

function doesMapHaveCustomZoneData(mapID)

  return ((mapData[mapID] ~= nil and mapData[mapID].zoneData ~= nil) or getZoneInfoByID(mapID) ~= nil)

end


-------------------------------------------------------------------------------
-- Get whether the current map has custom zone data or not
-------------------------------------------------------------------------------

function doesCurrentMapHaveCustomZoneData()
  
  return doesMapHaveCustomZoneData(getCurrentMapID())

end


-------------------------------------------------------------------------------
-- Creates zone hitbox on the map given some coordinates
-------------------------------------------------------------------------------

function createZoneHitbox(polygonData, zoneInfo)

  local polygonID
  local isDebug


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

        d(AWM.polygonData)

        --d(data.xN, data.yN)

        polygonCode = polygonCode .. ("{ xN = "..string.format("%.03f", data.xN)..", yN = "..string.format("%.03f", data.yN).." },\n")  

      end

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


      AWM.currentlySelectedPolygon = polygon
      ZO_WorldMap_MouseDown(button, ctrl, alt, shift)    
    end)

    polygon:SetHandler("OnMouseUp", function(control, button, upInside, ctrl, alt, shift, command)
      
      ZO_WorldMap_MouseUp(control, button, upInside)


      if (AWM.blobZoneInfo ~= nil and upInside and button == MOUSE_BUTTON_INDEX_LEFT) then

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

            navigateToMap(AWM.blobZoneInfo)

          end


        end


      end

      waitForRelease = false

    end)
      
  
    polygon:SetHandler("OnMouseEnter", function()

      if (not isInGamepadMode()) then
        updateCurrentPolygon(polygon)
      end

    end)
  
  else 
    -- it already exists, we just need to show it again
    WINDOW_MANAGER:GetControlByName(polygonID):SetHidden(false)
    WINDOW_MANAGER:GetControlByName(polygonID):SetMouseEnabled(true)
  end
end

-------------------------------------------------------------------------------
-- Compile map textures
-------------------------------------------------------------------------------

function compileMapTextures()

  AWM_TextureControl:SetAlpha(0)
  
  local hasError = false

  --print("getting blob info!")


  -- iterate through all of mapData
  for mapID, zoneData in pairs(mapData) do


    if (zoneData.zoneData ~= nil) then

      --print("got to here!")

      local zoneInfo = zoneData.zoneData

      for zoneIndex, zoneInfo in pairs(zoneInfo) do

        --print("checking zone info!")

        if (zoneInfo.zoneName ~= nil) then

          --print("there is a zone name!")

          if (zoneInfo.blobTexture == nil or (zoneInfo.nBlobTextureHeight == nil or zoneInfo.nBlobTextureWidth == nil) ) then

            --print("loading in textures!")

            local textureDirectory
            
            if (zoneInfo.blobTexture ~= nil) then
              textureDirectory = zoneInfo.blobTexture
            else
              textureDirectory = getFileDirectoryFromMapName(zoneInfo.zoneName)
            end

            -- load texture into control from name
            AWM_TextureControl:SetTexture(textureDirectory)

            -- check if texture exists before doing stuff
            if (AWM_TextureControl:IsTextureLoaded()) then

              -- get the dimensions
              local textureHeight, textureWidth = AWM_TextureControl:GetTextureFileDimensions()

              -- save texture name and dimensions
              mapData[mapID].zoneData[zoneIndex].blobTexture = textureDirectory
              mapData[mapID].zoneData[zoneIndex].nBlobTextureHeight = textureHeight / 4096
              mapData[mapID].zoneData[zoneIndex].nBlobTextureWidth = textureWidth / 4096

            else

              print("The following texture failed to load: "..textureDirectory)
              hasError = true

            end
          end
        end
      end
    end
  end

  -- if texture compilation has had no issues, then go ahead
  if (hasError == false and not AWM.areTexturesCompiled) then

    print("Successfully loaded.", true)
    AWM.areTexturesCompiled = true

  end
end

function parseMapData(mapID)

  if (mapID ~= nil) then


    print("Current map id: ".. mapID)


    -- Check if the current zone/map has any custom map data set to it
    if (mapData[mapID] ~= nil) then
      
      --print("This map has custom data!")


      if (mapData[mapID].isExclusive ~= nil) then
        isExclusive = mapData[mapID].isExclusive
      else
        isExclusive = false
      end


      if (mapData[mapID].zoneData ~= nil) then
        --print("This map has custom zone data!")
        local zoneData = mapData[mapID].zoneData

        for zoneAttribute, zoneInfo in pairs(zoneData) do


          if (zoneInfo.zoneName ~= nil) then

            print(zoneInfo.zoneName)

            print(tostring(zoneAttribute))
            print(tostring(zoneInfo))

            if (zoneInfo.xN ~= nil and zoneInfo.yN ~= nil) then
              if (zoneInfo.blobTexture ~= nil and zoneInfo.nBlobTextureHeight ~= nil and zoneInfo.nBlobTextureHeight ~= nil ) then
                if (zoneInfo.zonePolygonData ~= nil) then

                  createZoneHitbox(zoneInfo.zonePolygonData, zoneInfo)

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
-- Get polygon data by ID
-------------------------------------------------------------------------------

function getZoneHitboxPolygonByID(mapID)

  if (mapID ~= nil) then

    local zoneInfo = getZoneInfoByID(mapID)

    if (zoneInfo ~= nil and zoneInfo.zonePolygonData ~= nil) then

      local zonePolygonData = zoneInfo.zonePolygonData
      local polygonName = "AWM-TempPolygon"

      local newPolygon = WINDOW_MANAGER:GetControlByName(polygonName)

      if (newPolygon ~= nil) then

        newPolygon:ClearPoints()

      else
        newPolygon = ZO_WorldMapContainer:CreateControl(polygonName, CT_POLYGON)
      end

      for index, data in pairs(zonePolygonData) do  
        newPolygon:AddPoint(zonePolygonData[index].xN, zonePolygonData[index].yN)
      end

      return newPolygon

    end
  end
end

-------------------------------------------------------------------------------
-- Get polygon bounding box function
-------------------------------------------------------------------------------

function getPolygonBoundingBox(polygon)

  if (polygon ~= nil) then

    local leftMostCoord
    local rightMostCoord
    local topMostCoord
    local bottomMostCoord

    for i = 1, polygon:GetNumPoints() do -- loop through all polygon points

      local xN, yN = polygon:GetPoint(i)

      -- get left most side of rect
      if (leftMostCoord == nil or xN <= leftMostCoord) then
        leftMostCoord = xN
      end

      -- get right most side of rect
      if (rightMostCoord == nil or rightMostCoord <= xN) then
        rightMostCoord = xN
      end

      -- get top most side of rect
      if (topMostCoord == nil or yN <= topMostCoord) then
        topMostCoord = yN
      end

      -- get bottom most side of rect
      if (bottomMostCoord == nil or bottomMostCoord <= yN) then
        bottomMostCoord = yN
      end

    end

    -- top left corner
    local topLeft = { xN = leftMostCoord, yN = topMostCoord }

    -- top right corner
    local topRight = { xN = rightMostCoord, yN = topMostCoord }

    -- bottom left corner
    local bottomLeft = { xN = leftMostCoord, yN = bottomMostCoord }

    -- bottom right corner
    local bottomRight = { xN = rightMostCoord, yN = bottomMostCoord }

    local nWidth = rightMostCoord - leftMostCoord
    local nHeight = bottomMostCoord - topMostCoord

    local nOffsetX = leftMostCoord
    local nOffsetY = topMostCoord

    local nStart = topLeft

    print("Leftmost coord: "..leftMostCoord)
    print("Rightmost coord: "..rightMostCoord)
    print("Topmost coord: "..topMostCoord)
    print("Bottommost coord: "..bottomMostCoord)
    print("nWidth: "..nWidth)
    print("nHeight: "..nHeight)

    return nStart, nWidth, nHeight, nOffsetX, nOffsetY

  end

end

-------------------------------------------------------------------------------
-- Get zoneInfo object by name function
-------------------------------------------------------------------------------

function getZoneInfoByName(name)

  if (mapData ~= nil) then

    for mapID, mapInfo in pairs(mapData) do

      if (mapInfo.zoneName ~= nil) then

        local zoneInfo = mapInfo.zoneData

          for zoneIndex, zoneInfo in pairs(zoneInfo) do
        
            if (zoneInfo.zoneName == name) then
              return zoneInfo
            end
          end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Is Tamriel Map function
-------------------------------------------------------------------------------

function isMapTamriel(mapID)

  if (mapID == nil) then
    mapID = getCurrentMapID()
  end

  local zoneInfo = getZoneInfoByID(mapID)

  return (zoneInfo ~= nil and zoneInfo.zoneName == "Tamriel")

end

-------------------------------------------------------------------------------
-- Is Eltheric Map function
-------------------------------------------------------------------------------

function isMapEltheric(mapID)

  if (mapID == nil) then
    mapID = getCurrentMapID()
  end

  local zoneInfo = getZoneInfoByID(mapID)

  return (zoneInfo ~= nil and zoneInfo.zoneName == "Eltheric Ocean")

end

-------------------------------------------------------------------------------
-- Is Map Artaeum function
-------------------------------------------------------------------------------

function isMapArtaeum(mapID)

  local zoneInfo = getZoneInfoByID(mapID)

  return (zoneInfo ~= nil and zoneInfo.zoneName == "Artaeum")

end

-------------------------------------------------------------------------------
-- Is Map Aurbis function
-------------------------------------------------------------------------------

function isMapAurbis(mapID)

  local zoneInfo = getZoneInfoByID(mapID)

  return (zoneInfo ~= nil and zoneInfo.zoneName == "The Aurbis")

end

-------------------------------------------------------------------------------
-- Get Aurbis map ID function
-------------------------------------------------------------------------------

function getAurbisMapID()
  return 439
end

-------------------------------------------------------------------------------
-- Get Eltheric map ID function
-------------------------------------------------------------------------------

function getElthericMapID()
  return 315
end

-------------------------------------------------------------------------------
-- Get top level zone mapID function
-------------------------------------------------------------------------------

function getTopLevelZoneMapID(mapID)

  if (mapID == nil) then
    mapID = getCurrentMapID()
  end

  if(isMapArtaeum(mapID)) then
    return mapID
  end

  local zoneName, _, _, zoneIndex, _ = GetMapInfoById(mapID)

  if (zoneIndex ~= nil) then

    local zoneID = GetZoneId(zoneIndex)

    if (zoneID ~= nil) then

      local lastParentMapID = -100
      local parentMapID = GetMapIdByZoneId(GetParentZoneId(zoneID))
      local originalParentMapID = parentMapID

      -- get the top-most zone mapID
      while( lastParentMapID ~= parentMapID ) do

        parentMapID = GetMapIdByZoneId(GetParentZoneId(zoneID))

        if (lastParentID ~= parentMapID and parentMapID ~= nil) then
          lastParentMapID = parentMapID
        end

      end

      if (parentMapID ~= nil) then

        if (originalParentMapID == 0) then

          return mapID

        else

          -- fix fargrave being weird
          if (parentMapID == 2035) then

            return 2119

          else

            return parentMapID

          end
        end
      end
    end
  end
end

-------------------------------------------------------------------------------
-- Check if map is inside the Aurbis map
-------------------------------------------------------------------------------

function isMapInAurbis(mapID)

  if (mapID == nil) then
    mapID = getCurrentMapID()
  end

  local topLevelMapID = getTopLevelZoneMapID(mapID)
  local isInAurbis = false

  if (isMapTamriel(topLevelMapID) or isMapAurbis(topLevelMapID)) then
    return isInAurbis
  end

  -- does this map have custom defined data
  if (doesMapHaveCustomZoneData(topLevelMapID)) then

    local aurbisMapData = mapData[getAurbisMapID()].zoneData

    -- then check if it's in the aurbis
    for zoneIndex, data in pairs(aurbisMapData) do

      local zoneData = mapData[getAurbisMapID()].zoneData[zoneIndex]

      if (zoneData.zoneID == topLevelMapID) then

        isInAurbis = true

      end
    end
  end

  return isInAurbis
end

-------------------------------------------------------------------------------
-- Check if map is inside Eltheric Ocean map
-------------------------------------------------------------------------------

function isMapInEltheric(mapID)

  if (mapID == nil) then
    mapID = getCurrentMapID()
  end

  local topLevelMapID = getTopLevelZoneMapID(mapID)
  local isInEltheric = false

  -- does this map have custom defined data
  if (doesMapHaveCustomZoneData(topLevelMapID)) then

    local elthericMapData = mapData[getElthericMapID()].zoneData

    -- then check if it's in the eltheric
    for zoneIndex, data in pairs(elthericMapData) do

      local zoneData = mapData[getElthericMapID()].zoneData[zoneIndex]

      if (zoneData.zoneID == topLevelMapID) then

        isInEltheric = true

      end
    end
  end

  local parentMapSetToEltheric = false

  if (isInEltheric) then
    parentMapSetToEltheric = (mapData[mapID] ~= nil and mapData[mapID].parentMapID ~= nil and mapData[mapID].parentMapID == getElthericMapID() )
  end


  return (isInEltheric or parentMapSetToEltheric)
end

-------------------------------------------------------------------------------
-- Get zone bounding box function
-------------------------------------------------------------------------------

function getMapBoundingBoxByID(mapID)

  mapInfo = getZoneInfoByID(mapID)

  if (mapInfo ~= nil) then

    -- does a debug anchor texture exist for this map?
    if (mapInfo.nDebugBlobTextureWidth ~= nil) then

      return mapInfo.debugXN, mapInfo.debugYN, mapInfo.nDebugBlobTextureWidth, mapInfo.nDebugBlobTextureHeight

    else

      -- else return the normal blob texture
      return mapInfo.xN, mapInfo.yN, mapInfo.nBlobTextureWidth, mapInfo.nBlobTextureHeight

    end

  end
end
