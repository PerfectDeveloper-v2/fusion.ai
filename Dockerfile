# 1. Use an official, lightweight Python runtime as a parent image
FROM python:3.11-slim

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Prevent Python from writing .pyc files to disk and buffer stdout/stderr
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 4. Copy the requirements file into the container first (takes advantage of Docker caching)
COPY requirements.txt .

# 5. Install the Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# 6. Copy the rest of your local application code into the container
COPY . .

# 7. Expose the port so the hosting platform can route traffic to it
# (Render reads $PORT dynamically, Hugging Face uses 7860, standard is 8000)
EXPOSE 8000

# 8. Command to run the application using Uvicorn
CMD ["uvicorn", "fusionai:app", "--host", "0.0.0.0", "--port", "8000"]
