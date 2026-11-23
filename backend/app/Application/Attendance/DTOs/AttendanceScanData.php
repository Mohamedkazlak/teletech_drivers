<?php

declare(strict_types=1);

namespace App\Application\Attendance\DTOs;

final readonly class AttendanceScanData
{
    public function __construct(
        public string $driverId,
        public string $qrPayload,
        public float $lat,
        public float $lng,
        public float $accuracyM,
        public bool $isMocked,
    ) {}
}
