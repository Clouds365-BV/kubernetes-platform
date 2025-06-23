The Challenge

This repository contains a very simple Python FastAPI application. The task is to containerize this application and deploy the resulting image to a Kubernetes cluster using Terraform. Application edpoints should be accessible via curl.
Instructions

    Fork this repository to your personal version control account (GitHub, GitLab, etc.).
    Create all the code related to this task.
    Create a README-SOLUTION.md file in the root of the repository with the following information:
        How to run the code
        How to deploy the application
        How to verify that the application is running
        Any other relevant information

The Requirements

    Containerize application. Use any container registry you want (e.g. DockerHub).
    The values for the environment variable in the Python script can be random but you should think about security and best practices.
    The application must be deployed to a Kubernetes cluster using a Helm chart (use any Kubernetes cluster of your choice: minikube/any cloud provider).
    The application should be exposed and accessible via a curl.
    Terraform must be used to manage the deployment to the Kubernetes cluster. Please follow the best practices.

Good to have

    The Helm chart and Terraform code should be reusable across environments.
    Describe any tradeoffs you have made in your solution and the way you'd like to improve it for the real production environment.

Important

    Feel free to change code if you think it is necessary.
    Feel free to use any LLM but document it in the README-SOLUTION.md file.

Note

    We expect you not to spend more than 4 hours for this task.
