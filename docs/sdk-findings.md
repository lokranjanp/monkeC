# Monkey C / Connect IQ: findings from this computer

Inspection date: **2026-11-23**, macOS, repository `/Users/lokranjan/PycharmProjects/monkeC`.

This is the separate understanding document requested alongside the skills. Observations below distinguish actual experiments from documentation-based guidance and work that remains unverified. Machine-specific paths and versions belong here; agents should rediscover them rather than hard-code them into future projects.

## What is installed and usable

- SDK Manager root: `/Users/lokranjan/Library/Application Support/Garmin/ConnectIQ`.
- Active config: `current-sdk.cfg` under that root. Its content is an SDK directory, with a trailing slash and no terminal newline on this machine.
- Active SDK: `Sdks/connectiq-sdk-mac-9.3.0-2026-10-20-95888f262/`.
- Compiler reports **Connect IQ Compiler version: 9.3.0**.
- `monkeyc` was not on the shell PATH. The absolute wrapper worked; no SDK reinstall or global shell edit was needed.
- Host architecture reports `arm64`. `/usr/libexec/java_home -V` reports Eclipse Adoptium / Temurin **17.0.7**, `x86_64`, at `/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`. Actual compile/run success is established; I did not investigate the translation mechanism or install a different Java.
- There are **82 installed device-profile directories**, plus shared Fonts. Profiles are installed separately from the compiler. Their presence does not identify the user's device.
- The Connect IQ simulator launched successfully through the SDK's `bin/connectiq` script.
- This repository initially had IDE metadata and a Python venv, with no Garmin app source. Existing staged/modified `.idea` files were left alone.

Garmin's [SDK page](https://developer.garmin.com/connect-iq/sdk/) also lists 9.3.0 at the time of this investigation. That is a corroborating web observation, not a permanent “latest version” assumption.

## The most useful mental model

**Monkey C is the language; Toybox is the device API; Connect IQ is the build/runtime ecosystem.** Garmin Connect's web/account services and the Connect IQ Mobile SDK are separate integrations. A simple watch app can be compiled and simulated without building a phone app or calling a cloud API.

There are several independent compatibility axes:

1. Compiler/SDK version determines available build tools and language checks.
2. Device API level/firmware determines which runtime interfaces a device can provide.
3. Product hardware determines screen, inputs, sensors, and limits.
4. App type and foreground/background/glance context restrict available APIs and memory.
5. Manifest permissions enable only the supported protected operations.
6. Runtime data can still be absent, stale, or unavailable.

A compile success verifies only part of this contract. Declaring a permission does not add missing hardware. A `has` guard does not establish a valid GPS fix. Choosing a recent SDK does not upgrade device firmware.

## Local knowledge sources worth using first

The installed SDK contains enough material to avoid guessing common API signatures:

- `doc/Toybox/`: class/module API HTML, including types, nulls, “Since”, permissions, and device support.
- `doc/docs/Monkey_C/`: language syntax, Monkey Types, containers, memory, annotations, and compiler options.
- `doc/docs/Core_Topics/`: lifecycle, manifest, resources, backgrounding, sensors, communications, storage, testing, and publishing.
- `doc/docs/Reference_Guides/`: command-line setup and Jungle rules.
- `doc/docs/Connect_IQ_FAQ/`: focused answers such as AMOLED watch-face behavior.
- `bin/templates/`: current project skeletons with unresolved class-name and manifest placeholders.
- `samples/`: feature examples including Timer, ApplicationStorage, SimpleDataField, BackgroundTimer, PositionSample, RecordSample, Sensor, WebRequest, and Analog.
- `bin/resources.xsd`: resource schema.
- `Devices/<id>/compiler.json` and `simulator.json`: installed product metadata.

Root SDK HTML files such as `ReferenceGuides.html` are tiny redirect files; the actual local guide content is under `doc/docs`. Web navigation pages sometimes exposed only a site shell to the web reader, making the installed HTML especially useful.

Samples are examples, not guaranteed modern starting projects. The installed Timer sample has an older version-1 manifest, `minSdkVersion`, and many old product IDs absent locally. The current watch-app template uses manifest version 3 and `minApiLevel`. Copying a template requires resolving its placeholders; copying a sample requires auditing its targets and assumptions. I did not modify the installed SDK or samples.

## Monkey C understandings

