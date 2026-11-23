<?php

declare(strict_types=1);

namespace App\Http\Requests\DeviceTokens;

use App\Domain\Enums\DevicePlatform;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class UpsertDeviceTokenRequest extends FormRequest
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
            'platform' => ['required', 'string', Rule::in(['android', 'ios'])],
        ];
    }

    public function platform(): DevicePlatform
    {
        return DevicePlatform::from((string) $this->validated('platform'));
    }

    public function token(): string
    {
        return (string) $this->validated('token');
    }
}
