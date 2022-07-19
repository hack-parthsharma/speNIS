target:
  nasm -f bin spenis16.asm -o spenis16.bin
  qemu-system-i386 -hda spenis16.bin
