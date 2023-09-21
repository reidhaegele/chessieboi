extends Control

var w_c = ""
var b_c = ""

var b_check = "Black King in check"
var w_check = "White King in check"

var b_checkmate = "Checkmate, White wins"
var w_checkmate = "Checkmate, Black wins"

var w_adv = 0
var w_adv_text = "+0"
var b_adv = 0
var b_adv_text = "+0"

var c_status = "In play"
var game_over = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$c_status.text = c_status

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_over: return
	$c_status.text = c_status
	$b_captured.text = b_adv_text + "\n" + b_c
	$w_captured.text = w_adv_text + "\n" + w_c


func _on_Chessboard_b_capture(piece, value):
	b_adv += value
	w_adv -= value
	
	w_adv_text = w_adv
	if w_adv_text >= 0: w_adv_text = "+" + str(w_adv_text)
	else: w_adv_text = str(w_adv_text)
	b_adv_text = b_adv
	if b_adv_text >= 0: b_adv_text = "+" + str(b_adv_text)
	else: b_adv_text = str(b_adv_text)
	
	b_c = b_c + piece

func _on_Chessboard_w_capture(piece, value):
	w_adv += value
	b_adv -= value
	
	w_adv_text = w_adv
	if w_adv_text >= 0: w_adv_text = "+" + str(w_adv_text)
	else: w_adv_text = str(w_adv_text)
	b_adv_text = b_adv
	if b_adv_text >= 0: b_adv_text = "+" + str(b_adv_text)
	else: b_adv_text = str(b_adv_text)
	
	w_c = w_c + piece

func _on_Chessboard_check(color):
	if int(color)==2: c_status = "In play"
	elif color: c_status = "Black in check"
	else: c_status = "White in check"


func _on_Chessboard_checkmate(color):
	if color: c_status = "Black checkmated"
	else: c_status = "White checkmated"
	game_over = true
	$c_status.text = c_status
