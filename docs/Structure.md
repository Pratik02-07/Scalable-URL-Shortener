Scalable URL Shortener/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── shorten.py         # POST /api/v1/shorten
│   │   │   ├── redirect.py        # GET /{short_code}
│   │   │   ├── stats.py           # GET /api/v1/stats/{short_code}
│   │   │   └── health.py          # GET /health, GET /ready
│   │   ├── core/
│   │   │   ├── config.py          # pydantic-settings environment config
│   │   │   └── security.py        # CORS, validation, rate limiting helpers
│   │   ├── db/
│   │   │   ├── session.py         # SQLAlchemy engine & async/sync session
│   │   │   └── base.py            # Base model class
│   │   ├── models/
│   │   │   └── url.py             # SQLAlchemy URL & click stats models
│   │   ├── schemas/
│   │   │   └── url.py             # Pydantic request/response schemas
│   │   ├── services/
│   │   │   ├── url_service.py     # Base62 generation, DB queries
│   │   │   └── cache_service.py   # Redis get/set/invalidate with TTL
│   │   └── main.py                # FastAPI app initialization & middleware
│   ├── tests/
│   │   ├── test_shorten.py        # Pytest API unit/integration tests
│   │   ├── test_redirect.py
│   │   ├── test_cache.py
│   │   └── conftest.py            # Test fixtures (sqlite/mock redis)
│   ├── Dockerfile
│   ├── requirements.txt
│   └── pytest.ini
├── frontend/
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.tsx           # Home page (URL shortener input + quick copy)
│   │   │   ├── dashboard/page.tsx # Analytics dashboard (links, click counts, graph)
│   │   │   └── layout.tsx
│   │   ├── components/            # UI components (Navbar, ShortenForm, StatsCard)
│   │   └── lib/                   # API client fetchers
│   ├── Dockerfile
│   ├── package.json
│   └── next.config.js
├── terraform/                     # Modular IaC for AWS
│   ├── modules/
│   │   ├── vpc/                   # 3 Public + 3 Private Subnets across AZs
│   │   ├── alb/                   # ALB & Target Groups
│   │   ├── ecs/                   # Cluster, Fargate Services, Task Definitions
│   │   ├── rds/                   # PostgreSQL Multi-AZ
│   │   ├── redis/                 # ElastiCache Redis Subnet Group & Cluster
│   │   └── ecr/                   # ECR repositories for backend & frontend
│   └── environments/
│       ├── dev/
│       └── prod/
├── .github/
│   └── workflows/
│       ├── ci.yml                 # Lint, Pytest, Next.js build, Docker build & Trivy scan
│       └── cd.yml                 # Terraform apply & ECS Fargate deployment
├── docker-compose.yml             # Full local stack (FastAPI, Next.js, Postgres, Redis)
├── .env.example
├── plan.md                        # Project plan reference
└── README.md                      # Comprehensive DevOps documentation & setup guide
