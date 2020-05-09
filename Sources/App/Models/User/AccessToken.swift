//
//  AccessToken.swift
//  App
//
//  Created by DylanHu on 2020/5/7.
//

import Foundation
import Vapor
import Crypto
import Authentication
import FluentMySQL

struct AccessToken: MySQLModel {
    typealias Database = MySQLDatabase
    var id: Int?
    
    typealias Token = String
    
    static var entity: String {return "AccessTokens"}
    static let accessTokenExpirationInterval: TimeInterval = 60 * 60 * 24 * 30
    
    /// token
    private(set) var tokenString: Token
    /// 用户ID
    private(set) var userID: String
    /// 过期时间
    let expireTime: Date
    
    init(userID: String) throws {
        self.tokenString = try CryptoRandom().generateData(count: 32).base64EncodedString()
        self.userID = userID
        
        let date = Date(timeIntervalSinceNow: AccessToken.accessTokenExpirationInterval)
        self.expireTime = date
    }
}

extension AccessToken: BearerAuthenticatable {
    static var tokenKey: TokenKey = \.tokenString
    
    public static func authenticate(using bearer: BearerAuthorization, on conn: DatabaseConnectable) -> EventLoopFuture<AccessToken?> {
        return Future.flatMap(on: conn) {
            return AccessToken.query(on: conn).filter(tokenKey == bearer.token).first().map { token in
                guard let token = token , token.expireTime > Date() else {return nil}
                return token
            }
        }
    }
}


/// Allows `AccessToken` to be used as a dynamic migration.
extension AccessToken: Migration { }

/// Allows `AccessToken` to be encoded to and decoded from HTTP messages.
extension AccessToken: Content {}

/// Allows `AccessToken` to be used as a dynamic parameter in route definitions.
extension AccessToken: Parameter {}
