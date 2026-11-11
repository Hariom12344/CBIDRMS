# Database and ORM Philosophy

Database decisions in TES are based on:

* maintainability
* scalability
* development speed
* predictable engineering
* AI-assisted workflows
* long-term flexibility

TES currently plans to use:

## Database

* PostgreSQL

## Database Platform

* Supabase

## ORM

* Prisma ORM

## Validation

* Zod

## Architecture

* Modular Monolith

## API Style

* REST APIs

---

# Why PostgreSQL Fits TES

TES now focuses on:

* structured business systems
* scalable relational data
* predictable schemas
* maintainable relationships
* long-term data consistency

PostgreSQL supports:

* relational consistency
* structured data modeling
* reliable querying
* scalable production systems
* strong reporting capabilities

This makes PostgreSQL a strong long-term choice for TES.

---

# Why Supabase Is Planned

TES currently plans to use Supabase because it provides:

* managed PostgreSQL infrastructure
* faster backend setup
* authentication support
* scalable cloud infrastructure
* easier developer experience

This helps TES reduce infrastructure complexity during development.

---

# Why Prisma ORM Is Planned

TES currently plans to use Prisma ORM because it provides:

* type-safe database queries
* predictable schema management
* clean database access patterns
* easier onboarding
* better maintainability
* AI-friendly query generation

TES currently prioritizes:

> Predictable engineering and maintainable development workflows.

---

# Database Engineering Principles

TES follows these important database principles.

---

## Separate Database Models from API Contracts

Raw database records should never be directly exposed to frontend systems.

Instead, TES uses:

* DTO mapping
* response contracts
* structured API payloads

This is one major purpose of the:

```txt
contract/
```

folder.

---

## Avoid Premature Optimization

TES does not currently optimize for:

* massive distributed systems
* highly complex infrastructure
* premature microservices architecture

Current focus:

* maintainability
* predictable development
* rapid iteration
* clean architecture

---

## Standardization Is Critical

TES plans to standardize:

* schema naming
* validation structure
* DTO patterns
* database conventions
* query patterns
* migration workflows

This improves:

* onboarding speed
* project consistency
* debugging quality
* AI predictability
