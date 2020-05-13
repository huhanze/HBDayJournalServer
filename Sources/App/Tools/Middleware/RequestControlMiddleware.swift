//
//  RequestControlMiddleware.swift
//  App
//  访问控制处理
//  Created by DylanHu on 2020/5/13.
//

import Foundation
import Vapor


public struct RequestControlMiddleware {
    
    typealias BodyCallback = ((_ request: Request) throws -> Future<Response>?)
    internal var cache: MemoryKeyedCache
    internal let limit: Int
    internal let refreshInterval: Double
    internal var bodyCallback: BodyCallback?
    
    init(_ rate: Rate, _ cache: MemoryKeyedCache, bodyCallback: BodyCallback? = nil) {
        self.cache = cache
        self.limit = rate.limit
        self.refreshInterval = rate.refreshInterval
        self.bodyCallback = bodyCallback
    }
}

extension RequestControlMiddleware : Middleware {
    
    public func respond(to request: Request, chainingTo next: Responder) throws -> EventLoopFuture<Response> {
        let peer = (request.http.remotePeer.hostname ?? "") + request.http.urlString
        
        return cache.get(peer, as: [String:String].self).flatMap({(entry) in
            let createString = entry?[Keys.createdAt] ?? ""
            var createdAt = Double(createString) ?? Date().timeIntervalSince1970
            var requestsLeft = Int(entry?[Keys.requestsLeft] ?? "") ?? self.limit
            let now = Date().timeIntervalSince1970
            
            if now - createdAt >= self.refreshInterval {
                createdAt = now
                requestsLeft = self.limit
            }
            
            defer {
                let dict = [Keys.createdAt: "\(createdAt)",
                    Keys.requestsLeft: String(requestsLeft)]
                _ = self.cache.set(peer, to: dict)
            }
            
            requestsLeft -= 1
            
            guard requestsLeft >= 0 else {
                guard let callback = self.bodyCallback, let body = try callback(request) else {
                    let json = ["status":"429","message":"访问太频繁，请稍后再试"]
                    return try json.encode(for: request)
                }
                return try body.encode(for: request)
            }
            
            return try next.respond(to: request)
        })
    }
    
    
}

fileprivate struct Keys {
    static let createdAt = "createdAt"
    static let requestsLeft = "requestsLeft"
}

public struct Rate {
    public enum Interval {
        case second
        case munite
        case hour
        case day
    }
    
    let limit: Int
    let interval: Interval
    
    init(_ limit: Int, _ interval: Interval) {
        self.limit = limit
        self.interval = interval
    }
    
    internal var refreshInterval: Double {
        switch interval {
        case .second:
            return 1
        case .munite:
            return 60
        case .hour:
            return 3600 // 60 * 60
        case .day:
            return 86400 // 60 * 60 * 24
        }
    }
}
