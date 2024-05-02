fx_version 'cerulean'
game 'gta5'

name "cfx-tcd-starterpack"
description "A Advanced Starter Pack System for QBCore and ESX Framework"
author "Teezy Core Development"
version "1.3.0"

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua'
}

client_scripts {
	'core.lua',
	'client/*.lua'
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	'core.lua',
	'server/*.lua'
}

escrow_ignore {
	'config.lua',
	'core.lua',
	'client/*.lua',
	'server/*.lua'
}

dependencies {
	'ox_lib',
}

lua54 'yes'