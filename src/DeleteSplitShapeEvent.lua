--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 09/01/2021

DeleteSplitShapeEvent = {}
DeleteSplitShapeEvent_mt = Class(DeleteSplitShapeEvent, Event)

InitEventClass(DeleteSplitShapeEvent, "DeleteSplitShapeEvent")

function DeleteSplitShapeEvent:emptyNew()
    local e = Event:new(DeleteSplitShapeEvent_mt)
    return e
end

function DeleteSplitShapeEvent:new(splitShapeId)
    local e = DeleteSplitShapeEvent:emptyNew()
    e.splitShapeId = splitShapeId
    return e
end

function DeleteSplitShapeEvent:writeStream(streamId, connection)
    writeSplitShapeIdToStream(streamId, self.splitShapeId)
end

function DeleteSplitShapeEvent:readStream(streamId, connection)
    self.splitShapeId = readSplitShapeIdFromStream(streamId)
    self:run(connection)
end

function DeleteSplitShapeEvent:run(connection)
    if self.splitShapeId ~= 0 then
        delete(self.splitShapeId)
    end
end

function DeleteSplitShapeEvent.sendEvent(splitShapeId)
    g_client:getServerConnection():sendEvent(DeleteSplitShapeEvent:new(splitShapeId))
end
