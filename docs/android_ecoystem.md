# Android SDK、ADB、Fastboot、Emulator、AVD 與 Kotlin / Java 關係整理

## 1. 先建立整體心智模型

在 Android 開發與測試環境中，可以先把整體分成兩個世界：

1. **Workstation 端**
   - macOS
   - Linux
   - Windows
   - Android SDK
   - JDK / Java
   - `sdkmanager`
   - `avdmanager`
   - `adb`
   - `fastboot`
   - Android Emulator

2. **Android Device 端**
   - 實體 Pixel
   - Android Virtual Device（AVD）
   - Android OS
   - Android Runtime（ART）
   - Android Framework
   - Apps

整體關係可以理解成：

```text
Developer / Test Engineer
        │
        ▼
Mac / Linux Workstation
        │
        ├── JDK / Java
        │
        └── Android SDK
             │
             ├── Command-Line Tools
             │    ├── sdkmanager
             │    └── avdmanager
             │
             ├── Platform Tools
             │    ├── adb
             │    └── fastboot
             │
             └── Android Emulator
                    │
                    ▼
                  AVD
                    │
                    ▼
               Android OS
                    │
                    ├── ART
                    ├── Android Framework
                    ├── System Services
                    └── Apps
                         │
                         ├── Kotlin
                         └── Java
```

---

# 2. Java / JDK

Java 在 Android 開發環境中有兩個常見角色。

## 2.1 Android Tooling 的執行環境

Android 開發生態中大量工具建立在 JVM / Java ecosystem 上，例如：

- Gradle
- Android Gradle Plugin
- Kotlin Compiler
- Android Build Tools
- 部分 Android SDK tooling

因此 Workstation 通常需要安裝 JDK。

例如：

```bash
java -version
javac -version
```

常見版本例如：

```text
OpenJDK 17
```

需要注意：

> 安裝 Java 不代表 Android App 一定要使用 Java 開發。

現在 Android App 非常常使用 Kotlin。

---

# 3. Kotlin 是什麼？

Kotlin 是由 JetBrains 開發的程式語言，也是現代 Android App 開發的主流語言之一。

例如 Kotlin Android Activity：

```kotlin
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        println("Hello Android")
    }
}
```

Java 也可以完成相同工作：

```java
public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        System.out.println("Hello Android");
    }
}
```

所以 Kotlin 與 Java 都可以用來撰寫 Android Application。

```text
Kotlin ──┐
         ├── Android Application
Java ────┘
```

---

# 4. Kotlin 與 Java 的關係

Kotlin 從一開始就非常重視與 Java 的相容性。

因此 Kotlin 與 Java 可以：

- 存在於同一個 Android Project
- Kotlin 呼叫 Java
- Java 呼叫 Kotlin
- 共用 Java Library
- 共用 Android Framework API

例如：

```text
app/
├── MainActivity.kt
├── DeviceManager.kt
└── LegacyHelper.java
```

Kotlin 可以呼叫 Java：

```kotlin
val helper = LegacyHelper()
helper.doSomething()
```

這種能力稱為：

> Java Interoperability

---

# 5. JVM 與 Android Runtime（ART）

一般 Java Application 的執行流程大致是：

```text
Java
  │
  ▼
javac
  │
  ▼
.class bytecode
  │
  ▼
JVM
  │
  ▼
Windows / Linux / macOS
```

Android 的流程則不同。

```text
Kotlin / Java
       │
       ▼
    Compiler
       │
       ▼
   .class files
       │
       ▼
Android Build Tools
       │
       ▼
     DEX
       │
       ▼
      ART
       │
       ▼
   Android OS
```

ART：

> Android Runtime

是 Android 系統中負責執行 Android Application code 的 runtime。

因此更精確的說法是：

> Kotlin / Java 使用 Java / JVM 生態系與 bytecode toolchain，但 Android App 最終通常會被轉換成 DEX，並由 ART 執行。

---

# 6. Android SDK

SDK：

> Software Development Kit

Android SDK 是 Google 提供的一整套 Android 開發、建置、測試與 Device Management 工具。

它不是單一程式，而是一整組工具集合。

典型結構：

```text
Android SDK
│
├── cmdline-tools/
├── platform-tools/
├── build-tools/
├── platforms/
├── emulator/
└── system-images/
```

---

# 7. Android SDK Command-Line Tools

Command-Line Tools 是 Android SDK 中的一組 CLI 工具。

常見目錄：

```text
cmdline-tools/
└── latest/
    └── bin/
        ├── sdkmanager
        └── avdmanager
```

最常見的工具：

- `sdkmanager`
- `avdmanager`

這些工具主要用來管理 Android SDK 與虛擬裝置。

---

# 8. sdkmanager

`sdkmanager` 可以理解為：

> Android SDK 的 Package Manager

它的角色很像：

- `apt`
- `brew`
- `pip`
- `npm`

只是它管理的是 Android SDK Components。

查看可用套件：

```bash
sdkmanager --list
```

