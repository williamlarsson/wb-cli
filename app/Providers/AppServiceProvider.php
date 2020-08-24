<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot()
    {
        //
    }

    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        //
    }

    /**
     * Create authentication to workbook and return cookie
     *
     * @return string
     */
    protected function connectToWorkbook() {

        // $DATE = date("Y/m/d");

        // $ACCESS_TOKEN = env("ACCESS_TOKEN");
        // $ACCOUNT_ID = env("ACCOUNT_ID");
        // $headers = [
        //     "Authorization: Bearer $ACCESS_TOKEN",
        //     "Harvest-Account-Id: $ACCOUNT_ID",
        //     "User-Agent: williamlarsson@live.dk"
        // ];
        // $curl = curl_init();
        // curl_setopt($curl, CURLOPT_URL,"https://api.harvestapp.com/v2/time_entries");
        // curl_setopt($curl, CURLOPT_HTTPHEADER, $headers);
        // curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);

        // $server_output = curl_exec ($ch);

        // $json = json_decode($server_output);
        // curl_close ($ch);
        // return $json;
    }
}
