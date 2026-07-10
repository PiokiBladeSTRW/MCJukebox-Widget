// Cleanup user Fed Directories to avoid Shell Injection [Using meta characters users can inject terminal commands]

/*
 * If a folder/song/artist name contains meta characters like &, ;, |, ` or such, it is possible to inject Commands into the Terminal.
 * That is, commands can be ran into the device with just certain names.
 *
 * Two steps are taken to Avoid this:
 *  1) Encapsulation:
 *          Encapsulating user fed Strings into " " allows for meta chars to run. But ' ' takes everything as literal string, nothing is Executed
 *  2) Cleanup:
 *          Pre-existing ' in the name will lead to errors, hence those are handled using \
 *
 *  Example: " Guns N' Roses " should become: 'Guns N' \' 'Roses'
 */


function inputClean(input) {
    /*
     * Splits String based on ' and then joins them with proper \'
     *
     * Let's take two example Inputs, A: "Guns N' Roses" & "They '' Us"
     *
     * splitData gets the respective data: ["Guns N", " Roses"] & ["They ", "", " Us"]
     *
     * We Loop through splitData, if the element exists [inferring it wasn't consequtive quotes], we encapsulate it in ' ' then add it to encapData
     * If the element IS empty, an empty element is passed to encapData as well to ensure multiple quotes work!
     *
     * encapData gets the respective data: ["'Guns N'", "' Roses'"] & ["'They '", "", "' Us'"]
     *
     * At end we join encapData by "\\'", so every space is filled with backslash colons,
     *
     * Final Output becomes respectively: 'Guns N'\'' Roses' & 'They '\'\'' Us'
     *
     * Which when interpreted by shell becomes plain Guns N' Rosees & They '' Us ; No Commands within the strings are executed ever
     */

    let splitData= input.split("'")
    let encapData= []

    for (let i =0; i<splitData.length; i++) {

        if(splitData[i]) {
            encapData.push("'"+ splitData[i] + "'" )
        } else {
            encapData.push("")
        }
    }
    return encapData.join("\\'")
}