The VM runs compiled bytecode. Syntax resembles familiar languages, but callback, memory, type, and API behavior must be learned on its own terms.

**Modern typing:** Monkey Types supports explicit member/argument/return types, unions (`or`), nullable types (`?`), container types, tuple types, and typed callbacks. `monkeyc -l 3` enables strict checking. The older [Monkey C overview](https://developer.garmin.com/connect-iq/monkey-c/) says the compiler does not check type safety; that statement is incomplete for this installed SDK. The installed `Monkey_Types.html` and actual compiler behavior are better guides.

**Imports:** `using` imports a module name and can alias it. `import` additionally makes class names convenient in type expressions. Module functions remain qualified. This distinction explains why new templates use `as Dictionary?` and `as Dc` after importing the corresponding modules.

**Nulls:** Type checking is useful for APIs and dictionary lookups that can return null. Missing data and zero have different meanings. A type cast does not validate an external reading or turn a String into a Number.

**Symbols and dictionaries:** `:count` and `"count"` are different keys. Dictionary literal pairs use `=>`. Symbol keys are common in API options, while JSON and stored data often use string keys. Missing entries evaluate to null.

**Callbacks:** A Method is bound to its owner; `counter.method(:increment).invoke()` invokes that counter's method. Use the API's callback signature, not JavaScript closures or promise conventions.

**Numbers:** Integer division truncates. In the runtime probe, `5 / 2` was 2 and `5.toFloat() / 2` was 2.5. Units and conversions need deliberate handling in fitness calculations.

**Memory:** Documentation describes reference counting, with circular ownership as a hazard. Bound Methods retain their receivers. Stop owned timers/listeners and break cycles; weak references are an option with nullable dereferencing. Runtime behavior of every ownership pattern was not tested here.

**Errors:** Catchable exceptions and fatal VM errors are different. Check unsupported symbols, nulls, indices, and memory conditions before assuming `try/catch` will recover.

## How an app fits together

`manifest.xml` defines app identity/type/entry, products, minimum API, permissions, languages, and barrels. `monkey.jungle` selects source/resources/overrides. The resource compiler generates `Rez`; application code consumes those IDs and layouts. These pieces must agree.

The app class extends `Application.AppBase`, initializes its parent, and returns the initial view/delegate. Views render through a provided `Graphics.Dc`; delegates handle input. Updates from timers/network callbacks should alter state and request rendering. A view's visible lifetime is a natural owner for view-specific subscriptions.

App type changes architecture. A data field participates in Garmin's activity UI, while a device app that records an activity needs an explicit recording session. A watch face must account for sleep/power behavior. A glance/background service has separate resource/API constraints. The detailed skills route agents to these distinctions before they write code.

Properties/settings and persistent app storage are different facilities. Sensors, activity context, tracking summaries, and sensor history also represent different kinds of data. Network calls are callback-based and need unavailable/error cases. These understandings came from local guides and API references; they were not validated by live sensor, storage, network, or recording experiments in this session.

## Hands-on experiment

Created [an original small watch-app](../examples/sdk-probe/README.md), with no copied Garmin sample source. It draws text and contains five meaningful runtime tests:

1. Null readings display `--`; an actual zero displays `0`.
2. Symbol and String dictionary keys differ; an absent key yields null.
3. A bound Method updates the intended receiver.
4. Integer division differs from explicit floating-point division.
5. A typed numeric array compiles and runs, and `has` recognizes a method.

The manifest selects `fr265` and `fenix7`, with minimum API 3.2.0 and no permissions. Both selected installed profiles are API **5.2.0**, so this does **not** prove operation on an actual 3.2.0 device.

The local `fr265` profile is round 416×416, AMOLED, with a 60×60 launcher icon. `fenix7` is round 260×260, MIP, with a 40×40 icon. Both profiles report these limits: watch-app 786,432 bytes; watch face 131,072; data field 262,144; glance/background 65,536 each; audio provider 524,288. These are observed profile values, not universal Garmin limits.

A disposable RSA-4096 / PKCS#8 DER key was generated under `/tmp` for the experiment and removed after validation. No existing developer key was sought outside project configuration or replaced. The experiment's private key is not part of the deliverable; reproducing a build requires a development key.

### Build and test results

- Strict test builds (`-l 3 -w -t`) succeeded for both products.
- Each product ran all five tests: **5 passed, 0 failed, 0 errors**, for ten successful test executions total.
- Strict release builds (`-l 3 -w -r`) succeeded for both products without warnings after the icon override was added.
- The release app was run and visually inspected on the Forerunner 265 simulator; it displayed “Monkey C works” centered on the black round display.
- The final fr265 test build was repeated after the icon resource change and built without warnings. The test logic was unchanged; the recorded runtime results predate this resource-only correction.
- Local export (`-e -r -l 3 -w`) succeeded. No upload, store submission, or hardware installation was performed.

See [fr265 test output](evidence/test-fr265.txt), [fenix7 test output](evidence/test-fenix7.txt), and [export output](evidence/export.txt). Release outputs measured 12,684 bytes for fr265 and 6,924 for fenix7; the `.iq` measured 17,833 bytes. These are file sizes, not runtime heap usage or a performance benchmark.

### What failed and what it taught me

**Strict assertions and nullable values:** The first test build failed at `Test.assertEqual(values[key], ...)` and `Test.assertEqual(values["missing"], null)`. The checker identified nullable operands against non-null Object parameters. Changing these to `Test.assert(values[key] == expected)` and `Test.assert(values["missing"] == null)` preserved the assertion and strict typing. No checker suppression was needed.

**Icon dimensions:** A shared 40×40 icon produced a fr265 scaling warning. A 60×60 SVG with the same logical viewBox, selected through a fr265 resource override, removed the warning. The base icon remains correct for fenix7.

**Runner exit status:** Both successful simulator suites returned shell status **1** despite their completed PASSED summaries. Therefore neither “nonzero always means test failure” nor “ignore all nonzero statuses” is reliable here. The skills require complete summary/count/error evidence and reporting the discrepancy. The wrapper's implementation/root cause and negative-case exit semantics were not investigated.

**Export count:** The compiler said “BUILDING FOR 3 DEVICES” for two manifest product IDs. Inspection showed `fr265` maps to `006-B4257-00`, while `fenix7` maps to `006-B3906-00` and `006-B3909-00`. The package contains exactly those three PRG/debug pairs. A product ID can expand to multiple hardware variants.

**Archive format:** `unzip` rejected the `.iq`; `file` identified a 7-Zip archive. macOS `tar -tf` and `tar -xOf ... manifest.xml` successfully inspected it. The skills say to detect the format instead of assuming ZIP.

**Test versus ordinary run:** Unit-test runs completed promptly. A normal app run stayed connected while the app displayed, so a long-lived `monkeydo` process alone is not proof of a hang.

**Screenshot capture limitation:** The live simulator screenshot visibly showed the app, but UI automation timed out during a later Save Screen Capture dialog attempt. No saved screenshot is included. The simulator process launched for this experiment was terminated during cleanup; that normal runner session is not presented as a clean application-exit test.

## What the skills prioritize

The [language skill](../.agents/skills/monkey-c/SKILL.md) focuses on decisions where familiar-language assumptions lead agents astray. The [Connect IQ skill](../.agents/skills/garmin-connect-iq/SKILL.md) starts with a situation brief and routes to deeper references only when needed.

They intentionally avoid hard-coding this computer's SDK version, username, device choice, or key. A small read-only helper discovers the active SDK and supports a `CIQ_SDK` override. It was tested with the real SDK, an explicit valid override, and an invalid path. The skill entry points pass the skill-creator frontmatter/scaffold validator; this is structural validation, not proof that every future agent task will succeed.

The validator needed PyYAML, which was installed only into ignored `.local/validation-deps` using the project's configured Python 3.11.9 environment. It was not added as a Garmin project dependency.

## Limits and next-app questions

No physical Garmin was connected/tested. No live phone, Garmin Connect account, HTTP service, sensor feed, activity/FIT recording, BLE/ANT device, or production signing identity was exercised. Battery behavior, actual firmware support, watch-face always-on rules, background scheduling, glance rendering, and data-field layouts remain documentation-based guidance.

Both simulated products are round; this does not validate rectangular, semiround, or every input arrangement. No Windows/Linux execution was tested. No app-store readiness or broad Garmin compatibility is claimed.

For a real app, establish its purpose, actual products, app type, data source, offline behavior, and minimum supported firmware/API. Then validate the relevant lifecycle and device features. The existing SDK is sufficient to begin that work.
