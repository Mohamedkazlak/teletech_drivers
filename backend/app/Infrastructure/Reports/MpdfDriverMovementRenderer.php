<?php

declare(strict_types=1);

namespace App\Infrastructure\Reports;

use App\Domain\Reports\DriverMovementDocument;
use Mpdf\Config\ConfigVariables;
use Mpdf\Config\FontVariables;
use Mpdf\HTMLParserMode;
use Mpdf\Mpdf;
use Mpdf\Output\Destination;

final class MpdfDriverMovementRenderer
{
    public function render(DriverMovementDocument $document): string
    {
        $temp = storage_path('framework/mpdf');
        if (! is_dir($temp)) {
            mkdir($temp, 0777, true);
        }

        $fontDir = resource_path('fonts');
        $mpdf = new Mpdf([
            'mode' => 'utf-8',
            'format' => 'A4',
            'orientation' => 'P',
            'margin_left' => 8,
            'margin_right' => 8,
            'margin_top' => 10,
            'margin_bottom' => 10,
            'tempDir' => $temp,
            'fontDir' => array_merge((new ConfigVariables)->getDefaults()['fontDir'], [$fontDir]),
            'fontdata' => (new FontVariables)->getDefaults()['fontdata'] + [
                'amiri' => [
                    'R' => 'Amiri-Regular.ttf',
                    'useOTL' => 0xFF,
                    'useKashida' => 75,
                ],
            ],
            'default_font' => 'amiri',
            'directionality' => 'rtl',
        ]);
        $mpdf->SetDirectionality('rtl');
        $mpdf->SetTitle('TELETECH_TITLE');
        $mpdf->SetAuthor('TELETECH_AUTHOR');

        foreach ($document->pages as $index => $page) {
            if ($index > 0) {
                $mpdf->AddPage();
            }
            $mpdf->WriteHTML(view('reports.driver-movement', [
                'document' => $document,
                'page' => $page,
                'includeNotes' => false,
            ])->render());
            $mpdf->WriteHTML(
                view('reports.driver-movement-notes', [
                    'notesHeightMm' => $this->notesHeightMm($mpdf),
                ])->render(),
                HTMLParserMode::HTML_BODY,
            );
        }

        $pdf = $mpdf->Output('', Destination::STRING_RETURN);

        return str_replace(
            [
                $this->literalMarker('TELETECH_TITLE'),
                $this->literalMarker('TELETECH_AUTHOR'),
            ],
            [
                $this->pdfText('تقرير حركة سيارة'),
                $this->pdfText($document->driverName),
            ],
            $pdf,
        );
    }

    /**
     * Content height of the notes box so its border ends on the bottom margin.
     * Measured after the sheet, because a week and a full month leave different gaps.
     */
    private function notesHeightMm(Mpdf $mpdf): float
    {
        $gapMm = 3.0;
        $paddingMm = 4.0;
        $borderMm = 0.6;
        $safetyMm = 1.5;
        $outer = $mpdf->h - $mpdf->bMargin - $mpdf->y - $gapMm - $safetyMm;

        return max(12.0, round($outer - $paddingMm - $borderMm, 2));
    }

    private function literalMarker(string $ascii): string
    {
        return '('."\xFE\xFF".mb_convert_encoding($ascii, 'UTF-16BE', 'UTF-8').')';
    }

    /**
     * Hex UTF-16 keeps Arabic intact. mPDF's literal strings treat the 0x29
     * byte inside ة as a closing parenthesis and cut the text short.
     */
    private function pdfText(string $text): string
    {
        $utf16 = "\xFE\xFF".mb_convert_encoding($text, 'UTF-16BE', 'UTF-8');

        return '<'.strtoupper(bin2hex($utf16)).'>';
    }
}
