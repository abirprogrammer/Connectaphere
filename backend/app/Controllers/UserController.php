<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;
use App\Validators\Validator;
use PDO;

class UserController {
    public static function profile(): void {
        $authUser = AuthMiddleware::authenticate();
        $targetUserId = $_GET['user_id'] ?? $authUser['user_id'];

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT u.id, u.username, u.email, u.created_at,
                              p.full_name, p.bio, p.avatar_url, p.cover_url, p.location, p.website, p.birth_date, p.privacy_level
                              FROM users u
                              LEFT JOIN profiles p ON u.id = p.user_id
                              WHERE u.id = ?");
        $stmt->execute([$targetUserId]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$user) {
            Response::error('User not found', 404);
        }

        // Get friends count and posts count
        $stmt = $db->prepare("SELECT COUNT(*) FROM friendships WHERE user_id = ?");
        $stmt->execute([$targetUserId]);
        $user['friends_count'] = (int)$stmt->fetchColumn();

        $stmt = $db->prepare("SELECT COUNT(*) FROM posts WHERE user_id = ?");
        $stmt->execute([$targetUserId]);
        $user['posts_count'] = (int)$stmt->fetchColumn();

        // Friendship status relative to auth user
        if ($authUser['user_id'] != $targetUserId) {
            $stmt = $db->prepare("SELECT status FROM friend_requests WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)");
            $stmt->execute([$authUser['user_id'], $targetUserId, $targetUserId, $authUser['user_id']]);
            $req = $stmt->fetch(PDO::FETCH_ASSOC);

            $stmt = $db->prepare("SELECT id FROM friendships WHERE (user_id = ? AND friend_id = ?)");
            $stmt->execute([$authUser['user_id'], $targetUserId]);
            $isFriend = (bool)$stmt->fetchColumn();

            $user['relationship'] = $isFriend ? 'friends' : ($req ? $req['status'] : 'none');
        } else {
            $user['relationship'] = 'self';
        }

        Response::success('Profile retrieved', $user);
    }

    public static function updateProfile(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $db = Database::getConnection();
        $stmt = $db->prepare("UPDATE profiles SET full_name = COALESCE(?, full_name), bio = COALESCE(?, bio),
                              location = COALESCE(?, location), website = COALESCE(?, website)
                              WHERE user_id = ?");
        $stmt->execute([
            $data['full_name'] ?? null,
            $data['bio'] ?? null,
            $data['location'] ?? null,
            $data['website'] ?? null,
            $authUser['user_id']
        ]);

        Response::success('Profile updated successfully');
    }

    public static function search(): void {
        AuthMiddleware::authenticate();
        $query = trim($_GET['q'] ?? '');

        if (!$query) {
            Response::success('Search results', []);
        }

        $db = Database::getConnection();
        $searchParam = "%{$query}%";
        $stmt = $db->prepare("SELECT u.id, u.username, p.full_name, p.avatar_url
                              FROM users u
                              LEFT JOIN profiles p ON u.id = p.user_id
                              WHERE u.username LIKE ? OR p.full_name LIKE ?
                              LIMIT 20");
        $stmt->execute([$searchParam, $searchParam]);
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success('Search results', $results);
    }
}
