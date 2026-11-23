<?php

declare(strict_types=1);

namespace App\Domain\Repositories;

use App\Domain\Entities\AdminDashboard;

interface AdminDashboardRepositoryInterface
{
    public function summarize(): AdminDashboard;
}
