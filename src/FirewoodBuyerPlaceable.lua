--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 11/01/2021

FirewoodBuyerPlaceable = {}
FirewoodBuyerPlaceable_mt = Class(FirewoodBuyerPlaceable, Placeable)
InitObjectClass(FirewoodBuyerPlaceable, "FirewoodBuyerPlaceable")

function FirewoodBuyerPlaceable:new(isServer, isClient, customMt)
    local p = Placeable:new(isServer, isClient, customMt or FirewoodBuyerPlaceable_mt)
    registerObjectClassName(p, "FirewoodBuyerPlaceable")
    return p
end

function FirewoodBuyerPlaceable:delete()
    --if self.sellingStation ~= nil then
    --    g_currentMission.storageSystem:removeUnloadingStation(self.sellingStation)
    --    self.sellingStation:delete()
    --end

    unregisterObjectClassName(self)
    FirewoodBuyerPlaceable:superClass().delete(self)
end

function FirewoodBuyerPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
    if not FirewoodBuyerPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
        return false
    end

    local xmlFile = loadXMLFile("TempXML", xmlFilename)

    --self.sellingStation = SellingStation:new(self.isServer, self.isClient)
    --self.sellingStation:load(self.nodeId, xmlFile, "placeable.sellingStation", self.customEnvironment)
    --self.sellingStation.owningPlaceable = self

    local baseKey = "placeable.firewoodBuyer"

    local minPriceScale = getXMLFloat(xmlFile, baseKey .. "#minPriceScale") or 1
    local maxPriceScale = getXMLFloat(xmlFile, baseKey .. "#maxPriceScale") or 1

    self.priceScale = minPriceScale + math.random() * (maxPriceScale - minPriceScale)

    local minCapacity = getXMLFloat(xmlFile, baseKey .. "#minCapacity") or 1
    local maxCapacity = getXMLFloat(xmlFile, baseKey .. "#maxCapacity") or 1

    self.capacity = minCapacity + math.floor((math.random() * (maxCapacity - minCapacity)) / 100) * 100

    self.firewoodAmount = 0

    if self.isServer then
        self.usageScale = getXMLFloat(xmlFile, baseKey .. "#usageScale") or 1

        local sellTrigger = getXMLString(xmlFile, baseKey .. "#sellTrigger")

        if sellTrigger ~= nil then
            self.triggerNode = I3DUtil.indexToObject(self.nodeId, sellTrigger)
            if self.triggerNode ~= nil then
                addTrigger(self.triggerNode, "sellTriggerCallback", self)
            end
        end
    end

    delete(xmlFile)

    return true
end

function FirewoodBuyerPlaceable:finalizePlacement()
    FirewoodBuyerPlaceable:superClass().finalizePlacement(self)
    --self.sellingStation:register(true)
    --g_currentMission.storageSystem:addUnloadingStation(self.sellingStation)
end

function FirewoodBuyerPlaceable:readStream(streamId, connection)
    FirewoodBuyerPlaceable:superClass().readStream(self, streamId, connection)
    --if connection:getIsServer() then
    --    local sellingStationId = NetworkUtil.readNodeObjectId(streamId)
    --    self.sellingStation:readStream(streamId, connection)
    --    g_client:finishRegisterObject(self.sellingStation, sellingStationId)
    --end
end

function FirewoodBuyerPlaceable:writeStream(streamId, connection)
    FirewoodBuyerPlaceable:superClass().writeStream(self, streamId, connection)
    --if not connection:getIsServer() then
    --    NetworkUtil.writeNodeObjectId(streamId, NetworkUtil.getObjectId(self.sellingStation))
    --    self.sellingStation:writeStream(streamId, connection)
    --    g_server:registerObjectInStream(connection, self.sellingStation)
    --end
end

function FirewoodBuyerPlaceable:collectPickObjects(node)
    local foundNode = false
    --for _, unloadTrigger in ipairs(self.sellingStation.unloadTriggers) do
    --    if node == unloadTrigger.exactFillRootNode then
    --        foundNode = true
    --        break
    --    end
    --end

    if not foundNode then
        FirewoodBuyerPlaceable:superClass().collectPickObjects(self, node)
    end
end

function FirewoodBuyerPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
    if not FirewoodBuyerPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
        return false
    end

    --if not self.sellingStation:loadFromXMLFile(xmlFile, key .. ".sellingStation") then
    --    return false
    --end

    return true
end

function FirewoodBuyerPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
    FirewoodBuyerPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)

    --self.sellingStation:saveToXMLFile(xmlFile, key .. ".sellingStation", usedModNames)
end

function FirewoodBuyerPlaceable:triggerPalletCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    local object = g_currentMission:getNodeObject(otherId)

    if object ~= nil then
        DebugUtil.printTableRecursively(object, nil, nil, 0)
    end
    --if object ~= nil and object.isa ~= nil and object:isa(Vehicle) and object.typeName:find("pallet") then
    --    if onEnter then
    --        local fillUnitIndex = object:getFirstValidFillUnitToFill(FillType.STRAWPELLETS, true)
    --        if fillUnitIndex == nil then
    --            fillUnitIndex = object:getFirstValidFillUnitToFill(FillType.HAYPELLETS, true)
    --        end

    --        local fillType = object:getFillUnitFillType(fillUnitIndex)
    --        if fillType ~= nil then
    --            if self:getIsFillTypeAllowed(fillType) and object:getFillUnitFillLevel(fillUnitIndex) > 0 then
    --                self:raiseActive()
    --                self.palletsInTrigger[object] = fillType
    --            end
    --        end
    --    elseif onLeave then
    --        self.palletsInTrigger[object] = nil
    --    end
    --end
end
