# Build tooling

Only PowerShell (5.1 or 7) is required. A Lua 5.1 interpreter is needed for the smoke test, and
lua-language-server for the type check.

| Task | Command |
| --- | --- |
| Smoke-load the addon and build every page | `.\build\smoke.ps1 -Lua <lua5.1>` |
| Type-check with LuaLS against the baseline | `.\build\luals-check.ps1` (finds the VS Code extensions; `-UpdateBaseline` rewrites it) |
| Check that new enUS strings are appended | `.\tools\Validate-LocalizationAppendOnly.ps1` |
| Build a release zip locally (into `dist\`) | `.\build\stage.ps1` |
| Same, stamping a version | `.\build\stage.ps1 -Version 1.0.1 -ReleaseType beta01` |

## Lua 5.1

Windows: download the LuaBinaries `lua-5.1.5_Win64_bin.zip` (sourceforge.net/projects/luabinaries), unzip it
anywhere, and pass the path with `-Lua`. With `lua5.1` on the PATH, `-Lua` can be dropped. See
`harness\README.md` for what the smoke test covers.

## Pull request checks

`.github\workflows\checks.yml` runs on every pull request and branch push, and `release.yml` calls it before
staging a tag. Each check is its own job:

- **Lua syntax:** `luac5.1 -p` on every tracked Lua file, and every TOC entry exists.
- **Smoke load:** `smoke.ps1`. A run that loads no files fails.
- **LuaLS:** `luals-check.ps1` with lua-language-server and Ketho's WoW API annotations, pinned in the workflow
  to the versions of the VS Code extensions. It fails on any Error, Warning, or Information diagnostic missing
  from `build\luals\baseline.json`, which matches on file, code, and message, not line.

The LuaLS settings for the check live in `build\luals\config.json`, a copy of the `Lua.*` keys in
`.vscode\settings.json` (which isn't tracked). Change both together. When a fix clears a baseline entry, the
check says so; run `.\build\luals-check.ps1 -UpdateBaseline` and commit the smaller baseline. Add to the
baseline only a warning that can't be fixed in code.

## Releasing

Before tagging, stamp `## Version:` and `## X-ReleaseDate:` in `TwintopQOL.toc` and add the release's section
to the top of `NewsContent.lua`; the packager rewrites none of them. Then push a tag whose version matches the
TOC: `1.0.0-release`, `1.0.0-beta01`, or `1.0.0-alpha01`.

The workflow in `.github\workflows\release.yml` runs the checks in `checks.yml`, stages the zip with
`stage.ps1` as a workflow artifact, and hands the checkout to the BigWigs packager. The packager builds the
zip, creates the GitHub release with it attached, and uploads to CurseForge and Wago when the TOC has an
`X-Curse-Project-ID` or `X-Wago-ID` line and the `CF_API_KEY` or `WAGO_API_TOKEN` secret exists. A tag
containing `alpha` or `beta` is a pre-release everywhere. The changelog on every site is the newest release's
section of `NewsContent.lua` (from its first `# ` heading to the next), which the workflow writes to `CHANGELOG.md`.

**Dry run.** Run the workflow by hand (workflow_dispatch): the packager builds the zip with `-d` (no uploads,
no GitHub release) and the zip is attached to the run as the `packager` artifact.
