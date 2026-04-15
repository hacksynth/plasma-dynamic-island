pragma ComponentBehavior: Bound

import QtQuick
import org.kde.plasma.private.mpris as Mpris

// Subscribes to KDE's multiplexed MPRIS model. Mpris2Model picks the
// currently-active player across all running media apps; we only see
// one logical "current track" via currentPlayer.
QtObject {
    id: source

    property int _refreshCount: 0
    property bool _ready: false
    property bool _hasActiveSlot: false

    property Mpris.Mpris2Model _mpris: Mpris.Mpris2Model {
        id: mprisModel
    }

    readonly property var _player: mprisModel.currentPlayer

    on_PlayerChanged: {
        console.log("[media-source] currentPlayer ->",
            _player ? (_player.identity || "(unnamed)") : "null")
        _scheduleRefresh()
    }

    // 50ms throttle. PropertiesChanged fires multiple changed signals in
    // the same frame on track changes (track + artist + album + artUrl);
    // coalesce them into a single _refresh().
    property Timer _dispatchTimer: Timer {
        id: dispatchTimer
        interval: 50
        repeat: false
        onTriggered: source._refresh()
    }

    property Connections _playerConnections: Connections {
        target: source._player
        ignoreUnknownSignals: true
        function onPlaybackStatusChanged() { source._scheduleRefresh() }
        function onTrackChanged()          { source._scheduleRefresh() }
        function onArtistChanged()         { source._scheduleRefresh() }
        function onAlbumChanged()          { source._scheduleRefresh() }
        function onArtUrlChanged()         { source._scheduleRefresh() }
    }

    function _scheduleRefresh() {
        if (!_ready) return
        dispatchTimer.restart()
    }

    function _refresh() {
        _refreshCount++
        const p = source._player

        if (!p) {
            if (_hasActiveSlot) {
                console.log("[media-source] no player, dismissing media slot")
                IslandController.dismiss("media")
                _hasActiveSlot = false
            }
            return
        }

        const status = p.playbackStatus
        const isStopped = (status === Mpris.PlaybackStatus.Stopped
            || status === Mpris.PlaybackStatus.Unknown)

        if (isStopped) {
            if (_hasActiveSlot) {
                console.log("[media-source] player stopped, dismissing media slot")
                IslandController.dismiss("media")
                _hasActiveSlot = false
            }
            return
        }

        const data = {
            track: p.track || "",
            artist: p.artist || "",
            album: p.album || "",
            artUrl: (p.artUrl || "").toString(),
            playing: status === Mpris.PlaybackStatus.Playing,
            identity: p.identity || "",
            iconName: p.iconName || ""
        }

        console.log("[media-source] refresh #" + _refreshCount,
            "playing=" + data.playing,
            "track=" + data.track.substring(0, 30),
            "artist=" + data.artist.substring(0, 20),
            "artUrl=" + (data.artUrl ? data.artUrl.substring(0, 60) : "(none)"))

        IslandController.request("media", data)
        _hasActiveSlot = true
    }

    Component.onCompleted: {
        console.log("[media-source] initial currentPlayer:",
            mprisModel.currentPlayer
                ? (mprisModel.currentPlayer.identity || "(unnamed)")
                : "null")

        Qt.callLater(function() {
            source._ready = true
            console.log("[media-source] ready")
            source._scheduleRefresh()
        })
    }
}
