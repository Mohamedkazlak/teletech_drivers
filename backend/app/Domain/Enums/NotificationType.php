<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum NotificationType: string
{
    case RequestSubmitted = 'request_submitted';
    case TripReadyToAssign = 'trip_ready_to_assign';
    case TripAssigned = 'trip_assigned';
    case OwnTripAssigned = 'own_trip_assigned';
    case TripEndedReportNeeded = 'trip_ended_report_needed';

    public function titleKey(): string
    {
        return 'notifications.'.$this->value.'.title';
    }

    public function bodyKey(): string
    {
        return 'notifications.'.$this->value.'.body';
    }
}
