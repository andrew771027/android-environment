# 測試指南 — v0.4.3

目前原始碼定義 28 個 mock 與 2 個整合案例。Mock 使用 pytest 呼叫 Bash helpers 或 status script，不需要真實 SDK，也不會啟動 emulator。整合案例需要 SDK、baseline AVD 與完成開機的 emulator。

## 準備環境

[pyproject.toml](../pyproject.toml) 宣告 Python >= 3.14、pytest >= 9.1.1 且 < 10.0.0。

```bash
python3.14 -m venv .venv
source .venv/bin/activate
python -m pip install 'pytest>=9.1.1,<10.0.0'
```

`make unit-test` 與 `make integration-test` 優先使用 `.venv/bin/python`，否則使用 `python3`。可指定 `PYTHON=/path/to/python`。已有 `.venv` 時可用 `source script.sh` 啟用。

## 執行指令

| 範圍 | 指令 | 案例數 | 需求 |
| --- | --- | --- | --- |
| Mock | `make unit-test` | 28 | Python、pytest、Bash；不需啟動 emulator |
| Mock 詳細輸出 | `python -m pytest -v -m "not integration" tests` | 28 | 同上 |
| 整合 | `make integration-test` | 2 | SDK、baseline AVD、online emulator |
| Build Tools helpers | `python -m pytest -v tests/test_build_tools.py` | 6 | 使用暫存檔，不需真實 Build Tools |
| 全部 | `python -m pytest -v tests` | 30 | 整合案例所需環境 |

`integration` marker 只分類測試，不會依主機環境自動跳過。Mock 與整合分別通過不代表曾單次執行全部 30 個案例。

## Mock 涵蓋範圍

| 測試檔 | 案例數 | 驗證內容 |
| --- | --- | --- |
| [test_emulator_lib.py](../tests/test_emulator_lib.py) | 6 | 第一台 online emulator 的 serial、沒有 emulator、boot property、等待超時 |
| [test_kvm.py](../tests/test_kvm.py) | 4 | KVM 路徑存在／缺少、acceleration 指令成功／失敗 |
| [test_headless.py](../tests/test_headless.py) | 7 | 固定 serial、boot readiness、等待成功／超時、AVD 名稱解析、status 的 ADB-listing 失敗處理 |
| [test_acceleration.py](../tests/test_acceleration.py) | 5 | macOS acceleration 成功／失敗、emulator 存在／缺少、macOS dispatch |
| [test_build_tools.py](../tests/test_build_tools.py) | 6 | Package ID、versioned directory、目錄存在／缺少、三個 required executables、缺少 zipalign |

Mock 將假的 `adb`、`emulator` 或 `uname` 放在子程序 `PATH` 最前面。KVM 路徑測試使用一般暫存檔，不是 `/dev/kvm`。Build Tools 案例使用暫存目錄與 `exit 0` executable stubs，不執行真實 binary。Timeout 案例仍會真正 `sleep`。

Headless status 的 ADB 失敗案例執行真正的 entry point，確認退出碼 1 且不誤報 `STOPPED`。其他 headless helper 案例未涵蓋 offline、missing serial 或錯誤 AVD。Desktop timeout 以 Bash `if` 包裝等待函式，最後一行 `TIMEOUT` 才是失敗分支依據；headless 等待案例直接檢查退出碼。

## 整合案例

[test_emulator_integration.py](../tests/test_emulator_integration.py) 檢查：

1. `emulator -list-avds` 包含硬編碼的 `cookbook_pixel_api_36`。
2. 第一台 ADB 狀態為 `device` 的 emulator 回報 `sys.boot_completed=1`。

案例不安裝 SDK、不建立 AVD、不啟動或停止 emulator。先完成 [setup](./setup.md)，在自己的 terminal 啟動：

```bash
make create-avd
make headless-start
make integration-test
```

若已有 ready emulator，直接執行整合測試即可；headless start 會拒絕重複啟動。桌面模式可用 `make emulator-start`。

AVD listing 與 boot 案例彼此獨立，不能證明正在執行的是設定中的 AVD，也不檢查 headless flags、固定 serial、acceleration 或 shutdown。

## v0.4.3 驗證紀錄

2026-10-08，在目前 macOS Intel 工作區執行：

| 指令 | 結果 |
| --- | --- |
| `make unit-test` | `28 passed, 2 deselected in 8.89s` |
| `make integration-test` | `2 passed, 28 deselected in 0.19s` |
| `make validate-build-tools` | Build Tools 36.0.0 目錄與 required executables 檢查通過 |

Mock 執行沒有啟動 emulator；整合測試使用既有 online emulator。上述結果均退出碼 0。`deselected` 是 marker 排除的案例，不是失敗或自動 skip。

本次沒有執行 Gradle build、APK 安裝、真實 Linux/KVM、Apple Silicon、完整 emulator 啟停或 provisioning 端到端測試。Build Tools validator 只檢查 Java command、目錄與執行權限，未執行工具。

## 已知限制

[acceleration.sh](../scripts/lib/acceleration.sh) 的 `check_macos_acceleration` 仍有 `retrun 1` 拼字錯誤。Emulator 缺少時，預期提前 return 無法執行。現有 missing-emulator 案例只測 `check_emulator_exists`，未涵蓋這條 helper 路徑；suite 通過不表示該問題已修正。

Build Tools 案例不涵蓋不可執行的 binaries、installer 的 SDK command 呼叫、部分安裝修復或完整 validator 流程。Smoke runner、CI、APK build verification 尚未實作。

## 排查失敗

| 問題 | 處理方式 |
| --- | --- |
| 找不到 pytest | 確認 Make 選用的 Python 已安裝 pytest |
| SDK 工具缺少 | 檢查 `PATH`，執行 `make doctor` |
| AVD 缺少 | 執行 `make create-avd`，確認名稱符合整合案例預期 |
| ADB 空清單 | 啟動 emulator，查看啟動輸出與 log |
| Boot property 不是 `1` | 等待開機，檢查 emulator log |
| Build Tools validator 失敗 | 確認版本目錄與三個 executable；見 [Build Tools](./build-tools.md) |

## Release 檢查

依 [commit_manual.md](../commit_manual.md)，更新 source、tests、README、docs、roadmap 與 project version，分別驗證 mock 與整合案例。Release tag 應指向包含已驗證內容的 release commit；修改中的工作區不會被 tag 收錄。這次文件更新沒有建立 commit 或 tag。
