<?php

declare(strict_types=1);

namespace App\Broadcasting;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\PrivateChannel;

/**
 * Private channels authorized by role, plus a personal channel per user.
 */
final class RealtimeChannels
{
    public const ADMIN = 'role.admin';

    public const COMPANY_ADMIN = 'role.company-admin';

    public const DRIVERS_ADMIN = 'role.drivers-admin';

    /**
     * Trip and trip-request updates for every staff console, plus the people involved.
     *
     * @param  list<string>  $userIds
     * @return list<PrivateChannel>
     */
    public static function fleet(array $userIds): array
    {
        return self::unique([
            new PrivateChannel(self::ADMIN),
            new PrivateChannel(self::COMPANY_ADMIN),
            new PrivateChannel(self::DRIVERS_ADMIN),
            ...self::users($userIds),
        ]);
    }

    /**
     * Availability reviews for the drivers admin (and system admin) and the driver.
     *
     * @param  list<string>  $userIds
     * @return list<PrivateChannel>
     */
    public static function availability(array $userIds): array
    {
        return self::unique([
            new PrivateChannel(self::ADMIN),
            new PrivateChannel(self::DRIVERS_ADMIN),
            ...self::users($userIds),
        ]);
    }

    /**
     * Live map viewers: system admin and drivers admin.
     *
     * @return list<PrivateChannel>
     */
    public static function liveMap(): array
    {
        return [
            new PrivateChannel(self::ADMIN),
            new PrivateChannel(self::DRIVERS_ADMIN),
        ];
    }

    public static function user(string $userId): PrivateChannel
    {
        return new PrivateChannel('user.'.$userId);
    }

    /**
     * @param  list<Channel>  $channels
     * @return list<string>
     */
    public static function names(array $channels): array
    {
        return array_map(static fn (Channel $channel): string => $channel->name, $channels);
    }

    /**
     * @param  list<string>  $userIds
     * @return list<PrivateChannel>
     */
    private static function users(array $userIds): array
    {
        $channels = [];
        foreach ($userIds as $userId) {
            if ($userId === '') {
                continue;
            }
            $channels[$userId] = self::user($userId);
        }

        return array_values($channels);
    }

    /**
     * @param  list<PrivateChannel>  $channels
     * @return list<PrivateChannel>
     */
    private static function unique(array $channels): array
    {
        $byName = [];
        foreach ($channels as $channel) {
            $byName[$channel->name] = $channel;
        }

        return array_values($byName);
    }
}
