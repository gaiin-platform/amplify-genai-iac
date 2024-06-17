resource "aws_lambda_layer_version" "panddoc_lambda_layer" {
  filename   = "../files/pandoc_layer.zip"
  layer_name = "pandoc_layer"
  compatible_runtimes = ["python3.10","python3.11"]
}
