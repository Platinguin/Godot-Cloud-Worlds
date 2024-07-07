extends Camera3D

var camera_movement_speed : float = 100.0
var camera_rotation_speed : float = 0.005
	
func _process(delta):
	if Input.is_action_pressed("keyboard_right"):
		self.transform.origin += self.transform.basis.x * Input.get_action_strength("keyboard_right") * delta * camera_movement_speed
	if Input.is_action_pressed("keyboard_left"):
		self.transform.origin -= self.transform.basis.x * Input.get_action_strength("keyboard_left") * delta * camera_movement_speed
	if Input.is_action_pressed("keyboard_forward"):
		self.transform.origin -= self.transform.basis.z * Input.get_action_strength("keyboard_forward") * delta * camera_movement_speed
	if Input.is_action_pressed("keyboard_back"):
		self.transform.origin += self.transform.basis.z * Input.get_action_strength("keyboard_back") * delta * camera_movement_speed

func _input(event):
	# RIGHT MOUSE CLICK
	if (event is InputEventMouseMotion and event.button_mask == 2):
		self.look_at(self.transform.origin - self.transform.basis.z + self.transform.basis.x * camera_rotation_speed * event.relative.x - self.transform.basis.y * camera_rotation_speed * event.relative.y)
	# MOUSE WHEEL UP + RIGHT MOUSE CLICK (8+2)
	if (event is InputEventMouseButton and event.button_mask == 10):
		camera_movement_speed *= 1.1
	# MOUSE WHEEL DOWN+ RIGHT MOUSE CLICK (16+2)
	if (event is InputEventMouseButton and event.button_mask == 18): 
		camera_movement_speed *= 0.9
		if camera_movement_speed < 1.0:
			camera_movement_speed = 1.0
