extends CharacterBody2D

#Movimento
@export var speed: float = 150.0
@export var gravity: float = 900.00

#Sistema de vida
@export var max_health: int = 100
var health: int = max_health

#Sinal para atualizar a HUD
signal health_changed(current, max)

#Controle de ações
var is_attacking: bool = false
var is_hurt: bool = false

#Referências
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta) -> void:
	if is_attacking or is_hurt:
		#Enquanto estiver atacando ou tomando dano, não pode mover
		velocity.x = 0
		move_and_slide()
		return
		
	apply_gravity(delta)
	handle_movements()
	handle_animation()
	
	move_and_slide()
	
	
#Funções

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		
func handle_movements():
	var input_dir = Input.get_axis("left", "right")
	velocity.x = input_dir * speed
	
	#Dano de teste
	if Input.is_action_just_pressed("debug_damage"):
		take_damage(10)
	
	#Virar sprite
	if input_dir !=0:
		anim.flip_h = input_dir < 0
		
	#Ataque
	if Input.is_action_just_pressed("attack"):
		play_attack()
		
func play_attack():
	is_attacking = true
	anim.play("attack")
	
	#Impede que movimento/animação voltem no meio do ataque
	#Quando a animação terminar, o sinal animation_finished chamará reset_attack()
	
func play_hurt():
	is_hurt = true
	anim.play("hurt")
	
	#Depois que a animação terminar, reset_hurt será chamado (sinal)
	
func handle_animation():
	if is_attacking or is_hurt:
		return #não muda a animação durante ataque/dano	
	
	if velocity.x == 0:
		anim.play("idle")
	else:
		anim.play("run")
		
#Animações terminadas

func _on_animated_sprite_2d_animation_finished() -> void:
	match  anim.animation:
		"attack":
			reset_attack()
		"hurt":
			reset_hurt()
			
func reset_attack():
	is_attacking = false
	
func reset_hurt():
	is_hurt = false
	
#Sistema de vida

func take_damage(amount: int):
	if is_hurt:
		return #Evita tomar vários hits durante a animação
	
	health -= amount
	health = max(health, 0)
	
	emit_signal("health_changed", health, max_health)
	
	if health <= 0:
		die()
	else:
		play_hurt()
		
func die():
	#Comportamento simples de protótipo
	print("Player morreu")
	velocity = Vector2.ZERO
	is_hurt = true
	anim.play("hurt")
		
