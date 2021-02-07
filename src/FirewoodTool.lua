---${title}

---@author ${author}
---@version r_version_r
---@date 16/01/2021

---@class FirewoodTool
---@field superClass fun(self:table):any
---@field isClient boolean
---@field rootNode integer
---@field baseDirectory string
FirewoodTool = {}
FirewoodTool.treeCollisionMask = 16777216
FirewoodTool_mt = Class(FirewoodTool, HandTool)

InitObjectClass(FirewoodTool, "FirewoodTool")

---@return FirewoodTool
function FirewoodTool:new(isServer, isClient, customMt)
    ---@type FirewoodTool
    local ft = HandTool:new(isServer, isClient, customMt or FirewoodTool_mt)
    ft.isChopping = false
    ft.minChopDistance = 1
    ft.maxChopDistance = 3
    ft.choppingScale = 1
    ft.choppingTimer = 0
    ft.choppingMinTimeout = 700
    ft.choppingMaxTimeout = 6000 / ft.choppingScale
    ft.choppingMinTimeoutVolume = 75
    ft.choppingMaxTimeoutVolume = 350
    ft.maxChoppingVolume = 400
    ft.maxPalletRange = 16

    ft.showNotOwnedWarning = false
    ft.showTooBigWarning = false
    ft.showPalletNotInRangeWarning = false

    ft.pauseTimer = 0
    ft.pauseTimeout = 100
    return ft
end

function FirewoodTool:load(xmlFilename, player)
    if not FirewoodTool:superClass().load(self, xmlFilename, player) then
        return false
    end

    local xmlFileId = loadXMLFile("TempXML", xmlFilename)

    self.minChopDistance = getXMLFloat(xmlFileId, "handTool.firewoodTool#minChopDistance") or self.minChopDistance
    self.maxChopDistance = getXMLFloat(xmlFileId, "handTool.firewoodTool#maxChopDistance") or self.maxChopDistance
    self.choppingScale = getXMLFloat(xmlFileId, "handTool.firewoodTool#choppingScale") or self.choppingScale
    self.choppingMaxTimeout = self.choppingMaxTimeout / self.choppingScale
    self.maxPalletRange = getXMLFloat(xmlFileId, "handTool.firewoodTool#maxPalletRange") or self.maxPalletRange

    self.equipmentUVs = StringUtil.getVectorNFromString(getXMLString(xmlFileId, "handTool.firewoodTool#equipmentUvs") or "0 0", 2)

    if self.isClient then
        self.workAnimation = RoyalAnimation:new()
        self.workAnimation:load(self.rootNode, xmlFileId, "handTool.work")
        self.workSample = g_soundManager:loadSampleFromXML(xmlFileId, "handTool.work", "sound", self.baseDirectory, self.rootNode, 1, AudioGroup.DEFAULT, nil, nil)
        self.splitSample = g_soundManager:loadSampleFromXML(xmlFileId, "handTool.work", "splitSound", self.baseDirectory, self.rootNode, 1, AudioGroup.DEFAULT, nil, nil)
    end

    delete(xmlFileId)

    return true
end

function FirewoodTool:delete()
    if self.isClient then
        g_soundManager:deleteSample(self.workSample)
        g_soundManager:deleteSample(self.splitSample)
    end

    FirewoodTool:superClass().delete(self)
end

function FirewoodTool:update(dt, allowInput)
    FirewoodTool:superClass().update(self, dt, allowInput)

    if self.isClient and self.player.isOwner then
        if not self.isChopping then
            self:updateChopRaycast()
        end

        if self.showNotOwnedWarning then
            g_currentMission:showBlinkingWarning(g_i18n:getText("warning_youDontHaveAccessToThisLand"), 1500)
            self.showNotOwnedWarning = false
        end

        if self.showTooBigWarning then
            g_currentMission:showBlinkingWarning(g_i18n:getText("fw_warning_logtoobig"), 1500)
            self.showTooBigWarning = false
        end

        if self.showPalletNotInRangeWarning then
            g_currentMission:showBlinkingWarning(g_i18n:getText("fw_warning_nopallet"), 1500)
            self.showPalletNotInRangeWarning = false
        end

        if self.pauseTimer > 0 then
            self.pauseTimer = self.pauseTimer - dt
        end

        if self.activatePressed and self.choppingData ~= nil and self.pauseTimer <= 0 then
            if not self.isChopping and self:checkCanBeChopped(self.choppingData) then
                local pallet = Firewood:findPalletInRange(self.maxPalletRange)
                if pallet ~= nil then
                    self.choppingData.pallet = pallet
                    self.isChopping = true
                    self.workAnimation:playAnim(1, -1)
                    self.choppingData.chopTime = self:getChoppingTime(self.choppingData.volume)
                else
                    self.showPalletNotInRangeWarning = true
                end
            end
            if self.isChopping then
                self.choppingTimer = self.choppingTimer + dt
                if self.choppingTimer >= self.choppingData.chopTime then
                    if self.choppingData.pallet ~= nil then
                        self.chop(self.choppingData.pallet, self:getChoppingVolume(self.choppingData), self.choppingData.objectId)
                        g_soundManager:playSample(self.splitSample)
                        self.pauseTimer = self.pauseTimeout
                    end
                    self:resetChopping()
                end
            end
        else
            self:resetChopping()
        end

        self.workAnimation:update(dt)

        if self.workAnimation:getIsPlaying() then
            if not g_soundManager:getIsSamplePlaying(self.workSample, 0) then
                g_soundManager:playSample(self.workSample)
            end
        else
            if g_soundManager:getIsSamplePlaying(self.workSample, 0) then
                g_soundManager:stopSample(self.workSample)
            end
        end
        self.activatePressed = false
    end
