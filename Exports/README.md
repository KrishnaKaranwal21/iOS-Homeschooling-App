# Opening the current app

Use the source project at the root of the `app2.0` branch for development:

```sh
git fetch origin
git switch app2.0
git pull --ff-only origin app2.0
git log -1 --oneline
open Homeschool.xcodeproj
```

If you already have unsaved local changes, keep them safe before switching branches.
In Xcode, check that the open project's location is this checkout, select the
Homeschool scheme, and build/run it on the intended simulator or device. The current
Progress screen has a **Day / Week / Month** picker. If it shows **Time / Activities**,
you are running an older project or app build. Use Product > Clean Build Folder and
build/run again; deleting the app and its saved learner data is unnecessary.

## ZIP snapshots

These ZIPs are snapshots, not live links to the repository:

- `HomeSchool-App.zip`: complete project; extract it and open its Homeschool.xcodeproj.
- `Progress-Section.zip`: Progress source and integration references, not a standalone app.
- `Gather-Section.zip`: Gather source and integration references, not a standalone app.

The archives were refreshed to include the Day / Week / Month Progress screen.
Each archive includes `EXPORT-SOURCE.txt` identifying its source commit and a
SHA256SUMS.txt manifest. Use a new extraction folder rather than an older extracted copy.
The homepage to-do images discussed in chat are design mockups and have not been coded.

Before distributing archives after changing source, verify they are current:

```sh
python3 Scripts/check-exports.py
```

This checks their source files against the checkout and verifies archive checksums.
