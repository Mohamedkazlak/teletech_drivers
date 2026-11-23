<?php

declare(strict_types=1);

namespace Tests\Feature\Drivers;

use App\Application\Drivers\Actions\ExportDriverMovementReportAction;
use App\Domain\Enums\AttendanceSource;
use App\Domain\Enums\AvailabilityStatus;
use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Reports\DriverMovementRow;
use App\Domain\Services\DriverMovementReportBuilder;
use App\Models\AttendanceLog;
use App\Models\Place;
use App\Models\Trip;
use App\Models\TripRequest;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Str;
use Tests\Support\CreatesUsers;
use Tests\TestCase;

final class DriverMovementReportTest extends TestCase
{
    use CreatesUsers;
    use RefreshDatabase;

    public function test_export_is_limited_to_admin_roles_and_unknown_drivers_are_404(): void
    {
        $driver = $this->createUserWithRole(UserRole::Driver);
        $query = '/api/drivers/'.$driver->id.'/report/export?period=month&date=2026-09-01';

        $this->actingAsRole(UserRole::Driver)->get($query)->assertForbidden();
        $this->actingAsRole(UserRole::Employee)->get($query)->assertForbidden();

        foreach ([UserRole::Admin, UserRole::CompanyAdmin, UserRole::DriversAdmin] as $role) {
            $response = $this->actingAsRole($role)->get($query);
            $response->assertOk();
            $this->assertStringContainsString('application/pdf', (string) $response->headers->get('content-type'));
            $this->assertStringStartsWith('%PDF', $response->getContent());
            $this->assertStringContainsString(
                'driver-report-'.$driver->id.'-month-2026-09-01.pdf',
                (string) $response->headers->get('content-disposition'),
            );
        }

        $this->actingAsRole(UserRole::Admin)
            ->get('/api/drivers/'.Str::uuid().'/report/export?period=week&date=2026-09-01')
            ->assertNotFound();
    }

