<?php

namespace App\Commands;

use Illuminate\Console\Scheduling\Schedule;
use LaravelZero\Framework\Commands\Command;
// use LaravelZero\Framework\Providers\AppServiceProviders;

class Bookings extends Command
{
    /**
     * The signature of the command.
     *
     * @var string
     */
    protected $signature = 'bookings';

    /**
     * The description of the command.
     *
     * @var string
     */
    protected $description = "Show bookings for given date";


    /**
     * Connect to
     *
     * @return string
     */
    protected function CURL($url, $headers, $params, $post) {
        $curl = curl_init();

        curl_setopt($curl, CURLOPT_URL, $url);
        curl_setopt($curl, CURLOPT_POST, $post);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $params);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_HTTPHEADER, $headers);
        // if ( $headers) {
        // }

        $server_output = curl_exec ($curl);

        $json = json_decode($server_output);
        $this->info( $server_output );
        curl_close ($curl);
        return $json;
    }

    /**
     * Connect to
     *
     * @return void
     */
    protected function connectToWorkbook() {

        // $DATE = date("Y/m/d");

        $WORKBOOK_USERNAME = env("WORKBOOK_USERNAME");
        $WORKBOOK_PASSWORD = env("WORKBOOK_PASSWORD");

        $this->info("Establishing authentication to workbook...");

        $WB_AUTH_PARAMS = [
            "UserName: $WORKBOOK_USERNAME",
            "Password : $WORKBOOK_PASSWORD",
            "RememberMe: true "
        ];
        $WB_AUTH_HEADERS = [
            'Content-Type: application/json'
        ];
        $WB_AUTH_WITHOUT_HEADERS = $this->CURL("https://wbapp.magnetix.dk/api/auth/ldap", $WB_AUTH_HEADERS, $WB_AUTH_PARAMS, true);
        // $this->info($WB_AUTH_WITHOUT_HEADERS);
        return;

        // AUTH_WITHOUT_HEADERS=$(curl -s "https://wbapp.magnetix.dk/api/auth/ldap" \
        //     -H "Content-Type: application/json" \
        //     -X "POST" \
        //     -d '{"UserName":"'"$WORKBOOK_USERNAME"'","Password":"'"$WORKBOOK_PASSWORD"'", "RememberMe": true}')

        // if [[ $WORKBOOK_RESOURCE_ID ]]; then
        //     WORKBOOK_USER_ID=$WORKBOOK_RESOURCE_ID
        // else
        //     WORKBOOK_USER_ID=$( echo $AUTH_WITHOUT_HEADERS | tr '\r\n' ' ' |  jq '.Id' )
        // fi

        // AUTH_WITH_HEADERS=$(curl -i -s "https://wbapp.magnetix.dk/api/auth/ldap" \
        //     -H "Content-Type: application/json" \
        //     -X "POST" \
        //     -d '{"UserName":"'"$WORKBOOK_USERNAME"'","Password":"'"$WORKBOOK_PASSWORD"'", "RememberMe": true}')


        // if [[ $AUTH_WITH_HEADERS =~ "ss-pid=(.{20})" ]]; then
        //     SS_PID=${match[1]}
        // elif [[ $AUTH_WITH_HEADERS =~ ss-pid=(.{20}) ]]; then
        //     SS_PID=${BASH_REMATCH[1]}
        // else
        //     echo "Couldn't authenticate"
        //     return;
        // fi

        // if [[ $AUTH_WITH_HEADERS =~ "ss-id=(.{20})" ]]; then
        //     SS_ID=${match[1]}
        // elif [[ $AUTH_WITH_HEADERS =~ ss-id=(.{20}) ]]; then
        //     SS_ID=${BASH_REMATCH[1]}
        // else
        //     echo "Couldn't authenticate"
        //     return;
        // fi
        // $ch = curl_init();
        // curl_setopt($ch, CURLOPT_URL,"https://api.harvestapp.com/v2/time_entries");
        // // curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        // $ACCESS_TOKEN = env("ACCESS_TOKEN");
        // $ACCOUNT_ID = env("ACCOUNT_ID");

        // $headers = [
        //     'Authorization: 1745324.pt.tNGe8DDZCUF-0LPJp2wn6Bmpe8qS7p-vb5sCdnY0zyz71wrty6Tyxt3jzzktpodqkwGgftBp6KnjQ9zd7M6ejA',
        //     'Harvest-Account-Id: 1003438',
        //     'Content-Type: application/json',
        // ];


        // curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

        // $server_output = curl_exec ($ch);

        // $json = json_decode($server_output);
        // curl_close ($ch);
        // $this->info($json);
        // print  $server_output ;

    }

    /**
     * Execute the console command.
     *
     * @return mixed
     */
    public function handle()
    {
        $this->connectToWorkbook();
    }

    /**
     * Define the command's schedule.
     *
     * @param  \Illuminate\Console\Scheduling\Schedule $schedule
     * @return void
     */
    public function schedule(Schedule $schedule): void
    {
        // $schedule->command(static::class)->everyMinute();
    }

}
