#pragma compile(ProductName, "S2CE ModManager")     ; 产品名称
#pragma compile(Comments, "Freeware")       ; Comments

#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ListViewConstants.au3>
#include <GuiListView.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <EditConstants.au3>
#include <Array.au3>
#include <File.au3>
#include "S2CE_BannerData.au3"

; 适用于 Windows 10 1703 及更高版本
DllCall("user32.dll", "bool", "SetProcessDpiAwarenessContext", "int64", -4) ; -4 对应 PER_MONITOR_AWARE_V2

Opt("MustDeclareVars", 1)
Opt("GUIOnEventMode", 0)

; Banner Base64 is kept in S2CE_BannerData.au3. Both AU3 files must be together.
Global Const $APP = "S2CE ModManager 1.1"
Global Const $STEAM_URI = "steam://rungameid/3846830"
Global Const $SCRIPT_DEFAULT = @AppDataDir & "\The Creative Assembly\Shogun2CompleteEdition\Steam\scripts"
Global $gGameDir = "", $gScriptDir = $SCRIPT_DEFAULT
Global $gDataDir = "", $gDisabledDir = "", $gScriptFile = ""
Global $gGUI, $gList, $gListH, $gLblGame, $gLblScript, $gLblStatus, $gLog
Global $gBtnBrowseGame, $gBtnBrowseScript, $gBtnOpenGame, $gBtnOpenScript, $gBtnScan, $gBtnActivate, $gBtnDeactivate
Global $gBtnMoveUp, $gBtnMoveDown
Global $gBtnLangEnglish, $gBtnLangChinese
Global $gLang = _DetectDefaultLanguage() ; 中文系统用中文，其余用英文
Global $gBtnSteam, $gBtnOpenData, $gBtnOpenDisabled
Global $gLblReadyLight, $gLblReadyText
Global $gBusy = False
Global $gBannerPath = ""
Global $g_iZoom = _GetSystemDpiZoom()

; 自动检测游戏安装目录
$gGameDir = _FindGameDir()
_UpdatePaths()
_PrepareEmbeddedBanner()

$gGUI = GUICreate($APP, _Scale(1000), _Scale(700), -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU, $WS_MINIMIZEBOX))
GUISetBkColor(0x181A1F, $gGUI)
_CreateUI()
_RefreshPathLabels()
_ScanMods()
GUISetState(@SW_SHOW, $gGUI)

While True
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            ExitLoop
        Case $gBtnBrowseGame
            _ChooseGameDir()
        Case $gBtnBrowseScript
            _ChooseScriptDir()
        Case $gBtnOpenGame
            _OpenGameDir()
        Case $gBtnOpenScript
            _OpenScriptFile()
        Case $gBtnScan
            _ScanMods()
        Case $gBtnActivate
            _ApplyMods(True)
        Case $gBtnDeactivate
            _ApplyMods(False)
        Case $gBtnMoveUp
            _MoveSelectedPack(-1)
        Case $gBtnMoveDown
            _MoveSelectedPack(1)
        Case $gBtnLangEnglish
            _SetLanguage("EN")
        Case $gBtnLangChinese
            _SetLanguage("ZH")
        Case $gBtnSteam
            ShellExecute($STEAM_URI)
            _Log(_T("已请求通过 Steam 启动游戏。"))
        Case $gBtnOpenData
            _OpenFolder($gDataDir)
        Case $gBtnOpenDisabled
            _OpenFolder($gDisabledDir)
    EndSwitch
WEnd
GUIDelete($gGUI)
If $gBannerPath <> "" And FileExists($gBannerPath) Then FileDelete($gBannerPath)
Exit

Func _DetectDefaultLanguage()
    ; 0804=简中(中国), 0404=繁中(台湾), 0C04=繁中(香港),
    ; 1004=简中(新加坡), 1404=繁中(澳门)
    Switch @OSLang
        Case "0804", "0404", "0C04", "1004", "1404"
            Return "ZH"
    EndSwitch
    Return "EN"
EndFunc

