function getTrainSpeed(train)
	return train.speed * 60.0 * 3.6;
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
	local wagon_stack_count = 40;	
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
	local wagon_stack_count = 25000;	
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
			global.modtrainspeeds.trainId2mass[train.id] = getTrainMass(train);
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
end



function getTrainMass(train)
	local total = 0.0;
	
	total = total + getLocomotiveCount(train) * 12500.0;
	
	total = total + getCargoWagonCount(train) * 10000.0;
	total = total + getCargoWagonUsageRatio(train) * 10000.0;
	
	total = total + getFluidWagonCount(train) * 5000.0;
	total = total + getFluidWagonUsageRatio(train) * 15000.0;
	
	return total;
end



function getTrainForce(train)
	local trainSpeed = getTrainSpeed(train);
	
	local pullingForce = getLocomotiveCount(train) * 2500.0;
	local totalForce = pullingForce;
	
	local wheelFriction = trainSpeed * 0.5 * (getLocomotiveCount(train) + getCargoWagonCount(train) + getFluidWagonCount(train));
	local airFriction = trainSpeed * trainSpeed * 0.1;
	local totalFriction = wheelFriction + airFriction;
	
	if totalFriction > totalForce then
		totalFriction = totalForce;
	end
	
	return totalForce - totalFriction;
end



function adjustTrainAccleration(train)
	local currSpeed = getTrainSpeed(train);
	if not global.modtrainspeeds.trainId2speed[train.id] then
		global.modtrainspeeds.trainId2speed[train.id] = currSpeed;
		return
	end
	
	local prevSpeed = global.modtrainspeeds.trainId2speed[train.id];
	local acceleration = (currSpeed - prevSpeed) * 60.0;
	local didChange = 0;
	
	local maxAcceleration = global.modtrainspeeds.trainId2force[train.id] / global.modtrainspeeds.trainId2mass[train.id];
	
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
		train.speed = currSpeed / 60.0 / 3.6;
	end
	
	global.modtrainspeeds.trainId2speed[train.id] = getTrainSpeed(train);
end

script.on_event({defines.events.on_tick},
	function (e)
		ensure_mod_context();
		
		if (e.tick % 120 == 0) then
			findTrains();
			for trainId, train in pairs(global.modtrainspeeds.trainId2train) do
				if train.valid then
					global.modtrainspeeds.trainId2mass[trainId] = getTrainMass(train);
					global.modtrainspeeds.trainId2force[trainId] = getTrainForce(train);
				end
			end
		end
		
		if (e.tick % 10 == 0) then
			for trainId, train in pairs(global.modtrainspeeds.trainId2train) do
				if train.valid then
					for direction, locomotives in pairs(train.locomotives) do
						for idx, locomotive in ipairs(locomotives) do
							locomotive.create_build_effect_smoke();
						end
					end
				end
			end
		end
		
		if global.modtrainspeeds.trainId2train then
			for trainId, train in pairs(global.modtrainspeeds.trainId2train) do
				if train.valid then
					adjustTrainAccleration(train);
				end
			end
		end
	end
)
