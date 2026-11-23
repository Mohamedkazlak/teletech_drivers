<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class TripConfirmationStageFilterTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_completed_and_awaiting_report_stages_follow_confirmation_status(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $pending = $this->trip($creator, TripStatus::Completed, TripConfirmationStatus::Pending, null);
        $confirmed = $this->trip($creator, TripStatus::Completed, TripConfirmationStatus::Confirmed, true);
        $unconfirmed = $this->trip($creator, TripStatus::Completed, TripConfirmationStatus::Unconfirmed, false);
        $legacy = $this->trip($creator, TripStatus::Completed, null, null);
        $going = $this->trip($creator, TripStatus::Going, TripConfirmationStatus::Pending, null);

        $this->actingAsRole(UserRole::DriversAdmin);

        $this->assertEqualsCanonicalizing(
            [$confirmed, $unconfirmed],
            $this->ids('/api/trips?stage=completed'),
        );
        $this->assertSame([$pending], $this->ids('/api/trips?stage=awaiting_report'));
        $this->assertEqualsCanonicalizing(
            [$pending, $confirmed, $unconfirmed, $legacy],
            $this->ids('/api/trips?status=completed'),
        );
        $this->assertSame([], $this->ids('/api/trips?stage=awaiting_report&status=going'));
        $this->assertSame([$going], $this->ids('/api/trips?status=going'));
        $this->assertNotContains($legacy, $this->ids('/api/trips?stage=completed'));
        $this->assertNotContains($legacy, $this->ids('/api/trips?stage=awaiting_report'));

        $this->getJson('/api/trips?stage=needs_report')->assertJsonValidationErrors(['stage']);
    }

    public function test_driver_showed_up_false_returns_no_shows(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);
        $noShow = $this->trip($creator, TripStatus::Completed, TripConfirmationStatus::Confirmed, false);
        $showed = $this->trip($creator, TripStatus::Completed, TripConfirmationStatus::Confirmed, true);
        $unknown = $this->trip($creator, TripStatus::Completed, TripConfirmationStatus::Pending, null);

        $this->actingAsRole(UserRole::CompanyAdmin);

        $this->assertSame([$noShow], $this->ids('/api/trips?driver_showed_up=false'));
        $this->assertSame([$showed], $this->ids('/api/trips?driver_showed_up=true'));
        $this->assertSame(
            [$noShow],
            $this->ids('/api/trips?stage=completed&driver_showed_up=false'),
        );
        $this->assertNotContains($unknown, $this->ids('/api/trips?driver_showed_up=false'));
        $this->assertNotContains($showed, $this->ids('/api/trips?driver_showed_up=false'));

        $this->getJson('/api/trips?driver_showed_up=maybe')->assertJsonValidationErrors(['driver_showed_up']);

        $this->actingAsRole(UserRole::Employee)->getJson('/api/trips?stage=awaiting_report')->assertForbidden();
    }

    private function trip(
        User $creator,
        TripStatus $status,
        ?TripConfirmationStatus $confirmation,
        ?bool $showedUp,
    ): string {
        return Trip::factory()->create([
            'created_by' => $creator->id,
            'status' => $status,
            'confirmation_status' => $confirmation,
            'driver_showed_up' => $showedUp,
            'scheduled_at' => now()->addHour(),
        ])->id;
    }

    /**
     * @return list<string>
     */
    private function ids(string $url): array
    {
        return collect($this->getJson($url)->assertOk()->json('data'))->pluck('id')->all();
    }
}
