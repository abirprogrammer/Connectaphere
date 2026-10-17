<?php

namespace App\Controllers;

use App\Services\Database;
use App\Services\Response;
use App\Services\TokenService;
use App\Validators\Validator;
use PDO;

class AuthController {
    public static function register(): void {
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $validated = Validator::validate($data, [
            'username' => 'required|min:3|max:50',
            'email' => 'required|email|max:150',
            'password' => 'required|min:6',
            'full_name' => 'required|min:2|max:100'
        ]);

        $db = Database::getConnection();

        // Check unique username & email
        $stmt = $db->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
        $stmt->execute([$validated['username'], $validated['email']]);
        if ($stmt->fetch()) {
            Response::error('Username or email already exists.', 409);
        }

        $db->beginTransaction();
        try {
            $passwordHash = password_hash($data['password'], PASSWORD_BCRYPT);

            $stmt = $db->prepare("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)");
            $stmt->execute([$validated['username'], $validated['email'], $passwordHash]);
            $userId = $db->lastInsertId();

            $stmt = $db->prepare("INSERT INTO profiles (user_id, full_name) VALUES (?, ?)");
            $stmt->execute([$userId, $validated['full_name']]);

            $db->commit();

            $accessToken = TokenService::generateToken(['user_id' => $userId, 'username' => $validated['username']]);
            $refreshToken = TokenService::generateOpaqueToken();
            $refreshTokenHash = password_hash($refreshToken, PASSWORD_BCRYPT);

            $stmt = $db->prepare("INSERT INTO sessions (user_id, refresh_token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))");
            $stmt->execute([$userId, $refreshTokenHash]);

            Response::success('User registered successfully', [
                'user' => [
                    'id' => (int)$userId,
                    'username' => $validated['username'],
                    'email' => $validated['email'],
                    'full_name' => $validated['full_name'],
                    'avatar_url' => null,
                ],
                'access_token' => $accessToken,
                'refresh_token' => $refreshToken,
            ], 201);
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error('Registration failed: ' . $e->getMessage(), 500);
        }
    }

    public static function login(): void {
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $validated = Validator::validate($data, [
            'email' => 'required|email',
            'password' => 'required'
        ]);

        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT u.id, u.username, u.email, u.password_hash, u.status, p.full_name, p.avatar_url
                              FROM users u
                              LEFT JOIN profiles p ON u.id = p.user_id
                              WHERE u.email = ?");
        $stmt->execute([$validated['email']]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user || !password_verify($data['password'], $user['password_hash'])) {
            Response::error('Invalid credentials', 401);
        }

        if ($user['status'] === 'suspended') {
            Response::error('Account is suspended', 403);
        }

        $accessToken = TokenService::generateToken(['user_id' => $user['id'], 'username' => $user['username']]);
        $refreshToken = TokenService::generateOpaqueToken();
        $refreshTokenHash = password_hash($refreshToken, PASSWORD_BCRYPT);

        $stmt = $db->prepare("INSERT INTO sessions (user_id, refresh_token_hash, expires_at) VALUES (?, ?, DATE_ADD(NOW(), INTERVAL 30 DAY))");
        $stmt->execute([$user['id'], $refreshTokenHash]);

        Response::success('Login successful', [
            'user' => [
                'id' => (int)$user['id'],
                'username' => $user['username'],
                'email' => $user['email'],
                'full_name' => $user['full_name'],
                'avatar_url' => $user['avatar_url'],
            ],
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken,
        ]);
    }

    public static function logout(): void {
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $db = Database::getConnection();

        if (!empty($data['refresh_token'])) {
            // Revoke active refresh token
            $stmt = $db->prepare("UPDATE sessions SET is_revoked = 1 WHERE is_revoked = 0");
            $stmt->execute();
        }

        Response::success('Logged out successfully');
    }

    public static function resetPassword(): void {
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $validated = Validator::validate($data, [
            'email' => 'required|email',
            'new_password' => 'required|min:6'
        ]);

        $db = Database::getConnection();
        $newHash = password_hash($data['new_password'], PASSWORD_BCRYPT);

        $stmt = $db->prepare("UPDATE users SET password_hash = ? WHERE email = ?");
        $stmt->execute([$newHash, $validated['email']]);

        if ($stmt->rowCount() > 0) {
            Response::success('Password reset successfully');
        } else {
            Response::error('User with this email not found', 404);
        }
    }
}
