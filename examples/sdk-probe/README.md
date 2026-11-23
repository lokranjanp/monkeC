# SDK probe

An original watch-app that draws “Monkey C works” and includes five Run No Evil tests for null handling, Symbol/String dictionary keys, bound Methods, integer division, and typed arrays/capability checks.

The two products are experimental targets selected from the installed profiles, not a claim about the user's hardware. `fr265` uses a 60×60 icon override; `fenix7` uses the 40×40 base icon.

## Reproduce

From this repository root, set `KEY` to an existing authorized development key in PKCS#8 DER format, stored outside the repository:

```sh
SDK=$(sh .agents/skills/garmin-connect-iq/scripts/sdk-path.sh)
KEY=/absolute/path/to/developer_key.der
DEVICE=fr265
mkdir -p examples/sdk-probe/bin

"$SDK/bin/monkeyc" -f examples/sdk-probe/monkey.jungle -d "$DEVICE" \
  -y "$KEY" -o "examples/sdk-probe/bin/probe-$DEVICE-test.prg" -l 3 -w -t

"$SDK/bin/connectiq"
# Once the simulator is ready:
"$SDK/bin/monkeydo" "examples/sdk-probe/bin/probe-$DEVICE-test.prg" "$DEVICE" -t
```

Expected summary: `PASSED (passed=5, failed=0, errors=0)`. Repeat sequentially with `DEVICE=fenix7`. The inspected macOS 9.3.0 runner returned exit code 1 even on both successful suites; examine the complete summary rather than assuming success or failure from that code alone. Any missing/incomplete summary or transport error needs investigation.

Build and run without tests:

```sh
"$SDK/bin/monkeyc" -f examples/sdk-probe/monkey.jungle -d "$DEVICE" \
  -y "$KEY" -o "examples/sdk-probe/bin/probe-$DEVICE.prg" -l 3 -w -r
"$SDK/bin/monkeydo" "examples/sdk-probe/bin/probe-$DEVICE.prg" "$DEVICE"
```

The normal runner stays connected while the app runs. Stop the app using the simulator's File → Kill App command when finished.

Export locally:

```sh
"$SDK/bin/monkeyc" -f examples/sdk-probe/monkey.jungle -y "$KEY" \
  -o examples/sdk-probe/bin/probe.iq -l 3 -w -r -e
```

No upload is performed. On this installation export produced three part-number entries from the two products, because `fenix7` contains two hardware variants.

If no development key exists, see the skill's [signing instructions](../../.agents/skills/garmin-connect-iq/references/toolchain.md). The key created for the original exploration was disposable and is not included. Give this app a new ID and use the intended developer identity if adapting it into a separate real app.
