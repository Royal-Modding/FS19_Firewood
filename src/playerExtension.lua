--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 11/12/2020

PlayerExtension = {}

function PlayerExtension:new(superFunc, isServer, isClient)
    self = superFunc(nil, isServer, isClient)
    self.inputInformation.registrationList[InputAction.FIREWOOD_MAKE] = {
        eventId = "",
        callback = self.makeFirewoodActionEvent,
        triggerUp = false,
        triggerDown = true,
        triggerAlways = false,
        activeType = Player.INPUT_ACTIVE_TYPE.STARTS_DISABLED,
        callbackState = nil,
        text = g_i18n:getText("fw_MAKE"),
        textVisibility = false
    }
    return self
end

function PlayerExtension:updateActionEvents()
    local eventId = self.inputInformation.registrationList[InputAction.FIREWOOD_MAKE].eventId
    g_inputBinding:setActionEventActive(eventId, Firewood.foundSplitShape ~= nil)
    g_inputBinding:setActionEventTextVisibility(eventId, Firewood.foundSplitShape ~= nil)
end

function PlayerExtension:makeFirewoodActionEvent()
    Firewood:collectFirewood()
end
