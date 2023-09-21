extends Sprite

# Array to represent the chess pieces on the board
var chessBoard: Array = [
	"rnbqkbnr",
	"pppppppp",
	"        ",
	"        ",
	"        ",
	"        ",
	"PPPPPPPP",
	"RNBQKBNR"
]

var chessPieces = {"p": 1, "n": 3, "b": 3, "r": 5, "q": 9}

# Chessboard cell size
var cellSize: Vector2 = Vector2(64, 64)
var myOffset: Vector2 = Vector2(225,240)

var whiteTurn = true
var black_check = false
var white_check = false
var black_checkmate = false
var white_checkmate = false

var selectedPiece: Sprite = null
var lastPiece: Sprite = null
var dotSize = 10
var dotColor = Color(0.9, 0.8, 0.3)
var checkColor = Color(1, 0.1, 0.3)
signal w_capture(piece, value)
signal b_capture(piece, value)
signal check(color)
signal checkmate(color)

func _ready() -> void:
	# Spawn chess pieces on the board
	for row in range(8):
		for col in range(8):
			# Get the chess piece character from the array
			var pieceChar: String = chessBoard[row][col]

			# Spawn the chess piece sprite if it's not an empty cell
			if pieceChar != " ":
				var pieceSprite: Sprite = Sprite.new() 
				pieceSprite.set_name(pieceChar)
				if pieceChar.to_lower() == pieceChar:
					pieceSprite.texture = load("res://sprites/" + pieceChar + ".png")
				else:
					pieceSprite.texture = load("res://sprites/" + pieceChar + "1.png")
				pieceSprite.position = Vector2(col, row) * cellSize - myOffset
				pieceSprite.z_index = 1
				pieceSprite.scale = Vector2(cellSize.x / pieceSprite.texture.get_width(), cellSize.y / pieceSprite.texture.get_height())
				add_child(pieceSprite)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == BUTTON_LEFT and mouse_event.pressed:
			# Get the cell position that was clicked
			var cellX: int = int((mouse_event.position.x) / cellSize.x)
			var cellY: int = int((mouse_event.position.y) / cellSize.y)

			# Generate the name of the chess piece sprite based on the cell position
			#var piece_name: String = chessBoard[cellY][cellX]
			
			var chess_piece: Node = null
			for child in self.get_children():
				var tilex: int = int((child.position.x + myOffset.x) / cellSize.x)
				var tiley: int = int((child.position.y + myOffset.y) / cellSize.y)
				if tiley == cellY and tilex == cellX:
					if child.has_meta("is_dot"):
						if not (child.has_meta("is_self") or child.has_meta("is_check")):
							if chess_piece != null:
								chess_piece = null
							move_selected_piece(child)
							break
					else:
						var child_isWhite = child.name.to_upper()==child.name
						if (whiteTurn and child_isWhite) or (not whiteTurn and not child_isWhite):
							chess_piece = child
							break
			
#			# Debugging Purposes _+_+_+_+_+_+_+_+_
#			for child in self.get_children():
#				# Check if the child is a Label node
#				if child is Label:
#					# Call queue_free() to delete the Label node
#					child.queue_free()
#			# Create a Label node
#			var label = Label.new()
#			# Set the text to display
#			label.text = "Piece: " + piece_name + "\nCellY: " + str(cellY) + "\nCellX: " + str(cellX) + "\nmouseX: " + str(mouse_event.position.x) + "\nmouseY: " + str(mouse_event.position.y)
#			# Add the Label node to the parent node
#			add_child(label)
#			# Debugging Purposes Over _+_+_+_+_+_+_+_+_

			# Get the chess piece sprite by name
#			var chess_piece: Node = get_node(piece_name)

			# Check if the retrieved node is a valid chess piece sprite
			if chess_piece != null and chess_piece is Sprite:
				# Perform actions on the selected chess piece sprite
				set_selected_piece(chess_piece)
			else:
				set_selected_piece()
				lastPiece=null

