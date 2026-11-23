<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\AdminDashboard;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AdminDashboard
 */
final class AdminDashboardResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var AdminDashboard $dashboard */
        $dashboard = $this->resource;

        return [
            'drivers' => [
                'total' => $dashboard->driversTotal,
                'checked_in' => $dashboard->driversCheckedIn,
                'checked_out' => $dashboard->driversCheckedOut,
                'absent' => $dashboard->driversAbsent,
            ],
            'employees_total' => $dashboard->employeesTotal,
            'places_total' => $dashboard->placesTotal,
            'trips' => [
                'unassigned' => $dashboard->tripsUnassigned,
                'assigned' => $dashboard->tripsAssigned,
                'in_progress' => $dashboard->tripsInProgress,
                'completed_today' => $dashboard->tripsCompletedToday,
                'completed_this_week' => $dashboard->tripsCompletedThisWeek,
            ],
            'requests' => [
                'pending' => $dashboard->requestsPending,
                'approved' => $dashboard->requestsApproved,
                'rejected' => $dashboard->requestsRejected,
            ],
            'unconfirmed_trips' => $dashboard->unconfirmedTrips,
        ];
    }
}
