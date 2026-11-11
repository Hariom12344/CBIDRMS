---
name: validation
description: ES validation convention — Zod schema-based validation at system boundaries, run before business logic executes. Use when adding input validation for API routes, forms, or any external data entry point.
---

# ES Validation System

Schema-based validation, using **Zod**.

## Rule

Validation happens **before** business logic execution — a route handler's `logic/` code should be able to assume its input is already well-formed by the time it runs. The `contract/` folder (see `backend-architecture`) is where these schemas live, alongside the DTOs they validate into.

## Where to validate

Only at system boundaries: user input, form submissions, external API responses, query params, request bodies. Don't add redundant validation for data that's already been through a boundary check and is just flowing between internal functions — trust internal code and framework guarantees past that point.

## Why Zod specifically

Secure APIs, predictable data structures, easier debugging, reusable validation patterns — and TypeScript types can be inferred directly from the schema, so the schema is the single source of truth for both runtime validation and compile-time types.
