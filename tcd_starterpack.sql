CREATE TABLE IF NOT EXISTS `tcd_starterpack` (
  `id` int AUTO_INCREMENT PRIMARY KEY,
  `identifier` varchar(255) DEFAULT NULL,
  `date_received` varchar(10) DEFAULT NULL,
  `received` tinyint(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;