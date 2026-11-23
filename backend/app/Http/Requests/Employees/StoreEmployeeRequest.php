<?php

declare(strict_types=1);

namespace App\Http\Requests\Employees;

use App\Application\Employees\DTOs\CreateEmployeeData;
use App\Domain\Enums\Branch;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

final class StoreEmployeeRequest extends FormRequest
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
            'name_en' => ['required', 'string', 'max:255'],
            'name_ar' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'email', 'max:255', 'unique:users,email'],
            'password' => ['required', 'string', Password::defaults()],
            'phone' => ['nullable', 'string', 'max:50'],
            'branch' => ['nullable', 'string', Rule::enum(Branch::class)],
        ];
    }

    public function toDto(): CreateEmployeeData
    {
        /** @var string|null $branch */
        $branch = $this->validated('branch');

        return new CreateEmployeeData(
            nameEn: (string) $this->validated('name_en'),
            nameAr: (string) $this->validated('name_ar'),
            email: (string) $this->validated('email'),
            password: (string) $this->validated('password'),
            phone: $this->validated('phone'),
            branch: $branch === null ? null : Branch::from($branch),
        );
    }
}
