import ballerina/http;
import ballerina/sql;
import ballerinax/postgresql;
import ballerina/os;
import ballerina/log;

listener http:Listener httpListener = new(9090);

// Define CORS configuration
http:CorsConfig corsConfig = {
    allowOrigins: ["*"], // Allow all origins
    allowCredentials: true, // Allow credentials
    allowHeaders: ["*"], // Allow all headers
    exposeHeaders: ["*"], // Expose all headers
    allowMethods: ["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"] // Allow these methods
};

@http:ServiceConfig {
    cors: corsConfig
}

service /userAPI on httpListener {

    resource function post addUser(@http:Payload User user) returns json|error {
        postgresql:Client dbClient = check createDbClient();
        sql:ParameterizedQuery query = `INSERT INTO users (username,email) VALUES (${user.username}, ${user.email}) `;
        var result = dbClient->execute(query);
        check closeDbClient(dbClient);
        if (result is sql:ExecutionResult) {
            return {message: "User added successfully"};
        } else if (result is error) {
            log:printError("Failed to add user", 'error = result);
            return error("Failed to add user", result);
        }
    }
}

// Utility function to create a new database client
function createDbClient() returns postgresql:Client|error {
    string dbHost =   os:getEnv("DB_HOST");
    string dbUsername =   os:getEnv("DB_USERNAME");
    string dbPassword =   os:getEnv("DB_PASSWORD");
    string dbName =   os:getEnv("DB_NAME");
    return new postgresql:Client(dbHost, dbUsername, dbPassword, dbName, 25059);
}

// Utility function to close the database client
function closeDbClient(postgresql:Client dbClient) returns error? {
    return dbClient.close();
}

type User record{
    string username;
    string email;
};