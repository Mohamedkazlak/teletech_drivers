<?php

declare(strict_types=1);

namespace App\Http\Requests\Drivers;

use App\Application\Drivers\DTOs\ListDriversData;
use App\Domain\Enums\DriverAttendanceFilter;
use App\Http\Requests\Concerns\NormalizesBooleanQuery;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListDriversRequest extends FormRequest
{
    use NormalizesBooleanQuery;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->normalizeBooleanQuery('is_active');
        $this->rejectIncludeDeletedForNonAdmin();
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'is_active' => ['sometimes', 'boolean'],
            'attendance' => ['sometimes', 'nullable', 'string', Rule::enum(DriverAttendanceFilter::class)],
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'include_deleted' => ['sometimes', 'boolean'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListDriversData
    {
        $includeDeleted = $this->boolean('include_deleted');

        /** @var string|null $attendance */
        $attendance = $this->validated('attendance');

        return new ListDriversData(
            isActive: $this->has('is_active') ? $this->boolean('is_active') : null,
            attendance: $attendance === null ? null : DriverAttendanceFilter::from($attendance),
            search: $this->validated('search'),
            includeDeleted: $includeDeleted,
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
        );
    }
}
