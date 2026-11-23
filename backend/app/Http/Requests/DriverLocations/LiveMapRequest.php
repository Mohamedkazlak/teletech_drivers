<?php

declare(strict_types=1);

namespace App\Http\Requests\DriverLocations;

use App\Domain\Enums\DriverAttendanceFilter;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class LiveMapRequest extends FormRequest
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
            'driver_id' => ['sometimes', 'nullable', 'uuid'],
            'attendance' => ['sometimes', 'nullable', 'string', Rule::enum(DriverAttendanceFilter::class)],
        ];
    }

    public function driverId(): ?string
    {
        $id = $this->validated('driver_id');

        return is_string($id) && $id !== '' ? $id : null;
    }

    public function attendance(): ?DriverAttendanceFilter
    {
        $attendance = $this->validated('attendance');

        return is_string($attendance) && $attendance !== ''
            ? DriverAttendanceFilter::from($attendance)
            : null;
    }
}
