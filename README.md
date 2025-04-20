# News API to BigQuery Cloud Run Job

A Google Cloud Run Job that periodically fetches news articles from the News API and stores the data in BigQuery for analysis and archiving.

## Overview

This project implements an automated data pipeline that:

1. Runs as a scheduled Cloud Run job
2. Fetches the latest news articles from the News API
3. Transforms the data into a suitable format
4. Loads the articles into a BigQuery table
5. Provides logging and error handling

## Architecture

![Architecture Diagram](https://storage.googleapis.com/your-bucket/news-api-architecture.png)

- **Cloud Run Job**: Serverless container that runs the data extraction process
- **News API**: External REST API providing news articles from various sources
- **BigQuery**: Data warehouse for storing and analyzing the news data
- **Cloud Scheduler**: Triggers the Cloud Run job on a defined schedule
- **Secret Manager**: Securely stores API keys and other credentials

## Prerequisites

- Google Cloud Platform account with billing enabled
- News API key ([get one here](https://newsapi.org/register))
- The following APIs enabled:
  - Cloud Run API
  - BigQuery API
  - Secret Manager API
  - Cloud Scheduler API

## Setup

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/news-api-to-bigquery.git
cd news-api-to-bigquery
```

### 2. Set up your environment variables

Create a `.env` file with the following variables:

```
PROJECT_ID=your-gcp-project-id
NEWS_API_KEY=your-news-api-key
BIGQUERY_DATASET=news_data
BIGQUERY_TABLE=articles
```

### 3. Store your News API key in Secret Manager

```bash
gcloud secrets create news-api-key --data-file=<(echo -n "your-news-api-key")
```

### 4. Create BigQuery dataset and table

```bash
# Create dataset
bq mk --dataset ${PROJECT_ID}:news_data

# Create table with schema
bq mk --table \
    --schema source:STRING,author:STRING,title:STRING,description:STRING,url:STRING,urlToImage:STRING,publishedAt:TIMESTAMP,content:STRING \
    news_data.articles
```

### 5. Build and deploy the Cloud Run job

```bash
# Build using Cloud Build
gcloud builds submit --tag gcr.io/${PROJECT_ID}/news-api-job

# Deploy Cloud Run job
gcloud run jobs create news-api-job \
    --image gcr.io/${PROJECT_ID}/news-api-job \
    --memory 512Mi \
    --timeout 10m \
    --set-secrets NEWS_API_KEY=news-api-key:latest \
    --region us-central1
```

### 6. Set up Cloud Scheduler to run the job

```bash
# Create a scheduler job to run every hour
gcloud scheduler jobs create http news-api-scheduler \
    --schedule="0 * * * *" \
    --uri="https://us-central1-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${PROJECT_ID}/jobs/news-api-job:run" \
    --http-method=POST \
    --oauth-service-account-email=${PROJECT_ID}@appspot.gserviceaccount.com
```

## Configuration Options

The application can be configured through environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `QUERY` | News API search query | "technology" |
| `LANGUAGE` | Language for news articles | "en" |
| `DAYS_BACK` | Number of days to look back | 1 |
| `ARTICLE_LIMIT` | Maximum number of articles to fetch | 100 |
| `BIGQUERY_DATASET` | BigQuery dataset name | "news_data" |
| `BIGQUERY_TABLE` | BigQuery table name | "articles" |

## Code Structure

```
├── Dockerfile           # Container configuration
├── main.py              # Entry point for the application
├── requirements.txt     # Python dependencies
├── src/
│   ├── news_api.py      # News API client
│   ├── bigquery.py      # BigQuery interaction
│   └── data_transform.py # Data transformation logic
├── tests/               # Unit and integration tests
└── terraform/           # IaC for deployment
```

## How it Works

1. The Cloud Scheduler triggers the Cloud Run job at the specified interval
2. The job fetches the News API key from Secret Manager
3. It queries the News API for recent articles matching the configured parameters
4. The data is transformed into the BigQuery schema format
5. The articles are inserted into the BigQuery table
6. Logs are written to Cloud Logging

## Development

### Local Testing

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export NEWS_API_KEY=your-api-key
export PROJECT_ID=your-project-id

# Run locally
python main.py
```

### Running Tests

```bash
pytest
```

## Deployment with Terraform

The `terraform` directory contains Infrastructure as Code to deploy all components:

```bash
cd terraform
terraform init
terraform apply
```

## Monitoring and Logging

- View job execution history in Cloud Run console
- Monitor BigQuery data in the BigQuery console
- View logs in Cloud Logging with the filter:
  ```
  resource.type="cloud_run_job" AND resource.labels.job_name="news-api-job"
  ```

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -am 'Add new feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [News API](https://newsapi.org/) for providing the news data
- Google Cloud Platform documentation
