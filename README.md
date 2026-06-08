# ai-studio
Desktop app, cross platform, Chat like codex but more than chat

# Build

```bash
flutter build macos --release && mkdir -p /tmp/ai_studio_dmg && cp -R "build/macos/Build/Products/Release/ai_studio.app" /tmp/ai_studio_dmg/ && ln -s /Applications /tmp/ai_studio_dmg/Applications && hdiutil create -volname "AI Studio" -srcfolder /tmp/ai_studio_dmg -ov -format UDZO ai-studio-macos.dmg && rm -rf /tmp/ai_studio_dmg
```