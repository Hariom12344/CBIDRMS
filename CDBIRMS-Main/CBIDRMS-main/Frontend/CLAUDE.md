# Frontend Instructions

This repo uses the Engineering System Claude Code plugin.

For code or file changes, follow the ES request workflow first, then apply the matching frontend skills:
- request-workflow
- frontend-architecture
- feature-contract
- validation
- testing-strategy
- seo-metadata for Next.js pages only

Frontend structure should stay feature-based:
- Flutter: presentation/, domain/, data/
- Next.js: components/, hooks/, model/, api/

Keep UI files thin, put business logic in the right layer, and build features as complete vertical slices.