---${title}

---@author ${author}
---@version r_version_r
---@date 07/02/2021

LightAnimatedVehicle = {}

function LightAnimatedVehicle.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(AnimatedVehicle, specializations)
end

function LightAnimatedVehicle.registerOverwrittenFunctions(vehicleType)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAnimation", LightAnimatedVehicle.loadAnimation)
    SpecializationUtil.registerOverwrittenFunction(vehicleType, "loadAnimationPart", LightAnimatedVehicle.loadAnimationPart)
end

function LightAnimatedVehicle:loadAnimation(superFunc, xmlFile, key, animation)
    self.spec_animatedVehicle.isLightAnimation = getXMLBool(xmlFile, key .. "#isLight") or false
    self.spec_animatedVehicle.isVeryLightAnimation = getXMLBool(xmlFile, key .. "#isVeryLight") or false
    local result = superFunc(self, xmlFile, key, animation)
    self.spec_animatedVehicle.isLightAnimation = nil
    self.spec_animatedVehicle.isVeryLightAnimation = nil
    return result
end

function LightAnimatedVehicle:loadAnimationPart(superFunc, xmlFile, partKey, part)
    if self.spec_animatedVehicle.isVeryLightAnimation then
        local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, partKey .. "#node"), self.i3dMappings)
        local startTime = getXMLFloat(xmlFile, partKey .. "#startTime")
        local endTime = getXMLFloat(xmlFile, partKey .. "#endTime")
        local visibility = getXMLBool(xmlFile, partKey .. "#visibility")

        if startTime ~= nil and endTime ~= nil then
            part.node = node
            part.duration = (endTime - startTime) * 1000
            part.startTime = startTime * 1000
            part.direction = 0
            if node ~= nil then
                part.visibility = visibility
            end
            return true
        end
        return false
    elseif self.spec_animatedVehicle.isLightAnimation then
        local node = I3DUtil.indexToObject(self.components, getXMLString(xmlFile, partKey .. "#node"), self.i3dMappings)
        local startTime = getXMLFloat(xmlFile, partKey .. "#startTime")
        local endTime = getXMLFloat(xmlFile, partKey .. "#endTime")
        local startRot = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#startRot"), 3)
        local endRot = StringUtil.getRadiansFromString(getXMLString(xmlFile, partKey .. "#endRot"), 3)
        local startTrans = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#startTrans"), 3)
        local endTrans = StringUtil.getVectorNFromString(getXMLString(xmlFile, partKey .. "#endTrans"), 3)
        local visibility = getXMLBool(xmlFile, partKey .. "#visibility")

        if startTime ~= nil and endTime ~= nil then
            part.node = node
            part.duration = (endTime - startTime) * 1000
            part.startTime = startTime * 1000
            part.direction = 0
            if node ~= nil then
                if endRot ~= nil then
                    part.startRot = startRot
                    part.endRot = endRot
                end
                if endTrans ~= nil then
                    part.startTrans = startTrans
                    part.endTrans = endTrans
                end
                part.visibility = visibility
            end
            return true
        end
        return false
    else
        return superFunc(self, xmlFile, partKey, part)
    end
end
