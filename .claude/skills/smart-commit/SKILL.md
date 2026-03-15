---
description: |
  Intelligently analyzes uncommitted changes, groups by context, and creates semantic 
  atomic commits with GPG signing. Follows Conventional Commits format, separates 
  concerns (feat/fix/refactor/test/style), and generates descriptive commit messages. 
  Automatically fixes GPG signing issues. Complete commit generation from repository 
  detection through signed commits.

tags:
  - git
  - commit
  - conventional-commits
  - gpg-signing
  - semantic-commits
  - version-control

category: git

invocation-triggers:
  - "create commits"
  - "commit my changes"
  - "organize commits"
  - "make commits"
  - "commit this"
  - "smart commit"
  - "atomic commits"

allowed-tools:
  - Shell
  - Read
  - Grep
  - Glob

required_permissions:
  - git_write

model: claude-sonnet-4-5-20250929
---

# Smart Commit Skill

## When to Use This Skill

I automatically invoke this Skill when you:
- Ask to commit your changes
- Want to organize multiple changes
- Need semantic commit messages
- Mention creating commits
- Request atomic commits

## What I Do

Create intelligent, organized commits:
- ✅ **Analyze**: Understands what changed (logic, tests, refactor, etc)
- ✅ **Group**: Creates atomic commits by context
- ✅ **Generate**: Writes descriptive Conventional Commits messages
- ✅ **Sign**: GPG-signs commits (MANDATORY)
- ✅ **Auto-fix**: Automatically fixes GPG signing issues

## Execution Flow (Optimized for Early Failure)

```
1. Validate Repository Context    ← Fast: Check we're in a git repo
2. Validate GPG Signing (EARLY!)  ← Fast: Test with empty commit
                                     FAIL FAST if GPG broken!
3. Check for Changes              ← Fast: git diff check
4. Analyze All Files & Diffs      ← HEAVY: Only runs if GPG OK
5. Generate Commit Messages       ← HEAVY: Semantic analysis
6. Execute Commits (GPG signed)   ← Safe: GPG already validated
```

**Key Optimization**: GPG validation happens BEFORE file analysis. If GPG is broken, fails in ~1 second instead of wasting 10+ seconds analyzing files first.

## Process Details

### Phase 1: Repository Context Detection

**CRITICAL**: Always establish repository context FIRST.

1. Get current working directory
2. Check if we're in a git repository
3. Get git repository root (`git rev-parse --show-toplevel`)
4. Get repository name and remote
5. Get current branch
6. Display repository context
7. Change directory to git root

**Why this matters:**
- Prevents confusion when workspace has multiple repositories
- Ensures all file paths are relative to correct git root
- Provides clear context in output and commit messages

### Phase 2: Validate GPG Signing (EARLY!)

**CRITICAL**: GPG signing is MANDATORY unless `--no-sign` explicitly used.

```bash
# Check if GPG key configured
GPG_KEY=$(git config user.signingkey)

if [ -z "$GPG_KEY" ]; then
    echo "❌ ERROR: No GPG signing key configured"
    exit 1
fi

# Configure GPG_TTY
export GPG_TTY=$(tty)

# Test if GPG signing works
if git commit --allow-empty -S -m "test" >/dev/null 2>&1; then
    git reset --soft HEAD~1
    SIGN_FLAG="-S"
else
    # AUTO-FIX SEQUENCE
    # Try fix 1: Set GPG_TTY explicitly
    # Try fix 2: Restart GPG agent
    # If all fail: Exit with instructions
fi
```

#### Automatic Fix Protocol

When GPG signing fails, automatically attempt to fix:

1. **Set GPG_TTY**: `export GPG_TTY=$(tty)`
2. **Test signing**: Try with new GPG_TTY
3. **Restart agent** if needed:
   ```bash
   gpgconf --kill gpg-agent
   gpg-agent --daemon
   ```
4. **Continue**: If fixed, proceed with signed commits

