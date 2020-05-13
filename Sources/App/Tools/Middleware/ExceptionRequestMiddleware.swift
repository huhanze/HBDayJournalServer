//
//  ExceptionRequestMiddleware.swift
//  App
//  异常路由处理
//  Created by DylanHu on 2020/5/13.
//

import Foundation
import Vapor

public final class ExceptionRequestMiddleware: Middleware {
    /// 请求回调
    typealias RequestCallback = (Request) throws -> (Future<Response>?)
    private let callback: RequestCallback
    
    init(callback: @escaping RequestCallback) {
        self.callback = callback
    }
}


extension ExceptionRequestMiddleware {
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        return try next.respond(to: request).flatMap({ (response) in
            let status = response.http.status
            if status == .notFound { // 对404 错误拦截处理
                if let response = try self.callback(request) {
                    return response
                }
            }
            return request.eventLoop.newSucceededFuture(result: response)
        })
    }
}
