// Handle the Song and Artist Titles
function handleTrackTitles(output) {

    /*
     * Input is in the form of "<ArtistName>\x1f<TitleTrack>\x1f<FileLocation>"
     *
     * \x1f: Is the Unit Seperator ASCII Character, not displayed in Prints
     * In Case the song Lacks Metadata containing TitleTrack, the FileLocation would be used
     *
     * Output: x[0]: <Artist Name> ; x[1]: <Track Title> ; x[2]: <File Location>
     */
    let x = output.split("\x1f")

    let trackArtist = x[0]
    let trackTitle = ''

    if(x[1]) {
        trackTitle = String(x[1])
    } else {
        trackTitle = String(x[2])
    }

    if(trackTitle) {
        return [trackTitle, trackArtist]
    } else {
        return ["", ""]
    }

}