After successful auto-fix, ask user if they want to make it permanent:
```
✅ GPG signing fixed temporarily!

To make it permanent, I can add to ~/.zshrc:
  export GPG_TTY=$(tty)

Should I do this now?
```

**If auto-fix fails**, provide detailed manual instructions and exit.

### Phase 3: Check for Changes

```bash
# Check if there are uncommitted changes
if git diff --quiet && git diff --cached --quiet; then
    echo "✅ No uncommitted changes"
    exit 0
fi
```

### Phase 4: Analyze All Changes

Change to git root and identify all changed files:

```bash
cd "$GIT_ROOT" || exit 1

# Get list of changed files (relative to git root)
CHANGED_FILES=$(git diff --name-only HEAD)
STAGED_FILES=$(git diff --cached --name-only)
UNTRACKED_FILES=$(git ls-files --others --exclude-standard)

# Combine and deduplicate
ALL_CHANGED_FILES=$(echo -e "$CHANGED_FILES\n$STAGED_FILES\n$UNTRACKED_FILES" | sort -u | grep -v '^$')
```

For each changed file, get the diff and understand what changed:

```bash
for file in $ALL_CHANGED_FILES; do
    # Check if file is new (untracked)
    if git ls-files --error-unmatch "$file" > /dev/null 2>&1; then
        # File is tracked - show diff
        if git diff --cached --quiet -- "$file"; then
            # Unstaged changes
            git diff HEAD -- "$file"
        else
            # Staged changes
            git diff --cached -- "$file"
        fi
    else
        # File is new/untracked
        head -100 "$file"
    fi
    
    # Also read full file for context
    if [ -f "$file" ]; then
        Read "$file"
    fi
done
```

Analyze each file for:
- **Type of change**: new feature, bug fix, refactor, test, docs, style
- **Component affected**: logic, controller, adapter, model, test, config
- **Related files**: e.g., implementation + test together
- **Scope**: what feature/module it affects

### Phase 5: Group Changes into Logical Commits

**Grouping Strategy:**

1. **By Type + Scope** (primary grouping)
2. **Keep related files together** (e.g., source + test)
3. **Separate concerns** (logic ≠ style ≠ tests)

**Grouping rules:**

| Type | Group With | Separate From |
|------|------------|---------------|
| **feat** | Related tests | Other features |
| **fix** | Related tests | Refactors |
| **refactor** | Nothing else | Everything |
| **test** | Implementation (if new) | Unrelated tests |
| **style** | Nothing else | Everything |
| **docs** | Related code | Other docs |
| **chore** | Related config | Code changes |

**Example grouping:**

```
Commit 1: feat(payment): add validation logic
  - src/logic/payment_validation.clj (new)
  - test/unit/logic/payment_validation_test.clj (new)

Commit 2: refactor(controller): extract payment logic
  - src/controllers/payment.clj (modified)
  
Commit 3: test(payment): add edge case tests
  - test/unit/logic/payment_test.clj (modified)
  
Commit 4: style(payment): fix formatting
  - src/logic/payment.clj (formatting only)
```

### Phase 6: Generate Commit Messages

For each group, generate Conventional Commits message:

**Format:**
```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring (no behavior change)
- `test`: Adding/updating tests
- `style`: Formatting, whitespace (no code change)
- `docs`: Documentation only
- `perf`: Performance improvement
- `chore`: Build, deps, config

**Subject Line Rules:**
- ✅ Use imperative mood ("add" not "added" or "adds")
- ✅ Don't capitalize first letter (after colon)
- ✅ No period at the end
- ✅ Max 50 characters
- ✅ Complete the sentence: "If applied, this commit will..."

**Body Guidelines:**
- Explain **what** and **why**, not **how**
- Wrap at 72 characters
- Separate from subject with blank line
- Use bullet points for multiple items

**Footer Guidelines:**
- `Fixes #123` - Closes issue
- `Closes #456` - Closes issue
- `Refs #789` - References issue
- `BREAKING CHANGE:` - Breaking changes

### Phase 7: Propose Commits

