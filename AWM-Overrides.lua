--[[===========================================================================
                        AccurateWorldMap Overrides
===============================================================================

        Functions that AccurateWorldMap needs to override in order to
                              work properly.

---------------------------------------------------------------------------]]--

-------------------------------------------------------------------------------
-- Get base addon object and dependencies
-------------------------------------------------------------------------------

AWM = AWM or {}
local LZ = LibZone 
local GPS = LibGPS3


-- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
-- ██░▄▄▀██░▄▄▄░██░▄▀▄░██░▄▄░█░▄▄▀█▄▄░▄▄█▄░▄██░▄▄▀█▄░▄██░████▄░▄█▄▄░▄▄██░███░████░▄▄░█░▄▄▀█▄▄░▄▄██░▄▄▀██░██░██░▄▄▄██░▄▄▄░██
-- ██░█████░███░██░█░█░██░▀▀░█░▀▀░███░████░███░▄▄▀██░███░█████░████░████▄▀▀▀▄████░▀▀░█░▀▀░███░████░█████░▄▄░██░▄▄▄██▄▄▄▀▀██
-- ██░▀▀▄██░▀▀▀░██░███░██░████░██░███░███▀░▀██░▀▀░█▀░▀██░▀▀░█▀░▀███░██████░██████░████░██░███░████░▀▀▄██░██░██░▀▀▀██░▀▀▀░██
-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

-------------------------------------------------------------------------------
-- Compatibility patch for True Exploration
-------------------------------------------------------------------------------

-- Mark the Eltheric Ocean map as a MAPTYPE_WORLD so that True Exploration
-- doesn't fade it out.

-------------------------------------------------------------------------------

local zos_GetMapType = GetMapType
function GetMapType()

  local mapType = zos_GetMapType()

  if (getCurrentMapID() == getElthericMapID()) then
    return MAPTYPE_WORLD
  end

  return mapType
end

-- ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄
-- ██░▄▄▄░██░▄▄▄░██░▄▄▄░████░▄▄▄██░██░██░▀██░██░▄▄▀█▄▄░▄▄█▄░▄██░▄▄▄░██░▀██░██░▄▄▄░██
-- ██▀▀▀▄▄██░███░██▄▄▄▀▀████░▄▄███░██░██░█░█░██░██████░████░███░███░██░█░█░██▄▄▄▀▀██
-- ██░▀▀▀░██░▀▀▀░██░▀▀▀░████░█████▄▀▀▄██░██▄░██░▀▀▄███░███▀░▀██░▀▀▀░██░██▄░██░▀▀▀░██
-- ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀

-------------------------------------------------------------------------------
-- Worldmap click events
-------------------------------------------------------------------------------

-- Override vanilla's worldmap's click functions so that clicks don't get passed
-- to vanilla zone locations on isExclusive maps, as well as making sure that
-- our custom zone blobs get the click priority. 

-------------------------------------------------------------------------------

ZO_PreHook("ProcessMapClick", function(xN, yN)

  if ((AWM.isInsideBlobHitbox and AWM.blobZoneInfo ~= nil) or getIsCurrentMapExclusive()) then

    -- handle zone clicks if in gamepad mode
    if (isInGamepadMode() and (AWM.isInsideBlobHitbox and AWM.blobZoneInfo ~= nil)) then
      navigateToMap(AWM.blobZoneInfo)
    end

    return true
  end

end)

ZO_PreHook("ZO_WorldMap_MouseUp", function(mapControl, mouseButton, upInside)

  if (mouseButton == MOUSE_BUTTON_INDEX_RIGHT and upInside) then
    if (mapData[getCurrentMapID()] ~= nil and mapData[getCurrentMapID()].parentMapID ~= nil) then

        navigateToMap(mapData[getCurrentMapID()].parentMapID)
        return true
        
    end
  end
end)

-------------------------------------------------------------------------------
-- Map mouseover info function
-------------------------------------------------------------------------------

-- Override vanilla's map mouseover info function to prevent vanilla highlight
-- blobs from showing on the map, and to show our own.

-------------------------------------------------------------------------------

