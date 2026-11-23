<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Application\Auth\Results\AuthTokenResult;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin AuthTokenResult
 */
final class AuthTokenResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var AuthTokenResult $result */
        $result = $this->resource;

        return [
            'token' => $result->token,
            'token_type' => 'Bearer',
            'user' => (new UserResource($result->user))->resolve(),
        ];
    }
}
