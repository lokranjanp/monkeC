# Monkey C and Garmin Connect IQ agent skills

Two skills built from inspection and hands-on use of the installed Connect IQ SDK:

- [monkey-c](.agents/skills/monkey-c/SKILL.md): language semantics, typing, nulls, callbacks, ownership, and tests.
- [garmin-connect-iq](.agents/skills/garmin-connect-iq/SKILL.md): establish project/device context, discover the SDK, choose the app architecture, build, simulate, debug, and export.

Read [SDK findings](docs/sdk-findings.md) for the separate research notes, exact local environment, experiment results, caveats, and source map. The skills contain reusable guidance; the findings describe this computer on 2026-11-23.

The [SDK probe](examples/sdk-probe/README.md) is an original minimal app with five runtime tests. It was compiled with strict typing and tested in the simulator for `fr265` and `fenix7`. It is an experiment, not a production app template for every app type.

## Use

Invoke `$monkey-c` for language work or `$garmin-connect-iq` for Garmin app development. Both allow normal automatic skill selection. The source folders live in `.agents/skills/`; this machine also has links to them in `~/.codex/skills/` for personal discovery. An already-running agent may need a new session to discover newly added skills.

For another agent/tool, load the relevant `SKILL.md` and follow its links only as needed. Each skill folder can be copied independently; the companion skill is optional. Keep the scripts and references with their entry point. If this repository moves, update this machine's personal links.

Start with context, not a large generated app: determine app type, actual devices, minimum API, permissions, data sources, display/input constraints, and what can be verified locally. Installed profiles do not identify the user's watch.

Build outputs, temporary validation dependencies, and private signing keys are ignored. No Garmin SDK files or production signing key are bundled.
