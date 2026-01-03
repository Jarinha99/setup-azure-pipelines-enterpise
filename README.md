# setup-azure-pipelines-enterpise

The goal of this repository is to create a complete CI/CD structure from scratch for an enterprise-level company, aiming for a mature platform with agile deliveries.

Ensuring a good Dev UX, with ease and simplicity in creating new pipelines with parameters available for the team's needs, avoiding any repetitive configuration by the Dev teams.

The plan and much of the documentation are being done with Claude.

The template repositories are in Azure DevOps, as is the pipeline.

The VMs/K8s and other resources are in Azure.

# Features

- [x] - Azure Devops with agents building a pipeline from azure-pipelines.yaml.

- [] - Setup steps for run SonarQube, Unit Tests, Build, and Deploy on Kuberentes on multiple enviroments (DEV/QA/PRD).

- [] - Unique template of pipeline used by some APIs with different technologies and versions, in a simplified and parameterized way.

- [] - Blue/Green Deploy

- [] - Canary Deploy

# Steps

- [x] - Create Azure organization + Subscription + Azure Devops account

- [x] - Build pipeline sample

- [x] - Configure and connect self hosted agents to agent pool and run pipelines on them.

- [] - Create Template and setup an application to use the template.

- [] - Setup build of Java and NodeJS with multiple versions

- [] - Setup unit tests step with sonarqube analysis of coverage and code smells.

- [] - Setup deploy on kubernetes on multiple environments