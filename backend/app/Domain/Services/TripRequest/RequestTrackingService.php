<?php

declare(strict_types=1);

namespace App\Domain\Services\TripRequest;

use App\Domain\Entities\RequestTracking;
use App\Domain\Entities\RequestTrackingDriver;
use App\Domain\Entities\RequestTrackingEvent;
use App\Domain\Enums\RequestTrackingStage;
use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use DateTimeImmutable;

/**
 * Single place that derives a requester's tracking stage and timeline.
 *
 * Grouped requests share the trip's assignment, progress, and confirmation.
 * Each call still describes only one request.
 */
final class RequestTrackingService
{
    public function build(RequestTrackingFacts $facts): RequestTracking
    {
        $stage = $this->stage($facts);

        return new RequestTracking(
            stage: $stage,
            timeline: $this->timeline($facts, $stage),
            rejectionReason: $stage === RequestTrackingStage::Rejected
                ? $this->reason($facts->rejectionReason)
                : null,
            driver: $facts->hasDriver
                ? new RequestTrackingDriver(
                    nameEn: $this->blankToNull($facts->driverNameEn),
                    nameAr: $this->blankToNull($facts->driverNameAr),
                    phone: $this->blankToNull($facts->driverPhone),
                )
                : null,
            scheduledAt: $facts->scheduledAt,
            carLicense: $facts->hasDriver ? $this->blankToNull($facts->carLicense) : null,
        );
    }

    public function stage(RequestTrackingFacts $facts): RequestTrackingStage
    {
        if ($facts->requestStatus === TripRequestStatus::Cancelled) {
            return RequestTrackingStage::Cancelled;
        }

        if ($facts->requestStatus === TripRequestStatus::Rejected) {
            return RequestTrackingStage::Rejected;
        }

        if ($facts->tripStatus === TripStatus::Cancelled) {
            return RequestTrackingStage::Cancelled;
        }

        if ($facts->requestStatus === TripRequestStatus::Pending) {
            return RequestTrackingStage::Submitted;
        }

        if ($facts->tripStatus === TripStatus::Completed) {
            return match ($facts->confirmationStatus) {
                TripConfirmationStatus::Pending => RequestTrackingStage::AwaitingConfirmation,
                TripConfirmationStatus::Confirmed => RequestTrackingStage::Confirmed,
                TripConfirmationStatus::Unconfirmed => RequestTrackingStage::Unconfirmed,
                null => RequestTrackingStage::Finished,
            };
        }

        if (in_array($facts->tripStatus, [
            TripStatus::Going,
            TripStatus::AtDestination,
            TripStatus::Returning,
        ], true)) {
            return RequestTrackingStage::InProgress;
        }

        if ($facts->hasDriver || $facts->tripStatus === TripStatus::Assigned) {
            return RequestTrackingStage::DriverAssigned;
        }

        return RequestTrackingStage::Approved;
    }

    /**
     * @return list<RequestTrackingEvent>
     */
    private function timeline(RequestTrackingFacts $facts, RequestTrackingStage $current): array
    {
        if ($current === RequestTrackingStage::Rejected) {
            return [
                $this->event(RequestTrackingStage::Submitted, $facts->createdAt, $facts->requesterRole),
                $this->event(RequestTrackingStage::Rejected, $facts->handledAt, UserRole::CompanyAdmin),
            ];
        }

        if ($current === RequestTrackingStage::Cancelled) {
            return $this->cancelledTimeline($facts);
        }

        $events = [];
        foreach ($this->happyPath() as $step) {
            $reached = $this->rank($step) <= $this->rank($current);
            $events[] = $this->event(
                $step,
                $reached ? $this->timestamp($step, $facts) : null,
                $this->actor($step, $facts),
            );
        }

        if ($current === RequestTrackingStage::Confirmed) {
            $events[] = $this->event(
                RequestTrackingStage::Confirmed,
                $facts->confirmedAt,
                $facts->confirmationActorRole ?? $facts->requesterRole,
            );
        }

        if ($current === RequestTrackingStage::Unconfirmed) {
            $events[] = $this->event(
                RequestTrackingStage::Unconfirmed,
                $facts->tripUpdatedAt,
                null,
            );
        }

        return $events;
    }

