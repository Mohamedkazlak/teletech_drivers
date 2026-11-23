<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Domain\Entities\GroupSuggestion;
use App\Domain\Entities\GroupSuggestionMember;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin GroupSuggestion
 */
final class GroupSuggestionResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        /** @var GroupSuggestion $suggestion */
        $suggestion = $this->resource;

        return [
            'cluster_id' => $suggestion->clusterId,
            'request_ids' => $suggestion->requestIds,
            'destination_label' => $suggestion->destinationLabel,
            'route_label' => $suggestion->routeLabel,
            'date' => $suggestion->date,
            'earliest_requested_at' => $suggestion->earliestRequestedAt->format(DATE_ATOM),
            'latest_requested_at' => $suggestion->latestRequestedAt->format(DATE_ATOM),
            'members' => array_map(
                static fn (GroupSuggestionMember $member): array => [
                    'request_id' => $member->requestId,
                    'requester_name_en' => $member->requesterNameEn,
                    'requester_name_ar' => $member->requesterNameAr,
                    'branch' => $member->branch,
                    'from_place' => $member->fromPlace,
                    'to_place' => $member->toPlace,
                    'requested_at' => $member->requestedAt->format(DATE_ATOM),
                ],
                $suggestion->members,
            ),
        ];
    }
}
