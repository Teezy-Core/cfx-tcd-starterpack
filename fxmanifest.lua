fx_version 'cerulean'
game 'gta5'

name "cfx-tcd-starterpack"
description "A Advanced Starter Pack System for QBCore, ESX, and QBOX Frameworks"
author "Teezy Core Development"
version "2.2.0"

shared_scripts {
	'@ox_lib/init.lua',
	'shared/*.lua',
	'config.lua'
}

client_scripts {
	'client/**/*.lua',
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'server/**/*.lua',
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