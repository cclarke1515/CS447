# Connor Clarke 	cmc240

# set to 1 to show solution after generating puzzle, so the grader can properly test.
# (and so can you, really)
.eqv GRADER_MODE 1

.macro print_str %str
	.data
	print_str_message: .asciiz %str
	.text
	push a0
	push v0
	la a0, print_str_message
	li v0, 4
	syscall
	pop v0
	pop a0
.end_macro

.eqv INVALID -1
.eqv RED      0
.eqv GREEN    1
.eqv BLUE     2
.eqv YELLOW   3
.eqv ORANGE   4
.eqv PURPLE   5

.eqv MIN_COLORS  3
.eqv MAX_COLORS  6
.eqv PUZZLE_SIZE 4
.eqv NUM_TRIES   10

.eqv INPUT_SIZE 100

.data
	color_names:  .asciiz "rgbyop"    # indexed by color constants

	playing:      .word 0             # bool - keep playing?
	player_won:   .word 0             # bool - did they win?
	num_colors:   .word 0             # how many colors (difficulty level)
	tries_left:   .word 0             # how many tries the player has remaining

	str_input:    .byte 0:INPUT_SIZE  # string input buffer

	puzzle:       .byte 0:PUZZLE_SIZE # the solution
	guess:        .byte 0:PUZZLE_SIZE # the player's guess
	puzzle_cross: .byte 0:PUZZLE_SIZE # used by check_guess
	guess_cross:  .byte 0:PUZZLE_SIZE # "
.text

# -------------------------------------
.global main
main:
	# while playing...
	_loop:
		jal ask_for_num_colors
		jal generate_puzzle
		jal show_solution_to_grader
		jal play_game
		jal game_over_message
		jal ask_play_again
	lw  t0, playing
	bne t0, 0, _loop

	# exit
	li v0, 10
	syscall

# -------------------------------------
# prompts user for number of colors and sets num_colors to a value in the range
# [MIN_COLORS, MAX_COLORS].
ask_for_num_colors:
	
	lw s0, num_colors
	blt s0, MIN_COLORS, _loop		# if t0 is less than 3 go to loop
	bgt s0, MAX_COLORS, _loop		# if t0 is greater than 6 go to loop
	
	_loop:
		print_str "How many colors?: "
		li v0, 5
		syscall				# get user input. currently stored in v0
		sw v0, num_colors		# store input into num_colors
		move s0, v0			# copy v0 into s0 to check if it is in range
		
		blt s0, MIN_COLORS, _loop	# check if statement again
		bgt s0, MAX_COLORS, _loop	# ^^^^^^^^^^^^^^^^^^^^^^^^
		
jr ra

# -------------------------------------
# fills puzzle with PUZZLE_SIZE colors, randomly selected from the range [0 .. num_colors).
generate_puzzle:
	
	li s0, 0				# reset counter
	blt s0, PUZZLE_SIZE, _loop		# for ( int i = 0; i < PUZZLE_SIZE; i++ )
	
	_loop:
		li a0, 0			# set lower bound
		lb a1, num_colors		# set upper bound
		li v0, 42
		syscall				# get random integer
		la t1, puzzle			# t1 = A
		add t1, t1, s0			# t1 = A + Si
		sb v0, (t1)			# store random int into puzzle[i]
		
		add s0, s0, 1			# i++
		blt s0, PUZZLE_SIZE, _loop	# jump back to top of loop if not equal to puzzle size
		
jr ra

# -------------------------------------
# if we're in grader mode, show the puzzle solution.
show_solution_to_grader:

push ra						# needed for jal

	li s0, 0
	beq s0, GRADER_MODE, _next		# empty bc no actual loop needed
	print_str "(SOLUTION: "
	jal show_solution			# jump to show_solution
	print_str ")\n"
	
	_next:
		# monke

pop ra						# needed for jal
	
jr ra


# -------------------------------------
# show the puzzle solution as text (e.g. rggb)
show_solution:
	
	li s0, 0				# reset counter
	blt s0, PUZZLE_SIZE, _loop		# for ( int i = 0; i < PUZZLE_SIZE; i++ )
	
	_loop:
		# PUZZLE ARRAY
		la t1, puzzle			# t1 = A
		add t1, t1, s0			# no mul needed so t1 = A + Si
		lb v0, (t1)
		
		# COLOR ARRAY	
		la t2, color_names		# load color_names
		add t2, t2, v0			# add from puzzle array
		lb a0, (t2)			# load total into a0
		li v0, 11
		syscall
		
		add s0, s0, 1			# i++
		blt s0, PUZZLE_SIZE, _loop	# jump back to top
	
