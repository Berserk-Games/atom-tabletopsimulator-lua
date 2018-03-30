import urllib2, sys;
from bs4 import BeautifulSoup

urls = [
    "http://berserk-games.com/knowledgebase/api/#addNotebookTab",
    "http://berserk-games.com/knowledgebase/api/#broadcastToAll",
    "http://berserk-games.com/knowledgebase/api/#broadcastToColor",
    "http://berserk-games.com/knowledgebase/api/#clearPixelPaint",
    "http://berserk-games.com/knowledgebase/api/#clearVectorPaint",
    "http://berserk-games.com/knowledgebase/api/#copy",
    "http://berserk-games.com/knowledgebase/api/#destroyObject",
    "http://berserk-games.com/knowledgebase/api/#editNotebookTab",
    "http://berserk-games.com/knowledgebase/api/#flipTable",
    "http://berserk-games.com/knowledgebase/api/#getAllObjects",
    "http://berserk-games.com/knowledgebase/api/#getNotebookTabs",
    "http://berserk-games.com/knowledgebase/api/#getNotes",
    "http://berserk-games.com/knowledgebase/api/#getObjectFromGUID",
    "http://berserk-games.com/knowledgebase/api/#getSeatedPlayers",
    "http://berserk-games.com/knowledgebase/api/#log",
    "http://berserk-games.com/knowledgebase/api/#logStyle",
    "http://berserk-games.com/knowledgebase/api/#onChat",
    "http://berserk-games.com/knowledgebase/api/#onCollisionEnter",
    "http://berserk-games.com/knowledgebase/api/#onCollisionExit",
    "http://berserk-games.com/knowledgebase/api/#onCollisionStay",
    "http://berserk-games.com/knowledgebase/api/#onDestroy",
    "http://berserk-games.com/knowledgebase/api/#onDropped",
    "http://berserk-games.com/knowledgebase/api/#onFixedUpdate",
    "http://berserk-games.com/knowledgebase/api/#onLoad",
    "http://berserk-games.com/knowledgebase/api/#onObjectDestroyed",
    "http://berserk-games.com/knowledgebase/api/#onObjectDropped",
    "http://berserk-games.com/knowledgebase/api/#onObjectEnterScriptingZone",
    "http://berserk-games.com/knowledgebase/api/#onObjectLeaveContainer",
    "http://berserk-games.com/knowledgebase/api/#onObjectLeaveScriptingZone",
    "http://berserk-games.com/knowledgebase/api/#onObjectLoopingEffect",
    "http://berserk-games.com/knowledgebase/api/#onObjectPickedUp",
    "http://berserk-games.com/knowledgebase/api/#onObjectRandomize",
    "http://berserk-games.com/knowledgebase/api/#onObjectSpawn",
    "http://berserk-games.com/knowledgebase/api/#onObjectTriggerEffect",
    "http://berserk-games.com/knowledgebase/api/#onPickedUp",
    "http://berserk-games.com/knowledgebase/api/#onPlayerChangedColor",
    "http://berserk-games.com/knowledgebase/api/#onPlayerConnect",
    "http://berserk-games.com/knowledgebase/api/#onPlayerDisconnect",
    "http://berserk-games.com/knowledgebase/api/#onPlayerTurnEnd",
    "http://berserk-games.com/knowledgebase/api/#onPlayerTurnStart",
    "http://berserk-games.com/knowledgebase/api/#onSave",
    "http://berserk-games.com/knowledgebase/api/#onUpdate",
    "http://berserk-games.com/knowledgebase/api/#print",
    "http://berserk-games.com/knowledgebase/api/#printToAll",
    "http://berserk-games.com/knowledgebase/api/#printToColor",
    "http://berserk-games.com/knowledgebase/api/#removeNotebookTab",
    "http://berserk-games.com/knowledgebase/api/#setNotes",
    "http://berserk-games.com/knowledgebase/api/#spawnObject",
    "http://berserk-games.com/knowledgebase/api/#startLuaCoroutine",
    "http://berserk-games.com/knowledgebase/api/#stringColorToRGB",
    "http://berserk-games.com/knowledgebase/assetbundle/#getLoopingEffectIndex",
    "http://berserk-games.com/knowledgebase/assetbundle/#getLoopingEffects",
    "http://berserk-games.com/knowledgebase/assetbundle/#getTriggerEffects",
    "http://berserk-games.com/knowledgebase/assetbundle/#playLoopingEffect",
    "http://berserk-games.com/knowledgebase/assetbundle/#playTriggerEffect",
    "http://berserk-games.com/knowledgebase/clock/#getValue",
    "http://berserk-games.com/knowledgebase/clock/#pauseStart",
    "http://berserk-games.com/knowledgebase/clock/#paused",
    "http://berserk-games.com/knowledgebase/clock/#setValue",
    "http://berserk-games.com/knowledgebase/clock/#showCurrentTime",
    "http://berserk-games.com/knowledgebase/clock/#startStopwatch",
    "http://berserk-games.com/knowledgebase/counter/#clear",
    "http://berserk-games.com/knowledgebase/counter/#decrement",
    "http://berserk-games.com/knowledgebase/counter/#getValue",
    "http://berserk-games.com/knowledgebase/counter/#increment",
    "http://berserk-games.com/knowledgebase/counter/#setValue",
    "http://berserk-games.com/knowledgebase/external-editor-api/",
    "http://berserk-games.com/knowledgebase/json",
    "http://berserk-games.com/knowledgebase/json/#decode",
    "http://berserk-games.com/knowledgebase/json/#encode",
    "http://berserk-games.com/knowledgebase/json/#encode_pretty",
    "http://berserk-games.com/knowledgebase/object",
    "http://berserk-games.com/knowledgebase/object/#AssetBundle",
    "http://berserk-games.com/knowledgebase/object/#Clock",
    "http://berserk-games.com/knowledgebase/object/#Counter",
    "http://berserk-games.com/knowledgebase/object/#RPGFigurine",
    "http://berserk-games.com/knowledgebase/object/#TextTool",
    "http://berserk-games.com/knowledgebase/object/#addForce",
    "http://berserk-games.com/knowledgebase/object/#addTorque",
    "http://berserk-games.com/knowledgebase/object/#angular_drag",
    "http://berserk-games.com/knowledgebase/object/#auto_raise",
    "http://berserk-games.com/knowledgebase/object/#bounciness",
    "http://berserk-games.com/knowledgebase/object/#call",
    "http://berserk-games.com/knowledgebase/object/#clearButtons",
    "http://berserk-games.com/knowledgebase/object/#clearInputs",
    "http://berserk-games.com/knowledgebase/object/#clone",
    "http://berserk-games.com/knowledgebase/object/#createButton",
    "http://berserk-games.com/knowledgebase/object/#createInput",
    "http://berserk-games.com/knowledgebase/object/#cut",
    "http://berserk-games.com/knowledgebase/object/#deal",
    "http://berserk-games.com/knowledgebase/object/#dealToColorWithOffset",
    "http://berserk-games.com/knowledgebase/object/#destruct",
    "http://berserk-games.com/knowledgebase/object/#drag",
    "http://berserk-games.com/knowledgebase/object/#dynamic_friction",
    "http://berserk-games.com/knowledgebase/object/#editButton",
    "http://berserk-games.com/knowledgebase/object/#editInput",
    "http://berserk-games.com/knowledgebase/object/#flip",
    "http://berserk-games.com/knowledgebase/object/#getAngularVelocity",
    "http://berserk-games.com/knowledgebase/object/#getBounds",
    "http://berserk-games.com/knowledgebase/object/#getBoundsNormalized",
    "http://berserk-games.com/knowledgebase/object/#getButtons",
    "http://berserk-games.com/knowledgebase/object/#getColorTint",
    "http://berserk-games.com/knowledgebase/object/#getCustomObject",
    "http://berserk-games.com/knowledgebase/object/#getDescription",
    "http://berserk-games.com/knowledgebase/object/#getGUID",
    "http://berserk-games.com/knowledgebase/object/#getInputs",
    "http://berserk-games.com/knowledgebase/object/#getLock",
    "http://berserk-games.com/knowledgebase/object/#getLuaScript",
    "http://berserk-games.com/knowledgebase/object/#getName",
    "http://berserk-games.com/knowledgebase/object/#getObjects",
    "http://berserk-games.com/knowledgebase/object/#getPosition",
    "http://berserk-games.com/knowledgebase/object/#getQuantity",
    "http://berserk-games.com/knowledgebase/object/#getRotation",
    "http://berserk-games.com/knowledgebase/object/#getRotationValues",
    "http://berserk-games.com/knowledgebase/object/#getScale",
    "http://berserk-games.com/knowledgebase/object/#getStateId",
    "http://berserk-games.com/knowledgebase/object/#getStates",
    "http://berserk-games.com/knowledgebase/object/#getStatesCount",
    "http://berserk-games.com/knowledgebase/object/#getTable",
    "http://berserk-games.com/knowledgebase/object/#getTransformForward",
    "http://berserk-games.com/knowledgebase/object/#getTransformRight",
    "http://berserk-games.com/knowledgebase/object/#getTransformUp",
    "http://berserk-games.com/knowledgebase/object/#getValue",
    "http://berserk-games.com/knowledgebase/object/#getVar",
    "http://berserk-games.com/knowledgebase/object/#getVelocity",
    "http://berserk-games.com/knowledgebase/object/#grid_projection",
    "http://berserk-games.com/knowledgebase/object/#guid",
    "http://berserk-games.com/knowledgebase/object/#held_by_color",
    "http://berserk-games.com/knowledgebase/object/#highlightOff",
    "http://berserk-games.com/knowledgebase/object/#highlightOn",
    "http://berserk-games.com/knowledgebase/object/#interactable",
    "http://berserk-games.com/knowledgebase/object/#isSmoothMoving",
    "http://berserk-games.com/knowledgebase/object/#mass",
    "http://berserk-games.com/knowledgebase/object/#name",
    "http://berserk-games.com/knowledgebase/object/#positionToLocal",
    "http://berserk-games.com/knowledgebase/object/#positionToWorld",
    "http://berserk-games.com/knowledgebase/object/#putObject",
    "http://berserk-games.com/knowledgebase/object/#randomize",
    "http://berserk-games.com/knowledgebase/object/#reload",
    "http://berserk-games.com/knowledgebase/object/#removeButton",
    "http://berserk-games.com/knowledgebase/object/#removeInput",
    "http://berserk-games.com/knowledgebase/object/#rest",
    "http://berserk-games.com/knowledgebase/object/#resting",
    "http://berserk-games.com/knowledgebase/object/#roll",
    "http://berserk-games.com/knowledgebase/object/#rotate",
    "http://berserk-games.com/knowledgebase/object/#scale",
    "http://berserk-games.com/knowledgebase/object/#scaleAllAxes",
    "http://berserk-games.com/knowledgebase/object/#script_code",
    "http://berserk-games.com/knowledgebase/object/#script_state",
    "http://berserk-games.com/knowledgebase/object/#setAngularVelocity",
    "http://berserk-games.com/knowledgebase/object/#setColorTint",
    "http://berserk-games.com/knowledgebase/object/#setCustomObject",
    "http://berserk-games.com/knowledgebase/object/#setDescription",
    "http://berserk-games.com/knowledgebase/object/#setLock",
    "http://berserk-games.com/knowledgebase/object/#setLuaScript",
    "http://berserk-games.com/knowledgebase/object/#setName",
    "http://berserk-games.com/knowledgebase/object/#setPosition",
    "http://berserk-games.com/knowledgebase/object/#setPositionSmooth",
    "http://berserk-games.com/knowledgebase/object/#setRotation",
    "http://berserk-games.com/knowledgebase/object/#setRotationSmooth",
    "http://berserk-games.com/knowledgebase/object/#setRotationValues",
    "http://berserk-games.com/knowledgebase/object/#setScale",
    "http://berserk-games.com/knowledgebase/object/#setState",
    "http://berserk-games.com/knowledgebase/object/#setTable",
    "http://berserk-games.com/knowledgebase/object/#setValue",
    "http://berserk-games.com/knowledgebase/object/#setVar",
    "http://berserk-games.com/knowledgebase/object/#setVelocity",
    "http://berserk-games.com/knowledgebase/object/#shuffle",
    "http://berserk-games.com/knowledgebase/object/#shuffleStates",
    "http://berserk-games.com/knowledgebase/object/#static_friction",
    "http://berserk-games.com/knowledgebase/object/#sticky",
    "http://berserk-games.com/knowledgebase/object/#tag",
    "http://berserk-games.com/knowledgebase/object/#takeObject",
    "http://berserk-games.com/knowledgebase/object/#tooltip",
    "http://berserk-games.com/knowledgebase/object/#translate",
    "http://berserk-games.com/knowledgebase/object/#use_gravity",
    "http://berserk-games.com/knowledgebase/object/#use_grid",
    "http://berserk-games.com/knowledgebase/object/#use_hands",
    "http://berserk-games.com/knowledgebase/object/#use_snap_points",
    "http://berserk-games.com/knowledgebase/player",
    "http://berserk-games.com/knowledgebase/player/",
    "http://berserk-games.com/knowledgebase/player/#admin",
    "http://berserk-games.com/knowledgebase/player/#attachCameraToObject",
    "http://berserk-games.com/knowledgebase/player/#blindfolded",
    "http://berserk-games.com/knowledgebase/player/#broadcast",
    "http://berserk-games.com/knowledgebase/player/#changeColor",
    "http://berserk-games.com/knowledgebase/player/#color",
    "http://berserk-games.com/knowledgebase/player/#getHandCount",
    "http://berserk-games.com/knowledgebase/player/#getHandObjects",
    "http://berserk-games.com/knowledgebase/player/#getHandTransform",
    "http://berserk-games.com/knowledgebase/player/#getHoldingObjects",
    "http://berserk-games.com/knowledgebase/player/#getHoverObject",
    "http://berserk-games.com/knowledgebase/player/#getPlayerHand",
    "http://berserk-games.com/knowledgebase/player/#getPlayers",
    "http://berserk-games.com/knowledgebase/player/#getPointerPosition",
    "http://berserk-games.com/knowledgebase/player/#getPointerRotation",
    "http://berserk-games.com/knowledgebase/player/#getSpectators",
    "http://berserk-games.com/knowledgebase/player/#host",
    "http://berserk-games.com/knowledgebase/player/#kick",
    "http://berserk-games.com/knowledgebase/player/#lift_height",
    "http://berserk-games.com/knowledgebase/player/#lookAt",
    "http://berserk-games.com/knowledgebase/player/#mute",
    "http://berserk-games.com/knowledgebase/player/#print",
    "http://berserk-games.com/knowledgebase/player/#promote",
    "http://berserk-games.com/knowledgebase/player/#promoted",
    "http://berserk-games.com/knowledgebase/player/#seated",
    "http://berserk-games.com/knowledgebase/player/#setHandTransform",
    "http://berserk-games.com/knowledgebase/player/#steam_id",
    "http://berserk-games.com/knowledgebase/player/#steam_name",
    "http://berserk-games.com/knowledgebase/player/#team",
    "http://berserk-games.com/knowledgebase/rpgfigurine/#attack",
    "http://berserk-games.com/knowledgebase/rpgfigurine/#changeMode",
    "http://berserk-games.com/knowledgebase/rpgfigurine/#die",
    "http://berserk-games.com/knowledgebase/rpgfigurine/#onAttack",
    "http://berserk-games.com/knowledgebase/rpgfigurine/#onHit",
    "http://berserk-games.com/knowledgebase/scripting-lighting/",
    "http://berserk-games.com/knowledgebase/scripting-lighting/#ambient_intensity",
    "http://berserk-games.com/knowledgebase/scripting-lighting/#ambient_type",
    "http://berserk-games.com/knowledgebase/scripting-lighting/#apply",
    "http://berserk-games.com/knowledgebase/scripting-lighting/#getAmbientEquatorColor",
    "http://berserk-games.com/knowledgebase/scripting-lighting/#getAmbientGroundColor",
    "http://berserk-games.com/knowledgebase/scripting-lighting/#getAmbientSkyColor",
    "http://berserk-games.com/knowledgebase/scripting-lighting/#getLightColor",
    "http://berserk-games.com/knowledgebase/scripting-lighting/#light_intensity",
    "http://berserk-games.com/knowledgebase/scripting-lighting/#reflection_intensity",
    "http://berserk-games.com/knowledgebase/scripting-physics/",
    "http://berserk-games.com/knowledgebase/scripting-physics/#cast",
    "http://berserk-games.com/knowledgebase/scripting-physics/#getGravity",
    "http://berserk-games.com/knowledgebase/scripting-physics/#setAmbientEquatorColor",
    "http://berserk-games.com/knowledgebase/scripting-physics/#setAmbientGroundColor",
    "http://berserk-games.com/knowledgebase/scripting-physics/#setAmbientSkyColor",
    "http://berserk-games.com/knowledgebase/scripting-physics/#setGravity",
    "http://berserk-games.com/knowledgebase/scripting-physics/#setLightColor",
    "http://berserk-games.com/knowledgebase/texttool/#getFontColor",
    "http://berserk-games.com/knowledgebase/texttool/#getFontSize",
    "http://berserk-games.com/knowledgebase/texttool/#getValue",
    "http://berserk-games.com/knowledgebase/texttool/#setFontColor",
    "http://berserk-games.com/knowledgebase/texttool/#setFontSize",
    "http://berserk-games.com/knowledgebase/texttool/#setValue",
    "http://berserk-games.com/knowledgebase/timer/",
    "http://berserk-games.com/knowledgebase/timer/#create",
    "http://berserk-games.com/knowledgebase/timer/#destroy",
    "http://berserk-games.com/knowledgebase/webrequest/",
    "http://berserk-games.com/knowledgebase/webrequest/#get",
    "http://berserk-games.com/knowledgebase/webrequest/#post",
    "http://berserk-games.com/knowledgebase/webrequest/#pull",
]


