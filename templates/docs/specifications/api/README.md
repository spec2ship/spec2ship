# API Specifications

This directory contains API specifications in OpenAPI format.

## API Inventory

| API | Version | Status | OpenAPI File |
|-----|---------|--------|--------------|
| | | | |

## Versioning Policy

<!--
Document your API versioning strategy here.
-->

- Major versions: Breaking changes
- Minor versions: New features, backwards compatible
- Patch versions: Bug fixes

## API Standards

### Naming Conventions

- Endpoints: lowercase, hyphenated (e.g., `/user-profiles`)
- Query params: camelCase (e.g., `?pageSize=10`)
- Request/response bodies: camelCase

### Response Format

```json
{
  "data": {},
  "meta": {
    "requestId": "string",
    "timestamp": "ISO8601"
  }
}
```

### Error Format

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": {}
  }
}
```

### Status Codes

| Code | Usage |
|------|-------|
| 200 | Successful GET, PUT, PATCH |
| 201 | Successful POST (created) |
| 204 | Successful DELETE |
| 400 | Bad request / validation error |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not found |
| 409 | Conflict |
| 500 | Server error |

## Adding New APIs

1. Create OpenAPI spec file: `{api-name}.yaml`
2. Add entry to inventory table above
3. Ensure spec passes validation
4. Update related architecture docs if needed
