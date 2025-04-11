#!/bin/bash

# === CONFIGURATION ===
CONTAINER_NAME="gem5"
HOST_BASE_DIR=$(basename "$(pwd)") # Host base directory

HOST_SOURCE_DIR="$(pwd)/src"            # Host source directory
HOST_OUTPUT_DIR="$(pwd)/build"          # Host output directory

CONTAINER_SOURCE_DIR="/tmp/src/$HOST_BASE_DIR"         # Target dir inside container
CONTAINER_OUTPUT_DIR="/tmp/build/$HOST_BASE_DIR"       # Output dir inside container

CLANG_EXE="/root/llvm-project-fi-system/build/bin/clang"
CLANG_FLAGS="-O0 --target=riscv32 -march=rv32imzfinx_xfpint -mabi=ilp32 \
  --sysroot="/opt/riscv-newlib-imzfinx/riscv32-unknown-elf" --gcc-toolchain="/opt/riscv-newlib-imzfinx" \
  -nostdlib -static \
"
LINK_FLAGS="-L/opt/riscv-newlib-imzfinx/riscv32-unknown-elf/lib \
	          -lc -lm -lgcc \
           "

DUMP_EXE="/root/llvm-project-fi-system/build/bin/llvm-objcopy"
# DUMP_CMD="$DUMP_EXE --dump-section .text=$OUT.bin $OUT && xxd -p $OUT.bin | tr -d '\n' | sed 's/../& /g' > $OUT.hex"
# DUMP_CMD="$DUMP_EXE -O verilog $OUT.bin $OUT.hex"

DISASSEM_EXE="/root/llvm-project-fi-system/build/bin/llvm-objdump"
# DISASSEM_CMD="$DISASSEM_EXE -D $OUT > $OUT.disasm"

SRCS=$(find $(pwd)/src -type f \( -name "*.c" -o -name "*.cc" -o -name "*.S" \))
SRC_BASES=$(find $(pwd)/src -type f \( -name "*.c" -o -name "*.cc" -o -name "*.S" \) -exec basename {} \;)
LINK_FILE=$(find $(pwd)/src -type f -name "*.ld" -exec basename {} \;)

# === PREPARE HOST DIRS ===
mkdir -p "$HOST_OUTPUT_DIR"

# === COPY SOURCE TO CONTAINER ===
docker exec "$CONTAINER_NAME" /bin/bash -c "rm -rf $CONTAINER_SOURCE_DIR"
docker exec "$CONTAINER_NAME" /bin/bash -c "rm -rf $CONTAINER_OUTPUT_DIR"
docker exec "$CONTAINER_NAME" /bin/bash -c "mkdir -p $CONTAINER_SOURCE_DIR"
docker exec "$CONTAINER_NAME" /bin/bash -c "mkdir -p $CONTAINER_OUTPUT_DIR"
docker cp "$HOST_SOURCE_DIR/." "$CONTAINER_NAME:$CONTAINER_SOURCE_DIR"

# === compile to object file ===
for FILE in $SRC_BASES; do
  # if *.c or *.cc, use special flags
  if [[ $FILE == *.c || $FILE == *.cc ]]; then
    echo "Compiling $FILE"
    docker exec "$CONTAINER_NAME" /bin/bash -c "cd $CONTAINER_OUTPUT_DIR && $CLANG_EXE $CLANG_FLAGS -c $CONTAINER_SOURCE_DIR/$FILE -o $CONTAINER_OUTPUT_DIR/$FILE.o"
  else
    docker exec "$CONTAINER_NAME" /bin/bash -c "cd $CONTAINER_OUTPUT_DIR && $CLANG_EXE $CLANG_FLAGS -c $CONTAINER_SOURCE_DIR/$FILE -o $CONTAINER_OUTPUT_DIR/$FILE.o"
  fi
done

# === link object files ===
docker exec "$CONTAINER_NAME" /bin/bash -c "cd $CONTAINER_OUTPUT_DIR && 
  $CLANG_EXE $CLANG_FLAGS $CONTAINER_OUTPUT_DIR/*.o -T $CONTAINER_SOURCE_DIR/$LINK_FILE -o $CONTAINER_OUTPUT_DIR/$HOST_BASE_DIR.elf $LINK_FLAGS"

# === dump sections ===
OUT="$HOST_BASE_DIR.elf"
# docker exec "$CONTAINER_NAME" /bin/bash -c \
#   "cd $CONTAINER_OUTPUT_DIR && $DUMP_EXE --dump-section .text=$OUT.bin $OUT && xxd -p $OUT.bin | tr -d '\n' | sed 's/../& /g' > $OUT.hex"
docker exec "$CONTAINER_NAME" /bin/bash -c \
  "cd $CONTAINER_OUTPUT_DIR && $DUMP_EXE -O binary $OUT $OUT.bin&& xxd -p $OUT.bin | tr -d '\n' | sed 's/../& /g' > $OUT.hex"

docker exec "$CONTAINER_NAME" /bin/bash -c \
  "cd $CONTAINER_OUTPUT_DIR && $DISASSEM_EXE -D $OUT > $OUT.disasm"

# docker exec "$CONTAINER_NAME" /bin/bash -c \
#   "mkdir -p $CONTAINER_OUTPUT_DIR && cd $CONTAINER_OUTPUT_DIR && $CLANG_CMD && $DUMP_CMD && $DISASSEM_CMD"

# === COPY RESULT BACK TO HOST ===
docker cp "$CONTAINER_NAME:$CONTAINER_OUTPUT_DIR/." "$HOST_OUTPUT_DIR/"

echo "✅ Build complete. Output in $HOST_OUTPUT_DIR"