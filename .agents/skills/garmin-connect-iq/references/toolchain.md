# Toolchain, simulator, and packaging

## Locate and inspect

On macOS, SDK Manager normally stores its state under `$HOME/Library/Application Support/Garmin/ConnectIQ`. On Linux the documented location is `$HOME/.Garmin/ConnectIQ`. On Windows use `%APPDATA%\Garmin\ConnectIQ`. Read `current-sdk.cfg` rather than guessing the newest directory in `Sdks`.

The helper `../scripts/sdk-path.sh` prints the current SDK root on macOS/Linux. Example from a project root containing this skill:

```sh
SDK=$(sh .agents/skills/garmin-connect-iq/scripts/sdk-path.sh)
"$SDK/bin/monkeyc" --version
"$SDK/bin/monkeyc" --help
"$SDK/bin/monkeydo" --help
java -version
```

Adjust the helper path if the skill is installed elsewhere. Alternatively read the cfg directly. `CIQ_SDK=/path/to/sdk sh /path/to/sdk-path.sh` selects an explicit SDK without changing SDK Manager.

The observed macOS wrappers invoke `java` from PATH. A configured `JAVA_HOME` alone does not make that shell pick its Java executable; verify the actual executable when diagnosing Java errors. Official command-line documentation requires Java 11 or newer. On Windows use the supplied `.bat` launchers and quote paths in the shell's native syntax.

Useful SDK locations:

- `bin/monkeyc`, `monkeybrains.jar`: compiler and Java implementation.
- `bin/connectiq`, `ConnectIQ.app` on macOS: simulator launcher/application.
- `bin/monkeydo`: push/run a PRG in the simulator.
- `doc/Toybox`: version-matched API contracts.
- `doc/docs`: actual local guides. Root-level HTML files can just redirect to the website.
- `bin/templates`: app skeletons containing placeholders such as `${appClassName}`.
- `samples`: runnable demonstrations, subject to their own manifests and dependencies.
- `bin/resources.xsd`: resource XML schema.
- Sibling `Devices/<product-id>/compiler.json`, `simulator.json`: separately downloaded device profiles.

Do not copy all SDK docs into a skill. Locate the relevant class or topic and read it on demand.

## Build commands

From an app's project directory, after setting `SDK`, `DEVICE` to an installed manifest product, and `KEY` to the authorized signing key path:

```sh
mkdir -p bin
"$SDK/bin/monkeyc" -f monkey.jungle -d "$DEVICE" \
  -o "bin/app-$DEVICE.prg" -y "$KEY" -l 3 -w
```

Use `-l 3` for strict new code; retain a legacy project's deliberate checker level. `-l 0/1/2/3` means off/gradual/informative/strict. `-w` enables warnings. `-r` strips debug information for release. `-O` controls optimization; inspect installed help before choosing values. Avoid deprecated `-m`, `-z`, and `-x` in new Jungle-based commands.

Relative paths in a Jungle file resolve relative to that Jungle's directory. CLI output paths resolve in the shell's working directory. Quote the argument to `-f` when passing multiple semicolon-separated Jungle files.

Keep build artifacts outside source directories and distinguish products/modes in filenames. A PRG is target-specific. Preserve debug information alongside the matching build for debugging; do not read stale generated files after a failed compile.

## Signing

Compilation uses `-y` with a private signing key. Check project/editor settings for an existing key **path** without printing private key contents. Do not generate a replacement key for an existing app to get past a build error.

For a new disposable experiment, Garmin's documented format is RSA 4096 converted to unencrypted PKCS#8 DER:

```sh
# Run in a disposable directory outside the repository; do not reuse for releases.
umask 077
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -inform PEM -outform DER \
  -in developer_key.pem -out developer_key.der -nocrypt
```

For a real app, preserve and securely back up the developer key. Exclude PEM/DER private keys from source control. The key is separate from the app ID, developer account credentials, and manifest permissions.

