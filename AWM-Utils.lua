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

function isInGamepadMode()
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

  -- does this map have a custom name / are custom names enabled? 
  if ((getZoneInfoByID(zoneID) ~= nil and getZoneInfoByID(zoneID).overrideLoreRenames ~= nil) or AWM.options.loreRenames) then

    if (getZoneInfoByID(zoneID) ~= nil) then

      return getZoneInfoByID(zoneID).zoneName

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

  return (getCurrentZoneInfo() ~= nil and (getCurrentZoneInfo().isExclusive ~= nil and getCurrentZoneInfo().isExclusive)) 

end


-------------------------------------------------------------------------------
-- Get whether the current map has custom zone data or not
-------------------------------------------------------------------------------

function doesCurrentMapHaveCustomZoneData()

  return (mapData[getCurrentMapID()] ~= nil and mapData[getCurrentMapID()].zoneData ~= nil)

end

