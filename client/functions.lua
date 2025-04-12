local Config = lib.load('config')

---@param rotation number
---@return table
rotationToDirection = function(rotation)
	local adjustedRotation = { x = (math.pi / 180) * rotation.x, y = (math.pi / 180) * rotation.y, z = (math.pi / 180) * rotation.z }
	local direction = { x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), z = math.sin(adjustedRotation.x) }
	return direction
end

---@param distance number
---@return table
rayCastGamePlayCamera = function(distance)
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = rotationToDirection(cameraRotation)
	local destination = { x = cameraCoord.x + direction.x * distance, y = cameraCoord.y + direction.y * distance, z = cameraCoord.z + direction.z * distance }
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, cache.ped, 0))
	return destination
end

---@param text string
textUI = function(text)
    lib.showTextUI(text)
end

hideTextUI = function()
    lib.hideTextUI()
end

---@param message string
---@param type string
notify = function(message, type)
    lib.notify({ description = message, type = type })
end

---@param entity integer
---@param options table
---@param distance number
---@param name string
---@return unknown
createEntityTarget = function(entity, options, distance, name)
    if Config.target == 'ox_target' then
        return exports.ox_target:addLocalEntity(entity, options)
    elseif Config.target == 'interact' then
        return exports.interact:AddLocalEntityInteraction({ entity = entity, name = name, id = name, distance = 1.0, interactDst = 1.0, options = options })
    else
        return exports[Config.target]:AddTargetEntity(entity, { name = name, options = options, distance = distance })
    end
end

---@param item string
---@return string
itemName = function(item)
    return exports.ox_inventory:Items()[item].label
end