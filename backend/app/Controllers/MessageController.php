<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;
use App\Validators\Validator;
use PDO;

class MessageController {
    public static function listConversations(): void {
        $authUser = AuthMiddleware::authenticate();
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT c.id, c.type, c.name, c.avatar_url, c.updated_at,
                              (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message,
                              (SELECT created_at FROM messages WHERE conversation_id = c.id ORDER BY created_at DESC LIMIT 1) as last_message_time,
                              (SELECT COUNT(*) FROM messages WHERE conversation_id = c.id AND id > cm.last_read_message_id AND sender_id != ?) as unread_count
                              FROM conversations c
                              JOIN conversation_members cm ON c.id = cm.conversation_id
                              WHERE cm.user_id = ?
                              ORDER BY c.updated_at DESC");
        $stmt->execute([$authUser['user_id'], $authUser['user_id']]);
        $conversations = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Populate participant info for direct chats
        foreach ($conversations as &$conv) {
            if ($conv['type'] === 'direct') {
                $pStmt = $db->prepare("SELECT u.id, u.username, pr.full_name, pr.avatar_url
                                       FROM conversation_members cm
                                       JOIN users u ON cm.user_id = u.id
                                       LEFT JOIN profiles pr ON u.id = pr.user_id
                                       WHERE cm.conversation_id = ? AND cm.user_id != ? LIMIT 1");
                $pStmt->execute([$conv['id'], $authUser['user_id']]);
                $participant = $pStmt->fetch(PDO::FETCH_ASSOC);

                if ($participant) {
                    $conv['name'] = $participant['full_name'] ?: $participant['username'];
                    $conv['avatar_url'] = $participant['avatar_url'];
                    $conv['other_user_id'] = (int)$participant['id'];
                }
            }
        }

        Response::success('Conversations', $conversations);
    }

    public static function createConversation(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $targetUserId = (int)($data['target_user_id'] ?? 0);

        if (!$targetUserId) {
            Response::error('Target user ID required', 400);
        }

        $db = Database::getConnection();

        // Check if direct conversation exists
        $stmt = $db->prepare("SELECT c.id FROM conversations c
                              JOIN conversation_members cm1 ON c.id = cm1.conversation_id
                              JOIN conversation_members cm2 ON c.id = cm2.conversation_id
                              WHERE c.type = 'direct' AND cm1.user_id = ? AND cm2.user_id = ?");
        $stmt->execute([$authUser['user_id'], $targetUserId]);
        $existing = $stmt->fetchColumn();

        if ($existing) {
            Response::success('Existing conversation found', ['conversation_id' => (int)$existing]);
        }

        $db->beginTransaction();
        try {
            $stmt = $db->prepare("INSERT INTO conversations (type, created_by) VALUES ('direct', ?)");
            $stmt->execute([$authUser['user_id']]);
            $convId = $db->lastInsertId();

            $stmtMem = $db->prepare("INSERT INTO conversation_members (conversation_id, user_id, role) VALUES (?, ?, 'member')");
            $stmtMem->execute([$convId, $authUser['user_id']]);
            $stmtMem->execute([$convId, $targetUserId]);

            $db->commit();
            Response::success('Conversation created', ['conversation_id' => (int)$convId], 201);
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error('Failed to create conversation', 500);
        }
    }

    public static function listMessages(): void {
        $authUser = AuthMiddleware::authenticate();
        $convId = (int)($_GET['conversation_id'] ?? 0);

        if (!$convId) {
            Response::error('Conversation ID required', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT m.id, m.conversation_id, m.sender_id, m.message_type, m.content, m.created_at,
                              u.username, pr.full_name, pr.avatar_url
                              FROM messages m
                              JOIN users u ON m.sender_id = u.id
                              LEFT JOIN profiles pr ON u.id = pr.user_id
                              WHERE m.conversation_id = ?
                              ORDER BY m.created_at ASC");
        $stmt->execute([$convId]);
        $messages = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Update last read message
        if (!empty($messages)) {
            $lastMsg = end($messages);
            $upd = $db->prepare("UPDATE conversation_members SET last_read_message_id = ? WHERE conversation_id = ? AND user_id = ?");
            $upd->execute([$lastMsg['id'], $convId, $authUser['user_id']]);
        }

        Response::success('Messages', $messages);
    }

    public static function sendMessage(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $convId = (int)($data['conversation_id'] ?? 0);
        $content = trim($data['content'] ?? '');
        $msgType = $data['message_type'] ?? 'text';

        if (!$convId || !$content) {
            Response::error('Conversation ID and content required', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("INSERT INTO messages (conversation_id, sender_id, message_type, content) VALUES (?, ?, ?, ?)");
        $stmt->execute([$convId, $authUser['user_id'], $msgType, $content]);
        $msgId = $db->lastInsertId();

        // Update conversation timestamp
        $upd = $db->prepare("UPDATE conversations SET updated_at = NOW() WHERE id = ?");
        $upd->execute([$convId]);

        Response::success('Message sent', [
            'id' => (int)$msgId,
            'conversation_id' => $convId,
            'sender_id' => (int)$authUser['user_id'],
            'content' => $content,
            'message_type' => $msgType,
            'created_at' => date('Y-m-d H:i:s')
        ], 201);
    }
}
