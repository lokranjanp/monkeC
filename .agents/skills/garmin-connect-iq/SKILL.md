---
name: garmin-connect-iq
description: Build, run, debug, and package Garmin Connect IQ apps with the installed SDK. Use for Monkey C projects, watch faces, data fields, device apps, widgets/glances, manifests, Jungle builds, resources, simulator tests, and Garmin device compatibility. Distinguish this device SDK from Garmin Connect web APIs and the Connect IQ Mobile SDK.
---

# Garmin Connect IQ development

Establish what is installed, what the project targets, and what the app is allowed to do before implementing a feature. The device programming platform is **Connect IQ**. Garmin Connect account/data APIs and the Connect IQ Mobile SDK solve different problems; clarify only when the requested integration depends on that distinction.

## Build a situation brief

Read project instructions and relevant files first. Record these facts concisely in working notes; do not make the user fill out a checklist if the project already answers it:

- Intended behavior and app type: watch face, data field, device app, widget/glance, or audio provider.
- Selected SDK/compiler version, Java availability, device-profile directory, signing-key path availability, and existing build commands.
- Manifest identity/entry point, minimum API, product IDs, permissions, languages, and barrel dependencies.
- Jungle source/resource paths, target overrides, annotations excluded from each build, generated files, and external dependencies.
- Foreground/background/glance context, display geometry/technology, input capabilities, memory budget, and data dependencies.
- What has actually been built, simulated, or tested on hardware; what remains assumed.

Do not infer the user's watch model from installed profiles. If no target is specified, use a clearly labeled installed target for a smoke test; ask for actual product requirements before committing to a shipping device matrix.

## Discover the local toolchain

Run [scripts/sdk-path.sh](scripts/sdk-path.sh) to print the SDK root on macOS/Linux. It accepts an explicit `CIQ_SDK` override and otherwise reads SDK Manager's active configuration. Then inspect `bin/monkeyc --version`, `--help`, and the platform's `monkeydo` usage. Paths may contain spaces and the cfg may contain a trailing slash without a newline.

Do not conclude the SDK is absent because `monkeyc` is missing from PATH. Use quoted absolute paths without changing global shell configuration. If Java fails, inspect the wrapper and Java installation separately from SDK discovery.

Read [toolchain.md](references/toolchain.md) for commands, signing, simulator execution, test verdicts, packaging, and common failures.

## Choose an implementation that fits the device

Treat compatibility as the intersection of **product + firmware/API + app type + execution context + permissions**. Compiler version, Connect IQ System number, and device API level are different version axes. A high SDK version does not upgrade an older watch or remove app-type restrictions.

- Use `$SDK/doc/Toybox` for API contracts and `$SDK/doc/docs` for architecture guidance. Check “Since”, supported products, nullability, and required permissions before using an unfamiliar API.
- Use `$SDK/bin/templates` for the matching app type and `$SDK/samples` for an API-specific example. Templates contain substitutions; samples can contain old manifests and products not installed locally. Inspect and adapt a copy; leave the SDK unchanged.
- Inspect device `compiler.json` and `simulator.json` for geometry, icon dimensions, display type, and per-app-type limits. These are local SDK implementation data, not a guarantee about a physical device's firmware.
- Use the correct lifecycle and data source. A data field extends Garmin's activity experience; a device app recording an activity has to manage its own recording session. A watch face must respect low-power/AMOLED behavior.
- Keep source, XML resources, generated `Rez` symbols, and build configuration consistent. Never hand-edit generated `Rez` output to fix a resource error.

Read [app-design.md](references/app-design.md) for lifecycle, resources, persistence, communications, sensors, power, and device-specific testing. Use `$monkey-c` when available for language/typing issues.

## Close the development loop

Build for explicit products, then exercise the relevant simulator behavior. For supported products with different displays/input/memory constraints, test representative differences and compile all declared release targets when practical. A simulator run does not prove real GPS, sensors, phone connectivity, battery life, or installed firmware behavior.

For new app work, complete a small working slice (manifest → resources → AppBase → view → explicit-target build → simulator) before adding services or broad device support. For fixes, make the smallest useful reproduction and validate the affected behavior.

Keep developer keys outside source control. Use an existing authorized app key for releases; a disposable lab key is only for experiments. Preserve existing app IDs and signing identity. Make local `.iq` export only when useful to the requested task; export does not publish. Store submission, account changes, and hardware installation are separate actions and are not implied by a request to edit/build code.

Deliver source changes with the compiler/targets/build mode, test summary, remaining warnings, and hardware-only gaps. Never describe an untested template as a verified Garmin app.
