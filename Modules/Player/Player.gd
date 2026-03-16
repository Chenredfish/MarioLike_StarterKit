extends CharacterBody2D

# 可調整的角色參數
@export var speed: float = 200.0
@export var jump_velocity: float = -600.0
@export var max_health: int = 3

# 鏡頭參數
@export var camera_smoothing: bool = true
@export var camera_speed: float = 5.0
@export var camera_offset: Vector2 = Vector2(0, -150)

# 角色狀態
var health: int
var is_dead: bool = false
var is_invincible: bool = false  # 無敵狀態
var score: int = 0  # 玩家分數

# 取得重力值
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# 節點引用
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@onready var camera = $Camera2D

# 訊號
signal health_changed(new_health)
signal player_died
signal coin_collected(score)
signal score_changed(new_score)

func _ready():
	health = max_health
	
	# 場景基礎設置初始化
	_initialize_scene_settings()
	
	# 設定初始動畫
	if animated_sprite:
		animated_sprite.play("idle")
	
	# 設定鏡頭
	if camera:
		camera.make_current()
		camera.enabled = camera_smoothing
		if camera_smoothing:
			camera.position_smoothing_enabled = true
			camera.position_smoothing_speed = camera_speed
		camera.offset = camera_offset

# 場景基礎設置初始化
func _initialize_scene_settings():
	# CharacterBody2D 基礎設定
	scale = Vector2(2, 2)
	collision_layer = 4  # 玩家在第4層
	
	# Area2D 碰撞設定
	var area_2d = get_node_or_null("Area2D")
	if area_2d:
		area_2d.collision_layer = 8  # 玩家檢測器在第4層
		area_2d.collision_mask = 18  # 檢測第2層(敵人) + 第5層(物品)
		# 連接信號
		if not area_2d.area_entered.is_connected(_on_area_2d_area_entered):
			area_2d.area_entered.connect(_on_area_2d_area_entered)
	
	# Camera2D 邊界設定
	if camera:
		camera.position = Vector2(0, -50)
		camera.limit_left = -100
		camera.limit_right = 2500
		camera.limit_top = -400
		camera.limit_bottom = 800
		camera.enabled = true

func _physics_process(delta):
	if is_dead:
		return
	
	# 重力處理
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# 跳躍處理
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		if animated_sprite:
			animated_sprite.play("jump")
	
	# 左右移動處理
	var direction = 0
	# 支援方向鍵和WASD
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction += 1
	
	if direction != 0:
		velocity.x = direction * speed
		# 翻轉角色方向
		if animated_sprite:
			animated_sprite.flip_h = direction < 0
			# 播放跑步動畫（如果在地上）
			if is_on_floor() and animated_sprite.animation != "jump":
				animated_sprite.play("run")
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		# 播放待機動畫（如果在地上且不在跳躍）
		if is_on_floor() and animated_sprite and animated_sprite.animation != "jump":
			animated_sprite.play("idle")
	
	# 下墜動畫
	if velocity.y > 0 and not is_on_floor() and animated_sprite:
		animated_sprite.play("fall")
	
	# 移動角色
	move_and_slide()

# 受傷函數
func take_damage(damage: int = 1):
	if is_dead or is_invincible:
		return
	
	health -= damage
	health_changed.emit(health)
	
	# 啟動無敵時間和播放受傷動畫
	is_invincible = true
	if animated_sprite:
		# 斷開舊的連接（如果存在）
		if animated_sprite.animation_finished.is_connected(_on_hit_animation_finished):
			animated_sprite.animation_finished.disconnect(_on_hit_animation_finished)
		
		animated_sprite.play("hit")
		# 連接動畫結束信號
		animated_sprite.animation_finished.connect(_on_hit_animation_finished, CONNECT_ONE_SHOT)
	
	# 啟動無敵時間的循環動畫（1.5秒）
	start_invincibility_animation()
	
	# 檢查是否死亡
	if health <= 0:
		die()

# 死亡函數
func die():
	is_dead = true
	player_died.emit()
	queue_free()  # 直接刪除角色

# 收集金幣函數
func collect_coin(value: int = 1):
	score += value
	print("Score: ", score)
	coin_collected.emit(score)
	score_changed.emit(score)

# 啟動無敵時間的循環動畫
func start_invincibility_animation():
	# 創建1.5秒的無敵時間
	var invincibility_timer = get_tree().create_timer(1.5)
	invincibility_timer.timeout.connect(_end_invincibility)
	
	# 啟動hit動畫的循環播放
	_loop_hit_animation()

func _loop_hit_animation():
	if not is_invincible or is_dead:
		return
	
	if animated_sprite:
		animated_sprite.play("hit")
		# 等待hit動畫結束後再次播放
		var animation_timer = get_tree().create_timer(0.5)  # hit動畫的大致長度
		animation_timer.timeout.connect(_loop_hit_animation)

func _end_invincibility():
	is_invincible = false
	# 恢復到idle動畫
	if animated_sprite and not is_dead:
		animated_sprite.play("idle")

# hit動畫結束時的回呼（保留但不使用）
func _on_hit_animation_finished():
	pass  # 現在不需要做任何事情

# 重置角色狀態
func reset():
	health = max_health
	is_dead = false
	is_invincible = false
	score = 0
	velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.play("idle")
		animated_sprite.modulate = Color.WHITE  # 確保顏色正常
	health_changed.emit(health)
	score_changed.emit(score)

# 區域檢測（僅用於收集物品）
func _on_area_2d_area_entered(area):
	# 檢查是否為可收集物品（直接檢查area本身）
	if area.has_method("collect"):
		var item = area
		item.collect()
		
		# 如果是金幣，增加分數
		if "coin_value" in item:
			collect_coin(item.coin_value)
		else:
			coin_collected.emit(score)  # 其他物品也發送信號

# 鏡頭控制函數
func set_camera_smoothing(enabled: bool):
	camera_smoothing = enabled
	if camera:
		camera.position_smoothing_enabled = enabled

func set_camera_speed(new_speed: float):
	camera_speed = new_speed
	if camera:
		camera.position_smoothing_speed = new_speed

func set_camera_offset(new_offset: Vector2):
	camera_offset = new_offset
	if camera:
		camera.offset = new_offset

func shake_camera(intensity: float = 5.0, duration: float = 0.2):
	if camera:
		# 創建簡單的鏡頭震動效果
		var original_offset = camera.offset
		var shake_tween = create_tween()
		shake_tween.tween_method(_apply_shake, intensity, 0.0, duration)
		shake_tween.tween_callback(func(): camera.offset = original_offset)

func _apply_shake(intensity: float):
	if camera:
		camera.offset = camera_offset + Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
