extends Node

export var fire_rate = 2.0
export var coins = 200

func _ready():
	update_coins(coins)
	
func _on_CityStockholm_city_entered():
	pass

func _on_CityStockholm_city_exited():
	pass

# Economy section starts here
func _on_PopupMenu_fire_upgrade_pressed(cost):
	if cost <= coins:
		$PlayerBoat.fire_damage+=1
		update_coins(coins-cost)
	else:	
		show_warn_message("insufficient funds")

func _on_PopupMenu_armor_upgrade_pressed(cost):
	if cost <= coins:
		$PlayerBoat.max_durability+=1
		$PlayerBoat.durability+=1
		$PlayerBoat.call("update_durability")
		update_coins(coins-cost)
	else:	
		show_warn_message("insufficient funds")
		
func update_coins(c):
	coins = c
	$HUD.update_coins(coins)

func show_warn_message(msg):
	$HUD.show_message($HUD.message_level_warn, msg)

func _on_BoatDisappearTimer_timeout():
	$NPCBoat.queue_free()
	$BoatDisappearTimer.stop()

func _on_NPCBoat_sinking():
	$BoatDisappearTimer.start()

func _on_NPCBoat_is_clicked(pos):
	$ObjectPopupControl.open(pos)

# An attack button is pressed, moving player boat towards target.
func _on_Pirate_attack_pressed(node):
	$Pirate.hide_popup_tutorial()
	$Player.attacking(node)

func _on_Player_battle_victory(node):
	$HUD/DialogUI.new_dialog("first_victory")

func _on_Pirate_sinking_boat_pressed(node):
	$Pirate.hide_tutorial()
	$HUD/RewardUI.show_tutorial()
	$HUD/RewardUI.open(node)

func _on_RewardUI_claim_all(items):
	for item in items:
		if Item_Meta.is_item_coin(item):
			var amount = Item_Meta.get_item_amount(item)
			$HUD.plus_coins(amount)
			$HUD.render_node()
		else:
			Inventory.store_one(item)

func _on_Pirate_boat_cleared():
	$HUD/DialogUI.new_dialog("first_reward")

func _on_Stockholm_enter_pressed(node):
	$Stockholm.hide_popup_tutorial()
	$Player.moving_to(node)

func _on_Stockholm_city_entered(node):
	if node.team() == 1:
		$Player.idle()
	get_tree().change_scene("res://scenes/CityHUD/CityHUD.tscn")

func _on_DialogUI_dialog_played(key):
	if key == "game_start":
		$Pirate.show_tutorial()
	if key == "first_victory":
		var pos = $Pirate.get_global_transform_with_canvas().origin
		pos.x -= 80
		pos.y -= 40
		$Pirate.show_tutorial()
	if key == "first_reward":
		$HUD/TutorialUI.set_pos(Utils.tutorial_position_offset($HUD.get_node("WorldViewButton")))
		$HUD/TutorialUI.open()
		
func _on_Pirate_body_pressed(node):
	$Pirate.hide_tutorial()
	$Pirate.show_popup_tutorial()

func reset_tutorial():
	pass
	
func _on_HUD_ancher_on():
	$Player.call("anchor_on")

func _on_HUD_ancher_off():
	$Player.call("anchor_off")

func _on_HUD_world_view_on():
	$HUD/TutorialUI.close()
	$Stockholm.show_tutorial()
	$Player.set_world_view()

func _on_HUD_world_view_off():
	$Player.set_boat_view()

func _on_Stockholm_body_pressed(popup_node):
	$Stockholm.hide_tutorial()
	$Stockholm.show_popup_tutorial()
