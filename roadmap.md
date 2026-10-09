# Android Environment roadmap

目前文件目標為 v0.4.3。已實作表示程式已存在；實測範圍與限制請見 [testing](./docs/testing.md)。

| 版本 | 範圍 | 狀態 |
| --- | --- | --- |
| v0.1 | SDK、adb、fastboot、emulator、AVD、doctor | 已實作基本 workstation tooling |
| v0.2 | API 設定、host-to-image mapping、跳過已安裝套件、環境驗證 | 已實作；runtime package revisions 未鎖定 |
| v0.3 | Desktop start、boot wait、status、stop、reset | 已實作；選第一台 online emulator，不檢查 AVD identity |
| v0.4.0 | Linux x86_64／KVM host check | 已實作；缺少真實 Linux/KVM 驗證 |
| v0.4.1 | 固定 port／serial 的 headless lifecycle 與 AVD identity check | 已實作 |
| v0.4.2 | macOS headless、跨平台 acceleration dispatch、status ADB-listing 錯誤處理 | 已實作 |
| **v0.4.3** | **選用 Build Tools 36.0.0 安裝／驗證、6 個 Build Tools helper tests、integration-test Make target** | **目前版本；28 mock 與 2 integration 分別通過** |
| v0.4.4 | Smoke runner、完整啟停／失敗路徑與 CI orchestration | 計畫中；目前沒有 smoke runner 或 CI workflow |
| v0.5 | Physical-device USB detection、ADB authorization、device info、fastboot detection | 計畫中；目前只有工具與手動指南 |
| v1.0 | 可重現 Mac／Linux workstation、emulator／physical Pixel、health check、CI verification | 長期目標 |

## v0.4.3 範圍

- `make install-build-tools`：依 `ANDROID_BUILD_TOOLS_VERSION` 安裝套件；versioned directory 存在就跳過，不修復部分安裝。
- `make validate-build-tools`：檢查 Java command、Build Tools 目錄及 `aapt2`、`apksigner`、`zipalign` 的執行權限。
- `make integration-test`：執行 baseline AVD listing 與第一台 online emulator 的 boot-completion 案例。
- Build Tools 為選用功能；`make install-sdk` 與 runtime validator 不自動處理它。

預設 API 36、Google APIs image 與 AVD 不變。Build Tools 預設為 36.0.0；`config/build-packages.txt` 目前是參考清單，腳本直接使用 `config/android.env` 的設定。

## 驗證與後續工作

2026-10-08，macOS Intel 實測 unit 為 `28 passed, 2 deselected`，integration 為 `2 passed, 28 deselected`，Build Tools validator 通過。整合測試使用既有 emulator，沒有執行完整啟停。未執行 Gradle build、APK 安裝、Linux/KVM 或 Apple Silicon 驗證。

後續工作包括修正 acceleration helper 的 `retrun` 未測試路徑、部分 Build Tools 安裝修復、tool execution checks、APK build verification、process supervision、timeout cleanup、smoke runner 與 CI。Android CLI migration 與完整 SDK revision locking 尚未實作。

文件與 `pyproject.toml` 的版本均為 v0.4.3。依 [commit manual](./commit_manual.md)，release tag 應在包含驗證內容的 commit 完成後建立；本次文件更新未建立 commit 或 tag。