def new_url(url):
    s = url.toLowerCase();
    s = s.replace("http://berserk-games.com/knowledgebase/", "https://api.tabletopsimulator.com/");
    s = s.replace("/scripting-", "/");
    s = s.replace("/api/#on", "/event/#on");
    s = s.replace("/api/", "/base/");
    s = s.replace("/external-editor-api", "/externaleditorapi");
    return s;


replacements = {}
for url in urls:
    replacememts[url] = new_url(url)


if len(sys.argv) > 1:
    if not os.path.exists(sys.argv[1]):
        print "No such file"
        sys.exit(1)

    # do replacement

else:
    sites = {}
    missing = []
    errors = 0

    for key in sorted(todo):
        url = todo[key]
        id_index = url.find("#")
        site = url[:id_index]
        id = url[id_index:]

        if site in missing:
            print '\r' + url + "                    "
            errors += 1
            continue

        if url not in sites:
            page = urllib2.urlopen(url)
            if not page:
                print '\r' + url + "                    "
                missing[site] = True
                errors += 1
                continue
            soup = BeautifulSoup(page, 'html.parser')
            sites[url] = soup
        else:
            soup = sites[url]

        if id_index >= 0 and not soup.select(id):
            print '\r' + url + "                    "
            errors += 1
        else:
            print '\r' + url + "                    ",

    print
    print errors, "errors"
