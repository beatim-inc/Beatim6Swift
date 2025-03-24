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
    var parameters: StepDetectionParameters

    @Published var isSwitchedOn = false
    @Published var scanEnabled = false
    @Published var peripherals = [CBPeripheral]() // 🎯 接続可能なデバイスのリスト
    @Published var connectedPeripherals = [CBPeripheral]() // 🎯 接続中のデバイスのリスト
    
    let serviceUUID = CBUUID(string: "56bb2dcf-04b3-4923-bbbd-ea12964d4d3b")
    let stepCharacteristicUUID = CBUUID(string: "f48c7a6c-540c-4214-9e4c-f7041cfe6844")
    
    //For NIT
    let leftPeripheralUUID = UUID(uuidString: "721E54CA-E1BA-595E-AF97-C49D2998436A") // M5StickCP2(L)
    let rightPeripheralUUID = UUID(uuidString: "EFDABB3F-18AD-F631-846F-A58A9427D077") // M5StickCP2(R)
    
    //For NOM
    //let leftPeripheralUUID = UUID(uuidString: "FFBD1E41-67FC-231E-0FE7-FB03A3D18DC2") // M5StickCP2(L)
    //let rightPeripheralUUID = UUID(uuidString: "D318B40F-5AC8-5E47-00D0-A426C337A5C6") // M5StickCP2(R)
    
    var lastStepTimeL: TimeInterval = 0
    var lastStepTimeR: TimeInterval = 0

    var onLStepDetectionNotified: (() -> Void)?
    var onRStepDetectionNotified: (() -> Void)?

    init(parameters: StepDetectionParameters) {
        self.parameters = parameters
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        startPeriodicMonitoring()
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            isSwitchedOn = true
            startScanning() // 🎯 BluetoothがONになったら自動スキャン開始
        } else {
            isSwitchedOn = false
        }
    }
    
    func startPeriodicMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.isSwitchedOn {
                self.checkAndReconnectPeripherals()
            }
        }
    }

    func checkAndReconnectPeripherals() {
        if !scanEnabled { return }
        
        let connectedUUIDs = connectedPeripherals.map { $0.identifier }
        
        if !connectedUUIDs.contains(leftPeripheralUUID!) {
            print("Reconnecting to left peripheral...")
            reconnectPeripheral(with: leftPeripheralUUID!)
        }
        if !connectedUUIDs.contains(rightPeripheralUUID!) {
            print("Reconnecting to right peripheral...")
            reconnectPeripheral(with: rightPeripheralUUID!)
        }
    }

    func reconnectPeripheral(with uuid: UUID) {
        if let peripheral = peripherals.first(where: { $0.identifier == uuid }) {
            connectPeripheral(peripheral: peripheral)
        } else {
            startScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !peripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            peripherals.append(peripheral) // 🎯 ここで追加
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Peripheral disconnected: \(peripheral.identifier)")
        connectedPeripherals.removeAll { $0.identifier == peripheral.identifier }
        // 再接続を試みる
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.connectPeripheral(peripheral: peripheral)
        }
    }

    //NOTE:withServiceをnilにすると、全デバイスを検索
    func startScanning() {
        if !scanEnabled { return }
        
        print("Scanning...")
        centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)

        // 🎯 1秒後にスキャン停止して自動接続
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.centralManager.stopScan()
            print("Scan completed. Found \(self.peripherals.count) devices.")
            self.autoConnectAllPeripherals()
        }
    }

    func connectPeripheral(peripheral: CBPeripheral) {
        print("Connect peripheral")
        print(peripheral)
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    // 🎯 自動接続機能
    func autoConnectAllPeripherals() {
        for peripheral in peripherals {
            if peripheral.state == .disconnected { // すでに接続済みのデバイスはスキップ
                connectPeripheral(peripheral: peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Enter didConnect")
        // 意外とこれがないとサービスの登録がうまくいかなかった
        peripheral.delegate = self
        peripheral.discoverServices(nil)

        // 🎯 接続済みデバイスリストに追加
        if !connectedPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            connectedPeripherals.append(peripheral)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("enter didDiscoverService")
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([stepCharacteristicUUID], for: service)
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
        guard let data = characteristic.value, let decodedString = String(data: data, encoding: .utf8) else { return }
        
        let imuDataStrings = decodedString.split(separator: ",")
        guard imuDataStrings.count == 6 else {
            print("❗️Error: IMU data format incorrect: \(decodedString)")
            return
        }
        
        let imuData = imuDataStrings.compactMap { Float($0) }
        
        guard imuData.count == 6 else {
            print("❗️Error: Failed to convert IMU data to Float: \(decodedString)")
            return
        }
        
        let az = imuData[2]
        
        let currentTime = Date().timeIntervalSince1970 * 1000 // ミリ秒単位

        if peripheral.identifier == leftPeripheralUUID {
            detectStep(peripheral: "L", az: az, currentTime: currentTime)
        } else if peripheral.identifier == rightPeripheralUUID {
            detectStep(peripheral: "R", az: az, currentTime: currentTime)
        }
    }

    private func detectStep(peripheral: String, az: Float, currentTime: TimeInterval) {
        let azThreshould = parameters.azThreshould
        let debounceTime = parameters.debounceTime
        
        if peripheral == "L" {
            if az < azThreshould && currentTime - lastStepTimeL > debounceTime {
                lastStepTimeL = currentTime
                print("✅ L step detected!")
                onLStepDetectionNotified?()
            }
        } else if peripheral == "R" {
            if az < azThreshould && currentTime - lastStepTimeR > debounceTime {
                lastStepTimeR = currentTime
                print("✅ R step detected!")
                onRStepDetectionNotified?()
            }
        }
    }
}
