//
//  AuthController.swift
//  App
//
//  Created by DylanHu on 2020/5/7.
//

import Foundation
import Vapor
import Fluent
import Crypto


struct AuthController {
    func authContainer(for refreshToken: RefreshToken.Token, on conn: DatabaseConnectable) throws -> Future<AuthContainer> {
        return try existedUser(matchingTokenString: refreshToken, on: conn).flatMap({ (user) in
            guard let user = user else { throw Abort(.notFound)}
            return try self.authContainer(for: user, on: conn)
        })
    }
    
    func authContainer(for user: User, on conn: DatabaseConnectable) throws -> Future<AuthContainer> {
        return try removeAllTokens(for: user, on: conn).flatMap({ _ in
            return try map(to: AuthContainer.self, self.accessToken(for: user, on: conn), self.refreshToken(for: user, on: conn), { (access, refresh) in
                return AuthContainer(accessToken: access, refreshToken: refresh)
            })
        })
    }
    
    func remmoveTokens(userID: String, on conn: DatabaseConnectable) throws -> Future<Void> {
        return User.query(on: conn).filter(\.userID == userID).first().flatMap { (user) in
            guard let user = user else { return Future.map(on: conn) {  Void()}}
            return try self.removeAllTokens(for: user, on: conn)
        }
    }
}

private extension AuthController {
    
    func existedUser(matchingTokenString tokenString: RefreshToken.Token, on conn: DatabaseConnectable) throws -> Future<User?> {
        return RefreshToken.query(on: conn).filter(\.tokenString == tokenString).first().flatMap { token in
            guard let token = token else {throw Abort(.notFound)}
            return User.query(on: conn).filter(\.userID == token.userID).first()
        }
    }
    
    func existedUser(matchingUser user: User, on conn: DatabaseConnectable) throws -> Future<User?> {
        return User.query(on: conn).filter(\.account == user.account).first()
    }
    
    func removeAllTokens(for user: User, on conn: DatabaseConnectable) throws -> Future<Void> {
        let accessTokens = AccessToken.query(on: conn).filter(\.userID == user.userID!).delete()
        let refreshToken = RefreshToken.query(on: conn).filter(\.userID == user.userID!).delete()
        return map(to: Void.self, accessTokens, refreshToken) { (_, _) in
            Void()
        }
    }
    
    func accessToken(for user: User, on conn: DatabaseConnectable) throws -> Future<AccessToken> {
        return try AccessToken(userID: user.userID ?? "").save(on: conn)
    }
    
    func refreshToken(for user: User, on conn: DatabaseConnectable) throws -> Future<RefreshToken> {
        return try RefreshToken(userID: user.userID ?? "").save(on: conn)
    }
    
    func accessToken(for refreshToken: RefreshToken, on conn: DatabaseConnectable) throws -> Future<AccessToken> {
        return try AccessToken(userID: refreshToken.userID).save(on: conn)
    }
}

