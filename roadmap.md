# Android Environment roadmap

文件以 v0.4.2 的 source code 與 test code 為基準。下表區分已實作功能與後續計畫；已實作不代表所有主機都完成實測，測試狀態請見 [testing](./docs/testing.md)。

| 版本 | 範圍 | 狀態 |
| --- | --- | --- |
| v0.1 | SDK、adb、fastboot、emulator、AVD、doctor | 已實作基本 workstation tooling |
| v0.2 | API 設定、host-to-image mapping、跳過已安裝套件、環境驗證 | 已實作；SDK package revisions 未鎖定 |
| v0.3 | Desktop start、boot wait、status、stop、reset | 已實作；選第一台 online emulator，未驗證 AVD identity |
| v0.4.0 | Linux x86_64／KVM host check | 已實作；缺少真實 Linux/KVM 驗證 |
| v0.4.1 | 固定 port／serial 的 headless start、status、stop 與 AVD identity check | 已實作 shared lifecycle |
| **v0.4.2** | **macOS headless、跨平台 acceleration dispatch、status ADB-listing 錯誤處理** | **目前文件目標；22 個 mock 案例通過** |
| v0.4.3 | Smoke-test runner 與完整啟停／失敗路徑驗證 | 計畫中 |
| v0.4.4 | CI／GitHub Actions orchestration | 計畫中；目前沒有 workflow |
| v0.5 | Physical-device USB detection、ADB authorization、device info、fastboot detection | 計畫中；目前只有工具與手動指南 |
| v1.0 | 可重現的 Mac／Linux workstation、emulator／physical Pixel、health check、CI verification | 長期目標 |

## v0.4.2 實作範圍

- `make acceleration-check`：macOS 以 `emulator -accel-check` 檢查 acceleration；Linux 委派給既有 x86_64／KVM script。
- `make headless-start`：檢查 acceleration 與已存在的 AVD，在 port 5554 啟動，等待 boot completion 並驗證 AVD 名稱。
- `make headless-status`：查詢 `emulator-5554`；ADB listing 失敗回報錯誤，不誤報 `STOPPED`。
- `make headless-stop`：先檢查 readiness 與 AVD identity，再發出關機請求；不等待斷線。

## 目前驗證與待處理項目

原始碼定義 22 個 mock 與 2 個整合案例。修正 macOS dispatch assertion 的拼字後，最新 `make unit-test` 結果為 `22 passed, 2 deselected`。使用者於 2026-10-08 回報兩個整合案例也通過；mock 與 integration 分別執行，合計 24 個現有案例皆通過，未提供單次全部案例的執行結果。Helper 仍有未涵蓋於目前測試的 `retrun` 拼字錯誤。詳見 [測試指南](./docs/testing.md)。

macOS Intel 曾完成一次 headless launch 的 readiness check；尚未驗證完整 real start/status/stop、process persistence、Apple Silicon 或 Linux/KVM。v0.4.2 沒有 PID supervisor、timeout 自動清理、smoke runner 或 CI orchestration。

文件版本為 v0.4.2；`pyproject.toml` 的 Python package version 也為 `0.4.2`。Android CLI migration 與完整 SDK revision locking 尚未實作。
