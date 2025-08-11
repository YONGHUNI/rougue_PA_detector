# Rogue Purple Air Sensor Detector & Data Fetcher Using GitHub Actions [![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/YONGHUNI/rougue_PA_detector)


This repository automates the collection and monitoring of Purple Air sensor data using GitHub Actions. It is designed for fully automated operation.

## Overview

- **Automated Data Collection**  
  The `2_retriever` module periodically gathers air quality data from Purple Air sensors via API calls. Its execution is orchestrated by the workflow defined in [`.github/workflows/retriever.yml`](.github/workflows/retriever.yml).

- **Continuous Anomaly Detection & Alerting**  
  The `1_checker` module processes the collected sensor data to detect anomalies (for example, offline sensors) and dispatches alerts (e.g., via Discord). This process is managed by the workflow defined in [`.github/workflows/check.yml`](.github/workflows/check.yml).

- **Security & Configuration**  
  All sensitive information (API keys, database credentials, etc.) is managed through GitHub Actions secrets and provided as environment variables during workflow execution.  
  There is no need to store secrets in the repository or input them manually at runtime.

## How It Works

1. **Scheduling**  
   - The data collection workflow ([`retriever.yml`](.github/workflows/retriever.yml)) is triggered automatically every hour at 30 minutes past, can be run manually via GitHub Actions, and also runs on any push to the main branch that modifies files in `2_retriever/**` or the workflow file itself.
   - The anomaly detection workflow ([`check.yml`](.github/workflows/check.yml)) has its own schedule: it runs on selected hours during weekdays and weekends, can also be manually triggered, and additionally runs when files in `1_checker/**` or the workflow file are pushed to the main branch.

2. **Execution**  
   - In the data collection workflow, the script `2_retriever/main.R` fetches and processes sensor data.
   - In the anomaly detection workflow, `1_checker/main.R` analyzes the sensor data; if anomalies are detected, it checks for a message file and (if present) sends an alert using Discord.

3. **Monitoring**  
   Detailed logs for each workflow run are available on the GitHub Actions dashboard, providing an easy way to monitor and troubleshoot the operations.

## Directory Structure

- `2_retriever/` — Contains the scripts responsible for automated data collection.
- `1_checker/` — Contains the scripts for anomaly detection and alerting.
- `.github/workflows/retriever.yml` — The workflow file for data retrieval.
- `.github/workflows/check.yml` — The workflow file for anomaly detection and alert dispatching.

## Local Development

While the primary mode of operation is automated via GitHub Actions, local testing is supported.  
For local runs, ensure all required environment variables or secret files are properly configured.

---

For detailed documentation on each module, please refer to their respective `README.md` files.
