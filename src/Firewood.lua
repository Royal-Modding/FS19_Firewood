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

    Utility.overwrittenFunction(SellingStation, "load", Firewood.sellingStationLoad)
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
end

function Firewood:raycastCallback(hitObjectId, _, _, _, _, _, _, _, _, _)
    if hitObjectId ~= g_currentMission.player.rootNode then
        if getHasClassId(hitObjectId, ClassIds.SHAPE) then
            local splitShapeType = getSplitType(hitObjectId)
            if splitShapeType ~= 0 then
                local splitType = g_splitTypeManager:getSplitTypeByIndex(splitShapeType)
                if splitType ~= nil then
                    self.foundSplitShape = {objectId = hitObjectId, splitType = splitType}
                    return false
                end
            end
        end
    end
    return true -- continue raycast
end

function Firewood:collectFirewood()
    if self.foundSplitShape then
        local splitShapeVolume = getVolume(self.foundSplitShape.objectId) * 1000
        if splitShapeVolume < 400 then
            local pallet = self:findPalletInRange(16)
            if pallet then
                local firewoodLiters = splitShapeVolume * 0.6
                pallet.vehicle:addFillUnitFillLevel(pallet.vehicle:getOwnerFarmId(), pallet.fillUnitIndex, firewoodLiters, FillType.FIREWOOD, ToolType.UNDEFINED)
                DeleteSplitShapeEvent.sendEvent(self.foundSplitShape.objectId)
            else
                g_currentMission:showBlinkingWarning(g_i18n:getText("fw_warning_nopallet"), 1500)
            end
        else
            g_currentMission:showBlinkingWarning(g_i18n:getText("fw_warning_logtoobig"), 1500)
        end
    end
end

function Firewood:findPalletInRange(range)
    local pallet = nil
    local distance = math.huge
    local px, py, pz = getWorldTranslation(g_currentMission.player.rootNode)

    for _, v in pairs(g_currentMission.vehicles) do
        if v.getFillUnits then
            local fillUnitIndex = self:canLoadFirewood(v)
            if fillUnitIndex then
                local vx, vy, vz = getWorldTranslation(v.rootNode)
                local d = MathUtil.vector3Length(px - vx, py - vy, pz - vz)
                if d < distance then
                    distance = d
                    pallet = {vehicle = v, fillUnitIndex = fillUnitIndex}
                end
            end
        end
    end

    if distance <= range then
        return pallet
    end

    return nil
end

function Firewood:canLoadFirewood(vehicle)
    for _, f in pairs(vehicle:getFillUnits()) do
        local fillUnitIndex = f.fillUnitIndex
        if vehicle:getFillUnitSupportsFillType(fillUnitIndex, FillType.FIREWOOD) then
            if vehicle:getFillUnitLastValidFillType(FillType.FIREWOOD) or vehicle:getFillUnitLastValidFillType(FillType.UNKNOWN) then
                if vehicle:getFillUnitFreeCapacity(fillUnitIndex) > 0 then
                    return fillUnitIndex
                end
            end
        end
    end
    return nil
end

---Add Firewood to selling stationName
function Firewood.sellingStationLoad(object, superFunc, ...)
    if not superFunc(object, ...) then
        return false
    end

    local aW = object.acceptedFillTypes[FillType.WHEAT]
    local aB = object.acceptedFillTypes[FillType.BARLEY]
    local aO = object.acceptedFillTypes[FillType.OAT]
    local aC = object.acceptedFillTypes[FillType.CANOLA]
    local aS = object.acceptedFillTypes[FillType.SOYBEAN]
    local aSF = object.acceptedFillTypes[FillType.SUNFLOWER]
    local aM = object.acceptedFillTypes[FillType.MAIZE]

    if object.acceptedFillTypes[FillType.FIREWOOD] == nil and (aW or aB or aO or aC or aS or aSF or aM ) then
        object:addAcceptedFillType(FillType.FIREWOOD, g_fillTypeManager.fillTypes[FillType.FIREWOOD].pricePerLiter, true, false)

        --Re-init the pricing dynamics for the added pellets.
        object:initPricingDynamics()
    end

    return true
end

---Add a Firewood
function Firewood:loadFirewoodType()
    local hudOverlayFilename = "hud/fillTypes/hud_fill_firewood.png"
    local hudOverlayFilenameSmall = "hud/fillTypes/hud_fill_firewood_sml.png"
    local pricePerLiter = 10
    local massPerLiter = 0.750 / 1000

    g_fillTypeManager:addFillType("FIREWOOD", g_i18n:getText("fillType_firewood"), true, pricePerLiter, massPerLiter, 32, hudOverlayFilename, hudOverlayFilenameSmall, self.directory, nil, {1, 1, 1}, nil, false)

end
