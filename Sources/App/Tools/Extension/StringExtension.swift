//
//  StringExtension.swift
//  App
//
//  Created by DylanHu on 2020/5/7.
//

import Foundation
import Vapor
import Crypto


extension String {
    
    func hash(_ req: Request) throws -> String {
        return try req.make(BCryptDigest.self).hash(self)
    }
    
    func isValidateAccount() -> (Bool, String) {
        if count == 0 {
            return (false, "账号不能为空")
        }
        
        if count > 20 {
            return (false, "账号超过最大长度")
        }
        return (true, "账号有效")
    }
    
    func isValidatePassword() -> (Bool, String) {
        if count < 8 {
            return (false, "密码长度不能低于8位")
        }
        
        return (true, "密码有效")
    }
}
