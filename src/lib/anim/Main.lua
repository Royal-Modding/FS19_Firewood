--- Royal Animation

---@author Royal Modding
---@version 1.2.0.0
---@date 19/01/2021

--- Initialize RoyalAnimation
---@param utilityDirectory string
function InitRoyalAnimation(utilityDirectory)
    source(Utils.getFilename("Animation.lua", utilityDirectory))
    g_logManager:devInfo("Royal Animation loaded successfully by " .. g_currentModName)
    return true
end
