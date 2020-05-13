//
//  ConfigureManager.swift
//  App
//
//  Created by DylanHu on 2020/5/13.
//

import Foundation
import Vapor
import FluentMySQL
import Authentication

public class ConfigureManager {
    
    
    public static func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
        
        // =========================== NIOServerConfig ===========================
        var serverConfigure = NIOServerConfig.default()
        serverConfigure.hostname = "0.0.0.0"
        serverConfigure.port = 80
        services.register(serverConfigure)
        
        // =========================== CommandConfig ===========================
        var commands = CommandConfig.default()
        commands.useFluentCommands()
        services.register(commands)
        
        // =========================== AuthenticationProvider ===========================
        try services.register(AuthenticationProvider())

        // ===========================   Rotuer  ===========================
        let router = EngineRouter.default()
        try routes(router)
        services.register(router, as: Router.self)

        // =========================== Middleware ===========================
        MiddlewareManager.register(&services)
        
        // ===========================    MySQL   ===========================
        try services.register(FluentMySQLProvider())
        DatabaseConfigManager.configure(&env, &services)
        
        // ===========================    Models  ============================
        MigrationsManager.register(&services)
    }

}

class DatabaseConfigManager {
    
    struct MySQLConfig {
        let host: String = "106.12.13.162" // "localhost"
        let port: Int = 3306
        let userName: String = "root"  // dylanhu
        let password: String = "deitxihc521"  // 123456
        let database: String = "day_journal"  // test
        
//        let host: String = "localhost" // "localhost"
//        let port: Int = 3306
//        let userName: String = "dylanhu"  // dylanhu
//        let password: String = "123456"  // 123456
//        let database: String = "test"  // test
    }
    
    
    
    private static let mySqlConf = MySQLConfig()
        
    static func configure(_ env: inout Environment, _ services: inout Services) {
        let mysql = MySQLDatabase(config: MySQLDatabaseConfig(hostname: mySqlConf.host, port: mySqlConf.port, username: mySqlConf.userName, password: mySqlConf.password, database: mySqlConf.database, capabilities: .default, characterSet: .utf8_general_ci, transport: .cleartext))
        
        var databases = DatabasesConfig()
        databases.add(database: mysql, as: .mysql)
        services.register(databases)
    }
}

public class MigrationsManager {
    
    static func register(_ services: inout Services) {
        var migrations = MigrationConfig()
        migrations.add(model: Todo.self, database: .mysql)
        migrations.add(model: User.self, database: .mysql)
        migrations.add(model: AccessToken.self, database: .mysql)
        migrations.add(model: RefreshToken.self, database: .mysql)
        migrations.add(model: UserInfo.self, database: .mysql)
        migrations.add(model: Image.self, database: .mysql)
        services.register(migrations)
    }
}

public class MiddlewareManager {
    
    static func register(_ services: inout Services) {
        // Register middleware
        var middlewares = MiddlewareConfig() // Create _empty_ middleware config
        middlewares.use(ExceptionRequestMiddleware(callback: { request in
            return try ["status":"404", "message" : "访问路径不存在"].encode(for: request)
        }))
        // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
        middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
        middlewares.use(RequestControlMiddleware(Rate(30, .munite), MemoryKeyedCache()))
        services.register(middlewares)
    }
}
