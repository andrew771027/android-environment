# 測試指南

測試使用 pytest 執行 Python 測試，再透過 subprocess 呼叫 Bash 或 Android SDK 工具。依據 [pytest.ini](../pytest.ini)，`integration` marker 表示測試需要真實 Android SDK 或 emulator。

## 準備 Python 環境

[pyproject.toml](../pyproject.toml) 宣告 Python >= 3.14，pytest >= 9.1.1 且 < 10.0.0。從專案根目錄執行；如果尚未建立虛擬環境：

```bash
python3.14 -m venv .venv
source .venv/bin/activate
python -m pip install 'pytest>=9.1.1,<10.0.0'
```

已有 `.venv` 時可以使用現有的 [script.sh](../script.sh)：

```bash
source script.sh
```

必須使用 `source` 才會改變目前 shell 的環境。`bash script.sh` 只會在子 shell 啟用環境。也可以直接使用 `.venv/bin/python -m pytest`，避免選錯 Python。

## 執行方式

| 目的 | 命令 | 前提 |
| --- | --- | --- |
| Mock 測試 | `python -m pytest -v -m "not integration"` | Python、pytest、Bash 與基本 shell 工具；不需要真實 emulator |
| 整合測試 | `python -m pytest -v -m integration` | SDK 工具、baseline AVD、已開機的 emulator |
| 全部測試 | `python -m pytest -v tests` 或 `make test` | 同整合測試；make 使用 PATH 中的 pytest |
| 單一 timeout 測試 | `python -m pytest -v tests/test_emulator_lib.py::test_wait_for_emulator_boot_timeout` | 同 Mock 測試 |

Marker 只分類測試，不會自動跳過。`make test` 執行全部測試，沒有 emulator 時整合測試會失敗。

## Mock 測試：6 個案例

[test_emulator_lib.py](../tests/test_emulator_lib.py) 在 pytest 的 `tmp_path` 建立可執行的假 `adb`，將其目錄放在複製後的 `PATH` 最前面，再用 Bash source 真正的 `scripts/lib/emulator.sh`。測試不會呼叫真實 adb，也不會啟動或停止真實 emulator。

| 案例 | 驗證內容 |
| --- | --- |
| 查找 serial | 同時有 emulator 與實體裝置時取得 emulator serial |
| 沒有 emulator | 只有實體裝置時輸出空字串 |
| 已完成開機 | 假 adb 回傳 `1` 時得到 `READY` |
| 尚未完成開機 | 假 adb 回傳 `0` 時得到 `NOT_READY` |
| 沒有裝置 | 開機判定為 false |
| 等待超時 | 沒有 emulator 時，以 2 秒預算、1 秒間隔進入 `TIMEOUT` 分支 |

Timeout 案例仍使用真正的 sleep。Bash 測試包裝以 `if ...; then ...; else echo TIMEOUT; fi` 執行，所以 `result.returncode == 0` 是包裝腳本的退出碼；最後一行 `TIMEOUT` 才證明等待函式回傳失敗。

目前未涵蓋 start/stop/reset 腳本端到端行為、等待途中變為 READY、多 emulator 選取、offline 狀態與 ADB 指令失敗。

## 整合測試：2 個案例

[test_emulator_integration.py](../tests/test_emulator_integration.py) 直接執行 SDK 工具，不會自動建立、啟動、等待或停止 emulator。

1. `test_configured_emulator_exists`：確認 `emulator -list-avds` 的輸出包含 `cookbook_pixel_api_36`。此名稱目前寫死在測試中，沒有讀取 `config/android.env`。
2. `test_running_emulator_is_boot_completed`：從 `adb devices` 取第一個 online emulator，確認其 `sys.boot_completed` 為 `1`。不會核對該 serial 是否對應上述 AVD。

先準備 SDK、AVD 和執行中的 emulator：

```bash
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
source script.sh
make create-avd
make emulator-start
python -m pytest -v -m integration
```

若尚未安裝系統映像，先依 [README](../readme.md) 完成 SDK 安裝。`make emulator-start` 本身會等待開機；若 emulator 已由其他方式啟動，可先執行 `make emulator-wait`。腳本與測試適合一次使用一台 online emulator。

## 本次對話中的失敗與修正

### `AttributeError: 'tuple' object has no attribute 'returncode'`

Timeout 測試原本使用 `result = (script, env)`，只建立 tuple。已改為 `result = run_bash(script, env)`，取得 `subprocess.CompletedProcess`，才能讀取 `returncode` 與 `stdout`。

同時修正 `TIOMEOUT` 拼字為 `TIMEOUT`、將編碼字串整理為 `encoding="utf-8"`，並把成功開機的斷言改成精確比較 `READY`，避免 `NOT_READY` 也通過子字串比對。

### `assert []`：沒有 online emulator

代表 adb 成功執行，但清單沒有符合條件的 emulator。AVD 存在不代表它正在執行。測試已補上 `No online emulator found` 訊息、啟動提示與 adb 原始輸出。

```bash
adb devices
make emulator-start
python -m pytest -v -m integration
```

若裝置已 online，但 `sys.boot_completed` 尚未為 `1`，先執行 `make emulator-wait`。ADB server 無法啟動、工具不在 PATH 等指令層級問題，會由 subprocess 報錯，應先解決工具或執行環境問題。

### Makefile 註解出現在 console

註解的 `#` 放在行首，不加 Tab，也不要寫成 `\#`。Tab 開頭的行屬於 recipe，會傳給 shell；反斜線又會改變 `#` 的解讀。

```makefile
test:
	pytest -v tests

# Mock Emulator測試
# pytest -m "not integration"
# 真實Emulator測試
# pytest -m integration
```

`make -n test` 可在不執行測試的情況下檢查 recipe，預期只顯示 `pytest -v tests`。

## 驗證紀錄

本次對話修正後曾執行 Mock 測試，結果為 `6 passed, 2 deselected`。當時 AVD 清單有 `cookbook_pixel_api_36`，但 `adb devices` 沒有裝置，因此未宣稱整合測試通過。此紀錄反映當時環境；目前結果請重新執行上述命令確認。
