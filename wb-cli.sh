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

function summary() {

    echo ""
    echo "${blue}Summary of registrations for ${green}${DATE_MESSAGE}:${reset}"

    TIME_ENTRY_DAILY_REQUEST=$( curl -s "https://workbook.magnetix.dk/api/json/reply/TimeEntryDailyRequest?ResourceIds=${WORKBOOK_USER_ID}&Date=${DATE}" \
        -H "Accept: application/json, text/plain, */*" \
        -H "Content-Type: application/json" \
        -H "Cookie: ${COOKIE}"   )

    REGISTERED_TASKS_DATA=$( echo $TIME_ENTRY_DAILY_REQUEST | jq '[.[] | select(.Hours > 0 )]' )
    REGISTERED_TASKS_LENGTH=$( echo $REGISTERED_TASKS_DATA | jq length )

    REGISTRATIONS_COUNTER=0
    while [ $REGISTRATIONS_COUNTER -lt $REGISTERED_TASKS_LENGTH ]; do

        CURRENT_REGISTRATION=$( echo $REGISTERED_TASKS_DATA | jq  " .[${REGISTRATIONS_COUNTER}]" )

        WORKBOOK_TASK_ID=$( echo $CURRENT_REGISTRATION | jq -j '.TaskId')

        WORKBOOK_TASK_DATA=$( curl -s "https://workbook.magnetix.dk/api/task/${WORKBOOK_TASK_ID}/visualization" \
            -H "Accept: application/json, text/plain, */*" \
            -H "Content-Type: application/json" \
            -H "Cookie: ${COOKIE}" )

        echo ""
        echo "${reset}Client: ${green}$( echo $WORKBOOK_TASK_DATA | jq -j '.JobName')"
        echo "${reset}Hours registered: ${green}$( echo $CURRENT_REGISTRATION | jq -j '.Hours')"
        echo "${reset}Taskname: ${green}$( echo $WORKBOOK_TASK_DATA | jq -j '.TaskName')"
        echo "${reset}Description: ${green}$( echo $CURRENT_REGISTRATION | jq -j '.Description')"

        let REGISTRATIONS_COUNTER=REGISTRATIONS_COUNTER+1
    done
    REGISTERED_TASKS_HOURS_TOTAL=$( echo $REGISTERED_TASKS_DATA | tr '\r\n' ' ' | jq -j '[.[] | .Hours ] | add // 0' )

    #SUMMARIZE
    echo ""
    if [[ "$WEEKDAY" == "5" ]]; then
        MAX_HOURS=7
    else
        MAX_HOURS=7.5
    fi

    if [[ "$REGISTERED_TASKS_HOURS_TOTAL" == "0"  ]]; then
        echo "${reset}Nothing was registered"
    else
        echo "${reset}Hours booked : ${green}$MAX_HOURS"
        echo "${reset}Hours registered: ${green}$REGISTERED_TASKS_HOURS_TOTAL"

        if [[ $( jq -n "$REGISTERED_TASKS_HOURS_TOTAL>$MAX_HOURS" ) == "true" ]]; then

            echo "${red}Heads up. You have overbooked with ${green}$( jq -n "$REGISTERED_TASKS_HOURS_TOTAL-$MAX_HOURS" )${red} hours. "
            echo "${reset}Run the register again to update, or visit workbook manually to correct this."
            SOUND_FILE="/System/Library/Sounds/Sosumi.aiff"
            if test -f "$SOUND_FILE"; then
                afplay $SOUND_FILE
            fi

        elif [[ $( jq -n "$REGISTERED_TASKS_HOURS_TOTAL<$MAX_HOURS" ) == "true" ]]; then
            echo "${red}Heads up. You have underbooked with ${green}$( jq -n "$MAX_HOURS-$REGISTERED_TASKS_HOURS_TOTAL" )${red} hours. "
            echo "${reset}Run the register again to update, or visit workbook manually to correct this."
            SOUND_FILE="/System/Library/Sounds/Sosumi.aiff"
            if test -f "$SOUND_FILE"; then
                afplay $SOUND_FILE
            fi
        else
            # echo "${green}Done"
            # echo "${reset}Now: ${red} Treci la Traeba!"
            SOUND_FILE="/System/Library/Sounds/Glass.aiff"
            if test -f "$SOUND_FILE"; then
                afplay $SOUND_FILE
            fi
        fi
    fi
}

