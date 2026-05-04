<?php
/**
 * db_connect.php
 * CommuniServe — PDO Database Connection
 * ─────────────────────────────────────────────────────────────────
 * LOCATION: /php/db_connect.php
 * USAGE:    require_once __DIR__ . '/../php/db_connect.php';
 *           Then use $pdo directly.
 * ─────────────────────────────────────────────────────────────────
 * SECURITY NOTES:
 *   • Never echo $e->getMessage() in production — log it instead.
 *   • Move credentials to a .env file or config outside web root
 *     before going live on a public server.
 * ─────────────────────────────────────────────────────────────────
 */

// ── Connection credentials ──────────────────────────────────────
// For XAMPP defaults: host=localhost, user=root, pass=''
// Change DB_PASS if you set a MySQL root password in phpMyAdmin.

define('DB_HOST', 'localhost');
define('DB_NAME', 'communiserve');
define('DB_USER', 'root');
define('DB_PASS', '');          // ← update if you have a password
define('DB_CHARSET', 'utf8mb4');

// ── PDO options ─────────────────────────────────────────────────
$dsn = sprintf(
    'mysql:host=%s;dbname=%s;charset=%s',
    DB_HOST,
    DB_NAME,
    DB_CHARSET
);

$pdoOptions = [
    // Throw exceptions on every DB error (caught by try/catch below)
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,

    // Return rows as associative arrays by default
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,

    // Disable emulated prepares — use real server-side prepared statements
    // This is the PRIMARY defence against SQL injection.
    PDO::ATTR_EMULATE_PREPARES   => false,

    // Keep connection alive with XAMPP (prevents "MySQL server has gone away")
    PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci",
];

// ── Create connection ────────────────────────────────────────────
try {
    $pdo = new PDO($dsn, DB_USER, DB_PASS, $pdoOptions);
} catch (PDOException $e) {
    // Log error to PHP error log (visible in XAMPP → xampp/apache/logs/error.log)
    error_log('[CommuniServe DB Error] ' . $e->getMessage());

    // Send JSON error response (used by fetch() in sp_steps.js)
    http_response_code(500);
    header('Content-Type: application/json');
    echo json_encode([
        'success' => false,
        'error'   => 'Database connection failed. Please contact the administrator.',
        // Uncomment next line ONLY during local development:
        // 'debug'  => $e->getMessage(),
    ]);
    exit;
}

/**
 * Helper: sanitize a string value coming from $_POST.
 * Returns null if the value is empty/whitespace, trimmed string otherwise.
 * Usage: $val = clean($_POST['last_name']);
 */
function clean(?string $value): ?string
{
    if ($value === null) return null;
    $trimmed = trim($value);
    return ($trimmed === '' || strtolower($trimmed) === 'na') ? null : $trimmed;
}

/**
 * Helper: return 1 or 0 for a checkbox POST value.
 * HTML checkboxes only appear in $_POST when checked.
 * Usage: $val = checkbox('is_4ps_beneficiary');
 */
function checkbox(string $name): int
{
    return isset($_POST[$name]) && $_POST[$name] === '1' ? 1 : 0;
}