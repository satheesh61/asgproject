resource "aws_ssm_document" "load_avg_demo_asg_ref_ssm_doc_01" {
  name          = "${local.asg_name}-ref-ssm-doc-01"
  document_type = "Automation"
  document_format = "YAML"
  tags = local.common_tags
  content = <<DOC
  schemaVersion: '0.3'
  description: |-
    *Automation doc to refresh the ASG instance Daily
  parameters:
    autoscalinggroupname:
      type: String
    InstanceWarmup:
      type: Integer
    MinHealthyPercentage:
      type: Integer
    AutomationAssumerole:
      type: String
  assumeRole: '{{ AutomationAssumerole }}'
  mainSteps:
    - name: StartInstanceRefresh
      action: aws:executeAwsApi
      isEnd: true
      inputs:
        Service: autoscaling
        Api: StartInstanceRefresh
        AutoScalingGroupName: '{{ autoscalinggroupname }}'
        Preferences:
          InstanceWarmup: '{{ InstanceWarmup }}'
          AutoRollback: false
          MinHealthyPercentage: '{{ MinHealthyPercentage }}'
DOC
}

resource "aws_ssm_maintenance_window" "load_avg_demo_asg_ref_ssm_mw_01" {
  name     = "${local.asg_name}-ref-ssm-mw-01"
  schedule = "cron(0 0,00 0 ? * * *)"
  duration = 4
  cutoff   = 2
  allow_unassociated_targets = true
  schedule_timezone = "UTC"
    tags = merge(
    local.common_tags
    )
}

resource "aws_ssm_maintenance_window_task" "load_avg_demo_asg_ref_ssm_task_01" {
    name = "${local.asg_name}-ref-ssm-task-01"
    window_id = aws_ssm_maintenance_window.load_avg_demo_asg_ref_ssm_mw_01.id
    task_arn = aws_ssm_document.load_avg_demo_asg_ref_ssm_doc_01.name
    service_role_arn = aws_iam_role.load_avg_demo_asg_ref_ssm_service_role_01.arn
    task_type = "AUTOMATION"
    priority = 1
    task_invocation_parameters{
        automation_parameters{
             document_version = "$DEFAULT"
             parameter {
                 
                 name = "autoscalinggroupname"
                 values = ["${module.load_avg_demo_asg_01.autoscaling_group_name}"]
             }
             parameter {
                 name = "InstanceWarmup"
                 values = ["120"]
            }
            parameter  {
                 name = "MinHealthyPercentage"
                 values = ["90"]
            }
            parameter   {
                 name = "AutomationAssumerole"
                 values = ["${aws_iam_role.load_avg_demo_asg_ref_ssm_service_role_01.arn}"]
            }
        }
    }
}


data "aws_iam_policy_document" "load_avg_demo_asg_ref_ssm_service_role_policy" {
  statement {
     actions = ["sts:AssumeRole"]

     principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "load_avg_demo_asg_ref_ssm_service_role_01" {
  name                = "${local.asg_name}-ref-ssm-mw-service-role-01"
  path                = "/"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"]
  assume_role_policy  = data.aws_iam_policy_document.load_avg_demo_asg_ref_ssm_service_role_policy.json
  tags = local.common_tags
}

## CREATING DB AMI AUTOMATION POLICY FOR SSM MW TASK
resource "aws_iam_role_policy" "load_avg_demo_asg_ref_ssm_service_role_policy_01" {
  name = "${local.asg_name}-ref-ssm-mw-service-role-policy-01"
  role = aws_iam_role.load_avg_demo_asg_ref_ssm_service_role_01.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "iam:PassRole"
            ],
            "Resource": "${aws_iam_role.load_avg_demo_asg_ref_ssm_service_role_01.arn}"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "autoscaling:DeleteTags",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeTags",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:RollbackInstanceRefresh",
                "autoscaling:StartInstanceRefresh",
                "autoscaling:CreateLaunchConfiguration",
                "autoscaling:DescribeScalingActivities",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:CreateOrUpdateTags",
                "autoscaling:UpdateAutoScalingGroup",
                "autoscaling:DescribeInstanceRefreshes",
                "autoscaling:CancelInstanceRefresh",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "autoscaling:DetachInstances"
            ],
            "Resource": "${module.load_avg_demo_asg_01.autoscaling_group_arn}"
        }
    ]
}
EOF

}

