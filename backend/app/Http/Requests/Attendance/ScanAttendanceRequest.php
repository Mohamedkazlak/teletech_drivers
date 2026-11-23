<?php

declare(strict_types=1);

namespace App\Http\Requests\Attendance;

use App\Application\Attendance\DTOs\AttendanceScanData;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class ScanAttendanceRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'qr_payload' => ['required', 'string', 'max:500'],
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'accuracy_m' => ['required', 'numeric', 'min:0'],
            'is_mocked' => ['required', 'boolean'],
        ];
    }

    public function toDto(): AttendanceScanData
    {
        /** @var User $user */
        $user = $this->user();

        return new AttendanceScanData(
            driverId: (string) $user->id,
            qrPayload: (string) $this->validated('qr_payload'),
            lat: (float) $this->validated('lat'),
            lng: (float) $this->validated('lng'),
            accuracyM: (float) $this->validated('accuracy_m'),
            isMocked: $this->boolean('is_mocked'),
        );
    }
}
