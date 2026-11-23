<?php

declare(strict_types=1);

namespace App\Http\Requests\DeviceTokens;

use Illuminate\Foundation\Http\FormRequest;

final class DeleteDeviceTokenRequest extends FormRequest
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
            'token' => ['required', 'string', 'max:4096'],
        ];
    }

    public function token(): string
    {
        return (string) $this->validated('token');
    }
}
