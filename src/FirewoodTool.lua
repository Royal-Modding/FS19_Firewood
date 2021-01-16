--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 16/01/2021

FirewoodTool = {}
local FirewoodTool_mt = Class(FirewoodTool, HandTool)
FirewoodTool.treeCollisionMask = 16789504

InitObjectClass(FirewoodTool, "FirewoodTool")

function FirewoodTool:new(isServer, isClient, customMt)
    local ft = HandTool:new(isServer, isClient, customMt or FirewoodTool_mt)
    ft.isChopping = false
    ft.cutFocusDistance = -1.0
    ft.minChopDistance = 1
    ft.maxChopDistance = 3
    return ft
end

function FirewoodTool:load(xmlFilename, player)
    if not FirewoodTool:superClass().load(self, xmlFilename, player) then
        return false
    end

    --local xmlFile = loadXMLFile("TempXML", xmlFilename)

    --self.pricePerMilliSecond = Utils.getNoNil(getXMLFloat(xmlFile, "handTool.FirewoodTool.pricePerSecond"), 50) / 1000
    --self.moveCounter = 0

    --if self.isClient then
    --    self.sampleMeasure = g_soundManager:loadSampleFromXML(xmlFile, "handTool.FirewoodTool.sounds", "measure", self.baseDirectory, self.rootNode, 1, AudioGroup.VEHICLE, nil, nil)
    --end

    --delete(xmlFile)

    return true
end

function FirewoodTool:delete()
    --if self.isClient then
    --    g_soundManager:deleteSample(self.sampleMeasure)
    --end

    FirewoodTool:superClass().delete(self)
end

function FirewoodTool:update(dt, allowInput)
    FirewoodTool:superClass().update(self, dt, allowInput)

    if self.isClient then
        if not self.isChopping then
            self:updateChopRaycast()
        end

        if self.showNotOwnedWarning then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 2000)
            self.showNotOwnedWarning = false -- reset so it can be set to true later
        end
    end

    Utility.renderTable(0.15, 0.8, 0.015, self.choppingData or {"nil"})
end

function FirewoodTool:draw()
    FirewoodTool:superClass().draw(self)
end

function FirewoodTool:onDeactivate(allowInput)
    FirewoodTool:superClass().onDeactivate(self)
end

function FirewoodTool:updateChopRaycast()
    self.choppingData = nil
    local cameraPosition = {getWorldTranslation(self.player.cameraNode)}
    local worldDirection = {unProject(0.52, 0.4, 1)}
    worldDirection[1], worldDirection[2], worldDirection[3] = MathUtil.vector3Normalize(worldDirection[1], worldDirection[2], worldDirection[3])
    raycastClosest(cameraPosition[1], cameraPosition[2], cameraPosition[3], worldDirection[1], worldDirection[2], worldDirection[3], "chopRaycastCallback", self.maxChopDistance, self, self.treeCollisionMask)
end

function FirewoodTool:chopRaycastCallback(hitObjectId, x, y, z, distance)
    if distance <= self.maxChopDistance and distance >= self.minChopDistance then
        self.choppingData = {objectId = hitObjectId, x = x, y = y, z = z, distance = distance}
    end
end

registerHandTool("firewoodTool", FirewoodTool)
