require 'rivenmods-common-v0-1-1'







function getCargoWagonCapacity()
	return game.entity_prototypes['cargo-wagon'].get_inventory_size(defines.inventory.cargo_wagon);
end

function getFluidWagonCapacity()
	return game.entity_prototypes['fluid-wagon'].fluid_capacity;
end



function getLocomotiveWeight()
	return game.entity_prototypes['locomotive'].weight;
end

function getCargoWagonWeight()
	return game.entity_prototypes['cargo-wagon'].weight;
end

function getFluidWagonWeight()
	return game.entity_prototypes['fluid-wagon'].weight;
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

function getFluidWagonCount(train)
	local wagon_count = 0;
	for idx, wagon in ipairs(train.fluid_wagons) do
		wagon_count = wagon_count + 1;
	end
	return wagon_count;
end



function getTrainCargoStackUsage(train)
	local train_stack_used = 0.0;
	for itemName, amount in pairs(train.get_contents()) do
		train_stack_used = train_stack_used + amount / game.item_prototypes[itemName].stack_size;
	end
	return train_stack_used;
end

function getTrainFluidWagonUsage(train)
	local train_stack_used = 0.0;
	for itemName, amount in pairs(train.get_fluid_contents()) do
		train_stack_used = train_stack_used + amount;
	end
	return train_stack_used;
end



function getTrainMass(train)
	local emptyWeight = 0.0;
	emptyWeight = emptyWeight + getLocomotiveCount(train) * getLocomotiveWeight();
	emptyWeight = emptyWeight + getCargoWagonCount(train) * getCargoWagonWeight();
	emptyWeight = emptyWeight + getFluidWagonCount(train) * getFluidWagonWeight();
	
	local cargoWeight = 0.0;
	cargoWeight = cargoWeight + getTrainCargoStackUsage(train) * global.settings.cargoStackWeight; -- default 250: 40 stacks  --> 10K kg
	cargoWeight = cargoWeight + getTrainFluidWagonUsage(train) * global.settings.fluidLiterWeight; -- default 0.4: 25K liters --> 10K kg
	
	
	local total = emptyWeight + cargoWeight;	
	--game.print('--- train id: ' .. train.id);
	--game.print('train weight: ' .. emptyWeight);
	--game.print('cargo weight: ' .. getTrainCargoStackUsage(train));
	--game.print('fluid weight: ' .. getTrainFluidWagonUsage(train));
	
	return total;
end



function isTrainActuallyCargoShipInstead(train) 
	for direction, locomotives in pairs(train.locomotives) do
		for idx, locomotive in ipairs(locomotives) do
			if locomotive.name == 'cargo_ship_engine' or locomotive.name == 'boat_engine' then
				return true
			end
		end
	end
	
	return false
end



function isTrainActuallyPoweredElectrically(train)
	for direction, locomotives in pairs(train.locomotives) do
		for idx, locomotive in ipairs(locomotives) do
			if locomotive.prototype.name == 'bet-locomotive' then
				return true
			end
		end
	end
	
	return false
end



function getLocomotiveFuelForceMultiplier(train)
	-- wood: 2M            --> 0.30
	-- coal: 4M            --> 0.60
	-- solid fuel: 12M     --> 1.08
	-- rocket fuel: 100M   --> 2.00
	-- nuclear: 1210M      --> 3.08

	local fuel_value = 0;
	for direction, locomotives in pairs(train.locomotives) do
		for idx, locomotive in ipairs(locomotives) do
			local burning_item = locomotive.burner.currently_burning
			if burning_item ~= nil then
				fuel_value = fuel_value + math.log(burning_item.fuel_value / 1000000) / math.log(10);
			end
		end
	end
	return fuel_value;
end



function getTrainPullingForce(train)
	local absTrainSpeed = math.abs(getTrainSpeed(train));
	
	local pullingForce = global.settings.locomotivePullforce;
	
	if isTrainActuallyPoweredElectrically(train) then
		-- low speed, high torque
		-- high speed, low torque
		local forceMultiplier = 1.25;
		local lowSpeedLimit = 33;
		local lowSpeedBonus = math.max(0, lowSpeedLimit - absTrainSpeed) / lowSpeedLimit;
		pullingForce = pullingForce * ((forceMultiplier - 1.0) + lowSpeedBonus);
	end	
	
	if global.settings.fuelTypeBasedAcceleration then
		pullingForce = pullingForce * getLocomotiveFuelForceMultiplier(train);
	else
		pullingForce = pullingForce * getLocomotiveCount(train);
	end
	
	return pullingForce
end



