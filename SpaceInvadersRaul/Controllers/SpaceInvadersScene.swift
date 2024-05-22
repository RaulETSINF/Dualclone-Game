//
//  GameScene.swift
//  SpaceInvadersRaul
//
//  Created by Raul Piqueras Melero on 21/5/24.
//
import SpriteKit
import CoreMotion

class SpaceInvadersScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var motionManager: CMMotionManager!
    var bleManager: BLEManager!
    var lastShootTime: TimeInterval = 0
    var lives: Int = 100

    override func didMove(to view: SKView) {
        // Configuración inicial de la escena
        self.backgroundColor = SKColor(red: 209/255, green: 60/255, blue: 94/255, alpha: 1.0)
        
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
        let currentTime = CACurrentMediaTime()
        if currentTime - lastShootTime > 1.0 {
            lastShootTime = currentTime
            shootProjectile()
        }
    }
    
    func shootProjectile() {
        let projectileSize = CGSize(width: 15, height: 15)
        let projectile = SKSpriteNode(color: SKColor(red: 78/255, green: 169/255, blue: 87/255, alpha: 1.0), size: projectileSize)
        
        // Posicionar el proyectil en el centro del jugador
        projectile.position = CGPoint(x: player.position.x, y: player.position.y + player.size.height / 2 + projectile.size.height / 2)
        
        projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
        projectile.physicsBody?.isDynamic = true
        projectile.physicsBody?.affectedByGravity = false
        projectile.physicsBody?.categoryBitMask = 4 // Categoría para proyectiles del jugador
        projectile.physicsBody?.contactTestBitMask = 2 // Colisiona con proyectiles enemigos
        projectile.physicsBody?.collisionBitMask = 0
        self.addChild(projectile)
        
        let moveAction = SKAction.moveBy(x: 0, y: self.frame.height, duration: 1.0)
        let removeAction = SKAction.run {
            if let projectileData = try? JSONEncoder().encode(["x": projectile.position.x, "y": projectile.position.y]) {
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
                let projectile = SKSpriteNode(color: SKColor.white, size: projectileSize)
                projectile.position = CGPoint(x: projectileInfo["x"]!, y: self.frame.maxY)
                projectile.physicsBody = SKPhysicsBody(rectangleOf: projectile.size)
                projectile.physicsBody?.isDynamic = true
                projectile.physicsBody?.affectedByGravity = false
                projectile.physicsBody?.categoryBitMask = 2 // Categoría para proyectiles del enemigo
                projectile.physicsBody?.contactTestBitMask = 1 | 4 // Colisiona con el jugador y con proyectiles del jugador
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
        } else if firstBody.categoryBitMask == 4 && secondBody.categoryBitMask == 2 {
            // Proyectil del jugador colisiona con proyectil enemigo
            print("Explosion creada")
            createExplosion(at: contact.contactPoint)
            firstBody.node?.removeFromParent()
            secondBody.node?.removeFromParent()
        }
    }

    func createExplosion(at position: CGPoint) {
        let explosion = SKEmitterNode(fileNamed: "Explosion.sks")!
        explosion.position = position
        self.addChild(explosion)
        
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.3) // Desvanece el emisor de partículas
        let removeAction = SKAction.removeFromParent()
        let sequenceAction = SKAction.sequence([fadeOutAction, removeAction])
        explosion.run(sequenceAction)
    }

    func handlePlayerHit() {
        lives -= 1
        if lives <= 0 {
            gameOver()
        }
    }

    func gameOver() {
        let transition = SKTransition.flipHorizontal(withDuration: 0.5)
        if let scene = MenuScene(fileNamed: "MenuScene") {
            self.view?.presentScene(scene, transition: transition)
        }
    }
}
