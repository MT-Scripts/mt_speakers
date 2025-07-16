local Config = lib.load('config')
local speakers = {}
local pickupStatus = {}

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        pickupStatus = {}
    end
end)

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM `speakers`', {}, function(result)
        for _, v in pairs(result) do
            speakers[v.id] = { prop = Config.speakers[v.item], item = v.item, location = json.decode(v.location), users = json.decode(v.users) or {}, id = v.id, owner = v.owner }
        end
    end)
end)

local updateSpeakers = function()
    TriggerClientEvent('mt_speakers:client:updateSpeakers', -1)
end

---@param speakerId number
local updateSpeakersById = function(speakerId)
    local speakerData = {
        item = speakers[speakerId].item,
        location = speakers[speakerId].location,
        users = speakers[speakerId].users,
        id = speakers[speakerId].id,
        owner = speakers[speakerId].owner
        --exclude 'prop' as it's client-side only
    }
    TriggerClientEvent('mt_speakers:client:updateSpeakerById', -1, speakerId, speakerData)
end

local updateSpeakerUsers = function(speakerId)
    TriggerClientEvent('mt_speakers:client:updateSpeakerUsers', -1, speakerId, speakers[speakerId].users)
end

---@param citizenid string
---@param speakerId number
---@return boolean
local getUserAccess = function(citizenid, speakerId)
    local userExists = false
    if not speakers[speakerId] then return false end
    if speakers[speakerId].owner == citizenid then return true end
    for _, uv in pairs(speakers[speakerId].users) do
        if (uv.citizenid == citizenid) then userExists = true break end
    end
    return userExists
end

---@param speakerId number
local deleteSpeaker = function(speakerId)
    TriggerClientEvent('mt_speakers:client:deleteSpeaker', -1, speakerId)
end

local pickupStatus = {}

---@param speakerId number
---@return boolean
function canPickup(speakerId)
    if pickupStatus[speakerId] then
        return false
    end
    pickupStatus[speakerId] = true
    return true
end

---@param speakerId number
function releasePickup(speakerId)
    pickupStatus[speakerId] = false
end

lib.callback.register('mt_speakers:server:getUserAccess', function(source, speakerId)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    return getUserAccess(citizenid, speakerId)
end)

---@param source number
---@param speaker string
---@param coords any
---@param heading number
---@return boolean
lib.callback.register('mt_speakers:server:placeSpeaker', function(source, speaker, coords, heading)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    coords = vec4(coords.x, coords.y, coords.z, heading)
    MySQL.insert('INSERT INTO `speakers` (item, location, users, owner) VALUES (?, ?, ?, ?)', {
        speaker, json.encode(coords), json.encode({}), Player.PlayerData.citizenid
    }, function(id)
        speakers[id] = { prop = Config.speakers[speaker], item = speaker, location = coords, users = {}, id = id, owner = Player.PlayerData.citizenid }
        updateSpeakers()
    end)
    return true
end)

lib.callback.register('mt_speakers:server:getSpeakers', function()
    return speakers
end)

lib.callback.register('mt_speakers:server:deleteSpeaker', function(source, speakerId)
    if not speakers[speakerId] then
        return false, 'Speaker não encontrado.'
    end

    if not canPickup(speakerId) then
        return false, 'Alguém já está pegando esse speaker.'
    end

    exports.xsound:Destroy(-1, 'speaker_'..speakerId)

    MySQL.Async.execute('DELETE FROM `speakers` WHERE `id` = ?', { speakerId }, function(rowsChanged)
        if rowsChanged > 0 then
            speakers[speakerId] = nil
            deleteSpeaker(speakerId)
        end
        releasePickup(speakerId)
    end)

    return true
end)

