<?php

declare(strict_types=1);

namespace App\Domain\Services;

use App\Domain\Exceptions\AttendanceRejectedException;

/**
 * Static headquarters QR. The HMAC covers version|company_headquarters.
 * Changing the version invalidates codes that are already printed.
 */
final class AttendanceQr
{
    public function payload(): string
    {
        $version = $this->version();

        return 'telecars-attendance:v'.$version.':'.$this->signature($version);
    }

    public function assertValid(string $payload): void
    {
        $expected = $this->payload();
        if (! hash_equals($expected, trim($payload))) {
            throw new AttendanceRejectedException(
                'invalid_qr',
                __('messages.attendance_invalid_qr'),
            );
        }
    }

    private function signature(int $version): string
    {
        return hash_hmac('sha256', $version.'|company_headquarters', $this->secret());
    }

    private function version(): int
    {
        return (int) config('attendance.qr_version', 1);
    }

    private function secret(): string
    {
        $configured = config('attendance.qr_secret');
        if (is_string($configured) && $configured !== '') {
            return $configured;
        }

        return hash('sha256', (string) config('app.key').'|attendance-qr');
    }
}
