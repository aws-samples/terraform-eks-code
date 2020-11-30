
# aws_iam_role_policy_attachment.AWSCodePipelineServiceRole-eu-west-1-pipe-eksworkshop-app__AWSCodePipelineServiceRole-eu-west-1-pipe-eksworkshop-app:
resource "aws_iam_role_policy_attachment" "AWSCodePipelineServiceRole-eu-west-1-pipe-eksworkshop-app__AWSCodePipelineServiceRole-eu-west-1-pipe-eksworkshop-app" {
  policy_arn = aws_iam_policy.AWSCodePipelineServiceRole-eu-west-1-pipe-eksworkshop-app.arn
  role       = aws_iam_role.AWSCodePipelineServiceRole-eu-west-1-pipe-eksworkshop-app.id
}
