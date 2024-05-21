//
//  GameScene.swift
//  SpaceInvadersRaul
//
//  Created by Raul Piqueras Melero on 21/5/24.
//
import SpriteKit
import CoreMotion

class SpaceInvadersScene: SKScene {
    
    var player: SKSpriteNode!
    var motionManager: CMMotionManager!
    var bleManager: BLEManager!

    override func didMove(to view: SKView) {
        // Configuración inicial de la escena
        self.backgroundColor = SKColor.black
        
        // Configurar la nave del jugador
        player = SKSpriteNode(color: SKColor.green, size: CGSize(width: 50, height: 50))
        player.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 100)
        self.addChild(player)
        
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
            self.player.position.x = max(min(self.player.position.x, self.size.width - self.player.size.width / 2), self.player.size.width / 2)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            if location.y > self.player.position.y {
                shootProjectile()
            }
        }
    }
    
    func shootProjectile() {
        let projectile = SKSpriteNode(color: SKColor.red, size: CGSize(width: 10, height: 20))
        projectile.position = player.position
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
                let projectile = SKSpriteNode(color: SKColor.blue, size: CGSize(width: 10, height: 20))
                projectile.position = CGPoint(x: projectileInfo["x"]!, y: self.frame.maxY)
                self.addChild(projectile)
                
                let moveAction = SKAction.moveBy(x: 0, y: -self.frame.height, duration: 1.0)
                let removeAction = SKAction.removeFromParent()
                projectile.run(SKAction.sequence([moveAction, removeAction]))
            }
        }
    }
}
