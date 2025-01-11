local Config = lib.load('config')
local speakers = {}
local FrameworkCore = nil

if Config.framework == 'qb' then
    FrameworkCore = exports['qb-core']:GetCoreObject()
elseif Config.framework == 'esx' then
    FrameworkCore = exports.es_extended:getSharedObject()
end

MySQL.ready(function()
    MySQL.Async.fetchAll('SELECT * FROM `speakers`', {}, function(result)
        for _, v in pairs(result) do
            speakers[v.id] = { prop = Config.speakers[v.item], item = v.item, location = json.decode(v.location), users = json.decode(v.users) or {}, id = v.id, owner = v.owner }
        end
    end)
end)

local updateSpeakers = function()
    for _, v in pairs(GetPlayers()) do
        lib.callback.await('mt_speakers:client:updateSpeakers', v)
    end
end

---@param speakerId number
local updateSpeakersById = function(speakerId)
    for _, v in pairs(GetPlayers()) do
        lib.callback.await('mt_speakers:client:updateSpeakerById', v, speakerId, speakers[speakerId])
    end
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
    for _, v in pairs(GetPlayers()) do
        lib.callback.await('mt_speakers:client:deleteSpeaker', v, speakerId)
    end
end

lib.callback.register('mt_speakers:server:getUserAccess', function(source, speakerId)
    local src = source
    local Player = Config.framework == 'qb' and FrameworkCore?.Functions.GetPlayer(src) or Config.framework == 'esx' and FrameworkCore?.GetPlayerFromId(src) or exports.qbx_core:GetPlayer(src)
    local citizenid = Config.framework == 'esx' and Player.getIdentifier or Player.PlayerData.citizenid
    return getUserAccess(citizenid, speakerId)
end)

---@param source number
---@param speaker string
---@param coords any
---@param heading number
---@return boolean
lib.callback.register('mt_speakers:server:placeSpeaker', function(source, speaker, coords, heading)
    local src = source
    local Player = Config.framework == 'qb' and FrameworkCore?.Functions.GetPlayer(src) or Config.framework == 'esx' and FrameworkCore?.GetPlayerFromId(src) or exports.qbx_core:GetPlayer(src)
    coords = vec4(coords.x, coords.y, coords.z, heading)
    local citizenid = Config.framework == 'esx' and Player.getIdentifier or Player.PlayerData.citizenid
    MySQL.insert('INSERT INTO `speakers` (item, location, users, owner) VALUES (?, ?, ?, ?)', {
        speaker, json.encode(coords), json.encode({}), citizenid
    }, function(id)
        speakers[id] = { prop = Config.speakers[speaker], item = speaker, location = coords, users = {}, id = id, owner = citizenid }
        updateSpeakers()
    end)
    return true
end)

lib.callback.register('mt_speakers:server:getSpeakers', function()
    return speakers
end)

lib.callback.register('mt_speakers:server:deleteSpeaker', function(source, speakerId)
    MySQL.Async.execute('DELETE FROM `speakers` WHERE `id` = ?', { speakerId }, function()
        exports.xsound:Destroy(-1, 'speaker_'..speakerId)
        speakers[speakerId] = nil
        deleteSpeaker(speakerId)
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
    local Player = Config.framework == 'qb' and FrameworkCore?.Functions.GetPlayer(src) or Config.framework == 'esx' and FrameworkCore?.GetPlayerFromId(src) or exports.qbx_core:GetPlayer(src)
    local citizenid = Config.framework == 'esx' and Player.getIdentifier() or Player.PlayerData.citizenid
    return MySQL.query.await('SELECT * FROM `speakers_musics` WHERE `citizenid` = ?', { citizenid })
end)

lib.callback.register('mt_speakers:server:addMusic', function(source, data)
    local Player = Config.framework == 'qb' and FrameworkCore?.Functions.GetPlayer(src) or Config.framework == 'esx' and FrameworkCore?.GetPlayerFromId(src) or exports.qbx_core:GetPlayer(src)
    local citizenid = Config.framework == 'esx' and Player.getIdentifier() or Player.PlayerData.citizenid
    MySQL.insert('INSERT INTO `speakers_musics` (citizenid, label, url) VALUES (?, ?, ?)', { citizenid, data.label, data.url })
    return true
end)

lib.callback.register('mt_speakers:server:deleteMusic', function(source, id)
    MySQL.Async.execute('DELETE FROM `speakers_musics` WHERE `musicId` = ?', { id })
    return true
end)

lib.callback.register('mt_speakers:server:getCloseUsers', function(source, speakerId)
    local closePlayers = {}
    for _, v in pairs(GetPlayers()) do
        local Player = Config.framework == 'qb' and FrameworkCore?.Functions.GetPlayer(v) or Config.framework == 'esx' and FrameworkCore?.GetPlayerFromId(v) or exports.qbx_core:GetPlayer(v)
        if not Player then goto continue end
        local citizenid = Config.framework == 'esx' and Player.getIdentifier() or Player.PlayerData.citizenid
        if getUserAccess(citizenid, speakerId) then goto continue end
        closePlayers[#closePlayers+1] = { id = v, citizenid = citizenid, name = Config.framework == 'esx' and Player.getName() or  Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname }
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
    updateSpeakersById(speakerId)
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
    updateSpeakersById(speakerId)
    MySQL.update.await('UPDATE speakers SET `users` = ? WHERE id = ?', { json.encode(users), speakerId })
    return true
end)