    /**
     * @return list<RequestTrackingEvent>
     */
    private function cancelledTimeline(RequestTrackingFacts $facts): array
    {
        $events = [
            $this->event(RequestTrackingStage::Submitted, $facts->createdAt, $facts->requesterRole),
        ];

        if ($this->approvalReached($facts)) {
            $events[] = $this->event(
                RequestTrackingStage::Approved,
                $this->timestamp(RequestTrackingStage::Approved, $facts),
                $this->actor(RequestTrackingStage::Approved, $facts),
            );
        }

        if ($facts->hasDriver || $facts->assignedAt !== null) {
            $events[] = $this->event(
                RequestTrackingStage::DriverAssigned,
                $facts->assignedAt,
                UserRole::DriversAdmin,
            );
        }

        if ($facts->goingStartedAt !== null) {
            $events[] = $this->event(
                RequestTrackingStage::InProgress,
                $facts->goingStartedAt,
                UserRole::Driver,
            );
        }

        if ($facts->finishedAt !== null) {
            $events[] = $this->event(
                RequestTrackingStage::Finished,
                $facts->finishedAt,
                UserRole::Driver,
            );
        }

        $events[] = $this->event(
            RequestTrackingStage::Cancelled,
            $facts->requestStatus === TripRequestStatus::Cancelled
                ? $facts->requestUpdatedAt
                : $facts->tripUpdatedAt,
            $facts->requestStatus === TripRequestStatus::Cancelled
                ? $facts->requesterRole
                : UserRole::DriversAdmin,
        );

        return $events;
    }

    private function approvalReached(RequestTrackingFacts $facts): bool
    {
        return $facts->requestStatus === TripRequestStatus::Approved
            || $facts->autoApproved
            || $facts->approvedAt !== null
            || $facts->tripStatus !== null;
    }

    private function event(
        RequestTrackingStage $stage,
        ?DateTimeImmutable $reachedAt,
        ?UserRole $actorRole,
    ): RequestTrackingEvent {
        return new RequestTrackingEvent($stage, $reachedAt, $actorRole);
    }

    /**
     * @return list<RequestTrackingStage>
     */
    private function happyPath(): array
    {
        return [
            RequestTrackingStage::Submitted,
            RequestTrackingStage::Approved,
            RequestTrackingStage::DriverAssigned,
            RequestTrackingStage::InProgress,
            RequestTrackingStage::Finished,
            RequestTrackingStage::AwaitingConfirmation,
        ];
    }

    private function rank(RequestTrackingStage $stage): int
    {
        return match ($stage) {
            RequestTrackingStage::Submitted => 0,
            RequestTrackingStage::Approved, RequestTrackingStage::Rejected => 1,
            RequestTrackingStage::DriverAssigned => 2,
            RequestTrackingStage::InProgress => 3,
            RequestTrackingStage::Finished => 4,
            RequestTrackingStage::AwaitingConfirmation => 5,
            RequestTrackingStage::Confirmed, RequestTrackingStage::Unconfirmed => 6,
            RequestTrackingStage::Cancelled => 7,
        };
    }

    private function timestamp(RequestTrackingStage $stage, RequestTrackingFacts $facts): ?DateTimeImmutable
    {
        return match ($stage) {
            RequestTrackingStage::Submitted => $facts->createdAt,
            RequestTrackingStage::Approved => $facts->approvedAt
                ?? (($facts->autoApproved || $facts->requestStatus === TripRequestStatus::Approved)
                    ? $facts->handledAt
                    : null),
            RequestTrackingStage::DriverAssigned => $facts->assignedAt,
            RequestTrackingStage::InProgress => $facts->goingStartedAt,
            RequestTrackingStage::Finished => $facts->finishedAt,
            RequestTrackingStage::AwaitingConfirmation => $facts->confirmationRequestedAt,
            RequestTrackingStage::Confirmed => $facts->confirmedAt,
            RequestTrackingStage::Unconfirmed => $facts->tripUpdatedAt,
            RequestTrackingStage::Rejected => $facts->handledAt,
            RequestTrackingStage::Cancelled => $facts->requestStatus === TripRequestStatus::Cancelled
                ? $facts->requestUpdatedAt
                : $facts->tripUpdatedAt,
        };
    }

    private function actor(RequestTrackingStage $stage, RequestTrackingFacts $facts): ?UserRole
    {
        return match ($stage) {
            RequestTrackingStage::Submitted => $facts->requesterRole,
            RequestTrackingStage::Approved => $facts->autoApproved
                ? $facts->requesterRole
                : UserRole::CompanyAdmin,
            RequestTrackingStage::Rejected => UserRole::CompanyAdmin,
            RequestTrackingStage::DriverAssigned => UserRole::DriversAdmin,
            RequestTrackingStage::InProgress,
            RequestTrackingStage::Finished,
            RequestTrackingStage::AwaitingConfirmation => UserRole::Driver,
            RequestTrackingStage::Confirmed => $facts->confirmationActorRole ?? $facts->requesterRole,
            RequestTrackingStage::Unconfirmed => null,
            RequestTrackingStage::Cancelled => $facts->requestStatus === TripRequestStatus::Cancelled
                ? $facts->requesterRole
                : UserRole::DriversAdmin,
        };
    }

    private function reason(?string $reason): ?string
    {
        return $this->blankToNull($reason);
    }

    private function blankToNull(?string $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $trimmed = trim($value);

        return $trimmed === '' ? null : $trimmed;
    }
}