Func _T($sText)
    If $gLang = "ZH" Then Return $sText
    Switch $sText
        Case "已请求通过 Steam 启动游戏。"
            Return "Steam launch requested."
        Case "横幅图片加载失败"
            Return "Banner image could not be loaded."
        Case "《全面战争：幕府将军2》完全版 · MOD管理工具"
            Return "Total War: SHOGUN 2 Complete Edition · MOD Manager"
        Case "使用“激活 / 停用”按钮分别管理 PACK"
            Return "Use Activate / Deactivate to manage PACKs"
        Case "作者：Sorin"
            Return "Author: Sorin"
        Case "设置"
            Return "Settings"
        Case "游戏目录"
            Return "Game directory"
        Case "修改游戏目录"
            Return "Set game folder"
        Case "打开游戏目录"
            Return "Open game directory"
        Case "用户脚本目录"
            Return "User script directory"
        Case "修改脚本目录"
            Return "Set script folder"
        Case "打开user.script.txt"
            Return "Open user.script.txt"
        Case "使用说明"
            Return "Instructions"
        Case "1.先勾选需要处理的 PACK；未勾选项不操作。"
            Return "1. Check target PACKs; unchecked items are skipped."
        Case "2.激活：将勾选且位于 Disabled_Mods 的 PACK 移回 data，并更新 user.script.txt。"
            Return "2. Activate: move from Disabled_Mods to data; update user.script.txt."
        Case "3.停用：将勾选且位于 data 的 PACK 移至 Disabled_Mods，并更新 user.script.txt。"
            Return "3. Deactivate: move from data to Disabled_Mods; update user.script.txt."
        Case "4.选择已激活的 PACK 行，使用上移/下移调整加载顺序。"
            Return "4. Select an active row, then use Up/Down to reorder."
        Case "5.完成后建议重新启动游戏。"
            Return "5. Restart the game after changes."
        Case "本地 PACK 列表"
            Return "Local PACKs"
        Case "↑ 上移"
            Return "↑ Up"
        Case "↓ 下移"
            Return "↓ Down"
        Case "配置缺失"
            Return "Config missing"
        Case "选中|PACK 文件名|类型|大小|文件位置|内部路径"
            Return "Check|PACK name|Type|Size|Location|Full path"
        Case "重新扫描"
            Return "Rescan"
        Case "激活"
            Return "Activate"
        Case "停用"
            Return "Deactivate"
        Case "从Steam启动游戏"
            Return "Launch via Steam"
        Case "打开 data"
            Return "Open data"
        Case "打开停用区"
            Return "Open Disabled"
        Case "状态"
            Return "Status"
        Case "就绪"
            Return "Ready"
        Case "请手动选择"
            Return "Select manually"
        Case "已就绪"
            Return "Ready"
        Case "请检查路径设置"
            Return "Check paths"
        Case "请选择包含 data 子目录的游戏根目录"
            Return "Select the game root containing the data folder"
        Case "所选目录不包含 data 子目录。"
            Return "The selected folder does not contain a data subfolder."
        Case "请选择用户脚本目录"
            Return "Select the user script folder"
        Case "已更新用户脚本目录。"
            Return "User script directory updated."
        Case "尚未设置有效的游戏目录。"
            Return "No valid game directory has been set."
        Case "user.script.txt 尚不存在。"
            Return "user.script.txt does not exist yet."
        Case "脚本目录："
            Return "Script directory: "
        Case "请先设置有效的游戏目录。"
            Return "Please set a valid game directory first."
        Case "扫描完成，共 "
            Return "Scan complete: "
        Case " 个 PACK。"
            Return " PACK(s)."
        Case "扫描完成。"
            Return "Scan complete."
        Case "读取失败"
            Return "Read error"
        Case "头部无效"
            Return "Invalid header"
        Case "非PFH"
            Return "Not PFH"
        Case "未知("
            Return "Unknown ("
        Case "仅处理已勾选且位于 Disabled_Mods 的 PACK：移入 data 目录并加入 user.script.txt。"
            Return "Only checked PACKs in Disabled_Mods will be processed: move to data and add to user.script.txt."
        Case "仅处理已勾选且位于 data 的 PACK：移入 Disabled_Mods 目录并从 user.script.txt 移除。"
            Return "Only checked PACKs in data will be processed: move to Disabled_Mods and remove from user.script.txt."
        Case "请先勾选需要"
            Return "Select PACKs to "
        Case "的 PACK。"
            Return ""
        Case "未勾选的项目不会被处理。"
            Return "Unchecked items will be skipped."
        Case "操作："
            Return ":"
        Case "建议先关闭游戏。继续吗？"
            Return "It is recommended to close the game first. Continue?"
        Case "已处于目标状态，跳过："
            Return "Already in target state; skipped: "
        Case "文件已不存在，跳过："
            Return "File no longer exists; skipped: "
        Case "目标已存在，未覆盖："
            Return "Destination already exists; not overwritten: "
        Case "移动成功："
            Return "Moved successfully: "
        Case "移动失败："
            Return "Move failed: "
        Case "严重警告：脚本更新失败。文件移动已完成，请手动检查并修正 user.script.txt。"
            Return "CRITICAL: Script update failed after moving files. Please check and repair user.script.txt manually."
        Case "PACK 文件移动已执行，但 user.script.txt 更新失败。"
            Return "PACK files were moved, but user.script.txt could not be updated."
        Case "请检查用户脚本文件："
            Return "Please check the user script file: "
        Case "完成：成功移动 "
            Return " completed: moved "
        Case " 个，失败/跳过 "
            Return " PACK(s), failed/skipped "
        Case " 个。"
            Return " PACK(s)."
        Case "结束。移动="
            Return " finished. Moved="
        Case "，失败/跳过="
            Return ", failed/skipped="
        Case "操作完成。"
            Return " completed."
        Case "成功移动："
            Return "Moved successfully: "
        Case "失败/跳过："
            Return "Failed/skipped: "
        Case "请完全退出并重新启动游戏后验证。"
            Return "Fully exit and restart the game, then verify."
        Case "请先单击选中一个 PACK 行，再点击上移或下移。"
            Return "Select one PACK row, then click Up or Down."
        Case "复选框仅用于批量激活/停用。"
            Return "Checkboxes are only for batch Activate/Deactivate."
        Case "排序操作一次只处理一个 PACK。请仅选中一行。"
            Return "Reordering moves one PACK at a time. Select exactly one row."
        Case "只能调整已激活（位于 data 目录）的 PACK 加载顺序。"
            Return "Only active PACKs (in the data folder) can be reordered."
        Case "请先激活该 PACK，再使用上移/下移。"
            Return "Activate this PACK before using Up/Down."
        Case "该 PACK 已位于激活列表顶部。"
            Return "This PACK is already at the top of the active list."
        Case "该 PACK 已位于激活列表底部。"
            Return "This PACK is already at the bottom of the active list."
        Case "无法更新 user.script.txt，已撤销本次排序。"
            Return "Could not update user.script.txt; this reorder was reverted."
        Case "请检查脚本目录、user.script.txt 文件权限以及文件是否可写。"
            Return "Check the script directory, user.script.txt permissions, and whether the file is writable."
        Case "排序失败：user.script.txt 未更新。"
            Return "Reordering failed: user.script.txt was not updated."
        Case "已调整加载顺序："
            Return "Load order updated: "
        Case " 上移。"
            Return " moved up."
        Case " 下移。"
            Return " moved down."
        Case "加载顺序已调整："
            Return "Load order changed: "
        Case " 上移"
            Return " up"
        Case " 下移"
            Return " down"
        Case "已按列表顺序更新 user.script.txt（UTF-16 LE）。"
            Return "user.script.txt updated in list order (UTF-16 LE)."
        Case "位于data目录"
            Return "In data"
        Case "位于Disabled_Mods目录"
            Return "In Disabled_Mods"
        Case "位于其他路径"
            Return "Other location"
        Case "user.script.txt 已更新（UTF-16 LE）。"
            Return "user.script.txt updated (UTF-16 LE)."
        Case "目录无法创建或访问："
            Return "Cannot create or access folder: "
        Case "请先勾选需要激活的 PACK。"
            Return "Please check the PACKs you want to activate."
        Case "请先勾选需要停用的 PACK。"
            Return "Please check the PACKs you want to deactivate."
    EndSwitch
    Return $sText
EndFunc

Func _StyleLanguageButtons()
    _StyleButton($gBtnLangEnglish)
    _StyleButton($gBtnLangChinese)
    If $gLang = "EN" Then
        GUICtrlSetBkColor($gBtnLangEnglish, 0xA66E32)
        GUICtrlSetColor($gBtnLangEnglish, 0xFFFFFF)
        GUICtrlSetBkColor($gBtnLangChinese, 0x303540)
        GUICtrlSetColor($gBtnLangChinese, 0xE5E7EB)
    Else
        GUICtrlSetBkColor($gBtnLangChinese, 0xA66E32)
        GUICtrlSetColor($gBtnLangChinese, 0xFFFFFF)
        GUICtrlSetBkColor($gBtnLangEnglish, 0x303540)
        GUICtrlSetColor($gBtnLangEnglish, 0xE5E7EB)
    EndIf
EndFunc

Func _SetLanguage($sNewLang)
    If $gLang = $sNewLang Then Return

    ; Keep target checkboxes and selected rows when recreating the UI in the new language.
    Local $aChecked[0], $aSelected[0]
    Local $iCount = _GUICtrlListView_GetItemCount($gListH)
    For $i = 0 To $iCount - 1
        Local $sPath = _GUICtrlListView_GetItemText($gListH, $i, 5)
        If $sPath = "" Then ContinueLoop
        If _GUICtrlListView_GetItemChecked($gListH, $i) Then
            Local $nChecked = UBound($aChecked)
            ReDim $aChecked[$nChecked + 1]
            $aChecked[$nChecked] = $sPath
        EndIf
        If _GUICtrlListView_GetItemSelected($gListH, $i) Then
            Local $nSelected = UBound($aSelected)
            ReDim $aSelected[$nSelected + 1]
            $aSelected[$nSelected] = $sPath
        EndIf
    Next

    $gLang = $sNewLang
    GUIDelete($gGUI)
    $gGUI = GUICreate($APP, _Scale(1000), _Scale(700), -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU, $WS_MINIMIZEBOX))
    GUISetBkColor(0x181A1F, $gGUI)
    _CreateUI()
    _RefreshPathLabels()
    _ScanMods()

    Local $iNewCount = _GUICtrlListView_GetItemCount($gListH)
    For $i = 0 To $iNewCount - 1
        Local $sPath = _GUICtrlListView_GetItemText($gListH, $i, 5)
        For $j = 0 To UBound($aChecked) - 1
            If StringLower($sPath) = StringLower($aChecked[$j]) Then
                _GUICtrlListView_SetItemChecked($gListH, $i, True)
                ExitLoop
            EndIf
        Next
        For $j = 0 To UBound($aSelected) - 1
            If StringLower($sPath) = StringLower($aSelected[$j]) Then
                _GUICtrlListView_SetItemSelected($gListH, $i, True)
                ExitLoop
            EndIf
        Next
    Next
    GUISetState(@SW_SHOW, $gGUI)
EndFunc

