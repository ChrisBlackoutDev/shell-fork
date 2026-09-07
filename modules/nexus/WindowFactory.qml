pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.components
import qs.services
import qs.modules.nexus

Singleton {
    id: root

    function create(parent: Item, props: var): void {
        nexusComp.createObject(parent ?? dummy, props);
    }

    function createForRoute(route: string): bool {
        const resolved = PageRegistry.resolveRoute(route);
        if (!resolved)
            return false;

        create(null, {
            initialPageIndex: resolved.pageIndex,
            initialSubPages: resolved.subPages
        });
        return true;
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            property int initialPageIndex: 0
            property list<int> initialSubPages: []

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth
            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: Tr.tr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx].label)

            Nexus {
                id: nexus

                anchors.fill: parent
                nState.screen: win.screen
                nState.isWindow: true
                Component.onCompleted: nState.navigate(win.initialPageIndex, win.initialSubPages)
                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
