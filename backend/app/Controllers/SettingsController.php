<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;

class SettingsController {
    public static function updateTheme(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $theme = $data['theme'] ?? 'system'; // light, dark, system

        if (!in_array($theme, ['light', 'dark', 'system'])) {
            Response::error('Invalid theme preference', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("UPDATE profiles SET theme_preference = ? WHERE user_id = ?");
        $stmt->execute([$theme, $authUser['user_id']]);

        Response::success('Theme preference updated', ['theme' => $theme]);
    }

    public static function deleteAccount(): void {
        $authUser = AuthMiddleware::authenticate();
        $db = Database::getConnection();

        $stmt = $db->prepare("DELETE FROM users WHERE id = ?");
        $stmt->execute([$authUser['user_id']]);

        Response::success('Account deleted successfully');
    }
}