Func _PrepareEmbeddedBanner()
    ; Decode Base64 using the Windows Crypt32 API (built into Windows).
    Local $iRequiredBytes = 0
    Local $aSize = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryW", _
            "wstr", $g_sEmbeddedBannerBase64, "dword", StringLen($g_sEmbeddedBannerBase64), _
            "dword", 1, "ptr", 0, "dword*", $iRequiredBytes, "ptr", 0, "ptr", 0)
    If @error Then Return SetError(1, 0, False)
    If Not IsArray($aSize) Then Return SetError(1, 0, False)
    If Not $aSize[0] Then Return SetError(1, 0, False)
    If $aSize[5] <= 0 Then Return SetError(1, 0, False)

    Local $iByteCount = $aSize[5]
    Local $tBuffer = DllStructCreate("byte[" & $iByteCount & "]")
    If @error Then Return SetError(2, 0, False)

    Local $iBufferCapacity = $iByteCount
    Local $aDecode = DllCall("Crypt32.dll", "bool", "CryptStringToBinaryW", _
            "wstr", $g_sEmbeddedBannerBase64, "dword", StringLen($g_sEmbeddedBannerBase64), _
            "dword", 1, "ptr", DllStructGetPtr($tBuffer), "dword*", $iBufferCapacity, "ptr", 0, "ptr", 0)
    If @error Then Return SetError(3, 0, False)
    If Not IsArray($aDecode) Then Return SetError(3, 0, False)
    If Not $aDecode[0] Then Return SetError(3, 0, False)
    If $aDecode[5] <> $iByteCount Then Return SetError(3, 0, False)

    Local $bImage = DllStructGetData($tBuffer, 1)
    If @error Then Return SetError(4, 0, False)
    If BinaryLen($bImage) <> $iByteCount Then Return SetError(4, 0, False)
    If BinaryMid($bImage, 1, 3) <> Binary("0xFFD8FF") Then Return SetError(5, 0, False)

    ; A per-process temp file avoids dependencies and conflicts between instances.
    $gBannerPath = @TempDir & "\S2CE_ModManager_" & @AutoItPID & "_banner.jpg"
    Local $hFile = FileOpen($gBannerPath, BitOR($FO_OVERWRITE, $FO_BINARY))
    If $hFile = -1 Then
        $gBannerPath = ""
        Return SetError(6, 0, False)
    EndIf
    FileWrite($hFile, $bImage)
    Local $iWriteError = @error
    FileClose($hFile)

    If $iWriteError Or Not FileExists($gBannerPath) Or FileGetSize($gBannerPath) <> $iByteCount Then
        If FileExists($gBannerPath) Then FileDelete($gBannerPath)
        $gBannerPath = ""
        Return SetError(7, 0, False)
    EndIf
    Return True
EndFunc

Func _GetSystemDpiZoom()
    ; Win10 1607+ 可直接查询系统 DPI
    Local $aRet = DllCall("user32.dll", "uint", "GetDpiForSystem")
    If Not @error And IsArray($aRet) And $aRet[0] > 0 Then Return $aRet[0] / 96.0
    ; 回退：读注册表
    Local $iDPI = RegRead("HKCU\Control Panel\Desktop\WindowMetrics", "AppliedDPI")
    If @error Or $iDPI = 0 Then Return 1.0
    Return $iDPI / 96.0
EndFunc

Func _Scale($iValue)
    Return Int($iValue * $g_iZoom + 0.5)
EndFunc

