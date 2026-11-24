# Instrucciones: add, sub, and, or, slt, slti, sll, srl, addi, addiu, addu, andi, ori, lui, syscall, $zero
# - add, sub: positivos y al menos un operando negativo
# - and, or: operandos con unos en los 16 bits altos
# - slt, slti: resultado 1 y 0; operando negativo donde con signo y sin signo difieren
# - sll, srl: shamt=0 y shamt!=0 con srl sobre valor negativo (entran ceros)
# - addi: inmediato negativo; addiu, addu: via li (-2^15..2^15-1) y move
# - andi, ori, lui: inmediato con bit 15 = 1 (andi/ori extienden con ceros)
# - syscall: servicios 11 y 10; $zero: intenta escribir y comprueba que sigue en 0


.data

.text
main:
    # li y move -> addiu y addu
    li   $t0, 20
    li   $t1, -6
    move $t2, $t1

    # add y sub con positivos y negativos
    add  $s0, $t0, $t1      # 14 (0x0000000E)
    sub  $s1, $t1, $t0      # -26 (0xFFFFFFE6)
    addi $s2, $t0, -25      # -5 (0xFFFFFFFB)

    # and / or con 16 bits altos en 1; andi / ori / lui con bit 15 en 1
    lui  $t3, 0x8000        # 0x80000000 (bit 15 del imm = 1)
    ori  $t4, $t3, 0x8005   # 0x80008005 (zero-ext en ori)
    andi $t5, $t4, 0x8001   # 0x00008001 (zero-ext en andi)
    or   $s3, $t4, $t3      # 0x80008005
    and  $s4, $t4, $t5      # 0x00008001

    # slt y slti: 1 y 0, incluyendo caso donde signo vs sin signo difieren (-6 < 20 es 1 con signo, 0 sin signo)
    slt  $s5, $t1, $t0      # 1
    slt  $s6, $t0, $t1      # 0
    slti $s7, $t1, 0        # 1 (-6 < 0)

    # sll y srl: shamt=0 y shamt!=0 sobre negativo (-6 -> ceros a la izquierda)
    sll  $t6, $t1, 0        # -6 (0xFFFFFFFA)
    srl  $t7, $t1, 0        # -6 (0xFFFFFFFA)
    srl  $t8, $t1, 4        # 0x0FFFFFFF

    # Escritura en $zero y comprobacion de que vale 0
    addi $zero, $t0, 77
    add  $t9, $zero, $zero  # 0x00000000

    # Imprimir 4 lineas cortas en hex (cabe en 12x48)
    move $a0, $s0
    jal  print_hex
    move $a0, $s1
    jal  print_hex
    move $a0, $t8
    jal  print_hex
    move $a0, $t9
    jal  print_hex

    li   $v0, 10
    syscall

print_hex:
    move $a2, $a0
    li   $a3, 28
p_loop:
    srl  $a0, $a2, 28
    andi $a0, $a0, 0x0F
    slti $a1, $a0, 10
    beq  $a1, $zero, p_alpha
    addi $a0, $a0, 48
    j    p_out
p_alpha:
    addi $a0, $a0, 55
p_out:
    li   $v0, 11
    syscall
    sll  $a2, $a2, 4
    addi $a3, $a3, -4
    bge  $a3, $zero, p_loop
    li   $a0, 10
    li   $v0, 11
    syscall
    jr   $ra



