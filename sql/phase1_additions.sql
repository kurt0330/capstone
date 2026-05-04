USE communiserve;

-- =============================================================================
-- 1. CREATE THE TABLES (Fixed for XAMPP Timestamp rules)
-- =============================================================================

CREATE TABLE IF NOT EXISTS provider_files (
    file_id         INT           NOT NULL AUTO_INCREMENT,
    provider_id     INT           NOT NULL,
    file_type       ENUM('national_id','photo','secondary_id','certificate') NOT NULL,
    file_path       VARCHAR(300)  NOT NULL,
    original_name   VARCHAR(255)  NOT NULL,
    uploaded_at     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (file_id),
    CONSTRAINT fk_pfiles_provider FOREIGN KEY (provider_id) REFERENCES providers (provider_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS assessment_tests (
    test_id         INT           NOT NULL AUTO_INCREMENT,
    admin_id        INT           NOT NULL,
    trade_category  ENUM('Carpenter','Electrician','Kasambahay') NOT NULL,
    test_title      VARCHAR(150)  NOT NULL,
    passing_score   DECIMAL(5,2)  NOT NULL DEFAULT 75.00,
    is_active       BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP     NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (test_id),
    UNIQUE KEY uq_active_trade (trade_category, is_active),
    CONSTRAINT fk_atests_admin FOREIGN KEY (admin_id) REFERENCES admins (admin_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS assessment_questions (
    question_id     INT           NOT NULL AUTO_INCREMENT,
    test_id         INT           NOT NULL,
    question_text   TEXT          NOT NULL,
    question_order  TINYINT UNSIGNED NOT NULL DEFAULT 1,
    points          TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (question_id),
    CONSTRAINT fk_aquestions_test FOREIGN KEY (test_id) REFERENCES assessment_tests (test_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS assessment_choices (
    choice_id       INT           NOT NULL AUTO_INCREMENT,
    question_id     INT           NOT NULL,
    choice_text     VARCHAR(300)  NOT NULL,
    is_correct      BOOLEAN       NOT NULL DEFAULT FALSE,
    choice_order    TINYINT UNSIGNED NOT NULL DEFAULT 1,
    PRIMARY KEY (choice_id),
    CONSTRAINT fk_achoices_question FOREIGN KEY (question_id) REFERENCES assessment_questions (question_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS assessment_attempts (
    attempt_id      INT           NOT NULL AUTO_INCREMENT,
    provider_id     INT           NOT NULL,
    test_id         INT           NOT NULL,
    score_raw       DECIMAL(5,2)  DEFAULT NULL,
    score_pct       DECIMAL(5,2)  DEFAULT NULL,
    passed          BOOLEAN       DEFAULT NULL,
    started_at      TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    submitted_at    TIMESTAMP     NULL DEFAULT NULL,
    PRIMARY KEY (attempt_id),
    CONSTRAINT fk_attempts_provider FOREIGN KEY (provider_id) REFERENCES providers (provider_id) ON DELETE CASCADE,
    CONSTRAINT fk_attempts_test FOREIGN KEY (test_id) REFERENCES assessment_tests (test_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS assessment_answers (
    answer_id       INT           NOT NULL AUTO_INCREMENT,
    attempt_id      INT           NOT NULL,
    question_id     INT           NOT NULL,
    chosen_choice_id INT          DEFAULT NULL,
    PRIMARY KEY (answer_id),
    UNIQUE KEY uq_answer_per_question (attempt_id, question_id),
    CONSTRAINT fk_answers_attempt FOREIGN KEY (attempt_id) REFERENCES assessment_attempts (attempt_id) ON DELETE CASCADE,
    CONSTRAINT fk_answers_question FOREIGN KEY (question_id) REFERENCES assessment_questions (question_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- =============================================================================
-- 2. INSERT SEED DATA (Direct ID method to prevent Foreign Key errors)
-- =============================================================================

-- Create Admin
INSERT IGNORE INTO users (user_id, full_name, email, password_hash, role, barangay, municipality, province)
VALUES (1, 'LGU Admin', 'admin@communiserve.gov.ph', '$2y$10$placeholder', 'Admin', 'Poblacion', 'Anini-y', 'Antique');
INSERT IGNORE INTO admins (admin_id, user_id) VALUES (1, 1);

-- CARPENTER TEST
INSERT IGNORE INTO assessment_tests (test_id, admin_id, trade_category, test_title, passing_score, is_active)
VALUES (1, 1, 'Carpenter', 'Panday Competency Test v1', 75.00, TRUE);

INSERT IGNORE INTO assessment_questions (question_id, test_id, question_text, question_order) VALUES
(1, 1, 'What tool is primarily used to drive nails into wood?', 1),
(2, 1, 'Which type of joint provides the strongest connection in wood?', 2);

INSERT IGNORE INTO assessment_choices (question_id, choice_text, is_correct, choice_order) VALUES
(1, 'Screwdriver', FALSE, 1), (1, 'Claw Hammer', TRUE, 2),
(2, 'Butt Joint', FALSE, 1), (2, 'Dovetail Joint', TRUE, 2);

-- ELECTRICIAN TEST
INSERT IGNORE INTO assessment_tests (test_id, admin_id, trade_category, test_title, passing_score, is_active)
VALUES (2, 1, 'Electrician', 'Electrical Competency Test v1', 75.00, TRUE);

INSERT IGNORE INTO assessment_questions (question_id, test_id, question_text, question_order) VALUES
(3, 2, 'What color is the ground wire in PH standards?', 1),
(4, 2, 'What device protects a circuit from overloading?', 2);

INSERT IGNORE INTO assessment_choices (question_id, choice_text, is_correct, choice_order) VALUES
(3, 'Red', FALSE, 1), (3, 'Green', TRUE, 2),
(4, 'Capacitor', FALSE, 1), (4, 'Circuit Breaker', TRUE, 2);

-- KASAMBAHAY TEST
INSERT IGNORE INTO assessment_tests (test_id, admin_id, trade_category, test_title, passing_score, is_active)
VALUES (3, 1, 'Kasambahay', 'Kasambahay Competency Test v1', 75.00, TRUE);

INSERT IGNORE INTO assessment_questions (question_id, test_id, question_text, question_order) VALUES
(5, 3, 'What is the minimum rest day per week?', 1),
(6, 3, 'What should you do in a medical emergency?', 2);

INSERT IGNORE INTO assessment_choices (question_id, choice_text, is_correct, choice_order) VALUES
(5, 'No rest day', FALSE, 1), (5, 'One day per week', TRUE, 2),
(6, 'Ignore it', FALSE, 1), (6, 'Call 911', TRUE, 2);