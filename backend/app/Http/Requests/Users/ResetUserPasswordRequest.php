<?php

declare(strict_types=1);

namespace App\Http\Requests\Users;

use App\Application\Users\DTOs\ResetUserPasswordData;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules\Password;

final class ResetUserPasswordRequest extends FormRequest
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
            'password' => ['required', 'string', 'confirmed', Password::defaults()],
        ];
    }

    public function toDto(string $actorId, string $userId): ResetUserPasswordData
    {
        return new ResetUserPasswordData(
            actorId: $actorId,
            userId: $userId,
            password: (string) $this->validated('password'),
        );
    }
}
