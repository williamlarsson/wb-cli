function wbRegister () {

    WORKBOOK_TASK_BOOKING=$1

    WORKBOOK_TASK_ID=$( echo $WORKBOOK_TASK_BOOKING | jq -j '.TaskId')
    TOTAL_HOURS_BOOKED=$( jq -n $TOTAL_HOURS_BOOKED + $( echo $WORKBOOK_TASK_BOOKING | jq -j '.Hours') )

    WORKBOOK_REGISTERED_HOURS=$( echo $REGISTERED_TASKS | jq -j '[.[] | select(.TaskId == '$WORKBOOK_TASK_ID') | .Hours ] | add // 0' )

    WORKBOOK_TASK_DATA=$( curl -s "https://workbook.magnetix.dk/api/task/${WORKBOOK_TASK_ID}/visualization" \
        -H "Accept: application/json, text/plain, */*" \
        -H "Content-Type: application/json" \
        -H "Cookie: ${COOKIE}" )

    echo ""
    echo "${reset}You're booked on: ${green}$( echo $WORKBOOK_TASK_DATA | jq -j '.JobName')"
    echo "${reset}Hours booked: ${green}$( echo $WORKBOOK_TASK_BOOKING | jq -j '.Hours')"
    echo "${reset}Hours registered: ${green}$WORKBOOK_REGISTERED_HOURS"
    echo "${reset}Taskname: ${green}$( echo $WORKBOOK_TASK_DATA | jq -j '.TaskName')"
    echo ""

    # NO REGISTERED HOURS
    if [[ $WORKBOOK_REGISTERED_HOURS == 0 ]]; then

        echo "${reset}Do want to register this booking?"
        echo "${green}1: ${reset} Yes, I want to register the booked amount of hours: ${green}$( echo $WORKBOOK_TASK_BOOKING | jq -j '.Hours')"
        echo "${green}2: ${reset} Yes, I want to register, but manually enter the amount of hours."
        echo "${green}3: ${reset} No, I don't want to register to this booking"
        echo -n "${reset}Enter number and press [ENTER]: "
        read USER_HOURS

        if [[ "$USER_HOURS" == "1" ]]; then
            USER_HOURS=$( echo $WORKBOOK_TASK_BOOKING | jq -j '.Hours')

        elif [[ "$USER_HOURS" == "2" ]]; then
            echo -n "${reset}Enter amount of desired hours and press [ENTER]: "
            read USER_HOURS

        elif [[ "$USER_HOURS" == "3" ]]; then
            return
        fi


        echo -n "${reset}Enter description for the registration and press [ENTER]: "
        read USER_DESCRIPTION

        echo "${reset}Sending registration to workbook"

        REGISTER_TIME_REQUEST=$( curl -s "https://workbook.magnetix.dk/api/personalexpense/timeentry/week" \
            -H "Accept: application/json, text/plain, */*" \
            -H "Content-Type: application/json" \
            -H "Cookie: ${COOKIE}" \
            -X "POST" \
            -d '{"ResourceId":'$WORKBOOK_USER_ID',"TaskId":'$( echo $WORKBOOK_TASK_BOOKING | jq -j '.TaskId')',"Hours":'$USER_HOURS',"Description":"'"$USER_DESCRIPTION"'", "Date":'$DATE'T00:00:00.000Z}' )

    else
        # PREVIOUSLY REGISTERED, UPDATE
        echo "${reset}Do want to update this booking?"
        echo "${green}1: ${reset} Yes, I want to update with the booked amount of hours: ${green}$( echo $WORKBOOK_TASK_BOOKING | jq -j '.Hours')"
        echo "${green}2: ${reset} Yes, I want to update, but manually enter the amount of hours."
        echo "${green}3: ${reset} No, I don't want to update this booking"
        echo -n "${reset}Enter number and press [ENTER]: "
        read USER_HOURS

        if [[ "$USER_HOURS" == "1" ]]; then
            USER_HOURS=$( echo $WORKBOOK_TASK_BOOKING | jq -j '.Hours')

        elif [[ "$USER_HOURS" == "2" ]]; then
            echo -n "${reset}Enter amount of desired hours and press [ENTER]: "
            read USER_HOURS

        elif [[ "$USER_HOURS" == "3" ]]; then
            return
        fi


        echo -n "${reset}Enter description for the registration and press [ENTER]: "
        read USER_DESCRIPTION

        echo "${reset}Sending registration to workbook"

        WORKBOOK_REGISTERED_ID=$( echo $REGISTERED_TASKS | jq -j '[.[] | select(.TaskId == '$WORKBOOK_TASK_ID') | select(.Hours > 0) ] | first | .Id' )

        REGISTER_TIME_REQUEST=$( curl -s "https://workbook.magnetix.dk/api/json/reply/TimeEntryUpdateRequest" \
            -H "Accept: application/json, text/plain, */*" \
            -H "Content-Type: application/json" \
            -H "Cookie: ${COOKIE}" \
            -X "POST" \
            -d '{"Id": '$WORKBOOK_REGISTERED_ID', "ResourceId":'$WORKBOOK_USER_ID',"TaskId":'$( echo $WORKBOOK_TASK_BOOKING | jq -j '.TaskId')',"Hours":'$USER_HOURS',"Description":"'"$USER_DESCRIPTION"'","Date":'$DATE'T00:00:00.000Z}' )

    fi
}

