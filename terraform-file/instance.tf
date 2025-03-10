# IAM Role for SSM Host
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "ssm_role" {
  name = "SSMHostRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach SSM Full Access Permissions to the Role
resource "aws_iam_role_policy_attachment" "ssm_full_access_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

# Create IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "SSMHostInstanceProfile"
  role = aws_iam_role.ssm_role.name
}


# EC2 Instances & Security Group


resource "aws_instance" "ssm_host" {
  ami                  = "ami-04aa00acb1165b32a"
  instance_type        = "t2.micro"
  subnet_id            = aws_subnet.public_1.id
  security_groups      = [aws_security_group.ssm_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name  # Attach IAM Role here

  user_data = <<-EOF
    #!/bin/bash
    set -e  # Stop script if any command fails
    echo "Installing AWS SSM Session Manager Plugin..."
    curl -O https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
    sudo yum install -y session-manager-plugin.rpm
    echo "Session Manager Plugin installed successfully!"
  EOF

  tags = { Name = "SSM-Host" }
}



# IAM Role for Private Server (SSM Access)
resource "aws_iam_role" "ssm_role_server" {
  name = "SSMPrivateServerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# Attach AmazonSSMManagedInstanceCore Policy to IAM Role
resource "aws_iam_role_policy_attachment" "ssm_core_attach_server" {
  role       = aws_iam_role.ssm_role_server.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Create IAM Instance Profile for EC2 Server
resource "aws_iam_instance_profile" "ssm_instance_profile_server" {
  name = "SSMInstanceProfileServer"
  role = aws_iam_role.ssm_role_server.name
}

# EC2 Instance (Private Server with SSM Role)
resource "aws_instance" "server" {
  ami                         = "ami-04aa00acb1165b32a"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_2.id
  security_groups             = [aws_security_group.server_sg.id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile_server.name  # Attach IAM Role here

  tags = { Name = "Server" }
}

# Security Group for SSM Host
resource "aws_security_group" "ssm_sg" {
  vpc_id = aws_vpc.main.id
  name   = "ssm-sg"

  # Allow inbound access for SSM Agent communication
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow SSM connectivity
    description = "Allow SSM Agent communication"
  }

  # Allow SSH for port forwarding (Developer access)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Typically restricted to Developer IP
    description = "Allow SSH access for SSM Port Forwarding"
  }

  # Allow outbound access to the internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "ssm-security-group"
  }
}

# Security Group for Server in Private Subnet
resource "aws_security_group" "server_sg" {
  vpc_id = aws_vpc.main.id
  name   = "server-sg"

  # Allow SSH access from the SSM Host only
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ssm_sg.id] # Only from SSM Host
    description     = "Allow SSH from SSM Host"
  }

  ingress {
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow database connections (e.g., MariaDB) from private subnet instances
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"] # Private VPC CIDR
    description = "Allow MySQL/MariaDB access within VPC"
  }

  # Allow outbound access (for NAT Gateway)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "server-security-group"
  }
}