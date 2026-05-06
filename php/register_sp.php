<?php
/**
 * register_sp.php
 * CommuniServe — Service Provider Registration Processor
 * ─────────────────────────────────────────────────────────────────
 * LOCATION : /php/register_sp.php
 * CALLED BY: SP/html/form1.html  (fetch POST from sp_steps.js)
 * METHOD   : POST
 * RESPONSE : JSON  { success: bool, message: string, provider_id?: int }
 * ─────────────────────────────────────────────────────────────────
 * INSERTS INTO:
 *   1. users              (role = 'Provider')
 *   2. providers          (trade_category, admin_status = 'Pending')
 *   3. nsrp_details       (all personal / socio-economic fields)
 *   4. employment_details (status, education, history)
 *   5. provider_files     (paths to uploaded files)
 *
 * ALLOWED TRADE CATEGORIES (strict):
 *   Carpenter | Electrician | Kasambahay
 *
 * FILE UPLOAD FOLDERS (relative to project root):
 *   uploads/national_ids/
 *   uploads/photos/
 *   uploads/secondary_ids/
 *   uploads/certificates/
 * ─────────────────────────────────────────────────────────────────
 */

declare(strict_types=1);

// ── 1. Bootstrap ─────────────────────────────────────────────────
header('Content-Type: application/json');
header('X-Content-Type-Options: nosniff');

// Only accept POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed.']);
    exit;
}

require_once __DIR__ . '/db_connect.php';   // supplies $pdo, clean(), checkbox()


// ── 2. Constants ──────────────────────────────────────────────────

// Absolute path to /uploads/ folder (sits at project root, one level above /php/)
define('UPLOAD_ROOT', realpath(__DIR__ . '/../uploads') . DIRECTORY_SEPARATOR);

// Allowed trade categories — strictly enforced
const ALLOWED_TRADES = ['Carpenter', 'Electrician', 'Kasambahay'];

// Max file size: 5 MB
const MAX_FILE_BYTES = 5 * 1024 * 1024;

// Allowed MIME types for uploads
const ALLOWED_MIME = [
    'image/jpeg',
    'image/png',
    'application/pdf',
];

// Maps file input name → subfolder and db enum value
const FILE_MAP = [
    'file_national_id'  => ['folder' => 'national_ids',  'type' => 'national_id'],
    'file_photo'        => ['folder' => 'photos',         'type' => 'photo'],
    'file_national_id_back' => ['folder' => 'national_ids',  'type' => 'national_id_back'],
    'file_certificate'  => ['folder' => 'certificates',   'type' => 'certificate'],
];


// ── 3. Input Collection & Validation ─────────────────────────────

$errors = [];

// ── STEP 1: Personal Info ─────────────────────────────────────────

// users table
$email          = clean($_POST['email']          ?? null);
$contact_number = clean($_POST['contact_number'] ?? null);
$barangay       = clean($_POST['pres_barangay']  ?? null);  // users.barangay mirrors pres_barangay
$municipality   = clean($_POST['pres_city']      ?? null) ?? 'Anini-y';
$province       = clean($_POST['pres_province']  ?? null) ?? 'Antique';

// nsrp_details — name block
$last_name      = clean($_POST['last_name']   ?? null);
$first_name     = clean($_POST['first_name']  ?? null);
$middle_name    = clean($_POST['middle_name'] ?? null);
$suffix         = clean($_POST['suffix']      ?? null);

// nsrp_details — demographics
$date_of_birth  = clean($_POST['date_of_birth'] ?? null);
$age            = isset($_POST['age']) && is_numeric($_POST['age'])
                    ? (int)$_POST['age'] : null;
$sex            = clean($_POST['sex'] ?? null);
$civil_status   = clean($_POST['civil_status'] ?? null);

// nsrp_details — address
$pres_street    = clean($_POST['pres_street']   ?? null);
$pres_barangay  = clean($_POST['pres_barangay'] ?? null);
$pres_city      = clean($_POST['pres_city']     ?? null);
$pres_province  = clean($_POST['pres_province'] ?? null);

