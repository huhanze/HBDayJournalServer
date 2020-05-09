//
//  User.swift
//  App
//
//  Created by DylanHu on 2020/5/6.
//

import FluentMySQL
import Vapor
import Authentication

struct  User: MySQLModel {
    typealias Database = MySQLDatabase
    
    var id: Int?
    var userID: String?
    private(set) var account: String
    
    var password: String
    
    /// 创建用户
    init(userID: String, _ account: String, _ password: String) {
        self.userID = userID
        self.account = account
        self.password = password
    }
    
    var createdAt: Date?
    var updatedAt: Date?
    var deletedAt: Date?
}


/// Allows `User` to be used as a dynamic migration.
extension User: Migration { }

/// Allows `User` to be encoded to and decoded from HTTP messages.
extension User: Content {}

/// Allows `User` to be used as a dynamic parameter in route definitions.
extension User: Parameter {}

extension User {
    static var entity: String { return self.name + "s"}
    
    static var createdAtKey: TimestampKey? = \User.createdAt
    static var updatedAtKey: TimestampKey? = \User.updatedAt
    static var deletedAtKey: TimestampKey? = \User.deletedAt
}

extension User: BasicAuthenticatable {
    static var usernameKey: UsernameKey {
        return \.account
    }
    
    static var passwordKey: PasswordKey {
        return \.password
    }
}

extension User {
    func willCreate(on conn: MySQLConnection) throws -> EventLoopFuture<User> {
        return Future.map(on: conn) {
            self
        }
    }
}

