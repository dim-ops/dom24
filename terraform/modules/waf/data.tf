data "aws_lb" "shared" {
  tags = {
    "ingress.k8s.aws/stack" = "shared-alb"
  }
}
