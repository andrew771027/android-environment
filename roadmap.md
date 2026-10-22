# Android Environment roadmap

目前文件與 `pyproject.toml` 的版本為 **v0.4.5**。已實作表示原始碼存在；實測範圍與限制請見 [testing](./docs/testing.md)。

| 版本 | 範圍 | 狀態 |
| --- | --- | --- |
| v0.1 | SDK、ADB、fastboot、emulator、AVD、doctor | 已實作基本 workstation tooling |
| v0.2 | API 設定、host-to-image mapping、跳過已安裝套件、環境驗證 | 已實作；SDK package revisions 未鎖定 |
| v0.3 | Desktop start、boot wait、status、stop、reset | 已實作；選第一台 online emulator，不檢查 AVD identity |
| v0.4.0 | Linux x86_64／KVM host check | 已實作；缺少真實 Linux/KVM 驗證 |
| v0.4.1 | 固定 port／serial 的 headless lifecycle、AVD identity check | 已實作 |
| v0.4.2 | macOS headless、跨平台 acceleration dispatch、status ADB 錯誤處理 | 已實作 |
| v0.4.3 | 選用 Build Tools 安裝／驗證、integration-test Make target | 已實作 |
| v0.4.4 | 六項 runtime smoke checks、headless-smoke | 已實作；不自動停止 emulator |
| **v0.4.5** | **本機 CI runner、PID tracking、owned cleanup、退出碼處理** | **目前版本；70 個單元案例、2 個整合案例** |
| v0.4.6 | 修正並啟用 hosted CI、分離 unit 與 emulator jobs、artifact reports | unit workflow 已設定；hosted 執行與 emulator job 尚待驗證 |
| v0.5 | Physical-device USB detection、ADB authorization、device info、fastboot detection | 計畫中；目前只有工具與手動指南 |
| v1.0 | 可重現 Mac／Linux workstation、emulator／physical Pixel、health check、CI verification | 長期目標 |

## v0.4.5 範圍

- `make ci-headless-smoke`：啟動 headless emulator、等待 READY、執行 smoke，退出時嘗試清理。
- CI 使用專屬暫存 PID 檔，啟動前被拒絕時保留既有 emulator；啟動後即使 boot 失敗仍嘗試清理。
- `headless_stop.sh --owned`：檢查 PID 對應的程序命令、AVD 與 port，以 TERM／KILL 清理，不依賴 Android 開機完成。
- 手動 `headless-stop`：維持 readiness 與 AVD identity 檢查，ADB shutdown 後增加 PID fallback。
- 分開顯示 workflow 與 cleanup exit code；保留原始失敗，原流程成功但 cleanup 失敗時也回傳失敗。
- 新增 13 個 process 案例與 7 個 CI cleanup 案例。案例使用 fake commands 或一般 host processes，不啟動 Android emulator。

預設仍為 API 36、Google APIs image、AVD `cookbook_pixel_api_36` 與選用 Build Tools 36.0.0。既有 `make smoke` 和 `make headless-smoke` 行為不變。

## 驗證與後續工作

2026-10-22 的執行結果與環境記錄於 [testing](./docs/testing.md)。整合案例使用既有 emulator，只檢查 AVD listing 與 boot completion；不代表完整啟停、owned cleanup 或所有平台已實測。

後續工作包括：

- `.github/workflows/ci.yml` 已修正目錄、Python 版本、Action references、unit selection 與 artifact 設定；推送後確認 hosted unit 結果，再規劃獨立 emulator job。
- 在 macOS Intel、Apple Silicon 與 Linux/KVM 驗證真實 start／smoke／stop、開機失敗與 signal 路徑。
- 補強程序身分與 PID reuse 處理、descendant supervision，以及 ADB calls 的 timeout。
- 修復部分 Build Tools 安裝、驗證實際工具執行，加入 Gradle build 與 APK 安裝測試。
- 評估 Android CLI migration 與完整 SDK revision locking。

## Release 狀態

依 [commit manual](./commit_manual.md)，release 需要 source、tests、README、docs、roadmap、project version 與驗證結果一致。版本已為 `0.4.5`；本次文件更新不建立 commit 或 tag。`v0.4.5` tag 應在 release commit 完成後指向該 commit，避免把未收錄的工作區修改誤認為已發布內容。