local zos_GetMapMouseoverInfo = GetMapMouseoverInfo
GetMapMouseoverInfo = function(xN, yN)

  local mapID = getCurrentMapID()

  -- invisible blank default mouseover data
  local locationName = ""
  local textureFile = "" 
  local widthN = 0.01
  local heightN = 0.01
  local locXN = 0
  local locYN = 0

  -- if the current map is not set to exclusive, or we don't have any data for it, get vanilla values for the current position
  if (not getIsCurrentMapExclusive() or not doesCurrentMapHaveCustomZoneData()) then
   locationName, textureFile, widthN, heightN, locXN, locYN = zos_GetMapMouseoverInfo(xN, yN)
  end

  if (doesCurrentMapHaveCustomZoneData()) then

    if (AWM.isInsideBlobHitbox and AWM.currentlySelectedPolygon ~= nil) then 

      local blobInfo = AWM.blobZoneInfo

      locationName = getZoneNameFromID(blobInfo.zoneID)

      if (AWM.options.isDebug and blobInfo.nDebugBlobTextureWidth ~= nil) then

        textureFile = blobInfo.debugBlobTexture
        widthN = blobInfo.nDebugBlobTextureWidth
        heightN = blobInfo.nDebugBlobTextureHeight
        locXN = blobInfo.debugXN
        locYN = blobInfo.debugYN

      else

        textureFile = blobInfo.blobTexture
        widthN = blobInfo.nBlobTextureWidth
        heightN = blobInfo.nBlobTextureHeight
        locXN = blobInfo.xN
        locYN = blobInfo.yN
      end

      
      if (blobInfo.zoneDescription ~= nil and AWM.options.zoneDescriptions == true) then
        ZO_WorldMapMouseOverDescription:SetText(blobInfo.zoneDescription)
      end

    end

  end

  return locationName, textureFile, widthN, heightN, locXN, locYN
end

-------------------------------------------------------------------------------
-- Zone name functions
-------------------------------------------------------------------------------

-- Override ESO's zone names with AccurateWorldMap's custom ones.

-------------------------------------------------------------------------------

local zos_GetMapTitle = ZO_WorldMap_GetMapTitle
ZO_WorldMap_GetMapTitle = function()
  return getZoneNameFromID(getCurrentMapID())
end


local zos_GetZoneNameByIndex = GetZoneNameByIndex
GetZoneNameByIndex = function(zoneIndex)
  return getZoneNameFromID(GetMapIdByZoneId(GetZoneId(zoneIndex)))
end


local zos_GetMapInfoByIndex = GetMapInfoByIndex
function GetMapInfoByIndex(zoneIndex)
    local mapName, mapType, mapContentType, zoneIndex, description = zos_GetMapInfoByIndex(zoneIndex)


    if (getZoneNameFromID(GetMapIdByZoneId(GetZoneId(zoneIndex))) ~= "") then
      mapName = getZoneNameFromID(GetMapIdByZoneId(GetZoneId(zoneIndex)))
    end

    return mapName, mapType, mapContentType, zoneIndex, description
end

-------------------------------------------------------------------------------
-- Map zoom controller
-------------------------------------------------------------------------------

-- Override vanilla's map zoom levels with any custom defined ones.

-------------------------------------------------------------------------------

local zos_GetMapCustomMaxZoom = GetMapCustomMaxZoom
GetMapCustomMaxZoom = function()
  if (getCurrentZoneInfo() ~= nil and getCurrentZoneInfo().zoomLevel ~= nil ) then
    return getCurrentZoneInfo().zoomLevel
  else
    return zos_GetMapCustomMaxZoom()
  end
end

-------------------------------------------------------------------------------
-- Map POI icon controller
-------------------------------------------------------------------------------

-- Override vanilla's map POI icon info with AccurateWorldMap custom data.

-------------------------------------------------------------------------------

local zos_GetPOIMapInfo = GetPOIMapInfo
GetPOIMapInfo = function(zoneIndex, poiIndex)

  local normalisedX, normalisedZ, poiPinType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby = zos_GetPOIMapInfo(zoneIndex, poiIndex)

  if (getCurrentMapID() == 1719) then -- if we are in Western Skyrim

    if (string.match(icon, "poi_raiddungeon_")) then -- and the icon is a Trial, then remove
      isShownInCurrentMap = false
      isNearby = false
      icon = nil
    end

  end
  return normalisedX, normalisedZ, poiPinType, icon, isShownInCurrentMap, linkedCollectibleIsLocked, isDiscovered, isNearby
end

-------------------------------------------------------------------------------
-- Map wayshrine/dungeon node icon controller
-------------------------------------------------------------------------------

-- Controls placement, display, and location of wayshrine/dungeon/house icons.

-------------------------------------------------------------------------------

