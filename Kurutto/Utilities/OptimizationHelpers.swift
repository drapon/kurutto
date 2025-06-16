import Foundation
import UIKit
import SceneKit

// MARK: - Performance Optimizations

final class OptimizationHelpers {
    
    // MARK: - Image Optimization
    
    static func optimizedImage(named name: String, maxSize: CGSize? = nil) -> UIImage? {
        guard let image = UIImage(named: name) else { return nil }
        
        // Check cache first
        let cacheKey = "\(name)_\(maxSize?.width ?? 0)x\(maxSize?.height ?? 0)"
        if let cachedImage = MemoryManager.getCachedImage(forKey: cacheKey) {
            return cachedImage
        }
        
        // Resize if needed
        let optimizedImage: UIImage
        if let maxSize = maxSize, needsResize(image: image, maxSize: maxSize) {
            optimizedImage = resizeImage(image, maxSize: maxSize) ?? image
        } else {
            optimizedImage = image
        }
        
        // Cache the result
        MemoryManager.cacheImage(optimizedImage, forKey: cacheKey)
        
        return optimizedImage
    }
    
    private static func needsResize(image: UIImage, maxSize: CGSize) -> Bool {
        return image.size.width > maxSize.width || image.size.height > maxSize.height
    }
    
    private static func resizeImage(_ image: UIImage, maxSize: CGSize) -> UIImage? {
        let widthRatio = maxSize.width / image.size.width
        let heightRatio = maxSize.height / image.size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(
            width: image.size.width * ratio,
            height: image.size.height * ratio
        )
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // MARK: - SceneKit Optimization
    
    static func optimizeSceneNode(_ node: SCNNode) {
        // Flatten node hierarchy where possible
        node.flattenedClone()
        
        // Optimize geometry
        if let geometry = node.geometry {
            optimizeGeometry(geometry)
        }
        
        // Optimize children recursively
        node.childNodes.forEach { optimizeSceneNode($0) }
    }
    
    private static func optimizeGeometry(_ geometry: SCNGeometry) {
        // Reduce polygon count for distant objects
        geometry.subdivisionLevel = 0
        
        // Optimize materials
        geometry.materials.forEach { material in
            // Use simpler shading for performance
            material.lightingModel = .blinn
            
            // Disable expensive features if not needed
            material.isDoubleSided = false
            material.writesToDepthBuffer = true
            material.readsFromDepthBuffer = true
        }
    }
    
    // MARK: - Collection Optimization
    
    static func batchProcess<T, R>(
        items: [T],
        batchSize: Int = 10,
        process: @escaping ([T]) -> [R]
    ) async -> [R] {
        var results: [R] = []
        
        for i in stride(from: 0, to: items.count, by: batchSize) {
            let endIndex = min(i + batchSize, items.count)
            let batch = Array(items[i..<endIndex])
            
            let batchResults = await Task.detached(priority: .userInitiated) {
                process(batch)
            }.value
            
            results.append(contentsOf: batchResults)
        }
        
        return results
    }
}

// MARK: - Lazy Loading

@propertyWrapper
final class Lazy<T> {
    private var value: T?
    private let initializer: () -> T
    
    init(wrappedValue: @escaping @autoclosure () -> T) {
        self.initializer = wrappedValue
    }
    
    var wrappedValue: T {
        if let value = value {
            return value
        }
        let newValue = initializer()
        value = newValue
        return newValue
    }
    
    func reset() {
        value = nil
    }
}

// MARK: - Throttle & Debounce

final class Throttler {
    private let queue: DispatchQueue
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private var lastFire: Date = .distantPast
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func throttle(_ block: @escaping () -> Void) {
        let now = Date()
        let deadline = lastFire.addingTimeInterval(delay)
        
        if now >= deadline {
            queue.async(execute: block)
            lastFire = now
        }
    }
}

final class Debouncer {
    private let queue: DispatchQueue
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(_ block: @escaping () -> Void) {
        workItem?.cancel()
        
        let workItem = DispatchWorkItem(block: block)
        self.workItem = workItem
        
        queue.asyncAfter(deadline: .now() + delay, execute: workItem)
    }
    
    func cancel() {
        workItem?.cancel()
        workItem = nil
    }
}

// MARK: - Optimized Data Structures

final class CircularBuffer<T> {
    private var buffer: [T?]
    private var head = 0
    private var tail = 0
    private let capacity: Int
    private(set) var count = 0
    
    init(capacity: Int) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }
    
    func append(_ element: T) {
        buffer[tail] = element
        tail = (tail + 1) % capacity
        
        if count < capacity {
            count += 1
        } else {
            head = (head + 1) % capacity
        }
    }
    
    func removeFirst() -> T? {
        guard count > 0 else { return nil }
        
        let element = buffer[head]
        buffer[head] = nil
        head = (head + 1) % capacity
        count -= 1
        
        return element
    }
    
    var elements: [T] {
        var result: [T] = []
        var index = head
        
        for _ in 0..<count {
            if let element = buffer[index] {
                result.append(element)
            }
            index = (index + 1) % capacity
        }
        
        return result
    }
}

// MARK: - String Optimization

extension String {
    func localized(comment: String = "") -> String {
        // Cache localized strings
        struct LocalizationCache {
            static var cache: [String: String] = [:]
        }
        
        if let cached = LocalizationCache.cache[self] {
            return cached
        }
        
        let localized = NSLocalizedString(self, comment: comment)
        LocalizationCache.cache[self] = localized
        return localized
    }
}

// MARK: - Animation Optimization

extension UIView {
    func performBatchAnimations(_ animations: [() -> Void], duration: TimeInterval = 0.3) {
        UIView.animate(withDuration: duration, animations: {
            animations.forEach { $0() }
        })
    }
    
    func animateIfNeeded(duration: TimeInterval = 0.3, animations: @escaping () -> Void) {
        if UIAccessibility.isReduceMotionEnabled {
            animations()
        } else {
            UIView.animate(withDuration: duration, animations: animations)
        }
    }
}

// MARK: - SwiftUI Performance

import SwiftUI

struct ConditionalViewModifier: ViewModifier {
    let condition: Bool
    let trueModifier: AnyViewModifier
    let falseModifier: AnyViewModifier?
    
    func body(content: Content) -> some View {
        if condition {
            content.modifier(trueModifier)
        } else if let falseModifier = falseModifier {
            content.modifier(falseModifier)
        } else {
            content
        }
    }
}

struct AnyViewModifier: ViewModifier {
    private let _body: (AnyView) -> AnyView
    
    init<M: ViewModifier>(_ modifier: M) {
        _body = { AnyView($0.modifier(modifier)) }
    }
    
    func body(content: Content) -> some View {
        _body(AnyView(content))
    }
}

extension View {
    @ViewBuilder
    func `if`<TrueContent: View>(
        _ condition: Bool,
        transform: (Self) -> TrueContent
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func onlyOnce(perform action: @escaping () -> Void) -> some View {
        self.onAppear {
            action()
        }
    }
}