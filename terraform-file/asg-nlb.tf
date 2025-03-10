# Generate a Random Suffix (Avoids Naming Conflicts)
resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
}

# Launch Template for ASG
resource "aws_launch_template" "asg_launch_template" {
  name_prefix   = "asg-launch-template"
  image_id      = "ami-04aa00acb1165b32a"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.server_sg.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.ssm_instance_profile_server.name
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    echo "<h1>Hello from ASG instance!</h1>" > /usr/share/nginx/html/index.html
  EOF
  )
}

# Auto Scaling Group (ASG)
resource "aws_autoscaling_group" "server_asg" {
  launch_template {
    id      = aws_launch_template.asg_launch_template.id
    version = "$Latest"
  }
  vpc_zone_identifier = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  min_size            = 0   
  max_size            = 3   
  desired_capacity    = 0   

  tag {
    key                 = "Name"
    value               = "ASG-Server-Instance"
    propagate_at_launch = true
  }
}

# Scale Out & Scale In Policies
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "scale-out"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.server_asg.name
  policy_type            = "StepScaling"
  estimated_instance_warmup = 300

  step_adjustment {
    metric_interval_lower_bound = 30
    scaling_adjustment          = 1
  }
}

# Scale In Policy (Remove instance if CPU < 30%)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in"
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.server_asg.name
  policy_type            = "StepScaling"
  estimated_instance_warmup = 300

  # Remove 1 instance if CPU is between 0% and 29%
  step_adjustment {
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = 30
    scaling_adjustment          = -1
  }

  # Ensure a Step with No Upper Bound
  step_adjustment {
    metric_interval_lower_bound = 30
    scaling_adjustment          = 0  # No scale-in when CPU is above 30%
  }
}
# Create Network Load Balancer (NLB) for ASG 
resource "aws_lb" "nlb" {
  name               = "public-nlb"
  internal           = false  
  load_balancer_type = "network"
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# Create Target Group for ASG
resource "aws_lb_target_group" "tg" {
  name     = "asg-tg-${random_string.suffix.result}"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Attach ASG to Target Group
resource "aws_autoscaling_attachment" "asg_nlb" {
  autoscaling_group_name = aws_autoscaling_group.server_asg.id
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}
# Create NLB Listener
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}