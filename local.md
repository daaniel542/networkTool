# Internal Desktop Distribution

Use native desktop builds for internal IT distribution. The browser build remains
useful for the non-ICMP utilities, but Ping and Traceroute need the local OS
networking stack.

## Build Matrix

Build on each target operating system:

```sh
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

Flutter desktop builds are OS-specific. A Mac can build macOS, a Windows machine
can build Windows, and a Linux machine can build Linux. Use dedicated build
machines or CI runners for each platform.

## Package Outputs

- macOS: zip `build/macos/Build/Products/Release/Elephant Network Tool.app`
- Windows: zip the full `build/windows/x64/runner/Release/` directory
- Linux: zip the full `build/linux/x64/release/bundle/` directory

Keep all generated files in the Windows and Linux release folders together; the
executables depend on the adjacent Flutter runtime files.

## macOS Notes

The app already declares network client entitlement in both debug/profile and
release entitlement files. For smooth company-wide installation, distribute a
signed and notarized build if the company Macs enforce Gatekeeper.

## Windows Notes

Windows does not need additional network entitlements for this app. For a better
IT rollout, wrap the release directory in an installer such as MSIX, Inno Setup,
or WiX after the first manual zip distribution is validated.

## Recommended Rollout

1. Build and smoke-test one release per OS.
2. Send a small pilot group the matching OS zip.
3. Confirm Ping, Traceroute, DNS, password generation, and encoding tools work on
   managed company devices.
4. Move to signed/notarized installers once the pilot is stable.
