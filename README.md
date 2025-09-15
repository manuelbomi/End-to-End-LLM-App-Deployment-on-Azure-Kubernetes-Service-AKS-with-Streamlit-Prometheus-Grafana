# End-to-End LLM App Deployment on Azure Kubernetes Service (AKS) with Streamlit, Prometheus & Grafana

#### This repository documents the enterprise-grade deployment of a Large Language Model (LLM) Streamlit application with Prometheus (for metrics) and Grafana (for visualization) on Azure Kubernetes Service (AKS). 

#### It emphasizes production-ready practices, including TLS with Let's Encrypt, Ingress routing, and Helm-based installations.

#### The deployment uses Docker Hub images, Azure CLI, Kubernetes manifests (.yaml files), and a custom domain registered via Namecheap

---

## Features  🌟

* LLM Streamlit App (pulled from Docker Hub: emmanueloyekanlu/llm_enterprise:latest)

* Prometheus monitoring with custom scrape configs

* Grafana dashboards with persistent storage

* TLS certificates via Cert-Manager and Let's Encrypt

* NGINX Ingress Controller for routing and domain mapping

* Azure AKS for scalable container orchestration

* Enterprise-ready workflow: staging → production certificates, DNS integration, and monitoring

--- 

## Repository Structure  📂

Only Kubernetes manifests are included in this repository:

<img width="375" height="290" alt="Image" src="https://github.com/user-attachments/assets/a17bb7f6-70d5-4b48-9568-9d559da15524" />

Each manifest is modular and can be applied in sequence.

---

Prerequisites  🚀 

1. Azure CLI installed
     ◦ az login

2. kubectl and Helm installed
     ◦ kubectl version --client
     ◦ helm version

