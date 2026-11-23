<?php

declare(strict_types=1);

namespace App\Domain\Drivers;

/**
 * Egyptian private-vehicle plate: 1–3 traffic letters and 1–4 digits.
 *
 * Stored as letters separated by spaces, then the number: "ط ع ب 9295".
 * The letter set is the metal-plate alphabet used by Egyptian traffic.
 */
final class EgyptianCarPlate
{
    public const ALLOWED_LETTERS = 'أبجدرسصطعفقلمنهوي';

    public static function canonical(string $value): ?string
    {
        $compact = self::compact($value);
        $pattern = '/^(['.self::ALLOWED_LETTERS.']{1,3})(\d{1,4})$/u';
        if (preg_match($pattern, $compact, $matches) !== 1) {
            return null;
        }

        $letters = preg_split('//u', $matches[1], -1, PREG_SPLIT_NO_EMPTY);
        if ($letters === false || $letters === []) {
            return null;
        }

        return implode(' ', $letters).' '.$matches[2];
    }

    private static function compact(string $value): string
    {
        $value = strtr($value, [
            'إ' => 'أ',
            'آ' => 'أ',
            'ا' => 'أ',
            'ٱ' => 'أ',
            'ـ' => '',
            '٠' => '0',
            '١' => '1',
            '٢' => '2',
            '٣' => '3',
            '٤' => '4',
            '٥' => '5',
            '٦' => '6',
            '٧' => '7',
            '٨' => '8',
            '٩' => '9',
            '۰' => '0',
            '۱' => '1',
            '۲' => '2',
            '۳' => '3',
            '۴' => '4',
            '۵' => '5',
            '۶' => '6',
            '۷' => '7',
            '۸' => '8',
            '۹' => '9',
        ]);

        $compact = preg_replace('/\s+/u', '', $value);

        return $compact ?? $value;
    }
}
