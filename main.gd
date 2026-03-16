extends Node2D

func _ready():
	# 主場景基礎設置初始化
	_initialize_scene_settings()

# 主場景基礎設置初始化
func _initialize_scene_settings():
	# 設定實例化物件的位置和縮放
	var player = get_node_or_null("Player")
	if player:
		player.position = Vector2(106, 429)
	
	# 設定金幣位置
	var coin1 = get_node_or_null("Coin1")
	if coin1:
		coin1.position = Vector2(500, 250)
	
	var coin2 = get_node_or_null("Coin2")
	if coin2:
		coin2.position = Vector2(700, 200)
	
	var coin3 = get_node_or_null("Coin3")
	if coin3:
		coin3.position = Vector2(900, 250)
		coin3.scale = Vector2(2, 2)
	
	# 設定敵人位置
	var enemy = get_node_or_null("SimpleEnemy2")
	if enemy:
		enemy.position = Vector2(659, 366)
		enemy.scale = Vector2(2, 2)
