# Testing Guide

## Test Strategy

| Level | Purpose | Coverage Target |
|-------|---------|-----------------|
| Unit | Test individual functions/classes | {%} |
| Integration | Test component interactions | {%} |
| E2E | Test user workflows | Key flows |

## Running Tests

### All Tests

```bash
{test command}
```

### Unit Tests Only

```bash
{unit test command}
```

### Integration Tests Only

```bash
{integration test command}
```

### With Coverage

```bash
{coverage command}
```

## Test Structure

```
tests/
├── unit/                   # Unit tests
│   └── {module}/
├── integration/            # Integration tests
│   └── {feature}/
├── e2e/                    # End-to-end tests
│   └── {workflow}/
├── fixtures/               # Test data
└── helpers/                # Test utilities
```

## Writing Tests

### Unit Test Template

```{language}
{unit test example}
```

### Integration Test Template

```{language}
{integration test example}
```

## Test Data

### Using Fixtures

{Description of how to use test fixtures}

### Mocking

{Description of mocking approach}

## CI/CD Integration

Tests run automatically on:
- Pull request creation
- Push to main branch

See `.github/workflows/` for CI configuration.

## Debugging Tests

### Running Single Test

```bash
{single test command}
```

### Verbose Output

```bash
{verbose test command}
```

### Debug Mode

```bash
{debug test command}
```
