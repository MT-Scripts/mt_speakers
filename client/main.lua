local Config = lib.load('config')
lib.locale()
local clSpeakers = {}

---@param data any
---@param item any
local useSpeaker = function(data, item)
    textUI(locale('textui_place'))
    Player(cache.serverId).state:set('speakerInteracting', true, true)
    lib.callback.await('mt_speakers:server:itemActions', false, item.name, 'remove')
    local prop = CreateObject(GetHashKey(Config.speakers[item.name].prop), 0, 0, 0, false, false, false)
    local heading = GetEntityHeading(prop)
    SetEntityAlpha(prop, 150, false)
    SetEntityCollision(prop, false, false)
    SetEntityDrawOutline(prop, true)
    SetEntityDrawOutlineColor(prop, 255, 255, 255)

    CreateThread(function()
        local distance = 3.0
        while true do
            Wait(0)
            local coords = rayCastGamePlayCamera(distance)
            SetEntityCoords(prop, coords.x, coords.y, coords.z, heading, false, false, false)
            PlaceObjectOnGroundProperly(prop)
            SetEntityHeading(prop, heading)

            if IsControlPressed(0, 21) then
                if IsControlJustPressed(0, 15) then
                    if distance < 10.0 then distance += 0.2 end
                elseif IsControlJustPressed(0, 14) then
                    if distance > 0.0 then distance -= 0.2 end
                end
            else
                if IsControlPressed(0, 15) then
                    heading += 1.0
                elseif IsControlPressed(0, 14) then
                    heading -= 1.0
                end
            end

            if IsControlJustPressed(0, 176) then
                DeleteObject(prop)
                DeleteEntity(prop)
                hideTextUI()
                lib.callback.await('mt_speakers:server:placeSpeaker', false, item.name, coords, heading)
                break
            elseif IsControlJustPressed(0, 177) then
                DeleteObject(prop)
                DeleteEntity(prop)
                hideTextUI()
                lib.callback.await('mt_speakers:server:itemActions', false, item.name, 'add')
                break
            end
        end
    end)
    Player(cache.serverId).state:set('speakerInteracting', false, true)
end
exports("useSpeaker", useSpeaker)
lib.callback.register("useSpeaker", useSpeaker)

---@param speaker string
---@param speakerId number
local updateSpeakerSettings = function(speaker, speakerId)
    SendNUIMessage({
        action = 'setSpeakerSettings',
        data = {
            speakerId = speakerId,
            speakerName = itemName(speaker) .. ' ' .. speakerId,
            maxVolume = Config.speakers[speaker].maxVol,
            maxDistance = Config.speakers[speaker].maxDist,
            musicPlaying = exports.xsound:soundExists('speaker_'..speakerId) or false,
            volume = exports.xsound:soundExists('speaker_'..speakerId) and (exports.xsound:getInfo('speaker_'..speakerId).volume * 100) or 0,
            distance = exports.xsound:soundExists('speaker_'..speakerId) and exports.xsound:getInfo('speaker_'..speakerId).distance or 0,
            isPaused = exports.xsound:soundExists('speaker_'..speakerId) and exports.xsound:getInfo('speaker_'..speakerId).paused or false,
            locales = json.decode(LoadResourceFile(cache.resource, ('locales/%s.json'):format(Config.locale or 'en')))
        }
    })
end

---@param coords vector
---@param distance number
---@return table
local getPlayersFromCoords = function(coords, distance)
    coords = type(coords) == 'table' and vec3(coords.x, coords.y, coords.z) or coords or GetEntityCoords(cache.ped)
    local players = lib.getNearbyPlayers(coords, distance or 5, true)
    for i = 1, #players do players[i] = players[i].id end
    return players
end

---@param speakerId number
local updateSpeakerAccesses = function(speakerId)
    local closePlayers = lib.callback.await('mt_speakers:server:getCloseUsers', false, speakerId)

    for _, v in pairs(getPlayersFromCoords(GetEntityCoords(cache.ped), 100.0)) do
        local dist = #(GetEntityCoords(GetPlayerPed(v)) - GetEntityCoords(cache.ped))
        for i = 1, #closePlayers do
            if (not closePlayers[i].id == GetPlayerServerId(v)) then closePlayers[i] = nil end
        end
    end

    SendNUIMessage({
        action = 'setSpeakerAccesses',
        data = {
            users = clSpeakers[speakerId].users,
            close = closePlayers
        }
    })
