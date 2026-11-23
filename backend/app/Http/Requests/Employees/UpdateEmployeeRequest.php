<?php

declare(strict_types=1);

namespace App\Http\Requests\Employees;

use App\Application\Employees\DTOs\UpdateEmployeeData;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

final class UpdateEmployeeRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Only sent fields are validated. Boolean false is a real value, so
     * `is_active` is `sometimes|boolean` rather than `required`.
     *
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'name_en' => ['sometimes', 'required', 'string', 'max:255'],
            'name_ar' => ['sometimes', 'required', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:50'],
            'branch' => ['sometimes', 'nullable', 'string', Rule::enum(Branch::class)],
            'is_active' => ['sometimes', 'boolean'],
            'password' => ['sometimes', 'nullable', 'string', Password::defaults()],
        ];
    }

    public function toDto(): UpdateEmployeeData
    {
        $employee = User::query()
            ->where('role', UserRole::Employee)
            ->findOrFail((string) $this->route('id'));

        $branch = $this->exists('branch') ? $this->validated('branch') : $employee->branch?->value;
        $password = $this->validated('password');

        return new UpdateEmployeeData(
            id: (string) $employee->id,
            nameEn: $this->exists('name_en') ? (string) $this->validated('name_en') : $employee->name_en,
            nameAr: $this->exists('name_ar') ? (string) $this->validated('name_ar') : $employee->name_ar,
            phone: $this->exists('phone') ? $this->validated('phone') : $employee->phone,
            branch: is_string($branch) && $branch !== '' ? Branch::from($branch) : null,
            isActive: $this->exists('is_active') ? $this->boolean('is_active') : (bool) $employee->is_active,
            password: is_string($password) && $password !== '' ? $password : null,
        );
    }
}
