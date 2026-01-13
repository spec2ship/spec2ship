# Security Policy

## About This Project

Spec2Ship is a Claude Code plugin that runs entirely locally within the Claude Code CLI environment. It does not:
- Run server-side code
- Collect or transmit user data
- Store credentials or secrets
- Make external network requests (except through Claude's API)

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |
| < 0.2   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability in Spec2Ship, please report it by:

1. **Opening a GitHub Issue** for non-sensitive issues
2. **Contacting the maintainers directly** for sensitive vulnerabilities

### What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Fix (if applicable)**: Depends on severity

## Security Considerations for Users

Since Spec2Ship executes as a Claude Code plugin:

1. **Review plugin code**: All source code is open and available for inspection
2. **Trust boundary**: The plugin operates within Claude Code's sandbox
3. **Local files**: Plugin reads/writes only to `.s2s/` directory (gitignored by default)
4. **No secrets**: Never store API keys or credentials in `.s2s/` files

## Scope

Security issues we care about:
- Prompt injection vulnerabilities in commands or agents
- Malicious code execution paths
- Unintended file system access outside project scope
- Information disclosure through session files

Out of scope:
- Vulnerabilities in Claude Code itself (report to Anthropic)
- Vulnerabilities in the Claude API (report to Anthropic)
- Social engineering attacks
