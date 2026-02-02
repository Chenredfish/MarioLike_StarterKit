extends Area2D

# 金幣參數
@export var coin_value: int = 1

# 節點引用
@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	# 播放金幣動畫
	if animated_sprite:
		animated_sprite.play("spin")

# 被玩家收集
func collect():
	print("Coin collected!")
	# 播放收集音效（未來可添加）
	
	# 立即消失
	queue_free()