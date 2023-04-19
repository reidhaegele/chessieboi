extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var parent = get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var frames = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	frames = frames + 1
	if(frames > 60):
		for child in self.get_children():
			child.queue_free()
		frames=0
		var chessBoard1 = parent.get_child(0).chessBoard
		for i in range(8):
			for j in range(8):
				var label = Label.new()
				label.text = chessBoard1[i][j]
				label.rect_min_size = Vector2(64, 64)  # Set the size of each label
				label.rect_position = Vector2(((j * 50)+550), ((i * 50)+100))  # Set the position of each label
				add_child(label)  # Add the label as a child of the current node
