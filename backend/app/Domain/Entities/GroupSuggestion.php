<?php

declare(strict_types=1);

namespace App\Domain\Entities;

use DateTimeImmutable;

final readonly class GroupSuggestion
{
    /**
     * @param  list<string>  $requestIds
     * @param  list<GroupSuggestionMember>  $members
     */
    public function __construct(
        public string $clusterId,
        public array $requestIds,
        public string $destinationLabel,
        public string $routeLabel,
        public string $date,
        public DateTimeImmutable $earliestRequestedAt,
        public DateTimeImmutable $latestRequestedAt,
        public array $members = [],
    ) {}
}
