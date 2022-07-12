--[[===========================================================================
                     AccurateWorldMap, by Vylaera & Thal-J
===============================================================================

-- ascii title art done on https://texteditor.com/ascii-art/
-- https://textfancy.com/multiline-text-art/

-----------

TJ TODO:

- Ask Breaux for updated zone descs

Need to fix desc text being too big issue (we confirmed that it overflows on 1080p displays)

options:
- reduce text size (probably unreadable?)
- mess around with adding a rezisable description box somewhere
- maybe on the side of the map window? (for pc)
- reduce lore text

- fix gamepad being dependent on mouse
- make it so libzone dependency for parent is unneeded
- if in a dungeon or a house, put player/waypoint marker where that icon is on the map
- add topal hideaway blob
- add option and subsection in settings to control dungeons/trials, houses and wayshrines separately
- If player is in a house or a dungeon, and is looking at the tamriel map, put the player/waypoint icon where that icon is
- make Lore-Accurate Names English only
- Refactor the way names and decs/strings work in the mod to allow for translation
>> also work on adding translation
- Add "loading" text to map while blobs are still being compiled
- Find a way to move the zone name and clock to be closer to the actual map in K&M mode like gamepad
https://i.ibb.co/9pvcTjG/blackreach.png

I have a suggestion about new wayshrine display option on the world map, an "utilitarian" preset. 
If it selected only those wayshrines that have guild traders nearby, or those located in zone capitals will be visible on the world map along with all dungeon, trial and arena pins.
In case similar to the Rift zone when there are two wayshrines nearby one of which is in the capital city itself and second is the closest to the guild traders both should be visible on the map.
Also if it's possible to show only owned player houses they should also be visible, if it's NOT possible then none should be visible.

- Vvardenfell blob includes a small island that is actually for stonefalls
https://cdn.discordapp.com/attachments/806672739057664034/996095775849320558/unknown.png

Gamepad zoom seems to be all kinds of broken on mine, the bumpers do nothing and sometimes when you zoom out with the triggers you can't zoom back in. 

When using a controller, you can zoom out on the map, but you cannot zoom back in. 

When you click on a wayshrine, the description text stays on the screen but the desc black box vanishes. Ideally either both or neither should
disappear.

Minimaps seem to mess with the loading of the black box; the proportions are often off if I have the minimap enabled and active when I load up a character. Either too small or too big. I'm unsure if this is true for every UI mod, I personally use Bandit's UI, so that's the one I confirm causing issues.

- Transition over to using vanilla eso blobs instead of custom ones

  The Aurbis view version of Tamriel looks kind of artifact-y/noisy, is this a known issue or something that's only happening at my end? 

  Just wow! Installed this yesterday, and it is amazing. Everytime I open the map I am stunned by it. On gamepad UI I get an addon error, 
  so I need to use wayshrines using keyboard and mouse, but this may be a bug from another addon.

As far as I know you only need a folder "lang" with files like de.lua, en.lua, fr.lua etc, containing simple declarations like
Code:

ZO_CreateStringId("AWM_SOME_NAME", "Localiced Name")

and then use eg. AWM_CRAGLORN in your main.lua instead of "Craglorn". Other users like me could translate your en.lua to their native language.

--------

Vylaera TODO:

Misc issues:
- Aurbis rings don't contain their proper daedric/elven text
- Go over all zone descs
- Khenarthi's roost is too big on the map to lore scale - it's smaller in quin'rawl's map, also further away
>> perhaps scale it down and move it

POST RELEASE:
- Shrink Tamriel
- Move it over
- Delete Etheric Map
- Move High Isle and Systres over into Tamriel Map
- Update Aurbis Tamriel Blob
- Increase Tamriel Map Zoom Level
- Re-do all blobs and anchor blobs and zone hitboxes
- Allow for 4k Tamriel Tiles option

- Add IC Sewers circle to the imperial city map and make blob
- Rotate IC on the cyrodiil map 45 degrees to be consistent with oblivion (edit the tiles)
https://cdn.discordapp.com/attachments/806672739057664034/975049286305861672/unknown.png

---------------------------------------------------------------------------]]--
-- Create root addon object
-------------------------------------------------------------------------------

