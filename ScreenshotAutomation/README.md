# Screenshot automation

Run the complete capture and post-processing pipeline from the repository root:

```sh
swift ScreenshotAutomation/ScreenshotExportScript.swift
```

The script captures deterministic light, settings, and dark-mode screens for
the configured iPhone and iPad simulators. It then exports exact App Store PNG
dimensions under `screenshots/en-US/`, adding a localized marketing caption and
a programmatically rendered device bezel.

If your installed simulator names differ, override them without editing source:

```sh
SCREENSHOT_IPHONE_SIMULATOR="iPhone 17 Pro Max" \
SCREENSHOT_IPAD_SIMULATOR="iPad Pro 13-inch (M5)" \
SCREENSHOT_SIMULATOR_OS="26.5" \
swift ScreenshotAutomation/ScreenshotExportScript.swift
```
