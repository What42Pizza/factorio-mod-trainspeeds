function shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end



function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function starts_with(str, start)
   return str:sub(1, #start) == start
end

function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

function table_length(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end



function deeptostring(orig)
    local text
	if orig == nil then
		text = 'nil'
	elseif type(orig) == 'string' then
		text = '"' .. orig .. '"'
	elseif type(orig) == 'table' then
		text = ''
        for orig_key, orig_value in next, orig, nil do
            text = text .. deeptostring(orig_key) .. '=' .. deeptostring(orig_value) .. ','
        end
        -- text = '[' .. text .. deeptostring(getmetatable(orig)) .. ']'
        text = '[' .. text .. ']'
    else
        text = tostring(orig)
    end
    return text
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











trainId2train = {}
trainId2speed = {}
trainId2mass = {}
trainId2force = {}

function findTrains()
	trainId2train = {}
	for _idx1_, surface in pairs(game.surfaces) do
		for _idx2_, train in pairs(surface.get_trains()) do
			trainId2train[train.id] = train
		end
	end
end

function getTrainSpeed(train)
	return train.speed * 60.0 * 3.6;
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
	local total = 0.0;
	
	total = total + getLocomotiveCount(train) * 2500.0;
	
	
	-- air friction impacts only first locomotive
	total = total - 750.0;
	
	return total;
end



function adjustTrainAccleration(train)
	local currSpeed = getTrainSpeed(train);
	if not trainId2speed[train.id] then
		trainId2speed[train.id] = currSpeed;
		return
	end
	
	local prevSpeed = trainId2speed[train.id];
	local acceleration = (currSpeed - prevSpeed) * 60.0;
	local didChange = 0;
	
	local maxAcceleration = trainId2force[train.id] / trainId2mass[train.id];
	
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
	
	trainId2speed[train.id] = getTrainSpeed(train);
end


firstTick = true;

script.on_event({defines.events.on_tick},
	function (e)
		if (firstTick == true or e.tick % 120 == 0) then
			firstTick = false
			
			findTrains();
			for trainId, train in pairs(trainId2train) do
				if train.valid then
					trainId2mass[trainId] = getTrainMass(train);
					trainId2force[trainId] = getTrainForce(train);
				end
			end
		end
		
		if (e.tick % 10 == 0) then
			for trainId, train in pairs(trainId2train) do
				if train.valid then
					for direction, locomotives in pairs(train.locomotives) do
						for idx, locomotive in ipairs(locomotives) do
							locomotive.create_build_effect_smoke();
						end
					end
				end
			end
		end
		
		if trainId2train then
			for trainId, train in pairs(trainId2train) do
				if train.valid then
					adjustTrainAccleration(train);
				end
			end
		end
	end
)
