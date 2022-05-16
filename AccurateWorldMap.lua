--[[===========================================================================
                AccurateWorldMap, by BroughBreaux & Thal-J
===============================================================================

-- ascii title art done on https://texteditor.com/ascii-art/
-- https://textfancy.com/multiline-text-art/


Todo:

Things that need to be done before release:

TJ:
- refactor AccurateWorldMap to AWM
- and AccurateWorldMap.options to AWM.settings
- fix zone description text being cut off
- fix zone description text being truncating on map open
- implement gamepad desc background
- Fix player location being incorrect (and also group pins)
- Sort out K&M and gamepad desc grunge
- Do a once over of all zone descriptions with breaux so that she's happy with them
- add Systres blobs and stuff to the map
- Add Eltheric ocean map properly with High isle wayshrines
- Implement proper waypoint and player marker tracking and moving
- Make Tideholm its own zone, separate from s.e
- Do the same to Wasten Coraldale in summerset
- Add a "Recording" dot that appears when recording blob
- Add a close button to the polygon record control, and allow to reset without reload ui
- find a way to override g_playerChoseCurrentMap for High Isle

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
AccurateWorldMap.variableVersion = 2

-- set default options
AccurateWorldMap.defaults = {
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

-------------------------------------------------------------------------------
-- Globals
-------------------------------------------------------------------------------

-- bools
local recordCoordinates = false
local mouseDownOnPolygon = false
local enabled = true
local debug = false
local isExclusive = false
local hasDragged = false
local isInBlobHitbox = false
local waitForRelease = false
local areTexturesCompiled = false

-- ints
local currentCoordinateCount = 0
local currentMapOffsetX
local currentMapOffsetY
local currentMapIndex

-- objects
local currentPolygon = nil
local polygonData = {}
local newPolygonData = {}
local currentZoneInfo = {}




-- todo: fix this for gamepad mode as well
AWM_MouseOverGrungeTex = CreateControl("AWM_MouseOverGrungeTex", ZO_WorldMap, CT_TEXTURE)
AWM_MouseOverGrungeTex:SetTexture("/esoui/art/performance/statusmetermunge.dds")


-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local mapDimensions = 4096 -- px

local function onMousePressed()

  if isMouseWithinMapWindow() then

    if (recordCoordinates) then 
      PlaySound(SOUNDS.COUNTDOWN_TICK)

      local xN, yN = getNormalisedMouseCoordinates()

      table.insert(newPolygonData, {xN, yN})
      currentCoordinateCount = currentCoordinateCount + 1

    end


  end

end

local function updateCurrentPolygon(polygon) 

  currentMapIndex = GetCurrentMapIndex()
  isInBlobHitbox = true
  --print("User has entered zone hitbox")
  currentPolygon = polygon

  if (AccurateWorldMap.options.zoneDescriptions == true) then

    if (not isInGamepadMode()) then
      AWM_MouseOverGrungeTex:SetHidden(false)
    end


  end

  -- update with current zone info
  currentZoneInfo = getZoneInfoByID(getMapIDFromPolygonName(polygon:GetName()))

end

local function onWorldMapDrawn()

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
  ZO_WorldMapMouseOverDescription:SetMaxLineCount(2.5)
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

-------------------------------------------------------------------------------
-- Main addon event loop
-------------------------------------------------------------------------------

local function main()
  if (isWorldMapShown()) then


    if (isInGamepadMode()) then

      if (currentPolygon == nil) then
  
        tempPolygon = WINDOW_MANAGER:GetControlAtPoint(getMouseCoordinates())
  
  
        print(tempPolygon:GetName())
    
        if string.find(tempPolygon:GetName(), "blobHitbox") then
          updateCurrentPolygon(tempPolygon)
    
          print("in hitbox!")
  
        else
  
          isInBlobHitbox = false
          currentPolygon = nil
          currentZoneInfo = {}
  
        end
  
  
      end
  
    end
  
  
    if (currentPolygon ~= nil) then
  
      -- check to make sure that the user has actually left the hitbox, and is not just hovering over a wayshrine
      if (not (currentPolygon:IsPointInside(getMouseCoordinates()) and currentMapIndex == GetCurrentMapIndex())) then
  
        --print("left hitbox!")
        isInBlobHitbox = false
        currentPolygon = nil
        currentZoneInfo = {}
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

            navigateToMap(currentZoneInfo)

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

local function compileBlobTextures()

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

          if (zoneInfo.blobTexture == nil or zoneInfo.nBlobTextureHeight == nil or zoneInfo.nBlobTextureWidth == nil ) then

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
              mapData[mapID].zoneData[zoneIndex].nBlobTextureHeight = textureHeight / mapDimensions
              mapData[mapID].zoneData[zoneIndex].nBlobTextureWidth = textureWidth / mapDimensions

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
  if (hasError == false and areTexturesCompiled == false) then

    print("Successfully loaded.", true)
    areTexturesCompiled = true

  end

end

-------------------------------------------------------------------------------
--  On player ready / loaded function
-------------------------------------------------------------------------------

local function onPlayerLoaded()

  if (areTexturesCompiled == false) then
  
    print("Loading, please wait ...", true)

    -- call compileBlobTextures twice to make sure it's loaded
    zo_callLater(function()
      compileBlobTextures()
      zo_callLater(function() compileBlobTextures()
       end, 1000 )
    end, 2000 )

  end
end

-------------------------------------------------------------------------------
--  On zone/map change callback function
-------------------------------------------------------------------------------

local function onZoneChanged()

  -- Hide all existing zone blobs
  hideAllZoneBlobs()

  AWM_MouseOverGrungeTex:SetHidden(true)

  local mapIndex = getCurrentMapID()

  if (mapIndex ~= nil) then


    print("Current map id: ".. mapIndex)


    -- Check if the current zone/map has any custom map data set to it
    if (mapData[mapIndex] ~= nil) then
      
      --print("This map has custom data!")


      if (mapData[mapIndex].isExclusive ~= nil) then
        isExclusive = mapData[mapIndex].isExclusive
      else
        isExclusive = false
      end


      if (mapData[mapIndex].zoneData ~= nil) then
        --print("This map has custom zone data!")
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
--  Addon initialisation
-------------------------------------------------------------------------------

local function initialise(event, addonName)

  -- skip all addons that aren't ours
  if (addonName ~= AccurateWorldMap.name) then return end
  
  -- unregister as addon is now loaded
  EVENT_MANAGER:UnregisterForEvent(AccurateWorldMap.name, EVENT_ADD_ON_LOADED)
  
  -- Compile blob texture details
  compileBlobTextures()

  -- set up saved variables
  AccurateWorldMap.options = ZO_SavedVars:NewAccountWide("AWMVars", AccurateWorldMap.variableVersion, nil, AccurateWorldMap.defaults)

  -- set up slash commands
  SLASH_COMMANDS["/get_map_id"] = function() print(GetCurrentMapId(), true) end
  SLASH_COMMANDS["/record_polygon"] = recordPolygon
  SLASH_COMMANDS["/get_blobs"] = getBlobTextureDetails
  SLASH_COMMANDS["/set_map_to"] = navigateToMap
  SLASH_COMMANDS["/awm_debug"] = function() AccurateWorldMap.options.isDebug = not AccurateWorldMap.options.isDebug navigateToMap(getCurrentMapID()) end

  -- register LAM settings
  local panelName = "AccurateWorldMapSettings"
  local panel = LAM:RegisterAddonPanel(panelName, AccurateWorldMap.panelData)
  LAM:RegisterOptionControls(panelName, AccurateWorldMap.optionsData)
  
end

-------------------------------------------------------------------------------
-- Registering for events and callbacks
-------------------------------------------------------------------------------

EVENT_MANAGER:RegisterForEvent(AccurateWorldMap.name, EVENT_ADD_ON_LOADED, initialise)
EVENT_MANAGER:RegisterForEvent("onMouseDown", EVENT_GLOBAL_MOUSE_DOWN, onMousePressed)
EVENT_MANAGER:RegisterForEvent(AccurateWorldMap.name, EVENT_PLAYER_ACTIVATED, onPlayerLoaded)
EVENT_MANAGER:RegisterForUpdate("mainLoop", 0, main)

CALLBACK_MANAGER:RegisterCallback("OnWorldMapChanged", onZoneChanged)
CALLBACK_MANAGER:RegisterCallback("OnWorldMapShown", onWorldMapDrawn)


-------------------------------------------------------------------------------
-- Process map click function
-------------------------------------------------------------------------------

-- These functions control when the user's click is passed through to the map 
-- for events such as zone changing. We override that that so that our custom 
-- zone hitbox polygons get the priority, as long as isExclusive is true.

-------------------------------------------------------------------------------

ZO_PreHook("ProcessMapClick", function(xN, yN)

  -- in K&M mode, this function gets fired on every double click for some reason
  -- whereas in gamepad this gets fired every click

  print("processed map click function!")

  if ((isInBlobHitbox and currentZoneInfo ~= nil) or isExclusive) then


    if (isInGamepadMode() and (isInBlobHitbox and currentZoneInfo ~= nil)) then

      navigateToMap(currentZoneInfo)

    end


    return true
  end

end)

-------------------------------------------------------------------------------
-- Map mouseover info function
-------------------------------------------------------------------------------

-- Controls the "blobs", the highlight effect that appears  when hovering over
-- the zones on the map.

-------------------------------------------------------------------------------

local zos_GetMapMouseoverInfo = GetMapMouseoverInfo
GetMapMouseoverInfo = function(xN, yN)

  local mapIndex = getCurrentMapID()

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

        if (AccurateWorldMap.options.loreRenames) then
          locationName = currentZoneInfo.zoneName
        else
          locationName = getZoneNameFromID(currentZoneInfo.zoneID)
        end

        textureFile = currentZoneInfo.blobTexture
        widthN = currentZoneInfo.nBlobTextureWidth
        heightN = currentZoneInfo.nBlobTextureHeight
        locXN = currentZoneInfo.xN
        locYN = currentZoneInfo.yN

        if (currentZoneInfo.zoneDescription ~= nil and AccurateWorldMap.options.zoneDescriptions == true) then
          ZO_WorldMapMouseOverDescription:SetText(currentZoneInfo.zoneDescription)
        end

    end

  end

  return locationName, textureFile, widthN, heightN, locXN, locYN
end


