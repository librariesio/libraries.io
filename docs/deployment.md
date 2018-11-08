# Deploying Libraries.io To Production

The libraries.io project uses Capistrano for deploying code changes. The current production environment is on Google Cloud Platform using Google Compute Engine instances.

## Prerequisite

### Google Cloud

In order to be able to deploy to the Google Cloud instances you will need to have them provisioned and configured. For that you can refer to the Ansible repository found at [librariesio/infrastructure](https://github.com/librariesio/infrastructure).

You will also require a user account that has access to the Google Cloud project where the instances are deployed. That user must have SSH permissions to the provisioned instances. In addition to a user account, you will need a service account JSON document located in the project root directory on your local machine (`librariesio/.google_creds.json`).

### Application Settings

The application loads a number of settings from the `.env` file in the shared directory. To populate this file without having to store it in the repository Capistrano will copy the values from the one on your local machine. This means that you will need to have your `.env` file populated with all of the settings necessary for the production environment.

In addition to the `.env` file Capistrano will also copy the `config/secrets.yml` file to production during deployment.

## Deploying

Once the instances are provisioned and you have the necessary permissions and credentials from Google Cloud, as well as the `.env` and `config/secrets.yml` files, you can deploy the code for Libraries.

If this is the first time deploying to one or more instances then you will need to start by running the command `cap production linked_files:upload`. Once that has been run then you can do `cap production deploy`, at which point all of the instances should be running the latest version of the code.

The list of instances to deploy to is created automatically based on a query to the Google Cloud API. The differentiation between app servers, sidekiq workers, and the cron server is based on labels applied to the instances in GCP. The labelling is as follows:

- App server:
  - environment=production
  - role=web
  - type=app
  - project=libraries
- Sidekiq server:
  - environment=production
  - role=worker
  - type=app
  - project=libraries
- Cron server:
  - environment=production
  - role=worker
  - type=app
  - project=libraries
  - cron=yes
