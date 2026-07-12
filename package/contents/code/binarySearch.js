// Binay Search to ensure a playlist name doesn't already exist

function existsInArray(input, array) {
    /*
     * Checks whether the input exists in the array.
     *
     * Use Case in the widget:
     *  Input: Contains a String containing a playlist Name/Rename
     *  Array: Contains the list of Playlists in MPC
     */

    let low = 0
    let high = array.length - 1
    let mid = 0
    let midVal = ""

    input = input.toUpperCase()

    while (low <= high) {
        mid = Math.floor( (low + high) / 2 )
        midVal = array[mid].toUpperCase()

        // If Value is Found
        if(input === midVal) {
            return true
        }

        // Remove Half the Array
        if(input > midVal) {
            low = mid + 1
        } else {
            high = mid - 1
        }
    }

    return false
}
