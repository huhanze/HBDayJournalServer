

import Vapor

/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    
    try ConfigureManager.configure(&config, &env, &services)
}
