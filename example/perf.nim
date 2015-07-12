import 
  nvg

{.pragma: ic,
  importc, header:"perf.h", cdecl
.}
{.compile:"perf.c".}

type 
  GraphrenderStyle* = enum 
    GRAPH_RENDER_FPS, GRAPH_RENDER_MS, GRAPH_RENDER_PERCENT

const 
  GRAPH_HISTORY_COUNT* = 100

type 
  PerfGraph* = object 
    style*: cint
    name*: array[32, char]
    values*: array[GRAPH_HISTORY_COUNT, cfloat]
    head*: cint


proc initGraph*(fps: ptr PerfGraph; style: GraphrenderStyle; name: cstring){.ic.}
proc updateGraph*(fps: ptr PerfGraph; frameTime: cfloat){.ic.}
proc renderGraph*(vg: ptr NVGcontext; x: cfloat; y: cfloat; fps: ptr PerfGraph){.ic.}
proc getGraphAverage*(fps: ptr PerfGraph): cfloat{.ic.}
const 
  GPU_QUERY_COUNT* = 5

type 
  GPUtimer* = object 
    supported*: cint
    cur*: cint
    ret*: cint
    queries*: array[GPU_QUERY_COUNT, cuint]


proc initGPUTimer*(timer: ptr GPUtimer){.ic.}
proc startGPUTimer*(timer: ptr GPUtimer){.ic.}
proc stopGPUTimer*(timer: ptr GPUtimer; times: ptr cfloat; maxTimes: cint): cint{.ic.}
proc stopGPUTimer*(timer: ptr GPUtimer; times: var openarray[cfloat]): cint =
  stopGPUTimer(timer, times[0].addr, times.len.cint)