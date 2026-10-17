<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;

class ReactionController {
    public static function toggle(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $targetType = $data['target_type'] ?? 'post';
        $targetId = (int)($data['target_id'] ?? 0);
        $reactionType = $data['reaction_type'] ?? 'like';

        if (!$targetId) {
            Response::error('Invalid target ID', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT id, reaction_type FROM reactions WHERE target_type = ? AND target_id = ? AND user_id = ?");
        $stmt->execute([$targetType, $targetId, $authUser['user_id']]);
        $existing = $stmt->fetch();

        if ($existing) {
            if ($existing['reaction_type'] === $reactionType) {
                // Remove reaction if same
                $del = $db->prepare("DELETE FROM reactions WHERE id = ?");
                $del->execute([$existing['id']]);
                Response::success('Reaction removed', ['user_reaction' => null]);
            } else {
                // Update reaction
                $upd = $db->prepare("UPDATE reactions SET reaction_type = ? WHERE id = ?");
                $upd->execute([$reactionType, $existing['id']]);
                Response::success('Reaction updated', ['user_reaction' => $reactionType]);
            }
        } else {
            // Add reaction
            $ins = $db->prepare("INSERT INTO reactions (target_type, target_id, user_id, reaction_type) VALUES (?, ?, ?, ?)");
            $ins->execute([$targetType, $targetId, $authUser['user_id'], $reactionType]);

            // Notify post owner
            if ($targetType === 'post') {
                $postOwner = $db->prepare("SELECT user_id FROM posts WHERE id = ?");
                $postOwner->execute([$targetId]);
                $ownerId = $postOwner->fetchColumn();
                if ($ownerId && $ownerId != $authUser['user_id']) {
                    $notif = $db->prepare("INSERT INTO notifications (user_id, actor_id, type, title, body, entity_type, entity_id) VALUES (?, ?, 'reaction', 'New Reaction', 'reacted to your post', 'post', ?)");
                    $notif->execute([$ownerId, $authUser['user_id'], $targetId]);
                }
            }

            Response::success('Reaction added', ['user_reaction' => $reactionType]);
        }
    }
}
