//
//  ServerUtils.swift
//  App
//
//  Created by DylanHu on 2020/5/12.
//

import Foundation
import Vapor
import Crypto
import Random


class ServerUtils {
    
    
    static func getImageDirectory(_ path: String, req: Request) throws -> String {
        let workDir = DirectoryConfig.detect().workDir
        let envPath = req.environment.isRelease ? "release" : "debug"
        let filePath = "dayJournal/\(envPath)/\(path)"
        var localPath = ""
        if workDir.contains("dylanhu") {
            localPath = "/Users/dylanhu/Documents/\(filePath)"
        } else if (workDir.contains("root")) {
            localPath = "/root/image/\(filePath)"
        } else {
            localPath = "\(workDir)\(filePath)"
        }
        let manager = FileManager.default
        if !manager.fileExists(atPath: localPath) {
            try manager.createDirectory(atPath: localPath, withIntermediateDirectories: true, attributes: nil)
        }
        return localPath
    }
    
    static func imageName() -> String {
        return Date().format("yyyyMMddHHmmss") + ".png"
    }
}


extension Date {
    func format(_ format: String) -> String {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = format
        return dateformatter.string(from: self)
    }
}
