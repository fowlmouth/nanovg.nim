#
# Copyright (c) 2013 Mikko Mononen memon@inside.org
#
# This software is provided 'as-is', without any express or implied
# warranty.  In no event will the authors be held liable for any damages
# arising from the use of this software.
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
# 1. The origin of this software must not be misrepresented; you must not
#    claim that you wrote the original software. If you use this software
#    in a product, an acknowledgment in the product documentation would be
#    appreciated but is not required.
# 2. Altered source versions must be plainly marked as such, and must not be
#    misrepresented as being the original software.
# 3. This notice may not be removed or altered from any source distribution.
#

import 
  nvg, demo, perf, opengl
import glfw3 as glfw

proc errorcb*(error: cint; desc: cstring) {.cdecl.}  = 
  #printf("GLFW error %d: %s\x0A", error, desc)
  echo "GLFW error ", error, ": ", desc

var blowup*: cint = 0

var screenshot*: cint = 0

var premult*: cint = 0

proc key*(window: glfw.Window; key: cint; scancode: cint; action: cint; 
          mods: cint) {.cdecl.} = 
  # NVG_NOTUSED(scancode)
  # NVG_NOTUSED(mods)
  if key == KEY_ESCAPE and action == PRESS: 
    SetWindowShouldClose(window, GL_TRUE)
  if key == KEY_SPACE and action == PRESS: blowup = not blowup
  if key == KEY_S and action == PRESS: screenshot = 1
  if key == KEY_P and action == PRESS: premult = not premult
  
proc main*(): cint = 
  var window: glfw.Window
  var data: DemoData
  var vg: ptr NVGcontext = nil
  var gpuTimer: GPUtimer
  var 
    fps: PerfGraph
    cpuGraph: PerfGraph
    gpuGraph: PerfGraph
  var 
    prevt: cdouble = 0
    cpuTime: cdouble = 0
  if not glfw.Init().bool: 
    echo("Failed to init GLFW.")
    return - 1
  initGraph(addr(fps), GRAPH_RENDER_FPS, "Frame Time")
  initGraph(addr(cpuGraph), GRAPH_RENDER_MS, "CPU Time")
  initGraph(addr(gpuGraph), GRAPH_RENDER_MS, "GPU Time")
  discard glfw.SetErrorCallback(errorcb)
  when not defined(windows):#_WIN32): 
    # don't require this on win32, and works with more cards
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 2)
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, GL_TRUE)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
  glfw.WindowHint(glfw.OPENGL_DEBUG_CONTEXT, 1)
  when defined(DEMO_MSAA): 
    glfw.WindowHint(glfw.SAMPLES, 4)
  window = glfw.CreateWindow(1000, 600, "NanoVG", nil, nil)
  #	window = glfw.CreateWindow(1000, 600, "NanoVG", glfw.GetPrimaryMonitor(), NULL);
  if window.isNil:
    glfw.Terminate()
    return - 1
  discard glfw.SetKeyCallback(window, key)

  opengl.loadExtensions()

  glfw.MakeContextCurrent(window)
  when defined(NANOVG_GLEW): 
    glewExperimental = GL_TRUE
    if glewInit() != GLEW_OK: 
      printf("Could not init glew.\x0A")
      return - 1
    glGetError()
  when defined(DEMO_MSAA): 
    vg = nvgCreateGL3(NVG_STENCIL_STROKES or NVG_DEBUG)
  else: 
    vg = nvgCreateGL3(NVG_ANTIALIAS or NVG_STENCIL_STROKES or NVG_DEBUG)
  if vg == nil: 
    echo "Could not init nanovg."
    return - 1
  if loadDemoData(vg, addr(data)) == - 1: return - 1
  glfw.SwapInterval(0)
  initGPUTimer(addr(gpuTimer))
  glfw.SetTime(0)
  prevt = glfw.GetTime()
  while not glfw.WindowShouldClose(window).bool: 
    var 
      mx: cdouble
      my: cdouble
      t: cdouble
      dt: cdouble
    var 
      winWidth: cint
      winHeight: cint
    var 
      fbWidth: cint
      fbHeight: cint
    var pxRatio: cfloat
    var gpuTimes: array[3, cfloat]
    var 
      i: cint
      n: cint
    t = glfw.GetTime()
    dt = t - prevt
    prevt = t
    startGPUTimer(addr(gpuTimer))
    glfw.GetCursorPos(window, addr(mx), addr(my))
    glfw.GetWindowSize(window, addr(winWidth), addr(winHeight))
    glfw.GetFramebufferSize(window, addr(fbWidth), addr(fbHeight))
    # Calculate pixel ration for hi-dpi devices.
    pxRatio = fbWidth.cfloat / cfloat(winWidth)
    # Update and render
    glViewport(0, 0, fbWidth, fbHeight)
    if premult.bool: glClearColor(0, 0, 0, 0)
    else: glClearColor(0.3, 0.3, 0.32, 1.0)
    glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT or
        GL_STENCIL_BUFFER_BIT)
    nvgBeginFrame(vg, winWidth, winHeight, pxRatio)
    renderDemo(vg, mx.cfloat, my.cfloat, winWidth.cfloat, winHeight.cfloat, 
      t, blowup, addr(data))
    renderGraph(vg, 5, 5, addr(fps))
    renderGraph(vg, 5 + 200 + 5, 5, addr(cpuGraph))
    if gpuTimer.supported.bool: 
      renderGraph(vg, 5 + 200 + 5 + 200 + 5, 5, addr(gpuGraph))
    nvgEndFrame(vg)
    # Measure the CPU time taken excluding swap buffers (as the swap may wait for GPU)
    cpuTime = glfw.GetTime() - t
    updateGraph(addr(fps), dt)
    updateGraph(addr(cpuGraph), cpuTime)
    # We may get multiple results.
    n = stopGPUTimer(addr(gpuTimer), gpuTimes)
    i = 0
    while i < n: 
      updateGraph(addr(gpuGraph), gpuTimes[i])
      inc(i)
    if screenshot.bool: 
      screenshot = 0
      saveScreenShot(fbWidth, fbHeight, premult, "dump.png")
    glfw.SwapBuffers(window)
    glfw.PollEvents()
  freeDemoData(vg, addr(data))
  nvgDeleteGL3(vg)
  echo("Average Frame Time: ", getGraphAverage(addr(fps)) * 1000.0, " ms")
  echo("          CPU Time: ",
         getGraphAverage(addr(cpuGraph)) * 1000.0, " ms")
  echo("          GPU Time: ",
         getGraphAverage(addr(gpuGraph)) * 1000.0, " ms")
  glfw.Terminate()
  return 0

programResult = main()