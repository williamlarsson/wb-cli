# Workbook Command Line Interface

_"Work first, harvest after" - Ada Lungu, developer and philanthropist_

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

        wb                              Get overview of commands

        wb reg                          Register to workbook
        wb reg <yyyy-mm-dd>             Register for given date
        wb reg <-int|int>               Register for +/- amount of days.
                                        Example: wb reg -1 //Register for yesterday

        wb manual                       Register to workbook manually
        wb manual <yyyy-mm-dd>          Register to workbook manually for given date
        wb manual <-int|int>            Register to workbook manually +/- amount of days
                                        Example: wb bookings +1 //Get bookings for tomorrow

        wb bookings                     Get bookings overview for today
        wb bookings <yyyy-mm-dd>        Get bookings overview for given date
        wb bookings <-int|int>          Get bookings overview +/- amount of days
        wb bookings <int...int>         Get bookings summary for span of dates"
                                        Example: wb bookings +1 //Get bookings for tomorrow"
                                        Example: wb bookings 0...2 //Get bookings for today + 2 days ahead"

        wb summary                      Get registrations summary for today
        wb summary <yyyy-mm-dd>         Get registrations summary for given date
        wb summary <-int|int>           Get registrations summary +/- amount of days
        wb summary <int...int>          Get registrations summary for span of dates"
                                        Example: wb summary -3...0 //Get summary for last 3 days"
                                        Example: wb summary 2020-01-01 //Get summary for given date"