end

local updateSpeakerMusics = function()
    local musics = lib.callback.await('mt_speakers:server:getPlayerMusics')
    SendNUIMessage({ action = 'setSpeakersSongs', data = musics })
end

---@param speaker string
---@param speakerId number
local openSpeakerUI = function(speaker, speakerId)
    updateSpeakerSettings(speaker, speakerId)
    updateSpeakerMusics()
    updateSpeakerAccesses(speakerId)
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'setVisibleSpeakersMenu', data = true })
end

---@param speakerId number
local deleteSpeaker = function(speakerId)
    Player(cache.serverId).state:set('speakerInteracting', true, true)
    lib.callback.await('mt_speakers:server:deleteSpeaker', false, speakerId)
    lib.callback.await('mt_speakers:server:itemActions', false, clSpeakers[speakerId].item, 'add')
    Player(cache.serverId).state:set('speakerInteracting', false, true)
end

local spawnAllSpeakers = function()
    local speakers = lib.callback.await('mt_speakers:server:getSpeakers')
    for _, v in pairs(speakers) do
        if clSpeakers[v.id] then goto continue end
        local prop = CreateObject(GetHashKey(Config.speakers[v.item].prop), v.location.x, v.location.y, v.location.z, false, false, false)
        SetEntityHeading(prop, v.location.w)
        PlaceObjectOnGroundProperly(prop)
        Wait(200)
        FreezeEntityPosition(prop, true)
        createEntityTarget(prop, {
            {
                label = locale('target_interact'),
                icon = 'fas fa-music',
                onSelect = function()
                    openSpeakerUI(v.item, v.id)
                end,
                canInteract = function()
                    return lib.callback.await('mt_speakers:server:getUserAccess', false, v.id)
                end
            },
            {
                label = locale('target_pickup'),
                icon = 'fas fa-hand-paper',
                onSelect = function()
                    deleteSpeaker(v.id)
                end,
                canInteract = function()
                    return lib.callback.await('mt_speakers:server:getUserAccess', false, v.id)
                end
            }
        }, 2.5, 'speaker_' .. v.id)
        clSpeakers[v.id] = { prop = prop, item = v.item, location = v.location, users = v.users }
        :: continue ::
    end
end

local despawnAllSpeakers = function()
    for _, v in pairs(clSpeakers) do
        DeleteObject(v.prop)
        DeleteEntity(v.prop)
    end
    clSpeakers = {}
end

lib.callback.register('mt_speakers:client:updateSpeakerById', function(speakerId, speaker)
    clSpeakers[speakerId] = speaker
    return true
end)

lib.callback.register('mt_speakers:client:deleteSpeaker', function(speakerId)
    if clSpeakers[speakerId] then
        DeleteObject(clSpeakers[speakerId].prop)
        DeleteEntity(clSpeakers[speakerId].prop)
        clSpeakers[speakerId] = nil
    end
end)

lib.callback.register('mt_speakers:client:updateSpeakers', function()
    spawnAllSpeakers()
end)

RegisterNuiCallback('hideFrame', function(data, cb)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'setVisible' .. data.name, data = false })
    SendNUIMessage({ action = 'resetSpeakerSettings' })
    cb(true)
end)

RegisterNuiCallback('songActions', function(data, cb)
    local id, item = lib.callback.await('mt_speakers:server:songActions', false, data)
    updateSpeakerSettings(item, id)
    cb(true)
end)

RegisterNuiCallback('addMusic', function(data, cb)
    lib.callback.await('mt_speakers:server:addMusic', false, data)
    updateSpeakerMusics()
    cb(true)
end)

RegisterNuiCallback('deleteMusic', function(data, cb)
    lib.callback.await('mt_speakers:server:deleteMusic', false, data.musicId)
    updateSpeakerMusics()
    cb(true)
end)

RegisterNuiCallback('addAccess', function(data, cb)
    lib.callback.await('mt_speakers:server:addAccess', false, data.user, data.speakerId)
    updateSpeakerAccesses(data.speakerId)
    cb(true)
end)

RegisterNuiCallback('removeAccess', function(data, cb)
    lib.callback.await('mt_speakers:server:removeAccess', false, data.user, data.speakerId)
    updateSpeakerAccesses(data.speakerId)
    cb(true)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(500)
    spawnAllSpeakers()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    despawnAllSpeakers()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    Wait(500)
    spawnAllSpeakers()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    despawnAllSpeakers()
end)