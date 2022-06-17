N = nasm -f elf64
L = ld
CLANG = clang -pedantic -no-pie

# The path
IN = include
T = test

# THe objecst
OBJS = alloc.o
BINS = $(T)/main.out $(T)/ctest.out

all: $(BINS)

alloc.o: alloc.asm
	$(N) $< -o $@

$(T)/main.o: $(T)/test.asm
	$(N) $< -o $@

$(T)/main.out: $(T)/main.o $(OBJS)
	$(L) $(T)/main.o $(OBJS) -o $@

$(T)/ctest.out: $(T)/test.c $(OBJS)
	$(CLANG) -ggdb $(OBJS) $< -o $@

run_tests:
	./$(T)/ctest.out
	./$(T)/main.out

clean:
	rm $(OBJS) $(BINS) $(T)/main.o

