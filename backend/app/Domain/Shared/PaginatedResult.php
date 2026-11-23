<?php

declare(strict_types=1);

namespace App\Domain\Shared;

/**
 * @template T
 */
final readonly class PaginatedResult
{
    /**
     * @param  list<T>  $items
     */
    public function __construct(
        public array $items,
        public int $total,
        public int $page,
        public int $perPage,
    ) {}

    public function lastPage(): int
    {
        if ($this->perPage <= 0) {
            return 0;
        }

        return (int) max(1, (int) ceil($this->total / $this->perPage));
    }
}
