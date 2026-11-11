# API Structure and Infrastructure

TES follows a clean, scalable, and standardized API architecture designed for:

* maintainability
* AI-assisted development
* predictable engineering workflows
* reusable backend systems

The API architecture follows modern engineering practices inspired by companies like Microsoft, Google, and Stripe.

Main goals of the TES API system:

* predictable development flow
* reusable backend structure
* easier frontend integration
* clean knowledge transfer
* scalable architecture
* AI-friendly code generation

---

# API Versioning Structure

TES uses version-based API routing.

Example:

```txt
/api/v1/
```

Sample APIs:

```txt
/api/v1/auth/login
/api/v1/projects
/api/v1/vendors
/api/v1/invoices
```

Benefits:

* backward compatibility
* safer future updates
* support for multiple app versions
* reduced breaking changes

---

# Resource-Based API Design

TES follows resource-oriented REST API design.

APIs are designed around business resources.

Correct examples:

```txt
/projects
/vendors
/invoices
/users
```

Avoided patterns:

```txt
/createProject
/getVendorData
/deleteInvoice
```

Benefits:

* cleaner APIs
* predictable routing
* better scalability
* easier frontend understanding

---

# Standard API Methods

TES follows standard HTTP methods.

| Method | Purpose             |
| ------ | ------------------- |
| GET    | Read data           |
| POST   | Create data         |
| PATCH  | Update partial data |
| PUT    | Replace full data   |
| DELETE | Remove data         |

Example:

```txt
GET    /api/v1/projects
POST   /api/v1/projects
PATCH  /api/v1/projects/:projectId
DELETE /api/v1/projects/:projectId
```
