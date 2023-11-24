for _, loco in pairs(data.raw["locomotive"]) do
	loco.braking_force = 0.001 -- Base 10
end