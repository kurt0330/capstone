<?php
require_once __DIR__ . '/db_connect.php';
session_start();

$email = clean($_POST['email'] ?? '');
$password = $_POST['password'] ?? '';

// 1. Fetch user and their provider status
$stmt = $pdo->prepare('
    SELECT u.*, p.admin_status, p.rejected_at 
    FROM users u
    LEFT JOIN providers p ON u.user_id = p.user_id
    WHERE u.email = ?
');
$stmt->execute([$email]);
$user = $stmt->fetch();

if ($user && password_verify($password, $user['password_hash'])) {
    
    // THE HYBRID GATE LOGIC
    if ($user['admin_status'] === 'Pending') {
        echo json_encode(['success' => false, 'message' => 'Your application is still under review. Check your email for updates.']);
        exit;
    } 
    
    if ($user['admin_status'] === 'Rejected') {
        $rejectionDate = new DateTime($user['rejected_at']);
        $now = new DateTime();
        $interval = $rejectionDate->diff($now);

        if ($interval->days < 14) {
            $daysLeft = 14 - $interval->days;
            echo json_encode(['success' => false, 'message' => "Your application was rejected. You may try again in $daysLeft days."]);
            exit;
        }
    }

    // SUCCESS: If they reach here, they are Approved (or the 14 days passed)
    $_SESSION['user_id'] = $user['user_id'];
    $_SESSION['role'] = $user['role'];
    echo json_encode(['success' => true, 'redirect' => 'dashboard.php']);

} else {
    echo json_encode(['success' => false, 'message' => 'Invalid email or password.']);
}