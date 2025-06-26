# FastAPI Application Deployment Solution

This document describes the solution for deploying a FastAPI application to Kubernetes using Terraform and Helm.

## How to Run the Code

### Local Development

To run the FastAPI application locally:

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd kubernetes-platform
   ```

2. Install dependencies:
   ```bash
   cd src/fastapi
   pip install -r requirements.txt
   ```

3. Run the application:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

4. Access the API at http://localhost:8000

### Docker Container

To build and run the Docker container:

1. Build the image:
   ```bash
   cd src/fastapi
   docker build -t fastapi-app:latest .
   ```

2. Run the container:
   ```bash
   docker run -p 8000:8000 \
     -e DB_PASSWORD=secure_password \
     -e API_BASE_URL=http://localhost:8000 \
     -e LOG_LEVEL=info \
     -e MAX_CONNECTIONS=10 \
     fastapi-app:latest
   ```

3. Access the API at http://localhost:8000

## How to Deploy the Application

The application is deployed to Kubernetes using Terraform and Helm.

### Prerequisites

- Terraform (v1.0.0+)
- kubectl configured for your target cluster
- Helm (v3.0.0+)
- Docker (for building and pushing images)

### Deployment Steps

1. Build and push the Docker image to a container registry:
   ```bash
   cd src/fastapi
   docker build -t <registry>/fastapi-app:latest .
   docker push <registry>/fastapi-app:latest
   ```

2. Deploy using Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

This will:

- Create necessary Kubernetes resources (namespace, etc.)
- Deploy the Helm chart with the application

## How to Verify the Application is Running

After deployment, verify the application is running using these methods:

1. Check the deployment status:
   ```bash
   kubectl get deployments -n api
   ```

2. Verify pods are running:
   ```bash
   kubectl get pods -n api
   ```

3. Access the API endpoint:
   ```bash
   # For minikube
   minikube service fastapi -n api

   # For cloud provider with LoadBalancer
   kubectl get svc -n api
   # Note the EXTERNAL-IP and use it to access the API

   # Using port-forwarding
   kubectl port-forward svc/fastapi 8000:80 -n api
   # Then access at http://localhost:8000
   ```

4. Test specific endpoints:
   ```bash
   curl http://<service-url>/
   curl http://<service-url>/items/1
   ```

## Architecture and Design Decisions

### Security Considerations

- Sensitive information (DB_PASSWORD) is stored in Kubernetes secrets
- Non-root user is used in the container
- Resource limits are set to prevent resource exhaustion

### Scalability

- The deployment is configured with multiple replicas (2)
- Readiness and liveness probes are implemented for better resilience
- Can be scaled horizontally using Kubernetes HPA

### Improvements for Production

1. **CI/CD Pipeline**: Implement automated testing and deployment
2. **Monitoring and Logging**: Add Prometheus metrics and centralized logging
3. **Network Policies**: Implement stricter network policies
4. **Secret Management**: Use a more robust solution like HashiCorp Vault
5. **Resource Optimization**: Fine-tune resource requests and limits based on actual usage patterns

## Note

This implementation was created using GitHub Copilot for assistance with code generation and documentation.