function getTrainFrictionForce(train)
	local absTrainSpeed = math.abs(getTrainSpeed(train));
	
	local totalFriction = 0.0;
	
	if isTrainActuallyCargoShipInstead(train) then
		local dragFriction  = global.settings.trainWheelfrictionCoefficient  * (25 + absTrainSpeed);
		local waterFriction = global.settings.shipWaterfrictionCoefficient   * math_pow2(absTrainSpeed);
		
		totalFriction = dragFriction + waterFriction;
	else
		local vehicleCount  = getLocomotiveCount(train) + getCargoWagonCount(train) + getFluidWagonCount(train);
		local wheelFriction = global.settings.trainWheelfrictionCoefficient * absTrainSpeed * vehicleCount;
		local airFriction   = global.settings.trainAirfrictionCoefficient   * math_pow2(absTrainSpeed);
		
		totalFriction = wheelFriction + airFriction;
	end
	
	return totalFriction;
end


function isTrainDebugLogged(train)
	return false -- train.id >= 1269
end



function getTrainForce(train)
	local pullingForce  = getTrainPullingForce(train);		
	local totalFriction = getTrainFrictionForce(train);

	if isTrainDebugLogged(train) then
		game.print('train pulling: ' .. string.format("%.2f", pullingForce));
		game.print('train friction: ' .. string.format("%.2f", totalFriction));
	end

	return math.max(0.0, pullingForce - totalFriction);
end



function adjustTrainAccleration(train)
	local currSpeed = getTrainSpeed(train);
	if not global.trainId2speed[train.id] then
		global.trainId2speed[train.id] = currSpeed;
		return
	end
	
	local prevSpeed = global.trainId2speed[train.id];
	local acceleration = (currSpeed - prevSpeed) * GAME_FRAMERATE;
	local origAcceleration = acceleration;
	local didChange = 0;
	
	if global.trainId2force[train.id] == nil then
		global.trainId2force[train.id] = getTrainForce(train);
	end
	
	if global.trainId2mass[train.id] == nil then
		global.trainId2mass[train.id] = getTrainMass(train);
	end
	
	
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
	
	if isTrainDebugLogged(train) then
		game.print('train acceleration: change=' .. didChange .. ' -> '
		   .. string.format("%.2f", acceleration*GAME_FRAMERATE) .. '/'
		   .. string.format("%.2f", maxAcceleration*GAME_FRAMERATE) .. '/'
		   .. string.format("%.2f", origAcceleration*GAME_FRAMERATE)
		);
	end
	
	global.trainId2speed[train.id] = getTrainSpeed(train);
end



function ensure_mod_context()
	ensure_global_rndm()
	ensure_global_mapping('trainId2train');
	ensure_global_mapping('trainId2mass');
	ensure_global_mapping('trainId2force');
	ensure_global_mapping('trainId2speed');
end



function refresh_mod_settings()
	global.settings = {
		fuelTypeBasedAcceleration     = settings.global["modtrainspeeds-fuel-type-based-acceleration"].value,
		locomotivePullforce           = settings.global["modtrainspeeds-locomotive-pullforce"].value,
		cargoStackWeight              = settings.global["modtrainspeeds-cargo-stack-weight"].value,
		fluidLiterWeight              = settings.global["modtrainspeeds-fluid-liter-weight"].value,
		trainAirfrictionCoefficient   = settings.global["modtrainspeeds-train-airfriction-coefficient"].value,
		shipWaterfrictionCoefficient  = settings.global["modtrainspeeds-ship-waterfriction-coefficient"].value,
		trainWheelfrictionCoefficient = settings.global["modtrainspeeds-train-wheelfriction-coefficient"].value
	}
end



script.on_event({defines.events.on_tick},
	function (e)
		ensure_mod_context();
		
		if global.settings == nil or e.tick % GAME_FRAMERATE == 0 then
			refresh_mod_settings();
		end
		
		local discoveryInterval = 120;
		local measureInterval = 120;
		local adjustInterval = 1;
		
		if (e.tick % discoveryInterval == 0) then
			findTrains();
		end
		
		for trainId, train in pairs(global.trainId2train) do
			if train.valid then
				if (e.tick % measureInterval == trainId % measureInterval) then
					global.trainId2mass[trainId]  = getTrainMass(train);
					global.trainId2force[trainId] = getTrainForce(train);
				end
			end
		end
		
		for trainId, train in pairs(global.trainId2train) do
			if train.valid then
				if (e.tick % adjustInterval == trainId % adjustInterval) then
					if train.state == defines.train_state.on_the_path
					or train.state == defines.train_state.manual_control then
					
						-- adjustTrainAccleration(train);
					end
				end
			end
		end
	end
)
