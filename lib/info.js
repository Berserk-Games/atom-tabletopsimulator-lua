/// <reference path="../typings/hover.d.ts" />
var child_process = require('child_process');
var remote = require('electron').remote;
var Q = require('q');
function provider(p) {
    function okInfo(text) {
        var ty = p.result(text);
        if (ty) {
            return { valid: true, info: ty };
        }
        return { valid: false, info: text.join('\n') };
    }
    function errInfo(text) {
        remote.dialog.showMessageBox(remote.getCurrentWindow(), {
            type: 'info',
            normalizeAccessKeys: true,
            message: "Hover Info Error" + text,
            detailedMessage: text,
            buttons: ['Close']
        }).then(function(event) {
            if (event.response === 0) {
                window.alert('ok')
            }
        });
        return { valid: false, info: text };
    }
    function execPromise(cmd) {
        var cmd_ = cmd.cmd + ' ' + cmd.args.join(' ');
        var r = Q.nfcall(child_process.exec, cmd_);
        return r;
    }
    function dummyInfo2(pos) {
        var cmd = p.command(pos);
        return execPromise(cmd)
            .then(okInfo)
            .catch(errInfo);
    }
    return dummyInfo2;
}
exports.provider = provider;
