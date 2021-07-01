# Connor Clarke
# cmc240

# preserves a0, v0
.macro print_str %str
	# DON'T PUT ANYTHING BETWEEN .macro AND .end_macro!!
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

# -------------------------------------------
.eqv ARR_LENGTH 5
.data
	arr: .word 100, 200, 300, 400, 500
	message: .asciiz "testing!"
.text
# -------------------------------------------
.globl main
main:
	jal input_arr
	jal print_arr
	la a0, message
	jal print_chars
	# exit()
	li v0, 10
	syscall
# -------------------------------------------
input_arr:
	blt t3, ARR_LENGTH, _loop
	
	_loop:
		print_str "enter value: "
		li v0, 5
		syscall
		la t1, arr
		mul t2, t3, 4
		add t1, t1, t2
		sw v0, (t1)		# store input
		 
		add t3, t3, 1		# i++
		blt t3, ARR_LENGTH, input_arr
			
	jr ra
	
print_arr:
	blt t0, ARR_LENGTH, _top
	
	_top:
		print_str "arr["
		move a0, t0		# a0 = i 
		li v0, 1
		syscall			# print i value
		print_str "] = "
		la t1, arr		# t1 = A
		mul t2, t0, 4		# t2 = S * i
		add t1, t1, t2		# t1 NOW = A + Si
		lw a0, (t1)		# a0 = arr[i]
		syscall			# print arr[i]
		print_str "\n"
		
		add t0, t0, 1		# i++
		blt t0, ARR_LENGTH, print_arr	
	
	jr ra
	
print_chars:
	la t0, message			# t0 = message
	bne t1, zero, _test
	
	_test:
		lb t1, (t0)		# t1 = byte
		lb a0, (t0)		# store byte into a0
		li v0, 11
		syscall
		print_str "\n"
		
		add t0, t0, 1		# t0++
		bne t1, zero, _test
	
	jr ra
	
