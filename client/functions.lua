function LookEntity(entity)
	if type(entity) == "vector3" then
		if not IsPedHeadingTowardsPosition(PlayerPedId(), entity, 30.0) then
			TaskTurnPedToFaceCoord(PlayerPedId(), entity, 1500)
			Wait(1500)
		end
	else
		if DoesEntityExist(entity) then
			if not IsPedHeadingTowardsPosition(PlayerPedId(), GetEntityCoords(entity), 30.0) then
				TaskTurnPedToFaceCoord(PlayerPedId(), GetEntityCoords(entity), 1500)
				Wait(1500)
			end
		end
	end
end

function LoadAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		RequestAnimDict(dict)
		Wait(5)
	end
end

function UnloadAnimDict(dict)
	RemoveAnimDict(dict)
end

function LoadModel(entity)
	while not HasModelLoaded(entity) do
		RequestModel(entity)
		Wait(5)
	end
end

function MakeProp(data, freeze, synced)
	LoadModel(data.prop)
	local prop = CreateObject(data.prop, data.coords.x, data.coords.y, data.coords.z, synced or 0, synced or 0, 0)
	SetEntityHeading(prop, data.coords.w)
	FreezeEntityPosition(prop, freeze or 0)
	return prop
end

function DestroyProp(entity)
	SetEntityAsMissionEntity(entity)
	Wait(5)
	DetachEntity(entity, true, true)
	Wait(5)
	DeleteEntity(entity)
end

function SetPed(model, coords, freeze, collision, scenario, anim)
	LoadModel(model)
	local ped = CreatePed(0, model, coords.x, coords.y, coords.z - 1.03, coords.w, false, false)
	SetEntityInvincible(ped, true)
	SetBlockingOfNonTemporaryEvents(ped, true)
	FreezeEntityPosition(ped, freeze or true)
	if collision then SetEntityNoCollisionEntity(ped, PlayerPedId(), false) end
	if scenario then TaskStartScenarioInPlace(ped, scenario, 0, true) end
	if anim then
		loadAnimDict(anim[1])
		TaskPlayAnim(ped, anim[1], anim[2], 1.0, 1.0, -1, 1, 0.2, 0, 0, 0)
	end
	return ped
end

function UnloadModel(entity)
	SetModelAsNoLongerNeeded(entity)
end
