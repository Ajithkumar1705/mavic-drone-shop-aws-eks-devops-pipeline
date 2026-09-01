resource "aws_ecr_repository" "service" {
  for_each = toset(var.services)

  name                 = "rs-${each.value}"
  image_tag_mutability = "IMMUTABLE" # once pushed, a tag can't be overwritten — forces new tags per build, matches the git-sha tagging in ci.yml

  image_scanning_configuration {
    scan_on_push = true # ECR's own scan-on-push, in addition to Trivy in CI — defense in depth, not redundant
  }
}

resource "aws_ecr_lifecycle_policy" "service" {
  for_each = aws_ecr_repository.service

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only the last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
