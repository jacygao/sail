extends Panel

signal invest
signal leave

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_LeaveButton_pressed():
	emit_signal("leave")

func _on_InvestButton_pressed():
	emit_signal("invest")