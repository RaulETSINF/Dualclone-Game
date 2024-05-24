import SpriteKit
import CoreMotion

class SpaceInvadersScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var motionManager: CMMotionManager!
    var bleManager: BLEManager!
    var lastShootTime: TimeInterval = 0
    var lives: Int = 5
    var livesLabel: SKLabelNode!
    var backgroundMusic: SKAudioNode!
    var exitButton: SKLabelNode!
    
    let shootSound = SKAction.playSoundFileNamed("shoot.wav", waitForCompletion: false)
    let invaderKilled = SKAction.playSoundFileNamed("invaderkilled.wav", waitForCompletion: false)
    let proyectile = SKAction.playSoundFileNamed("proyectile", waitForCompletion: false)
    
    
    override func didMove(to view: SKView) {
        
        self.backgroundColor = SKColor(red: 209/255, green: 60/255, blue: 94/255, alpha: 1.0)
        
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            backgroundMusic.autoplayLooped = true
            addChild(backgroundMusic)
        }
        
        // Configurar la nave del jugador
        let playerSize = CGSize(width: 50, height: 50)
        let playerPath = UIBezierPath(rect: CGRect(origin: CGPoint.zero, size: playerSize))
        let playerShape = SKShapeNode(path: playerPath.cgPath)
        playerShape.strokeColor = .white
        playerShape.lineWidth = 5
        playerShape.fillColor = .clear
        
        player = SKSpriteNode(color: .clear, size: playerSize)
        playerShape.position = CGPoint(x: -playerSize.width / 2, y: -playerSize.height / 2)
        player.addChild(playerShape)
        player.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 100)
        self.addChild(player)
        
        // Configurar física
        self.physicsWorld.contactDelegate = self
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = false
        player.physicsBody?.categoryBitMask = 1
        player.physicsBody?.contactTestBitMask = 2
        
        // Configuración del gestor de movimiento
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
        
        // Configurar actualización de escena
        let _: TimeInterval = 1.0 / 60.0
        let updateQueue = OperationQueue()
        updateQueue.name = "Motion Update Queue"
        motionManager.startDeviceMotionUpdates(to: updateQueue) { (motionData, error) in
            guard let data = motionData else { return }
            self.updatePlayerPosition(data: data)
        }
        
        // Configurar BLEManager
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            bleManager = appDelegate.bleManager
            bleManager.startScanning()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(receivedProjectileData(_:)), name: .didReceiveProjectileData, object: nil)
        
        // Configurar la etiqueta de vidas
        livesLabel = SKLabelNode(text: "Vidas: \(lives)")
        livesLabel.fontName = "Arial-BoldMT"
        livesLabel.fontSize = 24
        livesLabel.fontColor = .white
        livesLabel.position = CGPoint(x: self.frame.minX + 80, y: self.frame.minY + 20)
        self.addChild(livesLabel)
        
        // Configurar el botón de salida
        exitButton = SKLabelNode(text: "Exit")
        exitButton.fontName = "Arial-BoldMT"
        exitButton.fontSize = 24
        exitButton.fontColor = .white
        exitButton.position = CGPoint(x: self.frame.maxX - 80, y: self.frame.minY + 20)
        exitButton.name = "exitButton"
        self.addChild(exitButton)
    }
    
    func updatePlayerPosition(data: CMDeviceMotion) {
        DispatchQueue.main.async {
            let xMovement = CGFloat(data.attitude.roll) * 500
            self.player.position.x += xMovement * CGFloat(self.motionManager.accelerometerUpdateInterval)
            
            // Asegurar que el jugador no se salga de los bordes de la pantalla
            self.player.position.x = max(min(self.player.position.x, self.size.width - self.player.size.width / 2), self.player.size.width / 2)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            
            if touchedNode.name == "exitButton" {
                returnToMenu()
            }
            
            let currentTime = CACurrentMediaTime()
            if currentTime - lastShootTime > 0.5 {
                lastShootTime = currentTime
                shootProjectile()
            }
        }
    }
    func shootProjectile() {
        let projectileSize = CGSize(width: 15, height: 15)
        let projectile = SKSpriteNode(color: SKColor.white, size: projectileSize)
        
        // Posicionar el proyectil centrado pero un poco más adelante del jugador
        projectile.position = CGPoint(x: player.position.x, y: player.position.y + player.size.height / 2 + projectile.size.height)
        
        projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.affectedByGravity = false
        projectile.physicsBody?.categoryBitMask = 2 // Categoría para proyectiles del jugador
        projectile.physicsBody?.contactTestBitMask = 2 // Colisiona con proyectiles enemigos
        projectile.physicsBody?.collisionBitMask = 0
        self.addChild(projectile)
        
        self.run(shootSound)
        
        let moveAction = SKAction.moveBy(x: 0, y: self.frame.height, duration: 1.0)
        let removeAction = SKAction.run {
            // Invertir la coordenada x para el dispositivo receptor
            let invertedX = self.frame.width - projectile.position.x
            if let projectileData = try? JSONEncoder().encode(["x": invertedX, "y": projectile.position.y]) {
                self.bleManager.sendProjectileData(projectileData)
            }
            projectile.removeFromParent()
        }
        projectile.run(SKAction.sequence([moveAction, removeAction]))
    }
    
    @objc func receivedProjectileData(_ notification: Notification) {
        if let data = notification.object as? Data {
            if let projectileInfo = try? JSONDecoder().decode([String: CGFloat].self, from: data) {
                let projectileSize = CGSize(width: 15, height: 15)
                let projectile = SKSpriteNode(color: SKColor(red: 78/255, green: 169/255, blue: 87/255, alpha: 1.0), size: projectileSize)
                projectile.position = CGPoint(x: projectileInfo["x"]!, y: self.frame.maxY)
                projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
                projectile.physicsBody?.isDynamic = true
                projectile.physicsBody?.affectedByGravity = false
                projectile.physicsBody?.categoryBitMask = 2 // Categoría para proyectiles del enemigo
                projectile.physicsBody?.contactTestBitMask = 1 | 2 // Colisiona con el jugador y con proyectiles del jugador
                projectile.physicsBody?.collisionBitMask = 0
                self.addChild(projectile)
                
                let moveAction = SKAction.moveBy(x: 0, y: -self.frame.height, duration: 1.0)
                let removeAction = SKAction.removeFromParent()
                projectile.run(SKAction.sequence([moveAction, removeAction]))
            }
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody
        var secondBody: SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        } else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        
        if firstBody.categoryBitMask == 1 && secondBody.categoryBitMask == 2 {
            if firstBody.node is SKSpriteNode {
                handlePlayerHit()
                createExplosion(at: contact.contactPoint)
            }
            secondBody.node?.removeFromParent()
        } else if firstBody.categoryBitMask == 2 && secondBody.categoryBitMask == 2 {
            // Proyectil del jugador colisiona con proyectil enemigo
            createExplosion(at: contact.contactPoint)
            self.run(proyectile)
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
        }
    }
    
    func createExplosion(at position: CGPoint) {
        if let explosion = SKEmitterNode(fileNamed: "Explosion.sks") {
            explosion.position = position
            self.addChild(explosion)
            
            let fadeOutAction = SKAction.fadeOut(withDuration: 0.3) // Desvanece el emisor de partículas
            let removeAction = SKAction.removeFromParent()
            let sequenceAction = SKAction.sequence([fadeOutAction, removeAction])
            explosion.run(sequenceAction)
        }
    }
    
    func handlePlayerHit() {
        lives -= 1
        livesLabel.text = "Vidas: \(lives)"
        
        // Reproducir sonido de invaderkilled
        self.run(invaderKilled)
        
        if lives <= 0 {
            gameOver()
        }
    }
    
    func gameOver() {
        // Crear el nodo de texto "Game Over"
        let gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontName = "Arial-BoldMT"
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        gameOverLabel.zPosition = 100 // Asegurarse de que el texto esté al frente
        self.addChild(gameOverLabel)
        
        // Esperar 3 segundos y luego volver al menú
        let waitAction = SKAction.wait(forDuration: 3.0)
        let transitionAction = SKAction.run {
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            if let scene = MenuScene(fileNamed: "MenuScene") {
                scene.scaleMode = .fill
                self.view?.presentScene(scene, transition: transition)
            }
        }
        let sequence = SKAction.sequence([waitAction, transitionAction])
        self.run(sequence)
    }

    // Dentro de tu clase SpaceInvadersScene
    func returnToMenu() {
        if let view = self.view, let viewController = view.window?.rootViewController {
            let alert = UIAlertController(title: "Confirm Exit", message: "Are you sure you want to return to the menu?", preferredStyle: .alert)
            
            let confirmAction = UIAlertAction(title: "Yes", style: .default) { _ in
                let transition = SKTransition.flipHorizontal(withDuration: 0.5)
                if let scene = MenuScene(fileNamed: "MenuScene") {
                    scene.scaleMode = .fill
                    view.presentScene(scene, transition: transition)
                }
            }
            
            let cancelAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            
            alert.addAction(confirmAction)
            alert.addAction(cancelAction)
            
            viewController.present(alert, animated: true, completion: nil)
        }
    }

    
    
}
