<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;
use PDO;

class FriendController {
    public static function sendRequest(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $receiverId = (int)($data['receiver_id'] ?? 0);

        if (!$receiverId || $receiverId === (int)$authUser['user_id']) {
            Response::error('Invalid user ID', 400);
        }

        $db = Database::getConnection();

        // Check if already friends or request exists
        $stmt = $db->prepare("SELECT id, status FROM friend_requests WHERE (sender_id = ? AND receiver_id = ?) OR (sender_id = ? AND receiver_id = ?)");
        $stmt->execute([$authUser['user_id'], $receiverId, $receiverId, $authUser['user_id']]);
        if ($stmt->fetch()) {
            Response::error('Friend request or friendship already exists', 400);
        }

        $stmt = $db->prepare("INSERT INTO friend_requests (sender_id, receiver_id, status) VALUES (?, ?, 'pending')");
        $stmt->execute([$authUser['user_id'], $receiverId]);

        // Create notification
        $stmt = $db->prepare("INSERT INTO notifications (user_id, actor_id, type, title, body, entity_type, entity_id) VALUES (?, ?, 'friend_request', 'New Friend Request', 'sent you a friend request', 'user', ?)");
        $stmt->execute([$receiverId, $authUser['user_id'], $authUser['user_id']]);

        Response::success('Friend request sent');
    }

    public static function respondRequest(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $requestId = (int)($data['request_id'] ?? 0);
        $action = $data['action'] ?? ''; // accept or reject

        if (!$requestId || !in_array($action, ['accept', 'reject'])) {
            Response::error('Invalid request or action', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT * FROM friend_requests WHERE id = ? AND receiver_id = ? AND status = 'pending'");
        $stmt->execute([$requestId, $authUser['user_id']]);
        $req = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$req) {
            Response::error('Friend request not found', 404);
        }

        if ($action === 'accept') {
            $db->beginTransaction();
            try {
                $stmt = $db->prepare("UPDATE friend_requests SET status = 'accepted' WHERE id = ?");
                $stmt->execute([$requestId]);

                // Insert bilateral friendship entries
                $stmt = $db->prepare("INSERT IGNORE INTO friendships (user_id, friend_id) VALUES (?, ?), (?, ?)");
                $stmt->execute([$req['sender_id'], $req['receiver_id'], $req['receiver_id'], $req['sender_id']]);

                $db->commit();
                Response::success('Friend request accepted');
            } catch (\Exception $e) {
                $db->rollBack();
                Response::error('Failed to accept request', 500);
            }
        } else {
            $stmt = $db->prepare("UPDATE friend_requests SET status = 'rejected' WHERE id = ?");
            $stmt->execute([$requestId]);
            Response::success('Friend request rejected');
        }
    }

    public static function listFriends(): void {
        $authUser = AuthMiddleware::authenticate();
        $targetUserId = $_GET['user_id'] ?? $authUser['user_id'];

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT u.id, u.username, p.full_name, p.avatar_url, p.bio
                              FROM friendships f
                              JOIN users u ON f.friend_id = u.id
                              LEFT JOIN profiles p ON u.id = p.user_id
                              WHERE f.user_id = ?");
        $stmt->execute([$targetUserId]);
        $friends = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success('Friends list', $friends);
    }

    public static function pendingRequests(): void {
        $authUser = AuthMiddleware::authenticate();
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT fr.id as request_id, fr.created_at, u.id as user_id, u.username, p.full_name, p.avatar_url
                              FROM friend_requests fr
                              JOIN users u ON fr.sender_id = u.id
                              LEFT JOIN profiles p ON u.id = p.user_id
                              WHERE fr.receiver_id = ? AND fr.status = 'pending'");
        $stmt->execute([$authUser['user_id']]);
        $requests = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success('Pending friend requests', $requests);
    }

    public static function removeFriend(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $friendId = (int)($data['friend_id'] ?? 0);

        $db = Database::getConnection();
        $stmt = $db->prepare("DELETE FROM friendships WHERE (user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)");
        $stmt->execute([$authUser['user_id'], $friendId, $friendId, $authUser['user_id']]);

        Response::success('Friend removed');
    }
}
