# npm audit — known issues + accepted risk register

Per ADR-093 §S5, `npm run check:audit` is the deploy gate. The gate
runs at `--audit-level=critical` (any critical finding blocks),
**not** `--audit-level=high`, because of the known transitive
`react-router-dom@6.x` graph documented below.

`npm run check:audit:high` is the awareness gate — non-blocking but
surfaces the same findings so they can't be silently ignored.

## Accepted (high) findings as of 2026-05-02

All listed below originate from a single dep: `react-router-dom@^6.30.1`
(tracked in `package.json`). They surface because that release line
pulls in older `glob`, `lodash`, `minimatch`, `picomatch` versions
through nested transitive paths.

| Package | Severity | Origin |
|---------|---------|--------|
| `@remix-run/router@<=1.23.1` | high | react-router |
| `react-router@6.0.0–6.30.2` | high | direct |
| `react-router-dom@6.0.0-alpha.0–6.30.2` | high | direct |
| `glob@10.2.0–10.4.5` | high | nested |
| `lodash@<=4.17.23` | high | nested |
| `minimatch@9.0.0–9.0.6` | high | nested |
| `picomatch@<=2.3.1` | high | nested |

### Why accepted

- All findings are in build/runtime support libraries that don't
  process attacker-controlled input on the user's request path —
  the routing surface (4 routes, all internal) is fully under
  application control.
- The fix path is `react-router-dom@7` which has breaking API
  changes (data router model, Future flags). Migrating is a
  separate scoped task, not a security hot-fix.
- No critical vulnerabilities are present; the deploy gate
  (`check:audit`) passes.

## Follow-up

Tracked: upgrade to `react-router-dom@7` once a sprint is
available — closes all 7 of these in one bump.
