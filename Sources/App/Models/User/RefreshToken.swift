//
//  RefreshToken.swift
//  App
//
//  Created by DylanHu on 2020/5/7.
//

import Crypto
import FluentMySQL
import Vapor

struct RefreshToken: MySQLModel {
    typealias Database = MySQLDatabase
    var id: Int?
    
    static var entity: String {
        return self.name + "s"
    }
    
    typealias Token = String
    
    let tokenString: Token
    let userID: String
    
    init(userID: String) throws {
        self.tokenString = try CryptoRandom().generateData(count: 32).base64EncodedString()
        self.userID = userID
    }
}


/// Allows `RefreshToken` to be used as a dynamic migration.
extension RefreshToken: Migration { }

/// Allows `RefreshToken` to be encoded to and decoded from HTTP messages.
extension RefreshToken: Content {}

/// Allows `RefreshToken` to be used as a dynamic parameter in route definitions.
extension RefreshToken: Parameter {}
