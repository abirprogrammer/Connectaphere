<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Database;
use App\Services\Response;
use App\Validators\Validator;
use PDO;

class GroupController {
    public static function index(): void {
        $authUser = AuthMiddleware::authenticate();
        $db = Database::getConnection();

        $stmt = $db->prepare("SELECT g.id, g.name, g.description, g.privacy, g.cover_url, g.creator_id, g.created_at,
                              (SELECT COUNT(*) FROM group_members WHERE group_id = g.id) as members_count,
                              (SELECT status FROM group_members WHERE group_id = g.id AND user_id = ?) as member_status
                              FROM groups g
                              ORDER BY g.created_at DESC");
        $stmt->execute([$authUser['user_id']]);
        $groups = $stmt->fetchAll(PDO::FETCH_ASSOC);

        Response::success('Groups list', $groups);
    }

    public static function create(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;

        $validated = Validator::validate($data, [
            'name' => 'required|min:3|max:100',
            'description' => 'max:500'
        ]);

        $db = Database::getConnection();
        $privacy = $data['privacy'] ?? 'public';

        $db->beginTransaction();
        try {
            $stmt = $db->prepare("INSERT INTO groups (name, description, privacy, creator_id) VALUES (?, ?, ?, ?)");
            $stmt->execute([$validated['name'], $validated['description'], $privacy, $authUser['user_id']]);
            $groupId = $db->lastInsertId();

            $stmtMem = $db->prepare("INSERT INTO group_members (group_id, user_id, role, status) VALUES (?, ?, 'admin', 'approved')");
            $stmtMem->execute([$groupId, $authUser['user_id']]);

            $db->commit();
            Response::success('Group created successfully', ['group_id' => (int)$groupId], 201);
        } catch (\Exception $e) {
            $db->rollBack();
            Response::error('Failed to create group', 500);
        }
    }

    public static function join(): void {
        $authUser = AuthMiddleware::authenticate();
        $data = json_decode(file_get_contents('php://input'), true) ?: $_POST;
        $groupId = (int)($data['group_id'] ?? 0);

        if (!$groupId) {
            Response::error('Group ID required', 400);
        }

        $db = Database::getConnection();
        $stmt = $db->prepare("SELECT privacy FROM groups WHERE id = ?");
        $stmt->execute([$groupId]);
        $group = $stmt->fetch();

        if (!$group) {
            Response::error('Group not found', 404);
        }

        $status = ($group['privacy'] === 'public') ? 'approved' : 'pending';
        $stmtIns = $db->prepare("INSERT IGNORE INTO group_members (group_id, user_id, role, status) VALUES (?, ?, 'member', ?)");
        $stmtIns->execute([$groupId, $authUser['user_id'], $status]);

        Response::success('Group join request processed', ['status' => $status]);
    }
}
