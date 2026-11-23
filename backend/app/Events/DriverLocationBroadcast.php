<?php

declare(strict_types=1);

namespace App\Events;

use App\Broadcasting\RealtimeChannels;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * A driver's latest fix for the live map.
 * Broadcasts after the location row commits.
 */
final class DriverLocationBroadcast implements ShouldBroadcast
{
    use Dispatchable;
    use InteractsWithSockets;
    use SerializesModels;

    public bool $afterCommit = true;

    public function __construct(
        public readonly string $driverId,
        public readonly ?string $tripId,
        public readonly float $lat,
        public readonly float $lng,
        public readonly string $status,
    ) {}

    /**
     * @return list<Channel>
     */
    public function broadcastOn(): array
    {
        return RealtimeChannels::liveMap();
    }

    public function broadcastAs(): string
    {
        return 'driver-location.updated';
    }

    /**
     * @return array{id: string, status: string, trip_id: string|null, lat: float, lng: float}
     */
    public function broadcastWith(): array
    {
        return [
            'id' => $this->driverId,
            'status' => $this->status,
            'trip_id' => $this->tripId,
            'lat' => $this->lat,
            'lng' => $this->lng,
        ];
    }
}
