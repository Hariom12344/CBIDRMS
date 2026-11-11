# Clean Architecture + MVVM Guidelines

Version: 1.0

Platform: **Flutter (mobile)**. This is the presentation-layer implementation spec referenced from [01-frontend-structure.md](01-frontend-structure.md). For the Next.js/web equivalent, see [CLEAN_ARCHITECTURE_AND_NEXTJS.md](CLEAN_ARCHITECTURE_AND_NEXTJS.md).

---

# Objective

This project follows **Clean Architecture** with **MVVM**.

Clean Architecture organizes the entire application.

MVVM organizes only the Presentation Layer.

Both coexist and complement each other.

---

# Architecture Overview

```
Presentation (MVVM)
        ↓
Domain
        ↓
Data
```

---

# MVVM

MVVM exists only inside the Presentation layer.

```
View
   ↓
ViewModel
```

### View

Responsibilities

- Display UI
- Collect user input
- Display loading/error/success states
- Observe ViewModel

View must NEVER

- Call APIs
- Access Database
- Execute Business Logic
- Parse JSON

---

### ViewModel

Responsibilities

- Hold UI State
- Handle Presentation Logic
- Validate UI Inputs
- Call Use Cases
- Update UI State

Examples

- isLoading
- errorMessage
- selectedTab
- emailController
- passwordController

ViewModel must NEVER

- Call HTTP directly
- Query Database
- Know Firebase
- Parse JSON

---

# Domain Layer

The Domain layer contains business rules.

It has no dependency on Flutter, Firebase, HTTP or Database.

---

## Entity

Entity represents business objects.

Example

```
User
Project
Invoice
PurchaseOrder
```

Entities never contain

- fromJson()
- toJson()
- HTTP
- Database code

---

## Use Case

A Use Case represents one business action.

Examples

```
LoginUser

RegisterUser

CreateProject

ApproveInvoice

GenerateBOQ

AssignWorker
```

Responsibilities

- Execute Business Rules
- Coordinate repositories
- Return Entities

Use Cases must NEVER

- Parse JSON
- Know HTTP
- Know Firebase

---

## Repository (Contract)

Repository is a Contract.

It defines WHAT operations are available.

Example

```dart
abstract class AuthRepository {

 Future<UserEntity> login(...);

 Future<void> logout();

}
```

Repository never contains implementation.

Think

"What can be done?"

NOT

"How it is done."

---

# Data Layer

Contains implementation.

---

## Repository Implementation

Implements Repository Contract.

Responsibilities

- Fulfill Repository Contract
- Convert Model → Entity
- Call Data Sources

Think

"How is the contract fulfilled?"

---

## Remote Data Source

Responsible for

- REST API
- Firebase
- GraphQL
- Supabase
- External Services

Responsibilities

- HTTP Requests
- Firebase Calls
- Parse API Response
- Return Models

Must NEVER contain Business Logic.

---

## Local Data Source

Responsible for

- SQLite
- Hive
- SharedPreferences
- Secure Storage

---

## Models

Models represent external data.

Examples

```
UserModel

InvoiceModel

ProjectModel
```

Responsibilities

- fromJson()
- toJson()
- API Mapping
- Database Mapping

Models are NOT Business Objects.

---

# Complete Request Flow

```
User

↓

View

↓

ViewModel

↓

UseCase

↓

Repository (Contract)

↓

Repository Implementation

↓

Remote Data Source

↓

REST API / Firebase
```

---

# Complete Response Flow

```
REST API / Firebase

↓

Remote Data Source

↓

UserModel

↓

Repository Implementation

↓

UserEntity

↓

UseCase

↓

ViewModel

↓

View

↓

User
```

---

# Responsibilities Summary

| Layer | Responsibility |
|---------|----------------|
| View | UI Only |
| ViewModel | Presentation Logic + UI State |
| UseCase | Business Logic |
| Repository | Contract |
| Repository Implementation | Contract Implementation |
| Remote Data Source | API/Firebase |
| Local Data Source | Local Storage |
| Model | External Data Mapping |
| Entity | Business Object |

---

# Dependency Rule

Always

```
Presentation

↓

Domain

↓

Data
```

Never the opposite.

Data must never know Presentation.

Domain must never know Flutter.

Presentation must never know Database.

---

# Feature Folder Structure

```
features/

auth/

    presentation/

        pages/

        widgets/

        viewmodels/

    domain/

        entities/

        repositories/

        usecases/

    data/

        models/

        repositories/

        datasources/

            remote/

            local/
```

Every feature must follow this structure.

---

# Naming Convention

View

```
login_page.dart
```

ViewModel

```
login_viewmodel.dart
```

Use Case

```
login_usecase.dart

register_usecase.dart

forgot_password_usecase.dart
```

Repository

```
auth_repository.dart
```

Repository Implementation

```
auth_repository_impl.dart
```

Remote Data Source

```
auth_remote_datasource.dart
```

Model

```
user_model.dart
```

Entity

```
user.dart
```

---

# Important Rules

✅ View never calls Repository.

✅ View talks only to ViewModel.

✅ ViewModel talks only to UseCases.

✅ UseCase talks only to Repository.

✅ Repository is only a Contract.

✅ Repository Implementation fulfills the Contract.

✅ Repository Implementation talks to Data Sources.

✅ Data Sources communicate with external systems.

✅ Models belong only to Data Layer.

✅ Entities belong only to Domain Layer.

---

# Mental Model

View
→ "Show the screen."

ViewModel
→ "Manage the screen."

UseCase
→ "Perform the business action."

Repository
→ "These operations are available."

Repository Implementation
→ "This is how those operations work."

Remote Data Source
→ "Talk to the server."

Model
→ "Represent external data."

Entity
→ "Represent business data."

---

# Golden Rule

MVVM exists INSIDE the Presentation Layer.

Clean Architecture organizes the entire application.

```
Presentation (MVVM)

    View

    ViewModel

↓

Domain

    UseCases

    Entities

    Repository Contracts

↓

Data

    Repository Implementations

    Remote Data Sources

    Local Data Sources

    Models
```

This separation must be preserved throughout the project.
