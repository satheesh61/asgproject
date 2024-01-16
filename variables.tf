variable "instance_keypair" {
  description = "AWS EC2 Key pair that need to be associated with EC2 Instance"
  type = string
  default = "eks-terraform-key"
}
variable "instance_type" {
  description = "AWS EC2 instance type for an ASG"
  type = string
  default = "t3a.small"
}

variable "asg_userdata" {
  description = "ASG LOAD Average Userdata"
  type        = map

  default = {
  userdata = <<-EOT
  #!/bin/bash
  sudo yum install amazon-cloudwatch-agent -y
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a start
  TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
  instance_id=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s  http://169.254.169.254/latest/meta-data/instance-id)
  asg_name=$(aws ec2 --region=ap-south-1 describe-tags --filters "Name=resource-id,Values=$instance_id" "Name=key,Values=aws:autoscaling:groupName" --output text --query 'Tags[0].Value')
  (crontab -l;  echo "* * * * * /bin/aws  --region ap-south-1 cloudwatch put-metric-data  --namespace="custom_load"  --metric-name  "LoadAverage5min"  --value  \$(awk  '{printf \"\\%.2f\\n\",  \$2  / $(nproc) }'  /proc/loadavg ) --unit "Count"  --dimensions AutoScalingGroupName=$asg_name,InstanceId=$instance_id  > /tmp/cpuload-lastrun.log 2>&1") | sort -u | crontab
  sudo amazon-linux-extras install epel -y
  sudo yum install stress -y
  EOT
  }
}
