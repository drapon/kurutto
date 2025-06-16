import SceneKit
import SwiftUI

class SceneManager: ObservableObject {
    let scene = SCNScene()
    private var boardNode: SCNNode?
    private var animalNodes: [AnimalType: SCNNode] = [:]
    private var cameraNode: SCNNode?
    
    init() {
        setupScene()
    }
    
    private func setupScene() {
        // 背景色を設定
        scene.background.contents = UIColor(named: "BackgroundColor") ?? UIColor.systemBackground
        
        // カメラの設定
        let camera = SCNCamera()
        camera.fieldOfView = 45
        camera.zNear = 0.1
        camera.zFar = 100
        
        cameraNode = SCNNode()
        cameraNode?.camera = camera
        cameraNode?.position = SCNVector3(0, 8, 12)
        cameraNode?.eulerAngles = SCNVector3(-0.3, 0, 0)  // 少し下向きに
        scene.rootNode.addChildNode(cameraNode!)
        
        // メインライトの設定
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .directional
        lightNode.light?.intensity = 800
        lightNode.light?.castsShadow = true
        lightNode.position = SCNVector3(5, 10, 5)
        lightNode.eulerAngles = SCNVector3(-0.5, 0.3, 0)
        scene.rootNode.addChildNode(lightNode)
        
        // 環境光の設定
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.intensity = 400
        ambientLightNode.light?.color = UIColor(white: 1.0, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)
        
        // 追加の補助光
        let fillLightNode = SCNNode()
        fillLightNode.light = SCNLight()
        fillLightNode.light?.type = .omni
        fillLightNode.light?.intensity = 300
        fillLightNode.position = SCNVector3(-5, 5, 5)
        scene.rootNode.addChildNode(fillLightNode)
        
        createBoard()
        createAnimalPositions()
    }
    
    private func createBoard() {
        // ボードのベース
        let boardRadius: CGFloat = 5
        let boardHeight: CGFloat = 0.4
        
        // メインボード
        let boardGeometry = SCNCylinder(radius: boardRadius, height: boardHeight)
        let boardMaterial = SCNMaterial()
        boardMaterial.diffuse.contents = UIColor(named: "BoardColor") ?? UIColor.systemGray5
        boardMaterial.specular.contents = UIColor.white
        boardMaterial.shininess = 0.1
        boardGeometry.materials = [boardMaterial]
        
        boardNode = SCNNode(geometry: boardGeometry)
        boardNode?.position = SCNVector3(0, 0, 0)
        boardNode?.name = "board"
        
        // ボードの縁を追加
        let rimGeometry = SCNTorus(ringRadius: boardRadius, pipeRadius: 0.1)
        let rimMaterial = SCNMaterial()
        rimMaterial.diffuse.contents = UIColor(white: 0.8, alpha: 1.0)
        rimGeometry.materials = [rimMaterial]
        
        let rimNode = SCNNode(geometry: rimGeometry)
        rimNode.position = SCNVector3(0, boardHeight / 2, 0)
        boardNode?.addChildNode(rimNode)
        
        // 中心マーカー
        let centerGeometry = SCNCylinder(radius: 0.3, height: 0.01)
        let centerMaterial = SCNMaterial()
        centerMaterial.diffuse.contents = UIColor(white: 0.9, alpha: 0.5)
        centerGeometry.materials = [centerMaterial]
        
        let centerNode = SCNNode(geometry: centerGeometry)
        centerNode.position = SCNVector3(0, boardHeight / 2 + 0.01, 0)
        boardNode?.addChildNode(centerNode)
        
        if let boardNode = boardNode {
            scene.rootNode.addChildNode(boardNode)
        }
    }
    
    func createAnimalPositions() {
        // 既存の動物ノードを削除
        animalNodes.values.forEach { $0.removeFromParentNode() }
        animalNodes.removeAll()
        
        // 円形に配置（6匹の動物）
        let radius: Float = 3.5
        let angleStep = Float.pi * 2 / 6
        
        for (index, animal) in AnimalType.allCases.enumerated() {
            let angle = Float(index) * angleStep
            let x = radius * cos(angle)
            let z = radius * sin(angle)
            
            let animalNode = createAnimalNode(for: animal)
            animalNode.position = SCNVector3(x, 0.7, z)
            animalNode.eulerAngles = SCNVector3(0, -angle + Float.pi / 2, 0)  // 中心を向くように回転
            
            animalNodes[animal] = animalNode
            boardNode?.addChildNode(animalNode)
        }
    }
    
    private func createAnimalNode(for animal: AnimalType) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.name = animal.rawValue
        
        // 台座
        let baseGeometry = SCNCylinder(radius: 0.8, height: 0.2)
        let baseMaterial = SCNMaterial()
        baseMaterial.diffuse.contents = UIColor(white: 0.95, alpha: 1.0)
        baseGeometry.materials = [baseMaterial]
        
        let baseNode = SCNNode(geometry: baseGeometry)
        baseNode.position = SCNVector3(0, -0.6, 0)
        containerNode.addChildNode(baseNode)
        
        // 動物を表すシンプルな形状
        let animalGeometry: SCNGeometry
        let animalColor = getAnimalColor(for: animal)
        
