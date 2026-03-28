-- ============================================================
-- Smart Water Billing System - Database Schema
-- Run this in MySQL before deploying the project
-- ============================================================

CREATE DATABASE IF NOT EXISTS water_system;
USE water_system;

-- -------------------------------------------------------
-- USERS TABLE  (registered residents / user accounts)
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    first_name  VARCHAR(50)  NOT NULL,
    last_name   VARCHAR(50)  NOT NULL,
    email       VARCHAR(100) NOT NULL UNIQUE,
    username    VARCHAR(50)  NOT NULL UNIQUE,
    phone       VARCHAR(15)  NOT NULL,
    address     VARCHAR(255) NOT NULL,
    password    VARCHAR(255) NOT NULL,          -- store hashed in production
    meter_no    VARCHAR(30)  NOT NULL UNIQUE,
    role        ENUM('USER','ADMIN') DEFAULT 'USER',
    is_active   TINYINT(1)   DEFAULT 1,
    created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP
);

-- -------------------------------------------------------
-- USAGE / BILLING RECORDS
-- -------------------------------------------------------
CREATE TABLE IF NOT EXISTS usage_records (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    units         INT          NOT NULL DEFAULT 0,
    bill_amount   INT          NOT NULL DEFAULT 0,
    bill_date     DATETIME     DEFAULT CURRENT_TIMESTAMP,
    is_paid       TINYINT(1)   DEFAULT 0
);

-- -------------------------------------------------------
-- SAMPLE DATA  (optional – remove in production)
-- -------------------------------------------------------
INSERT IGNORE INTO users
    (first_name, last_name, email, username, phone, address, password, meter_no, role, is_active)
VALUES
    ('Sai Pranay',  'Reddy',   'saipranay@example.com',  'saipranay', '9876543210', 'Flat 101, Block A, Hyderabad', 'user123', 'MTR1001', 'USER', 1),
    ('Vardhan',     'Kumar',   'vardhan@example.com',    'vardhan',   '9876543211', 'Flat 202, Block B, Hyderabad', 'user123', 'MTR1002', 'USER', 1),
    ('Geeta',       'Sharma',  'geeta@example.com',      'geeta',     '9876543212', 'Flat 303, Block C, Hyderabad', 'user123', 'MTR1003', 'USER', 1),
    ('Vaishnavi',   'Nair',    'vaishnavi@example.com',  'vaishnavi', '9876543213', 'Flat 404, Block D, Hyderabad', 'user123', 'MTR1004', 'USER', 1);

INSERT IGNORE INTO usage_records (customer_name, units, bill_amount, bill_date) VALUES
    ('saipranay', 450, 900,  NOW() - INTERVAL 30 DAY),
    ('saipranay', 380, 760,  NOW() - INTERVAL 60 DAY),
    ('vardhan',   310, 620,  NOW() - INTERVAL 30 DAY),
    ('geeta',     890, 1780, NOW() - INTERVAL 30 DAY),
    ('vaishnavi', 520, 1040, NOW() - INTERVAL 30 DAY);

-- -------------------------------------------------------
-- VERIFY
-- -------------------------------------------------------
SELECT 'users table' AS tbl, COUNT(*) AS rows FROM users
UNION ALL
SELECT 'usage_records',       COUNT(*)            FROM usage_records;
