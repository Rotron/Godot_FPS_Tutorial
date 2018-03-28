extends RigidBody

const GRENADE_DAMAGE = 40;

const GRENADE_TIME = 3;
var grenade_timer = 0;

const EXPLOSION_WAIT_TIME = 0.48;
var explosion_wait_timer = 0;

var attached = false;
var attach_point = null;

var rigid_shape;
var grenade_mesh;
var blast_area;
var explosion_particles;

var player_body;

func _ready():
	rigid_shape = get_node("CollisionShape");
	grenade_mesh = get_node("StickyGrenade");
	blast_area = get_node("BlastArea");
	explosion_particles = get_node("Explosion");
	
	explosion_particles.emitting = false;
	explosion_particles.one_shot = true;
	
	var stickyArea = get_node("StickyArea");
	stickyArea.connect("body_entered", self, "collided_with_body");


func collided_with_body(body):
	
	# Make sure we are not colliding with ourself
	if (body == self):
		return;
	
	# We do not want to collide with the player that's thrown this grenade
	if (player_body != null):
		if (body == player_body):
			return;
	
	if (attached == false):
		# Attach ourselves to the body at that position. We will do this by
		# making ourselves a child of that node.
		attached = true;
		attach_point = Spatial.new();
		body.add_child(attach_point);
		attach_point.global_transform.origin = self.global_transform.origin;
		rigid_shape.disabled = true;
		
		# Set our mode to MODE_STATIC so the grenade does not move around
		mode = RigidBody.MODE_STATIC;


func _process(delta):
	
	if (attached == true):
		global_transform.origin = attach_point.global_transform.origin;
	
	if (grenade_timer < GRENADE_TIME):
		grenade_timer += delta;
		return;
	
	if (explosion_wait_timer < EXPLOSION_WAIT_TIME):
		explosion_wait_timer += delta;
		
		# If we have waited long enough, we need to explode!
		# Doing the check this way reduces a boolean, and since this is a small script, its likely okay
		# to use some coding tricks like this.
		if (explosion_wait_timer >= EXPLOSION_WAIT_TIME):
			explosion_particles.emitting = true;
			
			grenade_mesh.visible = false;
			rigid_shape.disabled = true;
			mode = RigidBody.MODE_STATIC;
			
			# Get all of the bodies in the area, and apply damage to them
			var bodies = blast_area.get_overlapping_bodies();
			for body in bodies:
				if body.has_method("bullet_hit"):
					body.bullet_hit(GRENADE_DAMAGE, global_transform.origin);
			
			# If you want, this would be the perfect place to play a sound!
			
	else:
		if (explosion_wait_timer < EXPLOSION_WAIT_TIME):
			explosion_wait_timer += delta;
			
			if (explosion_wait_timer >= EXPLOSION_WAIT_TIME):
				if (attached == true):
					attach_point.queue_free();
				queue_free();