end

function FirewoodTool.chop(pallet, volume, objectId)
    DeleteSplitShapeEvent.sendEvent(objectId)
    MakeFirewoodEvent.sendEvent(pallet.vehicle, pallet.fillUnitIndex, volume)
end

function FirewoodTool:checkCanBeChopped(choppingData, doNotWarn)
    if not g_currentMission.accessHandler:canFarmAccessLand(self.player.farmId, choppingData.x, choppingData.z) then
        self.showNotOwnedWarning = true and not doNotWarn
        return false
    end
    if choppingData.volume > self.maxChoppingVolume then
        self.showTooBigWarning = true and not doNotWarn
        return false
    end
    return true
end

function FirewoodTool:resetChopping()
    self.isChopping = false
    self.choppingTimer = 0
    self.choppingData = nil
    self.workAnimation:stopAnim(1)
end

function FirewoodTool:updateChopRaycast()
    self.choppingData = nil
    local cameraPosition = {getWorldTranslation(self.player.cameraNode)}
    local worldDirection = {unProject(0.52, 0.4, 1)}
    worldDirection[1], worldDirection[2], worldDirection[3] = MathUtil.vector3Normalize(worldDirection[1], worldDirection[2], worldDirection[3])
    raycastClosest(cameraPosition[1], cameraPosition[2], cameraPosition[3], worldDirection[1], worldDirection[2], worldDirection[3], "chopRaycastCallback", self.maxChopDistance, self, self.treeCollisionMask)
end

function FirewoodTool:chopRaycastCallback(hitObjectId, x, y, z, distance)
    if getHasClassId(hitObjectId, ClassIds.SHAPE) then
        local splitShapeType = getSplitType(hitObjectId)
        if splitShapeType ~= 0 then
            if distance <= self.maxChopDistance and distance >= self.minChopDistance then
                self.choppingData = {objectId = hitObjectId, x = x, y = y, z = z, distance = distance, volume = getVolume(hitObjectId) * 1000}
            end
        end
    end
end

function FirewoodTool:getChoppingTime(volume)
    local clampedVolume = Utility.clamp(self.choppingMinTimeoutVolume, volume, self.choppingMaxTimeoutVolume)
    local normalizedVolume = (clampedVolume - self.choppingMinTimeoutVolume) / (self.choppingMaxTimeoutVolume - self.choppingMinTimeoutVolume)
    local steps = math.ceil(self.choppingMaxTimeout / 1000)
    local time = (math.ceil(steps * normalizedVolume) * 1000) + self.choppingMinTimeout
    return time
end

function FirewoodTool:getChoppingVolume(choppingData)
    -- maxGain if volume <= maxGainVolume otherwise gain drops progressively to minGain untill minGainVolume
    local maxGain = 1.3
    local maxGainVolume = 30
    local minGain = 0.35
    local minGainVolume = 280
    local gain = 1
    if choppingData.volume <= maxGainVolume then
        gain = maxGain
    elseif choppingData.volume >= minGainVolume then
        gain = minGain
    else
        local normalizedInvertedVolume = 1 - (choppingData.volume - maxGainVolume) / (minGainVolume - maxGainVolume)
        gain = minGain + (maxGain - minGain) * normalizedInvertedVolume
    end
    return choppingData.volume * gain
end

function FirewoodTool:onActivate(allowInput)
    FirewoodTool:superClass().onActivate(self)

    if not self.player.isOwner then
        self.player.visualInformation:setProtectiveUV(self.equipmentUVs)
        self.player:setWoodWorkVisibility(true)
    end
end

function FirewoodTool:onDeactivate(allowInput)
    FirewoodTool:superClass().onDeactivate(self)

    self.player:setWoodWorkVisibility(false)
end

registerHandTool("firewoodTool", FirewoodTool)
