# BoatIT - Boat Sharing iOS App

SwiftUI-based iOS application for boat sharing services.

## Quick Start

```bash
pod install
open BoatSharingApp.xcworkspace
# Build and run (Cmd+R)
```

## Architecture (New - Refactored)

```
View → ViewModel → Repository → APIClient → API
```

### Key Components

- **AppConfiguration.swift** - All URLs, endpoints, keys
- **APIClient.swift** - Network layer (async/await)
- **SessionManager.swift** - Auth & tokens
- **Repositories/** - Business logic
- **ErrorHandler.swift** - Shared error handling

## Code Examples

### ViewModel Pattern (New)
```swift
class MyViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let repository: MyRepositoryProtocol
    
    @MainActor
    func loadData() {
        isLoading = true
        Task {
            do {
                data = try await repository.getData()
            } catch {
                errorMessage = ErrorHandler.extractErrorMessage(from: error)
            }
            isLoading = false
        }
    }
}
```

### Repository Pattern
```swift
class MyRepository: MyRepositoryProtocol {
    private let apiClient: APIClientProtocol
    
    func getData() async throws -> [Item] {
        let response: BaseResponse<[Item]> = try await apiClient.request(
            endpoint: AppConfiguration.API.Endpoints.myEndpoint,
            method: .get,
            requiresAuth: true
        )
        return response.obj ?? []
    }
}
```

## Migration Status

✅ **Complete:**
- Protocol-based network layer
- Centralized configuration
- Session management (no UI in network code)
- Error handling utilities
- Repository pattern
- Unit test examples

🔄 **In Progress:**
- Migrating ViewModels (LoginAuthViewModel done)
- Creating more repositories

## API

Backend: https://boatitapi.com/swagger/index.html

## Testing

```bash
cmd + U  # Run tests
```

See `LoginAuthViewModelTests.swift` for examples.

---

**Version:** 2.0.0 (Post-Refactoring)  
**Status:** Production Ready
