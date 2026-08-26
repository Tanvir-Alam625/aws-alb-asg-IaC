# Architecture Overview

## Infrastructure diagram
```mermaid
flowchart LR
  Internet["Internet"] --> IGW["IGW"]
  IGW --> Public["Public Subnets"]
  Public --> ALB["ALB (internet-facing)"]
  Public --> Bastion["Bastion EC2 (public)"]
  IGW --> NAT["NAT Gateway"]
  Public -->|routes| PrivateApp["Private Application Subnets"]
  PrivateApp --> ASG["Auto Scaling Group (backend)"]
  ASG --> Backend1["Backend EC2 (Node.js) 1\n/health"]
  ASG --> Backend2["Backend EC2 (Node.js) 2\n/health"]
  ASG --> Backend3["Backend EC2 (Node.js) 3\n/health"]
  PrivateDB["Private DB Subnet"] --> DB["PostgreSQL EC2"]
  ASG --> DB
  Bastion -. SSH .-> Backend1
  Bastion -. SSH .-> Backend2
  Bastion -. SSH .-> Backend3
  ALB -->|forwards traffic| ASG
  classDef public fill:#e6f7ff,stroke:#0366d6;
  classDef private fill:#fff5e6,stroke:#d46a00;
  class Public,ALB,Bastion public;
  class PrivateApp,ASG,Backend1,Backend2,Backend3,PrivateDB,DB private;
```

## SSH topology

```text
Local PC
  |
  +--> Bastion EC2 (public)
           |
           +--> Backend EC2 (private)
           |
           +--> PostgreSQL EC2 (private)
```

## CI/CD flow

```text
GitHub main
  |
  v
GitHub Actions
  |
  +--> test
  +--> build
  +--> package
  +--> deploy
  |
  v
ALB / ASG / Backend instances
```

## Security model

- Public: ALB, Bastion, NAT.
- Private: backend ASG, PostgreSQL EC2.
- Database and backend are never directly exposed to the internet.
- Access to SSH is restricted to `admin_cidr` only.
