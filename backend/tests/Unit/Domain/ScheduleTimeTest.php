<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Services\ScheduleTime;
use DateTimeImmutable;
use DateTimeZone;
use Illuminate\Support\Carbon;
use Tests\TestCase;

final class ScheduleTimeTest extends TestCase
{
    public function test_past_and_future_are_instants_in_the_business_timezone(): void
    {
        $this->travelTo(Carbon::parse('2026-11-16 14:00:00', 'Africa/Cairo'));

        $clock = new ScheduleTime(new DateTimeZone('Africa/Cairo'));

        $this->assertTrue($clock->isNotFuture(new DateTimeImmutable('2026-11-16T11:59:00+00:00')));
        $this->assertTrue($clock->isNotFuture(new DateTimeImmutable('2026-11-16T14:00:00+02:00')));
        $this->assertFalse($clock->isNotFuture(new DateTimeImmutable('2026-11-16T12:01:00+00:00')));
    }
}
