for _, loco in pairs(data.raw["locomotive"]) do
	loco.braking_force = 10.00 -- Base: 10
end



local train_types = {
	"locomotive",
	"fluid-wagon",
	"cargo-wagon"
}



for _, train_type in ipairs(train_types) do
	for prototype_name, item_prototype in pairs(data.raw[train_type]) do
		if  prototype_name ~= 'cargo_ship_engine'
		and prototype_name ~= 'cargo_ship'
		and prototype_name ~= 'boat_engine'
		and prototype_name ~= 'oil_tanker'
	 -- and prototype_name ~= 'boat'		
		then
			item_prototype.weight = 10 * item_prototype.weight
		end
	end
end






local fuel_types = {
	"wood",
	"coal",
	"solid-fuel",
	"rocket-fuel",
	"nuclear-fuel"
}

--for i, fuel_type in ipairs(fuel_types) do
--	local fuel = data.raw.item[fuel_type]
--	fuel.fuel_acceleration_multiplier = 10
--	fuel.fuel_top_speed_multiplier = 1
--end