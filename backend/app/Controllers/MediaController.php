<?php

namespace App\Controllers;

use App\Middleware\AuthMiddleware;
use App\Services\Response;

class MediaController {
    public static function upload(): void {
        AuthMiddleware::authenticate();

        if (empty($_FILES['file'])) {
            Response::error('No file uploaded', 400);
        }

        $file = $_FILES['file'];
        $config = require __DIR__ . '/../../config/config.php';
        $uploadDir = $config['app']['upload_dir'];

        if (!file_exists($uploadDir)) {
            mkdir($uploadDir, 0755, true);
        }

        $fileName = time() . '_' . preg_replace('/[^a-zA-Z0-9._-]/', '', basename($file['name']));
        $targetPath = $uploadDir . $fileName;

        $allowedMimetypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'video/mp4', 'video/webm', 'video/quicktime'];
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        $mimeType = finfo_file($finfo, $file['tmp_name']);
        finfo_close($finfo);

        if (!in_array($mimeType, $allowedMimetypes)) {
            Response::error('Invalid file type: ' . $mimeType, 422);
        }

        if (move_uploaded_file($file['tmp_name'], $targetPath)) {
            $fileUrl = $config['app']['upload_base_url'] . $fileName;
            $mediaType = str_contains($mimeType, 'video') ? 'video' : 'image';

            Response::success('File uploaded successfully', [
                'url' => $fileUrl,
                'media_type' => $mediaType,
                'file_name' => $fileName,
                'file_size' => $file['size']
            ]);
        } else {
            Response::error('Failed to move uploaded file', 500);
        }
    }
}
