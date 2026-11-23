<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Entities\RequestTrackingEvent;
use App\Domain\Enums\RequestTrackingStage;
use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Services\TripRequest\RequestTrackingFacts;
use App\Domain\Services\TripRequest\RequestTrackingService;
use DateTimeImmutable;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

final class RequestTrackingServiceTest extends TestCase
{
    private RequestTrackingService $tracking;

    protected function setUp(): void
    {
        parent::setUp();
        $this->tracking = new RequestTrackingService;
    }

    /**
     * @return list<array{0: TripStatus, 1: RequestTrackingStage}>
     */
    public static function inProgressStatuses(): array
    {
        return [
            [TripStatus::Going, RequestTrackingStage::InProgress],
            [TripStatus::AtDestination, RequestTrackingStage::InProgress],
            [TripStatus::Returning, RequestTrackingStage::InProgress],
        ];
    }

    public function test_pending_request_is_submitted_and_hides_the_driver(): void
    {
        $tracking = $this->tracking->build($this->facts());

        $this->assertSame(RequestTrackingStage::Submitted, $tracking->stage);
        $this->assertNull($tracking->driver);
        $this->assertNull($tracking->carLicense);
        $this->assertNull($tracking->rejectionReason);
        $this->assertNull($this->event($tracking->timeline, RequestTrackingStage::Approved)->reachedAt);
        $this->assertSame(
            UserRole::CompanyAdmin,
            $this->event($tracking->timeline, RequestTrackingStage::Approved)->actorRole,
        );
    }

