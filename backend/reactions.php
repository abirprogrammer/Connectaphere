<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

$host = "localhost";
$user = "programm_abir";
$pass = "abir@2025";
$db   = "programm_abir2025";

$conn = new mysqli($host, $user, $pass, $db);
if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "DB connection failed"]);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
$targetType = $input['target_type'] ?? 'post';
$targetId = $input['target_id'] ?? 0;
$userId = $input['user_id'] ?? 1;
$reactionType = $input['reaction_type'] ?? 'like';

if (empty($targetId)) {
    echo json_encode(["success" => false, "message" => "Target ID required"]);
    exit;
}

$stmt = $conn->prepare("SELECT id, reaction_type FROM reactions WHERE target_type = ? AND target_id = ? AND user_id = ?");
$stmt->bind_param("sii", $targetType, $targetId, $userId);
$stmt->execute();
$result = $stmt->get_result();
$existing = $result->fetch_assoc();
$stmt->close();

if ($existing) {
    if ($existing['reaction_type'] === $reactionType) {
        $del = $conn->prepare("DELETE FROM reactions WHERE id = ?");
        $del->bind_param("i", $existing['id']);
        $del->execute();
        $del->close();
        echo json_encode(["success" => true, "message" => "Reaction removed", "data" => ["user_reaction" => null]]);
    } else {
        $upd = $conn->prepare("UPDATE reactions SET reaction_type = ? WHERE id = ?");
        $upd->bind_param("si", $reactionType, $existing['id']);
        $upd->execute();
        $upd->close();
        echo json_encode(["success" => true, "message" => "Reaction updated", "data" => ["user_reaction" => $reactionType]]);
    }
} else {
    $ins = $conn->prepare("INSERT INTO reactions (target_type, target_id, user_id, reaction_type) VALUES (?, ?, ?, ?)");
    $ins->bind_param("siis", $targetType, $targetId, $userId, $reactionType);
    $ins->execute();
    $ins->close();
    echo json_encode(["success" => true, "message" => "Reaction added", "data" => ["user_reaction" => $reactionType]]);
}

$conn->close();
?>
