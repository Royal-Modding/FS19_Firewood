--
-- ${title}
--
-- @author ${author}
-- @version ${version}
-- @date 09/01/2021

InitRoyalMod(Utils.getFilename("lib/rmod/", g_currentModDirectory))
InitRoyalUtility(Utils.getFilename("lib/utility/", g_currentModDirectory))


Firewood = RoyalMod.new(r_debug_r, false)

function Firewood:initialize()
end

function Firewood:onValidateVehicleTypes(vehicleTypeManager, addSpecialization, addSpecializationBySpecialization, addSpecializationByVehicleType, addSpecializationByFunction)
    -- @param specName string name of the spec to add
    --addSpecialization("specName")

    -- @param specName string name of the spec to add
    -- @param requiredSpecName string name of the required spec
    --addSpecializationBySpecialization("specName", "requiredSpecName")

    -- @param specName string name of the spec to add
    -- @param requiredVehicleTypeName string name of the required vehicle type
    --addSpecializationByVehicleType("specName", "requiredVehicleTypeName")

    -- @param specName string name of the spec to add
    -- @param function function if return true spec will be added to the current vehicle type
    --addSpecializationByFunction("specName", function(vehicleType) return false end)
end

function Firewood:onMissionInitialize(baseDirectory, missionCollaborators)
end

function Firewood:onSetMissionInfo(missionInfo, missionDynamicInfo)
end

function Firewood:onLoad()
end

function Firewood:onPreLoadMap(mapFile)
end

function Firewood:onCreateStartPoint(startPointNode)
end

function Firewood:onLoadMap(mapNode, mapFile)
end

function Firewood:onPostLoadMap(mapNode, mapFile)
end

function Firewood:onLoadSavegame(savegameDirectory, savegameIndex)
end

function Firewood:onPreLoadVehicles(xmlFile, resetVehicles)
end

function Firewood:onPreLoadItems(xmlFile)
end

function Firewood:onPreLoadOnCreateLoadedObjects(xmlFile)
end

function Firewood:onLoadFinished()
end

function Firewood:onStartMission()
end

function Firewood:onMissionStarted()
end

function Firewood:onWriteStream(streamId)
end

function Firewood:onReadStream(streamId)
end

function Firewood:onUpdate(dt)
end

function Firewood:onUpdateTick(dt)
end

function Firewood:onWriteUpdateStream(streamId, connection, dirtyMask)
end

function Firewood:onReadUpdateStream(streamId, timestamp, connection)
end

function Firewood:onMouseEvent(posX, posY, isDown, isUp, button)
end

function Firewood:onKeyEvent(unicode, sym, modifier, isDown)
end

function Firewood:onDraw()
end

function Firewood:onPreSaveSavegame(savegameDirectory, savegameIndex)
end

function Firewood:onPostSaveSavegame(savegameDirectory, savegameIndex)
end

function Firewood:onPreDeleteMap()
end

function Firewood:onDeleteMap()
end
