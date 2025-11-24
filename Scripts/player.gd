extends CharacterBody2D

# ----------------------------------------------------
# Movimento
# ----------------------------------------------------
@export var speed: float = 150.0
@export var gravity: float = 900.0

# ----------------------------------------------------
# Vida
# ----------------------------------------------------
@export var max_health: int = 100
var health: int = max_health

var hud: CanvasLayer # Será recuperado no _ready()

# ----------------------------------------------------
# Estados
# ----------------------------------------------------
var is_attacking: bool = false
var is_hurt: bool = false

# ----------------------------------------------------
# Referências
# ----------------------------------------------------
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


# ====================================================
# READY
# ====================================================
func _ready() -> void:
	hud = get_tree().get_first_node_in_group("hud")

	if hud:
		
		hud.update_health(health, max_health)


# ====================================================
# FÍSICA
# ====================================================
func _physics_process(delta: float) -> void:
	if is_attacking or is_hurt:
		velocity.x = 0
		move_and_slide()
		return

	apply_gravity(delta)
	handle_movements()
	handle_animation()

	move_and_slide()


# ====================================================
# MOVIMENTO
# ====================================================
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0


func handle_movements() -> void:
	var input_dir := Input.get_axis("left", "right")
	velocity.x = input_dir * speed

	# Teste de dano
	if Input.is_action_just_pressed("debug_damage"):
		take_damage(10)

	# Virar sprite
	if input_dir != 0:
		anim.flip_h = input_dir < 0

	# Ataque
	if Input.is_action_just_pressed("attack"):
		play_attack()


# ====================================================
# AÇÕES
# ====================================================
func play_attack() -> void:
	is_attacking = true
	anim.play("attack")


func play_hurt() -> void:
	is_hurt = true
	anim.play("hurt")


# ====================================================
# ANIMAÇÕES
# ====================================================
func handle_animation() -> void:
	if is_attacking or is_hurt:
		return

	if velocity.x == 0:
		anim.play("idle")
	else:
		anim.play("run")


func _on_animated_sprite_2d_animation_finished() -> void:
	match anim.animation:
		"attack":
			reset_attack()
		"hurt":
			reset_hurt()


func reset_attack() -> void:
	is_attacking = false


func reset_hurt() -> void:
	is_hurt = false


# ====================================================
# SISTEMA DE VIDA
# ====================================================
func take_damage(amount: int) -> void:
	# Impede dano repetido durante animação de hurt
	if is_hurt:
		return

	health -= amount
	health = clamp(health, 0, max_health)

	# Atualiza HUD com animação suave
	if hud:
		hud.update_health(health, max_health)
		hud.flash_damage()

	if health <= 0:
		die()
	else:
		play_hurt()


func die() -> void:
	print("Player morreu")

	# Congela personagem
	velocity = Vector2.ZERO
	is_hurt = true
	is_attacking = true

	# Usa a animação de hurt como placeholder
	anim.play("hurt")

	# Aqui você pode futuramente colocar:
	# anim.play("death")
	# get_tree().reload_current_scene()
	# emitir sinal "player_morreu"
