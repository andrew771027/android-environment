# Android Environment roadmap

目前文件目標為 v0.4.4。已實作表示程式已存在；實測範圍與限制請見 [testing](./docs/testing.md)。

| 版本 | 範圍 | 狀態 |
| --- | --- | --- |
| v0.1 | SDK、adb、fastboot、emulator、AVD、doctor | 已實作基本 workstation tooling |
| v0.2 | API 設定、host-to-image mapping、跳過已安裝套件、環境驗證 | 已實作；runtime package revisions 未鎖定 |
| v0.3 | Desktop start、boot wait、status、stop、reset | 已實作；選第一台 online emulator，不檢查 AVD identity |
| v0.4.0 | Linux x86_64／KVM host check | 已實作；缺少真實 Linux/KVM 驗證 |
| v0.4.1 | 固定 port／serial 的 headless lifecycle 與 AVD identity check | 已實作 |
| v0.4.2 | macOS headless、跨平台 acceleration dispatch、status ADB-listing 錯誤處理 | 已實作 |
| v0.4.3 | 選用 Build Tools 36.0.0 安裝／驗證、6 個 Build Tools helper tests、integration-test Make target | 已實作；歷史驗證見 testing |
| **v0.4.4** | **Smoke runner、headless-smoke、19 個 smoke tests** | **目前版本；50 mock、2 integration 與真實 smoke 通過** |
| 後續 v0.4.x | 完整啟停／失敗路徑、timeout cleanup 與 CI orchestration | 計畫中 |
| v0.5 | Physical-device USB detection、ADB authorization、device info、fastboot detection | 計畫中；目前只有工具與手動指南 |
| v1.0 | 可重現 Mac／Linux workstation、emulator／physical Pixel、health check、CI verification | 長期目標 |

## v0.4.4 範圍

- `make smoke`：檢查固定 serial 的 ADB、boot、numeric SDK、non-empty model、Package Manager 與 shell。
- `make headless-smoke`：先啟動 headless，再 smoke；不自動停止或清理。
- 桌面 start 使用 AVD graphics settings，預設停用 boot animation，log 寫入 `artifacts/emulator.log`。
- 19 個 smoke tests，包含 boot 未完成、ADB 失敗但輸出有效，以及 runner 成功／失敗；另補 headless start／stop 的 ADB 失敗與 acceleration 提前返回測試。沒有完整 lifecycle end-to-end 或 CI。

2026-10-15 重驗：unit `50 passed, 2 deselected`；integration `2 passed, 50 deselected`；真實 smoke 六項通過。沙箱外 ADB 確認 `emulator-5554` 為 `cookbook_pixel_api_36`，SDK `36`。使用既有 emulator，未驗證完整啟停、headless-smoke 或跨平台行為；詳見 [testing](./docs/testing.md)。

## v0.4.3 已有功能

- `make install-build-tools`：依 `ANDROID_BUILD_TOOLS_VERSION` 安裝套件；versioned directory 存在就跳過，不修復部分安裝。
- `make validate-build-tools`：檢查 Java command、Build Tools 目錄及 `aapt2`、`apksigner`、`zipalign` 的執行權限。
- `make integration-test`：執行 baseline AVD listing 與第一台 online emulator 的 boot-completion 案例。
- Build Tools 為選用功能；`make install-sdk` 與 runtime validator 不自動處理它。

預設 API 36、Google APIs image 與 AVD 不變。Build Tools 預設為 36.0.0；`config/build-packages.txt` 目前是參考清單，腳本直接使用 `config/android.env` 的設定。

## 驗證與後續工作

2026-10-08，macOS Intel 實測 unit 為 `28 passed, 2 deselected`，integration 為 `2 passed, 28 deselected`，Build Tools validator 通過。整合測試使用既有 emulator，沒有執行完整啟停。未執行 Gradle build、APK 安裝、Linux/KVM 或 Apple Silicon 驗證。

後續工作包括部分 Build Tools 安裝修復、tool execution checks、APK build verification、process supervision、timeout cleanup、smoke runner 測試補強與 CI。Android CLI migration 與完整 SDK revision locking 尚未實作。

文件與 `pyproject.toml` 的版本均為 v0.4.4。依 [commit manual](./commit_manual.md)，release tag 應在包含驗證內容的 commit 完成後建立；本次文件更新未建立 commit 或 tag。
