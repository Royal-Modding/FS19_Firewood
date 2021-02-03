---${title}

---@author ${author}
---@version r_version_r
---@date 30/01/2021

FoliageBendingFix = {}

function FoliageBendingFix.prerequisitesPresent(specializations)
    return true
end

function FoliageBendingFix.registerEventListeners(vehicleType)
    SpecializationUtil.registerEventListener(vehicleType, "onLoad", FoliageBendingFix)
    SpecializationUtil.registerEventListener(vehicleType, "onPostLoad", FoliageBendingFix)
end

function FoliageBendingFix:onLoad(savegame)
    local spec = self.spec_foliageBending
    spec.alwaysActive = getXMLBool(self.xmlFile, "vehicle.foliageBending#alwaysActive") or false
end

function FoliageBendingFix:onPostLoad(savegame)
    local spec = self.spec_foliageBending
    if spec.alwaysActive then
        self:activateBendingNodes()
    end
end
