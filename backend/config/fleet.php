<?php

declare(strict_types=1);

return [
    /*
    | Week start for period=week filters. English weekday name.
    | Fleet calendars start on Saturday.
    */
    'week_starts_on' => env('FLEET_WEEK_STARTS_ON', 'Saturday'),
];
