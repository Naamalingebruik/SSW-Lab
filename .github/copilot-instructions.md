# GitHub Copilot Instructions — SSW-Lab

## Purpose
This repository contains study guides and Hyper-V lab automation scripts for preparing
Microsoft certification exams (MD-102, MS-102, SC-300, AZ-104) at Sogeti SSW.

## MS Learn alignment
When editing documentation (`docs/`) or lab scripts (`scripts/labs/`), always verify
content against the **official Microsoft Learn documentation** using the
Microsoft Learn MCP server (configured in `.vscode/mcp.json`).

### Verification checklist
1. **Exam domain names and weights** — check against the current skills-measured document:
   - MD-102: <https://learn.microsoft.com/credentials/certifications/resources/study-guides/md-102>
   - MS-102: <https://learn.microsoft.com/credentials/certifications/resources/study-guides/ms-102>
   - SC-300: <https://learn.microsoft.com/credentials/certifications/resources/study-guides/sc-300>
   - AZ-104: <https://learn.microsoft.com/credentials/certifications/resources/study-guides/az-104>

2. **MS Learn module links** — every `https://learn.microsoft.com/en-us/training/modules/…` URL
   in the study guides must resolve to an existing, published module.
   Use `microsoft_docs_fetch` to confirm the page exists and the title matches.

3. **Learning-path links** — every `https://learn.microsoft.com/en-us/training/paths/…` URL
   must point to a current, published learning path.

4. **Exam page links** — use the current URL format:
   - Certification page: `https://learn.microsoft.com/credentials/certifications/<cert-name>/`
   - Study guide:        `https://learn.microsoft.com/credentials/certifications/resources/study-guides/<exam-code>`
   - Practice assessment: `https://learn.microsoft.com/certifications/practice-assessments-for-microsoft-certifications`

### Recommended MCP queries
```
# Verify a module exists
microsoft_docs_fetch(url: "https://learn.microsoft.com/en-us/training/modules/<module-slug>/")

# Find the latest exam domains and weights
microsoft_docs_search(query: "<exam-code> skills measured domains weights")

# Find learning paths for a certification
microsoft_docs_search(query: "<exam-code> learning path modules")
```

## Language conventions
- English content lives in `docs/study-guide-*.md`
- Dutch content lives in `docs/studieprogramma-*.md`
- Both files must stay in sync when making content changes

## PowerShell conventions
- All scripts use WPF GUI (System.Windows.Forms / Windows.Markup.XamlReader)
- Use the `Dark` theme (#1E1E2E background) consistent with existing scripts
- Scripts must support `-DryRun` mode and manual step-through mode
