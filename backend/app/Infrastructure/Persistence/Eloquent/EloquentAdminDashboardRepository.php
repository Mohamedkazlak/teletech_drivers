<?php

declare(strict_types=1);

namespace App\Infrastructure\Persistence\Eloquent;

use App\Domain\Entities\AdminDashboard;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStage;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Repositories\AdminDashboardRepositoryInterface;
use App\Domain\Services\AttendanceClock;
use App\Domain\Services\FleetPeriodRange;
use App\Models\AttendanceLog;
use App\Models\Place;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use DateTimeImmutable;
use DateTimeZone;

/**
 * Counts for the system-admin dashboard.
 *
 * Drivers, employees, and places exclude soft-deleted rows and include
 * inactive ones. Checked in, checked out, and absent are today's attendance.
 * On a weekly off day absent is 0. Completed trip windows use
 * finished_at in Africa/Cairo. The week starts Saturday.
 */
final class EloquentAdminDashboardRepository implements AdminDashboardRepositoryInterface
{
    public function __construct(
        private readonly FleetPeriodRange $periods,
        private readonly AttendanceClock $clock,
    ) {}

    public function summarize(): AdminDashboard
    {
        $now = DateTimeImmutable::createFromInterface(now());
        $todayStart = $now->setTimezone($this->periods->timezone())->setTime(0, 0, 0);
        $week = $this->periods->containing('week', null, $now);

        $drivers = User::query()->where('role', UserRole::Driver);
        $attendance = $this->attendanceCounts();

        return new AdminDashboard(
            driversTotal: (clone $drivers)->count(),
            driversCheckedIn: $attendance['checked_in'],
            driversCheckedOut: $attendance['checked_out'],
            driversAbsent: $attendance['absent'],
            employeesTotal: User::query()->where('role', UserRole::Employee)->count(),
            placesTotal: Place::query()->count(),
            tripsUnassigned: $this->countTripsWithStatus(TripStatus::Unassigned),
            tripsAssigned: $this->countTripsWithStatus(TripStatus::Assigned),
            tripsInProgress: Trip::query()->whereIn('status', array_map(
                static fn (TripStatus $status): string => $status->value,
                TripStage::InProgress->statuses(),
            ))->count(),
            tripsCompletedToday: $this->countCompletedBetween($todayStart, $todayStart->modify('+1 day')),
            tripsCompletedThisWeek: $this->countCompletedBetween($week['start'], $week['end_exclusive']),
            requestsPending: $this->countRequests(TripRequestStatus::Pending),
            requestsApproved: $this->countRequests(TripRequestStatus::Approved),
            requestsRejected: $this->countRequests(TripRequestStatus::Rejected),
            unconfirmedTrips: Trip::query()->whereUnconfirmed(true)->count(),
        );
    }

    /**
     * @return array{checked_in: int, checked_out: int, absent: int}
     */
    private function attendanceCounts(): array
    {
        $workDate = $this->clock->today();
        $driverIds = User::query()->where('role', UserRole::Driver)->pluck('id');
        $open = AttendanceLog::query()
            ->whereIn('driver_id', $driverIds)
            ->whereDate('work_date', $workDate)
            ->whereNull('checked_out_at')
            ->count();
        $closed = AttendanceLog::query()
            ->whereIn('driver_id', $driverIds)
            ->whereDate('work_date', $workDate)
            ->whereNotNull('checked_out_at')
            ->count();
        $absent = $this->clock->isWeeklyOff($workDate)
            ? 0
            : $driverIds->count() - $open - $closed;

        return [
            'checked_in' => $open,
            'checked_out' => $closed,
            'absent' => max(0, $absent),
        ];
    }

    private function countTripsWithStatus(TripStatus $status): int
    {
        return Trip::query()->where('status', $status)->count();
    }

    private function countRequests(TripRequestStatus $status): int
    {
        return TripRequest::query()->where('status', $status)->count();
    }

    private function countCompletedBetween(DateTimeImmutable $start, DateTimeImmutable $end): int
    {
        $utc = new DateTimeZone('UTC');

        return Trip::query()
            ->where('status', TripStatus::Completed)
            ->where('finished_at', '>=', $start->setTimezone($utc))
            ->where('finished_at', '<', $end->setTimezone($utc))
            ->count();
    }
}
