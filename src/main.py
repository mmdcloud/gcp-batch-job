import os
import requests
from google.cloud import bigquery

def call_news_api_and_ingest():
    api_key = os.environ.get('NEWS_API_KEY', '14411238a52d4395b1f5a73c0ab7dfaa')
    url = f'https://newsapi.org/v2/top-headlines?country=us&pageSize=20&apiKey={api_key}'
    
    response = requests.get(url)
    response.raise_for_status()
    news_data = response.json()

    if news_data.get('status') != 'ok':
        raise RuntimeError(f"NewsAPI error: {news_data.get('message')}")

    news_articles = news_data.get('articles', [])
    print(f"NewsAPI returned {len(news_articles)} articles.")

    # Filter out removed or empty articles if desired
    rows_to_insert = [
        {
            'title': article.get('title'),
            'description': article.get('description'),
            'url': article.get('url')
        }
        for article in news_articles
        if article.get('title') and article.get('title') != '[Removed]'
    ]

    print(f"Prepared {len(rows_to_insert)} rows for BigQuery ingestion.")

    if not rows_to_insert:
        print("No valid rows to insert.")
        return

    project_id = os.environ['PROJECT_ID']
    client = bigquery.Client(project=project_id)
    table_ref = client.get_table("batchnews.batchnewstable")

    errors = client.insert_rows_json(table_ref, rows_to_insert)
    if errors:
        raise RuntimeError(f'Error inserting rows into BigQuery: {errors}')

    print(f'Successfully ingested {len(rows_to_insert)} rows into BigQuery.')

if __name__ == '__main__':
    call_news_api_and_ingest()