// Permanent address — null when same_as_permanent was checked
$same_address   = isset($_POST['same_as_permanent']) && $_POST['same_as_permanent'] === '1';
$perm_street    = $same_address ? $pres_street   : clean($_POST['perm_street']   ?? null);
$perm_barangay  = $same_address ? $pres_barangay : clean($_POST['perm_barangay'] ?? null);
$perm_city      = $same_address ? $pres_city     : clean($_POST['perm_city']     ?? null);
$perm_province  = $same_address ? $pres_province : clean($_POST['perm_province'] ?? null);

// nsrp_details — parents
$father_name    = clean($_POST['father_name']    ?? null);
$father_contact = clean($_POST['father_contact'] ?? null);
$mother_name    = clean($_POST['mother_name']    ?? null);
$mother_contact = clean($_POST['mother_contact'] ?? null);
$parents_civil_status = clean($_POST['parents_civil_status'] ?? null);

// nsrp_details — socio-economic (5 booleans — Final Schema)
$is_4ps_beneficiary = checkbox('is_4ps_beneficiary');
$is_indigent        = checkbox('is_indigent');
$is_pwd             = checkbox('is_pwd');
$is_senior_citizen  = checkbox('is_senior_citizen');
$is_solo_parent     = checkbox('is_solo_parent');

// ── STEP 2: Professional Profile ─────────────────────────────────

$employment_status   = clean($_POST['employment_status']   ?? null);
$employment_type     = clean($_POST['employment_type']     ?? null) ?? 'Not Applicable';
$unemployment_reason = clean($_POST['unemployment_reason'] ?? null) ?? 'Not Applicable';
$self_employed_spec  = clean($_POST['self_employed_spec']  ?? null);

// Education
$highest_education    = clean($_POST['highest_education']    ?? null);
$school_last_attended = clean($_POST['school_last_attended'] ?? null);
$course_completed     = clean($_POST['course_completed']     ?? null);
$year_graduated       = isset($_POST['year_graduated']) && is_numeric($_POST['year_graduated'])
                            ? (int)$_POST['year_graduated'] : null;
$employment_history   = clean($_POST['employment_history'] ?? null);

// ── STEP 3: Trade Selection ───────────────────────────────────────
$trade_category = clean($_POST['trade_category'] ?? null);

// ── Step 4: Assessment — no user input, handled by Admin ─────────
// (admin_status defaults to 'Pending' in providers table)

// ── Password — registration assigns a temporary password ─────────
// Real flow: generate a random temp password, email it to provider.
// For Phase 1: use a placeholder hash. Admin resets on approval.
$temp_password  = 'TempPass_' . bin2hex(random_bytes(4));
$password_hash  = password_hash($temp_password, PASSWORD_BCRYPT);


// ── 4. Server-Side Validation ─────────────────────────────────────

// Required: name
if (!$last_name)  $errors[] = 'Last name is required.';
if (!$first_name) $errors[] = 'First name is required.';

// Required: email
if (!$email) {
    $errors[] = 'Email address is required.';
} elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $errors[] = 'Invalid email address format.';
}

// Required: demographics
if (!$date_of_birth) $errors[] = 'Date of birth is required.';
if (!$sex)           $errors[] = 'Sex is required.';
if (!$civil_status)  $errors[] = 'Civil status is required.';

// Required: address
if (!$pres_barangay) $errors[] = 'Barangay is required.';
if (!$pres_city)     $errors[] = 'Municipality is required.';
if (!$pres_province) $errors[] = 'Province is required.';

// Required: employment status
if (!$employment_status) $errors[] = 'Employment status is required.';

// Trade category — strict whitelist
if (!$trade_category) {
    $errors[] = 'Trade category is required.';
} elseif (!in_array($trade_category, ALLOWED_TRADES, true)) {
    $errors[] = 'Invalid trade category. Must be Carpenter, Electrician, or Kasambahay.';
}

