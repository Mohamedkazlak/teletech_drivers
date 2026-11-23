<?php

declare(strict_types=1);

namespace App\Domain\Reports;

final readonly class DriverMovementDocument
{
    /**
     * @param  list<DriverMovementPage>  $pages
     */
    public function __construct(
        public string $driverName,
        public string $plate,
        public string $project,
        public array $pages,
    ) {}
}
