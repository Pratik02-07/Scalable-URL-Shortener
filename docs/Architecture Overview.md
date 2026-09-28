                                       Internet
                                          │
                                          ▼
                                  ┌──────────────┐
                                  │   AWS ALB    │
                                  │ (Port 80/443)│
                                  └──────┬───────┘
                                         │
                 ┌───────────────────────┴───────────────────────┐
                 │ Path: / (Default)                             │ Path: /api/*, /{code}, /health
                 ▼                                               ▼
     ┌───────────────────────┐                       ┌───────────────────────┐
     │ Next.js ECS Service   │                       │  FastAPI ECS Service  │
     │ (Frontend Container)  │                       │  (Backend Container)  │
     └───────────────────────┘                       └───────────┬───────────┘
                                                                 │
                                                   ┌─────────────┴─────────────┐
                                                   ▼                           ▼
                                        ┌────────────────────┐      ┌────────────────────┐
                                        │ ElastiCache Redis  │      │   RDS PostgreSQL   │
                                        │ (Caching Layer)    │      │  (Database Layer)  │
                                        └────────────────────┘      └────────────────────┘
