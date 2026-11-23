<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DriverLocation extends Model
{
    public $incrementing = false;

    public $timestamps = false;

    protected $primaryKey = 'driver_id';

    protected $keyType = 'string';

    const UPDATED_AT = 'updated_at';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'driver_id',
        'trip_id',
        'lat',
        'lng',
        'heading',
        'speed',
        'accuracy',
        'is_tracking',
        'updated_at',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'lat' => 'decimal:7',
            'lng' => 'decimal:7',
            'heading' => 'float',
            'speed' => 'float',
            'accuracy' => 'float',
            'is_tracking' => 'boolean',
            'updated_at' => 'datetime',
        ];
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class, 'trip_id');
    }
}
