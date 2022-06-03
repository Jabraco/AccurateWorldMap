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
local LMP = LibMapPing2

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
-- Map mouse enter / exit function
-------------------------------------------------------------------------------

-- Override what happens when the mouse enters or leaves worldmap

-------------------------------------------------------------------------------

ZO_PreHook("ZO_WorldMap_MouseEnter", function()

  if (not isInGamepadMode()) then

    AWMWaypointKeybind = {
      {
        name = "Set / Remove Destination",
        keybind = "UI_SHORTCUT_TERTIARY",
        callback = function() onWaypointSet(getNormalisedMouseCoordinates()) end,
      },
      alignment = KEYBIND_STRIP_ALIGN_CENTER,
    }

    if (not isChampionPointWindowShown() and isMouseWithinMapWindow() or AWM.currentlySelectedPolygon ~= nil) then
      KEYBIND_STRIP:AddKeybindButtonGroup(AWMWaypointKeybind)  
    end
  end
  return true
end)

ZO_PreHook("ZO_WorldMap_MouseExit", function()

  if (not isInGamepadMode() and not isChampionPointWindowShown() and not isMouseWithinMapWindow() ) then
    KEYBIND_STRIP:RemoveKeybindButtonGroup(AWMWaypointKeybind)
  end
  return true
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

      if (not string.match(AWM.currentlySelectedPolygon:GetName(), "duplicate")) then
        locationName = getZoneNameFromID(blobInfo.zoneID, true)
      else
        locationName = getZoneNameFromID(blobInfo.zoneID)
      end


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
      else
        AWM_MouseOverGrungeTex:SetHidden(true)
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

local zos_GetJournalQuestLocationInfo = GetJournalQuestLocationInfo
GetJournalQuestLocationInfo = function(questIndex)

  local zoneName, objectiveName, zoneIndex, poiIndex = zos_GetJournalQuestLocationInfo(questIndex)

  zoneName = getZoneNameFromID(GetMapIdByZoneId(GetZoneId(zoneIndex)))

  return zoneName, objectiveName, zoneIndex, poiIndex

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

    if (string.match(icon, "poi_raiddungeon_")) then -- and the icon is a Trial, then remove (this hides the duplicate Kyne's Aegis icon)
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

  if (mapData[mapIndex] ~= nil) then

    local zoneData = mapData[mapIndex]

    if (mapData[mapIndex][nodeIndex] ~= nil) then
      if (zoneData[nodeIndex] ~= nil) then 
        if (zoneData[nodeIndex].xN ~= nil and zoneData[nodeIndex].yN ~= nil) then
          normalizedX = zoneData[nodeIndex].xN
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

    -- if position tracking is enabled, we're in the Tamriel map, and the current node doesn't have any data, (or location data) then fallback to modded positioning
    if ( (isPlayerTrackingEnabled() and isMapTamriel())  and (isLocatedInCurrentMap) ) then
      if (zoneData[nodeIndex] == nil or (zoneData[nodeIndex] ~= nil and zoneData[nodeIndex].xN == nil and zoneData[nodeIndex].yN == nil)) then

        local zoneIndex, poiIndex = GetFastTravelNodePOIIndicies(nodeIndex)
        local parentMapID = getParentMapID(GetMapIdByZoneId(GetZoneId(zoneIndex)))

        if (doesMapHaveCustomZoneData(parentMapID)) then

          -- force correct wayshrine position placement
          local globalXN, globalYN = GetPOIMapInfo(zoneIndex, poiIndex)
          normalizedX, normalizedY = getFixedGlobalCoordinates(parentMapID, globalXN, globalYN)

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

-- Borrowed from Valve's GuildShrines addon. 

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

      -- Replace tiles with debug version if debug mode is enabled
      if AWM.options.isDebug then
        tileIndex = tostring(tileIndex) .. "_debug"  
      end
  
      return "AccurateWorldMap/tiles/" .. getCurrentZoneInfo().customTileName .. "_" .. tileIndex .. ".dds"
    end
  end
  return tileTexture
end

-------------------------------------------------------------------------------
-- Worldmap player pin & waypoint repositioning
-------------------------------------------------------------------------------

-- Override vanilla's player pin and waypoint positioning to be more consistent
-- with AWM's zone positioning

-------------------------------------------------------------------------------

if (isPlayerTrackingEnabled()) then

  zos_GetUniversallyNormalizedMapInfo = GetUniversallyNormalizedMapInfo
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

          --remember: the eltheric y offset already has the -0.14 built in
          normalisedOffsetX = -0.331420898
          normalisedOffsetY = 0.125502929
          normalisedWidth = 0.462524414
          normalisedHeight = 0.462524414

        else
          if (doesMapHaveCustomZoneData(mapID)) then

            -- if this map doesn't have custom data, but its parent does, then scale the current normalised position to inside of the main zone's one        
            if (getMapBoundingBoxByID(mapID) ~= nil) then

              print("custom data loaded")

              normalisedOffsetX, normalisedOffsetY, normalisedWidth, normalisedHeight = getMapBoundingBoxByID(mapID)
              normalisedOffsetY = normalisedOffsetY - 0.14000000059605
    
              -- if we're in the eltheric map, do special stuff
              if (isMapInEltheric(mapID)) then

                -- safety check in case something went wrong and our dataset is nil
                if (normalisedOffsetX ~= nil and normalisedOffsetY ~= nil and normalisedWidth ~= nil and normalisedHeight ~= nil) then
                  -- add back the Y offset
                  normalisedOffsetY = normalisedOffsetY + 0.14000000059605

                  -- get the offsets for eltheric map
                  local nOffsetX, nOffsetY, scale = GetUniversallyNormalizedMapInfo(getElthericMapID())

                  -- scale the current map to how it would be if it was in the tamriel map
                  normalisedWidth = normalisedWidth * scale
                  normalisedHeight = normalisedHeight * scale
                  normalisedOffsetX = (((1 - normalisedOffsetX) * nOffsetX) * scale) + normalisedWidth
                  normalisedOffsetY = nOffsetY + (normalisedOffsetY * scale)
                end
              end
            end
          end
        end
      end
    end

    -- safety check in case something went wrong and our dataset is nil, reset to vanilla values
    if (normalisedOffsetX == nil or normalisedOffsetY == nil or normalisedWidth == nil or normalisedHeight == nil) then
      normalisedOffsetX, normalisedOffsetY, normalisedWidth, normalisedHeight = zos_GetUniversallyNormalizedMapInfo(mapID)
    end

    print(("X Offset: " .. normalisedOffsetX), ("Y Offset: " .. normalisedOffsetY), ("Normalised width: " .. normalisedWidth), ("Normalised height: " .. normalisedHeight))

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
        local fixedX, fixedY = getFixedGlobalCoordinates(mapID, normalisedX, normalisedY)

        -- make player visible on the map if they're inside eyevea
        if (mapID == 108) then
          isShownInCurrentMap = true
        end

        return fixedX, fixedY, direction, isShownInCurrentMap
      end

      -- looking at Eltheric map
      if (isMapEltheric()) then

        local fixedLocalXN, fixedLocalYN = getFixedElthericCoordinates(mapID, normalisedX, normalisedY)

        return fixedLocalXN, fixedLocalYN, direction, true
      end
    end

    return normalisedX, normalisedY, direction, isShownInCurrentMap
  end


  -- local zos_PingMap = PingMap
  -- PingMap = function(pingType, mapDisplayType, normalisedX, normalisedZ)

  --   d("ping map called")

  --   d(pingType)
  --   d(mapDisplayType)

  
  --   zos_PingMap(pingType, mapDisplayType, normalisedX, normalisedZ)

  -- end


  -- SecurePostHook("GetMapPlayerWaypoint", function()
  --   d("waypoint set")

  --   local xN, yN = GetMapPlayerWaypoint()

  --   PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, xN, yN)
  -- end)

  -- PingMap(*[MapDisplayPinType|#MapDisplayPinType]* _pingType_, *[MapDisplayType|#MapDisplayType]* _mapDisplayType_, *number* _normalizedX_, *number* _normalizedZ_)

  local zos_GetMapPlayerWaypoint = GetMapPlayerWaypoint
  GetMapPlayerWaypoint = function()


    -- get vanilla values
    nX, nY = zos_GetMapPlayerWaypoint()
    local isGlobal = (isMapTamriel())

    -- if lastwaypoint map is nil, and we have a waypoint, then forcefully set it
    if (AWM.lastWaypointMapID == nil and isWaypointPlaced()) then
      AWM.lastWaypointMapID = getCurrentMapID()
      zo_callLater(function()
        LMP:SetMapPing(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, nX, nY)
        LMP:UnsuppressPing(MAP_PIN_TYPE_PLAYER_WAYPOINT, "waypoint")
        LMP:RefreshMapPin(MAP_PIN_TYPE_PLAYER_WAYPOINT, "waypoint")
        PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, nX, nY)
      end, 300 )
      return nX, nY
    end

    -- if there is a waypoint set somewhere
    if (AWM.lastWaypointMapID ~= nil and isWaypointPlaced() and not isMapInAurbis(AWM.lastWaypointMapID)) then

      d("waypoint being automatically placed")

      -- if we are in Eltheric or Tamriel and there is a waypointer set in in an aurbis realm
      if ( (isMapTamriel() or isMapEltheric()) and isMapInAurbis(AWM.lastWaypointMapID)) then
        return -10, 0 -- return something big to get it out of the way
      end

      -- if the current map we're in has no modded data, return vanilla
      if (not doesMapHaveCustomZoneData(getCurrentMapID())) then
        AWM.lastWaypointMapID = getCurrentMapID()
        return nX, nY
      end

      -- if the current map we're in has modded data, but the previous map did not,
      -- but both were under the same parent zone, return vanilla
      if (doesMapHaveCustomZoneData(getCurrentMapID()) and not doesMapHaveCustomZoneData(AWM.lastWaypointMapID) and getParentMapID(AWM.lastWaypointMapID) == getParentMapID(getCurrentMapID())) then
        AWM.lastWaypointMapID = getCurrentMapID()
        AWM.lastLocalXN = nX
        AWM.lastLocalYN = nY
        return nX, nY
      end

      -- if we're in tamriel map now, but weren't before
      if (isGlobal and not isMapTamriel(AWM.lastWaypointMapID)) then

        if (AWM.lastGlobalXN ~= nil and AWM.lastGlobalYN ~= nil) then
          AWM.lastWaypointMapID = getTamrielMapID()
          return AWM.lastGlobalXN, AWM.lastGlobalYN

        else

          d("calclating fixed globals")
          nX, nY = getFixedGlobalCoordinates(AWM.lastWaypointMapID, nX, nY)
  
          AWM.lastWaypointMapID = getTamrielMapID()
          AWM.lastGlobalXN = nX
          AWM.lastGlobalYN = nY
  
          return nX, nY

        end
      end

      -- if we're in a local map now, but we were in tamriel before
      if (not isGlobal and isMapTamriel(AWM.lastWaypointMapID)) then

        d("returning modded local!")
        nX, nY = getFixedLocalCoordinates(getCurrentMapID(), nX, nY)

        AWM.lastWaypointMapID = getCurrentMapID()
        AWM.lastLocalXN = nX
        AWM.lastLocalYN = nY

        return nX, nY
      end

      -- if we're in a different local map as before
      if (not isGlobal and not isMapTamriel(AWM.lastWaypointMapID) and AWM.lastWaypointMapID == getCurrentMapID()) then

        -- do stuff

      end

    else
      AWM.lastWaypointMapID = nil
      return nX, nY
    end
  end
end