// Age sanity check
if ($age !== null && ($age < 15 || $age > 120)) {
    $errors[] = 'Age must be between 15 and 120.';
}

// If validation failed, return errors immediately
if (!empty($errors)) {
    http_response_code(422);
    echo json_encode(['success' => false, 'errors' => $errors]);
    exit;
}


// ── 5. File Upload Processing ─────────────────────────────────────

/**
 * processUpload(string $inputName): array|null
 * Returns ['path' => string, 'original' => string] on success, null if no file.
 * Throws RuntimeException on invalid file.
 */
function processUpload(string $inputName): ?array
{
    if (!isset($_FILES[$inputName]) || $_FILES[$inputName]['error'] === UPLOAD_ERR_NO_FILE) {
        return null;
    }

    $file = $_FILES[$inputName];

    // Check for upload errors
    if ($file['error'] !== UPLOAD_ERR_OK) {
        throw new RuntimeException("Upload error for {$inputName}: code {$file['error']}");
    }

    // Size check
    if ($file['size'] > MAX_FILE_BYTES) {
        throw new RuntimeException("File {$inputName} exceeds 5 MB limit.");
    }

    // MIME type check using finfo (more reliable than $_FILES['type'])
    $finfo    = new finfo(FILEINFO_MIME_TYPE);
    $mimeType = $finfo->file($file['tmp_name']);
    if (!in_array($mimeType, ALLOWED_MIME, true)) {
        throw new RuntimeException("File {$inputName} has an invalid type ({$mimeType}). Only JPG, PNG, PDF allowed.");
    }

    // Determine extension
    $extMap = [
        'image/jpeg'      => 'jpg',
        'image/png'       => 'png',
        'application/pdf' => 'pdf',
    ];
    $ext = $extMap[$mimeType];

    // Build a unique, clean filename — no user-supplied names in the path
    $config     = FILE_MAP[$inputName];
    $folder     = UPLOAD_ROOT . $config['folder'] . DIRECTORY_SEPARATOR;
    $uniqueName = uniqid('cs_', true) . '_' . time() . '.' . $ext;
    $destPath   = $folder . $uniqueName;

    // Ensure folder exists
    if (!is_dir($folder)) {
        mkdir($folder, 0755, true);
    }

    if (!move_uploaded_file($file['tmp_name'], $destPath)) {
        throw new RuntimeException("Failed to move uploaded file for {$inputName}.");
    }

    // Return relative path for storage in DB
    $relativePath = 'uploads/' . $config['folder'] . '/' . $uniqueName;

    return [
        'path'     => $relativePath,
        'original' => basename($file['name']),
        'type'     => $config['type'],
    ];
}

// Validate required files (National ID and Photo)
$uploadedFiles = [];
$fileErrors    = [];

foreach (FILE_MAP as $inputName => $config) {
    try {
        $result = processUpload($inputName);
        if ($result !== null) {
            $uploadedFiles[] = $result;
        } elseif (in_array($inputName, ['file_national_id', 'file_national_id_back', 'file_photo'], true)) {
            // These three are REQUIRED
            $fileErrors[] = ucfirst(str_replace('_', ' ', $inputName)) . ' is required.';
        }
        // If file_certificate is null, it just skips it without error now!
    } catch (RuntimeException $e) {
        $fileErrors[] = $e->getMessage();
    }
}

if (!empty($fileErrors)) {
    http_response_code(422);
    echo json_encode(['success' => false, 'errors' => $fileErrors]);
    exit;
}


// ── 6. Database Transaction ───────────────────────────────────────
// All 4 table inserts + file records happen in one atomic transaction.
// If anything fails, the entire registration is rolled back cleanly.

