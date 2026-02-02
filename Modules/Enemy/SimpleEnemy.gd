extends CharacterBody2D

# 敵人參數
@export var patrol_speed: float = 50.0
@export var patrol_distance: int = 5  # 巡邏格數
@export var tile_size: int = 32  # 一格的大小

# 敵人狀態
var start_position: Vector2
var direction: int = 1  # 1 = 向右, -1 = 向左
var patrol_range: float

# 取得重力值
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# 節點引用
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	# 記錄起始位置
	start_position = global_position
	# 計算巡邏範圍（5格 = 5 * 32 = 160像素）
	patrol_range = patrol_distance * tile_size
	
	# 設定初始動畫
	if animated_sprite:
		animated_sprite.play("walk")

func _physics_process(delta):
	# 添加重力處理
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 簡單的左右巡邏邏輯
	patrol()
	
	# 移動敵人（受重力影響）
	velocity.x = direction * patrol_speed
	
	move_and_slide()

func patrol():
	# 計算當前距離起始位置的距離
	var distance_from_start = global_position.x - start_position.x
	
	# 如果到達右邊界，轉向左
	if distance_from_start >= patrol_range:
		direction = -1
		if animated_sprite:
			animated_sprite.flip_h = true
	
	# 如果到達左邊界，轉向右
	elif distance_from_start <= -patrol_range:
		direction = 1
		if animated_sprite:
			animated_sprite.flip_h = false

# 傷害玩家的函數
func damage_player():
	print("Enemy damaged player!")

# 被玩家消滅（可擴展功能）
func take_damage(damage: int = 1):
	print("Enemy took damage!")
	die()

# 敵人死亡函數
func die():
	print("Enemy died!")
	# 停止移動
	velocity = Vector2.ZERO
	# 播放死亡動畫（如果有的話）
	if animated_sprite:
		animated_sprite.stop()
	# 使用call_deferred來延遲秋用刪除操作
	call_deferred("_deferred_cleanup")

# 延遲清理函數
func _deferred_cleanup():
	# 移除敵人
	queue_free()

# 區域檢測（用於傷害玩家）
func _on_area_2d_area_entered(area):
	# 檢查是否碰到玩家
	if area.get_parent().has_method("take_damage"):
		# 使用call_deferred來延遲處理碰撞
		call_deferred("_handle_player_collision", area.get_parent())

# 延遲處理玩家碰撞
func _handle_player_collision(player):
	var player_position = player.global_position
	var enemy_position = global_position
	
	# 計算相對位置
	var vertical_diff = player_position.y - enemy_position.y
	var horizontal_diff = abs(player_position.x - enemy_position.x)
	
	# 判斷碰撞方向 - 如果玩家在敵人上方則踩踏，否則側面碰撞
	if vertical_diff < -20 and horizontal_diff < 30:
		# 踩踏：敵人死亡，玩家反彈
		die()
		if player.has_method("bounce_jump"):
			player.bounce_jump()
		else:
			player.velocity.y = -300
	else:
		# 側面碰撞：玩家受傷
		player.take_damage(1)
