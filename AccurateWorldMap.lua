--[[===========================================================================
                AccurateWorldMap, by BroughBreaux & Thal-J
===============================================================================

-- ascii title art done on https://texteditor.com/ascii-art/
-- https://textfancy.com/multiline-text-art/


Todo:

Things that need to be done before release:

TJ:

- Remove version number from addon settings header
- Fix player location being incorrect (and also group pins)
- Implement proper waypoint and player marker tracking and moving
- Find a way to move the zone name and clock to be closer to the actual map in K&M mode like gamepad
- Sort out breaux's custom K&M and gamepad desc grunge design
- allow setting waypoints on the zone blobs
- fix zone blobs appearing on map transition
- Update IsJustaGhost's LibZone PR to explain changes and stuff as per baertram


Breaux:

- Fix the Aurbis tamriel blob - mismatches with what is there currently
- Fix Aurbis rings not containing their proper daedric/elven text
- Fix Dreadsail Reef blob being too big

Fix the following zone colouring and glow issues:

- dreadsail
- swords rest
- balfiera
- icereach
-greyhome
- tideholm (is now a separate blob)
- wasten coraldale (is now a separate blob)
- eyevea ?
- firemoth?
- fort grief?
- stirk & tempest island?
- two mini summerset quest islands?


Optional:
- Add IC Sewers circle to IC map and get blob
- Rotate IC on the cyrodiil map 45 degrees to be consistent with oblivion (edit the tiles)
https://cdn.discordapp.com/attachments/806672739057664034/975049286305861672/unknown.png



Interesting events to consider:
GetDisplayName() returns user id 
use that to make an isDeveloper() function


* GetPlayerActiveZoneName()
** _Returns:_ *string* _zoneName_

---------------------------------------------------------------------------]]--
-- Create root addon object
-------------------------------------------------------------------------------

-- set saved variable version number
AWM.variableVersion = 3

-- set default options
AWM.defaults = {
  isDebug = false,
  zoneDescriptions = false,
  loreRenames = true,
  mapStyle = "Vanilla",
  worldMapWayshrines = "All (Default)",
  hideIconGlow = false,
  movePlayerIcons = false,
}

-------------------------------------------------------------------------------
-- Dependency initialisation
-------------------------------------------------------------------------------

local LAM = LibAddonMenu2
local GPS = LibGPS3
local LMP = LibMapPing2
local LZ = LibZone 

-------------------------------------------------------------------------------
-- Globals
-------------------------------------------------------------------------------

-- objects
AWM.blobZoneInfo = {}
AWM.currentlySelectedPolygon = nil
polygonData = {}

AWM.wpData = {}

AWM.canRedrawMap = true
AWM.areTexturesCompiled = false
AWM.isInsideBlobHitbox = false
local recordCoordinates = false
local hasDragged = false
local waitForRelease = false

-- ints
local coordinateCount = 0

-------------------------------------------------------------------------------
-- Create map info background texture control
-------------------------------------------------------------------------------

AWM_MouseOverGrungeTex = CreateControl("AWM_MouseOverGrungeTex", ZO_WorldMap, CT_TEXTURE)
AWM_MouseOverGrungeTex:SetTexture("/esoui/art/performance/statusmetermunge.dds")

-------------------------------------------------------------------------------
--  On map change callback function
-------------------------------------------------------------------------------

local function onMapChanged()

  -- hide all existing zone blobs
  hideAllZoneBlobs()

  -- hide map info description background
  AWM_MouseOverGrungeTex:SetHidden(true)

  -- parse current map for any custom data
  parseMapData(getCurrentMapID())




end

-------------------------------------------------------------------------------
-- On waypoint / map ping added function
-------------------------------------------------------------------------------

local function globalToLocal()
  print("Global to Local:", true)
  d(GPS:GlobalToLocal(getNormalisedMouseCoordinates()))
end

local function localToGlobal()
  print("Local to Global:", true)
  d(GPS:LocalToGlobal(getNormalisedMouseCoordinates()))
end


local function onPingAdded(pingType, pingTag, xN, yN, isPingOwner)

  if (isMapTamriel()) then
    AWM.wpData.previousMap = "GLOBAL"
    AWM.wpData.lastWaypointType = "GLOBAL"
    AWM.wpData.globalYN, AWM.wpData.globalYN = xN, yN
  else
    AWM.wpData.previousMap = "LOCAL"
    AWM.wpData.lastWaypointType = "LOCAL"
    AWM.wpData.xN, AWM.wpData.yN = GPS:LocalToGlobal(xN, yN)
  end


  d("\n")
  d(AWM.wpData.lastWaypointType)

