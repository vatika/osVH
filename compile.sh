echo 'Assembling Kernel'

echo 'nasm object making'
nasm -f elf32 kernel.asm -o kasm.o

echo 'c object making'
gcc -fno-stack-protector -m32 -c kernel.c -o kc.o

echo 'linking'
ld -m elf_i386 -T link.ld -o kernel kasm.o kc.o

echo 'clean up !'
rm -rf *.o

qemu-system-i386 -kernel kernel
