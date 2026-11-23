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
 * A fleet change. Payload is the id and status only.
 * Broadcasts after the surrounding database transaction commits.
 */
final class FleetBroadcast implements ShouldBroadcast
{
    use Dispatchable;
    use InteractsWithSockets;
    use SerializesModels;

    public bool $afterCommit = true;

    /**
     * @param  list<string>  $userIds
     * @param  'fleet'|'availability'|'attendance'  $audience
     */
    public function __construct(
        public readonly string $eventName,
        public readonly string $id,
        public readonly string $status,
        public readonly array $userIds = [],
        public readonly string $audience = 'fleet',
    ) {}

    /**
     * @return list<Channel>
     */
    public function broadcastOn(): array
    {
        if ($this->audience === 'availability' || $this->audience === 'attendance') {
            return RealtimeChannels::availability($this->userIds);
        }

        return RealtimeChannels::fleet($this->userIds);
    }

    public function broadcastAs(): string
    {
        return $this->eventName;
    }

    /**
     * @return array{id: string, status: string}
     */
    public function broadcastWith(): array
    {
        return [
            'id' => $this->id,
            'status' => $this->status,
        ];
    }
}
