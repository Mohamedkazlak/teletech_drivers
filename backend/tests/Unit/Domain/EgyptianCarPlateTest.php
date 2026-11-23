<?php

declare(strict_types=1);

namespace Tests\Unit\Domain;

use App\Domain\Drivers\EgyptianCarPlate;
use PHPUnit\Framework\Attributes\DataProvider;
use Tests\TestCase;

final class EgyptianCarPlateTest extends TestCase
{
    /**
     * @return list<array{0: string, 1: string}>
     */
    public static function validPlates(): array
    {
        return [
            ['ط ع ب 9295', 'ط ع ب 9295'],
            ['طعب9295', 'ط ع ب 9295'],
            ['ب 5', 'ب 5'],
            ['ا ب ١٢٣', 'أ ب 123'],
        ];
    }

    #[DataProvider('validPlates')]
    public function test_canonical_form(string $input, string $expected): void
    {
        $this->assertSame($expected, EgyptianCarPlate::canonical($input));
    }

    public function test_rejects_latin_and_incomplete_plates(): void
    {
        $this->assertNull(EgyptianCarPlate::canonical('CAR-1'));
        $this->assertNull(EgyptianCarPlate::canonical('ط ع ب'));
        $this->assertNull(EgyptianCarPlate::canonical('9295'));
        $this->assertNull(EgyptianCarPlate::canonical('ط ع ب ج 1'));
    }
}