function wb () {
    magenta=`tput setaf 5`
    blue=`tput setaf 4`
    red=`tput setaf 1`
    green=`tput setaf 2`
    reset="$(tput sgr0)"

    if [[ "$1" = "register" ]] || [[ "$1" = "reg" ]] || [[ "$1" = "bookings" ]] || [[ "$1" = "today" ]] || [[ "$1" = "search" ]] || [[ "$1" = "manual" ]]; then

        echo "${reset}Establishing authentication to workbook..."

        # SET DATE ACCORDING TO USER INPUT
        if [[ $(( ${#2} > 0 )) == 1 && $(( ${#2} < 4 )) == 1  ]]; then
            CALCULATED_UNIX_DATE=$(( $( date +"%s" ) + $(( $2 * 86400 )) ))
            DATE=$( date -r $CALCULATED_UNIX_DATE +'%Y-%m-%d' )
            DATE_MESSAGE="$DATE"
        else
            DATE=${2:-$(date +'%Y-%m-%d')}
            DATE_MESSAGE="${2:-'today'}"
        fi



        AUTH_WITHOUT_HEADERS=$(curl -s "https://workbook.magnetix.dk/api/auth/ldap" \
            -H "Content-Type: application/json" \
            -X "POST" \
            -d '{"UserName":"'"$WORKBOOK_USERNAME"'","Password":"'"$WORKBOOK_PASSWORD"'", "RememberMe": true}')

        if [[ $WORKBOOK_RESOURCE_ID ]]; then
            WORKBOOK_USER_ID=$WORKBOOK_RESOURCE_ID
        else
            WORKBOOK_USER_ID=$( echo $AUTH_WITHOUT_HEADERS | tr '\r\n' ' ' |  jq '.Id' )
        fi

        AUTH_WITH_HEADERS=$(curl -i -s "https://workbook.magnetix.dk/api/auth/ldap" \
            -H "Content-Type: application/json" \
            -X "POST" \
            -d '{"UserName":"'"$WORKBOOK_USERNAME"'","Password":"'"$WORKBOOK_PASSWORD"'", "RememberMe": true}')

        # GET INFO FROM RESPONSE TO SET COOKIE
        if [[ $AUTH_WITH_HEADERS =~ "ss-pid=(.{20})" ]]; then
            SS_PID=${match[1]}
        elif [[ $AUTH_WITH_HEADERS =~ ss-pid=(.{20}) ]]; then
            SS_PID=${BASH_REMATCH[1]}
        else
            echo "Couldn't authenticate"
            return;
        fi

        if [[ $AUTH_WITH_HEADERS =~ "ss-id=(.{20})" ]]; then
            SS_ID=${match[1]}
        elif [[ $AUTH_WITH_HEADERS =~ ss-id=(.{20}) ]]; then
            SS_ID=${BASH_REMATCH[1]}
        else
            echo "Couldn't authenticate"
            return;
        fi

        COOKIE="X-UAId=; ss-opt=perm; ss-pid=${SS_PID}; ss-id=${SS_ID};"

        FILTER_RESPONSE=$( curl -s "https://workbook.magnetix.dk/api/schedule/weekly/visualization/data?ResourceIds=${WORKBOOK_USER_ID}&PeriodType=1&Date=${DATE}&Interval=1" \
            -H "Accept: application/json, text/plain, */*" \
            -H "Content-Type: application/json" \
            -H "Cookie: ${COOKIE}" \
            -X "POST" \
            -d '{}' )

        FILTER_RESPONSE_DETAILS=$( echo $FILTER_RESPONSE | jq '.[] | .Data | ."0" | .Details ')

        NUM_OF_BOOKINGS=$( echo $FILTER_RESPONSE_DETAILS | jq length)

        BOOKINGS_COUNTER=0

        REGISTERED_TASKS=$( curl -s "https://workbook.magnetix.dk/api/personalexpense/timeentry/visualization/entries?ResourceId=${WORKBOOK_USER_ID}&Date=${DATE}" \
            -H "Accept: application/json, text/plain, */*" \
            -H "Content-Type: application/json" \
            -H "Cookie: ${COOKIE}" )

        FILTER_RESPONSE_DETAILS=$( echo $FILTER_RESPONSE | jq '.[] | .Data | ."0" | .Details ')

        NUM_OF_BOOKINGS=$( echo $FILTER_RESPONSE_DETAILS | jq length)

        if [[ "$1" = "register" ]] || [[ "$1" = "reg" ]]; then


            TOTAL_HOURS_BOOKED=0
            TOTAL_HOURS_REGISTERED=0

            echo "${reset}You have ${green}$NUM_OF_BOOKINGS ${reset}booking(s) for ${green}$DATE_MESSAGE."

            BOOKINGS_COUNTER=0
            while [ $BOOKINGS_COUNTER -lt $NUM_OF_BOOKINGS ]; do

                CURRENT_TASK_BOOKING=$( echo $FILTER_RESPONSE_DETAILS | jq  " .[${BOOKINGS_COUNTER}]" )

                wbRegister "$CURRENT_TASK_BOOKING"
                let BOOKINGS_COUNTER=BOOKINGS_COUNTER+1
            done

            echo ""
            echo "${blue}Overview:${reset}"

            BOOKINGS_COUNTER=0
            while [ $BOOKINGS_COUNTER -lt $NUM_OF_BOOKINGS ]; do

                CURRENT_TASK_BOOKING=$( echo $FILTER_RESPONSE_DETAILS | jq  " .[${BOOKINGS_COUNTER}]" )

                WORKBOOK_TASK_ID=$( echo $CURRENT_TASK_BOOKING | jq -j '.TaskId')

                WORKBOOK_REGISTERED_HOURS=$( echo $REGISTERED_TASKS | tr '\r\n' ' ' | jq -j "[.[] | select(.TaskId == $WORKBOOK_TASK_ID) | .Hours ] | add // 0" )

                WORKBOOK_TASK_DATA=$( curl -s "https://workbook.magnetix.dk/api/task/${WORKBOOK_TASK_ID}/visualization" \
                    -H "Accept: application/json, text/plain, */*" \
                    -H "Content-Type: application/json" \
                    -H "Cookie: ${COOKIE}" )

                echo ""
                echo "${reset}Client: ${green}$( echo $WORKBOOK_TASK_DATA | jq -j '.JobName')"
                echo "${reset}Hours: ${green}$( echo $CURRENT_TASK_BOOKING | jq -j '.Hours')"
                echo "${reset}Hours registered: ${green}$WORKBOOK_REGISTERED_HOURS"
                echo "${reset}Taskname: ${green}$( echo $WORKBOOK_TASK_DATA | jq -j '.TaskName')"
                let TOTAL_HOURS_REGISTERED=8
                let BOOKINGS_COUNTER=BOOKINGS_COUNTER+1
            done

            #SUMMARIZE
            echo ""
            if [[ $(( $TOTAL_HOURS_BOOKED < $TOTAL_HOURS_REGISTERED )) = "1" ]]; then
                echo "${red}Heads up. You have overbooked with ${green}$(( $TOTAL_HOURS_REGISTERED - $TOTAL_HOURS_BOOKED ))${red} hours. "
                echo "${reset}Run the register again to update, or visit workbook manually to correct this."

            elif [[ $(( $TOTAL_HOURS_BOOKED > $TOTAL_HOURS_REGISTERED )) = "1" ]]; then
                echo "${red}Heads up. You have underbooked with ${green}$(( $TOTAL_HOURS_BOOKED - $TOTAL_HOURS_REGISTERED )) ${red} hours. "
                echo "${reset}Run the register again to update, or visit workbook manually to correct this."
            else
                echo "${green}Done"
                echo "${reset}Now: ${red} Treci la Traeba!"
            fi


        elif [[ "$1" = "bookings" ]] || [[ "$1" = "today" ]]; then

            BOOKINGS_COUNTER=0
            WORKBOOK_REGISTERED_HOURS=0

            echo "${reset}You have ${green}$NUM_OF_BOOKINGS ${reset}booking(s) for ${green}$DATE_MESSAGE."

            while [  $BOOKINGS_COUNTER -lt $NUM_OF_BOOKINGS ]; do

                CURRENT_TASK_BOOKING=$( echo $FILTER_RESPONSE_DETAILS | jq  " .[${BOOKINGS_COUNTER}]" )

                WORKBOOK_TASK_ID=$( echo $CURRENT_TASK_BOOKING | jq -j '.TaskId')


                WORKBOOK_REGISTERED_HOURS=$( echo $REGISTERED_TASKS | tr '\r\n' ' ' | jq -j '[.[] | select(.TaskId == '$WORKBOOK_TASK_ID') | .Hours ] | add // 0' )

                WORKBOOK_TASK_DATA=$( curl -s "https://workbook.magnetix.dk/api/task/${WORKBOOK_TASK_ID}/visualization" \
                    -H "Accept: application/json, text/plain, */*" \
                    -H "Content-Type: application/json" \
                    -H "Cookie: ${COOKIE}" )

                echo ""
                echo "${reset}Client: ${green}$( echo $WORKBOOK_TASK_DATA | jq -j '.JobName')"
                echo "${reset}Hours booked: ${green}$( echo $CURRENT_TASK_BOOKING | jq -j '.Hours')"
                echo "${reset}Hours registered: ${green}$WORKBOOK_REGISTERED_HOURS"
                echo "${reset}Taskname: ${green}$( echo $WORKBOOK_TASK_DATA | jq -j '.TaskName')"

                let BOOKINGS_COUNTER=BOOKINGS_COUNTER+1
            done

        elif [[ "$1" = "search" ]] || [[ "$1" = "manual" ]] ; then

            ALL_DATA=$( curl -s "https://workbook.magnetix.dk/api/json/reply/TimeEntryAllowedJobsVisualizationCacheRequest?OnlyActiveProjects=true&Date=${DATE}" \
                -H "Accept: application/json, text/plain, */*" \
                -H "Content-Type: application/json" \
                -H "Cookie: ${COOKIE}"
            )
            echo -n "${reset}Enter client and press [ENTER]: "
            read SEARCH_CLIENT
            ALL_JOBS=$( echo $ALL_DATA | jq '[.[]  | {"JobName": .JobName, "ProjectName": .ProjectName, "CustomerName": .CustomerName, "Id": .Id} ]' )
            MATCHING_JOBS=$( echo $ALL_JOBS | jq '[.[] | if .CustomerName|test("'$SEARCH_CLIENT'"; "i")  then ( {"JobName": .JobName, "ProjectName": .ProjectName, "CustomerName": .CustomerName, "Id": .Id} ) else empty end ]')
            MATCHING_JOBS_LENGTH=$( echo $MATCHING_JOBS | jq length)


            if [[ $MATCHING_JOBS_LENGTH = "0" ]]; then
                echo "${red}Didn't find a matching client."
                echo "${reset}Try again"
                return
            fi

            echo "${reset}Found ${green}$MATCHING_JOBS_LENGTH${reset} job(s) matching the client"
            echo ""

            MATCHING_JOBS_COUNTER=0
            while [ $MATCHING_JOBS_COUNTER -lt $MATCHING_JOBS_LENGTH ]; do
                echo "${blue}$MATCHING_JOBS_COUNTER: ${reset}Client: ${green}$( echo $MATCHING_JOBS | jq ".[$MATCHING_JOBS_COUNTER] | .CustomerName" ) ${reset}Job: ${green}$( echo $MATCHING_JOBS | jq ".[$MATCHING_JOBS_COUNTER] | .JobName" )"
                echo ""
                let MATCHING_JOBS_COUNTER=MATCHING_JOBS_COUNTER+1
            done

            echo -n "${reset}Choose the correct job index and press [ENTER]: "
            read USER_CLIENT
            USER_JOB_ID=$( echo $MATCHING_JOBS | jq ".[$USER_CLIENT] | .Id" )

            MATCHING_TASKS=$( curl -s "https://workbook.magnetix.dk/api/json/reply/TasksTimeRegistrationRequest?JobId=${USER_JOB_ID}&ResourceId=${WORKBOOK_USER_ID}" \
                -H "Accept: application/json, text/plain, */*" \
                -H "Content-Type: application/json" \
                -H "Cookie: ${COOKIE}" )

            MATCHING_TASKS_LENGTH=$( echo $MATCHING_TASKS | jq length)

            if [[ $MATCHING_TASKS_LENGTH = "0" ]]; then
                echo "${red}The job you selected doesn't have an assigned task."
                echo "${reset}Exiting"
                return
            fi

            MATCHING_TASKS_COUNTER=0
            while [ $MATCHING_TASKS_COUNTER -lt $MATCHING_TASKS_LENGTH ]; do
                echo "${blue}$MATCHING_TASKS_COUNTER: ${reset}Task: ${green}$( echo $MATCHING_TASKS | jq ".[$MATCHING_TASKS_COUNTER] | .TaskName" )"
                let MATCHING_TASKS_COUNTER=MATCHING_TASKS_COUNTER+1
            done

            echo -n "${reset}Choose the correct task and press [ENTER]: "
            read USER_TASK

            WORKBOOK_TASK_ID=$( echo $MATCHING_TASKS | jq ".[$USER_TASK] | .Id" )

            echo -n "${reset}Enter amount of desired hours and press [ENTER]: "
            read USER_HOURS

            echo -n "${reset}Enter description for the registration and press [ENTER]: "
            read USER_DESCRIPTION

            echo "${reset}Sending registration to workbook"

            REGISTER_TIME_REQUEST=$( curl -s "https://workbook.magnetix.dk/api/personalexpense/timeentry/week" \
                -H "Accept: application/json, text/plain, */*" \
                -H "Content-Type: application/json" \
                -H "Cookie: ${COOKIE}" \
                -X "POST" \
                -d '{"ResourceId":'$WORKBOOK_USER_ID',"TaskId":'$WORKBOOK_TASK_ID',"Hours":'$USER_HOURS',"Description":"'"$USER_DESCRIPTION"'", "Date":'$DATE'T00:00:00.000Z}' )
        fi

    else
        echo "${reset}Usage commands:"
        echo ""
        echo "${green}wb reg|register               ${reset}Register to workbook"
        echo "${green}wb reg|register <yyyy-mm-dd>  ${reset}Register for given date"
        echo "${green}wb reg|register <-int|int>    ${reset}Register for +/- amount of days."
        echo "                              ${blue}Example: wb reg -1 -> Register for yesterday"
        echo ""
        echo "${green}wb bookings                   ${reset}Get bookings overview for today"
        echo "${green}wb bookings <yyyy-mm-dd>      ${reset}Get bookings overview for given date"
        echo "${green}wb bookings <-int|int>        ${reset}Get bookings overview +/- amount of days"
        echo "                              ${blue}Example: wb bookings +1 -> Get bookings for tomorrow"
        echo ""
        echo "${green}wb search|manual              ${reset}Register to workbook manually"
        echo "${green}wb search|manual <yyyy-mm-dd> ${reset}Register to workbook manually for given date"
        echo "${green}wb search|manual <-int|int>   ${reset}Register to workbook manually +/- amount of days"
    fi
}
