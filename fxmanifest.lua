fx_version 'cerulean'
author 'Marttins'
description 'Simple speakers script for FiveM'
game 'gta5'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/*'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*'
}

ui_page 'web/build/index.html'

files {
    'locales/*',
    'web/build/**/*'
}