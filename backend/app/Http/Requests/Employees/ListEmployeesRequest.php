<?php

declare(strict_types=1);

namespace App\Http\Requests\Employees;

use App\Application\Employees\DTOs\ListEmployeesData;
use App\Domain\Enums\Branch;
use App\Http\Requests\Concerns\NormalizesBooleanQuery;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListEmployeesRequest extends FormRequest
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
            'branch' => ['sometimes', 'nullable', 'string', Rule::enum(Branch::class)],
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'include_deleted' => ['sometimes', 'boolean'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListEmployeesData
    {
        $includeDeleted = $this->boolean('include_deleted');

        /** @var string|null $branch */
        $branch = $this->validated('branch');

        return new ListEmployeesData(
            isActive: $this->has('is_active') ? $this->boolean('is_active') : null,
            branch: $branch === null ? null : Branch::from($branch),
            search: $this->validated('search'),
            includeDeleted: $includeDeleted,
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
        );
    }
}
