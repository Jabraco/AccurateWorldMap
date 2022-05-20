--[[===========================================================================
                AccurateWorldMap, by BroughBreaux & Thal-J
===============================================================================

-- ascii title art done on https://texteditor.com/ascii-art/
-- https://textfancy.com/multiline-text-art/


Todo:

Things that need to be done before release:

TJ:

- Fix player location being incorrect (and also group pins)
- Implement proper waypoint and player marker tracking and moving

- Find a way to move the zone name and clock to be closer to the actual map in K&M mode like gamepad
- Sort out breaux's custom K&M and gamepad desc grunge design


Breaux:

- add aurbis ring lines to tamriel and systres icons

- Make description background textures for both gamepad and K&M
- Fix the Aurbis tamriel blob - mismatches with what is there currently
>> Aurbis Tamriel is missing its waves as well
- Fix Aurbis rings not containing their proper daedric/elven text

- Fix Eltheric Ocean ring not being the correct colour, and looking werid
>> Eltheric Ocean map ring should be blackreach ring coloured, with a ship icon
>> Ring back to Tamriel should be an aurbis-themed smaller version of tamriel inside the ring, with waves
(like https://cdn.discordapp.com/attachments/806672739057664034/974778491373518868/unknown.png)
>> also note that the aurbis circle rings seem to be semitransparent - the western skyrim one has a slight blue tint as its in the sea

- Give TJ blobs for the following:
>> Dranil-Kir
>> Silitar
>> Fort Grief
>> Arcane University
>> The Earth Forge (Reach)
>> Sword's Rest Isle
>> Arcane University
>> Imperial City Prison
>> Dread Sail Reef Blob
>> High Isle & Amenos Blob

- add caecilly isle to eltheric and HR map:
https://cdn.discordapp.com/attachments/654414794144743425/977115570497531924/unknown.png


Breaux said she would look into:

- sorting out W.Skyrim's outline situation (as per carto club)
- fixing castle volikhar


Optional:

- Add IC Sewers circle to IC map and get blob
- Rotate IC on the cyrodiil map 45 degrees to be consistent with oblivion (edit the tiles)
https://cdn.discordapp.com/attachments/806672739057664034/975049286305861672/unknown.png
- Remove Dragonhold from S.E map by editing the tiles again (Add as option to remove dragonhold from zone map)


Move player marker brainstorming:

then i'd need to override GetUniversallyNormalizedMapInfo and then use libgps to fix the position?
override getmapplayerposition and override with the output from libgps, where it thinks the player should be

what i am understanding is that libgps uses GetUniversallyNormalizedMapInfo and some magic to convert local coordinates to global, in vanilla these coordinates are the same and match up
if i override GetUniversallyNormalizedMapInfo then that would affect libgps' local to global and thus shift where it would think the global position is
then i could use output of that to override GetMapPlayerPosition() for pins

  that's what i'm saying.. in vanilla, a local to global call will result in where the player marker actually is on the tamriel map
if a user is in 0.5, 0.5 in eastmarch, then local to global will give that location in the tamriel world map
the issue is, it gives the location according to the (vanilla) world map
which would be wrong in my addon, my eastmarch is shifted about 4cm to the left of where it is in vanilla

exactly, so when i override GetUniversallyNormalizedMapInfo with my addon's zone info, libgps will return the correct position on the world map for my addon
it would effectively give me the moved player marker's position
and i could then use that output of local-to-global to pipe into overriding GetMapPlayerPosition to force it to move to where it should be, visually

use GetUniversallyNormalizedMapInfo()

local originalCreatePin = ZO_WorldMapPins.CreatePin
ZO_WorldMapPins.CreatePin = function(self, pinType, pinTag, xLoc, yLoc, radius, borderInformation, ...)
    xLoc, yLoc = ApplyMyTransformation(xLoc, yLoc)
    return originalCreatePin(self, pinType, pinTag, xLoc, yLoc, radius, borderInformation, ...)
end

https://github.com/esoui/esoui/blob/master/esoui/ingame/map/mappin.lua#L2870

function ZO_MapPin:SetLocation(xLoc, yLoc, radius, borderInformation)

that function is called whenever pins are created or updated
so likely the best place for the transform. you can access the pinType via self:GetPinType() too, in order to filter any pins you do not want to adjust


that might work. are group players and companions counted as MAP_PIN_TYPE_PLAYER ?
sirinsidiator (sirinsidiator)
no, I believe they are separate types like MAP_PIN_TYPE_GROUPand MAP_PIN_TYPE_ACTIVE_COMPANION
but the type should not really matter for you, since you want to transform any pin?

you could check for MAP_PIN_TYPE_FAST_TRAVEL_WAYSHRINE and don't apply transformations in that case?

- can make a function to find the furthest left-upmost point from zone hitbox polygon, and same for right bottommost one
- that counts as the zone's player marker square area
- then get the player's position in the local map

  - check if current map id is in the database
  - if it is, then it is a visible zone


useful functions for this:

IsPlayerMoving() and IsPlayerTryingToMove()

if these are true, and the map is visible, then updae position

all player and companions use the GetMapPlayerPosition function, so if you override that you will affect them all

* GetMapPlayerPosition(*string* _unitTag_)
** _Returns:_ *number* _normalizedX_, *number* _normalizedZ_, *number* _heading_, *bool* _isShownInCurrentMap_

"heading" must be the rotation in degrees

keep isShownInCurrentMap unless some override is checked


Interesting events to consider:

GetDisplayName() returns user id 

use that to make an isDeveloper() function


* GetPlayerActiveZoneName()

** _Returns:_ *string* _zoneName_


* EVENT_GROUP_TYPE_CHANGED (*bool* _largeGroup_)
* EVENT_GROUP_UPDATE
* EVENT_GROUP_MEMBER_JOINED (*string* _memberCharacterName_, *string* _memberDisplayName_, *bool* _isLocalPlayer_)
* EVENT_GROUP_MEMBER_LEFT (*string* _memberCharacterName_, *[GroupLeaveReason|#GroupLeaveReason]* _reason_, *bool* _isLocalPlayer_, *bool* _isLeader_, *string* _memberDisplayName_, *bool* _actionRequiredVote_)
* EVENT_GROUP_MEMBER_ROLE_CHANGED (*string* _unitTag_, *[LFGRole|#LFGRole]* _newRole_)
* EVENT_GROUP_MEMBER_SUBZONE_CHANGED


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
  isDeveloper = false,
}

-------------------------------------------------------------------------------
-- Dependency initialisation
-------------------------------------------------------------------------------

local LAM = LibAddonMenu2
local GPS = LibGPS3
local LMP = LibMapPing2

-------------------------------------------------------------------------------
-- Globals
-------------------------------------------------------------------------------

-- objects
AWM.blobZoneInfo = {}
AWM.currentlySelectedPolygon = nil
polygonData = {}



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
-- On waypoint / map ping added function
-------------------------------------------------------------------------------

local function onPingAdded(pingType, pingTag, xN, yN, isPingOwner)


    d("\n")
    -- d("new waypoint added:")
    -- d(xN, yN)


    d(GPS:LocalToGlobal(xN, yN))

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
  AWM.blobZoneInfo = getZoneInfoByID(getMapIDFromPolygonName(polygon:GetName()))
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
    AWM_MouseOverGrungeTex:SetAlpha(0.65)
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

  -- register LAM settings
  local panelName = "AWMSettings"
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
