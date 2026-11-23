<?php

declare(strict_types=1);

namespace App\Models;

use App\Domain\Enums\Branch;
use App\Domain\Enums\TripStatus;
use App\Domain\Enums\UserRole;
use App\Domain\Services\AttendanceClock;
use Illuminate\Database\Eloquent\Builder;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens;

    use HasFactory;
    use HasUuids;
    use Notifiable;
    use SoftDeletes;

    public $incrementing = false;

    protected $keyType = 'string';

    /**
     * @var list<string>
     */
    protected $fillable = [
        'name_en',
        'name_ar',
        'email',
        'password',
        'role',
        'is_active',
        'phone',
        'branch',
        'deleted_by',
        'must_change_password',
    ];

    /**
     * @var list<string>
     */
    protected $hidden = [
        'password',
    ];

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'role' => UserRole::class,
            'branch' => Branch::class,
            'is_active' => 'boolean',
            'must_change_password' => 'boolean',
            'deleted_at' => 'datetime',
        ];
    }

    public function driverProfile(): HasOne
    {
        return $this->hasOne(DriverProfile::class, 'user_id');
    }

    public function favoritePlaces(): BelongsToMany
    {
        return $this->belongsToMany(Place::class, 'driver_favorite_places', 'user_id', 'place_id');
    }

    public function tripRequests(): HasMany
    {
        return $this->hasMany(TripRequest::class, 'employee_id');
    }

    public function drivenTrips(): HasMany
    {
        return $this->hasMany(Trip::class, 'driver_id');
    }

    public function createdTrips(): HasMany
    {
        return $this->hasMany(Trip::class, 'created_by');
    }

    public function attendanceLogs(): HasMany
    {
        return $this->hasMany(AttendanceLog::class, 'driver_id');
    }

    public function todayAttendance(): HasOne
    {
        return $this->hasOne(AttendanceLog::class, 'driver_id')
            ->whereDate('work_date', app(AttendanceClock::class)->today());
    }

    public function activeTrip(): HasOne
    {
        return $this->hasOne(Trip::class, 'driver_id')
            ->whereIn('status', self::activeTripStatuses());
    }

    public function driverLocation(): HasOne
    {
        return $this->hasOne(DriverLocation::class, 'driver_id');
    }

    /**
     * Open check-in today and no trip that is going, at the destination, or returning.
     */
    public function isAvailableNow(): bool
    {
        $log = $this->relationLoaded('todayAttendance')
            ? $this->getRelation('todayAttendance')
            : $this->todayAttendance()->first();

        if (! $log instanceof AttendanceLog || ! $log->isOpen()) {
            return false;
        }

        $active = $this->relationLoaded('activeTrip')
            ? $this->getRelation('activeTrip')
            : $this->activeTrip()->first();

        return $active === null;
    }

    /**
     * @param  Builder<User>  $query
     * @return Builder<User>
     */
    public function scopeCheckedInToday(Builder $query): Builder
    {
        $today = app(AttendanceClock::class)->today();

        return $query->whereHas(
            'attendanceLogs',
            static fn (Builder $logs) => $logs->whereDate('work_date', $today)->whereNull('checked_out_at'),
        );
    }

    /**
     * @param  Builder<User>  $query
     * @return Builder<User>
     */
    public function scopeNotCheckedInToday(Builder $query): Builder
    {
        $today = app(AttendanceClock::class)->today();

        return $query->whereDoesntHave(
            'attendanceLogs',
            static fn (Builder $logs) => $logs->whereDate('work_date', $today)->whereNull('checked_out_at'),
        );
    }

    /**
     * @param  Builder<User>  $query
     * @return Builder<User>
     */
    public function scopeAvailableToday(Builder $query): Builder
    {
        return $query->checkedInToday()->whereDoesntHave(
            'drivenTrips',
            static fn (Builder $trips) => $trips->whereIn('status', self::activeTripStatuses()),
        );
    }

    /**
     * @return list<string>
     */
    public static function activeTripStatuses(): array
    {
        return [
            TripStatus::Going->value,
            TripStatus::AtDestination->value,
            TripStatus::Returning->value,
        ];
    }

    public function deletedByUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'deleted_by');
    }
}
