//
//  Bluetooth.swift
//  SacketLED
//
//  Created by Oliver Elliott on 10/19/21.
//

import UIKit
import CoreBluetooth

extension TetrisVC: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        canScanForDisplay = false
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
            bluetoothStatus(on: false)
            showMoveCloserView(true)
            self.updateInLineView(show: false)
          case .poweredOn:
            print("central.state is .poweredOn")
            bluetoothStatus(on: true)
            canScanForDisplay = true
            if placeInLine == 0 {
                tryConnectDisplay()
            } else if placeInLine != nil {
                self.runConnectionTest()
            }
        @unknown default:
            print("Fatal error: unknown")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "Ble-Nano" {
            print("Found Nano")
            print(peripheral)
            if connectionTester == .testing {
                print("Found display and moving to kick validation")
                connectionTester = .waiting
                inLineTextView.isHidden = true
                centralManager.stopScan()
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if self.connectionTester == .waiting && !self.isConnectedToDisplay {
                        print("Validating now...")
                        self.connectionTester = .validating
                        self.scanForDisplay()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            if self.connectionTester == .validating { //Faliure to connect
                                self.connectionTester = .notTesting
                                self.centralManager.stopScan()
                                self.inLineTextView.isHidden = false
                                print("Unsuccessfull validation")
                            }
                        }
                    }
                }
            } else if connectionTester == .validating {
                print("Success validating kick")
                connectionTester = .notTesting
                centralManager.stopScan()
                kickFirstFromLine()
            } else {
                nanoPeripheral = peripheral
                nanoPeripheral!.delegate = self
                centralManager.stopScan()
                centralManager.connect(nanoPeripheral!)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected")
        nanoPeripheral?.discoverServices(nil)
        showMoveCloserView(false)
        isConnectedToDisplay = true
        self.updateInLineView(show: false)
        if !(game?.isRunning ?? false) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.gameOverView.alpha = 0
                self.startGame()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.game?.requestFullDisplayRefresh()
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Bluetooth Disconnected")
        isConnectedToDisplay = false
        showMoveCloserView(true)
        if placeInLine == 0 {
            tryConnectDisplay()
        }
    }
    
    func scanForDisplay() {
        showMoveCloserView(true)
        centralManager.scanForPeripherals(withServices: nil)
    }
    
    func showMoveCloserView(_ show: Bool) {
        UIView.animate(withDuration: 0.4) {
            if show {
                self.moveCloserView.alpha = 1
            } else {
                self.moveCloserView.alpha = 0
            }
        }
    }
    
    func bluetoothStatus(on: Bool) {
        if on {
            moveCloserLabel.text = "Please Move Closer to Display"
        } else {
            moveCloserLabel.text = "Please Turn on Bluetooth"
        }
    }
    
    func disconnectNano() {
        centralManager.stopScan()
        if let nanoPeripheral = nanoPeripheral {
            centralManager.cancelPeripheralConnection(nanoPeripheral)
        }
    }
    
}

extension TetrisVC: CBPeripheralDelegate {
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
