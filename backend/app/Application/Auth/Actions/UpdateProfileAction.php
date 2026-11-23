<?php

declare(strict_types=1);

namespace App\Application\Auth\Actions;

use App\Application\Auth\DTOs\UpdateProfileData;
use App\Domain\Entities\User;
use App\Domain\Repositories\UserRepositoryInterface;

final class UpdateProfileAction
{
    public function __construct(
        private readonly UserRepositoryInterface $users,
    ) {}

    public function execute(UpdateProfileData $data): User
    {
        return $this->users->updateProfile($data->userId, $data->changes);
    }
}
