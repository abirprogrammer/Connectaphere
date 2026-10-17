<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if (empty($_FILES['file'])) {
    echo json_encode(["success" => false, "message" => "No file uploaded. $_FILES is empty."]);
    exit;
}

$file = $_FILES['file'];
if ($file['error'] !== UPLOAD_ERR_OK) {
    echo json_encode(["success" => false, "message" => "PHP File Upload Error Code: " . $file['error']]);
    exit;
}

$uploadDir = __DIR__ . '/uploads/';

if (!file_exists($uploadDir)) {
    @mkdir($uploadDir, 0755, true);
}

$fileName = time() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '', basename($file['name']));
$targetPath = $uploadDir . $fileName;

if (move_uploaded_file($file['tmp_name'], $targetPath)) {
    $protocol = isset($_SERVER['HTTPS']) && $_SERVER['HTTPS'] === 'on' ? "https" : "http";
    $host = $_SERVER['HTTP_HOST'];
    $baseUrl = $protocol . "://" . $host . dirname($_SERVER['PHP_SELF']) . '/uploads/';
    $fileUrl = $baseUrl . $fileName;

    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = @finfo_file($finfo, $targetPath) ?: 'image/jpeg';
    if ($finfo) {
        finfo_close($finfo);
    }

    $mediaType = str_contains($mimeType, 'video') ? 'video' : 'image';

    echo json_encode([
        "success" => true,
        "message" => "File uploaded successfully",
        "data" => [
            "url" => $fileUrl,
            "media_type" => $mediaType,
            "file_name" => $fileName,
            "file_size" => $file['size']
        ]
    ]);
} else {
    echo json_encode(["success" => false, "message" => "Failed to move uploaded file. Please make sure the 'uploads/' directory exists and is writable (permissions 755/777)."]);
}
?>
