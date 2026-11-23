<?php

declare(strict_types=1);

namespace App\Application\Drivers\Actions;

use App\Domain\Reports\DriverMovementDocument;
use App\Domain\Services\DriverMovementReportBuilder;
use App\Domain\Services\FleetPeriodRange;
use App\Infrastructure\Reports\EloquentDriverMovementSource;
use App\Infrastructure\Reports\MpdfDriverMovementRenderer;
use App\Models\DriverProfile;
use App\Models\User;
use DateTimeZone;

final class ExportDriverMovementReportAction
{
    public function __construct(
        private readonly EloquentDriverMovementSource $source,
        private readonly DriverMovementReportBuilder $builder,
        private readonly MpdfDriverMovementRenderer $renderer,
        private readonly FleetPeriodRange $periods,
    ) {}

    public function document(string $driverId, string $period, string $date, string $project): DriverMovementDocument
    {
        $driver = User::query()->whereKey($driverId)->firstOrFail();
        $profile = DriverProfile::query()->where('user_id', $driverId)->first();
        $bounds = $this->periods->containing($period, $date);
        $utc = new DateTimeZone('UTC');
        $start = $bounds['start']->setTimezone($utc)->modify('-2 days');
        $end = $bounds['end_exclusive']->setTimezone($utc)->modify('+2 days');
        $arabic = trim((string) $driver->name_ar);
        $name = $arabic !== '' ? $arabic : trim((string) $driver->name_en);

        return new DriverMovementDocument(
            driverName: $name,
            plate: trim((string) ($profile->car_license ?? '')),
            project: trim($project),
            pages: $this->builder->pages(
                $period,
                $date,
                $this->source->trips($driverId, $start, $end),
                $this->source->presence($driverId, $start, $end),
            ),
        );
    }

    public function pdf(string $driverId, string $period, string $date, string $project): string
    {
        return $this->renderer->render($this->document($driverId, $period, $date, $project));
    }
}
