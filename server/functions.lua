local Config = lib.load('config')

lib.callback.register('mt_speakers:server:itemActions', function(source, speaker, action)
    local src = source
    if action == 'remove' then
        exports.ox_inventory:RemoveItem(src, speaker, 1)
    else
        exports.ox_inventory:AddItem(src, speaker, 1)
    end
end)