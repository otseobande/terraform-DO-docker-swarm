# Terraform Digital Ocean Docker Swarm Setup

This project setups docker swarm nodes on Digital ocean and deploys a basic nginx server on the swarm.

## Setup

- [Install terraform](https://learn.hashicorp.com/terraform/getting-started/install.html)

- Copy `terraform.tfvars.example` to `terraform.tfvars`

- Initatiate configurations

```
terraform init
```

- Apply configurations

```
terraform apply -var-file=terraform.tfvars --auto-approve
```
