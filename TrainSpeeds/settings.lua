data:extend
{
	{
		type = "bool-setting",
		name = "riven-acceleration-fuel-type-based-acceleration",
		order = "100",
		setting_type = "runtime-global",
		default_value = true
	},
	
	{
		type = "double-setting",
		name = "riven-acceleration-locomotive-pullforce",
		order = "101",
		setting_type = "runtime-global",
		default_value = 2500,
		minimum_value = 1000,
		maximum_value = 1000000
	},
	
	{
		type = "double-setting",
		name = "riven-acceleration-locomotive-braking-force",
		order = "102",
		setting_type = "runtime-global",
		default_value = 20000,
		minimum_value = 1000,
		maximum_value = 1000000
	},
	
	{
		type = "double-setting",
		name = "riven-acceleration-wagon-braking-force",
		order = "103",
		setting_type = "runtime-global",
		default_value = 1000,
		minimum_value = 0,
		maximum_value = 1000000
	},
	
	{
		type = "double-setting",
		name = "riven-acceleration-cargo-stack-weight",
		order = "201",
		setting_type = "runtime-global",
		default_value = 250,
		minimum_value = 10,
		maximum_value = 1000
	},	
	{
		type = "double-setting",
		name = "riven-acceleration-fluid-liter-weight",
		order = "202",
		setting_type = "runtime-global",
		default_value = 0.4,
		minimum_value = 0.1,
		maximum_value = 10.0
	},
	
	{
		type = "double-setting",
		name = "riven-acceleration-train-airfriction-coefficient",
		order = "401",
		setting_type = "runtime-global",
		default_value = 0.05,
		minimum_value = 0.0,
		maximum_value = 1.0
	},
	{
		type = "double-setting",
		name = "riven-acceleration-train-wheelfriction-coefficient",
		order = "402",
		setting_type = "runtime-global",
		default_value = 0.1,
		minimum_value = 0.0,
		maximum_value = 1.0
	},
	{
		type = "double-setting",
		name = "riven-acceleration-ship-waterfriction-coefficient",
		order = "403",
		setting_type = "runtime-global",
		default_value = 1000.0,
		minimum_value = 0.0,
		maximum_value = 100000.0
	},
}
