<?php

declare(strict_types=1);

return [

    /*
    |--------------------------------------------------------------------------
    | FCM service account
    |--------------------------------------------------------------------------
    |
    | Path to the Firebase service account JSON used for FCM HTTP v1.
    | Relative paths are resolved from the backend directory. An empty value
    | or a missing file skips push delivery.
    |
    */

    'credentials' => env('FIREBASE_CREDENTIALS'),

];
