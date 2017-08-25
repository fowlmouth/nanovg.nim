import 
  nanovg, os

{.pragma: ic,
  importc, header:"../../nanovg/example/demo.h", cdecl
.}
{.compile: "../nanovg/example/demo.c".}

type 
  DemoData* = object 
    fontNormal*: cint
    fontBold*: cint
    fontIcons*: cint
    images*: array[12, cint]


proc loadDemoData*(vg: ptr NVGcontext; data: ptr DemoData): cint{.ic.}
proc freeDemoData*(vg: ptr NVGcontext; data: ptr DemoData){.ic.}
proc renderDemo*(vg: ptr NVGcontext; mx: cfloat; my: cfloat; width: cfloat; 
                 height: cfloat; t: cfloat; blowup: cint; data: ptr DemoData){.ic.}
proc saveScreenShot*(w: cint; h: cint; premult: cint; name: cstring){.ic.}
