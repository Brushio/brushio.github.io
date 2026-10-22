// Делает лёгкие копии скриншотов для сайта.
// Берёт ../design/screens/<язык>/<экран>.png (оригиналы из Figma, в рамке iPhone)
// и пишет assets/img/screens/<язык>/<экран>.avif шириной 720 px (~30 КБ, с прозрачностью).
// Запуск на Mac из корня репозитория сайта:
//   swift scripts/make-screens.swift [папка со скриншотами]
// Результат коммитится: на GitHub Actions (Ubuntu) CoreGraphics нет.

import AppKit
import ImageIO

let fm = FileManager.default
let args = CommandLine.arguments
let sourceDir = URL(fileURLWithPath: args.count > 1 ? args[1] : "../design/screens")
let outDir = URL(fileURLWithPath: fm.currentDirectoryPath).appendingPathComponent("assets/img/screens")

let width = 720
let quality = 0.6

func convert(_ src: URL, to dst: URL) -> Bool {
    guard let image = NSImage(contentsOf: src)?.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return false }
    // Высота обязательно чётная: AVIF с прозрачностью и нечётной высотой Chrome
    // показывает полностью прозрачным.
    var height = Int(Double(image.height) * Double(width) / Double(image.width))
    height -= height % 2
    guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                              space: CGColorSpace(name: CGColorSpace.sRGB)!,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
    ctx.interpolationQuality = .high
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let resized = ctx.makeImage(),
          let out = CGImageDestinationCreateWithURL(dst as CFURL, "public.avif" as CFString, 1, nil) else { return false }
    CGImageDestinationAddImage(out, resized, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    return CGImageDestinationFinalize(out)
}

guard let langs = try? fm.contentsOfDirectory(at: sourceDir, includingPropertiesForKeys: [.isDirectoryKey]) else {
    fatalError("Нет папки со скриншотами: \(sourceDir.path)")
}

var failed = false
for langDir in langs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent })
    where (try? langDir.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
    let lang = langDir.lastPathComponent
    let target = outDir.appendingPathComponent(lang)
    try? fm.createDirectory(at: target, withIntermediateDirectories: true)

    let pngs = (try? fm.contentsOfDirectory(at: langDir, includingPropertiesForKeys: nil)) ?? []
    for png in pngs.filter({ $0.pathExtension.lowercased() == "png" }).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        let name = png.deletingPathExtension().lastPathComponent
        let dst = target.appendingPathComponent(name + ".avif")
        if convert(png, to: dst) {
            let kb = ((try? fm.attributesOfItem(atPath: dst.path)[.size] as? Int) ?? 0) / 1024
            print("✓ \(lang)/\(name).avif  \(kb) КБ")
        } else {
            print("✗ \(lang)/\(name).png - не получилось")
            failed = true
        }
    }
}
if failed { exit(1) }
