import unittest
import siwin, pixie
import boxes

test "window":
  var image: Image
  var window = newWindow(title="box test")

  window.onResize = proc(e: ResizeEvent) =
    image = newImage(e.size.x, e.size.y)

  window.onRender = proc(e: RenderEvent) =
    image.fill(rgba(255, 255, 255, 255))

    let ctx = image.newContext

    let a = box(window.size)
    let b = box(left = a.left+10, top = a.top+10, right = a.right-10, bottom = a.bottom-10)

    ctx.fillStyle = rgba(0, 0, 0, 20)
    ctx.fillRect b

    ctx.fillStyle = rgba(64, 255, 64, 255)
    ctx.fillRect box(center = b.center, w = 100, h = 50)

    let c = b.box(centerY = b.center, w = 100, h = 50)
    ctx.fillStyle = rgba(255, 64, 64, 255)
    ctx.fillRect b.box(centerY = b.center, w = 100, h = 50)

    ctx.fillStyle = rgba(64, 64, 255, 128)
    ctx.fillRect box(center = c.right, w = 50, h = 50)

    ctx.fillStyle = rgba(64, 255, 64, 128)
    ctx.fillRect box(top = c.bottom - 10, centerX = c.center, w = 50, h = 50)
      
    ctx.fillStyle = rgba(64, 64, 255, 255)
    ctx.fillRect b.box(centerY = b.center + 100, left = b.right + 2.5, w = 5, h = 50)
    
    window.drawImage image.data.toBgrx, ivec2(image.width.int32, image.height.int32)

  window.onKeyup = proc(e: KeyEvent) =
    if e.key == Key.escape:
      close window

  run window
