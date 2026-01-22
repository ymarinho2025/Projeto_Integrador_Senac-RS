CREATE DATABASE IF NOT EXISTS marinhos_network
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;

USE marinhos_network;
# --------------------------------------------------------------------
CREATE TABLE users (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  birth_date DATE NULL,
  country VARCHAR(80) NULL,
  state VARCHAR(80) NULL,
  status ENUM('ACTIVE','BLOCKED','PENDING') NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_users_email (email)
) ENGINE=InnoDB;
# --------------------------------------------------------------------
CREATE TABLE roles (
  id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(30) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_roles_name (name)
) ENGINE=InnoDB;
# --------------------------------------------------------------------
CREATE TABLE user_roles (
  user_id BIGINT UNSIGNED NOT NULL,
  role_id SMALLINT UNSIGNED NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, role_id),
  CONSTRAINT fk_user_roles_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_user_roles_role
    FOREIGN KEY (role_id) REFERENCES roles(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
# --------------------------------------------------------------------
CREATE TABLE posts (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id BIGINT UNSIGNED NOT NULL,
  content_text TEXT NULL,
  visibility ENUM('PUBLIC','CONNECTIONS','PRIVATE') NOT NULL DEFAULT 'PUBLIC',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY idx_posts_user_created (user_id, created_at),
  CONSTRAINT fk_posts_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
# --------------------------------------------------------------------
CREATE TABLE media_files (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  post_id BIGINT UNSIGNED NOT NULL,
  media_type ENUM('IMAGE','VIDEO','AUDIO') NOT NULL,
  url VARCHAR(500) NOT NULL,
  mime_type VARCHAR(100) NULL,
  size_bytes BIGINT UNSIGNED NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_media_post (post_id),
  CONSTRAINT fk_media_post
    FOREIGN KEY (post_id) REFERENCES posts(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
# --------------------------------------------------------------------
CREATE TABLE connections (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  requester_id BIGINT UNSIGNED NOT NULL,
  addressee_id BIGINT UNSIGNED NOT NULL,
  status ENUM('PENDING','ACCEPTED','BLOCKED') NOT NULL DEFAULT 'PENDING',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_connections_pair (requester_id, addressee_id),
  KEY idx_connections_requester (requester_id, status),
  KEY idx_connections_addressee (addressee_id, status),
  CONSTRAINT fk_connections_requester
    FOREIGN KEY (requester_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_connections_addressee
    FOREIGN KEY (addressee_id) REFERENCES users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
# --------------------------------------------------------------------
CREATE TABLE moderation_logs (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  actor_user_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(60) NOT NULL,
  target_type VARCHAR(40) NOT NULL,
  target_id BIGINT UNSIGNED NOT NULL,
  reason VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_modlogs_actor_date (actor_user_id, created_at),
  CONSTRAINT fk_modlogs_actor
    FOREIGN KEY (actor_user_id) REFERENCES users(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
# --------------------------------------------------------------------
CREATE TABLE daily_metrics (
  report_date DATE NOT NULL,
  new_users INT NOT NULL,
  new_posts INT NOT NULL,
  new_media INT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (report_date)
) ENGINE=InnoDB;
# --------------------------------------------------------------------
DELIMITER $$

CREATE PROCEDURE sp_generate_daily_metrics(IN p_date DATE)
BEGIN
  INSERT INTO daily_metrics (report_date, new_users, new_posts, new_media)
  SELECT
    p_date,
    (SELECT COUNT(*) FROM users WHERE DATE(created_at) = p_date),
    (SELECT COUNT(*) FROM posts WHERE DATE(created_at) = p_date),
    (SELECT COUNT(*) FROM media_files WHERE DATE(created_at) = p_date)
  ON DUPLICATE KEY UPDATE
    new_users = VALUES(new_users),
    new_posts = VALUES(new_posts),
    new_media = VALUES(new_media);
END$$

DELIMITER ;