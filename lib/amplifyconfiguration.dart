const amplifyconfig = '''{
  "UserAgent": "aws-amplify-cli/2.0",
  "Version": "1.0",
  "auth": {
    "plugins": {
      "awsCognitoAuthPlugin": {
        "UserAgent": "aws-amplify-cli/0.1.0",
        "Version": "0.1.0",
        "IdentityManager": {
          "Default": {}
        },
        "CognitoUserPool": {
          "Default": {
            "PoolId": "us-east-1_8pi6AxLlX",
            "AppClientId": "1sman6rto4tk7thtg5rbt1cv1d",
            "Region": "us-east-1"
          }
        },
        "Auth": {
          "Default": {
            "OAuth": {
              "WebDomain": "https://chope.auth.us-east-1.amazoncognito.com",
              "AppClientId": "1sman6rto4tk7thtg5rbt1cv1d",
              "SignInRedirectURI": "http://localhost:64722",
              "SignOutRedirectURI": "http://localhost:64722/logout",
              "Scopes": ["email", "openid", "profile"]
            }
          }
        }
      }
    }
  }
}''';
