<?php

declare(strict_types=1);

return [
    'request_submitted' => [
        'title' => 'طلب رحلة جديد',
        'body' => 'طلب :requester رحلة من :pickup إلى :destination.',
    ],
    'trip_ready_to_assign' => [
        'title' => 'رحلة جاهزة للتعيين',
        'body' => ':requester بانتظار سائق للرحلة من :pickup إلى :destination.',
    ],
    'trip_assigned' => [
        'title' => 'تم تعيين السائق',
        'body' => 'تم تعيين :driver للرحلة من :pickup إلى :destination.',
    ],
    'own_trip_assigned' => [
        'title' => 'تم تعيين سائق لرحلتك',
        'body' => 'تم تعيين :driver لرحلتك من :pickup إلى :destination.',
    ],
    'trip_ended_report_needed' => [
        'title' => 'انتهت الرحلة',
        'body' => 'انتهت رحلتك من :pickup إلى :destination. يرجى تقديم التقرير.',
    ],
];
