import SceneKit
import UIKit

class SceneManager: ObservableObject {
    var scene: SCNScene
    private var boardNode: SCNNode?
    private var animalNodes: [AnimalType: SCNNode] = [:]
    private var cardNodes: [SCNNode] = []
    private var gridSize: Int = 3
    private var selectedAnimals: [AnimalType] = []
    private var highlightedCardIndex: Int?
    
    init() {
        scene = SCNScene()
        setupScene()
        createBoard()
        setupAnimalsAndCards()
    }
    
    func setupScene() {
        // 背景をグラデーションに
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(x: 0, y: 0, width: 1024, height: 1024)
        gradientLayer.colors = [
            UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.85, green: 0.93, blue: 0.98, alpha: 1.0).cgColor,
            UIColor(red: 0.75, green: 0.88, blue: 0.95, alpha: 1.0).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        
        UIGraphicsBeginImageContext(gradientLayer.bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            scene.background.contents = gradientImage
        } else {
            scene.background.contents = UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1.0)
        }
        
        // 背景に雲を追加
        addClouds()
        
        // ライティング設定
        // 環境光（全体的に明るく）
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.color = UIColor(white: 0.75, alpha: 1.0)
        ambientLight.intensity = 1000
        
        let ambientLightNode = SCNNode()
        ambientLightNode.light = ambientLight
        scene.rootNode.addChildNode(ambientLightNode)
        
        // メインライト（太陽光のような）
        let mainLight = SCNLight()
        mainLight.type = .directional
        mainLight.color = UIColor(red: 1.0, green: 0.95, blue: 0.8, alpha: 1.0)
        mainLight.intensity = 1500
        mainLight.castsShadow = true
        mainLight.shadowMode = .forward
        mainLight.shadowColor = UIColor(white: 0, alpha: 0.3)
        mainLight.shadowRadius = 10
        mainLight.shadowSampleCount = 8
        
        let mainLightNode = SCNNode()
        mainLightNode.light = mainLight
        mainLightNode.position = SCNVector3(5, 10, 5)
        mainLightNode.eulerAngles = SCNVector3(-Float.pi/3, -Float.pi/4, 0)
        scene.rootNode.addChildNode(mainLightNode)
        
