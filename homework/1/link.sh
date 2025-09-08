#!/usr/bin/env bash
set -euo pipefail
ld -m elf_i386 practice1.o -o practice1
chmod +x practice1
