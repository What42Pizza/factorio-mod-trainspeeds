data:extend
{
	{
		type = "double-setting",
		name = "modtrainspeeds-fuel-bonus-mult",
		order = "100",
		setting_type = "runtime-global",
		default_value = 1,
		minimum_value = 0,
		maximum_value = 10
	},
	
	{
		type = "double-setting",
		name = "modtrainspeeds-locomotive-pullforce",
		order = "101",
		setting_type = "runtime-global",
		default_value = 2500,
		minimum_value = 1000,
		maximum_value = 1000000
	},
	
	{
		type = "double-setting",
		name = "modtrainspeeds-locomotive-braking-force",
		order = "102",
		setting_type = "runtime-global",
		default_value = 20000,
		minimum_value = 1000,
		maximum_value = 10000000
	},
	
	{
		type = "double-setting",
		name = "modtrainspeeds-wagon-braking-force",
		order = "103",
		setting_type = "runtime-global",
		default_value = 1000,
		minimum_value = 0,
		maximum_value = 10000000
	},
	
	{
		type = "double-setting",
		name = "modtrainspeeds-wagon-weight-mult",
		order = "201",
		setting_type = "runtime-global",
		default_value = 10,
		minimum_value = 0.01,
		maximum_value = 100
	},
	
	{
		type = "double-setting",
		name = "modtrainspeeds-cargo-stack-weight",
		order = "202",
		setting_type = "runtime-global",
		default_value = 250,
		minimum_value = 10,
		maximum_value = 1000
	},
	
	{
		type = "double-setting",
		name = "modtrainspeeds-fluid-liter-weight",
		order = "203",
		setting_type = "runtime-global",
		default_value = 0.4,
		minimum_value = 0.1,
		maximum_value = 10.0
	},
	
	{
		type = "double-setting",
		name = "modtrainspeeds-train-airfriction-coefficient",
		order = "401",
		setting_type = "runtime-global",
		default_value = 0.1,
		minimum_value = 0.0,
		maximum_value = 1.0
	},
	{
		type = "double-setting",
		name = "modtrainspeeds-train-wheelfriction-coefficient",
		order = "402",
		setting_type = "runtime-global",
		default_value = 0.25,
		minimum_value = 0.0,
		maximum_value = 1.0
	},
	{
		type = "double-setting",
		name = "modtrainspeeds-ship-waterfriction-coefficient",
		order = "403",
		setting_type = "runtime-global",
		default_value = 1000.0,
		minimum_value = 0.0,
		maximum_value = 100000.0
	},
}