try {
    $pdo->beginTransaction();

    // ── 6a. Check email uniqueness & Rejection Timer ───────────────
    $stmtCheck = $pdo->prepare('
        SELECT u.user_id, p.admin_status, p.rejected_at 
        FROM users u 
        LEFT JOIN providers p ON u.user_id = p.user_id 
        WHERE u.email = ? LIMIT 1
    ');
    $stmtCheck->execute([$email]);
    $existingUser = $stmtCheck->fetch();

    if ($existingUser) {
        if ($existingUser['admin_status'] === 'Rejected' && $existingUser['rejected_at'] !== null) {
            $rejectionDate = new DateTime($existingUser['rejected_at']);
            $now = new DateTime();
            $diff = $rejectionDate->diff($now);
            
            // Check if 14 days have passed
            if ($diff->days < 14) {
                $daysLeft = 14 - $diff->days;
                $pdo->rollBack();
                http_response_code(409);
                echo json_encode([
                    'success' => false,
                    'errors'  => ["Your previous application was rejected. Please wait $daysLeft more days to re-apply."]
                ]);
                exit;
            } else {
                // 14 days HAVE passed. Delete the old rejected records so they can start fresh.
                // This prevents duplicate IDs while allowing a new clean submission.
                $stmtDel = $pdo->prepare('DELETE FROM users WHERE user_id = ?');
                $stmtDel->execute([$existingUser['user_id']]);
                // The script will now continue to create the NEW record below.
            }
        } else {
            // Email exists and is either 'Pending' or 'Approved'
            $pdo->rollBack();
            http_response_code(409);
            echo json_encode([
                'success' => false, 
                'errors' => ['This email address is already registered and active or pending.']
            ]);
            exit;
        }
    }

    // ── 6b. INSERT: users ─────────────────────────────────────────
    $stmtUser = $pdo->prepare('
        INSERT INTO users
            (full_name, email, password_hash, role,
             contact_number, barangay, municipality, province)
        VALUES
            (:full_name, :email, :password_hash, :role,
             :contact_number, :barangay, :municipality, :province)
    ');
    $stmtUser->execute([
        ':full_name'      => trim("{$first_name} {$middle_name} {$last_name}"),
        ':email'          => $email,
        ':password_hash'  => $password_hash,
        ':role'           => 'Provider',
        ':contact_number' => $contact_number,
        ':barangay'       => $pres_barangay,
        ':municipality'   => $municipality,
        ':province'       => $province,
    ]);
    $userId = (int)$pdo->lastInsertId();

    // ── 6c. INSERT: providers ─────────────────────────────────────
    $stmtProv = $pdo->prepare('
        INSERT INTO providers
            (user_id, trade_category, admin_status, average_rating)
        VALUES
            (:user_id, :trade_category, :admin_status, :average_rating)
    ');
    $stmtProv->execute([
        ':user_id'        => $userId,
        ':trade_category' => $trade_category,
        ':admin_status'   => 'Pending',     // always starts as Pending
        ':average_rating' => 0.00,
    ]);
    $providerId = (int)$pdo->lastInsertId();

    // ── 6d. INSERT: nsrp_details ──────────────────────────────────
    $stmtNsrp = $pdo->prepare('
        INSERT INTO nsrp_details (
            provider_id,
            last_name, first_name, middle_name, suffix,
            date_of_birth, age, sex, civil_status,
            pres_street, pres_barangay, pres_city, pres_province,
            perm_street, perm_barangay, perm_city, perm_province,
            father_name, father_contact,
            mother_name, mother_contact,
            parents_civil_status,
            is_4ps_beneficiary, is_indigent, is_pwd,
            is_senior_citizen, is_solo_parent
        ) VALUES (
            :provider_id,
            :last_name, :first_name, :middle_name, :suffix,
            :date_of_birth, :age, :sex, :civil_status,
            :pres_street, :pres_barangay, :pres_city, :pres_province,
            :perm_street, :perm_barangay, :perm_city, :perm_province,
            :father_name, :father_contact,
            :mother_name, :mother_contact,
            :parents_civil_status,
            :is_4ps_beneficiary, :is_indigent, :is_pwd,
            :is_senior_citizen, :is_solo_parent
        )
    ');
    $stmtNsrp->execute([
        ':provider_id'         => $providerId,
        ':last_name'           => $last_name,
        ':first_name'          => $first_name,
        ':middle_name'         => $middle_name,
        ':suffix'              => $suffix,
        ':date_of_birth'       => $date_of_birth,
        ':age'                 => $age,
        ':sex'                 => $sex,
        ':civil_status'        => $civil_status,
        ':pres_street'         => $pres_street,
        ':pres_barangay'       => $pres_barangay,
        ':pres_city'           => $pres_city,
        ':pres_province'       => $pres_province,
        ':perm_street'         => $perm_street,
        ':perm_barangay'       => $perm_barangay,
        ':perm_city'           => $perm_city,
        ':perm_province'       => $perm_province,
        ':father_name'         => $father_name,
        ':father_contact'      => $father_contact,
        ':mother_name'         => $mother_name,
        ':mother_contact'      => $mother_contact,
        ':parents_civil_status'=> $parents_civil_status,
        ':is_4ps_beneficiary'  => $is_4ps_beneficiary,
        ':is_indigent'         => $is_indigent,
        ':is_pwd'              => $is_pwd,
        ':is_senior_citizen'   => $is_senior_citizen,
        ':is_solo_parent'      => $is_solo_parent,
    ]);

    // ── 6e. INSERT: employment_details ───────────────────────────
    $stmtEmp = $pdo->prepare('
        INSERT INTO employment_details (
            provider_id,
            employment_status, employment_type,
            unemployment_reason, self_employed_spec,
            highest_education, school_last_attended,
            course_completed, year_graduated,
            employment_history
        ) VALUES (
            :provider_id,
            :employment_status, :employment_type,
            :unemployment_reason, :self_employed_spec,
            :highest_education, :school_last_attended,
            :course_completed, :year_graduated,
            :employment_history
        )
    ');
    $stmtEmp->execute([
        ':provider_id'         => $providerId,
        ':employment_status'   => $employment_status,
        ':employment_type'     => $employment_type,
        ':unemployment_reason' => $unemployment_reason,
        ':self_employed_spec'  => $self_employed_spec,
        ':highest_education'   => $highest_education,
        ':school_last_attended'=> $school_last_attended,
        ':course_completed'    => $course_completed,
        ':year_graduated'      => $year_graduated,
        ':employment_history'  => $employment_history,
    ]);

    // ── 6f. INSERT: provider_files ───────────────────────────────
    if (!empty($uploadedFiles)) {
        $stmtFile = $pdo->prepare('
            INSERT INTO provider_files
                (provider_id, file_type, file_path, original_name)
            VALUES
                (:provider_id, :file_type, :file_path, :original_name)
        ');
        foreach ($uploadedFiles as $file) {
            $stmtFile->execute([
                ':provider_id'  => $providerId,
                ':file_type'    => $file['type'],
                ':file_path'    => $file['path'],
                ':original_name'=> $file['original'],
            ]);
        }
    }

    // ── Commit ────────────────────────────────────────────────────
    $pdo->commit();

    // ── 7. Success Response ───────────────────────────────────────
    echo json_encode([
        'success'     => true,
        'message'     => 'Registration submitted successfully. Your application is now Pending LGU review.',
        'provider_id' => $providerId,
        // Temp password shown once — in production, email this instead of returning it
        // 'temp_password' => $temp_password,
    ]);

} catch (PDOException $e) {
    // Roll back all inserts if anything failed
    if ($pdo->inTransaction()) {
        $pdo->rollBack();
    }

    // Delete any files that were already uploaded (cleanup)
    foreach ($uploadedFiles as $file) {
        $fullPath = realpath(__DIR__ . '/../') . DIRECTORY_SEPARATOR
                    . str_replace('/', DIRECTORY_SEPARATOR, $file['path']);
        if (file_exists($fullPath)) {
            unlink($fullPath);
        }
    }

    error_log('[CommuniServe Registration Error] ' . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error'   => 'Registration failed due to a server error. Please try again.',
        // Uncomment for local debug only:
        //'debug' => $e->getMessage(),
    ]);
}