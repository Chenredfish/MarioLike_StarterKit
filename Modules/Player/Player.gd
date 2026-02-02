extends CharacterBody2D

# 可調整的角色參數
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var max_health: int = 3

# 角色狀態
var health: int
var is_dead: bool = false

# 取得重力值
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# 節點引用
@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D

# 訊號
signal health_changed(new_health)
signal player_died
signal coin_collected

func _ready():
	health = max_health
	# 設定初始動畫
	if animated_sprite:
		animated_sprite.play("idle")

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
	var direction = Input.get_axis("ui_left", "ui_right")
	
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
	if is_dead:
		return
	
	health -= damage
	health_changed.emit(health)
	
	# 播放受傷動畫
	if animated_sprite:
		animated_sprite.play("hit")
	
	# 檢查是否死亡
	if health <= 0:
		die()

# 死亡函數
func die():
	is_dead = true
	player_died.emit()
	
	# 停止所有移動
	velocity = Vector2.ZERO
	
	# 播放死亡效果（可擴展）
	print("Player died!")

# 收集金幣函數
func collect_coin():
	coin_collected.emit()

# 重置角色狀態
func reset():
	health = max_health
	is_dead = false
	velocity = Vector2.ZERO
	if animated_sprite:
		animated_sprite.play("idle")
	health_changed.emit(health)

# 區域檢測（用於收集物品或觸發事件）
func _on_area_2d_area_entered(area):
	# 檢查是否為可收集物品
	if area.get_parent().has_method("collect"):
		area.get_parent().collect()
		coin_collected.emit()
	
	# 檢查是否為敵人
	if area.get_parent().has_method("damage_player"):
		take_damage(1)
