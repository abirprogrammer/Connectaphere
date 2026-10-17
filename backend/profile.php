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
$userId = $_GET['user_id'] ?? $_POST['user_id'] ?? 1;
$baseUploadUrl = 'https://programmingpulse.xyz/blood_app_api/uploads/';

if ($method === 'GET') {
    $stmt = $conn->prepare("SELECT u.id, u.username, u.email, u.created_at,
                            p.full_name, p.bio, p.avatar_url, p.cover_url, p.location, p.website, p.birth_date, p.privacy_level
                            FROM users u
                            LEFT JOIN `profiles` p ON u.id = p.user_id
                            WHERE u.id = ?");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();
    $stmt->close();

    if (!$user) {
        $result = $conn->query("SELECT u.id, u.username, u.email, u.created_at, p.full_name, p.bio, p.avatar_url, p.cover_url, p.location, p.website, p.birth_date, p.privacy_level FROM users u LEFT JOIN `profiles` p ON u.id = p.user_id ORDER BY u.id DESC LIMIT 1");
        $user = $result->fetch_assoc();
    }

    if (!$user) {
        echo json_encode(["success" => false, "message" => "User not found"]);
        exit;
    }

    $userId = (int)$user['id'];
    $user['id'] = $userId;

    if (!empty($user['avatar_url']) && !filter_var($user['avatar_url'], FILTER_VALIDATE_URL)) {
        $user['avatar_url'] = $baseUploadUrl . ltrim($user['avatar_url'], '/');
    }
    if (!empty($user['cover_url']) && !filter_var($user['cover_url'], FILTER_VALIDATE_URL)) {
        $user['cover_url'] = $baseUploadUrl . ltrim($user['cover_url'], '/');
    }

    $fStmt = $conn->prepare("SELECT COUNT(*) FROM friendships WHERE user_id = ?");
    $fStmt->bind_param("i", $userId);
    $fStmt->execute();
    $fStmt->bind_result($friendsCount);
    $fStmt->fetch();
    $fStmt->close();
    $user['friends_count'] = (int)$friendsCount;

    $pStmt = $conn->prepare("SELECT COUNT(*) FROM posts WHERE user_id = ?");
    $pStmt->bind_param("i", $userId);
    $pStmt->execute();
    $pStmt->bind_result($postsCount);
    $pStmt->fetch();
    $pStmt->close();
    $user['posts_count'] = (int)$postsCount;
    $user['relationship'] = 'self';

    echo json_encode(["success" => true, "message" => "Profile retrieved", "data" => $user]);
} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true) ?: $_POST;
    $userId = $input['user_id'] ?? 1;
    $fullName = $input['full_name'] ?? null;
    $bio = $input['bio'] ?? null;
    $location = $input['location'] ?? null;
    $website = $input['website'] ?? null;
    $avatarUrl = $input['avatar_url'] ?? null;
    $coverUrl = $input['cover_url'] ?? null;

    $fields = [];
    $types = "";
    $values = [];

    if ($fullName !== null) { $fields[] = "full_name = ?"; $types .= "s"; $values[] = $fullName; }
    if ($bio !== null) { $fields[] = "bio = ?"; $types .= "s"; $values[] = $bio; }
    if ($location !== null) { $fields[] = "location = ?"; $types .= "s"; $values[] = $location; }
    if ($website !== null) { $fields[] = "website = ?"; $types .= "s"; $values[] = $website; }
    if ($avatarUrl !== null) { $fields[] = "avatar_url = ?"; $types .= "s"; $values[] = $avatarUrl; }
    if ($coverUrl !== null) { $fields[] = "cover_url = ?"; $types .= "s"; $values[] = $coverUrl; }

    if (!empty($fields)) {
        $sql = "UPDATE `profiles` SET " . implode(", ", $fields) . " WHERE user_id = ?";
        $types .= "i";
        $values[] = $userId;

        $stmt = $conn->prepare($sql);
        if ($stmt) {
            $stmt->bind_param($types, ...$values);
            $stmt->execute();
            $stmt->close();
        }
    }

    echo json_encode(["success" => true, "message" => "Profile updated successfully"]);
}

$conn->close();
?>
