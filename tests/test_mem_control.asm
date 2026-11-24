# Instrucciones: lw, sw, lb, lbu, sb, beq, bne, j, jal, jr, syscall
# - lw, sw: desplazamiento positivo y negativo
# - lb, lbu: byte con bit 7 = 1 en al menos dos posiciones distintas (d[1:0] distinto)
# - sb: en las 4 posiciones (0,1,2,3) de una palabra, comprobando con lw que los otros bytes no cambian
# - beq, bne: cada uno tomado y no tomado; al menos un salto hacia atras
# - j: al menos una vez; jal, jr: procedimiento no hoja guardando $ra en pila; syscall 11 y 10

.data
word_area: .word 0x11223344
byte_src:  .byte 0x81, 0x92, 0xA3, 0xB4

.text
main:
    # lw y sw con desplazamiento positivo y negativo
    la   $t0, word_area
    li   $t1, 0x12345678
    sw   $t1, 4($t0)        # desplazamiento positivo (+4)
    lw   $s0, 4($t0)
    sw   $s0, -4($s1)       # usa base desplazada y lee con offset negativo
    addi $t2, $t0, 8
    sw   $t1, -4($t2)       # desplazamiento negativo (-4) sobre word_area+4
    lw   $s1, -4($t2)

    # sb en las 4 posiciones (0,1,2,3) de una misma palabra y comprobacion con lw
    li   $t3, 0x00000000
    sw   $t3, 0($t0)
    li   $t4, 0xA1
    sb   $t4, 0($t0)        # d[1:0] = 0
    li   $t4, 0xB2
    sb   $t4, 1($t0)        # d[1:0] = 1
    li   $t4, 0xC3
    sb   $t4, 2($t0)        # d[1:0] = 2
    li   $t4, 0xD4
    sb   $t4, 3($t0)        # d[1:0] = 3
    lw   $s2, 0($t0)        # debe ser 0xD4C3B2A1

    # lb y lbu sobre bytes con bit 7 = 1 en dos posiciones distintas
    la   $t5, byte_src
    lb   $s3, 1($t5)        # d[1:0] = 1, con signo -> 0xFFFFFF92
    lbu  $s4, 2($t5)        # d[1:0] = 2, sin signo -> 0x000000A3

    # beq y bne: no tomado, tomado y salto hacia atras + j
    li   $t6, 5
    li   $t7, 9
    beq  $t6, $t7, fail_path # no tomado
    bne  $t6, $t6, fail_path # no tomado
    li   $t8, 0
back_loop:
    addi $t8, $t8, 1
    bne  $t8, 2, back_loop  # salto hacia atras tomado
    beq  $t8, $t8, ok_beq   # tomado
fail_path:
    li   $s5, 0xDEAD
    j    after_branch
ok_beq:
    li   $s5, 0x0001
after_branch:
    j    call_nested

call_nested:
    jal  outer_proc
    move $s6, $v1           # resultado de procedimiento no hoja
    j    print_res

outer_proc:
    addi $sp, $sp, -8
    sw   $ra, 4($sp)
    sw   $s0, 0($sp)
    addi $a0, $zero, 3
    jal  inner_proc
    addi $v1, $v0, 10       # 6 + 10 = 16 (0x00000010)
    lw   $s0, 0($sp)
    lw   $ra, 4($sp)
    addi $sp, $sp, 8
    jr   $ra

inner_proc:
    add  $v0, $a0, $a0      # 3 + 3 = 6
    jr   $ra

print_res:
    move $a0, $s2
    jal  print_hex
    move $a0, $s3
    jal  print_hex
    move $a0, $s4
    jal  print_hex
    move $a0, $s6
    jal  print_hex

    li   $v0, 10
    syscall

print_hex:
    move $a2, $a0
    li   $a3, 28
h_loop:
    srl  $a0, $a2, 28
    andi $a0, $a0, 0x0F
    slti $a1, $a0, 10
    beq  $a1, $zero, h_alpha
    addi $a0, $a0, 48
    j    h_out
h_alpha:
    addi $a0, $a0, 55
h_out:
    li   $v0, 11
    syscall
    sll  $a2, $a2, 4
    addi $a3, $a3, -4
    bge  $a3, $zero, h_loop
    li   $a0, 10
    li   $v0, 11
    syscall
    jr   $ra