安裝 Platform Tools：

```bash
sdkmanager "platform-tools"
```

安裝 Emulator：

```bash
sdkmanager "emulator"
```

安裝 Android Platform：

```bash
sdkmanager "platforms;android-35"
```

安裝 Emulator System Image：

```bash
sdkmanager \
  "system-images;android-35;google_apis;x86_64"
```

因此：

```text
sdkmanager
   │
   ├── install platform-tools
   ├── install emulator
   ├── install Android platform
   └── install system image
```

`sdkmanager` 執行在 Workstation 上，而不是 Android Device 裡面。

---

# 9. avdmanager

AVD：

> Android Virtual Device

`avdmanager` 的角色是：

> 建立與管理 Android Virtual Device 設定。

例如：

```bash
avdmanager create avd \
    -n pixel_test \
    -k "system-images;android-35;google_apis;x86_64"
```

建立：

```text
pixel_test
```

概念上：

```text
System Image
     +
Device Config
     +
Hardware Config
     │
     ▼
     AVD
```

---

# 10. AVD 是什麼？

AVD 與 Emulator 不是同一件事。

## Emulator

Emulator 是：

> 執行虛擬 Android Device 的模擬器程式。

## AVD

AVD 是：

> 某一台虛擬 Android Device 的設定。

例如：

```text
Android Emulator
│
├── Pixel_6_API_34
├── Pixel_7_API_35
└── Pixel_8_API_36
```

這三個都是不同的 AVD。

可以使用：

```bash
emulator -avd Pixel_7_API_35
```

來啟動其中一台。

---

# 11. Android Emulator

Android Emulator 可以在：

- macOS
- Linux
- Windows

上模擬一台 Android Device。

例如：

```text
MacBook
│
└── Android Emulator
      │
      └── Virtual Pixel
            │
            ├── Android OS
            ├── Android Framework
            ├── ART
            ├── System Services
            ├── Chrome
            └── adbd
```

Emulator 裡不是只有手機 UI。

它實際上包含：

- Android System Image
- Android Framework
- ART
- System Services
- Linux Kernel
- Virtual Hardware

因此非常適合拿來練習：

```bash
adb devices
adb shell
adb install
adb push
adb pull
adb logcat
adb reboot
adb shell dumpsys
adb shell pm
adb shell am
```

---

# 12. Android SDK Platform Tools

Platform Tools 是 Android SDK 中的一組 Device Control 工具。

典型目錄：

```text
platform-tools/
│
├── adb
├── fastboot
└── ...
```

最重要的兩個工具：

- `adb`
- `fastboot`

對 Device Testing 與 Android Automation 而言，Platform Tools 是非常重要的一層。

---

# 13. adb

ADB：

> Android Debug Bridge

ADB 是 Workstation 與 Android Device 之間的橋樑。

```text
Workstation
     │
     │ adb
     ▼
Android Device
```

ADB 架構實際上可以分成：

```text
ADB Client
    │
    ▼
ADB Server
    │
    │ USB / TCP
    ▼
adbd
    │
    ▼
Android Device
```

其中：

```text
adb client
adb server
```

位於 Workstation。

而：

```text
adbd
```

位於 Android Device。

例如：

```bash
adb shell
```

大致流程是：

```text
Terminal
   │
   ▼
adb client
   │
   ▼
adb server
   │
   │ USB / TCP
   ▼
adbd
   │
   ▼
Android shell
```

因此可以執行：

```bash
adb shell ls
adb shell ps
adb shell dumpsys battery
adb shell getprop
```

---

# 14. adb 在 Device Testing 的角色

ADB 可以視為：

> Automation 控制 Android Device 的主要入口之一。

例如：

```text
Device Test Runner
        │
        ▼
SubprocessExecutor
        │
        ▼
adb shell ...
        │
        ▼
Pixel
```

Python 範例：

```python
subprocess.run([
    "adb",
    "-s",
    serial,
    "shell",
    "dumpsys",
    "battery",
])
```

Android Knowledge 與 Test Runner 可以保持架構分離：

```text
Android Cookbook
       │
       ▼
Android Domain Knowledge
       │
       ▼
adb / fastboot / Android OS

Device Test Runner
       │
       ▼
Automation Infrastructure
       │
       ▼
呼叫 adb / fastboot
```

也就是：

> Runner 使用 Android Domain Knowledge，但兩個 Repo 不需要綁死。

---

# 15. fastboot

`adb` 與 `fastboot` 都可以控制 Android Device，但它們操作的是不同的 Device State。

正常 Android OS 啟動後：

```text
Android OS
   │
   └── adb
```

Bootloader / Fastboot Mode：

```text
Bootloader
   │
   └── fastboot
```

Android Boot Flow 可以簡化為：

```text
Power On
   │
   ▼
Bootloader
   │
   │ fastboot
   ▼
Android OS
   │
   │ adb
   ▼
Applications
```

例如：

```bash
adb reboot bootloader
```

