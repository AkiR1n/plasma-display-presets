pragma ComponentBehavior: Bound

import QtQuick

import org.kde.plasma.plasma5support as Plasma5Support

import "code/CommandResult.js" as CommandResult

Item {
    id: root
    width: 0
    height: 0
    visible: false

    property bool busy: false
    property string pendingCommand: ""
    property var pendingContext: null

    signal finished(var result, var context)

    function run(command, context) {
        if (root.busy || !command) {
            return false;
        }

        root.busy = true;
        root.pendingCommand = command;
        root.pendingContext = context || {};

        if (dataSource.connectedSources.indexOf(command) >= 0) {
            dataSource.disconnectSource(command);
            dataSource.removeSource(command);
        }

        dataSource.connectSource(command);
        return true;
    }

    function clearPendingSource(sourceName) {
        if (!sourceName) {
            return;
        }

        dataSource.disconnectSource(sourceName);
        dataSource.removeSource(sourceName);
    }

    Plasma5Support.DataSource {
        id: dataSource
        engine: "executable"
        interval: 0

        onNewData: function(sourceName, data) {
            if (sourceName !== root.pendingCommand) {
                return;
            }

            var result = CommandResult.fromData(data);
            result.command = sourceName;

            root.clearPendingSource(sourceName);

            var context = root.pendingContext;
            root.busy = false;
            root.pendingCommand = "";
            root.pendingContext = null;
            root.finished(result, context);
        }
    }
}
