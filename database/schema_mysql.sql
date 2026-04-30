CREATE TABLE IF NOT EXISTS player_saves (
  player_id VARCHAR(64) PRIMARY KEY,
  save_version INT NOT NULL,
  save_data JSON NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS player_settings (
  player_id VARCHAR(64) PRIMARY KEY,
  settings_version INT NOT NULL,
  settings_data JSON NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS run_records (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  run_id VARCHAR(96) NOT NULL,
  player_id VARCHAR(64) NOT NULL,
  character_id VARCHAR(64) NOT NULL,
  branch_id VARCHAR(64) NOT NULL,
  victory TINYINT(1) NOT NULL DEFAULT 0,
  elapsed_time DECIMAL(10, 2) NOT NULL DEFAULT 0,
  kills INT NOT NULL DEFAULT 0,
  level INT NOT NULL DEFAULT 1,
  shard_gain INT NOT NULL DEFAULT 0,
  record_data JSON NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_run_records_run_id (run_id),
  KEY idx_run_records_player_created (player_id, created_at),
  KEY idx_run_records_character_branch (character_id, branch_id)
);
