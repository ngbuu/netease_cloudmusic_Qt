import QtQuick 6.2
import QtQuick.Window 6.2
import QtQuick.Controls 6.2
import QtQuick.Layouts 1.15

ListView {
    id: playlistView
    clip: true
    Component.onCompleted: {
        var recordRecentSong = neteaseAPI.recordRecentSong("300")
        if (recordRecentSong !== "") {
            var json = JSON.parse(recordRecentSong)
            var list = json.data.list
            for (var song in list) {
                var _id = list[song].data.id
                var _name = list[song].data.name
                var artist = ""
                for (var _artist in list[song].data.ar)
                    artist += "/" + list[song].data.ar[_artist].name
                artist = artist.substr(1)
                var alia = ""
                for (var _alia in list[song].data.alia)
                    alia += list[song].data.alia[_alia]
                if (list[song].hasOwnProperty("tns"))
                    for (var tn in list[song].data.tns)
                        alia += list[song].data.tns[tn]
                var album = list[song].data.al.name
                var cover = list[song].data.al.picUrl
                playlist.append({
                                    "id": _id,
                                    "name": _name,
                                    "artist": artist,
                                    "alia": alia,
                                    "album": album,
                                    "cover": cover
                                })
            }
        }
    }

    model: ListModel {
        id: playlist
    }
    delegate: MouseArea {
        id: mouseArea
        width: playlistView.width
        height: 45
        onReleased: {
            var songUrl = neteaseAPI.songUrl(id)
            if (songUrl !== "") {
                var json = JSON.parse(songUrl)
                if (json.code === 500) {
                    bannedToast.open()
                } else {
                    player.source = json.data[0].url
                    player.play()
                    var lyric = neteaseAPI.lyric(id)
                    if (lyric !== "") {
                        const lyricElement = {
                            "time": 0, // millisecond
                            "originalLyric": "",
                            "translatedLyric": "",
                            "romanianLyric": ""
                        }
                        const tiArAlByExpression = /^\[(ti|ar|al|by):(.*)\]$/
                        const lyricExpression = /^\[(\d{2}):(\d{2}).(\d{2}|\d{3})\](.*)/
                        var lyricJson = JSON.parse(lyric)
                        var lyricVersion = lyricJson.lrc.version
                        if (lyricVersion === 1 | lyricVersion === 0) {
                            lyricView.hasLyric = false
                            lyricView.autoScroll = false
                            lyricView.model.clear()
                        }
                        else {
                            lyricView.hasLyric = true
                            lyricView.autoScroll = true // I don't know the format of unautoscrollable lyric yet
                            var originalLyric = lyricJson.lrc.lyric
                            var translatedLyric = lyricJson?.tlyric?.lyric ?? ""
                            var romanianLyric = lyricJson?.romalrc?.lyric ?? ""
                            var result
                            var originalLyricModel = originalLyric.split("\n")
                            .filter(function(value){
                                return !(value.match(tiArAlByExpression) !== null | value.trim() === "" | ((value.match(lyricExpression) !== null) ? (value.match(lyricExpression)[4].trim() === "") : false))
                            })
                            .map(function(value){
//                                        if ((result = value.match(lyricExpression)) !== null) {
                                result = value.match(lyricExpression)
                                    return {
                                        "time": Number(result[1]) * 60 * 1000 + Number(result[2]) * 1000 + ((result[3].length > 2) ? Number(result[3]) : Number(result[3]) * 10),
                                        "originalLyric": result[4]
                                    }
//                                        }
                            })
                            var translatedLyricModel = translatedLyric.split("\n")
                            .filter(function(value){
                                return !(value.match(tiArAlByExpression) !== null | value.trim() === "" | ((value.match(lyricExpression) !== null) ? (value.match(lyricExpression)[4].trim() === "") : false))
                            })
                            .map(function(value){
//                                        if ((result = value.match(lyricExpression)) !== null) {
                                result = value.match(lyricExpression)
                                    return {
                                        "time": Number(result[1]) * 60 * 1000 + Number(result[2]) * 1000 + ((result[3].length > 2) ? Number(result[3]) : Number(result[3]) * 10),
                                        "translatedLyric": result[4]
                                    }
//                                        }
                            })
                            if (translatedLyricModel.length > 0) lyricView.hasTranslatedLyric = true
                                else lyricView.hasTranslatedLyric = false
                            var romanianLyricModel = romanianLyric.split("\n")
                            .filter(function(value){
                                return !(value.match(tiArAlByExpression) !== null | value.trim() === "" | ((value.match(lyricExpression) !== null) ? (value.match(lyricExpression)[4].trim() === "") : false))
                            })
                            .map(function(value){
//                                        if ((result = value.match(lyricExpression)) !== null) {
                                result = value.match(lyricExpression)
                                    return {
                                        "time": Number(result[1]) * 60 * 1000 + Number(result[2]) * 1000 + ((result[3].length > 2) ? Number(result[3]) : Number(result[3]) * 10),
                                        "romanianLyric": result[4]
                                    }
//                                        }
                            })
                            if (romanianLyricModel.length > 0) lyricView.hasRomanianLyric = true
                                else lyricView.hasRomanianLyric = false
                            var lyricModel = []
                            for (var i in originalLyricModel) {
                                var _translatedLyric = ""
                                var _romanianLyric = ""
                                for (var j in translatedLyricModel) if (translatedLyricModel[j].time === originalLyricModel[i].time) {
                                                                                                                                _translatedLyric = translatedLyricModel[j].translatedLyric
                                                                                                                                break
                                                                                                                                }
                                for (var k in romanianLyricModel) if (romanianLyricModel[k].time === originalLyricModel[i].time) {
                                                                                                                                _romanianLyric = romanianLyricModel[k].romanianLyric
                                                                                                                                break
                                                                                                                                }
                                lyricModel.push({
                                                "time": originalLyricModel[i].time,
                                                "originalLyric": originalLyricModel[i].originalLyric,
                                                "translatedLyric": _translatedLyric,
                                                "romanianLyric": _romanianLyric
                                })
                            }
                            lyricView.model.clear()
                            for (var n in lyricModel) {
                                lyricView.model.append({
                                    "time": lyricModel[n].time,
                                    "originalLyric": lyricModel[n].originalLyric,
                                    "translatedLyric": lyricView.hasTranslatedLyric? lyricModel[n].translatedLyric : "",
                                    "romanianLyric": lyricView.hasRomanianLyric? lyricModel[n].romanianLyric : ""
                                })
                            }
                        }
                    }
                }
            }
        }

        Material_Image {
            id: songCover
            width: height
            radius: 2
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            source: cover
            elevation: 2
            anchors.leftMargin: 5
            anchors.bottomMargin: 5
            anchors.topMargin: 5
        }

        RowLayout {
            anchors.left: songCover.right
            anchors.leftMargin: 5
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: 5
            height: 20
            Text {
                id: songName
                Layout.preferredHeight: parent.height
                Layout.preferredWidth: contentWidth
                text: name
                elide: Text.ElideRight
                font.pointSize: 12
            }
            Text {
                id: songAlia
                color: "#424242"
                Layout.preferredHeight: parent.height
                Layout.fillWidth: true
                text: (alia === "") ? "" : qsTr("（") + alia + qsTr("）")
                elide: Text.ElideRight
                font.pointSize: 12
            }
        }
        RowLayout {
            anchors.left: songCover.right
            anchors.leftMargin: 5
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 0
            anchors.bottomMargin: 10
            height: 10
            Text {
                id: songArtist
                color: "#424242"
                Layout.preferredHeight: parent.height
                Layout.preferredWidth: contentWidth
                text: artist
                elide: Text.ElideRight
            }
            Text {
                id: songAlbum
                color: "#424242"
                Layout.preferredHeight: parent.height
                Layout.fillWidth: true
                text: qsTr(" - ") + album
                elide: Text.ElideRight
            }
        }
    }
}
