require 'rivenmods-common-v0-1-0'



function getLocomotiveCount(train)
	local wagon_count = 0;
	for direction, locomotives in pairs(train.locomotives) do
		for idx, locomotive in ipairs(locomotives) do
			wagon_count = wagon_count + 1;
		end
	end
	return wagon_count;
end



function getCargoWagonCount(train)
	local wagon_count = 0;
	for idx, wagon in ipairs(train.cargo_wagons) do
		wagon_count = wagon_count + 1;
	end
	return wagon_count;
end



function getCargoWagonUsageRatio(train)
	local wagon_stack_count = game.entity_prototypes['cargo-wagon'].get_inventory_size(defines.inventory.cargo_wagon);
	local train_stack_used = 0.0;
	for itemName, amount in pairs(train.get_contents()) do
		train_stack_used = train_stack_used + amount / game.item_prototypes[itemName].stack_size;
	end
	return train_stack_used / wagon_stack_count;
end



function getFluidWagonCount(train)
	local wagon_count = 0;
	for idx, wagon in ipairs(train.fluid_wagons) do
		wagon_count = wagon_count + 1;
	end
	return wagon_count;
end



function getFluidWagonUsageRatio(train)
	local wagon_stack_count = game.entity_prototypes['fluid-wagon'].fluid_capacity;
	local train_stack_used = 0.0;
	for itemName, amount in pairs(train.get_fluid_contents()) do
		train_stack_used = train_stack_used + amount;
	end
	return train_stack_used / wagon_stack_count;
end



function getTrainMass(train)
	local total = 0.0;
	
	total = total + getLocomotiveCount(train)      * global.settings.locomotiveWeight;
	
	total = total + getCargoWagonCount(train)      * global.settings.cargoWagonWeight;
	total = total + getCargoWagonUsageRatio(train) * global.settings.cargoPayloadWeight;
	
	total = total + getFluidWagonCount(train)      * global.settings.fluidWagonWeight;
	total = total + getFluidWagonUsageRatio(train) * global.settings.fluidPayloadWeight;
	
	return total;
end



function getTrainForce(train)
	local trainSpeed    = getTrainSpeed(train);

	local pullingForce  = global.settings.locomotivePullforce * getLocomotiveCount(train);
	local totalForce    = pullingForce;
	
	local vehicleCount  = getLocomotiveCount(train) + getCargoWagonCount(train) + getFluidWagonCount(train);
	local wheelFriction = global.settings.trainWheelfrictionCoefficient * trainSpeed * vehicleCount;
	local airFriction   = global.settings.trainAirfrictionCoefficient   * math_pow2(trainSpeed);
	local totalFriction = wheelFriction + airFriction;

	return math.max(0.0, totalForce - totalFriction);
end



function adjustTrainAccleration(train)
	local currSpeed = getTrainSpeed(train);
	if not global.trainId2speed[train.id] then
		global.trainId2speed[train.id] = currSpeed;
		return
	end
	
	local prevSpeed = global.trainId2speed[train.id];
	local acceleration = (currSpeed - prevSpeed) * GAME_FRAMERATE;
	local didChange = 0;
	
	local trainForce = global.trainId2force[train.id];
	local trainMass  = global.trainId2mass[train.id];
	local maxAcceleration = trainForce / trainMass;
	
	if currSpeed > 0.1 and acceleration > maxAcceleration then
		acceleration = maxAcceleration;
		didChange = 1;
	end
	if currSpeed < -0.1 and acceleration < -maxAcceleration then
		acceleration = -maxAcceleration;
		didChange = 1;
	end
	
	if didChange == 1 then
		currSpeed = prevSpeed + acceleration;
		setTrainSpeed(train, currSpeed);
	end
	
	global.trainId2speed[train.id] = getTrainSpeed(train);
end



function addNiceSmokePuffsWhenDeparting(train)
	local trainSpeed = math.abs(getTrainSpeed(train));
	for direction, locomotives in pairs(train.locomotives) do
		for idx, locomotive in ipairs(locomotives) do
			locomotive.create_build_effect_smoke();
			
			if trainSpeed > 0.0 then
				local modulo = 0
				if trainSpeed < 2.5 then
					modulo = 0.50
				elseif trainSpeed < 5.0 then
					modulo = 0.25
				elseif trainSpeed < 10.0 then
					modulo = 0.15
				elseif trainSpeed < 25.0 then
					modulo = 0.10
				else
					modulo = 0.00
				end
				
				if global.rndm() < modulo then
					locomotive.surface.create_trivial_smoke({name='tank-smoke', position=locomotive.position})
				end
			end
		end
	end
end



function ensure_mod_context() 
	if not global.hasContext then
		global.hasContext = true;
		
		global.trainId2train = {}
		global.trainId2mass = {}
		global.trainId2force = {}
		global.trainId2speed = {}
	end
	
	if not global.rndm then
		global.rndm = game.create_random_generator()
		global.rndm.re_seed(1337);
	end
	
	if not global.settings then
		refresh_mod_settings();
	end
end



function refresh_mod_settings()
	game.print('trainspeeds.refresh_mod_settings');
	global.settings = {}
	global.settings.locomotivePullforce = settings.global["modtrainspeeds-locomotive-pullforce"].value;
	global.settings.locomotiveWeight = settings.global["modtrainspeeds-locomotive-weight"].value;
	global.settings.cargoWagonWeight = settings.global["modtrainspeeds-cargo-wagon-weight"].value;
	global.settings.cargoPayloadWeight = settings.global["modtrainspeeds-cargo-payload-weight"].value;
	global.settings.fluidWagonWeight = settings.global["modtrainspeeds-fluid-wagon-weight"].value;
	global.settings.fluidPayloadWeight = settings.global["modtrainspeeds-fluid-payload-weight"].value;
	global.settings.trainAirfrictionCoefficient = settings.global["modtrainspeeds-train-airfriction-coefficient"].value;
	global.settings.trainWheelfrictionCoefficient = settings.global["modtrainspeeds-train-wheelfriction-coefficient"].value;
	
	game.print('trainspeeds.trainWheelfrictionCoefficient: ' .. global.settings.trainWheelfrictionCoefficient);
end


 
script.on_event({defines.events.on_init},
	function (e) 
		refresh_mod_settings();
	end
)
script.on_event({defines.events.on_load},
	function (e) 
		refresh_mod_settings();
	end
)
script.on_event({defines.events.on_runtime_mod_setting_changed},
	function (e) 
		refresh_mod_settings();
	end
)



script.on_event({defines.events.on_tick},
	function (e)
		ensure_mod_context();
		
		local discoveryInterval = 120;
		local smokeInterval = 10;
		local adjustInterval = 1;
		
		if (e.tick % discoveryInterval == 0) then
			findTrains();
			
			for trainId, train in pairs(global.trainId2train) do
				if train.valid then
					global.trainId2mass[trainId]  = getTrainMass(train);
					global.trainId2force[trainId] = getTrainForce(train);
				end
			end
		end
		
		for trainId, train in pairs(global.trainId2train) do
			if train.valid then
				if train.state == defines.train_state.on_the_path or train.state == defines.train_state.manual_control then
					if (e.tick % smokeInterval == trainId % smokeInterval) then
						addNiceSmokePuffsWhenDeparting(train);
					end
					
					if (e.tick % adjustInterval == trainId % adjustInterval) then					
						adjustTrainAccleration(train);
					end
				end
			end
		end
	end
)
