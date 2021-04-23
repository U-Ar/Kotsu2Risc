main:
addi s2, zero, 5
addi s3, zero, 12
addi s7, s3, -9
or s4, s7, s2
and s5, s3, s4
add s5, s5, s4
beq s5, s7, end
slt s4, s3, s4
beq s4, zero, around
addi s5, zero, 0
around:
slt s4, s7, s2
add s7, s4, s5
sub s7, s7, s2
sw s7, 68(s3)
lw s2, 80(s0)
jal zero, end
addi s2, s0, 1
end:
sw s2, 84(zero)

