<?php

declare(strict_types=1);

namespace App\Models;

use App\Domain\Enums\TripRequestStatus;
use App\Domain\Enums\UserRole;
use App\Models\Concerns\ScopesFleetPeriod;
use Database\Factories\TripRequestFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TripRequest extends Model
{
    /** @use HasFactory<TripRequestFactory> */
    use HasFactory;

    use HasUuids;
    use ScopesFleetPeriod;

    public $incrementing = false;

    protected $keyType = 'string';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'employee_id',
        'requester_role',
        'pickup_place_id',
        'pickup_name',
        'pickup_lat',
        'pickup_lng',
        'pickup_address',
        'destination_place_id',
        'destination_name',
        'destination_lat',
        'destination_lng',
        'destination_address',
        'requested_at',
        'notes',
        'status',
        'trip_id',
        'rejection_reason',
        'handled_by',
        'handled_at',
        'approved_at',
        'auto_approved',
        'suggested_group_id',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'requester_role' => UserRole::class,
            'status' => TripRequestStatus::class,
            'requested_at' => 'datetime',
            'handled_at' => 'datetime',
            'approved_at' => 'datetime',
            'auto_approved' => 'boolean',
            'pickup_lat' => 'decimal:7',
            'pickup_lng' => 'decimal:7',
            'destination_lat' => 'decimal:7',
            'destination_lng' => 'decimal:7',
        ];
    }

    public function employee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'employee_id');
    }

    public function pickupPlace(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'pickup_place_id');
    }

    public function destinationPlace(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'destination_place_id');
    }

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class, 'trip_id');
    }

    public function handler(): BelongsTo
    {
        return $this->belongsTo(User::class, 'handled_by');
    }
}
