# Challenges Faced & Resolutions

1. **Terraform backend can't use variables.**
   The S3 backend block requires literal values, but I wanted the bucket name
   configurable. Resolved by adding a `bootstrap-backend.sh` script that
   provisions the bucket/table once and printing the value to paste into
   `versions.tf`, rather than trying to template the backend block itself.

2. **Chicken-and-egg: ECS task needs an image, but the image comes from the
   pipeline the infra is supposed to trigger.**
   Solved by defaulting `container_image` to a public placeholder image
   (`nginx`) so `terraform apply` succeeds on a fresh account, then letting the
   CI/CD pipeline's `force-new-deployment` step pick up the real image once
   it's pushed to ECR.

3. **Secrets exposure risk in ECS task definitions.**
   Environment variables in a task definition are visible in the AWS console/API.
   Resolved by using the ECS `secrets` block (pulls from Secrets Manager at
   container start) for credentials, and only using plain `environment` for
   non-sensitive values like host/db name.

4. **Balancing "comprehensive" against the 4-hour box.**
   Given the scope (infra + CI/CD + monitoring + docs), I prioritized a working,
   coherent happy-path over exhaustively implementing every nice-to-have
   (HTTPS, WAF, multi-env state isolation, real app tests) and instead listed
   those explicitly as documented follow-ups, so the reviewer can see the
   trade-off was deliberate rather than an oversight.
