import asyncio
import json
import asyncpg
from kafka import KafkaConsumer
from pydantic_settings import BaseSettings, SettingsConfigDict
import os

class Settings(BaseSettings):
    """Loads environment variables for configuration."""
    model_config = SettingsConfigDict(env_file=".env")

    kafka_bootstrap_servers: str = "localhost:9092"
    kafka_topic: str = "player-events"
    database_url: str = "postgresql://postgres:secr3t@localhost:5432/streetcred_db"
    nats_url: str = "nats://localhost:4222"

settings = Settings()
print(f"Connecting to database at: {settings.database_url}")
print("DATABASE_URL:", os.getenv("DATABASE_URL"))


async def get_db_connection():
    """Establishes a connection to the PostgreSQL database."""
    return await asyncpg.connect(settings.database_url)

async def process_message(message, db_pool):
    """
    Parses a Kafka message and updates the database.
    """
    try:
        # Kafka message values are bytes, so we decode to a string
        event_data = json.loads(message.value.decode('utf-8'))
        user_id = event_data.get('user_id')
        new_x = event_data.get('new_x')
        new_y = event_data.get('new_y')

        if not all([user_id, isinstance(new_x, int), isinstance(new_y, int)]):
            print(f"Skipping malformed message: {event_data}")
            return

        print(f"Processing move for user '{user_id}' to ({new_x}, {new_y})")

        # Use an 'UPSERT' command:
        # If the user_id exists, UPDATE their coordinates.
        # If not, INSERT a new row. This is idempotent.
        query = """
            INSERT INTO map_tiles (owner_user_id, x, y, ink_level, updated_at)
            VALUES ($1, $2, $3, 0, NOW())
            ON CONFLICT ON CONSTRAINT map_tiles_x_y_unique DO UPDATE
            SET x = $2, y = $3, updated_at = NOW();
        """
        async with db_pool.acquire() as connection:
            await connection.execute(query, user_id, new_x, new_y)
            print(f"Successfully persisted move for user '{user_id}'.")

    except json.JSONDecodeError:
        print(f"Error decoding JSON from message: {message.value}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

async def consume():
    """
    The main consumer loop. Connects to Kafka and the DB, then processes messages.
    """
    print("Starting Persistence Service...")
    db_pool = await asyncpg.create_pool(dsn=settings.database_url, min_size=1, max_size=5)
    print("Database connection pool created.")

    consumer = KafkaConsumer(
        settings.kafka_topic,
        bootstrap_servers=settings.kafka_bootstrap_servers,
        auto_offset_reset='earliest', # Start reading from the beginning of the topic
        group_id='persistence-group'  # Consumer group ID
    )
    print(f"Kafka consumer subscribed to topic '{settings.kafka_topic}'.")

    try:
        for message in consumer:
            await process_message(message, db_pool)
    finally:
        await db_pool.close()
        print("Database connection pool closed.")


if __name__ == "__main__":
    print("Persistence service started.")