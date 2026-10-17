<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;
use PDO;

class StoryController {
    public static function index(): void {
        $authUser = AuthMiddleware::authenticate();
        $db = Database::getConnection();

        // Active stories created within 24 hours
        $stmt = $db->prepare("SELECT s.id, s.user_id, s.media_url, s.media_type, s.caption, s.created_at, s.expires_at,
                              u.username, pr.full_name, pr.avatar_url,
                              (SELECT COUNT(*) FROM story_views WHERE story_id = s.id AND viewer_id = ?) as is_viewed
                              FROM stories s
                              JOIN users u ON s.user_id = u.id
                              LEFT JOIN profiles pr ON u.id = pr.user_id
                              WHERE s.expires_at > NOW() AND (s.user_id = ? OR s.user_id IN (SELECT friend_id FROM friendships WHERE user_id = ?))
                              ORDER BY s.created_at DESC");
        $stmt->execute([$authUser['user_id'], $authUser['user_id'], $authUser['user_id']]);
        $rawStories = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Group stories by user
        $grouped = [];
        foreach ($rawStories as $story) {
            $uId = $story['user_id'];
            if (!isset($grouped[$uId])) {
                $grouped[$uId] = [
                    'user_id' => $uId,
                    'username' => $story['username'],
                    'full_name' => $story['full_name'],
                    'avatar_url' => $story['avatar_url'],
                    'stories' => []
                ];
            }
            $story['is_viewed'] = (bool)$story['is_viewed'];
            $grouped[$uId]['stories'][] = $story;
        }

        Response::success('Stories feed', array_values($grouped));
    }

    public static function create(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $mediaUrl = $data['media_url'] ?? '';
        $mediaType = $data['media_type'] ?? 'image';
        $caption = $data['caption'] ?? null;

        if (!$mediaUrl) {
            Response::error('Media URL required', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("INSERT INTO stories (user_id, media_url, media_type, caption, expires_at)
                              VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 24 HOUR))");
        $stmt->execute([$authUser['user_id'], $mediaUrl, $mediaType, $caption]);

        Response::success('Story created', ['story_id' => (int)$db->lastInsertId()], 201);
    }

    public static function markViewed(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $storyId = (int)($data['story_id'] ?? 0);

        if (!$storyId) {
            Response::error('Story ID required', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("INSERT IGNORE INTO story_views (story_id, viewer_id) VALUES (?, ?)");
        $stmt->execute([$storyId, $authUser['user_id']]);

        Response::success('Story marked as viewed');
    }
}
