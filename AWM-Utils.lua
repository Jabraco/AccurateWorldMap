--[[===========================================================================
                        AccurateWorldMap Utility Functions
===============================================================================

        Utility functions that didn't deserve to be in the main file.

---------------------------------------------------------------------------]]--

-------------------------------------------------------------------------------
-- Get base addon object
-------------------------------------------------------------------------------

AccurateWorldMap = AccurateWorldMap or {}

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
-- Print text to chat
-------------------------------------------------------------------------------

function print(message, isForced, ...)
  if (AccurateWorldMap.options.isDebug or isForced) then
    df("[%s] %s", AccurateWorldMap.name, tostring(message):format(...))
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

function isWorldMapShown()
  return not ZO_WorldMapContainer:IsHidden()
end
  
-------------------------------------------------------------------------------
-- Get world map offsets from the sides of the screen
-------------------------------------------------------------------------------

function getWorldMapOffsets()
  return math.floor(ZO_WorldMapContainer:GetLeft()), math.floor(ZO_WorldMapContainer:GetTop())
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

function getCurrentZoneID()

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
  local blacklistedZoneIDS = {1737, 315}

  -- does this map have a custom name / are custom names enabled? 
  if (hasValue(blacklistedZoneIDS, zoneID) or AccurateWorldMap.options.loreRenames) then

    if (getZoneInfoByID(zoneID) ~= nil) then

      return getZoneInfoByID(zoneID).zoneName

    else

      return GetMapNameById(zoneID)

    end

    return getZoneInfoByID(zoneID).zoneName

  else
    -- else return vanilla name
    return GetMapNameById(zoneID)

  end

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
-- Navigate map to provided map via map data object or ID
-------------------------------------------------------------------------------

function navigateToMap(mapInfo)

  local mapID

  -- mapInfo can be either an int or a zoneData object, need to determine which it is
  -- if it's a zoneData object, then it will have an id

  if (mapInfo ~= nil) then

    if (isNumeric(mapInfo)) then -- it is an int

      mapID = tonumber(mapInfo)

    else -- it is a zoneData object

      if (mapInfo.zoneID ~= nil) then -- it is a zoneData object

        mapID = mapInfo.zoneID
  
      end

    end

    currentPolygon = nil
    isInBlobHitbox = false
    SetMapToMapId(mapID)
    currentZoneInfo = {}
    CALLBACK_MANAGER:FireCallbacks("OnWorldMapChanged")
    -- force map to zoom out
    local mapPanAndZoom = ZO_WorldMap_GetPanAndZoom()
    mapPanAndZoom:SetCurrentNormalizedZoom(0)
      
  end

end

