pragma Singleton

import QtQuick

QtObject {
    id: root

    readonly property list<var> pages: [
        // Appearance
        {
            route: "appearance",
            label: qsTr("Wallpaper & style"),
            icon: "palette",
            description: qsTr("Wallpaper, fonts, colours"),
            category: "appearance"
        },

        // Connectivity
        {
            route: "display",
            label: qsTr("Display"),
            icon: "monitor",
            description: qsTr("Output configuration"),
            category: "connectivity"
        },
        {
            route: "network",
            label: qsTr("Network"),
            icon: "wifi",
            description: qsTr("Wi-Fi, ethernet, VPN"),
            category: "connectivity"
        },
        {
            route: "bluetooth",
            label: qsTr("Connected devices"),
            icon: "devices_other",
            description: qsTr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            route: "audio",
            label: qsTr("Audio"),
            icon: "volume_up",
            description: qsTr("App volumes, sound devices"),
            category: "connectivity"
        },

        // System
        {
            route: "updates",
            label: qsTr("Updates"),
            icon: "update",
            description: qsTr("System updates"),
            category: "system"
        },
        {
            route: "plugins",
            label: qsTr("Plugins"),
            icon: "extension",
            description: qsTr("Manage plugins"),
            category: "system"
        },

        // Shell
        {
            route: "panels",
            label: qsTr("Panels"),
            icon: "dock_to_bottom",
            description: qsTr("Dashboard, taskbar, launcher, sidebar"),
            category: "shell"
        },
        {
            route: "apps",
            label: qsTr("Apps"),
            icon: "apps",
            description: qsTr("Default apps, favourites, hidden apps"),
            category: "shell"
        },
        {
            route: "services",
            label: qsTr("Services"),
            icon: "build",
            description: qsTr("Poll intervals, lyrics backend"),
            category: "shell"
        },
        {
            route: "language",
            label: qsTr("Language & region"),
            icon: "globe",
            description: qsTr("UI language, weather location, display units"),
            category: "shell"
        },

        // About
        {
            route: "about",
            label: qsTr("About"),
            icon: "info",
            description: qsTr("System information, credits"),
            category: "about"
        },
    ]

    readonly property var compatibilityRoutes: ({
            taskbar: {
                page: "panels",
                subPages: [2]
            },
            notifications: {
                page: "services",
                subPages: [1]
            },
            launcher: {
                page: "panels",
                subPages: [3]
            },
            dashboard: {
                page: "panels",
                subPages: [1]
            }
        })

    function resolveRoute(route: string): var {
        const compatibility = compatibilityRoutes[route];
        const pageRoute = compatibility?.page ?? route;
        const pageIndex = pages.findIndex(page => page.route === pageRoute);
        if (pageIndex < 0)
            return null;

        return {
            pageIndex,
            subPages: compatibility?.subPages ?? []
        };
    }
}
