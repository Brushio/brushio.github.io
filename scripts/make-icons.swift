// Делает иконки сайта из иконки приложения, экспортированной из Icon Composer
// (PNG 1024×1024 с уже скруглёнными прозрачными углами).
// Запуск на Mac из корня репозитория сайта:
//   swift scripts/make-icons.swift ../design/icon.png
// Результат коммитится: на GitHub Actions (Ubuntu) CoreGraphics нет.

import AppKit

let args = CommandLine.arguments
let sourcePath = args.count > 1 ? args[1] : "../design/icon.png"
let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let imgDir = root.appendingPathComponent("assets/img")

guard let source = NSImage(contentsOfFile: sourcePath),
      let icon = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fatalError("Не найдена иконка: \(sourcePath)")
}

// Цвет края иконки - им заливаем прозрачные углы для iPhone (он скругляет сам,
// а прозрачное закрашивает чёрным).
let edgeTeal = CGColor(srgbRed: 0.35, green: 0.80, blue: 0.72, alpha: 1)

func render(size: Int, to name: String, fillCorners: Bool) {
    let s = CGFloat(size)
    guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
    ctx.interpolationQuality = .high
    if fillCorners {
        ctx.setFillColor(edgeTeal)
        ctx.fill(CGRect(x: 0, y: 0, width: s, height: s))
    }
    ctx.draw(icon, in: CGRect(x: 0, y: 0, width: s, height: s))

    guard let image = ctx.makeImage() else { return }
    let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!
    try! data.write(to: imgDir.appendingPathComponent(name))
    print("✓ assets/img/\(name)")
}

render(size: 256, to: "icon-256.png", fillCorners: false)          // логотип на страницах
render(size: 512, to: "icon-512.png", fillCorners: false)          // превью ссылки (og:image)
render(size: 180, to: "apple-touch-icon.png", fillCorners: true)   // «На экран Домой» на iPhone
render(size: 64, to: "favicon-64.png", fillCorners: false)         // вкладка браузера