讓 Android Device 重新啟動到 Bootloader。

接著：

```bash
fastboot devices
```

確認 Fastboot Device。

---

# 16. adb vs fastboot

| 功能 | adb | fastboot |
|---|---|---|
| 操作階段 | Android OS | Bootloader |
| Android OS 是否已啟動 | 通常需要 | 不需要 |
| Android Shell | Yes | No |
| 安裝 APK | Yes | No |
| logcat | Yes | No |
| dumpsys | Yes | No |
| Flash Partition | 通常不是 | Yes |
| Boot Image | No | Yes |
| Bootloader 操作 | No | Yes |

因此一個 Device Test Lifecycle 有可能是：

```text
global_setup
     │
     ▼
fastboot flash
     │
     ▼
reboot
     │
     ▼
adb setup
     │
     ▼
adb scenario
     │
     ▼
collect artifacts
```

---

# 17. Android Platform

Android Platform 與 Platform Tools 很容易混淆。

例如：

```text
platforms;android-35
```

代表的是某個 Android API Level 的 SDK Platform。

例如：

```text
Android 15
API Level 35
```

Android App build 時可能會設定：

```kotlin
android {
    compileSdk = 35
}
```

SDK 中就需要：

```text
platforms/
└── android-35/
```

裡面包含 Android API Definitions，例如：

```text
android.app.Activity
android.content.Context
android.os.Bundle
android.hardware.*
```

因此：

```text
Android Platform
        ≠
Platform Tools
```

Android Platform：

```text
platforms/android-35
→ App Compilation
```

Platform Tools：

```text
platform-tools/adb
platform-tools/fastboot
→ Device Control
```

---

# 18. 名詞總整理

| 名詞 | 位置 | 主要用途 |
|---|---|---|
| Java / JDK | Workstation | Gradle、compiler、Android tooling 執行環境 |
| Kotlin | Development Language | 撰寫 Android App |
| Android SDK | Workstation | Android 開發工具總集合 |
| Command-Line Tools | Workstation | 管理 SDK 與 AVD |
| `sdkmanager` | Workstation | 安裝 Android SDK components |
| `avdmanager` | Workstation | 建立與管理 AVD |
| Platform Tools | Workstation | Device 操作工具集合 |
| `adb` | Workstation + Android `adbd` | 控制已啟動的 Android OS |
| `fastboot` | Workstation + Bootloader | Bootloader / Flash 操作 |
| Emulator | Workstation | 模擬 Android Hardware / Device |
| AVD | Workstation | 一台 Virtual Android Device 的設定 |
| Android Platform | Workstation | Android API Level / compile SDK |
| Android OS | Device | Android 作業系統 |
| ART | Android OS | Android Runtime |
| Kotlin / Java App | Android Device | Application Layer |

---

# 19. 建議的學習路徑

可以依照以下順序學習：

```text
Android Environment
        │
        ▼
sdkmanager / avdmanager
        │
        ▼
Emulator / AVD
        │
        ▼
adb
        │
        ▼
adb shell
        │
        ▼
Android OS
        │
        ▼
Linux / Android Internals
        │
        ▼
fastboot / bootloader
        │
        ▼
flash / recovery
        │
        ▼
Device Automation
        │
        ▼
Device Test Runner
```

這樣學習的重點不是單純記住 Android 指令，而是理解：

> Workstation 如何建立 Android Environment、控制 Android Device，並進一步深入 Android OS 與 Device Automation。

---

# 20. Android Cookbook 與 Android Environment 的分工

可以將兩個 Side Project 分開：

```text
android-environment/
│
├── setup
├── SDK installation
├── Emulator setup
├── AVD creation
└── Environment verification
```

專注：

> 如何建立一套可使用的 Android 學習與測試環境。

而：

```text
android-cookbook/
│
├── adb
├── fastboot
├── shell
├── logcat
├── dumpsys
├── pm
├── am
└── troubleshooting
```

專注：

> 如何操作 Android Device 與 Android OS。

兩者關係：

```text
Android Environment
        │
        ▼
提供可練習的環境
        │
        ▼
Android Cookbook
        │
        ▼
Android Domain Knowledge
        │
        ▼
Device Automation
        │
        ▼
Device Test Runner / Platform
```

---

# Summary

最核心的概念可以整理成：

```text
Kotlin / Java
     │
     ▼
Android Application

Android SDK
     │
     ├── sdkmanager
     ├── avdmanager
     ├── adb
     ├── fastboot
     └── emulator

Workstation
     │
     ▼
ADB / Fastboot
     │
     ▼
Pixel / AVD
     │
     ▼
Android OS
     │
     ├── ART
     ├── Framework
     ├── System Services
     └── Apps
```

一句話總結：

> **Android SDK 是 Workstation 操作 Android 世界的工具箱；Kotlin / Java 是開發 Android App 的語言；ADB / Fastboot 是控制 Android Device 的主要入口；Emulator + AVD 則提供虛擬 Android Device。**
