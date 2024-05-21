import Foundation
import SpriteKit
import CoreBluetooth

class MenuScene: SKScene {
    
    var bleManager: BLEManager!
    
    var scanButton: SKLabelNode!
    var startGameButton: SKLabelNode!
    
    override func didMove(to view: SKView) {
        // Configurar BLEManager
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            bleManager = appDelegate.bleManager
        }
        
        // Crear el botón
        scanButton = SKLabelNode(text: "Start Scanning")
        scanButton.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        scanButton.fontSize = 24
        scanButton.fontColor = SKColor.white
        scanButton.name = "scanButton"
        self.addChild(scanButton)
        
        
        // Crear el botón para iniciar el juego
        startGameButton = SKLabelNode(text: "Start Game")
        startGameButton.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 50)
        startGameButton.fontSize = 24
        startGameButton.fontColor = SKColor.white
        startGameButton.name = "startGameButton"
        self.addChild(startGameButton)
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            
            if touchedNode.name == "scanButton" {
                bleManager.startScanning()
            } else if touchedNode.name == "startGameButton" {
                loadGameScene()
            }
        }
    }
    
    
    func loadGameScene() {
        if let view = self.view {
            let scene = SpaceInvadersScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            let transition = SKTransition.flipHorizontal(withDuration: 0.5)
            view.presentScene(scene, transition: transition)
        }
    }
    
    
}
