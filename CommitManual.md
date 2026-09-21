# Commit Manual

這份清單用於整理 Android Environment 的提交與版本發布。一般 commit 依變更範圍完成相關項目；版本 tag 則在該版本驗證完成後建立。以下命令為操作指南，不代表已執行或驗證通過。

## 1. 確認變更範圍

從專案根目錄查看工作目錄與差異：

```bash
git status --short
git diff --stat
git diff
```

`git diff` 不會顯示尚未追蹤檔案的內容，需另外檢查 `git status` 列出的新檔案。

- [ ] 說明這次解決的問題、預期行為與影響範圍。
- [ ] 每個 commit 聚焦在可獨立理解、驗證的變更。
- [ ] 確認新檔案、刪除檔案與執行權限都符合預期。
- [ ] 排除本機 SDK、AVD、虛擬環境、測試暫存檔與執行紀錄。
- [ ] 檢查 `.gitignore`、IDE 設定等修改是否屬於此次提交。

## 2. Source Code

- [ ] 腳本、共用函式、設定與 Makefile 使用一致的變數和指令名稱。
- [ ] Makefile recipe 使用 Tab；操作用 targets 列入 `.PHONY`。
- [ ] 外部指令失敗、無效設定與逾時能回傳非零狀態。
- [ ] Emulator 流程核對開機狀態與目標身分，清理時只處理自己啟動的程序。
- [ ] 保留仍支援的 macOS / Linux 本機流程。

依修改範圍執行語法與命令展開檢查。例如 v0.4：

```bash
for script in scripts/check_kvm.sh scripts/install_cmdline_tools_linux.sh \
  scripts/lib/ci_emulator.sh scripts/run_headless_smoke.sh scripts/smoke_test.sh; do
  bash -n "$script" || break
done
make -n linux-tools install-sdk create-avd kvm-check headless-smoke unit-test test
git diff --check
```

`bash -n` 只檢查語法；`make -n` 只顯示預計執行的命令。兩者都不能證明執行結果正確。

## 3. Test Code 與驗證

測試環境與案例說明見 [docs/testing.md](./docs/testing.md)。

| 驗證層級 | 命令 | 前提與判定 |
| --- | --- | --- |
| Mock / 離線案例 | `python -m pytest -v -m "not integration"` | 先確認假 adb 隔離有效，避免呼叫真實 SDK 工具 |
| 既有整合案例 | `python -m pytest -v -m integration` | SDK、設定中的 AVD 與已開機的 emulator |
| 離線測試入口 | `make unit-test` 或 `make test` | 排除 integration；全部測試使用 `python -m pytest -v tests` |
| Linux headless smoke | `make kvm-check` 後執行 `make headless-smoke` | Linux x86_64、KVM、SDK、AVD 與隔離 runner |

- [ ] 測試涵蓋這次修改的正常流程與相關失敗條件。
- [ ] 記錄執行命令、環境、結果與未執行項目的原因。
- [ ] 修正失敗原因後重跑受影響的測試。
- [ ] 真實 smoke 確認 API、`sys.boot_completed=1`、AVD identity、檔案讀寫與程序清理。
- [ ] CI job 結果與 emulator logs 支持版本完成的宣稱。

離線測試通過不能推論 KVM 或真實 emulator 整合通過；未執行的驗證請明確標記為未驗證。

## 4. Docs、README 與 Roadmap

文件以讀者能直接理解和操作為目標：先寫用途與前提，再提供步驟、預期結果和必要的限制。

| 文件 | 檢查重點 |
| --- | --- |
| [setup.md](./docs/setup.md) | 安裝順序、相依套件、設定、可執行命令與完成條件 |
| [testing.md](./docs/testing.md) | 測試入口、環境需求、覆蓋範圍與驗證限制 |
| [Linux KVM](./docs/linux-kvm.md)、[headless lifecycle](./docs/headless-lifecycle.md) | KVM 前提、隔離、readiness、逾時與清理行為 |
| [readme.md](./readme.md) | 版本介紹、快速開始、指令表與文件連結 |
| [roadmap.md](./roadmap.md) | 區分已完成、進行中與未來規劃，避免將未驗證功能寫成完成 |

- [ ] 命令、路徑、設定名稱與目前實作一致。
- [ ] Markdown 標題、程式碼區塊、表格與相對連結正確。
- [ ] 更新已過時的整合狀態、案例數與版本說明。
- [ ] 驗證紀錄能辨識其適用版本或環境，避免讓舊結果看似本次結果。

## 5. 整理並建立 Commit

明確選取此次要提交的檔案，再檢查暫存區。例如只提交本指南：

```bash
git add CommitManual.md
git diff --cached --stat
git diff --cached
git diff --cached --check
git commit -m "docs: organize commit and release checklist"
```

提交前確認暫存區沒有混入其他變更。Commit message 說明具體結果；較大的修改可在內文補充原因、驗證方式與已知限制。

| 類型 | 適用變更 |
| --- | --- |
| `feat` | 新功能 |
| `fix` | 行為修正 |
| `test` | 測試案例或 helper |
| `docs` | 文件 |
| `ci` | CI workflow |
| `chore` | 維護設定與工具 |

## 6. 版本發布與 Tag

Tag 用來標記可辨識的版本，不需要每個 commit 都建立。發布前：

- [ ] 版本範圍內的程式、測試與文件已提交。
- [ ] 檢查 README、roadmap 與套件版本資訊是否符合本次發布範圍。
- [ ] 對應 commit 的必要 CI jobs 已通過，相關限制已記錄。
- [ ] 確認 tag 指向預期 commit，且版本名稱尚未使用。

以下以 `v0.4.0` 為例，實際使用時依專案版本命名調整：

```bash
git status --short
git log -1 --oneline
git tag --list 'v0.4*'
git tag -a v0.4.0 -m "Android Environment v0.4 — CI / Headless"
git show --stat v0.4.0
```

確認發布版本後，推送目前分支與該 tag：

```bash
git push
git push origin v0.4.0
```

## v0.4 發布前待驗證

Makefile、CI Python 版本、設定名稱、headless 啟動與清理、測試 helper 及文件入口已同步。發布前仍需：

- [ ] 執行離線測試並記錄結果。
- [ ] 在 Linux x86_64 / KVM runner 完成真實 smoke，確認 emulator 與暫存檔清理。
- [ ] 檢查對應 commit 的 GitHub Actions 結果與 artifacts，再標記版本完成。
