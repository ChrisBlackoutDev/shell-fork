pragma Singleton

import QtQuick
import Caelestia.I18n

QtObject {
    id: root

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
    readonly property list<var> pages: [
        // Appearance
        {
            route: "appearance",
            label: Tr.tr("Wallpaper & style"),
            icon: "palette",
            description: Tr.tr("Wallpaper, fonts, colours"),
            category: "appearance"
        },

        // Connectivity
        {
            route: "display",
            label: Tr.tr("Display"),
            icon: "monitor",
            description: Tr.tr("Output configuration"),
            category: "connectivity"
        },
        {
            route: "network",
            label: Tr.tr("Network"),
            icon: "wifi",
            description: Tr.tr("Wi-Fi, ethernet, VPN"),
            category: "connectivity"
        },
        {
            route: "bluetooth",
            label: Tr.tr("Connected devices"),
            icon: "devices_other",
            description: Tr.tr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            route: "audio",
            label: Tr.tr("Audio"),
            icon: "volume_up",
            description: Tr.tr("App volumes, sound devices"),
            category: "connectivity"
        },

        // System
        {
            route: "updates",
            label: Tr.tr("Updates"),
            icon: "update",
            description: Tr.tr("System updates"),
            category: "system"
        },
        {
            route: "plugins",
            label: Tr.tr("Plugins"),
            icon: "extension",
            description: Tr.tr("Manage plugins"),
            category: "system"
        },

        // Shell
        {
            route: "panels",
            label: Tr.tr("Panels"),
            icon: "dock_to_bottom",
            description: Tr.tr("Dashboard, taskbar, launcher, sidebar"),
            category: "shell"
        },
        {
            route: "apps",
            label: Tr.tr("Apps"),
            icon: "apps",
            description: Tr.tr("Default apps, favourites, hidden apps"),
            category: "shell"
        },
        {
            route: "services",
            label: Tr.tr("Services"),
            icon: "build",
            description: Tr.tr("Poll intervals, lyrics backend"),
            category: "shell"
        },
        {
            route: "language",
            label: Tr.tr("Language & region"),
            icon: "globe",
            description: Tr.tr("UI language, weather location, display units"),
            category: "shell"
        },

        // About
        {
            route: "about",
            label: Tr.tr("About"),
            icon: "info",
            description: Tr.tr("System information, credits"),
            category: "about"
        },
    ]

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
