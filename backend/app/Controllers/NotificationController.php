<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;
use PDO;

class NotificationController {
    public static function index(): void {
        $authUser = AuthMiddleware::authenticate();
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT n.id, n.user_id, n.actor_id, n.type, n.title, n.body, n.entity_type, n.entity_id, n.is_read, n.created_at,
                              u.username, pr.full_name, pr.avatar_url
                              FROM notifications n
                              JOIN users u ON n.actor_id = u.id
                              LEFT JOIN profiles pr ON u.id = pr.user_id
                              WHERE n.user_id = ?
                              ORDER BY n.created_at DESC LIMIT 50");
        $stmt->execute([$authUser['user_id']]);
        $notifications = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success('Notifications list', $notifications);
    }

    public static function markRead(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $notifId = $data['notification_id'] ?? null;

        $db = Database::getConnection();
        if ($notifId) {
            $stmt = $db->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
            $stmt->execute([$notifId, $authUser['user_id']]);
        } else {
            $stmt = $db->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
            $stmt->execute([$authUser['user_id']]);
        }

        Response::success('Notifications marked as read');
    }

    public static function registerDeviceToken(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $token = $data['token'] ?? '';
        $deviceType = $data['device_type'] ?? 'android';

        if (!$token) {
            Response::error('Device token required', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("INSERT INTO device_tokens (user_id, token, device_type) VALUES (?, ?, ?)
                              ON DUPLICATE KEY UPDATE user_id = VALUES(user_id), updated_at = NOW()");
        $stmt->execute([$authUser['user_id'], $token, $deviceType]);

        Response::success('Device token registered');
    }
}
