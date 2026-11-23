<?php

declare(strict_types=1);

namespace App\Http\Requests\Auth;

use App\Application\Auth\DTOs\UpdateProfileData;
use App\Domain\Enums\Branch;
use App\Domain\Enums\UserRole;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

final class UpdateProfileRequest extends FormRequest
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
        $userId = $this->user()?->getAuthIdentifier();

        return [
            'name_en' => ['sometimes', 'required', 'string', 'max:255'],
            'name_ar' => ['sometimes', 'nullable', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:50'],
            'branch' => ['sometimes', 'nullable', 'string', Rule::enum(Branch::class)],
            'email' => [
                'sometimes',
                'required',
                'string',
                'email',
                'max:255',
                Rule::unique('users', 'email')->ignore($userId),
            ],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $validator): void {
            $user = $this->user();
            if ($user === null || ! $this->exists('branch')) {
                return;
            }

            if ($user->role !== UserRole::Admin) {
                $validator->errors()->add(
                    'branch',
                    'Only an admin can change the branch after registration.',
                );
            }
        });
    }

    public function toDto(): UpdateProfileData
    {
        $changes = [];

        if ($this->exists('name_en')) {
            $changes['name_en'] = (string) $this->validated('name_en');
        }

        if ($this->exists('name_ar')) {
            $changes['name_ar'] = $this->validated('name_ar');
        }

        if ($this->exists('phone')) {
            $changes['phone'] = $this->validated('phone');
        }

        if ($this->exists('branch')) {
            $branch = $this->validated('branch');
            $changes['branch'] = $branch === null ? null : Branch::from((string) $branch);
        }

        if ($this->exists('email')) {
            $changes['email'] = (string) $this->validated('email');
        }

        return new UpdateProfileData(
            userId: (string) $this->user()->getAuthIdentifier(),
            changes: $changes,
        );
    }
}
