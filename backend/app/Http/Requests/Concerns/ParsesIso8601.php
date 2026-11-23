<?php

declare(strict_types=1);

namespace App\Http\Requests\Concerns;

use DateTimeImmutable;
use DateTimeInterface;

trait ParsesIso8601
{
    protected function parseOptionalDateTime(?string $value): ?DateTimeImmutable
    {
        if ($value === null || $value === '') {
            return null;
        }

        $parsed = DateTimeImmutable::createFromFormat(DateTimeInterface::ATOM, $value)
            ?: DateTimeImmutable::createFromFormat('Y-m-d\TH:i:sP', $value)
            ?: new DateTimeImmutable($value);

        return $parsed->setTimezone(new \DateTimeZone('UTC'));
    }
}
