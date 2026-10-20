# S2CE ModManager

**一款基于 AutoIt 原生 GUI 的《Total War: SHOGUN 2 – Complete Edition》本地 `.pack` MOD 管理工具。**

[![English](https://img.shields.io/badge/Language-English-blue)](README.md) [![简体中文](https://img.shields.io/badge/语言-简体中文-orange)](README_zh.md)

S2CE ModManager 会扫描游戏的 `data` 目录和 `Disabled_Mods` 目录，并通过移动 PACK 文件、更新 `user.script.txt` 来激活、停用和调整本地 MOD 加载顺序。

> **语言：** 英文版 README 为默认首页。点击上方 **English** 可查看英文说明。GitHub 的 README 不支持安全地通过脚本在同一页面内切换文本，因此语言按钮会打开对应语言的 README 文件。

## 功能

- **双语界面：** 默认使用英文，可在程序内即时切换 English / 中文。
- **扫描本地 PACK：** 列出游戏 `data` 和 `Disabled_Mods` 目录直接包含的 `.pack` 文件。
- **批量激活：** 勾选需要激活的项目，将符合条件的文件从 `Disabled_Mods` 移动到 `data`，并更新 `user.script.txt`。
- **批量停用：** 勾选需要停用的项目，将符合条件的文件从 `data` 移动到 `Disabled_Mods`，并移除对应脚本条目。
- **调整加载顺序：** 选中一个已激活的 PACK 行，点击 **Up / Down** 调整顺序并同步更新 `user.script.txt`。
- **规范脚本格式：** 管理的脚本条目使用 `mod "example.pack";` 格式。
- **内嵌横幅数据：** 横幅图片的 Base64 数据独立存放在 `S2CE_BannerData.au3` 中，不需要额外携带 JPG。
- **原生 AutoIt GUI：** 使用 AutoIt 原生 GUI 控件。
- **目录配置：** 通过 INI 文件保存游戏目录和脚本目录设置。

## 仓库文件

```text
S2CE-ModManager/
├── README.md                  # 英文文档（默认）
├── README_zh.md               # 简体中文文档
├── S2CE_ModManager.au3     # AutoIt 主程序源码
└── S2CE_BannerData.au3        # 内嵌横幅图片数据
```

主程序 `S2CE_ModManager.au3` 通过 `#include` 引入 `S2CE_BannerData.au3`。**运行或编译源码时，这两个 AU3 文件必须放在同一目录。** 编译后，图片数据会一起编入 EXE。

## 系统要求

- Windows 10 版本 1703 或更高版本。
- AutoIt v3，用于运行或编译源码。
- 已安装《Total War: SHOGUN 2 – Complete Edition》，并能够访问游戏目录。

当前仓库不包含预编译 EXE。

## 运行源码

1. 克隆或下载本仓库。
2. 将 `S2CE_ModManager.au3` 和 `S2CE_BannerData.au3` 放在同一文件夹。
3. 使用 AutoIt 运行 `S2CE_ModManager.au3`。

## 编译为 EXE

1. 安装 AutoIt v3 和 SciTE for AutoIt3。
2. 使用 SciTE 打开 `S2CE_ModManager.au3`。
3. 按 **F7** 编译。
4. 运行生成的 EXE。

编译后的 EXE 已包含横幅数据，不需要在 EXE 旁边放置 `S2CE_BannerData.au3`。但编译时必须能找到该 include 文件。

## 初次使用

1. 启动程序，检查游戏目录和脚本目录设置。
2. 如果未自动识别游戏目录，点击 **Set game folder**，选择包含 `data` 子目录的游戏根目录。
3. 如有需要，点击 **Set script folder**，指定 `user.script.txt` 所在目录。
4. 点击 **Rescan**，扫描支持目录中的 PACK 文件。
5. 勾选本次需要处理的项目，再点击 **Activate** 或 **Deactivate**。
6. 调整加载顺序时，选中一个已激活的 PACK 行，再点击 **Up** 或 **Down**。
7. 建议关闭并重新启动游戏，再验证 MOD 是否按预期生效。

## 工作方式

### 激活与停用

- 复选框用于指定本次批量操作的目标；未勾选项目不应被处理。
- 激活时，将符合条件的 PACK 从 `<GameFolder>\Disabled_Mods\` 移动到 `<GameFolder>\data\`。
- 停用时则反向移动。
- 程序会更新 `user.script.txt` 中对应的条目。
- 如果目标目录已有同名文件，程序不会覆盖它。

### 加载顺序

- 选中一个已激活的 PACK 行，然后点击 **Up** 或 **Down**。
- 调整后的顺序会写入 `user.script.txt`。
- 已停用的 PACK 必须先激活，才能调整加载顺序。

### 脚本格式

管理的条目采用以下格式：

```text
mod "example.pack";
```

程序会尝试保留其他无关脚本行和注释，并以 UTF-16 LE 格式写回脚本文件。

## 配置与临时文件

- `S2CE_ModManager.ini` 位于主程序同目录，用于保存游戏目录和脚本目录。
- 操作消息只保留在当前运行会话中；程序不会创建持久化日志文件。
- 启动时，程序会将内嵌横幅解码为临时图片文件，并在正常退出时尝试删除。
- 程序不会自动备份 PACK 文件或 `user.script.txt`。大量修改前建议自行备份。

## 已知限制与注意事项

- 本工具通过移动 `.pack` 文件和编辑 `user.script.txt` 管理 MOD，兼容性取决于具体游戏版本。
- 如果 PACK 移动成功但脚本更新失败，请手动检查文件位置和 `user.script.txt`。
- 程序只扫描目录直接包含的 `*.pack` 文件，不递归扫描子目录。
- 部分官方 PACK 可能会根据文件名过滤，不显示在用户 MOD 列表中。
- 修改文件前请关闭游戏，并确认其他程序没有占用目标文件。
- 在依赖本工具进行重要修改前，请先在目标 Windows 环境中编译并测试。

## 许可证

源码元信息标注为 Freeware，但仓库目前没有独立的 `LICENSE` 文件。如需允许他人再分发或修改，请先添加符合作者意愿的明确许可证。

---

[English version](README.md)
