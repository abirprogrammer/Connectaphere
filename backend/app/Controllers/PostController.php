<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;
use App\Validators\Validator;
use PDO;

class PostController {
    public static function index(): void {
        $authUser = AuthMiddleware::authenticate();
        $page = (int)($_GET['page'] ?? 1);
        $limit = 15;
        $offset = ($page - 1) * $limit;
        $filter = $_GET['filter'] ?? 'feed'; // feed, reels, saved, user

        $db = Database::getConnection();

        $query = "SELECT p.id, p.user_id, p.content, p.privacy, p.shares_count, p.created_at, p.updated_at,
                         u.username, pr.full_name, pr.avatar_url,
                         (SELECT COUNT(*) FROM reactions WHERE target_type = 'post' AND target_id = p.id) as reactions_count,
                         (SELECT COUNT(*) FROM comments WHERE post_id = p.id) as comments_count,
                         (SELECT reaction_type FROM reactions WHERE target_type = 'post' AND target_id = p.id AND user_id = ?) as user_reaction,
                         (SELECT COUNT(*) FROM saved_posts WHERE post_id = p.id AND user_id = ?) as is_saved
                  FROM posts p
                  JOIN users u ON p.user_id = u.id
                  LEFT JOIN profiles pr ON u.id = pr.user_id";

        $params = [$authUser['user_id'], $authUser['user_id']];

        if ($filter === 'reels') {
            $query .= " JOIN post_media pm ON p.id = pm.post_id WHERE pm.media_type = 'video'";
        } elseif ($filter === 'user') {
            $targetUserId = (int)($_GET['user_id'] ?? $authUser['user_id']);
            $query .= " WHERE p.user_id = ?";
            $params[] = $targetUserId;
        } elseif ($filter === 'saved') {
            $query .= " JOIN saved_posts sp ON p.id = sp.post_id WHERE sp.user_id = ?";
            $params[] = $authUser['user_id'];
        } else {
            // Default feed: public posts, user's own posts, or posts by user's friends
            $query .= " WHERE p.privacy = 'public' OR p.user_id = ? OR p.user_id IN (SELECT friend_id FROM friendships WHERE user_id = ?)";
            $params[] = $authUser['user_id'];
            $params[] = $authUser['user_id'];
        }

        $query .= " ORDER BY p.created_at DESC LIMIT ? OFFSET ?";
        $params[] = $limit;
        $params[] = $offset;

        $stmt = $db->prepare($query);
        $stmt->execute($params);
        $posts = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Attach media items to each post
        foreach ($posts as &$post) {
            $post['is_saved'] = (bool)$post['is_saved'];
            $stmtMedia = $db->prepare("SELECT id, media_type, url, thumbnail_url FROM post_media WHERE post_id = ? ORDER BY sort_order ASC");
            $stmtMedia->execute([$post['id']]);
            $post['media'] = $stmtMedia->fetchAll(PDO::FETCH_ASSOC);
        }

        Response::success('Posts feed', $posts);
    }

    public static function create(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $db = Database::getConnection();
        $db->beginTransaction();

        try {
            $content = $data['content'] ?? null;
            $privacy = $data['privacy'] ?? 'public';
            $mediaItems = $data['media'] ?? []; // Array of ['media_type' => 'image|video', 'url' => '...']

            $stmt = $db->prepare("INSERT INTO posts (user_id, content, privacy) VALUES (?, ?, ?)");
            $stmt->execute([$authUser['user_id'], $content, $privacy]);
            $postId = $db->lastInsertId();

            if (!empty($mediaItems)) {
                $stmtMedia = $db->prepare("INSERT INTO post_media (post_id, media_type, url, thumbnail_url, sort_order) VALUES (?, ?, ?, ?, ?)");
                foreach ($mediaItems as $idx => $m) {
                    $stmtMedia->execute([
                        $postId,
                        $m['media_type'] ?? 'image',
                        $m['url'],
                        $m['thumbnail_url'] ?? null,
                        $idx
                    ]);
                }
            }

            $db->commit();
            Response::success('Post created successfully', ['post_id' => (int)$postId], 201);
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error('Failed to create post: ' . $e->getMessage(), 500);
        }
    }

    public static function delete(): void {
        $authUser = AuthMiddleware::authenticate();
        $postId = (int)($_GET['id'] ?? 0);

        $db = Database::getConnection();
        $stmt = $db->prepare("DELETE FROM posts WHERE id = ? AND user_id = ?");
        $stmt->execute([$postId, $authUser['user_id']]);

        if ($stmt->rowCount() > 0) {
            Response::success('Post deleted successfully');
        } else {
            Response::error('Post not found or unauthorized', 404);
        }
    }

    public static function toggleSave(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $postId = (int)($data['post_id'] ?? 0);

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT id FROM saved_posts WHERE user_id = ? AND post_id = ?");
        $stmt->execute([$authUser['user_id'], $postId]);

        if ($stmt->fetch()) {
            $del = $db->prepare("DELETE FROM saved_posts WHERE user_id = ? AND post_id = ?");
            $del->execute([$authUser['user_id'], $postId]);
            Response::success('Post unsaved', ['is_saved' => false]);
        } else {
            $ins = $db->prepare("INSERT INTO saved_posts (user_id, post_id) VALUES (?, ?)");
            $ins->execute([$authUser['user_id'], $postId]);
            Response::success('Post saved', ['is_saved' => true]);
        }
    }
}
