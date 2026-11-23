# Language patterns and traps

These examples describe modern Monkey Types. Confirm behavior with the installed compiler when working on older code.

## Values, containers, and nulls

```monkeyc
import Toybox.Lang;

module ReadingFormat {
    function label(value as Number?) as String {
        if (value == null) {
            return "--";
        }
        return value.format("%d");
    }
}

var samples = [1, 2, 3] as Array<Number>;
var options = {:count => 7, "count" => 9};
// options[:count] and options["count"] are different entries.
// An absent dictionary entry yields null.
```

`Number?` means `Number or Null`. Keep uninitialized members nullable until initialization is guaranteed. The `(:initialized)` annotation is a promise to the checker, not initialization code.

Type expressions include `Array<Number>`, `Dictionary<String, Number>`, and tuples such as `[Views, InputDelegates]`. The angle brackets type containers; they do not imply a general user-defined generics system. Container compatibility is stricter than scalar union compatibility: do not assume `Array<Number>` is interchangeable with `Array<Number or String>`.

Runtime conversions use methods such as `toFloat()`; `as Float` is not a numeric conversion. For user input or a response, first validate the actual type, then convert, and handle invalid input. Check each API's accepted types rather than assuming implicit conversions.

Avoid translating collection helpers from another language by name. Inspect `doc/Toybox/Lang/Array.html` and `Dictionary.html`. Use an indexed `for` loop when a required higher-order operation is unavailable. Strings are immutable; repeated concatenation in an update loop allocates.

## Callback syntax and lifetime

```monkeyc
class Counter {
    var count as Number = 0;

    function initialize() {}

    function increment() as Void {
        count += 1;
    }
}

// Inside a function:
var counter = new Counter();
var callback = counter.method(:increment);
callback.invoke();
```

A Method keeps its receiver alive. If a receiver owns an object that retains its Method, that can create a cycle. Unregister listeners and stop timers according to their owner's lifecycle. A view-bound timer commonly starts in `onShow()` and stops in `onHide()`; a service has a different lifetime. Do not retain `Graphics.Dc` for later asynchronous drawing.

For module functions, the documented form is `new Lang.Method(MyModule, :handler)`. Typed callback contracts can look like `Method(value as Number) as Void`; match the API's exact parameters and return type.

## Capability and data checks

Use separate checks for separate failure modes:

1. Target/API contract: Does this product and app type support the API?
2. Manifest: Is its required permission present?
3. Runtime: Does the module/object have the needed symbol?
4. Data: Is the reading non-null, current, and of the expected type?

Example structural guard: `if (Toybox has :Sensor) { ... }`. Before dereferencing a nested optional API, guard the enclosing capability as needed. A `has` check can be optimized for a known build target; it is not a substitute for testing the supported products.

Null-safe display is a product decision. Preserve the distinction between missing, stale, and zero values; carry timestamps when caching external readings.

## Tests and diagnostics

```monkeyc
import Toybox.Lang;
import Toybox.Test;

(:test)
function missingReadingIsDistinct(logger as Logger) as Boolean {
    Test.assertEqual(ReadingFormat.label(null), "--");
    Test.assertEqual(ReadingFormat.label(0), "0");
    return true;
}
```

Tests accept one `Test.Logger` and return Boolean. Test-only helpers/classes should also be annotated when they should disappear from ordinary builds. `monkeyc -t` includes tests; `monkeydo ... -t` runs them on macOS/Linux. Check Windows wrapper help for its syntax.

SDK 9.3.0's strict checker rejects `Test.assertEqual(nullableValue, null)` because that method's operands are non-null Objects. Use `Test.assert(nullableValue == null)` or narrow values first. Preserve the strict check instead of hiding this with an unjustified cast.

For a failure, distinguish syntax/name resolution, type mismatch, missing resources, unavailable API, null data, and VM memory errors. Keep the original message, file/line, target, build mode, and reproduction. A `Symbol Not Found` can indicate app-type/API restrictions as well as a spelling error.

## Authoritative references

- Installed SDK: `doc/docs/Monkey_C/Monkey_Types.html`, `Objects_and_Memory.html`, `Containers.html`, `Exceptions_and_Errors.html`.
- [Monkey Types](https://developer.garmin.com/connect-iq/monkey-c/monkey-types/) for gradual typing and `import`.
- [Objects, modules, and memory](https://developer.garmin.com/connect-iq/monkey-c/objects-and-memory/) for ownership and callbacks.
- [Test API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Test.html) for exact assertion signatures.

Prefer the local version-matched API documentation when web documentation describes a newer SDK.