        switch animal {
        case .rabbit:
            // うさぎ: 楕円形の体と長い耳
            animalGeometry = SCNSphere(radius: 0.6)
        case .bear:
            // くま: 丸い体
            animalGeometry = SCNSphere(radius: 0.7)
        case .elephant:
            // ぞう: 大きめの体
            animalGeometry = SCNBox(width: 1.2, height: 1.0, length: 0.8, chamferRadius: 0.3)
        case .giraffe:
            // きりん: 背の高い形
            animalGeometry = SCNCylinder(radius: 0.5, height: 1.5)
        case .lion:
            // らいおん: たてがみ付き
            animalGeometry = SCNSphere(radius: 0.65)
        case .panda:
            // ぱんだ: 丸い形
            animalGeometry = SCNSphere(radius: 0.65)
        }
        
        let animalMaterial = SCNMaterial()
        animalMaterial.diffuse.contents = animalColor
        animalMaterial.specular.contents = UIColor.white
        animalMaterial.shininess = 0.1
        animalGeometry.materials = [animalMaterial]
        
        let animalNode = SCNNode(geometry: animalGeometry)
        animalNode.position = SCNVector3(0, 0, 0)
        
        // 動物特有の装飾を追加
        addAnimalDetails(to: animalNode, for: animal)
        
        containerNode.addChildNode(animalNode)
        
        // 名前ラベル
        let textGeometry = SCNText(string: animal.rawValue, extrusionDepth: 0.1)
        textGeometry.font = UIFont(name: "HiraginoMaruGothicProN-W4", size: 0.4)
        textGeometry.flatness = 0.1
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = UIColor(named: "PrimaryTextColor") ?? UIColor.darkText
        textGeometry.materials = [textMaterial]
        
        let textNode = SCNNode(geometry: textGeometry)
        let (min, max) = textNode.boundingBox
        let width = max.x - min.x
        let height = max.y - min.y
        textNode.position = SCNVector3(-width/2, 0.8, 0.4)
        
        containerNode.addChildNode(textNode)
        
        return containerNode
    }
    
    private func addAnimalDetails(to node: SCNNode, for animal: AnimalType) {
        switch animal {
        case .rabbit:
            // うさぎの耳
            let earGeometry = SCNCapsule(capRadius: 0.15, height: 0.6)
            let earMaterial = SCNMaterial()
            earMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.9, blue: 0.9, alpha: 1.0)
            earGeometry.materials = [earMaterial]
            
            let leftEar = SCNNode(geometry: earGeometry)
            leftEar.position = SCNVector3(-0.2, 0.5, 0)
            leftEar.eulerAngles = SCNVector3(0, 0, -0.2)
            node.addChildNode(leftEar)
            
            let rightEar = SCNNode(geometry: earGeometry)
            rightEar.position = SCNVector3(0.2, 0.5, 0)
            rightEar.eulerAngles = SCNVector3(0, 0, 0.2)
            node.addChildNode(rightEar)
            
        case .bear:
            // くまの耳
            let earGeometry = SCNSphere(radius: 0.2)
            let earMaterial = SCNMaterial()
            earMaterial.diffuse.contents = UIColor(red: 0.5, green: 0.3, blue: 0.1, alpha: 1.0)
            earGeometry.materials = [earMaterial]
            
            let leftEar = SCNNode(geometry: earGeometry)
            leftEar.position = SCNVector3(-0.4, 0.4, 0)
            node.addChildNode(leftEar)
            
            let rightEar = SCNNode(geometry: earGeometry)
            rightEar.position = SCNVector3(0.4, 0.4, 0)
            node.addChildNode(rightEar)
            
        case .lion:
            // らいおんのたてがみ
            let maneGeometry = SCNTorus(ringRadius: 0.7, pipeRadius: 0.2)
            let maneMaterial = SCNMaterial()
            maneMaterial.diffuse.contents = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0)
            maneGeometry.materials = [maneMaterial]
            
            let maneNode = SCNNode(geometry: maneGeometry)
            maneNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            node.addChildNode(maneNode)
            
        default:
            break
        }
    }
    
    private func getAnimalColor(for animal: AnimalType) -> UIColor {
        switch animal {
        case .rabbit: return UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0)
        case .bear: return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .elephant: return UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        case .giraffe: return UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        case .lion: return UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
        case .panda: return UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        }
    }
    
    func rotateBoard(duration: TimeInterval = 3.0) {
        guard let boardNode = boardNode else { return }
        
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: duration)
        rotation.timingMode = .easeInEaseOut
        boardNode.runAction(rotation)
    }
    
    func animateAnimals() {
        for (_, node) in animalNodes {
            let jump = SCNAction.sequence([
                SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 0.2),
                SCNAction.moveBy(x: 0, y: -0.5, z: 0, duration: 0.2)
            ])
            jump.timingMode = .easeInEaseOut
            
            let delay = SCNAction.wait(duration: Double.random(in: 0...0.3))
            let sequence = SCNAction.sequence([delay, jump])
            
            node.runAction(sequence)
        }
    }
    
    func highlightAnimal(_ animal: AnimalType) {
        guard let node = animalNodes[animal] else { return }
        
        let pulse = SCNAction.sequence([
            SCNAction.scale(to: 1.2, duration: 0.3),
            SCNAction.scale(to: 1.0, duration: 0.3)
        ])
        pulse.timingMode = .easeInEaseOut
        
        node.runAction(SCNAction.repeatForever(pulse), forKey: "highlight")
    }
    
    func removeHighlight(_ animal: AnimalType) {
        guard let node = animalNodes[animal] else { return }
        node.removeAction(forKey: "highlight")
        node.scale = SCNVector3(1, 1, 1)
    }
    
    func resetBoard() {
        boardNode?.removeAllActions()
        animalNodes.values.forEach { node in
            node.removeAllActions()
            node.scale = SCNVector3(1, 1, 1)
        }
    }
}