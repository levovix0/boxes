version       = "0.1"
author        = "levovix0"
description   = "Rect creation procs"
license       = "MIT"
srcDir        = "src"

requires "nim >= 1.6.6"
requires "vmath", "bumpy", "fusion"

task test, "run tests":  # needed because tests uses libraries, that is not dependencies
  exec "nim c --hints:off -r tests/tests"
