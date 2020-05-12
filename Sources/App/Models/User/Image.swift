//
//  Image.swift
//  App
//
//  Created by DylanHu on 2020/5/12.
//

import Foundation
import FluentMySQL
import Vapor

struct Image: MySQLModel {
    typealias Database = MySQLDatabase
    
    enum ImageType: String {
        case userPortrait = "userPortrait"
    }
    
    var id: Int?
    
    var createdAt: Date?
    var updatedAt: Date?
    
    /// 用户ID
    var userID: String
    /// 图片作用类型，如：用户头像
    var type: String
    /// 图片名称
    var name: String
    /// 图片路径
    var path: String
    
    
    init(_ userID: String, _ type: ImageType, name: String, _ path: String) {
        self.userID = userID
        self.type = type.rawValue
        self.name = name
        self.path = path
    }
    
}


extension Image {
    
    static var entity: String { return self.name + "s"}
    
    static var createdAtKey: TimestampKey? = \Image.createdAt
    static var updatedAtKey: TimestampKey? = \Image.updatedAt
}

extension Image: Migration{}

extension Image: Content{}


//extension Image: Decodable {
//    
//}
