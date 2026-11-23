<?php

declare(strict_types=1);

namespace App\Http\Requests\Users;

use App\Application\Users\DTOs\ListUsersData;
use App\Domain\Enums\UserRole;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ListUsersRequest extends FormRequest
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
            'role' => ['sometimes', 'nullable', 'string', Rule::enum(UserRole::class)],
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListUsersData
    {
        /** @var string|null $role */
        $role = $this->validated('role');

        return new ListUsersData(
            role: $role === null || $role === '' ? null : UserRole::from($role),
            search: $this->validated('search'),
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
        );
    }
}