Func _CreateUI()
    Local $id, $sBanner = $gBannerPath

    ; The embedded banner is materialized in the temp folder at startup.
    ; The display box remains 300x171 to preserve the original aspect ratio.
    If FileExists($sBanner) Then
        GUICtrlCreatePic($sBanner, _Scale(20), _Scale(15), _Scale(300), _Scale(171))
    Else
        GUICtrlCreateLabel("", _Scale(20), _Scale(15), _Scale(300), _Scale(171))
        GUICtrlSetBkColor(-1, 0x22252C)
        GUICtrlSetState(-1, $GUI_DISABLE)
        $id = GUICtrlCreateLabel("S2CE", _Scale(38), _Scale(52), _Scale(260), _Scale(38))
        GUICtrlSetFont($id, 24, 800, 0, "Segoe UI")
        GUICtrlSetColor($id, 0xE5B567)
        $id = GUICtrlCreateLabel("SHOGUN 2  /  MOD MANAGER", _Scale(40), _Scale(98), _Scale(255), _Scale(22))
        GUICtrlSetFont($id, 9, 600, 0, "Segoe UI")
        GUICtrlSetColor($id, 0xD5D9E0)
        $id = GUICtrlCreateLabel(_T("横幅图片加载失败"), _Scale(40), _Scale(145), _Scale(260), _Scale(22))
        GUICtrlSetFont($id, 8, 400, 0, "Segoe UI")
        GUICtrlSetColor($id, 0x8F9BAA)
    EndIf

    ; Language selectors in the upper-right corner.
    $gBtnLangEnglish = GUICtrlCreateButton("English", _Scale(830), _Scale(12), _Scale(68), _Scale(27))
    _StyleButton($gBtnLangEnglish)
    $gBtnLangChinese = GUICtrlCreateButton("中文", _Scale(906), _Scale(12), _Scale(68), _Scale(27))
    _StyleButton($gBtnLangChinese)
    _StyleLanguageButtons()

    ; Brand / title block to the right of the banner.
    $id = GUICtrlCreateLabel("For Total War: SHOGUN 2 - Complete Edition", _Scale(350), _Scale(32), _Scale(465), _Scale(20))
    GUICtrlSetFont($id, 9, 700, 0, "Segoe UI")
    GUICtrlSetColor($id, 0xD8A45E)
    $id = GUICtrlCreateLabel("S2CE ModManager", _Scale(348), _Scale(58), _Scale(610), _Scale(40))
    GUICtrlSetFont($id, 23, 700, 0, "Segoe UI")
    GUICtrlSetColor($id, 0xF1F3F5)
    $id = GUICtrlCreateLabel(_T("《全面战争：幕府将军2》完全版 · MOD管理工具"), _Scale(350), _Scale(105), _Scale(600), _Scale(22))
    GUICtrlSetFont($id, 10, 400, 0, "Segoe UI")
    GUICtrlSetColor($id, 0xAAB4C3)
    GUICtrlCreateLabel("", _Scale(350), _Scale(141), _Scale(600), _Scale(2))
    GUICtrlSetBkColor(-1, 0xD8A45E)
    $id = GUICtrlCreateLabel(_T("使用“激活 / 停用”按钮分别管理 PACK"), _Scale(350), _Scale(155), _Scale(425), _Scale(22))
    GUICtrlSetFont($id, 9, 400, 0, "Segoe UI")
    GUICtrlSetColor($id, 0x8F9BAA)
	; 作者信息：与中文标题同行，右侧对齐
	$id = GUICtrlCreateLabel(_T("作者：Sorin"), _Scale(790), _Scale(155), _Scale(170), _Scale(22), $SS_RIGHT)
	GUICtrlSetFont($id, 10, 600, 0, "Segoe UI")
	GUICtrlSetColor($id, 0xD8A45E)

    ; Divider under the complete top banner.
    GUICtrlCreateLabel("", _Scale(15), _Scale(198), _Scale(965), _Scale(1))
    GUICtrlSetBkColor(-1, 0x383C46)

    ; Lower-left column: paths and concise usage notes.
    $id = GUICtrlCreateLabel(_T("设置"), _Scale(20), _Scale(215), _Scale(245), _Scale(24))
    GUICtrlSetFont($id, 12, 700, 0, "Segoe UI")
    GUICtrlSetColor($id, 0xE5B567)

    $id = GUICtrlCreateLabel(_T("游戏目录"), _Scale(20), _Scale(250), _Scale(245), _Scale(20))
    GUICtrlSetColor($id, 0xE5E7EB)
    GUICtrlSetFont($id, 9, 600, 0, "Segoe UI")
    $gLblGame = GUICtrlCreateLabel("", _Scale(20), _Scale(275), _Scale(250), _Scale(48))
    GUICtrlSetColor($gLblGame, 0xAAB4C3)
    GUICtrlSetFont($gLblGame, 8, 400, 0, "Segoe UI")
    $gBtnBrowseGame = GUICtrlCreateButton(_T("修改游戏目录"), _Scale(20), _Scale(328), _Scale(122), _Scale(32))
    _StyleButton($gBtnBrowseGame)
    $gBtnOpenGame = GUICtrlCreateButton(_T("打开游戏目录"), _Scale(143), _Scale(328), _Scale(122), _Scale(32))
    _StyleButton($gBtnOpenGame)

    GUICtrlCreateLabel("", _Scale(20), _Scale(374), _Scale(245), _Scale(1))
    GUICtrlSetBkColor(-1, 0x383C46)
    $id = GUICtrlCreateLabel(_T("用户脚本目录"), _Scale(20), _Scale(390), _Scale(245), _Scale(20))
    GUICtrlSetColor($id, 0xE5E7EB)
    GUICtrlSetFont($id, 9, 600, 0, "Segoe UI")
    $gLblScript = GUICtrlCreateLabel("", _Scale(20), _Scale(415), _Scale(250), _Scale(48))
    GUICtrlSetColor($gLblScript, 0xAAB4C3)
    GUICtrlSetFont($gLblScript, 8, 400, 0, "Segoe UI")
    $gBtnBrowseScript = GUICtrlCreateButton(_T("修改脚本目录"), _Scale(20), _Scale(468), _Scale(122), _Scale(32))
    _StyleButton($gBtnBrowseScript)
    $gBtnOpenScript = GUICtrlCreateButton(_T("打开user.script.txt"), _Scale(143), _Scale(468), _Scale(122), _Scale(32))
    _StyleButton($gBtnOpenScript)

    GUICtrlCreateLabel("", _Scale(20), _Scale(514), _Scale(245), _Scale(1))
    GUICtrlSetBkColor(-1, 0x383C46)
    $id = GUICtrlCreateLabel(_T("使用说明"), _Scale(20), _Scale(531), _Scale(245), _Scale(20))
    GUICtrlSetColor($id, 0xD8A45E)
    GUICtrlSetFont($id, 10, 600, 0, "Segoe UI")
    $id = GUICtrlCreateLabel(_T("1.先勾选需要处理的 PACK；未勾选项不操作。") & @CRLF & _
            _T("2.激活：将勾选且位于 Disabled_Mods 的 PACK 移回 data，并更新 user.script.txt。") & @CRLF & _
            _T("3.停用：将勾选且位于 data 的 PACK 移至 Disabled_Mods，并更新 user.script.txt。") & @CRLF & _
            _T("4.选择已激活的 PACK 行，使用上移/下移调整加载顺序。") & @CRLF & _
            _T("5.完成后建议重新启动游戏。"), _
            _Scale(20), _Scale(559), _Scale(250), _Scale(130))
    GUICtrlSetColor($id, 0xAAB4C3)
    GUICtrlSetFont($id, 8, 400, 0, "Segoe UI")

    ; Lower-right column: list and actions.
    $id = GUICtrlCreateLabel(_T("本地 PACK 列表"), _Scale(300), _Scale(215), _Scale(400), _Scale(24))
    GUICtrlSetFont($id, 12, 700, 0, "Segoe UI")
    GUICtrlSetColor($id, 0xE5E7EB)
    ; 排序按钮使用列表行的高亮选择状态；复选框仍只用于批量激活/停用。
    $gBtnMoveUp = GUICtrlCreateButton(_T("↑ 上移"), _Scale(790), _Scale(210), _Scale(80), _Scale(30))
    _StyleButton($gBtnMoveUp)
    GUICtrlSetBkColor($gBtnMoveUp, 0x356A9A)
    $gBtnMoveDown = GUICtrlCreateButton(_T("↓ 下移"), _Scale(875), _Scale(210), _Scale(80), _Scale(30))
    _StyleButton($gBtnMoveDown)
    GUICtrlSetBkColor($gBtnMoveDown, 0x356A9A)
    ; 状态灯与常驻文字放在“设置”标题所在区域的右上角。
    $gLblReadyLight = GUICtrlCreateLabel("●", _Scale(130), _Scale(215), _Scale(22), _Scale(24), $SS_CENTER)
    GUICtrlSetFont($gLblReadyLight, 16, 700, 0, "Segoe UI Symbol")
    $gLblReadyText = GUICtrlCreateLabel(_T("配置缺失"), _Scale(154), _Scale(223), _Scale(110), _Scale(20))
    GUICtrlSetFont($gLblReadyText, 9, 400, 0, "Segoe UI")
    GUICtrlSetColor($gLblReadyText, 0xAAB4C3)

    $gList = GUICtrlCreateListView(_T("选中|PACK 文件名|类型|大小|文件位置|内部路径"), _
            _Scale(300), _Scale(244), _Scale(680), _Scale(325), BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS))
    $gListH = GUICtrlGetHandle($gList)
    _GUICtrlListView_SetExtendedListViewStyle($gListH, _
            BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES))
    _GUICtrlListView_SetColumnWidth($gListH, 0, _Scale(50))
    _GUICtrlListView_SetColumnWidth($gListH, 1, _Scale(285))
    _GUICtrlListView_SetColumnWidth($gListH, 2, _Scale(60))
    _GUICtrlListView_SetColumnWidth($gListH, 3, _Scale(100))
    _GUICtrlListView_SetColumnWidth($gListH, 4, _Scale(185))
    _GUICtrlListView_SetColumnWidth($gListH, 5, 0) ; 隐藏列保存真实文件路径，供移动操作使用
    GUICtrlSetBkColor($gList, 0x242831)
    GUICtrlSetColor($gList, 0xE5E7EB)
    GUICtrlSetFont($gList, 12, 400, 0, "Segoe UI")   ; 增大字体，从而增大行高

    ; Action bar below the ListView.
    $gBtnScan = GUICtrlCreateButton(_T("重新扫描"), _Scale(300), _Scale(582), _Scale(90), _Scale(36))
    _StyleButton($gBtnScan)
    GUICtrlSetBkColor($gBtnScan, 0xA66E32) ; 棕橙色
    GUICtrlSetColor($gBtnScan, 0xFFFFFF)
    $gBtnActivate = GUICtrlCreateButton(_T("激活"), _Scale(430), _Scale(582), _Scale(80), _Scale(36))
    GUICtrlSetBkColor($gBtnActivate, 0x397B57) ; 绿色
    GUICtrlSetColor($gBtnActivate, 0xFFFFFF)
    GUICtrlSetFont($gBtnActivate, 9, 700, 0, "Segoe UI")
    $gBtnDeactivate = GUICtrlCreateButton(_T("停用"), _Scale(510), _Scale(582), _Scale(80), _Scale(36))
    _StyleButton($gBtnDeactivate)
    GUICtrlSetBkColor($gBtnDeactivate, 0xA83D45) ; 红色
    GUICtrlSetColor($gBtnDeactivate, 0xFFFFFF)
    $gBtnSteam = GUICtrlCreateButton(_T("从Steam启动游戏"), _Scale(630), _Scale(582), _Scale(110), _Scale(36))
    _StyleButton($gBtnSteam)
    GUICtrlSetBkColor($gBtnSteam, 0x356A9A) ; 蓝色
    GUICtrlSetColor($gBtnSteam, 0xFFFFFF)
    $gBtnOpenData = GUICtrlCreateButton(_T("打开 data"), _Scale(780), _Scale(582), _Scale(95), _Scale(36))
    _StyleButton($gBtnOpenData)
    $gBtnOpenDisabled = GUICtrlCreateButton(_T("打开停用区"), _Scale(880), _Scale(582), _Scale(95), _Scale(36))
    _StyleButton($gBtnOpenDisabled)

    GUICtrlCreateLabel(_T("状态"), _Scale(300), _Scale(635), _Scale(45), _Scale(20))
    GUICtrlSetColor(-1, 0x8F9BAA)
    GUICtrlSetFont(-1, 9, 600, 0, "Segoe UI")
    $gLblStatus = GUICtrlCreateLabel(_T("就绪"), _Scale(348), _Scale(635), _Scale(625), _Scale(20))
    GUICtrlSetColor($gLblStatus, 0xD8A45E)
    ; Session-only activity feed; no persistent log file is created.
    $gLog = GUICtrlCreateEdit("", _Scale(300), _Scale(657), _Scale(680), _Scale(28), _
            BitOR($ES_READONLY, $ES_MULTILINE, $ES_AUTOVSCROLL))
    GUICtrlSetBkColor($gLog, 0x20232A)
    GUICtrlSetColor($gLog, 0xB8C0CC)
