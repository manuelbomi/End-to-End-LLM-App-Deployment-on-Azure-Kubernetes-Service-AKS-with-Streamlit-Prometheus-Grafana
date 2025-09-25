# End-to-End LLM App Deployment on Azure Kubernetes Service (AKS) with Streamlit, Prometheus & Grafana

#### This repository documents the enterprise-grade deployment of a Large Language Model (LLM) Streamlit application with Prometheus (for metrics) and Grafana (for visualization) on Azure Kubernetes Service (AKS). 

#### It emphasizes production-ready practices, including TLS with Let's Encrypt, Ingress routing, and Helm-based installations.

#### The deployment uses Docker Hub images, Azure CLI, Kubernetes manifests (.yaml files), and a custom domain registered via Namecheap

---

## Features  

* LLM Streamlit App (pulled from Docker Hub: emmanueloyekanlu/llm_enterprise:latest)

* Prometheus monitoring with custom scrape configs

* Grafana dashboards with persistent storage

* TLS certificates via Cert-Manager and Let's Encrypt

* NGINX Ingress Controller for routing and domain mapping

* Azure AKS for scalable container orchestration

* Enterprise-ready workflow: staging → production certificates, DNS integration, and monitoring

--- 

## Repository Structure  

Only Kubernetes manifests are included in this repository:

<img width="375" height="290" alt="Image" src="https://github.com/user-attachments/assets/a17bb7f6-70d5-4b48-9568-9d559da15524" />

Each manifest is modular and can be applied in sequence.

---


