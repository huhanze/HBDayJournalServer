//
//  HTTPRequestExtension.swift
//  App
//
//  Created by DylanHu on 2020/5/8.
//

import Foundation
import Vapor

extension HTTPHeaders {
    func getHeaderValue(_ name: String) -> String? {
        guard self.contains(name: name) else {
            return nil
        }
        
        return self[HTTPHeaderName(name)].first
    }
}


extension Request {
    // MARK: - 获取请求的host
    func getHost() -> String {
        return ConfigureManager.hostName
    }
    // MARK: - 获取HTTPMethod
    func getHTTPMethod() -> HTTPMethod {
        return self.http.method
    }
    // MARK: - 请求是否有body
    func isHasBody() -> Bool {
        return self.getHTTPMethod().hasRequestBody == .yes
    }
    
    // MARK: - headers相关
    
    /// 是否包含指定的header信息
    /// - Parameter name: header的name
    /// - Returns: true 包含该header，false 不包含
    func isContainHeader(_ name: String) -> Bool {
        return self.http.headers.contains(name: name)
    }
    
    // MARK: 获取指定请求头信息
    
    /// 获取指定请求头信息
    /// - Parameter name: 请求头的name
    /// - Returns: 返回请求头name的首个值(请求头中可能有多个相同的name)
    func getHeaderValue(_ name: String) -> String? {
        return self.http.headers.getHeaderValue(name)
    }
    
    /// 检查headers中的参数
    func checkParamsInHeader(_ req: Request, name headerName: String) throws ->  (String?,Future<Response>) {
        if !req.isContainHeader(headerName) {
            return try (nil,ResponseJSON<Empty>(status: .lessParam, message: "缺少\(headerName)参数").encode(for: req))
        }
        
        if let headerValue = self.getHeaderValue(headerName), headerValue.count > 0 {
            return try (headerValue,ResponseJSON<Empty>(status: .success).encode(for: req))
        }
        
        return try (nil,ResponseJSON<Empty>(status: .lessParam, message: "\(headerName)值不能为空").encode(for: req))
    }
    
}
