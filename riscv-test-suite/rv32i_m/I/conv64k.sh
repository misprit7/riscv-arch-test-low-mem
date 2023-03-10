#!/bin/sh
# Modify the branch tests so that they fit in 64K

for insn in beq bge bgeu blt bltu bne
do
    filename=src/${insn}-01.S
    cp $filename tmp
    awk -f rearrange_branches.awk tmp > $filename
done
rm tmp
