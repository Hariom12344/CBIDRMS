# API Payload Design

TES follows predictable JSON response structures.

## Success Response

```json
{
  "success": true,
  "message": "Operation successful",
  "data": {},
  "error": null
}
```

## Error Response

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

Benefits:

* frontend consistency
* easier debugging
* reusable API handling
* AI-friendly responses

---

# Validation System

TES plans to use schema-based validation systems.

Validation happens before business logic execution.

Current planned validation system:

* Zod

Benefits:

* secure APIs
* predictable data structures
* easier debugging
* reusable validation patterns
