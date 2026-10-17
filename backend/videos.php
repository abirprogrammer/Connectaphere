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
    $query = "SELECT p.id, p.user_id, p.content, p.privacy, p.shares_count, p.created_at,
                     u.username, pr.full_name, pr.avatar_url,
                     pm.id as media_id, pm.media_type, pm.url, pm.thumbnail_url,
                     (SELECT COUNT(*) FROM reactions WHERE target_type = 'post' AND target_id = p.id) as reactions_count,
                     (SELECT COUNT(*) FROM comments WHERE post_id = p.id) as comments_count
              FROM posts p
              JOIN post_media pm ON p.id = pm.post_id
              JOIN users u ON p.user_id = u.id
              LEFT JOIN `profiles` pr ON u.id = pr.user_id
              WHERE pm.media_type = 'video'
              ORDER BY p.created_at DESC LIMIT 30";

    $result = $conn->query($query);
    $videos = [];

    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
    $hostName = $_SERVER['HTTP_HOST'];
    $baseUploadUrl = $protocol . "://" . $hostName . dirname($_SERVER['PHP_SELF']) . '/uploads/';

    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $videoUrl = $row['url'];
            if (!filter_var($videoUrl, FILTER_VALIDATE_URL)) {
                $videoUrl = $baseUploadUrl . ltrim($videoUrl, '/');
            }

            $post = [
                'id' => (int)$row['id'],
                'user_id' => (int)$row['user_id'],
                'username' => $row['username'],
                'full_name' => $row['full_name'] ?? $row['username'],
                'avatar_url' => $row['avatar_url'],
                'content' => $row['content'],
                'privacy' => $row['privacy'],
                'shares_count' => (int)$row['shares_count'],
                'reactions_count' => (int)$row['reactions_count'],
                'comments_count' => (int)$row['comments_count'],
                'is_saved' => false,
                'user_reaction' => null,
                'created_at' => $row['created_at'],
                'media' => [
                    [
                        'id' => (int)$row['media_id'],
                        'media_type' => $row['media_type'],
                        'url' => $videoUrl,
                        'thumbnail_url' => $row['thumbnail_url']
                    ]
                ]
            ];
            $videos[] = $post;
        }
    }

    echo json_encode(["success" => true, "message" => "Videos fetched", "data" => $videos]);
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
    $userId = $input['user_id'] ?? 1;
    $content = $input['content'] ?? '';
    $videoUrl = $input['video_url'] ?? '';

    if (empty($videoUrl)) {
        echo json_encode(["success" => false, "message" => "Video URL required"]);
        exit;
    }

    $stmt = $conn->prepare("INSERT INTO posts (user_id, content, privacy) VALUES (?, ?, 'public')");
    $stmt->bind_param("is", $userId, $content);
    $stmt->execute();
    $postId = $conn->insert_id;
    $stmt->close();

    $mStmt = $conn->prepare("INSERT INTO post_media (post_id, media_type, url, sort_order) VALUES (?, 'video', ?, 0)");
    $mStmt->bind_param("is", $postId, $videoUrl);
    $mStmt->execute();
    $mStmt->close();

    echo json_encode(["success" => true, "message" => "Video post created successfully", "data" => ["post_id" => (int)$postId]]);
}

$conn->close();
?>
