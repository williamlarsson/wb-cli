# Workbook Command Line Interface
*"Work first, harvest after" - Ada Lungu, developer and philanthropist*

### Install jq (json parser for bash)
Mac: `brew install jq`

Win: `chocolatey install jq`

### Setup
- Duplicate config.example and rename to config.sh
- Update config.sh variables
- Finally, add these two lines to your .zshrc, .bash_profile or .bashrc file, and open a new terminal window / reload the session.

        source /path/to/wb-cli/config.sh
        source /path/to/wb-cli/wb-cli.sh

### Setup complete

## Usage
        wb                            Get overview of commands

        wb reg|register               Register to workbook
        wb reg|register <yyyy-mm-dd>  Register for given date
        wb reg|register <-int|int>    Register for +/- amount of days.
                                      Example: wb reg -1 -> Register for yesterday

        wb bookings                   Get bookings overview for today
        wb bookings <yyyy-mm-dd>      Get bookings overview for given date
        wb bookings <-int|int>        Get bookings overview +/- amount of days
                                      Example: wb bookings +1 -> Get bookings for tomorrow

        wb search|manual              Register to workbook manually
        wb search|manual <yyyy-mm-dd> Register to workbook manually for given date
        wb search|manual <-int|int>   Register to workbook manually +/- amount of days