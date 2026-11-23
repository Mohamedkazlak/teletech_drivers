<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\PlaceFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Place extends Model
{
    /** @use HasFactory<PlaceFactory> */
    use HasFactory;

    use HasUuids;
    use SoftDeletes;

    public $incrementing = false;

    protected $keyType = 'string';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'name_en',
        'name_ar',
        'latitude',
        'longitude',
        'address',
        'is_headquarters',
        'is_active',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'latitude' => 'decimal:7',
            'longitude' => 'decimal:7',
            'is_headquarters' => 'boolean',
            'is_active' => 'boolean',
            'deleted_at' => 'datetime',
        ];
    }

    public function favoritedByDrivers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'driver_favorite_places', 'place_id', 'user_id');
    }

    public function pickupTripRequests(): HasMany
    {
        return $this->hasMany(TripRequest::class, 'pickup_place_id');
    }

    public function destinationTripRequests(): HasMany
    {
        return $this->hasMany(TripRequest::class, 'destination_place_id');
    }

}
