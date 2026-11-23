<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class EnsurePasswordChangeNotRequired
{
    public const MESSAGE = 'You must change your password before continuing.';

    public const CODE = 'password_change_required';

    /**
     * @var list<string>
     */
    private const ALLOWED_PATHS = [
        'api/auth/change-password',
        'api/auth/logout',
        'api/auth/me',
    ];

    /**
     * @param  Closure(Request): Response  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user !== null && (bool) $user->must_change_password && ! $this->isAllowed($request)) {
            return response()->json([
                'message' => self::MESSAGE,
                'code' => self::CODE,
            ], 403);
        }

        return $next($request);
    }

    private function isAllowed(Request $request): bool
    {
        return in_array($request->path(), self::ALLOWED_PATHS, true);
    }
}
