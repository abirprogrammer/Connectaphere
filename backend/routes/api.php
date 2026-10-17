<?php

use App\Controllers\AuthController;
use App\Controllers\UserController;
use App\Controllers\FriendController;
use App\Controllers\PostController;
use App\Controllers\ReactionController;
use App\Controllers\CommentController;
use App\Controllers\StoryController;
use App\Controllers\MediaController;
use App\Controllers\MessageController;
use App\Controllers\CallController;
use App\Controllers\GroupController;
use App\Controllers\NotificationController;
use App\Controllers\SettingsController;
use App\Services\Response;

class Router {
    private array $routes = [];

    public function add(string $method, string $path, callable|array $handler): void {
        $this->routes[] = [
            'method' => strtoupper($method),
            'path' => $path,
            'handler' => $handler
        ];
    }

    public function dispatch(string $method, string $uri): void {
        $path = parse_url($uri, PHP_URL_PATH);

        // Dynamically strip any deployment base folder prefix up to /public
        $path = preg_replace('#^/.*/public#', '', $path);
        // Fallback for specific known paths
        $path = str_replace(['/blood_app_api/public', '/connectsphere/backend/public', '/public'], '', $path);

        if ($path === '' || $path === null) $path = '/';

        foreach ($this->routes as $route) {
            if ($route['method'] === $method && $route['path'] === $path) {
                call_user_func($route['handler']);
                return;
            }
        }

        Response::error("Route not found: {$method} {$path}", 404);
    }
}

$router = new Router();

// Auth
$router->add('POST', '/api/v1/auth/register', [AuthController::class, 'register']);
$router->add('POST', '/api/v1/auth/login', [AuthController::class, 'login']);
$router->add('POST', '/api/v1/auth/logout', [AuthController::class, 'logout']);
$router->add('POST', '/api/v1/auth/reset-password', [AuthController::class, 'resetPassword']);

// User & Profile
$router->add('GET', '/api/v1/user/profile', [UserController::class, 'profile']);
$router->add('POST', '/api/v1/user/profile', [UserController::class, 'updateProfile']);
$router->add('GET', '/api/v1/user/search', [UserController::class, 'search']);

// Friends
$router->add('POST', '/api/v1/friends/request', [FriendController::class, 'sendRequest']);
$router->add('POST', '/api/v1/friends/respond', [FriendController::class, 'respondRequest']);
$router->add('GET', '/api/v1/friends/list', [FriendController::class, 'listFriends']);
$router->add('GET', '/api/v1/friends/pending', [FriendController::class, 'pendingRequests']);
$router->add('POST', '/api/v1/friends/remove', [FriendController::class, 'removeFriend']);

// Posts
$router->add('GET', '/api/v1/posts', [PostController::class, 'index']);
$router->add('POST', '/api/v1/posts', [PostController::class, 'create']);
$router->add('DELETE', '/api/v1/posts', [PostController::class, 'delete']);
$router->add('POST', '/api/v1/posts/save', [PostController::class, 'toggleSave']);

// Reactions & Comments
$router->add('POST', '/api/v1/reactions/toggle', [ReactionController::class, 'toggle']);
$router->add('GET', '/api/v1/comments', [CommentController::class, 'index']);
$router->add('POST', '/api/v1/comments', [CommentController::class, 'create']);

// Stories
$router->add('GET', '/api/v1/stories', [StoryController::class, 'index']);
$router->add('POST', '/api/v1/stories', [StoryController::class, 'create']);
$router->add('POST', '/api/v1/stories/view', [StoryController::class, 'markViewed']);

// Media Uploads
$router->add('POST', '/api/v1/media/upload', [MediaController::class, 'upload']);

// Messaging
$router->add('GET', '/api/v1/conversations', [MessageController::class, 'listConversations']);
$router->add('POST', '/api/v1/conversations', [MessageController::class, 'createConversation']);
$router->add('GET', '/api/v1/messages', [MessageController::class, 'listMessages']);
$router->add('POST', '/api/v1/messages', [MessageController::class, 'sendMessage']);

// Calls
$router->add('POST', '/api/v1/calls/initiate', [CallController::class, 'initiate']);
$router->add('POST', '/api/v1/calls/respond', [CallController::class, 'respond']);

// Groups
$router->add('GET', '/api/v1/groups', [GroupController::class, 'index']);
$router->add('POST', '/api/v1/groups', [GroupController::class, 'create']);
$router->add('POST', '/api/v1/groups/join', [GroupController::class, 'join']);

// Notifications
$router->add('GET', '/api/v1/notifications', [NotificationController::class, 'index']);
$router->add('POST', '/api/v1/notifications/read', [NotificationController::class, 'markRead']);
$router->add('POST', '/api/v1/device-token', [NotificationController::class, 'registerDeviceToken']);

// Settings
$router->add('POST', '/api/v1/settings/theme', [SettingsController::class, 'updateTheme']);
$router->add('DELETE', '/api/v1/settings/account', [SettingsController::class, 'deleteAccount']);

return $router;
