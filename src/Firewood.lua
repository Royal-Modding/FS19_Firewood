---${title}

---@author ${author}
---@version r_version_r
---@date 09/01/2021

InitRoyalMod(Utils.getFilename("lib/rmod/", g_currentModDirectory))
InitRoyalUtility(Utils.getFilename("lib/utility/", g_currentModDirectory))
InitRoyalAnimation(Utils.getFilename("lib/anim/", g_currentModDirectory))

---@class Firewood : RoyalMod
Firewood = RoyalMod.new(r_debug_r, false)
Firewood.scanTimer = 0
Firewood.scanTimeout = 750
Firewood.foundSplitShape = nil

Firewood.sellPoints = {}
Firewood.inRangeSellPointTimer = 0
Firewood.inRangeSellPointTimeout = 500
Firewood.inRangeSellPoint = nil

function Firewood:initialize()
    Utility.overwrittenFunction(Player, "new", PlayerExtension.new)
    Utility.appendedFunction(Player, "updateActionEvents", PlayerExtension.updateActionEvents)
    if Player.makeFirewoodActionEvent == nil then
        Player.makeFirewoodActionEvent = PlayerExtension.makeFirewoodActionEvent
    end

    Utility.overwrittenFunction(SellingStation, "load", Firewood.sellingStationLoad)

    g_placeableTypeManager:addPlaceableType("firewoodBuyer", "FirewoodBuyerPlaceable", self.directory .. "FirewoodBuyerPlaceable.lua")

    --Utility.getVehicleLoadingSpeedMeter().addFilter(
    --    function(vehicleData)
    --        return string.find(vehicleData.filename, "firewoodPallet.xml"), "Firewood Pallet"
    --    end
    --)

    self.gameEnv["g_firewood"] = {}
    self.gameEnv["g_firewood"].Firewood = self
    self.gameEnv["g_firewood"].FirewoodTool = FirewoodTool
end

function Firewood:onValidateVehicleTypes(vehicleTypeManager, addSpecialization, addSpecializationBySpecialization, addSpecializationByVehicleType, addSpecializationByFunction)
    --addSpecializationBySpecialization("foliageBendingFix", "foliageBending")
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
        self.inRangeSellPointTimer = self.inRangeSellPointTimer + dt

        if self.scanTimer >= self.scanTimeout then
            self.scanTimer = 0
            self.foundSplitShape = nil
            local x, y, z = localToWorld(g_currentMission.player.cameraNode, 0, 0, 1.0)
            local dx, dy, dz = localDirectionToWorld(g_currentMission.player.cameraNode, 0, 0, -1)
            raycastAll(x, y, z, dx, dy, dz, "raycastCallback", 5, self)
        end

        if self.inRangeSellPointTimer >= self.inRangeSellPointTimeout then
            self.inRangeSellPointTimer = 0
            self.inRangeSellPoint = self:getClosestSellPoint(g_currentMission.player, 8)
        end

        if self.inRangeSellPoint and not g_gui:getIsGuiVisible() and not g_currentMission.player:hasHandtoolEquipped() then
            g_currentMission:addExtraPrintText(string.format("%s: %d / %d", g_i18n:convertText("$l10n_fw_fillType_firewood"), self.inRangeSellPoint.storedFirewood, self.inRangeSellPoint.storageCapacity))
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

function Firewood:onLoadHelpLine()
    return self.directory .. "gui/helpLine.xml"
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
    if self.foundSplitShape and entityExists(self.foundSplitShape.objectId) then
        local splitShapeVolume = getVolume(self.foundSplitShape.objectId) * 1000
        local pallet = self:findPalletInRange(25)
        if pallet then
            MakeFirewoodEvent.sendEvent(pallet.vehicle, pallet.fillUnitIndex, splitShapeVolume * 0.25)
            DeleteSplitShapeEvent.sendEvent(self.foundSplitShape.objectId)
        end
    end
end

function Firewood:findPalletInRange(range)
    local pallet = nil
    local distance = math.huge
    local px, py, pz = getWorldTranslation(g_currentMission.player.rootNode)

    for _, v in pairs(g_currentMission.vehicles) do
        if v.getFirstValidFillUnitToFill then
            local fillUnitIndex = v:getFirstValidFillUnitToFill(FillType.FIREWOOD)
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

---Add Firewood to selling stationName
function Firewood.sellingStationLoad(object, superFunc, ...)
    --if not superFunc(object, ...) then
    --    return false
    --end
    local ret = superFunc(object, ...)

    local aW = object.acceptedFillTypes[FillType.WHEAT]
    local aB = object.acceptedFillTypes[FillType.BARLEY]
    local aO = object.acceptedFillTypes[FillType.OAT]
    local aC = object.acceptedFillTypes[FillType.CANOLA]
    local aS = object.acceptedFillTypes[FillType.SOYBEAN]
    local aSF = object.acceptedFillTypes[FillType.SUNFLOWER]
    local aM = object.acceptedFillTypes[FillType.MAIZE]

    if object.acceptedFillTypes[FillType.FIREWOOD] == nil and (aW or aB or aO or aC or aS or aSF or aM) then
        object:addAcceptedFillType(FillType.FIREWOOD, g_fillTypeManager.fillTypes[FillType.FIREWOOD].pricePerLiter, true, false)
        --Re-init the pricing dynamics for the added pellets.
        object:initPricingDynamics()
    end

    return ret
end

---Add a Firewood
function Firewood:loadFirewoodType()
    local hudOverlayFilename = "hud/fillTypes/hud_fill_firewood.png"
    local hudOverlayFilenameSmall = "hud/fillTypes/hud_fill_firewood_sml.png"
    local pricePerLiter = 1.1
    local massPerLiter = 1.5 / 1000

    g_fillTypeManager:addFillType("FIREWOOD", g_i18n:getText("fw_fillType_firewood"), true, pricePerLiter, massPerLiter, 32, hudOverlayFilename, hudOverlayFilenameSmall, self.directory, nil, {1, 1, 1}, nil, false)
end

function Firewood:getClosestSellPoint(player, maxDistance)
    maxDistance = maxDistance or 15
    local sellPoint = nil
    local sellPointDistance = math.huge
    local px, py, pz = getWorldTranslation(player.rootNode)
    for sp, _ in pairs(self.sellPoints) do
        local spx, spy, spz = getWorldTranslation(sp.nodeId)
        local distance = MathUtil.vector3Length(px - spx, py - spy, pz - spz)
        if distance <= sellPointDistance then
            sellPointDistance = distance
            sellPoint = sp
        end
    end
    if sellPointDistance <= maxDistance then
        return sellPoint
    end
end
