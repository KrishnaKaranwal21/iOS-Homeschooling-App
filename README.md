# Learnook (Homeschool)

SwiftUI app for NIOS homeschooling families. Open `Homeschool.xcodeproj`, pick the **Homeschool** scheme and run.
Requires Xcode with the iOS 18.0 SDK or later; the deployment target is **iOS 18.0**, set once at project level.

The target uses Xcode's folder-synchronised group, so files added to or moved within `Homeschool/` are picked up
automatically. There is nothing to register in the project file.

## Project layout

```
Homeschool/
├── App/            App entry point, root flow switcher, tab bar, global pop-up
├── State/          AppState (single observable store), split into focused extensions
├── Models/         Plain value types, no UI
│   ├── Family/       Child, Account, PhoneNumber
│   ├── NIOS/         Age rules, curriculum rules + catalogue, syllabus, task ideas, activity guides, exams
│   ├── Learning/     Weekly plan, progress, Home tasks
│   ├── Gather/       Event, questions, registration, booking QR code, Place
│   ├── Community/    Parents, notifications
│   └── Chat/         Threads, messages, labels
├── Services/       Persistence, reminders, location, auth, chat store, sample data
├── DesignSystem/   Theme, typography, view styles, reusable components, mascot
├── Features/       One folder per screen group (views only)
│   └── Auth · Onboarding · ChildSetup · Home · Planner · Progress · Syllabus
│       Gather · Community · Chats · Profile
├── Resources/      NIOSSyllabus.json
├── Localizable.xcstrings   String Catalog (English only)
├── PrivacyInfo.xcprivacy   Privacy manifest (UserDefaults access, no tracking, no data collected)
└── Assets.xcassets
Docs/               Design notes and syllabus sources
```

Large screens are split into `Type.swift` plus `Type+Area.swift` extensions (for example `ProfileView+Children.swift`).
Members that the extensions share are internal, not `private`.

## Conventions

- One primary type per file, named after the file. Small private helpers live next to the view that uses them;
  shared helpers go to `DesignSystem` or the feature's `*Components.swift`.
- `AppState` keeps all stored properties in `State/AppState.swift` (`@Observable` cannot synthesise
  observation for stored properties declared in extensions). Behaviour lives in `AppState+<Area>.swift`.
- `///` documents what a declaration is for. `//` is only used inside code for a *why* that the code
  cannot show. `// MARK: -` separates sections, `// TODO:` marks prototype-only code.
- Views never talk to `UserDefaults`, Keychain or notifications directly; they go through `AppState` or a service.

## Appearance, accessibility and localisation

- **Light appearance only, on purpose.** The pastel palette and illustrations were designed on a warm off-white page and
  many screens use inline colours beside `Theme`. The lock lives in `HomeschoolApp` (`preferredColorScheme`) and the
  `UIUserInterfaceStyle = Light` build setting. Dark Mode needs a dark variant for every `Theme` token and inline colour
  (best as colour sets in `Assets.xcassets`), then removing both locks.
- **Dynamic Type.** Text uses `scaledFont`, which follows the text-size setting. Its `maxScale` cap protects tight layouts
  at standard sizes and is lifted to at least 2x once an accessibility size is chosen. A few sizes are deliberately
  proportional to their container (avatar initials, event artwork) and do not scale.
- **VoiceOver.** Icon-only buttons carry an `accessibilityLabel`; decorative chevrons are hidden.
- **Localisation.** `Localizable.xcstrings` lists the literal UI strings. The app is English only for now; add a language
  in the catalog and the project's Localizations list when that changes. Strings with interpolation are added by Xcode on the next build.
- **Privacy.** `PrivacyInfo.xcprivacy` declares `UserDefaults` access (reason `CA92.1`). Update it if you add a server,
  analytics or any other required-reason API.

## Prototype code

`MockData`, `AccountStore` and the simulated incoming chat message are prototype only and carry `// TODO:` notes. They
are meant to be replaced by a real backend.
