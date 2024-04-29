fx_version 'cerulean'
game 'gta5'

name "cfx-tcd-starterpack"
description "A Advanced Starter Pack for New Players"
author "Teezy Core Development"
version "1.0.0"

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

lua54 'yes'