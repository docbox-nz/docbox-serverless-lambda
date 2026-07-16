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

  # TODO: Lock down to lambda security group
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

  instance_class = "db.t4g.micro"

  db_name  = "docbox"
  username = "docbox_admin"
  password = "test"

  db_subnet_group_name   = aws_db_subnet_group.db_subnets.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible = true
  skip_final_snapshot = true

}