local zos_GetFastTravelNodeInfo = GetFastTravelNodeInfo    
GetFastTravelNodeInfo = function(nodeIndex)
  local known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked, disabled = zos_GetFastTravelNodeInfo(nodeIndex)

  if AWM.options.isDebug == true then
        d("Current Node: "..nodeIndex)
        d("Name: "..name)
        d(" ")
  end

  local mapIndex = getCurrentMapID()

  if (AWM.options.hideIconGlow) then
    glowIcon = nil
  end

  if (mapData[mapIndex] ~= nil and mapData[mapIndex][nodeIndex] ~= nil) then

    local zoneData = mapData[mapIndex]

    if (zoneData[nodeIndex] ~= nil) then 
      if zoneData[nodeIndex].xN ~= nil then
        normalizedX = zoneData[nodeIndex].xN
      end

      if zoneData[nodeIndex].yN ~= nil then
        normalizedY = zoneData[nodeIndex].yN
      end

      if (zoneData[nodeIndex].name ~= nil and AWM.options.loreRenames) then
        name = zoneData[nodeIndex].name
      end

      if zoneData[nodeIndex].disabled ~= nil then

        if (zoneData[nodeIndex].disabled) then

          isLocatedInCurrentMap = false
          disabled = true

        else

          isLocatedInCurrentMap = true
          disabled = false

        end
      end
    end

  end

  if (getCurrentZoneInfo() ~= nil and getCurrentZoneInfo().isWorldMap) then

    if (AWM.options.worldMapWayshrines == "None" or AWM.options.worldMapWayshrines == "Only Major Settlements") then

      isLocatedInCurrentMap = false
      disabled = true

    end

    if (mapData[mapIndex] ~= nil and mapData[mapIndex][nodeIndex] ~= nil) then

      if (mapData[mapIndex][nodeIndex].majorSettlement ~= nil and AWM.options.worldMapWayshrines == "Only Major Settlements") then

        isLocatedInCurrentMap = true
        disabled = false

      end

    end

  end

  return known, name, normalizedX, normalizedY, icon, glowIcon, poiType, isLocatedInCurrentMap, linkedCollectibleIsLocked, disabled
end

-------------------------------------------------------------------------------
-- Map pin tooltip controller
-------------------------------------------------------------------------------

-- Overrides default tooltip handler to add custom tooltips to Eyevea and Earth 
-- Forge wayshrines in both gamepad and keyboard & mouse mode.

-- Borrowed from GuildShrines addon. 

-------------------------------------------------------------------------------

