N = nasm -f elf64
L = ld
C = cc -pedantic -no-pie
AR = ar rc

# The path
INCLUDE_DIR = include
SRC_DIR = src
OBJ_DIR = obj
LIB_DIR = lib
TEST_DIR = test
BUILD_DIR = build
TEST_BIN_DIR = $(TEST_DIR)/bin
TEST_SRC_DIR = $(TEST_DIR)/src

# The objects
OBJS = $(addprefix $(OBJ_DIR)/, memalloc.o)

# The libs
LIBS = $(addprefix $(LIB_DIR)/, libmemalloc.a)

# The tests
TESTS = $(addprefix $(TEST_BIN_DIR)/, test_1.out)

all: $(OBJ_DIR) $(LIB_DIR) $(TEST_BIN_DIR) $(LIBS) $(TESTS)

$(TEST_BIN_DIR):
	@echo Creating: $@
	@mkdir -p $@

$(LIB_DIR):
	@echo Creating: $@
	@mkdir -p $@

$(OBJ_DIR):
	@echo Creating: $@
	@mkdir -p $@

# Compile all the objects
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.asm
	@echo Compiling: $< -o $@
	@$(N) $< -o $@

$(LIB_DIR)/%.a: $(OBJS)
	@echo Archiving: $^ -o $@
	@$(AR) $@ $^
	@ranlib $@

$(TEST_BIN_DIR)/%.out: $(TEST_SRC_DIR)/%.c $(LIBS) 
	@echo Compiling: $^ -o $@
	@$(C) $^ -o $@

# To run an specific test
test_%.out: $(TEST_BIN_DIR)/test_%.out
	@echo Testing:
	@echo Running: $<

	@valgrind --leak-check=full --track-origins=yes -s  --show-leak-kinds=all ./$<
	@echo Passed:

# To run all the tests
.PHONY: tests 
tests: $(TESTS) $(notdir $(TESTS))


clean_$(OBJ_DIR)/%.o:
	@echo Removing: $(OBJ_DIR)/$(notdir $@)
	@rm $(OBJ_DIR)/$(notdir $@)


clean_$(LIB_DIR)/%.a:
	@echo Removing: $(LIB_DIR)/$(notdir $@)
	@rm $(LIB_DIR)/$(notdir $@)

clean_$(TEST_BIN_DIR)/%.out:
	@echo Removing: $(TEST_BIN_DIR)/$(notdir $@)
	@rm $(TEST_BIN_DIR)/$(notdir $@)

.PHONY: clean 
clean: $(addprefix clean_, $(wildcard $(OBJ_DIR)/*.o)) \
	   $(addprefix clean_, $(wildcard $(LIB_DIR)/*.a)) \
	   $(addprefix clean_, $(wildcard $(TEST_BIN_DIR)/*.out))
ifneq ("$(wildcard $(LIB_DIR))", "")
		@echo Removing: $(LIB_DIR)
		@rmdir $(LIB_DIR)
endif

ifneq ("$(wildcard $(OBJ_DIR))", "")
		@echo Removing: $(OBJ_DIR)
		@rmdir $(OBJ_DIR)
endif

ifneq ("$(wildcard $(TEST_BIN_DIR))", "")
		@echo Removing: $(TEST_BIN_DIR)
		@rmdir $(TEST_BIN_DIR)
endif

