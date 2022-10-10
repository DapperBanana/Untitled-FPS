extends KinematicBody

const MIN_CAMERA_ANGLE = -60
const MAX_CAMERA_ANGLE = 70
const GRAVITY = -40

export var speed: float = 10.0
export var camera_sensitivity: float = 0.1
export var acceleration: float = 7.0
export var jump_impulse: float = 12.0
var velocity: Vector3 = Vector3.ZERO

var puppet_position = Vector3()
var puppet_velocity = Vector3()
var puppet_rotation = Vector2()

onready var head: Spatial = $Head
export(NodePath) onready var model = get_node(model) as Spatial
export(NodePath) onready var camera = get_node(camera) as Camera
export(NodePath) onready var network_tick_rate = get_node(network_tick_rate) as Timer
export(NodePath) onready var movement_tween = get_node(movement_tween) as Tween

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	camera.current = is_network_master()
	model.visible = !is_network_master()

func _physics_process(delta):
	#Gravity applies to all characters
	velocity.y += GRAVITY * delta
	
	if is_network_master():
		var movement = _get_movement_direction()
		
		velocity.x = lerp(velocity.x, movement.x * speed, acceleration * delta)
		velocity.z = lerp(velocity.z, movement.z * speed, acceleration * delta)
	
	else:
		global_transform.origin = puppet_position
		
		velocity.x = puppet_velocity.x
		velocity.y = puppet_velocity.y
		
		rotation.y = puppet_rotation.y
		head.rotation.x = puppet_rotation.x
	
	if !movement_tween.is_active():
		velocity = move_and_slide(velocity, Vector3.UP)

func _unhandled_input(event):
	if is_network_master():
		if event is InputEventMouseMotion:
			_handle_camera_rotation(event)

func _handle_camera_rotation(event):
	rotate_y(deg2rad(-event.relative.x * camera_sensitivity))
	head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	head.rotation.x = clamp(head.rotation.x,deg2rad(MIN_CAMERA_ANGLE),deg2rad(MAX_CAMERA_ANGLE))

func _get_movement_direction():
	var direction = Vector3.DOWN
	
	if Input.is_action_pressed("forward"):
		direction -= transform.basis.z
	if Input.is_action_pressed("backwards"):
		direction += transform.basis.z
	if Input.is_action_pressed("left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("right"):
		direction += transform.basis.x
	if Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump_impulse
	
	return direction.normalized()

puppet func update_state(p_position, p_velocity, p_rotation):
	puppet_position = p_position
	puppet_velocity = p_velocity
	puppet_rotation = p_rotation
	
	movement_tween.interpolate_property(self, "global_transform", global_transform, Transform(global_transform.basis, p_position), 0.1)
	movement_tween.start()


func _on_NetworkTickRate_timeout():
	if is_network_master():
		rpc_unreliable("update_state", global_transform.origin, velocity, Vector2(head.rotation.x, rotation.y))
	else:
		network_tick_rate.stop()
