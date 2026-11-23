<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Application\Attendance\Actions\AdjustAttendanceAction;
use App\Application\Attendance\Actions\CheckInAction;
use App\Application\Attendance\Actions\CheckOutAction;
use App\Application\Attendance\Actions\ListAttendanceAction;
use App\Application\Attendance\Actions\ShowTodayAttendanceAction;
use App\Application\Attendance\Actions\TodayAttendanceSummaryAction;
use App\Domain\Enums\UserRole;
use App\Domain\Exceptions\UserNotFoundException;
use App\Domain\Services\AttendanceQr;
use App\Http\Controllers\Controller;
use App\Http\Requests\Attendance\AdjustAttendanceRequest;
use App\Http\Requests\Attendance\ListAttendanceRequest;
use App\Http\Requests\Attendance\ScanAttendanceRequest;
use App\Http\Resources\AttendanceDayResource;
use App\Http\Resources\AttendanceLogResource;
use App\Models\AttendanceLog;
use App\Models\User;
use Illuminate\Http\JsonResponse;

final class AttendanceController extends Controller
{
    public function checkIn(ScanAttendanceRequest $request, CheckInAction $action): JsonResponse
    {
        $this->authorize('scan', AttendanceLog::class);

        return (new AttendanceLogResource($action->execute($request->toDto())))
            ->response()
            ->setStatusCode(201);
    }

    public function checkOut(ScanAttendanceRequest $request, CheckOutAction $action): AttendanceLogResource
    {
        $this->authorize('scan', AttendanceLog::class);

        return new AttendanceLogResource($action->execute($request->toDto()));
    }

    public function today(ShowTodayAttendanceAction $action): JsonResponse
    {
        $this->authorize('viewOwn', AttendanceLog::class);

        /** @var User $user */
        $user = request()->user();
        $result = $action->execute((string) $user->id);

        return response()->json([
            'work_date' => $result['work_date'],
            'status' => $result['status'],
            'attendance' => $result['attendance'] === null
                ? null
                : (new AttendanceLogResource($result['attendance']))->resolve(),
        ]);
    }

    public function mine(ListAttendanceRequest $request, ListAttendanceAction $action): JsonResponse
    {
        $this->authorize('viewOwn', AttendanceLog::class);

        /** @var User $user */
        $user = $request->user();

        return $this->history($action->execute($request->toDto((string) $user->id)));
    }

    public function index(ListAttendanceRequest $request, ListAttendanceAction $action): JsonResponse
    {
        $this->authorize('viewAny', AttendanceLog::class);

        return $this->history($action->execute($request->toDto()));
    }

    public function summary(TodayAttendanceSummaryAction $action): JsonResponse
    {
        $this->authorize('viewAny', AttendanceLog::class);

        return response()->json(['data' => $action->execute()]);
    }

    public function driverHistory(
        string $id,
        ListAttendanceRequest $request,
        ListAttendanceAction $action,
    ): JsonResponse {
        $this->authorize('viewAny', AttendanceLog::class);

        $driver = User::query()->whereKey($id)->first();
        if ($driver === null || $driver->role !== UserRole::Driver) {
            throw new UserNotFoundException;
        }

        return $this->history($action->execute($request->toDto($id)));
    }

    public function qr(AttendanceQr $qr): JsonResponse
    {
        $this->authorize('viewQr', AttendanceLog::class);

        return response()->json([
            'payload' => $qr->payload(),
            'hq_name' => (string) config('attendance.hq_name', 'Company Headquarters'),
            'version' => (int) config('attendance.qr_version', 1),
        ]);
    }

    public function adjust(AdjustAttendanceRequest $request, AdjustAttendanceAction $action): AttendanceLogResource
    {
        $this->authorize('adjust', AttendanceLog::class);

        return new AttendanceLogResource($action->execute($request->toDto()));
    }

    /**
     * @param  array{page: \App\Domain\Shared\PaginatedResult<mixed>, totals: array{days_present: int, days_absent: int, total_on_site_hours: float}}  $result
     */
    private function history(array $result): JsonResponse
    {
        $page = $result['page'];

        return response()->json([
            'data' => array_map(
                static fn ($item): array => (new AttendanceDayResource($item))->resolve(),
                $page->items,
            ),
            'totals' => $result['totals'],
            'meta' => [
                'current_page' => $page->page,
                'per_page' => $page->perPage,
                'total' => $page->total,
                'last_page' => $page->lastPage(),
            ],
        ]);
    }
}
