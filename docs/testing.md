# 測試指南

Android Environment v0.4.1 使用 pytest 呼叫 Bash 函式或 Android SDK 工具。Mock 測試不需要 SDK；整合測試需要已建立的 AVD 與完成開機的 emulator。

## 準備環境

[pyproject.toml](../pyproject.toml) 宣告 Python >= 3.14、pytest >= 9.1.1 且 < 10.0.0。從專案根目錄執行：

```bash
python3.14 -m venv .venv
source .venv/bin/activate
python -m pip install 'pytest>=9.1.1,<10.0.0'
```

已有 `.venv` 時，可用 `source script.sh` 啟用。`make unit-test` 優先使用 `.venv/bin/python`，否則使用 `python3`。也可以指定直譯器：

```bash
make unit-test PYTHON=/path/to/python
```

## 執行測試

| 範圍 | 指令 | 案例數 |
| --- | --- | --- |
| Mock 測試 | `make unit-test` | 16 |
| Mock 測試，顯示各案例 | `python -m pytest -v -m "not integration" tests` | 16 |
| 整合測試 | `python -m pytest -v -m integration tests` | 2 |
| 全部測試 | `python -m pytest -v tests` | 18 |

`integration` marker 只分類測試，不會依環境自動跳過。直接執行全部測試時，SDK 或 emulator 不可用會造成測試失敗。

## Mock 測試涵蓋範圍

| 測試檔 | 案例數 | 驗證內容 |
| --- | --- | --- |
| [test_emulator_lib.py](../tests/test_emulator_lib.py) | 6 | Serial 查找、沒有 emulator、已完成或未完成開機、等待超時 |
| [test_kvm.py](../tests/test_kvm.py) | 4 | KVM 路徑存在或缺少、acceleration 指令成功或失敗 |
| [test_headless.py](../tests/test_headless.py) | 6 | 指定 serial 存在、boot ready/not ready、等待成功或超時、AVD 名稱解析 |

測試在 `tmp_path` 建立假的 `adb` 或 `emulator` 指令，把該目錄放在子程序 `PATH` 最前面，再 source 真正的 Bash 函式庫。KVM 存在性測試使用一般暫存檔，並非 `/dev/kvm`。Timeout 案例仍會執行真正的 `sleep`。

Headless 的假 ADB 固定回傳 `device` 狀態，因此現有案例沒有涵蓋 offline、missing serial、錯誤 AVD、ADB 失敗或拒絕關機的流程。AVD 名稱測試驗證第一行的名稱，並去掉 CRLF 與後面的 `OK`。

Desktop timeout 測試以 Bash `if` 包裝等待函式；包裝程序回傳 0，最後一行 `TIMEOUT` 才是進入失敗分支的依據。Headless 測試則直接檢查函式的退出碼。

## 整合測試

[test_emulator_integration.py](../tests/test_emulator_integration.py) 驗證兩件事：

1. `emulator -list-avds` 的輸出包含 `cookbook_pixel_api_36`。
2. 第一台 ADB 狀態為 `device` 的 emulator 回報 `sys.boot_completed=1`。

測試不會安裝 SDK、建立 AVD 或啟動 emulator。先完成 [setup](./setup.md)，再執行：

```bash
make emulator-start
python -m pytest -v -m integration tests
```

Linux x86_64 可改用 `make headless-start`。但這兩個測試不會檢查 headless flags、固定 serial、KVM 或停止行為。AVD 存在測試和 boot 測試彼此獨立，不能證明正在執行的就是設定中的 AVD。

## 驗證紀錄

2026-09-23，在 macOS 執行現有 `make unit-test`：

```text
16 passed, 2 deselected in 7.44s
```

這次未執行兩個整合測試，也未驗證真實 Linux/KVM 或完整 headless 啟停流程。`deselected` 表示被 marker 篩選排除。

目前沒有涵蓋 provisioning scripts、KVM 讀寫權限、desktop start/stop/reset 或 headless entry-point scripts 的端到端測試。Mock 測試通過不能替代主機實測。

## 排查失敗

| 問題 | 處理方式 |
| --- | --- |
| 找不到 pytest | 確認 Make 選用的 Python 已安裝 pytest |
| 找不到 SDK 工具 | 檢查 `PATH`，執行 `make doctor` |
| AVD 不存在 | 執行 `make create-avd`，確認名稱符合測試預期 |
| 沒有 online emulator | 先啟動 emulator，再確認 `adb devices` |
| Boot property 不是 `1` | 等待開機並查看對應的 emulator log |

只調查單一測試時，可使用 pytest 的 node ID，例如：

```bash
python -m pytest -v tests/test_headless.py::test_avd_name_for_serial
```
