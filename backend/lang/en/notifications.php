<?php

declare(strict_types=1);

return [
    'request_submitted' => [
        'title' => 'New trip request',
        'body' => ':requester requested a trip from :pickup to :destination.',
    ],
    'trip_ready_to_assign' => [
        'title' => 'Trip ready to assign',
        'body' => ':requester is waiting for a driver on the trip from :pickup to :destination.',
    ],
    'trip_assigned' => [
        'title' => 'Driver assigned',
        'body' => ':driver is assigned to the trip from :pickup to :destination.',
    ],
    'own_trip_assigned' => [
        'title' => 'Driver assigned to your trip',
        'body' => ':driver is assigned to your trip from :pickup to :destination.',
    ],
    'trip_ended_report_needed' => [
        'title' => 'Trip ended',
        'body' => 'Your trip from :pickup to :destination has ended. Please submit the report.',
    ],
];
