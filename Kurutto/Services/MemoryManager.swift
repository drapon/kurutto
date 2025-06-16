import Foundation
import UIKit

class MemoryManager {
    static let shared = MemoryManager()
    
    private var memoryWarningObserver: NSObjectProtocol?
    private var resourceManagers: [WeakResourceManager] = []
    
    private init() {
        setupMemoryWarningObserver()
    }
    
    deinit {
        if let observer = memoryWarningObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Memory Warning Handling
    
    private func setupMemoryWarningObserver() {
        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }
    }
    
    private func handleMemoryWarning() {
        print("⚠️ Memory Warning Received")
        
        // Clean up caches
        URLCache.shared.removeAllCachedResponses()
        
        // Notify resource managers
        resourceManagers.forEach { weakManager in
            weakManager.manager?.releaseUnusedResources()
        }
        
        // Force garbage collection
        autoreleasepool {
            // This helps release autorelease objects
        }
        
        logMemoryUsage()
    }
    
    // MARK: - Resource Management
    
    func registerResourceManager(_ manager: ResourceManageable) {
        resourceManagers.append(WeakResourceManager(manager: manager))
        cleanupReleasedManagers()
    }
    
    private func cleanupReleasedManagers() {
        resourceManagers.removeAll { $0.manager == nil }
    }
    
    // MARK: - Memory Monitoring
    
    func logMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        print("📊 Memory Usage: \(memoryUsage.used / 1024 / 1024) MB / \(memoryUsage.total / 1024 / 1024) MB")
        
        if memoryUsage.percentageUsed > 80 {
            print("⚠️ High memory usage: \(memoryUsage.percentageUsed)%")
        }
    }
    
    func getMemoryUsage() -> (used: Int64, total: Int64, percentageUsed: Double) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: 1) { pointer in
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         pointer,
                         &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let usedMemory = Int64(info.resident_size)
            let totalMemory = Int64(ProcessInfo.processInfo.physicalMemory)
            let percentage = Double(usedMemory) / Double(totalMemory) * 100
            
            return (usedMemory, totalMemory, percentage)
        }
        
        return (0, 0, 0)
    }
    
    // MARK: - Image Cache Management
    
    private static let imageCache = NSCache<NSString, UIImage>()
    
    static func cacheImage(_ image: UIImage, forKey key: String) {
        imageCache.setObject(image, forKey: key as NSString)
    }
    
    static func getCachedImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    static func clearImageCache() {
        imageCache.removeAllObjects()
    }
}

// MARK: - Supporting Types

private struct WeakResourceManager {
    weak var manager: ResourceManageable?
}

protocol ResourceManageable: AnyObject {
    func releaseUnusedResources()
}

// MARK: - Extensions for Memory Management

extension SceneManager: ResourceManageable {
    func releaseUnusedResources() {
        // Release any cached textures or materials
        scene.rootNode.enumerateChildNodes { node, _ in
            node.geometry?.materials.forEach { material in
                material.diffuse.contents = nil
                material.normal.contents = nil
                material.specular.contents = nil
            }
        }
    }
}

extension AudioManager: ResourceManageable {
    func releaseUnusedResources() {
        // Stop and release background music if needed
        if UserDefaults.standard.bool(forKey: "reducedMemoryMode") {
            stopBackgroundMusic()
        }
    }
}

// MARK: - Memory Leak Detection Helper

#if DEBUG
class MemoryLeakDetector {
    private static var trackedObjects: [String: WeakObject] = [:]
    
    static func track(_ object: AnyObject, file: String = #file, line: Int = #line) {
        let identifier = "\(type(of: object))-\(ObjectIdentifier(object).hashValue)"
        let location = "\(file.split(separator: "/").last ?? ""):\(line)"
        
        trackedObjects[identifier] = WeakObject(object: object, location: location)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            checkForLeak(identifier: identifier)
        }
    }
    
    private static func checkForLeak(identifier: String) {
        if let weakObject = trackedObjects[identifier], weakObject.object != nil {
            print("⚠️ Potential memory leak detected: \(weakObject.location)")
        }
        trackedObjects.removeValue(forKey: identifier)
    }
    
    private struct WeakObject {
        weak var object: AnyObject?
        let location: String
    }
}
#endif