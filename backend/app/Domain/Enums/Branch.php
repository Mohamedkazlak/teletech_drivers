<?php

declare(strict_types=1);

namespace App\Domain\Enums;

enum Branch: string
{
    case CompanyHeadquarters = 'company_headquarters';
    case NewHeadquarters = 'new_headquarters';
}
