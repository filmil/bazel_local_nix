#!/bin/bash
export PATH=$(echo $(bazel info output_base)/external/nix_gnat_toolchain/bin):$PATH
rm -rf out
mkdir out
gnatmake -q -c greet.adb -D out
gnatmake -q hello.adb -aI. -aOout -D out -o hello_bin -largs out/greet.o
./hello_bin
