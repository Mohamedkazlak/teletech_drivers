<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Enums\HqDistanceBand;
use App\Domain\Services\HqDistanceClassifier;
use PHPUnit\Framework\TestCase;

final class HqDistanceClassifierTest extends TestCase
{
    private HqDistanceClassifier $classifier;

    protected function setUp(): void
    {
        parent::setUp();
        $this->classifier = new HqDistanceClassifier(200, 1000);
    }

    public function test_boundaries(): void
    {
        $this->assertSame(HqDistanceBand::Near, $this->classifier->classify(0));
        $this->assertSame(HqDistanceBand::Near, $this->classifier->classify(200));
        $this->assertSame(HqDistanceBand::Medium, $this->classifier->classify(201));
        $this->assertSame(HqDistanceBand::Medium, $this->classifier->classify(1000));
        $this->assertSame(HqDistanceBand::Far, $this->classifier->classify(1001));
        $this->assertSame(HqDistanceBand::Unknown, $this->classifier->classify(null));
        $this->assertSame(HqDistanceBand::Unknown, $this->classifier->classify(-1));
    }
}
