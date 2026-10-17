<?php

namespace App\Middleware;

use App\Services\TokenService;
use App\Services\Response;

class AuthMiddleware {
    public static function authenticate(): array {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';

        if (!$authHeader || !preg_match('/Bearer\s(\S+)/', $authHeader, $matches)) {
            Response::error('Unauthorized: Missing or invalid token', 401);
        }

        $token = $matches[1];
        $payload = TokenService::validateToken($token);

        if (!$payload) {
            Response::error('Unauthorized: Invalid or expired token', 401);
        }

        return $payload;
    }
}
