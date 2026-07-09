// Handle Time Data Updating upon 'mpc status'

function main(output) {

    /*
     * The Received Output is in the form of:
     *
     * If Playing:
     *  <Song Title>
     *  [<Playing Status] #<No In queue>/<Total Songs>  <Time Elapsed>/<Total Time>  <Elapsed Percent>
     *  volume: repeat: random: single: consume:
     *
     * If Not Playing:
     *  volume: repeat: random: single: consume:
     *
     *
     * Splitting the Data by Lines we Receive
     *  [0]: Song Title ; [1]: Playing Status and Time Data; [2]: Boolean Datas
     */


    // Split Data By Lines
    let x = output["stdout"].split("\n") ;


    // Ensure a Song is Actually Playing
    if( !x[0].startsWith("volume") ) {

        /*
         * Parses the Time Data in Second Line using Regex
         *
         * Input:
         *      [Playing] #1/16 0:04/3:02 (3%)
         *
         * Output:
         *      timeMatch[0]: "0:04/3:02"
         *      timeMatch[1]: "0:04"
         *      timeMatch[2]: "3:02"
         *
         */
        let timeMatch = x[1].match(/(\d+:\d+)\/(\d+:\d+)/);


        // Split the Minutes and Seconds
        let current_time = timeMatch[1].split(":") ;
        let total_time = timeMatch[2].split(":") ;

        // Convert the time into Pure Seconds and of INT
        let current_sec = parseInt(current_time[0]*60) + parseInt(current_time[1]) ;
        let total_sec = parseInt(total_time[0]*60 + parseInt(total_time[1])) ;

        if(total_sec===0) {
            return 0
        }
        return current_sec/total_sec
    }

    return 0
}
