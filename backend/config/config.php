<?php
// ConnectSphere Configuration

return [
    'app' => [
        'name' => 'ConnectSphere API',
        'env' => getenv('APP_ENV') ?: 'production',
        'url' => getenv('APP_URL') ?: 'https://programmabir.com/connectsphere/public', // update with your live domain if needed
        'jwt_secret' => getenv('JWT_SECRET') ?: 'connectsphere_super_secret_jwt_key_2026_change_in_prod',
        'jwt_expires_in' => 3600 * 24, // 24 hours
        'refresh_token_expires_in' => 3600 * 24 * 30, // 30 days
        'upload_dir' => __DIR__ . '/../public/uploads/',
        'upload_base_url' => (getenv('APP_URL') ?: 'https://programmabir.com/connectsphere/public') . '/uploads/',
        'max_file_size' => 50 * 1024 * 1024, // 50MB max upload
    ],
    'db' => [
        'host' => 'localhost',
        'port' => '3306',
        'database' => 'programm_abir2025',
        'username' => 'programm_abir',
        'password' => 'abir@2025',
        'charset' => 'utf8mb4',
    ],
    'agora' => [
        'app_id' => getenv('AGORA_APP_ID') ?: 'agora_demo_app_id',
        'app_certificate' => getenv('AGORA_APP_CERTIFICATE') ?: 'agora_demo_certificate',
    ],
    'fcm' => [
        'server_key' => getenv('FCM_SERVER_KEY') ?: 'fcm_demo_server_key',
    ]
];
