import Foundation
import SpriteKit
import CoreBluetooth

class MenuScene: SKScene, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    
    let myServiceUUID = CBUUID(string: "1201FB7E-AA4B-4D45-9BC7-D527E1F7E784")
    let myCharacteristicUUID = CBUUID(string: "29E79AF5-2457-40FF-92FE-FE5F299AAED3")

    override func didMove(to view: SKView) {
        // Configuración de CBCentralManager
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth status is POWERED ON")
            centralManager.scanForPeripherals(withServices: [myServiceUUID], options: nil)
        default:
            print("Bluetooth state: \(central.state)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Guardar el periférico descubierto y detener el escaneo
        discoveredPeripheral = peripheral
        centralManager.stopScan()

        // Configurar el delegado y conectar al periférico
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.identifier)")
        // Descubrir servicios del periférico
        peripheral.discoverServices([myServiceUUID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == myServiceUUID {
                    // Descubrir características del servicio
                    peripheral.discoverCharacteristics([myCharacteristicUUID], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == myCharacteristicUUID {
                    // Leer valor o suscribirse a la característica
                    peripheral.readValue(for: characteristic)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            // Procesar datos de la característica
            print("Received data: \(data)")
        }
    }
}
