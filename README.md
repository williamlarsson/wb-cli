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

        wb                          Command to register to workbook
        wb <yyyy-mm-dd>             Register for given date
        wb bookings                 Get bookings overview for today
        wb bookings <yyyy-mm-dd>    Get bookings overview for given date
