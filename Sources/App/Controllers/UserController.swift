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
        let group = router.grouped(UserController.grouped)
        
        // post
        group.post(User.self, at: path(.registerPath), use: register)
        group.post(User.self, at: path(.loginPath), use: login)
        group.post(GetUserInfoContainer.self, at: path(.getUserInfoPath), use: getUserInfo)
        group.post(UserInfoRequestContainer.self, at: path(.updateUserInfoPath), use: updateUserInfo)
        group.post(UserPortraitContainer.self, at: path(.uploadPortraitPath), use: uploadUserPortrait)
        group.post(UserCoverImageContainer.self, at: path(.uploadUserCover), use: updateUserCover)
        
        // get
        group.get(path(.userPortraitPath),String.parameter, use: getUserPortrait)
        group.get(path(.userCoverPath), String.parameter, use: getUserCoverImage)
    }
}

// MARK: - 用户路径
private extension UserController {
    
    private static let grouped = "users"
    /// 路径
    enum UserRouterPath: String {
        /// 用户注册
        case registerPath = "register"
        /// 用户登录
        case loginPath = "login"
        /// 获取用户信息
        case getUserInfoPath = "getUserInfo"
        /// 更新用户信息
        case updateUserInfoPath = "updateUserInfo"
        /// 上传用户头像
        case uploadPortraitPath = "uploadPortrait"
        /// 获取用头像
        case userPortraitPath = "userPortrait"
        /// 上传用户封面
        case uploadUserCover = "uploadUserCover"
        /// 用户封面
        case userCoverPath = "userCover"
    }
    
    /// 获取用户路径
    /// - Parameter userRouter: 路径类型
    /// - Returns: 用户路径原始值
    func path(_ userRouter: UserRouterPath) -> String {
        return userRouter.rawValue
    }

}

// MARK: - 用户相关请求
extension UserController {
    
    // MARK: 注册
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
    
    // MARK: 登录
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
    // MARK: 获取用户信息
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
    
    // MARK: 更新用户信息
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
    
