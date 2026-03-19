-- MySQL dump 10.13  Distrib 8.0.32, for Linux (x86_64)
-- Host: 192.168.10.3    Database: payment_db_old
-- Server version: 8.0.28
-- Dump started: 2026-03-18 23:11:04
-- ⚠️  주의: 이 파일은 마이그레이션 완료 후 삭제 예정이었으나 방치됨

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Table structure for table `Customer_PII`
--

DROP TABLE IF EXISTS `Customer_PII`;
CREATE TABLE `Customer_PII` (
  `id`           INT(11)      NOT NULL AUTO_INCREMENT,
  `name`         VARCHAR(50)  NOT NULL,
  `ssn`          VARCHAR(14)  NOT NULL,
  `card_number`  VARCHAR(19)  NOT NULL,
  `card_expiry`  VARCHAR(7)   NOT NULL,
  `phone`        VARCHAR(15)  NOT NULL,
  `email`        VARCHAR(100) NOT NULL,
  `address`      VARCHAR(200) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Customer_PII`
--

INSERT INTO `Customer_PII` VALUES
(1,'홍길동','801231-1234567','4012-8888-8888-1881','2025-04','010-1111-2222','hong@oldmail.com','서울특별시 종로구 세종대로 1'),
(2,'성춘향','850501-2345678','5100-0000-0000-0412','2025-07','010-2222-3333','sung@oldmail.com','전라북도 남원시 춘향로 99'),
(3,'이몽룡','820317-1456789','4111-2222-3333-4444','2025-01','010-3333-4444','lee@oldmail.com','경기도 광주시 경안로 45'),
(4,'변학도','791004-1567890','5200-0000-0000-0007','2024-11','010-4444-5555','byun@oldmail.com','전라남도 순천시 향동길 12'),
(5,'향단이','900622-2678901','4916-0000-0000-0000','2025-09','010-5555-6666','hyang@oldmail.com','경상남도 창원시 의창구 원이대로 33');

-- 총 89,000 건 중 샘플 5건
-- ... (이하 생략)

--
-- Table structure for table `Admin_Accounts`
--

DROP TABLE IF EXISTS `Admin_Accounts`;
CREATE TABLE `Admin_Accounts` (
  `id`         INT(11)     NOT NULL AUTO_INCREMENT,
  `username`   VARCHAR(50) NOT NULL,
  `password`   VARCHAR(100) NOT NULL COMMENT '평문 저장 — 보안 강화 필요',
  `role`       VARCHAR(20) NOT NULL,
  `last_login` DATETIME,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `Admin_Accounts` VALUES
(1,'db_admin','CardAdmin123!','DBA','2026-03-18 22:47:03'),
(2,'root','RootDB!0917','SUPERUSER','2026-03-17 09:12:44'),
(3,'backup_agent','Ftp!Backup77','BACKUP','2026-03-18 23:10:58');

-- Dump completed on 2026-03-18 23:11:51
