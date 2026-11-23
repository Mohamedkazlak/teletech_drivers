<?php

declare(strict_types=1);

namespace App\Infrastructure\Auth;

use App\Application\Contracts\TokenIssuerInterface;
use App\Domain\Entities\User as UserEntity;
use App\Domain\Exceptions\UserNotFoundException;
use App\Models\User as UserModel;
use Laravel\Sanctum\PersonalAccessToken;

final class SanctumTokenIssuer implements TokenIssuerInterface
{
    public function issue(UserEntity $user, string $tokenName = 'auth'): string
    {
        $model = UserModel::query()->find($user->id);

        if ($model === null) {
            throw new UserNotFoundException;
        }

        return $model->createToken($tokenName)->plainTextToken;
    }

    public function revokeCurrentToken(string $userId): void
    {
        $token = $this->resolveCurrentAccessToken($userId);

        if ($token !== null) {
            $token->delete();

            return;
        }

        $this->revokeAllTokens($userId);
    }

    public function revokeOtherTokens(string $userId): void
    {
        $current = $this->resolveCurrentAccessToken($userId);

        $query = PersonalAccessToken::query()
            ->where('tokenable_type', UserModel::class)
            ->where('tokenable_id', $userId);

        if ($current !== null) {
            $query->whereKeyNot($current->getKey());
        }

        $query->delete();
    }

    private function resolveCurrentAccessToken(string $userId): ?PersonalAccessToken
    {
        $authenticated = request()->user();

        if ($authenticated instanceof UserModel && (string) $authenticated->getAuthIdentifier() === $userId) {
            $token = $authenticated->currentAccessToken();

            if ($token instanceof PersonalAccessToken) {
                return $token;
            }
        }

        $bearer = request()->bearerToken();

        if (is_string($bearer) && $bearer !== '') {
            $accessToken = PersonalAccessToken::findToken($bearer);

            if ($accessToken instanceof PersonalAccessToken
                && (string) $accessToken->tokenable_id === $userId
            ) {
                return $accessToken;
            }
        }

        return null;
    }

    public function revokeAllTokens(string $userId): void
    {
        PersonalAccessToken::query()
            ->where('tokenable_type', UserModel::class)
            ->where('tokenable_id', $userId)
            ->delete();
    }
}
