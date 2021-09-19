
resource "aws_iam_role_policy_attachment" "AWSCodePipelineServiceRole-pipe-eksworkshop-app__AWSCodePipelineServiceRole-pipe-eksworkshop-app" {
  policy_arn = aws_iam_policy.AWSCodePipelineServiceRole-pipe-eksworkshop-app.arn
  role       = aws_iam_role.AWSCodePipelineServiceRole-pipe-eksworkshop-app.id
}
