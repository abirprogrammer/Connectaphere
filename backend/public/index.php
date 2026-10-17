<?php

use App\Middleware\CorsMiddleware;

require_once __DIR__ . '/../app/Services/Database.php';
require_once __DIR__ . '/../app/Services/Response.php';
require_once __DIR__ . '/../app/Services/TokenService.php';
require_once __DIR__ . '/../app/Middleware/AuthMiddleware.php';
require_once __DIR__ . '/../app/Middleware/CorsMiddleware.php';
require_once __DIR__ . '/../app/Validators/Validator.php';

require_once __DIR__ . '/../app/Controllers/AuthController.php';
require_once __DIR__ . '/../app/Controllers/UserController.php';
require_once __DIR__ . '/../app/Controllers/FriendController.php';
require_once __DIR__ . '/../app/Controllers/PostController.php';
require_once __DIR__ . '/../app/Controllers/ReactionController.php';
require_once __DIR__ . '/../app/Controllers/CommentController.php';
require_once __DIR__ . '/../app/Controllers/StoryController.php';
require_once __DIR__ . '/../app/Controllers/MediaController.php';
require_once __DIR__ . '/../app/Controllers/MessageController.php';
require_once __DIR__ . '/../app/Controllers/CallController.php';
require_once __DIR__ . '/../app/Controllers/GroupController.php';
require_once __DIR__ . '/../app/Controllers/NotificationController.php';
require_once __DIR__ . '/../app/Controllers/SettingsController.php';

CorsMiddleware::handle();

$router = require_once __DIR__ . '/../routes/api.php';
$router->dispatch($_SERVER['REQUEST_METHOD'], $_SERVER['REQUEST_URI']);
