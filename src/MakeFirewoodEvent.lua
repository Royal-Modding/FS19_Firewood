--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 31/01/2021

MakeFirewoodEvent = {}
MakeFirewoodEvent_mt = Class(MakeFirewoodEvent, Event)

InitEventClass(MakeFirewoodEvent, "MakeFirewoodEvent")

function MakeFirewoodEvent:emptyNew()
    local e = Event:new(MakeFirewoodEvent_mt)
    return e
end

function MakeFirewoodEvent:new(vehicle, fillUnitIndex, volume)
    local e = MakeFirewoodEvent:emptyNew()
    e.vehicle = vehicle
    e.fillUnitIndex = fillUnitIndex
    e.volume = volume
    return e
end

function MakeFirewoodEvent:writeStream(streamId, connection)
    NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteUInt16(streamId, self.fillUnitIndex)
    streamWriteFloat32(streamId, self.volume)
end

function MakeFirewoodEvent:readStream(streamId, connection)
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.fillUnitIndex = streamReadUInt16(streamId)
    self.volume = streamReadFloat32(streamId)
    self:run(connection)
end

function MakeFirewoodEvent:run(connection)
    if self.vehicle ~= nil then
        self.vehicle:addFillUnitFillLevel(self.vehicle:getOwnerFarmId(), self.fillUnitIndex, self.volume, FillType.FIREWOOD, ToolType.UNDEFINED)
    end
end

function MakeFirewoodEvent.sendEvent(vehicle, fillUnitIndex, volume)
    g_client:getServerConnection():sendEvent(MakeFirewoodEvent:new(vehicle, fillUnitIndex, volume))
end
