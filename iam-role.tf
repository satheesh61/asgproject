#CREATING THE ROLE WHICH ALLOWS ACCESS OF EC2 INSTANCES WITHOUT SSH KEYS ie VIA SSM SERVICE
data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_access_role" {
  name                = "${local.asg_name}-ec2-access-role-01"
  path               = "/system/"
  assume_role_policy  = data.aws_iam_policy_document.instance_assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy","arn:aws:iam::aws:policy/AmazonEC2FullAccess"]
  tags = merge(local.common_tags,
  {"application"="session-manager"}
  )
}

resource "aws_iam_instance_profile" "ec2_access_instance_profile" {
  name = "${local.asg_name}-ec2-access-role-01"
  role = aws_iam_role.ec2_access_role.name
  tags = merge(local.common_tags,
  {"application"="session-manager"}
  )
}