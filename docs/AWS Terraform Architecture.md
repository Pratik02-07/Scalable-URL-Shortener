terraform/
├── modules/
│   ├── vpc/         # VPC, 3 Public Subnets, 3 Private Subnets, IGW, NAT Gateways
│   ├── security/    # Security Groups (ALB -> ECS Tasks -> RDS/Redis strict isolation)
│   ├── ecr/         # ECR Repositories with image scanning enabled
│   ├── alb/         # Public ALB, Target Groups (Frontend:3000, Backend:8000), Path Rules
│   ├── ecs/         # Fargate Cluster, Task Definitions, Auto-scaling policies (min 2, max 10)
│   ├── rds/         # RDS PostgreSQL Multi-AZ DB Instance in private subnets
│   └── redis/       # ElastiCache Redis Cluster in private subnets
└── environments/
    ├── dev/         # Free-tier / small instance configurations (db.t4g.micro, cache.t4g.micro)
    └── prod/        # Multi-AZ production topology with Auto Scaling enabled
