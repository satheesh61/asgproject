# ASG Scaling in Cloudwatch metric based Alarm

resource "aws_cloudwatch_metric_alarm" "load_avg_demo_asg_cw_so_01" {
    alarm_name = "${local.asg_name}-cw-so-01"
    alarm_description = "when Average load of ASG instance is greater than 50%"
    actions_enabled = true
    alarm_actions = [
        module.load_avg_demo_asg_01.autoscaling_policy_arns["loadavginc"]
    ]
   # dimensions {}
    evaluation_periods = 1
    datapoints_to_alarm = 1
    threshold = 0.5
    comparison_operator = "GreaterThanOrEqualToThreshold"
    treat_missing_data = "missing"
    metric_query {
        expression = "SELECT AVG(LoadAverage5min) FROM custom_load WHERE AutoScalingGroupName = '${module.load_avg_demo_asg_01.autoscaling_group_name}' ORDER BY AVG() ASC"
        id = "q1"
        label = "LoadAverage"
        period   = 300
        return_data = true
    }
}

resource "aws_cloudwatch_metric_alarm" "load_avg_demo_asg_cw_si_01" {
    alarm_name = "${local.asg_name}-cw-si-01"
    alarm_description = "when Average load of ASG instance is lesser than 50%"
    actions_enabled = true
    alarm_actions = [
        module.load_avg_demo_asg_01.autoscaling_policy_arns["loadavgdec"]
    ]
   # dimensions {}
    evaluation_periods = 1
    datapoints_to_alarm = 1
    threshold = 0.5
    comparison_operator = "LessThanOrEqualToThreshold"
    treat_missing_data = "missing"
    metric_query {
        expression = "SELECT AVG(LoadAverage5min) FROM custom_load WHERE AutoScalingGroupName = '${module.load_avg_demo_asg_01.autoscaling_group_name}' ORDER BY AVG() ASC"
        id = "q1"
        label = "LoadAverage"
        period   = 300
        return_data = true
    }
}