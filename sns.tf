locals{
    email_notification = [""]           #Enter Email ID in which you want to receive the notification
}

resource "aws_sns_topic" "load_avg_demo_asg_sns_01"{
    name            =  "${local.asg_name}-sns-01"
    display_name    =  "${local.asg_name}-sns-01"
    tags = local.common_tags
}

resource "aws_sns_topic_subscription" "load_avg_demo_asg_sns_tp_01"{
    for_each = toset(local.email_notification)
    topic_arn = aws_sns_topic.load_avg_demo_asg_sns_01.arn
    protocol  = "email"
    endpoint  = each.value
}