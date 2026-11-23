<?php

declare(strict_types=1);

namespace App\Http\Requests\Concerns;

use App\Domain\Services\ScheduleTime;
use Illuminate\Validation\Validator;

trait RejectsPastSchedule
{
    protected function rejectPastSchedule(Validator $validator, string $field, ?string $raw): void
    {
        if (! is_string($raw) || $raw === '') {
            return;
        }

        $parsed = $this->parseOptionalDateTime($raw);
        if ($parsed === null || ! app(ScheduleTime::class)->isNotFuture($parsed)) {
            return;
        }

        $validator->errors()->add($field, __('messages.scheduled_in_past'));
    }
}
