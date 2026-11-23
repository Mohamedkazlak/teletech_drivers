<?php

declare(strict_types=1);

namespace App\Application\Admin\Actions;

use App\Domain\Entities\AdminDashboard;
use App\Domain\Repositories\AdminDashboardRepositoryInterface;

final class GetAdminDashboardAction
{
    public function __construct(
        private readonly AdminDashboardRepositoryInterface $dashboard,
    ) {}

    public function execute(): AdminDashboard
    {
        return $this->dashboard->summarize();
    }
}