EndFunc

Func _StyleButton($id)
    GUICtrlSetBkColor($id, 0x303540)
    GUICtrlSetColor($id, 0xE5E7EB)
    GUICtrlSetFont($id, 9, 600, 0, "Segoe UI")
EndFunc

Func _FindGameDir()
    ; 按用户指定的顺序检查常见安装位置。
    Local $a[6] = [ _
            "C:\Program Files (x86)\Steam\steamapps\common\Shogun 2 Complete Edition", _
            "D:\SteamLibrary\steamapps\common\Shogun 2 Complete Edition", _
            "E:\SteamLibrary\steamapps\common\Shogun 2 Complete Edition", _
            "F:\SteamLibrary\steamapps\common\Shogun 2 Complete Edition", _
            "G:\SteamLibrary\steamapps\common\Shogun 2 Complete Edition", _
            "H:\SteamLibrary\steamapps\common\Shogun 2 Complete Edition"]
    For $i = 0 To UBound($a) - 1
        If FileExists($a[$i] & "\data") Then Return $a[$i]
    Next
    Return ""
EndFunc

Func _UpdatePaths()
    $gDataDir = ""
    $gDisabledDir = ""
    $gScriptFile = $gScriptDir & "\user.script.txt"
    If $gGameDir <> "" Then
        $gDataDir = $gGameDir & "\data"
        $gDisabledDir = $gGameDir & "\Disabled_Mods"
    EndIf
EndFunc

Func _RefreshPathLabels()
    Local $sGame = $gGameDir, $sScript = $gScriptDir
    If $sGame = "" Then $sGame = _T("请手动选择")
    GUICtrlSetData($gLblGame, $sGame)
    GUICtrlSetData($gLblScript, $sScript)
    _UpdateReadyLight()
EndFunc

Func _UpdateReadyLight()
    Local $bGameOK = ($gGameDir <> "" And FileExists($gGameDir & "\shogun2_complete_edition.exe"))
    Local $bScriptOK = ($gScriptFile <> "" And FileExists($gScriptFile))
    If $bGameOK And $bScriptOK Then
        GUICtrlSetColor($gLblReadyLight, 0x45D483)
        GUICtrlSetData($gLblReadyText, _T("已就绪"))
        GUICtrlSetColor($gLblReadyText, 0x45D483)
    Else
        GUICtrlSetColor($gLblReadyLight, 0xF05252)
        GUICtrlSetData($gLblReadyText, _T("请检查路径设置"))
        GUICtrlSetColor($gLblReadyText, 0xF05252)
    EndIf
EndFunc

Func _ChooseGameDir()
    Local $s = FileSelectFolder(_T("请选择包含 data 子目录的游戏根目录"), "", 0, $gGameDir)
    If @error Or $s = "" Then Return
    If Not FileExists($s & "\data") Then
        MsgBox($MB_ICONWARNING, $APP, _T("所选目录不包含 data 子目录。"))
        Return
    EndIf
    $gGameDir = $s
    _UpdatePaths()
    _RefreshPathLabels()
    _ScanMods()
EndFunc

Func _ChooseScriptDir()
    Local $s = FileSelectFolder(_T("请选择用户脚本目录"), "", 0, $gScriptDir)
    If @error Or $s = "" Then Return
    $gScriptDir = $s
    _UpdatePaths()
    _RefreshPathLabels()
    _Log(_T("已更新用户脚本目录。"))
EndFunc

Func _OpenGameDir()
    If $gGameDir = "" Or Not FileExists($gGameDir) Then
        MsgBox($MB_ICONWARNING, $APP, _T("尚未设置有效的游戏目录。"))
        Return
    EndIf
    ShellExecute($gGameDir)
EndFunc

Func _OpenScriptFile()
    If $gScriptDir = "" Then Return
    If FileExists($gScriptFile) Then
        ShellExecute($gScriptFile)
    Else
        MsgBox($MB_ICONINFORMATION, $APP, _T("user.script.txt 尚不存在。") & @CRLF & _T("脚本目录：") & $gScriptDir)
        If FileExists($gScriptDir) Then ShellExecute($gScriptDir)
    EndIf
EndFunc

Func _ScanMods()
    If $gGameDir = "" Or Not FileExists($gDataDir) Then
        _GUICtrlListView_DeleteAllItems($gListH)
        _SetStatus(_T("请先设置有效的游戏目录。"))
        Return
    EndIf
    _GUICtrlListView_DeleteAllItems($gListH)
    _ScanFolder($gDataDir)
    Local $iActiveCount = _GUICtrlListView_GetItemCount($gListH)
    _ScanFolder($gDisabledDir)

    ; 先确保顺序稳定，再按 user.script.txt 中现有的 PACK 指令排列已激活 MOD。
    _SortRowsByName(0, $iActiveCount - 1)
    _SortActiveRowsByScriptOrder($iActiveCount)
    _SortRowsByName($iActiveCount, _GUICtrlListView_GetItemCount($gListH) - 1)

    _SetStatus(_T("扫描完成，共 ") & _GUICtrlListView_GetItemCount($gListH) & _T(" 个 PACK。"))
    _Log(_T("扫描完成。"))
EndFunc

Func _SortRowsByName($iStart, $iEnd)
    If $iStart < 0 Or $iEnd <= $iStart Then Return
    For $i = $iStart To $iEnd - 1
        For $j = $i + 1 To $iEnd
            Local $sLeft = StringLower(_GUICtrlListView_GetItemText($gListH, $i, 1))
            Local $sRight = StringLower(_GUICtrlListView_GetItemText($gListH, $j, 1))
            If $sLeft > $sRight Then _SwapListRows($i, $j)
        Next
    Next
EndFunc

Func _SortActiveRowsByScriptOrder($iActiveCount)
    If $iActiveCount <= 1 Or Not FileExists($gScriptFile) Then Return
    Local $hRead = FileOpen($gScriptFile, $FO_READ + $FO_UTF16_LE)
    If $hRead = -1 Then Return
    Local $sContent = FileRead($hRead)
    Local $iReadErr = @error
    FileClose($hRead)
    If $iReadErr Then Return

    Local $aLines = StringSplit(StringReplace($sContent, @CRLF, @LF), @LF, 1)
    Local $iTarget = 0
    For $iLine = 1 To $aLines[0]
        Local $sPackName = _ExtractPackName($aLines[$iLine])
        If $sPackName = "" Then ContinueLoop
        Local $iFound = -1
        For $iRow = $iTarget To $iActiveCount - 1
            If StringLower(_GUICtrlListView_GetItemText($gListH, $iRow, 1)) = StringLower($sPackName) Then
                $iFound = $iRow
                ExitLoop
            EndIf
        Next
        If $iFound >= $iTarget Then
            For $iMove = $iFound To $iTarget + 1 Step -1
                _SwapListRows($iMove, $iMove - 1)
            Next
            $iTarget += 1
            If $iTarget >= $iActiveCount Then ExitLoop
        EndIf
    Next
EndFunc

