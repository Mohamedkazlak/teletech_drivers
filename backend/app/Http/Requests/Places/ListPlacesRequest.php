<?php

declare(strict_types=1);

namespace App\Http\Requests\Places;

use App\Application\Places\DTOs\ListPlacesData;
use App\Http\Requests\Concerns\NormalizesBooleanQuery;
use Illuminate\Foundation\Http\FormRequest;

final class ListPlacesRequest extends FormRequest
{
    use NormalizesBooleanQuery;

    public function authorize(): bool
    {
        return true;
    }

    protected function prepareForValidation(): void
    {
        $this->normalizeBooleanQueries('is_active', 'is_headquarters');
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'is_active' => ['sometimes', 'boolean'],
            'is_headquarters' => ['sometimes', 'boolean'],
            'search' => ['sometimes', 'nullable', 'string', 'max:255'],
            'page' => ['sometimes', 'integer', 'min:1'],
            'per_page' => ['sometimes', 'integer', 'min:1', 'max:100'],
        ];
    }

    public function toDto(): ListPlacesData
    {
        return new ListPlacesData(
            isActive: $this->has('is_active') ? $this->boolean('is_active') : null,
            search: $this->validated('search'),
            isHeadquarters: $this->has('is_headquarters') ? $this->boolean('is_headquarters') : null,
            page: (int) ($this->validated('page') ?? 1),
            perPage: (int) ($this->validated('per_page') ?? 15),
        );
    }
}
