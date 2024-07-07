extends DirectionalLight3D

var a : float = 0.0;

func _process(delta):
	a += 0.001 # Dynamic
	a = 2.5 # Static Position
	
	self.look_at( transform.origin - Vector3(sin(a * 0.51), sin(a) * 0.5 + 0.52, cos(a * 0.51)) )
