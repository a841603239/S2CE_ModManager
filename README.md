# S2CE ModManager

一个基于 **AutoIt 原生 GUI** 的《Total War: SHOGUN 2 – Complete Edition》本地 PACK MOD 管理工具。用于查看游戏 `data` 目录中的 `.pack` 文件，并通过移动文件及更新 `user.script.txt` 来激活、停用和调整 MOD 加载顺序。

> 当前项目提供 AutoIt 源码。使用源码运行时，主程序与横幅数据文件必须放在同一目录；编译为 EXE 后，横幅数据会随程序一起编译，无需再携带独立 JPG。

## 功能

- **English / 中文界面切换**：默认使用 English，可在窗口右上角即时切换中文。
- **扫描本地 PACK**：扫描游戏 `data` 与 `Disabled_Mods` 目录中的 `.pack` 文件，显示文件名、PACK 类型、大小和文件位置。
- **激活 PACK**：勾选目标项后，将位于 `Disabled_Mods` 的 PACK 移回 `data`，并更新 `user.script.txt`。
- **停用 PACK**：勾选目标项后，将位于 `data` 的 PACK 移入游戏根目录下的 `Disabled_Mods`，并从 `user.script.txt` 移除相应指令。
- **调整加载顺序**：选中一个已激活的 PACK 行，点击“↑ Up”或“↓ Down”，同步更新 `user.script.txt` 中的 PACK 顺序。
- **规范脚本格式**：管理的 PACK 指令使用 `mod "example.pack";` 格式，并能识别常见的带引号与不带引号写法。
- **内置横幅图片**：JPG 的 Base64 数据存放在独立的 `S2CE_BannerData.au3` 中，不依赖外部 JPG 文件。
- **DPI 感知界面**：采用 AutoIt 原生 GUI，并对 Windows 显示缩放进行处理。
- **路径配置**：记住游戏目录和用户脚本目录。

## 项目文件

```text
S2CE-ModManager/
├── README.md
├── S2CE_ModManager_11.au3   # 主程序
└── S2CE_BannerData.au3      # 横幅 JPG 的 Base64 数据
```

`S2CE_BannerData.au3` 通过 `#include` 引入主程序。运行 `.au3` 源码时，**这两个文件必须位于同一目录**。编译为 EXE 后，包含文件会被编译进程序中。

## 系统要求

- Windows 10 1703 或更高版本（源码使用 Windows DPI 感知 API）。
- AutoIt v3，用于运行或编译 `.au3` 源码。
- 《Total War: SHOGUN 2 – Complete Edition》及可访问的游戏安装目录。

当前仓库源码包不包含预编译 EXE。

## 运行或编译

### 运行源码

1. 下载或克隆本仓库。
2. 确保 `S2CE_ModManager_11.au3` 和 `S2CE_BannerData.au3` 位于同一文件夹。
3. 使用 AutoIt 运行 `S2CE_ModManager_11.au3`。

### 编译为 EXE

1. 安装 AutoIt v3。
2. 使用 SciTE for AutoIt3 打开 `S2CE_ModManager_11.au3`。
3. 按 **F7** 编译。
4. 将编译生成的 EXE 放到合适位置运行。编译后的程序不再需要单独的 `S2CE_BannerData.au3` 文件。

## 初次使用

1. 启动程序后，检查左侧显示的游戏目录和用户脚本目录。
2. 如果游戏目录未自动识别，点击 **Set game folder / 修改游戏目录**，选择包含 `data` 子目录的游戏根目录。
3. 如需更改 `user.script.txt` 所在位置，点击 **Set script folder / 修改脚本目录**。
4. 点击 **Rescan / 重新扫描**，读取两个目录中的 PACK。
5. 勾选本次需要处理的 PACK，再点击 **Activate / 激活** 或 **Deactivate / 停用**。
6. 调整加载顺序时，单击选中一个已激活的 PACK 行，再点击 **↑ Up / 上移** 或 **↓ Down / 下移**。
7. 操作完成后，建议完全退出并重新启动游戏，再验证 MOD 是否按预期工作。

## 操作规则

- **复选框**用于指定本次批量激活或停用的目标；扫描后的项目默认不勾选。未勾选项目不会被处理。
- **高亮选中行**用于排序；排序一次只处理一个 PACK。停用区中的 PACK 需要先激活，才能调整加载顺序。
- 激活与停用会在游戏根目录内移动 `.pack` 文件：
  - 已激活：`<游戏目录>\data\`
  - 已停用：`<游戏目录>\Disabled_Mods\`
- 脚本指令使用如下规范格式：

  ```text
  mod "example.pack";
  ```

- 程序会尝试保留 `user.script.txt` 中其他非目标指令和注释，并以 UTF-16 LE 格式写回脚本文件。
- 程序只扫描上述目录中的直接子级 `*.pack` 文件，不递归扫描子目录；部分官方 PACK 会按文件名自动过滤，不显示在用户 MOD 列表中。
- 程序会提示用户尽量在游戏关闭时执行文件操作。确认操作前请自行关闭游戏，并确保目标 PACK 没有被其他程序占用。

## 配置与日志

- 配置文件为 `S2CE_ModManager.ini`，位于主程序所在目录，保存游戏目录和用户脚本目录。
- 界面内的操作记录仅保留在当前运行会话中；程序不创建持久化日志文件。
- 横幅图片会在启动时解码到临时目录，正常退出时尝试删除该临时文件。
- 项目不会自动备份 `user.script.txt` 或 PACK 文件。首次使用或进行大量修改前，建议自行备份相关文件。

## 已知限制

- 本工具通过移动 `.pack` 文件和编辑 `user.script.txt` 管理 MOD；实际效果取决于目标游戏版本是否支持这套传统 MOD 管理方式。
- 如果 PACK 文件移动成功，但 `user.script.txt` 写入失败，程序会显示警告。此时请检查脚本文件并手动核对 PACK 状态。
- 当目标目录已存在同名文件时，程序不会覆盖目标文件；请手动解决同名冲突后重试。
- 在公开发布前，建议在目标 Windows 环境中实际编译，并测试路径选择、批量激活/停用、加载顺序和中英文切换。

## 许可

源码中的编译元信息标注为 `Freeware`，但仓库当前未附带独立的 `LICENSE` 文件。若要公开发布或允许他人修改、再分发，请根据项目作者的意愿补充明确的开源或使用许可条款。
