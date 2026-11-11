# Backend Instructions

This repo uses the Engineering System Claude Code plugin.

For code or file changes, follow the ES request workflow first, then apply the matching backend skills:
- request-workflow
- backend-architecture
- api-design
- auth-infrastructure
- validation
- database-orm
- testing-strategy

Backend structure should stay feature-based:
- api/ for thin route/controller entry points
- logic/ for business rules
- contract/ for DTOs and schemas
- data/ for repository and persistence access

Keep validation at the boundary, keep routes thin, and prefer vertical-slice changes over broad refactors.