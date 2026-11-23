<?php

declare(strict_types=1);

namespace Tests\Feature\Trips;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Artisan;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class AutoConfirmTripsCommandTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_pending_confirmations_older_than_24_hours_become_unconfirmed(): void
    {
        $creator = $this->createUserWithRole(UserRole::DriversAdmin);

        try {
            Carbon::setTestNow(Carbon::parse('2026-11-05 12:00:00', 'UTC'));

            $exact = $this->trip($creator, TripConfirmationStatus::Pending, '2026-11-04 12:00:00');
            $older = $this->trip($creator, TripConfirmationStatus::Pending, '2026-11-04 11:59:59');
            $newer = $this->trip($creator, TripConfirmationStatus::Pending, '2026-11-04 12:00:01');
            $missingRequestedAt = $this->trip($creator, TripConfirmationStatus::Pending, null);
            $confirmed = $this->trip($creator, TripConfirmationStatus::Confirmed, '2026-11-01 12:00:00', false);
            $already = $this->trip($creator, TripConfirmationStatus::Unconfirmed, '2026-11-01 12:00:00');

            $this->artisan('trips:auto-confirm')
                ->expectsOutput('Marked 2 trip(s) as unconfirmed.')
                ->assertSuccessful();

            $this->assertUnconfirmed($exact);
            $this->assertUnconfirmed($older);
            $this->assertSame(TripConfirmationStatus::Pending, $newer->fresh()->confirmation_status);
            $this->assertSame(TripConfirmationStatus::Pending, $missingRequestedAt->fresh()->confirmation_status);
            $confirmed->refresh();
            $this->assertSame(TripConfirmationStatus::Confirmed, $confirmed->confirmation_status);
            $this->assertFalse($confirmed->driver_showed_up);
            $this->assertNotNull($confirmed->confirmed_at);
            $this->assertSame(TripConfirmationStatus::Unconfirmed, $already->fresh()->confirmation_status);

            $this->artisan('trips:auto-confirm')
                ->expectsOutput('Marked 0 trip(s) as unconfirmed.')
                ->assertSuccessful();

            $this->assertUnconfirmed($exact);
            $this->assertSame(TripConfirmationStatus::Confirmed, $confirmed->fresh()->confirmation_status);
            $this->assertSame(TripConfirmationStatus::Pending, $newer->fresh()->confirmation_status);
        } finally {
            Carbon::setTestNow();
        }
    }

    public function test_command_is_scheduled_hourly(): void
    {
        Artisan::call('schedule:list', ['--json' => true]);
        /** @var list<array<string, mixed>> $events */
        $events = json_decode(Artisan::output(), true, 512, JSON_THROW_ON_ERROR);

        $match = collect($events)->first(
            static fn (array $event): bool => str_contains((string) $event['command'], 'trips:auto-confirm'),
        );

        $this->assertIsArray($match);
        $this->assertSame('0 * * * *', $match['expression']);
    }

    private function trip(
        User $creator,
        TripConfirmationStatus $confirmation,
        ?string $requestedAt,
        ?bool $showedUp = null,
    ): Trip {
        return Trip::factory()->create([
            'created_by' => $creator->id,
            'status' => TripStatus::Completed,
            'confirmation_status' => $confirmation,
            'confirmation_requested_at' => $requestedAt,
            'confirmed_at' => $confirmation === TripConfirmationStatus::Confirmed ? '2026-11-01 13:00:00' : null,
            'driver_showed_up' => $showedUp,
        ]);
    }

    private function assertUnconfirmed(Trip $trip): void
    {
        $trip->refresh();
        $this->assertSame(TripConfirmationStatus::Unconfirmed, $trip->confirmation_status);
        $this->assertNull($trip->confirmed_at);
        $this->assertNull($trip->confirmed_by);
        $this->assertNull($trip->driver_showed_up);
    }
}
