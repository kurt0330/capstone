-- =============================================================================
-- PROJECT    : CommuniServe
-- DATABASE   : MySQL 8.0+
-- VERSION    : FINAL (Clean Schema)
-- DESCRIPTION: Full schema with inline Data Dictionary comments.
--              Import into Visual Paradigm via Tools > DB > Import DDL Script.
--
-- CONFIRMED REMOVALS (applied from schema review):
--   nsrp_details      → removed: is_victim_armed_conflict,
--                                is_sugar_plantation_worker,
--                                parents_unemployment_type
--   employment_details → removed entire Job Preference section:
--                                job_preference_local,
--                                job_preference_abroad,
--                                preferred_occupation,
--                                preferred_industry,
--                                expected_salary
--
-- TOTAL TABLES : 10
-- TRIGGERS     : 1
-- =============================================================================

CREATE DATABASE IF NOT EXISTS communiserve
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE communiserve;

-- =============================================================================
-- TABLE 1: users
-- Central authentication table. Every actor (Customer, Provider, Admin)
-- has exactly ONE row here, distinguished by `role`.
-- =============================================================================
CREATE TABLE users (
    user_id        INT          NOT NULL AUTO_INCREMENT,
    full_name      VARCHAR(150) NOT NULL,
    email          VARCHAR(150) NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    role           ENUM('Customer', 'Provider', 'Admin') NOT NULL,
    contact_number VARCHAR(15)  DEFAULT NULL,
    barangay       VARCHAR(100) NOT NULL,
    municipality   VARCHAR(100) NOT NULL DEFAULT 'Anini-y',
    province       VARCHAR(100) NOT NULL DEFAULT 'Antique',
    created_at     TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     TIMESTAMP    NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB;


-- =============================================================================
-- TABLE 2: customers
-- One-to-one extension of `users` for the Customer role.
-- =============================================================================
CREATE TABLE customers (
    customer_id        INT          NOT NULL AUTO_INCREMENT,
    user_id            INT          NOT NULL,           -- FK → users (1:1)
    preferred_barangay VARCHAR(100) DEFAULT NULL,       -- Default filter for searches

    PRIMARY KEY (customer_id),
    UNIQUE KEY uq_customers_user (user_id),             -- Enforces 1:1 with users
    CONSTRAINT fk_customers_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- TABLE 3: providers
-- One-to-one extension of `users` for the Provider role.
-- `admin_status` = 'Approved' is the SEARCH GATE — only approved providers
-- appear in customer search results.
-- =============================================================================
CREATE TABLE providers (
    provider_id    INT            NOT NULL AUTO_INCREMENT,
    user_id        INT            NOT NULL,             -- FK → users (1:1)
    trade_category ENUM(
                       'Carpenter',
                       'Electrician',
                       'Kasambahay',
                       'Nanny',
                       'Other'
                   )              NOT NULL,
    admin_status   ENUM(
                       'Pending',
                       'Approved',
                       'Rejected',
                       'Suspended'
                   )              NOT NULL DEFAULT 'Pending',
    average_rating DECIMAL(3,2)  NOT NULL DEFAULT 0.00, -- Auto-updated by trigger; range 0.00–5.00
    bio            TEXT          DEFAULT NULL,           -- Portfolio / self-description

    PRIMARY KEY (provider_id),
    UNIQUE KEY uq_providers_user (user_id),             -- Enforces 1:1 with users
    CONSTRAINT fk_providers_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- TABLE 4: admins
-- One-to-one extension of `users` for the LGU / PESO Admin role.
-- Provider accounts are created exclusively by this role.
-- =============================================================================
CREATE TABLE admins (
    admin_id   INT          NOT NULL AUTO_INCREMENT,
    user_id    INT          NOT NULL,                   -- FK → users (1:1)
    office     VARCHAR(100) NOT NULL DEFAULT 'PESO',    -- e.g., PESO, BESO
    position   VARCHAR(100) DEFAULT NULL,               -- e.g., Employment Officer

    PRIMARY KEY (admin_id),
    UNIQUE KEY uq_admins_user (user_id),
    CONSTRAINT fk_admins_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- TABLE 5: nsrp_details
-- DOLE NSRP Form 1 — Personal Information.
-- One-to-one with `providers`.
--
-- CLEAN SCHEMA: Socio-economic block contains exactly 5 boolean fields.
--   REMOVED: is_victim_armed_conflict
--   REMOVED: is_sugar_plantation_worker
--   REMOVED: parents_unemployment_type
-- =============================================================================
CREATE TABLE nsrp_details (
    nsrp_id              INT              NOT NULL AUTO_INCREMENT,
    provider_id          INT              NOT NULL,     -- FK → providers (1:1)

    -- ── Personal Name Block ──────────────────────────────────────────────────
    last_name            VARCHAR(80)      NOT NULL,
    first_name           VARCHAR(80)      NOT NULL,
    middle_name          VARCHAR(80)      DEFAULT NULL,
    suffix               VARCHAR(10)      DEFAULT NULL, -- Sr., Jr., III, etc.

    -- ── Birth & Demographics ─────────────────────────────────────────────────
    date_of_birth        DATE             NOT NULL,
    age                  TINYINT UNSIGNED NOT NULL,     -- Range 0–255 is sufficient
    sex                  ENUM(
                             'Male',
                             'Female'
                         )                NOT NULL,
    civil_status         ENUM(
                             'Single',
                             'Married',
                             'Widowed',
                             'Separated'
                         )                NOT NULL,

    -- ── Present Address ───────────────────────────────────────────────────────
    pres_street          VARCHAR(150)     DEFAULT NULL, -- House No. / Street / Village
    pres_barangay        VARCHAR(100)     NOT NULL,
    pres_city            VARCHAR(100)     NOT NULL,
    pres_province        VARCHAR(100)     NOT NULL,

    -- ── Permanent Address (NULL = same as present) ────────────────────────────
    perm_street          VARCHAR(150)     DEFAULT NULL,
    perm_barangay        VARCHAR(100)     DEFAULT NULL,
    perm_city            VARCHAR(100)     DEFAULT NULL,
    perm_province        VARCHAR(100)     DEFAULT NULL,

    -- ── Parent / Guardian Information ─────────────────────────────────────────
    father_name          VARCHAR(150)     DEFAULT NULL,
    father_contact       VARCHAR(15)      DEFAULT NULL,
    mother_name          VARCHAR(150)     DEFAULT NULL,
    mother_contact       VARCHAR(15)      DEFAULT NULL,
    parents_civil_status ENUM(
                             'Living Together',
                             'Solo Parent',
                             'Separated'
                         )                DEFAULT NULL,

    -- ── Socio-Economic Indicators (5 fields — FINAL) ──────────────────────────
    -- Maps directly to Form 1 checkboxes. All default FALSE (unchecked).
    is_4ps_beneficiary   BOOLEAN          NOT NULL DEFAULT FALSE,
    is_indigent          BOOLEAN          NOT NULL DEFAULT FALSE,
    is_pwd               BOOLEAN          NOT NULL DEFAULT FALSE, -- Person with Disability
    is_senior_citizen    BOOLEAN          NOT NULL DEFAULT FALSE,
    is_solo_parent       BOOLEAN          NOT NULL DEFAULT FALSE,

    PRIMARY KEY (nsrp_id),
    UNIQUE KEY uq_nsrp_provider (provider_id),          -- Enforces 1:1 with providers
    CONSTRAINT fk_nsrp_provider
        FOREIGN KEY (provider_id) REFERENCES providers (provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- TABLE 6: employment_details
-- DOLE NSRP Form 2 — Professional Profile.
-- One-to-one with `providers`.
--
-- CLEAN SCHEMA: Contains 3 sections only.
--   REMOVED: Entire Job Preference section
--            (job_preference_local, job_preference_abroad,
--             preferred_occupation, preferred_industry, expected_salary)
-- =============================================================================
CREATE TABLE employment_details (
    employment_id       INT          NOT NULL AUTO_INCREMENT,
    provider_id         INT          NOT NULL,           -- FK → providers (1:1)

    -- ── Section A: Current Employment Status ──────────────────────────────────
    employment_status   ENUM(
                            'Employed',
                            'Unemployed'
                        )            NOT NULL,
    employment_type     ENUM(
                            'Wage Employed',
                            'Self Employed',
                            'Not Applicable'
                        )            NOT NULL DEFAULT 'Not Applicable',
    unemployment_reason ENUM(
                            'New Entrant/Fresh Graduate',
                            'Finished Contract',
                            'Resigned',
                            'Retired',
                            'Terminated/Laid Off due to Calamity',
                            'Terminated/Laid Off (Local)',
                            'Terminated/Laid Off (Abroad)',
                            'Not Applicable'
                        )            NOT NULL DEFAULT 'Not Applicable',
    self_employed_spec  VARCHAR(100) DEFAULT NULL,       -- e.g., Nanny, Electrician, Carpenter

    -- ── Section B: Educational Background ────────────────────────────────────
    highest_education   ENUM(
                            'No Formal Education',
                            'Elementary Undergraduate',
                            'Elementary Graduate',
                            'High School Undergraduate',
                            'High School Graduate',
                            'Vocational/Technical',
                            'College Undergraduate',
                            'College Graduate',
                            'Post Graduate'
                        )            DEFAULT NULL,
    school_last_attended VARCHAR(150) DEFAULT NULL,
    course_completed     VARCHAR(150) DEFAULT NULL,
    year_graduated       YEAR        DEFAULT NULL,

    -- ── Section C: Employment History ────────────────────────────────────────
    employment_history   TEXT        DEFAULT NULL,       -- Free-text narrative

    PRIMARY KEY (employment_id),
    UNIQUE KEY uq_employment_provider (provider_id),    -- Enforces 1:1 with providers
    CONSTRAINT fk_employment_provider
        FOREIGN KEY (provider_id) REFERENCES providers (provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- TABLE 7: skills
-- One-to-many with `providers`.
-- A provider may list multiple skills beyond their primary trade category.
-- =============================================================================
CREATE TABLE skills (
    skill_id         INT              NOT NULL AUTO_INCREMENT,
    provider_id      INT              NOT NULL,          -- FK → providers
    skill_name       VARCHAR(100)     NOT NULL,          -- e.g., Plumbing, Tile-setting
    description      VARCHAR(255)     DEFAULT NULL,      -- Brief elaboration
    years_experience TINYINT UNSIGNED NOT NULL DEFAULT 0,

    PRIMARY KEY (skill_id),
    CONSTRAINT fk_skills_provider
        FOREIGN KEY (provider_id) REFERENCES providers (provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- TABLE 8: assessments
-- One-to-many with `providers` AND `admins`.
-- `lgu_status` combined with `providers.admin_status` forms the two-step
-- approval gate before a provider appears in search results.
-- =============================================================================
CREATE TABLE assessments (
    assessment_id INT           NOT NULL AUTO_INCREMENT,
    provider_id   INT           NOT NULL,               -- FK → providers
    admin_id      INT           NOT NULL,               -- FK → admins (the grader)
    test_score    DECIMAL(5,2)  DEFAULT NULL,            -- e.g., 85.50 out of 100.00
    lgu_status    ENUM(
                      'Pending',
                      'Passed',
                      'Failed'
                  )             NOT NULL DEFAULT 'Pending',
    remarks       TEXT          DEFAULT NULL,            -- Admin notes / feedback
    assessed_at   TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (assessment_id),
    CONSTRAINT fk_assessments_provider
        FOREIGN KEY (provider_id) REFERENCES providers (provider_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_assessments_admin
        FOREIGN KEY (admin_id) REFERENCES admins (admin_id)
        ON DELETE RESTRICT                              -- Protect audit trail
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- TABLE 9: job_requests
-- Core transactional table. Implements the full hiring lifecycle:
--
--   Pending → Accepted  → Ongoing → Completed
--           ↘ Declined
--           ↘ Cancelled  (customer cancels before acceptance)
--
-- Ratings can ONLY be inserted once job_status = 'Completed'.
-- =============================================================================
CREATE TABLE job_requests (
    job_id              INT          NOT NULL AUTO_INCREMENT,
    customer_id         INT          NOT NULL,           -- FK → customers
    provider_id         INT          NOT NULL,           -- FK → providers
    service_description TEXT         NOT NULL,           -- What the customer needs
    service_street      VARCHAR(150) DEFAULT NULL,       -- Exact work address
    service_barangay    VARCHAR(100) NOT NULL,           -- Proximity-matching barangay
    job_status          ENUM(
                            'Pending',
                            'Accepted',
                            'Declined',
                            'Ongoing',
                            'Completed',
                            'Cancelled'
                        )            NOT NULL DEFAULT 'Pending',
    requested_at        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accepted_at         TIMESTAMP    NULL DEFAULT NULL,       -- Set on Accepted
    started_at          TIMESTAMP    NULL DEFAULT NULL,       -- Set on Ongoing
    completed_at        TIMESTAMP    NULL DEFAULT NULL,       -- Set on Completed

    PRIMARY KEY (job_id),
    CONSTRAINT fk_jobreq_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_jobreq_provider
        FOREIGN KEY (provider_id) REFERENCES providers (provider_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- TABLE 10: ratings
-- One-to-one with `job_requests`.
-- UNIQUE KEY on job_id = Rating Lock: one completed job → one rating only.
-- CHECK constraint enforces 1–5 star range at the database level.
-- =============================================================================
CREATE TABLE ratings (
    rating_id   INT              NOT NULL AUTO_INCREMENT,
    job_id      INT              NOT NULL,               -- FK → job_requests (1:1)
    customer_id INT              NOT NULL,               -- FK → customers (denormalized)
    provider_id INT              NOT NULL,               -- FK → providers  (denormalized)
    stars       TINYINT UNSIGNED NOT NULL,               -- 1 to 5 only
    review_text TEXT             DEFAULT NULL,           -- Optional written feedback
    rated_at    TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (rating_id),
    UNIQUE KEY uq_rating_job (job_id),                   -- Rating Lock — one per completed job
    CONSTRAINT chk_stars
        CHECK (stars BETWEEN 1 AND 5),
    CONSTRAINT fk_ratings_job
        FOREIGN KEY (job_id) REFERENCES job_requests (job_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_ratings_customer
        FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_ratings_provider
        FOREIGN KEY (provider_id) REFERENCES providers (provider_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- =============================================================================
-- TRIGGER: trg_update_avg_rating
-- Fires AFTER every INSERT on `ratings`.
-- Recomputes providers.average_rating automatically so search results always
-- display a live score without an expensive AVG() JOIN on every page load.
-- =============================================================================
DELIMITER $$

CREATE TRIGGER trg_update_avg_rating
AFTER INSERT ON ratings
FOR EACH ROW
BEGIN
    UPDATE providers
    SET    average_rating = (
               SELECT ROUND(AVG(stars), 2)
               FROM   ratings
               WHERE  provider_id = NEW.provider_id
           )
    WHERE  provider_id = NEW.provider_id;
END$$

DELIMITER ;


-- =============================================================================
-- END OF SCRIPT
-- ─────────────────────────────────────────────────────────────────────────────
-- Tables   : 10 (users, customers, providers, admins, nsrp_details,
--                employment_details, skills, assessments,
--                job_requests, ratings)
-- Triggers : 1  (trg_update_avg_rating)
-- Removed  : is_victim_armed_conflict, is_sugar_plantation_worker,
--            parents_unemployment_type, job_preference_local,
--            job_preference_abroad, preferred_occupation,
--            preferred_industry, expected_salary
-- =============================================================================
