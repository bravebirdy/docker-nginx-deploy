# Use Alpine Python image if:
#  - You need a smaller image
#  - You require higher security
#  - You are willing to handle potential compilation issues
# Use Slim if:
#  - You need a more stable environment
#  - You don't want to deal with compilation issues
#  - Image size is not a primary concern
# FROM python:3.13-alpine
FROM python:3.13-slim

# Set the working directory
WORKDIR /app

# Copy only requirements first to leverage Docker layer caching
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY ./app ./app

# Expose the application port (this is just for documentation, not mandatory)
EXPOSE 8000

# Use environment variables for flexibility
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
