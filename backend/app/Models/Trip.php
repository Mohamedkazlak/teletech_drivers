<?php

declare(strict_types=1);

namespace App\Models;

use App\Domain\Enums\TripConfirmationStatus;
use App\Domain\Enums\TripStatus;
use App\Models\Concerns\ScopesFleetPeriod;
use Database\Factories\TripFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Trip extends Model
{
    /** @use HasFactory<TripFactory> */
    use HasFactory;

    use HasUuids;
    use ScopesFleetPeriod;

    public $incrementing = false;

    protected $keyType = 'string';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'driver_id',
        'assigned_at',
        'scheduled_at',
        'status',
        'created_by',
        'pickup_summary',
        'destination_summary',
        'going_started_at',
        'going_ended_at',
        'return_started_at',
        'finished_at',
        'start_lat',
        'start_lng',
        'going_distance_m',
        'return_distance_m',
        'total_distance_m',
        'going_route',
        'return_route',
        'confirmation_status',
        'confirmation_requested_at',
        'confirmed_at',
        'confirmed_by',
        'driver_showed_up',
        'confirmation_note',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'status' => TripStatus::class,
            'confirmation_status' => TripConfirmationStatus::class,
            'confirmation_requested_at' => 'datetime',
            'confirmed_at' => 'datetime',
            'driver_showed_up' => 'boolean',
            'assigned_at' => 'datetime',
            'scheduled_at' => 'datetime',
            'going_started_at' => 'datetime',
            'going_ended_at' => 'datetime',
            'return_started_at' => 'datetime',
            'finished_at' => 'datetime',
            'start_lat' => 'decimal:7',
            'start_lng' => 'decimal:7',
            'going_distance_m' => 'integer',
            'return_distance_m' => 'integer',
            'total_distance_m' => 'integer',
        ];
    }

    /**
     * Rows the admin dashboard counts as unconfirmed_trips.
     *
     * The 24h auto-complete command writes this status when the window
     * closes with no employee report. List filters use this same scope.
     *
     * @param  Builder<Trip>  $query
     * @return Builder<Trip>
     */
    public function scopeWhereUnconfirmed(Builder $query, bool $unconfirmed): Builder
    {
        $column = $query->qualifyColumn('confirmation_status');

        if ($unconfirmed) {
            return $query->where($column, TripConfirmationStatus::Unconfirmed);
        }

        return $query->where(function (Builder $inner) use ($column): void {
            $inner->where($column, '!=', TripConfirmationStatus::Unconfirmed->value)
                ->orWhereNull($column);
        });
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function confirmedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'confirmed_by');
    }

    public function tripRequests(): HasMany
    {
        return $this->hasMany(TripRequest::class, 'trip_id');
    }

    public function driverLocation(): HasOne
    {
        return $this->hasOne(DriverLocation::class, 'trip_id');
    }
}
