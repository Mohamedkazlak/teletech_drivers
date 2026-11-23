<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: amiri, sans-serif; font-size: 11px; color: #111; direction: rtl; }
        h1 { text-align: center; font-size: 18px; margin: 0 0 8px; }
        .meta { width: 100%; margin-bottom: 8px; }
        .meta td { vertical-align: top; font-size: 12px; padding: 2px 0; }
        .month-box { border: 1px solid #222; text-align: center; font-weight: bold; padding: 6px 8px; }
        table.grid { width: 100%; border-collapse: collapse; }
        table.grid th, table.grid td { border: 1px solid #222; padding: 3px 2px; text-align: center; font-size: 9px; }
        table.grid th { background-color: #f3f3f3; font-weight: bold; }
        tr.friday td { background-color: #d9d9d9; }
        .signatures { width: 100%; margin-top: 16px; }
        td.signatory { width: 25%; text-align: center; vertical-align: top; font-size: 11px; padding: 0 8px; }
        table.sign-blank { width: 88%; margin: 8px auto 0; border-collapse: collapse; }
        td.sign-blank-cell { border-bottom: 1px solid #222; font-size: 11px; }
        .notes-label { font-weight: bold; margin-bottom: 2mm; }
    </style>
</head>
<body>
    <h1>تقرير حركة سيارة</h1>
    <table class="meta">
        <tr>
            <td>
                <div>الاسم : {{ $document->driverName }}</div>
                <div>سيارة رقم : {{ $document->plate }}</div>
                @if ($document->project !== '')
                    <div>مشروع : {{ $document->project }}</div>
                @else
                    <div>مشروع :</div>
                @endif
            </td>
            <td style="width: 28%;">
                <div class="month-box">{{ $page->monthLabel }}</div>
            </td>
        </tr>
    </table>
    <table class="grid">
        <thead>
            <tr>
                <th>رقم</th>
                <th>يوم الاسبوع</th>
                <th>التاريخ</th>
                <th>الحضور بالشركة</th>
                <th>الإنصراف</th>
                <th>الرحلة من</th>
                <th>الرحلة إلى</th>
                <th>بداية الرحلة</th>
                <th>نهاية الرحلة</th>
                <th>توقيع</th>
            </tr>
        </thead>
        <tbody>
            @foreach ($page->rows as $row)
                <tr @class(['friday' => $row->friday])>
                    <td>{{ $row->dayNumber }}</td>
                    <td>{{ $row->weekday }}</td>
                    <td>{{ $row->date }}</td>
                    <td>{{ $row->arrival }}</td>
                    <td>{{ $row->departure }}</td>
                    <td>{{ $row->from }}</td>
                    <td>{{ $row->to }}</td>
                    <td>{{ $row->started }}</td>
                    <td>{{ $row->ended }}</td>
                    <td></td>
                </tr>
            @endforeach
        </tbody>
    </table>
    <table class="signatures">
        <tr>
            @foreach (\App\Domain\Services\DriverMovementReportBuilder::SIGNATURES as $signature)
                <td class="signatory">
                    <div>{{ $signature }}</div>
                    <table class="sign-blank">
                        <tr>
                            <td class="sign-blank-cell" height="46">&nbsp;</td>
                        </tr>
                    </table>
                </td>
            @endforeach
        </tr>
    </table>
    @if ($includeNotes ?? true)
        @include('reports.driver-movement-notes', [
            'notesHeightMm' => $notesHeightMm ?? 22,
        ])
    @endif
</body>
</html>
