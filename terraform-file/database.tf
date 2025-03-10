# SECURITY GROUP FOR RDS MARIADB (WITH INLINE RULES)

resource "aws_security_group" "rds_sg" {
  vpc_id = aws_vpc.main.id
  name   = "rds-security-group"

  # 🔹 Allow inbound MySQL/MariaDB traffic from EC2 instances
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.server_sg.id]  # Only allow from EC2 instances
    description     = "Allow MySQL/MariaDB access from EC2 instances"
  }

  # 🔹 Allow all outbound traffic (for updates, logging, replication)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "RDS-Security-Group" }
}

# RDS PARAMETER GROUP (FOR REPLICATION)

resource "aws_db_parameter_group" "mariadb_param_group" {
  name   = "mariadb-param-group"
  family = "mariadb10.5"

  parameter {
    name  = "binlog_format"
    value = "ROW"  # Required for replication
    apply_method = "immediate"
  }

  tags = { Name = "MariaDB-Parameter-Group" }
}

# RDS MARIADB MASTER INSTANCE (PRIVATE_2: us-east-1b)

resource "aws_db_instance" "mariadb_master" {
  identifier             = "mariadb-master"
  engine                 = "mariadb"
  engine_version         = "10.5"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "mariadb_db"
  username              = "admin"
  password              = "SuperSecretPass123"  # Store this securely (e.g., AWS Secrets Manager)
  parameter_group_name  = aws_db_parameter_group.mariadb_param_group.name
  multi_az              = false
  storage_encrypted     = false
  publicly_accessible   = false
  backup_retention_period = 7 
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  availability_zone      = "us-east-1b"

  tags = { Name = "MariaDB-Master" }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "my-rds-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "My RDS Subnet Group"
  }
}

# RDS MariaDB Replica Instance (PRIVATE_1: us-east-1a)

# Some manual confuguration needed for using the replica

# resource "aws_db_instance" "mariadb_replica" {
#   identifier                  = "mariadb-replica"
#   replicate_source_db         = aws_db_instance.mariadb_master.id
#   engine                      = "mariadb"
#   engine_version              = "10.5"
#   instance_class              = "db.t3.micro"
#   allocated_storage           = 20  # Should match the master if not using autoscaling
#   username                    = "replicaadmin"  # Username for the replica, can be different from the master
#   password                    = "ReplicaSecretPass123"  # Store this securely (e.g., AWS Secrets Manager)
#   parameter_group_name        = aws_db_parameter_group.mariadb_param_group.name
#   multi_az                    = false
#   storage_encrypted           = false
#   publicly_accessible         = false
#   backup_retention_period     = 0  # Typically, replicas don't need their own backups
#   vpc_security_group_ids      = [aws_security_group.rds_sg.id]
#   db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
#   availability_zone           = "us-east-1a"

#   tags = { Name = "MariaDB-Replica" }
# }
