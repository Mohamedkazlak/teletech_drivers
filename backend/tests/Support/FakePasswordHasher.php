<?php

declare(strict_types=1);

namespace Tests\Support;

use App\Application\Contracts\PasswordHasherInterface;

final class FakePasswordHasher implements PasswordHasherInterface
{
    public function hash(string $plainPassword): string
    {
        return 'hash:'.$plainPassword;
    }

    public function check(string $plainPassword, string $hashedPassword): bool
    {
        return $hashedPassword === $this->hash($plainPassword);
    }
}
