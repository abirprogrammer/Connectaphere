<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;
use PDO;

class CallController {
    public static function initiate(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $convId = (int)($data['conversation_id'] ?? 0);
        $receiverId = (int)($data['receiver_id'] ?? 0);
        $callType = $data['call_type'] ?? 'video';

        if (!$convId || !$receiverId) {
            Response::error('Conversation ID and receiver ID required', 400);
        }

        $db = Database::getConnection();
        $channelName = 'connectsphere_call_' . time() . '_' . rand(1000, 9999);
        $roomToken = 'token_' . bin2hex(random_bytes(16));

        $stmt = $db->prepare("INSERT INTO calls (conversation_id, caller_id, receiver_id, call_type, channel_name, room_token, status)
                              VALUES (?, ?, ?, ?, ?, ?, 'initiated')");
        $stmt->execute([$convId, $authUser['user_id'], $receiverId, $callType, $channelName, $roomToken]);
        $callId = $db->lastInsertId();

        // Notify receiver
        $notif = $db->prepare("INSERT INTO notifications (user_id, actor_id, type, title, body, entity_type, entity_id) VALUES (?, ?, 'call', 'Incoming Call', 'is calling you', 'call', ?)");
        $notif->execute([$receiverId, $authUser['user_id'], $callId]);

        Response::success('Call initiated', [
            'call_id' => (int)$callId,
            'channel_name' => $channelName,
            'room_token' => $roomToken,
            'call_type' => $callType
        ], 201);
    }

    public static function respond(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $callId = (int)($data['call_id'] ?? 0);
        $status = $data['status'] ?? 'accepted'; // accepted, rejected, ended

        if (!$callId || !in_array($status, ['accepted', 'rejected', 'ended'])) {
            Response::error('Invalid call ID or status', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("UPDATE calls SET status = ?, ended_at = IF(? = 'ended', NOW(), ended_at) WHERE id = ?");
        $stmt->execute([$status, $status, $callId]);

        Response::success('Call status updated', ['status' => $status]);
    }
}
