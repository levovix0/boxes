import macros, tables
import vmath, bumpy, fusion/astdsl, fusion/matching
export vmath, bumpy

{.experimental: "caseStmtMacros".}

proc contains*(r: Rect, p: Vec2): bool = overlaps(r, p)

proc center*(r: Rect): Vec2 = vec2(r.x + r.w/2, r.y + r.h/2)
proc left*(r: Rect): Vec2 = vec2(r.x, r.y + r.h/2)
proc right*(r: Rect): Vec2 = vec2(r.x + r.w, r.y + r.h/2)
proc top*(r: Rect): Vec2 = vec2(r.x + r.w/2, r.y)
proc bottom*(r: Rect): Vec2 = vec2(r.x + r.w/2, r.y + r.h)
proc topLeft*(r: Rect): Vec2 = vec2(r.x, r.y)
proc topRight*(r: Rect): Vec2 = vec2(r.x + r.w, r.y)
proc bottomLeft*(r: Rect): Vec2 = vec2(r.x, r.y + r.h)
proc bottomRight*(r: Rect): Vec2 = vec2(r.x + r.w, r.y + r.h)

proc margin*(r: Rect, all: SomeNumber): Rect =
  rect(r.xy + all.float32, r.wh - all.float32 * 2)

proc horisontal(x: SomeNumber): auto = x
proc horisontal(v: GVec2): auto = v.x
proc vertical(y: SomeNumber): auto = y
proc vertical(v: GVec2): auto = v.y


const boxProperties = ["w", "h", "wh", "x", "y", "xy", "left", "right", "top", "bottom", "center", "centerX", "centerY"]

