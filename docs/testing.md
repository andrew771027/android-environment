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

## Mock helper 的相依性與原理

三個 helper 定義於 [test_emulator_lib.py](../tests/test_emulator_lib.py)。它們彼此沒有直接呼叫，而是由每個測試組合使用：`make_fake_command` 準備指令檔案，`build_env` 準備搜尋路徑，`run_bash` 使用該環境執行真正的 Shell 函式。

| Helper | 輸入 → 輸出 | 相依性與前提 |
| --- | --- | --- |
| `make_fake_command` | 目錄、指令名稱、腳本內容 → 指令的 `Path` | Python 標準函式庫 `pathlib`；目錄必須已建立且可寫入 |
| `build_env` | 假指令所在目錄 → `dict[str, str]` | Python 標準函式庫 `os`；目前環境須有 `PATH` |
| `run_bash` | Bash 程式碼、環境字典 → `CompletedProcess[str]` | Python 標準函式庫 `subprocess`；傳入的 `PATH` 須能找到 Bash 與腳本使用的外部工具 |

`tmp_path` 是 pytest 提供的 fixture，為各測試提供獨立暫存目錄；這三個 helper 本身都是一般 Python 函式，並不是 fixture。

### `make_fake_command`：把預設回應做成可執行指令

```python
command = directory / name
command.write_text(content, encoding="utf-8")
command.chmod(0o755)
return command
```

`directory / name` 使用 `Path` 的路徑組合運算，例如產生 `/tmp/.../bin/adb`。`write_text` 寫入腳本內容，同名檔案已存在時會覆寫。`chmod(0o755)` 設定 POSIX 權限：擁有者可讀、寫、執行，其他使用者可讀、執行，讓 Bash 可以把檔案當作指令啟動。

呼叫端必須先用 `fake_bin.mkdir()` 建立目錄，並提供有效腳本。現有測試的內容以 `#!/usr/bin/env bash` 開頭，由 `/usr/bin/env` 依 `PATH` 找到 Bash。假 adb 利用 `$1` 等參數判斷呼叫方式，例如收到 `adb devices` 時 `$1` 是 `devices`，接著輸出測試指定的裝置清單。

這個 helper 只建立檔案，不會執行它，也不會安裝或替換 SDK 中的 adb。回傳的 `Path` 可供後續使用，但現有測試主要依賴它建立檔案的效果。

### `build_env`：讓子程序優先找到假 adb

```python
env = os.environ.copy()
env["PATH"] = f"{fake_bin}:" f"{env['PATH']}"
return env
```

`os.environ.copy()` 複製目前程序的環境變數，因此修改 `env` 不會改動 pytest 本身或使用者終端機的環境。相鄰的兩個 f-string 會串接，上述指定等同於 `f"{fake_bin}:{env['PATH']}"`；冒號是 macOS/Linux 的 PATH 分隔符號。

Bash 執行沒有指定路徑的 `adb` 時，會依序搜尋 PATH。將假指令目錄放在最前面，就會先找到該目錄中的 `adb`。保留原本 PATH，則 Bash、`awk`、`tr`、`sleep` 等工具仍可正常使用。

此函式不會建立目錄或檢查假指令是否存在。如果假 adb 沒有正確建立，搜尋可能繼續落到真實 SDK 的 adb；因此必須先準備好假指令再執行測試。若程式改用 adb 的絕對路徑，也會繞過這種替代方式。這是透過指令搜尋路徑替代外部相依性，並不是完整的程序沙箱。

### `run_bash`：執行真正的 Shell 邏輯並收集結果

```python
return subprocess.run(
    ["bash", "-c", script],
    text=True,
    capture_output=True,
    env=env,
    check=False,
)
```

`["bash", "-c", script]` 明確啟動 Bash，讓它把 `script` 字串當作程式執行。這裡沒有使用 `shell=True`，但傳入的 `script` 仍會由 Bash 解析，因此應使用測試內可控制的內容。

| 參數／結果 | 意義 |
| --- | --- |
| `env=env` | 使用指定的完整環境字典，讓 Bash 及其子程序繼承假指令優先的 PATH |
| `text=True` | 將 stdout/stderr 解碼為 Python 字串，方便比較 |
| `capture_output=True` | 分別收集 stdout 與 stderr，存入結果物件 |
| `check=False` | 子程序以非零狀態結束時，仍回傳結果，讓測試自行斷言 |
| `result.returncode` | Bash 程序的退出碼，0 通常代表成功 |
| `result.stdout` / `result.stderr` | 腳本的標準輸出／錯誤輸出 |

`subprocess.run` 會等待 Bash 結束。`check=False` 不會忽略所有例外，例如找不到 Bash 仍會拋出 `FileNotFoundError`。此 helper 沒有設定 subprocess timeout，因此腳本若卡住，Python 端不會自動中止它。

測試字串中的 `source "{EMULATOR_LIB}"` 會將真正的函式庫載入該 Bash 程序，再呼叫 `get_emulator_serial` 等函式。`EMULATOR_LIB` 由測試檔案的 `__file__` 推導出專案根目錄後組成絕對路徑，不依靠執行時的工作目錄尋找函式庫。等待函式會呼叫 logging helpers，所以 timeout 測試還會先 source `COMMON_LIB`。

### 三者如何串起來

```text
pytest 提供 tmp_path
    ↓
測試建立 fake_bin 目錄
    ├── make_fake_command → 寫入 fake_bin/adb 並加上執行權限
    └── build_env → PATH = fake_bin:原本的 PATH
                         ↓
                  run_bash(script, env)
                         ↓
                  Bash source 真正的 emulator.sh
                         ↓
                  get_emulator_serial 呼叫 adb devices
                         ↓
                  PATH 找到假 adb → 輸出預設裝置清單
                         ↓
                  真正的 awk 篩選 emulator serial
                         ↓
                  CompletedProcess → pytest 斷言結果
```

因此，測試替代的是外部 adb 回應，實際受測的 Bash 函式與文字處理仍然執行。各測試可用不同假 adb 內容模擬已開機、未開機或沒有裝置，而不需要真的啟動 Android。

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

## 驗證紀錄

本次對話修正後曾執行 Mock 測試，結果為 `6 passed, 2 deselected`。當時 AVD 清單有 `cookbook_pixel_api_36`，但 `adb devices` 沒有裝置，因此未宣稱整合測試通過。此紀錄反映當時環境；目前結果請重新執行上述命令確認。
