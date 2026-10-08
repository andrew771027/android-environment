# 測試指南 — v0.4.2

目前測試原始碼定義 22 個 mock 案例與 2 個整合案例。pytest 透過子程序呼叫 Bash 函式或 SDK 工具；mock 不需要真實 SDK，整合案例需要已建立的 AVD 與完成開機的 emulator。

## 準備環境

[pyproject.toml](../pyproject.toml) 宣告 Python >= 3.14、pytest >= 9.1.1 且 < 10.0.0。從專案根目錄執行：

```bash
python3.14 -m venv .venv
source .venv/bin/activate
python -m pip install 'pytest>=9.1.1,<10.0.0'
```

已有 `.venv` 時可用 `source script.sh` 啟用。`make unit-test` 優先使用 `.venv/bin/python`，否則使用 `python3`；也可指定 `make unit-test PYTHON=/path/to/python`。

## 指令與目前狀態

| 範圍 | 指令 | 原始碼案例數 | 目前限制 |
| --- | --- | --- | --- |
| 全部 mock | `make unit-test` | 22 | 22 passed；2 個整合案例被排除 |
| Mock 詳細輸出 | `python -m pytest -v -m "not integration" tests` | 22 | 同上 |
| 可執行 mock 子集 | `python -m pytest -q tests/test_emulator_lib.py tests/test_kvm.py tests/test_headless.py` | 17 | 不包含 acceleration 模組 |
| 整合案例 | `python -m pytest -v tests/test_emulator_integration.py` | 2 | 使用者回報兩個案例皆通過；需 SDK、AVD 與 online emulator |
| 全部案例 | `python -m pytest -v tests` | 24 | 整合案例需 SDK／AVD／online emulator；本次未執行全部案例 |

22 個 mock 與 2 個整合案例已分別通過，合計涵蓋全部 24 個現有案例；未提供單次執行全部案例的結果。`integration` marker 只分類測試，不會依環境自動跳過。也可用 `python -m pytest -v -m integration tests` 選擇整合案例；直接指定檔案讓執行範圍更明確。

## Mock 涵蓋範圍

| 測試檔 | 案例數 | 驗證內容 |
| --- | --- | --- |
| [test_emulator_lib.py](../tests/test_emulator_lib.py) | 6 | 第一台 online emulator 的 serial、沒有 emulator、boot property、等待超時 |
| [test_kvm.py](../tests/test_kvm.py) | 4 | KVM 路徑存在／缺少、acceleration 指令成功／失敗 |
| [test_headless.py](../tests/test_headless.py) | 7 | 固定 serial、boot ready/not ready、等待成功／超時、AVD 名稱解析、status 的 ADB-listing 失敗處理 |
| [test_acceleration.py](../tests/test_acceleration.py) | 5 | macOS acceleration 成功／失敗、emulator 存在／缺少及 macOS dispatch；五個案例皆通過 |

Mock 在 `tmp_path` 建立假的 `adb`、`emulator` 或 `uname`，放到子程序 `PATH` 最前面。KVM 路徑測試使用一般暫存檔，不是 `/dev/kvm`；timeout 案例仍會真正 `sleep`。

Headless 函式測試的假 ADB 固定回傳 `device` 狀態，未涵蓋 offline、missing serial 或錯誤 AVD。新增的 status 案例執行真正的 `headless_status.sh`，確認 `adb devices` 失敗時退出碼為 1，而且不誤報 `STOPPED`。AVD 名稱案例驗證第一行名稱及 CRLF 清理。

Desktop timeout 案例以 Bash `if` 包裝等待函式：子程序回傳 0，最後一行 `TIMEOUT` 才是進入失敗分支的依據；headless 等待案例直接檢查退出碼。

## Acceleration 修正與已知限制

[test_acceleration.py](../tests/test_acceleration.py) 的 macOS dispatch assertion 已將 `Chcek` 修正為 `Check`，與 script 實際成功訊息一致。修正後全部 mock 案例通過。

