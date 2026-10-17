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
    echo json_encode(["success" => false, "message" => "DB connection failed: " . $conn->connect_error]);
    exit;
}

$input = json_decode(file_get_contents('php://input'), true) ?: $_POST;

$identifier = trim($input['email'] ?? $input['username'] ?? '');
$password   = $input['password'] ?? '';

if (empty($identifier) || empty($password)) {
    echo json_encode(["success" => false, "message" => "Email/Username and password are required."]);
    exit;
}

$stmt = $conn->prepare("SELECT u.id, u.username, u.email, u.password_hash, u.status, p.full_name, p.avatar_url
                        FROM users u
                        LEFT JOIN `profiles` p ON u.id = p.user_id
                        WHERE u.email = ? OR u.username = ?");
if (!$stmt) {
    echo json_encode(["success" => false, "message" => "SQL Error: " . $conn->error]);
    exit;
}

$stmt->bind_param("ss", $identifier, $identifier);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "User not found for: " . $identifier]);
    $stmt->close();
    $conn->close();
    exit;
}

$user = $result->fetch_assoc();
$stmt->close();

if ($user['status'] === 'suspended') {
    echo json_encode(["success" => false, "message" => "Account is suspended."]);
    $conn->close();
    exit;
}

if (!password_verify($password, $user['password_hash'])) {
    echo json_encode(["success" => false, "message" => "Incorrect password."]);
    $conn->close();
    exit;
}

echo json_encode([
    "success" => true,
    "message" => "Login successful",
    "data" => [
        "user" => [
            "id" => (int)$user['id'],
            "username" => $user['username'],
            "email" => $user['email'],
            "full_name" => $user['full_name'] ?? $user['username'],
            "avatar_url" => $user['avatar_url']
        ],
        "access_token" => bin2hex(random_bytes(32)),
        "refresh_token" => bin2hex(random_bytes(32))
    ]
]);

$conn->close();
?>