Display proposed commits for user review:

```markdown
# 🎯 Proposed Commits

Based on analysis of your changes, here are the proposed commits:

---

## Commit 1: feat(payment): add validation logic

**Files**:
- ✅ src/logic/payment_validation.clj (new, +85 lines)
- ✅ test/unit/logic/payment_validation_test.clj (new, +120 lines)

**Changes**:
- Add CPF format validation
- Add amount range validation
- Add comprehensive test coverage

**Message**:
```
feat(payment): add validation logic

- Add CPF format validation with checksum
- Add amount range validation (0-100000)
- Add comprehensive test coverage (100%)

Related to payment refactor initiative
```

---

**Summary**:
- Total: 4 commits
- Files: 5 files across 4 commits
- Types: 1 feat, 1 refactor, 1 test, 1 style
```

### Phase 8: Execute Commits

If not in `--dry-run` mode, execute the commits:

```bash
# Ensure GPG_TTY is set for signing
if [ -n "$SIGN_FLAG" ]; then
    export GPG_TTY=$(tty)
fi

# For each proposed commit group
# Commit 1
git add src/logic/payment_validation.clj
git add test/unit/logic/payment_validation_test.clj

git commit $SIGN_FLAG -m "$(cat <<'EOF'
feat(payment): add validation logic

- Add CPF format validation with checksum
- Add amount range validation (0-100000)
- Add comprehensive test coverage (100%)

Related to payment refactor initiative
EOF
)"

echo "✅ Commit 1 created (feat: validation logic)"

# Repeat for each commit...
```

**IMPORTANT**: Always use HEREDOC for commit messages to preserve formatting.

## Commit Message Best Practices

### Good Examples

```bash
# ✅ GOOD
feat(payment): add CPF validation
fix(api): handle null response gracefully
refactor(controller): extract logic to service

# ❌ BAD
feat(payment): Added CPF validation.    # Past tense, period
Fix: Handle null response               # Capitalized
refactor: extracted logic               # Past tense
Update code                             # Vague, no scope
```

## Context Analysis Rules

### Identifying Change Type

**Feature** (feat):
- New function/namespace added
- New endpoint added
- New capability added

**Bug Fix** (fix):
- Fixes incorrect behavior
- Handles error case
- Corrects validation

**Refactor** (refactor):
- Code restructuring
- Extract function
- Move code between files
- No behavior change

**Test** (test):
- New test file
- New test cases
- Test updates

**Style** (style):
- Formatting only
- Whitespace changes
- No code logic change

**Documentation** (docs):
- README updates
- Comment additions
- Docstring updates

### Identifying Scope

Based on file path:

```
src/holocron/logic/payment.clj       → scope: payment
src/holocron/controllers/order.clj   → scope: order
src/holocron/adapters/external.clj   → scope: adapter or external
test/unit/holocron/logic/payment_test.clj → scope: payment (test)
```

## Modes

- **Default**: Analyze and create signed commits
- **--dry-run**: Preview without creating
- **--no-sign**: Create without GPG (NOT RECOMMENDED)
- **--interactive**: Approve each commit

## Examples

### Natural Language Invocation

```
"Commit my changes"
"Create commits for what I've done"
"Organize my work into commits"
"Make atomic commits"
```

### With Work Context

```
User: "I refactored payment processing and added tests"
You: [Notes the changes]
User: "Commit this"
You: [Automatically invokes this Skill]
     [Creates 2 commits: refactor + test]
```

## Success Criteria

Generated commits include:
- ✅ Atomic: One logical change per commit
- ✅ Semantic: Clear type and scope
- ✅ Descriptive: Explains what and why
- ✅ Signed: GPG signature verified
- ✅ Organized: Related changes grouped

## See Examples

- **Good Commits**: `examples/good-commits-example.md`
- **GPG Auto-Fix**: `examples/gpg-auto-fix-example.md`

---

**For developers**: This Skill creates organized, signed commits with complete logic. Automatic GPG fix handles 95% of signing issues.