文件更新開始時曾因 subprocess 參數清單中的分號造成收集階段 `SyntaxError`；工作區隨後修正了語法，最新執行已能收集全部 22 個 mock 案例。

[acceleration.sh](../scripts/lib/acceleration.sh) 的 `check_macos_acceleration` 還有 `retrun 1` 拼字錯誤；當 emulator 缺少時，預期的提前 return 無法執行。目前 missing-emulator 案例只測 `check_emulator_exists`，不涵蓋這條 helper 路徑。目前已修正 dispatch assertion，尚未修正 helper 的這條未測試路徑。

## 整合測試

[test_emulator_integration.py](../tests/test_emulator_integration.py) 驗證：

1. `emulator -list-avds` 包含硬編碼的 `cookbook_pixel_api_36`。
2. 第一台 ADB 狀態為 `device` 的 emulator 回報 `sys.boot_completed=1`。

測試不安裝 SDK、不建立 AVD、不啟動 emulator。先完成 [setup](./setup.md)，在自己的 terminal 啟動：

```bash
make create-avd
make headless-start
python -m pytest -v tests/test_emulator_integration.py
```

macOS 與 Linux x86_64 可使用 headless；桌面模式可改用 `make emulator-start`。這兩個案例不驗證 headless flags、固定 serial、acceleration 或停止行為。AVD listing 與 boot 案例獨立，不能證明正在執行的就是設定中的 AVD。

## 驗證紀錄

2026-10-08，macOS 文件更新時：

- 最新 `make unit-test`：`22 passed, 2 deselected in 9.86s`，退出碼為 0。`deselected` 為 marker 排除的兩個整合案例。
- 可執行的三個 mock 模組：17 個案例通過，見下方指令。
- 使用者於 2026-10-08 回報兩個整合案例皆通過：baseline AVD listing 與 online emulator 的 boot completion。未提供整合測試耗時、完整輸出或確切指令，因此此處記錄為使用者回報，沒有推定為單次 `24 passed` 的執行結果。
- 文件更新本身未重新執行整合測試，也未啟動或停止 emulator。

```bash
python3 -m pytest -q tests/test_emulator_lib.py tests/test_kvm.py tests/test_headless.py
```

同日稍早的 macOS Intel 操作曾建立 baseline AVD，且 headless launch 回報 `READY: cookbook_pixel_api_36 (emulator-5554)`。後續確認 process 已消失、ADB 清單為空，因此該次結果只支持啟動當下的 readiness；沒有證明持續執行或完整啟停流程。

歷史紀錄：2026-09-23 的 v0.4.1 mock suite 為 `16 passed, 2 deselected`。這是當時版本結果，不代表目前 22 個 mock 案例皆通過。

尚未驗證真實 Linux/KVM、Apple Silicon、provisioning scripts、KVM 讀寫權限、desktop start/stop/reset、headless start/stop 端到端流程。Mock 通過不能替代主機實測。Smoke runner 與 CI 不在 v0.4.2 範圍內。

## 排查失敗

| 問題 | 處理方式 |
| --- | --- |
| macOS dispatch assertion 失敗 | 比對 expected 與 script 實際成功訊息；目前預期為 `macOS Emulator Acceleration Check PASSED` |
| 找不到 pytest | 確認 Make 選用的 Python 已安裝 pytest |
| 找不到 SDK 工具 | 檢查 `PATH`，執行 `make doctor` |
| AVD 不存在 | `make create-avd`，確認名稱符合測試預期 |
| ADB 空清單 | 在自己的 terminal 啟動 emulator；查看啟動輸出與 log |
| Boot property 不是 `1` | 等待開機，查看對應 emulator log |

單一案例可指定 node ID：

```bash
python -m pytest -v tests/test_headless.py::test_status_reports_adb_failure
```
