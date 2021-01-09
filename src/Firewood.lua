--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 09/01/2021

InitRoyalMod(Utils.getFilename("lib/rmod/", g_currentModDirectory))
InitRoyalUtility(Utils.getFilename("lib/utility/", g_currentModDirectory))

---@class Firewood
Firewood = RoyalMod.new(r_debug_r, false)
Firewood.scanTimer = 0
Firewood.scanTimeout = 250
Firewood.foundSplitShape = nil


function Firewood:initialize()
    Utility.overwrittenFunction(Player, "new", PlayerExtension.new)
    Utility.appendedFunction(Player, "updateActionEvents", PlayerExtension.updateActionEvents)
    if Player.makeFirewoodActionEvent == nil then
        Player.makeFirewoodActionEvent = PlayerExtension.makeFirewoodActionEvent
    end
end

function Firewood:onValidateVehicleTypes(vehicleTypeManager, addSpecialization, addSpecializationBySpecialization, addSpecializationByVehicleType, addSpecializationByFunction)
    -- @param specName string name of the spec to add
    --addSpecialization("specName")

    -- @param specName string name of the spec to add
    -- @param requiredSpecName string name of the required spec
    --addSpecializationBySpecialization("specName", "requiredSpecName")

    -- @param specName string name of the spec to add
    -- @param requiredVehicleTypeName string name of the required vehicle type
    --addSpecializationByVehicleType("specName", "requiredVehicleTypeName")

    -- @param specName string name of the spec to add
    -- @param function function if return true spec will be added to the current vehicle type
    --addSpecializationByFunction("specName", function(vehicleType) return false end)
end

function Firewood:onMissionInitialize(baseDirectory, missionCollaborators)
end

function Firewood:onSetMissionInfo(missionInfo, missionDynamicInfo)
end

function Firewood:onLoad()
end

function Firewood:onPreLoadMap(mapFile)
end

function Firewood:onCreateStartPoint(startPointNode)
end

function Firewood:onLoadMap(mapNode, mapFile)
end

function Firewood:onPostLoadMap(mapNode, mapFile)
    -- Load Firewood types before the height map system gets initialized
    self:loadFirewoodType()

    -- The HUD cached a list of filltypes. We added a new one so need to refresh that list to prevent errors
    g_currentMission.hud.fillLevelsDisplay:refreshFillTypes(g_fillTypeManager)
end

function Firewood:onLoadSavegame(savegameDirectory, savegameIndex)
end

function Firewood:onPreLoadVehicles(xmlFile, resetVehicles)
end

function Firewood:onPreLoadItems(xmlFile)
end

function Firewood:onPreLoadOnCreateLoadedObjects(xmlFile)
end

function Firewood:onLoadFinished()
end

function Firewood:onStartMission()
end

function Firewood:onMissionStarted()
end

function Firewood:onWriteStream(streamId)
end

function Firewood:onReadStream(streamId)
end

function Firewood:onUpdate(dt)
    if g_dedicatedServerInfo == nil and g_currentMission.player.isEntered then
        self.scanTimer = self.scanTimer + dt
        if self.scanTimer >= self.scanTimeout then
            self.scanTimer = 0
            self.foundSplitShape = nil
            local x, y, z = localToWorld(g_currentMission.player.cameraNode, 0, 0, 1.0)
            local dx, dy, dz = localDirectionToWorld(g_currentMission.player.cameraNode, 0, 0, -1)
            raycastAll(x, y, z, dx, dy, dz, "raycastCallback", 5, self)
        end
    end
end

function Firewood:onUpdateTick(dt)
end

function Firewood:onWriteUpdateStream(streamId, connection, dirtyMask)
end

function Firewood:onReadUpdateStream(streamId, timestamp, connection)
end

function Firewood:onMouseEvent(posX, posY, isDown, isUp, button)
end

function Firewood:onKeyEvent(unicode, sym, modifier, isDown)
end

function Firewood:onDraw()
end

function Firewood:onPreSaveSavegame(savegameDirectory, savegameIndex)
end

function Firewood:onPostSaveSavegame(savegameDirectory, savegameIndex)
end

function Firewood:onPreDeleteMap()
end

function Firewood:onDeleteMap()
    self:unloadFirewoodType()
end

function Firewood:raycastCallback(hitObjectId, _, _, _, _, _, _, _, _, _)
    if hitObjectId ~= g_currentMission.player.rootNode then
        self.foundSplitShape = hitObjectId
        return false
    end
    return true -- continue raycast
end


---Add a Firewood
function Firewood:loadFirewoodType()
    local hudOverlayFilename = "hud/fillTypes/hud_fill_firewood.png"
    local hudOverlayFilenameSmall = "hud/fillTypes/hud_fill_firewood_sml.png"
    local pricePerLiter = 10
    local massPerLiter = 0.750 / 1000

    local fillType = g_fillTypeManager:addFillType("FIREWOOD", g_i18n:getText("fillType_firewood"), true, pricePerLiter, massPerLiter, 32, hudOverlayFilename, hudOverlayFilenameSmall, self.directory, nil, { 1, 1, 1 }, nil, false)

    -- g_fillTypeManager:addFillTypeToCategory(fillType.index, g_fillTypeManager.nameToCategoryIndex["BULK"])

    --local diffuseMapFilename = Utils.getFilename("resources/fillTypes/salt/salt_diffuse.png", self.modDirectory)
    --local normalMapFilename = Utils.getFilename("resources/fillTypes/salt/salt_normal.png", self.modDirectory)
    --local distanceMapFilename = Utils.getFilename("resources/fillTypes/salt/saltDistance_diffuse.png", self.modDirectory)

    --self.saltHeightType = self.densityMapHeightManager:addDensityMapHeightType("SALT", math.rad(32), 0.8, 0.10, 0.10, 0.9, 1, false, diffuseMapFilename, normalMapFilename, distanceMapFilename, false)
    --if self.saltHeightType == nil then
    --    Logging.error("Could not create the salt height type. The combination of map and mods are not compatible")
    --    return
    --end

    --local saltMaterialHolderFilename = Utils.getFilename("resources/fillTypes/salt/saltMaterialHolder.i3d", self.modDirectory)
    --self.saltMaterialHolder = loadI3DFile(saltMaterialHolderFilename, false, true, false)
end

function Firewood:unloadFirewoodType()
    --if self.saltMaterialHolder ~= nil then
    --    delete(self.saltMaterialHolder)
    --    self.saltMaterialHolder = nil
    --end
end

