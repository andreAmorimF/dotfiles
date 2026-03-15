---
description: |
  Automatically review GitHub Pull Requests following Nubank's Clojure and 
  Diplomat Architecture best practices. Performs comprehensive analysis covering 
  architecture boundaries (SRP), code style, security, testing, and provides 
  actionable feedback with specific file:line references and code examples.

tags:
  - code-review
  - pull-request
  - clojure
  - diplomat
  - architecture
  - security
  - quality-gate

category: code-quality

invocation-triggers:
  - "review this PR"
  - "analyze pull request"
  - "check PR"
  - "code review"
  - "review my changes"
  - "look at this PR"
  - "what do you think of this PR"
  - "pr review"
  - "review github"

allowed-tools:
  - Shell
  - Read
  - Grep
  - Glob

model: claude-sonnet-4-5-20250929
---

# PR Review Skill

## When to Use This Skill

I automatically invoke this Skill when you:
- Mention reviewing a Pull Request
- Provide GitHub PR URLs
- Ask for code quality analysis
- Request architectural validation
- Want comprehensive feedback on changes

## What I Do

Perform a thorough technical review covering:
- ✅ **Architecture**: Diplomat boundaries, SRP compliance
- ✅ **Code Style**: Clojure idioms, naming, formatting
- ✅ **Security**: PII handling, secrets, validation
- ✅ **Logic**: Business rules, error handling, edge cases
- ✅ **Testing**: Coverage, quality, missing tests
- ✅ **Documentation**: Docstrings, comments, READMEs

## Complete Review Process

When invoked (naturally or via `/pr-review`), I execute:

### Phase 1: Fetch PR Information
1. **Parse PR URL** to extract org/repo/number
2. **Fetch PR metadata** with `gh pr view`:
   - Title, author, status, changes count
   - Branch names (head → base)
3. **Fetch PR diff** with `gh pr diff`
4. **Detect context**: Local repo or external repo
5. **Fetch file content** (strategy based on context):
   - Local: Use Read tool directly
   - External: Use `gh api` for files

### Phase 2: Structural Analysis
1. **Categorize changed files** by component:
   - Controllers, Logic, Models, Adapters, Wire, Tests
2. **Identify change patterns**: Feature, fix, refactor
3. **Assess impact**: Low, Medium, High

### Phase 3: Architectural Review
- **Load conventions**: `@../../conventions/diplomat-guidelines.md`, `@../../conventions/severity.md`
- **Component boundary violations** (SRP)
- **Schema & skeleton patterns**
- **Wire pattern compliance** (wire.in tolerance, wire.out strictness)

### Phase 4: Code Style Review
- **Load convention**: `@../../conventions/clojure-style.md`
- **Formatting & indentation**
- **Function design** (length, parameters)
- **Naming conventions** (lisp-case, predicates, side-effects)
- **Idiomatic patterns** (when vs if, threading macros)
- **Anti-patterns** (magic numbers, god functions)

### Phase 5: Security & Safety Review
- **PII handling** in logs and wire.out
- **Exception handling** patterns
- **Validation** at boundaries
- **Secrets & configuration** (no hardcoded values)

### Phase 6: Testing & Documentation
- **Test coverage** for new/changed code
- **Documentation** (docstrings, :doc attributes)
- **CI status** check with `gh pr checks`

### Phase 7: Generate Report
- PR Summary
- Structural Analysis
- Findings (ordered by severity: MUST → SHOULD → COULD)
- Considered But Not Flagged
- Positive Observations
- Recommendations
- Review Verdict

### Key Features

**As a Skill** (auto-invoked):
- I extract PR URLs from natural language
- I understand context ("review my last PR")
- I can combine with other Skills automatically
- I provide a more conversational tone

**As a Command** (explicit `/pr-review`):
- Direct invocation with URL and optional review type
- Predictable, scriptable
- Better for CI/CD automation
- Stricter argument validation

## Examples

See the `examples/` directory for:
- `good-pr.md` - Example of well-structured PR with positive review
- `needs-work-pr.md` - PR with issues and how they're flagged
- `security-pr.md` - Security-focused review example

## Usage Patterns

### Natural Language Invocation

```
"Can you review this PR? https://github.com/nubank/holocron/pull/123"
"What do you think of PR #123 in holocron?"
"Check out my latest PR and let me know if there are any issues"
"Review the changes in https://github.com/nubank/holocron/pull/456"
```

### With Context

```
User: "I just opened a PR for the payment refactor"
You: "Great! What's the PR URL?"
User: "https://github.com/nubank/holocron/pull/789"
You: [Automatically invokes this Skill]
```

### Combined with Other Skills

```
"Review my PR and run the tests for the changed files"
→ Invokes pr-review Skill + test-runner Skill
```

## Success Criteria

A successful review provides:
- ✅ Clear verdict (PASS/NEEDS_CHANGES/MUST_ISSUES)
- ✅ Specific findings with severity (MUST/SHOULD/COULD)
- ✅ File:line references for every issue
- ✅ Code examples showing fixes
- ✅ "Considered But Not Flagged" transparency
- ✅ Actionable recommendations prioritized by impact

---

**For developers**: This Skill provides the same quality review as `/pr-review` but with natural language flexibility. Use whichever fits your workflow!