end

-------------------------------------------------------------------------------
-- On mouse clicked function
-------------------------------------------------------------------------------

local function onMouseClicked()

  if (isMouseWithinMapWindow()) then

    if (recordCoordinates) then 
      PlaySound(SOUNDS.COUNTDOWN_TICK)

      local xNormalised, yNormalised = getNormalisedMouseCoordinates()
      table.insert(polygonData, {xN = xNormalised, yN = yNormalised})
      coordinateCount = coordinateCount + 1

    end
  end
end

-------------------------------------------------------------------------------
-- Record new zone polygon function
-------------------------------------------------------------------------------

local function recordPolygon()

  if recordCoordinates == true then
    d("Coordinates recorded.")

    createZoneHitbox(polygonData)

    polygonData = {}
    coordinateCount = 0
    recordCoordinates = false
  end

  if recordCoordinates == false then
    d("Recording coordinates... click on the map to draw a polygon")
    recordCoordinates = true
  end
end

-------------------------------------------------------------------------------
-- On blob updated function
-------------------------------------------------------------------------------

function updateCurrentPolygon(polygon) 


  currentMapIndex = getCurrentMapID()
  AWM.isInsideBlobHitbox = true
  AWM.currentlySelectedPolygon = polygon

  if (AWM.options.zoneDescriptions == true) then

    if (not isInGamepadMode()) then
      AWM_MouseOverGrungeTex:SetHidden(false)
    end

  end


  -- update with current zone info
  if (not string.match(polygon:GetName(), "duplicate")) then

    AWM.blobZoneInfo = getZoneInfoByID(getMapIDFromPolygonName(polygon:GetName()), true)

  else

    AWM.blobZoneInfo = getZoneInfoByID(getMapIDFromPolygonName(polygon:GetName()))

  end
  
end

-------------------------------------------------------------------------------
-- On world map opened
-------------------------------------------------------------------------------

local function onWorldMapOpened()
  
  if (AWM.canRedrawMap) then

    AWM.canRedrawMap = false

    local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
    local enlargeConst = 1.5
  
    AWM_MouseOverGrungeTex:ClearAnchors()
    AWM_MouseOverGrungeTex:SetAnchor(TOPLEFT, ZO_WorldMap, TOPLEFT, (mapWidth - (mapWidth*enlargeConst))/2, -(0.47 * mapHeight))
    AWM_MouseOverGrungeTex:SetDrawTier(DT_PARENT)
    AWM_MouseOverGrungeTex:SetDimensions(mapWidth*enlargeConst, mapHeight)
    AWM_MouseOverGrungeTex:SetDrawLayer(DL_OVERLAY)
    AWM_MouseOverGrungeTex:SetDrawLayer(DL_CONTROLS)
    AWM_MouseOverGrungeTex:SetAlpha(0.55)
    AWM_MouseOverGrungeTex:SetHidden(true)
  
    -- set up map description label control
    ZO_WorldMapMouseOverDescription:SetFont("ZoFontGameLargeBold")
    ZO_WorldMapMouseOverDescription:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
  
    ZO_WorldMapMouseOverDescription:ClearAnchors()
  
    local mapDescPaddingAmount = mapWidth * 0.15
  
    ZO_WorldMapMouseOverDescription:SetAnchor(TOPLEFT, ZO_WorldMapMouseoverName, BOTTOMLEFT, mapDescPaddingAmount, 2)
    ZO_WorldMapMouseOverDescription:SetAnchor(TOPRIGHT, ZO_WorldMapMouseoverName, BOTTOMRIGHT, -(mapDescPaddingAmount), 2)
  
    if (not isInGamepadMode()) then
      ZO_WorldMap:SetAutoRectClipChildren(true)
      ZO_WorldMapContainerRaggedEdge:SetHidden(true)
    else
      ZO_WorldMap:SetAutoRectClipChildren(false)
      ZO_WorldMapContainerRaggedEdge:SetHidden(false)
    end
  end
end

-------------------------------------------------------------------------------
-- Main addon event loop
-------------------------------------------------------------------------------