jr ra

# -------------------------------------
# play one round of the game.
play_game:

li t0, 0

push ra
push s0
    
    	add t0, zero, zero			
    	sw t0, player_won			# player_won = false
    	
    	li s0, NUM_TRIES			# load number of tries
    	li a0, PUZZLE_SIZE			# do this so _looper doesn't trigger
    	
    	_loop:
    		sw s0, tries_left
    		ble s0, 0, _break		# while (tries_left > 0)
    		jal game_prompt			# input comes back in v0
    		
    		bne v0, PUZZLE_SIZE, _looper	# while (game_prompt() != PUZZLE_SIZE)
    		
    		jal convert_guess
    		
    		beq v0, 1, _check		# if (true)
    		
    	_looper:
    		print_str "Enter "
    		li a0, PUZZLE_SIZE
    		li v0, 1
    		syscall				# print puzzle size
    		print_str " letters.\n"
    		j _loop
    		
    	_check:
    		jal check_guess
    		lw t0, player_won
    		beq t0, zero, _elser		# incorrect guess
    		beq t0, 1, _break		# correct guess
    		
    	_elser:
    		sub s0, s0, 1			# tries_left--
    		
    		bgt s0, zero, _loop
    		
    	_else:	
		print_str "Invalid guess.\n"
		j _loop
		
	_break:
		#monke
pop s0		
pop ra

jr ra

# -------------------------------------
# shows how many tries remain and gets the user's guess.
# returns the length of the user's input.
game_prompt:
	
push ra

	print_str "("
	lw a0, tries_left			# load tries_left
	li v0, 1			
	syscall
	print_str " tries remaining) Enter your guess: "
	jal read_line
	
pop ra

jr  ra

# -------------------------------------
# loops over str_input and converts the characters to colors, filling in the "guess" array.
# assumes length of str_input == PUZZLE_SIZE.
# returns true (1) if it was a valid guess, and false (0) if not.
convert_guess:

push ra
push s0

	li s0, 0
	blt s0, PUZZLE_SIZE, _loop
	
	_loop:
		la t1, str_input		# load str_input into t1
		add t1, t1, s0
		lb a0, (t1)			# a0 will send to char_to_color in place of 'c'
		jal char_to_color		# char_to_color(str_input[i])
		
		beq v0, INVALID, _if		# if v0 came back invalid send to _if
		lw t3, num_colors
		bge v0, t3, _if			# if v0 is greater than num_colors send to _if
		blt v0, t3, _else		# ^ else go to _else
		
	_if:
		li v0, 0			# 0 = false
		j _break
		
	_else:
		la t2, guess			# load guess[]
		add t2, t2, s0
		sb v0, (t2)			# store color into guess[i]
		li v0, 1			# 1 = true
		
		add s0, s0, 1
		blt s0, PUZZLE_SIZE, _loop

_break:
pop s0		
pop ra
		
jr  ra

# -------------------------------------
# int char_to_color(char c)
# returns the character constant for the given character, or INVALID if it's invalid.
char_to_color:
				
	beq a0, 'r', _RED
	beq a0, 'R', _RED
	beq a0, 'g', _GREEN
	beq a0, 'G', _GREEN
	beq a0, 'b', _BLUE
	beq a0, 'B', _BLUE
	beq a0, 'y', _YELLOW
	beq a0, 'Y', _YELLOW
	beq a0, 'o', _ORANGE
	beq a0, 'O', _ORANGE
	beq a0, 'p', _PURPLE
	beq a0, 'P', _PURPLE
	j _default
	
	_RED:
		li v0, RED
		jr ra
		
	_GREEN:
		li v0, GREEN
		jr ra
		
	_BLUE:
		li v0, BLUE
		jr ra
		
	_YELLOW:
		li v0, YELLOW
		jr ra
		
	_ORANGE:
		li v0, ORANGE
		jr ra
		
	_PURPLE:
		li v0, PURPLE
		jr ra
		
	_default:
		li v0, INVALID			# -1 is invalid
		jr ra

# -------------------------------------
# shows win/lose message (and the solution if they lost).
game_over_message:
	
	lw t0, player_won
	beq t0, 1, _winner
	beq t0, zero, _loser
	
	_winner:
		print_str "That's right! You win!\n"
		jr ra
		
	_loser:
		print_str "Sorry, you're out of guesses...\nThe solution was: "
		push ra
		jal show_solution
		pop ra
		print_str "\n"
		
jr ra

