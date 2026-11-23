<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Application\Push\Contracts\FcmClient;
use App\Application\Push\FcmMessageException;
use RuntimeException;
use Throwable;

final class FakeFcmClient implements FcmClient
{
    /**
     * @var list<array<string, mixed>>
     */
    public array $sent = [];

    /**
     * Token value => FCM error code. Those sends throw instead of being recorded.
     *
     * @var array<string, string>
     */
    public array $rejected = [];

    public ?Throwable $failure = null;

    public bool $configured = true;

    public function isConfigured(): bool
    {
        return $this->configured;
    }

    public function send(array $message): void
    {
        if ($this->failure !== null) {
            throw $this->failure;
        }

        $token = (string) ($message['fid'] ?? '');
        if (isset($this->rejected[$token])) {
            throw new FcmMessageException($this->rejected[$token], 'FCM rejected the message.');
        }

        $this->sent[] = $message;
    }

    public static function down(string $message = 'fcm down'): self
    {
        $client = new self;
        $client->failure = new RuntimeException($message);

        return $client;
    }
}
