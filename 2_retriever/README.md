# 2_retriever: Automated Data Collection via GitHub Actions

This module is designed to periodically collect Purple Air sensor data, operating as an automated scheduled task using GitHub Actions — not as a traditional CI/CD pipeline, but for the automation.

## How It Works with GitHub Actions

- **Scheduled Automation**  
  The workflow is defined in `.github/workflows/retriever.yml`. It is triggered automatically at specified intervals (as-is: every 1 hour) using a cron schedule in GitHub Actions.

- **Secure Configuration**  
  Sensitive information (API keys, database credentials, etc.) is securely injected as environment variables via GitHub Actions secrets. The script accesses them using `Sys.getenv()`.

- **Data Retrieval and Processing**  
  The script sends requests to the Purple Air API, collects sensor history, and processes the result into a structured `data.table`. It includes built-in rate limiting (`Sys.sleep()`) to comply with API restrictions.

- **Monitoring and Logging**  
  Each run’s output and logs are available in the GitHub Actions dashboard, providing clear traceability and operational visibility.

## Workflow Steps (via `retriever.yml`)

1. **Checkout**: Retrieves the repository code.
2. **Environment Setup**: Installs R and required packages.
3. **Secrets Injection**: Loads environment variables from repository secrets.
4. **Execution**: Runs `Rscript --verbose ./2_retriever/main.R` automatically on schedule.

## Usage

- **No manual trigger needed**: All operations are automated through the GitHub Actions schedule.
- **To change schedule or environment**: Edit `.github/workflows/retriever.yml` in your repository.

## Local Testing

- While possible, local execution is secondary to automated operation. For local runs, ensure all required secrets are available as environment variables or local files.

---

This module is intended for automated, scheduled data collection and is managed entirely through GitHub Actions for reliability and security.