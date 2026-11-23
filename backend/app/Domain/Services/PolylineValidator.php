<?php

declare(strict_types=1);

namespace App\Domain\Services;

/**
 * Validates Google Encoded Polyline Algorithm Format strings (precision 5).
 * Charset: ASCII code units in [63, 126] (algorithm writes char = chunk + 63).
 */
final class PolylineValidator
{
    public function __construct(
        private readonly int $maxLength,
    ) {}

    public static function fromConfig(): self
    {
        return new self((int) config('teletech.polyline_max_length', 100_000));
    }

    public function isValid(string $encoded): bool
    {
        if (strlen($encoded) > $this->maxLength) {
            return false;
        }

        $length = strlen($encoded);
        for ($i = 0; $i < $length; $i++) {
            $code = ord($encoded[$i]);
            if ($code < 63 || $code > 126) {
                return false;
            }
        }

        return true;
    }

    public function maxLength(): int
    {
        return $this->maxLength;
    }
}
