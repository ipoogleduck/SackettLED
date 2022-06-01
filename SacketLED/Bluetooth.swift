//
//  Bluetooth.swift
//  SacketLED
//
//  Created by Oliver Elliott on 10/19/21.
//

import UIKit
import CoreBluetooth

extension ViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
            statusLabel.text = "Bluetooth Status: System Disabled"
            sendButton.isEnabled = false
          case .poweredOn:
            print("central.state is .poweredOn")
            statusLabel.text = "Bluetooth searching..."
            centralManager.scanForPeripherals(withServices: nil)
        @unknown default:
            print("Fatal error: unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "Ble-Nano" {
            print(peripheral)
            NanoPeripheral = peripheral
            NanoPeripheral.delegate = self
            centralManager.stopScan()
            centralManager.connect(NanoPeripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected")
        statusLabel.text = "Bluetooth connected"
        sendButton.isEnabled = true
        NanoPeripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Bluetooth Disconnected")
        sendButton.isEnabled = false
        statusLabel.text = "Bluetooth searching..."
        centralManager.scanForPeripherals(withServices: nil)
    }
    
}

extension ViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else { return }
        
        let service = services[1]
        print(service)
        peripheral.discoverCharacteristics(nil, for: service)
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
      guard let characteristics = service.characteristics else { return }

      for characteristic in characteristics {
        print(characteristic)
        FFE1Characteristic = characteristic
        print("Characteristic discovered")
        peripheral.setNotifyValue(true, for: characteristic)
      }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Value sent from BLE:")
        let str = String(decoding: characteristic.value!, as: UTF8.self)
        print(str)
//        if str == "Z" {
//            statusLabel.text = "Bluetooth connected"
//        } else if str == "Y" {
//            statusLabel.text = "HC12 Status: Igniting"
//        }
    }
    
}
