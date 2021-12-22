resource "aws_api_gateway_method" "SearchUsers" {
  rest_api_id   = aws_api_gateway_rest_api.OxyApi.id
  resource_id   = aws_api_gateway_resource.UserPath.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.user_pool.id
  request_parameters = {
    "method.request.querystring.q" = true
    "method.request.header.Content-Type" = true
  }

}

resource "aws_api_gateway_integration" "SearchUsers" {
  rest_api_id             = aws_api_gateway_rest_api.OxyApi.id
  resource_id             = aws_api_gateway_resource.UserPath.id
  http_method             = aws_api_gateway_method.SearchUsers.http_method
  integration_http_method = "POST"
  content_handling        = "CONVERT_TO_TEXT"
  passthrough_behavior    = "WHEN_NO_TEMPLATES"
  type                    = "AWS"
  timeout_milliseconds    = 29000

  request_parameters = {
    "integration.request.header.Content-Type" = "method.request.header.Content-Type"
  }
  credentials = aws_iam_role.APIGatewayCognitoIDPListUsers.arn
  uri         = "arn:aws:apigateway:${var.region}:cognito-idp:action/ListUsers"
  request_templates = {
    "application/json" = <<EOF
#set($q = $method.request.querystring.q)
{
    "UserPoolId": "${var.user_pool_id}", 
    "Filter": "email^=\"$q\""
}
  EOF
  }
}

resource "aws_api_gateway_integration_response" "SearchUsers" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  resource_id = aws_api_gateway_resource.UserPath.id
  http_method = aws_api_gateway_method.SearchUsers.http_method
  status_code = aws_api_gateway_method_response.SearchUsers_200.status_code
  content_handling = "CONVERT_TO_TEXT"
  response_parameters = {
    "method.response.header.Content-Type" = "integration.response.header.Content-Type"
  }
  response_templates = {
    "application/json" = <<EOF
#set($inputRoot = $util.parseJson($util.base64Decode($input.body)))
##set($inputRoot = $util.parseJson($input.body))
#set($attrMap = {"sub":"id","email":"email"})
#set($users=[])
##select and rename attribute for confirmed and enabled users
#foreach($u in $inputRoot.Users)
    #if($u.Enabled && $u.UserStatus.equals("CONFIRMED"))
        #set($tmp = {})
        #foreach($attr in $u.Attributes)
            #if($attrMap.containsKey($attr.Name))
                #set($tmp[$attrMap[$attr.Name]] = $attr.Value)
            #end
        #end 
        #set($nop = $users.add($tmp))
    #end
#end
[#foreach($u in $users)
    {#foreach($attr in $u.entrySet())
        "$attr.getKey()": "$attr.getValue()"#if($foreach.hasNext), #end 
    #end}#if($foreach.hasNext), #end 
#end]
    EOF
  }
  depends_on = [aws_api_gateway_integration.SearchUsers]
}

resource "aws_api_gateway_method_response" "SearchUsers_200" {
  rest_api_id = aws_api_gateway_rest_api.OxyApi.id
  resource_id = aws_api_gateway_resource.UserPath.id
  http_method = aws_api_gateway_method.SearchUsers.http_method
  status_code = 200
  response_parameters = {
    "method.response.header.Content-Type" = true
  }
  response_models = {
    "application/json" = "Empty"
  }
}