## Prerequisites  

    1. Azure CLI installed
    
        ◦ az login      
        
    2. kubectl and Helm installed
        ◦ kubectl version --client
        
        ◦ helm version

    3. An AKS Cluster    
      ◦ An AKS Cluster  (see how to create an AKS cluster here: https://github.com/manuelbomi/Azure-Kubernetes-Services-AKS-Enterprise-Cluster-Provisioning-/tree/main   )
      
      ◦ az aks get-credentials --resource-group <your-resource-group> --name <your-aks-cluster>

    4. Namecheap Domain pointing to your AKS ingress public IP (example: app.emmanueloyekanluprojects.com)

      ◦ Update A records in Namecheap to match the AKS LoadBalancer IP

    5. Docker Image available on Docker Hub:

      ◦ emmanueloyekanlu/llm_enterprise:latest

---

### Step-by-Step Deployment (Option 1)

#### 1. Install NGINX Ingress Controller

---
```ruby
kubectl create namespace ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
--namespace ingress-nginx \
--set controller.service.type=LoadBalancer

```
---

#### Check the external IP:

```ruby
kubectl get svc -n ingress-nginx
```

#### Update your Namecheap domain A records with this IP.

#### 2. Install Cert-Manager
---
```ruby
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm upgrade --install cert-manager jetstack/cert-manager \
--namespace cert-manager \
--create-namespace \
--set crds.enabled=true
```
---

#### 3. Apply Kubernetes Resources

#### Apply all manifests in order:
---
```ruby
kubectl apply -f 00-namespace.yaml
kubectl apply -f 01-pvcs.yaml
kubectl apply -f 02-secrets.yaml
kubectl apply -f 03-configmap.yaml
kubectl apply -f 04-deployments.yaml
kubectl apply -f 05-services.yaml
kubectl apply -f 06-ingress.yaml
```
---

#### Start with staging certificates:

```ruby
kubectl apply -f clusterissuer-staging.yaml
```

---

#### 4. Verify Certificates

##### Check if certs were issued:
---
```ruby
kubectl get certificates -n llm-system
kubectl describe certificate streamlit-tls -n llm-system
```
---

##### If Ready: True, you’re good.

##### Switch to production:
---
```ruby
kubectl apply -f clusterissuer-prod.yaml
kubectl apply -f 06-ingress.yaml
```
---

#### 5. Access Your Apps
* Streamlit: https://app.emmanueloyekanluprojects.com

* Prometheus: https://prometheus.emmanueloyekanluprojects.com

* Grafana: https://grafana.emmanueloyekanluprojects.com

---

### Step-by-Step Deployment (Option 2)
##### Alternatively, instead of using all the steps in option 1 above, you can choose to put all the .yaml manifests in a zip file, say *<ins>k8s-deployment-bundle.zip</ins>*

#### 1. Open Cloud Shell
    • Go to: https://shell.azure.com/
    
Or: Click the Cloud Shell icon from the Azure Portal
Choose Bash, not PowerShell.

#### 2. Upload Your Zip File

* Use the "Upload" button to upload k8s-deployment-bundle.zip
  
It will be saved in your Cloud Shell's $HOME directory or mounted /home/<you>/clouddrive.

#### 3. Unzip & Prepare
* unzip k8s-deployment-bundle.zip
  
* cd k8s-deployment-bundle

* create a deploy.sh file (nano deploy.sh)
* Copy the content of the deploy.sh in the repository and paste it into your deploy.sh file (ctrl + shift + v)
* Save it (ctrl + x)
* Give it permission (chmod +x deploy.sh)

##### 4. Connect to Your AKS Cluster

* az login
  
* az aks get-credentials --resource-group <your-resource-group> --name <your-aks-cluster-name>

* az aks get-credentials --resource-group llm_enterprise-rg --name llm-enterprise-2


##### 5. Run Your Deployment Script

* ./deploy.sh

##### The ./deploy.sh step will use the ./deploy.sh script to:
    • Install cert-manager
    • Apply the staging issuer
    • Deploy all components (Streamlit, Prometheus, Grafana, Ingress, Secrets, PVCs)

---
## Troubleshooting
#### 1. DNS Issues

* Ensure your domain points to the AKS ingress IP:
---
```ruby

kubectl get svc ingress-nginx-controller -n ingress-nginx -o wide
nslookup app.emmanueloyekanluprojects.com
```
---

#### 2. Certificates Not Issued

* Check CertificateRequests:
---
```ruby

kubectl get certificaterequests -n llm-system
kubectl describe certificaterequest <name>
```
---

* Ensure port 80 is open in your Azure NSG:

---
```ruby

az network nsg rule create \
--resource-group <your-resource-group> \
--nsg-name <your-nsg-name> \
--name Allow-HTTP \
--priority 100 \
--direction Inbound \
--access Allow \
--protocol Tcp \
--destination-port-ranges 80 \
--description "Allow HTTP for ACME challenge"
```
---

#### 3. Debugging Pods
---
```ruby
kubectl get pods -n llm-system
kubectl logs <pod-name> -n llm-system
```
---

#### 4. Test HTTP Challenge
---
```ruby
curl -v http://app.emmanueloyekanluprojects.com/.well-known/acme-challenge/test
```
---

#### Monitoring Stack  📊 

* Prometheus scrapes metrics from the Streamlit app on port 9001.

* Grafana connects to Prometheus and provides dashboards for app monitoring.

* Both Prometheus and Grafana use PersistentVolumeClaims (PVCs) for durable storage.

---

#### Scaling Up  🏗️ 

* Increase replicas for high availability (replicas: 3 in deployments).

* Add HPA (Horizontal Pod Autoscaler) for auto-scaling workloads.

* Integrate Azure Monitor for extended observability.

* Expand to multi-environment setup: dev, staging, prod.

---

#### Conclusion  ✅ 

* This repository demonstrates how to deploy an LLM-powered Streamlit app with monitoring on Azure Kubernetes Service (AKS) using production-grade practices:

* Docker Hub for images

* Helm for package management

* Cert-Manager for TLS automation

* Ingress + Namecheap DNS for routing

* Azure CLI for cluster operations

* With these manifests, anyone can reproduce this enterprise-ready deployment from scratch.

---

Thank you for reading

---

### **AUTHOR'S BACKGROUND**
### Author's Name:  Emmanuel Oyekanlu
```
Skillset:   I have experience spanning several years in data science, developing scalable enterprise data pipelines,
enterprise solution architecture, architecting enterprise systems data and AI applications,
software and AI solution design and deployments, data engineering, high performance computing (GPU, CUDA), machine learning,
NLP, Agentic-AI and LLM applications as well as deploying scalable solutions (apps) on-prem and in the cloud.

I can be reached through: manuelbomi@yahoo.com

Websites (professional):  http://emmanueloyekanlu.com/
Websites (application):  https://app.emmanueloyekanluprojects.com/
Publications:  https://scholar.google.com/citations?user=S-jTMfkAAAAJ&hl=en
LinkedIn:  https://www.linkedin.com/in/emmanuel-oyekanlu-6ba98616
Github:  https://github.com/manuelbomi

```
[![Icons](https://skillicons.dev/icons?i=aws,azure,gcp,scala,mongodb,redis,cassandra,kafka,anaconda,matlab,nodejs,django,py,c,anaconda,git,github,mysql,docker,kubernetes&theme=dark)](https://skillicons.dev)



  [![HitCount](https://hits.dwyl.com/manuelbomi/https://githubcom/manuelbomi/End-to-End-LLM-App-Deployment-on-Azure-Kubernetes-Service-AKS-with-Str.svg?style=flat-square&show=unique)](http://hits.dwyl.com/manuelbomi/https://githubcom/manuelbomi/End-to-End-LLM-App-Deployment-on-Azure-Kubernetes-Service-AKS-with-Str)


https://hits.dwyl.com/
