<?php

declare(strict_types=1);

namespace App\Domain\Reports;

use DateTimeImmutable;

/** One completed trip reduced to the fields the movement sheet prints. */
final readonly class MovementTripStop
{
    /**
     * @param  list<string>  $fromNames
     * @param  list<string>  $toNames
     */
    public function __construct(
        public ?DateTimeImmutable $startedAt,
        public ?DateTimeImmutable $finishedAt,
        public array $fromNames,
        public array $toNames,
    ) {}

    public function anchor(): ?DateTimeImmutable
    {
        return $this->startedAt ?? $this->finishedAt;
    }
}
