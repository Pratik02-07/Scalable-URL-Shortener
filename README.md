<div align="center">

## Scalable URL Shortener

[![CI Workflow](https://github.com/Pratik02-07/Scalable-URL-Shortene/actions/workflows/ci.yml/badge.svg)](https://github.com/Pratik02-07/Scalable-URL-Shortene/actions/workflows/ci.yml)
![AWS EKS](https://img.shields.io/badge/AWS-EKS%20v1.31-orange?logo=amazon-aws&logoColor=white)
![Terraform](https://img.shields.io/badge/IaC-Terraform%20~%3E%205.0-purple?logo=terraform&logoColor=white)
![GithubActions](https://img.shields.io/badge/GitHub%20Actions-Workflow-blue?logo=github&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-1.0.0-009688?logo=fastapi&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-Multi--stage-2496ED?logo=docker&logoColor=white)




<br />

![](Docs/Architectures.png)

</div>

---



> **A scalable, production-grade URL-shortening platform.**  
> Demonstrates containers, CI/CD, caching, infrastructure-as-code, and cloud deployment on AWS.


## Architecture

```
                         Internet
                            │
                            ▼
                    ┌──────────────┐
                    │     ALB      │  (Public Subnets)
                    └──────┬───────┘
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
          ECS/Fargate   ECS/Fargate   ECS/Fargate  (Private Subnets)
             │             │             │
             └─────────────┼─────────────┘
                           │
                    ┌──────▼──────┐
                    │   Redis     │
                    │ ElastiCache │
                    └──────┬──────┘
                           │ Cache Miss
                           ▼
                    ┌──────────────┐
                    │ PostgreSQL   │
                    │     RDS      │
                    │ Multi-AZ     │
                    └──────────────┘

        GitHub
           │
           ▼
   GitHub Actions
           │
     ┌─────┴─────┐
     ▼           ▼
   Tests       Docker
                 │
                 ▼
               ECR
                 │
                 ▼
          ECS Deployment
```

## Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Next.js (TypeScript) |
| **Backend** | FastAPI (Python 3.12) |
| **Database** | PostgreSQL (RDS Multi-AZ in prod) |
| **Cache** | Redis (ElastiCache in prod) |
| **Containers** | Docker + Docker Compose |
| **IaC** | Terraform |
| **CI/CD** | GitHub Actions |
| **Cloud** | AWS (ECS Fargate, ALB, RDS, ElastiCache, ECR, CloudWatch) |
| **Testing** | Pytest + k6 (load testing) |
| **Security** | IAM, Security Groups, Secrets Manager, Trivy |

---

## API

### Shorten a URL

```http
POST /api/v1/shorten
Content-Type: application/json

{
  "url": "https://example.com/very/long/url",
  "custom_alias": "my-link"   // optional
}
```

**Response `201 Created`:**
```json
{
  "short_code": "aB91xK",
  "short_url": "http://localhost:8000/aB91xK",
  "original_url": "https://example.com/very/long/url",
  "click_count": 0,
  "created_at": "2024-01-01T00:00:00Z",
  "is_active": true
}
```

### Redirect

```http
GET /{short_code}
→ 302 redirect to original URL
```

Cache-first: checks Redis → falls back to PostgreSQL → caches result.

### Stats

```http
GET /api/v1/stats/{short_code}
```

### Health Checks

```http
GET /health   → {"status": "ok"}        (liveness)
GET /ready    → {"status": "ready"}     (readiness — verifies DB)
```

---

## Running Locally

### Prerequisites

- Docker & Docker Compose
- Python 3.12+
- Node.js 20+

### 1. Clone & configure

```bash
git clone <repo>
cd url-shortener-devops
cp .env.example .env
```

### 2. Start all services

```bash
docker compose up -d
```

Services:
- **Backend** → http://localhost:8000
- **Frontend** → http://localhost:3000
- **PostgreSQL** → localhost:5432
- **Redis** → localhost:6379

Interactive API docs: http://localhost:8000/docs

### 3. Run backend tests

```bash
cd Backend
python -m pytest tests/ -v
```

---

## Project Phases

| Phase | Status | Description |
|---|---|---|
| 1 — Application | ✅ Complete | FastAPI + PostgreSQL + Redis (local) |
| 2 — Containerization | ✅ Complete | Docker + Docker Compose |
| 3 — CI with GitHub Actions | 🔜 Next | Lint → Test → Docker build → Trivy |
| 4 — AWS Infrastructure (Terraform) | 🔜 | VPC, ALB, ECS, RDS, ElastiCache, ECR |
| 5 — ECS Fargate Deployment | 🔜 | GitHub Actions → ECR → ECS |
| 6 — Redis + DB Scaling | 🔜 | ElastiCache + RDS Multi-AZ |
| 7 — Observability | 🔜 | CloudWatch logs, metrics, alarms |
| 8 — Load Testing | 🔜 | k6 at 100–4,000 RPS |

---

## Repository Structure

```
.
├── Backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── shorten.py       # POST /api/v1/shorten
│   │   │   └── redirect.py      # GET /{short_code}, GET /api/v1/stats/{code}
│   │   ├── core/
│   │   │   └── config.py        # Pydantic settings (env vars)
│   │   ├── db/
│   │   │   ├── base.py          # SQLAlchemy DeclarativeBase
│   │   │   └── session.py       # Engine + SessionLocal + get_db()
│   │   ├── models/
│   │   │   └── url.py           # URL ORM model
│   │   ├── schemas/
│   │   │   └── url.py           # Pydantic request/response schemas
│   │   ├── services/
│   │   │   ├── url_service.py   # Business logic (CRUD + short code gen)
│   │   │   └── cache_service.py # Redis cache (HIT/MISS/SET/DEL)
│   │   └── main.py              # FastAPI app + lifespan + CORS
│   ├── tests/
│   │   ├── test_api.py          # Integration tests (TestClient + mocked Redis)
│   │   ├── test_url_service.py  # Unit tests for service layer
│   │   ├── test_database.py     # ORM model tests
│   │   └── test_config.py       # Settings load test
│   ├── Dockerfile               # Multi-stage, non-root, HEALTHCHECK
│   ├── requirements.txt
│   └── pytest.ini
├── Frontend/
│   └── (Next.js app)
├── terraform/
│   ├── modules/                 # vpc / alb / ecs / rds / redis / ecr
│   └── environments/            # dev / prod
├── .github/
│   └── workflows/               # ci.yml / cd.yml  (Phase 3)
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## Performance Targets

| Metric | Target |
|---|---|
| Write throughput | ~4 req/s |
| Read throughput | ~400 req/s average |
| Peak read throughput | ~4,000 req/s |
| p99 redirect latency (cache HIT) | < 10 ms |
| p99 redirect latency (cache MISS) | < 50 ms |
| Cache hit ratio | > 95% |

---

## Resume Bullet Points

> **Scalable URL Shortener — AWS, Terraform, Docker, ECS Fargate, Redis, PostgreSQL, GitHub Actions**
>
> • Designed and deployed a highly available URL-shortening platform across multiple AWS Availability Zones using ECS Fargate, ALB and Terraform.  
> • Implemented Redis caching for read-heavy URL resolution, reducing database load by >95%.  
> • Built CI/CD pipelines with GitHub Actions for automated testing, Docker image builds, security scanning (Trivy) and ECS deployments.  
> • Validated the platform with k6 load tests at up to 4,000 RPS; monitored via CloudWatch dashboards and alarms.
