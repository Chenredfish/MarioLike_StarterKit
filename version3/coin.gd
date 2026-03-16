extends Area2D

# 金幣參數
@export var coin_value: int = 1

# 節點引用
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# 場景基礎設置初始化
	_initialize_scene_settings()
	
	# 播放金幣動畫
	if animated_sprite:
		animated_sprite.play("spin")

# 場景基礎設置初始化
func _initialize_scene_settings():
	# Area2D 碰撞設定
	collision_layer = 16  # 金幣在第5層 (2^4 = 16)
	collision_mask = 8    # 檢測第4層(玩家) (2^3 = 8)
	
	# 確保導出變數設定
	if coin_value <= 0:
		coin_value = 1

# 被玩家收集
func collect():
	print("Coin collected!")
	# 播放收集音效（未來可添加）
	
	# 立即消失
	queue_free()
