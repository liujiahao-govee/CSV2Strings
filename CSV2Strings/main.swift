//
//  main.swift
//  CSV2Strings
//
//  Created by 刘嘉豪 on 2021/5/25.
//

import Foundation

// 导出路径
let exportPath = "/Users/liujiahao/Desktop/strings"
// csv文件目录
let inputPath = "/Users/liujiahao/Desktop/iOS多语言.csv"


let fileName = "Localizable.strings"
let fileManager = FileManager.default

// strings 转 csv
//stringsToCsv()

// csv 转 strings
csvToStrings()

func csvToStrings() {
    
    guard let fileData = fileManager.contents(atPath: inputPath) else { return }
    
    guard let strArr = String(data: fileData, encoding: .utf8)?.components(separatedBy: "\r\n") else { return }
    
    var writeStrArr = [String]()
    var lproj = [String]()
    var keyDict = [String: Any]()
    var duplicatedKeys = [String]()
    
    let pattern = ",(?=([^\"]*\"[^\"]*\")*[^\"]*$)" // 分隔逗号的正则
    //2. 创建这正则表达式对象
    let regex = try? NSRegularExpression(pattern: pattern, options: []);
    
    for (index,value) in strArr.enumerated() {
        //3. 匹配字符串中的内容
        guard let tempArr = regex?.matches(in: value, options: [], range: NSRange(location: 0, length: value.count)) else
        {
            break
        }
        
        if index == 0 {
            for i in 0..<tempArr.count {
                let from = value.index(value.startIndex, offsetBy: tempArr[i].range.upperBound)
                var to:String.Index
                if i + 1 == tempArr.count {
                    to = value.endIndex
                }else {
                    to = value.index(value.startIndex, offsetBy: tempArr[i+1].range.lowerBound)
                }
                let line = String(value[from ..< to])
                if line.isEmpty {
                    continue
                }
                lproj.append(line)
                writeStrArr.append("")
            }
            continue
        }
        if tempArr.count < 1 {
            continue
        }
        
        let keyfrom = value.startIndex
        let keyto = value.index(value.startIndex, offsetBy: tempArr[0].range.lowerBound)
        var key = String(value[keyfrom ..< keyto]).replacingOccurrences(of: "\"\"", with: "\"")
        
        if key.hasPrefix("\"") {
            key.removeFirst()
        }
        
        if key.hasSuffix("\"") {
            key.removeLast()
        }
        
        if keyDict.updateValue("", forKey: key) != nil {
            duplicatedKeys.append(key)
        }
        
        for i in 0..<tempArr.count {
            if writeStrArr.count > i - 1 {
                let from = value.index(value.startIndex, offsetBy: tempArr[i].range.upperBound)
                var to:String.Index
                if i + 1 == tempArr.count {
                    to = value.endIndex
                }else {
                    to = value.index(value.startIndex, offsetBy: tempArr[i+1].range.lowerBound)
                }
                var tempvalue = String(value[from ..< to]).replacingOccurrences(of: "\"\"", with: "\"")
                if tempvalue.count == 0 {
                    continue
                }
                if tempvalue[tempvalue.startIndex] == "\"" {
                    tempvalue = String(tempvalue[tempvalue.index(tempvalue.startIndex, offsetBy: 1) ..< tempvalue.endIndex])
                }
                if tempvalue[tempvalue.index(tempvalue.endIndex, offsetBy: -1)] == "\"" {
                    tempvalue = String(tempvalue[tempvalue.startIndex ..< tempvalue.index(tempvalue.endIndex, offsetBy: -1)])
                }
                tempvalue = tempvalue.replacingOccurrences(of: "\"", with: "\\\"")
                writeStrArr[i].append("\"\(key)\" = \"\(tempvalue)\";\n")
            }
        }
    }
    for (i,dir) in lproj.enumerated() {
        let dirPath = exportPath+"/"+dir
        let filePath = dirPath + "/"+fileName
        
        try? fileManager.createDirectory(atPath: dirPath, withIntermediateDirectories: true, attributes: nil)
        
        let writeData = writeStrArr[i].data(using: .utf8)
        do {
            try writeData?.write(to: URL.init(fileURLWithPath: filePath))
            print("导出成功：\(filePath)")
        }catch {
            print(error)
        }
    }
    
    if !duplicatedKeys.isEmpty {
        print("⚠️⚠️⚠️重复keys: \(duplicatedKeys)!!!")
    }
}

