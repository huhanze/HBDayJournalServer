import FluentMySQL
import Vapor
import Authentication


/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    // Register providers first

    var serverConfigure = NIOServerConfig.default()
    serverConfigure.hostname = "0.0.0.0"
    serverConfigure.port = 80
    services.register(serverConfigure)
    try services.register(FluentMySQLProvider())

    // Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    // Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    // middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)
    
    try services.register(AuthenticationProvider())

    // Configure a SQLite database
    
    let mysql = MySQLDatabase(config: MySQLDatabaseConfig(hostname: "106.12.13.162", port: 3306, username: "root", password: "deitxihc521", database: "day_journal", capabilities: .default, characterSet: .utf8_general_ci, transport: .cleartext))
    
//    let mysql = MySQLDatabase(config: MySQLDatabaseConfig(hostname: "localhost", port: 3306, username: "dylanhu", password: "123456", database: "test", capabilities: .default, characterSet: .utf8_general_ci, transport: .cleartext))

    // Register the configured SQLite database to the database config.
    var databases = DatabasesConfig()
    databases.add(database: mysql, as: .mysql)
    services.register(databases)

    // Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Todo.self, database: .mysql)
    migrations.add(model: User.self, database: .mysql)
    migrations.add(model: AccessToken.self, database: .mysql)
    migrations.add(model: RefreshToken.self, database: .mysql)
    migrations.add(model: UserInfo.self, database: .mysql)
    migrations.add(model: Image.self, database: .mysql)
    services.register(migrations)
}