Func _SwapListRows($iA, $iB)
    If $iA = $iB Then Return
    Local $aTextA[6], $aTextB[6]
    Local $bCheckedA = _GUICtrlListView_GetItemChecked($gListH, $iA)
    Local $bCheckedB = _GUICtrlListView_GetItemChecked($gListH, $iB)
    Local $bSelectedA = _GUICtrlListView_GetItemSelected($gListH, $iA)
    Local $bSelectedB = _GUICtrlListView_GetItemSelected($gListH, $iB)

    For $iCol = 0 To 5
        $aTextA[$iCol] = _GUICtrlListView_GetItemText($gListH, $iA, $iCol)
        $aTextB[$iCol] = _GUICtrlListView_GetItemText($gListH, $iB, $iCol)
    Next
    For $iCol = 0 To 5
        _GUICtrlListView_SetItemText($gListH, $iA, $aTextB[$iCol], $iCol)
        _GUICtrlListView_SetItemText($gListH, $iB, $aTextA[$iCol], $iCol)
    Next

    _GUICtrlListView_SetItemChecked($gListH, $iA, $bCheckedB)
    _GUICtrlListView_SetItemChecked($gListH, $iB, $bCheckedA)
    _GUICtrlListView_SetItemSelected($gListH, $iA, $bSelectedB)
    _GUICtrlListView_SetItemSelected($gListH, $iB, $bSelectedA)
EndFunc

Func _ScanFolder($sFolder)
    If Not FileExists($sFolder) Then Return
    Local $h = FileFindFirstFile($sFolder & "\*.pack")
    If $h = -1 Then Return
    While 1
        Local $sName = FileFindNextFile($h)
        If @error Then ExitLoop
        Local $sFull = $sFolder & "\" & $sName
        If StringInStr(FileGetAttrib($sFull), "D") Then ContinueLoop
        ; 官方游戏 PACK 不属于用户 MOD，扫描时自动过滤（文件名不区分大小写）。
        If _IsOfficialPack($sName) Then ContinueLoop
        Local $i = _GUICtrlListView_AddItem($gListH, "")
        _GUICtrlListView_AddSubItem($gListH, $i, $sName, 1)
        _GUICtrlListView_AddSubItem($gListH, $i, _ReadPackType($sFull), 2)
        _GUICtrlListView_AddSubItem($gListH, $i, _FormatSize(FileGetSize($sFull)), 3)
        _GUICtrlListView_AddSubItem($gListH, $i, _GetLocationLabel($sFull), 4)
        _GUICtrlListView_AddSubItem($gListH, $i, $sFull, 5)
        ; 复选框只表示“本次操作目标”，不代表 PACK 当前是否已激活。
        ; 扫描后统一保持未勾选，避免误把所有活动 PACK 当作批量停用目标。
        _GUICtrlListView_SetItemChecked($gListH, $i, False)
    WEnd
    FileClose($h)
EndFunc

Func _IsOfficialPack($sName)
    Switch StringLower($sName)
        Case "audio.pack", "boot.pack", "bp_orig.pack", "campaign_streaming.pack", _
                "data.pack", "data_fots.pack", "local_global.pack", "models.pack", _
                "models2.pack", "movies.pack", "movies2.pack", "movies_fots.pack", _
                "shaders.pack", "terrain.pack", "web_content.pack"
            Return True
    EndSwitch
    Return False
EndFunc

Func _ReadPackType($sPath)
    Local $hFile = FileOpen($sPath, $FO_BINARY)
    If $hFile = -1 Then Return _T("读取失败")

    ; PFH3 header 至少 32 字节，多读一点便于校验。
    Local $bHeader = FileRead($hFile, 32)
    FileClose($hFile)

    If @error Or BinaryLen($bHeader) < 8 Then Return _T("头部无效")

    ; 签名前 3 字节应为 "PFH"。
    If BinaryToString(BinaryMid($bHeader, 1, 3), 1) <> "PFH" Then Return _T("非PFH")

    ; 第 4 字节低 4 位是 PFH 版本号。
    Local $iVersion = BitAND(Asc(BinaryMid($bHeader, 4, 1)), 0x0F)

    ; 类型与 bitmask 合并在 offset 4 的 u32 中（1-based 第 5 字节）。
    ; 先按小端还原 u32，再取低 3 位得到真正的类型值。
    Local $sRawHex = Hex(BinaryMid($bHeader, 5, 4))
    If StringLen($sRawHex) <> 8 Then Return _T("头部无效")
    Local $iRaw = Dec( _
            StringMid($sRawHex, 7, 2) & StringMid($sRawHex, 5, 2) & _
            StringMid($sRawHex, 3, 2) & StringMid($sRawHex, 1, 2))
    Local $iType = BitAND($iRaw, 0x7)

    Local $sTypeName
    Switch $iType
        Case 0
            $sTypeName = "Boot"
        Case 1
            $sTypeName = "Release"
        Case 2
            $sTypeName = "Patch"
        Case 3
            $sTypeName = "Mod"
        Case 4
            $sTypeName = "Movie"
        Case Else
            $sTypeName = _T("未知(") & $iType & ")"
    EndSwitch

    ; 非 PFH3 时附带版本，便于排查；PFH3 保持简洁。
    If $iVersion <> 3 Then
        $sTypeName &= " (PFH" & $iVersion & ")"
    EndIf

    Return $sTypeName
EndFunc

Func _FormatSize($n)
    If $n < 1024 Then Return $n & " B"
    If $n < 1048576 Then Return Round($n / 1024, 1) & " KB"
    Return Round($n / 1048576, 2) & " MB"
EndFunc

Func _ApplyMods($bEnable)
    If $gBusy Then Return
    If $gGameDir = "" Or Not FileExists($gDataDir) Then
        MsgBox($MB_ICONWARNING, $APP, _T("请先设置有效的游戏目录。"))
        Return
    EndIf
    Local $sActionNoun = ""
    If $bEnable Then
        $sActionNoun = ($gLang = "EN" ? "Activation" : _T("激活"))
    Else
        $sActionNoun = ($gLang = "EN" ? "Deactivation" : _T("停用"))
    EndIf
    Local $sConfirm = ""
    If $bEnable Then
        $sConfirm = _T("仅处理已勾选且位于 Disabled_Mods 的 PACK：移入 data 目录并加入 user.script.txt。")
    Else
        $sConfirm = _T("仅处理已勾选且位于 data 的 PACK：移入 Disabled_Mods 目录并从 user.script.txt 移除。")
    EndIf
    Local $iCount = _GUICtrlListView_GetItemCount($gListH)
    Local $iSelected = 0
    For $i = 0 To $iCount - 1
        If _GUICtrlListView_GetItemChecked($gListH, $i) Then $iSelected += 1
    Next
    If $iSelected = 0 Then
        Local $sNeedSelection = $bEnable ? _T("请先勾选需要激活的 PACK。") : _T("请先勾选需要停用的 PACK。")
        MsgBox($MB_ICONINFORMATION, $APP, $sNeedSelection & @CRLF & _
                _T("未勾选的项目不会被处理。"))
        Return
    EndIf
    If MsgBox(BitOR($MB_YESNO, $MB_ICONQUESTION), $APP, $sActionNoun & _T("操作：") & @CRLF & _
            $sConfirm & @CRLF & _T("建议先关闭游戏。继续吗？")) <> $IDYES Then Return

    $gBusy = True
    Local $iMoved = 0, $iFailed = 0
    Local $aChanges[0][2]
    Local $bNeedScript = False

    For $i = 0 To $iCount - 1
        Local $sName = _GUICtrlListView_GetItemText($gListH, $i, 1)
        Local $sPath = _GUICtrlListView_GetItemText($gListH, $i, 5)
        Local $bChecked = _GUICtrlListView_GetItemChecked($gListH, $i)
        If $sName = "" Or $sPath = "" Then ContinueLoop
        ; 复选框只负责指定本次操作目标：未勾选项目一律跳过。
        If Not $bChecked Then ContinueLoop
        Local $bCurrent = _IsInFolder($sPath, $gDataDir)
        ; 激活只移动当前停用区中的文件；停用只移动当前 data 目录中的文件。
        ; 已处于目标状态的文件跳过，不做重复移动。
        If $bEnable = $bCurrent Then
            _Log(_T("已处于目标状态，跳过：") & $sName)
            ContinueLoop
        EndIf
        Local $bWant = $bEnable
        If Not FileExists($sPath) Then
            _Log(_T("文件已不存在，跳过：") & $sName)
            $iFailed += 1
            ContinueLoop
        EndIf
        Local $sDest
        If $bWant Then
            $sDest = $gDataDir & "\" & $sName
        Else
            $sDest = $gDisabledDir & "\" & $sName
            If Not FileExists($gDisabledDir) Then DirCreate($gDisabledDir)
        EndIf
        If FileExists($sDest) Then
            _Log(_T("目标已存在，未覆盖：") & $sName)
            $iFailed += 1
            ContinueLoop
        EndIf
        If FileMove($sPath, $sDest, 0) Then
            _Log(_T("移动成功：") & $sName & " -> " & $sDest)
            $iMoved += 1
            _PushChange($aChanges, $sName, $bWant)
            $bNeedScript = True
        Else
            _Log(_T("移动失败：") & $sName)
            $iFailed += 1
        EndIf
    Next

    If $bNeedScript Then
        If Not _UpdateScript($aChanges) Then
            _Log(_T("严重警告：脚本更新失败。文件移动已完成，请手动检查并修正 user.script.txt。"))
            MsgBox($MB_ICONWARNING, $APP, _T("PACK 文件移动已执行，但 user.script.txt 更新失败。") & @CRLF & _T("请检查用户脚本文件：") & @CRLF & $gScriptDir)
        EndIf
    EndIf
    _ScanMods()
    _SetStatus($sActionNoun & _T("完成：成功移动 ") & $iMoved & _T(" 个，失败/跳过 ") & $iFailed & _T(" 个。"))
    _Log($sActionNoun & _T("结束。移动=") & $iMoved & _T("，失败/跳过=") & $iFailed)
    $gBusy = False
    MsgBox($MB_ICONINFORMATION, $APP, $sActionNoun & _T("操作完成。") & @CRLF & _T("成功移动：") & $iMoved & @CRLF & _T("失败/跳过：") & $iFailed & @CRLF & @CRLF & _T("请完全退出并重新启动游戏后验证。"))
