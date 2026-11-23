<?php

declare(strict_types=1);

namespace App\Http\Requests\Drivers;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

final class ExportDriverReportRequest extends FormRequest
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
            'period' => ['required', 'string', Rule::in(['week', 'month', 'year'])],
            'date' => ['required', 'date_format:Y-m-d'],
            'project' => ['sometimes', 'nullable', 'string', 'max:200'],
        ];
    }

    public function period(): string
    {
        return (string) $this->validated('period');
    }

    public function anchorDate(): string
    {
        return (string) $this->validated('date');
    }

    public function project(): string
    {
        $project = $this->validated('project');

        return is_string($project) ? trim($project) : '';
    }
}