    public function test_manual_approval_is_the_company_admin(): void
    {
        $approvedAt = new DateTimeImmutable('2026-11-02T12:00:00+00:00');
        $tracking = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Approved,
            approvedAt: $approvedAt,
            handledAt: $approvedAt,
        ));

        $this->assertSame(RequestTrackingStage::Approved, $tracking->stage);
        $approved = $this->event($tracking->timeline, RequestTrackingStage::Approved);
        $this->assertSame($approvedAt, $approved->reachedAt);
        $this->assertSame(UserRole::CompanyAdmin, $approved->actorRole);
    }

    public function test_auto_accepted_request_uses_the_requester_role(): void
    {
        $at = new DateTimeImmutable('2026-11-02T12:00:00+00:00');
        $tracking = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Approved,
            requesterRole: UserRole::DriversAdmin,
            autoApproved: true,
            approvedAt: $at,
            handledAt: $at,
            tripStatus: TripStatus::Unassigned,
            scheduledAt: $at,
        ));

        $this->assertSame(RequestTrackingStage::Approved, $tracking->stage);
        $this->assertNull($tracking->driver);
        $this->assertSame(
            UserRole::DriversAdmin,
            $this->event($tracking->timeline, RequestTrackingStage::Approved)->actorRole,
        );
        $this->assertSame(
            UserRole::DriversAdmin,
            $this->event($tracking->timeline, RequestTrackingStage::Submitted)->actorRole,
        );
    }

    public function test_assignment_reveals_driver_phone_and_vehicle(): void
    {
        $assignedAt = new DateTimeImmutable('2026-11-03T08:00:00+00:00');
        $tracking = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Approved,
            approvedAt: new DateTimeImmutable('2026-11-02T12:00:00+00:00'),
            tripStatus: TripStatus::Assigned,
            scheduledAt: new DateTimeImmutable('2026-11-04T09:00:00+00:00'),
            assignedAt: $assignedAt,
            hasDriver: true,
            driverNameEn: 'Nader',
            driverPhone: '010',
            carLicense: 'CAR-1',
        ));

        $this->assertSame(RequestTrackingStage::DriverAssigned, $tracking->stage);
        $this->assertSame('Nader', $tracking->driver?->nameEn);
        $this->assertSame('010', $tracking->driver?->phone);
        $this->assertSame('CAR-1', $tracking->carLicense);
        $this->assertSame($assignedAt, $this->event($tracking->timeline, RequestTrackingStage::DriverAssigned)->reachedAt);
        $this->assertSame(UserRole::DriversAdmin, $this->event($tracking->timeline, RequestTrackingStage::DriverAssigned)->actorRole);
    }

    #[DataProvider('inProgressStatuses')]
    public function test_driving_statuses_are_in_progress(TripStatus $status, RequestTrackingStage $stage): void
    {
        $tracking = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Approved,
            tripStatus: $status,
            hasDriver: true,
            goingStartedAt: new DateTimeImmutable('2026-11-04T09:00:00+00:00'),
        ));

        $this->assertSame($stage, $tracking->stage);
    }

    public function test_completion_moves_through_confirmation(): void
    {
        $finished = new DateTimeImmutable('2026-11-04T11:00:00+00:00');
        $awaiting = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Approved,
            tripStatus: TripStatus::Completed,
            finishedAt: $finished,
            confirmationStatus: TripConfirmationStatus::Pending,
            confirmationRequestedAt: $finished,
            hasDriver: true,
        ));
        $this->assertSame(RequestTrackingStage::AwaitingConfirmation, $awaiting->stage);
        $this->assertSame($finished, $this->event($awaiting->timeline, RequestTrackingStage::Finished)->reachedAt);

        $confirmed = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Approved,
            tripStatus: TripStatus::Completed,
            confirmationStatus: TripConfirmationStatus::Confirmed,
            confirmedAt: new DateTimeImmutable('2026-11-04T12:00:00+00:00'),
            confirmationActorRole: UserRole::Employee,
            hasDriver: true,
        ));
        $this->assertSame(RequestTrackingStage::Confirmed, $confirmed->stage);
        $this->assertSame(UserRole::Employee, $this->event($confirmed->timeline, RequestTrackingStage::Confirmed)->actorRole);

        $unconfirmed = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Approved,
            tripStatus: TripStatus::Completed,
            confirmationStatus: TripConfirmationStatus::Unconfirmed,
            tripUpdatedAt: new DateTimeImmutable('2026-11-05T12:00:00+00:00'),
            hasDriver: true,
        ));
        $this->assertSame(RequestTrackingStage::Unconfirmed, $unconfirmed->stage);
        $this->assertNull($this->event($unconfirmed->timeline, RequestTrackingStage::Unconfirmed)->actorRole);
    }

    public function test_rejection_keeps_the_reason_and_stops_the_timeline(): void
    {
        $tracking = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Rejected,
            handledAt: new DateTimeImmutable('2026-11-02T13:00:00+00:00'),
            rejectionReason: ' No cars ',
        ));

        $this->assertSame(RequestTrackingStage::Rejected, $tracking->stage);
        $this->assertSame('No cars', $tracking->rejectionReason);
        $this->assertNull($tracking->driver);
        $this->assertSame(
            [RequestTrackingStage::Submitted, RequestTrackingStage::Rejected],
            array_map(static fn ($event) => $event->stage, $tracking->timeline),
        );
    }

    public function test_cancelled_request_and_cancelled_trip_name_their_actor(): void
    {
        $request = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Cancelled,
            requestUpdatedAt: new DateTimeImmutable('2026-11-02T14:00:00+00:00'),
        ));
        $this->assertSame(RequestTrackingStage::Cancelled, $request->stage);
        $this->assertSame(UserRole::Employee, $this->event($request->timeline, RequestTrackingStage::Cancelled)->actorRole);

        $trip = $this->tracking->build($this->facts(
            requestStatus: TripRequestStatus::Approved,
            tripStatus: TripStatus::Cancelled,
            assignedAt: new DateTimeImmutable('2026-11-03T08:00:00+00:00'),
            tripUpdatedAt: new DateTimeImmutable('2026-11-03T09:00:00+00:00'),
            hasDriver: true,
        ));
        $this->assertSame(RequestTrackingStage::Cancelled, $trip->stage);
        $this->assertSame(UserRole::DriversAdmin, $this->event($trip->timeline, RequestTrackingStage::Cancelled)->actorRole);
        $this->assertNotNull($trip->driver);
    }

    /**
     * @param  list<RequestTrackingEvent>  $timeline
     */
    private function event(array $timeline, RequestTrackingStage $stage): RequestTrackingEvent
    {
        foreach ($timeline as $event) {
            if ($event->stage === $stage) {
                return $event;
            }
        }

        $this->fail('Missing timeline stage '.$stage->value);
    }

    private function facts(
        TripRequestStatus $requestStatus = TripRequestStatus::Pending,
        UserRole $requesterRole = UserRole::Employee,
        bool $autoApproved = false,
        ?DateTimeImmutable $approvedAt = null,
        ?DateTimeImmutable $handledAt = null,
        ?string $rejectionReason = null,
        ?DateTimeImmutable $requestUpdatedAt = null,
        ?TripStatus $tripStatus = null,
        ?DateTimeImmutable $scheduledAt = null,
        ?DateTimeImmutable $assignedAt = null,
        ?DateTimeImmutable $goingStartedAt = null,
        ?DateTimeImmutable $finishedAt = null,
        ?TripConfirmationStatus $confirmationStatus = null,
        ?DateTimeImmutable $confirmationRequestedAt = null,
        ?DateTimeImmutable $confirmedAt = null,
        ?UserRole $confirmationActorRole = null,
        ?DateTimeImmutable $tripUpdatedAt = null,
        bool $hasDriver = false,
        ?string $driverNameEn = null,
        ?string $driverPhone = null,
        ?string $carLicense = null,
    ): RequestTrackingFacts {
        return new RequestTrackingFacts(
            requestStatus: $requestStatus,
            requesterRole: $requesterRole,
            autoApproved: $autoApproved,
            createdAt: new DateTimeImmutable('2026-11-02T10:00:00+00:00'),
            approvedAt: $approvedAt,
            handledAt: $handledAt,
            rejectionReason: $rejectionReason,
            requestUpdatedAt: $requestUpdatedAt,
            tripStatus: $tripStatus,
            scheduledAt: $scheduledAt,
            assignedAt: $assignedAt,
            goingStartedAt: $goingStartedAt,
            finishedAt: $finishedAt,
            confirmationStatus: $confirmationStatus,
            confirmationRequestedAt: $confirmationRequestedAt,
            confirmedAt: $confirmedAt,
            confirmationActorRole: $confirmationActorRole,
            tripUpdatedAt: $tripUpdatedAt,
            hasDriver: $hasDriver,
            driverNameEn: $driverNameEn,
            driverNameAr: null,
            driverPhone: $driverPhone,
            carLicense: $carLicense,
        );
    }
}
