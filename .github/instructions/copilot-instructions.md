# FitWithFriends - GitHub Copilot Instructions

## Project Overview
FitWithFriends is a fitness competition app with an iOS client (SwiftUI) and Node.js/TypeScript backend. Users authenticate via Apple Sign-In and create group fitness competitions using HealthKit data.

## Architecture Patterns

### Backend (Node.js/Express/TypeScript)
- **Type-safe SQL**: Uses `@pgtyped` to generate TypeScript interfaces from SQL files. Regenerate with: `node pgtyped_cli/lib/index.js -c pgtypedconfig.json` (needs a running database matching the schema)
- **User ID Format**: Database stores user IDs as hex `bytea`. Convert with `convertUserIdToBuffer()` and `convertBufferToUserId()` in `utilities/userHelpers.ts`
- **OAuth Flow**: Custom Apple ID token grant in `oauth/AppleIdTokenGrant.ts`. Validates Apple tokens and creates users if needed
- **Error Handling**: Use `FWFErrorCodes` enum for custom error codes. Route-specific error handlers can catch by `err.customErrorCode`

### iOS Client (SwiftUI)
- **Dependency Injection**: `ObjectGraph` implements `IObjectGraph` for production, `MockObjectGraph` for previews/tests
- **Authentication Flow**: `AppleAuthenticationManager` → `AuthenticationManager` → UI via delegates and notifications
- **MVVM Pattern**: ViewModels are `@ObservableObject` classes, Views observe via `@ObservedObject`
- **Name Input Flow**: When user doesn't exist, shows `UserNameInputView` sheet via `NotificationCenter` pattern

## Key Workflows

### User Registration
1. Apple Sign-In provides name on first use only (`appleIdCredential.fullName`)
2. If user exists: authenticate with stored ID
3. If user doesn't exist: prompt for name via `UserNameInputView` → create user → retry authentication

### Competition Flow
- Competitions use UUID IDs, stored as strings in database
- Member relationships in `users_competitions` table with final points
- Real-time standings calculated via `competitionStandingsHelper.ts`

### Health Data Sync
- iOS: `HealthKitManager` observes activity summaries, uploads daily
- Backend: Bulk insert via `routes/activityData.ts`, validates ring completion goals

## Development Commands

### Backend
```bash
cd WebService/FitWithFriends
npm run build    # TypeScript compilation
npm test         # Jest tests (TZ=America/New_York); needs the docker-compose stack running, see Environment Setup
npm start        # Run compiled app
```

### iOS
- Open `Clients/iOS/FitWithFriends/FitWithFriends.xcworkspace` in Xcode
- Uses CocoaLumberjack for logging, HealthKit for data, Keychain for secure storage

## Running Tests
To run the tests for the `FitWithFriends` project, use the following command:

```fish
xcodebuild -workspace FitWithFriends.xcworkspace -scheme FitWithFriends -sdk iphonesimulator -destination 'platform=iOS Simulator,id=24F417EA-AE27-47CB-B70D-6DF943F5760E' test
```

This command ensures that the tests are executed on the specified iOS Simulator.

## Common Patterns
- **Error Responses**: Use `handleError()` helper with custom FWF error codes
- **Date Handling**: All times in UTC, client converts to user timezone
- **Background Tasks**: iOS schedules health data sync, backend processes competition results
- **Testing**: Mock all services in iOS previews, use `TestSQL` utilities for backend integration tests

## Environment Setup
- **Local Development**: Use `docker-compose-local-testing.yml` with PostgreSQL 17
- **Local test stack**: `docker compose -f WebService/docker-compose-local-testing.yml up -d --build` starts Postgres 17 and the app on port 3000, which the integration tests call
- **Azure Deployment**: Azure Web App deployed by `.github/workflows/web-service-deploy.yml` on push to main. Node 24 (`.nvmrc`). `Web.config` is still in the deploy package; the hosting OS is not recorded in the repo
- **Apple Authentication**: Requires Apple Developer account, configured JWKS endpoint for token validation
