provider "aws" {
  region     = "us-east-1"
}
resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = aws_iam_role.s3_lambda_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
         "Action": [
                "s3:CreateBucket",
                "s3:List*",
                "s3:Get*"
            ],
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "s3_lambda_role" {
  name = "s3_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_lambda_function" "test_lambda_function" {
        function_name = "lambdaTest"
        filename      = "test.zip"
        source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
        role          = aws_iam_role.s3_lambda_role.arn
        runtime       = "python3.9"
        handler       = "lambda_function.lambda_handler"
        timeout       = 10
}