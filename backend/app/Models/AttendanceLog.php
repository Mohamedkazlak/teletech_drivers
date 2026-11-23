<?php

declare(strict_types=1);

namespace App\Models;

use App\Domain\Enums\AttendanceSource;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class AttendanceLog extends Model
{
    use HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'driver_id',
        'work_date',
        'checked_in_at',
        'check_in_lat',
        'check_in_lng',
        'check_in_accuracy_m',
        'check_in_distance_m',
        'checked_out_at',
        'check_out_lat',
        'check_out_lng',
        'check_out_accuracy_m',
        'check_out_distance_m',
        'source',
        'adjusted_by',
        'adjustment_reason',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'work_date' => 'date',
            'checked_in_at' => 'datetime',
            'checked_out_at' => 'datetime',
            'check_in_lat' => 'float',
            'check_in_lng' => 'float',
            'check_in_accuracy_m' => 'float',
            'check_in_distance_m' => 'integer',
            'check_out_lat' => 'float',
            'check_out_lng' => 'float',
            'check_out_accuracy_m' => 'float',
            'check_out_distance_m' => 'integer',
            'source' => AttendanceSource::class,
        ];
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function adjuster(): BelongsTo
    {
        return $this->belongsTo(User::class, 'adjusted_by');
    }

    public function isOpen(): bool
    {
        return $this->checked_out_at === null;
    }

    public function status(): string
    {
        return $this->isOpen() ? 'checked_in' : 'checked_out';
    }

    public function onSiteHours(): ?float
    {
        if ($this->checked_out_at === null || $this->checked_in_at === null) {
            return null;
        }

        $seconds = $this->checked_out_at->getTimestamp() - $this->checked_in_at->getTimestamp();

        return round(max(0, $seconds) / 3600, 2);
    }

    public function workDateString(): string
    {
        return $this->work_date->format('Y-m-d');
    }
}
