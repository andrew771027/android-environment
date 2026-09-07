# Emulator 生命週期

本文依據目前的 [生命週期函式庫](../scripts/lib/emulator.sh)、[scripts](../scripts/) 與 [測試](../tests/) 說明實際行為。基本概念與手動 ADB 操作請參考 [Emulator guide](./emulator.md)。

## 狀態判定

| 狀態 | 判定條件 |
| --- | --- |
| `STOPPED` | `adb devices` 沒有 serial 以 `emulator-` 開頭、狀態為 `device` 的項目 |
| `BOOTING` | 找到 online emulator，但 `sys.boot_completed` 不是 `1` |
| `READY` | 找到 online emulator，且 `sys.boot_completed` 為 `1` |

`STOPPED` 是腳本的 ADB 觀測結果，不保證主機上沒有 emulator process；尚未連線或 offline 的 emulator 也可能顯示此狀態。`device` 只代表 ADB 已連線，仍須檢查 Android 是否完成開機。

```text
建立 AVD → 啟動 emulator → ADB online → sys.boot_completed = 1
                         BOOTING             READY
```

## 共用函式

| 函式 | 行為 |
| --- | --- |
| `get_emulator_serial` | 用 awk 選取第一個 online emulator，沒有符合項目時輸出空字串 |
| `is_emulator_connected` | 判斷查到的 serial 是否非空 |
| `is_emulator_boot_completed` | 查詢選定 serial 的開機屬性，移除 `\r` 後與 `1` 比較 |
| `wait_for_emulator_boot TIMEOUT INTERVAL` | 立即檢查 readiness，未完成則 sleep 後重試；成功回傳 0，超時回傳 1 |

等待函式使用 `common.sh` 的 logging helpers，直接呼叫時先 source `common.sh`，再 source `emulator.sh`。函式以累加 sleep 秒數計算等待預算；ADB 指令耗時不包含在計數內，因此不是嚴格的 wall-clock timeout，也沒有替每次 ADB 呼叫設定獨立 timeout。

## 命令行為

所有命令都從專案根目錄執行。

| 命令 | 實際流程 |
| --- | --- |
| `make emulator-start` | 檢查 emulator、adb 與設定的 AVD；已 READY 則成功結束，已 online 則等待，否則背景啟動 AVD 後等待 |
| `make emulator-wait` | 檢查 adb，等待 readiness；不啟動 emulator |
| `make emulator-status` | 顯示狀態、設定的 AVD 名稱，以及找到的 serial；正常查詢時 STOPPED/BOOTING 也不代表命令失敗 |
| `make emulator-stop` | 沒有 online emulator 則成功結束；否則送出 `adb -s SERIAL emu kill`，每秒檢查，最多累計等待 30 秒 |
| `make emulator-reset` | 停止查到的 online emulator，等待斷線，再以 `-wipe-data -no-snapshot-load -no-boot-anim` 啟動設定的 AVD，等待開機 |
| `make clean` | 刪除設定的 AVD；不會先停止 emulator |

啟動與重設會將 emulator stdout/stderr 寫入根目錄的 `emulator.log`，每次新啟動都覆寫該檔案。開機等待失敗會以非零狀態結束，但不會自動終止背景 emulator。

`emulator-reset` 會清除 AVD 的使用者資料，包括安裝的 App 與設定。它停止既有 emulator 的等待迴圈目前沒有 timeout；這與 `emulator-stop` 的 30 秒等待不同。

## 設定

預設值位於 [config/android.env](../config/android.env)。

| 變數 | 預設值 | 用途 |
| --- | --- | --- |
| `AVD_NAME` | `cookbook_pixel_api_36` | 建立、啟動、重設與刪除的 AVD |
| `AVD_DEVICE` | `pixel_7` | 建立 AVD 時使用的硬體 profile |
| `EMULATOR_BOOT_TIMEOUT_SECONDS` | `180` | 開機輪詢的等待預算 |
| `EMULATOR_BOOT_POLL_INTERVAL_SECONDS` | `2` | 開機輪詢間隔 |
| `EMULATOR_NO_SNAPSHOT_LOAD` | `true` | start 時加入 `-no-snapshot-load` |
| `EMULATOR_NO_BOOT_ANIMATION` | `true` | start 時加入 `-no-boot-anim` |

這些變數在設定檔中直接賦值，請修改設定檔調整行為；單純在呼叫前設定同名環境變數會被覆蓋。`ANDROID_HOME` 則保留外部傳入值。reset 的三個啟動 flags 是固定的，不受上述兩個布林設定控制。

## 目前的裝置選取限制

腳本每次都重新選取第一台 online emulator，沒有驗證該 serial 對應 `AVD_NAME`。因此 start 可能沿用其他 AVD，status 印出的 AVD 名稱也只是設定值。stop/reset 可能停止第一台 online emulator，即使它不是專案的 AVD。

此流程適合一次使用一台 emulator。offline 或尚未出現在 ADB 清單的 process 不會被辨識為已連線，重複 start 可能再次嘗試啟動。多裝置精準選取與 process 層級偵測目前尚未實作。

## 日常流程與驗證

```bash
make create-avd
make emulator-start
make emulator-status
python -m pytest -v -m integration
make emulator-stop
```

測試前需啟用 Python 測試環境，詳見 [testing.md](./testing.md)。`make validate` 驗證 provisioning；整合測試另外驗證 AVD 存在與執行中的 emulator 已完成開機。
