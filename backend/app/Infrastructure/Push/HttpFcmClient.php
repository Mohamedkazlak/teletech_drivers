<?php

declare(strict_types=1);

namespace App\Infrastructure\Push;

use App\Application\Push\Contracts\FcmClient;
use App\Application\Push\FcmMessageException;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * FCM HTTP v1. Credentials come from the service account JSON only.
 */
final class HttpFcmClient implements FcmClient
{
    private const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';

    private ?string $accessToken = null;

    private int $accessTokenExpiresAt = 0;

    private ?string $projectId = null;

    public function isConfigured(): bool
    {
        return $this->credentialsPath() !== null;
    }

    public function send(array $message): void
    {
        $path = $this->credentialsPath();
        if ($path === null) {
            Log::warning('FIREBASE_CREDENTIALS is missing; push delivery is skipped.');

            return;
        }

        $response = Http::withToken($this->accessToken($path))
            ->acceptJson()
            ->asJson()
            ->timeout(15)
            ->post(
                'https://fcm.googleapis.com/v1/projects/'.$this->projectId($path).'/messages:send',
                ['message' => $message],
            );

        if ($response->successful()) {
            return;
        }

        throw new FcmMessageException(
            errorCode: $this->errorCode($response->json()),
            message: 'FCM rejected the message.',
        );
    }

    private function credentialsPath(): ?string
    {
        $configured = config('firebase.credentials');
        if (! is_string($configured)) {
            return null;
        }

        $configured = trim($configured);
        if ($configured === '') {
            return null;
        }

        $path = $this->isAbsolute($configured) ? $configured : base_path($configured);

        return is_file($path) ? $path : null;
    }

    private function isAbsolute(string $path): bool
    {
        return str_starts_with($path, '/')
            || str_starts_with($path, '\\')
            || (strlen($path) > 2 && ctype_alpha($path[0]) && $path[1] === ':');
    }

    private function accessToken(string $path): string
    {
        if ($this->accessToken !== null && time() < $this->accessTokenExpiresAt) {
            return $this->accessToken;
        }

        $credentials = new ServiceAccountCredentials(self::SCOPE, $path);
        $token = $credentials->fetchAuthToken();
        $access = $token['access_token'] ?? null;
        if (! is_string($access) || $access === '') {
            throw new RuntimeException('FCM access token was not returned.');
        }

        $expiresIn = (int) ($token['expires_in'] ?? 3600);
        $this->accessToken = $access;
        $this->accessTokenExpiresAt = time() + max(60, $expiresIn - 60);

        return $access;
    }

    private function projectId(string $path): string
    {
        if ($this->projectId !== null) {
            return $this->projectId;
        }

        $json = json_decode((string) file_get_contents($path), true);
        $projectId = is_array($json) ? ($json['project_id'] ?? null) : null;
        if (! is_string($projectId) || $projectId === '') {
            throw new RuntimeException('The Firebase service account is missing project_id.');
        }

        $this->projectId = $projectId;

        return $projectId;
    }

    private function errorCode(mixed $body): ?string
    {
        if (! is_array($body)) {
            return null;
        }

        $error = $body['error'] ?? null;
        if (! is_array($error)) {
            return null;
        }

        $details = $error['details'] ?? null;
        if (is_array($details)) {
            foreach ($details as $detail) {
                if (! is_array($detail)) {
                    continue;
                }
                $code = $detail['errorCode'] ?? null;
                if (is_string($code) && $code !== '') {
                    return $code;
                }
            }
        }

        $status = $error['status'] ?? null;
        if (is_string($status) && in_array($status, ['UNREGISTERED', 'INVALID_ARGUMENT'], true)) {
            return $status;
        }

        return null;
    }
}
