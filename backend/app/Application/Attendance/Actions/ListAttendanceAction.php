<?php

declare(strict_types=1);

namespace App\Application\Attendance\Actions;

use App\Application\Attendance\AttendanceDayBuilder;
use App\Application\Attendance\DTOs\ListAttendanceData;
use App\Domain\Entities\AttendanceDay;
use App\Domain\Enums\UserRole;
use App\Domain\Shared\PaginatedResult;
use App\Models\User;

final class ListAttendanceAction
{
    public function __construct(
        private readonly AttendanceDayBuilder $days,
    ) {}

    /**
     * @return array{page: PaginatedResult<AttendanceDay>, totals: array{days_present: int, days_absent: int, total_on_site_hours: float}}
     */
    public function execute(ListAttendanceData $data): array
    {
        [$start, $end] = $this->days->range($data);
        $drivers = User::query()
            ->where('role', UserRole::Driver)
            ->when(
                $data->driverId !== null,
                fn ($query) => $query->whereKey($data->driverId),
            )
            ->orderBy('name_en')
            ->get();

        $built = $this->days->build($drivers, $start, $end, $data->status);
        $offset = max(0, ($data->page - 1) * $data->perPage);

        return [
            'page' => new PaginatedResult(
                items: array_values(array_slice($built, $offset, $data->perPage)),
                total: count($built),
                page: $data->page,
                perPage: $data->perPage,
            ),
            'totals' => $this->days->totals($built),
        ];
    }
}
