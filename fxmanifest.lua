fx_version 'cerulean'
game 'gta5'
author 'pScripts [tebex.pscripts.store]'
lua54 'yes'
description 'pScripts - Official Bridge'
version '1.0.7'

client_scripts {
    'client/main.lua',
    'client/utils.lua',
    'client/cache.lua',
    'client/marker.lua',
    'client/setup.lua',
    'client/appearance/*.lua',
    'client/carkeys/*.lua',
    'client/framework/*.lua',
    'client/inventory/*.lua',
    'client/notify/*.lua',
    'client/progress/*.lua',
    'client/target/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/debug.lua',
    'server/logs.lua',
    'server/framework/*.lua',
    'server/inventory/*.lua',
    'server/dispatch/*.lua',
    'server/notify/*.lua',
}

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua'
}