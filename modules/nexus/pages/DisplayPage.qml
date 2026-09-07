pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.nexus.common

PageBase {
    id: root

    property int selectedMonitorIndex: 0

    function selectFocusedMonitor(): void {
        const focused = Displays.monitors.findIndex(monitor => monitor.focused);
        selectedMonitorIndex = focused >= 0 ? focused : Displays.monitors.length > 0 ? 0 : -1;
    }

    title: qsTr("Display")

    Component.onCompleted: selectFocusedMonitor()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Connections {
            function onMonitorsChanged(): void {
                if (Displays.monitors.length === 0)
                    root.selectedMonitorIndex = -1;
                else if (root.selectedMonitorIndex < 0 || root.selectedMonitorIndex >= Displays.monitors.length)
                    root.selectFocusedMonitor();
            }

            target: Displays
        }

        SectionHeader {
            first: true
            text: qsTr("Configuration")
        }

        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: statusRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: statusRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Displays.loading ? qsTr("Detecting displays…") : qsTr("%1 active display(s)").arg(Displays.monitors.length)
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Changes are saved to the managed Hyprland monitor override")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        elide: Text.ElideRight
                    }
                }

                IconButton {
                    icon: "refresh"
                    type: IconButton.Tonal
                    isRound: true
                    disabled: Displays.loading
                    onClicked: Displays.refresh()
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: Displays.awaitingConfirmation
            first: true
            last: true
            implicitHeight: confirmationRow.implicitHeight + Tokens.padding.medium * 2

            RowLayout {
                id: confirmationRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "display_settings"
                    color: Colours.palette.m3primary
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Keep display settings?")
                        font: Tokens.font.body.small
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Reverting in %1 seconds").arg(Displays.confirmSeconds)
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                    }
                }

                TextButton {
                    text: qsTr("Revert")
                    type: TextButton.Tonal
                    onClicked: Displays.revertChanges()
                }

                TextButton {
                    text: qsTr("Keep")
                    onClicked: Displays.keepChanges()
                }
            }
        }

        ConnectedRect {
            Layout.fillWidth: true
            visible: Displays.error !== ""
            first: true
            last: true
            implicitHeight: displayError.implicitHeight + Tokens.padding.large * 2

            StyledText {
                id: displayError

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Tokens.padding.large
                text: Displays.error
                color: Colours.palette.m3error
                font: Tokens.font.body.small
                wrapMode: Text.Wrap
            }
        }

        SectionHeader {
            text: qsTr("Arrangement")
        }

        ArrangementSection {
            visible: Displays.monitors.length > 0
        }

        Repeater {
            model: Displays.monitors.length

            MonitorSection {
                required property int index

                monitorIndex: index
                monitor: Displays.monitors[index]
            }
        }
    }

    component ArrangementSection: ConnectedRect {
        id: arrangement

        readonly property real pad: Tokens.padding.large
        readonly property var bounds: calculateBounds(Displays.monitors)
        readonly property real logicalSpanWidth: Math.max(1, bounds.maxX - bounds.minX)
        readonly property real logicalSpanHeight: Math.max(1, bounds.maxY - bounds.minY)
        readonly property real layoutScale: Math.max(0.04, Math.min((canvas.width - pad * 2) / logicalSpanWidth, (canvas.height - pad * 2) / logicalSpanHeight))
        readonly property var selectedMonitor: root.selectedMonitorIndex >= 0 && root.selectedMonitorIndex < Displays.monitors.length ? Displays.monitors[root.selectedMonitorIndex] : null

        function visualWidth(monitor: var): real {
            const rotated = [1, 3, 5, 7].includes(monitor.transform);
            return (rotated ? monitor.height : monitor.width) / Math.max(0.1, monitor.scale);
        }

        function visualHeight(monitor: var): real {
            const rotated = [1, 3, 5, 7].includes(monitor.transform);
            return (rotated ? monitor.width : monitor.height) / Math.max(0.1, monitor.scale);
        }

        function calculateBounds(monitors: var): var {
            if (!monitors || monitors.length === 0)
                return {
                    minX: 0,
                    minY: 0,
                    maxX: 1,
                    maxY: 1
                };

            let minX = Infinity;
            let minY = Infinity;
            let maxX = -Infinity;
            let maxY = -Infinity;

            for (const monitor of monitors) {
                const width = visualWidth(monitor);
                const height = visualHeight(monitor);
                minX = Math.min(minX, monitor.x);
                minY = Math.min(minY, monitor.y);
                maxX = Math.max(maxX, monitor.x + width);
                maxY = Math.max(maxY, monitor.y + height);
            }

            return {
                minX,
                minY,
                maxX,
                maxY
            };
        }

        function screenX(monitor: var): real {
            return pad + (monitor.x - bounds.minX) * layoutScale;
        }

        function screenY(monitor: var): real {
            return pad + (monitor.y - bounds.minY) * layoutScale;
        }

        function commitTile(index: int, tileX: real, tileY: real): void {
            const x = Math.round(((tileX - pad) / layoutScale + bounds.minX) / 10) * 10;
            const y = Math.round(((tileY - pad) / layoutScale + bounds.minY) / 10) * 10;
            Displays.moveMonitor(index, x, y);
        }

        Layout.fillWidth: true
        first: true
        last: true
        implicitHeight: arrangementLayout.implicitHeight + Tokens.padding.large * 2

        ColumnLayout {
            id: arrangementLayout

            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.medium

                StyledText {
                    Layout.fillWidth: true
                    text: arrangement.selectedMonitor ? qsTr("Selected: %1").arg(arrangement.selectedMonitor.name) : qsTr("Selected: none")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }

                TextButton {
                    text: Displays.isMainMonitor(root.selectedMonitorIndex) ? qsTr("Main display") : qsTr("Set as main")
                    type: TextButton.Tonal
                    disabled: Displays.isMainMonitor(root.selectedMonitorIndex)
                    onClicked: Displays.setMainMonitor(root.selectedMonitorIndex)
                }
            }

            StyledRect {
                id: canvas

                Layout.fillWidth: true
                Layout.preferredHeight: 250
                radius: Tokens.rounding.medium
                color: Colours.tPalette.m3surfaceContainerHigh
                clip: true

                Repeater {
                    model: Displays.monitors.length

                    MonitorTile {
                        required property int index

                        arrangement: arrangement
                        canvas: canvas
                        monitorIndex: index
                        monitor: Displays.monitors[index]
                    }
                }
            }
        }
    }

    component MonitorTile: StyledRect {
        id: tile

        required property var arrangement
        required property Item canvas
        required property int monitorIndex
        required property var monitor

        readonly property bool selected: root.selectedMonitorIndex === monitorIndex
        readonly property bool main: Displays.isMainMonitor(monitorIndex)

        width: Math.max(90, arrangement.visualWidth(monitor) * arrangement.layoutScale)
        height: Math.max(62, arrangement.visualHeight(monitor) * arrangement.layoutScale)
        radius: Tokens.rounding.small
        color: main ? Colours.palette.m3primary : selected ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHigh
        border.width: selected ? 3 : 1
        border.color: selected ? Colours.palette.m3primary : Colours.palette.m3outlineVariant
        z: selected ? 2 : 1

        Binding {
            target: tile
            property: "x"
            value: tile.arrangement.screenX(tile.monitor)
            when: !dragArea.drag.active
        }

        Binding {
            target: tile
            property: "y"
            value: tile.arrangement.screenY(tile.monitor)
            when: !dragArea.drag.active
        }

        StateLayer {
            id: dragArea

            anchors.fill: parent
            color: tile.main ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            cursorShape: Qt.OpenHandCursor
            drag.target: tile
            drag.minimumX: tile.arrangement.pad
            drag.minimumY: tile.arrangement.pad
            drag.maximumX: Math.max(tile.arrangement.pad, tile.canvas.width - tile.width - tile.arrangement.pad)
            drag.maximumY: Math.max(tile.arrangement.pad, tile.canvas.height - tile.height - tile.arrangement.pad)
            onPressed: {
                cursorShape = Qt.ClosedHandCursor;
                root.selectedMonitorIndex = tile.monitorIndex;
            }
            onReleased: {
                cursorShape = Qt.OpenHandCursor;
                tile.arrangement.commitTile(tile.monitorIndex, tile.x, tile.y);
            }
            onClicked: root.selectedMonitorIndex = tile.monitorIndex
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: (tile.monitorIndex + 1).toString()
                color: tile.main ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                font: Tokens.font.title.medium
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: tile.monitor.name
                color: tile.main ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                font: Tokens.font.label.small
            }
        }
    }

    component MonitorSection: ColumnLayout {
        id: section

        required property int monitorIndex
        required property var monitor

        readonly property list<MenuItem> orientationItems: [
            MenuItem {
                text: qsTr("Normal")
                icon: "crop_16_9"
            },
            MenuItem {
                text: qsTr("90°")
                icon: "screen_rotation"
            },
            MenuItem {
                text: qsTr("180°")
                icon: "screen_rotation_alt"
            },
            MenuItem {
                text: qsTr("270°")
                icon: "screen_rotation"
            }
        ]
        readonly property list<int> orientationValues: [0, 1, 2, 3]
        readonly property list<MenuItem> colourItems: [
            MenuItem {
                text: qsTr("SDR")
                icon: "tonality"
            },
            MenuItem {
                text: qsTr("HDR")
                icon: "hdr_on"
            },
            MenuItem {
                text: qsTr("HDR EDID")
                icon: "hdr_auto"
            }
        ]
        readonly property list<string> colourValues: ["srgb", "hdr", "hdredid"]

        Layout.fillWidth: true
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            text: section.monitor.description || section.monitor.name
        }

        RowButton {
            first: true
            icon: "speed"
            text: section.monitor.mode
            subtext: qsTr("%1 at %2×%3, scale %4×").arg(section.monitor.name).arg(section.monitor.x).arg(section.monitor.y).arg(section.monitor.scale)
            trailingIcon: "refresh"
            onClicked: Displays.setHighestRefresh(section.monitorIndex)
        }

        TextFieldRow {
            label: qsTr("Mode")
            subtext: section.monitor.modes.length > 0 ? qsTr("Available: %1").arg(section.monitor.modes.slice(0, 3).join(", ")) : qsTr("No modes reported")
            value: section.monitor.mode
            errorText: qsTr("Use a reported mode or WIDTHxHEIGHT@HZ")
            validate: value => Displays.isValidMode(section.monitor, value)
            onEditingFinished: value => {
                const mode = value.trim();
                if (Displays.isValidMode(section.monitor, mode) && mode !== section.monitor.mode)
                    Displays.updateMonitor(section.monitorIndex, {
                        mode
                    }, true);
            }
        }

        StepperRow {
            label: qsTr("GUI scale")
            subtext: qsTr("Percent; 150 equals 1.5×")
            value: Math.round(section.monitor.scale * 100)
            from: 75
            to: 250
            stepSize: 5
            onMoved: value => Displays.updateMonitor(section.monitorIndex, {
                    scale: value / 100
                }, true)
        }

        SelectRow {
            label: qsTr("Orientation")
            subtext: qsTr("Rotate this output")
            menuItems: section.orientationItems
            active: menuItems[section.orientationValues.indexOf(section.monitor.transform)] ?? menuItems[0]
            onSelected: item => Displays.updateMonitor(section.monitorIndex, {
                    transform: section.orientationValues[menuItems.indexOf(item)]
                }, true)
        }

        SelectRow {
            label: qsTr("Colour mode")
            subtext: qsTr("SDR or HDR output mode")
            menuItems: section.colourItems
            active: menuItems[section.colourValues.indexOf(section.monitor.cm)] ?? menuItems[0]
            onSelected: item => {
                const value = section.colourValues[menuItems.indexOf(item)];
                Displays.updateMonitor(section.monitorIndex, {
                    hdr: value !== "srgb",
                    cm: value
                }, true);
            }
        }

        StepperRow {
            enabled: section.monitor.hdr
            opacity: enabled ? 1 : 0.45
            label: qsTr("SDR brightness")
            subtext: qsTr("Brightness of SDR content in HDR mode (%)")
            value: Math.round(section.monitor.sdrBrightness * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: value => Displays.updateMonitor(section.monitorIndex, {
                    sdrBrightness: value / 100
                }, true)
        }

        StepperRow {
            last: true
            enabled: section.monitor.hdr
            opacity: enabled ? 1 : 0.45
            label: qsTr("SDR saturation")
            subtext: qsTr("Saturation of SDR content in HDR mode (%)")
            value: Math.round(section.monitor.sdrSaturation * 100)
            from: 50
            to: 150
            stepSize: 5
            onMoved: value => Displays.updateMonitor(section.monitorIndex, {
                    sdrSaturation: value / 100
                }, true)
        }
    }
}
