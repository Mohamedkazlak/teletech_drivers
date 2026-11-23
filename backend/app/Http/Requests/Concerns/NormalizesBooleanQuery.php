<?php

declare(strict_types=1);

namespace App\Http\Requests\Concerns;

use App\Domain\Enums\UserRole;
use Illuminate\Auth\Access\AuthorizationException;

trait NormalizesBooleanQuery
{
    /**
     * Query strings send "true"/"false" and "1"/"0". The boolean rule accepts
     * 1/0 and real booleans, but rejects the strings "true" and "false".
     * Map the accepted spellings to booleans and leave anything else so
     * validation can reject it.
     */
    protected function normalizeBooleanQuery(string $key): void
    {
        if (! $this->exists($key)) {
            return;
        }

        $value = $this->input($key);
        if (is_bool($value) || is_int($value)) {
            return;
        }

        if (! is_string($value)) {
            return;
        }

        $normalized = match (strtolower(trim($value))) {
            'true', '1' => true,
            'false', '0' => false,
            default => null,
        };

        if ($normalized === null) {
            return;
        }

        $this->merge([
            $key => $normalized,
        ]);
    }

    protected function normalizeBooleanQueries(string ...$keys): void
    {
        foreach ($keys as $key) {
            $this->normalizeBooleanQuery($key);
        }
    }

    /**
     * A truthy include_deleted is admin-only. False or omitted stays a no-op.
     * Invalid values are left for the boolean rule (422).
     */
    protected function rejectIncludeDeletedForNonAdmin(): void
    {
        $this->normalizeBooleanQuery('include_deleted');

        if (! $this->exists('include_deleted') || ! $this->boolean('include_deleted')) {
            return;
        }

        if ($this->user()?->role === UserRole::Admin) {
            return;
        }

        throw new AuthorizationException;
    }
}