proc makeBox(args: seq[NimNode]): NimNode =
  if args.len == 1:
    let wh = args[0]
    return quote do:
      rect(vec2(), `wh`.vec2)

  var args = args
  let box =
    if args[0].kind notin {nnkExprEqExpr, nnkAsgn}:
      let r = args[0]
      args = args[1..^1]
      r
    else: newCall bindSym"Rect"

  let
    xs = ident"x"
    ys = ident"y"
    ws = ident"w"
    hs = ident"h"

  # read args
  let a = block:
    var r: seq[(string, NimNode)]
    for it in args:
      case it
      of ExprEqExpr[Ident(strVal: @s), @b]:
        r.add (s, b)
        if s notin boxProperties: error("unexpected property", it)
      of Asgn[Ident(strVal: @s), @b]:
        r.add (s, b)
        if s notin boxProperties: error("unexpected property", it)
      else: error("unexpected syntax", it)
    r
  let d = a.toTable

  # checks
  const
    marginX = ["left", "right"]
    marginY = ["top", "bottom"]
    coordinateX = ["x", "centerX", "center"]
    coordinateY = ["y", "centerY", "center"]
  
  proc contains[K, V](c: Table[K, V], v: varargs[K]): bool =
    for x in v:
      if x in c: return true
  
  proc contains2[K, V](c: Table[K, V], v: varargs[K]): bool =
    var one = true
    for x in v:
      if x in c:
        if one: one = false
        else: return true
  
  if marginX in d and coordinateX in d:
    error("cannot use both anchor and coordinate", args[0])
  if marginY in d and coordinateY in d:
    error("cannot use both anchor and coordinate", args[0])

  if "wh" in d and ("w" in d or "h" in d): error("duplicated size property", d["wh"][1])
  if "xy" in d and ("x" in d or "y" in d): error("duplicated coordinate property", d["xy"][1])

  if ("left" in d xor "right" in d) and ("w" notin d) and ("wh" notin d): error("missing width", args[0])
  if ("top" in d xor "bottom" in d) and ("h" notin d) and ("wh" notin d): error("missing height", args[0])
  if ("center" in d) and ("w" notin d or "h" notin d) and ("wh" notin d): error("missing size", args[0])
  if ("centerX" in d) and ("w" notin d) and ("wh" notin d): error("missing width", args[0])
  if ("centerY" in d) and ("h" notin d) and ("wh" notin d): error("missing height", args[0])

  if d.contains2(coordinateX): error("duplicated x property", args[0])
  if d.contains2(coordinateY): error("duplicated y property", args[0])

  template getX(v): NimNode = newCall(bindSym"float32", newCall(bindSym"horisontal", v))
  template getY(v): NimNode = newCall(bindSym"float32", newCall(bindSym"vertical", v))

  # generate code
  buildAst: blockStmt empty(), stmtList do:
    letSection:
      identDefs:
        pragmaExpr ident"box":
          pragma ident"used"  # todo: do not declare box, if it is not used
        empty()
        box

    if "xy" in d:
      letSection:
        identDefs:
          ident"xy"
          empty()
          d["xy"]
        identDefs:
          xs
          empty()
          call ident"float32", dotExpr(ident"xy", ident"x")
        identDefs:
          ys
          empty()
          call ident"float32", dotExpr(ident"xy", ident"y")

    if "wh" in d:
      letSection:
        identDefs:
          ident"wh"
          empty()
          d["wh"]
        identDefs:
          ws
          empty()
          call ident"float32", dotExpr(ident"wh", ident"x")
        identDefs:
          hs
          empty()
          call ident"float32", dotExpr(ident"wh", ident"y")
    
    if "x" in d:
      letSection:
        identDefs:
          xs
          empty()
          d["x"].getX
    
    if "y" in d:
      letSection:
        identDefs:
          ys
          empty()
          d["y"].getY
    
    if "w" in d:
      letSection:
        identDefs:
          ws
          empty()
          d["w"].getX

    if "h" in d:
      letSection:
        identDefs:
          hs
          empty()
          d["h"].getY
    
    if "left" in d:
      letSection:
        identDefs:
          xs
          empty()
          d["left"].getX
    
    if "top" in d:
      letSection:
        identDefs:
          ys
          empty()
          d["top"].getY

    if "right" in d:
      if "left" in d:
        letSection:
          identDefs:
            ws
            empty()
            call bindSym"-":
              d["right"].getX
              xs
      else:
        letSection:
          identDefs:
            xs
            empty()
            call bindSym"-":
              d["right"].getX
              ws

    if "bottom" in d:
      if "top" in d:
        letSection:
          identDefs:
            hs
            empty()
            call bindSym"-":
              d["bottom"].getY
              ys
      else:
        letSection:
          identDefs:
            ys
            empty()
            call bindSym"-":
              d["bottom"].getY
              hs
    
    if "center" in d:
      letSection:
        identDefs:
          ident"xy"
          empty()
          call bindSym"-":
            d["center"]
            call bindSym"/":
              call(bindSym"vec2", ws, hs)
              newLit 2'f32
        identDefs:
          xs
          empty()
          call ident"float32", dotExpr(ident"xy", ident"x")
        identDefs:
          ys
          empty()
          call ident"float32", dotExpr(ident"xy", ident"y")

    if "centerX" in d:
      letSection:
        identDefs:
          xs
          empty()
          call bindSym"-":
            d["centerX"].getX
            call bindSym"/":
              ws
              newLit 2'f32

    if "centerY" in d:
      letSection:
        identDefs:
          ys
          empty()
          call bindSym"-":
            d["centerY"].getY
            call bindSym"/":
              hs
              newLit 2'f32
    
    if ["x", "xy", "left", "right", "centerX", "center"] notin d:
      letSection:
        identDefs:
          xs
          empty()
          dotExpr(ident"box", ident"x")

    if ["y", "xy", "top", "bottom", "centerY", "center"] notin d:
      letSection:
        identDefs:
          ys
          empty()
          dotExpr(ident"box", ident"y")

    if ["w", "wh", "left", "right"] notin d:
      letSection:
        identDefs:
          ws
          empty()
          dotExpr(ident"box", ident"w")

    if ["h", "wh", "top", "bottom"] notin d:
      letSection:
        identDefs:
          hs
          empty()
          dotExpr(ident"box", ident"h")

    call bindSym"rect", call(bindSym"vec2", xs, ys), call(bindSym"vec2", ws, hs)


macro box*(args: varargs[untyped]): Rect =
  makeBox(args[0..^1])

