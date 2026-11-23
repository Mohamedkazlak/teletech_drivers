<?php

declare(strict_types=1);

namespace App\Http\Requests\Attendance;

use App\Application\Attendance\DTOs\ListAttendanceData;
use App\Domain\Enums\AttendanceListStatus;
use App\Http\Requests\Rules\FleetPeriod;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListAttendanceRequest extends FormRequest
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
            'status' => ['sometimes', 'nullable', 'string', Rule::enum(AttendanceListStatus::class)],
            'date' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'date_from' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            'date_to' => ['sometimes', 'nullable', 'date_format:Y-m-d'],
            ...FleetPeriod::rules(),
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(?string $driverId = null): ListAttendanceData
    {
        $status = $this->validated('status');
        $from = $this->validated('date_from');
        $to = $this->validated('date_to');
        $period = $this->validated('period');
        $date = $this->validated('date');

        return new ListAttendanceData(
            driverId: $driverId ?? $this->nullableString('driver_id'),
            status: is_string($status) && $status !== '' ? AttendanceListStatus::from($status) : null,
            date: is_string($date) && $date !== '' ? $date : null,
            period: is_string($period) && $period !== '' ? $period : null,
            periodDate: is_string($date) && $date !== '' ? $date : null,
            dateFrom: is_string($from) && $from !== '' ? $from : null,
            dateTo: is_string($to) && $to !== '' ? $to : null,
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
        );
    }

    private function nullableString(string $key): ?string
    {
        $value = $this->validated($key);

        return is_string($value) && $value !== '' ? $value : null;
    }
}
