<?php

declare(strict_types=1);

namespace App\Http\Requests\Notifications;

use App\Application\Notifications\DTOs\ListNotificationsData;
use App\Http\Requests\Concerns\NormalizesBooleanQuery;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;

final class ListNotificationsRequest extends FormRequest
{
    use NormalizesBooleanQuery;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->normalizeBooleanQuery('unread');
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'unread' => ['sometimes', 'nullable', 'boolean'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListNotificationsData
    {
        /** @var User $user */
        $user = $this->user();

        return new ListNotificationsData(
            userId: (string) $user->id,
            unread: $this->exists('unread') ? $this->boolean('unread') : null,
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
        );
    }
}
