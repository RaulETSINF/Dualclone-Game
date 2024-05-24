# Proyecto Space Invaders

## Nombre del alumno
Raul Piqueras Melero

## Descripción general del proyecto
El proyecto consiste en la creación de un clon del juego "Dual" con temática de "Space Invaders". El juego se juega en modo multijugador local utilizando Bluetooth para la comunicación entre dispositivos. Los jugadores controlan naves espaciales que pueden moverse y disparar proyectiles. Los disparos que salen de la pantalla de un dispositivo aparecen en la pantalla del otro dispositivo. El objetivo es destruir la nave del oponente mientras se evita ser golpeado por sus disparos.

## Funcionalidades y clases de la aplicación

### MenuScene

`MenuScene` es la escena inicial del juego, que presenta un menú donde los jugadores pueden iniciar el juego. Aquí se configuran las siguientes funcionalidades:

1. **Configuración del fondo:**
   - Se establece un color de fondo consistente con el tema del juego.

2. **Configuración de BLEManager:**
   - Se inicializa el `BLEManager` para gestionar la comunicación Bluetooth.

3. **Título del juego:**
   - Se crea y anima el título "Space Invaders" que se muestra en el centro de la pantalla.

4. **Botón de inicio del juego:**
   - Se crea y anima un botón de "Start Game" que permite a los jugadores comenzar la partida.

5. **Animaciones:**
   - `animateTitle()`: Anima el título del juego con un efecto de escalado.
   - `animateStartGameButton()`: Anima el botón de inicio con un efecto de pulsación.

6. **Detección de toques:**
   - `touchesBegan`: Detecta cuando el usuario toca el botón de "Start Game" y carga la escena del juego (`SpaceInvadersScene`).

#### Código de MenuScene
```swift
import Foundation
import SpriteKit
import CoreBluetooth

class MenuScene: SKScene {
    
    var bleManager: BLEManager!
    
    var scanButton: SKLabelNode!
    var startGameButton: SKLabelNode!
    var titleLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        // Configurar el fondo
        self.backgroundColor = SKColor(red: 209/255, green: 60/255, blue: 94/255, alpha: 1.0)
        
        // Configurar BLEManager
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            bleManager = appDelegate.bleManager
        }
        
        // Crear el título del juego
        titleLabel = SKLabelNode(text: "Space Invaders")
        titleLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY + 100)
        titleLabel.fontSize = 40
        titleLabel.fontColor = SKColor.white
        titleLabel.name = "titleLabel"
        self.addChild(titleLabel)
        
        // Crear el botón para iniciar el juego
        startGameButton = SKLabelNode(text: "Start Game")
        startGameButton.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 50)
        startGameButton.fontSize = 30
        startGameButton.fontColor = SKColor.white
        startGameButton.name = "startGameButton"
        self.addChild(startGameButton)
        
        // Animar el título
        animateTitle()
        
        // Animar el botón de iniciar juego
        animateStartGameButton()
    }
    
    func animateTitle() {
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatForever = SKAction.repeatForever(sequence)
        titleLabel.run(repeatForever)
    }
    
    func animateStartGameButton() {
        let pulseUp = SKAction.scale(to: 1.1, duration: 0.6)
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.6)
        let pulseSequence = SKAction.sequence([pulseUp, pulseDown])
        let repeatPulse = SKAction.repeatForever(pulseSequence)
        startGameButton.run(repeatPulse)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchedNode = self.atPoint(location)
            
            if touchedNode.name == "startGameButton" {
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
