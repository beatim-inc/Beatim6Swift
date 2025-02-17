//
//  BLEManager.swift
//  Beatim6Swift
//
//  Created by 野村健介 on 2025/02/17.
//


import CoreBluetooth
import SwiftUI

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    var centralManager: CBCentralManager!
    @Published var isSwitchedOn = false
    @Published var peripherals = [CBPeripheral]()
    
    let serviceUUID = CBUUID(string: "56bb2dcf-04b3-4923-bbbd-ea12964d4d3b")
    let lStepcharacteristicUUID = CBUUID(string: "f48c7a6c-540c-4214-9e4c-f7041cfe6844")
    let rStepcharacteristicUUID = CBUUID(string: "718cf980-b71e-4e35-b3a6-b2cbe3cb6c97")
    
    var onStepDetectionNotified:  (() -> Void)?

   override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isSwitchedOn = true
        } else {
            isSwitchedOn = false
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripherals.contains(peripheral) {
            peripherals.append(peripheral)
        }
    }

    //
    //NOTE:withServiceをnilにすると、全デバイスを検索
    func startScanning() {
        print("Scanning...")
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        print(peripherals)
    }

    func connectPeripheral(peripheral: CBPeripheral) {
        print("Connect peripheral")
        print(peripheral)
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Enter didConnect")
        // 意外とこれがないとサービスの登録がうまくいかなかった
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("enter didDiscoverService")
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([lStepcharacteristicUUID,rStepcharacteristicUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("enter didDiscoevrCharacteristics")
        print(service)
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("enter didUpdateValue")
        if let data = characteristic.value {
            // ここでデータを処理
            //TODO:ステップ検知が通知されたら...
            if(false){
              onStepDetectionNotified?()
            }
           print(data)
        }
        print(characteristic)
    }
}
