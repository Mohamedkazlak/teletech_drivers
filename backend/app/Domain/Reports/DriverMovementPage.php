<?php

declare(strict_types=1);

namespace App\Domain\Reports;

final readonly class DriverMovementPage
{
    /**
     * @param  list<DriverMovementRow>  $rows
     */
    public function __construct(
        public string $monthLabel,
        public array $rows,
    ) {}
}
