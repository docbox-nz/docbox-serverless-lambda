exports.handler = async (event) => {
    const token = event.headers?.Authorization || event.headers?.authorization;
    const path = event.path;
    const method = event.httpMethod;

    const isAuthorized = validateUserAccess({
        token,
        path,
        method,
    });
    if (!isAuthorized) {
        return generatePolicy("user-session-id", "Deny", event.methodArn);
    }

    return generatePolicy("user-session-id", "Allow", event.methodArn, {
        tenant: JSON.stringify({
            id: "0fa523d6-bbc7-4537-95d6-fe3d23c5eebd",
            env: "Production",
        }),
        user: JSON.stringify({
            id: "8c7c42b8-f18d-4ab1-a1db-c65247ad5704",
            name: "Test User",
        }),
    });
};

function validateUserAccess(data) {
    const { token, path, method } = data;
    // TODO: Real authentication logic
    return true;
}

function generatePolicy(principalId, effect, resource, context = {}) {
    return {
        principalId,
        policyDocument: {
            Version: "2012-10-17",
            Statement: [
                {
                    Action: "execute-api:Invoke",
                    Effect: effect,
                    Resource: resource || "*",
                },
            ],
        },
        context,
    };
}