    /// 上传用户头像
    /// - Parameters:
    ///   - req: 请求
    ///   - container: 请求的相关参数模型
    /// - Throws: 异常抛出
    /// - Returns: 请求的相应驱动
    func uploadUserPortrait(_ req: Request, _ container: UserPortraitContainer) throws -> Future<Response> {
        let token = BearerAuthorization(token: container.token)
        return AccessToken.authenticate(using: token, on: req).flatMap { (existToken) in
            guard let existToken = existToken else {
                return try ResponseJSON<Empty>(status: .invalidateToken).encode(for: req)
            }
            
            let first = UserInfo.query(on: req).filter(\.userID == existToken.userID).first()
            return first.flatMap { [unowned self](user) in
                if var user = user {
                    guard container.imageFile.data.count < kImageMaxSize else {
                        return try ResponseJSON<Empty>(status: .imageSizeToMaxLimit).encode(for: req)
                    }
                    let imageName = ServerUtils.imageName()
                    let filePath = try ServerUtils.getImageDirectory(ImagePath.userPortrait, req: req) + "/" + imageName
                    try Data(container.imageFile.data).write(to: URL(fileURLWithPath: filePath))
                    let firstImage = Image.query(on: req).filter(\.userID == user.userID!).filter(\.type == Image.ImageType.userPortrait.rawValue).first()
                    
                    return firstImage.flatMap({ existImage in
                        
                        var image = Image(user.userID!, Image.ImageType.userPortrait, name: imageName, filePath)
                        
                        // 若用户头像已存在，则更新头像
                        if let existImage = existImage {
                            if !existImage.path.isEmpty {
                                if FileManager.default.fileExists(atPath: existImage.path) {
                                    try FileManager.default.removeItem(atPath: existImage.path)
                                }
                                
                                image.id = existImage.id!
                                image.createdAt = existImage.createdAt
                                return image.update(on: req).flatMap({ updatedImage in
                                    user.portraitUrl = "http://" + req.getHost() + "/" + UserController.grouped + "/" + self.path(.userPortraitPath) + "/" + imageName
                                    return user.save(on: req).flatMap({ newUserInfo in
                                        try ResponseJSON<UserPotraitUrlContainer>(status: .success, message: "用户头像更新成功！",content: UserPotraitUrlContainer(portrait: newUserInfo.portraitUrl!)).encode(for: req)
                                    })
                                })
                            }
                        }
                       
                        // 第一次上传用户头像
                        return image.save(on: req).flatMap({ (existImage) in
                            user.portraitUrl = "http://" + req.getHost() + "/" + UserController.grouped + "/" + self.path(.userPortraitPath) + "/" + imageName
                            return user.save(on: req).flatMap({ newUserInfo in
                                try ResponseJSON<UserPotraitUrlContainer>(status: .success, message: "用户头像上传成功！",content: UserPotraitUrlContainer(portrait: newUserInfo.portraitUrl!)).encode(for: req)
                            })
                        })
                        
                    })
                }
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
        }
    }
    
    /// 更新用户封面
    /// - Parameters:
    ///   - req: 客户端发送的请求
    ///   - container: 请求相关参数信息
    /// - Throws: 请求发生错误抛出的异常
    /// - Returns: 返回的相应结果
    func updateUserCover(_ req: Request, _ container: UserCoverImageContainer) throws -> Future<Response> {
        let token = BearerAuthorization(token: container.token)
        return AccessToken.authenticate(using: token, on: req).flatMap { (existToken) in
            guard let existToken = existToken else {
                return try ResponseJSON<Empty>(status: .invalidateToken).encode(for: req)
            }
            
            let first = UserInfo.query(on: req).filter(\.userID == existToken.userID).first()
            return first.flatMap { [unowned self](user) in
                if var user = user {
                    guard container.imageFile.data.count < kImageMaxSize else {
                        return try ResponseJSON<Empty>(status: .imageSizeToMaxLimit).encode(for: req)
                    }
                    let imageName = ServerUtils.imageName()
                    let filePath = try ServerUtils.getImageDirectory(ImagePath.userCover, req: req) + "/" + imageName
                    try Data(container.imageFile.data).write(to: URL(fileURLWithPath: filePath))
                    let firstImage = Image.query(on: req).filter(\.userID == user.userID!).filter(\.type == Image.ImageType.userCover.rawValue).first()
                    
                    return firstImage.flatMap({ existImage in
                        
                        var image = Image(user.userID!, Image.ImageType.userCover, name: imageName, filePath)
                        
                        // 若用户头像已存在，则更新头像
                        if let existImage = existImage {
                            if !existImage.path.isEmpty {
                                if FileManager.default.fileExists(atPath: existImage.path) {
                                    try FileManager.default.removeItem(atPath: existImage.path)
                                }
                                
                                image.id = existImage.id!
                                image.createdAt = existImage.createdAt
                                return image.update(on: req).flatMap({ updatedImage in
                                    user.coverImageUrl = "http://" + req.getHost() + "/" + UserController.grouped + "/" + self.path(.userCoverPath) + "/" + imageName
                                    return user.save(on: req).flatMap({ newUserInfo in
                                        try ResponseJSON<UserCoverUrlContainer>(status: .success, message: "用户封面更新成功！",content: UserCoverUrlContainer(coverUrl: newUserInfo.coverImageUrl!)).encode(for: req)
                                    })
                                })
                            }
                        }
                       
                        // 第一次上传用户封面
                        return image.save(on: req).flatMap({ (existImage) in
                            user.portraitUrl = "http://" + req.getHost() + "/" + UserController.grouped + "/" + self.path(.userCoverPath) + "/" + imageName
                            return user.save(on: req).flatMap({ newUserInfo in
                                try ResponseJSON<UserCoverUrlContainer>(status: .success, message: "用户封面上传成功！",content: UserCoverUrlContainer(coverUrl: newUserInfo.coverImageUrl!)).encode(for: req)
                            })
                        })
                        
                    })
                }
                return try ResponseJSON<Empty>(status: .userNotExist).encode(for: req)
            }
        }
    }
    
    // MARK: 获取用户头像
    func getUserPortrait(_ req: Request) throws -> Future<Response> {
        let name = try req.parameters.next(String.self)
        print(name)
        let path = try ServerUtils.getImageDirectory(ImagePath.userPortrait, req: req) + "/" + name
        if !FileManager.default.fileExists(atPath: path) {
            return try ResponseJSON<Empty>(status: .failed, message: "访问的图片不存在！").encode(for: req)
        }
        return try req.streamFile(at: path)
    }
    
    // MARK: 获取用户封面
    func getUserCoverImage(_ req: Request) throws -> Future<Response> {
        let name = try req.parameters.next(String.self)
        print(name)
        let path = try ServerUtils.getImageDirectory(ImagePath.userCover, req: req) + "/" + name
        if !FileManager.default.fileExists(atPath: path) {
            return try ResponseJSON<Empty>(status: .failed, message: "访问的图片不存在！").encode(for: req)
        }
        return try req.streamFile(at: path)
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

struct UserPotraitUrlContainer: Content {
    var portrait: String
}

struct UserCoverUrlContainer: Content {
    var coverUrl: String
}
