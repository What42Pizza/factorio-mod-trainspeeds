require("prototypes.item")


data.raw["cargo-wagon"]["cargo-wagon"].weight = 10000
data.raw["fluid-wagon"]["fluid-wagon"].weight = 10000
data.raw["locomotive"]["locomotive"].weight   = 10000


local fuel_types = {
	"wood",
	"coal",
	"solid-fuel",
	"rocket-fuel",
	"nuclear-fuel"
}



for i, fuel_type in ipairs(fuel_types) do
	local fuel = data.raw.item[fuel_type]
	fuel.fuel_acceleration_multiplier = 10
	fuel.fuel_top_speed_multiplier = 1
end