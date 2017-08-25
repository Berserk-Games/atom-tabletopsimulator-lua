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
