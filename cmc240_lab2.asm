# Connor Clarke
# cmc240

# preserves a0, v0
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

.data
	display: .word 0
	operation: .byte 0

.text

.globl main
main:
	print_str "Hello! Welcome!\n"
	
_loop:
	lw a0, display
	li v0, 1
	syscall
	print_str "\nOperation (=,+,-,*,/,c,q): "
	li v0, 12
	syscall
	sb v0, operation
	# switch case
	lb t0, operation
	beq t0, 'q', _quit
	beq t0, 'c', _clear
	beq t0, '=', _equals
	beq t0, '+', _plus
	beq t0, '-', _minus
	beq t0, '*', _mult
	beq t0, '/', _div
	j _default
	
	_quit:
		li v0, 10
		syscall
		j _break
	
	_clear:
		print_str "\n"
		sw zero, display
		j _break
		
	_equals:
		print_str "\nValue: "
		li v0, 5
		syscall
		sw v0, display
		j _break
		
	_plus:
		print_str "\nValue: "
		li v0, 5
		syscall
		lw t0, display
		add t0, t0, v0
		sw t0, display
		j _break
	
	_minus:
		print_str "\nValue: "
		li v0, 5
		syscall
		lw t0, display
		sub t0, t0, v0
		sw t0, display
		j _break
	
	_mult:
		print_str "\nValue: "
		li v0, 5
		syscall
		lw t0, display		# set display to variable
		mul t0, t0, v0		# mult display and input
		sw t0, display 		# set product to display
		j _break
	
	_div:
		print_str "\nValue: "
		bne t0, v0, _zero
		li v0, 5
		syscall
		lw t0, display
		div t0, t0, v0
		sw t0, display
		j _break
		
	_zero:
		print_str "Cannot divide by zero"
		j _break
		
	_default:
		print_str "Huh?\n"
		
_break:
	j _loop
	
