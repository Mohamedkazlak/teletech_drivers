<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum UserRole: string
{
    case Admin = 'admin';
    case CompanyAdmin = 'company_admin';
    case DriversAdmin = 'drivers_admin';
    case Driver = 'driver';
    case Employee = 'employee';
}
