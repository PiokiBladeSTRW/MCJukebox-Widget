import QtQuick
import org.kde.plasma.plasma5support 2.0 as PS

import com.pioki.jukebox.backend 1.0        // C++ Plugin, works same as mpc idleloop player
import "../code/dirSanitize.js" as DirSanitize

QtObject {
    id: root

    // ==========================================
    // ENGINE
    // ==========================================

    // LISTENER LOOP
    property var titleUpdateCallback;
    property var playlistUpdateCallback;

    property var mpdListen: MPDListen {

        // Update Title & playStatus upon any player Changes
        function statusTitleUpdate() {

            // Update Title
            titlesUpdate(titleUpdateCallback)

            // Handle playStatus Configuration
            _run("mpc status", function(output){
                let splitData= output.trim().split("\n")

                // Nothing's Loaded Pause
                if( splitData[0].startsWith("volume") ) {
                    plasmoid.configuration.playStatus = false

                } else if(splitData[1].startsWith("[paused]")) {
                    plasmoid.configuration.playStatus = false

                } else {
                    plasmoid.configuration.playStatus = true
                }
            })
        }

        // Start Up
        Component.onCompleted: {
            start(plasmoid.configuration.mpdHost, plasmoid.configuration.mpdPort)
            statusTitleUpdate()
        }


        onPlayerChanged: {
            statusTitleUpdate()
        }

        onPlaylistsChanged: {
            playlistsListUpdate(playlistUpdateCallback)
        }
    }

    // TERMINAL COMMANDS EXECUTOR
    property var _callbackRegistry: ({})
    property int _callbackUID: 0

    property var engine: PS.DataSource {
        engine: "executable"
        connectedSources: []

        onNewData: (sourceName, data) =>{
            if(root._callbackRegistry[sourceName]) {
                var callbackFunc = root._callbackRegistry[sourceName];

                callbackFunc(data["stdout"]);
                delete root._callbackRegistry[sourceName]
            }

            disconnectSource(sourceName)
        }
    }

    // Function called by Public Functions
    function _run(cmd, callback) {
        if(callback) {
            let _uniqueCmd = cmd + " #" + _callbackUID;
            _callbackUID += 1;

            _callbackRegistry[_uniqueCmd] = callback;

            engine.connectSource(_uniqueCmd);
        } else{
            engine.connectSource(cmd);
        }
    }


    // ==========================================
    // CLEANUP (SANITIZATION)
    // ==========================================

    function sanitize(input) {
        return DirSanitize.inputClean(input);
    }


    // ==========================================
    // PUBLIC FUNCTIONS
    // ==========================================


    // ---------------
    // CACHE COMMANDS
    // ---------------

    // Refresh Slates Upon Open
    function hasDependencies(callback) {
        _run("which mpc && which mpd && echo 1 || echo 0", callback)
    }

    function bootUp() {
        _run("mkdir ~/.cache/jukebox_covers; mpc update")
    }

    function homeRegister(callback) {
        _run("ls /home", callback)
    }

    // ---------------
    // MUSIC PLAYER COMMANDS
    // ---------------


    // Toggle Play/Pause
    function playToggle(){
        _run("mpc toggle")
    }

    // Change Song -1: Previous, 1: Forward
    function changeSong(changeDirection) {
        if(changeDirection === 1) {
            _run("mpc next")
        } else {
            _run("mpc prev")
        }
    }

    // Seeks Specific Song Position
    function seekPosition(position) {
        _run("mpc seek "+ position)
    }

    // Toggle Shuffle
    function shuffleToggle() {
        _run("mpc shuffle")
    }

    // Toggle Repeat
    function repeatToggle(){
        _run("mpc repeat; mpc single")
    }

    // Temporary Song Play
    function tempSong(directory) {
        let cleanDir = sanitize(directory)

        // Callback as idle Might Miss toggle due to Cooldown [band-aid fix]
        _run(`
            mpc clear;
            mpc add ${cleanDir};
            mpc toggle;`.trim(), function(){
                titlesUpdate(titleUpdateCallback)
            })

        // If Shuffle was previously Enabled
        if(plasmoid.configuration.shuffle) {
            shuffleToggle()
        }
    }

    // Status Handling
    function statusUpdate(callback) {
        _run("mpc status", callback)
    }

    // Title Updating
    function titlesUpdate(callback) {
        _run("mpc -f '%artist%\x1f%title%\x1f%file%' current", callback)
    }



    // ---------------
    // UTILITES
    // ---------------

    // Search for Songs; isTitle: 1 - Search Titles; 0 - Search Files
    function search(text, isTitle, callback) {
        let cleanText = sanitize(text)
        let format = ""

        if(isTitle) {
            format = "title"
        } else {
            format = "file"
        }

        _run("mpc search -f '%"+ format+ "%' title "+ cleanText, callback)
    }


    // ---------------
    // PLAYLIST COMMANDS
    // ---------------

    // Chose a Playlist to play Songs Of
    function chosenPlaylist(playlistName) {
        let safeName = sanitize(playlistName)

        // Callback as idle Might Miss toggle due to Cooldown [band-aid fix]
        _run(`
            mpc clear;
            mpc load ${safeName};
            mpc toggle;`.trim(), function(output){
              titlesUpdate(titleUpdateCallback)
            })

        // If Shuffle was previously Enabled
        if(plasmoid.configuration.shuffle) {
            shuffleToggle()
        }
    }

    // Add a Playlist
    function addPlaylist(playlistName, playlistFolders, albumArt) {

        // Sanitize Playlist Name
        let safeName = sanitize(playlistName);

        // Make the Song Addition into ONE Command
        let commands = [];
        for (let i=0; i<playlistFolders.length; i++) {
            let folderPath = sanitize(playlistFolders[i]);
            commands.push( "mpc addplaylist "+ safeName + " " + folderPath) ;
        }
        let addCommand = commands.join("; ");

        // Update Directories, Save the Playlist, Add the Songs
        _run (`
            mpc update;
            mpc save ${safeName};
            mpc clearplaylist ${safeName};
            ${addCommand};
        `.trim())

        // Handle Album Art if Given
        if(albumArt) {
            let safeAlbumArt = sanitize(albumArt);
            _run("cp " + safeAlbumArt + " ~/.cache/jukebox_covers/"+ safeName +".png;")
        }
    }


    // Edit an Existing playlist
    function editPlaylist(playlist, newName, albumArt, songsAdded, songsRemoval){

        let safePlaylist = sanitize(playlist) ;
        let safeName = sanitize(newName) ;

        let commands= [];

        // Change Name
        if(newName) {
            commands.push("mpc renplaylist "+ safePlaylist + " "+ newName);
        } else {
            safeName = safePlaylist;
        }

        // Change Album Art
        if(albumArt) {
            let safeAlbumArt = sanitize(albumArt);
            commands.push( "rm ~/.cache/jukebox_covers/"+safePlaylist+".png");
            commands.push("cp "+ safeAlbumArt + " ~/.cache/jukebox_covers/" + safeName + ".png");
        }

        // Add Chosen Songs
        for (let i = 0; i<songsAdded.length; i++) {
            commands.push("mpc addplaylist "+ safeName + " "+ sanitize(songsAdded[i])) ;
        }

        // Remove Chosen Songs
        for (let i =0; i<songsRemoval.length ; i++) {
            commands.push("mpc delplaylist "+ safeName+" "+ songsRemoval[i]);
        }

        // Final Singular Command merging them all
        let finalCommand = commands.join("; ")
        _run(finalCommand)
    }


    // Delete a Playlist
    function deletePlaylist(playlist) {
        let safeName = sanitize(playlist)
        _run("mpc rm "+ safeName)
    }

    // Obtain List of Songs in a Playlist
    function obtainSongsPlaylist(playlist, callback) {
        let safeName = sanitize(playlist)
        _run("mpc playlist "+ safeName, callback)
    }

    // Obtain List of Files[later filtered to Songs] in a Directory
    function obtainSongsDirectory(path, callback) {
        let finalPath = sanitize( plasmoid.configuration.musicPath + path )
        _run("ls -p "+ finalPath + " | grep -v /", callback)
    }

    // Obtain a List of Playlists
    function playlistsListUpdate(callback) {
        _run("mpc lsplaylists | sort -f", callback)
    }
}
