pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.utils

Singleton {
    id: root

    readonly property string generatedConfigPath: `${Paths.config}/hypr-monitor-generated.lua`

    property list<var> monitors: []
    property list<string> lastAppliedRules: []
    property list<string> previousRules: []
    property bool loading: false
    property string error: ""
    property bool awaitingConfirmation: false
    property int confirmSeconds: 0

    function refresh(): void {
        loading = true;
        error = "";
        refreshProc.running = true;
    }

    function normalizeMode(mode: string): string {
        return mode.replace(/Hz$/, "");
    }

    function formatNumber(value: real, decimals: int): string {
        const rounded = Number(value.toFixed(decimals));
        return rounded.toString();
    }

    function currentMode(monitor: var): string {
        const prefix = `${monitor.width}x${monitor.height}@`;
        const refresh = monitor.refreshRate ?? 0;
        const match = (monitor.availableModes ?? []).find(mode => {
            if (!mode.startsWith(prefix))
                return false;

            const parsed = parseFloat(mode.slice(prefix.length));
            return Math.abs(parsed - refresh) < 0.2;
        });

        if (match)
            return normalizeMode(match);

        return `${monitor.width}x${monitor.height}@${formatNumber(refresh, 2)}`;
    }

    function normalizeMonitor(monitor: var): var {
        const preset = monitor.colorManagementPreset || "srgb";
        const hdr = preset === "hdr" || preset === "hdredid";

        return {
            name: monitor.name,
            description: monitor.description || monitor.name,
            make: monitor.make || "",
            model: monitor.model || "",
            width: monitor.width ?? 0,
            height: monitor.height ?? 0,
            mode: currentMode(monitor),
            modes: (monitor.availableModes ?? []).map(mode => normalizeMode(mode)),
            x: monitor.x ?? 0,
            y: monitor.y ?? 0,
            scale: monitor.scale ?? 1,
            transform: monitor.transform ?? 0,
            hdr: hdr,
            cm: hdr ? preset : "srgb",
            sdrBrightness: monitor.sdrBrightness ?? 1,
            sdrSaturation: monitor.sdrSaturation ?? 1,
            focused: monitor.focused ?? false,
            disabled: monitor.disabled ?? false
        };
    }

    function normalizeFromJson(json: var): list<var> {
        return json.filter(monitor => !monitor.disabled).map(monitor => normalizeMonitor(monitor));
    }

    function mergeRefreshedMonitors(refreshed: list<var>): list<var> {
        const refreshedNames = refreshed.map(monitor => monitor.name);
        const disconnected = monitors.filter(monitor => !refreshedNames.includes(monitor.name)).map(monitor => {
            const retained = Object.assign({}, monitor);
            retained.focused = false;
            return retained;
        });
        return [...refreshed, ...disconnected];
    }

    function logicalWidth(monitor: var): real {
        const rotated = monitor.transform === 1 || monitor.transform === 3 || monitor.transform === 5 || monitor.transform === 7;
        return (rotated ? monitor.height : monitor.width) / Math.max(0.1, monitor.scale);
    }

    function logicalHeight(monitor: var): real {
        const rotated = monitor.transform === 1 || monitor.transform === 3 || monitor.transform === 5 || monitor.transform === 7;
        return (rotated ? monitor.width : monitor.height) / Math.max(0.1, monitor.scale);
    }

    function buildRule(monitor: var): string {
        const bitdepth = monitor.hdr ? 10 : 8;
        const cm = monitor.hdr ? (monitor.cm || "hdr") : "srgb";
        const scale = formatNumber(monitor.scale, 2);
        const brightness = formatNumber(monitor.sdrBrightness, 2);
        const saturation = formatNumber(monitor.sdrSaturation, 2);

        return `${monitor.name}, ${monitor.mode}, ${monitor.x}x${monitor.y}, ${scale}, transform, ${monitor.transform}, bitdepth, ${bitdepth}, cm, ${cm}, sdrbrightness, ${brightness}, sdrsaturation, ${saturation}`;
    }

    function rulesFor(list: list<var>): list<string> {
        return list.map(monitor => buildRule(monitor));
    }

    function isValidMode(monitor: var, mode: string): bool {
        const trimmed = mode.trim();
        if (["preferred", "highres", "highrr", "maxwidth"].includes(trimmed))
            return true;

        if ((monitor.modes ?? []).includes(trimmed))
            return true;

        return /^\d+x\d+(@\d+(\.\d+)?)?$/.test(trimmed);
    }

    function quoteLua(value: string): string {
        return `"${value.replace(/\\/g, "\\\\").replace(/"/g, "\\\"").replace(/\n/g, "\\n")}"`;
    }

    function configText(list: list<var>): string {
        const lines = ["-- Generated atomically by Caelestia Display settings after explicit confirmation.", "-- Baseline disconnected outputs remain in hypr-user.lua until observed by this service.", ""];

        for (const monitor of list) {
            lines.push("hl.monitor({");
            lines.push(`    output = ${quoteLua(monitor.name)},`);
            lines.push(`    mode = ${quoteLua(monitor.mode)},`);
            lines.push(`    position = ${quoteLua(`${monitor.x}x${monitor.y}`)},`);
            lines.push(`    scale = ${formatNumber(monitor.scale, 2)},`);
            lines.push(`    transform = ${monitor.transform},`);
            lines.push(`    bitdepth = ${monitor.hdr ? 10 : 8},`);
            lines.push(`    cm = ${quoteLua(monitor.hdr ? (monitor.cm || "hdr") : "srgb")},`);
            lines.push(`    sdrbrightness = ${formatNumber(monitor.sdrBrightness, 2)},`);
            lines.push(`    sdrsaturation = ${formatNumber(monitor.sdrSaturation, 2)},`);
            lines.push("})");
            lines.push("");
        }

        return lines.join("\n");
    }

    function persistMonitors(list: list<var>): void {
        generatedConfig.setText(configText(list));
    }

    function applyRules(rules: list<string>): void {
        Hypr.extras.batchMessage(rules.map(rule => `keyword monitor ${rule}`));
    }

    function applyMonitors(nextMonitors: list<var>, confirm: bool): void {
        const rules = rulesFor(nextMonitors);

        if (rules.length === 0)
            return;

        if (confirm && !awaitingConfirmation) {
            previousRules = lastAppliedRules.length > 0 ? [...lastAppliedRules] : rulesFor(monitors);
            awaitingConfirmation = true;
        }

        if (confirm) {
            confirmSeconds = 15;
            confirmTimer.restart();
        }

        monitors = nextMonitors;
        lastAppliedRules = rules;
        applyRules(rules);
        refreshDelay.restart();
    }

    function updateMonitor(index: int, changes: var, confirm: bool): void {
        if (index < 0 || index >= monitors.length)
            return;

        if (changes.mode !== undefined && !isValidMode(monitors[index], changes.mode)) {
            error = qsTr("Invalid monitor mode: %1").arg(changes.mode);
            return;
        }

        const nextMonitors = monitors.map((monitor, monitorIndex) => {
            if (monitorIndex !== index)
                return monitor;

            const next = Object.assign({}, monitor);
            for (const [key, value] of Object.entries(changes))
                next[key] = value;

            return next;
        });

        applyMonitors(nextMonitors, confirm);
    }

    function rangesOverlap(aStart: real, aEnd: real, bStart: real, bEnd: real): bool {
        return Math.max(aStart, bStart) < Math.min(aEnd, bEnd);
    }

    function snapMonitorEdges(list: list<var>, index: int): list<var> {
        if (index < 0 || index >= list.length)
            return list;

        const threshold = 80;
        const snapped = list.map(monitor => Object.assign({}, monitor));
        const monitor = snapped[index];
        const width = logicalWidth(monitor);
        const height = logicalHeight(monitor);

        for (let i = 0; i < snapped.length; i++) {
            if (i === index)
                continue;

            const other = snapped[i];
            const otherWidth = logicalWidth(other);
            const otherHeight = logicalHeight(other);

            if (rangesOverlap(monitor.y, monitor.y + height, other.y, other.y + otherHeight)) {
                const leftToRight = Math.abs(monitor.x - (other.x + otherWidth));
                const rightToLeft = Math.abs((monitor.x + width) - other.x);

                if (leftToRight <= threshold)
                    monitor.x = Math.round(other.x + otherWidth);
                else if (rightToLeft <= threshold)
                    monitor.x = Math.round(other.x - width);
            }

            if (rangesOverlap(monitor.x, monitor.x + width, other.x, other.x + otherWidth)) {
                const topToBottom = Math.abs(monitor.y - (other.y + otherHeight));
                const bottomToTop = Math.abs((monitor.y + height) - other.y);

                if (topToBottom <= threshold)
                    monitor.y = Math.round(other.y + otherHeight);
                else if (bottomToTop <= threshold)
                    monitor.y = Math.round(other.y - height);
            }

            if (Math.abs(monitor.y - other.y) <= threshold)
                monitor.y = other.y;
        }

        return snapped;
    }

    function normalizeAdjacentEdges(list: list<var>, lockedIndex: int): list<var> {
        let snapped = list.map(monitor => Object.assign({}, monitor));
        for (let pass = 0; pass < 3; pass++) {
            for (let i = 0; i < snapped.length; i++) {
                if (i === lockedIndex)
                    continue;
                snapped = snapMonitorEdges(snapped, i);
            }
        }
        return snapped;
    }

    function moveMonitor(index: int, x: int, y: int): void {
        if (index < 0 || index >= monitors.length)
            return;

        const nextMonitors = monitors.map((monitor, monitorIndex) => {
            const next = Object.assign({}, monitor);
            if (monitorIndex === index) {
                next.x = x;
                next.y = y;
            }
            return next;
        });

        applyMonitors(snapMonitorEdges(nextMonitors, index), true);
    }

    function mainMonitorIndex(): int {
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].x === 0 && monitors[i].y === 0)
                return i;
        }

        return -1;
    }

    function isMainMonitor(index: int): bool {
        return index === mainMonitorIndex();
    }

    function setMainMonitor(index: int): void {
        if (index < 0 || index >= monitors.length)
            return;

        const selected = monitors[index];
        const nextMonitors = monitors.map(monitor => {
            const next = Object.assign({}, monitor);
            next.x = monitor.x - selected.x;
            next.y = monitor.y - selected.y;
            return next;
        });

        applyMonitors(normalizeAdjacentEdges(nextMonitors, index), true);
    }

    function setHighestRefresh(index: int): void {
        if (index < 0 || index >= monitors.length)
            return;

        const monitor = monitors[index];
        const modes = monitor.modes ?? [];
        if (modes.length === 0)
            return;

        let bestMode = monitor.mode;
        let bestRefresh = -1;

        for (const mode of modes) {
            const parsed = parseFloat(mode.split("@")[1] || "0");
            if (parsed > bestRefresh) {
                bestRefresh = parsed;
                bestMode = mode;
            }
        }

        updateMonitor(index, {
            mode: bestMode
        }, true);
    }

    function keepChanges(): void {
        persistMonitors(monitors);
        awaitingConfirmation = false;
        confirmTimer.stop();
        previousRules = [];
    }

    function revertChanges(): void {
        if (previousRules.length === 0) {
            awaitingConfirmation = false;
            confirmTimer.stop();
            return;
        }

        const rules = [...previousRules];
        awaitingConfirmation = false;
        confirmTimer.stop();
        applyRules(rules);
        lastAppliedRules = rules;
        previousRules = [];
        refreshDelay.restart();
    }

    Component.onCompleted: refresh()

    Timer {
        id: refreshDelay

        interval: 700
        onTriggered: root.refresh()
    }

    Timer {
        id: confirmTimer

        interval: 1000
        repeat: true
        onTriggered: {
            root.confirmSeconds -= 1;
            if (root.confirmSeconds <= 0)
                root.revertChanges();
        }
    }

    FileView {
        id: generatedConfig

        path: root.generatedConfigPath
        atomicWrites: true
        printErrors: false
        onSaveFailed: root.error = qsTr("Could not save the generated monitor override atomically.")
    }

    Process {
        id: refreshProc

        command: ["hyprctl", "-j", "monitors", "all"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text);
                    root.monitors = root.mergeRefreshedMonitors(root.normalizeFromJson(parsed));
                    root.lastAppliedRules = root.rulesFor(root.monitors);
                } catch (e) {
                    root.error = qsTr("Could not read monitor state.");
                }
                root.loading = false;
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.error = text.trim();
            }
        }
        onRunningChanged: {
            if (!running)
                root.loading = false;
        }
    }

    IpcHandler {
        function refresh(): void {
            root.refresh();
        }

        function list(): string {
            return root.monitors.map(monitor => `${monitor.name}: ${monitor.mode}, ${monitor.x}x${monitor.y}, ${monitor.scale}x, ${monitor.cm}`).join("\n");
        }

        function setHighestRefresh(name: string): void {
            const index = root.monitors.findIndex(monitor => monitor.name === name);
            if (index >= 0)
                root.setHighestRefresh(index);
        }

        function setMain(name: string): void {
            const index = root.monitors.findIndex(monitor => monitor.name === name);
            if (index >= 0)
                root.setMainMonitor(index);
        }

        function move(name: string, x: string, y: string): void {
            const index = root.monitors.findIndex(monitor => monitor.name === name);
            const parsedX = parseInt(x);
            const parsedY = parseInt(y);
            if (index >= 0 && Number.isFinite(parsedX) && Number.isFinite(parsedY))
                root.moveMonitor(index, parsedX, parsedY);
        }

        function keep(): void {
            root.keepChanges();
        }

        function revert(): void {
            root.revertChanges();
        }

        target: "display"
    }
}