function bookings() {
     FILTER_RESPONSE=$( curl -s "https://workbook.magnetix.dk/api/schedule/weekly/visualization/data?ResourceIds=${WORKBOOK_USER_ID}&PeriodType=1&Date=${DATE}&Interval=1" \
        -H "Accept: application/json, text/plain, */*" \
        -H "Content-Type: application/json" \
        -H "Cookie: ${COOKIE}" \
        -X "POST" \
        -d '{}' )

    FILTER_RESPONSE_DETAILS=$( echo $FILTER_RESPONSE | jq '.[] | .Data | ."0" | .Details ')

    NUM_OF_BOOKINGS=$( echo $FILTER_RESPONSE_DETAILS | jq length)
    BOOKINGS_COUNTER=0
    WORKBOOK_REGISTERED_HOURS=0

    echo ""
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
}

function wb () {
    magenta=`tput setaf 5`
    blue=`tput setaf 4`
    red=`tput setaf 1`
    green=`tput setaf 2`
    reset="$(tput sgr0)"

    if [[ "$1" = "reg" ]] || [[ "$1" = "bookings" ]] || [[ "$1" = "manual" ]] || [[ "$1" = "summary" ]]; then

        echo "${reset}Establishing authentication to workbook..."

        unset END_DATE
        unset START_DATE
        # (-?\+?\d)\.{2,3}(-?\+?\d+)
        REGEXP="(-?\+?[[:digit:]]+)\.+(-?\+?[[:digit:]]+)"

        if [[ $2 =~ $REGEXP ]]; then

            START_DATE_INT=${BASH_REMATCH[1]}
            START_CALCULATED_UNIX_DATE=$(( $( date +"%s" ) + $(( $START_DATE_INT * 86400 )) ))
            START_DATE=$( date -r $START_CALCULATED_UNIX_DATE +'%Y%m%d' )
            START_WEEKDAY=$( date -r $START_CALCULATED_UNIX_DATE +'%u' )
            START_DATE_MESSAGE="$DATE"

            DATE="$START_DATE"
            DATE_MESSAGE="$START_DATE_MESSAGE"

            END_DATE_INT=${BASH_REMATCH[2]}
            END_CALCULATED_UNIX_DATE=$(( $( date +"%s" ) + $(( $END_DATE_INT * 86400 )) ))
            END_DATE=$( date -r $END_CALCULATED_UNIX_DATE +'%Y%m%d' )
            END_WEEKDAY=$( date -r $END_CALCULATED_UNIX_DATE +'%u' )
            END_DATE_MESSAGE="$END_DATE"

        elif [[ $(( ${#2} >= 1 )) == 1 && $(( ${#2} <= 3 )) == 1  ]]; then
            # SET DATE BY DAYS SPAN
            CALCULATED_UNIX_DATE=$(( $( date +"%s" ) + $(( $2 * 86400 )) ))
            DATE=$( date -r $CALCULATED_UNIX_DATE +'%Y%m%d' )
            START_WEEKDAY=$( date -r $CALCULATED_UNIX_DATE +'%u' )
            DATE_MESSAGE="$DATE"
        else
            # SET DATE BY FORMAT YYYY-MM-DD
            DATE=${2:-$(date +'%Y-%m-%d')}
            START_WEEKDAY=${2:-$(date +'%u')}
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

        if [[ -z $START_DATE ]]; then

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
        fi


        if [[ "$1" = "reg" ]]; then

            TOTAL_HOURS_BOOKED=0
            TOTAL_HOURS_REGISTERED=0

            echo "${reset}You have ${green}$NUM_OF_BOOKINGS ${reset}booking(s) for ${green}$DATE_MESSAGE."

            BOOKINGS_COUNTER=0
            while [ $BOOKINGS_COUNTER -lt $NUM_OF_BOOKINGS ]; do

                CURRENT_TASK_BOOKING=$( echo $FILTER_RESPONSE_DETAILS | jq  " .[${BOOKINGS_COUNTER}]" )

                wbRegister "$CURRENT_TASK_BOOKING"
                let BOOKINGS_COUNTER=BOOKINGS_COUNTER+1
            done

            # SUMMARIZE
            summary

        elif [[ "$1" = "manual" ]] ; then

            ALL_DATA=$( curl -s "https://workbook.magnetix.dk/api/json/reply/TimeEntryAllowedJobsVisualizationCacheRequest?OnlyActiveProjects=true&Date=${DATE}" \
                -H "Accept: application/json, text/plain, */*" \
                -H "Content-Type: application/json" \
                -H "Cookie: ${COOKIE}" )

            echo -n "${reset}Enter client and press [ENTER]: "
            read SEARCH_CLIENT

            ALL_JOBS=$( echo $ALL_DATA | jq '[.[]  | {"JobName": .JobName, "ProjectName": .ProjectName, "CustomerName": .CustomerName, "Id": .Id} ]' )
            MATCHING_JOBS=$( echo $ALL_JOBS | jq '[.[] | if .CustomerName|test("'$SEARCH_CLIENT'"; "i")  then ( {"JobName": .JobName, "ProjectName": .ProjectName, "CustomerName": .CustomerName, "Id": .Id} ) else empty end ]')
            MATCHING_JOBS=$( echo $MATCHING_JOBS | jq 'sort_by(.CustomerName)' )
            MATCHING_JOBS_LENGTH=$( echo $MATCHING_JOBS | jq length)
            MATCHING_CLIENTS=$( echo $MATCHING_JOBS | jq '[.[] | .CustomerName]|unique' )
            MATCHING_CLIENTS_LENGTH=$( echo $MATCHING_CLIENTS | jq length)

            if [[ $MATCHING_JOBS_LENGTH = "0" ]]; then
                echo "${red}Didn't find a matching client."
                echo "${reset}Try again"
                return
            fi


            if [[ $MATCHING_CLIENTS_LENGTH > 1 ]]; then
                echo "${reset}Found ${green}$MATCHING_CLIENTS_LENGTH${reset} client(s) with ${green}$MATCHING_JOBS_LENGTH ${reset}job(s) matching your input"
                echo ""
            fi

            MATCHING_CLIENTS_COUNTER=0
            MATCHING_JOBS_COUNTER=0
            while [ $MATCHING_CLIENTS_COUNTER -lt $MATCHING_CLIENTS_LENGTH ]; do
                LOCAL_MATCHING_CLIENT=$( echo $MATCHING_CLIENTS | jq .[$MATCHING_CLIENTS_COUNTER] )
                LOCAL_MATCHING_JOBS=$( echo $MATCHING_JOBS | jq "[.[] | select(.CustomerName == $LOCAL_MATCHING_CLIENT) ]")
                LOCAL_MATCHING_JOBS_LENGTH=$( echo $LOCAL_MATCHING_JOBS | jq length )
                echo "${reset}Found ${green}$LOCAL_MATCHING_JOBS_LENGTH${reset} job(s) matching client: ${blue} $LOCAL_MATCHING_CLIENT"
                echo ""
                let MATCHING_CLIENTS_COUNTER=MATCHING_CLIENTS_COUNTER+1

                LOCAL_MATCHING_JOBS_COUNTER=0
                while [ $LOCAL_MATCHING_JOBS_COUNTER -lt $LOCAL_MATCHING_JOBS_LENGTH ]; do
                    echo "${blue}$(( $MATCHING_JOBS_COUNTER + 1 )): ${reset}Job: ${green}$( echo $MATCHING_JOBS | jq ".[$MATCHING_JOBS_COUNTER] | .JobName" )"
                    echo ""
                    let LOCAL_MATCHING_JOBS_COUNTER=LOCAL_MATCHING_JOBS_COUNTER+1
                    let MATCHING_JOBS_COUNTER=MATCHING_JOBS_COUNTER+1
                done

            done


            echo -n "${reset}Choose the correct job index and press [ENTER]: "
            read USER_JOB
            USER_JOB=$(( $USER_JOB - 1 ))
            USER_JOB_ID=$( echo $MATCHING_JOBS | jq ".[$USER_JOB] | .Id" )

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
                echo "${blue}$(( $MATCHING_TASKS_COUNTER + 1 )): ${reset}Task: ${green}$( echo $MATCHING_TASKS | jq ".[$MATCHING_TASKS_COUNTER] | .TaskName" )"
                let MATCHING_TASKS_COUNTER=MATCHING_TASKS_COUNTER+1
            done

            echo -n "${reset}Choose the correct task and press [ENTER]: "
            read USER_TASK
            USER_TASK=$(( $USER_TASK - 1 ))
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
            # SUMMARIZE
            summary

        elif [[ "$1" = "bookings" ]] || [[ "$1" = "summary" ]]; then

            if [[ -z $START_DATE ]]; then
                [[ "$1" = "bookings" ]] && bookings || summary
            else
                DATE_TODAY=$( date +'%Y%m%d')
                DATE="$START_DATE"
                DATE_COUNTER=$START_DATE_INT
                [[ $(( $END_DATE - $START_DATE )) > 0 ]] && DATE_DIRECTION=+ || DATE_DIRECTION=-

                while [  $DATE -ne $END_DATE ]; do
                    [[ $(( $DATE - $DATE_TODAY )) < 0 ]] && DATE_OPERATOR=- || DATE_OPERATOR=+
                    [[ $DATE_COUNTER -ne 0 ]] && DATE=$( date -v "${DATE_OPERATOR}${DATE_COUNTER#-}d" +'%Y%m%d') || DATE=$( date +'%Y%m%d')
                    DATE_MESSAGE="$( date -v "${DATE_OPERATOR}${DATE_COUNTER#-}d" +'%A %d/%m' )"

                    [[ "$1" = "bookings" ]] && bookings || summary

                let DATE_COUNTER=$(( $DATE_COUNTER $DATE_DIRECTION 1 ))
                done
            fi

            SOUND_FILE="/System/Library/Sounds/Bottle.aiff"
            if test -f "$SOUND_FILE"; then
                afplay $SOUND_FILE
            fi
        fi

    else
        echo "${reset}Usage commands:"
        echo ""
        echo "${green}wb reg                        ${reset}Register to workbook"
        echo "${green}wb reg <yyyy-mm-dd>           ${reset}Register for given date"
        echo "${green}wb reg <-int|int>             ${reset}Register for +/- amount of days."
        echo "                              ${blue}Example: wb reg -1 //Register for yesterday"
        echo ""
        echo "${green}wb manual                     ${reset}Register to workbook manually"
        echo "${green}wb manual <yyyy-mm-dd>        ${reset}Register to workbook manually for given date"
        echo "${green}wb manual <-int|int>          ${reset}Register to workbook manually +/- amount of days"
        echo "                              ${blue}Example: wb manual //Register to workbook manually for today"
        echo ""
        echo "${green}wb bookings                   ${reset}Get bookings summary for today"
        echo "${green}wb bookings <yyyy-mm-dd>      ${reset}Get bookings summary for given date"
        echo "${green}wb bookings <-int|int>        ${reset}Get bookings summary +/- amount of days"

        echo "                              ${blue}Example: wb bookings +1 //Get bookings for tomorrow"
        echo ""
        echo "${green}wb summary                    ${reset}Get registrations summary for today"
        echo "${green}wb summary <yyyy-mm-dd>       ${reset}Get registrations summary for given date"
        echo "${green}wb summary <-int|int>         ${reset}Get registrations summary +/- amount of days"
        echo "                              ${blue}Example: wb summary 2020-01-01 //Get summary for given date"
    fi
}