ZO_MapPin.TOOLTIP_CREATORS[MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE].creator = function(pin)
  local nodeIndex = pin:GetFastTravelNodeIndex()
  local _, name, _, _, _, _, _, _, _, disabled = GetFastTravelNodeInfo(nodeIndex)
  local info_tooltip

  if not isInGamepadMode() then 
    if not disabled then
      if nodeIndex ~= 215 and nodeIndex ~= 221 or ZO_Map_GetFastTravelNode() then -- Eyevea and the Earth Forge cannot be "jumped" to so we'll add "This area is not accessible via jumping." when they're not using a wayshrine
        InformationTooltip:AppendWayshrineTooltip(pin)																			-- Normal Wayshrine tooltip data
      else
        InformationTooltip:AddLine(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())	-- Wayshrine Name
        InformationTooltip:AddLine("This location can only be accessed via other Wayshrines.", "", 1, 0, 0)				-- "This area is not accessible via jumping."
      end	
    else
      InformationTooltip:AddLine(zo_strformat(SI_WORLD_MAP_LOCATION_NAME, name), "", ZO_TOOLTIP_DEFAULT_COLOR:UnpackRGB())		-- Wayshrine Name Only (unknown wayshrine)
    end		
  else
    if not disabled then 
      if nodeIndex ~= 215 and nodeIndex ~= 221 or ZO_Map_GetFastTravelNode() then -- Eyevea and the Earth Forge cannot be "jumped" to so we'll add "This area is not accessible via jumping." when they're not using a wayshrine 
        ZO_MapLocationTooltip_Gamepad:AppendWayshrineTooltip(pin)
      else
        local lineSection = ZO_MapLocationTooltip_Gamepad.tooltip:AcquireSection(ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapMoreQuestsContentSection"))
        lineSection:AddLine(name, ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapLocationTooltipContentLabel"), ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("gamepadElderScrollTooltipContent"))									-- Wayshrine Name
        lineSection:AddLine(GetString("This location can only be accessed via other Wayshrines."), ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapLocationTooltipContentLabel"), ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("gamepadElderScrollTooltipContent"))	-- "This area is not accessible via jumping."
        ZO_MapLocationTooltip_Gamepad.tooltip:AddSection(lineSection)
      end
    else
      local lineSection = ZO_MapLocationTooltip_Gamepad.tooltip:AcquireSection(ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapMoreQuestsContentSection"))
      lineSection:AddLine(name, ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("mapLocationTooltipContentLabel"), ZO_MapLocationTooltip_Gamepad.tooltip:GetStyle("gamepadElderScrollTooltipContent")) -- Wayshrine Name Only (unknown wayshrine)
      ZO_MapLocationTooltip_Gamepad.tooltip:AddSection(lineSection)
    end
  end
end

-------------------------------------------------------------------------------
-- Map tile texture controller
-------------------------------------------------------------------------------

-- Overrides certain map's textures with AccurateWorldMap ones if a custom
-- tile name is specified.

-------------------------------------------------------------------------------

local zos_GetMapTileTexture = GetMapTileTexture
GetMapTileTexture = function(tileIndex)

  local tileTexture = zos_GetMapTileTexture(tileIndex)

  if (tileIndex ~= nil) then

    if (getCurrentZoneInfo() ~= nil and getCurrentZoneInfo().customTileName ~= nil) then

      -- Replace tiles with debug version if debug is enabled
      if AWM.options.isDebug then
        tileIndex = tostring(tileIndex) .. "_debug"  
      end
  
      return "AccurateWorldMap/tiles/" .. getCurrentZoneInfo().customTileName .. "_" .. tileIndex .. ".dds"
  
    end
  end
  
  return tileTexture
end

-------------------------------------------------------------------------------
-- Worldmap player pin & waypoint positioning
-------------------------------------------------------------------------------

-- Override vanilla's player pin and waypoint positioning to be more consistent
-- with AccurateWorldMap's zone positioning

-------------------------------------------------------------------------------

local zos_GetUniversallyNormalizedMapInfo = GetUniversallyNormalizedMapInfo
GetUniversallyNormalizedMapInfo = function(mapID)

  local normalisedOffsetX, normalisedOffsetY, normalisedWidth, normalisedHeight = zos_GetUniversallyNormalizedMapInfo(mapID)

  d("Requesting normalised map info for map " .. mapID)

  if (not isMapTamriel(mapID)) then

    if (isMapInAurbis(mapID)) then

      -- hide daedric realms off the north edge of the map so that they can't be seen
      normalisedOffsetX = 0
      normalisedOffsetY = -0.8
      normalisedWidth = 0.2
      normalisedHeight = 0.2

    else

      if (isMapEltheric(mapID)) then

        --remember: the eltheric height offset already has the -0.14 built in
        normalisedOffsetX = -0.331420898
        normalisedOffsetY = 0.125502929
        normalisedWidth = 0.462524414
        normalisedHeight = 0.462524414

      else
        if (doesMapHaveCustomZoneData(mapID)) then

          -- if this map doesn't have custom data, but its parent does, then scale the current normalised position to inside of the main zone's one

          print("custom data detected")
      
          if (getMapBoundingBoxByID(mapID) ~= nil) then

            print("custom data loaded")

            normalisedOffsetX, normalisedOffsetY, normalisedWidth, normalisedHeight = getMapBoundingBoxByID(mapID)
            normalisedOffsetY = normalisedOffsetY - 0.14000000059605
  
          end


          if (isMapInEltheric(mapID)) then

            -- todo: only do this for custom zones in the eltheric and not everything that's within high isle (inc subzones)

            local nOffsetX, nOffsetY, scale = GetUniversallyNormalizedMapInfo(getElthericMapID())

            normalisedOffsetX = ((1 - normalisedOffsetX) * nOffsetX) * scale
            normalisedOffsetY = nOffsetY + (normalisedOffsetY * scale)
            -- normalisedWidth = normalisedWidth * scale
            -- normalisedHeight = normalisedHeight * scale


          end
        end
      end
    end
  end


  -- safety check in case something went wrong and our dataset is nil, reset to vanilla values
  if (normalisedOffsetX == nil or normalisedOffsetY == nil or normalisedWidth == nil or normalisedHeight == nil) then
    normalisedOffsetX, normalisedOffsetY, normalisedWidth, normalisedHeight = zos_GetUniversallyNormalizedMapInfo(mapID)
  end

  d(("X Offset: " .. normalisedOffsetX), ("Y Offset: " .. normalisedOffsetY), ("Normalised width: " .. normalisedWidth), ("Normalised height: " .. normalisedHeight) )

  return normalisedOffsetX, normalisedOffsetY, normalisedWidth, normalisedHeight

end

local zos_GetMapPlayerPosition = GetMapPlayerPosition
GetMapPlayerPosition = function(unitTag)

  normalisedX, normalisedY, direction, isShownInCurrentMap = zos_GetMapPlayerPosition(unitTag)

  local zoneID, _, _, _ = GetUnitRawWorldPosition(unitTag)
  zoneID = getParentZoneID(zoneID)
  local mapID = GetMapIdByZoneId(zoneID)

  if (mapID ~= nil or mapID ~= 0) then

    -- looking at Tamriel map
    if (isMapTamriel()) then

      -- get vanilla blob offsets and position for a map
      local nOffsetX, nOffsetY, nWidth, nHeight = zos_GetUniversallyNormalizedMapInfo(mapID)

      

      -- use that to get where the player is in that map
      local nLocalX = (normalisedX - nOffsetX) / nWidth --nWidth = scale
      local nLocalY = (normalisedY - (nOffsetY + 0.14000000059605)) / nHeight -- nHeight = scale

      --d(nLocalX, nLocalY)

      if (GPS:GetMapMeasurementByMapId(mapID) ~= nil) then

        local measurement = GPS:GetMapMeasurementByMapId(mapID)
        if (measurement ~= nil) then
  
          -- then transform those coordinates inside the bounds of AWM's fixed blob positions
          local fixedX, fixedY = measurement:ToGlobal(nLocalX, nLocalY)
  
          --d(fixedX, fixedY)
    
          return fixedX, fixedY, direction, isShownInCurrentMap

        end
      end
    end

    -- looking at Eltheric map
    if (isMapEltheric()) then

      -- get the current vanilla global position values from the jodewood (what the eltheric is)
      local offsetX, offsetY, scaleX, scaleY = zos_GetUniversallyNormalizedMapInfo(getElthericMapID())
      local globalX = normalisedX * scaleX + offsetX
      local globalY = normalisedY * scaleY + (offsetY + 0.14000000059605)

      -- get vanilla blob offsets and position for the current map
      local nOffsetX, nOffsetY, nWidth, nHeight = zos_GetUniversallyNormalizedMapInfo(mapID)

      -- use that to get the localised player coordinates in that map
      local nLocalX = (globalX - nOffsetX) / nWidth --nWidth = scale
      local nLocalY = (globalY - (nOffsetY + 0.14000000059605)) / nHeight -- nHeight = scale

      --d(nLocalX, nLocalY)
      
      if (GPS:GetMapMeasurementByMapId(mapID) ~= nil) then

        local measurement = GPS:GetMapMeasurementByMapId(mapID)
        if (measurement ~= nil) then

          -- then transform those coordinates inside the bounds of AWM's fixed blob positions
          local fixedGlobalX, fixedGlobalY = measurement:ToGlobal(nLocalX, nLocalY)

          -- and then transform that into the bounds of the custom Eltheric Map and return
          local elthericMeasurement = GPS:GetMapMeasurementByMapId(getElthericMapID())
          local fixedLocalX, fixedLocalY = elthericMeasurement:ToLocal(fixedGlobalX, fixedGlobalY)

          return fixedLocalX, fixedLocalY, direction, true
    
        end
      end
    end
  end

  return normalisedX, normalisedY, direction, isShownInCurrentMap
end



local zos_GetMapPlayerWaypoint = GetMapPlayerWaypoint
GetMapPlayerWaypoint = function()

  -- this function places a waypoint every time the map changes
  -- we can override its data based on what we know of the world and of the previous map
  -- if the previous map was local, and we have set a local waypoint, then we need to convert
  -- to global

  -- likewise if the previous map was global, and we are local, then we need to convert to local

  -- if the previous map was global, then do nothing

  -- check if the last map was global or local
  -- if it was global, then do nothing

  -- local to global ONLY works when we are inside that local map, so that has to be calculated BEFORE map switch
  -- if local to global is nil, then ignorei t

  d("waypoint placed")

  -- get vanilla values
  normalisedX, normalisedY = zos_GetMapPlayerWaypoint()

  
  local isGlobal = (isMapTamriel())

  if (AWM.wpData ~= nil) then
    return AWM.wpData.xN, AWM.wpData.yN
  else
    return normalisedX, normalisedY
  end
end


