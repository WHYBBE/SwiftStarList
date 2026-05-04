import AppKit

final class AvatarCache {
    static let shared = AvatarCache()
    private var memoryCache: NSCache<NSString, NSImage>
    private let diskCacheDir: URL

    private init() {
        memoryCache = NSCache()
        memoryCache.countLimit = 500

        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        diskCacheDir = appSupport.appendingPathComponent("StarList/avatars", isDirectory: true)
        try? FileManager.default.createDirectory(at: diskCacheDir, withIntermediateDirectories: true)
    }

    func image(for url: String) -> NSImage? {
        if let cached = memoryCache.object(forKey: url as NSString) {
            return cached
        }
        if let diskImage = loadFromDisk(url: url) {
            memoryCache.setObject(diskImage, forKey: url as NSString)
            return diskImage
        }
        return nil
    }

    func setImage(_ image: NSImage, for url: String) {
        memoryCache.setObject(image, forKey: url as NSString)
        saveToDisk(image: image, url: url)
    }

    func clear() {
        memoryCache.removeAllObjects()
        try? FileManager.default.removeItem(at: diskCacheDir)
        try? FileManager.default.createDirectory(at: diskCacheDir, withIntermediateDirectories: true)
    }

    private func cacheKey(for url: String) -> String {
        url.data(using: .utf8)?.base64EncodedString() ?? url
    }

    private func fileURL(for url: String) -> URL {
        diskCacheDir.appendingPathComponent(cacheKey(for: url))
    }

    private func saveToDisk(image: NSImage, url: String) {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
        try? pngData.write(to: fileURL(for: url))
    }

    private func loadFromDisk(url: String) -> NSImage? {
        let file = fileURL(for: url)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        return NSImage(contentsOf: file)
    }
}
