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
    echo json_encode(["success" => false, "message" => "DB connection failed: " . $conn->connect_error]);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

$protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
$hostName = $_SERVER['HTTP_HOST'];
$baseUploadUrl = $protocol . "://" . $hostName . dirname($_SERVER['PHP_SELF']) . '/uploads/';

if ($method === 'GET') {
    $query = "SELECT s.id, s.user_id, s.media_url, s.media_type, s.caption, s.created_at, s.expires_at,
                     u.username, pr.full_name, pr.avatar_url
              FROM stories s
              JOIN users u ON s.user_id = u.id
              LEFT JOIN `profiles` pr ON u.id = pr.user_id
              WHERE s.expires_at > NOW()
              ORDER BY s.created_at DESC";

    $result = $conn->query($query);
    $rawStories = [];

    if ($result) {
        while ($row = $result->fetch_assoc()) {
            $mediaUrl = $row['media_url'];
            if (!filter_var($mediaUrl, FILTER_VALIDATE_URL)) {
                $mediaUrl = $baseUploadUrl . ltrim($mediaUrl, '/');
            }

            $rawStories[] = [
                'id' => (int)$row['id'],
                'user_id' => (int)$row['user_id'],
                'username' => $row['username'],
                'full_name' => $row['full_name'] ?? $row['username'],
                'avatar_url' => $row['avatar_url'],
                'media_url' => $mediaUrl,
                'media_type' => $row['media_type'],
                'caption' => $row['caption'],
                'is_viewed' => false
            ];
        }
    }

    $grouped = [];
    foreach ($rawStories as $story) {
        $uId = $story['user_id'];
        if (!isset($grouped[$uId])) {
            $grouped[$uId] = [
                'user_id' => $uId,
                'username' => $story['username'],
                'full_name' => $story['full_name'],
                'avatar_url' => $story['avatar_url'],
                'stories' => []
            ];
        }
        $grouped[$uId]['stories'][] = [
            'id' => $story['id'],
            'media_url' => $story['media_url'],
            'media_type' => $story['media_type'],
            'caption' => $story['caption'],
            'is_viewed' => $story['is_viewed']
        ];
    }

    echo json_encode(["success" => true, "message" => "Stories fetched", "data" => array_values($grouped)]);
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
    if (empty($input)) {
        $input = $_REQUEST;
    }

    $userId = $input['user_id'] ?? 1;
    $mediaUrl = $input['media_url'] ?? '';
    $mediaType = $input['media_type'] ?? 'image';
    $caption = $input['caption'] ?? null;

    if (empty($mediaUrl)) {
        echo json_encode(["success" => false, "message" => "Media URL required"]);
        exit;
    }

    $stmt = $conn->prepare("INSERT INTO stories (user_id, media_url, media_type, caption, expires_at) VALUES (?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 24 HOUR))");
    if (!$stmt) {
        echo json_encode(["success" => false, "message" => "SQL Prepare Error: " . $conn->error]);
        exit;
    }

    $stmt->bind_param("isss", $userId, $mediaUrl, $mediaType, $caption);
    if ($stmt->execute()) {
        $storyId = $conn->insert_id;
        echo json_encode(["success" => true, "message" => "Story created successfully", "data" => ["story_id" => (int)$storyId]]);
    } else {
        echo json_encode(["success" => false, "message" => "Failed to create story: " . $stmt->error]);
    }
    $stmt->close();
}

$conn->close();
?>
