<?php

declare(strict_types=1);

namespace App\Http\Requests\Attendance;

use App\Application\Attendance\DTOs\AdjustAttendanceData;
use App\Models\User;
use DateTimeImmutable;
use Illuminate\Foundation\Http\FormRequest;

final class AdjustAttendanceRequest extends FormRequest
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
            'driver_id' => ['required', 'uuid'],
            'work_date' => ['required', 'date_format:Y-m-d'],
            'checked_in_at' => ['required', 'date'],
            'checked_out_at' => ['sometimes', 'nullable', 'date'],
            'reason' => ['required', 'string', 'min:1', 'max:500'],
        ];
    }

    public function toDto(): AdjustAttendanceData
    {
        /** @var User $actor */
        $actor = $this->user();
        $checkedOut = $this->validated('checked_out_at');

        return new AdjustAttendanceData(
            actorId: (string) $actor->id,
            driverId: (string) $this->validated('driver_id'),
            workDate: (string) $this->validated('work_date'),
            checkedInAt: new DateTimeImmutable((string) $this->validated('checked_in_at')),
            checkedOutAt: is_string($checkedOut) && $checkedOut !== ''
                ? new DateTimeImmutable($checkedOut)
                : null,
            reason: trim((string) $this->validated('reason')),
        );
    }
}
