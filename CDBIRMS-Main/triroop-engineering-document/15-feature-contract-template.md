# Feature Contract — Template & Guide

## What is a Feature Contract?

A **Feature Contract** is the single source of truth for one feature. Before any backend or frontend work starts, the contract answers every question a backend developer, frontend developer, QA tester, and future maintainer might ask about that feature — what it does, who can use it, what the API looks like, what can go wrong, and how we'll know it's done.

It replaces the usual pattern of scattered Slack threads, half-written tickets, and tribal knowledge with one document per feature that:

- Lets backend and frontend build against the same contract in parallel, without waiting on each other to clarify fields or error codes.
- Gives QA a ready-made list of test cases and edge cases instead of having to reverse-engineer them from the UI.
- Gives a future maintainer (including future-you) the "why" behind a feature, not just the "what" the code already shows.
- Forces validation rules, business rules, error codes, and permissions to be decided *before* implementation, not discovered during it.

One contract = one feature. Don't bundle multiple features into a single contract, and don't split one feature across multiple contracts.

This ties directly into TES's [vertical slice development](03-vertical-slice-development.md) model — the contract is what a slice is built against, end to end.

### Where it lives

Each project keeps its feature contracts under `docs/feature-contracts/<FEAT-ID>-<kebab-feature-name>.md` (e.g. `docs/feature-contracts/FEAT-001-create-project.md`). If a project already has its own contract-doc convention, match that instead of introducing a new folder.

### When to write one

Write a Feature Contract before starting any feature that touches an API, a database change, or more than one role/permission level. Trivial UI-only tweaks don't need one.

### Which version to use

| Version | Use when |
| --- | --- |
| Full (23 sections) | The feature has non-trivial business rules, multiple roles, or will be built by more than one person |
| Lean (13 sections) | Early-stage team, intern-led work, or a small self-contained feature |

Start lean if you're unsure — it's easy to extend a lean contract into a full one as complexity emerges, but don't retrofit process onto something already shipped.

---

## Full Template (23 Sections)

### 1. Feature Information

```
Feature ID
FEAT-001

Feature Name
Create Project

Module
Project Management

Priority
High

Status
In Development

Owner
Saurabh

Assigned To
Backend: Rahul
Frontend: Saurabh

Estimated Time
6 Hours
```

---

### 2. Business Objective

Why are we building this?

Example

> Allow the admin to create a new project so that all project-related work can be managed from a single place.

---

### 3. User Story

```
As an Admin

I want to create a new project

So that I can track work, expenses, and progress.
```

---

### 4. Actors

Who can use it?

```
Admin

Project Manager

Sales Executive

Client

Vendor
```

Example

```
Only Admin
```

---

### 5. Entry Point

Where does this feature start?

```
Dashboard

↓

Projects

↓

New Project Button
```

---

### 6. UI Reference

Include:

- Screenshot
- Figma Link
- Wireframe

Mark important buttons.

```
Save

↓

Calls API
```

---

### 7. User Flow

This is one of the most important sections.

```
Open Project Page

↓

Click New Project

↓

Fill Form

↓

Click Save

↓

Validation

↓

API Called

↓

Database Updated

↓

Success Message

↓

Redirect
```

---

### 8. Fields

| Field | Type | Required | Validation |
| --- | --- | --- | --- |
| Project Name | Text | Yes | Max 100 chars |
| Client | Dropdown | Yes | Must exist |
| Budget | Number | No | >=0 |
| Start Date | Date | Yes | Cannot be past |
| End Date | Date | No | >= Start Date |

---

### 9. Validation Rules

Don't just say "required."

Example

```
Project Name

Cannot be empty

Unique

Maximum 100 characters

Trim spaces
```

```
Budget

Positive number

Maximum 1 Crore
```

Follow TES's [Zod-based validation convention](08-api-payloads-and-validation.md) when turning these rules into schema code.

---

### 10. Business Rules

Different from validation.

Example

```
Project Status

New projects always start as Draft.
```

```
Project ID

Auto Generated

PRJ-000001
```

```
Client

Must already exist.
```

---

### 11. API Contracts

Every API.

Example

---

