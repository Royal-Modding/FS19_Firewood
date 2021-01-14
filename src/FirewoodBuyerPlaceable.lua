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
    if self.triggerNode ~= nil then
        removeTrigger(self.triggerNode)
    end

    unregisterObjectClassName(self)
    FirewoodBuyerPlaceable:superClass().delete(self)
end

function FirewoodBuyerPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
    if not FirewoodBuyerPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
        return false
    end

    print("FirewoodBuyerPlaceable:load")

    local xmlFile = loadXMLFile("TempXML", xmlFilename)

    local baseKey = "placeable.firewoodBuyer"

    self.storedFirewood = 0
    self.storageCapacity = 0

    if self.isServer and not self.isInPreviewMode then
        local minPriceScale = getXMLFloat(xmlFile, baseKey .. "#minPriceScale") or 1
        local maxPriceScale = getXMLFloat(xmlFile, baseKey .. "#maxPriceScale") or 1

        local minStorageCapacity = getXMLFloat(xmlFile, baseKey .. "#minStorageCapacity") or 5000
        local maxStorageCapacity = getXMLFloat(xmlFile, baseKey .. "#maxStorageCapacity") or 5000

        self.priceScale = minPriceScale + math.random() * (maxPriceScale - minPriceScale)

        self.storageCapacity = minStorageCapacity + math.floor((math.random() * (maxStorageCapacity - minStorageCapacity)) / 100) * 100

        self.usageScale = getXMLFloat(xmlFile, baseKey .. "#usageScale") or 1

        local sellTrigger = getXMLString(xmlFile, baseKey .. "#sellTrigger")
        if sellTrigger ~= nil then
            self.triggerNode = I3DUtil.indexToObject(self.nodeId, sellTrigger)
            if self.triggerNode ~= nil then
                addTrigger(self.triggerNode, "sellTriggerCallback", self)
            end
        end
    end

    self.dummyVisuals = {}
    local dummyVisualsKey = baseKey .. ".dummyVisual"
    local dummyVisualsIndex = 0
    while true do
        local key = string.format("%s(%d)", dummyVisualsKey, dummyVisualsIndex)
        if not hasXMLProperty(xmlFile, key) then
            break
        end
        local dummyVisual = getXMLString(xmlFile, key .. "#node")
        if dummyVisual ~= nil then
            local dummyVisualObject = I3DUtil.indexToObject(self.nodeId, dummyVisual)
            if dummyVisualObject ~= nil then
                table.insert(self.dummyVisuals, dummyVisualObject)
            end
        end
        dummyVisualsIndex = dummyVisualsIndex + 1
    end

    delete(xmlFile)

    return true
end

function FirewoodBuyerPlaceable:finalizePlacement()
    print("FirewoodBuyerPlaceable:finalizePlacement")
    FirewoodBuyerPlaceable:superClass().finalizePlacement(self)
    for _, dv in ipairs(self.dummyVisuals) do
        if entityExists(dv) then
            delete(dv)
        end
    end
end

function FirewoodBuyerPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
    if not FirewoodBuyerPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
        return false
    end

    print("FirewoodBuyerPlaceable:loadFromXMLFile")

    self.priceScale = getXMLFloat(xmlFile, key .. "#priceScale") or self.priceScale
    self.storageCapacity = getXMLFloat(xmlFile, key .. "#storageCapacity") or self.storageCapacity
    self.storedFirewood = getXMLFloat(xmlFile, key .. "#firewoodAmount") or self.storedFirewood

    return true
end

function FirewoodBuyerPlaceable:writeStream(streamId, connection)
    print("FirewoodBuyerPlaceable:writeStream")
    FirewoodBuyerPlaceable:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        streamWriteFloat32(streamId, self.storageCapacity)
        streamWriteFloat32(streamId, self.storedFirewood)
    end
end

function FirewoodBuyerPlaceable:readStream(streamId, connection)
    print("FirewoodBuyerPlaceable:readStream")
    FirewoodBuyerPlaceable:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        self.storageCapacity = streamReadFloat32(streamId)
        self.storedFirewood = streamReadFloat32(streamId)
    end
end

function FirewoodBuyerPlaceable:collectPickObjects(node)
    local foundNode = false
    if node == self.triggerNode then
        foundNode = true
    end
    if not foundNode then
        FirewoodBuyerPlaceable:superClass().collectPickObjects(self, node)
    end
end

function FirewoodBuyerPlaceable:sellTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    local object = g_currentMission:getNodeObject(otherId)

    if object ~= nil and onEnter then
        --DebugUtil.printTableRecursively(object, nil, nil, 0)
        print(otherId)
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

function FirewoodBuyerPlaceable:saveToXMLFile(xmlFile, key, usedModNames)
    FirewoodBuyerPlaceable:superClass().saveToXMLFile(self, xmlFile, key, usedModNames)

    setXMLFloat(xmlFile, key .. "#priceScale", self.priceScale)
    setXMLFloat(xmlFile, key .. "#storageCapacity", self.storageCapacity)
    setXMLFloat(xmlFile, key .. "#firewoodAmount", self.storedFirewood)
end

-- fix non normalized width and height of hotspot icons
function FirewoodBuyerPlaceable:loadHotspotFromXML(xmlFile, key)
    local hotspot = FirewoodBuyerPlaceable:superClass().loadHotspotFromXML(self, xmlFile, key)

    local width = getXMLFloat(xmlFile, key .. "#width")
    local height = getXMLFloat(xmlFile, key .. "#height")
    if width ~= nil and height ~= nil then
        width, height = getNormalizedScreenValues(width, height)
        hotspot:setSize(width, height)
    end

    return hotspot
end
