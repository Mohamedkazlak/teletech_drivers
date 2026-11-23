<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

final class SetLocaleFromHeader
{
    public function handle(Request $request, Closure $next): Response
    {
        $header = (string) $request->header('Accept-Language', 'en');
        $primary = strtolower(trim(explode(',', $header)[0] ?? 'en'));
        $primary = trim(explode(';', $primary)[0] ?? 'en');
        $language = explode('-', $primary)[0] ?? 'en';

        app()->setLocale(in_array($language, ['en', 'ar'], true) ? $language : 'en');

        return $next($request);
    }
}
