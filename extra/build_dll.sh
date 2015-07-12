#!/bin/sh

## script to build a .dll
## 
gcc \
  -DNANOVG_GL3_IMPLEMENTATION           \
  -I../nanovg/src                       \
  -fPIC -shared -Wl,-soname,libnvgGL3.so   \
  ../nanovg/src/nanovg.c nvg_dll_shim.c \
  -lGL -lm -olibnvgGL3.so

