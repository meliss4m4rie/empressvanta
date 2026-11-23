# Y2K Dollmaker Studio / Pocket Y2K Dollmaker

Desktop (Windows) and Android (APK) builds for **Y2K Dollmaker Studio** and **Pocket Y2K Dollmaker**.

## Downloads & Related Projects
- **iOS Build (`v1.0.0` — Unsigned `App.app` archive):** https://github.com/meliss4m4rie/y2k-dollmaker-studio-ios/releases/tag/v1.0.0
- **Empress Vanta Web & Dollmaker Repo:** https://github.com/meliss4m4rie/empressvanta
- **Dollz Vault Assets Repo:** https://github.com/meliss4m4rie/dollz-vault
- **Empress Vanta Neocities Portal:** https://empressvanta.neocities.org

## Windows
- Download the Windows release package from this repository's **Releases** tab and run the executable! 

## Android (APK)
- Download the `.apk` release asset from this repository's **Releases** tab.
- On your Android device, allow installation from your browser or file manager when prompted, then open the `.apk` to install.

## iOS (Unsigned Build Artifact)
The iOS bundle is hosted separately at https://github.com/meliss4m4rie/y2k-dollmaker-studio-ios/releases/tag/v1.0.0 as an **unsigned** `App.app` archive (compiled via GitHub Actions on `macos-15` with `xcodebuild` and `CODE_SIGNING_ALLOWED=NO`).

- **Not a direct-install `.ipa`:** Because it is an unsigned `.app` bundle rather than a signed `.ipa`, it cannot be installed directly onto a standard iPhone out of the box.
- **macOS + Xcode required:** Signing, building, and installing onto an iPhone requires **macOS and Xcode** with your own Apple signing/provisioning setup.


## Issues & Bug Reports

Found a bug or something broken? Open an issue in the repository and include:
- **Platform & build:** Which version or archive you used (Windows, Android APK, or the iOS `v1.0.0` `App.app` archive).
- **What happened vs. what you expected:** Steps to reproduce, error messages, or screenshots/screen recordings if helpful.

### Before You Open an iOS Issue
- **Unsigned `.app` bundle:** The iOS release (`App.app`) is built with `CODE_SIGNING_ALLOWED=NO` and is **not** a signed `.ipa`. Direct installation on a standard iPhone without signing/packaging on **macOS + Xcode** is expected to fail and is not a bug.
- **Signing & Xcode setup:** Apple signing, provisioning profiles, and device deployment require macOS and Xcode with your own Apple signing setup.
