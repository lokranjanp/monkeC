# App architecture and device constraints

## Choose the app context

- **Watch face:** home-screen time display, usually derived from `WatchUi.WatchFace`. Design active/sleep rendering, update cadence, and AMOLED always-on behavior. Do not keep a polling timer running as if it were a foreground app. Check device-specific burn-in/luminance restrictions in the local FAQ.
- **Data field:** embedded in Garmin's activity pages. `WatchUi.SimpleDataField.compute(info as Activity.Info)` returns a value and uses Garmin rendering; `WatchUi.DataField` supports custom drawing. Use the activity information supplied by the host and support varied field dimensions. Do not assume permission to start your own activity recording or the availability of all foreground-app APIs.
- **Device app (`watch-app` in manifests):** independent views and input handling. Activity recording, GPS, and services are explicit responsibilities when used.
- **Widget/glance:** quick information with a constrained glance entry point and a fuller launched experience. Inspect `AppBase.getGlanceView()` and supported device behavior. A glance is an execution mode, not a reason to invent a `glance` manifest app type.
- **Audio content provider:** music integration with dedicated playback/sync contracts; start from its actual SDK template.

The manifest's spelling may differ from `compiler.json` labels (`watch-app` versus `watchApp`, for example). Use an appropriate template and schema, not a copied device metadata label.

## App, view, and delegate

The manifest `entry` names the class extending `Application.AppBase`. `initialize()` calls `AppBase.initialize()`. App lifecycle callbacks belong here, with `getInitialView()` returning `[view]` or `[view, delegate]` under the appropriate typed signature.

A view commonly implements:

- `initialize()`: parent initialization and local state.
- `onLayout(dc)`: establish the layout/resources for the current dimensions.
- `onShow()`: acquire resources/listeners owned by the visible view.
- `onUpdate(dc)`: render current state. If using an XML layout, call `View.onUpdate(dc)` as appropriate.
- `onHide()`: release view-owned work and references.

Use a `BehaviorDelegate` for semantic actions where suitable. Check actual product inputs rather than assuming every screen is touch-enabled. Pair the delegate with the correct view. Asynchronous callbacks update model state and request a redraw with `WatchUi.requestUpdate()`; draw with the DC provided to `onUpdate()`.

Rendering should use `dc.getWidth()` and `dc.getHeight()`, readable fonts, and device/field-appropriate margins. Round display edges and data-field clipping need explicit testing. Bitmap size, alpha support, font metrics, and pixel density vary independently.

## Manifest, Jungle, and resources form one contract

Manifest: app identity, type, entry, name/icon references, minimum API, products, permissions, language declarations, and barrels. Preserve IDs in existing projects. Give a copied starter a new identity before shipping it as a separate app. Modern templates use manifest version 3 and `minApiLevel`; older samples can use version 1 and `minSdkVersion`.

Jungle: build selection and inheritance. A minimal explicit configuration is:

```jungle
project.manifest = manifest.xml
base.sourcePath = source
base.resourcePath = resources
fr265.resourcePath = $(base.resourcePath);resources-fr265
```

The `$(...)` syntax is Jungle variable expansion, not a shell command. Quote heredocs when writing Jungle from a shell. Paths use semicolon-separated lists. Preserve the base paths when adding overrides; an assignment that replaces them can drop shared resources. Inspect the full hierarchy when mixing shape/family/product overrides or `excludeAnnotations`.

Resources generate `Rez.Strings`, `Rez.Drawables`, `Rez.Layouts`, etc. Manifest references such as `@Strings.AppName` are XML references; `Rez.Strings.AppName` is a runtime resource ID, not the loaded text. Use the documented resource loader or layout factory. Match IDs and filename case. Supply language-specific strings and test longer text where the task requires localization.

Device launcher icon sizes differ. A scaled icon warning can be benign, but a resource override with the expected size gives predictable output. Do not treat one product's dimensions as a global default.

Barrels are Connect IQ libraries. Inspect both manifest dependencies and Jungle barrel paths/annotations; importing a module does not fetch an npm/Python-style dependency.

## Data, persistence, and communications

- `Application.Properties` describes configured app properties/settings backed by resource declarations. `Application.Storage` stores app-owned persistent state. Do not use a settings-property key as if it were a storage key without an intentional design.
- Handle missing keys, old schema versions, and unexpected types when loading saved state. Persist supported serializable values; consult the Storage API for restrictions and size limits. Avoid writes every draw/update.
- Inspect `onSettingsChanged()` when changes should update a running view. Preserve the user's settings when changing defaults or schema.
- `Activity.Info` is activity context. `Sensor` provides live sensor facilities; `SensorHistory` provides history; `ActivityMonitor` provides tracking summaries. They have different permissions, availability, units, and nullability. Choose the data source by meaning, not by similar field names.
- GPS requires API-appropriate permissions and valid fix handling. Start/stop subscriptions deliberately; a non-null structure does not always mean a valid fix.
- Activity recording belongs to `ActivityRecording.Session`. Design start, pause, stop, save/discard, and failure handling explicitly. Computing or displaying a metric does not automatically record it to FIT; investigate `FitContributor` if that is required.
- HTTP work uses callback-based `Communications` APIs, not browser fetch. Match response code/data types, configure the expected response format, and handle offline/error/stale data. Device/phone transport behavior must be tested on hardware. Check restrictions for watch-face/background and data-field contexts before adding networking.
- A companion iOS/Android app uses the **Connect IQ Mobile SDK** for phone/device integration. Garmin Connect cloud/account APIs are another integration entirely. Avoid adding either merely to make a local device app compile.

## Background, power, and memory

Background services are event-driven and constrained; they are not arbitrary always-running threads. Inspect `Background` registration APIs, `System.ServiceDelegate`, `AppBase.getServiceDelegate()`, `(:background)` scope, resource scope, and `Background.exit(data)`. The main app receives results through the documented callback. Check current scheduling/runtime limits rather than inventing a polling interval.

Each app context has its own memory budget. Read the product metadata and inspect runtime memory/profile tools; a watch-app allocation limit cannot be applied to its glance or background service. Avoid retaining large decoded images and allocating dictionaries/strings in hot paths. Stop listeners/timers when ownership ends; bound Methods can retain their owners.

For AMOLED faces, read the installed `doc/docs/Connect_IQ_FAQ/How_Do_I_Make_a_Watch_Face_for_AMOLED_Products.html`. Use its device-specific guidance and simulator heat-map/power-mode tools. Do not assume a single always-on rule applies to every generation or that a watch-app screenshot validates watch-face power use.

## Pick validation to match the change

Language math/null behavior → Run No Evil tests. Layout/input → simulator on representative shapes and input capabilities. Settings/storage → missing/old data and restart. Background/network → foreground handoff and unavailable data. Watch faces → active/low-power transitions and AMOLED protection. Recording/sensors/phone transport → hardware verification in addition to simulator checks.

Record simulator assumptions such as injected sensor readings. Do not infer a physical test from SDK device-profile availability. Release export should cover the intended manifest product set; two representative simulator targets are not proof that every Garmin device is supported.

Sources: installed `doc/docs/Connect_IQ_Basics/App_Types.html`, `Core_Topics/Manifest_and_Permissions.html`, `Build_Configuration.html`, `Resources.html`, `Backgrounding.html`, and relevant `doc/Toybox` classes. Online starting points: [app types](https://developer.garmin.com/connect-iq/articles/connect-iq-basics/App_Types.html), [resources](https://developer.garmin.com/connect-iq/articles/core-topics/Resources.html), [manifest and permissions](https://developer.garmin.com/connect-iq/articles/core-topics/Manifest_and_Permissions.html).