EndFunc

Func _MoveSelectedPack($iDirection)
    If $gBusy Then Return
    Local $iCount = _GUICtrlListView_GetItemCount($gListH)
    Local $iSelected = -1, $iSelectedCount = 0
    For $i = 0 To $iCount - 1
        If _GUICtrlListView_GetItemSelected($gListH, $i) Then
            $iSelected = $i
            $iSelectedCount += 1
        EndIf
    Next

    If $iSelectedCount = 0 Then
        MsgBox($MB_ICONINFORMATION, $APP, _T("请先单击选中一个 PACK 行，再点击上移或下移。") & @CRLF & _
                _T("复选框仅用于批量激活/停用。"))
        Return
    EndIf
    If $iSelectedCount > 1 Then
        MsgBox($MB_ICONINFORMATION, $APP, _T("排序操作一次只处理一个 PACK。请仅选中一行。"))
        Return
    EndIf

    Local $sPath = _GUICtrlListView_GetItemText($gListH, $iSelected, 5)
    Local $sName = _GUICtrlListView_GetItemText($gListH, $iSelected, 1)
    If Not _IsInFolder($sPath, $gDataDir) Then
        MsgBox($MB_ICONINFORMATION, $APP, _T("只能调整已激活（位于 data 目录）的 PACK 加载顺序。") & @CRLF & _
                _T("请先激活该 PACK，再使用上移/下移。"))
        Return
    EndIf

    Local $iTarget = $iSelected + $iDirection
    If $iTarget < 0 Or $iTarget >= $iCount Then
        _SetStatus($iDirection < 0 ? _T("该 PACK 已位于激活列表顶部。") : _T("该 PACK 已位于激活列表底部。"))
        Return
    EndIf
    Local $sTargetPath = _GUICtrlListView_GetItemText($gListH, $iTarget, 5)
    If Not _IsInFolder($sTargetPath, $gDataDir) Then
        _SetStatus($iDirection < 0 ? _T("该 PACK 已位于激活列表顶部。") : _T("该 PACK 已位于激活列表底部。"))
        Return
    EndIf

    _SwapListRows($iSelected, $iTarget)
    If Not _WriteActiveOrderToScript() Then
        ; 如果脚本文件无法按新顺序写入，则撤销界面上的换位，避免显示顺序与实际加载顺序不一致。
        _SwapListRows($iSelected, $iTarget)
        MsgBox($MB_ICONWARNING, $APP, _T("无法更新 user.script.txt，已撤销本次排序。") & @CRLF & _
                _T("请检查脚本目录、user.script.txt 文件权限以及文件是否可写。"))
        _SetStatus(_T("排序失败：user.script.txt 未更新。"))
        Return
    EndIf

    _SetStatus(_T("已调整加载顺序：") & $sName & ( $iDirection < 0 ? _T(" 上移。") : _T(" 下移。")))
    _Log(_T("加载顺序已调整：") & $sName & ( $iDirection < 0 ? _T(" 上移") : _T(" 下移")))
EndFunc

