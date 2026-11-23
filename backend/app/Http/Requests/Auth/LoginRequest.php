<?php

declare(strict_types=1);

namespace App\Http\Requests\Auth;

use App\Application\Auth\DTOs\LoginUserData;
use Illuminate\Foundation\Http\FormRequest;

final class LoginRequest extends FormRequest
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
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string'],
        ];
    }

    public function toDto(): LoginUserData
    {
        return new LoginUserData(
            email: (string) $this->validated('email'),
            password: (string) $this->validated('password'),
        );
    }
}
