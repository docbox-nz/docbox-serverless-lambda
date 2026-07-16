exports.handler = async (event) => {
    // TODO: Real authentication logic
    // const methodArn = event.methodArn;

    return {
        principalId: "user-session-id",
        policyDocument: {
            Version: "2012-10-17",
            Statement: [
                {
                    Action: "execute-api:Invoke",
                    Effect: "Allow",
                    Resource: "*",
                },
            ],
        },
        context: {
            tenant: JSON.stringify({
                id: "0fa523d6-bbc7-4537-95d6-fe3d23c5eebd",
                env: "Production",
            }),
            user: JSON.stringify({
                id: "8c7c42b8-f18d-4ab1-a1db-c65247ad5704",
                name: "Test User",
                image_id: "xxxx",
            }),
        },
    };
};
