# CS 21 M 10 -- S2 AY 2019-2020
# Gerizim Villarante -- 03/08/2020
# main.asm Peg Solitaire

.eqv BOARD_W 7
.eqv BOARD_W2 14
.eqv BOARD_SIZE 49
.eqv PEG 111
# (char)111 = 'o'
.eqv HOLE 46
# (char)46 = '.'
.eqv PEG_LAST 79
# (char)79 = 'O'
.eqv HOLE_LAST 69
# (char)69 = 'E'

.data
yes:		.asciiz "YES"		# string
no:		.asciiz	"NO"		# string
arrow:		.asciiz "->"		# string
board:		.space BOARD_SIZE	# char[][]
		.space 1		# \n or \0 terminated
pegs:		.byte 0			# int8		<= 49
end_coords:	.word 0			# address
moves_size:	.byte 0			# int8		< 49
moves:		.space 196		# int8[moves_size][x, y, p, q] x,y->p,q 	<= 7

.text
.macro print_char(%char)
		li $a0 %char
		li $v0 11
		syscall
.end_macro
.macro print_int_address(%offset, %address)
		lb $a0 %offset(%address)
		li $v0 1
		syscall
.end_macro
.macro print_string_label(%label)
		la $a0 %label
		li $v0 4
		syscall
.end_macro
# main ####################################################
main:		jal get_input
		jal init_board
		jal solve_board

		beqz $v0 then1
		print_string_label(yes)
		print_char('\n')
		jal print_moves		# print moves
		b end1
then1:		print_string_label(no)
end1:		li $v0	10		# end program
		syscall

# print_moves #############################################
# t0 = start moves address	x,y->p,q
# t1 = end moves address

print_moves:	lb $t0 moves_size	# load moves_size
		sll $t0 $t0 2		# moves_size * 4
		la $t1 moves		# load moves address
		add $t0 $t0 $t1
pm_loop:	beq $t0 $t1 pm_end
		print_int_address(-4, $t0)	# print x
		print_char(',')
		print_int_address(-3, $t0)	# print y
		print_string_label(arrow)
		print_int_address(-2, $t0)	# print p
		print_char(',')
		print_int_address(-1, $t0)	# print q
		print_char('\n')
		subi $t0 $t0 4		# decrement move count
		b pm_loop
pm_end:		jr $ra

# solve_board #############################################
# v0 = (bool)solved
		# prologue ################################
solve_board:	subiu $sp $sp 28
		sw $ra 4($sp)
		sw $s0 8($sp)
		sw $s1 12($sp)
		sw $s2 16($sp)
		sw $s3 20($sp)
		sw $s4 24($sp)
		sw $s5 28($sp)
		# base case ###############################
		lb $t0 pegs
		bne $t0 1 sb_body
		lw $t0 end_coords
		lb $t0 ($t0)
		bne $t0 PEG sb_body
		b sb_yes
		# body ####################################	
# s0 = row start (this row start address)
# s1 = row end (last + 1 address)
# s2 = col start (current address)
# s3 = col end (next row start address)
# s4 = row index
# s5 = col index
sb_body:	la $s0 board		# row start
		addi $s1 $s0 BOARD_SIZE	# row end
		move $s4 $zero		# row index
		move $s3 $s0		
sb_row:		addi $s4 $s4 1		# increment row index
		move $s0 $s3		# update row
		beq $s0 $s1 sb_no
		move $s2 $s0		# col start
		addi $s3 $s2 BOARD_W	# col end
		move $s5 $zero		# col index
sb_col:		addi $s5 $s5 1		# increment col index
		beq $s2 $s3 sb_row
		# try moves ###############################
		lb $t0 ($s2)		# check if PEG
		bne $t0 PEG sb_skip_cell# if not a peg continue
.macro make_move (%next_offset, %next_next_offset)
		li $t0 HOLE		# execute move, remove peg from current cell
		sb $t0 0($s2)
		sb $t0 %next_offset($s2)# remove next peg
		li $t0 PEG		# place peg to landing cell
		sb $t0 %next_next_offset($s2)
		lb $t0 pegs		# decrement pegs
		subi $t0 $t0 1
		sb $t0 pegs
.end_macro
.macro reverse_move (%next_offset, %next_next_offset)
		li $t0 PEG		# reverse moves
		sb $t0 0($s2)
		sb $t0 %next_offset($s2)
		li $t0 HOLE
		sb $t0 %next_next_offset($s2)
		lb $t0 pegs		# increment pegs
		addi $t0 $t0 1
		sb $t0 pegs
.end_macro
# sb_right:
		addi $t0 $s2 2		# check if there are 2 cells in right
		bge $t0 $s3 sb_left
		lb $t0 1($s2)		# check if right cell is a peg
		bne $t0 PEG sb_left
		lb $t0 2($s2)		# check if landing cell is a space
		bne $t0 HOLE sb_left
		make_move(1, 2)
		jal solve_board		# recursive call
		beqz $v0 sb_right_rev	# if return is no, reverse moves
		lb $t1 moves_size	# save move
		addi $t2 $t1 1		# increment move_size
		sb $t2 moves_size
		sll $t1 $t1 2
		la $t0 moves
		add $t0 $t0 $t1
		sb $s4 0($t0)		# save row
		sb $s5 1($t0)		# save initial col
		sb $s4 2($t0)		# save row
		addi $t1 $s5 2		# save final col
		sb $t1 3($t0)
		b sb_yes
