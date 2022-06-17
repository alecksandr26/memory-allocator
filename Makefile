N = nasm -f elf64
C = ld
CLANG = clang -no-pie

EXT = main.o
OBJS = alloc.o
BINS = main ctest

all: main.out ctest.out

alloc.o: alloc.asm
	$(N) $< -o $@

main.o: test.asm
	$(N) $< -o $@

main.out: $(EXT) $(OBJS)
	$(C) $(EXT) $(OBJS) -o $@

ctest.out: test.c $(OBJS)
	$(CLANG) -ggdb $(OBJS) $< -o $@

clean:
	rm $(OBJS) $(EXT) $(MAIN)
