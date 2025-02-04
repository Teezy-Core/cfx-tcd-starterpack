--
-- Table structure for table `tcd_starterpack`
--

CREATE TABLE `tcd_starterpack` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `identifier` varchar(50) NOT NULL,
  `received` tinyint(1) NOT NULL,
  `date_received` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


ALTER TABLE `tcd_starterpack`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `tcd_starterpack`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=14;
COMMIT;