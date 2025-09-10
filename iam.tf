data "aws_caller_identity" "current" {}

resource "aws_iam_role" "sonarqube_ssm" {
  name = "sonarqube-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "sonarqube_ssm_policy" {
  name = "sonarqube-ssm-get-parameter"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "ssm:GetParameter"
      ],
      Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/sonarqube/db_password"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sonarqube_attach_ssm" {
  role       = aws_iam_role.sonarqube_ssm.name
  policy_arn = aws_iam_policy.sonarqube_ssm_policy.arn
}

resource "aws_iam_instance_profile" "sonarqube_profile" {
  name = "sonarqube-ec2-profile"
  role = aws_iam_role.sonarqube_ssm.name
}

