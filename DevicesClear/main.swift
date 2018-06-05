//
//  main.swift
//  DevicesClear
//
//  Created by RockerHX on 2018/6/5.
//  Copyright © 2018年 RockerHX. All rights reserved.
//


import Foundation


extension String {

    public func position(of subString: String, backwards: Bool = false) -> Int {
        var pos = -1
        if let range = range(of: subString, options: (backwards ? .backwards : .literal)) {
            if !range.isEmpty {
                pos = self.distance(from: startIndex, to: range.lowerBound)
            }
        }
        return pos
    }

    public func truncation(of subString: String, backwards: Bool = false) -> [String] {
        let postion = position(of: subString, backwards: backwards)
        var postionIndex = String.Index(encodedOffset: postion)
        let left = self[startIndex..<postionIndex]
        postionIndex = String.Index(encodedOffset: (postion + 1))
        let right = self[postionIndex...]
        return [String(left), String(right)]
    }

    public func intercept(of subString: String, backwards: Bool = false) -> String {
        guard let interrupt = truncation(of: subString, backwards: backwards).first else { return "" }
        return interrupt
    }

}


let HomeDirectory = FileManager.default.homeDirectoryForCurrentUser
let Path = "Library/Developer/CoreSimulator/Devices"
let FileName = "device_set.plist"
let WholePath = HomeDirectory.appendingPathComponent(Path).appendingPathComponent(FileName)


struct Device {
    let name: String
    let path: String

    init?(with key: String, value: String) {
        guard let series = key.truncation(of: ".", backwards: true).last else { return nil }
        name = series
        path = value
    }
}


struct Series {
    let indexKey: String
    let name: String
    let version: String
    var devices = [Device]()

    init?(with key: String, value: [String: String]) {
        indexKey = key
        guard let series = key.truncation(of: ".", backwards: true).last else { return nil }
        let nameAndversion = series.truncation(of: "-")
        guard let sName = nameAndversion.first, let sVersion = nameAndversion.last else { return nil }
        name = sName
        version = sVersion
        value.forEach { (key, value) in
            guard let device = Device(with: key, value: value) else { return }
            devices.append(device)
        }
    }
}


func loadDevices() -> [String: Any]? {
    guard let sets = NSDictionary(contentsOf: WholePath) else { return nil }
    guard let devices = sets["DefaultDevices"] as? [String: Any] else { return nil }
    return devices
}


func packSerieses(with devices: [String: Any]?) -> [Series]? {
    guard let defaultDevices = devices else { return nil }

    var serieses = [Series]()
    defaultDevices.forEach { (key, value) in
        guard let devices = value as? [String: String] else { return }
        guard let series = Series(with: key, value: devices) else { return }
        serieses.append(series)
    }
    serieses.sort { $0.name > $1.name }
    return serieses
}


extension Array where Element == Series {

    func delete(with input: String) -> [Element] {
        let choses = input.components(separatedBy: ", ").map { return Int($0)! }
        var deletes = [Series]()
        choses.forEach { (index) in
            if index >= 0 && index < count {
                deletes.append(self[index])
            } else {
                print("❌ failed chose.")
            }
        }
        let fileManager = FileManager.default
        deletes.forEach { (series) in
            series.devices.forEach({ (device) in
                let path = HomeDirectory.appendingPathComponent(Path).appendingPathComponent(device.path)
                try? fileManager.removeItem(at: path)
            })
        }
        return deletes
    }

}


func start() {
    guard var devices = loadDevices() else { return }
    guard let serieses = packSerieses(with: devices) else { return }
    print("-----------------------------------")
    serieses.enumerated().forEach { (index, series) in
        print("\(index).\(series.version) - \(series.name)")
    }
    print("-----------------------------------")
    print("Chose you want to delete deveice series(eg: 1, 2, 3):")
    if let input = readLine() {
        let deletes = serieses.delete(with: input)
        deletes.forEach { (series) in
            devices[series.indexKey] = nil
        }
        if !deletes.isEmpty {
            let store = ["DefaultDevices": devices] as NSDictionary
            try? store.write(to: WholePath)
        }
        print("✅ Clean success!!!")
    } else {
        print("❌ File Load failure, please check your json file name.")
    }
}


start()