## Run and test

```sh
"$SDK/bin/connectiq"
"$SDK/bin/monkeydo" "bin/app-$DEVICE.prg" "$DEVICE"

"$SDK/bin/monkeyc" -f monkey.jungle -d "$DEVICE" \
  -o "bin/app-$DEVICE-test.prg" -y "$KEY" -l 3 -w -t
"$SDK/bin/monkeydo" "bin/app-$DEVICE-test.prg" "$DEVICE" -t
```

Start the simulator and wait for readiness before `monkeydo`; tests require the simulator. Use one simulator job at a time. A test name can follow `-t`. The macOS wrapper uses `-t`, while some website examples show Windows `/t`; inspect the installed wrapper rather than mixing syntax.

A normal app run can keep the runner connected until the app exits. Use the simulator's app-stop command when done (File → Kill App in the inspected 9.3.0 macOS simulator). Do not launch repeated jobs into an already running app and mistake the resulting connection error for a code failure.

### Interpreting test status

Record both the process exit status and the complete output. On the macOS SDK 9.3.0 installation inspected for this skill, two different device runs returned status **1** while printing a completed `PASSED (passed=5, failed=0, errors=0)` summary. This is an observed local behavior, not a general guarantee about all versions.

For this case, require the expected test count, a final PASSED summary, zero failures/errors, and no later transport/runtime failure. An absent summary, zero tests when tests were expected, a FAILED summary, or connection errors is not success. Do not globally convert exit 1 to success. Report discrepancies and validate the local wrapper before integrating a parser into CI.

Simulator inspection should cover the behavior changed: display clipping, button/touch actions, view navigation, start/stop, settings, missing data, and lifecycle transitions. Watch-face power modes, data-field layouts, and background services require their own simulator scenarios.

## Local export versus distribution

From the app directory:

```sh
"$SDK/bin/monkeyc" -f monkey.jungle -e -r -l 3 -w \
  -o bin/app.iq -y "$KEY"
```

Export builds the manifest's products into an `.iq` package. Verify device profiles are installed and all required targets compile. Inspect the package, resolve actionable warnings, and retain matching source/debug provenance. A local `.iq` is not a store listing and does not publish anything.

One product can expand into multiple hardware part numbers, so the export's device count need not equal the number of product IDs. Inspect `compiler.json`'s `partNumbers` and the package manifest. Check the archive format before extracting: the inspected 9.3.0 `.iq` was a 7-Zip archive, readable with macOS `tar -tf`, not `unzip`.

For hardware sideloading, consult the current device-specific Garmin instructions; the usual artifact is a device-specific PRG in the device's `GARMIN/APPS` directory. Do not assume USB file access is available on every device/OS. Store submission and release-signing continuity need the user's real app identity and explicit distribution scope.

## Diagnose by layer

- Command missing: check active SDK config and absolute wrapper path before installing anything.
- Java error: inspect Java version/architecture/PATH and wrapper requirements.
- Unknown product or missing files: compare `-d`, manifest product IDs, and installed device directories.
- Resource/`Rez` error: inspect effective Jungle paths, XML IDs, overrides, filename case, and generated resource output.
- Symbol/permission error: inspect the API's app-type, context, API-level, and permission requirements.
- Type error: read the actual signature; narrow nulls instead of disabling checks or adding blind casts.
- Simulator connection failure: check simulator readiness and existing running sessions.
- Runtime memory failure: inspect per-app-type budget, retained resources, allocations, and callback cycles.
- Packaging-only failure: inspect every manifest product and release annotation/exclusion differences.

Sources: [command-line setup](https://developer.garmin.com/connect-iq/reference-guides/monkey-c-command-line-setup/), [Jungle reference](https://developer.garmin.com/connect-iq/reference-guides/jungle-reference/), [unit testing](https://developer.garmin.com/connect-iq/core-topics/unit-testing/), plus the installed SDK help and wrappers.
