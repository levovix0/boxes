box markuping library, based on bumpy and vmath

```nim
import boxes

let a = box(vec2(100, 100))  # same as rect(vec2(), vec2(100, 100))
let b = a.margin(10)
let c = box(center=b.center, w=b.w, h=b.h/2)
let d = box(top=b.bottom + 10, centerX=b.center, wh=vec2(20, 10))
var e = b.box(x=55, w=10)  # same as box(x=55, y=b.y, w=10, h=b.h)
e     = b.box(left=55, right=65)  # same as previous
let f = box(center=b.topRight, w=10, h=10)
```
