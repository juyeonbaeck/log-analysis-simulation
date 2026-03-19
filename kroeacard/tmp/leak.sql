-- MySQL dump 10.13  Distrib 8.0.32, for Linux (x86_64)
-- Host: 192.168.10.5    Database: payment_db
-- Server version: 8.0.32
-- Dump started: 2026-03-19 09:28:11

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Table structure for table `Customer_PII`
--

DROP TABLE IF EXISTS `Customer_PII`;
CREATE TABLE `Customer_PII` (
  `id`            INT(11)      NOT NULL AUTO_INCREMENT,
  `name`          VARCHAR(50)  NOT NULL,
  `ssn`           VARCHAR(14)  NOT NULL COMMENT '주민등록번호',
  `card_number`   VARCHAR(19)  NOT NULL,
  `card_expiry`   VARCHAR(7)   NOT NULL,
  `card_cvv`      VARCHAR(4)   NOT NULL,
  `bank_account`  VARCHAR(20)  NOT NULL,
  `phone`         VARCHAR(15)  NOT NULL,
  `email`         VARCHAR(100) NOT NULL,
  `address`       VARCHAR(200) NOT NULL,
  `credit_score`  INT(4)       NOT NULL,
  `created_at`    DATETIME     NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `Customer_PII`
--

INSERT INTO `Customer_PII` VALUES
(1,'김민준','900112-1234567','4512-3456-7890-1234','2027-08','391','12345678901234','010-1234-5678','minjun.kim@email.com','서울특별시 강남구 테헤란로 123','782','2024-03-01 10:22:11'),
(2,'이서연','950623-2345678','5234-5678-9012-3456','2026-11','482','23456789012345','010-2345-6789','seoyeon.lee@email.com','경기도 성남시 분당구 판교로 456','651','2024-03-02 11:35:42'),
(3,'박지훈','880304-1456789','4111-1111-1111-1111','2028-03','737','34567890123456','010-3456-7890','jihoon.park@email.com','서울특별시 마포구 홍익로 78','829','2024-03-03 09:14:05'),
(4,'최수아','010715-4567890','5500-0000-0000-0004','2027-06','564','45678901234567','010-4567-8901','sua.choi@email.com','인천광역시 연수구 송도대로 234','710','2024-03-04 14:52:33'),
(5,'정도현','870919-1678901','4916-1234-5678-9012','2026-09','129','56789012345678','010-5678-9012','dohyun.jung@email.com','부산광역시 해운대구 센텀로 89','593','2024-03-05 16:03:17'),
(6,'강하은','920401-2789012','3782-8224-6310-0005','2028-12','847','67890123456789','010-6789-0123','haeun.kang@email.com','서울특별시 송파구 올림픽로 300','744','2024-03-06 08:41:55'),
(7,'윤재원','840726-1890123','6011-0000-0000-0004','2027-02','263','78901234567890','010-7890-1234','jaewon.yun@email.com','대전광역시 유성구 대학로 99','688','2024-03-07 13:27:44'),
(8,'임나영','991130-2901234','5105-1051-0510-5100','2026-07','915','89012345678901','010-8901-2345','nayoung.lim@email.com','경기도 수원시 영통구 광교로 145','615','2024-03-08 10:09:22'),
(9,'한승민','910815-1012345','4222-2222-2222-2222','2028-01','478','90123456789012','010-9012-3456','seungmin.han@email.com','서울특별시 관악구 봉천로 55','771','2024-03-09 15:44:08'),
(10,'오지은','030228-4123456','5425-2334-3010-9903','2027-10','632','01234567890123','010-0123-4567','jieun.oh@email.com','광주광역시 서구 상무대로 700','549','2024-03-10 12:18:31');

-- 총 147,000 건 중 샘플 10건 출력
-- ... (이하 생략)

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
-- Dump completed on 2026-03-19 09:28:43
