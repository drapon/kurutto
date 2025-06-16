import SceneKit
import UIKit

class SceneManager: ObservableObject {
    var scene: SCNScene
    private var boardNode: SCNNode?
    private var animalNodes: [AnimalType: SCNNode] = [:]
    
    init() {
        scene = SCNScene()
        setupScene()
        createBoard()
        createAnimalPositions()
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
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 8, 12)
        cameraNode.eulerAngles = SCNVector3(-0.4, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func createBoard() {
        boardNode = SCNNode()
        
        // ボード本体（よりカラフルに）
        let boardGeometry = SCNCylinder(radius: 5.0, height: 0.3)
        let boardMaterial = SCNMaterial()
        boardMaterial.diffuse.contents = UIColor(red: 0.98, green: 0.95, blue: 0.85, alpha: 1.0)
        boardMaterial.specular.contents = UIColor.white
        boardMaterial.shininess = 0.1
        boardGeometry.materials = [boardMaterial]
        
        let board = SCNNode(geometry: boardGeometry)
        board.position = SCNVector3(0, 0, 0)
        boardNode?.addChildNode(board)
        
        // ボードの縁（カラフルな装飾）
        let rimGeometry = SCNTube(innerRadius: 4.8, outerRadius: 5.2, height: 0.4)
        let rimMaterial = SCNMaterial()
        rimMaterial.diffuse.contents = UIColor(red: 0.9, green: 0.85, blue: 0.95, alpha: 1.0)
        rimGeometry.materials = [rimMaterial]
        
        let rimNode = SCNNode(geometry: rimGeometry)
        rimNode.position = SCNVector3(0, 0, 0)
        boardNode?.addChildNode(rimNode)
        
        // 中心の星マーク
        let starNode = createStarNode()
        starNode.position = SCNVector3(0, 0.2, 0)
        boardNode?.addChildNode(starNode)
        
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
            
            let animalNode = createCuteAnimalNode(for: animal)
            animalNode.position = SCNVector3(x, 0.7, z)
            animalNode.eulerAngles = SCNVector3(0, -angle + Float.pi / 2, 0)  // 中心を向くように回転
            
            animalNodes[animal] = animalNode
            boardNode?.addChildNode(animalNode)
        }
    }
    
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
    
