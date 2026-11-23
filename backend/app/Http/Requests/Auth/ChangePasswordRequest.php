<?php

declare(strict_types=1);

namespace App\Http\Requests\Auth;

use App\Application\Auth\DTOs\ChangePasswordData;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

final class ChangePasswordRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'current_password' => ['required', 'string'],
            'password' => ['required', 'string', 'confirmed', Password::defaults()],
        ];
    }

    public function toDto(): ChangePasswordData
    {
        return new ChangePasswordData(
            userId: (string) $this->user()->getAuthIdentifier(),
            currentPassword: (string) $this->validated('current_password'),
            password: (string) $this->validated('password'),
        );
    }
}
