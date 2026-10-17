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
$postId = $input['post_id'] ?? 0;
$userId = $input['user_id'] ?? 1;

if (empty($postId)) {
    echo json_encode(["success" => false, "message" => "Post ID required"]);
    exit;
}

$stmt = $conn->prepare("SELECT id FROM saved_posts WHERE user_id = ? AND post_id = ?");
$stmt->bind_param("ii", $userId, $postId);
$stmt->execute();
$result = $stmt->get_result();
$existing = $result->fetch_assoc();
$stmt->close();

if ($existing) {
    $del = $conn->prepare("DELETE FROM saved_posts WHERE user_id = ? AND post_id = ?");
    $del->bind_param("ii", $userId, $postId);
    $del->execute();
    $del->close();
    echo json_encode(["success" => true, "message" => "Post unsaved", "data" => ["is_saved" => false]]);
} else {
    $ins = $conn->prepare("INSERT INTO saved_posts (user_id, post_id) VALUES (?, ?)");
    $ins->bind_param("ii", $userId, $postId);
    $ins->execute();
    $ins->close();
    echo json_encode(["success" => true, "message" => "Post saved", "data" => ["is_saved" => true]]);
}

$conn->close();
?>
