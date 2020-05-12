//
//  ResponseJSON.swift
//  App
//
//  Created by DylanHu on 2020/5/7.
//

import Vapor

struct Empty: Content {

}

enum ResponseStatus: Int,Content {
    case success = 0
    case failed = 1
    case lessParam = 2
    case errorParam = 3
    case invalidateToken = 4
    case invalidatePassword = 5
    case unknownError = -1
    case userHasExist = 50000
    case userNotExist = 50001
    case imageSizeToMaxLimit = 60001
    
    var description : String {
        switch self {
        case .success:
            return "请求成功"
        case .failed:
            return "请求失败"
        case .errorParam:
            return "参数错误"
        case .invalidateToken:
            return "token已失效,请重新登录！"
        case .unknownError:
            return "未知错误"
        case .userHasExist:
            return "用户已存在"
        case .userNotExist:
            return "用户不存在"
        case .invalidatePassword:
            return "密码错误"
        case .lessParam:
            return "缺少参数"
        case .imageSizeToMaxLimit:
            return "图片超过了最大限制"
        }
    }
}

/// 请求响应
struct ResponseJSON<T: Content>: Content {
    
    /// 状态值
    private var status: ResponseStatus
    /// 请求响应结果描述
    private var message: String
    /// 返回的数据
    private var content: T?
    
    
    // MARK: - 初始化方法
    /// 请求成功时，初始化数据
    /// - Parameter data: 需要返回的数据
    init(content: T) {
        self.status = .success
        self.message = status.description
        self.content = content
    }
    
    /// 只返回请求的状态，不返回数据
    /// - Parameter status: 根据请求需要返回的状态参数，默认请求成功
    init(status: ResponseStatus = .success) {
        self.status = status
        self.message = status.description
        self.content = nil
    }
    
    /// 只返回请求的状态，不返回数据
    /// - Parameters:
    ///   - status: 根据请求需要返回的状态参数，默认请求成功
    ///   - message: 状态参数描述
    init(status: ResponseStatus = .success,
         message: String = ResponseStatus.success.description) {
        self.status = status
        self.message = message
        self.content = nil
    }
    
    /// 根据请求，返回相关的结果
    /// - Parameters:
    ///   - status: 响应状态
    ///   - message: 状态描述
    ///   - data: 请求应返回的数据
    init(status: ResponseStatus = .success,
         message: String = ResponseStatus.success.description,
         content: T?) {
        self.status = status
        self.message = message
        self.content = content
    }
}
