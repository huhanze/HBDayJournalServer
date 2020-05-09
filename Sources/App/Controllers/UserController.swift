//
//  UserController.swift
//  App
//
//  Created by DylanHu on 2020/5/6.
//

import Vapor
import FluentMySQL
import Crypto
import Authentication

final class UserController: RouteCollection {
    private let authController = AuthController()
    
    func boot(router: Router) throws {
        let group = router.grouped("users")
        
        // post
        group.post(User.self, at: "register", use: register)
        group.post(User.self, at: "login", use: login)
        group.post(GetUserInfoContainer.self, at: "getUserInfo", use: getUserInfo)
        group.post(UserInfoRequestContainer.self, at: "updateUserInfo", use: updateUserInfo)
    }
}

extension UserController {
    
    // MARK: - 注册
    func register(_ req: Request, newUser: User) throws -> Future<Response> {
        let firstElement = User.query(on: req).filter(\.account == newUser.account).first()
        return firstElement.flatMap { existUser in
            guard existUser == nil else {
                return try ResponseJSON<Empty>(status: .userHasExist).encode(for: req)
            }
            
            if newUser.account.isValidateAccount().0 == false {
                return try ResponseJSON<Empty>(status: .failed, message: newUser.account.isValidateAccount().1).encode(for: req)
            }
            
            if newUser.password.isValidatePassword().0 == false {
                return try ResponseJSON<Empty>(status: .failed, message: newUser.password.isValidatePassword().1).encode(for: req)
            }
            
            return try newUser.secureUser(with: req.make(BCryptDigest.self)).save(on: req).flatMap { user in
                
                return try self.authController.authContainer(for: user, on: req).flatMap({ (container) in
                    var access = AccessContainer(accessToken: container.accessToken)
                    if !req.environment.isRelease {
                        access.userID = user.userID
                    }
                    return try ResponseJSON<AccessContainer>(status: .success, message: "注册成功", content: access).encode(for: req)
                })
            }
        }
    }
    
    // MARK: - 登录
    func login(_ req: Request, _ user: User) throws -> Future <Response> {
        let firstResult = User.query(on: req).filter(\.account == user.account).first()
        return firstResult.flatMap { (loginUser) in
            guard let loginUser = loginUser else {
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
            
            let digest = try req.make(BCryptDigest.self)
            guard try digest.verify(user.password, created: loginUser.password) else {
                return try ResponseJSON<Empty>(status: .invalidatePassword).encode(for: req)
            }
            
            return try self.authController.authContainer(for: loginUser, on: req).flatMap({ (container) in
                var access = AccessContainer(accessToken: container.accessToken)
                if !req.environment.isRelease {
                    access.userID = loginUser.userID
                }
                return try ResponseJSON<AccessContainer>(status: .success, message: "登录成功", content: access).encode(for: req)
            })
        }
    }
    // MARK: - 获取用户信息
    func getUserInfo(_ req: Request, _ container: GetUserInfoContainer) throws -> Future<Response> {
        
        let (token,response) = try req.checkParamsInHeader(req, name: "token")
        if let token_ = token, token_.count > 0  {
            let tokenString = BearerAuthorization(token: token_)
            return AccessToken.authenticate(using: tokenString, on: req).flatMap { (existToken) in
                guard existToken != nil else {
                    return try ResponseJSON<Empty>(status: .invalidateToken).encode(for: req)
                }
                
                let firstResult = UserInfo.query(on: req).filter(\.userID == container.userID).first()
                return firstResult.flatMap { (existUserInfo)  in
                    
                    if let existUserInfo = existUserInfo, let userID = existUserInfo.userID, userID.count > 0 {
                        let userInfo = UserInfoContainer(existUserInfo)
                        return try ResponseJSON<UserInfoContainer>(content:userInfo).encode(for: req)
                    }
                    return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
                }
            }
        }
        
        return response
    }
    
    // MARK: - 更新用户信息
    func updateUserInfo(_ req: Request, _ container: UserInfoRequestContainer) throws -> Future<Response> {
        let token = BearerAuthorization(token: container.token)
        return AccessToken.authenticate(using: token, on: req).flatMap({ existToken in
            guard let existToken = existToken else {
                return try ResponseJSON<Empty>(status: .invalidateToken).encode(for: req)
            }
            
            let first = UserInfo.query(on: req).filter(\.userID == existToken.userID).first()
            return first.flatMap({ existUserInfo in
                let userInfo: UserInfo?
                if var existUserInfo = existUserInfo {
                    userInfo = existUserInfo.update(with: container)
                } else {
                    userInfo = UserInfo(id: nil, userID: container.userID, age: container.age, sex: container.sex, nickName: container.nickName, phoneNumber: container.phoneNumber, birthday: container.birthday, city: container.city, location: container.location, portraitUrl: container.portraitUrl)
                }
                
                return userInfo!.save(on: req).flatMap({ updatedUserInfo in
                    return try ResponseJSON<Empty>(status: .success, message: "成功更新用户信息").encode(for: req)
                })
            })
        })
    }
}

fileprivate struct AccessContainer: Content {
    var accessToken: String
    var userID: String?
    
    init(accessToken: String, userID: String? = nil) {
        self.accessToken = accessToken
        self.userID = userID
    }
}

private extension User {
    
    func secureUser(with digest: BCryptDigest) throws -> User {
        return try User(userID: UUID().uuidString, account, digest.hash(password))
    }
}


struct GetUserInfoContainer: Content {
    var userID: String
}
