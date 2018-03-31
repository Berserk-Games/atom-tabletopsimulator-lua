## 10.4.2
* Updated API links in autocomplete snippets to point to new API website

## 10.4.1
* Fixed bug in script loading from TTS

## 10.4.0
* Added onPlayerConnect, onPlayerDisconnect

## 10.3.0
* Added log, logStyle
* Force active file to open last on Save & Play so it remains active
* Removed 'experimental' tag from some features

## 10.2.1
* Fix #47

## 10.2.0
* TTS now fully supports utf-8, so plugin no longer converts utf-8 to \u codes (it still does the reverse if the setting is enabled)
* Open Save File command
* Generate GUID Code command (pulls GUIDs from TTS save file and makes Lua for them). Format customizable in Style section of package settings.
* Execute Selected Lua (ctrl-@) - send whatever code you have selected to TTS. If you're in an object script will execute under that object, otherwise will execute in Global.
* Highlight GUID Objects setting. When enabled and your cursor is near a GUID string will make TTS highlight the related object.
* Updated autocomplete suggestions for v10.2 additions
* Fixed some linter warnings relating to comments

## 10.0.1
* Fixed go to line function (was going to wrong line)
* Added more comprehensive setting to let user decide what files are opened in Atom when they are sent from TTS. Can also completely disable communication with TTS.
* Now displays a pop-up in Atom when your TTS mod hits a run-time error, with a button to jump to offending line (if able).
* Added ```Jump To Last Error``` menu option and hotkey ```ctrl-e```.
* Changed some settings so they default to on for options which have proved stable (such as the unicode conversion setting)
* Added default hotkeys for Get Lua Scripts (ctrl-shift-l) and Save And Play (ctrl-shift-s)
* Added documentation to github wiki, and help item to menu in plugin to open it


## 9.9.2
* Fixed errors which caused plugin to lock-up and be unable to fetch or send from/to TTS
* Added some more logging to save routines for future debugging
* Linter now recognizes repeat/until one-liners
* Grammar added for #include preprocessor command

## 9.9.1
Linter:
* Added ability to manually suppress a warning: postfix the line with --
* Added the option to delay the linter when a file is first opened
* Better understands one-liners (now works with closing parenthesis)
* Better understands table definitions (optional comma after last item)
* Fixed the linter spamming file locks when files are opened

## 1.2.4
Lua module snippets

* Added autocomplete suggestions for built-in Lua classes: string, table, bit32, dynamic

Linter support

* Added linter support (i.e. error detection as you type, instead of waiting to see errors after Save And Play)
* To enable it go to atom settings->install and install the 'linter' package by 'steelbrain' and the dependencies it asks for (other atom linter consumers should also work if you prefer one of them, i.e. Nuclide or atom-ide-ui).

Other updates

* Feature to re-open non-TTS files now simply does not close them when you Save And Play
* Save And Play now locks itself so you cannot trigger it more than once-at-a-time.
* Better autocomplete handling of else/elseif/end
* Fixed error on trying to Go To Line > end of file
* Fixed copy+paste error in cursorChange event
* Fixed not finding current function if root function had indent

## 1.2.3
* Fixed freezing when right click object and selecting lua editor

## 1.2.2
* Merged more pull requests

## 1.2.1
* Merged more pull requests with async saving

## 1.1.9
* Merged more pull requests

## 1.1.8
* Merged two pull requests

## 1.1.7
* Added getHandObjects() to Player
* Added onObjectDropped() event
* Added onObjectPickedUp() event

## 1.1.6
* Changed onload() to onLoad(). onload() will still work, just not in autocomplete
* Added Timer static global class
* Added onSave() event
* Added parameter to onLoad() for save state
* Added script_code to Global
* Added script_state to Object and Global
* Deprecated callLuaFunctionInOtherScript() and callLuaFunctionInOtherScriptWithParams()
* Added call() to Object and Global
* Added onAttack() to RPGFigurine
* Added onHit() to RPGFigurine
* Added promoted to Player
* Added team to Player
* Added kick() to Player
* Added mute() to Player
* Added promote() to Player
* Added changeColor() to Player
* Added changeTeam() to Player

## 1.1.5
* Added previous player to onPlayerTurnStart()
* Added next player to onPlayerTurnEnd()
* Added use_grid to Object
* Added use_snap_points to Object
* Added auto_raise to Object
* Added sticky to Object
* Added interactable to Object
* Removed getPlayer()
* Added Player static global class
* Added JSON static global class
* Added TextTool class

## 1.1.4
* Added tonumber() to autocomplete
* Added tostring() to autocomplete
* Added addNotebookTab() to autocomplete
* Added removeNotebookTab() to autocomplete
* Added getNotebookTabs() to autocomplete
* Added editNotebookTab() to autocomplete
* Added clearPixelPaint() to autocomplete
* Added clearVectorPaint() to autocomplete
* Added copy() to autocomplete
* Added paste() to autocomplete
* Added clone() to autocomplete
* Added RPGFigurine class to autocomplete
* Changed autocomplete references to color to player_color as appropriate
* Fixed Uncaught TypeError: this.stopConnection is not a function
* Globally accessible functions have been recolored to teal instead of blue
* Moved TTS contextual menu commands into a submenu

## 1.1.3
* Fixed setState autocomplete to include integer parameter

## 1.1.2
* Bumping to get Atom repo to recognize it

## 1.1.1
* Added getLuaScript()
* Changed scaleAllAxes() to scale() overload
* Cleaned up debug prints
* Fixed Save & Play with a new tab open
* Fixed reading in script/Object nicknames with special characters

## 1.1.0
* Added pushing from Unity. Push new scripts, debug print messages, and error messages.

## 1.0.7
* Reloading was reloading the old version, not the new one. Removed reloading code.

## 1.0.6
* Test autoupdater

## 1.0.5
* Autoupdater reloads plugin after update

## 1.0.4
* Test autoupdater

## 1.0.3
* Added autoupdater

## 1.0.2
* Test

## 1.0.1
* Added script_code to Object autocomplete

## 1.0.0 - First Release
* Every feature added
* Every bug fixed
