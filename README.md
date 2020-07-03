
# reason-guest-login-oidc-client


[![CircleCI](https://circleci.com/gh/yourgithubhandle/reason-guest-login-oidc-client/tree/master.svg?style=svg)](https://circleci.com/gh/yourgithubhandle/reason-guest-login-oidc-client/tree/master)


**Contains the following libraries and executables:**

```
reason-guest-login-oidc-client@0.0.0
│
├─test/
│   name:    TestReasonGuestLoginOidcClient.exe
│   require: reason-guest-login-oidc-client/library
│
├─library/
│   library name: reason-guest-login-oidc-client/library
│   require:
│
└─executable/
    name:    ReasonGuestLoginOidcClientApp.exe
    require: reason-guest-login-oidc-client/library
```

## Developing:

```
npm install -g esy redemon reenv
git clone <this-repo>
esy install
esy build
```

## Running Binary:

After building the project, you can run the main binary that is produced.

```
esy x ReasonGuestLoginOidcClientApp.exe 
```

## Running Tests:

```
# Runs the "test" command in `package.json`.
esy test
```
