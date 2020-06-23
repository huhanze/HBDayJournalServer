//
//  UserInfo.swift
//  App
//
//  Created by DylanHu on 2020/5/7.
//

import Foundation
import Vapor
import FluentMySQL

struct UserInfo: MySQLModel {
    typealias Database = MySQLDatabase
    var id: Int?
    
    static var entity: String {
        return self.name + "s"
    }
    
    var userID: String?
    var age: Int?
    var sex: Int?
    var nickName: String?
    var phoneNumber: String?
    var birthday: String?
    var city: String?
    var location: String?
    var portraitUrl: String?
    var coverImageUrl: String?
    
}

extension UserInfo {
    mutating func update(with container: UserInfoContainer) -> UserInfo {
        age = container.age
        sex = container.sex
        nickName = container.nickName
        portraitUrl = container.portraitUrl
        coverImageUrl = container.coverImageUrl
        phoneNumber = container.phoneNumber
        location = container.location
        birthday = container.birthday
        city = container.city
        return self
    }
    
    mutating func update(with container: UserInfoRequestContainer) -> UserInfo {
        age = container.age
        sex = container.sex
        nickName = container.nickName
        portraitUrl = container.portraitUrl
        coverImageUrl = container.coverImageUrl
        phoneNumber = container.phoneNumber
        location = container.location
        birthday = container.birthday
        city = container.city
        return self
    }
}

extension UserInfo: Migration {}
extension UserInfo: Content {}

struct UserInfoContainer: Content {
    var userID: String = ""
    var nickName: String = ""
    var portraitUrl: String = ""
    var coverImageUrl: String = ""
    var phoneNumber: String = ""
    var birthday: String = ""
    var city: String = ""
    var location: String = ""
    var age: Int = 0
    var sex: Int = 0
    
    init(_ user: UserInfo) {
        userID = user.userID ?? ""
        nickName = user.nickName ?? ""
        portraitUrl = user.portraitUrl ?? ""
        coverImageUrl = user.coverImageUrl ?? ""
        phoneNumber = user.phoneNumber ?? ""
        birthday = user.birthday ?? ""
        city = user.city ?? ""
        location = user.location ?? ""
        age = user.age ?? 0
        sex = user.sex ?? 0
    }
}

struct UserInfoRequestContainer: Content {
    var token: String
    var userID: String?
    var nickName: String?
    var portraitUrl: String?
    var coverImageUrl: String?
    var phoneNumber: String?
    var birthday: String?
    var city: String?
    var location: String?
    var age: Int?
    var sex: Int?
}

struct UserPortraitContainer: Content {
    var token: String
    var imageFile: File
}

struct UserCoverImageContainer: Content {
    var token: String
    var imageFile: File
}