        // フィルライト（影を柔らかくする）
        let fillLight = SCNLight()
        fillLight.type = .directional
        fillLight.color = UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 1.0)
        fillLight.intensity = 500
        
        let fillLightNode = SCNNode()
        fillLightNode.light = fillLight
        fillLightNode.position = SCNVector3(-5, 8, -5)
        fillLightNode.eulerAngles = SCNVector3(-Float.pi/4, Float.pi/4, 0)
        scene.rootNode.addChildNode(fillLightNode)
        
        // カメラ設定
        let camera = SCNCamera()
        camera.fieldOfView = 45
        camera.zNear = 0.1
        camera.zFar = 100
        
        let cameraNode = SCNNode()
        cameraNode.name = "cameraNode"
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 8, 12)
        cameraNode.eulerAngles = SCNVector3(-0.4, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func createBoard() {
        boardNode = SCNNode()
        boardNode?.name = "boardNode"
        
        // ボード本体（正方形に変更）
        let boardGeometry = SCNBox(width: 10, height: 0.3, length: 10, chamferRadius: 0.5)
        let boardMaterial = SCNMaterial()
        boardMaterial.diffuse.contents = UIColor(red: 0.98, green: 0.95, blue: 0.85, alpha: 1.0)
        boardMaterial.specular.contents = UIColor.white
        boardMaterial.shininess = 0.1
        boardGeometry.materials = [boardMaterial]
        
        let board = SCNNode(geometry: boardGeometry)
        board.position = SCNVector3(0, 0, 0)
        boardNode?.addChildNode(board)
        
        if let boardNode = boardNode {
            scene.rootNode.addChildNode(boardNode)
        }
    }
    
    func setupAnimalsAndCards() {
        // selectedAnimalsが設定されていない場合のみランダムに選択
        if selectedAnimals.isEmpty {
            selectedAnimals = AnimalType.allCases.shuffled().prefix(4).map { $0 }
        }
        createAnimalPositions()
        createCardGrid()
    }
    
    func setSelectedAnimals(_ animals: [AnimalType]) {
        selectedAnimals = animals
        // 既存の動物を削除して新しい動物で再作成
        animalNodes.values.forEach { $0.removeFromParentNode() }
        animalNodes.removeAll()
        createAnimalPositions()
    }
    
    func createAnimalPositions() {
        // 既存の動物ノードを削除
        animalNodes.values.forEach { $0.removeFromParentNode() }
        animalNodes.removeAll()
        
        // 4辺に動物を配置（上、右、下、左）
        let positions: [(Float, Float, Float)] = [
            (0, 0.7, -6),    // 上
            (6, 0.7, 0),     // 右
            (0, 0.7, 6),     // 下
            (-6, 0.7, 0)     // 左
        ]
        
        let rotations: [Float] = [
            0,                // 上向き（デフォルト）
            -Float.pi / 2,    // 右向き
            Float.pi,         // 下向き
            Float.pi / 2      // 左向き
        ]
        
        for (index, animal) in selectedAnimals.enumerated() {
            let animalNode = createCuteAnimalNode(for: animal)
            animalNode.position = SCNVector3(positions[index].0, positions[index].1, positions[index].2)
            animalNode.eulerAngles = SCNVector3(0, rotations[index], 0)
            
            animalNodes[animal] = animalNode
            boardNode?.addChildNode(animalNode)
        }
    }
    
    func createCardGrid() {
        // 既存のカードを削除
        cardNodes.forEach { $0.removeFromParentNode() }
        cardNodes.removeAll()
        
        let cardSize: Float = 1.2
        let spacing: Float = 0.3
        let totalSize = Float(gridSize) * cardSize + Float(gridSize - 1) * spacing
        let startOffset = -totalSize / 2 + cardSize / 2
        
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cardNode = createCardNode(index: row * gridSize + col)
                
                let x = startOffset + Float(col) * (cardSize + spacing)
                let z = startOffset + Float(row) * (cardSize + spacing)
                
                cardNode.position = SCNVector3(x, 0.2, z)
                cardNodes.append(cardNode)
                boardNode?.addChildNode(cardNode)
            }
        }
    }
    
    private func createCardNode(index: Int) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.name = "card_\(index)"
        
        // カード本体
        let cardGeometry = SCNBox(width: 1.2, height: 0.1, length: 1.2, chamferRadius: 0.1)
        let cardMaterial = SCNMaterial()
        cardMaterial.diffuse.contents = UIColor.white
        cardMaterial.specular.contents = UIColor.white
        cardMaterial.shininess = 0.1
        cardGeometry.materials = [cardMaterial]
        
        let cardNode = SCNNode(geometry: cardGeometry)
        containerNode.addChildNode(cardNode)
        
        // カードの表面に模様を追加
        let patternGeometry = SCNBox(width: 1.0, height: 0.01, length: 1.0, chamferRadius: 0.08)
        let patternMaterial = SCNMaterial()
        patternMaterial.diffuse.contents = getRandomCardColor()
        patternGeometry.materials = [patternMaterial]
        
        let patternNode = SCNNode(geometry: patternGeometry)
        patternNode.position = SCNVector3(0, 0.06, 0)
        containerNode.addChildNode(patternNode)
        
        // カードに番号を表示（デバッグ用、後で削除可能）
        let textGeometry = SCNText(string: "\(index + 1)", extrusionDepth: 0.01)
        textGeometry.font = UIFont.systemFont(ofSize: 0.3)
        textGeometry.flatness = 0.1
        let textMaterial = SCNMaterial()
        textMaterial.diffuse.contents = UIColor.darkGray
        textGeometry.materials = [textMaterial]
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(-0.15, 0.07, -0.15)
        textNode.scale = SCNVector3(1, 1, 1)
        containerNode.addChildNode(textNode)
        
        return containerNode
    }
    
    private func getRandomCardColor() -> UIColor {
        let colors = [
            UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.8, green: 1.0, blue: 0.8, alpha: 1.0),
            UIColor(red: 0.8, green: 0.8, blue: 1.0, alpha: 1.0),
            UIColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0),
            UIColor(red: 1.0, green: 0.8, blue: 1.0, alpha: 1.0),
            UIColor(red: 0.8, green: 1.0, blue: 1.0, alpha: 1.0)
        ]
        return colors.randomElement() ?? UIColor.white
    }
    
    func updateForDifficulty(gridSize: Int) {
        self.gridSize = gridSize
        // 動物は再選択せず、カードグリッドのみ更新
        createCardGrid()
    }
    
    func highlightCard(at index: Int) {
        // 前の点滅を停止
        if let previousIndex = highlightedCardIndex,
           previousIndex < cardNodes.count {
            cardNodes[previousIndex].removeAllActions()
            cardNodes[previousIndex].opacity = 1.0
        }
        
        // 新しいカードを点滅
        if index < cardNodes.count {
            highlightedCardIndex = index
            let fadeIn = SCNAction.fadeIn(duration: 0.3)
            let fadeOut = SCNAction.fadeOut(duration: 0.3)
            let pulse = SCNAction.sequence([fadeOut, fadeIn])
            let repeatPulse = SCNAction.repeatForever(pulse)
            
            cardNodes[index].runAction(repeatPulse)
        }
    }
    
    func getSelectedAnimals() -> [AnimalType] {
        return selectedAnimals
    }
    
    func getAnimalPosition(for animal: AnimalType) -> Int? {
        return selectedAnimals.firstIndex(of: animal)
    }
    
    // スワイプによる視点変更のためのメソッド
    func switchToAnimalView(animal: AnimalType) {
        guard let animalNode = animalNodes[animal] else { return }
        
        // カメラを動物の視点に移動
        let camera = scene.rootNode.childNode(withName: "cameraNode", recursively: true) ?? scene.rootNode.childNodes.first { $0.camera != nil }
        
        guard let cameraNode = camera else { return }
        
        // 動物の位置を取得
        let animalPosition = animalNode.worldPosition
        
        // カメラを動物の位置に配置（少し後ろに下がった位置）
        let cameraDistance: Float = 3.0  // 動物から少し後ろに下がる距離
        let cameraHeight: Float = 2.5    // カメラの高さ
        
        // ボードの中心（0, 0, 0）への方向ベクトルを計算
        let directionToCenter = SCNVector3(
            -animalPosition.x,
            0,
            -animalPosition.z
        )
        
        // 方向ベクトルを正規化
        let length = sqrt(directionToCenter.x * directionToCenter.x + directionToCenter.z * directionToCenter.z)
        let normalizedDirection = SCNVector3(
            directionToCenter.x / length,
            0,
            directionToCenter.z / length
        )
        
        // カメラの位置を計算（動物の位置から少し後ろに下がった位置）
        let cameraPosition = SCNVector3(
            animalPosition.x - normalizedDirection.x * cameraDistance,
            animalPosition.y + cameraHeight,
            animalPosition.z - normalizedDirection.z * cameraDistance
        )
        
        // カメラの向きを計算（中央を見る）
        let lookAtCenter = SCNLookAtConstraint(target: boardNode)
        lookAtCenter.isGimbalLockEnabled = true
        
        // アニメーションでカメラを移動
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        cameraNode.position = cameraPosition
        cameraNode.constraints = [lookAtCenter]
        
        SCNTransaction.commit()
    }
    
    func resetCameraView() {
        let camera = scene.rootNode.childNode(withName: "cameraNode", recursively: true) ?? scene.rootNode.childNodes.first { $0.camera != nil }
        
        guard let cameraNode = camera else { return }
        
        // カメラの制約をクリア
        cameraNode.constraints = []
        
        // デフォルトのカメラ位置に戻す
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        cameraNode.position = SCNVector3(0, 8, 12)
        cameraNode.eulerAngles = SCNVector3(-0.4, 0, 0)
        
        SCNTransaction.commit()
    }
    
    // 既存のヘルパーメソッド
    private func createCuteAnimalNode(for animal: AnimalType) -> SCNNode {
        let containerNode = SCNNode()
        containerNode.name = animal.rawValue
        
        // かわいい台座
        let baseGeometry = SCNCylinder(radius: 0.8, height: 0.15)
        let baseMaterial = SCNMaterial()
        baseMaterial.diffuse.contents = UIColor(red: 0.98, green: 0.95, blue: 0.9, alpha: 1.0)
        baseMaterial.specular.contents = UIColor.white
        baseMaterial.shininess = 0.1
        baseGeometry.materials = [baseMaterial]
        
        let baseNode = SCNNode(geometry: baseGeometry)
        baseNode.position = SCNVector3(0, -0.6, 0)
        containerNode.addChildNode(baseNode)
        
        // 台座の装飾
        let decorGeometry = SCNTorus(ringRadius: 0.75, pipeRadius: 0.05)
        let decorMaterial = SCNMaterial()
        decorMaterial.diffuse.contents = getAnimalAccentColor(for: animal)
        decorGeometry.materials = [decorMaterial]
        
        let decorNode = SCNNode(geometry: decorGeometry)
        decorNode.position = SCNVector3(0, -0.5, 0)
        containerNode.addChildNode(decorNode)
        
        // 動物ごとにかわいい形状を作成
        let animalShape = createCuteAnimalShape(for: animal)
        containerNode.addChildNode(animalShape)
        
        return containerNode
    }
    
    private func createCuteAnimalShape(for animal: AnimalType) -> SCNNode {
        let node = SCNNode()
        
        switch animal {
        case .rabbit:
            createCuteRabbit(node: node)
        case .bear:
            createCuteBear(node: node)
        case .elephant:
            createCuteElephant(node: node)
        case .giraffe:
            createCuteGiraffe(node: node)
        case .lion:
            createCuteLion(node: node)
        case .panda:
            createCutePanda(node: node)
        }
        
        return node
    }
    
    // 動物作成メソッド（前回のコードから継続）
    private func createCuteRabbit(node: SCNNode) {
        // 体
        let bodyGeometry = SCNSphere(radius: 0.5)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0)
        bodyGeometry.materials = [bodyMaterial]
        
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        node.addChildNode(bodyNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.4)
        headGeometry.materials = [bodyMaterial]
        
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.6, 0)
        node.addChildNode(headNode)
        
        // 耳
        let earGeometry = SCNCapsule(capRadius: 0.08, height: 0.5)
        let earMaterial = SCNMaterial()
        earMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1.0)
        earGeometry.materials = [earMaterial]
        
        let leftEar = SCNNode(geometry: earGeometry)
        leftEar.position = SCNVector3(-0.15, 0.9, 0)
        leftEar.eulerAngles = SCNVector3(0, 0, 0.2)
        node.addChildNode(leftEar)
        
        let rightEar = SCNNode(geometry: earGeometry)
        rightEar.position = SCNVector3(0.15, 0.9, 0)
        rightEar.eulerAngles = SCNVector3(0, 0, -0.2)
        node.addChildNode(rightEar)
        
        // 目
        createEyes(parentNode: node, yPosition: 0.65, zPosition: 0.35)
        
        // 鼻
        let noseGeometry = SCNSphere(radius: 0.05)
        let noseMaterial = SCNMaterial()
        noseMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0)
        noseGeometry.materials = [noseMaterial]
        
        let noseNode = SCNNode(geometry: noseGeometry)
        noseNode.position = SCNVector3(0, 0.55, 0.4)
        node.addChildNode(noseNode)
    }
    
    private func createCuteBear(node: SCNNode) {
        // 体
        let bodyGeometry = SCNSphere(radius: 0.6)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        bodyGeometry.materials = [bodyMaterial]
        
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        node.addChildNode(bodyNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.45)
        headGeometry.materials = [bodyMaterial]
        
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.65, 0)
        node.addChildNode(headNode)
        
        // 耳
        let earGeometry = SCNSphere(radius: 0.15)
        earGeometry.materials = [bodyMaterial]
        
        let leftEar = SCNNode(geometry: earGeometry)
        leftEar.position = SCNVector3(-0.3, 0.9, 0)
        node.addChildNode(leftEar)
        
        let rightEar = SCNNode(geometry: earGeometry)
        rightEar.position = SCNVector3(0.3, 0.9, 0)
        node.addChildNode(rightEar)
        
        // 鼻先
        let snoutGeometry = SCNSphere(radius: 0.2)
        let snoutMaterial = SCNMaterial()
        snoutMaterial.diffuse.contents = UIColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 1.0)
        snoutGeometry.materials = [snoutMaterial]
        
        let snoutNode = SCNNode(geometry: snoutGeometry)
        snoutNode.position = SCNVector3(0, 0.55, 0.35)
        node.addChildNode(snoutNode)
        
        // 目
        createEyes(parentNode: node, yPosition: 0.7, zPosition: 0.35)
        
        // 鼻
        let noseGeometry = SCNSphere(radius: 0.08)
        let noseMaterial = SCNMaterial()
        noseMaterial.diffuse.contents = UIColor.black
        noseGeometry.materials = [noseMaterial]
        
        let noseNode = SCNNode(geometry: noseGeometry)
        noseNode.position = SCNVector3(0, 0.55, 0.5)
        node.addChildNode(noseNode)
    }
    
    private func createCuteElephant(node: SCNNode) {
        // 体
        let bodyGeometry = SCNBox(width: 1.0, height: 0.8, length: 0.8, chamferRadius: 0.3)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 1.0)
        bodyGeometry.materials = [bodyMaterial]
        
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        node.addChildNode(bodyNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.5)
        headGeometry.materials = [bodyMaterial]
        
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.7, 0)
        node.addChildNode(headNode)
        
        // 耳（大きな扇形）
        let earGeometry = SCNBox(width: 0.4, height: 0.5, length: 0.1, chamferRadius: 0.2)
        earGeometry.materials = [bodyMaterial]
        
        let leftEar = SCNNode(geometry: earGeometry)
        leftEar.position = SCNVector3(-0.5, 0.7, 0)
        leftEar.eulerAngles = SCNVector3(0, -0.3, 0)
        node.addChildNode(leftEar)
        
        let rightEar = SCNNode(geometry: earGeometry)
        rightEar.position = SCNVector3(0.5, 0.7, 0)
        rightEar.eulerAngles = SCNVector3(0, 0.3, 0)
        node.addChildNode(rightEar)
        
        // 鼻（ぞうの鼻）
        let trunkGeometry = SCNCylinder(radius: 0.15, height: 0.8)
        trunkGeometry.materials = [bodyMaterial]
        
        let trunkNode = SCNNode(geometry: trunkGeometry)
        trunkNode.position = SCNVector3(0, 0.3, 0.4)
        trunkNode.eulerAngles = SCNVector3(Float.pi/4, 0, 0)
        node.addChildNode(trunkNode)
        
        // 目
        createEyes(parentNode: node, yPosition: 0.8, zPosition: 0.4)
    }
    
    private func createCuteGiraffe(node: SCNNode) {
        // 体
        let bodyGeometry = SCNBox(width: 0.6, height: 0.8, length: 0.5, chamferRadius: 0.2)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.9, blue: 0.6, alpha: 1.0)
        bodyGeometry.materials = [bodyMaterial]
        
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        node.addChildNode(bodyNode)
        
        // 首
        let neckGeometry = SCNCylinder(radius: 0.2, height: 1.0)
        neckGeometry.materials = [bodyMaterial]
        
        let neckNode = SCNNode(geometry: neckGeometry)
        neckNode.position = SCNVector3(0, 0.8, 0)
        node.addChildNode(neckNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.3)
        headGeometry.materials = [bodyMaterial]
        
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 1.4, 0)
        node.addChildNode(headNode)
        
        // 角（つの）
        let hornGeometry = SCNCone(topRadius: 0, bottomRadius: 0.05, height: 0.2)
        let hornMaterial = SCNMaterial()
        hornMaterial.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        hornGeometry.materials = [hornMaterial]
        
        let leftHorn = SCNNode(geometry: hornGeometry)
        leftHorn.position = SCNVector3(-0.1, 1.6, 0)
        node.addChildNode(leftHorn)
        
        let rightHorn = SCNNode(geometry: hornGeometry)
        rightHorn.position = SCNVector3(0.1, 1.6, 0)
        node.addChildNode(rightHorn)
        
        // 目
        createEyes(parentNode: node, yPosition: 1.4, zPosition: 0.25)
        
        // 模様（スポット）
        for _ in 0..<5 {
            let spotGeometry = SCNSphere(radius: 0.1)
            let spotMaterial = SCNMaterial()
            spotMaterial.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
            spotGeometry.materials = [spotMaterial]
            
            let spotNode = SCNNode(geometry: spotGeometry)
            spotNode.position = SCNVector3(
                Float.random(in: -0.25...0.25),
                Float.random(in: -0.3...1.0),
                0.26
            )
            node.addChildNode(spotNode)
        }
    }
    
    private func createCuteLion(node: SCNNode) {
        // 体
        let bodyGeometry = SCNSphere(radius: 0.6)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        bodyGeometry.materials = [bodyMaterial]
        
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        node.addChildNode(bodyNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.45)
        headGeometry.materials = [bodyMaterial]
        
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.7, 0)
        node.addChildNode(headNode)
        
        // たてがみ
        let maneGeometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.2)
        let maneMaterial = SCNMaterial()
        maneMaterial.diffuse.contents = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0)
        maneGeometry.materials = [maneMaterial]
        
        let maneNode = SCNNode(geometry: maneGeometry)
        maneNode.position = SCNVector3(0, 0.7, 0)
        maneNode.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        node.addChildNode(maneNode)
        
        // 耳
        let earGeometry = SCNPyramid(width: 0.2, height: 0.2, length: 0.1)
        earGeometry.materials = [bodyMaterial]
        
        let leftEar = SCNNode(geometry: earGeometry)
        leftEar.position = SCNVector3(-0.3, 1.0, 0)
        leftEar.eulerAngles = SCNVector3(0, 0, -Float.pi/4)
        node.addChildNode(leftEar)
        
        let rightEar = SCNNode(geometry: earGeometry)
        rightEar.position = SCNVector3(0.3, 1.0, 0)
        rightEar.eulerAngles = SCNVector3(0, 0, Float.pi/4)
        node.addChildNode(rightEar)
        
        // 目
        createEyes(parentNode: node, yPosition: 0.75, zPosition: 0.4)
        
        // 鼻
        let noseGeometry = SCNPyramid(width: 0.15, height: 0.1, length: 0.15)
        let noseMaterial = SCNMaterial()
        noseMaterial.diffuse.contents = UIColor(red: 0.2, green: 0.1, blue: 0.1, alpha: 1.0)
        noseGeometry.materials = [noseMaterial]
        
        let noseNode = SCNNode(geometry: noseGeometry)
        noseNode.position = SCNVector3(0, 0.65, 0.45)
        noseNode.eulerAngles = SCNVector3(Float.pi/2, 0, 0)
        node.addChildNode(noseNode)
    }
    
    private func createCutePanda(node: SCNNode) {
        // 体（白）
        let bodyGeometry = SCNSphere(radius: 0.6)
        let whiteMaterial = SCNMaterial()
        whiteMaterial.diffuse.contents = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        bodyGeometry.materials = [whiteMaterial]
        
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        node.addChildNode(bodyNode)
        
        // 頭（白）
        let headGeometry = SCNSphere(radius: 0.45)
        headGeometry.materials = [whiteMaterial]
        
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.65, 0)
        node.addChildNode(headNode)
        
        // 耳（黒）
        let blackMaterial = SCNMaterial()
        blackMaterial.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        
        let earGeometry = SCNSphere(radius: 0.15)
        earGeometry.materials = [blackMaterial]
        
        let leftEar = SCNNode(geometry: earGeometry)
        leftEar.position = SCNVector3(-0.3, 0.9, 0)
        node.addChildNode(leftEar)
        
        let rightEar = SCNNode(geometry: earGeometry)
        rightEar.position = SCNVector3(0.3, 0.9, 0)
        node.addChildNode(rightEar)
        
        // 目の周り（黒）
        let eyePatchGeometry = SCNSphere(radius: 0.15)
        eyePatchGeometry.materials = [blackMaterial]
        
        let leftEyePatch = SCNNode(geometry: eyePatchGeometry)
        leftEyePatch.position = SCNVector3(-0.15, 0.7, 0.35)
        leftEyePatch.scale = SCNVector3(1.2, 1, 0.5)
        node.addChildNode(leftEyePatch)
        
        let rightEyePatch = SCNNode(geometry: eyePatchGeometry)
        rightEyePatch.position = SCNVector3(0.15, 0.7, 0.35)
        rightEyePatch.scale = SCNVector3(1.2, 1, 0.5)
        node.addChildNode(rightEyePatch)
        
        // 目
        createEyes(parentNode: node, yPosition: 0.7, zPosition: 0.4, eyeColor: UIColor.white)
        
        // 鼻
        let noseGeometry = SCNSphere(radius: 0.08)
        noseGeometry.materials = [blackMaterial]
        
        let noseNode = SCNNode(geometry: noseGeometry)
        noseNode.position = SCNVector3(0, 0.6, 0.45)
        node.addChildNode(noseNode)
        
        // 腕（黒）
        let armGeometry = SCNSphere(radius: 0.25)
        armGeometry.materials = [blackMaterial]
        
        let leftArm = SCNNode(geometry: armGeometry)
        leftArm.position = SCNVector3(-0.5, 0, 0)
        node.addChildNode(leftArm)
        
        let rightArm = SCNNode(geometry: armGeometry)
        rightArm.position = SCNVector3(0.5, 0, 0)
        node.addChildNode(rightArm)
    }
    
    // ヘルパーメソッド
    private func createEyes(parentNode: SCNNode, yPosition: Float, zPosition: Float, eyeColor: UIColor = UIColor.black) {
        let eyeGeometry = SCNSphere(radius: 0.05)
        let eyeMaterial = SCNMaterial()
        eyeMaterial.diffuse.contents = eyeColor
        eyeGeometry.materials = [eyeMaterial]
        
        let leftEye = SCNNode(geometry: eyeGeometry)
        leftEye.position = SCNVector3(-0.1, yPosition, zPosition)
        parentNode.addChildNode(leftEye)
        
        let rightEye = SCNNode(geometry: eyeGeometry)
        rightEye.position = SCNVector3(0.1, yPosition, zPosition)
        parentNode.addChildNode(rightEye)
        
        // 目の輝き
        if eyeColor != UIColor.white {
            let highlightGeometry = SCNSphere(radius: 0.02)
            let highlightMaterial = SCNMaterial()
            highlightMaterial.diffuse.contents = UIColor.white
            highlightGeometry.materials = [highlightMaterial]
            
            let leftHighlight = SCNNode(geometry: highlightGeometry)
            leftHighlight.position = SCNVector3(-0.08, yPosition + 0.02, zPosition + 0.03)
            parentNode.addChildNode(leftHighlight)
            
            let rightHighlight = SCNNode(geometry: highlightGeometry)
            rightHighlight.position = SCNVector3(0.12, yPosition + 0.02, zPosition + 0.03)
            parentNode.addChildNode(rightHighlight)
        }
    }
    
    private func getAnimalAccentColor(for animal: AnimalType) -> UIColor {
        switch animal {
        case .rabbit:
            return UIColor(red: 1.0, green: 0.8, blue: 0.8, alpha: 1.0)
        case .bear:
            return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .elephant:
            return UIColor(red: 0.6, green: 0.6, blue: 0.7, alpha: 1.0)
        case .giraffe:
            return UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
        case .lion:
            return UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
        case .panda:
            return UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        }
    }
    
    private func addClouds() {
        // 複数の雲を追加
        for i in 0..<5 {
            let cloudNode = createCloudNode()
            cloudNode.position = SCNVector3(
                Float.random(in: -10...10),
                Float.random(in: 8...12),
                Float.random(in: -15...(-10))
            )
            cloudNode.scale = SCNVector3(
                Float.random(in: 0.8...1.5),
                Float.random(in: 0.8...1.2),
                Float.random(in: 0.8...1.5)
            )
            
            // ゆっくり動く雲
            let moveDistance = Float.random(in: 2...4)
            let moveDuration = Double.random(in: 10...20)
            let moveRight = SCNAction.moveBy(x: CGFloat(moveDistance), y: 0, z: 0, duration: moveDuration)
            let moveLeft = SCNAction.moveBy(x: CGFloat(-moveDistance), y: 0, z: 0, duration: moveDuration)
            let moveSequence = SCNAction.sequence([moveRight, moveLeft])
            let moveForever = SCNAction.repeatForever(moveSequence)
            
            cloudNode.runAction(moveForever)
            scene.rootNode.addChildNode(cloudNode)
        }
    }
    
    private func createCloudNode() -> SCNNode {
        let cloudNode = SCNNode()
        
        // 雲を複数の球体で構成
        let cloudParts = [
            (radius: 0.8, position: SCNVector3(0, 0, 0)),
            (radius: 0.6, position: SCNVector3(-0.6, 0.1, 0)),
            (radius: 0.7, position: SCNVector3(0.6, 0, 0)),
            (radius: 0.5, position: SCNVector3(0, 0, -0.4)),
            (radius: 0.6, position: SCNVector3(0.3, -0.1, 0.3))
        ]
        
        let cloudMaterial = SCNMaterial()
        cloudMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.9)
        cloudMaterial.transparency = 0.8
        
        for part in cloudParts {
            let partGeometry = SCNSphere(radius: CGFloat(part.radius))
            partGeometry.materials = [cloudMaterial]
            
            let partNode = SCNNode(geometry: partGeometry)
            partNode.position = part.position
            cloudNode.addChildNode(partNode)
        }
        
        return cloudNode
    }
    
    private func createStarNode() -> SCNNode {
        let starPath = UIBezierPath()
        let numberOfPoints = 5
        let radius: CGFloat = 0.5
        let innerRadius: CGFloat = 0.2
        
        for i in 0..<numberOfPoints * 2 {
            let angle = (CGFloat(i) * CGFloat.pi) / CGFloat(numberOfPoints)
            let r = (i % 2 == 0) ? radius : innerRadius
            let x = r * cos(angle)
            let y = r * sin(angle)
            
            if i == 0 {
                starPath.move(to: CGPoint(x: x, y: y))
            } else {
                starPath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        starPath.close()
        
        let starShape = SCNShape(path: starPath, extrusionDepth: 0.1)
        let starMaterial = SCNMaterial()
        starMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        starMaterial.specular.contents = UIColor.white
        starMaterial.shininess = 1.0
        starShape.materials = [starMaterial]
        
        let starNode = SCNNode(geometry: starShape)
        starNode.eulerAngles = SCNVector3(-Float.pi/2, 0, 0)
        
        // 星を回転させる
        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 10)
        let repeatRotate = SCNAction.repeatForever(rotate)
        starNode.runAction(repeatRotate)
        
        return starNode
    }
    
    // その他のメソッド（既存のコードから必要なものを継続）
    func rotateBoard() {
        guard let boardNode = boardNode else { return }
        
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 3)
        boardNode.runAction(rotation)
    }
    
    func highlightAnimal(_ animal: AnimalType) {
        guard let animalNode = animalNodes[animal] else { return }
        
        let scaleUp = SCNAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SCNAction.scale(to: 1.0, duration: 0.2)
        let pulse = SCNAction.sequence([scaleUp, scaleDown])
        
        animalNode.runAction(pulse)
    }
    
    func bounceAnimal(_ animal: AnimalType) {
        guard let animalNode = animalNodes[animal] else { return }
        
        let moveUp = SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 0.3)
        moveUp.timingMode = .easeOut
        let moveDown = SCNAction.moveBy(x: 0, y: -0.5, z: 0, duration: 0.3)
        moveDown.timingMode = .easeIn
        let bounce = SCNAction.sequence([moveUp, moveDown])
        
        animalNode.runAction(bounce)
    }
    
    func handleTap(at location: CGPoint, in view: SCNView) -> AnimalType? {
        let hitResults = view.hitTest(location, options: nil)
        
        for result in hitResults {
            var currentNode: SCNNode? = result.node
            
            while let node = currentNode {
                if let nodeName = node.name,
                   let animal = AnimalType.allCases.first(where: { $0.rawValue == nodeName }) {
                    return animal
                }
                currentNode = node.parent
            }
        }
        
        return nil
    }
    
    func handleCardTap(at location: CGPoint, in view: SCNView) -> Int? {
        let hitResults = view.hitTest(location, options: nil)
        
        for result in hitResults {
            var currentNode: SCNNode? = result.node
            
            while let node = currentNode {
                if let nodeName = node.name,
                   nodeName.hasPrefix("card_"),
                   let indexString = nodeName.split(separator: "_").last,
                   let index = Int(indexString) {
                    return index
                }
                currentNode = node.parent
            }
        }
        
        return nil
    }
    
    func resetScene() {
        // 既存のノードをクリア
        animalNodes.values.forEach { $0.removeFromParentNode() }
        animalNodes.removeAll()
        cardNodes.forEach { $0.removeFromParentNode() }
        cardNodes.removeAll()
        
        // 新しくセットアップ
        setupAnimalsAndCards()
    }
    
    // 不足している拡張メソッド
    func removeHighlight(_ animal: AnimalType) {
        guard let animalNode = animalNodes[animal] else { return }
        animalNode.removeAllActions()
        animalNode.opacity = 1.0
    }
    
    func animateAnimals() {
        for animalNode in animalNodes.values {
            let bounce = SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 0.3)
            bounce.timingMode = .easeInEaseOut
            let bounceBack = bounce.reversed()
            let sequence = SCNAction.sequence([bounce, bounceBack])
            animalNode.runAction(sequence)
        }
    }
}