<?php
header('Content-Type: application/json');
require_once 'db_connect.php';

try {
    // 1. Fetch the main provider and user data
    $sql = "
        SELECT
            u.user_id,
            u.full_name,
            u.contact_number,
            u.email,
            u.barangay AS user_barangay,
            u.created_at,

            p.provider_id,
            p.trade_category AS trade, 
            p.admin_status,
            p.bio,

            n.date_of_birth,
            n.age,
            n.sex,
            n.civil_status,
            n.pres_barangay AS barangay, 
            n.pres_street,
            n.perm_street,
            n.father_name,
            n.father_contact,
            n.mother_name,
            n.mother_contact,
            n.is_4ps_beneficiary,

            e.employment_status,
            e.highest_education,
            e.school_last_attended

        FROM providers p
        INNER JOIN users u ON u.user_id = p.user_id
        LEFT JOIN nsrp_details n ON n.provider_id = p.provider_id
        LEFT JOIN employment_details e ON e.provider_id = p.provider_id

        WHERE p.admin_status = 'Pending'
        ORDER BY u.created_at DESC
    ";

    $stmt = $pdo->prepare($sql);
    $stmt->execute();
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // 2. Loop through each provider to attach their files
    foreach ($rows as &$row) {
        $pid = $row['provider_id'];
        
        // Initialize these so they exist even if no file is found
        $row['national_id_front'] = null;
        $row['national_id_back'] = null;
        $row['profile_photo'] = null;

        // Query the provider_files table for this specific provider
        $fileStmt = $pdo->prepare("SELECT file_type, file_path FROM provider_files WHERE provider_id = ?");
        $fileStmt->execute([$pid]);
        $files = $fileStmt->fetchAll();

        foreach ($files as $file) {
            // Adjust the '../' depending on where your 'uploads' folder is relative to this PHP file
            $filePath = '../' . $file['file_path']; 

            if ($file['file_type'] === 'national_id') {
                $row['national_id_front'] = $filePath;
            } elseif ($file['file_type'] === 'national_id_back') {
                $row['national_id_back'] = $filePath;
            } elseif ($file['file_type'] === 'photo') {
                $row['profile_photo'] = $filePath;
            }
        }
    }

    // 3. Send the complete data back to the dashboard
    echo json_encode([
        'status' => 'success',
        'count'  => count($rows),
        'data'   => $rows
    ]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'status'  => 'error',
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}