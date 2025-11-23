extends CanvasLayer

@onready var bar: ProgressBar = $HealthBarContainer/ProgressBar


func _ready() -> void:
	#conecta automaticamente ao player quando ele aparece na cena
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		
func _on_player_health_changed(current, max_health):
	bar.max_value = max_health
	bar.value = current
	
	$HealthBarContainer/ProgressBar/Label.text = str(current, " / ", max_health)
	
	_uptade_bar_color(current, max_health)
	

func _uptade_bar_color(current, max_health):
	var ratio = float(current) / float(max_health)
	var fill = bar.get("theme_override_styles/fill")
	
	if ratio > 0.6:
		fill.bg_color = Color(0 ,1, 0) #verde
	elif ratio > 0.3:
		fill.bg_color = Color(1, 0.8, 0) #amarelo
	else:
		fill.bg_color = Color(1, 0, 0) #vermelho