func stringsToCsv() {
    var writeDic = [[String:String]]()
    var lproj = [String]()
    
    let dirs = try! fileManager.contentsOfDirectory(atPath: exportPath)
    for dir in dirs {
        if !dir.hasSuffix("lproj") {
            continue
        }
        let filePath = exportPath+"/"+dir+"/"+fileName
        let fileData = fileManager.contents(atPath: filePath)
        if (fileData == nil) {
            continue
        }
        lproj.append("\""+dir+"\"")
        
        guard let str = String(data: fileData!, encoding: .utf8) else {
            return
        }
        let pattern = "\".*\"" // 换行的正则匹配
        //2. 创建这正则表达式对象
        let regex = try? NSRegularExpression(pattern: pattern, options: []);
        //3. 匹配字符串中的内容
        guard let results = regex?.matches(in: str, options: [], range: NSRange(location: 0, length: str.count)) else
        {
            return
        }
        
        let linePattern = "\"\\s*[=]\\s*\""
        let lineRegex = try? NSRegularExpression(pattern: linePattern, options: []);
        
        for result in results {
            let from16 = str.index(str.startIndex, offsetBy: result.range.location)
            let to16 = str.index(from16, offsetBy: result.range.length)
            let line = String(str[from16 ..< to16])
            
            guard let lineResults = lineRegex?.matches(in: line, options: [], range: NSRange(location: 0, length: line.count)) else
            {
                continue
            }
            if lineResults.count == 0 {
                continue
            }
            let lineRange = lineResults[0].range
            let fromKey = line.index(line.startIndex, offsetBy: lineRange.location)
            let toKey = line.index(fromKey, offsetBy:lineRange.length)
            var key = String(line[line.index(line.startIndex, offsetBy: 1) ..< fromKey])
            key = key.replacingOccurrences(of: "\"", with: "\"\"")
            var value = String(line[toKey ..< line.index(line.endIndex, offsetBy: -1)])
            value = value.replacingOccurrences(of: "\"", with: "\"\"")
            
            var index = -1
            
            for (i, dic) in writeDic.enumerated() {
                if dic["key"] == key {
                    index = i
                    break
                }
            }
            if index == -1 {
                writeDic.append(["key":key,"data":value])
            }else {
                writeDic[index]["data"]! += "\",\"" + value
            }
        }
    }
    var str = "\"Key\"," + lproj.joined(separator: ",") + "\n"
    
    for (_,dic) in writeDic.enumerated() {
        str.append("\"\(dic["key"] ?? "")\",\"\(dic["data"] ?? "")\"\n")
    }
    let writeData = str.data(using: .utf8)
    try? writeData?.write(to: URL.init(fileURLWithPath: inputPath))
    
}

func keyValue(keyValues:[String]) -> (key:String,value:String) {
    let tempKey = keyValues[0].trimmingCharacters(in: .whitespaces)
    let key1 = tempKey.range(of: "\"")?.upperBound
    let key2 = tempKey.range(of: "\"", options: .backwards)?.lowerBound
    
    let key = String(tempKey[key1! ..< key2!])
    
    let tempValue = keyValues[1].trimmingCharacters(in: .whitespaces)
    let value1 = tempValue.range(of: "\"")?.upperBound
    let value2 = tempValue.range(of: "\"", options: .backwards)?.lowerBound
    let value = String(tempValue[value1! ..< value2!])
    
    return (key.replacingOccurrences(of: "\"", with: "\"\""), value.replacingOccurrences(of: "\"", with: "\"\""))
}

