import Foundation
import UIKit
import QuartzCore

class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount: Int = 0
    private var fps: Double = 0
    
    private let fpsUpdateInterval: TimeInterval = 1.0
    private var fpsTimer: Timer?
    
    private var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    
    private init() {}
    
    // MARK: - FPS Monitoring
    
    func startMonitoring() {
        guard displayLink == nil else { return }
        
        displayLink = CADisplayLink(target: self, selector: #selector(displayLinkDidFire))
        displayLink?.add(to: .main, forMode: .common)
        
        fpsTimer = Timer.scheduledTimer(withTimeInterval: fpsUpdateInterval, repeats: true) { [weak self] _ in
            self?.updateFPS()
        }
        
        print("🎮 Performance monitoring started")
    }
    
    func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        
        fpsTimer?.invalidate()
        fpsTimer = nil
        
        print("🎮 Performance monitoring stopped")
    }
    
    @objc private func displayLinkDidFire(_ displayLink: CADisplayLink) {
        frameCount += 1
        
        if lastTimestamp == 0 {
            lastTimestamp = displayLink.timestamp
        }
    }
    
    private func updateFPS() {
        guard let displayLink = displayLink else { return }
        
        let elapsed = displayLink.timestamp - lastTimestamp
        if elapsed > 0 {
            fps = Double(frameCount) / elapsed
            performanceMetrics.currentFPS = fps
            
            // Check for performance issues
            if fps < 30 {
                performanceMetrics.lowFPSCount += 1
                print("⚠️ Low FPS detected: \(String(format: "%.1f", fps)) fps")
            }
            
            // Update min/max
            if fps > 0 {
                performanceMetrics.minFPS = min(performanceMetrics.minFPS, fps)
                performanceMetrics.maxFPS = max(performanceMetrics.maxFPS, fps)
            }
        }
        
        frameCount = 0
        lastTimestamp = displayLink.timestamp
    }
    
    // MARK: - Performance Metrics
    
    func measureBlock<T>(name: String, block: () throws -> T) rethrows -> T {
        let startTime = CACurrentMediaTime()
        
        let result = try block()
        
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        
        performanceMetrics.recordOperation(name: name, duration: duration)
        
        if duration > 0.016 { // More than one frame (60fps)
            print("⚠️ Slow operation '\(name)': \(String(format: "%.3f", duration * 1000))ms")
        }
        
        return result
    }
    
    func getMetrics() -> PerformanceMetrics {
        performanceMetrics.memoryUsage = MemoryManager.shared.getMemoryUsage().used
        return performanceMetrics
    }
    
    func logPerformanceReport() {
        let metrics = getMetrics()
        
        print("""
        
        📊 Performance Report
        =====================
        FPS: \(String(format: "%.1f", metrics.currentFPS)) (min: \(String(format: "%.1f", metrics.minFPS)), max: \(String(format: "%.1f", metrics.maxFPS)))
        Low FPS incidents: \(metrics.lowFPSCount)
        Memory: \(metrics.memoryUsage / 1024 / 1024) MB
        
        Top 5 Slowest Operations:
        """)
        
        let sortedOperations = metrics.operationDurations.sorted { $0.value > $1.value }
        for (index, (name, duration)) in sortedOperations.prefix(5).enumerated() {
            print("\(index + 1). \(name): \(String(format: "%.3f", duration * 1000))ms")
        }
        
        print("=====================\n")
    }
}

// MARK: - Performance Metrics

struct PerformanceMetrics {
    var currentFPS: Double = 60.0
    var minFPS: Double = 60.0
    var maxFPS: Double = 60.0
    var lowFPSCount: Int = 0
    var memoryUsage: Int64 = 0
    var operationDurations: [String: TimeInterval] = [:]
    
    mutating func recordOperation(name: String, duration: TimeInterval) {
        if let existingDuration = operationDurations[name] {
            // Keep the maximum duration
            operationDurations[name] = max(existingDuration, duration)
        } else {
            operationDurations[name] = duration
        }
    }
}

// MARK: - Performance Optimization Helpers

extension UIView {
    func optimizeForPerformance() {
        // Rasterize for better performance
        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.main.scale
        
        // Disable unnecessary features
        layer.masksToBounds = true
        clipsToBounds = true
        
        // Opaque views render faster
        if backgroundColor != nil && backgroundColor != .clear {
            isOpaque = true
        }
    }
}

extension CALayer {
    func optimizeForPerformance() {
        // Enable edge antialiasing
        edgeAntialiasingMask = []
        
        // Disable implicit animations for better performance
        actions = [
            "position": NSNull(),
            "bounds": NSNull(),
            "transform": NSNull(),
            "opacity": NSNull(),
            "backgroundColor": NSNull()
        ]
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension PerformanceMonitor {
    func enableDebugOverlay(in view: UIView) {
        let overlayView = PerformanceOverlayView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayView)
        
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            overlayView.widthAnchor.constraint(equalToConstant: 120),
            overlayView.heightAnchor.constraint(equalToConstant: 60)
        ])
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            overlayView.updateMetrics(self.getMetrics())
        }
    }
}

class PerformanceOverlayView: UIView {
    private let fpsLabel = UILabel()
    private let memoryLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = 8
        
        let stackView = UIStackView(arrangedSubviews: [fpsLabel, memoryLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        
        [fpsLabel, memoryLabel].forEach { label in
            label.textColor = .white
            label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        }
    }
    
    func updateMetrics(_ metrics: PerformanceMetrics) {
        fpsLabel.text = "FPS: \(String(format: "%.1f", metrics.currentFPS))"
        memoryLabel.text = "MEM: \(metrics.memoryUsage / 1024 / 1024) MB"
        
        // Color code FPS
        if metrics.currentFPS < 30 {
            fpsLabel.textColor = .red
        } else if metrics.currentFPS < 50 {
            fpsLabel.textColor = .yellow
        } else {
            fpsLabel.textColor = .green
        }
    }
}
#endif