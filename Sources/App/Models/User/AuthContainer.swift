//
//  AuthContainer.swift
//  App
//
//  Created by DylanHu on 2020/5/7.
//

import Vapor

struct AuthContainer: Content {
    let accessToken: AccessToken.Token
    let expiresIn: TimeInterval
    let refreshToken: RefreshToken.Token
    
    init(accessToken: AccessToken, refreshToken: RefreshToken) {
        self.accessToken = accessToken.tokenString
        self.expiresIn = AccessToken.accessTokenExpirationInterval
        self.refreshToken = refreshToken.tokenString
    }
}


struct RefreshTokenContainer: Content {
    let refreshToken: RefreshToken.Token
}
