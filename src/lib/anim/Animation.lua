--
-- Royal Animation
--
-- @author Royal Modding
-- @version 1.1.0.0
-- @date 19/01/2021

---@class RoyalAnimation
RoyalAnimation = {}
RoyalAnimation_mt = Class(RoyalAnimation)

---@param mt any
---@return RoyalAnimation
function RoyalAnimation:new(mt)
    ---@type RoyalAnimation
    local ra = setmetatable({}, mt or RoyalAnimation_mt)
    ra.nodeId = 0
    return ra
end

---@param nodeId integer rootNode
---@param xmlFile integer xmlFile
---@param key string xmlKey
---@return boolean
function RoyalAnimation:load(nodeId, xmlFile, key)
    self.nodeId = nodeId

    local animKey = key .. ".animation"

    self.parts = {}
    self.speed = 0
    self.repeats = 0
    self.time = 0
    self.duration = Utils.getNoNil(getXMLFloat(xmlFile, animKey .. "#duration"), 3) * 1000
    if self.duration == 0 then
        self.duration = 1000
    end

    local i = 0
    while true do
        local partKey = string.format("%s.part(%d)", animKey, i)
        if not hasXMLProperty(xmlFile, partKey) then
            break
        end
        local node = I3DUtil.indexToObject(self.nodeId, getXMLString(xmlFile, partKey .. "#node"))
        if node ~= nil then
            local part = {}
            part.node = node
            part.animCurve = AnimCurve:new(linearInterpolatorN)
            local hasFrames = false
            local j = 0
            while true do
                local frameKey = string.format("%s.keyFrame(%d)", partKey, j)
                if not hasXMLProperty(xmlFile, frameKey) then
                    break
                end
                local keyTime = getXMLFloat(xmlFile, frameKey .. "#time")
                if keyTime == nil then
                    keyTime = (getXMLFloat(xmlFile, frameKey .. "#timeSeconds") or self.duration) / self.duration
                end
                local keyframe = {self:loadFrameValues(xmlFile, frameKey, node)}
                keyframe.time = keyTime
                part.animCurve:addKeyframe(keyframe)
                hasFrames = true
                j = j + 1
            end
            if hasFrames then
                table.insert(self.parts, part)
            end
        end
        i = i + 1
    end
    return true
end

function RoyalAnimation:loadFrameValues(xmlFile, key, node)
    local rx, ry, rz = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#rotation"))
    local x, y, z = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#translation"))
    local sx, sy, sz = StringUtil.getVectorFromString(getXMLString(xmlFile, key .. "#scale"))
    local isVisible = Utils.getNoNil(getXMLBool(xmlFile, key .. "#visibility"), true)

    local drx, dry, drz = getRotation(node)
    rx = Utils.getNoNilRad(rx, drx)
    ry = Utils.getNoNilRad(ry, dry)
    rz = Utils.getNoNilRad(rz, drz)
    local dx, dy, dz = getTranslation(node)
    x = Utils.getNoNil(x, dx)
    y = Utils.getNoNil(y, dy)
    z = Utils.getNoNil(z, dz)
    local dsx, dsy, dsz = getScale(node)
    sx = Utils.getNoNil(sx, dsx)
    sy = Utils.getNoNil(sy, dsy)
    sz = Utils.getNoNil(sz, dsz)

    local visibility = 1
    if not isVisible then
        visibility = 0
    end

    return x, y, z, rx, ry, rz, sx, sy, sz, visibility
end

---@param dt number delta time
function RoyalAnimation:update(dt)
    if self.speed ~= 0 then
        local newAnimTime = MathUtil.clamp(self.time + (self.speed * dt) / self.duration, 0, 1)

        if newAnimTime == 0 or newAnimTime == 1 then
            self.repeats = math.max(self.repeats - 1, -1)
            if self.repeats == 0 then
                -- anim finished
                self.speed = 0
                newAnimTime = 0
            else
                -- restart loop
                if newAnimTime == 0 then
                    newAnimTime = 1
                else
                    newAnimTime = 0
                end
            end
        end
        self:setAnimTime(newAnimTime)
    end
end

---@param time number animation time
---@return number time animation time
function RoyalAnimation:setAnimTime(time)
    time = MathUtil.clamp(time, 0, 1)

    for _, part in pairs(self.parts) do
        self:setFrameValues(part.node, part.animCurve:get(time))
    end

    self.time = time
    return time
end

function RoyalAnimation:setFrameValues(node, values)
    setTranslation(node, values[1], values[2], values[3])
    setRotation(node, values[4], values[5], values[6])
    setScale(node, values[7], values[8], values[9])
    setVisibility(node, values[10] == 1)
end

---@param speed number anim speed (use negative numbers for reverse)
---@param repeats integer number of repetitions (use -1 for endless looping)
function RoyalAnimation:playAnim(speed, repeats)
    self.speed = speed
    self.repeats = repeats
end

---@param repeats integer number of repetitions before stopping
---@param force boolean stop now at the current anim time
function RoyalAnimation:stopAnim(repeats, force)
    if force then
        self.speed = 0
        self.repeats = 0
    else
        self.repeats = math.max(repeats, 1)
    end
end

---@return number animTime normalized animation time
---@return number animTimeSec animation time in seconds
function RoyalAnimation:getAnimTime()
    return self.time, self.duration * self.time
end

---@return boolean
function RoyalAnimation:getIsPlaying()
    return self.speed ~= 0
end

---@param direction number 1 for forward and -1 for backward
---@return boolean
function RoyalAnimation:getIsPlayingInDirection(direction)
    return self.speed == (direction or 1)
end
