<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;
use App\Validators\Validator;
use PDO;

class CommentController {
    public static function index(): void {
        AuthMiddleware::authenticate();
        $postId = (int)($_GET['post_id'] ?? 0);

        if (!$postId) {
            Response::error('Post ID required', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT c.id, c.post_id, c.user_id, c.parent_id, c.content, c.created_at,
                              u.username, pr.full_name, pr.avatar_url
                              FROM comments c
                              JOIN users u ON c.user_id = u.id
                              LEFT JOIN profiles pr ON u.id = pr.user_id
                              WHERE c.post_id = ?
                              ORDER BY c.created_at ASC");
        $stmt->execute([$postId]);
        $comments = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success('Comments list', $comments);
    }

    public static function create(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $validated = Validator::validate($data, [
            'post_id' => 'required',
            'content' => 'required|min:1'
        ]);

        $db = Database::getConnection();
        $parentId = !empty($data['parent_id']) ? (int)$data['parent_id'] : null;

        $stmt = $db->prepare("INSERT INTO comments (post_id, user_id, parent_id, content) VALUES (?, ?, ?, ?)");
        $stmt->execute([$validated['post_id'], $authUser['user_id'], $parentId, $validated['content']]);
        $commentId = $db->lastInsertId();

        // Notify post owner
        $postOwner = $db->prepare("SELECT user_id FROM posts WHERE id = ?");
        $postOwner->execute([$validated['post_id']]);
        $ownerId = $postOwner->fetchColumn();
        if ($ownerId && $ownerId != $authUser['user_id']) {
            $notif = $db->prepare("INSERT INTO notifications (user_id, actor_id, type, title, body, entity_type, entity_id) VALUES (?, ?, 'comment', 'New Comment', 'commented on your post', 'post', ?)");
            $notif->execute([$ownerId, $authUser['user_id'], $validated['post_id']]);
        }

        Response::success('Comment added', [
            'id' => (int)$commentId,
            'post_id' => (int)$validated['post_id'],
            'user_id' => (int)$authUser['user_id'],
            'content' => $validated['content'],
            'created_at' => date('Y-m-d H:i:s')
        ], 201);
    }
}
