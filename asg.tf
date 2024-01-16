module "load_avg_demo_asg_kp_01" {
  source  = "terraform-aws-modules/key-pair/aws"
  key_name   = "${local.asg_name}-kp-01"
  public_key = var.instance_keypair
  tags = merge(
    local.common_tags
  )
}

module "load_avg_demo_asg_01" {
   source  = "terraform-aws-modules/autoscaling/aws"
   version = "~> 7.3.0"
  # AUTOSCALING GROUP
  name = "${local.asg_name}-01"
  use_name_prefix = false

  min_size                  = 2
  max_size                  = 5
  desired_capacity          = 2
  vpc_zone_identifier       = module.load_avg_demo_vpc.private_subnets
  enable_monitoring         = true
  create_scaling_policy     = true
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTerminatingInstances",
    "GroupTotalCapacity",
    "GroupTotalInstances"]

  termination_policies      = ["OldestLaunchTemplate"]
  security_groups = [module.load_avg_demo_asg_sg_01.security_group_id]

  # REFERENCING LAUNCH TEMPLATE NAME FROM CUSTOM MODULE LAUNCH TEMPLATE
  launch_template_name       = "${local.asg_name}-lt-01"
  update_default_version      = true
  launch_template_version = "$Latest"
  image_id          = data.aws_ami.amazon_linux.id
  #image_id          = "ami-02e94b011299ef128"
  instance_type     = var.instance_type
  key_name          = module.load_avg_demo_asg_kp_01.key_pair_name
  iam_instance_profile_arn = aws_iam_instance_profile.ec2_access_instance_profile.arn

  #Block device mapping
  block_device_mappings = [
    {
      # Root volume
      device_name = "/dev/xvda"
      no_device   = 0
      ebs = {
        delete_on_termination = true
        encrypted             = true
        volume_size           = 8
        volume_type           = "gp3"
      }
      },
  ]
  user_data        = base64encode(var.asg_userdata["userdata"])
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 32
    instance_metadata_tags      = "enabled"
  }
  tag_specifications = [
      {
        resource_type = "instance"
        tags = merge(
          local.common_tags,
          {"Name" = "${local.asg_name}-01" }

        )
      },
      {
        resource_type = "volume"
        tags = merge(
          local.common_tags,
          {"Name" = "${local.asg_name}-01" }
        )
      },
    ]

    #SIMPLE AUTOSCALING POLICY  
    scaling_policies = {
        loadavginc = {
            policy_type = "SimpleScaling"
            adjustment_type = "ChangeInCapacity"
            scaling_adjustment = 1
            cooldown = 300      
        },
        loadavgdec = {
            policy_type = "SimpleScaling"
            adjustment_type = "ChangeInCapacity"
            scaling_adjustment = -1
            cooldown = 300      
        }
    }
  tags = merge(local.common_tags)
}

module "load_avg_demo_asg_sg_01" {
  source = "git::https://gitlab.serviceurl.in/lentra/cloud-ops/aws/terraform/modules-prod.git//security-group"
  name   = "${local.asg_name}-sg-01"
  vpc_id = module.load_avg_demo_vpc.vpc_id
  ingress_with_source_security_group_id = [

  ]
  ingress_with_cidr_blocks = [
    # {
    #   from_port   = 22
    #   to_port     = 22
    #   protocol    = "22"
    #   description = "allow 22 port to Instance connect "
    #   cidr_blocks = "0.0.0.0/0"        # update with your IP
    # }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = -1
      to_port     = -1
      protocol    = -1
      description = "allow all traffic"
      cidr_blocks = "0.0.0.0/0"
    },
  ]
  tags = merge(
    local.common_tags
  )
}

# LANUCH TERMINATION NOTIFICATION RESOURCE

resource "aws_autoscaling_notification" "load_avg_demo_asg_not_01" {
  group_names = [
    module.load_avg_demo_asg_01.autoscaling_group_name
  ]

  notifications = [
    "autoscaling:EC2_INSTANCE_LAUNCH",
    "autoscaling:EC2_INSTANCE_TERMINATE",
    "autoscaling:EC2_INSTANCE_LAUNCH_ERROR",
    "autoscaling:EC2_INSTANCE_TERMINATE_ERROR",
  ]

  topic_arn = aws_sns_topic.load_avg_demo_asg_sns_01.arn
}