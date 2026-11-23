<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Enums\TripStatus;
use App\Domain\Exceptions\InvalidTripStatusTransitionException;
use App\Domain\Services\TripStatusTransitions;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\TestCase;

final class TripStatusTransitionsTest extends TestCase
{
    private TripStatusTransitions $transitions;

    protected function setUp(): void
    {
        parent::setUp();
        $this->transitions = new TripStatusTransitions;
    }

    /**
     * @return list<array{0: TripStatus, 1: TripStatus, 2: bool}>
     */
    public static function transitionTable(): array
    {
        $rows = [];
        foreach (TripStatus::cases() as $from) {
            foreach (TripStatus::cases() as $to) {
                $allowed = match ($from) {
                    TripStatus::Unassigned => in_array($to, [TripStatus::Assigned, TripStatus::Cancelled], true),
                    TripStatus::Assigned => in_array($to, [TripStatus::Going, TripStatus::Cancelled], true),
                    TripStatus::Going => $to === TripStatus::AtDestination,
                    TripStatus::AtDestination => $to === TripStatus::Returning,
                    TripStatus::Returning => $to === TripStatus::Completed,
                    TripStatus::Completed, TripStatus::Cancelled => false,
                };
                $rows[] = [$from, $to, $allowed];
            }
        }

        return $rows;
    }

    #[DataProvider('transitionTable')]
    public function test_exhaustive_transition_table(TripStatus $from, TripStatus $to, bool $allowed): void
    {
        $this->assertSame($allowed, $this->transitions->canTransition($from, $to));

        if ($allowed) {
            $this->transitions->assertTransition($from, $to);
            $this->assertTrue(true);
        } else {
            $this->expectException(InvalidTripStatusTransitionException::class);
            $this->transitions->assertTransition($from, $to);
        }
    }

    public function test_reassign_only_when_assigned(): void
    {
        $this->assertTrue($this->transitions->canReassign(TripStatus::Assigned));
        $this->assertFalse($this->transitions->canReassign(TripStatus::Unassigned));
        $this->assertFalse($this->transitions->canReassign(TripStatus::Going));
    }
}
