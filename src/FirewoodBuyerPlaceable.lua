---${title}

---@author ${author}
---@version r_version_r
---@date 11/01/2021

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

    Firewood.sellPoints[self] = nil

    unregisterObjectClassName(self)
    FirewoodBuyerPlaceable:superClass().delete(self)
end

function FirewoodBuyerPlaceable:load(xmlFilename, x, y, z, rx, ry, rz, initRandom)
    if not FirewoodBuyerPlaceable:superClass().load(self, xmlFilename, x, y, z, rx, ry, rz, initRandom) then
        return false
    end

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

        self.baseHotspotColor = StringUtil.getVectorNFromString(getXMLString(xmlFile, "placeable.hotspots#baseColor"), 4)
        self.activeHotspotColor = StringUtil.getVectorNFromString(getXMLString(xmlFile, "placeable.hotspots#activeColor"), 4)
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

    self.fillAnimation = RoyalAnimation:new()
    self.fillAnimation:load(self.nodeId, xmlFile, baseKey .. ".fill")

    self:setStoredFirewood(0)

    delete(xmlFile)

    return true
end

function FirewoodBuyerPlaceable:finalizePlacement()
    FirewoodBuyerPlaceable:superClass().finalizePlacement(self)
    for _, dv in ipairs(self.dummyVisuals) do
        if entityExists(dv) then
            delete(dv)
        end
    end
    Firewood.sellPoints[self] = true
    self.dirtyFlag = self:getNextDirtyFlag()
end

function FirewoodBuyerPlaceable:loadFromXMLFile(xmlFile, key, resetVehicles)
    if not FirewoodBuyerPlaceable:superClass().loadFromXMLFile(self, xmlFile, key, resetVehicles) then
        return false
    end

    self.priceScale = getXMLFloat(xmlFile, key .. "#priceScale") or self.priceScale
    self.storageCapacity = getXMLFloat(xmlFile, key .. "#storageCapacity") or self.storageCapacity
    self:setStoredFirewood(getXMLFloat(xmlFile, key .. "#firewoodAmount") or self.storedFirewood)

    return true
end

function FirewoodBuyerPlaceable:writeStream(streamId, connection)
    FirewoodBuyerPlaceable:superClass().writeStream(self, streamId, connection)
    if not connection:getIsServer() then
        streamWriteFloat32(streamId, self.storageCapacity)
        streamWriteFloat32(streamId, self.storedFirewood)
    end
end

function FirewoodBuyerPlaceable:readStream(streamId, connection)
    FirewoodBuyerPlaceable:superClass().readStream(self, streamId, connection)
    if connection:getIsServer() then
        self.storageCapacity = streamReadFloat32(streamId)
        self:setStoredFirewood(streamReadFloat32(streamId))
    end
end

function FirewoodBuyerPlaceable:writeUpdateStream(streamId, connection, dirtyMask)
    FirewoodBuyerPlaceable:superClass().writeUpdateStream(self, streamId, connection, dirtyMask)
    if not connection:getIsServer() then
        if streamWriteBool(streamId, bitAND(dirtyMask, self.dirtyFlag) ~= 0) then
            streamWriteFloat32(streamId, self.storedFirewood)
        end
    end
end

function FirewoodBuyerPlaceable:readUpdateStream(streamId, timestamp, connection)
    FirewoodBuyerPlaceable:superClass().readUpdateStream(self, streamId, timestamp, connection)
    if connection:getIsServer() then
        if streamReadBool(streamId) then
            self:setStoredFirewood(streamReadFloat32(streamId))
        end
    end
end

function FirewoodBuyerPlaceable:sellTriggerCallback(triggerId, otherId, onEnter, onLeave, onStay, otherShapeId)
    local object = g_currentMission:getNodeObject(otherId)
    if object ~= nil and object.isa ~= nil and object:isa(Vehicle) and (object.typeName:find("pallet") or object.typeName:find("fwPallet")) then
        if onEnter then
            local fillUnitIndex = object:getFirstValidFillUnitToFill(FillType.FIREWOOD, true)
            local fillUnitFillLevel = object:getFillUnitFillLevel(fillUnitIndex)
            local freeSpace = self.storageCapacity - self.storedFirewood

            if fillUnitFillLevel / 2 <= freeSpace then
                local farmId = object:getOwnerFarmId()
                local appliedDelta = math.abs(object:addFillUnitFillLevel(farmId, fillUnitIndex, -math.huge, FillType.FIREWOOD, ToolType.UNDEFINED))
                self:setStoredFirewood(self.storedFirewood + appliedDelta)
                local sellPrice = g_fillTypeManager:getFillTypeByIndex(FillType.FIREWOOD).pricePerLiter * appliedDelta * EconomyManager.getPriceMultiplier()
                g_currentMission:addMoney(sellPrice * self.priceScale, farmId, MoneyType.SOLD_WOOD, true, true)
                self:raiseActive()
                self:raiseDirtyFlags(self.dirtyFlag)
            end
        end
    end
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

function FirewoodBuyerPlaceable:hourChanged()
    FirewoodBuyerPlaceable:superClass().hourChanged(self)
    if self.isServer and self.storedFirewood > 0 then
        local sellEnabled = true
        local sellAmount = (3000 / 72) -- one full pallet every three days
        local airTemp = g_currentMission.environment.weather.airTemperature or 10
        if airTemp <= 3 then
            sellAmount = sellAmount * 1.25
        end

        if g_seasons then
            sellAmount = sellAmount * 2
            -- sell only from mid autumnn to early spring
            if g_seasons.environment.period >= 2 and g_seasons.environment.period <= 7 then
                sellEnabled = false
            end
        end

        if sellEnabled then
            self:setStoredFirewood(self.storedFirewood - sellAmount)
            self:raiseDirtyFlags(self.dirtyFlag)
        end
    end
end

function FirewoodBuyerPlaceable:setStoredFirewood(storedFirewood)
    if storedFirewood ~= self.storedFirewood then
        self.storedFirewood = math.max(0, storedFirewood)
        local fillPercentage = Utility.clamp(0, self.storedFirewood / self.storageCapacity, 1)
        self.fillAnimation:setAnimTime(fillPercentage)

        if self.activeHotspotColor and self.baseHotspotColor then
            local color = self.baseHotspotColor
            if fillPercentage < 0.3 then
                color = self.activeHotspotColor
            end
            for _, hotspot in pairs(self.mapHotspots) do
                hotspot:setColor(color)
            end
        end
    end
end
