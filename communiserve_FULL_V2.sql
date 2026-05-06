-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: May 06, 2026 at 07:00 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `communiserve`
--

-- --------------------------------------------------------

--
-- Table structure for table `admins`
--

CREATE TABLE `admins` (
  `admin_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `office` varchar(100) NOT NULL DEFAULT 'PESO',
  `position` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admins`
--

INSERT INTO `admins` (`admin_id`, `user_id`, `office`, `position`) VALUES
(1, 1, 'PESO', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `assessments`
--

CREATE TABLE `assessments` (
  `assessment_id` int(11) NOT NULL,
  `provider_id` int(11) NOT NULL,
  `admin_id` int(11) NOT NULL,
  `test_score` decimal(5,2) DEFAULT NULL,
  `lgu_status` enum('Pending','Passed','Failed') NOT NULL DEFAULT 'Pending',
  `remarks` text DEFAULT NULL,
  `assessed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `assessment_answers`
--

CREATE TABLE `assessment_answers` (
  `answer_id` int(11) NOT NULL,
  `attempt_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `chosen_choice_id` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `assessment_attempts`
--

CREATE TABLE `assessment_attempts` (
  `attempt_id` int(11) NOT NULL,
  `provider_id` int(11) NOT NULL,
  `test_id` int(11) NOT NULL,
  `score_raw` decimal(5,2) DEFAULT NULL,
  `score_pct` decimal(5,2) DEFAULT NULL,
  `passed` tinyint(1) DEFAULT NULL,
  `started_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `submitted_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `assessment_choices`
--

CREATE TABLE `assessment_choices` (
  `choice_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `choice_text` varchar(300) NOT NULL,
  `is_correct` tinyint(1) NOT NULL DEFAULT 0,
  `choice_order` tinyint(3) UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `assessment_choices`
--

INSERT INTO `assessment_choices` (`choice_id`, `question_id`, `choice_text`, `is_correct`, `choice_order`) VALUES
(1, 1, 'Screwdriver', 0, 1),
(2, 1, 'Claw Hammer', 1, 2),
(3, 2, 'Butt Joint', 0, 1),
(4, 2, 'Dovetail Joint', 1, 2),
(5, 3, 'Red', 0, 1),
(6, 3, 'Green', 1, 2),
(7, 4, 'Capacitor', 0, 1),
(8, 4, 'Circuit Breaker', 1, 2),
(9, 5, 'No rest day', 0, 1),
(10, 5, 'One day per week', 1, 2),
(11, 6, 'Ignore it', 0, 1),
(12, 6, 'Call 911', 1, 2);

-- --------------------------------------------------------

--
-- Table structure for table `assessment_questions`
--

CREATE TABLE `assessment_questions` (
  `question_id` int(11) NOT NULL,
  `test_id` int(11) NOT NULL,
  `question_text` text NOT NULL,
  `question_order` tinyint(3) UNSIGNED NOT NULL DEFAULT 1,
  `points` tinyint(3) UNSIGNED NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `assessment_questions`
--

INSERT INTO `assessment_questions` (`question_id`, `test_id`, `question_text`, `question_order`, `points`) VALUES
(1, 1, 'What tool is primarily used to drive nails into wood?', 1, 1),
(2, 1, 'Which type of joint provides the strongest connection in wood?', 2, 1),
(3, 2, 'What color is the ground wire in PH standards?', 1, 1),
(4, 2, 'What device protects a circuit from overloading?', 2, 1),
(5, 3, 'What is the minimum rest day per week?', 1, 1),
(6, 3, 'What should you do in a medical emergency?', 2, 1);

-- --------------------------------------------------------

--
-- Table structure for table `assessment_tests`
--

CREATE TABLE `assessment_tests` (
  `test_id` int(11) NOT NULL,
  `admin_id` int(11) NOT NULL,
  `trade_category` enum('Carpenter','Electrician','Kasambahay') NOT NULL,
  `test_title` varchar(150) NOT NULL,
  `passing_score` decimal(5,2) NOT NULL DEFAULT 75.00,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `assessment_tests`
--

INSERT INTO `assessment_tests` (`test_id`, `admin_id`, `trade_category`, `test_title`, `passing_score`, `is_active`, `created_at`, `updated_at`) VALUES
(1, 1, 'Carpenter', 'Panday Competency Test v1', 75.00, 1, '2026-05-06 16:06:35', NULL),
(2, 1, 'Electrician', 'Electrical Competency Test v1', 75.00, 1, '2026-05-06 16:06:35', NULL),
(3, 1, 'Kasambahay', 'Kasambahay Competency Test v1', 75.00, 1, '2026-05-06 16:06:35', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `customers`
--

CREATE TABLE `customers` (
  `customer_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `preferred_barangay` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `employment_details`
--

CREATE TABLE `employment_details` (
  `employment_id` int(11) NOT NULL,
  `provider_id` int(11) NOT NULL,
  `employment_status` enum('Employed','Unemployed') NOT NULL,
  `employment_type` enum('Wage Employed','Self Employed','Not Applicable') NOT NULL DEFAULT 'Not Applicable',
  `unemployment_reason` enum('New Entrant/Fresh Graduate','Finished Contract','Resigned','Retired','Terminated/Laid Off due to Calamity','Terminated/Laid Off (Local)','Terminated/Laid Off (Abroad)','Not Applicable') NOT NULL DEFAULT 'Not Applicable',
  `self_employed_spec` varchar(100) DEFAULT NULL,
  `highest_education` enum('No Formal Education','Elementary Undergraduate','Elementary Graduate','High School Undergraduate','High School Graduate','Vocational/Technical','College Undergraduate','College Graduate','Post Graduate') DEFAULT NULL,
  `school_last_attended` varchar(150) DEFAULT NULL,
  `course_completed` varchar(150) DEFAULT NULL,
  `year_graduated` year(4) DEFAULT NULL,
  `employment_history` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `employment_details`
--

INSERT INTO `employment_details` (`employment_id`, `provider_id`, `employment_status`, `employment_type`, `unemployment_reason`, `self_employed_spec`, `highest_education`, `school_last_attended`, `course_completed`, `year_graduated`, `employment_history`) VALUES
(1, 1, 'Unemployed', 'Not Applicable', 'New Entrant/Fresh Graduate', NULL, 'College Graduate', 'UA', NULL, '2027', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `job_requests`
--

CREATE TABLE `job_requests` (
  `job_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `provider_id` int(11) NOT NULL,
  `service_description` text NOT NULL,
  `service_street` varchar(150) DEFAULT NULL,
  `service_barangay` varchar(100) NOT NULL,
  `job_status` enum('Pending','Accepted','Declined','Ongoing','Completed','Cancelled') NOT NULL DEFAULT 'Pending',
  `requested_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `accepted_at` timestamp NULL DEFAULT NULL,
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nsrp_details`
--

CREATE TABLE `nsrp_details` (
  `nsrp_id` int(11) NOT NULL,
  `provider_id` int(11) NOT NULL,
  `last_name` varchar(80) NOT NULL,
  `first_name` varchar(80) NOT NULL,
  `middle_name` varchar(80) DEFAULT NULL,
  `suffix` varchar(10) DEFAULT NULL,
  `date_of_birth` date NOT NULL,
  `age` tinyint(3) UNSIGNED NOT NULL,
  `sex` enum('Male','Female') NOT NULL,
  `civil_status` enum('Single','Married','Widowed','Separated') NOT NULL,
  `pres_street` varchar(150) DEFAULT NULL,
  `pres_barangay` varchar(100) NOT NULL,
  `pres_city` varchar(100) NOT NULL,
  `pres_province` varchar(100) NOT NULL,
  `perm_street` varchar(150) DEFAULT NULL,
  `perm_barangay` varchar(100) DEFAULT NULL,
  `perm_city` varchar(100) DEFAULT NULL,
  `perm_province` varchar(100) DEFAULT NULL,
  `father_name` varchar(150) DEFAULT NULL,
  `father_contact` varchar(15) DEFAULT NULL,
  `mother_name` varchar(150) DEFAULT NULL,
  `mother_contact` varchar(15) DEFAULT NULL,
  `parents_civil_status` enum('Living Together','Solo Parent','Separated') DEFAULT NULL,
  `is_4ps_beneficiary` tinyint(1) NOT NULL DEFAULT 0,
  `is_indigent` tinyint(1) NOT NULL DEFAULT 0,
  `is_pwd` tinyint(1) NOT NULL DEFAULT 0,
  `is_senior_citizen` tinyint(1) NOT NULL DEFAULT 0,
  `is_solo_parent` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `nsrp_details`
--

INSERT INTO `nsrp_details` (`nsrp_id`, `provider_id`, `last_name`, `first_name`, `middle_name`, `suffix`, `date_of_birth`, `age`, `sex`, `civil_status`, `pres_street`, `pres_barangay`, `pres_city`, `pres_province`, `perm_street`, `perm_barangay`, `perm_city`, `perm_province`, `father_name`, `father_contact`, `mother_name`, `mother_contact`, `parents_civil_status`, `is_4ps_beneficiary`, `is_indigent`, `is_pwd`, `is_senior_citizen`, `is_solo_parent`) VALUES
(1, 1, 'Villojan', 'Kurt Angelo', 'Saquine', NULL, '2005-03-30', 21, 'Male', 'Single', 'purok 1', 'san francisco', 'Anini-y', 'Antique', 'purok 1', 'san francisco', 'Anini-y', 'Antique', NULL, NULL, NULL, NULL, NULL, 0, 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Table structure for table `providers`
--

CREATE TABLE `providers` (
  `provider_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `trade_category` enum('Carpenter','Electrician','Kasambahay','Nanny','Other') NOT NULL,
  `admin_status` enum('Pending','Approved','Rejected','Suspended') NOT NULL DEFAULT 'Pending',
  `rejected_at` timestamp NULL DEFAULT NULL,
  `average_rating` decimal(3,2) NOT NULL DEFAULT 0.00,
  `bio` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `providers`
--

INSERT INTO `providers` (`provider_id`, `user_id`, `trade_category`, `admin_status`, `rejected_at`, `average_rating`, `bio`) VALUES
(1, 2, 'Kasambahay', 'Pending', NULL, 0.00, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `provider_files`
--

CREATE TABLE `provider_files` (
  `file_id` int(11) NOT NULL,
  `provider_id` int(11) NOT NULL,
  `file_type` enum('national_id','national_id_back','photo','secondary_id','certificate') NOT NULL,
  `file_path` varchar(300) NOT NULL,
  `original_name` varchar(255) NOT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `provider_files`
--

INSERT INTO `provider_files` (`file_id`, `provider_id`, `file_type`, `file_path`, `original_name`, `uploaded_at`) VALUES
(1, 1, 'national_id', 'uploads/national_ids/cs_69fb72d6cb7478.94731719_1778086614.png', 'PhilID-specimen-Front_highres1-1024x576.png', '2026-05-06 16:56:54'),
(2, 1, 'photo', 'uploads/photos/cs_69fb72d6cbcfc7.40035502_1778086614.jpg', 'sample 2 by 2.jpg', '2026-05-06 16:56:54'),
(3, 1, 'national_id_back', 'uploads/national_ids/cs_69fb72d6cc1eb5.20359373_1778086614.png', 'PhilID-specimen-Front_highres1-1024x576.png', '2026-05-06 16:56:54');

-- --------------------------------------------------------

--
-- Table structure for table `ratings`
--

CREATE TABLE `ratings` (
  `rating_id` int(11) NOT NULL,
  `job_id` int(11) NOT NULL,
  `customer_id` int(11) NOT NULL,
  `provider_id` int(11) NOT NULL,
  `stars` tinyint(3) UNSIGNED NOT NULL,
  `review_text` text DEFAULT NULL,
  `rated_at` timestamp NOT NULL DEFAULT current_timestamp()
) ;

--
-- Triggers `ratings`
--
DELIMITER $$
CREATE TRIGGER `trg_update_avg_rating` AFTER INSERT ON `ratings` FOR EACH ROW BEGIN
    UPDATE providers
    SET    average_rating = (
               SELECT ROUND(AVG(stars), 2)
               FROM   ratings
               WHERE  provider_id = NEW.provider_id
           )
    WHERE  provider_id = NEW.provider_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `skills`
--

CREATE TABLE `skills` (
  `skill_id` int(11) NOT NULL,
  `provider_id` int(11) NOT NULL,
  `skill_name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `years_experience` tinyint(3) UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `full_name` varchar(150) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('Customer','Provider','Admin') NOT NULL,
  `contact_number` varchar(15) DEFAULT NULL,
  `barangay` varchar(100) NOT NULL,
  `municipality` varchar(100) NOT NULL DEFAULT 'Anini-y',
  `province` varchar(100) NOT NULL DEFAULT 'Antique',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `full_name`, `email`, `password_hash`, `role`, `contact_number`, `barangay`, `municipality`, `province`, `created_at`, `updated_at`) VALUES
(1, 'LGU Admin', 'admin@communiserve.gov.ph', '$2y$10$placeholder', 'Admin', NULL, 'Poblacion', 'Anini-y', 'Antique', '2026-05-06 16:06:35', NULL),
(2, 'Kurt Angelo Saquine Villojan', 'kurt@gmail.com', '$2y$10$3Xj6XQiMU3eFIOyX9GLUW.epV5X1LB2LnhyGwrPA6OxFGw3lcR.fm', 'Provider', NULL, 'san francisco', 'Anini-y', 'Antique', '2026-05-06 16:56:54', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admins`
--
ALTER TABLE `admins`
  ADD PRIMARY KEY (`admin_id`),
  ADD UNIQUE KEY `uq_admins_user` (`user_id`);

--
-- Indexes for table `assessments`
--
ALTER TABLE `assessments`
  ADD PRIMARY KEY (`assessment_id`),
  ADD KEY `fk_assessments_provider` (`provider_id`),
  ADD KEY `fk_assessments_admin` (`admin_id`);

--
-- Indexes for table `assessment_answers`
--
ALTER TABLE `assessment_answers`
  ADD PRIMARY KEY (`answer_id`),
  ADD UNIQUE KEY `uq_answer_per_question` (`attempt_id`,`question_id`),
  ADD KEY `fk_answers_question` (`question_id`);

--
-- Indexes for table `assessment_attempts`
--
ALTER TABLE `assessment_attempts`
  ADD PRIMARY KEY (`attempt_id`),
  ADD KEY `fk_attempts_provider` (`provider_id`),
  ADD KEY `fk_attempts_test` (`test_id`);

--
-- Indexes for table `assessment_choices`
--
ALTER TABLE `assessment_choices`
  ADD PRIMARY KEY (`choice_id`),
  ADD KEY `fk_achoices_question` (`question_id`);

--
-- Indexes for table `assessment_questions`
--
ALTER TABLE `assessment_questions`
  ADD PRIMARY KEY (`question_id`),
  ADD KEY `fk_aquestions_test` (`test_id`);

--
-- Indexes for table `assessment_tests`
--
ALTER TABLE `assessment_tests`
  ADD PRIMARY KEY (`test_id`),
  ADD UNIQUE KEY `uq_active_trade` (`trade_category`,`is_active`),
  ADD KEY `fk_atests_admin` (`admin_id`);

--
-- Indexes for table `customers`
--
ALTER TABLE `customers`
  ADD PRIMARY KEY (`customer_id`),
  ADD UNIQUE KEY `uq_customers_user` (`user_id`);

--
-- Indexes for table `employment_details`
--
ALTER TABLE `employment_details`
  ADD PRIMARY KEY (`employment_id`),
  ADD UNIQUE KEY `uq_employment_provider` (`provider_id`);

--
-- Indexes for table `job_requests`
--
ALTER TABLE `job_requests`
  ADD PRIMARY KEY (`job_id`),
  ADD KEY `fk_jobreq_customer` (`customer_id`),
  ADD KEY `fk_jobreq_provider` (`provider_id`);

--
-- Indexes for table `nsrp_details`
--
ALTER TABLE `nsrp_details`
  ADD PRIMARY KEY (`nsrp_id`),
  ADD UNIQUE KEY `uq_nsrp_provider` (`provider_id`);

--
-- Indexes for table `providers`
--
ALTER TABLE `providers`
  ADD PRIMARY KEY (`provider_id`),
  ADD UNIQUE KEY `uq_providers_user` (`user_id`);

--
-- Indexes for table `provider_files`
--
ALTER TABLE `provider_files`
  ADD PRIMARY KEY (`file_id`),
  ADD KEY `fk_pfiles_provider` (`provider_id`);

--
-- Indexes for table `ratings`
--
ALTER TABLE `ratings`
  ADD PRIMARY KEY (`rating_id`),
  ADD UNIQUE KEY `uq_rating_job` (`job_id`),
  ADD KEY `fk_ratings_customer` (`customer_id`),
  ADD KEY `fk_ratings_provider` (`provider_id`);

--
-- Indexes for table `skills`
--
ALTER TABLE `skills`
  ADD PRIMARY KEY (`skill_id`),
  ADD KEY `fk_skills_provider` (`provider_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `uq_users_email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admins`
--
ALTER TABLE `admins`
  MODIFY `admin_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `assessments`
--
ALTER TABLE `assessments`
  MODIFY `assessment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `assessment_answers`
--
ALTER TABLE `assessment_answers`
  MODIFY `answer_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `assessment_attempts`
--
ALTER TABLE `assessment_attempts`
  MODIFY `attempt_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `assessment_choices`
--
ALTER TABLE `assessment_choices`
  MODIFY `choice_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=13;

--
-- AUTO_INCREMENT for table `assessment_questions`
--
ALTER TABLE `assessment_questions`
  MODIFY `question_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `assessment_tests`
--
ALTER TABLE `assessment_tests`
  MODIFY `test_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `customers`
--
ALTER TABLE `customers`
  MODIFY `customer_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `employment_details`
--
ALTER TABLE `employment_details`
  MODIFY `employment_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `job_requests`
--
ALTER TABLE `job_requests`
  MODIFY `job_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nsrp_details`
--
ALTER TABLE `nsrp_details`
  MODIFY `nsrp_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `providers`
--
ALTER TABLE `providers`
  MODIFY `provider_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `provider_files`
--
ALTER TABLE `provider_files`
  MODIFY `file_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `ratings`
--
ALTER TABLE `ratings`
  MODIFY `rating_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `skills`
--
ALTER TABLE `skills`
  MODIFY `skill_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `admins`
--
ALTER TABLE `admins`
  ADD CONSTRAINT `fk_admins_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `assessments`
--
ALTER TABLE `assessments`
  ADD CONSTRAINT `fk_assessments_admin` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`admin_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_assessments_provider` FOREIGN KEY (`provider_id`) REFERENCES `providers` (`provider_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `assessment_answers`
--
ALTER TABLE `assessment_answers`
  ADD CONSTRAINT `fk_answers_attempt` FOREIGN KEY (`attempt_id`) REFERENCES `assessment_attempts` (`attempt_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_answers_question` FOREIGN KEY (`question_id`) REFERENCES `assessment_questions` (`question_id`) ON DELETE CASCADE;

--
-- Constraints for table `assessment_attempts`
--
ALTER TABLE `assessment_attempts`
  ADD CONSTRAINT `fk_attempts_provider` FOREIGN KEY (`provider_id`) REFERENCES `providers` (`provider_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_attempts_test` FOREIGN KEY (`test_id`) REFERENCES `assessment_tests` (`test_id`);

--
-- Constraints for table `assessment_choices`
--
ALTER TABLE `assessment_choices`
  ADD CONSTRAINT `fk_achoices_question` FOREIGN KEY (`question_id`) REFERENCES `assessment_questions` (`question_id`) ON DELETE CASCADE;

--
-- Constraints for table `assessment_questions`
--
ALTER TABLE `assessment_questions`
  ADD CONSTRAINT `fk_aquestions_test` FOREIGN KEY (`test_id`) REFERENCES `assessment_tests` (`test_id`) ON DELETE CASCADE;

--
-- Constraints for table `assessment_tests`
--
ALTER TABLE `assessment_tests`
  ADD CONSTRAINT `fk_atests_admin` FOREIGN KEY (`admin_id`) REFERENCES `admins` (`admin_id`);

--
-- Constraints for table `customers`
--
ALTER TABLE `customers`
  ADD CONSTRAINT `fk_customers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `employment_details`
--
ALTER TABLE `employment_details`
  ADD CONSTRAINT `fk_employment_provider` FOREIGN KEY (`provider_id`) REFERENCES `providers` (`provider_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `job_requests`
--
ALTER TABLE `job_requests`
  ADD CONSTRAINT `fk_jobreq_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_jobreq_provider` FOREIGN KEY (`provider_id`) REFERENCES `providers` (`provider_id`) ON UPDATE CASCADE;

--
-- Constraints for table `nsrp_details`
--
ALTER TABLE `nsrp_details`
  ADD CONSTRAINT `fk_nsrp_provider` FOREIGN KEY (`provider_id`) REFERENCES `providers` (`provider_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `providers`
--
ALTER TABLE `providers`
  ADD CONSTRAINT `fk_providers_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `provider_files`
--
ALTER TABLE `provider_files`
  ADD CONSTRAINT `fk_pfiles_provider` FOREIGN KEY (`provider_id`) REFERENCES `providers` (`provider_id`) ON DELETE CASCADE;

--
-- Constraints for table `ratings`
--
ALTER TABLE `ratings`
  ADD CONSTRAINT `fk_ratings_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ratings_job` FOREIGN KEY (`job_id`) REFERENCES `job_requests` (`job_id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_ratings_provider` FOREIGN KEY (`provider_id`) REFERENCES `providers` (`provider_id`) ON UPDATE CASCADE;

--
-- Constraints for table `skills`
--
ALTER TABLE `skills`
  ADD CONSTRAINT `fk_skills_provider` FOREIGN KEY (`provider_id`) REFERENCES `providers` (`provider_id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
