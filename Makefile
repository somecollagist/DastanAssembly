all: build run

build:
	nasm main.asm -f bin -o Dastan.img -Wall

run:
	qemu-system-x86_64 -drive format=raw,file=Dastan.img,index=0,if=floppy -m 128M
	# bochs -q