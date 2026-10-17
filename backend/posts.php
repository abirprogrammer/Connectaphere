<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS");
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
$baseUploadUrl = 'https://programmingpulse.xyz/blood_app_api/uploads/';

if ($method === 'GET') {
    $filter = $_GET['filter'] ?? 'feed';
    $userId = $_GET['user_id'] ?? 1;

    $query = "SELECT p.id, p.user_id, p.content, p.privacy, p.shares_count, p.created_at, p.updated_at,
                     u.username, pr.full_name, pr.avatar_url,
                     (SELECT COUNT(*) FROM reactions WHERE target_type = 'post' AND target_id = p.id) as reactions_count,
                     (SELECT COUNT(*) FROM comments WHERE post_id = p.id) as comments_count
              FROM posts p
              JOIN users u ON p.user_id = u.id
              LEFT JOIN `profiles` pr ON u.id = pr.user_id";

    if ($filter === 'reels') {
        $query .= " JOIN post_media pm ON p.id = pm.post_id WHERE pm.media_type = 'video'";
    } elseif ($filter === 'user') {
        $query .= " WHERE p.user_id = " . (int)$userId;
    } else {
        $query .= " WHERE p.privacy = 'public' OR p.user_id = " . (int)$userId;
    }

    $query .= " ORDER BY p.created_at DESC LIMIT 50";

    $result = $conn->query($query);
    $posts = [];

    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $row['id'] = (int)$row['id'];
            $row['user_id'] = (int)$row['user_id'];
            $row['reactions_count'] = (int)$row['reactions_count'];
            $row['comments_count'] = (int)$row['comments_count'];
            $row['shares_count'] = (int)$row['shares_count'];
            $row['is_saved'] = false;
            $row['user_reaction'] = null;

            if (!empty($row['avatar_url']) && !filter_var($row['avatar_url'], FILTER_VALIDATE_URL)) {
                $row['avatar_url'] = $baseUploadUrl . ltrim($row['avatar_url'], '/');
            }

            // Fetch media attachments
            $mStmt = $conn->prepare("SELECT id, media_type, url, thumbnail_url FROM post_media WHERE post_id = ? ORDER BY sort_order ASC");
            if ($mStmt) {
                $mStmt->bind_param("i", $row['id']);
                $mStmt->execute();
                $mRes = $mStmt->get_result();
                $mediaList = [];
                while ($m = $mRes->fetch_assoc()) {
                    $m['id'] = (int)$m['id'];
                    $mUrl = $m['url'];
                    if (!empty($mUrl) && !filter_var($mUrl, FILTER_VALIDATE_URL)) {
                        $mUrl = $baseUploadUrl . ltrim($mUrl, '/');
                    }
                    $m['url'] = $mUrl;
                    $mediaList[] = $m;
                }
                $mStmt->close();
                $row['media'] = $mediaList;
            } else {
                $row['media'] = [];
            }

            $posts[] = $row;
        }
    }

    echo json_encode(["success" => true, "message" => "Posts fetched", "data" => $posts]);
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
    $userId = $input['user_id'] ?? 1;
    $content = $input['content'] ?? null;
    $privacy = $input['privacy'] ?? 'public';
    $mediaItems = $input['media'] ?? [];

    if (is_string($mediaItems)) {
        $mediaItems = json_decode($mediaItems, true) ?: [];
    }

    $stmt = $conn->prepare("INSERT INTO posts (user_id, content, privacy) VALUES (?, ?, ?)");
    $stmt->bind_param("iss", $userId, $content, $privacy);
    if (!$stmt->execute()) {
        echo json_encode(["success" => false, "message" => "Failed to create post: " . $stmt->error]);
        exit;
    }
    $postId = $conn->insert_id;
    $stmt->close();

    if (!empty($mediaItems) && is_array($mediaItems)) {
        foreach ($mediaItems as $idx => $m) {
            $mType = $m['media_type'] ?? 'image';
            $mUrl = $m['url'] ?? '';
            $tUrl = $m['thumbnail_url'] ?? '';

            $mStmt = $conn->prepare("INSERT INTO post_media (post_id, media_type, url, thumbnail_url, sort_order) VALUES (?, ?, ?, ?, ?)");
            if ($mStmt) {
                $mStmt->bind_param("isssi", $postId, $mType, $mUrl, $tUrl, $idx);
                $mStmt->execute();
                $mStmt->close();
            }
        }
    }

    echo json_encode(["success" => true, "message" => "Post created successfully", "data" => ["post_id" => (int)$postId]]);
} elseif ($method === 'DELETE') {
    $postId = $_GET['id'] ?? 0;
    $stmt = $conn->prepare("DELETE FROM posts WHERE id = ?");
    $stmt->bind_param("i", $postId);
    $stmt->execute();
    $stmt->close();

    echo json_encode(["success" => true, "message" => "Post deleted successfully"]);
}

$conn->close();
?>