#### Create Project

```
POST

/api/v1/projects
```

Purpose

Create Project

Authentication

JWT Required

Headers

```
Authorization

Bearer Token
```

Request

```json
{
  "name": "Hotel Taj",
  "clientId": "CL001",
  "budget": 1200000
}
```

Success

```json
{
  "success": true,
  "data": {
      ...
  }
}
```

Failure

```json
{
  "success": false,
  "error": {
      "code": "PROJECT_EXISTS",
      "message": "Project already exists."
  }
}
```

Follow TES's [API architecture](06-api-architecture.md) conventions (versioning, resource-based routing, standard methods) and the [success/error envelope](08-api-payloads-and-validation.md) when writing this section.

---

### 12. Backend Processing Flow

Instead of just APIs, explain the logic.

```
Receive Request

↓

Authenticate User

↓

Validate Data

↓

Check Duplicate

↓

Generate Project ID

↓

Insert Database

↓

Log Activity

↓

Return Response
```

See TES's [backend structure](02-backend-structure.md) for where each of these steps lives in the `api/ logic/ contract/ data/` layout.

---

### 13. Database Impact

Exactly what changes.

```
Tables

Projects

ProjectLogs

Activities
```

Fields created.

Indexes.

Foreign Keys.

Transactions.

See TES's [database and ORM](09-database-and-orm.md) doc for schema and Prisma conventions.

---

### 14. Permissions

```
Admin

Create

Update

Delete

✓
```

```
Manager

Read

Update

✗ Delete
```

Follow TES's [middleware and authentication](07-middleware-and-authentication.md) conventions for enforcing this matrix.

---

### 15. Error Codes

```
PROJECT_EXISTS

CLIENT_NOT_FOUND

UNAUTHORIZED

INVALID_DATE

DATABASE_ERROR
```

Never use random messages. Always define codes.

---

### 16. Frontend Behaviour

If backend returns

```
PROJECT_EXISTS
```

Frontend should

```
Show toast

Project already exists.
```

If success

```
Redirect

/project/123
```

---

### 17. Loading Behaviour

```
Disable Save Button

↓

Show Spinner

↓

Enable Button Again
```

---

### 18. Notifications

```
Email

No
```

```
WhatsApp

No
```

```
Push Notification

Yes
```

---

### 19. Audit Logs

```
Who

Created Project

When

Time

Old Value

New Value

IP

Browser
```

---

### 20. Test Cases

Happy Path

```
Create valid project

Success
```

Validation

```
Empty name

Error
```

```
Duplicate name

Error
```

Permission

```
Sales user

Cannot create
```

Edge Cases

```
100-character name

Works
```

```
101-character name

Fails
```

See TES's [testing philosophy](11-testing-philosophy.md) for how these map to unit vs. integration tests.

---

### 21. Dependencies

```
Requires Client Module

Requires Authentication

Requires Company Settings
```

---

### 22. Definition of Done

This prevents ambiguity.

```
✓ Backend completed

✓ Frontend integrated

✓ Tested

✓ Swagger updated

✓ Postman updated

✓ Logging added

✓ Error handling completed

✓ Review approved

✓ Merged
```

---

### 23. Future Improvements

Don't mix future ideas into the current implementation.

Example

```
Bulk Create

Project Templates

Import from Excel

Clone Project
```

---

## Lean Template (For Interns / Early-Stage Teams)

For early-stage teams, 23 sections may be overkill. A lean version captures nearly all the information needed without overwhelming a new contributor. Extend into the full format as the team and feature complexity grow.

| Section | Why it matters |
| --- | --- |
| Feature Summary | What are we building? |
| User Story | Who needs it and why? |
| UI Screenshot | What does the user see? |
| User Flow | How does the feature work? |
| Fields & Validation | What data is entered? |
| Business Rules | What logic must be enforced? |
| API Contract | How do frontend and backend communicate? |
| Backend Flow | What should happen internally? |
| Database Changes | What data is stored or updated? |
| Permissions | Who can access it? |
| Error Codes | What failures are expected? |
| Acceptance Criteria | When is the feature considered complete? |
| Test Cases | How do we verify it works? |
