<?php

declare(strict_types=1);

namespace Tests\Feature\Push;

use App\Application\Push\Contracts\FcmClient;
use App\Domain\Enums\NotificationType;
use App\Domain\Enums\UserRole;
use App\Jobs\SendPushNotification;
use App\Models\DeviceToken;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Log\Events\MessageLogged;
use Illuminate\Support\Facades\Event;
use Laravel\Sanctum\Sanctum;
use Tests\Support\CreatesTripFixtures;
use Tests\Support\CreatesUsers;
use Tests\Support\FakeFcmClient;
use Tests\TestCase;

final class SendPushNotificationTest extends TestCase
{
    use CreatesTripFixtures;
    use CreatesUsers;
    use RefreshDatabase;

    private FakeFcmClient $fcm;

    protected function setUp(): void
    {
        parent::setUp();

        $this->fcm = new FakeFcmClient;
        $this->app->instance(FcmClient::class, $this->fcm);
    }

    public function test_push_is_sent_only_to_the_recipient_tokens_with_android_and_apns_config(): void
    {
        $recipient = $this->createUserWithRole(UserRole::CompanyAdmin);
        $bystander = $this->createUserWithRole(UserRole::Driver);
        $employee = $this->createUserWithRole(UserRole::Employee);
        $request = $this->createPendingRequest($employee);
        $trip = $this->createUnassignedTrip($recipient);
        $this->token($recipient, 'recipient-android', 'android', 'en');
        $this->token($recipient, 'recipient-ios', 'ios', 'ar');
        $this->token($bystander, 'bystander', 'android', 'en');

        $notification = $this->notification($recipient, tripId: $trip->id, tripRequestId: $request->id);
        Notification::query()->create([
            'user_id' => $recipient->id,
            'type' => NotificationType::TripAssigned,
            'title_key' => NotificationType::TripAssigned->titleKey(),
            'body_key' => NotificationType::TripAssigned->bodyKey(),
            'params' => $this->params(),
            'read_at' => now(),
        ]);

        SendPushNotification::dispatchSync($notification->id);

        $tokens = array_map(
            static fn (array $message): string => (string) $message['fid'],
            $this->fcm->sent,
        );
        sort($tokens);
        $this->assertSame(['recipient-android', 'recipient-ios'], $tokens);

        $english = $this->messageFor('recipient-android');
        $this->assertSame('New trip request', $english['notification']['title']);
        $this->assertSame(
            'Sara Adel requested a trip from Pickup to Destination.',
            $english['notification']['body'],
        );
        $this->assertSame([
            'notification_id' => $notification->id,
            'type' => NotificationType::RequestSubmitted->value,
            'trip_id' => $trip->id,
            'trip_request_id' => $request->id,
        ], $english['data']);
        $this->assertSame('HIGH', $english['android']['priority']);
        $this->assertSame('trips', $english['android']['notification']['channel_id']);
        $this->assertSame('10', $english['apns']['headers']['apns-priority']);
        $this->assertSame('default', $english['apns']['payload']['aps']['sound']);
        $this->assertSame(1, $english['apns']['payload']['aps']['badge']);

        $arabic = $this->messageFor('recipient-ios');
        $this->assertSame('طلب رحلة جديد', $arabic['notification']['title']);
        $this->assertSame(
            'طلب سارة عادل رحلة من Pickup إلى Destination.',
            $arabic['notification']['body'],
        );
        $this->assertSame(1, $arabic['apns']['payload']['aps']['badge']);
    }

    public function test_unregistered_and_invalid_tokens_are_deleted_and_the_rest_are_sent(): void
    {
        $recipient = $this->createUserWithRole(UserRole::CompanyAdmin);
        $this->token($recipient, 'gone', 'android', 'en');
        $this->token($recipient, 'invalid', 'ios', 'en');
        $this->token($recipient, 'kept', 'android', 'en');
        $this->fcm->rejected = [
            'gone' => 'UNREGISTERED',
            'invalid' => 'INVALID_ARGUMENT',
        ];

        SendPushNotification::dispatchSync($this->notification($recipient)->id);

        $this->assertSame(['kept'], array_map(
            static fn (array $message): string => (string) $message['fid'],
            $this->fcm->sent,
        ));
        $this->assertDatabaseMissing('device_tokens', ['token' => 'gone']);
        $this->assertDatabaseMissing('device_tokens', ['token' => 'invalid']);
        $this->assertDatabaseHas('device_tokens', ['token' => 'kept']);
    }

    public function test_missing_credentials_skip_delivery(): void
    {
        $this->app->forgetInstance(FcmClient::class);
        $warnings = [];
        Event::listen(MessageLogged::class, function (MessageLogged $event) use (&$warnings): void {
            if ($event->level === 'warning') {
                $warnings[] = $event->message;
            }
        });

        $recipient = $this->createUserWithRole(UserRole::CompanyAdmin);
        $this->token($recipient, 'phone', 'android', 'en');

        SendPushNotification::dispatchSync($this->notification($recipient)->id);

        $this->assertTrue(
            collect($warnings)->contains(
                fn (string $message): bool => str_contains($message, 'FIREBASE_CREDENTIALS'),
            ),
        );
        $this->assertDatabaseHas('device_tokens', ['token' => 'phone']);
    }

    public function test_a_push_failure_does_not_fail_the_trip_request(): void
    {
        $this->app->instance(FcmClient::class, FakeFcmClient::down());
        $admin = $this->createUserWithRole(UserRole::CompanyAdmin);
        $this->token($admin, 'admin-phone', 'android', 'en');
        $employee = $this->createUserWithRole(UserRole::Employee);

        Sanctum::actingAs($employee);
        $this->postJson('/api/trip-requests', $this->tripRequestPayload())
            ->assertCreated();

        $this->assertSame(1, Notification::query()->where('user_id', $admin->id)->count());
        $this->assertDatabaseHas('device_tokens', ['token' => 'admin-phone']);
    }

    private function token(User $user, string $token, string $platform, string $locale): void
    {
        DeviceToken::query()->create([
            'user_id' => $user->id,
            'token' => $token,
            'platform' => $platform,
            'locale' => $locale,
            'last_seen_at' => now(),
        ]);
    }

    private function notification(User $user, ?string $tripId = null, ?string $tripRequestId = null): Notification
    {
        return Notification::query()->create([
            'user_id' => $user->id,
            'type' => NotificationType::RequestSubmitted,
            'title_key' => NotificationType::RequestSubmitted->titleKey(),
            'body_key' => NotificationType::RequestSubmitted->bodyKey(),
            'params' => $this->params(),
            'trip_id' => $tripId,
            'trip_request_id' => $tripRequestId,
        ]);
    }

    /**
     * @return array<string, string>
     */
    private function params(): array
    {
        return [
            'requester_name_en' => 'Sara Adel',
            'requester_name_ar' => 'سارة عادل',
            'driver_name_en' => '',
            'driver_name_ar' => '',
            'pickup' => 'Pickup',
            'destination' => 'Destination',
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function messageFor(string $token): array
    {
        foreach ($this->fcm->sent as $message) {
            if (($message['fid'] ?? null) === $token) {
                return $message;
            }
        }

        $this->fail('No push was sent to '.$token);
    }
}
