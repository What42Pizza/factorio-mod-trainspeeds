local vanilla_loc = data.raw["locomotive"]["locomotive"]

if vanilla_loc ~= nil then
	-- vanilla_loc.burner.smoke = {}
	
	for idx, smoke_source in ipairs(vanilla_loc.burner.smoke) do
		smoke_source.frequency = 0
	end
end