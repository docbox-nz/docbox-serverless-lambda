
data "aws_vpc" "default" {
  id = var.vpc_id
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_db_subnet_group" "db_subnets" {
  name       = "docbox-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name = "Docbox DB Subnet Group"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "docbox-rds-security-group"
  description = "Allows incoming traffic to PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_instance" "postgres" {
  identifier            = "docbox-postgres-db"
  allocated_storage     = 20
  max_allocated_storage = 100
  engine                = "postgres"
  engine_version        = "16.3"

  instance_class = "db.t3.micro"

  db_name                     = "docbox"
  username                    = "docbox_admin"
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible                 = true
  skip_final_snapshot                 = true
  iam_database_authentication_enabled = true
}

locals {
  rds_db_user_prefix = "arn:aws:rds-db:${var.aws_region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.postgres.resource_id}"
}

# IAM Policy that allows the docbox role to connect to the docbox databases
resource "aws_iam_policy" "docbox_iam_rds_policy" {
  name        = "docbox_iam_rds_policy"
  description = "Allow access to per tenant database and docbox database credentials"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "rds-db:connect"
      Resource = [
        # Root database role access
        "${local.rds_db_user_prefix}/docbox_config_api",
        # Tenant wildcard database roles access
        "${local.rds_db_user_prefix}/docbox_*_dev_api",
        "${local.rds_db_user_prefix}/docbox_*_prod_api",
      ]
    }]
  })
}
