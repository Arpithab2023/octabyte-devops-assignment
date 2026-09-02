# Approach

## Order of work
1. Started with networking (VPC/subnets/routing) since every other resource depends on it.
2. Layered security groups next, tier by tier (ALB → app → DB), so nothing
   later could accidentally be provisioned with an over-permissive default SG.
3. Chose ECS Fargate over EC2/EKS: for a single-service app this gives managed
   scaling and patching without the operational overhead of EKS control-plane
   management or EC2 AMI maintenance — the fastest path to a production-grade
   deploy target that also plugs cleanly into the CI/CD pipeline (docker build → ECR → ECS).
4. Added RDS last among core infra, wired to its own subnet tier and SG so the
   database is never reachable except from the app tier.
5. Built the CI/CD pipeline around the deployment story required: PR tests →
   merge triggers build/scan/push → auto-deploy staging → manual gate → production.
   Used GitHub Environments for the approval gate rather than a custom approval
   step, since it's the native mechanism and shows up clearly in the Actions UI.
6. Monitoring: picked the three metric categories explicitly asked for
   (infra/app/db) and mapped each to concrete CloudWatch alarms + two dashboards,
   rather than instrumenting broadly — kept it meaningful over exhaustive.
7. Wrote docs last, once the design decisions were settled, so the README
   reflects what was actually built rather than what was planned.

## Trade-offs made under the time box
- Used a placeholder Node/Express app instead of building a full application —
  the assignment states application logic isn't the focus.
- Single NAT gateway instead of per-AZ (documented in README as a prod follow-up).
- Test/integration test steps in the pipeline are placeholders since there's no
  real app logic to test — the pipeline *structure* (fail-fast, scan, gate) is
  the deliverable being demonstrated.
- One environment variable (`environment`) toggles staging/production behavior
  in a single state file, rather than fully isolated states per environment —
  faster to demo, called out as a next step for real multi-env isolation.
