<?php

declare(strict_types=1);

namespace App\Application\Attendance\DTOs;

use App\Domain\Enums\AttendanceListStatus;

final readonly class ListAttendanceData
{
    public function __construct(
        public ?string $driverId,
        public ?AttendanceListStatus $status,
        public ?string $date,
        public ?string $period,
        public ?string $periodDate,
        public ?string $dateFrom,
        public ?string $dateTo,
        public int $page = 1,
        public int $perPage = 15,
    ) {}
}