# -------------------------------------
# ask if they want to play again, and sets the 'playing' variable accordingly
ask_play_again:
	
	_again:
		print_str "Play again (y/n)?: "
		li v0, 12
		syscall
		
		# SWITCH CASE YES
		beq v0, 'y', _player
		beq v0, 'Y', _player
		
		# SWITCH CASE NO
		beq v0, 'n', _quit
		beq v0, 'N', _quit
		
		bne t0, zero, _again		# while true
		
		j _default
		
	_player:
		add t0, zero, 1
		sw t0, playing
		print_str "\n"
		jr ra
		
	_quit:
		add t0, zero, zero
		sw t0, playing
		jr ra
		
	_default:
	
jr ra

# --------------------------------------------------------------------------------------------------
# DO NOT CHANGE ANYTHING BELOW THIS LINE! THERE IS NO REASON FOR YOU TO CHANGE ANYTHING BELOW!
# --------------------------------------------------------------------------------------------------

# -------------------------------------
# void check_guess()
# compares guess to puzzle. if they match exactly, sets player_won to true (1).
# otherwise, shows how many exact and inexact matches there are.
# this algorithm is frustratingly subtle and complicated, for such a simple game...
check_guess:
push s0
	# reset the cross arrays
	li t9, 0
	_clear_loop:
		sb zero, puzzle_cross(t9)
		sb zero, guess_cross(t9)
	add t9, t9, 1
	blt t9, PUZZLE_SIZE, _clear_loop

	# count of matches = 0
	li s0, 0

	# 1. find exact matches
	# for i:t9 = 0 to PUZZLE_SIZE
	li t9, 0
	_exact_loop:
		# if guess[i] == puzzle[i],
		lb t0, guess(t9)
		lb t1, puzzle(t9)
		bne t0, t1, _differ
			# cross both off
			li   t0, 1
			sb   t0, puzzle_cross(t9)
			sb   t0, guess_cross(t9)
			# count++
			add  s0, s0, 1
		_differ:
	add t9, t9, 1
	blt t9, PUZZLE_SIZE, _exact_loop

	# if all places guessed right, they win!
	beq s0, PUZZLE_SIZE, _win

	# otherwise, print count of exact matches
	print_str "Right color, right place: "
	move a0, s0
	li v0, 1
	syscall
	print_str "; "

	# 2. find inexact matches.
	# count = 0
	li s0, 0

	# for i:t9 = 0 to PUZZLE_SIZE
	li t9, 0
	_inexact_loop:
		# if not guess_cross[i] (if we haven't already looked at this guess color),
		lb  t0, guess_cross(t9)
		bne t0, 0, _next_i
			# for j:t8 = 0 to PUZZLE_SIZE
			li t8, 0
			_nested:
				# if not puzzle_cross[j] AND guess[i] == puzzle[j],
				lb t0, puzzle_cross(t8)
				bne t0, 0, _next_j
				lb t0, guess(t9)
				lb t1, puzzle(t8)
				bne t0, t1, _next_j
					# cross off guess[i] and puzzle[j]
					li   t0, 1
					sb   t0, puzzle_cross(t8)
					sb   t0, guess_cross(t9)
					# count++
					add  s0, s0, 1
				_next_j:
			add t8, t8, 1
			blt t8, PUZZLE_SIZE, _nested
		_next_i:
	add t9, t9, 1
	blt t9, PUZZLE_SIZE, _inexact_loop

	# print count of inexact matches
	print_str "right color, wrong place: "
	move a0, s0
	li v0, 1
	syscall
	print_str "\n"
	j _return

_win:
	# player_won = true
	li t0, 1
	sw t0, player_won
_return:
pop s0
jr ra

# -------------------------------------
# int strlen(char* str)
# returns number of characters in 0-terminated string.

strlen:
	li v0, 0
	_loop:
		lb  t0, (a0)
		beq t0, 0, _return
		add v0, v0, 1
		add a0, a0, 1
	j _loop
_return:
jr ra

# -------------------------------------
# int read_line()
# reads a line of text into str_input, removing the trailing \n (if any).
# returns the length of the text.

read_line:
push ra
	# read_string(str_input, INPUT_SIZE)
	la a0, str_input
	li a1, INPUT_SIZE
	li v0, 8
	syscall

	# len = strlen(str_input)
	la a0, str_input
	jal strlen

	# if len != 0 && str_input[len - 1] == '\n'
	beq v0, 0, _return
	sub t0, v0, 1
	lb  t1, str_input(t0)
	bne t1, '\n', _return

		# len--
		sub v0, v0, 1
		# str_input[len] = 0
		sb zero, str_input(v0)

	# return len
_return:
pop ra
jr  ra
