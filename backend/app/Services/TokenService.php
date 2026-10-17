<?php

namespace App\Services;

class TokenService {
    private static function base64UrlEncode(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    private static function base64UrlDecode(string $data): string {
        return base64_decode(strtr($data, '-_', '+/'));
    }

    public static function generateToken(array $payload): string {
        $config = require __DIR__ . '/../../config/config.php';
        $secret = $config['app']['jwt_secret'];

        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);
        $payload['iat'] = time();
        if (!isset($payload['exp'])) {
            $payload['exp'] = time() + $config['app']['jwt_expires_in'];
        }

        $base64UrlHeader = self::base64UrlEncode($header);
        $base64UrlPayload = self::base64UrlEncode(json_encode($payload));

        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, $secret, true);
        $base64UrlSignature = self::base64UrlEncode($signature);

        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }

    public static function validateToken(string $token): ?array {
        $config = require __DIR__ . '/../../config/config.php';
        $secret = $config['app']['jwt_secret'];

        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        list($header, $payload, $signature) = $parts;

        $validSignature = self::base64UrlEncode(
            hash_hmac('sha256', $header . "." . $payload, $secret, true)
        );

        if (!hash_equals($validSignature, $signature)) {
            return null;
        }

        $payloadData = json_decode(self::base64UrlDecode($payload), true);
        if (!$payloadData || (isset($payloadData['exp']) && $payloadData['exp'] < time())) {
            return null;
        }

        return $payloadData;
    }

    public static function generateOpaqueToken(): string {
        return bin2hex(random_bytes(32));
    }
}
