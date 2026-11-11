---
name: api-design
description: ES API design conventions — versioned, resource-based REST routes, standard HTTP methods, and a consistent JSON success/error envelope. Use when adding, changing, or reviewing HTTP API endpoints.
---

# ES API Structure

Resource-oriented, versioned REST design, inspired by API practices at companies like Microsoft, Google, and Stripe.

## Versioning

All APIs are versioned:

```
/api/v1/
```

```
/api/v1/auth/login
/api/v1/projects
/api/v1/vendors
/api/v1/invoices
```

Benefits: backward compatibility, safer future updates, support for multiple app versions, reduced breaking changes.

## Resource-based, not RPC-style

Design around business resources (nouns), not actions (verbs).

Correct:
```
/projects
/vendors
/invoices
/users
```

Avoid:
```
/createProject
/getVendorData
/deleteInvoice
```

## Standard HTTP methods

| Method | Purpose |
|---|---|
| GET | Read data |
| POST | Create data |
| PATCH | Update partial data |
| PUT | Replace full data |
| DELETE | Remove data |

```
GET    /api/v1/projects
POST   /api/v1/projects
PATCH  /api/v1/projects/:projectId
DELETE /api/v1/projects/:projectId
```

## Response envelope

Success:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": {},
  "error": null
}
```

Error:
```json
{
  "success": false,
  "message": "Unauthorized",
  "data": null,
  "error": {
    "code": "AUTH_REQUIRED"
  }
}
```

Every endpoint response — success or error — follows this shape. This is what makes frontend error handling and AI-generated client code predictable across the whole API surface.