local function main()
  if (isWorldMapShown() and isMouseWithinMapWindow()) then

    if (isInGamepadMode()) then

      if (AWM.currentlySelectedPolygon == nil) then
  
        tempPolygon = WINDOW_MANAGER:GetControlAtPoint(getMouseCoordinates())
  
        print(tempPolygon:GetName())
    
        if string.find(tempPolygon:GetName(), "blobHitbox") then
          updateCurrentPolygon(tempPolygon)
    
          print("in hitbox!")
  
        else
  
          AWM.isInsideBlobHitbox = false
          AWM.currentlySelectedPolygon = nil
          AWM.blobZoneInfo = {}
  
        end
      end
    end

    if (AWM.currentlySelectedPolygon ~= nil) then
  
      -- check to make sure that the user has actually left the hitbox, and is not just hovering over a wayshrine
      if (not (AWM.currentlySelectedPolygon:IsPointInside(getMouseCoordinates()) and currentMapIndex == getCurrentMapID())) then
  
        -- Left hitbox!
        AWM.isInsideBlobHitbox = false
        AWM.currentlySelectedPolygon = nil
        AWM.blobZoneInfo = {}
        
        ZO_WorldMapMouseOverDescription:SetText("")
        AWM_MouseOverGrungeTex:SetHidden(true)
  
      end
    end
  else

    -- hide mouseover info
    ZO_WorldMapMouseOverDescription:SetText("")
    AWM_MouseOverGrungeTex:SetHidden(true)

  end
end

-------------------------------------------------------------------------------
--  On player loaded function
-------------------------------------------------------------------------------

local function onPlayerLoaded()

  updateLocationsInfo()

  if (not AWM.areTexturesCompiled) then
  
    print("Loading, please wait ...", true)

    -- call compileMapTextures twice to make sure it's loaded
    zo_callLater(function()
      compileMapTextures()
      zo_callLater(function() compileMapTextures()
       end, 1000 )
    end, 2000 )

  end
end

-------------------------------------------------------------------------------
--  Addon initialisation
-------------------------------------------------------------------------------

local function initialise(event, addonName)

  -- skip all addons that aren't ours
  if (addonName ~= AWM.name) then return end
  
  -- unregister as addon is now loaded
  EVENT_MANAGER:UnregisterForEvent(AWM.name, EVENT_ADD_ON_LOADED)
  
  -- compile map textures
  compileMapTextures()

  -- update locations info on the sidebar
  updateLocationsInfo()

  -- set up saved variables
  AWM.options = ZO_SavedVars:NewAccountWide("AWMVars", AWM.variableVersion, nil, AWM.defaults)

  -- set up slash commands
  SLASH_COMMANDS["/get_map_id"] = function() print(GetCurrentMapId(), true) end
  SLASH_COMMANDS["/record_polygon"] = recordPolygon
  SLASH_COMMANDS["/get_blobs"] = compileMapTextures
  SLASH_COMMANDS["/set_map_to"] = navigateToMap
  SLASH_COMMANDS["/awm_debug"] = function() AWM.options.isDebug = not AWM.options.isDebug navigateToMap(getCurrentMapID()) end
  SLASH_COMMANDS["/fix_locations"] = fixLocations
  SLASH_COMMANDS["/set_is_developer"] = function() AWM.options.isDeveloper = not AWM.options.isDeveloper end
  SLASH_COMMANDS["/getboundingbox"] = getBoundingBox
  SLASH_COMMANDS["/localtoglobal"] = localToGlobal
  SLASH_COMMANDS["/globaltolocal"] = globalToLocal
  SLASH_COMMANDS["/getparentmapid"] = getParentMapID

  -- register LAM settings
  local panelName = "AWM_Settings"
  local panel = LAM:RegisterAddonPanel(panelName, AWM.panelData)
  LAM:RegisterOptionControls(panelName, AWM.optionsData)
  
end

-------------------------------------------------------------------------------
-- Registering for events and callbacks
-------------------------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent(AWM.name, EVENT_ADD_ON_LOADED, initialise)
EVENT_MANAGER:RegisterForEvent("onMouseDown", EVENT_GLOBAL_MOUSE_DOWN, onMouseClicked)
EVENT_MANAGER:RegisterForEvent(AWM.name, EVENT_PLAYER_ACTIVATED, onPlayerLoaded)
EVENT_MANAGER:RegisterForUpdate("mainLoop", 0, main)
CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", onMapChanged)
CALLBACK_MANAGER:RegisterCallback("OnWorldMapShown", onWorldMapOpened)
LMP:RegisterCallback("AfterPingAdded", onPingAdded)
