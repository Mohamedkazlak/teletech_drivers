<?php

declare(strict_types=1);

namespace App\Domain\Entities;

final readonly class RequestTrackingDriver
{
    public function __construct(
        public ?string $nameEn,
        public ?string $nameAr,
        public ?string $phone,
    ) {}
}