sb_right_rev:	reverse_move(1, 2)
sb_left:	subi $t0 $s2 2		# check if there are 2 cells in left
		blt $t0 $s0 sb_down
		lb $t0 -1($s2)		# check if left cell is PEG
		bne $t0 PEG sb_down
		lb $t0 -2($s2)		# check if landing cell is HOLE
		bne $t0 HOLE sb_down
		make_move(-1, -2)
		jal solve_board		# recursive call
		beqz $v0 sb_left_rev	# if return is no, reverse moves
		lb $t1 moves_size	# save move
		addi $t2 $t1 1		# increment move_size
		sb $t2 moves_size
		sll $t1 $t1 2
		la $t0 moves
		add $t0 $t0 $t1
		sb $s4 0($t0)		# save row
		sb $s5 1($t0)		# save initial col
		sb $s4 2($t0)		# save row
		subi $t1 $s5 2		# save final col
		sb $t1 3($t0)
		b sb_yes
sb_left_rev:	reverse_move(-1, -2)
sb_down:	addi $t0 $s2 BOARD_W2	# check if there are 2 cells below
		bge $t0 $s1 sb_up
		lb $t0 BOARD_W($s2)	# check if bottom cell is PEG
		bne $t0 PEG sb_up
		lb $t0 BOARD_W2($s2)	# check if landing cell is HOLE
		bne $t0 HOLE sb_up
		make_move(BOARD_W, BOARD_W2)
		jal solve_board		# recursive call
		beqz $v0 sb_down_rev	# if return is no, reverse moves
		lb $t1 moves_size	# save move
		addi $t2 $t1 1		# increment move_size
		sb $t2 moves_size
		sll $t1 $t1 2
		la $t0 moves
		add $t0 $t0 $t1
		sb $s4 0($t0)		# save initial row
		sb $s5 1($t0)		# save col
		addi $t1 $s4 2		# save final row
		sb $t1 2($t0)		
		sb $s5 3($t0)		# save col
		b sb_yes
sb_down_rev:	reverse_move(BOARD_W, BOARD_W2)
sb_up:		subi $t0 $s2 BOARD_W2	# check if there are 2 cells above
		la $t1 board
		blt $t0 $t1 sb_skip_cell
		lb $t0 -BOARD_W($s2)	# check if bottom cell is PEG
		bne $t0 PEG sb_skip_cell
		lb $t0 -BOARD_W2($s2)	# check if landing cell is HOLE
		bne $t0 HOLE sb_skip_cell
		make_move(-BOARD_W, -BOARD_W2)
		jal solve_board		# recursive call
		beqz $v0 sb_up_rev	# if return is no, reverse moves
		lb $t1 moves_size	# save move
		addi $t2 $t1 1		# increment move_size
		sb $t2 moves_size
		sll $t1 $t1 2
		la $t0 moves
		add $t0 $t0 $t1
		sb $s4 0($t0)		# save initial row
		sb $s5 1($t0)		# save col
		subi $t1 $s4 2		# save final row
		sb $t1 2($t0)		
		sb $s5 3($t0)		# save col
		b sb_yes
sb_up_rev:	reverse_move(-BOARD_W, -BOARD_W2)
		###########################################
sb_skip_cell:	addi $s2 $s2 1		# increment col
		j sb_col
sb_no:		li $v0 0		# set return to false
		b sb_epi
sb_yes:		li $v0 1		# set return to true
		# epilogue ################################
sb_epi:		lw $ra 4($sp)
		lw $s0 8($sp)
		lw $s1 12($sp)
		lw $s2 16($sp)
		lw $s3 20($sp)
		lw $s4 24($sp)
		lw $s5 28($sp)
		addiu $sp $sp 28
		jr $ra

# init_board ###############################################
# t0 = current cell
# t1 = last cell + 1
# t2 = peg count
# t3 = cell value
# t4 = cell value to store
init_board:	move $a0 $zero		# reset parameter
		la $t0 board		# address start
		addi $t1 $t0 BOARD_SIZE	# address end
		move $t2 $zero		# peg count
init_board_loop:beq $t0 $t1 init_board_end
		lb $t3 ($t0)		# load char
		bne $t3 PEG init_board_1# if cell is PEG
		addi $t2 $t2 1		# increment peg count
init_board_1:	bne $t3 PEG_LAST init_board_2# if cell is PEG_LAST
		addi $t2 $t2 1		# increment peg count
		sw $t0 end_coords	# store ending address
		li $t4 PEG		# replace cell with PEG
		sb $t4 ($t0)
init_board_2:	bne $t3 HOLE_LAST init_board_3# if cell is HOLE_LAST
		sw $t0 end_coords	# store ending address
		li $t4 HOLE		# replace cell with PEG
		sb $t4 ($t0)
init_board_3:	addi $t0 $t0 1		# increment address by 1 byte
		b init_board_loop
init_board_end:	sb $t2 pegs		# store peg count
		jr $ra

# get_input ###############################################
get_input:	la $t0 board		# address start
		addi $t1 $t0 BOARD_SIZE	# address end
get_input_loop:	beq $t0 $t1 get_input_end
		li $v0 8		# read string
		move $a0 $t0		# pass address
		li $a1 BOARD_W		# pass size
		addi $a1 $a1 2
		syscall
		addi $t0 $t0 BOARD_W	# increment address by 7 bytes
		b get_input_loop
get_input_end:	jr $ra
