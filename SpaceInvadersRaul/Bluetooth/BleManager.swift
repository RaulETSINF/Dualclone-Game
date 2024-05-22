//
//  BleManager.swift
//  SpaceInvadersRaul
//
//  Created by Raul Piqueras Melero on 21/5/24.
//

import Foundation
import CoreBluetooth

class BLEManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, CBPeripheralManagerDelegate {
    var centralManager: CBCentralManager!
    var peripheralManager: CBPeripheralManager!
    var discoveredPeripheral: CBPeripheral?
    var myServiceUUID: CBUUID
    var myCharacteristicUUID: CBUUID
    var myCharacteristic: CBMutableCharacteristic!

    override init() {
        self.myServiceUUID = CBUUID(string: "1201FB7E-AA4B-4D45-9BC7-D527E1F7E784")
        self.myCharacteristicUUID = CBUUID(string: "29E79AF5-2457-40FF-92FE-FE5F299AAED3")
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [myServiceUUID], options: nil)
            print("Started scanning for peripherals")
        } else {
            print("Central Manager is not powered on")
        }
    }

    // MARK: - CBCentralManagerDelegate Methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Central Manager powered on")
        case .poweredOff:
            print("Central Manager powered off")
        case .resetting:
            print("Central Manager resetting")
        case .unauthorized:
            print("Central Manager unauthorized")
        case .unsupported:
            print("Central Manager unsupported")
        case .unknown:
            print("Central Manager unknown")
        @unknown default:
            print("Central Manager unknown default")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        discoveredPeripheral = peripheral
        print("Discovered \(peripheral.identifier)")
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.identifier)")
        peripheral.discoverServices([myServiceUUID])
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == myServiceUUID {
                    peripheral.discoverCharacteristics([myCharacteristicUUID], for: service)
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == myCharacteristicUUID {
                    print("Caracteristica descubierta")
                    peripheral.readValue(for: characteristic)
                    peripheral.setNotifyValue(true, for: characteristic)
                    print(peripheral.readValue(for: characteristic))
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            print("Received data: \(data)")
            NotificationCenter.default.post(name: .didReceiveProjectileData, object: data)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == myCharacteristicUUID {
            print("Received data:")
        }
    }

    // MARK: - CBPeripheralManagerDelegate Methods
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            print("Peripheral Manager powered on")
            startAdvertising()
        default:
            print("Peripheral Manager state: \(peripheral.state.rawValue)")
        }
    }

    func startAdvertising() {
        let advertisementData: [String: Any] = [
            CBAdvertisementDataLocalNameKey: "DualClone",
            CBAdvertisementDataServiceUUIDsKey: [myServiceUUID]
        ]
        peripheralManager.startAdvertising(advertisementData)
        
        myCharacteristic = CBMutableCharacteristic(
            type: myCharacteristicUUID,
            properties: [.write, .notify, .read],
            value: nil,
            permissions: [.writeable, .readable]
        )
        
        let service = CBMutableService(type: myServiceUUID, primary: true)
        service.characteristics = [myCharacteristic]
        
        peripheralManager.add(service)
    }

    func sendProjectileData(_ data: Data) {
        if myCharacteristic != nil {
            print(peripheralManager.updateValue(data, for: myCharacteristic, onSubscribedCentrals: nil))
            print("Proyectil Enviado Bluetooth")
        }
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == myCharacteristicUUID {
                if let value = request.value {
                    NotificationCenter.default.post(name: .didReceiveProjectileData, object: value)
                    peripheralManager.respond(to: request, withResult: .success)
                    print("He recibido proyectil")
                }
            }
        }
    }
}

extension Notification.Name {
    static let didReceiveProjectileData = Notification.Name("didReceiveProjectileData")
}