    private func createCuteRabbit(node: SCNNode) {
        // うさぎ：白い楕円体 with 長い耳
        let bodyGeometry = SCNSphere(radius: 0.45)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.98, blue: 0.98, alpha: 1.0)
        bodyMaterial.specular.contents = UIColor.white
        bodyMaterial.shininess = 0.3
        bodyGeometry.materials = [bodyMaterial]
        
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        bodyNode.scale = SCNVector3(1.0, 1.2, 0.9)
        node.addChildNode(bodyNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.35)
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.35, 0.1)
        headNode.geometry?.materials = [bodyMaterial]
        node.addChildNode(headNode)
        
        // 耳（よりかわいく）
        for i in 0..<2 {
            let earContainer = SCNNode()
            
            // 外側の耳
            let earGeometry = SCNCapsule(capRadius: 0.08, height: 0.5)
            earGeometry.materials = [bodyMaterial]
            let earNode = SCNNode(geometry: earGeometry)
            
            // 内側の耳（ピンク）
            let innerEarGeometry = SCNCapsule(capRadius: 0.05, height: 0.35)
            let innerEarMaterial = SCNMaterial()
            innerEarMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.8, blue: 0.85, alpha: 1.0)
            innerEarGeometry.materials = [innerEarMaterial]
            
            let innerEarNode = SCNNode(geometry: innerEarGeometry)
            innerEarNode.position = SCNVector3(0, 0, 0.02)
            earNode.addChildNode(innerEarNode)
            
            let xOffset: Float = (i == 0) ? -0.15 : 0.15
            earContainer.position = SCNVector3(xOffset, 0.65, -0.05)
            earContainer.eulerAngles = SCNVector3(-0.1, 0, Float.pi * 0.08 * (i == 0 ? 1 : -1))
            earContainer.addChildNode(earNode)
            
            node.addChildNode(earContainer)
        }
        
        // 目（キラキラした黒い目）
        for i in 0..<2 {
            createCuteEye(parent: node, 
                         position: SCNVector3((i == 0) ? -0.12 : 0.12, 0.38, 0.32),
                         size: 0.06)
        }
        
        // 鼻（ピンクの小さな球）
        let noseGeometry = SCNSphere(radius: 0.04)
        let noseMaterial = SCNMaterial()
        noseMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.7, blue: 0.75, alpha: 1.0)
        noseGeometry.materials = [noseMaterial]
        
        let noseNode = SCNNode(geometry: noseGeometry)
        noseNode.position = SCNVector3(0, 0.25, 0.4)
        node.addChildNode(noseNode)
        
        // しっぽ（丸いふわふわ）
        let tailGeometry = SCNSphere(radius: 0.15)
        tailGeometry.materials = [bodyMaterial]
        let tailNode = SCNNode(geometry: tailGeometry)
        tailNode.position = SCNVector3(0, -0.1, -0.4)
        node.addChildNode(tailNode)
    }
    
    private func createCuteBear(node: SCNNode) {
        // くま：茶色い丸っこい体
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 0.65, green: 0.45, blue: 0.3, alpha: 1.0)
        bodyMaterial.specular.contents = UIColor(red: 0.7, green: 0.5, blue: 0.35, alpha: 1.0)
        bodyMaterial.shininess = 0.2
        
        // 体
        let bodyGeometry = SCNSphere(radius: 0.5)
        bodyGeometry.materials = [bodyMaterial]
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        bodyNode.scale = SCNVector3(1.1, 1.0, 0.9)
        node.addChildNode(bodyNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.4)
        headGeometry.materials = [bodyMaterial]
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.35, 0.1)
        node.addChildNode(headNode)
        
        // 耳（丸くてかわいい）
        for i in 0..<2 {
            let earGeometry = SCNSphere(radius: 0.12)
            earGeometry.materials = [bodyMaterial]
            let earNode = SCNNode(geometry: earGeometry)
            
            let xOffset: Float = (i == 0) ? -0.25 : 0.25
            earNode.position = SCNVector3(xOffset, 0.55, -0.05)
            node.addChildNode(earNode)
            
            // 耳の内側
            let innerEarGeometry = SCNSphere(radius: 0.06)
            let innerEarMaterial = SCNMaterial()
            innerEarMaterial.diffuse.contents = UIColor(red: 0.75, green: 0.55, blue: 0.4, alpha: 1.0)
            innerEarGeometry.materials = [innerEarMaterial]
            
            let innerEarNode = SCNNode(geometry: innerEarGeometry)
            innerEarNode.position = SCNVector3(0, 0, 0.08)
            earNode.addChildNode(innerEarNode)
        }
        
        // おなか（明るい茶色）
        let bellyGeometry = SCNSphere(radius: 0.35)
        let bellyMaterial = SCNMaterial()
        bellyMaterial.diffuse.contents = UIColor(red: 0.75, green: 0.55, blue: 0.4, alpha: 1.0)
        bellyGeometry.materials = [bellyMaterial]
        
        let bellyNode = SCNNode(geometry: bellyGeometry)
        bellyNode.position = SCNVector3(0, -0.05, 0.25)
        bellyNode.scale = SCNVector3(0.8, 0.7, 0.5)
        node.addChildNode(bellyNode)
        
        // 目
        for i in 0..<2 {
            createCuteEye(parent: node,
                         position: SCNVector3((i == 0) ? -0.12 : 0.12, 0.35, 0.35),
                         size: 0.07)
        }
        
        // 鼻（黒い楕円）
        let noseGeometry = SCNSphere(radius: 0.08)
        let noseMaterial = SCNMaterial()
        noseMaterial.diffuse.contents = UIColor.black
        noseGeometry.materials = [noseMaterial]
        
        let noseNode = SCNNode(geometry: noseGeometry)
        noseNode.position = SCNVector3(0, 0.2, 0.42)
        noseNode.scale = SCNVector3(1.2, 0.8, 0.8)
        node.addChildNode(noseNode)
    }
    
    private func createCuteElephant(node: SCNNode) {
        // ぞう：グレーの大きな体
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1.0)
        bodyMaterial.specular.contents = UIColor(white: 0.8, alpha: 1.0)
        bodyMaterial.shininess = 0.2
        
        // 体
        let bodyGeometry = SCNSphere(radius: 0.55)
        bodyGeometry.materials = [bodyMaterial]
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        bodyNode.scale = SCNVector3(1.2, 1.0, 1.0)
        node.addChildNode(bodyNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.45)
        headGeometry.materials = [bodyMaterial]
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.35, 0.15)
        node.addChildNode(headNode)
        
        // 鼻（シンプルなチューブ）
        let trunkGeometry = SCNCylinder(radius: 0.15, height: 0.8)
        trunkGeometry.materials = [bodyMaterial]
        let trunkNode = SCNNode(geometry: trunkGeometry)
        trunkNode.position = SCNVector3(0, -0.1, 0.5)
        trunkNode.eulerAngles = SCNVector3(Float.pi / 3, 0, 0)
        node.addChildNode(trunkNode)
        
        // 鼻の先
        let trunkTipGeometry = SCNSphere(radius: 0.15)
        trunkTipGeometry.materials = [bodyMaterial]
        let trunkTipNode = SCNNode(geometry: trunkTipGeometry)
        trunkTipNode.position = SCNVector3(0, -0.4, 0)
        trunkNode.addChildNode(trunkTipNode)
        
        // 大きな耳
        for i in 0..<2 {
            let earGeometry = SCNBox(width: 0.5, height: 0.6, length: 0.1, chamferRadius: 0.2)
            let earMaterial = SCNMaterial()
            earMaterial.diffuse.contents = UIColor(red: 0.75, green: 0.75, blue: 0.8, alpha: 1.0)
            earGeometry.materials = [earMaterial]
            
            let earNode = SCNNode(geometry: earGeometry)
            let xOffset: Float = (i == 0) ? -0.45 : 0.45
            earNode.position = SCNVector3(xOffset, 0.3, 0)
            earNode.eulerAngles = SCNVector3(0, (i == 0) ? -0.3 : 0.3, 0)
            node.addChildNode(earNode)
        }
        
        // 目
        for i in 0..<2 {
            createCuteEye(parent: node,
                         position: SCNVector3((i == 0) ? -0.15 : 0.15, 0.4, 0.4),
                         size: 0.06)
        }
    }
    
    private func createCuteGiraffe(node: SCNNode) {
        // きりん：黄色い体に茶色の模様
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
        bodyMaterial.specular.contents = UIColor(red: 1.0, green: 0.95, blue: 0.7, alpha: 1.0)
        bodyMaterial.shininess = 0.3
        
        // 体
        let bodyGeometry = SCNSphere(radius: 0.4)
        bodyGeometry.materials = [bodyMaterial]
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, -0.1, 0)
        node.addChildNode(bodyNode)
        
        // 首（長い）
        let neckGeometry = SCNCylinder(radius: 0.15, height: 0.8)
        neckGeometry.materials = [bodyMaterial]
        let neckNode = SCNNode(geometry: neckGeometry)
        neckNode.position = SCNVector3(0, 0.4, 0)
        node.addChildNode(neckNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.25)
        headGeometry.materials = [bodyMaterial]
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.9, 0.1)
        node.addChildNode(headNode)
        
        // 角（小さな突起）
        for i in 0..<2 {
            let hornGeometry = SCNCone(topRadius: 0, bottomRadius: 0.04, height: 0.15)
            hornGeometry.materials = [bodyMaterial]
            let hornNode = SCNNode(geometry: hornGeometry)
            
            let xOffset: Float = (i == 0) ? -0.08 : 0.08
            hornNode.position = SCNVector3(xOffset, 1.05, -0.05)
            node.addChildNode(hornNode)
            
            // 角の先の球
            let hornTipGeometry = SCNSphere(radius: 0.04)
            let hornTipMaterial = SCNMaterial()
            hornTipMaterial.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
            hornTipGeometry.materials = [hornTipMaterial]
            
            let hornTipNode = SCNNode(geometry: hornTipGeometry)
            hornTipNode.position = SCNVector3(0, 0.08, 0)
            hornNode.addChildNode(hornTipNode)
        }
        
        // 模様（茶色の斑点）
        for _ in 0..<5 {
            let spotGeometry = SCNSphere(radius: CGFloat.random(in: 0.05...0.1))
            let spotMaterial = SCNMaterial()
            spotMaterial.diffuse.contents = UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
            spotGeometry.materials = [spotMaterial]
            
            let spotNode = SCNNode(geometry: spotGeometry)
            let angle = Float.random(in: 0...(Float.pi * 2))
            let height = Float.random(in: -0.3...0.6)
            let radius = Float.random(in: 0.15...0.25)
            
            spotNode.position = SCNVector3(
                radius * cos(angle),
                height,
                radius * sin(angle) + 0.05
            )
            node.addChildNode(spotNode)
        }
        
        // 目
        for i in 0..<2 {
            createCuteEye(parent: node,
                         position: SCNVector3((i == 0) ? -0.08 : 0.08, 0.9, 0.25),
                         size: 0.05)
        }
    }
    
    private func createCuteLion(node: SCNNode) {
        // らいおん：黄金色の体にたてがみ
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = UIColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1.0)
        bodyMaterial.specular.contents = UIColor(red: 1.0, green: 0.8, blue: 0.5, alpha: 1.0)
        bodyMaterial.shininess = 0.3
        
        // 体
        let bodyGeometry = SCNSphere(radius: 0.45)
        bodyGeometry.materials = [bodyMaterial]
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        node.addChildNode(bodyNode)
        
        // 頭
        let headGeometry = SCNSphere(radius: 0.35)
        headGeometry.materials = [bodyMaterial]
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.35, 0.15)
        node.addChildNode(headNode)
        
        // たてがみ（ふわふわの円）
        let maneGeometry = SCNTorus(ringRadius: 0.4, pipeRadius: 0.15)
        let maneMaterial = SCNMaterial()
        maneMaterial.diffuse.contents = UIColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0)
        maneGeometry.materials = [maneMaterial]
        
        let maneNode = SCNNode(geometry: maneGeometry)
        maneNode.position = SCNVector3(0, 0.35, 0.1)
        maneNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        node.addChildNode(maneNode)
        
        // 耳
        for i in 0..<2 {
            let earGeometry = SCNCone(topRadius: 0, bottomRadius: 0.08, height: 0.12)
            earGeometry.materials = [bodyMaterial]
            let earNode = SCNNode(geometry: earGeometry)
            
            let xOffset: Float = (i == 0) ? -0.2 : 0.2
            earNode.position = SCNVector3(xOffset, 0.55, 0)
            earNode.eulerAngles = SCNVector3(0, 0, Float.pi)
            node.addChildNode(earNode)
        }
        
        // 目
        for i in 0..<2 {
            createCuteEye(parent: node,
                         position: SCNVector3((i == 0) ? -0.1 : 0.1, 0.35, 0.35),
                         size: 0.06)
        }
        
        // 鼻（茶色い三角）
        let noseGeometry = SCNCone(topRadius: 0, bottomRadius: 0.06, height: 0.08)
        let noseMaterial = SCNMaterial()
        noseMaterial.diffuse.contents = UIColor(red: 0.5, green: 0.3, blue: 0.2, alpha: 1.0)
        noseGeometry.materials = [noseMaterial]
        
        let noseNode = SCNNode(geometry: noseGeometry)
        noseNode.position = SCNVector3(0, 0.25, 0.45)
        noseNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
        node.addChildNode(noseNode)
    }
    
    private func createCutePanda(node: SCNNode) {
        // ぱんだ：白と黒のかわいい体
        let whiteMaterial = SCNMaterial()
        whiteMaterial.diffuse.contents = UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        whiteMaterial.specular.contents = UIColor.white
        whiteMaterial.shininess = 0.3
        
        let blackMaterial = SCNMaterial()
        blackMaterial.diffuse.contents = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        blackMaterial.specular.contents = UIColor(white: 0.3, alpha: 1.0)
        blackMaterial.shininess = 0.2
        
        // 体（白）
        let bodyGeometry = SCNSphere(radius: 0.5)
        bodyGeometry.materials = [whiteMaterial]
        let bodyNode = SCNNode(geometry: bodyGeometry)
        bodyNode.position = SCNVector3(0, 0, 0)
        bodyNode.scale = SCNVector3(1.0, 1.1, 0.9)
        node.addChildNode(bodyNode)
        
        // 頭（白）
        let headGeometry = SCNSphere(radius: 0.4)
        headGeometry.materials = [whiteMaterial]
        let headNode = SCNNode(geometry: headGeometry)
        headNode.position = SCNVector3(0, 0.35, 0.1)
        node.addChildNode(headNode)
        
        // 耳（黒）
        for i in 0..<2 {
            let earGeometry = SCNSphere(radius: 0.15)
            earGeometry.materials = [blackMaterial]
            let earNode = SCNNode(geometry: earGeometry)
            
            let xOffset: Float = (i == 0) ? -0.25 : 0.25
            earNode.position = SCNVector3(xOffset, 0.55, -0.05)
            node.addChildNode(earNode)
        }
        
        // 目の周りの黒い模様
        for i in 0..<2 {
            let eyePatchGeometry = SCNSphere(radius: 0.12)
            eyePatchGeometry.materials = [blackMaterial]
            let eyePatchNode = SCNNode(geometry: eyePatchGeometry)
            
            let xOffset: Float = (i == 0) ? -0.12 : 0.12
            eyePatchNode.position = SCNVector3(xOffset, 0.35, 0.32)
            eyePatchNode.scale = SCNVector3(1.0, 1.2, 0.8)
            node.addChildNode(eyePatchNode)
            
            // 目
            createCuteEye(parent: node,
                         position: SCNVector3(xOffset, 0.35, 0.38),
                         size: 0.05)
        }
        
        // 鼻（黒）
        let noseGeometry = SCNSphere(radius: 0.06)
        noseGeometry.materials = [blackMaterial]
        let noseNode = SCNNode(geometry: noseGeometry)
        noseNode.position = SCNVector3(0, 0.25, 0.42)
        node.addChildNode(noseNode)
        
        // 手足（黒）
        for i in 0..<2 {
            let armGeometry = SCNSphere(radius: 0.2)
            armGeometry.materials = [blackMaterial]
            let armNode = SCNNode(geometry: armGeometry)
            
            let xOffset: Float = (i == 0) ? -0.35 : 0.35
            armNode.position = SCNVector3(xOffset, -0.1, 0.2)
            armNode.scale = SCNVector3(0.8, 1.2, 0.8)
            node.addChildNode(armNode)
        }
    }
    
    private func createCuteEye(parent: SCNNode, position: SCNVector3, size: CGFloat) {
        // 目の白い部分
        let eyeWhiteGeometry = SCNSphere(radius: size * 0.8)
        let eyeWhiteMaterial = SCNMaterial()
        eyeWhiteMaterial.diffuse.contents = UIColor.white
        eyeWhiteGeometry.materials = [eyeWhiteMaterial]
        
        let eyeWhiteNode = SCNNode(geometry: eyeWhiteGeometry)
        eyeWhiteNode.position = position
        parent.addChildNode(eyeWhiteNode)
        
        // 黒目
        let pupilGeometry = SCNSphere(radius: size * 0.5)
        let pupilMaterial = SCNMaterial()
        pupilMaterial.diffuse.contents = UIColor.black
        pupilGeometry.materials = [pupilMaterial]
        
        let pupilNode = SCNNode(geometry: pupilGeometry)
        pupilNode.position = SCNVector3(0, 0, size * 0.3)
        eyeWhiteNode.addChildNode(pupilNode)
        
        // キラキラ（ハイライト）
        let highlightGeometry = SCNSphere(radius: size * 0.2)
        let highlightMaterial = SCNMaterial()
        highlightMaterial.diffuse.contents = UIColor.white
        highlightMaterial.emission.contents = UIColor.white
        highlightGeometry.materials = [highlightMaterial]
        
        let highlightNode = SCNNode(geometry: highlightGeometry)
        highlightNode.position = SCNVector3(size * 0.2, size * 0.2, size * 0.4)
        eyeWhiteNode.addChildNode(highlightNode)
    }
    
    private func createStarNode() -> SCNNode {
        let starPath = UIBezierPath()
        let centerX: CGFloat = 0
        let centerY: CGFloat = 0
        let radius: CGFloat = 0.3
        
        for i in 0..<10 {
            let angle = CGFloat(i) * CGFloat.pi / 5
            let r = (i % 2 == 0) ? radius : radius * 0.5
            let x = centerX + r * cos(angle - CGFloat.pi / 2)
            let y = centerY + r * sin(angle - CGFloat.pi / 2)
            
            if i == 0 {
                starPath.move(to: CGPoint(x: x, y: y))
            } else {
                starPath.addLine(to: CGPoint(x: x, y: y))
            }
        }
        starPath.close()
        
        let starShape = SCNShape(path: starPath, extrusionDepth: 0.05)
        let starMaterial = SCNMaterial()
        starMaterial.diffuse.contents = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 1.0)
        starMaterial.emission.contents = UIColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.3)
        starShape.materials = [starMaterial]
        
        return SCNNode(geometry: starShape)
    }
    
    private func getAnimalColor(for animal: AnimalType) -> UIColor {
        switch animal {
        case .rabbit:
            return UIColor(red: 1.0, green: 0.98, blue: 0.98, alpha: 1.0)
        case .bear:
            return UIColor(red: 0.65, green: 0.45, blue: 0.3, alpha: 1.0)
        case .elephant:
            return UIColor(red: 0.7, green: 0.7, blue: 0.75, alpha: 1.0)
        case .giraffe:
            return UIColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
        case .lion:
            return UIColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 1.0)
        case .panda:
            return UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        }
    }
    
    private func getAnimalAccentColor(for animal: AnimalType) -> UIColor {
        switch animal {
        case .rabbit:
            return UIColor(red: 1.0, green: 0.8, blue: 0.85, alpha: 1.0)
        case .bear:
            return UIColor(red: 0.75, green: 0.55, blue: 0.4, alpha: 1.0)
        case .elephant:
            return UIColor(red: 0.75, green: 0.75, blue: 0.8, alpha: 1.0)
        case .giraffe:
            return UIColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .lion:
            return UIColor(red: 0.7, green: 0.5, blue: 0.3, alpha: 1.0)
        case .panda:
            return UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        }
    }
    
    // アニメーション関連のメソッドは既存のものを使用
    func rotateBoard(duration: TimeInterval = 3.0) {
        guard let boardNode = boardNode else { return }
        
        let rotation = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: duration)
        rotation.timingMode = .easeInEaseOut
        boardNode.runAction(rotation)
    }
    
    func animateAnimals() {
        for (_, node) in animalNodes {
            let jump = SCNAction.moveBy(x: 0, y: 0.3, z: 0, duration: 0.3)
            jump.timingMode = .easeOut
            let fall = SCNAction.moveBy(x: 0, y: -0.3, z: 0, duration: 0.3)
            fall.timingMode = .easeIn
            
            let sequence = SCNAction.sequence([jump, fall])
            node.runAction(sequence)
        }
    }
    
    func highlightAnimal(_ animal: AnimalType) {
        guard let animalNode = animalNodes[animal] else { return }
        
        let scaleUp = SCNAction.scale(to: 1.2, duration: 0.2)
        let wait = SCNAction.wait(duration: 0.5)
        let scaleDown = SCNAction.scale(to: 1.0, duration: 0.2)
        
        let sequence = SCNAction.sequence([scaleUp, wait, scaleDown])
        animalNode.runAction(sequence)
        
        // グロー効果を追加
        if let firstGeometry = animalNode.childNodes.first?.geometry {
            let originalMaterials = firstGeometry.materials
            let glowMaterial = SCNMaterial()
            glowMaterial.diffuse.contents = UIColor.yellow
            glowMaterial.emission.contents = UIColor.yellow
            
            firstGeometry.materials = [glowMaterial]
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                firstGeometry.materials = originalMaterials
            }
        }
    }
    
    func removeHighlight(_ animal: AnimalType) {
        guard let animalNode = animalNodes[animal] else { return }
        animalNode.removeAllActions()
        animalNode.scale = SCNVector3(1, 1, 1)
    }
    
    private func addClouds() {
        // 雲を何個か追加
        for i in 0..<5 {
            let cloudNode = createCloudNode()
            let x = Float.random(in: -10...10)
            let y = Float.random(in: 8...12)
            let z = Float.random(in: -15...(-8))
            cloudNode.position = SCNVector3(x, y, z)
            cloudNode.scale = SCNVector3(
                Float.random(in: 0.8...1.5),
                Float.random(in: 0.8...1.2),
                Float.random(in: 0.8...1.3)
            )
            
            // ゆっくり動くアニメーション
            let moveDistance = Float.random(in: 15...25)
            let moveDuration = TimeInterval.random(in: 20...40)
            let moveRight = SCNAction.moveBy(x: CGFloat(moveDistance), y: 0, z: 0, duration: moveDuration)
            let moveLeft = SCNAction.moveBy(x: CGFloat(-moveDistance), y: 0, z: 0, duration: moveDuration)
            let sequence = SCNAction.sequence([moveRight, moveLeft])
            let forever = SCNAction.repeatForever(sequence)
            cloudNode.runAction(forever)
            
            scene.rootNode.addChildNode(cloudNode)
        }
        
        // 装飾的な星を追加
        for _ in 0..<8 {
            let starNode = createFloatingStarNode()
            let x = Float.random(in: -8...8)
            let y = Float.random(in: 3...10)
            let z = Float.random(in: -10...(-5))
            starNode.position = SCNVector3(x, y, z)
            
            // キラキラアニメーション
            let rotateAction = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: TimeInterval.random(in: 3...6))
            let scaleUp = SCNAction.scale(to: 1.2, duration: 1.5)
            let scaleDown = SCNAction.scale(to: 0.8, duration: 1.5)
            let scaleSequence = SCNAction.sequence([scaleUp, scaleDown])
            let group = SCNAction.group([
                SCNAction.repeatForever(rotateAction),
                SCNAction.repeatForever(scaleSequence)
            ])
            starNode.runAction(group)
            
            scene.rootNode.addChildNode(starNode)
        }
    }
    
    private func createCloudNode() -> SCNNode {
        let cloudNode = SCNNode()
        
        // 雲を複数の球体で構成
        let cloudParts = Int.random(in: 4...6)
        for i in 0..<cloudParts {
            let sphereRadius = CGFloat.random(in: 0.8...1.5)
            let sphereGeometry = SCNSphere(radius: sphereRadius)
            
            let cloudMaterial = SCNMaterial()
            cloudMaterial.diffuse.contents = UIColor(white: 1.0, alpha: 0.9)
            cloudMaterial.transparency = 0.7
            cloudMaterial.isDoubleSided = true
            sphereGeometry.materials = [cloudMaterial]
            
            let sphereNode = SCNNode(geometry: sphereGeometry)
            let x = Float(i) * 0.8 - Float(cloudParts) * 0.4
            let y = Float.random(in: -0.3...0.3)
            sphereNode.position = SCNVector3(x, y, 0)
            sphereNode.scale = SCNVector3(1.2, 0.8, 1.0)
            
            cloudNode.addChildNode(sphereNode)
        }
        
        return cloudNode
    }
    
    private func createFloatingStarNode() -> SCNNode {
        let starGeometry = SCNSphere(radius: 0.1)
        let starMaterial = SCNMaterial()
        starMaterial.diffuse.contents = UIColor(red: 1.0, green: 1.0, blue: 0.3, alpha: 1.0)
        starMaterial.emission.contents = UIColor(red: 1.0, green: 1.0, blue: 0.3, alpha: 0.5)
        starGeometry.materials = [starMaterial]
        
        let starNode = SCNNode(geometry: starGeometry)
        
        // 星の形の装飾を追加
        for i in 0..<4 {
            let rayGeometry = SCNCapsule(capRadius: 0.02, height: 0.3)
            rayGeometry.materials = [starMaterial]
            let rayNode = SCNNode(geometry: rayGeometry)
            rayNode.eulerAngles = SCNVector3(0, 0, Float(i) * Float.pi / 2)
            starNode.addChildNode(rayNode)
        }
        
        return starNode
    }
}