func _process(_delta: float) -> void:
	if selectedPiece != null:
		if selectedPiece != lastPiece:
			lastPiece = selectedPiece
			# Clear previous dots
			clear_dots()
			# Get selected piece's valid moves
			var validMoves = get_valid_moves(selectedPiece)
			
			# Draw dots on valid move squares
			for move in validMoves:
				draw_dot(move)
			draw_dot(Vector2(int((selectedPiece.position.x + myOffset.x) / cellSize.x), int((selectedPiece.position.y + myOffset.y) / cellSize.y)), true)
	else:
		clear_dots()
	if black_check: emit_signal("check", true)
	elif white_check: emit_signal("check", false)
	else: emit_signal("check", 2)

func move_selected_piece(dot: Sprite) -> void:
	var oldCellX = int((selectedPiece.position.x + myOffset.x) / cellSize.x)
	var oldCellY = int((selectedPiece.position.y + myOffset.y) / cellSize.y)
	var newCellX = int((dot.position.x + myOffset.x) / cellSize.x)
	var newCellY = int((dot.position.y + myOffset.y) / cellSize.y)
	
	var temp1 = dot.position
	clear_dots()
	
	for child in self.get_children():
		var childisblack = child.name.to_lower() == child.name
		var is_black = selectedPiece.name.to_lower() == selectedPiece.name
		
		var tilex: int = int((child.position.x + myOffset.x) / cellSize.x)
		var tiley: int = int((child.position.y + myOffset.y) / cellSize.y)
		if tiley == newCellY and tilex == newCellX:
			print(child.name)
			for p in chessPieces:
				if p in child.name.to_lower():
					var v = chessPieces[p]
					if childisblack:
						emit_signal("w_capture", p, v)
					else:
						emit_signal("b_capture", p, v)
					break
			child.queue_free()
#			break
		if child.has_meta("passable"):
			child.remove_meta("passable")
			if 'p' in selectedPiece.name.to_lower():
				if childisblack != is_black:
					if tilex == newCellX:
						var direction = 1
						if is_black:
							direction = -1
						var passedSquare = Vector2(newCellX, newCellY) + Vector2(0, direction)
						if passedSquare == Vector2(tilex,tiley):
							if childisblack:
								emit_signal("w_capture", "p", 1)
							else:
								emit_signal("b_capture", "p", 1)
							child.queue_free()
							chessBoard[tiley][tilex] = ' '
#							break
		if child.has_meta("is_check"):
			black_check = false
			white_check = false
			child.queue_free()
	
	if 'p' in selectedPiece.name.to_lower():
		if int(abs(oldCellY-newCellY))==2:
			selectedPiece.set_meta("passable", true)
			
	
	var temp = chessBoard[oldCellY][oldCellX]
	chessBoard[oldCellY][oldCellX] = ' '
	chessBoard[newCellY][newCellX] = temp
	selectedPiece.position = temp1
	
	black_check=false
	white_check=false
	white_checkmate = true
	black_checkmate = true
	for child in self.get_children():
		var childisblack = child.name.to_lower() == child.name
#		if whiteTurn:
#			if not childisblack:
		var moves = get_valid_moves(child)
		if moves and not childisblack: white_checkmate = false
		if moves and childisblack: black_checkmate = false
		var kingPosition = find_piece('k')
		if kingPosition in moves:
			if not childisblack: black_check = true
			else: white_check = true
			draw_dot(kingPosition, false, true)
			break
#		else:
#			if childisblack:
#				var moves = get_valid_moves(child)
#				if moves: black_checkmate = false
#				var kingPosition = find_piece('K')
#				if kingPosition in moves:
#					white_check = true
#					draw_dot(kingPosition, false, true)
#					break
	if white_checkmate:
		emit_signal("checkmate", false)
	elif black_checkmate:
		emit_signal("checkmate", true)
	selectedPiece = null
	lastPiece = null
	
	whiteTurn = not whiteTurn
	

func set_selected_piece(piece: Sprite=null) -> void:
	selectedPiece = piece

func clear_dots() -> void:
	# Remove all child nodes that are dots
	for child in get_children():
		if child.has_meta("is_dot") and not child.has_meta("is_check"):
			child.queue_free()

