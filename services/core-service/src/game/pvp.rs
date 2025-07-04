use chrono::NaiveDateTime;
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct PvPSession {
    pub id: i32,
    pub player_a: String,
    pub player_b: String,
    pub start_block: i64,
    pub result: Option<String>,
    pub created_at: NaiveDateTime,
    pub updated_at: NaiveDateTime,
}

// Example usage in PvP logic:
// let session = PvPSession { ... };
// let session_id = session_store.create_session(&session).await?;
// session_store.update_result(session_id, "A_won").await?;
// session_store.rollback_session(session_id).await?; 