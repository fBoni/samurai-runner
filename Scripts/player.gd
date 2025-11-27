extends CharacterBody2D

# Configs
@export var speed: float = 150.0
@export var gravity: float = 900.0
@export var jump_force: float = 380.0

# Cancelamento do ataque
@export var attack_cancel_time: float = 0.18

# Vida
@export var max_health: int = 100
var health: int = max_health

var hud: CanvasLayer

# FSM
enum State {
	IDLE,
	RUN,
	JUMP_START,
	JUMP,
	JUMP_TRANSITION,
	JUMP_FALL,
	ATTACK,
	BLOCK,
	HURT,
	DEATH
}

var state: State = State.IDLE
var previous_state: State

# Controle de ataque
var attack_timer := 0.0
var is_cancelable_attack := false

# Referências
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready():
	hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_health(health, max_health)


func _physics_process(delta):
	apply_gravity(delta)
	update_state(delta)
	move_and_slide()


# Função para mudar de estado
func set_state(new_state: State):
	if state == new_state:
		return

	previous_state = state
	state = new_state

	match state:

		State.IDLE:
			anim.play("idle")

		State.RUN:
			anim.play("run")

		State.JUMP_START:
			anim.play("jump_start")

		State.JUMP:
			anim.play("jump")

		State.JUMP_TRANSITION:
			anim.play("jump_transition")

		State.JUMP_FALL:
			anim.play("jump_fall")

		State.ATTACK:
			anim.play("attack_1")
			attack_timer = 0.0
			is_cancelable_attack = true

		State.BLOCK:
			anim.play("block")

		State.HURT:
			anim.play("hurt")

		State.DEATH:
			anim.play("death")
			velocity = Vector2.ZERO


# Atualiza o comportamento dependendo do estado
func update_state(delta):

	match state:

		State.IDLE:
			if Input.is_action_pressed("block") and is_on_floor():
				set_state(State.BLOCK)
				return

			if Input.is_action_just_pressed("attack"):
				set_state(State.ATTACK)
				return

			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = -jump_force
				set_state(State.JUMP_START)
				return

			var dir = Input.get_axis("left", "right")
			velocity.x = dir * speed
			if dir != 0:
				anim.flip_h = dir < 0
				set_state(State.RUN)


		State.RUN:
			if Input.is_action_pressed("block"):
				set_state(State.BLOCK)
				return

			if Input.is_action_just_pressed("attack"):
				set_state(State.ATTACK)
				return

			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = -jump_force
				set_state(State.JUMP_START)
				return

			var dir = Input.get_axis("left", "right")
			velocity.x = dir * speed
			if dir == 0:
				set_state(State.IDLE)

			if dir != 0:
				anim.flip_h = dir < 0


		State.BLOCK:
			velocity.x = 0

			if not Input.is_action_pressed("block"):
				set_state(State.IDLE)


		State.ATTACK:
			velocity.x = 0

			attack_timer += delta
			if attack_timer > attack_cancel_time:
				is_cancelable_attack = false

			if is_cancelable_attack and Input.is_action_pressed("block"):
				set_state(State.BLOCK)
				return


		State.JUMP_START:
			if velocity.y < 0:
				set_state(State.JUMP)


		State.JUMP:
			if velocity.y >= -40 and velocity.y < 0:
				set_state(State.JUMP_TRANSITION)

			if velocity.y > 0:
				set_state(State.JUMP_FALL)


		State.JUMP_TRANSITION:
			if velocity.y > 0:
				set_state(State.JUMP_FALL)


		State.JUMP_FALL:
			if is_on_floor():
				set_state(State.IDLE)


		State.HURT:
			pass


		State.DEATH:
			pass


# Gravidade
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0



# Sistema de vida
func take_damage(amount):
	if state == State.HURT or state == State.DEATH:
		return

	health -= amount
	health = clampi(health, 0, max_health)

	if hud:
		hud.update_health(health, max_health)
		hud.flash_damage()

	if health <= 0:
		set_state(State.DEATH)
		await get_tree().create_timer(0.5).timeout
		get_tree().reload_current_scene()
		return

	set_state(State.HURT)


# Animação finalizada
func _on_animated_sprite_2d_animation_finished():
	match anim.animation:
		"attack_1":
			set_state(State.IDLE)
		"hurt":
			set_state(State.IDLE)