Func _WriteActiveOrderToScript()
    If $gScriptDir = "" Then Return False
    If Not FileExists($gScriptDir) And Not DirCreate($gScriptDir) Then Return False

    ; 收集当前位于 data 的 PACK，并以列表顺序作为加载顺序。
    Local $aActiveNames[0]
    Local $iCount = _GUICtrlListView_GetItemCount($gListH)
    For $i = 0 To $iCount - 1
        Local $sPath = _GUICtrlListView_GetItemText($gListH, $i, 5)
        If _IsInFolder($sPath, $gDataDir) Then
            Local $n = UBound($aActiveNames)
            ReDim $aActiveNames[$n + 1]
            $aActiveNames[$n] = _GUICtrlListView_GetItemText($gListH, $i, 1)
        EndIf
    Next
    If UBound($aActiveNames) = 0 Then Return False

    Local $sContent = ""
    If FileExists($gScriptFile) Then
        Local $hRead = FileOpen($gScriptFile, $FO_READ + $FO_UTF16_LE)
        If $hRead = -1 Then Return False
        $sContent = FileRead($hRead)
        Local $iReadErr = @error
        FileClose($hRead)
        If $iReadErr Then Return False
    EndIf

    Local $aLines = StringSplit(StringReplace($sContent, @CRLF, @LF), @LF, 1)
    Local $aSlots[0]
    For $iLine = 1 To $aLines[0]
        Local $sPackName = _ExtractPackName($aLines[$iLine])
        If $sPackName <> "" And _FindNameInArray($sPackName, $aActiveNames) >= 0 Then
            Local $nSlot = UBound($aSlots)
            ReDim $aSlots[$nSlot + 1]
            $aSlots[$nSlot] = $iLine
        EndIf
    Next

    ; 保留脚本中其他指令/注释的位置；只替换已激活 PACK 对应的行。
    ; 如果某个已激活 PACK 尚无指令，会在最后一个 PACK 槽位后补齐；重复指令会被去重。
    Local $aOut[0]
    Local $iPackSlot = 0
    Local $iLastSlot = 0
    If UBound($aSlots) > 0 Then $iLastSlot = $aSlots[UBound($aSlots) - 1]

    If UBound($aSlots) = 0 Then
        For $iName = 0 To UBound($aActiveNames) - 1
            Local $nFirst = UBound($aOut)
            ReDim $aOut[$nFirst + 1]
            $aOut[$nFirst] = "mod """ & $aActiveNames[$iName] & """;"
        Next
    EndIf

    For $iLine = 1 To $aLines[0]
        Local $sPackName = _ExtractPackName($aLines[$iLine])
        If $sPackName <> "" And _FindNameInArray($sPackName, $aActiveNames) >= 0 Then
            If $iPackSlot < UBound($aActiveNames) Then
                Local $nManaged = UBound($aOut)
                ReDim $aOut[$nManaged + 1]
                $aOut[$nManaged] = "mod """ & $aActiveNames[$iPackSlot] & """;"
                $iPackSlot += 1
            EndIf
            ; 多余的重复 active PACK 指令不再复制。
        Else
            Local $nOther = UBound($aOut)
            ReDim $aOut[$nOther + 1]
            $aOut[$nOther] = _NormalizeScriptLine($aLines[$iLine])
        EndIf

        If $iLine = $iLastSlot And $iLastSlot > 0 Then
            While $iPackSlot < UBound($aActiveNames)
                Local $nExtra = UBound($aOut)
                ReDim $aOut[$nExtra + 1]
                $aOut[$nExtra] = "mod """ & $aActiveNames[$iPackSlot] & """;"
                $iPackSlot += 1
            WEnd
        EndIf
    Next

    Local $sNew = ""
    For $iLine = 0 To UBound($aOut) - 1
        If $iLine > 0 Then $sNew &= @CRLF
        $sNew &= $aOut[$iLine]
    Next
    If $sNew <> "" And StringRight($sNew, 2) <> @CRLF Then $sNew &= @CRLF

    Local $hWrite = FileOpen($gScriptFile, $FO_OVERWRITE + $FO_UTF16_LE)
    If $hWrite = -1 Then Return False
    FileWrite($hWrite, $sNew)
    Local $bOK = (@error = 0)
    FileClose($hWrite)
    If $bOK Then _Log(_T("已按列表顺序更新 user.script.txt（UTF-16 LE）。"))
    Return $bOK
EndFunc

Func _FindNameInArray($sName, ByRef $aNames)
    For $i = 0 To UBound($aNames) - 1
        If StringLower($aNames[$i]) = StringLower($sName) Then Return $i
    Next
    Return -1
EndFunc

Func _ExtractPackName($sLine)
    Local $aMatch = StringRegExp($sLine, "(?i)^\s*mod\s+(?:""([^""]+\.pack)""|([^""\s;]+\.pack))\s*;\s*$", 1)
    If @error Or Not IsArray($aMatch) Then Return ""
    Local $sName = $aMatch[0]
    If $sName = "" And UBound($aMatch) > 1 Then $sName = $aMatch[1]
    Return $sName
EndFunc

Func _PushChange(ByRef $a, $sName, $bEnabled)
    Local $n = UBound($a)
    ReDim $a[$n + 1][2]
    $a[$n][0] = $sName
    $a[$n][1] = $bEnabled
EndFunc

Func _GetLocationLabel($sPath)
    If _IsInFolder($sPath, $gDataDir) Then Return _T("位于data目录")
    If _IsInFolder($sPath, $gDisabledDir) Then Return _T("位于Disabled_Mods目录")
    Return _T("位于其他路径")
EndFunc

Func _IsInFolder($sPath, $sFolder)
    Local $p = StringLower(StringReplace($sPath, "/", "\"))
    Local $f = StringLower(StringRight($sFolder, 1) = "\" ? $sFolder : $sFolder & "\")
    Return StringLeft($p, StringLen($f)) = $f
EndFunc

Func _UpdateScript(ByRef $aChanges)
    If $gScriptDir = "" Then Return False
    If Not FileExists($gScriptDir) And Not DirCreate($gScriptDir) Then Return False
    Local $sContent = ""
    If FileExists($gScriptFile) Then
        Local $hRead = FileOpen($gScriptFile, $FO_READ + $FO_UTF16_LE)
        If $hRead = -1 Then Return False
        $sContent = FileRead($hRead)
        Local $iReadErr = @error
        FileClose($hRead)
        If $iReadErr Then Return False
    EndIf

    Local $aLines = StringSplit(StringReplace($sContent, @CRLF, @LF), @LF, 1)
    Local $aOut[0]
    For $i = 1 To $aLines[0]
        If $aLines[$i] = "" Then ContinueLoop
        Local $n = UBound($aOut)
        ReDim $aOut[$n + 1]
        ; Normalize recognized PACK directives to: mod "example.pack";
        $aOut[$n] = _NormalizeScriptLine($aLines[$i])
    Next

    ; Newly enabled entries are inserted at the top, preserving their
    ; selection order; entries higher in user.script.txt load earlier.
    Local $iNewPrefix = 0
    For $c = 0 To UBound($aChanges) - 1
        Local $sName = $aChanges[$c][0]
        Local $bEnable = $aChanges[$c][1]
        Local $bFound = False
        For $j = 0 To UBound($aOut) - 1
            If _IsScriptLineForPack($aOut[$j], $sName) Then
                $bFound = True
                If Not $bEnable Then $aOut[$j] = ""
            EndIf
        Next
        If $bEnable And Not $bFound Then
            Local $n2 = UBound($aOut)
            ReDim $aOut[$n2 + 1]
            For $k = $n2 To $iNewPrefix + 1 Step -1
                $aOut[$k] = $aOut[$k - 1]
            Next
            $aOut[$iNewPrefix] = "mod """ & $sName & """;"
            $iNewPrefix += 1
        EndIf
    Next

    Local $sNew = ""
    For $i = 0 To UBound($aOut) - 1
        If $aOut[$i] = "" Then ContinueLoop
        If $sNew <> "" Then $sNew &= @CRLF
        $sNew &= $aOut[$i]
    Next
    If $sNew <> "" Then $sNew &= @CRLF

    Local $hWrite = FileOpen($gScriptFile, $FO_OVERWRITE + $FO_UTF16_LE)
    If $hWrite = -1 Then Return False
    FileWrite($hWrite, $sNew)
    Local $bOK = (@error = 0)
    FileClose($hWrite)
    If $bOK Then _Log(_T("user.script.txt 已更新（UTF-16 LE）。"))
    Return $bOK
EndFunc

Func _NormalizeScriptLine($sLine)
    ; Accept both legacy forms and normalize recognized .pack directives.
    ; Quoted filenames may contain spaces; unquoted names may not.
    Local $aMatch = StringRegExp($sLine, "(?i)^\s*mod\s+(?:""([^""]+\.pack)""|([^""\s;]+\.pack))\s*;\s*$", 1)
    If @error Then Return $sLine
    If Not IsArray($aMatch) Then Return $sLine

    Local $sName = $aMatch[0]
    If $sName = "" And UBound($aMatch) > 1 Then $sName = $aMatch[1]
    If $sName = "" Then Return $sLine
    Return "mod """ & $sName & """;"
EndFunc

Func _IsScriptLineForPack($sLine, $sName)
    Local $sEsc = StringRegExpReplace($sName, "([\\.^$|()\[\]{}*+?])", "\\$1")
    ; Match both canonical quoted and older unquoted directives.
    Local $sPattern = "(?i)^\s*mod\s+(?:""" & $sEsc & """|" & $sEsc & ")\s*;\s*$"
    Return StringRegExp($sLine, $sPattern) = 1
EndFunc

Func _OpenFolder($sPath)
    If $sPath = "" Then Return
    If Not FileExists($sPath) Then DirCreate($sPath)
    If FileExists($sPath) Then
        ShellExecute($sPath)
    Else
        MsgBox($MB_ICONWARNING, $APP, _T("目录无法创建或访问：") & $sPath)
    EndIf
EndFunc

Func _SetStatus($s)
    GUICtrlSetData($gLblStatus, $s)
EndFunc

Func _Log($s)
    ; Session-only activity feed. Nothing is written to a persistent log file.
    Local $old = GUICtrlRead($gLog)
    If $old <> "" Then $old &= @CRLF
    Local $line = "[" & @HOUR & ":" & @MIN & ":" & @SEC & "] " & $s
    GUICtrlSetData($gLog, $old & $line)
EndFunc
