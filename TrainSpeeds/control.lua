local GAME_FRAMERATE = 60.0;

function math_sign(x)
   if x < 0 then
     return -1
   elseif x > 0 then
     return 1
   else
     return 0
   end
end

function math_pow2(x)
	return x * x
end


function getTrainSpeed(train)
	return train.speed * GAME_FRAMERATE * 3.6;
end

function setTrainSpeed(train, speed)
	train.speed = speed / GAME_FRAMERATE / 3.6;
end



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



function findTrains()
	global.modtrainspeeds.trainId2train = {}
	for _idx1_, surface in pairs(game.surfaces) do
		for _idx2_, train in pairs(surface.get_trains()) do
			global.modtrainspeeds.trainId2train[train.id] = train;
			global.modtrainspeeds.trainId2mass[train.id]  = getTrainMass(train);
			global.modtrainspeeds.trainId2force[train.id] = getTrainForce(train);
		end
	end
end



function ensure_mod_context() 
	if not global.modtrainspeeds then
		global.modtrainspeeds = {}
		global.modtrainspeeds.trainId2train = {}
		global.modtrainspeeds.trainId2mass = {}
		global.modtrainspeeds.trainId2force = {}
		global.modtrainspeeds.trainId2speed = {}
	end
	
	if not global.modtrainspeeds.rndm then
		global.modtrainspeeds.rndm = game.create_random_generator()
		global.modtrainspeeds.rndm.re_seed(1337);
	end
end



function getTrainMass(train)
	local total = 0.0;
	
	total = total + getLocomotiveCount(train)      * settings.global["modtrainspeeds-locomotive-weight"].value;
	
	total = total + getCargoWagonCount(train)      * settings.global["modtrainspeeds-cargo-wagon-weight"].value;
	total = total + getCargoWagonUsageRatio(train) * settings.global["modtrainspeeds-cargo-payload-weight"].value;
	
	total = total + getFluidWagonCount(train)      * settings.global["modtrainspeeds-fluid-wagon-weight"].value;
	total = total + getFluidWagonUsageRatio(train) * settings.global["modtrainspeeds-fluid-payload-weight"].value;
	
	return total;
end



function getTrainForce(train)
	local trainSpeed    = getTrainSpeed(train);

	local pullingForce  = settings.global["modtrainspeeds-locomotive-pullforce"].value * getLocomotiveCount(train);
	local totalForce    = pullingForce;
	
	local vehicleCount  = getLocomotiveCount(train) + getCargoWagonCount(train) + getFluidWagonCount(train);
	local wheelFriction = settings.global["modtrainspeeds-train-wheelfriction-coefficient"].value * trainSpeed * vehicleCount;
	local airFriction   = settings.global["modtrainspeeds-train-airfriction-coefficient"].value   * math_pow2(trainSpeed);
	local totalFriction = wheelFriction + airFriction;

	return math.max(0.0, totalForce - totalFriction);
end



function adjustTrainAccleration(train)
	local currSpeed = getTrainSpeed(train);
	if not global.modtrainspeeds.trainId2speed[train.id] then
		global.modtrainspeeds.trainId2speed[train.id] = currSpeed;
		return
	end
	
	local prevSpeed = global.modtrainspeeds.trainId2speed[train.id];
	local acceleration = (currSpeed - prevSpeed) * GAME_FRAMERATE;
	local didChange = 0;
	
	local trainForce = global.modtrainspeeds.trainId2force[train.id];
	local trainMass  = global.modtrainspeeds.trainId2mass[train.id];
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
	
	global.modtrainspeeds.trainId2speed[train.id] = getTrainSpeed(train);
end



function addNiceSmokePuffsWhenDeparting(train, smokeInterval, tickCount)
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
				
				if global.modtrainspeeds.rndm() < modulo then
					locomotive.surface.create_trivial_smoke({name='tank-smoke', position=locomotive.position})
				end
			end
		end
	end
end



script.on_event({defines.events.on_tick},
	function (e)
		ensure_mod_context();
		
		local discoveryInterval = 120;
		local smokeInterval = 10;
		local adjustInterval = 1;
		
		if (e.tick % discoveryInterval == 0) then
			findTrains();
			
			for trainId, train in pairs(global.modtrainspeeds.trainId2train) do
				if train.valid then
					global.modtrainspeeds.trainId2mass[trainId]  = getTrainMass(train);
					global.modtrainspeeds.trainId2force[trainId] = getTrainForce(train);
				end
			end
		end
		
		for trainId, train in pairs(global.modtrainspeeds.trainId2train) do
			if train.valid then
				if train.state == defines.train_state.on_the_path or train.state == defines.train_state.manual_control then
					if (e.tick % smokeInterval == trainId % smokeInterval) then
						addNiceSmokePuffsWhenDeparting(train, smokeInterval, e.tick);
					end
					
					if (e.tick % adjustInterval == trainId % adjustInterval) then					
						adjustTrainAccleration(train);
					end
				end
			end
		end
	end
)
