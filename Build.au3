#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         EyeZiS

 Script Function:
	Automates the process of building a .rmskin
	NOTE: I have no idea how to do this only with the commandline

#ce ----------------------------------------------------------------------------

Global Const $sSkin = "Curvs"
Global Const $sSkinFolder = @ScriptDir
Global Const $sVersion = IniRead($sSkin & ".ini", "Metadata", "Version", "1.0")

ShellExecute("C:\Program Files\Rainmeter\Rainmeter.exe", "!Manage Skins")

$hWin = WinWait("Manage Rainmeter")
WinActivate($hWin)
ControlClick($hWin, "", "[CLASS:Button; INSTANCE:2]") ; Click on the create package button

$hWin2 = WinWait("Rainmeter Skin Packager")
WinActivate($hWin2)
; Fill in the form
ControlSetText($hWin2, "", "[CLASS:Edit; INSTANCE:1]", $sSkin)
ControlSetText($hWin2, "", "[CLASS:Edit; INSTANCE:2]", "EyeZiS")
ControlSetText($hWin2, "", "[CLASS:Edit; INSTANCE:3]", $sVersion)

ControlClick($hWin2, "", "[CLASS:Button; INSTANCE:3]") ; Add a skin to the package
$hWin3 = WinWait("Add")
WinActivate($hWin3)
ControlCommand($hWin3, "", "[CLASS:ComboBox; INSTANCE:1]", "SelectString", $sSkin)
Sleep(500)
ControlClick($hWin3, "", "[CLASS:Button; INSTANCE:4]")
WinWaitClose($hWin3)

ControlClick($hWin2, "", "[CLASS:Button; INSTANCE:5]") ; Add a plugin to the package
$hWin3 = WinWait("Add")

WinActivate($hWin3)
ControlClick($hWin3, "", "[CLASS:Button; INSTANCE:1]") ; Select 32 bit plugin
$hWin4 = WinWait("Select plugin file")
WinActivate($hWin4)
ControlClick($hWin4, "", "[CLASS:ToolbarWindow32; INSTANCE:2]", "left", 1, 0, 0)
Sleep(500)
ControlSend($hWin4, "", "[CLASS:Edit; INSTANCE:2]", "C:\Users\Dank memes\Desktop\Rainmeter Plugin dev\C++\PluginMouseInfo\x32\Release", 1)
ControlSend($hWin4, "", "[CLASS:Edit; INSTANCE:2]", "{ENTER}")
Sleep(500)
ControlSend($hWin4, "", "[CLASS:Edit; INSTANCE:1]", "MouseInfo.dll", 1)
ControlSend($hWin4, "", "[CLASS:Edit; INSTANCE:1]", "{ENTER}")
ControlClick($hWin4, "", "[CLASS:Button; INSTANCE:1]")
WinWaitClose($hWin4)

Sleep(2000)

WinActivate($hWin3)
ControlClick($hWin3, "", "[CLASS:Button; INSTANCE:2]") ; Select 64 bit plugin
$hWin4 = WinWait("Select plugin file")
WinActivate($hWin4)
ControlClick($hWin4, "", "[CLASS:ToolbarWindow32; INSTANCE:2]", "left", 1, 0, 0)
Sleep(500)
ControlSend($hWin4, "", "[CLASS:Edit; INSTANCE:2]", "C:\Users\Dank memes\Desktop\Rainmeter Plugin dev\C++\PluginMouseInfo\x64\Release", 1)
ControlSend($hWin4, "", "[CLASS:Edit; INSTANCE:2]", "{ENTER}")
Sleep(500)
ControlSend($hWin4, "", "[CLASS:Edit; INSTANCE:1]", "MouseInfo.dll", 1)
ControlSend($hWin4, "", "[CLASS:Edit; INSTANCE:1]", "{ENTER}")
ControlClick($hWin4, "", "[CLASS:Button; INSTANCE:1]")
WinWaitClose($hWin4)

ControlClick($hWin3, "", "[CLASS:Button; INSTANCE:3]") ; Add the plugin
WinWaitClose($hWin3)

WinActivate($hWin2)
ControlClick($hWin2, "", "[CLASS:Button; INSTANCE:7]") ; Click next

$sFile = ControlGetText($hWin2, "", "[CLASS:Edit; INSTANCE:1]")
ControlClick($hWin2, "", "[CLASS:Button; INSTANCE:4]") ; Select the "load skin" radio button
ControlSetText($hWin2, "", "[CLASS:Edit; INSTANCE:2]", StringFormat("%s\%s.ini", $sSkin, $sSkin)) ; Enter the skin to load

ControlSetText($hWin2, "", "[CLASS:Edit; INSTANCE:3]", "3.2.1.2386") ; Set rainmeter version
ControlCommand($hWin2, "", "[CLASS:ComboBox; INSTANCE:2]", "SelectString", "Vista") ; Set windows version

ControlCommand($hWin2, "", "[CLASS:SysTabControl32; INSTANCE:1]", "TabRight", "2") ; Go to the next tab
Sleep(1500)
ControlSetText($hWin2, "", "[CLASS:Edit; INSTANCE:2]", $sSkin & "\@Resources\Variables.inc") ; Set our variables.inc file
ControlClick($hWin2, "", "[CLASS:Button; INSTANCE:2]") ; Check the "merge skins" check box
Sleep(1000)

; Create the package
ControlClick($hWin2, "", "[CLASS:Button; INSTANCE:17]")

; A "human" should close the packager now

Do
	Sleep(100)
Until Not WinExists($hWin)

FileDelete($sSkinFolder & "\*.rmskin")

ConsoleWrite($sFile & @CRLF)
ConsoleWrite($sSkinFolder & @CRLF)
FileMove($sFile, $sSkinFolder)