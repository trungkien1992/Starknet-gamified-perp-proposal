use sqlx::{PgPool, Row};
use crate::game::pvp::PvPSession;
use anyhow::Result;
use std::collections::HashMap;

pub struct SessionStore {
    pool: PgPool,
}

impl SessionStore {
    pub fn new(pool: PgPool) -> Self {
        Self { pool }
    }

    pub async fn create_session(&self, session: &PvPSession) -> Result<i32, sqlx::Error> {
        let query = sqlx::query(
            "INSERT INTO pvp_sessions (player_a, player_b, start_block) VALUES ($1, $2, $3) RETURNING id"
        )
        .bind(&session.player_a)
        .bind(&session.player_b)
        .bind(session.start_block as i64)  // Convert u64 to i64
        .fetch_one(&self.pool)
        .await?;
        
        let id: i32 = query.get("id");
        Ok(id)
    }

    pub async fn update_result(&self, id: i32, result: &str) -> Result<(), sqlx::Error> {
        let query = sqlx::query(
            "UPDATE pvp_sessions SET result = $1, updated_at = NOW() WHERE id = $2"
        )
        .bind(result)
        .bind(id)
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub async fn rollback_session(&self, id: i32) -> Result<(), sqlx::Error> {
        self.update_result(id, "rollback").await
    }

    pub async fn save_session(&self, session_id: &str, data: &HashMap<String, String>) -> Result<()> {
        let data_json = serde_json::to_value(data)?;
        let query = sqlx::query(
            r#"
            INSERT INTO sessions (id, data, created_at, updated_at)
            VALUES ($1, $2, to_timestamp($3), to_timestamp($4))
            ON CONFLICT (id) DO UPDATE SET
                data = EXCLUDED.data,
                updated_at = EXCLUDED.updated_at
            "#
        )
        .bind(session_id)
        .bind(&data_json)
        .bind(std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs() as i64)
        .bind(std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH)?.as_secs() as i64)
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }

    pub async fn load_session(&self, session_id: &str) -> Result<Option<HashMap<String, String>>> {
        let query = sqlx::query(
            r#"
            SELECT data FROM sessions WHERE id = $1
            "#
        )
        .bind(session_id);
        
        let row = query.fetch_optional(&self.pool).await?;
        
        if let Some(row) = row {
            let data_json: serde_json::Value = row.get("data");
            let data: HashMap<String, String> = serde_json::from_value(data_json)?;
            Ok(Some(data))
        } else {
            Ok(None)
        }
    }
} 