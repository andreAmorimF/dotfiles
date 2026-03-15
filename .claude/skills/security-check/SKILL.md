# Security Check Skill

## Overview

This skill provides security vulnerability detection capabilities based on known vulnerability patterns identified in paymabills team repositories.

## What This Skill Does

Validates code against 4 critical security vulnerability categories:

### Q1-CRITICAL: Sensitive Data in Logs
- **Risk**: Exposure of PII (CPF, email), credentials (tokens, passwords), financial data
- **CWE**: CWE-359, CWE-532
- **Compliance**: LGPD, PCI-DSS violations
- **Detection**: Identifies logging of complete objects/maps instead of explicit field selection

### Q2-IMPORTANT: Insecure Open Scopes
- **Risk**: Broken access control, privilege escalation
- **CWE**: CWE-863
- **OWASP**: A01:2021 (Broken Access Control)
- **Detection**: Identifies use of `auth/admin` or `auth/trusted` instead of service-specific scopes

### Q3-QUICK-WINS: Improper Externalization
- **Risk**: Exposure of internal fields, lack of API contracts
- **CWE**: CWE-213
- **OWASP**: A04:2021 (Insecure Design)
- **Detection**: Missing `externalize!` interceptor or use of `schema/Any`

### Q4-SECRETS: Hardcoded Secrets & Unencrypted Kafka
- **Risk**: Credential exposure, data interception
- **CWE**: CWE-798, CWE-319
- **OWASP**: A07:2021 (Authentication Failures)
- **Detection**: Hardcoded credentials, Kafka without SSL/TLS

## When to Use This Skill

- **Pre-commit**: Validate working changes for security issues
- **Pre-PR**: Validate entire branch before opening pull request
- **Security review**: Quick security assessment of code changes
- **Compliance check**: Verify LGPD/PCI-DSS compliance

## Related Commands

- `/security-check` - Main command for automated security validation
- `/code-check` - General code quality validation
- `/pr-review` - Comprehensive PR review including security

## Knowledge Base

This skill is based on comprehensive security analysis of real-world vulnerability patterns in production payment systems, covering the most common security issues found in microservices architectures.

## Examples

See the `examples/` directory for:
- `critical-sensitive-logs.md` - Q1 vulnerability examples
- `important-open-scopes.md` - Q2 vulnerability examples
- `quick-wins-externalize.md` - Q3 vulnerability examples
- `secrets-hardcoded.md` - Q4 vulnerability examples

## Integration

This skill integrates with:
- Git workflow (hooks, aliases)
- CI/CD pipelines
- IDE integration (pre-save validation)
- Code review process

## Performance

- **Speed**: 3-8 seconds for typical branch
- **Accuracy**: Based on real-world vulnerability patterns from production systems
- **False positives**: Minimal on Q1-Q3, requires manual verification on Q4

## Severity Levels

Following `@../conventions/severity.md`:

- **MUST**: Security vulnerabilities that expose sensitive data or violate compliance (block commit)
- **SHOULD**: Security issues that weaken security posture (fix before PR)
- **COULD**: Security improvements for better practices (consider)

## References

### Internal Documentation
- Q1-CRITICO-SENSITIVE-DATA-IN-LOGS.md
- Q2-IMPORTANTE-INSECURE-OPEN-SCOPES.md
- Q3-QUICK-WINS-IMPROPER-EXTERNALIZE.md
- Q4-BACKLOG-SECRETS-AND-KAFKA.md

### External Standards
- **OWASP Top 10 2021**: https://owasp.org/Top10/
- **OWASP API Security**: https://owasp.org/API-Security/
- **CWE Top 25**: https://cwe.mitre.org/top25/
- **LGPD**: Lei Geral de Proteção de Dados
- **PCI-DSS**: Payment Card Industry Data Security Standard

### Nubank Playbooks
- Proper Externalize: Confluence ENGCHAP
- Scopes Best Practices: InfoSec Playbooks
- Logging Security: Security Engineering

## Continuous Improvement

This skill is continuously updated as:
- New vulnerability patterns are discovered
- Security standards evolve
- Team feedback is incorporated
- False positive patterns are refined

## Support

For questions or issues:
1. Check examples in `examples/` directory
2. Review internal vulnerability documentation
3. Consult InfoSec team for complex cases
4. Contribute improvements via PR

---

**Version**: 1.0
**Last updated**: 2026-02-04
