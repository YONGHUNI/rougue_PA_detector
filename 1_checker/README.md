# 1_checker: Automated Anomaly Detection & Alerts via GitHub Actions

This module continuously monitors Purple Air sensor data for anomalies (e.g., offline sensors) and dispatches alerts, all triggered and managed by GitHub Actions scheduling.

## How It Works with GitHub Actions

- **Scheduled Checks**  
  Anomaly detection runs are scheduled using GitHub Actions, via `.github/workflows/check.yml`. Runs occur at regular intervals.

- **Secure Secrets Management**  
  All sensitive information (API keys, sensor indices, participant info) is injected as environment variables from GitHub repository secrets and accessed via `Sys.getenv()` in the script.

- **Anomaly Detection & Alerting**  
  The script processes the latest sensor data, checks for missing or abnormal values, and sends alerts (e.g., to Discord) if issues are found.

- **Compliance with Rate Limits**  
  `Sys.sleep()` is used to pace API calls, ensuring the service is not overloaded and to comply with external API restrictions.

- **Logging & Monitoring**  
  All workflow executions and alert logs are available in the GitHub Actions dashboard for auditing and troubleshooting.

## Workflow Steps (via `retriever.yml` or similar)

1. **Checkout**: Retrieves the code.
2. **Environment Setup**: Installs R and dependencies.
3. **Secrets Injection**: Loads environment variables from repository secrets.
4. **Execution**: Runs `Rscript --verbose ./1_checker/main.R` automatically on schedule.

## Usage

- **Fully automated**: No manual intervention is required; anomaly checks and alerting are handled automatically by the workflow scheduler.
- **To modify schedule or settings**: Edit the relevant workflow YAML (e.g., `check.yml`) in `.github/workflows/`.

## Local Testing

- Local runs are supported for development/debugging. Ensure all required secrets are set as environment variables or available as local files.

---

This module is designed for hands-off, automated anomaly detection and alerting, powered by scheduled GitHub Actions workflows.