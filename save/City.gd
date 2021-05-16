extends Node

var city = {
	"Stockholm": {
		"population": 134000,
		"economy": 1880,
		"defence": 2000,
		"products": {
			"fish":2, 
			"bread":2, 
			"weapon":1, 
			"bronze":1,
		},
		"forces": {
			"Leo Linderroth": 20,
		}
	}
}

func occupy(city_name, force_name, rate):
	var c = city[city_name]
	if !c["forces"].has(force_name):
		c["forces"][force_name] = 0
	c["forces"][force_name] += rate

func get_city(city_name):
	return city[city_name]

func get_population(city_data):
	return city_data["population"]

func get_economy(city_data):
	return city_data["economy"]
	
func get_defence(city_data):
	return city_data["defence"]

func get_forces(city_data):
	return city_data["forces"]

func get_products(city_name:String):
	return city[city_name]["products"]
	
func sold_product(city_name, pid):
	if city[city_name]["products"][pid] > 0:
		city[city_name]["products"][pid] -= 1
		return true
	return false