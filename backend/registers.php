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

$input = json_decode(file_get_contents('php://input'), true);
if (!$input) {
    $input = $_POST;
}
if (empty($input)) {
    $input = $_REQUEST;
}

$username  = trim($input['username'] ?? '');
$email     = trim($input['email'] ?? '');
$password  = $input['password'] ?? '';
$full_name = trim($input['full_name'] ?? '');

if (empty($username) || empty($email) || empty($password) || empty($full_name)) {
    echo json_encode([
        "success" => false,
        "message" => "All fields (username, email, password, full_name) are required."
    ]);
    exit;
}

// Check if username or email exists
$stmt = $conn->prepare("SELECT id FROM users WHERE username = ? OR email = ?");
$stmt->bind_param("ss", $username, $email);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows > 0) {
    echo json_encode(["success" => false, "message" => "Username or email already exists."]);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

$password_hash = password_hash($password, PASSWORD_BCRYPT);

$conn->begin_transaction();

try {
    $stmtUser = $conn->prepare("INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)");
    $stmtUser->bind_param("sss", $username, $email, $password_hash);
    if (!$stmtUser->execute()) {
        throw new Exception("User insert failed: " . $stmtUser->error);
    }
    $userId = $conn->insert_id;
    $stmtUser->close();

    $stmtProfile = $conn->prepare("INSERT INTO `profiles` (user_id, full_name) VALUES (?, ?)");
    $stmtProfile->bind_param("is", $userId, $full_name);
    if (!$stmtProfile->execute()) {
        throw new Exception("Profile insert failed: " . $stmtProfile->error);
    }
    $stmtProfile->close();

    $conn->commit();

    echo json_encode([
        "success" => true,
        "message" => "User registered successfully",
        "data" => [
            "user" => [
                "id" => (int)$userId,
                "username" => $username,
                "email" => $email,
                "full_name" => $full_name,
                "avatar_url" => null
            ],
            "access_token" => bin2hex(random_bytes(32)),
            "refresh_token" => bin2hex(random_bytes(32))
        ]
    ]);
} catch (Exception $e) {
    $conn->rollback();
    echo json_encode([
        "success" => false,
        "message" => "Registration error: " . $e->getMessage()
    ]);
}

$conn->close();
?>
