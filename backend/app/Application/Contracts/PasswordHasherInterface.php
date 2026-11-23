<?php

declare(strict_types=1);

namespace App\Application\Contracts;

interface PasswordHasherInterface
{
    public function hash(string $plainPassword): string;

    public function check(string $plainPassword, string $hashedPassword): bool;
}
