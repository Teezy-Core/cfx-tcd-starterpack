fx_version 'cerulean'
game 'gta5'
use_experimental_fxv2_oal 'yes'

name "cfx-tcd-starterpackrework"
description "A Advanced Starter Pack System for QBCore, ESX, and QBOX Frameworks"
author "Teezy Core Development"
version "2.2.3"

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
	'shared/core.lua',
}

client_scripts {
	'client/main.lua',
	'client/functions/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/main.lua',
	'server/functions/sql.lua',
	'server/functions/*.lua',
}

files {
	'locales/*.json',
}

escrow_ignore {
	'locales/*.json',
	'config.lua',
	'shared/*.lua',
	'client/**/*.lua',
	'server/**/*.lua',
}

dependencies {
	'ox_lib',
}

lua54 'yes'