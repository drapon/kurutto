import SwiftUI
import SceneKit

struct SceneView3D: UIViewRepresentable {
    let scene: SCNScene
    @Binding var selectedNode: String?
    let onNodeTapped: ((String) -> Void)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.backgroundColor = UIColor.clear
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false  // スワイプジェスチャーと競合を避けるため無効化
        scnView.showsStatistics = false
        
        // カメラコントロールの設定
        scnView.defaultCameraController.interactionMode = .orbitTurntable
        scnView.defaultCameraController.inertiaEnabled = true
        scnView.defaultCameraController.maximumVerticalAngle = 45
        scnView.defaultCameraController.minimumVerticalAngle = -15
        
        // タップジェスチャーを追加
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // 必要に応じて更新
    }
    
    class Coordinator: NSObject {
        var parent: SceneView3D
        
        init(_ parent: SceneView3D) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
            guard let scnView = gestureRecognizer.view as? SCNView else { return }
            
            let location = gestureRecognizer.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: [:])
            
            if let firstHit = hitResults.first {
                var node: SCNNode? = firstHit.node
                
                // 親ノードを探してノード名を取得
                while node != nil {
                    if let nodeName = node?.name {
                        // 動物名かカード名かをチェック
                        if AnimalType.allCases.contains(where: { $0.rawValue == nodeName }) ||
                           nodeName.hasPrefix("card_") {
                            parent.selectedNode = nodeName
                            parent.onNodeTapped?(nodeName)
                            
                            // タップフィードバック
                            let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
                            feedbackGenerator.impactOccurred()
                            
                            // タップアニメーション
                            animateNodeTap(node!)
                            break
                        }
                    }
                    node = node?.parent
                }
            }
        }
        
        
        private func animateNodeTap(_ node: SCNNode) {
            let scaleAction = SCNAction.sequence([
                SCNAction.scale(to: 0.9, duration: 0.1),
                SCNAction.scale(to: 1.1, duration: 0.1),
                SCNAction.scale(to: 1.0, duration: 0.1)
            ])
            node.runAction(scaleAction)
        }
    }
}

// SceneView用のViewModifier
struct SceneViewModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadow: Bool
    
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .if(shadow) { view in
                view.shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
    }
}


