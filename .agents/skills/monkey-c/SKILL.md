---
name: monkey-c
description: Write, explain, and debug Garmin Monkey C source, including Toybox APIs, Monkey Types, nullability, callbacks, memory, and Run No Evil tests. Use for .mc language work; use garmin-connect-iq for SDK setup, app architecture, device targeting, and packaging.
---

# Monkey C

Understand the execution context before changing code. Monkey C runs in Garmin's Connect IQ VM; it is not C, JavaScript, or a Python variant. Similar syntax does not imply compatible libraries, callbacks, memory behavior, or collection operations.

## Establish context

- Inspect the nearest manifest, Jungle files, relevant `.mc` files, and resource definitions. Identify app type, target products, minimum API, compiler version, type-check level, and whether this code runs in foreground, background, or glance mode.
- Preserve the project's naming, imports, and typing conventions. For new code, prefer explicit boundary/member types and strict checking when the project supports it. Do not turn a small bug fix into a typing migration.
- Read the installed SDK's `doc/Toybox/<Module>/<Class>.html` for signatures, nullability, permissions, supported devices, and “Since” notes. Read `doc/docs/Monkey_C/Monkey_Types.html` for typing questions. Older overview pages claiming there is no static checking are incomplete for modern SDKs.
- If SDK discovery or building is needed, use `$garmin-connect-iq` when available, or locate the active SDK and inspect `bin/monkeyc --help` directly. The language work does not require an editor extension.

## Language decisions that matter

- Use `class ... extends ...` and `initialize()`; call the appropriate parent initializer. Use modules for shared functions/constants. Declare members; do not dynamically attach fields or methods to instances.
- Distinguish `using Toybox.Lang as Lang;` from `import Toybox.Lang;`. `import` makes class names available in type expressions; module functions still need qualification. Do not assume Java-style class imports or alias `import` with `as`.
- Use `as` for type declarations, `or` for unions, and `?` for nullable types. A cast communicates a type assertion; it does not validate external data or convert a String to a Number. Narrow unknown values with `instanceof` and null checks.
- Distinguish `:name` (a Symbol) from `"name"` (a String). Dictionary entries use `=>`. API option dictionaries often use Symbols; JSON/storage data often use Strings. Follow the API's actual contract.
- Check nullable readings and missing dictionary values. An API existing, permission being declared, and a meaningful reading being available are three different conditions. Do not display missing sensor data as a real zero.
- Pass bound callbacks using `method(:handler)` or `instance.method(:handler)`. For a module callback, consult `Lang.Method` construction. Do not invent arrow functions, closures, promises, or `async`/`await`.
- Use `has :symbol` for capability checks and `instanceof Type` for runtime types. Capability guards do not grant permissions or make an API valid for a different app type.
- Number is a 32-bit integer. Integer division truncates; convert an operand with `toFloat()` when a fractional result is required. Check units before conversion or formatting.
- Memory is reference counted. Break ownership cycles, release callbacks/listeners, and use weak references where appropriate. Cache expensive resources outside frequent drawing paths; measure before optimizing.
- Treat fatal VM errors separately from catchable exceptions. `try/catch` cannot repair every null access, invalid symbol, or out-of-bounds failure.

## Implement and verify

Keep rendering, event handling, and pure calculations separable. Preserve the lifecycle contract of the actual base class; a `WatchUi.SimpleDataField.compute()` implementation is not a regular view update method.

For language or API edge cases, make a minimal compiler probe at the project's type-check level rather than guessing. For runtime semantics, use `(:test)` functions and the simulator. Compilation alone cannot validate runtime behavior.

When tests are useful, build with `monkeyc -t`, then run the test-enabled PRG using the platform's `monkeydo` test switch. Verify the completed test summary, including counts and errors. SDK/platform wrappers may have surprising exit-status behavior; do not silently discard a nonzero exit code or accept an absent summary.

Read [language-patterns.md](references/language-patterns.md) for concrete syntax, null-safe examples, callback ownership, and test details. Report which target and compiler/type-check mode were actually verified.