func draw_dot(square: Vector2, dark: bool=false, check: bool=false) -> void:
	# Create a new dot Sprite
	var dot = Sprite.new()
	dot.texture = load("res://sprites/Dot.png")  # Set dot texture
	dot.position = square * cellSize - myOffset # Set dot position based on square
	dot.scale = Vector2(dotSize, dotSize) / cellSize  # Set dot scale based on dot size and cell size
	
	if dark:
		dot.modulate = dotColor  # Set dot color
		dot.self_modulate = dotColor
		dot.set_meta("is_self", true)
		
	if check:
		dot.modulate = checkColor  # Set dot color
		dot.self_modulate = checkColor
		dot.set_meta("is_check", true)
	
	# Set a metadata flag to identify the dot
	dot.set_meta("is_dot", true)
	
	# Add dot as a child of this Node2D
	add_child(dot)

func get_valid_moves(piece) -> Array:
	var validMoves = []
	var cellX: int = int((piece.position.x + myOffset.x) / cellSize.x)
	var cellY: int = int((piece.position.y + myOffset.y) / cellSize.y)
	var currentSquare = Vector2(cellX, cellY)
	var direction = -1  # Assuming the pawn moves towards the positive y-axis (up the board)
	var is_black
	
	is_black = piece.name == piece.name.to_lower()
	
	if is_black:  # Assuming the pawn has a `is_black` boolean property that indicates its color
		direction = 1  # If the pawn is black, it moves towards the negative y-axis (down the board)
	
	if 'p' in piece.name.to_lower():
		# Check for valid moves diagonally for capturing opponent's pieces
		var leftCapture = currentSquare + Vector2(-1, direction)
		var rightCapture = currentSquare + Vector2(1, direction)
		var leftPassant = currentSquare + Vector2(-1, 0)
		var rightPassant = currentSquare + Vector2(1, 0)
		
		# Check if left capture is valid
		if is_valid_square(leftCapture):
			var leftCapturePiece = get_piece_on_square(leftCapture)
			var lcpColor = leftCapturePiece.to_lower()==leftCapturePiece
			if leftCapturePiece != ' ' and lcpColor != is_black:
				if is_black:
					var potential_board = chessBoard.duplicate()
					potential_board[leftCapture.y][leftCapture.x] = potential_board[currentSquare.y][currentSquare.x]
					potential_board[currentSquare.y][currentSquare.x] = ' '
					var king_pos: Vector2 = find_piece('k')
					if not is_in_check(potential_board, king_pos):
						validMoves.append(leftCapture)
				elif (not is_black):
					var potential_board = chessBoard.duplicate()
					potential_board[leftCapture.y][leftCapture.x] = potential_board[currentSquare.y][currentSquare.x]
					potential_board[currentSquare.y][currentSquare.x] = ' '
					var king_pos: Vector2 = find_piece('K')
					if not is_in_check(potential_board, king_pos):
						validMoves.append(leftCapture)
				
			var passantLeft = get_piece_on_square(leftPassant)
			var lPColor = passantLeft.to_lower()==passantLeft
			if passantLeft != ' ' and lPColor != is_black:
				for child in self.get_children():
					var tilex: int = int((child.position.x + myOffset.x) / cellSize.x)
					var tiley: int = int((child.position.y + myOffset.y) / cellSize.y)
					if tiley == leftPassant.y and tilex == leftPassant.x:
						if child.has_meta("passable"):
							if is_black:
								var potential_board = chessBoard.duplicate()
								potential_board[leftCapture.y][leftCapture.x] = potential_board[currentSquare.y][currentSquare.x]
								potential_board[currentSquare.y][currentSquare.x] = ' '
								potential_board[leftPassant.y][leftPassant.x] = ' '
								var king_pos: Vector2 = find_piece('k')
								if not is_in_check(potential_board, king_pos):
									validMoves.append(leftCapture)
							elif (not is_black):
								var potential_board = chessBoard.duplicate()
								potential_board[leftCapture.y][leftCapture.x] = potential_board[currentSquare.y][currentSquare.x]
								potential_board[currentSquare.y][currentSquare.x] = ' '
								potential_board[leftPassant.y][leftPassant.x] = ' '
								var king_pos: Vector2 = find_piece('K')
								if not is_in_check(potential_board, king_pos):
									validMoves.append(leftCapture)
				
		# Check if right capture is valid
		if is_valid_square(rightCapture):
			var rightCapturePiece = get_piece_on_square(rightCapture)
			var rcpColor = rightCapturePiece.to_lower()==rightCapturePiece
			if rightCapturePiece != ' ' and rcpColor != is_black:
				if is_black:
					var potential_board = chessBoard.duplicate()
					potential_board[rightCapture.y][rightCapture.x] = potential_board[currentSquare.y][currentSquare.x]
					potential_board[currentSquare.y][currentSquare.x] = ' '
					var king_pos: Vector2 = find_piece('k')
					if not is_in_check(potential_board, king_pos):
						validMoves.append(rightCapture)
				elif (not is_black):
					var potential_board = chessBoard.duplicate()
					potential_board[rightCapture.y][rightCapture.x] = potential_board[currentSquare.y][currentSquare.x]
					potential_board[currentSquare.y][currentSquare.x] = ' '
					var king_pos: Vector2 = find_piece('K')
					if not is_in_check(potential_board, king_pos):
						validMoves.append(rightCapture)
				
			var passantRight = get_piece_on_square(rightPassant)
			var rPColor = passantRight.to_lower()==passantRight
			if passantRight != ' ' and rPColor != is_black:
				for child in self.get_children():
					var tilex: int = int((child.position.x + myOffset.x) / cellSize.x)
					var tiley: int = int((child.position.y + myOffset.y) / cellSize.y)
					if tiley == rightPassant.y and tilex == rightPassant.x:
						if child.has_meta("passable"):
							if is_black:
								var potential_board = chessBoard.duplicate()
								potential_board[rightCapture.y][rightCapture.x] = potential_board[currentSquare.y][currentSquare.x]
								potential_board[currentSquare.y][currentSquare.x] = ' '
								potential_board[rightPassant.y][rightPassant.x] = ' '
								var king_pos: Vector2 = find_piece('k')
								if not is_in_check(potential_board, king_pos):
									validMoves.append(rightCapture)
							elif (not is_black):
								var potential_board = chessBoard.duplicate()
								potential_board[rightCapture.y][rightCapture.x] = potential_board[currentSquare.y][currentSquare.x]
								potential_board[currentSquare.y][currentSquare.x] = ' '
								potential_board[rightPassant.y][rightPassant.x] = ' '
								var king_pos: Vector2 = find_piece('K')
								if not is_in_check(potential_board, king_pos):
									validMoves.append(rightCapture)
		
		# Check for valid moves one square forward
		var forwardMove = currentSquare + Vector2(0, direction)
		if is_valid_square(forwardMove) and get_piece_on_square(forwardMove) == ' ':
			if is_black:
				var potential_board = chessBoard.duplicate()
				potential_board[forwardMove.y][forwardMove.x] = potential_board[currentSquare.y][currentSquare.x]
				potential_board[currentSquare.y][currentSquare.x] = ' '
				var king_pos: Vector2 = find_piece('k')
				if not is_in_check(potential_board, king_pos):
					validMoves.append(forwardMove)
			elif (not is_black):
				var potential_board = chessBoard.duplicate()
				potential_board[forwardMove.y][forwardMove.x] = potential_board[currentSquare.y][currentSquare.x]
				potential_board[currentSquare.y][currentSquare.x] = ' '
				var king_pos: Vector2 = find_piece('K')
				if not is_in_check(potential_board, king_pos):
					validMoves.append(forwardMove)
			# Check for valid moves two squares forward from starting position
			var startingPosition = (1 if is_black else 6)  # Assuming the pawn starts at row 1 for white, row 6 for black
			if currentSquare.y == startingPosition:
				var doubleForwardMove = currentSquare + Vector2(0, direction * 2)
				if is_valid_square(doubleForwardMove) and get_piece_on_square(doubleForwardMove) == ' ':
					if is_black:
						var potential_board = chessBoard.duplicate()
						potential_board[doubleForwardMove.y][doubleForwardMove.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('k')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(doubleForwardMove)
					elif (not is_black):
						var potential_board = chessBoard.duplicate()
						potential_board[doubleForwardMove.y][doubleForwardMove.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('K')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(doubleForwardMove)
	
	elif 'b' in piece.name.to_lower():
		# Define the possible directions for bishop movement
		var directions = [
			Vector2(-1, -1),  # Top-left diagonal
			Vector2(1, -1),   # Top-right diagonal
			Vector2(-1, 1),   # Bottom-left diagonal
			Vector2(1, 1),    # Bottom-right diagonal
		]
		
		# Iterate through each direction and check for valid moves
		for dir in directions:
			var nextSquare = currentSquare + dir
			while is_valid_square(nextSquare):
				var pieceOnNextSquare = get_piece_on_square(nextSquare)
				if pieceOnNextSquare == ' ':
					# If the square is empty, add it as a valid move
					if is_black:
						var potential_board = chessBoard.duplicate()
						potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('k')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(nextSquare)
					elif (not is_black):
						var potential_board = chessBoard.duplicate()
						potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('K')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(nextSquare)
				else:
					# If the square has an opponent's piece, capture it and stop checking in this direction
					var ponsColor = pieceOnNextSquare.to_lower()==pieceOnNextSquare
					if ponsColor != is_black:
						if is_black:
							var potential_board = chessBoard.duplicate()
							potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
							potential_board[currentSquare.y][currentSquare.x] = ' '
							var king_pos: Vector2 = find_piece('k')
							if not is_in_check(potential_board, king_pos):
								validMoves.append(nextSquare)
						elif (not is_black):
							var potential_board = chessBoard.duplicate()
							potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
							potential_board[currentSquare.y][currentSquare.x] = ' '
							var king_pos: Vector2 = find_piece('K')
							if not is_in_check(potential_board, king_pos):
								validMoves.append(nextSquare)
					break
				nextSquare += dir  # Move to the next square in the same direction
	
	elif 'n' in piece.name.to_lower():
		# Define the possible knight move offsets
		var moveOffsets = [
			Vector2(-2, -1),  # Two squares up and one square left
			Vector2(-1, -2),  # One square up and two squares left
			Vector2(1, -2),   # One square up and two squares right
			Vector2(2, -1),   # Two squares up and one square right
			Vector2(-2, 1),   # Two squares down and one square left
			Vector2(-1, 2),   # One square down and two squares left
			Vector2(1, 2),    # One square down and two squares right
			Vector2(2, 1),    # Two squares down and one square right
		]
		
		# Iterate through each move offset and check for valid moves
		for offset in moveOffsets:
			var nextSquare = currentSquare + offset
			if is_valid_square(nextSquare):
				var pieceOnNextSquare = get_piece_on_square(nextSquare)
				if pieceOnNextSquare == ' ':
					# If the square is empty, add it as a valid move
					if is_black:
						var potential_board = chessBoard.duplicate()
						potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('k')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(nextSquare)
					elif (not is_black):
						var potential_board = chessBoard.duplicate()
						potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('K')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(nextSquare)
				else:
					# If the square has an opponent's piece, capture it and add as a valid move
					var ponsColor = pieceOnNextSquare.to_lower()==pieceOnNextSquare
					if ponsColor != is_black:
						if is_black:
							var potential_board = chessBoard.duplicate()
							potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
							potential_board[currentSquare.y][currentSquare.x] = ' '
							var king_pos: Vector2 = find_piece('k')
							if not is_in_check(potential_board, king_pos):
								validMoves.append(nextSquare)
						elif (not is_black):
							var potential_board = chessBoard.duplicate()
							potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
							potential_board[currentSquare.y][currentSquare.x] = ' '
							var king_pos: Vector2 = find_piece('K')
							if not is_in_check(potential_board, king_pos):
								validMoves.append(nextSquare)
	
	elif 'q' in piece.name.to_lower():
		# Define the possible directions for queen movement (diagonal, horizontal, and vertical)
		var directions = [
			Vector2(-1, -1),  # Top-left diagonal
			Vector2(1, -1),   # Top-right diagonal
			Vector2(-1, 1),   # Bottom-left diagonal
			Vector2(1, 1),    # Bottom-right diagonal
			Vector2(0, -1),   # Left
			Vector2(0, 1),    # Right
			Vector2(-1, 0),   # Up
			Vector2(1, 0),    # Down
		]
		
		# Iterate through each direction and check for valid moves
		for dir in directions:
			var nextSquare = currentSquare + dir
			while is_valid_square(nextSquare):
				var pieceOnNextSquare = get_piece_on_square(nextSquare)
				if pieceOnNextSquare == ' ':
					# If the square is empty, add it as a valid move
					if is_black:
						var potential_board = chessBoard.duplicate()
						potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('k')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(nextSquare)
					elif (not is_black):
						var potential_board = chessBoard.duplicate()
						potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('K')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(nextSquare)
				else:
					# If the square has an opponent's piece, capture it and stop checking in this direction
					var ponsColor = pieceOnNextSquare.to_lower()==pieceOnNextSquare
					if ponsColor != is_black:
						if is_black:
							var potential_board = chessBoard.duplicate()
							potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
							potential_board[currentSquare.y][currentSquare.x] = ' '
							var king_pos: Vector2 = find_piece('k')
							if not is_in_check(potential_board, king_pos):
								validMoves.append(nextSquare)
						elif (not is_black):
							var potential_board = chessBoard.duplicate()
							potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
							potential_board[currentSquare.y][currentSquare.x] = ' '
							var king_pos: Vector2 = find_piece('K')
							if not is_in_check(potential_board, king_pos):
								validMoves.append(nextSquare)
					break
				nextSquare += dir  # Move to the next square in the same direction
	
	elif 'r' in piece.name.to_lower():
		# Define the possible directions for rook movement (horizontal and vertical)
		var directions = [
			Vector2(0, -1),   # Left
			Vector2(0, 1),    # Right
			Vector2(-1, 0),   # Up
			Vector2(1, 0),    # Down
		]
		
		# Iterate through each direction and check for valid moves
		for dir in directions:
			var nextSquare = currentSquare + dir
			while is_valid_square(nextSquare):
				var pieceOnNextSquare = get_piece_on_square(nextSquare)
				if pieceOnNextSquare == ' ':
					# If the square is empty, add it as a valid move
					if is_black:
						var potential_board = chessBoard.duplicate()
						potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('k')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(nextSquare)
					elif (not is_black):
						var potential_board = chessBoard.duplicate()
						potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
						potential_board[currentSquare.y][currentSquare.x] = ' '
						var king_pos: Vector2 = find_piece('K')
						if not is_in_check(potential_board, king_pos):
							validMoves.append(nextSquare)
				else:
					# If the square has an opponent's piece, capture it and stop checking in this direction
					var ponsColor = pieceOnNextSquare.to_lower()==pieceOnNextSquare
					if ponsColor != is_black:
						if is_black:
							var potential_board = chessBoard.duplicate()
							potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
							potential_board[currentSquare.y][currentSquare.x] = ' '
							var king_pos: Vector2 = find_piece('k')
							if not is_in_check(potential_board, king_pos):
								validMoves.append(nextSquare)
						elif (not is_black):
							var potential_board = chessBoard.duplicate()
							potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
							potential_board[currentSquare.y][currentSquare.x] = ' '
							var king_pos: Vector2 = find_piece('K')
							if not is_in_check(potential_board, king_pos):
								validMoves.append(nextSquare)
					break
				nextSquare += dir  # Move to the next square in the same direction
	
	elif 'k' in piece.name.to_lower():
		# Define the possible directions for king movement (including diagonals)
		var directions = [
			Vector2(0, -1),   # Left
			Vector2(0, 1),    # Right
			Vector2(-1, 0),   # Up
			Vector2(1, 0),    # Down
			Vector2(-1, -1),  # Diagonal left-up
			Vector2(-1, 1),   # Diagonal left-down
			Vector2(1, -1),   # Diagonal right-up
			Vector2(1, 1),    # Diagonal right-down
		]
		
		# Iterate through each direction and check for valid moves
		for dir in directions:
			var nextSquare = currentSquare + dir
			if is_valid_square(nextSquare):
				var pieceOnNextSquare = get_piece_on_square(nextSquare)
				var ponsColor = pieceOnNextSquare.to_lower()==pieceOnNextSquare
				if pieceOnNextSquare == ' ' or ponsColor != is_black:
					# If the square is empty or has an opponent's piece, add it as a valid move
					var potential_board = chessBoard.duplicate()
					potential_board[nextSquare.y][nextSquare.x] = potential_board[currentSquare.y][currentSquare.x]
					potential_board[currentSquare.y][currentSquare.x] = ' '
					if not is_in_check(potential_board, nextSquare):
						validMoves.append(nextSquare)
	
	return validMoves

func is_valid_square(square: Vector2) -> bool:
	var boardSize = 8  # Assuming the chessboard size is 8x8

	# Check if the square is within the chessboard bounds
	if square.x >= 0 and square.x < boardSize and square.y >= 0 and square.y < boardSize:
		return true
	else:
		return false

func get_piece_on_square(square: Vector2) -> String:
	return chessBoard[square.y][square.x]

func find_piece(piece: String) -> Vector2:
	for row in range(8):
	# Iterate through columns
		for col in range(8):
			# Check if the element at the current row and column is the desired character
			if chessBoard[row][col] == piece:
				# Return the row and column index as a Vector2
				return Vector2(col, row)

	# If the character is not found, return an invalid Vector2
	return Vector2(-1, -1)

const DIRECTIONS = [
	Vector2(0, -1),   # Up
	Vector2(0, 1),    # Down
	Vector2(-1, 0),   # Left
	Vector2(1, 0),    # Right
	Vector2(-1, -1),  # Up-Left
	Vector2(-1, 1),   # Down-Left
	Vector2(1, -1),   # Up-Right
	Vector2(1, 1),    # Down-Right
]
const KNIGHT_MOVES: Array = [
	Vector2(1, 2),
	Vector2(2, 1),
	Vector2(-1, 2),
	Vector2(-2, 1),
	Vector2(1, -2),
	Vector2(2, -1),
	Vector2(-1, -2),
	Vector2(-2, -1)
]


# Function to check if the king is in check
func is_in_check(board: Array, king_pos: Vector2) -> bool:
	# Define the enemy player
	var is_black = false
	var p = board[king_pos.y][king_pos.x]
	if p.to_lower() == p: is_black = true 
	
	# Check for threats from enemy knights
	for i in range(8):
		var next_pos = king_pos + KNIGHT_MOVES[i]
		if is_valid_square(next_pos):
			var next_piece = board[int(next_pos.y)][int(next_pos.x)]
			var npBlack = next_piece.to_lower()==next_piece
			if next_piece.to_lower() == 'n' and (npBlack != is_black):
				return true
	
	# Check for threats from enemy bishops, rooks, and queens
	for i in range(8):
		var current_pos = king_pos + DIRECTIONS[i]
		while is_valid_square(current_pos):
			var curr_piece = board[int(current_pos.y)][int(current_pos.x)]
			var lower_curr = curr_piece.to_lower()
			var is_enemy = (lower_curr == curr_piece) != is_black
			if curr_piece != ' ':
				if is_enemy and lower_curr == 'b' and i in [4, 5, 6, 7]:
					return true
				elif is_enemy and lower_curr == 'r' and i in [0, 1, 2, 3]:
					return true
				elif is_enemy and lower_curr == 'q':
#					if i in [0, 1, 2, 3] or i in [4, 5, 6, 7]:
						return true
				break
			current_pos += DIRECTIONS[i]
	
	# Check for threats from enemy pawns
	var pawn_attacks = [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]
	for i in range(4):
		var next_pos = king_pos + pawn_attacks[i]
		if not is_valid_square(next_pos):
			continue
		var next_piece = board[int(next_pos.y)][int(next_pos.x)]
		var lower_next = next_piece.to_lower()
		var is_enemy = (lower_next == next_piece) != is_black
		if lower_next == 'p' and is_enemy:
			return true
	
	#Check for threats from enemy kings
	for dir in DIRECTIONS:
		var next_pos = Vector2((king_pos.x + dir.x), (king_pos.y + dir.y))
		if not is_valid_square(next_pos):
			continue
		if board[next_pos.y][next_pos.x].to_lower()=='k':
			var is_enemy = (board[next_pos.y][next_pos.x] == board[next_pos.y][next_pos.x].to_lower()) != is_black
			return true
	
	# If no threats are found, the king is not in check
	return false

