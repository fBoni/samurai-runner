extends CharacterBody2D

# Movimento
@export var speed: float = 150.0
@export var gravity: float = 900.0

# Vida do player
@export var max_health: int = 100
var health: int = max_health

var hud: CanvasLayer # Será recuperado no _ready()

# Estados
var is_attacking: bool = false
var is_hurt: bool = false
var is_death: bool = false
var is_jump_start: bool = false
var is_blocking: bool = false


# Referências
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	hud = get_tree().get_first_node_in_group("hud")

	if hud:
		hud.update_health(health, max_health)


# FÍSICA
func _physics_process(delta: float) -> void:
	# Detecta block no início so frame
	if Input.is_action_pressed("block") and is_on_floor() and not is_attacking and not is_hurt and not is_hurt and not is_death:
		is_blocking = true
	else:
		is_blocking = false
	
	# Bloqueia tudo quando block ativo	
	if is_blocking or is_attacking or is_hurt or is_death:
		velocity.x = 0
		move_and_slide()
		return

	apply_gravity(delta)
	handle_movements()
	handle_animation()
	move_and_slide()


# MOVIMENTO
func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0


func handle_movements() -> void:
	if is_death:
		return
	
	var input_dir := Input.get_axis("left", "right")
	velocity.x = input_dir * speed

	# Debug de dano / TEMPORÁRIO
	if Input.is_action_just_pressed("debug_damage"):
		take_damage(10)

	# Virar sprite
	if input_dir != 0:
		anim.flip_h = input_dir < 0
		
	# Sistema de pulo
	# Pressionou o pulo e está no chão
	if Input.is_action_just_pressed("jump") and is_on_floor():
		is_jump_start = true
		anim.play("jump_start")
		
		# O impulso acontece imediatamente
		velocity.y = -380.0 #verificar se essa velocidade está ok
		
		# is_jump_start vai ser desligado sozinho ao detectar subina no handle_animation()	

	# Ataque
	if Input.is_action_just_pressed("attack"):
		play_attack()
	

# AÇÕES
func play_attack() -> void:
	if is_death:
		return
	
	is_attacking = true
	anim.play("attack")


func play_hurt() -> void:
	is_hurt = true
	anim.play("hurt")
	

func play_block():
	is_blocking = true
	anim.play("block")


# ANIMAÇÕES
func handle_animation() -> void:
	if is_attacking or is_hurt or is_death:
		return
	
	#Defesa
	if is_blocking:
		anim.play("block")
		return
	
		
	# No ar
	if not is_on_floor():
		# Durante jump-start
		if is_jump_start:
			if anim.player != "jump_start":
				is_jump_start = false #encerrou animação
			return
		
		# Subindo forte
		if velocity.y < -40:
			anim.play("jump")
			return
			
		#Subida suave - transição
		if velocity.y < 0:
			anim.play("jump_transition")
			return
		
		#Caindo
		if velocity.y > 0:
			anim.play("jump_fall")
			return
		
		return
		
# No chão
	is_jump_start = false

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
		"death":
			restart_level()
			


func reset_attack() -> void:
	is_attacking = false


func reset_hurt() -> void:
	is_hurt = false



# SISTEMA DE VIDA
func take_damage(amount: int) -> void:
	if is_hurt or is_death:
		return

	health -= amount
	health = clampi(health, 0, max_health)

	# Atualiza HUD com animação suave
	if hud:
		hud.update_health(health, max_health)
		hud.flash_damage()

	if health <= 0:
		die()
		return
		
	play_hurt()


func die() -> void:
	print("Player morreu")
	is_death = true
	is_hurt = false
	is_attacking = false
	
	# Congela personagem
	velocity = Vector2.ZERO
	
	anim.play("death")
	
func restart_level() -> void:
	await get_tree().create_timer(0.5).timeout
	get_tree().reload_current_scene()


	
	
	
	# emitir sinal "player_morreu"
