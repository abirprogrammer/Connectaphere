<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
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

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $postId = $_GET['post_id'] ?? 0;
    $stmt = $conn->prepare("SELECT c.id, c.post_id, c.user_id, c.parent_id, c.content, c.created_at,
                            u.username, pr.full_name, pr.avatar_url
                            FROM comments c
                            JOIN users u ON c.user_id = u.id
                            LEFT JOIN `profiles` pr ON u.id = pr.user_id
                            WHERE c.post_id = ?
                            ORDER BY c.created_at ASC");
    $stmt->bind_param("i", $postId);
    $stmt->execute();
    $result = $stmt->get_result();
    $comments = [];

    while ($row = $result->fetch_assoc()) {
        $row['id'] = (int)$row['id'];
        $row['post_id'] = (int)$row['post_id'];
        $row['user_id'] = (int)$row['user_id'];
        $comments[] = $row;
    }
    $stmt->close();

    echo json_encode(["success" => true, "message" => "Comments fetched", "data" => $comments]);
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
    $postId = $input['post_id'] ?? 0;
    $userId = $input['user_id'] ?? 1;
    $content = $input['content'] ?? '';

    if (empty($postId) || empty($content)) {
        echo json_encode(["success" => false, "message" => "Post ID and content required"]);
        exit;
    }

    $stmt = $conn->prepare("INSERT INTO comments (post_id, user_id, content) VALUES (?, ?, ?)");
    $stmt->bind_param("iis", $postId, $userId, $content);
    $stmt->execute();
    $commentId = $conn->insert_id;
    $stmt->close();

    echo json_encode(["success" => true, "message" => "Comment added", "data" => ["id" => (int)$commentId]]);
}

$conn->close();
?>
