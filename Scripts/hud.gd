extends CanvasLayer

@onready var hp_bar: ProgressBar = $HealthBar

var displayed_value := 0.0

func _ready() -> void:
	reset_color()


func update_health(current: int, max_health: int) -> void:
	if hp_bar == null:
		return
		
	hp_bar.max_value = max_health
	hp_bar.value = current
	
	#Tween suave para o valor exibido
	var tween := create_tween()
	tween.tween_property(self, "displayed_value", current, 0.25)\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(Tween.EASE_OUT)
	tween.connect("finished", Callable(self, "_apply_bar_value"))
	
	_update_color(current, max_health)
	
func _apply_bar_value() -> void:
	#aplica o valor final na barra após a animação
	hp_bar.value = displayed_value
	
func _update_color(current: int, max_health: int) -> void:
	var ratio := float(current) / float(max_health)
	var fill_style: StyleBoxFlat = hp_bar.get_theme_stylebox("fill")
	
	var target_color := Color.GREEN
	
	if ratio > 0.6:
		target_color = Color(0,1,0) #Verde
	elif ratio > 0.3:
		target_color = Color(1,0.8,0) #Amarelo
	else:
		target_color = Color(1,0,0) #Vermelho
		
	#Tween suave para a cor
	var tween := create_tween()
	tween.tween_property(fill_style, "bg_color", target_color, 0.25)
	
	
func flash_damage() -> void:
	var tween := create_tween()
	hp_bar.modulate = Color(1,0.6,0.6)
	tween.tween_property(hp_bar, "modulate", Color.WHITE, 0.3)\
	.set_trans(Tween.TRANS_SINE)\
	.set_ease(tween.EASE_OUT)

func reset_color():
	var fill_style: StyleBoxFlat = hp_bar.get_theme_stylebox("fill")
	fill_style.bg_color = Color(0,1,0) 
	
	
	
