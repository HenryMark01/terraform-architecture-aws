# VPC Endpoint for SSM
resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.ssm"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "SSM-VPC-Endpoint"
  }
}

# VPC Endpoint for SSM Messages
resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "SSM-Messages-VPC-Endpoint"
  }
}

# VPC Endpoint for EC2 Messages (Required for SSM)
resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.ec2messages"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "EC2-Messages-VPC-Endpoint"
  }
}

#  Security Group for VPC Endpoints (Allows HTTPS for SSM)
resource "aws_security_group" "vpc_endpoint_sg" {
  vpc_id = aws_vpc.main.id
  name   = "vpc-endpoint-sg"

  # Allow inbound HTTPS (443) from VPC CIDR
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.0/16"]
    description = "Allow HTTPS traffic for SSM VPC Endpoint"
  }

  # Allow outbound HTTPS (443)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "vpc-endpoint-security-group"
  }
}