# syntax=docker/dockerfile:1
FROM python:3.11-slim

# Install Poetry
RUN pip install poetry

# Set workdir
WORKDIR /app

# Copy pyproject and poetry.lock
COPY poetry.lock pyproject.toml ./

# Copy the rest of the source
COPY src ./src

# Install dependencies
RUN poetry config virtualenvs.create false && poetry install --no-interaction --no-ansi

# Expose port (adjust if needed)
EXPOSE 8001

# Set entrypoint (adjust if your main file is different)
CMD ["python", "-m", "src.main"]
