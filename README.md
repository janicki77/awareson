# Awareson

# Flask Web App on Azure with Terraform & GitHub Actions

## Stack

- **Flask** (Python web framework)
- **Docker** (for containerization)
- **Azure App Service** (hosting)
- **Azure Database for MySQL**
- **Terraform** (infrastructure as code)
- **GitHub Actions** (CI/CD automation)

## App link
https://myapp-service-awareson.azurewebsites.net/

## How it works

There are two pipelines, one for infra and one for the app. If the users table doesn't exist, you can initialize it via a special endpoint:
GET /initdb (https://myapp-service-awareson.azurewebsites.net/initdb)

App adds a record in a MySQL database. It is internally using deleations over VNET. Container image is built with docker and pushed onto ACR.
Deployment pipeline has a simple connectivity test embedded.