-- set saved variable version number
AWM.variableVersion = 5

-- set default options
AWM.defaults = {
  isDebug = false,
  zoneDescriptions = false,
  loreRenames = true,
  mapStyle = "Vanilla",
  worldMapWayshrines = "All (Default)",
  hideIconGlow = false,
  iconRepositioning = true,
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

-- bools
AWM.canRedrawMap = true
AWM.areTexturesCompiled = false
AWM.isInsideBlobHitbox = false
AWM.isLoaded = false
local recordCoordinates = false
local hasDragged = false
local waitForRelease = false
local waitToHideKeybind

-- ints
AWM.lastWaypointMapID = nil
AWM.lastGlobalXN = nil
AWM.lastGlobalYN = nil
AWM.lastLocalXN = nil
AWM.lastLocalYN = nil
local coordinateCount = 0

-------------------------------------------------------------------------------
-- Create map info background texture control
-------------------------------------------------------------------------------

AWM_MouseOverGrungeTex = CreateControl("AWM_MouseOverGrungeTex", ZO_WorldMap, CT_TEXTURE)

local function getControlAtPoint()

  local tempControl = WINDOW_MANAGER:GetControlAtPoint(getMouseCoordinates())
  print(tempControl:GetName(), true)

end

-------------------------------------------------------------------------------
--  On map change callback function
-------------------------------------------------------------------------------

local function onMapChanged()

  -- hide all existing zone blobs
  hideAllZoneBlobs()

  -- force previous blob info to hide
  zo_callLater(function()

    AWM.currentlySelectedPolygon = nil
    AWM.blobZoneInfo = {}
    AWM.isInsideBlobHitbox = false
    AWM_MouseOverGrungeTex:SetHidden(true)

  end, 1 )
  
  -- parse current map for any custom data
  parseMapData(getCurrentMapID())

end

-------------------------------------------------------------------------------
-- On waypoint set functions
-------------------------------------------------------------------------------

local lastXN, lastYN

function onWaypointSet(xN, yN)

  local mouseXN, mouseYN = getNormalisedMouseCoordinates()

  if (isWaypointPlaced() and canRemoveWaypoint(mouseXN, mouseYN, lastXN, lastYN, getCurrentMapID())) then
    LMP:RemoveMapPing(MAP_PIN_TYPE_PLAYER_WAYPOINT)
    AWM.lastLocalXN = nil
    AWM.lastLocalYN = nil
    AWM.lastGlobalXN = nil
    AWM.lastGlobalYN = nil
    AWM.lastWaypointMapID = nil
  else
    LMP:SetMapPing(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, xN, yN)
    PingMap(MAP_PIN_TYPE_PLAYER_WAYPOINT, MAP_TYPE_LOCATION_CENTERED, xN, yN)
    lastXN = xN
    lastYN = yN
  end

  -- update waypoint keybind state
  ZO_WorldMap_MouseEnter()
end

function onPostWaypointSet(pingType, pingTag, xN, yN, isPingOwner)
  if (pingType == MAP_PIN_TYPE_PLAYER_WAYPOINT and pingTag == "waypoint" and isPingOwner and isWaypointPlaced()) then

    -- check to see if we're setting waypoint a local map
    if (not isMapTamriel()) then
      print("waypoint set in a local map!")
      AWM.lastLocalXN = xN
      AWM.lastLocalYN = yN
      AWM.lastGlobalXN = nil
      AWM.lastGlobalYN = nil
    end

    -- check to see if we're setting waypoint in tamriel
    if (isMapTamriel()) then
      print("waypoint set in tamriel map!")
      AWM.lastGlobalXN = xN
      AWM.lastGlobalYN = yN
      
    end

    AWM.lastWaypointMapID = getCurrentMapID()
  end
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
-- Record new zone hitbox polygon function
-------------------------------------------------------------------------------

local function recordPolygonBlob()

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
    AWM_MouseOverGrungeTex:SetHidden(false)
  end

  -- update with current zone info
  if (string.match(polygon:GetName(), "duplicate")) then
    AWM.blobZoneInfo = getZoneInfoByID(getMapIDFromPolygonName(polygon:GetName()), true)
  else
    AWM.blobZoneInfo = getZoneInfoByID(getMapIDFromPolygonName(polygon:GetName()))
  end

  ZO_WorldMap_MouseEnter()
  
end

-------------------------------------------------------------------------------
-- On world map opened
-------------------------------------------------------------------------------

local function onWorldMapOpened()
  
  if (AWM.canRedrawMap) then

    AWM.canRedrawMap = false

    local mapWidth, mapHeight = ZO_WorldMapContainer:GetDimensions()
    local enlargeConst = 1.5
    local mapDescPaddingAmount = mapWidth * 0.11
  
    -- set up map description label control
    ZO_WorldMapMouseOverDescription:SetFont("ZoFontGameLargeBold")
    ZO_WorldMapMouseOverDescription:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
    ZO_WorldMapMouseOverDescription:ClearAnchors()
    ZO_WorldMapMouseOverDescription:SetAnchor(TOPLEFT, ZO_WorldMapMouseoverName, BOTTOMLEFT, mapDescPaddingAmount, 2)
    ZO_WorldMapMouseOverDescription:SetAnchor(TOPRIGHT, ZO_WorldMapMouseoverName, BOTTOMRIGHT, -(mapDescPaddingAmount), 4)

    -- set up map description background
    AWM_MouseOverGrungeTex:ClearAnchors()
    AWM_MouseOverGrungeTex:SetAnchor(TOPLEFT, ZO_WorldMap, TOPLEFT, 0, 0)
    AWM_MouseOverGrungeTex:SetDimensions(mapWidth, mapHeight)
  
    -- set up label description background 
    if (isInGamepadMode()) then
      AWM_MouseOverGrungeTex:SetTexture("AccurateWorldMap/misc/gamepadshadow.dds")
      AWM_MouseOverGrungeTex:SetAlpha(0.65)
    else

      if (dui) then -- check if DarkUI is installed
        AWM_MouseOverGrungeTex:SetTexture("AccurateWorldMap/misc/pc_shadow_darkui.dds")
      else -- if not, return vanilla styled desc background
        AWM_MouseOverGrungeTex:SetTexture("AccurateWorldMap/misc/pc_shadow.dds")
      end
      
      AWM_MouseOverGrungeTex:SetAlpha(0.45)
    end

    AWM_MouseOverGrungeTex:SetDrawTier(DT_PARENT)
    AWM_MouseOverGrungeTex:SetDrawLayer(DL_OVERLAY)
    AWM_MouseOverGrungeTex:SetDrawLayer(DL_CONTROLS)
    AWM_MouseOverGrungeTex:SetHidden(true)

    -- hide serenated edge if not in gamepad
    ZO_WorldMapContainerRaggedEdge:SetHidden(not isInGamepadMode())

  end
end

-------------------------------------------------------------------------------
-- Main addon event loop
-------------------------------------------------------------------------------

local function main()
  if (isWorldMapActive()) then

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

    else

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
  AWM.isLoaded = true
  
  -- compile map textures
  compileMapTextures()

  -- update locations info on the sidebar
  updateLocationsInfo()

  -- set up saved variables
  AWM.options = ZO_SavedVars:NewAccountWide("AWMVars", AWM.variableVersion, nil, AWM.defaults)

  -- set up slash commands
  SLASH_COMMANDS["/get_map_id"] = function() print(GetCurrentMapId(), true) end
  SLASH_COMMANDS["/record_blob"] = recordPolygonBlob
  SLASH_COMMANDS["/get_blobs"] = compileMapTextures
  SLASH_COMMANDS["/set_map_to"] = navigateToMap
  SLASH_COMMANDS["/awm_debug"] = function() AWM.options.isDebug = not AWM.options.isDebug navigateToMap(getCurrentMapID()) end
  SLASH_COMMANDS["/getparentmapid"] = getParentMapID
  SLASH_COMMANDS["/getcontrolatpoint"] = getControlAtPoint

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
LMP:RegisterCallback("AfterPingAdded", onPostWaypointSet)
