<?php

declare(strict_types=1);

namespace App\Http\Requests\Auth;

use App\Application\Auth\DTOs\RegisterUserData;
use App\Domain\Enums\Branch;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;

final class RegisterRequest extends FormRequest
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
            'password' => ['required', 'string', 'confirmed', Password::defaults()],
            'phone' => ['required', 'string', 'max:50'],
            'branch' => ['required', 'string', Rule::enum(Branch::class)],
        ];
    }

    public function toDto(): RegisterUserData
    {
        return new RegisterUserData(
            nameEn: (string) $this->validated('name_en'),
            nameAr: (string) $this->validated('name_ar'),
            email: (string) $this->validated('email'),
            password: (string) $this->validated('password'),
            phone: (string) $this->validated('phone'),
            branch: Branch::from((string) $this->validated('branch')),
        );
    }
}