lib.callback.register('mt_speakers:server:songActions', function(source, data)
    if data.action == 'update' then
        exports.xsound:setVolume(-1, 'speaker_'..data.speakerId, (data.volume / 100))
        exports.xsound:Distance(-1, 'speaker_'..data.speakerId, data.distance)
    elseif data.action == 'resume' then
        exports.xsound:Resume(-1, 'speaker_'..data.speakerId)
    elseif data.action == 'pause' then
        exports.xsound:Pause(-1, 'speaker_'..data.speakerId)
    else
        local coords = speakers[data.speakerId].location
        exports.xsound:PlayUrlPos(-1, 'speaker_'..data.speakerId, data.url, (Config.speakers[speakers[data.speakerId].item].maxVol / 200), vec3(coords.x, coords.y, coords.z), false)
        exports.xsound:Distance(-1, 'speaker_'..data.speakerId, (Config.speakers[speakers[data.speakerId].item].maxDist / 2))
    end
    return data.speakerId, speakers[data.speakerId].item
end)

lib.callback.register('mt_speakers:server:getPlayerMusics', function(source)
    local Player = exports.qbx_core:GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    return MySQL.query.await('SELECT * FROM `speakers_musics` WHERE `citizenid` = ?', { citizenid })
end)

lib.callback.register('mt_speakers:server:addMusic', function(source, data)
    local Player = exports.qbx_core:GetPlayer(source)
    local citizenid = Player.PlayerData.citizenid
    MySQL.insert('INSERT INTO `speakers_musics` (citizenid, label, url) VALUES (?, ?, ?)', { citizenid, data.label, data.url })
    return true
end)

lib.callback.register('mt_speakers:server:deleteMusic', function(source, id)
    MySQL.Async.execute('DELETE FROM `speakers_musics` WHERE `musicId` = ?', { id })
    return true
end)

lib.callback.register('mt_speakers:server:getCloseUsers', function(source, speakerId)
    local closePlayers = {}
    for _, v in pairs(exports.qbx_core:GetQBPlayers()) do
        if not v then goto continue end
        if getUserAccess(v.PlayerData.citizenid, speakerId) then goto continue end
        closePlayers[#closePlayers+1] = { id = v.PlayerData.source, citizenid = v.PlayerData.citizenid, name = v.PlayerData.charinfo.firstname..' '..v.PlayerData.charinfo.lastname }
        :: continue ::
    end
    return closePlayers
end)

lib.callback.register('mt_speakers:server:addAccess', function(source, user, speakerId)
    local users = MySQL.query.await('SELECT users FROM `speakers` WHERE `id` = ?', { speakerId })
    users = json.decode(users[1].users)
    if not users then users = {} end
    users[#users+1] = user
    speakers[speakerId].users = users
    updateSpeakerUsers(speakerId) -- Use specific update instead of full sync
    MySQL.update.await('UPDATE speakers SET `users` = ? WHERE id = ?', { json.encode(users), speakerId })
    return true
end)

lib.callback.register('mt_speakers:server:removeAccess', function(source, user, speakerId)
    local users = MySQL.query.await('SELECT users FROM `speakers` WHERE `id` = ?', { speakerId })
    users = json.decode(users[1].users)
    if not users then users = {} end
    for uk, uv in pairs(users) do
        if uv.citizenid == user.citizenid then users[uk] = nil end
    end
    speakers[speakerId].users = users
    updateSpeakerUsers(speakerId) -- Use specific update instead of full sync
    MySQL.update.await('UPDATE speakers SET `users` = ? WHERE id = ?', { json.encode(users), speakerId })
    return true
end)

lib.callback.register('mt_speakers:server:itemActions', function(source, speaker, action)
    local src = source

    local isSpeakerItem = false
    for item, _ in pairs(Config.speakers) do
        if item == speaker then
            isSpeakerItem = true
            break
        end
    end
    if not isSpeakerItem then return end

    if action == 'remove' then
        exports.ox_inventory:RemoveItem(src, speaker, 1)
    else
        exports.ox_inventory:AddItem(src, speaker, 1)
    end
end)