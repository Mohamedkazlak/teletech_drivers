<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Shared\PaginatedResult;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\JsonResource;

final class PaginatedResourceResponse
{
    /**
     * @param  PaginatedResult<mixed>  $result
     * @param  list<JsonResource|array<string, mixed>>  $resources
     */
    public static function make(PaginatedResult $result, array $resources): JsonResponse
    {
        return response()->json([
            'data' => array_map(
                static function (JsonResource|array $resource): array {
                    if ($resource instanceof JsonResource) {
                        return $resource->resolve();
                    }

                    return $resource;
                },
                $resources,
            ),
            'meta' => [
                'current_page' => $result->page,
                'per_page' => $result->perPage,
                'total' => $result->total,
                'last_page' => $result->lastPage(),
            ],
        ]);
    }
}