    public function test_sheet_rows_for_each_period_and_the_day_rules(): void
    {
        $this->travelTo(Carbon::parse('2026-11-17 12:00:00', 'Africa/Cairo'));

        $admin = $this->createUserWithRole(UserRole::Admin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $driver->name_ar = 'محمود السائق';
        $driver->name_en = 'Mahmoud';
        $driver->save();
        $driver->driverProfile()->update(['car_license' => 'ط ع ب 9295']);

        $hq = Place::factory()->create(['name_ar' => 'الشركة', 'name_en' => 'HQ']);
        $site = Place::factory()->create(['name_ar' => 'الموقع', 'name_en' => 'Site']);
        $deleted = Place::factory()->create(['name_ar' => 'الموقع المحذوف', 'name_en' => 'Gone']);

        $this->presence($driver, AvailabilityStatus::Available, '2026-09-01 08:00:00');
        $this->presence($driver, AvailabilityStatus::FinishedToday, '2026-09-01 16:00:00');
        $this->presence($driver, AvailabilityStatus::FinishedToday, '2026-09-01 17:30:00');

        $this->trip($driver, $admin, $hq, $site, '2026-09-01 09:00:00', '2026-09-01 11:00:00');
        $this->trip($driver, $admin, $site, $hq, '2026-09-01 13:00:00', '2026-09-01 15:30:00');
        $friday = $this->trip($driver, $admin, $hq, $deleted, '2026-09-04 23:30:00', '2026-09-05 01:10:00');
        $deleted->delete();

        $this->grouped($driver, $admin, $hq, $site, '2026-09-02 10:00:00', '2026-09-02 12:00:00');

        $this->trip($driver, $admin, $hq, $site, null, '2026-09-03 18:00:00');
        Trip::factory()->create([
            'driver_id' => $driver->id,
            'created_by' => $admin->id,
            'status' => TripStatus::Completed,
            'scheduled_at' => $this->cairo('2026-09-06 09:00:00'),
            'going_started_at' => $this->cairo('2026-09-06 09:00:00'),
            'finished_at' => $this->cairo('2026-09-06 10:00:00'),
            'driver_showed_up' => false,
            'pickup_summary' => 'hidden',
            'destination_summary' => 'hidden',
        ]);

        $action = app(ExportDriverMovementReportAction::class);
        $month = $action->document($driver->id, 'month', '2026-09-01', 'مشروع النيل');
        $this->assertSame('محمود السائق', $month->driverName);
        $this->assertSame('ط ع ب 9295', $month->plate);
        $this->assertSame('مشروع النيل', $month->project);
        $this->assertSame('شهر سبتمبر 2026', $month->pages[0]->monthLabel);
        $this->assertCount(30, $this->leading($month->pages[0]->rows));

        $first = $this->day($month->pages[0]->rows, '01-Sep-26');
        $this->assertCount(2, $first);
        $this->assertSame('1', $first[0]->dayNumber);
        $this->assertSame('الثلاثاء', $first[0]->weekday);
        $this->assertSame('8.00', $first[0]->arrival);
        $this->assertSame('5.30', $first[0]->departure);
        $this->assertFalse($first[0]->departureIsDefault);
        $this->assertSame('9.00', $first[0]->started);
        $this->assertSame('', $first[1]->dayNumber);
        $this->assertSame('', $first[1]->arrival);
        $this->assertSame('', $first[1]->departure);
        $this->assertFalse($first[1]->departureIsDefault);
        $this->assertSame('1.00', $first[1]->started);
        $this->assertSame('3.30', $first[1]->ended);

        $empty = $this->day($month->pages[0]->rows, '07-Sep-26');
        $this->assertCount(1, $empty);
        $this->assertSame('', $empty[0]->from);
        $this->assertSame('', $empty[0]->arrival);
        $this->assertSame('', $empty[0]->departure);
        $this->assertFalse($empty[0]->departureIsDefault);

        $across = $this->day($month->pages[0]->rows, '04-Sep-26');
        $this->assertTrue($across[0]->friday);
        $this->assertSame('الجمعة', $across[0]->weekday);
        $this->assertSame('الموقع المحذوف', $across[0]->to);
        $this->assertSame('11.30', $across[0]->started);
        $this->assertSame('1.10', $across[0]->ended);
        $this->assertSame('5.00', $across[0]->departure);
        $this->assertTrue($across[0]->departureIsDefault);
        $nextMorning = $this->day($month->pages[0]->rows, '05-Sep-26');
        $this->assertSame([], $nextMorning[0]->from === '' ? [] : ['leaked']);
        $this->assertSame('', $nextMorning[0]->from);
        $this->assertSame('', $nextMorning[0]->departure);
        $this->assertFalse($nextMorning[0]->departureIsDefault);

        $grouped = $this->day($month->pages[0]->rows, '02-Sep-26');
        $this->assertSame('الشركة · الموقع', $grouped[0]->from);
        $this->assertSame('الموقع · الشركة', $grouped[0]->to);
        $this->assertSame('12.00', $grouped[0]->ended);
        $this->assertSame('5.00', $grouped[0]->departure);
        $this->assertTrue($grouped[0]->departureIsDefault);

        $blankEnd = $this->day($month->pages[0]->rows, '03-Sep-26');
        $this->assertSame('', $blankEnd[0]->started);
        $this->assertSame('6.00', $blankEnd[0]->ended);
        $this->assertSame('5.00', $blankEnd[0]->departure);
        $this->assertTrue($blankEnd[0]->departureIsDefault);

        $noShow = $this->day($month->pages[0]->rows, '06-Sep-26');
        $this->assertSame([], $noShow[0]->from === '' ? [] : ['showed']);
        $this->assertSame('', $noShow[0]->from);
        $this->assertSame('', $noShow[0]->departure);
        $this->assertFalse($noShow[0]->departureIsDefault);

        $week = $action->document($driver->id, 'week', '2026-09-01', '');
        $this->assertCount(1, $week->pages);
        $this->assertCount(7, $this->leading($week->pages[0]->rows));

        $year = $action->document($driver->id, 'year', '2026-09-15', '');
        $this->assertCount(12, $year->pages);
        $this->assertSame('شهر يناير 2026', $year->pages[0]->monthLabel);
        $this->assertSame('شهر سبتمبر 2026', $year->pages[8]->monthLabel);

        $pdf = $this->actingAsRole(UserRole::Admin)
            ->get('/api/drivers/'.$driver->id.'/report/export?period=month&date=2026-09-01&project='.urlencode('مشروع النيل'))
            ->assertOk()
            ->getContent();
        $this->assertStringStartsWith('%PDF', $pdf);
        $this->assertSame(1, $this->pdfPageCount($pdf));
        $this->assertPdfContains($pdf, 'تقرير حركة سيارة');
        $this->assertPdfContains($pdf, 'محمود السائق');
        $streams = $pdf.$this->inflate($pdf);
        $this->assertTrue(
            str_contains($streams, '0.851') || str_contains($streams, '0.850') || str_contains($streams, '0.851 0.851 0.851'),
            'Friday rows should be shaded gray.',
        );
        $html = view('reports.driver-movement', [
            'document' => $month,
            'page' => $month->pages[0],
        ])->render();
        $cursor = 0;
        $names = DriverMovementReportBuilder::SIGNATURES;
        foreach ($names as $index => $signature) {
            $at = strpos($html, $signature, $cursor);
            $this->assertNotFalse($at, 'Sheet is missing '.$signature);
            $blank = strpos($html, 'sign-blank-cell', $at);
            $this->assertNotFalse($blank, 'Signature space is missing under '.$signature);
            $next = $names[$index + 1] ?? null;
            if ($next !== null) {
                $nextAt = strpos($html, $next, $at + strlen($signature));
                $this->assertNotFalse($nextAt);
                $this->assertLessThan($nextAt, $blank, 'Signature space must sit under '.$signature);
            }
            $cursor = $blank;
        }
        $this->assertStringNotContainsString('*', $html);
        $this->assertStringContainsString('ملاحظات', $html);
        $this->assertMatchesRegularExpression('/height:\s*22\.00mm/', $html);

        $this->assertNotNull($friday->id);
    }

    public function test_missed_finish_prints_five_only_after_the_cairo_day_ends(): void
    {
        $this->travelTo(Carbon::parse('2026-09-10 15:00:00', 'Africa/Cairo'));

        $admin = $this->createUserWithRole(UserRole::Admin);
        $driver = $this->createUserWithRole(UserRole::Driver);
        $hq = Place::factory()->create(['name_ar' => 'الشركة', 'name_en' => 'HQ']);
        $site = Place::factory()->create(['name_ar' => 'الموقع', 'name_en' => 'Site']);

        $this->trip($driver, $admin, $hq, $site, '2026-09-01 09:00:00', '2026-09-01 10:15:00');
        $this->trip($driver, $admin, $site, $hq, '2026-09-01 13:00:00', '2026-09-01 14:45:00');
        $this->presence($driver, AvailabilityStatus::Available, '2026-09-02 08:00:00');
        $this->presence($driver, AvailabilityStatus::FinishedToday, '2026-09-02 16:40:00');
        $this->presence($driver, AvailabilityStatus::Available, '2026-09-03 08:00:00');
        $this->presence(
            $driver,
            AvailabilityStatus::FinishedToday,
            '2026-09-03 19:00:00',
            approved: false,
        );
        $this->presence($driver, AvailabilityStatus::Available, '2026-09-08 08:05:00');
        $this->presence($driver, AvailabilityStatus::Available, '2026-09-10 09:10:00');
        $this->trip($driver, $admin, $hq, $site, '2026-09-12 09:00:00', '2026-09-12 18:30:00');

        $rows = app(ExportDriverMovementReportAction::class)
            ->document($driver->id, 'month', '2026-09-01', '')
            ->pages[0]
            ->rows;

        $forgot = $this->day($rows, '08-Sep-26');
        $this->assertSame('5.00', $forgot[0]->departure);
        $this->assertTrue($forgot[0]->departureIsDefault);
        $this->assertSame('8.05', $forgot[0]->arrival);

        $today = $this->day($rows, '10-Sep-26');
        $this->assertSame('9.10', $today[0]->arrival);
        $this->assertSame('', $today[0]->departure);
        $this->assertFalse($today[0]->departureIsDefault);

        $idle = $this->day($rows, '04-Sep-26');
        $this->assertSame('', $idle[0]->arrival);
        $this->assertSame('', $idle[0]->from);
        $this->assertSame('', $idle[0]->departure);
        $this->assertFalse($idle[0]->departureIsDefault);

        $explicit = $this->day($rows, '02-Sep-26');
        $this->assertSame('4.40', $explicit[0]->departure);
        $this->assertFalse($explicit[0]->departureIsDefault);

        $rejected = $this->day($rows, '03-Sep-26');
        $this->assertSame('5.00', $rejected[0]->departure);
        $this->assertTrue($rejected[0]->departureIsDefault);

        $many = $this->day($rows, '01-Sep-26');
        $this->assertCount(2, $many);
        $this->assertSame('5.00', $many[0]->departure);
        $this->assertTrue($many[0]->departureIsDefault);
        $this->assertSame('', $many[1]->departure);
        $this->assertFalse($many[1]->departureIsDefault);
        $this->assertSame('2.45', $many[1]->ended);

        $future = $this->day($rows, '12-Sep-26');
        $this->assertSame('6.30', $future[0]->ended);
        $this->assertSame('', $future[0]->departure);
        $this->assertFalse($future[0]->departureIsDefault);
    }

    /**
     * @param  list<DriverMovementRow>  $rows
     * @return list<DriverMovementRow>
     */
    private function day(array $rows, string $date): array
    {
        $matched = [];
        $collecting = false;
        foreach ($rows as $row) {
            if ($row->leading && $row->date === $date) {
                $collecting = true;
                $matched[] = $row;

                continue;
            }
            if ($row->leading) {
                if ($collecting) {
                    break;
                }

                continue;
            }
            if ($collecting) {
                $matched[] = $row;
            }
        }

        return $matched;
    }

    /**
     * @param  list<DriverMovementRow>  $rows
     * @return list<DriverMovementRow>
     */
    private function leading(array $rows): array
    {
        return array_values(array_filter($rows, static fn (DriverMovementRow $row): bool => $row->leading));
    }

    private function cairo(string $wallClock): Carbon
    {
        return Carbon::parse($wallClock, 'Africa/Cairo')->utc();
    }

    private function presence(
        User $driver,
        AvailabilityStatus $status,
        string $cairo,
        bool $approved = true,
    ): void {
        if (! $approved) {
            return;
        }

        $at = $this->cairo($cairo);
        $workDate = $at->copy()->timezone('Africa/Cairo')->toDateString();
        $log = AttendanceLog::query()
            ->where('driver_id', $driver->id)
            ->whereDate('work_date', $workDate)
            ->first() ?? new AttendanceLog([
                'driver_id' => $driver->id,
                'work_date' => $workDate,
            ]);
        if (! $log->exists) {
            $log->id = (string) Str::uuid();
            $log->source = AttendanceSource::Scan;
            $log->checked_in_at = $at;
        }
        if ($status === AvailabilityStatus::Available) {
            if ($log->checked_in_at === null || $at->lt($log->checked_in_at)) {
                $log->checked_in_at = $at;
            }
        } else {
            $log->checked_out_at = $at;
        }
        $log->save();
    }

    private function trip(
        User $driver,
        User $creator,
        Place $from,
        Place $to,
        ?string $startCairo,
        ?string $endCairo,
    ): Trip {
        $trip = Trip::factory()->create([
            'driver_id' => $driver->id,
            'created_by' => $creator->id,
            'status' => TripStatus::Completed,
            'scheduled_at' => $this->cairo($startCairo ?? $endCairo),
            'going_started_at' => $startCairo === null ? null : $this->cairo($startCairo),
            'finished_at' => $endCairo === null ? null : $this->cairo($endCairo),
            'pickup_summary' => 'fallback-from',
            'destination_summary' => 'fallback-to',
        ]);
        TripRequest::factory()->approved()->create([
            'employee_id' => $creator->id,
            'requester_role' => UserRole::Admin,
            'trip_id' => $trip->id,
            'pickup_place_id' => $from->id,
            'pickup_name' => 'اسم احتياطي من',
            'destination_place_id' => $to->id,
            'destination_name' => 'اسم احتياطي إلى',
            'status' => TripRequestStatus::Approved,
        ]);

        return $trip;
    }

    private function grouped(
        User $driver,
        User $creator,
        Place $hq,
        Place $site,
        string $startCairo,
        string $endCairo,
    ): void {
        $trip = $this->trip($driver, $creator, $hq, $site, $startCairo, $endCairo);
        TripRequest::factory()->approved()->create([
            'employee_id' => $creator->id,
            'requester_role' => UserRole::Admin,
            'trip_id' => $trip->id,
            'pickup_place_id' => $site->id,
            'pickup_name' => 'اسم احتياطي من',
            'destination_place_id' => $hq->id,
            'destination_name' => 'اسم احتياطي إلى',
            'status' => TripRequestStatus::Approved,
        ]);
    }

    private function pdfPageCount(string $pdf): int
    {
        preg_match_all('/\/Type\s*\/Page(?!s)/', $pdf, $matches);

        return count($matches[0]);
    }

    private function assertPdfContains(string $pdf, string $text): void
    {
        $utf16 = strtoupper(bin2hex("\xFE\xFF".mb_convert_encoding($text, 'UTF-16BE', 'UTF-8')));
        $raw = "\xFE\xFF".mb_convert_encoding($text, 'UTF-16BE', 'UTF-8');
        $streams = $this->inflate($pdf);
        $this->assertTrue(
            str_contains($pdf, $text)
            || str_contains($pdf, $utf16)
            || str_contains($pdf, $raw)
            || str_contains($streams, $text)
            || str_contains($streams, $raw),
            'PDF is missing '.$text,
        );
    }

    private function inflate(string $pdf): string
    {
        $text = '';
        if (preg_match_all('/stream\r?\n(.*?)\r?\nendstream/s', $pdf, $matches) !== 1 && $matches[1] === []) {
            return '';
        }
        foreach ($matches[1] as $stream) {
            $decoded = @gzuncompress($stream);
            if ($decoded === false) {
                $decoded = @gzinflate($stream);
            }
            if (is_string($decoded)) {
                $text .= $decoded;
            }
        }

        return $text;
    }
}
