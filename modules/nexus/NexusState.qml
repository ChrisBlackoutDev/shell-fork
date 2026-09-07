import QtQuick
import Quickshell
import Quickshell.Bluetooth

QtObject {
    property ShellScreen screen
    property bool isWindow
    property bool animatingContainer
    property int currentPageIdx
    property list<int> subPageIdxStack
    property bool searchOpen

    property string selectedWallpaperCategory
    property BluetoothDevice selectedBtDevice
    property DesktopEntry selectedApp
    property int editingVpnIndex: -1
    property string selectedNetworkSsid
    property string selectedEthernetInterface
    property bool networkDetailsFromSaved
    property bool preserveSubPageStack: false

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed

    function navigate(pageIdx: int, subPages: list<int>): void {
        preserveSubPageStack = true;
        currentPageIdx = pageIdx;
        subPageIdxStack = [...subPages];
        preserveSubPageStack = false;
    }

    function openSubPage(idx: int): void {
        subPageIdxStack.push(idx);
        subPageOpened(idx);
    }

    function closeSubPage(): void {
        subPageClosed();
        subPageIdxStack.pop();
    }

    onCurrentPageIdxChanged: {
        if (!preserveSubPageStack)
            subPageIdxStack.length = 0;
    }
}
